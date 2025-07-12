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
            if not target.Character then return end
            
            local humanoid = target.Character:FindFirstChild("Humanoid")
            local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
            local head = target.Character:FindFirstChild("Head")
            
            if not humanoid or not rootPart or not head then return end
            
            -- Calculate positions and visibility
            local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if not onScreen then return end

            -- Update all properties in real-time
            if ESPObject.Drawings.Box then
                ESPObject.Drawings.Box.Color = ESP.Color
                ESPObject.Drawings.Box.Visible = featureStates.ESPBoxes
            end
            
            if ESPObject.Drawings.BoxOutline then
                ESPObject.Drawings.BoxOutline.Color = ESP.OutlineColor
                ESPObject.Drawings.BoxOutline.Thickness = ESP.OutlineSize
                ESPObject.Drawings.BoxOutline.Visible = featureStates.ESPOutlines and featureStates.ESPBoxes
            end
            
            -- ... [similar updates for all other ESP elements] ...
            
            -- Position calculations
            local cameraCFrame = Camera.CFrame
            local rightVector = cameraCFrame.RightVector
            local upVector = cameraCFrame.UpVector
            
            local centerPos = (rootPart.CFrame * ESP.BoxShift).Position
            local topRight = Camera:WorldToViewportPoint(centerPos + (rightVector * ESP.BoxSize.X/2) + (upVector * ESP.BoxSize.Y/2))
            local bottomLeft = Camera:WorldToViewportPoint(centerPos - (rightVector * ESP.BoxSize.X/2) - (upVector * ESP.BoxSize.Y/2))
            
            local size = Vector2.new(
                math.abs(topRight.X - bottomLeft.X),
                math.abs(topRight.Y - bottomLeft.Y)
            )
            local position = Vector2.new(
                math.min(topRight.X, bottomLeft.X),
                math.min(topRight.Y, bottomLeft.Y)
            )

            -- Update positions
            if ESPObject.Drawings.Box then
                ESPObject.Drawings.Box.Size = size
                ESPObject.Drawings.Box.Position = position
            end
            
            -- ... [similar position updates for other elements] ...
        end

        local function ClearESP()
            for _, drawing in pairs(ESPObject.Drawings) do
                if drawing and drawing.Remove then
                    drawing:Remove()
                end
            end
            ESPObject.Drawings = {}
            
            for _, conn in pairs(ESPObject.Connections) do
                conn:Disconnect()
            end
        end

        local function CharacterAdded(character)
            -- Clear previous ESP
            ClearESP()
            
            -- Wait for character to fully load
            repeat task.wait() until character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart")
            
            -- Create new drawings
            ESPObject.Drawings.Box = Drawing.new("Square")
            ESPObject.Drawings.BoxOutline = Drawing.new("Square")
            -- ... [create other drawings] ...
            
            -- Setup render connection
            ESPObject.Connections.Render = RunService.RenderStepped:Connect(UpdateESP)
        end

        -- Initial setup
        if target.Character then
            CharacterAdded(target.Character)
        end
        
        -- Connect character events
        ESPObject.Connections.CharacterAdded = target.CharacterAdded:Connect(CharacterAdded)
        ESPObject.Connections.CharacterRemoving = target.CharacterRemoving:Connect(ClearESP)
        
        ESPObjects[target] = ESPObject
    end,

    remove = function(target)
        if not ESPObjects[target] then return end
        local espObj = ESPObjects[target]
        
        -- Clean up drawings
        for _, drawing in pairs(espObj.Drawings) do
            if drawing and drawing.Remove then
                drawing:Remove()
            end
        end
        
        -- Disconnect events
        for _, conn in pairs(espObj.Connections) do
            conn:Disconnect()
        end
        
        ESPObjects[target] = nil
    end,

    updateAll = function()
        for player, espObj in pairs(ESPObjects) do
            -- Update properties immediately
            if espObj.Drawings.Box then
                espObj.Drawings.Box.Color = ESP.Color
                espObj.Drawings.Box.Visible = featureStates.ESPBoxes
            end
            
            if espObj.Drawings.BoxOutline then
                espObj.Drawings.BoxOutline.Color = ESP.OutlineColor
                espObj.Drawings.BoxOutline.Thickness = ESP.OutlineSize
                espObj.Drawings.BoxOutline.Visible = featureStates.ESPOutlines and featureStates.ESPBoxes
            end
            
            -- ... [update all other properties] ...
        end
    end,

    toggle = function(state)
        featureStates.AdvancedESP = state
        
        if state then
            -- Initialize ESP for all existing players
            for _, target in ipairs(Players:GetPlayers()) do
                if target ~= player then
                    self.create(target)
                end
            end
            
            -- Start continuous updater
            if not ESPUpdater then
                ESPUpdater = RunService.Heartbeat:Connect(function()
                    for _, espObj in pairs(ESPObjects) do
                        if espObj.Update then
                            espObj.Update()
                        end
                    end
                end)
            end
        else
            -- Clean up
            for target in pairs(ESPObjects) do
                self.remove(target)
            end
            
            if ESPUpdater then
                ESPUpdater:Disconnect()
                ESPUpdater = nil
            end
        end
    end
}
