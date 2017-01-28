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


install() {
	if ! [ -e $DOWNLOAD_ISO ]; then
		wget $DOWNLOAD_URL$DOWNLOAD_ISO
	fi
	if [ -e $BASE_IMAGE ]; then
		echo "$BASE_IMAGE already exists. Skipping install"
		exit
	fi
	qemu-img create -f qcow2 $BASE_IMAGE $BASE_DISK_SIZE

	qemu-system-x86_64 $KVM -cdrom $DOWNLOAD_ISO -hda $BASE_IMAGE -boot d -m $MEMORY -cpu $CPU $REBOOT -smp $NUM_CPUS
	echo "Manually install ubuntu."
	echo "We recommend you name your user ubunu and install openssh."
}

boot() {
	qemu-system-x86_64 $KVM -hda $BASE_IMAGE  -redir tcp:$LOCAL_SSH_PORT::22 -m $MEMORY  -cpu $CPU $REBOOT -smp $NUM_CPUS $GRAPHICS &
	echo "Waiting for ubuntu to boot."
	sleep 1
	ssh -p $LOCAL_SSH_PORT $USER@localhost
}

login() {
	ssh -p $LOCAL_SSH_PORT $USER@localhost
}

provision() {
ssh -p $LOCAL_SSH_PORT $USER@localhost 'bash -s' <<EOT
	
	#sudo apt-get install curl
	#sudo apt-get install linux-headers-$$(uname -r) gcc make git
	curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain=nightly -y;
	git clone $CLONE_URL
	source ~/.cargo/env
	echo "source ~/.cargo/env" >> ~/.bashrc
	rustup install nightly
	rustup default nightly
	rustup component add rust-src
	cargo install xargo
	cargo install rustfmt
	cargo install clippy
EOT
}

help() {
	echo "Usage: $0 boot | login | install | provision | help"
	echo "boot: Start the VM and SSH into it."
	echo "login: SSH into the VM."
	echo "install: Download ISO and create image."
	echo "provision: Install Rust and Rustyvisor."
	echo "help: This cruft."
	exit -1
}

if [[ $# != 1 || $1 == "-h" || $1 == "--help" || $1 == "help" ]]; then
	help
fi

$@
