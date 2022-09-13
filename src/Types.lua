--!strict
local Package = script.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)

local Types = {}

export type LandmasterConfigData = {
	Seed: number,
	Origin: Vector2,
	Frequency: number,
	Width: number,
	HeightCeiling: number,
	WaterHeight: number,
	Maps: {
		Height: _Math.NoiseSolver?,
		Heat: _Math.NoiseSolver?,
		Rain: _Math.NoiseSolver?,
	},
}

export type Landmaster = {
	new: (LandmasterConfigData) -> Landmaster,
	Destroy: (Landmaster) -> nil,
	Clone: (Landmaster) -> Landmaster,
	BuildRegion: (self: Landmaster, start: Vector3, finish: Vector3) -> Model
}

export type TerrainData<T> = {[number]: {[number]: {[number]: T}}}


return Types