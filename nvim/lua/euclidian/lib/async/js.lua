local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table




local State = {}





local Promise = {}


local function weak(t)
   return setmetatable(t, { __mode = "k" })
end




local states = weak({})
local values = weak({})
local thens = weak({})



local propagateThens
local propagateElses

local function onFulfilled(p, val)
   if states[p] == "pending" then
      states[p] = "fulfilled"
      values[p] = val
      propagateThens(p)
   end
end

local function onRejected(p, val)
   if states[p] == "pending" then
      states[p] = "rejected"
      values[p] = val
      propagateElses(p)
   end
end

local function new(fn)
   local p = setmetatable({}, { __index = Promise })
   states[p] = "pending"
   thens[p] = {}

   if fn then
      vim.schedule(function()
         fn(
         function(val)
            onFulfilled(p, val)
         end,
         function(val)
            onRejected(p, val)
         end)

      end)
   end

   return p
end

local uv = vim.loop


local function newThreaded(fn, ...)
   local p = setmetatable({}, { __index = Promise })
   states[p] = "pending"
   thens[p] = {}
   local args = table.pack(...)
   if fn then
      local res, rej
      res = uv.new_async(function(val)
         onFulfilled(p, val)
         res:close()
      end)
      rej = uv.new_async(function(val)
         onRejected(p, val)
         res:close()
      end)

      uv.new_thread(
      function(sfunc, resAsync, rejAsync, ...)
         local func = loadstring(sfunc)
         func(
         function(val)
            resAsync:send(val)
         end,
         function(val)
            rejAsync:send(val)
         end,
         ...)

      end,
      string.dump(fn),
      res, rej,
      unpack(args))

   end

   return p
end

function Promise.andThen(self, thenFn, elseFn)
   local p = new()
   local s = states[self]

   table.insert(thens[self], { p, thenFn, elseFn })

   if s == "fulfilled" then
      propagateThens(self)
   elseif s == "rejected" then
      propagateElses(self)
   end

   return p
end

function Promise.orElse(self, elseFn)
   return self:andThen(nil, elseFn)
end

local function isPromise(t)
   local mt = getmetatable(t)
   return mt and mt.__index == Promise
end

propagateThens = function(p)
   for _, t in ipairs(thens[p]) do
      local controlledPromise = t[1]
      local fn = t[2]

      if fn then
         local valOrPromise = fn(values[p])
         if isPromise(valOrPromise) then
            (valOrPromise):andThen(
            function(val) onFulfilled(controlledPromise, val) end,
            function(val) onRejected(controlledPromise, val) end)

         else
            onFulfilled(controlledPromise, valOrPromise)
         end
      else
         onFulfilled(controlledPromise, values[p])
      end
   end
   thens[p] = {}
end

propagateElses = function(p)
   for _, t in ipairs(thens[p]) do
      local controlledPromise = t[1]
      local catchFn = t[3]

      if catchFn then
         local valOrPromise = catchFn(values[p])
         if isPromise(valOrPromise) then
            (valOrPromise):andThen(
            function(val) onFulfilled(controlledPromise, val) end,
            function(val) onRejected(controlledPromise, val) end)

         else
            onFulfilled(controlledPromise, valOrPromise)
         end
      else
         onFulfilled(controlledPromise, values[p])
      end
   end
end


local ts = weak({})
local function async(fn)
   return function()
      local co = coroutine.create(fn)
      ts[co] = true
      local function resume(...)
         return coroutine.resume(co, ...)
      end

      local function asyncStuff(ok, val)
         if not ok then
            error(val)
         end
         if coroutine.status(co) == "dead" then
            return val
         end
         if isPromise(val) then
            local res = function(v) asyncStuff(resume(v)) end;
            (val):andThen(res, res)
         else
            return asyncStuff(resume(val))
         end
      end

      return new(function(res)
         res(asyncStuff(resume()))
         ts[co] = false
      end)
   end
end


local function await(val)
   local t = coroutine.running()
   if ts[t] then
      if type(val) == "function" then
         return coroutine.yield(val())
      else
         return coroutine.yield(val)
      end
   else
      if type(val) == "function" then
         return val()
      else
         while states[val] == "pending" do
            vim.wait(10)
         end
         return values[val]
      end
   end
end

return {
   a = {
      wait = await,
      sync = async,
   },

   promise = {
      new = new,
      newThreaded = newThreaded,
      resolve = function(val)
         local p = setmetatable({}, { __index = Promise })
         states[p] = "fulfilled"
         values[p] = val
         thens[p] = {}
         return p
      end,
      reject = function(val)
         local p = setmetatable({}, { __index = Promise })
         states[p] = "rejected"
         values[p] = val
         thens[p] = {}
         return p
      end,
   },

   Promise = Promise,
   State = State,
}