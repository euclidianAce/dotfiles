local log <const> = require("cyan.log")
local fs <const> = require("cyan.fs")
local cs <const> = require("cyan.colorstring")
local ansi <const> = require("cyan.ansi")

local logCmd <const> = log.create_logger(
	io.stdout,
	cs.highlight({ansi.color.dark.green}, "Cmd Out")
)

local logCmdCont <const> = log.create_logger(
	io.stdout,
	cs.highlight({ansi.color.dark.green}, "...")
)

local info <const> = log.create_logger(
	io.stdout,
	cs.highlight({ansi.color.bright.blue}, "Nvim Gen"),
	cs.highlight({ansi.color.bright.blue}, "...")
)

local function runCmd(cmd: string, max_log_lines: integer): {string}
	max_log_lines = max_log_lines or math.huge as integer
	info("Running command ", cs.highlight({ansi.color.dark.magenta}, cmd))
	local p <const> = assert(io.popen(cmd))
	local res <const>: {string} = {}
	local ln = p:read("*l")
	while ln do
		if #res < max_log_lines then
			if res[1] then
				logCmdCont(ln)
			else
				logCmd(ln)
			end
		end
		table.insert(res, ln)
		ln = p:read("*l")
	end
	p:close()
	return res
end

local nvim_cmd <const> = "/usr/local/bin/nvim"
local src <const>, target <const> = fs.path.new("scripts/nvimgen.tl"), fs.path.new("scripts/nvimgen.lua")
local scriptUpdated <const> = src:mod_time() > (target:mod_time() or -1)
if scriptUpdated then
	log.warn(src:tostring(), " is newer than ", target:tostring(), ". Attempting to update...")
	if not os.execute(("cyan gen %s -o %s"):format(src:to_real_path(), target:to_real_path())) then
		log.err("Failed to update nvimgen script")
		return
	end
end

local last <const> = fs.read(".last_nvim_commit")

local current <const> = runCmd(("%s --version"):format(nvim_cmd), 2)[1]
if not scriptUpdated then
	if last then
		if current == last then
			info("Neovim api definitions up to date")
			return
		end
		info(
			"Neovim api definitions not up to date:\n",
			"      last: ", tostring(last), "\n",
			"   current: ", current
		)
	else
		info(
			"Neovim api definitions not up to date:\n",
			"      last: ", last or "(none)", "\n",
			"   current: ", current
		)
	end
end

runCmd(("%s --headless -u NORC '+luafile scripts/nvimgen.lua' '+q'"):format(nvim_cmd))

local f = io.open(".last_nvim_commit", "w")
f:write(current)
f:close()

info("Updated Neovim api type definitions for commit: ", current)
