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
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/BIGGE1VeryAccurateSpawn.mp3?raw=true",
	"nckdlkxjcjcxjxj"
)

spawn.Volume = 1
spawn.Name = "spawn"
spawn.PlaybackSpeed = 1
spawn.RollOffMaxDistance = 70

local hit = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/E-1_Damage.mp3?raw=true",
	"jvopzoisjjdhdhcjkxj"
)

hit.Volume = 1
hit.Name = "hit"
hit.PlaybackSpeed = 0.8
hit.RollOffMaxDistance = 70

local despawn = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/BIGGE1VeryAccurateDespawn.mp3?raw=true",
	"cndkxkjcjdjfjccj"
)

despawn.Volume = 1
despawn.Name = "despawn"
despawn.PlaybackSpeed = 1
despawn.RollOffMaxDistance = 200

local url =
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_16259573036_Model_BIGGE-1_1789381620.txt"

local path = "BIGGE-1jjcjdjdjjjxhj"

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

	spawn.Parent = entityHRP
	hit.Parent = entityHRP
	despawn.Parent = entityHRP

	spawn:Play()

	------------------------------------------------
	-- STATE
	------------------------------------------------

	local chasing = false
	local chaseStarted = false
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
	-- GET INITIAL FLOOR
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
	-- DESPAWN
	------------------------------------------------

	local function Despawn()
		if despawning then
			return
		end

		despawning = true
		randomLoopRunning = false
		chasing = false
		chaseStarted = false

		------------------------------------------------
		-- STOP TWEEN
		------------------------------------------------

		if tween then
			tween:Cancel()
			tween = nil
		end

		------------------------------------------------
		-- DISCONNECT LOOPS
		------------------------------------------------

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

		------------------------------------------------
		-- DISABLE EVERYTHING EXCEPT DESPAWN SOUND
		------------------------------------------------

		if model and model.Parent then
			for _, obj in ipairs(model:GetDescendants()) do

				if obj:IsA("Sound") then
					if obj ~= despawn
						and obj.Name ~= "despawn" then

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

		------------------------------------------------
		-- PLAY DESPAWN
		------------------------------------------------

		if despawn and despawn.Parent then
			despawn.Volume = 1

			despawnConnection =
				despawn.Ended:Connect(function()
					if despawnConnection then
						despawnConnection:Disconnect()
						despawnConnection = nil
					end

					------------------------------------------------
					-- DESTROY FULL MODEL
					------------------------------------------------

					if model then
						model:Destroy()
					end

					------------------------------------------------
					-- CLEAR STATE
					------------------------------------------------

					model = nil
					entityHRP = nil
					char = nil
					charHRP = nil
					hum = nil
					floor = nil
					tween = nil
					chasing = nil
					chaseStarted = nil
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
			char = nil
			charHRP = nil
			hum = nil
			floor = nil
			tween = nil
			chasing = nil
			chaseStarted = nil
			randomLoopRunning = nil
			despawning = nil
		end
	end

	------------------------------------------------
	-- 60 SECOND LIFETIME
	------------------------------------------------

	task.delay(60, function()
		if model and model.Parent and not despawning then
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

		if not char or not char.Parent then
			return false
		end

		for _, obj in ipairs(char:GetDescendants()) do
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

		if not charHRP or not charHRP.Parent then
			return false
		end

		if not entityHRP or not entityHRP.Parent then
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
	-- CHASE CONDITION
	------------------------------------------------

	local function ShouldChase()
		return HasSpotLight()
			and LookingAtEntity()
	end

	------------------------------------------------
	-- FIND FLOOR BELOW ENTITY
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
			local hitPart =
				result.Instance

			if hitPart:IsA("BasePart")
				and hitPart.Name == "Floor" then

				return hitPart
			end

			local parentModel =
				hitPart:FindFirstAncestorWhichIsA(
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
		if despawning then
			return nil
		end

		local f =
			GetFloorBelow()

		if f and f.Parent then
			floor = f
		else
			if not floor
				or not floor.Parent then

				floor =
					GetLatestRoomFloor()
			end

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

		return Vector3.new(
			pos.X,
			pos.Y,
			pos.Z
		), f
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
				math.random(200, 300) / 100
			)

			if not randomLoopRunning
				or despawning
				or not model
				or not model.Parent then

				break
			end

			if chasing then
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

			------------------------------------------------
			-- CURRENT FLOOR DELETED
			------------------------------------------------

			if floor and not floor.Parent then
				floor =
					GetLatestRoomFloor()

				if not floor then
					continue
				end
			end

			local targetPos, targetFloor =
				GetRandomFloorTarget()

			if targetPos
				and targetFloor
				and not despawning then

				floor = targetFloor

				local currentCF =
					entityHRP.CFrame

				local targetCF =
					CFrame.new(targetPos)
					* currentCF.Rotation

				local tweenFloor =
					targetFloor

				tween =
					TweenService:Create(
						entityHRP,
						TweenInfo.new(5),
						{
							CFrame = targetCF
						}
					)

				tween:Play()

				------------------------------------------------
				-- CHECK FLOOR WHILE TWEENING
				------------------------------------------------

				while tween
					and tween.PlaybackState
						== Enum.PlaybackState.Playing do

					if despawning then
						tween:Cancel()
						tween = nil
						break
					end

					if chasing then
						tween:Cancel()
						tween = nil
						break
					end

					------------------------------------------------
					-- EXACT FLOOR USED BY THIS TWEEN DELETED
					------------------------------------------------

					if not tweenFloor
						or not tweenFloor.Parent then

						tween:Cancel()
						tween = nil

						local newFloor =
							GetLatestRoomFloor()

						if newFloor
							and newFloor.Parent
							and entityHRP
							and entityHRP.Parent
							and not despawning then

							floor = newFloor

							local _, newSize =
								model:GetBoundingBox()

							local fCF =
								newFloor.CFrame

							local fSize =
								newFloor.Size

							local xMax =
								math.max(
									0,
									fSize.X / 2
										- newSize.X / 2
								)

							local zMax =
								math.max(
									0,
									fSize.Z / 2
										- newSize.Z / 2
								)

							local x =
								(math.random() * 2 - 1)
								* xMax

							local z =
								(math.random() * 2 - 1)
								* zMax

							local y =
								fSize.Y / 2
								+ newSize.Y / 2
								+ 1

							local pos =
								fCF:PointToWorldSpace(
									Vector3.new(
										x,
										y,
										z
									)
								)

							local newTarget =
								Vector3.new(
									pos.X,
									pos.Y,
									pos.Z
								)

							tweenFloor =
								newFloor

							local newCF =
								CFrame.new(
									newTarget
								)
								* entityHRP.CFrame.Rotation

							tween =
								TweenService:Create(
									entityHRP,
									TweenInfo.new(5),
									{
										CFrame = newCF
									}
								)

							tween:Play()
						else
							break
						end
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
					or not model.Parent then

					if chaseConnection then
						chaseConnection:Disconnect()
						chaseConnection = nil
					end

					return
				end

				local shouldChase =
					ShouldChase()

				if shouldChase then

					if not chasing then
						chasing = true
						chaseStarted = true
					end

					------------------------------------------------
					-- CANCEL RANDOM TWEEN
					------------------------------------------------

					if tween then
						tween:Cancel()
						tween = nil
					end

					------------------------------------------------
					-- MOVE TO PLAYER
					------------------------------------------------

					if charHRP
						and charHRP.Parent
						and entityHRP
						and entityHRP.Parent then

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
					end

					------------------------------------------------
					-- DAMAGE
					------------------------------------------------

					damageTimer += dt

					while damageTimer >= 0.5 do
						damageTimer -= 0.5

						if charHRP
							and charHRP.Parent
							and entityHRP
							and entityHRP.Parent
							and hum
							and hum.Parent then

							local distance =
								(
									entityHRP.Position
									- charHRP.Position
								).Magnitude

							local touchDistance =
								(
									entityHRP.Size.Magnitude
									+ charHRP.Size.Magnitude
								) / 2

							if distance
								<= touchDistance then

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

								hum:TakeDamage(75)

								game.ReplicatedStorage
									.GameStats[
										"Player_"
										.. game.Players.LocalPlayer.Name
									]
									.Total
									.DeathCause
									.Value = "BIGGE-1"
							end
						end
					end

				else

					------------------------------------------------
					-- END CHASE
					------------------------------------------------

					if chasing then
						chasing = false
						damageTimer = 0

						local f =
							GetFloorBelow()

						if f then
							floor = f
						else
							floor =
								GetLatestRoomFloor()
						end
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
	local shakeDelay = 0.5 / 100

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
								math.random(-2, 2)
						end
					end
				end
			end
		)
end
