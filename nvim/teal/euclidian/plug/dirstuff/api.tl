local nvim <const> = require("euclidian.lib.nvim")
local uv <const> = vim.loop

local groupFromId: function(integer): string
local userFromId: function(integer): string

do
	local user_cache: {integer:string} = nil
	local group_cache: {integer:string} = nil

	groupFromId = function(id: integer): string
		if not group_cache then
			group_cache = {}
			for ln in assert(io.lines("/etc/group")) do
				local name, gid = ln:match("([%w-_]+):[^:]*:(%d+)")
				group_cache[tonumber(gid) as integer] = name
			end
		end
		return group_cache[id]
	end

	userFromId = function(id: integer): string
		if not user_cache then
			user_cache = {}
			for ln in assert(io.lines("/etc/passwd")) do
				local name, uid = ln:match("([%w-_]+):[^:]*:(%d+)")
				user_cache[tonumber(uid) as integer] = name
			end
		end
		return user_cache[id]
	end
end

local filetypes <const>: {string:string} = {
	file = "-",
	directory = "d",
	link = "l",
}

local suffixes <const> = { "", "K", "M", "G", "T", "P", "E", "Z", "Y" }
local function humanReadableSize(sz: integer): string
	local l = math.floor(math.log(sz) / math.log(10))
	for i, s in ipairs(suffixes) do
		if l < i * 3 then
			if i == 1 then
				return ("% 4d"):format(sz)
			end
			return ("%.1f" .. s):format(sz / (10 ^ ((i - 1) * 3)))
		end
	end
	return ("%.1e"):format(sz)
end

local record Permissions
	read: boolean
	write: boolean
	execute: boolean
end

local record Stat
	type: string
	groupPermissions: Permissions
	ownerPermissions: Permissions
	otherPermissions: Permissions
	owner: string
	group: string
	size: integer
	nlink: integer
	modificationTime: integer
end

local dir <const> = {
	Stat = Stat,
	Permissions = Permissions,
}

local function convertPermissions(n: integer): Permissions
	return {
		read = (n & 4) > 0,
		write = (n & 2) > 0,
		execute = (n & 1) > 0,
	}
end

local function convertStat(stat: uv.FsStat): Stat
	return {
		type = stat.type,
		size = stat.size,
		groupPermissions = convertPermissions(stat.mode >> 6),
		ownerPermissions = convertPermissions(stat.mode >> 3),
		otherPermissions = convertPermissions(stat.mode),
		owner = userFromId(stat.uid),
		group = groupFromId(stat.gid),
		nlink = stat.nlink,
		modificationTime = stat.mtime.sec,
	}
end

function dir.stat(filename: string): Stat, string
	local stat <const>, err <const> = uv.fs_stat(filename)
	if not stat then return nil, err end
	return convertStat(stat)
end

function dir.lstat(filename: string): Stat, string
	local stat <const>, err <const> = uv.fs_lstat(filename)
	if not stat then return nil, err end
	return convertStat(stat)
end

function dir.permsToString(p: Permissions): string
	return ("%s%s%s"):format(
		p.read and "r" or "-",
		p.write and "w" or "-",
		p.execute and "x" or "-"
	)
end

function dir.statToString(stat: Stat): string
	return ("%s%s%s%s %2d %s %s %s %s"):format(
		filetypes[stat.type] or "?",
		dir.permsToString(stat.ownerPermissions),
		dir.permsToString(stat.groupPermissions),
		dir.permsToString(stat.otherPermissions),
		stat.nlink,
		stat.owner,
		stat.group,
		humanReadableSize(stat.size),
		os.date("%b %2d %R", stat.modificationTime)
	)
end

function dir.statString(filename: string): string, string
	local stat <const>, err <const> = uv.fs_stat(filename)
	if not stat then return nil, err end
	return dir.statToString(convertStat(stat))
end

function dir.lstatString(filename: string): string, string
	local stat <const>, err <const> = uv.fs_lstat(filename)
	if not stat then return nil, err end
	return dir.statToString(convertStat(stat))
end

-- local ns <const> = vim.api.nvim_create_namespace("euclidian.plug.dirstuff")

function dir.ls(dirname: string, buf: nvim.Buffer)
	assert(buf)
	assert(buf:isValid())
	local scanner <const>, err <const> = uv.fs_scandir(dirname)
	if not scanner then
		buf:setLines(0, -1, false, {
			"unable to scandir: " .. tostring(dirname),
			err,
		})
		return
	end
	local dirs <const> = {}
	local files <const> = {}
	for f in uv.fs_scandir_next, scanner do
		local stat = assert(dir.lstat(dirname .. "/" .. f))
		local t = stat.type
		if t == "directory" then
			table.insert(dirs, {f, stat})
		else
			-- TODO: follow symlinks
			table.insert(files, {f, stat})
		end
	end

	local function cmp(a: {string, Stat}, b: {string, Stat}): boolean
		return a[1] < b[1]
	end

	table.sort(dirs, cmp)
	table.sort(files, cmp)

	local stats <const> = {}
	local lines <const> = {}
	local function ins(s: {string, Stat})
		table.insert(stats, s[2])

		table.insert(
			lines,
			("%s %s%s"):format(
				dir.statToString(s[2]),
				s[1],
				s[2].type == "directory" and "/" or ""
			)
		)
	end
	for _, v in ipairs(dirs) do ins(v) end
	for _, v in ipairs(files) do ins(v) end

	buf:setLines(0, -1, false, lines)
	-- vim.api.nvim_set_decoration_provider(ns, {
		-- on_win = function(): boolean
			-- return true
		-- end,
		-- on_line = function(_: any, _win: integer, bufnr: integer, row: integer): boolean
			-- if bufnr ~= buf.id then
				-- return false
			-- end
			-- local stat <const> = stats[row + 1]
			-- buf:setExtmark(ns, row, 0, {
				-- ephemeral = true,
				-- end_line = row,
				-- end_col = 8,
				-- hl_group = "Error",
			-- })
		-- end
	-- })
end

return dir
