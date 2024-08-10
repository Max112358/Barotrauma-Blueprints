if SERVER then return end --prevents it from running on the server







function blue_prints.get_description_from_xml(xmlString)
    local function trim(s)
        return s:match("^%s*(.-)%s*$")
    end

    -- Find the Label tag with header="Description"
    --local labelTag = xmlString:match('<Label[^>]+header="Description".-/>') --case sensitive
	local labelTag = xmlString:match('<Label[^>]*header="[%s]*[dD][eE][sS][cC][rR][iI][pP][tT][iI][oO][nN][%s]*".-/>')
    if not labelTag then
        return nil
    end

    -- Extract the body attribute
    local body = labelTag:match('body="([^"]*)"')
    if not body then
        return nil
    end

    return trim(body)
end






function blue_prints.print_all_saved_files()

    local saved_files = File.GetFiles(blue_prints.save_path)
    
    for name, value in pairs(saved_files) do
        if string.match(value, "%.txt$") then
			local filename = value:match("([^\\]+)$") --capture after last backslash
			local filename = string.gsub(filename, "%.txt$", "") --cut out the .txt at the end
			
			local xml_of_file = blue_prints.readFile(value)
			local description_of_file = blue_prints.get_description_from_xml(xml_of_file)
			
			print("-------------")
			if description_of_file ~= nil then
				--print(filename .. " " .. description_of_file)
				print('‖color:white‖' .. filename .. '‖end‖  -  ‖color:yellow‖' .. description_of_file .. '‖end‖')
			else
				print('‖color:white‖' .. filename .. '‖end‖  -  ‖color:yellow‖' .. "No description label." .. '‖end‖')
			end
        end
    end
end


function blue_prints.readFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil, "Failed to open file: " .. path
    end
    local content = file:read("*all")
    file:close()
    return content
end


function blue_prints.isInteger(str)
    return str and not (str == "" or str:find("%D"))
end

function blue_prints.isFloat(str)
    local n = tonumber(str)
    return n ~= nil and math.floor(n) ~= n
end



function blue_prints.removeKeyFromTable(tbl, keyToRemove)
    local newTable = {}
    for k, v in pairs(tbl) do
        if k ~= keyToRemove then
            newTable[k] = v
        end
    end
    return newTable
end



function blue_prints.hexToRGBA(hex)
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




function blue_prints.getNthValue(tbl, n)
    local count = 0
    for key, value in pairs(tbl) do
        count = count + 1
        if count == n then
            return value
        end
    end
    return nil  -- Return nil if there are fewer than n items
end






function blue_prints.string_to_bool(passed_string)
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