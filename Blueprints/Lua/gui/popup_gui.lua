if SERVER then return end -- we don't want server to run GUI code.

-- Create main frame for all popups
blue_prints.popup_frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
blue_prints.popup_frame.CanBeFocused = false
blue_prints.current_popup = nil

function blue_prints.show_popup(config)
    -- Hide any existing popup
    if blue_prints.current_popup then
        blue_prints.current_popup.Visible = false
    end
    
    -- Create new popup frame
    local popup = GUI.Frame(GUI.RectTransform(Vector2(1, 1), blue_prints.popup_frame.RectTransform, GUI.Anchor.Center), nil)
    popup.CanBeFocused = false
    popup.Visible = true
    blue_prints.current_popup = popup

    -- Background dimming
    local backgroundButton = GUI.Button(GUI.RectTransform(Vector2(1, 1), popup.RectTransform), "", GUI.Alignment.Center, nil)
    backgroundButton.Color = Color(0, 0, 0, 100)
    
    -- Content container
    local popupContent = GUI.Frame(GUI.RectTransform(Vector2(0.4, 0.6), popup.RectTransform, GUI.Anchor.Center))
    local popupList = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), popupContent.RectTransform, GUI.Anchor.BottomCenter))
    
    -- Title
    if config.title then
        local titleText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.15), popupList.Content.RectTransform), 
            config.title, nil, nil, GUI.Alignment.Center)
        titleText.TextScale = 1.5
        titleText.TextColor = Color(200, 200, 200)
        titleText.Wrap = true
    end
    
    -- Message lines
    if config.messages then
        for _, message in ipairs(config.messages) do
            local messageBlock = GUI.TextBlock(
                GUI.RectTransform(Vector2(1, message.height or 0.05), popupList.Content.RectTransform),
                message.text or message,
                nil, nil, GUI.Alignment.Center
            )
            messageBlock.Wrap = true
            messageBlock.TextColor = message.color or Color(200, 200, 200)
            if message.padding then
                messageBlock.Padding = message.padding
            else
                messageBlock.Padding = Vector4(10, 5, 10, 5)
            end
        end
    end
    
    -- Optional spacer
    if config.addSpacer then
        GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.10), popupList.Content.RectTransform), 
            '', nil, nil, GUI.Alignment.Center)
    end
    
    -- Buttons
    if config.buttons then
        for _, buttonConfig in ipairs(config.buttons) do
            local button = GUI.Button(
                GUI.RectTransform(Vector2(1, 0.1), popupList.Content.RectTransform),
                buttonConfig.text,
                GUI.Alignment.Center,
                "GUIButtonSmall"
            )
            if buttonConfig.color then
                button.Color = buttonConfig.color
            end
            button.OnClicked = function()
                if buttonConfig.onClick then
                    buttonConfig.onClick()
                end
                popup.Visible = false
            end
        end
    end
    
    -- Close on background click
    backgroundButton.OnClicked = function()
        popup.Visible = false
    end
    
    return popup
end

-- Add to GUI update list for all relevant screens
Hook.Patch("Barotrauma.GameScreen", "AddToGUIUpdateList", function()
    blue_prints.popup_frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)

Hook.Patch("Barotrauma.NetLobbyScreen", "AddToGUIUpdateList", function(self, ptable)
    blue_prints.popup_frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)

Hook.Patch("Barotrauma.SubEditorScreen", "AddToGUIUpdateList", function()
    blue_prints.popup_frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)

--[[
--use like this in other scripts:
blue_prints.show_popup({
    title = "Load Failed",
    messages = {
        {
            text = "Your circuit has failed to load.",
            height = 0.1  -- Taller block for wrapped text
        },
        {
            text = "Your blueprint file might be from an earlier version of Blueprints and nothing is actually wrong. Try saving it again (overwriting the original) to update your blueprint file to the latest version.",
            height = 0.2
        },
        {
            text = "If you are certain your file is up to date try loading it again. Do not move or change anything during loading: the loaded circuit must match the blueprint file EXACTLY in order for you not to see this message.",
            height = 0.2
        },
        {
            text = "This also means if the inputs change any values in any component the unit test will also fail. Same thing if you have some value that changes over time, like RGB or timing values from an oscillator. So the circuit might still be ok, it just does not match your save exactly.",
            height = 0.2
        },
        {
            text = "If none of these exceptions apply and the problem persists please report this bug on the steam workshop page or the discord. Include a download link to your saved blueprint file and a screenshot of your console text (you can see that by hitting F3)",
            --color = Color(255, 0, 0),  -- Red text
            height = 0.2
        }
    },
    addSpacer = true,
    buttons = {
        {
            text = "Close",
            onClick = function() end
        }
    }
})
--]]