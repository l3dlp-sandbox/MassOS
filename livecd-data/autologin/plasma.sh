cp iso-workdir/massos-rootfs/etc/sddm.conf{,.orig}
sed -e 's|Session=|Session=plasma|' -e 's|User=|User=massos|' -i iso-workdir/massos-rootfs/etc/sddm.conf
