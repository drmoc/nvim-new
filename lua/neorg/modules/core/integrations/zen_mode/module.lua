--[[
    file: ZenMode-Integration
    title: An integration for `zen-mode`
    summary: Integrates and exposes the functionality of `zen-mode` in Neorg.
    internal: true
    ---
This is a basic wrapper around `zen_mode` that allows one to toggle the zen mode programatically.
--]]

local neorg = require("neorg.core")
local modules = neorg.modules

local module = modules.create("core.integrations.zen_mode")

module.setup = function()
    local success, zen_mode = pcall(require, "zen_mode")

    if not success then
        return { success = false }
    end

    module.private.zen_mode = zen_mode
end

module.private = {
    zen_mode = nil,
}

---@class core.integrations.zen_mode
module.public = {
    toggle = function()
        vim.cmd(":ZenMode")
    end,
}
return module
