local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CurrentRooms = workspace:WaitForChild("CurrentRooms")
local LatestRoom = RS:WaitForChild("GameData"):WaitForChild("LatestRoom")

local room = CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
if not room then
	return
end

local function GetGitSound(GithubSnd, SoundName)
	if not isfile(SoundName .. ".mp3") then
		writefile(SoundName .. ".mp3", game:HttpGet(GithubSnd))
	end

	local sound = Instance.new("Sound")
	sound.SoundId = (getcustomasset or getsynasset)(SoundName .. ".mp3")
	return sound
end

local spawn = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/BM-1_Spawn.mp3?raw=true",
	"hcjfkdkchhdjjdjcj"
)

spawn.Volume = 0.6
spawn.Name = "spawn"
spawn.PlaybackSpeed = 1
spawn.RollOffMaxDistance = 50

local explosion = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/BM-1_Explode.mp3?raw=true",
	"jckosokxjdhdhhsjxn"
)

explosion.Volume = 0.6
explosion.Name = "explosion"
explosion.PlaybackSpeed = 1
explosion.RollOffMaxDistance = 60

local hit = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/BM-1_Damage.mp3?raw=true",
	"vhjdkdkccjjfjfhc"
)

hit.Volume = 1
hit.Name = "hit"
hit.PlaybackSpeed = 1
hit.RollOffMaxDistance = 70

local Players = game:GetService("Players")
local LPlayer = Players.LocalPlayer

local ExplosionHits = {}

local function WatchExplosion(Explosion)
	if not Explosion then
		return
	end

	ExplosionHits[Explosion] = true

	task.spawn(function()
		local startTime = tick()
		local duration = 0.8
		local hitted = false

		while Explosion
			and Explosion.Parent
			and tick() - startTime < duration do

			if not hitted then
				local Char = LPlayer.Character
				local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
				local HRP = Char and Char:FindFirstChild("HumanoidRootPart")

				if Hum and HRP and Hum.Health > 0 then
					local distance = (HRP.Position - Explosion.Position).Magnitude

					if distance <= Explosion.BlastRadius then
						hitted = true
						Hum.Health = math.max(0, Hum.Health - 5)
						local stats = game.ReplicatedStorage.GameStats:FindFirstChild(
				"Player_" .. LPlayer.Name
			)

			if stats and stats:FindFirstChild("Total") then
				local deathCause = stats.Total:FindFirstChild("DeathCause")

				if deathCause then
					deathCause.Value = "BM-1"
				end
			end
			
			hit:Play() 
					end
				end
			end

			RunService.Heartbeat:Wait()
		end

		ExplosionHits[Explosion] = nil
	end)
end

local parts = room:FindFirstChild("Parts")
local floor = parts and parts:FindFirstChild("Floor")

if not floor or not floor:IsA("BasePart") then
	return
end

local url = "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_12855788697_Model_BM-1_1789278342.txt"
local file = "BM-1.txt"

if not isfile(file) then
	writefile(file, game:HttpGet(url))
end

local model = game:GetObjects(getcustomasset(file))[1]
if not model then
	return
end

model.Parent = workspace

local HRP = model:FindFirstChild("HumanoidRootPart")
if not HRP then
	model:Destroy()
	return
end

spawn.Parent = HRP
explosion.Parent = HRP
hit.Parent = HRP

spawn:Play()

for _, v in ipairs(model:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CanCollide = false
		v.CanTouch = false
	end
end

local boxCF, boxSize = model:GetBoundingBox()

local floorCF = floor.CFrame
local floorSize = floor.Size

local maxX = math.max(
	0,
	floorSize.X / 2 - boxSize.X / 2
)

local maxZ = math.max(
	0,
	floorSize.Z / 2 - boxSize.Z / 2
)

local function GetRandomFloorPosition()
	local x = (math.random() * 2 - 1) * maxX
	local z = (math.random() * 2 - 1) * maxZ

	local y =
		floorSize.Y / 2
		+ boxSize.Y / 2

	local pos = floorCF:PointToWorldSpace(
		Vector3.new(x, y, z)
	)

	return CFrame.new(pos) * CFrame.fromMatrix(
		Vector3.zero,
		floorCF.RightVector,
		floorCF.UpVector,
		-floorCF.LookVector
	)
end

local targetBoxCF = GetRandomFloorPosition()

local pivotCF = model:GetPivot()
local pivotToBox = pivotCF:ToObjectSpace(boxCF)

local targetPivot =
	targetBoxCF *
	pivotToBox:Inverse()

model:PivotTo(targetPivot)

local images = {}

for _, obj in ipairs(model:GetDescendants()) do
	if obj:IsA("ImageLabel") then
		images[#images + 1] = {
			object = obj,
			position = obj.Position
		}
	end
end

local shakePower = 8
local rotationPower = 8
local timer = 0
local shakeDelay = 4 / 100

local imageConnection = RunService.RenderStepped:Connect(function(dt)
	if not model or not model.Parent then
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
			local image = info.object

			if image and image.Parent then
				local pos = info.position

				local power = math.floor(shakePower + 0.5)
				local rot = math.floor(rotationPower + 0.5)

				local x = math.random(-power, power) / 100
				local y = math.random(-power, power) / 100

				image.Position = UDim2.new(
					pos.X.Scale + x,
					pos.X.Offset,
					pos.Y.Scale + y,
					pos.Y.Offset
				)

				image.Rotation = math.random(-rot, rot)
			end
		end
	end
end)

local movementStopped = false
local currentMoveTween = nil

task.spawn(function()
	task.wait(8)

	if not model or not model.Parent then
		return
	end

	local startTime = tick()
	local shakeTweenTime = 1

	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not model or not model.Parent then
			conn:Disconnect()
			return
		end

		local alpha = math.clamp(
			(tick() - startTime) / shakeTweenTime,
			0,
			1
		)

		shakePower = 8 + ((30 - 8) * alpha)
		rotationPower = 8 + ((100 - 8) * alpha)

		if alpha >= 1 then
			shakePower = 30
			rotationPower = 100
			conn:Disconnect()
		end
	end)

	repeat
		task.wait()
	until not conn.Connected

	if not model or not model.Parent then
		return
	end

	task.wait(1)

	if not model or not model.Parent or not HRP or not HRP.Parent then
		return
	end

	-- Ngắt movement
	movementStopped = true

	if currentMoveTween then
		currentMoveTween:Cancel()
		currentMoveTween = nil
	end

	-- Ngắt shake
	if imageConnection then
		imageConnection:Disconnect()
		imageConnection = nil
	end

	for _, info in ipairs(images) do
		local image = info.object

		if image and image.Parent then
			image.Position = info.position
			image.Rotation = 0
		end
	end
	
		-- Explosion effect
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = false
		elseif obj:IsA("PointLight")
			or obj:IsA("SpotLight")
			or obj:IsA("SurfaceLight") then
			obj.Enabled = false
		elseif obj:IsA("Sound") and obj.Name ~= "explosion" then
			obj:Destroy()
		elseif obj:IsA("Motor6D")
			or obj:IsA("Weld")
			or obj:IsA("WeldConstraint")
			or obj:IsA("ManualWeld")
			or obj:IsA("Snap")
			or obj:IsA("RigidConstraint") then
			obj:Destroy()
		elseif obj:IsA("ImageLabel") then
			obj.Image = "rbxassetid://114851091287228"
		end
	end

	HRP.Anchored = false

	local Explosion = Instance.new("Explosion")
Explosion.Position = HRP.Position
Explosion.BlastRadius = 15
Explosion.BlastPressure = 0
Explosion.DestroyJointRadiusPercent = 0
Explosion.Parent = workspace

WatchExplosion(Explosion)

	-- Clone system
	HRP.Archivable = true

	local function SetupClone(Name, Offset, ImageId, Direction)
	local Clone = HRP:Clone()
	if not Clone then
		return
	end

	Clone.Name = Name
	Clone.Parent = HRP.Parent
	Clone.CFrame = HRP.CFrame * CFrame.new(Offset, 0, 0)

	Clone.Anchored = false
	Clone.CanCollide = true
	Clone.CanTouch = false
	Clone.CanQuery = true
	Clone.Massless = false

	for _, obj in ipairs(Clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = false
			obj.CanCollide = true
			obj.CanTouch = false
			obj.CanQuery = true
			obj.Massless = false
		elseif obj:IsA("ImageLabel") then
			obj.Image = ImageId
		end
	end

	local exploded = false
	local touchConnection

	-- Đợi 3 giây rồi mới bắt đầu văng + collision detection
	task.delay(1, function()
		if not Clone or not Clone.Parent or exploded then
			return
		end

		-- Bắt đầu cho phép phát hiện va chạm
		Clone.CanTouch = true

		for _, obj in ipairs(Clone:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.CanTouch = true
			end
		end

		-- Bắt đầu văng
		Clone.AssemblyLinearVelocity =
			Direction * 170 + Vector3.new(0, 20, 0)
			
			task.wait(0.6)

		-- Chỉ tạo Touched lúc này
		touchConnection = Clone.Touched:Connect(function(hitPart)
			if exploded then
				return
			end

			if not hitPart or not hitPart.Parent then
				return
			end

			-- Bỏ qua chính BM-1
			if hitPart:IsDescendantOf(model) then
				return
			end

			-- Bỏ qua chính clone
			if hitPart:IsDescendantOf(Clone) then
				return
			end

			exploded = true

			if touchConnection then
				touchConnection:Disconnect()
				touchConnection = nil
			end

			Clone.AssemblyLinearVelocity = Vector3.zero
			Clone.AssemblyAngularVelocity = Vector3.zero

			-- Tắt BillboardGui
			for _, obj in ipairs(Clone:GetDescendants()) do
				if obj:IsA("BillboardGui") then
					obj.Enabled = false
				end
			end

			-- Explosion
			local CloneExplosion = Instance.new("Explosion")
CloneExplosion.Position = Clone.Position
CloneExplosion.BlastRadius = 15
CloneExplosion.BlastPressure = 0
CloneExplosion.DestroyJointRadiusPercent = 0
CloneExplosion.Parent = workspace

WatchExplosion(CloneExplosion)

			-- Explosion sound riêng
			local CloneSound = explosion:Clone()
			CloneSound.Parent = Clone
			CloneSound:Play()

			-- Destroy sau 2 giây
			task.delay(2, function()
				if Clone and Clone.Parent then
					Clone:Destroy()
				end
			end)
		end)
	end)

	return Clone
end

		local Clone1 = SetupClone(
		"BM-1_Clone1",
		-3,
		"rbxassetid://72602355245190",
		-HRP.CFrame.RightVector
	)

	local Clone2 = SetupClone(
		"BM-1_Clone2",
		3,
		"rbxassetid://89763378952555",
		HRP.CFrame.RightVector
	)
	
	explosion:Play()

	-- Chờ 1.2 giây sau khi 2 clone được tạo
	task.wait(1.2)

	if not HRP or not HRP.Parent then
		return
	end

	-- Tắt toàn bộ BillboardGui của HRP gốc
	for _, obj in ipairs(HRP:GetDescendants()) do
		if obj:IsA("BillboardGui") then
			obj.Enabled = false
		end
	end

	-- Explosion của HRP gốc
	local HRPExplosion = Instance.new("Explosion")
HRPExplosion.Position = HRP.Position
HRPExplosion.BlastRadius = 15
HRPExplosion.BlastPressure = 0
HRPExplosion.DestroyJointRadiusPercent = 0
HRPExplosion.Parent = workspace

WatchExplosion(HRPExplosion)

	-- Sound explosion của HRP gốc
	explosion:Play()

	-- Đợi 2 giây rồi destroy HRP
	task.wait(2)

	if HRP and HRP.Parent then
		HRP:Destroy()
	end

	-- Đợi thêm 3 giây
	task.wait(3)

	-- Dọn toàn bộ connection
	if imageConnection then
		imageConnection:Disconnect()
		imageConnection = nil
	end

	if currentMoveTween then
		currentMoveTween:Cancel()
		currentMoveTween = nil
	end

	if model and model.Parent then
		model:Destroy()
	end

	-- Dọn sound
	if spawn then
		spawn:Destroy()
	end

	if explosion then
		explosion:Destroy()
	end

	if hit then
		hit:Destroy()
	end

	-- Dọn state
	images = {}
	movementStopped = true
	currentMoveTween = nil
	HRP = nil
	model = nil
end)

task.spawn(function()
	while model and model.Parent and not movementStopped do
		task.wait(math.random(2, 3))

		if movementStopped then
			break
		end

		if not model or not model.Parent or not HRP or not HRP.Parent then
			break
		end

		local targetCF = GetRandomFloorPosition()

		local currentPos = HRP.Position
		local targetPos = targetCF.Position
		local distance = (targetPos - currentPos).Magnitude

		if distance > 0.05 then
			local duration = distance / 50

			currentMoveTween = TweenService:Create(
				HRP,
				TweenInfo.new(
					duration,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.Out
				),
				{
					CFrame = targetCF
				}
			)

			currentMoveTween:Play()
			currentMoveTween.Completed:Wait()

			currentMoveTween = nil
		end
	end
end)
