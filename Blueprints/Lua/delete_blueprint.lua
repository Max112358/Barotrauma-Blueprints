if SERVER then return end --prevents it from running on the server

function blue_prints.delete_blueprint(provided_path)
    -- Check if the filename already ends with .txt
    if not string.match(provided_path, "%.txt$") then
        -- Add .txt if it's not already present
        provided_path = provided_path .. ".txt"
    end

    local file_path = blue_prints.normalizePath(blue_prints.save_path .. "/" .. provided_path)

    if File.Exists(file_path) then
        local success = blue_prints.safeFileOperation(os.remove, file_path)
        if success then
            print("File deleted successfully.")
        else
            -- Try alternate path if first attempt fails
            local alt_path = file_path:gsub("LocalMods/", "local_mods/")
            success = blue_prints.safeFileOperation(os.remove, alt_path)
            if success then
                print("File deleted successfully.")
            else
                print("Error deleting file")
            end
        end
    else
        print("file not found")
        print("saved designs:")
        blue_prints.print_all_saved_files()
    end
end