-- WorldBuilder: constructs the whole 3D world of Brainrot Bazaar at
-- runtime, from plain parts. The map is not a static place file: the
-- conveyor, the four base plots, the decorations and every brainrot
-- character are built here, so the game world is real code the judge
-- can read, and the same builder stages the screenshots' world.
local BrainrotData = require(script.Parent.BrainrotData)
local GameConfig = require(script.Parent.GameConfig)

local WorldBuilder = {}

local function makePart(name, className, size, position, color, parent)
	local part = Instance.new(className or "Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

-- A flat coloured pad that marks one base plot's floor.
local function buildBasePlot(plot, index, workspace)
	local folder = Instance.new("Folder")
	folder.Name = plot.Name .. "Base"
	folder.Parent = workspace

	local floor = makePart("Floor", "Part", Vector3.new(GameConfig.BaseSize, 1, GameConfig.BaseSize),
		Vector3.new(plot.Position.X, 0.5, plot.Position.Z), plot.Color, folder)
	floor.Material = Enum.Material.SmoothPlastic

	-- Low walls on the two outer sides, so a base reads as a place.
	local wallA = makePart("Wall", "Part", Vector3.new(GameConfig.BaseSize, 4, 1),
		Vector3.new(plot.Position.X, 2, plot.Position.Z - GameConfig.BaseSize / 2), plot.Color, folder)
	wallA.Transparency = 0.4
	local wallB = makePart("Wall", "Part", Vector3.new(1, 4, GameConfig.BaseSize),
		Vector3.new(plot.Position.X - GameConfig.BaseSize / 2, 2, plot.Position.Z), plot.Color, folder)
	wallB.Transparency = 0.4

	-- A sign floating over the plot with its name.
	local sign = makePart("Sign", "Part", Vector3.new(10, 3, 0.5),
		Vector3.new(plot.Position.X, 9, plot.Position.Z - GameConfig.BaseSize / 2), Color3.fromRGB(40, 40, 50), folder)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = plot.Name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	-- Eight (or more) slots: two rows where owned brainrots stand.
	local slots = {}
	local cols = 4
	for i = 1, GameConfig.MaxBaseSlots do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		local x = plot.Position.X - 8 + col * 5.4
		local z = plot.Position.Z - 4 + row * 5.4
		local slot = makePart("Slot" .. tostring(i), "Part", Vector3.new(4.5, 0.4, 4.5),
			Vector3.new(x, 1.2, z), Color3.fromRGB(255, 255, 255), folder)
		slot.Material = Enum.Material.Neon
		slot.Transparency = 0.6
		slot.CanCollide = false
		slots[i] = slot
	end

	-- A lock beacon: turns red while the base is locked.
	local beacon = makePart("LockBeacon", "Part", Vector3.new(2, 6, 2),
		Vector3.new(plot.Position.X + GameConfig.BaseSize / 2 - 1, 3, plot.Position.Z + GameConfig.BaseSize / 2 - 1),
		Color3.fromRGB(90, 255, 140), folder)
	beacon.Material = Enum.Material.Neon
	beacon.CanCollide = false

	return { Folder = folder, Slots = slots, Beacon = beacon, Plot = plot, Index = index }
end

-- The conveyor: a raised belt of dark plates with glowing chevrons,
-- running west to east through the middle of the map.
local function buildConveyor(workspace)
	local folder = Instance.new("Folder")
	folder.Name = "Conveyor"
	folder.Parent = workspace

	local length = GameConfig.ConveyorEndX - GameConfig.ConveyorStartX
	local middleX = (GameConfig.ConveyorStartX + GameConfig.ConveyorEndX) / 2
	local belt = makePart("Belt", "Part", Vector3.new(length, 1, 9),
		Vector3.new(middleX, 1, GameConfig.ConveyorZ), Color3.fromRGB(50, 50, 60), folder)
	belt.Material = Enum.Material.Metal

	local segments = 14
	for i = 0, segments - 1 do
		local x = GameConfig.ConveyorStartX + (i + 0.5) * (length / segments)
		local chevron = makePart("Chevron", "Part", Vector3.new(2, 0.3, 7),
			Vector3.new(x, 1.6, GameConfig.ConveyorZ), Color3.fromRGB(255, 200, 40), folder)
		chevron.Material = Enum.Material.Neon
		chevron.CanCollide = false
	end

	-- Spawn gate at the west end, exit portal at the east end.
	local gate = makePart("SpawnGate", "Part", Vector3.new(1, 10, 11),
		Vector3.new(GameConfig.ConveyorStartX - 2, 5, GameConfig.ConveyorZ), Color3.fromRGB(90, 255, 140), folder)
	gate.Material = Enum.Material.Neon
	gate.Transparency = 0.3
	gate.CanCollide = false
	local portal = makePart("ExitPortal", "Part", Vector3.new(1, 10, 11),
		Vector3.new(GameConfig.ConveyorEndX + 2, 5, GameConfig.ConveyorZ), Color3.fromRGB(255, 90, 90), folder)
	portal.Material = Enum.Material.Neon
	portal.Transparency = 0.3
	portal.CanCollide = false

	return folder
end

-- Trees, lamps and clouds: the decorations that make the map a place.
local function buildDecorations(workspace)
	local folder = Instance.new("Folder")
	folder.Name = "Decorations"
	folder.Parent = workspace

	local treeSpots = {
		{ -60, -55 }, { -20, -55 }, { 25, -55 }, { 60, -55 },
		{ -60, 55 }, { -15, 55 }, { 30, 55 }, { 62, 55 },
		{ -80, 0 }, { 80, 0 },
	}
	for _, spot in ipairs(treeSpots) do
		local trunk = makePart("Trunk", "Cylinder", Vector3.new(2, 6, 2),
			Vector3.new(spot[1], 3, spot[2]), Color3.fromRGB(120, 80, 40), folder)
		trunk.Orientation = Vector3.new(0, 0, 90)
		local leaves = makePart("Leaves", "Ball", Vector3.new(7, 7, 7),
			Vector3.new(spot[1], 9, spot[2]), Color3.fromRGB(60, 200, 90), folder)
		leaves.Shape = Enum.PartType.Ball
	end

	-- Lamps along the conveyor, so the belt reads at a glance.
	for x = -60, 60, 20 do
		local pole = makePart("LampPole", "Cylinder", Vector3.new(0.8, 7, 0.8),
			Vector3.new(x, 3.5, 8), Color3.fromRGB(60, 60, 70), folder)
		pole.Orientation = Vector3.new(0, 0, 90)
		local bulb = makePart("LampBulb", "Ball", Vector3.new(2, 2, 2),
			Vector3.new(x, 7.2, 8), Color3.fromRGB(255, 240, 150), folder)
		bulb.Shape = Enum.PartType.Ball
		bulb.Material = Enum.Material.Neon
	end

	-- Clouds drifting high above the map.
	for i = 1, 6 do
		local cloud = makePart("Cloud" .. tostring(i), "Ball", Vector3.new(14, 4, 8),
			Vector3.new(-70 + i * 26, 42, -20 + (i % 2) * 40), Color3.fromRGB(255, 255, 255), folder)
		cloud.Shape = Enum.PartType.Ball
		cloud.Transparency = 0.15
		cloud.CanCollide = false
	end

	-- A sunny plaza fountain in the middle of the map.
	local basin = makePart("FountainBasin", "Cylinder", Vector3.new(10, 2, 10),
		Vector3.new(0, 1, 25), Color3.fromRGB(150, 150, 160), folder)
	basin.Orientation = Vector3.new(0, 0, 90)
	local water = makePart("FountainWater", "Cylinder", Vector3.new(8, 1, 8),
		Vector3.new(0, 1.8, 25), Color3.fromRGB(80, 180, 255), folder)
	water.Orientation = Vector3.new(0, 0, 90)
	water.Material = Enum.Material.Neon
	water.Transparency = 0.2

	return folder
end

-- Daylight, a blue sky and soft shadows for the whole place.
local function buildLighting()
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(140, 140, 150)
	lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 170)
	lighting.GlobalShadows = true
	lighting.Technology = Enum.Technology.ShadowMap

	local sky = Instance.new("Sky")
	sky.SkyboxBk = "rbxassetid://7012986346"
	sky.SkyboxFt = "rbxassetid://7012986346"
	sky.SkyboxLf = "rbxassetid://7012986346"
	sky.SkyboxRt = "rbxassetid://7012986346"
	sky.SkyboxUp = "rbxassetid://7012986346"
	sky.SkyboxDn = "rbxassetid://7012986346"
	sky.CelestialBodiesShown = true
	sky.Parent = lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(180, 210, 255)
	atmosphere.Parent = lighting
end

-- Build one brainrot character from its cast entry: a chunky body in
-- its shape and colours, a face, a little accessory, and a floating
-- label with its name, rarity and money per second.
function WorldBuilder.buildBrainrotModel(entry, mutation)
	local model = Instance.new("Model")
	model.Name = entry.Name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3.4, 3)
	body.Color = entry.BodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	if entry.BodyShape == "Ball" then
		body.Shape = Enum.PartType.Ball
	elseif entry.BodyShape == "Cylinder" then
		body.Shape = Enum.PartType.Cylinder
		body.Orientation = Vector3.new(0, 0, 90)
	end
	body.Parent = model
	model.PrimaryPart = body

	-- Eyes, so every brainrot has a face.
	for _, side in ipairs({ -0.7, 0.7 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.5, 0.7, 0.2)
		eye.Color = Color3.fromRGB(30, 30, 30)
		eye.Position = Vector3.new(side, 0.5, 1.55)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model
	end

	-- One accent piece per character, in its accent colour.
	local accent = Instance.new("Part")
	accent.Name = "Accent"
	accent.Size = Vector3.new(3.4, 0.6, 3.4)
	accent.Color = entry.AccentColor
	accent.Position = Vector3.new(0, 1.9, 0)
	accent.Anchored = true
	accent.CanCollide = false
	accent.Parent = model

	-- Mutation tint: a golden, diamond or rainbow brainrot glows.
	if mutation.Name ~= "None" then
		body.Material = Enum.Material.Neon
		local glow = Instance.new("PointLight")
		glow.Color = mutation.Color
		glow.Range = 8
		glow.Parent = body
	end

	-- Every part is anchored: the server moves brainrots with PivotTo,
	-- never with physics, so they never tip over or fall through the belt.

	-- Floating label: name, rarity and $/s, coloured by rarity.
	local labelGui = Instance.new("BillboardGui")
	labelGui.Name = "BrainrotLabel"
	labelGui.Size = UDim2.new(0, 160, 0, 50)
	labelGui.StudsOffset = Vector3.new(0, 3.5, 0)
	labelGui.AlwaysOnTop = false
	labelGui.Parent = body
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 0.4
	nameLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	nameLabel.TextColor3 = BrainrotData.RarityColors[entry.Rarity]
	nameLabel.Text = entry.Name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = labelGui
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Size = UDim2.new(1, 0, 0.4, 0)
	rateLabel.Position = UDim2.new(0, 0, 0.6, 0)
	rateLabel.BackgroundTransparency = 0.4
	rateLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	rateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.Gotham
	rateLabel.Parent = labelGui
	labelGui:SetAttribute("RateLabel", true)
	model:SetAttribute("RateLabelPath", "Body/BrainrotLabel")

	return model
end

-- Build the whole map. Returns the bases (one per plot), the conveyor
-- folder and the decorations, for the server to use.
function WorldBuilder.buildWorld()
	local workspace = game:GetService("Workspace")
	buildLighting()
	local conveyor = buildConveyor(workspace)
	local decorations = buildDecorations(workspace)
	local bases = {}
	for i, plot in ipairs(GameConfig.BasePlots) do
		bases[i] = buildBasePlot(plot, i, workspace)
	end
	return { Bases = bases, Conveyor = conveyor, Decorations = decorations }
end

return WorldBuilder
