local project_terminal = require("features.project_terminal")

project_terminal.setup()

vim.api.nvim_create_user_command("ProjectRun", function()
  project_terminal.run("run")
end, { desc = "Run current project/file" })

vim.api.nvim_create_user_command("ProjectBuild", function()
  project_terminal.run("build")
end, { desc = "Build current project" })
