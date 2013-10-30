patches: add ubuntu 12.04 lts kernel ibi support
================================================

This directory contains a series of patches that should be applied to the 
ubuntu 12.04-LTS kernel (linux 3.5.0) in order for working with the wilink8
r8.a6.02 sdio in-band interrupt support.
This series of patches add new APIs to the sdio_irq driver that are used 
by the r8.a6.02 modified drivers.

Without this patch set the driver would not build with the 12.04-LTS kernel.
    
Notes:
======
1. The build script is not applying this patch set. It needs to be manually
applied to the linux pc kernel source followed buy a build/install of
the modified kernel to the Ubuntu PC.

2. The new mac80211 integrated with R8.2 (ol_r8.a7.02) is supporting also
linux kernel 3.8 (and up)
Therefore support has been added to the driver for reading platform data info
from device tree.
The following switches should be enabled in the ubuntu kernel .config to
allow building the new driver:

CONFIG_OF=y

#
# Device Tree and Open Firmware support
#
# CONFIG_PROC_DEVICETREE is not set
# CONFIG_OF_SELFTEST is not set
CONFIG_OF_ADDRESS=y
CONFIG_OF_IRQ=y
CONFIG_OF_DEVICE=y
CONFIG_OF_I2C=y
CONFIG_OF_NET=y
CONFIG_OF_MDIO=y
CONFIG_OF_PCI=y
CONFIG_OF_PCI_IRQ=y
CONFIG_OF_MTD=y

The following web page has instructions on obtaining/rebuilding
the Ubuntu 12.04 linux kernel after applying this patch set:

http://linuxtweaking.blogspot.co.uk/2012/08/ubuntu-1204-lts-kernel-compile-guide.html



