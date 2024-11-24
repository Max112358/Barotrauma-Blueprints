if SERVER then return end -- we don't want server to run GUI code.




-- our main frame where we will put our custom GUI
local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
local resolution = blue_prints.getScreenResolution()
local run_once_at_start = false

local function generate_load_gui()
    -- menu frame
    blue_prints.current_gui_page = GUI.Frame(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.Center), nil)
    blue_prints.current_gui_page.CanBeFocused = false
    blue_prints.current_gui_page.Visible = false

    -- put a button that goes behind the menu content, so we can close it when we click outside
    local closeButton = GUI.Button(GUI.RectTransform(Vector2(1, 1), blue_prints.current_gui_page.RectTransform, GUI.Anchor.Center), "", GUI.Alignment.Center, nil)
    closeButton.OnClicked = function ()
        blue_prints.current_gui_page.Visible = not blue_prints.current_gui_page.Visible
    end

    local menuContent = GUI.Frame(GUI.RectTransform(Vector2(0.4, 0.6), blue_prints.current_gui_page.RectTransform, GUI.Anchor.Center))
    local menuList = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), menuContent.RectTransform, GUI.Anchor.BottomCenter))

    local title_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "LOAD BLUEPRINT", nil, nil, GUI.Alignment.Center)
    title_text.TextScale = 2.0
    title_text.Wrap = false

    local instruction_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), 
        'Click a button to load. Hover over the button to see its description. \n\nIf the base component is not available, FPGAs will be used instead. These components must be in your main inventory, not a toolbelt/backpack etc. \n\nClick anywhere outside this box to cancel.', 
        nil, nil, GUI.Alignment.CenterLeft)
    instruction_text.Wrap = true
    instruction_text.Padding = Vector4(0, 0, 0, 0) --no idea why this is needed, but it wont wrap correctly without this.

    local saved_files = File.GetFiles(blue_prints.save_path)
    for name, value in pairs(saved_files) do
        if string.match(value, "%.txt$") then
            local filename = value:match("([^\\]+)$")
            local filename = string.gsub(filename, "%.txt$", "")
            
            local xml_of_file = blue_prints.readFile(value)
            local description_of_file = blue_prints.get_description_from_xml(xml_of_file)
            local number_of_components_in_file = blue_prints.get_component_count_from_xml(xml_of_file)
            
            -- Create button container
            local buttonContainer = GUI.Frame(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform))
            
            -- Create load button with tooltip
            local button_label = filename .. " - " .. tostring(number_of_components_in_file) .. " FPGAs"
            local leftButton = GUI.Button(GUI.RectTransform(Vector2(0.90, 1), buttonContainer.RectTransform, GUI.Anchor.CenterLeft), 
                tostring(button_label), GUI.Alignment.CenterLeft, "GUIButtonSmall")
            
            -- Set tooltip with description
            if description_of_file then
                description_of_file = description_of_file:gsub("&#xA;", "\n") --turn baros weird formatting back into newlines. This is how it does "enter".
                description_of_file = description_of_file:gsub("&#xD;", "\n") --2 versions of "enter" for some reason.
                leftButton.ToolTip = description_of_file
            else
                leftButton.ToolTip = "No description available"
            end
            
            leftButton.OnClicked = function ()
                blue_prints.most_recently_loaded_blueprint_name = filename
                blue_prints.construct_blueprint(filename)
                blue_prints.current_gui_page.Visible = not blue_prints.current_gui_page.Visible
            end

            -- Create delete button with tooltip
            local rightButton = GUI.Button(GUI.RectTransform(Vector2(0.10, 1), buttonContainer.RectTransform, GUI.Anchor.CenterRight), 
                "Delete", GUI.Alignment.Center, "GUIButtonSmall")
            rightButton.ToolTip = "Delete " .. filename
            rightButton.OnClicked = function ()
                message_box = GUI.MessageBox('Delete Blueprint?', 
                    'Are you sure you want to delete "' .. filename .. '"?', 
                    {'Cancel', 'Delete'}) 
    
                cancel_button = nil
                delete_button = nil
                
                if message_box.Buttons[0] == nil then --this is if no one has registered it. If some other mod registers it I dont want it to break.
                    cancel_button = message_box.Buttons[1]
                    delete_button = message_box.Buttons[2]
                else
                    cancel_button = message_box.Buttons[0]
                    delete_button = message_box.Buttons[1]
                end
                
                delete_button.Color = Color(255, 80, 80) -- Sets the button color to red
                delete_button.HoverColor = Color(255, 120, 120) -- light red hover color
                
                cancel_button.OnClicked = function ()
                    message_box.Close()
                end
                
                delete_button.OnClicked = function ()
                    blue_prints.delete_blueprint(filename)
                    blue_prints.current_gui_page.Visible = not blue_prints.current_gui_page.Visible
                    GUI.AddMessage('Blueprint Deleted', Color.White)
                    message_box.Close()
                end
            end
            rightButton.Color = Color(255, 80, 80)
            
            -- Add a small spacer between entries
            local spacer = GUI.Frame(GUI.RectTransform(Vector2(1, 0.01), menuList.Content.RectTransform))
        end
    end
    
    return blue_prints.current_gui_page
end

local function check_and_rebuild_frame()
    local new_resolution = blue_prints.getScreenResolution()
    if new_resolution ~= resolution or run_once_at_start == false then
        -- our main frame where we will put our custom GUI
        frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
        frame.CanBeFocused = false

        -- a button to right of our screen to open a sub-frame menu
        local button = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.2), frame.RectTransform, GUI.Anchor.CenterRight), "Load Blueprint", GUI.Alignment.Center, "GUIButtonSmall")
        button.RectTransform.AbsoluteOffset = Point(25, 0)
        button.OnClicked = function ()
            if blue_prints.current_gui_page ~= nil then blue_prints.current_gui_page.Visible = false end
            blue_prints.current_gui_page = nil
            blue_prints.current_gui_page = generate_load_gui()
            blue_prints.current_gui_page.Visible = not blue_prints.current_gui_page.Visible
        end

        resolution = new_resolution
        run_once_at_start = true
    end
end

Hook.Patch("Barotrauma.Items.Components.CircuitBox", "AddToGUIUpdateList", function()
    check_and_rebuild_frame()
    frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)