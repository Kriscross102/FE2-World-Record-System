local module = {}

-- Variables -- -- --

local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStore = DataStoreService:GetDataStore("FE2_WRStore")
local Map = workspace.Multiplayer:WaitForChild("Map")
local WREvent, WR, MapID, WRType, WRSolo, WRMulti = nil, nil, "NotSet", "Solo", nil, nil


local MapName = Map.Settings.MapName.Value
local SSMap

function module:SetMapID(id)
	MapID = id
end

-- Setup Events -- -- -- -- -- -- -- -- -- --

if workspace:FindFirstChild("WREvent") == nil then
	WREvent = Instance.new("RemoteEvent", workspace)
	WREvent.Name = "WREvent"
else
	WREvent = workspace:FindFirstChild("WREvent")
end

-- Setup Data Functions -- -- -- -- -- -- -- -- -- --

function FetchData(MapID, Type) -- Get the data and return different values depending on the multi/solo record.
	if Type == "Multiplayer" then
		return DataStore:GetAsync("WRKey_" .. MapID .. "_Multiplayer")
	elseif Type == "Solo" then
		return DataStore:GetAsync("WRKey_" .. MapID .. "_Solo")
	end
end

function SetData(Plr, min, sec, milli) -- Save the data to the datastore to be used across all servers.
	local f, e = pcall(function()
		DataStore:UpdateAsync("WRKey_" .. MapID .. "_" .. WRType, function(oldVal)
			return Plr.UserId .. "-" .. min .. "-" .. sec .. "-" .. milli
		end)
	end)
end

-- Setup Check Functions -- -- -- -- -- -- -- -- -- --

function CheckSoloWR(plr, min, sec, milli) 
	-- Kinda sloppy math, mathematicians please don't kill me :/
	if WRSolo ~= nil then
		if ((min * 60) + sec + (milli / 1000)) < (((WRSolo[2]) * 60) + (WRSolo[3]) + ((WRSolo[4]) / 1000)) then
			-- New WR
			SetData(plr, min, string.format("%02d", sec), milli)
			ReplicatedStorage.Remote.Alert:FireAllClients("New World Record! - " .. plr.Name .. " - " .. min .. ":" .. string.format("%02d", sec) .. "." .. milli .. " (Solo)")
		end
	else
		-- First ever WR
		SetData(plr, min, string.format("%02d", sec), milli)
		ReplicatedStorage.Remote.Alert:FireAllClients("New World Record! - " .. plr.Name .. " - " .. min .. ":" .. string.format("%02d", sec) .. "." .. milli .. " (Solo)")	
	end
end

function CheckMultiWR(plr, min, sec, milli)
	-- Kinda sloppy math v2 :/
	if WRMulti ~= nil then
		if ((min * 60) + sec + (milli / 1000)) < (((WRMulti[2]) * 60) + (WRMulti[3]) + ((WRMulti[4]) / 1000)) then
			-- New WR
			SetData(plr, min, string.format("%02d", sec), milli)
			ReplicatedStorage.Remote.Alert:FireAllClients("New World Record! - " .. plr.Name .. " - " .. min .. ":" .. string.format("%02d", sec) .. "." .. milli .. " (Multiplayer)")
		end
	else
		-- First ever WR
		SetData(plr, min, string.format("%02d", sec), milli)
		ReplicatedStorage.Remote.Alert:FireAllClients("New World Record! - " .. plr.Name .. " - " .. min .. ":" .. string.format("%02d", sec) .. "." .. milli .. " (Multiplayer)")	
	end
end

-- Setup Full Module -- -- -- -- -- -- -- -- -- --

function module:Start()
	local cur_plrs = {}
	local count = 0
	local records = {}
	local record_times = {}
	local record_plr
	
	-- Make sure the map ID is set and make sure that the correct map ID is being used to avoid hacking world records for other maps.
	
	if MapID == "NotSet" then
		ReplicatedStorage.Remote.Alert:FireAllClients("Please set a map ID otherwise the module cannot work!", Color3.new(1, 0, 0))
		return
	end
	
	if Map:FindFirstChild("Settings") then
		local MapName = Map.Settings.MapName.Value
		local Creator = Map.Settings.Creator.Value
		local SSMap

		table.foreach(ServerStorage.Maps:GetChildren(), function(i,v)
			if v.Settings.MapName.Value == MapName and v.Settings.Creator.Value == Creator then
				SSMap = v
			end
		end)
		
		-- Make sure that the correct map ID is being used to not override other map world records. People can be sneaky :/

		local SSMapID, EndLen = string.find(SSMap.Name, MapID)
		if SSMapID ~= nil then
			print("Map ID is correct")
		else
			ReplicatedStorage.Remote.Alert:FireAllClients("The Map ID that you have set is incorrect!", Color3.new(1, 0, 0))
			return
		end
	end
	
	-- Check who is in the map and add it to the 'cur_plrs' table, remove them once they are done.
	
	if workspace.Multiplayer:FindFirstChild("Map") then
		for k,v in pairs(game.Players:GetPlayers()) do
			if (workspace.Multiplayer.Map.Spawn.Position - v.Character.Humanoid.RootPart.Position).magnitude <= 50 then
				if v.Character and v.Character:FindFirstChild("WRClient") == nil then
					local s = script.WRClient:Clone()
					s.Parent = v.Character
					s.Disabled = false
				end
				cur_plrs[#cur_plrs + 1] = v
				v.Character.Humanoid.Died:Connect(function()
					for k = 1, #cur_plrs do
						if cur_plrs[k] == v then
							table.remove(cur_plrs, k)
						end
					end
				end)
			end
		end
	else
		return
	end
	
	-- Change the world record type based on the amount of players in the map
	
	if #cur_plrs > 1 then
		WRType = "Multiplayer"
	else
		WRType = "Solo"
	end
	
	-- Wait for everyone to survive and make sure that people are still alive
	
	spawn(function()
		while game:GetService("RunService").Heartbeat:Wait() do
			if #cur_plrs ~= 0 and count >= #cur_plrs then
				if WRType == "Solo" then
					record_plr = record_times[1][1]
					CheckSoloWR(record_plr, record_times[1][2], record_times[1][3], record_times[1][4])
					break
				elseif WRType == "Multiplayer" then
					record_plr = record_times[1][1]
					CheckMultiWR(record_plr, record_times[1][2], record_times[1][3], record_times[1][4])
					break
				end
			end
		end
	end)
	
	-- At the start of the map, display the solo and multiplayer records
	
	WRSolo = FetchData(MapID, "Solo")
	if WRSolo ~= nil then
		WRSolo = string.split(WRSolo, "-")
		ReplicatedStorage.Remote.Alert:FireAllClients("Current WR: " .. game.Players:GetNameFromUserIdAsync(WRSolo[1]) .. " - " ..  (WRSolo[2] .. ":" .. WRSolo[3] .. "." .. WRSolo[4]) .. " (Solo)")
	end
	
	WRMulti = FetchData(MapID, "Multiplayer")
	if WRMulti ~= nil then
		WRMulti = string.split(WRMulti, "-")
		ReplicatedStorage.Remote.Alert:FireAllClients("Current WR: " .. game.Players:GetNameFromUserIdAsync(WRMulti[1]) .. " - " ..  (WRMulti[2] .. ":" .. WRMulti[3] .. "." .. WRMulti[4]) .. " (Multiplayer)")
	end
	
	-- When the time event is fired, add the time into the table, and sort it based on length (in seconds)
	
	-- Again, sloppy math :/
	
	WREvent.OnServerEvent:Connect(function(plr, min, sec, milli)
		if records[plr] == nil then
			count = count + 1
			records[plr] = 1
			record_times[#record_times + 1] = {plr, min, sec, milli}
			table.sort(record_times, function(a, b)
				return ((a[2] * 60) + a[3] + (a[4] / 1000)) < ((b[2] * 60) + b[3] + (b[4] / 1000))
			end)
		end 
	end)
end

-- All done!

print("Module is all working.")

return module
