if SERVER then return end --prevents it from running on the server

-- Function to write text to a file
local function writeFile(path, text)
    return blue_prints.writeFile(path, text)
end

-- Recursively copy a directory structure
local function copy_directory_structure(source, destination)
    -- Normalize paths
    source = blue_prints.normalizePath(source)
    destination = blue_prints.normalizePath(destination)
    
    -- Ensure destination exists
    if not blue_prints.createFolder(destination) then
        print("Failed to create destination directory: " .. destination)
        return false
    end
    
    -- Get all files and directories using our safe functions
    local files = blue_prints.getFiles(source)
    local directories = blue_prints.getDirectories(source)
    
    -- Copy files
    for _, filepath in pairs(files) do
        if string.match(filepath, "%.txt$") then
            local filename = filepath:match("([^/\\]+)$")
            local file_content = blue_prints.readFileContents(filepath)
            if file_content then
                local dest_path = blue_prints.normalizePath(destination .. "/" .. filename)
                if not File.Exists(dest_path) then
                    writeFile(dest_path, file_content)
                end
            end
        end
    end
    
    -- Recursively copy subdirectories
    for _, dir in pairs(directories) do
        local dir_name = dir:match("([^/\\]+)$")
        if dir_name then
            local source_subdir = blue_prints.normalizePath(source .. "/" .. dir_name)
            local dest_subdir = blue_prints.normalizePath(destination .. "/" .. dir_name)
            copy_directory_structure(source_subdir, dest_subdir)
        end
    end
    
    return true
end

-- Create base directory first
if not blue_prints.ensureBaseDirectory() then
    print("Failed to create blueprint directory")
    return nil
end

-- Check if this is first run by looking for existing content
local existing_files = blue_prints.getFiles(blue_prints.save_path)
local existing_dirs = blue_prints.getDirectories(blue_prints.save_path)
local is_first_run = #existing_files == 0 and #existing_dirs == 0

if is_first_run then
    -- Look for starter_blueprints directory
    local starter_blueprints_path = blue_prints.normalizePath(blue_prints.path .. "/starter_blueprints")
    if File.DirectoryExists(starter_blueprints_path) then
        -- Copy the entire directory structure
        if copy_directory_structure(starter_blueprints_path, blue_prints.save_path) then
            print("Successfully copied starter blueprints")
        else
            print("Failed to copy starter blueprints")
        end
    else
        print("No starter_blueprints directory found at: " .. starter_blueprints_path)
        -- Create default folders if no starter blueprints exist
        local defaultFolders = {"General", "Reactor", "Navigation", "Weapons", "Medical"}
        for _, folder in ipairs(defaultFolders) do
            local folderPath = blue_prints.normalizePath(blue_prints.save_path .. "/" .. folder)
            blue_prints.createFolder(folderPath)
        end
    end
end