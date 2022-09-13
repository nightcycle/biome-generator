--!strict
local Package = script.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Terrain = workspace.Terrain

local TerrainUtil = {}
TerrainUtil.__index = TerrainUtil

function TerrainUtil.clear()
	Terrain:Clear()
end

function TerrainUtil.fillToHeightAlpha(
	position: Vector2, 
	surfaceMaterial: Enum.Material, 
	heightAlpha: number, 
	surfaceThickness: number, 
	waterHeight: number, 
	maxHeight: number,
	normal: number
)
	local material = Enum.Material.Air
	local height = heightAlpha * maxHeight

	local function drawLayer(focusAltitude: number)

		local cellPosition = Terrain:WorldToCell(Vector3.new(position.X, focusAltitude*4, position.Y))
		local distFromSurface = math.abs(focusAltitude - height)*0.5

		if height >= focusAltitude then -- surface or ground
			if height < waterHeight then
				material = Enum.Material.Mud
			elseif distFromSurface < surfaceThickness then
				if normal > 0.8 then
					material = Enum.Material.Rock
				elseif normal > 0.7 then
					material = Enum.Material.Ground
				else
					material = surfaceMaterial
				end
			else
				material = Enum.Material.Ground
			end
		else
			if focusAltitude < waterHeight then
				material = Enum.Material.Water
			else
				material = Enum.Material.Air
			end
		end

		local precision = if distFromSurface < 4 then distFromSurface/4 else 1

		local region = Region3.new(
			cellPosition,
			cellPosition + Vector3.new(1,1,1)*4
		)

		local success, msg = pcall(function()
			-- Terrain:FillRegion(region, 4, material)
			Terrain:WriteVoxels(
				region,
				4,
				{{{material}}},
				{{{precision}}}
			)
		end)
		if not success then
			warn(msg)
		end
	end
	-- drawLayer(height)
	for focusAltitude=0, maxHeight do
		drawLayer(focusAltitude)
	end
end

return TerrainUtil