return {
	"lervag/vimtex",
	priority = 1000,
	lazy = false, -- we don't want to lazy load VimTeX
	-- tag = "v2.15", -- uncomment to pin to a specific release
	init = function()
		-- VimTeX configuration goes here
		-- " This is necessary for VimTeX to load properly. The "indent" is optional.
		-- " Note that most plugin managers will do this automatically.
		vim.cmd("filetype plugin indent on")

		-- " This enables Vim's and neovim's syntax-related features. Without this, some
		-- " VimTeX features will not work (see ":help vimtex-requirements" for more
		-- " info).
		vim.cmd("syntax enable")

		-- " Viewer options: One may configure the viewer either by specifying a built-in
		-- " viewer method:
		vim.cmd('let g:vimtex_view_method = "skim"')

		-- " Or with a generic interface:
		vim.cmd('let g:vimtex_view_general_viewer = "okular"')
		vim.cmd('let g:vimtex_view_general_options = "--unique file:@pd\\#src:@line@tex"')

		-- " VimTeX uses latexmk as the default compiler backend. If you use it, which is
		-- " strongly recommended, you probably don't need to configure anything. If you
		-- " want another compiler backend, you can change it as follows. The list of
		-- " supported backends and further explanation is provided in the documentation,
		-- " see ":help vimtex-compiler".
		vim.cmd('let g:vimtex_compiler_method = "latexmk"')

		-- " Most VimTeX mappings rely on localleader and this can be changed with the
		-- " following line. The default is usually fine and is the symbol "\".
	end,
}
