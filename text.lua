-- ====================================================================
-- PANEL GEMINI - GAG2 (Full Seeds + Gear Tab + Packet Buffer Fast & Smooth)
-- Script được làm bởi WhiteSs
-- ====================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StatsService = game:GetService("Stats")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Link WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- 1. TẠO WINDOW CHÍNH
local Window = WindUI:CreateWindow({
    Title = "Panel Gemini",
    Author = "WhiteSs",
    Icon = "sprout",
    Folder = "GeminiGAG2",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark"
})

-- 2. KHỞI TẠO TABS
local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
local AutoTab = Window:Tab({ Title = "Auto", Icon = "repeat" })
local ShopTab = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })
local GearTab = Window:Tab({ Title = "Gear", Icon = "wrench" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "sliders" })

-- =========================================================
-- LOGIC DÒ PLOT CHUẨN ĐÉT QUA ATTRIBUTES (OWNER & OWNERUSERID)
-- =========================================================
_G.MyPlot = nil
local SavedPlotName = "Không tìm thấy"

local function findMyPlot()
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return nil end

    for _, plot in ipairs(gardens:GetChildren()) do
        -- 1. Đọc Attributes chuẩn từ game (Owner / OwnerUserId)
        local attrOwner = plot:GetAttribute("Owner")
        local attrUserId = plot:GetAttribute("OwnerUserId")

        if attrOwner and tostring(attrOwner) == LocalPlayer.Name then
            return plot
        end
        if attrUserId and tonumber(attrUserId) == LocalPlayer.UserId then
            return plot
        end

        -- 2. Dự phòng: Kiểm tra Value Object
        local ownerValue = plot:FindFirstChild("Owner") or plot:FindFirstChild("OwnerName") or plot:FindFirstChild("Player")
        if ownerValue then
            if (ownerValue:IsA("StringValue") and ownerValue.Value == LocalPlayer.Name) or
               (ownerValue:IsA("ObjectValue") and ownerValue.Value == LocalPlayer) then
                return plot
            end
        end
    end

    -- 3. Dự phòng: Đo khoảng cách tới nhân vật
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
        if closestPlot and shortestDistance < 100 then
            return closestPlot
        end
    end

    return gardens:FindFirstChild("Plot1") or gardens:FindFirstChild("plot1") or gardens:GetChildren()[1]
end

-- Chạy dò 1 lần duy nhất khi load Script
_G.MyPlot = findMyPlot()
if _G.MyPlot then
    SavedPlotName = "workspace.Gardens." .. _G.MyPlot.Name
end

---------------------------------------------------------
-- MỤC: MAIN
---------------------------------------------------------
local MainSection = MainTab:Section({ Title = "Thông Tin Hub" })

MainSection:Paragraph({
    Title = "Gemini GAG2",
    Desc = "Script được làm bởi WhiteSs"
})

local StatusParagraph = MainSection:Paragraph({
    Title = "📊 Status Hệ Thống",
    Desc = "Đang tải thông số..."
})

-- Vòng lặp Realtime FPS / Ping / Status Plot
task.spawn(function()
    while task.wait(0.5) do
        local fps = math.floor(1 / math.max(RunService.RenderStepped:Wait(), 0.001))
        local ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
        local ms = math.floor(RunService.RenderStepped:Wait() * 1000)

        StatusParagraph:SetDesc(string.format(
            "FPS: %d | Ping: %dms | MS: %dms\nPlot: %s\nScript được làm bởi WhiteSs | Gemini GAG2",
            fps, ping, ms, SavedPlotName
        ))
    end
end)

---------------------------------------------------------
-- MỤC: AUTO
---------------------------------------------------------
local AutoSection1 = AutoTab:Section({ Title = "Thu Hoạch & Hạt Giống" })

_G.FruitBatchLimit = 1
_G.AutoHarvest = false
_G.AutoCollectSeed = false

AutoSection1:Input({
    Title = "FruitHarvest Amount",
    Desc = "Số lượng quả thu hoạch / đợt (Mặc định: 1)",
    Value = "1",
    Placeholder = "Nhập số lượng...",
    Callback = function(Text)
        local num = tonumber(Text)
        _G.FruitBatchLimit = (num and num > 0) and math.floor(num) or 1
    end
})

-- AUTO HARVEST LOGIC
local function triggerHarvestPrompt(prompt)
    if not prompt then return end
    pcall(function()
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 9999
        prompt.RequiresLineOfSight = false
        
        if fireHarvestPrompt then
            fireHarvestPrompt(prompt)
        elseif fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)
end

local function processHarvest()
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

                    local harvestPart = fruit:FindFirstChild("HarvestPart")
                    local harvestPrompt = harvestPart and harvestPart:FindFirstChild("HarvestPrompt")

                    if harvestPrompt then
                        triggerHarvestPrompt(harvestPrompt)
                        count = count + 1
                        if count >= _G.FruitBatchLimit then break end
                    end
                end
            end
            if count >= _G.FruitBatchLimit then break end
        end
    end)
end

task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoHarvest then processHarvest() end
    end
end)

AutoSection1:Toggle({
    Title = "Auto Harvest",
    Value = false,
    Callback = function(Value)
        _G.AutoHarvest = Value
    end
})

-- AUTO COLLECT SEED LOGIC
local function triggerPickupPrompt(prompt)
    if not prompt then return end
    pcall(function()
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 9999
        prompt.RequiresLineOfSight = false
        
        if firePickupPrompt then
            firePickupPrompt(prompt)
        elseif fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)
end

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
    local conn = tween.Completed:Connect(function() completed = true end)

    while not completed do
        if not _G.AutoCollectSeed then
            tween:Cancel()
            break
        end
        task.wait(0.05)
    end
    if conn then conn:Disconnect() end

    if prompt and _G.AutoCollectSeed then
        triggerPickupPrompt(prompt)
    end
end

task.spawn(function()
    while task.wait(0.3) do
        if _G.AutoCollectSeed then
            pcall(function()
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                local droppedFolder = workspace:FindFirstChild("DroppedItems")

                if rootPart and droppedFolder then
                    for _, item in ipairs(droppedFolder:GetChildren()) do
                        if not _G.AutoCollectSeed then break end

                        local promptAnchor = item:FindFirstChild("PromptAnchor")
                        local pickupPrompt = promptAnchor and promptAnchor:FindFirstChild("PickupPrompt")

                        if promptAnchor and pickupPrompt then
                            local distance = (rootPart.Position - promptAnchor.Position).Magnitude
                            if distance <= 100 then
                                tweenToAndPick(promptAnchor.Position, pickupPrompt)
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

AutoSection1:Toggle({
    Title = "Auto Collect Seed",
    Value = false,
    Callback = function(Value)
        _G.AutoCollectSeed = Value
    end
})

local AutoSection2 = AutoTab:Section({ Title = "Tự Động Bán Đồ" })

_G.DelaySell = 0.1
AutoSection2:Input({
    Title = "DelaySell",
    Desc = "Thời gian delay bán (Mặc định: 0.1)",
    Value = "0.1",
    Placeholder = "0.1 hoặc 0,1",
    Callback = function(Text)
        local sanitizedText = string.gsub(Text, ",", ".")
        local num = tonumber(Text)
        _G.DelaySell = (num and num >= 0) and num or 0.1
    end
})

_G.AutoSell = false
AutoSection2:Toggle({
    Title = "Auto Sell Inventory",
    Value = false,
    Callback = function(Value)
        _G.AutoSell = Value
        task.spawn(function()
            local Networking
            pcall(function()
                Networking = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
            end)

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
-- CHUNG: KẾT NỐI REMOTE PACKET
---------------------------------------------------------
local PacketRemote = ReplicatedStorage:WaitForChild("SharedModules")
    :WaitForChild("Packet")
    :WaitForChild("RemoteEvent")

---------------------------------------------------------
-- MỤC: SHOP (HẠT GIỐNG - HEADER \159\000)
---------------------------------------------------------
local ShopSection = ShopTab:Section({ Title = "Cửa Hàng Hạt Giống" })

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
    "Maple Pomegranate", "Maple Poison Apple", "Maple Venom Spitter"
}

_G.SelectedSeeds = {}
_G.AutoBuySeed = false
_G.AutoBuyAllSeeds = false

-- Cache sẵn Buffer Hạt Giống (Header \159\000)
local SeedBuffers = {}
for _, name in ipairs(AllSeeds) do
    local payload = "\159\000" .. string.char(#name) .. name
    SeedBuffers[name] = buffer.fromstring(payload)
end

local function buySeedFast(seedName)
    local buf = SeedBuffers[seedName]
    if buf then
        PacketRemote:FireServer(buf)
    end
end

-- Lọc loại Hạt
local function filterSeeds(filterType)
    local filtered = {}
    for _, name in ipairs(AllSeeds) do
        local isMaple = string.find(name, "Maple") ~= nil
        if filterType == "Normal" and not isMaple then
            table.insert(filtered, name)
        elseif filterType == "Maple" and isMaple then
            table.insert(filtered, name)
        elseif filterType == "All" then
            table.insert(filtered, name)
        end
    end
    return filtered
end

local SeedDropdown

ShopSection:Dropdown({
    Title = "Lọc Loại Hạt Giống",
    Desc = "Lọc hạt Thường (Normal) hoặc Hạt Phong (Maple)",
    Values = { "All", "Normal", "Maple" },
    Value = "All",
    Callback = function(Value)
        local newList = filterSeeds(Value)
        if SeedDropdown then
            SeedDropdown:SetValues(newList)
        end
    end
})

SeedDropdown = ShopSection:Dropdown({
    Title = "Chọn Hạt Giống (Multi-Select)",
    Desc = "Tích chọn 1 hoặc nhiều hạt giống muốn mua",
    Values = AllSeeds,
    Multi = true,
    Value = { AllSeeds[1] },
    Callback = function(Values)
        _G.SelectedSeeds = Values
    end
})

ShopSection:Toggle({
    Title = "Auto Buy Selected Seeds",
    Desc = "Mua lặp tất cả các hạt đã chọn",
    Value = false,
    Callback = function(Value)
        _G.AutoBuySeed = Value
        task.spawn(function()
            while _G.AutoBuySeed do
                if _G.SelectedSeeds and #_G.SelectedSeeds > 0 then
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

ShopSection:Toggle({
    Title = "Auto Buy All Seeds",
    Desc = "Duyệt mua toàn bộ danh sách hạt giống trong shop",
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
-- MỤC: GEAR (DỤNG CỤ - HEADER \163\000)
---------------------------------------------------------
local GearSection = GearTab:Section({ Title = "Cửa Hàng Dụng Cụ (Gear Shop)" })

local AllGears = {
    "Syrup Watering Can",
    "Syrup Sprinkler"
}

_G.SelectedGears = {}
_G.AutoBuyGear = false
_G.AutoBuyAllGears = false

-- Cache sẵn Buffer Gear (Header \163\000)
local GearBuffers = {}
for _, name in ipairs(AllGears) do
    local payload = "\163\000" .. string.char(#name) .. name
    GearBuffers[name] = buffer.fromstring(payload)
end

local function buyGearFast(gearName)
    local buf = GearBuffers[gearName]
    if buf then
        PacketRemote:FireServer(buf)
    end
end

-- Dropdown Chọn Nhiều Gear
GearSection:Dropdown({
    Title = "Chọn Gear (Multi-Select)",
    Desc = "Tích chọn 1 hoặc nhiều Dụng Cụ muốn mua",
    Values = AllGears,
    Multi = true,
    Value = { AllGears[1] },
    Callback = function(Values)
        _G.SelectedGears = Values
    end
})

-- Toggle Mua Gear Được Chọn
GearSection:Toggle({
    Title = "Auto Buy Selected Gear",
    Desc = "Mua lặp tất cả các Gear đã tích chọn",
    Value = false,
    Callback = function(Value)
        _G.AutoBuyGear = Value
        task.spawn(function()
            while _G.AutoBuyGear do
                if _G.SelectedGears and #_G.SelectedGears > 0 then
                    for _, gearName in ipairs(_G.SelectedGears) do
                        if not _G.AutoBuyGear then break end
                        buyGearFast(gearName)
                        task.wait(0.02)
                    end
                end
                task.wait(0.05)
            end
        end)
    end
})

-- Toggle Mua Toàn Bộ Gear
GearSection:Toggle({
    Title = "Auto Buy All Gear",
    Desc = "Tự động mua toàn bộ danh sách Dụng Cụ (Gear)",
    Value = false,
    Callback = function(Value)
        _G.AutoBuyAllGears = Value
        task.spawn(function()
            while _G.AutoBuyAllGears do
                for _, gearName in ipairs(AllGears) do
                    if not _G.AutoBuyAllGears then break end
                    buyGearFast(gearName)
                    task.wait(0.02)
                end
                task.wait(0.1)
            end
        end)
    end
})

---------------------------------------------------------
-- MỤC: MISC
---------------------------------------------------------
local MiscSection1 = MiscTab:Section({ Title = "Tối Ưu Vườn (Garden Visibility)" })

-- Hide Others Garden
MiscSection1:Toggle({
    Title = "Hide Others Garden",
    Desc = "Tàng hình toàn bộ garden xung quanh, không tàng hình vườn bản thân",
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

-- Hide You Garden
MiscSection1:Toggle({
    Title = "Hide You Garden",
    Desc = "Tàng hình vườn của bản thân",
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

local MiscSection2 = MiscTab:Section({ Title = "Tối Ưu Đồ Họa" })

MiscSection2:Button({
    Title = "FPS BOOSTER",
    Desc = "Xóa Texture, Effect, Shadows để tối ưu FPS",
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
        
        WindUI:Notify({ Title = "FPS BOOTER", Content = "Đã tối ưu hóa FPS!", Duration = 3 })
    end
})
