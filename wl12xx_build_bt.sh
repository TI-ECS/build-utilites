#!/bin/bash

#                            \\\// 
#                           -(o o)- 
#========================oOO==(_)==OOo=======================
#
# This file contains the Bluetooth components which should
# be built and installed on the target filesystem
#


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
	echo "bt-modules, expat, dbus, libIConv, zlib, gettext, glib, dbus-glib, check, bluez, hcidump, ncurses"
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
	bt-modules 1
	expat 1
	dbus 1
	libIConv 1
	zlib 1
	gettext 1
	glib 1
	dbus-glib 1
	check 1
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
	bt-enable 1
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
		make KLIB=${ROOTFS} INSTALL_MOD_PATH=${ROOTFS} "install-modules" || exit 1
		add_fingerprint 1
	fi
	echo "bt-modules built successfully"
}

function expat()
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="expat-2.0.1.tar.gz"
	COMPONENT_DIR="expat-2.0.1"
	
	download_component "http://downloads.sourceforge.net/project/expat/expat/2.0.1/expat-2.0.1.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} 2>&1>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "expat built successfully"
}


function dbus()
{
	if  [ $# -eq 1 ]; then
		START_MODULE="dbus-1.4.1.tar.gz"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	expat

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="dbus-1.4.1.tar.gz"
	COMPONENT_DIR="dbus-1.4.1"
	download_component "http://dbus.freedesktop.org/releases/dbus/dbus-1.4.1.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		echo "ac_cv_func_pipe2=no" > arm-linux.cache || exit 1
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --cache-file=arm-linux.cache --disable-inotify --without-x 2>&1>>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		echo "messagebus:x:102:105::${MY_LOCALSTATEDIR}/run/dbus:/bin/false" >> ${ROOTFS}${MY_SYSCONFDIR}/passwd || exit 1
		add_fingerprint 1
	fi
	echo "dbus built successfully"
}


function libIConv()
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="libiconv-1.13.1.tar.gz"
	COMPONENT_DIR="libiconv-1.13.1"
	download_component "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.13.1.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} 2>&1>>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "libIConv built successfully"
}

function zlib()
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="zlib-1.2.7.tar.gz"
	COMPONENT_DIR="zlib-1.2.7"
	download_component "http://zlib.net/zlib-1.2.7.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} 2>&1>>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		add_fingerprint 1
	fi
	echo "zlib built successfully"
}

function gettext()
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="gettext-0.18.tar.gz"
	COMPONENT_DIR="gettext-0.18"
	download_component "http://ftp.gnu.org/gnu/gettext/gettext-0.18.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		echo "ac_cv_func_unsetenv=no" > arm-linux.cache || exit 1
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --cache-file=arm-linux.cache 2>&1>>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "gettext built successfully"
}

function glib()
{
	if  [ $# -eq 1 ]; then
		START_MODULE="glib-2.24.1.tar.bz2"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	libIConv
	zlib

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="glib-2.24.1.tar.bz2"
	COMPONENT_DIR="glib-2.24.1"
	download_component "http://ftp.gnome.org/pub/GNOME/sources/glib/2.24/glib-2.24.1.tar.bz2"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		echo "glib_cv_stack_grows=no
		glib_cv_uscore=yes
		ac_cv_func_posix_getpwuid_r=yes
		ac_cv_func_posix_getgrgid_r=yes
		ac_cv_func_pipe2=no" > arm-linux.cache || exit 1
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --cache-file=arm-linux.cache --with-libiconv=gnu 2>&1>>${BUILD_LOG_FILE} || exit 1
		sed -i 's/\(^Libs: .*\)/\1 -liconv/g' glib-2.0.pc || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "glib built successfully"
}

function dbus-glib()
{
	if  [ $# -eq 1 ]; then
		START_MODULE="dbus-glib-0.84.tar.gz"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	dbus
	glib

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="dbus-glib-0.84.tar.gz"
	COMPONENT_DIR="dbus-glib-0.84"
	download_component "http://dbus.freedesktop.org/releases/dbus-glib/dbus-glib-0.84.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		echo "ac_cv_have_abstract_sockets=yes" > arm-linux.cache || exit 1
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --cache-file=arm-linux.cache 2>&1>>${BUILD_LOG_FILE} || exit 1
		sed -i 's/examples//g' dbus/Makefile || exit 1
		sed -i 's/tools test/test/g' Makefile || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "dbus-glib built successfully"
}


function check()
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="check-0.9.6.tar.gz"
	COMPONENT_DIR="check-0.9.6"
	download_component "http://downloads.sourceforge.net/check/check-0.9.6.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} 2>&1>>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "check built successfully"
}

function bluez()
{
	if  [ $# -eq 1 ]; then
		START_MODULE="bluez-4.98.tar.gz"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	check
	dbus
	glib

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="bluez-4.98.tar.gz"
	COMPONENT_DIR="bluez-4.98"
	download_component "http://kernel.org/pub/linux/bluetooth/bluez-4.98.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		[ ! -e BlueZ_patches-v2.zip ] && { wget http://processors.wiki.ti.com/images/7/7e/BlueZ_patches-v2.zip || exit 1; }
		unzip -o BlueZ_patches-v2.zip || exit 1
		apply_patches

		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --enable-tools --enable-dund --enable-alsa --enable-test --enable-audio --enable-serial --enable-service --enable-hidd --enable-gstreamer --enable-usb --enable-tools --enable-bccmd --enable-hid2hci --enable-dfutool --enable-pand --disable-cups 2>&1>>${BUILD_LOG_FILE}
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		cp audio/audio.conf tools/rfcomm.conf input/input.conf ${ROOTFS}${MY_SYSCONFDIR}/bluetooth/ || exit 1
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
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} 2>&1>>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
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
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR}  -with-shared --without-debug --without-normal 2>&1>>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
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
	download_component " http://ftp.gnu.org/gnu/readline/readline-6.2.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} 2>&1>>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
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
	COMPONENT_DIR="alsa-lib-1.0.26"
	download_component "http://fossies.org/linux/misc/alsa-lib-1.0.24.1.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --prefix=${MY_PREFIX} --host=${BUILD_HOST} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} 2>&1>>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
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
		sed -i '11227 i *)\n;;' configure 2>&1>>${BUILD_LOG_FILE} || exit 1
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --enable-apps --disable-usb 2>&1>>${BUILD_LOG_FILE} || exit 1
		sed -i 's/^\(libdir=\).*/\1\$\{prefix\}\/lib/g' openobex.pc || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
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
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} 2>&1>>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "libical built successfully"
}

function obexd
{
	if  [ $# -eq 1 ]; then
		START_MODULE="obexd-0.34.tar.gz"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	bluez
	openobex
	libical

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="obexd-0.34.tar.gz"
	COMPONENT_DIR="obexd-0.34"
	download_component "http://www.kernel.org/pub/linux/bluetooth/obexd-0.34.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} 2>&1>>${BUILD_LOG_FILE} || exit 1
		wget http://processors.wiki.ti.com/images/4/43/Obexd-patches_v1.tar.gz || exit 1
		echo "Openning archive: Obexd-patches_v1.tar.gz" && tar -xzf Obexd-patches_v1.tar.gz || exit 1
		apply_patches
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
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
	COMPONENT_NAME="171181b6ef6c94aefc828dc7fd8de136b9f97532"
	COMPONENT_DIR="bluez-tools"
	download_component "git://gitorious.org/bluez-tools/bluez-tools.git"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		[ ! -e Bt-obex-patches.zip ] && { wget 'http://processors.wiki.ti.com/images/f/f5/Bt-obex-patches.zip' || exit 1; }
		unzip -o Bt-obex-patches.zip || exit 1
		apply_patches

		/usr/bin/libtoolize || exit 1
		/usr/bin/aclocal || exit 1
		/usr/bin/autoheader || exit 1
		/usr/bin/automake --add-missing || exit 1
		/usr/bin/autoconf || exit 1
		./configure --host=${BUILD_HOST} --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} 2>&1>>${BUILD_LOG_FILE} || exit 1
		make 2>&1>>${BUILD_LOG_FILE} || exit 1
		make install DESTDIR=${ROOTFS} || exit 1
		add_fingerprint 1
	fi
	echo "bt-obex built successfully"
}

function firmware
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="db43d1f05efda9777d7ac1ac366637e29e21f77f"
	COMPONENT_DIR="bt-firmware"
	download_component "git://github.com/TI-ECS/bt-firmware.git"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		mkdir -p ${ROOTFS}/lib/firmware || exit 1

		if [ x"$MACHINE_TYPE" = "x" ]; then
			get_machine_used
		fi

		PRINT_STR="Invoking: cp ${MACHINE_TYPE}/TIInit_7.2.31.bts ${ROOTFS}/lib/firmware/"
		echo ${PRINT_STR}
		cp ./${MACHINE_TYPE}/TIInit_7.2.31.bts ${ROOTFS}/lib/firmware/ || exit 1
		add_fingerprint 1
	fi
	echo "firmware built successfully"
}

function wl1271-demo
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="wl1271-bluetooth-2012-03-26.tar.gz"
	COMPONENT_DIR="wl1271-bluetooth"
	download_component "https://gforge.ti.com/gf/download/frsrelease/827/5494/wl1271-bluetooth-2012-03-26.tar.gz"
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
	COMPONENT_NAME="dd75971705ada8fb0e88a0fb3f68833086c5bba4"
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

function add_fingerprint()
{
	if [ x"$1" = "x" ]; then
	  echo "Function add_fingerprint() called with no parameters!!!"
	  exit 1
	fi
	local FILENAME="${FINGURE_PRINT_DIR}/${COMPONENT_NAME##*/}"
	touch  ${FILENAME} || exit 1
	echo $1 > ${FILENAME} || exit
}

function fingerprint()
{
	local FILENAME="${FINGURE_PRINT_DIR}/${COMPONENT_NAME##*/}"
	# if no file exists
	if [ ! -e ${FILENAME} ]; then
		return 0
	fi
	read MAX < ${FILENAME}
	return ${MAX}
}

function download_component()
{
	if [ x"$1" = "x" ]; then
		echo "Function called with no parameters!!!"
		exit 1
	fi

	if [ ! x"${START_MODULE}" = "x" ]; then							# if the START_MODULE is not empty
		if [ ${START_MODULE} = ${COMPONENT_NAME} ]; then			# if we are building the start module
			CURRENT_OPTION=${USER_OPTION}							# take the user option as is
		else
			CURRENT_OPTION="1"										# else, we are building dependency, so we should only build not rebuild
		fi
	else
		CURRENT_OPTION=${USER_OPTION}								# take the user option as is
	fi
	# get the extension of the file
	local EXT=${1/*./}

	# check the fingerprint value
	fingerprint
	case "$?" in
		0) # 0 - File not compiled nor installed
			CURRENT_OPTION="2" # override to "rebuild" option
		;;
		1) # 1 - File was installed properly
			# if the option is build and fingerprint OK, nothing to do
			if [ ${CURRENT_OPTION} = "1" ]; then 
				return
			fi
		;;
		*)
			echo "Corrupted fingerprint for component ${COMPONENT_NAME}"
			exit 1
		;;
	esac
#	echo "Decided to rebuild for ${COMPONENT_NAME}"
#	read
	# I get here in one situation : USER_OPTION = 2
	case "${EXT}" in
		git)
			# if git directory exist, do not clone it again
			if [ ! -d ${COMPONENT_DIR} ]; then
			  git clone $1 || exit 1
			fi
			cd ${COMPONENT_DIR} || exit 1
			git reset --hard ${COMPONENT_NAME} || exit 1
		;;

		gz|bz2)
			# delete the working directory if exists
			if [ ! x"${COMPONENT_DIR}" = "x" ]; then
				rm -rf ${COMPONENT_DIR} || exit 1
			fi

			local TAR_FLAGS="-xzf"

			if [ ${EXT} = "bz2" ]; then
				TAR_FLAGS="-xjf"
			fi
			# if component doesn't exist, bring it
			if [ ! -e ${COMPONENT_NAME} ]; then
				wget $1 || exit 1
			fi
			echo "Openning archive: ${COMPONENT_NAME}"
			tar ${TAR_FLAGS} ${COMPONENT_NAME} || exit 1 
			# move to the directory if not empty
			if [ ! x"${COMPONENT_DIR}" = "x" ]; then			
				cd ${COMPONENT_DIR} || exit 1
			fi;
		;;

		*)
			echo "Unknown extension of remote package"
			exit 1
		;;
	esac
}

function get_machine_used()
{
	# check if the machine type is already defined
	if [ ! x"${MACHINE_TYPE}" = "x" ]; then
		return;
	fi
	echo ""
	echo "Please select the machine you use:"
	echo "==================================="
	echo "1. am180x-evm (am1808)"
	echo "2. am37x-evm (omap3evm)"
	echo "3. am335x-evm (am335x)"
	read choice
	case $choice in
		1) MACHINE_TYPE="am1808" ;;
		2) MACHINE_TYPE="omap3evm" ;;
		3) MACHINE_TYPE="am335x" ;;
		*)
		echo "This is not a valid choice... Exitiing script"
		exit 1
		;;
	esac
}

function check_env()
{
        [ -e ${WORK_SPACE}/.check_env.stamp ] && return 0
        which dpkg
	if [ $? -ne 0 ]
	then
		echo "The following packages should be installed on the system:"
		echo "bash bison flex perl bc python python-m2crypto corkscrew"
		echo "git autoconf automake libtool gettext patch libglib2.0-dev"
		echo "Please check before to continue."
		return 0
	fi
        err=0
        ret=0
	packages="bash bison flex perl bc python python-m2crypto corkscrew git autoconf automake libtool gettext patch libglib2.0-dev"
        for p in ${packages}
        do
                echo -n "Checking ${p}..."
                present=`dpkg-query -W ${p} 2>/dev/null | awk '{print $1}'`
                [ x"${present}" != x"${p}" ] && echo "Package ${p} is not found. Please run 'apt-get install ${p}' to install it." && err=1 && ret=1
                [ ${err} -ne 1 ] && echo "OK"
                err=0
        done
        return ${ret}
}
############################################# MAIN ###############################################
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
check_env || exit 1
touch ${WORK_SPACE}/.check_env.stamp
BUILD_LOG_FILE=${FINGURE_PRINT_DIR}/build.log
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
