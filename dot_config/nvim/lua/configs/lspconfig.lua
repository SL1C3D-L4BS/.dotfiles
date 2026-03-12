require("nvchad.configs.lspconfig").defaults()

-- SL1C3D-L4BS: enable LSP for common dev (install via :Mason)
local servers = {
  "html",
  "cssls",
  "lua_ls",
  "pyright",
  "rust_analyzer",
  "ts_ls",
  "jsonls",
  "clangd",   -- C/C++
  "jdtls",    -- Java
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
