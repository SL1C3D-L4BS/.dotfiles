-- ══════════════════════════════════════════════════════════════
-- Custom plugins — NvChad 2.5 | lazy.nvim | 2026
-- All plugins lazy-loaded; NvChad core loaded via init.lua import
-- ══════════════════════════════════════════════════════════════

return {

  -- ── Treesitter — override NvChad defaults ─────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua","python","rust","go","javascript","typescript","tsx",
        "json","yaml","toml","markdown","markdown_inline","bash",
        "html","css","sql","nix","regex","vim","vimdoc",
      },
      highlight    = { enable = true, additional_vim_regex_highlighting = false },
      indent       = { enable = true },
      auto_install = true,
    },
  },

  -- ── Mason (LSP installer) ──────────────────────────────────
  {
    "williamboman/mason.nvim",
    cmd  = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = {
      ui = {
        border = "rounded",
        icons  = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
      },
    },
  },

  -- ── Mason-lspconfig bridge ────────────────────────────────
  {
    "williamboman/mason-lspconfig.nvim",
    event        = "BufReadPre",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = {
        "lua_ls", "pyright", "rust_analyzer", "gopls",
        "ts_ls", "jsonls", "yamlls", "taplo", "bashls",
      },
      automatic_installation = true,
    },
  },

  -- ── LSP config ────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    event        = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "b0o/schemastore.nvim",
    },
    config = function()
      local lsp = require("lspconfig")
      local cap = vim.tbl_deep_extend("force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities()
      )

      -- Borders for hover/signature
      vim.lsp.handlers["textDocument/hover"]          = vim.lsp.with(vim.lsp.handlers.hover,          { border = "rounded" })
      vim.lsp.handlers["textDocument/signatureHelp"]  = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

      -- Diagnostics
      vim.diagnostic.config({
        virtual_text  = { prefix = "●", source = "if_many" },
        signs         = { text = { [1]=" ", [2]=" ", [3]=" ", [4]=" " } },
        underline     = true,
        update_in_insert = false,
        severity_sort = true,
        float         = { border = "rounded", source = true },
      })

      -- Generic on_attach
      local on_attach = function(_, bufnr)
        local opts = { buffer = bufnr, silent = true }
        vim.keymap.set("n", "gd",         vim.lsp.buf.definition,      opts)
        vim.keymap.set("n", "gD",         vim.lsp.buf.declaration,     opts)
        vim.keymap.set("n", "gr",         "<cmd>Telescope lsp_references<CR>", opts)
        vim.keymap.set("n", "gi",         vim.lsp.buf.implementation,  opts)
        vim.keymap.set("n", "K",          vim.lsp.buf.hover,           opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action,     opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,          opts)
        vim.keymap.set("n", "<leader>ds", "<cmd>Telescope lsp_document_symbols<CR>", opts)
        vim.keymap.set("n", "[d",         vim.diagnostic.goto_prev,    opts)
        vim.keymap.set("n", "]d",         vim.diagnostic.goto_next,    opts)
      end

      -- Servers
      local servers = {
        pyright      = {},
        gopls        = { settings = { gopls = { gofumpt = true } } },
        ts_ls        = {},
        bashls       = {},
        taplo        = {},
        rust_analyzer = {
          settings = { ["rust-analyzer"] = { checkOnSave = { command = "clippy" } } },
        },
        lua_ls = {
          settings = {
            Lua = {
              runtime   = { version = "LuaJIT" },
              workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
              telemetry = { enable = false },
              diagnostics = { globals = { "vim" } },
            },
          },
        },
        jsonls = {
          settings = {
            json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } },
          },
        },
        yamlls = {
          settings = {
            yaml = { schemaStore = { enable = false, url = "" },
                     schemas = require("schemastore").yaml.schemas() },
          },
        },
      }

      for name, cfg in pairs(servers) do
        lsp[name].setup(vim.tbl_deep_extend("force", {
          on_attach    = on_attach,
          capabilities = cap,
        }, cfg))
      end
    end,
  },

  -- ── Formatting ────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event  = "BufWritePre",
    cmd    = "ConformInfo",
    opts   = {
      formatters_by_ft = {
        lua        = { "stylua" },
        python     = { "ruff_format", "ruff_organize_imports" },
        rust       = { "rustfmt" },
        go         = { "goimports", "gofmt" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json       = { "prettier" },
        yaml       = { "prettier" },
        markdown   = { "prettier" },
        sh         = { "shfmt" },
        bash       = { "shfmt" },
        toml       = { "taplo" },
      },
      format_on_save  = { timeout_ms = 800, lsp_fallback = true },
      notify_on_error = false,
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
      "hrsh7th/cmp-cmdline",
      { "L3MON4D3/LuaSnip", build = "make install_jsregexp", version = "v2.*" },
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line-1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        window  = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"]     = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-p>"]     = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-d>"]     = cmp.mapping.scroll_docs(4),
          ["<C-u>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = false }),
          ["<Tab>"]     = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip",  priority = 750 },
          { name = "path",     priority = 500 },
        }, {
          { name = "buffer", priority = 250, keyword_length = 3 },
        }),
        formatting = {
          expandable_indicator = true,
          format = function(_, item)
            -- Use NvChad icons if available, else fallback
            local ok, icons = pcall(require, "nvchad.icons.lspkind")
            if ok and icons[item.kind] then
              item.kind = icons[item.kind] .. " " .. item.kind
            end
            item.menu = nil  -- clean up menu column
            return item
          end,
        },
      })

      -- Cmdline completion
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
      })
    end,
  },

  -- ── Telescope ─────────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    cmd          = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = vim.fn.executable("make") == 1 },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    opts = function()
      local actions = require("telescope.actions")
      return {
        defaults = {
          prompt_prefix   = "  ",
          selection_caret = " ",
          path_display    = { "truncate" },
          sorting_strategy = "ascending",
          layout_config   = { horizontal = { prompt_position = "top", preview_width = 0.55 } },
          file_ignore_patterns = { "%.git/", "node_modules/", "%.direnv/", "target/", "%.lock" },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<Esc>"] = actions.close,
            },
          },
        },
        pickers = {
          find_files = { hidden = true },
          live_grep  = { additional_args = { "--hidden" } },
        },
        extensions = {
          fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true },
          ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
      }
    end,
    config = function(_, opts)
      local t = require("telescope")
      t.setup(opts)
      pcall(t.load_extension, "fzf")
      pcall(t.load_extension, "ui-select")
    end,
  },

  -- ── AI: CodeCompanion (local ollama) ──────────────────────
  {
    "olimorris/codecompanion.nvim",
    cmd          = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "hrsh7th/nvim-cmp",
    },
    opts = {
      strategies = {
        chat   = { adapter = "ollama" },
        inline = { adapter = "ollama" },
        agent  = { adapter = "ollama" },
      },
      adapters = {
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            env    = { url = "http://127.0.0.1:11434" },
            schema = { model = { default = "llama3.2" } },
          })
        end,
      },
      display = {
        chat = { window = { layout = "vertical", width = 0.4 } },
      },
    },
    keys = {
      { "<leader>ai", "<cmd>CodeCompanionChat<CR>",    desc = "AI Chat",    mode = { "n", "v" } },
      { "<leader>aa", "<cmd>CodeCompanionChat Add<CR>",desc = "AI Add",     mode = "v" },
      { "<leader>ac", "<cmd>CodeCompanion<CR>",        desc = "AI Inline",  mode = { "n", "v" } },
      { "<leader>aA", "<cmd>CodeCompanionActions<CR>", desc = "AI Actions", mode = { "n", "v" } },
    },
  },

  -- ── LazyGit ───────────────────────────────────────────────
  {
    "kdheepak/lazygit.nvim",
    cmd          = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = { { "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit" } },
  },

  -- ── Terminal ──────────────────────────────────────────────
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd     = "ToggleTerm",
    keys    = {
      { "<C-\\>",    "<cmd>ToggleTerm<CR>",                        desc = "Toggle terminal" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>",        desc = "Float terminal" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>",   desc = "H terminal" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>",     desc = "V terminal" },
    },
    opts = {
      size = function(term)
        return term.direction == "horizontal" and 15 or math.floor(vim.o.columns * 0.35)
      end,
      open_mapping     = [[<c-\>]],
      direction        = "float",
      float_opts       = { border = "curved" },
      shade_terminals  = false,
      persist_mode     = true,
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)
      -- ESC exits terminal mode
      vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
      vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h")
      vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j")
      vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k")
      vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l")
    end,
  },

  -- ── File tree ─────────────────────────────────────────────
  {
    "nvim-tree/nvim-tree.lua",
    cmd          = { "NvimTreeToggle", "NvimTreeFocus" },
    keys         = { { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "File tree" } },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      hijack_netrw = true,
      view         = { width = 32, side = "left" },
      renderer = {
        group_empty    = true,
        highlight_git  = true,
        icons = {
          glyphs = {
            folder = { arrow_closed = "", arrow_open = "" },
          },
        },
      },
      git      = { enable = true, ignore = false },
      filters  = { dotfiles = false, custom = { "^.git$" } },
      actions  = { open_file = { quit_on_open = false } },
    },
    config = function(_, opts)
      -- Disable netrw before nvim-tree
      vim.g.loaded_netrw       = 1
      vim.g.loaded_netrwPlugin = 1
      require("nvim-tree").setup(opts)
    end,
  },

  -- ── Which-key ─────────────────────────────────────────────
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts  = {
      plugins = { marks = false, registers = false },
      win     = { border = "rounded" },
    },
    config = function(_, opts)
      require("which-key").setup(opts)
      require("which-key").add({
        { "<leader>a", group = "AI" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>l", group = "LSP" },
        { "<leader>t", group = "Terminal" },
        { "<leader>u", group = "UI" },
      })
    end,
  },

  -- ── Git signs ─────────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts  = {
      signs = {
        add            = { text = "▎" },
        change         = { text = "▎" },
        delete         = { text = "" },
        topdelete      = { text = "" },
        changedelete   = { text = "▎" },
        untracked      = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs   = package.loaded.gitsigns
        local opts = { buffer = bufnr }
        vim.keymap.set("n", "]h", gs.next_hunk,                         opts)
        vim.keymap.set("n", "[h", gs.prev_hunk,                         opts)
        vim.keymap.set("n", "<leader>hs", gs.stage_hunk,                opts)
        vim.keymap.set("n", "<leader>hr", gs.reset_hunk,                opts)
        vim.keymap.set("n", "<leader>hp", gs.preview_hunk,              opts)
        vim.keymap.set("n", "<leader>hb", function() gs.blame_line({ full = true }) end, opts)
        vim.keymap.set("n", "<leader>hd", gs.diffthis,                  opts)
      end,
    },
  },

  -- ── Diagnostics panel ─────────────────────────────────────
  {
    "folke/trouble.nvim",
    cmd  = "Trouble",
    opts = { use_diagnostic_signs = true, auto_preview = false },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>",              desc = "Diagnostics" },
      { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<CR>",                  desc = "Location list" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>",                   desc = "Quickfix" },
    },
  },

  -- ── Autopairs ─────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local ap = require("nvim-autopairs")
      ap.setup({ check_ts = true, ts_config = { lua = { "string" } } })
      -- Integrate with cmp
      local cmp_ap = require("nvim-autopairs.completion.cmp")
      require("cmp").event:on("confirm_done", cmp_ap.on_confirm_done())
    end,
  },

  -- ── Comments ──────────────────────────────────────────────
  {
    "numToStr/Comment.nvim",
    keys  = { { "gc", mode = { "n", "v" } }, { "gb", mode = { "n", "v" } } },
    opts  = {},
  },

  -- ── Indent guides ─────────────────────────────────────────
  {
    "lukas-reineke/indent-blankline.nvim",
    event  = { "BufReadPre", "BufNewFile" },
    main   = "ibl",
    opts   = {
      indent = { char = "│", tab_char = "│" },
      scope  = { enabled = true, show_start = false, show_end = false },
      exclude = {
        filetypes = { "help", "dashboard", "neo-tree", "lazy", "mason", "notify", "toggleterm" },
      },
    },
  },

  -- ── Todo comments ─────────────────────────────────────────
  {
    "folke/todo-comments.nvim",
    event        = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = true },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev todo" },
      { "<leader>ft", "<cmd>TodoTelescope<CR>",                    desc = "Find todos" },
    },
  },

  -- ── Better notifications ───────────────────────────────────
  {
    "rcarriga/nvim-notify",
    event  = "VeryLazy",
    opts   = {
      timeout     = 3000,
      render      = "minimal",
      stages      = "fade",
      max_width   = 50,
      top_down    = false,
    },
    config = function(_, opts)
      local notify = require("notify")
      notify.setup(opts)
      vim.notify = notify
    end,
  },

  -- ── Schemastore (JSON/YAML schemas) ───────────────────────
  { "b0o/schemastore.nvim", lazy = true },

  -- ── Web devicons ──────────────────────────────────────────
  { "nvim-tree/nvim-web-devicons", lazy = true },

}
