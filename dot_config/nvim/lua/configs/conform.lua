local options = {
  formatters_by_ft = {
    lua       = { "stylua" },
    python    = { "black", "isort" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    javascriptreact = { "prettier" },
    css       = { "prettier" },
    scss      = { "prettier" },
    html      = { "prettier" },
    json      = { "prettier" },
    yaml      = { "prettier" },
    markdown  = { "prettier" },
    rust      = { "rustfmt" },
    go        = { "gofmt" },
    sh        = { "shfmt" },
    bash      = { "shfmt" },
    zsh       = { "shfmt" },
  },
  format_on_save = {
    timeout_ms = 700,
    lsp_fallback = true,
  },
}

return options
