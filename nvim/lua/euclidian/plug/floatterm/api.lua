local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local a = vim.api

local Dialog = dialog.Dialog

local floatterm = {
   show = nil,
   hide = nil,
}

local d
local shell
local key
local termopenOpts
local windowOpts

function floatterm.setTermOptions(opts) termopenOpts = opts end
function floatterm.setShell(s) shell = s end
function floatterm.setToggleKey(k) key = k end
function floatterm.setWindowOpts(opts) windowOpts = opts end

local function addShowMappings()
   vim.keymap.set("n", key, floatterm.show, { silent = true })
end

local function applyWindowOpts(w)
   for k, v in pairs(windowOpts) do
      (w.setOption)(w, k, v)
   end
end

function floatterm.init(opts)
   d = dialog.new(opts)
   addShowMappings()
end

function floatterm.deinit()
   if d then
      d:close()
      d = nil
   end
end

function floatterm.buffer()
   return d:ensureBuf()
end

local function addHideMappings()
   local b = d:ensureBuf()
   b:setKeymap("n", key, floatterm.hide, { silent = true })
   b:setKeymap("t", key, floatterm.hide, { silent = true })
   nvim.autocmd("WinLeave", nil, floatterm.hide, { buffer = b.id, once = true })
end

local getBuf

do
   local shown = false
   floatterm.show = function()
      shown = true
      getBuf()
      d:show()
      local win = d:win()
      win:setOption("winblend", 8)
      applyWindowOpts(win)
      d:focus()
   end

   floatterm.hide = function()
      if shown then
         shown = false
         d:hide()
         addShowMappings()
      end
   end
end

local channelId

getBuf = function()
   local buf = d:ensureBuf()
   if buf:getOption("buftype") ~= "terminal" then
      buf:setOption("modified", false)
      buf:call(function()
         local opts = termopenOpts
         if not opts or not next(opts) then
            opts = vim.empty_dict()
         end
         channelId = vim.fn.termopen(shell, opts)







      end)
      addHideMappings()
   end
   return buf
end

function floatterm.channel()
   return channelId
end

local chansend = a.nvim_chan_send

function floatterm.send(s)
   local buf = getBuf()
   if not buf:isValid() then
      return false
   end
   chansend(channelId, s)
   return true
end

return floatterm