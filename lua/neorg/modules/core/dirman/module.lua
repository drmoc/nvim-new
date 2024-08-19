--[[
    file: Dirman
    title: The Most Critical Component of any Organized Workflow
    description: The `dirman` module handles different collections of notes in separate directories.
    summary: This module is be responsible for managing directories full of .norg files.
    ---
`core.dirman` provides other modules the ability to see which directories the user is in, where
each note collection is stored and how to interact with it.

When writing notes, it is often crucial to have notes on a certain topic be isolated from notes on another topic.
Dirman achieves this with a concept of "workspaces", which are named directories full of `.norg` notes.

To use `core.dirman`, simply load up the module in your configuration and specify the directories you would like to be managed for you:

```lua
require('neorg').setup {
    load = {
        ["core.defaults"] = {},
        ["core.dirman"] = {
            config = {
                workspaces = {
                    my_ws = "~/neorg", -- Format: <name_of_workspace> = <path_to_workspace_root>
                    my_other_notes = "~/work/notes",
                },
                index = "index.norg", -- The name of the main (root) .norg file
            }
        }
    }
}
```

To query the current workspace, run `:Neorg workspace`. To set the workspace, run `:Neorg workspace <workspace_name>`.

### Changing the Current Working Directory
After a recent update `core.dirman` will no longer change the current working directory after switching
workspace. To get the best experience it's recommended to set the `autochdir` Neovim option.


### Create a new note
You can use dirman to create new notes in your workspaces.

```lua
local dirman = require('neorg').modules.get_module("core.dirman")
dirman.create_file("my_file", "my_ws", {
    no_open  = false,  -- open file after creation?
    force    = false,  -- overwrite file if exists
    metadata = {}      -- key-value table for metadata fields
})
```
--]]

local neorg = require("neorg.core")
local config, log, modules, utils = neorg.config, neorg.log, neorg.modules, neorg.utils

local module = modules.create("core.dirman")

module.setup = function()
    return {
        success = true,
        requires = { "core.autocommands", "core.ui", "core.storage" },
    }
end

module.load = function()
    -- Go through every workspace and expand special symbols like ~
    for name, workspace_location in pairs(module.config.public.workspaces) do
        module.config.public.workspaces[name] = vim.fn.expand(workspace_location) ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
    end

    modules.await("core.keybinds", function(keybinds)
        keybinds.register_keybind(module.name, "new.note")
    end)

    -- Used to detect when we've entered a buffer with a potentially different cwd
    module.required["core.autocommands"].enable_autocommand("BufEnter", true)

    modules.await("core.neorgcmd", function(neorgcmd)
        neorgcmd.add_commands_from_table({
            index = {
                args = 0,
                name = "dirman.index",
            },
        })
    end)

    -- Synchronize core.neorgcmd autocompletions
    module.public.sync()

    if module.config.public.open_last_workspace and vim.fn.argc(-1) == 0 then
        if module.config.public.open_last_workspace == "default" then
            if not module.config.public.default_workspace then
                log.warn(
                    'Configuration error in `core.dirman`: the `open_last_workspace` option is set to "default", but no default workspace is provided in the `default_workspace` configuration variable. Defaulting to opening the last known workspace.'
                )
                module.public.set_last_workspace()
                return
            end

            module.public.open_workspace(module.config.public.default_workspace)
        else
            module.public.set_last_workspace()
        end
    elseif module.config.public.default_workspace then
        module.public.set_workspace(module.config.public.default_workspace)
    end
end

module.config.public = {
    -- The list of active Neorg workspaces.
    --
    -- There is always an inbuilt workspace called `default`, whose location is
    -- set to the Neovim current working directory on boot.
    workspaces = {
        default = vim.fn.getcwd(),
    },
    -- The name for the index file.
    --
    -- The index file is the "entry point" for all of your notes.
    index = "index.norg",
    -- The default workspace to set whenever Neovim starts.
    default_workspace = nil,
    -- Whether to open the last workspace's index file when `nvim` is executed
    -- without arguments.
    --
    -- May also be set to the string `"default"`, due to which Neorg will always
    -- open up the index file for the workspace defined in `default_workspace`.
    open_last_workspace = false,
    -- Whether to use core.ui.text_popup for `dirman.new.note` event.
    -- if `false`, will use vim's default `vim.ui.input` instead.
    use_popup = true,
}

module.private = {
    current_workspace = { "default", vim.fn.getcwd() },
}

---@class core.dirman
module.public = {
    get_workspaces = function()
        return module.config.public.workspaces
    end,
    get_workspace_names = function()
        return vim.tbl_keys(module.config.public.workspaces)
    end,
    --- If present retrieve a workspace's path by its name, else returns nil
    ---@param name string #The name of the workspace
    get_workspace = function(name)
        return module.config.public.workspaces[name]
    end,
    --- Returns a table in the format { "workspace_name", "path" }
    get_current_workspace = function()
        return module.private.current_workspace
    end,
    --- Sets the workspace to the one specified (if it exists) and broadcasts the workspace_changed event
    ---@return boolean True if the workspace is set correctly, false otherwise
    ---@param ws_name string #The name of a valid namespace we want to switch to
    set_workspace = function(ws_name)
        -- Grab the workspace location
        local workspace = module.config.public.workspaces[ws_name]
        -- Create a new object describing our new workspace
        local new_workspace = { ws_name, workspace }

        -- If the workspace does not exist then error out
        if not workspace then
            log.warn("Unable to set workspace to", workspace, "- that workspace does not exist")
            return false
        end

        -- Create the workspace directory if not already present
        vim.fn.mkdir(workspace, "p")

        -- Cache the current workspace
        local current_ws = vim.deepcopy(module.private.current_workspace)

        -- Set the current workspace to the new workspace object we constructed
        module.private.current_workspace = new_workspace

        if ws_name ~= "default" then
            module.required["core.storage"].store("last_workspace", ws_name)
        end

        -- Broadcast the workspace_changed event with all the necessary information
        modules.broadcast_event(
            assert(
                modules.create_event(
                    module,
                    "core.dirman.events.workspace_changed",
                    { old = current_ws, new = new_workspace }
                )
            )
        )

        return true
    end,
    --- Dynamically defines a new workspace if the name isn't already occupied and broadcasts the workspace_added event
    ---@return boolean True if the workspace is added successfully, false otherwise
    ---@param workspace_name string #The unique name of the new workspace
    ---@param workspace_path string #A full path to the workspace root
    add_workspace = function(workspace_name, workspace_path)
        -- If the module already exists then bail
        if module.config.public.workspaces[workspace_name] then
            return false
        end

        -- Set the new workspace and its path accordingly
        module.config.public.workspaces[workspace_name] = workspace_path
        -- Broadcast the workspace_added event with the newly added workspace as the content
        modules.broadcast_event(
            assert(
                modules.create_event(module, "core.dirman.events.workspace_added", { workspace_name, workspace_path })
            )
        )

        -- Sync autocompletions so the user can see the new workspace
        module.public.sync()

        return true
    end,
    --- If the file we opened is within a workspace directory, returns the name of the workspace, else returns nil
    get_workspace_match = function()
        -- Cache the current working directory
        module.config.public.workspaces.default = vim.fn.getcwd()

        -- Grab the working directory of the current open file
        local realcwd = vim.fn.expand("%:p:h")

        -- Store the length of the last match
        local last_length = 0

        -- The final result
        local result = ""

        -- Find a matching workspace
        for workspace, location in pairs(module.config.public.workspaces) do
            if workspace ~= "default" then
                -- Expand all special symbols like ~ etc. and escape special characters
                local expanded = string.gsub(vim.fn.expand(location), "%p", "%%%1") ---@diagnostic disable-line -- TODO: type error workaround <pysan3>

                -- If the workspace location is a parent directory of our current realcwd
                -- or if the ws location is the same then set it as the real workspace
                -- We check this last_length here because if a match is longer
                -- than the previous one then we can say it is a much more precise
                -- match and hence should be prioritized
                if realcwd:find(expanded) and #expanded > last_length then ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
                    -- Set the result to the workspace name
                    result = workspace
                    -- Set the last_length variable to the new length
                    last_length = #expanded
                end
            end
        end

        return result:len() ~= 0 and result or "default"
    end,
    --- Uses the `get_workspace_match()` function to determine the root of the workspace based on the
    --- current working directory, then changes into that workspace
    set_closest_workspace_match = function()
        -- Get the closest workspace match
        local ws_match = module.public.get_workspace_match()

        -- If that match exists then set the workspace to it!
        if ws_match then
            module.public.set_workspace(ws_match)
        else
            -- Otherwise try to reset the workspace to the default
            module.public.set_workspace("default")
        end
    end,
    --- Updates completions for the :Neorg command
    sync = function()
        -- Get all the workspace names
        local workspace_names = module.public.get_workspace_names()

        -- Add the command to core.neorgcmd so it can be used by the user!
        modules.await("core.neorgcmd", function(neorgcmd)
            neorgcmd.add_commands_from_table({
                workspace = {
                    max_args = 1,
                    name = "dirman.workspace",
                    complete = { workspace_names },
                },
            })
        end)
    end,

    ---@class core.dirman.create_file_opts
    ---@field no_open? boolean do not open the file after creation?
    ---@field force? boolean overwrite file if it already exists?
    ---@field metadata? core.esupports.metagen.metadata metadata fields, if provided inserts metadata - an empty table uses default values

    --- Takes in a path (can include directories) and creates a .norg file from that path
    ---@param path string a path to place the .norg file in
    ---@param workspace? string workspace name
    ---@param opts? core.dirman.create_file_opts additional options
    create_file = function(path, workspace, opts)
        opts = opts or {}

        -- Grab the current workspace's full path
        local fullpath

        if workspace ~= nil then
            fullpath = module.public.get_workspace(workspace)
        else
            fullpath = module.public.get_current_workspace()[2]
        end

        if fullpath == nil then
            log.error("Error in fetching workspace path")
            return
        end

        -- Split the path at every /
        local split = vim.split(vim.trim(path), config.pathsep, true) ---@diagnostic disable-line -- TODO: type error workaround <pysan3>

        -- If the last element is empty (i.e. if the string provided ends with '/') then trim it
        if split[#split]:len() == 0 then
            split = vim.list_slice(split, 0, #split - 1)
        end

        -- Go through each directory (excluding the actual file name) and create each directory individually
        for _, element in ipairs(vim.list_slice(split, 0, #split - 1)) do
            vim.loop.fs_mkdir(fullpath .. config.pathsep .. element, 16877)
            fullpath = fullpath .. config.pathsep .. element
        end

        -- If the provided filepath ends in .norg then don't append the filetype automatically
        local fname = fullpath .. config.pathsep .. split[#split]
        if not vim.endswith(path, ".norg") then
            fname = fname .. ".norg"
        end

        -- Create the file
        local fd = vim.loop.fs_open(fname, opts.force and "w" or "a", 438)
        if fd then
            vim.loop.fs_close(fd)
        end

        local bufnr = module.public.get_file_bufnr(fname)
        modules.broadcast_event(
            assert(modules.create_event(module, "core.dirman.events.file_created", { buffer = bufnr, opts = opts }))
        )

        if not opts.no_open then
            -- Begin editing that newly created file
            vim.cmd("e " .. fname .. "| w")
        end
    end,

    --- Takes in a workspace name and a path for a file and opens it
    ---@param workspace_name string #The name of the workspace to use
    ---@param path string #A path to open the file (e.g directory/filename.norg)
    open_file = function(workspace_name, path)
        local workspace = module.public.get_workspace(workspace_name)

        if workspace == nil then
            return
        end

        vim.cmd("e " .. workspace .. config.pathsep .. path .. " | w")
    end,
    --- Reads the neorg_last_workspace.txt file and loads the cached workspace from there
    set_last_workspace = function()
        -- Attempt to open the last workspace cache file in read-only mode
        local storage = modules.get_module("core.storage")

        if not storage then
            log.trace("Module `core.storage` not loaded, refusing to load last user's workspace.")
            return
        end

        local last_workspace = storage.retrieve("last_workspace")
        last_workspace = type(last_workspace) == "string" and last_workspace
            or module.config.public.default_workspace
            or ""

        local workspace_path = module.public.get_workspace(last_workspace)

        if not workspace_path then
            log.trace("Unable to switch to workspace '" .. last_workspace .. "'. The workspace does not exist.")
            return
        end

        -- If we were successful in switching to that workspace then begin editing that workspace's index file
        if module.public.set_workspace(last_workspace) then
            vim.cmd("e " .. workspace_path .. config.pathsep .. module.config.public.index)

            utils.notify("Last Workspace -> " .. workspace_path)
        end
    end,
    --- Checks for file existence by supplying a full path in `filepath`
    ---@param filepath string
    file_exists = function(filepath)
        local f = io.open(filepath, "r")

        if f ~= nil then
            f:close()
            return true
        else
            return false
        end
    end,
    --- Get the bufnr for a `filepath` (full path)
    ---@param filepath string
    get_file_bufnr = function(filepath)
        if module.public.file_exists(filepath) then
            local uri = vim.uri_from_fname(filepath)
            return vim.uri_to_bufnr(uri)
        end
    end,
    --- Returns a list of all files relative path from a `workspace_name`
    ---@param workspace_name string
    ---@return table?
    get_norg_files = function(workspace_name)
        local res = {}
        local workspace = module.public.get_workspace(workspace_name)

        if not workspace then
            return
        end

        local scanned_dir = vim.fs.dir(workspace, { depth = 20 })

        for name, type in scanned_dir do
            if type == "file" and vim.endswith(name, ".norg") then
                table.insert(res, workspace .. config.pathsep .. name)
            end
        end

        return res
    end,
    --- Sets the current workspace and opens that workspace's index file
    ---@param workspace string #The name of the workspace to open
    open_workspace = function(workspace)
        -- If we have, then query that workspace
        local ws_match = module.public.get_workspace(workspace)

        -- If the workspace does not exist then give the user a nice error and bail
        if not ws_match then
            log.error('Unable to switch to workspace - "' .. workspace .. '" does not exist')
            return
        end

        -- Set the workspace to the one requested
        module.public.set_workspace(workspace)

        -- If we're switching to a workspace that isn't the default workspace then enter the index file
        if workspace ~= "default" then
            vim.cmd("e " .. ws_match .. config.pathsep .. module.config.public.index)
        end
    end,
    --- Touches a file in workspace
    --- TODO: make the touch file recursive
    ---@param path string
    ---@param workspace string
    touch_file = function(path, workspace)
        vim.validate({
            path = { path, "string" },
            workspace = { workspace, "string" },
        })

        local ws_match = module.public.get_workspace(workspace)

        if not workspace then
            return false
        end

        local file = io.open(ws_match .. config.pathsep .. path, "w")

        if not file then
            return false
        end

        file:write("")
        file:close()
        return true
    end,
    get_index = function()
        return module.config.public.index
    end,
}

module.on_event = function(event)
    -- If somebody has executed the :Neorg workspace command then
    if event.type == "core.neorgcmd.events.dirman.workspace" then
        -- Have we supplied an argument?
        if event.content[1] then
            module.public.open_workspace(event.content[1])

            vim.schedule(function()
                local new_workspace = module.public.get_workspace(event.content[1])

                if not new_workspace then
                    return
                end

                utils.notify("New Workspace: " .. event.content[1] .. " -> " .. new_workspace)
            end)
        else -- No argument supplied, simply print the current workspace
            -- Query the current workspace
            local current_ws = module.public.get_current_workspace()
            -- Nicely print it. We schedule_wrap here because people with a configured logger will have this message
            -- silenced by other trace logs
            vim.schedule(function()
                utils.notify("Current Workspace: " .. current_ws[1] .. " -> " .. current_ws[2])
            end)
        end
    end

    -- If somebody has executed the :Neorg index command then
    if event.type == "core.neorgcmd.events.dirman.index" then
        local current_ws = module.public.get_current_workspace()

        local index_path = table.concat({ current_ws[2], "/", module.config.public.index })

        if vim.fn.filereadable(index_path) == 0 then
            if current_ws[1] == "default" then
                utils.notify(table.concat({
                    "Index file will not be created in 'default' workspace to avoid confusion.",
                    "If this is intentional, manually create an index file beforehand to use this command.",
                }, " "))
                return
            end
            if not module.public.touch_file(module.config.public.index, module.public.get_current_workspace()[1]) then
                utils.notify(
                    table.concat({
                        "Unable to create '",
                        module.config.public.index,
                        "' in the current workspace - are your filesystem permissions set correctly?",
                    }),
                    vim.log.levels.WARN
                )
                return
            end
        end

        vim.cmd.edit(index_path)
        return
    end

    -- If the user has executed a keybind to create a new note then create a prompt
    if event.type == "core.keybinds.events.core.dirman.new.note" then
        if module.config.public.use_popup then
            module.required["core.ui"].create_prompt("NeorgNewNote", "New Note: ", function(text)
                -- Create the file that the user has entered
                module.public.create_file(text)
            end, {
                center_x = true,
                center_y = true,
            }, {
                width = 25,
                height = 1,
                row = 10,
                col = 0,
            })
        else
            vim.ui.input({ prompt = "New Note: " }, function(text)
                if text ~= nil and #text > 0 then
                    module.public.create_file(text)
                end
            end)
        end
    end
end

module.events.defined = {
    workspace_changed = modules.define_event(module, "workspace_changed"),
    workspace_added = modules.define_event(module, "workspace_added"),
    workspace_cache_empty = modules.define_event(module, "workspace_cache_empty"),
    file_created = modules.define_event(module, "file_created"),
}

module.events.subscribed = {
    ["core.autocommands"] = {
        bufenter = true,
    },
    ["core.dirman"] = {
        workspace_changed = true,
    },
    ["core.neorgcmd"] = {
        ["dirman.workspace"] = true,
        ["dirman.index"] = true,
    },
    ["core.keybinds"] = {
        ["core.dirman.new.note"] = true,
    },
}

return module
