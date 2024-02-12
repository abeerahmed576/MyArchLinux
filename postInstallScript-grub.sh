#!/bin/bash

## Only for btrfs filesystem - Setting the correct ID for @ subvolume
#btrfs subvol set-default 256 /

## Using desired timezone
region=Asia
city=Dhaka

ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime

## Syncing system to hardware clock using UTC format
hwclock --systohc --utc

## Setting pacman BD mirror
mirror_url="http://mirror.xeonbd.com/archlinux"

echo "## Bangladesh" > /etc/pacman.d/mirrorlist
echo "Server=$mirror_url/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist

## Changing some pacman configuration using sed
sed -i -e '/Color/s/#//' -e '/ParallelDownloads/s/#//' -e '/Color/a ILoveCandy' /etc/pacman.conf

## Enabling Bangla(BD) and English(US) locale
sed -i -e '/bn_BD/s/#//' -e '/en_US.UTF-8/s/#//' /etc/locale.gen

locale-gen

## Setting English(US) as system language
echo "LANG=en_US.UTF-8" > /etc/locale.conf

## Setting size 122 of terminus-font for tty. The package "terminus-font" is needed to be installed for this.
echo "FONT=ter-122n" > /etc/vconsole.conf

## Setting the hostname
system_hostname=rajshahi-home

echo $system_hostname > /etc/hostname

## Configuring for localhost
echo -e "\n127.0.0.1	localhost\n
## For IPv6
::1		localhost\n
127.0.0.1	$system_hostname" >> /etc/hosts

## Installing additional packages (with KDE)
pacman -Syy

pkglist=/home/MyArchLinux/pkglist-grub.txt
pacman -S --needed - < $pkglist

## Installing Grub for UEFI on an NVME SSD
esp_path=$(findmnt -nr -o TARGET /dev/nvme0n1p1)
os_name="Arch Linux"

grub-install --target=x86_64-efi --efi-directory=$esp_path --bootloader-id="$os_name"
grub-mkconfig -o /boot/grub/grub.cfg

## Setting password for root account
printf "\e[1;32mPassword for Root\e[0m\n"
passwd root

## Creating a user account, adding the user to wheel group and setting password for the account
username=abeer
# Write full name in quotes
full_name="Abeer Ahmed"

useradd -m -G wheel -c "$full_name" $username

printf "\e[1;32mPassword for $username\e[0m\n"
passwd $username

## Giving all memebers of wheel group privilege to execute any command
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/all-for-wheel

## Enabling necessary systemd services
systemctl enable avahi-daemon
systemctl enable haveged.service
#systemctl enable bluetooth.service
#systemctl enable cups.service
systemctl enable fstrim.timer
systemctl enable sddm.service
systemctl enable NetworkManager
systemctl enable upower
#systemctl enable sshd
#systemctl enable reflector.timer
#systemctl enable firewalld

## Making links of folders in personal files partition to ~/
folders=$(ls /MyHome)

for folder in ${folders[@]}; do
    ln -s /MyHome/"$folder" /home/$username
    done

## Completion message
printf "\e[1;32mDone! Now, if no other changes left to make, exit the chroot, run \"umount -R /mnt\" and reboot.\e[0m\n"
