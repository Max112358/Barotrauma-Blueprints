if SERVER then return end -- we don't want server to run GUI code.

-- our main frame where we will put our custom GUI
local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
frame.CanBeFocused = false
local save_gui = nil

local function generate_save_gui()
	-- menu frame
	save_gui = GUI.Frame(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.Center), nil)
	save_gui.CanBeFocused = false
	save_gui.Visible = false

	-- put a button that goes behind the menu content, so we can close it when we click outside
	local closeButton = GUI.Button(GUI.RectTransform(Vector2(1, 1), save_gui.RectTransform, GUI.Anchor.Center), "", GUI.Alignment.Center, nil)
	closeButton.OnClicked = function ()
		save_gui.Visible = not save_gui.Visible
	end

	local menuContent = GUI.Frame(GUI.RectTransform(Vector2(0.4, 0.6), save_gui.RectTransform, GUI.Anchor.Center))
	local menuList = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), menuContent.RectTransform, GUI.Anchor.BottomCenter))

	local title_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "SAVE", nil, nil, GUI.Alignment.Center)
	title_text.TextScale = 2.0
	title_text.Wrap = false


	local instruction_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "Enter a filename and hit save. If using an existing filename, the old file will be overwritten. Click anywhere outside this box to cancel.", nil, nil, GUI.Alignment.Center)
	instruction_text.Wrap = true
	instruction_text.Padding = Vector4(0, 0, 0, 0) --no idea why this is needed, but it wont wrap correctly without this.


	local textBox = GUI.TextBox(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "Your filename here.")
	textBox.OnTextChangedDelegate = function (textBox)
		--print(textBox.Text)
	end
	
	local spacer_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)



	local save_button = GUI.Button(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "Save", GUI.Alignment.Center, "GUIButtonSmall")
	save_button.OnClicked = function ()
		blue_prints.save_blueprint(textBox.Text)
		save_gui.Visible = not save_gui.Visible
		GUI.AddMessage('File Saved', Color.White)
	end
	
	
	return save_gui
end


-- a button to right of our screen to open a sub-frame menu
local button = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.2), frame.RectTransform, GUI.Anchor.CenterRight), "Save Blueprint", GUI.Alignment.Center, "GUIButtonSmall")
button.RectTransform.AbsoluteOffset = Point(25, 70)
button.OnClicked = function ()
	save_gui = generate_save_gui()
	save_gui.Visible = not save_gui.Visible
end



Hook.Patch("Barotrauma.Items.Components.CircuitBox", "AddToGUIUpdateList", function()
    frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)
