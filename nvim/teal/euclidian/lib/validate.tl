local record Validator
	_checker: function(any): boolean, string
	metamethod __call: function(Validator, any): boolean, string

	metamethod __add: function(Validator, Validator): Validator
end


local validatorMt <const>: metatable<Validator> = {
	__index = Validator,
}

local function new(checker: (function(any): boolean, string)): Validator
	return setmetatable({ _checker = checker } as Validator, validatorMt)
end

function validatorMt.__add(self: Validator, other: Validator): Validator
	local a <const> = self._checker
	local b <const> = other._checker
	return new(function(val: any): boolean, string
		do
			local ok <const>, err <const> = a(val)
			if not ok then
				return false, err
			end
		end
		do
			local ok <const>, err <const> = b(val)
			if not ok then
				return false, err
			end
		end
		return true
	end)
end

function validatorMt.__call(self: Validator, val: any): boolean, string
	return self._checker(val)
end

local validate <const> = {
	Validator = Validator,

	new = new,
}

local typeValidators <const>: {string:Validator} = setmetatable({}, { __mode = "k" })
function validate.type(t: string): Validator
	if not typeValidators[t] then
		typeValidators[t] = new(function(val: any): boolean, string
			if type(val) ~= t then
				return false, "value is not a " .. t
			end
			return true
		end)
	end
	return typeValidators[t]
end

function validate.range(a: number, b: number): Validator
	return validate.type("number") + new(function(val: any): boolean, string
		assert(val is number)
		if not (a <= val as number
			and val as number <= b) then
			return false, ("%s is not within [%f, %f]"):format(tostring(val), a, b)
		end
		return true
	end)
end

return validate
