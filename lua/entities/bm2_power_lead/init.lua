AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/bitminers2/bitminer_plug_2.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	local physics = self:GetPhysicsObject()
	if (physics:IsValid()) then
		physics:Wake()
	end

	self:SetHealth(25)

	self.plug = ents.Create("bm2_plug_1")
	self.plug.parent = self
	self.plug:SetPos(self:GetPos() + Vector(0,0,20)) //Spawn 20 unites higher than the extention
	
	self.pluggedIn = false
	self.plug:Spawn()
	self.rope = constraint.Rope(self, self.plug, 0, 0, Vector(0,0,0), Vector(0,0,0), 200, 0, 0, 1, "cable/cable2", false)

end	

function ENT:OnPlugedIn(position, angle, parent)
	constraint.RemoveConstraints(self, "Rope")
	local mainParent = self.plug.connectedDevice or self.plug
	local otherPos = Vector(0,0,0)
	if self.plug.connectedDevice then
		otherPos = self.plug.connectedDevice:WorldToLocal(self.plug:GetPos())
	end
	self.rope = constraint.Rope(parent, mainParent, 0, 0, parent:WorldToLocal(position), otherPos, 200, 50, 0, 1, "cable/cable2", false)
	self.connectedDevice = parent
	self:SetAngles(angle + parent:GetAngles())
	self:SetPos(position) 
	self:SetParent(parent)
	self:SetMoveType(MOVETYPE_NONE)

	//Notifty the circit it was plugged into that it is now part of it
	BM2UpdateAllConnectedDevices(self)

end


function ENT:StartTouch(e)
	if not self.pluggedIn then
		if e.isBitminer then
			local pos, ang = e:PlugIn(self)
			if pos ~= false then
				self:OnPlugedIn(pos, ang, e)
				self.pluggedIn = true
			end
		end
	end
end

//Handles upluggin and everything it needs to do.
function ENT:UnPlug()
	if self.connectedDevice and self.pluggedIn then

		self.connectedDevice:Unplug(self)
		//Notifty the circit it was connected to that is it no longer connected to it
		BM2UpdateAllConnectedDevices(self.connectedDevice)

		self.connectedDevice = nil

		BM2UpdateAllConnectedDevices(self)

		self:SetParent()
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetPos(self:GetPos() + (self:GetAngles():Forward() *  20 ))
		self.pluggedIn = false

		//Re-attach rope
		if self.rope ~= nil and self.rope ~= NULL then
			self.rope:Remove()
		end
		if self.plug.rope ~= nil and self.plug.rope ~= NULL then
			self.plug.rope:Remove()
		end

		constraint.RemoveAll(self)

		local mainParent = self.plug.connectedDevice or self.plug
		local otherPos = Vector(0,0,0)
		if self.plug.connectedDevice then
			otherPos = self.plug.connectedDevice:WorldToLocal(self.plug:GetPos())
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
	self.plug:UnPlug()
	self:UnPlug()
	self.plug:Remove()
end

//Destroying it
function ENT:OnTakeDamage(damage)
	self:SetHealth(self:Health() - damage:GetDamage())
	if self:Health() <= 0 then
		self:Remove()
	end
end