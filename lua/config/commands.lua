local project_terminal = require("features.project_terminal")

vim.api.nvim_create_user_command("ProjectRun", function()
	project_terminal.run("run")
end, {})
vim.api.nvim_create_user_command("ProjectBuild", function()
	project_terminal.run("build")
end, {})

vim.api.nvim_create_user_command("ConfigHealth", function()
	local tools = {
		"git",
		"rg",
		"fd",
		"python3",
		"stylua",
		"ruff",
		"ty",
		"rustfmt",
		"nixfmt",
		"prettier",
		"npm",
		"ollama",
	}

	local installed = {}
	local missing = {}

	for _, tool in ipairs(tools) do
		if vim.fn.executable(tool) == 1 then
			table.insert(installed, tool)
		else
			table.insert(missing, tool)
		end
	end

	local lines = {
		("Installed (%d): %s"):format(#installed, #installed > 0 and table.concat(installed, ", ") or "(none)"),
		("Missing (%d): %s"):format(#missing, #missing > 0 and table.concat(missing, ", ") or "(none)"),
	}

	vim.notify(table.concat(lines, "\n"), #missing == 0 and vim.log.levels.INFO or vim.log.levels.WARN, {
		title = "Config health",
	})
end, {})
