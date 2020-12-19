
local Package = require("euclidian.lib.package-manager.Package")

local set <const> = {}

local ti <const>, sf <const> = table.insert, string.format
local function tiFmt(t: {string}, s: string, ...: any)
	ti(t, sf(s, ...))
end

local function generateDef(out: {string}, p: Package.Spec)
	assert(p.id, "Attempt to generate package def without id")
	local leadingSpaces = (" "):rep(#("Package { "))

	local function ins(s: string, ...: any)
		tiFmt(out, leadingSpaces .. s, ...)
	end
	local function commaNewline()
		tiFmt(out, ",\n")
	end

	tiFmt(out, "Package { kind = %q", p.kind) commaNewline()
	ins("id = %d", p.id) commaNewline()

	if p.alias then
		ins("alias = %q", p.alias) commaNewline()
	end
	if p.kind == "git" then
		ins("repo = %q", p.repo)
		if p.branch then
			commaNewline()
			ins("branch = %q", p.branch)
		end
	elseif p.kind == "local" then
		ins("path = %q", p.path)
	end
	commaNewline()

	if p.dependents then
		local d = {}
		for _, dep in ipairs(p.dependents) do
			if dep is Package.Spec then
				table.insert(d, tostring(dep.id))
			end
		end
		if #d > 0 then
			ins("dependents = { %s }", table.concat(d, ", "))
		else
			table.remove(out)
		end
	else
		table.remove(out)
	end

	tiFmt(out, " }\n")
end

function set.serialize(ps: {Package.Spec}): string
	local out = {}
	local pkgs: {number:Package.Spec} = {}
	local generated: {number:boolean} = {}

	local lastId = 0
	local function id(): number
		lastId = lastId + 1
		return lastId
	end

	local function gen(p: Package.Spec)
		if not p.id then
			p.id = id()
			generateDef(out, p)
			pkgs[p.id] = p
		end
	end

	for _, p in ipairs(ps) do
		for _, dep in ipairs(p.dependents or {}) do
			gen(dep as Package.Spec)
		end
		gen(p)
	end

	return table.concat(out)
end

function set.deserialize(str: string): {Package.Spec}
	local packages: {number:Package.Spec} = {}

	local function Package(p: Package.Spec)
		assert(p.id, "Package has no id!")
		packages[p.id] = p
	end

	local chunk = assert(loadstring(str))
	setfenv(chunk, { Package = Package })
	chunk()

	for id, pkg in pairs(packages) do
		pkg.id = nil
		if pkg.dependents then
			for i, depId in ipairs(pkg.dependents) do
				pkg.dependents[i] = packages[depId as number]
			end
		end
	end

	return packages
end

local loadedSets: {string:{Package.Spec}} = {}
local setPath = vim.fn.stdpath("config") as string .. "/sets"
local function loadSet(name: string): {Package.Spec}
	-- TODO: use luv to do the file read
	local fh <const> = assert(io.open(setPath .. "/" .. name, "r"))
	local content <const> = fh:read("*a")
	fh:close()
	return set.deserialize(content)
end

function set.load(name: string): {Package.Spec}
	if not loadedSets[name] then
		loadedSets[name] = loadSet(name)
	end
	return loadedSets[name]
end

function set.save(name: string, s: {Package.Spec})
	assert(name) assert(s)
	local fh <const> = assert(io.open(setPath .. "/" .. name, "w"))
	fh:write(set.serialize(s), "\n")
	fh:close()
end

local map <const> = vim.tbl_map
local glob <const> = vim.fn.glob as function(string, boolean, boolean): {string}

function set.list(): {string}
	return map(function(s: string): string
		return s:sub(#setPath+2, -1)
	end, glob(setPath .. "/*", true, true))
end

return set

