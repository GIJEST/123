local lp = game.Players.LocalPlayer
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")

local dist = 5
getgenv().Farm = false
local anchorEnabled = false
local lastPulledTargets = {}

local excludedNPCNames = {}
local excludedPlayerNames = {}

local selectedTab = "NPC"
local selectedTeamFilter = "All"

local function isSelf(p)
	return p == lp or p == lp.Character or (p:IsDescendantOf(lp.Character))
end

local function getTeamColor(p)
	if p:IsA("Player") then return p.Team and p.Team.TeamColor.Color or Color3.new(1,1,1) end
	return Color3.new(1,1,1)
end

local function passesTeamFilter(p)
	if selectedTeamFilter == "All" then return true end
	if not p:IsA("Player") or not p.Team then return false end
	if selectedTeamFilter == "My Team" then return p.Team == lp.Team end
	if selectedTeamFilter == "Other Team" then return p.Team ~= lp.Team end
	return false
end

local function createCheck(name, parent, list, teamColor)
	local f = Instance.new("Frame", parent)
	f.Size = UDim2.new(1, 0, 0, 26)
	f.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	f.BorderSizePixel = 0

	local l = Instance.new("TextLabel", f)
	l.Size = UDim2.new(1, -30, 1, 0)
	l.Position = UDim2.new(0, 5, 0, 0)
	l.Text = name
	l.BackgroundTransparency = 1
	l.TextColor3 = teamColor or Color3.new(1, 1, 1)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Font = Enum.Font.SourceSans
	l.TextSize = 16

	local b = Instance.new("TextButton", f)
	b.Size = UDim2.new(0, 24, 0, 24)
	b.Position = UDim2.new(1, -28, 0.5, -12)
	b.Text = list[name] and "✔" or ""
	b.BackgroundColor3 = list[name] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(60, 60, 60)
	b.BorderSizePixel = 0
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 18
	b.AutoButtonColor = false

	b.MouseButton1Click:Connect(function()
		list[name] = not list[name]
		b.Text = list[name] and "✔" or ""
		b.BackgroundColor3 = list[name] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(60, 60, 60)
	end)
end

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "PullGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 470)
frame.Position = UDim2.new(0, 30, 0.5, -235)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true

local mover = Instance.new("Frame", frame)
mover.Size = UDim2.new(1, 0, 0, 20)
mover.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mover.BorderSizePixel = 0

local dragging, offset
mover.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		offset = Vector2.new(i.Position.X, i.Position.Y) - Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
	end
end)
uis.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
uis.InputChanged:Connect(function(i)
	if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
		local p = Vector2.new(i.Position.X, i.Position.Y) - offset
		frame.Position = UDim2.new(0, p.X, 0, p.Y)
	end
end)

local tabs = Instance.new("Frame", frame)
tabs.Size = UDim2.new(1, 0, 0, 30)
tabs.Position = UDim2.new(0, 0, 0, 20)
tabs.BackgroundTransparency = 1

local npcBtn = Instance.new("TextButton", tabs)
npcBtn.Size = UDim2.new(0.5, 0, 1, 0)
npcBtn.Text = "NPCs"
npcBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
npcBtn.BorderSizePixel = 0
npcBtn.TextColor3 = Color3.new(1, 1, 1)
npcBtn.Font = Enum.Font.SourceSansBold
npcBtn.TextSize = 16

local plrBtn = Instance.new("TextButton", tabs)
plrBtn.Size = UDim2.new(0.5, 0, 1, 0)
plrBtn.Position = UDim2.new(0.5, 0, 0, 0)
plrBtn.Text = "Players"
plrBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
plrBtn.BorderSizePixel = 0
plrBtn.TextColor3 = Color3.new(1, 1, 1)
plrBtn.Font = Enum.Font.SourceSansBold
plrBtn.TextSize = 16

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -10, 1, -160)
scroll.Position = UDim2.new(0, 5, 0, 85)
scroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.BorderSizePixel = 0

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local teamFilterFrame = Instance.new("Frame", frame)
teamFilterFrame.Size = UDim2.new(1, -10, 0, 26)
teamFilterFrame.Position = UDim2.new(0, 5, 0, 55)
teamFilterFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
teamFilterFrame.BorderSizePixel = 0

local teamFilters = { "All", "My Team", "Other Team" }
local filterButtons = {}

for i, t in ipairs(teamFilters) do
	local b = Instance.new("TextButton", teamFilterFrame)
	b.Size = UDim2.new(1/#teamFilters, -2, 1, 0)
	b.Position = UDim2.new((i-1)/#teamFilters, (i-1)*2, 0, 0)
	b.Text = t
	b.BackgroundColor3 = t == "All" and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(60, 60, 60)
	b.BorderSizePixel = 0
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.SourceSans
	b.TextSize = 14
	filterButtons[t] = b

	b.MouseButton1Click:Connect(function()
		if selectedTeamFilter == t then
			selectedTeamFilter = "All"
		else
			selectedTeamFilter = t
		end
		for k, btn in pairs(filterButtons) do
			btn.BackgroundColor3 = k == selectedTeamFilter and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(60, 60, 60)
		end
		updateList()
	end)
end

local sliderLbl = Instance.new("TextLabel", frame)
sliderLbl.Size = UDim2.new(1, -20, 0, 20)
sliderLbl.Position = UDim2.new(0, 10, 1, -70)
sliderLbl.Text = "Distance: "..dist
sliderLbl.TextColor3 = Color3.new(1, 1, 1)
sliderLbl.BackgroundTransparency = 1
sliderLbl.Font = Enum.Font.SourceSans
sliderLbl.TextSize = 16

local sliderBack = Instance.new("Frame", frame)
sliderBack.Size = UDim2.new(1, -20, 0, 10)
sliderBack.Position = UDim2.new(0, 10, 1, -50)
sliderBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sliderBack.BorderSizePixel = 0

local knob = Instance.new("Frame", sliderBack)
knob.Size = UDim2.new(0, 10, 1, 0)
knob.Position = UDim2.new(dist/20, -5, 0, 0)
knob.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
knob.BorderSizePixel = 0

local draggingSlider = false
knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = true end end)
uis.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end end)
uis.InputChanged:Connect(function(i)
	if draggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
		local x = math.clamp((i.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
		dist = math.floor(x * 20)
		knob.Position = UDim2.new(x, -5, 0, 0)
		sliderLbl.Text = "Distance: "..dist
	end
end)

local status = Instance.new("Frame", frame)
status.Size = UDim2.new(0, 10, 0, 10)
status.Position = UDim2.new(1, -20, 1, -20)
status.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
status.BorderSizePixel = 0

local anchorBtn = Instance.new("TextButton", frame)
anchorBtn.Size = UDim2.new(0, 80, 0, 24)
anchorBtn.Position = UDim2.new(1, -90, 1, -100)
anchorBtn.Text = "Anchor"
anchorBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
anchorBtn.TextColor3 = Color3.new(1, 1, 1)
anchorBtn.BorderSizePixel = 0
anchorBtn.Font = Enum.Font.SourceSansBold
anchorBtn.TextSize = 16

anchorBtn.MouseButton1Click:Connect(function()
	anchorEnabled = not anchorEnabled
	anchorBtn.BackgroundColor3 = anchorEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(60, 60, 60)
end)

function updateList()
	for _, c in pairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	if selectedTab == "NPC" then
		local addedNames = {}
		for _, d in ipairs(workspace:GetDescendants()) do
			if typeof(d) == "Instance" and d:IsA("Humanoid") and d.Health > 0 then
				local npc = d.Parent
				if not isSelf(npc) and not game.Players:GetPlayerFromCharacter(npc) then
					if not addedNames[npc.Name] then
						addedNames[npc.Name] = true
						createCheck(npc.Name, scroll, excludedNPCNames)
					end
				end
			end
		end
	else
		for _, p in ipairs(game.Players:GetPlayers()) do
			if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and passesTeamFilter(p) then
				createCheck(p.Name, scroll, excludedPlayerNames, getTeamColor(p))
			end
		end
	end
end

npcBtn.MouseButton1Click:Connect(function()
	selectedTab = "NPC"
	npcBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	plrBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	updateList()
end)

plrBtn.MouseButton1Click:Connect(function()
	selectedTab = "Player"
	plrBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	npcBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	updateList()
end)

task.defer(function()
	updateList()
end)

local updateThread

uis.InputBegan:Connect(function(i, g)
	if g then return end
	if i.KeyCode == Enum.KeyCode.H then
		getgenv().Farm = not getgenv().Farm
		status.BackgroundColor3 = getgenv().Farm and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

		if getgenv().Farm then
			updateList()
			if updateThread == nil or coroutine.status(updateThread) == "dead" then
				updateThread = coroutine.create(function()
					while getgenv().Farm do
						task.wait(3)
						if getgenv().Farm then
							updateList()
						end
					end
				end)
				coroutine.resume(updateThread)
			end
		else
			if anchorEnabled then
				for _, t in ipairs(lastPulledTargets) do
					local hrp = t:FindFirstChild("HumanoidRootPart")
					if hrp then hrp.Anchored = true end
				end
			end
		end
	end
end)

rs.Heartbeat:Connect(function()
	if not getgenv().Farm or not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
	local h = lp.Character.HumanoidRootPart
	lastPulledTargets = {}

	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Humanoid") and d.Health > 0 then
			local p = d.Parent
			if p and p:FindFirstChild("HumanoidRootPart") and not isSelf(p) then
				local isNPC = game.Players:GetPlayerFromCharacter(p) == nil
				local skip = isNPC and excludedNPCNames[p.Name] or (not isNPC and excludedPlayerNames[p.Name])
				if not skip and (isNPC or passesTeamFilter(game.Players:GetPlayerFromCharacter(p))) then
					for _, b in ipairs(p:GetDescendants()) do
						if b:IsA("BasePart") then
							b.CanCollide = false
							b.Massless = true
						end
					end
					local hrp = p.HumanoidRootPart
					local hmd = p:FindFirstChildOfClass("Humanoid")
					if hrp and hmd then
						hrp.Anchored = false
						hmd.PlatformStand = true
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
						hrp.CFrame = h.CFrame + h.CFrame.LookVector * dist
						table.insert(lastPulledTargets, p)
					end
				end
			end
		end
	end
end)
