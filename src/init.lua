--!strict
local Package = script
local Packages = Package.Parent
local Terrain = workspace.Terrain

local Solver = require(script.Solver)
local Types = require(Package.Types)

local _Maid = require(Packages.Maid)
local NoiseUtil = require(Packages.NoiseUtil)
local GeometryUtil = require(Packages.GeometryUtil)

export type NoiseSolver = NoiseUtil.NoiseSolver
export type LandmasterConfigData = Types.LandmasterConfigData
export type TerrainData<T> = Types.TerrainData<T>
export type NoiseMap<T> = Types.NoiseMap<T>
export type PropTemplateData = Types.PropTemplateData
export type TerrainColumnData = Types.TerrainColumnData
export type MapSolver = Solver.MapSolver
export type Alpha = number
export type PropSolveData = Types.PropSolveData

export type Landmaster = {
	__index: Landmaster,
	_Maid: _Maid.Maid,
	_Config: LandmasterConfigData,
	_Solver: MapSolver,
	_PropBallots: {[Enum.Material]: {[number]: number}},
	new: (LandmasterConfigData) -> Landmaster,
	Destroy: (Landmaster) -> nil,
	Debug: (self: Landmaster, map: NoiseUtil.NoiseSolver, resolution: number, scale: number) -> Frame,
	GetTerrainColumnData: (self: Landmaster, position: Vector3) -> TerrainColumnData,
	GetMap: Solver.GetMap<Landmaster>,
	SetMap: Solver.SetMap<Landmaster>,
	SolveRegionTerrain: (self: Landmaster, region:Region3, scale: Alpha?) -> (Region3, TerrainData<Enum.Material>, TerrainData<number>, {[string]: TerrainColumnData}),
	BuildRegionTerrain: (self: Landmaster, gridRegion: Region3, materialData: TerrainData<Enum.Material>, precisionData: TerrainData<number>) -> nil,
	Decorate: (self: Landmaster, region:Region3, columnMap: {[string]: TerrainColumnData}) -> {[number]: Instance},
}

-- private functions
function worldToCell(position: Vector3): Vector3
	return Vector3.new(
		math.round(position.X/4),
		math.round(position.Y/4),
		math.round(position.Z/4)
	)
end

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
function Landmaster:GetMap(key: string): any
	return self._Solver:GetMap(key :: any) :: any
end

--- Sets a noise map for usage.
function Landmaster:SetMap(key: string, map: any): nil
	self._Solver:SetMap(key :: any, map)
	return nil
end

--- Constructs a landmaster.
function Landmaster.new(config: LandmasterConfigData): Landmaster

	local propBallotLists = {}
	
	for mat, tempList in pairs(config.Props or {}) do
		propBallotLists[mat] = {}
		local netScarcity = 0
		local minScarcity = math.huge
		for i, tempData: PropTemplateData in ipairs(tempList) do
			minScarcity = math.min(tempData.Scarcity, minScarcity)
			netScarcity += tempData.Scarcity
		end
		for i, tempData: PropTemplateData in ipairs(tempList) do
			for j=1, math.round(tempData.Scarcity * math.ceil(netScarcity/minScarcity)) do
				table.insert(propBallotLists[mat], i)
			end
		end
	end


	-- Terrain:Clear()
	local self = {
		_Config = config,
		_PropBallots = propBallotLists,
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
			local v = map:Get(a)
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
	-- local columnMap = self:GetMap("Prop")

	local heightAlpha: number = heightMap(normalizedCoordinates)
	local normal = normalMap(normalizedCoordinates)
	local surfaceMaterial = materialMap(normalizedCoordinates)
	-- local prop = columnMap(normalizedCoordinates)
	local heightCeiling: number = self._Config.HeightCeiling
	local height = heightAlpha * heightCeiling

	return {
		Position = Vector3.new(
			columnPosition.X, 
			height,
			columnPosition.Z
		),
		Height = height,
		SurfaceMaterial = surfaceMaterial,
		Normal = normal,
		Prop = nil,--prop,
	}
end

function getSmoothness(height: number)
	return (height - math.floor(height/4)*4)/4
end

--- Given a world region3 it constructs a grid normalized region and the material + precision data tables needed for Terrain:WriteVoxels(). Should be parallel safe. As 
function Landmaster:SolveRegionTerrain(region:Region3, scale: number?): (Region3, TerrainData<Enum.Material>, TerrainData<number>, {[string]: Types.TerrainColumnData})
	scale = scale or 1
	assert(scale ~= nil)

	local start = region.CFrame.Position - region.Size/2
	local finish = region.CFrame.Position + region.Size/2 + Vector3.new(4,0,0)

	start = worldToCell(start) * 4
	finish = worldToCell(finish) * 4

	local originPosition = Vector2.new(start.X, start.Z)*4
	
	local heightCeiling: number = self._Config.HeightCeiling
	local waterHeight: number = self._Config.WaterHeight


	local regStart = worldToCell(Vector3.new(originPosition.X, 0, originPosition.Y))
	local regSize = Vector2.new(finish.X - start.X, finish.Z - start.Z)
	local gridRegion = Region3.new(
		regStart,
		regStart + Vector3.new(regSize.X, heightCeiling, regSize.Y)
	):ExpandToGrid(4)

	local rAlpha = (Vector2.new(regStart.X, regStart.Z))/(regSize/4)
	local regionWeight = 0.5 + math.clamp(
		math.noise(
			rAlpha.X,
			rAlpha.Y
		),
		-1,
		1
	)*0.5 + 0.01
	local rng = Random.new(self._Config.Seed * regionWeight)
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
	local layerCount = math.ceil(gridRegion.Size.Y/4)
	local xCount = math.ceil(gridRegion.Size.X/4)
	local zCount = math.ceil(gridRegion.Size.Z/4)
	local materialGrid = create3dTable(Vector3.new(xCount,layerCount,zCount))
	local precisionGrid = create3dTable(Vector3.new(xCount,layerCount,zCount))
	local surfaceThickness = 8

	local increment = math.floor(1/scale)

	local importantXIndeces = {}
	local importantZIndeces = {}
	local columnMap: {[string]: Types.TerrainColumnData} = {}
	local allAir = true

	local function constructPillar(xIndex: number, zIndex: number, height: number, normal: number, surfaceMaterial: Enum.Material)
		if xIndex <= xCount and zIndex <= zCount then
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
					if focusAltitude < waterHeight and self._Config.WaterEnabled then
						material = Enum.Material.Water
					else
						material = Enum.Material.Air
					end
				end
	
				local precision = if distFromSurface < 4 then distFromSurface/4 else 1
				materialGrid[xIndex][yIndex][zIndex] = material
				precisionGrid[xIndex][yIndex][zIndex] = if material == Enum.Material.Water then 0 else precision
				if material ~= Enum.Material.Air or (material == Enum.Material.Water and self._Config.WaterEnabled) or precisionGrid[xIndex][yIndex][zIndex] > 0 then
					allAir = false
				end
			end
		end
	end
	
	for xIndex=1, xCount+1 do
		if xIndex % increment == 0 or (xIndex == xCount or xIndex == 1) then
			table.insert(importantXIndeces, xIndex)
			for zIndex=1, zCount do
				if zIndex % increment == 0 or (zIndex == zCount or zIndex == 1) then
					if #importantXIndeces == 1 then
						table.insert(importantZIndeces, zIndex)
					end
					local columnPosition = regStart + Vector3.new(xIndex, 0, zIndex)*4

					columnMap[tostring(Vector2.new(xIndex, zIndex))] = self:GetTerrainColumnData(columnPosition)
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

				local function triLerp(aAlpha: number, aVal: number, bAlpha: number, bVal: number, cAlpha: number, cVal: number): number
					return aAlpha * aVal + bAlpha * bVal + cAlpha * cVal
				end

				local function getProp(surfaceMaterial: Enum.Material): PropSolveData?
					if self._PropBallots[surfaceMaterial] then
						local prop: PropTemplateData?
						local propScale = rng:NextNumber()
						local limit = #self._PropBallots[surfaceMaterial]
						if limit > 0 then
							local index = rng:NextInteger(1,limit)
							local propIndex = self._PropBallots[surfaceMaterial][index]
							
							prop = self._Config.Props[surfaceMaterial][propIndex]
							assert(prop ~= nil)
							
							local val = rng:NextNumber()
							local rot = rng:NextNumber()
							if prop.Scarcity >= val then
								return {
									Template = prop.Template,
									CFrame = CFrame.Angles(0,math.rad(rot * 360),0),
									Scale = 0.5 + propScale,
								}
							end
						end			
					end
					return nil
				end

				local function terrainLerp(pV2: Vector2, aV2: Vector2, bV2: Vector2, cV2: Vector2): Types.TerrainColumnData?
					local aKey = tostring(aV2)
					local bKey = tostring(bV2)
					local cKey = tostring(cV2)

					local aData = columnMap[aKey]
					local bData = columnMap[bKey]
					local cData = columnMap[cKey]

					local point = Vector3.new(pV2.X, 0, pV2.Y)
					local a = Vector3.new(aV2.X, 0, aV2.Y)
					local b = Vector3.new(bV2.X, 0, bV2.Y)
					local c = Vector3.new(cV2.X, 0, cV2.Y)
					
					local area = GeometryUtil.getTriangleArea(a,b,c)

					local cAlpha = GeometryUtil.getTriangleArea(a,b,point)/area
					if cAlpha ~= cAlpha then cAlpha = 0 end

					local aAlpha = GeometryUtil.getTriangleArea(b,c,point)/area
					if aAlpha ~= aAlpha then aAlpha = 0 end
	
					local bAlpha = GeometryUtil.getTriangleArea(c,a,point)/area
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
			

					local height = triLerp(
						aAlpha,
						aData.Height,
						bAlpha,
						bData.Height,
						cAlpha,
						cData.Height
					)

					local normal = triLerp(
						aAlpha,
						aData.Normal,
						bAlpha,
						bData.Normal,
						cAlpha,
						cData.Normal
					)

					local colData = {
						Position = Vector3.new(
							pV2.X,
							height,
							pV2.Y
						),
						Height = height,
						SurfaceMaterial = surfaceMaterial,
						Normal = normal,
						Prop = nil,
					}
					
					return colData
				end
				
				for xIndex=prevXIndex, nextXIndex do
					for zIndex=prevZIndex, nextZIndex do
	
						local point = Vector2.new(xIndex, zIndex)
						local colData = terrainLerp(point, q1Point, q2Point, q3Point)
						if not colData then
							colData = terrainLerp(point, q1Point, q4Point, q3Point)
						end
						
						assert(colData ~= nil, "Bad solve data: "..tostring(Vector2.new(xIndex, zIndex)))
						columnMap[tostring(point)] = colData
						constructPillar(xIndex, zIndex, colData.Height, colData.Normal, colData.SurfaceMaterial)
					end
				end
				for k, colData: TerrainColumnData in pairs(columnMap) do
					local pV2 = Vector2.new(colData.Position.X, colData.Position.Z)
					-- local uV2 = pV2 + Vector2.new(0,1)
					-- local rV2 = pV2 + Vector2.new(1,0)
					local ruV2 = pV2 + Vector2.new(1,1)
					-- local uColData: TerrainColumnData? = columnMap[tostring(uV2)]
					-- local rColData: TerrainColumnData? = columnMap[tostring(rV2)]
					local ruColData: TerrainColumnData? = columnMap[tostring(ruV2)]

					if colData and ruColData then
						local smooth = getSmoothness(colData.Height)
						-- local uSmooth = getSmoothness(uColData.Height)
						-- local rSmooth = getSmoothness(rColData.Height)
						local ruSmooth = getSmoothness(ruColData.Height)

						if ruColData.Height > colData.Height and ruColData.Height-colData.Height <= 4 then
							ruSmooth = 1
						elseif ruColData.Height < colData.Height and colData.Height-ruColData.Height <= 4 then
							ruSmooth = 0
						end
						-- local rMidSmooth = smooth + (rSmooth - smooth) * 0.5
						-- local uMidSmooth = smooth + (uSmooth - smooth) * 0.5
						-- local finalSmooth = rMidSmooth + (uMidSmooth - rMidSmooth) * 0.5
						local finalSmooth = smooth + (ruSmooth - smooth) * 0.5
						local baseHeight = math.floor(colData.Height/4)*4
						colData.Position = Vector3.new(pV2.X,baseHeight+finalSmooth*4,pV2.Y)
						colData.Prop = getProp(colData.SurfaceMaterial)
					end
				end
			end
		end
	end

	if allAir then
		return Region3.new(Vector3.new(0,0,0), Vector3.new(0,0,0)), {}, {}, columnMap
	else
		return gridRegion, materialGrid, precisionGrid, columnMap
	end
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

function Landmaster:Decorate(region:Region3, columnMap: {[string]: Types.TerrainColumnData})
	-- print("\nDECORATION")
	local props: {[number]: Instance} = {}
	local start = region.CFrame.Position - region.Size/2
	for k, columnData in pairs(columnMap) do
		if columnData.Prop then
			local propData = columnData.Prop
			local prop = propData.Template:Clone()
			local cf = propData.CFrame + start + (columnData.Position * Vector3.new(4,1,4)) + Vector3.new(2,-4,2)
			prop:PivotTo(cf)

			for j, dep in ipairs(prop:GetDescendants()) do
				if dep:IsA("BasePart") then
					local offset = cf:Inverse() * dep.CFrame
					dep.Size *= propData.Scale
					dep.CFrame = cf * CFrame.fromMatrix(
						offset.Position * propData.Scale,
						offset.XVector,
						offset.YVector,
						offset.ZVector
					)
				end
			end
			table.insert(props, prop)
		-- else
			-- print("KEY", k)
		end
	end

	return props
end


return Landmaster