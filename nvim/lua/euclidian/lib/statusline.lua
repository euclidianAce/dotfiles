
local util = require("euclidian.lib.util")
local set = util.tab.set
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
   comp.hiGroup = hiGroup
   if type(text) == "string" then
      comp.text = text
   elseif type(text) == "function" then
      statusline._funcs[#lineComponents + 1] = text
      comp.isFunc = true
      comp.funcId = #lineComponents + 1
   end
   table.insert(lineComponents, comp)
end

local function makeLine(tags, winId)
   local tagSet = set(tags)
   local buf = {}
   for _, component in ipairs(lineComponents) do
      local include = false
      for t in pairs(component.tags) do
         if tagSet[t] or currentTags[t] then
            include = true
            break
         end
      end
      for t in pairs(component.invertedTags) do
         if tagSet[t] or currentTags[t] then
            include = false
            break
         end
      end
      if include then
         table.insert(buf, ("%%#%s#"):format(component.hiGroup))
         if component.isFunc then
            table.insert(buf, ([[%%{luaeval("require'euclidian.lib.statusline'._funcs[%d](%d)")}]]):format(component.funcId, winId))
         else
            table.insert(buf, component.text)
         end
         table.insert(buf, "%#Normal#")
      end
   end
   return table.concat(buf)
end

local function setLine(winId)
   local ok, active = pcall(vim.api.nvim_win_get_var, winId or 0, "statusline_active")
   if not ok then
      pcall(vim.api.nvim_win_set_var, winId or 0, "statusline_active", false)
      active = 0
   end
   local tags = active and
   { "Active" } or
   { "Inactive" }
   vim.api.nvim_win_set_option(winId or 0, "statusline", makeLine(tags, winId))
end

function statusline.updateWindows()
   for _, winId in ipairs(vim.api.nvim_list_wins()) do
      setLine(winId)
   end
end

function statusline.setInactive(winId)
   vim.api.nvim_win_set_var(winId or 0, "statusline_active", false)
   statusline.updateWindows()
end

function statusline.setActive(winId)
   vim.api.nvim_win_set_var(winId or 0, "statusline_active", true)
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

function statusline.isActive(winId)
   return a.nvim_win_get_var(winId or 0, "statusline_active")
end

cmd("augroup customstatus")
cmd("autocmd!")
cmd("autocmd WinEnter,BufWinEnter * let w:statusline_active = v:true | lua require'euclidian.lib.statusline'.updateWindows()")
cmd("autocmd WinLeave *             let w:statusline_active = v:false")
cmd("augroup END")

statusline.setActive()
statusline.updateWindows()

return statusline