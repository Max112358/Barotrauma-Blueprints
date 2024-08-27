if SERVER then return end -- we don't want server to run GUI code.

-- our main frame where we will put our custom GUI
local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
frame.CanBeFocused = false
local delete_gui = nil



-- a button to right of our screen to open a sub-frame menu
local button = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.2), frame.RectTransform, GUI.Anchor.CenterRight), "Clear Circuitbox", GUI.Alignment.Center, "GUIButtonSmall")
button.RectTransform.AbsoluteOffset = Point(25, 140)
button.OnClicked = function ()
	blue_prints.clear_circuitbox()
	GUI.AddMessage('Circuitbox Cleared', Color.White)
end



Hook.Patch("Barotrauma.Items.Components.CircuitBox", "AddToGUIUpdateList", function()
    frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)
