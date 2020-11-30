game.Players.LocalPlayer.PlayerGui.GameGui.HUD.Alerts.ChildAdded:Connect(function(v)
	pcall(function()
		-- Check if the text is the "Checking..." text.
		if v.Text == "Checking..." then
			-- Wait until it isn't checking and see if the player survived
			repeat wait() until v.Text ~= "Checking..." 
			-- Make sure they don't have the "Incorrect Exit" text
			if string.find(v.Text, "You Survived!") then
				-- Extract the digits and fire the event
				local digits = {}
				for x in string.gmatch(v.Text, "%d+") do
					digits[#digits + 1] = tonumber(x)
				end
				local min, sec, milli = digits[1], digits[2], digits[3]	
				if workspace.WREvent ~= nil then
					workspace.WREvent:FireServer(min, sec, milli)
				end
			end
		end
	end)
end)