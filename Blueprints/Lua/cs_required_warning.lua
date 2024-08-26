if SERVER then return end -- we don't want server to run GUI code.

-- our main frame where we will put our custom GUI
local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
frame.CanBeFocused = false

-- popup frame
local popup = GUI.Frame(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.Center), nil)
popup.CanBeFocused = false
popup.Visible = true

local popupContent = GUI.Frame(GUI.RectTransform(Vector2(0.4, 0.6), popup.RectTransform, GUI.Anchor.Center))
local popupList = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), popupContent.RectTransform, GUI.Anchor.BottomCenter))

GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.15), popupList.Content.RectTransform), "WARNING", nil, nil, GUI.Alignment.Center)
GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), popupList.Content.RectTransform), "You are using Blueprints without enabling csharp scripting.", nil, nil, GUI.Alignment.Center)
GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), popupList.Content.RectTransform), 'Go to the main menu (the one with singleplayer, multiplayer, etc).', nil, nil, GUI.Alignment.Center)
GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), popupList.Content.RectTransform), 'In the main menu, click the "Open LuaCs Settings" button in the top left.', nil, nil, GUI.Alignment.Center)
GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), popupList.Content.RectTransform), 'Then hit the "enable csharp scripting" check box.', nil, nil, GUI.Alignment.Center)
GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), popupList.Content.RectTransform), 'Blueprints will not function without this.', nil, nil, GUI.Alignment.Center)
GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.10), popupList.Content.RectTransform), '', nil, nil, GUI.Alignment.Center)

local closeButton = GUI.Button(GUI.RectTransform(Vector2(1, 0.1), popupList.Content.RectTransform), "Close", GUI.Alignment.Center, "GUIButtonSmall")
closeButton.OnClicked = function ()
	popup.Visible = not popup.Visible
end


Hook.Patch("Barotrauma.NetLobbyScreen", "AddToGUIUpdateList", function(self, ptable)
    frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)

Hook.Patch("Barotrauma.SubEditorScreen", "AddToGUIUpdateList", function()
    frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)