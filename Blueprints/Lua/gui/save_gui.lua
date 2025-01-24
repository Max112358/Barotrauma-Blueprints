if SERVER then return end -- we don't want server to run GUI code.

local resolution = blue_prints.getScreenResolution()
local run_once_at_start = false

-- Forward declarations
local check_and_rebuild_frame
local create_folder_modal
local generate_save_gui

create_folder_modal = function()
    -- Create a new modal frame that covers the entire screen
    local modalFrame = GUI.Frame(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.Center), nil)
    modalFrame.CanBeFocused = false

    -- Darkened background
    local backgroundButton = GUI.Button(GUI.RectTransform(Vector2(1, 1), modalFrame.RectTransform), "",
        GUI.Alignment.Center, nil)
    backgroundButton.Color = Color(0, 0, 0, 100)

    -- Modal content container - make it consistent with load_gui width (0.4)
    local modalContent = GUI.Frame(GUI.RectTransform(Vector2(0.4, 0.6), modalFrame.RectTransform, GUI.Anchor.Center))
    local menuList = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), modalContent.RectTransform, GUI.Anchor.BottomCenter))

    -- Title - matching load_gui style
    local titleText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform),
        "CREATE NEW FOLDER", nil, nil, GUI.Alignment.Center)
    titleText.TextScale = 2.0
    titleText.Wrap = false

    -- Spacer
    local spacer1 = GUI.Frame(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform))

    -- Folder name label
    local folderNameText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform),
        "Folder Name:", nil, nil, GUI.Alignment.CenterLeft)

    -- Text input - full width like in save_gui
    local textBox = GUI.TextBox(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "")

    -- Spacer
    local spacer2 = GUI.Frame(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform))

    -- Button container for proper centering
    local buttonContainer = GUI.Frame(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform))

    -- Create and Cancel buttons with proper spacing
    local cancelButton = GUI.Button(
        GUI.RectTransform(Vector2(0.45, 1), buttonContainer.RectTransform, GUI.Anchor.CenterLeft),
        "Cancel", GUI.Alignment.Center, "GUIButtonSmall")

    local createButton = GUI.Button(
        GUI.RectTransform(Vector2(0.45, 1), buttonContainer.RectTransform, GUI.Anchor.CenterRight),
        "Create", GUI.Alignment.Center, "GUIButtonSmall")

    -- Button handlers
    cancelButton.OnClicked = function()
        modalFrame.Visible = false
        modalFrame.RemoveFromGUIUpdateList()
        -- Ensure main save window is visible
        if blue_prints.current_gui_page then
            blue_prints.current_gui_page.Visible = true
        end
    end

    backgroundButton.OnClicked = cancelButton.OnClicked

    createButton.OnClicked = function()
        if textBox.Text and textBox.Text ~= "" then
            local success, result = blue_prints.createNewFolder(textBox.Text)
            if success then
                -- Close modal
                modalFrame.Visible = false
                modalFrame.RemoveFromGUIUpdateList()

                -- Refresh save window to show new folder
                if blue_prints.current_gui_page then
                    blue_prints.current_gui_page.Visible = false
                end
                blue_prints.current_gui_page = generate_save_gui()
                blue_prints.current_gui_page.Visible = true

                GUI.AddMessage("Folder created successfully", Color(0, 255, 0))
            else
                GUI.AddMessage("Failed to create folder: " .. result, Color(255, 0, 0))
            end
        else
            GUI.AddMessage("Please enter a folder name", Color(255, 0, 0))
        end
    end

    return modalFrame
end

generate_save_gui = function()
    blue_prints.current_gui_page = GUI.Frame(GUI.RectTransform(Vector2(1, 1), blue_prints.gui_button_frame.RectTransform, GUI.Anchor.Center),
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
    local menuList = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), menuContent.RectTransform, GUI.Anchor.BottomCenter))

    -- Title
    local title_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "SAVE BLUEPRINT",
        nil, nil, GUI.Alignment.Center)
    title_text.TextScale = 1.5
    title_text.TextColor = Color(200, 200, 200)
    title_text.Wrap = false

    -- Instructions
    local instruction_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.20), menuList.Content.RectTransform),
        'Enter a filename and select a folder. If using an existing filename, the old file will be overwritten.\n\n' ..
        'A label with the name "Description" will be used as the reminder text when loading.\n\n' ..
        'Click anywhere outside this box to cancel.',
        nil, nil, GUI.Alignment.TopLeft)
    instruction_text.Wrap = true
    instruction_text.TextColor = Color(200, 200, 200)
    instruction_text.Padding = Vector4(10, 5, 10, 5)

    -- Create New Folder Button
    local createFolderButton = GUI.Button(GUI.RectTransform(Vector2(1, 0.08), menuList.Content.RectTransform),
        "Create New Folder", GUI.Alignment.Center, "GUIButtonSmall")

    createFolderButton.OnClicked = function()
        -- Hide the save window temporarily
        blue_prints.current_gui_page.Visible = false
        -- Show the folder creation modal
        local modalFrame = create_folder_modal()
    end

    local spacer1 = GUI.Frame(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform))

    -- Folder Selection
    local folderText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform),
        "Select Folder:", nil, nil, GUI.Alignment.CenterLeft)

    local folderDropDown = GUI.DropDown(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform),
        "Select Folder", nil, nil, false)

    -- Add folders to dropdown with numeric indices
    local folders = blue_prints.getFolderList()
    for i, folder in ipairs(folders) do
        folderDropDown.AddItem(folder, i)
    end

    -- Select the most recently used folder if it exists
    local selectedIndex = 1 -- Default to first item
    for i, folder in ipairs(folders) do
        if folder == blue_prints.most_recent_folder then
            selectedIndex = i
            break
        end
    end
    folderDropDown.Select(selectedIndex - 1) -- -1 because dropdown uses 0-based indexing

    -- Store folder list for reference
    local folderLookup = folders

    local spacer2 = GUI.Frame(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform))

    -- Filename Section
    local filenameText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform),
        "Filename:", nil, nil, GUI.Alignment.CenterLeft)

    local filenameTextBox = GUI.TextBox(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform),
        "Your filename here")
    
    -- Set the text box to the most recently used name if available
    if blue_prints.most_recently_used_blueprint_name ~= nil then
        filenameTextBox.Text = blue_prints.most_recently_used_blueprint_name
    end

    local spacer3 = GUI.Frame(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform))

    -- Save Button
    local save_button = GUI.Button(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform),
        "Save", GUI.Alignment.Center, "GUIButtonSmall")

    save_button.OnClicked = function()
        if filenameTextBox.Text and filenameTextBox.Text ~= "" then
            -- Get the selected index and use it to look up the folder name
            local selectedIndex = (tonumber(folderDropDown.SelectedData) or 1) - 1
            local selectedFolder = folderLookup[selectedIndex + 1] -- +1 because Lua arrays start at 1

            --print("Selected index:", selectedIndex)  -- Debug print
            --print("Selected folder:", selectedFolder)  -- Debug print

            if selectedFolder == "[Root Directory]" then
                --print("Saving to root directory")
                blue_prints.save_blueprint(filenameTextBox.Text)
            else
                --print("Saving to folder:", selectedFolder)
                blue_prints.save_blueprint(filenameTextBox.Text, selectedFolder)
            end
            blue_prints.current_gui_page.Visible = false
            GUI.AddMessage('File Saved', Color.White)
        else
            GUI.AddMessage('Please enter a filename', Color(255, 0, 0))
        end
    end

    return blue_prints.current_gui_page
end

check_and_rebuild_frame = function()
    local new_resolution = blue_prints.getScreenResolution()
    if new_resolution ~= resolution or run_once_at_start == false then

        local spacer = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.04), blue_prints.gui_button_frame_list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)

        local button = GUI.Button(GUI.RectTransform(Vector2(1, 0.1), blue_prints.gui_button_frame_list.Content.RectTransform), "Save Blueprint", GUI.Alignment.Center, "GUIButtonSmall")

        button.OnClicked = function()
            if blue_prints.current_gui_page ~= nil then
                blue_prints.current_gui_page.Visible = false
            end
            blue_prints.current_gui_page = nil
            blue_prints.current_gui_page = generate_save_gui()
            blue_prints.current_gui_page.Visible = true
        end

        resolution = new_resolution
        run_once_at_start = true
    end
end

Hook.Patch("Barotrauma.Items.Components.CircuitBox", "AddToGUIUpdateList", function()
    check_and_rebuild_frame()
end, Hook.HookMethodType.After)
