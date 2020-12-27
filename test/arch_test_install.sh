#/bin/bash

partition() {
parted --script /dev/sda \
	    mklabel gpt \
	    mkpart primary 1MiB 100MiB set 1 bios_grub on \
	    'mkpart primary 101MiB -1'
mkfs.ext4 /dev/sda2
}

partition
mount /dev/sda2 /mnt
pacstrap /mnt base linux linux-firmware
genfstab -L /mnt >> /mnt/etc/fstab
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/EST /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
echo runner > /etc/hostname
cat > /etc/hosts <<- EOM
127.0.0.1	localhost
::1		localhost
127.0.1.1	runner.localdomain	runner
EOM
echo "root:321321" | chpasswd
