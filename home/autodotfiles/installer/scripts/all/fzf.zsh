if [[ -d ~/.fzf ]]; then
	mvbak ~/.fzf
	echo -e "\e[33m\!/ A previous version of \e[32mFuzzy Finder\e[33m was detected ==> backed it up to \e[32m$LAST_FILEBAK_PATH\e[33m..."
fi

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
chmod +x ~/.fzf/install
~/.fzf/install --all
