-- KIB Hook - Enhanced Version with Fully Fixed ESP
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Teams = game:GetService('Teams')
local TweenService = game:GetService('TweenService')
local player = Players.LocalPlayer
local gui = player:WaitForChild('PlayerGui')
local Camera = workspace.CurrentCamera
local currentColorPicker = nil
local colorPickerConnection = nil

-- Configuration
local NAME_TEXT_SIZE = 18
local NAME_Y_OFFSET = 3
local NO_TEAM_COLOR = Color3.fromRGB(255, 255, 0)
local COLOR_BOOST = 0.3
local TEXT_STROKE_COLOR = Color3.new(0, 0, 0)

-- Tracking
local activeESP = {}
local activeHighlights = {}
local noclipConnection
local espConnections = {}
local chamsConnections = {}

-- Feature States
local featureStates = {
    NoClip = false,
    ESP = false,
    Chams = false,
    FullBright = false,
    AdvancedESP = false,

    -- Add ESP feature states
    ESPBoxes = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPNames = true,
    ESPTracers = true,
    ESPOutlines = true,
    
    -- Aim feature states (these will be set by the loaded Aim script)
    ShowFOV = true,
    TeamCheck = true,
    VisibilityCheck = true
}

-- Feature Keybinds
local featureKeybinds = {
    NoClip = nil,
    ESP = nil,
    Chams = nil,
    FullBright = nil,
    AdvancedESP = nil,
    Menu = Enum.KeyCode.F2,
    Aimbot = nil, -- Add Aimbot keybind here
}

-- Store toggle components
local toggleComponents = {
    NoClip = { slider = nil, callback = nil },
    ESP = { slider = nil, callback = nil },
    Chams = { slider = nil, callback = nil },
    FullBright = { slider = nil, callback = nil },
    AdvancedESP = { slider = nil, callback = nil },
    ShowFOV = { slider = nil, callback = nil },
    TeamCheck = { slider = nil, callback = nil },
    VisibilityCheck = { slider = nil, callback = nil },
    Aimbot = { slider = nil, callback = nil } -- Add Aimbot toggle component
}

-- Load External Scripts
local HttpService = game:GetService('HttpService')

-- AIM Script (External)
local aimModule
local AIM_SCRIPT_URL = "https://raw.githubusercontent.com/KidsInBasement/Rb/refs/heads/main/aim_script.lua" -- <--- REPLACE THIS
pcall(function()
    local aimCode = HttpService:HttpGet(AIM_SCRIPT_URL, true)
    if aimCode then
        aimModule = loadstring(aimCode)()
        -- Initialize Aim settings from the loaded module
        if aimModule and aimModule.Aim then
            for k, v in pairs(aimModule.Aim) do
                Aim[k] = v -- Copy settings from module's Aim table
            end
            FOVCircle = aimModule.FOVCircle -- Assign the FOVCircle from the module
        end
    else
        warn("Failed to load AIM script from " .. AIM_SCRIPT_URL)
    end
end)

-- Advanced ESP Script (External)
local advancedEspModule
local ADVANCED_ESP_SCRIPT_URL = "https://raw.githubusercontent.com/KidsInBasement/Rb/refs/heads/main/advanced_esp_script.lua" -- <--- REPLACE THIS
pcall(function()
    local advancedEspCode = HttpService:HttpGet(ADVANCED_ESP_SCRIPT_URL, true)
    if advancedEspCode then
        advancedEspModule = loadstring(advancedEspCode)()
        -- Initialize ESP settings from the loaded module
        if advancedEspModule and advancedEspModule.ESP then
            for k, v in pairs(advancedEspModule.ESP) do
                ESP[k] = v -- Copy settings from module's ESP table
            end
            if advancedEspModule.SetFeatureStates then
                advancedEspModule.SetFeatureStates(featureStates) -- Pass featureStates
            end
        end
    else
        warn("Failed to load Advanced ESP script from " .. ADVANCED_ESP_SCRIPT_URL)
    end
end)

-- Ensure Aim and ESP tables exist even if external scripts fail to load
local Aim = Aim or {
    Enabled = false, Active = false, TeamCheck = true, VisibilityCheck = true,
    AimPart = 'Head', FOV = 80, ShowFOV = true, CurrentKey = 'None', AimKey = nil, KeybindListening = false,
}

local ESP = ESP or {
    Enabled = false, TeamCheck = true, Boxes = true, BoxShift = CFrame.new(0, 0, 0),
    BoxSize = Vector3.new(4, 6, 0), Color = Color3.fromRGB(255, 165, 0), FaceCamera = false,
    Names = true, Health = true, HealthTextSize = 19, HealthTextOffset = 40, Distance = true,
    DistanceTextSize = 17, DistanceTextOffset = 21, Tracers = true,
    TracerFrom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 1),
    TracerColor = Color3.fromRGB(255, 165, 0), TracerThickness = 1, TracerTransparency = 1,
    Outlines = true, OutlineColor = Color3.new(0, 0, 0), OutlineSize = 1, FillColor = Color3.fromRGB(0, 0, 0),
    FillTransparency = 0.5, TextSize = 16, TextFont = Drawing.Fonts.UI, TextColor = Color3.fromRGB(255, 165, 0),
    TextOutline = true, TextOutlineColor = Color3.fromRGB(255, 165, 0), TextOffset = Vector2.new(0, 0),
}

local FOVCircle = FOVCircle or Drawing.new('Circle') -- Define if not loaded by Aim module

-- Handle toggle with slider animation
local function handleToggleWithSlider(featureName, state)
    featureStates[featureName] = state

    if
        toggleComponents[featureName] and toggleComponents[featureName].slider
    then
        local slider = toggleComponents[featureName].slider
        local newPosition = state and UDim2.new(1, -25, 0, 1)
            or UDim2.new(0, 2, 0, 1)
        TweenService
            :Create(
                slider,
                TweenInfo.new(
                    0.15,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ),
                {
                    Position = newPosition,
                    BackgroundColor3 = state and Color3.fromRGB(255, 165, 0)
                        or Color3.new(1, 1, 1),
                }
            )
            :Play()
    end

    if
        toggleComponents[featureName] and toggleComponents[featureName].callback
    then
        toggleComponents[featureName].callback(state)
    end
end

-- Create GUI (rest of your GUI creation logic remains the same)
local ScreenGui = Instance.new('ScreenGui')
ScreenGui.ResetOnSpawn = false
ScreenGui.Name = 'KIBHook'
ScreenGui.Parent = gui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Container
local MainFrame = Instance.new('Frame')
MainFrame.Name = 'Main'
MainFrame.Parent = ScreenGui
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 600, 0, 400)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false

local mainCorner = Instance.new('UICorner')
mainCorner.CornerRadius = UDim.new(0, 6)
mainCorner.Parent = MainFrame

-- Left Tabs Column
local LeftTabs = Instance.new('Frame')
LeftTabs.Name = 'LeftTabs'
LeftTabs.Parent = MainFrame
LeftTabs.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
LeftTabs.BackgroundTransparency = 0.98
LeftTabs.Size = UDim2.new(0, 150, 1, 0)

local tabsCorner = Instance.new('UICorner')
tabsCorner.CornerRadius = UDim.new(0, 6)
tabsCorner.Parent = LeftTabs

-- Header
local Header = Instance.new('Frame')
Header.Name = 'Header'
Header.Parent = LeftTabs
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, -15, 0, 40)
Header.Position = UDim2.new(0, 15, 0, 10)

local nLabel = Instance.new('TextLabel')
nLabel.Size = UDim2.new(0, 18, 0, 20)
nLabel.Position = UDim2.new(0, 4.5, 0, 10)
nLabel.Font = Enum.Font.GothamBold
nLabel.Text = 'K'
nLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
nLabel.TextSize = 18
nLabel.BackgroundTransparency = 1
nLabel.TextXAlignment = Enum.TextXAlignment.Left
nLabel.Parent = Header

local restLabel = Instance.new('TextLabel')
restLabel.Size = UDim2.new(1, -18, 1, 0)
restLabel.Position = UDim2.new(0, 16, 0, 0)
restLabel.Font = Enum.Font.GothamBold
restLabel.Text = 'IB Hook'
restLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
restLabel.TextSize = 18
restLabel.TextXAlignment = Enum.TextXAlignment.Left
restLabel.BackgroundTransparency = 1
restLabel.Parent = Header

-- Version Text
local versionText = Instance.new('TextLabel')
versionText.Name = 'Version'
versionText.Parent = LeftTabs
versionText.BackgroundTransparency = 1
versionText.Position = UDim2.new(0, 15, 1, -25)
versionText.Font = Enum.Font.Gotham
versionText.Text = 'V1.29 Not So Stable'
versionText.TextColor3 = Color3.fromRGB(100, 100, 100)
versionText.TextSize = 12
versionText.TextXAlignment = Enum.TextXAlignment.Left

local creatorText = Instance.new('TextLabel')
creatorText.Name = 'Creator'
creatorText.Parent = LeftTabs
creatorText.BackgroundTransparency = 1
creatorText.Position = UDim2.new(0, 15, 1, -12)
creatorText.Font = Enum.Font.Gotham
creatorText.Text = 'By KidsInBasement'
creatorText.TextColor3 = Color3.fromRGB(100, 100, 100)
creatorText.TextSize = 12
creatorText.TextXAlignment = Enum.TextXAlignment.Left

-- Tabs Container
local TabsContainer = Instance.new('Frame')
TabsContainer.Name = 'TabsContainer'
TabsContainer.Parent = LeftTabs
TabsContainer.BackgroundTransparency = 1
TabsContainer.Position = UDim2.new(0, 0, 0, 60)
TabsContainer.Size = UDim2.new(1, 0, 1, -85)

local TabList = Instance.new('UIListLayout')
TabList.Parent = TabsContainer
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabList.Padding = UDim.new(0, 8)
TabList.SortOrder = Enum.SortOrder.LayoutOrder

-- Content Area
local ContentFrame = Instance.new('Frame')
ContentFrame.Name = 'Content'
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 157, 0, 15)
ContentFrame.Size = UDim2.new(1, -170, 1, -30)

-- Tab Configuration
local tabs = {
    { Name = 'General', Icon = '' },
    { Name = 'Visual', Icon = '' },
    { Name = 'ESP', Icon = '' },
    { Name = 'Aim', Icon = '' },
    { Name = 'Settings', Icon = '' },
}

local contentSections = {}
local currentTab = nil

-- Create Tab
local function createTab(tabData, index)
    local tabButton = Instance.new('TextButton')
    tabButton.Name = tabData.Name
    tabButton.Size = UDim2.new(0.9, 0, 0, 40)
    tabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tabButton.Font = Enum.Font.GothamBold
    tabButton.Text = tabData.Name
    tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabButton.TextSize = 14
    tabButton.TextXAlignment = Enum.TextXAlignment.Left
    tabButton.LayoutOrder = index
    tabButton.ClipsDescendants = false

    local textPadding = Instance.new('UIPadding')
    textPadding.PaddingLeft = UDim.new(0, 16)
    textPadding.Parent = tabButton

    local highlight = Instance.new('Frame')
    highlight.Name = 'Highlight'
    highlight.Size = UDim2.new(0, 5, 1, 0)
    highlight.Position = UDim2.new(0, -18, 0, 0)
    highlight.AnchorPoint = Vector2.new(0, 0)
    highlight.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    highlight.BorderSizePixel = 0
    highlight.Visible = false
    highlight.ZIndex = 2
    highlight.Parent = tabButton

    local buttonCorner = Instance.new('UICorner')
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = tabButton

    tabButton.MouseButton1Click:Connect(function()
        for _, tab in pairs(TabsContainer:GetChildren()) do
            if tab:IsA('TextButton') then
                tab.Highlight.Visible = false
                tab.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            end
        end

        for _, section in pairs(contentSections) do
            section.Visible = false
        end

        highlight.Visible = true
        contentSections[tabData.Name].Visible = true
        tabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        currentTab = tabButton
    end)

    return tabButton
end

-- Create Content Section
local function createContentSection(name)
    local section = Instance.new('Frame')
    section.Name = name
    section.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    section.BackgroundTransparency = 0.1
    section.Size = UDim2.new(1, 0, 1, 0)
    section.Visible = false

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = section

    local header = Instance.new('TextLabel')
    header.Text = '  ' .. name
    header.Font = Enum.Font.GothamBold
    header.TextColor3 = Color3.fromRGB(255, 165, 0)
    header.TextSize = 16
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundTransparency = 1
    header.Parent = section

    -- Create a ScrollingFrame instead of regular Frame
    local scrollFrame = Instance.new('ScrollingFrame')
    scrollFrame.Name = 'Container'
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Size = UDim2.new(1, -20, 1, -40)
    scrollFrame.Position = UDim2.new(0, 10, 0, 35)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 1000) -- Adjust as needed
    scrollFrame.ScrollBarThickness = 5
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    scrollFrame.Parent = section

    local layout = Instance.new('UIListLayout')
    layout.Padding = UDim.new(0, 10)
    layout.Parent = scrollFrame

    -- Update canvas size when layout changes
    layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    return section
end

-- Create Toggle
local function createToggle(
    parent,
    labelText,
    initialState,
    callback,
    hasBind,
    featureName
)
    local toggleFrame = Instance.new('Frame')
    toggleFrame.Name = labelText
    toggleFrame.Size = UDim2.new(1, -20, 0, 30)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = parent

    -- Label
    local label = Instance.new('TextLabel')
    label.Text = labelText
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = toggleFrame

    -- Keybind Button
    local keybindButton
    if hasBind then
        keybindButton = Instance.new('TextButton')
        keybindButton.Size = UDim2.new(0, 50, 0, 20)
        keybindButton.Position = UDim2.new(0.7, 10, 0.5, -10)
        keybindButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        keybindButton.Text = 'Bind'
        keybindButton.TextColor3 = Color3.new(1, 1, 1)
        keybindButton.TextSize = 12
        keybindButton.Font = Enum.Font.Gotham
        keybindButton.AutoButtonColor = false
        keybindButton.Parent = toggleFrame

        local keybindCorner = Instance.new('UICorner')
        keybindCorner.CornerRadius = UDim.new(0, 4)
        keybindCorner.Parent = keybindButton
    end

    -- Toggle Button
    local toggleButton = Instance.new('TextButton')
    toggleButton.Size = UDim2.new(0, 50, 0, 25)
    toggleButton.Position = UDim2.new(1, -55, 0.5, -12)
    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleButton.AutoButtonColor = false
    toggleButton.Text = ''
    toggleButton.Parent = toggleFrame

    local slider = Instance.new('Frame')
    slider.Name = 'Slider'
    slider.Size = UDim2.new(0, 23, 0, 23)
    slider.Position = initialState and UDim2.new(1, -25, 0, 1)
        or UDim2.new(0, 2, 0, 1)
    slider.BackgroundColor3 = initialState and Color3.fromRGB(255, 165, 0)
        or Color3.new(1, 1, 1)
    slider.Parent = toggleButton

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = toggleButton

    local sliderCorner = Instance.new('UICorner')
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = slider

    -- Store components
    if featureName then
        toggleComponents[featureName] = {
            slider = slider,
            callback = callback,
        }
    end

    toggleButton.MouseButton1Click:Connect(function()
        handleToggleWithSlider(featureName, not featureStates[featureName])
    end)

    return toggleFrame, keybindButton
end

-- Create Slider
local function createSlider(
    parent,
    labelText,
    minValue,
    maxValue,
    initialValue,
    callback
)
    local sliderFrame = Instance.new('Frame')
    sliderFrame.Size = UDim2.new(1, -20, 0, 40)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = parent

    -- Label
    local label = Instance.new('TextLabel')
    label.Text = labelText
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.Size = UDim2.new(0.3, 0, 0.5, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = sliderFrame

    -- Value box
    local valueBox = Instance.new('TextBox')
    valueBox.Size = UDim2.new(0, 50, 0, 20)
    valueBox.Position = UDim2.new(0.3, 5, 0.5, -20)
    valueBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    valueBox.Text = tostring(initialValue)
    valueBox.TextColor3 = Color3.new(1, 1, 1)
    valueBox.TextSize = 12
    valueBox.Font = Enum.Font.Gotham
    valueBox.Parent = sliderFrame

    local valueBoxCorner = Instance.new('UICorner')
    valueBoxCorner.CornerRadius = UDim.new(0, 4)
    valueBoxCorner.Parent = valueBox

    -- Slider track
    local sliderTrack = Instance.new('Frame')
    sliderTrack.Size = UDim2.new(0.7, -60, 0, 4)
    sliderTrack.Position = UDim2.new(0.3, 60, 0.65, -18)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    sliderTrack.Parent = sliderFrame

    local sliderFill = Instance.new('Frame')
    sliderFill.Size = UDim2.new(
        (initialValue - minValue) / (maxValue - minValue),
        0,
        1,
        0
    )
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    sliderFill.Parent = sliderTrack

    local sliderHandle = Instance.new('TextButton')
    sliderHandle.Size = UDim2.new(0, 16, 0, 16)
    sliderHandle.Position = UDim2.new(
        (initialValue - minValue) / (maxValue - minValue),
        -8,
        0.5,
        -8
    )
    sliderHandle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    sliderHandle.Text = ''
    sliderHandle.Parent = sliderTrack

    local dragging = false
    sliderHandle.MouseButton1Down:Connect(function()
        dragging = true
    end)

    UserInputService.InputChanged:Connect(function(input)
        if
            dragging
            and input.UserInputType == Enum.UserInputType.MouseMovement
        then
            local newX = (input.Position.X - sliderTrack.AbsolutePosition.X)
                / sliderTrack.AbsoluteSize.X
            newX = math.clamp(newX, 0, 1)
            local value = math.floor(minValue + (maxValue - minValue) * newX)

            sliderFill.Size = UDim2.new(newX, 0, 1, 0)
            sliderHandle.Position = UDim2.new(newX, -8, 0.5, -8)
            valueBox.Text = tostring(value)
            callback(value)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    valueBox.FocusLost:Connect(function()
        local value = tonumber(valueBox.Text) or initialValue
        value = math.clamp(value, minValue, maxValue)
        valueBox.Text = tostring(value)

        local newX = (value - minValue) / (maxValue - minValue)
        sliderFill.Size = UDim2.new(newX, 0, 1, 0)
        sliderHandle.Position = UDim2.new(newX, -8, 0.5, -8)
        callback(value)
    end)

    return sliderFrame
end

-- Color Picker Function
local function createColorPicker(parent, labelText, initialColor, callback)
    local colorFrame = Instance.new('Frame')
    colorFrame.Size = UDim2.new(1, -20, 0, 30)
    colorFrame.BackgroundTransparency = 1
    colorFrame.Parent = parent

    -- Label
    local label = Instance.new('TextLabel')
    label.Text = labelText
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = colorFrame

    -- Color Button
    local colorButton = Instance.new('TextButton')
    colorButton.Size = UDim2.new(0, 50, 0, 20)
    colorButton.Position = UDim2.new(0.7, 60, 0.5, -10)
    colorButton.BackgroundColor3 = initialColor
    colorButton.Text = ''
    colorButton.Parent = colorFrame

    local colorCorner = Instance.new('UICorner')
    colorCorner.CornerRadius = UDim.new(0, 4)
    colorCorner.Parent = colorButton

    colorButton.MouseButton1Click:Connect(function()
        if currentColorPicker then
            currentColorPicker:Destroy()
            currentColorPicker = nil
            return
        end

        -- Create Picker GUI
        local pickerGui = Instance.new('ScreenGui')
        pickerGui.Name = "ColorPickerGui"
        pickerGui.ResetOnSpawn = false
        pickerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        pickerGui.Parent = game:GetService("CoreGui") or player.PlayerGui

        -- Main Frame
        local pickerFrame = Instance.new('Frame')
        pickerFrame.Size = UDim2.new(0, 250, 0, 300)
        pickerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        local buttonRightEdge = colorButton.AbsolutePosition.X + colorButton.AbsoluteSize.X
        pickerFrame.Position = UDim2.new(0, buttonRightEdge + 60, 0, colorButton.AbsolutePosition.Y)
        pickerFrame.BackgroundTransparency = 0.1
        if pickerFrame.AbsolutePosition.X + pickerFrame.AbsoluteSize.X > workspace.CurrentCamera.ViewportSize.X then
            pickerFrame.Position = UDim2.new(0, workspace.CurrentCamera.ViewportSize.X - pickerFrame.AbsoluteSize.X - 600, 0, colorButton.AbsolutePosition.Y)
        end
        pickerFrame.Parent = pickerGui

        local corner = Instance.new('UICorner')
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = pickerFrame

        -- Saturation/Value Box
        local saturationBox = Instance.new('ImageLabel')
        saturationBox.Name = "SaturationBox"
        saturationBox.Size = UDim2.new(0, 180, 0, 180)
        saturationBox.Position = UDim2.new(0, 10, 0, 10)
        saturationBox.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
        saturationBox.Image = "rbxassetid://4155801252"
        saturationBox.ZIndex = 1001
        saturationBox.Parent = pickerFrame

        -- Hue Slider (red at bottom)
        local hueSlider = Instance.new('Frame')
        hueSlider.Name = "HueSlider"
        hueSlider.Size = UDim2.new(0, 20, 0, 180)
        hueSlider.Position = UDim2.new(1, -30, 0, 10)
        hueSlider.BackgroundColor3 = Color3.new(1, 1, 1)
        hueSlider.ZIndex = 1001
        hueSlider.Parent = pickerFrame

        local hueGradient = Instance.new('UIGradient')
        hueGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
        }
        hueGradient.Rotation = 90 -- Red at bottom
        hueGradient.Parent = hueSlider

        -- Hue Selector
        local hueSelector = Instance.new('Frame')
        hueSelector.Name = "HueSelector"
        hueSelector.Size = UDim2.new(1, 0, 0, 5)
        hueSelector.AnchorPoint = Vector2.new(0, 0.5)
        hueSelector.BackgroundColor3 = Color3.new(1, 1, 1)
        hueSelector.BorderSizePixel = 2
        hueSelector.BorderColor3 = Color3.new(0, 0, 0)
        hueSelector.ZIndex = 1002
        hueSelector.Parent = hueSlider

        -- Picker Dot
        local pickerDot = Instance.new('Frame')
        pickerDot.Name = "PickerDot"
        pickerDot.Size = UDim2.new(0, 6, 0, 6)
        pickerDot.AnchorPoint = Vector2.new(0.5, 0.5)
        pickerDot.BackgroundColor3 = Color3.new(1, 1, 1)
        pickerDot.BorderSizePixel = 2
        pickerDot.BorderColor3 = Color3.new(0, 0, 0)
        pickerDot.ZIndex = 1002
        pickerDot.Parent = saturationBox

        -- RGB Controls
        local rgbFrame = Instance.new('Frame')
        rgbFrame.Size = UDim2.new(1, -20, 0, 80)
        rgbFrame.Position = UDim2.new(0, 10, 0, 200)
        rgbFrame.BackgroundTransparency = 1
        rgbFrame.Parent = pickerFrame

        local function createRGBControl(yPos, label)
            local frame = Instance.new('Frame')
            frame.Size = UDim2.new(1, 0, 0, 20)
            frame.Position = UDim2.new(0, 0, 0, yPos)
            frame.BackgroundTransparency = 1
            frame.Parent = rgbFrame

            local lbl = Instance.new('TextLabel')
            lbl.Text = label
            lbl.Size = UDim2.new(0, 20, 1, 0)
            lbl.TextColor3 = Color3.new(1,1,1)
            lbl.BackgroundTransparency = 1
            lbl.Parent = frame

            local valueBox = Instance.new('TextBox')
            valueBox.Size = UDim2.new(0, 40, 1, 0)
            valueBox.Position = UDim2.new(0, 25, 0, 0)
            valueBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
            valueBox.TextColor3 = Color3.new(1,1,1)
            valueBox.TextSize = 12
            valueBox.Parent = frame

            local sliderTrack = Instance.new('Frame')
            sliderTrack.Name = "SliderTrack"
            sliderTrack.Size = UDim2.new(0, 120, 0, 5)
            sliderTrack.Position = UDim2.new(0, 70, 0.5, -2)
            sliderTrack.BackgroundColor3 = Color3.fromRGB(80,80,80)
            sliderTrack.Parent = frame

            local sliderFill = Instance.new('Frame')
            sliderFill.Name = "SliderFill"
            sliderFill.Size = UDim2.new(0, 120, 0, 5)
            sliderFill.BackgroundColor3 = Color3.fromRGB(255,165,0)
            sliderFill.Parent = sliderTrack

            local sliderHandle = Instance.new('Frame')
            sliderHandle.Name = "SliderHandle"
            sliderHandle.Size = UDim2.new(0, 10, 0, 10)
            sliderHandle.Position = UDim2.new(0, -5, 0.5, -5)
            sliderHandle.BackgroundColor3 = Color3.new(1,1,1)
            sliderHandle.Parent = sliderTrack

            local corner = Instance.new('UICorner')
            corner.CornerRadius = UDim.new(0, 2)
            corner.Parent = sliderTrack

            return valueBox, sliderFill, sliderHandle, sliderTrack
        end

        local rValue, rFill, rHandle, rTrack = createRGBControl(0, "R")
        local gValue, gFill, gHandle, gTrack = createRGBControl(20, "G")
        local bValue, bFill, bHandle, bTrack = createRGBControl(40, "B")

        -- Hex Input
        local hexFrame = Instance.new('Frame')
        hexFrame.Size = UDim2.new(1, -20, 0, 20)
        hexFrame.Position = UDim2.new(0, 10, 0, 270)
        hexFrame.BackgroundTransparency = 1
        hexFrame.Parent = pickerFrame

        local hexLabel = Instance.new('TextLabel')
        hexLabel.Text = "Hex:"
        hexLabel.Size = UDim2.new(0, 30, 1, 0)
        hexLabel.TextColor3 = Color3.new(1,1,1)
        hexLabel.BackgroundTransparency = 1
        hexLabel.Parent = hexFrame

        local hexInput = Instance.new('TextBox')
        hexInput.Size = UDim2.new(0, 80, 1, 0)
        hexInput.Position = UDim2.new(0, 35, 0, 0)
        hexInput.BackgroundColor3 = Color3.fromRGB(60,60,60)
        hexInput.TextColor3 = Color3.new(1,1,1)
        hexInput.TextSize = 12
        hexInput.Parent = hexFrame

        -- Store current HSV values separately
        local currentH, currentS, currentV = Color3.toHSV(initialColor)

        -- Universal Update Function
        local function updateAllControls()
            local newColor = Color3.fromHSV(currentH, currentS, currentV)
            
            -- Update hue selector (accounting for flipped gradient)
            hueSelector.Position = UDim2.new(0, 0, 0, (1 - currentH) * hueSlider.AbsoluteSize.Y)
            
            -- Update saturation box color and picker dot
            saturationBox.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
            pickerDot.Position = UDim2.new(0, currentS * saturationBox.AbsoluteSize.X, 0, (1 - currentV) * saturationBox.AbsoluteSize.Y)

            -- Update RGB controls
            local r, g, b = math.floor(newColor.R * 255), math.floor(newColor.G * 255), math.floor(newColor.B * 255)
            rValue.Text = tostring(r)
            gValue.Text = tostring(g)
            bValue.Text = tostring(b)
            
            local rNorm, gNorm, bNorm = newColor.R, newColor.G, newColor.B
            rFill.Size = UDim2.new(rNorm, 0, 1, 0)
            gFill.Size = UDim2.new(gNorm, 0, 1, 0)
            bFill.Size = UDim2.new(bNorm, 0, 1, 0)
            rHandle.Position = UDim2.new(rNorm, -5, 0.5, -5)
            gHandle.Position = UDim2.new(gNorm, -5, 0.5, -5)
            bHandle.Position = UDim2.new(bNorm, -5, 0.5, -5)

            -- Update Hex
            hexInput.Text = string.format("#%02X%02X%02X", r, g, b)

            -- Update button and callback
            colorButton.BackgroundColor3 = newColor
            callback(newColor)
        end

        -- Initialize with current color
        updateAllControls()

        -- Mouse Interaction Variables
        local hueDragging = false
        local svDragging = false
        local rDragging = false
        local gDragging = false
        local bDragging = false

        -- HSV Controls Logic
        local function updateHueSelector(mouseY)
            local relativeY = mouseY - hueSlider.AbsolutePosition.Y
            currentH = 1 - math.clamp(relativeY / hueSlider.AbsoluteSize.Y, 0, 1)
            hueSelector.Position = UDim2.new(0, 0, 0, relativeY)
            updateAllControls()
        end

        local function updatePickerDot(mouseX, mouseY)
            local relX = mouseX - saturationBox.AbsolutePosition.X
            local relY = mouseY - saturationBox.AbsolutePosition.Y
            currentS = math.clamp(relX / saturationBox.AbsoluteSize.X, 0, 1)
            currentV = 1 - math.clamp(relY / saturationBox.AbsoluteSize.Y, 0, 1)
            
            pickerDot.Position = UDim2.new(0, relX, 0, relY)
            updateAllControls()
        end

        -- RGB Slider Logic
        local function updateRGBSlider(sliderTrack, value, maxValue)
            local mouseX = UserInputService:GetMouseLocation().X
            local relativeX = mouseX - sliderTrack.AbsolutePosition.X
            local normalized = math.clamp(relativeX / sliderTrack.AbsoluteSize.X, 0, 1)
            return math.floor(normalized * maxValue)
        end

        -- Input Connections
        hueSelector.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                hueDragging = true
            end
        end)

        hueSlider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                hueDragging = true
                updateHueSelector(input.Position.Y)
            end
        end)

        saturationBox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                svDragging = true
                updatePickerDot(input.Position.X, input.Position.Y)
            end
        end)

        -- RGB Slider Handlers
        local function setupRGBDrag(handle, track, valueBox, fill, component)
            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if component == "R" then rDragging = true
                    elseif component == "G" then gDragging = true
                    elseif component == "B" then bDragging = true end
                end
            end)

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local newValue = updateRGBSlider(track, 0, 255)
                    valueBox.Text = tostring(newValue)
                    
                    local newColor = Color3.fromRGB(
                        component == "R" and newValue or tonumber(rValue.Text) or 0,
                        component == "G" and newValue or tonumber(gValue.Text) or 0,
                        component == "B" and newValue or tonumber(bValue.Text) or 0
                    )
                    currentH, currentS, currentV = Color3.toHSV(newColor)
                    updateAllControls()
                    
                    if component == "R" then rDragging = true
                    elseif component == "G" then gDragging = true
                    elseif component == "B" then bDragging = true end
                end
            end)
        end

        setupRGBDrag(rHandle, rTrack, rValue, rFill, "R")
        setupRGBDrag(gHandle, gTrack, gValue, gFill, "G")
        setupRGBDrag(bHandle, bTrack, bValue, bFill, "B")

        -- TextBox Handlers
        local function setupTextBox(valueBox, component)
            valueBox.FocusLost:Connect(function()
                local value = tonumber(valueBox.Text) or 0
                value = math.clamp(value, 0, 255)
                valueBox.Text = tostring(value)
                
                local newColor = Color3.fromRGB(
                    component == "R" and value or tonumber(rValue.Text) or 0,
                    component == "G" and value or tonumber(gValue.Text) or 0,
                    component == "B" and value or tonumber(bValue.Text) or 0
                )
                currentH, currentS, currentV = Color3.toHSV(newColor)
                updateAllControls()
            end)
        end

        setupTextBox(rValue, "R")
        setupTextBox(gValue, "G")
        setupTextBox(bValue, "B")

        -- Hex Input Handler
        hexInput.FocusLost:Connect(function()
            local hex = hexInput.Text:gsub("#", "")
            if #hex == 6 then
                local r = tonumber(hex:sub(1,2), 16) or 0
                local g = tonumber(hex:sub(3,4), 16) or 0
                local b = tonumber(hex:sub(5,6), 16) or 0
                local newColor = Color3.fromRGB(r, g, b)
                currentH, currentS, currentV = Color3.toHSV(newColor)
                updateAllControls()
            end
        end)

        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if hueDragging then
                    updateHueSelector(input.Position.Y)
                elseif svDragging then
                    updatePickerDot(input.Position.X, input.Position.Y)
                elseif rDragging then
                    local newValue = updateRGBSlider(rTrack, 0, 255)
                    rValue.Text = tostring(newValue)
                    local newColor = Color3.fromRGB(
                        newValue,
                        tonumber(gValue.Text) or 0,
                        tonumber(bValue.Text) or 0
                    )
                    currentH, currentS, currentV = Color3.toHSV(newColor)
                    updateAllControls()
                elseif gDragging then
                    local newValue = updateRGBSlider(gTrack, 0, 255)
                    gValue.Text = tostring(newValue)
                    local newColor = Color3.fromRGB(
                        tonumber(rValue.Text) or 0,
                        newValue,
                        tonumber(bValue.Text) or 0
                    )
                    currentH, currentS, currentV = Color3.toHSV(newColor)
                    updateAllControls()
                elseif bDragging then
                    local newValue = updateRGBSlider(bTrack, 0, 255)
                    bValue.Text = tostring(newValue)
                    local newColor = Color3.fromRGB(
                        tonumber(rValue.Text) or 0,
                        tonumber(gValue.Text) or 0,
                        newValue
                    )
                    currentH, currentS, currentV = Color3.toHSV(newColor)
                    updateAllControls()
                end
            end
        end)

        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                hueDragging = false
                svDragging = false
                rDragging = false
                gDragging = false
                bDragging = false
            end
        end)

        -- Close picker when clicking outside
        local outsideConn = game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = input.Position
                if not (mousePos.X >= pickerFrame.AbsolutePosition.X and 
                       mousePos.X <= pickerFrame.AbsolutePosition.X + pickerFrame.AbsoluteSize.X and
                       mousePos.Y >= pickerFrame.AbsolutePosition.Y and 
                       mousePos.Y <= pickerFrame.AbsolutePosition.Y + pickerFrame.AbsoluteSize.Y) then
                    pickerGui:Destroy()
                    currentColorPicker = nil
                    outsideConn:Disconnect()
                end
            end
        end)

        currentColorPicker = pickerGui
    end)

    return colorFrame
end

-- Setup Menu Toggle
local menuToggleConnection
local function setupMenuToggle()
    if menuToggleConnection then
        menuToggleConnection:Disconnect()
    end

    menuToggleConnection = UserInputService.InputBegan:Connect(
        function(input, gameProcessed)
            if gameProcessed then
                return
            end

            -- Menu toggle
            if input.KeyCode == featureKeybinds.Menu then
                MainFrame.Visible = not MainFrame.Visible
            end

            -- Feature toggles with slider animation
            if
                featureKeybinds.NoClip
                and input.KeyCode == featureKeybinds.NoClip
            then
                handleToggleWithSlider('NoClip', not featureStates.NoClip)
            elseif
                featureKeybinds.ESP and input.KeyCode == featureKeybinds.ESP
            then
                handleToggleWithSlider('ESP', not featureStates.ESP)
            elseif
                featureKeybinds.Chams
                and input.KeyCode == featureKeybinds.Chams
            then
                handleToggleWithSlider('Chams', not featureStates.Chams)
            elseif
                featureKeybinds.FullBright
                and input.KeyCode == featureKeybinds.FullBright
            then
                handleToggleWithSlider(
                    'FullBright',
                    not featureStates.FullBright
                )
            elseif
                featureKeybinds.AdvancedESP
                and input.KeyCode == featureKeybinds.AdvancedESP
            then
                handleToggleWithSlider(
                    'AdvancedESP',
                    not featureStates.AdvancedESP
                )
            elseif
                featureKeybinds.Aimbot
                and input.KeyCode == featureKeybinds.Aimbot
            then
                handleToggleWithSlider(
                    'Aimbot',
                    not Aim.Enabled
                )
            end
        end
    )
end

-- Noclip Function
local function toggleNoclip(state)
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

-- FullBright Functions
local function toggleFullBright(state)
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

-- Initialize FullBright
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
                            wait()
                        until _G.FullBrightEnabled
                    end
                    game:GetService('Lighting')[property] = targetValue
                end
            end)
    end

    spawn(function()
        repeat
            wait()
        until _G.FullBrightEnabled
        while wait() do
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

-- ESP Functions (basic, original ESP)
local function getTeamColor(player)
    if not player.Team then
        return NO_TEAM_COLOR
    end
    local baseColor = player.Team.TeamColor.Color
    return Color3.new(
        math.min(baseColor.R * (1 + COLOR_BOOST), 1),
        math.min(baseColor.G * (1 + COLOR_BOOST), 1),
        math.min(baseColor.B * (1 + COLOR_BOOST), 1)
    )
end

local function createESP(player)
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
    espText.TextStrokeColor3 = TEXT_STROKE_COLOR
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
                    createESP(player)
                end
            end
        )
    end

    player:GetPropertyChangedSignal('Team'):Connect(function()
        espText.TextColor3 = getTeamColor(player)
    end)
end

local function updateESP(state)
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
                    createESP(player)
                end
                if not espConnections[player] then
                    espConnections[player] = player.CharacterAdded:Connect(function(character)
                        if featureStates.ESP then
                            createESP(player)
                        end
                    end)
                end
            end
        end
    end
end

-- Chams Functions
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

local function updateChams(state)
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
                    end)
                end
            end
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

    -- ESP Toggle (basic)
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

    -- ESP Tab (Advanced ESP controls)
    local espTabContainer = contentSections.ESP.Container

    local layout = espTabContainer:FindFirstChildOfClass("UIListLayout")
    if layout then
        layout:Destroy()
    end

    local currentY = 10

    -- Advanced ESP Toggle
    local espMasterToggle, espMasterKeybind = createToggle(
        espTabContainer,
        'Advanced ESP',
        featureStates.AdvancedESP,
        function(state) 
            featureStates.AdvancedESP = state 
            if advancedEspModule and advancedEspModule.ToggleAdvancedESP then
                advancedEspModule.ToggleAdvancedESP(state)
            end
        end,
        true,
        'AdvancedESP'
    )
    espMasterToggle.Position = UDim2.new(0, 0, 0, currentY)
    currentY = currentY + 40

    -- Feature toggles for Advanced ESP
    local boxesToggle, _ = createToggle(
        espTabContainer,
        'Boxes',
        featureStates.ESPBoxes,
        function(state)
            featureStates.ESPBoxes = state
            ESP.Boxes = state
            if advancedEspModule and advancedEspModule.UpdateAllESP then
                advancedEspModule.UpdateAllESP()
            end
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
            if advancedEspModule and advancedEspModule.UpdateAllESP then
                advancedEspModule.UpdateAllESP()
            end
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
            if advancedEspModule and advancedEspModule.UpdateAllESP then
                advancedEspModule.UpdateAllESP()
            end
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
            if advancedEspModule and advancedEspModule.UpdateAllESP then
                advancedEspModule.UpdateAllESP()
            end
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
            if advancedEspModule and advancedEspModule.UpdateAllESP then
                advancedEspModule.UpdateAllESP()
            end
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
            if advancedEspModule and advancedEspModule.UpdateAllESP then
                advancedEspModule.UpdateAllESP()
            end
        end,
        false,
        'ESPOutlines'
    )
    outlinesToggle.Position = UDim2.new(0, 0, 0, currentY + 200)

    currentY = currentY + 240

    -- Color Pickers for Advanced ESP
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
        ESP.TextColor = color -- Note: Corrected to ESP.TextColor
        ESP.TextOutlineColor = color -- Note: Also update outline color if they are linked
    end).Position = UDim2.new(0, 0, 0, currentY + 120)

    createColorPicker(espTabContainer, 'Tracer Color', ESP.TracerColor, function(color)
        ESP.TracerColor = color
    end).Position = UDim2.new(0, 0, 0, currentY + 160)

    currentY = currentY + 200

    -- Sliders for Advanced ESP
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
            if advancedEspModule and advancedEspModule.UpdateAllESP then
                advancedEspModule.UpdateAllESP()
            end
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
            if advancedEspModule and advancedEspModule.UpdateAllESP then
                advancedEspModule.UpdateAllESP()
            end
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
            if advancedEspModule and advancedEspModule.UpdateAllESP then
                advancedEspModule.UpdateAllESP()
            end
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
            if aimModule and aimModule.Aim then
                aimModule.Aim.Enabled = state
                aimModule.FOVCircle.Visible = Aim.ShowFOV and state
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
                setupMenuToggle()
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                Aim.CurrentKey = 'MB1'
                Aim.AimKey = Enum.UserInputType.MouseButton1 -- Corrected to Enum
                aimKeybind.Text = 'MB1'
                connection:Disconnect()
                setupMenuToggle()
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                Aim.CurrentKey = 'MB2'
                Aim.AimKey = Enum.UserInputType.MouseButton2 -- Corrected to Enum
                aimKeybind.Text = 'MB2'
                connection:Disconnect()
                setupMenuToggle()
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                Aim.CurrentKey = 'MB3'
                Aim.AimKey = Enum.UserInputType.MouseButton3 -- Corrected to Enum
                aimKeybind.Text = 'MB3'
                connection:Disconnect()
                setupMenuToggle()
            end
            if aimModule and aimModule.Aim then
                aimModule.Aim.AimKey = Aim.AimKey
                aimModule.Aim.CurrentKey = Aim.CurrentKey
            end
        end)
    end)
    aimKeybind.Text = Aim.CurrentKey

    -- Team Check
    createToggle(aimContainer, 'Team Check', featureStates.TeamCheck, function(state)
        featureStates.TeamCheck = state
        Aim.TeamCheck = state
        if aimModule and aimModule.Aim then
            aimModule.Aim.TeamCheck = state
        end
    end, false, 'TeamCheck')

    -- Visibility Check
    createToggle(
        aimContainer,
        'Visibility Check',
        featureStates.VisibilityCheck,
        function(state)
            featureStates.VisibilityCheck = state
            Aim.VisibilityCheck = state
            if aimModule and aimModule.Aim then
                aimModule.Aim.VisibilityCheck = state
            end
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
            if aimModule and aimModule.FOVCircle then
                aimModule.FOVCircle.Visible = state and Aim.Enabled
            end
            if aimModule and aimModule.Aim then
                aimModule.Aim.ShowFOV = state
            end
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
        if aimModule and aimModule.Aim then
            aimModule.Aim.AimPart = 'Head'
        end
    end)

    torsoButton.MouseButton1Click:Connect(function()
        Aim.AimPart = 'Torso'
        torsoHighlight.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        headHighlight.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        if aimModule and aimModule.Aim then
            aimModule.Aim.AimPart = 'Torso'
        end
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
            if aimModule and aimModule.FOVCircle then
                aimModule.FOVCircle.Radius = value
            end
            if aimModule and aimModule.Aim then
                aimModule.Aim.FOV = value
            end
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
        })
    end)
end

-- Player Handling
local function handlePlayer(p)
    p.CharacterAdded:Connect(function()
        if featureStates.ESP then
            createESP(p)
        end
        if featureStates.Chams then
            createChams(p)
        end
        if featureStates.AdvancedESP and advancedEspModule and advancedEspModule.CreateESP then
            advancedEspModule.CreateESP(p)
        end
    end)

    if p.Character then
        if featureStates.ESP then
            createESP(p)
        end
        if featureStates.Chams then
            createChams(p)
        end
        if featureStates.AdvancedESP and advancedEspModule and advancedEspModule.CreateESP then
            advancedEspModule.CreateESP(p)
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    handlePlayer(p)
    if featureStates.AdvancedESP and advancedEspModule and advancedEspModule.CreateESP then
        advancedEspModule.CreateESP(p)
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
    if advancedEspModule and advancedEspModule.RemoveESP then
        advancedEspModule.RemoveESP(p)
    end
end)

-- Initialize ESP for all existing players immediately
for _, p in ipairs(Players:GetPlayers()) do
    handlePlayer(p)
    if featureStates.AdvancedESP and advancedEspModule and advancedEspModule.CreateESP then
        advancedEspModule.CreateESP(p)
    end
end

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

    local titleK = Instance.new('TextLabel') -- Renamed to avoid conflict
    titleK.Text = 'K'
    titleK.Font = Enum.Font.GothamBold
    titleK.TextSize = 18
    titleK.TextColor3 = Color3.fromRGB(255, 165, 0)
    titleK.Size = UDim2.new(1, 0, 0.5, 0)
    titleK.Position = UDim2.new(0, -38, 0, 5)
    titleK.BackgroundTransparency = 1
    titleK.Parent = mainFrame

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

warn('KIB Hook - Enhanced Version Loaded with All Features')
