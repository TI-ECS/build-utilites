#!/bin/bash

if [ ! -e setup-env ]
then
	echo "No setup-env"
	exit 1
fi
source setup-env
ME=$0
components="libnl openssl iw hostap wpa_supplicant crda ti-utils ti-utils-firmware compat-wireless"

function download ()
{
	file="$2"
	[ -e ${WORK_SPACE}/${file} ] && echo "File $file already exists. Skipping download." && return 0
	wget "$1"
	if [ $? -ne 0 ]
	then 
		echo "Failed to download $file"
		exit 1
	fi
}

function git_clone ()
{
	file="$2"
	[ -e ${WORK_SPACE}/${file} ] && echo "File $file alread exists. Skipping git clone." && return 0
	git clone "$1"
	if [ $? -ne 0 ]
	then
		echo "Failed to download $2 git repository"
		exit 1
	fi
}
function compat-wireless()
{
	stage=$1
	if [ x"$stage" = "xdownload"  -o x"$stage" = "xall" ]
	then
		#download https://gforge.ti.com/gf/download/frsrelease/768/5331/ti-compat-wireless-wl12xx-r4-12-12-20.tar.gz ti-compat-wireless-wl12xx-r4-12-12-20.tar.gz
		#tar xzf ti-compat-wireless-wl12xx-r4-12-12-20.tar.gz
		download https://gforge.ti.com/gf/download/frsrelease/801/5434/ti-compat-wireless-wl12xx-2012-02-06-r4-12.tgz ti-compat-wireless-wl12xx-2012-02-06-r4-12.tgz
		tar xzf ti-compat-wireless-wl12xx-2012-02-06-r4-12.tgz
		cd ${WORK_SPACE}/compat-wireless || exit 1
		download http://processors.wiki.ti.com/images/a/aa/Compat-wireless-patches.zip Compat-wireless-patches.zip
		mkdir tmp-patches
		cd tmp-patches
		unzip ../Compat-wireless-patches.zip && cd -
		for i in `$LS tmp-patches`; do patch -p1 -i tmp-patches/$i || exit 1; done
		res=`./scripts/driver-select wl12xx`
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/compat-wireless
		make KLIB_BUILD=${KLIB_BUILD} KLIB=${ROOTFS} || exit 1
	fi
	if [ x"$stage" = "xinstall"  -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/compat-wireless
		make KLIB_BUILD=${KLIB_BUILD} KLIB=${ROOTFS} install-modules
	fi

	if [ x"$stage" = "xclean" ]
	then
		cd $WORK_SPACE/compat-wireless
		make KLIB=${ROOTFS} uninstall
		cd $WORK_SPACE && rm -rf compat-wireless
	fi

	cd $WORK_SPACE
}
function crda ()
{
	stage=$1
	if [ x"$stage" = "xdownload"  -o x"$stage" = "xall" ]
	then
		download "http://wireless.kernel.org/download/crda/crda-1.1.1.tar.bz2" "crda-1.1.1.tar.bz2"
		tar xjf crda-1.1.1.tar.bz2
		cd ${WORK_SPACE}/crda-1.1.1
		download http://linuxwireless.org/download/wireless-regdb/regulatory.bins/2011.04.28-regulatory.bin 2011.04.28-regulatory.bin
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/crda-1.1.1
		make USE_OPENSSL=1 all_noverify || exit 1
	fi
	if [ x"$stage" = "xinstall"  -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/crda-1.1.1
		DESTDIR=${ROOTFS} make USE_OPENSSL=1 UDEV_RULE_DIR="etc/udev/rules.d/" install || exit 1
		mkdir -p ${ROOTFS}/usr/lib/crda
		cp 2011.04.28-regulatory.bin ${ROOTFS}/usr/lib/crda/regulatory.bin
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd $WORK_SPACE/crda-1.1.1
		DESTDIR=${ROOTFS} make clean
		cd $WORK_SPACE && rm -rf crda-1.1.1
	fi
	cd $WORK_SPACE
}

function iw ()
{
	stage=$1
	if [ x"$stage" = "xdownload"  -o x"$stage" = "xall" ]
	then
		git_clone git://git.sipsolutions.net/iw.git iw
		cd ${WORK_SPACE}/iw
		git reset --hard 0a236ef5f8e4ba7218aac7d0cdacf45673d5b35c || exit 1
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/iw
		make || exit 1
	fi

	if [ x"$stage" = "xinstall"  -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/iw
		DESTDIR=${ROOTFS} make install || exit 1
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd $WORK_SPACE/iw
		make clean
		cd $WORK_SPAC
	fi
	cd $WORK_SPACE
}
function libnl ()
{
	stage=$1
	if [ x"$stage" = x"download" -o x"$stage" = "xall" ]
	then
		download http://www.infradead.org/~tgr/libnl/files/libnl-2.0.tar.gz libnl-2.0.tar.gz
		tar xzf libnl-2.0.tar.gz
		cd ${WORK_SPACE}/libnl-2.0
		./configure --prefix=${ROOTFS} CC=${CROSS_COMPILE}gcc LD=${CROSS_COMPILE}ld RANLIB=${CROSS_COMPILE}ranlib --host=arm-linux
		if [ $? != 0 ]
		then
			echo "libnl failed to be configured"
			exit 1
		fi
	fi

	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/libnl-2.0
		make || exit 1
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/libnl-2.0
		make install || exit 1
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd $WORK_SPACE/libnl-2.0
		make uninstall
		cd $WORK_SPACE
	fi
	cd $WORK_SPACE

}
function openssl ()
{
	stage=$1
	if [ x"$stage" = x"download" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}
		download "http://www.openssl.org/source/openssl-1.0.0d.tar.gz" "openssl-1.0.0d.tar.gz"
		tar xzf openssl-1.0.0d.tar.gz
		download http://processors.wiki.ti.com/images/e/ee/Openssl-1.0.0d-new-compilation-target-for-configure.zip Openssl-1.0.0d-new-compilation-target-for-configure.zip
		cd ${WORK_SPACE}/openssl-1.0.0d
		unzip ${WORK_SPACE}/Openssl-1.0.0d-new-compilation-target-for-configure.zip || exit 1
		patch -p1 -i 0001-openssl-1.0.0d-new-target-os-for-configure.patch || exit 1
		CROSS_COMPILE= perl ./Configure  shared --prefix=$ROOTFS/usr --openssldir=$ROOTFS/usr/lib/ssl linux-elf-arm
	fi || exit 1
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/openssl-1.0.0d
		make || exit 1
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/openssl-1.0.0d
		make install_sw || exit 1
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd ${WORK_SPACE}/openssl-1.0.0d
		rm -f ${ROOTFS}/usr/lib/*ssl* ${ROOTFS}/usr/lib/pkgconfig/*ssl*
		cd $WORK_SPACE && rm -rf openssl-1.0.0d
	fi
	cd $WORK_SPACE
}
function ti-utils ()
{
	stage=$1
	if [ x"$stage" = x"download" -o x"$stage" = "xall" ]
	then
		git_clone git://github.com/TI-ECS/ti-utils.git ti-utils
		cd ${WORK_SPACE}/ti-utils
		git reset --hard aaffc13e6c804291ac7dcefdcec181c0207ff67a
	fi

	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/ti-utils
		NFSROOT=${ROOTFS} make || exit 1
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/ti-utils
		NFSROOT=${ROOTFS} make install || exit 1
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd ${WORK_SPACE}/ti-utils
		NFSROOT=${ROOTFS} make clean
		rm ${ROOTFS}/home/root/calibrator ${ROOTFS}/home/root/wl12xx-tool.sh
		cd $WORK_SPACE
	fi
	cd $WORK_SPACE
}
function ti-utils-firmware()
{
	stage=$1
	 
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		mkdir -p $ROOTFS/lib/firmware/ti-connectivity
		cp ${WORK_SPACE}/ti-utils/firmware/* $ROOTFS/lib/firmware/ti-connectivity
		rm -f $ROOTFS/lib/firmware/ti-connectivity/Makefile
		cp -r ${WORK_SPACE}/ti-utils/ini_files $ROOTFS/lib/firmware/ti-connectivity
	fi
	if [ x"$stage" = "xclean" ]
	then
		rm -f $ROOTFS/lib/firmware/ti-connectivity
		rm -rf $ROOTFS/lib/firmware/ti-connectivity
		cd $WORK_SPACE
	fi
}

function hostap_patching ()
{
	[ -e ${WORK_SPACE}/hostap/patches.83fa07226deb/patches.83fa07226deb.done ] && return
	download  "http://processors.wiki.ti.com/images/8/8a/Hostapd-wpa-supplicant-patches.zip" Hostapd-wpa-supplicant-patches.zip
	mkdir patches.83fa07226deb
	cd patches.83fa07226deb && unzip ../Hostapd-wpa-supplicant-patches.zip && cd -
	for i in `$LS patches.83fa07226deb/*.patch`
	do 
		patch -p1 -i $i
		if [ $? -ne 0 ]
		then
			echo "Patch patches.83fa07226deb/$i failed. Exiting..."
			exit 1
		fi
	done
	touch patches.83fa07226deb/patches.83fa07226deb.done
}
function make_hostapd_defconfig ()
{
	cat > .config <<"hostapd_defconfig"
# Example hostapd build time configuration
# This file lists the configuration options that are used when building the
# hostapd binary. All lines starting with # are ignored. Configuration option
# lines must be commented out complete, if they are not to be included, i.e.,
# just setting VARIABLE=n is not disabling that variable.
#
# This file is included in Makefile, so variables like CFLAGS and LIBS can also
# be modified from here. In most cass, these lines should use += in order not
# to override previous values of the variables.
DESTDIR=$(ROOTFS)
#CC=$(CROSS_COMPILE)gcc
#CFLAGS += -I$(ROOTFS)/include -DCONFIG_LIBNL20
#CPPFLAGS += -DCONFIG_LIBNL20
#LIBS += -L$(ROOTFS)/lib -lnl-genl
#LIBS_p += -L$(ROOTFS)/lib
#LIBDIR = $(ROOTFS)/lib
#BINDIR = $(ROOTFS)/usr/sbin
# Driver interface for Host AP driver
CONFIG_DRIVER_HOSTAP=y
# Driver interface for drivers using the nl80211 kernel interface
CONFIG_DRIVER_NL80211=y
CONFIG_LIBNL20=y
# driver_nl80211.c requires a rather new libnl (version 1.1) which may not be
# shipped with your distribution yet. If that is the case, you need to build
# newer libnl version and point the hostapd build to use it.
LIBNL=$(ROOTFS)
CFLAGS += -I$(LIBNL)/include -I$(ROOTFS)/usr/include/
LIBS += -L$(LIBNL)/lib -L$(LIBNL)/lib  -L$(ROOTFS)/usr/lib -lssl -lcrypto -ldl
LIBS_p += -L$(LIBNL)/lib -L$(LIBNL)/lib  -L$(ROOTFS)/usr/lib -lssl -lcrypto -ldl
hostapd_defconfig
}

function hostap()
{
	stage=$1
	if [ x"$stage" = x"download" -o x"$stage" = "xall" ]
	then
		git_clone git://w1.fi/srv/git/hostap.git hostap
		cd ${WORK_SPACE}/hostap
		git reset --hard 83fa07226debc2f7082b6ccd62dbb1cd47c30472
		hostap_patching
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/hostap/hostapd
		make_hostapd_defconfig
		make clean
		make || exit 1
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/hostap/hostapd
		make install || exit 1
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd ${WORK_SPACE}/hostap/hostapd
		make clean
		cd ../wpa_supplicant
		make clean
		cd $WORK_SPACE
	fi
	cd $WORK_SPACE

}
function make_wpa_sup_defconfig ()
{
	cat > .config <<"wpa_sup_defconfig"
# Example wpa_supplicant build time configuration
DESTDIR=$(ROOTFS)
CFLAGS += -I$(ROOTFS)/usr/include/
LIBS += -L$(ROOTFS)/usr/lib
LIBS_p += -L$(ROOTFS)/usr/lib
CONFIG_WAPI=y
CONFIG_LIBNL20=y
NEED_BGSCAN=y
CONFIG_BGSCAN_LEARN=y
# Driver interface for generic Linux wireless extensions
CONFIG_DRIVER_WEXT=y
# Driver interface for Linux drivers using the nl80211 kernel interface
CONFIG_DRIVER_NL80211=y
# Driver interface for wired Ethernet drivers
CONFIG_DRIVER_WIRED=y
# Enable IEEE 802.1X Supplicant (automatically included if any EAP method is
# included)
CONFIG_IEEE8021X_EAPOL=y
# EAP-MD5
CONFIG_EAP_MD5=y
# EAP-MSCHAPv2
CONFIG_EAP_MSCHAPV2=y
# EAP-TLS
CONFIG_EAP_TLS=y
# EAL-PEAP
CONFIG_EAP_PEAP=y
# EAP-TTLS
CONFIG_EAP_TTLS=y
# EAP-GTC
CONFIG_EAP_GTC=y
# EAP-OTP
CONFIG_EAP_OTP=y
# LEAP
CONFIG_EAP_LEAP=y
# Wi-Fi Protected Setup (WPS)
CONFIG_WPS=y
# Enable WSC 2.0 support
CONFIG_WPS2=y
# PKCS#12 (PFX) support (used to read private key and certificate file from
# a file that usually has extension .p12 or .pfx)
CONFIG_PKCS12=y
# Smartcard support (i.e., private key on a smartcard), e.g., with openssl
# engine.
CONFIG_SMARTCARD=y
# Select control interface backend for external programs, e.g, wpa_cli:
# unix = UNIX domain sockets (default for Linux/*BSD)
# udp = UDP sockets using localhost (127.0.0.1)
# named_pipe = Windows Named Pipe (default for Windows)
# y = use default (backwards compatibility)
# If this option is commented out, control interface is not included in the
# build.
CONFIG_CTRL_IFACE=y
# Select configuration backend:
# file = text file (e.g., wpa_supplicant.conf; note: the configuration file
#	path is given on command line, not here; this option is just used to
#	select the backend that allows configuration files to be used)
# winreg = Windows registry (see win_example.reg for an example)
CONFIG_BACKEND=file
# PeerKey handshake for Station to Station Link (IEEE 802.11e DLS)
CONFIG_PEERKEY=y
# Add support for writing debug log to a file (/tmp/wpa_supplicant-log-#.txt)
CONFIG_DEBUG_FILE=y
LIBNL=$(ROOTFS)
CFLAGS += -I$(LIBNL)/include
LIBS += -L$(LIBNL)/lib  -lssl -lcrypto -ldl
LIBS_p += -L$(LIBNL)/lib  -lssl -lcrypto -ldl
# for p2p
CONFIG_P2P=y
CONFIG_AP=y
wpa_sup_defconfig
}
function wpa_supplicant ()
{
	stage=$1
	if [ x"$stage" = x"build" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/hostap/wpa_supplicant
		make clean
		make_wpa_sup_defconfig
		make || exit 1
	fi
	if [ x"$stage" = x"install" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/hostap/wpa_supplicant
		make install || exit 1
	fi
	cd $WORK_SPACE
}

function usage ()
{
	echo "This script compiles one of following utilities: libnl, openssl, hostapd, wpa_supplicant,wl12xx_modules,firmware,crda,calibrator"
	echo "by calling specific utility name and action."
	echo "In case the options is 'all' all utilities will be downloaded and installed on root file system."
	echo "File setup-env contains all required environment variables, for example:"
	echo "	ROOTFS=<path to target root file system>."
	echo "Part of operations requires root access."
	echo "Usage: `basename $ME` target <libnl"
	echo "                              openssl"
	echo "                              hostapd"
	echo "                              wpa_supplicant"
	echo "                              wl12xx_modules"
	echo "                              firmware"
	echo "                              crda"
	echo "                              calibrator>  action <download|build|install>"
	echo "                      all"
	echo "                      clean-all"
}

function check_libs()
{
	local openssl=`pkg-config --exists openssl`
	local libnl=`pkg-config --exists libnl`
	package=$1

	if [ $openssl -ne 0 -o $libnl -ne 0 ]
	then
		echo "Cannot build $1: openssl and libnl should be installed first."
		exit 1
	fi
}
function package_dir_exists()
{
	if [ -d "$1" ]
	then
		echo "Package $2 already downloaded at: $1"
		return 1
	fi
	return 0
}
function check_env()
{
	which dpkg 2>&1>/dev/null || return 0
	err=0
	ret=0
	packages="python python-m2crypto bash bison flex perl bc corkscrew git-core git-email git-gui git-svn gitk"
	for p in ${packages}
	do
		echo -n "Checking ${p}..."
		present=`dpkg --get-selections ${p} 2>/dev/null | awk '{print $1}'`
		[ x"${present}" != x"${p}" ] && echo "Package ${p} is not found. Please run 'apt-get install ${p}' to install it." && err=1 && ret=1
		[ ${err} -ne 1 ] && echo "OK"
		err=0
	done
	return ${ret}
}
############################# MAIN ##############################################
# First building environment should be checked
check_env || exit 1
exit
if [ -z $CROSS_COMPILE ]
then
	#lets find some
	tool_path=`which arm-none-linux-gnueabi-gcc`
	if [ $? -ne 0 ]
	then
		echo "No tool chain is found"
		exit 1
	fi	
	export CROSS_COMPILE=`dirname $tool_path`/arm-none-linux-gnueabi-
fi

if [ -z $KLIB_BUILD ]
then
	echo "Path to kernel sources has to be defined"
	exit 1
fi

if [ -z $ROOTFS ]
then
	echo "No path to root file system"
	exit 1
fi
argc=$#
if [ $argc -lt 1 ]
then
	usage
	exit 1
elif [ $argc -eq 1 ]
then
	if [ x"$1" != x"all" -a x"$1" != x"clean-all" ]
	then
		usage
		exit 1
	else
		package="$1"
	fi
fi

if [ $argc -eq 2 ]
then
	package=$1
	stage=$2
fi
if [ ! -d $WORK_SPACE ]
then
	mkdir -p $WORK_SPACE
fi
cd $WORK_SPACE

case $package in
	libnl)
		case $stage in
			download )
				package_dir_exists ${WORK_SPACE}/libnl-2.0 libnl-2 && libnl "download"
				;;
			build)
				package_dir_exists ${WORK_SPACE}/libnl-2.0 libnl-2
				if [ ! $? ]
				then
					libnl "download"
				fi
				cd ${WORK_SPACE}/libnl-2.0
				libnl "build"
				;;
			install)
				package_dir_exists ${WORK_SPACE}/libnl-2.0 libnl-2
				if [ ! $? ]
				then
					libnl "all" && exit
				else
					cd ${WORK_SPACE}/libnl-2.0
					libnl "install"
				fi
				;;
			all)
				package_dir_exists ${WORK_SPACE}/libnl-2.0 libnl-2 || rm -rf libnl-2.0
				libnl "all"
				;;
			*)
				echo "Error: illegal action for libnl"
				exit 1
		esac
		;;
	openssl)
		case $stage in
			download )
				package_dir_exists ${WORK_SPACE}/openssl-1.0.0d openssl || exit 1
				openssl "download"
				;;
			build)
				package_dir_exists ${WORK_SPACE}/openssl-1.0.0d openssl
				if [ ! $? ]
				then
					openssl "download"
				fi
				cd ${WORK_SPACE}/openssl-1.0.0d
				openssl "build"
				;;
			install)
				package_dir_exists ${WORK_SPACE}/openssl-1.0.0d openssl
				test [ ! $? ] && openssl "all" && exit 0
				cd ${WORK_SPACE}/openssl-1.0.0d
				openssl "install"
				;;
			all)
				package_dir_exists ${WORK_SPACE}/openssl-1.0.0d openssl || rm -rf openssl-1.0.0d
				openssl "all"
				;;
		esac
		;;
	iw)
		case $stage in
			download )
				package_dir_exists ${WORK_SPACE}/iw iw || exit 1
				iw "download"
				;;
			build)
				package_dir_exists ${WORK_SPACE}/iw iw
				[ ! $? ] && iw "download"
				check_libs iw
				iw "build"
				;;
			install)
				package_dir_exists ${WORK_SPACE}/iw iw
				[ ! $? ] && iw "donwload"
				[ ! -x ${WORK_SPACE}/iw/iw ] && iw "build"
				iw "install"
				;;
			all)

				package_dir_exists ${WORK_SPACE}/iw iw || rm -rf ${WORK_SPACE}/iw
				iw "all"
				;;
			*)
				echo "Error: illegal action for iw"
				exit 1
				;;
		esac
		;;
	hostapd)
		case $stage in
			download)
				package_dir_exists ${WORK_SPACE}/hostap hostapd || exit 1
				hostap "download"
				;;
			build)
				if [ ! -d ${WORK_SPACE}/hostap ]
				then
					hostap "download"
				fi
				cd ${WORK_SPACE}/hostap
				hostap "build"
				;;
			install)
				if [ ! -d ${WORK_SPACE}/hostap ]
				then
					hostap "download"
				fi
				if [ ! -e ${WORK_SPACE}/hostap/hostapd/hostapd ]
				then
					hostap "build"
				fi
				hostap "install"
				;;
			all)
				package_dir_exists ${WORK_SPACE}/hostap hostapd || rm -rf ${WORK_SPACE}/hostap
				hostap "all"
				;;
			*)
				echo "Error: illegal action for hostapd"
				exit 1
				;;
		esac
		
		;;
	wpa_supplicant)
		case $stage in
			download)
				package_dir_exists ${WORK_SPACE}/hostap wpa_supplicant || exit 1
				hostap "download"
				;;
			build)
				if [ ! -e ${WORK_SPACE}/hostap ]
				then
					hostap "download"
				fi
				wpa_supplicant "build"
				;;
			install)
				if [ ! -e ${WORK_SPACE}/hostap ]
				then
					hostap "download"
				fi
				if [ ! -e ${WORK_SPACE}/hostap/wpa_supplicant/wpa_supplicant ]
				then
					wpa_supplicant "build"
				fi
				wpa_supplicant "install"
				;;
			*)
				echo "Error: illegal action for hostapd"
				exit 1
				;;
		esac
		;;
	wl12xx_modules)
		case $stage in
			download)
				package_dir_exists ${WORK_SPACE}/compat-wireless compat-wireless || exit 1
				compat-wireless "download"
				;;
			build)
				if [ ! -d ${WORK_SPACE}/compat-wireless ]
				then
					compat-wireless "download"
				fi
				cd ${WORK_SPACE}/compat-wireless
				compat-wireless "build"
				;;
			install)
				if [ ! -d ${WORK_SPACE}/compat-wireless ]
				then
					compat-wireless "all"
				else
					cd ${WORK_SPACE}/compat-wireless
					compat-wireless "install"
				fi
				;;
			all)
				package_dir_exists ${WORK_SPACE}/compat-wireless compat-wireless || rm -rf ${WORK_SPACE}/compat-wireless
				compat-wireless "all"
				;;
			*)
				echo "Error: illegal action for hostapd"
				exit 1
				;;
		esac

		;;
	calibrator)
		case $stage in
			download)
				if [ -d ${WORK_SPACE}/ti-utils ]
				then
					echo "Calibrator is part of ti-utils package that already exists at: ${WORK_SPACE}/ti-utils"
					exit 0
				fi
				ti-utils "download"
				;;
			build)
				if [ ! -d ${WORK_SPACE}/ti-utils ]
				then
					ti-utils "download"
				fi
				cd ${WORK_SPACE}/ti-utils
				ti-utils "build"
				;;
			install)
				if [ ! -d ${WORK_SPACE}/ti-utils ]
				then
					ti-utils "all"
				else
					if [ ! -e ${WORK_SPACE}/ti-utils/calibrator ]
					then
						ti-utils "build"
					fi
					ti-utils "install"
				fi
				;;
			all)
				ti-utils "all"
				;;
			*)
				echo "Error: illegal action for calibrator"
				exit 1
				;;
		esac
		;;
	firmware)
		if [ x$stage != "xinstall" ]
		then
			echo "illegal action for firmware"
			exit 1
		fi
		if [ ! -d ti-utils/firmware ]
		then
			ti-utils "download"
		fi
		ti-utils-firmware
		;;
	crda)
		case $stage in
			download)
				package_dir_exists ${WORK_SPACE}/crda-1.1.1 crda || exit 1
				crda "download"
				;;
			build)
				if [ ! -d ${WORK_SPACE}/crda-1.1.1 ]
				then
					crda "download"
				fi
				cd ${WORK_SPACE}/crda-1.1.1
				crda "build"
				;;
			install)
				if [ ! -d ${WORK_SPACE}/crda-1.1.1 ]
				then
					crda "all"
				else
					cd ${WORK_SPACE}/crda-1.1.1
					crda "install"
				fi
				;;
			all)
				package_dir_exists ${WORK_SPACE}/crda-1.1.1 crda || rm -rf ${WORK_SPACE}/crda-1.1.1
				crda "all"
				;;
			*)
				echo "Error: illegal action for crda"
				exit 1
				;;
		esac
		;;
	all)
		libnl "all"
		openssl "all"
		iw "all"
		hostap "all"
		wpa_supplicant "all"
		crda "all"
		ti-utils "all"
		ti-utils-firmware
		compat-wireless "all"
		;;
	clean-all)
		compat-wireless "clean"
		ti-utils "clean"
		crda "clean"
		hostap "clean"
		iw "clean"
		openssl "clean"
		libnl "clean"
		;;
	*)
		usage
		exit 1
esac
