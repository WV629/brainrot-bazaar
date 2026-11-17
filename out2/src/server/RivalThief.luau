-- RivalThief: Baron von Crumb, the NPC rival who keeps stealing tense
-- even when nobody else is online. He lives in the fourth base plot,
-- watches for an unlocked base with a brainrot worth taking, sneaks
-- over, grabs one and runs home. A slap stuns him and makes him drop
-- whatever he is carrying. The server drives him with update(dt).
local BrainrotData = require(script.Parent.BrainrotData)
local GameConfig = require(script.Parent.GameConfig)

local RivalThief = {}

-- Build the Baron's blocky little body: a purple top hat, a moustache
-- strip and a cape-coloured torso, all plain parts.
function RivalThief.buildModel()
	local model = Instance.new("Model")
	model.Name = "BaronVonCrumb"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 4, 2)
	body.Color = Color3.fromRGB(120, 60, 160)
	body.Anchored = true
	body.Parent = model
	model.PrimaryPart = body

	local hat = Instance.new("Part")
	hat.Name = "TopHat"
	hat.Size = Vector3.new(2, 2, 2)
	hat.Color = Color3.fromRGB(30, 30, 40)
	hat.Position = Vector3.new(0, 3, 0)
	hat.Anchored = true
	hat.Parent = model

	local brim = Instance.new("Part")
	brim.Name = "HatBrim"
	brim.Size = Vector3.new(3.4, 0.4, 3.4)
	brim.Color = Color3.fromRGB(30, 30, 40)
	brim.Position = Vector3.new(0, 2.1, 0)
	brim.Anchored = true
	brim.Parent = model

	local moustache = Instance.new("Part")
	moustache.Name = "Moustache"
	moustache.Size = Vector3.new(2.4, 0.5, 0.3)
	moustache.Color = Color3.fromRGB(20, 20, 20)
	moustache.Position = Vector3.new(0, 0.6, 1.1)
	moustache.Anchored = true
	moustache.Parent = model

	local labelGui = Instance.new("BillboardGui")
	labelGui.Name = "RivalLabel"
	labelGui.Size = UDim2.new(0, 180, 0, 30)
	labelGui.StudsOffset = Vector3.new(0, 4.5, 0)
	labelGui.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.TextColor3 = Color3.fromRGB(255, 90, 140)
	label.Text = "Baron von Crumb - RIVAL THIEF"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = labelGui

	return model
end

-- Fresh state for one Baron. Home is his own base plot.
function RivalThief.newState(homePosition)
	return {
		Mode = "Idle",
		Position = homePosition + Vector3.new(0, 3, 0),
		Target = nil,
		TargetPlayer = nil,
		StunUntil = 0,
		Carrying = nil,
		NextVisitAt = 0,
	}
end

-- Pick a victim: the richest unlocked base with at least one brainrot.
-- players is a list of { Player, Data, BaseIndex } the server keeps.
function RivalThief.chooseVictim(players, bases, now)
	local best = nil
	local bestValue = 0
	for _, entry in ipairs(players) do
		local data = entry.Data
		if data.LockUntil < now and #data.Owned > 0 then
			local value = 0
			for _, item in ipairs(data.Owned) do
				value = value + item.Entry.Price
			end
			if value > bestValue then
				bestValue = value
				best = entry
			end
		end
	end
	return best
end

-- Move towards a point at the Baron's walking speed. Returns true
-- once he has arrived.
function RivalThief.walkTowards(state, goal, dt)
	local current = state.Position
	local delta = goal - current
	delta = Vector3.new(delta.X, 0, delta.Z)
	local distance = delta.Magnitude
	if distance < 1.5 then
		return true
	end
	local step = math.min(distance, 9 * dt)
	state.Position = current + delta.Unit * step
	return false
end

-- Slap him: he drops whatever he carries and cannot move for a while.
function RivalThief.stun(state, now, seconds)
	state.StunUntil = now + seconds
	local dropped = state.Carrying
	state.Carrying = nil
	if state.Mode == "Escape" or state.Mode == "Steal" then
		state.Mode = "Return"
	end
	return dropped
end

function RivalThief.isStunned(state, now)
	return now < state.StunUntil
end

return RivalThief
