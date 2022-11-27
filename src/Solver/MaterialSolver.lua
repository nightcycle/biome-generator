--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Types = require(Package.Types)

type ErosionData = {
	Limit: number,
	RockMaterial: Enum.Material,
	GroundMaterial: Enum.Material,
}

local Materials: {[Enum.Material]: ErosionData} = {
	[Enum.Material.Grass] = {
		Limit = 0.3,
		RockMaterial = Enum.Material.Rock,
		GroundMaterial = Enum.Material.Ground,	
	},
	[Enum.Material.LeafyGrass] = {
		Limit = 0.3,
		RockMaterial = Enum.Material.Rock,
		GroundMaterial = Enum.Material.Ground,	
	},
	[Enum.Material.Sand] = {
		Limit = 0.2,
		RockMaterial = Enum.Material.Sandstone,
		GroundMaterial = Enum.Material.Sand,	
	},
	[Enum.Material.Snow] = {
		Limit = 0.3,
		RockMaterial = Enum.Material.Rock,
		GroundMaterial = Enum.Material.Snow,	
	},
	[Enum.Material.Ground] = {
		Limit = 0.3,
		RockMaterial = Enum.Material.Rock,
		GroundMaterial = Enum.Material.Ground,	
	},
	[Enum.Material.Mud] = {
		Limit = 0.2,
		RockMaterial = Enum.Material.Rock,
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
	return function(alpha: Vector2): Enum.Material
		local heat = getHeatMap()(alpha)
		local rain = getRainMap()(alpha)
		local height = getHeightMap()(alpha)
		local normal = getNormalMap()(alpha)

		local waterHeight: number = config.WaterHeight/config.HeightCeiling

		local baseMaterial: Enum.Material
		if height < waterHeight then
			baseMaterial = Enum.Material.Mud
		end

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

		local erosionData: ErosionData? = Materials[baseMaterial]
		if not erosionData then
			return baseMaterial
		else
			assert(erosionData ~= nil)
			if normal > erosionData.Limit then
				if normal > erosionData.Limit * 1.2 then
					return erosionData.RockMaterial
				else
					return erosionData.GroundMaterial
				end
			else
				return baseMaterial
			end			
		end
	end
end