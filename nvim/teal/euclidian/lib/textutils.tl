local textutils <const> = {}

function textutils.rightAlign(str: string, wid: integer): string
	assert(wid >= 0)
	return (" "):rep(wid - #str) .. str
end

function textutils.insertFormatted(list: {string}, fmt: string, ...: any)
	table.insert(list, string.format(fmt, ...))
end

function textutils.limit(str: string, len: integer, showTail: boolean): string
	return showTail
		and string.sub(str, -len)
		or string.sub(str, 1, len)
end

return textutils
