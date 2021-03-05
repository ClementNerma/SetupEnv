if [[ -d ~/.fzf ]]; then
	mvbak ~/.fzf
	echoc "\z[yellow]°\!/ A previous version of \z[green]°Fuzzy Finder\z[]° was detected ==> backed it up to \z[magenta]°$LAST_FILEBAK_PATH\z[]°...\z[]°"
fi

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
chmod +x ~/.fzf/install
~/.fzf/install --all
