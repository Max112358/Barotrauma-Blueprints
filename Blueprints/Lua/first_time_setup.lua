if SERVER then return end --prevents it from running on the server

-- Function to write text to a file
local function writeFile(path, text)
    return blue_prints.writeFile(path, text)
end

local function copy_all_txt_files(source, destination)
    local saved_files = blue_prints.getFiles(source)
    
    for name, value in pairs(saved_files) do
        if string.match(value, "%.txt$") then
            local filename = value:match("([^/\\]+)$") -- Match after last slash or backslash
            local file_to_copy = blue_prints.readFileContents(value)
            if file_to_copy then
                local save_path = blue_prints.normalizePath(destination .. "/" .. filename)
                if not File.Exists(save_path) then
                    writeFile(save_path, file_to_copy)
                end
            end
        end
    end
end

--on first run, create the directory with our new helper function
if not blue_prints.checkDirectory(blue_prints.save_path) then
    print("Failed to create blueprint directory")
    return nil
end

copy_all_txt_files(blue_prints.path, blue_prints.save_path)