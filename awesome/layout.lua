-- custom layout for awesomewm
-- based somewhat off of the default fair layout

local math = math
local ipairs = ipairs
local client = require("awful.client")
local capi = {mouse = mouse, screen = screen, mousegrabber = mousegrabber}

local function organize(p)
	-- p has clients and the work area
	-- 	p.clients, p.workarea

	for index, client in ipairs(p.clients) do
		-- a clients geometry table has
		-- 	x,y coordinates
		-- 	width and height
		local geometry = {}

		-- the math for all the tiling and such
		if #p.clients == 3 then
			geometry.width = p.workarea.width / 2
			if index == 1 then
				geometry.x = p.workarea.x
				geometry.y = p.workarea.y
				geometry.height = p.workarea.height
			else
				geometry.height = p.workarea.height / 2
				geometry.x = p.workarea.x + p.workarea.width / 2
				geometry.y = p.workarea.y + (index-2) * p.workarea.height / 2
			end
		else
			local rows = (#p.clients > 3 and 2) or 1
			local topCols = (#p.clients > 3 and math.floor(#p.clients / 2)) or #p.clients
			local botCols = math.ceil(#p.clients / 2)

			geometry.height = p.workarea.height / rows
			if index <= topCols then
				geometry.y = p.workarea.y
				geometry.x = p.workarea.x + (index-1) * p.workarea.width / topCols
				geometry.width = p.workarea.width / topCols
			else
				geometry.width = p.workarea.width / botCols
				geometry.y = p.workarea.y + p.workarea.height / 2
				geometry.x = p.workarea.x + (index - topCols - 1) * geometry.width
			end

		end
		p.geometries[client] = geometry
	end
end

local function mouse_resize_handler(client, corner, x, y)
	local cursor = "cross"
	local coords_delta = {x=0, y=0}
	local workarea = client.screen.workarea
	capi.mousegrabber.run(function(mouse)
		if not client.valid then return false end
		mouse.x = mouse.x + coords_delta.x
		mouse.y = mouse.y + coords_delta.y
		local geometry = client:geometry()

		local num = 0.5
		client.setwfact(num, client)
	end)
end

return {
	arrange = organize,
	name = "Tiled",
	mouse_resize_handler = mouse_resize_handler,
	resize_jump_to_corner = false,
}

