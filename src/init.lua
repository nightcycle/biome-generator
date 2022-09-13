--!strict
local Package = script
local Packages = Package.Parent
local Terrain = workspace.Terrain

local Solver = require(script.Solver)
local Types = require(Package.Types)

local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

export type NoiseSolver = _Math.NoiseSolver
export type LandmasterConfigData = Types.LandmasterConfigData
export type TerrainData<T> = Types.TerrainData<T>
export type Landmaster = Types.Landmaster

--- @class Landmaster
--- A configurable worker that can solve and build terrain.
local Landmaster: Landmaster = {} :: any
Landmaster.__index = Landmaster

--- Cleans up landmaster.
function Landmaster:Destroy()
	-- self:Clear()
	self._Maid:Destroy()
	for k, v in pairs(self) do
		self[k] = nil
	end
	setmetatable(self, nil)
	return nil
end

--- Constructs a landmaster.
function Landmaster.new(config: LandmasterConfigData): Landmaster
	-- Terrain:Clear()
	local self = {
		_Config = config,
		Solver = Solver.new(config),
		_Maid = _Maid.new(),
	}
	setmetatable(self, Landmaster)

	return self :: any
end

--- Renders a map gui for the provided solver.
function Landmaster:Debug(map: NoiseSolver, resolution: number, scale: number):Frame
	local frame = Instance.new("Frame")
	-- print("Start")
	for x=1, resolution do
		if x%10 == 0 then task.wait(); print(x/resolution) end
		-- task.wait()
		for y=1, resolution do
			local a = Vector2.new(x,y)/resolution
			local v = map(a)
			-- print("XY", a)
			local pxFrame = Instance.new("Frame")
			pxFrame.BorderSizePixel = 0
			pxFrame.BackgroundColor3 = Color3.fromHSV(0,0,v)
			pxFrame.Size = UDim2.fromOffset(scale,scale)
			pxFrame.Position = UDim2.fromOffset(x*scale,y*scale)
			pxFrame.Parent = frame
		end
	end
	-- print("Stop")
	return frame
end

--- Given a world region3 it constructs a grid normalized region and the material + precision data tables needed for Terrain:WriteVoxels(). Should be parallel safe.
function Landmaster:SolveRegionTerrain(region:Region3): (Region3, TerrainData<Enum.Material>, TerrainData<number>)
	local start = region.CFrame.Position - region.Size/2
	local finish = region.CFrame.Position + region.Size/2

	start = Terrain:WorldToCell(start) * 4
	finish = Terrain:WorldToCell(finish) * 4

	local originPosition = Vector2.new(start.X, start.Z)*4
	
	local heightCeiling: number = self._Config.HeightCeiling
	local waterHeight: number = self._Config.WaterHeight

	local regStart = Terrain:WorldToCell(Vector3.new(originPosition.X, 0, originPosition.Y))
	local regSize = Vector2.new(finish.X - start.X, finish.Z - start.Z)
	local gridRegion = Region3.new(
		regStart,
		regStart + Vector3.new(regSize.X, heightCeiling, regSize.Y)
	):ExpandToGrid(4)
	
	local function create3dTable(size: Vector3)
		local ret = {}
		for x = 1, size.X do
			ret[x] = {}
			for y = 1, size.Y do
				ret[x][y] = {}
			end
		end	
		return ret
	end
	local layerCount = gridRegion.Size.Y/4
	local xCount = gridRegion.Size.X/4
	local zCount = gridRegion.Size.Z/4
	local matGrid = create3dTable(Vector3.new(xCount,layerCount,zCount))
	local preGrid = create3dTable(Vector3.new(xCount,layerCount,zCount))
	local surfaceThickness = 8

	for xIndex=1, xCount do
		for zIndex=1, zCount do
			
			local columnPosition = regStart + Vector3.new(xIndex, 0, zIndex)*4
			local normalizedCoordinates = self.Solver:GetNormalizedCoordinatesFromPosition(Vector2.new(columnPosition.X, columnPosition.Z))
			local heightAlpha: number = self.Solver:GetHeightAlpha(normalizedCoordinates)
			local normal = self.Solver:GetNormalAlpha(normalizedCoordinates)
			local surfaceMaterial = self.Solver:GetSurfaceMaterial(normalizedCoordinates)

			local height = heightAlpha * heightCeiling

			for yIndex=1, layerCount do
				local focusAltitude = heightCeiling * yIndex / layerCount
				local distFromSurface = math.abs(focusAltitude - height)*0.5
				local material = Enum.Material.Air
				if height >= focusAltitude then -- surface or ground
					if height < waterHeight then
						material = Enum.Material.Mud
					elseif distFromSurface < surfaceThickness then
						if normal > 0.9 then
							material = Enum.Material.Rock
						elseif normal > 0.8 then
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

				matGrid[xIndex][yIndex][zIndex] = material
				preGrid[xIndex][yIndex][zIndex] = precision
			end
		end
	end
	return gridRegion, matGrid, preGrid
end

--- Writes voxels based on the returned values of SolveRegionTerrain.
function Landmaster:BuildRegionTerrain(gridRegion: Region3, materialData: TerrainData<Enum.Material>, precisionData: TerrainData<number>)

	Terrain:WriteVoxels(
		gridRegion,
		4,
		materialData,
		precisionData
	)
	return nil
end

return Landmaster