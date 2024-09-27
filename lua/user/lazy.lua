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
    colorscheme = { "catppuccin-macchiato" },
  },
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
})
vim.cmd("highlight @neorg.headings.1.prefix guifg=#9d7cd8") -- #AE7AF8 --OK
vim.cmd("highlight @neorg.headings.1.title cterm=bold gui=bold guifg=#9d7cd8") --OK
vim.cmd("highlight @neorg.headings.2.prefix guifg=#7aa2f7") --#4DBBDC--OK
vim.cmd("highlight @neorg.headings.2.title cterm=bold gui=bold guifg=#7aa2f7")
vim.cmd("highlight @neorg.headings.3.prefix guifg=#F47090")
vim.cmd("highlight @neorg.headings.3.title cterm=bold gui=bold guifg=#F47090")
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
vim.cmd("highlight @neorg.quotes.1.prefix guifg=#c0caf5")
vim.cmd("highlight @neorg.quotes.1.content guifg=#c0caf5")
vim.cmd("highlight @neorg.quotes.2.prefix guifg=#c0caf5")
vim.cmd("highlight @neorg.quotes.2.content guifg=#c0caf5")
vim.cmd("highlight @neorg.quotes.3.prefix guifg=#c0caf5")
vim.cmd("highlight @neorg.quotes.3.content guifg=#c0caf5")
vim.cmd("highlight @neorg.quotes.4.prefix guifg=#c0caf5")
vim.cmd("highlight @neorg.quotes.4.content guifg=#c0caf5")
vim.cmd("highlight @neorg.quotes.5.prefix guifg=#c0caf5")
vim.cmd("highlight @neorg.quotes.5.content guifg=#c0caf5") -- #9399B3

-- #1f2335
-- #24283b
-- #292e42
-- #3b4261
-- #414868
-- #545c7e
-- #565f89
-- #737aa2
-- #a9b1d6
-- #c0caf5
-- #394b70
-- #3d59a1
-- #7aa2f7
-- #7dcfff
-- #b4f9f8
-- #9d7cd8
-- #bb9af7
-- #ff9e64
-- #ffc777
-- #c3e88d
-- #4fd6be
-- #41a6b5
-- #ff757f
-- #c53b53
-- #ff007c
