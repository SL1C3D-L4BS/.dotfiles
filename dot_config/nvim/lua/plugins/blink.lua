-- ─────────────────────────────────────────────────────────────────────────────
-- blink.cmp — SL1C3D-L4BS (replaces nvim-cmp; ships prebuilt Rust binary)
-- https://github.com/saghen/blink.cmp
-- ─────────────────────────────────────────────────────────────────────────────

return {
  {
    "saghen/blink.cmp",
    version      = "1.*",
    event        = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts = {
      -- Keymap preset — default with some overrides
      keymap = {
        preset = "default",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<CR>"]      = { "accept", "fallback" },
        ["<Tab>"]     = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"]   = { "snippet_backward", "select_prev", "fallback" },
        ["<C-e>"]     = { "cancel", "fallback" },
        ["<C-y>"]     = { "accept" },
        ["<C-k>"]     = { "scroll_documentation_up", "fallback" },
        ["<C-j>"]     = { "scroll_documentation_down", "fallback" },
        ["<Up>"]      = { "select_prev", "fallback" },
        ["<Down>"]    = { "select_next", "fallback" },
      },

      appearance = {
        nerd_font_variant = "mono",
      },

      completion = {
        accept = {
          auto_brackets = { enabled = true },
        },
        documentation = {
          auto_show            = true,
          auto_show_delay_ms   = 200,
          update_delay_ms      = 50,
          window = {
            border = "rounded",
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine",
          },
        },
        ghost_text = { enabled = false },
        menu = {
          border = "rounded",
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection",
          draw = {
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
            },
          },
        },
      },

      sources = {
        default     = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {},
      },

      -- Cmdline (Shift+:): config lives at top-level cmdline.sources, not sources.cmdline
      cmdline = {
        sources = { "buffer", "cmdline" },
      },

      -- Use Lua fuzzy to avoid Rust binary/trace errors (e.g. "failed to run" in sources)
      fuzzy = {
        implementation = "lua",
      },

      signature = { enabled = true },
    },
    opts_extend = { "sources.default" },
  },
}
