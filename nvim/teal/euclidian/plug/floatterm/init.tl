local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local floatterm <const> = require("euclidian.plug.floatterm.api")
local type Dialog = dialog.Dialog

local key = ""
local shell = vim.fn.has("win32") and "powershell.exe" or "bash"
local termopenOpts: {string:any} = {}

local record SetupOpts
	toggle: string

	wid: number
	hei: number
	row: number
	col: number

	centered: boolean | Dialog.Opts.Center
	border: nvim.Window.Config.Border

	shell: string
	termopenOpts: {string:any}
	windowOpts: {string:any}
end

return function(opts: SetupOpts)
		opts = opts or {}

		floatterm.setToggleKey(opts.toggle or key)
		floatterm.setShell(opts.shell or shell)
		floatterm.setTermOptions(opts.termopenOpts or termopenOpts)
		floatterm.setWindowOpts(opts.windowOpts or {})

		floatterm.deinit()
		floatterm.init{
			wid = opts.wid or 0.9, hei = opts.hei or 0.85,
			row = opts.row, col = opts.col,
			centered = opts.centered or true,
			border = opts.border,

			interactive = true,
			hidden = true,
		}

		nvim.api.addUserCommand(
			"FloatingTerminalShow",
			floatterm.show,
			{
				nargs = 0,
				bar = true,
				desc = "Show or focus the floating terminal",
			}
		)

		nvim.api.addUserCommand(
			"FloatingTerminalHide",
			floatterm.show,
			{
				nargs = 0,
				bar = true,
				desc = "Hide the floating terminal",
			}
		)

		nvim.api.addUserCommand(
			"FloatingTerminalOpenInCurrent",
			nvim.scheduleWrap(function()
				nvim.Window():setBuf(floatterm.buffer().id)
			end),
			{
				nargs = 0,
				bar = true,
				desc = "Open the floatterm buffer in the current window",
			}
		)
end
