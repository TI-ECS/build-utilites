#!/bin/bash

#                            \\\// 
#                           -(o o)- 
#========================oOO==(_)==OOo=======================
#
# This file contains the Bluetooth components which should
# be built and installed on the target filesystem
#

source ./functions/python-functions
function usage()
{
	echo
	echo
	echo "************************************"
	echo "* Bluetooth Modules Builder Script *"
	echo "************************************"
	echo
	echo "This script compiles the BT modules components"
	echo "The script can build each component as standalone by invoking: \"./wl12xx_build_bt.sh <module name> <build/rebuild>\""
	echo "For example: \"./wl12xx_build_bt.sh bt-modules rebuild\""
	echo
	echo "Available components are:"
	echo "bt-modules, expat, libffi, dbus, libIConv, zlib, gettext, glib, dbus-glib,"
	echo "check, python, pygobject, dbus-python,bluez, hcidump, ncurses"
	echo "readline, alsa-lib, openobex, libical, obexd, bt-obex, firmware, wl1271-demo, bt-enable"
	echo
	echo "You may also build all components by typing: \"./wl12xx_build_bt.sh all build\""
	echo
	echo "Prerequisites"
	echo "============="
	echo "The following variables should be exported in order to run the script:"
	echo "1) ROOTFS - should point to the root filesystem where the BT components will be installed"
	echo "2) WORK_SPACE - should point to the workspace where the components will be downloaded and compiled"
	echo "3) KLIB_BUILD - should point to the kernel which the compat bluetooth will be compiled against."
	echo "4) Path to cross compiler in PATH"
	echo ""
}

function all()
{
	get_machine_used
	#bt-modules 1
	uim 1
	expat 1
	libffi
	glib 1
	dbus 1
	libIConv 1
	zlib 1
	gettext 1
	dbus-glib 1
	check 1
	python 1
	pygobject 1
	dbus-python 1
	bluez 1
	hcidump 1
	ncurses 1
	readline 1
	alsa-lib 1
	openobex 1
	libical 1
	obexd 1
	bt-obex 1
	firmware 1
	wl1271-demo 1
	#bt-enable 1
}

function apply_patches()
{
	[ ! -e $LS ] && echo "Please set full path of ls utility in setup-env file." && exit 1
	files=`$LS *.patch`
	for f in ${files}; do patch -p1 -i ${f} || exit 1; done
	return 0
}
function bt-modules()
{
	if [ x"$KLIB_BUILD" = "x" ]; then
		echo "Please set KLIB_BUILD variable to point to your Linux kernel"
		exit 1
	fi

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="ti-compat-bluetooth-2012-02-20.tar.gz"
	COMPONENT_DIR="compat-bluetooth"
	download_component "https://gforge.ti.com/gf/download/frsrelease/802/5435/ti-compat-bluetooth-2012-02-20.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		[ ! -e Compat-patch-zip-v1.zip ] && { wget http://processors.wiki.ti.com/images/9/99/Compat-patch-zip-v1.zip || exit 1; }
		unzip -o Compat-patch-zip-v1.zip || exit 1
		apply_patches

		./scripts/driver-select bt || exit 1
		make KLIB=${ROOTFS} "install-modules" || exit 1
		add_fingerprint 1
	fi
	echo "bt-modules built successfully"
}

function bluez()
{
	if  [ $# -eq 1 ]; then
		START_MODULE="bluez"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	check
	dbus
	glib
	uim

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="bluez"
	COMPONENT_REV="70a609bb3a7401b56377de77586e09a56d631468"
	COMPONENT_DIR="bluez"
	download_component "git://git.kernel.org/pub/scm/bluetooth/bluez.git"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		#[ ! -e BlueZ_patches-v2.zip ] && { wget http://processors.wiki.ti.com/images/7/7e/BlueZ_patches-v2.zip || exit 1; }
		#unzip -o BlueZ_patches-v2.zip || exit 1
		#apply_patches
		patch -p1 -i ${old_dir}/patches/0001-bluez-define-_GNU_SOURCE-macro.patch
		patch -p1 -i ${old_dir}/patches/0001-socket-enable-for-bluez-4_98.patch 
		patch -p1 -i ${old_dir}/patches/0002-bluez-enable-source-interface.patch
		patch -p1 -i ${old_dir}/patches/0001-bluez-define-macro-lacking-in-compiler.patch

		/usr/bin/libtoolize || exit 1
		/usr/bin/aclocal || exit 1
		/usr/bin/autoheader || exit 1
		/usr/bin/automake --add-missing || exit 1
		/usr/bin/autoconf || exit 1

		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --enable-tools --enable-dund --enable-alsa --enable-test --enable-audio --enable-serial --enable-service --enable-hidd --enable-gstreamer --enable-usb --enable-tools --enable-bccmd --enable-hid2hci --enable-dfutool --enable-pand --disable-cups
		make || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		cp audio/audio.conf profiles/input/input.conf ${ROOTFS}${MY_SYSCONFDIR}/bluetooth/ || exit 1
		cp test/agent ${ROOTFS}${MY_PREFIX}/bin/agent || exit 1
		add_fingerprint 1
	fi
	echo "bluez built successfully"
}

function hcidump
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="bluez-hcidump-2.2.tar.gz"
	COMPONENT_DIR="bluez-hcidump-2.2"
	download_component "http://pkgs.fedoraproject.org/repo/pkgs/bluez-hcidump/bluez-hcidump-2.2.tar.gz/3c298a8be67099fe227f3e4d9de539d5/bluez-hcidump-2.2.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} || exit 1
		make || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		add_fingerprint 1
	fi
	echo "hcidump built successfully"
}

function ncurses
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="ncurses-5.9.tar.gz"
	COMPONENT_DIR="ncurses-5.9"
	download_component "http://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR}  -with-shared --without-debug --without-normal || exit 1
		make || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		add_fingerprint 1
	fi
	echo "ncurses built successfully"
}

function readline
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="readline-6.2.tar.gz"
	COMPONENT_DIR="readline-6.2"
	download_component "ftp://ftp.cwru.edu/pub/bash/readline-6.2.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} || exit 1
		make || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "readline built successfully"
}


function alsa-lib
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="alsa-lib-1.0.24.1.tar.gz"
	COMPONENT_DIR="alsa-lib-1.0.25"
	download_component "http://fossies.org/linux/misc/alsa-lib-1.0.24.1.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --prefix=${MY_PREFIX} --host=${BUILD_HOST} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} || exit 1
		make || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "alsa-lib built successfully"
}

function openobex
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="openobex-1.5.tar.gz"
	COMPONENT_DIR="openobex-1.5"
	download_component "http://ftp.osuosl.org/pub/linux/bluetooth/openobex-1.5.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
	#	wget 'http://mirror.anl.gov/pub/linux/bluetooth/openobex-1.5.tar.gz' || exit 1
		add_fingerprint 0
		sed -i '11227 i *)\n;;' configure || exit 1
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --enable-apps --disable-usb || exit 1
		sed -i 's/^\(libdir=\).*/\1\$\{prefix\}\/lib/g' openobex.pc || exit 1
		make || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "openobex built successfully"
}

function libical
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="libical-0.44.tar.gz"
	COMPONENT_DIR="libical-0.44"
	download_component "http://downloads.sourceforge.net/project/freeassociation/libical/libical-0.44/libical-0.44.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} || exit 1
		make || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "libical built successfully"
}

function obexd
{
	if  [ $# -eq 1 ]; then
		START_MODULE="2281d4fac9fec97993b0a6dc0e2ec42911eac194"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	bluez
	openobex
	libical
	readline
	ncurses

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="obexd"
	COMPONENT_REV="2281d4fac9fec97993b0a6dc0e2ec42911eac194"
	COMPONENT_DIR="obexd"
	download_component "git://git.kernel.org/pub/scm/bluetooth/obexd.git"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} || exit 1
		#wget http://processors.wiki.ti.com/images/2/22/Obexd-fix-UTF-conversions-1.tar.gz || exit 1
		wget http://processors.wiki.ti.com/images/4/43/Obexd-patches_v1.tar.gz || exit 1
		echo "Openning archive: Obexd-patches_v1.tar.gz" && tar -xzf Obexd-patches_v1.tar.gz || exit 1
		#apply_patches
		make || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		add_fingerprint 1
	fi
	echo "obexd built successfully"
}

function bt-obex
{
	if  [ $# -eq 1 ]; then
		START_MODULE="171181b6ef6c94aefc828dc7fd8de136b9f97532"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	dbus-glib
	readline
	ncurses

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="bluez-tools"
	COMPONENT_REV="171181b6ef6c94aefc828dc7fd8de136b9f97532"
	COMPONENT_DIR="bluez-tools"
	download_component "git://gitorious.org/bluez-tools/bluez-tools.git"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		[ ! -e Bt-obex-patches.zip ] && { wget 'http://processors.wiki.ti.com/images/f/f5/Bt-obex-patches.zip' || exit 1; }
		unzip -o Bt-obex-patches.zip || exit 1
		apply_patches
		patch -p1 -i ${old_dir}/patches/0001-bt-obex-new-dbus-api-for-obexd.patch

		/usr/bin/libtoolize || exit 1
		/usr/bin/aclocal || exit 1
		/usr/bin/autoheader || exit 1
		/usr/bin/automake --add-missing || exit 1
		/usr/bin/autoconf || exit 1
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} || exit 1
		make LIBS="$LIBS -lncurses" || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		add_fingerprint 1
	fi
	echo "bt-obex built successfully"
}

function wl1271-demo
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="wl1271-bluetooth-2012-03-26.tar.gz"
	COMPONENT_DIR="wl1271-bluetooth"
	download_component "https://gforge.ti.com/gf/download/frsrelease/827/5494/wl1271-bluetooth-2012-03-26.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		#https://github.com/TI-ECS/wl1271-bluetooth/zipball/master
		mkdir -p ${ROOTFS}/usr/share/wl1271-demos/bluetooth/gallery || exit 1
		mkdir -p ${ROOTFS}/usr/share/wl1271-demos/bluetooth/scripts || exit 1
		mkdir -p ${ROOTFS}/usr/share/wl1271-demos/bluetooth/ftp_folder || exit 1

		if [ x"$MACHINE_TYPE" = "x" ]; then
			get_machine_used
		fi

		cp ./gallery/* ${ROOTFS}/usr/share/wl1271-demos/bluetooth/gallery || exit 1
		cp ./script/common/* ${ROOTFS}/usr/share/wl1271-demos/bluetooth/scripts || exit 1
		cp ./script/${MACHINE_TYPE}/* ${ROOTFS}/usr/share/wl1271-demos/bluetooth/scripts || exit 1
		cp ./ftp_folder/* ${ROOTFS}/usr/share/wl1271-demos/bluetooth/ftp_folder || exit 1
		add_fingerprint 1
	fi
	echo "wl1271-demo built successfully"
}

function bt-enable
{
	cd ${WORK_SPACE} || exit 1
	if [ x"$KLIB_BUILD" = "x" ]; then
		echo "Please set KLIB_BUILD variable to point to your Linux kernel"
		exit 1
	fi
	COMPONENT_NAME="bt_enable"
	COMPONENT_REV="dd75971705ada8fb0e88a0fb3f68833086c5bba4"
	COMPONENT_DIR="bt_enable"
	download_component "git://github.com/TI-ECS/bt_enable.git"
	if [ ${CURRENT_OPTION} = "2" ]; then
		[ ! -e Bt-enable-standalone-makefile.zip ] && { wget 'http://processors.wiki.ti.com/images/8/8f/Bt-enable-standalone-makefile.zip' || exit 1; }
	  unzip -o Bt-enable-standalone-makefile.zip || exit 1
	  apply_patches

	  if [ x"$MACHINE_TYPE" = "x" ]; then
		  get_machine_used
	  fi
	  cp ./gpio_en_${MACHINE_TYPE}.c ./gpio_en.c
	  make DEST_DIR=${ROOTFS} KERNEL_DIR=${KLIB_BUILD} || exit 1
	  make DEST_DIR=${ROOTFS} KERNEL_DIR=${KLIB_BUILD} install || exit 1
	  add_fingerprint 1
	fi
	echo "bt-enable built successfully"
}

#==================================================================================
# Main
#==================================================================================
old_dir=`pwd`
MACHINE_TYPE=""

source setup-env || exit 1
# if there are no sufficient arguments...
if  [ $# -lt 2 ]; then
	usage
	exit 0
fi

if [ x"$CROSS_COMPILE" = "x" ]; then
	echo "define CROSS_COMPILE variable"
	exit 1
fi

which ${CROSS_COMPILE}gcc > /dev/null

if [ $? -ne 0 ]; then
	echo "No toolchain in path"
	exit 1
fi

BUILD_HOST=`echo $CROSS_COMPILE | sed s/-$//`

if [ x"$ROOTFS" = "x" ]; then
	echo "Please set ROOTFS variable to point to your root filesystem"
	exit 1
fi

if [ x"$WORK_SPACE" = "x" ]; then
	echo "Please set WORK_SPACE variable to point to your preferred work space"
	exit 1
fi

FINGURE_PRINT_DIR="${WORK_SPACE}/.FingurePrint"
mkdir -p ${FINGURE_PRINT_DIR} || exit 1

USER_OPTION=0
CURRENT_OPTION=0

case "$2" in
	build)
		USER_OPTION=1
	;;
	rebuild)
		USER_OPTION=2
	;;
	*)
		echo "Unknown option $2"
		exit 1
	;;
esac

CURRENT_OPTION=${USER_OPTION}

MODULE_TO_INVOKE=$1
$MODULE_TO_INVOKE 1

cd ${old_dir}
