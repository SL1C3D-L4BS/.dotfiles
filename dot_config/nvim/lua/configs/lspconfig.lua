-- Merge blink.cmp LSP capabilities so completion/signatureHelp etc work with LSP
local nvchad_lsp = require("nvchad.configs.lspconfig")
local ok, blink = pcall(require, "blink.cmp")
if ok and blink and blink.get_lsp_capabilities then
  nvchad_lsp.capabilities = blink.get_lsp_capabilities(nvchad_lsp.capabilities)
end
nvchad_lsp.defaults()

-- SL1C3D-L4BS: fullstack LSP (install via :Mason or system/Nix)
local servers = {
  -- Web & frontend
  "html",
  "cssls",
  "ts_ls",
  "jsonls",
  "volar",        -- Vue 3
  "svelte",
  "tailwindcss",
  -- Backend & infra
  "lua_ls",
  "pyright",
  "rust_analyzer",
  "gopls",        -- Go
  "clangd",       -- C/C++
  "jdtls",        -- Java
  "csharp_ls",    -- C# / .NET
  "intelephense", -- PHP
  "solargraph",   -- Ruby
  "zls",          -- Zig
  "elixir_ls",    -- Elixir (optional: install elixir)
  -- YAML, Dockerfile, Bash, SQL
  "yamlls",
  "dockerfile_ls",
  "bashls",
  "sqls",
  -- Optional: Kotlin, Dart/Flutter, GraphQL, Prisma (uncomment if needed)
  -- "kotlin_language_server",
  -- "dart",
  -- "graphql",
  -- "prisma",
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
