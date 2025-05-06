# Copyright (C) 2021 AutoUpdate <281677160@qq.com>
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-autoupdate

PKG_MAINTAINER:=AutoUpdate <281677160@qq.com>

LUCI_TITLE:=LuCI Support for AutoUpdate
LUCI_DEPENDS:=+curl +wget-ssl
LUCI_PKGARCH:=all


include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
