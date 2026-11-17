-- PlayerActions: the keyboard the player fights with. F slaps a thief
-- (the Baron, or a player carrying one of your brainrots). Buying uses
-- the ProximityPrompt's own E key, so slapping never steals that key.
-- ContextActionService is used on purpose: a plain InputBegan handler
-- that bails on gameProcessedEvent never sees keys Roblox's own
-- camera scripts already ate.
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local SlapRequest = remotes:WaitForChild("SlapRequest")

local function slap(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		SlapRequest:FireServer()
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("BrainrotSlap", slap, false, Enum.KeyCode.F)
