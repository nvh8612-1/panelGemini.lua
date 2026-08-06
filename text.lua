local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Các biến trạng thái toàn cục
_G.FruitBatchLimit = 1
_G.AutoHarvest = false
_G.AutoCollectSeed = false
_G.HideMePlot = false
_G.HideAllGarden = false
_G.MyPlot = nil

-- Cache thuộc tính gốc để phục hồi khi hiện lại vườn
local originalTransparencyCache = {}
local originalCanCollideCache = {}

-- ==========================================
-- 1. HÀM TRACKER TỰ ĐỘNG QUÉT PLOT CỦA BẠN
-- ==========================================
local function findMyPlot()
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return nil end

    for _, plot in ipairs(gardens:GetChildren()) do
        local ownerValue = plot:FindFirstChild("Owner") or plot:FindFirstChild("OwnerName") or plot:FindFirstChild("Player")
        if ownerValue then
            if (ownerValue:IsA("StringValue") and ownerValue.Value == LocalPlayer.Name) or
               (ownerValue:IsA("ObjectValue") and ownerValue.Value == LocalPlayer) then
                return plot
            end
        end
        if plot.Name:find(LocalPlayer.Name) or plot.Name:find(tostring(LocalPlayer.UserId)) then
            return plot
        end
    end

    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPos = character.HumanoidRootPart.Position
        local closestPlot = nil
        local shortestDistance = math.huge

        for _, plot in ipairs(gardens:GetChildren()) do
            local plotPart = plot:FindFirstChildWhichIsA("BasePart", true)
            if plotPart then
                local dist = (plotPart.Position - rootPos).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestPlot = plot
                end
            end
        end
        return closestPlot
    end
    return nil
end

-- ==========================================
-- 2. HÀM ẨN VƯỜN (TRONG SUỐT & TẮT VA CHẠM)
-- ==========================================
local function setPlotVisible(plot, state)
    if not plot then return end
    
    for _, obj in ipairs(plot:GetDescendants()) do
        if obj:IsA("BasePart") then
            if state then -- Ẩn vườn
                if originalTransparencyCache[obj] == nil then
                    originalTransparencyCache[obj] = obj.Transparency
                    originalCanCollideCache[obj] = obj.CanCollide
                end
                obj.Transparency = 1
                obj.CanCollide = false
            else -- Hiện lại vườn
                if originalTransparencyCache[obj] ~= nil then
                    obj.Transparency = originalTransparencyCache[obj]
                    obj.CanCollide = originalCanCollideCache[obj]
                end
            end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if state then
                if originalTransparencyCache[obj] == nil then
                    originalTransparencyCache[obj] = obj.Transparency
                end
                obj.Transparency = 1
            else
                if originalTransparencyCache[obj] ~= nil then
                    obj.Transparency = originalTransparencyCache[obj]
                end
            end
        end
    end
end

local function toggleMePlot(state)
    if not _G.MyPlot then _G.MyPlot = findMyPlot() end
    if not _G.MyPlot then return end
    setPlotVisible(_G.MyPlot, state)
end

local function toggleAllGarden(state)
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return end

    for _, plot in ipairs(gardens:GetChildren()) do
        setPlotVisible(plot, state)
    end
end

-- ==========================================
-- 3. HÀM THU HOẠCH (AUTO HARVEST)
-- ==========================================
local function processHarvest()
    pcall(function()
        if not _G.MyPlot then _G.MyPlot = findMyPlot() end
        local targetFolder = _G.MyPlot or workspace:FindFirstChild("Gardens") or workspace
        local count = 0

        for _, crop in ipairs(targetFolder:GetDescendants()) do
            if not _G.AutoHarvest then break end
            
            if crop:IsA("ProximityPrompt") and (crop.Name:lower():find("harvest") or crop.ObjectText:lower():find("harvest") or crop.ActionText:lower():find("harvest")) then
                fireproximityprompt(crop)
                count = count + 1
                if count >= _G.FruitBatchLimit then break end
            end
        end
    end)
end

task.spawn(function()
    while true do
        if _G.AutoHarvest then processHarvest() end
        task.wait(0.1)
    end
end)

-- ==========================================
-- 4. HÀM NHẶT HẠT GIỐNG BÁN KÍNH 30M (TWEEN)
-- ==========================================
local function tweenToAndPick(targetPos, prompt)
    local character = LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local distance = (rootPart.Position - targetPos).Magnitude
    local tweenTime = distance / 50
    if tweenTime < 0.1 then tweenTime = 0.1 end

    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))})

    tween:Play()
    
    local completed = false
    tween.Completed:Connect(function() completed = true end)

    while not completed do
        if not _G.AutoCollectSeed then
            tween:Cancel()
            break
        end
        task.wait(0.05)
    end

    if prompt and _G.AutoCollectSeed then
        fireproximityprompt(prompt)
    end
end

task.spawn(function()
    while true do
        if _G.AutoCollectSeed then
            pcall(function()
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                local droppedFolder = workspace:FindFirstChild("DroppedItems")

                if rootPart and droppedFolder then
                    for _, item in ipairs(droppedFolder:GetChildren()) do
                        if not _G.AutoCollectSeed then break end

                        local targetPart = item:FindFirstChild("PromptAnchor") 
                            or item:FindFirstChildWhichIsA("BasePart") 
                            or (item:IsA("BasePart") and item)

                        if targetPart then
                            local distance = (rootPart.Position - targetPart.Position).Magnitude
                            if distance <= 100 then
                                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                                tweenToAndPick(targetPart.Position, prompt)
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- ==========================================
-- 5. GIAO DIỆN PANEL GEMINI GAG2 (UI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local MinimizeBtn = Instance.new("TextButton")
local ContentFrame = Instance.new("Frame")

local OpenCloseBtn = Instance.new("TextButton")
local OpenCorner = Instance.new("UICorner")

local PlotStatus = Instance.new("TextLabel")
local FruitInput = Instance.new("TextBox")
local HarvestBtn = Instance.new("TextButton")
local CollectBtn = Instance.new("TextButton")
local HideAllBtn = Instance.new("TextButton")
local HideMeBtn = Instance.new("TextButton")

ScreenGui.Name = "GeminiGAG2Panel_Perfect"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Nút tròn nổi 'G' để Ẩn / Hiện toàn bộ Menu
OpenCloseBtn.Name = "OpenCloseBtn"
OpenCloseBtn.Parent = ScreenGui
OpenCloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
OpenCloseBtn.Position = UDim2.new(0.02, 0, 0.15, 0)
OpenCloseBtn.Size = UDim2.new(0, 35, 0, 35)
OpenCloseBtn.Font = Enum.Font.SourceSansBold
OpenCloseBtn.Text = "G"
OpenCloseBtn.TextColor3 = Color3.fromRGB(0, 225, 255)
OpenCloseBtn.TextSize = 20
OpenCloseBtn.Active = true
OpenCloseBtn.Draggable = true

OpenCorner.CornerRadius = UDim.new(1, 0)
OpenCorner.Parent = OpenCloseBtn

-- Main Frame
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.Position = UDim2.new(0.08, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 230, 0, 330)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Title Bar
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "  Gemini GAG2 Panel"
Title.TextColor3 = Color3.fromRGB(0, 225, 255)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- Nút Thu Gọn (-) và Xòe Ra (^)
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Parent = Title
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Position = UDim2.new(0.8, 0, 0, 0)
MinimizeBtn.Size = UDim2.new(0.2, 0, 1, 0)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 22

-- Content Frame
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.Size = UDim2.new(1, 0, 1, -35)

-- Status Bar
PlotStatus.Name = "PlotStatus"
PlotStatus.Parent = ContentFrame
PlotStatus.BackgroundTransparency = 1
PlotStatus.Position = UDim2.new(0.05, 0, 0.02, 0)
PlotStatus.Size = UDim2.new(0.9, 0, 0, 20)
PlotStatus.Font = Enum.Font.SourceSansItalic
PlotStatus.Text = "Plot: Standby..."
PlotStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
PlotStatus.TextSize = 14

local function updatePlotUI()
    _G.MyPlot = findMyPlot()
    if _G.MyPlot then
        PlotStatus.Text = "Plot: " .. _G.MyPlot.Name
        PlotStatus.TextColor3 = Color3.fromRGB(50, 255, 100)
    else
        PlotStatus.Text = "Plot: Không tìm thấy"
        PlotStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

-- Fruit Input
FruitInput.Name = "FruitInput"
FruitInput.Parent = ContentFrame
FruitInput.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
FruitInput.Position = UDim2.new(0.08, 0, 0.11, 0)
FruitInput.Size = UDim2.new(0.84, 0, 0, 30)
FruitInput.Font = Enum.Font.SourceSans
FruitInput.PlaceholderText = "Số trái / khung (1, 2...)"
FruitInput.Text = "1"
FruitInput.TextColor3 = Color3.fromRGB(255, 255, 255)
FruitInput.TextSize = 14

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = FruitInput

FruitInput.FocusLost:Connect(function()
    local num = tonumber(FruitInput.Text)
    if num and num > 0 then
        _G.FruitBatchLimit = math.floor(num)
    else
        FruitInput.Text = tostring(_G.FruitBatchLimit)
    end
end)

-- Button 1: Auto Harvest
HarvestBtn.Name = "HarvestBtn"
HarvestBtn.Parent = ContentFrame
HarvestBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
HarvestBtn.Position = UDim2.new(0.08, 0, 0.25, 0)
HarvestBtn.Size = UDim2.new(0.84, 0, 0, 30)
HarvestBtn.Font = Enum.Font.SourceSansBold
HarvestBtn.Text = "Auto Harvest: OFF"
HarvestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HarvestBtn.TextSize = 14

local HarvestCorner = Instance.new("UICorner")
HarvestCorner.CornerRadius = UDim.new(0, 6)
HarvestCorner.Parent = HarvestBtn

HarvestBtn.MouseButton1Click:Connect(function()
    _G.AutoHarvest = not _G.AutoHarvest
    if _G.AutoHarvest then
        updatePlotUI()
        HarvestBtn.Text = "Auto Harvest: ON"
        HarvestBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        HarvestBtn.Text = "Auto Harvest: OFF"
        HarvestBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end)

-- Button 2: Auto Collect Seed (30m)
CollectBtn.Name = "CollectBtn"
CollectBtn.Parent = ContentFrame
CollectBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CollectBtn.Position = UDim2.new(0.08, 0, 0.39, 0)
CollectBtn.Size = UDim2.new(0.84, 0, 0, 30)
CollectBtn.Font = Enum.Font.SourceSansBold
CollectBtn.Text = "Auto Collect Seed (30m): OFF"
CollectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CollectBtn.TextSize = 13

local CollectCorner = Instance.new("UICorner")
CollectCorner.CornerRadius = UDim.new(0, 6)
CollectCorner.Parent = CollectBtn

CollectBtn.MouseButton1Click:Connect(function()
    _G.AutoCollectSeed = not _G.AutoCollectSeed
    if _G.AutoCollectSeed then
        CollectBtn.Text = "Auto Collect Seed (30m): ON"
        CollectBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        CollectBtn.Text = "Auto Collect Seed (30m): OFF"
        CollectBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end)

-- Button 3: Hide All Garden
HideAllBtn.Name = "HideAllBtn"
HideAllBtn.Parent = ContentFrame
HideAllBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
HideAllBtn.Position = UDim2.new(0.08, 0, 0.53, 0)
HideAllBtn.Size = UDim2.new(0.84, 0, 0, 30)
HideAllBtn.Font = Enum.Font.SourceSansBold
HideAllBtn.Text = "Hide All Garden: OFF"
HideAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HideAllBtn.TextSize = 14

local HideAllCorner = Instance.new("UICorner")
HideAllCorner.CornerRadius = UDim.new(0, 6)
HideAllCorner.Parent = HideAllBtn

HideAllBtn.MouseButton1Click:Connect(function()
    _G.HideAllGarden = not _G.HideAllGarden
    if _G.HideAllGarden then
        toggleAllGarden(true)
        HideAllBtn.Text = "Hide All Garden: ON"
        HideAllBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        toggleAllGarden(false)
        HideAllBtn.Text = "Hide All Garden: OFF"
        HideAllBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end)

-- Button 4: Hide Me Garden
HideMeBtn.Name = "HideMeBtn"
HideMeBtn.Parent = ContentFrame
HideMeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
HideMeBtn.Position = UDim2.new(0.08, 0, 0.67, 0)
HideMeBtn.Size = UDim2.new(0.84, 0, 0, 30)
HideMeBtn.Font = Enum.Font.SourceSansBold
HideMeBtn.Text = "Hide Me Garden: OFF"
HideMeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HideMeBtn.TextSize = 14

local HideMeCorner = Instance.new("UICorner")
HideMeCorner.CornerRadius = UDim.new(0, 6)
HideMeCorner.Parent = HideMeBtn

HideMeBtn.MouseButton1Click:Connect(function()
    _G.HideMePlot = not _G.HideMePlot
    if _G.HideMePlot then
        updatePlotUI()
        toggleMePlot(true)
        HideMeBtn.Text = "Hide Me Garden: ON"
        HideMeBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        toggleMePlot(false)
        HideMeBtn.Text = "Hide Me Garden: OFF"
        HideMeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end)

-- LOGIC THU GỌN (-) VÀ XÒE RA (^)
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        ContentFrame.Visible = false
        MainFrame:TweenSize(UDim2.new(0, 230, 0, 35), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.15, true)
        MinimizeBtn.Text = "^"
    else
        MainFrame:TweenSize(UDim2.new(0, 230, 0, 330), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.15, true, function()
            ContentFrame.Visible = true
        end)
        MinimizeBtn.Text = "-"
    end
end)

-- LOGIC ẨN / HIỆN TOÀN BỘ MENU (NÚT NỔI 'G' HOẶC PHÍM 'K')
local function toggleUI()
    MainFrame.Visible = not MainFrame.Visible
end

OpenCloseBtn.MouseButton1Click:Connect(toggleUI)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.K then
        toggleUI()
    end
end)
