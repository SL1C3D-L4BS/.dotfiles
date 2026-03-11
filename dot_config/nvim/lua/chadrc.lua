-- ─────────────────────────────────────────────────────────────────────────────
-- NvChad — SL1C3D-L4BS | Hyprland #1 brand (white, black, grey, Discord Blurple)
-- Elite 2026: full base_16 + base_30 override, hl_override, Treesitter
-- ─────────────────────────────────────────────────────────────────────────────

---@type ChadrcConfig
local M = {}

-- Theme: onedark base, fully overridden with SL1C3D-L4BS palette
M.base46 = {
  theme = "onedark",
  transparency = false,
  hl_add = {},
  hl_override = {
    Comment = { fg = "#909090", italic = true },
    ["@comment"] = { fg = "#909090", italic = true },
    ["@keyword"] = { fg = "#5865F2" },
    ["@keyword.function"] = { fg = "#5865F2" },
    ["@keyword.return"] = { fg = "#5865F2" },
    ["@function"] = { fg = "#5865F2" },
    ["@function.call"] = { fg = "#5865F2" },
    ["@function.builtin"] = { fg = "#5865F2" },
    ["@method"] = { fg = "#5865F2" },
    ["@method.call"] = { fg = "#5865F2" },
    ["@type"] = { fg = "#e0e0e0" },
    ["@string"] = { fg = "#e0e0e0" },
    ["@number"] = { fg = "#f1fa8c" },
    ["@operator"] = { fg = "#f8f8f2" },
    ["@variable"] = { fg = "#f8f8f2" },
    ["@variable.builtin"] = { fg = "#5865F2" },
    ["@parameter"] = { fg = "#e0e0e0" },
    ["@field"] = { fg = "#e0e0e0" },
    ["@error"] = { fg = "#ff5555" },
    ["@exception"] = { fg = "#ff5555" },
    Normal = { fg = "#f8f8f2", bg = "#0d0d0d" },
    NormalFloat = { bg = "#1a1a1a" },
    FloatBorder = { fg = "#2d2d2d", bg = "#1a1a1a" },
    StatusLine = { fg = "#e0e0e0", bg = "#1a1a1a" },
    CursorLine = { bg = "#1a1a1a" },
    CursorLineNr = { fg = "#5865F2" },
    LineNr = { fg = "#909090" },
    Pmenu = { fg = "#f8f8f2", bg = "#1a1a1a" },
    PmenuSel = { fg = "#f8f8f2", bg = "#5865F2" },
    NvimTreeFolderIcon = { fg = "#5865F2" },
    NvimTreeFolderName = { fg = "#5865F2" },
    TelescopeBorder = { fg = "#2d2d2d" },
    TelescopeSelection = { fg = "#f8f8f2", bg = "#5865F2" },
    WinSeparator = { fg = "#2d2d2d" },
    TabLine = { fg = "#909090", bg = "#1a1a1a" },
    TabLineFill = { bg = "#0d0d0d" },
    TabLineSel = { fg = "#f8f8f2", bg = "#5865F2" },
    FloatTitle = { fg = "#e0e0e0", bg = "#1a1a1a" },
  },
  changed_themes = {
    onedark = {
      base_16 = {
        base00 = "#0d0d0d",
        base01 = "#1a1a1a",
        base02 = "#2d2d2d",
        base03 = "#909090",
        base04 = "#909090",
        base05 = "#f8f8f2",
        base06 = "#e0e0e0",
        base07 = "#1a1a1a",
        base08 = "#ff5555",
        base09 = "#f1fa8c",
        base0A = "#f1fa8c",
        base0B = "#50fa7b",
        base0C = "#e0e0e0",
        base0D = "#5865F2",
        base0E = "#5865F2",
        base0F = "#909090",
      },
      base_30 = {
        black = "#0d0d0d",
        darker_black = "#080808",
        black2 = "#1a1a1a",
        one_bg = "#1a1a1a",
        one_bg2 = "#2d2d2d",
        one_bg3 = "#404040",
        grey = "#909090",
        grey_fg = "#909090",
        grey_fg2 = "#6c6c6c",
        light_grey = "#e0e0e0",
        line = "#2d2d2d",
        white = "#f8f8f2",
        statusline_bg = "#1a1a1a",
        lightbg = "#1a1a1a",
        lightbg2 = "#2d2d2d",
        pmenu_bg = "#1a1a1a",
        folder_bg = "#5865F2",
        blue = "#5865F2",
        nord_blue = "#5865F2",
        purple = "#5865F2",
        dark_purple = "#5865F2",
        red = "#ff5555",
        baby_pink = "#ff5555",
        pink = "#ff79c6",
        green = "#50fa7b",
        vibrant_green = "#50fa7b",
        yellow = "#f1fa8c",
        sun = "#f1fa8c",
        orange = "#f1fa8c",
        cyan = "#e0e0e0",
        teal = "#e0e0e0",
      },
    },
  },
  integrations = {},
}

-- UI: statusline, tabufline, cmp, telescope
M.ui = {
  statusline = {
    enabled = true,
    theme = "default",
    separator_style = "default",
  },
  tabufline = {
    enabled = true,
    lazyload = true,
  },
  telescope = { style = "borderless" },
  cmp = {
    style = "default",
    icons_left = false,
  },
}

-- Optional: NvDash header with brand name (load_on_startup = false by default)
-- M.nvdash = {
--   load_on_startup = false,
--   header = { " SL1C3D-L4BS ", " " },
-- }

return M
