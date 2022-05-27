local command <const> = require("euclidian.lib.command")
-- local floatterm <const> = require("euclidian.plug.floatterm.api")
local nvim <const> = require("euclidian.lib.nvim")
local lines <const> = require("euclidian.lib.lines")
local tu <const> = require("euclidian.lib.textutils")

local modeMap <const>: {string:{string, string}} = {
	["n"]  = { " Normal ",     "STLNormal" },
	["i"]  = { " Insert ",     "STLInsert" },
	["r"]  = { " Confirm ",    "STLCommand" },
	["R"]  = { " Replace ",    "STLReplace" },
	["v"]  = { " Visual ",     "STLVisual" },
	["V"]  = { " V·Line ",     "STLVisual" },
	[""] = { " V·Block ",    "STLVisual" },
	["c"]  = { " Command ",    "STLCommand" },
	["s"]  = { " Select ",     "STLVisual" },
	["S"]  = { " S·Line ",     "STLVisual" },
	[""] = { " S·Block ",    "STLVisual" },
	["nt"] = { " N·Terminal ", "STLNormal" },
	["t"]  = { " I·Terminal ", "STLTerminal" },
	["!"]  = { " Shell ",      "Comment" },
}

local function getModeText(): string
	local m <const> = nvim.api.getMode().mode as string
	local found = modeMap[m]
		or modeMap[m:sub(1, 1)]
		or { " ??? ", "Error" }
	nvim.api.setHl(0, "STLModeText", { link = found[2] })
	return found[1]
end

local alwaysActive <const> = {"Active", "Inactive"}
local active <const> = {"Active"}
local inactive <const> = {"Inactive"}
local empty <const> = {}

local status <const> = lines.new()

local currentTags <const>: {string:boolean} = {}
local updateAll <const> = vim.schedule_wrap(function()
	local currentWinId <const> = nvim.api.getCurrentWin()
	local tags <const> = {}
	for k, v in pairs(currentTags) do
		tags[k] = v
	end
	for _, winid in ipairs(nvim.api.listWins()) do
		local win <const> = nvim.Window(winid)
		if win:isValid() then
			tags.Active = currentWinId == winid
			tags.Inactive = currentWinId ~= winid
			-- neat idea, but looks crappy, make a specific bar for terminals
			-- local ft <const> = floatterm.fromWindow(win)
			-- if ft then
				-- status:setLocalBar(tags, win)
			-- else
			status:setLocalStatus(tags, win)
			-- end
		end
	end
end)

status:add(
	alwaysActive, empty,
	function(winid: integer): string
		local win <const>, buf <const> = nvim.winBuf(winid)
		-- make buffer number section line up with line number column
		local nu <const> = win:getOption("number")
		local rnu <const> = win:getOption("relativenumber")
		local scl <const> = win:getOption("signcolumn"):match("yes:(%d+)")

		if not (nu or rnu or scl as boolean) then
			return (" % 4d "):format(buf.id)
		end

		local spaces <const> = ((nu or rnu) and win:getOption("numberwidth") or 0)
			+ (tonumber(scl) as integer or 0)
		if spaces < 3 then
			return (" % 4d "):format(buf.id)
		end
		return tu.rightAlign(tostring(buf.id), spaces) .. " "
	end,
	"STLBufferInfo", true
)

status:add(active, inactive, getModeText, "STLModeText")

-- {{{ Teehee funi speeeen
-- do
	-- local idx = 1
	-- local loop <const> = {
		-- "⠏ ", "⠋ ",
		-- "⠙ ", "⠹ ",
		-- "⠸ ", "⠼ ",
		-- "⠴ ", "⠦ ",
		-- "⠧ ", "⠇ ",
	-- }

	-- status:add(active, inactive, function(): string
		-- return loop[idx]
	-- end, "STLModeText")

	-- local uv = vim.loop
	-- local t = uv.new_timer()
	-- t:start(100, 75, vim.schedule_wrap(function()
		-- idx = idx + 1
		-- if idx > #loop then
			-- idx = 1
		-- end
		-- updateAll()
	-- end))
-- end
-- }}}
-- git stuffs {{{
local gitActive <const>, gitInactive <const> = {"Git"}, {"Inactive"}
local maxBranchWid <const> = 20
local currentBranch = ""

local function parseDiff(s: string): string, string, string
	-- ex: 1 file changed, 1 insertion(+)
	-- ex: 5 files changed, 98 insertions(+), 45 deletions(-)
	return s:match("(%d+) file"), s:match("(%d+) insert"), s:match("(%d+) delet")
end

local filesChanged, insertions, deletions: string, string, string
local function updateGitStatusline()
	local b = nvim.Buffer()
	if b:getOption("buftype") == "nofile" then
		return
	end
	local function oneshot<T...>(fn: function(T)): function(T)
		local execd = false
		return function(...: T)
			if not execd then
				fn(...)
				execd = true
			end
		end
	end
	do
		local gotDiff = false
		command.spawn{
			command = { "git", "diff", "--shortstat" },
			cwd = vim.loop.cwd(),
			onStdoutLine = oneshot(function(ln: string)
				gotDiff = true
				filesChanged, insertions, deletions = parseDiff(ln)
				updateAll()
			end),
			onExit = function()
				if not gotDiff then
					filesChanged, insertions, deletions = nil, nil, nil
					updateAll()
				end
			end,
		}
	end
	command.spawn{
		command = { "git", "branch", "--show-current" },
		cwd = vim.loop.cwd(),
		onStdoutLine = oneshot(function(ln: string)
			currentBranch = ln
			updateAll()
		end),
	}
end
nvim.api.createAutocmd("BufWritePost", { pattern = "*", callback = updateGitStatusline })

status:add(gitActive, gitInactive, function(): string
	if currentBranch == "" then return "" end
	return " " .. currentBranch:sub(1, maxBranchWid)
end, "STLGit", true)
status:add(gitActive, gitInactive, function(): string
	if currentBranch == "" then return "" end
	return (" %s %s+ %s- "):format(filesChanged or "0", insertions or "0", deletions or "0")
end, "STLGit", true)

currentTags.Git = true
vim.keymap.set("n", "<F12>", function()
	currentTags.Git = not currentTags.Git
	updateAll()
end, {})
-- }}}

status:add(alwaysActive, empty, function(winid: integer): string
	local buf <const> = nvim.Buffer(nvim.Window(winid):getBuf())
	if buf:getOption("buftype") == "terminal" then
		return ""
	end
	return " %f %m%r%h%w"
end, "STLFname", true)

status:add(active, inactive, " %= 🌌🐢🌌 %= ", "StatusLine")
status:add(inactive, active, " %= ", "StatusLineNC")

local insFmt <const> = tu.insertFormatted
local minWid <const> = 100
status:add(active, inactive, function(winid: integer): string
	local win <const>, buf <const> = nvim.winBuf(winid)

	local wid <const> = win:getWidth()
	local line <const>, col <const> = unpack(win:getCursor())

	local out <const>: {string} = {}

	local isShort = wid < minWid

	-- tabs/spaces info
	local expandtab <const> = buf:getOption("expandtab")
	local num <const> = expandtab
		and buf:getOption("shiftwidth")
		or buf:getOption("tabstop")
	insFmt(
		out, "%s(%d)",
		(expandtab
			and "spaces "
			or "tabs "):sub(1, isShort and 1 or -1),
		num
	)

	-- line info
	local totalLines <const> = #buf:getLines(0, -1, false)
	if not isShort then
		insFmt(out, "Ln: %3d of %3d", line, totalLines)
		insFmt(out, "Col: %3d", col + 1)
		insFmt(out, "%3d%%", line / totalLines * 100)
	else
		insFmt(out, "%d,%d", line, col + 1)
	end

	if #out > 1 then
		return "  " .. table.concat(out, isShort and " " or " │ ") .. "  "
	else
		return "  " .. out[1] .. "  "
	end
end, "STLBufferInfo")

status:add(inactive, active, function(winid: integer): string
	return ("  Ln: %3d  "):format(nvim.Window(winid):getCursor()[1])
end, "STLBufferInfo")

vim.schedule(function()
	updateGitStatusline()
	updateAll()
end)

local group <const> = nvim.createAugroup("Statusline")
group:add({ "WinEnter", "BufWinEnter" }, { callback = function() updateAll() end })
