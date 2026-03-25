#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# encrypt-root.sh — LUKS2 encryption for nvme0n1p2 (btrfs root)
# ══════════════════════════════════════════════════════════════
#
# REQUIREMENTS:
#   - Boot from Arch Linux live USB
#   - Full backup verified on /data (sda1) before proceeding
#   - ~1TB free space on /data for temporary btrfs send/receive
#
# DISK LAYOUT (current):
#   nvme0n1p1  512MB  FAT32  /boot  (ESP — stays unencrypted)
#   nvme0n1p2  931GB  btrfs  /      (subvols: @, @home, @snapshots, @swap, @cache, @pkg, @log, @tmp)
#
# DISK LAYOUT (target):
#   nvme0n1p1  512MB  FAT32  /boot  (ESP — stays unencrypted)
#   nvme0n1p2  931GB  LUKS2 → btrfs (same subvols, encrypted at rest)
#
# ESTIMATED TIME: 30-60 minutes depending on data size
#
# ══════════════════════════════════════════════════════════════
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DEVICE="/dev/nvme0n1p2"
MAPPER_NAME="cryptroot"
BACKUP_DIR="/mnt/data/backup/pre-encryption"
BTRFS_UUID="04bdeb1e-dde7-47bd-ad09-54c7b74e69fc"

echo -e "${RED}══════════════════════════════════════════════════════════════${NC}"
echo -e "${RED} FULL DISK ENCRYPTION — THIS WILL REFORMAT nvme0n1p2        ${NC}"
echo -e "${RED} Run from Arch Live USB ONLY. NOT from the installed system. ${NC}"
echo -e "${RED}══════════════════════════════════════════════════════════════${NC}"
echo ""

# ─── Safety checks ───
if [ "$(hostname)" = "sl1c3d-l4bs" ]; then
    echo -e "${RED}ERROR: You are running from the installed system.${NC}"
    echo "Boot from a live USB first."
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Must run as root."
    exit 1
fi

echo -e "${YELLOW}Step 1: Mount backup drive${NC}"
mkdir -p /mnt/data
mount /dev/sda1 -o subvol=/@data /mnt/data
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}Step 2: Mount source btrfs${NC}"
mkdir -p /mnt/source
mount "$DEVICE" -o subvol=/ /mnt/source

echo -e "${YELLOW}Step 3: Snapshot and send all subvolumes to backup${NC}"
for subvol in @ @home @snapshots @cache @pkg @log @tmp; do
    echo "  Sending $subvol..."
    if [ -d "/mnt/source/$subvol" ]; then
        # Create read-only snapshot for send
        btrfs subvolume snapshot -r "/mnt/source/$subvol" "/mnt/source/${subvol}.backup"
        btrfs send "/mnt/source/${subvol}.backup" | btrfs receive "$BACKUP_DIR/"
        btrfs subvolume delete "/mnt/source/${subvol}.backup"
    fi
done
# @swap is special — recreate empty, don't backup
echo "  Skipping @swap (will recreate empty)"

umount /mnt/source

echo -e "${YELLOW}Step 4: Create LUKS2 container${NC}"
echo -e "${RED}You will be prompted for a passphrase. Choose a STRONG one.${NC}"
cryptsetup luksFormat --type luks2 \
    --cipher aes-xts-plain64 \
    --key-size 512 \
    --hash sha512 \
    --pbkdf argon2id \
    --iter-time 3000 \
    "$DEVICE"

echo -e "${YELLOW}Step 5: Open LUKS container${NC}"
cryptsetup open "$DEVICE" "$MAPPER_NAME"

echo -e "${YELLOW}Step 6: Create btrfs filesystem inside LUKS${NC}"
mkfs.btrfs -L archroot "/dev/mapper/$MAPPER_NAME"

echo -e "${YELLOW}Step 7: Mount and create subvolumes${NC}"
mount "/dev/mapper/$MAPPER_NAME" /mnt/source
for subvol in @ @home @snapshots @swap @cache @pkg @log @tmp; do
    btrfs subvolume create "/mnt/source/$subvol"
done

echo -e "${YELLOW}Step 8: Receive backed-up subvolumes${NC}"
umount /mnt/source
mount "/dev/mapper/$MAPPER_NAME" -o subvol=/ /mnt/source

for subvol in @ @home @snapshots @cache @pkg @log @tmp; do
    if [ -d "$BACKUP_DIR/${subvol}.backup" ]; then
        echo "  Receiving $subvol..."
        # Delete the empty subvol we just created
        btrfs subvolume delete "/mnt/source/$subvol"
        btrfs send "$BACKUP_DIR/${subvol}.backup" | btrfs receive /mnt/source/
        # Rename from .backup to original name
        mv "/mnt/source/${subvol}.backup" "/mnt/source/$subvol"
        # Make writable again
        btrfs property set "/mnt/source/$subvol" ro false
    fi
done

echo -e "${YELLOW}Step 9: Create swap subvol${NC}"
btrfs subvolume create /mnt/source/@swap
truncate -s 0 /mnt/source/@swap/swapfile
chattr +C /mnt/source/@swap/swapfile
fallocate -l 8G /mnt/source/@swap/swapfile
chmod 600 /mnt/source/@swap/swapfile
mkswap /mnt/source/@swap/swapfile

echo -e "${YELLOW}Step 10: Update fstab and crypttab${NC}"
NEW_UUID=$(blkid -s UUID -o value "/dev/mapper/$MAPPER_NAME")
LUKS_UUID=$(blkid -s UUID -o value "$DEVICE")

# Mount the root subvol to edit configs
umount /mnt/source
mount "/dev/mapper/$MAPPER_NAME" -o subvol=@ /mnt/source

# Create crypttab
echo "cryptroot  UUID=$LUKS_UUID  none  luks,discard" > /mnt/source/etc/crypttab

# Update fstab — replace old UUID with new one
sed -i "s/$BTRFS_UUID/$NEW_UUID/g" /mnt/source/etc/fstab

echo -e "${YELLOW}Step 11: Update bootloader (systemd-boot or GRUB)${NC}"
mount /dev/nvme0n1p1 /mnt/source/boot

# Check for systemd-boot
if [ -d "/mnt/source/boot/loader" ]; then
    echo "  Detected systemd-boot"
    # Update loader entry to add cryptdevice
    for entry in /mnt/source/boot/loader/entries/*.conf; do
        if grep -q "options" "$entry"; then
            sed -i "s|options|options cryptdevice=UUID=$LUKS_UUID:cryptroot:allow-discards|" "$entry"
        fi
    done
fi

# Regenerate initramfs with encrypt hook
mount -t proc proc /mnt/source/proc
mount -t sysfs sys /mnt/source/sys
mount --rbind /dev /mnt/source/dev

echo -e "${YELLOW}Step 12: Add encrypt hook to mkinitcpio${NC}"
# Add 'encrypt' hook before 'filesystems'
chroot /mnt/source sed -i 's/HOOKS=(.*filesystems/HOOKS=(\1encrypt filesystems/' /etc/mkinitcpio.conf
chroot /mnt/source mkinitcpio -P

echo -e "${YELLOW}Step 13: Cleanup${NC}"
umount -R /mnt/source
umount /mnt/data
cryptsetup close "$MAPPER_NAME"

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN} ENCRYPTION COMPLETE                                         ${NC}"
echo -e "${GREEN} Reboot and enter your LUKS passphrase at boot.              ${NC}"
echo -e "${GREEN} Once verified, clean up: rm -rf /data/backup/pre-encryption ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
