--!strict
local Package = script.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)

local Types = {}

export type BiomeData = {
	Name: string,
	Material: (Enum.Material),

}

export type LandmasterConfigData = {
	Seed: number,
	Origin: Vector2,
	Frequency: number,
	Width: number,
	HeightCeiling: number,
	WaterHeight: number,
	Biomes: {[number]: BiomeData},
	Maps: {
		Height: _Math.NoiseSolver?,
		Heat: _Math.NoiseSolver?,
		Rain: _Math.NoiseSolver?,
		-- River: _Math.NoiseSolver?,
		-- Terrain: _Math.NoiseSolver?,
	},
}

export type Landmaster = {
	new: (LandmasterConfigData) -> Landmaster,
	Destroy: (Landmaster) -> nil,
	Clone: (Landmaster) -> Landmaster,
	BuildRegion: (self: Landmaster, start: Vector3, finish: Vector3) -> Model
}

return Types