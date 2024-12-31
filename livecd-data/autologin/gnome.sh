cp iso-workdir/massos-rootfs/etc/gdm/custom.conf{,.orig}
sed -i '6iAutomaticLoginEnable=True' iso-workdir/massos-rootfs/etc/gdm/custom.conf
sed -i '7iAutomaticLogin=massos' iso-workdir/massos-rootfs/etc/gdm/custom.conf
