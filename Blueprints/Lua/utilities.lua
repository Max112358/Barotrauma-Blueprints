if SERVER then return end --prevents it from running on the server


function print_all_saved_files()

    local saved_files = File.GetFiles(blue_prints.save_path)
    
    for name, value in pairs(saved_files) do
        if string.match(value, "%.txt$") then
			local filename = value:match("([^\\]+)$")
            print(filename)
        end
    end
end


function readFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil, "Failed to open file: " .. path
    end
    local content = file:read("*all")
    file:close()
    return content
end


function isInteger(str)
    return str and not (str == "" or str:find("%D"))
end

function isFloat(str)
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




function getNthValue(tbl, n)
    local count = 0
    for key, value in pairs(tbl) do
        count = count + 1
        if count == n then
            return value
        end
    end
    return nil  -- Return nil if there are fewer than n items
end



function clear_circuitbox() --this does not work. I cant figure out how to get a IReadOnlyCollection<CircuitBoxNode> type for the final call
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end
	local components = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").Components
	blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").RemoveComponents(components)
end



function move_input_output_nodes() --this does not work. I cant figure out how to get a IReadOnlyCollection<CircuitBoxNode> type for the final call
	if blue_prints.most_recent_circuitbox == nil then print("no circuitbox detected") return end

	local input_output_nodes = blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").InputOutputNodes 
	local input_connection_node = getNthValue(input_output_nodes, 1)
	local output_connection_node = getNthValue(input_output_nodes, 2)

	local nodes = {}

	table.insert(nodes, input_connection_node)

    local component_position = Vector2(800, 800)
		
	blue_prints.most_recent_circuitbox.GetComponentString("CircuitBox").MoveComponent(component_position, nodes) 
end



function string_to_bool(passed_string)
    -- Convert to lower case for case-insensitive comparison
    local lower_string = string.lower(passed_string)
    
    -- Check for common true values
    if lower_string == "true" or lower_string == "1" then
        return true
    elseif lower_string == "false" or lower_string == "0" then
        return false
    else
        -- Handle unexpected cases (could also return nil or error)
        error("Invalid string for boolean conversion: " .. passed_string)
    end
end


--save a reference to the most recently interacted circuit box
Hook.Add("item.interact", "get_blue_prints.most_recent_circuitbox", function(potential_circuit_box, characterPicker, ignoreRequiredItemsBool, forceSelectKeyBool, forceActionKeyBool)
	if Character.Controlled == nil then return end
	if potential_circuit_box.Prefab.Identifier == "circuitbox" then
		blue_prints.most_recent_circuitbox = potential_circuit_box
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