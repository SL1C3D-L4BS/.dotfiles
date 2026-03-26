-- ══════════════════════════════════════════════════════════════
-- init.lua — the_architect | NvChad 2.5 via lazy.nvim | 2026
-- Target startup: <70ms
-- ══════════════════════════════════════════════════════════════

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader must be set before lazy loads anything
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- NvChad base46 cache path — must be set before lazy loads NvChad
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"

-- Load options early (no plugin deps)
require("config.options")

-- Lazy plugin manager
require("lazy").setup({
  -- NvChad core — UI, themes, statusline, tabufline, base46 theming
  {
    "NvChad/NvChad",
    lazy   = false,
    branch = "v2.5",
    import = "nvchad.plugins",
    config = function()
      require("nvchad.options")
    end,
  },

  -- Custom plugins extend/override NvChad defaults
  { import = "plugins" },
}, {
  defaults = { lazy = true },
  install  = { colorscheme = { "nvchad" } },
  ui = {
    border = "rounded",
    icons  = {
      ft         = "",
      lazy       = "󰂠 ",
      loaded     = "",
      not_loaded = "",
    },
  },
  performance = {
    rtp = {
      -- Disable built-in plugins that slow startup and we don't use
      disabled_plugins = {
        "2html_plugin","tohtml","getscript","getscriptPlugin",
        "gzip","logipat","netrw","netrwPlugin","netrwSettings",
        "netrwFileHandlers","matchit","tar","tarPlugin","rrhelper",
        "spellfile_plugin","vimball","vimballPlugin","zip","zipPlugin",
        "tutor","rplugin","syntax","synmenu","optwin","compiler",
        "bugreport","ftplugin",
      },
    },
  },
  checker = { enabled = false },
  rocks   = { enabled = false },
})

-- Load ALL base46 theme caches immediately so nothing is grey
vim.schedule(function()
  local cache = vim.g.base46_cache
  if cache then
    for _, file in ipairs(vim.fn.readdir(cache)) do
      dofile(cache .. file)
    end
  end
  require("config.mappings")
end)
