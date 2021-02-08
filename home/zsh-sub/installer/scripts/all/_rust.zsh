if [ -d ~/.rustup ]; then
	mvbak ~/.rustup
	echo -e "\e[33m\!/ A previous version of \e[32mRust\e[33m was detected ==> backed it up to \e[32m$LAST_MVBAK_PATH\e[33m..."
fi

if [ -d ~/.cargo ]; then
	mvbak ~/.cargo
	echo -e "\e[33m\!/ A previous version of \e[32mCargo\e[33m was detected ==> backed it up to \e[32m$LAST_MVBAK_PATH\e[33m..."	
fi

curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
source $HOME/.cargo/env # Just for this session

_step "Installing tools for Rust..."
sudo apt install -yqqq llvm libclang-dev
