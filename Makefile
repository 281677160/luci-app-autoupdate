include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for AutoBuild Firmware/AutoUpdate.sh
LUCI_DEPENDS:=+curl +grep +wget +wget-ssl
LUCI_PKGARCH:=all
PKG_VERSION:=1
PKG_RELEASE:=20221121

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
