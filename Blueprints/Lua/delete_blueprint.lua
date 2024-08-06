if SERVER then return end --prevents it from running on the server


function blue_prints.delete_blueprint(provided_path)

	local file_path = (blue_prints.save_path .. "/" .. provided_path)

	if File.Exists(file_path) then
		local result, err = os.remove(file_path)
		if result then
			print("File deleted successfully.")
		else
			print("Error deleting file: " .. err)
		end
	else
		print("file not found")
		print("saved designs:")
		blue_prints.print_all_saved_files()
	end

end
