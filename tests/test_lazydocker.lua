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

T["setup()"]["validate global table"] = function()
    load_module()

    eq(get("type(LazyDocker)"), "table")
    eq(get("type(LazyDocker.config)"), "table")

    local expect_config_type = function(field, value)
        field = ("type(LazyDocker.config.%s)"):format(field)
        eq(get(field), value)
    end

    expect_config_type("width", "number")
    expect_config_type("height", "number")
end

T["setup()"]["check default config"] = function()
    set_size(100, 200)
    load_module()

    eq(get("LazyDocker.config.height"), 61)
    eq(get("LazyDocker.config.width"), 123)
end

T["setup()"]["check custon config"] = function()
    set_size(200, 200)
    load_module({ width = 100, height = 100 })

    eq(get("LazyDocker.config.height"), 100)
    eq(get("LazyDocker.config.width"), 100)
end

T["setup()"]["validate incorrect config"] = function()
    local specs = {
        100,
        { width = "a", height = 50 },
        { width = 50, height = "a" },
        { width = -10, height = 50 },
        { width = 50, height = -10 },
        { width = 1.5, height = 50 },
        { width = 50, height = 0.8 },
    }

    for _, spec in ipairs(specs) do
        err(function()
            load_module(spec)
        end)
    end
end

return T
