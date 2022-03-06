local nvim = require("euclidian.lib.nvim")

local function set(t)
   local s = {}
   for _, v in ipairs(t) do
      s[v] = true
   end
   return s
end

local statusline = {
   higroup = "StatuslineModeText",
   _funcs = {},
}

local active = {}

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
}, {
   __index = function(self, key)
      return rawget(self, string.sub(key, 1, 1)) or { " ???? ", "Error" }
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
   local m = vim.api.nvim_get_mode().mode
   local map = userModes[m]
   nvim.command("hi! clear StatuslineModeText")
   nvim.command("hi! link StatuslineModeText %s", map[2])
   return map[1]
end

local Component = {}









local lineComponents = {}
local currentTags = {}

function statusline.add(
   tags,
   invertedTags,
   text,
   hiGroup,
   preEval)

   local comp = {
      tags = set(tags),
      invertedTags = set(invertedTags),
   }
   comp.hiGroup = hiGroup
   if type(text) == "string" then
      comp.text = text
   elseif text then
      statusline._funcs[#lineComponents + 1] = text
      comp.isFunc = true
      comp.funcId = #lineComponents + 1
   end
   comp.preEval = preEval
   table.insert(lineComponents, comp)
end

local function makeLine(tags, winId)
   local tagSet = set(tags)
   local buf = {}
   for i, component in ipairs(lineComponents) do
      local include = false
      for t in pairs(component.tags) do
         if tagSet[t] or currentTags[t] then
            include = true
            break
         end
      end
      if include then
         for t in pairs(component.invertedTags) do
            if tagSet[t] or currentTags[t] then
               include = false
               break
            end
         end
      end
      if include then
         table.insert(buf, "%#" .. component.hiGroup .. "#")
         if component.isFunc then
            if component.preEval then
               local ok, res = pcall(statusline._funcs[component.funcId], winId)
               if ok then
                  table.insert(buf, res)
               else
                  print(res)
                  table.insert(buf, "???")
               end
            else
               table.insert(
               buf,
               [=[%{luaeval("require'euclidian.lib.statusline'._funcs[]=] ..
               component.funcId ..
               "](" .. winId .. [=[)")}]=])

            end
         else
            table.insert(buf, component.text)
         end
         if i < #lineComponents and not lineComponents[i + 1].hiGroup then
            table.insert(buf, "%#Normal#")
         end
      end
   end
   return table.concat(buf)
end

function statusline.updateWindow(winId)
   local win = nvim.Window(winId)
   if win:isValid() then
      local tags = active[win.id] and
      { "Active" } or
      { "Inactive" }
      win:setOption("statusline", makeLine(tags, win.id))
   end
end

function statusline.updateAllWindows()
   for _, winId in ipairs(vim.api.nvim_list_wins()) do
      statusline.updateWindow(winId)
   end
end

function statusline.setInactive(winId)
   winId = winId or nvim.Window().id
   active[winId] = false
   statusline.updateWindow(winId)
end

function statusline.setActive(winId)
   winId = winId or nvim.Window().id
   active[winId] = true
   statusline.updateWindow(winId)
end

function statusline.toggleTag(name)

   for _, v in ipairs(type(name) == "table" and assert(name) or { name }) do
      currentTags[v] = not currentTags[v]
   end
   statusline.updateAllWindows()
end

function statusline.tagToggler(name)
   return function() statusline.toggleTag(name) end
end

function statusline.isActive(winId)
   winId = winId or nvim.Window().id
   return active[winId]
end

local group = "Statusline"
nvim.api.createAugroup(group, { clear = true })
nvim.api.createAutocmd({ "WinEnter", "BufWinEnter" }, { callback = function() statusline.setActive() end, group = group })
nvim.api.createAutocmd("WinLeave", { callback = function() statusline.setInactive() end, group = group })

statusline.setActive()
statusline.updateAllWindows()

return statusline