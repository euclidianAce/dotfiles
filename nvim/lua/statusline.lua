local M = {
   _funcs = {},
}

local cmd = vim.api.nvim_command
local function set(t)
   local s = {}
   for _, v in ipairs(t) do
      s[v] = true
   end
   return s
end

local Mode = {}































local modeMap = setmetatable({
   ["n"] = { "Normal", "Constant" },
   ["i"] = { "Insert", "Function" },
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
}, {
   __index = function(self, key)
      return self[string.sub(key, 1, 1)]
   end,
})

local userModes = setmetatable({}, { __index = modeMap })

function M.mode(mode, text, hlgroup)
   userModes[mode] = { text, hlgroup }
end

function M.getModeText()
   local m = vim.fn.mode(true)
   if not modeMap[m] then
      m = string.sub(m, 1, 1)
   end
   cmd("hi! link StatuslineModeText " .. modeMap[m][2])
   return modeMap[m][1]
end

local Component = {}





local lineComponents = {}
local currentTags = {}

function M.add(tags, invertedTags, text, hiGroup)
   local comp = {
      tags = set(tags),
      invertedTags = set(invertedTags),
   }
   if type(text) == "string" then
      comp.text = ("%%#%s#"):format(hiGroup) .. (text) .. "%#Normal#"
   elseif type(text) == "function" then
      M._funcs[#lineComponents + 1] = text
      comp.text = ("%%#%s#"):format(hiGroup) .. ([[%%{luaeval("require'statusline'._funcs[%d]()")}]]):format(#lineComponents + 1) .. "%#Normal#"
   end
   table.insert(lineComponents, comp)
end
local function components()
   local i = 0
   return function()
      i = i + 1
      if lineComponents[i] then
         return lineComponents[i].tags, lineComponents[i].invertedTags, lineComponents[i].text
      end
   end
end

local function makeLine(tags)
   local tagSet = set(tags)
   local buf = {}
   for compTags, compInvTags, text in components() do
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
         table.insert(buf, text)
      end
   end
   return table.concat(buf)
end

function M.setInactive()
   vim.api.nvim_win_set_option(0, "statusline", makeLine({ "Inactive" }))
end

function M.setActive()
   vim.api.nvim_win_set_option(0, "statusline", makeLine({ "Active" }))
end

function M.toggleTag(name)
   currentTags[name] = not currentTags[name]
   M.setActive()
end

cmd("augroup customstatus")
cmd("autocmd!")
cmd("autocmd WinEnter,BufWinEnter * lua require('statusline').setActive()")
cmd("autocmd WinLeave * lua require('statusline').setInactive()")
cmd("augroup END")
M.setActive()

return M
