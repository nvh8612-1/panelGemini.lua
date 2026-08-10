-- ====================================================================
-- GEMINI | CHAT GPT - GAG2
-- Script by WhiteSs
-- ====================================================================

local Players = game:GetService("Players")
local StatsService = game:GetService("Stats")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ====================================================================
-- WINDUI
-- ====================================================================

local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "Gemini | Chat GPT",
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
            if gui:IsA("ScreenGui")
                and gui.Name ~= "Gemini_AFK_Screen_Minimal" then
                gui.DisplayOrder = 9999
            end
        end
    end)
end)

-- ====================================================================
-- TABS
-- ====================================================================

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "home"
})

local AutoTab = Window:Tab({
    Title = "Auto",
    Icon = "repeat"
})

local ShopTab = Window:Tab({
    Title = "Shop",
    Icon = "shopping-cart"
})

local GearTab = Window:Tab({
    Title = "Gear",
    Icon = "wrench"
})

local TapTab = Window:Tab({
    Title = "Tiện Tap",
    Icon = "mouse-pointer-click"
})

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "sliders"
})

-- ====================================================================
-- ALL SEEDS
-- SHOP + HARVEST DÙNG CHUNG
-- ====================================================================

local AllSeeds = {

    -- =========================
    -- NORMAL
    -- =========================

    "Carrot",
    "Strawberry",
    "Blueberry",
    "Tulip",
    "Tomato",
    "Apple",
    "Bamboo",
    "Corn",
    "Cactus",
    "Pineapple",
    "Mushroom",
    "Banana",
    "Grape",
    "Coconut",
    "Green Bean",
    "Mango",
    "Rocket Pop",
    "Dragon Fruit",
    "Acorn",
    "Cherry",
    "Sunflower",
    "Fire Fern",
    "Venus Fly Trap",
    "Pomegranate",
    "Poison Apple",
    "Venom Spitter",
    "Moon Bloom",
    "Sun Bloom",
    "Hypno Bloom",
    "Dragon's Breath",
    "Star Fruit",
    "Conifer Cone",
    "Amber Cranberry",
    "Atlantic Giant Pumpkin",

    -- =========================
    -- MAPLE
    -- =========================

    "Maple Coconut",
    "Maple Green Bean",
    "Maple Carrot",
    "Maple Strawberry",
    "Maple Blueberry",
    "Maple Tulip",
    "Maple Tomato",
    "Maple Apple",
    "Maple Bamboo",
    "Maple Corn",
    "Maple Cactus",
    "Maple Pineapple",
    "Maple Mushroom",
    "Maple Banana",
    "Maple Grape",
    "Maple Mango",
    "Maple Dragon Fruit",
    "Maple Acorn",
    "Maple Cherry",
    "Maple Sunflower",
    "Maple Venus Fly Trap",
    "Maple Pomegranate",
    "Maple Poison Apple",
    "Maple Venom Spitter",
    "Maple Atlantic Giant Pumpkin"
}

-- ====================================================================
-- PLOT
-- ====================================================================

_G.MyPlot = nil

local SavedPlotName =
    "workspace.Gardens.Plot1"

local function findMyPlot()

    local gardens =
        workspace:FindFirstChild("Gardens")

    if not gardens then
        return nil
    end

    for _, plot in ipairs(
        gardens:GetChildren()
    ) do

        local attrOwner =
            plot:GetAttribute("Owner")

        local attrUserId =
            plot:GetAttribute("OwnerUserId")

        if attrOwner
            and tostring(attrOwner)
                == LocalPlayer.Name then

            return plot
        end

        if attrUserId
            and tonumber(attrUserId)
                == LocalPlayer.UserId then

            return plot
        end

        local ownerValue =
            plot:FindFirstChild("Owner")
            or plot:FindFirstChild("OwnerName")
            or plot:FindFirstChild("Player")

        if ownerValue then

            if ownerValue:IsA("StringValue")
                and ownerValue.Value
                    == LocalPlayer.Name then

                return plot
            end

            if ownerValue:IsA("ObjectValue")
                and ownerValue.Value
                    == LocalPlayer then

                return plot
            end
        end
    end

    local character =
        LocalPlayer.Character

    if character
        and character:FindFirstChild(
            "HumanoidRootPart"
        ) then

        local rootPos =
            character.HumanoidRootPart.Position

        local closestPlot = nil
        local shortestDistance =
            math.huge

        for _, plot in ipairs(
            gardens:GetChildren()
        ) do

            local plotPart =
                plot:FindFirstChildWhichIsA(
                    "BasePart",
                    true
                )

            if plotPart then

                local distance =
                    (
                        plotPart.Position
                        - rootPos
                    ).Magnitude

                if distance <
                    shortestDistance then

                    shortestDistance =
                        distance

                    closestPlot =
                        plot
                end
            end
        end

        if closestPlot
            and shortestDistance < 100 then

            return closestPlot
        end
    end

    return gardens:FindFirstChild("Plot1")
        or gardens:FindFirstChild("plot1")
        or gardens:GetChildren()[1]
end

_G.MyPlot = findMyPlot()

if _G.MyPlot then
    SavedPlotName =
        "workspace.Gardens."
        .. _G.MyPlot.Name
end

-- ====================================================================
-- UTIL
-- ====================================================================

local function getLeavesValue()

    local leaderstats =
        LocalPlayer:FindFirstChild(
            "leaderstats"
        )

    if leaderstats then

        local leaves =
            leaderstats:FindFirstChild(
                "Leaves"
            )

        if leaves then
            return leaves.Value
        end
    end

    return 0
end

local function formatNumber(n)

    return tostring(n)
        :reverse()
        :gsub(
            "%d%d%d",
            "%1,"
        )
        :reverse()
        :gsub(
            "^,",
            ""
        )
end

-- ====================================================================
-- MAIN
-- ====================================================================

local MainSection =
    MainTab:Section({
        Title = "Thông Tin Hub"
    })

MainSection:Paragraph({
    Title = "Gemini | Chat GPT | Grow A Garden 2",
    Desc = "=> WhiteSs"
})

local StatusParagraph =
    MainSection:Paragraph({
        Title = "📊 Status Hệ Thống",
        Desc = "Đang tải dữ liệu..."
    })

task.spawn(function()

    while task.wait(0.5) do

        pcall(function()

            local fps = 0
            local frameTime = 0
            local ping = 0

            pcall(function()
                ping = math.floor(
                    StatsService.Network
                        .ServerStatsItem[
                            "Data Ping"
                        ]:GetValue()
                )
            end)

            pcall(function()

                local dt =
                    RunService.RenderStepped:Wait()

                if dt > 0 then

                    fps =
                        math.floor(1 / dt)

                    frameTime =
                        math.floor(dt * 1000)
                end
            end)

            StatusParagraph:SetDesc(
                string.format(
                    "👤 Người chơi: %s\n\n" ..
                    "🍁 Leaves: %s\n\n" ..
                    "⚡ FPS: %d | Ping: %dms | Frame: %dms\n\n" ..
                    "🏡 Plot: %s\n\n" ..
                    "Trạng thái: Đang hoạt động",
                    LocalPlayer.Name,
                    formatNumber(
                        getLeavesValue()
                    ),
                    fps,
                    ping,
                    frameTime,
                    SavedPlotName
                )
            )
        end)
    end
end)

-- ====================================================================
-- AUTO HARVEST
-- ====================================================================

local AutoSection1 =
    AutoTab:Section({
        Title = "🌱 Thu Hoạch & Hạt Giống"
    })

_G.FruitBatchLimit = 1
_G.AutoHarvest = false
_G.AutoCollectSeed = false
_G.LookAtTarget = false
_G.HarvestSelectedSeeds = {}

-- ====================================================================
-- HARVEST SELECT - MULTI
-- ====================================================================

local HarvestDropdown =
    AutoSection1:Dropdown({

        Title = "Harvest Select",

        Desc =
            "Chọn nhiều Seed Name để Harvest",

        Values = AllSeeds,

        Multi = true,

        Value = {},

        Callback = function(
            Values
        )

            _G.HarvestSelectedSeeds =
                Values or {}

        end
    })

-- ====================================================================
-- HARVEST AMOUNT
-- ====================================================================

AutoSection1:Input({

    Title = "FruitHarvest Amount",

    Desc =
        "Số fruit xử lý mỗi vòng",

    Value = "1",

    Placeholder = "1",

    Callback = function(
        Text
    )

        local num =
            tonumber(Text)

        if num and num > 0 then

            _G.FruitBatchLimit =
                math.floor(num)

        else

            _G.FruitBatchLimit = 1
        end
    end
})

-- ====================================================================
-- LOOK AT
-- ====================================================================

AutoSection1:Toggle({

    Title =
        "Look At Plant When Harvest",

    Desc =
        "Xoay camera tới fruit",

    Value = false,

    Callback = function(
        Value
    )

        _G.LookAtTarget =
            Value
    end
})

local function lookAtPosition(
    targetPos
)

    if not _G.LookAtTarget then
        return
    end

    local camera =
        workspace.CurrentCamera

    if camera then

        camera.CFrame =
            CFrame.new(
                camera.CFrame.Position,
                targetPos
            )
    end
end

-- ====================================================================
-- GET SEED NAME
-- ====================================================================

local function getFruitSeedName(
    fruit
)

    if not fruit then
        return nil
    end

    local attr =
        fruit:GetAttribute(
            "SeedName"
        )

    if attr ~= nil then
        return tostring(attr)
    end

    local value =
        fruit:FindFirstChild(
            "SeedName"
        )

    if value
        and value:IsA(
            "StringValue"
        ) then

        return tostring(
            value.Value
        )
    end

    return nil
end

-- ====================================================================
-- CHECK SELECTED
-- ====================================================================

local function isSelectedHarvestSeed(
    seedName
)

    if not seedName then
        return false
    end

    local target =
        string.lower(
            tostring(seedName)
        )

    for _, selected in ipairs(
        _G.HarvestSelectedSeeds or {}
    ) do

        if string.lower(
            tostring(selected)
        ) == target then

            return true
        end
    end

    return false
end

-- ====================================================================
-- FIND HARVEST PROMPT
-- ====================================================================

local function getHarvestPrompt(
    fruit
)

    if not fruit then
        return nil
    end

    local prompt =
        fruit:FindFirstChild(
            "HarvestPrompt",
            true
        )

    if prompt
        and prompt:IsA(
            "ProximityPrompt"
        ) then

        return prompt
    end

    return fruit:FindFirstChildWhichIsA(
        "ProximityPrompt",
        true
    )
end

-- ====================================================================
-- FIRE HARVEST PROMPT
-- ====================================================================

local function triggerHarvest(
    prompt
)

    if not prompt then
        return false
    end

    local success = false

    pcall(function()

        prompt.HoldDuration = 0
        prompt.MaxActivationDistance =
            99999

        prompt.RequiresLineOfSight =
            false

        if fireHarvestPrompt then

            fireHarvestPrompt(
                prompt
            )

            success = true

        elseif fireproximityprompt then

            fireproximityprompt(
                prompt
            )

            success = true
        end
    end)

    return success
end

-- ====================================================================
-- PROCESS HARVEST
-- ====================================================================

local function processHarvest()

    if not _G.AutoHarvest then
        return
    end

    if not _G.HarvestSelectedSeeds
        or #_G.HarvestSelectedSeeds
            == 0 then

        return
    end

    if not _G.MyPlot then
        _G.MyPlot =
            findMyPlot()
    end

    local plot =
        _G.MyPlot

    if not plot then
        return
    end

    local plants =
        plot:FindFirstChild(
            "Plants"
        )

    if not plants then
        return
    end

    local harvested = 0

    for _, plant in ipairs(
        plants:GetChildren()
    ) do

        if not _G.AutoHarvest then
            break
        end

        local fruits =
            plant:FindFirstChild(
                "Fruits"
            )

        if fruits then

            for _, fruit in ipairs(
                fruits:GetChildren()
            ) do

                if not _G.AutoHarvest then
                    break
                end

                local seedName =
                    getFruitSeedName(
                        fruit
                    )

                if isSelectedHarvestSeed(
                    seedName
                ) then

                    local prompt =
                        getHarvestPrompt(
                            fruit
                        )

                    if prompt then

                        local part =
                            fruit:FindFirstChild(
                                "HarvestPart"
                            )
                            or fruit:FindFirstChildWhichIsA(
                                "BasePart",
                                true
                            )

                        if part then
                            lookAtPosition(
                                part.Position
                            )
                        end

                        if triggerHarvest(
                            prompt
                        ) then

                            harvested += 1
                        end

                        if harvested >=
                            _G.FruitBatchLimit then

                            return
                        end
                    end
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(
    function()

        if _G.AutoHarvest then
            processHarvest()
        end
    end
)

AutoSection1:Toggle({

    Title = "Auto Harvest",

    Desc =
        "Fire HarvestPrompt theo Seed Name đã chọn",

    Value = false,

    Callback = function(
        Value
    )

        _G.AutoHarvest =
            Value
    end
})

-- ====================================================================
-- AUTO COLLECT SEED
-- ====================================================================

local function triggerPickupPrompt(
    prompt,
    targetPart
)

    if not prompt then
        return
    end

    pcall(function()

        prompt.HoldDuration = 0
        prompt.MaxActivationDistance =
            99999

        prompt.RequiresLineOfSight =
            false

        if targetPart
            and _G.LookAtTarget then

            lookAtPosition(
                targetPart.Position
            )
        end

        if firePickupPrompt then

            firePickupPrompt(
                prompt
            )

        elseif fireproximityprompt then

            fireproximityprompt(
                prompt
            )
        end
    end)
end

RunService.Heartbeat:Connect(
    function()

        if not _G.AutoCollectSeed then
            return
        end

        pcall(function()

            local droppedFolder =
                workspace:FindFirstChild(
                    "DroppedItems"
                )

            if not droppedFolder then
                return
            end

            for _, item in ipairs(
                droppedFolder:GetChildren()
            ) do

                if not _G.AutoCollectSeed then
                    break
                end

                local anchor =
                    item:FindFirstChild(
                        "PromptAnchor"
                    )
                    or item:FindFirstChildWhichIsA(
                        "BasePart"
                    )

                local prompt =
                    item:FindFirstChildWhichIsA(
                        "ProximityPrompt",
                        true
                    )

                if prompt then

                    triggerPickupPrompt(
                        prompt,
                        anchor
                    )
                end
            end
        end)
    end
)

AutoSection1:Toggle({

    Title =
        "Auto Collect Seed",

    Desc =
        "Tự động nhặt Seed rơi",

    Value = false,

    Callback = function(
        Value
    )

        _G.AutoCollectSeed =
            Value
    end
})

-- ====================================================================
-- AUTO SELL
-- ====================================================================

local AutoSection2 =
    AutoTab:Section({
        Title = "💰 Tự Động Bán"
    })

_G.DelaySell = 0.1
_G.AutoSell = false

AutoSection2:Input({

    Title = "Delay Sell",

    Desc =
        "Delay giữa mỗi lần bán",

    Value = "0.1",

    Placeholder = "0.1",

    Callback = function(
        Text
    )

        local sanitized =
            string.gsub(
                Text,
                ",",
                "."
            )

        local num =
            tonumber(
                sanitized
            )

        _G.DelaySell =
            (
                num and num >= 0
            )
            and num
            or 0.1
    end
})

AutoSection2:Toggle({

    Title =
        "Auto Sell Inventory",

    Value = false,

    Callback = function(
        Value
    )

        _G.AutoSell =
            Value

        if not Value then
            return
        end

        task.spawn(function()

            local Networking

            pcall(function()

                Networking =
                    require(
                        ReplicatedStorage
                            :WaitForChild(
                                "SharedModules"
                            )
                            :WaitForChild(
                                "Networking"
                            )
                    )
            end)

            while _G.AutoSell do

                pcall(function()

                    if Networking
                        and Networking.NPCS
                        and Networking.NPCS.SellAll then

                        Networking.NPCS
                            .SellAll:Fire()
                    end
                end)

                task.wait(
                    math.max(
                        _G.DelaySell or 0.1,
                        0.01
                    )
                )
            end
        end)
    end
})

-- ====================================================================
-- PACKET
-- ====================================================================

local PacketRemote =
    ReplicatedStorage
        :WaitForChild(
            "SharedModules"
        )
        :WaitForChild(
            "Packet"
        )
        :WaitForChild(
            "RemoteEvent"
        )

-- ====================================================================
-- SHOP
-- ====================================================================

local ShopSection =
    ShopTab:Section({
        Title =
            "🌱 Cửa Hàng Hạt Giống"
    })

_G.SelectedSeeds = {}
_G.AutoBuySeed = false
_G.AutoBuyAllSeeds = false
_G.CurrentSeedFilter = "All"

-- ====================================================================
-- SEED BUFFER
-- ====================================================================

local SeedBuffers = {}

for _, name in ipairs(
    AllSeeds
) do

    local payload =
        "\160\000"
        .. string.char(#name)
        .. name

    SeedBuffers[name] =
        buffer.fromstring(
            payload
        )
end

local function buySeedFast(
    seedName
)

    local bufferData =
        SeedBuffers[seedName]

    if bufferData then

        PacketRemote:FireServer(
            bufferData
        )
    end
end

-- ====================================================================
-- FILTER SEED
-- ====================================================================

local function filterSeeds(
    filterType
)

    local filtered = {}

    for _, seedName in ipairs(
        AllSeeds
    ) do

        local isMaple =
            string.find(
                string.lower(
                    seedName
                ),
                "maple",
                1,
                true
            ) ~= nil

        if filterType == "All" then

            table.insert(
                filtered,
                seedName
            )

        elseif filterType == "Normal" then

            if not isMaple then

                table.insert(
                    filtered,
                    seedName
                )
            end

        elseif filterType == "Maple" then

            if isMaple then

                table.insert(
                    filtered,
                    seedName
                )
            end
        end
    end

    return filtered
end

-- ====================================================================
-- CLEAN SELECTED
-- ====================================================================

local function cleanSelectedSeeds(
    newList
)

    local allowed = {}

    for _, seedName in ipairs(
        newList
    ) do

        allowed[seedName] =
            true
    end

    local cleaned = {}

    for _, seedName in ipairs(
        _G.SelectedSeeds or {}
    ) do

        if allowed[seedName] then

            table.insert(
                cleaned,
                seedName
            )
        end
    end

    _G.SelectedSeeds =
        cleaned
end

-- ====================================================================
-- SEED DROPDOWN
-- ====================================================================

local SeedDropdown

local function updateSeedList(
    filterType
)

    _G.CurrentSeedFilter =
        filterType

    local newList =
        filterSeeds(
            filterType
        )

    cleanSelectedSeeds(
        newList
    )

    if SeedDropdown then

        pcall(function()

            SeedDropdown:SetValues(
                newList
            )
        end)

        pcall(function()

            SeedDropdown:SetValue(
                _G.SelectedSeeds
            )
        end)
    end
end

-- ====================================================================
-- FILTER
-- ====================================================================

ShopSection:Dropdown({

    Title =
        "Lọc Loại Hạt Giống",

    Desc =
        "All / Normal / Maple",

    Values = {
        "All",
        "Normal",
        "Maple"
    },

    Value = "All",

    Callback = function(
        Value
    )

        updateSeedList(
            Value
        )
    end
})

-- ====================================================================
-- SELECT SEED
-- ====================================================================

SeedDropdown =
    ShopSection:Dropdown({

        Title =
            "Chọn Hạt Giống",

        Desc =
            "Multi-Select - áp dụng Filter",

        Values =
            AllSeeds,

        Multi = true,

        Value = {},

        Callback = function(
            Values
        )

            _G.SelectedSeeds =
                Values or {}
        end
    })

-- ====================================================================
-- AUTO BUY SELECTED
-- ====================================================================

ShopSection:Toggle({

    Title =
        "Auto Buy Selected Seeds",

    Desc =
        "Mua lặp Seed đã chọn",

    Value = false,

    Callback = function(
        Value
    )

        _G.AutoBuySeed =
            Value

        if not Value then
            return
        end

        task.spawn(function()

            while _G.AutoBuySeed do

                for _, seedName in ipairs(
                    _G.SelectedSeeds or {}
                ) do

                    if not _G.AutoBuySeed then
                        break
                    end

                    buySeedFast(
                        seedName
                    )

                    task.wait(
                        0.02
                    )
                end

                task.wait(
                    0.05
                )
            end
        end)
    end
})

-- ====================================================================
-- AUTO BUY ALL - THEO FILTER
-- ====================================================================

ShopSection:Toggle({

    Title =
        "Auto Buy All Seeds",

    Desc =
        "Mua toàn bộ Seed theo Filter",

    Value = false,

    Callback = function(
        Value
    )

        _G.AutoBuyAllSeeds =
            Value

        if not Value then
            return
        end

        task.spawn(function()

            while _G.AutoBuyAllSeeds do

                local currentList =
                    filterSeeds(
                        _G.CurrentSeedFilter
                    )

                for _, seedName in ipairs(
                    currentList
                ) do

                    if not _G.AutoBuyAllSeeds then
                        break
                    end

                    buySeedFast(
                        seedName
                    )

                    task.wait(
                        0.02
                    )
                end

                task.wait(
                    0.1
                )
            end
        end)
    end
})

-- ====================================================================
-- GEAR
-- ====================================================================

local GearSection =
    GearTab:Section({
        Title =
            "🔧 Cửa Hàng Gear"
    })

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

for _, name in ipairs(
    AllGears
) do

    local payload =
        "\164\000"
        .. string.char(#name)
        .. name

    GearBuffers[name] =
        buffer.fromstring(
            payload
        )
end

local function buyGearFast(
    gearName
)

    local bufferData =
        GearBuffers[gearName]

    if bufferData then

        PacketRemote:FireServer(
            bufferData
        )
    end
end

GearSection:Dropdown({

    Title =
        "Chọn Gear",

    Desc =
        "Multi-Select",

    Values =
        AllGears,

    Multi = true,

    Value = {},

    Callback = function(
        Values
    )

        _G.SelectedGears =
            Values or {}
    end
})

GearSection:Toggle({

    Title =
        "Auto Buy Selected Gear",

    Value = false,

    Callback = function(
        Value
    )

        _G.AutoBuyGear =
            Value

        if not Value then
            return
        end

        task.spawn(function()

            while _G.AutoBuyGear do

                for _, gearName in ipairs(
                    _G.SelectedGears or {}
                ) do

                    if not _G.AutoBuyGear then
                        break
                    end

                    buyGearFast(
                        gearName
                    )

                    task.wait(
                        0.02
                    )
                end

                task.wait(
                    0.05
                )
            end
        end)
    end
})

GearSection:Toggle({

    Title =
        "Auto Buy All Gear",

    Desc =
        "Mua toàn bộ Gear",

    Value = false,

    Callback = function(
        Value
    )

        _G.AutoBuyAllGears =
            Value

        if not Value then
            return
        end

        task.spawn(function()

            while _G.AutoBuyAllGears do

                for _, gearName in ipairs(
                    AllGears
                ) do

                    if not _G.AutoBuyAllGears then
                        break
                    end

                    buyGearFast(
                        gearName
                    )

                    task.wait(
                        0.02
                    )
                end

                task.wait(
                    0.1
                )
            end
        end)
    end
})

-- ====================================================================
-- TIỆN TAP
-- ====================================================================

local TapSection =
    TapTab:Section({
        Title =
            "⚡ Tiện Tap"
    })

_G.TapSpeed = 1
_G.AutoTap = false

TapSection:Slider({

    Title =
        "Tốc độ Tap",

    Desc =
        "1 → 36 lần/giây",

    Step = 1,

    Value = {
        Min = 1,
        Max = 36,
        Default = 1
    },

    Callback = function(
        Value
    )

        _G.TapSpeed =
            math.clamp(
                tonumber(Value) or 1,
                1,
                36
            )
    end
})

local TapStatus =
    TapSection:Paragraph({

        Title =
            "📊 Trạng thái",

        Desc =
            "🔴 OFF | 1 tap/giây"
    })

local function getTapPosition()

    local camera =
        workspace.CurrentCamera

    if not camera then
        return 0, 0
    end

    local viewport =
        camera.ViewportSize

    return
        math.floor(
            viewport.X / 2
        ),
        math.floor(
            viewport.Y / 2
        )
end

local function performTap()

    pcall(function()

        local x, y =
            getTapPosition()

        VirtualInputManager:
            SendMouseButtonEvent(
                x,
                y,
                0,
                true,
                game,
                0
            )

        VirtualInputManager:
            SendMouseButtonEvent(
                x,
                y,
                0,
                false,
                game,
                0
            )
    end)
end

TapSection:Toggle({

    Title =
        "Auto Tap",

    Desc =
        "Tự động tap",

    Value = false,

    Callback = function(
        Value
    )

        _G.AutoTap =
            Value

        if not Value then
            return
        end

        task.spawn(function()

            while _G.AutoTap do

                performTap()

                local speed =
                    math.clamp(
                        tonumber(
                            _G.TapSpeed
                        ) or 1,
                        1,
                        36
                    )

                task.wait(
                    1 / speed
                )
            end
        end)
    end
})

task.spawn(function()

    while task.wait(0.2) do

        pcall(function()

            local speed =
                math.clamp(
                    tonumber(
                        _G.TapSpeed
                    ) or 1,
                    1,
                    36
                )

            local state =
                _G.AutoTap
                and "🟢 ON"
                or "🔴 OFF"

            TapStatus:SetDesc(
                string.format(
                    "%s | %d tap/giây",
                    state,
                    speed
                )
            )
        end)
    end
end)

-- ====================================================================
-- MISC
-- ====================================================================

local MiscSection1 =
    MiscTab:Section({
        Title =
            "🌳 Tối Ưu Vườn"
    })

MiscSection1:Toggle({

    Title =
        "Hide Others Garden",

    Desc =
        "Ẩn Garden người khác",

    Value = false,

    Callback = function(
        Value
    )

        local gardens =
            workspace:FindFirstChild(
                "Gardens"
            )

        if not gardens then
            return
        end

        for _, obj in ipairs(
            gardens:GetChildren()
        ) do

            if not (
                _G.MyPlot
                and obj == _G.MyPlot
            ) then

                for _, child in ipairs(
                    obj:GetDescendants()
                ) do

                    if child:IsA(
                        "BasePart"
                    ) then

                        child.Transparency =
                            Value
                            and 1
                            or 0

                        child.CanCollide =
                            not Value
                    end
                end
            end
        end
    end
})

MiscSection1:Toggle({

    Title =
        "Hide Your Garden",

    Desc =
        "Ẩn Garden của bạn",

    Value = false,

    Callback = function(
        Value
    )

        if not _G.MyPlot then
            return
        end

        for _, child in ipairs(
            _G.MyPlot:GetDescendants()
        ) do

            if child:IsA(
                "BasePart"
            ) then

                child.Transparency =
                    Value
                    and 1
                    or 0

                child.CanCollide =
                    not Value
            end
        end
    end
})

-- ====================================================================
-- FPS BOOST
-- ====================================================================

local MiscSection2 =
    MiscTab:Section({
        Title =
            "🎮 Tối Ưu Đồ Họa"
    })

MiscSection2:Button({

    Title =
        "FPS BOOSTER",

    Desc =
        "Giảm Effect / Shadow / Quality",

    Callback = function()

        pcall(function()

            local Terrain =
                workspace:FindFirstChildOfClass(
                    "Terrain"
                )

            if Terrain then

                Terrain.WaterWaveSize =
                    0

                Terrain.WaterWaveSpeed =
                    0

                Terrain.WaterReflectance =
                    0

                Terrain.WaterTransparency =
                    1
            end

            local Lighting =
                game:GetService(
                    "Lighting"
                )

            Lighting.GlobalShadows =
                false

            for _, obj in ipairs(
                workspace:GetDescendants()
            ) do

                if obj:IsA(
                    "ParticleEmitter"
                )
                    or obj:IsA("Trail")
                    or obj:IsA("Smoke")
                    or obj:IsA("Fire")
                    or obj:IsA("Sparkles") then

                    obj.Enabled =
                        false

                elseif obj:IsA(
                    "BasePart"
                ) then

                    obj.Material =
                        Enum.Material.SmoothPlastic
                end
            end

            pcall(function()

                settings()
                    .Rendering
                    .QualityLevel =
                    Enum.QualityLevel.Level01
            end)
        end)
    end
})

-- ====================================================================
-- DONE
-- ====================================================================

print("====================================")
print(" GEMINI | CHAT GPT")
print(" Grow A Garden 2")
print(" WhiteSs")
print("------------------------------------")
print(" Green Bean: Added")
print(" Maple Green Bean: Added")
print(" Harvest Select: Multi")
print(" Shop Filter: All / Normal / Maple")
print(" Auto Buy: Filter Aware")
print(" Tap Speed: 1 -> 36")
print("====================================")
