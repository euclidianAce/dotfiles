local a = vim.api

local function failsafe(f, err_prefix)
   local ok = true
   local err
   local unpack_ = unpack
   return function(...)
      if ok then
         local res = { pcall(f, ...) }
         ok = table.remove(res, 1)
         if ok then
            return unpack_(res)
         end
         err = res[1]
      end
      a.nvim_err_writeln((err_prefix or "") .. err)
   end
end

local function pcallWrap(f, err_prefix)
   local unpack_ = unpack
   return function(...)
      local res = { pcall(f, ...) }
      local ok = table.remove(res, 1)
      if ok then
         return unpack_(res)
      end
      local err = res[1]
      a.nvim_err_writeln((err_prefix or "") .. err)
   end
end

local UI = {}















local auto = require("euclidian.lib.nvim._autogenerated")

local function unCamel(s)
   return (s:gsub("[A-Z]", function(m)
      return "_" .. m:lower()
   end))
end
local function genMetatable(t, prefix)
   local cache = setmetatable({}, { __mode = "kv" })
   local api = vim.api
   local index = setmetatable({}, {
      __index = function(self, key)
         local fn = api["nvim_" .. prefix .. "_" .. unCamel(key)]
         if fn then
            local wrapped = function(self, ...)
               return fn(self.id, ...)
            end
            rawset(self, key, wrapped)
            return wrapped
         end
      end,
   })
   return {
      __name = "nvim." .. prefix,
      __call = function(_, n)
         if not n or n == 0 then
            n = api["nvim_get_current_" .. prefix]()
         end
         if not cache[n] then
            cache[n] = setmetatable({ id = n }, { __index = t })
         end
         return cache[n]
      end,
      __index = index,
      __eq = function(self, other)
         if not (type(self) == "table") or not (type(other) == "table") then
            return false
         end
         local selfMt = getmetatable(self)
         local otherMt = getmetatable(other)
         if not selfMt or not otherMt then
            return false
         end
         return (selfMt.__index == otherMt.__index) and
         ((self).id == (other).id)
      end,
   }
end
local function genSetMetatable(t, prefix)
   setmetatable(t, genMetatable(t, prefix))
end
genSetMetatable(auto.Buffer, "buf")
genSetMetatable(auto.Window, "win")
genSetMetatable(auto.Tab, "tab")

setmetatable(auto.api, {
   __index = function(self, key)
      local api = vim.api
      local fn = api["nvim_" .. unCamel(key)]
      if fn then
         rawset(self, key, fn)
         return fn
      end
   end,
})

local CommandOpts = {}










































local AutocmdOpts = {}






local nvim = {
   api = auto.api,
   Window = auto.Window,
   Buffer = auto.Buffer,
   Tab = auto.Tab,

   UI = UI,
   MapOpts = auto.MapOpts,
   CommandArgs = auto.CommandArgs,
   CommandAttributes = auto.CommandAttributes,

   CommandOpts = CommandOpts,
   AutocmdOpts = AutocmdOpts,

   _exports = {},
}

function nvim.ui(n)
   return (a.nvim_list_uis())[n or 1]
end

function nvim.openWin(b, enter, c)
   return nvim.Window(a.nvim_open_win(b and b.id or 0, enter, c))
end

function nvim.createBuf(listed, scratch)
   return nvim.Buffer(a.nvim_create_buf(listed, scratch))
end

function nvim.winBuf(n)
   local win = nvim.Window(n)
   return win, nvim.Buffer(win:getBuf())
end

function nvim.command(fmt, ...)
   a.nvim_command(string.format(fmt, ...))
end

local function toStrArr(s)
   if type(s) == "string" then
      return { s }
   else
      return s
   end
end

function nvim.autocmd(sEvents, sPatts, expr, maybeOpts)
   assert(sEvents, "no events")
   assert(expr, "no expr")

   local events = table.concat(toStrArr(sEvents), ",")
   local opts = maybeOpts or {}

   assert(sPatts or opts.buffer, "no patterns or buffer")
   local patts = sPatts and table.concat(toStrArr(sPatts), ",")

   local actualExpr
   if type(expr) == "string" then
      actualExpr = expr
   else
      local key = "autocmd" .. events .. (patts or "buffer=" .. tostring(opts.buffer))
      if opts.canError then
         nvim._exports[key] = pcallWrap(expr, ("Error in autocmd for %s %s: "):format(events, patts))
      else
         nvim._exports[key] = failsafe(expr, ("Error in autocmd for %s %s: "):format(events, patts))
      end
      actualExpr = ("lua require'euclidian.lib.nvim'._exports[%q]()"):format(key)
   end
   local cmd = { "autocmd" }
   table.insert(cmd, events)
   if opts.buffer then
      table.insert(cmd, ("<buffer=%d>"):format(opts.buffer == true and vim.api.nvim_get_current_buf() or opts.buffer))
   end
   if patts then table.insert(cmd, patts) end
   if opts.once then table.insert(cmd, "++once") end
   if opts.nested then table.insert(cmd, "++nested") end
   table.insert(cmd, actualExpr)

   nvim.command(table.concat(cmd, " "))
end

function nvim.augroup(name, lst, clear)
   nvim.command("augroup %s", name)
   if clear then
      nvim.command("autocmd!")
   end
   for _, v in ipairs(lst) do
      nvim.autocmd(v[1], v[2], v[3], v[4])
   end
   nvim.command("augroup END")
end

function nvim.setKeymap(mode, lhs, rhs, userSettings)
   if type(rhs) == "string" then
      a.nvim_set_keymap(mode, lhs, rhs, userSettings)
   else
      assert(not userSettings.callback)
      userSettings.callback = rhs
      a.nvim_set_keymap(mode, lhs, '', userSettings)
   end
end

function nvim.delKeymap(mode, lhs)
   pcall(a.nvim_del_keymap, mode, lhs)
end

nvim.Buffer.setKeymap = function(self, mode, lhs, rhs, userSettings)
   if type(rhs) == "string" then
      a.nvim_buf_set_keymap(self.id, mode, lhs, rhs, userSettings)
   else
      assert(not userSettings.callback)
      userSettings.callback = rhs
      a.nvim_buf_set_keymap(self.id, mode, lhs, '', userSettings)
   end
end

nvim.Buffer.delKeymap = function(self, mode, lhs)
   pcall(a.nvim_buf_del_keymap, self.id, mode, lhs)
end

return nvim