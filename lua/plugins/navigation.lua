return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        sorting_strategy = "ascending",
      },
    },
  },
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    opts = {
      view_options = {
        show_hidden = true,
      },
      skip_confirm_for_simple_edits = true,
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
}
