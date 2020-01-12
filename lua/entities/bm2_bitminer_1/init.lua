AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	table.insert(BITMINER_ENTS, self)

	//Upgrade list, each upgrade cost is different, each cost you add defines how much it costs to upgrade it again
	self:SetModel("models/bitminers2/bitminer_1.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType(SIMPLE_USE)
	local physics = self:GetPhysicsObject()
	if (physics:IsValid()) then
		physics:Wake()
	end
 
	self:SetHealth(150)

	//This is how much power this bitminer uses. This is used to determin if the generator can power it or not.
	self.powerUsage = 1

	//This is the entity that we are "plugged" into. Will be nil if not pluged into any
	self.connectedEntity = nil

	self.socket = {
		position = Vector(-3.49,2.7,18),
		angle = Angle(0,0,0),
		pluggedInEntity = nil
	}

	//This is the target state for mining.
	self.miningState = false

	//This table will store players that have previous "used" the entity.
	//This way when receiving net messages we know if they have used it or not.
	self.authorisedPlayers = {}

	//An easy way to tell if something is one of the three bitminers
	self.isBitminer = true

	//Machine specs are here
	self.clockSpeed = 2.44
	self.cores = 1

	self:SetClockSpeed(self.clockSpeed)
	self:SetCoreCount(self.cores)

	self:SetBitcoinAmount(0)
	self.bitcoin = 0

	//Keeps track of upgrades
	self.upgradeTracker = {cpu = 0, cores = 0}

	self:SetAutomaticFrameAdvance(true)

	self.animation = false
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
	else
		self:SetIsMining(false)
	end
end

//When ever this is called it calculate the amount of bitcoint that should be mined and then stores it.
//This should only be called once per second by the generator, calling it more will cause it to give more bitcoins
function ENT:MineBitcoin()
	self.bitcoin = self.bitcoin + ((self.clockSpeed * BM2CONFIG.BaseSpeed * BM2CONFIG.BitminerSpeedMulipliers["bitminerS1"]) * self.cores)
	self:SetBitcoinAmount(self.bitcoin)
end

//These are command specific handlers

//Updates the entity to be mining or not.
function ENT:UpdateMiningState(state)
	if state then
		if not self:GetIsMining() then
			if self:GetHasPower() then
				self.miningState = true
				return "Started mining."
			else
				return "Cannot begin mining. No power received."
			end
		else
			return "This bitminer is already mining."
		end
	else
		if self:GetIsMining() then
			self.miningState = false
			return "The Bitminer has stopped mining."
		else
			return "The Bitminer has already stopped mining."
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