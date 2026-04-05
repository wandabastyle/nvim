return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {},
    config = function(_, opts)
      require("mason").setup(opts)

      local ensure_installed = {
        "lua-language-server",
        "nixd",
        "rust-analyzer",
        "pyright",
        "typescript-language-server",
      }

      local registry = require("mason-registry")

      local function ensure_packages()
        for _, name in ipairs(ensure_installed) do
          local ok, pkg = pcall(registry.get_package, name)
          if ok and not pkg:is_installed() then
            pkg:install()
          end
        end
      end

      if registry.refresh then
        registry.refresh(ensure_packages)
      else
        ensure_packages()
      end
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.confirm({ select = true })
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer" },
        }),
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "windwp/nvim-autopairs",
      "williamboman/mason.nvim",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.diagnostic.config({
        virtual_text = true,
        severity_sort = true,
        float = { border = "rounded" },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user-lsp-keymaps", { clear = true }),
        callback = function(event)
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, {
              buffer = event.buf,
              silent = true,
              desc = desc,
            })
          end

          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("n", "gd", vim.lsp.buf.definition, "Go to definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
          map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
          map("n", "gr", vim.lsp.buf.references, "References")
          map("n", "<leader>lr", vim.lsp.buf.rename, "Rename")
          map("n", "<leader>la", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>lf", function()
            vim.lsp.buf.format({ async = true })
          end, "Format")
          map("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
          map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
          map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
        end,
      })

      local servers = {
        lua_ls = {
          capabilities = capabilities,
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
              hint = { enable = true },
            },
          },
        },
        nixd = {
          capabilities = capabilities,
          settings = {
            nixd = {
              formatting = { command = { "nixfmt" } },
            },
          },
        },
        rust_analyzer = {
          capabilities = capabilities,
        },
        pyright = {
          capabilities = capabilities,
        },
        ts_ls = {
          capabilities = capabilities,
        },
      }

      for server, config in pairs(servers) do
        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end

      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
}
