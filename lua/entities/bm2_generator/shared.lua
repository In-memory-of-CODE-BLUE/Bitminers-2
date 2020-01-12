ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Generator"
ENT.Spawnable = true
ENT.Category = "Bitminers 2"

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 1, "IsOn" )
	self:NetworkVar( "Bool", 2, "ShowToMuchPowerWarning")
	self:NetworkVar( "Bool", 3, "ShowNoFuelWarning")
	self:NetworkVar( "Int", 1, "FuelLevel")
	self:NetworkVar( "Float", 2, "PowerConsumpsion")
end