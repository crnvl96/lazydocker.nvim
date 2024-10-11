local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = new_set({
	hooks = {
		pre_case = function()
			child.restart({ "-u", "scripts/minimal_init.lua" })
		end,
		post_once = child.stop,
	},
})

T["setup()"] = new_set()

T["setup()"]["create global table"] = function()
	child.lua([[require('lazydocker').setup()]])
	eq(child.lua_get("type(LazyDocker)"), "table")
end

T["setup()"]["check global table"] = function()
	child.lua([[require('lazydocker').setup()]])

	eq(child.lua_get("type(LazyDocker.config)"), "table")
	eq(child.lua_get("type(LazyDocker.config.width)"), "number")
	eq(child.lua_get("type(LazyDocker.config.height)"), "number")
end

return T
