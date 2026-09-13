local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CurrentRooms = workspace:WaitForChild("CurrentRooms")
local LatestRoom = RS:WaitForChild("GameData"):WaitForChild("LatestRoom")

local despawnTime = false
local stopped = false
local behaviorRunning = false
local imageConnection
local behaviorConnection
local digConn

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
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/CHA-1_Spawn.mp3?raw=true",
	"kpsoriasisjcj"
)

spawn.Volume = 1
spawn.Name = "spawn"
spawn.PlaybackSpeed = 1
spawn.RollOffMaxDistance = 70

local charge = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/CHA-1_Scream.mp3?raw=true",
	"jciskjxjjdjjfjiix"
)

charge.Volume = 1.5
charge.Name = "charge"
charge.PlaybackSpeed = 1
charge.RollOffMaxDistance = 400

local hit = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/CHA-1_Damage.mp3?raw=true",
	"kvloxjdjjfjjskch"
)

hit.Volume = 2
hit.Name = "hit"
hit.PlaybackSpeed = 1
hit.RollOffMaxDistance = 70

local despawn = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/CHA-1_End_Buzz.mp3?raw=true",
	"jkcospkzjxjjdjd"
)

despawn.Volume = 1
despawn.Name = "despawn"
despawn.PlaybackSpeed = 1
despawn.RollOffMaxDistance = 180

local parts = room:FindFirstChild("Parts")
local floor = parts and parts:FindFirstChild("Floor")

if not floor or not floor:IsA("BasePart") then
	return
end

local url = "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_16259573036_Model_CHA-1_1789264984.txt"
local file = "CHA-1kckksk.txt"

if not isfile(file) then
	writefile(file, game:HttpGet(url))
end

local model = game:GetObjects(getcustomasset(file))[1]
if not model then
	return
end

model.Parent = workspace

for _, v in ipairs(model:GetDescendants()) do
	if v.Name == "Torso" or v:IsA("Motor6D") then
		v:Destroy()
	elseif v:IsA("BasePart") then
		v.CanCollide = false
		v.CanTouch = true
	end
end

local HRP = model:FindFirstChild("HumanoidRootPart")
if not HRP then
	model:Destroy()
	return
end

HRP.CanCollide = false

spawn.Parent = HRP
charge.Parent = HRP
hit.Parent = HRP
despawn.Parent = HRP

spawn:Play()

local images = {}
local face

for _, obj in ipairs(model:GetDescendants()) do
	if obj:IsA("ImageLabel") then
		if not face then
			face = obj
		end

		images[#images + 1] = {
			object = obj,
			position = obj.Position
		}
	end
end

local timer = 0
local shakeDelay = 6 / 100

local shakePower = 3
local rotationPower = 5

imageConnection = RunService.RenderStepped:Connect(function(dt)
	if despawnTime or stopped then
		return
	end

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

				local x = math.random(-shakePower, shakePower) / 100
				local y = math.random(-shakePower, shakePower) / 100

				image.Position = UDim2.new(
					pos.X.Scale + x,
					pos.X.Offset,
					pos.Y.Scale + y,
					pos.Y.Offset
				)

				image.Rotation = math.random(
					-rotationPower,
					rotationPower
				)
			end
		end
	end
end)

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

local x = (math.random() * 2 - 1) * maxX
local z = (math.random() * 2 - 1) * maxZ

local y =
	floorSize.Y / 2
	+ boxSize.Y / 2

local pos = floorCF:PointToWorldSpace(
	Vector3.new(x, y, z)
)

local targetBoxCF =
	CFrame.new(pos) *
	CFrame.fromMatrix(
		Vector3.zero,
		floorCF.RightVector,
		floorCF.UpVector,
		-floorCF.LookVector
	)

local pivotCF = model:GetPivot()
local pivotToBox = pivotCF:ToObjectSpace(boxCF)

local targetPivot =
	targetBoxCF *
	pivotToBox:Inverse()

model:PivotTo(targetPivot)

task.wait(3.5)

if face then
	face.Image = "rbxassetid://131650688208923"
end

local function Cleanup()
	if stopped then
		return
	end

	stopped = true

	if digConn then
		digConn:Disconnect()
		digConn = nil
	end

	if imageConnection then
		imageConnection:Disconnect()
		imageConnection = nil
	end

	if face and face.Parent then
		face.Image = "rbxassetid://13327247700"
	end
	
	for _, v in ipairs(model:GetDescendants()) do
	if v:IsA("Sound") then
			v.Volume = 0
			v:Stop()
		end
	end

	despawn.Volume = 1
	despawn:Play()

	local HRP = model and model:FindFirstChild("HumanoidRootPart")
	local Billboard
	local Image

	if model then
		for _, v in ipairs(model:GetDescendants()) do
			if v:IsA("BillboardGui") then
				Billboard = v

				for _, obj in ipairs(v:GetDescendants()) do
					if obj:IsA("ImageLabel") then
						Image = obj
						break
					end
				end

				break
			end
		end
	end

	local TweenInfo = TweenInfo.new(
	4,
	Enum.EasingStyle.Cubic,
	Enum.EasingDirection.In
)

	local HRPTween

	if HRP then
		HRP.Anchored = true

		HRPTween = TweenService:Create(
			HRP,
			TweenInfo,
			{
				CFrame = HRP.CFrame + Vector3.new(0, -11, 0)
			}
		)

		HRPTween:Play()
	end

	if Image then
		local ImageTween = TweenService:Create(
			Image,
			TweenInfo,
			{
				Rotation = -30,
				ImageColor3 = Color3.new(0, 0, 0)
			}
		)

		ImageTween:Play()
	end

	if HRPTween then
		HRPTween.Completed:Wait()
	end

	table.clear(images)

	if model then
		model:Destroy()
		model = nil
	end
end

local function Behavior()
	if stopped or despawnTime or not model or behaviorRunning then
		return
	end

	behaviorRunning = true

	local HRP = model:FindFirstChild("HumanoidRootPart")

	if not HRP then
		behaviorRunning = false
		return
	end

	local LP = game.Players.LocalPlayer
	local Char = LP.Character
	local LHRP = Char and Char:FindFirstChild("HumanoidRootPart")

	if not LHRP then
		behaviorRunning = false
		return
	end

	HRP.Anchored = true
	HRP.CanCollide = false

	if face then
		face.Image = "rbxassetid://131650688208923"
	end

	task.wait(2)

	Char = LP.Character
	LHRP = Char and Char:FindFirstChild("HumanoidRootPart")

	if not LHRP then
		behaviorRunning = false
		return
	end

	local target = LHRP.CFrame

	charge:Play()

	if face then
		face.Image = "rbxassetid://89956441150243"
	end

	local hitted = false
	local Tween
	
	Tween = TweenService:Create(
		HRP,
		TweenInfo.new(
			0.4,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
		),
		{
			CFrame = target
		}
	)

	digConn = HRP.Touched:Connect(function(part)
		if hitted or stopped then
			return
		end

		local Char = LP.Character

		if not Char or not part:IsDescendantOf(Char) then
			return
		end

		local Hum = Char:FindFirstChildOfClass("Humanoid")

		if not Hum then
			return
		end

		hitted = true

		if Tween then
			Tween:Cancel()
		end

		hit:Play()
		Hum:TakeDamage(25)

		local Stats = RS:FindFirstChild("GameStats")
		local PlayerStats = Stats and Stats:FindFirstChild("Player_" .. LP.Name)
		local Total = PlayerStats and PlayerStats:FindFirstChild("Total")
		local DeathCause = Total and Total:FindFirstChild("DeathCause")

		if DeathCause then
			DeathCause.Value = "CHA-1"
		end

		if digConn then
			digConn:Disconnect()
			digConn = nil
		end
	end)

	shakePower = 6
rotationPower = 8

Tween:Play()
Tween.Completed:Wait()

shakePower = 3
rotationPower = 5

charge:Stop()

	if digConn then
		digConn:Disconnect()
		digConn = nil
	end

	if face and face.Parent then
		face.Image = "rbxassetid://131650688208923"
	end

	behaviorRunning = false
end

task.spawn(function()
	task.wait(40)

	if stopped then
		return
	end

	despawnTime = true

	while behaviorRunning and not stopped do
		task.wait()
	end

	if not stopped then
		Cleanup()
	end
end)

task.spawn(function()
	while not stopped do
		Behavior()

		if stopped then
			break
		end

		task.wait(math.random(2, 8))
	end
end)

if despawnTime and not stopped then
	while behaviorRunning and not stopped do
		task.wait()
	end

	if not stopped then
		Cleanup()
	end
end
