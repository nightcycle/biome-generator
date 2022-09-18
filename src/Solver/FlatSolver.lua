--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)
local Types = require(Package.Types)
-- local Vector = _Math.Algebra.Vector

local FLAT_RADIUS = 0.05

return function(config: Types.LandmasterConfigData)

	local map = _Math.Noise.Cellular.new()
	map:SetSeed(config.Seed)
	map:SetFrequency(config.Frequency)
	map:SetAmplitude(1)
	map:GeneratePoints(4, _Math.Algebra.Vector.new(0, 0), _Math.Algebra.Vector.new(1, 1))
	
	return function(alpha: Vector2): Vector2?
		local closestPoint: Vector2?
		local closestDist
		for i, cityPoint: _Math.Vector in ipairs(map.Points) do
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