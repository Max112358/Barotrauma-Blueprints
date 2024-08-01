if SERVER then return end --prevents it from running on the server

-- Function to write text to a file
local function writeFile(path, text)
    local file = io.open(path, "w")
    if file then
        file:write(text)
        file:close()
    else
        print("Error: Could not open file for writing")
    end
end



local function copy_all_txt_files(source, destination)

    local saved_files = File.GetFiles(source)
    
    for name, value in pairs(saved_files) do
        if string.match(value, "%.txt$") then
            --print(string.format("  %s: %s", name, value))
			local filename = value:match("([^\\]+)$")
			local file_to_copy = File.Read(value)
			local save_path = destination .. "/" .. filename
			if not File.Exists(save_path) then
				writeFile(save_path , file_to_copy)
			end
        end
    end
end


--on first run, create the directory
if not File.DirectoryExists(blue_prints.save_path) then
	local createDir = File.CreateDirectory(blue_prints.save_path)
	copy_all_txt_files(blue_prints.path, blue_prints.save_path)
	if not createDir then
		print("Failed to create directory")
		return nil
	end
end
