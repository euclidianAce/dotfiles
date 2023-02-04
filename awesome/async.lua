local Gio = require "lgi".Gio
local gears = require "gears"

local async = {}

function async.readAll(filename)
	local to_resume = coroutine.running()
	Gio.Async.start(function()
		local file = Gio.File.new_for_path(filename)
		local info, err = file:async_query_info("standard::size", "NONE")
		if not info then
			gears.timer.delayed_call(function()
				coroutine.resume(to_resume, nil, err)
			end)
			return
		end
		local stream = file:async_read()
		local bytes = stream:async_read_bytes(info:get_size())
		stream:async_close()
		gears.timer.delayed_call(function()
			coroutine.resume(to_resume, bytes.data)
		end)
	end)()
	return coroutine.yield()
end

return async
