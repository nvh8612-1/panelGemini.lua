local Players = game:GetService("Players")
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

    -- Ưu tiên 1: Quét tên Owner trong từng Plot
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

    -- Ưu tiên 2 (Dự phòng): Chọn Plot nằm gần nhân vật nhất
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
-- 2. HÀM TỰ ĐỘNG THU HOẠCH (AUTO HARVEST)
-- ==========================================
local function processHarvest()
    pcall(function()
        -- Tự động tracker lại Plot nếu chưa xác định được
        if not _G.MyPlot then
            _G.MyPlot = findMyPlot()
        end
        
        local targetFolder = _G.MyPlot or workspace:FindFirstChild("Gardens") or workspace
        local count = 0

        for _, crop in ipairs(targetFolder:GetDescendants()) do
            if not _G.AutoHarvest then break end
            
            if crop:IsA("ProximityPrompt") and (crop.Name:lower():find("harvest") or crop.ObjectText:lower():find("harvest") or crop.ActionText:lower():find("harvest")) then
                fireproximityprompt(crop)
                count = count + 1
                
                -- Giới hạn số trái mỗi khung hình theo Input
                if count >= _G.FruitBatchLimit then
                    break
                end
            end
        end
    end)
end

-- Vòng lặp Auto Harvest
task.spawn(function()
    while true do
        if _G.AutoHarvest then
            processHarvest()
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- 3. HÀM TỰ ĐỘNG NHẶT HẠT GIỐNG (AUTO COLLECT SEED)
-- ==========================================
local function moveToAndPick(targetPos, prompt)
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    humanoid:MoveTo(targetPos)
    
    local timeWaited = 0
    while (rootPart.Position - targetPos).Magnitude > 4 and timeWaited < 2 do
        if not _G.AutoCollectSeed then break end
        task.wait(0.1)
        timeWaited = timeWaited + 0.1
    end

    if prompt then
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
                            moveToAndPick(targetPart.Position, prompt)
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- ==========================================
-- 4. GIAO DIỆN PANEL GEMINI GAG2 (UI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local PlotStatus = Instance.new("TextLabel")

local FruitInput = Instance.new("TextBox")
local HarvestBtn = Instance.new("TextButton")
local CollectBtn = Instance.new("TextButton")

ScreenGui.Name = "GeminiGAG2Panel_AutoTrack"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Khung chính
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.Size = UDim2.new(0, 230, 0, 250)
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Tiêu đề Panel
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Gemini GAG2 Panel"
Title.TextColor3 = Color3.fromRGB(0, 225, 255)
Title.TextSize = 18

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- Nhãn hiển thị trạng thái Plot
PlotStatus.Name = "PlotStatus"
PlotStatus.Parent = MainFrame
PlotStatus.BackgroundTransparency = 1
PlotStatus.Position = UDim2.new(0.05, 0, 0.16, 0)
PlotStatus.Size = UDim2.new(0.9, 0, 0, 20)
PlotStatus.Font = Enum.Font.SourceSansItalic
PlotStatus.Text = "Plot: Standby..."
PlotStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
PlotStatus.TextSize = 14

-- Hàm cập nhật Plot Status UI
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
FruitInput.Parent = MainFrame
FruitInput.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
FruitInput.Position = UDim2.new(0.08, 0, 0.27, 0)
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

-- Nút Auto Harvest (Đã tích hợp Auto Tracker)
HarvestBtn.Name = "HarvestBtn"
HarvestBtn.Parent = MainFrame
HarvestBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
HarvestBtn.Position = UDim2.new(0.08, 0, 0.46, 0)
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
        -- TỰ ĐỘNG TRACK PLOT NGAY KHI BẤM BẬT
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
CollectBtn.Parent = MainFrame
CollectBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CollectBtn.Position = UDim2.new(0.08, 0, 0.65, 0)
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
