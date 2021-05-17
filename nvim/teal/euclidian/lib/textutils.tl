local textutils <const> = {}

function textutils.rightAlign(str: string, wid: integer): string
	assert(wid >= 0)
	return (" "):rep(wid - #str) .. str
end

function textutils.insertFormatted(list: {string}, fmt: string, ...: any)
	table.insert(list, string.format(fmt, ...))
end

return textutils
