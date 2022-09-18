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

--- Gets a noise map at a specified category.
function Landmaster:GetMap<T>(key: string): Types.NoiseMap<T>
	return self._Solver:GetMap(key)
end

--- Sets a noise map for usage.
function Landmaster:SetMap<T>(key: string, map: Types.NoiseMap<T>): nil
	self._Solver:SetMap(key, map)
	return nil
end

--- Constructs a landmaster.
function Landmaster.new(config: LandmasterConfigData): Landmaster
	-- Terrain:Clear()
	local self = {
		_Config = config,
		_Solver = Solver.new(config),
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

--- Gets the TerrainColumnData at a specific world position on the map.
function Landmaster:GetTerrainColumnData(columnPosition: Vector3): Types.TerrainColumnData
	
	local normalizedCoordinates = self._Solver:GetNormalizedCoordinatesFromPosition(Vector2.new(columnPosition.X, columnPosition.Z))

	local heightMap = self:GetMap("Height")
	local normalMap = self:GetMap("Normal")
	local materialMap = self:GetMap("Material")

	local heightAlpha: number = heightMap(normalizedCoordinates)
	local normal = normalMap(normalizedCoordinates)
	local surfaceMaterial = materialMap(normalizedCoordinates)

	local heightCeiling: number = self._Config.HeightCeiling
	local height = heightAlpha * heightCeiling

	return {
		Height = height,
		SurfaceMaterial = surfaceMaterial,
		Normal = normal,
	}
end

--- Given a world region3 it constructs a grid normalized region and the material + precision data tables needed for Terrain:WriteVoxels(). Should be parallel safe. As 
function Landmaster:SolveRegionTerrain(region:Region3, scale: _Math.Alpha?): (Region3, TerrainData<Enum.Material>, TerrainData<number>)
	scale = scale or 1
	assert(scale ~= nil)

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

	local increment = math.floor(1/scale)

	local importantXIndeces = {}
	local importantZIndeces = {}
	local solveMap: {[string]: Types.TerrainColumnData} = {}
	local function constructPillar(xIndex: number, zIndex: number, height: number, normal: number, surfaceMaterial: Enum.Material)
		for yIndex=1, layerCount do
			local focusAltitude = heightCeiling * yIndex / layerCount
			local distFromSurface = math.abs(focusAltitude - height)*0.5

			local material = Enum.Material.Air
			if height >= focusAltitude then -- surface or ground
				if distFromSurface < surfaceThickness then
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

	for xIndex=1, xCount do
		if xIndex % increment == 0 or (xIndex == xCount or xIndex == 1) then
			table.insert(importantXIndeces, xIndex)
			for zIndex=1, zCount do
				if zIndex % increment == 0 or (zIndex == zCount or zIndex == 1) then
					if #importantXIndeces == 1 then
						table.insert(importantZIndeces, zIndex)
					end
					local columnPosition = regStart + Vector3.new(xIndex, 0, zIndex)*4
					solveMap[tostring(Vector2.new(xIndex, zIndex))] = self:GetTerrainColumnData(columnPosition)
				end
			end
		end
	end

	for i, nextXIndex in ipairs(importantXIndeces) do
		for j, nextZIndex in ipairs(importantZIndeces) do

			local prevXIndex = importantXIndeces[i-1]
			local prevZIndex = importantZIndeces[j-1]

			if prevXIndex and prevZIndex then

				local q1Point = Vector2.new(nextXIndex, nextZIndex)
				local q2Point = Vector2.new(nextXIndex, prevZIndex)
				local q3Point = Vector2.new(prevXIndex, prevZIndex)
				local q4Point = Vector2.new(prevXIndex, nextZIndex)

				local function terrainLerp(pV2: Vector2, aV2: Vector2, bV2: Vector2, cV2: Vector2): Types.TerrainColumnData?
					local aKey = tostring(aV2)
					local bKey = tostring(bV2)
					local cKey = tostring(cV2)

					local aData = solveMap[aKey]
					local bData = solveMap[bKey]
					local cData = solveMap[cKey]

					local point = Vector3.new(pV2.X, 0, pV2.Y)
					local a = Vector3.new(aV2.X, 0, aV2.Y)
					local b = Vector3.new(bV2.X, 0, bV2.Y)
					local c = Vector3.new(cV2.X, 0, cV2.Y)
					
					local area = _Math.Geometry.getTriangleArea(a,b,c)

					local cAlpha = _Math.Geometry.getTriangleArea(a,b,point)/area
					if cAlpha ~= cAlpha then cAlpha = 0 end

					local aAlpha = _Math.Geometry.getTriangleArea(b,c,point)/area
					if aAlpha ~= aAlpha then aAlpha = 0 end
	
					local bAlpha = _Math.Geometry.getTriangleArea(c,a,point)/area
					if bAlpha ~= bAlpha then bAlpha = 0 end

					local fullAlpha = cAlpha + aAlpha + bAlpha

					local isInTri = (fullAlpha < 1.01)

					if not isInTri then return end
					local surfaceMaterial: Enum.Material

					local nVal = math.noise(pV2.X/math.pi, pV2.Y/math.pi)
					local score = math.clamp(0.5 + 0.5*nVal, 0, 1)

					if score < aAlpha then
						surfaceMaterial = aData.SurfaceMaterial
					elseif score < aAlpha + bAlpha then
						surfaceMaterial = bData.SurfaceMaterial
					else
						surfaceMaterial = cData.SurfaceMaterial
					end
			
					local function triLerp(aAlpha: number, aVal: number, bAlpha: number, bVal: number, cAlpha: number, cVal: number): number
						return aAlpha * aVal + bAlpha * bVal + cAlpha * cVal
					end

					local height = triLerp(aAlpha, aData.Height, bAlpha, bData.Height, cAlpha, cData.Height)
					local normal = triLerp(aAlpha, aData.Normal, bAlpha, bData.Normal, cAlpha, cData.Normal)

					return {
						Height = height,
						SurfaceMaterial = surfaceMaterial,
						Normal = normal,
					}
				end
				
				for xIndex=prevXIndex, nextXIndex do
					for zIndex=prevZIndex, nextZIndex do
	
						local point = Vector2.new(xIndex, zIndex)

						local solveData = terrainLerp(point, q1Point, q2Point, q3Point)
						if not solveData then
							solveData = terrainLerp(point, q1Point, q4Point, q3Point)
						end
						assert(solveData ~= nil, "Bad solve data: "..tostring(Vector2.new(xIndex, zIndex)))
						constructPillar(xIndex, zIndex, solveData.Height, solveData.Normal, solveData.SurfaceMaterial)
					end
				end
			end
		end
	end

	return gridRegion, matGrid, preGrid
end

--- Writes voxels based on the returned values of SolveRegionTerrain.
function Landmaster:BuildRegionTerrain(gridRegion: Region3, materialData: TerrainData<Enum.Material>, precisionData: TerrainData<number>)
	-- print("REGION", gridRegion)
	-- print("SIZE", gridRegion.Size)
	-- print("MAT", materialData)
	
	Terrain:WriteVoxels(
		gridRegion,
		4,
		materialData,
		precisionData
	)
	return nil
end

return Landmaster