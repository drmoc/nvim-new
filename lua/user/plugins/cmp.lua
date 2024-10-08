return {
  "benlubas/cmp2lsp",
  config = vim.schedule_wrap(function()
    require("cmp2lsp").setup({})
  end),
}
