if SERVER then return end -- we don't want server to run GUI code.

-- our main frame where we will put our custom GUI
local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
frame.CanBeFocused = false

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

	local title_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "LOAD", nil, nil, GUI.Alignment.Center)
	title_text.TextScale = 2.0
	title_text.Wrap = false


	local instruction_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "Click on one of the buttons to load that blueprint. The FPGA cost is how many components are required to make it. If the base component is not available, FPGAs will be used instead. These components must be in your main inventory, not a toolbelt/backpack etc. Click anywhere outside this box to cancel.", nil, nil, GUI.Alignment.Center)
	instruction_text.Wrap = true
	instruction_text.Padding = Vector4(0, 0, 0, 0) --no idea why this is needed, but it wont wrap correctly without this.


	local saved_files = File.GetFiles(blue_prints.save_path)
	for name, value in pairs(saved_files) do
		if string.match(value, "%.txt$") then
			local filename = value:match("([^\\]+)$") --capture after last backslash
			local filename = string.gsub(filename, "%.txt$", "") --cut out the .txt at the end
			
			local xml_of_file = blue_prints.readFile(value)
			local description_of_file = blue_prints.get_description_from_xml(xml_of_file)
			local number_of_components_in_file = blue_prints.get_component_count_from_xml(xml_of_file)
			
			local blueprint_button = GUI.Button(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), tostring(filename), GUI.Alignment.Center, "GUIButtonSmall")
			blueprint_button.OnClicked = function ()
				blue_prints.construct_blueprint(filename)
				blue_prints.current_gui_page.Visible = not blue_prints.current_gui_page.Visible
				GUI.AddMessage('File Loading...', Color.White)
			end
			
			local component_count_string = filename .. " - " .. tostring(number_of_components_in_file) .. " FPGAs"
			local component_count_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.025), menuList.Content.RectTransform), component_count_string, nil, nil, GUI.Alignment.Center)
			--component_count_text.TextColor = Color(math.random(0, 255), math.random(0, 255), math.random(0, 255))
			component_count_text.Wrap = false
			
			
			if description_of_file ~= nil then
				local description_text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.15), menuList.Content.RectTransform), description_of_file, nil, nil, GUI.Alignment.CenterLeft)
				description_text.Wrap = true
				description_text.Padding = Vector4(0, 0, 0, 0) --no idea why this is needed, but it wont wrap correctly without this.
			end
		end
	end
	
	return blue_prints.current_gui_page
end


-- a button to right of our screen to open a sub-frame menu
local button = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.2), frame.RectTransform, GUI.Anchor.CenterRight), "Load Blueprint", GUI.Alignment.Center, "GUIButtonSmall")
button.RectTransform.AbsoluteOffset = Point(25, 0)
button.OnClicked = function ()
	if blue_prints.current_gui_page ~= nil then blue_prints.current_gui_page.Visible = false end
	blue_prints.current_gui_page = nil
	blue_prints.current_gui_page = generate_load_gui()
	blue_prints.current_gui_page.Visible = not blue_prints.current_gui_page.Visible
end



Hook.Patch("Barotrauma.Items.Components.CircuitBox", "AddToGUIUpdateList", function()
    frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)
