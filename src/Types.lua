--!strict
local Package = script.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Types = {}

--- @type NoiseSolver (Vector2) -> number
--- @within Landmaster
--- Returns a deterministic value at position on map. The vector must be normalized to be within 0 and 1.

type NoiseSolver = _Math.NoiseSolver

--- @type LandmasterConfigData {Seed: number,Origin: Vector2,Frequency: number,Width: number,HeightCeiling: number, WaterHeight: number,Maps: {Height: NoiseSolver?,Heat: NoiseSolver?,Rain: NoiseSolver?},}
--- @within Landmaster
--- The data format usable when configuring Landmaster

export type LandmasterConfigData = {
	Seed: number,
	Origin: Vector2,
	Frequency: number,
	Width: number,
	HeightCeiling: number,
	WaterHeight: number,
	Maps: {
		Height: NoiseSolver?,
		Heat: NoiseSolver?,
		Rain: NoiseSolver?,
	},
}


export type Landmaster = {
	__index: Landmaster,
	_Maid: _Maid.Maid,
	_Config: LandmasterConfigData,
	new: (LandmasterConfigData) -> Landmaster,
	Destroy: (Landmaster) -> nil,
	Solver: {[string]: any},
	Debug: (self: Landmaster, map: NoiseSolver, resolution: number, scale: number) -> Frame,
	SolveRegionTerrain: (self: Landmaster, region:Region3) -> (Region3, TerrainData<Enum.Material>, TerrainData<number>),
	BuildRegionTerrain: (self: Landmaster, gridRegion: Region3, materialData: TerrainData<Enum.Material>, precisionData: TerrainData<number>) -> nil,
}


--- @type TerrainData {[number]: {[number]: {[number]: T}}}
--- @within Landmaster
--- Data usable within Terrain:WriteVoxels().

export type TerrainData<T> = {[number]: {[number]: {[number]: T}}}


return Types