local ollama = require("config.ollama")

local python_indent = vim.api.nvim_create_augroup("python_indent", { clear = true })
local ollama_lifecycle = vim.api.nvim_create_augroup("ollama_lifecycle", { clear = true })
local external_file_watch = vim.api.nvim_create_augroup("external_file_watch", { clear = true })

local nvim_focused = true
local checktime_timer = vim.uv.new_timer()
local last_shellpost_ms = 0
local shellpost_debounce_ms = 200

local function safe_checktime_current_buffer()
  if vim.fn.mode() == "c" then
    return
  end

  if vim.bo.buftype ~= "" then
    return
  end

  pcall(vim.cmd, "silent! checktime %")
end

vim.api.nvim_create_autocmd("FileType", {
  group = python_indent,
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = ollama_lifecycle,
  callback = function()
    ollama.on_vim_enter()
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = ollama_lifecycle,
  callback = function()
    ollama.on_vim_leave_pre()
  end,
})

vim.api.nvim_create_autocmd("FocusLost", {
  group = external_file_watch,
  callback = function()
    nvim_focused = false
  end,
})

vim.api.nvim_create_autocmd("FocusGained", {
  group = external_file_watch,
  callback = function()
    nvim_focused = true
    safe_checktime_current_buffer()
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = external_file_watch,
  callback = function(args)
    if nvim_focused then
      return
    end

    local now = vim.uv.now()
    if now - last_shellpost_ms < shellpost_debounce_ms then
      return
    end
    last_shellpost_ms = now

    local changed_file = args.file ~= "" and vim.fn.fnamemodify(args.file, ":~:.") or "current buffer"
    vim.notify("Reloaded external changes: " .. changed_file, vim.log.levels.INFO)

    vim.defer_fn(function()
      pcall(vim.cmd, "silent! Gitsigns refresh")
      pcall(vim.cmd, "silent! redrawstatus")

      local ok, gitsigns = pcall(require, "gitsigns")
      if ok and type(gitsigns.next_hunk) == "function" then
        vim.defer_fn(function()
          pcall(gitsigns.next_hunk)
          pcall(vim.cmd, "silent! redrawstatus")
        end, 120)
      end
    end, 120)
  end,
})

if checktime_timer then
  checktime_timer:start(500, 500, vim.schedule_wrap(function()
    if not nvim_focused then
      safe_checktime_current_buffer()
    end
  end))
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = external_file_watch,
  callback = function()
    if checktime_timer then
      checktime_timer:stop()
      checktime_timer:close()
      checktime_timer = nil
    end
  end,
})
