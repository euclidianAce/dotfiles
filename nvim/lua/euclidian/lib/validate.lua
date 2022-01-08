local Validator = {}















local validatorMt = {
   __index = Validator,
}

local function new(checker, desc)
   return setmetatable({ checker = assert(checker), desc = assert(desc) }, validatorMt)
end

local validate = {
   Validator = Validator,

   new = new,
   inspector = tostring,

   toNumber = new(
   function(val)
      return tonumber(val) ~= nil
   end,
   "be convertible to a number"),

}

local function inspect(value)
   return ((validate.inspector or tostring)(value))
end


function validatorMt.__add(self, other)
   local a = self.checker
   local b = other.checker
   return new(
   function(val)
      return a(val) or b(val)
   end,
   self.desc .. " or " .. other.desc)

end



function validatorMt.__sub(self, other)
   local a = self.checker
   local b = other.checker
   return new(
   function(val)
      return a(val) or not b(val)
   end,
   self.desc .. " or not " .. other.desc)

end


function validatorMt.__mul(self, other)
   local a = self.checker
   local b = other.checker
   return new(
   function(val)
      return a(val) and b(val)
   end,
   self.desc .. " and " .. other.desc)

end


function validatorMt.__div(self, other)
   local a = self.checker
   local b = other.checker
   return new(
   function(val)
      return a(val) and not b(val)
   end,
   self.desc .. " and not " .. other.desc)

end


function validatorMt.__unm(self)
   local a = self.checker
   return new(
   function(val)
      return not a(val)
   end,
   "not " .. self.desc)

end

function validatorMt.__call(self, val)
   local ok = self.checker(val)
   if not ok then
      return false, ("expected <%s> to %s"):format(inspect(val), self.desc)
   end
   return true
end

local typeValidators = setmetatable({}, { __mode = "k" })
function validate.type(t)
   if not typeValidators[t] then
      typeValidators[t] = new(
      function(val)
         return type(val) == t
      end,
      "be of type " .. t)

   end
   return typeValidators[t]
end

function validate.range(a, b, fmt)
   fmt = fmt or "%f"
   return validate.type("number") *
   new(
   function(val)
      assert(type(val) == "number")
      return (a <= val and
      val <= b)
   end,
   ("be within [" .. fmt .. ", " .. fmt .. "]"):format(a, b))

end

function validate.hasKey(name, maybe_validator)
   local val_cond = maybe_validator and maybe_validator.checker
   local desc = "have key " .. name
   if maybe_validator then
      desc = desc .. " and that key to " .. maybe_validator.desc
   end
   return new(
   function(val)
      local ok, res = pcall(function()
         return (val)[name]
      end)
      if not ok or rawequal(res, nil) then
         return false
      end
      if val_cond then
         return val_cond(res)
      end
      return true
   end,
   desc)

end

return validate