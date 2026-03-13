-- ─────────────────────────────────────────────────────────────────────────────
-- extras.lua — SL1C3D-L4BS additional Neovim plugins (2026 frontier)
-- ─────────────────────────────────────────────────────────────────────────────

return {
  -- ── smear-cursor.nvim — animated cursor smear (folke) ──────────────────────
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts  = {
      stiffness            = 0.8,
      trailing_exponent    = 0.1,
      hide_target_hack     = true,
      legacy_computing_symbols_support = false,
      -- Use brand accent color for the smear trail
      cursor_color         = "#5865F2",
      normal_bg            = "#0d0d0d",
    },
  },

  -- ── render-markdown.nvim — in-editor markdown rendering ────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft   = { "markdown", "Avante" },
    opts = {
      file_types    = { "markdown", "Avante" },
      render_modes  = { "n", "c" },
      heading       = {
        enabled = true,
        icons   = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
        backgrounds = false,
        foregrounds = true,
      },
      code = {
        enabled    = true,
        sign       = false,
        style      = "full",           -- "full" = language + border + content
        width      = "block",
        border     = "thin",
      },
      dash           = { enabled = true },
      bullet         = { enabled = true },
      checkbox       = { enabled = true },
      quote          = { enabled = true },
      table          = { enabled = true, style = "full" },
      link           = { enabled = true },
      callout        = { enabled = true },
    },
  },

  -- ── trouble.nvim v3 — diagnostics panel ────────────────────────────────────
  {
    "folke/trouble.nvim",
    cmd  = { "Trouble" },
    opts = {
      auto_close   = false,
      focus        = true,
      follow       = true,
      indent_guides = true,
      multiline    = true,
      modes = {
        symbols = {
          win = { position = "right", size = { width = 0.3 } },
        },
      },
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",  desc = "Buffer diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>",               desc = "Workspace diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>",       desc = "Symbols (Trouble)" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<cr>",                   desc = "Location list" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>",                    desc = "Quickfix list" },
      { "[x",         function() require("trouble").prev({ skip_groups = true, jump = true }) end, desc = "Prev trouble item" },
      { "]x",         function() require("trouble").next({ skip_groups = true, jump = true }) end, desc = "Next trouble item" },
    },
  },

  -- ── diffview.nvim — git diff + merge tool ──────────────────────────────────
  {
    "sindrets/diffview.nvim",
    cmd  = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>",                     desc = "Diff view (git)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>",            desc = "File history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>",              desc = "Repo history" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>",                    desc = "Close diff view" },
    },
    opts = {
      enhanced_diff_hl = true,
      show_help_hints  = false,
      view = {
        default = {
          layout = "diff2_horizontal",
          winbar_info = false,
        },
        merge_tool = {
          layout = "diff3_horizontal",
          disable_diagnostics = true,
        },
      },
      file_panel = {
        listing_style = "tree",
        tree_options  = { flatten_dirs = true },
        win_config    = { position = "left", width = 35 },
      },
    },
  },
}
