-- SL1C3D-L4BS — DAP (Debug Adapter Protocol) for fullstack debugging
-- Adapters installed via Mason (:Mason, then install debugpy, delve, codelldb, node)

local dap = require("dap")
local dapui = require("dapui")

-- ─── UI ────────────────────────────────────────────────────────────────────
dapui.setup({
  layouts = {
    {
      elements = {
        { id = "scopes", size = 0.25 },
        { id = "breakpoints", size = 0.25 },
        { id = "stacks", size = 0.25 },
        { id = "watches", size = 0.25 },
      },
      size = 0.2,
      position = "left",
    },
    { elements = { { id = "repl", size = 0.5 }, { id = "console", size = 0.5 } }, size = 0.25, position = "bottom" },
  },
  floating = { border = "rounded" },
})

-- Open UI on session start, close on terminate
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- ─── Keymaps (leader + d) ───────────────────────────────────────────────────
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: toggle breakpoint" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP: continue" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP: step into" })
vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "DAP: step over" })
vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "DAP: step out" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "DAP: open REPL" })
vim.keymap.set("n", "<leader>du", function()
  dapui.toggle()
end, { desc = "DAP: toggle UI" })
