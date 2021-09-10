local a <const> = vim.api
local dialog <const> = require("euclidian.lib.dialog")
local fs <const> = require("euclidian.lib.fs")
local notification <const> = require("euclidian.lib.notification")
local nvim <const> = require("euclidian.lib.nvim")
local quick <const> = require("euclidian.lib.dialog.quick")
local z <const> = require("euclidian.lib.async.zig")

-- TODO: use libuv for file reads and writes

local stdpath <const> = vim.fn.stdpath as function(string): string

local record scripter
	record Opts
		open: string
		dir: string
	end
	__call: function(scripter, Opts)
end

local dir = stdpath("config") .. "/.scripter"
local function scriptPath(name: string): string
	return dir .. "/" .. name
end

local currentScript, currentScriptChanged: string, boolean
local openEditor, openBrowser: function(), function()

local mainDialog = dialog.new{
	wid = 75, hei = 30,
	centered = true,
	interactive = true,
	notMinimal = true,
	hidden = true,
}
mainDialog:setModifiable(true)

local function execBuffer(b: nvim.Buffer, ...: any)
	local lines <const> = b:getLines(0, -1, false);
	local txt <const> = table.concat(lines, "\n")

	local chunk <const>, loaderr <const> = loadstring(txt)
	if not chunk then
		a.nvim_err_writeln(loaderr)
		return
	end
	local ok <const>, err <const> = pcall(chunk, ...) as (boolean, string)
	if not ok then
		a.nvim_err_writeln(err)
	end
end

local promptOpts <const>: dialog.Dialog.Opts = {
	wid = 45, hei = 1,
	centered = true,
	interactive = true,
	ephemeral = true,
}

local function saveBufferToFile(buf: nvim.Buffer, file: string)
	assert(buf)
	assert(file)
	if not currentScriptChanged then
		return
	end
	local realPath <const> = scriptPath(file)
	local fh <const>, err <const> = io.open(realPath, "w")
	if err then
		notification.create("Could not save script " .. file .. ": " .. tostring(err))
		return
	end
	for _, ln in ipairs(buf:getLines(0, -1, false)) do
		fh:write(ln, "\n")
	end
	fh:close()
	notification.create("Saved script " .. file)
	currentScriptChanged = false
end

local function clearMappings(d: dialog.Dialog)
	for _, map in ipairs(d:buf():getKeymap("n") as {{string:string}}) do
		d:delKeymap("n", map.lhs)
	end
end

openEditor = function()
	assert(currentScript)
	clearMappings(mainDialog)
	local buf <const> = mainDialog:ensureBuf()
	local win <const> = mainDialog:ensureWin()
	mainDialog:focus()

	local text <const> = {}
	if fs.exists(scriptPath(currentScript)) then
		for ln in io.lines(scriptPath(currentScript)) do
			table.insert(text, ln)
		end
	end
	mainDialog:setLines(text)

	mainDialog:setWinSize(75, 30):center()
	win:setOption("cursorline", false)
	win:setOption("number", true)
	win:setOption("relativenumber", true)

	mainDialog:setModifiable(true)
	buf:setOption("ft", "lua")
	buf:setKeymap(
		"n", "<cr>",
		function() execBuffer(mainDialog:buf()) end,
		{ silent = true, noremap = true }
	)
	buf:setKeymap(
		"n", "<leader>r",
		z.asyncFn(function()
			local strArgs <const> = quick.prompt("Script Arguments: ")
			local loaded <const>, err <const> = loadstring("return " .. strArgs)
			if not loaded then
				notification.create("Could not load arguments: " .. tostring(err))
				return
			end
			local function forwardPcall(ok: boolean, ...: any): any...
				if not ok then
					coroutine.yield()
					error("unreachable")
				end
				return ...
			end
			execBuffer(mainDialog:buf(), forwardPcall(pcall(loaded)))
		end),
		{ silent = true, noremap = true }
	)
	local save = z.asyncFn(function()
		if not currentScript then
			currentScript = quick.prompt("Save As: ", promptOpts)
		end
		saveBufferToFile(buf, currentScript)
	end)
	buf:setKeymap(
		"n", "<bs>",
		function()
			z.nosuspend(save)
			currentScript = nil
			openBrowser()
		end,
		{ silent = true, noremap = true }
	)
	buf:setKeymap("n", "<leader>W", save, { silent = true, noremap = true })
	buf:setKeymap("n", ":w<cr>", save, { silent = true, noremap = true })
	mainDialog:show()
	buf:attach(false, {
		on_lines = function(): boolean
			if currentScript then
				currentScriptChanged = true
			end
			return true
		end,
	})
	mainDialog:addKeymap("n", "", function() mainDialog:hide() end, { silent = true, noremap = true })
end

openBrowser = function()
	assert(not currentScript)
	local win <const> = mainDialog:ensureWin()
	local buf <const> = mainDialog:ensureBuf()

	mainDialog:setModifiable(false)
	a.nvim_set_current_win(win.id)
	win:setOption("cursorline", true)
	win:setOption("number", false)
	win:setOption("relativenumber", false)
	buf:setOption("filetype", "________not_a_real_file_type_but_other_stuff_causes_errors________")

	clearMappings(mainDialog)
	local scripts = {}
	for f in fs.ls(dir) do
		table.insert(scripts, f)
	end
	mainDialog:setLines(scripts)
	mainDialog:fitTextPadded(2, 2, 50, 10):center()
	if #scripts == 0 then
		z.async(function()
			if quick.yesOrNo("No scripts found, create new script?") then
				currentScript = quick.prompt("Name: ", promptOpts)
				openEditor()
			else
				mainDialog:close()
			end
		end)
		return
	end
	mainDialog:addKeymap("n", "<bs>", function() mainDialog:close() end, {})
	mainDialog:addKeymap("n", "<cr>", function()
		currentScript = mainDialog:getCurrentLine()
		openEditor()
	end, {})
	mainDialog:addKeymap("n", "dd", z.asyncFn(function()
		local file <const> = mainDialog:getCurrentLine()
		if quick.yesOrNo("Delete " .. file .. "?") then
			os.remove(scriptPath(file))
			openBrowser()
		end
	end), { noremap = true })
	mainDialog:addKeymap("n", "o", z.asyncFn(function()
		currentScript = quick.prompt("New Script: ")
		openEditor()
	end), { noremap = true })
end

function scripter.open()
	if mainDialog:win():isValid() then
		mainDialog:focus()
		return
	end
	if currentScript then
		openEditor()
	else
		openBrowser()
	end
end

return setmetatable(scripter, {
	__call = function(_self: scripter, opts: scripter.Opts)
		opts = opts or {}
		if opts.dir then
			dir = opts.dir
		end

		if not fs.exists(dir) then
			fs.mkdirp(dir)
		end

		if opts.open then
			nvim.setKeymap(
				"n", opts.open,
				scripter.open,
				{ noremap = true, silent = true }
			)
		end
	end
})
