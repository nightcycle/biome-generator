--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local NoiseUtil = require(Packages.NoiseUtil)
local CurveUtil = require(Packages.CurveUtil)
local _Maid = require(Packages.Maid)

local Types = require(Package.Types)

return function(
	config: Types.LandmasterConfigData, 
	getTerrainMap: () -> Types.NoiseMap<number>, 
	getRiverMap: () -> Types.NoiseMap<number>
)
	local cache = {}

	local map: NoiseUtil.NoiseSolver = NoiseUtil.Simplex.new()
	map:SetSeed(config.Seed)
	map:SetFrequency(config.Frequency)
	map:SetAmplitude(1)
	map:SetLacunarity(2)
	map:SetPersistence(0.5)

	for i = 1, 4 do
		local Octave = NoiseUtil.Simplex.new()
		Octave:SetSeed(config.Seed * i)
		map:InsertOctave(Octave)
	end

	return function(alpha: Vector2): number
		if cache[alpha] then return cache[alpha] end

		local baseValue = (map:Get(alpha)^1.5) * 2
		if baseValue ~= baseValue then
			baseValue = 0
		end

		local terrainValue = getTerrainMap()(alpha)

		baseValue = math.clamp(baseValue * 0.5 + 0.5 * terrainValue, 0, 1)
		local distFromCenter = (Vector2.new(0.5, 0.5) - alpha).Magnitude
		local linearReduction = math.max(1 - (distFromCenter / 0.5), 0)
		local easedReduction = CurveUtil.ease(linearReduction ^ 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		local easedHeight = easedReduction * baseValue

		local riverValue = getRiverMap()(alpha)

		local final = riverValue * math.clamp(easedHeight, 0, 1)
	
		cache[alpha] = final
	
		return final
	end
end