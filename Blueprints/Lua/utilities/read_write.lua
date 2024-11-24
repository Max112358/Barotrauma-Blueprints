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
    
    local files = File.GetFiles(path)
    if not files or #files == 0 then
        -- Try alternate path format
        local alt_path = path:gsub("LocalMods/", "local_mods/")
        files = File.GetFiles(alt_path)
    end
    
    return files or {}
end

-- Write file with platform compatibility
function blue_prints.writeFile(path, content)
    path = blue_prints.normalizePath(path)
    
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
        return true
    end
    
    -- Try alternate path if direct write fails
    local alt_path = path:gsub("LocalMods/", "local_mods/")
    file = io.open(alt_path, "w")
    if file then
        file:write(content)
        file:close()
        return true
    end
    
    print("Failed to write file: " .. path)
    return false
end

-- Debug helper function
function blue_prints.printSystemInfo()
    print("Operating system: " .. (package.config:sub(1,1) == '\\' and "Windows" or "Unix-like"))
    print("Save path: " .. blue_prints.save_path)
    print("Normalized save path: " .. blue_prints.normalizePath(blue_prints.save_path))
end