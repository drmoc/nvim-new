return {
    {
        'epilande/checkbox-cycle.nvim',
        ft = 'markdown',
        opts = {
            states = {
                { '[ ]', '[x]' },
            },
        },
        keys = {
            { '<CR>', '<Cmd>CheckboxCycleNext<CR>', desc = 'Próximo estado do checkbox', ft = { 'markdown' }, mode = { 'n', 'v' }, },
            { '<S-CR>', '<Cmd>CheckboxCyclePrev<CR>', desc = 'Estado anterior do checkbox', ft = { 'markdown' }, mode = { 'n', 'v' }, },
        },
    },
}
