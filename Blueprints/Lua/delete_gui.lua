if SERVER then return end -- we don't want server to run GUI code.

-- our main frame where we will put our custom GUI
local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
frame.CanBeFocused = false


local function generate_delete_gui()
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

	local title_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "DELETE", nil, nil, GUI.Alignment.Center)
	title_text.TextScale = 2.0
	title_text.Wrap = false
	title_text.TextColor = Color(255, 0, 0)


	local instruction_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "Enter a filename and hit delete. Click anywhere outside this box to cancel.", nil, nil, GUI.Alignment.Center)
	instruction_text.Wrap = true
	instruction_text.Padding = Vector4(0, 0, 0, 0) --no idea why this is needed, but it wont wrap correctly without this.


	local textBox = GUI.TextBox(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "Your filename here")
	textBox.OnTextChangedDelegate = function (textBox)
		--print(textBox.Text)
	end
	if blue_prints.most_recently_loaded_blueprint_name ~= nil then
		textBox.Text = blue_prints.most_recently_loaded_blueprint_name
	end
	
	local spacer_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)



	local delete_button = GUI.Button(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "Delete", GUI.Alignment.Center, "GUIButtonSmall")
	delete_button.OnClicked = function ()
		blue_prints.delete_blueprint(textBox.Text)
		blue_prints.current_gui_page.Visible = not blue_prints.current_gui_page.Visible
		GUI.AddMessage('File Deleted', Color.White)
	end
	
	
	return blue_prints.current_gui_page
end


-- a button to right of our screen to open a sub-frame menu
local button = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.2), frame.RectTransform, GUI.Anchor.CenterRight), "Delete Blueprint", GUI.Alignment.Center, "GUIButtonSmall")
button.RectTransform.AbsoluteOffset = Point(25, 210)
button.OnClicked = function ()
	if blue_prints.current_gui_page ~= nil then blue_prints.current_gui_page.Visible = false end
	blue_prints.current_gui_page = nil
	blue_prints.current_gui_page = generate_delete_gui()
	blue_prints.current_gui_page.Visible = not blue_prints.current_gui_page.Visible
end



Hook.Patch("Barotrauma.Items.Components.CircuitBox", "AddToGUIUpdateList", function()
    frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)
