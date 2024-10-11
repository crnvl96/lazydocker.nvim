local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local new_set = MiniTest.new_set

local eq = helpers.expect.equality
local get = child.lua_get

--stylua: ignore start
local load_module = function(config) child.load('lazydocker', config) end
local set_size = function(...) return child.set_size(...) end
--stylua: ignore end

local T = new_set({
    hooks = {
        pre_case = child.setup,
        post_once = child.stop,
        n_retry = 1,
    },
})

T["setup()"] = new_set()

T["setup()"]["create global table"] = function()
    load_module()
    eq(get("type(LazyDocker)"), "table")
end

T["setup()"]["check global table types"] = function()
    load_module()

    eq(get("type(LazyDocker.config)"), "table")

    local expect_config_type = function(field, value)
        field = ("type(LazyDocker.config.%s)"):format(field)
        eq(get(field), value)
    end

    expect_config_type("width", "number")
    expect_config_type("height", "number")
end

T["setup()"]["check global table values"] = function()
    set_size(100, 200)
    load_module()

    eq(get("LazyDocker.config.height"), 61)
    eq(get("LazyDocker.config.width"), 123)
end

return T
