if SERVER then return end --prevents it from running on the server



local function sanity_check_blue_print(inputs, outputs, components, wires, labels, inputNodePos, outputNodePos)
    local function check_table_not_empty(t, name)
        if type(t) ~= "table" or next(t) == nil then
            return false, name .. " is empty or not a table"
        end
        return true
    end

    local function check_position(pos, name)
        if type(pos) ~= "table" or pos.x == nil or pos.y == nil then
            return false, name .. " is missing x or y coordinate"
        end
        return true
    end

	--[[ --its possible to have no input labels at all
    -- Check inputs and outputs
    local ok, msg = check_table_not_empty(inputs, "Inputs")
    if not ok then return false, msg end
    ok, msg = check_table_not_empty(outputs, "Outputs")
    if not ok then return false, msg end
	--]]
	

    -- Check components
    ok, msg = check_table_not_empty(components, "Components")
    if not ok then return false, msg end
    for i, component in ipairs(components) do
        if not component.id or not component.position or not component.usedResource or
           not component.item or not component.class or not component.class.name then
            return false, "Component " .. i .. " is missing required fields"
        end
        ok, msg = check_position(component.position, "Component " .. i .. " position")
        if not ok then return false, msg end
    end

    -- Check wires
    ok, msg = check_table_not_empty(wires, "Wires")
    if not ok then return false, msg end
    for i, wire in ipairs(wires) do
        if not wire.id or not wire.prefab or not wire.from or not wire.to or
           not wire.from.name or not wire.to.name then
            return false, "Wire " .. i .. " is missing required fields"
        end
    end

	--[[ --its possible to have no labels, and also possible to have blank labels
    -- Check labels
    ok, msg = check_table_not_empty(labels, "Labels")
    if not ok then return false, msg end
    for i, label in ipairs(labels) do
        if not label.id or not label.color or not label.position or not label.size or
           not label.header or not label.body then
            return false, "Label " .. i .. " is missing required fields"
        end
        ok, msg = check_position(label.position, "Label " .. i .. " position")
        if not ok then return false, msg end
        if not label.size.width or not label.size.height then
            return false, "Label " .. i .. " size is missing width or height"
        end
    end
	--]]

    -- Check input and output node positions
    ok, msg = check_position(inputNodePos, "Input node position")
    if not ok then return false, msg end
    ok, msg = check_position(outputNodePos, "Output node position")
    if not ok then return false, msg end

    -- If we've made it this far, all checks have passed
    return true, "All checks passed"
end



local function add_attribute_to_component_in_xml(xmlContent, targetId, attributeString)
	-- Function to add the attribute to the specific Component element
	local function modifyComponent(componentString)
		local id = componentString:match('id="(%d+)"')
		if id and tonumber(id) == targetId then
			return componentString:gsub('/>$', string.format(' %s />', attributeString))
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
	
	
	
	local inputs, outputs, components, wires, labels, inputNodePos, outputNodePos = blue_prints.parseXML(circuitbox_xml)
	local sanity_check_result, sanity_check_message = sanity_check_blue_print(inputs, outputs, components, wires, labels, inputNodePos, outputNodePos)
	
	
	
	if sanity_check_result == false then
		print("Sanity check failed: " .. sanity_check_message)
		print("Something is wrong with this save file! Please link a copy to this save file on the workshop page!")
		print("The file is in your barotrauma localmods folder. The mod maker needs this file to fix the problem!")
		print("This mod will only work with vanilla components.")
	end
	
	
	

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

