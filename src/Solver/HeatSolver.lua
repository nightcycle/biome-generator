--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local NoiseUtil = require(Packages.NoiseUtil)
local CurveUtil = require(Packages.CurveUtil)
local _Maid = require(Packages.Maid)

local Types = require(Package.Types)
local Vector = require(Packages.Vector)

return function(config: Types.LandmasterConfigData)

	local map: NoiseUtil.NoiseSolver = NoiseUtil.Cellular.new()
	map:SetSeed(config.Seed)
	map:SetFrequency(config.Frequency)
	map:SetAmplitude(1)
	map:GeneratePoints(30, Vector.new(0, 0), Vector.new(1, 1))

	return function(alpha: Vector2): number
		local baseValue = 1 - map:Get(alpha)
		if baseValue ~= baseValue then
			baseValue = 0
		end

		local equatorWeight = 1 - math.abs(alpha.Y - 0.5) / 0.5

		local easedReduction = CurveUtil.ease(equatorWeight ^ 0.175, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

		return math.clamp((baseValue * 1.25 - 0.125) * easedReduction, 0, 1)
	end
end