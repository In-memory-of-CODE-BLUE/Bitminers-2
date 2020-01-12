ENT.Type = "anim"

ENT.PrintName = "Bitminer 2"
ENT.Spawnable = true
ENT.Category = "Bitminers 2"

ENT.upgrades = {
	CPU = {name = "CPU Speed +256MHz", cost = {2000,4000,8000,16000,320000, 64000, 128000}, amountPerUpgrade = 0.256},
	CORES = {name = "Adds an extra core", cost = {50000, 10000, 175000}}
}

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 1, "HasPower" )
	self:NetworkVar( "Bool", 2, "IsOn")
	self:NetworkVar( "Bool", 3, "IsMining")
	self:NetworkVar( "Float", 1, "BitcoinAmount")
	self:NetworkVar( "Int", 1, "CPUUpgrade")
	self:NetworkVar( "Int", 2, "CoreUpgrade")  
	self:NetworkVar( "Float", 3, "ClockSpeed")
	self:NetworkVar( "Int", 4, "CoreCount")
	//A string table of all the updates that have been purchased.
	self:NetworkVar( "String", 1, "Updates") 
	self:NetworkVar("Entity", 0, "owning_ent")
end

