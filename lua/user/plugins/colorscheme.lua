return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "auto", -- latte, frappe, macchiato, mocha
      background = { -- :h background
        light = "latte",
        dark = "mocha",
      },
      transparent_background = true, -- disables setting the background color.
      show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
      term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
      dim_inactive = {
        enabled = false, -- dims the background color of inactive window
        shade = "dark",
        percentage = 0.15, -- percentage of the shade to apply to the inactive window
      },
      no_italic = false, -- Force no italic
      no_bold = false, -- Force no bold
      no_underline = false, -- Force no underline
      styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
        comments = { "italic" }, -- Change the style of comments
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
        -- miscs = {}, -- Uncomment to turn off hard-coded styles
      },
      color_overrides = {},
      custom_highlights = {},
      default_integrations = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = false,
        mini = {
          enabled = true,
          indentscope_color = "",
        },
        -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
      },
    })
    vim.cmd.colorscheme("catppuccin-macchiato")
  end,
}

-- return {
--   "ilof2/posterpole.nvim",
--   priority = 1000,
--   config = function()
--     require("posterpole").setup({
--       transparent = true,
--       colorless_bg = false, -- grayscale or not
--       dim_inactive = false, -- highlight inactive splits
--       brightness = 0, -- negative numbers - darker, positive - lighter
--       selected_tab_highlight = false, --highlight current selected tab
--       fg_saturation = 0, -- font saturation, gray colors become more brighter
--       bg_saturation = 0, -- background saturation
--     })
--     vim.cmd("colorscheme posterpole")
--   end,
-- }
--
-- return {
--   "marko-cerovac/material.nvim",
--   priority = 1000,
--   config = function()
--     require("material").setup({})
--   end,
-- }
--       options = {
--         theme = "material-stealth",
--       },
--       contrast = {
--         terminal = false, -- Enable contrast for the built-in terminal
--         sidebars = false, -- Enable contrast for sidebar-like windows ( for example Nvim-Tree )
--         floating_windows = false, -- Enable contrast for floating windows
--         cursor_line = false, -- Enable darker background for the cursor line
--         lsp_virtual_text = false, -- Enable contrasted background for lsp virtual text
--         non_current_windows = false, -- Enable contrasted background for non-current windows
--         filetypes = {}, -- Specify which filetypes get the contrasted (darker) background
--       },
--
--       styles = { -- Give comments style such as bold, italic, underline etc.
--         comments = { [[ italic = true ]] },
--         strings = { [[ bold = true ]] },
--         keywords = { [[ underline = true ]] },
--         functions = { [[ bold = true, undercurl = true ]] },
--         variables = {},
--         operators = {},
--         types = {},
--       },
--
--       plugins = { -- Uncomment the plugins that you use to highlight them
--         -- Available plugins:
--         -- "coc",
--         -- "colorful-winsep",
--         -- "dap",
--         -- "dashboard",
--         -- "eyeliner",
--         -- "fidget",
--         -- "flash",
--         -- "gitsigns",
--         -- "harpoon",
--         -- "hop",
--         -- "illuminate",
--         "indent-blankline",
--         -- "lspsaga",
--         -- "mini",
--         -- "neogit",
--         -- "neotest",
--         -- "neo-tree",
--         "neorg",
--         -- "noice",
--         -- "nvim-cmp",
--         -- "nvim-navic",
--         -- "nvim-tree",
--         -- "nvim-web-devicons",
--         -- "rainbow-delimiters",
--         -- "sneak",
--         "telescope",
--         -- "trouble",
--         "which-key",
--         -- "nvim-notify",
--       },
--
--       disable = {
--         colored_cursor = false, -- Disable the colored cursor
--         borders = false, -- Disable borders between vertically split windows
--         background = false, -- Prevent the theme from setting the background (NeoVim then uses your terminal background)
--         term_colors = false, -- Prevent the theme from setting terminal colors
--         eob_lines = false, -- Hide the end-of-buffer lines
--       },
--
--       high_visibility = {
--         lighter = false, -- Enable higher contrast text for lighter style
--         darker = false, -- Enable higher contrast text for darker style
--       },
--
--       lualine_style = "default", -- Lualine style ( can be 'stealth' or 'default' )
--
--       async_loading = true, -- Load parts of the theme asynchronously for faster startup (turned on by default)
--
--       custom_colors = nil, -- If you want to override the default colors, set this to a function
--
--       custom_highlights = {}, -- Overwrite highlights with your own
--     })
--     vim.cmd.colorscheme("material")
--   end,
-- }

-- return {
-- 	"scottmckendry/cyberdream.nvim",
-- 	lazy = false,
-- 	priority = 1000,
-- 	config = function()
-- 		require("cyberdream").setup({
-- 			-- Recommended - see "Configuring" below for more config options
-- 			transparent = true, -- disables setting the background color.
-- 			italic_comments = true,
-- 			hide_fillchars = true,
-- 			borderless_telescope = true,
-- 			highlights = {
-- 				-- Highlight groups to override, adding new groups is also possible
-- 				-- See `:help highlight-groups` for a list of highlight groups
--
-- 				-- Example:
-- 				Comment = { fg = "#696969", bg = "NONE", italic = true },
--
-- 				-- Complete list can be found in `lua/cyberdream/theme.lua`
-- 			},
--
-- 			-- Override a color entirely
-- 			colors = {
-- 				-- For a list of colors see `lua/cyberdream/colours.lua`
-- 				-- Example:
-- 				bg = "#000000",
-- 				green = "#00ff00",
-- 				magenta = "#ff00ff",
-- 			},
-- 			terminal_colors = true,
-- 		})
-- 		vim.cmd("colorscheme cyberdream") -- set the colorscheme
-- 	end,
-- }

-- return
--   {
--     "eldritch-theme/eldritch.nvim",
--     lazy = false,
--     priority = 1000,
--     opts = {},
--     config = function ()
--       require("eldritch").setup({
--         flavour = "auto", -- latte, frappe, macchiato, mocha
--         background = { -- :h background
--           transparent_background = true, -- disables setting the background color.
--           show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
--           term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
--           dim_inactive = {
--             enabled = false, -- dims the background color of inactive window
--             shade = "dark",
--             percentage = 0.15, -- percentage of the shade to apply to the inactive window
--           },
--           no_italic = false, -- Force no italic
--           no_bold = false, -- Force no bold
--           no_underline = false, -- Force no underline
--           styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
--             comments = { "italic" }, -- Change the style of comments
--             conditionals = { "italic" },
--             loops = {},
--             functions = {},
--             keywords = {},
--             strings = {},
--             variables = {},
--             numbers = {},
--             booleans = {},
--             properties = {},
--             types = {},
--             operators = {},
--             -- miscs = {}, -- Uncomment to turn off hard-coded styles
--           },
--           color_overrides = {},
--           custom_highlights = {},
--           default_integrations = true,
--           integrations = {
--             cmp = true,
--             gitsigns = true,
--             nvimtree = true,
--             treesitter = true,
--             notify = false,
--             mini = {
--               enabled = true,
--               indentscope_color = "",
--             },
--             -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
--           },
--         },
--       })
--       vim.cmd("colorscheme eldritch")
--     end,
--   }
-- return {
--   "folke/tokyonight.nvim",
--   priority = 1000,
--   config = function()
--     local transparent = true -- set to true if you would like to enable transparency
--
--     local bg = "#011628"
--     local bg_dark = "#011423"
--     local bg_highlight = "#143652"
--     local bg_search = "#0A64AC"
--     local bg_visual = "#275378"
--     local fg = "#CBE0F0"
--     local fg_dark = "#B4D0E9"
--     local fg_gutter = "#627E97"
--     local border = "#547998"
--
--     require("tokyonight").setup({
--       style = "night",
--       transparent = transparent,
--       styles = {
--         sidebars = transparent and "transparent" or "dark",
--         floats = transparent and "transparent" or "dark",
--       },
--       on_colors = function(colors)
--         colors.bg = bg
--         colors.bg_dark = transparent and colors.none or bg_dark
--         colors.bg_float = transparent and colors.none or bg_dark
--         colors.bg_highlight = bg_highlight
--         colors.bg_popup = bg_dark
--         colors.bg_search = bg_search
--         colors.bg_sidebar = transparent and colors.none or bg_dark
--         colors.bg_statusline = transparent and colors.none or bg_dark
--         colors.bg_visual = bg_visual
--         colors.border = border
--         colors.fg = fg
--         colors.fg_dark = fg_dark
--         colors.fg_float = fg
--         colors.fg_gutter = fg_gutter
--         colors.fg_sidebar = fg_dark
--       end,
--     })
--
--     vim.cmd("colorscheme tokyonight")
--   end,
-- }

-- return {
-- 	"navarasu/onedark.nvim",
-- 	priority = 1000,
-- 	config = function()
-- 		require("onedark").load()
-- 		local bg = "#011628"
-- 		local bg_dark = "#011423"
-- 		local bg_highlight = "#143652"
-- 		local bg_search = "#0A64AC"
-- 		local bg_visual = "#275378"
-- 		local fg = "#CBE0F0"
-- 		local fg_dark = "#B4D0E9"
-- 		local fg_gutter = "#627E97"
-- 		local border = "#547998"
--
-- 		require("onedark").setup({
-- 			style = "darker",
-- 		})
-- 		on_colors = function(colors)
-- 			colors.bg = bg
-- 			colors.bg_dark = bg_dark
-- 			colors.bg_float = bg_dark
-- 			colors.bg_highlight = bg_highlight
-- 			colors.bg_popup = bg_dark
-- 			colors.bg_search = bg_search
-- 			colors.bg_sidebar = bg_dark
-- 			colors.bg_statusline = bg_dark
-- 			colors.bg_visual = bg_visual
-- 			colors.border = border
-- 			colors.fg = fg
-- 			colors.fg_dark = fg_dark
-- 			colors.fg_float = fg
-- 			colors.fg_gutter = fg_gutter
-- 			colors.fg_sidebar = fg_dark
-- 		end
-- 		vim.cmd("colorscheme onedark")
-- 	end,
-- },
-- return
-- 	{
-- 		"rebelot/kanagawa.nvim",
-- 		priority = 1000,
-- 		config = function()
-- 			require("kanagawa").setup({
-- 				compile = false, -- enable compiling the colorscheme
-- 				undercurl = true, -- enable undercurls
-- 				commentStyle = { italic = true },
-- 				functionStyle = {},
-- 				keywordStyle = { italic = true },
-- 				statementStyle = { bold = true },
-- 				typeStyle = {},
-- 				transparent = false, -- do not set background color
-- 				dimInactive = false, -- dim inactive window `:h hl-NormalNC`
-- 				terminalColors = true, -- define vim.g.terminal_color_{0,17}
-- 				colors = { -- add/modify theme and palette colors
-- 					palette = {},
-- 					theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
-- 				},
-- 				overrides = function(colors) -- add/modify highlights
-- 					return {}
-- 				end,
-- 				theme = "wave", -- Load "wave" theme when 'background' option is not set
-- 				background = { -- map the value of 'background' option to a theme
-- 					dark = "wave", -- try "dragon" !
-- 					light = "lotus",
-- 				},
-- 			})
-- 			vim.cmd("colorscheme kanagawa")
-- 		end,
-- 	}
-- 	{
-- 		--	"NTBBloodbath/doom-one.nvim",
-- 		"maxmx03/dracula.nvim",
-- 		setup = function()
-- 			-- Add color to cursor
-- 			vim.g.dracula_cursor_coloring = true
-- 			-- Set :terminal colors
-- 			vim.g.dracula_terminal_colors = true
-- 			-- Enable italic comments
-- 			vim.g.dracula_italic_comments = true
-- 			-- Enable TS support
-- 			vim.g.dracula_enable_treesitter = true
-- 			-- Color whole diagnostic text or only underline
-- 			vim.g.dracula_diagnostics_text_color = false
-- 			-- Enable transparent background
-- 			vim.g.dracula_transparent_background = false
--
-- 			-- Pumblend transparency
-- 			vim.g.dracula_pumblend_enable = false
-- 			vim.g.dracula_pumblend_transparency = 20
--
-- 			-- Plugins integration
-- 			vim.g.dracula_plugin_neorg = true
-- 			vim.g.dracula_plugin_barbar = false
-- 			vim.g.dracula_plugin_telescope = true
-- 			vim.g.dracula_plugin_neogit = true
-- 			vim.g.dracula_plugin_nvim_tree = true
-- 			vim.g.dracula_plugin_dashboard = true
-- 			vim.g.dracula_plugin_startify = true
-- 			vim.g.dracula_plugin_whichkey = true
-- 			vim.g.dracula_plugin_indent_blankline = true
-- 			vim.g.dracula_plugin_vim_illuminate = true
-- 			vim.g.dracula_plugin_lspsaga = true
-- 		end,
-- 		config = function()
-- 			-- vim.cmd("colorscheme dracula")
-- 		end,
-- 	},
--
--
-- return {
--   "rose-pine/neovim",
--   name = "rose-pine",
--   config = function()
--     require("rose-pine").setup({
--       -- configurações do tema variant = "auto", -- auto, main, moon, or dawn
--       transparent_background = true, -- disables setting the background color.
--       dark_variant = "main", -- main, moon, or dawn
--       dim_inactive_windows = false,
--       extend_background_behind_borders = true,
--
--       enable = {
--         terminal = true,
--         legacy_highlights = true, -- Improve compatibility for previous versions of Neovim
--         migrations = true, -- Handle deprecated options automatically
--       },
--
--       styles = {
--         bold = true,
--         italic = true,
--         transparency = false,
--       },
--
--       groups = {
--         border = "muted",
--         link = "iris",
--         panel = "surface",
--
--         error = "love",
--         hint = "iris",
--         info = "foam",
--         note = "pine",
--         todo = "rose",
--         warn = "gold",
--
--         git_add = "foam",
--         git_change = "rose",
--         git_delete = "love",
--         git_dirty = "rose",
--         git_ignore = "muted",
--         git_merge = "iris",
--         git_rename = "pine",
--         git_stage = "iris",
--         git_text = "rose",
--         git_untracked = "subtle",
--
--         h1 = "iris",
--         h2 = "foam",
--         h3 = "rose",
--         h4 = "gold",
--         h5 = "pine",
--         h6 = "foam",
--       },
--
--       highlight_groups = {
--         Comment = { fg = "foam" },
--         VertSplit = { fg = "muted", bg = "muted" },
--       },
--
--       before_highlight = function(group, highlight, palette)
--         -- Disable all undercurls
--         if highlight.undercurl then
--           highlight.undercurl = false
--         end
--
--         -- Change palette colour
--         if highlight.fg == palette.pine then
--           highlight.fg = palette.foam
--         end
--       end,
--     })
--     vim.cmd.colorscheme("rose-pine-moon")
--   end,
-- }
