local M = {
  state = {
    buf = nil,
    win = nil,
    height = 12,
  },
}

local root_markers = {
  "Cargo.toml",
  "package.json",
  "pyproject.toml",
  "flake.nix",
  ".git",
}

local function get_buf_path()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return vim.uv.cwd()
  end
  return vim.fs.dirname(file)
end

local function find_root()
  local start = get_buf_path()
  local found = vim.fs.find(root_markers, {
    path = start,
    upward = true,
    stop = vim.uv.os_homedir(),
  })

  if #found == 0 then
    return vim.uv.cwd()
  end

  return vim.fs.dirname(found[1])
end

local function detect_command(mode)
  local file = vim.api.nvim_buf_get_name(0)
  local ft = vim.bo.filetype
  local root = find_root()

  if vim.uv.fs_stat(root .. "/Cargo.toml") then
    if mode == "build" then
      return "cargo build", root
    end
    return "cargo run", root
  end

  if vim.uv.fs_stat(root .. "/package.json") then
    if mode == "build" then
      return "npm run build", root
    end
    return "npm run dev", root
  end

  if vim.uv.fs_stat(root .. "/flake.nix") then
    if mode == "build" then
      return "nix build", root
    end
    return "nix run", root
  end

  if ft == "python" and file ~= "" then
    if mode == "build" then
      return nil, nil, "Python has no default build target"
    end
    return ("python3 %s"):format(vim.fn.shellescape(file)), vim.uv.cwd()
  end

  if ft == "lua" and file ~= "" then
    if mode == "build" then
      return nil, nil, "Lua has no default build target"
    end
    return ("lua %s"):format(vim.fn.shellescape(file)), vim.uv.cwd()
  end

  if mode == "build" then
    return nil, nil, "No supported build target found"
  end

  return nil, nil, "No supported run target found"
end

local function restore_win(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end

local function ensure_terminal()
  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
      vim.api.nvim_set_current_win(M.state.win)
      return
    end

    vim.cmd("botright split")
    vim.cmd(("resize %d"):format(M.state.height))
    M.state.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(M.state.win, M.state.buf)
    return
  end

  vim.cmd("botright split")
  vim.cmd(("resize %d"):format(M.state.height))
  vim.cmd("terminal")

  M.state.win = vim.api.nvim_get_current_win()
  M.state.buf = vim.api.nvim_get_current_buf()

  vim.keymap.set("n", "q", "<cmd>close<CR>", {
    buffer = M.state.buf,
    silent = true,
    desc = "Close project terminal",
  })

  vim.keymap.set("t", "<C-q>", [[<C-\><C-n><cmd>close<CR>]], {
    buffer = M.state.buf,
    silent = true,
    desc = "Close project terminal",
  })
end

function M.run(mode)
  local cmd, cwd, err = detect_command(mode)
  if not cmd then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local prev_win = vim.api.nvim_get_current_win()
  ensure_terminal()

  local job = vim.b[M.state.buf].terminal_job_id
  if not job then
    vim.notify("Project terminal job is unavailable", vim.log.levels.ERROR)
    restore_win(prev_win)
    return
  end

  local line = ("cd %s && %s\n"):format(vim.fn.shellescape(cwd), cmd)
  vim.fn.chansend(job, line)
  restore_win(prev_win)
end

function M.focus()
  ensure_terminal()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_set_current_win(M.state.win)
    vim.cmd("startinsert")
  end
end

function M.close()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("TermClose", {
    callback = function(args)
      if args.buf == M.state.buf then
        M.state.buf = nil
        M.state.win = nil
      end
    end,
  })
end

return M
