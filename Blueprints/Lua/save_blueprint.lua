if SERVER then return end --prevents it from running on the server


-- Delimiter constants
local STRING_START = "<<<STRINGSTART>>>"
local STRING_END = "<<<STRINGEND>>>"

-- Encodes a string to be safely stored in XML attributes
local function encodeAttributeString(str)
    if str == nil then return "" end
    
    -- First, escape any existing delimiters in the content
    local escaped = str:gsub(STRING_START, "\\<<<STRINGSTART>>>")
                      :gsub(STRING_END, "\\<<<STRINGEND>>>")
    
    -- Clean the string of control characters
    escaped = blue_prints.clean_string(escaped)
    
    -- Wrap the escaped content with delimiters
    return STRING_START .. escaped .. STRING_END
end

-- Decodes a string that was stored in XML attributes
local function decodeAttributeString(str)
    if str == nil then return "" end
    
    -- Check if the string has our delimiters
    local content = str:match(STRING_START .. "(.-)" .. STRING_END)
    if not content then
        -- If no delimiters found, return original string (for backward compatibility)
        return str
    end
    
    -- Unescape any escaped delimiters
    return content:gsub("\\<<<STRINGSTART>>>", STRING_START)
                 :gsub("\\<<<STRINGEND>>>", STRING_END)
end

local function processLabelStrings(xmlString)
    -- Process header and body attributes in Label tags
    return xmlString:gsub('(<Label[^>]-)(header="([^"]*)")', function(prefix, full, content)
        return prefix .. 'header="' .. encodeAttributeString(content) .. '"'
    end):gsub('(<Label[^>]-)(body="([^"]*)")', function(prefix, full, content)
        return prefix .. 'body="' .. encodeAttributeString(content) .. '"'
    end)
end


-- Function to process input/output node labels
local function processNodeLabels(xmlString)
    -- Pattern to match InputNode or OutputNode sections
    local function processNodeSection(nodeSection)
        -- Process ConnectionLabelOverride tags within the node section
        return nodeSection:gsub('(<ConnectionLabelOverride[^>]-value=)"([^"]*)"', function(prefix, content)
            -- Don't re-encode if already encoded
            if content:match("^" .. STRING_START .. ".*" .. STRING_END .. "$") then
                return prefix .. '"' .. content .. '"'
            end
            return prefix .. '"' .. encodeAttributeString(content) .. '"'
        end)
    end

    -- Process InputNode sections
    xmlString = xmlString:gsub("(<InputNode.-</InputNode>)", processNodeSection)
    
    -- Process OutputNode sections
    xmlString = xmlString:gsub("(<OutputNode.-</OutputNode>)", processNodeSection)
    
    return xmlString
end


-- Modified function to add encoded attributes to components
local function add_encoded_attribute_to_component(xmlContent, targetId, attributeName, attributeValue)
    -- First encode the attribute value
    local encodedValue = encodeAttributeString(attributeValue)
    
    -- Function to add the attribute to the specific Component element
    local function modifyComponent(componentString)
        local id = componentString:match('id="(%d+)"')
        if id and tonumber(id) == targetId then
            -- Create the full attribute string with the encoded value
            local attributeStr = string.format('%s=%s', attributeName, encodedValue)
            return componentString:gsub('/>$', ' ' .. blue_prints.escapePercent(attributeStr) .. ' />')
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
local function renumber_components(xmlString)
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


local function remove_attribute_from_components(xmlContent, attributeName)
    -- Function to remove the specified attribute from a component
    local function removeAttribute(componentString)
        -- Pattern to match traditional XML attributes
        local pattern1 = '%s*' .. attributeName .. '="[^"]+"'
        
        -- Pattern to match encoded strings with delimiters
        local pattern2 = '%s*' .. attributeName .. '=<<<STRINGSTART>>>[^<]*<<<STRINGEND>>>'
        
        -- Remove both types of attributes
        local result = componentString:gsub(pattern1, '')
        result = result:gsub(pattern2, '')
        
        return result
    end

    -- Find all Component elements and process them
    local function processComponents(content)
        return content:gsub('<Component.-/>', removeAttribute)
    end

    -- Find the CircuitBox element
    local circuitBoxStart, circuitBoxEnd = xmlContent:find('<CircuitBox.->')
    local circuitBoxEndTag = xmlContent:find('</CircuitBox>', circuitBoxEnd)
    if not circuitBoxStart or not circuitBoxEndTag then
        print("CircuitBox element not found")
        return xmlContent
    end

    -- Extract and process the CircuitBox content
    local circuitBoxContent = xmlContent:sub(circuitBoxEnd + 1, circuitBoxEndTag - 1)
    local modifiedCircuitBoxContent = processComponents(circuitBoxContent)

    -- Replace the original CircuitBox content with the modified content
    return xmlContent:sub(1, circuitBoxEnd) .. modifiedCircuitBoxContent .. xmlContent:sub(circuitBoxEndTag)
end




local function clean_component_whitespace(xmlContent)
    local function cleanComponent(componentString)
        -- Don't touch anything between STRINGSTART and STRINGEND
        local parts = {}
        local lastPos = 1
        
        -- Find start and end positions of all encoded strings
        local startPos = componentString:find('<<<STRINGSTART>>>', lastPos, true)
        while startPos do
            local endPos = componentString:find('<<<STRINGEND>>>', startPos, true)
            if not endPos then break end
            
            -- Add the part before the encoded string
            local beforePart = componentString:sub(lastPos, startPos - 1)
            beforePart = beforePart:gsub('%s+', ' ') -- collapse multiple spaces to single space
            table.insert(parts, beforePart)
            
            -- Add the encoded string unchanged
            table.insert(parts, componentString:sub(startPos, endPos + 13))
            
            lastPos = endPos + 14
            startPos = componentString:find('<<<STRINGSTART>>>', lastPos, true)
        end
        
        -- Add any remaining part after the last encoded string
        if lastPos <= #componentString then
            local remaining = componentString:sub(lastPos)
            remaining = remaining:gsub('%s+', ' ')
            table.insert(parts, remaining)
        end
        
        return table.concat(parts)
    end

    -- Find all Component tags and process them
    local circuitBoxStart, circuitBoxEnd = xmlContent:find('<CircuitBox.->')
    local circuitBoxEndTag = xmlContent:find('</CircuitBox>', circuitBoxEnd)
    if not circuitBoxStart or not circuitBoxEndTag then
        return xmlContent
    end

    local circuitBoxContent = xmlContent:sub(circuitBoxEnd + 1, circuitBoxEndTag - 1)
    local modifiedContent = circuitBoxContent:gsub('<Component.-/>', cleanComponent)

    return xmlContent:sub(1, circuitBoxEnd) .. modifiedContent .. xmlContent:sub(circuitBoxEndTag)
end



-- Function to round a number to the nearest integer
local function round(num)
    return math.floor(num + 0.5)
end

-- Function to round the position and size attributes in a Label element
local function round_attributes(label)
    -- Round the position attribute
    if label:find('position="') then
        local pos_x, pos_y = label:match('position="([^,]+),([^"]+)"')
        local rounded_position = string.format('position="%d,%d"', round(tonumber(pos_x)), round(tonumber(pos_y)))
        label = label:gsub('position="[^"]+"', rounded_position)
    end

    -- Round the size attribute
    if label:find('size="') then
        local size_x, size_y = label:match('size="([^,]+),([^"]+)"')
        local rounded_size = string.format('size="%d,%d"', round(tonumber(size_x)), round(tonumber(size_y)))
        label = label:gsub('size="[^"]+"', rounded_size)
    end
	
	if label:find('pos="') then
        local pos_x, pos_y = label:match('pos="([^,]+),([^"]+)"')
        local rounded_position = string.format('pos="%d,%d"', round(tonumber(pos_x)), round(tonumber(pos_y)))
        label = label:gsub('pos="[^"]+"', rounded_position)
    end

    return label
end

-- Function to process the entire XML string
local function round_position_values(xml_string)
    local processed_string = ""

    -- Process each line of the XML string
    for line in xml_string:gmatch("[^\r\n]+") do
        -- Find and process Label elements
        if line:find("<Label") or line:find("<Component") or line:find("<InputNode") or line:find("<OutputNode") then
            line = round_attributes(line)
        end
        processed_string = processed_string .. line .. "\n"
    end

    return processed_string
end











function blue_prints.prepare_circuitbox_xml_for_saving()
    if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end

    local sacrificial_xml = XElement("Root")
    blue_prints.most_recent_circuitbox.Save(sacrificial_xml)
    local circuitbox_xml = tostring(sacrificial_xml)



    local components = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Components
    
    for i, component in ipairs(components) do
        -- Add the class name to component
        local class_name = nil
        for value in component.Item.Components do
            local target_string = tostring(value)
            local target_string = target_string:match("([^%.]+)$")
            if string.find(target_string, "Component") then
                class_name = target_string
                break
            end
        end
        if class_name ~= nil then 
            circuitbox_xml = add_encoded_attribute_to_component(circuitbox_xml, component.ID, 'Class', class_name)
        else
            print("Error: couldn't find class name! Report this bug on the workshop page please! Component causing the problem: " .. tostring(component.Item.Prefab.Identifier))
        end
        
        -- Add any values stored inside the component
        local my_editables = component.Item.GetInGameEditableProperties(false)
        for tuple in my_editables do 
            local field_name = tostring(tuple.Item2.name)
            local field_value = tostring(tuple.Item2.GetValue(tuple.Item1))
            
            field_name = blue_prints.clean_string(field_name)
            field_value = blue_prints.clean_string(field_value)
            
            circuitbox_xml = add_encoded_attribute_to_component(
                circuitbox_xml, 
                component.ID, 
                field_name,
                field_value
            )
        end
        
        -- Add the item prefab itself
        circuitbox_xml = add_encoded_attribute_to_component(
            circuitbox_xml, 
            component.ID, 
            'item',
            tostring(component.Item.Prefab.Identifier)
        )
    end
    
    --remove stuff that shouldnt be there that gets added inside sub editor only
    circuitbox_xml = remove_attribute_from_components(circuitbox_xml, "InventoryIconColor")
    circuitbox_xml = remove_attribute_from_components(circuitbox_xml, "ContainerColor")
    circuitbox_xml = remove_attribute_from_components(circuitbox_xml, "SpriteDepthWhenDropped")

    -- Process Label strings
    circuitbox_xml = processLabelStrings(circuitbox_xml)
    
    -- Process Input/Output node labels
    circuitbox_xml = processNodeLabels(circuitbox_xml)
    
    -- Cleanup and formatting
    circuitbox_xml = put_components_in_order(circuitbox_xml)
    circuitbox_xml = renumber_components(circuitbox_xml)
    circuitbox_xml = round_position_values(circuitbox_xml)
    circuitbox_xml = clean_component_whitespace(circuitbox_xml)
    
    return circuitbox_xml
end






function blue_prints.save_blueprint(provided_path, folder)
    if Character.Controlled == nil then print("you dont have a character") return end
    if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
    
    -- Default to "General" folder if none specified
    folder = folder or "General"
    
    -- Store the folder and filename for future use
    blue_prints.most_recent_folder = folder
    blue_prints.most_recently_used_blueprint_name = provided_path:gsub("%.txt$", "") -- Remove .txt if present
    
    -- Prepare the circuit box XML
    local circuitbox_xml = blue_prints.prepare_circuitbox_xml_for_saving()
    
    -- Save using the folder-aware function
    return blue_prints.saveWithFolder(provided_path, folder, circuitbox_xml)
end
