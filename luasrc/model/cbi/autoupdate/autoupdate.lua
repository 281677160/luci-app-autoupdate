require("luci.sys")
require("luci.http")
require("luci.dispatcher")

local m = Map("autoupdate", translate("AutoUpdate"),
    translate("AutoUpdate LUCI supports one-click firmware upgrade and scheduled upgrade"))

local s = m:section(TypedSection, "login", "")
s.addremove = false
s.anonymous = true

-- Helper function to safely execute commands and handle errors
local function safe_exec(command)
    local handle = io.popen(command .. " 2>&1")
    if handle then
        local result = handle:read("*a")
        handle:close()
        return result:gsub("%s+$", "") -- trim trailing whitespace
    end
    return ""
end

-- Function to get system information more efficiently
local function get_sys_info()
    local info = {}
    
    -- Make sure script is executable
    os.execute("chmod +x /usr/bin/AutoUpdate 2>/dev/null")
    os.execute("tee /tmp/autotimes 2>/dev/null")
    
    -- Check for updates and capture exit code
    info.check_error = (os.execute("AutoUpdate > /tmp/autoupdate.log 2>&1") ~= 0)
    
    -- Read configuration values more efficiently
    info.github_url = safe_exec([[awk -F'=' '/GITHUB_LINK=/ {gsub(/"/, "", $2); print $2}' /etc/openwrt_update]])
    info.local_version = safe_exec([[awk -F'=' '/FIRMWARE_VERSION=/ {gsub(/"/, "", $2); print $2}' /etc/openwrt_update]])
    info.cloud_version = safe_exec("cat /tmp/cloud_version 2>/dev/null")
    
    -- Read tags version info if available
    if nixio.fs.access("/tmp/tags_version") then
        info.equipment_name = safe_exec([[awk -F'=' '/EQUIPMENT_NAME=/ {gsub(/"/, "", $2); print $2}' /tmp/tags_version]])
        info.model_type = safe_exec([[awk -F'=' '/MODEL_TYPE=/ {gsub(/"/, "", $2); print $2}' /tmp/tags_version]])
        info.kernel_type = safe_exec([[awk -F'=' '/KERNEL_TYPE=/ {gsub(/"/, "", $2); print $2}' /tmp/tags_version]])
    else
        info.equipment_name = ""
        info.model_type = ""
        info.kernel_type = ""
    end
    
    return info
end

-- AutoUpdate switch
local o = s:option(Flag, "enable", translate("Enable AutoUpdate"),
    translate("Automatically update firmware during the specified time"))
o.default = o.disabled
o.rmempty = false

-- Update time settings
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

-- Get system info once and reuse
local sys_info = get_sys_info()

-- GitHub URL setting
local github = s:option(Value, "github", translate("GitHub URL"))
github.default = sys_info.github_url
github.rmempty = false

-- Keep config option
local use_no_config_update = s:option(Flag, "use_no_config_update", 
    translate("Do not keep configuration on update"))
use_no_config_update.default = use_no_config_update.disabled

-- Upgrade button with enhanced error handling
local button_upgrade_firmware = s:option(Button, "_upgrade", translate("Upgrade to Latest Version"),
    translate("Click the button below to upgrade to the latest version. Please wait patiently until the router reboots.")..
    "<br><br><br>".. translate("Local firmware version:").. " <strong>".. sys_info.local_version.. "</strong>"..
    "<br>".. translate("Cloud firmware version:").. " <strong>".. sys_info.cloud_version.. "</strong>"..
    "<br><br>".. translate("Equipment name:").. " ".. sys_info.equipment_name..
    "<br>".. translate("Kernel version:").. " ".. sys_info.kernel_type..
    "<br>".. translate("Firmware type:").. " ".. sys_info.model_type)

if sys_info.check_error then
    button_upgrade_firmware.description = button_upgrade_firmware.description ..
        "<br><br><span style='color:red;font-weight:bold;'>" .. 
        translate("Error: Could not fetch cloud version information") .. "</span>"
end

button_upgrade_firmware.inputtitle = translate("Start Upgrade")
button_upgrade_firmware.template = "autoupdate/autoupdate"

function button_upgrade_firmware.write(self, section)
    -- Read config value safely
    local config_value = safe_exec("uci -q get autoupdate.@login[0].use_no_config_update || echo 0")
    local use_no_config = (config_value == "1")
    
    -- Build and execute upgrade command
    local upgrade_command = use_no_config and "AutoUpdate -k" or "AutoUpdate -u"
    os.execute(upgrade_command .. " >> /tmp/autoupdate.log 2>&1 &")
    
    -- Show immediate feedback
    luci.http.redirect(luci.dispatcher.build_url("admin/system/autoupdate") .. "?upgrade_started=1")
end

-- Cleanup temporary files
os.execute("rm -f /tmp/autotimes 2>/dev/null")

-- Apply settings and restart service
local uci = luci.model.uci.cursor()
uci:set("autoupdate", "config", "enable", "1")
if uci:changes() then
    uci:commit("autoupdate")
    os.execute("/etc/init.d/autoupdate restart >/dev/null 2>&1")
end

return m
