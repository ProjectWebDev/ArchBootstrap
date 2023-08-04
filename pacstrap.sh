#!/bin/bash
# Begins install script with warnings but gives exit option
echo "This script makes a lot of assumptions, but this was meant as a learning experience and was never intended to be put into practice."
echo "What this script assumes:
	- A network connection is established
	- The defaut keyboard layout is being used
	- The system has already been manually been partitioned and mounted"

echo "This script assumes that the user is using the default keyboard layout. \n
If you wish to change the layout you must exit this script first."

while true; do
	read -p "Continue? (Yy/Nn): " yn
    case $yn in
        [Yy]* ) echo "Continuing..."; break;;
        [Nn]* ) echo "Exiting..."; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Check BIOS type and set environment variable for later
#if ls /sys/firmware/efi/efivars 2>&/dev/null; then
#	echo "This system is running a UEFI BIOS. This will be important when \n
#	configuring partitions and installing a bootloader."
#   export BIOS="uefi" 
#else
#	echo "This system is running a Legacy BIOS. This will be important when \n
#	configuring partitions and installing a bootloader."
#	export BIOS="legacy"

# Networking
echo "This script assumes a network connection is already established, however \n
a networking daemon will be installed and enabled later."

# Installation steps
#Ensures system clock is accurate
timedatectl set-ntp true

# Disk partitioning
## This is where an efi system partition may need to be created
lsblk
echo "Above is a list of potential disks to install to. Usually the best option is /dev/sda \n
but this may not be the case if you have multiple disks. The easiest way to check is by looking at the disk size."

read -p "Select a disk: " disk

echo "cfdisk will now open for manual disk partitioning" # An automatic option may be implemented in the future
if BIOS="uefi"
	echo "Because this is a UEFI system, an EFI System Partition will be required. A safe size is usually \n
	around 512MB. This script assumes the ESP is created first."
else
	echo "Because this is a Legacy system, it is recommended to leave 2MB at the start of \n
	the disk for the bootloader. However, this is not required."
sleep 7
cfdisk $disk

# Mounting partitions
echo ""

mkdir /mnt/home
mkdir /mnt/boot
mount 
arch-chroot $disk