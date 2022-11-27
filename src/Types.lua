--!strict
local Package = script.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Types = {}

--- @type NoiseSolver (Vector2) -> number
--- @within Landmaster
--- Returns a deterministic value at position on map. The vector must be normalized to be within 0 and 1.

export type NoiseMap<T> = (Vector2) -> T

--- @type LandmasterConfigData {Seed: number,Origin: Vector2,Frequency: number,Width: number,HeightCeiling: number, WaterHeight: number,Maps: {Height: NoiseSolver?,Heat: NoiseSolver?,Rain: NoiseSolver?},}
--- @within Landmaster
--- The data format usable when configuring Landmaster

export type PropTemplateData = {
	Template: Model,
	Scarcity: number,
}

export type PropSolveData = {
	Template: Model,
	CFrame: CFrame,
	Scale: number,
}

export type LandmasterConfigData = {
	Seed: number,
	Origin: Vector2,
	Frequency: number,
	Width: number,
	HeightCeiling: number,
	WaterHeight: number,
	WaterEnabled: boolean,
	Props: {[Enum.Material]: {[number]: PropTemplateData}},
	Maps: {
		Height: NoiseMap<_Math.Alpha>?,
		BaseHeight: NoiseMap<_Math.Alpha>?,
		Heat: NoiseMap<_Math.Alpha>?,
		Rain: NoiseMap<_Math.Alpha>?,
		River: NoiseMap<_Math.Alpha>?,
		Prop: NoiseMap<string?>?,
		Topography: NoiseMap<_Math.Alpha>?,
		Normal: NoiseMap<_Math.Alpha>?,
		Material: NoiseMap<Enum.Material>?,
		Flat: NoiseMap<Vector2?>?,
	}?,
}

--- @type TerrainColumnData {Height: number,Normal: _Math.Alpha,SurfaceMaterial: Enum.Material}
--- @within Landmaster
--- The data format used in solving each column of terrain.
export type TerrainColumnData = {
	Position: Vector3,
	Height: number,
	Normal: _Math.Alpha,
	SurfaceMaterial: Enum.Material,
	Prop: PropSolveData?,
}

export type Landmaster = {
	__index: Landmaster,
	_Maid: _Maid.Maid,
	_Config: LandmasterConfigData,
	_Solver: {[string]: any},
	new: (LandmasterConfigData) -> Landmaster,
	Destroy: (Landmaster) -> nil,
	Debug: (self: Landmaster, map: _Math.NoiseSolver, resolution: number, scale: number) -> Frame,
	GetTerrainColumnData: (self: Landmaster, position: Vector3) -> TerrainColumnData,
	GetMap: <T>(self: Landmaster, key: string) -> NoiseMap<T>,
	SetMap: <T>(self: Landmaster, key: string, map: NoiseMap<T>) -> nil,
	SolveRegionTerrain: (self: Landmaster, region:Region3, scale: _Math.Alpha?) -> (Region3, TerrainData<Enum.Material>, TerrainData<number>, {[string]: TerrainColumnData}),
	BuildRegionTerrain: (self: Landmaster, gridRegion: Region3, materialData: TerrainData<Enum.Material>, precisionData: TerrainData<number>, solveMap: {[string]: TerrainColumnData}) -> nil,
}


--- @type TerrainData {[number]: {[number]: {[number]: T}}}
--- @within Landmaster
--- Data usable within Terrain:WriteVoxels().

export type TerrainData<T> = {[number]: {[number]: {[number]: T}}}


return Types