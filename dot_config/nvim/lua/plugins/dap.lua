-- SL1C3D-L4BS — DAP plugins: nvim-dap, dap-ui, Mason DAP adapters (fullstack debugging)

return {
  -- Mason: LSP/DAP/formatter installer (needed for mason-nvim-dap)
  {
    "williamboman/mason.nvim",
    opts = { ui = { border = "rounded" } },
  },

  -- DAP core
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>db", desc = "DAP: toggle breakpoint" },
      { "<leader>dc", desc = "DAP: continue" },
      { "<leader>di", desc = "DAP: step into" },
      { "<leader>do", desc = "DAP: step over" },
      { "<leader>dO", desc = "DAP: step out" },
      { "<leader>dr", desc = "DAP: open REPL" },
      { "<leader>du", desc = "DAP: toggle UI" },
    },
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "jay-babu/mason-nvim-dap.nvim",
    },
    config = function()
      require("configs.dap")
    end,
  },

  -- Auto-install DAP adapters via Mason (debugpy, delve, codelldb, node)
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      ensure_installed = {
        "debugpy",  -- Python
        "node",     -- Node/TS (js-debug-adapter)
        "delve",    -- Go
        "codelldb", -- Rust, C/C++
      },
      automatic_installation = true,
      handlers = {},
    },
  },
}
