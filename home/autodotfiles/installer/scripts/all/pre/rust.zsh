if [ -d ~/.rustup ]; then
	mvbak ~/.rustup
	echowarn "\z[yellow]°\!/ A previous version of \z[green]°Rust\z[]° was detected ==> backed it up to \z[magenta]°$LAST_FILEBAK_PATH\z[]°...\z[]°"
fi

if [ -d ~/.cargo ]; then
	mvbak ~/.cargo
	echowarn "\z[yellow]°\!/ A previous version of \z[green]°Cargo\z[]° was detected ==> backed it up to \z[magenta]°$LAST_FILEBAK_PATH\\z[]°..\z[]°"	
fi

curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
source $HOME/.cargo/env # Just for this session

_step "Installing tools for Rust..."
sudo apt install -yqqq llvm libclang-dev
