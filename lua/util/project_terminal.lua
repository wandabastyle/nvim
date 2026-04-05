local M = {
  state = {
    buf = nil,
    win = nil,
    height = 12,
  },
}

local function project_root(startpath)
  local root_markers = { "Cargo.toml", "package.json", "pyproject.toml", ".git" }
  local found = vim.fs.find(root_markers, { upward = true, path = startpath })
  if #found == 0 then
    return vim.fn.getcwd()
  end
  return vim.fs.dirname(found[1])
end

local function command_for_file(mode)
  local file = vim.api.nvim_buf_get_name(0)
  local filetype = vim.bo.filetype
  local cwd = project_root(file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd())

  if vim.uv.fs_stat(cwd .. "/Cargo.toml") then
    return mode == "build" and "cargo build" or "cargo run", cwd
  end

  if filetype == "python" and file ~= "" then
    if mode == "build" then
      return "python -m compileall .", cwd
    end
    return ("python %s"):format(vim.fn.shellescape(file)), cwd
  end

  if (filetype == "typescript" or filetype == "javascript") and vim.uv.fs_stat(cwd .. "/package.json") then
    if mode == "build" then
      return "npm run build", cwd
    end
    return "npm run dev", cwd
  end

  return nil, nil
end

local function ensure_terminal()
  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    if not (M.state.win and vim.api.nvim_win_is_valid(M.state.win)) then
      vim.cmd("botright split")
      vim.cmd(("resize %d"):format(M.state.height))
      M.state.win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(M.state.win, M.state.buf)
    end
    return
  end

  vim.cmd("botright split")
  vim.cmd(("resize %d"):format(M.state.height))
  vim.cmd("terminal")

  M.state.win = vim.api.nvim_get_current_win()
  M.state.buf = vim.api.nvim_get_current_buf()

  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = M.state.buf, silent = true, desc = "Close terminal split" })
  vim.keymap.set("t", "<C-q>", [[<C-\><C-n><cmd>close<CR>]], {
    buffer = M.state.buf,
    silent = true,
    desc = "Close terminal split",
  })
end

function M.run(mode)
  local command, cwd = command_for_file(mode)
  if not command then
    vim.notify("No run/build command for this file type", vim.log.levels.WARN)
    return
  end

  local prev_win = vim.api.nvim_get_current_win()
  ensure_terminal()

  local job = vim.b[M.state.buf].terminal_job_id
  if not job then
    vim.notify("Terminal job not available", vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(job, ("cd %s && %s\n"):format(vim.fn.shellescape(cwd), command))

  if vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
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

return M
