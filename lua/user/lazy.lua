local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
  { import = "user.plugins" },
  { import = "user.plugins.lsp" },
}, {
  install = {
    colorscheme = { "catppuccin-mocha" },
  },
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
})
vim.cmd("highlight @neorg.headings.1.prefix guifg=#B989F4")
vim.cmd("highlight @neorg.headings.1.title cterm=bold gui=bold guifg=#B989F4")
vim.cmd("highlight @neorg.headings.2.prefix guifg=#789AF1") -- #7aa2f7
vim.cmd("highlight @neorg.headings.2.title cterm=bold gui=bold guifg=#789AF1")
vim.cmd("highlight @neorg.headings.3.prefix guifg=#E67084") -- #F47090
vim.cmd("highlight @neorg.headings.3.title cterm=bold gui=bold guifg=#E67084")
vim.cmd("highlight @neorg.headings.4.prefix guifg=#a6e3a2")
vim.cmd("highlight @neorg.headings.4.title guifg=#a6e3a2")
vim.cmd("highlight @neorg.headings.6.prefix guifg=#00ea7a")
vim.cmd("highlight @neorg.headings.6.title cterm=bold gui=bold guifg=#00ea7a")
vim.cmd("highlight @neorg.todo_items.done guifg=#00ea7a")
vim.cmd("highlight @neorg.todo_items.pending guifg=#ffffff")
vim.cmd("highlight @neorg.todo_items.undone guifg=#F10014")
vim.cmd("highlight @neorg.markup.bold cterm=bold gui=bold guifg=#ffffff")
vim.cmd("highlight @neorg.markup.italic cterm=italic gui=italic guifg=#ffffff")
vim.cmd("highlight @neorg.markup.subscript guifg=#4fd6be") -- #50fa7a
vim.cmd("highlight @neorg.markup.variable guifg=#ff79c6") -- #ff007c
vim.cmd("highlight @neorg.markup.inline_math guifg=#ff6c6b")
vim.cmd("highlight @neorg.markup.superscript guifg=#fffe7b")
vim.cmd("highlight @neorg.lists.unordered.prefix guifg=#f8f8f2")
vim.cmd("highlight @neorg.lists.ordered.prefix guifg=#f8f8f2")
vim.cmd("highlight @neorg.quotes.1.prefix guifg=#a5adcb")
vim.cmd("highlight @neorg.quotes.1.content guifg=#a5adcb")
vim.cmd("highlight @neorg.quotes.2.prefix guifg=#a5adcb")
vim.cmd("highlight @neorg.quotes.2.content guifg=#a5adcb")
vim.cmd("highlight @neorg.quotes.3.prefix guifg=#a5adcb")
vim.cmd("highlight @neorg.quotes.3.content guifg=#a5adcb")
vim.cmd("highlight @neorg.quotes.4.prefix guifg=#a5adcb")
vim.cmd("highlight @neorg.quotes.4.content guifg=#a5adcb")
vim.cmd("highlight @neorg.quotes.5.prefix guifg=#a5adcb")
vim.cmd("highlight @neorg.quotes.5.content guifg=#a5adcb")
vim.cmd("highlight markdownH1 guifg=#B989F4")
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

--  Rosewater #f4dbd6 #F0D2CC
--  Flamingo  #f0c6c6 #EBB8BA
--  Pink      #f5bde6 #F1ABE0
--  Mauve     #c6a0f6 #B989F4
--  Red       #ed8796 #E67084
--  Marron    #ee99a0 #E7848F
--  Peach     #f5a97f #F1986C
--  Yellow    #eed49f #E9CB8E
--  Green     #a6da95 #97D583
--  Teal      #8bd5ca #7BCDBE
--  Sky       #91d7e3 #81CFDC
--  Sapphire  #7dc4e4 #6CB7DE
--  Blue      #8aadf4 #789AF1
--  Lavender  #b7bdf8 #A8ADF6
--  Text      #cad3f5 #B9C2F2
--  Subtext 1 #b8c0e0
--  Subtext 0 #a5adcb
--  Overlay 2 #939ab7
--  Overlay 1 #8087a2
--  Overlay 0 #6e738d
--  Surface 2 #5b6078
--  Surface 1 #494d64
--  Surface 0 #363a4f
--  Base      #24273a
--  Mantle    #1e2030
--  Crust     #181926
