--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Types = require(Package.Types)

return function(config: Types.LandmasterConfigData, getBaseHeightMap: () -> Types.NoiseMap<number>, getFlatMap: () -> Types.NoiseMap<Vector2?>)

	local cache = {}

	return function(alpha: Vector2): number
		if cache[alpha] then return cache[alpha] end

		local baseHeightMap = getBaseHeightMap()

		local flatMap = getFlatMap()
		local flatPoint = flatMap(alpha)
		local baseHeight = baseHeightMap(alpha)

		if not flatPoint then 
			cache[alpha] = baseHeight
			return baseHeight 
		end
		assert(flatPoint ~= nil)

		local flatPointHeight = baseHeightMap(flatPoint)
		cache[alpha] = flatPointHeight
		return flatPointHeight
	end
end