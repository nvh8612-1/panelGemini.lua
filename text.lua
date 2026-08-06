-- ====================================================================
-- PANEL GEMINI - GAG2 (Scan workspace.Gardens Once)
-- Script được làm bởi WhiteSs
-- ====================================================================

-- Link loadstring chính thức từ Releases của Footagesus
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- 1. TẠO WINDOW CHÍNH
local Window = WindUI:CreateWindow({
    Title = "Panel Gemini",
    Author = "WhiteSs",
    Icon = "sprout", -- Icon mầm cây
    Folder = "GeminiGAG2",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark"
})

-- 2. KHỞI TẠO TABS
local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
local AutoTab = Window:Tab({ Title = "Auto", Icon = "repeat" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "sliders" })

---------------------------------------------------------
-- MỤC: MAIN
---------------------------------------------------------
local MainSection = MainTab:Section({ Title = "Thông Tin Hub" })

MainSection:Paragraph({
    Title = "Gemini GAG2",
    Desc = "Script được làm bởi WhiteSs"
})

-- Status Paragraph
local StatusParagraph = MainSection:Paragraph({
    Title = "📊 Status Hệ Thống",
    Desc = "Đang quét danh sách Plot..."
})

-- Logic Quét Plot Trong workspace.Gardens (Chạy 1 lần duy nhất khi bật script)
local StatsService = game:GetService("Stats")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function CheckMyPlotOnce()
    local myPlotName = "Không tìm thấy"
    
    local gardens = workspace:FindFirstChild("Gardens")
    if gardens then
        -- Lặp qua tất cả các plot trong workspace.Gardens
        for _, plot in pairs(gardens:GetChildren()) do
            -- Kiểm tra xem plot có chứa Owner trùng với LocalPlayer không
            local ownerObj = plot:FindFirstChild("Owner")
            if ownerObj then
                if ownerObj:IsA("ObjectValue") and ownerObj.Value == LocalPlayer then
                    myPlotName = plot.Name
                    break
                elseif ownerObj:IsA("StringValue") and (ownerObj.Value == LocalPlayer.Name or ownerObj.Value == tostring(LocalPlayer.UserId)) then
                    myPlotName = plot.Name
                    break
                end
            end
        end
    end
    
    return myPlotName
end

-- Gọi hàm check đúng 1 lần khi load UI
local trackedPlot = CheckMyPlotOnce()

-- Cập nhật FPS / Ping realtime, giữ nguyên Plot đã check 1 lần
task.spawn(function()
    while task.wait(0.5) do
        local fps = math.floor(1 / math.max(RunService.RenderStepped:Wait(), 0.001))
        local ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
        local ms = math.floor(RunService.RenderStepped:Wait() * 1000)

        StatusParagraph:SetDesc(string.format(
            "FPS: %d | Ping: %dms | MS: %dms\nPlot: %s\nScript được làm bởi WhiteSs | Gemini GAG2",
            fps, ping, ms, trackedPlot
        ))
    end
end)

---------------------------------------------------------
-- MỤC: AUTO
---------------------------------------------------------
local AutoSection1 = AutoTab:Section({ Title = "Thu Hoạch & Hạt Giống" })

-- FruitHarvest Input
_G.FruitHarvestAmount = 1
AutoSection1:Input({
    Title = "FruitHarvest",
    Desc = "(Khuyên dùng 15) Mặc định: 1",
    Value = "1",
    Placeholder = "Nhập số lượng...",
    Callback = function(Text)
        local num = tonumber(Text)
        _G.FruitHarvestAmount = num or 1
    end
})

-- Auto Harvest Toggle
_G.AutoHarvest = false
AutoSection1:Toggle({
    Title = "Auto Harvest",
    Value = false,
    Callback = function(Value)
        _G.AutoHarvest = Value
        task.spawn(function()
            while _G.AutoHarvest do
                task.wait(0.5)
            end
        end)
    end
})

-- Auto Collect Seed Toggle
_G.AutoCollectSeed = false
AutoSection1:Toggle({
    Title = "Auto Collect Seed",
    Value = false,
    Callback = function(Value)
        _G.AutoCollectSeed = Value
        task.spawn(function()
            while _G.AutoCollectSeed do
                task.wait(1)
            end
        end)
    end
})

local AutoSection2 = AutoTab:Section({ Title = "Tự Động Bán Đồ" })

-- DelaySell Input
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

-- Auto Sell Inventory Toggle
_G.AutoSell = false
AutoSection2:Toggle({
    Title = "Auto Sell Inventory",
    Value = false,
    Callback = function(Value)
        _G.AutoSell = Value
        task.spawn(function()
            local Networking
            pcall(function()
                Networking = require(game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("Networking"))
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
-- MỤC: MISC
---------------------------------------------------------
local MiscSection1 = MiscTab:Section({ Title = "Tối Ưu Vườn (Garden Visibility)" })

-- Hide Others Garden
_G.HideOthersGarden = false
MiscSection1:Toggle({
    Title = "Hide Others Garden",
    Desc = "Tàng hình toàn bộ garden xung quanh, không tàng hình vườn bản thân",
    Value = false,
    Callback = function(Value)
        _G.HideOthersGarden = Value
        
        local gardens = workspace:FindFirstChild("Gardens")
        if gardens then
            for _, obj in pairs(gardens:GetChildren()) do
                local isMyPlot = (obj.Name == trackedPlot)
                
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
_G.HideYouGarden = false
MiscSection1:Toggle({
    Title = "Hide You Garden",
    Desc = "Tàng hình vườn của bản thân",
    Value = false,
    Callback = function(Value)
        _G.HideYouGarden = Value
        
        local gardens = workspace:FindFirstChild("Gardens")
        if gardens then
            for _, obj in pairs(gardens:GetChildren()) do
                local isMyPlot = (obj.Name == trackedPlot)
                
                if isMyPlot then
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

local MiscSection2 = MiscTab:Section({ Title = "Tối Ưu Đồ Họa" })

-- FPS BOOTER
MiscSection2:Button({
    Title = "FPS BOOTER",
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
