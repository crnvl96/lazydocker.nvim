local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local new_set = MiniTest.new_set

local eq = helpers.expect.equality
local err = helpers.expect.error

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

T["setup()"]["correctly handle a custom config input by the user"] = function()
    set_size(200, 200)
    load_module({ width = 100, height = 100 })

    eq(get("LazyDocker.config.height"), 100)
    eq(get("LazyDocker.config.width"), 100)
end

T["setup()"]["correctly handle a invalid config input by the user"] = function()
    err(function()
        load_module(100)
    end, "a valid config table must be provided as argument of `setup`. Please check `:h LazyDocker.config`")
end

T["setup()"]["correctly handle a non-numeric width"] = function()
    err(function()
        load_module({ width = "a", height = 50 })
    end, "`width` must be a number. Please check `:h LazyDocker.config`")
end

T["setup()"]["correctly handle a non-numeric height"] = function()
    err(function()
        load_module({ width = 50, height = "a" })
    end, "`height` must be a number. Please check `:h LazyDocker.config`")
end

T["setup()"]["correctly handle a negative width"] = function()
    err(function()
        load_module({ width = -10, height = 50 })
    end, "`width` must have a positive value. Please check `:h LazyDocker.config`")
end

T["setup()"]["correctly handle a negative height"] = function()
    err(function()
        load_module({ width = 40, height = -50 })
    end, "`height` must have a positive value. Please check `:h LazyDocker.config`")
end

return T
