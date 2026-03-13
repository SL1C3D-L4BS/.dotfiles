-- ─────────────────────────────────────────────────────────────────────────────
-- avante.nvim — AI coding assistant (Cursor-style, inside Neovim)
-- Pointed at OpenClaw gateway: http://127.0.0.1:18789/v1
-- https://github.com/yetone/avante.nvim
-- ─────────────────────────────────────────────────────────────────────────────

return {
  {
    "yetone/avante.nvim",
    event       = "VeryLazy",
    version     = false,         -- latest main (avante moves fast)
    build       = "make",        -- compiles the Rust binary on first load
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts  = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name  = false,
            drag_and_drop = { insert_mode = true },
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = { file_types = { "markdown", "Avante" } },
        ft   = { "markdown", "Avante" },
      },
    },

    opts = {
      -- ── OpenClaw gateway (OpenAI-compatible local endpoint) ────────────
      provider = "openclaw",
      providers = {
        openclaw = {
          __inherited_from = "openai",
          endpoint         = "http://127.0.0.1:18789/v1",
          -- Use a dummy key — gateway authenticates differently
          api_key_name     = "cmd:echo sk-local",
          model            = "gpt-4o",
          timeout          = 30000,
          extra_request_body = {
            temperature = 0.7,
            max_tokens  = 8192,
          },
        },
      },

      -- ── Behaviour ──────────────────────────────────────────────────────
      behaviour = {
        auto_suggestions                    = false,
        auto_set_highlight_group            = true,
        auto_set_keymaps                    = true,
        auto_apply_diff_after_generation    = false,
        support_paste_from_clipboard        = true,
      },

      -- ── UI ─────────────────────────────────────────────────────────────
      windows = {
        position = "right",
        wrap     = true,
        width    = 40,
        sidebar_header = {
          align   = "center",
          rounded = true,
        },
        ask = {
          floating  = false,
          start_insert = true,
          border = "rounded",
        },
      },

      -- ── Diff view ──────────────────────────────────────────────────────
      diff = {
        autojump = true,
        list_opener = "copen",
      },

      -- ── Hints ──────────────────────────────────────────────────────────
      hints = { enabled = true },
    },
  },
}
