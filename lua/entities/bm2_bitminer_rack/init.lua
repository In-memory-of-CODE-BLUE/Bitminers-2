AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	table.insert(BITMINER_ENTS, self)

	//Upgrade list, each upgrade cost is different, each cost you add defines how much it costs to upgrade it again
	self:SetModel("models/bitminers2/bitminer_rack.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType(SIMPLE_USE)
	local physics = self:GetPhysicsObject()
	if (physics:IsValid()) then
		physics:Wake()
	end

	self:SetHealth(1000)

	//This is how much power this bitminer uses. This is used to determin if the generator can power it or not.
	self.powerUsage = 0

	//Power usage per server
	self.serverPowerUsage = 1

	//This is the entity that we are "plugged" into. Will be nil if not pluged into any
	self.connectedEntity = nil

	self.socket = {
		position = Vector(14.5,3.5,-26.25),
		angle = Angle(0,180,0),
		pluggedInEntity = nil
	}

	self.rack = {}
	self.rackStart = 4.9
	self.rackOffset = 7.2

	//This is the target state for mining.
	self.miningState = false

	//This table will store players that have previous "used" the entity.
	//This way when receiving net messages we know if they have used it or not.
	self.authorisedPlayers = {}

	//An easy way to tell if something is one of the three bitminers
	self.isBitminer = true

	//Machine specs are here
	self.serverCores = 2

	self.clockSpeed = 5.5
	self.cores = 0

	self:SetClockSpeed(self.clockSpeed)
	self:SetCoreCount(self.cores)

	self:SetBitcoinAmount(0)
	self.bitcoin = 0

	//Keeps track of upgrades
	self.upgradeTracker = {cpu = 0, cores = 0}

	self:SetAutomaticFrameAdvance(true)

	self.animation = false

	self:UpdateConnectedServers()
end	

//Updates the clients on connected servers
function ENT:UpdateConnectedServers()
	local t = {}
	self.powerUsage = 0
	for i = 1, 8 do
		if self.rack[i] ~= nil then
			t[i] = true
			self.powerUsage = self.powerUsage + self.serverPowerUsage
		else
			t[i] = false
		end
	end
	self:SetConnectedServers(util.TableToJSON(t))
	self:SetCoreCount(self.cores)
end

//Removes the server from the rack
function ENT:RemoveServer(index) 
	self.cores = self.cores - self.serverCores 
	local pos = self.rack[index]:GetPos()
	pos = pos + self:GetAngles():Forward() * 45
	self.rack[index].beenPlacedIntoRack = false
	self.rack[index]:SetParent()
	self.rack[index]:SetMoveType(MOVETYPE_VPHYSICS)
	self.rack[index]:GetPhysicsObject():EnableGravity(true)
	self.rack[index]:SetPos(pos)
	self.rack[index] = nil
	self:UpdateConnectedServers()
end

//Adds a server to the rack
function ENT:StartTouch(e)
	if e:GetClass() == "bm2_bitminer_server" then
		if(table.Count(self.rack) == 8) then
			return
		end

		if e.beenPlacedIntoRack then return end
		e.beenPlacedIntoRack = true
		local hasSpace = -1
		for i = 1 , 8 do
			if self.rack[i] == nil then
				hasSpace = i
				break
			end
		end 
 
		if hasSpace ~= -1 then
			local pos = self:GetAngles():Up() * self.rackStart
			pos = pos + self:GetAngles():Up() * (self.rackOffset * (hasSpace - 1))
			pos = pos + self:GetAngles():Forward() * 0.1
			e:SetPos(self:GetPos() + pos)
			e:SetAngles(self:GetAngles())
			e:SetMoveType(MOVETYPE_NONE)
			e:SetParent(self)
			self.rack[hasSpace] = e
			self.rack[hasSpace].index = hasSpace
			self.rack[hasSpace].parentServer = self
			self.cores = self.cores + self.serverCores 
			self:UpdateConnectedServers()
		end
	end
end

//Returns true if the rack has at least one server mounted
function ENT:HasServer()
	local hasServer = false
	for i = 1 , 8 do
		if self.rack[i] ~= nil then
			hasServer = true
			break
		end
	end 
	return hasServer
end

//Attemps to "plug in" anouther plug into ourself, this will return false if it failes and pos, ang if it succeeds
function ENT:PlugIn(ent)
	//We dont want to plug something in that does not fit ;D
	if ent:GetClass() ~= "bm2_power_lead" then return false end 

	//Find empty socket
	local emptySocket = false

	if self.socket.pluggedInEntity == nil then
		emptySocket = true
	end

	//We found a slot
	if emptySocket  then
		self.socket.pluggedInEntity = ent

		local pos = self:GetAngles():Right() * self.socket.position.x
		pos = pos + self:GetAngles():Forward() * self.socket.position.z
		pos = pos + self:GetAngles():Up() * self.socket.position.y

		//Return the position so the plug can position itself correctly
		return self:GetPos() + pos, self.socket.angle
	end

	//We failes :c
	return false
end

//Used to disconnect the plug from the entity its pluged into (the bitminer)
function ENT:Unplug(plug)
	if self.socket.pluggedInEntity == plug then
		self.socket.pluggedInEntity = nil //unplug
	end
end

--Cleans up the authorised player table
function ENT:CleanAuthorisedPlayers()
	for k, v in pairs(self.authorisedPlayers) do
		if IsValid(v) then
			if v:GetPos():Distance(self:GetPos()) > 300 then
				self.authorisedPlayers[k] = nil
			end
		else
			self.authorisedPlayers[k] = nil
		end
	end
end

function ENT:Use(ent, caller)
	if caller:GetPos():Distance(self:GetPos()) > 300 then return end
	
	self:CleanAuthorisedPlayers()
	
	if not table.HasValue(self.authorisedPlayers, caller) then
		table.insert(self.authorisedPlayers, caller)
	end

	caller:OpenBitminerTerminal(self)
end

//Called when ever the device is connected/diconnected from something
function ENT:OnDevicesUpdated()
	if BM2GetConnectedGenerator(self) == false then
		self:SetHasPower(false)
	end
end

function ENT:Think()
	if self.miningState and self:GetHasPower() then
		self:SetIsMining(true)
		for k ,v in pairs(self.rack) do
			if v.SetShouldAnimate then
				v:SetShouldAnimate(true)
			end
		end
	else
		self:SetIsMining(false)
		for k ,v in pairs(self.rack) do
			if v.SetShouldAnimate then
				v:SetShouldAnimate(false)
			end
		end
	end
end

//When ever this is called it calculate the amount of bitcoint that should be mined and then stores it.
//This should only be called once per second by the generator, calling it more will cause it to give more bitcoins
function ENT:MineBitcoin()
	self.bitcoin = self.bitcoin + ((self.clockSpeed * BM2CONFIG.BaseSpeed * BM2CONFIG.BitminerSpeedMulipliers["bitminerRack"]) * self.cores)
	self:SetBitcoinAmount(self.bitcoin)
end

//These are command specific handlers

//Updates the entity to be mining or not.
function ENT:UpdateMiningState(state)
	if state then
		if not self:GetIsMining() then
			if self:GetHasPower() and self:HasServer() then
				self.miningState = true
				return "Started mining"
			elseif not self:HasServer() then

				return "The rack has no servers mounted. Please add at least one to start mining."
			else
				return "Cannot begin mining. No power received."
			end
		else
			return "This bitminer is already mining."
		end
	else
		if self:GetIsMining() then
			self.miningState = false
			return "The Bitminer Rack has stopped mining."
		else
			return "The Bitminer Rack has already stopped mining."
		end
	end
end

//Destroying it
function ENT:OnTakeDamage(damage)
	self:SetHealth(self:Health() - damage:GetDamage())
	if self:Health() <= 0 then
		self:Remove()
	end
end

function ENT:OnRemove()
	if self.socket.pluggedInEntity ~= nil then
		self.socket.pluggedInEntity:UnPlug()
	end

	table.RemoveByValue(BITMINER_ENTS, self)
end

