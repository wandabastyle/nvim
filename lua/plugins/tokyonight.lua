return {
  'folke/tokyonight.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    require('tokyonight').setup {
      style = 'moon', -- "storm", "night", "moon", "day"
      transparent = false, -- enable transparency
      terminal_colors = true,
      styles = {
        comments = { italic = false },
        keywords = { italic = false },
        sidebars = 'transparent',
        floats = 'transparent',
      },
    }

    -- Load colorscheme
    vim.cmd.colorscheme 'tokyonight'

    -- Toggle transparency
    vim.g.tokyo_transparent = true
    local function toggle_transparency()
      vim.g.tokyo_transparent = not vim.g.tokyo_transparent
      require('tokyonight').setup {
        style = 'moon',
        transparent = vim.g.tokyo_transparent,
      }
      vim.cmd.colorscheme 'tokyonight'
    end

    vim.keymap.set('n', '<leader>bg', toggle_transparency, { noremap = true, silent = true })
  end,
}
