local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Các biến trạng thái toàn cục
_G.FruitBatchLimit = 1 -- Số lượng trái xử lý tối đa mỗi lượt (mặc định là 1)
_G.AutoHarvest = false
_G.AutoCollectSeed = false

-- ==========================================
-- 1. HÀM TỰ ĐỘNG THU HOẠCH (AUTO HARVEST)
-- ==========================================
local function processHarvest()
    pcall(function()
        -- Tìm thư mục chứa cây/trái trồng trong workspace (thường tên là Crops, Plants, v.v.)
        local cropsFolder = workspace:FindFirstChild("Crops") 
            or workspace:FindFirstChild("Plants") 
            or workspace:FindFirstChild("Farm") 
            or workspace

        local count = 0
        for _, crop in ipairs(cropsFolder:GetDescendants()) do
            if not _G.AutoHarvest then break end
            
            -- Kiểm tra xem có ProximityPrompt thu hoạch không
            if crop:IsA("ProximityPrompt") and (crop.Name:lower():find("harvest") or crop.ObjectText:lower():find("harvest") or crop.ActionText:lower():find("harvest")) then
                fireproximityprompt(crop)
                count = count + 1
                
                -- Giới hạn số lượng trái theo Input của người dùng trong 1 khung hình/chu kỳ
                if count >= _G.FruitBatchLimit then
                    break
                end
            end
        end
    end)
end

task.spawn(function()
    while true do
        if _G.AutoHarvest then
            processHarvest()
        end
        task.wait(0.001)
    end
end)

-- ==========================================
-- 2. HÀM TỰ ĐỘNG NHẶT HẠT GIỐNG (AUTO COLLECT SEED)
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
        task.wait(0.01)
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
        task.wait(0.03)
    end
end)

-- ==========================================
-- 3. GIAO DIỆN PANEL GEMINI GAG2 (UI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local UICorner = Instance.new("UICorner")

-- Khai báo khung Input & Buttons
local FruitInput = Instance.new("TextBox")
local HarvestBtn = Instance.new("TextButton")
local CollectBtn = Instance.new("TextButton")

ScreenGui.Name = "GeminiGAG2Panel"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Khung chính của Panel
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 220, 0, 210)
MainFrame.Active = true
MainFrame.Draggable = true -- Kéo thả Panel thoải mái trên màn hình

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

-- Ô Nhập Số Lượng Trái (Fruit Input)
FruitInput.Name = "FruitInput"
FruitInput.Parent = MainFrame
FruitInput.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
FruitInput.Position = UDim2.new(0.08, 0, 0.23, 0)
FruitInput.Size = UDim2.new(0.84, 0, 0, 35)
FruitInput.Font = Enum.Font.SourceSans
FruitInput.PlaceholderText = "Số trái / khung (Ví dụ: 1, 2...)"
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
HarvestBtn.Parent = MainFrame
HarvestBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
HarvestBtn.Position = UDim2.new(0.08, 0, 0.45, 0)
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
CollectBtn.Position = UDim2.new(0.08, 0, 0.67, 0)
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