--!strict
local Package = script
local Packages = Package.Parent
local Terrain = workspace.Terrain
local TerrainUtil = require(script.Terrain)

local Solver = require(script.Solver)
local Types = require(Package.Types)

local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

--- @class Landmaster
--- A configurable worker that can solve and build terrain.
local Landmaster = {}
Landmaster.__index = Landmaster

--- Cleans up landmaster.
function Landmaster:Destroy()
	self:Clear()
	self._Maid:Destroy()
	for k, v in pairs(self) do
		self[k] = nil
	end
	setmetatable(self, nil)
end

--- Clones a landmaster.
function Landmaster:Clone()

end

--- Constructs a landmaster.
function Landmaster.new(config: Types.LandmasterConfigData)
	TerrainUtil.clear()
	local self = {
		_Config = config,
		Solver = Solver.new(config),
		_Maid = _Maid.new(),
	}
	setmetatable(self, Landmaster)

	return self :: any
end

function Landmaster:Clear()
	TerrainUtil.clear()
	self._Maid:DoCleaning()
end

function Landmaster:Debug(map: _Math.NoiseSolver, resolution: number, scale: number):Frame
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

--- Constructs a region.
function Landmaster:BuildRegion(region: Region3): Model
	local start = region.CFrame.Position - region.Size/2
	local finish = region.CFrame.Position + region.Size/2

	start = Terrain:WorldToCell(start) * 4
	finish = Terrain:WorldToCell(finish) * 4

	local regionModel = Instance.new("Model")

	local anchor = Instance.new("Part")
	anchor.Name = "Anchor"
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.Locked = true
	anchor.Size = finish - start
	anchor.Position = start + anchor.Size/2
	anchor.Parent = regionModel

	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Parent = anchor
	selectionBox.Adornee = anchor
	
	regionModel.PrimaryPart = anchor

	for x=start.X, finish.X, 4 do
		task.wait()
		for z=start.Z, finish.Z, 4 do
			local position = Vector2.new(x,z)*4
			local normalizedCoordinates = self.Solver:GetNormalizedCoordinatesFromPosition(position)
			local heightAlpha = self.Solver:GetHeightAlpha(normalizedCoordinates)
			local normalAlpha = self.Solver:GetNormalAlpha(normalizedCoordinates)
			local surfaceMaterial = self.Solver:GetSurfaceMaterial(normalizedCoordinates)

			local heightCeiling: number = self._Config.HeightCeiling
			local waterHeight: number = self._Config.WaterHeight

			TerrainUtil.fillToHeightAlpha(position, surfaceMaterial, heightAlpha, 4, waterHeight, heightCeiling, normalAlpha)
		end
	end

	return regionModel
end

return Landmaster