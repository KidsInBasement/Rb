-- AIM Module for KIB Hook
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Camera = workspace.CurrentCamera

-- Aim System Configuration
local Aim = {
    Enabled = false,
    Active = false,
    TeamCheck = true, -- This will be passed from the main script or configured here
    VisibilityCheck = true, -- This will be passed from the main script or configured here
    AimPart = 'Head',
    FOV = 80,
    ShowFOV = true, -- This will be passed from the main script or configured here
    CurrentKey = 'None',
    AimKey = nil,
    KeybindListening = false,
}

-- FOV Circle Drawing
local FOVCircle = Drawing.new('Circle')
FOVCircle.Visible = false
FOVCircle.Radius = Aim.FOV
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.Transparency = 1
FOVCircle.Filled = false
FOVCircle.NumSides = 64

-- Function to get the closest player within FOV
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Aim.FOV
    local player = Players.LocalPlayer -- Assuming LocalPlayer is accessible or passed

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            -- Team check
            if Aim.TeamCheck and v.Team and player.Team and v.Team == player.Team then 
                continue 
            end
            
            local targetPart = v.Character:FindFirstChild(Aim.AimPart)
            if not targetPart then continue end
            
            local screenPos = Camera:WorldToScreenPoint(targetPart.Position)
            if screenPos.Z > 0 then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                
                -- Only proceed if distance is within FOV
                if distance < shortestDistance then
                    -- Visibility check
                    if Aim.VisibilityCheck then
                        -- Cast a ray from camera to target
                        local raycastParams = RaycastParams.new()
                        raycastParams.FilterDescendantsInstances = {player.Character, v.Character}
                        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                        
                        local rayOrigin = Camera.CFrame.Position
                        local rayDirection = (targetPart.Position - rayOrigin).Unit * (rayOrigin - targetPart.Position).Magnitude
                        local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                        
                        -- If ray hits nothing or hits the target player, then visible
                        if not raycastResult or raycastResult.Instance:IsDescendantOf(v.Character) then
                            closestPlayer = v
                            shortestDistance = distance
                        end
                    else
                        -- No visibility check needed
                        closestPlayer = v
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Aim Loop
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = Aim.FOV
    FOVCircle.Visible = Aim.ShowFOV and Aim.Enabled
    
    local keyPressed = false
    if Aim.AimKey then
        -- Handle mouse buttons first
        if Aim.CurrentKey == "MB1" then
            keyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        elseif Aim.CurrentKey == "MB2" then
            keyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        elseif Aim.CurrentKey == "MB3" then
            keyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
        else
            -- Handle keyboard keys
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

-- Return the Aim table and FOVCircle for external control
return {
    Aim = Aim,
    FOVCircle = FOVCircle
}
