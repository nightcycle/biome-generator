--!strict
local Package = script.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)
local Types = require(Package.Types)

local Solver = {}
Solver.__index = Solver

function Solver.new(config: Types.LandmasterConfigData)
	local HeightMap = config.Maps.Height or require(script.HeightSolver)(
		config, 
		require(script.TerrainSolver)(config), 
		require(script.RiverSolver)(config)
	)
	local NormalMap = require(script.NormalSolver)(config, HeightMap)

	local self = {
		_Config = config,
		Maps = {
			Rain = config.Maps.Rain or require(script.RainSolver)(config),
			Heat = config.Maps.Heat or require(script.HeatSolver)(config),
			Normal = NormalMap,
			Height = HeightMap,
		},
		_Maid = _Maid.new(),
	}
	setmetatable(self, Solver)
	return self
end

function Solver:GetNormalizedCoordinatesFromPosition(position: Vector2): Vector2
	local origin: Vector2 = self._Config.Origin
	local width: number = self._Config.Width

	local size = Vector2.new(1,1) * width

	local minPos = origin - size * 0.5
	local maxPos = origin + size * 0.5

	local alpha = (position - minPos)/(maxPos - minPos)
	local aX: number = alpha.X
	local aY: number = alpha.Y
	if alpha.X < 0 then
		aX = 1+(alpha.X + math.ceil(alpha.X))
	elseif alpha.X > 1 then
		aX = (alpha.X - math.floor(alpha.X))-1
	end

	if alpha.Y < 0 then
		aY = 1+(alpha.Y + math.abs(math.ceil(alpha.Y)))
	elseif alpha.Y > 1 then
		aY = (alpha.Y - math.floor(alpha.Y))-1
	end

	return Vector2.new(aX, aY)
end

function Solver:GetSurfaceMaterial(normalizedCoordinates: Vector2): Enum.Material
	local heatMap: _Math.NoiseSolver = self.Maps.Heat
	local rainMap: _Math.NoiseSolver = self.Maps.Rain

	local heat = heatMap(normalizedCoordinates)
	local rain = rainMap(normalizedCoordinates)

	if heat > 0.66 then
		if rain > 0.66 then
			return Enum.Material.LeafyGrass
		elseif rain > 0.33 then
			return Enum.Material.Sandstone
		else
			return Enum.Material.Sandstone
		end
	elseif heat > 0.33 then
		if rain > 0.66 then
			return Enum.Material.LeafyGrass
		elseif rain > 0.33 then
			return Enum.Material.Grass
		else
			return Enum.Material.Ground
		end
	else
		if rain > 0.66 then
			return Enum.Material.Snow
		elseif rain > 0.33 then
			return Enum.Material.Glacier
		else
			return Enum.Material.Ground
		end
	end
end

function Solver:GetNormalAlpha(normalizedCoordinates: Vector2)
	local normalMap: _Math.NoiseSolver = self.Maps.Normal
	return normalMap(normalizedCoordinates)
end

function Solver:GetHeightAlpha(normalizedCoordinates: Vector2)
	local heightMap: _Math.NoiseSolver = self.Maps.Height
	return heightMap(normalizedCoordinates)
end

return Solver