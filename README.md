# AutoDotFiles :hammer_and_wrench:

This repository contains an automatic setup program I've made to setup my whole environment on any computer.  
It is meant for personal usage only, but as it's a relatively complex setup I make it public so anyone can check how it works.

## Goal

The goal of this project is to install with a simple single command my whole environment - aliases, software configuration, tools, packages - with a one-line update process with a simple rollback method in case something goes wrong.

It also adapts the environment depending on if the platform is WSL 2 or a real Debian distribution, and also if the computer is my main computer or not, meaning I also use it on my professional computer.

Currently, it contains ~1k of ZSH (not counting blank lines and comments).

## Features

* Auto-installation and update of softwares
* Auto-installation and configuration of aliases, functions, configuration for softwares
* Auto-backup of current environment during update process
* Remote installer to setup the environment on a distant server
* Works both on WSL (Debian) and Debian-based distributions

## Content

* Shell is [`zsh`](https://github.com/zsh-users/zsh)
* Shell framework is [OhMyZSH!](https://github.com/ohmyzsh/ohmyzsh)
* Prompt is [Powerlevel10k](https://github.com/romkatv/powerlevel10k)

Many other software are included, and change from time to time depending on which tools I find the most intuitive and enjoyable to use.

This project is mainly tailored for Debian in WSL 2, but should work fine on any Debian-based distribution.

## Usage

This repository contains an automatic setup program I've made to setup my whole environment on any computer.  
It is meant for personal usage only, but as it's a relatively complex setup I make it public so anyone can check how it works.

## Usage

### Installation

First, clone this repository:

```bash
git clone https://github.com/ClementNerma/AutoDotFiles
cd AutoDotFiles
chmod +x *.bash
```

Setup environment on current computer:

```bash
./auto-install.bash
```

Setup environment on another computer:

```shell
./remote-setup.bash

# To skip the prompts:
./remote-user.bash <username> <remote IP address> --yes
```

### Update

On main computer use `zerupdate`, on any other one use `zerupdate_online` to update from the latest version of the source code from this repository.
