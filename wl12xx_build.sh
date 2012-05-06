#!/bin/bash

if [ ! -e setup-env ]
then
	echo "No setup-env"
	exit 1
fi
source setup-env
unset PKG_CONFIG_SYSROOT_DIR
ME=$0
components="libnl openssl iw hostap wpa_supplicant crda ti-utils ti-utils-firmware compat-wireless"

function download ()
{
	file="$2"
	[ -e ${top_dir}/${file} ] && echo "File $file already exists. Skipping download." && return 0
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
	[ -e ${top_dir}/${file} ] && echo "File $file alread exists. Skipping git clone." && return 0
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
		https://gforge.ti.com/gf/download/frsrelease/801/5434/ti-compat-wireless-wl12xx-2012-02-06-r4-12.tgz
		tar xzf ti-compat-wireless-wl12xx-2012-02-06-r4-12.tgz
		cd ${top_dir}/compat-wireless
		download http://processors.wiki.ti.com/images/a/aa/Compat-wireless-patches.zip Compat-wireless-patches.zip
		mkdir tmp-patches
		cd tmp-patches
		unzip ../Compat-wireless-patches.zip && cd -
		for i in `$LS tmp-patches`; do patch -p1 -i tmp-patches/$i || exit 1; done
		res=`./scripts/driver-select wl12xx`
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/compat-wireless
		make KLIB_BUILD=${KLIB_BUILD} KLIB=${NFSROOT} || exit 1
	fi
	if [ x"$stage" = "xinstall"  -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/compat-wireless
		sudo -E make KLIB=${NFSROOT} install || exit 1
	fi

	if [ x"$stage" = "xclean" ]
	then
		cd $top_dir/compat-wireless
		make KLIB=${NFSROOT} uninstall
		cd $top_dir && rm -rf compat-wireless ti-compat-wireless-wl12xx-r4-12-12-20.tar.gz
	fi

	cd $top_dir
}
function crda ()
{
	stage=$1
	if [ x"$stage" = "xdownload"  -o x"$stage" = "xall" ]
	then
		download "http://wireless.kernel.org/download/crda/crda-1.1.1.tar.bz2" "crda-1.1.1.tar.bz2"
		tar xjf crda-1.1.1.tar.bz2
		cd ${top_dir}/crda-1.1.1
		download http://linuxwireless.org/download/wireless-regdb/regulatory.bins/2011.04.28-regulatory.bin 2011.04.28-regulatory.bin
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/crda-1.1.1
		make USE_OPENSSL=1 all_noverify || exit 1
	fi
	if [ x"$stage" = "xinstall"  -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/crda-1.1.1
		sudo -E DESTDIR=${NFSROOT} make USE_OPENSSL=1 install || exit 1
		sudo mkdir -p ${NFSROOT}/usr/lib/crda
		sudo -E cp 2011.04.28-regulatory.bin ${NFSROOT}/usr/lib/crda/regulatory.bin
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd $top_dir/crda-1.1.1
		sudo -E make uninstall
		cd $top_dir && rm -rf crda-1.1.1 crda-1.1.1.tar.bz2
	fi
	cd $top_dir
}

function iw ()
{
	stage=$1
	if [ x"$stage" = "xdownload"  -o x"$stage" = "xall" ]
	then
		git_clone git://git.sipsolutions.net/iw.git iw
		cd ${top_dir}/iw
		git reset --hard 0a236ef5f8e4ba7218aac7d0cdacf45673d5b35c || exit 1
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/iw
		make || exit 1
	fi

	if [ x"$stage" = "xinstall"  -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/iw
		sudo -E make install || exit 1
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd $top_dir/iw
		sudo -E make uninstall
		cd $top_dir && rm -rf iw
	fi
	cd $top_dir
}
function libnl ()
{
	stage=$1
	if [ x"$stage" = x"download" -o x"$stage" = "xall" ]
	then
		download http://www.infradead.org/~tgr/libnl/files/libnl-2.0.tar.gz libnl-2.0.tar.gz
		tar xzf libnl-2.0.tar.gz
		cd ${top_dir}/libnl-2.0
		./configure --prefix=${NFSROOT} CC=${CROSS_COMPILE}gcc LD=${CROSS_COMPILE}ld RANLIB=${CROSS_COMPILE}ranlib --host=arm-linux
		if [ $? != 0 ]
		then
			echo "libnl failed to be configured"
			exit 1
		fi
	fi

	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/libnl-2.0
		make || exit 1
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/libnl-2.0
		sudo -E make install || exit 1
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd $top_dir/libnl-2.0
		sudo -E make uninstall
		cd $top_dir && rm -rf libnl-2.0 libnl-2.0.tar.gz
	fi
	cd $top_dir

}
function openssl ()
{
	stage=$1
	if [ x"$stage" = x"download" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}
		download "http://www.openssl.org/source/openssl-1.0.0d.tar.gz" "openssl-1.0.0d.tar.gz"
		tar xzf openssl-1.0.0d.tar.gz
		cd ${top_dir}/openssl-1.0.0d
		download http://processors.wiki.ti.com/images/e/ee/Openssl-1.0.0d-new-compilation-target-for-configure.zip Openssl-1.0.0d-new-compilation-target-for-configure.zip
		unzip Openssl-1.0.0d-new-compilation-target-for-configure.zip
		patch -p1 -i 0001-openssl-1.0.0d-new-target-os-for-configure.patch || exit 1
		CROSS_COMPILE= perl ./Configure  shared --prefix=$NFSROOT/usr --openssldir=$NFSROOT/usr/lib/ssl linux-elf-arm
	fi || exit 1
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/openssl-1.0.0d
		make || exit 1
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/openssl-1.0.0d
		sudo -E make install || exit 1
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd ${top_dir}/openssl-1.0.0d
		sudo -E make uninstall
		cd $top_dir && rm -rf openssl-1.0.0d openssl-1.0.0d.tar.gz
	fi
	cd $top_dir
}
function ti-utils ()
{
	stage=$1
	if [ x"$stage" = x"download" -o x"$stage" = "xall" ]
	then
		git_clone git://github.com/TI-ECS/ti-utils.git ti-utils
		cd ${top_dir}/ti-utils
		git reset --hard aaffc13e6c804291ac7dcefdcec181c0207ff67a
	fi

	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/ti-utils
		make || exit 1
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/ti-utils
		sudo -E make install || exit 1
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd ${top_dir}/ti-utils
		sudo -E make uninstall
		cd $top_dir && rm -rf ti-utils
	fi
	cd $top_dir
}
function ti-utils-firmware()
{
	stage=$1
	 
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		sudo -E mkdir -p $NFSROOT/lib/firmware/ti-connectivity
		sudo cp ${top_dir}/ti-utils/firmware/* $NFSROOT/lib/firmware/ti-connectivity
		sudo rm -f $NFSROOT/lib/firmware/ti-connectivity/Makefile
		sudo cp -r ${top_dir}/ti-utils/ini_files $NFSROOT/lib/firmware/ti-connectivity
	fi
	if [ x"$stage" = "xclean" ]
	then
		if [ -d ${top_dir}/ti-utils ]
		then
			cd ${top_dir}/ti-utils
			sudo -E make uninstall
			cd $top_dir && rm -rf ti-utils
		fi
	fi
}

function hostap_patching ()
{
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
DESTDIR=$(NFSROOT)
#CC=$(CROSS_COMPILE)gcc
#CFLAGS += -I$(NFSROOT)/include -DCONFIG_LIBNL20
#CPPFLAGS += -DCONFIG_LIBNL20
#LIBS += -L$(NFSROOT)/lib -lnl-genl
#LIBS_p += -L$(NFSROOT)/lib
#LIBDIR = $(NFSROOT)/lib
#BINDIR = $(NFSROOT)/usr/sbin
# Driver interface for Host AP driver
CONFIG_DRIVER_HOSTAP=y
# Driver interface for drivers using the nl80211 kernel interface
CONFIG_DRIVER_NL80211=y
CONFIG_LIBNL20=y
# driver_nl80211.c requires a rather new libnl (version 1.1) which may not be
# shipped with your distribution yet. If that is the case, you need to build
# newer libnl version and point the hostapd build to use it.
LIBNL=$(NFSROOT)
CFLAGS += -I$(LIBNL)/include -I$(NFSROOT)/usr/include/
LIBS += -L$(LIBNL)/lib -L$(LIBNL)/lib  -L$(NFSROOT)/usr/lib -lssl -lcrypto -ldl
LIBS_p += -L$(LIBNL)/lib -L$(LIBNL)/lib  -L$(NFSROOT)/usr/lib -lssl -lcrypto -ldl
hostapd_defconfig
}

function hostap()
{
	stage=$1
	if [ x"$stage" = x"download" -o x"$stage" = "xall" ]
	then
		git_clone git://w1.fi/srv/git/hostap.git hostap
		cd ${top_dir}/hostap
		git reset --hard 83fa07226debc2f7082b6ccd62dbb1cd47c30472
		hostap_patching
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/hostap/hostapd
		make_hostapd_defconfig
		make clean
		make || exit 1
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/hostap/hostapd
		sudo -E make install || exit 1
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd ${top_dir}/hostap/hostapd
		sudo -E make uninstall
		cd ../wpa_supplicant
		sudo -E make uninstall
		cd $top_dir && rm -rf hostap
	fi
	cd $top_dir

}
function make_wpa_sup_defconfig ()
{
	cat > .config <<"wpa_sup_defconfig"
# Example wpa_supplicant build time configuration
DESTDIR=$(NFSROOT)
CFLAGS += -I$(NFSROOT)/usr/include/
LIBS += -L$(NFSROOT)/usr/lib
LIBS_p += -L$(NFSROOT)/usr/lib
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
LIBNL=$(NFSROOT)
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
		cd ${top_dir}/hostap/wpa_supplicant
		make clean
		make_wpa_sup_defconfig
		make || exit 1
	fi
	if [ x"$stage" = x"install" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/hostap/wpa_supplicant
		sudo -E make install || exit 1
	fi
	cd $top_dir
}

function usage ()
{
	echo "This script compiles one of following utilities: libnl, openssl, hostapd, wpa_supplicant,wl12xx_modules,firmware,crda,calibrator"
	echo "by calling specific utility name and action."
	echo "In case the options is 'all' all utilities will be downloaded and installed on root file system."
	echo "File setup-env contains all required environment variables, for example:"
	echo "	NFSROOT=<path to target root file system>."
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
############################# MAIN ##############################################
# First building environment should be checked
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

if [ -z $NFSROOT ]
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
if [ ! -d $top_dir ]
then
	mkdir -p $top_dir
fi
cd $top_dir

case $package in
	libnl)
		case $stage in
			download )
				package_dir_exists ${top_dir}/libnl-2.0 libnl-2 && libnl "download"
				;;
			build)
				package_dir_exists ${top_dir}/libnl-2.0 libnl-2
				if [ ! $? ]
				then
					libnl "download"
				fi
				cd ${top_dir}/libnl-2.0
				libnl "build"
				;;
			install)
				package_dir_exists ${top_dir}/libnl-2.0 libnl-2
				if [ ! $? ]
				then
					libnl "all" && exit
				else
					cd ${top_dir}/libnl-2.0
					libnl "install"
				fi
				;;
			all)
				package_dir_exists ${top_dir}/libnl-2.0 libnl-2 || rm -rf libnl-2.0
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
				package_dir_exists ${top_dir}/openssl-1.0.0d openssl || exit 1
				openssl "download"
				;;
			build)
				package_dir_exists ${top_dir}/openssl-1.0.0d openssl
				if [ ! $? ]
				then
					openssl "download"
				fi
				cd ${top_dir}/openssl-1.0.0d
				openssl "build"
				;;
			install)
				package_dir_exists ${top_dir}/openssl-1.0.0d openssl
				test [ ! $? ] && openssl "all" && exit 0
				cd ${top_dir}/openssl-1.0.0d
				openssl "install"
				;;
			all)
				package_dir_exists ${top_dir}/openssl-1.0.0d openssl || rm -rf openssl-1.0.0d
				openssl "all"
				;;
		esac
		;;
	iw)
		case $stage in
			download )
				package_dir_exists ${top_dir}/iw iw || exit 1
				iw "download"
				;;
			build)
				package_dir_exists ${top_dir}/iw iw
				[ ! $? ] && iw "download"
				check_libs iw
				iw "build"
				;;
			install)
				package_dir_exists ${top_dir}/iw iw
				[ ! $? ] && iw "donwload"
				[ ! -x ${top_dir}/iw/iw ] && iw "build"
				iw "install"
				;;
			all)

				package_dir_exists ${top_dir}/iw iw || rm -rf ${top_dir}/iw
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
				package_dir_exists ${top_dir}/hostap hostapd || exit 1
				hostap "download"
				;;
			build)
				if [ ! -d ${top_dir}/hostap ]
				then
					hostap "download"
				fi
				cd ${top_dir}/hostap
				hostap "build"
				;;
			install)
				if [ ! -d ${top_dir}/hostap ]
				then
					hostap "download"
				fi
				if [ ! -e ${top_dir}/hostap/hostapd/hostapd ]
				then
					hostap "build"
				fi
				hostap "install"
				;;
			all)
				package_dir_exists ${top_dir}/hostap hostapd || rm -rf ${top_dir}/hostap
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
				package_dir_exists ${top_dir}/hostap wpa_supplicant || exit 1
				hostap "download"
				;;
			build)
				if [ ! -e ${top_dir}/hostap ]
				then
					hostap "download"
				fi
				wpa_supplicant "build"
				;;
			install)
				if [ ! -e ${top_dir}/hostap ]
				then
					hostap "download"
				fi
				if [ ! -e ${top_dir}/hostap/wpa_supplicant/wpa_supplicant ]
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
				package_dir_exists ${top_dir}/compat-wireless compat-wireless || exit 1
				compat-wireless "download"
				;;
			build)
				if [ ! -d ${top_dir}/compat-wireless ]
				then
					compat-wireless "download"
				fi
				cd ${top_dir}/compat-wireless
				compat-wireless "build"
				;;
			install)
				if [ ! -d ${top_dir}/compat-wireless ]
				then
					compat-wireless "all"
				else
					cd ${top_dir}/compat-wireless
					compat-wireless "install"
				fi
				;;
			all)
				package_dir_exists ${top_dir}/compat-wireless compat-wireless || rm -rf ${top_dir}/compat-wireless
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
				if [ -d ${top_dir}/ti-utils ]
				then
					echo "Calibrator is part of ti-utils package that already exists at: ${top_dir}/ti-utils"
					exit 0
				fi
				ti-utils "download"
				;;
			build)
				if [ ! -d ${top_dir}/ti-utils ]
				then
					ti-utils "download"
				fi
				cd ${top_dir}/ti-utils
				ti-utils "build"
				;;
			install)
				if [ ! -d ${top_dir}/ti-utils ]
				then
					ti-utils "all"
				else
					if [ ! -e ${top_dir}/ti-utils/calibrator ]
					then
						ti-utils "build"
					fi
					ti-utils "install"
				fi
				;;
			*)
				echo "Error: illegal action for hostapd"
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
				package_dir_exists ${top_dir}/crda-1.1.1 crda || exit 1
				crda "download"
				;;
			build)
				if [ ! -d ${top_dir}/crda-1.1.1 ]
				then
					crda "download"
				fi
				cd ${top_dir}/crda-1.1.1
				crda "build"
				;;
			install)
				if [ ! -d ${top_dir}/crda-1.1.1 ]
				then
					crda "all"
				else
					cd ${top_dir}/crda-1.1.1
					crda "install"
				fi
				;;
			all)
				package_dir_exists ${top_dir}/crda-1.1.1 crda || rm -rf ${top_dir}/crda-1.1.1
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
		for p in $components
		do
			$p clean
		done
		;;
	*)
		usage
		exit 1
esac
