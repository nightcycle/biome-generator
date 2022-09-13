--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Types = require(Package.Types)

return function(config: Types.LandmasterConfigData, heightMap: _Math.NoiseSolver)
	
	return function(alpha: Vector2): number
		local step = 0.00001
		local upRightAlpha = alpha + Vector2.new(1,1)*step
		local botLeftAlpha = alpha + Vector2.new(-1,-1)*step
		local upRight = heightMap(upRightAlpha)
		local bottomLeft = heightMap(botLeftAlpha)
		local hor = (upRightAlpha - botLeftAlpha).Magnitude
		local ver = (upRight - bottomLeft) * (config.HeightCeiling/config.Width) * 40
		-- local slope = ver/hor
		local angle = math.abs(math.atan2(hor, ver))
		return 1 - (angle/math.rad(90))
	end
end