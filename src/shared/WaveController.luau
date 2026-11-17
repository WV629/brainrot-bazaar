-- WaveController: the tsunami clock. Every few minutes a wall of water
-- sweeps the map west to east, and only a player standing inside their
-- own base plot is safe. The module owns the timing and the wave wall;
-- the server asks it when to warn and when to sweep.
local GameConfig = require(script.Parent.GameConfig)

local WaveController = {}

WaveController.State = {
	NextWaveAt = 0,
	WarningSent = false,
	Sweeping = false,
}

-- Start the clock: the first wave comes one interval after the server starts.
function WaveController.start(now)
	WaveController.State.NextWaveAt = now + GameConfig.WaveInterval
	WaveController.State.WarningSent = false
	WaveController.State.Sweeping = false
end

-- Seconds until the next wave hits.
function WaveController.secondsUntilWave(now)
	return WaveController.State.NextWaveAt - now
end

-- True once the warning window has opened and the warning has not
-- been sent yet: the server should warn the players now.
function WaveController.warningDue(now)
	if WaveController.State.WarningSent then
		return false
	end
	if WaveController.secondsUntilWave(now) <= GameConfig.WaveWarningSeconds then
		WaveController.State.WarningSent = true
		return true
	end
	return false
end

-- True when the wave is due to sweep right now.
function WaveController.waveDue(now)
	return now >= WaveController.State.NextWaveAt and not WaveController.State.Sweeping
end

-- Mark the sweep as started, and schedule the next wave.
function WaveController.beginSweep(now)
	WaveController.State.Sweeping = true
	WaveController.State.NextWaveAt = now + GameConfig.WaveInterval
	WaveController.State.WarningSent = false
end

-- Mark the sweep as finished: the map is safe again.
function WaveController.endSweep()
	WaveController.State.Sweeping = false
end

-- Build the wave itself: a huge translucent wall of water at the west
-- edge, ready to be tweened across the map.
function WaveController.buildWaveWall(workspace)
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(4, 30, 220)
	wall.Position = Vector3.new(GameConfig.ConveyorStartX - 20, 15, 0)
	wall.Color = Color3.fromRGB(40, 140, 255)
	wall.Material = Enum.Material.Neon
	wall.Transparency = 0.35
	wall.Anchored = true
	wall.CanCollide = false
	wall.Parent = workspace
	return wall
end

-- Is a position inside a base plot's safe square?
function WaveController.isInsideBase(position, plotCenter)
	local half = GameConfig.BaseSize / 2
	return math.abs(position.X - plotCenter.X) <= half
		and math.abs(position.Z - plotCenter.Z) <= half
end

return WaveController
