#! /bin/bash

GMP_VERSION=6.2.1
MPFR_VERSION=4.1.0
MPC_VERSION=1.2.1
BINUTILS_VERSION=2.32
GCC_VERSION=7.3.0
GLIBC_VERSION=2.31
GLIBC_PORTS_VERSION=2.16.0
GLIBC_LINUXTHREADS_VERSION=2.5
LINUX_VERSION=4.19.192
TARGET_ARCH=arm

PREFIX=/opt/arm-gcc-$GCC_VERSION
# TARGET 即为交叉编译链
# 需要将指定的arm交叉编译链路径添加到环境变量PATH中
TARGET=arm-linux-gnueabihf
BASE=`pwd`
PWD=$BASE

# 编译gmp
cd $BASE
echo "compiling gmp..."
if [ -d gmp-$GMP_VERSION ]; then
	rm -rf gmp-$GMP_VERSION/
fi
tar -xf gmp-$GMP_VERSION.tar.xz
cd gmp-$GMP_VERSION
mkdir build
cd build
../configure --prefix=$PREFIX --host=$TARGET CFLAGS=-I$PREFIX/include LDFLAGS=-L$PREFIX/lib
make -j4 && make install
echo "compiling gmp...done"

# 编译mpfr
cd $BASE
echo "compiling mpfr..."
if [ -d mpfr-$MPFR_VERSION ]; then
	rm -rf mpfr-$MPFR_VERSION/
fi
tar -xf mpfr-$MPFR_VERSION.tar.xz
cd mpfr-$MPFR_VERSION
mkdir build
cd build
../configure --prefix=$PREFIX --host=$TARGET CFLAGS=-I$PREFIX/include LDFLAGS=-L$PREFIX/lib
make -j4 && make install
echo "compiling mpfr...done"

# 编译mpc
cd $BASE
echo "compiling mpc..."
if [ -d mpc-$MPC_VERSION ]; then
	rm -rf mpc-$MPC_VERSION/
fi
tar -xf mpc-$MPC_VERSION.tar.gz
cd mpc-$MPC_VERSION
mkdir build
cd build
../configure --prefix=$PREFIX --host=$TARGET CFLAGS=-I$PREFIX/include LDFLAGS=-L$PREFIX/lib
make -j4 && make install
echo "compiling mpc...done"

# 安装内核头文件
cd $BASE
echo "installing linux header files"
if [ ! -d linux-$LINUX_VERSION ]; then
	tar -xf linux-$LINUX_VERSION.tar.xz
fi
cd linux-$LINUX_VERSION/
make headers_install ARCH=$TARGET_ARCH INSTALL_HDR_PATH=$PREFIX
echo "installing linux header files done"

# 编译binutils
cd $BASE
echo "compiling binutils..."
if [ -d binutils-$BINUTILS_VERSION ]; then
	rm -rf binutils-$BINUTILS_VERSION/
fi
tar -xf binutils-$BINUTILS_VERSION.tar.xz
cd binutils-$BINUTILS_VERSION
mkdir build
cd build
../configure --prefix=$PREFIX --host=$TARGET --disable-multilib --disable-werror --enable-install-libiberty
make -j4 && make install
echo "compiling binutils...done"

# 编译gcc
cd $BASE
echo "compiling gcc..."
if [ -d gcc-$GCC_VERSION ]; then
	rm -rf gcc-$GCC_VERSION/
fi
tar -xf gcc-$GCC_VERSION.tar.xz

if [ -d gmp-$GMP_VERSION ]; then
	rm -rf gmp-$GMP_VERSION/
fi
tar -xf gmp-$GMP_VERSION.tar.xz
mv gmp-$GMP_VERSION gcc-$GCC_VERSION/gmp

if [ -d mpfr-$MPFR_VERSION ]; then
	rm -rf mpfr-$MPFR_VERSION/
fi
tar -xf mpfr-$MPFR_VERSION.tar.xz
mv mpfr-$MPFR_VERSION gcc-$GCC_VERSION/mpfr

if [ -d mpc-$MPC_VERSION ]; then
	rm -rf mpc-$MPC_VERSION/
fi
tar -xf mpc-$MPC_VERSION.tar.gz
mv mpc-$MPC_VERSION gcc-$GCC_VERSION/mpc

cd gcc-$GCC_VERSION
mkdir build
cd build
../configure --prefix=$PREFIX --host=$TARGET --target=$TARGET --without-headers --enable-languages=c --disable-threads --with-newlib --disable-shared --disable-libssp --disable-deciaml-float --disable-lto --with-mpc=$PREFIX --with-mpfr=$PREFIX --with-gmp=$PREFIX
make all-gcc -j4
make install-gcc
make all-target-libgcc -j4
make install-target-libgcc
echo "compiling gcc...done"

# 编译glibc
cd $BASE
echo "compiling glibc..."
if [ -d glibc-$GLIBC_VERSION ]; then
	rm -rf glibc-$GLIBC_VERSION/
fi
tar -xf glibc-$GLIBC_VERSION.tar.xz
if [ -d glibc-ports-$GLIBC_PORTS_VERSION ]; then
	rm -rf glibc-ports-$GLIBC_PORTS_VERSION/
fi
tar -xf glibc-ports-$GLIBC_PORTS_VERSION.tar.xz
mv glibc-ports-$GLIBC_PORTS_VERSION ports
mv ports glibc-$GLIBC_VERSION/
tar -xf glibc-linuxthreads-$GLIBC_LINUXTHREADS_VERSION.tar.bz2 -C glibc-$GLIBC_VERSION/
# config.cache文件的内容
#libc_cv_forced_unwind=yes
#libc_cv_c_cleanup=yes
#libc_cv_arm_tls=yes
cp config.cache glibc-$GLIBC_VERSION
cd glibc-$GLIBC_VERSION
./configure --prefix=$PREFIX CC=$TARGET-gcc --host=$TARGET --enable-add-ons --disable-profile --cache-file=config.cache --with-binutils=$BINUTILS_BIN --with-headers=$PREFIX/include --libdir=/usr/lib --libexecdir=/usr/lib
make all -j4 && make install
echo "compiling glibc...done"

# 重新编译gcc
echo "compiling gcc again..."
cd $BASE/gcc-$GCC_VERSION
rm -rf build
mkdir build
cd build
../configure --prefix=$PREFIX --host=$TARGET --target=$TARGET --enable-languages=c,c++ --enable-shared --disable-multilib --disable-lto --with-mpc=$PREFIX --with-mpfr=$PREFIX --with-gmp=$PREFIX
make -j4 && make install
echo "compiling gcc again...done"


