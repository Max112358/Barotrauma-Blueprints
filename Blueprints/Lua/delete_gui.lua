if SERVER then return end -- we don't want server to run GUI code.

-- our main frame where we will put our custom GUI
local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
frame.CanBeFocused = false
local delete_gui = nil

local function generate_delete_gui()
	-- menu frame
	delete_gui = GUI.Frame(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.Center), nil)
	delete_gui.CanBeFocused = false
	delete_gui.Visible = false

	-- put a button that goes behind the menu content, so we can close it when we click outside
	local closeButton = GUI.Button(GUI.RectTransform(Vector2(1, 1), delete_gui.RectTransform, GUI.Anchor.Center), "", GUI.Alignment.Center, nil)
	closeButton.OnClicked = function ()
		delete_gui.Visible = not delete_gui.Visible
	end

	local menuContent = GUI.Frame(GUI.RectTransform(Vector2(0.4, 0.6), delete_gui.RectTransform, GUI.Anchor.Center))
	local menuList = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), menuContent.RectTransform, GUI.Anchor.BottomCenter))

	local title_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "DELETE", nil, nil, GUI.Alignment.Center)
	title_text.TextScale = 2.0
	title_text.Wrap = false


	local instruction_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "Enter a filename and hit delete. Click anywhere outside this box to cancel.", nil, nil, GUI.Alignment.Center)
	instruction_text.Wrap = true
	instruction_text.Padding = Vector4(0, 0, 0, 0) --no idea why this is needed, but it wont wrap correctly without this.


	local textBox = GUI.TextBox(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "Your filename here.")
	textBox.OnTextChangedDelegate = function (textBox)
		--print(textBox.Text)
	end
	
	local spacer_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)



	local delete_button = GUI.Button(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "Delete", GUI.Alignment.Center, "GUIButtonSmall")
	delete_button.OnClicked = function ()
		blue_prints.delete_blueprint(textBox.Text)
		delete_gui.Visible = not delete_gui.Visible
		GUI.AddMessage('File Deleted', Color.White)
	end
	
	
	return delete_gui
end


-- a button to right of our screen to open a sub-frame menu
local button = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.2), frame.RectTransform, GUI.Anchor.CenterRight), "Delete Blueprint", GUI.Alignment.Center, "GUIButtonSmall")
button.RectTransform.AbsoluteOffset = Point(25, 210)
button.OnClicked = function ()
	delete_gui = generate_delete_gui()
	delete_gui.Visible = not delete_gui.Visible
end



Hook.Patch("Barotrauma.Items.Components.CircuitBox", "AddToGUIUpdateList", function()
    frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)
