if SERVER then return end

local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
local resolution = blue_prints.getScreenResolution()
local run_once_at_start = false
local folder_states = {} -- Track collapsed state of folders
local button_height = 45

-- Function to move blueprints from a folder to root
local function moveFilesToRoot(folderPath)
    if folderPath == "[Root Directory]" then return true end

    local fullFolderPath = blue_prints.normalizePath(blue_prints.save_path .. "/" .. folderPath)
    local rootPath = blue_prints.normalizePath(blue_prints.save_path)
    local files = File.GetFiles(fullFolderPath)
    local success = true

    if files then
        for _, filepath in ipairs(files) do
            if string.match(filepath, "%.txt$") then
                -- Read file content
                local content = blue_prints.readFileContents(filepath)
                if content then
                    -- Get just the filename
                    local filename = filepath:match("([^/\\]+)$")
                    -- Create new path in root
                    local newPath = blue_prints.normalizePath(rootPath .. "/" .. filename)
                    -- Write to new location
                    if not blue_prints.writeFile(newPath, content) then
                        success = false
                    end
                end
            end
        end
    end

    return success
end

-- Function to delete a folder and its contents
local function deleteFolder(folderPath)
    if folderPath == "[Root Directory]" then return false end

    local fullFolderPath = blue_prints.normalizePath(blue_prints.save_path .. "/" .. folderPath)

    -- Move all files to root first
    if not moveFilesToRoot(folderPath) then
        return false
    end

    -- Try to delete the folder
    local success = pcall(function()
        File.DeleteDirectory(fullFolderPath)
    end)

    -- If first attempt fails, try alternate path
    if not success then
        local altPath = fullFolderPath:gsub("LocalMods/", "local_mods/")
        success = pcall(function()
            File.DeleteDirectory(altPath)
        end)
    end

    return success
end

local function count_blueprints_in_folder(folderPath)
    local files = File.GetFiles(folderPath)
    local count = 0
    if files then
        for _, filepath in ipairs(files) do
            if string.match(filepath, "%.txt$") then
                count = count + 1
            end
        end
    end
    return count
end

local function formatFolderHeaderText(folderName, isExpanded, blueprintCount)
    return string.format("%s %s (%d blueprints)",
        isExpanded and "▼" or "▶",
        folderName,
        blueprintCount)
end

local function generate_load_gui()
    blue_prints.current_gui_page = GUI.Frame(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.Center),
        nil)
    blue_prints.current_gui_page.CanBeFocused = false
    blue_prints.current_gui_page.Visible = false

    -- Background close button
    local closeButton = GUI.Button(
    GUI.RectTransform(Vector2(1, 1), blue_prints.current_gui_page.RectTransform, GUI.Anchor.Center), "",
        GUI.Alignment.Center, nil)
    closeButton.OnClicked = function()
        blue_prints.current_gui_page.Visible = not blue_prints.current_gui_page.Visible
    end

    local menuContent = GUI.Frame(GUI.RectTransform(Vector2(0.4, 0.6), blue_prints.current_gui_page.RectTransform,
        GUI.Anchor.Center))
    local mainList = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), menuContent.RectTransform, GUI.Anchor.BottomCenter))

    -- Title
    local title_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.08), mainList.Content.RectTransform),
        "LOAD BLUEPRINT", nil, nil, GUI.Alignment.Center)
    title_text.TextScale = 1.5
    title_text.TextColor = Color(200, 200, 200)

    -- Instructions
    local instruction_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.25), mainList.Content.RectTransform),
        'Click a button to load. Hover over the button to see its description. Click folder headers to expand/collapse.\n\n' ..
        'If the base component is not available, FPGAs will be used instead. These components must be in your main inventory, not a toolbelt/backpack etc.\n\n' ..
        'Click anywhere outside this box to cancel.',
        nil, nil, GUI.Alignment.TopLeft)
    instruction_text.Wrap = true
    instruction_text.TextColor = Color(200, 200, 200)
    instruction_text.Padding = Vector4(10, 5, 10, 5)

    local function createBlueprintButton(filename, filepath, description, componentCount, contentList)
        local buttonContainer = GUI.Frame(GUI.RectTransform(Vector2(1, 0.10), contentList.Content.RectTransform,
            GUI.Anchor.TopCenter))
        buttonContainer.RectTransform.MinSize = Point(0, button_height)
        buttonContainer.RectTransform.MaxSize = Point(9999, button_height)

        local button_label = filename .. " - " .. tostring(componentCount) .. " FPGAs"
        local leftButton = GUI.Button(
            GUI.RectTransform(Vector2(0.90, 1), buttonContainer.RectTransform, GUI.Anchor.CenterLeft),
            button_label, GUI.Alignment.CenterLeft, "GUIButtonSmall")
        leftButton.TextBlock.Padding = Vector4(80, 0, 0, 0)

        if description then
            description = description:gsub("&#xA;", "\n"):gsub("&#xD;", "\n")
            leftButton.ToolTip = description
        else
            leftButton.ToolTip = "No description available"
        end

        leftButton.OnClicked = function()
            blue_prints.construct_blueprint(filepath)
            blue_prints.current_gui_page.Visible = false
        end

        local rightButton = GUI.Button(
            GUI.RectTransform(Vector2(0.10, 1), buttonContainer.RectTransform, GUI.Anchor.CenterRight),
            "Delete", GUI.Alignment.Center, "GUIButtonSmall")
        rightButton.ToolTip = "Delete " .. filename
        rightButton.Color = Color(255, 80, 80)
        rightButton.HoverColor = Color(255, 120, 120)

        rightButton.OnClicked = function()
            local message_box = GUI.MessageBox('Delete Blueprint?',
                'Are you sure you want to delete "' .. filename .. '"?',
                { 'Cancel', 'Delete' })

            local cancel_button = nil
            local delete_button = nil

            if message_box.Buttons[0] == nil then
                cancel_button = message_box.Buttons[1]
                delete_button = message_box.Buttons[2]
            else
                cancel_button = message_box.Buttons[0]
                delete_button = message_box.Buttons[1]
            end

            delete_button.Color = Color(255, 80, 80)
            delete_button.HoverColor = Color(255, 120, 120)

            cancel_button.OnClicked = function() message_box.Close() end
            delete_button.OnClicked = function()
                blue_prints.delete_blueprint(filepath)
                blue_prints.current_gui_page.Visible = false
                GUI.AddMessage('Blueprint Deleted', Color.White)
                message_box.Close()
            end
        end
    end

    -- Process folders
    local folders = blue_prints.getFolderList()
    for _, folderName in ipairs(folders) do
        local folderPath = folderName == "[Root Directory]" and "" or folderName
        local fullFolderPath = blue_prints.normalizePath(blue_prints.save_path .. "/" .. folderPath)
        local blueprintCount = count_blueprints_in_folder(fullFolderPath)

        folder_states[folderName] = folder_states[folderName] or false

        -- Create folder container
        local folderContainer = GUI.Frame(GUI.RectTransform(Vector2(1, 0.10), mainList.Content.RectTransform,
            GUI.Anchor.TopCenter))
        folderContainer.RectTransform.MinSize = Point(0, button_height)
        folderContainer.RectTransform.MaxSize = Point(9999, button_height)

        -- Create folder button with 90% width
        local headerButton = GUI.Button(
            GUI.RectTransform(Vector2(0.90, 1), folderContainer.RectTransform, GUI.Anchor.CenterLeft),
            formatFolderHeaderText(folderName, folder_states[folderName], blueprintCount),
            GUI.Alignment.CenterLeft, "GUIButtonSmall")
        headerButton.TextColor = Color(150, 150, 255)
        headerButton.HoverColor = Color(180, 180, 255, 0.5)
        headerButton.ForceUpperCase = 1
        headerButton.TextBlock.Padding = Vector4(0, 0, 0, 0)

        -- Add delete button for folder (except root)
        if folderName ~= "[Root Directory]" then
            local deleteButton = GUI.Button(
                GUI.RectTransform(Vector2(0.10, 1), folderContainer.RectTransform, GUI.Anchor.CenterRight),
                "Delete", GUI.Alignment.Center, "GUIButtonSmall")
            deleteButton.ToolTip = "Delete folder and move contents to root"
            deleteButton.Color = Color(255, 80, 80)
            deleteButton.HoverColor = Color(255, 120, 120)

            deleteButton.OnClicked = function()
                local message_box = GUI.MessageBox('Delete Folder?',
                    'Are you sure you want to delete "' ..
                    folderName .. '"?\nAll blueprints will be moved to the root folder.',
                    { 'Cancel', 'Delete' })

                local cancel_button = nil
                local delete_button = nil

                if message_box.Buttons[0] == nil then
                    cancel_button = message_box.Buttons[1]
                    delete_button = message_box.Buttons[2]
                else
                    cancel_button = message_box.Buttons[0]
                    delete_button = message_box.Buttons[1]
                end

                delete_button.Color = Color(255, 80, 80)
                delete_button.HoverColor = Color(255, 120, 120)

                cancel_button.OnClicked = function() message_box.Close() end
                delete_button.OnClicked = function()
                    if deleteFolder(folderName) then
                        blue_prints.current_gui_page.Visible = false
                        GUI.AddMessage('Folder Deleted', Color.White)
                        message_box.Close()
                        -- Regenerate GUI to show updated folder structure
                        Timer.Wait(function()
                            blue_prints.current_gui_page = generate_load_gui()
                            blue_prints.current_gui_page.Visible = true
                        end, 100)
                    else
                        GUI.AddMessage('Failed to delete folder', Color(255, 0, 0))
                        message_box.Close()
                    end
                end
            end
        end

        local files = File.GetFiles(fullFolderPath)
        local size_of_listbox = #files * button_height + 20

        local contentList = GUI.ListBox(GUI.RectTransform(Vector2(1, 0.1), mainList.Content.RectTransform))
        contentList.RectTransform.MinSize = Point(0, size_of_listbox)
        contentList.RectTransform.MaxSize = Point(999999, size_of_listbox)
        contentList.Visible = folder_states[folderName]

        -- Process files
        if files then
            for _, filepath in ipairs(files) do
                if string.match(filepath, "%.txt$") then
                    local filename = filepath:match("([^/\\]+)%.txt$")
                    local xmlContent = blue_prints.readFileContents(filepath)
                    local description = blue_prints.get_description_from_xml(xmlContent)
                    local componentCount = blue_prints.get_component_count_from_xml(xmlContent)

                    createBlueprintButton(filename, folderPath .. "/" .. filename, description, componentCount,
                        contentList)
                end
            end
        end

        headerButton.OnClicked = function()
            folder_states[folderName] = not folder_states[folderName]
            contentList.Visible = folder_states[folderName]
            headerButton.Text = formatFolderHeaderText(folderName, folder_states[folderName], blueprintCount)
        end
    end

    return blue_prints.current_gui_page
end

local function check_and_rebuild_frame()
    local new_resolution = blue_prints.getScreenResolution()
    if new_resolution ~= resolution or run_once_at_start == false then
        frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
        frame.CanBeFocused = false

        local button = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.2), frame.RectTransform, GUI.Anchor.CenterRight),
            "Load Blueprint", GUI.Alignment.Center, "GUIButtonSmall")
        button.RectTransform.AbsoluteOffset = Point(25, 0)
        button.OnClicked = function()
            if blue_prints.current_gui_page then
                blue_prints.current_gui_page.Visible = false
            end
            blue_prints.current_gui_page = generate_load_gui()
            blue_prints.current_gui_page.Visible = true
        end

        resolution = new_resolution
        run_once_at_start = true
    end
end

Hook.Patch("Barotrauma.Items.Components.CircuitBox", "AddToGUIUpdateList", function()
    check_and_rebuild_frame()
    frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)
