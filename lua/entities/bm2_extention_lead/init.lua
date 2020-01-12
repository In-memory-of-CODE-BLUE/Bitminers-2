AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/bitminers2/bitminer_plug_3.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	local physics = self:GetPhysicsObject()
	if (physics:IsValid()) then
		physics:Wake()
	end

	self:SetHealth(25)

	self.plug = ents.Create("bm2_plug_1")
	self.plug:SetPos(self:GetPos() + Vector(0,0,20)) //Spawn 20 unites higher than the extention
	self.plug.parent = self
	self.plug:Spawn()
	self.plug.rope = constraint.Rope(self, self.plug, 0, 0, Vector(0,0,0), Vector(0,0,0), 200, 0, 0, 1, "cable/cable2", false)

	//This is the entity that we are "plugged" into. Will be nil if not pluged into any
	self.connectedEntity = nil

	//This is a table of socket infomation such as socket position, angle, and if something is plugged in or not
	self.sockets = {
		[1] = {
			position = Vector(2.5,2.6,3),
			angle = Angle(0,0,-90),
			pluggedInEntity = nil
		},
		[2] = {
			position = Vector(2.5,2.6,10),
			angle = Angle(0,0,-90),
			pluggedInEntity = nil 
		},
		[3] = {
			position = Vector(2.5,2.6,16.6),
			angle = Angle(0,0,-90),
			pluggedInEntity = nil 
		},
		[4] = {
			position = Vector(2.5,2.6,16.8 + 6),
			angle = Angle(0,0,-90),
			pluggedInEntity = nil 
		}
	}
end	

//Attemps to "plug in" anouther plug into ourself, this will return false if it failes and pos, ang if it succeeds
function ENT:PlugIn(ent)
	//We dont want to plug something in that does not fit ;D
	if ent:GetClass() ~= "bm2_plug_1" then return false end 

	//Dont plug into our selfs silly
	if ent.parent == self then return false end

	//Find empty socket
	local emptySocket = -1
	for i = 1 , 4 do
		if self.sockets[5 - i].pluggedInEntity == nil then
			emptySocket = 5 - i
			break
		end
	end

	//Debug
	BM2UpdateAllConnectedDevices(self)

	//We found a slot
	if emptySocket ~= -1 then

		//Now we need to be sure that there is not loop in the circuit so we dont create a loop

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

//Used to disconnect the plug from the entity its pluged into (this extention lead.)
function ENT:Unplug(plug)
	for i = 1 , 4 do
		if self.sockets[i].pluggedInEntity == plug then
			self.sockets[i].pluggedInEntity = nil //unplug
		end
	end
end

function ENT:OnRemove()
	self.plug:UnPlug()
	for k ,v in pairs(self.sockets) do
		if v.pluggedInEntity ~= nil then
			v.pluggedInEntity:UnPlug()
		end
	end
	self.plug:Remove()
end

//Destroying it
function ENT:OnTakeDamage(damage)
	self:SetHealth(self:Health() - damage:GetDamage())
	if self:Health() <= 0 then
		self:Remove()
	end
end
