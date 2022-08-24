#!/usr/bin/sh

sudo apt install htop
sudo apt-get install fish
echo "set fish_greeting" >> ~/.config/fish/config.fish
ssh-keygen -b 2048 -t rsa -f .ssh/id_rsa -q -N ""
cat ~/.ssh/id_rsa.pub

## git
sudo apt-get update
sudo apt-get install git
cd ~/Till
git config --global user.name "Till Lehmann"
git config --global user.email "till.lehmann@student.hpi.de"
git clone git@gitlab.hpi.de:till.lehmann/mt-fpga-alignment.git --recurse-submodules
cd mt-fpga-alignment

## Atom
cd ~/Downloads
wget -qO - https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
sudo apt-get update
sudo apt-get install atom

## Hyper
cd ~/Downloads
sudo apt-get install qapt-deb-installer gdebi-core
wget -O hyper https://releases.hyper.is/download/deb
sudo gdebi hyper

## Clion
sudo apt install clang-format
sudo apt install build-essential
sudo snap install clion --classic

## Fonts
sudo apt install fonts-firacode

## Python
sudo apt install python3-pip
sudo -H pip3 install black[d]

# OpenVPN
sudo apt update
sudo apt install openvpn-systemd-resolved
