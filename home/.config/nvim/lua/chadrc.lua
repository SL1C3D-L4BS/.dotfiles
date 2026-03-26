-- ══════════════════════════════════════════════════════════════
-- SL1C3D-V1M | NvChad chadrc.lua | THE ARCHITECT | 2026
-- ══════════════════════════════════════════════════════════════

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme         = "sl1c3d",
  theme_toggle  = { "sl1c3d", "catppuccin_latte" },
  transparency  = true,

  hl_override = {
    Comment      = { italic = true },
    ["@comment"] = { italic = true },

    -- NvDash branding
    NvDashAscii   = { fg = "#2D6A4F", bg = "NONE" },
    NvDashButtons = { fg = "#9B9BAB", bg = "NONE" },

    -- Statusline pill segments
    St_file       = { fg = "#0D0D1A", bg = "#2D6A4F", bold = true },
    St_file_sep   = { fg = "#2D6A4F", bg = "NONE" },
    St_gitIcons   = { fg = "#D4A017", bg = "#1A1A2E" },
    St_lspError   = { fg = "#C41E3A", bg = "#1A1A2E" },
    St_lspWarning = { fg = "#D4A017", bg = "#1A1A2E" },
    St_lspHints   = { fg = "#9B59B6", bg = "#1A1A2E" },
    St_lspInfo    = { fg = "#0077B6", bg = "#1A1A2E" },
    St_cwd        = { fg = "#0D0D1A", bg = "#0077B6", bold = true },
    St_cwd_sep    = { fg = "#0077B6", bg = "NONE" },
    St_pos        = { fg = "#0D0D1A", bg = "#9B59B6", bold = true },
    St_pos_sep    = { fg = "#9B59B6", bg = "NONE" },

    -- Tabufline pill tabs
    TbFill          = { bg = "#070710" },
    TbBufOn         = { fg = "#E8E6E3", bg = "#1A1A2E", bold = true },
    TbBufOnModified = { fg = "#2D6A4F", bg = "#1A1A2E" },
    TbBufOff        = { fg = "#4B4B5B", bg = "#070710" },
    TbBufOffModified = { fg = "#6B6B7B", bg = "#070710" },

    -- Floating windows — gorgeous borders
    FloatBorder = { fg = "#2D6A4F", bg = "NONE" },
    NormalFloat = { bg = "#0D0D1A" },

    -- Telescope floating
    TelescopeBorder       = { fg = "#2D6A4F", bg = "NONE" },
    TelescopePromptBorder = { fg = "#9B59B6", bg = "NONE" },
    TelescopeResultsBorder = { fg = "#2D6A4F", bg = "NONE" },
    TelescopePreviewBorder = { fg = "#0077B6", bg = "NONE" },
    TelescopePromptTitle  = { fg = "#0D0D1A", bg = "#9B59B6", bold = true },
    TelescopeResultsTitle = { fg = "#0D0D1A", bg = "#2D6A4F", bold = true },
    TelescopePreviewTitle = { fg = "#0D0D1A", bg = "#0077B6", bold = true },
    TelescopePromptPrefix = { fg = "#9B59B6" },
    TelescopeSelection    = { fg = "#E8E6E3", bg = "#1A1A2E", bold = true },
    TelescopeMatching     = { fg = "#D4A017", bold = true },

    -- Pmenu floating pills
    Pmenu      = { bg = "#111125" },
    PmenuSel   = { fg = "#E8E6E3", bg = "#2D6A4F", bold = true },
    PmenuSbar  = { bg = "#1A1A2E" },
    PmenuThumb = { bg = "#2D6A4F" },

    -- CMP floating menu
    CmpBorder   = { fg = "#2D6A4F", bg = "NONE" },
    CmpDocBorder = { fg = "#0077B6", bg = "NONE" },

    -- Cursor + line
    CursorLine   = { bg = "#111125" },
    CursorLineNr = { fg = "#2D6A4F", bold = true },
    LineNr       = { fg = "#4B4B5B" },

    -- Indent guides
    IblChar      = { fg = "#1E1E38" },
    IblScopeChar = { fg = "#2D6A4F" },

    -- Which-key floating
    WhichKey          = { fg = "#2D6A4F" },
    WhichKeyGroup     = { fg = "#9B59B6" },
    WhichKeyDesc      = { fg = "#9B9BAB" },
    WhichKeySeparator = { fg = "#4B4B5B" },
    WhichKeyFloat     = { bg = "#0D0D1A" },

    -- Visual selection
    Visual    = { bg = "#2D3A5C" },
    VisualNOS = { bg = "#2D3A5C" },

    -- Search gold
    Search    = { fg = "#0D0D1A", bg = "#D4A017" },
    IncSearch = { fg = "#0D0D1A", bg = "#E8B930" },

    -- Mason/Lazy floating
    LazyH1           = { fg = "#0D0D1A", bg = "#2D6A4F", bold = true },
    LazyButton       = { fg = "#9B9BAB", bg = "#1A1A2E" },
    LazyButtonActive = { fg = "#E8E6E3", bg = "#2D6A4F" },
    LazySpecial      = { fg = "#D4A017" },
    MasonHeader      = { fg = "#0D0D1A", bg = "#2D6A4F", bold = true },
    MasonHighlight   = { fg = "#0077B6" },

    -- NvimTree
    NvimTreeRootFolder  = { fg = "#2D6A4F", bold = true },
    NvimTreeFolderIcon  = { fg = "#0077B6" },
    NvimTreeFolderName  = { fg = "#0077B6" },
    NvimTreeGitDirty    = { fg = "#D4A017" },
    NvimTreeGitNew      = { fg = "#2ECC71" },
    NvimTreeGitDeleted  = { fg = "#C41E3A" },
    NvimTreeSpecialFile = { fg = "#B97EDE" },
    NvimTreeWinSeparator = { fg = "#1E1E38", bg = "NONE" },

    -- Diagnostics
    DiagnosticError = { fg = "#C41E3A" },
    DiagnosticWarn  = { fg = "#D4A017" },
    DiagnosticInfo  = { fg = "#0077B6" },
    DiagnosticHint  = { fg = "#9B59B6" },

    -- Notify floating
    NotifyERRORBorder = { fg = "#C41E3A" },
    NotifyWARNBorder  = { fg = "#D4A017" },
    NotifyINFOBorder  = { fg = "#0077B6" },
    NotifyDEBUGBorder = { fg = "#9B59B6" },
  },

  hl_add = {
    Sl1c3dAccent   = { fg = "#2D6A4F" },
    Sl1c3dGold     = { fg = "#D4A017" },
    Sl1c3dMagic    = { fg = "#9B59B6" },
    Sl1c3dRaven    = { fg = "#0077B6" },
    Sl1c3dGryf     = { fg = "#C41E3A" },
    Sl1c3dLavender = { fg = "#B97EDE" },
    Sl1c3dParch    = { fg = "#E8E6E3" },
    Sl1c3dDim      = { fg = "#6B6B7B" },
  },
}

M.ui = {
  statusline = {
    enabled         = true,
    theme           = "vscode_colored",
    separator_style = "round",
  },
  tabufline = {
    enabled  = true,
    lazyload = true,
  },
  telescope = {
    style = "bordered",
  },
  cmp = {
    style = "atom_colored",
  },
}

M.nvdash = {
  load_on_startup = true,
  header = {
    "",
    "  ██████  ██▓   ██▓▄████▄ ▓█████▓█████▄  ██▒  █▓██▓███▄ ▄███▓",
    " ▒██    ▒▓██▒  ▓██▒██▀ ▀█ ▓█   ▀▒██▀ ██▌▓██░  █▒██▒██▒▀█▀ ██▒",
    " ░ ▓██▄  ▒██░  ▒██▒▓█   ▄ ▒███  ░██  █▌ ▓██ █▒░██▒▓██   ▓██░",
    "   ▒  ██▒▒██░  ░██░▓▓▄▄██▒▒▓█ ▄ ░▓█▄  ▌  ▒██ █░██░▒██   ▒██ ",
    " ▒██████▒░█████▒██░▒ ▓███▀░▒████▒░▒████▓   ▒▀█░ ██░▒██▒  ░██▒",
    " ▒ ▒▓▒ ▒░░ ▒░▓ ░▓  ░ ░▒ ▒░░ ▒░ ░ ▒▒▓ ▒    ░▐░ ░▓ ░ ▒░  ░ ░",
    " ░ ░▒  ░░░ ░ ▒ ░▒░  ░ ▒  ░ ░ ░ ░ ▒ ▒    ░░░  ▒░░ ░      ░",
    " ░  ░ ░   ░ ░  ▒░░       ░   ░ ░ ░     ░░  ▒░░     ░   ",
    "      ░     ░ ░░ ░ ░     ░ ░  ░          ░  ░       ░   ",
    "                                                         ",
    "      THE ARCHITECT  ///  SL1C3D-L4BS  ///  2026         ",
    "",
  },
  buttons = {
    { txt = "  Find File",      keys = "ff", cmd = "Telescope find_files" },
    { txt = "  Recent Files",   keys = "fr", cmd = "Telescope oldfiles" },
    { txt = "  Find Word",      keys = "fw", cmd = "Telescope live_grep" },
    { txt = "  Bookmarks",      keys = "bm", cmd = "Telescope marks" },
    { txt = "  Themes",         keys = "th", cmd = "Telescope themes" },
    { txt = "  Mappings",       keys = "ch", cmd = "NvCheatsheet" },
  },
}

return M
