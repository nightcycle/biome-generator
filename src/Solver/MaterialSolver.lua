--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local _Maid = require(Packages.Maid)
local NoiseUtil = require(Packages.NoiseUtil)
local Types = require(Package.Types)
local Vector = require(Packages.Vector)

type ErosionData = {
	Limit: number,
	RockMaterial: Enum.Material,
	GroundMaterial: Enum.Material,
}

local BASE_LIMIT = 0.4
local DEFAULT_GROUND = Enum.Material.Ground
local DEFAULT_ROCK = Enum.Material.Rock

local Materials: {[Enum.Material]: ErosionData} = {
	[Enum.Material.Grass] = {
		Limit = BASE_LIMIT,
		RockMaterial = DEFAULT_ROCK,
		GroundMaterial = DEFAULT_GROUND,	
	},
	[Enum.Material.LeafyGrass] = {
		Limit = BASE_LIMIT,
		RockMaterial = DEFAULT_ROCK,
		GroundMaterial = DEFAULT_GROUND,	
	},
	[Enum.Material.Sand] = {
		Limit = BASE_LIMIT*0.8,
		RockMaterial = Enum.Material.Sandstone,
		GroundMaterial = Enum.Material.Sand,	
	},
	[Enum.Material.Snow] = {
		Limit = BASE_LIMIT*0.8,
		RockMaterial = DEFAULT_ROCK,
		GroundMaterial = Enum.Material.Snow,	
	},
	[Enum.Material.Ground] = {
		Limit = BASE_LIMIT,
		RockMaterial = DEFAULT_ROCK,
		GroundMaterial = DEFAULT_GROUND,	
	},
	[Enum.Material.Mud] = {
		Limit = BASE_LIMIT*0.8,
		RockMaterial = DEFAULT_ROCK,
		GroundMaterial = Enum.Material.Mud,	
	},
}


return function(
	config: Types.LandmasterConfigData, 
	getHeatMap: () -> Types.NoiseMap<number>,
	getRainMap: () -> Types.NoiseMap<number>,
	getNormalMap: () -> Types.NoiseMap<number>,
	getHeightMap: () -> Types.NoiseMap<number>
)

	local randMap = NoiseUtil.Random.new(config.Seed)
	randMap:SetSeed(config.Seed * 1.23452)
	randMap:SetFrequency(config.Frequency)
	randMap:SetAmplitude(1)
	randMap:GeneratePoints(30, Vector.new(0, 0), Vector.new(1, 1))

	return function(alpha: Vector2): Enum.Material

		local heat = getHeatMap()(alpha)
		local rain = getRainMap()(alpha)
		local height = getHeightMap()(alpha)
		local normal = getNormalMap()(alpha)

		local waterHeight: number = config.WaterHeight/config.HeightCeiling

		local baseMaterial: Enum.Material
		if height < waterHeight then
			baseMaterial = Enum.Material.Mud
		else
			if heat > 0.66 then
				if rain > 0.66 then
					baseMaterial = Enum.Material.LeafyGrass
				elseif rain > 0.33 then
					baseMaterial = Enum.Material.Sandstone
				else
					baseMaterial = Enum.Material.Sandstone
				end
			elseif heat > 0.33 then
				if rain > 0.66 then
					baseMaterial = Enum.Material.LeafyGrass
				elseif rain > 0.33 then
					baseMaterial = Enum.Material.Grass
				else
					baseMaterial = Enum.Material.Ground
				end
			else
				if rain > 0.66 then
					baseMaterial = Enum.Material.Snow
				elseif rain > 0.33 then
					baseMaterial = Enum.Material.Glacier
				else
					baseMaterial = Enum.Material.Ground
				end
			end
		end
		local erosionData: ErosionData? = Materials[baseMaterial]
		if not erosionData then
			return baseMaterial
		else
			assert(erosionData ~= nil)
			local rockLimit = erosionData.Limit * 1.3
			local threshold = math.clamp(math.abs(normal - erosionData.Limit)/0.5, 0, 1)
			local rVal = randMap:Get(alpha)
			local isRendered = true--rVal < threshold and threshold < rockLimit
			if normal >= erosionData.Limit then
				if normal >= rockLimit then
					if isRendered then
						return erosionData.RockMaterial
					else
						return baseMaterial
					end
				else
					if isRendered then
						return erosionData.GroundMaterial
					else
						return baseMaterial
					end
				end
			else
				return baseMaterial
			end			
		end
	end
end