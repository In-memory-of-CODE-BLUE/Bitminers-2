include("shared.lua")

surface.CreateFont( "BM2GeneratorFont", {
	font = "Roboto Lt", 
	extended = false,
	size = 40,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

local fuelMaterial = Material("materials/bitminers2/ui/fuel.png", "noclamp smooth")
local outputMaterial = Material("materials/bitminers2/ui/output.png", "noclamp smooth")
local warningMaterial = Material("materials/bitminers2/ui/warning.png", "noclamp smooth")

local function __round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function ENT:DrawTranslucent()
	self:DrawModel()

	if LocalPlayer():GetPos():Distance(self:GetPos()) < 350 then
		if self.cam2d3dAng == nil then
			self.cam2d3dAng = Angle(0,LocalPlayer():GetAngles().y - 90,90)
		else
			self.cam2d3dAng = LerpAngle(7 * FrameTime(),self.cam2d3dAng, Angle(0,LocalPlayer():GetAngles().y - 90,90))
		end
		--Cam 2D3D for drawing infomation
		local ang = self:GetAngles()
		local pos = self:GetPos() + Vector(0,0,40) - (ang:Forward() * 5) + (ang:Up() * 20)

		local alpha = 1 - math.Clamp((LocalPlayer():GetPos():Distance(self:GetPos()) / 350) * 1.1, 0, 1)

		cam.Start3D2D(pos, self.cam2d3dAng, 0.05)
			if not self:GetShowToMuchPowerWarning() then
				if not self:GetShowNoFuelWarning() then
					draw.RoundedBox(8,-200, -10 , 410, (70 * 2) + 10,Color(0,0,0,100 * alpha))

					surface.SetMaterial(outputMaterial)
					surface.SetDrawColor(Color(200,200,0, 255 * alpha))
					surface.DrawTexturedRect(-200 + 4, 4, 64 - 8, 64 - 8)

					surface.SetMaterial(fuelMaterial)
					surface.SetDrawColor(Color(255,165,0, 255 * alpha))
					surface.DrawTexturedRect(-200 + 4,70 + 4, 64 - 8, 64 - 8)

					//Draw power ussage bar
					draw.RoundedBox(4, -200 + 70, 4, 400 - 70, 60-8, Color(36,36,36, 255 * alpha))
					draw.RoundedBox(2, -200 + 70 + 2, 4 + 2, 400 - 70 - 4, 60-8 - 4, Color(15,15,15, 255 * alpha))
					if self:GetPowerConsumpsion() > 0 then
						draw.RoundedBox(2, -200 + 70 + 2, 4 + 2, (400 - 70 - 4) * (self:GetPowerConsumpsion()/ BM2CONFIG.GeneratorPowerOutput), 60-8 - 4, Color(200,200,0, 255 * alpha))
					end
					
					local powerLevel = __round(self:GetPowerConsumpsion(), 2)

					draw.SimpleText((powerLevel*100).."/"..(BM2CONFIG.GeneratorPowerOutput * 100).."W", "BM2GeneratorFont", 45, ((60-8-4)/2) + 6, Color(0,0,0, 255 * alpha), 1, 1)
					draw.SimpleText((powerLevel*100).."/"..(BM2CONFIG.GeneratorPowerOutput * 100).."W", "BM2GeneratorFont", 44, ((60-8-4)/2) + 5, Color(255,255,255, 255 * alpha), 1, 1)

					draw.RoundedBox(4, -200 + 70, 4 + 70, 400 - 70, 60-8, Color(36,36,36,  255 * alpha))
					draw.RoundedBox(2, -200 + 70 + 2, 4 + 2 + 70, 400 - 70 - 4, 60-8 - 4, Color(15,15,15, 255 * alpha))
					draw.RoundedBox(2, -200 + 70 + 2, 4 + 2 + 70, (400 - 70 - 4) * (self:GetFuelLevel()/ 1000), 60-8 - 4, Color(255,165,0,  255 * alpha))
					draw.SimpleText(self:GetFuelLevel().."/1000 L", "BM2GeneratorFont", 45, ((60-8-4)/2) + 6 + 70, Color(0,0,0, 255 * alpha), 1, 1)
					draw.SimpleText(self:GetFuelLevel().."/1000 L", "BM2GeneratorFont", 44, ((60-8-4)/2) + 5 + 70, Color(255,255,255, 255 * alpha), 1, 1)
				else
					surface.SetMaterial(warningMaterial)
					surface.SetDrawColor(Color(255,80,80, 255))
					surface.DrawTexturedRect(-80, -20, 160, 160)

					draw.SimpleText("Out of fuel!", "BM2GeneratorFont", 0, 170, Color(0,0,0, 255), 1, 1)
					draw.SimpleText("Out of fuel!", "BM2GeneratorFont", -1, 170 - 1, Color(255,255,255, 255), 1, 1)

					draw.SimpleText("Please purchase some fuel.", "BM2GeneratorFont", 0, 170 + 35, Color(0,0,0, 255), 1, 1)
					draw.SimpleText("Please purchase some fuel.", "BM2GeneratorFont", -1, 170 - 1 + 35, Color(255,255,255, 255), 1, 1)

				end
			else
				surface.SetMaterial(warningMaterial)
				surface.SetDrawColor(Color(255,255,255, 255))
				surface.DrawTexturedRect(-80, -20, 160, 160)

				draw.SimpleText("You are using to much power!", "BM2GeneratorFont", 0, 170, Color(0,0,0, 255), 1, 1)
				draw.SimpleText("You are using to much power!", "BM2GeneratorFont", -1, 170 - 1, Color(255,255,255, 255), 1, 1)

				draw.SimpleText("Please disconnect some devices or find anouther power source.", "BM2GeneratorFont", 0, 170 + 35, Color(0,0,0, 255), 1, 1)
				draw.SimpleText("Please disconnect some devices or find anouther power source.", "BM2GeneratorFont", -1, 170 - 1 + 35, Color(255,255,255, 255), 1, 1)

			end
		cam.End3D2D()
	end
end