include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for AutoBuild Firmware/AutoUpdate.sh
LUCI_DEPENDS:=+curl +wget
LUCI_PKGARCH:=all
PKG_VERSION:=1
PKG_RELEASE:=20210221

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
