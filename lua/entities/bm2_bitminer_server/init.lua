AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/bitminers2/bitminer_2.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	local physics = self:GetPhysicsObject()
	if (physics:IsValid()) then
		physics:Wake()
	end

	self:SetHealth(50)

	self.inserted = false
end	

function ENT:OnRemove()
	print("check 1")
	if self.parentServer ~= nil then
			print("check 2")
		if self.beenPlacedIntoRack then
				print("check 3")
			self.parentServer:RemoveServer(self.index) 
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
