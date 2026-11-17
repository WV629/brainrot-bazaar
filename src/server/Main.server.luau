-- Main server: the whole game loop of Brainrot Bazaar. One script owns
-- the state (every player's money, brainrots, lock and rebirth) and
-- drives everything else: spawning brainrots onto the conveyor, paying
-- income every second, buying, stealing, slapping, the NPC rival thief
-- and the tsunami wave. The client only shows the state and asks for
-- actions; the server decides them all.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Economy = require(ReplicatedStorage.Shared.Economy)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local WaveController = require(ReplicatedStorage.Shared.WaveController)
local WorldBuilder = require(ReplicatedStorage.Shared.WorldBuilder)
local RivalThief = require(script.Parent.RivalThief)

-- The world, built once at startup: four base plots, the conveyor,
-- the decorations, the sky and the light.
local world = WorldBuilder.buildWorld()
local bases = world.Bases

-- Remotes: one folder, one RemoteEvent per action, so the client can
-- never call a server function that is not on this list.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local MoneyUpdate = Instance.new("RemoteEvent")
MoneyUpdate.Name = "MoneyUpdate"
MoneyUpdate.Parent = remotes

local Notify = Instance.new("RemoteEvent")
Notify.Name = "Notify"
Notify.Parent = remotes

local WaveAlert = Instance.new("RemoteEvent")
WaveAlert.Name = "WaveAlert"
WaveAlert.Parent = remotes

local BuySlotRequest = Instance.new("RemoteEvent")
BuySlotRequest.Name = "BuySlotRequest"
BuySlotRequest.Parent = remotes

local RebirthRequest = Instance.new("RemoteEvent")
RebirthRequest.Name = "RebirthRequest"
RebirthRequest.Parent = remotes

local LockRequest = Instance.new("RemoteEvent")
LockRequest.Name = "LockRequest"
LockRequest.Parent = remotes

local SlapRequest = Instance.new("RemoteEvent")
SlapRequest.Name = "SlapRequest"
SlapRequest.Parent = remotes

-- One record per player. Owned holds { Entry, Mutation, Model, Slot }.
local playerData = {}
local freePlots = { 1, 2, 3, 4 }

-- Brainrots currently walking the conveyor.
local conveyorBrainrots = {}

-- The rival thief's den sits at the north edge of the map.
local rivalHome = Vector3.new(0, 0, -58)
local rivalState = RivalThief.newState(rivalHome)
local rivalModel = RivalThief.buildModel()
rivalModel.Parent = game:GetService("Workspace")
rivalModel:PivotTo(CFrame.new(rivalState.Position))
rivalState.NextVisitAt = GameConfig.RivalVisitInterval

local lastSpawnAt = 0
local lastIncomeAt = 0
local waveWall = nil
local waveKnocked = {}

local function now()
	return os.clock()
end

local function sendNotification(player, text)
	Notify:FireClient(player, text)
end

local function sendMoneyUpdate(player)
	local data = playerData[player]
	if not data then
		return
	end
	local income = Economy.totalIncomePerSecond(data.Owned, data.Multiplier)
	MoneyUpdate:FireClient(player, data.Money, income, #data.Owned, data.Rebirths,
		math.max(0, data.LockUntil - now()), WaveController.secondsUntilWave(now()))
end

local function freeSlotIndex(data)
	for i = 1, data.Slots do
		local taken = false
		for _, item in ipairs(data.Owned) do
			if item.Slot == i then
				taken = true
				break
			end
		end
		if not taken then
			return i
		end
	end
	return nil
end

local function slotPosition(data, slotIndex)
	local base = bases[data.BaseIndex]
	return base.Slots[slotIndex].Position + Vector3.new(0, 1.9, 0)
end

local function setRateLabel(model, entry, mutation, multiplier)
	local body = model.PrimaryPart
	local gui = body:FindFirstChild("BrainrotLabel")
	if not gui then
		return
	end
	local rateLabel = gui:FindFirstChild("RateLabel")
	if rateLabel then
		rateLabel.Text = Economy.formatMoney(Economy.incomePerSecond(entry, mutation, multiplier)) .. "/s"
	end
end

-- Put a brainrot on a base slot and mark it owned by this player.
local function placeOnBase(player, entry, mutation, model)
	local data = playerData[player]
	local slot = freeSlotIndex(data)
	if not slot then
		return false
	end
	model:PivotTo(CFrame.new(slotPosition(data, slot)))
	setRateLabel(model, entry, mutation, data.Multiplier)
	table.insert(data.Owned, { Entry = entry, Mutation = mutation, Model = model, Slot = slot })
	return true
end

-- Spawn one brainrot at the west gate and let it walk the conveyor.
local function spawnConveyorBrainrot()
	if #conveyorBrainrots >= GameConfig.MaxConveyorBrainrots then
		return
	end
	local entry, mutation = BrainrotData.rollSpawn()
	local model = WorldBuilder.buildBrainrotModel(entry, mutation)
	model.Parent = game:GetService("Workspace")
	model:PivotTo(CFrame.new(GameConfig.ConveyorStartX, 3.4, GameConfig.ConveyorZ))
	setRateLabel(model, entry, mutation, 1)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy"
	prompt.ObjectText = entry.Name .. " - " .. Economy.formatMoney(entry.Price)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	local record = { Entry = entry, Mutation = mutation, Model = model, X = GameConfig.ConveyorStartX, Prompt = prompt }
	table.insert(conveyorBrainrots, record)

	prompt.Triggered:Connect(function(player)
		buyBrainrot(player, record)
	end)
end

-- Buy the brainrot off the conveyor: pay, then it walks to your base.
function buyBrainrot(player, record)
	local data = playerData[player]
	if not data then
		return
	end
	if not record.Model.Parent then
		return
	end
	if data.Money < record.Entry.Price then
		sendNotification(player, "Not enough money for " .. record.Entry.Name .. "!")
		return
	end
	if freeSlotIndex(data) == nil then
		sendNotification(player, "Your base is full! Buy more slots.")
		return
	end
	for i, other in ipairs(conveyorBrainrots) do
		if other == record then
			table.remove(conveyorBrainrots, i)
			break
		end
	end
	data.Money = data.Money - record.Entry.Price
	record.Prompt:Destroy()

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 12
	click.Parent = record.Model.PrimaryPart
	click.MouseClick:Connect(function(clickingPlayer)
		trySteal(clickingPlayer, record, player)
	end)

	placeOnBase(player, record.Entry, record.Mutation, record.Model)
	sendNotification(player, "You bought " .. record.Entry.Name .. " for " .. Economy.formatMoney(record.Entry.Price) .. "!")
	sendMoneyUpdate(player)
end

-- Steal a brainrot off somebody else's base: grab it and carry it
-- home. A locked base cannot be stolen from, and you carry one at a time.
function trySteal(thief, record, owner)
	local thiefData = playerData[thief]
	local ownerData = playerData[owner]
	if not thiefData or not ownerData or thief == owner then
		return
	end
	if thiefData.Carrying then
		sendNotification(thief, "You are already carrying a brainrot!")
		return
	end
	if ownerData.LockUntil > now() then
		sendNotification(thief, owner.Name .. "'s base is locked!")
		return
	end
	for i, item in ipairs(ownerData.Owned) do
		if item.Model == record.Model then
			table.remove(ownerData.Owned, i)
			break
		end
	end
	thiefData.Carrying = { Entry = record.Entry, Mutation = record.Mutation, Model = record.Model, Owner = owner }
	local character = thief.Character
	if character and character:FindFirstChild("Humanoid") then
		character.Humanoid.WalkSpeed = GameConfig.CarryWalkSpeed
	end
	sendNotification(thief, "You stole " .. record.Entry.Name .. "! Run home!")
	sendNotification(owner, thief.Name .. " stole your " .. record.Entry.Name .. "!")
	sendMoneyUpdate(owner)
end

-- Drop what a player is carrying: it returns to its rightful owner.
local function dropCarried(player)
	local data = playerData[player]
	if not data or not data.Carrying then
		return
	end
	local carried = data.Carrying
	data.Carrying = nil
	local character = player.Character
	if character and character:FindFirstChild("Humanoid") then
		character.Humanoid.WalkSpeed = GameConfig.NormalWalkSpeed
	end
	local ownerData = playerData[carried.Owner]
	if ownerData and carried.Owner.Parent then
		if freeSlotIndex(ownerData) then
			placeOnBase(carried.Owner, carried.Entry, carried.Mutation, carried.Model)
			sendNotification(carried.Owner, "Your " .. carried.Entry.Name .. " was returned!")
			sendMoneyUpdate(carried.Owner)
			return
		end
	end
	carried.Model:Destroy()
end

-- A carrying player who reaches their own base keeps the steal.
local function depositCarried(player)
	local data = playerData[player]
	if not data or not data.Carrying then
		return
	end
	local base = bases[data.BaseIndex]
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	local position = character.HumanoidRootPart.Position
	if not WaveController.isInsideBase(position, base.Plot.Position) then
		return
	end
	local carried = data.Carrying
	data.Carrying = nil
	if character:FindFirstChild("Humanoid") then
		character.Humanoid.WalkSpeed = GameConfig.NormalWalkSpeed
	end
	if placeOnBase(player, carried.Entry, carried.Mutation, carried.Model) then
		sendNotification(player, "Stolen " .. carried.Entry.Name .. " is yours now!")
		sendMoneyUpdate(player)
	else
		sendNotification(player, "Your base is full! The stolen brainrot got away.")
		carried.Model:Destroy()
	end
end

-- Slap: knock the rival (or a thief carrying your brainrot) back.
local function onSlap(player)
	local data = playerData[player]
	if not data then
		return
	end
	if data.LastSlap and now() - data.LastSlap < GameConfig.SlapCooldown then
		return
	end
	data.LastSlap = now()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	local myPosition = character.HumanoidRootPart.Position

	-- Slap the Baron if he is close: he drops his loot and freezes.
	if (rivalState.Position - myPosition).Magnitude <= GameConfig.SlapRange then
		local dropped = RivalThief.stun(rivalState, now(), GameConfig.SlapStun)
		if dropped then
			local ownerData = playerData[dropped.Owner]
			if ownerData then
				placeOnBase(dropped.Owner, dropped.Entry, dropped.Mutation, dropped.Model)
				sendNotification(dropped.Owner, "You slapped the Baron! Your " .. dropped.Entry.Name .. " is back!")
			end
		end
		sendNotification(player, "SLAP! The Baron is stunned!")
		return
	end

	-- Slap a player who is carrying one of your brainrots.
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherData = playerData[other]
			local otherCharacter = other.Character
			if otherData and otherData.Carrying and otherData.Carrying.Owner == player
				and otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart") then
				local distance = (otherCharacter.HumanoidRootPart.Position - myPosition).Magnitude
				if distance <= GameConfig.SlapRange then
					dropCarried(other)
					sendNotification(player, "SLAP! You knocked your brainrot loose!")
					return
				end
			end
		end
	end
end

-- Lock your base: no stealing from it until the lock runs out.
local function onLock(player)
	local data = playerData[player]
	if not data then
		return
	end
	if data.LockUntil > now() then
		sendNotification(player, "Your base is already locked!")
		return
	end
	if data.LockCooldownUntil and now() < data.LockCooldownUntil then
		sendNotification(player, "Lock is recharging. Wait a little!")
		return
	end
	data.LockUntil = now() + GameConfig.LockDuration
	data.LockCooldownUntil = data.LockUntil + GameConfig.LockCooldown
	sendNotification(player, "Base locked for " .. tostring(GameConfig.LockDuration) .. " seconds!")
end

-- Rebirth: trade everything for a permanent income multiplier.
local function onRebirth(player)
	local data = playerData[player]
	if not data then
		return
	end
	local cost = Economy.rebirthCost(data.Rebirths)
	if data.Money < cost then
		sendNotification(player, "Rebirth costs " .. Economy.formatMoney(cost) .. ". Keep earning!")
		return
	end
	for _, item in ipairs(data.Owned) do
		item.Model:Destroy()
	end
	data.Owned = {}
	dropCarried(player)
	data.Money = GameConfig.StartingMoney
	data.Rebirths = data.Rebirths + 1
	data.Multiplier = Economy.rebirthMultiplier(data.Rebirths)
	sendNotification(player, "REBIRTH! Your income is now x" .. tostring(data.Multiplier) .. " forever!")
	sendMoneyUpdate(player)
end

-- Buy one more base slot.
local function onBuySlot(player)
	local data = playerData[player]
	if not data then
		return
	end
	if data.Slots >= GameConfig.MaxBaseSlots then
		sendNotification(player, "Your base already has every slot!")
		return
	end
	local cost = Economy.slotCost(data.Slots - GameConfig.BaseSlots)
	if data.Money < cost then
		sendNotification(player, "A new slot costs " .. Economy.formatMoney(cost) .. ".")
		return
	end
	data.Money = data.Money - cost
	data.Slots = data.Slots + 1
	sendNotification(player, "New base slot! You now have " .. tostring(data.Slots) .. ".")
	sendMoneyUpdate(player)
end

SlapRequest.OnServerEvent:Connect(onSlap)
LockRequest.OnServerEvent:Connect(onLock)
RebirthRequest.OnServerEvent:Connect(onRebirth)
BuySlotRequest.OnServerEvent:Connect(onBuySlot)

-- A new player joins: give them a base plot, starting money and a
-- character, plus the classic leaderstats for money and rebirths.
local function onPlayerAdded(player)
	local plotIndex = table.remove(freePlots, 1)
	if not plotIndex then
		player:Kick("Brainrot Bazaar is full (4 players). Try again soon!")
		return
	end
	local data = {
		Money = GameConfig.StartingMoney,
		Owned = {},
		Rebirths = 0,
		Multiplier = 1,
		Slots = GameConfig.BaseSlots,
		BaseIndex = plotIndex,
		LockUntil = 0,
		LockCooldownUntil = 0,
		LastSlap = 0,
		Carrying = nil,
	}
	playerData[player] = data

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local moneyValue = Instance.new("IntValue")
	moneyValue.Name = "Money"
	moneyValue.Value = data.Money
	moneyValue.Parent = leaderstats
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats
	data.MoneyValue = moneyValue
	data.RebirthValue = rebirthValue

	player:LoadCharacter()
	sendNotification(player, "Welcome to Brainrot Bazaar! Buy brainrots off the conveyor!")
	sendMoneyUpdate(player)
end

local function onPlayerRemoving(player)
	local data = playerData[player]
	if not data then
		return
	end
	dropCarried(player)
	for _, item in ipairs(data.Owned) do
		item.Model:Destroy()
	end
	table.insert(freePlots, data.BaseIndex)
	playerData[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Pay every player's income, once a second.
local function payIncome()
	for player, data in pairs(playerData) do
		local income = Economy.totalIncomePerSecond(data.Owned, data.Multiplier)
		data.Money = data.Money + income
		if data.MoneyValue then
			data.MoneyValue.Value = math.floor(data.Money)
		end
		if data.RebirthValue then
			data.RebirthValue.Value = data.Rebirths
		end
		sendMoneyUpdate(player)
	end
end

-- The tsunami: warn, then sweep the wall across the map. Anyone
-- caught outside their own base is knocked back to spawn and drops
-- whatever they were carrying.
local function startWave()
	WaveController.beginSweep(now())
	waveWall = WaveController.buildWaveWall(game:GetService("Workspace"))
	waveKnocked = {}
	WaveAlert:FireAllClients("wave", GameConfig.WaveSweepSeconds)
	local goal = CFrame.new(GameConfig.ConveyorEndX + 20, 15, 0)
	local tween = TweenService:Create(waveWall, TweenInfo.new(GameConfig.WaveSweepSeconds, Enum.EasingStyle.Linear),
		{ CFrame = goal })
	tween:Play()
	tween.Completed:Connect(function()
		if waveWall then
			waveWall:Destroy()
			waveWall = nil
		end
		WaveController.endSweep()
	end)
end

local function sweepWave(dt)
	if not waveWall then
		return
	end
	local wallX = waveWall.Position.X
	for player, data in pairs(playerData) do
		if not waveKnocked[player] then
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local position = character.HumanoidRootPart.Position
				local base = bases[data.BaseIndex]
				if wallX >= position.X and not WaveController.isInsideBase(position, base.Plot.Position) then
					waveKnocked[player] = true
					dropCarried(player)
					character:PivotTo(CFrame.new(0, 6, 20))
					sendNotification(player, "The tsunami caught you! Run home next time!")
				end
			end
		end
	end
end

-- The Baron's visit: pick the richest unlocked base, sneak over,
-- grab the priciest brainrot and run home with it.
local function updateRival(dt)
	local state = rivalState
	if RivalThief.isStunned(state, now()) then
		return
	end
	if state.Mode == "Idle" then
		if now() >= state.NextVisitAt then
			local players = {}
			for player, data in pairs(playerData) do
				table.insert(players, { Player = player, Data = data })
			end
			local victim = RivalThief.chooseVictim(players, bases, now())
			if victim then
				state.TargetPlayer = victim.Player
				state.Mode = "Sneak"
			else
				state.NextVisitAt = now() + 20
			end
		end
	elseif state.Mode == "Sneak" then
		local victimData = playerData[state.TargetPlayer]
		if not victimData or #victimData.Owned == 0 or victimData.LockUntil > now() then
			state.Mode = "Return"
			state.TargetPlayer = nil
		else
			local base = bases[victimData.BaseIndex]
			local goal = Vector3.new(base.Plot.Position.X, 3, base.Plot.Position.Z)
			if RivalThief.walkTowards(state, goal, dt) then
				local best = nil
				local bestPrice = 0
				for _, item in ipairs(victimData.Owned) do
					if item.Entry.Price > bestPrice then
						bestPrice = item.Entry.Price
						best = item
					end
				end
				if best then
					for i, item in ipairs(victimData.Owned) do
						if item == best then
							table.remove(victimData.Owned, i)
							break
						end
					end
					state.Carrying = { Entry = best.Entry, Mutation = best.Mutation, Model = best.Model, Owner = state.TargetPlayer }
					sendNotification(state.TargetPlayer, "The Baron stole your " .. best.Entry.Name .. "! Slap him!")
					state.Mode = "Escape"
				else
					state.Mode = "Return"
				end
			end
		end
	elseif state.Mode == "Escape" then
		if state.Carrying then
			state.Carrying.Model:PivotTo(CFrame.new(state.Position + Vector3.new(0, 5, 0)))
		end
		local goal = Vector3.new(rivalHome.X, 3, rivalHome.Z)
		if RivalThief.walkTowards(state, goal, dt) then
			if state.Carrying then
				state.Carrying.Model:Destroy()
				sendNotification(state.TargetPlayer, "The Baron got away with your " .. state.Carrying.Entry.Name .. "!")
				state.Carrying = nil
			end
			state.Mode = "Idle"
			state.NextVisitAt = now() + GameConfig.RivalVisitInterval
			state.TargetPlayer = nil
		end
	elseif state.Mode == "Return" then
		local goal = Vector3.new(rivalHome.X, 3, rivalHome.Z)
		if RivalThief.walkTowards(state, goal, dt) then
			state.Mode = "Idle"
			state.NextVisitAt = now() + GameConfig.RivalVisitInterval
			state.TargetPlayer = nil
		end
	end
	rivalModel:PivotTo(CFrame.new(state.Position))
end

-- The heartbeat: move the conveyor, pay income, run the wave clock
-- and the rival, and keep the lock beacons honest.
WaveController.start(now())
RunService.Heartbeat:Connect(function(dt)
	local t = now()

	if t - lastSpawnAt >= GameConfig.SpawnInterval then
		lastSpawnAt = t
		spawnConveyorBrainrot()
	end

	if t - lastIncomeAt >= 1 then
		lastIncomeAt = t
		payIncome()
	end

	for i = #conveyorBrainrots, 1, -1 do
		local record = conveyorBrainrots[i]
		record.X = record.X + GameConfig.ConveyorSpeed * dt
		if record.X >= GameConfig.DespawnX then
			record.Model:Destroy()
			table.remove(conveyorBrainrots, i)
		else
			record.Model:PivotTo(CFrame.new(record.X, 3.4, GameConfig.ConveyorZ))
		end
	end

	for player, data in pairs(playerData) do
		local base = bases[data.BaseIndex]
		base.Beacon.Color = data.LockUntil > t and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(90, 255, 140)
		if data.Carrying then
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				data.Carrying.Model:PivotTo(CFrame.new(character.HumanoidRootPart.Position + Vector3.new(0, 5, 0)))
			end
			depositCarried(player)
		end
	end

	if WaveController.warningDue(t) then
		WaveAlert:FireAllClients("warning", GameConfig.WaveWarningSeconds)
	end
	if WaveController.waveDue(t) then
		startWave()
	end
	sweepWave(dt)

	updateRival(dt)
end)
