if SERVER then return end --prevents it from running on the server

local path_to_loaded_file = nil
local has_load_completed_array = {
	["clear_circuitbox_complete"] = false,
    ["add_components_complete"] = false,
	["add_wires_complete"] = false,
    ["add_labels_complete"] = false,
    ["rename_labels_complete"] = false,
    ["change_input_output_labels_complete"] = false,
	["update_values_in_components_complete"] = false,
	["resize_labels_complete"] = false,
	["move_input_output_nodes_complete"] = false
}





function blue_prints.parseXML(xmlString)
	local inputs = {}
	local outputs = {}
	local components = {}
	local wires = {}
	local labels = {}
	local inputNodePos = {}
    local outputNodePos = {}

    -- Parse InputNode
    local inputNode = xmlString:match("<InputNode[^>]+>")
    if inputNode then
        local posX, posY = inputNode:match('pos="([%d%.%-]+),([%d%.%-]+)"')
        inputNodePos = {x = tonumber(posX), y = tonumber(posY)}
    end

    -- Parse OutputNode
    local outputNode = xmlString:match("<OutputNode[^>]+>")
    if outputNode then
        local posX, posY = outputNode:match('pos="([%d%.%-]+),([%d%.%-]+)"')
        outputNodePos = {x = tonumber(posX), y = tonumber(posY)}
    end

    -- Parse input and output labels (if any)
    for name, value in xmlString:gmatch('<ConnectionLabelOverride name="([^"]+)" value="([^"]+)"') do
        if name:match("^signal_in") then
            inputs[name] = value
        elseif name:match("^signal_out") then
            outputs[name] = value
        end
    end

	-- Parse Components
	for component in xmlString:gmatch('<Component.-/>') do
		local id = component:match('id="(%d+)"')
		local positionX, positionY = component:match('position="([%-%d%.]+),([%-%d%.]+)"')
		local usedResource = component:match('usedresource="([^"]+)"')
		
		-- Try new format first, then fall back to old format
		local item = component:match('item=<<<STRINGSTART>>>([^<]+)<<<STRINGEND>>>') or component:match('item="([^"]+)"')
        local class = component:match('Class=<<<STRINGSTART>>>([^<]+)<<<STRINGEND>>>') or component:match('Class="([^"]+)"')
		
		
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
		
		
		-- Parse additional attributes for the class, including Value
        -- First try new format with STRINGSTART/STRINGEND
        for attr, value in component:gmatch('(%w+)=<<<STRINGSTART>>>(.-)<<<STRINGEND>>>') do
            if attr ~= "id" and attr ~= "position" and attr ~= "backingitemid" and 
               attr ~= "usedresource" and attr ~= "item" and attr ~= "Class" then
                componentData.class.attributes[attr] = value
            end
        end
        
        -- If no attributes found, try old format
        if next(componentData.class.attributes) == nil then
            for attr, value in component:gmatch('(%w+)="(.-)"  ') do
                if attr ~= "id" and attr ~= "position" and attr ~= "backingitemid" and 
                   attr ~= "usedresource" and attr ~= "item" and attr ~= "Class" then
                    componentData.class.attributes[attr] = value
                end
            end
        end
		
		
		table.insert(components, componentData)
	end
	
	-- Parse Wires
	wires = {}
	for wire in xmlString:gmatch("<Wire.-</Wire>") do
		local wireData = {
			id = wire:match('id="(%d+)"'),
			prefab = wire:match('prefab="([^"]+)"')
		}
		
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
		
		
		local html_entities = {
			['&quot;'] = '"',
			['&amp;'] = '&',
			['&lt;'] = '<',
			['&gt;'] = '>',
			['&nbsp;'] = ' ',
			['&iexcl;'] = '¡',
			['&cent;'] = '¢',
			['&pound;'] = '£',
			['&curren;'] = '¤',
			['&yen;'] = '¥',
			['&brvbar;'] = '¦',
			['&sect;'] = '§',
			['&uml;'] = '¨',
			['&copy;'] = '©',
			['&ordf;'] = 'ª',
			['&laquo;'] = '«',
			['&not;'] = '¬',
			['&shy;'] = '­',
			['&reg;'] = '®',
			['&macr;'] = '¯',
			['&deg;'] = '°',
			['&plusmn;'] = '±',
			['&sup2;'] = '²',
			['&sup3;'] = '³',
			['&acute;'] = '´',
			['&micro;'] = 'µ',
			['&para;'] = '¶',
			['&middot;'] = '·',
			['&cedil;'] = '¸',
			['&sup1;'] = '¹',
			['&ordm;'] = 'º',
			['&raquo;'] = '»',
			['&frac14;'] = '¼',
			['&frac12;'] = '½',
			['&frac34;'] = '¾',
			['&iquest;'] = '¿',
			['&#xA;'] = '\n',
			['&#xD;'] = '\n'
		}

		local function contains_html_entities(str)
			return str:find('&[^;]+;')
		end

		local function decode_html_entities(str)
			if not contains_html_entities(str) then
				return str
			end
			return (str:gsub('(&[^;]+;)', function(entity)
				return html_entities[entity] or entity
			end))
		end
		
		if header then
			header = decode_html_entities(header)
		end
		if body then
			body = decode_html_entities(body)
		end

		
        table.insert(labels, {
            id = id,
            color = color,
            position = {x = tonumber(posX), y = tonumber(posY)},
            size = {width = tonumber(sizeW), height = tonumber(sizeH)},
            header = header,
            body = body
        })
    end
	
	blue_prints.add_advertisement_label(components, labels, inputNodePos, outputNodePos)--if there is no ad, add one

    return inputs, outputs, components, wires, labels, inputNodePos, outputNodePos
end




function blue_prints.check_inventory_for_requirements(components)



	--print("Game mode: ", Game.IsSubEditor)

    local missing_components = {}
	
	if Game.IsSubEditor then return missing_components end --if in sub editor, you dont have to worry about inventory
	
    for _, component in ipairs(components) do
        missing_components[component.item] = (missing_components[component.item] or 0) + 1
    end
    local character = Character.Controlled
    
    local fpgacircuit_count = 0
    
	--count inventory items already stored inside the box
	if blue_prints.most_recent_circuitbox ~= nil then 
		local items_already_in_box = blue_prints.get_components_currently_in_circuitbox(blue_prints.most_recent_circuitbox)
		
		for resource, count in pairs(items_already_in_box) do
			local identifier = resource
			if identifier == "fpgacircuit" then
				fpgacircuit_count = fpgacircuit_count + count
			elseif missing_components[identifier] and missing_components[identifier] > 0 then
				missing_components[identifier] = missing_components[identifier] - count
			end
		end
	end
	
	
	
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









function blue_prints.add_component_to_circuitbox(component, use_fpga)
    if blue_prints.most_recent_circuitbox == nil then print("No circuitbox detected") return end
	
	
	--due to refactoring I no longer need this, but will keep it for historical compatability with older blueprints
	if component.item == "oscillatorcomponent" then component.item = "oscillator" end --these components are named strangely and break convention
	if component.item == "concatenationcomponent" then component.item = "concatcomponent" end
	if component.item == "exponentiationcomponent" then component.item = "powcomponent" end
	if component.item == "regexfind" then component.item = "regexcomponent" end
	if component.item == "signalcheck" then component.item = "signalcheckcomponent" end
	if component.item == "squareroot" then component.item = "squarerootcomponent" end
	

    local item_to_add = use_fpga and ItemPrefab.GetItemPrefab("fpgacircuit") or ItemPrefab.GetItemPrefab(component.item)
    local component_position = Vector2(component.position.x, component.position.y)
	--print(tostring(component))
	--print(item_to_add)
    blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").AddComponent(item_to_add, component_position)
    --print(string.format("Added component %s at position (%.2f, %.2f)", use_fpga and "fpgacircuit" or component.item, component_position.x, component_position.y))
end

function blue_prints.add_all_components_to_circuitbox(components, index, inventory_status)
    if blue_prints.most_recent_circuitbox == nil then print("No circuitbox detected") return end
	
    index = index or 1  -- Start with the first component if no index is provided
    inventory_status = inventory_status or blue_prints.check_inventory_for_requirements(components)

    if index <= #components then
        local component = components[index]
        local use_fpga = inventory_status[component.item] and inventory_status[component.item] > 0

        blue_prints.add_component_to_circuitbox(component, use_fpga)

        if use_fpga then
            inventory_status[component.item] = inventory_status[component.item] - 1
            if inventory_status[component.item] == 0 then
                inventory_status[component.item] = nil
            end
        end

        -- Schedule the next addition with a delay
        Timer.Wait(function() blue_prints.add_all_components_to_circuitbox(components, index + 1, inventory_status) end, blue_prints.time_delay_between_loops)
    else
        -- If all components are added, print a message
        --print("All components added.")
		has_load_completed_array["add_components_complete"] = true
    end
end


function blue_prints.add_wires_to_circuitbox_recursive(wires, index)
    if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
    
    local first_connection = nil
    local second_connection = nil
    
    local components = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Components
    local input_output_nodes = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").InputOutputNodes
    local input_connection_node = blue_prints.getNthValue(input_output_nodes, 1)
    local input_connections = input_connection_node.Connectors
    local output_connection_node = blue_prints.getNthValue(input_output_nodes, 2)
    local output_connections = output_connection_node.Connectors

    if index > #wires then
		--print("All wires added.")
		has_load_completed_array["add_wires_complete"] = true
        return
    end
    
    local wire = wires[index]
	
	--select wire color
	local wire_prefab = ItemPrefab.GetItemPrefab(tostring(wire.prefab))
	LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.CircuitBoxUI"], "SelectWire")
	local circuitbox_ui = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").UI.SelectWire(nil, wire_prefab)
    
    for component_key, component_value in pairs(components) do
        local connectors = component_value.Connectors
		
		for i = 0, connectors.length-1 do
			if tostring(component_value.ID) == tostring(wire.from.target) and tostring(connectors[i].name) == tostring(wire.from.name) then
                first_connection = connectors[i]
            end
            
            if tostring(component_value.ID) == tostring(wire.to.target) and tostring(connectors[i].name) == tostring(wire.to.name) then
                second_connection = connectors[i]
            end
		end
		
    end
	
	
	if wire.from.target == nil then
        local input_to_target = string.match(tostring(wire.from.name), "%d+")
        first_connection = input_connections[tonumber(input_to_target)-1]
    end
    
    if wire.to.target == nil then
        local input_to_target = string.match(tostring(wire.to.name), "%d+")
        second_connection = output_connections[tonumber(input_to_target)-1]
    end
    
    if first_connection and second_connection then
        blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").AddWire(first_connection, second_connection)
    end
    
    -- Recur to the next wire
	Timer.Wait(function() blue_prints.add_wires_to_circuitbox_recursive(wires, index + 1) end, blue_prints.time_delay_between_loops)
end


function blue_prints.change_input_output_labels(input_dict, output_dict)
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local input_output_nodes = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").InputOutputNodes 
	local input_connection_node = blue_prints.getNthValue(input_output_nodes, 1)
	local output_connection_node = blue_prints.getNthValue(input_output_nodes, 2)
		
	blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").SetConnectionLabelOverrides(input_connection_node, input_dict) 
	blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").SetConnectionLabelOverrides(output_connection_node, output_dict) 
	
	has_load_completed_array["change_input_output_labels_complete"] = true
end





function blue_prints.add_advertisement_label(components, labels, inputNodePos, outputNodePos)
    if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
    
    --just add an extra label to labels table thats to the right of the rightmost component or label
	--dont do this if there is already an advertisement label
	advertisement_header = "Blueprints"
	
	for _, label in ipairs(labels) do --if there is already an advertisement, dont add another
		if label.header and label.header == advertisement_header then
			return 
		end
	end
	
	
	local furthestRight = blue_prints.getFurthestRightElement(components, labels, inputNodePos, outputNodePos)

	--print("Furthest right element type:", furthestRight.type)
	--print("Furthest right x-coordinate:", furthestRight.x)
	--print("Furthest right y-coordinate:", furthestRight.y)
	
	
	local function addManualLabel(id, color, posX, posY, sizeW, sizeH, header, body)
        table.insert(labels, {
            id = id,
            color = color,
            position = {x = tonumber(posX), y = tonumber(posY)},
            size = {width = tonumber(sizeW), height = tonumber(sizeH)},
            header = header,
            body = body
        })
    end

	addManualLabel(#labels, "#0082FF", furthestRight.x + 384, furthestRight.y, 512, 256, advertisement_header, 'Circuit made with Blueprints. \n \n Get it now on the steam workshop!')
	
end





function blue_prints.add_labels_to_circuitbox_recursive(labels, index)
    if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
    
    -- Base case: if we've processed all labels, return
    if index > #labels then
		has_load_completed_array["add_labels_complete"] = true
        return
    end
    
    -- Process the current label
    local label = labels[index]
	local x_offset_for_resizing = label.position.x - (label.size.width/2) + 128
	local y_offset_for_resizing = label.position.y + (label.size.height/2) - 128
	
    local label_position = Vector2(x_offset_for_resizing, y_offset_for_resizing)
    blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").AddLabel(label_position)
    
    -- Recursive call to process the next label
	Timer.Wait(function() blue_prints.add_labels_to_circuitbox_recursive(labels, index + 1) end, blue_prints.time_delay_between_loops)
end



function blue_prints.rename_all_labels_in_circuitbox(labels)
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
		
		local label_node = blue_prints.getNthValue(label_nodes, i)
		local label_header = blue_prints.net_limited_string_type(tostring(label.header))
		local label_body = blue_prints.net_limited_string_type(tostring(label.body))
		local label_color = blue_prints.hexToRGBA(label.color)
		
		blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").RenameLabel(label_node, label_color, label_header, label_body)
    end
	
	--print("All labels added.")
	has_load_completed_array["rename_labels_complete"] = true
end

local function resize_label(label_node, direction, resize_vector)
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
	
	blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").ResizeNode(label_node, direction, resize_vector)
end


function blue_prints.resize_labels(labels_from_blueprint)
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local label_nodes_in_box = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Labels 

	 for i, label_in_blueprint in ipairs(labels_from_blueprint) do
		
		local label_node = blue_prints.getNthValue(label_nodes_in_box, i)
		
		local amount_to_expand_x = label_in_blueprint.size.width - label_node.size.X
		amount_to_expand_x = amount_to_expand_x
		local resize_amount_right = Vector2(amount_to_expand_x, 256) --the 256 doesnt do anything, but if you send a 0 it doesnt work
		blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").ResizeNode(label_node, 2, resize_amount_right) --2 is expand right
		
		local amount_to_expand_y = label_in_blueprint.size.height - label_node.size.Y
		local resize_amount_y = Vector2(256, -amount_to_expand_y)
		
		Timer.Wait(function() resize_label(label_node, 1, resize_amount_y) end, 200) --the commands override each other if sent too fast. 1 is expand down.
		
    end
	
	has_load_completed_array["resize_labels_complete"] = true
end




function blue_prints.update_values_in_components(components_from_blueprint) 
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local components_in_box = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Components
	
	for index, component_in_box in ipairs(components_in_box) do
		
		local component_to_copy = components_from_blueprint[index]
		
		local component_class_to_change = component_in_box.Item.GetComponentString(component_to_copy.class.name)
		if component_class_to_change then
			for attr, value in pairs(component_to_copy.class.attributes) do
				--print("  " .. attr .. ":", value)
				
				
				--print(component_class_to_change)
				--print(tostring(component_class_to_change[attr]))
				
				local success = false
				local result
				
				
				--print(attr)
				local is_actually_editable = false
				local my_editables =  component_in_box.Item.GetInGameEditableProperties(false)
				for tuple in my_editables do 
					--print(tuple.Item2.name, ' = ', tuple.Item2.GetValue(tuple.Item1)) 
					if tostring(tuple.Item2.name) == tostring(attr) then
						is_actually_editable = true
						break
					end
				end
				
				
				if is_actually_editable then --only attempt load if its actually editable
				
					-- First attempt (string version)
					if not success then
						success, result = pcall(function()
							component_class_to_change[attr] = value
							return "String operation successful"
						end)
					end
					
					-- Second attempt (number version)
					if not success then
						success, result = pcall(function()
							component_class_to_change[attr] = tonumber(value)
							return "Number operation successful"
						end)
					end

					-- Third attempt (bool version)
					if not success then
						success, result = pcall(function()
							component_class_to_change[attr] = blue_prints.string_to_bool(value)
							return "Boolean operation successful"
						end)
					end
					
					
					
					--oscillator is a special case because it uses enums
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
						success = true
					end
					

					if success then
						--print("Operation succeeded:", result)
					else
						print("All operations failed. Last error: ", result)
						print("Component type that failed: ", component_class_to_change.name)
					end

					
					--print("Game mode: ", Game.GameSession.GameMode.Name)
					if Game.GameSession ~= nil then --a nil check for the sub editor
						local gameModeName = tostring(Game.GameSession.GameMode.Name)
						if not Game.GameSession.GameMode.IsSinglePlayer then --these dont exist in single player so will cause a crash if not avoided.
							local property = component_class_to_change.SerializableProperties[Identifier(attr)]
							Networking.CreateEntityEvent(component_in_box.Item, Item.ChangePropertyEventData(property, component_class_to_change))
						end
					end
				
				
				end

				
				
			end
		end	


	end

	--print("All values updated inside components.")
	has_load_completed_array["update_values_in_components_complete"] = true
end

function blue_prints.move_input_output_nodes(inputNodePos, outputNodePos)
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local input_output_nodes = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").InputOutputNodes 
	local input_connection_node = blue_prints.getNthValue(input_output_nodes, 1)
	local output_connection_node = blue_prints.getNthValue(input_output_nodes, 2)

    
    
    local sacrificial_immutable_array_input = blue_prints.immutable_array_type.Create(input_connection_node)
    local input_connection_node_in_immutable_aray = sacrificial_immutable_array_input.Add(input_connection_node)
    
	
	local input_delta_x = inputNodePos.x - input_connection_node.Position.X
	local input_delta_y = inputNodePos.y - input_connection_node.Position.Y
	local move_input_vector = Vector2(input_delta_x, input_delta_y)
	
	blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").MoveComponent(move_input_vector, input_connection_node_in_immutable_aray) 
	
	
	
	local sacrificial_immutable_array_output = blue_prints.immutable_array_type.Create(output_connection_node)
    local output_connection_node_in_immutable_aray = sacrificial_immutable_array_output.Add(output_connection_node)
	
    local output_delta_x = outputNodePos.x - output_connection_node.Position.X
	local output_delta_y = outputNodePos.y - output_connection_node.Position.Y
	local move_output_vector = Vector2(output_delta_x, output_delta_y)
    
    blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").MoveComponent(move_output_vector, output_connection_node_in_immutable_aray) 
	
	has_load_completed_array["move_input_output_nodes_complete"] = true
end





function blue_prints.clear_circuitbox() 
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
	
	local components = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Components
	if #components > 0 then
		local first_component = blue_prints.getNthValue(components, 1)
		local component_immutable_array = blue_prints.immutable_array_type.Create(first_component)
		
		for _, component in ipairs(components) do
			component_immutable_array = component_immutable_array.Add(component)
		end
		blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").RemoveComponents(component_immutable_array)
	end
	
	local labels = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Labels
	if #labels > 0 then
		local first_label = blue_prints.getNthValue(labels, 1)
		local label_immutable_array = blue_prints.immutable_array_type.Create(first_label)
		
		for _, label in ipairs(labels) do
			label_immutable_array = label_immutable_array.Add(label)
		end
		blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").RemoveLabel(label_immutable_array)
	end
	
	
	
	local wires = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Wires
	if #wires > 0 then
		local first_wire = blue_prints.getNthValue(wires, 1)
		local wire_immutable_array = blue_prints.immutable_array_type.Create(first_wire)
		
		for _, wire in ipairs(wires) do
			wire_immutable_array = wire_immutable_array.Add(wire)
		end
		blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").RemoveWires(wire_immutable_array)
	end
	
	
	
	--move the input output panels back to their original location
	local move_input_vector = Vector2(-512, 0)
	local move_output_vector = Vector2(512, 0)
	blue_prints.move_input_output_nodes(move_input_vector, move_output_vector)
	
	--reset the labels on the input output panels
	local empty_input = {signal_in1 = "", signal_in2 = "", signal_in3 = "", signal_in4 = "", signal_in5 = "", signal_in6 = "", signal_in7 = "", signal_in8 = ""}
	local empty_output = {signal_out1 = "", signal_out2 = "", signal_out3 = "", signal_out4 = "", signal_out5 = "", signal_out6 = "", signal_out7 = "", signal_out8 = ""}
	blue_prints.change_input_output_labels(empty_input, empty_output)
	
	has_load_completed_array["clear_circuitbox_complete"] = true
end






function blue_prints.wait_for_clear_circuitbox(inputs, outputs, components, wires, labels, inputNodePos, outputNodePos) 


	local number_of_components = #components
	local number_of_labels = #labels
	local number_of_wires = #wires
	local time_delay_for_components = (number_of_components + 10) * blue_prints.time_delay_between_loops + 50
	local time_delay_for_labels = (number_of_labels + 40) * blue_prints.time_delay_between_loops + 50 --labels seem to take a long time in game
	local time_delay_for_wire_completion = (number_of_wires + 10) * blue_prints.time_delay_between_loops + 50
	
	local longer_delay = math.max(time_delay_for_components + time_delay_for_wire_completion, time_delay_for_labels + 1000) + 1000

	blue_prints.add_all_components_to_circuitbox(components)
	Timer.Wait(function() blue_prints.add_labels_to_circuitbox_recursive(labels, 1) end, 50)
	Timer.Wait(function() blue_prints.add_wires_to_circuitbox_recursive(wires, 1) end, time_delay_for_components)
	Timer.Wait(function() blue_prints.rename_all_labels_in_circuitbox(labels) end, time_delay_for_labels)
	blue_prints.change_input_output_labels(inputs, outputs)
	Timer.Wait(function() blue_prints.update_values_in_components(components) end, time_delay_for_components)
	Timer.Wait(function() blue_prints.resize_labels(labels) end, time_delay_for_labels)
	Timer.Wait(function() blue_prints.move_input_output_nodes(inputNodePos, outputNodePos) end, time_delay_for_components) --delayed because the change also changes the position
	
	Timer.Wait(function() blue_prints.delayed_loading_complete_array_check() end, longer_delay)
	Timer.Wait(function() blue_prints.delayed_loading_complete_unit_test() end, longer_delay)

end




function blue_prints.construct_blueprint(provided_path)
	if Character.Controlled == nil then print("you dont have a character") return end
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
	
	wires_added_complete = false
	labels_changed_complete = false
	
	
	if Game.Paused then --the load will fail if you attempt it while paused. This fixes that.
		print("Unpause the game to complete loading your circuit.")
		Timer.Wait(function() blue_prints.construct_blueprint(provided_path) end, 1000)
		return
	end

	-- Check if the filename already ends with .txt
    if not string.match(provided_path, "%.txt$") then
        -- Add .txt if it's not already present
        provided_path = provided_path .. ".txt"
    end

	local file_path = (blue_prints.save_path .. "/" .. provided_path)
	path_to_loaded_file = file_path
	local xmlContent, err = blue_prints.readFile(file_path)

	if xmlContent then
		-- In the usage section:
		local inputs, outputs, components, wires, labels, inputNodePos, outputNodePos = blue_prints.parseXML(xmlContent)
		
		-- Set the entire array to false
		for key, _ in pairs(has_load_completed_array) do
			has_load_completed_array[key] = false
		end
		
		
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
		
		--Check inventory for required components
		local missing_components = blue_prints.check_inventory_for_requirements(components)

		local all_needed_items_are_present = true
		for _, count in pairs(missing_components) do
			if count > 0 then
				all_needed_items_are_present = false
				break
			end
		end

		if all_needed_items_are_present then
			print("All required components are present! Now loading blueprint...")
			GUI.AddMessage('File Loading...', Color.White)
			blue_prints.clear_circuitbox()
			Timer.Wait(function() blue_prints.wait_for_clear_circuitbox(inputs, outputs, components, wires, labels, inputNodePos, outputNodePos) end, 500)
		else
			print("You are missing: ")
			GUI.AddMessage('Not Enough Components', Color.Red)
			for name, count in pairs(missing_components) do
				if count > 0 then
					print(name .. ": " .. count)
				end
			end
		end

		

		
	else
		print("file not found")
		print("saved designs:")
		blue_prints.print_all_saved_files()
	end
end





function blue_prints.delayed_loading_complete_array_check()

	local function allTrue(array)
		for key, value in pairs(array) do
			if value ~= true then
				return false -- If any value is not true, return false
			end
		end
		return true -- If the loop completes, all values are true
	end

	local result = allTrue(has_load_completed_array)
	if result then
		GUI.AddMessage('Load Complete', Color.White)
		print("Blueprint loading complete")
	else
		GUI.AddMessage('Loading Failed', Color.Red)
		
		message_box = GUI.MessageBox('Load Failed', 'Your circuit has failed to load. One of the load functions has failed to complete. Hit F3 for more details. \n \nTry loading it again. \n \nIf the problem persists please report this bug on the steam workshop page. Include a download link to your saved blueprint file and a screenshot of your console text (you can see that by hitting F3)', {'OK'}) 
		ok_button = nil
		
		if message_box.Buttons[0] == nil then --this is if no one has registered it. If some other mod registers it I dont want it to break.
			ok_button = message_box.Buttons[1]
		else --if its been registered, it will behave as a csharp table
			ok_button = message_box.Buttons[0]
		end
		
		ok_button.OnClicked = function ()
			message_box.Close()
		end
		
		for key, value in pairs(has_load_completed_array) do
			print(tostring(key) .. ": " .. tostring(value))
		end
	end

end





function blue_prints.delayed_loading_complete_unit_test()

	if blue_prints.unit_tests_enabled then

		xml_of_loaded_circuit = blue_prints.prepare_circuitbox_xml_for_saving()
		--run a unit test here to make sure it works
		local load_test_results = blue_prints.loading_complete_unit_test(path_to_loaded_file, xml_of_loaded_circuit)
		print("Passed loading unit test: " .. tostring(load_test_results))
		
		if load_test_results then
			--GUI.AddMessage('Load Complete!', Color.White)
		else
			GUI.AddMessage('Load Failed!', Color.Red)
			message_box = GUI.MessageBox('Load Failed', 'Your circuit has failed to load. Your blueprint file might be from an earlier version of Blueprints and nothing is actually wrong. Try saving it again (overwriting the original) to update your blueprint file to the latest version. \n \nIf you are certain your file is up to date try loading it again. Do not move or change anything during loading: the loaded circuit must match the blueprint file EXACTLY in order for you not to see this message. \n \nThis also means if the inputs change any values in any component the unit test will also fail. Same thing if you have some value that changes over time, like RGB or timing values from an oscillator. So the circuit might still be ok, it just does not match your save exactly. \n \nIf none of these exceptions apply and the problem persists please report this bug on the steam workshop page or the discord. Include a download link to your saved blueprint file and a screenshot of your console text (you can see that by hitting F3)', {'OK'}) 
		
			ok_button = nil
			
			if message_box.Buttons[0] == nil then --this is if no one has registered it. If some other mod registers it I dont want it to break.
				ok_button = message_box.Buttons[1]
			else --if its been registered, it will behave as a csharp table
				ok_button = message_box.Buttons[0]
			end
			
			ok_button.OnClicked = function ()
				message_box.Close()
			end
		end
	end

end