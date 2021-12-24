local common <const> = require("cyan.tlcommon")
local config <const> = require("cyan.config")
local fs <const> = require("cyan.fs")
local log <const> = require("cyan.log")

local out_name <const> = ... or "out.lua"

local dots <const> = fs.path.new(assert(os.getenv("DOTFILE_DIR"))) .. "nvim"
assert(dots:exists() and dots:is_directory())
fs.chdir(dots)

local loaded_config <const>, errs <const> = config.load()
if not loaded_config then
	log.err(table.concat(errs or {}, "\n"))
	return 1
end
local env <const> = assert(common.init_env_from_config(loaded_config))

local function module_name(p: fs.Path): string
	local copy = p:copy()
	copy[#copy] = copy[#copy]:gsub("%.tl$", "")
	if copy[#copy] == "init" then
		table.remove(copy)
	end
	return table.concat(copy, ".")
end

local to_write <const>: {{string, string}} = {}
for p in fs.scan_dir(".", {"teal/**/*"}, {"teal/types/**/*"}) do
	local path <const> = p:to_real_path()
	local parsed <const> = assert(common.parse_file(path))
	if #parsed.errs > 0 then
		common.report_errors(log.err, parsed.errs, path, "syntax error")
	end

	local result <const> = common.type_check_ast(parsed.ast, {
		filename = path,
		gen_target = loaded_config.gen_target,
		gen_compat = loaded_config.gen_compat,
		env = env,
	})
	if not common.report_result(result, loaded_config) then
		return 1
	end
	log.info("Processed ", path)
	table.insert(to_write, {module_name(p), common.compile_ast(parsed.ast)})
end

table.sort(
	to_write,
	function(a: {string, string}, b: {string, string}): boolean
		return a[1] < b[1]
	end
)

local fh = assert(io.open(out_name, "w"))
for _, to in ipairs(to_write) do
	fh:write(("package.preload[%q] = function(...)\n"):format(to[1]))
	fh:write(to[2], "\n")
	fh:write("end\n")
end
local main <const> = assert(io.open("init.lua", "r"))
fh:write(main:read("*a"))
main:close()
fh:close()
log.info("Wrote ", out_name)
