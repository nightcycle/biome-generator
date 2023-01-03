--!strict
local Package = script.Parent
local Packages = Package.Parent
local NoiseUtil = require(Packages.NoiseUtil)
local _Maid = require(Packages.Maid)
local Types = require(Package.Types)

type NoiseSolver = NoiseUtil.NoiseSolver
type NoiseMap<T> = Types.NoiseMap<T>
type PropSolveData = Types.PropSolveData

-- Heat = number
-- Rain = number
-- River = number
-- Topography = number
-- Flat = Vector2?
-- Height = number
-- BaseHeight = number
-- Normal = number
-- Material = Enum.Material
-- Prop = PropSolveData

export type GetMap<T> = (
	((self: T, key: "Heat") -> NoiseMap<number>)
	& ((self: T, key: "Rain") -> NoiseMap<number>)
	& ((self: T, key: "River") -> NoiseMap<number>)
	& ((self: T, key: "Topography") -> NoiseMap<number>)
	& ((self: T, key: "Flat") -> NoiseMap<Vector2?>)
	& ((self: T, key: "Height") -> NoiseMap<number>)
	& ((self: T, key: "BaseHeight") -> NoiseMap<number>)
	& ((self: T, key: "Normal") -> NoiseMap<number>)
	& ((self: T, key: "Material") -> NoiseMap<Enum.Material>)
)

export type SetMap<T> = (
	((self: T, key: "Heat", map: NoiseMap<number>) -> nil)
	& ((self: T, key: "Rain", map: NoiseMap<number>) -> nil)
	& ((self: T, key: "River", map: NoiseMap<number>) -> nil)
	& ((self: T, key: "Topography", map: NoiseMap<number>) -> nil)
	& ((self: T, key: "Flat", map: NoiseMap<Vector2?>) -> nil)
	& ((self: T, key: "Height", map: NoiseMap<number>) -> nil)
	& ((self: T, key: "BaseHeight", map: NoiseMap<number>) -> nil)
	& ((self: T, key: "Normal", map: NoiseMap<number>) -> nil)
	& ((self: T, key: "Material", map: NoiseMap<Enum.Material>) -> nil)
)

export type MapSolver = {
	__index: MapSolver,
	_Maid: _Maid.Maid,
	_Config: Types.LandmasterConfigData,
	_Maps: {
		Heat: NoiseMap<number>,
		Rain: NoiseMap<number>,
		River: NoiseMap<number>,
		Topography: NoiseMap<number>,
		Flat: NoiseMap<Vector2?>,
		Height: NoiseMap<number>,
		BaseHeight: NoiseMap<number>,
		Normal: NoiseMap<number>,
		Material: NoiseMap<Enum.Material>,
	},
	GetMap: GetMap<MapSolver>,
	SetMap: SetMap<MapSolver>,
	GetPositionFromNormalizedCoordinates: (self: MapSolver, coordinates: Vector2) -> Vector2,
	GetNormalizedCoordinatesFromPosition: (self: MapSolver, coordinates: Vector2) -> Vector2,
	GetNormalAlpha: (self: MapSolver, normalizedCoordinates: Vector2) -> number,
	GetHeightAlpha: (self: MapSolver, normalizedCoordinates: Vector2) -> number,
	new: (config: Types.LandmasterConfigData) -> MapSolver,
}

local MapSolver: MapSolver = {} :: any
MapSolver.__index = MapSolver

function MapSolver:GetMap(key: any): any
	assert(self._Maps[key] ~= nil, "No map at key "..tostring(key))
	return self._Maps[key]
end

function MapSolver:SetMap(key: string, map: NoiseMap<any>)
	assert(map ~= nil, "Bad map")
	self._Maps[key] = map
	return nil
end

function MapSolver.new(config: Types.LandmasterConfigData)
	local self: MapSolver = setmetatable({
		_Config = config,
		_Maps = {},
		_Maid = _Maid.new(),
	}, MapSolver) :: any

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

	for k, map in pairs(config.Maps or {}) do
		self:SetMap(k, map)
	end

	return self
end

function MapSolver:GetPositionFromNormalizedCoordinates(coordinates: Vector2): Vector2
	local origin: Vector2 = self._Config.Origin
	local width: number = self._Config.Width
	local size = Vector2.new(1,1) * width
	local minPos = origin - size * 0.5
	return minPos + coordinates*size
end

function MapSolver:GetNormalizedCoordinatesFromPosition(position: Vector2): Vector2
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

function MapSolver:GetNormalAlpha(normalizedCoordinates: Vector2): number
	local normalMap: NoiseMap<number> = self._Maps.Normal
	return normalMap(normalizedCoordinates)
end

function MapSolver:GetHeightAlpha(normalizedCoordinates: Vector2): number
	local heightMap: NoiseMap<number> = self._Maps.Height
	return heightMap(normalizedCoordinates)
end

return MapSolver