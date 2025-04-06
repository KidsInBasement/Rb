local Aim = {
    Enabled = false,
    Active = false,
    TeamCheck = true,
    VisibilityCheck = true,
    AimPart = 'Head',
    FOV = 80,
    ShowFOV = true,
    CurrentKey = 'None',
    AimKey = nil,
    KeybindListening = false,
}

local FOVCircle = Drawing.new('Circle')
FOVCircle.Visible = false
FOVCircle.Radius = Aim.FOV
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.Transparency = 1
FOVCircle.Filled = false
FOVCircle.NumSides = 64

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

return {
    Aim = Aim,
    FOVCircle = FOVCircle
}
