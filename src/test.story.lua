--!strict
local Package = script.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local RunService = game:GetService("RunService")

return function(coreGui: ScreenGui)
	local maid = _Maid.new()
	
	task.spawn(function()
		local target = workspace:WaitForChild("Target")
		local _Module = require(script.Parent)

		local mapFolder = if workspace:FindFirstChild("Map") then workspace.Map else Instance.new("Folder")
		mapFolder.Name = "Map"
		mapFolder.Parent = workspace

		local landmaster = _Module.new({
			Seed = 1229534,
			Width = 1024*2,
			HeightCeiling = 100,
			WaterHeight = 30,
			Frequency = 4,
			Props = {},
			WaterEnabled = true,
			Origin = Vector2.new(0,0),
		})

		local pos = Vector3.new(0,0,0)
		local size = Vector3.new(1,1,1)
		-- local updateStarted = false


		local function update(dT: number)
			if size == target.Size and pos == target.Position then return end
			-- if updateStarted then return end
			-- updateStarted = true
			pos = target.Position
			size = target.Size
			local startTick = tick()
			local region, matGrid, preGrid, solveMap = landmaster:SolveRegionTerrain(Region3.new(pos - size/2, pos + size/2), 2^-1)

			landmaster:BuildRegionTerrain(region, matGrid, preGrid, solveMap)

			print("Duration", (tick() - startTick))
			-- updateStarted = false
		end
		local index = 0
		local function _debug(map)
			local res = 100
			local scale = 2
			local frame = landmaster:Debug(map, res, scale)
			maid:GiveTask(frame)
			frame.Parent = coreGui
			frame.Position = UDim2.fromOffset(scale*res*index, 0)
			index += 1
		end
		-- _debug(landmaster.Solver.Maps.Normal)
		-- _debug(landmaster.Solver.Maps.Height)
		maid:GiveTask(RunService.RenderStepped:Connect(update))
		maid:GiveTask(landmaster)
	end)
	
	return function()
		maid:Destroy()
	end
end