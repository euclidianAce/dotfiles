
local util = require("euclidian.lib.util")
local set = util.set
local a = vim.api

local statusline = {
   higroup = "StatuslineModeText",
   _funcs = {},








}

local cmd = vim.api.nvim_command

local modeMap = setmetatable({
   ["n"] = { "Normal", "Constant" },
   ["i"] = { "Insert", "Function" },
   ["r"] = { "Confirm", "Special" },
   ["R"] = { "Replace", "Special" },
   ["v"] = { "Visual", "String" },
   ["V"] = { "Visual Line", "String" },
   [""] = { "Visual Block", "String" },
   ["c"] = { "Command", "Special" },
   ["s"] = { "Select", "Visual" },
   ["S"] = { "Select Line", "Visual" },
   [""] = { "Select Block", "Visual" },
   ["t"] = { "Terminal", "Number" },
   ["!"] = { "Shell", "Comment" },
   ["?"] = { " ???? ", "Error" },
}, {
   __index = function(self, key)
      return rawget(self, string.sub(key, 1, 1)) or self["?"]
   end,
})

local userModes = setmetatable({}, {
   __index = function(self, key)
      return rawget(self, string.sub(key, 1, 1)) or modeMap[key]
   end,
})

function statusline.mode(mode, text, hlgroup)
   userModes[mode] = { text, hlgroup }
end

function statusline.getModeText()
   local m = vim.fn.mode(true)
   local map = userModes[m]
   cmd("hi! clear StatuslineModeText | hi! link StatuslineModeText " .. map[2])
   return map[1]
end

local Component = {}






local lineComponents = {}
local currentTags = {}

function statusline.add(tags, invertedTags, text, hiGroup)
   local comp = {
      tags = set(tags),
      invertedTags = set(invertedTags),
   }
   if type(text) == "string" then
      comp.text = {
         ("%%#%s#"):format(hiGroup),
         text,
         "%#Normal#",
      }
   elseif type(text) == "function" then
      statusline._funcs[#lineComponents + 1] = text
      comp.isFunc = true
      comp.text = {
         ("%%#%s#"):format(hiGroup), ([[%%{luaeval("require'euclidian.lib.statusline'._funcs[%d](]]):format(#lineComponents + 1),
         [[)")}]],
         "%#Normal#",
      }
   end
   table.insert(lineComponents, comp)
end

local function components()
   local i = 0
   return function()
      i = i + 1
      if lineComponents[i] then
         return lineComponents[i].tags, lineComponents[i].invertedTags, lineComponents[i].text, lineComponents[i].isFunc
      end
   end
end

local function makeLine(tags, winId)
   local tagSet = set(tags)
   local buf = {}
   for compTags, compInvTags, text, isFunc in components() do
      local include = false
      for t in pairs(compTags) do
         if tagSet[t] or currentTags[t] then
            include = true
            break
         end
      end
      for t in pairs(compInvTags) do
         if tagSet[t] or currentTags[t] then
            include = false
            break
         end
      end
      if include then
         if isFunc then
            table.insert(buf, text[1])
            table.insert(buf, text[2])
            table.insert(buf, tostring(winId))
            table.insert(buf, text[3])
         else
            table.insert(buf, table.concat(text))
         end
      end
   end
   return table.concat(buf)
end

local function setLine(winId)
   local ok, active = pcall(vim.api.nvim_win_get_var, winId or 0, "statusline_active")
   if not ok then
      pcall(vim.api.nvim_win_set_var, winId or 0, "statusline_active", 0)
      active = 0
   end
   local tags = active == 1 and
   { "Active" } or
   { "Inactive" }
   vim.api.nvim_win_set_option(winId or 0, "statusline", makeLine(tags, winId))
end

function statusline.updateWindows()
   for _, win_id in ipairs(vim.api.nvim_list_wins()) do
      setLine(win_id)
   end
end

function statusline.setInactive(win_id)
   vim.api.nvim_win_set_var(win_id or 0, "statusline_active", 0)
   statusline.updateWindows()
end

function statusline.setActive(win_id)
   vim.api.nvim_win_set_var(win_id or 0, "statusline_active", 1)
   statusline.updateWindows()
end

function statusline.toggleTag(name)
   if type(name) == "string" then
      currentTags[name] = not currentTags[name]
   else
      for _, v in ipairs(name) do
         currentTags[v] = not currentTags[v]
      end
   end
   statusline.updateWindows()
end

function statusline.isActive(winid)
   return a.nvim_win_get_var(winid or 0, "statusline_active") == 1
end

cmd("augroup customstatus")
cmd("autocmd!")
cmd("autocmd WinEnter,BufWinEnter * let w:statusline_active = 1 | lua require'euclidian.lib.statusline'.updateWindows()")
cmd("autocmd WinLeave *             let w:statusline_active = 0")
cmd("augroup END")

statusline.setActive()
statusline.updateWindows()

return statusline
