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

function floatterm.setTermOptions(opts) termopenOpts = opts end
function floatterm.setShell(s) shell = s end
function floatterm.setToggleKey(k) key = k end

local function addShowMappings()
   nvim.setKeymap("n", key, floatterm.show, { noremap = true, silent = true })
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
   b:setKeymap("n", key, floatterm.hide, { noremap = true, silent = true })
   b:setKeymap("t", key, floatterm.hide, { noremap = true, silent = true })
   nvim.autocmd("WinLeave", nil, floatterm.hide, { buffer = b.id, once = true })
end

local getBuf

do
   local shown = false
   floatterm.show = function()
      shown = true
      getBuf()
      d:show():win():setOption("winblend", 8)
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
         channelId = vim.fn.termopen(shell, termopenOpts)







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