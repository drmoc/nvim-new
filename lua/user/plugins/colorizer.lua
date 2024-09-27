return {
  "norcalli/nvim-colorizer.lua",
  config = function()
    require("colorizer").setup({
      "*", -- Aplica a todos os arquivos
    }, {
      RGB = true, -- Suporta valores RGB
      RRGGBB = true, -- Suporta valores hexadecimais (#RRGGBB)
      names = false, -- Desativa nomes de cores (por exemplo, 'blue')
      RRGGBBAA = true, -- Suporte para valores hexadecimais com alfa
      rgb_fn = true, -- Suporta funções CSS como `rgb(255, 128, 64)`
      hsl_fn = true, -- Suporte para funções HSL como `hsl(120, 100%, 50%)`
      css = true, -- Suporte para cores CSS
      css_fn = true, -- Suporte para funções CSS
    })
  end,
}
