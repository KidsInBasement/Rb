local ESP = {
    Enabled = false,
    TeamCheck = true,
    Boxes = true,
    BoxShift = CFrame.new(0, 0, 0),
    BoxSize = Vector3.new(4, 6, 0),
    Color = Color3.fromRGB(255, 165, 0),
    FaceCamera = false,
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

local function CreateESP(player)
    if ESPObjects[player] then return end

    local ESPObject = {
        Player = player,
        Drawings = {},
        Connections = {},
    }

    local function UpdateESP()
        if not player.Character or not player.Character:FindFirstChild('Humanoid') or not player.Character:FindFirstChild('HumanoidRootPart') then
            return
        end

        local RootPart = player.Character.HumanoidRootPart
        local Head = player.Character:FindFirstChild('Head')
        local Humanoid = player.Character.Humanoid

        local RootPos, RootVis = Camera:WorldToViewportPoint(RootPart.Position)
        local HeadPos = Head and Camera:WorldToViewportPoint(Head.Position) or RootPos

        if not RootVis then
            for _, drawing in pairs(ESPObject.Drawings) do
                if drawing then drawing.Visible = false end
            end
            return
        end

        -- Box ESP
        if ESP.Boxes then
            local cameraCFrame = Camera.CFrame
            local rightVector = cameraCFrame.RightVector
            local upVector = cameraCFrame.UpVector
            
            local centerPos = (RootPart.CFrame * ESP.BoxShift).Position
            local topRight = Camera:WorldToViewportPoint(centerPos + (rightVector * ESP.BoxSize.X/2) + (upVector * ESP.BoxSize.Y/2))
            local bottomLeft = Camera:WorldToViewportPoint(centerPos - (rightVector * ESP.BoxSize.X/2) - (upVector * ESP.BoxSize.Y/2))
            
            local Size = Vector2.new(math.abs(topRight.X - bottomLeft.X), math.abs(topRight.Y - bottomLeft.Y))
            local Position = Vector2.new(math.min(topRight.X, bottomLeft.X), math.min(topRight.Y, bottomLeft.Y))

            if not ESPObject.Drawings.Box then
                ESPObject.Drawings.Box = Drawing.new('Square')
                ESPObject.Drawings.Box.Visible = false
                ESPObject.Drawings.Box.Color = ESP.Color
                ESPObject.Drawings.Box.Thickness = 1
                ESPObject.Drawings.Box.Filled = false
            end

            ESPObject.Drawings.Box.Size = Size
            ESPObject.Drawings.Box.Position = Position
            ESPObject.Drawings.Box.Visible = RootVis

            -- Box outline
            if ESP.Outlines then
                if not ESPObject.Drawings.BoxOutline then
                    ESPObject.Drawings.BoxOutline = Drawing.new('Square')
                    ESPObject.Drawings.BoxOutline.Visible = false
                    ESPObject.Drawings.BoxOutline.Color = ESP.OutlineColor
                    ESPObject.Drawings.BoxOutline.Thickness = ESP.OutlineSize
                    ESPObject.Drawings.BoxOutline.Filled = false
                end

                ESPObject.Drawings.BoxOutline.Size = Size + Vector2.new(ESP.OutlineSize * 2, ESP.OutlineSize * 2)
                ESPObject.Drawings.BoxOutline.Position = Position - Vector2.new(ESP.OutlineSize, ESP.OutlineSize)
                ESPObject.Drawings.BoxOutline.Visible = RootVis
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
                ESPObject.Drawings.BoxFill.Visible = RootVis
            end
        end

        -- Name ESP
        if ESP.Names then
            if not ESPObject.Drawings.Name then
                ESPObject.Drawings.Name = Drawing.new('Text')
                ESPObject.Drawings.Name.Visible = false
                ESPObject.Drawings.Name.Color = ESP.TextColor
                ESPObject.Drawings.Name.Size = ESP.TextSize
                ESPObject.Drawings.Name.Font = ESP.TextFont
                ESPObject.Drawings.Name.Center = true
            end

            local NamePosition = Vector2.new(RootPos.X, RootPos.Y - ESP.TextOffset.Y)
            ESPObject.Drawings.Name.Text = player.Name
            ESPObject.Drawings.Name.Position = NamePosition
            ESPObject.Drawings.Name.Visible = RootVis

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

                ESPObject.Drawings.NameOutline.Text = player.Name
                ESPObject.Drawings.NameOutline.Position = NamePosition + Vector2.new(1, 1)
                ESPObject.Drawings.NameOutline.Visible = RootVis
            end
        end

        -- Health ESP
        if ESP.Health then
            if not ESPObject.Drawings.Health then
                ESPObject.Drawings.Health = Drawing.new('Text')
                ESPObject.Drawings.Health.Visible = false
                ESPObject.Drawings.Health.Color = ESP.TextColor
                ESPObject.Drawings.Health.Size = ESP.HealthTextSize
                ESPObject.Drawings.Health.Font = ESP.TextFont
                ESPObject.Drawings.Health.Center = true
            end

            local HealthPosition = Vector2.new(RootPos.X, RootPos.Y - ESP.HealthTextOffset)
            ESPObject.Drawings.Health.Text = tostring(math.floor(Humanoid.Health)) .. '/' .. tostring(math.floor(Humanoid.MaxHealth))
            ESPObject.Drawings.Health.Position = HealthPosition
            ESPObject.Drawings.Health.Visible = RootVis

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

                ESPObject.Drawings.HealthOutline.Text = ESPObject.Drawings.Health.Text
                ESPObject.Drawings.HealthOutline.Position = HealthPosition + Vector2.new(1, 1)
                ESPObject.Drawings.HealthOutline.Visible = RootVis
            end
        end

        -- Distance ESP
        if ESP.Distance then
            if not ESPObject.Drawings.Distance then
                ESPObject.Drawings.Distance = Drawing.new('Text')
                ESPObject.Drawings.Distance.Visible = false
                ESPObject.Drawings.Distance.Color = ESP.TextColor
                ESPObject.Drawings.Distance.Size = ESP.DistanceTextSize
                ESPObject.Drawings.Distance.Font = ESP.TextFont
                ESPObject.Drawings.Distance.Center = true
            end

            local DistancePosition = Vector2.new(RootPos.X, RootPos.Y - ESP.DistanceTextOffset)
            local Distance = math.floor((RootPart.Position - Camera.CFrame.Position).Magnitude)
            ESPObject.Drawings.Distance.Text = tostring(Distance) .. 'm'
            ESPObject.Drawings.Distance.Position = DistancePosition
            ESPObject.Drawings.Distance.Visible = RootVis

            -- Distance outline
            if ESP.TextOutline then
                if not ESPObject.Drawings.DistanceOutline then
                    ESPObject.Drawings.DistanceOutline = Drawing.new('Text')
                    ESPObject.Drawings.DistanceOutline.Visible = false
                    ESPObject.Drawings.DistanceOutline.Color = ESP.TextOutlineColor
                    ESPObject.Drawings.DistanceOutline.Size = ESP.DistanceTextSize
                    ESPObject.Drawings.DistanceOutline.Font = ESP.TextFont
                    ESPObject.Drawings.DistanceOutline.Center = true
                end

                ESPObject.Drawings.DistanceOutline.Text = ESPObject.Drawings.Distance.Text
                ESPObject.Drawings.DistanceOutline.Position = DistancePosition + Vector2.new(1, 1)
                ESPObject.Drawings.DistanceOutline.Visible = RootVis
            end
        end

        -- Tracer ESP
        if ESP.Tracers then
            if not ESPObject.Drawings.Tracer then
                ESPObject.Drawings.Tracer = Drawing.new('Line')
                ESPObject.Drawings.Tracer.Visible = false
                ESPObject.Drawings.Tracer.Color = ESP.TracerColor
                ESPObject.Drawings.Tracer.Thickness = ESP.TracerThickness
                ESPObject.Drawings.Tracer.Transparency = ESP.TracerTransparency
            end

            ESPObject.Drawings.Tracer.From = ESP.TracerFrom
            ESPObject.Drawings.Tracer.To = Vector2.new(RootPos.X, RootPos.Y)
            ESPObject.Drawings.Tracer.Visible = RootVis
        end
    end

    local function ClearESP()
        for _, DrawingObject in pairs(ESPObject.Drawings) do
            DrawingObject.Visible = false
            DrawingObject:Remove()
        end
        ESPObject.Drawings = {}
    end

    local function CharacterAdded(Character)
        if not Character then return end

        local Humanoid = Character:WaitForChild('Humanoid')
        local RootPart = Character:WaitForChild('HumanoidRootPart')

        ESPObject.Connections.HumanoidDied = Humanoid.Died:Connect(function()
            ClearESP()
        end)

        ESPObject.Connections.CharacterRemoving = Character.AncestryChanged:Connect(function(_, Parent)
            if Parent == nil then
                ClearESP()
            end
        end)

        ESPObject.Connections.RenderStepped = RunService.RenderStepped:Connect(UpdateESP)
    end

    if player.Character then
        CharacterAdded(player.Character)
    end

    ESPObject.Connections.CharacterAdded = player.CharacterAdded:Connect(CharacterAdded)
    ESPObjects[player] = ESPObject
end

local function RemoveESP(player)
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

local function UpdateAllESP()
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= player and (not ESP.TeamCheck or Player.Team ~= player.Team) then
            RemoveESP(Player)
            CreateESP(Player)
        end
    end
end

local ESPUpdater = RunService.Heartbeat:Connect(function()
    for player, espObject in pairs(ESPObjects) do
        if player and player.Character then
            if espObject.Drawings.Box then espObject.Drawings.Box.Color = ESP.Color end
            if espObject.Drawings.BoxOutline then espObject.Drawings.BoxOutline.Color = ESP.OutlineColor end
            if espObject.Drawings.BoxFill then espObject.Drawings.BoxFill.Color = ESP.FillColor end
            if espObject.Drawings.Name then espObject.Drawings.Name.Color = ESP.TextColor end
            if espObject.Drawings.NameOutline then espObject.Drawings.NameOutline.Color = ESP.TextOutlineColor end
            if espObject.Drawings.Health then espObject.Drawings.Health.Color = ESP.TextColor end
            if espObject.Drawings.HealthOutline then espObject.Drawings.HealthOutline.Color = ESP.TextOutlineColor end
            if espObject.Drawings.Distance then espObject.Drawings.Distance.Color = ESP.TextColor end
            if espObject.Drawings.DistanceOutline then espObject.Drawings.DistanceOutline.Color = ESP.TextOutlineColor end
            if espObject.Drawings.Tracer then espObject.Drawings.Tracer.Color = ESP.TracerColor end
        end
    end
end)

local function ToggleAdvancedESP(state)
    if state then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                RemoveESP(player)
                local conn = player.CharacterAdded:Connect(function(char)
                    CreateESP(player)
                    conn:Disconnect()
                end)
                if player.Character then
                    CreateESP(player)
                end
            end
        end
        
        Players.PlayerAdded:Connect(function(newPlayer)
            local conn = newPlayer.CharacterAdded:Connect(function(char)
                CreateESP(newPlayer)
                conn:Disconnect()
            end)
            if newPlayer.Character then
                CreateESP(newPlayer)
            end
        end)
    else
        for player in pairs(ESPObjects) do
            RemoveESP(player)
        end
    end
end

return {
    ESP = ESP,
    CreateESP = CreateESP,
    RemoveESP = RemoveESP,
    UpdateAllESP = UpdateAllESP,
    ToggleAdvancedESP = ToggleAdvancedESP
}
