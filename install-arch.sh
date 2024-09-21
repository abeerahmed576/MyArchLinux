efi_part=/dev/nvme0n1p1
boot_part=/dev/nvme0n1p2
root_part=/dev/nvme0n1p5
root_part_label="Arch Cosmic"
btrfs_subvols=@home,@root,@tmp,@log,@cache,@snapshots
btrfs_subvols_mountpoints=home,root,tmp,var/log,var/cache,.snapshots

## Formatting partitions
#mkfs.fat -F 32 -n EFI $efi_part
#mkfs.fat -F 32 -n BOOT $boot_part
mkfs.btrfs -f -L "$root_part_label" $root_part

## Mounting Root partition and creating specified subvolumes
readarray -t btrfs_subvols_array < <(awk -F ',' '{ for( i=1; i<=NF; i++ ) print $i }' <<< "$btrfs_subvols")
readarray -t btrfs_subvols_mountpoints_array < <(awk -F ',' '{ for( i=1; i<=NF; i++ ) print $i }' <<< "$btrfs_subvols_mountpoints")
#btrfs_subvols_list_length=${#btrfs_subvols_array[@]}

mount $root_part /mnt
btrfs subvol create /mnt/@

for subvol in "${btrfs_subvols_array[@]}"; do
  btrfs subvol create /mnt/$subvol
done

umount /mnt

## Re-mounting Root partition with all the subvolumes

mount -o compress=zstd:1,noatime,subvol=@ $root_part /mnt
mkdir -p /mnt/{efi,boot,MyHome}  # Creating directories for EFI, BOOT and other desired mountpoints

for mountpoint in "${btrfs_subvols_mountpoints_array[@]}"; do
  mkdir -p /mnt/$mountpoint
done

for i in "${!btrfs_subvols_array[@]}"; do
  mount -o compress=zstd:1,noatime,subvol=${btrfs_subvols_array[$i]} $root_part /mnt/${btrfs_subvols_mountpoints_array[$i]}
done

## Mounting EFI and BOOT partition
mount -o umask=0077 $efi_part /mnt/efi
mount -o umask=0077 $boot_part /mnt/boot

## Setting Pacman mirror
echo "## Bangladesh
Server=http://mirror.xeonbd.com/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

## Installing base packages
pacstrap -Ki /mnt base base-devel git nano reflector rsync

## Generating File System table
genfstab -U /mnt >> /mnt/etc/fstab
