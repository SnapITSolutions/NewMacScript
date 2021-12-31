# NewMacScript

Script for new Mac installations.

## About

This setup script is for setting up a new Mac with applications needed by developers.

Please feel free to alter this script to meet your specific needs.

## Installation with Curl

To install this script from a brand new Mac (fresh out of the box!), open `Terminal` and run the following command.

``` shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/staceybellerose/NewMacScript/main/setup.sh)"
```

## Terminal Tools (Manual Installation)

All of the following are commands that you can enter directly into Terminal or let the script run for you.

### [Homebrew](https://brew.sh/)

Homebrew is a third-party package manager for MacOS.

#### Install Homebrew

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew doctor
```

#### Update Homebrew

```shell
brew update
brew upgrade
```

### [iTerm2](https://www.iterm2.com/)

iTerm2 is a better terminal.

```shell
brew cask install iterm2
```

### Git

```shell
brew install git
```

### Ruby

Ruby is installed using `rvm`.

```shell
bash -c "$(curl -sSL https://get.rvm.io | bash -s stable --ruby)"
gem install rails
gem install bundler
```

### zsh

zsh isn't installed by this script. For more details, see [this page](./zsh.md).

### more tools

The setup script installs even more tools. Read through the script for more details!

## The End
