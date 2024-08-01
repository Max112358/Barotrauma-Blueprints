if SERVER then return end --prevents it from running on the server


local configDescriptions = {}
configDescriptions["commands"] = "you can use blueprints or bp"
configDescriptions["load"] = "load a blueprint. EX: bp load reactor_controller.txt"
configDescriptions["save"] = "save a blueprint. EX: bp save reactor_controller.txt"
configDescriptions["list"] = "list all saved files. EX: bp list"


local most_recent_circuitbox = nil 
LuaUserData.RegisterType("Barotrauma.NetLimitedString")
local net_limited_string_type = LuaUserData.CreateStatic("Barotrauma.NetLimitedString", true)
local time_delay_between_loops = 100


--TODO list
--move the input output windows. This is being blocked because I cant figure out how to get a IReadOnlyCollection<CircuitBoxNode> type for the final call
--get clear_circuitbox working. same problem as above.
--resize labels. This is doable, but low priority in my opinion.
--set values inside components set somehow (impossible? its not even in the save file, and also no function for it)
--add buttons to control the mod instead of the text interface


local function print_all_saved_files()

    local saved_files = File.GetFiles(blue_prints.path)
    
    for name, value in pairs(saved_files) do
        if string.match(value, "%.txt$") then
            print(string.format("  %s: %s", name, value))
        end
    end
end


local function readFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil, "Failed to open file: " .. path
    end
    local content = file:read("*all")
    file:close()
    return content
end

local function parseXML(xmlString)


	local inputs = {}
	local outputs = {}
	local components = {}
	local wires = {}
	local labels = {}
	local inputNodePos = {}
    local outputNodePos = {}

    -- Parse InputNode
    for inputNode in xmlString:gmatch("<InputNode.-</InputNode>") do
        local posX, posY = inputNode:match('pos="([%d%.%-]+),([%d%.%-]+)"')
        inputNodePos = {x = tonumber(posX), y = tonumber(posY)}
        
        for name, value in inputNode:gmatch('<ConnectionLabelOverride name="([^"]+)" value="([^"]+)"') do
            if name:match("^signal_in") then
                inputs[name] = value
            end
        end
    end

    -- Parse OutputNode
    for outputNode in xmlString:gmatch("<OutputNode.-</OutputNode>") do
        local posX, posY = outputNode:match('pos="([%d%.%-]+),([%d%.%-]+)"')
        outputNodePos = {x = tonumber(posX), y = tonumber(posY)}
        
        for name, value in outputNode:gmatch('<ConnectionLabelOverride name="([^"]+)" value="([^"]+)"') do
            if name:match("^signal_out") then
                outputs[name] = value
            end
        end
    end

    -- Parse Components
    for component in xmlString:gmatch('<Component[^>]+/>') do
        local id = component:match('id="(%d+)"')
        local positionX, positionY = component:match('position="([%d%.%-]+),([%d%.%-]+)"')
        local usedResource = component:match('usedresource="([^"]+)"')

        table.insert(components, {
            id = id,
            position = {x = tonumber(positionX), y = tonumber(positionY)},
            usedResource = usedResource
        })
    end
	
	-- Parse Wires
    for wire in xmlString:gmatch("<Wire.-</Wire>") do
        local wireData = {id = wire:match('id="(%d+)"')}
        
        local fromName, fromTarget = wire:match('<From name="([^"]+)" target="([^"]*)"')
        local toName, toTarget = wire:match('<To name="([^"]+)" target="([^"]*)"')
        
        wireData.from = {name = fromName, target = fromTarget ~= "" and fromTarget or nil}
        wireData.to = {name = toName, target = toTarget ~= "" and toTarget or nil}
        
        table.insert(wires, wireData)
    end
	
	-- Parse Labels
    for label in xmlString:gmatch('<Label[^>]+/>') do
        local id = label:match('id="(%d+)"')
        local color = label:match('color="([^"]+)"')
        local posX, posY = label:match('position="([%d%.%-]+),([%d%.%-]+)"')
        local sizeW, sizeH = label:match('size="([%d%.%-]+),([%d%.%-]+)"')
        local header = label:match('header="([^"]+)"')
        local body = label:match('body="([^"]+)"')
        table.insert(labels, {
            id = id,
            color = color,
            position = {x = tonumber(posX), y = tonumber(posY)},
            size = {width = tonumber(sizeW), height = tonumber(sizeH)},
            header = header,
            body = body
        })
    end

    return inputs, outputs, components, wires, labels, inputNodePos, outputNodePos
end





local function isInteger(str)
    return str and not (str == "" or str:find("%D"))
end

local function isFloat(str)
    local n = tonumber(str)
    return n ~= nil and math.floor(n) ~= n
end

function removeKeyFromTable(tbl, keyToRemove)
    local newTable = {}
    for k, v in pairs(tbl) do
        if k ~= keyToRemove then
            newTable[k] = v
        end
    end
    return newTable
end

function hexToRGBA(hex)
    -- Remove the '#' if present
    hex = hex:gsub("#", "")
    
    -- Check if it's a valid hex color
    if #hex ~= 6 and #hex ~= 8 then
        return nil, "Invalid hex color format"
    end
    
    -- Convert hex to decimal
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    local a = 255
    
    -- If alpha channel is provided
    if #hex == 8 then
        a = tonumber(hex:sub(7, 8), 16)
    end
    
    -- Return Color object
    return Color(r, g, b, a)
end

local function getNthValue(tbl, n)
    local count = 0
    for key, value in pairs(tbl) do
        count = count + 1
        if count == n then
            return value
        end
    end
    return nil  -- Return nil if there are fewer than n items
end

--local prefab = ItemPrefab.GetItemPrefab("string")


local function clear_circuitbox() --this does not work. I cant figure out how to get a IReadOnlyCollection<CircuitBoxNode> type for the final call
	if most_recent_circuitbox == nil then print("no circuitbox detected") return end
	local components = most_recent_circuitbox.GetComponentString("CircuitBox").Components
	most_recent_circuitbox.GetComponentString("CircuitBox").RemoveComponents(components)
end


local function add_component_to_circuitbox(component)
    if most_recent_circuitbox == nil then 
        print("No circuitbox detected")
        return 
    end

    local item_to_add = ItemPrefab.GetItemPrefab(component.usedResource)
    local component_position = Vector2(component.position.x, component.position.y)
    most_recent_circuitbox.GetComponentString("CircuitBox").AddComponent(item_to_add, component_position)
    --print(string.format("Added component %s at position (%.2f, %.2f)", component.usedResource, component_position.x, component_position.y))
end

local function add_all_components_to_circuitbox(components, index)
    if most_recent_circuitbox == nil then 
        print("No circuitbox detected")
        return 
    end

    index = index or 1  -- Start with the first component if no index is provided

    if index <= #components then
        local component = components[index]
        add_component_to_circuitbox(component)

        -- Schedule the next addition with a delay
        Timer.Wait(function() add_all_components_to_circuitbox(components, index + 1) end, time_delay_between_loops)
    else
        -- If all components are added, print a message
        print("All components added.")
    end
end



local function add_wires_to_circuitbox_recursive(wires, index)
    if most_recent_circuitbox == nil then print("no circuitbox detected") return end
    
    local first_connection = nil
    local second_connection = nil
    
    local components = most_recent_circuitbox.GetComponentString("CircuitBox").Components
    local input_output_nodes = most_recent_circuitbox.GetComponentString("CircuitBox").InputOutputNodes
    local input_connection_node = getNthValue(input_output_nodes, 1)
    local input_connections = input_connection_node.Connectors
    local output_connection_node = getNthValue(input_output_nodes, 2)
    local output_connections = output_connection_node.Connectors

    if index > #wires then
		print("All wires added.")
        return
    end
    
    local wire = wires[index]
    
    for component_key, component_value in pairs(components) do
        local connectors = component_value.Connectors

        for connector_key, connector_value in pairs(connectors) do
            if tostring(component_value.ID) == tostring(wire.from.target) and tostring(connector_value.name) == tostring(wire.from.name) then
                first_connection = connector_value
            end
            
            if tostring(component_value.ID) == tostring(wire.to.target) and tostring(connector_value.name) == tostring(wire.to.name) then
                second_connection = connector_value
            end
        end
    end
    
    if wire.from.target == nil then
        local input_to_target = string.match(tostring(wire.from.name), "%d+")
        first_connection = getNthValue(input_connections, tonumber(input_to_target))
    end
    
    if wire.to.target == nil then
        local input_to_target = string.match(tostring(wire.to.name), "%d+")
        second_connection = getNthValue(output_connections, tonumber(input_to_target))
    end
    
    if first_connection and second_connection then
        most_recent_circuitbox.GetComponentString("CircuitBox").AddWire(first_connection, second_connection)
    end
    
    -- Recur to the next wire
	Timer.Wait(function() add_wires_to_circuitbox_recursive(wires, index + 1) end, time_delay_between_loops)
end


local function change_input_output_labels(input_dict, output_dict)
	if most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local input_output_nodes = most_recent_circuitbox.GetComponentString("CircuitBox").InputOutputNodes 
	local input_connection_node = getNthValue(input_output_nodes, 1)
	local output_connection_node = getNthValue(input_output_nodes, 2)
		
	most_recent_circuitbox.GetComponentString("CircuitBox").SetConnectionLabelOverrides(input_connection_node, input_dict) 
	most_recent_circuitbox.GetComponentString("CircuitBox").SetConnectionLabelOverrides(output_connection_node, output_dict) 
end


local function add_labels_to_circuitbox_recursive(labels, index)
    if most_recent_circuitbox == nil then print("no circuitbox detected") return end
    
    -- Base case: if we've processed all labels, return
    if index > #labels then
        return
    end
    
    -- Process the current label
    local label = labels[index]
    local label_position = Vector2(label.position.x, label.position.y)
    most_recent_circuitbox.GetComponentString("CircuitBox").AddLabel(label_position)
    
    -- Recursive call to process the next label
	Timer.Wait(function() add_labels_to_circuitbox_recursive(labels, index + 1) end, time_delay_between_loops)
end



local function rename_all_labels_in_circuitbox(labels)
	if most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local label_nodes = most_recent_circuitbox.GetComponentString("CircuitBox").Labels 

	 for i, label in ipairs(labels) do
        --print(string.format("  Label %d:", i))
        --print(string.format("    ID: %s", label.id))
        --print(string.format("    Color: %s", label.color))
        --print(string.format("    Position: (%.2f, %.2f)", label.position.x, label.position.y))
        --print(string.format("    Size: %.2f x %.2f", label.size.width, label.size.height))
        --print(string.format("    Header: %s", label.header))
        --print(string.format("    Body: %s", label.body))
		
		local label_node = getNthValue(label_nodes, i)
		local label_header = net_limited_string_type(tostring(label.header))
		local label_body = net_limited_string_type(tostring(label.body))
		local label_color = hexToRGBA(label.color)
		
		most_recent_circuitbox.GetComponentString("CircuitBox").RenameLabel(label_node, label_color, label_header, label_body)
    end
end



local function move_input_output_nodes() --this does not work. I cant figure out how to get a IReadOnlyCollection<CircuitBoxNode> type for the final call
	if most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local input_output_nodes = most_recent_circuitbox.GetComponentString("CircuitBox").InputOutputNodes 
	local input_connection_node = getNthValue(input_output_nodes, 1)
	local output_connection_node = getNthValue(input_output_nodes, 2)
		
		
	--local read_only_component = i_read_only_collection_type(tostring(label.body))
	--local read_only_component_input = i_read_only_collection_type(input_connection_node)
	--local read_only_component_output = i_read_only_collection_type(output_connection_node)
	--local read_only_component_input = immutable_array_type(input_connection_node)
	
	LuaUserData.RegisterType("System.Collections.Immutable.ImmutableHashSet")
	local immutable_hashset_type = LuaUserData.CreateStatic("System.Collections.Immutable.ImmutableHashSet", false)
	local read_only_component_input = immutable_hashset_type.Create(input_connection_node)
	
	local component_position = Vector2(800, 800)
		
	most_recent_circuitbox.GetComponentString("CircuitBox").MoveComponent(component_position, read_only_component_input) 
end


local function check_inventory_for_requirements(components)
    local missing_components = {}
    for _, component in ipairs(components) do
        missing_components[component.usedResource] = (missing_components[component.usedResource] or 0) + 1
    end

    local character = Character.Controlled
    
    for inventory_item in character.Inventory.AllItems do
        local identifier = tostring(inventory_item.Prefab.Identifier)
        if missing_components[identifier] and missing_components[identifier] > 0 then
            missing_components[identifier] = missing_components[identifier] - 1
        end
    end    
    
    -- Remove components that are not missing
    for identifier, count in pairs(missing_components) do
        if count <= 0 then
            missing_components[identifier] = nil
        end
    end

    return missing_components
end

	
local function checkStringAgainstTags(targetString, tags) --this is needed to run the command line args
    for tag, _ in pairs(tags) do
        if targetString == tag then
            return true  -- Match found
        end
    end
    return false  -- No match found
end



local function construct_blueprint(provided_path)
	if Character.Controlled == nil then print("you dont have a character") return end

	local file_path = (blue_prints.path .. "/" .. provided_path)
	local xmlContent, err = readFile(file_path)

	if xmlContent then
		-- In the usage section:
		local inputs, outputs, components, wires, labels, inputNodePos, outputNodePos = parseXML(xmlContent)

		--print("Inputs:", inputs)
		--print("Outputs:", outputs)
		--print("Components:", components)
		--print("Wires:", wires)

		--[[
		for name, value in pairs(inputs) do
			print(string.format("  %s: %s", name, value))
		end
	

		for name, value in pairs(outputs) do
			print(string.format("  %s: %s", name, value))
		end

		if components then
			print("\nComponents:")
			for _, component in ipairs(components) do
				print(string.format("Component ID: %s", component.id))
				print(string.format("  Position: (%.2f, %.2f)", component.position.x, component.position.y))
				print(string.format("  Used Resource: %s", component.usedResource))
			end
		else
			print("Components is nil")
		end

		if wires then
			print("\nWires:")
			for _, wire in ipairs(wires) do
				print(string.format("Wire ID: %s", wire.id))
				print(string.format("  From: %s (Target: %s)", wire.from.name, wire.from.target or "nil"))
				print(string.format("  To: %s (Target: %s)", wire.to.name, wire.to.target or "nil"))
			end
		else
			print("Wires is nil")
		end
		--]]

		local number_of_components = #components
		local number_of_labels = #labels
		local time_delay_for_components_labeling = (number_of_components + 1) * time_delay_between_loops + 50
		local time_delay_for_labels_labeling = (number_of_labels + 1) * time_delay_between_loops + 50

		-- Check inventory for required components
		local missing_components = check_inventory_for_requirements(components)

		local all_needed_items_are_present = true
		for _, count in pairs(missing_components) do
			if count > 0 then
				all_needed_items_are_present = false
				break
			end
		end

		if all_needed_items_are_present then
			print("All required components are present!")
			add_all_components_to_circuitbox(components)
			Timer.Wait(function() add_labels_to_circuitbox_recursive(labels, 1) end, 50)
			Timer.Wait(function() add_wires_to_circuitbox_recursive(wires, 1) end, time_delay_for_components_labeling)
			Timer.Wait(function() rename_all_labels_in_circuitbox(labels) end, time_delay_for_labels_labeling)
			change_input_output_labels(inputs, outputs)
			
		else
			print("You are missing: ")
			for name, count in pairs(missing_components) do
				if count > 0 then
					print(name .. ": " .. count)
				end
			end
		end
	else
		print("file not found")
		print("saved designs:")
		print_all_saved_files()
	end
end


local function save_blueprint(provided_path)
	if Character.Controlled == nil then print("you dont have a character") return end
	if most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local file_path = (blue_prints.path .. "/" .. provided_path)
	
	local character = Character.Controlled
    
	local sacrificial_xml = XElement("Root")
	most_recent_circuitbox.Save(sacrificial_xml)
	local circuitbox_xml = tostring(sacrificial_xml)

	-- Open the file for writing
	local file = io.open(file_path, "w")

	-- Check if the file was successfully opened
	if file then
		-- Write the XML string to the file
		file:write(circuitbox_xml)
		
		-- Close the file
		file:close()
		
		print("blueprint saved to " .. file_path)
		return
	else
		print("Error: Could not open file for writing")
	end
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
			construct_blueprint(command[2])
		else
			print("No filename given. EX: bp load file_name.txt")
		end
	end
	
	
	if command[1] == "save" then
		if command[2] ~= nil then
			print("Attempting to save blueprint")
			save_blueprint(command[2])
		else
			print("No filename given. EX: bp save file_name.txt")
		end
	end
	
	
	if command[1] == "list" then
		print_all_saved_files()
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


--save a reference to the most recently interacted circuit box
Hook.Add("item.interact", "get_most_recent_circuitbox", function(potential_circuit_box, characterPicker, ignoreRequiredItemsBool, forceSelectKeyBool, forceActionKeyBool)
	if Character.Controlled == nil then return end
	if potential_circuit_box.Prefab.Identifier == "circuitbox" then
		most_recent_circuitbox = potential_circuit_box
	end
end)


--[[
Hook.Add("item.interact", "tagPrinter", function(item, characterPicker, ignoreRequiredItemsBool, forceSelectKeyBool, forceActionKeyBool)
   
	local myTags = item.GetTags()

	print("-------------")
	print("Item:----------")
	print(item.Prefab.Identifier)


	print("Tags:---------")
	for tag in myTags do
		print(tag)
	end
	print("-------------")
end)
--]]