if SERVER then return end --prevents it from running on the server





















-- Function to extract components and their IDs
local function extractComponents(xmlString)
    local components = {}
    for id, position in xmlString:gmatch('<Component id="(%d+)" position="([^"]+)"') do
        components[#components + 1] = {id = tonumber(id), position = position}
    end
    table.sort(components, function(a, b) return a.id < b.id end)
    return components
end

-- Function to create ID mapping
local function createIdMapping(components)
    local idMap = {}
    local newId = 0
    for _, component in ipairs(components) do
        idMap[component.id] = newId
        newId = newId + 1
    end
    return idMap
end

-- Function to update component IDs and wire targets
local function updateXml(xmlString, idMap)
    -- Update component IDs
    xmlString = xmlString:gsub('<Component id="(%d+)"', function(id)
        return string.format('<Component id="%d"', idMap[tonumber(id)])
    end)
    
    -- Update wire targets
    xmlString = xmlString:gsub('target="(%d*)"', function(target)
        if target ~= "" then
            local newTarget = idMap[tonumber(target)]
            if newTarget then
                return string.format('target="%d"', newTarget)
            else
                print("Warning: No mapping found for target " .. target)
                return string.format('target="%s"', target)
            end
        else
            return 'target=""'
        end
    end)
    
    return xmlString
end

-- Main function to renumber components and update wire targets
local function renumberComponents(xmlString)
    local components = extractComponents(xmlString)
    local idMap = createIdMapping(components)
    return updateXml(xmlString, idMap)
end



























local function find_id_within_component(component_string)

	-- Define the pattern to match the id attribute value
	local pattern = 'id="(%d+)"'

	-- Extract the id value using string.match
	local id_value = string.match(component_string, pattern)

	-- Print the result
	if id_value then
		return id_value
	else
		return ""
	end

end


local function find_specific_component(xmlContent, target_component)
    -- Split the XML content into lines
    local lines = {}
    for line in string.gmatch(xmlContent, "[^\r\n]+") do
        table.insert(lines, line)
    end

    -- Define the pattern to match the component
    local pattern = "<Component.-/->"

    -- Initialize counters
    local count = 0

    -- Iterate through each line to find the specific component
    for i, line in ipairs(lines) do
        -- Check for components in the current line
        for component in string.gmatch(line, pattern) do
            count = count + 1
            if count == target_component then
                -- Return both the line number and the line content
                return i, line
            end
        end
    end

    -- Return nil, nil if the component was not found
    return nil, nil
end


local function count_component_number(xmlContent)

	-- Define the pattern to match the component
	local pattern = "<Component.-/->"

	-- Initialize counter
	local count = 0

	-- Use string.gmatch to iterate over all matches
	for _ in string.gmatch(xmlContent, pattern) do
		count = count + 1
	end
	
	return count

end


local function swap_lines_in_string(xmlContent, line1, line2)
	-- Split the text into lines
	local lines = {}
	for line in string.gmatch(xmlContent, "[^\r\n]+") do
		table.insert(lines, line)
	end

	-- Swap the specified lines
	if line1 <= #lines and line2 <= #lines then
		lines[line1], lines[line2] = lines[line2], lines[line1]
	else
		print("Error: Line numbers out of range.")
	end

	-- Join the lines back into a single string
	local swapped_text = table.concat(lines, "\n")

	return swapped_text
end



local function put_components_in_order(xmlContent)
	
	local something_in_xml_changed = false
	local number_of_components = count_component_number(xmlContent)
	
	for i = 1, number_of_components-1 do
		local first_line_number, first_line_content = find_specific_component(xmlContent, i)
		local second_line_number, second_line_content = find_specific_component(xmlContent, i+1)
		
		--print(first_line_content)
		--print(second_line_content)
		--print("-----")
		
		local first_id = find_id_within_component(first_line_content)
		local second_id = find_id_within_component(second_line_content)
		
		if tonumber(first_id) > tonumber(second_id) then
			--print("comparing" .. first_id .. " to " .. second_id)
			xmlContent = swap_lines_in_string(xmlContent, first_line_number, second_line_number)
			something_in_xml_changed = true
		end
	end
	
	if something_in_xml_changed then return put_components_in_order(xmlContent) end
	
	--print(xmlContent)
	
	return xmlContent

end






local function add_attribute_to_component_in_xml(xmlContent, targetId, attributeString)
	-- Function to add the attribute to the specific Component element
	local function modifyComponent(componentString)
		local id = componentString:match('id="(%d+)"')
		if id and tonumber(id) == targetId then
			local escapedAttributeString = attributeString:gsub('%%', '%%%%')
			return componentString:gsub('/>$', ' ' .. escapedAttributeString .. ' />')
		else
			return componentString
		end
	end

	-- Find the CircuitBox element
	local circuitBoxStart, circuitBoxEnd = xmlContent:find('<CircuitBox.->')
	local circuitBoxEndTag = xmlContent:find('</CircuitBox>', circuitBoxEnd)
	if not circuitBoxStart or not circuitBoxEndTag then
		print("CircuitBox element not found")
		return xmlContent
	end

	-- Extract the CircuitBox content
	local circuitBoxContent = xmlContent:sub(circuitBoxEnd + 1, circuitBoxEndTag - 1)

	-- Modify the specific Component element
	local modifiedCircuitBoxContent = circuitBoxContent:gsub('<Component.-/>', modifyComponent)

	-- Replace the original CircuitBox content with the modified content
	return xmlContent:sub(1, circuitBoxEnd) .. modifiedCircuitBoxContent .. xmlContent:sub(circuitBoxEndTag)
end


function blue_prints.save_blueprint(provided_path)
	if Character.Controlled == nil then print("you dont have a character") return end
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
	
    -- Check if the filename already ends with .txt
    if not string.match(provided_path, "%.txt$") then
        -- Add .txt if it's not already present
        provided_path = provided_path .. ".txt"
    end

	local file_path = (blue_prints.save_path .. "/" .. provided_path)
	
	local character = Character.Controlled

    
	local sacrificial_xml = XElement("Root")
	blue_prints.most_recent_circuitbox.Save(sacrificial_xml)
	local circuitbox_xml = tostring(sacrificial_xml)

	--the xml does not contain the components, so we need to add them
	local components = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Components
	
	for i, component in ipairs(components) do
		
		
		
		
		
		
		local memoryComponent = component.Item.GetComponentString("MemoryComponent")
		if memoryComponent then
			local element_to_add = 'Class="MemoryComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(memoryComponent.Value)
			element_to_add = 'Value="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local arithmeticComponent = component.Item.GetComponentString("ArithmeticComponent")
		if arithmeticComponent then
			local element_to_add = 'Class="ArithmeticComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(arithmeticComponent.ClampMax)
			element_to_add = 'ClampMax="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(arithmeticComponent.ClampMin)
			element_to_add = 'ClampMin="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(arithmeticComponent.TimeFrame)
			element_to_add = 'TimeFrame="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local trigonometricFunctionComponent = component.Item.GetComponentString("TrigonometricFunctionComponent")
		if trigonometricFunctionComponent then
			local element_to_add = 'Class="TrigonometricFunctionComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(trigonometricFunctionComponent.UseRadians)
			element_to_add = 'UseRadians="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local colorComponent = component.Item.GetComponentString("ColorComponent")
		if colorComponent then
			local element_to_add = 'Class="ColorComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(colorComponent.UseHSV)
			element_to_add = 'UseHSV="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local concatComponent = component.Item.GetComponentString("ConcatComponent")
		if concatComponent then
			local element_to_add = 'Class="ConcatComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(concatComponent.Separator)
			element_to_add = 'Separator="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local stringComponent = component.Item.GetComponentString("StringComponent")
		if stringComponent then
			local element_to_add = 'Class="StringComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(stringComponent.TimeFrame)
			element_to_add = 'TimeFrame="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local delayComponent = component.Item.GetComponentString("DelayComponent")
		if delayComponent then
			local element_to_add = 'Class="DelayComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(delayComponent.Delay)
			element_to_add = 'Delay="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(delayComponent.ResetWhenSignalReceived)
			element_to_add = 'ResetWhenSignalReceived="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(delayComponent.ResetWhenDifferentSignalReceived)
			element_to_add = 'ResetWhenDifferentSignalReceived="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local equalsComponent = component.Item.GetComponentString("EqualsComponent")
		if equalsComponent then
			local element_to_add = 'Class="EqualsComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(equalsComponent.Output)
			element_to_add = 'Output="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(equalsComponent.FalseOutput)
			element_to_add = 'FalseOutput="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(equalsComponent.TimeFrame)
			element_to_add = 'TimeFrame="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local exponentiationComponent = component.Item.GetComponentString("ExponentiationComponent")
		if exponentiationComponent then
			local element_to_add = 'Class="ExponentiationComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(exponentiationComponent.Exponent)
			element_to_add = 'Exponent="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local moduloComponent = component.Item.GetComponentString("ModuloComponent")
		if moduloComponent then
			local element_to_add = 'Class="ModuloComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(moduloComponent.Modulus)
			element_to_add = 'Modulus="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local notComponent = component.Item.GetComponentString("NotComponent")
		if notComponent then
			local element_to_add = 'Class="NotComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(notComponent.ContinuousOutput)
			element_to_add = 'ContinuousOutput="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local booleanOperatorComponent = component.Item.GetComponentString("BooleanOperatorComponent")
		if booleanOperatorComponent then
			local element_to_add = 'Class="BooleanOperatorComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(booleanOperatorComponent.Output)
			element_to_add = 'Output="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(booleanOperatorComponent.FalseOutput)
			element_to_add = 'FalseOutput="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(booleanOperatorComponent.TimeFrame)
			element_to_add = 'TimeFrame="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local oscillatorComponent = component.Item.GetComponentString("OscillatorComponent")
		if oscillatorComponent then
			local element_to_add = 'Class="OscillatorComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(oscillatorComponent.OutputType)
			element_to_add = 'OutputType="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(oscillatorComponent.Frequency)
			element_to_add = 'Frequency="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local regExFindComponent = component.Item.GetComponentString("RegExFindComponent")
		if regExFindComponent then
			local element_to_add = 'Class="RegExFindComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(regExFindComponent.Output)
			element_to_add = 'Output="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(regExFindComponent.UseCaptureGroup)
			element_to_add = 'UseCaptureGroup="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(regExFindComponent.OutputEmptyCaptureGroup)
			element_to_add = 'OutputEmptyCaptureGroup="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(regExFindComponent.FalseOutput)
			element_to_add = 'FalseOutput="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(regExFindComponent.ContinuousOutput)
			element_to_add = 'ContinuousOutput="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(regExFindComponent.Expression)
			element_to_add = 'Expression="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local relayComponent = component.Item.GetComponentString("RelayComponent")
		if relayComponent then
			local element_to_add = 'Class="RelayComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(relayComponent.IsOn)
			element_to_add = 'IsOn="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local signalCheckComponent = component.Item.GetComponentString("SignalCheckComponent")
		if signalCheckComponent then
			local element_to_add = 'Class="SignalCheckComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(signalCheckComponent.Output)
			element_to_add = 'Output="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(signalCheckComponent.FalseOutput)
			element_to_add = 'FalseOutput="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			element_to_add = tostring(signalCheckComponent.TargetSignal)
			element_to_add = 'TargetSignal="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end

		local wifiComponent = component.Item.GetComponentString("WifiComponent")
		if wifiComponent then
			local element_to_add = 'Class="WifiComponent"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
			
			local element_to_add = tostring(wifiComponent.Channel)
			element_to_add = 'Channel="' .. element_to_add .. '"'
			circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, element_to_add)
		end
		
		
		
		
		local parsed_item_string = tostring(component.Item):match("^(%S+%s+%S+)")
		parsed_item_string = parsed_item_string:gsub("%s+", "")
		parsed_item_string = parsed_item_string:lower()
		parsed_item_string = 'item="' .. parsed_item_string .. '"'
		

		circuitbox_xml = add_attribute_to_component_in_xml(circuitbox_xml, component.ID, parsed_item_string)
    end
	
	--now some cleanup to deal with deleted components
	circuitbox_xml = put_components_in_order(circuitbox_xml)
	circuitbox_xml = renumberComponents(circuitbox_xml)
	
	
	

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

