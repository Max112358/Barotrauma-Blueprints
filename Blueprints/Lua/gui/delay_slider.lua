if SERVER then return end

local resolution = blue_prints.getScreenResolution()
local run_once_at_start = false

local function check_and_rebuild_frame()
    local new_resolution = blue_prints.getScreenResolution()
    if new_resolution ~= resolution or run_once_at_start == false then

        local spacer = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.08), blue_prints.gui_button_frame_list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)

        -- Create the label
        local label = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.08), blue_prints.gui_button_frame_list.Content.RectTransform), "Load/Clear Delay", nil, nil, GUI.Alignment.Center)

        local scrollBar = GUI.ScrollBar(GUI.RectTransform(Vector2(1, 0.1), blue_prints.gui_button_frame_list.Content.RectTransform), 0.1, nil, "GUISlider")
        
        scrollBar.Range = Vector2(150, 1000)

        if run_once_at_start == false then
            scrollBar.BarScrollValue = blue_prints.time_delay_between_loops
            run_once_at_start = true
        end

        scrollBar.OnMoved = function ()
            local truncatedValue = math.floor(scrollBar.BarScrollValue) -- Truncate to nearest integer
                scrollBar.ToolTip = "Delay for loading. Increase on laggier servers. Current Value: " .. truncatedValue .. "ms"
            --print(truncatedValue)
            blue_prints.time_delay_between_loops = truncatedValue
        end

        resolution = new_resolution
    end
end

Hook.Patch("Barotrauma.Items.Components.CircuitBox", "AddToGUIUpdateList", function()
    check_and_rebuild_frame()
end, Hook.HookMethodType.After)
