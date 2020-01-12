AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/bitminers2/bitminer_plug_1.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	local physics = self:GetPhysicsObject()
	if (physics:IsValid()) then
		physics:Wake()
	end

	self:SetHealth(25)

	self:SetUseType(SIMPLE_USE)

	//Are we plugged in and what are we plugged into
	self.pluggedIn = false
	self.connectedDevice = nil

end	

function ENT:Think()

end

function ENT:OnPlugedIn(position, angle, parent)
	constraint.RemoveConstraints(self, "Rope")
	local mainParent = self.parent.connectedDevice or self.parent
	local otherPos = Vector(0,0,0)
	if self.parent.connectedDevice then
		otherPos = self.parent.connectedDevice:WorldToLocal(self.parent:GetPos())
	end
	self.rope = constraint.Rope(parent, mainParent, 0, 0, parent:WorldToLocal(position), otherPos, 200, 50, 0, 1, "cable/cable2", false)

	self.connectedDevice = parent
	self:SetAngles(angle + parent:GetAngles())
	self:SetPos(position) 
	self:SetParent(parent)
	self:SetMoveType(MOVETYPE_NONE)

	//Update all devices on the ciruit of this change.
	BM2UpdateAllConnectedDevices(self)
end

function ENT:StartTouch(e)
	if not self.pluggedIn then
		if e:GetClass() == "bm2_extention_lead" or e:GetClass() == "bm2_generator" or e:GetClass() == "bm2_solarconverter" then
			local pos, ang = e:PlugIn(self)
			if pos ~= false then
				self:OnPlugedIn(pos, ang, e)
				self.pluggedIn = true
			end
		end
	end
end

//Handles unpluggin and cleaning up
function ENT:UnPlug()
	if self.connectedDevice and self.pluggedIn then
		self.connectedDevice:Unplug(self)

		BM2UpdateAllConnectedDevices(self.connectedDevice)

		//Notifty the circit it was connected to that is it no longer connected to it
		self.connectedDevice = nil

		BM2UpdateAllConnectedDevices(self)

		self:SetParent()
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetPos(self:GetPos() + (self:GetAngles():Right() *  15)  + (self:GetAngles():Up() *  -15) + Vector(0,0,10)) 
		self.pluggedIn = false

		if self.rope ~= nil and self.rope ~= NULL then
			self.rope:Remove()
		end

		constraint.RemoveAll(self)

		if self.parent.rope ~= nil and self.parent.rope ~= NULL then
			self.parent.rope:Remove()
		end

		local mainParent = self.parent.connectedDevice or self.parent
		local otherPos = Vector(0,0,0)
		if self.parent.connectedDevice then
			otherPos = self.parent.connectedDevice:WorldToLocal(self.parent:GetPos())
		end
		self.rope = constraint.Rope(mainParent, self, 0, 0, otherPos, Vector(0,0,0), 200, 50, 0, 1, "cable/cable2", false)
	
		//To prevent some bug where the plugs have no graphics
		self:GetPhysicsObject():EnableGravity(true)
	end
end

//Unplug it
function ENT:Use(act, caller)
	self:UnPlug()
end
 
function ENT:OnRemove()
	if self.parent and IsValid(self.parent) then
		self.parent:Remove()
	end
end

//Destroying it
function ENT:OnTakeDamage(damage)
	self:SetHealth(self:Health() - damage:GetDamage())
	if self:Health() <= 0 then
		self:Remove()
	end
end