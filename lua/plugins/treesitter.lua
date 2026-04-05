return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = {
          "lua",
          "nix",
          "rust",
          "python",
          "javascript",
          "typescript",
          "tsx",
          "json",
          "markdown",
          "vim",
          "bash",
          "markdown_inline",
          "vimdoc",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
