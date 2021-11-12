-- st.font = "Fantasque Sans Mono:size=14:bold=false:antialias=true"
-- st.font = "FiraCode Light:size=12:antialias=true"
-- st.font = "Fixedsys Excelsior:size=12:antialias=false:bold=false" -- this has problems with width
-- st.font = "Hasklig:size=14:bold=false:antialias=true"
-- st.font = "Ubuntu Mono:size=12:antialias=true"
st.font = "Julia Mono:size=10:antialias=true"
-- st.font = "terminus:size=12:antialias=true"
-- st.font = "CozetteVector:size=11:antialias=false"
-- st.font = "cozette:size=11:antialias=true"

st.borderpx = 4
st.barcursorwidth = 1
st.blinktimeout = 1200

st.colorname = {
	"#181520",
	"#D16161",
	"#62F5A2",
	"#D5C876",
	"#799AE0",
	"#6554A0",
	"cyan3",
	"gray90",

	"gray50",
	"#E69090",
	"#A8EBC5",
	"#F0E7AC",
	"#AAC3FD",
	"magenta",
	"cyan",
	"white",
}

local function updatecursor()
	st.underlinecursorheight = math.floor(term.usedfontsize() / 8 + 3)
end

updatecursor()

st.keymap(mod.crtl, key.Up, function()
	term.zoom(1)
	updatecursor()
end)

st.keymap(mod.crtl, key.Down, function()
	term.zoom(-1)
	updatecursor()
end)
