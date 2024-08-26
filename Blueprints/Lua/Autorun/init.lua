--the purpose of this script is to initalize the mod
--it reads any changes from the default config and saves the result as a global variable
--after that it loads the rest of the scripts


--get the local path and save it as a global. only autorun files can get the path in this way!
blue_prints = {}
blue_prints.path = ...
blue_prints.save_path = "LocalMods/Blueprints_saved_blueprints"

local success = false
local result

-- First attempt (string version)
if not success then
	success, result = pcall(function()
		--used to create netlimitedstrings
		LuaUserData.RegisterType("Barotrauma.NetLimitedString")
		blue_prints.net_limited_string_type = LuaUserData.CreateStatic("Barotrauma.NetLimitedString", true)

		--for accessing component values inside components
		LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Item"], "GetInGameEditableProperties")
		LuaUserData.RegisterType("System.ValueTuple`2[System.Object,Barotrauma.SerializableProperty]")

		--used to create immutable arrays
		LuaUserData.RegisterType("System.Collections.Immutable.ImmutableArray")
		LuaUserData.RegisterType("System.Collections.Immutable.ImmutableArray`1")
		blue_prints.immutable_array_type = LuaUserData.CreateStatic("System.Collections.Immutable.ImmutableArray", false)
		
		return "Registration of csharp types successful"
	end)
end


if success then
	blue_prints.most_recent_circuitbox = nil 
	blue_prints.time_delay_between_loops = 100
	
	--run the rest of the files
	dofile(blue_prints.path .. "/Lua/first_time_setup.lua")
	dofile(blue_prints.path .. "/Lua/utilities.lua")
	dofile(blue_prints.path .. "/Lua/save_blueprint.lua")
	dofile(blue_prints.path .. "/Lua/load_blueprint.lua")
	dofile(blue_prints.path .. "/Lua/delete_blueprint.lua")
	dofile(blue_prints.path .. "/Lua/commands.lua")
else
	dofile(blue_prints.path .. "/Lua/cs_required_warning.lua")
end


--TODO list
--add buttons to control the mod instead of the text interface

