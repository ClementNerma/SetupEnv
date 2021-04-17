
# Open a file or directory on Windows from a 'fd' search
function openfd() {
  local results=$(fd "$@")
  local count=$(echo "$results" | wc -l)

  if [[ -z "$results" ]]; then
      echoerr "No result found for this search."
      return 1
  fi

  if [[ $count = 1 ]]; then
    open "$results"
    return
  fi

  local selected=$(echo "$results" | fzf)

  if [[ -z "$selected" ]]; then
    return 1
  fi

  open "$selected"
}

# Open a file or directory on Windows from a 'zoxide' search
function openz() {
  local result=$(zoxide query "$1" 2>/dev/null)

  if [[ -z "$result" ]]; then
    echoerr "No result found by Zoxide."
    return 1
  fi

  open "$result"
}

# Open a file or directory on Windows from a 'zoxide' + 'fd' search
function openfz() {
  if [[ -z "$1" ]]; then
    echoerr "Please provide a search for Zoxide."
    return 1
  fi

  local result=$(zoxide query "$1" 2>/dev/null)

  if [[ -z "$result" ]]; then
    echoerr "No result found by Zoxide."
    return 1
  fi
  
  cd "$result"
  openfd
}

# Aliases to exit after open commands
function opene() { open "$@" && exit }
function openze() { openz "$@" && exit }
function openfde() { openfd "$@" && exit }
function openfze() { openfz "$@" && exit }

# Add a list of directories to Zoxide's index
# All directories one level under the provided list will be indexed as well
function zoxide_populate_with() {
    for dir in "$@"; do
    	echoverb "> Populating Zoxide index with: \z[yellow]°$dir\z[]°"

        if [[ ! -d $dir ]]; then
            echoerr "Directory not found: \z[yellow]°$dir\z[]°"
            continue
        fi

        zoxide add "$dir"

        for item in "$dir"; do
            [[ -d $item ]] && zoxide add "$item"
        done
    done
}