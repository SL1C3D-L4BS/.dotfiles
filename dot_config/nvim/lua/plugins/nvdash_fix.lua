-- ─────────────────────────────────────────────────────────────────────────────
-- NvDash cursor fix — SL1C3D-L4BS
-- NvChad nvdash sets cursor to (row, col) where col can exceed line length
-- (buffer lines are empty); nvim_win_set_cursor then errors "Column value outside range".
-- Patch open() to clamp cursor column to valid range.
-- ─────────────────────────────────────────────────────────────────────────────

return {
  {
    "NvChad/NvChad",
    optional = true,
    opts = function(_, opts)
      vim.defer_fn(function()
        local ok, nvdash = pcall(require, "nvchad.nvdash")
        if not ok or not nvdash or not nvdash.open then return end

        local api = vim.api
        local _open = nvdash.open

        nvdash.open = function(buf, win, action)
          local set_cursor_orig = api.nvim_win_set_cursor
          api.nvim_win_set_cursor = function(win_id, pos)
            local bufnr = api.nvim_win_get_buf(win_id)
            local line_count = api.nvim_buf_line_count(bufnr)
            if pos[1] < 1 or pos[1] > line_count then return end
            local lines = api.nvim_buf_get_lines(bufnr, pos[1] - 1, pos[1], false)
            local line = (lines and lines[1]) or ""
            local col = math.min(pos[2], math.max(0, #line))
            set_cursor_orig(win_id, { pos[1], col })
          end
          local ok2, err = pcall(_open, buf, win, action)
          api.nvim_win_set_cursor = set_cursor_orig
          if not ok2 then error(err) end
        end
      end, 0)
      return opts or {}
    end,
  },
}
