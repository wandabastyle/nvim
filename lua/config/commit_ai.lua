local M = {}
local ollama = require("config.ollama")
local commit_script = vim.fs.normalize(vim.fn.stdpath("config") .. "/scripts/git-commit-ai.py")

local function current_buffer_file()
	local file = vim.api.nvim_buf_get_name(0)

	if file == "" then
		return nil
	end

	return vim.fs.normalize(vim.fn.fnamemodify(file, ":p"))
end

-- Return the directory of the current buffer, or the current working directory.
local function current_buffer_dir()
	local file = current_buffer_file()

	if not file then
		return vim.uv.cwd()
	end

	return vim.fn.fnamemodify(file, ":p:h")
end

local function repo_relative_path(git_root, file)
	local relative = vim.fs.relpath(git_root, file)

	if not relative or vim.startswith(relative, "..") then
		return nil
	end

	return relative
end

local function get_current_file_status(git_root, relative_file, callback)
	vim.system(
		{ "git", "status", "--porcelain", "--", relative_file },
		{ cwd = git_root, text = true },
		function(result)
			vim.schedule(function()
				if result.code ~= 0 then
					local stderr_text = vim.trim(result.stderr or "")
					callback(nil, stderr_text ~= "" and stderr_text or "Could not inspect current file status")
					return
				end

				callback(vim.trim(result.stdout or ""), nil)
			end)
		end
	)
end

local function notify_other_changes(git_root, relative_file)
	vim.system({ "git", "status", "--porcelain" }, { cwd = git_root, text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				return
			end

			local other_count = 0

			for line in (result.stdout or ""):gmatch("[^\r\n]+") do
				local path = line:sub(4)

				if path ~= relative_file and not vim.endswith(path, " -> " .. relative_file) then
					other_count = other_count + 1
				end
			end

			if other_count > 0 then
				vim.notify(
					("Committing only %s; %d other changed path(s) will be left untouched"):format(
						relative_file,
						other_count
					),
					vim.log.levels.INFO,
					{ title = "Git commit" }
				)
			end
		end)
	end)
end

-- Find the git repo root for the current buffer context.
local function in_git_repo(callback)
	local buffer_dir = current_buffer_dir()

	vim.system({ "git", "-C", buffer_dir, "rev-parse", "--show-toplevel" }, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				callback(nil)
				return
			end

			local git_root = vim.trim(result.stdout or "")

			if git_root == "" then
				callback(nil)
				return
			end

			callback(git_root)
		end)
	end)
end

-- Run the local Python helper and return a suggested commit message.
local function run_commit_message_ai(git_root, callback)
	vim.system({ "python3", commit_script }, { cwd = git_root, text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				local stderr_text = vim.trim(result.stderr or "")
				callback(nil, "AI script failed: " .. stderr_text)
				return
			end

			local suggestion = vim.trim(result.stdout or "")

			if suggestion == "" then
				callback(nil, "AI script returned an empty message")
				return
			end

			callback(suggestion, nil)
		end)
	end)
end

-- Commit only the current buffer path, leaving unrelated repo changes untouched.
local function commit_with_message(git_root, relative_file, message, callback)
	vim.system(
		{ "git", "commit", "-m", message, "--", relative_file },
		{ cwd = git_root, text = true },
		function(result)
			vim.schedule(function()
				if result.code == 0 then
					callback(true, vim.trim(result.stdout or ""))
					return
				end

				local stderr_text = vim.trim(result.stderr or "")

				if stderr_text == "" then
					stderr_text = vim.trim(result.stdout or "")
				end

				callback(false, stderr_text)
			end)
		end
	)
end

-- Main workflow for <leader>gm: write buffer -> suggest -> edit -> commit current file.
local function git_write()
	local file = current_buffer_file()

	if not file then
		vim.notify("Current buffer has no file path", vim.log.levels.ERROR)
		return
	end

	local wrote_ok = pcall(vim.cmd, "write")

	if not wrote_ok then
		vim.notify("Could not save current buffer", vim.log.levels.ERROR)
		return
	end

	in_git_repo(function(git_root)
		if not git_root then
			vim.notify("Not inside a git repository", vim.log.levels.ERROR)
			return
		end

		local relative_file = repo_relative_path(git_root, file)

		if not relative_file then
			vim.notify("Current file is outside the git repository", vim.log.levels.ERROR)
			return
		end

		get_current_file_status(git_root, relative_file, function(status, status_err)
			if status_err then
				vim.notify(status_err, vim.log.levels.ERROR)
				return
			end

			if not status or status == "" then
				vim.notify("Current file has no git changes", vim.log.levels.INFO)
				return
			end

			if status:match("^%?%?") then
				vim.notify("Current file is untracked; stage it first before committing", vim.log.levels.WARN)
				return
			end

			notify_other_changes(git_root, relative_file)

			ollama.ensure_running(function()
				run_commit_message_ai(git_root, function(suggested_message, err)
					if err then
						vim.notify(err, vim.log.levels.ERROR)
						return
					end

					vim.ui.input({
						prompt = "Git commit message for " .. relative_file .. ": ",
						default = suggested_message,
					}, function(input)
						if input == nil then
							vim.notify("Commit canceled", vim.log.levels.INFO)
							return
						end

						local final_message = vim.trim(input)

						if final_message == "" then
							vim.notify("Empty commit message. Aborted.", vim.log.levels.INFO)
							return
						end

						commit_with_message(git_root, relative_file, final_message, function(ok, output)
							if ok then
								local success_text = "Commit created for " .. relative_file

								if output ~= "" then
									success_text = success_text .. ": " .. output
								end

								vim.notify(success_text, vim.log.levels.INFO)
								return
							end

							vim.notify("git commit failed: " .. output, vim.log.levels.ERROR)
						end)
					end)
				end)
			end)
		end)
	end)
end

function M.setup()
	vim.keymap.set("n", "<leader>gm", git_write, {
		desc = "Save and commit current file with AI message",
		silent = true,
	})
end

M.in_git_repo = in_git_repo
M.run_commit_message_ai = run_commit_message_ai
M.commit_with_message = commit_with_message
M.git_write = git_write

return M
