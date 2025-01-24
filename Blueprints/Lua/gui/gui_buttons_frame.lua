if SERVER then return end -- we don't want server to run GUI code.

local resolution = blue_prints.getScreenResolution()
local run_once_at_start = false

--gui frame to hold the UI buttons that open the various GUIs
blue_prints.gui_button_frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
blue_prints.gui_button_frame.CanBeFocused = false
blue_prints.gui_button_frame.Visible = true

--this is needed to handle different resolutions
local function check_and_rebuild_frame()
    local new_resolution = blue_prints.getScreenResolution()
    if new_resolution ~= resolution or run_once_at_start == false then
        blue_prints.gui_button_frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
        blue_prints.gui_button_frame.CanBeFocused = false

        blue_prints.gui_button_frame_content = GUI.Frame(GUI.RectTransform(Vector2(0.1, 0.15), blue_prints.gui_button_frame.RectTransform, GUI.Anchor.CenterRight))
        blue_prints.gui_button_frame_list = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), blue_prints.gui_button_frame_content.RectTransform, GUI.Anchor.BottomCenter))

        local spacer = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.04), blue_prints.gui_button_frame_list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
        local title = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.08), blue_prints.gui_button_frame_list.Content.RectTransform), "Blueprints", nil, nil, GUI.Alignment.Center)
        title.TextColor = Color(180, 180, 255)

        resolution = new_resolution
        run_once_at_start = true
    end
end

Hook.Patch("Barotrauma.Items.Components.CircuitBox", "AddToGUIUpdateList", function()
    check_and_rebuild_frame()
    blue_prints.gui_button_frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)
