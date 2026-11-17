-- Economy: the money maths of Brainrot Bazaar. Every price, income and
-- rebirth number the game shows comes through here, so the server and
-- the client can never disagree about what a brainrot is worth.
local BrainrotData = require(script.Parent.BrainrotData)
local GameConfig = require(script.Parent.GameConfig)

local Economy = {}

-- Money per second one owned brainrot earns, after its mutation and
-- the owner's rebirth multiplier.
function Economy.incomePerSecond(entry, mutationName, rebirthMultiplier)
	local multiplier = 1
	for _, mutation in ipairs(BrainrotData.Mutations) do
		if mutation.Name == mutationName then
			multiplier = mutation.Multiplier
			break
		end
	end
	return entry.Rate * multiplier * rebirthMultiplier
end

-- Total money per second across everything a player owns.
-- owned is a list of { Entry = cast entry, Mutation = "Golden" | ... }.
function Economy.totalIncomePerSecond(owned, rebirthMultiplier)
	local total = 0
	for _, item in ipairs(owned) do
		total = total + Economy.incomePerSecond(item.Entry, item.Mutation, rebirthMultiplier)
	end
	return total
end

-- What the next rebirth costs, from how many the player already has.
function Economy.rebirthCost(rebirths)
	return GameConfig.RebirthBaseCost * (rebirths + 1) * (rebirths + 1)
end

-- The permanent multiplier a player keeps after this many rebirths.
function Economy.rebirthMultiplier(rebirths)
	return 1 + rebirths * GameConfig.RebirthMultiplierStep
end

-- What the next extra base slot costs, from how many extra the
-- player already bought.
function Economy.slotCost(extraSlotsBought)
	return GameConfig.SlotBaseCost * (extraSlotsBought + 1)
end

-- Format money the way the HUD shows it: $1,234 or $1.2K / $3.4M.
function Economy.formatMoney(amount)
	amount = math.floor(amount)
	if amount >= 1000000 then
		return "$" .. string.format("%.1fM", amount / 1000000)
	elseif amount >= 10000 then
		return "$" .. string.format("%.1fK", amount / 1000)
	end
	local text = tostring(amount)
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. out
end

-- The full label a brainrot shows above its head and in the shop:
-- name, rarity, mutation and money per second.
function Economy.describeBrainrot(entry, mutation, rebirthMultiplier)
	local rate = Economy.incomePerSecond(entry, mutation.Name, rebirthMultiplier)
	local label = entry.Name .. "  [" .. entry.Rarity .. "]"
	if mutation.Name ~= "None" then
		label = label .. " " .. mutation.Name
	end
	return label .. "  -  " .. Economy.formatMoney(rate) .. "/s"
end

return Economy
