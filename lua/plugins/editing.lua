return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
      enable_check_bracket_line = false,
    },
  },
  {
    "ethanholz/nvim-lastplace",
    event = "BufReadPost",
    opts = {
      lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
      lastplace_ignore_filetype = { "gitcommit", "gitrebase" },
      lastplace_open_folds = true,
    },
  },
}
