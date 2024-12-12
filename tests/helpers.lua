-- Helpers present have have been inspired from:
--
-- https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md
--
-- and
--
-- https://github.com/echasnovski/mini.nvim/blob/main/tests/helpers.lua

local Helpers = {}

Helpers.expect = vim.deepcopy(MiniTest.expect)

Helpers.expect.match = MiniTest.new_expectation(
    -- Expectation subject
    "string matching",
    -- Predicate
    function(str, pattern)
        return str:find(pattern) ~= nil
    end,
    -- Fail context
    function(str, pattern)
        return string.format("Pattern: %s\nObserved string: %s", vim.inspect(pattern), str)
    end
)

Helpers.expect.no_match = MiniTest.new_expectation(
    -- Expectation subject
    "no string matching",
    -- Predicate
    function(str, pattern)
        return str:find(pattern) == nil
    end,
    -- Fail context
    function(str, pattern)
        return string.format("Pattern: %s\nObserved string: %s", vim.inspect(pattern), str)
    end
)

Helpers.new_child_neovim = function()
    local child = MiniTest.new_child_neovim()

    local prevent_hanging = function(method)
        if not child.is_blocked() then
            return
        end

        local msg = string.format("Can not use `child.%s` because child process is blocked.", method)
        error(msg)
    end

    child.setup = function()
        child.restart({ "-u", "scripts/minimal_init.lua" })

        child.bo.readonly = false
    end

    child.load = function(name, config)
        local lua_cmd = ([[require('%s').setup(...)]]):format(name)
        child.lua(lua_cmd, { config })
    end

    child.mini_unload = function(mod_name, tbl_name)
        child.lua(([[package.loaded['%s'] = nil]]):format(mod_name))
        child.lua(("_G[%s] = nil"):format(tbl_name))

        if child.fn.exists("#" .. tbl_name) == 1 then
            child.api.nvim_del_augroup_by_name(tbl_name)
        end
    end

    child.set_size = function(lines, columns)
        prevent_hanging("set_size")

        if type(lines) == "number" then
            child.o.lines = lines
        end

        if type(columns) == "number" then
            child.o.columns = columns
        end
    end

    child.get_size = function()
        prevent_hanging("get_size")

        return { child.o.lines, child.o.columns }
    end

    return child
end

return Helpers
