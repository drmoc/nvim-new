--[[
    file: Concealer
    title: Display Markup as Icons, not Text
    description: The concealer module converts verbose markup elements into beautified icons for your viewing pleasure.
    summary: Enhances the basic Neorg experience by using icons instead of text.
    embed: https://user-images.githubusercontent.com/76052559/216767027-726b451d-6da1-4d09-8fa4-d08ec4f93f54.png
    ---
"Concealing" is the process of hiding away from plain sight. When writing raw Norg, long strings like
`***** Hello` or `$$ Definition` can be distracting and sometimes unpleasant when sifting through large notes.

To reduce the amount of cognitive load required to "parse" Norg documents with your own eyes, this module
masks, or sometimes completely hides many categories of markup.

The concealer depends on [Nerd Fonts >=v3.0.1](https://github.com/ryanoasis/nerd-fonts/releases/latest) to be
installed on your system.
--]]

-- utils  to be refactored

local neorg = require("neorg.core")
local lib, log, modules, utils = neorg.lib, neorg.log, neorg.modules, neorg.utils

local function in_range(k, l, r_ex)
    return l <= k and k < r_ex
end

local function is_concealing_on_row_range(mode, conceallevel, concealcursor, current_row_0b, row_start_0b, row_end_0bex)
    if conceallevel < 1 then
        return false
    elseif not in_range(current_row_0b, row_start_0b, row_end_0bex) then
        return true
    else
        return (concealcursor:find(mode) ~= nil)
    end
end

local function table_extend_in_place(tbl, tbl_ext)
    for k, v in pairs(tbl_ext) do
        tbl[k] = v
    end
end

local function get_node_position_and_text_length(bufid, node)
    local row_start_0b, col_start_0b = node:range()

    -- FIXME parser: multi_definition_suffix, weak_paragraph_delimiter should not span across lines
    -- assert(row_start_0b == row_end_0bin, row_start_0b .. "," .. row_end_0bin)
    local text = vim.treesitter.get_node_text(node, bufid)
    local past_end_offset_1b = text:find("%s") or text:len() + 1
    return row_start_0b, col_start_0b, (past_end_offset_1b - 1)
end

local function get_header_prefix_node(header_node)
    local first_child = header_node:child(0)
    assert(first_child:type() == header_node:type() .. "_prefix")
    return first_child
end

local function get_line_length(bufid, row_0b)
    return vim.api.nvim_strwidth(vim.api.nvim_buf_get_lines(bufid, row_0b, row_0b + 1, true)[1])
end

--- end utils

--- TODO: Migrate to `vim.version` when `0.10.0` becomes stable
local has_anticonceal = (function()
    if not utils.is_minimum_version(0, 10, 0) then
        return false
    end

    if utils.is_minimum_version(0, 10, 1) then
        return true
    end

    local full_version = vim.api.nvim_cmd({ cmd = "version" }, { output = true })
    local _, _, sub_version = string.find(full_version, "-(%d+)[+]")
    if not sub_version then
        return true
    end -- no longer a dev version
    sub_version = tonumber(sub_version)
    return sub_version and sub_version > 575
end)()

local module = modules.create("core.concealer", {
    "preset_basic",
    "preset_varied",
    "preset_diamond",
})

module.setup = function()
    return {
        success = true,
        requires = {
            "core.autocommands",
            "core.integrations.treesitter",
        },
    }
end

module.private = {
    ns_icon = vim.api.nvim_create_namespace("neorg-conceals"),
    ns_prettify_flag = vim.api.nvim_create_namespace("neorg-conceals.prettify-flag"),
    rerendering_scheduled_bufids = {},
    enabled = true,
    cursor_record = {},
}

local function set_mark(bufid, row_0b, col_0b, text, highlight, ext_opts)
    local ns_icon = module.private.ns_icon
    local opt = {
        virt_text = { { text, highlight } },
        virt_text_pos = "overlay",
        virt_text_win_col = nil,
        hl_group = nil,
        conceal = nil,
        id = nil,
        end_row = row_0b,
        end_col = col_0b,
        hl_eol = nil,
        virt_text_hide = nil,
        hl_mode = "combine",
        virt_lines = nil,
        virt_lines_above = nil,
        virt_lines_leftcol = nil,
        ephemeral = nil,
        right_gravity = nil,
        end_right_gravity = nil,
        priority = nil,
        strict = nil, -- default true
        sign_text = nil,
        sign_hl_group = nil,
        number_hl_group = nil,
        line_hl_group = nil,
        cursorline_hl_group = nil,
        spell = nil,
        ui_watched = nil,
    }

    if ext_opts then
        table_extend_in_place(opt, ext_opts)
    end

    vim.api.nvim_buf_set_extmark(bufid, ns_icon, row_0b, col_0b, opt)
end

local function table_get_default_last(tbl, index)
    return tbl[index] or tbl[#tbl]
end

local prettify_icon_table = {
    numeric = { "1", "2", "3", "4", "5", "6", "7", "8", "9" },
    numeric_dot = {
        "⒈",
        "⒉",
        "⒊",
        "⒋",
        "⒌",
        "⒍",
        "⒎",
        "⒏",
        "⒐",
        "⒑",
        "⒒",
        "⒓",
        "⒔",
        "⒕",
        "⒖",
        "⒗",
        "⒘",
        "⒙",
        "⒚",
        "⒛",
    },
    numeric_pareneses = {
        "⑴",
        "⑵",
        "⑶",
        "⑷",
        "⑸",
        "⑹",
        "⑺",
        "⑻",
        "⑼",
        "⑽",
        "⑾",
        "⑿",
        "⒀",
        "⒁",
        "⒂",
        "⒃",
        "⒄",
        "⒅",
        "⒆",
        "⒇",
    },
    numeric_circled = {
        "①",
        "②",
        "③",
        "④",
        "⑤",
        "⑥",
        "⑦",
        "⑧",
        "⑨",
        "⑩",
        "⑪",
        "⑫",
        "⑬",
        "⑭",
        "⑮",
        "⑯",
        "⑰",
        "⑱",
        "⑲",
        "⑳",
    },
    latin_lowercase = {
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z",
    },
    latin_uppercase = {
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I",
        "J",
        "K",
        "L",
        "M",
        "N",
        "O",
        "P",
        "Q",
        "R",
        "S",
        "T",
        "U",
        "V",
        "W",
        "X",
        "Y",
        "Z",
    },
    latin_lowercase_parentheses = {
        "⒜",
        "⒝",
        "⒞",
        "⒟",
        "⒠",
        "⒡",
        "⒢",
        "⒣",
        "⒤",
        "⒥",
        "⒦",
        "⒧",
        "⒨",
        "⒩",
        "⒪",
        "⒫",
        "⒬",
        "⒭",
        "⒮",
        "⒯",
        "⒰",
        "⒱",
        "⒲",
        "⒳",
        "⒴",
        "⒵",
    },
    latin_uppercase_circled = {
        "Ⓐ",
        "Ⓑ",
        "Ⓒ",
        "Ⓓ",
        "Ⓔ",
        "Ⓕ",
        "Ⓖ",
        "Ⓗ",
        "Ⓘ",
        "Ⓙ",
        "Ⓚ",
        "Ⓛ",
        "Ⓜ",
        "Ⓝ",
        "Ⓞ",
        "Ⓟ",
        "Ⓠ",
        "Ⓡ",
        "Ⓢ",
        "Ⓣ",
        "Ⓤ",
        "Ⓥ",
        "Ⓦ",
        "Ⓧ",
        "Ⓨ",
        "Ⓩ",
    },
    latin_lowercase_circled = {
        "ⓐ",
        "ⓑ",
        "ⓒ",
        "ⓓ",
        "ⓔ",
        "ⓕ",
        "ⓖ",
        "ⓗ",
        "ⓘ",
        "ⓙ",
        "ⓚ",
        "ⓛ",
        "ⓜ",
        "ⓝ",
        "ⓞ",
        "ⓟ",
        "ⓠ",
        "ⓡ",
        "ⓢ",
        "ⓣ",
        "ⓤ",
        "ⓥ",
        "ⓦ",
        "ⓧ",
        "ⓨ",
        "ⓩ",
    },
}

local function get_number_table(initial_number)
    -- TODO: error handling
    for _, number_table in pairs(prettify_icon_table) do
        if number_table[1] == initial_number then
            return number_table
        end
    end
end

local function get_ordered_index(bufid, prefix_node)
    -- TODO: calculate levels in one pass, since treesitter API implementation seems to have ridiculously high complexity
    local _, _, level = get_node_position_and_text_length(bufid, prefix_node)
    local header_node = prefix_node:parent()
    -- TODO: fix parser: `(ERROR)` on standalone prefix not followed by text, like `- `
    -- assert(header_node:type() .. "_prefix" == prefix_node:type())
    local sibling = header_node:prev_named_sibling()
    local count = 1

    while sibling and (sibling:type() == header_node:type()) do
        local _, _, sibling_level = get_node_position_and_text_length(bufid, get_header_prefix_node(sibling))
        if sibling_level < level then
            break
        elseif sibling_level == level then
            count = count + 1
        end
        sibling = sibling:prev_named_sibling()
    end

    return count, (sibling or header_node:parent())
end

local superscript_digits = {
    "⁰",
    "¹",
    "²",
    "³",
    "⁴",
    "⁵",
    "⁶",
    "⁷",
    "⁸",
    "⁹",
}

---@class core.concealer
module.public = {
    foldtext = function()
        local foldstart = vim.v.foldstart
        local line = vim.api.nvim_buf_get_lines(0, foldstart - 1, foldstart, true)[1]

        return lib.match(line, function(lhs, rhs)
            return vim.startswith(lhs, rhs)
        end)({
            ["@document.meta"] = "Document Metadata",
            _ = function()
                local line_length = vim.api.nvim_strwidth(line)

                local icon_extmarks = vim.api.nvim_buf_get_extmarks(
                    0,
                    module.private.ns_icon,
                    { foldstart - 1, 0 },
                    { foldstart - 1, line_length },
                    {
                        details = true,
                    }
                )

                for _, extmark in ipairs(icon_extmarks) do
                    local extmark_details = extmark[4]
                    local extmark_column = extmark[3] + (line_length - vim.api.nvim_strwidth(line))

                    for _, virt_text in ipairs(extmark_details.virt_text or {}) do
                        line = line:sub(1, extmark_column)
                            .. virt_text[1]
                            .. line:sub(extmark_column + vim.api.nvim_strwidth(virt_text[1]) + 1)
                        line_length = vim.api.nvim_strwidth(line) - line_length + vim.api.nvim_strwidth(virt_text[1])
                    end
                end

                return line
            end,
        })
    end,

    icon_renderers = {
        on_left = function(config, bufid, node)
            if not config.icon then
                return
            end
            local row_0b, col_0b, len = get_node_position_and_text_length(bufid, node)
            local text = (" "):rep(len - 1) .. config.icon
            set_mark(bufid, row_0b, col_0b, text, config.highlight)
        end,

        footnote_concealed = function(config, bufid, node)
            local link_title_node = node:next_named_sibling()
            local link_title = vim.treesitter.get_node_text(link_title_node, bufid)
            if config.numeric_superscript and link_title:match("%d+") then
                local t = {}
                for i = 1, #link_title do
                    local d = link_title:sub(i, i):byte() - 0x30
                    table.insert(t, superscript_digits[d + 1])
                end
                local superscripted_title = table.concat(t)
                local row_start_0b, col_start_0b, _, _ = link_title_node:range()
                local highlight = config.title_highlight
                set_mark(bufid, row_start_0b, col_start_0b, superscripted_title, highlight)
            end
        end,

        multilevel_on_right = function(config, bufid, node)
            if not config.icons then
                return
            end
            local row_0b, col_0b, len = get_node_position_and_text_length(bufid, node)
            local icon = table_get_default_last(config.icons, len)
            if not icon then
                return
            end
            local text = (" "):rep(len - 1) .. icon
            local highlight = config.highlights and table_get_default_last(config.highlights, len)
            set_mark(bufid, row_0b, col_0b, text, highlight)
        end,

        multilevel_ordered_inline_on_right = function(config, bufid, node)
            if not config.generators then
                return
            end

            local row_0b, col_0b, len = get_node_position_and_text_length(bufid, node)

            local index = get_ordered_index(bufid, node)
            local generator = table_get_default_last(config.generators, len)
            local format = table_get_default_last(config.formatters, len)

            local text = (" "):rep(len - 1) .. string.format(format, generator(index))

            local highlight = config.highlights and table_get_default_last(config.highlights, len)

            set_mark(bufid, row_0b, col_0b, text:sub(1, len), highlight)
            set_mark(bufid, row_0b, col_0b + len, text:sub(len + 1), highlight, {
                virt_text_pos = "inline",
            })
        end,

        multilevel_ordered_on_right = function(config, bufid, node)
            if not config.icons then
                return
            end
            local row_0b, col_0b, len = get_node_position_and_text_length(bufid, node)
            local initial_number = table_get_default_last(config.icons, len)
            if not initial_number then
                return
            end
            local number_table = get_number_table(initial_number)
            if not number_table then
                return
            end -- TODO: warning
            local index = get_ordered_index(bufid, node)
            local text = (" "):rep(len - 1) .. (number_table[index] or "~")
            local highlight = config.highlights and table_get_default_last(config.highlights, len)

            set_mark(bufid, row_0b, col_0b, text, highlight)
        end,

        multilevel_copied = function(config, bufid, node)
            if not config.icons then
                return
            end
            local row_0b, col_0b, len = get_node_position_and_text_length(bufid, node)
            local last_icon, last_highlight
            for i = 1, len do
                if config.icons[i] ~= nil then
                    last_icon = config.icons[i]
                end
                if not last_icon then
                    goto continue
                end
                last_highlight = config.highlights[i] or last_highlight
                set_mark(bufid, row_0b, col_0b + (i - 1), last_icon, last_highlight)
                ::continue::
            end
        end,

        fill_text = function(config, bufid, node)
            if not config.icon then
                return
            end
            local row_0b, col_0b, len = get_node_position_and_text_length(bufid, node)
            local text = config.icon:rep(len)
            set_mark(bufid, row_0b, col_0b, text, config.highlight)
        end,

        fill_multiline_chop2 = function(config, bufid, node)
            if not config.icon then
                return
            end
            local row_start_0b, col_start_0b, row_end_0bin, col_end_0bex = node:range()
            for i = row_start_0b, row_end_0bin do
                local l = i == row_start_0b and col_start_0b + 1 or 0
                local r_ex = i == row_end_0bin and col_end_0bex - 1 or get_line_length(bufid, i)
                set_mark(bufid, i, l, config.icon:rep(r_ex - l), config.highlight)
            end
        end,

        render_horizontal_line = function(config, bufid, node)
            if not config.icon then
                return
            end

            local row_start_0b, col_start_0b, _, col_end_0bex = node:range()
            local render_col_start_0b = config.left == "here" and col_start_0b or 0
            local opt_textwidth = vim.bo[bufid].textwidth
            local render_col_end_0bex = config.right == "textwidth" and (opt_textwidth > 0 and opt_textwidth or 79)
                or vim.api.nvim_win_get_width(vim.fn.bufwinid(bufid))
            local len = math.max(col_end_0bex - col_start_0b, render_col_end_0bex - render_col_start_0b)
            set_mark(bufid, row_start_0b, render_col_start_0b, config.icon:rep(len), config.highlight)
        end,

        render_code_block = function(config, bufid, node)
            local tag_name = vim.treesitter.get_node_text(node:named_child(0), bufid)
            if not (tag_name == "code" or tag_name == "embed") then
                return
            end

            local row_start_0b, col_start_0b, row_end_0bin = node:range()
            assert(row_start_0b < row_end_0bin)
            local conceal_on = (vim.wo.conceallevel >= 2) and config.conceal

            if conceal_on then
                for _, row_0b in ipairs({ row_start_0b, row_end_0bin }) do
                    vim.api.nvim_buf_set_extmark(
                        bufid,
                        module.private.ns_icon,
                        row_0b,
                        0,
                        { end_col = get_line_length(bufid, row_0b), conceal = "" }
                    )
                end
            end

            if conceal_on or config.content_only then
                row_start_0b = row_start_0b + 1
                row_end_0bin = row_end_0bin - 1
            end

            local line_lengths = {}
            local max_len = 0
            for row_0b = row_start_0b, row_end_0bin do
                local len = get_line_length(bufid, row_0b)
                if len > max_len then
                    max_len = len
                end
                table.insert(line_lengths, len)
            end

            local to_eol = (config.width ~= "content")

            for row_0b = row_start_0b, row_end_0bin do
                local len = line_lengths[row_0b - row_start_0b + 1]
                local mark_col_start_0b = math.max(0, col_start_0b - config.padding.left)
                local mark_col_end_0bex = max_len + config.padding.right
                if len >= mark_col_start_0b then
                    vim.api.nvim_buf_set_extmark(bufid, module.private.ns_icon, row_0b, mark_col_start_0b, {
                        end_row = row_0b + 1,
                        hl_eol = to_eol,
                        hl_group = config.highlight,
                        hl_mode = "blend",
                        virt_text = not to_eol and { { (" "):rep(mark_col_end_0bex - len), config.highlight } } or nil,
                        virt_text_pos = "overlay",
                        virt_text_win_col = len,
                        spell = config.spell_check,
                    })
                else
                    vim.api.nvim_buf_set_extmark(bufid, module.private.ns_icon, row_0b, len, {
                        end_row = row_0b + 1,
                        hl_eol = to_eol,
                        hl_group = config.highlight,
                        hl_mode = "blend",
                        virt_text = {
                            { (" "):rep(mark_col_start_0b - len) },
                            { not to_eol and (" "):rep(mark_col_end_0bex - mark_col_start_0b) or "", config.highlight },
                        },
                        virt_text_pos = "overlay",
                        virt_text_win_col = len,
                        spell = config.spell_check,
                    })
                end
            end
        end,
    },

    icon_generators = {
        numeric = function(index)
            return tostring(index)
        end,

        convert_to_base_n = function(vocabulary, number)
            local result = {}

            while number > 0 do
                local remainder = ((number - 1) % #vocabulary) + 1

                table.insert(result, 1, string.sub(vocabulary, remainder, remainder))
                number = math.floor((number - 1) / #vocabulary)
            end

            return table.concat(result)
        end,

        alphanumeric_uppercase = function(index)
            return module.public.icon_generators.convert_to_base_n("ABCDEFGHIJKLMNOPQRSTUVWXYZ", index)
        end,

        alphanumeric_lowercase = function(index)
            return module.public.icon_generators.convert_to_base_n("abcdefghijklmnopqrstuvwxyz", index)
        end,
    },
}

module.config.public = {
    -- Which icon preset to use.
    --
    -- The currently available icon presets are:
    -- - "basic" - use a mixture of icons (includes cute flower icons!)
    -- - "diamond" - use diamond shapes for headings
    -- - "varied" - use a mix of round and diamond shapes for headings; no cute flower icons though :(
    icon_preset = "basic",

    -- If true, Neorg will enable folding by default for `.norg` documents.
    -- You may use the inbuilt Neovim folding options like `foldnestmax`,
    -- `foldlevelstart` and others to then tune the behaviour to your liking.
    --
    -- Set to `false` if you do not want Neorg setting anything.
    folds = true,

    -- When set to `auto`, Neorg will open all folds when opening new documents if `foldlevel` is 0.
    -- When set to `always`, Neorg will always open all folds when opening new documents.
    -- When set to `never`, Neorg will not do anything.
    init_open_folds = "auto",

    -- Configuration for icons.
    --
    -- This table contains the full configuration set for each icon, including
    -- its query (where to be placed), render functions (how to be placed) and
    -- characters to use.
    --
    -- For most use cases, the only values that you should be changing is the `icon`/`icons` field.
    -- `icon` is a string, while `icons` is a table of strings for multilevel elements like
    -- headings, lists, and quotes.
    --
    -- To disable part of the config, replace the table with `false`, or prepend `false and` to it.
    -- For example: `done = false` or `done = false and { ... }`.
    icons = {
        todo = {
            done = {
                icon = "󰄬",
                nodes = { "todo_item_done" },
                render = module.public.icon_renderers.on_left,
            },
            pending = {
                icon = "󰥔",
                nodes = { "todo_item_pending" },
                render = module.public.icon_renderers.on_left,
            },
            undone = {
                icon = "×",
                nodes = { "todo_item_undone" },
                render = module.public.icon_renderers.on_left,
            },
            uncertain = {
                icon = "",
                nodes = { "todo_item_uncertain" },
                render = module.public.icon_renderers.on_left,
            },
            on_hold = {
                icon = "",
                nodes = { "todo_item_on_hold" },
                render = module.public.icon_renderers.on_left,
            },
            cancelled = {
                icon = "",
                nodes = { "todo_item_cancelled" },
                render = module.public.icon_renderers.on_left,
            },
            recurring = {
                icon = "↺",
                nodes = { "todo_item_recurring" },
                render = module.public.icon_renderers.on_left,
            },
            urgent = {
                icon = "⚠",
                nodes = { "todo_item_urgent" },
                render = module.public.icon_renderers.on_left,
            },
        },

        list = {
            icons = { "•" },
            nodes = {
                "unordered_list1_prefix",
                "unordered_list2_prefix",
                "unordered_list3_prefix",
                "unordered_list4_prefix",
                "unordered_list5_prefix",
                "unordered_list6_prefix",
            },
            render = module.public.icon_renderers.multilevel_on_right,
        },
        ordered = {
            icons = (not has_anticonceal) and { "⒈", "A", "a", "⑴", "Ⓐ", "ⓐ" } or nil,
            nodes = {
                "ordered_list1_prefix",
                "ordered_list2_prefix",
                "ordered_list3_prefix",
                "ordered_list4_prefix",
                "ordered_list5_prefix",
                "ordered_list6_prefix",
            },

            --- A list of icon generators.
            ---
            --- Icon generators live in the `icon_generators` namespace. They create
            --- a unique ID for each index in the list. This can be as simple as `1, 2, 3, 4...`
            --- or `A, B, C, D...`, but one could opt for more complex generators.
            generators = {
                module.public.icon_generators.numeric,
                module.public.icon_generators.alphanumeric_uppercase,
                module.public.icon_generators.alphanumeric_lowercase,
                module.public.icon_generators.numeric,
            },

            --- A list of lua patterns specifying how to format each
            --- nesting level of an ordered list.
            ---
            --- `%s` is substituted with the string returned by the `generator`.
            formatters = { "%s.", "%s.", "%s.", "(%s)" },

            render = has_anticonceal and module.public.icon_renderers.multilevel_ordered_inline_on_right
                or module.public.icon_renderers.multilevel_ordered_on_right,
        },
        quote = {
            icons = { "│" },
            nodes = {
                "quote1_prefix",
                "quote2_prefix",
                "quote3_prefix",
                "quote4_prefix",
                "quote5_prefix",
                "quote6_prefix",
            },
            highlights = {
                "@neorg.quotes.1.prefix",
                "@neorg.quotes.2.prefix",
                "@neorg.quotes.3.prefix",
                "@neorg.quotes.4.prefix",
                "@neorg.quotes.5.prefix",
                "@neorg.quotes.6.prefix",
            },
            render = module.public.icon_renderers.multilevel_copied,
        },
        heading = {
            icons = { "◉", "◎", "○", "✺", "▶", "⤷" },
            highlights = {
                "@neorg.headings.1.prefix",
                "@neorg.headings.2.prefix",
                "@neorg.headings.3.prefix",
                "@neorg.headings.4.prefix",
                "@neorg.headings.5.prefix",
                "@neorg.headings.6.prefix",
            },
            nodes = {
                "heading1_prefix",
                "heading2_prefix",
                "heading3_prefix",
                "heading4_prefix",
                "heading5_prefix",
                "heading6_prefix",
                concealed = {
                    "link_target_heading1",
                    "link_target_heading2",
                    "link_target_heading3",
                    "link_target_heading4",
                    "link_target_heading5",
                    "link_target_heading6",
                },
            },
            render = module.public.icon_renderers.multilevel_on_right,
        },
        definition = {
            single = {
                icon = "≡",
                nodes = { "single_definition_prefix", concealed = { "link_target_definition" } },
                render = module.public.icon_renderers.on_left,
            },
            multi_prefix = {
                icon = "⋙ ",
                nodes = { "multi_definition_prefix" },
                render = module.public.icon_renderers.on_left,
            },
            multi_suffix = {
                icon = "⋘ ",
                nodes = { "multi_definition_suffix" },
                render = module.public.icon_renderers.on_left,
            },
        },

        footnote = {
            single = {
                icon = "⁎",
                -- When set to true, footnote link with numeric title will be
                -- concealed to superscripts.
                numeric_superscript = true,
                title_highlight = "@neorg.footnotes.title",
                nodes = { "single_footnote_prefix", concealed = { "link_target_footnote" } },
                render = module.public.icon_renderers.on_left,
                render_concealed = module.public.icon_renderers.footnote_concealed,
            },
            multi_prefix = {
                icon = "⁑ ",
                nodes = { "multi_footnote_prefix" },
                render = module.public.icon_renderers.on_left,
            },
            multi_suffix = {
                icon = "⁑ ",
                nodes = { "multi_footnote_suffix" },
                render = module.public.icon_renderers.on_left,
            },
        },

        delimiter = {
            weak = {
                icon = "⟨",
                highlight = "@neorg.delimiters.weak",
                nodes = { "weak_paragraph_delimiter" },
                render = module.public.icon_renderers.fill_text,
            },
            strong = {
                icon = "⟪",
                highlight = "@neorg.delimiters.strong",
                nodes = { "strong_paragraph_delimiter" },
                render = module.public.icon_renderers.fill_text,
            },
            horizontal_line = {
                icon = "─",
                highlight = "@neorg.delimiters.horizontal_line",
                nodes = { "horizontal_line" },
                -- The starting position of horizontal lines:
                -- - "window": the horizontal line starts from the first column, reaching the left of the window
                -- - "here": the horizontal line starts from the node column
                left = "here",
                -- The ending position of horizontal lines:
                -- - "window": the horizontal line ends at the last column, reaching the right of the window
                -- - "textwidth": the horizontal line ends at column `textwidth` or 79 when it's set to zero
                right = "window",
                render = module.public.icon_renderers.render_horizontal_line,
            },
        },

        markup = {
            spoiler = {
                icon = "•",
                highlight = "@neorg.markup.spoiler",
                nodes = { "spoiler" },
                render = module.public.icon_renderers.fill_multiline_chop2,
            },
        },

        -- Options that control the behaviour of code block dimming
        -- (placing a darker background behind `@code` tags).
        code_block = {
            -- If true will only dim the content of the code block (without the
            -- `@code` and `@end` lines), not the entirety of the code block itself.
            content_only = true,

            -- The width to use for code block backgrounds.
            --
            -- When set to `fullwidth` (the default), will create a background
            -- that spans the width of the buffer.
            --
            -- When set to `content`, will only span as far as the longest line
            -- within the code block.
            width = "fullwidth",

            -- Additional padding to apply to either the left or the right. Making
            -- these values negative is considered undefined behaviour (it is
            -- likely to work, but it's not officially supported).
            padding = {
                left = 0,
                right = 0,
            },

            -- If `true` will conceal (hide) the `@code` and `@end` portion of the code
            -- block.
            conceal = false,

            -- If `false` will disable spell check on code blocks when 'spell' option is switched on.
            spell_check = true,

            nodes = { "ranged_verbatim_tag" },
            highlight = "@neorg.tags.ranged_verbatim.code_block",
            render = module.public.icon_renderers.render_code_block,
            insert_enabled = true,
        },
    },
}

local function pos_eq(pos1, pos2)
    return (pos1.x == pos2.x) and (pos1.y == pos2.y)
end

local function pos_le(pos1, pos2)
    return pos1.x < pos2.x or (pos1.x == pos2.x and pos1.y <= pos2.y)
end

-- local function pos_lt(pos1, pos2)
--     return pos1.x < pos2.x or (pos1.x == pos2.x and pos1.y < pos2.y)
-- end

local function remove_extmarks(bufid, pos_start_0b_0b, pos_end_0bin_0bex)
    assert(pos_le(pos_start_0b_0b, pos_end_0bin_0bex))
    if pos_eq(pos_start_0b_0b, pos_end_0bin_0bex) then
        return
    end

    local ns_icon = module.private.ns_icon
    for _, result in
        ipairs(
            vim.api.nvim_buf_get_extmarks(
                bufid,
                ns_icon,
                { pos_start_0b_0b.x, pos_start_0b_0b.y },
                { pos_end_0bin_0bex.x - ((pos_end_0bin_0bex.y == 0) and 1 or 0), pos_end_0bin_0bex.y - 1 },
                {}
            )
        )
    do
        local extmark_id = result[1]
        local node_pos_0b_0b = { x = result[2], y = result[3] }
        assert(
            pos_le(pos_start_0b_0b, node_pos_0b_0b) and pos_le(node_pos_0b_0b, pos_end_0bin_0bex),
            ("start=%s, end=%s, node=%s"):format(
                vim.inspect(pos_start_0b_0b),
                vim.inspect(pos_end_0bin_0bex),
                vim.inspect(node_pos_0b_0b)
            )
        )
        vim.api.nvim_buf_del_extmark(bufid, ns_icon, extmark_id)
    end
end

local function is_inside_example(_node) ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
    -- TODO: waiting for parser fix
    return false
end

local function should_skip_prettify(mode, current_row_0b, node, config, row_start_0b, row_end_0bex)
    local result
    if config.insert_enabled then
        result = false
    elseif (mode == "i") and in_range(current_row_0b, row_start_0b, row_end_0bex) then
        result = true
    elseif is_inside_example(node) then
        result = true
    else
        result = false
    end
    return result
end

local function query_get_nodes(query, document_root, bufid, row_start_0b, row_end_0bex)
    local result = {}
    local concealed_node_ids = {}
    for id, node in query:iter_captures(document_root, bufid, row_start_0b, row_end_0bex) do
        if node:missing() then
            goto continue
        end
        if query.captures[id] == "icon-concealed" then
            concealed_node_ids[node:id()] = true
        end
        table.insert(result, node)
        ::continue::
    end
    return result, concealed_node_ids
end

local function check_min(xy, x_new, y_new)
    if (x_new < xy.x) or (x_new == xy.x and y_new < xy.y) then
        xy.x = x_new
        xy.y = y_new
    end
end

local function check_max(xy, x_new, y_new)
    if (x_new > xy.x) or (x_new == xy.x and y_new > xy.y) then
        xy.x = x_new
        xy.y = y_new
    end
end

local function add_prettify_flag_line(bufid, row)
    local ns_prettify_flag = module.private.ns_prettify_flag
    vim.api.nvim_buf_set_extmark(bufid, ns_prettify_flag, row, 0, {})
end

local function add_prettify_flag_range(bufid, row_start_0b, row_end_0bex)
    for row = row_start_0b, row_end_0bex - 1 do
        add_prettify_flag_line(bufid, row)
    end
end

local function remove_prettify_flag_on_line(bufid, row_0b)
    -- TODO: optimize
    local ns_prettify_flag = module.private.ns_prettify_flag
    vim.api.nvim_buf_clear_namespace(bufid, ns_prettify_flag, row_0b, row_0b + 1)
end

local function remove_prettify_flag_range(bufid, row_start_0b, row_end_0bex)
    -- TODO: optimize
    local ns_prettify_flag = module.private.ns_prettify_flag
    vim.api.nvim_buf_clear_namespace(bufid, ns_prettify_flag, row_start_0b, row_end_0bex)
end

local function remove_prettify_flag_all(bufid)
    remove_prettify_flag_range(bufid, 0, -1)
end

local function get_visible_line_range(winid)
    local row_start_1b = vim.fn.line("w0", winid)
    local row_end_1b = vim.fn.line("w$", winid)
    return (row_start_1b - 1), row_end_1b
end

local function get_parsed_query_lazy()
    if module.private.prettify_query then
        return module.private.prettify_query
    end

    local keys = { "config", "icons" }
    local function traverse_config(config, f)
        if config == false then
            return
        end
        if config.nodes then
            f(config)
            return
        end
        if type(config) ~= "table" then
            log.warn(("unsupported icon config: %s = %s"):format(table.concat(keys, "."), config))
            return
        end
        local key_pos = #keys + 1
        for key, sub_config in pairs(config) do
            keys[key_pos] = key
            traverse_config(sub_config, f)
            keys[key_pos] = nil
        end
    end

    local config_by_node_name = {}
    local queries = { "[" }

    traverse_config(module.config.public.icons, function(config)
        for _, node_type in ipairs(config.nodes) do
            table.insert(queries, ("(%s)@icon"):format(node_type))
            config_by_node_name[node_type] = config
        end
        for _, node_type in ipairs(config.nodes.concealed or {}) do
            table.insert(queries, ("(%s)@icon-concealed"):format(node_type))
            config_by_node_name[node_type] = config
        end
    end)

    table.insert(queries, "]")
    local query_combined = table.concat(queries, " ")
    module.private.prettify_query = utils.ts_parse_query("norg", query_combined)
    assert(module.private.prettify_query)
    module.private.config_by_node_name = config_by_node_name
    return module.private.prettify_query
end

local function prettify_range(bufid, row_start_0b, row_end_0bex)
    -- in case there's undo/removal garbage
    -- TODO: optimize
    row_end_0bex = math.min(row_end_0bex + 1, vim.api.nvim_buf_line_count(bufid))

    local treesitter_module = module.required["core.integrations.treesitter"]
    local document_root = treesitter_module.get_document_root(bufid)
    assert(document_root)

    local nodes, concealed_node_ids =
        query_get_nodes(get_parsed_query_lazy(), document_root, bufid, row_start_0b, row_end_0bex)

    local pos_start_0b_0b = { x = row_start_0b, y = 0 }
    local pos_end_0bin_0bex = { x = row_end_0bex - 1, y = get_line_length(bufid, row_end_0bex - 1) }

    for i = 1, #nodes do
        check_min(pos_start_0b_0b, nodes[i]:start())
        check_max(pos_end_0bin_0bex, nodes[i]:end_())
    end

    remove_extmarks(bufid, pos_start_0b_0b, pos_end_0bin_0bex)
    remove_prettify_flag_range(bufid, pos_start_0b_0b.x, pos_end_0bin_0bex.x + 1)
    add_prettify_flag_range(bufid, pos_start_0b_0b.x, pos_end_0bin_0bex.x + 1)

    local winid = vim.fn.bufwinid(bufid)
    assert(winid > 0)
    local current_row_0b = vim.api.nvim_win_get_cursor(winid)[1] - 1
    local current_mode = vim.api.nvim_get_mode().mode
    local conceallevel = vim.wo[winid].conceallevel
    local concealcursor = vim.wo[winid].concealcursor

    assert(document_root)

    for _, node in ipairs(nodes) do
        local node_row_start_0b, _, _node_row_end_0bin = node:range()
        local node_row_end_0bex = _node_row_end_0bin + 1
        local config = module.private.config_by_node_name[node:type()]

        if should_skip_prettify(current_mode, current_row_0b, node, config, node_row_start_0b, node_row_end_0bex) then
            goto continue
        end

        local has_conceal = (
            concealed_node_ids[node:id()]
            and (not config.check_conceal or config.check_conceal(node))
            and is_concealing_on_row_range(
                current_mode,
                conceallevel,
                concealcursor,
                current_row_0b,
                node_row_start_0b,
                node_row_end_0bex
            )
        )

        if has_conceal then
            if config.render_concealed then
                config:render_concealed(bufid, node)
            end
        else
            config:render(bufid, node)
        end

        ::continue::
    end
end

local function render_window_buffer(bufid)
    local ns_prettify_flag = module.private.ns_prettify_flag
    local winid = vim.fn.bufwinid(bufid)
    local row_start_0b, row_end_0bex = get_visible_line_range(winid)
    local prettify_flags_0b = vim.api.nvim_buf_get_extmarks(
        bufid,
        ns_prettify_flag,
        { row_start_0b, 0 },
        { row_end_0bex - 1, -1 },
        {}
    )
    local row_nomark_start_0b, row_nomark_end_0bin
    local i_flag = 1
    for i = row_start_0b, row_end_0bex - 1 do
        while i_flag <= #prettify_flags_0b and i > prettify_flags_0b[i_flag][2] do
            i_flag = i_flag + 1
        end

        if i_flag <= #prettify_flags_0b and i == prettify_flags_0b[i_flag][2] then
            i_flag = i_flag + 1
        else
            assert(i < (prettify_flags_0b[i_flag] and prettify_flags_0b[i_flag][2] or row_end_0bex))
            row_nomark_start_0b = row_nomark_start_0b or i
            row_nomark_end_0bin = i
        end
    end

    assert((row_nomark_start_0b == nil) == (row_nomark_end_0bin == nil))
    if row_nomark_start_0b then
        prettify_range(bufid, row_nomark_start_0b, row_nomark_end_0bin + 1)
    end
end

local function render_all_scheduled_and_done()
    for bufid, _ in pairs(module.private.rerendering_scheduled_bufids) do
        if vim.fn.bufwinid(bufid) >= 0 then
            render_window_buffer(bufid)
        end
    end
    module.private.rerendering_scheduled_bufids = {}
end

local function schedule_rendering(bufid)
    local not_scheduled = vim.tbl_isempty(module.private.rerendering_scheduled_bufids)
    module.private.rerendering_scheduled_bufids[bufid] = true
    if not_scheduled then
        vim.schedule(render_all_scheduled_and_done)
    end
end

local function mark_line_changed(bufid, row_0b)
    remove_prettify_flag_on_line(bufid, row_0b)
    schedule_rendering(bufid)
end

local function mark_line_range_changed(bufid, row_start_0b, row_end_0bex)
    remove_prettify_flag_range(bufid, row_start_0b, row_end_0bex)
    schedule_rendering(bufid)
end

local function mark_all_lines_changed(bufid)
    if not module.private.enabled then
        return
    end

    remove_prettify_flag_all(bufid)
    schedule_rendering(bufid)
end

local function clear_all_extmarks(bufid)
    local ns_icon = module.private.ns_icon
    local ns_prettify_flag = module.private.ns_prettify_flag
    vim.api.nvim_buf_clear_namespace(bufid, ns_icon, 0, -1)
    vim.api.nvim_buf_clear_namespace(bufid, ns_prettify_flag, 0, -1)
end

local function get_table_default_empty(tbl, key)
    if not tbl[key] then
        tbl[key] = {}
    end
    return tbl[key]
end

local function update_cursor(event)
    local cursor_record = get_table_default_empty(module.private.cursor_record, event.buffer)
    cursor_record.row_0b = event.cursor_position[1] - 1
    cursor_record.col_0b = event.cursor_position[2]
    cursor_record.line_content = event.line_content
end

local function handle_init_event(event)
    -- TODO: make sure only init once

    assert(vim.api.nvim_win_is_valid(event.window))
    update_cursor(event)

    local function on_line_callback(
        tag,
        bufid,
        _changedtick, ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
        row_start_0b,
        _row_end_0bex, ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
        row_updated_0bex,
        _n_byte_prev ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
    )
        assert(tag == "lines")

        if not module.private.enabled then
            return
        end

        mark_line_range_changed(bufid, row_start_0b, row_updated_0bex)
    end

    local attach_succeeded = vim.api.nvim_buf_attach(event.buffer, true, { on_lines = on_line_callback })
    assert(attach_succeeded)
    local language_tree = vim.treesitter.get_parser(event.buffer, "norg")

    local bufid = event.buffer
    -- used for detecting non-local (multiline) changes, like spoiler / code block
    -- TODO: exemption in certain cases, for example when changing only heading followed by pure texts,
    -- in which case all its descendents would be unnecessarily re-concealed.
    local function on_changedtree_callback(ranges)
        -- TODO: abandon if too large
        for i = 1, #ranges do
            local range = ranges[i]
            local row_start_0b = range[1]
            local row_end_0bex = range[3] + 1
            remove_prettify_flag_range(bufid, row_start_0b, row_end_0bex)
        end
    end

    language_tree:register_cbs({ on_changedtree = on_changedtree_callback })
    mark_all_lines_changed(event.buffer)

    if module.config.public.folds and vim.api.nvim_win_is_valid(event.window) then
        local wo = vim.wo[event.window]
        wo.foldmethod = "expr"
        wo.foldexpr = vim.treesitter.foldexpr and "v:lua.vim.treesitter.foldexpr()" or "nvim_treesitter#foldexpr()"
        wo.foldtext = "v:lua.require'neorg'.modules.get_module('core.concealer').foldtext()"

        local init_open_folds = module.config.public.init_open_folds
        local function open_folds()
            vim.cmd("normal! zR")
        end

        if init_open_folds == "always" then
            open_folds()
        elseif init_open_folds == "never" then -- luacheck:ignore 542
            -- do nothing
        else
            if init_open_folds ~= "auto" then
                log.warn('"init_open_folds" must be "auto", "always", or "never"')
            end

            if wo.foldlevel == 0 then
                open_folds()
            end
        end
    end
end

local function handle_insert_toggle(event)
    mark_line_changed(event.buffer, event.cursor_position[1] - 1)
end

local function handle_insertenter(event)
    handle_insert_toggle(event)
end

local function handle_insertleave(event)
    handle_insert_toggle(event)
end

local function handle_toggle_prettifier(event)
    -- FIXME: module.private.enabled should be a map from bufid to boolean
    module.private.enabled = not module.private.enabled
    if module.private.enabled then
        mark_all_lines_changed(event.buffer)
    else
        module.private.rerendering_scheduled_bufids[event.buffer] = nil
        clear_all_extmarks(event.buffer)
    end
end

local function is_same_line_movement(event)
    -- some operations like dd / u cannot yet be listened reliably
    -- below is our best approximation
    local cursor_record = module.private.cursor_record
    return (
        cursor_record
        and cursor_record.row_0b == event.cursor_position[1] - 1
        and cursor_record.col_0b ~= event.cursor_position[2]
        and cursor_record.line_content == event.line_content
    )
end

local function handle_cursor_moved(event)
    -- reveal/conceal when conceallevel>0
    -- also triggered when dd / u
    if not is_same_line_movement(event) then
        local cursor_record = module.private.cursor_record[event.buffer]
        if cursor_record then
            -- leaving previous line, conceal it if necessary
            mark_line_changed(event.buffer, cursor_record.row_0b)
        end
        -- entering current line, conceal it if necessary
        local current_row_0b = event.cursor_position[1] - 1
        mark_line_changed(event.buffer, current_row_0b)
    end
    update_cursor(event)
end

local function handle_cursor_moved_i(event)
    return handle_cursor_moved(event)
end

local function handle_winscrolled(event)
    schedule_rendering(event.buffer)
end

local function handle_filetype(event)
    handle_init_event(event)
end

local event_handlers = {
    ["core.neorgcmd.events.core.concealer.toggle"] = handle_toggle_prettifier,
    -- ["core.autocommands.events.bufnewfile"] = handle_init_event,
    ["core.autocommands.events.filetype"] = handle_filetype,
    ["core.autocommands.events.bufreadpost"] = handle_init_event,
    ["core.autocommands.events.insertenter"] = handle_insertenter,
    ["core.autocommands.events.insertleave"] = handle_insertleave,
    ["core.autocommands.events.cursormoved"] = handle_cursor_moved,
    ["core.autocommands.events.cursormovedi"] = handle_cursor_moved_i,
    ["core.autocommands.events.winscrolled"] = handle_winscrolled,
}

module.on_event = function(event)
    if event.referrer == "core.autocommands" and vim.bo[event.buffer].ft ~= "norg" then
        return
    end

    if (not module.private.enabled) and (event.type ~= "core.neorgcmd.events.core.concealer.toggle") then
        return
    end
    return event_handlers[event.type](event)
end

module.load = function()
    local icon_preset =
        module.imported[module.name .. ".preset_" .. module.config.public.icon_preset].config.private["icon_preset_" .. module.config.public.icon_preset]
    if not icon_preset then
        log.error(
            ("Unable to load icon preset '%s' - such a preset does not exist"):format(module.config.public.icon_preset)
        )
        return
    end

    module.config.public =
        vim.tbl_deep_extend("force", module.config.public, { icons = icon_preset }, module.config.custom or {})

    -- module.required["core.autocommands"].enable_autocommand("BufNewFile")
    module.required["core.autocommands"].enable_autocommand("FileType", true)
    module.required["core.autocommands"].enable_autocommand("BufReadPost")
    module.required["core.autocommands"].enable_autocommand("InsertEnter")
    module.required["core.autocommands"].enable_autocommand("InsertLeave")
    module.required["core.autocommands"].enable_autocommand("CursorMoved")
    module.required["core.autocommands"].enable_autocommand("CursorMovedI")
    module.required["core.autocommands"].enable_autocommand("WinScrolled", true)

    modules.await("core.neorgcmd", function(neorgcmd)
        neorgcmd.add_commands_from_table({
            ["toggle-concealer"] = {
                name = "core.concealer.toggle",
                args = 0,
                condition = "norg",
            },
        })
    end)
    if utils.is_minimum_version(0, 7, 0) then
        vim.api.nvim_create_autocmd("OptionSet", {
            pattern = "conceallevel",
            callback = function(_ev) ---@diagnostic disable-line -- TODO: type error workaround <pysan3>
                local bufid = vim.api.nvim_get_current_buf()
                if vim.bo[bufid].ft ~= "norg" then
                    return
                end
                mark_all_lines_changed(bufid)
            end,
        })
    end
end

-- TODO;
-- [---------] lazyredraw, ttyfast
-- [x] no conceal on cursor line at insert mode
-- [---------] no conceal inside examples
-- [x] insert mode movement
-- [x] code, spoiler, non-local changes, languagetree (WONTFIX complicated cases)
-- [x]code config
-- [x] conceal links
-- [x] fix toggle-concealer
-- [ ] visual mode skip prettify ("ivV"):find(mode), ModeChanged
-- [+++++++] use vim.b[bufnr]
-- [x] chuncked concealing on demand for large file
-- --- (prev), current, (next): singleton record, changed when moving large steps
-- [++++++] adaptive performance tuning: instant, CursorHold
-- [++++++] multi-column ordering
-- [x] strip heading/list icon
-- number_spec: "§A.a1."
-- digit_infos: { ["A"] = ..., ["a"] = ..., ["1"] = ..., ["⑴"] = ... }
-- result: render({3,5,2,6,7}) = "§C.e2.6.7"
-- [ ] folding
-- [x] remove "enabled" and nestings from config
-- [x] fix: quote level >6
-- rerender on window size change
-- -- details like queries and highlights are closely coupled with the implementation. revealing it to the users are more noisy than helpful

module.events.subscribed = {
    ["core.autocommands"] = {
        -- bufnewfile = true,
        filetype = true,
        bufreadpost = true,
        insertenter = true,
        insertleave = true,
        cursormoved = true,
        cursormovedi = true,
        winscrolled = true,
    },

    ["core.neorgcmd"] = {
        ["core.concealer.toggle"] = true,
    },
}

return module
