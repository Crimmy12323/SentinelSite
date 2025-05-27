-- Credits to Federal for the ui design
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- [[ State for reanimation ]]
local ghostEnabled = false
local originalCharacter
local ghostClone
local originalCFrame
local originalAnimateScript
local updateConnection
local ghostOriginalHipHeight
local cloneSize = 1
local cloneWidth = 1
local ghostOriginalSizes = {}
local ghostOriginalMotorCFrames = {}
local bodyParts = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot"
}

-- [[ Adjusts the clone so its lowest part is on the ground ]]
local function adjustCloneToGround(clone)
    if not clone then return end
    local lowestY = math.huge
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            local bottomY = part.Position.Y - (part.Size.Y * 0.5)
            if bottomY < lowestY then
                lowestY = bottomY
            end
        end
    end
    local offset = 0 - lowestY
    if offset > 0 then
        if clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame + Vector3.new(0, offset, 0))
        else
            clone:TranslateBy(Vector3.new(0, offset, 0))
        end
    end
end

-- [[ Prevent GUI loss on respawn ]]
local preservedGuis = {}
local function preserveGuis()
    local playerGui = LocalPlayer:FindFirstChildWhichIsA("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.ResetOnSpawn then
                table.insert(preservedGuis, gui)
                gui.ResetOnSpawn = false
            end
        end
    end
end

local function restoreGuis()
    for _, gui in ipairs(preservedGuis) do
        if gui and gui.Parent then
            gui.ResetOnSpawn = true
        end
    end
    table.clear(preservedGuis)
end

-- [[ Update clone scale for size/width sliders ]]
local function updateCloneScale()
    if not ghostClone then return end
    for part, origSize in pairs(ghostOriginalSizes) do
        if part and part:IsA("BasePart") then
            part.Size = Vector3.new(origSize.X * cloneSize * cloneWidth, origSize.Y * cloneSize, origSize.Z * cloneSize)
        end
    end
    for motor, orig in pairs(ghostOriginalMotorCFrames) do
        if motor and motor:IsA("Motor6D") then
            local c0 = orig.C0
            local c1 = orig.C1
            local newC0 = CFrame.new(
                c0.Position.X * cloneSize * cloneWidth,
                c0.Position.Y * cloneSize,
                c0.Position.Z * cloneSize
            ) * CFrame.Angles(c0:ToEulerAnglesXYZ())
            local newC1 = CFrame.new(
                c1.Position.X * cloneSize * cloneWidth,
                c1.Position.Y * cloneSize,
                c1.Position.Z * cloneSize
            ) * CFrame.Angles(c1:ToEulerAnglesXYZ())
            motor.C0 = newC0
            motor.C1 = newC1
        end
    end

    local ghostHumanoid = ghostClone:FindFirstChildWhichIsA("Humanoid")
    if ghostHumanoid and ghostOriginalHipHeight then
        ghostHumanoid.HipHeight = ghostOriginalHipHeight * cloneSize
    end

    adjustCloneToGround(ghostClone)
end

-- [[ Copy ragdoll part positions from clone to original ]]
local function updateRagdolledParts()
    if not ghostEnabled or not originalCharacter or not ghostClone then return end
    for _, partName in ipairs(bodyParts) do
        local originalPart = originalCharacter:FindFirstChild(partName)
        local clonePart = ghostClone:FindFirstChild(partName)
        if originalPart and clonePart then
            originalPart.CFrame = clonePart.CFrame
            originalPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            originalPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end
end

-- [[ Main function to enable/disable ghost reanimation ]]
local function setGhostEnabled(newState)
    ghostEnabled = newState

    if ghostEnabled then
        local char = LocalPlayer.Character
        if not char then
            warn("No character found!")
            return
        end

        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root then
            warn("Character is missing either Humanoid or HumanoidRootPart!")
            return
        end

        originalCharacter = char
        originalCFrame = root.CFrame

        char.Archivable = true
        ghostClone = char:Clone()
        char.Archivable = false

        local originalName = originalCharacter.Name
        ghostClone.Name = originalName .. "_clone"

        local ghostHumanoid = ghostClone:FindFirstChildWhichIsA("Humanoid")
        if ghostHumanoid then
            ghostHumanoid.DisplayName = originalName .. "_clone"
            ghostOriginalHipHeight = ghostHumanoid.HipHeight
        end

        if not ghostClone.PrimaryPart then
            local hrp = ghostClone:FindFirstChild("HumanoidRootPart")
            if hrp then
                ghostClone.PrimaryPart = hrp
            end
        end

        -- [[ Make clone invisible ]]
        for _, part in ipairs(ghostClone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            end
        end
        local head = ghostClone:FindFirstChild("Head")
        if head then
            for _, child in ipairs(head:GetChildren()) do
                if child:IsA("Decal") then
                    child.Transparency = 1
                end
            end
        end

        -- [[ Store original sizes and motor CFrames for scaling ]]
        ghostOriginalSizes = {}
        ghostOriginalMotorCFrames = {}
        for _, desc in ipairs(ghostClone:GetDescendants()) do
            if desc:IsA("BasePart") then
                ghostOriginalSizes[desc] = desc.Size
            elseif desc:IsA("Motor6D") then
                ghostOriginalMotorCFrames[desc] = { C0 = desc.C0, C1 = desc.C1 }
            end
        end

        if cloneSize ~= 1 or cloneWidth ~= 1 then
            updateCloneScale()
        end

        local animate = originalCharacter:FindFirstChild("Animate")
        if animate then
            originalAnimateScript = animate
            originalAnimateScript.Disabled = true
            originalAnimateScript.Parent = ghostClone
        end

        preserveGuis()
        ghostClone.Parent = originalCharacter.Parent

        adjustCloneToGround(ghostClone)

        LocalPlayer.Character = ghostClone
        if ghostHumanoid then
            Workspace.CurrentCamera.CameraSubject = ghostHumanoid
        end
        restoreGuis()

        if originalAnimateScript then
            originalAnimateScript.Disabled = false
        end

        -- [[ Start ragdoll sync ]]
        task.delay(0, function()
            if not ghostEnabled then return end
            ReplicatedStorage.RagdollEvent:FireServer()
            task.delay(0, function()
                if not ghostEnabled then return end
                if updateConnection then updateConnection:Disconnect() end
                updateConnection = RunService.Heartbeat:Connect(updateRagdolledParts)
            end)
        end)

    else
        if updateConnection then
            updateConnection:Disconnect()
            updateConnection = nil
        end

        if not originalCharacter or not ghostClone then return end

        for i = 1, 3 do
            ReplicatedStorage.UnragdollEvent:FireServer()
            task.wait(0.1)
        end

        local origRoot = originalCharacter:FindFirstChild("HumanoidRootPart")
        local ghostRoot = ghostClone:FindFirstChild("HumanoidRootPart")
        local targetCFrame = ghostRoot and ghostRoot.CFrame or originalCFrame

        local animate = ghostClone:FindFirstChild("Animate")
        if animate then
            animate.Disabled = true
            animate.Parent = originalCharacter
        end

        ghostClone:Destroy()

        if origRoot then
            origRoot.CFrame = targetCFrame
            origRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            origRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end

        local origHumanoid = originalCharacter:FindFirstChildWhichIsA("Humanoid")
        preserveGuis()
        LocalPlayer.Character = originalCharacter
        if origHumanoid then
            Workspace.CurrentCamera.CameraSubject = origHumanoid
            origHumanoid.PlatformStand = false
            origHumanoid:ChangeState(Enum.HumanoidStateType.Running)
            origHumanoid.Sit = false
            origHumanoid.Jump = true
            task.wait(0.03)
            origHumanoid.Jump = false
            -- Reset all part velocities
            for _, part in ipairs(originalCharacter:GetChildren()) do
                if part:IsA("BasePart") then
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
        restoreGuis()

        if animate then
            task.wait(0.1)
            animate.Disabled = false
        end

        cloneSize = 1
        cloneWidth = 1
    end
end

-- [[ Animation playback logic (fake animation system) ]]
local fakeAnimStop
local fakeAnimRunning = false
fakeAnimStop = false
local fakeAnimSpeed = 1.1
local function stopFakeAnimation()
    fakeAnimStop = true
    fakeAnimRunning = false
    if not ghostClone then return end
    for i,script in pairs(ghostClone:GetChildren()) do
        if script:IsA("LocalScript") and script.Enabled == false then
            script.Enabled=true
        end
    end
    for motor, orig in pairs(ghostOriginalMotorCFrames) do
        if motor and motor:IsA("Motor6D") then
            motor.C0 = orig.C0
            motor.C1 = orig.C1
        end
    end

    for _, partName in ipairs(bodyParts) do
        local part = ghostClone:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end
end

-- [[ Play a fake animation on the ghost clone using keyframes ]]
local function playFakeAnimation(animationId)
    if not ghostClone then
        warn("No fake character available!")
        return
    end
    if animationId == "" then return end
    if fakeAnimRunning then
        stopFakeAnimation()
        task.wait(0.01)
        stopFakeAnimation()
    end
    wait(0.02)
    cloneSize = 1
    cloneWidth = 1
    updateCloneScale()

    for motor, orig in pairs(ghostOriginalMotorCFrames) do
        motor.C0 = orig.C0
    end

    local success, NeededAssets = pcall(function()
        return game:GetObjects("rbxassetid://" .. animationId)[1]
    end)
    if not success or not NeededAssets then
        warn("Invalid Animation ID.")
        return
    end

    local character = ghostClone
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local head = character:WaitForChild("Head")
    local leftFoot = character:WaitForChild("LeftFoot")
    local leftHand = character:WaitForChild("LeftHand")
    local leftLowerArm = character:WaitForChild("LeftLowerArm")
    local leftLowerLeg = character:WaitForChild("LeftLowerLeg")
    local leftUpperArm = character:WaitForChild("LeftUpperArm")
    local leftUpperLeg = character:WaitForChild("LeftUpperLeg")
    local lowerTorso = character:WaitForChild("LowerTorso")
    local rightFoot = character:WaitForChild("RightFoot")
    local rightHand = character:WaitForChild("RightHand")
    local rightLowerArm = character:WaitForChild("RightLowerArm")
    local rightLowerLeg = character:WaitForChild("RightLowerLeg")
    local rightUpperArm = character:WaitForChild("RightUpperArm")
    local rightUpperLeg = character:WaitForChild("RightUpperLeg")
    local upperTorso = character:WaitForChild("UpperTorso")

    local Joints = {
        ["Torso"] = rootPart:FindFirstChild("RootJoint"),
        ["Head"] = head:FindFirstChild("Neck"),
        ["LeftUpperArm"] = leftUpperArm:FindFirstChild("LeftShoulder"),
        ["RightUpperArm"] = rightUpperArm:FindFirstChild("RightShoulder"),
        ["LeftUpperLeg"] = leftUpperLeg:FindFirstChild("LeftHip"),
        ["RightUpperLeg"] = rightUpperLeg:FindFirstChild("RightHip"),
        ["LeftFoot"] = leftFoot:FindFirstChild("LeftAnkle"),
        ["RightFoot"] = rightFoot:FindFirstChild("RightAnkle"),
        ["LeftHand"] = leftHand:FindFirstChild("LeftWrist"),
        ["RightHand"] = rightHand:FindFirstChild("RightWrist"),
        ["LeftLowerArm"] = leftLowerArm:FindFirstChild("LeftElbow"),
        ["RightLowerArm"] = rightLowerArm:FindFirstChild("RightElbow"),
        ["LeftLowerLeg"] = leftLowerLeg:FindFirstChild("LeftKnee"),
        ["RightLowerLeg"] = rightLowerLeg:FindFirstChild("RightKnee"),
        ["LowerTorso"] = lowerTorso:FindFirstChild("Root"),
        ["UpperTorso"] = upperTorso:FindFirstChild("Waist"),
    }
    
    fakeAnimStop = false
    fakeAnimRunning = true
    
    -- [[ PlatformStand trick to prevent physics glitches ]]
    local part = Instance.new("Part")
    part.Size = Vector3.new(2048,0.1,2048)
    part.Anchored = true
    part.Position = game.Players.LocalPlayer.Character.LowerTorso.Position + Vector3.new(0,-0.527,0)
    part.Transparency = 1
    part.Parent = workspace
    game.Players.LocalPlayer.Character.Humanoid.PlatformStand = true
    task.wait(0.1)
    for i,script in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
        if script:IsA("LocalScript") and script.Enabled then
            script.Enabled=false
        end
    end
    game.Players.LocalPlayer.Character.Humanoid.PlatformStand = false
    part:Destroy()
    spawn(function()
        while fakeAnimRunning do
            if fakeAnimStop then
                fakeAnimRunning = false
                break
            end

            pcall(function()
                local keyframes = NeededAssets:GetKeyframes()
                for ii = 1, #keyframes do
                    if fakeAnimStop then break end

                    local currentFrame = keyframes[ii]
                    local nextFrame = keyframes[ii + 1] or keyframes[1]
                    local currentTime = currentFrame.Time
                    local nextTime = nextFrame.Time
                    if nextTime <= currentTime then
                        nextTime = nextTime + NeededAssets.Length
                    end

                    local frameLength = (nextTime - currentTime) / fakeAnimSpeed
                    local startTime = os.clock()
                    local endTime = startTime + frameLength

                    while os.clock() < endTime and not fakeAnimStop do
                        local now = os.clock()
                        local alpha = math.clamp((now - startTime) / frameLength, 0, 1)

                        pcall(function()
                            for _, currentPose in pairs(currentFrame:GetDescendants()) do
                                local nextPose = nextFrame:FindFirstChild(currentPose.Name, true)
                                local motor = Joints[currentPose.Name]

                                if motor and nextPose and ghostOriginalMotorCFrames[motor] then
                                    local currentCF = ghostOriginalMotorCFrames[motor].C0 * currentPose.CFrame
                                    local nextCF = ghostOriginalMotorCFrames[motor].C0 * nextPose.CFrame
                                    motor.C0 = currentCF:Lerp(nextCF, alpha)
                                end
                            end
                        end)
                        RunService.Heartbeat:Wait()
                    end
                end
            end)

            task.wait(0.03)
        end
    end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.R then
        stopFakeAnimation()
        task.wait(0.01)
        stopFakeAnimation()
        return
    end
end)

end

-- [[ Listen for character respawn and cleanup ghost if needed ]]
LocalPlayer = Players.LocalPlayer

LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            if ghostEnabled then
                setGhostEnabled(false)
                local toggleButton = gui:FindFirstChild("ToggleButton", true)
                if toggleButton then
                    toggleButton.Text = "Enable Reanimation"
                    toggleButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
                end
            end
        end)
    end
end)

-- [[ GUI Logic]]
local G2L = {};

G2L["1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling
G2L["1"].ResetOnSpawn = false

G2L["2"] = Instance.new("Frame", G2L["1"]);
G2L["2"]["BorderSizePixel"] = 0;
G2L["2"]["BackgroundColor3"] = Color3.fromRGB(23, 23, 25);
G2L["2"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["2"]["Size"] = UDim2.new(0, 318, 0, 470);
G2L["2"]["Position"] = UDim2.new(0, 667, 0, 447);
G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["2"]["Name"] = [[MainFrame]];

G2L["3"] = Instance.new("UICorner", G2L["2"]);
G2L["3"]["CornerRadius"] = UDim.new(0, 7);

G2L["4"] = Instance.new("Frame", G2L["2"]);
G2L["4"]["BorderSizePixel"] = 0;
G2L["4"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 35);
G2L["4"]["Size"] = UDim2.new(0, 316, 0, 51);
G2L["4"]["Position"] = UDim2.new(0, 1, 0, 0);
G2L["4"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4"]["Name"] = [[TopBar]];

G2L["5"] = Instance.new("UICorner", G2L["4"]);
G2L["5"]["CornerRadius"] = UDim.new(0, 7);

G2L["6"] = Instance.new("TextLabel", G2L["4"]);
G2L["6"]["BorderSizePixel"] = 0;
G2L["6"]["TextSize"] = 18;
G2L["6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["6"]["FontFace"] = Font.new([[rbxassetid://12187365977]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L["6"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L["6"]["BackgroundTransparency"] = 1;
G2L["6"]["Size"] = UDim2.new(0, 200, 0, 50);
G2L["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["6"]["Text"] = [[Sentinel Reanimation]];
G2L["6"]["Position"] = UDim2.new(0.01852, 0, 0.03846, 0);

local closeButton = Instance.new("ImageButton", G2L["4"])
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -16, 0.72, -12)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.BackgroundTransparency = 1
closeButton.Image = "rbxassetid://10152135063"

closeButton.MouseEnter:Connect(function()
    closeButton.Image = "rbxassetid://104301854198764"
end)

closeButton.MouseLeave:Connect(function()
    closeButton.Image = "rbxassetid://10152135063"
end)

closeButton.MouseEnter:Connect(function()
    local hoverTween = TweenService:Create(closeButton, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 0, 0)})
    hoverTween:Play()
end)

closeButton.MouseLeave:Connect(function()
    local leaveTween = TweenService:Create(closeButton, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 255, 255)})
    leaveTween:Play()
end)

closeButton.MouseButton1Click:Connect(function()
    if ghostEnabled then
        setGhostEnabled(false)
        G2L["1b"].Text = "Enable R15 Reanimation"
        G2L["1b"].TextColor3 = Color3.fromRGB(207, 207, 207)
    end
    G2L["1"]:Destroy()
end)

local minimizeButton = Instance.new("ImageButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 24, 0, 34)
minimizeButton.Position = UDim2.new(1, -48, 0.72, -12)
minimizeButton.AnchorPoint = Vector2.new(1, 0.5)
minimizeButton.BackgroundTransparency = 1
minimizeButton.Image = "rbxassetid://15396333997"
minimizeButton.Parent = G2L["4"]

minimizeButton.MouseEnter:Connect(function()
    minimizeButton.Image = "rbxassetid://15396333997"
    TweenService:Create(minimizeButton, TweenInfo.new(0.2), {
        ImageColor3 = Color3.fromRGB(57, 190, 249)
    }):Play()
end)

minimizeButton.MouseLeave:Connect(function()
    minimizeButton.Image = "rbxassetid://15396333997"
    TweenService:Create(minimizeButton, TweenInfo.new(0.2), {
        ImageColor3 = Color3.fromRGB(255, 255, 255)
    }):Play()
end)

local isMinimized = false
local originalSize = G2L["2"].Size
local topBar = G2L["4"]

local function toggleMinimize()
    isMinimized = not isMinimized

    for _, child in ipairs(G2L["2"]:GetChildren()) do
        if child ~= topBar and child:IsA("GuiObject") then
            child.Visible = not isMinimized
        end
    end

    local targetSize = isMinimized
        and UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 51)
        or originalSize

    TweenService:Create(G2L["2"], TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = targetSize
    }):Play()
end

minimizeButton.MouseButton1Click:Connect(toggleMinimize)

closeButton.MouseButton1Click:Connect(function()
    if ghostEnabled then
        setGhostEnabled(false)
    end
    G2L["1"]:Destroy()
end)

G2L["7"] = Instance.new("Frame", G2L["2"]);
G2L["7"]["BorderSizePixel"] = 0;
G2L["7"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 35);
G2L["7"]["Size"] = UDim2.new(0, 294, 0, 36);
G2L["7"]["Position"] = UDim2.new(0, 12, 0, 66);
G2L["7"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["7"]["Name"] = [[Search]];

G2L["8"] = Instance.new("UICorner", G2L["7"]);
G2L["8"]["CornerRadius"] = UDim.new(0, 4);

G2L["9"] = Instance.new("UIStroke", G2L["7"]);
G2L["9"]["Transparency"] = 0.23;
G2L["9"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["9"]["Thickness"] = 0.7;
G2L["9"]["Color"] = Color3.fromRGB(58, 58, 58);

G2L["a"] = Instance.new("TextBox", G2L["7"]);
G2L["a"]["CursorPosition"] = -1;
G2L["a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["a"]["BorderSizePixel"] = 0;
G2L["a"]["TextSize"] = 15;
G2L["a"]["TextColor3"] = Color3.fromRGB(136, 136, 136);
G2L["a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["a"]["FontFace"] = Font.new([[rbxassetid://12187365977]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
G2L["a"]["Size"] = UDim2.new(0, 183, 0, 29);
G2L["a"]["Position"] = UDim2.new(0.14286, 0, 0.08333, 0);
G2L["a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["a"].PlaceholderText = "Search animations..."
G2L["a"].PlaceholderColor3 = Color3.fromRGB(136, 136, 136)
G2L["a"]["Text"] = [[Search animations...]];
G2L["a"]["BackgroundTransparency"] = 1;

G2L["b"] = Instance.new("ImageLabel", G2L["7"]);
G2L["b"]["BorderSizePixel"] = 0;
G2L["b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["b"]["Image"] = [[http://www.roblox.com/asset/?id=5107220207]];
G2L["b"]["Size"] = UDim2.new(0, 15, 0, 15);
G2L["b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["b"]["BackgroundTransparency"] = 1;
G2L["b"]["Position"] = UDim2.new(0.04422, 0, 0.27778, 0);

G2L["c"] = Instance.new("TextButton", G2L["7"]);
G2L["c"]["BorderSizePixel"] = 0;
G2L["c"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L["c"]["TextSize"] = 17;
G2L["c"]["BackgroundColor3"] = Color3.fromRGB(57, 190, 249);
G2L["c"]["FontFace"] = Font.new([[rbxassetid://12187365977]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
G2L["c"]["Size"] = UDim2.new(0, 62, 0, 36);
G2L["c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["c"]["Text"] = [[Add]];
G2L["c"]["Position"] = UDim2.new(0.78912, 0, 0, 0);

G2L["d"] = Instance.new("UICorner", G2L["c"]);
G2L["d"]["CornerRadius"] = UDim.new(0, 4);

G2L["e"] = Instance.new("Frame", G2L["2"]);
G2L["e"]["BorderSizePixel"] = 0;
G2L["e"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 35);
G2L["e"]["Size"] = UDim2.new(0, 294, 0, 288);
G2L["e"]["Position"] = UDim2.new(0, 12, 0, 118);
G2L["e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["e"]["Name"] = [[Buttons]];

G2L["f"] = Instance.new("UICorner", G2L["e"]);
G2L["f"]["CornerRadius"] = UDim.new(0, 4);

G2L["10"] = Instance.new("UIStroke", G2L["e"]);
G2L["10"]["Transparency"] = 0.23;
G2L["10"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["10"]["Thickness"] = 0.7;
G2L["10"]["Color"] = Color3.fromRGB(58, 58, 58);

G2L["speed_frame"] = Instance.new("Frame", G2L["2"])
G2L["speed_frame"]["BorderSizePixel"] = 0
G2L["speed_frame"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 35)
G2L["speed_frame"]["Size"] = UDim2.new(0, 294, 0, 40)
G2L["speed_frame"]["Position"] = UDim2.new(0, 12, 0, 375)
G2L["speed_frame"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["speed_frame"]["Name"] = "SpeedSlider"

G2L["speed_stroke"] = Instance.new("UIStroke", G2L["speed_frame"])
G2L["speed_stroke"]["Transparency"] = 0.23
G2L["speed_stroke"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
G2L["speed_stroke"]["Thickness"] = 0.7
G2L["speed_stroke"]["Color"] = Color3.fromRGB(58, 58, 58)

G2L["speed_corner"] = Instance.new("UICorner", G2L["speed_frame"])
G2L["speed_corner"]["CornerRadius"] = UDim.new(0, 4)

G2L["speed_label"] = Instance.new("TextLabel", G2L["speed_frame"])
G2L["speed_label"]["BorderSizePixel"] = 0
G2L["speed_label"]["TextSize"] = 14
G2L["speed_label"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["speed_label"]["FontFace"] = Font.new([[rbxassetid://12187365977]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
G2L["speed_label"]["TextColor3"] = Color3.fromRGB(207, 207, 207)
G2L["speed_label"]["BackgroundTransparency"] = 1
G2L["speed_label"]["Size"] = UDim2.new(0, 100, 0, 28)
G2L["speed_label"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["speed_label"]["Text"] = "Animation Speed:"
G2L["speed_label"]["Position"] = UDim2.new(0.07, 0, -0.05, 0)

G2L["speed_value"] = Instance.new("TextLabel", G2L["speed_frame"])
G2L["speed_value"]["BorderSizePixel"] = 0
G2L["speed_value"]["TextSize"] = 14
G2L["speed_value"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["speed_value"]["FontFace"] = Font.new([[rbxassetid://12187365977]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
G2L["speed_value"]["TextColor3"] = Color3.fromRGB(57, 190, 249)
G2L["speed_value"]["BackgroundTransparency"] = 1
G2L["speed_value"]["Size"] = UDim2.new(0, 50, 0, 28)
G2L["speed_value"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["speed_value"]["Text"] = "1.1x"
G2L["speed_value"]["Position"] = UDim2.new(0.8, 0, 0.15, 0)

G2L["speed_slider"] = Instance.new("Frame", G2L["speed_frame"])
G2L["speed_slider"]["BorderSizePixel"] = 0
G2L["speed_slider"]["BackgroundColor3"] = Color3.fromRGB(50, 50, 50)
G2L["speed_slider"]["Size"] = UDim2.new(0, 180, 0, 5)
G2L["speed_slider"]["Position"] = UDim2.new(0.05, 0, 0.7, 0)
G2L["speed_slider"]["Name"] = "SliderTrack"

G2L["speed_slider_corner"] = Instance.new("UICorner", G2L["speed_slider"])
G2L["speed_slider_corner"]["CornerRadius"] = UDim.new(1, 0)

G2L["speed_slider_fill"] = Instance.new("Frame", G2L["speed_slider"])
G2L["speed_slider_fill"]["BorderSizePixel"] = 0
G2L["speed_slider_fill"]["BackgroundColor3"] = Color3.fromRGB(57, 190, 249)
G2L["speed_slider_fill"]["Size"] = UDim2.new(0.5, 0, 1, 0)
G2L["speed_slider_fill"]["Name"] = "SliderFill"

G2L["speed_slider_fill_corner"] = Instance.new("UICorner", G2L["speed_slider_fill"])
G2L["speed_slider_fill_corner"]["CornerRadius"] = UDim.new(1, 0)

G2L["speed_slider_thumb"] = Instance.new("Frame", G2L["speed_slider"])
G2L["speed_slider_thumb"]["BorderSizePixel"] = 0
G2L["speed_slider_thumb"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["speed_slider_thumb"]["Size"] = UDim2.new(0, 15, 0, 15)
G2L["speed_slider_thumb"]["Position"] = UDim2.new(0.5, -7, 0, -5)
G2L["speed_slider_thumb"]["Name"] = "SliderThumb"

G2L["speed_slider_thumb_corner"] = Instance.new("UICorner", G2L["speed_slider_thumb"])
G2L["speed_slider_thumb_corner"]["CornerRadius"] = UDim.new(1, 0)

local slider = G2L["speed_slider"]
local fill = G2L["speed_slider_fill"]
local thumb = G2L["speed_slider_thumb"]
local valueLabel = G2L["speed_value"]

local minValue = 0.1
local maxValue = 3.0
local currentValue = 1.1

local function updateSlider(value)
    local normalized = (value - minValue) / (maxValue - minValue)
    TweenService:Create(fill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(normalized, 0, 1, 0)}):Play()
    TweenService:Create(thumb, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(normalized, -7, 0, -5)}):Play()
    valueLabel.Text = string.format("%.1fx", value)
    fakeAnimSpeed = value
end

local function setValueFromXPosition(x)
    local relativeX = math.clamp(x - slider.AbsolutePosition.X, 0, slider.AbsoluteSize.X)
    local normalized = relativeX / slider.AbsoluteSize.X
    currentValue = minValue + (maxValue - minValue) * normalized
    updateSlider(currentValue)
end

local uis = game:GetService("UserInputService")
local isDraggingSlider = false

local function onInputChanged(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and isDraggingSlider then
        setValueFromXPosition(input.Position.X)
    end
end

thumb.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingSlider = true
    end
end)

slider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingSlider = true
        setValueFromXPosition(input.Position.X)
    end
end)

thumb.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingSlider = false
    end
end)
slider.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingSlider = false
    end
end)

thumb.InputChanged:Connect(onInputChanged)
uis.InputChanged:Connect(onInputChanged)

updateSlider(currentValue)

G2L["18"] = Instance.new("Frame", G2L["2"]);
G2L["18"]["BorderSizePixel"] = 0;
G2L["18"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 35);
G2L["18"]["Size"] = UDim2.new(0, 294, 0, 36);
G2L["18"]["Position"] = UDim2.new(0, 12, 0, 425);
G2L["18"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["18"]["Name"] = [[Enable]];

G2L["19"] = Instance.new("UIStroke", G2L["18"]);
G2L["19"]["Transparency"] = 0.23;
G2L["19"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
G2L["19"]["Thickness"] = 0.7;
G2L["19"]["Color"] = Color3.fromRGB(58, 58, 58);

G2L["1a"] = Instance.new("UICorner", G2L["18"]);
G2L["1a"]["CornerRadius"] = UDim.new(0, 4);

G2L["1b"] = Instance.new("TextLabel", G2L["18"]);
G2L["1b"]["BorderSizePixel"] = 0;
G2L["1b"]["TextSize"] = 14;
G2L["1b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["1b"]["FontFace"] = Font.new([[rbxassetid://12187365977]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L["1b"]["TextColor3"] = Color3.fromRGB(207, 207, 207);
G2L["1b"]["BackgroundTransparency"] = 1;
G2L["1b"]["Size"] = UDim2.new(0, 200, 0, 28);
G2L["1b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["1b"]["Text"] = [[Enable R15 Reanimation]];
G2L["1b"]["Position"] = UDim2.new(0.15986, 0, 0.11111, 0);

G2L["1c"] = Instance.new("TextButton", G2L["18"]);
G2L["1c"]["BackgroundTransparency"] = 1;
G2L["1c"]["Size"] = UDim2.new(1, 0, 1, 0);
G2L["1c"]["Text"] = "";
G2L["1c"]["Name"] = [[EnableButton]];

local hoverColor = Color3.fromRGB(57, 190, 249)
local normalColor = Color3.fromRGB(207, 207, 207)
local maroonColor = Color3.fromRGB(171, 27, 27)

local tweenInfo = TweenInfo.new(
    0.25,
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out
)

local function tweenTextColor(label, targetColor)
    TweenService:Create(label, tweenInfo, {TextColor3 = targetColor}):Play()
end

G2L["1c"].MouseEnter:Connect(function()
    tweenTextColor(G2L["1b"], hoverColor)
end)

G2L["1c"].MouseLeave:Connect(function()
    local textLabel = G2L["1b"]
    if textLabel.Text:lower() == "disable r15 reanimation" then
        tweenTextColor(textLabel, maroonColor)
    else
        tweenTextColor(textLabel, normalColor)
    end
end)

G2L["1c"].MouseEnter:Connect(function()
    local textLabel = G2L["1b"]
    if textLabel.Text:lower() == "enable r15 reanimation" then
        tweenTextColor(textLabel, hoverColor)
    else
        tweenTextColor(textLabel, hoverColor)
    end
end)

if G2L["1b"].Text:lower() == "disable r15 reanimation" then
    G2L["1b"].TextColor3 = Color3.fromRGB(171, 27, 27)
end

if G2L["1b"].Text:lower() == "enable r15 reanimation" then
    G2L["1b"].TextColor3 = Color3.fromRGB(207, 207, 207)
end

G2L["1c"].MouseButton1Click:Connect(function()
    if ghostEnabled then
        setGhostEnabled(false)
        G2L["1b"].Text = "Enable R15 Reanimation"
        G2L["1b"].TextColor3 = Color3.fromRGB(207, 207, 207)
    else
        setGhostEnabled(true)
        G2L["1b"].Text = "Disable R15 Reanimation"
        G2L["1b"].TextColor3 = Color3.fromRGB(171, 27, 27)
    end
end)

local loadedAnimations = {}
local currentPlayingAnimation = nil

local function toggleFakeAnimation(animationId)
    if not ghostEnabled then
        warn("Reanimation is not enabled!")
        return
    end

    if currentPlayingAnimation == animationId then
        stopFakeAnimation()
        task.wait(0.01)
        stopFakeAnimation()
        currentPlayingAnimation = nil
        return
    end

    if currentPlayingAnimation then
        stopFakeAnimation()
        task.wait(0.01)
        stopFakeAnimation()
    end

    if not loadedAnimations[animationId] then
        local success, animation = pcall(function()
            return game:GetObjects("rbxassetid://" .. animationId)[1]
        end)
        if success and animation then
            loadedAnimations[animationId] = animation
        else
            warn("Failed to load animation with ID: " .. animationId)
            return
        end
    end

    currentPlayingAnimation = animationId
    playFakeAnimation(animationId)
end

local showR6Label = true

local HttpService = game:GetService("HttpService")
local ANIMATIONS_FILE = "customAnims.json"
loadedAnimations.custom = loadedAnimations.custom or {}

local function saveAnimationsToFile()
    if not isfolder("sentinel_animations") then
        makefolder("sentinel_animations")
    end

    local success, json = pcall(function()
        return HttpService:JSONEncode(loadedAnimations.custom)
    end)

    if success then
        writefile("sentinel_animations/"..ANIMATIONS_FILE, json)
    else
        warn("Failed to encode animations:", json)
    end
end

local function loadAnimationsFromFile()
    if not isfolder("sentinel_animations") then return end
    if not isfile("sentinel_animations/"..ANIMATIONS_FILE) then return end

    local success, content = pcall(function()
        return readfile("sentinel_animations/"..ANIMATIONS_FILE)
    end)

    if not success then return end

    local success2, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if success2 and data then
        loadedAnimations.custom = data
    end
end

local function addNewAnimation(animName, animId)
    local success, animation = pcall(function()
        return game:GetObjects("rbxassetid://" .. animId)[1]
    end)

    if not success or not animation then
        warn("Invalid Animation ID.")
        return false
    end

    table.insert(loadedAnimations.custom, {
        Name = animName,
        ID = animId,
        IsR6 = false
    })

    saveAnimationsToFile()
    return true
end

local function createAddEmoteGUI(parentGUI, refreshCallback)
    local addEmoteGUI = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"))
    addEmoteGUI.Name = "AddEmoteGUI"
    addEmoteGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    addEmoteGUI.ResetOnSpawn = false

    local addEmoteFrame = Instance.new("Frame", addEmoteGUI)
    addEmoteFrame.Name = "AddEmote"
    addEmoteFrame.BorderSizePixel = 0
    addEmoteFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
    addEmoteFrame.Size = UDim2.new(0, 235, 0, 138)
    addEmoteFrame.Position = UDim2.new(0.5, -117.5, 0.5, -69)
    addEmoteFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    addEmoteFrame.Visible = false

    local UserInputService = game:GetService("UserInputService")
    local runService = game:GetService("RunService")

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function Lerp(a, b, m)
        return a + (b - a) * m
    end

    local lastMousePos
    local lastGoalPos
    local DRAG_SPEED = 15

    local function Update(dt)
        if not startPos then return end
        if not dragging and lastGoalPos then
            addEmoteFrame.Position = UDim2.new(
                startPos.X.Scale, Lerp(addEmoteFrame.Position.X.Offset, lastGoalPos.X.Offset, dt * DRAG_SPEED),
                startPos.Y.Scale, Lerp(addEmoteFrame.Position.Y.Offset, lastGoalPos.Y.Offset, dt * DRAG_SPEED)
            )
            return
        end

        local delta = lastMousePos - UserInputService:GetMouseLocation()
        local xGoal = startPos.X.Offset - delta.X
        local yGoal = startPos.Y.Offset - delta.Y
        lastGoalPos = UDim2.new(startPos.X.Scale, xGoal, startPos.Y.Scale, yGoal)
        addEmoteFrame.Position = UDim2.new(
            startPos.X.Scale, Lerp(addEmoteFrame.Position.X.Offset, xGoal, dt * DRAG_SPEED),
            startPos.Y.Scale, Lerp(addEmoteFrame.Position.Y.Offset, yGoal, dt * DRAG_SPEED)
        )
    end

    addEmoteFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = addEmoteFrame.Position
            lastMousePos = UserInputService:GetMouseLocation()

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    addEmoteFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    runService.Heartbeat:Connect(Update)

    local emoteCorner = Instance.new("UICorner", addEmoteFrame)
    emoteCorner.CornerRadius = UDim.new(0, 4)

    local emoteStroke = Instance.new("UIStroke", addEmoteFrame)
    emoteStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    emoteStroke.Thickness = 0.7
    emoteStroke.Color = Color3.fromRGB(59, 59, 59)

    local animNameBox = Instance.new("TextBox", addEmoteFrame)
    animNameBox.Name = "AnimName"
    animNameBox.CursorPosition = -1
    animNameBox.PlaceholderColor3 = Color3.fromRGB(119, 119, 119)
    animNameBox.BorderSizePixel = 0
    animNameBox.TextSize = 14
    animNameBox.TextColor3 = Color3.fromRGB(179, 179, 179)
    animNameBox.BackgroundColor3 = Color3.fromRGB(35, 35, 39)
    animNameBox.FontFace = Font.new("rbxassetid://12187365977", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    animNameBox.PlaceholderText = "Animation Name"
    animNameBox.Size = UDim2.new(0, 211, 0, 30)
    animNameBox.Position = UDim2.new(0.05106, 0, 0.08642, 0)
    animNameBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
    animNameBox.Text = ""

    local nameBoxCorner = Instance.new("UICorner", animNameBox)
    nameBoxCorner.CornerRadius = UDim.new(0, 2)

    local nameBoxStroke = Instance.new("UIStroke", animNameBox)
    nameBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    nameBoxStroke.Thickness = 0.7
    nameBoxStroke.Color = Color3.fromRGB(59, 59, 59)

    local animIdBox = Instance.new("TextBox", addEmoteFrame)
    animIdBox.Name = "AnimID"
    animIdBox.CursorPosition = -1
    animIdBox.PlaceholderColor3 = Color3.fromRGB(119, 119, 119)
    animIdBox.BorderSizePixel = 0
    animIdBox.TextSize = 14
    animIdBox.TextColor3 = Color3.fromRGB(179, 179, 179)
    animIdBox.BackgroundColor3 = Color3.fromRGB(35, 35, 39)
    animIdBox.FontFace = Font.new("rbxassetid://12187365977", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    animIdBox.PlaceholderText = "Animation ID"
    animIdBox.Size = UDim2.new(0, 211, 0, 30)
    animIdBox.Position = UDim2.new(0.05106, 0, 0.38808, 0)
    animIdBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
    animIdBox.Text = ""

    local idBoxCorner = Instance.new("UICorner", animIdBox)
    idBoxCorner.CornerRadius = UDim.new(0, 2)

    local idBoxStroke = Instance.new("UIStroke", animIdBox)
    idBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    idBoxStroke.Thickness = 0.7
    idBoxStroke.Color = Color3.fromRGB(59, 59, 59)

    local confirmButton = Instance.new("TextButton", addEmoteFrame)
    confirmButton.Name = "Confirm"
    confirmButton.BorderSizePixel = 0
    confirmButton.TextColor3 = Color3.fromRGB(187, 187, 187)
    confirmButton.TextSize = 15
    confirmButton.BackgroundColor3 = Color3.fromRGB(43, 43, 48)
    confirmButton.FontFace = Font.new("rbxassetid://12187365977", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    confirmButton.Size = UDim2.new(0, 210, 0, 29)
    confirmButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
    confirmButton.Text = "Confirm"
    confirmButton.Position = UDim2.new(0.05106, 0, 0.7029, 0)

    local confirmCorner = Instance.new("UICorner", confirmButton)
    confirmCorner.CornerRadius = UDim.new(0, 4)

    local confirmStroke = Instance.new("UIStroke", confirmButton)
    confirmStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    confirmStroke.Thickness = 0.7
    confirmStroke.Color = Color3.fromRGB(59, 59, 59)

    confirmButton.MouseButton1Click:Connect(function()
        local animName = animNameBox.Text
        local animId = animIdBox.Text

        if animName == "" or animId == "" then
            warn("Please enter both animation name and ID")
            return
        end

        if addNewAnimation(animName, animId) then
            animNameBox.Text = ""
            animIdBox.Text = ""
            addEmoteFrame.Visible = false
            if refreshCallback then
                refreshCallback()
            end
        else
            warn("Failed to add animation - invalid ID")
        end
    end)

    local function toggleAddEmoteGUI()
        addEmoteFrame.Visible = not addEmoteFrame.Visible
        if addEmoteFrame.Visible then
            animNameBox.Text = ""
            animIdBox.Text = ""
        end
    end

    return {
        GUI = addEmoteGUI,
        toggle = toggleAddEmoteGUI
    }
end

loadAnimationsFromFile()

local emoteKeybinds = {}

local function addButtonsToFrame()
    local parent = G2L["e"]
    parent:ClearAllChildren()
    local scrollingFrame = Instance.new("ScrollingFrame", parent)
    scrollingFrame.Name = "EmoteScrollingFrame"
    scrollingFrame.Size = UDim2.new(1, 0, 0.87, 0)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 2010)
    scrollingFrame.ScrollBarThickness = 5
    scrollingFrame.BackgroundTransparency = 1

    local yOffset = 10

    local emotes = {
        {"Back On 74", "108088087568172", false},
        {"Boogie Bomb", "90159280044964", false},
        {"Billy Bounce", "96342044032488", false},
        {"Boogie Down", "83261869707370", false},
        {"Cupid's Arrow", "122288826913668", false},
        {"California Gurls", "131457845572132", false},
        {"Chase Me Down", "97455319886162", false},
        {"Default Dance", "9836885605", false},
        {"Dancery", "135978042300523", false},
        {"Desirable", "80125132098992", false},
        {"Disco Fever", "9836369561", false},
        {"Evil Plan", "99449894581351", false},
        {"Electro Shuffle", "9116910876", false},
        {"Electro Swing", "7839963379", false},
        {"FreeStylin", "107995227083576", false},
        {"Fresh", "9116897929", false},
        {"Groove Destroyer", "18147813725", false},
        {"Griddy", "135342670717393", false},
        {"Hot Marat", "7107202783", false},
        {"Hakari Dance", "73789839912852", true},
        {"Hey Now", "7124753337", false},
        {"Hype", "121532134633896", false},
        {"Head Banger", "114573617035275", false},
        {"Infinite Dab", "74538409545244"},
        {"Jabba Switchway", "8229514367", false},
        {"Jubi Slide", "16570530493", false},
        {"Lucid Dream", "108895351743195", false},
        {"Look At Me", "129004554500202", false},
        {"Mr Blue Sky", "8603017969", false},
        {"Maximum Bounce", "8703876822", false},
        {"Miku Live", "102039871027058", false},
        {"Miku Miku Beam", "116802170205791", false},
        {"No Cure", "76827103391437", false},
        {"Orange Justice", "11212163754", false},
        {"Phonky Turn", "122815417402057", false},
        {"Pull Up", "8871805743", false},
        {"Poki", "83405509049719", false},
        {"Party Hips", "91664350716653", false},
        {"Reanimated", "7757686890", false},
        {"Scenario", "8924083749", false},
        {"Snoop's Walk", "95567389800091", false},
        {"Slalom Style", "123624215915471", false},
        {"Toosie Slide", "8230248004", false},
        {"Take The L", "114109549820426"},
        {"The Floss", "9003921069", false},
        {"Verve", "119993822512014", false},
        {"The Viper", "109195495448084", false},
        {"What You Want", "112811217802231", false},
        {"Unlock It", "104997186005133", true},
        {"Goofy Twerk", "71819565973448", false},
        {"Sicko Mode", "100379545014024", true},
        {"Stock Shuffle", "95645590336118", true},
        {"Billy Bounce R6", "104963686949319", true},
        {"Embarrassing", "110978487197470", true},
        {"Arona", "134041849348680", true},
        {"Goofy Ahh Hump", "116682294641877", false},
        {"Omni Man Pose", "83598910354775", false},
        {"Self Head", "93659508999288", false},
        {"Get Butt Fucked", "97970042209398", false},
        {"2 Armed Stroke", "98873055560654", false},
        {"Hakari 2", "70986254530914", true},
        {"Cum Shot", "139791836037885", false},
        {"Monster Mash", "133556505496748", true},
        {"Slay Jump", "127922356397397", true},
        {"Jerk Off", "139882809426807", false},
        {"Twerk", "77493234914180", false},
        {"Back Shot", "104625684132073", false},
        {"Lap Dance", "93816795776514", false},
        {"Runaway", "124138007910724", false},
        {"Runaway Twerk", "83523061911331", false},
        {"Give Head (Goofy Edition)", "118753756727960", false},
        {"Twerk On The Floor", "97412783228774", false},
        {"Scissoring", "135771690782346", false},
        {"Assumptions", "98653233606495", true},
        {"Assumptions R15", "100885689396978", false},
        {"Big Swastika", "94631359696320", false},
        {"Distraction Dance", "100885689396978", false},
        {"Peanut Butter JT", "71347001855728", true},
        {"Fat Shit", "118865365595523", false}
    }

    for _, custom in ipairs(loadedAnimations.custom or {}) do
        table.insert(emotes, {custom.Name, custom.ID, custom.IsR6})
    end

    table.sort(emotes, function(a, b)
        return a[1]:lower() < b[1]:lower()
    end)

    local buttons = {}

    for _, emote in ipairs(emotes) do
        local emoteName = emote[1]
        local emoteId = emote[2]
        local isR6 = emote[3]

        local keyBox = Instance.new("TextBox", scrollingFrame)
        keyBox.Name = "KeybindBox"
        keyBox.Size = UDim2.new(0, 32, 0, 32)
        keyBox.Position = UDim2.new(0, 8, 0, yOffset)
        keyBox.BackgroundColor3 = Color3.fromRGB(35, 35, 39)
        keyBox.Text = ""
        keyBox.TextSize = 14
        keyBox.Font = Enum.Font.GothamSemibold
        keyBox.TextColor3 = Color3.fromRGB(179, 179, 179)
        keyBox.BorderSizePixel = 0
        keyBox.ClearTextOnFocus = false
        keyBox.PlaceholderText = "..."
        keyBox.TextXAlignment = Enum.TextXAlignment.Center

        local keyCorner = Instance.new("UICorner", keyBox)
        keyCorner.CornerRadius = UDim.new(0, 4)

        local keyStroke = Instance.new("UIStroke", keyBox)
        keyStroke.Transparency = 0.23
        keyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        keyStroke.Thickness = 0.7
        keyStroke.Color = Color3.fromRGB(58, 58, 58)

        keyBox.Focused:Connect(function()
            keyBox.Text = ""
            if keyInputConn then
                keyInputConn:Disconnect()
                keyInputConn = nil
            end
            keyInputConn = game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    emoteKeybinds[emoteId] = input.KeyCode
                    keyBox.Text = input.KeyCode.Name
                    if keyInputConn then
                        keyInputConn:Disconnect()
                        keyInputConn = nil
                    end
                    keyBox:ReleaseFocus()
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    emoteKeybinds[emoteId] = nil
                    keyBox.Text = ""
                    if keyInputConn then
                        keyInputConn:Disconnect()
                        keyInputConn = nil
                    end
                    keyBox:ReleaseFocus()
                end
            end)
        end)

        keyBox.FocusLost:Connect(function()
            if keyInputConn then
                keyInputConn:Disconnect()
                keyInputConn = nil
            end
            if emoteKeybinds[emoteId] then
                keyBox.Text = emoteKeybinds[emoteId].Name
            else
                keyBox.Text = ""
            end
        end)

        keyBox:GetPropertyChangedSignal("Text"):Connect(function()
            local text = keyBox.Text
            if #text == 1 then
                local upper = text:upper()
                local foundKey = nil
                for _, key in pairs(Enum.KeyCode:GetEnumItems()) do
                    if key.Name == upper then
                        foundKey = key
                        break
                    end
                end
                if foundKey then
                    emoteKeybinds[emoteId] = foundKey
                    keyBox.Text = foundKey.Name
                    keyBox:ReleaseFocus()
                end
            end
        end)

        local button = Instance.new("TextButton", scrollingFrame)
        button.Name = emoteName
        button.Size = UDim2.new(1, -68, 0, 32)
        button.Position = UDim2.new(0, 48, 0, yOffset)
        button.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
        button.Text = emoteName
        button.TextSize = 17
        button.Font = Enum.Font.GothamSemibold
        button.TextColor3 = Color3.fromRGB(244, 244, 244)
        button.BorderSizePixel = 0
        button.AutoButtonColor = false

        local buttonStroke = Instance.new("UIStroke", button)
        buttonStroke.Transparency = 0.23
        buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        buttonStroke.Thickness = 0.7
        buttonStroke.Color = Color3.fromRGB(58, 58, 58)

        local buttonCorner = Instance.new("UICorner", button)
        buttonCorner.CornerRadius = UDim.new(0, 4)

        if showR6Label and isR6 then
            local r6Label = Instance.new("TextLabel", button)
            r6Label.Size = UDim2.new(0, 28, 0, 16)
            r6Label.Position = UDim2.new(1, -36, 0.5, -8)
            r6Label.BackgroundColor3 = Color3.fromRGB(57, 190, 249)
            r6Label.Text = "R6"
            r6Label.TextSize = 12
            r6Label.Font = Enum.Font.GothamBold
            r6Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            r6Label.BorderSizePixel = 0
            r6Label.BackgroundTransparency = 0
            r6Label.TextStrokeTransparency = 1
            r6Label.TextXAlignment = Enum.TextXAlignment.Center
            r6Label.TextYAlignment = Enum.TextYAlignment.Center

            local labelCorner = Instance.new("UICorner", r6Label)
            labelCorner.CornerRadius = UDim.new(1, 0)
        end

        button.MouseEnter:Connect(function()
            local hoverTween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(31, 31, 35)})
            hoverTween:Play()
        end)

        button.MouseLeave:Connect(function()
            local leaveTween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(31, 31, 35)})
            leaveTween:Play()
        end)

        button.MouseButton1Click:Connect(function()
            button.TextColor3 = Color3.fromRGB(244, 244, 244)

            local clickTween = TweenService:Create(button, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(57, 190, 249)})
            clickTween:Play()
            clickTween.Completed:Connect(function()
                local resetTween = TweenService:Create(button, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(244, 244, 244)})
                resetTween:Play()
            end)

            if emoteName == "Runaway" then
                currentValue = 0.1
                updateSlider(currentValue)
            else
                currentValue = 1.1
                updateSlider(currentValue)
            end

            toggleFakeAnimation(emoteId)
        end)

        keyBox.Focused:Connect(function()
            keyBox.Text = ""
            if keyInputConn then
                keyInputConn:Disconnect()
                keyInputConn = nil
            end
            keyInputConn = game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    emoteKeybinds[emoteId] = input.KeyCode
                    keyBox.Text = input.KeyCode.Name
                    if keyInputConn then
                        keyInputConn:Disconnect()
                        keyInputConn = nil
                    end
                    keyBox:ReleaseFocus()
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    emoteKeybinds[emoteId] = nil
                    keyBox.Text = ""
                    if keyInputConn then
                        keyInputConn:Disconnect()
                        keyInputConn = nil
                    end
                    keyBox:ReleaseFocus()
                end
            end)
        end)

        keyBox.FocusLost:Connect(function()
            if keyInputConn then
                keyInputConn:Disconnect()
                keyInputConn = nil
            end
            if emoteKeybinds[emoteId] then
                keyBox.Text = emoteKeybinds[emoteId].Name
            else
                keyBox.Text = ""
            end
        end)

        if emoteKeybinds[emoteId] then
            keyBox.Text = emoteKeybinds[emoteId].Name
        else
            keyBox.Text = ""
        end

        table.insert(buttons, {button = button, keyBox = keyBox})
        yOffset = yOffset + 40
    end

    game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            for emoteId, keyCode in pairs(emoteKeybinds) do
                if input.KeyCode == keyCode then
                    toggleFakeAnimation(emoteId)
                end
            end
        end
    end)

    local searchBox = G2L["a"]
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = searchBox.Text:lower()
        yOffset = 10

        for _, pair in ipairs(buttons) do
            local button = pair.button
            local keyBox = pair.keyBox
            if button.Name:lower():find(searchText) then
                button.Visible = true
                keyBox.Visible = true
                button.Position = UDim2.new(0, 48, 0, yOffset)
                keyBox.Position = UDim2.new(0, 8, 0, yOffset)
                yOffset = yOffset + 40
            else
                button.Visible = false
                keyBox.Visible = false
            end
        end

        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    end)

    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

local addEmotePopup = createAddEmoteGUI(G2L["1"], addButtonsToFrame)
G2L["c"].MouseButton1Click:Connect(function()
    addEmotePopup.toggle()
end)

G2L["1"].Destroying:Connect(function()
    if ghostEnabled then
        setGhostEnabled(false)
    end
end)

local dragFrame = G2L["4"]
local mainFrame = G2L["2"]
local dragging = false
local dragInput, dragStart, startPos
local dragTween

local initialOffset

dragFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isDraggingSlider then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        initialOffset = startPos - UDim2.new(0, input.Position.X, 0, input.Position.Y)
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

dragFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging and not isDraggingSlider then
        if not dragStart or not startPos then
            dragging = false
            return
        end
        
        local newPos = UDim2.new(
            0, input.Position.X + initialOffset.X.Offset,
            0, input.Position.Y + initialOffset.Y.Offset
        )
        
        if dragTween then dragTween:Cancel() end
        dragTween = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = newPos}
        )
        dragTween:Play()
    end
end)

local guiVisible = true
local toggleKey = Enum.KeyCode.N

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == toggleKey then
        guiVisible = not guiVisible
        G2L["1"].Enabled = guiVisible
    end
end)

addButtonsToFrame()

return G2L["1"], require;
