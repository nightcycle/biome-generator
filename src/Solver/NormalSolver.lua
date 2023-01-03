--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local _Maid = require(Packages.Maid)

local Types = require(Package.Types)

return function(
	config: Types.LandmasterConfigData,
	getHeightMap: () -> Types.NoiseMap<number>
)
	-- print("H TIME")
	return function(alpha: Vector2): number
		local step = 4/config.Width

		local upAlpha = alpha + Vector2.new(0,1)*step
		local downAlpha = alpha + Vector2.new(0,-1)*step
		local rightAlpha = alpha + Vector2.new(1,0)*step
		local leftAlpha = alpha + Vector2.new(-1,0)*step

		local upHeight = getHeightMap()(upAlpha)
		local downHeight = getHeightMap()(downAlpha)
		local rightHeight = getHeightMap()(rightAlpha)
		local leftHeight = getHeightMap()(leftAlpha)

		local yAlt = math.abs(upHeight-downHeight)*config.HeightCeiling
		local xAlt = math.abs(rightHeight-leftHeight)*config.HeightCeiling

		local yAngle = math.abs(math.atan(yAlt/(step*2*config.Width)))
		local xAngle = math.abs(math.atan(xAlt/(step*2*config.Width)))

		return math.max(xAngle, yAngle)/math.rad(90)
	end
end