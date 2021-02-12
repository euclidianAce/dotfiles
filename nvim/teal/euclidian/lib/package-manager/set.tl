
local tree <const> = require("euclidian.lib.package-manager.tree")
local packagespec <const> = require("euclidian.lib.package-manager.packagespec")
local Spec <const> = packagespec.Spec
local uv <const> = vim.loop

local set <const> = {}
local setPath = tree.set

local ti <const>, sf <const> = table.insert, string.format
local function tiFmt(t: {string}, s: string, ...: any)
	ti(t, sf(s, ...))
end

local function generateDef(out: {string}, p: Spec)
	assert(p.id, "Attempt to generate package def without id")
	local leadingSpaces <const> = (" "):rep(#("Package { "))

	local function ins(s: string, ...: any)
		tiFmt(out, leadingSpaces .. s, ...)
		tiFmt(out, ",\n")
	end

	tiFmt(out, "Package { kind = %q,\n", p.kind)
	ins("id = %d", p.id)

	if p.alias then
		ins("alias = %q", p.alias)
	end
	if p.kind == "git" then
		ins("repo = %q", p.repo)
		if p.branch then
			ins("branch = %q", p.branch)
		end
	elseif p.kind == "local" then
		ins("path = %q", p.path)
	end

	if p.dependents then
		local d <const> = {}
		for _, dep in ipairs(p.dependents) do
			if dep is Spec and dep.id then
				table.insert(d, tostring(dep.id))
			end
		end

		if #d > 0 then
			ins("dependents = { %s }", table.concat(d, ", "))
		end
	end

	if p.post then
		ins("post = %q", p.post)
	end

	table.remove(out)
	tiFmt(out, " }\n")
end

function set.serialize(ps: {Spec}): string
	local out <const> = {}
	local pkgs <const>: {number:Spec} = {}

	local lastId = 0
	local function nextId(): number
		lastId = lastId + 1
		return lastId
	end

	local function gen(p: Spec)
		if not p.id then
			p.id = nextId()
			generateDef(out, p)
			pkgs[p.id] = p
		end
	end

	for _, p in ipairs(ps) do
		for _, dep in ipairs(p.dependents or {}) do
			gen(dep as Spec)
		end
		gen(p)
	end

	table.insert(out, "\n-- vim: ft=teal")

	return table.concat(out)
end

function set.deserialize(str: string): {Spec}
	local packages <const>: {number:Spec} = {}

	local largestId = -1
	local function Package(p: Spec)
		assert(p.id, "Package has no id!")
		packages[p.id] = packagespec.new(p)
		if p.id > largestId then
			largestId = p.id
		end
	end

	local chunk <const> = assert(loadstring(str))
	setfenv(chunk, { Package = Package } as table)
	-- Should I be pcalling this? Yes. Am I? No.
	chunk()

	for _, pkg in pairs(packages) do
		pkg.id = nil
		if pkg.dependents then
			for i, depId in ipairs(pkg.dependents) do
				pkg.dependents[i] = packages[depId as number]
			end
		end
	end

	-- Guarantee that packages has no holes
	for i = largestId, 1, -1 do
		if packages[i] == nil then
			table.remove(packages, i)
		end
	end

	return packages
end

-- TODO: use luv to do the file reads/writes

local function loadSet(name: string): {Spec}
	local fh <const> = assert(io.open(setPath .. "/" .. name, "r"))
	local content <const> = fh:read("*a")
	fh:close()
	return set.deserialize(content)
end

local loadedSets <const>: {string:{Spec}} = {}
function set.load(name: string): {Spec}
	if not loadedSets[name] then
		loadedSets[name] = loadSet(name)
	end
	return loadedSets[name]
end

function set.save(name: string, s: {Spec})
	assert(name, "Can't save a set without a name") assert(s, "No set to save")
	local fh <const> = assert(io.open(setPath .. "/" .. name, "w"))
	fh:write(set.serialize(s), "\n")
	fh:close()
	loadedSets[name] = nil
end

function set.list(): {string}
	local list: {string} = {}
	local dir = uv.fs_scandir(setPath)
	for name in uv.fs_scandir_next, dir do
		table.insert(list, name)
	end
	return list
end

return set

