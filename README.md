# Ubuntu VM image

```
Usage: ./qemu.sh <command>
Commands:
boot: Start the VM.
login: SSH into the VM.
copy: Copies files from the host source to the guest destination
install: Download ISO and create image.
provision: Install Rust and Rustyvisor.
debug: Launch QEMU in debug mode.
       Wait for a minute before connecting GDB.
       To connect GDB run the following command at the GDB prompt:
       target remote localhost:1234
help: This cruft.
```
