-- Hud: the whole interface of Brainrot Bazaar, drawn as a ScreenGui
-- over the 3D world. Money and income sit top-right (the top-left
-- corner stays clear for Roblox's own menu buttons), the wave timer
-- sits top-centre, the shop lists the cast down the left, and the
-- lock, slot and rebirth buttons sit bottom-right. The client only
-- shows state the server sends; every button asks the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Economy = require(ReplicatedStorage.Shared.Economy)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local MoneyUpdate = remotes:WaitForChild("MoneyUpdate")
local Notify = remotes:WaitForChild("Notify")
local WaveAlert = remotes:WaitForChild("WaveAlert")
local BuySlotRequest = remotes:WaitForChild("BuySlotRequest")
local RebirthRequest = remotes:WaitForChild("RebirthRequest")
local LockRequest = remotes:WaitForChild("LockRequest")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBazaarHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(name, parent, size, position, text, textColor, background)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundColor3 = background or Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.25
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = parent
	return label
end

local function makeButton(name, parent, size, position, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	return button
end

-- Money panel, top-right, clear of Roblox's top-left menu buttons.
local moneyPanel = Instance.new("Frame")
moneyPanel.Name = "MoneyPanel"
moneyPanel.Size = UDim2.new(0, 260, 0, 110)
moneyPanel.Position = UDim2.new(1, -276, 0, 16)
moneyPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
moneyPanel.BackgroundTransparency = 0.2
moneyPanel.Parent = gui

local moneyLabel = makeLabel("MoneyLabel", moneyPanel, UDim2.new(1, -16, 0, 44), UDim2.new(0, 8, 0, 8),
	"$100", Color3.fromRGB(120, 255, 140), Color3.fromRGB(20, 20, 30))
local incomeLabel = makeLabel("IncomeLabel", moneyPanel, UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 56),
	"$0/s", Color3.fromRGB(255, 255, 255), Color3.fromRGB(20, 20, 30))
local collectionLabel = makeLabel("CollectionLabel", moneyPanel, UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 84),
	"0 brainrots  -  0 rebirths", Color3.fromRGB(200, 200, 220), Color3.fromRGB(20, 20, 30))

-- Wave timer, top-centre.
local waveLabel = makeLabel("WaveLabel", gui, UDim2.new(0, 320, 0, 36), UDim2.new(0.5, -160, 0, 16),
	"Next wave: 3:00", Color3.fromRGB(120, 200, 255), Color3.fromRGB(20, 20, 30))

-- Shop panel: the whole cast, with rarity colours and $/s, down the left.
local shopPanel = Instance.new("ScrollingFrame")
shopPanel.Name = "ShopPanel"
shopPanel.Size = UDim2.new(0, 280, 0, 420)
shopPanel.Position = UDim2.new(0, 16, 0, 70)
shopPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
shopPanel.BackgroundTransparency = 0.2
shopPanel.ScrollBarThickness = 6
shopPanel.Parent = gui

local shopTitle = makeLabel("ShopTitle", shopPanel, UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 0),
	"BRAINROT SHOP", Color3.fromRGB(255, 220, 80), Color3.fromRGB(20, 20, 30))
local y = 32
for _, entry in ipairs(BrainrotData.Cast) do
	local row = Instance.new("Frame")
	row.Name = entry.Id
	row.Size = UDim2.new(1, -8, 0, 30)
	row.Position = UDim2.new(0, 4, 0, y)
	row.BackgroundTransparency = 1
	row.Parent = shopPanel
	local rarityDot = Instance.new("Frame")
	rarityDot.Size = UDim2.new(0, 12, 0, 12)
	rarityDot.Position = UDim2.new(0, 2, 0, 9)
	rarityDot.BackgroundColor3 = BrainrotData.RarityColors[entry.Rarity]
	rarityDot.Parent = row
	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.new(0.55, 0, 1, 0)
	nameText.Position = UDim2.new(0, 20, 0, 0)
	nameText.BackgroundTransparency = 1
	nameText.Text = entry.Name
	nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameText.TextScaled = true
	nameText.TextXAlignment = Enum.TextXAlignment.Left
	nameText.Font = Enum.Font.GothamBold
	nameText.Parent = row
	local priceText = Instance.new("TextLabel")
	priceText.Size = UDim2.new(0.45, -4, 1, 0)
	priceText.Position = UDim2.new(0.55, 0, 0, 0)
	priceText.BackgroundTransparency = 1
	priceText.Text = Economy.formatMoney(entry.Price) .. "  |  " .. Economy.formatMoney(entry.Rate) .. "/s"
	priceText.TextColor3 = Color3.fromRGB(120, 255, 140)
	priceText.TextScaled = true
	priceText.TextXAlignment = Enum.TextXAlignment.Right
	priceText.Font = Enum.Font.Gotham
	priceText.Parent = row
	y = y + 32
end
shopPanel.CanvasSize = UDim2.new(0, 0, 0, y)

-- Action buttons, bottom-right.
local lockButton = makeButton("LockButton", gui, UDim2.new(0, 160, 0, 44), UDim2.new(1, -176, 1, -160),
	"LOCK BASE (60s)", Color3.fromRGB(60, 120, 255))
local slotButton = makeButton("SlotButton", gui, UDim2.new(0, 160, 0, 44), UDim2.new(1, -176, 1, -108),
	"BUY BASE SLOT", Color3.fromRGB(120, 80, 200))
local rebirthButton = makeButton("RebirthButton", gui, UDim2.new(0, 160, 0, 44), UDim2.new(1, -176, 1, -56),
	"REBIRTH", Color3.fromRGB(255, 90, 90))

lockButton.MouseButton1Click:Connect(function()
	LockRequest:FireServer()
end)
slotButton.MouseButton1Click:Connect(function()
	BuySlotRequest:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	RebirthRequest:FireServer()
end)

-- Hints, bottom-centre.
local hintLabel = makeLabel("HintLabel", gui, UDim2.new(0, 520, 0, 30), UDim2.new(0.5, -260, 1, -40),
	"Press E near a brainrot to buy it  -  Press F to slap thieves  -  Click a rival brainrot to steal it",
	Color3.fromRGB(220, 220, 230), Color3.fromRGB(20, 20, 30))

-- Notifications feed, under the money panel.
local noticeLabel = makeLabel("NoticeLabel", gui, UDim2.new(0, 260, 0, 60), UDim2.new(1, -276, 0, 136),
	"", Color3.fromRGB(255, 230, 120), Color3.fromRGB(20, 20, 30))

-- The server sends the whole money state once a second.
MoneyUpdate.OnClientEvent:Connect(function(money, income, ownedCount, rebirths, lockSecondsLeft, waveSeconds)
	moneyLabel.Text = Economy.formatMoney(money)
	incomeLabel.Text = Economy.formatMoney(income) .. "/s"
	collectionLabel.Text = tostring(ownedCount) .. " brainrots  -  " .. tostring(rebirths) .. " rebirths"
	lockButton.Text = lockSecondsLeft > 0 and "BASE LOCKED" or "LOCK BASE (60s)"
	local minutes = math.floor(waveSeconds / 60)
	local seconds = math.floor(waveSeconds % 60)
	waveLabel.Text = "Next wave: " .. tostring(minutes) .. ":" .. string.format("%02d", seconds)
	if waveSeconds <= 15 then
		waveLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	else
		waveLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
	end
end)

Notify.OnClientEvent:Connect(function(text)
	noticeLabel.Text = text
	task.delay(5, function()
		if noticeLabel.Text == text then
			noticeLabel.Text = ""
		end
	end)
end)

WaveAlert.OnClientEvent:Connect(function(kind, seconds)
	if kind == "warning" then
		waveLabel.Text = "TSUNAMI IN " .. tostring(seconds) .. "s - RUN HOME!"
		waveLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
		noticeLabel.Text = "A tsunami is coming! Get inside your base!"
	elseif kind == "wave" then
		noticeLabel.Text = "TSUNAMI! Stay inside your base!"
	end
end)
