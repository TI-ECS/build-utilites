#!/bin/bash

export ARCH="arm"
export CROSS_COMPILE="arm-arago-linux-gnueabi-"
export MY_PREFIX="/usr"
export MY_SYSCONFDIR="/etc"
export MY_LOCALSTATEDIR="/var"
export CC="${CROSS_COMPILE}gcc"
export CXX="${CROSS_COMPILE}g++"
export AR="${CROSS_COMPILE}ar"
export RANLIB="${CROSS_COMPILE}ranlib"
export CFLAGS="-I${ROOTFS}${MY_PREFIX}/include"
export CPPFLAGS="${CFLAGS}"
export LDFLAGS="-L${ROOTFS}${MY_PREFIX}/lib"
export PKG_CONFIG_SYSROOT_DIR=${ROOTFS}
export PKG_CONFIG_PATH="${ROOTFS}${MY_PREFIX}/lib/pkgconfig"
export PKG_CONFIG_LIBDIR=""
export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=""
export PKG_CONFIG_ALLOW_SYSTEM_LIBS=""
function usage()
{
	echo
	echo
	echo "************************************"
	echo "* Bluetooth Modules Builder Script *"
	echo "************************************"
	echo
	echo "This script compiles the BT modules components"
	echo "The script can build each component as standalone by invoking: \"./wl12xx_build_bt.sh <module name>\""
	echo "For example: \"./wl12xx_build_bt.sh bt_modules\""
	echo
	echo "Available components are:"
	echo "bt_modules, expat, dbus, libIConv, zlib, gettext, glib, dbus-glib, check, bluez, hcidump, ncurses"
	echo "readline, alsa-lib, openobex, libical, obexd, bt-obex, obexftp, firmware, wl1271-demo, bt-enable"
	echo
	echo "You may also build all components by typing: \"./wl12xx_build_bt.sh build_all\""
	echo
	echo "Prerequisites"
	echo "============="
	echo "The following variables should be exported in order to run the script:"
	echo "1) ROOTFS - should point to the root filesystem where the BT components will be installed"
	echo "2) WORK_SPACE - should point to the workspace where the components will be downloaded and compiled"
	echo "3) KLIB_BUILD - should point to the kernel which the compat bluetooth will be compiled against."
	echo "                The KLIB_BUILD is needed for bt_modules component or when using build_all option."
	echo "4) Path to cross compiler in PATH"
	echo ""
}

function build_all()
{
	get_platform_used
	bt_modules
	expat
	dbus
	libIConv
	zlib
	gettext
	glib
	dbus-glib
	check
	bluez
	hcidump
	ncurses
	readline
	alsa-lib
	openobex
	libical
	obexd
	bt-obex
	obexftp
	firmware
	wl1271-demo
	bt-enable
}


function bt_modules()
{
	if [ x"$KLIB_BUILD" = "x" ]; then
		echo "Please set KLIB_BUILD variable to point to your Linux kernel"
		exit -1
	fi
	COMPONENT_NAME="ti-compat-bluetooth-2012-02-20.tar.gz"
	COMPONENT_DIR="compat-bluetooth"
	download_component "https://gforge.ti.com/gf/download/frsrelease/802/5435/ti-compat-bluetooth-2012-02-20.tar.gz"

	wget http://processors.wiki.ti.com/images/9/99/Compat-patch-zip-v1.zip || exit -1
	unzip Compat-patch-zip-v1.zip || exit -1
	patch -p1 < 0001-compat-bluetooth-2.6-removed-unused-BT-modules-from-.patch || exit -1
	patch -p1 < 0002-Bluetooth-Fix-l2cap-conn-failures-for-ssp-devices.patch || exit -1

	./scripts/driver-select bt || exit -1
	make KLIB=${ROOTFS} "install-modules" || exit -1
	echo "bt_modules built successfully"
}

function expat()
{
	COMPONENT_NAME="expat-2.0.1.tar.gz"
	COMPONENT_DIR="expat-2.0.1"
	download_component "http://downloads.sourceforge.net/project/expat/expat/2.0.1/expat-2.0.1.tar.gz"

	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "expat built successfully"
}


function dbus()
{
	COMPONENT_NAME="dbus-1.4.1.tar.gz"
	COMPONENT_DIR="dbus-1.4.1"
	download_component "http://dbus.freedesktop.org/releases/dbus/dbus-1.4.1.tar.gz"

	echo "ac_cv_func_pipe2=no" > arm-linux.cache || exit -1
	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --cache-file=arm-linux.cache --disable-inotify --without-x || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "messagebus:x:102:105::${MY_LOCALSTATEDIR}/run/dbus:/bin/false" >> ${ROOTFS}${MY_SYSCONFDIR}/passwd || exit -1
	echo "dbus built successfully"
}


function libIConv()
{
	COMPONENT_NAME="libiconv-1.13.1.tar.gz"
	COMPONENT_DIR="libiconv-1.13.1"
	download_component "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.13.1.tar.gz"

	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "libIConv built successfully"
}

function zlib()
{
	COMPONENT_NAME="zlib-1.2.6.tar.gz"
	COMPONENT_DIR="zlib-1.2.6"
	download_component "http://zlib.net/zlib-1.2.6.tar.gz"

	./configure --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	echo "zlib built successfully"
}

function gettext()
{
	COMPONENT_NAME="gettext-0.18.tar.gz"
	COMPONENT_DIR="gettext-0.18"
	download_component "http://ftp.gnu.org/gnu/gettext/gettext-0.18.tar.gz"

	echo "ac_cv_func_unsetenv=no" > arm-linux.cache || exit -1
	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --cache-file=arm-linux.cache || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "gettext built successfully"
}

function glib()
{
	COMPONENT_NAME="glib-2.24.1.tar.bz2"
	COMPONENT_DIR="glib-2.24.1"
	download_component "http://ftp.gnome.org/pub/GNOME/sources/glib/2.24/glib-2.24.1.tar.bz2"

	echo "glib_cv_stack_grows=no
	glib_cv_uscore=yes
	ac_cv_func_posix_getpwuid_r=yes
	ac_cv_func_posix_getgrgid_r=yes
	ac_cv_func_pipe2=no" > arm-linux.cache || exit -1
	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --cache-file=arm-linux.cache --with-libiconv=gnu || exit -1
	sed -i 's/\(^Libs: .*\)/\1 -liconv/g' glib-2.0.pc || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "glib built successfully"
}

function dbus-glib()
{
	COMPONENT_NAME="dbus-glib-0.84.tar.gz"
	COMPONENT_DIR="dbus-glib-0.84"
	download_component "http://dbus.freedesktop.org/releases/dbus-glib/dbus-glib-0.84.tar.gz"

	echo "ac_cv_have_abstract_sockets=yes" > arm-linux.cache || exit -1
	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --cache-file=arm-linux.cache || exit -1
	sed -i 's/examples//g' dbus/Makefile || exit -1
	sed -i 's/tools test/test/g' Makefile || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "dbus-glib built successfully"
}


function check()
{
	COMPONENT_NAME="check-0.9.6.tar.gz"
	COMPONENT_DIR="check-0.9.6"
	download_component "http://downloads.sourceforge.net/check/check-0.9.6.tar.gz"
	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "check() built successfully"
}

function bluez()
{
	COMPONENT_NAME="bluez-4.98.tar.gz"
	COMPONENT_DIR="bluez-4.98"
	download_component "http://kernel.org/pub/linux/bluetooth/bluez-4.98.tar.gz"

	wget http://processors.wiki.ti.com/images/d/d2/BlueZ_patches-v1.zip || exit -1
	unzip BlueZ_patches-v1.zip || exit -1

	patch -p1 < ./0001-socket-enable-for-bluez-4_98.patch || exit -1
	patch -p1 < ./0001-bluez-enable-source-interface.patch || exit -1
	patch -p1 < ./bluez4-fix-synchronization-between-bluetoothd-and-dr.patch || exit -1

	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --enable-tools --enable-dund --disable-alsa --enable-test --enable-audio --enable-serial --enable-service --enable-hidd || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	cp audio/audio.conf tools/rfcomm.conf input/input.conf ${ROOTFS}${MY_SYSCONFDIR}/bluetooth/ || exit -1
	cp test/agent ${ROOTFS}${MY_PREFIX}/bin/agent || exit -1
	echo "bluez built successfully"
}

function hcidump
{
	COMPONENT_NAME="bluez-hcidump-2.2.tar.gz"
	COMPONENT_DIR="bluez-hcidump-2.2"
	download_component "http://pkgs.fedoraproject.org/repo/pkgs/bluez-hcidump/bluez-hcidump-2.2.tar.gz/3c298a8be67099fe227f3e4d9de539d5/bluez-hcidump-2.2.tar.gz"

	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	echo "hcidump built successfully"
}

function ncurses
{
	COMPONENT_NAME="ncurses-5.9.tar.gz"
	COMPONENT_DIR="ncurses-5.9"
	download_component "http://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz"

	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR}  -with-shared --without-debug --without-normal || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	echo "ncurses built successfully"
}

function readline
{
	COMPONENT_NAME="readline-6.2.tar.gz"
	COMPONENT_DIR="readline-6.2"
	download_component "ftp://ftp.cwru.edu/pub/bash/readline-6.2.tar.gz"

	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "readline built successfully"
}


function alsa-lib
{
	COMPONENT_NAME="alsa-lib-1.0.24.1.tar.gz"
	COMPONENT_DIR="alsa-lib-1.0.25"
	download_component "http://fossies.org/linux/misc/alsa-lib-1.0.24.1.tar.gz"

	./configure --prefix=${MY_PREFIX} --host=arm-arago-linux-gnueabi --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "alsa-lib built successfully"
}

function openobex
{
	COMPONENT_NAME="openobex-1.5.tar.gz"
	COMPONENT_DIR="openobex-1.5"
	download_component "http://ftp.osuosl.org/pub/linux/bluetooth/openobex-1.5.tar.gz"

#	wget 'http://mirror.anl.gov/pub/linux/bluetooth/openobex-1.5.tar.gz' || exit -1

	sed -i '11227 i *)\n;;' configure || exit -1
	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --enable-apps --disable-usb || exit -1
	sed -i 's/^\(libdir=\).*/\1\$\{prefix\}\/lib/g' openobex.pc || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "openobex built successfully"
}

function libical
{
	COMPONENT_NAME="libical-0.44.tar.gz"
	COMPONENT_DIR="libical-0.44"
	download_component "http://downloads.sourceforge.net/project/freeassociation/libical/libical-0.44/libical-0.44.tar.gz"

	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "libical built successfully"
}

function obexd
{
	COMPONENT_NAME="obexd-0.34.tar.gz"
	COMPONENT_DIR="obexd-0.34"
	download_component "http://www.kernel.org/pub/linux/bluetooth/obexd-0.34.tar.gz"

	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} || exit -1
	wget http://processors.wiki.ti.com/images/2/22/Obexd-fix-UTF-conversions-1.tar.gz || exit -1
	tar -xzvf Obexd-fix-UTF-conversions-1.tar.gz || exit -1
	patch -p 1 < 0001-obexd-fix-UTF-conversions.patch || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	echo "obexd built successfully"
}

function bt-obex
{
	COMPONENT_NAME="171181b6ef6c94aefc828dc7fd8de136b9f97532"
	COMPONENT_DIR="bluez-tools"
	download_component "git://gitorious.org/bluez-tools/bluez-tools.git"

#	wget 'http://processors.wiki.ti.com/images/5/5b/0001-GStatBuf-fix-compilation-issue.zip'
#	unzip 0001-GStatBuf-fix-compilation-issue.zip || exit -1
	wget 'http://processors.wiki.ti.com/images/f/f5/Bt-obex-patches.zip' || exit -1
	unzip Bt-obex-patches.zip || exit -1
	patch -p1 < 0001-GStatBuf-fix-compilation-issue.patch || exit -1
	patch -p1 < 0001-add-dependency-for-ncurses.patch || exit -1
	/usr/bin/libtoolize || exit -1
	/usr/bin/aclocal || exit -1
	/usr/bin/autoheader || exit -1
	/usr/bin/automake --add-missing || exit -1
	/usr/bin/autoconf || exit -1
	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	echo "bt-obex built successfully"
}

function obexftp
{
	COMPONENT_NAME="obexftp-0.23.tar.bz2"
	COMPONENT_DIR="obexftp-0.23"
	download_component "http://triq.net/obexftp/obexftp-0.23.tar.bz2"

	./configure --host=arm-arago-linux-gnueabi --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --disable-perl --disable-python --disable-tcl || exit -1
	make || exit -1
	make install DESTDIR=${ROOTFS} || exit -1
	rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
	echo "obexftp built successfully"
}

function firmware
{
	COMPONENT_NAME="db43d1f05efda9777d7ac1ac366637e29e21f77f"
	COMPONENT_DIR="bt-firmware"
	download_component "git://github.com/TI-ECS/bt-firmware.git"

	mkdir -p ${ROOTFS}/lib/firmware || exit -1

	if [ x"$PLATFORM_DIR" = "x" ]; then
		get_platform_used
	fi

	PRINT_STR="Invoking: cp ${PLATFORM_DIR}/TIInit_7.2.31.bts ${ROOTFS}/lib/firmware/"
	echo ${PRINT_STR}
	cp ./${PLATFORM_DIR}/TIInit_7.2.31.bts ${ROOTFS}/lib/firmware/ || exit -1
	echo "firmware built successfully"
}

function wl1271-demo
{
	COMPONENT_NAME="wl1271-bluetooth-2012-03-26.tar.gz"
	COMPONENT_DIR="wl1271-bluetooth"
	download_component "https://gforge.ti.com/gf/download/frsrelease/827/5494/wl1271-bluetooth-2012-03-26.tar.gz"

	mkdir -p ${ROOTFS}/usr/share/wl1271-demos/bluetooth/gallery || exit -1
	mkdir -p ${ROOTFS}/usr/share/wl1271-demos/bluetooth/scripts || exit -1
	mkdir -p ${ROOTFS}/usr/share/wl1271-demos/bluetooth/ftp_folder || exit -1

	if [ x"$PLATFORM_DIR" = "x" ]; then
		get_platform_used
	fi

	cp ./gallery/* ${ROOTFS}/usr/share/wl1271-demos/bluetooth/gallery || exit -1
	cp ./script/common/* ${ROOTFS}/usr/share/wl1271-demos/bluetooth/scripts || exit -1
	cp ./script/${PLATFORM_DIR}/* ${ROOTFS}/usr/share/wl1271-demos/bluetooth/scripts || exit -1
	cp ./ftp_folder/* ${ROOTFS}/usr/share/wl1271-demos/bluetooth/ftp_folder || exit -1

	echo "wl1271-demo built successfully"
}

function bt-enable
{
	COMPONENT_NAME="dd75971705ada8fb0e88a0fb3f68833086c5bba4"
	COMPONENT_DIR="bt_enable"
	download_component "git://github.com/TI-ECS/bt_enable.git"

	wget 'http://processors.wiki.ti.com/images/8/8f/Bt-enable-standalone-makefile.zip' || exit -1
	unzip Bt-enable-standalone-makefile.zip || exit -1
	patch -p1 < 0001-bt-enable-standalone-makefile.patch || exit -1

	if [ x"$PLATFORM_DIR" = "x" ]; then
		get_platform_used
	fi
	cp ./gpio_en_${PLATFORM_DIR}.c ./gpio_en.c
	make DEST_DIR=${ROOTFS} KERNEL_DIR=${KLIB_BUILD} install || exit -1
	echo "bt-enable built successfully"
}

function download_component()
{
	if [ x"$1" = "x" ]; then
	  echo "Function called with no parameters!!!"
	  exit -1
	fi

	# download to workspace
	cd ${WORK_SPACE} || exit -1

	# get the extension of the file
	local EXT=${1/*./}


	case "${EXT}" in
		git)
			# if git directory exist, do not clone it again
			if [ ! -d ${COMPONENT_DIR} ]; then
			  git clone $1 || exit -1
			fi
			cd ${COMPONENT_DIR} || exit -1
			git reset --hard ${COMPONENT_NAME} || exit -1
		;;

		gz|bz2)
			#delete the working directory if exists
			if [ ! x"${COMPONENT_DIR}" = "x" ]; then
			  rm -rf ${COMPONENT_DIR} || exit -1
			fi

			local TAR_FLAGS="-xzvf"

			if [ ${EXT} = "bz2" ]; then
				TAR_FLAGS="-xjvf"
			fi
			# if component doesn't exist, bring it
			if [ ! -e ${COMPONENT_NAME} ]; then
				wget $1 || exit -1
			fi
			tar ${TAR_FLAGS} ${COMPONENT_NAME} || exit -1 
			cd ${COMPONENT_DIR} || exit -1
		;;

		*)
			echo "Unknown extension of remote package"
			exit -1
		;;
	esac
}

function get_platform_used()
{
	echo ""
	echo "Please select the platform you use:"
	echo "==================================="
	echo "1. am180x-evm"
	echo "2. am37x-evm"
	echo "3. am335x-evm"
	read choice
	case $choice in
		1) PLATFORM_DIR="am1808" ;;
		2) PLATFORM_DIR="omap3evm" ;;
		3) PLATFORM_DIR="am335x" ;;
		*)
		echo "This is not a valid choice... Exitiing script"
		exit 1
		;;
		
	esac
}

old_dir=`pwd`
PLATFORM_DIR=""

# if there are no arguments...
if  [ $# -lt 1 ]; then
	usage
	exit 0
fi

if [ x"$CROSS_COMPILE" = "x" ]; then
	echo "define CROSS_COMPILE variable"
	exit -1
fi

which ${CROSS_COMPILE}gcc > /dev/null

if [ $? -ne 0 ]; then
	echo "No toolchain in path"
	exit -1
fi


if [ x"$ROOTFS" = "x" ]; then
	echo "Please set ROOTFS variable to point to your root filesystem"
	exit -1
fi

if [ x"$WORK_SPACE" = "x" ]; then
	echo "Please set WORK_SPACE variable to point to your preferred work space"
	exit -1
fi

OPERATION=$1
$OPERATION

cd ${old_dir}
