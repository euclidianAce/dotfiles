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
      comp.text = ("%%#%s#"):format(hiGroup) .. ([[%%{luaeval("require'euclidian.statusline'._funcs[%d]()")}]]):format(#lineComponents + 1) .. "%#Normal#"
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

local function setLine(win_id)
   local ok, active = pcall(vim.api.nvim_win_get_var, win_id or 0, "statusline_active")
   if not ok then
      pcall(vim.api.nvim_win_set_var, win_id or 0, "statusline_active", 0)
      active = 0
   end
   local tags = active == 1 and
   { "Active" } or
   { "Inactive" }
   vim.api.nvim_win_set_option(win_id or 0, "statusline", makeLine(tags))
end

function M.updateWindows()
   for _, win_id in ipairs(vim.api.nvim_list_wins()) do
      setLine(win_id)
   end
end

function M.setInactive(win_id)
   vim.api.nvim_win_set_var(win_id or 0, "statusline_active", 0)
   M.updateWindows()
end

function M.setActive(win_id)
   vim.api.nvim_win_set_var(win_id or 0, "statusline_active", 1)
   M.updateWindows()
end

function M.toggleTag(name)
   currentTags[name] = not currentTags[name]
   M.updateWindows()
end

cmd("augroup customstatus")
cmd("autocmd!")
cmd("autocmd WinEnter,BufWinEnter * let w:statusline_active = 1 | lua require'euclidian.statusline'.updateWindows()")
cmd("autocmd WinLeave *             let w:statusline_active = 0 | lua require'euclidian.statusline'.updateWindows()")
cmd("augroup END")

M.setActive()
M.updateWindows()

return M