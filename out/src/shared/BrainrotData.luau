-- BrainrotData: the whole cast of Brainrot Bazaar. Every character is an
-- original invention of this game: no names, looks or lines are borrowed
-- from any existing brainrot game. Each entry describes one brainrot's
-- rarity, income, price, shape and colours, so the spawner, the shop and
-- the world builder all read the same table.
local BrainrotData = {}

BrainrotData.Rarities = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Secret",
}

-- Rarity colours, as shown on the name labels and in the shop.
BrainrotData.RarityColors = {
	Common = Color3.fromRGB(190, 190, 190),
	Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 180, 40),
	Mythic = Color3.fromRGB(255, 70, 90),
	Secret = Color3.fromRGB(60, 255, 220),
}

-- Chance a spawned brainrot rolls each rarity (weights, not percents).
BrainrotData.RarityWeights = {
	Common = 40,
	Rare = 28,
	Epic = 16,
	Legendary = 9,
	Mythic = 5,
	Secret = 2,
}

-- Mutations multiply a brainrot's income. Rolled when it spawns.
BrainrotData.Mutations = {
	{ Name = "None", Multiplier = 1, Chance = 82, Color = Color3.fromRGB(255, 255, 255) },
	{ Name = "Golden", Multiplier = 2, Chance = 10, Color = Color3.fromRGB(255, 215, 0) },
	{ Name = "Diamond", Multiplier = 4, Chance = 6, Color = Color3.fromRGB(120, 220, 255) },
	{ Name = "Rainbow", Multiplier = 8, Chance = 2, Color = Color3.fromRGB(255, 120, 220) },
}

-- The cast. BodyShape is "Box", "Ball" or "Cylinder"; the world builder
-- turns each entry into a chunky little 3D character from plain parts.
-- Price is what a player pays on the conveyor; Rate is money per second.
BrainrotData.Cast = {
	{
		Id = "toast_knight",
		Name = "Toast Knight",
		Rarity = "Common",
		Price = 50,
		Rate = 2,
		BodyShape = "Box",
		BodyColor = Color3.fromRGB(222, 178, 110),
		AccentColor = Color3.fromRGB(160, 160, 170),
		Blurb = "A knight sworn to protect breakfast.",
	},
	{
		Id = "pickle_dj",
		Name = "DJ Pickle",
		Rarity = "Common",
		Price = 120,
		Rate = 4,
		BodyShape = "Cylinder",
		BodyColor = Color3.fromRGB(110, 200, 80),
		AccentColor = Color3.fromRGB(40, 40, 40),
		Blurb = "Drops the beat. Drops the brine.",
	},
	{
		Id = "burrito_professor",
		Name = "Burrito Professor",
		Rarity = "Rare",
		Price = 300,
		Rate = 9,
		BodyShape = "Box",
		BodyColor = Color3.fromRGB(240, 200, 130),
		AccentColor = Color3.fromRGB(90, 60, 30),
		Blurb = "Lectures on wrap theory. Nobody listens.",
	},
	{
		Id = "couch_potato_king",
		Name = "Couch Potato King",
		Rarity = "Rare",
		Price = 600,
		Rate = 15,
		BodyShape = "Ball",
		BodyColor = Color3.fromRGB(190, 140, 90),
		AccentColor = Color3.fromRGB(200, 60, 60),
		Blurb = "Rules the living room from one cushion.",
	},
	{
		Id = "traffic_cone_wizard",
		Name = "Traffic Cone Wizard",
		Rarity = "Epic",
		Price = 1400,
		Rate = 28,
		BodyShape = "Cylinder",
		BodyColor = Color3.fromRGB(255, 120, 30),
		AccentColor = Color3.fromRGB(255, 255, 255),
		Blurb = "Casts spells. Directs traffic. Same thing.",
	},
	{
		Id = "spaghetti_astronaut",
		Name = "Spaghetti Astronaut",
		Rarity = "Epic",
		Price = 2800,
		Rate = 45,
		BodyShape = "Box",
		BodyColor = Color3.fromRGB(250, 230, 180),
		AccentColor = Color3.fromRGB(180, 200, 255),
		Blurb = "One small slurp for noodle-kind.",
	},
	{
		Id = "fridge_philosopher",
		Name = "Fridge Philosopher",
		Rarity = "Legendary",
		Price = 6000,
		Rate = 80,
		BodyShape = "Box",
		BodyColor = Color3.fromRGB(220, 230, 240),
		AccentColor = Color3.fromRGB(80, 120, 200),
		Blurb = "If the light is off, are you still hungry?",
	},
	{
		Id = "disco_llama",
		Name = "Disco Llama",
		Rarity = "Legendary",
		Price = 11000,
		Rate = 130,
		BodyShape = "Box",
		BodyColor = Color3.fromRGB(255, 255, 255),
		AccentColor = Color3.fromRGB(255, 80, 200),
		Blurb = "The floor is lava. The llama is disco.",
	},
	{
		Id = "cactus_accountant",
		Name = "Cactus Accountant",
		Rarity = "Mythic",
		Price = 22000,
		Rate = 220,
		BodyShape = "Cylinder",
		BodyColor = Color3.fromRGB(60, 180, 90),
		AccentColor = Color3.fromRGB(255, 220, 120),
		Blurb = "Prickly about your deductions.",
	},
	{
		Id = "moon_cheese_goblin",
		Name = "Moon Cheese Goblin",
		Rarity = "Mythic",
		Price = 40000,
		Rate = 350,
		BodyShape = "Ball",
		BodyColor = Color3.fromRGB(240, 230, 150),
		AccentColor = Color3.fromRGB(120, 90, 160),
		Blurb = "Mined the moon. Ate the profits.",
	},
	{
		Id = "toilet_paper_dragon",
		Name = "Toilet Paper Dragon",
		Rarity = "Secret",
		Price = 90000,
		Rate = 600,
		BodyShape = "Cylinder",
		BodyColor = Color3.fromRGB(250, 250, 250),
		AccentColor = Color3.fromRGB(255, 90, 90),
		Blurb = "Hoards every roll. Breathes softness.",
	},
	{
		Id = "grandma_wifi_router",
		Name = "Grandma's WiFi Router",
		Rarity = "Secret",
		Price = 200000,
		Rate = 1000,
		BodyShape = "Box",
		BodyColor = Color3.fromRGB(60, 60, 70),
		AccentColor = Color3.fromRGB(90, 255, 150),
		Blurb = "Five bars. Zero patience. Infinite love.",
	},
}

-- Look a brainrot up by its id.
function BrainrotData.getById(id)
	for _, entry in ipairs(BrainrotData.Cast) do
		if entry.Id == id then
			return entry
		end
	end
	return nil
end

-- All brainrots of one rarity, in cast order.
function BrainrotData.getByRarity(rarity)
	local out = {}
	for _, entry in ipairs(BrainrotData.Cast) do
		if entry.Rarity == rarity then
			table.insert(out, entry)
		end
	end
	return out
end

-- Roll one rarity from the weights above.
function BrainrotData.rollRarity()
	local total = 0
	for _, rarity in ipairs(BrainrotData.Rarities) do
		total = total + BrainrotData.RarityWeights[rarity]
	end
	local roll = math.random(1, total)
	local running = 0
	for _, rarity in ipairs(BrainrotData.Rarities) do
		running = running + BrainrotData.RarityWeights[rarity]
		if roll <= running then
			return rarity
		end
	end
	return "Common"
end

-- Roll one mutation from the chances above.
function BrainrotData.rollMutation()
	local roll = math.random(1, 100)
	local running = 0
	for _, mutation in ipairs(BrainrotData.Mutations) do
		running = running + mutation.Chance
		if roll <= running then
			return mutation
		end
	end
	return BrainrotData.Mutations[1]
end

-- Roll a full spawn: a rarity, then a random character of that rarity,
-- then a mutation. Returns the cast entry and the mutation table.
function BrainrotData.rollSpawn()
	local rarity = BrainrotData.rollRarity()
	local pool = BrainrotData.getByRarity(rarity)
	local entry = pool[math.random(1, #pool)]
	return entry, BrainrotData.rollMutation()
end

return BrainrotData
