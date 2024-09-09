if SERVER then return end --prevents it from running on the server


local configDescriptions = {}
configDescriptions["commands"] = "you can use blueprints or bp"
configDescriptions["load"] = "load a blueprint. EX: bp load reactor_controller"
configDescriptions["save"] = "save a blueprint. EX: bp save reactor_controller"
configDescriptions["need"] = "get requirements for a blueprint. EX: bp need reactor_controller"
configDescriptions["delete"] = "delete a blueprint. EX: bp delete reactor_controller"
configDescriptions["list"] = "list all saved files. EX: bp list"
configDescriptions["toggle"] = "toggle things on and off. EX: bp toggle tests"
configDescriptions["clear"] = "Remove all components and labels from a circuitbox. EX: bp clear"


	
local function checkStringAgainstTags(targetString, tags) --this is needed to run the command line args
    for tag, _ in pairs(tags) do
        if targetString == tag then
            return true  -- Match found
        end
    end
    return false  -- No match found
end




local function runCommand(command)
	if command[1] == nil or command[1] == "help" or command[1] == "commands" then
		for key, value in pairs(configDescriptions) do
			print(key .. ": " .. value)
		end
	end
	
	
	if command[1] == "load" then
		if command[2] ~= nil then
			print("Attempting to build blueprint")
			blue_prints.construct_blueprint(command[2])
		else
			print("No filename given. EX: bp load file_name.txt")
		end
	end
	
	
	if command[1] == "save" then
		if command[2] ~= nil then
			print("Attempting to save blueprint")
			blue_prints.save_blueprint(command[2])
		else
			print("No filename given. EX: bp save file_name.txt")
		end
	end
	
	if command[1] == "need" then
		if command[2] ~= nil then
			print("Attempting to get blueprint requirements")
			blue_prints.print_requirements_of_circuit(command[2]) 
			blue_prints.check_what_is_needed_for_blueprint(command[2])
		else
			print("No filename given. EX: bp need file_name.txt")
		end
	end
	
	if command[1] == "delete" then
		if command[2] ~= nil then
			print("Attempting to delete blueprint")
			blue_prints.delete_blueprint(command[2])
		else
			print("No filename given. EX: bp delete file_name.txt")
		end
	end
	
	if command[1] == "clear" then
		blue_prints.clear_circuitbox()
	end
	
	if command[1] == "list" then
		blue_prints.print_all_saved_files()
	end
	
	if command[1] == "unit_tests" then
		blue_prints.unit_tests_enabled = true
		blue_prints.unit_test_all_blueprint_files()
	end
	
	if command[1] == "toggle" then
		if command[2] == "tests" then
			blue_prints.unit_tests_enabled =  not blue_prints.unit_tests_enabled
			print("tests enabled: " .. tostring(blue_prints.unit_tests_enabled))
		end
	end
	
	
	if checkStringAgainstTags(command[1], configDescriptions) then
		--print("Match found!")
	else
		print("Command not recognized. type bp to see available commands.")
	end
	
end

Game.AddCommand("blueprints", "configures blueprints", function (command)
	runCommand(command)
end)


Game.AddCommand("bp", "configures blueprints abbreviated", function (command)
	runCommand(command)
end)





