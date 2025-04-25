include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/package.mk

PKG_NAME:=luci-app-autoupdate
PKG_VERSION:=1.20
PKG_RELEASE:=20221121

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  DEPENDS:=+curl +wget-ssl
  TITLE:=LuCI Support for autoupdate and filebrowser
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  Provides web interface for auto-updating OpenWrt firmware and managing filebrowser.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
  $(INSTALL_DIR) $(1)/etc/uci-defaults
  $(INSTALL_BIN) ./root/etc/uci-defaults/* $(1)/etc/uci-defaults/
  
  $(INSTALL_DIR) $(1)/usr/lib/lua/luci
  $(CP) ./luasrc/* $(1)/usr/lib/lua/luci/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

