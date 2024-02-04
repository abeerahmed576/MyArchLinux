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
echo "Server=$mirror_url/$repo/os/$arch" >> /etc/pacman.d/mirrorlist

## Changing some pacman configuration using sed
sed -i -e '/Color/s/#//' -e '/ParallelDownloads/s/#//' -e '/Color/a ILoveCandy' /etc/pacman.conf

## Enabling Bangla(BD) and English(US) locale
sed -i -e '/bn_BD/s/#//' -e '/en_US.UTF-8/s/#//' /etc/locale.gen

locale-gen

## Setting English(US) as system language
echo "LANG=en_US.UTF-8" > /etc/locale.conf

## Setting size 122 of terminus-font for tty
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

pkglist=/home/MyArchLinux/pkglist.txt
pacman -S --needed - < $pkglist

## Installing systemd-boot
bootctl install

## Defining minimum necessary kernel options in /etc/kernel/cmdline for kernel-install to use when creating bootloader entries. This is also necessary for installation in a chroot as kernel-install will pick up kernel options of the live ISO's kernel which we don't want.
root_part=$(bootctl -R)
root_uuid=$(blkid -o value -s UUID $root_part)
machineID=$(cat /etc/machine-id)

# The "rootflags" option is only needed for btrfs. If using ext2/3/4, remove this option.
echo "root=UUID=$root_uuid rootflags=subvol=/@ rw loglevel=3 systemd.machine_id=$machineID" > /etc/kernel/cmdline

## Using kernel-install for placing kernel and initramsfs images at the required places for systemd-boot and automatic bootloader entry.
kernel_vers=$(ls /usr/lib/modules)

for version in ${kernel_vers[@]}; do
    kernel-install add "$version" /usr/lib/modules/"$version"/vmlinuz
    done

## Cleanup of /boot as kernel and initramsfs images created by mkinitcpio in this directory are useless for systemd-boot
rm /boot/vmlinuz* /boot/initramfs*

## Setting password for root account
echo "Password for Root"
passwd root

## Creating a user account and setting password for it
username=abeer
# Write full name in quotes
full_name="Abeer Ahmed"

useradd -m -G wheel -c "$full_name" $username

echo "Password for $username"
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
folders=$(ls /MyFiles)

for folder in ${folders[@]}; do
    ln -s /MyFiles/"$folder" /home/$username
    done
