local color <const> = require("euclidian.lib.color")
local Color <const> = color.Color
local ColorName <const> = color.ColorName
local Gradient <const> = color.Gradient
local Palette <const> = color.Palette

local p <const>: {ColorName:Gradient} = {
	bg      = { 0x16131F, 0x181520, 0x2B2735 },
	fg      = { 0x817998, 0xD8CEE4, 0xEFEFEF },
	blue    = { 0x395081, 0x799AE0, 0xAAC3FD },
	gray    = { 0x332F3C, 0x464252, 0x817998 },
	green   = { 0x32754B, 0x53B67E, 0x7BCE8F },
	orange  = { 0xC88B43, 0xE8AB73, 0xFFC590 },
	purple  = { 0x6554A0, 0x9876D9, 0xC7B1F2 },
	red     = { 0x77405F, 0xD16161, 0xE69090 },
	yellow  = { 0xB5AA60, 0xD5C876, 0xF0E7AC },
	cyan    = { 0x387072, 0x429DA0, 0x70C3C6 },
	magenta = { 0x8A294D, 0xC24472, 0xEF6194 },
}

local function extract(grads: {ColorName:Gradient}, idx: integer): Palette
	local res <const> = {}
	for k, v in pairs(grads) do
		res[k] = v[idx]
	end
	return res
end

local dark <const> = extract(p, 1)
local normal <const> = extract(p, 2)
local bright <const> = extract(p, 3)

local hi <const> = color.scheme.hi

local min <const>, max <const> = math.min, math.max
local function clamp<T>(n: T, a: number, b: number): T
	return min(max(n, a), b) as T
end

local darkenFactor <const> = 128
local function invert(fgColor: integer): Color
	local r <const>, g <const>, b <const> = color.hexToRgb(fgColor)
	return {
		color.rgbToHex(
			r - clamp(darkenFactor, r * 0.16, r * 0.90),
			g - clamp(darkenFactor, g * 0.16, g * 0.90),
			b - clamp(darkenFactor, b * 0.16, b * 0.90)
		),
		fgColor
	}
end

local function applyHighlights(
	primary: ColorName,
	secondary: ColorName,
	primaryComplement: ColorName,
	secondaryComplement: ColorName
)
	vim.g.colors_name = "euclidian"
	primary = primary or "fg"
	primaryComplement = primaryComplement or primary
	secondary = secondary or primary
	secondaryComplement = secondaryComplement or secondary

	hi.Normal                  = { normal.fg, normal.bg }
	hi.Visual                  = { -1, dark.gray }
	hi.ErrorMsg                = { nil, normal.red }
	hi.Question                = { dark.green }
	hi.Search                  = { dark[secondary], -1, "bold,reverse" }
	hi.IncSearch               = { bright[secondary], nil, "bold,underline,reverse" }

	hi.StatusLine              = invert(dark[secondary])
	hi.StatusLineNC            = invert(normal.gray)

	hi.VertSplit               = { nil, normal.gray }
	hi.TabLine                 = { dark[secondary], normal.gray }
	hi.TabLineSel              = { normal[secondary], normal.gray }
	hi.TabLineFill             = { nil, dark.gray }
	hi.Title                   = { dark[secondary] }

	hi.FloatBorder             = { dark.fg, bright.bg }

	hi.Pmenu                   = { normal.fg, bright.bg }
	hi.PmenuSel                = { nil,  normal.gray }
	hi.PmenuSbar               = { nil,  bright.gray }
	hi.PmenuThumb              = { nil,  normal.gray }

	hi.CursorLine              = { nil, bright.bg }
	hi.CursorColumn            = { nil, bright.bg }
	hi.LineNr                  = { normal.gray, dark.bg }
	hi.CursorLineNr            = { nil, dark.bg }

	hi.Folded                  = { dark[secondary], bright.bg, "bold" }
	hi.FoldColumn              = { dark[secondary], dark.bg, "bold" }
	hi.SignColumn              = { bright.bg, dark.bg }
	hi.NonText                 = { bright.bg }
	hi.MatchParen              = { normal[secondary], dark[secondary], "bold" }

	hi.Comment                 = { dark[secondary], nil, "italic" }
	hi.Constant                = { normal[secondary] }

	hi.Identifier              = { normal.fg }
	hi.Function                = { bright[primary], nil, "bold" }

	hi.Statement               = { normal[primary] }
	hi.Operator                = { normal[primaryComplement] }

	hi.Type                    = { bright[primaryComplement] }
	hi.Structure               = { dark[primaryComplement] }
	hi.StorageClass            = { bright[primaryComplement], nil, "bold" }

	hi.Special                 = { bright[secondary] }
	hi.Delimiter               = { dark[primary], -1 }

	hi.PreProc                 = { bright[secondary] }

	hi.Todo                    = { bright[secondary], nil, "bold" }
	hi.Error                   = { nil, dark.red, "bold" }

	hi.Underlined              = { nil, nil, "underline" }

	hi.TSConstructor           = {  }
	hi.TSParameter             = { bright[secondaryComplement] }
	hi.TSParameterReference    = { bright[secondaryComplement] }
	hi.TSAttribute             = { bright[primaryComplement] }
	hi.TSConstBuiltin          = { normal[secondary] }

	hi.String                  = hi.Constant
	hi.Character               = hi.Constant
	hi.Number                  = hi.Constant
	hi.Boolean                 = hi.Constant
	hi.Float                   = hi.Constant

	hi.Conditional             = hi.Statement
	hi.Repeat                  = hi.Statement
	hi.Label                   = hi.Statement
	hi.Keyword                 = hi.Statement
	hi.Exception               = hi.Statement

	hi.Typedef                 = hi.Type

	hi.SpecialComment          = hi.Special
	hi.SpecialChar             = hi.Special
	hi.SpecialKey              = hi.Special
	hi.Tag                     = hi.Special
	hi.Debug                   = hi.Special

	hi.PreCondit               = hi.PreProc
	hi.Include                 = hi.PreProc
	hi.Define                  = hi.PreProc
	hi.Macro                   = hi.PreProc

	hi.Directory               = { normal[primary] }
	hi.WarningMsg              = { nil, normal.red }
	hi.WildMenu                = { normal.bg, normal.yellow }

	-- Diagnostics
	hi.DiagnosticError   = { bright.red }
	hi.DiagnosticHint    = { bright.fg }
	hi.DiagnosticInfo    = { bright.gray }
	hi.DiagnosticWarning = { bright.orange }

	-- Git stuffs
	hi.DiffAdd                     = { dark.green }
	hi.DiffDelete                  = { dark.red }
	hi.NeogitDiffAddHighlight      = { normal.green }
	hi.NeogitDiffDeleteHighlight   = { normal.red }
	hi.NeogitDiffContextHighlight  = { normal.blue, dark.bg }
	hi.NeogitHunkHeader            = { bright.gray, dark.gray }
	hi.NeogitHunkHeaderHighlight   = { bright.gray, normal.gray }

	-- Custom Statusline Groups
	hi.STLBufferInfo           = invert(dark[secondary])
	hi.STLGit                  = invert(normal.green)
	hi.STLFname                = invert(bright.gray)

	hi.STLNormal               = invert(normal[primary])
	hi.STLInsert               = invert(normal[primaryComplement])
	hi.STLCommand              = invert(normal[secondary])
	hi.STLVisual               = invert(normal[secondaryComplement])

	hi.STLReplace              = invert(normal.red)
	hi.STLTerminal             = invert(normal.orange)

	hi.TrailingWhitespace      = { dark[secondary], dark[secondary] }

	local function hex(col: integer): string
		return ("#%06X"):format(col)
	end
	vim.g.terminal_color_0  = hex(normal.bg)
	vim.g.terminal_color_1  = hex(normal.red)
	vim.g.terminal_color_2  = hex(normal.green)
	vim.g.terminal_color_3  = hex(normal.yellow)
	vim.g.terminal_color_4  = hex(normal.blue)
	vim.g.terminal_color_5  = hex(normal.magenta)
	vim.g.terminal_color_6  = hex(normal.cyan)
	vim.g.terminal_color_7  = hex(bright.gray)

	vim.g.terminal_color_8  = hex(bright.bg)
	vim.g.terminal_color_9  = hex(bright.red)
	vim.g.terminal_color_10 = hex(bright.green)
	vim.g.terminal_color_11 = hex(bright.yellow)
	vim.g.terminal_color_12 = hex(bright.blue)
	vim.g.terminal_color_13 = hex(bright.magenta)
	vim.g.terminal_color_14 = hex(bright.cyan)
	vim.g.terminal_color_15 = hex(bright.fg)
end

local themes: {string:{ColorName, ColorName, ColorName, ColorName}} = {
	default = {"blue", "red", "purple", "orange"},
	watermelon = {"cyan", "magenta"},

	blue = {"blue", "blue", "purple"},
	red = {"red", "red", "orange", "red"},
	purple = {"purple", "blue", "purple", "fg"},
	cyan = {"cyan", "fg", "cyan", "gray"},
}

local function applyTheme(name: string)
	if name == "random" then
		local keys <const> = vim.tbl_keys(themes)
		name = keys[math.random(1, #keys)]
		print("Random theme: " .. name)
	end
	applyHighlights(unpack(themes[name]))
end

return {
	themes = themes,
	normal = normal,
	dark = dark,
	bright = bright,
	applyHighlights = applyHighlights,
	applyTheme = applyTheme,
}
