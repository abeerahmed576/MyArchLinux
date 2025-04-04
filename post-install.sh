#!/bin/bash

##### Variables Section #####
region=Asia  # For time zone
city=Dhaka  # For time zone
system_lang="en_US.UTF-8"
mirror_url="http://mirror.xeonbd.com/archlinux"
system_hostname=rajshahi-home
os_name="Arch Linux"
username=abeer
full_name="Abeer Ahmed"  # Write full name in quotes

offine_install_config="--config pacman-offline.conf"
##### Variables Section #####

## Using desired timezone
ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime

## Syncing system to hardware clock using UTC format
hwclock --systohc --utc

## Setting pacman BD mirror
echo "## Bangladesh
Server=$mirror_url/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

## Changing some pacman configuration using sed
sed -i -e '/Color/s/#//' -e '/ParallelDownloads/s/#//' -e '/Color/a ILoveCandy' /etc/pacman.conf

## Enabling Bangla(BD) and English(US) locale
sed -i -e '/bn_BD/s/#//' -e '/en_US.UTF-8/s/#//' /etc/locale.gen

locale-gen

## Setting English(US) as system language
echo "LANG=$system_lang" > /etc/locale.conf

## Setting size 122 of terminus-font for tty. The package "terminus-font" is needed to be installed for this.
echo "FONT=ter-122n" > /etc/vconsole.conf

## Setting the hostname
echo $system_hostname > /etc/hostname

## Configuring for localhost
echo -e "\n127.0.0.1	localhost\n
## For IPv6
::1		localhost\n
127.0.0.1	$system_hostname" >> /etc/hosts

## Masking pacman hooks for mkinitcpio as we'll be using kernel-install for systemd-boot
mkdir -p /etc/pacman.d/hooks

ln -s /dev/null /etc/pacman.d/hooks/60-mkinitcpio-remove.hook
ln -s /dev/null /etc/pacman.d/hooks/90-mkinitcpio-install.hook

## Installing necessary packages
pacman -Syy

pkglist=pkglist.txt
#pkglist_kde=pkglist-KDE.txt

pacman -S --needed $offine_install_config - < $pkglist
#pacman -S --needed $offine_install_config - < $pkglist_kde  # For KDE
#pacman -S --needed $offine_install_config cosmic  # For Cosmic DE
#pacman -S --needed $offine_install_config gnome  # For Gnome DE

## Installing systemd-boot
bootctl --efi-boot-option-description="$os_name" install

## Defining minimum necessary kernel options in /etc/kernel/cmdline for kernel-install to use when creating bootloader entries. This is also necessary for installation in a chroot as kernel-install will pick up kernel options of the live ISO's kernel which we don't want.
root_part=$(bootctl -R)
root_uuid=$(blkid -o value -s UUID $root_part)
machineID=$(cat /etc/machine-id)

# The "rootflags" option is only needed for btrfs. If using ext2/3/4, remove this option.
echo "root=UUID=$root_uuid rootflags=subvol=/@ rw loglevel=3 systemd.machine_id=$machineID" > /etc/kernel/cmdline

## Using kernel-install for placing kernel and initramsfs images at the required places for systemd-boot and automatic bootloader entry.
readarray -t kernel_vers < <(ls /usr/lib/modules)

for version in "${kernel_vers[@]}"; do
    kernel-install add $version /usr/lib/modules/$version/vmlinuz
done

## Cleanup of /boot as kernel and initramsfs images generated by mkinitcpio in this directory are useless for systemd-boot
rm /boot/vmlinuz* /boot/initramfs*

## (If installing GRUB, uncomment lines 91-94) Installing Grub for UEFI
# esp_path=$(findmnt -nr -o TARGET /dev/nvme0n1p1)
# esp_path=$(bootctl -p)
#
# grub-install --target=x86_64-efi --efi-directory=$esp_path --bootloader-id="$os_name"
# grub-mkconfig -o /boot/grub/grub.cfg

## Setting password for root account
printf "\e[1;32mPassword for Root\e[0m\n"
passwd root

## Creating a user account, adding the user to wheel group and setting password for the account
useradd -m -G wheel -c "$full_name" -s /usr/bin/zsh $username

printf "\e[1;32mPassword for $username\e[0m\n"
passwd $username

## Giving all memebers of wheel group privilege to execute any command
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/all-for-wheel

## Enabling necessary background services
systemctl enable avahi-daemon
systemctl enable haveged.service
systemctl enable fstrim.timer
systemctl enable NetworkManager
systemctl enable upower
#systemctl enable sshd
#systemctl enable reflector.timer
#systemctl enable firewalld
#systemctl enable bluetooth.service
#systemctl enable cups.service  # For printing service. The package "cups" is needed to be installed
systemctl enable systemd-boot-update.service
#systemctl enable snapper-timeline.timer
#systemctl enable snapper-cleanup.timer

#systemctl enable sddm.service  # For KDE
#systemctl enable cosmic-greeter.service  # For Cosmic DE
#systemctl enable gdm.service  # For Gnome DE

## Making links to folders in personal files partition in ~/
#readarray -t folders < <(ls /MyHome)

#for folder in "${folders[@]}"; do
#    ln -s /MyHome/$folder /home/$username
#done

## Only for btrfs filesystem - Setting the correct ID for @ subvolume
btrfs subvol set-default 256 /

## Completion message
printf "\e[1;32mDone! Now, if no other changes left to make, exit the chroot, run \"umount -R /mnt\" and reboot.\e[0m\n"
