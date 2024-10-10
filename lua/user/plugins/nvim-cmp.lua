return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    "L3MON4D3/LuaSnip", -- snippet engine
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
    "onsails/lspkind.nvim", -- vs-code like pictograms
    "saghen/blink.cmp",
    "rafamadriz/friendly-snippets",
  },
  config = function()
    local cmp = require("cmp")

    local luasnip = require("luasnip")

    local lspkind = require("lspkind")

    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup({
      completion = {
        completeopt = "menu,menuone,preview,noselect",
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
        ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-e>"] = cmp.mapping.abort(), -- close completion window
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
      }),
      -- sources for autocompletion
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" }, -- snippets
        { name = "buffer" }, -- text within current buffer
        { name = "path" }, -- file system paths
        { name = "supermaven" },
      }),
      -- configure lspkind for vs-code like pictograms in completion menu
      formatting = {
        format = lspkind.cmp_format({
          mode = "symbol",
          max_width = 50,
          symbol_map = { Supermaven = "" },
          maxwidth = 50,
          ellipsis_char = "...",
        }),
      },
      -- kind_icons = {
      symbol_map = {
        Text = "󰉿",
        Method = "󰊕",
        Function = "󰊕",
        Constructor = "󰒓",
        Field = "󰜢",
        Variable = "󰆦",
        Property = "󰖷",
        Class = "󱡠",
        Interface = "󱡠",
        Struct = "󱡠",
        Module = "󰅩",
        Unit = "󰪚",
        Value = "󰦨",
        Enum = "󰦨",
        EnumMember = "󰦨",
        Keyword = "󰻾",
        Constant = "󰏿",
        Snippet = "󱄽",
        Color = "󰏘",
        File = "󰈔",
        Reference = "󰬲",
        Folder = "󰉋",
        Event = "󱐋",
        Operator = "󰪚",
        TypeParameter = "󰬛",
        Supermaven = "",
      },
      highlight = {
        ns = vim.api.nvim_create_namespace("blink_cmp"),
      },
      trigger = {
        completion = {
          -- regex used to get the text when fuzzy matching
          -- changing this may break some sources, so please report if you run into issues
          -- todo: shouldnt this also affect the accept command? should this also be per language?
          keyword_regex = "[%w_\\-]",
          -- LSPs can indicate when to show the completion window via trigger characters
          -- however, some LSPs (*cough* tsserver *cough*) return characters that would essentially
          -- always show the window. We block these by default
          blocked_trigger_characters = { " ", "\n", "\t" },
          -- when true, will show the completion window when the cursor comes after a trigger character when entering insert mode
          show_on_insert_on_trigger_character = true,
        },
        signature_help = {
          enabled = false,
          blocked_trigger_characters = {},
          blocked_retrigger_characters = {},
          -- when true, will show the signature help window when the cursor comes after a trigger character when entering insert mode
          show_on_insert_on_trigger_character = true,
        },
      },
      fuzzy = {
        -- frencency tracks the most recently/frequently used items and boosts the score of the item
        use_frecency = true,
        -- proximity bonus boosts the score of items with a value in the buffer
        use_proximity = true,
        max_items = 200,
        -- controls which sorts to use and in which order, these three are currently the only allowed options
        sorts = { "label", "kind", "score" },
      },
      nerd_font_variant = "normal",
    })
  end,
  vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", { fg = "#6CC644" }),
}
