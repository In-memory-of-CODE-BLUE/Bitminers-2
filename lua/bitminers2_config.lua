-- DONT TOUCH OR YOU WILL MESS UP API

local BitcoinVal = nil
-- CHANGE THIS TO CURRENCY SYMBOL (I.E USD, EUR)
local CUR = USD

http.Fetch("https://blockchain.info/ticker?currency=USD&value=1"
	function( body, len, headers, code )
		-- The first argument is the HTML we asked for.
		
		local response = util.JSONToTable(body);
		local BitcoinVal = !response.CUR.15m.last
		
	end,
	function( error )
		print("Well... SHIT! Something went seriously wrong!")
	end
)




BM2CONFIG = {}

--Setting this to false will disable the generator from making sound.
BM2CONFIG.GeneratorsProduceSound = true

--Dollas a bitcoins sells for. Dont make this too large or it will be too easy to make money
BM2CONFIG.BitcoinValue = B

--This is a value that when raising or lowering will effect the speed of all bitminers.
--This is a balanced number and you should only change it if you know you need to. Small increments make big differences
BM2CONFIG.BaseSpeed = 0.005

--The higher this number, the faster the generator will loose fuel.
--You can use this to balance out more so they need to buy fuel more frequently
BM2CONFIG.BaseFuelDepletionRate = 0.9 --0.9 default


--This will allow you to change the default generator output level
BM2CONFIG.GeneratorPowerOutput = 10 --This should only be whole numbers, 10 == 1000W

--These should be 1 by default, changing them high will increase the default
--speed for that bitminer. Making it lower than 1 makes it slower. 
--Remember this is a multiplier so 1 = normal, 2 = twice as fast, 3 = three times as fast, 0.5 = half as slow
BM2CONFIG.BitminerSpeedMulipliers = {
	["bitminerS1"] = 1,
	["bitminerS2"] = 1,
	["bitminerRack"] = 1
}

hook.Add("loadCustomDarkRPItems", "BM2.RegisterEntities", function()
	DarkRP.createCategory{
		name = "Bitminers 2",
		categorises = "entities",
		startExpanded = true,
		color = Color(120, 120, 255, 255),
		sortOrder = 1,
	}

	DarkRP.createEntity("Bitminer S1", {
		ent = "bm2_bitminer_1",
		model = "models/bitminers2/bitminer_1.mdl",
		price = 5000,
		max = 4,
		cmd = "buybitminers1",
		category = "Bitminers 2"
	}) 

	DarkRP.createEntity("Bitminer S2", {
		ent = "bm2_bitminer_2",
		model = "models/bitminers2/bitminer_3.mdl",
		price = 25000,
		max = 4,
		cmd = "buybitminers2",
		category = "Bitminers 2"
	})

	DarkRP.createEntity("Bitminer Server", {
		ent = "bm2_bitminer_server",
		model = "models/bitminers2/bitminer_2.mdl",
		price = 50000,
		max = 16,
		cmd = "buybitminerserver",
		category = "Bitminers 2"
	})

	DarkRP.createEntity("Bitminer Rack", {
		ent = "bm2_bitminer_rack",
		model = "models/bitminers2/bitminer_rack.mdl",
		price = 100000,
		max = 2,
		cmd = "buybitminerrack",
		category = "Bitminers 2"
	})

	DarkRP.createEntity("Extension Lead", {
		ent = "bm2_extention_lead",
		model = "models/bitminers2/bitminer_plug_3.mdl",
		price = 500,
		max = 8,
		cmd = "buybitminerextension",
		category = "Bitminers 2"
	})

	DarkRP.createEntity("Power Lead", {
		ent = "bm2_power_lead",
		model = "models/bitminers2/bitminer_plug_2.mdl",
		price = 500,
		max = 10,
		cmd = "buybitminerpowerlead",
		category = "Bitminers 2"
	})

	DarkRP.createEntity("Generator", {
		ent = "bm2_generator",
		model = "models/bitminers2/generator.mdl",
		price = 6000,
		max = 3,
		cmd = "buybitminergenerator",
		category = "Bitminers 2"
	})

	DarkRP.createEntity("Fuel", {
		ent = "bm2_fuel",
		model = "models/props_junk/gascan001a.mdl",
		price = 1000,
		max = 4,
		cmd = "buybitminerfuel",
		category = "Bitminers 2"
	})

	hook.Call("BM2_DLC_loadCustomDarkRPItems")
end)
