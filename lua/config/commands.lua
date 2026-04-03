local project_terminal = require("features.project_terminal")

vim.api.nvim_create_user_command("ProjectRun", function() project_terminal.run("run") end, {})
vim.api.nvim_create_user_command("ProjectBuild", function() project_terminal.run("build") end, {})
