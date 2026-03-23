-- ══════════════════════════════════════════════════════════════
-- NvChad 2.5+ entry point — the_architect | 2026
-- Target startup: <70ms
-- ══════════════════════════════════════════════════════════════

-- Bootstrap NvChad if not installed
local nvchad_path = vim.fn.stdpath("data") .. "/nvchad"
if not vim.uv.fs_stat(nvchad_path) then
  vim.fn.system({
    "git", "clone", "--depth", "1",
    "https://github.com/NvChad/starter",
    vim.fn.stdpath("config"),
  })
end

require "nvchad.options"
require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)
