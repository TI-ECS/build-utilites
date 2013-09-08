#!/bin/bash

declare -A wl18xx_download_target="git://github.com/TI-OpenLink/wl18xx.git"
declare -A wl18xx_tag="ol_r8.a7.02"

declare -A compatwireless_download_target="git://github.com/TI-OpenLink/compat-wireless.git"
declare -A compat_wireless_tag="ol_r8.a7.02_34"

declare -A compat_download_target="git://github.com/TI-OpenLink/compat.git"
declare -A compat_tag="ol_r8.a7.02"

declare -A ti_utils_download_target="git://github.com/TI-OpenLink/18xx-ti-utils.git"
declare -A ti_utils_tag="ol_r8.a7.02"

declare -A wl18xx_fw_download_target="git://github.com/TI-OpenLink/wl18xx_fw.git"
declare -A wl18xx_fw_tag="ol_r8.a7.02"

declare -A hostap_download_target="git://github.com/TI-OpenLink/hostap.git"
declare -A hostap_tag="ol_r8.a7.02"

declare -A iw_download_target="git://git.sipsolutions.net/iw.git"
declare -A iw_tag="0a236ef5f8e4ba7218aac7d0cdacf45673d5b35c"

if [ ! -e setup-env ]
then
	echo "No setup-env"
	exit 1
fi
source setup-env

export GIT_TREE=${WORK_SPACE}/wl18xx
export GIT_COMPAT_TREE=${WORK_SPACE}/compat

unset PKG_CONFIG_SYSROOT_DIR
ME=$0
components="libnl openssl iw hostap wpa_supplicant crda ti-utils wl18xx-firmware compat-wireless"

old_dir=`pwd`

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
	if [ -e ${WORK_SPACE}/${file} ]
	then
		echo "File $file alread exists. Skipping git clone."
		cd ${WORK_SPACE}/${file}
		git fetch || exit 1
		echo "git $file fetched."
		return 0
	fi
	git clone "$1"
	if [ $? -ne 0 ]
	then
		echo "Failed to download $2 git repository"
		exit 1
	fi
	echo "git $file cloned."
}

function compat-wireless()
{
	stage=$1

	if [ x"$stage" = "xdownload"  -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}
		git_clone ${wl18xx_download_target} wl18xx
		cd ${WORK_SPACE}/wl18xx
		git reset --hard ${wl18xx_tag} || exit 1
		cd ${WORK_SPACE}
		git_clone ${compat_download_target} compat
		cd ${WORK_SPACE}/compat
		git reset --hard ${compat_tag} || exit 1
		cd ${WORK_SPACE}
		git_clone ${compatwireless_download_target} compat-wireless
		cd ${WORK_SPACE}/compat-wireless
		git reset --hard ${compat_wireless_tag} || exit 1
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/compat-wireless
		./scripts/admin-refresh.sh network
		./scripts/driver-select wl18xx
		echo "# Use platform data with kernels older then 3.8 that dont use DT" >> config.mk
		echo "export CONFIG_WILINK_PLATFORM_DATA=y" >> config.mk
		make KLIB_BUILD=${KLIB_BUILD} KLIB=${ROOTFS} || exit 1
	fi
	if [ x"$stage" = "xinstall"  -o x"$stage" = "xall" ]
	then
		find ${ROOTFS} -name "wl12xx*.ko" | xargs rm -f
		find ${ROOTFS} -name "mac80211.ko" | xargs rm -f
		find ${ROOTFS} -name "cfg80211.ko" | xargs rm -f
		find ${ROOTFS} -name "compat.ko" | xargs rm -f
		cd ${WORK_SPACE}/compat-wireless
		make KLIB_BUILD=${KLIB_BUILD} KLIB=${ROOTFS} install-modules
	fi

	if [ x"$stage" = "xclean" ]
	then
		cd $WORK_SPACE/compat-wireless
		make KLIB_BUILD=${KLIB_BUILD} KLIB=${ROOTFS} clean || exit 1
#		cd $WORK_SPACE && rm -rf compat-wireless
	fi

	cd $WORK_SPACE
}
function crda ()
{
	stage=$1
	if [ x"$stage" = "xdownload"  -o x"$stage" = "xall" ]
	then
		download "http://wireless.kernel.org/download/crda/crda-1.1.1.tar.bz2" "crda-1.1.1.tar.bz2"
                download "http://linuxwireless.org/download/wireless-regdb/regulatory.bins/2011.04.28-regulatory.bin" "2011.04.28-regulatory.bin"
		tar xjf crda-1.1.1.tar.bz2
		cd ${WORK_SPACE}/crda-1.1.1
		cp ${WORK_SPACE}/2011.04.28-regulatory.bin .
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
		git_clone ${iw_download_target} iw
		cd ${WORK_SPACE}/iw
		git reset --hard ${iw_tag} || exit 1
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
		cd .. && rm -rf libnl-2.0
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
		cd ${WORK_SPACE}/openssl-1.0.0d
		patch -p1 -i ${old_dir}/patches/0001-openssl-1.0.0d-new-target-os-for-configure.patch || exit 1
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
		cd .. && rm -rf openssl-1.0.0d
	fi
	cd $WORK_SPACE
}
function ti-utils ()
{
	stage=$1

	if [ x"$stage" = x"download" -o x"$stage" = "xall" ]
	then
		git_clone "${ti_utils_download_target}" 18xx-ti-utils
		cd ${WORK_SPACE}/18xx-ti-utils
		git reset --hard "${ti_utils_tag}" || exit 1
	fi

	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/18xx-ti-utils
		NFSROOT=${ROOTFS} make || exit 1
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/18xx-ti-utils
		#NFSROOT=${ROOTFS} make install || exit 1
		if [ ! -x calibrator ]
		then
			echo "calibrator is not built, run 'make' first"
			exit 1
		fi
		cp -f ./calibrator ${ROOTFS}/usr/bin
		chmod 755 ${ROOTFS}/usr/bin/calibrator
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd ${WORK_SPACE}/18xx-ti-utils
		NFSROOT=${ROOTFS} make clean
		rm -f ${ROOTFS}/usr/bin/calibrator
		cd ${WORK_SPACE}/18xx-ti-utils/wlconf
		NFSROOT=${ROOTFS} make clean
		rm -fr ${ROOTFS}/usr/sbin/wlconf
		rm -fr ${ROOTFS}/home/root/scripts/wlconf/
	fi
	cd $WORK_SPACE
}

function wl18xx-firmware()
{
	stage=$1
	 
	if [ x"$stage" = x"download" -o x"$stage" = "xall" ]
	then
		git_clone "${wl18xx_fw_download_target}" wl18xx_fw
		cd ${WORK_SPACE}/wl18xx_fw
		git reset --hard "${wl18xx_fw_tag}"
	fi

	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		mkdir -p $ROOTFS/lib/firmware/ti-connectivity
		cp ${WORK_SPACE}/wl18xx_fw/*.bin $ROOTFS/lib/firmware/ti-connectivity
	fi
	if [ x"$stage" = "xclean" ]
	then
		rm -rf $ROOTFS/lib/firmware/ti-connectivity
	fi
	cd $WORK_SPACE
}

function make_hostapd_defconfig ()
{
	cat > .config <<"hostapd_defconfig"
# Example hostapd build time configuration
#
# This file lists the configuration options that are used when building the
# hostapd binary. All lines starting with # are ignored. Configuration option
# lines must be commented out complete, if they are not to be included, i.e.,
# just setting VARIABLE=n is not disabling that variable.
#
# This file is included in Makefile, so variables like CFLAGS and LIBS can also
# be modified from here. In most cass, these lines should use += in order not
# to override previous values of the variables.

DESTDIR=$(ROOTFS)
# Driver interface for Host AP driver
CONFIG_DRIVER_HOSTAP=y

# Driver interface for wired authenticator
#CONFIG_DRIVER_WIRED=y

# Driver interface for drivers using the nl80211 kernel interface
CONFIG_DRIVER_NL80211=y
CONFIG_LIBNL20=y
# driver_nl80211.c requires a rather new libnl (version 1.1) which may not be
# shipped with your distribution yet. If that is the case, you need to build
# newer libnl version and point the hostapd build to use it.
#LIBNL=/usr/src/libnl
#CFLAGS += -I$(LIBNL)/include
#LIBS += -L$(LIBNL)/lib

# Driver interface for FreeBSD net80211 layer (e.g., Atheros driver)
#CONFIG_DRIVER_BSD=y
#CFLAGS += -I/usr/local/include
#LIBS += -L/usr/local/lib
#LIBS_p += -L/usr/local/lib
#LIBS_c += -L/usr/local/lib

# Driver interface for no driver (e.g., RADIUS server only)
#CONFIG_DRIVER_NONE=y

# IEEE 802.11F/IAPP
CONFIG_IAPP=y

# WPA2/IEEE 802.11i RSN pre-authentication
CONFIG_RSN_PREAUTH=y

# PeerKey handshake for Station to Station Link (IEEE 802.11e DLS)
CONFIG_PEERKEY=y

# IEEE 802.11w (management frame protection)
# This version is an experimental implementation based on IEEE 802.11w/D1.0
# draft and is subject to change since the standard has not yet been finalized.
# Driver support is also needed for IEEE 802.11w.
#CONFIG_IEEE80211W=y

# Integrated EAP server
CONFIG_EAP=y

# EAP-MD5 for the integrated EAP server
CONFIG_EAP_MD5=y

# EAP-TLS for the integrated EAP server
CONFIG_EAP_TLS=y

# EAP-MSCHAPv2 for the integrated EAP server
CONFIG_EAP_MSCHAPV2=y

# EAP-PEAP for the integrated EAP server
CONFIG_EAP_PEAP=y

# EAP-GTC for the integrated EAP server
CONFIG_EAP_GTC=y

# EAP-TTLS for the integrated EAP server
CONFIG_EAP_TTLS=y

# EAP-SIM for the integrated EAP server
#CONFIG_EAP_SIM=y

# EAP-AKA for the integrated EAP server
#CONFIG_EAP_AKA=y

# EAP-AKA' for the integrated EAP server
# This requires CONFIG_EAP_AKA to be enabled, too.
#CONFIG_EAP_AKA_PRIME=y

# EAP-PAX for the integrated EAP server
#CONFIG_EAP_PAX=y

# EAP-PSK for the integrated EAP server (this is _not_ needed for WPA-PSK)
#CONFIG_EAP_PSK=y

# EAP-SAKE for the integrated EAP server
#CONFIG_EAP_SAKE=y

# EAP-GPSK for the integrated EAP server
#CONFIG_EAP_GPSK=y
# Include support for optional SHA256 cipher suite in EAP-GPSK
#CONFIG_EAP_GPSK_SHA256=y

# EAP-FAST for the integrated EAP server
# Note: Default OpenSSL package does not include support for all the
# functionality needed for EAP-FAST. If EAP-FAST is enabled with OpenSSL,
# the OpenSSL library must be patched (openssl-0.9.9-session-ticket.patch)
# to add the needed functions.
#CONFIG_EAP_FAST=y

# Wi-Fi Protected Setup (WPS)
CONFIG_WPS=y
# Enable WSC 2.0 support
CONFIG_WPS2=y
# Enable UPnP support for external WPS Registrars
CONFIG_WPS_UPNP=y

# EAP-IKEv2
#CONFIG_EAP_IKEV2=y

# Trusted Network Connect (EAP-TNC)
#CONFIG_EAP_TNC=y

# PKCS#12 (PFX) support (used to read private key and certificate file from
# a file that usually has extension .p12 or .pfx)
CONFIG_PKCS12=y

# RADIUS authentication server. This provides access to the integrated EAP
# server from external hosts using RADIUS.
#CONFIG_RADIUS_SERVER=y

# Build IPv6 support for RADIUS operations
CONFIG_IPV6=y

# IEEE Std 802.11r-2008 (Fast BSS Transition)
#CONFIG_IEEE80211R=y

# Use the hostapd's IEEE 802.11 authentication (ACL), but without
# the IEEE 802.11 Management capability (e.g., madwifi or FreeBSD/net80211)
#CONFIG_DRIVER_RADIUS_ACL=y

# IEEE 802.11n (High Throughput) support
CONFIG_IEEE80211N=y

# Remove debugging code that is printing out debug messages to stdout.
# This can be used to reduce the size of the hostapd considerably if debugging
# code is not needed.
#CONFIG_NO_STDOUT_DEBUG=y

# Remove support for RADIUS accounting
#CONFIG_NO_ACCOUNTING=y

# Remove support for RADIUS
#CONFIG_NO_RADIUS=y

# Remove support for VLANs
#CONFIG_NO_VLAN=y

# Remove support for dumping state into a file on SIGUSR1 signal
# This can be used to reduce binary size at the cost of disabling a debugging
# option.
#CONFIG_NO_DUMP_STATE=y

CONFIG_NO_RANDOM_POOL=y
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
		cd ${WORK_SPACE}
		git_clone "${hostap_download_target}" hostap
		cd ${WORK_SPACE}/hostap
		git reset --hard "${hostap_tag}"
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/hostap/hostapd
		make_hostapd_defconfig
		make clean || exit 1
		make || exit 1
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/hostap/hostapd
		make install || exit 1
		for i in hostapd hostapd_cli; do cp -f $i ${ROOTFS}/usr/sbin/$i || exit 1; done
		cp hostapd.conf ${ROOTFS}/etc/ 
	fi
	if [ x"$stage" = "xclean" ]
	then
		cd ${WORK_SPACE}/hostap/hostapd
		make clean
		cd ../wpa_supplicant
		make clean
	fi
	cd $WORK_SPACE

}

function make_wpa_sup_defconfig()
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
# IEEE 802.11n (High Throughput) support
CONFIG_IEEE80211N=y
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
		for i in wpa_supplicant wpa_cli wpa_passphrase; do cp $i ${ROOTFS}/usr/sbin//$i || exit 1; done
		cp ${old_dir}/scripts/wpa_supplicant/wpa_supplicant.conf ${ROOTFS}/etc/ 
	fi
	cd $WORK_SPACE
}

function wlconf ()
{
	stage=$1
	if [ x"$stage" = x"build" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/18xx-ti-utils/wlconf
		NFSROOT=${ROOTFS} make || exit 1
	fi
	if [ x"$stage" = x"install" -o x"$stage" = "xall" ]
	then
		cd ${WORK_SPACE}/18xx-ti-utils/wlconf
		if [ ! -x wlconf ]
		then
			echo "wlconf is not built, run 'make' first"
			exit 1
		fi
		mkdir -p ${ROOTFS}/usr/sbin/wlconf
		mkdir -p ${ROOTFS}/usr/sbin/wlconf/official_inis
		cp -f ./wlconf ${ROOTFS}/usr/sbin/wlconf
		chmod 755 ${ROOTFS}/usr/sbin/wlconf
		for i in dictionary.txt struct.bin wl18xx-conf-default.bin README example.conf example.ini; do cp $i ${ROOTFS}/usr/sbin/wlconf/$i || exit 1; done
		cp official_inis/* ${ROOTFS}/usr/sbin/wlconf/official_inis
		mkdir -p ${ROOTFS}/home/root/scripts/wlconf
		cp ${old_dir}/scripts/wlconf/* ${ROOTFS}/home/root/scripts/wlconf
		chmod 755 ${ROOTFS}/home/root/scripts/wlconf/*
	fi
	cd $WORK_SPACE
}

function usage ()
{
	echo "This script compiles one of following utilities: libnl, openssl, hostapd, wpa_supplicant,wl18xx_modules,firmware,crda,calibrator,wlconf"
	echo "by calling specific utility name and action."
	echo "In case the options is 'all' all utilities will be downloaded and installed on root file system."
	echo "File setup-env contains all required environment variables, for example:"
	echo "	ROOTFS=<path to target root file system>."
	echo "Part of operations requires root access."
	echo "Usage: `basename $ME` target <libnl"
	echo "                              openssl"
	echo "                              hostapd"
	echo "                              wpa_supplicant"
	echo "                              wl18xx_modules"
	echo "                              firmware"
	echo "                              crda"
	echo "                              wlconf"
	echo "                              calibrator>  action <download|build|install>"
	echo "                      all"
	echo "                      clean-all"
}

function check_libs()
{
	local openssl=`pkg-config --exists openssl`
	local libnl=`pkg-config --exists libnl-2.0`
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
	[ -e ${WORK_SPACE}/.check_env.stamp ] && return 0
	which dpkg 2>&1>/dev/null || return 0
	err=0
	ret=0
	packages="python python-m2crypto bash bison flex perl bc corkscrew"
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
	touch ${WORK_SPACE}/.check_env.stamp
fi
cd ${WORK_SPACE}

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
	wl18xx_modules)
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
				echo "Error: illegal action for wl18xx_modules"
				exit 1
				;;
		esac

		;;
	calibrator)
		case $stage in
			download)
				if [ -d ${WORK_SPACE}/ti-utils ]
				then
					echo "Calibrator is part of ti-utils package that already exists at: ${WORK_SPACE}/18xx-ti-utils"
					exit 0
				fi
				ti-utils "download"
				;;
			build)
				if [ ! -d ${WORK_SPACE}/18xx-ti-utils ]
				then
					ti-utils "download"
				fi
				cd ${WORK_SPACE}/ti-utils
				ti-utils "build"
				;;
			install)
				if [ ! -d ${WORK_SPACE}/18xx-ti-utils ]
				then
					ti-utils "all"
				else
					if [ ! -e ${WORK_SPACE}/18xx-ti-utils/calibrator ]
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
	wlconf)
		case $stage in
			download)
				if [ ! -d ${WORK_SPACE}/18xx-ti-utils ]
				then
					ti-utils "download"
				fi
				;;
			build)
				if [ ! -d ${WORK_SPACE}/18xx-ti-utils ]
				then
					ti-utils "download"
				fi
				wlconf "build"
				;;
			install)
				if [ ! -d ${WORK_SPACE}/18xx-ti-utils ]
				then
					ti-utils "download"
				fi
				if [ ! -e ${WORK_SPACE}/18xx-ti-utils/wlconf/wlconf ]
				then
					wlconf "build"
				fi
				wlconf "install"
				;;
			all)
				wlconf "all"
				;;
			*)
				echo "Error: illegal action for wlconf"
				exit 1
				;;
		esac
		;;
	firmware)
		if [  x$stage = "xclean"  -o  x$stage = "xdownload" -o x$stage = "xinstall"  -o x$stage = "xall" ]
		then

			if [ ! -d wl18xx_fw/ ]
			then
				wl18xx-firmware "download"
			fi

			wl18xx-firmware $2 
		else
			echo "illegal action for firmware"
			exit 1
		fi
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
		wl18xx-firmware "all"
		compat-wireless "all"
		wlconf "all"
		;;
	clean-all)
		compat-wireless "clean"
		ti-utils "clean"
		crda "clean"
		hostap "clean"
		iw "clean"
		openssl "clean"
		libnl "clean"
		wl18xx-firmware "clean"
		;;
	*)
		usage
		exit 1
esac
