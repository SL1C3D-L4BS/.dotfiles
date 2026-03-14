-- Merge blink.cmp LSP capabilities so completion/signatureHelp etc work with LSP
local nvchad_lsp = require("nvchad.configs.lspconfig")
local ok, blink = pcall(require, "blink.cmp")
if ok and blink and blink.get_lsp_capabilities then
  nvchad_lsp.capabilities = blink.get_lsp_capabilities(nvchad_lsp.capabilities)
end
nvchad_lsp.defaults()

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
