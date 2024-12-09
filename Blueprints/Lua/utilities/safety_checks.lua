if SERVER then return end --prevents it from running on the server

function blue_prints.validate_blueprint_xml(xmlString)
    if not xmlString then
        return false, "No XML content provided"
    end

    -- Check for required main elements
    if not xmlString:match("<CircuitBox.-</CircuitBox>") then
        return false, "Missing CircuitBox element"
    end
    if not xmlString:match("<InputNode[^>]+>") then
        return false, "Missing InputNode"
    end
    if not xmlString:match("<OutputNode[^>]+>") then
        return false, "Missing OutputNode"
    end

    -- Validate input/output node positions
    local inputNode = xmlString:match("<InputNode[^>]+>")
    local outputNode = xmlString:match("<OutputNode[^>]+>")
    
    if inputNode then
        local posX, posY = inputNode:match('pos="([%d%.%-]+),([%d%.%-]+)"')
        if not (posX and posY and tonumber(posX) and tonumber(posY)) then
            return false, "Invalid InputNode position"
        end
    end
    
    if outputNode then
        local posX, posY = outputNode:match('pos="([%d%.%-]+),([%d%.%-]+)"')
        if not (posX and posY and tonumber(posX) and tonumber(posY)) then
            return false, "Invalid OutputNode position"
        end
    end

    -- Validate components
    for component in xmlString:gmatch('<Component.-/>') do
        -- Check required attributes
        local id = component:match('id="(%d+)"')
        local posX, posY = component:match('position="([%-%d%.]+),([%-%d%.]+)"')
        
        -- Check both old and new format for item and class
        local item = component:match('item="([^"]+)"') or 
                    component:match('item=<<<STRINGSTART>>>([^<]+)<<<STRINGEND>>>')
        local class = component:match('Class="([^"]+)"') or
                     component:match('Class=<<<STRINGSTART>>>([^<]+)<<<STRINGEND>>>')

        if not (id and posX and posY and item and class) then
            return false, "Invalid component definition - missing required attributes"
        end

        -- Validate position values are numbers
        if not (tonumber(posX) and tonumber(posY)) then
            return false, "Invalid component position values"
        end

        -- Validate ID is a number
        if not tonumber(id) then
            return false, "Invalid component ID"
        end

        -- Check if item prefab exists
        if item == "oscillatorcomponent" then item = "oscillator"
        elseif item == "concatenationcomponent" then item = "concatcomponent"
        elseif item == "exponentiationcomponent" then item = "powcomponent"
        elseif item == "regexfind" then item = "regexcomponent"
        elseif item == "signalcheck" then item = "signalcheckcomponent"
        elseif item == "squareroot" then item = "squarerootcomponent" end

        local itemPrefab = ItemPrefab.GetItemPrefab(item)
        if not itemPrefab then
            return false, "Invalid item prefab: " .. tostring(item)
        end
    end

    -- Validate wire connections
    for wire in xmlString:gmatch("<Wire.-</Wire>") do
        local id = wire:match('id="(%d+)"')
        if not id or not tonumber(id) then
            return false, "Invalid wire ID"
        end

        -- Check wire prefab
        local prefab = wire:match('prefab="([^"]+)"')
        if not prefab then
            return false, "Missing wire prefab"
        end
        
        local wirePrefab = ItemPrefab.GetItemPrefab(prefab)
        if not wirePrefab then
            return false, "Invalid wire prefab: " .. tostring(prefab)
        end

        -- Check connections
        local fromName, fromTarget = wire:match('<From name="([^"]+)" target="([^"]*)"')
        local toName, toTarget = wire:match('<To name="([^"]+)" target="([^"]*)"')
        
        if not (fromName and toName) then
            return false, "Invalid wire connections"
        end

        -- Validate signal names format
        if fromTarget == "" and not fromName:match("^signal_%w+%d+$") then
            return false, "Invalid input signal name format"
        end
        if toTarget == "" and not toName:match("^signal_%w+%d+$") then
            return false, "Invalid output signal name format"
        end
    end

    -- Validate labels
    for label in xmlString:gmatch('<Label.-/>') do
        local id = label:match('id="(%d+)"')
        local posX, posY = label:match('position="([%d%.%-]+),([%d%.%-]+)"')
        local sizeW, sizeH = label:match('size="([%d%.%-]+),([%d%.%-]+)"')
        local color = label:match('color="([^"]+)"')
        
        if not (id and posX and posY and sizeW and sizeH and color) then
            return false, "Invalid label definition - missing required attributes"
        end

        -- Validate numeric values
        if not (tonumber(posX) and tonumber(posY) and 
                tonumber(sizeW) and tonumber(sizeH)) then
            return false, "Invalid label position or size values"
        end

        -- Validate color format (basic check for hex color)
        if not color:match("^#[0-9A-Fa-f]+$") then
            return false, "Invalid label color format"
        end
    end

    -- If all checks pass
    return true, "Blueprint XML is valid"
end

function blue_prints.validate_blueprint_file(provided_path)
    -- Add .txt extension if not present
    if not string.match(provided_path, "%.txt$") then
        provided_path = provided_path .. ".txt"
    end

    -- Normalize the path
    local file_path = blue_prints.normalizePath(blue_prints.save_path .. "/" .. provided_path)

    -- Try to read the file content using our safe read function
    local xmlContent = blue_prints.readFileContents(file_path)
    if not xmlContent then
        return false, "Could not read file: " .. provided_path
    end

    -- Use the XML string validator to check the content
    return blue_prints.validate_blueprint_xml(xmlContent)
end