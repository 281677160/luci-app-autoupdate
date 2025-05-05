# Copyright (C) 2020 Lienol <lawlienol@gmail.com>
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-autoupdate

LUCI_TITLE:=LuCI Support for AutoBuild Firmware/AutoUpdate
LUCI_DEPENDS:=+ubus +libubus-lua +curl +wget-ssl
LUCI_PKGARCH:=all
PKG_VERSION:=1.2
PKG_RELEASE:=$(shell date +%Y%m%d)

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
