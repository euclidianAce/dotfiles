
local record Package
	-- TODO: propose some sort of enum set to access these at runtime without having to repeat the definition of them?
	enum Kind
		"git" "local"
	end
	kinds: {Kind:boolean}
	record Spec
		alias: string
		opt: boolean

		id: number
		dependents: {number|Spec}

		kind: Kind

		-- git
		repo: string
		branch: string

		-- local
		path: string
	end
end

Package.kinds = {
	["git"] = true,
	["local"] = true,
}

return Package
