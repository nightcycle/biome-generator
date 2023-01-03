--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local NoiseUtil = require(Packages.NoiseUtil)
local Vector = require(Packages.Vector)
local _Maid = require(Packages.Maid)
local Types = require(Package.Types)
-- local Vector = _Math.Algebra.Vector

local FLAT_RADIUS = 0.05

return function(config: Types.LandmasterConfigData)

	local map = NoiseUtil.Cellular.new()
	map:SetSeed(config.Seed)
	map:SetFrequency(config.Frequency)
	map:SetAmplitude(1)
	map:GeneratePoints(4, Vector.new(0, 0), Vector.new(1, 1))
	
	return function(alpha: Vector2): Vector2?
		local closestPoint: Vector2?
		local closestDist
		for i, cityPoint: Vector.Vector in ipairs(map.Points) do
			local cityAlpha = Vector2.new(cityPoint[1], cityPoint[2])
			local dist = (cityAlpha - alpha).Magnitude
			if dist <= FLAT_RADIUS then
				if not closestDist or dist < closestDist then
					closestDist = dist
					closestPoint = cityAlpha
				end
			end
		end
		return closestPoint
	end
end