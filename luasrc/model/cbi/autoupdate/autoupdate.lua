require("luci.sys")
require("luci.http")
require("luci.dispatcher")

local m = Map("autoupdate", translate("AutoUpdate"),
    translate("AutoUpdate LUCI supports one-click firmware upgrade and scheduled upgrade"))

local s = m:section(TypedSection, "login", "")
s.addremove = false
s.anonymous = true

-- 自动更新开关
local o = s:option(Flag, "enable", translate("Enable AutoUpdate"),
    translate("Automatically update firmware during the specified time"))
o.default = o.disabled
o.rmempty = false

-- 更新时间设置
local week = s:option(ListValue, "week", translate("Week Day"))
week:value(7, translate("Everyday"))
for i = 0, 6 do
    local day_name = os.date("%A", os.time({year = 2000, month = 1, day = 2 + i}))
    week:value(i, translate(day_name))
end
week.default = 0

local hour = s:option(Value, "hour", translate("Fixed Hour"))
hour.datatype = "range(0,23)"
hour.rmempty = false

local minute = s:option(Value, "minute", translate("Fixed Minute"))
minute.datatype = "range(0,59)"
minute.rmempty = false

local function get_sys_info()
    local info = {}

    -- 确保脚本可执行
    os.execute("chmod +x /usr/bin/AutoUpdate")
    os.execute("tee /tmp/autotimes 2>&1")

    -- 执行检查更新脚本并捕获返回值
    local check_result = luci.sys.call("AutoUpdate > /tmp/autoupdate.log 2>&1")
    -- 检查退出码是否为1
    if check_result == 1 then
        info.check_error = true
    else
        info.check_error = false
    end

    -- 获取系统信息
    info.github_url = luci.sys.exec("awk -F'=' '/GITHUB_LINK=/ {gsub(/\"/, \"\", $2); print $2}' /etc/openwrt_update") or ""
    info.local_version = luci.sys.exec("awk -F'=' '/FIRMWARE_VERSION=/ {gsub(/\"/, \"\", $2); print $2}' /etc/openwrt_update") or ""
    info.cloud_version = luci.sys.exec("cat /tmp/cloud_version 2>/dev/null") or ""
    info.equipment_name = luci.sys.exec("awk -F'=' '/EQUIPMENT_NAME=/ {gsub(/\"/, \"\", $2); print $2}' /tmp/tags_version 2>/dev/null") or ""
    info.model_type = luci.sys.exec("awk -F'=' '/MODEL_TYPE=/ {gsub(/\"/, \"\", $2); print $2}' /tmp/tags_version 2>/dev/null") or ""
    info.kernel_type = luci.sys.exec("awk -F'=' '/KERNEL_TYPE=/ {gsub(/\"/, \"\", $2); print $2}' /tmp/tags_version 2>/dev/null") or ""
    return info
end

local sys_info = get_sys_info()

-- GitHub URL 设置
local github = s:option(Value, "github", translate("GitHub URL"))
github.default = sys_info.github_url
github.rmempty = false

-- 新增勾选框
local use_no_config_update = s:option(Flag, "use_no_config_update", translate("Do not keep configuration on update"))
use_no_config_update.default = use_no_config_update.disabled

-- 升级按钮（带执行功能）
local button_upgrade_firmware = s:option(Button, "_upgrade", translate("Upgrade to Latest Version"),
    translate("Click the button below to upgrade to the latest version. Please wait patiently until the router reboots.")..
    "<br><br>".. translate("Local firmware version:").. " ".. sys_info.local_version..
    "<br>".. translate("Cloud firmware version:").. " ".. sys_info.cloud_version..
    "<br><br>".. translate("Equipment name:").. " ".. sys_info.equipment_name..
    "<br>".. translate("Kernel version:").. " ".. sys_info.kernel_type..
    "<br>".. translate("Firmware type:").. " ".. sys_info.model_type)

-- 如果检查更新失败，显示错误信息
if sys_info.check_error then
    button_upgrade_firmware.description = button_upgrade_firmware.description ..
        "<br><br><span style='color:red;'>" .. translate("Error detected in cloud version number") .. "</span>"
end

button_upgrade_firmware.inputtitle = translate("Start Upgrade")
button_upgrade_firmware.template = "autoupdate/upgrade_button"

function button_upgrade_firmware.write(self, section)
    -- 从配置文件读取 use_no_config_update 的值
    local config_value = luci.sys.exec("uci get autoupdate.@login[0].use_no_config_update 2>/dev/null"):gsub("\n", "")
    local use_no_config = (config_value == "1")

    -- 根据勾选框的值选择升级命令
    local upgrade_command = use_no_config and "AutoUpdate -k" or "AutoUpdate -u"
    -- 执行升级命令
    local upgrade_result = luci.sys.call(upgrade_command.. " > /tmp/autoupdate.log 2>&1")

    -- 重定向回页面
    luci.http.redirect(luci.dispatcher.build_url("admin/system/autoupdate"))
end

-- 删除标记
os.execute("rm -f /tmp/autotimes 2>&1")

-- 应用设置后重启服务
local uci = require("luci.model.uci").cursor()
uci:set("autoupdate", "config", "enable", "1")
uci:commit("autoupdate")
os.execute("/etc/init.d/autoupdate restart")

return m
