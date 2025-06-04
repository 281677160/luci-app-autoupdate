module("luci.controller.autoupdate", package.seeall)

function index()
    entry({"admin", "system", "autoupdate"}, cbi("autoupdate/autoupdate"), _("AutoUpdate"), 60)
    entry({"admin", "system", "autoupdate", "do_check"}, call("action_check")).leaf = true
    entry({"admin", "system", "autoupdate", "do_upgrade"}, call("action_upgrade")).leaf = true
    entry({"admin", "system", "autoupdate", "check_status"}, call("action_check_status")).leaf = true
end

local function read_file(path)
    local f = io.open(path, "r")
    if f then
        local content = f:read("*a")
        f:close()
        return content
    end
    return nil
end

function action_check()
    os.execute("rm -f /tmp/compare_version /tmp/autoupdate.lock /tmp/autoupgrade.*")
    local check_result = luci.sys.call("AutoUpdate -c > /tmp/autoupdate.log 2>&1")

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = check_result == 0,
        has_update = nixio.fs.access("/tmp/compare_version"),
        message = check_result == 0 and 
                 (nixio.fs.access("/tmp/compare_version") and 
                  "发现新版本，是否立即升级？" or "当前已是最新版本") or
                 "检测失败,请查看日志/tmp/autoupdate.log"
    })
end

function action_upgrade()
    local use_no_config = luci.sys.exec("uci get autoupdate.@login[0].use_no_config_update 2>/dev/null"):match("1")

    -- Check for running process
    local pid = read_file("/tmp/autoupgrade.pid")
    if pid and tonumber(pid) and nixio.kill(tonumber(pid), 0) then
        luci.http.write_json({ success = false, message = "已有升级进程运行(PID:".. pid.. ")" })
        return
    end

    -- Cleanup old files
    os.execute("rm -f /tmp/autoupdate.lock /tmp/autoupgrade.pid")

    -- Start upgrade
    local upgrade_cmd = use_no_config and "AutoUpdate -k" or "AutoUpdate -u"
    local cmd = string.format(
        "(%s > /tmp/autoupdate.log 2>&1; "..
        "echo $? > /tmp/autoupgrade.exitcode; "..
        "rm -f /tmp/autoupgrade.pid) & "..
        "echo $! > /tmp/autoupgrade.pid", 
        upgrade_cmd
    )
    
    if os.execute(cmd) ~= 0 then
        luci.http.write_json({ success = false, message = "进程启动失败" })
        return
    end

    -- Verify PID
    for _ = 1, 3 do
        pid = read_file("/tmp/autoupgrade.pid")
        if pid then
            luci.http.write_json({
                success = true,
                message = "后台升级进程已启动(PID:".. pid.. ")",
                pid = tonumber(pid)
            })
            return
        end
        nixio.nanosleep(0.5) -- sleep 500ms
    end

    luci.http.write_json({ success = false, message = "无法确认进程状态" })
end

function action_check_status()
    local response = {}
    local exit_code = read_file("/tmp/autoupgrade.exitcode")

    if exit_code then
        os.remove("/tmp/autoupgrade.exitcode")
        exit_code = tonumber(exit_code:match("%d+")) or -1
        
        response = {
            running = false,
            success = exit_code == 0,
            message = exit_code == 0 and "升级成功,稍后请手动刷新页面..." or
                     exit_code == 1 and "升级失败,请查看日志/tmp/autoupdate.log" or
                     "异常退出码：".. exit_code
        }
        os.remove("/tmp/autoupgrade.pid")
    else
        local pid = read_file("/tmp/autoupgrade.pid")
        if pid and nixio.kill(tonumber(pid), 0) then
            response = { running = true, message = "升级进行中" }
        else
            response = { 
                running = false, 
                success = false, 
                message = pid and "进程异常终止" or "无进行中的升级" 
            }
            os.remove("/tmp/autoupgrade.pid")
        end
    end

    luci.http.write_json(response)
end
