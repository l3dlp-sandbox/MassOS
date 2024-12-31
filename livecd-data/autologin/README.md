# PORTING DESKTOP ENVIRONMENTS
Do the following if you are porting a desktop environment to MassOS:

1. Fork this repo.
2. Add a script named `<your-de>.sh` containing the commands used to configure autologin. Look at the reference `xfce.sh` if you are unsure on how it should be formatted.
3. Modify `autologin.sh` to add a check for your desktop environment. Follow the format of others. The most common way to check whether the desktop environment's session file exists. For example, `if [ -e iso-workdir/massos-rootfs/usr/share/xsessions/xfce.desktop ]` for Xfce. You might use `elif` to keep in the one condition statement.
4. If needed, edit the `utils/livecd-cleanup.sh` script in the MassOS repository to ensure osinstallgui correctly removes the autologin configuration from the target system after installation.
5. Test your changes to ensure they work.
6. Create a pull request with your additions.
