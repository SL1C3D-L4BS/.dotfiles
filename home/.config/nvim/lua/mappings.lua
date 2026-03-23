-- ── Keymaps ───────────────────────────────────────────────────
local map = vim.keymap.set

-- Leader
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- Better nav
map("n", "j",          "gj")
map("n", "k",          "gk")
map("n", "<C-d>",      "<C-d>zz")
map("n", "<C-u>",      "<C-u>zz")
map("n", "n",          "nzzzv")
map("n", "N",          "Nzzzv")

-- Window nav
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Resize
map("n", "<C-Up>",    ":resize +2<CR>")
map("n", "<C-Down>",  ":resize -2<CR>")
map("n", "<C-Left>",  ":vertical resize -2<CR>")
map("n", "<C-Right>", ":vertical resize +2<CR>")

-- Buffer nav
map("n", "<Tab>",       ":bnext<CR>")
map("n", "<S-Tab>",     ":bprev<CR>")
map("n", "<leader>bd",  ":bdelete<CR>")

-- Quick save/quit
map("n", "<leader>w",  "<cmd>w<CR>")
map("n", "<leader>q",  "<cmd>q<CR>")
map("n", "<leader>Q",  "<cmd>qa!<CR>")

-- No highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Indent in visual
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move lines
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>",    { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>",     { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>",       { desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>",     { desc = "Help" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>",      { desc = "Recent files" })
map("n", "<leader>fd", "<cmd>Telescope diagnostics<CR>",   { desc = "Diagnostics" })
map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Symbols" })

-- LSP (set in on_attach)
map("n", "<leader>ca", vim.lsp.buf.code_action,        { desc = "Code action" })
map("n", "<leader>rn", vim.lsp.buf.rename,             { desc = "Rename" })
map("n", "gd",         vim.lsp.buf.definition,         { desc = "Go to definition" })
map("n", "gr",         "<cmd>Telescope lsp_references<CR>", { desc = "References" })
map("n", "K",          vim.lsp.buf.hover,              { desc = "Hover docs" })
map("n", "[d",         vim.diagnostic.goto_prev,       { desc = "Prev diagnostic" })
map("n", "]d",         vim.diagnostic.goto_next,       { desc = "Next diagnostic" })

-- NvimTree
map("n", "<leader>e",  "<cmd>NvimTreeToggle<CR>", { desc = "File tree" })

-- CodeCompanion (AI)
map("n", "<leader>ai", "<cmd>CodeCompanionChat<CR>",   { desc = "AI chat" })
map("v", "<leader>aa", "<cmd>CodeCompanionChat Add<CR>",{ desc = "Add to AI chat" })
map("n", "<leader>ac", "<cmd>CodeCompanion<CR>",        { desc = "AI inline" })

-- Lazygit
map("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "LazyGit" })

-- Terminal
map("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>")
map("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>")
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>")
map("t", "<Esc>",      "<C-\\><C-n>")
