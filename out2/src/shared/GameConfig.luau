-- GameConfig: every tunable number of Brainrot Bazaar lives in one place,
-- so balancing the game never means hunting through the game loop.
local GameConfig = {}

-- Starting cash for a fresh player.
GameConfig.StartingMoney = 100

-- How often a new brainrot steps onto the conveyor, in seconds.
GameConfig.SpawnInterval = 6

-- How many brainrots may walk the conveyor at once.
GameConfig.MaxConveyorBrainrots = 12

-- Conveyor path: brainrots walk from west to east along Z = 0.
GameConfig.ConveyorStartX = -70
GameConfig.ConveyorEndX = 70
GameConfig.ConveyorZ = 0
GameConfig.ConveyorSpeed = 4

-- Base plots: four corners of the map, one per player slot.
GameConfig.BasePlots = {
	{ Name = "Sunny Plot", Position = Vector3.new(-45, 0, -35), Color = Color3.fromRGB(255, 170, 60) },
	{ Name = "Berry Plot", Position = Vector3.new(45, 0, -35), Color = Color3.fromRGB(255, 90, 140) },
	{ Name = "Mint Plot", Position = Vector3.new(-45, 0, 35), Color = Color3.fromRGB(80, 220, 160) },
	{ Name = "Bubble Plot", Position = Vector3.new(45, 0, 35), Color = Color3.fromRGB(90, 170, 255) },
}
GameConfig.BaseSize = 26
GameConfig.BaseSlots = 8
GameConfig.MaxBaseSlots = 16

-- A brainrot nobody buys walks off the east end and despawns.
GameConfig.DespawnX = 74

-- Locking a base stops every thief, rival and player, for this long.
GameConfig.LockDuration = 60
GameConfig.LockCooldown = 60

-- Slap: knocks a thief back and stuns them, with a short cooldown.
GameConfig.SlapRange = 14
GameConfig.SlapCooldown = 3
GameConfig.SlapStun = 5

-- Stealing: carrying a stolen brainrot slows you down, and a wave
-- (or a slap) makes you drop it where you stand.
GameConfig.CarryWalkSpeed = 10
GameConfig.NormalWalkSpeed = 16

-- The tsunami: a warning, then a wall of water sweeps the map.
GameConfig.WaveInterval = 180
GameConfig.WaveWarningSeconds = 15
GameConfig.WaveSweepSeconds = 12

-- The NPC rival thief pays a visit this often, in seconds.
GameConfig.RivalVisitInterval = 75

-- Rebirth: pay the cost, lose your money and brainrots, keep a
-- permanent income multiplier. The cost grows with each rebirth.
GameConfig.RebirthBaseCost = 100000
GameConfig.RebirthMultiplierStep = 0.5

-- Extra base slots cost this much each, growing per slot bought.
GameConfig.SlotBaseCost = 5000

return GameConfig
