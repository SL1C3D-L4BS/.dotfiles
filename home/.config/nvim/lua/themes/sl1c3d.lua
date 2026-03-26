-- ══════════════════════════════════════════════════════════════
-- SL1C3D-V1M — Harry Potter × Cyberpunk theme for NvChad base46
-- THE ARCHITECT | SL1C3D-L4BS | 2026
-- ══════════════════════════════════════════════════════════════
-- Palette: Hogwarts midnight bg, Slytherin emerald primary,
-- Gryffindor scarlet urgent, Ravenclaw blue info, Amethyst magic
-- ══════════════════════════════════════════════════════════════

local M = {}

-- ── UI Colors (30) ────────────────────────────────────────────
M.base_30 = {
  white         = "#E8E6E3",   -- parchment
  darker_black  = "#070710",   -- chamber of secrets
  black         = "#0D0D1A",   -- hogwarts midnight (nvim bg)
  black2        = "#111125",   -- slightly lighter bg
  one_bg        = "#1A1A2E",   -- surface (one step above bg)
  one_bg2       = "#222244",   -- surface hover
  one_bg3       = "#2A2A50",   -- third bg level
  grey          = "#4B4B5B",   -- between dim and muted
  grey_fg       = "#5B5B6B",   -- grey with fg tint
  grey_fg2      = "#6B6B7B",   -- faded ink
  light_grey    = "#7B7B8B",   -- lighter grey
  red           = "#C41E3A",   -- gryffindor scarlet
  baby_pink     = "#E85D75",   -- lighter scarlet
  pink          = "#B97EDE",   -- lavender magic
  line          = "#1E1E38",   -- subtle separator
  green         = "#2ECC71",   -- vibrant success green
  vibrant_green = "#3DDB84",   -- brighter green
  nord_blue     = "#4A90D9",   -- lighter ravenclaw
  blue          = "#0077B6",   -- ravenclaw blue
  seagreen      = "#2D6A4F",   -- slytherin emerald
  yellow        = "#D4A017",   -- gold
  sun           = "#E8B930",   -- brighter gold
  purple        = "#9B59B6",   -- amethyst
  dark_purple   = "#7B3FA0",   -- deeper amethyst
  teal          = "#1A8A6A",   -- bright slytherin
  orange        = "#D4A017",   -- gold (HP has no orange)
  cyan          = "#0097D9",   -- bright ravenclaw
  statusline_bg = "#111125",   -- dark statusline
  lightbg       = "#1E1E38",   -- lighter bg
  lightbg2      = "#222244",   -- even lighter
  pmenu_bg      = "#2D6A4F",   -- popup menu (slytherin emerald)
  folder_bg     = "#0077B6",   -- folder icons (ravenclaw)
  lavender      = "#B97EDE",   -- magic lavender
}

-- ── Base16 Syntax Colors ──────────────────────────────────────
M.base_16 = {
  base00 = "#0D0D1A",   -- bg: hogwarts midnight
  base01 = "#1A1A2E",   -- lighter bg: dark corridor
  base02 = "#222244",   -- selection: surface hover
  base03 = "#6B6B7B",   -- comments: faded ink
  base04 = "#9B9BAB",   -- dark fg: weathered scroll
  base05 = "#E8E6E3",   -- fg: parchment
  base06 = "#C8C6C3",   -- light fg: parchment variant
  base07 = "#E8E6E3",   -- lightest: parchment
  base08 = "#C41E3A",   -- variables/tags: gryffindor scarlet
  base09 = "#D4A017",   -- constants/numbers: gold
  base0A = "#B97EDE",   -- classes/bold: lavender magic
  base0B = "#2ECC71",   -- strings: vibrant green
  base0C = "#0097D9",   -- regex/escape: bright ravenclaw
  base0D = "#0077B6",   -- functions: ravenclaw blue
  base0E = "#9B59B6",   -- keywords: amethyst
  base0F = "#740001",   -- deprecated: dark gryffindor
}

-- ── Treesitter & highlight polish ─────────────────────────────
M.polish_hl = {
  treesitter = {
    ["@variable"]         = { fg = "#C8C6C3" },   -- parchment light
    ["@variable.builtin"] = { fg = "#C41E3A" },    -- gryffindor
    ["@property"]         = { fg = "#1A8A6A" },    -- bright slytherin
    ["@field"]            = { fg = "#1A8A6A" },    -- bright slytherin
    ["@parameter"]        = { fg = "#E8B930" },    -- bright gold
    ["@function"]         = { fg = "#0077B6" },    -- ravenclaw blue
    ["@function.builtin"] = { fg = "#4A90D9" },    -- lighter ravenclaw
    ["@function.call"]    = { fg = "#0077B6" },    -- ravenclaw blue
    ["@method"]           = { fg = "#0077B6" },    -- ravenclaw
    ["@method.call"]      = { fg = "#0077B6" },    -- ravenclaw
    ["@keyword"]          = { fg = "#9B59B6" },    -- amethyst
    ["@keyword.return"]   = { fg = "#B97EDE" },    -- lavender
    ["@keyword.function"] = { fg = "#9B59B6" },    -- amethyst
    ["@keyword.operator"] = { fg = "#9B59B6" },    -- amethyst
    ["@conditional"]      = { fg = "#9B59B6" },    -- amethyst
    ["@repeat"]           = { fg = "#9B59B6" },    -- amethyst
    ["@include"]          = { fg = "#B97EDE" },    -- lavender
    ["@type"]             = { fg = "#D4A017" },    -- gold
    ["@type.builtin"]     = { fg = "#D4A017" },    -- gold
    ["@type.definition"]  = { fg = "#D4A017" },    -- gold
    ["@constructor"]      = { fg = "#D4A017" },    -- gold
    ["@string"]           = { fg = "#2ECC71" },    -- vibrant green
    ["@string.escape"]    = { fg = "#0097D9" },    -- bright ravenclaw
    ["@string.regex"]     = { fg = "#0097D9" },    -- bright ravenclaw
    ["@number"]           = { fg = "#D4A017" },    -- gold
    ["@boolean"]          = { fg = "#D4A017" },    -- gold
    ["@float"]            = { fg = "#D4A017" },    -- gold
    ["@constant"]         = { fg = "#D4A017" },    -- gold
    ["@constant.builtin"] = { fg = "#E8B930" },    -- bright gold
    ["@operator"]         = { fg = "#9B9BAB" },    -- weathered scroll
    ["@punctuation"]      = { fg = "#7B7B8B" },    -- light grey
    ["@punctuation.bracket"]   = { fg = "#9B9BAB" },
    ["@punctuation.delimiter"] = { fg = "#6B6B7B" },
    ["@comment"]          = { fg = "#6B6B7B", italic = true },
    ["@tag"]              = { fg = "#C41E3A" },    -- gryffindor
    ["@tag.attribute"]    = { fg = "#D4A017" },    -- gold
    ["@tag.delimiter"]    = { fg = "#6B6B7B" },    -- faded
    ["@namespace"]        = { fg = "#B97EDE" },    -- lavender
    ["@attribute"]        = { fg = "#B97EDE" },    -- lavender
    ["@text.title"]       = { fg = "#E8E6E3", bold = true },
    ["@text.uri"]         = { fg = "#0077B6", underline = true },
    ["@text.emphasis"]    = { italic = true },
    ["@text.strong"]      = { bold = true },
    ["@text.todo"]        = { fg = "#D4A017", bold = true },
    ["@text.note"]        = { fg = "#0077B6" },
    ["@text.warning"]     = { fg = "#D4A017" },
    ["@text.danger"]      = { fg = "#C41E3A" },
  },

  defaults = {
    -- Editor chrome
    CursorLine   = { bg = "#111125" },
    CursorLineNr = { fg = "#2D6A4F", bold = true },
    LineNr       = { fg = "#4B4B5B" },
    Visual       = { bg = "#2D3A5C" },
    VisualNOS    = { bg = "#2D3A5C" },
    Search       = { fg = "#0D0D1A", bg = "#D4A017" },
    IncSearch    = { fg = "#0D0D1A", bg = "#E8B930" },

    -- Diagnostics
    DiagnosticError = { fg = "#C41E3A" },
    DiagnosticWarn  = { fg = "#D4A017" },
    DiagnosticInfo  = { fg = "#0077B6" },
    DiagnosticHint  = { fg = "#9B59B6" },

    DiagnosticUnderlineError = { sp = "#C41E3A", undercurl = true },
    DiagnosticUnderlineWarn  = { sp = "#D4A017", undercurl = true },
    DiagnosticUnderlineInfo  = { sp = "#0077B6", undercurl = true },
    DiagnosticUnderlineHint  = { sp = "#9B59B6", undercurl = true },

    -- Git signs
    DiffAdd    = { fg = "#2ECC71" },
    DiffChange = { fg = "#0077B6" },
    DiffDelete = { fg = "#C41E3A" },
    DiffText   = { fg = "#D4A017" },

    -- Floating windows
    FloatBorder = { fg = "#2D6A4F" },
    NormalFloat = { bg = "#111125" },

    -- Pmenu
    Pmenu      = { bg = "#111125" },
    PmenuSel   = { bg = "#2D6A4F", fg = "#E8E6E3" },
    PmenuSbar  = { bg = "#1A1A2E" },
    PmenuThumb = { bg = "#2D6A4F" },

    -- Telescope
    TelescopeBorder       = { fg = "#2D6A4F" },
    TelescopePromptBorder = { fg = "#2D6A4F" },
    TelescopePromptPrefix = { fg = "#2D6A4F" },
    TelescopeSelection    = { bg = "#1A1A2E", fg = "#E8E6E3" },
    TelescopeMatching     = { fg = "#D4A017", bold = true },

    -- Indent
    IblIndent = { fg = "#1E1E38" },
    IblScope  = { fg = "#2D6A4F" },

    -- WhichKey
    WhichKey          = { fg = "#2D6A4F" },
    WhichKeyGroup     = { fg = "#9B59B6" },
    WhichKeyDesc      = { fg = "#9B9BAB" },
    WhichKeySeparator = { fg = "#4B4B5B" },

    -- NvimTree
    NvimTreeFolderIcon  = { fg = "#0077B6" },
    NvimTreeFolderName  = { fg = "#0077B6" },
    NvimTreeRootFolder  = { fg = "#2D6A4F", bold = true },
    NvimTreeGitDirty    = { fg = "#D4A017" },
    NvimTreeGitNew      = { fg = "#2ECC71" },
    NvimTreeGitDeleted  = { fg = "#C41E3A" },
    NvimTreeSpecialFile = { fg = "#B97EDE" },

    -- Notify
    NotifyERRORBorder = { fg = "#C41E3A" },
    NotifyWARNBorder  = { fg = "#D4A017" },
    NotifyINFOBorder  = { fg = "#0077B6" },
    NotifyDEBUGBorder = { fg = "#9B59B6" },
    NotifyTRACEBorder = { fg = "#6B6B7B" },
    NotifyERRORIcon   = { fg = "#C41E3A" },
    NotifyWARNIcon    = { fg = "#D4A017" },
    NotifyINFOIcon    = { fg = "#0077B6" },
    NotifyDEBUGIcon   = { fg = "#9B59B6" },
    NotifyTRACEIcon   = { fg = "#6B6B7B" },

    -- Lazy
    LazyH1          = { fg = "#0D0D1A", bg = "#2D6A4F", bold = true },
    LazyButton      = { fg = "#9B9BAB", bg = "#1A1A2E" },
    LazyButtonActive = { fg = "#E8E6E3", bg = "#2D6A4F" },
    LazySpecial     = { fg = "#D4A017" },

    -- Mason
    MasonHeader       = { fg = "#0D0D1A", bg = "#2D6A4F", bold = true },
    MasonHighlight    = { fg = "#0077B6" },
    MasonMutedBlock   = { bg = "#1A1A2E" },

    -- Trouble
    TroubleNormal = { bg = "#0D0D1A" },
    TroubleCount  = { fg = "#9B59B6", bold = true },
  },
}

M.type = "dark"

M = require("base46").override_theme(M, "sl1c3d")

return M
