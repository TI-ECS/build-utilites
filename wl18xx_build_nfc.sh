#!/bin/bash

#                            \\\// 
#                           -(o o)- 
#========================oOO==(_)==OOo=======================
#
# This file contains the NFC components which should
# be built and installed on the target filesystem
#
BUILD_VERSION="r8"
declare -A compat_nfc["r8"]="https://gforge.ti.com/gf/download/frsrelease/977/6265/ti-compat-nfc-2012-10-29.tar.gz"

function usage()
{
	echo
	echo
	echo "************************************"
	echo "* NFC Modules Builder Script *"
	echo "************************************"
	echo
	echo "This script compiles the NFC modules components"
	echo "The script can build each component as standalone by invoking: \"./wl18xx_build_nfc.sh <module name> <build/rebuild>\""
	echo "For example: \"./wl18xx_build_nfc.sh nfc-modules rebuild\""
	echo
	echo "Available components are:"
	echo "nfc-modules, expat, dbus, libIConv, zlib, gettext, glib, dbus-glib"
	echo "firmware, nfc-demo-scripts, nfc-demo-app, uim, neard, python"
	echo "pygobject, dbus-python"
	echo
	echo "You may also build all components by typing: \"./wl18xx_build_nfc.sh all build\""
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
	nfc-modules 1
	libnl 1
	neard 1
	neardal 1
	expat 1
	dbus 1
	libIConv 1
	libffi 1
	zlib 1
	gettext 1
	glib 1
	dbus-glib 1
	firmware 1
	python 1
	pygobject 1
	dbus-python 1
	uim 1
	nfc-demo-scripts 1
	nfc-demo-app 1
}


function nfc-modules()
{
	if [ x"$KLIB_BUILD" = "x" ]; then
		echo "Please set KLIB_BUILD variable to point to your Linux kernel"
		exit 1
	fi

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME=`basename ${compat_nfc[$BUILD_VERSION]}`
	COMPONENT_DIR="compat-nfc"
	download_component "${compat_nfc[$BUILD_VERSION]}"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		./scripts/driver-select nfc || exit 1
		make KLIB=${ROOTFS} "install-modules" || exit 1
		mkdir -p ${ROOTFS}${MY_PREFIX}/include/linux || exit 1
		cp ./include/linux/nfc.h ${ROOTFS}${MY_PREFIX}/include/linux/
		add_fingerprint 1
	fi
	echo "nfc-modules built successfully"
}

function neard()
{
	if  [ $# -eq 1 ]; then
		START_MODULE="neard"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	nfc-modules
	dbus
	glib
	libnl

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="neard"
	COMPONENT_REV="6abe847ade787bd15512c56a9a088f69027bc0b6"
	COMPONENT_DIR="neard"
	download_component "git://git.kernel.org/pub/scm/network/nfc/neard.git"
	if [ ${CURRENT_OPTION} = "2" ]; then
          add_fingerprint 0
	  if [ x"$MACHINE_TYPE" = "x" ]; then
		  get_machine_used
	  fi
    	  ./bootstrap || exit 1
	  ./configure --host=arm-linux --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} || exit 1
	  make || exit 1
	  mkdir -p ${ROOTFS}/usr/bin || exit 1
	  install -c -m 755 src/neard ${ROOTFS}/usr/bin/ || exit 1
	  install -c -m 755 src/org.neard.conf ${ROOTFS}/etc/dbus-1/system.d/ || exit 1
	  mkdir -p ${ROOTFS}/usr/share/nfc-test-scripts || exit 1
	  install -c -m 755 test/* ${ROOTFS}/usr/share/nfc-test-scripts/ || exit 1
	  mkdir -p ${ROOTFS}/etc/init.d || exit 1
	  mkdir -p ${ROOTFS}/etc/rc5.d || exit 1
	  install -c -m 755 ${old_dir}/scripts/nfc/neard.sh ${ROOTFS}/etc/init.d/ || exit 1
	  cd ${ROOTFS}/etc/init.d/ || exit 1
	  ln -s -f ../init.d/neard.sh ../rc5.d/S91neard || exit 1
	  add_fingerprint 1
	fi
	echo "neard built successfully"
}

function neardal()
{
	if  [ $# -eq 1 ]; then
		START_MODULE="neardal"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	neard
	dbus-glib

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="neardal"
	COMPONENT_REV="0.7"
	COMPONENT_DIR="neardal"
	download_component "git://github.com/connectivity/neardal.git"
	if [ ${CURRENT_OPTION} = "2" ]; then
          add_fingerprint 0
	  if [ x"$MACHINE_TYPE" = "x" ]; then
		  get_machine_used
	  fi
	  ./autogen.sh
	  ./configure --host=arm-linux --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --libdir=${ROOTFS}${MY_PREFIX}/lib || exit 1
	  make LIBS="-ldbus-glib-1 -lglib-2.0"|| exit 1
	  make install prefix=${ROOTFS} || exit 1
	  add_fingerprint 1
	fi
	echo "neard application layer built successfully"
}

function nfc-demo-app()
{
	if  [ $# -eq 1 ]; then
		START_MODULE="nfc-demo-app.tar.gz"
	fi
	# dependency section, in here we build the dependencies. We do not want to rebuild them each time
	neardal

	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="nfc-demo-app-2012-11-1.tar.gz"
	COMPONENT_DIR="nfc-demo-app"
	download_component "https://gforge.ti.com/gf/download/frsrelease/985/6284/nfc-demo-app-2012-11-1.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
          add_fingerprint 0
	  if [ x"$MACHINE_TYPE" = "x" ]; then
		  get_machine_used
	  fi
	  ./autogen.sh
	  ./configure --host=arm-linux --prefix=${MY_PREFIX} --sysconfdir=${MY_SYSCONFDIR} --localstatedir=${MY_LOCALSTATEDIR} --libdir=${ROOTFS}${MY_PREFIX}/lib || exit 1
	  make  LIBS="-ldbus-1 -ldbus-glib-1 -lgio-2.0 -lgmodule-2.0 -lgobject-2.0 -lglib-2.0 -liconv -lffi -lz" || exit 1
	  make install DESTDIR=${ROOTFS} || exit 1
	  add_fingerprint 1
	fi
	echo "neard application layer nfc demo application built successfully"
}

function libnl()
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="libnl-2.0.tar.gz"
	COMPONENT_DIR="libnl-2.0"
	
	download_component "http://www.infradead.org/~tgr/libnl/files/libnl-2.0.tar.gz"
	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		patch -p1 < ${old_dir}/patches/0001-libnl-add-lnl-genl-to-default-configuration.patch || exit 1
		./configure --prefix=${ROOTFS}${MY_PREFIX} CC=${CROSS_COMPILE}gcc LD=${CROSS_COMPILE}ld RANLIB=${CROSS_COMPILE}ranlib --host=arm-linux || exit 1
		make || exit 1
		make install || exit 1
		rm `find ${ROOTFS}${MY_PREFIX}/lib/ -name '*.la'` >& /dev/null
		add_fingerprint 1
	fi
	echo "libnl built successfully"
}


function nfc-demo-scripts
{
	cd ${WORK_SPACE} || exit 1
	COMPONENT_NAME="nfc-demo-scripts"
	COMPONENT_DIR="nfc-demo-scripts"

	if [ ${CURRENT_OPTION} = "2" ]; then
		add_fingerprint 0
		mkdir -p ${ROOTFS}/usr/share/nfc-test-scripts || exit 1

		if [ x"$MACHINE_TYPE" = "x" ]; then
			get_machine_used
		fi

		cp ${old_dir}/scripts/nfc/nfc-demo-scripts/* ${ROOTFS}/usr/share/nfc-test-scripts || exit 1
		add_fingerprint 1
	fi
	echo "nfc demo python scripts installed successfully"
}


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
