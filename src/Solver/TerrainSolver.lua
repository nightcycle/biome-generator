--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Types = require(Package.Types)
local Vector = _Math.Algebra.Vector

return function(config: Types.LandmasterConfigData)
	local flatMap = _Math.Noise.Simplex.new()
	flatMap:SetSeed(config.Seed * 1235.3463)
	flatMap:SetFrequency(config.Frequency)
	flatMap:SetAmplitude(1)
	flatMap:SetLacunarity(2)
	flatMap:SetPersistence(0.25)
	
	for i = 1, 2 do
		local Octave = _Math.Noise.Simplex.new()
		Octave:SetSeed(config.Seed * i * 23.50234)
		flatMap:InsertOctave(Octave)
	end
	
	local hillMap = _Math.Noise.Simplex.new()
	hillMap:SetSeed(config.Seed * 12345.3463)
	hillMap:SetFrequency(config.Frequency)
	hillMap:SetAmplitude(1)
	hillMap:SetLacunarity(2)
	hillMap:SetPersistence(0.25)
	
	for i = 1, 3 do
		local Octave = _Math.Noise.Simplex.new()
		Octave:SetSeed(config.Seed * i * 235.504)
		hillMap:InsertOctave(Octave)
	end
	
	local mountainMap = _Math.Noise.Cellular.new()
	mountainMap:SetSeed(config.Seed * 12.34)
	mountainMap:SetFrequency(config.Frequency)
	mountainMap:SetAmplitude(1)
	mountainMap:GeneratePoints(60, Vector.new(0, 0), Vector.new(1, 1))
	
	local mountainHeightMap = _Math.Noise.Simplex.new()
	mountainHeightMap:SetSeed(config.Seed * 12.3463)
	mountainHeightMap:SetFrequency(config.Frequency)
	mountainHeightMap:SetAmplitude(1)
	
	return function(alpha: Vector2): number
		local ruggedness = 1 - flatMap:Get(alpha)
		if ruggedness ~= ruggedness then
			ruggedness = 0
		end
	
		ruggedness = (_Math.clamp(ruggedness ^ 2 - 0.1, 0, 1) * (1 / 0.9)) ^ 0.5
	
		local hillValue = (2 * _Math.clamp(((hillMap:Get(alpha) ^ 0.5) - 0.5), 0, 1)) ^ 1.5
		
		local mountainValue = (
			mountainHeightMap:Get(alpha)
			* _Math.Algebra.ease(mountainMap:Get(alpha), Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		) ^ 0.75
	
		return _Math.clamp((_Math.clamp(ruggedness * (hillValue * 0.3 + mountainValue), 0, 1) ^ 2) * 8, 0, 1)
	end
	
end


