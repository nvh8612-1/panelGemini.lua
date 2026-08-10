-- ====================================================================
-- PANEL GEMINI - GAG2 (Compact & Fixed UI No Empty Tab)
-- ====================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Panel Gemini | GAG2",
    Author = "WhiteSs",
    Folder = "GeminiGAG2",
    Size = UDim2.fromOffset(550, 400),
    Theme = "Dark"
})

local MainTab  = Window:Tab({ Title = "Main",  Icon = "home" })
local AutoTab  = Window:Tab({ Title = "Auto",  Icon = "repeat" })
local ShopTab  = Window:Tab({ Title = "Shop",  Icon = "shopping-cart" })
local SpeedTab = Window:Tab({ Title = "Speed", Icon = "zap" })
local MiscTab  = Window:Tab({ Title = "Misc",  Icon = "sliders" })

-- 1. MAIN TAB
MainTab:Paragraph({ Title = "Panel Gemini", Desc = "Tác giả: WhiteSs" })
local Status = MainTab:Paragraph({ Title = "Status", Desc = "Đang chạy..." })

task.spawn(function()
    while task.wait(0.5) do
        local fps = math.floor(1 / math.max(RunService.RenderStepped:Wait(), 0.001))
        Status:SetDesc(string.format("Người chơi: %s\nFPS: %d | Status: OK", LocalPlayer.Name, fps))
    end
end)

-- 2. AUTO TAB
_G.AutoHarvest = false
_G.AutoCollectSeed = false
_G.AutoSell = false

AutoTab:Toggle({
    Title = "Auto Harvest",
    Value = false,
    Callback = function(v) _G.AutoHarvest = v end
})

AutoTab:Toggle({
    Title = "Auto Collect Seed",
    Value = false,
    Callback = function(v) _G.AutoCollectSeed = v end
})

AutoTab:Toggle({
    Title = "Auto Sell All",
    Value = false,
    Callback = function(v)
        _G.AutoSell = v
        task.spawn(function()
            local Net = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
            while _G.AutoSell do
                if Net and Net.NPCS and Net.NPCS.SellAll then Net.NPCS.SellAll:Fire() end
                task.wait(0.5)
            end
        end)
    end
})

-- Loop Harvest & Collect (Heartbeat)
RunService.Heartbeat:Connect(function()
    if _G.AutoHarvest then
        pcall(function()
            local gardens = workspace:FindFirstChild("Gardens")
            if not gardens then return end
            for _, plot in ipairs(gardens:GetChildren()) do
                local plants = plot:FindFirstChild("Plants")
                if plants then
                    for _, plant in ipairs(plants:GetChildren()) do
                        local fruits = plant:FindFirstChild("Fruits")
                        if fruits then
                            for _, fruit in ipairs(fruits:GetChildren()) do
                                local prompt = fruit:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt then
                                    prompt.HoldDuration = 0
                                    if fireproximityprompt then fireproximityprompt(prompt) end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    if _G.AutoCollectSeed then
        pcall(function()
            local dropped = workspace:FindFirstChild("DroppedItems")
            if dropped then
                for _, item in ipairs(dropped:GetChildren()) do
                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        prompt.HoldDuration = 0
                        if fireproximityprompt then fireproximityprompt(prompt) end
                    end
                end
            end
        end)
    end
end)

-- 3. SHOP TAB
local PacketRemote = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent")
local AllSeeds = { "Carrot", "Strawberry", "Blueberry", "Tulip", "Tomato", "Apple", "Maple Strawberry", "Maple Blueberry" }

ShopTab:Dropdown({
    Title = "Chọn Hạt Mua",
    Values = AllSeeds,
    Multi = true,
    Value = { "Carrot" },
    Callback = function(v) _G.SelectedSeeds = v end
})

ShopTab:Toggle({
    Title = "Auto Buy Selected Seeds",
    Value = false,
    Callback = function(v)
        _G.AutoBuy = v
        task.spawn(function()
            while _G.AutoBuy do
                if _G.SelectedSeeds then
                    for _, name in ipairs(_G.SelectedSeeds) do
                        local payload = "\160\000" .. string.char(#name) .. name
                        PacketRemote:FireServer(buffer.fromstring(payload))
                        task.wait(0.05)
                    end
                end
                task.wait(0.1)
            end
        end)
    end
})

-- 4. SPEED TAB (Đã hiện chuẩn 100%)
_G.WalkSpeedValue = 16
_G.ActivateSpeed = false

SpeedTab:Slider({
    Title = "Speed",
    Desc = "Chỉnh tốc độ di chuyển (1-100)",
    Min = 1,
    Max = 100,
    Value = 16,
    Callback = function(v)
        _G.WalkSpeedValue = v
        if _G.ActivateSpeed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = _G.WalkSpeedValue
        end
    end
})

SpeedTab:Toggle({
    Title = "Activate Speed",
    Desc = "Bật / Tắt Tốc Độ",
    Value = false,
    Callback = function(v)
        _G.ActivateSpeed = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v and _G.WalkSpeedValue or 16
        end
    end
})

RunService.Stepped:Connect(function()
    if _G.ActivateSpeed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = _G.WalkSpeedValue
    end
end)

-- 5. MISC TAB
MiscTab:Toggle({
    Title = "Hide Others Garden",
    Value = false,
    Callback = function(v)
        local gardens = workspace:FindFirstChild("Gardens")
        if gardens then
            for _, plot in ipairs(gardens:GetChildren()) do
                if not string.find(plot.Name, LocalPlayer.Name) then
                    for _, part in ipairs(plot:GetDescendants()) do
                        if part:IsA("BasePart") then part.Transparency = v and 1 or 0 end
                    end
                end
            end
        end
    end
})

MiscTab:Button({
    Title = "FPS BOOSTER",
    Callback = function()
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic
            elseif v:IsA("Decal") or v:IsA("Texture") then v:Destroy() end
        end
    end
})
