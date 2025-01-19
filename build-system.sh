#!/bin/bash
#
# Builds the core MassOS system (Stage 2) in a chroot environment.
# Copyright (C) 2021-2022 MassOS Developers.
#
# This script is part of the MassOS build system. It is licensed under GPLv3+.
# See the 'LICENSE' file for the full license text. On a MassOS system, this
# document can also be found at '/usr/share/massos/LICENSE'.
#
# === IF RESUMING A FAILED BUILD, DO NOT REMOVE ANY LINES BEFORE LINE 38 ===
#
# Exit if something goes wrong.
set -e
# Disabling hashing is useful so the newly built tools are detected.
set +h
# Ensure we're running in the MassOS chroot.
if [ $EUID -ne 0 ] || [ ! -d /sources ]; then
  echo "This script should not be run manually." >&2
  echo "stage2.sh will automatically run it in a chroot environment." >&2
  exit 1
fi
# Change to the source tarballs directory and set up the environment.
cd /sources
. build.env
# === REMOVE LINES BELOW THIS FOR RESUMING A FAILED BUILD ===
# Mark the build as started, for Stage 2 resume.
touch .BUILD_HAS_STARTED
# Setup the full filesystem structure.
mkdir -p /{boot,home,mnt,opt,srv}
mkdir -p /boot/efi
mkdir -p /etc/{opt,sysconfig}
mkdir -p /usr/lib/firmware
mkdir -p /usr/{,local/}{include,src}
mkdir -p /usr/local/{bin,lib,libexec,sbin}
mkdir -p /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -p /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -p /var/{cache,local,log,mail,opt,spool}
mkdir -p /var/lib/{color,misc,locate}
ln -sf lib /usr/local/lib64
ln -sf /run /var/run
ln -sf /run/lock /var/lock
ln -sf /run/media /media
install -dm0750 /root
cp -r /etc/skel/. /root
install -dm1777 /tmp /var/tmp
touch /var/log/{btmp,lastlog,faillog,wtmp}
chmod 664 /var/log/lastlog
chmod 600 /var/log/btmp
# Install man pages for MassOS system utilities.
cp -r man/* /usr/share/man
# Install MassOS Backgrounds.
install -t /usr/share/backgrounds -Dm644 backgrounds/*
ln -sf . /usr/share/backgrounds/xfce
# Install additional MassOS files.
install -t /usr/share/massos -Dm644 LICENSE builtins massos-logo.png massos-logo-small.png massos-logo-extrasmall.png massos-logo-notext.png massos-logo-sidetext.png
install -dm755 /usr/share/pixmaps
for i in /usr/share/massos/*.png; do ln -sfr $i /usr/share/pixmaps; done
# Set the locale correctly.
mkdir -p /usr/lib/locale
mklocales 2>/dev/null
# Install Rust and Go to temporary directories for building some packages.
tar -xf rust-1.84.0-x86_64-unknown-linux-gnu.tar.gz
cd rust-1.84.0-x86_64-unknown-linux-gnu
./install.sh --prefix=/sources/rust --without=rust-docs
tar -xf ../cargo-c-x86_64-unknown-linux-musl.tar.gz -C /sources/rust/bin
tar -xf ../bindgen-cli-x86_64-unknown-linux-gnu.tar.xz -C /sources/rust/bin --strip-components=1 bindgen-cli-x86_64-unknown-linux-gnu/bindgen
install -t /sources/rust/bin -Dm755 ../cbindgen
cd ..
rm -rf rust-1.84.0-x86_64-unknown-linux-gnu
tar -xf go1.23.4.linux-amd64.tar.gz
# Bison (circular deps; rebuilt later).
tar -xf bison-3.8.2.tar.xz
cd bison-3.8.2
./configure --prefix=/usr
make
make install
cd ..
rm -rf bison-3.8.2
# Perl (circular deps; rebuilt later).
tar -xf perl-5.40.0.tar.xz
cd perl-5.40.0
./Configure -des -Doptimize="$CFLAGS" -Dprefix=/usr -Dvendorprefix=/usr -Duseshrplib -Dprivlib=/usr/lib/perl5/5.40/core_perl -Darchlib=/usr/lib/perl5/5.40/core_perl -Dsitelib=/usr/lib/perl5/5.40/site_perl -Dsitearch=/usr/lib/perl5/5.40/site_perl -Dvendorlib=/usr/lib/perl5/5.40/vendor_perl -Dvendorarch=/usr/lib/perl5/5.40/vendor_perl
make
make install
cd ..
rm -rf perl-5.40.0
# Python (circular deps; rebuilt later).
tar -xf Python-3.13.1.tar.xz
cd Python-3.13.1
./configure --prefix=/usr --enable-shared --without-ensurepip --disable-test-modules
make
make install
cd ..
rm -rf Python-3.13.1
# Texinfo (circular deps; rebuilt later).
tar -xf texinfo-7.2.tar.xz
cd texinfo-7.2
./configure --prefix=/usr
make
make install
cd ..
rm -rf texinfo-7.2
# util-linux (circular deps; rebuilt later).
tar -xf util-linux-2.40.4.tar.xz
cd util-linux-2.40.4
mkdir -p /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime --libdir=/usr/lib --runstatedir=/run --disable-static --disable-chfn-chsh --disable-liblastlog2 --disable-login --disable-nologin --disable-pylibmount --disable-runuser --disable-setpriv --disable-su --disable-use-tty-group --without-python
make
make install
cd ..
rm -rf util-linux-2.40.4
# man-pages.
tar -xf man-pages-6.9.1.tar.xz
cd man-pages-6.9.1
rm -f man3/crypt*
make prefix=/usr install
install -t /usr/share/licenses/man-pages -Dm644 LICENSES/*
cd ..
rm -rf man-pages-6.9.1
# iana-etc.
tar -xf iana-etc-20250108.tar.gz
install -t /etc -Dm644 iana-etc-20250108/{protocols,services}
install -dm755 /usr/share/licenses/iana-etc
cat > /usr/share/licenses/iana-etc/LICENSE << "END"
Copyright 2017 Jörg Thalheim

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
END
rm -rf iana-etc-20250108
# Glibc.
tar -xf glibc-2.40.tar.xz
cd glibc-2.40
patch -Np1 -i ../patches/glibc-2.40-vardirectories.patch
mkdir -p build; cd build
echo "rootsbindir=/usr/sbin" > configparms
CFLAGS="-O2" CXXFLAGS="-O2" ../configure --prefix=/usr --with-pkgversion="MassOS Glibc 2.40" --enable-kernel=4.19 --enable-stack-protector=strong --disable-nscd --disable-werror libc_cv_slibdir=/usr/lib
make
sed -i '/test-installation/s@$(PERL)@echo not running@' ../Makefile
make install
sed -i '/RTLDLIST=/s@/usr@@g' /usr/bin/ldd
sed -e '/#/d' -e '/SUPPORTED-LOCALES/d' -e 's|\\||g' -e 's|/| |g' -e 's|^|#|g' -e 's|#en_US.UTF-8|en_US.UTF-8|' ../localedata/SUPPORTED >> /etc/locales
mklocales
install -t /usr/share/licenses/glibc -Dm644 ../COPYING ../COPYING.LIB ../LICENSES
cd ../..
rm -rf glibc-2.40
# tzdata.
mkdir -p tzdata; cd tzdata
tar -xf ../tzdata2024b.tar.gz
mkdir -p /usr/share/zoneinfo/{posix,right}
for region in etcetera southamerica northamerica europe africa antarctica asia australasia backward; do
  echo "Setting up tzdata for region ${region}..."
  zic -L /dev/null -d /usr/share/zoneinfo ${region}
  zic -L /dev/null -d /usr/share/zoneinfo/posix ${region}
  zic -L leapseconds -d /usr/share/zoneinfo/right ${region}
done
install -t /usr/share/zoneinfo -Dm644 {iso3166,zone{,1970}}.tab
zic -d /usr/share/zoneinfo -p America/New_York
ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
install -t /usr/share/licenses/tzdata -Dm644 LICENSE
cd ..
rm -rf tzdata
# zlib.
tar -xf zlib-1.3.1.tar.xz
cd zlib-1.3.1
./configure --prefix=/usr
make
make install
install -dm755 /usr/share/licenses/zlib
cat zlib.h | head -n28 | tail -n25 > /usr/share/licenses/zlib/LICENSE
rm -f /usr/lib/libz.a
cd ..
rm -rf zlib-1.3.1
# bzip2.
tar -xf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so CFLAGS="$CFLAGS -fPIC"
make clean
make CFLAGS="$CFLAGS"
make PREFIX=/usr install
cp -a libbz2.so.* /usr/lib
ln -s libbz2.so.1.0.8 /usr/lib/libbz2.so
cp bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sf bzip2 $i
done
rm -f /usr/lib/libbz2.a
install -t /usr/share/licenses/bzip2 -Dm644 LICENSE
cd ..
rm -rf bzip2-1.0.8
# XZ.
tar -xf xz-5.6.3.tar.xz
cd xz-5.6.3
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/xz -Dm644 COPYING COPYING.GPLv2 COPYING.GPLv3 COPYING.LGPLv2.1
cd ..
rm -rf xz-5.6.3
# LZ4.
tar -xf lz4-1.10.0.tar.gz
cd lz4-1.10.0
make PREFIX=/usr BUILD_STATIC=no CFLAGS="$CFLAGS"
make PREFIX=/usr BUILD_STATIC=no install
install -t /usr/share/licenses/lz4 -Dm644 LICENSE
cd ..
rm -rf lz4-1.10.0
# ZSTD.
tar -xf zstd-1.5.6.tar.gz
cd zstd-1.5.6
make prefix=/usr CFLAGS="$CFLAGS -fPIC"
make prefix=/usr install
rm -f /usr/lib/libzstd.a
install -t /usr/share/licenses/zstd -Dm644 COPYING LICENSE
cd ..
rm -rf zstd-1.5.6
# pigz.
tar -xf pigz-2.8.tar.gz
cd pigz-2.8
make CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
install -t /usr/bin -Dm755 pigz unpigz
install -t /usr/share/man/man1/pigz.1 -Dm644 pigz.1
ln -sf pigz.1 /usr/share/man/man1/unpigz.1
install -dm755 /usr/share/licenses/pigz
cat README | tail -n18 > /usr/share/licenses/pigz/LICENSE
cd ..
rm -rf pigz-2.8
# lzip.
tar -xf lzip-1.24.1.tar.gz
cd lzip-1.24.1
./configure CXXFLAGS="$CXXFLAGS" --prefix=/usr
make
make install
install -t /usr/share/licenses/lzip -Dm644 COPYING
cd ..
rm -rf lzip-1.24.1
# Readline.
tar -xf readline-8.2.13.tar.gz
cd readline-8.2.13
./configure --prefix=/usr --disable-static --with-curses
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
install -t /usr/share/licenses/readline -Dm644 COPYING
cd ..
rm -rf readline-8.2.13
# m4.
tar -xf m4-1.4.19.tar.xz
cd m4-1.4.19
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/m4 -Dm644 COPYING
cd ..
rm -rf m4-1.4.19
# bc.
tar -xf bc-7.0.3.tar.xz
cd bc-7.0.3
CC=gcc ./configure.sh --prefix=/usr --disable-generated-tests --enable-readline
make
make install
install -t /usr/share/licenses/bc -Dm644 LICENSE.md
cd ..
rm -rf bc-7.0.3
# Flex.
tar -xf flex-2.6.4.tar.gz
cd flex-2.6.4
./configure --prefix=/usr --disable-static
make
make install
ln -sf flex /usr/bin/lex
ln -sf flex.1 /usr/share/man/man1/lex.1
ln -sf flex.info /usr/share/info/lex.info
install -t /usr/share/licenses/flex -Dm644 COPYING
cd ..
rm -rf flex-2.6.4
# Tcl.
tar -xf tcl8.6.15-src.tar.gz
cd tcl8.6.15
TCLROOTSRCDIR="$PWD"
cd unix
./configure --prefix=/usr --mandir=/usr/share/man
make
sed -e "s|$TCLROOTSRCDIR/unix|/usr/lib|" -e "s|$TCLROOTSRCDIR|/usr/include|" -i tclConfig.sh
sed -e "s|$TCLROOTSRCDIR/unix/pkgs/tdbc1.1.9|/usr/lib/tdbc1.1.9|" -e "s|$TCLROOTSRCDIR/pkgs/tdbc1.1.9/generic|/usr/include|" -e "s|$TCLROOTSRCDIR/pkgs/tdbc1.1.9/library|/usr/lib/tcl8.6|" -e "s|$TCLROOTSRCDIR/pkgs/tdbc1.1.9|/usr/include|" -i pkgs/tdbc1.1.9/tdbcConfig.sh
sed -e "s|$TCLROOTSRCDIR/unix/pkgs/itcl4.3.0|/usr/lib/itcl4.3.0|" -e "s|$TCLROOTSRCDIR/pkgs/itcl4.3.0/generic|/usr/include|" -e "s|$TCLROOTSRCDIR/pkgs/itcl4.3.0|/usr/include|" -i pkgs/itcl4.3.0/itclConfig.sh
unset TCLROOTSRCDIR
make install
chmod u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sf tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
install -t /usr/share/licenses/tcl -Dm644 ../license.terms
cd ../..
rm -rf tcl8.6.15
# pkconf (replaces pkg-config).
tar -xf pkgconf-2.3.0.tar.xz
cd pkgconf-2.3.0
./configure --prefix=/usr --disable-static
make
make install
ln -sf pkgconf /usr/bin/pkg-config
ln -sf pkgconf.1 /usr/share/man/man1/pkg-config.1
install -t /usr/share/licenses/pkgconf -Dm644 COPYING
ln -sf pkgconf /usr/share/licenses/pkg-config
cd ..
rm -rf pkgconf-2.3.0
# Binutils.
tar -xf binutils-2.43.1.tar.xz
cd binutils-2.43.1
patch -Np1 -i ../patches/binutils-2.43.1-upstreamfix.patch
mkdir build; cd build
CFLAGS="-O2" CXXFLAGS="-O2" ../configure --prefix=/usr --sysconfdir=/etc --with-pkgversion="MassOS Binutils 2.43.1" --with-system-zlib --enable-default-hash-style=gnu --enable-gold --enable-install-libiberty --enable-ld=default --enable-new-dtags --enable-plugins --enable-relro --enable-shared --disable-werror
make tooldir=/usr
make -j1 tooldir=/usr install
rm -f /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a
install -t /usr/share/licenses/binutils -Dm644 ../COPYING ../COPYING.LIB ../COPYING3 ../COPYING3.LIB
cd ../..
rm -rf binutils-2.43.1
# GMP.
tar -xf gmp-6.3.0.tar.xz
cd gmp-6.3.0
./configure --prefix=/usr --enable-cxx --disable-static
make
make install
install -t /usr/share/licenses/gmp -Dm644 COPYING COPYINGv2 COPYINGv3 COPYING.LESSERv3
cd ..
rm -rf gmp-6.3.0
# MPFR.
tar -xf mpfr-4.2.1.tar.xz
cd mpfr-4.2.1
./configure --prefix=/usr --disable-static --enable-thread-safe
make
make install
install -t /usr/share/licenses/mpfr -Dm644 COPYING COPYING.LESSER
cd ..
rm -rf mpfr-4.2.1
# MPC.
tar -xf mpc-1.3.1.tar.gz
cd mpc-1.3.1
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/mpc -Dm644 COPYING.LESSER
cd ..
rm -rf mpc-1.3.1
# Attr.
tar -xf attr-2.5.2.tar.xz
cd attr-2.5.2
./configure --prefix=/usr --disable-static --sysconfdir=/etc
make
make install
install -t /usr/share/licenses/attr -Dm644 doc/COPYING doc/COPYING.LGPL
cd ..
rm -rf attr-2.5.2
# Acl.
tar -xf acl-2.3.2.tar.xz
cd acl-2.3.2
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/acl -Dm644 doc/COPYING doc/COPYING.LGPL
cd ..
rm -rf acl-2.3.2
# libxcrypt.
tar -xf libxcrypt-4.4.37.tar.xz
cd libxcrypt-4.4.37
mkdir build-normal; cd build-normal
../configure --prefix=/usr --enable-hashes=glibc,strong --enable-obsolete-api=no --disable-failure-tokens --disable-static
make
mkdir ../build-compat; cd ../build-compat
../configure --prefix=/usr --enable-hashes=glibc,strong --enable-obsolete-api=glibc --disable-failure-tokens --disable-static
make
cd ..
make -C build-normal install
install -t /usr/lib -Dm755 build-compat/.libs/libcrypt.so.1.1.0
ln -sf libcrypt.so.1.1.0 /usr/lib/libcrypt.so.1
ln -sf libcrypt.so.1.1.0 /usr/lib/libcrypt.so
ldconfig
install -t /usr/share/licenses/libxcrypt -Dm644 COPYING.LIB LICENSING
cd ..
rm -rf libxcrypt-4.4.37
# Libcap.
tar -xf libcap-2.73.tar.xz
cd libcap-2.73
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib CFLAGS="$CFLAGS -fPIC"
make prefix=/usr lib=lib install
chmod 755 /usr/lib/lib{cap,psx}.so.2.73
install -t /usr/share/licenses/libcap -Dm644 License
cd ..
rm -rf libcap-2.73
# CrackLib.
tar -xf cracklib-2.10.3.tar.bz2
cd cracklib-2.10.3
CPPFLAGS="-I/usr/include/$(readlink /usr/bin/python3)" ./configure --prefix=/usr --disable-static --with-python --with-default-dict=/usr/lib/cracklib/pw_dict
make
make install
install -dm755 /usr/lib/cracklib
bzip2 -cd ../cracklib-words-2.10.3.bz2 > /usr/share/dict/cracklib-words
ln -sf cracklib-words /usr/share/dict/words
echo "massos" > /usr/share/dict/cracklib-extra-words
create-cracklib-dict /usr/share/dict/cracklib-words /usr/share/dict/cracklib-extra-words
install -t /usr/share/licenses/cracklib -Dm644 COPYING.LIB
cd ..
rm -rf cracklib-2.10.3
# Linux-PAM (older autotools version - new Meson version will be built later).
tar -xf Linux-PAM-1.6.1.tar.xz
cd Linux-PAM-1.6.1
patch -Np1 -i ../patches/Linux-PAM-1.6.1-pamconfig.patch
./configure --prefix=/usr --sysconfdir=/etc --libdir=/usr/lib --enable-securedir=/usr/lib/security --disable-doc
make
make install
chmod 4755 /usr/sbin/unix_chkpwd
install -t /etc/pam.d -Dm644 pam.d/*
cd ..
rm -rf Linux-PAM-1.6.1
# libpwquality (Python bindings will be built later).
tar -xf libpwquality-1.4.5.tar.bz2
cd libpwquality-1.4.5
./configure --prefix=/usr --disable-static --with-securedir=/usr/lib/security --disable-python-bindings
make
make install
install -t /usr/share/licenses/libpwquality -Dm644 COPYING
cd ..
rm -rf libpwquality-1.4.5
# Libcap (PAM module only, which could not be built before).
tar -xf libcap-2.73.tar.xz
cd libcap-2.73
make CFLAGS="$CFLAGS -fPIC" -C pam_cap
install -t /usr/lib/security -Dm755 pam_cap/pam_cap.so
install -t /etc/security -Dm644 pam_cap/capability.conf
cd ..
rm -rf libcap-2.73
# Shadow (initial build; will be rebuilt later to support AUDIT).
tar -xf shadow-4.17.2.tar.xz
cd shadow-4.17.2
patch -Np1 -i ../patches/shadow-4.17.2-MassOS.patch
touch /usr/bin/passwd
./configure --sysconfdir=/etc --disable-static --with-bcrypt --with-group-name-max-length=32 --with-libcrack --with-yescrypt --without-libbsd
make
make exec_prefix=/usr pamdir= install
make -C man install-man
chmod 0600 /etc/default/useradd
pwconv
grpconv
install -t /etc/pam.d -Dm644 pam.d/*
rm -f /etc/{limits,login.access}
install -t /usr/share/licenses/shadow -Dm644 COPYING
cd ..
rm -rf shadow-4.17.2
# GCC.
tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0
mkdir -p isl
tar -xf ../isl-0.27.tar.xz -C isl --strip-components=1
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
mkdir -p build; cd build
CFLAGS="-O2" CXXFLAGS="-O2" ../configure LD=ld --prefix=/usr --with-pkgversion="MassOS GCC 14.2.0" --with-system-zlib --enable-languages=c,c++ --enable-default-pie --enable-default-ssp --enable-host-pie --enable-linker-build-id --disable-bootstrap --disable-fixincludes --disable-multilib
make
make install
ln -sfr /usr/bin/cpp /usr/lib
ln -sf ../../libexec/gcc/$(gcc -dumpmachine)/$(gcc -dumpversion)/liblto_plugin.so /usr/lib/bfd-plugins/
ln -sf gcc.1 /usr/share/man/man1/cc.1
mkdir -p /usr/share/gdb/auto-load/usr/lib
mv /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
find /usr -depth -name x86_64-stage1-linux-gnu\* | xargs rm -rf
install -t /usr/share/licenses/gcc -Dm644 ../COPYING ../COPYING.LIB ../COPYING3 ../COPYING3.LIB ../COPYING.RUNTIME
cd ../..
rm -rf gcc-14.2.0
# unifdef.
tar -xf unifdef-2.12.tar.gz
cd unifdef-2.12
make
make prefix=/usr install
install -t /usr/share/licenses/unifdef -Dm644 COPYING
cd ..
rm -rf unifdef-2.12
# Ncurses.
tar -xf ncurses-6.5.tar.gz
cd ncurses-6.5
mkdir -p build; cd build
../configure --prefix=/usr --mandir=/usr/share/man --enable-pc-files --with-shared --with-cxx-shared --without-debug --without-normal --with-pkg-config-libdir=/usr/lib/pkgconfig
make
make DESTDIR=$PWD/temp install
install -t /usr/lib -Dm755 temp/usr/lib/libncursesw.so.6.5
rm -f temp/usr/lib/libncursesw.so.6.5
sed -i 's/^#if.*XOPEN.*$/#if 1/' temp/usr/include/curses.h
cp -a temp/* /
for lib in ncurses form panel menu; do
  ln -sf lib${lib}w.so /usr/lib/lib${lib}.so
  ln -sf ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
done
ln -sf libncursesw.so /usr/lib/libcurses.so
ln -sf libncursesw.so /usr/lib/libtinfo.so
ldconfig
install -t /usr/share/licenses/ncurses -Dm644 ../COPYING
cd ../..
rm -rf ncurses-6.5
# libedit.
tar -xf libedit-20240808-3.1.tar.gz
cd libedit-20240808-3.1
sed -i 's/history.3//g' doc/Makefile.in
./configure --prefix=/usr --disable-static
make
make install
cp /usr/share/man/man3/e{ditline,l}.3
install -t /usr/share/licenses/libedit -Dm644 COPYING
cd ..
rm -rf libedit-20240808-3.1
# libsigsegv.
tar -xf libsigsegv-2.14.tar.gz
cd libsigsegv-2.14
./configure --prefix=/usr --enable-shared --disable-static
make
make install
install -t /usr/share/licenses/libsigsegv -Dm644 COPYING
cd ..
rm -rf libsigsegv-2.14
# Sed.
tar -xf sed-4.9.tar.xz
cd sed-4.9
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/sed -Dm644 COPYING
cd ..
rm -rf sed-4.9
# Gettext.
tar -xf gettext-0.23.1.tar.xz
cd gettext-0.23.1
./configure --prefix=/usr --disable-static
make
make install
chmod 0755 /usr/lib/preloadable_libintl.so
install -t /usr/share/licenses/gettext -Dm644 COPYING
cd ..
rm -rf gettext-0.23.1
# Bison.
tar -xf bison-3.8.2.tar.xz
cd bison-3.8.2
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/bison -Dm644 COPYING
cd ..
rm -rf bison-3.8.2
# PCRE.
tar -xf pcre-8.45.tar.bz2
cd pcre-8.45
./configure --prefix=/usr --enable-unicode-properties --enable-jit --enable-pcre16 --enable-pcre32 --enable-pcregrep-libz --enable-pcregrep-libbz2 --enable-pcretest-libreadline --disable-static
make
make install
install -t /usr/share/licenses/pcre -Dm644 LICENCE
cd ..
rm -rf pcre-8.45
# PCRE2.
tar -xf pcre2-10.44.tar.bz2
cd pcre2-10.44
./configure --prefix=/usr --enable-unicode --enable-jit --enable-pcre2-16 --enable-pcre2-32 --enable-pcre2grep-libz --enable-pcre2grep-libbz2 --enable-pcre2test-libreadline --disable-static
make
make install
install -t /usr/share/licenses/pcre2 -Dm644 LICENCE
cd ..
rm -rf pcre2-10.44
# Grep.
tar -xf grep-3.11.tar.xz
cd grep-3.11
./configure --prefix=/usr
make
make install
cd ..
rm -rf grep-3.11
# Bash.
tar -xf bash-5.2.37.tar.gz
cd bash-5.2.37
./configure --prefix=/usr --without-bash-malloc --with-installed-readline
make
make install
ln -sf bash.1 /usr/share/man/man1/sh.1
install -t /usr/share/licenses/bash -Dm644 COPYING
cd ..
rm -rf bash-5.2.37
# bash-completion.
tar -xf bash-completion-2.16.0.tar.xz
cd bash-completion-2.16.0
./configure --prefix=/usr --sysconfdir=/etc
make
make install
install -t /usr/share/licenses/bash-completion -Dm644 COPYING
cd ..
rm -rf bash-completion-2.16.0
# libtool.
tar -xf libtool-2.5.4.tar.xz
cd libtool-2.5.4
./configure --prefix=/usr
make
make install
rm -f /usr/lib/libltdl.a
install -t /usr/share/licenses/libtool -Dm644 COPYING
cd ..
rm -rf libtool-2.5.4
# GDBM.
tar -xf gdbm-1.24.tar.gz
cd gdbm-1.24
./configure --prefix=/usr --disable-static --enable-libgdbm-compat
make
make install
install -t /usr/share/licenses/gdbm -Dm644 COPYING
cd ..
rm -rf gdbm-1.24
# gperf.
tar -xf gperf-3.1.tar.gz
cd gperf-3.1
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/gperf -Dm644 COPYING
cd ..
rm -rf gperf-3.1
# Expat.
tar -xf expat-2.6.4.tar.xz
cd expat-2.6.4
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/expat -Dm644 COPYING
cd ..
rm -rf expat-2.6.4
# libmetalink.
tar -xf libmetalink-0.1.3.tar.bz2
cd libmetalink-0.1.3
./configure --prefix=/usr --enable-static=no
make
make install
install -t /usr/share/licenses/libmetalink -Dm644 COPYING
cd ..
rm -rf libmetalink-0.1.3
# Inetutils.
tar -xf inetutils-2.5.tar.xz
cd inetutils-2.5
sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
./configure --prefix=/usr --bindir=/usr/bin --localstatedir=/var --disable-logger --disable-whois --disable-rcp --disable-rexec --disable-rlogin --disable-rsh --disable-servers
make
make install
mv /usr/bin/ifconfig /usr/sbin/ifconfig
install -t /usr/share/licenses/inetutils -Dm644 COPYING
cd ..
rm -rf inetutils-2.5
# Netcat.
tar -xf netcat-0.7.1.tar.bz2
cd netcat-0.7.1
./configure --prefix=/usr --mandir=/usr/share/man --infodir=/usr/share/info
make
make install
install -t /usr/share/licenses/netcat -Dm644 COPYING
cd ..
rm -rf netcat-0.7.1
# Less.
tar -xf less-668.tar.gz
cd less-668
./configure --prefix=/usr --sysconfdir=/etc --with-regex=pcre2
make
make install
install -t /usr/share/licenses/less -Dm644 COPYING LICENSE
cd ..
rm -rf less-668
# Lua.
tar -xf lua-5.4.7.tar.gz
cd lua-5.4.7
patch -Np1 -i ../patches/lua-5.4.4-sharedlib+pkgconfig.patch
make MYCFLAGS="$CFLAGS -fPIC" linux-readline
make INSTALL_DATA="cp -d" INSTALL_TOP=/usr INSTALL_MAN=/usr/share/man/man1 TO_LIB="liblua.so liblua.so.5.4 liblua.so.5.4.7" install
install -t /usr/lib/pkgconfig -Dm644 lua.pc
cat src/lua.h | tail -n24 | head -n20 | sed -e 's/* //g' -e 's/*//g' > COPYING
install -t /usr/share/licenses/lua -Dm644 COPYING
cd ..
rm -rf lua-5.4.7
# Perl.
tar -xf perl-5.40.0.tar.xz
cd perl-5.40.0
BUILD_ZLIB=False BUILD_BZIP2=0 ./Configure -des -Doptimize="$CFLAGS" -Dprefix=/usr -Dvendorprefix=/usr -Dprivlib=/usr/lib/perl5/5.40/core_perl -Darchlib=/usr/lib/perl5/5.40/core_perl -Dsitelib=/usr/lib/perl5/5.40/site_perl -Dsitearch=/usr/lib/perl5/5.40/site_perl -Dvendorlib=/usr/lib/perl5/5.40/vendor_perl -Dvendorarch=/usr/lib/perl5/5.40/vendor_perl -Dman1dir=/usr/share/man/man1 -Dman3dir=/usr/share/man/man3 -Dpager="/usr/bin/less -isR" -Duseshrplib -Dusethreads
BUILD_ZLIB=False BUILD_BZIP2=0 make
BUILD_ZLIB=False BUILD_BZIP2=0 make install
install -t /usr/share/licenses/perl -Dm644 Copying
cd ..
rm -rf perl-5.40.0
# SGMLSpm
tar -xf SGMLSpm-1.1.tar.gz
cd SGMLSpm-1.1
chmod +w MYMETA.yml
perl Makefile.PL
make
make install
rm -f /usr/lib/perl5/5.40/core_perl/perllocal.pod
ln -sf sgmlspl.pl /usr/bin/sgmlspl
install -t /usr/share/licenses/sgmlspm -Dm644 COPYING
cd ..
rm -rf SGMLSpm-1.1
# XML-Parser.
tar -xf XML-Parser-2.47.tar.gz
cd XML-Parser-2.47
perl Makefile.PL
make
make install
cd ..
rm -rf XML-Parser-2.47
# Intltool.
tar -xf intltool-0.51.0.tar.gz
cd intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/intltool -Dm644 COPYING
cd ..
rm -rf intltool-0.51.0
# Autoconf.
tar -xf autoconf-2.72.tar.xz
cd autoconf-2.72
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/autoconf -Dm644 COPYING COPYINGv3 COPYING.EXCEPTION
cd ..
rm -rf autoconf-2.72
# Autoconf (legacy version 2.13).
tar -xf autoconf-2.13.tar.gz
cd autoconf-2.13
patch -Np1 -i ../patches/autoconf-2.13-consolidated_fixes-1.patch
mv autoconf.texi autoconf213.texi
rm autoconf.info
./configure --prefix=/usr --infodir=/usr/share/info --program-suffix=2.13
make
make install
install -m644 autoconf213.info /usr/share/info
install-info --info-dir=/usr/share/info autoconf213.info
install -t /usr/share/licenses/autoconf213 -Dm644 COPYING
cd ..
rm -rf autoconf-2.13
# Automake.
tar -xf automake-1.17.tar.xz
cd automake-1.17
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/automake -Dm644 COPYING
cd ..
rm -rf automake-1.17
# autoconf-archive.
tar -xf autoconf-archive-2023.02.20.tar.xz
cd autoconf-archive-2023.02.20
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/autoconf-archive -Dm644 COPYING{,.EXCEPTION}
cd ..
rm -rf autoconf-archive-2023.02.20
# dotconf.
tar -xf dotconf-1.4.1.tar.gz
cd dotconf-1.4.1
autoreconf -fi
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/dotconf -Dm644 COPYING
cd ..
rm -rf dotconf-1.4.1
# PSmisc.
tar -xf psmisc-v23.7.tar.bz2
cd psmisc-v23.7
sed -i 's/UNKNOWN/23.7/g' misc/git-version-gen
./autogen.sh
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/psmisc -Dm644 COPYING
cd ..
rm -rf psmisc-v23.7
# elfutils.
tar -xf elfutils-0.192.tar.bz2
cd elfutils-0.192
CFLAGS="-O2" CXXFLAGS="-O2" ./configure --prefix=/usr --program-prefix="eu-" --disable-debuginfod --enable-libdebuginfod=dummy
make
make install
rm -f /usr/lib/lib{asm,dw,elf}.a
install -t /usr/share/licenses/elfutils -Dm644 COPYING COPYING-GPLV2 COPYING-LGPLV3
cd ..
rm -rf elfutils-0.192
# libbpf.
tar -xf libbpf-1.5.0.tar.gz
cd libbpf-1.5.0/src
make
make LIBSUBDIR=lib install
rm -f /usr/lib/libbpf.a
install -t /usr/share/licenses/libbpf -Dm644 ../LICENSE{,.BSD-2-Clause,.LGPL-2.1}
cd ../..
rm -rf libbpf-1.5.0
# patchelf.
tar -xf patchelf-0.18.0.tar.bz2
cd patchelf-0.18.0
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/patchelf -Dm644 COPYING
cd ..
rm -rf patchelf-0.18.0
# strace.
tar -xf strace-6.12.tar.xz
cd strace-6.12
./configure --prefix=/usr --with-libdw
make
make install
install -t /usr/share/licenses/strace -Dm644 COPYING LGPL-2.1-or-later
cd ..
rm -rf strace-6.12
# memstrack.
tar -xf memstrack-0.2.2.tar.gz
cd memstrack-0.2.2
make
make install
install -t /usr/share/licenses/memstrack -Dm644 LICENSE
cd ..
rm -rf memstrack-0.2.2
# libffi.
tar -xf libffi-3.4.6.tar.gz
cd libffi-3.4.6
./configure --prefix=/usr --disable-static --disable-exec-static-tramp
make
make install
install -t /usr/share/licenses/libffi -Dm644 LICENSE
cd ..
rm -rf libffi-3.4.6
# OpenSSL.
tar -xf openssl-3.4.0.tar.gz
cd openssl-3.4.0
./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic
make
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
install -t /usr/share/licenses/openssl -Dm644 LICENSE.txt
cd ..
rm -rf openssl-3.4.0
# easy-rsa.
tar -xf EasyRSA-3.2.1.tgz
cd EasyRSA-3.2.1
install -Dm755 easyrsa /usr/bin/easyrsa
install -Dm644 openssl-easyrsa.cnf /etc/easy-rsa/openssl-easyrsa.cnf
install -Dm644 vars.example /etc/easy-rsa/vars
install -dm755 /etc/easy-rsa/x509-types/
install -m644 x509-types/* /etc/easy-rsa/x509-types/
install -t /usr/share/licenses/easy-rsa -Dm644 COPYING.md gpl-2.0.txt
cd ..
rm -rf EasyRSA-3.2.1
# mpdecimal.
tar -xf mpdecimal-4.0.0.tar.gz
cd mpdecimal-4.0.0
./configure --prefix=/usr
make
make install
rm -f /usr/lib/libmpdec{,++}.a
install -t /usr/share/licenses/mpdecimal -Dm644 COPYRIGHT.txt
cd ..
rm -rf mpdecimal-4.0.0
# scdoc.
tar -xf scdoc-1.11.0.tar.gz
cd scdoc-1.11.0
sed -i 's/-Werror//g' Makefile
make PREFIX=/usr
make PREFIX=/usr install
install -t /usr/share/licenses/scdoc -Dm644 COPYING
cd ..
rm -rf scdoc-1.11.0
# kmod.
tar -xf kmod-33.tar.xz
cd kmod-33
./configure --prefix=/usr --sysconfdir=/etc --with-xz --with-zstd --with-zlib --with-openssl
make
make install
for target in depmod insmod modinfo modprobe rmmod; do ln -sf ../bin/kmod /usr/sbin/$target; done
ln -sf kmod /usr/bin/lsmod
install -t /usr/share/licenses/kmod -Dm644 COPYING
cd ..
rm -rf kmod-33
# Python (initial build; will be rebuilt later to support SQLite and Tk).
tar -xf Python-3.13.1.tar.xz
cd Python-3.13.1
./configure --prefix=/usr --enable-shared --enable-optimizations --with-system-expat --with-system-libmpdec --with-ensurepip --disable-test-modules
make
make install
ln -sf python3 /usr/bin/python
ln -sf pydoc3 /usr/bin/pydoc
ln -sf idle3 /usr/bin/idle
ln -sf python3-config /usr/bin/python-config
ln -sf pip3 /usr/bin/pip
install -t /usr/share/licenses/python -Dm644 LICENSE
cd ..
rm -rf Python-3.13.1
# flit-core.
tar -xf flit_core-3.10.1.tar.gz
cd flit_core-3.10.1
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist flit_core
install -t /usr/share/licenses/flit-core -Dm644 LICENSE
cd ..
rm -rf flit_core-3.10.1
# wheel.
tar -xf wheel-0.45.1.tar.gz
cd wheel-0.45.1
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist wheel
install -t /usr/share/licenses/wheel -Dm644 LICENSE.txt
cd ..
rm -rf wheel-0.45.1
# setuptools.
tar -xf setuptools-75.8.0.tar.gz
cd setuptools-75.8.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist setuptools
install -t /usr/share/licenses/setuptools -Dm644 LICENSE
cd ..
rm -rf setuptools-75.8.0
# pip.
tar -xf pip-24.3.1.tar.gz
cd pip-24.3.1
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pip --upgrade
install -t /usr/share/licenses/pip -Dm644 LICENSE.txt
cd ..
rm -rf pip-24.3.1
# Sphinx (required to build man pages of some packages).
mkdir -p sphinx
tar --no-same-owner --same-permissions -xf sphinx-8.1.3-x86_64-python3.13-venv.tar.xz -C sphinx --strip-components=1
# Ninja.
tar -xf ninja-1.12.1.tar.gz
cd ninja-1.12.1
python configure.py --bootstrap
install -m755 ninja /usr/bin
install -Dm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -Dm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja
install -t /usr/share/licenses/ninja -Dm644 COPYING
cd ..
rm -rf ninja-1.12.1
# Meson.
tar -xf meson-1.6.1.tar.gz
cd meson-1.6.1
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist meson
install -t /usr/share/bash-completion/completions -Dm644 data/shell-completions/bash/meson
install -t /usr/share/zsh/site-functions -Dm644 data/shell-completions/zsh/_meson
install -t /usr/share/licenses/meson -Dm644 COPYING
cd ..
rm -rf meson-1.6.1
# PyParsing.
tar -xf pyparsing-3.2.0.tar.gz
cd pyparsing-3.2.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pyparsing
install -t /usr/share/licenses/pyparsing -Dm644 LICENSE
cd ..
rm -rf pyparsing-3.2.0
# edittables.
tar -xf editables-0.5.tar.gz
cd editables-0.5
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist editables
install -t /usr/share/licenses/editables -Dm644 LICENSE.txt
cd ..
rm -rf editables-0.5
# packaging.
tar -xf packaging-24.2.tar.gz
cd packaging-24.2
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist packaging
install -t /usr/share/licenses/packaging -Dm644 LICENSE{,.APACHE,.BSD}
cd ..
rm -rf packaging-24.2
# pyproject-metadata.
tar -xf pyproject_metadata-0.9.0.tar.gz
cd pyproject_metadata-0.9.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pyproject-metadata
install -t /usr/share/licenses/pyproject-metadata -Dm644 LICENSE
cd ..
rm -rf pyproject_metadata-0.9.0
# typing-extensions
tar -xf typing_extensions-4.12.2.tar.gz
cd typing_extensions-4.12.2
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist typing_extensions
install -t /usr/share/licenses/typing-extensions -Dm644 LICENSE
cd ..
rm -rf typing_extensions-4.12.2
# setuptools-scm.
tar -xf setuptools_scm-8.0.4.tar.gz
cd setuptools-scm-8.0.4
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist setuptools_scm
install -t /usr/share/licenses/setuptools-scm -Dm644 LICENSE
cd ..
rm -rf setuptools-scm-8.0.4
# pathspec.
tar -xf pathspec-0.12.1.tar.gz
cd pathspec-0.12.1
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pathspec
install -t /usr/share/licenses/pathspec -Dm644 LICENSE
cd ..
rm -rf pathspec-0.12.1
# pluggy.
tar -xf pluggy-1.5.0.tar.gz
cd pluggy-1.5.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pluggy
install -t /usr/share/licenses/pluggy -Dm644 LICENSE
cd ..
rm -rf pluggy-1.5.0
# trove-classifiers.
tar -xf trove-classifiers-2024.9.12.tar.gz
cd trove-classifiers-2024.9.12
sed -i '/calver/s/^/#/;$iversion="2024.9.12"' setup.py
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist trove-classifiers
cd ..
rm -rf trove-classifiers-2024.9.12
# hatchling.
tar -xf hatchling-1.27.0.tar.gz
cd hatchling-1.27.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist hatchling
install -t /usr/share/licenses/hatching -Dm644 LICENSE.txt
cd ..
rm -rf hatchling-1.27.0
# six.
tar -xf six-1.16.0.tar.gz
cd six-1.16.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist six
install -t /usr/share/licenses/six -Dm644 LICENSE
cd ..
rm -rf six-1.16.0
# distro.
tar -xf distro-1.9.0.tar.gz
cd distro-1.9.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist distro
install -t /usr/share/licenses/distro -Dm644 LICENSE
cd ..
rm -rf distro-1.9.0
# libpwquality (Python bindings only, which could not be built before).
tar -xf libpwquality-1.4.5.tar.bz2
cd libpwquality-1.4.5
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist ./python
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pwquality
cd ..
rm -rf libpwquality-1.4.5
# libseccomp.
tar -xf libseccomp-2.5.5.tar.gz
cd libseccomp-2.5.5
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libseccomp -Dm644 LICENSE
cd ..
rm -rf libseccomp-2.5.5
# File.
tar -xf file-5.46.tar.gz
cd file-5.46
mkdir -p bootstrap; cd bootstrap
../configure --prefix=/usr --enable-libseccomp
make
cd ..
./configure --prefix=/usr --enable-libseccomp
make FILE_COMPILE="$PWD"/bootstrap/src/file
make install
install -t /usr/share/licenses/file -Dm644 COPYING
cd ..
rm -rf file-5.46
# Coreutils.
tar -xf coreutils-9.5.tar.xz
cd coreutils-9.5
./configure --prefix=/usr --enable-no-install-program=kill,uptime --with-packager="MassOS"
make
make install
mv /usr/bin/chroot /usr/sbin
mv /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
dircolors -p > /etc/dircolors
install -t /usr/share/licenses/coreutils -Dm644 COPYING
cd ..
rm -rf coreutils-9.5
# Diffutils.
tar -xf diffutils-3.10.tar.xz
cd diffutils-3.10
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/diffutils -Dm644 COPYING
cd ..
rm -rf diffutils-3.10
# Gawk.
tar -xf gawk-5.3.1.tar.xz
cd gawk-5.3.1
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/gawk -Dm644 COPYING
cd ..
rm -rf gawk-5.3.1
# Findutils.
tar -xf findutils-4.10.0.tar.xz
cd findutils-4.10.0
./configure --prefix=/usr --localstatedir=/var/lib/locate
make
make install
install -t /usr/share/licenses/findutils -Dm644 COPYING
cd ..
rm -rf findutils-4.10.0
# Groff.
tar -xf groff-1.23.0.tar.gz
cd groff-1.23.0
./configure --prefix=/usr
make -j1
make install
install -t /usr/share/licenses/groff -Dm644 COPYING LICENSES
cd ..
rm -rf groff-1.23.0
# Gzip.
tar -xf gzip-1.13.tar.xz
cd gzip-1.13
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/gzip -Dm644 COPYING
cd ..
rm -rf gzip-1.13
# Texinfo.
tar -xf texinfo-7.2.tar.xz
cd texinfo-7.2
./configure --prefix=/usr
make
make install
make TEXMF=/usr/share/texmf install-tex
install -t /usr/share/licenses/texinfo -Dm644 COPYING
cd ..
rm -rf texinfo-7.2
# Sharutils.
tar -xf sharutils-4.15.2.tar.xz
cd sharutils-4.15.2
sed -i 's/BUFSIZ/rw_base_size/' src/unshar.c
sed -i '/program_name/s/^/extern /' src/*opts.h
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/sharutils -Dm644 COPYING
cd ..
rm -rf sharutils-4.15.2
# LMDB.
tar -xf LMDB_0.9.31.tar.gz
cd lmdb-LMDB_0.9.31/libraries/liblmdb
make CFLAGS="$CFLAGS"
sed -i 's| liblmdb.a||' Makefile
make prefix=/usr install
install -t /usr/share/licenses/lmdb -Dm644 COPYRIGHT LICENSE
cd ../../..
rm -rf lmdb-LMDB_0.9.31
# Cyrus SASL (will be rebuilt later to support krb5 and OpenLDAP).
tar -xf cyrus-sasl-2.1.28.tar.gz
cd cyrus-sasl-2.1.28
sed -i '/saslint/a #include <time.h>' lib/saslutil.c
sed -i '/plugin_common/a #include <time.h>' plugins/cram.c
./configure --prefix=/usr --sysconfdir=/etc --enable-auth-sasldb --with-dbpath=/var/lib/sasl/sasldb2 --with-sphinx-build=no --with-saslauthd=/var/run/saslauthd
make -j1
make -j1 install
install -t /usr/share/licenses/cyrus-sasl -Dm644 COPYING
cd ..
rm -rf cyrus-sasl-2.1.28
# libmnl.
tar -xf libmnl-1.0.5.tar.bz2
cd libmnl-1.0.5
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/libmnl -Dm644 COPYING
cd ..
rm -rf libmnl-1.0.5
# libnftnl.
tar -xf libnftnl-1.2.8.tar.xz
cd libnftnl-1.2.8
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/libnftnl -Dm644 COPYING
cd ..
rm -rf libnftnl-1.2.8
# libnfnetlink.
tar -xf libnfnetlink-1.0.2.tar.bz2
cd libnfnetlink-1.0.2
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/libnfnetlink -Dm644 COPYING
cd ..
rm -rf libnfnetlink-1.0.2
# nftables (will be rebuilt after Jansson for JSON support).
tar -xf nftables-1.1.1.tar.xz
cd nftables-1.1.1
./configure --prefix=/usr --sysconfdir=/etc --disable-debug --without-json
make
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist ./py
make install
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist nftables
install -t /usr/share/licenses/nftables -Dm644 COPYING
cd ..
rm -rf nftables-1.1.1
# iptables.
tar -xf iptables-1.8.11.tar.xz
cd iptables-1.8.11
./configure --prefix=/usr --enable-libipq --enable-nftables
make
make install
install -t /usr/share/licenses/iptables -Dm644 COPYING
cd ..
rm -rf iptables-1.8.11
# UFW.
tar -xf ufw-0.36.2.tar.gz
cd ufw-0.36.2
python setup.py install
install -t /usr/share/licenses/ufw -Dm644 COPYING
cd ..
rm -rf ufw-0.36.2
# IPRoute2.
tar -xf iproute2-6.12.0.tar.xz
cd iproute2-6.12.0
make
make SBINDIR=/usr/sbin install
install -t /usr/share/licenses/iproute2 -Dm644 COPYING
cd ..
rm -rf iproute2-6.12.0
# Kbd.
tar -xf kbd-2.7.1.tar.xz
cd kbd-2.7.1
patch -Np1 -i ../patches/kbd-2.4.0-backspace-1.patch
sed -i 's/RESIZECONS_PROGS=yes/RESIZECONS_PROGS=no/g' configure
./configure --prefix=/usr --disable-tests
make
make install
rm -f /usr/share/man/man8/resizecons.8
install -t /usr/share/licenses/kbd -Dm644 COPYING
cd ..
rm -rf kbd-2.7.1
# libpipeline.
tar -xf libpipeline-1.5.8.tar.gz
cd libpipeline-1.5.8
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/libpipeline -Dm644 COPYING
cd ..
rm -rf libpipeline-1.5.8
# libunwind.
tar -xf libunwind-1.6.2.tar.gz
cd libunwind-1.6.2
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libunwind -Dm644 COPYING
cd ..
rm -rf libunwind-1.6.2
# libuv.
tar -xf libuv-v1.50.0.tar.gz
cd libuv-v1.50.0
./autogen.sh
./configure --prefix=/usr --disable-static
make
make -C docs man
make install
install -t /usr/share/man/man1 -Dm644 docs/build/man/libuv.1
install -t /usr/share/licenses/libuv -Dm644 LICENSE
cd ..
rm -rf libuv-v1.50.0
# Make.
tar -xf make-4.4.1.tar.gz
cd make-4.4.1
./configure --prefix=/usr
make
make install
ln -sf make /usr/bin/gmake
ln -sf make.1 /usr/share/man/gmake.1
install -t /usr/share/licenses/make -Dm644 COPYING
cd ..
rm -rf make-4.4.1
# Ed.
tar -xf ed-1.21.tar.lz
cd ed-1.21
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/ed -Dm644 COPYING
cd ..
rm -rf ed-1.21
# Patch.
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/patch -Dm644 COPYING
cd ..
rm -rf patch-2.7.6
# tar.
tar -xf tar-1.35.tar.xz
cd tar-1.35
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/tar -Dm644 COPYING
cd ..
rm -rf tar-1.35
# Nano.
tar -xf nano-8.3.tar.xz
cd nano-8.3
./configure --prefix=/usr --sysconfdir=/etc --enable-utf8
make
make install
cp doc/sample.nanorc /etc/nanorc
sed -i '0,/# include/{s/# include/include/}' /etc/nanorc
install -t /usr/share/licenses/nano -Dm644 COPYING
cd ..
rm -rf nano-8.3
# dos2unix.
tar -xf dos2unix-7.5.2.tar.gz
cd dos2unix-7.5.2
make
make install
install -t /usr/share/licenses/dos2unix -Dm644 COPYING.txt
cd ..
rm -rf dos2unix-7.5.2
# docutils.
tar -xf docutils-0.21.2.tar.gz
cd docutils-0.21.2
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist docutils
install -t /usr/share/licenses/docutils -Dm644 COPYING.txt
cd ..
rm -rf docutils-0.21.2
# MarkupSafe.
tar -xf markupsafe-3.0.2.tar.gz
cd markupsafe-3.0.2
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist MarkupSafe
install -t /usr/share/licenses/markupsafe -Dm644 LICENSE.txt
cd ..
rm -rf markupsafe-3.0.2
# Jinja2.
tar -xf jinja2-3.1.4.tar.gz
cd jinja2-3.1.4
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist Jinja2
install -t /usr/share/licenses/jinja2 -Dm644 LICENSE.txt
cd ..
rm -rf jinja2-3.1.4
# Mako.
tar -xf mako-1.3.7.tar.gz
cd mako-rel_1_3_7
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist Mako
install -t /usr/share/licenses/mako -Dm644 LICENSE
cd ..
rm -rf mako-rel_1_3_7
# pyxdg.
tar -xf pyxdg-0.28.tar.gz
cd pyxdg-0.28
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pyxdg
install -t /usr/share/licenses/pyxdg -Dm644 COPYING
cd ..
rm -rf pyxdg-0.28
# pefile.
tar -xf pefile-2024.8.26.tar.gz
cd pefile-2024.8.26
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pefile
install -t /usr/share/licenses/pefile -Dm644 LICENSE
cd ..
rm -rf pefile-2024.8.26
# pyelftools.
tar -xf pyelftools-0.31.tar.gz
cd pyelftools-0.31
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pyelftools
install -t /usr/share/licenses/pyelftools -Dm644 LICENSE
cd ..
rm -rf pyelftools-0.31
# Pygments.
tar -xf pygments-2.19.1.tar.gz
cd pygments-2.19.1
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist Pygments
install -t /usr/share/licenses/pygments -Dm644 LICENSE
cd ..
rm -rf pygments-2.19.1
# toml.
tar -xf toml-0.10.2.tar.gz
cd toml-0.10.2
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist toml
install -t /usr/share/licenses/toml -Dm644 LICENSE
cd ..
rm -rf toml-0.10.2
# semantic-version.
tar -xf semantic_version-2.10.0.tar.gz
cd semantic_version-2.10.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist semantic_version
install -t /usr/share/licenses/semantic-version -Dm644 LICENSE
cd ..
rm -rf semantic_version-2.10.0
# smartypants.
tar -xf smartypants.py-2.0.1.tar.gz
cd smartypants.py-2.0.1
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist smartypants
install -t /usr/share/licenses/smartypants -Dm644 COPYING
cd ..
rm -rf smartypants.py-2.0.1
# typogrify.
tar -xf typogrify-2.0.7.tar.gz
cd typogrify-2.0.7
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist typogrify
install -t /usr/share/licenses/typogrify -Dm644 LICENSE.txt
cd ..
rm -rf typogrify-2.0.7
# zipp.
tar -xf zipp-3.21.0.tar.gz
cd zipp-3.21.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist zipp
install -t /usr/share/licenses/zipp -Dm644 LICENSE
cd ..
rm -rf zipp-3.21.0
# importlib-metadata
tar -xf importlib_metadata-8.5.0.tar.gz
cd importlib_metadata-8.5.0
rm -f exercises.py
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist importlib_metadata
install -t /usr/share/licenses/importlib-metadata -Dm644 LICENSE
cd ..
rm -rf importlib_metadata-8.5.0
# lark.
tar -xf lark-1.2.2.tar.gz
cd lark-1.2.2
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist lark
install -t /usr/share/licenses/lark -Dm644 LICENSE
cd ..
rm -rf lark-1.2.2
# fastjsonschema.
tar -xf fastjsonschema-2.21.0.tar.gz
cd fastjsonschema-2.21.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist fastjsonschema
install -t /usr/share/licenses/fastjsonschema -Dm644 LICENSE
cd ..
rm -rf fastjsonschema-2.21.0
# poetry-core.
tar -xf poetry_core-1.9.1.tar.gz
cd poetry_core-1.9.1
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist poetry_core
install -t /usr/share/licenses/poetry-core -Dm644 LICENSE
cd ..
rm -rf poetry_core-1.9.1
# Markdown.
tar -xf markdown-3.7.tar.gz
cd markdown-3.7
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist Markdown
install -t /usr/share/licenses/markdown -Dm644 LICENSE.md
cd ..
rm -rf markdown-3.7
# python-distutils-extra.
tar -xf python-distutils-extra-2.39.tar.gz
cd python-distutils-extra-2.39
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist python-distutils-extra
install -t /usr/share/licenses/python-distutils-extra -Dm644 LICENSE
cd ..
rm -rf python-distutils-extra-2.39
# ptyprocess.
tar -xf ptyprocess-0.7.0.tar.gz
cd ptyprocess-0.7.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist ptyprocess
install -t /usr/share/licenses/ptyprocess -Dm644 LICENSE
cd ..
rm -rf ptyprocess-0.7.0
# pexpect.
tar -xf pexpect-4.9.tar.gz
cd pexpect-4.9
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pexpect
install -t /usr/share/licenses/pexpect -Dm644 LICENSE
cd ..
rm -rf pexpect-4.9
# ply.
tar -xf ply-3.11.tar.gz
cd ply-3.11
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist ply
install -t /usr/share/licenses/ply -Dm644 ../extra-package-licenses/ply-license.txt
cd ..
rm -rf ply-3.11
# Cython.
tar -xf cython-3.0.11.tar.gz
cd cython-3.0.11
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist Cython
install -t /usr/share/licenses/cython -Dm644 COPYING.txt LICENSE.txt
cd ..
rm -rf cython-3.0.11
# gi-docgen.
tar -xf gi-docgen-2024.1.tar.xz
cd gi-docgen-2024.1
meson setup build --prefix=/usr --buildtype=minsize -Ddevelopment_tests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gi-docgen -Dm644 LICENSES/{Apache-2.0.txt,GPL-3.0-or-later.txt}
cd ..
rm -rf gi-docgen-2024.1
# Locale-gettext.
tar -xf Locale-gettext-1.07.tar.gz
cd Locale-gettext-1.07
perl Makefile.PL
make
make install
install -dm755 /usr/share/licenses/locale-gettext
cat README | head -n16 | tail -n6 > /usr/share/licenses/locale-gettext/COPYING
cd ..
rm -rf Locale-gettext-1.07
# help2man.
tar -xf help2man-1.49.3.tar.xz
cd help2man-1.49.3
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/help2man -Dm644 COPYING
cd ..
rm -rf help2man-1.49.3
# dialog.
tar -xf dialog-1.3-20240619.tgz
cd dialog-1.3-20240619
./configure --prefix=/usr --enable-nls --with-libtool --with-ncursesw
make
make install
rm -f /usr/lib/libdialog.a
chmod 755 /usr/lib/libdialog.so.15.0.0
install -t /usr/share/licenses/dialog -Dm644 COPYING
cd ..
rm -rf dialog-1.3-20240619
# acpi.
tar -xf acpi-1.7.tar.gz
cd acpi-1.7
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/acpi -Dm644 COPYING
cd ..
rm -rf acpi-1.7
# rpcsvc-proto.
tar -xf rpcsvc-proto-1.4.4.tar.xz
cd rpcsvc-proto-1.4.4
./configure --sysconfdir=/etc
make
make install
install -t /usr/share/licenses/rpcsvc-proto -Dm644 COPYING
cd ..
rm -rf rpcsvc-proto-1.4.4
# Which.
tar -xf which-2.21.tar.gz
cd which-2.21
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/which -Dm644 COPYING
cd ..
rm -rf which-2.21
# tree.
tar -xf unix-tree-2.2.1.tar.bz2
cd unix-tree-2.2.1
make CFLAGS="$CFLAGS"
make PREFIX=/usr MANDIR=/usr/share/man install
chmod 644 /usr/share/man/man1/tree.1
install -t /usr/share/licenses/tree -Dm644 LICENSE
cd ..
rm -rf unix-tree-2.2.1
# GPM.
tar -xf gpm-1.20.7-38-ge82d1a6.tar.gz
cd gpm-e82d1a653ca94aa4ed12441424da6ce780b1e530
patch -Np1 -i ../patches/gpm-1.20.7-pregenerated-docs.patch
./autogen.sh
./configure --prefix=/usr --sysconfdir=/etc
make
make install
ln -sf libgpm.so.2.1.0 /usr/lib/libgpm.so
rm -f /usr/lib/libgpm.a
install -t /etc -m644 conf/gpm-root.conf
install -t /usr/share/info -vDm644 doc/gpm.info
install -t /usr/share/man/man1 -vDm644 doc/{gpm-root,mev,mouse-test}.1
install -t /usr/share/man/man7 -vDm644 doc/gpm-types.7
install -t /usr/share/man/man8 -vDm644 doc/gpm.8
install-info --dir-file=/usr/share/info/dir /usr/share/info/gpm.info
install -t /usr/share/licenses/gpm -Dm644 COPYING
cd ..
rm -rf gpm-e82d1a653ca94aa4ed12441424da6ce780b1e530
# pv.
tar -xf pv-1.9.25.tar.gz
cd pv-1.9.25
./configure --prefix=/usr --mandir=/usr/share/man
make
make install
install -t /usr/share/licenses/pv -Dm644 docs/COPYING
cd ..
rm -rf pv-1.9.25
# liburing.
tar -xf liburing-2.8.tar.gz
cd liburing-liburing-2.8
./configure --prefix=/usr --mandir=/usr/share/man
make
make install
rm -f /usr/lib/liburing{,-ffi}.a
cd ..
rm -rf liburing-liburing-2.8
# duktape.
tar -xf duktape-2.7.0.tar.xz
cd duktape-2.7.0
CFLAGS="$CFLAGS -DDUK_USE_FASTINT" LDFLAGS="$LDFLAGS -lm" make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr
make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr install
install -t /usr/share/licenses/duktape -Dm644 LICENSE.txt
cd ..
rm -rf duktape-2.7.0
# oniguruma.
tar -xf onig-6.9.9.tar.gz
cd onig-6.9.9
./configure --prefix=/usr --disable-static --enable-posix-api
make
make install
install -t /usr/share/licenses/oniguruma -Dm644 COPYING
cd ..
rm -rf onig-6.9.9
# jq.
tar -xf jq-1.7.1.tar.gz
cd jq-1.7.1
./configure --prefix=/usr --disable-docs --disable-static
make
make install
install -t /usr/share/licenses/jq -Dm644 COPYING
cd ..
rm -rf jq-1.7.1
# ICU.
tar -xf icu4c-76_1-src.tgz
cd icu/source
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/icu -Dm644 ../LICENSE
cd ../..
rm -rf icu
# Boost.
tar -xf boost-1.87.0-b2-nodocs.tar.xz
cd boost-1.87.0
./bootstrap.sh --prefix=/usr --with-icu
./b2 stage -j$(nproc) threading=multi link=shared
./b2 install threading=multi link=shared
install -t /usr/share/licenses/boost -Dm644 LICENSE_1_0.txt
cd ..
rm -rf boost-1.87.0
# libgpg-error.
tar -xf libgpg-error-1.51.tar.bz2
cd libgpg-error-1.51
./configure --prefix=/usr --enable-install-gpg-error-config
make
make install
install -t /usr/share/licenses/libgpg-error -Dm644 COPYING COPYING.LIB
cd ..
rm -rf libgpg-error-1.51
# libgcrypt.
tar -xf libgcrypt-1.11.0.tar.bz2
cd libgcrypt-1.11.0
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/libgcrypt -Dm644 COPYING COPYING.LIB
cd ..
rm -rf libgcrypt-1.11.0
# Unzip.
tar -xf unzip60.tar.gz
cd unzip60
patch -Np1 -i ../patches/unzip-6.0-manyfixes.patch
make -f unix/Makefile generic
make prefix=/usr MANDIR=/usr/share/man/man1 -f unix/Makefile install
install -t /usr/share/licenses/unzip -Dm644 LICENSE
cd ..
rm -rf unzip60
# Zip.
tar -xf zip30.tar.gz
cd zip30
make -f unix/Makefile generic CC="gcc -std=gnu89"
make prefix=/usr MANDIR=/usr/share/man/man1 -f unix/Makefile install
install -t /usr/share/licenses/zip -Dm644 LICENSE
cd ..
rm -rf zip30
# minizip.
tar -xf zlib-1.3.1.tar.xz
cd zlib-1.3.1/contrib/minizip
autoreconf -fi
./configure --prefix=/usr --enable-static=no
make
make install
install -t /usr/share/licenses/minizip -Dm644 /usr/share/licenses/zlib/LICENSE
cd ../../..
rm -rf zlib-1.3.1
# libmicrodns.
tar -xf microdns-0.2.0.tar.xz
cd microdns-0.2.0
meson setup build --prefix=/usr --buildtype=minsize -Dexamples=disabled -Dtests=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libmicrodns -Dm644 COPYING
cd ..
rm -rf microdns-0.2.0
# libsodium.
tar -xf libsodium-1.0.20.tar.gz
cd libsodium-1.0.20
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libsodium -Dm644 LICENSE
cd ..
rm -rf libsodium-1.0.20
# sgml-common.
tar -xf sgml-common-0.6.3.tgz
cd sgml-common-0.6.3
patch -Np1 -i ../patches/sgml-common-0.6.3-manpage-1.patch
autoreconf -fi
./configure --prefix=/usr --sysconfdir=/etc
make
make docdir=/usr/share/doc install
install-catalog --add /etc/sgml/sgml-ent.cat /usr/share/sgml/sgml-iso-entities-8879.1986/catalog
install-catalog --add /etc/sgml/sgml-docbook.cat /etc/sgml/sgml-ent.cat
cd ..
rm -rf sgml-common-0.6.3
# Docbook 3.1 DTD.
mkdir docbk31
cd docbk31
unzip -q ../docbk31.zip
sed -i -e '/ISO 8879/d' -e 's|DTDDECL "-//OASIS//DTD DocBook V3.1//EN"|SGMLDECL|g' docbook.cat
install -dm755 /usr/share/sgml/docbook/sgml-dtd-3.1
chown -R root:root .
install docbook.cat /usr/share/sgml/docbook/sgml-dtd-3.1/catalog
cp -af *.dtd *.mod *.dcl /usr/share/sgml/docbook/sgml-dtd-3.1
install-catalog --add /etc/sgml/sgml-docbook-dtd-3.1.cat /usr/share/sgml/docbook/sgml-dtd-3.1/catalog
install-catalog --add /etc/sgml/sgml-docbook-dtd-3.1.cat /etc/sgml/sgml-docbook.cat
cat >> /usr/share/sgml/docbook/sgml-dtd-3.1/catalog << "END"
  -- Begin Single Major Version catalog changes --

PUBLIC "-//Davenport//DTD DocBook V3.0//EN" "docbook.dtd"

  -- End Single Major Version catalog changes --
END
cd ..
rm -rf docbk31
# Docbook 4.5 DTD.
mkdir docbook-4.5
cd docbook-4.5
unzip -q ../docbook-4.5.zip
sed -i -e '/ISO 8879/d' -e '/gml/d' docbook.cat
install -d /usr/share/sgml/docbook/sgml-dtd-4.5
chown -R root:root .
install docbook.cat /usr/share/sgml/docbook/sgml-dtd-4.5/catalog
cp -af *.dtd *.mod *.dcl /usr/share/sgml/docbook/sgml-dtd-4.5
install-catalog --add /etc/sgml/sgml-docbook-dtd-4.5.cat /usr/share/sgml/docbook/sgml-dtd-4.5/catalog
install-catalog --add /etc/sgml/sgml-docbook-dtd-4.5.cat /etc/sgml/sgml-docbook.cat
cat >> /usr/share/sgml/docbook/sgml-dtd-4.5/catalog << "END"
  -- Begin Single Major Version catalog changes --

PUBLIC "-//OASIS//DTD DocBook V4.4//EN" "docbook.dtd"
PUBLIC "-//OASIS//DTD DocBook V4.3//EN" "docbook.dtd"
PUBLIC "-//OASIS//DTD DocBook V4.2//EN" "docbook.dtd"
PUBLIC "-//OASIS//DTD DocBook V4.1//EN" "docbook.dtd"
PUBLIC "-//OASIS//DTD DocBook V4.0//EN" "docbook.dtd"

  -- End Single Major Version catalog changes --
END
cd ..
rm -rf docbook-4.5
# libxml2.
tar -xf libxml2-2.13.5.tar.xz
cd libxml2-2.13.5
./configure --prefix=/usr --sysconfdir=/etc --disable-static --with-history --with-icu --with-threads PYTHON=/usr/bin/python3
make
make install
rm -f /usr/lib/libxml2.la
sed -i '/libs=/s/xml2.*/xml2"/' /usr/bin/xml2-config
install -t /usr/share/licenses/libxml2 -Dm644 Copyright
cd ..
rm -rf libxml2-2.13.5
# libarchive.
tar -xf libarchive-3.7.7.tar.xz
cd libarchive-3.7.7
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libarchive -Dm644 COPYING
cd ..
rm -rf libarchive-3.7.7
# Docbook XML 4.5.
mkdir docbook-xml-4.5
cd docbook-xml-4.5
unzip -q ../docbook-xml-4.5.zip
install -dm755 /usr/share/xml/docbook/xml-dtd-4.5
install -dm755 /etc/xml
chown -R root:root .
cp -af docbook.cat *.dtd ent/ *.mod /usr/share/xml/docbook/xml-dtd-4.5
test -e /etc/xml/docbook || xmlcatalog --noout --create /etc/xml/docbook
xmlcatalog --noout --add "public" "-//OASIS//DTD DocBook XML V4.5//EN" "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" /etc/xml/docbook
xmlcatalog --noout --add "public" "-//OASIS//DTD DocBook XML CALS Table Model V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/calstblx.dtd" /etc/xml/docbook
xmlcatalog --noout --add "public" "-//OASIS//DTD XML Exchange Table Model 19990315//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/soextblx.dtd" /etc/xml/docbook
xmlcatalog --noout --add "public" "-//OASIS//ELEMENTS DocBook XML Information Pool V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/dbpoolx.mod" /etc/xml/docbook
xmlcatalog --noout --add "public" "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/dbhierx.mod" /etc/xml/docbook
xmlcatalog --noout --add "public" "-//OASIS//ELEMENTS DocBook XML HTML Tables V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/htmltblx.mod" /etc/xml/docbook
xmlcatalog --noout --add "public" "-//OASIS//ENTITIES DocBook XML Notations V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/dbnotnx.mod" /etc/xml/docbook
xmlcatalog --noout --add "public" "-//OASIS//ENTITIES DocBook XML Character Entities V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/dbcentx.mod" /etc/xml/docbook
xmlcatalog --noout --add "public" "-//OASIS//ENTITIES DocBook XML Additional General Entities V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/dbgenent.mod" /etc/xml/docbook
xmlcatalog --noout --add "rewriteSystem" "http://www.oasis-open.org/docbook/xml/4.5" "file:///usr/share/xml/docbook/xml-dtd-4.5" /etc/xml/docbook
xmlcatalog --noout --add "rewriteURI" "http://www.oasis-open.org/docbook/xml/4.5" "file:///usr/share/xml/docbook/xml-dtd-4.5" /etc/xml/docbook
test -e /etc/xml/catalog || xmlcatalog --noout --create /etc/xml/catalog
xmlcatalog --noout --add "delegatePublic" "-//OASIS//ENTITIES DocBook XML" "file:///etc/xml/docbook" /etc/xml/catalog
xmlcatalog --noout --add "delegatePublic" "-//OASIS//DTD DocBook XML" "file:///etc/xml/docbook" /etc/xml/catalog
xmlcatalog --noout --add "delegateSystem" "http://www.oasis-open.org/docbook/" "file:///etc/xml/docbook" /etc/xml/catalog
xmlcatalog --noout --add "delegateURI" "http://www.oasis-open.org/docbook/" "file:///etc/xml/docbook" /etc/xml/catalog
for DTDVERSION in 4.1.2 4.2 4.3 4.4; do
  xmlcatalog --noout --add "public" "-//OASIS//DTD DocBook XML V$DTDVERSION//EN" "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" /etc/xml/docbook
  xmlcatalog --noout --add "rewriteSystem" "http://www.oasis-open.org/docbook/xml/$DTDVERSION" "file:///usr/share/xml/docbook/xml-dtd-4.5" /etc/xml/docbook
  xmlcatalog --noout --add "rewriteURI" "http://www.oasis-open.org/docbook/xml/$DTDVERSION" "file:///usr/share/xml/docbook/xml-dtd-4.5" /etc/xml/docbook
  xmlcatalog --noout --add "delegateSystem" "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" "file:///etc/xml/docbook" /etc/xml/catalog
  xmlcatalog --noout --add "delegateURI" "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" "file:///etc/xml/docbook" /etc/xml/catalog
done
cd ..
rm -rf docbook-xml-4.5
# docbook-xsl-nons.
tar -xf docbook-xsl-nons-1.79.2.tar.bz2
cd docbook-xsl-nons-1.79.2
patch -Np1 -i ../patches/docbook-xsl-nons-1.79.2-stack_fix-1.patch
install -dm755 /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2
cp -R VERSION assembly common eclipse epub epub3 extensions fo highlighting html htmlhelp images javahelp lib manpages params profiling roundtrip slides template tests tools webhelp website xhtml xhtml-1_1 xhtml5 /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2
ln -s VERSION /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2/VERSION.xsl
install -Dm644 README /usr/share/doc/docbook-xsl-nons-1.79.2/README.txt
install -m644 RELEASE-NOTES* NEWS* /usr/share/doc/docbook-xsl-nons-1.79.2
if [ ! -d /etc/xml ]; then install -dm755 /etc/xml; fi
if [ ! -f /etc/xml/catalog ]; then
  xmlcatalog --noout --create /etc/xml/catalog
fi
xmlcatalog --noout --add "rewriteSystem" "https://cdn.docbook.org/release/xsl-nons/1.79.2" "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" /etc/xml/catalog
xmlcatalog --noout --add "rewriteURI" "https://cdn.docbook.org/release/xsl-nons/1.79.2" "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" /etc/xml/catalog
xmlcatalog --noout --add "rewriteSystem" "https://cdn.docbook.org/release/xsl-nons/current" "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" /etc/xml/catalog
xmlcatalog --noout --add "rewriteURI" "https://cdn.docbook.org/release/xsl-nons/current" "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" /etc/xml/catalog
xmlcatalog --noout --add "rewriteSystem" "http://docbook.sourceforge.net/release/xsl/current" "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" /etc/xml/catalog
xmlcatalog --noout --add "rewriteURI" "http://docbook.sourceforge.net/release/xsl/current" "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" /etc/xml/catalog
install -t /usr/share/licenses/docbook-xsl -Dm644 COPYING
cd ..
rm -rf docbook-xsl-nons-1.79.2
# libxslt.
tar -xf libxslt-1.1.42.tar.xz
cd libxslt-1.1.42
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libxslt -Dm644 COPYING
cd ..
rm -rf libxslt-1.1.42
# Lynx.
tar -xf lynx2.9.2.tar.bz2
cd lynx2.9.2
./configure --prefix=/usr --sysconfdir=/etc/lynx --datadir=/usr/share/doc/lynx --with-bzlib --with-screen=ncursesw --with-ssl --with-zlib --enable-gzip-help --enable-ipv6 --enable-locale-charset
make
make install-full
sed -i 's/#LOCALE_CHARSET:FALSE/LOCALE_CHARSET:TRUE/' /etc/lynx/lynx.cfg
sed -i 's/#DEFAULT_EDITOR:/DEFAULT_EDITOR:nano/' /etc/lynx/lynx.cfg
sed -i 's/#PERSISTENT_COOKIES:FALSE/PERSISTENT_COOKIES:TRUE/' /etc/lynx/lynx.cfg
install -t /usr/share/licenses/lynx -Dm644 COPYHEADER COPYING
cd ..
rm -rf lynx2.9.2
# xmlto.
tar -xf xmlto-0.0.29.tar.bz2
cd xmlto-0.0.29
autoreconf -fi
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/xmlto -Dm644 COPYING
cd ..
rm -rf xmlto-0.0.29
# OpenSP.
tar -xf OpenSP-1.5.2.tar.gz
cd OpenSP-1.5.2
patch -Np1 -i ../patches/OpenSP-1.5.2-GCC14.patch
sed -i 's/32,/253,/' lib/Syntax.cxx
sed -i 's/LITLEN          240 /LITLEN          8092/' unicode/{gensyntax.pl,unicode.syn}
./configure --prefix=/usr --disable-static --enable-default-catalog=/etc/sgml/catalog --enable-default-search-path=/usr/share/sgml --enable-http
make pkgdatadir=/usr/share/sgml/OpenSP-1.5.2
make pkgdatadir=/usr/share/sgml/OpenSP-1.5.2 docdir=/usr/share/doc/OpenSP-1.5.2 install
ln -sf onsgmls /usr/bin/nsgmls
ln -sf osgmlnorm /usr/bin/sgmlnorm
ln -sf ospam /usr/bin/spam
ln -sf ospcat /usr/bin/spcat
ln -sf ospent /usr/bin/spent
ln -sf osx /usr/bin/sx
ln -sf osx /usr/bin/sgml2xml
ln -sf libosp.so /usr/lib/libsp.so
install -t /usr/share/licenses/opensp -Dm644 COPYING
cd ..
rm -rf OpenSP-1.5.2
# OpenJade.
tar -xf openjade-1.3.2.tar.gz
cd openjade-1.3.2
patch -Np1 -i ../patches/openjade-1.3.2-upstream-1.patch
sed -i -e '/getopts/{N;s#&G#g#;s#do .getopts.pl.;##;}' -e '/use POSIX/ause Getopt::Std;' msggen.pl
CXXFLAGS="$CXXFLAGS -fno-lifetime-dse" ./configure --prefix=/usr --mandir=/usr/share/man --enable-http --disable-static --enable-default-catalog=/etc/sgml/catalog --enable-default-search-path=/usr/share/sgml --datadir=/usr/share/sgml/openjade-1.3.2
make
make install
make install-man
ln -sf openjade /usr/bin/jade
ln -sf libogrove.so /usr/lib/libgrove.so
ln -sf libospgrove.so /usr/lib/libspgrove.so
ln -sf libostyle.so /usr/lib/libstyle.so
install -m644 dsssl/catalog /usr/share/sgml/openjade-1.3.2/
install -m644 dsssl/*.{dtd,dsl,sgm} /usr/share/sgml/openjade-1.3.2
install-catalog --add /etc/sgml/openjade-1.3.2.cat /usr/share/sgml/openjade-1.3.2/catalog
install-catalog --add /etc/sgml/sgml-docbook.cat /etc/sgml/openjade-1.3.2.cat
echo "SYSTEM \"http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd\" \"/usr/share/xml/docbook/xml-dtd-4.5/docbookx.dtd\"" >> /usr/share/sgml/openjade-1.3.2/catalog
install -t /usr/share/licenses/openjade -Dm644 COPYING
cd ..
rm -rf openjade-1.3.2
# docbook-dsssl.
tar -xf docbook-dsssl-1.79.tar.bz2
cd docbook-dsssl-1.79
install -m755 bin/collateindex.pl /usr/bin
install -m644 bin/collateindex.pl.1 /usr/share/man/man1
install -dm755 /usr/share/sgml/docbook/dsssl-stylesheets-1.79
cp -R * /usr/share/sgml/docbook/dsssl-stylesheets-1.79
install-catalog --add /etc/sgml/dsssl-docbook-stylesheets.cat /usr/share/sgml/docbook/dsssl-stylesheets-1.79/catalog
install-catalog --add /etc/sgml/dsssl-docbook-stylesheets.cat /usr/share/sgml/docbook/dsssl-stylesheets-1.79/common/catalog
install-catalog --add /etc/sgml/sgml-docbook.cat /etc/sgml/dsssl-docbook-stylesheets.cat
cd ..
rm -rf docbook-dsssl-1.79
# docbook-utils.
tar -xf docbook-utils-0.6.14.tar.gz
cd docbook-utils-0.6.14
patch -Np1 -i ../patches/docbook-utils-0.6.14-grep.patch
sed -i 's:/html::' doc/HTML/Makefile.in
./configure --prefix=/usr --mandir=/usr/share/man
make
make docdir=/usr/share/doc install
for doctype in html ps dvi man pdf rtf tex texi txt; do ln -svf docbook2$doctype /usr/bin/db2$doctype; done
install -t /usr/share/licenses/docbook-utils -Dm644 COPYING
cd ..
rm -rf docbook-utils-0.6.14
# Docbook XML 5.0.
unzip -q docbook-5.0.zip
cd docbook-5.0
install -dm755 /usr/share/xml/docbook/schema/{dtd,rng,sch,xsd}/5.0
install -m644  dtd/* /usr/share/xml/docbook/schema/dtd/5.0
install -m644  rng/* /usr/share/xml/docbook/schema/rng/5.0
install -m644  sch/* /usr/share/xml/docbook/schema/sch/5.0
install -m644  xsd/* /usr/share/xml/docbook/schema/xsd/5.0
if [ ! -e /etc/xml/docbook-5.0 ]; then
  xmlcatalog --noout --create /etc/xml/docbook-5.0
fi
xmlcatalog --noout --add "public" "-//OASIS//DTD DocBook XML 5.0//EN" "file:///usr/share/xml/docbook/schema/dtd/5.0/docbook.dtd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "system" "http://www.oasis-open.org/docbook/xml/5.0/dtd/docbook.dtd" "file:///usr/share/xml/docbook/schema/dtd/5.0/docbook.dtd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "system" "http://docbook.org/xml/5.0/dtd/docbook.dtd" "file:///usr/share/xml/docbook/schema/dtd/5.0/docbook.dtd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/rng/docbook.rng" "file:///usr/share/xml/docbook/schema/rng/5.0/docbook.rng" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/rng/docbook.rng" "file:///usr/share/xml/docbook/schema/rng/5.0/docbook.rng" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/rng/docbookxi.rng" "file:///usr/share/xml/docbook/schema/rng/5.0/docbookxi.rng" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/rng/docbookxi.rng" "file:///usr/share/xml/docbook/schema/rng/5.0/docbookxi.rng" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/rnc/docbook.rnc" "file:///usr/share/xml/docbook/schema/rng/5.0/docbook.rnc" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/rng/docbook.rnc" "file:///usr/share/xml/docbook/schema/rng/5.0/docbook.rnc" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/rnc/docbookxi.rnc" "file:///usr/share/xml/docbook/schema/rng/5.0/docbookxi.rnc" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/rng/docbookxi.rnc" "file:///usr/share/xml/docbook/schema/rng/5.0/docbookxi.rnc" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/xsd/docbook.xsd" "file:///usr/share/xml/docbook/schema/xsd/5.0/docbook.xsd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/xsd/docbook.xsd" "file:///usr/share/xml/docbook/schema/xsd/5.0/docbook.xsd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/xsd/docbookxi.xsd" "file:///usr/share/xml/docbook/schema/xsd/5.0/docbookxi.xsd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/xsd/docbookxi.xsd" "file:///usr/share/xml/docbook/schema/xsd/5.0/docbookxi.xsd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/xsd/xi.xsd" "file:///usr/share/xml/docbook/schema/xsd/5.0/xi.xsd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/xsd/xi.xsd" "file:///usr/share/xml/docbook/schema/xsd/5.0/xi.xsd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/xsd/xlink.xsd" "file:///usr/share/xml/docbook/schema/xsd/5.0/xlink.xsd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/xsd/xlink.xsd" "file:///usr/share/xml/docbook/schema/xsd/5.0/xlink.xsd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/xsd/xml.xsd" "file:///usr/share/xml/docbook/schema/xsd/5.0/xml.xsd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/xsd/xml.xsd" "file:///usr/share/xml/docbook/schema/xsd/5.0/xml.xsd" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/sch/docbook.sch" "file:///usr/share/xml/docbook/schema/sch/5.0/docbook.sch" /etc/xml/docbook-5.0
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/sch/docbook.sch" "file:///usr/share/xml/docbook/schema/sch/5.0/docbook.sch" /etc/xml/docbook-5.0
xmlcatalog --noout --create /usr/share/xml/docbook/schema/dtd/5.0/catalog.xml
xmlcatalog --noout --add "public" "-//OASIS//DTD DocBook XML 5.0//EN" "docbook.dtd" /usr/share/xml/docbook/schema/dtd/5.0/catalog.xml
xmlcatalog --noout --add "system" "http://www.oasis-open.org/docbook/xml/5.0/dtd/docbook.dtd" "docbook.dtd" /usr/share/xml/docbook/schema/dtd/5.0/catalog.xml
xmlcatalog --noout --create /usr/share/xml/docbook/schema/rng/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/rng/docbook.rng" "docbook.rng" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/rng/docbook.rng" "docbook.rng" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/rng/docbookxi.rng" "docbookxi.rng" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/rng/docbookxi.rng" "docbookxi.rng" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/rng/docbook.rnc" "docbook.rnc" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/rng/docbook.rnc" "docbook.rnc" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/rng/docbookxi.rnc" "docbookxi.rnc" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/rng/docbookxi.rnc" "docbookxi.rnc" /usr/share/xml/docbook/schema/rng/5.0/catalog.xml
xmlcatalog --noout --create /usr/share/xml/docbook/schema/sch/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/sch/docbook.sch" "docbook.sch" /usr/share/xml/docbook/schema/sch/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/sch/docbook.sch" "docbook.sch" /usr/share/xml/docbook/schema/sch/5.0/catalog.xml
xmlcatalog --noout --create /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/xsd/docbook.xsd" "docbook.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/xsd/docbook.xsd" "docbook.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/xsd/docbookxi.xsd" "docbookxi.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/xsd/docbookxi.xsd" "docbookxi.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/xsd/xlink.xsd" "xlink.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/xsd/xlink.xsd" "xlink.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.0/xsd/xml.xsd" "xml.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.0/xsd/xml.xsd" "xml.xsd" /usr/share/xml/docbook/schema/xsd/5.0/catalog.xml
xmlcatalog --noout --add "delegatePublic" "-//OASIS//DTD DocBook XML 5.0//EN" "file:///usr/share/xml/docbook/schema/dtd/5.0/catalog.xml" /etc/xml/catalog
xmlcatalog --noout --add "delegateSystem" "http://docbook.org/xml/5.0/dtd/" "file:///usr/share/xml/docbook/schema/dtd/5.0/catalog.xml" /etc/xml/catalog
xmlcatalog --noout --add "delegateURI" "http://docbook.org/xml/5.0/dtd/" "file:///usr/share/xml/docbook/schema/dtd/5.0/catalog.xml" /etc/xml/catalog
xmlcatalog --noout --add "delegateURI" "http://docbook.org/xml/5.0/rng/" "file:///usr/share/xml/docbook/schema/rng/5.0/catalog.xml" /etc/xml/catalog
xmlcatalog --noout --add "delegateURI" "http://docbook.org/xml/5.0/sch/" "file:///usr/share/xml/docbook/schema/sch/5.0/catalog.xml" /etc/xml/catalog
xmlcatalog --noout --add "delegateURI" "http://docbook.org/xml/5.0/xsd/" "file:///usr/share/xml/docbook/schema/xsd/5.0/catalog.xml" /etc/xml/catalog
cd ..
rm -rf docbook-5.0
# Docbook XML 5.1.
mkdir docbook-5.1
cd docbook-5.1
unzip -q ../docbook-v5.1-os.zip
install -dm755 /usr/share/xml/docbook/schema/{rng,sch}/5.1
install -m644 schemas/rng/* /usr/share/xml/docbook/schema/rng/5.1
install -m644 schemas/sch/* /usr/share/xml/docbook/schema/sch/5.1
install -m755 tools/db4-entities.pl /usr/bin
install -dm755 /usr/share/xml/docbook/stylesheet/docbook5
install -m644 tools/db4-upgrade.xsl /usr/share/xml/docbook/stylesheet/docbook5
if [ ! -e /etc/xml/docbook-5.1 ]; then
  xmlcatalog --noout --create /etc/xml/docbook-5.1
fi
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.1/rng/docbook.rng" "file:///usr/share/xml/docbook/schema/rng/5.1/docbook.rng" /etc/xml/docbook-5.1
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.1/rng/docbook.rng" "file:///usr/share/xml/docbook/schema/rng/5.1/docbook.rng" /etc/xml/docbook-5.1
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.1/rng/docbookxi.rng" "file:///usr/share/xml/docbook/schema/rng/5.1/docbookxi.rng" /etc/xml/docbook-5.1
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.1/rng/docbookxi.rng" "file:///usr/share/xml/docbook/schema/rng/5.1/docbookxi.rng" /etc/xml/docbook-5.1
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.1/rnc/docbook.rnc" "file:///usr/share/xml/docbook/schema/rng/5.1/docbook.rnc" /etc/xml/docbook-5.1
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.1/rng/docbook.rnc" "file:///usr/share/xml/docbook/schema/rng/5.1/docbook.rnc" /etc/xml/docbook-5.1
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.1/rnc/docbookxi.rnc" "file:///usr/share/xml/docbook/schema/rng/5.1/docbookxi.rnc" /etc/xml/docbook-5.1
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.1/rng/docbookxi.rnc" "file:///usr/share/xml/docbook/schema/rng/5.1/docbookxi.rnc" /etc/xml/docbook-5.1
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.1/sch/docbook.sch" "file:///usr/share/xml/docbook/schema/sch/5.1/docbook.sch" /etc/xml/docbook-5.1
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.1/sch/docbook.sch" "file:///usr/share/xml/docbook/schema/sch/5.1/docbook.sch" /etc/xml/docbook-5.1
xmlcatalog --noout --create /usr/share/xml/docbook/schema/rng/5.1/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.1/schemas/rng/docbook.schemas/rng" "docbook.schemas/rng" /usr/share/xml/docbook/schema/rng/5.1/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.1/schemas/rng/docbook.schemas/rng" "docbook.schemas/rng" /usr/share/xml/docbook/schema/rng/5.1/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.1/schemas/rng/docbookxi.schemas/rng" "docbookxi.schemas/rng" /usr/share/xml/docbook/schema/rng/5.1/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.1/schemas/rng/docbookxi.schemas/rng" "docbookxi.schemas/rng" /usr/share/xml/docbook/schema/rng/5.1/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.1/schemas/rng/docbook.rnc" "docbook.rnc" /usr/share/xml/docbook/schema/rng/5.1/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.1/schemas/rng/docbook.rnc" "docbook.rnc" /usr/share/xml/docbook/schema/rng/5.1/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.1/schemas/rng/docbookxi.rnc" "docbookxi.rnc" /usr/share/xml/docbook/schema/rng/5.1/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.1/schemas/rng/docbookxi.rnc" "docbookxi.rnc" /usr/share/xml/docbook/schema/rng/5.1/catalog.xml
xmlcatalog --noout --create /usr/share/xml/docbook/schema/sch/5.1/catalog.xml
xmlcatalog --noout --add "uri" "http://docbook.org/xml/5.1/schemas/sch/docbook.schemas/sch" "docbook.schemas/sch" /usr/share/xml/docbook/schema/sch/5.1/catalog.xml
xmlcatalog --noout --add "uri" "http://www.oasis-open.org/docbook/xml/5.1/schemas/sch/docbook.schemas/sch" "docbook.schemas/sch" /usr/share/xml/docbook/schema/sch/5.1/catalog.xml
xmlcatalog --noout --add "delegatePublic" "-//OASIS//DTD DocBook XML 5.1//EN" "file:///usr/share/xml/docbook/schema/dtd/5.1/catalog.xml" /etc/xml/catalog
xmlcatalog --noout --add "delegateSystem" "http://docbook.org/xml/5.1/dtd/" "file:///usr/share/xml/docbook/schema/dtd/5.1/catalog.xml" /etc/xml/catalog
xmlcatalog --noout --add "delegateURI" "http://docbook.org/xml/5.1/dtd/" "file:///usr/share/xml/docbook/schema/dtd/5.1/catalog.xml" /etc/xml/catalog
xmlcatalog --noout --add "delegateURI" "http://docbook.org/xml/5.1/rng/" "file:///usr/share/xml/docbook/schema/rng/5.1/catalog.xml" /etc/xml/catalog
xmlcatalog --noout --add "delegateURI" "http://docbook.org/xml/5.1/sch/" "file:///usr/share/xml/docbook/schema/sch/5.1/catalog.xml" /etc/xml/catalog
xmlcatalog --noout --add "delegateURI" "http://docbook.org/xml/5.1/xsd/" "file:///usr/share/xml/docbook/schema/xsd/5.1/catalog.xml" /etc/xml/catalog
cd ..
rm -rf docbook-5.1
# lxml.
tar -xf lxml-5.3.0.tar.gz
cd lxml-5.3.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist lxml
install -t /usr/share/licenses/lxml -Dm644 LICENSE.txt LICENSES.txt
cd ..
rm -rf lxml-5.3.0
# itstool.
tar -xf itstool-2.0.7.tar.bz2
cd itstool-2.0.7
PYTHON=/usr/bin/python3 ./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/itstool -Dm644 COPYING COPYING.GPL3
cd ..
rm -rf itstool-2.0.7
# Asciidoc.
tar -xf asciidoc-10.2.1.tar.gz
cd asciidoc-10.2.1
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist asciidoc
install -t /usr/share/licenses/asciidoc -Dm644 /usr/lib/$(readlink /usr/bin/python3)/site-packages/asciidoc-*.dist-info/LICENSE
cd ..
rm -rf asciidoc-10.2.1
# Moreutils.
tar -xf moreutils_0.69.orig.tar.xz
cd moreutils-0.69
make CFLAGS="$CFLAGS" DOCBOOKXSL=/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2
make install
install -t /usr/share/licenses/moreutils -Dm644 COPYING
cd ..
rm -rf moreutils-0.69
# GNU-EFI.
tar -xf gnu-efi-3.0.18.tar.bz2
cd gnu-efi-3.0.18
CFLAGS="-O2" make
CFLAGS="-O2" make PREFIX=/usr install
install -t /usr/share/licenses/gnu-efi -Dm644 README.efilib
cd ..
rm -rf gnu-efi-3.0.18
# hwdata.
tar -xf hwdata-0.391.tar.gz
cd hwdata-0.391
./configure --prefix=/usr --disable-blacklist
make
make install
install -t /usr/share/licenses/hwdata -Dm644 COPYING
cd ..
rm -rf hwdata-0.391
# systemd (initial build; will be rebuilt later to support more features).
tar -xf systemd-257.2.tar.gz
cd systemd-257.2
meson setup build --prefix=/usr --sysconfdir=/etc --localstatedir=/var --buildtype=minsize -Dmode=release -Dversion-tag=257.2-massos -Dshared-lib-tag=257.2-massos -Dbpf-framework=disabled -Dcryptolib=openssl -Ddefault-compression=xz -Ddefault-dnssec=no -Ddev-kvm-mode=0660 -Ddns-over-tls=openssl -Dfallback-hostname=massos -Dhomed=disabled -Dinitrd=true -Dinstall-tests=false -Dman=enabled -Dpamconfdir=/etc/pam.d -Drpmmacrosdir=no -Dsysupdate=disabled -Dsysusers=true -Dtests=false -Dtpm=true -Dukify=disabled -Duserdb=false
ninja -C build
ninja -C build install
systemd-machine-id-setup
systemd-sysusers
chgrp utmp /var/log/lastlog
systemctl preset-all
systemctl disable systemd-time-wait-sync
cat > /etc/pam.d/systemd-user << "END"
account  required pam_access.so
account  include  system-account
session  required pam_env.so
session  required pam_limits.so
session  required pam_unix.so
session  required pam_loginuid.so
session  optional pam_keyinit.so force revoke
session  optional pam_systemd.so
auth     required pam_deny.so
password required pam_deny.so
END
install -t /usr/lib/systemd/system -Dm644 ../systemd-units/*
systemctl enable gpm
install -t /usr/share/licenses/systemd -Dm644 LICENSE.{GPL2,LGPL2.1} LICENSES/*
cd ..
rm -rf systemd-257.2
# D-Bus (initial build; will be rebuilt later for more features).
tar -xf dbus-1.16.0.tar.xz
cd dbus-1.16.0
meson setup build --prefix=/usr --buildtype=minsize -Dapparmor=disabled -Dlibaudit=disabled -Dmodular_tests=disabled -Dselinux=disabled -Dx11_autolaunch=disabled
ninja -C build
ninja -C build install
systemd-sysusers
ln -sf /etc/machine-id /var/lib/dbus
install -t /usr/share/licenses/dbus -Dm644 COPYING
cd ..
rm -rf dbus-1.16.0
# Man-DB.
tar -xf man-db-2.13.0.tar.xz
cd man-db-2.13.0
./configure --prefix=/usr --sysconfdir=/etc --with-systemdsystemunitdir=/usr/lib/systemd/system --with-db=gdbm --disable-setuid --enable-cache-owner=bin --with-browser=/usr/bin/lynx
make
make install
install -t /usr/share/licenses/man-db -Dm644 COPYING
cd ..
rm -rf man-db-2.13.0
# Procps-NG.
tar -xf procps-ng-4.0.5.tar.xz
cd procps-ng-4.0.5
./configure --prefix=/usr --disable-static --disable-kill --with-systemd
make src_w_LDADD='$(LDADD) -lsystemd'
make install
install -t /usr/share/licenses/procps-ng -Dm644 COPYING COPYING.LIB
cd ..
rm -rf procps-ng-4.0.5
# util-linux.
tar -xf util-linux-2.40.4.tar.xz
cd util-linux-2.40.4
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime --bindir=/usr/bin --libdir=/usr/lib --sbindir=/usr/sbin --runstatedir=/run --disable-chfn-chsh --disable-login --disable-nologin --disable-su --disable-setpriv --disable-runuser --disable-pylibmount --disable-liblastlog2 --disable-static --without-python
make
make install
install -t /usr/share/licenses/util-linux -Dm644 COPYING
cd ..
rm -rf util-linux-2.40.4
# FUSE2.
tar -xf fuse-2.9.9.tar.gz
cd fuse-2.9.9
patch -Np1 -i ../patches/fuse-2.9.9-glibc234.patch
autoreconf -fi
UDEV_RULES_PATH=/usr/lib/udev/rules.d MOUNT_FUSE_PATH=/usr/bin ./configure --prefix=/usr --libdir=/usr/lib --enable-lib --enable-util --disable-example --disable-static
make
make install
rm -f /etc/init.d/fuse
chmod 4755 /usr/bin/fusermount
install -t /usr/share/licenses/fuse2 -Dm644 COPYING COPYING.LIB
cd ..
rm -rf fuse-2.9.9
# FUSE3.
tar -xf fuse-3.16.2.tar.gz
cd fuse-3.16.2
sed -i '/^udev/,$ s/^/#/' util/meson.build
meson setup build --prefix=/usr --buildtype=minsize -Dexamples=false -Dtests=false
ninja -C build
ninja -C build install
chmod 4755 /usr/bin/fusermount3
cat > /etc/fuse.conf << "END"
# Set the maximum number of FUSE mounts for non-root users (default = 1000).
#mount_max = 1000

# Allow non-root users to mount with the 'allow_other' or 'allow_root' options.
#user_allow_other
END
install -t /usr/share/licenses/fuse3 -Dm644 LICENSE GPL2.txt LGPL2.txt
cd ..
rm -rf fuse-3.16.2
# e2fsprogs.
tar -xf e2fsprogs-1.47.1.tar.xz
cd e2fsprogs-1.47.1
mkdir e2-build; cd e2-build
../configure --prefix=/usr --sysconfdir=/etc --enable-elf-shlibs --disable-fsck --disable-libblkid --disable-libuuid --disable-uuidd
make
make install
rm -f /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gzip -d /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
install -t /usr/share/licenses/e2fsprogs -Dm644 ../../extra-package-licenses/e2fsprogs-license.txt
cd ../..
rm -rf e2fsprogs-1.47.1
# dosfstools.
tar -xf dosfstools-4.2.tar.gz
cd dosfstools-4.2
./configure --prefix=/usr --enable-compat-symlinks --mandir=/usr/share/man --docdir=/usr/share/doc/dosfstools
make
make install
install -t /usr/share/licenses/dosfstools -Dm644 COPYING
cd ..
rm -rf dosfstools-4.2
# dracut.
tar -xf dracut-ng-105.tar.gz
cd dracut-ng-105
patch -Np1 -i ../patches/dracut-105-upstreamfix.patch
./configure --prefix=/usr --sysconfdir=/etc --libdir=/usr/lib --systemdsystemunitdir=/usr/lib/systemd/system --bashcompletiondir=/usr/share/bash-completion/completions
make
make install
cat > /etc/dracut.conf.d/massos.conf << "END"
# Default dracut configuration file for MassOS.

# Compression to use for the initramfs.
compress="xz"

# Make the initramfs reproducible.
reproducible="yes"

# These modules are required to support live CD booting; do not remove them.
add_dracutmodules+=" dmsquash-live overlayfs "

# These modules are unneeded for booting MassOS and would bloat the initramfs.
# Some of them also have dependencies outside the scope of MassOS.
# Remove them from the exclude list only if you know what you are doing.
omit_dracutmodules+=" biosdevname cifs connman dash dbus-broker dmraid fcoe fcoe-uefi hwdb iscsi kernel-modules-extra kernel-network-modules lunmask memstrack mksh multipath nbd network network-legacy network-manager nfs nvdimm nvmf qemu qemu-net rngd usrmount virtiofs "
END
install -t /usr/share/licenses/dracut -Dm644 COPYING
cd ..
rm -rf dracut-ng-105
# LZO.
tar -xf lzo-2.10.tar.gz
cd lzo-2.10
./configure --prefix=/usr --enable-shared --disable-static
make
make install
install -t /usr/share/licenses/lzo -Dm644 COPYING
cd ..
rm -rf lzo-2.10
# lzop.
tar -xf lzop-1.04.tar.gz
cd lzop-1.04
./configure --prefix=/usr --mandir=/usr/share/man
make
make install
install -t /usr/share/licenses/lzop -Dm644 COPYING
cd ..
rm -rf lzop-1.04
# cpio.
tar -xf cpio-2.15.tar.bz2
cd cpio-2.15
./configure --prefix=/usr --enable-mt --with-rmt=/usr/libexec/rmt
make
make install
install -t /usr/share/licenses/cpio -Dm644 COPYING
cd ..
rm -rf cpio-2.15
# squashfs-tools.
tar -xf squashfs-tools-4.6.1.tar.gz
cd squashfs-tools-4.6.1/squashfs-tools
make GZIP_SUPPORT=1 XZ_SUPPORT=1 LZO_SUPPORT=1 LZMA_XZ_SUPPORT=1 LZ4_SUPPORT=1 ZSTD_SUPPORT=1 XATTR_SUPPORT=1
make INSTALL_PREFIX=/usr INSTALL_MANPAGES_DIR=/usr/share/man/man1 install
install -t /usr/share/licenses/squashfs-tools -Dm644 ../COPYING
cd ../..
rm -rf squashfs-tools-4.6.1
# squashfuse.
tar -xf squashfuse-0.5.2.tar.gz
cd squashfuse-0.5.2
./autogen.sh
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/squashfuse -Dm644 LICENSE
cd ..
rm -rf squashfuse-0.5.2
# libtasn1.
tar -xf libtasn1-4.19.0.tar.gz
cd libtasn1-4.19.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libtasn1 -Dm644 COPYING
cd ..
rm -rf libtasn1-4.19.0
# p11-kit.
tar -xf p11-kit-0.25.5.tar.xz
cd p11-kit-0.25.5
sed '20,$ d' -i trust/trust-extract-compat
cat >> trust/trust-extract-compat << "END"
/usr/libexec/make-ca/copy-trust-modifications
/usr/sbin/make-ca -r
END
meson setup build --prefix=/usr --buildtype=minsize -Dtrust_paths=/etc/pki/anchors
ninja -C build
ninja -C build install
ln -sfr /usr/libexec/p11-kit/trust-extract-compat /usr/bin/update-ca-certificates
ln -sf ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
install -t /usr/share/licenses/p11-kit -Dm644 COPYING
cd ..
rm -rf p11-kit-0.25.5
# make-ca.
tar -xf make-ca-1.14.tar.gz
cd make-ca-1.14
make install
mkdir -p /etc/ssl/local
make-ca -g
systemctl enable update-pki.timer
install -t /usr/share/licenses/make-ca -Dm644 LICENSE{,.GPLv3,.MIT}
cd ..
rm -rf make-ca-1.14
# libaio.
tar -xf libaio-libaio-0.3.113.tar.gz
cd libaio-libaio-0.3.113
sed -i '/install.*libaio.a/s/^/#/' src/Makefile
make
make install
install -t /usr/share/licenses/libaio -Dm644 COPYING
cd ..
rm -rf libaio-libaio-0.3.113
# mdadm.
tar -xf mdadm-4.3.tar.xz
cd mdadm-4.3
make
make BINDIR=/usr/sbin install
install -t /usr/share/licenses/mdadm -Dm644 COPYING
cd ..
rm -rf mdadm-4.3
# LVM2.
tar -xf LVM2.2.03.30.tgz
cd LVM2.2.03.30
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --enable-cmdlib --enable-dmeventd --enable-lvmpolld --enable-pkgconfig --enable-readline --enable-udev_rules --enable-udev_sync --with-thin=internal
make
make install
make install_systemd_units
install -t /usr/share/licenses/lvm2 -Dm644 COPYING{,.BSD,.LIB}
cd ..
rm -rf LVM2.2.03.30
# dmraid.
tar -xf dmraid-1.0.0.rc16-3.tar.bz2
cd dmraid/1.0.0.rc16-3/dmraid
./configure --prefix=/usr --enable-led --enable-intel_led --enable-shared_lib
make -j1
make -j1 install
rm -f /usr/lib/libdmraid.a
install -t /usr/share/licenses/dmraid -Dm644 LICENSE{,_GPL,_LGPL}
cd ../../..
rm -rf dmraid
# btrfs-progs.
tar -xf btrfs-progs-v6.12.tar.xz
cd btrfs-progs-v6.12
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/btrfs-progs -Dm644 COPYING
cd ..
rm -rf btrfs-progs-v6.12
# inih.
tar -xf inih-r58.tar.gz
cd inih-r58
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/inih -Dm644 LICENSE.txt
cd ..
rm -rf inih-r58
# Userspace-RCU.
tar -xf userspace-rcu-0.15.0.tar.bz2
cd userspace-rcu-0.15.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/userspace-rcu -Dm644 LICENSE.md lgpl-relicensing.md LICENSES/*
cd ..
rm -rf userspace-rcu-0.15.0
# xfsprogs.
tar -xf xfsprogs-6.12.0.tar.xz
cd xfsprogs-6.12.0
sed -i 's/icu-i18n/icu-uc &/' configure
make DEBUG=-DNDEBUG INSTALL_USER=root INSTALL_GROUP=root
make install
make install-dev
rm -f /usr/lib/libhandle.{l,}a
install -t /usr/share/licenses/xfsprogs -Dm644 debian/copyright
cd ..
rm -rf xfsprogs-6.12.0
# f2fs-tools.
tar -xf f2fs-tools-1.16.0.tar.gz
cd f2fs-tools-1.16.0
./autogen.sh
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/f2fs-tools -Dm644 COPYING
cd ..
rm -rf f2fs-tools-1.16.0
# jfsutils.
tar -xf jfsutils-1.1.15.tar.gz
cd jfsutils-1.1.15
patch -Np1 -i ../patches/jfsutils-1.1.15-fixes.patch
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/jfsutils -Dm644 COPYING
cd ..
rm -rf jfsutils-1.1.15
# reiserfsprogs.
tar -xf reiserfsprogs-3.6.27.tar.xz
cd reiserfsprogs-3.6.27
sed -i '24iAC_USE_SYSTEM_EXTENSIONS' configure.ac
autoreconf -fi
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/reiserfsprogs -Dm644 COPYING
cd ..
rm -rf reiserfsprogs-3.6.27
# ntfs-3g.
tar -xf ntfs-3g-2022.10.3.tar.gz
cd ntfs-3g-2022.10.3
./autogen.sh
./configure --prefix=/usr --disable-static --with-fuse=external
make
make install
ln -s ../bin/ntfs-3g /usr/sbin/mount.ntfs
ln -s ntfs-3g.8 /usr/share/man/man8/mount.ntfs.8
install -t /usr/share/licenses/ntfs-3g -Dm644 COPYING COPYING.LIB
cd ..
rm -rf ntfs-3g-2022.10.3
# exfatprogs.
tar -xf exfatprogs-1.2.6.tar.xz
cd exfatprogs-1.2.6
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/exfatprogs -Dm644 COPYING
cd ..
rm -rf exfatprogs-1.2.6
# udftools.
tar -xf udftools-2.3.tar.gz
cd udftools-2.3
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/udftools -Dm644 COPYING
cd ..
rm -rf udftools-2.3
# Fakeroot.
tar -xf fakeroot_1.36.2.orig.tar.gz
cd fakeroot-1.36.2
./configure --prefix=/usr --libdir=/usr/lib/libfakeroot --disable-static
make
make install
install -dm755 /etc/ld.so.conf.d
echo "/usr/lib/libfakeroot" > /etc/ld.so.conf.d/fakeroot.conf
ldconfig
install -t /usr/share/licenses/fakeroot -Dm644 COPYING
cd ..
rm -rf fakeroot-1.36.2
# Parted.
tar -xf parted-3.6.tar.xz
cd parted-3.6
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/parted -Dm644 COPYING
cd ..
rm -rf parted-3.6
# Popt.
tar -xf popt-popt-1.19-release.tar.gz
cd popt-popt-1.19-release
./autogen.sh
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/popt -Dm644 COPYING
cd ..
rm -rf popt-popt-1.19-release
# gptfdisk.
tar -xf gptfdisk-1.0.10.tar.gz
cd gptfdisk-1.0.10
sed -i 's|ncursesw/||' gptcurses.cc
make
install -t /usr/sbin -Dm755 gdisk cgdisk sgdisk fixparts
install -t /usr/share/man/man8 -Dm644 gdisk.8 cgdisk.8 sgdisk.8 fixparts.8
install -t /usr/share/licenses/gptfdisk -Dm644 COPYING
cd ..
rm -rf gptfdisk-1.0.10
# run-parts (from debianutils).
tar -xf debianutils-5.5.tar.gz
cd debianutils-5.5
./configure --prefix=/usr
make run-parts
install -t /usr/bin -Dm755 run-parts
install -t /usr/share/man/man8 -Dm644 run-parts.8
install -t /usr/share/licenses/run-parts -Dm644 /usr/share/licenses/gptfdisk/COPYING
cd ..
rm -rf debianutils-5.5
# seatd.
tar -xf seatd-0.9.1.tar.gz
cd seatd-0.9.1
meson setup build --prefix=/usr --buildtype=minsize -Dlibseat-logind=systemd -Dserver=enabled -Dexamples=disabled -Dman-pages=enabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/seatd -Dm644 LICENSE
cd ..
rm -rf seatd-0.9.1
# libdisplay-info.
tar -xf libdisplay-info-0.2.0.tar.bz2
cd libdisplay-info-0.2.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libdisplay-info -Dm644 LICENSE
cd ..
rm -rf libdisplay-info-0.2.0
# libpaper.
tar -xf libpaper-2.2.5.tar.gz
cd libpaper-2.2.5
./configure --prefix=/usr --sysconfdir=/etc --disable-static --enable-relocatable
make
make install
cat > /etc/papersize << "END"
# Specify the default paper size in this file.
# Run 'paper --all --no-size' for a list of supported paper sizes.
END
install -dm755 /etc/libpaper.d
install -t /usr/share/licenses/libpaper -Dm644 COPYING
cd ..
rm -rf libpaper-2.2.5
# xxhash.
tar -xf xxHash-0.8.3.tar.gz
cd xxHash-0.8.3
make PREFIX=/usr CFLAGS="$CFLAGS -fPIC"
make PREFIX=/usr install
rm -f /usr/lib/libxxhash.a
ln -sf xxhsum.1 /usr/share/man/man1/xxh32sum.1
ln -sf xxhsum.1 /usr/share/man/man1/xxh64sum.1
ln -sf xxhsum.1 /usr/share/man/man1/xxh128sum.1
install -t /usr/share/licenses/xxhash -Dm644 LICENSE
cd ..
rm -rf xxHash-0.8.3
# rsync.
tar -xf rsync-3.4.1.tar.gz
cd rsync-3.4.1
./configure --prefix=/usr --without-included-popt --without-included-zlib
make
make install
install -t /usr/share/licenses/rsync -Dm644 COPYING
cd ..
rm -rf rsync-3.4.1
# libnghttp2.
tar -xf nghttp2-1.64.0.tar.xz
cd nghttp2-1.64.0
./configure --prefix=/usr --disable-static --enable-lib-only
make
make install
install -t /usr/share/licenses/libnghttp2 -Dm644 COPYING
cd ..
rm -rf nghttp2-1.64.0
# libnghttp3.
tar -xf nghttp3-1.6.0.tar.xz
cd nghttp3-1.6.0
./configure --prefix=/usr
make
make install
rm -f /usr/lib/libnghttp3.a
install -t /usr/share/licenses/libnghttp3 -Dm644 COPYING
cd ..
rm -rf nghttp3-1.6.0
# curl (INITIAL LIMITED BUILD; will be rebuilt later to support more features).
tar -xf curl-8.11.1.tar.xz
cd curl-8.11.1
./configure --prefix=/usr --disable-static --without-libpsl --with-openssl --enable-threaded-resolver --with-ca-path=/etc/ssl/certs
make
make install
install -t /usr/share/licenses/curl -Dm644 COPYING
cd ..
rm -rf curl-8.11.1
# jsoncpp.
tar -xf jsoncpp-1.9.6.tar.gz
cd jsoncpp-1.9.6
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/jsoncpp -Dm644 LICENSE
cd ..
rm -rf jsoncpp-1.9.6
# rhash.
tar -xf RHash-1.4.5.tar.gz
cd RHash-1.4.5
./configure --prefix=/usr --sysconfdir=/etc --extra-cflags="$CFLAGS" --extra-ldflags="$LDFLAGS"
make
make -j1 install
make -j1 -C librhash install-lib-headers install-lib-shared install-so-link
install -t /usr/share/licenses/rhash -Dm644 COPYING
cd ..
rm -rf RHash-1.4.5
# CMake.
tar -xf cmake-3.31.4.tar.gz
cd cmake-3.31.4
sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake
./bootstrap --prefix=/usr --parallel=$(nproc) --generator=Ninja --docdir=/share/doc/cmake --mandir=/share/man --system-libs --no-system-cppdap --sphinx-man
ninja
ninja install
install -t /usr/share/licenses/cmake -Dm644 Copyright.txt
cd ..
rm -rf cmake-3.31.4
# brotli.
tar -xf brotli-1.1.0.tar.gz
cd brotli-1.1.0
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBROTLI_DISABLE_TESTS=TRUE -Wno-dev -G Ninja -B build
ninja -C build
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
ninja -C build install
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist Brotli
install -t /usr/share/licenses/brotli -Dm644 LICENSE
cd ..
rm -rf brotli-1.1.0
# c-ares.
tar -xf c-ares-1.34.4.tar.gz
cd c-ares-1.34.4
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/c-ares -Dm644 LICENSE.md
cd ..
rm -rf c-ares-1.34.4
# utfcpp.
tar -xf utfcpp-4.0.6.tar.gz
cd utfcpp-4.0.6
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/license/utfcpp -Dm644 LICENSE
cd ..
rm -rf utfcpp-4.0.6
# yyjson.
tar -xf yyjson-0.10.0.tar.gz
cd yyjson-0.10.0
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DBUILD_SHARED_LIBS=ON -DYYJSON_BUILD_TESTS=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/yyjson -Dm644 LICENSE
cd ..
rm -rf yyjson-0.10.0
# JSON-C.
tar -xf json-c-0.18.tar.gz
cd json-c-0.18
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DBUILD_STATIC_LIBS=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/json-c -Dm644 COPYING
cd ..
rm -rf json-c-0.18
# cryptsetup.
tar -xf cryptsetup-2.7.5.tar.xz
cd cryptsetup-2.7.5
./configure --prefix=/usr --disable-asciidoc --disable-ssh-token
make
make install
install -t /usr/share/licenses/cryptsetup -Dm644 COPYING.LGPL
cd ..
rm -rf cryptsetup-2.7.5
# multipath-tools.
tar -xf multipath-tools-0.10.0.tar.gz
cd multipath-tools-0.10.0
make prefix=/usr etc_prefix= configfile=/etc/multipath.conf statedir=/etc/multipath LIB=lib
make prefix=/usr etc_prefix= configfile=/etc/multipath.conf statedir=/etc/multipath LIB=lib install
install -t /usr/share/licenses/multipath-tools -Dm644 COPYING
cd ..
rm -rf multipath-tools-0.10.0
# libtpms.
tar -xf libtpms-0.10.0.tar.gz
cd libtpms-0.10.0
./autogen.sh --prefix=/usr --with-openssl --with-tpm2
make
make install
rm -f /usr/lib/libtpms.a
install -t /usr/share/licenses/libtpms -Dm644 LICENSE
cd ..
rm -rf libtpms-0.10.0
# tpm2-tss.
tar -xf tpm2-tss-4.1.3.tar.gz
cd tpm2-tss-4.1.3
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --with-runstatedir=/run --with-sysusersdir=/usr/lib/sysusers.d --with-tmpfilesdir=/usr/lib/tmpfiles.d --with-udevrulesprefix="60-" --disable-static
make
make install
install -t /usr/share/licenses/tpm2-tss -Dm644 LICENSE
cd ..
rm -rf tpm2-tss-4.1.3
# tpm2-tools.
tar -xf tpm2-tools-5.7.tar.gz
cd tpm2-tools-5.7
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/tpm2-tools -Dm644 docs/LICENSE
cd ..
rm -rf tpm2-tools-5.7
# libusb.
tar -xf libusb-1.0.27.tar.bz2
cd libusb-1.0.27
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libusb -Dm644 COPYING
cd ..
rm -rf libusb-1.0.27
# libmtp.
tar -xf libmtp-1.1.22.tar.gz
cd libmtp-1.1.22
./configure --prefix=/usr --disable-rpath --disable-static --with-udev=/usr/lib/udev
make
make install
install -t /usr/share/licenses/libmtp -Dm644 COPYING
cd ..
rm -rf libmtp-1.1.22
# libnfs.
tar -xf libnfs-5.0.3.tar.gz
cd libnfs-libnfs-5.0.3
./bootstrap
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libnfs -Dm644 COPYING LICENCE-BSD.txt LICENCE-GPL-3.txt LICENCE-LGPL-2.1.txt
cd ..
rm -rf libnfs-libnfs-5.0.3
# libieee1284.
tar -xf libieee1284-0.2.11-12-g0663326.tar.gz
cd libieee1284-0663326cbcfdf2a59f9492ddaff72ec5d1b248eb
patch -Np1 -i ../patches/libieee1284-0.2.11-python3.patch
./bootstrap
./configure --prefix=/usr --mandir=/usr/share/man --disable-static --with-python
make -j1
make -j1 install
install -t /usr/share/licenses/libieee1284 -Dm644 COPYING
cd ..
rm -rf libieee1284-0663326cbcfdf2a59f9492ddaff72ec5d1b248eb
# libunistring.
tar -xf libunistring-1.3.tar.xz
cd libunistring-1.3
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libunistring -Dm644 COPYING COPYING.LIB
cd ..
rm -rf libunistring-1.3
# libidn2.
tar -xf libidn2-2.3.7.tar.gz
cd libidn2-2.3.7
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libidn2 -Dm644 COPYING COPYINGv2 COPYING.LESSERv3 COPYING.unicode
cd ..
rm -rf libidn2-2.3.7
# whois.
tar -xf whois-5.5.23.tar.gz
cd whois-5.5.23
make
make prefix=/usr install-whois
make prefix=/usr install-mkpasswd
make prefix=/usr install-pos
install -t /usr/share/licenses/whois -Dm644 COPYING
cd ..
rm -rf whois-5.5.23
# libpsl.
tar -xf libpsl-0.21.5.tar.gz
cd libpsl-0.21.5
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libpsl -Dm644 COPYING
cd ..
rm -rf libpsl-0.21.5
# usbutils.
tar -xf usbutils-018.tar.xz
cd usbutils-018
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/usbutils -Dm644 LICENSES/*
cd ..
rm -rf usbutils-018
# pciutils.
tar -xf pciutils-3.13.0.tar.xz
cd pciutils-3.13.0
make PREFIX=/usr SHAREDIR=/usr/share/hwdata SHARED=yes
make PREFIX=/usr SHAREDIR=/usr/share/hwdata SHARED=yes install install-lib
chmod 755 /usr/lib/libpci.so
install -t /usr/share/licenses/pciutils -Dm644 COPYING
cd ..
rm -rf pciutils-3.13.0
# pkcs11-helper.
tar -xf pkcs11-helper-1.30.0.tar.bz2
cd pkcs11-helper-1.30.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/pkcs11-helper -Dm644 COPYING COPYING.BSD COPYING.GPL
cd ..
rm -rf pkcs11-helper-1.30.0
# python-certifi.
tar -xf python-certifi-2024.08.30.tar.gz
cd python-certifi-2024.08.30
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist certifi
install -t /usr/share/licenses/python-certifi -Dm644 LICENSE
cd ..
rm -rf python-certifi-2024.08.30
# libssh2.
tar -xf libssh2-1.11.1.tar.xz
cd libssh2-1.11.1
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libssh2 -Dm644 COPYING
cd ..
rm -rf libssh2-1.11.1
# Jansson.
tar -xf jansson-2.14.tar.bz2
cd jansson-2.14
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/jansson -Dm644 LICENSE
cd ..
rm -rf jansson-2.14
# nftables (rebuild with Jansson for JSON support).
tar -xf nftables-1.1.1.tar.xz
cd nftables-1.1.1
./configure --prefix=/usr --sysconfdir=/etc --disable-debug --with-json
make
make install
cd ..
rm -rf nftables-1.1.1
# libassuan.
tar -xf libassuan-3.0.1.tar.bz2
cd libassuan-3.0.1
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/libassuan -Dm644 COPYING COPYING.LIB
cd ..
rm -rf libassuan-3.0.1
# Nettle.
tar -xf nettle-3.10.1.tar.gz
cd nettle-3.10.1
./configure --prefix=/usr --disable-static
make
make install
chmod 755 /usr/lib/lib{hogweed,nettle}.so
install -t /usr/share/licenses/nettle -Dm644 COPYINGv2 COPYINGv3 COPYING.LESSERv3
cd ..
rm -rf nettle-3.10.1
# GNUTLS.
tar -xf gnutls-3.8.8.tar.xz
cd gnutls-3.8.8
./configure --prefix=/usr --disable-rpath --disable-static --with-default-trust-store-pkcs11="pkcs11:" --enable-openssl-compatibility --enable-ssl3-support
make
make install
install -t /usr/share/licenses/gnutls -Dm644 LICENSE
cd ..
rm -rf gnutls-3.8.8
# libevent.
tar -xf libevent-2.1.12-stable.tar.gz
cd libevent-2.1.12-stable
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DEVENT__LIBRARY_TYPE=SHARED -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libevent -Dm644 LICENSE
cd ..
rm -rf libevent-2.1.12-stable
# libldap.
tar -xf openldap-2.6.9.tgz
cd openldap-2.6.9
autoconf
./configure --prefix=/usr --sysconfdir=/etc --enable-dynamic --enable-versioning --disable-debug --disable-slapd --disable-static
make depend
make
make install
chmod 755 /usr/lib/libl{ber,dap}.so.2.*
install -t /usr/share/licenses/libldap -Dm644 COPYRIGHT LICENSE
cd ..
rm -rf openldap-2.6.9
# npth.
tar -xf npth-1.8.tar.bz2
cd npth-1.8
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/npth -Dm644 COPYING.LIB
cd ..
rm -rf npth-1.8
# libksba.
tar -xf libksba-1.6.7.tar.bz2
cd libksba-1.6.7
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/libksba -Dm644 COPYING COPYING.GPLv2 COPYING.GPLv3 COPYING.LGPLv3
cd ..
rm -rf libksba-1.6.7
# GNUPG.
tar -xf gnupg-2.5.1.tar.bz2
cd gnupg-2.5.1
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --enable-g13
make
make install
install -t /usr/share/licenses/gnupg -Dm644 COPYING{,.CC0,.GPL2,.LGPL21,.LGPL3,.other}
cd ..
rm -rf gnupg-2.5.1
# krb5.
tar -xf krb5-1.21.3.tar.gz
cd krb5-1.21.3/src
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var/lib --runstatedir=/run --disable-rpath --enable-dns-for-realm --with-system-et --with-system-ss --without-system-verto
make
make install
install -t /usr/share/licenses/krb5 -Dm644 ../NOTICE
cd ../..
rm -rf krb5-1.21.3
# rtmpdump.
tar -xf rtmpdump-2.4-105-g6f6bb13.tar.gz
cd rtmpdump-6f6bb1353fc84f4cc37138baa99f586750028a01
make prefix=/usr mandir=/usr/share/man
make prefix=/usr mandir=/usr/share/man install
rm -f /usr/lib/librtmp.a
install -t /usr/share/licenses/rtmpdump -Dm644 COPYING
cd ..
rm -rf rtmpdump-6f6bb1353fc84f4cc37138baa99f586750028a01
# curl (rebuild to support more features).
tar -xf curl-8.11.1.tar.xz
cd curl-8.11.1
./configure --prefix=/usr --disable-static --with-openssl --with-libssh2 --with-gssapi --with-nghttp3 --with-openssl-quic --enable-ares --enable-threaded-resolver --with-ca-path=/etc/ssl/certs
make
make install
cd ..
rm -rf curl-8.11.1
# libnl.
tar -xf libnl-3.11.0.tar.gz
cd libnl-3.11.0
./configure --prefix=/usr --sysconfdir=/etc --disable-static
make
make install
install -t /usr/share/licenses/libnl -Dm644 COPYING
cd ..
rm -rf libnl-3.11.0
# SWIG.
tar -xf swig-4.3.0.tar.gz
cd swig-4.3.0
./autogen.sh
./configure --prefix=/usr --without-maximum-compile-warnings
make
make install
install -t /usr/share/licenses/swig -Dm644 COPYRIGHT LICENSE LICENSE-GPL LICENSE-UNIVERSITIES
cd ..
rm -rf swig-4.3.0
# keyutils.
tar -xf keyutils-1.6.3.tar.gz
cd keyutils-1.6.3
make
make BINDIR=/usr/bin LIBDIR=/usr/lib SBINDIR=/usr/sbin NO_ARLIB=1 install
install -t /usr/share/licenses/keyutils -Dm644 LICENCE.{L,}GPL
cd ..
rm -rf keyutils-1.6.3
# libnvme.
tar -xf libnvme-1.11.1.tar.gz
cd libnvme-1.11.1
meson setup build --prefix=/usr --buildtype=minsize -Dlibdbus=enabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libnvme -Dm644 COPYING
cd ..
rm -rf libnvme-1.11.1
# nvme-cli.
tar -xf nvme-cli-2.11.tar.gz
cd nvme-cli-2.11
meson setup build --prefix=/usr --sysconfdir=/etc --buildtype=minsize -Ddocs=man -Ddocs-build=true
ninja -C build
ninja -C build install
install -t /usr/share/licenses/nvme-cli -Dm644 LICENSE
cd ..
rm -rf nvme-cli-2.11
# libcap-ng.
tar -xf libcap-ng-0.8.5.tar.gz
cd libcap-ng-0.8.5
./autogen.sh
./configure --prefix=/usr --disable-static --without-python --with-python3
make
make install
install -t /usr/share/licenses/libcap-ng -Dm644 COPYING{,.LIB}
cd ..
rm -rf libcap-ng-0.8.5
# smartmontools.
tar -xf smartmontools-7.4.tar.gz
cd smartmontools-7.4
./configure --prefix=/usr --sysconfdir=/etc
make
make install
systemctl enable smartd
install -t /usr/share/licenses/smartmontools -Dm644 COPYING
cd ..
rm -rf smartmontools-7.4
# OpenVPN.
tar -xf openvpn-2.6.12.tar.gz
cd openvpn-2.6.12
echo 'u openvpn - "OpenVPN" -' > /usr/lib/sysusers.d/openvpn.conf
systemd-sysusers
sed -i '/^CONFIGURE_DEFINES=/s/set/env/g' configure.ac
autoreconf -fi
./configure --prefix=/usr --enable-pkcs11 --enable-plugins --enable-systemd --enable-x509-alt-username
make
make install
while read -r line; do
  case "$(file -bS --mime-type "$line")" in
    "text/x-shellscript") install -t /usr/share/openvpn -Dm755 "$line" ;;
    *) install -t /usr/share/openvpn -Dm644 "$line" ;;
  esac
done <<< $(find contrib -type f)
cp -r sample/sample-config-files /usr/share/openvpn/examples
install -t /usr/share/licenses/openvpn -Dm644 COPYING COPYRIGHT.GPL
cd ..
rm -rf openvpn-2.6.12
# GPGME.
tar -xf gpgme-1.24.1.tar.bz2
cd gpgme-1.24.1
sed -i 's/python3.12/python3.13/' configure
./configure --prefix=/usr --disable-gpg-test --disable-gpgsm-test --enable-languages=cl,cpp,python
make PYTHONS=
top_builddir="$PWD" srcdir="$PWD/lang/python" pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist "$PWD/lang/python"
make PYTHONS= install
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist gpg
install -t /usr/share/licenses/gpgme -Dm644 COPYING{,.LESSER} LICENSES
cd ..
rm -rf gpgme-1.24.1
# SQLite.
tar -xf sqlite-autoconf-3480000.tar.gz
cd sqlite-autoconf-3480000
./configure --prefix=/usr --disable-static --enable-fts4 --enable-fts5 CPPFLAGS="$CPPFLAGS -DSQLITE_ENABLE_COLUMN_METADATA=1 -DSQLITE_ENABLE_UNLOCK_NOTIFY=1 -DSQLITE_ENABLE_DBSTAT_VTAB=1 -DSQLITE_SECURE_DELETE=1 -DSQLITE_ENABLE_FTS3_TOKENIZER=1"
make
make install
install -dm755 /usr/share/licenses/sqlite
cat > /usr/share/licenses/sqlite/LICENSE << "END"
The code and documentation of SQLite is dedicated to the public domain.
See https://www.sqlite.org/copyright.html for more information.
END
cd ..
rm -rf sqlite-autoconf-3480000
# Cyrus SASL (rebuild to support krb5 and OpenLDAP).
tar -xf cyrus-sasl-2.1.28.tar.gz
cd cyrus-sasl-2.1.28
sed -i '/saslint/a #include <time.h>' lib/saslutil.c
sed -i '/plugin_common/a #include <time.h>' plugins/cram.c
./configure --prefix=/usr --sysconfdir=/etc --enable-auth-sasldb --with-dbpath=/var/lib/sasl/sasldb2 --with-ldap --with-sphinx-build=no --with-saslauthd=/var/run/saslauthd
make -j1
make -j1 install
cd ..
rm -rf cyrus-sasl-2.1.28
# libtirpc.
tar -xf libtirpc-1.3.6.tar.bz2
cd libtirpc-1.3.6
./configure --prefix=/usr --sysconfdir=/etc --disable-static
make
make install
install -t /usr/share/licenses/libtirpc -Dm644 COPYING
cd ..
rm -rf libtirpc-1.3.6
# libnsl.
tar -xf libnsl-2.0.1.tar.xz
cd libnsl-2.0.1
./configure --sysconfdir=/etc --disable-static
make
make install
install -t /usr/share/licenses/libnsl -Dm644 COPYING
cd ..
rm -rf libnsl-2.0.1
# libetpan.
tar -xf libetpan-1.9.4.tar.gz
cd libetpan-1.9.4
patch -Np1 -i ../patches/libetpan-1.9.4-securityfix.patch
./autogen.sh --prefix=/usr --disable-debug --disable-static --with-gnutls --without-openssl
make
make install
install -t /usr/share/licenses/libetpan -Dm644 COPYRIGHT
cd ..
rm -rf libetpan-1.9.4
# Wget.
tar -xf wget-1.25.0.tar.gz
cd wget-1.25.0
./configure --prefix=/usr --sysconfdir=/etc --disable-rpath --with-cares --with-metalink
make
make install
install -t /usr/share/licenses/wget -Dm644 COPYING
cd ..
rm -rf wget-1.25.0
# Audit.
tar -xf audit-userspace-4.0.2.tar.gz
cd audit-userspace-4.0.2
./autogen.sh
./configure --prefix=/usr --sysconfdir=/etc --disable-static --enable-gssapi-krb5 --enable-systemd --with-libcap-ng
make
make install
install -dm0700 /var/log/audit
install -dm0750 /etc/audit/rules.d
cat > /etc/audit/rules.d/default.rules << "END"
-w /etc/passwd -p rwxa
-w /etc/security -p rwxa
-A always,exclude -F msgtype=BPF
-A always,exclude -F msgtype=SERVICE_STOP
-A always,exclude -F msgtype=SERVICE_START
END
systemctl enable auditd
install -t /usr/share/licenses/audit -Dm644 COPYING COPYING.LIB
cd ..
rm -rf audit-userspace-4.0.2
# AppArmor.
tar -xf apparmor-4.0.3.tar.gz
cd apparmor-4.0.3/libraries/libapparmor
./configure --prefix=/usr --with-perl --with-python
make
cd ../..
make -C changehat/pam_apparmor
make -C binutils
make -C parser
make -C profiles
make -C utils
make -C utils/vim
make -C libraries/libapparmor install
make -C changehat/pam_apparmor install
make -C binutils install
make -C parser -j1 install install-systemd
make -C profiles install
make -C utils install
rm -f /usr/lib/libapparmor.a
chmod 755 /usr/lib/perl5/*/vendor_perl/auto/LibAppArmor/LibAppArmor.so
systemctl enable apparmor
install -t /usr/share/licenses/apparmor -Dm644 LICENSE libraries/libapparmor/COPYING.LGPL changehat/pam_apparmor/COPYING
cd ..
rm -rf apparmor-4.0.3
# Linux-PAM (rebuild with newer version, and to support Audit).
tar -xf Linux-PAM-1.7.0.tar.xz
cd Linux-PAM-1.7.0
sed -e "s/'elinks'/'lynx'/" -e "s/'-no-numbering', '-no-references'/'-force-html', '-nonumbers', '-stdin'/" -i meson.build
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/linux-pam -Dm644 COPYING Copyright
cd ..
rm -rf Linux-PAM-1.7.0
# Shadow (rebuild to support Audit).
tar -xf shadow-4.17.2.tar.xz
cd shadow-4.17.2
patch -Np1 -i ../patches/shadow-4.17.2-MassOS.patch
./configure --sysconfdir=/etc --disable-static --with-audit --with-bcrypt --with-group-name-max-length=32 --with-libcrack --with-yescrypt --without-libbsd
make
make exec_prefix=/usr pamdir= install
make -C man install-man
install -t /etc/pam.d -Dm644 pam.d/*
rm -f /etc/{limits,login.access}
cd ..
rm -rf shadow-4.17.2
# Sudo.
tar -xf sudo-1.9.16p2.tar.gz
cd sudo-1.9.16p2
./configure --prefix=/usr --libexecdir=/usr/lib --with-linux-audit --with-secure-path --with-insults --with-all-insults --with-passwd-tries=5 --with-env-editor --with-passprompt="[sudo] password for %p: "
make
make install
sed -e '/pam_rootok.so/d' -e '/pam_wheel.so/d' /etc/pam.d/su > /etc/pam.d/sudo
sed -e 's|# %wheel ALL=(ALL:ALL) ALL|%wheel ALL=(ALL:ALL) ALL|' -e 's|# Defaults secure_path|Defaults secure_path|' -e 's|/sbin:/bin|/var/lib/flatpak/exports/bin:/snap/bin|' -i /etc/sudoers
sed -i '53i## Show astericks while typing the password' /etc/sudoers
sed -i '54iDefaults pwfeedback' /etc/sudoers
sed -i '55i##' /etc/sudoers
install -t /usr/share/licenses/sudo -Dm644 LICENSE.md
cd ..
rm -rf sudo-1.9.16p2
# Fcron.
tar -xf fcron-ver3_3_1.tar.gz
cd fcron-ver3_3_1
echo 'u fcron - "Fcron User" -' > /usr/lib/sysusers.d/fcron.conf
systemd-sysusers
autoconf
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --without-sendmail --with-piddir=/run --with-boot-install=no --with-editor=/usr/bin/nano --with-dsssl-dir=/usr/share/sgml/docbook/dsssl-stylesheets-1.79
make
make install
for i in crondyn cronsighup crontab; do ln -sf f$i /usr/bin/$i; done
ln -sf fcron /usr/sbin/cron
for i in crontab.1 crondyn.1; do ln -sf f$i /usr/share/man/man1/$i; done
for i in crontab.1 crondyn.1; do ln -sf f$i /usr/share/man/fr/man1/$i; done
ln -sf fcrontab.5 /usr/share/man/man5/crontab.5
ln -sf fcrontab.5 /usr/share/man/fr/man5/crontab.5
ln -sf fcron.8 /usr/share/man/man8/cron.8
ln -sf fcron.8 /usr/share/man/fr/man8/cron.8
install -dm754 /etc/cron.{hourly,daily,weekly,monthly}
cat > /var/spool/fcron/systab.orig << "END"
&bootrun 01 * * * *  /usr/bin/run-parts /etc/cron.hourly
&bootrun 02 00 * * * /usr/bin/run-parts /etc/cron.daily
&bootrun 22 00 * * 0 /usr/bin/run-parts /etc/cron.weekly
&bootrun 42 00 1 * * /usr/bin/run-parts /etc/cron.monthly
END
fcrontab -z -u systab
systemctl enable fcron
install -t /usr/share/licenses/fcron -Dm644 doc/en/txt/gpl.txt
cd ..
rm -rf fcron-ver3_3_1
# lsof.
tar -xf lsof-4.99.4.tar.gz
cd lsof-4.99.4
./Configure linux -n
sed -i "s/cc/cc $CFLAGS/" Makefile
make
install -m755 lsof /usr/sbin/lsof
install -m644 Lsof.8 /usr/share/man/man8/lsof.8
install -t /usr/share/licenses/lsof -Dm644 COPYING
cd ..
rm -rf lsof-4.99.4
# NSPR.
tar -xf nspr-4.36.tar.gz
cd nspr-4.36/nspr
./configure --prefix=/usr --with-mozilla --with-pthreads --enable-64bit
make
make install
rm -f /usr/lib/lib{nspr,plc,plds}4.a
rm -f /usr/bin/{compile-et.pl,prerr.properties}
install -t /usr/share/licenses/nspr -Dm644 LICENSE
cd ../..
rm -rf nspr-4.36
# NSS.
tar -xf nss-3.107.tar.gz
cd nss-3.107/nss
mkdir gyp
tar -xf ../../gyp-1615ec.tar.gz -C gyp --strip-components=1
sed -i "s|'disable_werror%': 0|'disable_werror%': 1|" coreconf/config.gypi
PATH="$PATH:$PWD/gyp" ./build.sh --target=x64 --enable-libpkix --disable-tests --opt --system-nspr --system-sqlite
install -t /usr/lib -Dm755 ../dist/Release/lib/*.so
install -t /usr/lib -Dm644 ../dist/Release/lib/*.chk
install -t /usr/bin -Dm755 ../dist/Release/bin/{*util,shlibsign,signtool,signver,ssltap}
install -t /usr/share/man/man1 -Dm644 doc/nroff/{*util,signtool,signver,ssltap}.1
install -dm755 /usr/include/nss
cp -r ../dist/{public,private}/nss/* /usr/include/nss
sed pkg/pkg-config/nss.pc.in -e 's|%prefix%|/usr|g' -e 's|%libdir%|${prefix}/lib|g' -e 's|%exec_prefix%|${prefix}|g' -e 's|%includedir%|${prefix}/include/nss|g' -e "s|%NSPR_VERSION%|$(pkg-config --modversion nspr)|g" -e "s|%NSS_VERSION%|3.107.0|g" > /usr/lib/pkgconfig/nss.pc
sed pkg/pkg-config/nss-config.in -e 's|@prefix@|/usr|g' -e "s|@MOD_MAJOR_VERSION@|$(pkg-config --modversion nss | cut -d. -f1)|g" -e "s|@MOD_MINOR_VERSION@|$(pkg-config --modversion nss | cut -d. -f2)|g" -e "s|@MOD_PATCH_VERSION@|$(pkg-config --modversion nss | cut -d. -f3)|g" > /usr/bin/nss-config
chmod 755 /usr/bin/nss-config
ln -sf ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
install -t /usr/share/licenses/nss -Dm644 COPYING
cd ../..
rm -rf nss-3.107
# Git.
tar -xf git-2.48.1.tar.xz
cd git-2.48.1
./configure --prefix=/usr --with-gitconfig=/etc/gitconfig --with-libpcre2
make all man
make perllibdir=/usr/lib/perl5/5.40/site_perl install install-man
install -t /usr/share/licenses/git -Dm644 COPYING LGPL-2.1
cd ..
rm -rf git-2.48.1
# snowball.
tar -xf snowball-2.2.0.tar.gz
cd snowball-2.2.0
patch -Np1 -i ../patches/snowball-2.2.0-sharedlibrary.patch
make
install -t /usr/bin -Dm755 snowball stemwords
install -m755 libstemmer.so.0 /usr/lib/libstemmer.so.0.0.0
ln -s libstemmer.so.0.0.0 /usr/lib/libstemmer.so.0
ln -s libstemmer.so.0 /usr/lib/libstemmer.so
install -m644 include/libstemmer.h /usr/include/libstemmer.h
ldconfig
install -t /usr/share/licenses/snowball -Dm644 COPYING
cd ..
rm -rf snowball-2.2.0
# Pahole.
tar -xf pahole-1.28.tar.gz
cd pahole-1.28
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -D__LIB=lib -DLIBBPF_EMBEDDED=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
mv /usr/share/dwarves/runtime/python/ostra.py /usr/lib/$(readlink /usr/bin/python3)/ostra.py
rm -rf /usr/share/dwarves/runtime/python
install -t /usr/share/licenses/pahole -Dm644 COPYING
cd ..
rm -rf pahole-1.28
# libsmbios.
tar -xf libsmbios-2.4.3.tar.gz
cd libsmbios-2.4.3
./autogen.sh --prefix=/usr --sysconfdir=/etc --disable-static
make
make install
patchelf --remove-rpath /usr/sbin/smbios-sys-info-lite
cp -r out/public-include/* /usr/include
install -t /usr/share/licenses/libsmbios -Dm644 COPYING COPYING-GPL
cd ..
rm -rf libsmbios-2.4.3
# DKMS.
tar -xf dkms-3.1.4.tar.gz
cd dkms-3.1.4
make MODDIR=/usr/lib/modules install
install -t /usr/share/licenses/dkms -Dm644 COPYING
cd ..
rm -rf dkms-3.1.4
# GLib (initial build for circular dependency).
tar -xf glib-2.82.2.tar.xz
cd glib-2.82.2
meson setup build --prefix=/usr --buildtype=minsize -Dglib_debug=disabled -Dintrospection=disabled -Dman=true -Dtests=false -Dsysprof=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/glib -Dm644 COPYING
cd ..
rm -rf glib-2.82.2
# GTK-Doc.
tar -xf gtk-doc-1.34.0.tar.xz
cd gtk-doc-1.34.0
autoreconf -fi
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/gtk-doc -Dm644 COPYING COPYING-DOCS
cd ..
rm -rf gtk-doc-1.34.0
# libsigc++.
tar -xf libsigc++-2.12.1.tar.xz
cd libsigc++-2.12.1
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libsigc++ -Dm644 COPYING
cd ..
rm -rf libsigc++-2.12.1
# GLibmm.
tar -xf glibmm-2.66.7.tar.xz
cd glibmm-2.66.7
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/glibmm -Dm644 COPYING COPYING.tools
cd ..
rm -rf glibmm-2.66.7
# gobject-introspection.
tar -xf gobject-introspection-1.82.0.tar.xz
cd gobject-introspection-1.82.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gobject-introspection -Dm644 COPYING{,.{GPL,LGPL}}
cd ..
rm -rf gobject-introspection-1.82.0
# GLib (rebuild to support gobject-introspection).
tar -xf glib-2.82.2.tar.xz
cd glib-2.82.2
meson setup build --prefix=/usr --buildtype=minsize -Dglib_debug=disabled -Dintrospection=enabled -Dman=true -Dtests=false -Dsysprof=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/glib -Dm644 COPYING
cd ..
rm -rf glib-2.82.2
# shared-mime-info.
tar -xf shared-mime-info-2.4.tar.gz
cd shared-mime-info-2.4
meson setup build --prefix=/usr --buildtype=minsize -Dupdate-mimedb=true
ninja -C build
ninja -C build install
install -t /usr/share/licenses/shared-mime-info -Dm644 COPYING
cd ..
rm -rf shared-mime-info-2.4
# desktop-file-utils.
tar -xf desktop-file-utils-0.28.tar.xz
cd desktop-file-utils-0.28
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -dm755 /usr/share/applications
update-desktop-database /usr/share/applications
install -t /usr/share/licenses/desktop-file-utils -Dm644 COPYING
cd ..
rm -rf desktop-file-utils-0.28
# Graphene.
tar -xf graphene-1.10.8.tar.gz
cd graphene-1.10.8
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false -Dinstalled_tests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/graphene -Dm644 LICENSE.txt
cd ..
rm -rf graphene-1.10.8
# LLVM / Clang / LLD / libc++ / libc++abi / compiler-rt.
tar -xf llvm-19.1.7.src.tar.xz
mkdir -p cmake libunwind third-party
tar -xf cmake-19.1.7.src.tar.xz -C cmake --strip-components=1
tar -xf libunwind-19.1.7.src.tar.xz -C libunwind --strip-components=1
tar -xf third-party-19.1.7.src.tar.xz -C third-party --strip-components=1
cd llvm-19.1.7.src
mkdir -p projects/{compiler-rt,libcxx,libcxxabi} tools/{clang,lld}
tar -xf ../clang-19.1.7.src.tar.xz -C tools/clang --strip-components=1
tar -xf ../lld-19.1.7.src.tar.xz -C tools/lld --strip-components=1
tar -xf ../libcxx-19.1.7.src.tar.xz -C projects/libcxx --strip-components=1
tar -xf ../libcxxabi-19.1.7.src.tar.xz -C projects/libcxxabi --strip-components=1
tar -xf ../compiler-rt-19.1.7.src.tar.xz -C projects/compiler-rt --strip-components=1
tar -xf ../runtimes-19.1.7.src.tar.xz -C cmake/modules --strip-components=3 runtimes-19.1.7.src/cmake/Modules/{Handle,Warning}Flags.cmake
sed -i 's/utility/tool/' utils/FileCheck/CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_DOCDIR=share/doc -DCMAKE_SKIP_INSTALL_RPATH=ON -DLLVM_HOST_TRIPLE=x86_64-pc-linux-gnu -DLLVM_BINUTILS_INCDIR=/usr/include -DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON -DLLVM_ENABLE_FFI=ON -DLLVM_ENABLE_RTTI=ON -DLLVM_ENABLE_ZLIB=ON -DLLVM_ENABLE_ZSTD=ON -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_USE_PERF=ON -DLLVM_TARGETS_TO_BUILD="AMDGPU;BPF;X86" -DENABLE_LINKER_BUILD_ID=ON -DCLANG_CONFIG_FILE_SYSTEM_DIR=/etc/clang -DCLANG_DEFAULT_PIE_ON_LINUX=ON -DLIBCXX_INSTALL_LIBRARY_DIR=/usr/lib -DLIBCXXABI_INSTALL_LIBRARY_DIR=/usr/lib -DLIBCXXABI_USE_LLVM_UNWINDER=OFF -DCOMPILER_RT_USE_LIBCXX=OFF -DLLVM_BUILD_DOCS=ON -DLLVM_ENABLE_SPHINX=ON -DSPHINX_WARNINGS_AS_ERRORS=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -dm755 /etc/clang
echo "-fstack-protector-strong" > /etc/clang/clang.cfg
echo "-fstack-protector-strong" > /etc/clang/clang++.cfg
install -t /usr/share/licenses/llvm -Dm644 LICENSE.TXT
install -t /usr/share/licenses/clang -Dm644 LICENSE.TXT
install -t /usr/share/licenses/lld -Dm644 LICENSE.TXT
install -t /usr/share/licenses/libc++ -Dm644 LICENSE.TXT
install -t /usr/share/licenses/libc++abi -Dm644 LICENSE.TXT
install -t /usr/share/licenses/compiler-rt -Dm644 LICENSE.TXT
cd ..
rm -rf cmake libunwind llvm-19.1.7.src third-party
# bpftool.
tar -xf bpftool-7.5.0.tar.gz
tar -xf libbpf-1.5.0.tar.gz -C bpftool-7.5.0/libbpf --strip-components=1
cd bpftool-7.5.0/src
make all doc
make install doc-install prefix=/usr mandir=/usr/share/man
install -t /usr/share/licenses/bpftool -Dm644 ../LICENSE{,.BSD-2-Clause,.GPL-2.0}
cd ../..
rm -rf bpftool-7.5.0
# volume-key.
tar -xf volume_key-0.3.12.tar.gz
cd volume_key-volume_key-0.3.12
autoreconf -fi
./configure --prefix=/usr --without-python
make
make install
install -t /usr/share/licenses/volume-key -Dm644 COPYING
cd ..
rm -rf volume_key-volume_key-0.3.12
# JSON-GLib.
tar -xf json-glib-1.10.0.tar.xz
cd json-glib-1.10.0
meson setup build --prefix=/usr --buildtype=minsize -Dman=true -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/json-glib -Dm644 COPYING
cd ..
rm -rf json-glib-1.10.0
# mandoc (needed by efivar 38+).
tar -xf mandoc-1.14.6.tar.gz
cd mandoc-1.14.6
./configure --prefix=/usr
make mandoc
install -m755 mandoc /usr/bin/mandoc
install -m644 mandoc.1 /usr/share/man/man1/mandoc.1
install -t /usr/share/licenses/mandoc -Dm644 LICENSE
cd ..
rm -rf mandoc-1.14.6
# efivar.
tar -xf efivar-39.tar.gz
cd efivar-39
make CFLAGS="$CFLAGS"
make LIBDIR=/usr/lib install
install -t /usr/share/licenses/efivar -Dm644 COPYING
cd ..
rm -rf efivar-39
# efibootmgr.
tar -xf efibootmgr-18.tar.bz2
cd efibootmgr-18
make EFIDIR=massos EFI_LOADER=grubx64.efi
make EFIDIR=massos EFI_LOADER=grubx64.efi install
install -t /usr/share/licenses/efibootmgr -Dm644 COPYING
cd ..
rm -rf efibootmgr-18
# libpng.
tar -xf libpng-1.6.45.tar.xz
cd libpng-1.6.45
patch -Np1 -i ../patches/libpng-1.6.45-apng.patch
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libpng -Dm644 LICENSE
cd ..
rm -rf libpng-1.6.45
# FreeType (circular dependency; will be rebuilt later to support HarfBuzz).
tar -xf freetype-2.13.3.tar.xz
cd freetype-2.13.3
sed -ri "s|.*(AUX_MODULES.*valid)|\1|" modules.cfg
sed -r "s|.*(#.*SUBPIXEL_RENDERING) .*|\1|" -i include/freetype/config/ftoption.h
./configure --prefix=/usr --enable-freetype-config --disable-static --without-harfbuzz
make
make install
install -t /usr/share/licenses/freetype -Dm644 LICENSE.TXT docs/GPLv2.TXT
cd ..
rm -rf freetype-2.13.3
# Graphite2 (circular dependency; will be rebuilt later to support HarfBuzz).
tar -xf graphite2-1.3.14.tgz
cd graphite2-1.3.14
sed -i '/cmptest/d' tests/CMakeLists.txt
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/graphite2 -Dm644 COPYING LICENSE
cd ..
rm -rf graphite2-1.3.14
# HarfBuzz.
tar -xf harfbuzz-10.2.0.tar.xz
cd harfbuzz-10.2.0
meson setup build --prefix=/usr --buildtype=minsize -Dgraphite2=enabled -Dtests=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/harfbuzz -Dm644 COPYING
cd ..
rm -rf harfbuzz-10.2.0
# FreeType (rebuild to support HarfBuzz).
tar -xf freetype-2.13.3.tar.xz
cd freetype-2.13.3
sed -ri "s|.*(AUX_MODULES.*valid)|\1|" modules.cfg
sed -r "s|.*(#.*SUBPIXEL_RENDERING) .*|\1|" -i include/freetype/config/ftoption.h
./configure --prefix=/usr --enable-freetype-config --disable-static --with-harfbuzz
make
make install
cd ..
rm -rf freetype-2.13.3
# Graphite2 (rebuild to support HarfBuzz).
tar -xf graphite2-1.3.14.tgz
cd graphite2-1.3.14
sed -i '/cmptest/d' tests/CMakeLists.txt
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
cd ..
rm -rf graphite2-1.3.14
# Woff2.
tar -xf woff2-1.0.2.tar.gz
cd woff2-1.0.2
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/woff2 -Dm644 LICENSE
cd ..
rm -rf woff2-1.0.2
# Unifont.
install -dm755 /usr/share/fonts/unifont
gzip -cd unifont-16.0.01.pcf.gz > /usr/share/fonts/unifont/unifont.pcf
install -t /usr/share/licenses/unifont -Dm644 extra-package-licenses/LICENSE-unifont.txt
# GRUB.
tar -xf grub-2.12.tar.xz
cd grub-2.12
echo "depends bli part_gpt" > grub-core/extra_deps.lst
mkdir build-pc; cd build-pc
CFLAGS="-O2" CXXFLAGS="-O2" ../configure --prefix=/usr --sysconfdir=/etc --disable-efiemu --enable-grub-mkfont --enable-grub-mount --with-platform=pc --disable-werror
mkdir ../build-efi; cd ../build-efi
CFLAGS="-O2" CXXFLAGS="-O2" ../configure --prefix=/usr --sysconfdir=/etc --disable-efiemu --enable-grub-mkfont --enable-grub-mount --with-platform=efi --disable-werror
cd ..
make -C build-pc
make -C build-efi
make -C build-efi bashcompletiondir="/usr/share/bash-completion/completions" install
make -C build-pc bashcompletiondir="/usr/share/bash-completion/completions" install
cat > /usr/share/grub/sbat.csv << "END"
sbat,1,SBAT Version,sbat,1,https://github.com/rhboot/shim/blob/main/SBAT.md
grub,3,Free Software Foundation,grub,2.12,https://gnu.org/software/grub/
grub.massos,1,MassOS,grub,2.12,https://massos.org
END
install -t /usr/share/licenses/grub -Dm644 COPYING
cd ..
rm -rf grub-2.12
# os-prober.
tar -xf os-prober_1.83.tar.xz
cd work
gcc $CFLAGS newns.c -o newns $LDFLAGS
install -t /usr/bin -Dm755 os-prober linux-boot-prober
install -t /usr/lib/os-prober -Dm755 newns
install -t /usr/share/os-prober -Dm755 common.sh
for dir in os-probes os-probes/mounted os-probes/init linux-boot-probes linux-boot-probes/mounted; do
  install -t /usr/lib/$dir -Dm755 $dir/common/*
  if [ -d $dir/x86 ]; then
    cp -r $dir/x86/* /usr/lib/$dir
  fi
done
install -t /usr/lib/os-probes/mounted -Dm755 os-probes/mounted/powerpc/20macosx
install -dm755 /var/lib/os-prober
install -t /usr/share/licenses/os-prober -Dm644 debian/copyright
install -t /usr/share/licenses/os-prober /usr/share/licenses/systemd/LICENSE.GPL2
cd ..
rm -rf work
# libyaml.
tar -xf yaml-0.2.5.tar.gz
cd yaml-0.2.5
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libyaml -Dm644 License
cd ..
rm -rf yaml-0.2.5
# PyYAML.
tar -xf pyyaml-6.0.2.tar.gz
cd pyyaml-6.0.2
pip --disable-pip-version-check wheel --no-build-isolation --no-deps --no-cache-dir -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist PyYAML
install -t /usr/share/licenses/pyyaml -Dm644 LICENSE
cd ..
rm -rf pyyaml-6.0.2
# libatasmart.
tar -xf libatasmart_0.19.orig.tar.xz
cd libatasmart-0.19
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libatasmart -Dm644 LGPL
cd ..
rm -rf libatasmart-0.19
# libbytesize.
tar -xf libbytesize-2.11.tar.gz
cd libbytesize-2.11
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/libbytesize -Dm644 LICENSE
cd ..
rm -rf libbytesize-2.11
# libblockdev.
tar -xf libblockdev-3.2.1.tar.gz
cd libblockdev-3.2.1
./configure --prefix=/usr --sysconfdir=/etc --with-python3 --without-nvdimm
make
make install
install -t /usr/share/licenses/libblockdev -Dm644 LICENSE
cd ..
rm -rf libblockdev-3.2.1
# libdaemon.
tar -xf libdaemon_0.14.orig.tar.gz
cd libdaemon-0.14
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libdaemon -Dm644 LICENSE
cd ..
rm -rf libdaemon-0.14
# libgudev.
tar -xf libgudev-238.tar.xz
cd libgudev-238
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libgudev -Dm644 COPYING
cd ..
rm -rf libgudev-238
# libmbim.
tar -xf libmbim-1.30.0.tar.gz
cd libmbim-1.30.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libmbim -Dm644 LICENSES/*
cd ..
rm -rf libmbim-1.30.0
# libqrtr-glib.
tar -xf libqrtr-glib-1.2.2.tar.gz
cd libqrtr-glib-1.2.2
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libqrtr-glib -Dm644 LICENSES/*
cd ..
rm -rf libqrtr-glib-1.2.2
# libqmi.
tar -xf libqmi-1.34.0.tar.gz
cd libqmi-1.34.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libqmi -Dm644 COPYING COPYING.LIB
cd ..
rm -rf libqmi-1.34.0
# libevdev.
tar -xf libevdev-1.13.3.tar.xz
cd libevdev-1.13.3
meson setup build --prefix=/usr --sysconfdir=/etc --localstatedir=/var -Ddocumentation=disabled -Dtests=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libevdev -Dm644 COPYING
cd ..
rm -rf libevdev-1.13.3
# libwacom.
tar -xf libwacom-2.14.0.tar.xz
cd libwacom-2.14.0
meson setup build --prefix=/usr --buildtype=minsize -Dtests=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libwacom -Dm644 COPYING
cd ..
rm -rf libwacom-2.14.0
# mtdev.
tar -xf mtdev-1.1.7.tar.bz2
cd mtdev-1.1.7
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/mtdev -Dm644 COPYING
cd ..
rm -rf mtdev-1.1.7
# Wayland.
tar -xf wayland-1.23.1.tar.xz
cd wayland-1.23.1
meson setup build --prefix=/usr --buildtype=minsize -Ddocumentation=false -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/wayland -Dm644 COPYING
cd ..
rm -rf wayland-1.23.1
# wayland-protocols.
tar -xf wayland-protocols-1.39.tar.xz
cd wayland-protocols-1.39
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/wayland-protocols -Dm644 COPYING
cd ..
rm -rf wayland-protocols-1.39
# wlr-protocols.
tar -xf wlr-protocols-107.tar.gz
cd wlr-protocols-ffb89ac-ffb89ac790096f6e6272822c8d5df7d0cc6fcdfa
make install
install -dm755 /usr/share/licenses/wlr-protocols
cat > /usr/share/licenses/wlr-protocols/LICENSE << "END"
The license for each component in this package can be found in the component's
XML file in the directory '/usr/share/wlr-protocols/unstable/'.
END
cd ..
rm -rf wlr-protocols-ffb89ac-ffb89ac790096f6e6272822c8d5df7d0cc6fcdfa
# aspell.
tar -xf aspell-0.60.8.1.tar.gz
cd aspell-0.60.8.1
./configure --prefix=/usr
make
make install
ln -sfn aspell-0.60 /usr/lib/aspell
install -m755 scripts/ispell /usr/bin/
install -m755 scripts/spell /usr/bin/
install -t /usr/share/licenses/aspell -Dm644 COPYING
cd ..
rm -rf aspell-0.60.8.1
# aspell-en.
tar -xf aspell6-en-2020.12.07-0.tar.bz2
cd aspell6-en-2020.12.07-0
./configure
make
make install
cd ..
rm -rf aspell6-en-2020.12.07-0
# Enchant.
tar -xf enchant-2.8.2.tar.gz
cd enchant-2.8.2
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/enchant -Dm644 COPYING.LIB
cd ..
rm -rf enchant-2.8.2
# Fontconfig.
tar -xf fontconfig-2.16.0.tar.bz2
cd fontconfig-2.16.0
meson setup build --prefix=/usr --buildtype=minsize -Ddoc-pdf=disabled -Dtests=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/fontconfig -Dm644 COPYING
cd ..
rm -rf fontconfig-2.16.0
# Fribidi.
tar -xf fribidi-1.0.16.tar.xz
cd fribidi-1.0.16
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/fribidi -Dm644 COPYING
cd ..
rm -rf fribidi-1.0.16
# giflib.
tar -xf giflib-5.2.2.tar.gz
cd giflib-5.2.2
patch -Np1 -i ../patches/giflib-5.2.2-manpagedirectory.patch
cp pic/gifgrid.gif doc/giflib-logo.gif
make
make PREFIX=/usr install
rm -f /usr/lib/libgif.a
install -t /usr/share/licenses/giflib -Dm644 COPYING
cd ..
rm -rf giflib-5.2.2
# libexif.
tar -xf libexif-0.6.24.tar.bz2
cd libexif-0.6.24
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libexif -Dm644 COPYING
cd ..
rm -rf libexif-0.6.24
# lolcat.
tar -xf lolcat-1.5.tar.gz
cd lolcat-1.5
make CFLAGS="$CFLAGS"
install -t /usr/bin -Dm755 censor lolcat
install -t /usr/share/licenses/lolcat -Dm644 LICENSE
cd ..
rm -rf lolcat-1.5
# NASM.
tar -xf nasm-2.16.03.tar.xz
cd nasm-2.16.03
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/nasm -Dm644 LICENSE
cd ..
rm -rf nasm-2.16.03
# libjpeg-turbo.
tar -xf libjpeg-turbo-3.1.0.tar.gz
cd libjpeg-turbo-3.1.0
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_DEFAULT_LIBDIR=lib -DCMAKE_SKIP_INSTALL_RPATH=TRUE -DENABLE_STATIC=FALSE -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libjpeg-turbo -Dm644 LICENSE.md README.ijg
cd ..
rm -rf libjpeg-turbo-3.1.0
# libgphoto2
tar -xf libgphoto2-2.5.31.tar.xz
cd libgphoto2-2.5.31
./configure --prefix=/usr --disable-rpath
make
make install
install -t /usr/share/licenses/libgphoto2 -Dm644 COPYING
cd ..
rm -rf libgphoto2-2.5.31
# Pixman.
tar -xf pixman-0.44.2.tar.xz
cd pixman-0.44.2
meson setup build --prefix=/usr --buildtype=minsize -Dtests=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/pixman -Dm644 COPYING
cd ..
rm -rf pixman-0.44.2
# Qpdf.
tar -xf qpdf-11.9.1.tar.gz
cd qpdf-11.9.1
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_STATIC_LIBS=OFF -DINSTALL_EXAMPLES=OFF -DREQUIRE_CRYPTO_GNUTLS=OFF -DREQUIRE_CRYPTO_OPENSSL=ON -DUSE_IMPLICIT_CRYPTO=OFF -DDEFAULT_CRYPTO=openssl -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/bash-completion/completions -Dm644 completions/bash/qpdf
install -t /usr/share/zsh/site-functions -Dm644 completions/zsh/_qpdf
install -t /usr/share/licenses/qpdf -Dm644 Artistic-2.0 LICENSE.txt NOTICE.md
cd ..
rm -rf qpdf-11.9.1
# qrencode.
tar -xf qrencode-4.1.1.tar.bz2
cd qrencode-4.1.1
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/qrencode -Dm644 COPYING
cd ..
rm -rf qrencode-4.1.1
# libsass.
tar -xf libsass-3.6.6.tar.gz
cd libsass-3.6.6
autoreconf -fi
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libsass -Dm644 COPYING LICENSE
cd ..
rm -rf libsass-3.6.6
# sassc.
tar -xf sassc-3.6.2.tar.gz
cd sassc-3.6.2
autoreconf -fi
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/sassc -Dm644 LICENSE
cd ..
rm -rf sassc-3.6.2
# ISO-Codes.
tar -xf iso-codes-v4.17.0.tar.bz2
cd iso-codes-v4.17.0
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/iso-codes -Dm644 COPYING
cd ..
rm -rf iso-codes-v4.17.0
# xdg-user-dirs.
tar -xf xdg-user-dirs-0.18.tar.gz
cd xdg-user-dirs-0.18
./configure --prefix=/usr --sysconfdir=/etc
make
make install
install -t /usr/share/licenses/xdg-user-dirs -Dm644 COPYING
cd ..
rm -rf xdg-user-dirs-0.18
# LSB-Tools.
tar -xf LSB-Tools-0.12.tar.gz
cd LSB-Tools-0.12
make
make install
rm -f /usr/sbin/{lsbinstall,install_initd,remove_initd}
install -t /usr/share/licenses/lsb-tools -Dm644 LICENSE
cd ..
rm -rf LSB-Tools-0.12
# p7zip.
tar -xf p7zip-17.05.tar.gz
cd p7zip-17.05
make OPTFLAGS="$CFLAGS" all3
make DEST_HOME=/usr DEST_MAN=/usr/share/man DEST_SHARE_DOC=/usr/share/doc/p7zip install
install -t /usr/share/licenses/p7zip -Dm644 DOC/License.txt
cd ..
rm -rf p7zip-17.05
# Ruby.
tar -xf ruby-3.4.1.tar.xz
cd ruby-3.4.1
./configure --prefix=/usr --enable-shared --without-baseruby --without-valgrind ac_cv_func_qsort_r=no
make
make capi
make install
install -t /usr/share/licenses/ruby -Dm644 COPYING
cd ..
rm -rf ruby-3.4.1
# slang.
tar -xf slang-2.3.3.tar.bz2
cd slang-2.3.3
./configure --prefix=/usr --sysconfdir=/etc --with-readline=gnu
make -j1
make -j1 install_doc_dir=/usr/share/doc/slang SLSH_DOC_DIR=/usr/share/doc/slang/slsh install-all
chmod 755 /usr/lib/libslang.so.2.3.3 /usr/lib/slang/v2/modules/*.so
rm -f /usr/lib/libslang.a
install -t /usr/share/licenses/slang -Dm644 COPYING
cd ..
rm -rf slang-2.3.3
# BIND Utils.
tar -xf bind-9.20.4.tar.xz
cd bind-9.20.4
./configure --prefix=/usr --with-json-c --with-libidn2 --with-libxml2 --with-lmdb --with-openssl
make -C lib/isc
make -C lib/dns
make -C lib/ns
make -C lib/isccfg
make -C lib/isccc
make -C bin/dig
make -C bin/nsupdate
make -C bin/rndc
make -C doc
make -C lib/isc install
make -C lib/dns install
make -C lib/ns install
make -C lib/isccfg install
make -C lib/isccc install
make -C bin/dig install
make -C bin/nsupdate install
make -C bin/rndc install
install -t /usr/share/man/man1 -Dm644 doc/man/{dig,host,nslookup,nsupdate}.1
install -t /usr/share/licenses/bind-utils -Dm644 COPYRIGHT LICENSE
cd ..
rm -rf bind-9.20.4
# dhcpcd.
tar -xf dhcpcd-10.1.0.tar.xz
cd dhcpcd-10.1.0
echo 'u dhcpcd - "dhcpcd PrivSep" /var/lib/dhcpcd' > /usr/lib/sysusers.d/dhcpcd.conf
systemd-sysusers
install -o dhcpcd -g dhcpcd -dm700 /var/lib/dhcpcd
./configure --prefix=/usr --sysconfdir=/etc --libexecdir=/usr/lib/dhcpcd --runstatedir=/run --dbdir=/var/lib/dhcpcd --privsepuser=dhcpcd
make
make install
rm -f /usr/lib/dhcpcd/dhcpcd-hooks/30-hostname
install -t /usr/share/licenses/dhcpcd -Dm644 LICENSE
cd ..
rm -rf dhcpcd-10.1.0
# xdg-utils.
tar -xf xdg-utils-1.1.3.tar.gz
cd xdg-utils-1.1.3
sed -i 's/egrep/grep -E/' scripts/xdg-open.in
./configure --prefix=/usr --mandir=/usr/share/man
make
make install
install -t /usr/share/licenses/xdg-utils -Dm644 LICENSE
cd ..
rm -rf xdg-utils-1.1.3
# wpa_supplicant.
tar -xf wpa_supplicant-2.11.tar.gz
cd wpa_supplicant-2.11/wpa_supplicant
cat > .config << "END"
CONFIG_BACKEND=file
CONFIG_CTRL_IFACE=y
CONFIG_CTRL_IFACE_DBUS=y
CONFIG_CTRL_IFACE_DBUS_NEW=y
CONFIG_CTRL_IFACE_DBUS_INTRO=y
CONFIG_DEBUG_FILE=y
CONFIG_DEBUG_SYSLOG=y
CONFIG_DEBUG_SYSLOG_FACILITY=LOG_DAEMON
CONFIG_DRIVER_NL80211=y
CONFIG_DRIVER_WEXT=y
CONFIG_DRIVER_WIRED=y
CONFIG_EAP_GTC=y
CONFIG_EAP_LEAP=y
CONFIG_EAP_MD5=y
CONFIG_EAP_MSCHAPV2=y
CONFIG_EAP_OTP=y
CONFIG_EAP_PEAP=y
CONFIG_EAP_TLS=y
CONFIG_EAP_TTLS=y
CONFIG_IEEE8021X_EAPOL=y
CONFIG_IPV6=y
CONFIG_LIBNL32=y
CONFIG_PEERKEY=y
CONFIG_PKCS12=y
CONFIG_READLINE=y
CONFIG_SMARTCARD=y
CONFIG_WPS=y
CFLAGS += -I/usr/include/libnl3
END
make BINDIR=/usr/sbin LIBDIR=/usr/lib
install -m755 wpa_{cli,passphrase,supplicant} /usr/sbin/
install -m644 doc/docbook/wpa_supplicant.conf.5 /usr/share/man/man5/
install -m644 doc/docbook/wpa_{cli,passphrase,supplicant}.8 /usr/share/man/man8/
install -m644 systemd/*.service /usr/lib/systemd/system/
install -m644 dbus/fi.w1.wpa_supplicant1.service /usr/share/dbus-1/system-services/
install -dm755 /etc/dbus-1/system.d
install -m644 dbus/dbus-wpa_supplicant.conf /etc/dbus-1/system.d/wpa_supplicant.conf
install -t /usr/share/licenses/wpa-supplicant -Dm644 ../COPYING ../README
cd ../..
rm -rf wpa_supplicant-2.11
# wireless-tools.
tar -xf wireless_tools.30.pre9.tar.gz
cd wireless_tools.30
sed -i '/BUILD_STATIC =/d' Makefile
make CFLAGS="$CFLAGS -I."
make INSTALL_DIR=/usr/bin INSTALL_LIB=/usr/lib INSTALL_INC=/usr/include INSTALL_MAN=/usr/share/man install
install -t /usr/share/licenses/wireless-tools -Dm644 COPYING
cd ..
rm -rf wireless_tools.30
# fmt.
tar -xf fmt-11.1.2.tar.gz
cd fmt-11.1.2
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=ON -DFMT_TEST=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/fmt -Dm644 LICENSE
cd ..
rm -rf fmt-11.1.2
# libzip.
tar -xf libzip-1.11.2.tar.xz
cd libzip-1.11.2
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_REGRESS=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libzip -Dm644 LICENSE
cd ..
rm -rf libzip-1.11.2
# dmg2img.
tar -xf dmg2img_1.6.7.orig.tar.gz
cd dmg2img-1.6.7
patch --ignore-whitespace -Np1 -i ../patches/dmg2img-1.6.7-openssl.patch
make PREFIX=/usr CFLAGS="$CFLAGS"
install -m755 dmg2img vfdecrypt /usr/bin
install -t /usr/share/licenses/dmg2img -Dm644 COPYING
cd ..
rm -rf dmg2img-1.6.7
# libcbor.
tar -xf libcbor-0.11.0.tar.gz
cd libcbor-0.11.0
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=ON -DWITH_EXAMPLES=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libcbor -Dm644 LICENSE.md
cd ..
rm -rf libcbor-0.11.0
# libfido2.
tar -xf libfido2-1.15.0.tar.gz
cd libfido2-1.15.0
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_EXAMPLES=OFF -DBUILD_STATIC_LIBS=OFF -DBUILD_TESTS=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libfido2 -Dm644 LICENSE
cd ..
rm -rf libfido2-1.15.0
# util-macros.
tar -xf util-macros-1.20.2.tar.xz
cd util-macros-1.20.2
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make install
install -t /usr/share/licenses/util-macros -Dm644 COPYING
cd ..
rm -rf util-macros-1.20.2
# xorgproto.
tar -xf xorgproto-2024.1.tar.xz
cd xorgproto-2024.1
meson setup build --prefix=/usr -Dlegacy=true
ninja -C build
ninja -C build install
install -t /usr/share/licenses/xorgproto -Dm644 COPYING*
cd ..
rm -rf xorgproto-2024.1
# libXau.
tar -xf libXau-1.0.12.tar.xz
cd libXau-1.0.12
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/libxau -Dm644 COPYING
cd ..
rm -rf libXau-1.0.12
# libXdmcp.
tar -xf libXdmcp-1.1.5.tar.xz
cd libXdmcp-1.1.5
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/libxdmcp -Dm644 COPYING
cd ..
rm -rf libXdmcp-1.1.5
# xcb-proto.
tar -xf xcb-proto-1.17.0.tar.xz
cd xcb-proto-1.17.0
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make install
install -t /usr/share/licenses/xcb-proto -Dm644 COPYING
cd ..
rm -rf xcb-proto-1.17.0
# libxcb.
tar -xf libxcb-1.17.0.tar.xz
cd libxcb-1.17.0
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static --without-doxygen
make
make install
install -t /usr/share/licenses/libxcb -Dm644 COPYING
cd ..
rm -rf libxcb-1.17.0
# xtrans.
tar -xf xtrans-1.5.2.tar.xz
cd xtrans-1.5.2
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/xtrans -Dm644 COPYING
cd ..
rm -rf xtrans-1.5.2
# Many needed libraries and dependencies from the Xorg project.
for i in libX11-1.8.10 libXext-1.3.6 libFS-1.0.10 libICE-1.1.2 libSM-1.2.5 libXScrnSaver-1.2.4 libXt-1.3.1 libXmu-1.2.1 libXpm-3.5.17 libXaw-1.0.16 libXfixes-6.0.1 libXcomposite-0.4.6 libXrender-0.9.12 libXcursor-1.2.3 libXdamage-1.1.6 libfontenc-1.1.8 libXfont2-2.0.7 libXft-2.3.8 libXi-1.8.2 libXinerama-1.1.5 libXrandr-1.5.4 libXres-1.2.2 libXtst-1.2.5 libXv-1.0.13 libXvMC-1.0.14 libXxf86dga-1.1.6 libXxf86vm-1.1.6 libdmx-1.1.5 libxkbfile-1.1.3 libxshmfence-1.3.3; do
  tar -xf $i.tar.*
  cd $i
  case $i in
    libXt-*) ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static --with-appdefaultdir=/etc/X11/app-defaults ;;
    libXpm-*) ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static --disable-open-zfile ;;
    *) ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static ;;
  esac
  make
  make install
  install -t /usr/share/licenses/$(echo $i | cut -d- -f1 | tr '[:upper:]' '[:lower:]') -Dm644 COPYING
  cd ..
  rm -rf $i
  ldconfig
done
# libpciaccess.
tar -xf libpciaccess-0.18.1.tar.xz
cd libpciaccess-0.18.1
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libpciaccess -Dm644 COPYING
cd ..
rm -rf libpciaccess-0.18.1
# xcb-util.
tar -xf xcb-util-0.4.1.tar.xz
cd xcb-util-0.4.1
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/xcb-util -Dm644 COPYING
cd ..
rm -rf xcb-util-0.4.1
# xcb-util-image.
tar -xf xcb-util-image-0.4.1.tar.xz
cd xcb-util-image-0.4.1
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/xcb-util-image -Dm644 COPYING
cd ..
rm -rf xcb-util-image-0.4.1
# xcb-util-keysyms.
tar -xf xcb-util-keysyms-0.4.1.tar.xz
cd xcb-util-keysyms-0.4.1
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/xcb-util-keysyms -Dm644 COPYING
cd ..
rm -rf xcb-util-keysyms-0.4.1
# xcb-util-renderutil.
tar -xf xcb-util-renderutil-0.3.10.tar.xz
cd xcb-util-renderutil-0.3.10
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/xcb-util-renderutil -Dm644 COPYING
cd ..
rm -rf xcb-util-renderutil-0.3.10
# xcb-util-wm.
tar -xf xcb-util-wm-0.4.2.tar.xz
cd xcb-util-wm-0.4.2
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/xcb-util-wm -Dm644 COPYING
cd ..
rm -rf xcb-util-wm-0.4.2
# xcb-util-cursor.
tar -xf xcb-util-cursor-0.1.5.tar.xz
cd xcb-util-cursor-0.1.5
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/xcb-util-cursor -Dm644 COPYING
cd ..
rm -rf xcb-util-cursor-0.1.5
# xcb-util-xrm.
tar -xf xcb-util-xrm-1.3.tar.bz2
cd xcb-util-xrm-1.3
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/xcb-util-xrm -Dm644 COPYING
cd ..
rm -rf xcb-util-xrm-1.3
# xcb-util-errors.
tar -xf xcb-util-errors-1.0.1.tar.xz
cd xcb-util-errors-1.0.1
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/xcb-util-errors -Dm644 COPYING
cd ..
rm -rf xcb-util-errors-1.0.1
# libdrm.
tar -xf libdrm-2.4.124.tar.xz
cd libdrm-2.4.124
patch -Np1 -i ../patches/libdrm-2.4.118-license.patch
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false -Dudev=true -Dvalgrind=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libdrm -Dm644 LICENSE
cd ..
rm -rf libdrm-2.4.124
# DirectX-Headers.
tar -xf DirectX-Headers-1.614.1.tar.gz
cd DirectX-Headers-1.614.1
meson setup build --prefix=/usr --buildtype=minsize -Dbuild-test=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/directx-headers -Dm644 LICENSE
cd ..
rm -rf DirectX-Headers-1.614.1
# SPIRV-Headers.
tar -xf SPIRV-Headers-vulkan-sdk-1.4.304.0.tar.gz
cd SPIRV-Headers-vulkan-sdk-1.4.304.0
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/spirv-headers -Dm644 LICENSE
cd ..
rm -rf SPIRV-Headers-vulkan-sdk-1.4.304.0
# SPIRV-Tools.
tar -xf SPIRV-Tools-vulkan-sdk-1.4.304.0.tar.gz
cd SPIRV-Tools-vulkan-sdk-1.4.304.0
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=ON -DSPIRV_TOOLS_BUILD_STATIC=OFF -DSPIRV_WERROR=OFF -DSPIRV-Headers_SOURCE_DIR=/usr -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/spirv-tools -Dm644 LICENSE
cd ..
rm -rf SPIRV-Tools-vulkan-sdk-1.4.304.0
# SPIRV-LLVM-Translator.
tar -xf SPIRV-LLVM-Translator-19.1.3.tar.gz
cd SPIRV-LLVM-Translator-19.1.3
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_SKIP_INSTALL_RPATH=ON -DBUILD_SHARED_LIBS=ON -DLLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR=/usr -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/spirv-llvm-translator -Dm644 LICENSE.TXT
cd ..
rm -rf SPIRV-LLVM-Translator-19.1.3
# libclc.
tar -xf libclc-19.1.7.src.tar.xz
cd libclc-19.1.7.src
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libclc -Dm644 LICENSE.TXT
cd ..
rm -rf libclc-19.1.7.src
# glslang.
tar -xf glslang-15.1.0.tar.gz
cd glslang-15.1.0
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=ON -DALLOW_EXTERNAL_SPIRV_TOOLS=ON -DGLSLANG_TESTS=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/glslang -Dm644 LICENSE.txt
cd ..
rm -rf glslang-15.1.0
# shaderc.
tar -xf shaderc-2024.4.tar.gz
cd shaderc-2024.4
sed -i '/third_party/d' CMakeLists.txt
sed -i '/build-version/d' glslc/CMakeLists.txt
sed -i 's|SPIRV|glslang/&|' libshaderc_util/src/compiler.cc
echo '"2024.4"' > glslc/src/build-version.inc
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DSHADERC_SKIP_TESTS=ON -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/shaderc -Dm644 LICENSE
cd ..
rm -rf shaderc-2024.4
# Vulkan-Headers.
tar -xf Vulkan-Headers-vulkan-sdk-1.4.304.tar.gz
cd Vulkan-Headers-vulkan-sdk-1.4.304
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/vulkan-headers -Dm644 LICENSE.md
cd ..
rm -rf Vulkan-Headers-vulkan-sdk-1.4.304
# Vulkan-Loader.
tar -xf Vulkan-Loader-vulkan-sdk-1.4.304.tar.gz
cd Vulkan-Loader-vulkan-sdk-1.4.304
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DVULKAN_HEADERS_INSTALL_DIR=/usr -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_INSTALL_DATADIR=/share -DCMAKE_SKIP_RPATH=TRUE -DBUILD_TESTS=OFF -DBUILD_WSI_XCB_SUPPORT=ON -DBUILD_WSI_XLIB_SUPPORT=ON -DBUILD_WSI_WAYLAND_SUPPORT=ON -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/vulkan-loader -Dm644 LICENSE.txt
cd ..
rm -rf Vulkan-Loader-vulkan-sdk-1.4.304
# ORC.
tar -xf orc-0.4.40.tar.bz2
cd orc-0.4.40
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
rm -f /usr/lib/liborc-test-0.4.a
install -t /usr/share/licenses/orc -Dm644 COPYING
cd ..
rm -rf orc-0.4.40
# Vulkan-Tools.
tar -xf Vulkan-Tools-vulkan-sdk-1.4.304.0.tar.gz
cd Vulkan-Tools-vulkan-sdk-1.4.304.0
mkdir -p volk
tar -xf ../volk-1.4.304.tar.gz -C volk --strip-components=1
cmake -DCMAKE_INSTALL_PREFIX="$PWD/volk/install" -DCMAKE_BUILD_TYPE=MinSizeRel -DVOLK_INSTALL=ON -Wno-dev -G Ninja -B volk/build -S volk
ninja -C volk/build
ninja -C volk/build install
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DBUILD_CUBE=ON -DBUILD_ICD=OFF -DBUILD_VULKANINFO=ON -DBUILD_WSI_XCB_SUPPORT=ON -DBUILD_WSI_XLIB_SUPPORT=ON -DBUILD_WSI_WAYLAND_SUPPORT=ON -DVOLK_INSTALL_DIR="$PWD/volk/install" -Wno-dev -G Ninja -B build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DBUILD_CUBE=ON -DBUILD_ICD=OFF -DBUILD_VULKANINFO=OFF -DBUILD_WSI_XCB_SUPPORT=OFF -DBUILD_WSI_XLIB_SUPPORT=OFF -DBUILD_WSI_WAYLAND_SUPPORT=ON -DVOLK_INSTALL_DIR="$PWD/volk/install" -Wno-dev -G Ninja -B build-wayland
ninja -C build
ninja -C build-wayland
ninja -C build install
install -Dm755 build-wayland/cube/vkcube /usr/bin/vkcube-wayland
install -t /usr/share/licenses/vulkan-tools -Dm644 LICENSE.txt
cd ..
rm -rf Vulkan-Tools-vulkan-sdk-1.4.304.0
# libva (circular dependency; will be rebuilt later to support Mesa).
tar -xf libva-2.22.0.tar.bz2
cd libva-2.22.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libva -Dm644 COPYING
cd ..
rm -rf libva-2.22.0
# libvdpau.
tar -xf libvdpau-1.5.tar.bz2
cd libvdpau-1.5
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libvdpau -Dm644 COPYING
cd ..
rm -rf libvdpau-1.5
# libglvnd.
tar -xf libglvnd-v1.7.0.tar.bz2
cd libglvnd-v1.7.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
cat README.md | tail -n211 | head -n22 | sed 's/    //g' > COPYING
install -t /usr/share/licenses/libglvnd -Dm644 COPYING
cd ..
rm -rf libglvnd-v1.7.0
# Mesa.
tar -xf mesa-24.3.2.tar.xz
cd mesa-24.3.2
meson setup build --prefix=/usr --buildtype=minsize -Dplatforms=wayland,x11 -Dgallium-drivers=auto -Dvulkan-drivers=auto -Dvulkan-layers=device-select,intel-nullhw,overlay,screenshot -Dgallium-nine=true -Dgallium-opencl=icd -Dgallium-rusticl=true -Dglx=dri -Dglvnd=enabled -Dintel-clc=enabled -Dintel-rt=enabled -Dosmesa=true -Dvideo-codecs=all -Dvalgrind=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/mesa -Dm644 docs/license.rst
cd ..
rm -rf mesa-24.3.2
# libva (rebuild to support Mesa).
tar -xf libva-2.22.0.tar.bz2
cd libva-2.22.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libva -Dm644 COPYING
cd ..
rm -rf libva-2.22.0
# xbitmaps.
tar -xf xbitmaps-1.1.3.tar.xz
cd xbitmaps-1.1.3
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make install
install -t /usr/share/licenses/xbitmaps -Dm644 COPYING
cd ..
rm -rf xbitmaps-1.1.3
# iceauth.
tar -xf iceauth-1.0.10.tar.xz
cd iceauth-1.0.10
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/iceauth -Dm644 COPYING
cd ..
rm -rf iceauth-1.0.10
# luit.
tar -xf luit-1.1.1.tar.bz2
cd luit-1.1.1
sed -i -e "/D_XOPEN/s/5/6/" configure
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/luit -Dm644 COPYING
cd ..
rm -rf luit-1.1.1
# mkfontscale.
tar -xf mkfontscale-1.2.3.tar.xz
cd mkfontscale-1.2.3
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/mkfontscale -Dm644 COPYING
cd ..
rm -rf mkfontscale-1.2.3
# sessreg.
tar -xf sessreg-1.1.3.tar.xz
cd sessreg-1.1.3
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/sessreg -Dm644 COPYING
cd ..
rm -rf sessreg-1.1.3
# setxkbmap.
tar -xf setxkbmap-1.3.4.tar.xz
cd setxkbmap-1.3.4
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/setxkbmap -Dm644 COPYING
cd ..
rm -rf setxkbmap-1.3.4
# smproxy.
tar -xf smproxy-1.0.7.tar.xz
cd smproxy-1.0.7
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/smproxy -Dm644 COPYING
cd ..
rm -rf smproxy-1.0.7
# Many needed programs from the Xorg project.
for i in x11perf-1.7.0 xauth-1.1.3 xbacklight-1.2.4 xcmsdb-1.0.7 xcursorgen-1.0.8 xdpyinfo-1.3.4 xdriinfo-1.0.7 xev-1.2.6 xgamma-1.0.7 xhost-1.0.9 xinput-1.6.4 xkbcomp-1.4.7 xkbevd-1.1.6 xkbutils-1.0.6 xkill-1.0.6 xlsatoms-1.1.4 xlsclients-1.1.5 xmessage-1.0.7 xmodmap-1.0.11 xpr-1.2.0 xprop-1.2.8 xrandr-1.5.3 xrdb-1.2.2 xrefresh-1.1.0 xset-1.2.5 xsetroot-1.1.3 xvinfo-1.1.5 xwd-1.0.9 xwininfo-1.1.6 xwud-1.0.7; do
  tar -xf $i.tar.*
  cd $i
  ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
  make
  make install
  install -t /usr/share/licenses/$(echo $i | cut -d- -f1) -Dm644 COPYING
  cd ..
  rm -rf $i
done
rm -f /usr/bin/xkeystone
# font-util.
tar -xf font-util-1.4.1.tar.xz
cd font-util-1.4.1
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make
make install
install -t /usr/share/licenses/font-util -Dm644 COPYING
cd ..
rm -rf font-util-1.4.1
# noto-fonts / noto-fonts-cjk / noto-fonts-emoji.
tar --no-same-owner --same-permissions -xf noto-fonts-2024.12.01.tar.xz -C / --strip-components=1
tar --no-same-owner --same-permissions -xf noto-fonts-cjk-20230817.tar.xz -C / --strip-components=1
tar --no-same-owner --same-permissions -xf noto-fonts-emoji-2.047.tar.xz -C / --strip-components=1
sed -i 's|<string>sans-serif</string>|<string>Noto Sans</string>|' /etc/fonts/fonts.conf
sed -i 's|<string>monospace</string>|<string>Noto Sans Mono</string>|' /etc/fonts/fonts.conf
fc-cache
# xkeyboard-confdig.
tar -xf xkeyboard-config-2.43.tar.xz
cd xkeyboard-config-2.43
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/xkeyboard-config -Dm644 COPYING
cd ..
rm -rf xkeyboard-config-2.43
# libxklavier.
tar -xf libxklavier-5.4.tar.bz2
cd libxklavier-5.4
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libxklavier -Dm644 COPYING.LIB
cd ..
rm -rf libxklavier-5.4
# libxkbcommon.
tar -xf libxkbcommon-1.7.0.tar.xz
cd libxkbcommon-1.7.0
meson setup build --prefix=/usr --buildtype=minsize -Denable-docs=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libxkbcommon -Dm644 LICENSE
cd ..
rm -rf libxkbcommon-1.7.0
# eglexternalplatform.
tar -xf eglexternalplatform-1.2.tar.gz
cd eglexternalplatform-1.2
patch -Np1 -i ../patches/eglexternalplatform-1.2-upstreamfix.patch
meson setup build --prefix=/usr --buildtype=minsize --includedir=/usr/include/EGL
ninja -C build
ninja -C build install
install -t /usr/share/licenses/eglexternalplatform -Dm644 COPYING
cd ..
rm -rf eglexternalplatform-1.2
# egl-wayland.
tar -xf egl-wayland-1.1.17.tar.gz
cd egl-wayland-1.1.17
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -dm755 /usr/share/egl/egl_external_platform.d
cat > /usr/share/egl/egl_external_platform.d/10_nvidia_wayland.json << "END"
{
    "file_format_version" : "1.0.0",
    "ICD" : {
        "library_path" : "libnvidia-egl-wayland.so.1"
    }
}

END
install -t /usr/share/licenses/egl-wayland -Dm644 COPYING
cd ..
rm -rf egl-wayland-1.1.17
# systemd (rebuild to support more features).
tar -xf systemd-257.2.tar.gz
cd systemd-257.2
meson setup build --prefix=/usr --sysconfdir=/etc --localstatedir=/var --buildtype=minsize -Dmode=release -Dversion-tag=257.2-massos -Dshared-lib-tag=257.2-massos -Dbpf-framework=enabled -Dcryptolib=openssl -Ddefault-compression=xz -Ddefault-dnssec=no -Ddev-kvm-mode=0660 -Ddns-over-tls=openssl -Dfallback-hostname=massos -Dhomed=disabled -Dinitrd=true -Dinstall-tests=false -Dman=enabled -Dpamconfdir=/etc/pam.d -Drpmmacrosdir=no -Dsysupdate=disabled -Dsysusers=true -Dtests=false -Dtpm=true -Dukify=disabled -Duserdb=true
ninja -C build
ninja -C build install
cat > /etc/pam.d/systemd-user << "END"
account  required pam_access.so
account  include  system-account
session  required pam_env.so
session  required pam_limits.so
session  required pam_unix.so
session  required pam_loginuid.so
session  optional pam_keyinit.so force revoke
session  optional pam_systemd.so
auth     required pam_deny.so
password required pam_deny.so
END
cd ..
rm -rf systemd-257.2
# D-Bus (rebuild for X and libaudit support).
tar -xf dbus-1.16.0.tar.xz
cd dbus-1.16.0
meson setup build --prefix=/usr --buildtype=minsize -Dapparmor=enabled -Dlibaudit=enabled -Dmodular_tests=disabled -Dselinux=disabled -Dx11_autolaunch=enabled
ninja -C build
ninja -C build install
systemd-sysusers
cd ..
rm -rf dbus-1.16.0
# D-Bus GLib.
tar -xf dbus-glib-0.112.tar.gz
cd dbus-glib-0.112
./configure --prefix=/usr --sysconfdir=/etc --disable-static
make
make install
install -t /usr/share/licenses/dbus-glib -Dm644 COPYING
cd ..
rm -rf dbus-glib-0.112
# alsa-lib.
tar -xf alsa-lib-1.2.13.tar.bz2
cd alsa-lib-1.2.13
./configure --prefix=/usr --without-debug
make
make install
install -t /usr/share/licenses/alsa-lib -Dm644 COPYING
cd ..
rm -rf alsa-lib-1.2.13
# libepoxy.
tar -xf libepoxy-1.5.10.tar.gz
cd libepoxy-1.5.10
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libepoxy -Dm644 COPYING
cd ..
rm -rf libepoxy-1.5.10
# libxcvt.
tar -xf libxcvt-0.1.3.tar.xz
cd libxcvt-0.1.3
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libxcvt -Dm644 COPYING
cd ..
rm -rf libxcvt-0.1.3
# Xorg-Server.
tar -xf xorg-server-21.1.15.tar.xz
cd xorg-server-21.1.15
patch -Np1 -i ../patches/xorg-server-21.1.2-addxvfbrun.patch
meson setup build --prefix=/usr --buildtype=minsize -Dglamor=true -Dlibunwind=true -Dsuid_wrapper=true -Dxephyr=true -Dxvfb=true -Dxkb_output_dir=/var/lib/xkb
ninja -C build
ninja -C build install
install -t /usr/bin -Dm755 xvfb-run
install -t /usr/share/man/man1 xvfb-run.1
install -dm755 /etc/X11/xorg.conf.d
install -t /usr/share/licenses/xorg-server -Dm644 COPYING
cd ..
rm -rf xorg-server-21.1.15
# Xwayland.
tar -xf xwayland-24.1.4.tar.xz
cd xwayland-24.1.4
meson setup build --prefix=/usr --buildtype=minsize -Dxvfb=false -Dxkb_output_dir=/var/lib/xkb
ninja -C build
ninja -C build install
install -t /usr/share/licenses/xwayland -Dm644 COPYING
cd ..
rm -rf xwayland-24.1.4
# libinput.
tar -xf libinput-1.27.1.tar.bz2
cd libinput-1.27.1
meson setup build --prefix=/usr --buildtype=minsize -Ddebug-gui=false -Ddocumentation=false -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libinput -Dm644 COPYING
cd ..
rm -rf libinput-1.27.1
# xf86-input-libinput.
tar -xf xf86-input-libinput-1.5.0.tar.xz
cd xf86-input-libinput-1.5.0
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/xf86-input-libinput -Dm644 COPYING
cd ..
rm -rf xf86-input-libinput-1.5.0
# intel-gmmlib.
tar -xf intel-gmmlib-22.5.4.tar.gz
cd gmmlib-intel-gmmlib-22.5.4
CFLAGS="" CXXFLAGS="" LDFLAGS="" cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DRUN_TEST_SUITE=OFF -Wno-dev -G Ninja -B build
CFLAGS="" CXXFLAGS="" LDFLAGS="" ninja -C build
CFLAGS="" CXXFLAGS="" LDFLAGS="" ninja -C build install
install -t /usr/share/licenses/intel-gmmlib -Dm644 LICENSE.md
cd ..
rm -rf gmmlib-intel-gmmlib-22.5.4
# intel-vaapi-driver.
tar -xf intel-vaapi-driver-2.4.1.tar.bz2
cd intel-vaapi-driver-2.4.1
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/intel-vaapi-driver -Dm644 COPYING
cd ..
rm -rf intel-vaapi-driver-2.4.1
# intel-media-driver.
tar -xf intel-media-24.4.4.tar.gz
cd media-driver-intel-media-24.4.4
CFLAGS="" CXXFLAGS="" LDFLAGS="" cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DINSTALL_DRIVER_SYSCONF=OFF -DMEDIA_BUILD_FATAL_WARNINGS=OFF -Wno-dev -G Ninja -B build
CFLAGS="" CXXFLAGS="" LDFLAGS="" ninja -C build
CFLAGS="" CXXFLAGS="" LDFLAGS="" ninja -C build install
install -t /usr/share/licenses/intel-media-driver -Dm644 LICENSE.md
cd ..
rm -rf media-driver-intel-media-24.4.4
# xinit.
tar -xf xinit-1.4.3.tar.xz
cd xinit-1.4.3
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static --with-xinitdir=/etc/X11/app-defaults
make
make install
ldconfig
install -t /usr/share/licenses/xinit -Dm644 COPYING
cd ..
rm -rf xinit-1.4.3
# cdrkit.
tar -xf cdrkit_1.1.11.orig.tar.gz
cd cdrkit-1.1.11
patch -Np1 -i ../patches/cdrkit-1.1.11-gcc10.patch
CFLAGS="$CFLAGS -Wno-error=implicit-function-declaration" cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
ln -sf genisoimage /usr/bin/mkisofs
ln -sf genisoimage.1 /usr/share/man/man1/mkisofs.1
install -t /usr/share/licenses/cdrkit -Dm644 COPYING
cd ..
rm -rf cdrkit-1.1.11
# dvd+rw-tools.
tar -xf dvd+rw-tools-7.1.tar.gz
cd pkg-dvd-rw-tools-upstream-7.1
patch -Np1 -i ../patches/dvd+rw-tools-7.1-genericfixes.patch
make CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS"
install -t /usr/bin -m755 growisofs dvd+rw-booktype dvd+rw-format dvd+rw-mediainfo dvd-ram-control
install -t /usr/share/man/man1 -m644 growisofs.1
install -t /usr/share/licenses/dvd+rw-tools -Dm644 LICENSE
cd ..
rm -rf pkg-dvd-rw-tools-upstream-7.1
# libburn.
tar -xf libburn-1.5.6.tar.gz
cd libburn-1.5.6
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libburn -Dm644 COPYING COPYRIGHT
cd ..
rm -rf libburn-1.5.6
# libisofs.
tar -xf libisofs-1.5.6.tar.gz
cd libisofs-1.5.6
./configure --prefix=/usr --disable-static --enable-libacl --enable-xattr
make
make install
install -t /usr/share/licenses/libisofs -Dm644 COPYING COPYRIGHT
cd ..
rm -rf libisofs-1.5.6
# libisoburn.
tar -xf libisoburn-1.5.6.tar.gz
cd libisoburn-1.5.6
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libisoburn -Dm644 COPYING COPYRIGHT
cd ..
rm -rf libisoburn-1.5.6
# yq.
tar -xf yq-4.44.6.tar.gz
cd yq-4.44.6
go build -trimpath -buildmode=pie -ldflags="-linkmode=external"
install -t /usr/bin -Dm755 yq
install -dm755 /usr/share/bash-completion/completions
install -dm755 /usr/share/zsh/site-functions
install -dm755 /usr/share/fish/vendor_completions.d
yq completion bash > /usr/share/bash-completion/completions/yq
yq completion zsh > /usr/share/zsh/site-functions/_yq
yq completion fish > /usr/share/fish/vendor_completions.d/yq.fish
install -t /usr/share/licenses/yq -Dm644 LICENSE
cd ..
rm -rf yq-4.44.6
# tldr (we use the Rust version called 'tealdeer' for faster runtime).
tar -xf tealdeer-1.7.1.tar.gz
cd tealdeer-1.7.1
cargo build --release
install -Dm755 target/release/tldr /usr/bin/tldr
install -Dm644 completion/bash_tealdeer /usr/share/bash-completion/completions/tldr
install -Dm644 completion/fish_tealdeer /usr/share/fish/vendor_completions.d/tldr.fish
install -Dm644 completion/zsh_tealdeer /usr/share/zsh/site-functions/_tldr
install -t /usr/share/licenses/tldr -Dm644 LICENSE-APACHE LICENSE-MIT
cd ..
rm -rf tealdeer-1.7.1
# hyfetch (provides neofetch).
tar -xf hyfetch-1.99.0.tar.gz
cd hyfetch-1.99.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist HyFetch
ln -sf neowofetch /usr/bin/neofetch
install -t /usr/share/licenses/hyfetch -Dm644 LICENSE.md
cd ..
rm -rf hyfetch-1.99.0
# fastfetch.
tar -xf fastfetch-2.33.0.tar.gz
cd fastfetch-2.33.0
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_SYSTEM_YYJSON=ON -DINSTALL_LICENSE=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/fastfetch -Dm644 LICENSE
cd ..
rm -rf fastfetch-2.33.0
# htop.
tar -xf htop-3.3.0.tar.xz
cd htop-3.3.0
./configure --prefix=/usr --sysconfdir=/etc --enable-delayacct --enable-openvz --enable-unicode --enable-vserver
make
make install
rm -f /usr/share/applications/htop.desktop
install -t /usr/share/licenses/htop -Dm644 COPYING
cd ..
rm -rf htop-3.3.0
# bsd-games.
tar -xf bsd-games-3.3.tar.gz
cd bsd-games-3.3
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/bsd-games -Dm644 LICENSE
cd ..
rm -rf bsd-games-3.3
# sl.
tar -xf sl-5.05.tar.gz
cd sl-5.05
gcc $CFLAGS sl.c -o sl -s -lncursesw
install -t /usr/bin -Dm755 sl
install -t /usr/share/man/man1 -Dm644 sl.1
install -t /usr/share/licenses/sl -Dm644 LICENSE
cd ..
rm -rf sl-5.05
# cowsay.
tar -xf cowsay-3.8.4.tar.gz
cd cowsay-3.8.4
make prefix=/usr install
install -t /usr/share/licenses/cowsay -Dm644 LICENSE.txt
cd ..
rm -rf cowsay-3.8.4
# figlet.
tar -xf figlet_2.2.5.orig.tar.gz
cd figlet-2.2.5
make BINDIR=/usr/bin MANDIR=/usr/share/man DEFAULTFONTDIR=/usr/share/figlet/fonts all
make BINDIR=/usr/bin MANDIR=/usr/share/man DEFAULTFONTDIR=/usr/share/figlet/fonts install
install -t /usr/share/licenses/figlet -Dm644 LICENSE
cd ..
rm -rf figlet-2.2.5
# CMatrix.
tar -xf cmatrix-v2.0-Butterscotch.tar
cd cmatrix
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/fonts/misc -Dm644 mtx.pcf
install -t /usr/share/consolefonts -Dm644 matrix.fnt
install -t /usr/share/consolefonts -Dm644 matrix.psf.gz
install -t /usr/share/man/man1 -Dm644 cmatrix.1
install -t /usr/share/licenses/cmatrix -Dm644 COPYING
cd ..
rm -rf cmatrix
# vitetris.
tar -xf vitetris-0.59.1.tar.gz
cd vitetris-0.59.1
sed -i 's|#define CONFIG_FILENAME ".vitetris"|#define CONFIG_FILENAME ".config/vitetris"|' src/config2.h
CFLAGS="$CFLAGS -Wno-error=implicit-function-declaration -Wno-error=implicit-int" ./configure --prefix=/usr --with-ncurses --without-x
make
make gameserver
make install
mv /usr/bin/{tetris,vitetris}
install -m755 gameserver /usr/bin/vitetris-gameserver
ln -sf vitetris /usr/bin/tetris
ln -sf vitetris-gameserver /usr/bin/tetris-gameserver
rm -f /usr/share/applications/vitetris.desktop
rm -f /usr/share/pixmaps/vitetris.xpm
install -t /usr/share/licenses/vitetris -Dm644 licence.txt
cd ..
rm -rf vitetris-0.59.1
# fuseiso.
tar -xf fuseiso-20070708.tar.bz2
cd fuseiso-20070708
patch -Np1 -i ../patches/fuseiso-20070708-fixes.patch
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/fuseiso -Dm644 COPYING
cd ..
rm -rf fuseiso-20070708
# mtools.
tar -xf mtools-4.0.46.tar.bz2
cd mtools-4.0.46
sed -e '/^SAMPLE FILE$/s:^:# :' -i mtools.conf
./configure --prefix=/usr --sysconfdir=/etc --mandir=/usr/share/man --infodir=/usr/share/info
make
make install
install -t /etc -Dm644 mtools.conf
install -t /usr/share/licenses/mtools -Dm644 COPYING
cd ..
rm -rf mtools-4.0.46
# Polkit.
tar -xf polkit-126.tar.gz
cd polkit-126
patch -Np1 -i ../patches/polkit-125-massos-undetected-distro.patch
meson setup build --prefix=/usr --buildtype=minsize -Dman=true -Dpam_prefix=/etc/pam.d -Dsession_tracking=logind -Dtests=false
ninja -C build
ninja -C build install
systemd-sysusers
install -t /usr/share/licenses/polkit -Dm644 COPYING
cd ..
rm -rf polkit-126
# OpenSSH.
tar -xf openssh-9.9p1.tar.gz
cd openssh-9.9p1
install -o root -g sys -dm700 /var/lib/sshd
echo 'u sshd - "sshd PrivSep" /var/lib/sshd' > /usr/lib/sysusers.d/sshd.conf
systemd-sysusers
./configure --prefix=/usr --sysconfdir=/etc/ssh --with-default-path="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin" --with-kerberos5=/usr --with-libedit --with-pam --with-pid-dir=/run --with-privsep-path=/var/lib/sshd --with-privsep-user=sshd --with-ssl-engine --with-xauth=/usr/bin/xauth
make
make install
install -t /usr/bin -Dm755 contrib/ssh-copy-id
install -t /usr/share/man/man1 -Dm644 contrib/ssh-copy-id.1
cp /etc/pam.d/{login,sshd}
sed -i 's/#UsePAM no/UsePAM yes/' /etc/ssh/sshd_config
install -t /usr/share/licenses/openssh -Dm644 LICENCE
cd ..
rm -rf openssh-9.9p1
# sshfs.
tar -xf sshfs-3.7.3.tar.xz
cd sshfs-3.7.3
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/sshfs -Dm644 COPYING
cd ..
rm -rf sshfs-3.7.3
# GLU.
tar -xf glu-9.0.3.tar.xz
cd glu-9.0.3
meson setup build --prefix=/usr --buildtype=minsize -Dgl_provider=gl
ninja -C build
ninja -C build install
rm -f /usr/lib/libGLU.a
cd ..
rm -rf glu-9.0.3
# FreeGLUT.
tar -xf freeglut-3.6.0.tar.gz
cd freeglut-3.6.0
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DFREEGLUT_BUILD_DEMOS=OFF -DFREEGLUT_BUILD_STATIC_LIBS=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/freeglut -Dm644 COPYING
cd ..
rm -rf freeglut-3.6.0
# GLEW.
tar -xf glew-2.2.0.tgz
cd glew-2.2.0
sed -i 's|lib64|lib|g' config/Makefile.linux
make
make install.all
chmod 755 /usr/lib/libGLEW.so.2.2.0
rm -f /usr/lib/libGLEW.a
install -t /usr/share/licenses/glew -Dm644 LICENSE.txt
cd ..
rm -rf glew-2.2.0
# libtiff.
tar -xf libtiff-v4.7.0.tar.bz2
cd libtiff-v4.7.0
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libtiff -Dm644 LICENSE.md
cd ..
rm -rf libtiff-v4.7.0
# lcms2.
tar -xf lcms2-2.16.tar.gz
cd lcms2-2.16
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/lcms2 -Dm644 LICENSE
cd ..
rm -rf lcms2-2.16
# JasPer.
tar -xf jasper-4.2.4.tar.gz
cd jasper-4.2.4
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_SKIP_INSTALL_RPATH=YES -DALLOW_IN_SOURCE_BUILD=YES -DJAS_ENABLE_DOC=NO -DJAS_ENABLE_LIBJPEG=ON -DJAS_ENABLE_OPENGL=ON -Wno-dev -G Ninja -B build1
ninja -C build1
ninja -C build1 install
install -t /usr/share/licenses/jasper -Dm644 LICENSE.txt
cd ..
rm -rf jasper-4.2.4
# libliftoff.
tar -xf libliftoff-v0.5.0.tar.bz2
cd libliftoff-v0.5.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libliftoff -Dm644 LICENSE
cd ..
rm -rf libliftoff-v0.5.0
# wlroots.
tar -xf wlroots-0.18.2.tar.bz2
cd wlroots-0.18.2
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/wlroots -Dm644 LICENSE
cd ..
rm -rf wlroots-0.18.2
# libsysprof-capture.
tar -xf sysprof-47.1.tar.xz
cd sysprof-47.1
meson setup build --prefix=/usr --buildtype=minsize -Dexamples=false -Dgtk=false -Dhelp=false -Dlibsysprof=false -Dsysprofd=none -Dtests=false -Dtools=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libsysprof-capture -Dm644 COPYING{,.gpl-2}
cd ..
rm -rf sysprof-47.1
# at-spi2-core (now provides ATK and at-spi2-atk).
tar -xf at-spi2-core-2.54.1.tar.gz
cd at-spi2-core-2.54.1
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/at-spi2-core -Dm644 COPYING
ln -sf at-spi2-core /usr/share/licenses/at-spi2-atk
ln -sf at-spi2-core /usr/share/licenses/atk
cd ..
rm -rf at-spi2-core-2.54.1
# Atkmm.
tar -xf atkmm-2.28.4.tar.xz
cd atkmm-2.28.4
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/atkmm -Dm644 COPYING{,.tools}
cd ..
rm -rf atkmm-2.28.4
# GDK-Pixbuf.
tar -xf gdk-pixbuf-2.42.12.tar.xz
cd gdk-pixbuf-2.42.12
meson setup build --prefix=/usr --buildtype=minsize -Dinstalled_tests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gdk-pixbuf -Dm644 COPYING
cd ..
rm -rf gdk-pixbuf-2.42.12
# Cairo.
tar -xf cairo-1.18.2.tar.bz2
cd cairo-1.18.2
meson setup build --prefix=/usr --buildtype=minsize -Dtee=enabled -Dtests=disabled -Dxlib-xcb=enabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/cairo -Dm644 COPYING{,-LGPL-2.1}
cd ..
rm -rf cairo-1.18.2
# Cairomm.
tar -xf cairomm-1.14.5.tar.bz2
cd cairomm-1.14.5
meson setup build --prefix=/usr --buildtype=minsize -Dbuild-examples=false -Dbuild-tests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/cairomm -Dm644 COPYING
cd ..
rm -rf cairomm-1.14.5
# HarfBuzz (rebuild to support Cairo).
tar -xf harfbuzz-10.2.0.tar.xz
cd harfbuzz-10.2.0
meson setup build --prefix=/usr --buildtype=minsize -Dgraphite2=enabled -Dtests=disabled
ninja -C build
ninja -C build install
cd ..
rm -rf harfbuzz-10.2.0
# Pango.
tar -xf pango-1.56.0.tar.gz
cd pango-1.56.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/pango -Dm644 COPYING
cd ..
rm -rf pango-1.56.0
# Pangomm.
tar -xf pangomm-2.46.4.tar.xz
cd pangomm-2.46.4
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/pangomm -Dm644 COPYING{,.tools}
cd ..
rm -rf pangomm-2.46.4
# hicolor-icon-theme.
tar -xf hicolor-icon-theme-0.18.tar.xz
cd hicolor-icon-theme-0.18
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/hicolor-icon-theme -Dm644 COPYING
cd ..
rm -rf hicolor-icon-theme-0.18
# sound-theme-freedesktop.
tar -xf sound-theme-freedesktop-0.8.tar.bz2
cd sound-theme-freedesktop-0.8
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/sound-theme-freedesktop -Dm644 CREDITS
cd ..
rm -rf sound-theme-freedesktop-0.8
# GTK2.
tar -xf gtk+-2.24.33.tar.xz
cd gtk+-2.24.33
sed -e 's#l \(gtk-.*\).sgml#& -o \1#' -i docs/{faq,tutorial}/Makefile.in
CFLAGS="$CFLAGS -Wno-error=implicit-int -Wno-error=incompatible-pointer-types" ./configure --prefix=/usr --sysconfdir=/etc
make
make install
install -t /usr/share/licenses/gtk2 -Dm644 COPYING
cd ..
rm -rf gtk+-2.24.33
# libwebp.
tar -xf libwebp-1.5.0.tar.gz
cd libwebp-1.5.0
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_SKIP_INSTALL_RPATH=ON -DBUILD_SHARED_LIBS=ON -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libwebp -Dm644 COPYING
cd ..
rm -rf libwebp-1.5.0
# jp2a.
tar -xf jp2a-1.3.2.tar.bz2
cd jp2a-1.3.2
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/jp2a -Dm644 COPYING LICENSES
cd ..
rm -rf jp2a-1.3.2
# libglade.
tar -xf libglade-2.6.4.tar.bz2
cd libglade-2.6.4
sed -i '/DG_DISABLE_DEPRECATED/d' glade/Makefile.in
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libglade -Dm644 COPYING
cd ..
rm -rf libglade-2.6.4
# Graphviz.
tar -xf graphviz-12.2.1.tar.bz2
cd graphviz-12.2.1
sed -i '/LIBPOSTFIX="64"/s/64//' configure.ac
./autogen.sh
./configure --prefix=/usr --disable-php --enable-lefty --with-webp
sed -i "s|0|$(date +%Y%m%d)|" builddate.h
make
make -j1 install
install -t /usr/share/licenses/graphviz -Dm644 COPYING
cd ..
rm -rf graphviz-12.2.1
# Vala.
tar -xf vala-0.56.17.tar.xz
cd vala-0.56.17
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/vala -Dm644 COPYING
cd ..
rm -rf vala-0.56.17
# libgusb.
tar -xf libgusb-0.4.9.tar.xz
cd libgusb-0.4.9
meson setup build --prefix=/usr --buildtype=minsize -Ddocs=false -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libgusb -Dm644 COPYING
cd ..
rm -rf libgusb-0.4.9
# librsvg.
tar -xf librsvg-2.59.2.tar.xz
cd librsvg-2.59.2
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/librsvg -Dm644 COPYING.LIB
cd ..
rm -rf librsvg-2.59.2
# adwaita-icon-theme.
tar -xf adwaita-icon-theme-47.0.tar.xz
cd adwaita-icon-theme-47.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/adwaita-icon-theme -Dm644 COPYING{,_CCBYSA3,_LGPL}
cd ..
rm -rf adwaita-icon-theme-47.0
# Colord.
tar -xf colord-1.4.7.tar.xz
cd colord-1.4.7
patch -Np1 -i ../patches/colord-1.4.7-upstreamfixes.patch
sed -i '/class="manual"/i<refmiscinfo class="source">colord</refmiscinfo>' man/*.xml
echo 'u colord - "Color Daemon Owner" /var/lib/colord' > /usr/lib/sysusers.d/colord.conf
systemd-sysusers
meson setup build --prefix=/usr --buildtype=minsize -Ddaemon_user=colord -Dvapi=true -Dsystemd=true -Dlibcolordcompat=true -Dargyllcms_sensor=false -Dman=false -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/colord -Dm644 COPYING
cd ..
rm -rf colord-1.4.7
# CUPS.
tar -xf cups-2.4.11-source.tar.gz
cd cups-2.4.11
cat > /usr/lib/sysusers.d/cups.conf << "END"
u cups 420 "CUPS Service User" /var/spool/cups
m cups lp
END
systemd-sysusers
patch -Np1 -i ../patches/cups-2.4.11-pamconfig.patch
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib --with-docdir=/usr/share/cups/doc --with-rundir=/run/cups --with-cups-group=420 --with-cups-user=420 --with-system-groups=lpadmin --enable-libpaper
make
make install
echo "ServerName /run/cups/cups.sock" > /etc/cups/client.conf
sed -e "s|#User 420|User 420|" -e "s|#Group 420|Group 420|" -i /etc/cups/cups-files.conf{,.default}
systemctl enable cups
install -t /usr/share/licenses/cups -Dm644 LICENSE NOTICE
cd ..
rm -rf cups-2.4.11
# cups-pk-helper.
tar -xf cups-pk-helper-0.2.7.tar.xz
cd cups-pk-helper-0.2.7
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/cups-pk-helper -Dm644 COPYING
cd ..
rm -rf cups-pk-helper-0.2.7
# GTK3.
tar -xf gtk+-3.24.43.tar.xz
cd gtk+-3.24.43
meson setup build --prefix=/usr --buildtype=minsize -Dbroadway_backend=true -Dcolord=yes -Dexamples=false -Dman=true -Dprint_backends=cups,file,lpr -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gtk3 -Dm644 COPYING
cd ..
rm -rf gtk+-3.24.43
# Gtkmm3.
tar -xf gtkmm-3.24.9.tar.xz
cd gtkmm-3.24.9
meson setup build --prefix=/usr --buildtype=minsize -Dbuild-demos=false -Dbuild-tests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gtkmm3 -Dm644 COPYING{,.tools}
cd ..
rm -rf gtkmm-3.24.9
# libhandy.
tar -xf libhandy-1.8.3.tar.xz
cd libhandy-1.8.3
meson setup build --prefix=/usr --buildtype=minsize -Dexamples=false -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libhandy -Dm644 COPYING
cd ..
rm -rf libhandy-1.8.3
# libdecor.
tar -xf libdecor-0.2.2.tar.gz
cd libdecor-0.2.2
meson setup build --prefix=/usr --buildtype=minsize -Ddemo=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libdecor -Dm644 LICENSE
cd ..
rm -rf libdecor-0.2.2
# mesa-utils.
tar -xf mesa-demos-9.0.0.tar.xz
cd mesa-demos-9.0.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
install -t /usr/bin -Dm755 build/src/{egl/opengl/eglinfo,xdemos/glx{info,gears}}
install -t /usr/share/licenses/mesa-utils -Dm644 /usr/share/licenses/mesa/license.rst
cd ..
rm -rf mesa-demos-9.0.0
# gnome-themes-extra (for accessibility - provides high contrast theme).
tar -xf gnome-themes-extra-3.28.tar.xz
cd gnome-themes-extra-3.28
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/gnome-themes-extra -Dm644 LICENSE
cd ..
rm -rf gnome-themes-extra-3.28
# webp-pixbuf-loader.
tar -xf webp-pixbuf-loader-0.2.7.tar.gz
cd webp-pixbuf-loader-0.2.7
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/webp-pixbuf-loader -Dm644 LICENSE.LGPL-2
cd ..
rm -rf webp-pixbuf-loader-0.2.7
# gtk-layer-shell.
tar -xf gtk-layer-shell-0.9.0.tar.gz
cd gtk-layer-shell-0.9.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gtk-layer-shell -Dm644 LICENSE_{GPL,LGPL,MIT}.txt
cd ..
rm -rf gtk-layer-shell-0.9.0
# VTE.
tar -xf vte-0.78.2.tar.gz
cd vte-0.78.2
meson setup build --prefix=/usr --buildtype=minsize -Dgtk4=false
ninja -C build
ninja -C build install
rm -f /etc/profile.d/vte.*
install -t /usr/share/licenses/vte -Dm644 COPYING.{CC-BY-4-0,GPL3,LGPL3,XTERM}
cd ..
rm -rf vte-0.78.2
# gcab.
tar -xf gcab-1.6.tar.xz
cd gcab-1.6
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gcab -Dm644 COPYING
cd ..
rm -rf gcab-1.6
# keybinder.
tar -xf keybinder-3.0-0.3.2.tar.gz
cd keybinder-3.0-0.3.2
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/keybinder -Dm644 COPYING
cd ..
rm -rf keybinder-3.0-0.3.2
# libgee.
tar -xf libgee-0.20.6.tar.xz
cd libgee-0.20.6
CFLAGS="$CFLAGS -Wno-error=incompatible-pointer-types" ./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libgee -Dm644 COPYING
cd ..
rm -rf libgee-0.20.6
# exiv2.
tar -xf exiv2-0.28.3.tar.gz
cd exiv2-0.28.3
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DEXIV2_ENABLE_CURL=YES -DEXIV2_ENABLE_NLS=YES -DEXIV2_ENABLE_VIDEO=YES -DEXIV2_ENABLE_WEBREADY=YES -DEXIV2_BUILD_SAMPLES=NO -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/exiv2 -Dm644 COPYING
cd ..
rm -rf exiv2-0.28.3
# meson-python.
tar -xf meson_python-0.16.0.tar.gz
cd meson_python-0.16.0
pip --disable-pip-version-check wheel --no-build-isolation --no-deps --no-cache-dir -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist meson_python
install -t /usr/share/licenses/meson-python -Dm644 LICENSE LICENSES/MIT.txt
cd ..
rm -rf meson_python-0.16.0
# PyCairo.
tar -xf pycairo-1.27.0.tar.gz
cd pycairo-1.27.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/pycairo -Dm644 COPYING{,-LGPL-2.1,-MPL-1.1}
cd ..
rm -rf pycairo-1.27.0
# PyGObject.
tar -xf pygobject-3.50.0.tar.xz
cd pygobject-3.50.0
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/pygobject -Dm644 COPYING
cd ..
rm -rf pygobject-3.50.0
# dbus-python.
tar -xf dbus-python-1.3.2.tar.gz
cd dbus-python-1.3.2
pip --disable-pip-version-check wheel --no-build-isolation --no-deps --no-cache-dir -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist dbus-python
install -t /usr/share/licenses/dbus-python -Dm644 COPYING
cd ..
rm -rf dbus-python-1.3.2
# python-dbusmock.
tar -xf python-dbusmock-0.32.2.tar.gz
cd python-dbusmock-0.32.2
pip --disable-pip-version-check wheel --no-build-isolation --no-deps --no-cache-dir -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist python-dbusmock
install -t /usr/share/licenses/python-dbusmock -Dm644 COPYING
cd ..
rm -rf python-dbusmock-0.32.2
# pycups.
tar -xf pycups-2.0.4.tar.gz
cd pycups-2.0.4
pip --disable-pip-version-check wheel --no-build-isolation --no-deps --no-cache-dir -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pycups
install -t /usr/share/licenses/pycups -Dm644 COPYING
cd ..
rm -rf pycups-2.0.4
# firewalld.
tar -xf firewalld-2.3.0.tar.bz2
cd firewalld-2.3.0
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make
make install
rm -f /etc/xdg/autostart/firewall-applet.desktop
systemctl enable firewalld
install -t /usr/share/licenses/firewalld -Dm644 COPYING
cd ..
rm -rf firewalld-2.3.0
# gexiv2.
tar -xf gexiv2-0.14.3.tar.xz
cd gexiv2-0.14.3
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gexiv2 -Dm644 COPYING
cd ..
rm -rf gexiv2-0.14.3
# libpeas.
tar -xf libpeas-1.36.0.tar.xz
cd libpeas-1.36.0
meson setup build --prefix=/usr --buildtype=minsize -Ddemos=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libpeas -Dm644 COPYING
cd ..
rm -rf libpeas-1.36.0
# libjcat.
tar -xf libjcat-0.2.2.tar.xz
cd libjcat-0.2.2
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libjcat -Dm644 LICENSE
cd ..
rm -rf libjcat-0.2.2
# libgxps.
tar -xf libgxps-0.3.2.tar.xz
cd libgxps-0.3.2
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libgxps -Dm644 COPYING
cd ..
rm -rf libgxps-0.3.2
# djvulibre.
tar -xf djvulibre-3.5.28.tar.gz
cd djvulibre-3.5.28
./configure --prefix=/usr --disable-desktopfiles
make
make install
for i in 22 32 48 64; do install -m644 desktopfiles/prebuilt-hi${i}-djvu.png /usr/share/icons/hicolor/${i}x${i}/mimetypes/image-vnd.djvu.mime.png; done
install -t /usr/share/licenses/djvulibre -Dm644 COPYING COPYRIGHT
cd ..
rm -rf djvulibre-3.5.28
# libraw.
tar -xf LibRaw-0.21.3.tar.gz
cd LibRaw-0.21.3
autoreconf -fi
./configure --prefix=/usr --enable-jasper --enable-jpeg --enable-lcms --disable-static
make
make install
install -t /usr/share/licenses/libraw -Dm644 COPYRIGHT LICENSE.LGPL
cd ..
rm -rf LibRaw-0.21.3
# libogg.
tar -xf libogg-1.3.5.tar.xz
cd libogg-1.3.5
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libogg -Dm644 COPYING
cd ..
rm -rf libogg-1.3.5
# libvorbis.
tar -xf libvorbis-1.3.7.tar.xz
cd libvorbis-1.3.7
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libvorbis -Dm644 COPYING
cd ..
rm -rf libvorbis-1.3.7
# libtheora.
tar -xf libtheora-1.1.1.tar.xz
cd libtheora-1.1.1
sed -i 's/png_\(sizeof\)/\1/g' examples/png2theora.c
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libtheora -Dm644 COPYING LICENSE
cd ..
rm -rf libtheora-1.1.1
# Speex.
tar -xf speex-1.2.1.tar.gz
cd speex-1.2.1
./configure --prefix=/usr --disable-static --enable-binaries
make
make install
install -t /usr/share/licenses/speex -Dm644 COPYING
cd ..
rm -rf speex-1.2.1
# SpeexDSP.
tar -xf speexdsp-1.2.1.tar.gz
cd speexdsp-1.2.1
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/speexdsp -Dm644 COPYING
cd ..
rm -rf speexdsp-1.2.1
# Opus.
tar -xf opus-1.3.1.tar.gz
cd opus-1.3.1
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/opus -Dm644 COPYING
cd ..
rm -rf opus-1.3.1
# FLAC.
tar -xf flac-1.4.3.tar.xz
cd flac-1.4.3
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=ON -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/flac -Dm644 COPYING.{FDL,GPL,LGPL,Xiph}
cd ..
rm -rf flac-1.4.3
# libsndfile (will be rebuilt later with LAME/mpg123 for MPEG support).
tar -xf libsndfile-1.2.2.tar.xz
cd libsndfile-1.2.2
./configure --prefix=/usr --disable-static --disable-mpeg
make
make install
install -t /usr/share/licenses/libsndfile -Dm644 COPYING
cd ..
rm -rf libsndfile-1.2.2
# libsamplerate.
tar -xf libsamplerate-0.2.2.tar.xz
cd libsamplerate-0.2.2
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libsamplerate -Dm644 COPYING
cd ..
rm -rf libsamplerate-0.2.2
# JACK2.
tar -xf jack2-1.9.22.tar.gz
cd jack2-1.9.22
patch -Np1 -i ../patches/jack2-1.9.22-updatewaf.patch
./waf configure --prefix=/usr --htmldir=/usr/share/doc/jack2 --autostart=none --classic --dbus --systemd-unit
./waf build -j$(nproc)
./waf install
install -t /usr/share/licenses/jack2 -Dm644 COPYING
cd ..
rm -rf jack2-1.9.22
# SBC.
tar -xf sbc-2.0.tar.xz
cd sbc-2.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/sbc -Dm644 COPYING COPYING.LIB
cd ..
rm -rf sbc-2.0
# ldac.
tar -xf ldacBT-2.0.2.3.tar.gz
cd ldacBT
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/ldac -Dm644 LICENSE
cd ..
rm -rf ldacBT
# libfreeaptx.
tar -xf libfreeaptx-0.1.1.tar.gz
cd libfreeaptx-0.1.1
make PREFIX=/usr CC=gcc CFLAGS="$CFLAGS"
make PREFIX=/usr install
install -t /usr/share/licenses/libfreeaptx -Dm644 COPYING
cd ..
rm -rf libfreeaptx-0.1.1
# liblc3.
tar -xf liblc3-1.1.1.tar.gz
cd liblc3-1.1.1
sed -i "s|install_rpath: join_paths(get_option('prefix'), get_option('libdir'))||" tools/meson.build
meson setup build --prefix=/usr --buildtype=minsize -Dpython=true -Dtools=true
ninja -C build
ninja -C build install
install -t /usr/share/licenses/liblc3 -Dm644 LICENSE
cd ..
rm -rf liblc3-1.1.1
# libical.
tar -xf libical-3.0.19.tar.gz
cd libical-3.0.19
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DGOBJECT_INTROSPECTION=ON -DICAL_BUILD_DOCS=OFF -DLIBICAL_BUILD_TESTING=OFF -DICAL_GLIB_VAPI=ON -DSHARED_ONLY=ON -Wno-dev -G Ninja -B build
ninja -C build -j1
ninja -C build install
install -t /usr/share/licenses/libical -Dm644 COPYING LICENSE LICENSE.LGPL21.txt
cd ..
rm -rf libical-3.0.19
# BlueZ.
tar -xf bluez-5.79.tar.xz
cd bluez-5.79
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --enable-library
make
make install
ln -sf ../libexec/bluetooth/bluetoothd /usr/sbin
install -dm755 /etc/bluetooth
install -m644 src/main.conf /etc/bluetooth/main.conf
systemctl enable bluetooth
systemctl enable --global obex
install -t /usr/share/licenses/bluez -Dm644 COPYING COPYING.LIB
cd ..
rm -rf bluez-5.79
# Avahi.
tar -xf avahi-0.8.tar.gz
cd avahi-0.8
echo 'u avahi - "Avahi Daemon Owner" /var/run/avahi-daemon' > /usr/lib/sysusers.d/avahi.conf
systemd-sysusers
patch -Np1 -i ../patches/avahi-0.8-upstreamfixes.patch
patch -Np1 -i ../patches/avahi-0.8-add-missing-script.patch
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-mono --disable-monodoc --disable-python --disable-qt3 --disable-qt4 --disable-qt5 --disable-rpath --disable-static --enable-compat-libdns_sd --with-distro=none
make
make install
systemctl enable avahi-daemon
install -t /usr/share/licenses/avahi -Dm644 LICENSE
cd ..
rm -rf avahi-0.8
# PulseAudio.
tar -xf pulseaudio-17.0.tar.xz
cd pulseaudio-17.0
meson setup build --prefix=/usr --buildtype=minsize -Ddatabase=gdbm -Ddoxygen=false -Dtests=false
ninja -C build
ninja -C build install
rm -f /etc/dbus-1/system.d/pulseaudio-system.conf
install -t /usr/share/licenses/pulseaudio -Dm644 LICENSE GPL LGPL
cd ..
rm -rf pulseaudio-17.0
# libao.
tar -xf libao-1.2.2.tar.bz2
cd libao-1.2.2
autoreconf -fi
CFLAGS="$CFLAGS -Wno-error=implicit-function-declaration" ./configure --prefix=/usr --disable-static --disable-esd --enable-alsa-mmap
make
make install
install -t /usr/share/licenses/libao -Dm644 COPYING
cd ..
rm -rf libao-1.2.2
# pcaudiolib.
tar -xf pcaudiolib-1.3.tar.gz
cd pcaudiolib-1.3
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/pcaudiolib -Dm644 COPYING
cd ..
rm -rf pcaudiolib-1.3
# espeak-ng.
tar -xf espeak-ng-1.52.0.tar.gz
cd espeak-ng-1.52.0
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_SKIP_INSTALL_RPATH=ON -DBUILD_SHARED_LIBS=ON -DESPEAK_COMPAT=ON -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/espeak-ng -Dm644 COPYING{,.{APACHE,BSD2,UCD}}
cd ..
rm -rf espeak-ng-1.52.0
# speech-dispatcher.
tar -xf speech-dispatcher-0.11.5.tar.gz
cd speech-dispatcher-0.11.5
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static --without-baratinoo --without-espeak --without-flite --without-ibmtts --without-kali --without-voxin
make
make install
rm -f /etc/speech-dispatcher/modules/{cicero,espeak,espeak-mbrola-generic,flite}.conf
rm -f /usr/libexec/speech-dispatcher-modules/sd_cicero
sed -i 's/#AddModule "espeak-ng"/AddModule "espeak-ng"/' /etc/speech-dispatcher/speechd.conf
systemctl enable speech-dispatcherd
install -t /usr/share/licenses/speech-dispatcher -Dm644 COPYING.{GPL-2,GPL-3,LGPL}
cd ..
rm -rf speech-dispatcher-0.11.5
# SDL.
tar -xf SDL-1.2.15.tar.gz
cd SDL-1.2.15
sed -i '/_XData32/s:register long:register _Xconst long:' src/video/x11/SDL_x11sym.h
./configure --prefix=/usr --disable-static
make
make install
cd ..
rm -rf SDL-1.2.15
# SDL2.
tar -xf SDL2-2.30.10.tar.gz
cd SDL2-2.30.10
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DSDL_HIDAPI_LIBUSB=ON -DSDL_RPATH=OFF -DSDL_STATIC=OFF -DSDL_TEST=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/sdl2 -Dm644 LICENSE.txt
cd ..
rm -rf SDL2-2.30.10
# biosdevname.
tar -xf biosdevname-0.7.3.tar.gz
cd biosdevname-0.7.3
./autogen.sh --prefix=/usr --mandir=/usr/share/man
make
make install
install -t /usr/share/licenses/biosdevname -Dm644 COPYING
cd ..
rm -rf biosdevname-0.7.3
# dmidecode.
tar -xf dmidecode-3.6.tar.xz
cd dmidecode-3.6
make prefix=/usr CFLAGS="$CFLAGS"
make prefix=/usr install
install -t /usr/share/licenses/dmidecode -Dm644 LICENSE
cd ..
rm -rf dmidecode-3.6
# laptop-detect.
tar -xf laptop-detect_0.16.tar.xz
cd laptop-detect-0.16
sed -e "s/@VERSION@/0.16/g" < laptop-detect.in > laptop-detect
install -Dm755 laptop-detect /usr/bin/laptop-detect
install -Dm644 laptop-detect.1 /usr/share/man/man1/laptop-detect.1
install -t /usr/share/licenses/laptop-detect -Dm644 debian/copyright
cd ..
rm -rf laptop-detect-0.16
# flashrom.
tar -xf flashrom-v1.5.1.tar.xz
cd flashrom-v1.5.1
meson setup build --prefix=/usr --buildtype=minsize -Dprogrammer=all -Dtests=disabled
ninja -C build
ninja -C build install
rm -f /usr/lib/libflashrom.a
sed 's|GROUP="plugdev"|TAG+="uaccess"|g' util/flashrom_udev.rules > /usr/lib/udev/rules.d/70-flashrom.rules
install -t /usr/share/licenses/flashrom -Dm644 COPYING
cd ..
rm -rf flashrom-v1.5.1
# rrdtool.
tar -xf rrdtool-1.9.0.tar.gz
cd rrdtool-1.9.0
autoreconf -fi
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-rpath --disable-static --enable-lua --enable-perl --enable-perl-site-install --enable-python --enable-ruby --enable-ruby-site-install --enable-tcl
make
make install
install -t /usr/share/licenses/rrdtool -Dm644 COPYRIGHT LICENSE
cd ..
rm -rf rrdtool-1.9.0
# lm-sensors.
tar -xf lm-sensors-3-6-0.tar.gz
cd lm-sensors-3-6-0
sed -i 's/-Wl,-rpath,$(LIBDIR)//' Makefile
make PREFIX=/usr MANDIR=/usr/share/man BUILD_STATIC_LIB=0 PROG_EXTRA=sensord CFLAGS="$CFLAGS -Wno-error=incompatible-pointer-types"
make PREFIX=/usr MANDIR=/usr/share/man BUILD_STATIC_LIB=0 PROG_EXTRA=sensord install
install -t /usr/share/licenses/lm-sensors -Dm644 COPYING COPYING.LGPL
cd ..
rm -rf lm-sensors-3-6-0
# libpcap.
tar -xf libpcap-1.10.5.tar.xz
cd libpcap-1.10.5
autoreconf -fi
./configure --prefix='/usr' --enable-ipv6 --enable-bluetooth --enable-usb --with-libnl
make
make install
rm -f /usr/lib/libpcap.a
install -t /usr/share/licenses/libpcap -Dm644 LICENSE
cd ..
rm -rf libpcap-1.10.5
# Net-SNMP.
tar -xf net-snmp-5.9.4.tar.gz
cd net-snmp-5.9.4
./configure --prefix=/usr --sysconfdir=/etc --mandir=/usr/share/man --disable-static --enable-ucd-snmp-compatibility --enable-ipv6 --with-python-modules --with-default-snmp-version="3" --with-sys-contact="root@localhost" --with-sys-location="Unknown" --with-logfile="/var/log/snmpd.log" --with-mib-modules="host misc/ipfwacc ucd-snmp/diskio tunnel ucd-snmp/dlmod ucd-snmp/lmsensorsMib" --with-persistent-directory="/var/net-snmp"
make NETSNMP_DONT_CHECK_VERSION=1
make -j1 install
install -t /usr/share/licenses/net-snmp -Dm644 COPYING
cd ..
rm -rf net-snmp-5.9.4
# ppp.
tar -xf ppp-2.5.1.tar.gz
cd ppp-2.5.1
patch -Np1 -i ../patches/ppp-2.4.9-extrafiles.patch
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --runstatedir=/run --enable-cbcp --enable-multilink --enable-systemd
make
make install
install -t /usr/bin -Dm755 scripts/p{on,off,log}
install -t /etc/ppp -Dm755 etc/{ip{,v6}-{down,up},options}
install -Dm600 etc.ppp/chap-secrets.example /etc/ppp/pap-secrets/chap-secrets
install -Dm600 etc.ppp/pap-secrets.example /etc/ppp/pap-secrets/pap-secrets
install -t /usr/share/man/man1 -Dm644 scripts/pon.1
ln -sf pon.1 /usr/share/man/man1/poff.1
ln -sf pon.1 /usr/share/man/man1/plog.1
install -dm755 /etc/ppp/peers
chmod 0755 /usr/lib/pppd/2.5.1/*.so
install -dm755 /usr/share/licenses/ppp
cat > /usr/share/licenses/ppp/LICENSE << "END"
All of the code can be freely used and redistributed.  The individual
source files each have their own copyright and permission notice.
Pppd, pppstats and pppdump are under BSD-style notices.  Some of the
pppd plugins are GPL'd.  Chat is public domain.
END
cd ..
rm -rf ppp-2.5.1
# Vim.
tar -xf vim-9.1.1020.tar.gz
cd vim-9.1.1020
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
echo '#define SYS_GVIMRC_FILE "/etc/gvimrc"' >> src/feature.h
./configure --prefix=/usr --with-features=huge --enable-gpm --enable-gui=gtk3 --with-tlib=ncursesw --enable-luainterp --enable-perlinterp --enable-python3interp=dynamic --enable-rubyinterp --enable-tclinterp --with-tclsh=tclsh --with-compiledby="MassOS"
make
make install
cat > /etc/vimrc << "END"
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1
set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif
END
ln -s vim /usr/bin/vi
for L in /usr/share/man/{,*/}man1/vim.1; do ln -s vim.1 $(dirname $L)/vi.1; done
rm -f /usr/share/applications/vim.desktop
rm -f /usr/share/applications/gvim.desktop
install -t /usr/share/licenses/vim -Dm644 LICENSE
cd ..
rm -rf vim-9.1.1020
# libwpe.
tar -xf libwpe-1.16.0.tar.xz
cd libwpe-1.16.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libwpe -Dm644 COPYING
cd ..
rm -rf libwpe-1.16.0
# OpenJPEG.
tar -xf openjpeg-2.5.3.tar.gz
cd openjpeg-2.5.3
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_STATIC_LIBS=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
cp -r doc/man /usr/share
install -t /usr/share/licenses/openjpeg -Dm644 LICENSE
cd ..
rm -rf openjpeg-2.5.3
# libsecret.
tar -xf libsecret-0.21.6.tar.gz
cd libsecret-0.21.6
meson setup build --prefix=/usr --buildtype=minsize -Dgtk_doc=true
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libsecret -Dm644 COPYING{,.TESTS}
cd ..
rm -rf libsecret-0.21.6
# Gcr.
tar -xf gcr-3.41.2.tar.xz
cd gcr-3.41.2
sed -i 's|"/desktop|"/org|' schema/*.xml
meson setup build --prefix=/usr --buildtype=minsize -Dssh_agent=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gcr -Dm644 COPYING
cd ..
rm -rf gcr-3.41.2
# Gcr4.
tar -xf gcr-4.3.0.tar.xz
cd gcr-4.3.0
meson setup build --prefix=/usr --buildtype=minsize -Dgtk4=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gcr4 -Dm644 COPYING
cd ..
rm -rf gcr-4.3.0
# pinentry.
tar -xf pinentry-1.3.1.tar.bz2
cd pinentry-1.3.1
./configure --prefix=/usr --enable-pinentry-tty
make
make install
install -t /usr/share/licenses/pinentry -Dm644 COPYING
cd ..
rm -rf pinentry-1.3.1
# AccountsService.
tar -xf accountsservice-23.13.9.tar.xz
cd accountsservice-23.13.9
sed -i '/sys.exit(77)/d' tests/test-daemon.py
CFLAGS="$CFLAGS -Wno-error=implicit-function-declaration" meson setup build --prefix=/usr --buildtype=minsize -Dadmin_group=wheel
ninja -C build
ninja -C build install
install -t /usr/share/licenses/accountsservice -Dm644 COPYING
cd ..
rm -rf accountsservice-23.13.9
# polkit-gnome.
tar -xf polkit-gnome-0.105.tar.xz
cd polkit-gnome-0.105
patch -Np1 -i ../patches/polkit-gnome-0.105-upstreamfixes.patch
./configure --prefix=/usr
make
make install
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop << "END"
[Desktop Entry]
Name=PolicyKit Authentication Agent
Comment=PolicyKit Authentication Agent
Exec=/usr/libexec/polkit-gnome-authentication-agent-1
Terminal=false
Type=Application
Categories=
NoDisplay=true
OnlyShowIn=GNOME;XFCE;Unity;
AutostartCondition=GNOME3 unless-session gnome
END
install -t /usr/share/licenses/polkit-gnome -Dm644 COPYING
cd ..
rm -rf polkit-gnome-0.105
# gnome-keyring.
tar -xf gnome-keyring-46.2.tar.xz
cd gnome-keyring-46.2
sed -i 's|"/desktop|"/org|' schema/*.xml
./configure --prefix=/usr --sysconfdir=/etc --enable-ssh-agent --disable-debug
make
make install
install -t /usr/share/licenses/gnome-keyring -Dm644 COPYING COPYING.LIB
cd ..
rm -rf gnome-keyring-46.2
# Poppler.
tar -xf poppler-25.01.0.tar.xz
cd poppler-25.01.0
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_CPP_TESTS=OFF -DBUILD_GTK_TESTS=OFF -DBUILD_MANUAL_TESTS=OFF -DENABLE_QT5=OFF -DENABLE_QT6=OFF -DENABLE_UNSTABLE_API_ABI_HEADERS=ON -DENABLE_ZLIB_UNCOMPRESS=ON -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/poppler -Dm644 COPYING{,3}
cd ..
rm -rf poppler-25.01.0
# poppler-data.
tar -xf poppler-data-0.4.12.tar.gz
cd poppler-data-0.4.12
make prefix=/usr install
install -t /usr/share/licenses/poppler-data -Dm644 COPYING{,.adobe,.gpl2}
cd ..
rm -rf poppler-data-0.4.12
# GhostScript.
tar -xf ghostscript-10.04.0.tar.xz
cd ghostscript-10.04.0
rm -rf cups/libs freetype lcms2mt jpeg leptonica libpng openjpeg tesseract zlib
./configure --prefix=/usr --disable-compile-inits --disable-hidden-visibility --enable-dynamic --enable-fontconfig --enable-freetype --enable-openjpeg --with-drivers=ALL --with-system-libtiff --with-x
make so
make soinstall
install -t /usr/include/ghostscript -Dm644 base/*.h
ln -sf gsc /usr/bin/gs
ln -sfn ghostscript /usr/include/ps
install -t /usr/share/licenses/ghostscript -Dm644 LICENSE
cd ..
rm -rf ghostscript-10.04.0
# libcupsfilters.
tar -xf libcupsfilters-2.1.0.tar.xz
cd libcupsfilters-2.1.0
./configure --prefix=/usr --disable-static --disable-mutool
make
make install
install -t /usr/share/licenses/libcupsfilters -Dm644 LICENSE
cd ..
rm -rf libcupsfilters-2.1.0
# libppd.
tar -xf libppd-2.1.0.tar.xz
cd libppd-2.1.0
./configure --prefix=/usr --disable-static --disable-mutool --enable-ppdc-utils --with-cups-rundir=/run/cups
make
make install
install -t /usr/share/licenses/libppd -Dm644 LICENSE
cd ..
rm -rf libppd-2.1.0
# cups-browsed.
tar -xf cups-browsed-2.1.1.tar.xz
cd cups-browsed-2.1.1
./configure --prefix=/usr --with-cups-rundir=/run/cups --disable-static --without-rcdir
make
make install
install -t /usr/lib/systemd/system -Dm644 daemon/cups-browsed.service
systemctl enable cups-browsed
install -t /usr/share/licenses/cups-browsed -Dm644 COPYING LICENSE
cd ..
rm -rf cups-browsed-2.1.1
# cups-filters.
tar -xf cups-filters-2.0.1.tar.xz
cd cups-filters-2.0.1
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static --disable-mutool
make
make install
install -t /usr/share/licenses/cups-filters -Dm644 COPYING LICENSE
cd ..
rm -rf cups-filters-2.0.1
# cups-pdf.
tar -xf cups-pdf_3.0.1.tar.gz
cd cups-pdf-3.0.1/src
gcc $CFLAGS cups-pdf.c -o cups-pdf -lcups $LDFLAGS
install -t /usr/lib/cups/backend -Dm755 cups-pdf
install -t /usr/share/cups/model -Dm644 ../extra/CUPS-PDF_{,no}opt.ppd
install -t /etc/cups -Dm644 ../extra/cups-pdf.conf
install -t /usr/share/licenses/cups-pdf -Dm644 ../COPYING
cd ../..
rm -rf cups-pdf-3.0.1
# Gutenprint.
tar -xf gutenprint-5.3.4.tar.xz
cd gutenprint-5.3.4
./configure --prefix=/usr --disable-static --disable-static-genppd --disable-test
make
make install
install -t /usr/share/licenses/gutenprint -Dm644 COPYING
cd ..
rm -rf gutenprint-5.3.4
# SANE.
tar -xf backends-1.3.1.tar.gz
cd backends-1.3.1
echo "1.3.1" > .tarball-version
echo "1.3.1" > .version
autoreconf -fi
mkdir build; cd build
../configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-rpath --with-group=scanner --with-lockdir=/run/lock
make
make install
install -Dm644 tools/udev/libsane.rules /usr/lib/udev/rules.d/65-scanner.rules
install -t /usr/share/licenses/sane -Dm644 ../COPYING ../LICENSE ../README.djpeg
cd ../..
rm -rf backends-1.3.1
# HPLIP.
tar -xf hplip-3.24.4.tar.gz
cd hplip-3.24.4
patch -Np1 -i ../patches/hplip-3.24.4-manyfixes.patch
AUTOMAKE="automake --foreign" autoreconf -fi
CFLAGS="$CFLAGS -Wno-error=implicit-function-declaration -Wno-error=implicit-int -Wno-error=incompatible-pointer-types -Wno-error=return-mismatch" ./configure --prefix=/usr --enable-cups-drv-install --enable-hpcups-install --disable-imageProcessor-build --enable-pp-build --disable-qt4 --disable-qt5
make
make -j1 rulesdir=/usr/lib/udev/rules.d install
rm -rf /usr/share/hal
rm -f /etc/xdg/autostart/hplip-systray.desktop
rm -f /usr/share/applications/hp{lip,-uiscan}.desktop
rm -f /usr/bin/hp-{uninstall,upgrade} /usr/share/hplip/{uninstall,upgrade}.py
install -t /usr/share/licenses/hplip -Dm644 COPYING
cd ..
rm -rf hplip-3.24.4
# system-config-printer.
tar -xf system-config-printer-1.5.18.tar.xz
cd system-config-printer-1.5.18
patch -Np1 -i ../patches/system-config-printer-1.5.18-pythonbuild.patch
./bootstrap
./configure --prefix=/usr --sysconfdir=/etc --disable-rpath --with-cups-serverbin-dir=/usr/lib/cups --with-systemdsystemunitdir=/usr/lib/systemd/system --with-udev-rules --with-udevdir=/usr/lib/udev
make
make install
install -t /usr/share/licenses/system-config-printer -Dm644 COPYING
cd ..
rm -rf system-config-printer-1.5.18
# Tk.
tar -xf tk8.6.15-src.tar.gz
cd tk8.6.15/unix
./configure --prefix=/usr --mandir=/usr/share/man --enable-64bit
make
sed -e "s@^\(TK_SRC_DIR='\).*@\1/usr/include'@" -e "/TK_B/s@='\(-L\)\?.*unix@='\1/usr/lib@" -i tkConfig.sh
make install
make install-private-headers
ln -sf wish8.6 /usr/bin/wish
chmod 755 /usr/lib/libtk8.6.so
install -t /usr/share/licenses/tk -Dm644 license.terms
cd ../..
rm -rf tk8.6.15
# Python (rebuild to support SQLite and Tk).
tar -xf Python-3.13.1.tar.xz
cd Python-3.13.1
./configure --prefix=/usr --enable-shared --enable-optimizations --with-system-expat --with-system-libmpdec --without-ensurepip --disable-test-modules
make
make install
cd ..
rm -rf Python-3.13.1
# dnspython.
tar -xf dnspython-2.7.0.tar.gz
cd dnspython-2.7.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist dnspython
install -t /usr/share/licenses/dnspython -Dm644 LICENSE
cd ..
rm -rf dnspython-2.7.0
# chardet.
tar -xf chardet-5.2.0.tar.gz
cd chardet-5.2.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist chardet
install -t /usr/share/licenses/chardet -Dm644 LICENSE
cd ..
rm -rf chardet-5.2.0
# charset-normalizer.
tar -xf charset-normalizer-3.3.2.tar.gz
cd charset-normalizer-3.3.2
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist charset-normalizer
install -t /usr/share/licenses/charset-normalizer -Dm644 LICENSE
cd ..
rm -rf charset-normalizer-3.3.2
# idna.
tar -xf idna-3.10.tar.gz
cd idna-3.10
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist idna
install -t /usr/share/licenses/idna -Dm644 LICENSE.md
cd ..
rm -rf idna-3.10
# pycparser.
tar -xf pycparser-release_v2.22.tar.gz
cd pycparser-release_v2.22
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pycparser
install -t /usr/share/licenses/pycparser -Dm644 LICENSE
cd ..
rm -rf pycparser-release_v2.22
# cffi.
tar -xf cffi-1.17.1.tar.gz
cd cffi-1.17.1
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist cffi
install -t /usr/share/licenses/cffi -Dm644 LICENSE
cd ..
rm -rf cffi-1.17.1
# setuptools-rust.
tar -xf setuptools-rust-1.10.2.tar.gz
cd setuptools-rust-1.10.2
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist setuptools_rust
install -t /usr/share/licenses/setuptools-rust -Dm644 LICENSE
cd ..
rm -rf setuptools-rust-1.10.2
# maturin.
tar -xf maturin-1.8.1.tar.gz
cd maturin-1.8.1
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist maturin
install -t /usr/share/licenses/maturin -Dm644 license-{apache,mit}
cd ..
rm -rf maturin-1.8.1
# cryptography.
tar -xf cryptography-44.0.0.tar.gz
cd cryptography-44.0.0
CC=clang RUSTFLAGS="$RUSTFLAGS -Clinker-plugin-lto -Clinker=clang -Clink-arg=-fuse-ld=lld" pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist cryptography
install -t /usr/share/licenses/cryptography -Dm644 LICENSE{,.APACHE,.BSD}
cd ..
rm -rf cryptography-44.0.0
# pyopenssl.
tar -xf pyopenssl-24.3.0.tar.gz
cd pyopenssl-24.3.0
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist pyOpenSSL
install -t /usr/share/licenses/pyopenssl -Dm644 LICENSE
cd ..
rm -rf pyopenssl-24.3.0
# urllib3.
tar -xf urllib3-2.2.2.tar.gz
cd urllib3-2.2.2
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist urllib3
install -t /usr/share/licenses/urllib3 -Dm644 LICENSE.txt
cd ..
rm -rf urllib3-2.2.2
# requests.
tar -xf requests-2.32.3.tar.gz
cd requests-2.32.3
patch -Np1 -i ../patches/requests-2.32.3-systemcertificates.patch
pip --disable-pip-version-check wheel --no-build-isolation --no-cache-dir --no-deps -w dist .
pip --disable-pip-version-check install --root-user-action ignore --no-cache-dir --no-index --no-user -f dist requests
install -t /usr/share/licenses/requests -Dm644 LICENSE
cd ..
rm -rf requests-2.32.3
# libplist.
tar -xf libplist-2.6.0.tar.bz2
cd libplist-2.6.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libplist -Dm644 COPYING COPYING.LESSER
cd ..
rm -rf libplist-2.6.0
# libimobiledevice-glue.
tar -xf libimobiledevice-glue-1.3.1.tar.bz2
cd libimobiledevice-glue-1.3.1
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/libimobiledevice-glue -Dm644 COPYING
cd ..
rm -rf libimobiledevice-glue-1.3.1
# libusbmuxd.
tar -xf libusbmuxd-2.1.0.tar.bz2
cd libusbmuxd-2.1.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libusbmuxd -Dm644 COPYING
cd ..
rm -rf libusbmuxd-2.1.0
# libimobiledevice.
tar -xf libimobiledevice-1.3.0-217-g1ec2c2c.tar.gz
cd libimobiledevice-1ec2c2c5e3609cc02b302bcbd79ed2872260d350
echo "1.3.0-217-g1ec2c2c" > .tarball-version
./autogen.sh --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libimobiledevice -Dm644 COPYING COPYING.LESSER
cd ..
rm -rf libimobiledevice-1ec2c2c5e3609cc02b302bcbd79ed2872260d350
# ytnef.
tar -xf ytnef-2.1.2.tar.gz
cd ytnef-2.1.2
./autogen.sh
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/ytnef -Dm644 COPYING
cd ..
rm -rf ytnef-2.1.2
# JSON (required by smblient 4.16+).
tar -xf JSON-4.10.tar.gz
cd JSON-4.10
perl Makefile.PL
make
make install
cat lib/JSON.pm | tail -n9 | head -n6 | install -Dm644 /dev/stdin /usr/share/licenses/json/COPYING
cd ..
rm -rf JSON-4.10
# Parse-Yapp.
tar -xf Parse-Yapp-1.21.tar.gz
cd Parse-Yapp-1.21
perl Makefile.PL
make
make install
install -dm755 /usr/share/licenses/parse-yapp
cat lib/Parse/Yapp.pm | tail -n14 | head -n12 > /usr/share/licenses/parse-yapp/COPYING
cd ..
rm -rf Parse-Yapp-1.21
# smbclient (client portion of Samba).
tar -xf samba-4.21.2.tar.gz
cd samba-4.21.2
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --with-pammodulesdir=/usr/lib/security --with-piddir=/run/samba --systemd-install-services --enable-fhs --with-acl-support --with-ads --with-cluster-support --with-ldap --with-pam --with-profiling-data --with-systemd --with-winbind
make
make install
ln -sfr /usr/bin/smbspool /usr/lib/cups/backend/smb
rm -f /etc/sysconfig/samba
rm -f /usr/bin/{cifsdd,ctdb,ctdb_diagnostics,dbwrap_tool,dumpmscat,gentest,ldbadd,ldbdel,ldbedit,ldbmodify,ldbrename,ldbsearch,locktest,ltdbtool,masktest,mdsearch,mvxattr,ndrdump,ntlm_auth,oLschema2ldif,onnode,pdbedit,ping_pong,profiles,regdiff,regpatch,regshell,regtree,samba-regedit,samba-tool,sharesec,smbcontrol,smbpasswd,smbstatus,smbtorture,tdbbackup,tdbdump,tdbrestore,tdbtool,testparm,wbinfo}
rm -f /usr/sbin/{ctdbd,ctdbd_wrapper,eventlogadm,nmbd,samba,samba_dnsupdate,samba_downgrade_db,samba-gpupdate,samba_kcc,samba_spnupdate,samba_upgradedns,smbd,winbindd}
rm -rf /usr/include/samba-4.0/{charset.h,core,credentials.h,dcerpc.h,dcerpc_server.h,dcesrv_core.h,domain_credentials.h,gen_ndr,ldb_wrap.h,lookup_sid.h,machine_sid.h,ndr,ndr.h,param.h,passdb.h,policy.h,rpc_common.h,samba,share.h,smb2_lease_struct.h,smbconf.h,smb_ldap.h,smbldap.h,tdr.h,tsocket.h,tsocket_internal.h,util,util_ldb.h}
rm -rf /usr/lib/samba/{bind9,gensec,idmap,krb5,ldb,nss_info,process_model,service,vfs}
rm -rf /usr/lib/$(readlink /usr/bin/python3)/{samba,talloc.cpython-310-x86_64-linux-gnu.so,tdb.cpython-310-x86_64-linux-gnu.so,_tdb_text.py,_tevent.cpython-310-x86_64-linux-gnu.so,tevent.py}
rm -f /usr/lib/pkgconfig/{dcerpc,dcerpc_samr,dcerpc_server,ndr_krb5pac,ndr_nbt,ndr,ndr_standard,netapi,samba-credentials,samba-hostconfig,samba-policy.cpython-310-x86_64-linux-gnu,samba-util,samdb}.pc
rm -f /usr/lib/security/pam_winbind.so
rm -f /usr/lib/systemd/system/{nmb,samba,smb,winbind}.service
rm -rf /usr/share/{ctdb,samba}
rm -f /usr/share/man/man1/{ctdb,ctdbd,ctdb_diagnostics,ctdbd_wrapper,dbwrap_tool,gentest,ldbadd,ldbdel,ldbedit,ldbmodify,ldbrename,ldbsearch,locktest,log2pcap,ltdbtool,masktest,mdsearch,mvxattr,ndrdump,ntlm_auth,oLschema2ldif,onnode,ping_pong,profiles,regdiff,regpatch,regshell,regtree,sharesec,smbcontrol,smbstatus,smbtorture,testparm,vfstest,wbinfo}.1
rm -f /usr/share/man/man3/{ldb,talloc}.3
rm -f /usr/share/man/man5/{ctdb.conf,ctdb-script.options,ctdb.sysconfig,lmhosts,pam_winbind.conf,smb.conf,smbgetrc,smbpasswd}.5
rm -f /usr/share/man/man7/{ctdb,ctdb-statistics,ctdb-tunables,samba,traffic_learner,traffic_replay}.7
rm -f /usr/share/man/man8/{cifsdd,eventlogadm,idmap_ad,idmap_autorid,idmap_hash,idmap_ldap,idmap_nss,idmap_rfc2307,idmap_rid,idmap_script,idmap_tdb2,idmap_tdb,nmbd,pam_winbind,pdbedit,samba,samba-bgqd,samba_downgrade_db,samba-gpupdate,samba-regedit,samba-tool,smbd,smbpasswd,smbspool_krb5_wrapper,tdbbackup,tdbdump,tdbrestore,tdbtool,vfs_acl_tdb,vfs_acl_xattr,vfs_aio_fork,vfs_aio_pthread,vfs_audit,vfs_btrfs,vfs_cap,vfs_catia,vfs_commit,vfs_crossrename,vfs_default_quota,vfs_dirsort,vfs_extd_audit,vfs_fake_perms,vfs_fileid,vfs_fruit,vfs_full_audit,vfs_glusterfs_fuse,vfs_gpfs,vfs_linux_xfs_sgid,vfs_media_harmony,vfs_offline,vfs_preopen,vfs_readahead,vfs_readonly,vfs_recycle,vfs_shadow_copy2,vfs_shadow_copy,vfs_shell_snap,vfs_snapper,vfs_streams_depot,vfs_streams_xattr,vfs_syncops,vfs_time_audit,vfs_unityed_media,vfs_virusfilter,vfs_widelinks,vfs_worm,vfs_xattr_tdb,winbindd,winbind_krb5_locator}.8
rm -rf /var/cache/samba /var/lib/{ctdb,samba} /var/lock/samba /var/log/samba /var/run/{ctdb,samba}
install -t /usr/share/licenses/smbclient -Dm644 COPYING VFS-License-clarification.txt
cd ..
rm -rf samba-4.21.2
# mobile-broadband-provider-info.
tar -xf mobile-broadband-provider-info-20240407.tar.gz
cd mobile-broadband-provider-info-20240407
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/mobile-broadband-provider-info -Dm644 COPYING
cd ..
rm -rf mobile-broadband-provider-info-20240407
# ModemManager.
tar -xf ModemManager-1.22.0.tar.gz
cd ModemManager-1.22.0
meson setup build --prefix=/usr --buildtype=minsize -Dpolkit=permissive -Dvapi=true
ninja -C build
ninja -C build install
install -t /usr/share/licenses/modemmanager -Dm644 COPYING COPYING.LIB
cd ..
rm -rf ModemManager-1.22.0
# libndp.
tar -xf libndp_1.9.orig.tar.gz
cd libndp-1.9
./autogen.sh
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
install -t /usr/share/licenses/libndp -Dm644 COPYING
cd ..
rm -rf libndp-1.9
# newt.
tar -xf newt-0.52.24.tar.gz
cd newt-0.52.24
sed -e 's/^LIBNEWT =/#&/' -e '/install -m 644 $(LIBNEWT)/ s/^/#/' -e 's/$(LIBNEWT)/$(LIBNEWTSONAME)/g' -i Makefile.in
./configure --prefix=/usr --with-gpm-support --with-python=$(readlink /usr/bin/python3)
make
make install
install -t /usr/share/licenses/newt -Dm644 COPYING
cd ..
rm -rf newt-0.52.24
# UPower.
tar -xf upower-v1.90.7.tar.bz2
cd upower-v1.90.7
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/upower -Dm644 COPYING
systemctl enable upower
cd ..
rm -rf upower-v1.90.7
# power-profiles-daemon.
tar -xf power-profiles-daemon-0.23.tar.bz2
cd power-profiles-daemon-0.23
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/power-profiles-daemon -Dm644 COPYING
systemctl enable power-profiles-daemon
cd ..
rm -rf power-profiles-daemon-0.23
# NetworkManager.
tar -xf NetworkManager-1.50.1.tar.gz
cd NetworkManager-1.50.1
meson setup build --prefix=/usr --buildtype=minsize -Dnmtui=true -Dqt=false -Dselinux=false -Dsession_tracking=systemd -Dtests=no
ninja -C build
ninja -C build install
cat >> /etc/NetworkManager/NetworkManager.conf << "END"
# Put your custom configuration files in '/etc/NetworkManager/conf.d/'.
[main]
plugins=keyfile
END
install -t /usr/share/licenses/networkmanager -Dm644 COPYING{,.{GFD,LGP}L}
systemctl enable NetworkManager
cd ..
rm -rf NetworkManager-1.50.1
# libnma.
tar -xf libnma-1.10.6.tar.xz
cd libnma-1.10.6
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libnma -Dm644 COPYING{,.LGPL}
cd ..
rm -rf libnma-1.10.6
# libnotify.
tar -xf libnotify-0.8.3.tar.xz
cd libnotify-0.8.3
meson setup build --prefix=/usr --buildtype=minsize -Dman=false -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libnotify -Dm644 COPYING
cd ..
rm -rf libnotify-0.8.3
# startup-notification.
tar -xf startup-notification-0.12.tar.gz
cd startup-notification-0.12
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/startup-notification -Dm644 COPYING
cd ..
rm -rf startup-notification-0.12
# libwnck.
tar -xf libwnck-43.2.tar.gz
cd libwnck-43.2
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libwnck -Dm644 COPYING
cd ..
rm -rf libwnck-43.2
# network-manager-applet.
tar -xf network-manager-applet-1.36.0.tar.xz
cd network-manager-applet-1.36.0
meson setup build --prefix=/usr --buildtype=minsize -Dappindicator=no -Dselinux=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/network-manager-applet -Dm644 COPYING
cd ..
rm -rf network-manager-applet-1.36.0
# NetworkManager-openvpn.
tar -xf NetworkManager-openvpn-1.12.0.tar.xz
cd NetworkManager-openvpn-1.12.0
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make
make install
echo 'u nm-openvpn - "NetworkManager OpenVPN" -' > /usr/lib/sysusers.d/nm-openvpn.conf
systemd-sysusers
install -t /usr/share/licenses/networkmanager-openvpn -Dm644 COPYING
cd ..
rm -rf NetworkManager-openvpn-1.12.0
# UDisks.
tar -xf udisks-2.10.1.tar.bz2
cd udisks-2.10.1
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static --enable-available-modules
make
make install
install -t /usr/share/licenses/udisks -Dm644 COPYING
cd ..
rm -rf udisks-2.10.1
# gsettings-desktop-schemas.
tar -xf gsettings-desktop-schemas-47.1.tar.xz
cd gsettings-desktop-schemas-47.1
sed -i -r 's|"(/system)|"/org/gnome\1|g' schemas/*.in
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gsettings-desktop-schemas -Dm644 COPYING
cd ..
rm -rf gsettings-desktop-schemas-47.1
# libproxy.
tar -xf libproxy-0.5.9.tar.gz
cd libproxy-0.5.9
meson setup build --prefix=/usr --buildtype=minsize -Drelease=true -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libproxy -Dm644 COPYING
cd ..
rm -rf libproxy-0.5.9
# glib-networking.
tar -xf glib-networking-2.80.1.tar.gz
cd glib-networking-2.80.1
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/glib-networking -Dm644 COPYING
cd ..
rm -rf glib-networking-2.80.1
# libsoup.
tar -xf libsoup-2.74.3.tar.gz
cd libsoup-2.74.3
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false -Dvapi=enabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libsoup -Dm644 COPYING
cd ..
rm -rf libsoup-2.74.3
# libsoup3.
tar -xf libsoup-3.6.4.tar.gz
cd libsoup-3.6.4
meson setup build --prefix=/usr --buildtype=minsize -Dpkcs11_tests=disabled -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libsoup3 -Dm644 COPYING
cd ..
rm -rf libsoup-3.6.4
# ostree.
tar -xf libostree-2024.10.tar.xz
cd libostree-2024.10
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static --enable-experimental-api --enable-gtk-doc --with-curl --with-dracut --with-ed25519-libsodium --with-modern-grub --with-grub2-mkconfig-path=/usr/bin/grub-mkconfig --with-openssl --without-soup
make
make install
rm -f /etc/dracut.conf.d/ostree.conf
install -t /usr/share/licenses/libostree -Dm644 COPYING
cd ..
rm -rf libostree-2024.10
# libxmlb.
tar -xf libxmlb-0.3.21.tar.xz
cd libxmlb-0.3.21
meson setup build --prefix=/usr --buildtype=minsize -Dstemmer=true -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libxmlb -Dm644 LICENSE
cd ..
rm -rf libxmlb-0.3.21
# AppStream.
tar -xf AppStream-1.0.4.tar.xz
cd AppStream-1.0.4
meson setup build --prefix=/usr --buildtype=minsize -Dvapi=true -Dcompose=true
ninja -C build
ninja -C build install
install -t /usr/share/licenses/appstream -Dm644 COPYING
cd ..
rm -rf AppStream-1.0.4
# appstream-glib.
tar -xf appstream_glib_0_8_3.tar.gz
cd appstream-glib-appstream_glib_0_8_3
meson setup build --prefix=/usr --buildtype=minsize -Drpm=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/appstream-glib -Dm644 COPYING
cd ..
rm -rf appstream-glib-appstream_glib_0_8_3
# Bubblewrap.
tar -xf bubblewrap-0.11.0.tar.xz
cd bubblewrap-0.11.0
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/bubblewrap -Dm644 COPYING
cd ..
rm -rf bubblewrap-0.11.0
# xdg-dbus-proxy.
tar -xf xdg-dbus-proxy-0.1.6.tar.xz
cd xdg-dbus-proxy-0.1.6
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/xdg-dbus-proxy -Dm644 COPYING
cd ..
rm -rf xdg-dbus-proxy-0.1.6
# Malcontent (circular dependency; initial build without malcontent-ui).
tar -xf malcontent-0.10.5.tar.xz
cd malcontent-0.10.5
tar -xf ../libglib-testing-0.1.1.tar.xz -C subprojects
mv subprojects/libglib-testing{-0.1.1,}
meson setup build --prefix=/usr --buildtype=minsize -Dui=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/malcontent -Dm644 COPYING{,-DOCS}
cd ..
rm -rf malcontent-0.10.5
# Flatpak.
tar -xf flatpak-1.14.10.tar.xz
cd flatpak-1.14.10
patch -Np1 -i ../patches/flatpak-1.14.5-flathubrepo.patch
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static --with-system-bubblewrap --with-system-dbus-proxy --with-dbus-config-dir=/usr/share/dbus-1/system.d
make
make install
cat >> /etc/profile.d/flatpak.sh << "END"
# Ensure PATH includes Flatpak directories.
if [ -n "$XDG_DATA_HOME" ] && [ -d "$XDG_DATA_HOME/flatpak/exports/bin" ]; then
  PATH="$PATH:$XDG_DATA_HOME/flatpak/exports/bin"
elif [ -n "$HOME" ] && [ -d "$HOME/.local/share/flatpak/exports/bin" ]; then
  PATH="$PATH:$HOME/.local/share/flatpak/exports/bin"
fi
if [ -d /var/lib/flatpak/exports/bin ]; then
  PATH="$PATH:/var/lib/flatpak/exports/bin"
fi
export PATH
END
sed -i 's|"Flatpak system helper" -|"Flatpak system helper" /var/lib/flatpak|' /usr/lib/sysusers.d/flatpak.conf
systemd-sysusers
flatpak remote-add --if-not-exists flathub ./flathub.flatpakrepo
install -t /usr/share/licenses/flatpak -Dm644 COPYING
cd ..
rm -rf flatpak-1.14.10
# Malcontent (rebuild with malcontent-ui after resolving circular dependency).
tar -xf malcontent-0.10.5.tar.xz
cd malcontent-0.10.5
tar -xf ../libglib-testing-0.1.1.tar.xz -C subprojects
mv subprojects/libglib-testing{-0.1.1,}
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/malcontent -Dm644 COPYING{,-DOCS}
cd ..
rm -rf malcontent-0.10.5
# libportal / libportal-gtk3.
tar -xf libportal-0.9.0.tar.xz
cd libportal-0.9.0
meson setup build --prefix=/usr --buildtype=minsize -Dbackend-gtk3=enabled -Dbackend-gtk4=disabled -Dbackend-qt5=disabled -Ddocs=false -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libportal -Dm644 COPYING
install -t /usr/share/licenses/libportal-gtk3 -Dm644 COPYING
cd ..
rm -rf libportal-0.9.0
# geocode-glib.
tar -xf geocode-glib-3.26.4.tar.xz
cd geocode-glib-3.26.4
meson setup build1 --prefix=/usr --buildtype=minsize -Denable-installed-tests=false
meson setup build2 --prefix=/usr --buildtype=minsize -Denable-installed-tests=false -Dsoup2=false
ninja -C build1
ninja -C build2
ninja -C build1 install
ninja -C build2 install
install -t /usr/share/licenses/geocode-glib -Dm644 COPYING.LIB
cd ..
rm -rf geocode-glib-3.26.4
# GeoClue.
tar -xf geoclue-2.7.2.tar.bz2
cd geoclue-2.7.2
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/geoclue -Dm644 COPYING{,.LIB}
cd ..
rm -rf geoclue-2.7.2
# passim.
tar -xf passim-0.1.8.tar.xz
cd passim-0.1.8
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/passim -Dm644 LICENSE
cd ..
rm -rf passim-0.1.8
# fwupd-efi.
tar -xf fwupd-efi-1.7.tar.gz
cd fwupd-efi-1.7
meson setup build --prefix=/usr --buildtype=minsize -Defi_sbat_distro_id="massos" -Defi_sbat_distro_summary="MassOS" -Defi_sbat_distro_pkgname="fwupd-efi" -Defi_sbat_distro_version="1.5" -Defi_sbat_distro_url="https://massos.org"
ninja -C build
ninja -C build install
install -t /usr/share/licenses/fwupd-efi -Dm644 COPYING
cd ..
rm -rf fwupd-efi-1.7
# fwupd.
tar -xf fwupd-2.0.3.tar.xz
cd fwupd-2.0.3
meson setup build --prefix=/usr --buildtype=minsize -Defi_binary=false -Dlaunchd=disabled -Dsupported_build=enabled -Dsystemd_unit_user=fwupd -Dtests=false
ninja -C build
ninja -C build install
systemd-sysusers
install -t /usr/share/licenses/fwupd -Dm644 COPYING
cd ..
rm -rf fwupd-2.0.3
# libcdio.
tar -xf libcdio-2.1.0.tar.bz2
cd libcdio-2.1.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libcdio -Dm644 COPYING
cd ..
rm -rf libcdio-2.1.0
# libcdio-paranoia.
tar -xf libcdio-paranoia-10.2+2.0.2.tar.gz
cd libcdio-paranoia-10.2+2.0.2
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libcdio-paranoia -Dm644 COPYING
cd ..
rm -rf libcdio-paranoia-10.2+2.0.2
# rest (built twice for both ABIs: rest-0.7 and rest-1.0).
tar -xf rest-0.8.1.tar.xz
cd rest-0.8.1
./configure --prefix=/usr --with-ca-certificates=/etc/pki/tls/certs/ca-bundle.crt
make
make install
cd ..
rm -rf rest-0.8.1
tar -xf rest-0.9.1.tar.xz
cd rest-0.9.1
patch -Np1 -i ../patches/rest-0.9.1-upstreamfix.patch
meson setup build --prefix=/usr --buildtype=minsize -Dexamples=false -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/rest -Dm644 COPYING
cd ..
rm -rf rest-0.9.1
# wpebackend-fdo.
tar -xf wpebackend-fdo-1.14.3.tar.xz
cd wpebackend-fdo-1.14.3
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/wpebackend-fdo -Dm644 COPYING
cd ..
rm -rf wpebackend-fdo-1.14.3
# libass.
tar -xf libass-0.17.3.tar.xz
cd libass-0.17.3
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libass -Dm644 COPYING
cd ..
rm -rf libass-0.17.3
# OpenH264.
tar -xf openh264-2.5.0.tar.gz
cd openh264-2.5.0
meson setup build --prefix=/usr --buildtype=minsize -Dtests=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/openh264 -Dm644 LICENSE
cd ..
rm -rf openh264-2.5.0
# libde265.
tar -xf libde265-1.0.15.tar.gz
cd libde265-1.0.15
./configure --prefix=/usr --disable-static --disable-sherlock265
make
make install
rm -f /usr/bin/tests
install -t /usr/share/licenses/libde265 -Dm644 COPYING
cd ..
rm -rf libde265-1.0.15
# cdparanoia.
tar -xf cdparanoia-III-10.2.src.tgz
cd cdparanoia-III-10.2
patch -Np1 -i ../patches/cdparanoia-III-10.2-buildfix.patch
./configure --prefix=/usr --mandir=/usr/share/man
make -j1
make -j1 install
chmod 755 /usr/lib/libcdda_*.so.0.10.2
install -t /usr/share/licenses/cdparanoia -Dm644 COPYING-GPL COPYING-LGPL
cd ..
rm -rf cdparanoia-III-10.2
# mpg123.
tar -xf mpg123-1.32.10.tar.bz2
cd mpg123-1.32.10
./configure --prefix=/usr --enable-int-quality=yes --with-audio="alsa jack oss pulse sdl"
make
make install
install -t /usr/share/licenses/mpg123 -Dm644 COPYING
cd ..
rm -rf mpg123-1.32.10
# libvpx.
tar -xf libvpx-1.15.0.tar.gz
cd libvpx-1.15.0
sed -i 's/cp -p/cp/' build/make/Makefile
mkdir libvpx-build; cd libvpx-build
../configure --prefix=/usr --enable-shared --disable-static --disable-examples --disable-unit-tests
make
make install
install -t /usr/share/licenses/libvpx -Dm644 ../LICENSE
cd ../..
rm -rf libvpx-1.15.0
# LAME.
tar -xf lame3_100.tar.gz
cd LAME-lame3_100
./configure --prefix=/usr --enable-mp3rtp --enable-nasm --disable-static
make
make install
install -t /usr/share/licenses/lame -Dm644 COPYING LICENSE
cd ..
rm -rf LAME-lame3_100
# libsndfile (LAME/mpg123 rebuild).
tar -xf libsndfile-1.2.2.tar.xz
cd libsndfile-1.2.2
./configure --prefix=/usr --disable-static
make
make install
cd ..
rm -rf libsndfile-1.2.2
# twolame.
tar -xf twolame-0.4.0.tar.gz
cd twolame-0.4.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/twolame -Dm644 COPYING
cd ..
rm -rf twolame-0.4.0
# Taglib.
tar -xf taglib-2.0.2.tar.gz
cd taglib-2.0.2
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DBUILD_SHARED_LIBS=ON -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/taglib -Dm644 COPYING.{LGPL,MPL}
cd ..
rm -rf taglib-2.0.2
# SoundTouch.
tar -xf soundtouch-2.3.3.tar.gz
cd soundtouch
./bootstrap
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/soundtouch -Dm644 COPYING.TXT
cd ..
rm -rf soundtouch
# libdv.
tar -xf libdv-1.0.0.tar.gz
cd libdv-1.0.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libdv -Dm644 COPYING COPYRIGHT
cd ..
rm -rf libdv-1.0.0
# libdvdread.
tar -xf libdvdread-6.1.3.tar.bz2
cd libdvdread-6.1.3
autoreconf -fi
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libdvdread -Dm644 COPYING
cd ..
rm -rf libdvdread-6.1.3
# libdvdnav.
tar -xf libdvdnav-6.1.1.tar.bz2
cd libdvdnav-6.1.1
autoreconf -fi
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libdvdnav -Dm644 COPYING
cd ..
rm -rf libdvdnav-6.1.1
# libcanberra.
tar -xf libcanberra_0.30.orig.tar.xz
cd libcanberra-0.30
patch -Np1 -i ../patches/libcanberra-0.30-wayland.patch
./configure --prefix=/usr --disable-oss
make
make -j1 install
install -t /usr/share/licenses/libcanberra -Dm644 LGPL
cat > /etc/X11/xinit/xinitrc.d/40-libcanberra-gtk-module.sh << "END"
#!/bin/bash

# GNOME loads the libcanberra GTK module automatically, but others don't.
if [ "${DESKTOP_SESSION:0:5}" != "gnome" ] && [ -z "${GNOME_DESKTOP_SESSION_ID}" ]; then
  if [ -z "$GTK_MODULES" ]; then
    GTK_MODULES="canberra-gtk-module"
  else
    GTK_MODULES="$GTK_MODULES:canberra-gtk-module"
  fi
  export GTK_MODULES
fi
END
chmod 755 /etc/X11/xinit/xinitrc.d/40-libcanberra-gtk-module.sh
cd ..
rm -rf libcanberra-0.30
# x264.
tar -xf x264-0.164.3198.tar.bz2
cd x264-da14df5535fd46776fb1c9da3130973295c87aca
cat > version.sh << "END"
#!/bin/sh
# Hardcode version because required files don't exist in git snapshot.
cat > /dev/stdout << "ENE"
#define X264_REV 3198
#define X264_REV_DIFF 0
#define X264_VERSION " r3198 da14df5"
#define X264_POINTVER "0.164.3198 da14df5"
ENE
END
./configure --prefix=/usr --enable-shared --extra-cflags="-DX264_BIT_DEPTH=0 -DX264_CHROMA_FORMAT=0 -DX264_GPL=1 -DX264_INTERLACED=1"
make
make install
install -t /usr/share/licenses/x264 -Dm644 COPYING
cd ..
rm -rf x264-da14df5535fd46776fb1c9da3130973295c87aca
# x265.
tar -xf x265_4.1.tar.gz
cd x265_4.1
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DGIT_ARCHETYPE=1 -Wno-dev -G Ninja -B build -S source
ninja -C build
ninja -C build install
rm -f /usr/lib/libx265.a
install -t /usr/share/licenses/x265 -Dm644 COPYING
cd ..
rm -rf x265_4.1
# libraw1394.
tar -xf libraw1394-2.1.2.tar.xz
cd libraw1394-2.1.2
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libraw1394 -Dm644 COPYING.LIB
cd ..
rm -rf libraw1394-2.1.2
# libavc1394.
tar -xf libavc1394-0.5.4.tar.gz
cd libavc1394-0.5.4
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libavc1394 -Dm644 COPYING
cd ..
rm -rf libavc1394-0.5.4
# libiec61883.
tar -xf libiec61883-1.2.0.tar.xz
cd libiec61883-1.2.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libiec61883 -Dm644 COPYING
cd ..
rm -rf libiec61883-1.2.0
# libnice.
tar -xf libnice-0.1.22.tar.gz
cd libnice-0.1.22
meson setup build --prefix=/usr --buildtype=minsize -Dexamples=disabled -Dtests=disabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libnice -Dm644 COPYING.LGPL
cd ..
rm -rf libnice-0.1.22
# libbs2b.
tar -xf libbs2b-3.1.0.tar.bz2
cd libbs2b-3.1.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libbs2b -Dm644 COPYING
cd ..
rm -rf libbs2b-3.1.0
# a52dec.
tar -xf a52dec-0.8.0.tar.gz
cd a52dec-0.8.0
CFLAGS="$CFLAGS -fPIC" ./configure --prefix=/usr --mandir=/usr/share/man --enable-shared --disable-static
make
make install
install -t /usr/include/a52dec -Dm644 liba52/a52_internal.h
install -t /usr/share/licenses/a52dec -Dm644 COPYING
cd ..
rm -rf a52dec-0.8.0
# xvidcore.
tar -xf xvidcore-1.3.7.tar.bz2
cd xvidcore/build/generic
./configure --prefix=/usr
make
make install
chmod 755 /usr/lib/libxvidcore.so.4.3
rm -f /usr/lib/libxvidcore.a
install -t /usr/share/licenses/xvidcore -Dm644 ../../LICENSE
cd ../../..
rm -rf xvidcore
# libaom.
tar -xf libaom-3.11.0.tar.gz
cd libaom-3.11.0
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=1 -DENABLE_DOCS=0 -DENABLE_TESTS=0 -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
rm -f /usr/lib/libaom.a
install -t /usr/share/licenses/libaom -Dm644 LICENSE PATENTS
cd ..
rm -rf libaom-3.11.0
# SVT-AV1.
tar -xf SVT-AV1-v2.3.0.tar.bz2
cd SVT-AV1-v2.3.0
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=1 -DNATIVE=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/svt-av1 -Dm644 {LICENSE{,-BSD2},PATENTS}.md
cd ..
rm -rf SVT-AV1-v2.3.0
# dav1d.
tar -xf dav1d-1.5.0.tar.bz2
cd dav1d-1.5.0
meson setup build --prefix=/usr --buildtype=minsize -Denable_tests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/dav1d -Dm644 COPYING
cd ..
rm -rf dav1d-1.5.0
# rav1e.
tar -xf rav1e-0.7.1.tar.gz
cd rav1e-0.7.1
cargo build --release
cargo cbuild --release
sed -i 's|/usr/local|/usr|' target/x86_64-unknown-linux-gnu/release/rav1e.pc
install -t /usr/bin -Dm755 target/release/rav1e
install -t /usr/include/rav1e -Dm644 target/x86_64-unknown-linux-gnu/release/include/rav1e/rav1e.h
install -t /usr/lib/pkgconfig -Dm644 target/x86_64-unknown-linux-gnu/release/rav1e.pc
install -Dm755 target/x86_64-unknown-linux-gnu/release/librav1e.so /usr/lib/librav1e.so.0.7.1
ln -sf librav1e.so.0.7.1 /usr/lib/librav1e.so.0
ln -sf librav1e.so.0.7.1 /usr/lib/librav1e.so
ldconfig
install -t /usr/share/licenses/rav1e -Dm644 LICENSE PATENTS
cd ..
rm -rf rav1e-0.7.1
# wavpack.
tar -xf wavpack-5.7.0.tar.xz
cd wavpack-5.7.0
./configure --prefix=/usr --disable-rpath --enable-legacy
make
make install
install -t /usr/share/licenses/wavpack -Dm644 COPYING
cd ..
rm -rf wavpack-5.7.0
# libudfread.
tar -xf libudfread-1.1.2.tar.bz2
cd libudfread-1.1.2
./bootstrap
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libudfread -Dm644 COPYING
cd ..
rm -rf libudfread-1.1.2
# libbluray.
tar -xf libbluray-1.3.4.tar.bz2
cd libbluray-1.3.4
./bootstrap
sed -i 's/with_external_libudfread=$withwal/with_external_libudfread=yes/' configure
./configure --prefix=/usr --disable-bdjava-jar --disable-examples --disable-static
make
make install
install -t /usr/share/licenses/libbluray -Dm644 COPYING
cd ..
rm -rf libbluray-1.3.4
# libmodplug.
tar -xf libmodplug-0.8.9.0.tar.gz
cd libmodplug-0.8.9.0
./configure --prefix=/usr --disable-static
make
make install
install -t /usr/share/licenses/libmodplug -Dm644 COPYING
cd ..
rm -rf libmodplug-0.8.9.0
# libmpeg2.
tar -xf libmpeg2-upstream-0.5.1.tar.gz
cd libmpeg2-upstream-0.5.1
sed -i 's/static const/static/' libmpeg2/idct_mmx.c
./configure --prefix=/usr --enable-shared --disable-static
find . -name Makefile -exec sed -i 's|-Wl,-rpath,/usr/lib||' {} ';'
make
make install
install -t /usr/share/licenses/libmpeg2 -Dm644 COPYING
cd ..
rm -rf libmpeg2-upstream-0.5.1
# libheif.
tar -xf libheif-1.19.5.tar.gz
cd libheif-1.19.5
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TESTING=OFF -DWITH_AOM_DECODER=ON -DWITH_AOM_ENCODER=ON -DWITH_DAV1D=ON -DWITH_JPEG_DECODER=ON -DWITH_JPEG_ENCODER=ON -DWITH_LIBDE265=ON -DWITH_OpenJPEG_DECODER=ON -DWITH_OpenJPEG_ENCODER=ON -DWITH_RAV1E=ON -DWITH_SvtEnc=ON -DWITH_X265=ON -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libheif -Dm644 COPYING
cd ..
rm -rf libheif-1.19.5
# libavif.
tar -xf libavif-1.1.1.tar.gz
cd libavif-1.1.1
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DAVIF_BUILD_APPS=ON -DAVIF_BUILD_GDK_PIXBUF=ON -DAVIF_CODEC_AOM=SYSTEM -DAVIF_CODEC_SVT=SYSTEM -DAVIF_CODEC_DAV1D=SYSTEM -DAVIF_CODEC_RAV1E=SYSTEM -DAVIF_LIBYUV=LOCAL -DAVIF_ENABLE_WERROR=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libavif -Dm644 LICENSE
cd ..
rm -rf libavif-1.1.1
# chafa.
tar -xf chafa-1.14.5.tar.xz
cd chafa-1.14.5
./configure --prefix=/usr --enable-gtk-doc --enable-man --disable-static
make
make install
install -t /usr/share/licenses/chafa -Dm644 COPYING{,.LESSER}
cd ..
rm -rf chafa-1.14.5
# HarfBuzz (rebuild again to support chafa).
tar -xf harfbuzz-10.2.0.tar.xz
cd harfbuzz-10.2.0
meson setup build --prefix=/usr --buildtype=minsize -Dgraphite2=enabled -Dtests=disabled
ninja -C build
ninja -C build install
cd ..
rm -rf harfbuzz-10.2.0
# FAAC.
tar -xf faac-1_30.tar.gz
cd faac-1_30
patch -Np1 -i ../patches/faac-1.30-pkgconfig.patch
autoreconf -fi
./configure --prefix=/usr --enable-shared --disable-static
make
make install
install -t /usr/share/licenses/faac -Dm644 COPYING README
cd ..
rm -rf faac-1_30
# FAAD2.
tar -xf faad2-2.11.1.tar.gz
cd faad2-2.11.1
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/faad2 -Dm644 COPYING
cd ..
rm -rf faad2-2.11.1
# FFmpeg.
tar -xf ffmpeg-7.1.tar.xz
cd ffmpeg-7.1
patch -Np1 -i ../patches/ffmpeg-7.1-chromium.patch
sed -i 's/X265_BUILD >= 210/(&) \&\& (X265_BUILD < 213)/' libavcodec/libx265.c
./configure --prefix=/usr --disable-debug --disable-htmlpages --disable-nonfree --disable-static --enable-alsa --enable-bzlib --enable-gmp --enable-gpl --enable-iconv --enable-libaom --enable-libass --enable-libbluray --enable-libbs2b --enable-libcdio --enable-libdav1d --enable-libdrm --enable-libfontconfig --enable-libfreetype --enable-libfribidi --enable-libiec61883 --enable-libjack --enable-libmodplug --enable-libmp3lame --enable-libopenh264 --enable-libopenjpeg --enable-libopus --enable-libpulse --enable-librav1e --enable-librsvg --enable-librtmp --enable-libshaderc --enable-libspeex --enable-libsvtav1 --enable-libtheora --enable-libtwolame --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxcb --enable-libxcb-shape --enable-libxcb-shm --enable-libxcb-xfixes --enable-libxml2 --enable-libxvid --enable-manpages --enable-opengl --enable-openssl --enable-optimizations --enable-sdl2 --enable-shared --enable-small --enable-stripping --enable-vaapi --enable-vdpau --enable-version3 --enable-vulkan --enable-xlib --enable-zlib
make
gcc $CFLAGS tools/qt-faststart.c -o tools/qt-faststart $LDFLAGS
make install
install -t /usr/bin -Dm755 tools/qt-faststart
install -t /usr/share/licenses/ffmpeg -Dm644 COPYING.GPLv2 COPYING.GPLv3 COPYING.LGPLv2.1 COPYING.LGPLv3 LICENSE.md
cd ..
rm -rf ffmpeg-7.1
# OpenAL.
tar -xf openal-soft-1.24.1.tar.gz
cd openal-soft-1.24.1
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DALSOFT_EXAMPLES=OFF -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -t /usr/share/licenses/openal -Dm644 COPYING BSD-3Clause
cd ..
rm -rf openal-soft-1.24.1
# GStreamer / gst-plugins-{base,good,bad,ugly} / gst-libav / gstreamer-vaapi / gst-editing-services / gst-python
tar -xf gstreamer-1.24.11.tar.bz2
cd gstreamer-1.24.11
meson setup build --prefix=/usr --buildtype=minsize -Ddevtools=disabled -Dexamples=disabled -Dglib-asserts=disabled -Dglib-checks=disabled -Dgobject-cast-checks=disabled -Dgpl=enabled -Dgst-examples=disabled -Dlibnice=disabled -Dorc-source=system -Dpackage-name="MassOS GStreamer 1.24.11" -Dpackage-origin="https://massos.org" -Drtsp_server=disabled -Dtests=disabled -Dvaapi=enabled -Dgst-plugins-bad:aja=disabled -Dgst-plugins-bad:avtp=disabled -Dgst-plugins-bad:fdkaac=disabled -Dgst-plugins-bad:gpl=enabled -Dgst-plugins-bad:iqa=disabled -Dgst-plugins-bad:srtp=disabled -Dgst-plugins-bad:tinyalsa=disabled -Dgst-plugins-ugly:gpl=enabled
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gstreamer -Dm644 LICENSE
install -t /usr/share/licenses/gst-plugins-base -Dm644 subprojects/gst-plugins-base/COPYING
install -t /usr/share/licenses/gst-plugins-good -Dm644 subprojects/gst-plugins-good/COPYING
install -t /usr/share/licenses/gst-plugins-bad -Dm644 subprojects/gst-plugins-bad/COPYING
install -t /usr/share/licenses/gst-plugins-ugly -Dm644 subprojects/gst-plugins-ugly/COPYING
install -t /usr/share/licenses/gst-libav -Dm644 subprojects/gst-libav/COPYING
install -t /usr/share/licenses/gstreamer-vaapi -Dm644 subprojects/gstreamer-vaapi/COPYING.LIB
install -t /usr/share/licenses/gst-editing-services -Dm644 subprojects/gst-editing-services/COPYING{,.LIB}
install -t /usr/share/licenses/gst-python -Dm644 subprojects/gst-python/COPYING
cd ..
rm -rf gstreamer-1.24.11.tar.bz2
# PipeWire + WirePlumber.
tar -xf pipewire-1.2.7.tar.bz2
cd pipewire-1.2.7
mkdir -p subprojects/wireplumber
tar -xf ../wireplumber-0.5.7.tar.bz2 -C subprojects/wireplumber --strip-components=1
meson setup build --prefix=/usr --buildtype=minsize -Dbluez5-backend-native-mm=enabled -Dexamples=disabled -Dffmpeg=enabled -Dpw-cat-ffmpeg=enabled -Dtests=disabled -Dvulkan=enabled -Dsession-managers=wireplumber -Dwireplumber:system-lua=true -Dwireplumber:tests=false
ninja -C build
ninja -C build install
systemctl --global enable pipewire.socket pipewire-pulse.socket
systemctl --global enable wireplumber
echo "autospawn = no" >> /etc/pulse/client.conf
install -t /usr/share/licenses/pipewire -Dm644 COPYING
install -t /usr/share/licenses/wireplumber -Dm644 subprojects/wireplumber/LICENSE
cd ..
rm -rf pipewire-1.2.7
# xdg-desktop-portal.
tar -xf xdg-desktop-portal-1.18.4.tar.xz
cd xdg-desktop-portal-1.18.4
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/xdg-desktop-portal -Dm644 COPYING
cd ..
rm -rf xdg-desktop-portal-1.18,4
# xdg-desktop-portal-gtk.
tar -xf xdg-desktop-portal-gtk-1.15.2.tar.xz
cd xdg-desktop-portal-gtk-1.15.2
meson setup build --prefix=/usr --buildtype=minsize -Dappchooser=enabled -Dlockdown=enabled -Dsettings=enabled -Dwallpaper=disabled
ninja -C build
ninja -C build install
cat > /etc/xdg/autostart/xdg-desktop-portal-gtk.desktop << "END"
[Desktop Entry]
Type=Application
Name=Portal service (GTK/GNOME implementation)
Exec=/bin/bash -c "dbus-update-activation-environment --systemd DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY; systemctl start --user xdg-desktop-portal-gtk.service"
END
install -t /usr/share/licenses/xdg-desktop-portal-gtk -Dm644 COPYING
cd ..
rm -rf xdg-desktop-portal-gtk-1.15.2
# WebKitGTK.
tar -xf webkitgtk-2.46.5.tar.xz
cd webkitgtk-2.46.5
sed -i '/U_SHOW_CPLUSPLUS_API/a#define U_SHOW_CPLUSPLUS_HEADER_API 0' Source/WTF/wtf/Platform.h
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_SKIP_RPATH=ON -DPORT=GTK -DLIB_INSTALL_DIR=/usr/lib -DENABLE_BUBBLEWRAP_SANDBOX=ON -DENABLE_GAMEPAD=OFF -DENABLE_MINIBROWSER=ON -DUSE_AVIF=ON -DUSE_GTK4=OFF -DUSE_JPEGXL=OFF -DUSE_LIBBACKTRACE=OFF -DUSE_LIBHYPHEN=OFF -DUSE_WOFF2=ON -Wno-dev -G Ninja -B build
ninja -C build
ninja -C build install
install -dm755 /usr/share/licenses/webkitgtk
find Source -name 'COPYING*' -or -name 'LICENSE*' -print0 | sort -z | while IFS= read -d $'\0' -r _f; do echo "### $_f ###"; cat "$_f"; echo; done > /usr/share/licenses/webkitgtk/LICENSE
cd ..
rm -rf webkitgtk-2.46.5
# Cogl.
tar -xf cogl-1.22.8.tar.xz
cd cogl-1.22.8
CFLAGS="$CFLAGS -Wno-error=implicit-function-declaration" ./configure --prefix=/usr --enable-gles1 --enable-gles2 --enable-kms-egl-platform --enable-wayland-egl-platform --enable-xlib-egl-platform --enable-wayland-egl-server --enable-cogl-gst
make -j1
make -j1 install
install -t /usr/share/licenses/cogl -Dm644 COPYING
cd ..
rm -rf cogl-1.22.8
# Clutter.
tar -xf clutter-1.26.4.tar.xz
cd clutter-1.26.4
./configure --prefix=/usr --sysconfdir=/etc --enable-egl-backend --enable-evdev-input --enable-wayland-backend --enable-wayland-compositor
make
make install
install -t /usr/share/licenses/clutter -Dm644 COPYING
cd ..
rm -rf clutter-1.26.4
# Clutter-GTK.
tar -xf clutter-gtk-1.8.4.tar.xz
cd clutter-gtk-1.8.4
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/clutter-gtk -Dm644 COPYING
cd ..
rm -rf clutter-gtk-1.8.4
# Clutter-GST.
tar -xf clutter-gst-3.0.27.tar.xz
cd clutter-gst-3.0.27
CFLAGS="$CFLAGS -Wno-error=implicit-function-declaration -Wno-error=int-conversion" ./configure --prefix=/usr --sysconfdir=/etc --disable-debug
make
make install
install -t /usr/share/licenses/clutter-gst -Dm644 COPYING
cd ..
rm -rf clutter-gst-3.0.27
# libchamplain.
tar -xf libchamplain-0.12.21.tar.xz
cd libchamplain-0.12.21
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libchamplain -Dm644 COPYING
cd ..
rm -rf libchamplain-0.12.21
# gspell.
tar -xf gspell-1.14.0.tar.xz
cd gspell-1.14.0
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gspell -Dm644 LICENSES/LGPL-2.1-or-later.txt
cd ..
rm -rf gspell-1.14.0
# gnome-online-accounts.
tar -xf gnome-online-accounts-3.48.3.tar.xz
cd gnome-online-accounts-3.48.3
meson setup build --prefix=/usr --buildtype=minsize -Dfedora=false -Dman=true -Dmedia_server=true
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gnome-online-accounts -Dm644 COPYING
cd ..
rm -rf gnome-online-accounts-3.48.3
# libgdata.
tar -xf libgdata-0.18.1.tar.xz
cd libgdata-0.18.1
meson setup build --prefix=/usr --buildtype=minsize -Dalways_build_tests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/libgdata -Dm644 COPYING
cd ..
rm -rf libgdata-0.18.1
# gtksourceview3.
tar -xf gtksourceview-3.24.11-28-g73e57b5.tar.gz
cd gtksourceview-73e57b5787ac60776c57032e05a4cc32207f9cf6
find . -type f -name Makefile.am -exec sed -i '/@CODE_COVERAGE_RULES@/d' {} ';'
CFLAGS="$CFLAGS -Wno-error=incompatible-pointer-types" ./autogen.sh --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static --disable-glade-catalog
make
make install
install -t /usr/share/licenses/gtksourceview3 -Dm644 COPYING
cd ..
rm -rf gtksourceview-73e57b5787ac60776c57032e05a4cc32207f9cf6
# gtksourceview4.
tar -xf gtksourceview-4.8.4.tar.xz
cd gtksourceview-4.8.4
meson setup build --prefix=/usr --buildtype=minsize
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gtksourceview4 -Dm644 COPYING
cd ..
rm -rf gtksourceview-4.8.4
# yad.
tar -xf yad-14.1.tar.xz
cd yad-14.1
./configure --prefix=/usr
make
make install
install -t /usr/share/licenses/yad -Dm644 COPYING
cd ..
rm -rf yad-14.1
# msgraph.
tar -xf msgraph-0.2.3.tar.gz
cd msgraph-0.2.3
meson setup build --prefix=/usr --buildtype=minsize -Dtests=false
ninja -C build
ninja -C build install
install -t /usr/share/licenses/msgraph -Dm644 COPYING
cd ..
rm -rf msgraph-0.2.3
# GVFS.
tar -xf gvfs-1.56.1.tar.xz
cd gvfs-1.56.1
meson setup build --prefix=/usr --buildtype=minsize -Dburn=true -Dman=true
ninja -C build
ninja -C build install
install -t /usr/share/licenses/gvfs -Dm644 COPYING
cd ..
rm -rf gvfs-1.56.1
# gPlanarity.
tar -xf gplanarity_17906.orig.tar.gz
cd gplanarity-17906
patch -Np1 -i ../patches/gplanarity-17906-fixes.patch
make
make PREFIX=/usr install
install -t /usr/share/licenses/gplanarity -Dm644 COPYING
cd ..
rm -rf gplanarity-17906
# Plymouth.
tar -xf plymouth-24.004.60.tar.bz2
cd plymouth-24.004.60
meson setup build --prefix=/usr --buildtype=minsize -Dlogo=/usr/share/massos/massos-logo-sidetext.png -Drelease-file=/etc/os-release
ninja -C build
ninja -C build install
sed -i 's/dracut -f/mkinitramfs/' /usr/libexec/plymouth/plymouth-update-initrd
sed -i 's/WatermarkVerticalAlignment=.96/WatermarkVerticalAlignment=.5/' /usr/share/plymouth/themes/spinner/spinner.plymouth
cp /usr/share/massos/massos-logo-sidetext.png /usr/share/plymouth/themes/spinner/watermark.png
plymouth-set-default-theme bgrt
install -t /usr/share/licenses/plymouth -Dm644 COPYING
cd ..
rm -rf plymouth-24.004.60
# Busybox.
tar -xf busybox-1.37.0.tar.bz2
cd busybox-1.37.0
patch -Np1 -i ../patches/busybox-1.37.0-linuxheaders68.patch
cp ../busybox-config .config
make
install -t /usr/bin -Dm755 busybox
install -t /usr/share/licenses/busybox -Dm644 LICENSE
cd ..
rm -rf busybox-1.37.0
# Linux Kernel.
tar -xf linux-6.12.10.tar.xz
cd linux-6.12.10
make mrproper
cp ../kernel-config .config
make olddefconfig
make
make INSTALL_MOD_PATH=/usr INSTALL_MOD_STRIP=1 modules_install
KREL=$(make -s kernelrelease)
cp arch/x86/boot/bzImage /boot/vmlinuz-$KREL
cp arch/x86/boot/bzImage /usr/lib/modules/$KREL/vmlinuz
cp System.map /boot/System.map-$KREL
cp .config /boot/config-$KREL
rm -f /usr/lib/modules/$KREL/{source,build}
echo $KREL > version
builddir=/usr/lib/modules/$KREL/build
install -t "$builddir" -Dm644 .config Makefile Module.symvers System.map version vmlinux
install -t "$builddir/kernel" -Dm644 kernel/Makefile
install -t "$builddir/arch/x86" -Dm644 arch/x86/Makefile
cp -t "$builddir" -a scripts
install -Dt "$builddir/tools/objtool" tools/objtool/objtool
mkdir -p "$builddir"/{fs/xfs,mm}
cp -t "$builddir" -a include
cp -t "$builddir/arch/x86" -a arch/x86/include
install -t "$builddir/arch/x86/kernel" -Dm644 arch/x86/kernel/asm-offsets.s
install -t "$builddir/drivers/md" -Dm644 drivers/md/*.h
install -t "$builddir/net/mac80211" -Dm644 net/mac80211/*.h
install -t "$builddir/drivers/media/i2c" -Dm644 drivers/media/i2c/msp3400-driver.h
install -t "$builddir/drivers/media/usb/dvb-usb" -Dm644 drivers/media/usb/dvb-usb/*.h
install -t "$builddir/drivers/media/dvb-frontends" -Dm644 drivers/media/dvb-frontends/*.h
install -t "$builddir/drivers/media/tuners" -Dm644 drivers/media/tuners/*.h
install -t "$builddir/drivers/iio/common/hid-sensors" -Dm644 drivers/iio/common/hid-sensors/*.h
find . -name 'Kconfig*' -exec install -Dm644 {} "$builddir/{}" ';'
rm -rf "$builddir/Documentation"
find -L "$builddir" -type l -delete
find "$builddir" -type f -name '*.o' -delete
ln -sr "$builddir" "/usr/src/linux"
install -t /usr/share/licenses/linux -Dm644 COPYING LICENSES/exceptions/* LICENSES/preferred/*
cd ..
rm -rf linux-6.12.10
unset builddir
# NVIDIA Open Kernel Modules.
tar -xf open-gpu-kernel-modules-565.77.tar.gz
cd open-gpu-kernel-modules-565.77
patch -Np1 -i ../patches/nvidia-open-kernel-modules-565.57.01-fix.patch
make CC=gcc SYSSRC=/usr/src/linux
install -t /usr/lib/modules/$KREL/extramodules -Dm644 kernel-open/*.ko
strip --strip-debug /usr/lib/modules/$KREL/extramodules/*.ko
for i in /usr/lib/modules/$KREL/extramodules/*.ko; do xz --threads=$(nproc) "$i"; done
echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" > /usr/lib/modprobe.d/nvidia.conf
depmod $KREL
install -t /usr/share/licenses/nvidia-open-kernel-modules -Dm644 COPYING
cd ..
rm -rf open-gpu-kernel-modules-565.77
unset KREL
# MassOS release detection utility.
gcc $CFLAGS massos-release.c -o massos-release
install -t /usr/bin -Dm755 massos-release
# Determine the version of osinstallgui that should be used by the Live CD.
echo "0.2.3" > /usr/share/massos/.osinstallguiver
# Determine firmware versions that should be installed.
cat > /usr/share/massos/firmwareversions << "END"
# DO NOT EDIT THIS FILE!

# This file defines the firmware versions corresponding to this MassOS build.
# Firmware is not included in the rootfs image; only in the Live CD ISO.
# The ISO creator will use this file to know what firmware versions to install.

# Eventually, a utility called 'massos-firmware' will be created, to allow
# installing/uninstalling firmware on the fly. If you are reading this, chances
# are it already exists. In any case, it will also reference this file.

linux-firmware: 20241110
intel-microcode: 20241112
sof-firmware: 2024.09.2
END
# snapd version, for when the snapd installation program is finally written.
cat > /usr/share/massos/snapdversion << "END"
# DO NOT EDIT THIS FILE!

# This file defines the version of snapd corresponding to this MassOS build.
# snapd is not installed by default due to its controversy.
# But we still want to offer it, as it provides some packages not in Flatpak.

# Eventually, a utility called 'massos-snapd' will be created, to allow
# installing snapd and uninstalling it. It will need to reference to this file
# to know which version of snapd to install.

# The snapd version, see <https://github.com/canonical/snapd/releases>.
version: 2.66.1

# Whether or not snapd is installed ('massos-snapd' sets this automatically).
installed: no
END
# Clean sources directory and self destruct.
cd ..
rm -rf /sources
