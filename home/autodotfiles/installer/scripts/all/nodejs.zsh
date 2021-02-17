if [[ -d ~/.volta ]]; then
	mvbak ~/.volta
	echoc "\z[yellow]°\!/ A previous version of \z[green]°Volta\z[]° was detected ==> backed it up to \z[magenta]°$LAST_FILEBAK_PATH\z[]°..."
fi

_step "Installing Volta..."
curl https://get.volta.sh | bash

export VOLTA_HOME="$HOME/.volta"    # Just for this session
export PATH="$VOLTA_HOME/bin:$PATH" # Just for this session

_step "Installing Node.js & NPM..."
volta install node@latest

_step "Installing Yarn..."
volta install yarn
yarn -v # Just to be sure Yarn was installed correctly
