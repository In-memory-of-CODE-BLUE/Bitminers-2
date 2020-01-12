include("shared.lua")

local function __round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

//Animate fan(s)
function ENT:Think()
	if LocalPlayer():GetPos():Distance(self:GetPos()) < 500 then
		if self:GetIsMining() then
			self.fanAng = self.fanAng + (FrameTime() * 400)
			for i = 0 , self:GetBoneCount() - 1 do
				if string.match( self:GetBoneName(i), "fan" ) ~= nil then
					self:ManipulateBoneAngles(i,Angle(self.fanAng,0,0))
				end
			end
		end 

		if self.prev ~= self:GetIsMining() then
			self:DestroyShadow()
			self:CreateShadow()
		end

		self.prev = self:GetIsMining()
	end
end 

//Yuck I know but its to much effort to re-write the entire system
function ENT:Initialize()
	self.fanAng = 0
	self.prev = false

	//So each bitminer can have its own set of unique instructions. This is how we will do that
	self.customInstructions = {
		status = { //Outputs usefull runtime infomation
			command = "STATUS",
			description = "Outputs usefull infomation about the current device.",
			action = function(arg1, arg2, instructionTable, ent, consoleDisplay)
				consoleDisplay.history = consoleDisplay.history.."\n------------------STATUS------------------\n"
				local firstPart = "IS MINING                                 "
				local secondPart = string.upper(tostring(ent:GetIsMining()))
				consoleDisplay.history = consoleDisplay.history..string.sub(firstPart, 1, string.len(firstPart) - string.len(secondPart))..secondPart.."\n"
				firstPart = "HAS POWER                                 "
				secondPart = string.upper(tostring(ent:GetHasPower()))
				consoleDisplay.history = consoleDisplay.history..string.sub(firstPart, 1, string.len(firstPart) - string.len(secondPart))..secondPart.."\n"
				consoleDisplay.history = consoleDisplay.history.."------------------------------------------\n\n"
			end
		},
		info = {
			command = "INFO",
			description = "Outputs sepcifications for the device such as power usage.",
			action = function(arg1, arg2, instructionTable, ent, consoleDisplay)
				consoleDisplay.history = consoleDisplay.history.."\n-------------------INFO------------------\n"
				local serverTable = util.JSONToTable(self:GetConnectedServers())
				local serverCount = 0
				for i = 1 , 8 do
					if serverTable[i] == true then
						serverCount = serverCount + 1
					end
				end
				consoleDisplay.history = consoleDisplay.history.."SERVER COUNT                            "..serverCount.."\n"
				local firstPart = "CLOCK SPEED                              "
				local secondPart = tostring(__round(ent:GetClockSpeed(), 3)).."Ghz"
				consoleDisplay.history = consoleDisplay.history..string.sub(firstPart, 1, string.len(firstPart) - string.len(secondPart))..secondPart.."\n"
				local firstPart = "CORES                                    "
				local secondPart = ent:GetCoreCount()
				consoleDisplay.history = consoleDisplay.history..string.sub(firstPart, 1, string.len(firstPart) - string.len(secondPart))..secondPart.."\n"
				consoleDisplay.history = consoleDisplay.history.."POWER REQUIREMENT          100-800W (MAX)\n"
				consoleDisplay.history = consoleDisplay.history.."MODEL NAME                  Bitminer Rack\n"
				local playerName = self:Getowning_ent()
				if playerName ~= NULL then playerName = playerName:Name() else playerName = "Unknown" end
				consoleDisplay.history = consoleDisplay.history..string.sub("OWNER                                    ", 1, string.len("OWNER                                    ") - string.len(playerName))..playerName.."\n"
				consoleDisplay.history = consoleDisplay.history.."-----------------------------------------\n\n"
			end
		},
		mining = {
			command = "MINING",
			description = "Starts or stop the miner from mining.",
			action = function(arg1, arg2, instructionTable, ent, consoleDisplay)
				if arg1 == nil then 
					consoleDisplay.history = consoleDisplay.history.."To use this command please supply one of the following arguments, 'mining start' or 'mining stop'\n"
				elseif arg1 == "start" then
					net.Start("BM2.Command.Mining")
						net.WriteEntity(ent)
						net.WriteBool(true)
					net.SendToServer()
				elseif arg1 == "stop" then
					net.Start("BM2.Command.Mining")
						net.WriteEntity(ent)
						net.WriteBool(false)
					net.SendToServer()
				else
					consoleDisplay.history = consoleDisplay.history.."The option '"..arg1.."' is not a valid option, the options are 'mining start' or 'mining stop'\n"
				end
			end
		},
		bitcoin = { //Used for selling or getting info about bitcoins
			command = "BITCOIN",
			description = "Allows you to sell or see infomation about the stored bitcoins.",
			action = function(arg1, arg2, instructionTable, ent, consoleDisplay)
				if arg1 == "info" then
					consoleDisplay.history = consoleDisplay.history.."\n-------------------BITCOIN------------------\n"
					local firstPart = "Bitcoin Amount                              "
					local secondPart = comma_value(__round(ent:GetBitcoinAmount(), 2)).."btc"
					consoleDisplay.history = consoleDisplay.history..string.sub(firstPart, 1, string.len(firstPart) - string.len(secondPart))..secondPart.."\n"
					firstPart =	"Bitcoin Value ($)                           "
					secondPart = tostring(comma_value(__round(ent:GetBitcoinAmount() * BM2CONFIG.BitcoinValue, 2)))
					consoleDisplay.history = consoleDisplay.history..string.sub(firstPart, 1, string.len(firstPart) - string.len(secondPart))..secondPart.."\n"
					consoleDisplay.history = consoleDisplay.history.."--------------------------------------------\n\n"
				elseif arg1 == "sell" then
					net.Start("BM2.Command.SellBitcoins")
						net.WriteEntity(ent)
					net.SendToServer()
					local firstPart =	"From                                        "
					local secondPart = tostring(comma_value(__round(ent:GetBitcoinAmount(), 2))).."btc"
					consoleDisplay.history = consoleDisplay.history.."\n-------------------RECEIPT------------------\n"
					consoleDisplay.history = consoleDisplay.history..string.sub(firstPart, 1, string.len(firstPart) - string.len(secondPart))..secondPart.."\n"
					firstPart =	"Convereted to                               "
					secondPart = "$"..tostring(comma_value(__round(ent:GetBitcoinAmount() * BM2CONFIG.BitcoinValue, 2)))
					consoleDisplay.history = consoleDisplay.history..string.sub(firstPart, 1, string.len(firstPart) - string.len(secondPart))..secondPart.."\n"
					consoleDisplay.history = consoleDisplay.history.."The money has been transfered to your wallet\n"
					consoleDisplay.history = consoleDisplay.history.."--------------------------------------------\n\n"
				else
					if arg1 == nil then
						consoleDisplay.history = consoleDisplay.history.."To use this command please supply one of the following arguments, 'bitcoin info' or 'bticoin sell'\n"
					else
						consoleDisplay.history = consoleDisplay.history.."The option '"..arg1.."' is not a valid option, the options are 'bitcoin info' or 'bticoin sell'\n"
					end
				end
			end
		},
		upgrade = { //Used for selling or getting info about bitcoins
			command = "UPGRADE",
			description = "Shows available upgrades and allows you to purchase them.",
			action = function(arg1, arg2, instructionTable, ent, consoleDisplay)
				if arg1 == "1" then //CPU
					net.Start("BM2.Command.Upgrade")
					net.WriteEntity(ent)
					net.WriteBool(false)
					net.SendToServer()
				elseif arg1 == "2" then //Cores
					net.Start("BM2.Command.Upgrade")
					net.WriteEntity(ent)
					net.WriteBool(true)
					net.SendToServer()
				else
					if arg1 == nil then
						consoleDisplay.history = consoleDisplay.history.."\n-------------------UPGRADES------------------\n"
						local i = 0

						if self.upgrades.CPU.cost[self:GetCPUUpgrade() + 1] ~= nil then
							i = i + 1
							firstPart =	"[1] "..self.upgrades.CPU.name.."                                                              "
							secondPart = "                                             "
							thirdtPart = "$"..comma_value(self.upgrades.CPU.cost[self:GetCPUUpgrade() + 1])
							local str = string.sub(firstPart, 0, string.len(secondPart))
							consoleDisplay.history = consoleDisplay.history..string.sub(str, 1, string.len(str) - string.len(thirdtPart))..thirdtPart.."\n"
						end

						if self.upgrades.CORES.cost[self:GetCoreUpgrade() + 1] ~= nil then
							i = i + 1 
							firstPart =	"[2] "..self.upgrades.CORES.name.."                                                              "
							secondPart = "                                             "
							thirdtPart = "$"..comma_value(self.upgrades.CORES.cost[self:GetCoreUpgrade() + 1])
							local str = string.sub(firstPart, 0, string.len(secondPart))
							consoleDisplay.history = consoleDisplay.history..string.sub(str, 1, string.len(str) - string.len(thirdtPart))..thirdtPart.."\n"
						end

						if i == 0 then
							consoleDisplay.history = consoleDisplay.history.."There are no more upgrade left for this device.\n"
						end

						consoleDisplay.history = consoleDisplay.history.."---------------------------------------------\nType 'upgrade 1' or 'upgrade 2' to select one.\n"
					else
						consoleDisplay.history = consoleDisplay.history.."The option '"..arg1.."' is not a valid option, the options are 'upgrade 1' or 'upgrade 2'\n"
					end
				end
			end
		},
		eject = {
			command = "EJECT",
			description = "Ejects a server from the rack",
			action = function(arg1, arg2, instructionTable, ent, consoleDisplay)
				if arg1 == nil then
					consoleDisplay.history = consoleDisplay.history.."To use this command please supply a server to eject, e.g 'eject 4'\n"
				elseif isnumber(tonumber(arg1)) then
					net.Start("BM2.Command.Eject")
						net.WriteEntity(ent)
						net.WriteInt(tonumber(arg1), 8)
					net.SendToServer()
				else
					consoleDisplay.history = consoleDisplay.history.."The option '"..arg1.."' is not a valid option, the options are 'eject 1-8'\n"
				end
			end
		},
		servers = { 
			command = "SERVERS",
			description = "Outputs a list of server in the rack.",
			action = function(arg1, arg2, instructionTable, ent, consoleDisplay)
				local servers = util.JSONToTable(self:GetConnectedServers())
				consoleDisplay.history = consoleDisplay.history.."\n-------------------SERVERS------------------\n"
				for i = 1 , 8 do
					local firstPart =	"#"..i.."                                          "
					secondPart = "EMPTY"
					if servers[i] then 
						secondPart = "INSERTED"
					end
					consoleDisplay.history = consoleDisplay.history..string.sub(firstPart, 1, string.len(firstPart) - string.len(secondPart))..secondPart.."\n"
				end
				consoleDisplay.history = consoleDisplay.history.."--------------------------------------------\n"
			end
		},
	}  

	--Only add if DLC is loaded
	if BITMINERS_2_EXTRAS_DLC then
		self.customInstructions.remote = {
			command = "REMOTE",
			description = "Allows you to install and uninstall and change the name of a remote access module that will allow you to access the bitminer remotely using "..BM2EXTRACONFIG.RemoteAccessCommand..". Installing it costs $"..string.Comma(BM2EXTRACONFIG.RemoteAccessPrice)..".",
			action = function(arg1, arg2, instructionTable, ent, consoleDisplay)
				if arg1 == "install" then
					net.Start("BM2.Command.RemoteInstall")
					net.WriteEntity(ent)
					net.WriteBool(true)
					net.SendToServer()
					ent.remoteName = math.random(10,99).."."..math.random(100,800).."."..math.random(10,99).."."..math.random(100,800)
				elseif arg1 == "remove" then
					net.Start("BM2.Command.RemoteInstall")
					net.WriteEntity(ent)
					net.WriteBool(false)
					net.SendToServer()
				elseif arg1 == "setname" then
					local _string = arg2 or math.random(10,99).."."..math.random(100,800).."."..math.random(10,99).."."..math.random(100,800)
					ent.remoteName = _string
					consoleDisplay.history = consoleDisplay.history.."Remote name changed to '".._string.."'\n"
				else
					if arg1 == nil then
						consoleDisplay.history = consoleDisplay.history.."---------------------------------------------\nType 'REMOTE INSTALL' to install the remote module. Installing costs $"..string.Comma(BM2EXTRACONFIG.RemoteAccessPrice).." and allows to bitminer to be remotely access using "..BM2EXTRACONFIG.RemoteAccessCommand.."\nType 'REMOTE REMOVE' to uninstall the remote module.\nType 'REMOTE SETNAME ExampleName' to change the remote name of the bitminer. The name cannot contain spaces!\n"
					else
						consoleDisplay.history = consoleDisplay.history.."The option '"..arg1.."' is not a valid option, the options are 'install', 'setname' or 'remove'\n"
					end
				end
			end
		}
	end
end

function ENT:Draw()
	self:DrawModel()
end