-- ══════════════════════════════════════════════════════════════
-- SL1C3D-V1M Plugins — NvChad 2.5 | lazy.nvim | 2026
-- Full-stack: Python, Rust, Go, C/C++, C#, Zig, TS/JS, Lua,
-- Nix, Docker, Terraform, Web, + DAP + AI + Agentic
-- ══════════════════════════════════════════════════════════════

return {

  -- ── Treesitter — full language coverage ──────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- Systems
        "lua", "python", "rust", "go", "gomod", "gosum", "gowork",
        "c", "cpp", "c_sharp", "zig",
        -- Web
        "javascript", "typescript", "tsx", "html", "css", "scss",
        "vue", "svelte", "astro", "graphql", "prisma",
        -- Data & Config
        "json", "json5", "jsonc", "yaml", "toml", "xml", "csv",
        -- Markup
        "markdown", "markdown_inline", "latex",
        -- Shell & Infra
        "bash", "fish", "dockerfile", "terraform", "hcl", "nix",
        -- Other
        "sql", "regex", "vim", "vimdoc", "luadoc", "query",
        "proto", "make", "cmake", "ninja", "just",
        "gitcommit", "gitignore", "git_rebase", "diff",
      },
      highlight    = { enable = true, additional_vim_regex_highlighting = false },
      indent       = { enable = true },
      auto_install = true,
    },
  },

  -- ── Treesitter textobjects (select function/class/etc) ──
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event        = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["al"] = "@loop.outer",
              ["il"] = "@loop.inner",
              ["ai"] = "@conditional.outer",
              ["ii"] = "@conditional.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
            goto_next_end       = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
            goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
            goto_previous_end   = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
          },
          swap = {
            enable = true,
            swap_next     = { ["<leader>sp"] = "@parameter.inner" },
            swap_previous = { ["<leader>sP"] = "@parameter.inner" },
          },
        },
      })
    end,
  },

  -- ── Mason (LSP/DAP/Linter installer) ────────────────────
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

  -- ── Mason-lspconfig bridge ──────────────────────────────
  {
    "williamboman/mason-lspconfig.nvim",
    event        = "BufReadPre",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = {
        -- Core
        "lua_ls", "pyright", "rust_analyzer", "gopls",
        "ts_ls", "jsonls", "yamlls", "taplo", "bashls",
        -- Systems
        "clangd", "zls", "omnisharp",
        -- Web
        "html", "cssls", "tailwindcss", "emmet_ls",
        -- Infra
        "dockerls", "docker_compose_language_service",
        "terraformls",
        -- Data
        "sqlls",
      },
      automatic_installation = true,
    },
  },

  -- ── LSP config (nvim 0.11+ native API) ─────────────────
  {
    "neovim/nvim-lspconfig",
    event        = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "b0o/schemastore.nvim",
    },
    config = function()
      local cap = vim.tbl_deep_extend("force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities()
      )

      -- Diagnostics
      vim.diagnostic.config({
        virtual_text  = { prefix = "●", source = "if_many" },
        signs         = { text = { [1]=" ", [2]=" ", [3]=" ", [4]=" " } },
        underline     = true,
        update_in_insert = false,
        severity_sort = true,
        float         = { border = "rounded", source = true },
      })

      -- Buffer-local keymaps on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf, silent = true }
          vim.keymap.set("n", "gd",         vim.lsp.buf.definition,      opts)
          vim.keymap.set("n", "gD",         vim.lsp.buf.declaration,     opts)
          vim.keymap.set("n", "gr",         "<cmd>Telescope lsp_references<CR>", opts)
          vim.keymap.set("n", "gi",         vim.lsp.buf.implementation,  opts)
          vim.keymap.set("n", "K",          vim.lsp.buf.hover,           opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action,     opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,          opts)
          vim.keymap.set("n", "<leader>ds", "<cmd>Telescope lsp_document_symbols<CR>", opts)
          vim.keymap.set("n", "<leader>ws", "<cmd>Telescope lsp_workspace_symbols<CR>", opts)
          vim.keymap.set("n", "<leader>lf", function() vim.lsp.buf.format({ async = true }) end, opts)
          vim.keymap.set("n", "[d",         function() vim.diagnostic.jump({ count = -1 }) end, opts)
          vim.keymap.set("n", "]d",         function() vim.diagnostic.jump({ count = 1 })  end, opts)
          vim.keymap.set("n", "<leader>ld", function() vim.diagnostic.open_float() end, opts)

          -- Inlay hints toggle (nvim 0.10+)
          if vim.lsp.inlay_hint then
            vim.keymap.set("n", "<leader>li", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
            end, opts)
          end
        end,
      })

      -- Shared config for all servers
      vim.lsp.config("*", { capabilities = cap })

      -- Per-server configs
      local servers = {
        -- ── Python ──
        pyright = {
          settings = { python = {
            analysis = { autoSearchPaths = true, diagnosticMode = "workspace", useLibraryCodeForTypes = true },
          }},
        },

        -- ── Rust ──
        rust_analyzer = {
          settings = { ["rust-analyzer"] = {
            check     = { command = "clippy" },
            cargo     = { allFeatures = true },
            procMacro = { enable = true },
            inlayHints = {
              bindingModeHints       = { enable = true },
              closureReturnTypeHints = { enable = "always" },
              lifetimeElisionHints   = { enable = "always" },
            },
          }},
        },

        -- ── Go ──
        gopls = {
          settings = { gopls = {
            gofumpt       = true,
            staticcheck   = true,
            usePlaceholders = true,
            analyses      = { unusedparams = true, shadow = true, nilness = true, unusedwrite = true },
            hints         = { assignVariableTypes = true, compositeLiteralFields = true, compositeLiteralTypes = true, constantValues = true, functionTypeParameters = true, parameterNames = true, rangeVariableTypes = true },
            codelenses    = { gc_details = true, generate = true, test = true, tidy = true },
          }},
        },

        -- ── TypeScript/JavaScript ──
        ts_ls = {
          settings = {
            typescript = { inlayHints = { includeInlayParameterNameHints = "all", includeInlayFunctionParameterTypeHints = true, includeInlayVariableTypeHints = true } },
            javascript = { inlayHints = { includeInlayParameterNameHints = "all", includeInlayFunctionParameterTypeHints = true } },
          },
        },

        -- ── C/C++ ──
        clangd = {
          cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu", "--completion-style=detailed", "--function-arg-placeholders", "--fallback-style=llvm" },
          init_options = { clangdFileStatus = true },
        },

        -- ── C# (Unity + .NET) ──
        omnisharp = {
          cmd = { vim.fn.stdpath("data") .. "/mason/packages/omnisharp/omnisharp" },
          settings = {
            FormattingOptions  = { EnableEditorConfigSupport = true },
            MsBuild            = { LoadProjectsOnDemand = false },
            RoslynExtensionsOptions = {
              EnableAnalyzersSupport   = true,
              EnableImportCompletion   = true,
              AnalyzeOpenDocumentsOnly = true,
            },
          },
          handlers = {
            ["textDocument/definition"] = function(...)
              return require("omnisharp_extended").handler(...)
            end,
          },
        },

        -- ── Zig ──
        zls = {},

        -- ── Web ──
        html       = {},
        cssls      = {},
        tailwindcss = {},
        emmet_ls   = { filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "astro" } },

        -- ── Shell ──
        bashls = {},

        -- ── Config ──
        taplo = {},

        -- ── Infra ──
        dockerls = {},
        docker_compose_language_service = {},
        terraformls = {},

        -- ── Data ──
        sqlls = {},

        -- ── Lua ──
        lua_ls = {
          settings = {
            Lua = {
              runtime     = { version = "LuaJIT" },
              workspace   = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
              telemetry   = { enable = false },
              diagnostics = { globals = { "vim" } },
              hint        = { enable = true },
            },
          },
        },

        -- ── JSON (with schemastore) ──
        jsonls = {
          settings = {
            json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } },
          },
        },

        -- ── YAML (with schemastore) ──
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = false, url = "" },
              schemas     = require("schemastore").yaml.schemas(),
            },
          },
        },
      }

      local server_names = {}
      for name, cfg in pairs(servers) do
        vim.lsp.config(name, cfg)
        table.insert(server_names, name)
      end
      vim.lsp.enable(server_names)
    end,
  },

  -- ── DAP (Debug Adapter Protocol) ────────────────────────
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
      "leoluz/nvim-dap-go",
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end,              desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end,                       desc = "Continue" },
      { "<leader>di", function() require("dap").step_into() end,                      desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end,                      desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end,                       desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end,                    desc = "Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end,                       desc = "Run last" },
      { "<leader>dt", function() require("dap").terminate() end,                      desc = "Terminate" },
      { "<leader>du", function() require("dapui").toggle() end,                       desc = "Toggle DAP UI" },
    },
    config = function()
      local dap    = require("dap")
      local dapui  = require("dapui")

      -- DAP UI setup
      dapui.setup({
        layouts = {
          { elements = { "scopes", "breakpoints", "stacks", "watches" }, size = 40, position = "left" },
          { elements = { "repl", "console" },                           size = 0.25, position = "bottom" },
        },
        floating = { border = "rounded" },
      })

      -- Auto open/close DAP UI
      dap.listeners.after.event_initialized["dapui_config"]  = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"]  = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"]      = function() dapui.close() end

      -- Virtual text for debug values
      require("nvim-dap-virtual-text").setup({ commented = true })

      -- Breakpoint signs with HP colors
      vim.fn.sign_define("DapBreakpoint",          { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn",  linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint",            { text = "", texthl = "DiagnosticInfo",  linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped",             { text = "→", texthl = "DiagnosticOk",   linehl = "Visual", numhl = "DiagnosticOk" })

      -- ── Python DAP ──
      require("dap-python").setup("python")

      -- ── Go DAP ──
      require("dap-go").setup()

      -- ── C/C++/Rust DAP (lldb) ──
      dap.adapters.lldb = {
        type    = "executable",
        command = "/usr/bin/lldb-dap",
        name    = "lldb",
      }
      local lldb_config = {
        {
          name    = "Launch",
          type    = "lldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd             = "${workspaceFolder}",
          stopOnEntry     = false,
          args            = {},
          runInTerminal   = false,
        },
      }
      dap.configurations.c    = lldb_config
      dap.configurations.cpp  = lldb_config
      dap.configurations.rust = lldb_config

      -- ── Node/TS DAP ──
      dap.adapters["pwa-node"] = {
        type    = "server",
        host    = "localhost",
        port    = "${port}",
        executable = {
          command = "node",
          args    = { vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js", "${port}" },
        },
      }
      dap.configurations.javascript = {
        { type = "pwa-node", request = "launch", name = "Launch file", program = "${file}", cwd = "${workspaceFolder}" },
      }
      dap.configurations.typescript = dap.configurations.javascript

      -- ── C# DAP (netcoredbg) ──
      dap.adapters.coreclr = {
        type    = "executable",
        command = "/usr/bin/netcoredbg",
        args    = { "--interpreter=vscode" },
      }
      dap.configurations.cs = {
        { type = "coreclr", name = "Launch .NET", request = "launch",
          program = function() return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file") end },
      }
    end,
  },

  -- ── Formatting — full language coverage ─────────────────
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
        vue        = { "prettier" },
        svelte     = { "prettier" },
        astro      = { "prettier" },
        json       = { "prettier" },
        jsonc      = { "prettier" },
        yaml       = { "prettier" },
        markdown   = { "prettier" },
        html       = { "prettier" },
        css        = { "prettier" },
        scss       = { "prettier" },
        graphql    = { "prettier" },
        sh         = { "shfmt" },
        bash       = { "shfmt" },
        toml       = { "taplo" },
        c          = { "clang-format" },
        cpp        = { "clang-format" },
        cs         = { "csharpier" },
        zig        = { "zigfmt" },
        nix        = { "nixfmt" },
        proto      = { "buf" },
        terraform  = { "terraform_fmt" },
        hcl        = { "terraform_fmt" },
        sql        = { "sql_formatter" },
        dockerfile = { "hadolint" },
      },
      format_on_save  = { timeout_ms = 800, lsp_fallback = true },
      notify_on_error = false,
    },
  },

  -- ── Linting ─────────────────────────────────────────────
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        python     = { "ruff" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        go         = { "golangcilint" },
        dockerfile = { "hadolint" },
        sh         = { "shellcheck" },
        bash       = { "shellcheck" },
        terraform  = { "tflint" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function() lint.try_lint() end,
      })
    end,
  },

  -- ── Completion ──────────────────────────────────────────
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
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then luasnip.expand_or_jump()
            elseif has_words_before() then cmp.complete()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then luasnip.jump(-1)
            else fallback() end
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
            local ok, icons = pcall(require, "nvchad.icons.lspkind")
            if ok and icons[item.kind] then
              item.kind = icons[item.kind] .. " " .. item.kind
            end
            item.menu = nil
            return item
          end,
        },
      })

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

  -- ── Telescope ───────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    cmd          = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = vim.fn.executable("make") == 1 },
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-telescope/telescope-dap.nvim",
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
          file_ignore_patterns = { "%.git/", "node_modules/", "%.direnv/", "target/", "%.lock", "bin/Debug/", "obj/" },
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
      pcall(t.load_extension, "dap")
    end,
  },

  -- ── AI: CodeCompanion (local ollama) ────────────────────
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

  -- ── Rust extras (crates.nvim) ───────────────────────────
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts  = {
      completion = { cmp = { enabled = true } },
      lsp       = { enabled = true, actions = true, hover = true },
    },
  },

  -- ── Go extras ───────────────────────────────────────────
  {
    "olexsmir/gopher.nvim",
    ft           = "go",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    build        = ":GoInstallDeps",
    opts         = {},
  },

  -- ── LazyGit ─────────────────────────────────────────────
  {
    "kdheepak/lazygit.nvim",
    cmd          = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = { { "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit" } },
  },

  -- ── Terminal ────────────────────────────────────────────
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd     = "ToggleTerm",
    keys    = {
      { "<C-\\>",     "<cmd>ToggleTerm<CR>",                        desc = "Toggle terminal" },
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
      vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
      vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h")
      vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j")
      vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k")
      vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l")
    end,
  },

  -- ── File tree ───────────────────────────────────────────
  {
    "nvim-tree/nvim-tree.lua",
    cmd          = { "NvimTreeToggle", "NvimTreeFocus" },
    keys         = { { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "File tree" } },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      hijack_netrw = true,
      view         = { width = 32, side = "left" },
      renderer = {
        group_empty   = true,
        highlight_git = true,
        icons = { glyphs = { folder = { arrow_closed = "", arrow_open = "" } } },
      },
      git     = { enable = true, ignore = false },
      filters = { dotfiles = false, custom = { "^.git$" } },
      actions = { open_file = { quit_on_open = false } },
    },
    config = function(_, opts)
      vim.g.loaded_netrw       = 1
      vim.g.loaded_netrwPlugin = 1
      require("nvim-tree").setup(opts)
    end,
  },

  -- ── Which-key ───────────────────────────────────────────
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
        { "<leader>c", group = "Claude" },
        { "<leader>d", group = "Debug" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>h", group = "Git Hunks" },
        { "<leader>l", group = "LSP" },
        { "<leader>s", group = "Swap" },
        { "<leader>t", group = "Terminal" },
        { "<leader>u", group = "UI" },
        { "<leader>x", group = "Diagnostics" },
      })
    end,
  },

  -- ── Git signs ───────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts  = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
        untracked    = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs   = package.loaded.gitsigns
        local opts = { buffer = bufnr }
        vim.keymap.set("n", "]h",          gs.next_hunk,                                       opts)
        vim.keymap.set("n", "[h",          gs.prev_hunk,                                       opts)
        vim.keymap.set("n", "<leader>hs",  gs.stage_hunk,                                      opts)
        vim.keymap.set("n", "<leader>hr",  gs.reset_hunk,                                      opts)
        vim.keymap.set("n", "<leader>hp",  gs.preview_hunk,                                    opts)
        vim.keymap.set("n", "<leader>hb",  function() gs.blame_line({ full = true }) end,      opts)
        vim.keymap.set("n", "<leader>hd",  gs.diffthis,                                        opts)
        vim.keymap.set("n", "<leader>hD",  function() gs.diffthis("~") end,                    opts)
      end,
    },
  },

  -- ── Diagnostics panel ───────────────────────────────────
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

  -- ── Autopairs ───────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local ap = require("nvim-autopairs")
      ap.setup({ check_ts = true, ts_config = { lua = { "string" } } })
      local cmp_ap = require("nvim-autopairs.completion.cmp")
      require("cmp").event:on("confirm_done", cmp_ap.on_confirm_done())
    end,
  },

  -- ── Comments ────────────────────────────────────────────
  { "numToStr/Comment.nvim", keys = { { "gc", mode = { "n", "v" } }, { "gb", mode = { "n", "v" } } }, opts = {} },

  -- ── Indent guides ───────────────────────────────────────
  {
    "lukas-reineke/indent-blankline.nvim",
    event  = { "BufReadPre", "BufNewFile" },
    main   = "ibl",
    opts   = {
      indent  = { char = "│", tab_char = "│" },
      scope   = { enabled = true, show_start = false, show_end = false },
      exclude = { filetypes = { "help", "dashboard", "neo-tree", "lazy", "mason", "notify", "toggleterm" } },
    },
  },

  -- ── Todo comments ───────────────────────────────────────
  {
    "folke/todo-comments.nvim",
    event        = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = true },
    keys = {
      { "]t",          function() require("todo-comments").jump_next() end, desc = "Next todo" },
      { "[t",          function() require("todo-comments").jump_prev() end, desc = "Prev todo" },
      { "<leader>ft",  "<cmd>TodoTelescope<CR>",                            desc = "Find todos" },
    },
  },

  -- ── Better notifications ────────────────────────────────
  {
    "rcarriga/nvim-notify",
    event  = "VeryLazy",
    opts   = { timeout = 3000, render = "minimal", stages = "fade", max_width = 50, top_down = false },
    config = function(_, opts)
      local notify = require("notify")
      notify.setup(opts)
      vim.notify = notify
    end,
  },

  -- ── Claude Code integration ─────────────────────────────
  {
    "greggh/claude-code.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd  = { "ClaudeCode", "ClaudeCodeSend", "ClaudeCodeTreeAdd" },
    keys = {
      { "<leader>cc", "<cmd>ClaudeCode<CR>",         desc = "Claude Code toggle" },
      { "<leader>cs", "<cmd>ClaudeCodeSend<CR>",     desc = "Claude Code send",  mode = "v" },
      { "<leader>ct", "<cmd>ClaudeCodeTreeAdd<CR>",  desc = "Claude Code add file" },
    },
    opts = { window = { position = "vertical", width = 0.4, open_on_start = false } },
  },

  -- ── OmniSharp extended (go-to-definition in decompiled sources) ──
  { "Hoffs/omnisharp-extended-lsp.nvim", lazy = true },

  -- ── Schemastore ─────────────────────────────────────────
  { "b0o/schemastore.nvim", lazy = true },

  -- ── Web devicons ────────────────────────────────────────
  { "nvim-tree/nvim-web-devicons", lazy = true },

}
