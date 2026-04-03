local project_runner = { buf = nil, win = nil }

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

	if mode == "build" then
		return nil, nil, "No supported build target found for this project"
	end

	if file ~= "" and vim.bo.filetype == "python" then
		return ("python %s"):format(vim.fn.shellescape(file)), vim.fn.getcwd()
	end

	return nil, nil, "No supported project type found (Rust/Cargo or Python file)"
end

local function run_in_project_terminal(mode)
	local cmd, cwd, err = project_command(mode)
	if not cmd then
		vim.notify(err, vim.log.levels.WARN)
		return
	end

	if project_runner.buf and vim.api.nvim_buf_is_valid(project_runner.buf) then
		local job = vim.b[project_runner.buf].terminal_job_id
		if not project_runner.win or not vim.api.nvim_win_is_valid(project_runner.win) then
			vim.cmd("botright split")
			vim.cmd("resize 12")
			project_runner.win = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(project_runner.win, project_runner.buf)
		else
			vim.api.nvim_set_current_win(project_runner.win)
		end

		if job then
			vim.fn.chansend(job, ("cd %s && %s\n"):format(vim.fn.shellescape(cwd), cmd))
		end
		vim.cmd("startinsert")
		return
	end

	vim.cmd("botright split")
	vim.cmd("resize 12")
	vim.cmd("terminal")
	project_runner.win = vim.api.nvim_get_current_win()
	project_runner.buf = vim.api.nvim_get_current_buf()
	local job = vim.b[project_runner.buf].terminal_job_id
	vim.fn.chansend(job, ("cd %s && %s\n"):format(vim.fn.shellescape(cwd), cmd))
	vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = project_runner.buf, silent = true, desc = "Close project terminal" })
	vim.keymap.set("t", "<C-q>", [[<C-\><C-n><cmd>close<CR>]], { buffer = project_runner.buf, silent = true, desc = "Close project terminal" })
	vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("ProjectRun", function()
	run_in_project_terminal("run")
end, {})
vim.api.nvim_create_user_command("ProjectBuild", function()
	run_in_project_terminal("build")
end, {})
vim.keymap.set("n", "<leader>rr", "<cmd>ProjectRun<CR>", { silent = true, desc = "Run project/current file" })
vim.keymap.set("n", "<leader>rb", "<cmd>ProjectBuild<CR>", { silent = true, desc = "Build project" })
