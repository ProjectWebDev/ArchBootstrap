#!/bin/bash

echo "Personalized Arch Installer Part 1"
echo "Any changes that need to be made must be made in this script using any text editor (vim, nano, etc)."

# Pre-Install
if [ "$(find /sys/firmware/efi/efivars 2>/dev/null | wc -l)" != 0 ]
then echo "This system is running UEFI Firmware."
else echo "This system is running Legacy BIOS Firmware."
fi

##Wireless Setup
###This isn't needed for ethernet because it is enabled on boot
systemctl enable --now dhcpcd.service
ping -c3 archlinux.org > /dev/null 2>&1
if [ $? -eq 0 ] ;
then echo You are connected to the internet, continuing ; exit 0
else echo You are not connected to the internet, exiting ; exit 1
fi

timedatectl set-ntp true

#Install
##Partitioning
echo "The following program will now allow you to create and edit the partition scheme for the disk of your choosing."
echo "A list of potential disks to install Arch Linux on will now appear."
lsblk
echo "Please choose a disk. The standard disk is /dev/sda, however you may choose a different disk."
echo "If this system uses UEFI Firmware, you will also need to create an EFI System Partiton (ESP), if one does not already exist."
echo "Which disk do you wish to use? (eg. /dev/sda)"
echo "Input choice here: "
read -rp DISK
cfdisk "$DISK"
echo "This script assumes that /dev/sda1 is the ESP, /dev/sda2 is the swap partition, and /dev/sda3 is the root partition."
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda3
mkswap /dev/sda2
swapon /dev/sda2

##Mounting
mount /dev/sda3 /mnt
mkdir /mnt/efi
mount /dev/sda1 /mnt/efi

##Installation
pacstrap /mnt base base-devel linux linux-firmware vim NetworkManager
genfstab -U /mnt >> /mnt/etc/fstab

echo "Part 1 of this script has finished. Please run Part 2 in an arch-chroot."
