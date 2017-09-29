#!/bin/bash

KVM="-enable-kvm"
USER="ubuntu"
DOWNLOAD_URL="http://archive.ubuntu.com/ubuntu/dists/yakkety/main/installer-amd64/current/images/netboot/"
DOWNLOAD_ISO="mini.iso"
BASE_IMAGE="ubuntu.qcow2"
CPU="host"
NUM_CPUS="4"
# Needs at least 256M to boot.
MEMORY="512M"
# Needs 1G to install, more than 2 to be useful.
BASE_DISK_SIZE="5G"
LOCAL_SSH_PORT="5022"
GRAPHICS="-nographic"
REBOOT="-no-reboot"
CLONE_URL="http://github.com/iankronquist/rustyvisor"
SERIAL_FILE="./serial.txt"
KEY_FILE="./sshkey"


install() {
	if ! [ -e $DOWNLOAD_ISO ]; then
		wget $DOWNLOAD_URL$DOWNLOAD_ISO
	fi
	if [ -e $BASE_IMAGE ]; then
		echo "$BASE_IMAGE already exists. Skipping install"
		exit
	fi
	qemu-img create -f qcow2 $BASE_IMAGE $BASE_DISK_SIZE

	qemu-system-x86_64 $KVM -cdrom $DOWNLOAD_ISO -hda $BASE_IMAGE -boot d -m $MEMORY $REBOOT -smp $NUM_CPUS
	echo "Manually install ubuntu."
	echo "We recommend you name your user ubuntu and install openssh."
}

boot() {
	qemu-system-x86_64 $KVM -hda $BASE_IMAGE  -redir tcp:$LOCAL_SSH_PORT::22 -m $MEMORY  -cpu $CPU $REBOOT -smp $NUM_CPUS -serial file:$SERIAL_FILE $GRAPHICS
}

debug() {
	qemu-system-x86_64 -s -hda $BASE_IMAGE  -redir tcp:$LOCAL_SSH_PORT::22 -m $MEMORY  $REBOOT -smp $NUM_CPUS $GRAPHICS -serial file:$SERIAL_FILE -D qemu_logs.txt -d exec,int,cpu_reset --append "console=ttyS0 debug kvm-intel.nested=1"
}

login() {
	ssh -i $KEY_FILE -p $LOCAL_SSH_PORT $USER@localhost
}

provision() {
	ssh-keygen -N '' -f $KEY_FILE
	ssh-copy-id -i $KEY_FILE -p $LOCAL_SSH_PORT $USER@localhost

ssh -i $KEY_FILE -p $LOCAL_SSH_PORT $USER@localhost 'bash -s' <<EOT
	
	#sudo apt-get install curl
	#sudo apt-get install linux-headers-\$(uname -r) gcc make git vim
	curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain=nightly -y;
	git clone $CLONE_URL
	#source ~/.cargo/env

	#echo "source ~/.cargo/env" >> ~/.bashrc
	echo "alias v=vim" >> ~/.bashrc
	echo "alias gs='git status'" >> ~/.bashrc
	echo "alias gap='git add -p'" >> ~/.bashrc

	echo "set spell" >> ~/.vimrc
	echo "syntax on" >> ~/.vimrc
	echo "set number" >> ~/.vimrc
	echo "au BufRead,BufNewFile *.rs setfiletype rust" >> ~/.vimrc
	echo "autocmd BufRead,BufNewFile *.rs setlocal expandtab syntax=rust" >> ~/.vimrc
	mkdir -p ~/.vim/syntax

	rustup install nightly
	rustup default nightly
	rustup component add rust-src
	cargo install xargo
	cargo install rustfmt
	cargo install clippy
EOT

	scp -i $KEY_FILE -P $LOCAL_SSH_PORT ./rust.vim $USER@localhost:~/.vim
}

copy() {
	scp -i $KEY_FILE -P $LOCAL_SSH_PORT -r $1 $USER@localhost:$2
}

help() {
	echo "Usage: $0 boot | login | install | provision | debug | help"
	echo "boot: Start the VM."
	echo "login: SSH into the VM."
	echo "install: Download ISO and create image."
	echo "copy: Copies from the host source to the guest destination"
	echo "provision: Install Rust and Rustyvisor."
	echo "debug: Launch QEMU in debug mode."
	echo "       Wait for a minute before connecting GDB."
	echo "       To connect GDB run the following command at the GDB prompt:"
	echo "       target remote localhost:1234"
	echo "help: This cruft."
	exit -1
}

if [[ $# == 0 || $1 == "-h" || $1 == "--help" || $1 == "help" ]]; then
	help
fi

$@
