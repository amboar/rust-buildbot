#!/bin/bash

set -ex

ARCH=$1
BINUTILS=2.25.1
GCC=5.3.0

mkdir binutils
cd binutils

# First up, build binutils
curl https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS.tar.bz2 | tar xjf -
mkdir binutils-build
cd binutils-build
../binutils-$BINUTILS/configure \
  --target=$ARCH-unknown-freebsd10
make -j10
make install
cd ../..
rm -rf binutils

# Next, download the FreeBSD libc and relevant header files

mkdir freebsd
case "$ARCH" in
    x86_64)
        URL=ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/10.2-RELEASE/base.txz
        ;;
    i686)
        URL=ftp://ftp.freebsd.org/pub/FreeBSD/releases/i386/10.2-RELEASE/base.txz
        ;;
esac
curl $URL | tar xJf - -C freebsd ./usr/include ./usr/lib ./lib

dst=/usr/local/$ARCH-unknown-freebsd10

cp -r freebsd/usr/include $dst/
cp freebsd/usr/lib/crt1.o $dst/lib
cp freebsd/usr/lib/Scrt1.o $dst/lib
cp freebsd/usr/lib/crti.o $dst/lib
cp freebsd/usr/lib/crtn.o $dst/lib
cp freebsd/usr/lib/libc.a $dst/lib
cp freebsd/usr/lib/libutil.a $dst/lib
cp freebsd/usr/lib/libutil_p.a $dst/lib
cp freebsd/usr/lib/libm.a $dst/lib
cp freebsd/usr/lib/librt.so.1 $dst/lib
cp freebsd/usr/lib/libexecinfo.so.1 $dst/lib
cp freebsd/lib/libc.so.7 $dst/lib
cp freebsd/lib/libm.so.5 $dst/lib
cp freebsd/lib/libutil.so.9 $dst/lib
cp freebsd/lib/libthr.so.3 $dst/lib/libpthread.so

ln -s libc.so.7 $dst/lib/libc.so
ln -s libm.so.5 $dst/lib/libm.so
ln -s librt.so.1 $dst/lib/librt.so
ln -s libutil.so.9 $dst/lib/libutil.so
ln -s libexecinfo.so.1 $dst/lib/libexecinfo.so
rm -rf freebsd

# Finally, download and build gcc to target FreeBSD
mkdir gcc
cd gcc
curl https://ftp.gnu.org/gnu/gcc/gcc-$GCC/gcc-$GCC.tar.bz2 | tar xjf -
cd gcc-$GCC
./contrib/download_prerequisites

mkdir ../gcc-build
cd ../gcc-build
../gcc-$GCC/configure                            \
  --enable-languages=c,c++                       \
  --target=$ARCH-unknown-freebsd10               \
  --disable-multilib                             \
  --disable-nls                                  \
  --disable-libgomp                              \
  --disable-libquadmath                          \
  --disable-libssp                               \
  --disable-libvtv                               \
  --disable-libcilkrts                           \
  --disable-libada                               \
  --disable-libsanitizer                         \
  --disable-libquadmath-support                  \
  --disable-lto
make -j10
make install
cd ../..
rm -rf gcc
