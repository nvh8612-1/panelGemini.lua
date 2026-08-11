-- ====================================================================
-- GEMINI HUB - GAG2
-- Full Version (Fixed Anti-AFK 100% No Kick / Standing Still)
-- Script hợp nhất bởi WhiteSs
-- ====================================================================

local Players = game:GetService("Players")
local StatsService = game:GetService("Stats")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- ====================================================================
-- WINDUI
-- ====================================================================

local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "Gemini Hub",
    Author = "WhiteSs",
    Icon = "sprout",
    Folder = "GeminiGAG2",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark"
})

task.spawn(function()
    task.wait(0.5)

    pcall(function()
        local parentTarget = (gethui and gethui()) or CoreGui

        for _, gui in ipairs(parentTarget:GetChildren()) do
            if gui:IsA("ScreenGui") then
                gui.DisplayOrder = 9999
            end
        end
    end)
end)

-- ====================================================================
-- TABS
-- ====================================================================

local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
local AutoTab = Window:Tab({ Title = "Auto", Icon = "repeat" })
local ShopTab = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })
local GearTab = Window:Tab({ Title = "Gear", Icon = "wrench" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "sliders" })

-- ====================================================================
-- SEEDS
-- ====================================================================

local AllSeeds = {
    "Carrot", "Strawberry", "Blueberry", "Tulip", "Tomato", "Apple", "Bamboo", "Corn", "Cactus", "Pineapple",
    "Mushroom", "Banana", "Grape", "Coconut", "Green Bean", "Mango", "Rocket Pop", "Dragon Fruit", "Acorn",
    "Cherry", "Sunflower", "Fire Fern", "Venus Fly Trap", "Pomegranate", "Poison Apple", "Venom Spitter", "Moon Bloom",
    "Sun Bloom", "Hypno Bloom", "Dragon's Breath", "Star Fruit", "Conifer Cone", "Amber Cranberry", "Atlantic Giant Pumpkin",
    "Maple Coconut", "Maple Green Bean", "Maple Carrot", "Maple Strawberry", "Maple Blueberry", "Maple Tulip", "Maple Tomato", 
    "Maple Apple", "Maple Bamboo", "Maple Corn", "Maple Cactus", "Maple Pineapple", "Maple Mushroom", "Maple Banana", 
    "Maple Grape", "Maple Mango", "Maple Dragon Fruit", "Maple Acorn", "Maple Cherry", "Maple Sunflower", "Maple Venus Fly Trap", 
    "Maple Pomegranate", "Maple Poison Apple", "Maple Venom Spitter"
}

-- ====================================================================
-- PLOT
-- ====================================================================

_G.MyPlot = nil
local SavedPlotName = "workspace.Gardens.Plot1"

local function findMyPlot()
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return nil end

    for _, plot in ipairs(gardens:GetChildren()) do
        local owner = plot:GetAttribute("Owner")
        local userId = plot:GetAttribute("OwnerUserId")

        if owner and tostring(owner) == LocalPlayer.Name then return plot end
        if userId and tonumber(userId) == LocalPlayer.UserId then return plot end

        local ownerValue = plot:FindFirstChild("Owner") or plot:FindFirstChild("OwnerName") or plot:FindFirstChild("Player")
        if ownerValue then
            if ownerValue:IsA("StringValue") and ownerValue.Value == LocalPlayer.Name then return plot end
            if ownerValue:IsA("ObjectValue") and ownerValue.Value == LocalPlayer then return plot end
        end
    end

    return gardens:FindFirstChild("Plot1") or gardens:FindFirstChild("plot1") or gardens:GetChildren()[1]
end

_G.MyPlot = findMyPlot()
if _G.MyPlot then
    SavedPlotName = "workspace.Gardens." .. _G.MyPlot.Name
end

-- ====================================================================
-- UTIL
-- ====================================================================

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

-- ====================================================================
-- MAIN
-- ====================================================================

local MainSection = MainTab:Section({ Title = "Thông Tin Hub" })

MainSection:Paragraph({ 
    Title = "Gemini Hub", 
    Desc = "Gemini và 1 cổ đông Chat GPT đã hỗ trợ Hub này\n=> WhiteSs" 
})

local StatusParagraph = MainSection:Paragraph({ Title = "📊 Status Hệ Thống", Desc = "Đang tải..." })

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local ping = 0
            pcall(function()
                ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)

            local fps = 0
            local dt = RunService.RenderStepped:Wait()
            if dt > 0 then fps = math.floor(1 / dt) end

            StatusParagraph:SetDesc(
                string.format(
                    "👤 Người chơi: %s\n\n🍁 Leaves: %s\n\n⚡ FPS: %d | Ping: %dms\n\n🏡 Plot: %s\n\nGemini Hub",
                    LocalPlayer.Name, formatNumber(getLeavesValue()), fps, ping, SavedPlotName
                )
            )
        end)
    end
end)

-- ====================================================================
-- AUTO / HARVEST
-- ====================================================================

local AutoSection1 = AutoTab:Section({ Title = "🌱 Thu Hoạch & Hạt Giống" })

_G.FruitBatchLimit = 1
_G.AutoHarvest = false
_G.AutoCollectSeed = false
_G.LookAtTarget = false
_G.HarvestSelectedSeeds = {}

local HarvestDropdown

local function filterHarvestSeeds(filterType)
    local filtered = {}
    for _, name in ipairs(AllSeeds) do
        local lowerName = string.lower(name)
        local isMaple = string.find(lowerName, "maple", 1, true) ~= nil
        local isAtlantic = lowerName == "atlantic giant pumpkin"

        if filterType == "All" then
            table.insert(filtered, name)
        elseif filterType == "Normal" then
            if not isMaple and not isAtlantic then table.insert(filtered, name) end
        elseif filterType == "Maple" then
            if isMaple or isAtlantic then table.insert(filtered, name) end
        end
    end
    return filtered
end

AutoSection1:Dropdown({
    Title = "Harvest Seed Filter",
    Desc = "Bộ lọc riêng cho Harvest",
    Values = { "All", "Normal", "Maple" },
    Value = "All",
    Callback = function(Value)
        local list = filterHarvestSeeds(Value)
        _G.HarvestSelectedSeeds = {}
        if HarvestDropdown then
            pcall(function() HarvestDropdown:SetValues(list) end)
            pcall(function() HarvestDropdown:SetValue({}) end)
        end
    end
})

HarvestDropdown = AutoSection1:Dropdown({
    Title = "Harvest Select",
    Desc = "Bấm 1 lần chọn, bấm lại để bỏ chọn",
    Values = AllSeeds,
    Multi = true,
    Value = {},
    Callback = function(Values)
        if typeof(Values) == "table" then
            _G.HarvestSelectedSeeds = Values
        else
            _G.HarvestSelectedSeeds = {}
        end
    end
})

AutoSection1:Input({
    Title = "FruitHarvest Amount",
    Desc = "Số lượng Harvest mỗi vòng",
    Value = "1",
    Placeholder = "1",
    Callback = function(Text)
        local num = tonumber(Text)
        if num and num > 0 then
            _G.FruitBatchLimit = math.floor(num)
        else
            _G.FruitBatchLimit = 1
        end
    end
})

AutoSection1:Toggle({
    Title = "Look At Plant When Harvest",
    Desc = "Xoay camera về HarvestPart",
    Value = false,
    Callback = function(Value) _G.LookAtTarget = Value end
})

local function lookAtPosition(position)
    if not _G.LookAtTarget then return end
    local camera = workspace.CurrentCamera
    if camera then
        camera.CFrame = CFrame.new(camera.CFrame.Position, position)
    end
end

local function isHarvestSelected(seedName)
    if not seedName then return false end
    for _, selected in ipairs(_G.HarvestSelectedSeeds or {}) do
        if string.lower(tostring(selected)) == string.lower(tostring(seedName)) then
            return true
        end
    end
    return false
end

local function getPlantSeedName(plant)
    if not plant then return nil end
    local attr = plant:GetAttribute("SeedName")
    if attr ~= nil then return tostring(attr) end

    local value = plant:FindFirstChild("SeedName", true)
    if value and value:IsA("StringValue") then return tostring(value.Value) end

    local attrName = plant:GetAttribute("Name")
    if attrName ~= nil then return tostring(attrName) end

    return plant.Name
end

local function fireHarvestFromPlant(plant)
    if not plant then return false end
    local harvestPart = plant:FindFirstChild("HarvestPart", true)
    if not harvestPart then return false end

    local harvestPrompt = harvestPart:FindFirstChild("HarvestPrompt", true) or harvestPart:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not harvestPrompt then return false end

    local success = false
    pcall(function()
        if _G.LookAtTarget then
            local basePart = harvestPart:IsA("BasePart") and harvestPart or harvestPart:FindFirstChildWhichIsA("BasePart", true)
            if basePart then lookAtPosition(basePart.Position) end
        end

        pcall(function()
            harvestPrompt.HoldDuration = 0
            harvestPrompt.MaxActivationDistance = 99999
            harvestPrompt.RequiresLineOfSight = false
        end)

        if fireHarvestPrompt then
            fireHarvestPrompt(harvestPrompt)
            success = true
        elseif fireproximityprompt then
            fireproximityprompt(harvestPrompt)
            success = true
        end
    end)

    return success
end

local function processHarvest()
    if not _G.AutoHarvest or #(_G.HarvestSelectedSeeds or {}) == 0 then return end
    if not _G.MyPlot then _G.MyPlot = findMyPlot() end

    local plot = _G.MyPlot
    if not plot or not plot:FindFirstChild("Plants") then return end

    local count = 0
    for _, plant in ipairs(plot.Plants:GetChildren()) do
        if not _G.AutoHarvest then break end
        local seedName = getPlantSeedName(plant)
        if seedName and isHarvestSelected(seedName) then
            if fireHarvestFromPlant(plant) then
                count += 1
                if count >= _G.FruitBatchLimit then break end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if _G.AutoHarvest then processHarvest() end
end)

AutoSection1:Toggle({
    Title = "Auto Harvest",
    Desc = "Fire HarvestPrompt theo Seed",
    Value = false,
    Callback = function(Value) _G.AutoHarvest = Value end
})

-- ====================================================================
-- AUTO COLLECT
-- ====================================================================

local function triggerPickupPrompt(prompt)
    if not prompt then return end
    pcall(function()
        pcall(function()
            prompt.HoldDuration = 0
            prompt.MaxActivationDistance = 99999
            prompt.RequiresLineOfSight = false
        end)

        if firePickupPrompt then
            firePickupPrompt(prompt)
        elseif fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)
end

RunService.Heartbeat:Connect(function()
    if not _G.AutoCollectSeed then return end
    pcall(function()
        local folder = workspace:FindFirstChild("DroppedItems")
        if not folder then return end

        for _, item in ipairs(folder:GetChildren()) do
            if not _G.AutoCollectSeed then break end
            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then triggerPickupPrompt(prompt) end
        end
    end)
end)

AutoSection1:Toggle({
    Title = "Auto Collect Seed",
    Desc = "Tự động nhặt Seed",
    Value = false,
    Callback = function(Value) _G.AutoCollectSeed = Value end
})

-- ====================================================================
-- AUTO SELL
-- ====================================================================

local AutoSection2 = AutoTab:Section({ Title = "💰 Tự Động Bán" })
_G.DelaySell = 0
_G.AutoSell = false

AutoSection2:Input({
    Title = "Delay Sell",
    Desc = "Mặc định: 0",
    Value = "0",
    Placeholder = "0",
    Callback = function(Text)
        local num = tonumber(string.gsub(Text, ",", "."))
        _G.DelaySell = (num and num >= 0) and num or 0
    end
})

AutoSection2:Toggle({
    Title = "Auto Sell Inventory",
    Desc = "Tự động bán toàn bộ Inventory",
    Value = false,
    Callback = function(Value)
        _G.AutoSell = Value
        if not Value then return end

        task.spawn(function()
            local Networking
            pcall(function()
                Networking = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
            end)

            while _G.AutoSell do
                pcall(function()
                    if Networking and Networking.NPCS and Networking.NPCS.SellAll then
                        Networking.NPCS.SellAll:Fire()
                    end
                end)
                task.wait(_G.DelaySell or 0)
            end
        end)
    end
})

-- ====================================================================
-- SPEED
-- ====================================================================

local SpeedSection = AutoTab:Section({ Title = "⚡ Speed" })
_G.WalkSpeed = 1
_G.ActivateSpeed = false

SpeedSection:Slider({
    Title = "Tốc độ Di chuyển",
    Desc = "Humanoid.WalkSpeed: 1 → 36",
    Step = 1,
    Value = { Min = 1, Max = 36, Default = 1 },
    Callback = function(Value)
        _G.WalkSpeed = math.clamp(tonumber(Value) or 1, 1, 36)
    end
})

SpeedSection:Toggle({
    Title = "Activate Speed",
    Desc = "Áp dụng Humanoid.WalkSpeed",
    Value = false,
    Callback = function(Value)
        _G.ActivateSpeed = Value
        if not Value then
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.WalkSpeed = 16 end
            end
        end
    end
})

RunService.Heartbeat:Connect(function()
    if not _G.ActivateSpeed then return end
    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = math.clamp(_G.WalkSpeed or 1, 1, 36)
    end
end)

-- ====================================================================
-- SHOP TAB
-- ====================================================================

local PacketRemote = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent")
local ShopSection = ShopTab:Section({ Title = "🌱 Cửa Hàng Hạt Giống" })

_G.SelectedSeeds = {}
_G.AutoBuySeed = false
_G.AutoBuyAllSeeds = false

local ShopSeedDropdown

local function filterShopSeeds(filterType)
    local filtered = {}
    for _, name in ipairs(AllSeeds) do
        local lowerName = string.lower(name)
        local isMaple = string.find(lowerName, "maple", 1, true) ~= nil
        local isAtlantic = lowerName == "atlantic giant pumpkin"

        if filterType == "All" then
            table.insert(filtered, name)
        elseif filterType == "Normal" then
            if not isMaple and not isAtlantic then table.insert(filtered, name) end
        elseif filterType == "Maple" then
            if isMaple or isAtlantic then table.insert(filtered, name) end
        end
    end
    return filtered
end

ShopSection:Dropdown({
    Title = "Shop Seed Filter",
    Desc = "Lọc Normal / Maple",
    Values = { "All", "Normal", "Maple" },
    Value = "All",
    Callback = function(Value)
        local list = filterShopSeeds(Value)
        _G.SelectedSeeds = {}
        if ShopSeedDropdown then
            pcall(function() ShopSeedDropdown:SetValues(list) end)
            pcall(function() ShopSeedDropdown:SetValue({}) end)
        end
    end
})

ShopSeedDropdown = ShopSection:Dropdown({
    Title = "Chọn Seed Shop",
    Desc = "Multi-Select (Bấm 1 lần chọn, bấm lại để bỏ)",
    Values = AllSeeds,
    Multi = true,
    Value = {},
    Callback = function(Values)
        if typeof(Values) == "table" then
            _G.SelectedSeeds = Values
        else
            _G.SelectedSeeds = {}
        end
    end
})

local function buySeedFast(seedName)
    pcall(function()
        local isMaple = string.find(string.lower(seedName), "maple") ~= nil
        local b = buffer.create(3 + #seedName)
        buffer.writeu8(b, 0, isMaple and 160 or 159)
        buffer.writeu8(b, 1, 0)
        buffer.writeu8(b, 2, #seedName)
        buffer.writestring(b, 3, seedName)
        PacketRemote:FireServer(b)
    end)
end

ShopSection:Toggle({
    Title = "Auto Buy Selected Seeds",
    Desc = "Mua các Seed đã chọn",
    Value = false,
    Callback = function(Value)
        _G.AutoBuySeed = Value
        if not Value then return end
        task.spawn(function()
            while _G.AutoBuySeed do
                for _, seedName in ipairs(_G.SelectedSeeds or {}) do
                    if not _G.AutoBuySeed then break end
                    buySeedFast(seedName)
                    task.wait(0.02)
                end
                task.wait(0.05)
            end
        end)
    end
})

ShopSection:Toggle({
    Title = "Auto Buy All Seeds",
    Desc = "Mua toàn bộ Seed",
    Value = false,
    Callback = function(Value)
        _G.AutoBuyAllSeeds = Value
        if not Value then return end
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

-- ====================================================================
-- GEAR TAB
-- ====================================================================

local GearSection = GearTab:Section({ Title = "🔧 Cửa Hàng Gear" })

local AllGears = {
    "Syrup Watering Can",
    "Syrup Sprinkler",
    "Super Syrup Watering Can",
    "Super Syrup Sprinkler"
}

_G.SelectedGears = {}
_G.AutoBuyGear = false
_G.AutoBuyAllGears = false

local function buyGearFast(gearName)
    pcall(function()
        local b = buffer.create(3 + #gearName)
        buffer.writeu8(b, 0, 164)
        buffer.writeu8(b, 1, 0)
        buffer.writeu8(b, 2, #gearName)
        buffer.writestring(b, 3, gearName)
        PacketRemote:FireServer(b)
    end)
end

GearSection:Dropdown({
    Title = "Chọn Gear",
    Desc = "Multi-Select",
    Values = AllGears,
    Multi = true,
    Value = {},
    Callback = function(Values)
        if typeof(Values) == "table" then
            _G.SelectedGears = Values
        else
            _G.SelectedGears = {}
        end
    end
})

GearSection:Toggle({
    Title = "Auto Buy Selected Gear",
    Desc = "Mua Gear đã chọn",
    Value = false,
    Callback = function(Value)
        _G.AutoBuyGear = Value
        if not Value then return end
        task.spawn(function()
            while _G.AutoBuyGear do
                for _, gearName in ipairs(_G.SelectedGears or {}) do
                    if not _G.AutoBuyGear then break end
                    buyGearFast(gearName)
                    task.wait(0.02)
                end
                task.wait(0.05)
            end
        end)
    end
})

GearSection:Toggle({
    Title = "Auto Buy All Gear",
    Desc = "Mua toàn bộ Gear",
    Value = false,
    Callback = function(Value)
        _G.AutoBuyAllGears = Value
        if not Value then return end
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

-- ====================================================================
-- MISC TAB (NÂNG CẤP ANTI-AFK CHỐNG KICK BẰNG VIRTUAL INPUT & IDLED HOOK)
-- ====================================================================

local MiscSection1 = MiscTab:Section({ Title = "🌳 Tối Ưu Vườn" })

MiscSection1:Toggle({
    Title = "Hide Others Garden",
    Desc = "Ẩn Garden người khác",
    Value = false,
    Callback = function(Value)
        local gardens = workspace:FindFirstChild("Gardens")
        if not gardens then return end

        for _, obj in ipairs(gardens:GetChildren()) do
            local isMyPlot = _G.MyPlot and obj == _G.MyPlot
            if not isMyPlot then
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("BasePart") then
                        child.Transparency = Value and 1 or 0
                        child.CanCollide = not Value
                    end
                end
            end
        end
    end
})

MiscSection1:Toggle({
    Title = "Hide Your Garden",
    Desc = "Ẩn Garden của bạn",
    Value = false,
    Callback = function(Value)
        if not _G.MyPlot then return end
        for _, child in ipairs(_G.MyPlot:GetDescendants()) do
            if child:IsA("BasePart") then
                child.Transparency = Value and 1 or 0
                child.CanCollide = not Value
            end
        end
    end
})

local MiscSection2 = MiscTab:Section({ Title = "🚀 Tối Ưu & Chống AFK" })

MiscSection2:Button({
    Title = "FPS BOOSTER",
    Desc = "Giảm Texture / Effect / Shadow",
    Callback = function()
        pcall(function()
            local Terrain = workspace:FindFirstChildOfClass("Terrain")
            if Terrain then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 1
            end

            Lighting.GlobalShadows = false

            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                elseif obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end

            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
        end)
    end
})

-- HỆ THỐNG ANTI-AFK ĐÃ TỐI ƯU CHỐNG KICK
_G.AntiAFK = true

MiscSection2:Toggle({
    Title = "Anti-AFK (No Kick)",
    Desc = "Chống văng 100% (Giữ nhân vật đứng yên)",
    Value = true,
    Callback = function(Value)
        _G.AntiAFK = Value
    end
})

-- 1. Bắt sự kiện Idled mặc định
LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0,0))
        end)
    end
end)

-- 2. Vòng lặp Virtual Input mô phỏng tương tác nền (Mỗi 60s)
task.spawn(function()
    while true do
        task.wait(60)
        if _G.AntiAFK then
            pcall(function()
                -- Gửi tín hiệu giữ nhịp kết nối nhưng KHÔNG làm di chuyển nhân vật
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Unknown, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Unknown, false, game)
            end)
        end
    end
end)
