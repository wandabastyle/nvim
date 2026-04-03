local M = {
	state = {
		buf = nil,
		win = nil,
		height = 12,
	},
}

local function find_project_root(markers, startpath)
	local found = vim.fs.find(markers, { upward = true, path = startpath, stop = vim.uv.os_homedir() })
	if #found == 0 then
		return nil
	end
	return vim.fs.dirname(found[1])
end

local function project_command(mode)
	local file = vim.api.nvim_buf_get_name(0)
	local from = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
	local root = find_project_root({ "Cargo.toml" }, from)

	if root then
		return mode == "build" and "cargo build" or "cargo run", root
	end

	if vim.bo.filetype == "python" and file ~= "" then
		if mode == "build" then
			return nil, nil, "Python has no default build target (use :ProjectRun)"
		end
		return ("python %s"):format(vim.fn.shellescape(file)), vim.fn.getcwd()
	end

	if mode == "build" then
		return nil, nil, "No supported build target found for this project"
	end

	return nil, nil, "No supported project type found (Rust/Cargo or Python file)"
end

local function ensure_terminal_window()
	if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
		if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
			vim.api.nvim_set_current_win(M.state.win)
		else
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

local function restore_window(win)
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_current_win(win)
		return true
	end
	return false
end

function M.run(mode)
	local cmd, cwd, err = project_command(mode)
	if not cmd then
		vim.notify(err, vim.log.levels.WARN)
		return
	end

	local prev_win = vim.api.nvim_get_current_win()
	ensure_terminal_window()

	local job = M.state.buf and vim.b[M.state.buf].terminal_job_id or nil
	if not job then
		vim.notify("Project terminal is unavailable", vim.log.levels.ERROR)
		return
	end

	vim.fn.chansend(job, ("cd %s && %s\n"):format(vim.fn.shellescape(cwd), cmd))
	restore_window(prev_win)
end

function M.focus()
	ensure_terminal_window()
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
		callback = function(ev)
			if ev.buf == M.state.buf and vim.v.event.status ~= 0 then
				vim.notify(("Project terminal exited with code %d"):format(vim.v.event.status), vim.log.levels.WARN)
			end
		end,
	})
end

return M
