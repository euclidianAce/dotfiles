

vim.g.colors_name = "euclidian"
local p = {
   darkFg = 0x817998,
   fg = 0xD8CEE4,
   brightFg = 0xEFEFEF,

   darkBg = 0x16131F,
   bg = 0x181520,
   brightBg = 0x2B2735,

   darkGray = 0x332F3C,
   gray = 0x464252,
   brightGray = 0x817998,

   darkRed = 0x77405F,
   red = 0xD16161,
   brightRed = 0xE69090,

   darkGreen = 0x50D480,
   green = 0x62F5A2,
   brightGreen = 0xA8EBC5,

   darkBlue = 0x395081,
   blue = 0x799AE0,
   brightBlue = 0xAAC3FD,

   darkYellow = 0xA59844,
   yellow = 0xD5C876,
   brightYellow = 0xF0E7AC,

   darkPurple = 0x6554A0,
   purple = 0x9876D9,
   brightPurple = 0xC7B1F2,

   darkOrange = 0xB47B46,
   orange = 0xE8AB73,
   brightOrange = 0xC3AA93,
}

local hi = require("euclidian.lib.color").scheme.hi


hi.Normal = { p.fg, p.bg }
hi.Visual = { -1, p.darkGray }
hi.ErrorMsg = { nil, p.red }
hi.Question = { p.darkGreen }
hi.Search = { p.darkGreen, hi.Visual[2], "bold" }
hi.IncSearch = hi.Search

hi.VertSplit = { nil, p.bg }
hi.StatusLine = { nil, p.brightGray }
hi.TabLine = { nil, p.brightGray }
hi.TabLineSel = { nil, p.gray, "bold" }
hi.TabLineFill = { nil, p.darkGray }
hi.Title = { p.green, nil, "bold" }

hi.FloatBorder = { p.darkFg, p.brightBg }

hi.Pmenu = { p.fg, p.brightBg }
hi.PmenuSel = { nil, p.gray }
hi.PmenuSbar = { nil, p.brightGray }
hi.PmenuThumb = { nil, p.gray }

hi.CursorLine = { nil, p.brightBg }
hi.CursorColumn = { nil, p.brightBg }
hi.LineNr = { p.gray, p.darkBg }
hi.CursorLineNr = { nil, p.darkBg }

hi.Folded = { p.darkRed, nil, "bold" }
hi.FoldColumn = { p.darkRed, p.darkBg, "bold" }
hi.SignColumn = { p.brightBg, p.darkBg }
hi.NonText = { p.brightBg }
hi.MatchParen = { p.red, p.darkRed, "bold" }


hi.Comment = { p.darkRed }
hi.Constant = { p.red }

hi.Identifier = { p.fg }
hi.Function = { p.brightBlue, nil, "bold" }

hi.Statement = { p.blue }
hi.Operator = { p.darkPurple }

hi.Type = { p.purple }
hi.Structure = { p.darkPurple }
hi.StorageClass = { p.brightPurple, nil, "bold" }

hi.Special = { p.brightRed }
hi.Delimiter = { p.brightGray, -1 }

hi.PreProc = { p.brightRed }

hi.Todo = { p.brightRed, nil, "bold" }
hi.Error = { nil, p.red, "bold" }

hi.Underlined = { nil, nil, "underline" }


hi.TSConstructor = {}
hi.TSParameter = { p.orange }
hi.TSParameterReference = { p.orange }
hi.TSAttribute = { p.brightPurple }
hi.TSConstBuiltin = { p.red }

hi.String = hi.Constant
hi.Character = hi.Constant
hi.Number = hi.Constant
hi.Boolean = hi.Constant
hi.Float = hi.Constant

hi.Conditional = hi.Statement
hi.Repeat = hi.Statement
hi.Label = hi.Statement
hi.Keyword = hi.Statement
hi.Exception = hi.Statement

hi.Typedef = hi.Type

hi.SpecialComment = hi.Special
hi.SpecialChar = hi.Special
hi.SpecialKey = hi.Special
hi.Tag = hi.Special
hi.Debug = hi.Special

hi.PreCondit = hi.PreProc
hi.Include = hi.PreProc
hi.Define = hi.PreProc
hi.Macro = hi.PreProc

hi.Directory = { p.blue }
hi.WarningMsg = { nil, p.red }
hi.WildMenu = { p.bg, p.yellow }

return p