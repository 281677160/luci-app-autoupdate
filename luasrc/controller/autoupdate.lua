module("luci.controller.autoupdate", package.seeall)

function index()
    entry({"admin", "system", "autoupdate"}, cbi("autoupdate/autoupdate"), _("AutoUpdate"), 60)
    entry({"admin", "system", "autoupdate", "do_check"}, call("action_check")).leaf = true
    entry({"admin", "system", "autoupdate", "do_upgrade"}, call("action_upgrade")).leaf = true
    entry({"admin", "system", "autoupdate", "check_status"}, call("action_check_status")).leaf = true
end

-- 检查更新
function action_check()
    os.execute("rm -f /tmp/compare_version /tmp/autoupdate.lock /tmp/autoupgrade.*")
    local check_result = luci.sys.call("AutoUpdate > /tmp/autoupdate.log 2>&1")
    
    local response = {}
    if check_result == 1 then
        response = { success = false, message = "检测失败,请查看日志/tmp/autoupdate.log" }
    else
        local has_update = io.open("/tmp/compare_version", "r") ~= nil
        response = {
            success = true,
            has_update = has_update,
            message = has_update and "发现新版本，是否立即升级？" or "当前已是最新版本"
        }
    end
    luci.http.write_json(response)
end

-- 启动升级
function action_upgrade()
    -- 获取勾选框的值
    local use_no_config_update = luci.http.formvalue("use_no_config_update") == "1"

    -- 检测锁文件有效性（新增逻辑）
    local lock_file = io.open("/tmp/autoupdate.lock", "r")
    if lock_file then
        lock_file:close()
        -- 增加进程存活检测
        local pid_file = io.open("/tmp/autoupgrade.pid", "r")
        if pid_file then
            local pid = pid_file:read("*a")
            pid_file:close()
            if os.execute("kill -0 "..pid.." 2>/dev/null") == 0 then
                luci.http.write_json({success=false, message="已有升级进程运行(PID:"..pid..")"})
                return
            else  -- 进程已结束但残留锁文件
                os.remove("/tmp/autoupdate.lock")
                os.remove("/tmp/autoupgrade.pid")
            end
        else
            os.remove("/tmp/autoupdate.lock")  -- 清理无效锁文件
        end
    end

    -- 创建锁文件（原子操作）
    if os.execute("mkdir /tmp/autoupdate.lock 2>/dev/null") ~= 0 then
        luci.http.write_json({success=false, message="锁文件创建失败"})
        return
    end

    -- 根据勾选框的值选择升级命令
    local upgrade_command = use_no_config_update and "AutoUpdate -u" or "AutoUpdate -k"

    -- 启动升级进程（优化版本）
    os.execute("("..upgrade_command.." > /tmp/autoupdate.log 2>&1; "..
        "echo $? > /tmp/autoupgrade.exitcode; "..
        "rm -rf /tmp/autoupdate.lock /tmp/autoupgrade.pid) & "..
        "echo $! > /tmp/autoupgrade.pid")
    
    -- 验证PID文件（增加重试机制）
    for i=1,3 do  -- 最多重试3次
        local pid_file = io.open("/tmp/autoupgrade.pid", "r")
        if pid_file then
            local pid = pid_file:read("*a")
            pid_file:close()
            luci.http.write_json({
                success = true,
                message = "后台升级进程已启动(PID:"..pid..")",
                pid = tonumber(pid)
            })
            return
        end
        os.execute("sleep 0.5")  -- 等待500ms
    end

    -- PID文件生成失败处理
    os.execute("rm -rf /tmp/autoupdate.lock")
    luci.http.write_json({
        success = false,
        message = "进程启动失败，请检查系统资源"
    })
end

-- 检查升级状态
function action_check_status()
    local response = {}
    local pid_path = "/tmp/autoupgrade.pid"
    local exit_code_path = "/tmp/autoupgrade.exitcode"
    
    -- 检查进程状态
    if io.open(pid_path, "r") then
        local pid_file = io.open(pid_path, "r")
        local pid = pid_file:read("*a")
        pid_file:close()
        
        -- 验证进程是否存在
        if os.execute("kill -0 "..pid.." 2>/dev/null") == 0 then
            response = { running = true, message = "升级进行中" }
        else
            os.remove(pid_path)
            local exit_code = nil
            
            -- 读取退出码文件
            if io.open(exit_code_path, "r") then
                local exit_file = io.open(exit_code_path, "r")
                exit_code = tonumber(exit_file:read("*l")) or 1
                exit_file:close()
                os.remove(exit_code_path)
            end
            
            -- 确定升级结果
            if exit_code ~= nil then
                response = {
                    running = false,
                    success = (exit_code == 0),
                    message = (exit_code == 0) and "升级成功" or ("升级失败,请查看日志/tmp/autoupdate.log")
                }
            else
                -- 兼容旧版本日志检测
                local log_success = os.execute("grep -q 'Upgrade succeeded' /tmp/autoupdate.log") == 0
                response = {
                    running = false,
                    success = log_success,
                    message = log_success and "升级成功" or "升级失败,请查看日志/tmp/autoupdate.log"
                }
            end
        end
    else
        response = { running = false, message = "无进行中的升级" }
    end
    
    luci.http.write_json(response)
end
