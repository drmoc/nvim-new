--[[
    File for creating text popups for the user.
--]]

local neorg = require("neorg.core")
local modules = neorg.modules

local module = modules.create("core.ui.text_popup")

---@class core.ui
module.public = {
    --- Opens a floating window at the specified position and asks for user input
    ---@param name string #The name of the floating window
    ---@param input_text string #The input text to prompt the user for input
    ---@param callback fun(entered_text: string, data: table) #A function that gets invoked whenever the user provides some text.
    ---@param modifiers table #Special table to modify certain attributes of the floating window (like centering on the x or y axis)
    ---@param config table #A config like you would pass into nvim_open_win()
    create_prompt = function(name, input_text, callback, modifiers, config)
        -- Create the base cofiguration for the popup window
        local window_config = {
            relative = "win",
            style = "minimal",
            border = "rounded",
        }

        -- Apply any custom modifiers that the user has specified
        window_config = assert(modules.get_module("core.ui"), "core.ui is not loaded!").apply_custom_options(
            modifiers,
            vim.tbl_extend("force", window_config, config or {})
        )

        local buf = vim.api.nvim_create_buf(false, true)

        -- Set the buffer type to "prompt" to give it special behaviour (:h prompt-buffer)
        vim.api.nvim_buf_set_option(buf, "buftype", "prompt")
        vim.api.nvim_buf_set_name(buf, name)

        -- Create a callback to be invoked on prompt confirmation
        vim.fn.prompt_setcallback(buf, function(content)
            if content:len() > 0 then
                callback(content, {
                    close = function(opts)
                        vim.api.nvim_buf_delete(buf, opts or { force = true })
                    end,
                })
            end
        end)

        -- Construct some custom mappings for the popup
        vim.keymap.set("n", "<Esc>", vim.cmd.quit, { silent = true, buffer = buf })
        vim.keymap.set("n", "<Tab>", "<CR>", { silent = true, buffer = buf })
        vim.keymap.set("i", "<Tab>", "<CR>", { silent = true, buffer = buf })
        vim.keymap.set("i", "<C-c>", "<Esc>:q<CR>", { silent = true, buffer = buf })

        -- If the use has specified some input text then show that input text in the buffer
        if input_text then
            vim.fn.prompt_setprompt(buf, input_text)
        end

        -- Automatically enter insert mode
        vim.api.nvim_feedkeys("i", "t", false)

        -- Create the floating popup window with the prompt buffer
        local winid = vim.api.nvim_open_win(buf, true, window_config)

        -- Make sure to clean up the window if the user leaves the popup at any time
        vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave", "BufDelete" }, {
            buffer = buf,
            once = true,
            callback = function()
                pcall(vim.api.nvim_win_close, winid, true)
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end,
        })

        -- HACK(vhyrro): Prevent the "not enough room" error when leaving the window.
        -- See: https://github.com/neovim/neovim/issues/19464
        vim.api.nvim_win_set_option(winid, "winbar", "")
    end,
}

return module
