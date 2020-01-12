//This is a bunch of helper function for getting connected devices,
//updating devices, getting linked generators etc

AddCSLuaFile("bitminers2_config.lua")
include("bitminers2_config.lua")

local P = FindMetaTable("Player")

--All bitminer ents
BITMINER_ENTS = {}

util.AddNetworkString("BM2.OpenTerminal")

//Used to tell the client to open a terminal for this entity.
function P:OpenBitminerTerminal(bitminer)
	net.Start("BM2.OpenTerminal")
		net.WriteEntity(bitminer)
	net.Send(self)
end

function P:SellBitcoins(bitminer)
	if bitminer.isBitminer == false or bitminer.isBitminer == nil then return end
	if table.HasValue(bitminer.authorisedPlayers, self) or bitminer.remoteUser == self then
		if self:GetEyeTrace().Entity ~= bitminer and bitminer.remoteUser ~= self then 
			net.Start("BM2.Client.TerminalPrint")
			net.WriteString("[ERROR] NOT LOOKING AT THE BITMINER! EXIT TERMINAL AND TRY AGAIN!")
			net.Send(self)
			return 
		end

		self:addMoney(bitminer.bitcoin * BM2CONFIG.BitcoinValue)
		bitminer.bitcoin = 0
		bitminer:SetBitcoinAmount(0)
	end
end

//Can be called on either a power lead, extention lead or plug 1 (recursion)
function BM2GetConnectedDevices(ent, devices)

	//Either set up the table or use the one passed from recussion
	devices = devices or {}

	//Stop here if we are already in the table (To prevent loops)
	if table.HasValue(devices, ent) then return devices end

	//insert ourselfs into the device list
	if isentity(ent) and ent ~= NULL then
		table.insert(devices, ent)	
	else
		return devices
	end

	//Now check what we are
	if  ent ~= NULL and ent:GetClass() == "bm2_extention_lead" then
		//Loop over all of the sockets
		for i = 1 , 4 do
			if ent.sockets[i].pluggedInEntity ~= nil then
				devices = BM2GetConnectedDevices(ent.sockets[i].pluggedInEntity, devices)
			end
		end
		//Now check what we are pluged into
		if ent.plug ~= nil then
			devices = BM2GetConnectedDevices(ent.plug, devices)
		end
	elseif ent ~= NULL and ent:GetClass() == "bm2_plug_1" then
		if ent.connectedDevice ~= nil then
			devices = BM2GetConnectedDevices(ent.connectedDevice, devices)
		end
		devices = BM2GetConnectedDevices(ent.parent, devices)
		if ent.parent ~= nil and ent.parent:GetClass() == "bm2_power_lead" and ent.parent.connectedDevice ~= nil then
			if not table.HasValue(devices, ent.parent.connectedDevice) and ent.parent.connectedDevice ~= NULL and isentity(ent.parent.connectedDevice) then
				table.insert(devices, ent.parent.connectedDevice)
			end
		end
	elseif ent ~= NULL and ent:GetClass() == "bm2_power_lead" then
		if ent.connectedDevice ~= nil then
			devices = BM2GetConnectedDevices(ent.connectedDevice, devices)
		end
		devices = BM2GetConnectedDevices(ent.plug, devices)
	elseif ent ~= NULL and ent:GetClass() == "bm2_generator" then
		for i = 1 , 2 do
			if ent.sockets[i].pluggedInEntity ~= nil then
				devices = BM2GetConnectedDevices(ent.sockets[i].pluggedInEntity, devices)
			end
		end
	elseif ent ~= NULL and ent:GetClass() == "bm2_solarconverter" then
		for i = 1 , 2 do
			if ent.sockets[i].pluggedInEntity ~= nil then
				devices = BM2GetConnectedDevices(ent.sockets[i].pluggedInEntity, devices)
			end
		end
	end

	//Return the device
	return devices
end

//Triggers an update for all these devices to store the devices there connected to. When ever something is connected of disconected then this needs to be called
function BM2UpdateAllConnectedDevices(ent)

	//These are entities that dont need a copy of connected devices.
	local skipEntities = {
		"bm2_plug_1",
		"bm2_extention_lead",
		"bm2_power_lead"
	}

	//Get the devices in the circit related to the entity
	local devices = BM2GetConnectedDevices(ent)
 
	//Update devices table on the devices required.
	for k ,v in pairs(devices) do
		if isentity(v) and v.GetClass then
			if isentity(v) and not table.HasValue(skipEntities, v:GetClass()) then
				v._devices = devices
				if v.OnDevicesUpdated then
					v:OnDevicesUpdated()
				end
			end
		end
	end
end
 
//Takes any bitminer and attemps to find the generator connected to it.
//Will return false is no generator is on the same cirv, second return is weather or not it is a battery box or a generator
function BM2GetConnectedGenerator(ent)
	if ent._devices == nil then return false end //There are no devices on this entity
	for k ,v in pairs(ent._devices) do
		if isentity(v) and v ~= NULL and v:GetClass() == "bm2_generator" then
			return v, false
		end
	end

	--Try to find a battery box instead
	for k ,v in pairs(ent._devices) do
		if isentity(v) and v ~= NULL and v:GetClass() == "bm2_solarconverter" then
			return v, true
		end
	end

	return false
end

//Takes a generator and returns all bitminers (in a table) connected to it
//Returns false if it is connected to no devices at all
function BM2GetConnectedMiners(ent)
	if ent._devices == nil then return false end
	local miners = {}
	for k ,v in pairs(ent._devices) do
		local class = "unknown"
		if v ~= NULL and isentity(v) and v.GetClass ~= nil then class = v:GetClass() end
		if class == "bm2_bitminer_1" or class == "bm2_bitminer_2" or class == "bm2_bitminer_rack" then
			table.insert(miners, v)
		end
	end
	return miners
end
  
//Networking stuff here
util.AddNetworkString("BM2.Client.TerminalPrint")
util.AddNetworkString("BM2.Command.Mining")
util.AddNetworkString("BM2.Command.SellBitcoins")
util.AddNetworkString("BM2.Command.Upgrade")
util.AddNetworkString("BM2.Command.Eject")

//Handles mining toggling
net.Receive("BM2.Command.Mining", function(len, ply)
	local ent = net.ReadEntity()
	local state = net.ReadBool()

	if ent.isBitminer then
		ent:CleanAuthorisedPlayers()
		if table.HasValue(ent.authorisedPlayers or {}, ply) or ent.remoteUser == ply then
			local info = ent:UpdateMiningState(state)
			net.Start("BM2.Client.TerminalPrint")
			net.WriteString(info)
			net.Send(ply)
		end
	end
end)

//Sell bitcoins
net.Receive("BM2.Command.SellBitcoins", function(len, ply)
	local e = net.ReadEntity()
	if not IsValid(e) then return end

	--if e:GetPos():Distance(e:GetPos()) > 300 and e.remoteUser ~= ply then return end
	if e.isBitminer then
		e:CleanAuthorisedPlayers()
	end
	if table.HasValue(e.authorisedPlayers or {}, ply) or e.remoteUser == ply then
		ply:SellBitcoins(e)
	end
end)

//Handles ejecting servers.
net.Receive("BM2.Command.Eject", function(len, ply)
	local e = net.ReadEntity()
	local index = math.Clamp(math.floor(net.ReadInt(8)), 1, 8)

	if e ~= nil and (table.HasValue(e.authorisedPlayers or {}, ply) or e.remoteUser == ply) then
		if ply:GetEyeTrace().Entity ~= e then 
				net.Start("BM2.Client.TerminalPrint")
				net.WriteString("[ERROR] NOT LOOKING AT THE BITMINER! EXIT TERMINAL AND TRY AGAIN!")
				net.Send(ply)
			return 
		end
		if e:GetClass() == "bm2_bitminer_rack" then
			if index > 0 and index < 9 then
				//Eject the server if it exists
				if e.rack[index] ~= nil then
					e:RemoveServer(index)
					net.Start("BM2.Client.TerminalPrint")
					net.WriteString("The server has been ejected.")
					net.Send(ply)
				else
					net.Start("BM2.Client.TerminalPrint")
					net.WriteString("There is not server in that slot, type 'SERVERS' for a list of connected servers.")
					net.Send(ply)
				end
			else
				net.Start("BM2.Client.TerminalPrint")
				net.WriteString("The index you supplied is not in range (1-8)")
				net.Send(ply)
			end
		end
	end
end)

//Upgrade the bitminers
net.Receive("BM2.Command.Upgrade", function(len, ply)
	local e = net.ReadEntity()
	local type = net.ReadBool() //false = 1 , true = 2
	if e ~= nil and e.isBitminer then
		if table.HasValue(e.authorisedPlayers or {}, ply) or e.remoteUser == ply then
			if ply:GetEyeTrace().Entity ~= e and e.remoteUser ~= ply then 
				net.Start("BM2.Client.TerminalPrint")
				net.WriteString("[ERROR] NOT LOOKING AT THE BITMINER! EXIT TERMINAL AND TRY AGAIN!")
				net.Send(ply)
				return 
			end
			if type then
				//Upgrade Cores
				if e.upgrades.CORES.cost[e.upgradeTracker.cores + 1] ~= nil then
					if ply:canAfford(e.upgrades.CORES.cost[e.upgradeTracker.cores + 1]) then
						ply:addMoney(e.upgrades.CORES.cost[e.upgradeTracker.cores + 1] * -1)
						e.upgradeTracker.cores = e.upgradeTracker.cores + 1
						e:SetCoreUpgrade(e.upgradeTracker.cores)
						e.cores = e.cores + 1
						e:SetCoreCount(e.cores)
						net.Start("BM2.Client.TerminalPrint")
						net.WriteString("Your upgrade has been installed (CORE), type info to see the new specifications!")
						net.Send(ply)
					else
						net.Start("BM2.Client.TerminalPrint")
						net.WriteString("You cannot afford this upgrade!")
						net.Send(ply)
					end
				end
			else
				//Upgrade Cores
				if e.upgrades.CPU.cost[e.upgradeTracker.cpu + 1] ~= nil then
					if ply:canAfford(e.upgrades.CPU.cost[e.upgradeTracker.cpu + 1]) then
						ply:addMoney(e.upgrades.CPU.cost[e.upgradeTracker.cpu + 1] * -1)
						e.clockSpeed = e.clockSpeed + e.upgrades.CPU.amountPerUpgrade
						e.upgradeTracker.cpu = e.upgradeTracker.cpu + 1
						e:SetClockSpeed(e.clockSpeed)
						e:SetCPUUpgrade(e.upgradeTracker.cpu)
						net.Start("BM2.Client.TerminalPrint")
						net.WriteString("Your upgrade has been installed (CPU), type info to see the new specifications!")
						net.Send(ply)
					else
						net.Start("BM2.Client.TerminalPrint")
						net.WriteString("You cannot afford this upgrade!")
						net.Send(ply)
					end
				end
			end
		end
	end
end)