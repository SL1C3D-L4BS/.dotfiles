-- ── Options ───────────────────────────────────────────────────
local o = vim.opt

-- Performance
o.lazyredraw   = false
o.updatetime   = 100
o.timeoutlen   = 300

-- Editing
o.number         = true
o.relativenumber = true
o.cursorline     = true
o.scrolloff      = 8
o.sidescrolloff  = 8
o.wrap           = false
o.expandtab      = true
o.shiftwidth     = 4
o.tabstop        = 4
o.smartindent    = true

-- Search
o.ignorecase = true
o.smartcase  = true
o.hlsearch   = false
o.incsearch  = true

-- UI
o.termguicolors = true
o.signcolumn    = "yes"
o.showmode      = false
o.cmdheight     = 1
o.pumheight     = 10
o.splitright    = true
o.splitbelow    = true

-- Files
o.swapfile = false
o.backup   = false
o.undofile = true
o.undodir  = vim.fn.stdpath("data") .. "/undo"

-- Clipboard
o.clipboard = "unnamedplus"

-- Fold (via treesitter)
o.foldmethod = "expr"
o.foldexpr   = "nvim_treesitter#foldexpr()"
o.foldenable = false

-- Completion
o.completeopt = { "menu", "menuone", "noselect" }
