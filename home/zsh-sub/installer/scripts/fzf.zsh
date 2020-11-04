
if [[ -d ~/.fzf ]]; then
	echo -e "\e[33m\!/ A previous version of \e[32mFuzzy Finder\e[33m was detected ==> backing it up to \e[32m~/.fzf.bak\e[33m...\e[0m"
	mv ~/.fzf ~/.fzf.bak
fi

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all
