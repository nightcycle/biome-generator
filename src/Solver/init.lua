--!strict
local Package = script.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)
local Types = require(Package.Types)

local Solver = {}
Solver.__index = Solver

function Solver:GetMap<T>(key: string): ((Vector2) -> T)
	assert(self._Maps[key] ~= nil, "No map at key "..tostring(key))
	return self._Maps[key]
end

function Solver:SetMap<T>(key: string, map: _Math.NoiseSolver)
	assert(map ~= nil, "Bad map")
	self._Maps[key] = map
end

function Solver.new(config: Types.LandmasterConfigData)
	local self = {
		_Config = config,
		_Maps = {},
		_Maid = _Maid.new(),
	}
	setmetatable(self, Solver)

	self:SetMap("Heat", require(script.HeatSolver)(config))
	self:SetMap("Rain", require(script.RainSolver)(config))
	self:SetMap("River", require(script.RiverSolver)(config))
	self:SetMap("Topography", require(script.TopographySolver)(config))
	self:SetMap("Flat", require(script.FlatSolver)(config))
	self:SetMap("Height", require(script.HeightSolver)(
		config, 
		function() return self:GetMap("BaseHeight") end, 
		function() return self:GetMap("Flat") end
	))
	self:SetMap("BaseHeight", require(script.BaseHeightSolver)(
		config, 
		function() return self:GetMap("Topography") end, 
		function() return self:GetMap("River") end
	))
	self:SetMap("Normal", require(script.NormalSolver)(
		config,
		function() return self:GetMap("Height") end
	))
	self:SetMap("Material", require(script.MaterialSolver)(
		config,
		function() return self:GetMap("Heat") end, 
		function() return self:GetMap("Rain") end,
		function() return self:GetMap("Normal") end,
		function() return self:GetMap("Height") end
	))
	self:SetMap("Prop", require(script.PropSolver)(
		config,
		function() return self:GetMap("Height") end,
		function() return self:GetMap("Material") end,
		function() return self:GetMap("Normal") end
	))
	for k, map in pairs(config.Maps or {}) do
		self:SetMap(k, map)
	end

	return self
end

function Solver:GetPositionFromNormalizedCoordinates(coordinates: Vector2): Vector2
	local origin: Vector2 = self._Config.Origin
	local width: number = self._Config.Width
	local size = Vector2.new(1,1) * width
	local minPos = origin - size * 0.5
	return minPos + coordinates*size
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

function Solver:GetNormalAlpha(normalizedCoordinates: Vector2)
	local normalMap: _Math.NoiseSolver = self.Maps.Normal
	return normalMap(normalizedCoordinates)
end

function Solver:GetHeightAlpha(normalizedCoordinates: Vector2)
	local heightMap: _Math.NoiseSolver = self.Maps.Height
	return heightMap(normalizedCoordinates)
end

return Solver