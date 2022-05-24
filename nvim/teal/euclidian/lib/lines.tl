local nvim <const> = require("euclidian.lib.nvim")

local function set<T>(t: {T}): {T:boolean}
	local s = {}
	for _, v in ipairs(t) do
		s[v] = true
	end
	return s
end

local record Component
	isFunc: boolean
	funcId: integer
	preEval: boolean
	hiGroup: string
	text: string
	tags: {string:boolean}
	invertedTags: {string:boolean}
end

local record Line
	{Component}

	functions: {function(integer): string}

	_internalId: integer
end

local cache <const>: {Line} = {}
local lines <const> = { Line = Line, Component = Component, _cache = cache }

local lastId = 0

function lines.new(): Line
	local l <const>: Line = setmetatable({ functions = {} }, { __index = Line })
	cache[lastId] = l
	l._internalId = lastId
	lastId = lastId + 1
	return l
end

function Line:add(
	tags: {string},
	invertedTags: {string},
	text: (string | function(integer): string),
	hiGroup: string,
	preEval: boolean
)
	local comp: Component = {
		tags = set(tags),
		invertedTags = set(invertedTags),
		preEval = preEval,
		hiGroup = hiGroup,
	}
	if text is string then
		comp.text = text
	elseif text then
		self.functions[#self + 1] = text
		comp.isFunc = true
		comp.funcId = #self + 1
	end
	table.insert(self, comp)
end

function Line:reify(activeTags: {string:boolean}, param: integer): string
	local buf = {}
	for i, component in ipairs(self) do
		local include = false
		for t in pairs(component.tags) do
			if activeTags[t] then
				include = true
				break
			end
		end
		if include then
			for t in pairs(component.invertedTags) do
				if activeTags[t] then
					include = false
					break
				end
			end
		end
		if include then
			table.insert(buf, "%#".. component.hiGroup .. "#")
			if component.isFunc then
				if component.preEval then
					local ok, res = pcall(self.functions[component.funcId], param)
					if ok then
						table.insert(buf, res)
					else
						table.insert(buf, "???")
					end
				else
					local evalArg = ("require'euclidian.lib.lines'._cache[%d].functions[%d](%s)"):format(
						self._internalId,
						component.funcId,
						param and tostring(param) or ""
					)
					table.insert(
						buf,
						("%%{luaeval(%q)}"):format(evalArg)
					)
				end
			else
				table.insert(buf, component.text)
			end
			if i < #self and not self[i + 1].hiGroup then
				table.insert(buf, "%#Normal#")
			end
		end
	end
	return table.concat(buf)
end

function Line:setLocalStatus(active: {string:boolean}, win: nvim.Window)
	if not win:isValid() then
		return
	end

	win:setOption("statusline", self:reify(active, win.id))
end

function Line:setLocalBar(active: {string:boolean}, win: nvim.Window)
	if not win:isValid() then
		return
	end

	win:setOption("winbar", self:reify(active, win.id))
end

function Line:setTab(active: {string:boolean})
	vim.o.tabline = self:reify(active)
end

return lines
