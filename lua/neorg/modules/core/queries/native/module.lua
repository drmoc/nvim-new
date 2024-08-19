--[[
    file: Queries-Module
    title: Queries Made Easy
    summary: TS wrapper in order to fetch nodes using a custom table.
    internal: true
    ---
The `core.queries.native` module provides useful Treesitter wrappers
to query information from Norg documents.
--]]

local neorg = require("neorg.core")
local lib, log, modules = neorg.lib, neorg.log, neorg.modules

---@class core.queries.native.tree_node
---@field query string[]
---@field subtree core.queries.native.tree_node[]|nil
---@field recursive boolean|nil

local module = modules.create("core.queries.native")

module.setup = function()
    return {
        success = true,
        requires = { "core.integrations.treesitter" },
    }
end

module.examples = {
    ["Get the content of all todo_item1 in a norg file"] = function()
        local buf = 1 -- The buffer to query informations

        --- @type core.queries.native.tree_node[]
        local tree = {
            {
                query = { "first", "document_content" },
                subtree = {
                    {
                        query = { "all", "generic_list" },
                        recursive = true,
                        subtree = {
                            {
                                query = { "all", "todo_item1" },
                            },
                        },
                    },
                },
            },
        }

        -- Get a list of { node, buf }
        local nodes = module.required["core.queries.native"].query_nodes_from_buf(tree, buf)
        local extracted_nodes = module.required["core.queries.native"].extract_nodes(nodes)

        -- Free the text in memory after reading nodes
        module.required["core.queries.native"].delete_content(buf)

        print(nodes, extracted_nodes)
    end,
}

---@class core.queries.native
module.public = {
    --- Recursively generates results from a `parent` node, following a `tree` table
    --- @see First implementation in: https://github.com/danymat/neogen/blob/main/lua/neogen/utilities/nodes.lua
    ---@param parent userdata
    ---@param tree core.queries.native.tree_node
    ---@param results table|nil
    ---@return table
    query_from_tree = function(parent, tree, bufnr, results)
        local res = results or {}

        for _, subtree in pairs(tree) do
            local matched, how_to_fix = module.private.matching_nodes(parent, subtree, bufnr)

            if type(matched) == "string" then
                log.error(
                    "Oh no! There's been an error in the query. It seems that we've received some malformed input at one of the subtrees present in parent node of type",
                    parent:type() ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
                )
                log.error("Here's the error message:", matched)

                if how_to_fix then
                    log.warn("To fix the issue:", vim.trim(how_to_fix))
                end

                return ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
            end

            -- We extract matching nodes that doesn't have subtree
            if not subtree.subtree then
                for _, v in pairs(matched) do
                    table.insert(res, { v, bufnr })
                end
            else
                for _, node in pairs(matched) do
                    local nodes = module.public.query_from_tree(node, subtree.subtree, bufnr, res)

                    if not nodes then
                        return {}
                    end

                    res = vim.tbl_extend("force", res, nodes)
                end
            end
        end

        return res
    end,

    --- Use a `tree` to query all required nodes from a `bufnr`. Returns a list of nodes of type { node, bufnr }
    ---@param tree core.queries.native.tree_node
    ---@param bufnr number
    ---@return table
    query_nodes_from_buf = function(tree, bufnr)
        local temp_buf = module.public.get_temp_buf(bufnr)
        local root_node = module.required["core.integrations.treesitter"].get_document_root(temp_buf)
        if not root_node then
            return {}
        end

        local res = module.public.query_from_tree(root_node, tree, bufnr)
        return res
    end,

    --- Extract content from `nodes` of type { node, bufnr }
    ---@param nodes table
    ---@param opts table
    ---   - opts.all_lines (bool)    if true, will return all lines instead of the first one
    ---@return table
    extract_nodes = function(nodes, opts)
        opts = opts or {}
        local res = {}

        for _, node in ipairs(nodes) do
            local temp_buf = module.public.get_temp_buf(node[2])
            local extracted = vim.split(vim.treesitter.get_node_text(node[1], temp_buf), "\n")

            if opts.all_lines then
                table.insert(res, extracted)
            else
                table.insert(res, extracted[1])
            end
        end
        return res
    end,

    --- Find the parent `node` that match `node_type`. Returns a node of type { node, bufnr }.
    --- If `opts.multiple`, returns a table of parent nodes that mached `node_type`
    --- `node` must be of type { node, bufnr }
    ---@param node table
    ---@param node_type string
    ---@param opts table
    ---   - opts.multiple (bool):  if true, will return all recursive parent nodes that match `node_type`
    ---@return table
    find_parent_node = function(node, node_type, opts)
        vim.validate({
            node = { node, "table" },
            node_type = { node_type, "string" },
            opts = { opts, "table", true },
        })

        opts = opts or {}
        local res = {}
        local parent = node[1]:parent()
        while parent do
            if parent:type() == node_type then
                table.insert(res, { parent, node[2] })
                if not opts.multiple then
                    return res[1]
                end
            end
            parent = parent:parent()
        end
        return res
    end,

    --- Creates an unlisted temp buffer reading from the original bufnr.
    --- This does prevent triggering norg autocommands
    ---@param buf number #The bufnr to get text from
    ---@param opts table? #Custom options
    ---   - opts.no_force_read boolean? #If true, will not read original buffer if it fails to open
    ---@return number #The temporary bufnr
    get_temp_buf = function(buf, opts)
        opts = opts or {}
        -- If we don't have any previous private data, get the file text
        if not module.private.data.temp_bufs[buf] then
            -- Get the file name from bufnr
            local uri = vim.uri_from_bufnr(buf)
            local fname = vim.uri_to_fname(uri)

            -- Open and read all lines in the file
            local f, err = io.open(fname, "r")
            local lines
            if not f then
                log.warn("Can't read file " .. fname)
                if opts.no_force_read then
                    log.error(err)
                    return ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
                end
                lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            else
                lines = f:read("*a") or ""
                lines = vim.split(lines, "\n")
                if lines[#lines] == "" then
                    --vim.split automatically adds an empty line because the file stops with a newline
                    table.remove(lines)
                end
                f:close()
            end

            -- Stores the lines in a temp buffer
            local temp_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, lines)
            vim.api.nvim_buf_attach(temp_buf, false, {
                on_lines = function()
                    module.private.data.temp_bufs[buf].changed = true
                end,
            })
            module.private.data.temp_bufs[buf] = { buf = temp_buf, changed = false }
        end

        return module.private.data.temp_bufs[buf].buf
    end,

    apply_temp_changes = function(buf)
        local temp_buf = module.private.data.temp_bufs[buf]
        if temp_buf and temp_buf.changed then
            -- Write the lines to original file
            local lines = vim.api.nvim_buf_get_lines(temp_buf.buf, 0, -1, false)
            local uri = vim.uri_from_bufnr(buf)
            local fname = vim.uri_to_fname(uri)

            lib.when(vim.fn.bufloaded(buf) == 1, function()
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                vim.api.nvim_buf_call(buf, lib.wrap(vim.cmd, "write!")) ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
            end, lib.wrap(vim.fn.writefile, lines, fname))

            -- We reset the state as false because we are consistent with the original file
            temp_buf.changed = false
        end
    end,

    --- Deletes the content from data.
    --- If no buffer is provided, will delete every buffer datas
    --- @overload fun()
    ---@param buf number #The content relative to the provided buffer
    delete_content = function(buf)
        lib.when(buf, function() ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
            module.private.data.temp_bufs[buf] = nil
        end, function()
            module.private.data.temp_bufs = {}
        end)
    end,
}

module.private = {
    data = {
        -- Must be a table of keys like buffer = string_content
        temp_bufs = {},
    },

    --- Returns a list of child nodes (from `parent`) that matches a `tree`
    ---@param parent userdata
    ---@param tree core.queries.native.tree_node
    ---@return table
    matching_nodes = function(parent, tree, bufnr)
        local res = {}
        local where = tree.where ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
        local matched_query, how_to_fix =
            module.private.matching_query(parent, tree.query, { recursive = tree.recursive })

        if type(matched_query) == "string" then
            return matched_query, how_to_fix ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
        end

        if not where then
            return matched_query
        else
            for _, matched in pairs(matched_query) do
                local matched_where = module.private.predicate_where(matched, where, { bufnr = bufnr })
                if matched_where then
                    table.insert(res, matched)
                end
            end
        end

        return res
    end,

    --- Get a list of child nodes (from `parent`) that match the provided `query`
    --- @see First implementation in: https://github.com/danymat/neogen/blob/main/lua/neogen/utilities/nodes.lua
    ---@param parent userdata
    ---@param query table
    ---@param opts table
    ---   - opts.recursive (bool):      if true will recursively find the matching query
    ---@return table | any, any ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
    matching_query = function(parent, query, opts)
        vim.validate({
            parent = { parent, "userdata" },
            query = { query, "table" },
            opts = { opts, "table", true },
        })
        opts = opts or {}
        local res = {}

        if not query then
            return "No 'queries' value present in the query object!",
                [[
Be sure to supply a query parameter, one that looks as such:
{
    query = { "all", "heading1" }, -- You can use any node type here
}
            ]]
        end

        if vim.fn.len(query) < 2 then
            return "Not enough queries supplied! Expected at least 2 but got " .. tostring(#query),
                ([[
Be sure to supply a second parameter, that being the type of node you would like to operate on.
You should change your line to something like:
{
    query = { "%s", "heading1" }
}
Instead.
            ]]):format(query[1] or "all")
        end

        if not vim.tbl_contains({ "all", "first", "match" }, query[1]) then
            return "Syntax error: " .. query[1] .. " is not a valid node operation.",
                ([[
Use a supported node operation. Neorg currently supports "all", "first" and "match".
With that in mind, you can do something like this (for example):
{
    query = { "all", "%s" }
}
            ]]):format(query[2])
        end

        -------------------------

        for node in parent:iter_children() do ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
            if node:type() == query[2] then
                -- query : { "first", "node_name"} first child node that match node_name
                if query[1] == "first" then
                    table.insert(res, node)
                    break
                    -- query : { "match", "node_name", "test" } all node_name nodes that match "test" content
                    -- elseif query[1] == "match" then
                    -- TODO Match node content
                    -- query : { "all", "node_name" } all child nodes that match node_name
                elseif query[1] == "all" then
                    table.insert(res, node)
                end
            end

            if opts.recursive then
                local found = module.private.matching_query(node, query, { recursive = true })
                vim.list_extend(res, found)
            end
        end

        return res
    end,

    --- Checks if `parent` node matches a `where` query and returns a predicate accordingly
    ---@param parent userdata
    ---@param where table
    ---@param opts table
    ---   - opts.bufnr (number):    used in where[1] == "child_content" (in order to get the node's content)
    ---@return boolean
    predicate_where = function(parent, where, opts)
        opts = opts or {}

        if not where or #where == 0 then
            return true
        end

        -- Where statements requesting children nodes from parent node
        for node in parent:iter_children() do ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
            if where[1] == "child_exists" then
                if node:type() == where[2] then
                    return true
                end
            end

            if where[1] == "child_content" then
                local temp_buf = module.public.get_temp_buf(opts.bufnr)
                if
                    node:type() == where[2]
                    and vim.split(vim.treesitter.query.get_node_text(node, temp_buf), "\n")[1] == where[3] ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
                then
                    return true
                end
            end
        end

        return false
    end,
}

return module
