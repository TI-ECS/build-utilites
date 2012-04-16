#!/bin/bash

if [ ! -e setup-env ]
then
	echo "No setup-env"
	exit 1
fi
source setup-env
ME=$0
function download ()
{
	wget "$1"
	if [ $? -ne 0 ]
	then 
		echo "Failed to download $2"
		exit 1
	fi
}

function git_clone ()
{
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
		download https://gforge.ti.com/gf/download/frsrelease/768/5331/ti-compat-wireless-wl12xx-r4-12-12-20.tar.gz ti-compat-wireless-wl12xx-r4-12-12-20.tar.gz
		tar xzf ti-compat-wireless-wl12xx-r4-12-12-20.tar.gz
		cd ${top_dir}/compat-wireless
		download http://processors.wiki.ti.com/images/a/aa/Compat-wireless-patches.zip Compat-wireless-patches.zip
		mkdir tmp-patches
		cd tmp-patches
		unzip ../Compat-wireless-patches.zip && cd -
		for i in `$LS tmp-patches`; do patch -p1 -i tmp-patches/$i; done
		res=`./scripts/driver-select wl12xx`
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/compat-wireless
		make
	fi
	if [ x"$stage" = "xinstall"  -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/compat-wireless
		sudo -E make install
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
		make USE_OPENSSL=1 all_noverify
	fi
	if [ x"$stage" = "xinstall"  -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/crda-1.1.1
		sudo -E DESTDIR=${NFSROOT} make USE_OPENSSL=1 install
		sudo mkdir -p ${NFSROOT}/usr/lib/crda
		sudo -E cp 2011.04.28-regulatory.bin ${NFSROOT}/usr/lib/crda/regulatory.bin
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
		git reset --hard 0a236ef5f8e4ba7218aac7d0cdacf45673d5b35c
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/iw
		make
	fi

	if [ x"$stage" = "xinstall"  -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/iw
		sudo -E make install
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
		make
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/libnl-2.0
		sudo -E make install
	fi
	cd $top_dir

}
function openssl ()
{
	stage=$1
	if [ x"$stage" = x"download" -o x"$stage" = "xall" ]
	then
		download http://www.openssl.org/source/openssl-1.0.0d.tar.gz;name=src openssl-1.0.0d.tar.gz
		tar xzf openssl-1.0.0d.tar.gz
		cd ${top_dir}/openssl-1.0.0d
		download http://processors.wiki.ti.com/images/e/ee/Openssl-1.0.0d-new-compilation-target-for-configure.zip Openssl-1.0.0d-new-compilation-target-for-configure.zip
		unzip Openssl-1.0.0d-new-compilation-target-for-configure.zip
		patch -p1 -i 0001-openssl-1.0.0d-new-target-os-for-configure.patch
		CROSS_COMPILE= perl ./Configure  shared --prefix=$NFSROOT/usr --openssldir=$NFSROOT/usr/lib/ssl linux-elf-arm
	fi
	if [ x"$stage" = "xbuild" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/openssl-1.0.0d
		make
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/openssl-1.0.0d
		sudo -E make install
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
		make
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/ti-utils
		sudo -E make install
	fi
	cd $top_dir
}
function ti-utils-firmware()
{
	sudo -E mkdir -p $NFSROOT/lib/firmware/ti-connectivity
	sudo cp ${top_dir}/ti-utils/firmware/* $NFSROOT/lib/firmware/ti-connectivity
	sudo rm -f $NFSROOT/lib/firmware/ti-connectivity/Makefile
	sudo cp -r ${top_dir}/ti-utils/ini_files $NFSROOT/lib/firmware/ti-connectivity
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

# Driver interface for wired authenticator
#CONFIG_DRIVER_WIRED=y

# Driver interface for madwifi driver
#CONFIG_DRIVER_MADWIFI=y
#CFLAGS += -I../../madwifi # change to the madwifi source directory

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

# Driver interface for FreeBSD net80211 layer (e.g., Atheros driver)
#CONFIG_DRIVER_BSD=y
#CFLAGS += -I/usr/local/include
#LIBS += -L/usr/local/lib
#LIBS_p += -L/usr/local/lib
#LIBS_c += -L/usr/local/lib

# Driver interface for no driver (e.g., RADIUS server only)
#CONFIG_DRIVER_NONE=y

# IEEE 802.11F/IAPP
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
		make
	fi
	if [ x"$stage" = "xinstall" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/hostap/hostapd
		sudo -E make install
	fi
	cd $top_dir

}
function make_wpa_sup_defconfig ()
{
	cat > .config <<"wpa_sup_defconfig"
# Example wpa_supplicant build time configuration
#
# This file lists the configuration options that are used when building the
# hostapd binary. All lines starting with # are ignored. Configuration option
# lines must be commented out complete, if they are not to be included, i.e.,
# just setting VARIABLE=n is not disabling that variable.
#
# This file is included in Makefile, so variables like CFLAGS and LIBS can also
# be modified from here. In most cases, these lines should use += in order not
# to override previous values of the variables.


# Uncomment following two lines and fix the paths if you have installed OpenSSL
# or GnuTLS in non-default location
DESTDIR=$(NFSROOT)
CFLAGS += -I$(NFSROOT)/usr/include/
LIBS += -L$(NFSROOT)/usr/lib
LIBS_p += -L$(NFSROOT)/usr/lib

# Some Red Hat versions seem to include kerberos header files from OpenSSL, but
# the kerberos files are not in the default include path. Following line can be
# used to fix build issues on such systems (krb5.h not found).
#CFLAGS += -I/usr/include/kerberos

# Example configuration for various cross-compilation platforms

#### sveasoft (e.g., for Linksys WRT54G) ######################################
#CC=mipsel-uclibc-gcc
#CC=/opt/brcm/hndtools-mipsel-uclibc/bin/mipsel-uclibc-gcc
#CFLAGS += -Os
#CPPFLAGS += -I../src/include -I../../src/router/openssl/include
#LIBS += -L/opt/brcm/hndtools-mipsel-uclibc-0.9.19/lib -lssl
###############################################################################

#### openwrt (e.g., for Linksys WRT54G) #######################################
#CC=mipsel-uclibc-gcc
#CC=/opt/brcm/hndtools-mipsel-uclibc/bin/mipsel-uclibc-gcc
#CFLAGS += -Os
#CPPFLAGS=-I../src/include -I../openssl-0.9.7d/include \
#	-I../WRT54GS/release/src/include
#LIBS = -lssl
###############################################################################

#CC=$(CROSS_COMPILE)gcc
#CFLAGS += -DCONFIG_LIBNL20
#CPPFLAGS += -DCONFIG_LIBNL20
#LIBS += -L$(NFSROOT)/lib -lnl
#LIBS_p += -L$(NFSROOT)/lib
#LIBDIR = $(NFSROOT)/lib
#BINDIR = $(NFSROOT)/usr/sbin

CONFIG_WAPI=y
CONFIG_LIBNL20=y
NEED_BGSCAN=y
CONFIG_BGSCAN_LEARN=y

# Driver interface for Host AP driver
#CONFIG_DRIVER_HOSTAP=y

# Driver interface for Agere driver
#CONFIG_DRIVER_HERMES=y
# Change include directories to match with the local setup
#CFLAGS += -I../../hcf -I../../include -I../../include/hcf
#CFLAGS += -I../../include/wireless

# Driver interface for madwifi driver
# Deprecated; use CONFIG_DRIVER_WEXT=y instead.
#CONFIG_DRIVER_MADWIFI=y
# Set include directory to the madwifi source tree
#CFLAGS += -I../../madwifi

# Driver interface for ndiswrapper
# Deprecated; use CONFIG_DRIVER_WEXT=y instead.
#CONFIG_DRIVER_NDISWRAPPER=y

# Driver interface for Atmel driver
#CONFIG_DRIVER_ATMEL=y

# Driver interface for old Broadcom driver
# Please note that the newer Broadcom driver (&quot;hybrid Linux driver&quot;) supports
# Linux wireless extensions and does not need (or even work) with the old
# driver wrapper. Use CONFIG_DRIVER_WEXT=y with that driver.
#CONFIG_DRIVER_BROADCOM=y
# Example path for wlioctl.h; change to match your configuration
#CFLAGS += -I/opt/WRT54GS/release/src/include

# Driver interface for Intel ipw2100/2200 driver
# Deprecated; use CONFIG_DRIVER_WEXT=y instead.
#CONFIG_DRIVER_IPW=y

# Driver interface for Ralink driver
#CONFIG_DRIVER_RALINK=y

# Driver interface for generic Linux wireless extensions
CONFIG_DRIVER_WEXT=y

# Driver interface for Linux drivers using the nl80211 kernel interface
CONFIG_DRIVER_NL80211=y

# Driver interface for FreeBSD net80211 layer (e.g., Atheros driver)
#CONFIG_DRIVER_BSD=y
#CFLAGS += -I/usr/local/include
#LIBS += -L/usr/local/lib
#LIBS_p += -L/usr/local/lib
#LIBS_c += -L/usr/local/lib

# Driver interface for Windows NDIS
#CONFIG_DRIVER_NDIS=y
#CFLAGS += -I/usr/include/w32api/ddk
#LIBS += -L/usr/local/lib
# For native build using mingw
#CONFIG_NATIVE_WINDOWS=y
# Additional directories for cross-compilation on Linux host for mingw target
#CFLAGS += -I/opt/mingw/mingw32/include/ddk
#LIBS += -L/opt/mingw/mingw32/lib
#CC=mingw32-gcc
# By default, driver_ndis uses WinPcap for low-level operations. This can be
# replaced with the following option which replaces WinPcap calls with NDISUIO.
# However, this requires that WZC is disabled (net stop wzcsvc) before starting
# wpa_supplicant.
# CONFIG_USE_NDISUIO=y

# Driver interface for development testing
#CONFIG_DRIVER_TEST=y

# Include client MLME (management frame processing) for test driver
# This can be used to test MLME operations in hostapd with the test interface.
# space.
#CONFIG_CLIENT_MLME=y

# Driver interface for wired Ethernet drivers
CONFIG_DRIVER_WIRED=y

# Driver interface for the Broadcom RoboSwitch family
#CONFIG_DRIVER_ROBOSWITCH=y

# Driver interface for no driver (e.g., WPS ER only)
#CONFIG_DRIVER_NONE=y

# Solaris libraries
#LIBS += -lsocket -ldlpi -lnsl
#LIBS_c += -lsocket

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

# EAP-FAST
# Note: Default OpenSSL package does not include support for all the
# functionality needed for EAP-FAST. If EAP-FAST is enabled with OpenSSL,
# the OpenSSL library must be patched (openssl-0.9.8d-tls-extensions.patch)
# to add the needed functions.
#CONFIG_EAP_FAST=y

# EAP-GTC
CONFIG_EAP_GTC=y

# EAP-OTP
CONFIG_EAP_OTP=y

# EAP-SIM (enable CONFIG_PCSC, if EAP-SIM is used)
#CONFIG_EAP_SIM=y

# EAP-PSK (experimental; this is _not_ needed for WPA-PSK)
#CONFIG_EAP_PSK=y

# EAP-PAX
#CONFIG_EAP_PAX=y

# LEAP
CONFIG_EAP_LEAP=y

# EAP-AKA (enable CONFIG_PCSC, if EAP-AKA is used)
#CONFIG_EAP_AKA=y

# EAP-AKA' (enable CONFIG_PCSC, if EAP-AKA' is used).
# This requires CONFIG_EAP_AKA to be enabled, too.
#CONFIG_EAP_AKA_PRIME=y

# Enable USIM simulator (Milenage) for EAP-AKA
#CONFIG_USIM_SIMULATOR=y

# EAP-SAKE
#CONFIG_EAP_SAKE=y

# EAP-GPSK
#CONFIG_EAP_GPSK=y
# Include support for optional SHA256 cipher suite in EAP-GPSK
#CONFIG_EAP_GPSK_SHA256=y

# EAP-TNC and related Trusted Network Connect support (experimental)
#CONFIG_EAP_TNC=y

# Wi-Fi Protected Setup (WPS)
CONFIG_WPS=y
# Enable WSC 2.0 support
CONFIG_WPS2=y

# EAP-IKEv2
#CONFIG_EAP_IKEV2=y

# PKCS#12 (PFX) support (used to read private key and certificate file from
# a file that usually has extension .p12 or .pfx)
CONFIG_PKCS12=y

# Smartcard support (i.e., private key on a smartcard), e.g., with openssl
# engine.
CONFIG_SMARTCARD=y

# PC/SC interface for smartcards (USIM, GSM SIM)
# Enable this if EAP-SIM or EAP-AKA is included
#CONFIG_PCSC=y

# Development testing
#CONFIG_EAPOL_TEST=y

# Select control interface backend for external programs, e.g, wpa_cli:
# unix = UNIX domain sockets (default for Linux/*BSD)
# udp = UDP sockets using localhost (127.0.0.1)
# named_pipe = Windows Named Pipe (default for Windows)
# y = use default (backwards compatibility)
# If this option is commented out, control interface is not included in the
# build.
CONFIG_CTRL_IFACE=y

# Include support for GNU Readline and History Libraries in wpa_cli.
# When building a wpa_cli binary for distribution, please note that these
# libraries are licensed under GPL and as such, BSD license may not apply for
# the resulting binary.
#CONFIG_READLINE=y

# Remove debugging code that is printing out debug message to stdout.
# This can be used to reduce the size of the wpa_supplicant considerably
# if debugging code is not needed. The size reduction can be around 35%
# (e.g., 90 kB).
#CONFIG_NO_STDOUT_DEBUG=y

# Remove WPA support, e.g., for wired-only IEEE 802.1X supplicant, to save
# 35-50 kB in code size.
#CONFIG_NO_WPA=y

# Remove WPA2 support. This allows WPA to be used, but removes WPA2 code to
# save about 1 kB in code size when building only WPA-Personal (no EAP support)
# or 6 kB if building for WPA-Enterprise.
#CONFIG_NO_WPA2=y

# Remove IEEE 802.11i/WPA-Personal ASCII passphrase support
# This option can be used to reduce code size by removing support for
# converting ASCII passphrases into PSK. If this functionality is removed, the
# PSK can only be configured as the 64-octet hexstring (e.g., from
# wpa_passphrase). This saves about 0.5 kB in code size.
#CONFIG_NO_WPA_PASSPHRASE=y

# Disable scan result processing (ap_mode=1) to save code size by about 1 kB.
# This can be used if ap_scan=1 mode is never enabled.
#CONFIG_NO_SCAN_PROCESSING=y

# Select configuration backend:
# file = text file (e.g., wpa_supplicant.conf; note: the configuration file
#	path is given on command line, not here; this option is just used to
#	select the backend that allows configuration files to be used)
# winreg = Windows registry (see win_example.reg for an example)
CONFIG_BACKEND=file

# Remove configuration write functionality (i.e., to allow the configuration
# file to be updated based on runtime configuration changes). The runtime
# configuration can still be changed, the changes are just not going to be
# persistent over restarts. This option can be used to reduce code size by
# about 3.5 kB.
#CONFIG_NO_CONFIG_WRITE=y

# Remove support for configuration blobs to reduce code size by about 1.5 kB.
#CONFIG_NO_CONFIG_BLOBS=y

# Select program entry point implementation:
# main = UNIX/POSIX like main() function (default)
# main_winsvc = Windows service (read parameters from registry)
# main_none = Very basic example (development use only)
#CONFIG_MAIN=main

# Select wrapper for operatins system and C library specific functions
# unix = UNIX/POSIX like systems (default)
# win32 = Windows systems
# none = Empty template
#CONFIG_OS=unix

# Select event loop implementation
# eloop = select() loop (default)
# eloop_win = Windows events and WaitForMultipleObject() loop
# eloop_none = Empty template
#CONFIG_ELOOP=eloop

# Select layer 2 packet implementation
# linux = Linux packet socket (default)
# pcap = libpcap/libdnet/WinPcap
# freebsd = FreeBSD libpcap
# winpcap = WinPcap with receive thread
# ndis = Windows NDISUIO (note: requires CONFIG_USE_NDISUIO=y)
# none = Empty template
#CONFIG_L2_PACKET=linux

# PeerKey handshake for Station to Station Link (IEEE 802.11e DLS)
CONFIG_PEERKEY=y

# IEEE 802.11w (management frame protection)
# This version is an experimental implementation based on IEEE 802.11w/D1.0
# draft and is subject to change since the standard has not yet been finalized.
# Driver support is also needed for IEEE 802.11w.
#CONFIG_IEEE80211W=y

# Select TLS implementation
# openssl = OpenSSL (default)
# gnutls = GnuTLS (needed for TLS/IA, see also CONFIG_GNUTLS_EXTRA)
# internal = Internal TLSv1 implementation (experimental)
# none = Empty template
#CONFIG_TLS=openssl

# Whether to enable TLS/IA support, which is required for EAP-TTLSv1.
# You need CONFIG_TLS=gnutls for this to have any effect. Please note that
# even though the core GnuTLS library is released under LGPL, this extra
# library uses GPL and as such, the terms of GPL apply to the combination
# of wpa_supplicant and GnuTLS if this option is enabled. BSD license may not
# apply for distribution of the resulting binary.
#CONFIG_GNUTLS_EXTRA=y

# If CONFIG_TLS=internal is used, additional library and include paths are
# needed for LibTomMath. Alternatively, an integrated, minimal version of
# LibTomMath can be used. See beginning of libtommath.c for details on benefits
# and drawbacks of this option.
#CONFIG_INTERNAL_LIBTOMMATH=y
#ifndef CONFIG_INTERNAL_LIBTOMMATH
#LTM_PATH=/usr/src/libtommath-0.39
#CFLAGS += -I$(LTM_PATH)
#LIBS += -L$(LTM_PATH)
#LIBS_p += -L$(LTM_PATH)
#endif
# At the cost of about 4 kB of additional binary size, the internal LibTomMath
# can be configured to include faster routines for exptmod, sqr, and div to
# speed up DH and RSA calculation considerably
#CONFIG_INTERNAL_LIBTOMMATH_FAST=y

# Include NDIS event processing through WMI into wpa_supplicant/wpasvc.
# This is only for Windows builds and requires WMI-related header files and
# WbemUuid.Lib from Platform SDK even when building with MinGW.
#CONFIG_NDIS_EVENTS_INTEGRATED=y
#PLATFORMSDKLIB=&quot;/opt/Program Files/Microsoft Platform SDK/Lib&quot;

# Add support for old DBus control interface
# (fi.epitest.hostap.WPASupplicant)
#CONFIG_CTRL_IFACE_DBUS=y

# Add support for new DBus control interface
# (fi.w1.hostap.wpa_supplicant1)
#CONFIG_CTRL_IFACE_DBUS_NEW=y

# Add introspection support for new DBus control interface
#CONFIG_CTRL_IFACE_DBUS_INTRO=y

# Add support for loading EAP methods dynamically as shared libraries.
# When this option is enabled, each EAP method can be either included
# statically (CONFIG_EAP_&lt;method&gt;=y) or dynamically (CONFIG_EAP_&lt;method&gt;=dyn).
# Dynamic EAP methods are build as shared objects (eap_*.so) and they need to
# be loaded in the beginning of the wpa_supplicant configuration file
# (see load_dynamic_eap parameter in the example file) before being used in
# the network blocks.
#
# Note that some shared parts of EAP methods are included in the main program
# and in order to be able to use dynamic EAP methods using these parts, the
# main program must have been build with the EAP method enabled (=y or =dyn).
# This means that EAP-TLS/PEAP/TTLS/FAST cannot be added as dynamic libraries
# unless at least one of them was included in the main build to force inclusion
# of the shared code. Similarly, at least one of EAP-SIM/AKA must be included
# in the main build to be able to load these methods dynamically.
#
# Please also note that using dynamic libraries will increase the total binary
# size. Thus, it may not be the best option for targets that have limited
# amount of memory/flash.
#CONFIG_DYNAMIC_EAP_METHODS=y

# IEEE Std 802.11r-2008 (Fast BSS Transition)
#CONFIG_IEEE80211R=y

# Add support for writing debug log to a file (/tmp/wpa_supplicant-log-#.txt)
CONFIG_DEBUG_FILE=y

# Enable privilege separation (see README 'Privilege separation' for details)
#CONFIG_PRIVSEP=y

# Enable mitigation against certain attacks against TKIP by delaying Michael
# MIC error reports by a random amount of time between 0 and 60 seconds
#CONFIG_DELAYED_MIC_ERROR_REPORT=y

# Enable tracing code for developer debugging
# This tracks use of memory allocations and other registrations and reports
# incorrect use with a backtrace of call (or allocation) location.
#CONFIG_WPA_TRACE=y
# For BSD, comment out these.
#LIBS += -lexecinfo
#LIBS_p += -lexecinfo
#LIBS_c += -lexecinfo

# Use libbfd to get more details for developer debugging
# This enables use of libbfd to get more detailed symbols for the backtraces
# generated by CONFIG_WPA_TRACE=y.
#CONFIG_WPA_TRACE_BFD=y
# For BSD, comment out these.
#LIBS += -lbfd -liberty -lz
#LIBS_p += -lbfd -liberty -lz
#LIBS_c += -lbfd -liberty -lz
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
		make 
	fi
	if [ x"$stage" = x"install" -o x"$stage" = "xall" ]
	then
		cd ${top_dir}/hostap/wpa_supplicant
		sudo -E make install
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
elif [ $argc -eq 1 -a x"$1" != x"all" ]
then
	usage
	exit 1
else
	package="all"
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
				package_dir_exists ${top_dir}/libnl-2.0 libnl-2 || exit 1
				libnl "download"
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
				openssl "all"
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
	*)
		usage
		exit 1
esac
