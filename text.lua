local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Biến trạng thái toàn cục
_G.FruitBatchLimit = 1
_G.AutoHarvest = false
_G.AutoCollectSeed = false
_G.MyPlot = nil

-- ==========================================
-- 1. HÀM TRACKER TÌM PLOT TỰ ĐỘNG
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
-- 2. HÀM THU HOẠCH (AUTO HARVEST)
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
-- 3. HÀM BAY ĐẾN NHẶT HẠT GIỐNG (TWEEN / FLY)
-- ==========================================
local function tweenToAndPick(targetPos, prompt)
    local character = LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Tính khoảng cách để chỉnh tốc độ bay mượt mà (Tốc độ ~ 50 stud/s)
    local distance = (rootPart.Position - targetPos).Magnitude
    local tweenTime = distance / 50
    if tweenTime < 0.1 then tweenTime = 0.1 end

    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))})

    tween:Play()
    
    -- Chờ bay xong hoặc nếu người dùng tắt Auto thì dừng Tween
    local completed = false
    tween.Completed:Connect(function() completed = true end)

    while not completed do
        if not _G.AutoCollectSeed then
            tween:Cancel()
            break
        end
        task.wait(0.05)
    end

    -- Tự động nhặt khi bay tới nơi
    if prompt and _G.AutoCollectSeed then
        fireproximityprompt(prompt)
    end
end

task.spawn(function()
    while true do
        if _G.AutoCollectSeed then
            pcall(function()
                local droppedFolder = workspace:FindFirstChild("DroppedItems")
                if droppedFolder then
                    for _, item in ipairs(droppedFolder:GetChildren()) do
                        if not _G.AutoCollectSeed then break end

                        local targetPart = item:FindFirstChild("PromptAnchor") 
                            or item:FindFirstChildWhichIsA("BasePart") 
                            or (item:IsA("BasePart") and item)

                        if targetPart then
                            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                            tweenToAndPick(targetPart.Position, prompt)
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- ==========================================
-- 4. GIAO DIỆN PANEL GEMINI GAG2 (CÓ NÚT THU GỌN - / ^)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local MinimizeBtn = Instance.new("TextButton")
local ContentFrame = Instance.new("Frame") -- Khung chứa nội dung bên trong

local PlotStatus = Instance.new("TextLabel")
local FruitInput = Instance.new("TextBox")
local HarvestBtn = Instance.new("TextButton")
local CollectBtn = Instance.new("TextButton")

ScreenGui.Name = "GeminiGAG2Panel_Tween"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Frame Chính (Bao ngoài)
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.Size = UDim2.new(0, 230, 0, 250)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true -- Giúp ẩn nội dung khi thu gọn

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Thanh Tiêu Đề
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

-- Nút Thu Gọn (-) / Mở Rộng (^)
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Parent = Title
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Position = UDim2.new(0.8, 0, 0, 0)
MinimizeBtn.Size = UDim2.new(0.2, 0, 1, 0)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 22

-- Khung chứa nội dung (sẽ ẩn/hiện khi bấm nút)
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.Size = UDim2.new(1, 0, 1, -35)

-- Trạng thái Plot
PlotStatus.Name = "PlotStatus"
PlotStatus.Parent = ContentFrame
PlotStatus.BackgroundTransparency = 1
PlotStatus.Position = UDim2.new(0.05, 0, 0.05, 0)
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

-- Input Số Lượng Trái
FruitInput.Name = "FruitInput"
FruitInput.Parent = ContentFrame
FruitInput.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
FruitInput.Position = UDim2.new(0.08, 0, 0.18, 0)
FruitInput.Size = UDim2.new(0.84, 0, 0, 35)
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

-- Nút Auto Harvest
HarvestBtn.Name = "HarvestBtn"
HarvestBtn.Parent = ContentFrame
HarvestBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
HarvestBtn.Position = UDim2.new(0.08, 0, 0.40, 0)
HarvestBtn.Size = UDim2.new(0.84, 0, 0, 35)
HarvestBtn.Font = Enum.Font.SourceSansBold
HarvestBtn.Text = "Auto Harvest: OFF"
HarvestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HarvestBtn.TextSize = 15

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

-- Nút Auto Collect Seed
CollectBtn.Name = "CollectBtn"
CollectBtn.Parent = ContentFrame
CollectBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CollectBtn.Position = UDim2.new(0.08, 0, 0.62, 0)
CollectBtn.Size = UDim2.new(0.84, 0, 0, 35)
CollectBtn.Font = Enum.Font.SourceSansBold
CollectBtn.Text = "Auto Collect Seed: OFF"
CollectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CollectBtn.TextSize = 15

local CollectCorner = Instance.new("UICorner")
CollectCorner.CornerRadius = UDim.new(0, 6)
CollectCorner.Parent = CollectBtn

CollectBtn.MouseButton1Click:Connect(function()
    _G.AutoCollectSeed = not _G.AutoCollectSeed
    if _G.AutoCollectSeed then
        CollectBtn.Text = "Auto Collect Seed: ON"
        CollectBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        CollectBtn.Text = "Auto Collect Seed: OFF"
        CollectBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end)

-- ==========================================
-- XỬ LÝ NÚT THU GỌN / MỞ RỘNG PANEL
-- ==========================================
local isMinimized = false

MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    
    if isMinimized then
        -- Thu gọn lại: Chỉ giữ thanh tiêu đề
        ContentFrame.Visible = false
        MainFrame:TweenSize(UDim2.new(0, 230, 0, 35), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
        MinimizeBtn.Text = "^"
    else
        -- Mở rộng ra đầy đủ
        MainFrame:TweenSize(UDim2.new(0, 230, 0, 250), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true, function()
            ContentFrame.Visible = true
        end)
        MinimizeBtn.Text = "-"
    end
end)
