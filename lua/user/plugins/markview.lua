return {
  "OXY2DEV/markview.nvim",
  lazy = false, -- Recomenda-se carregar o plugin imediatamente
  -- ft = "markdown", -- Você pode habilitar se preferir carregar apenas em arquivos markdown

  dependencies = {
    -- Parsers necessários para renderizar o markdown corretamente
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons", -- Ícones para melhorar a aparência
  },
}
