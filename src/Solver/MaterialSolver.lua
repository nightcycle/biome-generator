--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Types = require(Package.Types)

return function(config: Types.LandmasterConfigData, getHeatMap: () -> Types.NoiseMap<number>, getRainMap: () -> Types.NoiseMap<number>, getHeightMap: () -> Types.NoiseMap<number>)
	return function(alpha: Vector2): Enum.Material
		local heat = getHeatMap()(alpha)
		local rain = getRainMap()(alpha)
		local height = getHeightMap()(alpha)

		local waterHeight: number = config.WaterHeight/config.HeightCeiling

		if height < waterHeight then
			return Enum.Material.Mud
		end
		if heat > 0.66 then
			if rain > 0.66 then
				return Enum.Material.LeafyGrass
			elseif rain > 0.33 then
				return Enum.Material.Sandstone
			else
				return Enum.Material.Sandstone
			end
		elseif heat > 0.33 then
			if rain > 0.66 then
				return Enum.Material.LeafyGrass
			elseif rain > 0.33 then
				return Enum.Material.Grass
			else
				return Enum.Material.Ground
			end
		else
			if rain > 0.66 then
				return Enum.Material.Snow
			elseif rain > 0.33 then
				return Enum.Material.Glacier
			else
				return Enum.Material.Ground
			end
		end
	end
end