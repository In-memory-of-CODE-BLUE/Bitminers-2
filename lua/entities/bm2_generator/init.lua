AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

sound.Add( {
	name = "bm2_engine",
	channel = CHAN_STATIC,
	volume = 1,
	level = 75,
	pitch = { 95, 110 },
	sound = "vehicles/v8/v8_idle_loop1.wav"
} )

function ENT:Initialize()
	self:SetModel("models/bitminers2/generator.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	local physics = self:GetPhysicsObject()
	if (physics:IsValid()) then
		physics:Wake()
	end

	self:SetHealth(1000)

	self.soundPlaying = false

	//This is the entity that we are "plugged" into. Will be nil if not pluged into any
	self.connectedEntity = nil

	//This is a table of socket infomation such as socket position, angle, and if something is plugged in or not
	self.sockets = {
		[1] = {
			position = Vector(19.7,14,-13.7),
			angle = Angle(0,0,0),
			pluggedInEntity = nil
		},
		[2] = {
			position = Vector(19.7,14,-13.7 - 6.9),
			angle = Angle(0,0,0),
			pluggedInEntity = nil 
		}
	}

	//Between 0 and 100
	self.fuel = 500

	//This is how much the fuelConsumption should be multiplied by, this should be a pretty low number
	self.fuelDepleteRate = BM2CONFIG.BaseFuelDepletionRate

	//Max amount of watt to output (in KW)
	self.maxPowerOut = BM2CONFIG.GeneratorPowerOutput //1000W

	self.fuelTickTimer = CurTime() //Used to time fuel consumption

	self.connectedFuelLine = nil
end	


function ENT:UpdatePowerToBitminers(bitminers, shouldPower)
	for k, v in pairs(bitminers) do
		v:SetHasPower(shouldPower)
	end
end
 
//Called once per second to calculate how much fuel should be lost based on what is being powered
function ENT:TickFuel()
	if self.fuel > 0 then
		self:SetShowNoFuelWarning(false)
		local connectedBitminers = BM2GetConnectedMiners(self)
		if connectedBitminers == false then 
			self:SetPowerConsumpsion(0)
			return 
		end //Dont use any fuel
		local fuelConsumption = 0 //How much fuel to use
		for k ,v in pairs(connectedBitminers) do
			if v.miningState then
				fuelConsumption = fuelConsumption + v.powerUsage
			end
		end

		if fuelConsumption > self.maxPowerOut then
			self:SetShowToMuchPowerWarning(true)
			if self.soundPlaying then
				self:StopSound("bm2_engine")
				self.soundPlaying = false 
			end	
			self:UpdatePowerToBitminers(connectedBitminers, false)
			return 
		else
			self:SetShowToMuchPowerWarning(false)
			self.fuel = self.fuel - (fuelConsumption * self.fuelDepleteRate)
			self:SetPowerConsumpsion(fuelConsumption)
			
			if self.fuel <= 0 then
				self:UpdatePowerToBitminers(connectedBitminers, false)
				self.fuel = 0
				return
			end 
		end

		if fuelConsumption > 0 then
			if not self.soundPlaying and BM2CONFIG.GeneratorsProduceSound then
				self:EmitSound("bm2_engine")
				self.soundPlaying = true
			end
			for k ,v in pairs(connectedBitminers) do
				if v.miningState then
					v:MineBitcoin() //Also mines the bitcoins to keep them all in sync with each other
					fuelConsumption = fuelConsumption + v.powerUsage
				end
			end
		else
			if self.soundPlaying and BM2CONFIG.GeneratorsProduceSound then
				self:StopSound("bm2_engine")
				self.soundPlaying = false
			end	
		end

		self:UpdatePowerToBitminers(connectedBitminers, true)
	else
		self:SetShowNoFuelWarning(true)
		if self.soundPlaying and BM2CONFIG.GeneratorsProduceSound then
			self:StopSound("bm2_engine")
			self.soundPlaying = false
		end
	end
end

function ENT:Think()
	if CurTime() > self.fuelTickTimer then
		self.fuelTickTimer = CurTime() + 1
		self:TickFuel() 
		self:SetFuelLevel(self.fuel)
	end
end

function ENT:PlugInFuelLine(ent)
	if self.connectedFuelLine == nil then
		self.connectedFuelLine = ent

		local socketPos = Vector(0,43.3,-22.6)
		local socketAng = Angle(180,0,0)

		local pos = self:GetAngles():Right() * socketPos.x
		pos = pos + self:GetAngles():Forward() * socketPos.z
		pos = pos + self:GetAngles():Up() * socketPos.y

		//Return the position so the plug can position itself correctly
		return true, self:GetPos() + pos, socketAng
	else
		return false
	end
end

//Attemps to "plug in" anouther plug into ourself, this will return false if it failes and pos, ang if it succeeds
function ENT:PlugIn(ent)
	//We dont want to plug something in that does not fit ;D
	if ent:GetClass() ~= "bm2_plug_1" then return false end 

	//Find empty socket
	local emptySocket = -1
	for i = 1 , 2 do
		if self.sockets[i].pluggedInEntity == nil then
			emptySocket = i
			break
		end
	end

	//We found a slot
	if emptySocket ~= -1 then
		self.sockets[emptySocket].pluggedInEntity = ent

		local pos = self:GetAngles():Right() * self.sockets[emptySocket].position.x
		pos = pos + self:GetAngles():Forward() * self.sockets[emptySocket].position.z
		pos = pos + self:GetAngles():Up() * self.sockets[emptySocket].position.y

		//Return the position so the plug can position itself correctly
		return self:GetPos() + pos, self.sockets[emptySocket].angle
	end

	//We failes :c
	return false
end

//Used to disconnect the plug from the entity its pluged into (the generator)
function ENT:Unplug(plug)
	for i = 1 , 2 do
		if self.sockets[i].pluggedInEntity == plug then
			self.sockets[i].pluggedInEntity = nil //unplug
		end
	end
end

function ENT:OnRemove()
	for i = 1 , 2 do
		if self.sockets[i].pluggedInEntity ~= nil then
			self.sockets[i].pluggedInEntity:UnPlug()
		end
	end
	self:StopSound("bm2_engine")
end

function ENT:StartTouch(ent)
	if ent:GetClass() == "bm2_fuel" or ent:GetClass() == "bm2_large_fuel" then
		if not ent.used then
			ent.used = true
			ent:Remove()
			self.fuel = math.Clamp(self.fuel + ent.fuelAmount, 0, 1000)
			self:EmitSound("ambient/water/water_splash1.wav", 75, math.random(90,110), 1)
		end
	end
end

//Called when ever the device is connected/diconnected from something
function ENT:OnDevicesUpdated() 

end

//Destroying it
function ENT:OnTakeDamage(damage)
	self:SetHealth(self:Health() - damage:GetDamage())
	if self:Health() <= 0 then
		self:Remove()
	end
end
