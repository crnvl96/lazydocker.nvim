local Helpers = {}

Helpers.expect = vim.deepcopy(MiniTest.expect)

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
