-- Credits: Federal, Ak Admin

-- [[ Services ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")

-- [[ Auto VC Unban]]
local VoiceChatService = game:GetService("VoiceChatService")
local AudioFocusService = game:GetService("AudioFocusService")

    local function removeSuspension()
    task.wait(0.2)
    local _vc = game:GetService("VoiceChatInternal")
    VoiceChatService:joinVoice()
    VoiceChatService:rejoinVoice()
    _vc:JoinByGroupIdToken("", false, true)
    VoiceChatService:joinVoice()
    task.wait(0.1)
end

game:GetService("VoiceChatInternal").LocalPlayerModerated:Connect(removeSuspension)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Sentinel" .. " vRewrite",
    SubTitle = "by fuckluau",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.K
})

local Tabs = {
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Workspace = Window:AddTab({ Title = "Workspace", Icon = "hard-drive" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "chevrons-up" }),
    Reanimation = Window:AddTab({ Title = "Reanimation", Icon = "person-standing" }),
    Exploits = Window:AddTab({ Title = "Exploits", Icon = "scroll" }),
    Voice = Window:AddTab({ Title = "Voice", Icon = "mic" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "box" })
}

Window:SelectTab(1)

-- [[ Player Section ]]
local WalkspeedSlider = Tabs.Player:AddSlider("Slider", {
    Title = "Walkspeed",
    Description = "",
    Default = 16,
    Min = 1,
    Max = 350,
    Rounding = 0,
    Callback = function(Value)
        local function getHumanoid()
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            return character and character:FindFirstChildOfClass("Humanoid")
        end

        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = Value
        end
    end
})

local JumppowerSlider = Tabs.Player:AddSlider("Slider", {
    Title = "Jumppower",
    Description = "",
    Default = 55,
    Min = 55,
    Max = 150,
    Rounding = 0,
    Callback = function(Value)
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = Value
            char.Humanoid.UseJumpPower = true
        end
    end
})

if game.PlaceId == 6884319169 then
Tabs.Player:AddButton({
    Title = "Refresh Character",
    Description = "Refreshes your character's appearance",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")

        local button = playerGui:WaitForChild("Menu")
            .Hub.Modify.Right.Refresh
            .Frame.Frame.Frame:FindFirstChild("TextButton")

        if button and button:IsA("TextButton") then
            for _, connection in pairs(getconnections(button.MouseButton1Click)) do
                connection:Fire()
            end
        end
    end
})
else
end

-- [[ Tp Tool ]]
Tabs.Player:AddButton({
    Title = "Teleport Tool",
    Description = "Gives you a tool that teleports you to where you click",
    Callback = function()
        local player = game.Players.LocalPlayer
        local mouse = player:GetMouse()

        local oldTool = player.Backpack:FindFirstChild("Click Teleport")
        if oldTool then oldTool:Destroy() end

        local tool = Instance.new("Tool")
        tool.RequiresHandle = false
        tool.Name = "Click Teleport"

        tool.Activated:Connect(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end

            local pos = mouse.Hit.Position + Vector3.new(0, 2.5, 0)
            local rot = select(2, char.HumanoidRootPart.CFrame:ToEulerAnglesYXZ())
            char.HumanoidRootPart.CFrame = CFrame.new(pos) * CFrame.Angles(0, rot, 0)
        end)

        tool.Parent = player.Backpack
    end
})

local TeleportSection = Tabs.Player:AddSection("Random Shit")

-- [[ Face Fuck ]]
Tabs.Player:AddButton({
    Title = "Face Fuck",
    Description = "Face fucks your friend aggressively",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EnterpriseExperience/bruhlolw/refs/heads/main/face_bang_script.lua"))()
    end
})

-- [[ Rewind ]]
Tabs.Player:AddButton({
    Title = "Rewind (Hold C)",
    Description = "Rewind your characters movement",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/platinum-ViniVX/mic-up-script-pack/refs/heads/main/rewind%20script"))()
    end
})

-- [[ Head Sit ]]
Tabs.Player:AddButton({
    Title = "Head Sit (X)",
    Description = "Sit on nearby player's head",
    Callback = function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local UIS = game:GetService("UserInputService")
        local Workspace = game:GetService("Workspace")
        local plr = Players.LocalPlayer

        local char, hrp, hum
        local sitting = false
        local hbConn, inputConn

        local function loadChar()
            char = plr.Character or plr.CharacterAdded:Wait()
            hrp = char:WaitForChild("HumanoidRootPart")
            hum = char:WaitForChild("Humanoid")
        end

        local function getNearestHRP()
            local closest, shortest = nil, math.huge
            local myPos = hrp and hrp.Position
            if not myPos then return nil end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= plr and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = p.Character.HumanoidRootPart
                    end
                end
            end
            return closest
        end

        local function stopSit()
            sitting = false
            if hbConn then hbConn:Disconnect() hbConn = nil end
            if hum then hum.Sit = false end
            if hrp then
                hrp.Velocity, hrp.RotVelocity = Vector3.zero, Vector3.zero
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {char}
                params.FilterType = Enum.RaycastFilterType.Blacklist
                local hit = Workspace:Raycast(hrp.Position, Vector3.new(0, -100, 0), params)
                hrp.CFrame = hit and CFrame.new(hit.Position + Vector3.new(0, 3, 0)) or (hrp.CFrame - Vector3.new(0, 5, 0))
            end
        end

        local function startSit()
            local target = getNearestHRP()
            if not target then return end
            sitting = true
            hum.Sit = true
            if hbConn then hbConn:Disconnect() end
            hbConn = RunService.Heartbeat:Connect(function()
                if not sitting or not target.Parent then stopSit() return end
                hum.Sit = true
                hrp.CFrame = target.CFrame * CFrame.new(0, 3, 0)
                hrp.Velocity, hrp.RotVelocity = Vector3.zero, Vector3.zero
            end)
        end

        loadChar()

        if inputConn then inputConn:Disconnect() end
        inputConn = UIS.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.X then
                if sitting then stopSit() else startSit() end
            end
        end)

        plr.CharacterAdded:Connect(function()
            task.wait(1)
            loadChar()
        end)
    end
})

local PlayerSection = Tabs.Player:AddSection("Fun")

-- [[ Player Spin ]]
local player = Players.LocalPlayer
local spinSpeed = 500
local spinning = false
local spinDirection = 1

local function updateSpin(char)
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then
        local success
        success, root = pcall(function()
            return char:WaitForChild("HumanoidRootPart", 2)
        end)
        if not success or not root then
            warn("Could not find HumanoidRootPart")
            return
        end
    end

    local existingBAV = root:FindFirstChild("SpinBAV")
    if existingBAV then
        existingBAV:Destroy()
    end

    if spinning then
        local bav = Instance.new("BodyAngularVelocity")
        bav.Name = "SpinBAV"
        bav.Parent = root
        bav.MaxTorque = Vector3.new(0, math.huge, 0)
        bav.P = 1250
        bav.AngularVelocity = Vector3.new(0, spinSpeed * math.pi / 180 * spinDirection, 0)
    end
end

player.CharacterAdded:Connect(function(char)
    if spinning then
        updateSpin(char)
    end
end)

-- [[ Ball Mode ]]
local player = Players.LocalPlayer
local speedmultiplier, jumppower, jumpgap = 30, 60, 0.3
local ballConnection, jumpConnection

local function enableBall()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    root.Shape = Enum.PartType.Ball
    root.Size = Vector3.new(5, 5, 5)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {char}

    ballConnection = RunService.RenderStepped:Connect(function(delta)
        if not root or not humanoid or humanoid.Health <= 0 then return end
        root.CanCollide = true
        humanoid.PlatformStand = true
        if UserInputService:GetFocusedTextBox() then return end

        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.LookVector end

        if move.Magnitude > 0 then
            root.RotVelocity += move.Unit * delta * speedmultiplier
        end
    end)

    jumpConnection = UserInputService.JumpRequest:Connect(function()
        local result = workspace:Raycast(
            root.Position,
            Vector3.new(0, -((root.Size.Y / 2) + jumpgap), 0),
            params
        )
        if result then
            root.Velocity = root.Velocity + Vector3.new(0, jumppower, 0)
        end
    end)

    Camera.CameraSubject = root
end

local function disableBall()
    local char = player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(root.Position)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Shape = Enum.PartType.Block
        root.Size = Vector3.new(2, 2, 1)
        root.CanCollide = true
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    if ballConnection then ballConnection:Disconnect(); ballConnection = nil end
    if jumpConnection then jumpConnection:Disconnect(); jumpConnection = nil end

    Camera.CameraSubject = humanoid
end

-- [[ Jerk Off ]]
local jerkingEnabled = false
local jerkingSpeed = 0.6
local timePosition = 0.6
local jerkAnim = nil
local jerkTrack = nil

Tabs.Player:AddToggle("JerkToggle", {
    Title = "Jerk Off",
    Default = false,
    Callback = function(state)
        jerkingEnabled = state
        
        if state then
            if jerkTrack and jerkTrack.IsPlaying then
                return
            end
            
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            
            jerkAnim = Instance.new("Animation")
            jerkAnim.AnimationId = "rbxassetid://698251653"
            jerkTrack = humanoid:LoadAnimation(jerkAnim)
            
            task.spawn(function()
                while jerkingEnabled and jerkTrack do
                    jerkTrack:Play()
                    jerkTrack:AdjustSpeed(jerkingSpeed)
                    jerkTrack.TimePosition = timePosition
                    task.wait(0.1)
                end
            end)
        else
            if jerkTrack then
                jerkTrack:Stop()
                jerkTrack = nil
            end
            if jerkAnim then
                jerkAnim:Destroy()
                jerkAnim = nil
            end
        end
    end
})

Tabs.Player:AddToggle("BallModeToggle", {
    Title = "Ball Mode",
    Default = false,
    Callback = function(state)
        ballMode = state
        if state then
            enableBall()
        else
            disableBall()
        end
    end
})

local spinToggle = Tabs.Player:AddToggle("spinToggle", {
    Title = "Enable Player Spin",
    Default = false,
    Callback = function(state)
        spinning = state
        if player.Character then
            updateSpin(player.Character)
        end
    end
})

Tabs.Player:AddSlider("JerkSpeedSlider", {
    Title = "Jerk Speed",
    Description = "Adjust animation speed",
    Default = jerkingSpeed,
    Min = 0.2,
    Max = 3,
    Rounding = 1,
    Callback = function(value)
        jerkingSpeed = value
        if jerkTrack then
            jerkTrack:AdjustSpeed(jerkingSpeed)
        end
    end
})

Tabs.Player:AddSlider("BallSpeedSlider", {
    Title = "Ball Speed",
    Description = "Adjust ball movement speed",
    Default = speedmultiplier,
    Min = 16,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        speedmultiplier = value
    end
})

local Slider = Tabs.Player:AddSlider("Slider", {
    Title = "Spin Speed",
    Description = "",
    Default = 500,
    Min = 50,
    Max = 5000,
    Rounding = 0,
    Callback = function(Value)
        spinSpeed = Value
        if player.Character and spinning then
            updateSpin(player.Character)
        end
    end
})

-- [[ Workspace Section ]]

local Section = Tabs.Workspace:AddSection("Server Utilities")

-- [[ Anti Lag ]]
if game.PlaceId == 6884319169 then 
    local ModifyListAddDelete = ReplicatedStorage:WaitForChild("ModifyListAddDelete")
    local micEvent = ReplicatedStorage:WaitForChild("MicEvent")
end

local antiLagToggled = false
local antiLagThread = nil
local antiLagConnections = {}
local targetItemNames = { "aura", "Fluffy Satin Gloves Black" }
local batchSize = 10

local function hasItemInName(accessory)
    for _, itemName in ipairs(targetItemNames) do
        if accessory.Name:lower():find(itemName:lower()) then
            return true
        end
    end
    return false
end

local function isonhead(accessory)
    local handle = accessory:FindFirstChild("Handle")
    if handle and handle.Parent and handle.Parent.Name == "Head" then
        return true
    end
    local attachment = accessory:FindFirstChildWhichIsA("Attachment")
    if attachment and attachment.Parent and attachment.Parent.Name == "Head" then
        return true
    end
    if accessory.Parent and accessory.Parent:IsA("Model") then
        local head = accessory.Parent:FindFirstChild("Head")
        if head and handle and handle.Position.Y >= head.Position.Y then
            return true
        end
    end
    return false
end

local function removeitems(character)
    if not character then return end
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Accessory") and 
           not item:FindFirstChild("BillboardGui") and 
           not item:FindFirstChild("SurfaceGui") and
           hasItemInName(item) and 
           not isonhead(item) then
            item:Destroy()
        end
    end
end

local function plyrbatch()
    local players = Players:GetPlayers()
    local n = #players
    for i = 1, n, batchSize do
        if not antiLagToggled then break end
        for j = i, math.min(i + batchSize - 1, n) do
            local char = players[j].Character
            if char then
                removeitems(char)
            end
        end
        task.wait()
    end
end

local function donutbatch()
    local descendants = workspace:GetDescendants()
    local n = #descendants
    for i = 1, n, batchSize do
        if not antiLagToggled then break end
        for j = i, math.min(i + batchSize - 1, n) do
            local obj = descendants[j]
            if obj:IsA("BasePart") and obj.Name:lower():find("gradientdonut") then
                obj:Destroy()
            end
        end
        task.wait()
    end
end

local function onAccessoryAdded(accessory)
    if hasItemInName(accessory) and not isonhead(accessory) then
        accessory:Destroy()
    end
end

local function onCharacterAdded(character)
    removeitems(character)
    local conn = character.ChildAdded:Connect(function(child)
        if child:IsA("Accessory") then
            onAccessoryAdded(child)
        end
    end)
    table.insert(antiLagConnections, conn)
end

local function onPlayerAdded(player)
    if player.Character then
        onCharacterAdded(player.Character)
    end
    local charConn = player.CharacterAdded:Connect(onCharacterAdded)
    table.insert(antiLagConnections, charConn)
end

local function onWorkspaceDescendantAdded(obj)
    if obj:IsA("BasePart") and obj.Name:lower():find("gradientdonut") then
        obj:Destroy()
    end
end

local function connectAntiLagEvents()
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    table.insert(antiLagConnections, Players.PlayerAdded:Connect(onPlayerAdded))
    table.insert(antiLagConnections, workspace.DescendantAdded:Connect(onWorkspaceDescendantAdded))
end

local function disconnectAntiLagEvents()
    for _, conn in ipairs(antiLagConnections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    table.clear(antiLagConnections)
end

local function antiLagLoop()
    while antiLagToggled do
        plyrbatch()
        donutbatch()
        task.wait(2)
    end
end

local function startAntiLag()
    if antiLagThread then return end
    antiLagToggled = true
    connectAntiLagEvents()
    antiLagThread = task.spawn(function()
        antiLagLoop()
        antiLagThread = nil
    end)
end

local function stopAntiLag()
    antiLagToggled = false
    disconnectAntiLagEvents()
end

if game.PlaceId == 6884319169 then
local Toggle = Tabs.Workspace:AddToggle("MyToggle", 
{
    Title = "Anti Lag", 
    Description = "Reduces lag specificaly for Mic Up",
    Default = false,
    Callback = function(state)
	if state then
        startAntiLag()
	else
        stopAntiLag()
        end
    end 
})
else
    local button = Tabs.Workspace:AddButton({
        Title = "You Are Not In Mic Up",
        Description = "This feature is only available in Mic Up",
        Callback = function() end
    })
end

-- [[ Booth / White Board Section ]]
local BoothsSection = Tabs.Workspace:AddSection("Booths / White Board")

local function getCharMap()
    return {
        A = "Aօ", B = "B", C = "Cօ", D = "D", E = "օEօ", F = "Fօ", G = "Gօ", H = "H", I = "օlօ", J = "J",
        K = "օKօ", L = "Lօ", M = "M", N = "Nօ", O = "O", P = "Pօ", Q = "Q", R = "Rօ", S = "Sօ", T = "T",
        U = "Uօ", V = "V", W = "W", X = "X", Y = "Y", Z = "Z",
        a = "aօ", b = "b", c = "cօ", d = "d", e = "օeօ", f = "fօ", g = "gօ", h = "h", i = "iօ", j = "j",
        k = "kօ", l = "l", m = "m", n = "nօ", o = "o", p = "p", q = "q", r = "rօ", s = "sօ", t = "t",
        u = "uօ", v = "v", w = "w", x = "x", y = "y", z = "z"
    }
end

local function bypassText(str, charMap, iVariant)
    charMap = table.clone(charMap)
    if not iVariant then charMap.I = "lօ" end
    local chars = {}
    for c in str:gmatch(".") do
        table.insert(chars, charMap[c] or c)
    end
    local modified = table.concat(chars)
    if not modified:find("%s") then
        local mid = math.floor(#modified / 2)
        modified = modified:sub(1, mid) .. "" .. modified:sub(mid + 1)
    end
    return table.concat(modified:split(""), "\t")
end

if game.PlaceId == 6884319169 then
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UpdateBoothText = ReplicatedStorage:WaitForChild("UpdateBoothText")
    local EventTextSchool = ReplicatedStorage:WaitForChild("EventTextSchool")
    local charMap = getCharMap()

    BoothsSection:AddInput("Input", {
        Title = "Booth Bypass",
        Description = "Bypass booth text restrictions",
        Placeholder = "Enter text",
        Finished = true,
        Callback = function(input)
            local text = bypassText(input, charMap, true)
            local args = { text, "Gray", "DenkOne" }
            UpdateBoothText:FireServer(unpack(args))
        end,
    })

    BoothsSection:AddInput("WhiteBoardInput", {
        Title = "White Board",
        Description = "Bypass white board text restrictions",
        Placeholder = "Enter text",
        Finished = true,
        Callback = function(input)
            if input ~= "" then
                local text = bypassText(input, charMap, false)
                EventTextSchool:FireServer(text)
            end
        end,
    })
else
    Tabs.Workspace:AddButton({
        Title = "You Are Not In Mic Up",
        Description = "This feature is only available in Mic Up",
        Callback = function() end
    })
end

-- [[ Baseplate Section ]]
local BaseplateSection = Tabs.Workspace:AddSection("Baseplate")

-- [[ Baseplate Expander ]]
local baseplateColor = Color3.fromRGB(50, 50, 50)
local baseplatePosition = Vector3.new(66, 13.5, 72.5)
local baseplateSize = Vector3.new(40000, 5, 40000)
local baseplateMaterial = Enum.Material.Asphalt
local baseplateTransparency = 0
local maxPartSize = 2048

local function createBaseplate()
    local Workspace = workspace
    if Workspace:FindFirstChild("TERRAIN_EDITOR") then
        return 
    end

    local TerrainFolder = Instance.new("Folder")
    TerrainFolder.Name = "TERRAIN_EDITOR"
    TerrainFolder.Parent = Workspace

    local baseX, baseY, baseZ = baseplateSize.X, baseplateSize.Y, baseplateSize.Z
    local divX = math.ceil(baseX / maxPartSize)
    local divZ = math.ceil(baseZ / maxPartSize)
    local partSizeX = baseX / divX
    local partSizeZ = baseZ / divZ
    local partSize = Vector3.new(partSizeX, baseY, partSizeZ)
    local basePos = baseplatePosition

    for i = 0, divX - 1 do
        local offsetX = (i - (divX / 2)) * partSizeX + (partSizeX / 2)
        for j = 0, divZ - 1 do
            local offsetZ = (j - (divZ / 2)) * partSizeZ + (partSizeZ / 2)
            local part = Instance.new("Part")
            part.Size = partSize
            part.Position = basePos + Vector3.new(offsetX, 0, offsetZ)
            part.Anchored = true
            part.Material = baseplateMaterial
            part.Color = baseplateColor
            part.Transparency = baseplateTransparency
            part.Parent = TerrainFolder
        end
    end
end

local function destroyBaseplate()
    local terrainFolder = workspace:FindFirstChild("TERRAIN_EDITOR")
    if terrainFolder then
        terrainFolder:Destroy()
    end
end

Tabs.Workspace:AddButton({
    Title = "Create Baseplate",
    Description = "Creates a large baseplate",
    Callback = createBaseplate
})

Tabs.Workspace:AddButton({
    Title = "Destroy Baseplate",
    Description = "Removes the created baseplate",
    Callback = destroyBaseplate
})

local Colorpicker = Tabs.Workspace:AddColorpicker("Colorpicker", {
    Title = "Colorpicker",
    Description = "Description for colorpicker",
    Default = Color3.fromRGB(96, 205, 255)
})

Colorpicker:OnChanged(function(color)
            baseplateColor = color
        local folder = workspace:FindFirstChild("TERRAIN_EDITOR")
        if folder then
            for _, part in ipairs(folder:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Color = color
                end
            end
        end
end)
    
Colorpicker:SetValueRGB(Color3.fromRGB(50, 50, 50))

-- [[ Teleport Section ]]
local Section = Tabs.Teleport:AddSection("Mic Up Teleports")

if game.PlaceId == 6884319169 then
Tabs.Teleport:AddButton({
    Title = "Teleport To Spawn",
    Description = "Teleports to a random spawn point",
    Callback = function()
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")

        local spawns = {}
        for _, part in ipairs(workspace:GetChildren()) do
            if part:IsA("Part") and part.Name:lower():find("spawn") then
                spawns[#spawns + 1] = part
            end
        end

        if #spawns > 0 then
            root.CFrame = spawns[math.random(#spawns)].CFrame + Vector3.new(0, 5, 0)
        end
    end
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

Tabs.Teleport:AddButton({
    Title = "Teleport To Floating Platform",
    Description = "Teleports to tower coordinates",
    Callback = function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")
        root.CFrame = CFrame.new(718.84, 910.55, -181.80)
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleport To Booths",
    Description = "Teleports to booths",
    Callback = function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")
        root.CFrame = CFrame.new(582.97, 21.10, -160.05)
    end
})
else
    Tabs.Teleport:AddButton({
    Title = "You Are Not In Mic Up",
    Description = "This feature is only available in Mic Up",
    Callback = function()
    end
})
end

local TeleportSection = Tabs.Teleport:AddSection("Player Teleports")

local selectedPlayerName = ""

local Input = Tabs.Teleport:AddInput("Input", {
    Title = "Username Input",
    Description = "Select a player to teleport to",
    Default = "",
    Placeholder = "User/Display",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        selectedPlayerName = Value
    end
})

Tabs.Teleport:AddButton({
    Title = "Confirm Teleport",
    Description = "Teleport to the specified player",
    Callback = function()
        if selectedPlayerName == "" then 
            return 
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and 
               (player.Name:lower():find(selectedPlayerName:lower()) or 
                player.DisplayName:lower():find(selectedPlayerName:lower())) then
                
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local root = char:WaitForChild("HumanoidRootPart")
                
                local targetChar = player.Character
                if targetChar then
                    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        root.CFrame = targetRoot.CFrame + Vector3.new(0, 5, 0)
                        break
                    end
                end
            end
        end
    end
})

-- [[ Exploits Section ]]
Tabs.Exploits:AddButton({
    Title = "Infinite Yield",
    Description = "Executes Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/edgeiy/infiniteyield/master/source"))()
    end
})

Tabs.Exploits:AddButton({
    Title = "System Broken",
    Description = "Executes System Broken",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/H20CalibreYT/SystemBroken/main/script"))()
    end
})

local reanimsupport = {
    [6884319169] = true,
    [5950733731] = true,
    [5683833663] = true
}

if reanimsupport[game.PlaceId] then
    Tabs.Reanimation:AddButton({
        Title = "Load R15 Reanimation",
        Description = "Loads R15 reanimation script",
        Callback = function()
            loadstring(game:HttpGet("https://ichfickdeinemutta.pages.dev/sizechanger.lua"))()
        end
    })
else
    Tabs.Reanimation:AddButton({
        Title = "You Are Not In Mic Up",
        Description = "This feature is only available in Mic Up",
        Callback = function() end
    })
end

-- [[ Snake Reanim ]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local snakeorder = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot"
}

local snakeDistance = 1.0
local snakeSmoothing = 0.1

local ghostEnabled = false
local originalCharacter
local ghostClone
local originalCFrame
local updateConnection
local previousPositions = {}
local targetPositions = {}

local function updateSnakeParts()
    if not ghostEnabled or not originalCharacter or not originalCharacter.Parent or 
       not ghostClone or not ghostClone.Parent then
        if updateConnection then
            updateConnection:Disconnect()
            updateConnection = nil
        end
        return
    end

    local rootPart = ghostClone:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local isMoving = rootPart.AssemblyLinearVelocity.Magnitude > 0.1
    local firstPartName = snakeorder[1]
    local firstPart = originalCharacter:FindFirstChild(firstPartName)

    if firstPart then
        if not targetPositions[firstPartName] then targetPositions[firstPartName] = firstPart.CFrame end
        if not previousPositions[firstPartName] then previousPositions[firstPartName] = firstPart.CFrame end

        if isMoving then
            local targetCFrame = CFrame.new(rootPart.Position) * (rootPart.CFrame - rootPart.Position)
            targetPositions[firstPartName] = targetCFrame
        end

        local smoothCFrame = previousPositions[firstPartName]:Lerp(targetPositions[firstPartName], snakeSmoothing)
        firstPart.CFrame = smoothCFrame
        firstPart.AssemblyLinearVelocity = Vector3.zero
        firstPart.AssemblyAngularVelocity = Vector3.zero
        previousPositions[firstPartName] = smoothCFrame

        for i = 2, #snakeorder do
            local partName = snakeorder[i]
            local currentPart = originalCharacter:FindFirstChild(partName)
            local previousPart = originalCharacter:FindFirstChild(snakeorder[i-1])

            if currentPart and previousPart then
                if not targetPositions[partName] then targetPositions[partName] = currentPart.CFrame end
                if not previousPositions[partName] then previousPositions[partName] = currentPart.CFrame end

                if isMoving then
                    local prevPartPos = previousPart.Position
                    local prevPartRot = previousPart.CFrame - previousPart.Position
                    local directionVector

                    if i == 2 then
                        directionVector = (prevPartPos - rootPart.Position).Unit
                    else
                        local beforePreviousPart = originalCharacter:FindFirstChild(snakeorder[i-2])
                        if beforePreviousPart then
                            directionVector = (prevPartPos - beforePreviousPart.Position).Unit
                        else
                            directionVector = prevPartRot.LookVector
                        end
                    end

                    if directionVector.Magnitude < 0.1 then
                        directionVector = prevPartRot.LookVector
                    end

                    local targetPosition = prevPartPos + directionVector * snakeDistance
                    targetPositions[partName] = CFrame.new(targetPosition) * prevPartRot
                end

                local smoothCFrame = previousPositions[partName]:Lerp(targetPositions[partName], snakeSmoothing)
                currentPart.CFrame = smoothCFrame
                currentPart.AssemblyLinearVelocity = Vector3.zero
                currentPart.AssemblyAngularVelocity = Vector3.zero
                previousPositions[partName] = smoothCFrame
            end
        end
    end
end

local function setGhostEnabled(newState)
    ghostEnabled = newState

    if ghostEnabled then
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root then return end
        if originalCharacter or ghostClone then return end

        originalCharacter = char
        originalCFrame = root.CFrame
        char.Archivable = true
        ghostClone = char:Clone()
        char.Archivable = false
        ghostClone.Name = originalCharacter.Name .. "_clone"
        
        local ghostHumanoid = ghostClone:FindFirstChildWhichIsA("Humanoid")
        if ghostHumanoid then
            ghostHumanoid.DisplayName = originalCharacter.Name .. "_clone"
            ghostHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
        
        if not ghostClone.PrimaryPart then
            local hrp = ghostClone:FindFirstChild("HumanoidRootPart")
            if hrp then ghostClone.PrimaryPart = hrp end
        end
        
        for _, part in ipairs(ghostClone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                part.CanCollide = false
                part.Anchored = false
                part.CanQuery = false
            elseif part:IsA("Decal") then
                part.Transparency = 1
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then
                    handle.Transparency = 1
                    handle.CanCollide = false
                    handle.CanQuery = false
                end
            end
        end
        
        local animate = originalCharacter:FindFirstChild("Animate")
        if animate then
            animate.Disabled = true
            animate.Parent = ghostClone
        end
        
        ghostClone.Parent = Workspace
        LocalPlayer.Character = ghostClone
        
        if ghostHumanoid then
            Workspace.CurrentCamera.CameraSubject = ghostHumanoid
        end
        
        if animate and animate.Parent == ghostClone then
            animate.Disabled = false
        end
        if game.PlaceId == 6884319169 then
        local ohString1 = "Ball"
        ReplicatedStorage.Ragdoll:FireServer(ohString1)
        else
        local ohBoolean1 = true
        game:GetService("ReplicatedStorage").Events.RagdollState:FireServer(ohBoolean1)
        end
        
        targetPositions = {}
        previousPositions = {}
        
        if updateConnection then updateConnection:Disconnect() end
        updateConnection = RunService.Heartbeat:Connect(updateSnakeParts)

    else
        if not originalCharacter or not ghostClone then return end
        if updateConnection then
            updateConnection:Disconnect()
            updateConnection = nil
        end
        if game.PlaceId == 6884319169 then
            ReplicatedStorage.Unragdoll:FireServer()
        else
            local ohBoolean1 = false
            ReplicatedStorage.Events.RagdollState:FireServer(false)
        end

        local targetCFrame = originalCFrame
        local ghostPrimary = ghostClone.PrimaryPart
        if ghostPrimary then targetCFrame = ghostPrimary.CFrame end

        local animate = ghostClone:FindFirstChild("Animate")
        if animate then
            animate.Disabled = true
            animate.Parent = originalCharacter
        end

        ghostClone:Destroy()
        ghostClone = nil

        if originalCharacter and originalCharacter.Parent then
            local origRoot = originalCharacter:FindFirstChild("HumanoidRootPart")
            local origHumanoid = originalCharacter:FindFirstChildWhichIsA("Humanoid")

            if origRoot then
                origRoot.CFrame = targetCFrame
                origRoot.AssemblyLinearVelocity = Vector3.zero
                origRoot.AssemblyAngularVelocity = Vector3.zero
            end
            
            LocalPlayer.Character = originalCharacter
            
            if origHumanoid then
                Workspace.CurrentCamera.CameraSubject = origHumanoid
                origHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            
            if animate and animate.Parent == originalCharacter then
                task.wait(0.1)
                animate.Disabled = false
            end
        end
        
        originalCharacter = nil
    end
end

local function cleanup()
    if ghostEnabled then
        setGhostEnabled(false)
    end
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
end

if LocalPlayer.Character then
    LocalPlayer.Character.Destroying:Connect(function()
        if ghostEnabled then
            if updateConnection then
                updateConnection:Disconnect()
                updateConnection = nil
            end
            if ghostClone then
                ghostClone:Destroy()
                ghostClone = nil
            end
            originalCharacter = nil
            ghostEnabled = false
        end
    end)
end

if Tabs and Tabs.Reanimation then
    Tabs.Reanimation:AddToggle("SnakeReanim", {
        Title = "Snake Reanimation", 
        Description = "Makes your character snake-like",
        Default = false,
        Callback = function(state)
            setGhostEnabled(state)
        end 
    })

    Tabs.Reanimation:AddSlider("SnakeDistanceSlider", {
        Title = "Snake Distance",
        Description = "Changes snake length",
        Default = 1,
        Min = 0.1,
        Max = 10,
        Rounding = 1,
        Callback = function(value)
            snakeDistance = value
        end
    })
end

Tabs.Voice:AddButton({
    Title = "Unsuspend Voice Chat",
    Description = "Unsuspend your voice chat",
    Callback = function()
        game:GetService("VoiceChatService"):joinVoice()
    end
})

Tabs.Voice:AddButton({
    Title = "Disconnect Voice Chat",
    Description = "Disconnects from voice chat",
    Callback = function()
        local _vc = game:GetService("VoiceChatInternal")
        _vc:Leave()
    end
})

Tabs.Voice:AddButton({
    Title = "Voice Chat Prority Speaker",
    Description = "Makes you the priority speaker",
    Callback = function()
        game:GetService("AudioFocusService"):RegisterContextIdFromLua(100)
        task.wait()
        game:GetService("AudioFocusService"):RequestFocus(100, 9999999)
    end
})

local function preserveNameTag()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    
    humanoid.NameDisplayDistance = 100
    humanoid.HealthDisplayDistance = 100
    humanoid.NameOcclusion = Enum.NameOcclusion.NoOcclusion
end

preserveNameTag()

game.Players.LocalPlayer.CharacterAdded:Connect(preserveNameTag)
