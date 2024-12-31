# Check which desktop environment is installed and configure autologin for it.

if test -e iso-workdir/massos-rootfs/usr/share/xsessions/xfce.desktop; then
  echo "[autologin] Configuring autologin for Xfce..."
  . livecd-data/autologin/xfce.sh
  variant="xfce"
elif [ -e iso-workdir/massos-rootfs/usr/share/wayland-sessions/gnome-wayland.desktop ]; then
  echo "[autologin] Configuring autologin for GNOME..."
  . livecd-data/autologin/gnome.sh
  variant="gnome"
elif [ -e iso-workdir/massos-rootfs/usr/share/xsessions/plasma.desktop ]; then
  echo "[autologin] Configuring autologin for KDE Plasma..."
  . livecd-data/autologin/plasma.sh
  variant="plasma"
else
  echo "[autologin] No supported desktop found; not configuring autologin."
  echo "[autologin] If you are using an unsupported desktop environment,"
  echo "[autologin] please consider adding support. For information, see the"
  echo "[autologin] file 'livecd-data/autologin/README.md'."
  variant="nodesktop"
fi

export variant
