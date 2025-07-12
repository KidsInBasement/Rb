-- Advanced ESP Module for KIB Hook
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Camera = workspace.CurrentCamera

-- Local variables that need to be set by the main script
local featureStates = {}
local LocalPlayer = nil

-- ESP Settings (These will be the ones directly manipulated by GUI)
local ESP = {
    Enabled = false, -- This will be controlled by main script's featureStates.AdvancedESP
    TeamCheck = true,
    Boxes = true,
    BoxShift = CFrame.new(0, 0, 0),
    BoxSize = Vector3.new(4, 6, 0),
    Color = Color3.fromRGB(255, 165, 0),
    FaceCamera = false, -- Unused in current logic, but kept for config
    Names = true,
    Health = true,
    HealthTextSize = 19,
    HealthTextOffset = 40,
    Distance = true,
    DistanceTextSize = 17,
    DistanceTextOffset = 21,
    Tracers = true,
    TracerFrom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 1),
    TracerColor = Color3.fromRGB(255, 165, 0),
    TracerThickness = 1,
    TracerTransparency = 1,
    Outlines = true,
    OutlineColor = Color3.new(0, 0, 0),
    OutlineSize = 1,
    FillColor = Color3.fromRGB(0, 0, 0),
    FillTransparency = 0.5,
    TextSize = 16,
    TextFont = Drawing.Fonts.UI,
    TextColor = Color3.fromRGB(255, 165, 0),
    TextOutline = true,
    TextOutlineColor = Color3.fromRGB(255, 165, 0),
    TextOffset = Vector2.new(0, 0),
}

local ESPObjects = {}

local function CreateESP(playerToESP)
    if ESPObjects[playerToESP] then
        return
    end

    local ESPObject = {
        Player = playerToESP,
        Drawings = {},
        Connections = {},
    }

    local function UpdateESP()
        if
            not playerToESP.Character
            or not playerToESP.Character:FindFirstChild('Humanoid')
            or not playerToESP.Character:FindFirstChild('HumanoidRootPart')
            or not featureStates.AdvancedESP -- Check main toggle state
        then
            -- Hide all ESP elements if player is not visible or AdvancedESP is off
            for _, drawing in pairs(ESPObject.Drawings) do
                drawing.Visible = false
            end
            return
        end

        local RootPart = playerToESP.Character.HumanoidRootPart
        local Head = playerToESP.Character:FindFirstChild('Head')
        local Humanoid = playerToESP.Character.Humanoid

        local RootPos, RootVis = Camera:WorldToViewportPoint(RootPart.Position)
        local HeadPos = Head and Camera:WorldToViewportPoint(Head.Position)
            or RootPos

        local isVisible = RootVis
        if not isVisible then
            for _, drawing in pairs(ESPObject.Drawings) do
                drawing.Visible = false
            end
            return
        end

        -- Box
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
            ESPObject.Drawings.Box.Visible = true

            -- Box outline
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
                ESPObject.Drawings.BoxOutline.Visible = true
            else
                if ESPObject.Drawings.BoxOutline then
                    ESPObject.Drawings.BoxOutline.Visible = false
                end
            end

            -- Box fill
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
                ESPObject.Drawings.BoxFill.Visible = true
            else
                if ESPObject.Drawings.BoxFill then
                    ESPObject.Drawings.BoxFill.Visible = false
                end
            end
        else
            if ESPObject.Drawings.Box then ESPObject.Drawings.Box.Visible = false end
            if ESPObject.Drawings.BoxOutline then ESPObject.Drawings.BoxOutline.Visible = false end
            if ESPObject.Drawings.BoxFill then ESPObject.Drawings.BoxFill.Visible = false end
        end

        -- Name
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
            ESPObject.Drawings.Name.Text = playerToESP.Name
            ESPObject.Drawings.Name.Position = NamePosition
            ESPObject.Drawings.Name.Visible = true

            -- Name outline
            if ESP.TextOutline then
                if not ESPObject.Drawings.NameOutline then
                    ESPObject.Drawings.NameOutline = Drawing.new('Text')
                    ESPObject.Drawings.NameOutline.Visible = false
                    ESPObject.Drawings.NameOutline.Color = ESP.TextOutlineColor
                    ESPObject.Drawings.NameOutline.Size = ESP.TextSize
                    ESPObject.Drawings.NameOutline.Font = ESP.TextFont
                    ESPObject.Drawings.NameOutline.Center = true
                end

                ESPObject.Drawings.NameOutline.Text = playerToESP.Name
                ESPObject.Drawings.NameOutline.Position = NamePosition
                    + Vector2.new(1, 1)
                ESPObject.Drawings.NameOutline.Visible = true
            else
                if ESPObject.Drawings.NameOutline then
                    ESPObject.Drawings.NameOutline.Visible = false
                end
            end
        else
            if ESPObject.Drawings.Name then ESPObject.Drawings.Name.Visible = false end
            if ESPObject.Drawings.NameOutline then ESPObject.Drawings.NameOutline.Visible = false end
        end

        -- Health
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
            ESPObject.Drawings.Health.Visible = true

            -- Health outline
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
                ESPObject.Drawings.HealthOutline.Visible = true
            else
                if ESPObject.Drawings.HealthOutline then
                    ESPObject.Drawings.HealthOutline.Visible = false
                end
            end
        else
            if ESPObject.Drawings.Health then ESPObject.Drawings.Health.Visible = false end
            if ESPObject.Drawings.HealthOutline then ESPObject.Drawings.HealthOutline.Visible = false end
        end

        -- Distance
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
            ESPObject.Drawings.Distance.Visible = true

            -- Distance outline
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
                ESPObject.Drawings.DistanceOutline.Visible = true
            else
                if ESPObject.Drawings.DistanceOutline then
                    ESPObject.Drawings.DistanceOutline.Visible = false
                end
            end
        else
            if ESPObject.Drawings.Distance then ESPObject.Drawings.Distance.Visible = false end
            if ESPObject.Drawings.DistanceOutline then ESPObject.Drawings.DistanceOutline.Visible = false end
        end

        -- Tracer
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
            ESPObject.Drawings.Tracer.Visible = true
        else
            if ESPObject.Drawings.Tracer then
                ESPObject.Drawings.Tracer.Visible = false
            end
        end
    end

    local function ClearESP()
        for _, DrawingObject in pairs(ESPObjects[playerToESP].Drawings) do
            if DrawingObject and DrawingObject.Remove then
                DrawingObject.Visible = false
                DrawingObject:Remove()
            end
        end
        ESPObjects[playerToESP].Drawings = {}
    end

    local function CharacterAdded(Character)
        if not Character then
            return
        end

        local Humanoid = Character:WaitForChild('Humanoid')
        local RootPart = Character:WaitForChild('HumanoidRootPart')

        ESPObject.Connections.HumanoidDied = Humanoid.Died:Connect(function()
            ClearESP()
        end)

        ESPObject.Connections.CharacterRemoving =
            Character.AncestryChanged:Connect(
                function(_, Parent)
                    if Parent == nil then
                        ClearESP()
                    end
                end
            )

        -- Important: Start the RenderStepped connection only if AdvancedESP is enabled
        -- The main ESPUpdater will handle continuous updates
        if featureStates.AdvancedESP then
            ESPObject.Connections.RenderStepped = RunService.RenderStepped:Connect(
                UpdateESP
            )
        end
    end

    if playerToESP.Character then
        CharacterAdded(playerToESP.Character)
    end

    ESPObject.Connections.CharacterAdded = playerToESP.CharacterAdded:Connect(
        CharacterAdded
    )
    ESPObjects[playerToESP] = ESPObject
end

local function RemoveESP(playerToESP)
    if not ESPObjects[playerToESP] then return end
    
    for _, drawing in pairs(ESPObjects[playerToESP].Drawings) do
        if drawing and drawing.Remove then
            drawing.Visible = false
            drawing:Remove()
        end
    end
    
    for _, connection in pairs(ESPObjects[playerToESP].Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    ESPObjects[playerToESP] = nil
end

local function UpdateAllESP(player_local)
    LocalPlayer = player_local -- Ensure LocalPlayer is set for team check
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and (not ESP.TeamCheck or Player.Team ~= LocalPlayer.Team) then
            if featureStates.AdvancedESP then
                RemoveESP(Player)
                CreateESP(Player)
            else
                RemoveESP(Player)
            end
        end
    end
end

local function ToggleAdvancedESP(state, player_local)
    featureStates.AdvancedESP = state
    LocalPlayer = player_local -- Ensure LocalPlayer is set
    if state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                CreateESP(p)
            end
        end
    else
        for p in pairs(ESPObjects) do
            RemoveESP(p)
        end
    end
end

-- This updater loop will ensure drawing properties are always synced
local ESPUpdater = RunService.Heartbeat:Connect(function()
    if featureStates.AdvancedESP then
        for playerToESP, espObject in pairs(ESPObjects) do
            if playerToESP and playerToESP.Character and espObject and espObject.UpdateESP then
                -- This will update visibility and position
                espObject.UpdateESP()
                -- Update drawing properties (colors, sizes etc.)
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

-- Function to set feature states from main script
local function SetFeatureStatesRef(statesTable)
    featureStates = statesTable
end

-- Function to set LocalPlayer from main script
local function SetLocalPlayerRef(playerRef)
    LocalPlayer = playerRef
end

-- Return functions and tables to be accessed by the main script
return {
    ESPConfig = ESP, -- Renamed to avoid direct conflict with 'ESP' variable in main script
    ESPObjects = ESPObjects,
    CreateESP = CreateESP,
    RemoveESP = RemoveESP,
    UpdateAllESP = UpdateAllESP,
    ToggleAdvancedESP = ToggleAdvancedESP,
    SetFeatureStates = SetFeatureStatesRef,
    SetLocalPlayer = SetLocalPlayerRef
}
