local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CurrentRooms = workspace:WaitForChild("CurrentRooms")
local LatestRoom = RS:WaitForChild("GameData"):WaitForChild("LatestRoom")
local despawnTime = false
local stopped = false
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
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/DG-1_Spawn.mp3?raw=true",
	"bcdstiovvrsthh"
)

spawn.Volume = 1
spawn.Name = "spawn"
spawn.PlaybackSpeed = 1
spawn.RollOffMaxDistance = 70

local jump = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/DG-1_Jump.mp3?raw=true",
	"nvkspajsbvjjjcjjd"
)

jump.Volume = 1.5
jump.Name = "jump"
jump.PlaybackSpeed = 1
jump.RollOffMaxDistance = 70

local dig = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/DG-1_Dig.mp3?raw=true",
	"pvosidjjcjcjsjjfhfhjx"
)

dig.Volume = 1.5
dig.Name = "dig"
dig.PlaybackSpeed = 1
dig.RollOffMaxDistance = 70

local hit = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/DG-1_Damage.mp3?raw=true",
	"lllvkkcncjdjshjxjcjf"
)

hit.Volume = 2
hit.Name = "hit"
hit.PlaybackSpeed = 1
hit.RollOffMaxDistance = 70

local despawn = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/DG-1_DeSpawn.mp3?raw=true",
	"ockjdkkdkcjjsjd"
)

despawn.Volume = 0.6
despawn.Name = "despawn"
despawn.PlaybackSpeed = 1
despawn.RollOffMaxDistance = 180

local underground = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/DG-1_Buzz_(Underground).mp3?raw=true",
	"jkvooskejhdjfocojxhsfj"
)

underground.Volume = 1.5
underground.Name = "undergroundBuzzing"
underground.PlaybackSpeed = 1
underground.Looped = true
underground.RollOffMaxDistance = 50

local parts = room:FindFirstChild("Parts")
local floor = parts and parts:FindFirstChild("Floor")

if not floor or not floor:IsA("BasePart") then
	return
end

local url = "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_16259573036_Model_DG-1_1789231961.txt"
local file = "DG-1_1789231961.txt"

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

model.HumanoidRootPart.CanCollide = false
spawn.Parent = model.HumanoidRootPart
jump.Parent = model.HumanoidRootPart
dig.Parent = model.HumanoidRootPart
underground.Parent = model.HumanoidRootPart
hit.Parent = model.HumanoidRootPart
despawn.Parent = model.HumanoidRootPart
spawn:Play() 

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

task.wait(5)

local function Move(HRP, target, duration)
	local start = HRP.CFrame
	local steps = math.max(1, math.ceil(duration * 40))

	for i = 1, steps do
		local alpha = i / steps

		HRP.CFrame = start:Lerp(target, alpha)

		task.wait(0.03)
	end

	HRP.CFrame = target
end

local function Cleanup()
	if stopped then
		return
	end

	stopped = true

	if imageConnection then
		imageConnection:Disconnect()
		imageConnection = nil
	end

	if digConn then
		digConn:Disconnect()
		digConn = nil
	end

	for _, v in ipairs(model:GetDescendants()) do
		if v:IsA("Light") then
			v.Enabled = false

		elseif v:IsA("BillboardGui") then
			v.Enabled = false

		elseif v:IsA("Sound") then
			v.Volume = 0
			v:Stop()
		end
	end

	despawn.Volume = 0.6
	despawn:Play()

	despawn.Ended:Wait()

	if imageConnection then
		imageConnection:Disconnect()
		imageConnection = nil
	end

	if digConn then
		digConn:Disconnect()
		digConn = nil
	end

	table.clear(images)

	if model then
		model:Destroy()
		model = nil
	end
end

local function Behavior()
	local HRP = model.HumanoidRootPart
	HRP.Anchored = true
	HRP.CanCollide = false

	local original = HRP.CFrame
	local digConn

	jump:Play()

	Move(
		HRP,
		original + Vector3.new(0, 3, 0),
		0.05
	)

	task.wait(0.5)

	dig:Play()

	Move(
		HRP,
		original + Vector3.new(0, -14, 0),
		0.1
	)

	HRP.Buzz.Playing = false
	underground:Play()
	
	if despawnTime then
		Cleanup()
		return
	end

	task.wait(0.5)

	local LP = game.Players.LocalPlayer
	local Char = LP.Character
	local LHRP = Char and Char:FindFirstChild("HumanoidRootPart")

	if LHRP then
		local cf = LHRP.CFrame

		local target = CFrame.new(
			cf.Position + Vector3.new(0, -8, 0)
		) * (cf - cf.Position)

		Move(
			HRP,
			target,
			0.2
		)
	end

	task.wait(1)

	HRP.DigUp:Play()

	local hitted = false

	digConn = HRP.Touched:Connect(function(part)
		if hitted then
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
		hit:Play() 
		Hum:TakeDamage(15)
		game.ReplicatedStorage
									.GameStats[
										"Player_"
										.. game.Players.LocalPlayer.Name
									]
									.Total
									.DeathCause
									.Value = "DG-1"

		if digConn then
			digConn:Disconnect()
			digConn = nil
		end
	end)

	-- movement bắt đầu -> ngắt Touched
	HRP.Buzz.Playing = true
	underground:Stop()

	local tpCF = HRP.CFrame

	Move(
		HRP,
		tpCF + Vector3.new(0, 9, 0),
		0.1
	)

	local tpCF2 = tpCF + Vector3.new(0, 10, 0)

	task.wait(0.5)
	
	if digConn then
		digConn:Disconnect()
		digConn = nil
	end

		Move(
		HRP,
		tpCF2 + Vector3.new(0, -2, 0),
		0.1
	)
end

task.spawn(function()
	for i = 0, 40 do
		if despawnTime then
			return
		end

		task.wait(1)
	end

	despawnTime = true
end)

task.spawn(function()
	while not stopped do
		Behavior()

		if stopped then
			break
		end

		task.wait(math.random(3, 5))
	end
end)
