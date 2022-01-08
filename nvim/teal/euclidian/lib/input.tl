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

function input.input(opts: vim.ui.InputOpts): string
	local result: string
	z.suspend(function(me: z.Frame<nil>)
		vim.ui.input(opts, function(i: string)
			result = i
			z.resume(me)
		end)
	end)
	return result
end

function input.select(items: {any}, opts: vim.ui.SelectOpts): any, integer
	local result, result_idx: any, integer
	z.suspend(function(me: z.Frame<nil>)
		vim.ui.select(items, opts, function(r: any, i: integer)
			result = r
			result_idx = i
			z.resume(me)
		end)
	end)
	return result, result_idx
end

return input
