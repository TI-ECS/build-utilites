#!/bin/bash

#                            \\\// 
#                           -(o o)- 
#========================oOO==(_)==OOo=======================
#
# This file contains the Bluetooth components which should
# be built and installed on the target filesystem
#

BUILD_VERSION="r8"
declare -A compat_bluetooth["r8"]="https://gforge.ti.com/gf/download/frsrelease/990/6319/compat-bluetooth-ol-r8.a5.01_Nov_12_2012.tar.gz"

function usage()
{
	echo
	echo
	echo "************************************"
	echo "* Bluetooth Modules Builder Script *"
	echo "************************************"
	echo
	echo "This script compiles the BT modules components"
	echo "The script can build each component as standalone by invoking: \"./wl18xx_build_bt.sh <module name> <build/rebuild>\""
	echo "For example: \"./wl12xx_build_bt.sh bt-modules rebuild\""
	echo
	echo "Available components are:"
	echo "bt-modules, bluez, hcidump, obexd, bt-obex, firmware, wl1271-demo"
	echo
	echo "You may also build all components by typing: \"./wl18xx_build_bt.sh all build\""
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
	bt-modules 1
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
	openobex 1
	libical 1
	obexd 1
	bt-obex 1
	firmware 1
	wl1271-demo 1
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
	COMPONENT_NAME=`basename ${compat_bluetooth[$BUILD_VERSION]}`
	COMPONENT_DIR="compat-bluetooth"
	download_component "${compat_bluetooth[$BUILD_VERSION]}"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		patch -p1 -i ${old_dir}/patches/0001-compat-wireless-usb-missing-macro.patch

		./scripts/driver-select bt || exit 1
		make KLIB=${ROOTFS} bt || exit 1

		make KLIB=${ROOTFS} "install-modules" || exit 1
		add_fingerprint 1
	fi
	echo "bt-modules built successfully"
}

function alsa-lib
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="alsa-lib-1.0.26.tar.gz"
	COMPONENT_DIR="alsa-lib-1.0.26"
	download_component "http://fossies.org/linux/misc/alsa-lib-1.0.26.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --prefix=${MY_PREFIX} --host=${BUILD_HOST} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --disable-python || exit 1
		make || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "alsa-lib built successfully"
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
	#COMPONENT_REV="18a5dc6cdcf0828443c415eaea82b6834a8f9825"
	COMPONENT_REV="70a609bb3a7401b56377de77586e09a56d631468"
	COMPONENT_DIR="bluez"
	download_component "git://git.kernel.org/pub/scm/bluetooth/bluez.git"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		patch -p1 -i ${old_dir}/patches/0001-bluez-define-_GNU_SOURCE-macro.patch || exit 1
		patch -p1 -i ${old_dir}/patches/0002-bluez-define-macro-lacking-in-compiler.patch || exit 1
		patch -p1 -i ${old_dir}/patches/0003-socket-enable-for-bluez-4_98.patch || exit 1
		patch -p1 -i ${old_dir}/patches/0004-bluez-enable-source-interface.patch || exit 1
		patch -p1 -i ${old_dir}/patches/0005-bluez-enable-gatt.patch || exit 1
		patch -p1 -i ${old_dir}/patches/0006-bluez-fix-missing-include-directive.patch || exit 1
		patch -p1 -i ${old_dir}/patches/0001-Enable-auto-reconnection.patch || exit 1

		/usr/bin/libtoolize || exit 1
		/usr/bin/aclocal || exit 1
		/usr/bin/autoheader || exit 1
		/usr/bin/automake --add-missing || exit 1
		/usr/bin/autoconf || exit 1

		LIBS='-liconv' ./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --enable-alsa --enable-tools --enable-test --enable-audio --enable-serial --enable-service --enable-gstreamer --enable-usb --enable-tools --enable-bccmd --enable-hid2hci --enable-dfutool --enable-pand --disable-cups --enable-debug --enable-gatt --enable-hid2hci --enable-health
		make LIBS='-lffi' || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		cp audio/audio.conf profiles/input/input.conf ${ROOTFS}${MY_SYSCONFDIR}/bluetooth/ || exit 1
		cp test/agent ${ROOTFS}${MY_PREFIX}/bin/agent || exit 1
		mkdir -p ${ROOTFS}/usr/share/bluetooth
		list='simple-agent test-device test-discovery test-manager'

		cd test
		for i in ${list}; do sed -i -e 's/from gi\.repository //' -e 's/GObject/gobject/' $i; done
		list='simple-agent list-devices simple-player simple-service test-adapter test-alert test-attrib test-audio test-device test-discovery test-health test-health-sink test-heartrate test-input test-manager test-nap test-network test-oob test-profile test-proximity test-sap-server test-service test-telephony test-textfile test-thermometer uuidtest rctest monitor-bluetooth mpris-player lmptest gaptest hciemu hsmicro hsplay hstest l2test attest avtest bdaddr btiotest'
		echo "installing tests in ${ROOTFS}/usr/share/bluetooth"
		cp ${list} ${ROOTFS}/usr/share/bluetooth
		cd -
		add_fingerprint 1
	fi
	echo "bluez built successfully"
} 

function hcidump
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="bluez-hcidump-2.4.tar.gz"
	COMPONENT_DIR="bluez-hcidump-2.4"
	download_component "http://www.kernel.org/pub/linux/bluetooth/bluez-hcidump-2.4.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		patch -p1 -i ${old_dir}/patches/0001-blueti-Add-TI-Logger-dump.patch || exit 1
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
		START_MODULE="obexd"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	bluez
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
		/usr/bin/libtoolize || exit 1
		/usr/bin/aclocal || exit 1
		/usr/bin/autoheader || exit 1
		/usr/bin/automake --add-missing || exit 1
		/usr/bin/autoconf || exit 1
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} || exit 1
		#patch -p1 -i ${old_dir}/patches/0001-obexd-ftp-and-opp-cancel-security.patch || exit 1
		wget http://processors.wiki.ti.com/images/4/43/Obexd-patches_v1.tar.gz || exit 1
		echo "Openning archive: Obexd-patches_v1.tar.gz" && tar -xzf Obexd-patches_v1.tar.gz || exit 1
		patch -p1 -i 0001-obexd-make-OPP-push-timeout-longer.patch
		make || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		test -d ${ROOTFS}/usr/share/bluetooth || mkdir -p  ${ROOTFS}/usr/share/bluetooth
		list='exchange-business-cards  ftp-client  get-capabilities  list-folders  map-client  opp-client  pbap-client'
		for f in ${list}; do
			install -c test/$f ${ROOTFS}/usr/share/bluetooth || exit 1
		done
		add_fingerprint 1
	fi
	echo "obexd built successfully"
}

function bt-obex
{
	if  [ $# -eq 1 ]; then
		START_MODULE="bluez-tools"
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
		#patch -p1 -i ${old_dir}/patches/0001-manager-adoptation-to-new-manager-interface-of-bluez.patch

		/usr/bin/libtoolize || exit 1
		/usr/bin/aclocal || exit 1
		/usr/bin/autoheader || exit 1
		/usr/bin/automake --add-missing || exit 1
		/usr/bin/autoconf || exit 1
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} || exit 1
		make LIBS="-ldbus-glib-1 -ldbus-1 -lgobject-2.0 -lglib-2.0 -liconv -lffi -lz -lncurses" || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		add_fingerprint 1
	fi
	echo "bt-obex built successfully"
}

function wl1271-demo
{
	START_MODULE="wl1271-bluetooth"
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="wl1271-bluetooth"
	COMPONENT_DIR="wl1271-bluetooth"
	COMPONENT_REV="d847b748f031ddc5f4fafed4bb3ce03e880a1057" #branch r8
	download_component "git://github.com/TI-ECS/wl1271-bluetooth.git"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
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
source ./functions/common-functions
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
