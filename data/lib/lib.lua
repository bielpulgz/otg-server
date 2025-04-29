-- Core API functions implemented in Lua
dofile('data/lib/core/core.lua')

-- Compatibility library for our old Lua API
dofile('data/lib/compat/compat.lua')

-- Debugging helper function for Lua developers
dofile('data/lib/debugging/dump.lua')
dofile('data/lib/debugging/lua_version.lua')

-----Custom System
-- Autoloot
dofile('data/lib/custom/autoloot.lua')
-- Daily Reward
dofile('data/lib/custom/dailyreward_lib.lua')
-- Reward Boss
dofile('data/lib/custom/reward_boss.lua')


