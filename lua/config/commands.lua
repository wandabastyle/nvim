local terminal = require("util.project_terminal")

vim.api.nvim_create_user_command("ProjectRun", function()
  terminal.run("run")
end, { desc = "Run project/file in terminal split" })

vim.api.nvim_create_user_command("ProjectBuild", function()
  terminal.run("build")
end, { desc = "Build project in terminal split" })
