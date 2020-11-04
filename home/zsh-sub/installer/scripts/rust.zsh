
if [ -d ~/.rustup ]; then
	echo -e "\e[33m\!/ A previous version of \e[32mRust\e[33m was detected ==> backing it up to \e[32m~/.rustup.bak\e[33m...\e[0m"
	rm -rf ~/.rustup.bak
	mv ~/.rustup ~/.rustup.bak
fi

if [ -d ~/.cargo ]; then
	echo -e "\e[33m\!/ A previous version of \e[32mCargo\e[33m was detected ==> backing it up to \e[32m~/.cargo.bak\e[33m...\e[0m"
	rm -rf ~/.cargo.bak
	mv ~/.cargo ~/.cargo.bak
fi

curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
source $HOME/.cargo/env # Just for this session

_step "Installing tools for Rust..."
sudo apt install -yqqq llvm libclang-dev

_step "Installing required tools for some Rust libraries..."
sudo apt install -yqqq pkg-config libssl-dev
