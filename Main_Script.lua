-- ESP Updater
local ESPUpdater = RunService.Heartbeat:Connect(function()
    if featureStates.AdvancedESP then
        for player, espObject in pairs(ESPObjects) do
            if player and player.Character then
                -- Update all properties in real-time for all players
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

local function ToggleAdvancedESP(state)
    featureStates.AdvancedESP = state
    if state then
        -- Initialize ESP for all existing players when first enabled
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer and player.Character then
                CreateESP(player)
            end
        end
    else
        for Player in pairs(ESPObjects) do
            RemoveESP(Player)
        end
    end
end

-- Initialize Features
local function initializeFeatures()
    -- Create tabs and sections
    for index, tabData in ipairs(tabs) do
        local tabButton = createTab(tabData, index)
        tabButton.Parent = TabsContainer

        local section = createContentSection(tabData.Name)
        section.Parent = ContentFrame
        contentSections[tabData.Name] = section
    end

    -- Activate first tab
    local firstTab = TabsContainer:FindFirstChild('General')
    if firstTab then
        firstTab.Highlight.Visible = true
        contentSections.General.Visible = true
        currentTab = firstTab
        firstTab.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    end

    -- General Tab
    local generalContainer = contentSections.General.Container

    -- NoClip Toggle
    local noclipToggle, noclipKeybind = createToggle(
        generalContainer,
        'NoClip',
        featureStates.NoClip,
        function(state)
            toggleNoclip(state)
        end,
        true,
        'NoClip'
    )

    -- Visual Tab
    local visualContainer = contentSections.Visual.Container

    -- ESP Toggle
    local espToggle, espKeybind = createToggle(
        visualContainer,
        'Player ESP',
        featureStates.ESP,
        function(state)
            updateESP(state)
        end,
        true,
        'ESP'
    )

    -- Chams Toggle
    local chamsToggle, chamsKeybind = createToggle(
        visualContainer,
        'Team Chams',
        featureStates.Chams,
        function(state)
            updateChams(state)
        end,
        true,
        'Chams'
    )

    -- FullBright Toggle
    local fullbrightToggle, fullbrightKeybind = createToggle(
        visualContainer,
        'Full Bright',
        featureStates.FullBright,
        function(state)
            toggleFullBright(state)
        end,
        true,
        'FullBright'
    )

-- ESP Tab
local espTabContainer = contentSections.ESP.Container

-- Remove automatic vertical layout if it exists
local layout = espTabContainer:FindFirstChildOfClass("UIListLayout")
if layout then
    layout:Destroy()
end

-- Store Y positions for each row
local currentY = 10  -- Starting Y position

-- Advanced ESP Toggle (top of the list)
local espMasterToggle, espMasterKeybind = createToggle(
    espTabContainer,
    'Advanced ESP',
    featureStates.AdvancedESP,
    function(state) 
        featureStates.AdvancedESP = state 
        ToggleAdvancedESP(state)
    end,
    true,
    'AdvancedESP'
)
espMasterToggle.Position = UDim2.new(0, 0, 0, currentY)
currentY = currentY + 40  -- Move down for next element

-- First row of toggles
local boxesToggle, _ = createToggle(
    espTabContainer,
    'Boxes',
    featureStates.ESPBoxes,
    function(state)
        featureStates.ESPBoxes = state
        ESP.Boxes = state
        UpdateAllESP()
    end,
    false,
    'ESPBoxes'
)
boxesToggle.Position = UDim2.new(0, 0, 0, currentY)

local distanceToggle, _ = createToggle(
    espTabContainer,
    'Distance',
    featureStates.ESPDistance,
    function(state)
        featureStates.ESPDistance = state
        ESP.Distance = state
        UpdateAllESP()
    end,
    false,
    'ESPDistance'
)
distanceToggle.Position = UDim2.new(0, 0, 0, currentY + 40)

local healthToggle, _ = createToggle(
    espTabContainer,
    'Health',
    featureStates.ESPHealth,
    function(state)
        featureStates.ESPHealth = state
        ESP.Health = state
        UpdateAllESP()
    end,
    false,
    'ESPHealth'
)
healthToggle.Position = UDim2.new(0, 0, 0, currentY + 80)

local namesToggle, _ = createToggle(
    espTabContainer,
    'Names',
    featureStates.ESPNames,
    function(state)
        featureStates.ESPNames = state
        ESP.Names = state
        UpdateAllESP()
    end,
    false,
    'ESPNames'
)
namesToggle.Position = UDim2.new(0, 0, 0, currentY + 120)

local tracersToggle, _ = createToggle(
    espTabContainer,
    'Tracers',
    featureStates.ESPTracers,
    function(state)
        featureStates.ESPTracers = state
        ESP.Tracers = state
        UpdateAllESP()
    end,
    false,
    'ESPTracers'
)
tracersToggle.Position = UDim2.new(0, 0, 0, currentY + 160)

local outlinesToggle, _ = createToggle(
    espTabContainer,
    'Outlines',
    featureStates.ESPOutlines,
    function(state)
        featureStates.ESPOutlines = state
        ESP.Outlines = state
        UpdateAllESP()
    end,
    false,
    'ESPOutlines'
)
outlinesToggle.Position = UDim2.new(0, 0, 0, currentY + 200)

-- Update currentY for color pickers
currentY = currentY + 240

-- Color Pickers
createColorPicker(espTabContainer, 'Box Color', ESP.Color, function(color)
    ESP.Color = color
end).Position = UDim2.new(0, 0, 0, currentY)

createColorPicker(espTabContainer, 'Outline Color', ESP.OutlineColor, function(color)
    ESP.OutlineColor = color
end).Position = UDim2.new(0, 0, 0, currentY + 40)

createColorPicker(espTabContainer, 'Fill Color', ESP.FillColor, function(color)
    ESP.FillColor = color
end).Position = UDim2.new(0, 0, 0, currentY + 80)

createColorPicker(espTabContainer, 'Text Color', ESP.TextOutlineColor, function(color)
    ESP.TextOutlineColor = color
end).Position = UDim2.new(0, 0, 0, currentY + 120)

createColorPicker(espTabContainer, 'Tracer Color', ESP.TracerColor, function(color)
    ESP.TracerColor = color
end).Position = UDim2.new(0, 0, 0, currentY + 160)

-- Update currentY for sliders
currentY = currentY + 200

-- Sliders
createSlider(
    espTabContainer,
    'Box Width',
    1,
    30,
    ESP.BoxSize.X,
    function(value)
        ESP.BoxSize = Vector3.new(value, ESP.BoxSize.Y, 0)
    end
).Position = UDim2.new(0, 0, 0, currentY)

createSlider(
    espTabContainer,
    'Box Height',
    1,
    30,
    ESP.BoxSize.Y,
    function(value)
        ESP.BoxSize = Vector3.new(ESP.BoxSize.X, value, 0)
    end
).Position = UDim2.new(0, 0, 0, currentY + 40)

createSlider(
    espTabContainer,
    'Box Shift',
    -10,
    10,
    ESP.BoxShift.Y,
    function(value)
        ESP.BoxShift = CFrame.new(0, value, 0)
    end
).Position = UDim2.new(0, 0, 0, currentY + 80)

createSlider(
    espTabContainer,
    'Name Size',
    1,
    100,
    ESP.TextSize,
    function(value)
        ESP.TextSize = value
        UpdateAllESP()
    end
).Position = UDim2.new(0, 0, 0, currentY + 120)

createSlider(
    espTabContainer,
    'Health ESP Size',
    1,
    100,
    ESP.HealthTextSize,
    function(value)
        ESP.HealthTextSize = value
        UpdateAllESP()
    end
).Position = UDim2.new(0, 0, 0, currentY + 160)

createSlider(
    espTabContainer,
    'Distance ESP Size',
    1,
    100,
    ESP.DistanceTextSize,
    function(value)
        ESP.DistanceTextSize = value
        UpdateAllESP()
    end
).Position = UDim2.new(0, 0, 0, currentY + 200)

createSlider(
    espTabContainer,
    'Name Offset',
    -300,
    300,
    ESP.TextOffset.Y,
    function(value)
        ESP.TextOffset = Vector2.new(0, value)
    end
).Position = UDim2.new(0, 0, 0, currentY + 240)

createSlider(
    espTabContainer,
    'Health Offset',
    -300,
    300,
    ESP.HealthTextOffset,
    function(value)
        ESP.HealthTextOffset = value
    end
).Position = UDim2.new(0, 0, 0, currentY + 280)

createSlider(
    espTabContainer,
    'Distance Offset',
    -300,
    300,
    ESP.DistanceTextOffset,
    function(value)
        ESP.DistanceTextOffset = value
    end
).Position = UDim2.new(0, 0, 0, currentY + 320)

createSlider(
    espTabContainer,
    'Tracer Thickness',
    1,
    20,
    ESP.TracerThickness,
    function(value)
        ESP.TracerThickness = value
    end
).Position = UDim2.new(0, 0, 0, currentY + 360)

createSlider(
    espTabContainer,
    'Outline Size',
    1,
    20,
    ESP.OutlineSize,
    function(value)
        ESP.OutlineSize = value
    end
).Position = UDim2.new(0, 0, 0, currentY + 400)

createSlider(
    espTabContainer,
    'Fill Transparency',
    0,
    100,
    ESP.FillTransparency * 101,
    function(value)
        ESP.FillTransparency = value / 101
    end
).Position = UDim2.new(0, 0, 0, currentY + 440)

    -- Keybind Assignment
    local function assignKeybind(keybindButton, featureName)
        keybindButton.MouseButton1Click:Connect(function()
            keybindButton.Text = '...'

            local connection
            connection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    featureKeybinds[featureName] = input.KeyCode
                    keybindButton.Text = input.KeyCode.Name
                    connection:Disconnect()
                    setupMenuToggle()
                elseif
                    input.UserInputType == Enum.UserInputType.MouseButton1
                then
                    featureKeybinds[featureName] = 'MB1'
                    keybindButton.Text = 'MB1'
                    connection:Disconnect()
                    setupMenuToggle()
                elseif
                    input.UserInputType == Enum.UserInputType.MouseButton2
                then
                    featureKeybinds[featureName] = 'MB2'
                    keybindButton.Text = 'MB2'
                    connection:Disconnect()
                    setupMenuToggle()
                elseif
                    input.UserInputType == Enum.UserInputType.MouseButton3
                then
                    featureKeybinds[featureName] = 'MB3'
                    keybindButton.Text = 'MB3'
                    connection:Disconnect()
                    setupMenuToggle()
                end
            end)
        end)
    end

    assignKeybind(noclipKeybind, 'NoClip')
    assignKeybind(espKeybind, 'ESP')
    assignKeybind(chamsKeybind, 'Chams')
    assignKeybind(fullbrightKeybind, 'FullBright')
    assignKeybind(espMasterKeybind, 'AdvancedESP')

    noclipKeybind.Text = '...'
    espKeybind.Text = '...'
    chamsKeybind.Text = '...'
    fullbrightKeybind.Text = '...'
    espMasterKeybind.Text = '...'

    -- Aim Tab
    local aimContainer = contentSections.Aim.Container

    -- Aimbot Toggle
    local aimToggle, aimKeybind = createToggle(
        aimContainer,
        'Aimbot',
        Aim.Enabled,
        function(state)
            Aim.Enabled = state
            if
                toggleComponents['Aimbot'] and toggleComponents['Aimbot'].slider
            then
                local slider = toggleComponents['Aimbot'].slider
                local newPosition = state and UDim2.new(1, -25, 0, 1)
                    or UDim2.new(0, 2, 0, 1)
                slider.Position = newPosition
                slider.BackgroundColor3 = state and Color3.fromRGB(255, 165, 0)
                    or Color3.new(1, 1, 1)
            end
        end,
        true,
        'Aimbot'
    )

    -- Aimbot Keybind
    aimKeybind.MouseButton1Click:Connect(function()
        aimKeybind.Text = '...'
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Aim.CurrentKey = input.KeyCode.Name
                Aim.AimKey = input.KeyCode
                aimKeybind.Text = input.KeyCode.Name
                connection:Disconnect()
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                Aim.CurrentKey = 'MB1'
                Aim.AimKey = input.UserInputType
                aimKeybind.Text = 'MB1'
                connection:Disconnect()
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                Aim.CurrentKey = 'MB2'
                Aim.AimKey = input.UserInputType
                aimKeybind.Text = 'MB2'
                connection:Disconnect()
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                Aim.CurrentKey = 'MB3'
                Aim.AimKey = input.UserInputType
                aimKeybind.Text = 'MB3'
                connection:Disconnect()
            end
        end)
    end)
    aimKeybind.Text = Aim.CurrentKey

    -- Team Check
    createToggle(aimContainer, 'Team Check', featureStates.TeamCheck, function(state)
        featureStates.TeamCheck = state
        Aim.TeamCheck = state
    end, false, 'TeamCheck')

    -- Visibility Check
    createToggle(
        aimContainer,
        'Visibility Check',
        featureStates.VisibilityCheck,
        function(state)
            featureStates.VisibilityCheck = state
            Aim.VisibilityCheck = state
        end,
        false,
        'VisibilityCheck'
    )

    -- Show FOV Toggle
    createToggle(
        aimContainer,
        'Show FOV',
        featureStates.ShowFOV,
        function(state)
            featureStates.ShowFOV = state
            Aim.ShowFOV = state
            FOVCircle.Visible = state
        end,
        false,
        'ShowFOV'
    )

    -- Aim Part Selection
    local partFrame = Instance.new('Frame')
    partFrame.Size = UDim2.new(1, -20, 0, 40)
    partFrame.BackgroundTransparency = 1
    partFrame.Parent = aimContainer

    local headButton = Instance.new('TextButton')
    headButton.Size = UDim2.new(0.45, -5, 0, 30)
    headButton.Position = UDim2.new(0.025, 0, 0, 5)
    headButton.Text = 'Head'
    headButton.TextSize = 14
    headButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    headButton.TextColor3 = Color3.new(1, 1, 1)
    headButton.Font = Enum.Font.Gotham
    headButton.Parent = partFrame

    local headHighlight = Instance.new('Frame')
    headHighlight.Name = 'Highlight'
    headHighlight.Size = UDim2.new(0, 5, 1, 0)
    headHighlight.Position = UDim2.new(1, -165, 0, 0)
    headHighlight.AnchorPoint = Vector2.new(1, 0)
    headHighlight.BackgroundColor3 = Aim.AimPart == 'Head'
            and Color3.fromRGB(255, 165, 0)
        or Color3.fromRGB(60, 60, 60)
    headHighlight.BorderSizePixel = 0
    headHighlight.ZIndex = 2
    headHighlight.Parent = headButton

    local torsoButton = Instance.new('TextButton')
    torsoButton.Size = UDim2.new(0.45, -5, 0, 30)
    torsoButton.Position = UDim2.new(0.525, 0, 0, 5)
    torsoButton.Text = 'Torso'
    torsoButton.TextSize = 14
    torsoButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    torsoButton.TextColor3 = Color3.new(1, 1, 1)
    torsoButton.Font = Enum.Font.Gotham
    torsoButton.Parent = partFrame

    local torsoHighlight = Instance.new('Frame')
    torsoHighlight.Name = 'Highlight'
    torsoHighlight.Size = UDim2.new(0, 5, 1, 0)
    torsoHighlight.Position = UDim2.new(1, -165, 0, 0)
    torsoHighlight.AnchorPoint = Vector2.new(1, 0)
    torsoHighlight.BackgroundColor3 = Aim.AimPart == 'Torso'
            and Color3.fromRGB(255, 165, 0)
        or Color3.fromRGB(60, 60, 60)
    torsoHighlight.BorderSizePixel = 0
    torsoHighlight.ZIndex = 2
    torsoHighlight.Parent = torsoButton

    local buttonCorner = Instance.new('UICorner')
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = headButton

    local buttonCorner2 = Instance.new('UICorner')
    buttonCorner2.CornerRadius = UDim.new(0, 4)
    buttonCorner2.Parent = torsoButton

    headButton.MouseButton1Click:Connect(function()
        Aim.AimPart = 'Head'
        headHighlight.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        torsoHighlight.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)

    torsoButton.MouseButton1Click:Connect(function()
        Aim.AimPart = 'Torso'
        torsoHighlight.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        headHighlight.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)

    -- FOV Controls
    createSlider(
        aimContainer,
        'FOV Radius',
        10,
        500,
        Aim.FOV,
        function(value)
            Aim.FOV = value
            FOVCircle.Radius = value
        end
    )

    -- Settings Tab
    local settingsContainer = contentSections.Settings.Container

    -- Menu Toggle Keybind
    local menuToggleFrame = Instance.new('Frame')
    menuToggleFrame.Size = UDim2.new(1, -20, 0, 30)
    menuToggleFrame.BackgroundTransparency = 1
    menuToggleFrame.Parent = settingsContainer

    local menuToggleLabel = Instance.new('TextLabel')
    menuToggleLabel.Text = 'Menu Toggle Key'
    menuToggleLabel.Font = Enum.Font.Gotham
    menuToggleLabel.TextColor3 = Color3.new(1, 1, 1)
    menuToggleLabel.TextSize = 14
    menuToggleLabel.Size = UDim2.new(0.6, 0, 1, 0)
    menuToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    menuToggleLabel.BackgroundTransparency = 1
    menuToggleLabel.Parent = menuToggleFrame

    local menuToggleButton = Instance.new('TextButton')
    menuToggleButton.Size = UDim2.new(0, 100, 0, 25)
    menuToggleButton.Position = UDim2.new(0.75, 0, 0, 2.5)
    menuToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    menuToggleButton.Text = featureKeybinds.Menu.Name
    menuToggleButton.TextColor3 = Color3.new(1, 1, 1)
    menuToggleButton.TextSize = 12
    menuToggleButton.Font = Enum.Font.Gotham
    menuToggleButton.Parent = menuToggleFrame

    local menuToggleCorner = Instance.new('UICorner')
    menuToggleCorner.CornerRadius = UDim.new(0, 4)
    menuToggleCorner.Parent = menuToggleButton

    menuToggleButton.MouseButton1Click:Connect(function()
        menuToggleButton.Text = '...'
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                featureKeybinds.Menu = input.KeyCode
                menuToggleButton.Text = input.KeyCode.Name
                connection:Disconnect()
                setupMenuToggle()
            end
        end)
    end)
end

-- Player Handling
local function handlePlayer(player)
    player.CharacterAdded:Connect(function()
        if featureStates.ESP then
            createESP(player)
        end
        if featureStates.Chams then
            createChams(player)
        end
        if featureStates.AdvancedESP then
            CreateESP(player)
        end
    end)

    if player.Character then
        if featureStates.ESP then
            createESP(player)
        end
        if featureStates.Chams then
            createChams(player)
        end
        if featureStates.AdvancedESP then
            CreateESP(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    handlePlayer(player)
    if featureStates.AdvancedESP then
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if activeESP[player] then
        activeESP[player]:Destroy()
    end
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
    end
    if espConnections[player] then
        espConnections[player]:Disconnect()
    end
    if chamsConnections[player] then
        chamsConnections[player]:Disconnect()
    end
    RemoveESP(player)
end)

-- Initialize ESP for all existing players immediately
for _, player in ipairs(Players:GetPlayers()) do
    handlePlayer(player)
    if featureStates.AdvancedESP then
        CreateESP(player)
    end
end

-- Get closest player for aimbot
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Aim.FOV
    
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

-- Setup menu toggle key
setupMenuToggle()

-- Initialize features after GUI creation
initializeFeatures()

-- Initialize FullBright to off
_G.FullBrightEnabled = false
toggleFullBright(false)

-- Menu persistence through respawns
player.CharacterAdded:Connect(function()
    task.wait(1)
    if not player.PlayerGui:FindFirstChild('KIBHook') then
        ScreenGui:Clone().Parent = player.PlayerGui
    end
end)

-- Show injection notification
local function showInjectionNotification()
    local notification = Instance.new('ScreenGui')
    notification.Name = 'InjectionNotification'
    notification.Parent = gui
    notification.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mainFrame = Instance.new('Frame')
    mainFrame.Size = UDim2.new(0, 400, 0, 120)
    mainFrame.Position = UDim2.new(0.5, -200, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    mainFrame.BackgroundTransparency = 0.5
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = notification

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local title = Instance.new('TextLabel')
    title.Text = 'IB Hook'
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Parent = mainFrame

    local title = Instance.new('TextLabel')
    title.Text = 'K'
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 165, 0)
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.Position = UDim2.new(0, -38, 0, 5)
    title.BackgroundTransparency = 1
    title.Parent = mainFrame

    local hint = Instance.new('TextLabel')
    hint.Text = 'Press ' .. featureKeybinds.Menu.Name .. ' to open menu'
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 14
    hint.TextColor3 = Color3.fromRGB(255, 255, 255)
    hint.Size = UDim2.new(1, 0, 0.5, 0)
    hint.Position = UDim2.new(0, -8, 0.5, -5)
    hint.BackgroundTransparency = 1
    hint.Parent = mainFrame

    delay(6, function()
        game
            :GetService('TweenService')
            :Create(mainFrame, TweenInfo.new(0.5), {
                BackgroundTransparency = 1,
            })
            :Play()
        wait(0.5)
        notification:Destroy()
    end)
end

showInjectionNotification()
