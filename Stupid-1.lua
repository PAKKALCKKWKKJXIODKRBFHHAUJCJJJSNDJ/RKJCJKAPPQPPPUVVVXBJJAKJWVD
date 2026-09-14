local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

local CurrentRooms = workspace:WaitForChild("CurrentRooms")
local LatestRoom = RS:WaitForChild("GameData"):WaitForChild("LatestRoom")

local function GetGitSound(GithubSnd, SoundName)
	if not isfile(SoundName .. ".mp3") then
		writefile(SoundName .. ".mp3", game:HttpGet(GithubSnd))
	end

	local sound = Instance.new("Sound")
	sound.SoundId = (getcustomasset or getsynasset)(SoundName .. ".mp3")
	return sound
end

local spawn = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Stupid1VeryAccurateSpawn.mp3?raw=true",
	"gfawtujbvhjhv"
)

spawn.Volume = 1
spawn.Name = "spawn"
spawn.PlaybackSpeed = 1
spawn.RollOffMaxDistance = 70

local despawn = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Stupid1VeryAccurateDespawn.mp3?raw=true",
	"gfdtyhvchjjhcfgvv"
)

despawn.Volume = 1
despawn.Name = "despawn"
despawn.PlaybackSpeed = 1
despawn.RollOffMaxDistance = 200

local url =
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_16259573036_Model_Stupid-1_1789379898.txt"

local path = "STUPID1JJCJJD"

if not isfile(path) then
	writefile(path, game:HttpGet(url))
end

local model = game:GetObjects(getcustomasset(path))[1]

if not model then
	return
end

model.Parent = workspace

local entityHRP =
	model:FindFirstChild("HumanoidRootPart", true)

if not entityHRP or not entityHRP:IsA("BasePart") then
	model:Destroy()
	return
end

entityHRP.Anchored = true

spawn.Parent = entityHRP
despawn.Parent = entityHRP

spawn:Play()

------------------------------------------------
-- STATE
------------------------------------------------

local despawning = false
local tween = nil
local wanderRunning = true

------------------------------------------------
-- GET FLOOR
------------------------------------------------

local function GetFloorBelow()
	if despawning then
		return nil
	end

	if not entityHRP
		or not entityHRP.Parent then
		return nil
	end

	local params = RaycastParams.new()

	params.FilterType =
		Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances = {
		model
	}

	local result =
		workspace:Raycast(
			entityHRP.Position,
			Vector3.new(0, -1000, 0),
			params
		)

	if result then
		local part = result.Instance

		if part:IsA("BasePart")
			and part.Name == "Floor" then
			return part
		end

		local parentModel =
			part:FindFirstAncestorWhichIsA("Model")

		if parentModel then
			local floor =
				parentModel:FindFirstChild(
					"Floor",
					true
				)

			if floor
				and floor:IsA("BasePart") then
				return floor
			end
		end
	end

	return nil
end

local function GetLatestRoomFloor()
	if despawning then
		return nil
	end

	local room =
		CurrentRooms:FindFirstChild(
			tostring(LatestRoom.Value)
		)

	if not room then
		return nil
	end

	local parts =
		room:FindFirstChild("Parts")

	if not parts then
		return nil
	end

	local floor =
		parts:FindFirstChild("Floor")

	if floor
		and floor:IsA("BasePart")
		and floor.Parent then
		return floor
	end

	return nil
end

------------------------------------------------
-- MODEL SIZE
------------------------------------------------

local boxCF, boxSize =
	model:GetBoundingBox()

------------------------------------------------
-- GET RANDOM TARGET
------------------------------------------------

local function GetRandomFloorTarget()
	if despawning
		or not entityHRP
		or not entityHRP.Parent then
		return nil
	end

	local floor =
		GetFloorBelow()

	if not floor
		or not floor.Parent then

		floor =
			GetLatestRoomFloor()
	end

	if not floor
		or not floor:IsA("BasePart")
		or not floor.Parent then
		return nil
	end

	local floorCF = floor.CFrame
	local floorSize = floor.Size

	local maxX =
		math.max(
			0,
			floorSize.X / 2 - boxSize.X / 2
		)

	local maxZ =
		math.max(
			0,
			floorSize.Z / 2 - boxSize.Z / 2
		)

	local x =
		(math.random() * 2 - 1) * maxX

	local z =
		(math.random() * 2 - 1) * maxZ

	local y =
		floorSize.Y / 2
		+ boxSize.Y / 2
		+ 1

	local pos =
		floorCF:PointToWorldSpace(
			Vector3.new(
				x,
				y,
				z
			)
		)

	return CFrame.new(pos)
		* entityHRP.CFrame.Rotation
end

------------------------------------------------
-- INITIAL POSITION
------------------------------------------------

local initialTarget =
	GetRandomFloorTarget()

if not initialTarget then
	model:Destroy()
	return
end

local pivotCF =
	model:GetPivot()

local pivotToBox =
	pivotCF:ToObjectSpace(boxCF)

local targetBoxCF =
	CFrame.new(initialTarget.Position)
	* CFrame.fromMatrix(
		Vector3.zero,
		boxCF.RightVector,
		boxCF.UpVector,
		-boxCF.LookVector
	)

local targetPivot =
	targetBoxCF
	* pivotToBox:Inverse()

model:PivotTo(targetPivot)

------------------------------------------------
-- WANDER
------------------------------------------------

task.spawn(function()
	while wanderRunning
		and not despawning
		and model
		and model.Parent
		and entityHRP
		and entityHRP.Parent do

		-- Đứng yên một khoảng random trước khi đi
		task.wait(
			math.random(300, 500) / 100
		)

		if not wanderRunning
			or despawning
			or not model
			or not model.Parent
			or not entityHRP
			or not entityHRP.Parent then
			break
		end

		local targetCF =
			GetRandomFloorTarget()

		if targetCF then
			local distance =
				(
					targetCF.Position
					- entityHRP.Position
				).Magnitude

			local speed = 30

			local duration =
				math.max(
					0.4,
					distance / speed
				)

			tween =
				TweenService:Create(
					entityHRP,
					TweenInfo.new(
						duration,
						Enum.EasingStyle.Linear
					),
					{
						CFrame = targetCF
					}
				)

			tween:Play()

			tween.Completed:Wait()

			tween = nil
		end
	end
end)

------------------------------------------------
-- IMAGE SHAKE
------------------------------------------------

local images = {}

for _, obj in ipairs(
	model:GetDescendants()
) do
	if obj:IsA("ImageLabel") then
		images[#images + 1] = {
			object = obj,
			position = obj.Position
		}
	end
end

local imageTimer = 0
local shakeDelay = 0.5 / 100

local imageConnection

imageConnection =
	RunService.RenderStepped:Connect(
		function(dt)

			if despawning then
				return
			end

			if not model
				or not model.Parent then

				if imageConnection then
					imageConnection:Disconnect()
					imageConnection = nil
				end

				return
			end

			imageTimer += dt

			if imageTimer >= shakeDelay then
				imageTimer -= shakeDelay

				for _, info in ipairs(images) do
					local image =
						info.object

					if image
						and image.Parent then

						local pos =
							info.position

						local x =
							math.random(-3, 3)
							/ 100

						local y =
							math.random(-3, 3)
							/ 100

						image.Position =
							UDim2.new(
								pos.X.Scale + x,
								pos.X.Offset,
								pos.Y.Scale + y,
								pos.Y.Offset
							)

						image.Rotation =
							math.random(-3, 3)
					end
				end
			end
		end
	)

------------------------------------------------
-- DESPAWN
------------------------------------------------

local function Despawn()
	if despawning then
		return
	end

	despawning = true
	wanderRunning = false

	if tween then
		tween:Cancel()
		tween = nil
	end

	if imageConnection then
		imageConnection:Disconnect()
		imageConnection = nil
	end

	if model and model.Parent then
		for _, obj in ipairs(
			model:GetDescendants()
		) do

			if obj:IsA("Sound") then
				if obj ~= despawn then
					obj.Volume = 0
					obj:Stop()
				end

			elseif obj:IsA("BillboardGui") then
				obj.Enabled = false

			elseif obj:IsA("PointLight")
				or obj:IsA("SpotLight")
				or obj:IsA("SurfaceLight") then

				obj.Enabled = false
			end
		end
	end

	if despawn
		and despawn.Parent then

		despawn.Volume = 1
		despawn:Play()

		despawn.Ended:Once(function()
			if model then
				model:Destroy()
			end

			model = nil
			entityHRP = nil
			tween = nil
		end)

	else
		if model then
			model:Destroy()
		end

		model = nil
		entityHRP = nil
		tween = nil
	end
end

------------------------------------------------
-- 60 SECOND LIFETIME
------------------------------------------------

task.delay(40, function()
	if model
		and model.Parent
		and not despawning then

		Despawn()
	end
end)
