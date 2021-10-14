#!/bin/bash -e

# Parts stolen / modified from https://github.com/classy-giraffe/easy-arch/blob/main/easy-arch.sh

# Global Vars (mainly for readability, these null strings aren't used before being overwritten by the rest of script)
BIOS=""
CPU=""
microcode=""
kernel=""
DISK=""
ESP=""
ROOT=""
HOME=""

# Functions

# Checks system for compatibility with script
function syscheck {
	if [ -e /sys/firmware/efi/efivars ]
                then
	                export BIOS="x86_64-efi"
        
                        # Checking the microcode to install.
                         CPU=$(grep vendor_id /proc/cpuinfo)
                        if [[ "$CPU" == *"AuthenticAMD"* ]]
                                then
                                        microcode=amd-ucode
                                else
                                        microcode=intel-ucode
                        fi

                else
                        echo "This script was designed for UEFI systems, so it will \n
	                    not work as intended on your system. Exiting..." 
                        exit 1
        fi

}

# Select the install disk
function whichdisk {
  # Selecting the target for the installation.
  PS3="Select the disk where Arch Linux is going to be installed: "
  select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
  do
    DISK=$ENTRY
    echo "Installing Arch Linux on $DISK."
    break
  done
}

# Wipe partition table
function wipesys {
  # Deleting old partition scheme.
  read -p "This will delete the current partition table on $DISK. Do you agree [y/N]? " response
  response=${response,,}
  if [[ "$response" =~ ^(yes|y)$ ]]
    then
        wipefs -af "$DISK" &>/dev/null
        sgdisk -Zo "$DISK" &>/dev/null
    else
        echo "Quitting."
        exit 1
  fi
}

# Create partitions on new partition table (includes home partition)
function homepart_layout {
  # Creating a new partition scheme including home partition.
  echo "Creating new partition scheme on $DISK."
  parted -s $DISK \
    mklabel gpt \
    mkpart ESP 1MiB 513MiB \
    mkpart Root 513MiB 51712MiB \
    mkpart Home 51713MiB 100% \

	# Formatting the ESP as FAT32.
	ESP="$DISK"1
	echo "Formatting the EFI Partition as FAT32."
	mkfs.fat -F 32 "$ESP" &>/dev/null

    ROOT="$DISK"2
    HOME="$DISK"3

    # Formatting the root and home partitions as ext4.
    echo "Formatting the Root Partition as ext4."
    mkfs.ext4 "$ROOT" &>/dev/null
    echo "Formatting the Home Partition as ext4."
    mkfs.ext4 "$HOME" &>/dev/null
}

# Create partitions on new partition table (excludes home partition)
function standard_parts {
  echo "Creating new partition scheme on $DISK."
  parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP 1MiB 513MiB \
    mkpart Root 513MiB 100% \

	# Formatting the ESP as FAT32.
	ESP="$DISK"1
	echo "Formatting the EFI Partition as FAT32."
	mkfs.fat -F 32 "$ESP" &>/dev/null

    ROOT="$DISK"2

    # Formatting the root partition as ext4.
    echo "Formatting the Root Partition as ext4."
    mkfs.ext4 "$ROOT" &>/dev/null
}

# Mount partitions for installation
function mount_partitions {
	#Unmount all partitions on /mnt (commented out for now)
    #umount -R /mnt
    
    mount "$ROOT" /mnt
    mkdir -p /mnt/boot
	mount "$ESP" /mnt/boot

	if [[ $HOME == "$DISK"3 ]]
	then
		mkdir -p /mnt/home
		mount "$HOME" /mnt/home
	fi
}


# Select how to handle internet post-install
function network_setup {
    echo "Network utilities:"
    echo "1) IWD — iNet wireless daemon is a wireless daemon for Linux written by Intel (WiFi-only)."
    echo "2) NetworkManager — Program for providing detection and configuration for systems to automatically connect to networks (both WiFi and Ethernet). - Preferred Option"
    echo "3) wpa_supplicant — It's a cross-platform supplicant with support for WEP, WPA and WPA2 (WiFi-only, a DHCP client will be automatically installed too.)"
    echo "4) I will do this on my own."
    read -r -p "Insert the number of the corresponding networking utility: " choice
    echo "$choice will be installed"
    case $choice in
        1 ) echo "Installing IWD."    
            pacstrap /mnt iwd
            echo "Enabling IWD."
            systemctl enable iwd --root=/mnt &>/dev/null
            ;;
        2 ) echo "Installing NetworkManager."
            pacstrap /mnt networkmanager
            echo "Enabling NetworkManager."
            systemctl enable NetworkManager --root=/mnt &>/dev/null
            ;;
        3 ) echo "Installing wpa_supplicant and dhcpcd."
            pacstrap /mnt wpa_supplicant dhcpcd
            echo "Enabling wpa_supplicant and dhcpcd."
            systemctl enable wpa_supplicant --root=/mnt &>/dev/null
            systemctl enable dhcpcd --root=/mnt &>/dev/null
            ;;
        4 )
            ;;
        * ) echo "You did not enter a valid selection."
            network_setup
    esac
}

# Select what kernel to install
function kernel_selector {
    echo "List of kernels:"
    echo "1) Stable — Vanilla Linux kernel and modules."
    echo "2) Hardened — A security-focused Linux kernel."
    echo "3) Longterm — Long-term support (LTS) Linux kernel and modules."
    echo "4) Zen Kernel — Optimized for desktop usage."
    read -r -p "Insert the number of the corresponding kernel: " choice
    echo "$choice will be installed."
    case $choice in
        1 ) kernel=linux
            ;;
        2 ) kernel=linux-hardened
            ;;
        3 ) kernel=linux-lts
            ;;
        4 ) kernel=linux-zen
            ;;
        * ) echo "You did not enter a valid selection."
            kernel_selector
    esac
}

# Clear tty for cleanliness
clear

# Begins install script with warnings but gives exit option
echo "This script is a work in progress, but is at this point mostly functional."
echo "This means that there may be some issues."

while true; do
	read -p "Continue? (Yy/Nn): " yn
    case $yn in
        [Yy]* ) echo "Continuing..."; break;;
        [Nn]* ) echo "Exiting..."; exit 1;;
        * ) echo "Please answer yes or no.";;
    esac
done


# Installation steps
#Ensures system clock is accurate
timedatectl set-ntp true 
syscheck
whichdisk

while true; do
	read -p "Do you want a home partition? (Yy/Nn): " yn
    case $yn in
        [Yy]* ) wipesys; homepart_layout; break;;
        [Nn]* ) wipesys; standard_parts; break;;
        * ) echo "Please answer yes or no.";;
    esac
done

kernel_selector
mount_partitions

# Pacstrap (setting up a base sytem onto the new root).
echo "Installing the base system (it may take a while)."
pacstrap /mnt base $kernel $microcode linux-firmware grub efibootmgr reflector base-devel os-prober

network_setup

# Generating /etc/fstab.
echo "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Setting hostname.
read -p "Please enter the hostname: " hostname
echo "$hostname" > /mnt/etc/hostname

# Set superuser name variable
read -p "Please enter name for the superuser account: " username

# Setting up locales.
read -p "Please insert the locale you use (format: xx_XX): " locale
echo "$locale.UTF-8 UTF-8"  > /mnt/etc/locale.gen
echo "LANG=$locale.UTF-8" > /mnt/etc/locale.conf

# Setting hosts file.
echo "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF


# Configuring the system.    
arch-chroot /mnt /bin/bash -e <<EOF
    
    # Setting up timezone.
    ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null
    
    # Setting up clock.
    hwclock --systohc
    
    # Generating locales.
    echo "Generating locales."
    locale-gen &>/dev/null
    
    # Installing GRUB.
    echo "Installing GRUB on /boot."
	grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB &>/dev/null
    
    # Creating grub config file.
    echo "Creating GRUB config file."
    grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

	# Enabling Reflector timer.
	echo "Enabling Reflector."
	systemctl enable reflector.timer &>/dev/null
EOF


# Setting root password and new superuser privileged login
arch-chroot /mnt << EOF
    # Set root password
    passwd
    
    # New superuser login
    echo "It is standard to create a new login to avoid using the elevated privileges of the root account."
    echo "Logging in as the root user is insecure, so a superuser account \n is set so root privileges can still be securely accessed when needed."
    
    echo "Adding superuser $username with root privilege."
    useradd -m $username
    usermod -aG wheel $username
    echo "$username ALL=(ALL) ALL" >> /etc/sudoers.d/$username
EOF

# Finishing up
echo "Done, you may now wish to reboot (further changes can be done by chrooting into /mnt)."
exit 0