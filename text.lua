-- ====================================================================
-- PANEL GEMINI - GAG2 (Full Seeds + Full Gear + White Screen Anti-AFK Fixed)
-- Script được làm bởi WhiteSs
-- ====================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StatsService = game:GetService("Stats")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
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
local SavedPlotName = "workspace.Gardens.Plot1"

local function findMyPlot()
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return nil end

    for _, plot in ipairs(gardens:GetChildren()) do
        local attrOwner = plot:GetAttribute("Owner")
        local attrUserId = plot:GetAttribute("OwnerUserId")

        if attrOwner and tostring(attrOwner) == LocalPlayer.Name then
            return plot
        end
        if attrUserId and tonumber(attrUserId) == LocalPlayer.UserId then
            return plot
        end

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
        if closestPlot and shortestDistance < 100 then
            return closestPlot
        end
    end

    return gardens:FindFirstChild("Plot1") or gardens:FindFirstChild("plot1") or gardens:GetChildren()[1]
end

_G.MyPlot = findMyPlot()
if _G.MyPlot then
    SavedPlotName = "workspace.Gardens." .. _G.MyPlot.Name
end

-- Hàm lấy giá trị Leaves và định dạng số
local function getLeavesValue()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local leaves = leaderstats:FindFirstChild("Leaves")
        if leaves then
            return leaves.Value
        end
    end
    return 0
end

local function formatNumber(n)
    return tostring(n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

---------------------------------------------------------
-- MỤC: MAIN
---------------------------------------------------------
local MainSection = MainTab:Section({ Title = "Thông Tin Hub" })

MainSection:Paragraph({
    Title = "Panel Gemini | Grow A Garden 2",
    Desc = "=> WhiteSs"
})

local StatusParagraph = MainSection:Paragraph({
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
            "👤 Người chơi: %s\n\n" ..
            "🍁 Leaves : %s\n\n" ..
            "⚡ FPS: %d | Ping: %dms | Frame: %dms\n\n" ..
            "🏡 Vườn (Plot): %s\n\n" ..
            "Trạng thái: Đang hoạt động ổn định\n\n" ..
            "Phiên bản: Gemini GAG2 - Update Fall Harvest\n\n" ..
            "Nâng cấp: Shop,Gear, Chức năng thu hoạch,Bán,Ẩn vường,FPS, Chức năng AFK mới ,...",
            LocalPlayer.Name,
            formatNumber(leaves),
            fps,
            ping,
            ms,
            SavedPlotName
        )

        StatusParagraph:SetDesc(formattedText)
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
        local num = tonumber(sanitizedText)
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
-- MỤC: SHOP
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
-- MỤC: GEAR
---------------------------------------------------------
local GearSection = GearTab:Section({ Title = "Cửa Hàng Dụng Cụ (Gear Shop)" })

local AllGears = {
    "Syrup Watering Can",
    "Syrup Sprinkler",
    "Super Syrup Watering Can",
    "Super Syrup Sprinkler"
}

_G.SelectedGears = {}
_G.AutoBuyGear = false
_G.AutoBuyAllGears = false

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

GearSection:Dropdown({
    Title = "Chọn Gear (Multi-Select)",
    Desc = "Tích chọn Dụng Cụ muốn mua",
    Values = AllGears,
    Multi = true,
    Value = { AllGears[1] },
    Callback = function(Values)
        _G.SelectedGears = Values
    end
})

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

GearSection:Toggle({
    Title = "Auto Buy All Gear",
    Desc = "Tự động mua tất cả loại Syrup Watering Can & Sprinkler",
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

MiscSection1:Toggle({
    Title = "Hide Others Garden",
    Desc = "Tàng hình toàn bộ garden xung quanh",
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

local MiscSection2 = MiscTab:Section({ Title = "Tối Ưu Đồ Họa & Chức Năng AFK" })

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
        
        WindUI:Notify({ Title = "FPS BOOSTER", Content = "Đã tối ưu hóa FPS!", Duration = 3 })
    end
})

-- =========================================================
-- SYSTEM CHỨC NĂNG MÀN HÌNH TRẮNG AFK (ĐÃ FIX TOÀN BỘ LỖI)
-- =========================================================
local AFKGui = nil
local AFKTimerThread = nil
local AFKKeyThread = nil
local AFKSeconds = 0

local function createAFKScreen(onCloseCallback)
    if AFKGui then AFKGui:Destroy() end

    AFKGui = Instance.new("ScreenGui")
    AFKGui.Name = "Gemini_AFK_Screen_Fixed"
    AFKGui.ResetOnSpawn = false
    AFKGui.IgnoreGuiInset = true -- Tràn toàn màn hình đè Topbar
    AFKGui.DisplayOrder = 999999 -- Ưu tiên nổi lên cao nhất

    -- Gắn Gui vào CoreGui hoặc PlayerGui
    local parentTarget = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    AFKGui.Parent = parentTarget

    -- Background Trắng Phủ 100%
    local WhiteFrame = Instance.new("Frame")
    WhiteFrame.Size = UDim2.fromScale(1, 1)
    WhiteFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    WhiteFrame.BorderSizePixel = 0
    WhiteFrame.Active = true
    WhiteFrame.ZIndex = 9999
    WhiteFrame.Parent = AFKGui

    -- Container căn giữa màn hình
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 250)
    Container.Position = UDim2.fromScale(0.5, 0.5)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.BackgroundTransparency = 1
    Container.ZIndex = 10000
    Container.Parent = WhiteFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 15)
    UIListLayout.Parent = Container

    -- 1. Text AFK 💤
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.LayoutOrder = 1
    TitleLabel.Size = UDim2.new(1, 0, 0, 50)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "AFK 💤"
    TitleLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
    TitleLabel.TextSize = 40
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.ZIndex = 10001
    TitleLabel.Parent = Container

    -- 2. Text Thông Số 🍁 | FPS | AFK
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.LayoutOrder = 2
    InfoLabel.Size = UDim2.new(1, 0, 0, 40)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "🍁 0 | FPS: 60 | AFK: 0:00:00"
    InfoLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
    InfoLabel.TextSize = 22
    InfoLabel.Font = Enum.Font.SourceSansMedium
    InfoLabel.ZIndex = 10001
    InfoLabel.Parent = Container

    -- 3. Nút | Thoát AFK |
    local ExitButton = Instance.new("TextButton")
    ExitButton.LayoutOrder = 3
    ExitButton.Size = UDim2.new(0, 180, 0, 45)
    ExitButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    ExitButton.BorderSizePixel = 0
    ExitButton.Text = "| Thoát AFK |"
    ExitButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    ExitButton.TextSize = 18
    ExitButton.Font = Enum.Font.SourceSansBold
    ExitButton.ZIndex = 10002
    ExitButton.Parent = Container

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = ExitButton

    ExitButton.MouseButton1Click:Connect(function()
        if onCloseCallback then
            onCloseCallback()
        end
    end)

    -- Vòng lặp cập nhật thời gian
    AFKSeconds = 0
    AFKTimerThread = task.spawn(function()
        while _G.AntiAFK do
            local fps = math.floor(1 / math.max(RunService.RenderStepped:Wait(), 0.001))
            local leaves = getLeavesValue()
            
            local hrs = math.floor(AFKSeconds / 3600)
            local mins = math.floor((AFKSeconds % 3600) / 60)
            local secs = AFKSeconds % 60
            local timeStr = string.format("%d:%02d:%02d", hrs, mins, secs)

            InfoLabel.Text = string.format("🍁 %s | FPS: %d | AFK: %s", formatNumber(leaves), fps, timeStr)
            
            task.wait(1)
            AFKSeconds = AFKSeconds + 1
        end
    end)

    -- Bấm phím Space mỗi 1 phút (60s) chống AFK
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
    if AFKGui then
        AFKGui:Destroy()
        AFKGui = nil
    end
    if AFKTimerThread then
        task.cancel(AFKTimerThread)
        AFKTimerThread = nil
    end
    if AFKKeyThread then
        task.cancel(AFKKeyThread)
        AFKKeyThread = nil
    end
end

-- Toggle Anti-AFK trong Menu (Kết nối với Nút bấm UI)
local AFKToggle = MiscSection2:Toggle({
    Title = "Anti-AFK (Màn Hình Trắng)",
    Desc = "Bật màn hình trắng AFK & Bấm phím PC mỗi 1 phút",
    Value = false,
    Callback = function(Value)
        _G.AntiAFK = Value
        if Value then
            createAFKScreen(function()
                -- Khi ấn Nút | Thoát AFK | trên màn hình trắng -> Tắt Toggle
                _G.AntiAFK = false
                AFKToggle:SetValue(false)
                removeAFKScreen()
            end)
        else
            removeAFKScreen()
        end
    end
})
