local M = {}

local SERVICE = "ollama.service"
local STOP_TIMER = "ollama-stop.timer"

local function notify(msg, level)
  vim.schedule(function()
    vim.notify(msg, level)
  end)
end

local function systemctl_available()
  if vim.fn.executable("systemctl") == 1 then
    return true
  end

  notify("systemctl is unavailable; skipping Ollama systemd controls", vim.log.levels.WARN)
  return false
end

local function run_user_systemctl(args, on_exit)
  if not systemctl_available() then
    if on_exit then
      on_exit(false)
    end
    return
  end

  local cmd = { "systemctl", "--user" }
  vim.list_extend(cmd, args)

  vim.system(cmd, { text = true }, function(result)
    local ok = result.code == 0

    if not ok then
      local stderr_text = vim.trim(result.stderr or "")
      if stderr_text == "" then
        stderr_text = vim.trim(result.stdout or "")
      end

      if stderr_text == "" then
        stderr_text = "unknown error"
      end

      notify(
        "systemctl --user " .. table.concat(args, " ") .. " failed: " .. stderr_text,
        vim.log.levels.WARN
      )
    end

    if on_exit then
      on_exit(ok)
    end
  end)
end

function M.start_service(on_exit)
  run_user_systemctl({ "start", SERVICE }, on_exit)
end

function M.cancel_scheduled_stop(on_exit)
  run_user_systemctl({ "stop", STOP_TIMER }, on_exit)
end

function M.schedule_delayed_stop(on_exit)
  M.cancel_scheduled_stop(function(stop_ok)
    M.start_stop_timer(function(start_ok)
      if on_exit then
        on_exit(stop_ok and start_ok)
      end
    end)
  end)
end

function M.start_stop_timer(on_exit)
  run_user_systemctl({ "start", STOP_TIMER }, on_exit)
end

function M.ensure_running(callback)
  M.start_service(function(ok)
    if callback then
      callback(ok)
    end
  end)
end

function M.on_vim_enter()
  M.cancel_scheduled_stop(function()
    M.start_service()
  end)
end

function M.on_vim_leave_pre()
  M.schedule_delayed_stop()
end

return M
