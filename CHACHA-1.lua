local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CancelAllTweens
local CurrentRooms = workspace:WaitForChild("CurrentRooms")
local LatestRoom = RS.GameData:WaitForChild("LatestRoom")

local Room = CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
if not Room then
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

local despawn = GetGitSound(
	"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/CHACHA1Despawn.mp3?raw=true",
	"ucidospxjjcidojxc"
)

despawn.Volume = 1
despawn.Name = "despawn"
despawn.PlaybackSpeed = 1
despawn.RollOffMaxDistance = 70

local Parts = Room:FindFirstChild("Parts")
local Floor = Parts and Parts:FindFirstChild("Floor")

if not Floor or not Floor:IsA("BasePart") then
	return
end

local URL = "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_16259573036_Model_CHACHA-1_1789465448.txt"
local File = "CHACHA-1.txt"

if not isfile(File) then
	writefile(File, game:HttpGet(URL))
end

local Model = game:GetObjects(getcustomasset(File))[1]
if not Model then
	return
end

Model.Parent = workspace
despawn.Parent = Model.HumanoidRootPart

local Cleaned = false
local Despawned = false
local FinalShake = false
local SpawnTime = os.clock()

local BoxCF, BoxSize = Model:GetBoundingBox()

local FloorCF = Floor.CFrame
local FloorSize = Floor.Size

local X = (math.random() * 2 - 1) * math.max(
	0,
	FloorSize.X / 2 - BoxSize.X / 2
)

local Z = (math.random() * 2 - 1) * math.max(
	0,
	FloorSize.Z / 2 - BoxSize.Z / 2
)

local Y = FloorSize.Y / 2 + BoxSize.Y / 2

local Pos = FloorCF:PointToWorldSpace(
	Vector3.new(X, Y, Z)
)

local TargetBoxCF = CFrame.new(Pos) * CFrame.fromMatrix(
	Vector3.zero,
	FloorCF.RightVector,
	FloorCF.UpVector,
	-FloorCF.LookVector
)

local PivotCF = Model:GetPivot()
local PivotToBox = PivotCF:ToObjectSpace(BoxCF)

Model:PivotTo(
	TargetBoxCF * PivotToBox:Inverse()
)

local Images = {}

for _, Obj in ipairs(Model:GetDescendants()) do
	if Obj:IsA("ImageLabel") then
		Images[#Images + 1] = {
	Object = Obj,
	Position = Obj.Position,
	Rotation = Obj.Rotation,
	Size = Obj.Size,
	ImageId = Obj.Image
}
	end
end

local ShakePower = 5
local RotationPower = 10
local FinalShakePower = 25
local FinalRotationPower = 50
local Timer = 0
local ShakeDelay = 3 / 100

local Connection

Connection = RunService.RenderStepped:Connect(function(dt)
	if Cleaned or FinalShake or not Model or not Model.Parent then
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end

		return
	end

	Timer += dt

	if Timer >= ShakeDelay then
		Timer -= ShakeDelay

		for _, Info in ipairs(Images) do
			local Image = Info.Object

			if Image and Image.Parent then
				local Pos = Info.Position

				local Power = math.floor(ShakePower + 0.5)
				local Rot = math.floor(RotationPower + 0.5)

				local X = math.random(-Power, Power) / 100
				local Y = math.random(-Power, Power) / 100

				Image.Position = UDim2.new(
					Pos.X.Scale + X,
					Pos.X.Offset,
					Pos.Y.Scale + Y,
					Pos.Y.Offset
				)

				Image.Rotation = math.random(-Rot, Rot)
			end
		end
	end
end)

task.wait(3)

if Connection then
	Connection:Disconnect()
	Connection = nil
end

if not Model or not Model.Parent then
	return
end

for _, Info in ipairs(Images) do
	local Image = Info.Object

	if Image and Image.Parent then
	Image.Position = Info.Position
	Image.Rotation = Info.Rotation
	Image.Size = Info.Size
	Image.Image = Info.ImageId
end
end

local Billboards = {}

for _, Info in ipairs(Images) do
	local Image = Info.Object

	if Image and Image.Parent then
		local Billboard = Image:FindFirstAncestorOfClass("BillboardGui")

		if Billboard then
			local Found = false

			for _, v in ipairs(Billboards) do
				if v.Gui == Billboard then
					Found = true
					break
				end
			end

			if not Found then
				Billboards[#Billboards + 1] = {
					Gui = Billboard,
					Position = Billboard.StudsOffset,
					Size = Billboard.Size
				}
			end
		end
	end
end

local function SetImage(Id)
	for _, Info in ipairs(Images) do
		local Image = Info.Object

		if Image and Image.Parent then
			Image.Image = "rbxassetid://" .. Id
		end
	end
end

local function ResetBillboards()
	for _, Info in ipairs(Billboards) do
		local Gui = Info.Gui

		if Gui and Gui.Parent then
			Gui.StudsOffset = Info.Position
			Gui.Size = Info.Size
		end
	end
end

local Movement = 1

local Movement1Tween = nil
local Movement2Tween = nil
local Movement3Tween = nil

local function Cleanup()
	if Cleaned then
		return
	end

	Cleaned = true
	Movement = 0

	CancelAllTweens()

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	if not Model or not Model.Parent then
		return
	end

	for _, Obj in ipairs(Model:GetDescendants()) do
		if Obj:IsA("PointLight") then
			Obj.Enabled = false

		elseif Obj:IsA("BillboardGui") then
			Obj.Enabled = false

		elseif Obj:IsA("Sound") then
			if Obj ~= despawn then
				Obj.Volume = 0
			end
		end
	end

	if not Despawned and despawn and despawn.Parent then
		Despawned = true

		despawn.Volume = 1
		despawn:Play()
		despawn.Ended:Wait()
	end

	if Model and Model.Parent then
		Model:Destroy()
	end
end

task.spawn(function()
	local Remaining = 50 - (os.clock() - SpawnTime)

	if Remaining > 0 then
		task.wait(Remaining)
	end

	if Cleaned or not Model or not Model.Parent then
		return
	end

	-- Dừng Movement 1/2/3
	Movement = 0

	CancelAllTweens()
	ResetBillboards()

	-- Bật Final Shake
	-- Bật Final Shake
FinalShake = true

for _, Info in ipairs(Images) do
	local Image = Info.Object

	if Image and Image.Parent then
		Image.Image = Info.ImageId
	end
end

Timer = 0

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	Connection = RunService.RenderStepped:Connect(function(dt)
		if Cleaned or not Model or not Model.Parent or not FinalShake then
			if Connection then
				Connection:Disconnect()
				Connection = nil
			end

			return
		end

		Timer += dt

		if Timer >= ShakeDelay then
			Timer -= ShakeDelay

			for _, Info in ipairs(Images) do
				local Image = Info.Object

				if Image and Image.Parent then
					local Pos = Info.Position

					local Power = math.floor(FinalShakePower + 0.5)
local Rot = math.floor(FinalRotationPower + 0.5)

					local X = math.random(-Power, Power) / 100
					local Y = math.random(-Power, Power) / 100

					Image.Position = UDim2.new(
						Pos.X.Scale + X,
						Pos.X.Offset,
						Pos.Y.Scale + Y,
						Pos.Y.Offset
					)

					Image.Rotation = math.random(-Rot, Rot)
				end
			end
		end
	end)

	-- Shake 4 giây
	task.wait(4)

	if Cleaned or not Model or not Model.Parent then
		return
	end

	FinalShake = false

	-- Reset Image về vị trí/rotation gốc trước Cleanup
	for _, Info in ipairs(Images) do
		local Image = Info.Object

		if Image and Image.Parent then
			Image.Position = Info.Position
			Image.Rotation = Info.Rotation
			Image.Size = Info.Size
		end
	end

	Cleanup()
end)

CancelAllTweens = function()
	if Movement1Tween then
		Movement1Tween:Cancel()
		Movement1Tween = nil
	end

	if Movement2Tween then
		Movement2Tween:Cancel()
		Movement2Tween = nil
	end

	if Movement3Tween then
		Movement3Tween:Cancel()
		Movement3Tween = nil
	end
end

-- Movement 1

local function Movement1()
	while Movement == 1 and Model and Model.Parent do
		SetImage("113819272136931")

		for _, Info in ipairs(Billboards) do
			local Gui = Info.Gui

			if Gui and Gui.Parent and Movement == 1 then
				local Start = Info.Position
				local Target = Start + Vector3.new(-3, 0, 0)

				Gui.StudsOffset = Target

				local Tween = TweenService:Create(
					Gui,
					TweenInfo.new(
						0.17,
						Enum.EasingStyle.Sine,
						Enum.EasingDirection.Out
					),
					{
						StudsOffset = Start
					}
				)

				Movement1Tween = Tween

				Tween:Play()
				Tween.Completed:Wait()

				if Movement1Tween == Tween then
					Movement1Tween = nil
				end

				if Movement ~= 1 then
					break
				end

				task.wait(0.08)
			end
		end

		if Movement ~= 1 then
			break
		end

		SetImage("138912756308683")

		for _, Info in ipairs(Billboards) do
			local Gui = Info.Gui

			if Gui and Gui.Parent and Movement == 1 then
				local Start = Info.Position
				local Target = Start + Vector3.new(3, 0, 0)

				Gui.StudsOffset = Target

				local Tween = TweenService:Create(
					Gui,
					TweenInfo.new(
						0.17,
						Enum.EasingStyle.Sine,
						Enum.EasingDirection.Out
					),
					{
						StudsOffset = Start
					}
				)

				Movement1Tween = Tween

				Tween:Play()
				Tween.Completed:Wait()

				if Movement1Tween == Tween then
					Movement1Tween = nil
				end

				if Movement ~= 1 then
					break
				end

				task.wait(0.08)
			end
		end
	end
end


-- Movement loop

while Model and Model.Parent do

	-- =========================
	-- MOVEMENT 1
	-- =========================

	Movement = 1
	CancelAllTweens()
	ResetBillboards()

	task.spawn(Movement1)

	task.wait(2)

if not Model or not Model.Parent or Movement == 0 then
	return
end

Movement = 2

	CancelAllTweens()
	ResetBillboards()


	-- =========================
	-- MOVEMENT 2
	-- =========================

	local StandingSizes = {}
	local SquashSizes = {}

	for _, Info in ipairs(Billboards) do
		local Gui = Info.Gui

		if Gui and Gui.Parent then
			local Size = Info.Size

			StandingSizes[Gui] = UDim2.new(
				Size.X.Scale,
				Size.X.Offset,
				Size.Y.Scale * 1.2,
				Size.Y.Offset * 1.2
			)

			SquashSizes[Gui] = UDim2.new(
				Size.X.Scale * 1.5,
				Size.X.Offset * 1.5,
				Size.Y.Scale * 0.6,
				Size.Y.Offset * 0.6
			)

			Gui.Size = StandingSizes[Gui]
		end
	end

	local Movement2Start = os.clock()

	while Model and Model.Parent and Movement == 2 do

		SetImage("88374836419149")

		for _, Info in ipairs(Billboards) do
			local Gui = Info.Gui

			if Gui and Gui.Parent and Movement == 2 then
				local Tween = TweenService:Create(
					Gui,
					TweenInfo.new(
						0.3,
						Enum.EasingStyle.Sine,
						Enum.EasingDirection.InOut
					),
					{
						Size = SquashSizes[Gui]
					}
				)

				Movement2Tween = Tween
				Tween:Play()
			end
		end

		task.wait(0.2)

		if not Model or not Model.Parent or Movement ~= 2 then
			break
		end

		SetImage("118739661493807")

		task.wait(0.1)

		if not Model or not Model.Parent or Movement ~= 2 then
			break
		end

		for _, Info in ipairs(Billboards) do
			local Gui = Info.Gui

			if Gui and Gui.Parent and Movement == 2 then
				local Tween = TweenService:Create(
					Gui,
					TweenInfo.new(
						0.3,
						Enum.EasingStyle.Sine,
						Enum.EasingDirection.InOut
					),
					{
						Size = StandingSizes[Gui]
					}
				)

				Movement2Tween = Tween
				Tween:Play()
			end
		end

		task.wait(0.3)

		if not Model or not Model.Parent or Movement ~= 2 then
			break
		end

		SetImage("88374836419149")

		if os.clock() - Movement2Start >= 2 then
			break
		end
	end

	if not Model or not Model.Parent or Movement == 0 then
	return
end

Movement = 3

	CancelAllTweens()
	ResetBillboards()


	-- =========================
	-- MOVEMENT 3
	-- =========================

	local BigSizes = {}
	local SmallSizes = {}

	for _, Info in ipairs(Billboards) do
		local Gui = Info.Gui

		if Gui and Gui.Parent then
			local Size = Info.Size

			BigSizes[Gui] = UDim2.new(
				Size.X.Scale * 1.7,
				Size.X.Offset * 1.7,
				Size.Y.Scale * 1.7,
				Size.Y.Offset * 1.7
			)

			SmallSizes[Gui] = UDim2.new(
				Size.X.Scale * 0.7,
				Size.X.Offset * 0.7,
				Size.Y.Scale * 0.7,
				Size.Y.Offset * 0.7
			)

			Gui.Size = BigSizes[Gui]
		end
	end

	SetImage("131776742309770")

	local Movement3Start = os.clock()

	while Model and Model.Parent and Movement == 3 do

		-- Big -> Small

		for _, Info in ipairs(Billboards) do
			local Gui = Info.Gui

			if Gui and Gui.Parent and Movement == 3 then
				local Tween = TweenService:Create(
					Gui,
					TweenInfo.new(
						0.15,
						Enum.EasingStyle.Quart,
						Enum.EasingDirection.InOut
					),
					{
						Size = SmallSizes[Gui]
					}
				)

				Movement3Tween = Tween
				Tween:Play()
			end
		end

		task.spawn(function()
			task.wait(0.1)

			if Model and Model.Parent and Movement == 3 then
				SetImage("133678930493744")
			end
		end)

		task.wait(0.15)

		if not Model or not Model.Parent or Movement ~= 3 then
			break
		end

		-- Small -> Big

		for _, Info in ipairs(Billboards) do
			local Gui = Info.Gui

			if Gui and Gui.Parent and Movement == 3 then
				local Tween = TweenService:Create(
					Gui,
					TweenInfo.new(
						0.15,
						Enum.EasingStyle.Quart,
						Enum.EasingDirection.InOut
					),
					{
						Size = BigSizes[Gui]
					}
				)

				Movement3Tween = Tween
				Tween:Play()
			end
		end

		task.spawn(function()
			task.wait(0.1)

			if Model and Model.Parent and Movement == 3 then
				SetImage("131776742309770")
			end
		end)

		task.wait(0.15)

		if not Model or not Model.Parent or Movement ~= 3 then
			break
		end

		if os.clock() - Movement3Start >= 2 then
			break
		end
	end


	-- =========================
	-- RESET + LOOP BACK TO 1
	-- =========================

	if not Model or not Model.Parent or Movement == 0 then
	return
end

Movement = 1

	CancelAllTweens()
	ResetBillboards()
end
