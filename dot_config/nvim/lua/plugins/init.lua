return {
  -- Disable NvChad's nvim-cmp so blink.cmp is the only completion engine (avoids duplicate engines and require("cmp") errors)
  { "hrsh7th/nvim-cmp", enabled = false },

  -- Standalone autopairs (NvChad's was tied to nvim-cmp; no cmp integration for blink.cmp)
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      fast_wrap = {},
      disable_filetype = { "TelescopePrompt", "vim" },
    },
    config = function(_, opts)
      require("nvim-autopairs").setup(opts)
    end,
  },

  { import = "plugins.devicons" },

  -- ─── Formatting ────────────────────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  -- ─── LSP ───────────────────────────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- ─── Treesitter: syntax, indent, fold ─────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc", "query",
        "python", "javascript", "typescript", "tsx",
        "rust", "go", "html", "css", "scss",
        "json", "toml", "yaml", "bash",
        "markdown", "markdown_inline",
        "regex", "c", "cpp", "java",
      },
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    },
  },

  -- ─── Indent guides ─────────────────────────────────────────────────────────
  -- Replaced by snacks.nvim indent module (see plugins/snacks.lua)
  -- Kept disabled here to avoid conflicts
  {
    "lukas-reineke/indent-blankline.nvim",
    enabled = false,
  },

  -- ─── Git signs in gutter ──────────────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPost",
    opts = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
        untracked    = { text = "▎" },
      },
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 500,
      },
    },
  },

  -- ─── Better notifications + command-line UI ───────────────────────────────
  -- nvim-notify replaced by snacks.notifier; noice kept for cmdline/lsp UI
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },   -- nvim-notify removed
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        hover = { enabled = true },
        signature = { enabled = true },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },
      views = {
        cmdline_popup = {
          position = { row = "40%", col = "50%" },
          size = { width = 60, min_width = 60, height = "auto" },
          border = { style = "rounded", padding = { 0, 1 } },
          win_options = { winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" } },
        },
      },
    },
  },

  -- ─── Telescope UI select (code actions → telescope picker) ────────────────
  {
    "nvim-telescope/telescope-ui-select.nvim",
    lazy = true,
    config = function()
      require("telescope").load_extension("ui-select")
    end,
  },

  -- ─── Oil.nvim: file browser as a buffer ───────────────────────────────────
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = { { "<leader>o", "<cmd>Oil<cr>", desc = "Open parent dir (Oil)" } },
    opts = {
      view_options = { show_hidden = true },
      float = {
        padding = 2,
        max_width = 80,
        max_height = 30,
        border = "rounded",
        win_options = { winblend = 10 },
      },
    },
  },
}
