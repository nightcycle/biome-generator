--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Types = require(Package.Types)
local Vector = _Math.Algebra.Vector

return function(config: Types.LandmasterConfigData)
	local map = _Math.Noise.Cellular.new()
	map:SetSeed(config.Seed)
	map:SetFrequency(config.Frequency)
	map:SetAmplitude(1)
	map:GeneratePoints(50, Vector.new(0, 0), Vector.new(1, 1))

	return function(alpha: Vector2): number
		local baseValue = 1 - map:Get(alpha)
		if baseValue ~= baseValue then
			baseValue = 0
		end

		return _Math.clamp(1.25 * (baseValue + 0.3) ^ 5, 0, 1)
	end
end