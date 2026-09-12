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
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/XE-1_Spawn.mp3?raw=true",
	"JJCJKSLLKSHXJKDJHgcjdj"
)

spawn.Volume = 1
spawn.Name = "spawn"
spawn.PlaybackSpeed = 1
spawn.RollOffMaxDistance = 70

local hit = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/XE-1_Damage.mp3?raw=true",
	"pockkkknshckcnxjdjdx"
)

hit.Volume = 1
hit.Name = "hit"
hit.PlaybackSpeed = 1
hit.RollOffMaxDistance = 70

local despawn = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/XE-1_DeSpawn.mp3?raw=true",
	"ppajjjcjcjddkhcjkkdjx"
)

despawn.Volume = 1
despawn.Name = "despawn"
despawn.PlaybackSpeed = 1
despawn.RollOffMaxDistance = 200

local url =
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_16259573036_Model_XE-1_1789228158.txt"

local path = "XE-1KCJJDKKXHHCHJ"

if not isfile(path) then
	writefile(path, game:HttpGet(url))
end

local model = game:GetObjects(getcustomasset(path))[1]

if model then
	model.Parent = workspace

	local entityHRP =
		model:FindFirstChild("HumanoidRootPart", true)

	if not entityHRP or not entityHRP:IsA("BasePart") then
		model:Destroy()
		return
	end
	
	entityHRP.Anchored = true

	spawn.Parent = entityHRP
	hit.Parent = entityHRP
	despawn.Parent = entityHRP

	spawn:Play()

	------------------------------------------------
	-- STATE
	------------------------------------------------

	local chasing = false
	local retreating = false
	local despawning = false
	local tween

	local chaseConnection
	local imageConnection
	local characterConnection
	local despawnConnection

	local randomLoopRunning = true

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

	local floor

	if room then
		local parts = room:FindFirstChild("Parts")

		floor =
			parts and parts:FindFirstChild("Floor")
	end

	if not floor or not floor:IsA("BasePart") then
		if characterConnection then
			characterConnection:Disconnect()
		end

		model:Destroy()
		return
	end

	------------------------------------------------
	-- MODEL SIZE
	------------------------------------------------

	local boxCF, boxSize =
		model:GetBoundingBox()

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

	------------------------------------------------
	-- INITIAL POSITION
	------------------------------------------------

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
	-- HITBOX
	------------------------------------------------

	local hitbox =
		Instance.new("Part")

	hitbox.Name = "Hitbox"
	hitbox.Size =
		Vector3.new(20, 20, 20)

	hitbox.CFrame =
		entityHRP.CFrame

	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.CanQuery = true
	hitbox.CanTouch = true
	hitbox.Anchored = false
	hitbox.Massless = true

	hitbox.Parent = model

	local weld =
		Instance.new("WeldConstraint")

	weld.Part0 = entityHRP
	weld.Part1 = hitbox
	weld.Parent = hitbox

	------------------------------------------------
	-- HITBOX DETECTION
	------------------------------------------------

	local hitboxEnabled = true

	local overlapParams =
		OverlapParams.new()

	overlapParams.FilterType =
		Enum.RaycastFilterType.Include

	overlapParams.FilterDescendantsInstances = {
		char
	}

	local function InHitbox()
		if not hitboxEnabled then
			return false
		end

		if not hitbox
			or not hitbox.Parent
			or not char
			or not char.Parent then

			return false
		end

		local parts =
			workspace:GetPartsInPart(
				hitbox,
				overlapParams
			)

		return #parts > 0
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
		chasing = false
		retreating = false
		hitboxEnabled = false

		if tween then
			tween:Cancel()
			tween = nil
		end

		if chaseConnection then
			chaseConnection:Disconnect()
			chaseConnection = nil
		end

		if imageConnection then
			imageConnection:Disconnect()
			imageConnection = nil
		end

		if characterConnection then
			characterConnection:Disconnect()
			characterConnection = nil
		end

		if model and model.Parent then
			for _, obj in ipairs(model:GetDescendants()) do
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

		if despawn and despawn.Parent then
			despawn.Volume = 1

			despawnConnection =
				despawn.Ended:Connect(function()

					if despawnConnection then
						despawnConnection:Disconnect()
						despawnConnection = nil
					end

					if model then
						model:Destroy()
					end

					model = nil
					entityHRP = nil
					hitbox = nil
					char = nil
					charHRP = nil
					hum = nil
					floor = nil
					tween = nil
					chasing = nil
					retreating = nil
					randomLoopRunning = nil
					despawning = nil
				end)

			despawn:Play()
		else
			if model then
				model:Destroy()
			end

			model = nil
			entityHRP = nil
			hitbox = nil
			char = nil
			charHRP = nil
			hum = nil
			floor = nil
			tween = nil
			chasing = nil
			retreating = nil
			randomLoopRunning = nil
			despawning = nil
		end
	end

	------------------------------------------------
	-- 60 SECOND LIFETIME
	------------------------------------------------

	task.delay(60, function()
		if model
			and model.Parent
			and not despawning then

			Despawn()
		end
	end)

	------------------------------------------------
	-- LOOKING AT ENTITY
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
			camera.CFrame.LookVector:Dot(direction)

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
	-- PLAYER RUNNING / AVOIDING
	------------------------------------------------

	local lastPlayerDistance

	local function IsAvoiding()
		if not charHRP
			or not charHRP.Parent
			or not entityHRP
			or not entityHRP.Parent then

			return false
		end

		local distance =
			(
				charHRP.Position
				- entityHRP.Position
			).Magnitude

		local velocity =
			charHRP.AssemblyLinearVelocity

		local away =
			charHRP.Position
			- entityHRP.Position

		if away.Magnitude > 0 then
			away = away.Unit

			local awaySpeed =
				velocity:Dot(away)

			if awaySpeed > 7 then
				lastPlayerDistance = distance
				return true
			end
		end

		if lastPlayerDistance then
			if distance > lastPlayerDistance + 0.8 then
				lastPlayerDistance = distance
				return true
			end
		end

		lastPlayerDistance = distance

		return false
	end

	------------------------------------------------
	-- FLOOR BELOW
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
			local part = result.Instance

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
	-- LATEST ROOM FLOOR
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
	-- RANDOM FLOOR POSITION
	------------------------------------------------

	local function GetRandomFloorTarget()
	if despawning then
		return nil
	end

	local f = GetFloorBelow()

	if f and f.Parent then
		floor = f
	elseif not floor or not floor.Parent then
		floor = GetLatestRoomFloor()
		f = floor
	else
		f = floor
	end

	if not f
		or not f:IsA("BasePart")
		or not f.Parent then
		return nil
	end

	local fCF = f.CFrame
	local fSize = f.Size

	-- Hitbox 20x20x20 nên chừa 10 studs mỗi phía
	local xMax = math.max(0, fSize.X / 2 - 10)
	local zMax = math.max(0, fSize.Z / 2 - 10)

	for _ = 1, 100 do
		local x =
			(math.random() * 2 - 1) * xMax

		local z =
			(math.random() * 2 - 1) * zMax

		-- HRP nằm trên mặt Floor
		local y =
			fSize.Y / 2 + 2

		local pos =
			fCF:PointToWorldSpace(
				Vector3.new(x, y, z)
			)

		local targetCF =
			CFrame.new(pos)
			* entityHRP.CFrame.Rotation

		if charHRP and charHRP.Parent then
			local distance =
				(
					targetCF.Position
					- charHRP.Position
				).Magnitude

			if distance > 20 then
				return targetCF, f
			end
		else
			return targetCF, f
		end
	end

	return nil
end

	------------------------------------------------
	-- RETREAT
	------------------------------------------------

	local function Retreat()
		if retreating
			or despawning
			or not model
			or not model.Parent then

			return
		end

		retreating = true
		chasing = false
		lastPlayerDistance = nil

		hitboxEnabled = false
		hitbox.CanTouch = false

		if tween then
			tween:Cancel()
			tween = nil
		end

		local targetCF
		local targetFloor

		for _ = 1, 10 do
			targetCF, targetFloor =
				GetRandomFloorTarget()

			if targetCF
				and targetFloor then
				break
			end
		end

		if not targetCF
			or not targetFloor
			or despawning
			or not entityHRP
			or not entityHRP.Parent then

			retreating = false

			if not despawning then
				hitboxEnabled = true
				hitbox.CanTouch = true
			end

			return
		end

		floor = targetFloor

		tween =
			TweenService:Create(
				entityHRP,
				TweenInfo.new(
					0.8,
					Enum.EasingStyle.Linear
				),
				{
					CFrame = targetCF
				}
			)

		tween:Play()

		tween.Completed:Wait()

		if despawning then
			return
		end

		tween = nil
		retreating = false

		hitboxEnabled = true
		hitbox.CanTouch = true

		lastPlayerDistance = nil
	end

	------------------------------------------------
	-- RANDOM MOVEMENT
	------------------------------------------------

	task.spawn(function()
		while randomLoopRunning
			and model
			and model.Parent
			and not despawning do

			task.wait(
				math.random(300, 400) / 100
			)

			if not randomLoopRunning
				or despawning
				or retreating
				or chasing
				or not model
				or not model.Parent then

				continue
			end

			if not entityHRP
				or not entityHRP.Parent then

				entityHRP =
					model:FindFirstChild(
						"HumanoidRootPart",
						true
					)

				if not entityHRP then
					break
				end
			end

			local targetCF, targetFloor =
				GetRandomFloorTarget()

			if targetCF
				and targetFloor
				and not despawning
				and not chasing
				and not retreating then

				floor = targetFloor

				tween =
					TweenService:Create(
						entityHRP,
						TweenInfo.new(
							0.8,
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
						or chasing
						or retreating then

						tween:Cancel()
						tween = nil
						break
					end

					if not targetFloor
						or not targetFloor.Parent then

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
	-- CHASE + DAMAGE
	------------------------------------------------

	local damageTimer = 0

	chaseConnection =
		RunService.RenderStepped:Connect(
			function(dt)

				if despawning then
					return
				end

				if not model
					or not model.Parent
					or not entityHRP
					or not entityHRP.Parent then

					return
				end

				if retreating then
					return
				end

				if not chasing then

					if InHitbox() then
						chasing = true
						hitboxEnabled = false
						hitbox.CanTouch = false
						lastPlayerDistance = nil

						if tween then
							tween:Cancel()
							tween = nil
						end
					else
						return
					end
				end

				if not LookingAtEntity() then
					Retreat()
					return
				end

				if IsAvoiding() then
					Retreat()
					return
				end

				if not charHRP
					or not charHRP.Parent
					or not hum
					or not hum.Parent then

					return
				end

				local currentPos =
					entityHRP.Position

				local targetPos =
					charHRP.Position

				local newPos =
					currentPos:Lerp(
						targetPos,
						math.clamp(
							dt * 8,
							0,
							1
						)
					)

				entityHRP.CFrame =
					CFrame.new(newPos)
					* entityHRP.CFrame.Rotation

				damageTimer += dt

				while damageTimer >= 0.005 do
					damageTimer -= 0.005

					if charHRP
						and charHRP.Parent
						and entityHRP
						and entityHRP.Parent
						and hum
						and hum.Parent then

						local newHit =
							hit:Clone()

						newHit.Parent =
							entityHRP

						newHit:Play()

						newHit.Ended:Connect(
							function()
								newHit:Destroy()
							end
						)

						hum:TakeDamage(0.15)

						game.ReplicatedStorage
							.GameStats[
								"Player_"
								.. game.Players.LocalPlayer.Name
							]
							.Total
							.DeathCause
							.Value = "XE-1"
					end
				end
			end
		)

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

	local timer = 0
	local shakeDelay = 0.25 / 100

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

				timer += dt

				if timer >= shakeDelay then
					timer -= shakeDelay

					for _, info in ipairs(images) do
						local image =
							info.object

						if image
							and image.Parent then

							local pos =
								info.position

							local x =
								math.random(-4, 4)
								/ 100

							local y =
								math.random(-4, 4)
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
end
