--[[
    file: Neorgcmd-List
    title: Provides the `:Neorg load ...` Command
    summary: Load a new module dynamically.
    internal: true
    ---
Upon exection (`:Neorg module load <module_path>`) dynamically docks a new module
into the current Neorg environment. Useful to include modules as a one-off.
--]]

local neorg = require("neorg.core")
local modules = neorg.modules

local module = modules.create("core.neorgcmd.commands.module.load")

module.setup = function()
    return { success = true, requires = { "core.neorgcmd" } }
end

module.public = {

    neorg_commands = {
        module = {
            args = 1,

            subcommands = {
                load = {
                    args = 1,
                    name = "module.load",
                },
            },
        },
    },
}

module.on_event = function(event)
    if event.type == "core.neorgcmd.events.module.load" then
        modules.load_module(event.content[1])
    end
end

module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["module.load"] = true,
    },
}

return module
