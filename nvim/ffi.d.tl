
local record ffi
	cdef: function(string)
	C: {string:function}
	new: function(string, number): any
end

return ffi

