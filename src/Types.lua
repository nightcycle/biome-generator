--!strict
local Package = script.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)

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
	new: (LandmasterConfigData) -> Landmaster,
	Destroy: (Landmaster) -> nil,
	Clone: (Landmaster) -> Landmaster,
	BuildRegion: (self: Landmaster, start: Vector3, finish: Vector3) -> Model
}


--- @type TerrainData {[number]: {[number]: {[number]: T}}}
--- @within Landmaster
--- Data usable within Terrain:WriteVoxels().

export type TerrainData<T> = {[number]: {[number]: {[number]: T}}}


return Types