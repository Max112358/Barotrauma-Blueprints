if SERVER then return end -- we don't want server to run GUI code.

local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
local resolution = Screen.Selected.Cam.Resolution
local run_once_at_start = false

local function check_and_rebuild_frame()
	local new_resolution = Screen.Selected.Cam.Resolution
	if new_resolution ~= resolution or run_once_at_start == false then

		-- our main frame where we will put our custom GUI
    	frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
		frame.CanBeFocused = false

		-- a button to right of our screen to open a sub-frame menu
		local button = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.2), frame.RectTransform, GUI.Anchor.CenterRight), "Clear Circuitbox", GUI.Alignment.Center, "GUIButtonSmall")
		button.RectTransform.AbsoluteOffset = Point(25, 140)
		button.OnClicked = function ()
			
			message_box = GUI.MessageBox('Are you sure you want to clear the box?', 'This will remove all components, labels and wires.', {'Cancel', 'Clear Box'}) 
			
			cancel_button = nil
			clear_button = nil
			
			if message_box.Buttons[0] == nil then --this is if no one has registered it. If some other mod registers it I dont want it to break.
				cancel_button = message_box.Buttons[1]
				clear_button = message_box.Buttons[2]
			else --if its been registered, it will behave as a csharp table
				cancel_button = message_box.Buttons[0]
				clear_button = message_box.Buttons[1]
			end
			
			cancel_button.OnClicked = function ()
				message_box.Close()
			end
			
			clear_button.OnClicked = function ()
				blue_prints.clear_circuitbox()
				GUI.AddMessage('Circuitbox Cleared', Color.White)
				message_box.Close()
			end
			
			
			
		end


		resolution = new_resolution
		run_once_at_start = true
	end
end




Hook.Patch("Barotrauma.Items.Components.CircuitBox", "AddToGUIUpdateList", function()
	check_and_rebuild_frame()
    frame.AddToGUIUpdateList()
end, Hook.HookMethodType.After)
