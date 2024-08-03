if SERVER then return end --prevents it from running on the server



function parseXML(xmlString)
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
        local item = component:match('item="([^"]+)"')
        local class = component:match('Class="([^"]+)"')
        
        local componentData = {
            id = id,
            position = {x = tonumber(positionX), y = tonumber(positionY)},
            usedResource = usedResource,
            item = item,
            class = {
                name = class,
                attributes = {}
            }
        }
        
        -- Parse additional attributes for the class
        for attr, value in component:gmatch('(%w+)="([^"]*)"') do
            if attr ~= "id" and attr ~= "position" and attr ~= "backingitemid" and 
               attr ~= "usedresource" and attr ~= "item" and attr ~= "Class" then
                componentData.class.attributes[attr] = value
            end
        end
        
        table.insert(components, componentData)
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






function check_inventory_for_requirements(components)
    local missing_components = {}
    for _, component in ipairs(components) do
        missing_components[component.item] = (missing_components[component.item] or 0) + 1
    end
    local character = Character.Controlled
    
    local fpgacircuit_count = 0
    
    -- First pass: count regular items and fpgacircuits
    for inventory_item in character.Inventory.AllItems do
        local identifier = tostring(inventory_item.Prefab.Identifier)
        if identifier == "fpgacircuit" then
            fpgacircuit_count = fpgacircuit_count + 1
        elseif missing_components[identifier] and missing_components[identifier] > 0 then
            missing_components[identifier] = missing_components[identifier] - 1
        end
    end
    
    -- Second pass: use fpgacircuits as wildcards only for remaining missing items
    for identifier, count in pairs(missing_components) do
        if count > 0 and fpgacircuit_count > 0 then
            local used_fpga = math.min(count, fpgacircuit_count)
            missing_components[identifier] = count - used_fpga
            fpgacircuit_count = fpgacircuit_count - used_fpga
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









function add_component_to_circuitbox(component, use_fpga)
    if blue_prints.most_recent_circuitbox == nil then 
        print("No circuitbox detected")
        return 
    end
	
	if component.item == "oscillatorcomponent" then component.item = "oscillator" end --these components are named strangely and break convention
	if component.item == "concatenationcomponent" then component.item = "concatcomponent" end
	if component.item == "exponentiationcomponent" then component.item = "powcomponent" end
	if component.item == "regexfind" then component.item = "regexcomponent" end
	if component.item == "signalcheck" then component.item = "signalcheckcomponent" end
	if component.item == "squareroot" then component.item = "squarerootcomponent" end
	
    local item_to_add = use_fpga and ItemPrefab.GetItemPrefab("fpgacircuit") or ItemPrefab.GetItemPrefab(component.item)
    local component_position = Vector2(component.position.x, component.position.y)
    blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").AddComponent(item_to_add, component_position)
    --print(string.format("Added component %s at position (%.2f, %.2f)", use_fpga and "fpgacircuit" or component.item, component_position.x, component_position.y))
end

function add_all_components_to_circuitbox(components, index, inventory_status)
    if blue_prints.most_recent_circuitbox == nil then 
        print("No circuitbox detected")
        return 
    end
    index = index or 1  -- Start with the first component if no index is provided
    inventory_status = inventory_status or check_inventory_for_requirements(components)

    if index <= #components then
        local component = components[index]
        local use_fpga = inventory_status[component.item] and inventory_status[component.item] > 0

        add_component_to_circuitbox(component, use_fpga)

        if use_fpga then
            inventory_status[component.item] = inventory_status[component.item] - 1
            if inventory_status[component.item] == 0 then
                inventory_status[component.item] = nil
            end
        end

        -- Schedule the next addition with a delay
        Timer.Wait(function() add_all_components_to_circuitbox(components, index + 1, inventory_status) end, blue_prints.time_delay_between_loops)
    else
        -- If all components are added, print a message
        print("All components added.")
    end
end


function add_wires_to_circuitbox_recursive(wires, index)
    if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
    
    local first_connection = nil
    local second_connection = nil
    
    local components = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Components
    local input_output_nodes = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").InputOutputNodes
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
        blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").AddWire(first_connection, second_connection)
    end
    
    -- Recur to the next wire
	Timer.Wait(function() add_wires_to_circuitbox_recursive(wires, index + 1) end, blue_prints.time_delay_between_loops)
end


function change_input_output_labels(input_dict, output_dict)
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local input_output_nodes = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").InputOutputNodes 
	local input_connection_node = getNthValue(input_output_nodes, 1)
	local output_connection_node = getNthValue(input_output_nodes, 2)
		
	blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").SetConnectionLabelOverrides(input_connection_node, input_dict) 
	blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").SetConnectionLabelOverrides(output_connection_node, output_dict) 
end


function add_labels_to_circuitbox_recursive(labels, index)
    if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
    
    -- Base case: if we've processed all labels, return
    if index > #labels then
        return
    end
    
    -- Process the current label
    local label = labels[index]
	local x_offset_for_resizing = label.position.x - (label.size.width/2) + 128
	local y_offset_for_resizing = label.position.y + (label.size.height/2) - 128
	
    local label_position = Vector2(x_offset_for_resizing, y_offset_for_resizing)
    blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").AddLabel(label_position)
    
    -- Recursive call to process the next label
	Timer.Wait(function() add_labels_to_circuitbox_recursive(labels, index + 1) end, blue_prints.time_delay_between_loops)
end



function rename_all_labels_in_circuitbox(labels)
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local label_nodes = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Labels 

	 for i, label in ipairs(labels) do
        --print(string.format("  Label %d:", i))
        --print(string.format("    ID: %s", label.id))
        --print(string.format("    Color: %s", label.color))
        --print(string.format("    Position: (%.2f, %.2f)", label.position.x, label.position.y))
        --print(string.format("    Size: %.2f x %.2f", label.size.width, label.size.height))
        --print(string.format("    Header: %s", label.header))
        --print(string.format("    Body: %s", label.body))
		
		if label.header == nil then label.header = "" end
		if label.body == nil then label.body = "" end
		
		local label_node = getNthValue(label_nodes, i)
		local label_header = blue_prints.net_limited_string_type(tostring(label.header))
		local label_body = blue_prints.net_limited_string_type(tostring(label.body))
		local label_color = hexToRGBA(label.color)
		
		blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").RenameLabel(label_node, label_color, label_header, label_body)
    end
	
	print("All labels added.")
end

local function resize_label(label_node, direction, resize_vector)
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
	
	blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").ResizeNode(label_node, direction, resize_vector)
end


function resize_labels(labels_from_blueprint)
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local label_nodes_in_box = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Labels 

	 for i, label_in_blueprint in ipairs(labels_from_blueprint) do
		
		local label_node = getNthValue(label_nodes_in_box, i)
		
		local amount_to_expand_x = label_in_blueprint.size.width - label_node.size.X
		amount_to_expand_x = amount_to_expand_x
		local resize_amount_right = Vector2(amount_to_expand_x, 256) --the 256 doesnt do anything, but if you send a 0 it doesnt work
		blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").ResizeNode(label_node, 2, resize_amount_right) --2 is expand right
		
		local amount_to_expand_y = label_in_blueprint.size.height - label_node.size.Y
		local resize_amount_y = Vector2(256, -amount_to_expand_y)
		
		Timer.Wait(function() resize_label(label_node, 1, resize_amount_y) end, 200) --the commands override each other if sent too fast. 1 is expand down.
		
    end
	
	print("All labels repositioned.")
end




function update_values_in_components(components_from_blueprint) 
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local components_in_box = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Components
	
	for index, component_in_box in ipairs(components_in_box) do
		
		local component_to_copy = components_from_blueprint[index]
		
		local component_class_to_change = component_in_box.Item.GetComponentString(component_to_copy.class.name)
		if component_class_to_change then
			for attr, value in pairs(component_to_copy.class.attributes) do
				--print("  " .. attr .. ":", value)
				
				
				
				if component_to_copy.class.name == "MemoryComponent" then
					if tostring(attr) == "Value" then
						component_class_to_change.Value = value
					end
				end

				if component_to_copy.class.name == "ArithmeticComponent" then
					if tostring(attr) == "ClampMax" then
						component_class_to_change.ClampMax = tonumber(value)
					end
					if tostring(attr) == "ClampMin" then
						component_class_to_change.ClampMin = tonumber(value)
					end
					if tostring(attr) == "TimeFrame" then
						component_class_to_change.TimeFrame = tonumber(value)
					end
				end

				if component_to_copy.class.name == "TrigonometricFunctionComponent" then
					if tostring(attr) == "UseRadians" then
						component_class_to_change.UseRadians = string_to_bool(value)
					end
				end

				if component_to_copy.class.name == "ColorComponent" then
					if tostring(attr) == "UseHSV" then
						component_class_to_change.UseHSV = string_to_bool(value)
					end
				end

				if component_to_copy.class.name == "ConcatComponent" then
					if tostring(attr) == "Separator" then
						component_class_to_change.Separator = value
					end
				end

				if component_to_copy.class.name == "StringComponent" then
					if tostring(attr) == "TimeFrame" then
						component_class_to_change.TimeFrame = tonumber(value)
					end
				end

				if component_to_copy.class.name == "DelayComponent" then
					if tostring(attr) == "Delay" then
						component_class_to_change.Delay = tonumber(value)
					end
					if tostring(attr) == "ResetWhenSignalReceived" then
						component_class_to_change.ResetWhenSignalReceived = string_to_bool(value)
					end
					if tostring(attr) == "ResetWhenDifferentSignalReceived" then
						component_class_to_change.ResetWhenDifferentSignalReceived = string_to_bool(value)
					end
				end

				if component_to_copy.class.name == "EqualsComponent" then
					if tostring(attr) == "Output" then
						component_class_to_change.Output = value
					end
					if tostring(attr) == "FalseOutput" then
						component_class_to_change.FalseOutput = value
					end
					if tostring(attr) == "TimeFrame" then
						component_class_to_change.TimeFrame = tonumber(value)
					end
				end

				if component_to_copy.class.name == "ExponentiationComponent" then
					if tostring(attr) == "Exponent" then
						component_class_to_change.Exponent = tonumber(value)
					end
				end

				if component_to_copy.class.name == "ModuloComponent" then
					if tostring(attr) == "Modulus" then
						component_class_to_change.Modulus = tonumber(value)
					end
				end

				if component_to_copy.class.name == "NotComponent" then
					if tostring(attr) == "ContinuousOutput" then
						component_class_to_change.ContinuousOutput = string_to_bool(value)
					end
				end

				if component_to_copy.class.name == "BooleanOperatorComponent" then
					if tostring(attr) == "Output" then
						component_class_to_change.Output = value
					end
					if tostring(attr) == "FalseOutput" then
						component_class_to_change.FalseOutput = value
					end
					if tostring(attr) == "TimeFrame" then
						component_class_to_change.TimeFrame = tonumber(value)
					end
				end

				if component_to_copy.class.name == "OscillatorComponent" then
					if tostring(attr) == "OutputType" then
						if value == "Pulse" then component_class_to_change.OutputType = component_class_to_change.WaveType.Pulse end
						if value == "Sawtooth" then component_class_to_change.OutputType = component_class_to_change.WaveType.Sawtooth end
						if value == "Sine" then component_class_to_change.OutputType = component_class_to_change.WaveType.Sine end
						if value == "Square" then component_class_to_change.OutputType = component_class_to_change.WaveType.Square end
						if value == "Triangle" then component_class_to_change.OutputType = component_class_to_change.WaveType.Triangle end
					end
					if tostring(attr) == "Frequency" then
						component_class_to_change.Frequency = tonumber(value)
					end
				end

				if component_to_copy.class.name == "RegExFindComponent" then
					if tostring(attr) == "Output" then
						component_class_to_change.Output = value
					end
					if tostring(attr) == "UseCaptureGroup" then
						component_class_to_change.UseCaptureGroup = string_to_bool(value)
					end
					if tostring(attr) == "OutputEmptyCaptureGroup" then
						component_class_to_change.OutputEmptyCaptureGroup = string_to_bool(value)
					end
					if tostring(attr) == "FalseOutput" then
						component_class_to_change.FalseOutput = value
					end
					if tostring(attr) == "ContinuousOutput" then
						component_class_to_change.ContinuousOutput = string_to_bool(value)
					end
					if tostring(attr) == "Expression" then
						component_class_to_change.Expression = value
					end
				end

				if component_to_copy.class.name == "RelayComponent" then
					if tostring(attr) == "IsOn" then
						component_class_to_change.IsOn = string_to_bool(value)
					end
				end

				if component_to_copy.class.name == "SignalCheckComponent" then
					if tostring(attr) == "Output" then
						component_class_to_change.Output = value
					end
					if tostring(attr) == "FalseOutput" then
						component_class_to_change.FalseOutput = value
					end
					if tostring(attr) == "TargetSignal" then
						component_class_to_change.TargetSignal = value
					end
				end

				if component_to_copy.class.name == "WifiComponent" then
					if tostring(attr) == "Channel" then
						component_class_to_change.Channel = tonumber(value)
					end
				end
				
			end
		end	

	end
	
	print("All values updated inside components.")
end






function construct_blueprint(provided_path)
	if Character.Controlled == nil then print("you dont have a character") return end

	local file_path = (blue_prints.save_path .. "/" .. provided_path)
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
		local time_delay_for_components = (number_of_components + 10) * blue_prints.time_delay_between_loops + 50
		local time_delay_for_labels = (number_of_labels + 40) * blue_prints.time_delay_between_loops + 50 --labels seem to take a long time in game

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
			Timer.Wait(function() add_wires_to_circuitbox_recursive(wires, 1) end, time_delay_for_components)
			Timer.Wait(function() rename_all_labels_in_circuitbox(labels) end, time_delay_for_labels)
			change_input_output_labels(inputs, outputs)
			Timer.Wait(function() update_values_in_components(components) end, time_delay_for_components)
			Timer.Wait(function() resize_labels(labels) end, time_delay_for_labels)
			
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













