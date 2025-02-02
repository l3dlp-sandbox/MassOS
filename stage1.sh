#!/bin/bash
#
# Build the environment which will be used to build the full OS later.
set -e
# Disabling hashing is useful so the newly built tools are detected.
set +h
# Ensure retrieve-sources.sh has been run first.
if [ ! -d sources ]; then
  echo "Error: You must run retrieve-sources.sh first!" >&2
  exit 1
fi
# Starting message.
echo "Starting Stage 1 Build..."
# Setup the environment.
LC_ALL=C
MASSOS="$PWD"/massos-rootfs
PATH="$MASSOS"/tools/bin:$PATH
CONFIG_SITE="$MASSOS"/usr/share/config.site
export LC_ALL MASSOS MASSOS_TARGET PATH CONFIG_SITE
# Build in parallel using all available CPU cores.
export MAKEFLAGS="-j$(nproc)"
# Compiler flags for MassOS. We prefer to optimise for size.
CFLAGS="-Os"
CXXFLAGS="-Os"
CPPFLAGS=""
LDFLAGS=""
export CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
# Setup the basic filesystem structure.
mkdir -p "$MASSOS"/{etc,usr/{bin,lib},var}
# Ensure the filesystem structure uses unified usr and merged bin-sbin.
ln -sf usr/bin "$MASSOS"/bin
ln -sf bin "$MASSOS"/usr/sbin
ln -sf usr/bin "$MASSOS"/sbin
ln -sf usr/lib "$MASSOS"/lib
ln -sf lib "$MASSOS"/usr/lib64
ln -sf usr/lib "$MASSOS"/lib64
# Move sources into the temporary environment.
mv sources "$MASSOS"
# Copy patches into the temporary environment.
cp -r patches "$MASSOS"/sources
# Copy systemd units into the temporary environment.
cp -r utils/systemd-units "$MASSOS"/sources
# Temporary toolchain directory.
mkdir "$MASSOS"/tools
# Change to the sources directory.
cd "$MASSOS"/sources
# Binutils (Initial build for bootstrapping).
tar -xf binutils-2.43.1.tar.xz
cd binutils-2.43.1
mkdir -p build; cd build
CFLAGS="-O2" CXXFLAGS="-O2" ../configure --prefix="$MASSOS"/tools --with-sysroot="$MASSOS" --target=x86_64-stage1-linux-gnu --with-pkgversion="MassOS Binutils 2.43.1" --enable-default-hash-style=gnu --enable-new-dtags --enable-relro --disable-gprofng --disable-nls --disable-werror
make
make -j1 install
cd ../..
rm -rf binutils-2.43.1
# GCC (Initial build for bootstrapping).
tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0
mkdir -p gmp mpfr mpc isl
tar -xf ../gmp-6.3.0.tar.xz -C gmp --strip-components=1
tar -xf ../mpfr-4.2.1.tar.xz -C mpfr --strip-components=1
tar -xf ../mpc-1.3.1.tar.gz -C mpc --strip-components=1
tar -xf ../isl-0.27.tar.xz -C isl --strip-components=1
sed -i '/m64=/s/lib64/lib/' gcc/config/i386/t-linux64
mkdir -p build; cd build
CFLAGS="-O2" CXXFLAGS="-O2" ../configure --prefix="$MASSOS"/tools --with-sysroot="$MASSOS" --target=x86_64-stage1-linux-gnu --with-pkgversion="MassOS GCC 14.2.0" --with-glibc-version=2.40 --with-newlib --without-headers --enable-languages=c,c++ --enable-default-pie --enable-default-ssp --enable-linker-build-id --disable-libatomic --disable-libgomp --disable-libquadmath --disable-libssp --disable-libstdcxx --disable-libvtv --disable-multilib --disable-nls --disable-shared --disable-threads
make
make install
cat ../gcc/{limitx,glimits,limity}.h > "$MASSOS"/tools/lib/gcc/x86_64-stage1-linux-gnu/14.2.0/install-tools/include/limits.h
cd ../..
rm -rf gcc-14.2.0
# Linux API Headers.
tar -xf linux-6.13.1.tar.xz
cd linux-6.13.1
make mrproper
make headers
find usr/include -type f -not -name '*.h' -delete
cp -r usr/include "$MASSOS"/usr
cd ..
rm -rf linux-6.13.1
# Glibc.
tar -xf glibc-2.40.tar.xz
cd glibc-2.40
patch -Np1 -i ../patches/glibc-2.40-vardirectories.patch
mkdir -p build; cd build
echo "rootsbindir=/usr/bin" > configparms
CFLAGS="-O2" CXXFLAGS="-O2" ../configure --prefix=/usr --host=x86_64-stage1-linux-gnu --build=$(../scripts/config.guess) --with-pkgversion="MassOS Glibc 2.40" --with-headers="$MASSOS"/usr/include --enable-kernel=4.19 --disable-nscd --disable-werror libc_cv_slibdir=/usr/lib
make
make DESTDIR="$MASSOS" install
ln -sf ld-linux-x86-64.so.2 "$MASSOS"/usr/lib/ld-lsb-x86-64.so.3
sed -i '/RTLDLIST=/s@/usr@@g' "$MASSOS"/usr/bin/ldd
cd ../..
rm -rf glibc-2.40
# libstdc++ from GCC (Could not be built with bootstrap GCC).
tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0
mkdir -p build; cd build
CFLAGS="-O2" CXXFLAGS="-O2" ../libstdc++-v3/configure --prefix=/usr --host=x86_64-stage1-linux-gnu --build=$(../config.guess) --disable-multilib --disable-nls --disable-libstdcxx-pch --with-gxx-include-dir=/tools/x86_64-stage1-linux-gnu/include/c++/14.2.0
make
make DESTDIR="$MASSOS" install
rm -f "$MASSOS"/usr/lib/lib{stdc++{,exp,fs},supc++}.la
cd ../..
rm -rf gcc-14.2.0
# m4.
tar -xf m4-1.4.19.tar.xz
cd m4-1.4.19
CFLAGS="$CFLAGS -DMB_LEN_MAX=16 -DPATH_MAX=4096" ./configure --prefix=/usr --host=x86_64-stage1-linux-gnu --build=$(build-aux/config.guess)
make
make DESTDIR="$MASSOS" install
cd ..
rm -rf m4-1.4.19
# Ncurses.
tar -xf ncurses-6.5.tar.gz
cd ncurses-6.5
mkdir -p build; cd build
../configure AWK=gawk
make -C include
make -C progs tic
cd ..
./configure AWK=gawk --prefix=/usr --host=x86_64-stage1-linux-gnu --build=$(./config.guess) --mandir=/usr/share/man --with-cxx-shared --with-manpage-format=normal --with-shared --without-ada --without-debug --without-normal --enable-widec --disable-stripping
make
make DESTDIR="$MASSOS" TIC_PATH="$PWD"/build/progs/tic install
ln -sf libncursesw.so "$MASSOS"/usr/lib/libncurses.so
sed -i 's/^#if.*XOPEN.*$/#if 1/' "$MASSOS"/usr/include/curses.h
cd ..
rm -rf ncurses-6.5
# Bash.
tar -xf bash-5.2.37.tar.gz
cd bash-5.2.37
./configure --prefix=/usr --host=x86_64-stage1-linux-gnu --build=$(support/config.guess) --without-bash-malloc
make
make DESTDIR="$MASSOS" install
ln -sf bash "$MASSOS"/bin/sh
cd ..
rm -rf bash-5.2.37
# Binutils (For stage 2, built using our new bootstrap toolchain).
tar -xf binutils-2.43.1.tar.xz
cd binutils-2.43.1
sed -i '6009s/$add_dir//' ltmain.sh
mkdir -p build; cd build
CFLAGS="-O2" CXXFLAGS="-O2" ../configure --prefix=/usr --host=x86_64-stage1-linux-gnu --build=$(../config.guess) --with-pkgversion="MassOS Binutils 2.43.1" --enable-64-bit-bfd --enable-default-hash-style=gnu --enable-new-dtags --enable-relro --enable-shared --disable-gprofng --disable-nls --disable-werror
make
make -j1 DESTDIR="$MASSOS" install
rm -f "$MASSOS"/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{l,}a
cd ../..
rm -rf binutils-2.43.1
# GCC (For stage 2, built using our new bootstrap toolchain).
tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0
mkdir -p gmp mpfr mpc isl
tar -xf ../gmp-6.3.0.tar.xz -C gmp --strip-components=1
tar -xf ../mpfr-4.2.1.tar.xz -C mpfr --strip-components=1
tar -xf ../mpc-1.3.1.tar.gz -C mpc --strip-components=1
tar -xf ../isl-0.27.tar.xz -C isl --strip-components=1
sed -i '/m64=/s/lib64/lib/' gcc/config/i386/t-linux64
sed -i '/thread_header =/s/@.*@/gthr-posix.h/' libgcc/Makefile.in libstdc++-v3/include/Makefile.in
mkdir -p build; cd build
CFLAGS="-O2" CXXFLAGS="-O2" ../configure --prefix=/usr --host=x86_64-stage1-linux-gnu --build=$(../config.guess) --target=x86_64-stage1-linux-gnu LDFLAGS_FOR_TARGET=-L"$PWD/x86_64-stage1-linux-gnu/libgcc" --with-build-sysroot="$MASSOS" --enable-languages=c,c++ --with-pkgversion="MassOS GCC 14.2.0" --enable-default-pie --enable-default-ssp --enable-linker-build-id --disable-nls --disable-multilib --disable-libatomic --disable-libgomp --disable-libquadmath --disable-libsanitizer --disable-libssp --disable-libvtv
make
make DESTDIR="$MASSOS" install
ln -sf gcc "$MASSOS"/usr/bin/cc
cd ../..
rm -rf gcc-14.2.0
# Install upgrade-toolset to provide basic utilities for the start of stage 2.
mv "${MASSOS}"/usr/bin/bash{,.save}
mv "${MASSOS}"/usr/bin/m4{,.save}
tar -xf upgrade-toolset-20221015-x86_64.tar.xz -C "$MASSOS"/usr/bin --strip-components=1
mv "${MASSOS}"/usr/bin/bash{.save,}
mv "${MASSOS}"/usr/bin/m4{.save,}
rm -f "$MASSOS"/usr/bin/LICENSE*
cd ../..
# Remove bootstrap toolchain directory.
rm -rf "$MASSOS"/tools
# Remove temporary system documentation.
rm -rf "$MASSOS"/usr/share/{info,man,doc}/*
# Copy extra utilities and configuration files into the environment.
cp -r utils/etc/* "$MASSOS"/etc
mv "$MASSOS"/etc/{lsb,os}-release "$MASSOS"/usr/lib
cp utils/massos-release "$MASSOS"/usr/lib
ln -sfr "$MASSOS"/usr/lib/massos-release "$MASSOS"/etc/massos-release
ln -sfr "$MASSOS"/usr/lib/os-release "$MASSOS"/etc/os-release
ln -sfr "$MASSOS"/usr/lib/lsb-release "$MASSOS"/etc/lsb-release
cp utils/programs/{adduser,mass-chroot,mkinitramfs,mklocales,{un,}zman} "$MASSOS"/usr/bin
cp utils/programs/massos-release.c "$MASSOS"/sources
cp -r utils/build-configs/* "$MASSOS"/sources
cp -r logo/* "$MASSOS"/sources
cp utils/builtins "$MASSOS"/sources
cp -r utils/extra-package-licenses "$MASSOS"/sources
cp -r backgrounds "$MASSOS"/sources
cp -r utils/man "$MASSOS"/sources
cp LICENSE "$MASSOS"/sources
cp build-system.sh build.env "$MASSOS"/sources
# If it is an "experimental" build, then date its release.
sed -i "s|experimental|experimental-$(date "+%Y%m%d")|g" "$MASSOS"/usr/lib/massos-release
sed -i "s|experimental|experimental-$(date "+%Y%m%d")|g" "$MASSOS"/usr/lib/os-release
sed -i "s|experimental|experimental-$(date "+%Y%m%d")|g" "$MASSOS"/usr/lib/lsb-release
# Finishing message.
echo -e "\nThe Stage 1 bootstrap system was built successfully."
echo "To build the full MassOS system, now run './stage2.sh' AS ROOT."
# Send a notification to the system if supported.
if notify-send --version &>/dev/null; then
  notify-send -i "$PWD"/logo/massos-logo.png "MassOS Build System" "The Stage 1 build has finished successfully." &>/dev/null || true
fi
