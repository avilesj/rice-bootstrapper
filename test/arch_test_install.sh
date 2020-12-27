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
pacstrap /mnt base linux linux-firmware grub
genfstab -L /mnt >> /mnt/etc/fstab
arch-chroot /mnt ln -sf /usr/share/zoneinfo/EST /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
echo runner > /mnt/etc/hostname
cat > /mnt/etc/hosts <<- EOM
127.0.0.1	localhost
::1		localhost
127.0.1.1	runner.localdomain	runner
EOM
arch-chroot /mnt echo "root:321321" | chpasswd
arch-chroot /mnt grub-install --target=i386-pc --recheck /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
