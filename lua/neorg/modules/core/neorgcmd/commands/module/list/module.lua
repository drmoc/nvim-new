--[[
    file: Neorgcmd-List
    title: Provides the `:Neorg list` Command
    summary: List loaded modules.
    internal: true
    ---
Upon execution (`:Neorg module list`) an info popup is created with a list of currently loaded
modules.
--]]

local neorg = require("neorg.core")
local modules = neorg.modules

local module = modules.create("core.neorgcmd.commands.module.list")

module.setup = function()
    return { success = true, requires = { "core.neorgcmd", "core.ui" } }
end

module.public = {
    neorg_commands = {
        module = {
            args = 1,

            subcommands = {
                list = {
                    args = 0,
                    name = "module.list",
                },
            },
        },
    },
}

module.on_event = function(event)
    if event.type == "core.neorgcmd.events.module.list" then
        local lines = {
            -- modules.get_module_config("core.concealer").icons.heading.level_1.icon
            "*"
                .. " "
                .. "Loaded Neorg Modules",
        }

        for _, mod in pairs(modules.loaded_modules) do
            table.insert(lines, "  - `" .. mod.name .. "`")
        end

        local buf = module.required["core.ui"].create_norg_buffer("module_list", "nosplit")
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.keymap.set("n", "q", vim.cmd.quit, { buffer = buf, silent = true, nowait = true })

        local width = vim.api.nvim_win_get_width(0)
        local height = vim.api.nvim_win_get_height(0)

        vim.api.nvim_open_win(buf, true, {
            relative = "win",
            win = 0,
            width = math.floor(width * 0.7),
            height = math.floor(height * 0.9),
            col = math.floor(width * 0.15),
            row = math.floor(height * 0.05),
            border = "single",
            style = "minimal",
        })

        vim.api.nvim_buf_set_option(buf, "modifiable", false)
        vim.api.nvim_buf_set_option(buf, "filetype", "norg")
        vim.api.nvim_buf_set_name(buf, "loaded_modules.norg")
    end
end

module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["module.list"] = true,
    },
}

return module
