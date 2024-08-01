

--the purpose of this script is to initalize the mod
--it reads any changes from the default config and saves the result as a global varible
--after that it loads the rest of the scripts


--get the local path and save it as a global. only autorun files can get the path in this way!
blue_prints = {}
blue_prints.path = ...

blue_prints.reactor_path = (blue_prints.path .. "/basic_reactor.txt")

--run the rest of the files
dofile(blue_prints.path .. "/Lua/commands.lua")