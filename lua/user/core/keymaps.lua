-- set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local keymap = vim.keymap -- for conciseness

---------------------
-- General Keymaps -------------------

-- use jj to exit insert mode
keymap.set("i", "jj", "<ESC>", { desc = "Exit insert mode with jj" })

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- delete single character without copying into register
-- keymap.set("n", "x", '"_x')

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- buffer management
keymap.set("n", "<leader>bn", ":bn<CR>", { desc = "Go to next buffer" }) --  go to next buffer
keymap.set("n", "<leader>bp", ":bp<CR>", { desc = "Go to previus buffer" }) --  go to previus buffer

-- save, quit and source
keymap.set("n", "<leader>w", ":wa<CR>", { desc = "Save current document" }) -- save current document
keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit without salving" }) --  quit without saving
keymap.set("n", "<leader>wq", ":wqa<CR>", { desc = "Save and quit all the windows" }) --  save and quit all the windows
keymap.set("n", "<leader>re", ":e<CR>", { desc = "Reload the file" }) --  save and quit all the windows
keymap.set("n", "<leader>so", ":source %<CR>", { desc = "Source current file" }) -- source current file
keymap.set("n", "<leader>si", ":source ~/.config/nvim/init.lua<CR>", { desc = "Source init.lua" }) --  source init lua

keymap.set("n", "<leader>cl", ":setlocal conceallevel=3<CR>", { desc = "Conceallevel=3" })
keymap.set("n", "<leader>ci", ":setlocal conceallevel=1<CR>", { desc = "Conceallevel=1" })
keymap.set("n", "<leader>co", ":setlocal conceallevel=0<CR>", { desc = "Conceallevel=0" })

keymap.set("n", "<leader>I", ":Neorg toc<CR>", { desc = "[Neorg] Open Neorg TOC" })
keymap.set("n", "<leader>pi", ":PasteImage<CR>", { desc = "Paste Image" })

-- Cronograma
keymap.set("n", "<leader>cr", ":e ~/medicina/cronograma.norg<CR>", { desc = "Open Cronograma" })

-- Configurações para Tabout
keymap.set("i", "<Tab>", "<Plug>(Tabout)", { silent = true })
keymap.set("i", "<S-Tab>", "<Plug>(TaboutBackward)", { silent = true })

-- AutoWrite
keymap.set('n', '<space>tw', ":ToggleAutowrite<CR>")

