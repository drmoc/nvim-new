return {
	"nvim-neorg/neorg",
	build = ":Neorg sync-parsers",
	-- tag = "*",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("neorg").setup({
			load = {
				["core.summary"] = {},
				["core.export.markdown"] = {},
				["core.defaults"] = {}, -- Loads default behaviour
				["core.concealer"] = {}, -- Adds pretty icons to your documents
				["core.integrations.image"] = {},
				["core.dirman"] = { -- Manages Neorg workspaces
					config = {
						workspaces = {
							notas = "~/medicina",
						},
					},
				},
			},
		})
	end,
}
