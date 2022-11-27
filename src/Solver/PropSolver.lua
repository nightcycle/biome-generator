--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Types = require(Package.Types)

return function(
	config: Types.LandmasterConfigData, 
	getHeightMap: () -> Types.NoiseMap<number>,
	getMaterialMap: () -> Types.NoiseMap<Enum.Material>,
	getNormalMap: () -> Types.NoiseMap<number>
)
	
	return function(alpha: Vector2): Types.PropSolveData?
		local material = getMaterialMap()(alpha)
		local height = getHeightMap()(alpha)
		if config.WaterEnabled and height < config.WaterHeight/config.HeightCeiling then
			return
		end

		local normal = getNormalMap()(alpha)
		
		local RNG = Random.new(normal ^ height)

		local props: {[number]: Types.PropTemplateData} = config.Props[material] or {}
		if #props < 1 then return end

		local categorySelectionVal = 1
		if #props > 1 then
			categorySelectionVal = RNG:NextInteger(1, #props)
		end
		
		local prop = props[categorySelectionVal]

		local insertVal = RNG:NextNumber()

		if insertVal > prop.Scarcity then return end

		return {
			Scale = 0.5 + RNG:NextNumber(),
			CFrame = CFrame.Angles(0,math.rad(RNG:NextNumber()*360),math.rad(RNG:NextNumber()*30-15)),
			Template = prop.Template,
		}
	end
end
