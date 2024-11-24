--this is the entry point for the code. This runs all other scripts.

--get the local path and save it as a global. only autorun files can get the path in this way!
blue_prints = {}
blue_prints.path = ...
-- Always use forward slashes internally, both Windows and Linux can handle this
blue_prints.path = blue_prints.path and blue_prints.path:gsub("\\", "/") or ""

-- Set up save path - will be normalized in read_write.lua functions
blue_prints.save_path = "LocalMods/Blueprints_saved_blueprints"

blue_prints.most_recent_circuitbox = nil 
blue_prints.time_delay_between_loops = 100
blue_prints.current_gui_page = nil
blue_prints.most_recently_loaded_blueprint_name = nil
blue_prints.unit_tests_enabled = false

dofile(blue_prints.path .. "/Lua/gui/cs_required_warning.lua")

if CSActive then --CSActive is if csharp scripts are enabled. This mod requires them.
    --setup
    dofile(blue_prints.path .. "/Lua/register_types.lua")
    dofile(blue_prints.path .. "/Lua/utilities/read_write.lua")  -- Load read_write before first_time_setup
    dofile(blue_prints.path .. "/Lua/first_time_setup.lua")
    
    --utilities
    dofile(blue_prints.path .. "/Lua/utilities/utilities.lua")
    
    --core logic
    dofile(blue_prints.path .. "/Lua/save_blueprint.lua")
    dofile(blue_prints.path .. "/Lua/load_blueprint.lua")
    dofile(blue_prints.path .. "/Lua/delete_blueprint.lua")
    dofile(blue_prints.path .. "/Lua/commands.lua")
    dofile(blue_prints.path .. "/Lua/unit_tests.lua")
    
    --gui
    dofile(blue_prints.path .. "/Lua/gui/load_gui.lua")
    dofile(blue_prints.path .. "/Lua/gui/save_gui.lua")
    dofile(blue_prints.path .. "/Lua/gui/clear_gui.lua")
end