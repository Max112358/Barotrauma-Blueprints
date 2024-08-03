

--the purpose of this script is to initalize the mod
--it reads any changes from the default config and saves the result as a global varible
--after that it loads the rest of the scripts


--get the local path and save it as a global. only autorun files can get the path in this way!
blue_prints = {}
blue_prints.path = ...
blue_prints.save_path = "LocalMods/Blueprints_saved_blueprints"


blue_prints.most_recent_circuitbox = nil 
LuaUserData.RegisterType("Barotrauma.NetLimitedString")
blue_prints.net_limited_string_type = LuaUserData.CreateStatic("Barotrauma.NetLimitedString", true)
blue_prints.time_delay_between_loops = 100


--run the rest of the files
dofile(blue_prints.path .. "/Lua/first_time_setup.lua")
dofile(blue_prints.path .. "/Lua/utilities.lua")
dofile(blue_prints.path .. "/Lua/save_blueprint.lua")
dofile(blue_prints.path .. "/Lua/load_blueprint.lua")
dofile(blue_prints.path .. "/Lua/delete_blueprint.lua")
dofile(blue_prints.path .. "/Lua/commands.lua")



--TODO list
--move the input output windows. This is being blocked because I cant figure out how to get a IReadOnlyCollection<CircuitBoxNode> type for the final call
--get clear_circuitbox working. same problem as above.
--add buttons to control the mod instead of the text interface

