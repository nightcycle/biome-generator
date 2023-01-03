--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local NoiseUtil = require(Packages.NoiseUtil)
local Vector = require(Packages.Vector)
local _Maid = require(Packages.Maid)
local Types = require(Package.Types)

return function(config: Types.LandmasterConfigData)
	local map: NoiseUtil.NoiseSolver = NoiseUtil.Voronoi.new()
	map:SetSeed(config.Seed * 1.23452)
	map:SetFrequency(config.Frequency)
	map:SetAmplitude(1)
	map:GeneratePoints(30, Vector.new(0, 0), Vector.new(1, 1))

	local blur: NoiseUtil.NoiseSolver = NoiseUtil.Cellular.new()
	blur:SetSeed(config.Seed * 1.23452)
	blur:SetFrequency(config.Frequency)
	blur:SetAmplitude(1)
	blur:GeneratePoints(30, Vector.new(0, 0), Vector.new(1, 1))

	local simplex: NoiseUtil.NoiseSolver = NoiseUtil.Simplex.new()
	simplex:SetSeed(120 + config.Seed * 0.25)
	simplex:SetFrequency(config.Frequency)
	simplex:SetAmplitude(1)
	simplex:SetLacunarity(2)
	simplex:SetPersistence(0.25)

	for i = 1, 4 do
		local Octave: NoiseUtil.NoiseSolver = NoiseUtil.Simplex.new()
		Octave:SetSeed(config.Seed * i * 2.524363)
		simplex:InsertOctave(Octave)
	end

	return function(alpha: Vector2): number
		local zone = map:Get(alpha)
		if zone ~= zone then
			zone = 0
		end

		local shade = (1 - blur:Get(alpha)) ^ 2

		local shadedZone = (math.clamp(zone * shade, 0, 1)) ^ 0.5
		local weight = simplex:Get(alpha) ^ 0.75
		return math.clamp((weight * shadedZone) ^ 0.5, 0, 1)
	end
end