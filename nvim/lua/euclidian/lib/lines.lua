local nvim = require("euclidian.lib.nvim")

local function set(t)
   local s = {}
   for _, v in ipairs(t) do
      s[v] = true
   end
   return s
end

local Component = {}









local Line = {}







local cache = {}
local lines = { Line = Line, Component = Component, _cache = cache }

local lastId = 0

function lines.new()
   local l = setmetatable({ functions = {} }, { __index = Line })
   cache[lastId] = l
   l._internalId = lastId
   lastId = lastId + 1
   return l
end

function Line:add(   tags,
   invertedTags,
   text,
   hiGroup,
   preEval)

   local comp = {
      tags = set(tags),
      invertedTags = set(invertedTags),
      preEval = preEval,
      hiGroup = hiGroup,
   }
   if type(text) == "string" then
      comp.text = text
   elseif text then
      self.functions[#self + 1] = text
      comp.isFunc = true
      comp.funcId = #self + 1
   end
   table.insert(self, comp)
end

function Line:reify(activeTags, param)
   local buf = {}
   for i, component in ipairs(self) do
      local include = false
      for t in pairs(component.tags) do
         if activeTags[t] then
            include = true
            break
         end
      end
      if include then
         for t in pairs(component.invertedTags) do
            if activeTags[t] then
               include = false
               break
            end
         end
      end
      if include then
         table.insert(buf, "%#" .. component.hiGroup .. "#")
         if component.isFunc then
            if component.preEval then
               local ok, res = pcall(self.functions[component.funcId], param)
               if ok then
                  table.insert(buf, res)
               else
                  table.insert(buf, "???")
               end
            else
               local evalArg = ("require'euclidian.lib.lines'._cache[%d].functions[%d](%s)"):format(
               self._internalId,
               component.funcId,
               param and tostring(param) or "")

               table.insert(
               buf,
               ("%%{luaeval(%q)}"):format(evalArg))

            end
         else
            table.insert(buf, component.text)
         end
         if i < #self and not self[i + 1].hiGroup then
            table.insert(buf, "%#Normal#")
         end
      end
   end
   return table.concat(buf)
end

function Line:setLocalStatus(active, win)
   return pcall(function()
      local str = self:reify(active, win.id)
      win:setOption("statusline", str)
   end)
end

function Line:setLocalBar(active, win)
   return pcall(function()
      local str = self:reify(active, win.id)
      win:setOption("winbar", str)
   end)
end

function Line:setTab(active)
   return pcall(function()
      vim.o.tabline = self:reify(active)
   end)
end

return lines