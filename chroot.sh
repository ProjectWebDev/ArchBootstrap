#!/bin/bash

echo "Personalized Arch Installer Part 2"

# Variables
HOST= arch-linux
USER= user

# Localization
echo en_US.UTF-8 UTF-8 > /etc/locale.gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
locale-gen

# System Configuration
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc
echo $HOST > /etc/hostname
echo "127.0.0.1	$HOST.localdomain $HOST" >> /etc/hosts

# Bootloader
sudo pacman -s refind-efi amd-ucode
refind-install
mkrlconf

echo This concludes Part 2 of the Personalized Arch Installer. You will now be exited out of the chroot. After this, you will need to unmount the partitions and shutdown the system in order to remove the installation media.
echo Goodbye!
exit
