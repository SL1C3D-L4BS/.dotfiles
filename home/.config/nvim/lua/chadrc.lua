-- ── NvChad user config (chadrc.lua) ───────────────────────────
-- Must return a table matching nvconfig.lua structure

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme         = "catppuccin",
  theme_toggle  = { "catppuccin", "catppuccin_latte" },
  transparency  = false,

  hl_override = {
    Comment      = { italic = true },
    ["@comment"] = { italic = true },
  },
}

M.ui = {
  statusline = {
    enabled        = true,
    theme          = "default",
    separator_style = "round",
  },
  tabufline = {
    enabled  = true,
    lazyload = true,
  },
  telescope = {
    style = "bordered",
  },
}

M.nvdash = {
  load_on_startup = true,
  header = {
    "                                                     ",
    "  ████████╗██╗  ██╗███████╗     █████╗ ██████╗ ████████╗ ",
    "     ██╔══╝██║  ██║██╔════╝    ██╔══██╗██╔══██╗╚══██╔══╝ ",
    "     ██║   ███████║█████╗      ███████║██████╔╝   ██║    ",
    "     ██║   ██╔══██║██╔══╝      ██╔══██║██╔══██╗   ██║    ",
    "     ██║   ██║  ██║███████╗    ██║  ██║██║  ██║   ██║    ",
    "     ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ",
    "                                                     ",
    "              SL1C3D-L4BS  |  2026                   ",
    "                                                     ",
  },
  buttons = {
    { txt = "  Find File",    keys = "ff", cmd = "Telescope find_files" },
    { txt = "  Recent Files", keys = "fr", cmd = "Telescope oldfiles" },
    { txt = "  Find Word",    keys = "fw", cmd = "Telescope live_grep" },
    { txt = "  Bookmarks",    keys = "bm", cmd = "Telescope marks" },
    { txt = "  Themes",       keys = "th", cmd = "Telescope themes" },
    { txt = "  Mappings",     keys = "ch", cmd = "NvCheatsheet" },
  },
}

return M
