--!strict
local Package = script.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Terrain = workspace.Terrain

local TerrainUtil = {}
TerrainUtil.__index = TerrainUtil

function TerrainUtil.clear()
	Terrain:Clear()
end

function TerrainUtil.fillToHeightAlpha(
	position: Vector2,
	size: Vector2,
	heightCeiling: number,
	waterCeiling: number
)


end

return TerrainUtil