if [[ -d ~/.volta ]]; then
	mvbak ~/.volta
	echo -e "\e[33m\!/ A previous version of \e[32mVolta\e[33m was detected ==> backed it up to \e[32m$LAST_FILEBAK_PATH\e[33m..."
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
