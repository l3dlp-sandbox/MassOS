cp iso-workdir/massos-rootfs/etc/lightdm/lightdm.conf iso-workdir/massos-rootfs/etc/lightdm/lightdm.conf.orig
sed -i 's/#autologin-user=/autologin-user=massos/' iso-workdir/massos-rootfs/etc/lightdm/lightdm.conf
sed -i 's/#autologin-user-timeout=0/autologin-user-timeout=0/' iso-workdir/massos-rootfs/etc/lightdm/lightdm.conf
sed -i 's/#autologin-session=/autologin-session=xfce/' iso-workdir/massos-rootfs/etc/lightdm/lightdm.conf
