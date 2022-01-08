local record Validator
	-- description to generate error messages
	-- errors are generated with the given format string
	--    ("expected %s to %s"):format(inspector(value), desc)
	desc: string
	checker: function(any): boolean

	metamethod __call: function(Validator, any): boolean, string

	metamethod __add: function(Validator, Validator): Validator
	metamethod __sub: function(Validator, Validator): Validator
	metamethod __mul: function(Validator, Validator): Validator
	metamethod __div: function(Validator, Validator): Validator
	metamethod __unm: function(Validator): Validator
end

local validatorMt <const>: metatable<Validator> = {
	__index = Validator,
}

local function new(checker: (function(any): boolean), desc: string): Validator
	return setmetatable({ checker = assert(checker), desc = assert(desc) } as Validator, validatorMt)
end

local validate <const> = {
	Validator = Validator,

	new = new,
	inspector: function(any): string = tostring,

	toNumber: Validator = new(
		function(val: any): boolean
			return tonumber(val) ~= nil
		end,
		"be convertible to a number"
	)
}

local function inspect(value: any): string
	return ((validate.inspector or tostring)(value))
end

-- Either a or b
function validatorMt.__add(self: Validator, other: Validator): Validator
	local a <const> = self.checker
	local b <const> = other.checker
	return new(
		function(val: any): boolean
			return a(val) or b(val)
		end,
		self.desc .. " or " .. other.desc
	)
end

-- a or not b
-- same as a + (-b)
function validatorMt.__sub(self: Validator, other: Validator): Validator
	local a <const> = self.checker
	local b <const> = other.checker
	return new(
		function(val: any): boolean
			return a(val) or not b(val)
		end,
		self.desc .. " or not " .. other.desc
	)
end

-- a and b
function validatorMt.__mul(self: Validator, other: Validator): Validator
	local a <const> = self.checker
	local b <const> = other.checker
	return new(
		function(val: any): boolean
			return a(val) and b(val)
		end,
		self.desc .. " and " .. other.desc
	)
end

-- a and not b
function validatorMt.__div(self: Validator, other: Validator): Validator
	local a <const> = self.checker
	local b <const> = other.checker
	return new(
		function(val: any): boolean
			return a(val) and not b(val)
		end,
		self.desc .. " and not " .. other.desc
	)
end

-- not a
function validatorMt.__unm(self: Validator): Validator
	local a <const> = self.checker
	return new(
		function(val: any): boolean
			return not a(val)
		end,
		"not " .. self.desc
	)
end

function validatorMt.__call(self: Validator, val: any): boolean, string
	local ok <const> = self.checker(val)
	if not ok then
		return false, ("expected <%s> to %s"):format(inspect(val), self.desc)
	end
	return true
end

local typeValidators <const>: {string:Validator} = setmetatable({}, { __mode = "k" })
function validate.type(t: string): Validator
	if not typeValidators[t] then
		typeValidators[t] = new(
			function(val: any): boolean
				return type(val) == t
			end,
			"be of type " .. t
		)
	end
	return typeValidators[t]
end

function validate.range(a: number, b: number, fmt: string): Validator
	fmt = fmt or "%f"
	return validate.type("number")
		* new(
			function(val: any): boolean, string
				assert(val is number)
				return (a <= val as number
					and val as number <= b)
			end,
			("be within [" .. fmt .. ", " .. fmt .. "]"):format(a, b)
		)
end

function validate.hasKey(name: string, maybe_validator: Validator): Validator
	local val_cond <const> = maybe_validator and maybe_validator.checker
	local desc = "have key " .. name
	if maybe_validator then
		desc = desc .. " and that key to " .. maybe_validator.desc
	end
	return new(
		function(val: any): boolean
			local ok <const>, res <const> = pcall(function(): any
				return (val as table)[name]
			end)
			if not ok or rawequal(res, nil) then
				return false
			end
			if val_cond then
				return val_cond(res)
			end
			return true
		end,
		desc
	)
end

return validate
