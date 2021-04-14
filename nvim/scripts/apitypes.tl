local log <const> = require("cyan.log")
local fs <const> = require("cyan.fs")

local function runCmd(cmd: string, readArg: string): string
	local p <const> = assert(io.popen(cmd))
	local res <const> = p:read(readArg or "*a")
	p:close()
	return res
end

local function exec()
	local src <const> = fs.path.new("scripts/nvimgen.tl")
	local target <const> = fs.path.new("scripts/nvimgen.lua")
	local scriptUpdated <const> = src:mod_time() > (target:mod_time() or -1)
	if scriptUpdated then
		log.warn(src:tostring(), " is newer than ", target:tostring(), ". Attempting to update...")
		if not os.execute(("cyan gen %s -o %s"):format(src:to_real_path(), target:to_real_path())) then
			log.err("Failed to update nvimgen script")
			return
		end
	end

	local last <const> = fs.read(".last_nvim_commit")

	local current <const> = runCmd("nvim --version", "*l")
	if last and not scriptUpdated then
		if current == last then
			log.info("Neovim api definitions up to date")
			return
		end
		log.info("Neovim api definitions not up to date:\n",
			"      last: ", tostring(last), "\n",
			"   current: ", current)
	end

	if not scriptUpdated then
		log.info("Neovim api definitions not up to date:\n",
			"      last: ", last or "(none)", "\n",
			"   current: ", current
		)
	end

	runCmd("nvim --headless -u NORC '+luafile scripts/nvimgen.lua' '+q'")

	local f = io.open(".last_nvim_commit", "w")
	f:write(current)
	f:close()

	log.info("Updated Neovim api type definitions for commit: ", current)
end

return {
	run_on = { "build:pre" },
	exec = exec,
}
