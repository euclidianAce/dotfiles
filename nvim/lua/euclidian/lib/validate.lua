local Validator = {}







local validatorMt = {
   __index = Validator,
}

local function new(checker)
   return setmetatable({ _checker = checker }, validatorMt)
end

function validatorMt.__add(self, other)
   local a = self._checker
   local b = other._checker
   return new(function(val)
      do
         local ok, err = a(val)
         if not ok then
            return false, err
         end
      end
      do
         local ok, err = b(val)
         if not ok then
            return false, err
         end
      end
      return true
   end)
end

function validatorMt.__call(self, val)
   return self._checker(val)
end

local validate = {
   Validator = Validator,

   new = new,
}

local typeValidators = setmetatable({}, { __mode = "k" })
function validate.type(t)
   if not typeValidators[t] then
      typeValidators[t] = new(function(val)
         if type(val) ~= t then
            return false, "value is not a " .. t
         end
         return true
      end)
   end
   return typeValidators[t]
end

function validate.range(a, b)
   return validate.type("number") + new(function(val)
      assert(type(val) == "number")
      if not (a <= val and
         val <= b) then
         return false, ("%s is not within [%f, %f]"):format(tostring(val), a, b)
      end
      return true
   end)
end

return validate