-- ─────────────────────────────────────────────────────────────────────────────
-- snacks.nvim — SL1C3D-L4BS (folke's multi-plugin collection)
-- Replaces: indent-blankline, nvim-notify, toggleterm, vim-illuminate, lazygit.nvim
-- https://github.com/folke/snacks.nvim
-- ─────────────────────────────────────────────────────────────────────────────

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy     = false,
    ---@type snacks.Config
    opts = {
      -- ── Active modules ─────────────────────────────────────────────────
      bigfile   = { enabled = true },        -- auto-disable heavy features for large files
      indent    = {                          -- replaces indent-blankline
        enabled = true,
        char = "│",
        hl = "IblIndent",
        scope = {
          enabled = true,
          hl = "IblScope",
        },
      },
      input     = { enabled = true },        -- better vim.ui.input
      notifier  = {                          -- replaces nvim-notify
        enabled = true,
        timeout = 3000,
        style   = "compact",
        top_down = false,
      },
      picker    = {                          -- telescope-like picker (replaces telescope for common ops)
        enabled = true,
        layout  = {
          reverse = true,
          layout  = { box = "vertical", backdrop = false, width = 0.8, min_width = 80, height = 0.8 },
        },
      },
      quickfile = { enabled = true },        -- faster file open
      words     = {                          -- highlight word under cursor (replaces vim-illuminate)
        enabled  = true,
        debounce = 200,
      },
      terminal  = {                          -- floating/split terminal (replaces toggleterm)
        enabled = true,
        win = {
          border = "rounded",
          wo = { winblend = 10 },
        },
      },
      lazygit   = { enabled = true },        -- lazygit integration (replaces lazygit.nvim)
      gitbrowse = { enabled = true },        -- open current file/line in browser
      bufdelete = { enabled = true },        -- delete buffer without closing split
      zen       = {                          -- zen/focus mode (replaces zen-mode.nvim)
        enabled = true,
        win     = { backdrop = { transparent = true, blend = 40 } },
      },
      dim       = { enabled = false },       -- opt-in: dims inactive code
      scroll    = { enabled = false },       -- disabled: can conflict with NvChad scroll
      explorer  = { enabled = false },       -- disabled: using oil.nvim

      -- ── Disabled (NvChad owns these) ─────────────────────────────────
      dashboard    = { enabled = false },
      statuscolumn = { enabled = false },
    },

    -- ── Key mappings ─────────────────────────────────────────────────────
    keys = {
      -- LazyGit
      { "<leader>gg", function() Snacks.lazygit() end,                    desc = "LazyGit" },
      { "<leader>gf", function() Snacks.lazygit.log_file() end,           desc = "Git file log" },
      { "<leader>gl", function() Snacks.lazygit.log() end,                desc = "Git log" },
      { "<leader>gB", function() Snacks.gitbrowse() end,                  desc = "Git browse (open in browser)" },
      -- Buffer
      { "<leader>bd", function() Snacks.bufdelete() end,                  desc = "Delete buffer" },
      { "<leader>bD", function() Snacks.bufdelete.all() end,              desc = "Delete all buffers" },
      -- Scratch
      { "<leader>.",  function() Snacks.scratch() end,                    desc = "Scratch buffer" },
      -- Zen
      { "<leader>z",  function() Snacks.zen() end,                        desc = "Zen mode" },
      -- Notifications
      { "<leader>nh", function() Snacks.notifier.show_history() end,      desc = "Notification history" },
      -- Picker shortcuts
      { "<leader>ff", function() Snacks.picker.files() end,               desc = "Find files" },
      { "<leader>fg", function() Snacks.picker.grep() end,                desc = "Live grep" },
      { "<leader>fb", function() Snacks.picker.buffers() end,             desc = "Buffers" },
      { "<leader>fr", function() Snacks.picker.recent() end,              desc = "Recent files" },
      { "<leader>fs", function() Snacks.picker.lsp_symbols() end,        desc = "LSP symbols" },
      { "<leader>fd", function() Snacks.picker.diagnostics() end,        desc = "Diagnostics" },
      -- Terminal
      { "<C-\\>",     function() Snacks.terminal() end,                   desc = "Toggle terminal", mode = { "n", "t" } },
      -- Words (navigate between word occurrences)
      { "]]", function() Snacks.words.jump(1, true) end,                  desc = "Next word occurrence" },
      { "[[", function() Snacks.words.jump(-1, true) end,                 desc = "Prev word occurrence" },
    },
  },
}
