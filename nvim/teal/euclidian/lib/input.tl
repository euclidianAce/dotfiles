local nvim <const> = require("euclidian.lib.nvim")
local z <const> = require("euclidian.lib.azync")

local input <const> = {}

function input.waitForKey(buf: nvim.Buffer, mode: vim.Mode, ...: string): string
	local keys <const> = {...}
	local teardown <const> = vim.schedule_wrap(function()
		for _, key in ipairs(keys) do
			buf:delKeymap(mode, key)
		end
	end)
	local pressed: string
	local me <const> = assert(z.currentFrame(), "attempt to waitForKey not in a coroutine")
	vim.schedule(function()
		for _, key in ipairs(keys) do
			buf:setKeymap(mode, key, function()
				pressed = key
				teardown()
				z.resume(me)
			end, { silent = true })
		end
	end)
	z.suspend()
	return pressed
end

return input
