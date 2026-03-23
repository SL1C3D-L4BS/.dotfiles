-- ══════════════════════════════════════════════════════════════
-- Plugin definitions — lazy.nvim | startup target <70ms
-- All plugins lazy-loaded aggressively
-- ══════════════════════════════════════════════════════════════

return {
  -- ── Override NvChad defaults ──────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua","python","rust","go","javascript","typescript","tsx",
        "json","yaml","toml","markdown","bash","html","css","sql","nix",
      },
      highlight    = { enable = true },
      indent       = { enable = true },
      auto_install = true,
    },
  },

  -- ── LSP + Mason ───────────────────────────────────────────
  {
    "williamboman/mason.nvim",
    cmd  = { "Mason", "MasonInstall" },
    opts = { ui = { border = "rounded" } },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = "BufReadPre",
    dependencies = { "mason.nvim", "nvim-lspconfig" },
    opts = {
      ensure_installed = {
        "lua_ls","pyright","ruff_lsp","rust_analyzer","gopls",
        "ts_ls","jsonls","yamlls","taplo","bashls","nixd",
      },
      automatic_installation = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    event        = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-lspconfig.nvim", "hrsh7th/cmp-nvim-lsp" },
    config       = function()
      local lsp = require("lspconfig")
      local cap = require("cmp_nvim_lsp").default_capabilities()

      local servers = {
        "lua_ls","pyright","ruff_lsp","gopls","ts_ls",
        "jsonls","yamlls","taplo","bashls","nixd",
      }
      for _, s in ipairs(servers) do
        lsp[s].setup({ capabilities = cap })
      end

      -- Rust analyzer special config
      lsp.rust_analyzer.setup({
        capabilities = cap,
        settings = { ["rust-analyzer"] = { checkOnSave = { command = "clippy" } } },
      })

      -- Diagnostics UI
      vim.diagnostic.config({
        virtual_text  = { prefix = "●" },
        signs         = true,
        underline     = true,
        update_in_insert = false,
        severity_sort = true,
        float         = { border = "rounded" },
      })
    end,
  },

  -- ── Formatting ────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event  = "BufWritePre",
    opts   = {
      formatters_by_ft = {
        lua        = { "stylua" },
        python     = { "ruff_format", "isort" },
        rust       = { "rustfmt" },
        go         = { "goimports", "gofmt" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json       = { "prettier" },
        yaml       = { "prettier" },
        markdown   = { "prettier" },
        sh         = { "shfmt" },
        nix        = { "alejandra" },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
  },

  -- ── Completion ────────────────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    event        = "InsertEnter",
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
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"]   = cmp.mapping.select_next_item(),
          ["<C-p>"]   = cmp.mapping.select_prev_item(),
          ["<C-d>"]   = cmp.mapping.scroll_docs(4),
          ["<C-u>"]   = cmp.mapping.scroll_docs(-4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]    = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]   = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip"  },
          { name = "path"     },
        }, {
          { name = "buffer", keyword_length = 3 },
        }),
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          format = function(_, item)
            local icons = require("nvchad.icons.lspkind")
            item.kind = (icons[item.kind] or "") .. item.kind
            return item
          end,
        },
      })
    end,
  },

  -- ── Telescope ─────────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    cmd          = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    opts = {
      defaults = {
        prompt_prefix   = "  ",
        selection_caret = " ",
        file_ignore_patterns = { ".git/", "node_modules/", ".direnv/", "target/" },
        layout_config   = { horizontal = { preview_width = 0.55 } },
      },
      extensions = { fzf = {} },
    },
    config = function(_, opts)
      local t = require("telescope")
      t.setup(opts)
      t.load_extension("fzf")
    end,
  },

  -- ── AI: CodeCompanion ─────────────────────────────────────
  {
    "olimorris/codecompanion.nvim",
    cmd          = { "CodeCompanion", "CodeCompanionChat" },
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    opts = {
      strategies = {
        chat   = { adapter = "ollama" },
        inline = { adapter = "ollama" },
      },
      adapters = {
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            schema = {
              model = { default = "llama3.2" },
            },
          })
        end,
      },
    },
  },

  -- ── LazyGit ───────────────────────────────────────────────
  {
    "kdheepak/lazygit.nvim",
    cmd          = "LazyGit",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- ── Terminal ──────────────────────────────────────────────
  {
    "akinsho/toggleterm.nvim",
    cmd  = "ToggleTerm",
    opts = {
      size         = function(term)
        return term.direction == "horizontal" and 15 or vim.o.columns * 0.35
      end,
      open_mapping = [[<c-\>]],
      direction    = "float",
      float_opts   = { border = "curved" },
    },
  },

  -- ── File tree ─────────────────────────────────────────────
  {
    "nvim-tree/nvim-tree.lua",
    cmd  = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = {
      view   = { width = 30 },
      git    = { enable = true },
      renderer = { group_empty = true },
      filters = { dotfiles = false },
    },
  },

  -- ── Which-key ─────────────────────────────────────────────
  {
    "folke/which-key.nvim",
    keys  = { "<leader>", "<c-r>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    opts  = {},
  },

  -- ── Git signs ─────────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    opts  = {
      signs = {
        add    = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
      },
    },
  },

  -- ── Better diagnostics ────────────────────────────────────
  {
    "folke/trouble.nvim",
    cmd  = { "Trouble" },
    opts = { use_diagnostic_signs = true },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics" },
    },
  },

  -- ── Autopairs ─────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts  = { check_ts = true },
  },

  -- ── Comments ──────────────────────────────────────────────
  {
    "numToStr/Comment.nvim",
    keys  = { "gc", "gb" },
    opts  = {},
  },

  -- ── Indent guides ─────────────────────────────────────────
  {
    "lukas-reineke/indent-blankline.nvim",
    event  = "BufReadPre",
    main   = "ibl",
    opts   = {
      scope = { enabled = true },
      indent = { char = "│" },
    },
  },

  -- ── Todo comments ─────────────────────────────────────────
  {
    "folke/todo-comments.nvim",
    event        = "BufReadPre",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts         = {},
  },
}
