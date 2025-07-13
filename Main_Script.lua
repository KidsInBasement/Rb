local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Teams = game:GetService('Teams')
local TweenService = game:GetService('TweenService')
local player = Players.LocalPlayer
local gui = player:WaitForChild('PlayerGui')
local Camera = workspace.CurrentCamera

local featureStates = _G.featureStates
local featureKeybinds = _G.featureKeybinds
local toggleComponents = _G.toggleComponents
local ESP = _G.ESP
local Aim = _G.Aim
local FOVCircle = _G.FOVCircle

local activeESP = {}
local activeHighlights = {}
local noclipConnection
local espConnections = {}
local chamsConnections = {}
local ESPObjects = {}
local ESPUpdater

_G.toggleNoclip = function(state)
    featureStates.NoClip = state
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA('BasePart') then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end

if not _G.FullBrightExecuted then
    _G.FullBrightEnabled = false
    _G.NormalLightingSettings = {
        Brightness = game:GetService('Lighting').Brightness,
        ClockTime = game:GetService('Lighting').ClockTime,
        FogEnd = game:GetService('Lighting').FogEnd,
        GlobalShadows = game:GetService('Lighting').GlobalShadows,
        Ambient = game:GetService('Lighting').Ambient,
    }

    local lightingProperties = {
        'Brightness',
        'ClockTime',
        'FogEnd',
        'GlobalShadows',
        'Ambient',
    }
    for _, property in ipairs(lightingProperties) do
        game
            :GetService('Lighting')
            :GetPropertyChangedSignal(property)
            :Connect(function()
                local currentValue = game:GetService('Lighting')[property]
                local normalValue = _G.NormalLightingSettings[property]

                local targetValue
                if property == 'Brightness' then
                    targetValue = 1
                elseif property == 'ClockTime' then
                    targetValue = 12
                elseif property == 'FogEnd' then
                    targetValue = 786543
                elseif property == 'GlobalShadows' then
                    targetValue = false
                elseif property == 'Ambient' then
                    targetValue = Color3.fromRGB(178, 178, 178)
                end

                if
                    currentValue ~= targetValue
                    and currentValue ~= normalValue
                then
                    _G.NormalLightingSettings[property] = currentValue
                    if not _G.FullBrightEnabled then
                        repeat
                            task.wait()
                        until _G.FullBrightEnabled
                    end
                    game:GetService('Lighting')[property] = targetValue
                end
            end)
    end

    spawn(function()
        repeat
            task.wait()
        until _G.FullBrightEnabled
        while task.wait() do
            if featureStates.FullBright then
                game:GetService('Lighting').Brightness = 1
                game:GetService('Lighting').ClockTime = 12
                game:GetService('Lighting').FogEnd = 786543
                game:GetService('Lighting').GlobalShadows = false
                game:GetService('Lighting').Ambient = Color3.fromRGB(
                    178,
                    178,
                    178
                )
            end
        end
    end)

    _G.FullBrightExecuted = true
end

_G.toggleFullBright = function(state)
    featureStates.FullBright = state
    _G.FullBrightEnabled = state

    if state then
        game:GetService('Lighting').Brightness = 1
        game:GetService('Lighting').ClockTime = 12
        game:GetService('Lighting').FogEnd = 786543
        game:GetService('Lighting').GlobalShadows = false
        game:GetService('Lighting').Ambient = Color3.fromRGB(178, 178, 178)
    else
        game:GetService('Lighting').Brightness =
            _G.NormalLightingSettings.Brightness
        game:GetService('Lighting').ClockTime =
            _G.NormalLightingSettings.ClockTime
        game:GetService('Lighting').FogEnd = _G.NormalLightingSettings.FogEnd
        game:GetService('Lighting').GlobalShadows =
            _G.NormalLightingSettings.GlobalShadows
        game:GetService('Lighting').Ambient = _G.NormalLightingSettings.Ambient
    end
end

local function getTeamColor(player)
    if not player.Team then
        return Color3.fromRGB(255, 255, 0)
    end
    local baseColor = player.Team.TeamColor.Color
    return Color3.new(
        math.min(baseColor.R * (1 + 0.3), 1),
        math.min(baseColor.G * (1 + 0.3), 1),
        math.min(baseColor.B * (1 + 0.3), 1)
    )
end

local function createLegacyESP(player)
    if activeESP[player] then
        activeESP[player]:Destroy()
    end

    if
        not featureStates.ESP
        or player == Players.LocalPlayer
        or not player.Character
    then
        return
    end

    local head = player.Character:FindFirstChild('Head')
    if not head then
        player.CharacterAdded:Wait()
        head = player.Character:WaitForChild('Head', 2)
        if not head then
            return
        end
    end

    local espGui = Instance.new('BillboardGui')
    espGui.Name = 'ESP_' .. player.UserId
    espGui.AlwaysOnTop = true
    espGui.Size = UDim2.new(0, 200, 0, 50)
    espGui.StudsOffset = Vector3.new(0, 3, 0)
    espGui.Adornee = head
    espGui.Parent = head

    local espText = Instance.new('TextLabel')
    espText.Size = UDim2.new(1, 0, 1, 0)
    espText.BackgroundTransparency = 1
    espText.Text = player.Name
    espText.TextColor3 = getTeamColor(player)
    espText.TextSize = 18
    espText.Font = Enum.Font.GothamBold
    espText.TextStrokeTransparency = 0
    espText.TextStrokeColor3 = Color3.new(0, 0, 0)
    espText.Parent = espGui

    activeESP[player] = espGui

    if not espConnections[player] then
        espConnections[player] = player.CharacterAdded:Connect(
            function(newCharacter)
                if activeESP[player] then
                    activeESP[player]:Destroy()
                    activeESP[player] = nil
                end

                local newHead
                repeat
                    newHead = newCharacter:FindFirstChild('Head')
                    task.wait()
                until newHead or not featureStates.ESP

                if newHead and featureStates.ESP then
                    createLegacyESP(player)
                end
            end
        )
    end

    player:GetPropertyChangedSignal('Team'):Connect(function()
        espText.TextColor3 = getTeamColor(player)
    end)
end

_G.updateESP = function(state)
    featureStates.ESP = state
    if not state then
        for player, gui in pairs(activeESP) do
            gui:Destroy()
            activeESP[player] = nil
        end
        for _, conn in pairs(espConnections) do
            conn:Disconnect()
        end
        espConnections = {}
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                if player.Character then
                    createLegacyESP(player)
                end
                if not espConnections[player] then
                    espConnections[player] = player.CharacterAdded:Connect(function(character)
                        if featureStates.ESP then
                            createLegacyESP(player)
                        end
                    end)
                end
            end
        end
    end
end

local function createChams(player)
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
    end

    if
        not featureStates.Chams
        or player == Players.LocalPlayer
        or not player.Character
    then
        return
    end

    local highlight = Instance.new('Highlight')
    highlight.Name = 'Highlight_' .. player.UserId
    highlight.Adornee = player.Character
    highlight.FillColor = getTeamColor(player)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = player.Character

    activeHighlights[player] = highlight

    if not chamsConnections[player] then
        chamsConnections[player] = player.CharacterAdded:Connect(
            function(newCharacter)
                if activeHighlights[player] then
                    activeHighlights[player]:Destroy()
                end

                task.wait(0.5)
                if featureStates.Chams then
                    createChams(player)
                end
            end
        )
    end

    player:GetPropertyChangedSignal('Team'):Connect(function()
        highlight.FillColor = getTeamColor(player)
    end)
end

_G.updateChams = function(state)
    featureStates.Chams = state
    if not state then
        for player, highlight in pairs(activeHighlights) do
            highlight:Destroy()
            activeHighlights[player] = nil
        end
        for _, conn in pairs(chamsConnections) do
            conn:Disconnect()
        end
        chamsConnections = {}
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                if player.Character then
                    createChams(player)
                end
                if not chamsConnections[player] then
                    chamsConnections[player] = player.CharacterAdded:Connect(function(character)
                        if featureStates.Chams then
                            createChams(player)
                        end
                    })
                end
            end
        end
    end
end

local function CreateAdvancedESP(player)
    if ESPObjects[player] then
        return
    end

    local ESPObject = {
        Player = player,
        Drawings = {},
        Connections = {},
    }

    local function UpdateDrawingESP()
        if
            not player.Character
            or not player.Character:FindFirstChild('Humanoid')
            or not player.Character:FindFirstChild('HumanoidRootPart')
        then
            return
        end

        local RootPart = player.Character.HumanoidRootPart
        local Head = player.Character:FindFirstChild('Head')
        local Humanoid = player.Character.Humanoid

        local RootPos, RootVis = Camera:WorldToViewportPoint(RootPart.Position)
        local HeadPos = Head and Camera:WorldToViewportPoint(Head.Position)
            or RootPos

        local isVisible = RootVis
        if not isVisible then
            if ESPObject.Drawings.Box then ESPObject.Drawings.Box.Visible = false end
            if ESPObject.Drawings.BoxOutline then ESPObject.Drawings.BoxOutline.Visible = false end
            if ESPObject.Drawings.BoxFill then ESPObject.Drawings.BoxFill.Visible = false end
            if ESPObject.Drawings.Name then ESPObject.Drawings.Name.Visible = false end
            if ESPObject.Drawings.NameOutline then ESPObject.Drawings.NameOutline.Visible = false end
            if ESPObject.Drawings.Health then ESPObject.Drawings.Health.Visible = false end
            if ESPObject.Drawings.HealthOutline then ESPObject.Drawings.HealthOutline.Visible = false end
            if ESPObject.Drawings.Distance then ESPObject.Drawings.Distance.Visible = false end
            if ESPObject.Drawings.DistanceOutline then ESPObject.Drawings.DistanceOutline.Visible = false end
            if ESPObject.Drawings.Tracer then ESPObject.Drawings.Tracer.Visible = false end
            return
        end

        if ESP.Boxes and featureStates.ESPBoxes then
            local cameraCFrame = Camera.CFrame
            local rightVector = cameraCFrame.RightVector
            local upVector = cameraCFrame.UpVector
            
            local centerPos = (RootPart.CFrame * ESP.BoxShift).Position
            local topRight = Camera:WorldToViewportPoint(centerPos + (rightVector * ESP.BoxSize.X/2) + (upVector * ESP.BoxSize.Y/2))
            local bottomLeft = Camera:WorldToViewportPoint(centerPos - (rightVector * ESP.BoxSize.X/2) - (upVector * ESP.BoxSize.Y/2))
            
            local Size = Vector2.new(
                math.abs(topRight.X - bottomLeft.X),
                math.abs(topRight.Y - bottomLeft.Y)
            )
            local Position = Vector2.new(
                math.min(topRight.X, bottomLeft.X),
                math.min(topRight.Y, bottomLeft.Y)
            )

            if not ESPObject.Drawings.Box then
                ESPObject.Drawings.Box = Drawing.new('Square')
                ESPObject.Drawings.Box.Visible = false
                ESPObject.Drawings.Box.Color = ESP.Color
                ESPObject.Drawings.Box.Thickness = 1
                ESPObject.Drawings.Box.Filled = false
            end

            ESPObject.Drawings.Box.Size = Size
            ESPObject.Drawings.Box.Position = Position
            ESPObject.Drawings.Box.Visible = featureStates.ESPBoxes and isVisible

            if ESP.Outlines and featureStates.ESPOutlines then
                if not ESPObject.Drawings.BoxOutline then
                    ESPObject.Drawings.BoxOutline = Drawing.new('Square')
                    ESPObject.Drawings.BoxOutline.Visible = false
                    ESPObject.Drawings.BoxOutline.Color = ESP.OutlineColor
                    ESPObject.Drawings.BoxOutline.Thickness = ESP.OutlineSize
                    ESPObject.Drawings.BoxOutline.Filled = false
                end

                ESPObject.Drawings.BoxOutline.Size = Size
                    + Vector2.new(ESP.OutlineSize * 2, ESP.OutlineSize * 2)
                ESPObject.Drawings.BoxOutline.Position = Position
                    - Vector2.new(ESP.OutlineSize, ESP.OutlineSize)
                ESPObject.Drawings.BoxOutline.Visible = featureStates.ESPOutlines and featureStates.ESPBoxes and isVisible
            else
                if ESPObject.Drawings.BoxOutline then
                    ESPObject.Drawings.BoxOutline.Visible = false
                end
            end

            if ESP.FillTransparency < 1 then
                if not ESPObject.Drawings.BoxFill then
                    ESPObject.Drawings.BoxFill = Drawing.new('Square')
                    ESPObject.Drawings.BoxFill.Visible = false
                    ESPObject.Drawings.BoxFill.Color = ESP.FillColor
                    ESPObject.Drawings.BoxFill.Thickness = 1
                    ESPObject.Drawings.BoxFill.Filled = true
                end

                ESPObject.Drawings.BoxFill.Size = Size
                ESPObject.Drawings.BoxFill.Position = Position
                ESPObject.Drawings.BoxFill.Transparency = ESP.FillTransparency
                ESPObject.Drawings.BoxFill.Visible = featureStates.ESPBoxes and isVisible
            else
                if ESPObject.Drawings.BoxFill then
                    ESPObject.Drawings.BoxFill.Visible = false
                end
            end
        else
            if ESPObject.Drawings.Box then
                ESPObject.Drawings.Box.Visible = false
            end
            if ESPObject.Drawings.BoxOutline then
                ESPObject.Drawings.BoxOutline.Visible = false
            end
            if ESPObject.Drawings.BoxFill then
                ESPObject.Drawings.BoxFill.Visible = false
            end
        end

        if ESP.Names and featureStates.ESPNames then
            if not ESPObject.Drawings.Name then
                ESPObject.Drawings.Name = Drawing.new('Text')
                ESPObject.Drawings.Name.Visible = false
                ESPObject.Drawings.Name.Color = ESP.TextColor
                ESPObject.Drawings.Name.Size = ESP.TextSize
                ESPObject.Drawings.Name.Font = ESP.TextFont
                ESPObject.Drawings.Name.Center = true
            end

            local NamePosition = Vector2.new(
                RootPos.X,
                RootPos.Y - ESP.TextOffset.Y
            )
            ESPObject.Drawings.Name.Text = player.Name
            ESPObject.Drawings.Name.Position = NamePosition
            ESPObject.Drawings.Name.Visible = featureStates.ESPNames and isVisible

            if ESP.TextOutline then
                if not ESPObject.Drawings.NameOutline then
                    ESPObject.Drawings.NameOutline = Drawing.new('Text')
                    ESPObject.Drawings.NameOutline.Visible = false
                    ESPObject.Drawings.NameOutline.Color = ESP.TextOutlineColor
                    ESPObject.Drawings.NameOutline.Size = ESP.TextSize
                    ESPObject.Drawings.NameOutline.Font = ESP.TextFont
                    ESPObject.Drawings.NameOutline.Center = true
                end

                ESPObject.Drawings.NameOutline.Text = player.Name
                ESPObject.Drawings.NameOutline.Position = NamePosition
                    + Vector2.new(1, 1)
                ESPObject.Drawings.NameOutline.Visible = featureStates.ESPNames and isVisible
            else
                if ESPObject.Drawings.NameOutline then
                    ESPObject.Drawings.NameOutline.Visible = false
                end
            end
        else
            if ESPObject.Drawings.Name then
                ESPObject.Drawings.Name.Visible = false
            end
            if ESPObject.Drawings.NameOutline then
                ESPObject.Drawings.NameOutline.Visible = false
            end
        end

        if ESP.Health and featureStates.ESPHealth then
            if not ESPObject.Drawings.Health then
                ESPObject.Drawings.Health = Drawing.new('Text')
                ESPObject.Drawings.Health.Visible = false
                ESPObject.Drawings.Health.Color = ESP.TextColor
                ESPObject.Drawings.Health.Size = ESP.HealthTextSize
                ESPObject.Drawings.Health.Font = ESP.TextFont
                ESPObject.Drawings.Health.Center = true
            end

            local HealthPosition = Vector2.new(
                RootPos.X,
                RootPos.Y - ESP.HealthTextOffset
            )
            ESPObject.Drawings.Health.Text = tostring(
                math.floor(Humanoid.Health)
            ) .. '/' .. tostring(math.floor(Humanoid.MaxHealth))
            ESPObject.Drawings.Health.Position = HealthPosition
            ESPObject.Drawings.Health.Visible = featureStates.ESPHealth and isVisible

            if ESP.TextOutline then
                if not ESPObject.Drawings.HealthOutline then
                    ESPObject.Drawings.HealthOutline = Drawing.new('Text')
                    ESPObject.Drawings.HealthOutline.Visible = false
                    ESPObject.Drawings.HealthOutline.Color = ESP.TextOutlineColor
                    ESPObject.Drawings.HealthOutline.Size = ESP.HealthTextSize
                    ESPObject.Drawings.HealthOutline.Font = ESP.TextFont
                    ESPObject.Drawings.HealthOutline.Center = true
                end

                ESPObject.Drawings.HealthOutline.Text =
                    ESPObject.Drawings.Health.Text
                ESPObject.Drawings.HealthOutline.Position = HealthPosition
                    + Vector2.new(1, 1)
                ESPObject.Drawings.HealthOutline.Visible = featureStates.ESPHealth and isVisible
            else
                if ESPObject.Drawings.HealthOutline then
                    ESPObject.Drawings.HealthOutline.Visible = false
                end
            end
        else
            if ESPObject.Drawings.Health then
                ESPObject.Drawings.Health.Visible = false
            end
            if ESPObject.Drawings.HealthOutline then
                ESPObject.Drawings.HealthOutline.Visible = false
            end
        end

        if ESP.Distance and featureStates.ESPDistance then
            if not ESPObject.Drawings.Distance then
                ESPObject.Drawings.Distance = Drawing.new('Text')
                ESPObject.Drawings.Distance.Visible = false
                ESPObject.Drawings.Distance.Color = ESP.TextColor
                ESPObject.Drawings.Distance.Size = ESP.DistanceTextSize
                ESPObject.Drawings.Distance.Font = ESP.TextFont
                ESPObject.Drawings.Distance.Center = true
            end

            local DistancePosition = Vector2.new(
                RootPos.X,
                RootPos.Y - ESP.DistanceTextOffset
            )
            local Distance = math.floor(
                (RootPart.Position - Camera.CFrame.Position).Magnitude
            )
            ESPObject.Drawings.Distance.Text = tostring(Distance) .. 'm'
            ESPObject.Drawings.Distance.Position = DistancePosition
            ESPObject.Drawings.Distance.Visible = featureStates.ESPDistance and isVisible

            if ESP.TextOutline then
                if not ESPObject.Drawings.DistanceOutline then
                    ESPObject.Drawings.DistanceOutline = Drawing.new('Text')
                    ESPObject.Drawings.DistanceOutline.Visible = false
                    ESPObject.Drawings.DistanceOutline.Color = ESP.TextOutlineColor
                    ESPObject.Drawings.DistanceOutline.Size =
                        ESP.DistanceTextSize
                    ESPObject.Drawings.DistanceOutline.Font = ESP.TextFont
                    ESPObject.Drawings.DistanceOutline.Center = true
                end

                ESPObject.Drawings.DistanceOutline.Text =
                    ESPObject.Drawings.Distance.Text
                ESPObject.Drawings.DistanceOutline.Position = DistancePosition
                    + Vector2.new(1, 1)
                ESPObject.Drawings.DistanceOutline.Visible = featureStates.ESPDistance and isVisible
            else
                if ESPObject.Drawings.DistanceOutline then
                    ESPObject.Drawings.DistanceOutline.Visible = false
                end
            end
        else
            if ESPObject.Drawings.Distance then
                ESPObject.Drawings.Distance.Visible = false
            end
            if ESPObject.Drawings.DistanceOutline then
                ESPObject.Drawings.DistanceOutline.Visible = false
            end
        end

        if ESP.Tracers and featureStates.ESPTracers then
            if not ESPObject.Drawings.Tracer then
                ESPObject.Drawings.Tracer = Drawing.new('Line')
                ESPObject.Drawings.Tracer.Visible = false
                ESPObject.Drawings.Tracer.Color = ESP.TracerColor
                ESPObject.Drawings.Tracer.Thickness = ESP.TracerThickness
                ESPObject.Drawings.Tracer.Transparency = ESP.TracerTransparency
            end

            ESPObject.Drawings.Tracer.From = ESP.TracerFrom
            ESPObject.Drawings.Tracer.To = Vector2.new(RootPos.X, RootPos.Y)
            ESPObject.Drawings.Tracer.Visible = featureStates.ESPTracers and isVisible
        else
            if ESPObject.Drawings.Tracer then
                ESPObject.Drawings.Tracer.Visible = false
            end
        end
    end

    local function ClearESPDrawing()
        for _, DrawingObject in pairs(ESPObject.Drawings) do
            if DrawingObject and DrawingObject.Remove then
                DrawingObject.Visible = false
                DrawingObject:Remove()
            end
        end
        ESPObject.Drawings = {}
    end

    local function CharacterAdded(Character)
        if not Character then
            return
        end

        local Humanoid = Character:WaitForChild('Humanoid')
        local RootPart = Character:WaitForChild('HumanoidRootPart')

        ESPObject.Connections.HumanoidDied = Humanoid.Died:Connect(function()
            ClearESPDrawing()
        end)

        ESPObject.Connections.CharacterRemoving =
            Character.AncestryChanged:Connect(
                function(_, Parent)
                    if Parent == nil then
                        ClearESPDrawing()
                    end
                end
            )

        ESPObject.Connections.RenderStepped = RunService.RenderStepped:Connect(
            UpdateDrawingESP
        )
    end

    if player.Character then
        CharacterAdded(player.Character)
    end

    ESPObject.Connections.CharacterAdded = player.CharacterAdded:Connect(
        CharacterAdded
    )
    ESPObjects[player] = ESPObject
end

local function RemoveAdvancedESP(player)
    if not ESPObjects[player] then return end
    
    for _, drawing in pairs(ESPObjects[player].Drawings) do
        if drawing and drawing.Remove then
            drawing.Visible = false
            drawing:Remove()
        end
    end
    
    for _, connection in pairs(ESPObjects[player].Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    ESPObjects[player] = nil
end

_G.UpdateAllESP = function()
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= player and (not ESP.TeamCheck or Player.Team ~= player.Team) then
            if featureStates.AdvancedESP then
                RemoveAdvancedESP(Player)
                CreateAdvancedESP(Player)
            else
                RemoveAdvancedESP(Player)
            end
        end
    end
end

ESPUpdater = RunService.Heartbeat:Connect(function()
    if featureStates.AdvancedESP then
        for player, espObject in pairs(ESPObjects) do
            if player and player.Character then
                if espObject.Drawings.Box then
                    espObject.Drawings.Box.Color = ESP.Color
                end
                if espObject.Drawings.BoxOutline then
                    espObject.Drawings.BoxOutline.Color = ESP.OutlineColor
                    espObject.Drawings.BoxOutline.Thickness = ESP.OutlineSize
                end
                if espObject.Drawings.BoxFill then
                    espObject.Drawings.BoxFill.Color = ESP.FillColor
                    espObject.Drawings.BoxFill.Transparency = ESP.FillTransparency
                end
                if espObject.Drawings.Name then
                    espObject.Drawings.Name.Color = ESP.TextColor
                    espObject.Drawings.Name.Size = ESP.TextSize
                end
                if espObject.Drawings.NameOutline then
                    espObject.Drawings.NameOutline.Color = ESP.TextOutlineColor
                    espObject.Drawings.NameOutline.Size = ESP.TextSize
                end
                if espObject.Drawings.Health then
                    espObject.Drawings.Health.Color = ESP.TextColor
                    espObject.Drawings.Health.Size = ESP.HealthTextSize
                end
                if espObject.Drawings.HealthOutline then
                    espObject.Drawings.HealthOutline.Color = ESP.TextOutlineColor
                    espObject.Drawings.HealthOutline.Size = ESP.HealthTextSize
                end
                if espObject.Drawings.Distance then
                    espObject.Drawings.Distance.Color = ESP.TextColor
                    espObject.Drawings.Distance.Size = ESP.DistanceTextSize
                end
                if espObject.Drawings.DistanceOutline then
                    espObject.Drawings.DistanceOutline.Color = ESP.TextOutlineColor
                    espObject.Drawings.DistanceOutline.Size = ESP.DistanceTextSize
                end
                if espObject.Drawings.Tracer then
                    espObject.Drawings.Tracer.Color = ESP.TracerColor
                    espObject.Drawings.Tracer.Thickness = ESP.TracerThickness
                end
            end
        end
    end
end)

_G.ToggleAdvancedESP = function(state)
    featureStates.AdvancedESP = state
    if state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer and p.Character then
                CreateAdvancedESP(p)
            end
        end
    else
        for p in pairs(ESPObjects) do
            RemoveAdvancedESP(p)
        end
    end
end

local function handlePlayerLogic(p)
    p.CharacterAdded:Connect(function()
        if featureStates.ESP then
            createLegacyESP(p)
        end
        if featureStates.Chams then
            createChams(p)
        end
        if featureStates.AdvancedESP then
            CreateAdvancedESP(p)
        end
    end)

    if p.Character then
        if featureStates.ESP then
            createLegacyESP(p)
        end
        if featureStates.Chams then
            createChams(p)
        end
        if featureStates.AdvancedESP then
            CreateAdvancedESP(p)
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    handlePlayerLogic(p)
    if featureStates.AdvancedESP then
        CreateAdvancedESP(p)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if activeESP[p] then
        activeESP[p]:Destroy()
    end
    if activeHighlights[p] then
        activeHighlights[p]:Destroy()
    end
    if espConnections[p] then
        espConnections[p]:Disconnect()
    end
    if chamsConnections[p] then
        chamsConnections[p]:Disconnect()
    end
    RemoveAdvancedESP(p)
end)

for _, p in ipairs(Players:GetPlayers()) do
    handlePlayerLogic(p)
    if featureStates.AdvancedESP then
        CreateAdvancedESP(p)
    end
end

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Aim.FOV
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            if Aim.TeamCheck and v.Team and player.Team and v.Team == player.Team then 
                continue 
            end
            
            local targetPart = v.Character:FindFirstChild(Aim.AimPart)
            if not targetPart then continue end
            
            local screenPos = Camera:WorldToScreenPoint(targetPart.Position)
            if screenPos.Z > 0 then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                
                if distance < shortestDistance then
                    if Aim.VisibilityCheck then
                        local raycastParams = RaycastParams.new()
                        raycastParams.FilterDescendantsInstances = {player.Character, v.Character}
                        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                        
                        local rayOrigin = Camera.CFrame.Position
                        local rayDirection = (targetPart.Position - rayOrigin).Unit * (rayOrigin - targetPart.Position).Magnitude
                        local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                        
                        if not raycastResult or raycastResult.Instance:IsDescendantOf(v.Character) then
                            closestPlayer = v
                            shortestDistance = distance
                        end
                    else
                        closestPlayer = v
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closestPlayer
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = Aim.FOV
    FOVCircle.Visible = Aim.ShowFOV and Aim.Enabled
    
    local keyPressed = false
    if Aim.AimKey then
        if Aim.CurrentKey == "MB1" then
            keyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        elseif Aim.CurrentKey == "MB2" then
            keyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        elseif Aim.CurrentKey == "MB3" then
            keyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
        else
            keyPressed = UserInputService:IsKeyDown(Aim.AimKey)
        end
    end
    
    if Aim.Enabled and keyPressed then
        local target = GetClosestPlayer()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(Aim.AimPart)
            if targetPart then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            end
        end
    end
end)

warn('KIB Hook - Core Logic (from GitHub) Loaded Successfully!')
