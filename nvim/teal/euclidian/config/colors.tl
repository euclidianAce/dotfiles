
-- Colorscheme
local color <const> = require("euclidian.lib.color")

vim.api.nvim_command("set bg=dark")
local palette <const>: {string:number} = {
	darkFg   = 0x817998,
	fg       = 0xD8CEE4,
	brightFg = 0xEFEFEF,

	darkBg   = 0x16131F,
	bg       = 0x181520,
	brightBg = 0x2B2735,

	darkGray   = 0x332F3C,
	gray       = 0x464252,
	brightGray = 0x817998,

	darkRed   = 0x77405F,
	red       = 0xD16161,
	brightRed = 0xE69090,

	darkPurple   = 0x826BB7,
	purple       = 0x9674D8,
	brightPurple = 0xC7B1F2,

	darkGreen   = 0x50D480,
	green       = 0x62F5A2,

	darkBlue   = 0x395081,
	blue       = 0x799AE0,
	brightBlue = 0xAAC3FD,

	orange = 0xE8AB73,
}

local p <const> = palette
local hi <const> = color.scheme.hi

-- ENV stuff would be nice here...
-- ui stuffs
hi.Normal   = { p.fg, p.bg }
hi.Visual   = { p.fg, p.darkGray }
hi.ErrorMsg = { nil, p.red }
hi.Search   = { p.bg, p.green }

hi.VertSplit   = { nil, p.gray }
hi.StatusLine  = { nil, p.brightGray }
hi.TabLine     = { nil, p.gray }
hi.TabLineSel  = { nil, p.brightGray, "bold" }
hi.TabLineFill = { nil, p.gray }
hi.Title       = { p.green, nil, "bold" }

hi.Pmenu        = { p.fg, p.brightBg }
hi.PmenuSel     = { nil,  p.gray }
hi.PmenuSbar    = { nil,  p.brightGray }
hi.PmenuThumb   = { nil,  p.gray }

hi.LineNr       = { p.gray, p.darkBg }
hi.CursorLineNr = { p.lightGray, p.darkBg, "bold" }

hi.Folded       = { p.darkRed, nil, "bold" }
hi.FoldColumn   = { p.darkRed, p.darkBg, "bold" }
hi.SignColumn   = { p.brightBg, p.darkBg }
hi.NonText      = { p.brightBg }
hi.MatchParen   = { p.brightBlue, nil, "bold" }

-- syntax
hi.Comment    = { p.darkRed }
hi.Constant   = { p.red }

hi.Identifier = { p.purple }
hi.Function   = { p.brightBlue, nil, "bold" }

hi.Statement  = { p.blue }
hi.Operator   = { p.darkPurple }

hi.Type         = { p.darkPurple, nil, "bold" }
hi.Structure    = { p.darkPurple }
hi.StorageClass = { p.brightPurple, nil, "bold" }

hi.Special   = { p.brightBlue }
hi.Delimiter = { p.brightGray }

hi.PreProc = { p.brightRed }

hi.Todo    = { p.brightRed, nil, "bold" }
hi.Error   = { nil, p.red, "bold" }

-- FIXME: Nov 26 20:55 2020
--        This cast should not be necessary
--        teal sees this literal as {string|nil} instead of
--        a tuple of [nil, nil, string], which is compatible with
--        Color -> [number, number, string]
hi.Underlined = { nil, nil, "underline" } as color.Color

-- Treesitter
hi.TSConstructor           = {  }
hi.TSParameter             = { p.orange }
hi.TSParameterReference    = { p.orange }
hi.TSAttribute             = { p.brightPurple }
hi.TSConstBuiltin          = { p.red }

hi.String    = hi.Constant
hi.Character = hi.Constant
hi.Number    = hi.Constant
hi.Boolean   = hi.Constant
hi.Float     = hi.Constant

hi.Conditional = hi.Statement
hi.Repeat      = hi.Statement
hi.Label       = hi.Statement
hi.Keyword     = hi.Statement
hi.Exception   = hi.Statement

hi.Typedef     = hi.Type

hi.SpecialComment = hi.Special
hi.SpecialChar    = hi.Special
hi.Tag            = hi.Special
hi.Debug          = hi.Special

hi.PreCondit = hi.PreProc
hi.Include   = hi.PreProc
hi.Define    = hi.PreProc
hi.Macro     = hi.PreProc

return p
