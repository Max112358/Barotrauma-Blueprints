if SERVER then return end --prevents it from running on the server

-- Platform-agnostic file path handling
function blue_prints.normalizePath(path)
    -- Replace Windows backslashes with forward slashes
    path = path:gsub("\\", "/")

    -- Remove any double slashes
    path = path:gsub("//+", "/")

    -- Remove trailing slash if present
    path = path:gsub("/$", "")

    return path
end

-- Safe file operations with error handling
function blue_prints.safeFileOperation(operation, ...)
    local success, result = pcall(operation, ...)
    if not success then
        print("File operation failed: " .. tostring(result))
        return nil
    end
    return result
end

-- Enhanced file reading with platform checks
function blue_prints.readFileContents(path)
    path = blue_prints.normalizePath(path)

    -- Try direct read first
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content
    end

    -- If direct read fails, try alternate path format
    local alt_path = path:gsub("LocalMods/", "local_mods/")
    file = io.open(alt_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content
    end

    return nil
end

-- Enhanced directory checking
function blue_prints.checkDirectory(path)
    path = blue_prints.normalizePath(path)

    if not File.DirectoryExists(path) then
        -- Try creating with normalized path
        local success = blue_prints.safeFileOperation(File.CreateDirectory, path)
        if not success then
            -- Try alternate path format
            local alt_path = path:gsub("LocalMods/", "local_mods/")
            success = blue_prints.safeFileOperation(File.CreateDirectory, alt_path)
            if not success then
                print("Failed to create directory: " .. path)
                return false
            end
        end
    end
    return true
end

-- Enhanced file listing that handles both Windows and Linux paths
function blue_prints.getFiles(path)
    path = blue_prints.normalizePath(path)
    
    -- Try to get files with current path format
    local success, files = pcall(function() return File.GetFiles(path) end)
    if success and files and #files > 0 then
        return files
    end
    
    -- If that fails, try with alternate path format
    success, files = pcall(function() 
        return File.GetFiles(path:gsub("LocalMods/", "local_mods/")) 
    end)
    if success and files and #files > 0 then
        return files
    end
    
    -- If no files found, return empty table instead of nil
    return {}
end

-- Write file with platform compatibility
function blue_prints.writeFile(path, content)
    path = blue_prints.normalizePath(path)
    path = path:gsub("%s", "_") -- Replace spaces with underscores

    local file, err = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
        return true
    end

    -- Log the error
    print("Failed to write file: " .. path .. " with error: " .. tostring(err))

    -- Try alternate path if direct write fails
    local alt_path = path:gsub("LocalMods/", "local_mods/")
    file, err = io.open(alt_path, "w")
    if file then
        file:write(content)
        file:close()
        return true
    end

    -- Log the error
    print("Failed to write file: " .. alt_path .. " with error: " .. tostring(err))
    return false
end

-- Debug helper function
function blue_prints.printSystemInfo()
    print("Operating system: " .. (package.config:sub(1, 1) == '\\' and "Windows" or "Unix-like"))
    print("Save path: " .. blue_prints.save_path)
    print("Normalized save path: " .. blue_prints.normalizePath(blue_prints.save_path))
end

-- Creates a folder if it doesn't exist, handling platform-specific path issues
function blue_prints.createFolder(folderPath)
    folderPath = blue_prints.normalizePath(folderPath)

    if not File.DirectoryExists(folderPath) then
        -- Try creating with normalized path
        local success = blue_prints.safeFileOperation(File.CreateDirectory, folderPath)
        if not success then
            -- Try alternate path format for different platforms
            local alt_path = folderPath:gsub("LocalMods/", "local_mods/")
            success = blue_prints.safeFileOperation(File.CreateDirectory, alt_path)
            if not success then
                print("Failed to create folder: " .. folderPath)
                return false
            end
        end
    end
    return true
end

-- Modified save function that handles folder paths
function blue_prints.saveWithFolder(provided_path, folder, content)
    if not provided_path or not folder or not content then
        print("Error: Missing required parameters for save")
        return false
    end

    -- Create a complete path including the folder
    local fullPath

    -- If folder is [Root Directory], save directly in the base save path
    if folder == "[Root Directory]" then
        fullPath = blue_prints.save_path
    else
        -- Clean and normalize the folder name
        folder = folder:gsub("[^%w%s%-_]", "") -- Remove special characters
        folder = folder:gsub("%s+", "_")       -- Replace spaces with underscores
        fullPath = blue_prints.normalizePath(blue_prints.save_path .. "/" .. folder)
    end

    -- Ensure the folder exists
    if not blue_prints.createFolder(fullPath) then
        print("Error: Could not create or access folder: " .. folder)
        return false
    end

    -- Add .txt extension if not present
    if not string.match(provided_path, "%.txt$") then
        provided_path = provided_path .. ".txt"
    end

    -- Create the full file path
    local file_path = blue_prints.normalizePath(fullPath .. "/" .. provided_path)

    -- Write the file
    if blue_prints.writeFile(file_path, content) then
        print("Blueprint saved to " .. file_path)
        return true
    else
        print("Error: Could not save blueprint")
        return false
    end
end

-- Ensures the base blueprints directory exists
function blue_prints.ensureBaseDirectory()
    local basePath = blue_prints.normalizePath(blue_prints.save_path)
    if not File.DirectoryExists(basePath) then
        local success = blue_prints.safeFileOperation(File.CreateDirectory, basePath)
        if not success then
            -- Try alternate path format
            local alt_path = basePath:gsub("LocalMods/", "local_mods/")
            success = blue_prints.safeFileOperation(File.CreateDirectory, alt_path)
            if not success then
                print("Failed to create base directory: " .. basePath)
                return false
            end
        end
    end
    return true
end

-- Gets all folders in the blueprints directory
function blue_prints.getFolders(path)
    -- Ensure base directory exists first
    if not blue_prints.ensureBaseDirectory() then
        return {}
    end

    path = blue_prints.normalizePath(path)

    local folders = {}
    local success = pcall(function()
        folders = File.GetDirectories(path)
    end)

    if not success or not folders or #folders == 0 then
        -- Try alternate path format
        local alt_path = path:gsub("LocalMods/", "local_mods/")
        success = pcall(function()
            folders = File.GetDirectories(alt_path)
        end)
    end

    return folders or {}
end

-- Gets list of folder names in a user-friendly format
function blue_prints.getFolderList()
    local folders = blue_prints.getFolders(blue_prints.save_path)
    local folderNames = { "[Root Directory]" } -- Allow saving in root directory

    for _, fullPath in pairs(folders) do
        -- Extract just the folder name from the full path
        local folderName = fullPath:match("([^/\\]+)$")
        if folderName then
            table.insert(folderNames, folderName)
        end
    end

    return folderNames
end

-- Creates a new folder in the blueprints directory
function blue_prints.createNewFolder(folderName)
    if not blue_prints.ensureBaseDirectory() then
        return false, "Cannot create base directory"
    end

    if not folderName or folderName == "" then
        return false, "Invalid folder name"
    end

    -- Clean the folder name
    folderName = folderName:gsub("[^%w%s%-_]", ""):gsub("%s+", "_")
    local folderPath = blue_prints.normalizePath(blue_prints.save_path .. "/" .. folderName)

    -- Check if folder already exists
    if File.DirectoryExists(folderPath) then
        return false, "Folder already exists"
    end

    -- Create the folder
    if blue_prints.createFolder(folderPath) then
        return true, folderName
    else
        return false, "Failed to create folder"
    end
end


-- Modified Directory Functions
function blue_prints.getDirectories(path)
    path = blue_prints.normalizePath(path)
    
    -- Try to get directories with current path format
    local success, dirs = pcall(function() return File.GetDirectories(path) end)
    if success and dirs and #dirs > 0 then
        return dirs
    end
    
    -- If that fails, try with alternate path format
    success, dirs = pcall(function() 
        return File.GetDirectories(path:gsub("LocalMods/", "local_mods/")) 
    end)
    if success and dirs and #dirs > 0 then
        return dirs
    end
    
    -- If no directories found, return empty table instead of nil
    return {}
end