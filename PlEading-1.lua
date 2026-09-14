local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local oklah

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

------------------------------------------------
-- SOUNDS
------------------------------------------------

local spawn = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/PIEading1VeryAccurateSpawn.mp3?raw=true",
	"vcdfgxdhjbvgg"
)

spawn.Volume = 1
spawn.Name = "spawn"
spawn.PlaybackSpeed = 1
spawn.RollOffMaxDistance = 70

local ambient = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/PIEading1VeryAccurateAmbient.mp3?raw=true",
	"hvjdkxjxhcj"
)

ambient.Volume = 1
ambient.Name = "ambient"
ambient.Looped = true
ambient.PlaybackSpeed = 1
ambient.RollOffMaxDistance = 70

local despawn = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/PIEading1VeryAccurateDespawn.mp3?raw=true",
	"gdyhvhjbvhjbvhh"
)

despawn.Volume = 1
despawn.Name = "despawn"
despawn.PlaybackSpeed = 1
despawn.RollOffMaxDistance = 200

------------------------------------------------
-- MODEL
------------------------------------------------

local url =
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_117270460643322_Model_E-1jjxkdx_1789217304.txt"

local path = "E-1jjcjdjdjjjxhj"

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

if not entityHRP
	or not entityHRP:IsA("BasePart") then

	model:Destroy()
	return
end

entityHRP.Anchored = true

spawn.Parent = entityHRP
ambient.Parent = entityHRP
despawn.Parent = entityHRP

ambient:Play()

local bla = entityHRP.Ambient
bla.Playing = false

spawn:Play()

------------------------------------------------
-- STATE
------------------------------------------------

local despawning = false
local randomLoopRunning = true
local tween = nil

local imageConnection = nil
local characterConnection = nil
local despawnConnection = nil
local conditionConnection = nil
local promptConnection = nil

local promptTriggered = false
local oklahRunning = false

local floor = nil

------------------------------------------------
-- CHARACTER
------------------------------------------------

local charHRP
local hum

local function UpdateChar()
	char = player.Character or player.CharacterAdded:Wait()

	charHRP =
		char:FindFirstChild("HumanoidRootPart")

	hum =
		char:FindFirstChildOfClass("Humanoid")
end

UpdateChar()

characterConnection =
	player.CharacterAdded:Connect(function()
		task.wait()

		if despawning then
			return
		end

		UpdateChar()
	end)

------------------------------------------------
-- INITIAL FLOOR
------------------------------------------------

local room =
	CurrentRooms:FindFirstChild(
		tostring(LatestRoom.Value)
	)

if room then
	local parts =
		room:FindFirstChild("Parts")

	floor =
		parts and parts:FindFirstChild("Floor")
end

if not floor
	or not floor:IsA("BasePart") then

	if characterConnection then
		characterConnection:Disconnect()
		characterConnection = nil
	end

	model:Destroy()
	return
end

------------------------------------------------
-- MODEL SIZE
------------------------------------------------

local boxCF, boxSize =
	model:GetBoundingBox()

------------------------------------------------
-- INITIAL POSITION
------------------------------------------------

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

local localX =
	(math.random() * 2 - 1) * maxX

local localZ =
	(math.random() * 2 - 1) * maxZ

local localY =
	floorSize.Y / 2
	+ boxSize.Y / 2
	+ 1

local boxPos =
	floorCF:PointToWorldSpace(
		Vector3.new(
			localX,
			localY,
			localZ
		)
	)

local boxRotation =
	CFrame.fromMatrix(
		Vector3.zero,
		floorCF.RightVector,
		floorCF.UpVector,
		-floorCF.LookVector
	)

local targetBoxCF =
	CFrame.new(boxPos)
	* boxRotation

local pivotCF =
	model:GetPivot()

local pivotToBox =
	pivotCF:ToObjectSpace(boxCF)

local targetPivot =
	targetBoxCF
	* pivotToBox:Inverse()

model:PivotTo(targetPivot)

------------------------------------------------
-- PROMPT
------------------------------------------------

local prompt = Instance.new("ProximityPrompt")

prompt.Name = "EntityPrompt"
prompt.ActionText = "KICK THE BABY"
prompt.ObjectText = "PlEading-1"
prompt.MaxActivationDistance = 20
prompt.RequiresLineOfSight = false
prompt.HoldDuration = 0
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.Parent = entityHRP

------------------------------------------------
-- GET FLOOR BELOW
------------------------------------------------

local function GetFloorBelow()
	if despawning then
		return nil
	end

	if not entityHRP
		or not entityHRP.Parent then
		return nil
	end

	local params =
		RaycastParams.new()

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
		local part =
			result.Instance

		if part:IsA("BasePart")
			and part.Name == "Floor" then

			return part
		end

		local parentModel =
			part:FindFirstAncestorWhichIsA(
				"Model"
			)

		if parentModel then
			local f =
				parentModel:FindFirstChild(
					"Floor",
					true
				)

			if f
				and f:IsA("BasePart") then

				return f
			end
		end
	end

	return nil
end

------------------------------------------------
-- GET LATEST ROOM FLOOR
------------------------------------------------

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

	local f =
		parts:FindFirstChild("Floor")

	if f
		and f:IsA("BasePart")
		and f.Parent then

		return f
	end

	return nil
end

------------------------------------------------
-- RANDOM FLOOR TARGET
------------------------------------------------

local function GetRandomFloorTarget()
	if despawning
		or not entityHRP
		or not entityHRP.Parent then

		return nil
	end

	local f =
		GetFloorBelow()

	if f and f.Parent then
		floor = f
	elseif not floor
		or not floor.Parent then

		floor =
			GetLatestRoomFloor()

		f = floor
	else
		f = floor
	end

	if not f
		or not f:IsA("BasePart")
		or not f.Parent then

		return nil
	end

	local _, size =
		model:GetBoundingBox()

	local fCF =
		f.CFrame

	local fSize =
		f.Size

	local xMax =
		math.max(
			0,
			fSize.X / 2 - size.X / 2
		)

	local zMax =
		math.max(
			0,
			fSize.Z / 2 - size.Z / 2
		)

	local x =
		(math.random() * 2 - 1)
		* xMax

	local z =
		(math.random() * 2 - 1)
		* zMax

	local y =
		fSize.Y / 2
		+ size.Y / 2
		+ 1

	local pos =
		fCF:PointToWorldSpace(
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
-- CLEANUP
------------------------------------------------

local function Cleanup()
	if despawnConnection then
		despawnConnection:Disconnect()
		despawnConnection = nil
	end

	if promptConnection then
		promptConnection:Disconnect()
		promptConnection = nil
	end

	if conditionConnection then
		conditionConnection:Disconnect()
		conditionConnection = nil
	end

	if prompt then
		prompt:Destroy()
		prompt = nil
	end

	if model then
		model:Destroy()
	end

	model = nil
	entityHRP = nil
	char = nil
	charHRP = nil
	hum = nil
	floor = nil
	tween = nil
	randomLoopRunning = false
end

------------------------------------------------
-- DESPAWN
------------------------------------------------

local function Despawn()
	if despawning then
		return
	end

	despawning = true
	randomLoopRunning = false

	if tween then
		tween:Cancel()
		tween = nil
	end

	if imageConnection then
		imageConnection:Disconnect()
		imageConnection = nil
	end

	if characterConnection then
		characterConnection:Disconnect()
		characterConnection = nil
	end

	if conditionConnection then
		conditionConnection:Disconnect()
		conditionConnection = nil
	end

	if promptConnection then
		promptConnection:Disconnect()
		promptConnection = nil
	end

	if prompt then
		prompt.Enabled = false
	end

	if despawn and despawn.Parent then
		despawn.Volume = 1
		despawn:Play()
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

	task.delay(2, function()
		Cleanup()
	end)
end

------------------------------------------------
-- OKLAH
------------------------------------------------

oklah = function()
	if oklahRunning then
		return
	end

	if not model
		or not model.Parent
		or not entityHRP
		or not entityHRP.Parent then
		return
	end

	oklahRunning = true

	if prompt then
		prompt.Enabled = false
	end

	despawning = true
	randomLoopRunning = false

	if tween then
		tween:Cancel()
		tween = nil
	end

	if conditionConnection then
		conditionConnection:Disconnect()
		conditionConnection = nil
	end

	if promptConnection then
		promptConnection:Disconnect()
		promptConnection = nil
	end

	if characterConnection then
		characterConnection:Disconnect()
		characterConnection = nil
	end

	if imageConnection then
		imageConnection:Disconnect()
		imageConnection = nil
	end

	for _, obj in ipairs(
		model:GetDescendants()
	) do

		if obj:IsA("ImageLabel") then
			obj.Image =
				"rbxassetid://135683894119025"
		end
	end

	task.delay(3, function()

		if model and model.Parent then
			for _, obj in ipairs(
				model:GetDescendants()
			) do

				if obj:IsA("Sound") then
					if obj ~= despawn then
						obj:Stop()
						obj.Volume = 0
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

			despawn.Ended:Wait()
		end

		Cleanup()
	end)
end

------------------------------------------------
-- PROMPT TRIGGER
------------------------------------------------

promptConnection =
	prompt.Triggered:Connect(function(triggerPlayer)

		if triggerPlayer ~= player then
			return
		end

		if despawning
			or promptTriggered
			or not model
			or not model.Parent
			or not entityHRP
			or not entityHRP.Parent then

			return
		end

		promptTriggered = true
		prompt.Enabled = false

		------------------------------------------------
		-- CANCEL ENTITY MOVEMENT
		------------------------------------------------

		randomLoopRunning = false

		if tween then
			tween:Cancel()
			tween = nil
		end

		------------------------------------------------
		-- UPDATE CHARACTER
		------------------------------------------------

		UpdateChar()

		if not charHRP
			or not charHRP.Parent then

			promptTriggered = false
			prompt.Enabled = true
			randomLoopRunning = true
			return
		end

		------------------------------------------------
		-- ANCHOR PLAYER
		------------------------------------------------

		charHRP.Anchored = true

		------------------------------------------------
		-- TARGET POSITION
		------------------------------------------------

		local targetPosition =
			entityHRP.Position
			+ entityHRP.CFrame.LookVector * 4

		local targetCFrame =
			CFrame.lookAt(
				targetPosition,
				entityHRP.Position
			)

		------------------------------------------------
		-- TWEEN PLAYER
		------------------------------------------------

		local playerTween =
			TweenService:Create(
				charHRP,
				TweenInfo.new(
					1,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				),
				{
					CFrame = targetCFrame
				}
			)

		playerTween:Play()
		playerTween.Completed:Wait()

		------------------------------------------------
		-- WAIT 1 SECOND
		------------------------------------------------

		task.wait(1)

		------------------------------------------------
		-- UNANCHOR PLAYER
		------------------------------------------------

		if charHRP
			and charHRP.Parent then

			charHRP.Anchored = false
		end

		------------------------------------------------
		-- CALL OKLAH
		------------------------------------------------

		oklah()
	end)

------------------------------------------------
-- 50 SECOND LIFETIME
------------------------------------------------

task.delay(50, function()
	if model
		and model.Parent
		and not despawning then

		Despawn()
	end
end)

------------------------------------------------
-- CHECK SPOTLIGHT
------------------------------------------------

local function HasSpotLight()
	if despawning then
		return false
	end

	if not char
		or not char.Parent then

		return false
	end

	for _, obj in ipairs(
		char:GetDescendants()
	) do

		if obj:IsA("SpotLight")
			and obj.Enabled then

			return true
		end
	end

	return false
end

------------------------------------------------
-- CHECK LOOKING AT ENTITY
------------------------------------------------

local function LookingAtEntity()
	if despawning then
		return false
	end

	if not entityHRP
		or not entityHRP.Parent then

		return false
	end

	local camera =
		workspace.CurrentCamera

	if not camera then
		return false
	end

	local camPos =
		camera.CFrame.Position

	local targetPos =
		entityHRP.Position

	local offset =
		targetPos - camPos

	if offset.Magnitude <= 0 then
		return true
	end

	local direction =
		offset.Unit

	local dot =
		camera.CFrame.LookVector:Dot(
			direction
		)

	if dot < 0.8 then
		return false
	end

	local params =
		RaycastParams.new()

	params.FilterType =
		Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances = {
		char,
		model
	}

	local result =
		workspace:Raycast(
			camPos,
			offset,
			params
		)

	if result then
		return false
	end

	return true
end

------------------------------------------------
-- SPOTLIGHT + LOOKING CHECK
------------------------------------------------

conditionConnection =
	RunService.RenderStepped:Connect(
		function()

			if despawning then
				if conditionConnection then
					conditionConnection:Disconnect()
					conditionConnection = nil
				end

				return
			end

			if not model
				or not model.Parent
				or not entityHRP
				or not entityHRP.Parent then

				return
			end

			if HasSpotLight()
				and LookingAtEntity() then

				oklah()
			end
		end
	)

------------------------------------------------
-- RANDOM WANDER
------------------------------------------------

task.spawn(function()

	while randomLoopRunning
		and model
		and model.Parent
		and not despawning do

		task.wait(
			math.random(200, 300) / 100
		)

		if not randomLoopRunning
			or despawning
			or not model
			or not model.Parent then

			break
		end

		local targetCF =
			GetRandomFloorTarget()

		if targetCF
			and entityHRP
			and entityHRP.Parent
			and not despawning then

			tween =
				TweenService:Create(
					entityHRP,
					TweenInfo.new(
						2,
						Enum.EasingStyle.Linear
					),
					{
						CFrame = targetCF
					}
				)

			tween:Play()

			while tween
				and tween.PlaybackState
					== Enum.PlaybackState.Playing do

				if despawning
					or not randomLoopRunning then

					tween:Cancel()
					tween = nil
					break
				end

				RunService.Heartbeat:Wait()
			end

			if tween
				and tween.PlaybackState
					~= Enum.PlaybackState.Playing then

				tween = nil
			end
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

		obj.Image =
			"rbxassetid://135743295865108"

		images[#images + 1] = {
			object = obj,
			position = obj.Position
		}
	end
end

local imageTimer = 0
local shakeDelay = 0.005

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
							math.random(-1, 1)
							/ 100

						local y =
							math.random(-1, 1)
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
