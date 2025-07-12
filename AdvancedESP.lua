-- Advanced ESP Module
local ESPObjects = {}
local featureStates, player, Camera, RunService, Players, Drawing, ESP
local ESPUpdater

return {
    init = function(states, plr, cam, run, players, draw, settings)
        featureStates = states
        player = plr
        Camera = cam
        RunService = run
        Players = players
        Drawing = draw
        ESP = settings
    end,

    create = function(target)
        if ESPObjects[target] then return end

        local ESPObject = {
            Player = target,
            Drawings = {},
            Connections = {},
        }
        
        local function UpdateESP()
            if
                not target.Character
                or not target.Character:FindFirstChild('Humanoid')
                or not target.Character:FindFirstChild('HumanoidRootPart')
            then
                return
            end

            local RootPart = target.Character.HumanoidRootPart
            local Head = target.Character:FindFirstChild('Head')
            local Humanoid = target.Character.Humanoid

            -- Calculate positions and visibility
            local RootPos, RootVis = Camera:WorldToViewportPoint(RootPart.Position)
            local HeadPos = Head and Camera:WorldToViewportPoint(Head.Position)
                or RootPos

            -- Only show ESP if player is visible on screen
            local isVisible = RootVis
            if not isVisible then
                -- Hide all ESP elements if player is not visible
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

            -- Box
            if ESP.Boxes and featureStates.ESPBoxes then
                -- Get camera vectors for proper facing
                local cameraCFrame = Camera.CFrame
                local rightVector = cameraCFrame.RightVector
                local upVector = cameraCFrame.UpVector
                
                -- Calculate box corners facing the camera (using fixed size)
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
                    ESPObject.Drawings.BoxOutline.Visible = featureStates.ESPOutlines and featureStates.ESPBoxes and isVisible
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
                ESPObject.Drawings.Name.Text = target.Name
                ESPObject.Drawings.Name.Position = NamePosition
                ESPObject.Drawings.Name.Visible = featureStates.ESPNames and isVisible

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

                    ESPObject.Drawings.NameOutline.Text = target.Name
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
                ESPObject.Drawings.Health.Visible = featureStates.ESPHealth and isVisible

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
                ESPObject.Drawings.Distance.Visible = featureStates.ESPDistance and isVisible

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
                ESPObject.Drawings.Tracer.Visible = featureStates.ESPTracers and isVisible
            else
                if ESPObject.Drawings.Tracer then
                    ESPObject.Drawings.Tracer.Visible = false
                end
            end
        end

        local RootPart = target.Character.HumanoidRootPart
        local Head = target.Character:FindFirstChild('Head')
        local Humanoid = target.Character.Humanoid

            local function ClearESP()
            for _, DrawingObject in pairs(ESPObject.Drawings) do
                DrawingObject.Visible = false
                DrawingObject:Remove()
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

            ESPObject.Connections.RenderStepped = RunService.RenderStepped:Connect(
                UpdateESP
            )
        end

        if target.Character then
            CharacterAdded(target.Character)
        end

        ESPObject.Connections.CharacterAdded = target.CharacterAdded:Connect(
            CharacterAdded
        )
        ESPObjects[target] = ESPObject
    end,

    remove = function(target)
        if not ESPObjects[target] then return end
        
        -- Clean up all drawings
        for _, drawing in pairs(ESPObjects[target].Drawings) do
            if drawing and drawing.Remove then
                drawing.Visible = false
                drawing:Remove()
            end
        end
        
        -- Disconnect all connections
        for _, connection in pairs(ESPObjects[target].Connections) do
            if connection then
                connection:Disconnect()
            end
        end
        
        ESPObjects[target] = nil
    end,

    updateAll = function()
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= player and (not ESP.TeamCheck or Player.Team ~= player.Team) then
                if featureStates.AdvancedESP then
                    -- Update properties in real-time
                    local espObj = ESPObjects[Player]
                    if espObj then
                        if espObj.Drawings.Box then
                            espObj.Drawings.Box.Color = ESP.Color
                        end
                        if espObj.Drawings.BoxOutline then
                            espObj.Drawings.BoxOutline.Color = ESP.OutlineColor
                            espObj.Drawings.BoxOutline.Thickness = ESP.OutlineSize
                        end
                        if espObj.Drawings.BoxFill then
                            espObj.Drawings.BoxFill.Color = ESP.FillColor
                            espObj.Drawings.BoxFill.Transparency = ESP.FillTransparency
                        end
                        if espObj.Drawings.Name then
                            espObj.Drawings.Name.Color = ESP.TextColor
                            espObj.Drawings.Name.Size = ESP.TextSize
                        end
                        if espObj.Drawings.NameOutline then
                            espObj.Drawings.NameOutline.Color = ESP.TextOutlineColor
                            espObj.Drawings.NameOutline.Size = ESP.TextSize
                        end
                        if espObj.Drawings.Health then
                            espObj.Drawings.Health.Color = ESP.TextColor
                            espObj.Drawings.Health.Size = ESP.HealthTextSize
                        end
                        if espObj.Drawings.HealthOutline then
                            espObj.Drawings.HealthOutline.Color = ESP.TextOutlineColor
                            espObj.Drawings.HealthOutline.Size = ESP.HealthTextSize
                        end
                        if espObj.Drawings.Distance then
                            espObj.Drawings.Distance.Color = ESP.TextColor
                            espObj.Drawings.Distance.Size = ESP.DistanceTextSize
                        end
                        if espObj.Drawings.DistanceOutline then
                            espObj.Drawings.DistanceOutline.Color = ESP.TextOutlineColor
                            espObj.Drawings.DistanceOutline.Size = ESP.DistanceTextSize
                        end
                        if espObj.Drawings.Tracer then
                            espObj.Drawings.Tracer.Color = ESP.TracerColor
                            espObj.Drawings.Tracer.Thickness = ESP.TracerThickness
                        end
                    end
                end
            end
        end
    end,

    toggle = function(state)
        featureStates.AdvancedESP = state
        if state then
            -- Initialize ESP for all existing players
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer and player.Character then
                    ESPObjects[player] = nil
                    create(player)
                end
            end
            
            -- Start updater
            if not ESPUpdater then
                ESPUpdater = RunService.Heartbeat:Connect(updateAll)
            end
        else
            for target in pairs(ESPObjects) do
                remove(target)
            end
            if ESPUpdater then
                ESPUpdater:Disconnect()
                ESPUpdater = nil
            end
        end
    end
}
