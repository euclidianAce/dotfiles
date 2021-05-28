
-- Colorscheme
vim.g.colors_name = "euclidian"
local enum Color
	"fg"
	"bg"
	"gray"
	"red"
	"green"
	"yellow"
	"blue"
	"purple"
	"orange"
end
local type Palette = {Color:integer}

local normal <const>: Palette = {
	bg     = 0x181520,
	fg     = 0xD8CEE4,
	blue   = 0x799AE0,
	gray   = 0x464252,
	green  = 0x62F5A2,
	orange = 0xE8AB73,
	purple = 0x9876D9,
	red    = 0xD16161,
	yellow = 0xD5C876,
}

local dark <const>: Palette = {
	bg     = 0x16131F,
	fg     = 0x817998,
	blue   = 0x395081,
	gray   = 0x332F3C,
	green  = 0x50D480,
	orange = 0xB47B46,
	purple = 0x6554A0,
	red    = 0x77405F,
	yellow = 0x7B7532,
}

local bright <const>: Palette = {
	bg     = 0x2B2735,
	fg     = 0xEFEFEF,
	blue   = 0xAAC3FD,
	gray   = 0x817998,
	green  = 0xA8EBC5,
	orange = 0xC3AA93,
	purple = 0xC7B1F2,
	red    = 0xE69090,
	yellow = 0xF0E7AC,
}

local color <const> = require("euclidian.lib.color")
local hi <const> = color.scheme.hi

local min <const>, max <const> = math.min, math.max
local function clamp<T>(n: T, a: number, b: number): T
	return min(max(n, a), b) as T
end

local darkenFactor <const> = 128
local function invert(fgColor: integer): color.Color
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
	primary: Color,
	primaryComplement: Color,
	secondary: Color,
	secondaryComplement: Color
)
	primary = primary or "fg"
	primaryComplement = primaryComplement or primary
	secondary = secondary or primary
	secondaryComplement = secondaryComplement or secondary

	hi.Normal                  = { normal.fg, normal.bg }
	hi.Visual                  = { -1, dark.gray }
	hi.ErrorMsg                = { nil, normal.red }
	hi.Question                = { dark.green }
	hi.Search                  = { dark.green, hi.Visual[2], "bold" }
	hi.IncSearch               = hi.Search

	hi.StatusLine              = invert(dark[secondary])
	hi.StatusLineNC            = invert(normal.gray)

	hi.VertSplit               = { nil, normal.bg }
	hi.TabLine                 = { nil, normal.gray }
	hi.TabLineSel              = { nil, bright.gray, "underline" }
	hi.TabLineFill             = { nil, dark.gray }
	hi.Title                   = { normal.green, nil, "bold" }

	hi.FloatBorder             = { dark.fg, bright.bg }

	hi.Pmenu                   = { normal.fg, bright.bg }
	hi.PmenuSel                = { nil,  normal.gray }
	hi.PmenuSbar               = { nil,  bright.gray }
	hi.PmenuThumb              = { nil,  normal.gray }

	hi.CursorLine              = { nil, bright.bg }
	hi.CursorColumn            = { nil, bright.bg }
	hi.LineNr                  = { normal.gray, dark.bg }
	hi.CursorLineNr            = { nil, dark.bg }

	hi.Folded                  = { dark[secondary], nil, "bold" }
	hi.FoldColumn              = { dark[secondary], dark.bg, "bold" }
	hi.SignColumn              = { bright.bg, dark.bg }
	hi.NonText                 = { bright.bg }
	hi.MatchParen              = { normal[secondary], dark[secondary], "bold" }

	hi.Comment                 = { dark[secondary] }
	hi.Constant                = { normal[secondary] }

	hi.Identifier              = { normal.fg }
	hi.Function                = { bright[primary], nil, "bold" }

	hi.Statement               = { normal[primary] }
	hi.Operator                = { normal[primaryComplement] }

	hi.Type                    = { normal[primaryComplement] }
	hi.Structure               = { dark[secondaryComplement] }
	hi.StorageClass            = { bright[primaryComplement], nil, "bold" }

	hi.Special                 = { bright[secondary] }
	hi.Delimiter               = { dark[primary], -1 }

	hi.PreProc                 = { bright[secondary] }

	hi.Todo                    = { bright[secondary], nil, "bold" }
	hi.Error                   = { nil, dark.red, "bold" }

	hi.Underlined              = { nil, nil, "underline" }

	hi.TSConstructor           = {  }
	hi.TSParameter             = { normal[secondaryComplement] }
	hi.TSParameterReference    = { normal[secondaryComplement] }
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


	-- Custom Statusline Groups
	hi.STLBufferInfo           = invert(dark[secondary])
	hi.STLGit                  = invert(dark.green)
	hi.STLFname                = invert(bright.gray)

	hi.STLNormal               = invert(normal[primary])
	hi.STLInsert               = invert(normal[primaryComplement])
	hi.STLCommand              = invert(normal[secondary])
	hi.STLVisual               = invert(normal[secondaryComplement])

	hi.STLReplace              = invert(normal.red)
	hi.STLTerminal             = invert(normal.orange)
end

local function hex(col: integer): string
	return ("#%06X"):format(col)
end
vim.g.terminal_color_0 = hex(normal.bg)
vim.g.terminal_color_1 = hex(normal.red)
vim.g.terminal_color_2 = hex(normal.green)
vim.g.terminal_color_3 = hex(normal.yellow)
vim.g.terminal_color_4 = hex(normal.blue)
vim.g.terminal_color_5 = hex(normal.purple)
vim.g.terminal_color_6 = "cyan3"
vim.g.terminal_color_7 = hex(bright.gray)

vim.g.terminal_color_8 = hex(bright.bg)
vim.g.terminal_color_9 = hex(bright.red)
vim.g.terminal_color_10 = hex(bright.green)
vim.g.terminal_color_11 = hex(bright.yellow)
vim.g.terminal_color_12 = hex(bright.blue)
vim.g.terminal_color_13 = "magenta"
vim.g.terminal_color_14 = "cyan"
vim.g.terminal_color_15 = "white"

return {
	normal = normal,
	dark = dark,
	bright = bright,
	applyHighlights = applyHighlights,
}
