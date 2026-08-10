-- ====================================================================
-- PANEL GEMINI - GAG2 (Direct Tab Binding - Anti Blank Tab)
-- Script được làm bởi WhiteSs
-- ====================================================================

local Players = game:GetService("Players")
local StatsService = game:GetService("Stats")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Load WindUI library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- 1. TẠO WINDOW CHÍNH
local Window = WindUI:CreateWindow({
    Title = "Panel Gemini",
    Author = "WhiteSs",
    Folder = "GeminiGAG2",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark"
})

-- 2. KHỞI TẠO TABS
local MainTab  = Window:Tab({ Title = "Main",  Icon = "home" })
local AutoTab  = Window:Tab({ Title = "Auto",  Icon = "repeat" })
local ShopTab  = Window:Tab({ Title = "Shop",  Icon = "shopping-cart" })
local SpeedTab = Window:Tab({ Title = "Speed", Icon = "zap" })
local MiscTab  = Window:Tab({ Title = "Misc",  Icon = "sliders" })

-- =========================================================
-- LOGIC DÒ PLOT & DỮ LIỆU
-- =========================================================
_G.MyPlot = nil
local SavedPlotName = "workspace.Gardens.Plot1"

local function findMyPlot()
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return nil end

    for _, plot in ipairs(gardens:GetChildren()) do
        local attrOwner = plot:GetAttribute("Owner")
        local attrUserId = plot:GetAttribute("OwnerUserId")

        if attrOwner and tostring(attrOwner) == LocalPlayer.Name then return plot end
        if attrUserId and tonumber(attrUserId) == LocalPlayer.UserId then return plot end

        local ownerValue = plot:FindFirstChild("Owner") or plot:FindFirstChild("OwnerName") or plot:FindFirstChild("Player")
        if ownerValue then
            if (ownerValue:IsA("StringValue") and ownerValue.Value == LocalPlayer.Name) or
               (ownerValue:IsA("ObjectValue") and ownerValue.Value == LocalPlayer) then
                return plot
            end
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
        if closestPlot and shortestDistance < 100 then return closestPlot end
    end

    return gardens:FindFirstChild("Plot1") or gardens:FindFirstChild("plot1") or gardens:GetChildren()[1]
end

_G.MyPlot = findMyPlot()
if _G.MyPlot then SavedPlotName = "workspace.Gardens." .. _G.MyPlot.Name end

local function getLeavesValue()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local leaves = leaderstats:FindFirstChild("Leaves")
        if leaves then return leaves.Value end
    end
    return 0
end

local function formatNumber(n)
    return tostring(n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

---------------------------------------------------------
-- TAB: MAIN
---------------------------------------------------------
MainTab:Paragraph({
    Title = "Panel Gemini | Grow A Garden 2",
    Desc = "=> WhiteSs"
})

local StatusParagraph = MainTab:Paragraph({
    Title = "📊 Status Hệ Thống",
    Desc = "Đang tải dữ liệu..."
})

task.spawn(function()
    while task.wait(0.5) do
        local fps = math.floor(1 / math.max(RunService.RenderStepped:Wait(), 0.001))
        local ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
        local ms = math.floor(RunService.RenderStepped:Wait() * 1000)
        local leaves = getLeavesValue()

        local formattedText = string.format(
            "👤 Người chơi: %s\n\n🍁 Leaves : %s\n\n⚡ FPS: %d | Ping: %dms | Frame: %dms\n\n🏡 Vườn (Plot): %s",
            LocalPlayer.Name, formatNumber(leaves), fps, ping, ms, SavedPlotName
        )
        StatusParagraph:SetDesc(formattedText)
    end
end)

---------------------------------------------------------
-- TAB: AUTO
---------------------------------------------------------
_G.FruitBatchLimit = 1
_G.AutoHarvest = false
_G.AutoCollectSeed = false
_G.LookAtTarget = true

AutoTab:Input({
    Title = "FruitHarvest Amount",
    Desc = "Số lượng quả thu hoạch / đợt",
    Value = "1",
    Placeholder = "Nhập số lượng...",
    Callback = function(Text)
        local num = tonumber(Text)
        _G.FruitBatchLimit = (num and num > 0) and math.floor(num) or 1
    end
})

AutoTab:Toggle({
    Title = "Look At Plant When Harvest",
    Desc = "Xoay camera về phía quả thu hoạch",
    Value = true,
    Callback = function(Value)
        _G.LookAtTarget = Value
    end
})

local function lookAtPosition(targetPos)
    local camera = workspace.CurrentCamera
    if camera then camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos) end
end

local function triggerHarvestPrompt(prompt, targetPart)
    if not prompt then return end
    pcall(function()
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 99999
        prompt.RequiresLineOfSight = false
        if _G.LookAtTarget and targetPart then lookAtPosition(targetPart.Position) end
        if fireHarvestPrompt then fireHarvestPrompt(prompt)
        elseif fireproximityprompt then fireproximityprompt(prompt) end
    end)
end

RunService.Heartbeat:Connect(function()
    if _G.AutoHarvest then
        pcall(function()
            if not _G.MyPlot then _G.MyPlot = findMyPlot() end
            local targetPlot = _G.MyPlot or (workspace:FindFirstChild("Gardens") and workspace.Gardens:FindFirstChildOfClass("Model"))
            if not targetPlot then return end
            local plants = targetPlot:FindFirstChild("Plants")
            if not plants then return end

            local count = 0
            for _, plant in ipairs(plants:GetChildren()) do
                if not _G.AutoHarvest then break end
                local fruits = plant:FindFirstChild("Fruits")
                if fruits then
                    for _, fruit in ipairs(fruits:GetChildren()) do
                        if not _G.AutoHarvest then break end
                        local harvestPrompt = fruit:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local harvestPart = fruit:FindFirstChild("HarvestPart") or fruit:FindFirstChildWhichIsA("BasePart") or fruit
                        if harvestPrompt then
                            triggerHarvestPrompt(harvestPrompt, harvestPart)
                            count = count + 1
                            if count >= _G.FruitBatchLimit then break end
                        end
                    end
                end
                if count >= _G.FruitBatchLimit then break end
            end
        end)
    end
end)

AutoTab:Toggle({
    Title = "Auto Harvest",
    Value = false,
    Callback = function(Value) _G.AutoHarvest = Value end
})

local function triggerPickupPrompt(prompt, targetPart)
    if not prompt then return end
    pcall(function()
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 99999
        prompt.RequiresLineOfSight = false
        if _G.LookAtTarget and targetPart then lookAtPosition(targetPart.Position) end
        if firePickupPrompt then firePickupPrompt(prompt)
        elseif fireproximityprompt then fireproximityprompt(prompt) end
    end)
end

RunService.Heartbeat:Connect(function()
    if _G.AutoCollectSeed then
        pcall(function()
            local droppedFolder = workspace:FindFirstChild("DroppedItems")
            if droppedFolder then
                for _, item in ipairs(droppedFolder:GetChildren()) do
                    if not _G.AutoCollectSeed then break end
                    local promptAnchor = item:FindFirstChild("PromptAnchor") or item:FindFirstChildWhichIsA("BasePart")
                    local pickupPrompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if pickupPrompt then triggerPickupPrompt(pickupPrompt, promptAnchor) end
                end
            end
        end)
    end
end)

AutoTab:Toggle({
    Title = "Auto Collect Seed",
    Value = false,
    Callback = function(Value) _G.AutoCollectSeed = Value end
})

_G.DelaySell = 0.1
AutoTab:Input({
    Title = "DelaySell",
    Desc = "Thời gian delay bán",
    Value = "0.1",
    Placeholder = "0.1",
    Callback = function(Text)
        local sanitizedText = string.gsub(Text, ",", ".")
        local num = tonumber(sanitizedText)
        _G.DelaySell = (num and num >= 0) and num or 0.1
    end
})

_G.AutoSell = false
AutoTab:Toggle({
    Title = "Auto Sell Inventory",
    Value = false,
    Callback = function(Value)
        _G.AutoSell = Value
        task.spawn(function()
            local Networking
            pcall(function() Networking = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking")) end)
            while _G.AutoSell do
                if Networking and Networking.NPCS and Networking.NPCS.SellAll then
                    Networking.NPCS.SellAll:Fire()
                end
                task.wait(_G.DelaySell or 0.1)
            end
        end)
    end
})

---------------------------------------------------------
-- SHOP
---------------------------------------------------------
local PacketRemote = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent")

local AllSeeds = {
    "Carrot", "Strawberry", "Blueberry", "Tulip", "Tomato", 
    "Apple", "Bamboo", "Corn", "Cactus", "Pineapple", 
    "Mushroom", "Banana", "Grape", "Coconut", 
    "Maple Coconut", "Mango", "Rocket Pop", "Dragon Fruit", "Acorn", 
    "Cherry", "Sunflower", "Fire Fern", "Venus Fly Trap", "Pomegranate", 
    "Poison Apple", "Venom Spitter", "Moon Bloom", "Sun Bloom", "Hypno Bloom", 
    "Dragon's Breath", "Star Fruit", "Conifer Cone", "Amber Cranberry", "Atlantic Giant Pumpkin", 
    "Maple Carrot", "Maple Strawberry", "Maple Blueberry", "Maple Tulip", "Maple Tomato", 
    "Maple Apple", "Maple Bamboo", "Maple Corn", "Maple Cactus", "Maple Pineapple", 
    "Maple Mushroom", "Maple Banana", "Maple Grape", "Maple Mango", 
    "Maple Dragon Fruit", "Maple Acorn", "Maple Cherry", "Maple Sunflower", "Maple Venus Fly Trap", 
    "Maple Pomegranate", "Maple Poison Apple", "Maple Venom Spitter", "Maple Atlantic Giant Pumpkin"
}

_G.SelectedSeeds = {}
_G.AutoBuySeed = false
_G.AutoBuyAllSeeds = false

local SeedBuffers = {}
for _, name in ipairs(AllSeeds) do
    local payload = "\160\000" .. string.char(#name) .. name
    SeedBuffers[name] = buffer.fromstring(payload)
end

local function buySeedFast(seedName)
    local buf = SeedBuffers[seedName]
    if buf then PacketRemote:FireServer(buf) end
end

ShopTab:Dropdown({
    Title = "Chọn Hạt Giống (Multi-Select)",
    Desc = "Tích chọn hạt muốn mua",
    Values = AllSeeds,
    Multi = true,
    Value = { AllSeeds[1] },
    Callback = function(Values) _G.SelectedSeeds = Values end
})

ShopTab:Toggle({
    Title = "Auto Buy Selected Seeds",
    Value = false,
    Callback = function(Value)
        _G.AutoBuySeed = Value
        task.spawn(function()
            while _G.AutoBuySeed do
                if _G.SelectedSeeds then
                    for _, seedName in ipairs(_G.SelectedSeeds) do
                        if not _G.AutoBuySeed then break end
                        buySeedFast(seedName)
                        task.wait(0.02)
                    end
                end
                task.wait(0.05)
            end
        end)
    end
})

ShopTab:Toggle({
    Title = "Auto Buy All Seeds",
    Value = false,
    Callback = function(Value)
        _G.AutoBuyAllSeeds = Value
        task.spawn(function()
            while _G.AutoBuyAllSeeds do
                for _, seedName in ipairs(AllSeeds) do
                    if not _G.AutoBuyAllSeeds then break end
                    buySeedFast(seedName)
                    task.wait(0.02)
                end
                task.wait(0.1)
            end
        end)
    end
})

---------------------------------------------------------
-- TAB: SPEED
---------------------------------------------------------
_G.WalkSpeedValue = 16
_G.ActivateSpeed = false

SpeedTab:Slider({
    Title = "WalkSpeed",
    Desc = "Kéo để chỉnh tốc độ chạy",
    Min = 1,
    Max = 100,
    Value = 16,
    Callback = function(Value)
        _G.WalkSpeedValue = Value
        if _G.ActivateSpeed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = _G.WalkSpeedValue
        end
    end
})

SpeedTab:Toggle({
    Title = "Activate Speed",
    Desc = "Bật/Tắt tốc độ di chuyển",
    Value = false,
    Callback = function(Value)
        _G.ActivateSpeed = Value
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value and _G.WalkSpeedValue or 16
        end
    end
})

RunService.Stepped:Connect(function()
    if _G.ActivateSpeed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if LocalPlayer.Character.Humanoid.WalkSpeed ~= _G.WalkSpeedValue then
            LocalPlayer.Character.Humanoid.WalkSpeed = _G.WalkSpeedValue
        end
    end
end)

---------------------------------------------------------
-- TAB: MISC
---------------------------------------------------------
MiscTab:Toggle({
    Title = "Hide Others Garden",
    Desc = "Ẩn toàn bộ vườn người khác",
    Value = false,
    Callback = function(Value)
        local gardens = workspace:FindFirstChild("Gardens")
        if gardens then
            for _, obj in pairs(gardens:GetChildren()) do
                local isMyPlot = (_G.MyPlot and obj == _G.MyPlot)
                if not isMyPlot then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("BasePart") then
                            child.Transparency = Value and 1 or 0
                            child.CanCollide = not Value
                        end
                    end
                end
            end
        end
    end
})

MiscTab:Toggle({
    Title = "Hide Your Garden",
    Desc = "Ẩn vườn bản thân",
    Value = false,
    Callback = function(Value)
        if _G.MyPlot then
            for _, child in pairs(_G.MyPlot:GetDescendants()) do
                if child:IsA("BasePart") then
                    child.Transparency = Value and 1 or 0
                    child.CanCollide = not Value
                end
            end
        end
    end
})

MiscTab:Button({
    Title = "FPS BOOSTER",
    Desc = "Xóa Texture/Bóng để tăng FPS",
    Callback = function()
        local Terrain = workspace:FindFirstChildOfClass('Terrain')
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
        end
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FogEnd = 9e9
        
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
        WindUI:Notify({ Title = "FPS BOOSTER", Content = "Đã tối ưu FPS!", Duration = 3 })
    end
})

-- AFK SCREEN
local AFKGui = nil
local AFKTimerThread = nil
local AFKKeyThread = nil
local AFKSeconds = 0

local function createAFKScreen()
    if AFKGui then AFKGui:Destroy() end

    AFKGui = Instance.new("ScreenGui")
    AFKGui.Name = "Gemini_AFK_Screen_Minimal"
    AFKGui.ResetOnSpawn = false
    AFKGui.IgnoreGuiInset = true
    AFKGui.DisplayOrder = 1

    local parentTarget = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    AFKGui.Parent = parentTarget

    local WhiteFrame = Instance.new("Frame")
    WhiteFrame.Size = UDim2.fromScale(1, 1)
    WhiteFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    WhiteFrame.BorderSizePixel = 0
    WhiteFrame.Active = false
    WhiteFrame.ZIndex = 1
    WhiteFrame.Parent = AFKGui

    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, -40, 0, 80)
    InfoLabel.Position = UDim2.fromScale(0.5, 0.5)
    InfoLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "🍁 0 | FPS: 60 | AFK:0:00:00"
    InfoLabel.TextColor3 = Color3.fromRGB(15, 15, 15)
    InfoLabel.TextSize = 24
    InfoLabel.TextWrapped = true
    InfoLabel.Font = Enum.Font.SourceSansBold
    InfoLabel.ZIndex = 2
    InfoLabel.Parent = WhiteFrame

    AFKSeconds = 0
    AFKTimerThread = task.spawn(function()
        while _G.AntiAFK do
            local fps = math.floor(1 / math.max(RunService.RenderStepped:Wait(), 0.001))
            local leaves = getLeavesValue()
            local hrs = math.floor(AFKSeconds / 3600)
            local mins = math.floor((AFKSeconds % 3600) / 60)
            local secs = AFKSeconds % 60
            InfoLabel.Text = string.format("🍁 %s  |  FPS: %d  |  AFK:%d:%02d:%02d", formatNumber(leaves), fps, hrs, mins, secs)
            task.wait(1)
            AFKSeconds = AFKSeconds + 1
        end
    end)

    AFKKeyThread = task.spawn(function()
        while _G.AntiAFK do
            task.wait(60)
            if _G.AntiAFK then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.1)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end)
            end
        end
    end)
end

local function removeAFKScreen()
    if AFKGui then AFKGui:Destroy() AFKGui = nil end
    if AFKTimerThread then task.cancel(AFKTimerThread) AFKTimerThread = nil end
    if AFKKeyThread then task.cancel(AFKKeyThread) AFKKeyThread = nil end
end

MiscTab:Toggle({
    Title = "Anti-AFK (Màn Hình Trắng)",
    Desc = "Màn hình trắng & Tự động chống văng AFK",
    Value = false,
    Callback = function(Value)
        _G.AntiAFK = Value
        if Value then createAFKScreen() else removeAFKScreen() end
    end
})
