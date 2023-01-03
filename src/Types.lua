--!strict
local Package = script.Parent
local Packages = Package.Parent
local NoiseUtil = require(Packages.NoiseUtil)
local _Maid = require(Packages.Maid)

local Types = {}

--- @type NoiseSolver (Vector2) -> number
--- @within Landmaster
--- Returns a deterministic value at position on map. The vector must be normalized to be within 0 and 1.

export type NoiseMap<T> = (Vector2) -> T

export type Alpha = number
export type PropTemplateData = {
	Template: Model,
	Scarcity: number,
}

export type PropSolveData = {
	Template: Model,
	CFrame: CFrame,
	Scale: number,
}

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
	WaterEnabled: boolean,
	Props: {[Enum.Material]: {[number]: PropTemplateData}},
	Maps: {
		Height: NoiseMap<Alpha>?,
		BaseHeight: NoiseMap<Alpha>?,
		Heat: NoiseMap<Alpha>?,
		Rain: NoiseMap<Alpha>?,
		River: NoiseMap<Alpha>?,
		Prop: NoiseMap<string?>?,
		Topography: NoiseMap<Alpha>?,
		Normal: NoiseMap<Alpha>?,
		Material: NoiseMap<Enum.Material>?,
		Flat: NoiseMap<Vector2?>?,
	}?,
}

--- @type TerrainColumnData {Height: number,Normal: Alpha,SurfaceMaterial: Enum.Material}
--- @within Landmaster
--- The data format used in solving each column of terrain.
export type TerrainColumnData = {
	Position: Vector3,
	Height: number,
	Normal: Alpha,
	SurfaceMaterial: Enum.Material,
	Prop: PropSolveData?,
}

--- @type TerrainData {[number]: {[number]: {[number]: T}}}
--- @within Landmaster
--- Data usable within Terrain:WriteVoxels().

export type TerrainData<T> = {[number]: {[number]: {[number]: T}}}


return Types