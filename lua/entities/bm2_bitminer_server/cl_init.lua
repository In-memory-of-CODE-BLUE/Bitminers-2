include("shared.lua")

function ENT:Initialize()
	self.fanAng = 0
end

//Animate fans
function ENT:Think()
	if LocalPlayer():GetPos():Distance(self:GetPos()) < 500 then
		if self:GetShouldAnimate() then
			self.fanAng = self.fanAng + (FrameTime() * 400)
			for i = 0 , self:GetBoneCount() - 1 do
				if string.match( self:GetBoneName(i), "fan" ) ~= nil then
					self:ManipulateBoneAngles(i,Angle(self.fanAng,0,0))
				end
			end
		end 
	end
end

function ENT:Draw()
	self:DrawModel()
end