-- ─────────────────────────────────────────────────────────────────────────────
-- nvim-web-devicons: SL1C3D-L4BS palette overrides (elite 2026)
-- Languages, DBs, tools — accent #5865F2, logo #b366ff, yellow #f1fa8c, etc.
-- Run :NvimWebDeviconsHiTest to preview all icons.
-- ─────────────────────────────────────────────────────────────────────────────

return {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false, -- load at startup so :NvimWebDeviconsHiTest is available
    opts = {
      color_icons = true,
      default = true,
      override = {
        -- Core languages (SL1C3D-L4BS accent / brand)
        lua = { icon = "\u{e620}", color = "#5865F2", name = "Lua" },
        py = { icon = "\u{e606}", color = "#f1fa8c", name = "Python" },
        pyi = { icon = "\u{e606}", color = "#f1fa8c", name = "Python" },
        rs = { icon = "\u{e68b}", color = "#dea584", name = "Rust" },
        go = { icon = "\u{e627}", color = "#00ADD8", name = "Go" },
        ts = { icon = "\u{e69e}", color = "#519ABA", name = "TypeScript" },
        tsx = { icon = "\u{e69e}", color = "#1354BF", name = "Tsx" },
        js = { icon = "\u{e60c}", color = "#f1fa8c", name = "JavaScript" },
        jsx = { icon = "\u{e65b}", color = "#20C2E3", name = "Jsx" },
        c = { icon = "\u{e61e}", color = "#599EFF", name = "C" },
        cpp = { icon = "\u{e61d}", color = "#519ABA", name = "Cpp" },
        ["c++"] = { icon = "\u{e61d}", color = "#F34B7D", name = "CPlusPlus" },
        zig = { icon = "\u{e62a}", color = "#F69A1B", name = "Zig" },
        -- DB / data
        sql = { icon = "\u{e706}", color = "#e0e0e0", name = "Sql" },
        db = { icon = "\u{e706}", color = "#e0e0e0", name = "Db" },
        json = { icon = "\u{e60b}", color = "#f1fa8c", name = "Json" },
        yaml = { icon = "\u{e60a}", color = "#909090", name = "Yaml" },
        yml = { icon = "\u{e60a}", color = "#909090", name = "Yml" },
        toml = { icon = "\u{e6b2}", color = "#9C4221", name = "Toml" },
        -- Config / infra
        Dockerfile = { icon = "\u{f308}", color = "#458EE6", name = "Dockerfile" },
        tf = { icon = "\u{e68f}", color = "#5F43E9", name = "Terraform" },
        tfvars = { icon = "\u{e68f}", color = "#5F43E9", name = "TFVars" },
        nix = { icon = "\u{f313}", color = "#7EBAE4", name = "Nix" },
        sh = { icon = "\u{f489}", color = "#909090", name = "Sh" },
        zsh = { icon = "\u{f489}", color = "#50fa7b", name = "Zsh" },
        bash = { icon = "\u{f489}", color = "#89E051", name = "Bash" },
        -- Web / markup
        html = { icon = "\u{e736}", color = "#E44D26", name = "Html" },
        css = { icon = "\u{e749}", color = "#663399", name = "Css" },
        scss = { icon = "\u{e603}", color = "#F55385", name = "Scss" },
        md = { icon = "\u{f48a}", color = "#e0e0e0", name = "Md" },
        markdown = { icon = "\u{f48a}", color = "#e0e0e0", name = "Markdown" },
        vue = { icon = "\u{e69c}", color = "#50fa7b", name = "Vue" },
        -- Brand highlight
        conf = { icon = "\u{e615}", color = "#5865F2", name = "Conf" },
        cfg = { icon = "\u{e615}", color = "#5865F2", name = "Configuration" },
        default = { icon = "\u{f016}", color = "#909090", name = "Default" },
      },
    },
  },
}
