#!/bin/bash
#
# MassOS Live CD (ISO) Creation Script - Copyright (C) 2024 Daniel Massey.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Exit on error.
set -e
# Ensure we are running as root.
if test $EUID -ne 0; then
  echo "Error: $(basename "$0") must be run as root."
  exit 1
fi
# Add the MassOS programs directory to our path, in case we're not on MassOS.
export PATH="$PATH:$PWD/utils/programs"
# Ensure dependencies are present.
which curl &>/dev/null || (echo "Error: curl is required." >&2; exit 1)
which make &>/dev/null || (echo "Error: make is required." >&2; exit 1)
which mass-chroot &>/dev/null || (echo "Error: mass-chroot (from MassOS) is required." >&2; exit 1)
which mkfs.fat &>/dev/null || (echo "Error: mkfs.fat from dosfstools is required." >&2; exit 1)
which mksquashfs &>/dev/null || (echo "Error: mksquashfs from squashfs-tools is required." >&2; exit 1)
which xorriso &>/dev/null || (echo "Error: xorriso from libisoburn is required." >&2; exit 1)
# Ensure that the rootfs file is specified and valid.
if test -z "$1"; then
  echo "Error: Rootfs file must be specified." >&2
  echo "Usage: $(basename "$0") <rootfs-file-name>.tar.xz" >&2
  exit 1
fi
if test ! -f "$1"; then
  echo "Error: Specified rootfs file $1 is not valid." >&2
  exit 1
fi
# Check if an existing directory exists.
if test -e "iso-workdir"; then
  echo "The working directory 'iso-workdir' already exists, please remove" >&2
  echo "it before running $(basename "$0")." >&2
  exit 1
fi
# Create directories.
mkdir -p iso-workdir/{iso-root,massos-rootfs,mnt,osinstallgui,squashfs-tmp,syslinux}
mkdir -p iso-workdir/iso-root/EFI/BOOT
mkdir -p iso-workdir/iso-root/isolinux
mkdir -p iso-workdir/iso-root/LiveOS
mkdir -p iso-workdir/squashfs-tmp/LiveOS
mkdir -p iso-workdir/efitmp
# Get firmware versions from the rootfs (before extracting the whole thing).
tar -xf "$1" -C iso-workdir --strip-components=3 usr/share/massos/firmwareversions
FW_VER="$(grep -m1 "^linux-firmware:" iso-workdir/firmwareversions | cut -d' ' -f2-)"
MVER="$(grep -m1 "^intel-microcode:" iso-workdir/firmwareversions | cut -d' ' -f2-)"
SOF_VER="$(grep -m1 "^sof-firmware:" iso-workdir/firmwareversions | cut -d' ' -f2-)"
# Get osinstallgui version from the rootfs (before extracting the whole thing).
tar -xf "$1" -C iso-workdir --strip-components=3 usr/share/massos/.osinstallguiver
OSINSTALLGUI_VER="$(cat iso-workdir/.osinstallguiver)"
# Download stuff.
echo "Downloading osinstallgui..."
curl -L "https://github.com/DanielMYT/osinstallgui/archive/$OSINSTALLGUI_VER/osinstallgui-$OSINSTALLGUI_VER.tar.gz" -o iso-workdir/osinstallgui.tar.gz
echo "Downloading SYSLINUX..."
curl -L https://cdn.kernel.org/pub/linux/utils/boot/syslinux/Testing/6.04/syslinux-6.04-pre1.tar.xz -o iso-workdir/syslinux.tar.xz
tar --no-same-owner -xf iso-workdir/syslinux.tar.xz -C iso-workdir/syslinux --strip-components=1
echo "Downloading firmware..."
curl -L "https://cdn.kernel.org/pub/linux/kernel/firmware/linux-firmware-$FW_VER.tar.xz" -o iso-workdir/firmware.tar.xz
curl -L "https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/archive/microcode-$MVER.tar.gz" -o iso-workdir/mcode.tar.gz
curl -L "https://github.com/thesofproject/sof-bin/releases/download/v$SOF_VER/sof-bin-$SOF_VER.tar.gz" -o iso-workdir/sof.tar.gz
# Extract rootfs.
echo "Extracting rootfs..."
tar -xpf "$1" -C iso-workdir/massos-rootfs
ver="$(cat iso-workdir/massos-rootfs/etc/massos-release)"
# Prepare the live system.
echo "Preparing the live system..."
chroot iso-workdir/massos-rootfs /usr/sbin/groupadd -r autologin
chroot iso-workdir/massos-rootfs /usr/sbin/useradd -c "Live User" -G wheel,autologin -ms /bin/bash massos
echo "massos:massos" | chroot iso-workdir/massos-rootfs /usr/sbin/chpasswd
echo "massos ALL=(ALL) NOPASSWD: ALL" > iso-workdir/massos-rootfs/etc/sudoers.d/live
cat > iso-workdir/massos-rootfs/etc/polkit-1/rules.d/49-live.rules << "END"
// Allow elevation without password prompt in the live environment.
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("massos")) {
        return polkit.Result.YES;
    }
});
END
# Install osinstallgui.
echo "Installing osinstallgui..."
tar -xf iso-workdir/osinstallgui.tar.gz -C iso-workdir/osinstallgui --strip-components=1
make -C iso-workdir/osinstallgui
make -C iso-workdir/osinstallgui DESTDIR="$PWD"/iso-workdir/massos-rootfs install
sed -e "s|<Your Distro Name Here>|MassOS $ver|g" -e "s|<name-of-live-user>|massos|g" -e "s|</path/to/your/distro/logo>|/usr/share/massos/massos-logo.png|g" iso-workdir/osinstallgui/osinstallgui.desktop.example > iso-workdir/massos-rootfs/usr/share/applications/osinstallgui.desktop
chroot iso-workdir/massos-rootfs /usr/bin/install -o massos -g massos -dm755 /home/massos/Desktop
chroot iso-workdir/massos-rootfs /usr/bin/install -o massos -g massos -m755 /usr/share/applications/osinstallgui.desktop /home/massos/Desktop/osinstallgui.desktop
# Set up desktop-specific autologin configuration.
. livecd-data/autologin/autologin.sh
# Install firmware.
echo "Installing firmware..."
mkdir -p iso-workdir/{firmware,mcode,sof}
tar --no-same-owner -xf iso-workdir/firmware.tar.xz -C iso-workdir/firmware --strip-components=1
tar --no-same-owner -xf iso-workdir/mcode.tar.gz -C iso-workdir/mcode --strip-components=1
tar --no-same-owner -xf iso-workdir/sof.tar.gz -C iso-workdir/sof --strip-components=1
pushd iso-workdir/firmware
make DESTDIR="$PWD"/../massos-rootfs FIRMWAREDIR=/usr/lib/firmware install-xz
install -t "$PWD"/../massos-rootfs/usr/share/licenses/linux-firmware -Dm644 GPL-2 GPL-3 LICENCE* LICENSE* WHENCE
popd
install -dm755 iso-workdir/massos-rootfs/usr/lib/firmware/intel-ucode
install -m644 iso-workdir/mcode/intel-ucode{,-with-caveats}/* iso-workdir/massos-rootfs/usr/lib/firmware/intel-ucode
install -t iso-workdir/massos-rootfs/usr/share/licenses/intel-microcode -Dm644 iso-workdir/mcode/license
pushd iso-workdir/sof
cp -at "$PWD"/../massos-rootfs/usr/lib/firmware/intel sof*
install -t "$PWD"/../massos-rootfs/usr/share/licenses/sof-firmware -Dm644 LICENCE.Intel LICENCE.NXP Notice.NXP
popd
cat > iso-workdir/massos-rootfs/usr/share/massos/builtins.d/firmware << "END"
intel-microcode
linux-firmware
sof-firmware
END
# Create Squashfs image.
echo "Creating squashfs image..."
cd iso-workdir/massos-rootfs
mksquashfs * ../iso-root/LiveOS/squashfs.img -comp xz -quiet
cd ../..
# Install kernel and generate initramfs.
echo "Installing kernel..."
cp iso-workdir/massos-rootfs/boot/vmlinuz* iso-workdir/iso-root/vmlinuz
echo "Generating initramfs..."
mass-chroot iso-workdir/massos-rootfs /usr/sbin/mkinitramfs "$(ls iso-workdir/massos-rootfs/usr/lib/modules)" >/dev/null
mv iso-workdir/massos-rootfs/boot/initramfs-*.img iso-workdir/iso-root/initramfs.img
# Install bootloader files.
echo "Setting up bootloader..."
## Legacy BIOS.
cp iso-workdir/syslinux/bios/core/isolinux.bin iso-workdir/iso-root/isolinux/isolinux.bin
cp iso-workdir/syslinux/bios/com32/elflink/ldlinux/ldlinux.c32 iso-workdir/iso-root/isolinux/ldlinux.c32
cp iso-workdir/syslinux/bios/com32/lib/libcom32.c32 iso-workdir/iso-root/isolinux/libcom32.c32
cp iso-workdir/syslinux/bios/com32/libutil/libutil.c32 iso-workdir/iso-root/isolinux/libutil.c32
cp iso-workdir/syslinux/bios/com32/menu/vesamenu.c32 iso-workdir/iso-root/isolinux/vesamenu.c32
cp iso-workdir/syslinux/bios/com32/modules/reboot.c32 iso-workdir/iso-root/isolinux/reboot.c32
cp iso-workdir/syslinux/bios/com32/modules/poweroff.c32 iso-workdir/iso-root/isolinux/poweroff.c32
cp iso-workdir/syslinux/bios/mbr/isohdpfx.bin iso-workdir/iso-root/isolinux/isohdpfx.bin
cp iso-workdir/syslinux/COPYING iso-workdir/iso-root/isolinux/LICENSE-ISOLINUX.txt
cp livecd-data/isolinux.cfg iso-workdir/iso-root/isolinux/isolinux.cfg
cp livecd-data/splash.png iso-workdir/iso-root/isolinux/splash.png
## UEFI.
mkdir -p iso-workdir/massos-rootfs/boot/grub
cp livecd-data/grub.cfg iso-workdir/massos-rootfs/boot/grub/grub.cfg
mass-chroot iso-workdir/massos-rootfs /usr/bin/grub-mkstandalone -d /usr/lib/grub/x86_64-efi -O x86_64-efi -o BOOTX64.EFI --compress=xz /boot/grub/grub.cfg >/dev/null
cp iso-workdir/massos-rootfs/BOOTX64.EFI iso-workdir/iso-root/EFI/BOOT/BOOTX64.EFI
chmod +x iso-workdir/iso-root/EFI/BOOT/BOOTX64.EFI
cp iso-workdir/massos-rootfs/usr/share/grub/unicode.pf2 iso-workdir/iso-root/unicode.pf2
cp iso-workdir/massos-rootfs/usr/share/licenses/grub/COPYING iso-workdir/iso-root/EFI/BOOT/LICENSE-BOOTX64.txt
fallocate -l $(($(du -bc iso-workdir/iso-root/EFI/BOOT/{BOOTX64.EFI,LICENSE-BOOTX64.txt} | tail -n1 | cut -f1) + 80000)) iso-workdir/iso-root/EFI/BOOT/efiboot.img
mkfs.fat -F12 iso-workdir/iso-root/EFI/BOOT/efiboot.img -n "MASSOS_EFI"
mount -o loop iso-workdir/iso-root/EFI/BOOT/efiboot.img iso-workdir/efitmp
mkdir -p iso-workdir/efitmp/EFI/BOOT
cp iso-workdir/iso-root/EFI/BOOT/{BOOTX64.EFI,LICENSE-BOOTX64.txt} iso-workdir/efitmp/EFI/BOOT
sync
umount iso-workdir/efitmp
# Copy additional files.
cp livecd-data/autorun.ico iso-workdir/iso-root/autorun.ico
cp livecd-data/autorun.inf iso-workdir/iso-root/autorun.inf
cp livecd-data/README.txt iso-workdir/iso-root/README.txt
cp LICENSE iso-workdir/iso-root/LICENSE.txt
touch iso-workdir/iso-root/THIS_IS_THE_MASSOS_LIVECD
# Create the ISO image.
echo "Creating ISO image..."
xorrisofs -iso-level 3 -d -J -N -R -max-iso9660-filenames -relaxed-filenames -allow-lowercase -V "MASSOS" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e EFI/BOOT/efiboot.img -isohybrid-gpt-basdat -no-emul-boot -isohybrid-mbr iso-workdir/iso-root/isolinux/isohdpfx.bin -o "massos-$ver-livecd-x86_64-$variant.iso" iso-workdir/iso-root
# Clean up.
echo "Cleaning up..."
rm -rf iso-workdir
# Finishing message.
echo "All done! Output image written to massos-$ver-livecd-x86_64-$variant.iso."
