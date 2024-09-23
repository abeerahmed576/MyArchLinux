##### Variables Section #####
efi_part=/dev/nvme0n1p1
boot_part=/dev/nvme0n1p2
root_part=/dev/nvme0n1p5
root_part_label="Arch Cosmic"

btrfs_subvols=@home,@root,@tmp,@log,@cache,@snapshots
btrfs_subvols_mountpoints=home,root,tmp,var/log,var/cache,.snapshots

myhome_part=/dev/nvme0n1p6
myhome_part_mountpoint=MyHome

mirror_url="http://mirror.xeonbd.com/archlinux"
##### Variables Section #####

## Formatting partitions
#mkfs.fat -F 32 -n EFI $efi_part
#mkfs.fat -F 32 -n BOOT $boot_part
mkfs.btrfs -f -L "$root_part_label" $root_part

## Mounting Root partition and creating specified subvolumes
readarray -t btrfs_subvols_array < <(awk -F ',' '{ for( i=1; i<=NF; i++ ) print $i }' <<< "$btrfs_subvols")
readarray -t btrfs_subvols_mountpoints_array < <(awk -F ',' '{ for( i=1; i<=NF; i++ ) print $i }' <<< "$btrfs_subvols_mountpoints")
#btrfs_subvols_list_length=${#btrfs_subvols_array[@]}  # The Hashtag(#) before array name is needed when calculating the length of an array

mount $root_part /mnt
btrfs subvol create /mnt/@

for subvol in "${btrfs_subvols_array[@]}"; do
  btrfs subvol create /mnt/$subvol
done

umount /mnt

## Re-mounting Root partition with all the subvolumes

mount -o compress=zstd:1,noatime,subvol=@ $root_part /mnt
mkdir -p /mnt/{efi,boot,"$myhome_part_mountpoint"}  # Creating directories for EFI, BOOT and other desired mountpoints

# Creating mountpoint directories
for mountpoint in "${btrfs_subvols_mountpoints_array[@]}"; do
  mkdir -p /mnt/$mountpoint
done

for i in "${!btrfs_subvols_array[@]}"; do  # If wanting to use indices/index when looping through an array, we have to append a "!" before the array name eg. "{!array[@]}"
  mount -o compress=zstd:1,noatime,subvol=${btrfs_subvols_array[$i]} $root_part /mnt/${btrfs_subvols_mountpoints_array[$i]}
done

## Mounting EFI, BOOT and other desired partitions
mount -o umask=0077 $efi_part /mnt/efi
mount -o umask=0077 $boot_part /mnt/boot
mount -o defaults,noatime $myhome_part /mnt/$myhome_part_mountpoint

## Setting pacman BD mirror
echo "## Bangladesh
Server=$mirror_url/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

## Enabling Color and ParallelDownloads options, disabling "core" and "extra" repo (So that pacman doesn't fail on the default repositories ) and enabling custom offline repo
#sed -e '/Color/s/#//' -e '/ParallelDownloads/s/#//' -e '/\[core\]/{s/^/#/; n; s/^/#/}' -e '/\[extra\]/{s/^/#/; n; s/^/#/}' -e "/\[custom\]/{s/#//; n; s/#//; n; s|.*|Server = file:///mnt/${myhome_part_mountpoint}/arch-pkgs/|}" /etc/pacman.conf

## Enabling Color and ParallelDownloads options, disabling "core" and "extra" repo (So that pacman doesn't fail on the default repositories ) and enabling custom offline repo
sed -i -e '/Color/s/#//' -e '/ParallelDownloads/s/#//' -e '/\[core\]/{s/^/#/; n; s/^/#/}' -e '/\[extra\]/{s/^/#/; n; s/^/#/}' /etc/pacman.conf

echo "[offline]
SigLevel = Optional TrustAll
Server = file:///mnt/MyHome/arch-pkgs/" >> /etc/pacman.conf

## Installing base packages
pacstrap -Ki /mnt base base-devel

## Generating File System table
genfstab -U /mnt >> /mnt/etc/fstab
