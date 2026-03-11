require "nvchad.options"

-- SL1C3D-L4BS elite defaults
local o = vim.opt
o.cursorline = true
o.cursorlineopt = "number,line"
o.number = true
o.relativenumber = true
o.wrap = false
o.termguicolors = true
o.signcolumn = "yes"
o.colorcolumn = "80"
o.updatetime = 200
o.mouse = "a"

-- Rounded float borders (NvChad-style floating pills)
vim.diagnostic.config({ float = { border = "rounded" } })
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
