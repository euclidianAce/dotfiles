
local window = require("euclidian.lib.window")
local a = vim.api

local Dialog = {Opts = {}, }











local function new(x, y, wid, hei)
   local win, buf = window.floating(x or 10, y or 10, wid or 50, hei or 5)
   a.nvim_buf_set_option(buf, "buftype", "nofile")
   a.nvim_buf_set_option(buf, "modifiable", false)
   a.nvim_win_set_option(win, "winblend", 5)
   return setmetatable({
      win = win,
      buf = buf,
   }, { __index = Dialog })
end
function Dialog:setLines(txt)
   a.nvim_buf_set_option(self.buf, "modifiable", true)
   a.nvim_buf_set_lines(self.buf, 0, -1, false, txt)
   a.nvim_buf_set_option(self.buf, "modifiable", false)
   return self
end
function Dialog:setText(edits)
   a.nvim_buf_set_option(self.buf, "modifiable", true)
   for _, edit in ipairs(edits) do
      a.nvim_buf_set_text(self.buf, edit[2], edit[3], edit[4], edit[5], { edit[1] })
   end
   a.nvim_buf_set_option(self.buf, "modifiable", false)
   return self
end
function Dialog:setCursor(row, col)
   a.nvim_win_set_cursor(self.win, { row, col })
   return self
end
function Dialog:getCursor()
   local pos = a.nvim_win_get_cursor(self.win)
   return pos[1], pos[2]
end
function Dialog:getLine(n)
   return a.nvim_buf_get_lines(self.buf, n - 1, n, false)[1]
end
function Dialog:setWin(o)
   a.nvim_win_set_config(self.win, {
      relative = "editor",
      row = assert(o.row, "no row"), col = assert(o.col, "no col"),
      width = assert(o.wid, "no wid"), height = assert(o.hei, "no hei"),
   })
   return self
end
function Dialog:addKeymap(mode, lhs, rhs, opts)
   a.nvim_buf_set_keymap(self.buf, mode, lhs, rhs, opts)
   return self
end
function Dialog:delKeymap(mode, lhs)
   a.nvim_buf_del_keymap(self.buf, mode, lhs)
   return self
end
function Dialog:setWinOpt(optName, val)
   a.nvim_win_set_option(self.win, optName, val)
   return self
end
function Dialog:setBufOpt(optName, val)
   a.nvim_buf_set_option(self.buf, optName, val)
   return self
end
function Dialog:setPrompt(prompt, cb)
   a.nvim_buf_set_option(self.buf, "modifiable", true)
   a.nvim_buf_set_option(self.buf, "buftype", "prompt")

   vim.fn.prompt_setprompt(self.buf, prompt or "> ")
   vim.fn.prompt_setcallback(self.buf, cb)
   a.nvim_command("startinsert")
end
function Dialog:unsetPrompt()
   a.nvim_buf_set_option(self.buf, "modifiable", false)
   a.nvim_buf_set_option(self.buf, "buftype", "nofile")
   a.nvim_command("stopinsert")
end
function Dialog:close()
   a.nvim_win_close(self.win, true)
end

return {
   new = new,
   Dialog = Dialog,
}
