



local function all_lines_the_same(filename, comparison_string)
    local file = io.open(filename, "r")
    if not file then
        print("Error: Unable to open file")
        return false
    end

    local file_lines = {}
    for line in file:lines() do
        table.insert(file_lines, line)
    end
    file:close()

    local string_lines = {}
    for line in comparison_string:gmatch("[^\r\n]+") do
        table.insert(string_lines, line)
    end

    local max_lines = math.max(#file_lines, #string_lines)
    local all_lines_same = true

    for i = 1, max_lines do
        local file_line = file_lines[i] or ""
        local string_line = string_lines[i] or ""

        if file_line ~= string_line then
            all_lines_same = false
            print(string.format("Mismatch at line %d:", i))
            print("File:   " .. file_line)
            print("String: " .. string_line)
            print()
        end
    end

    return all_lines_same
end



--[[
local function check_file_against_string(file_path, comparison_string)
  local ignore_prefixes = {'<link', '<Item name="" identifier="circuitbox"', '<input name="signal_', '<output name="signal_', '<ItemContainer QuickUseMovesItemsInside="False"', '<Holdable Attached="True"', '<requireditem items="wrench"', '<Wire id=', '</input', '</output'}
  local ignore_anywhere = {'header="Blueprints" body="Circuit made with Blueprints. &#xA; &#xA; Get it now on the steam workshop!"'}
  local file = io.open(file_path, "r")
  if not file then
    return false, "Unable to open file"
  end
  local file_lines = {}
  for line in file:lines() do
    table.insert(file_lines, line:match("^%s*(.+)"))
  end
  file:close()
  local comparison_lines = {}
  for line in comparison_string:gmatch("[^\r\n]+") do
    local should_ignore = false
    for _, prefix in ipairs(ignore_prefixes) do
      if line:match("^%s*" .. prefix) then
        should_ignore = true
        break
      end
    end
    if not should_ignore then
      for _, ignore_string in ipairs(ignore_anywhere) do
        if line:match(ignore_string) then
          should_ignore = true
          break
        end
      end
      if not should_ignore then
        table.insert(comparison_lines, line:match("^%s*(.+)"))
      end
    end
  end
  for _, comparison_line in ipairs(comparison_lines) do
    local found = false
    for _, file_line in ipairs(file_lines) do
      if file_line == comparison_line then
        found = true
        break
      end
    end
    if not found then
      print("Line not found in file: " .. comparison_line)
      return false, "Line not found in file: " .. comparison_line
    end
  end
  return true, "All lines found in file"
end
--]]


local function check_file_against_string(file_path, comparison_string)
  local include_prefixes = {'<InputNode' , '<OutputNode' , '<ConnectionLabelOverride', '<Component', '<From name=' , '<To name=', '<Label id='}
  local ignore_anywhere = {'header="Blueprints" body="Circuit made with Blueprints. &#xA; &#xA; Get it now on the steam workshop!"'}

  local file = io.open(file_path, "r")
  if not file then
    return false, "Unable to open file"
  end

  local file_lines = {}
  for line in file:lines() do
	local should_ignore = false
	for _, ignore_string in ipairs(ignore_anywhere) do
		if line:match(ignore_string) then
			should_ignore = true
			break
		end
	end
  
  
    for _, prefix in ipairs(include_prefixes) do
      if line:match("^%s*" .. prefix) and should_ignore == false then
        table.insert(file_lines, line:match("^%s*(.+)"))
        --print("including line from file: " .. line)
        break
      end
    end
  end
  file:close()

  local comparison_lines = {}
  for line in comparison_string:gmatch("[^\r\n]+") do
  
	local should_ignore = false
	for _, ignore_string in ipairs(ignore_anywhere) do
		if line:match(ignore_string) then
			should_ignore = true
			break
		end
	end
  
  
    for _, prefix in ipairs(include_prefixes) do
      if line:match("^%s*" .. prefix) and should_ignore == false then
        table.insert(comparison_lines, line:match("^%s*(.+)"))
        --print("including line from string: " .. line)
        break
      end
    end
  end

  for _, comparison_line in ipairs(comparison_lines) do
    local found = false
    for _, file_line in ipairs(file_lines) do
      if file_line == comparison_line then
        found = true
        break
      end
    end
    if not found then
      print("Line not found in file: " .. comparison_line)
      return false, "Line not found in file: " .. comparison_line
    end
  end
  
  for _, file_line in ipairs(file_lines) do
    local found = false
    for _, comparison_line in ipairs(comparison_lines) do
      if file_line == comparison_line then
        found = true
        break
      end
    end
    if not found then
      print("Line not found in string: " .. file_line)
      return false, "Line not found in string: " .. file_line
    end
  end

  return true, "All lines found in file"
end




function blue_prints.loading_complete_unit_test(path_to_loaded_file, loaded_circuit_xml)
	local result = check_file_against_string(path_to_loaded_file, loaded_circuit_xml)
	if result then
		--do nothing, this is normal
	else
		print('‖color:red‖"blueprint that failed its test: "' .. path_to_loaded_file .. '‖end‖')
		--print("blueprint that failed its test: " .. path_to_loaded_file)
	end
	return result
end



function blue_prints.unit_test_all_blueprint_files()

    local saved_files = File.GetFiles(blue_prints.save_path)
    current_delay = 0
	
    for name, value in pairs(saved_files) do
        if string.match(value, "%.txt$") then
			local filename = value:match("([^\\]+)$") --capture after last backslash
			local filename = string.gsub(filename, "%.txt$", "") --cut out the .txt at the end
			
			
			Timer.Wait(function() blue_prints.construct_blueprint(filename) end, current_delay)
			current_delay = current_delay + 12000
			
        end
    end
end