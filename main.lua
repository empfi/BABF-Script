local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local plrs = game:GetService("Players")

-- Wait for LocalPlayer if script runs before player is available
local p = plrs.LocalPlayer
if not p then
    repeat
        task.wait(0.1)
        p = plrs.LocalPlayer
    until p
end

-- Try to find the player's factory but avoid hard error if missing
local f
local ok, err = pcall(function()
    f = workspace:WaitForChild(p.Name .. "Factory", 10) -- Add timeout
end)

-- Only create UI after factory setup attempt
Rayfield:Notify({
    Title = "empfi | Build a Brainrot Factory",
    Content = "Loading...",
    Duration = 5,
})

local Window = Rayfield:CreateWindow({
    Name = "empfi | Build a Brainrot Factory",
    LoadingTitle = "empfi loading...",
    LoadingSubtitle = "by empfi",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "empfi",
        FileName = "BABF"
    },
    KeySystem = false,
})

if not ok or not f then
    warn("Factory not found: " .. tostring(err))
    Rayfield:Notify({
        Title = "Warning",
        Content = "Factory not found. Some features disabled.",
        Duration = 5,
    })
    f = Instance.new("Folder")
    f.Name = p.Name .. "Factory"
    f.Parent = workspace
end

local c = f:FindFirstChild("Collectors")
if not c then
    c = Instance.new("Folder")
    c.Name = "Collectors"
    c.Parent = f
end

-- Replace string icon names (which can error) with numeric 0 so tabs load reliably
local MainTab = Window:CreateTab("Main", 0)
local Divider = MainTab:CreateDivider()
local experienceTab = Window:CreateTab("Experience", 0)
local Divider = experienceTab:CreateDivider()
local aboutTab = Window:CreateTab("About", 0)
local Divider = aboutTab:CreateDivider()

-- Dev Tab (holds developer tools like the updater)
local devTab = Window:CreateTab("Dev", 0)
local Divider = devTab:CreateDivider()

-- Update Button
local updateButton = devTab:CreateButton({
    Name = "Update Script",
    Callback = function()
        local HttpService = game:GetService("HttpService")
        local sources = {
            { name = "jsDelivr CDN", url = "https://cdn.jsdelivr.net/gh/empfi/BABF-Script@main/main.lua" },
            { name = "GitHub RAW", url = "https://raw.githubusercontent.com/empfi/BABF-Script/main/main.lua" },
        }

        local apiUrl = "https://api.github.com/repos/empfi/BABF-Script/contents/main.lua"
        local errors = {}
        local fetchedScript

        -- Try CDN/raw first
        for _, src in ipairs(sources) do
            local ok, resp = pcall(function() return game:HttpGet(src.url) end)
            if ok and resp and #resp > 0 then
                fetchedScript = resp
                break
            else
                table.insert(errors, ("%s fetch failed: %s"):format(src.name, tostring(resp)))
            end
        end

        -- If still not fetched, try GitHub API to get download_url
        if not fetchedScript then
            local ok, apiResp = pcall(function() return game:HttpGet(apiUrl) end)
            if ok and apiResp then
                local parsedOk, parsed = pcall(function() return HttpService:JSONDecode(apiResp) end)
                if parsedOk and parsed and parsed.download_url then
                    local ok2, resp2 = pcall(function() return game:HttpGet(parsed.download_url) end)
                    if ok2 and resp2 and #resp2 > 0 then
                        fetchedScript = resp2
                    else
                        table.insert(errors, ("GitHub download_url fetch failed: %s"):format(tostring(resp2)))
                    end
                else
                    table.insert(errors, ("GitHub API parse failed: %s"):format(tostring(parsed)))
                end
            else
                table.insert(errors, ("GitHub API fetch failed: %s"):format(tostring(apiResp)))
            end
        end

        -- Try to load the script if fetched
        if fetchedScript then
            local loadOk, loadErr = pcall(function() loadstring(fetchedScript)() end)
            if loadOk then
                Rayfield:Destroy()
                Rayfield:Notify({
                    Title = "empfi | Build a Brainrot Factory",
                    Content = "Script successfully updated!",
                    Duration = 5,
                    Image = "loader",
                })
                return
            else
                table.insert(errors, ("loadstring failed: %s"):format(tostring(loadErr)))
            end
        end

        -- All attempts failed: open API page in host browser and notify with collected errors
        pcall(function()
            if type(os) == "table" and type(os.execute) == "function" then
                os.execute(string.format('$BROWSER "%s"', apiUrl))
            end
        end)

        Rayfield:Notify({
            Title = "empfi | Build a Brainrot Factory",
            Content = "Update failed. See console for details. Opened API page as fallback.",
            Duration = 8,
            Image = "loader",
        })
        warn("Update Script errors:\n" .. table.concat(errors, "\n"))
    end,
})

-- just found ts anti-afk ion if it works.
getgenv().afk_toggle = true
local VirtualUser = game:GetService("VirtualUser")
local status = getgenv().afk_toggle
if status == nil then
    getgenv().afk_toggle = false
end
if not p then
    error("Failed to get LocalPlayer reference")
end
p.Idled:Connect(function()
    if not getgenv().afk_toggle then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- Collect nearby collector pads.
function nearbyCollect()
    for _, m in pairs(c:GetChildren()) do
        local prompt = m:IsA("Model") and m:FindFirstChild("CollectPrompt", true)
        if prompt and prompt:IsA("ProximityPrompt") then
            fireproximityprompt(prompt)
        end
    end
end

-- Anti Lag
function antiLag()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local itemFolder = f:WaitForChild("Items")
    if itemFolder then
        itemFolder.Parent = replicatedStorage
    end
end

-- Purchase
local shopItems = {
    "Basic Conveyor", "Basic Upgrader", "Basic Machine", "Speedy Conveyor", "Basic Collector", "Better Upgrader",
    "Stair Conveyor", "Better Machine",
    "Slide Conveyor", "Split Conveyor", "Doubler Collector", "Super Conveyor", "Super Upgrader",
    "Super Collector", "Super Machine", "Heavenly Upgrader", "Heavenly Machine",
}


-- Global Variables
getgenv().autoBuyEnabled, getgenv().autoCollect = false, false
getgenv().selectedItems = { "Basic Conveyor" }

-- Auto Buy
function autoBuy()
    while getgenv().autoBuyEnabled do
        if getgenv().selectedItems and #getgenv().selectedItems > 0 then
            for _, item in ipairs(getgenv().selectedItems) do
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Remotes")
                    :WaitForChild("Game")
                    :WaitForChild("PurchaseItem")
                    :FireServer(item)
            end
        end
        task.wait(1)
    end
end

local collectLabel = MainTab:CreateLabel("Stand on the middle of collectors", "info")
local Toggle = MainTab:CreateToggle({
    Name = "Auto Collect Nearby Collectors",
    CurrentValue = false,
    Flag = "AutoCollectToggle",
    Callback = function(state)
        getgenv().autoCollect = state
        if state then
            print("Auto Collect: ON")
            task.spawn(function()
                while getgenv().autoCollect do
                    nearbyCollect()

                    task.wait(0.1)
                end
            end)
        else
            print("Auto Collect: OFF")
        end
    end,
})


-- Anti Lag Toggle
getgenv().antiLagEnabled = false

local lagToggle = MainTab:CreateToggle({
    Name = "Anti Lag",
    CurrentValue = false,
    Flag = "AntiLagToggle",
    Callback = function(state)
        getgenv().antiLagEnabled = state
        if state then
            antiLag()
            Rayfield:Notify({
                Title = "empfi | Build a Brainrot Factory",
                Content = "Anti Lag Enabled",
                Duration = 5,
                Image = "loader",
            })
        else
            -- Restore items folder back to the factory
            local replicatedStorage = game:GetService("ReplicatedStorage")
            local itemFolder = replicatedStorage:FindFirstChild("Items")
            if itemFolder then
                itemFolder.Parent = f
            end
            Rayfield:Notify({
                Title = "empfi | Build a Brainrot Factory",
                Content = "Anti Lag Disabled",
                Duration = 5,
                Image = "loader",
            })
        end
    end,
})

-- Select Items
local buyDropdown = MainTab:CreateDropdown({
    Name = "Select Item(s) to Buy",
    Options = shopItems,
    CurrentOption = { "Basic Conveyor" },
    MultipleOptions = true,
    Flag = "selectedItems",
    Callback = function(Options)
        getgenv().selectedItems = Options
        --print("Selected:", table.concat(getgenv().selectedItems, ", "))
    end,
})

-- Toggle for auto-buy
local buyToggle = MainTab:CreateToggle({
    Name = "Auto Buy",
    CurrentValue = false,
    Flag = "AutoBuyToggle",
    Callback = function(state)
        getgenv().autoBuyEnabled = state
        if state then
            print("Auto Buy: ON")
            -- run autoBuy in a new task so the UI thread isn't blocked
            task.spawn(autoBuy)
        else
            print("Auto Buy: OFF")
        end
    end,
})

-- Sound Control Toggle
local soundToggle = experienceTab:CreateToggle({
    Name = "Disable Game Sounds",
    CurrentValue = false,
    Flag = "DisableSoundsToggle",
    Callback = function(state)
        local soundService = game:GetService("SoundService")
        if state then
            soundService.Volume = 0
            Rayfield:Notify({
                Title = "empfi | Build a Brainrot Factory",
                Content = "Game sounds disabled",
                Duration = 3,
                Image = "loader",
            })
        else
            soundService.Volume = 1
            Rayfield:Notify({
                Title = "empfi | Build a Brainrot Factory",
                Content = "Game sounds enabled",
                Duration = 3,
                Image = "loader",
            })
        end
    end,
})

local Paragraph = aboutTab:CreateParagraph({
    Title = "About Script",
    Content =
    "Hey! This script is free and fully keyless! Enjoy building your Brainrot Factory with ease and efficiency using this script.",
})

-- Add Lighting tab and buttons
local lightingTab = Window:CreateTab("Lighting", 0)
local Divider = lightingTab:CreateDivider()

lightingTab:CreateButton({
    Name = "RTX Lighting",
    Description = "Load preset in lighting",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        -- Remove existing effects
        for i, v in pairs(Lighting:GetChildren()) do
            if v then
                v:Destroy()
            end
        end

        -- Create and setup effects
        local Bloom = Instance.new("BloomEffect")
        local Blur = Instance.new("BlurEffect")
        local ColorCor = Instance.new("ColorCorrectionEffect")
        local SunRays = Instance.new("SunRaysEffect")
        local Sky = Instance.new("Sky")
        local Atm = Instance.new("Atmosphere")

        Bloom.Parent = Lighting
        Blur.Parent = Lighting
        ColorCor.Parent = Lighting
        SunRays.Parent = Lighting
        Sky.Parent = Lighting
        Atm.Parent = Lighting

        -- Configure effects
        Bloom.Intensity = 0.3
        Bloom.Size = 10
        Bloom.Threshold = 0.8

        Blur.Size = 5

        ColorCor.Brightness = 0.1
        ColorCor.Contrast = 0.5
        ColorCor.Saturation = -0.3
        ColorCor.TintColor = Color3.fromRGB(255, 235, 203)

        SunRays.Intensity = 0.075
        SunRays.Spread = 0.727

        Sky.SkyboxBk = "http://www.roblox.com/asset/?id=151165214"
        Sky.SkyboxDn = "http://www.roblox.com/asset/?id=151165197"
        Sky.SkyboxFt = "http://www.roblox.com/asset/?id=151165224"
        Sky.SkyboxLf = "http://www.roblox.com/asset/?id=151165191"
        Sky.SkyboxRt = "http://www.roblox.com/asset/?id=151165206"
        Sky.SkyboxUp = "http://www.roblox.com/asset/?id=151165227"
        Sky.SunAngularSize = 10

        -- Configure lighting
        Lighting.Ambient = Color3.fromRGB(2,2,2)
        Lighting.Brightness = 2.25
        Lighting.ColorShift_Bottom = Color3.fromRGB(0,0,0)
        Lighting.ColorShift_Top = Color3.fromRGB(0,0,0)
        Lighting.EnvironmentDiffuseScale = 0.2
        Lighting.EnvironmentSpecularScale = 0.2
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
        Lighting.ShadowSoftness = 0.2
        Lighting.ClockTime = 7
        Lighting.GeographicLatitude = 25
        Lighting.ExposureCompensation = 0.5

        Atm.Density = 0
        Atm.Offset = 0.556
        Atm.Color = Color3.fromRGB(0, 0, 0)
        Atm.Decay = Color3.fromRGB(0, 0, 0)
        Atm.Glare = 0
        Atm.Haze = 1.72

        Rayfield:Notify({
            Title = "Lighting Changed",
            Content = "RTX Lighting preset has been applied",
            Duration = 3,
        })
    end
})

lightingTab:CreateButton({
    Name = "Advanced Lighting",
    Description = "Load preset in lighting",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        -- Remove existing effects
        for i, v in pairs(Lighting:GetChildren()) do
            if v then
                v:Destroy()
            end
        end

        -- Create and setup effects
        local Sky = Instance.new("Sky")
        local Bloom = Instance.new("BloomEffect")
        local ColorC = Instance.new("ColorCorrectionEffect")
        local SunRays = Instance.new("SunRaysEffect")

        -- Configure effects
        Sky.MoonAngularSize = 11
        Sky.MoonTextureId = "rbxasset://sky/moon.jpg"
        Sky.SkyboxBk = "rbxassetid://17843929750"
        Sky.SkyboxDn = "rbxassetid://17843931996"
        Sky.SkyboxFt = "rbxassetid://17843931265"
        Sky.SkyboxLf = "rbxassetid://17843929139"
        Sky.SkyboxRt = "rbxassetid://17843930617"
        Sky.SkyboxUp = "rbxassetid://17843932671"
        Sky.StarCount = 3000
        Sky.SunAngularSize = 21
        Sky.SunTextureId = "rbxasset://sky/sun.jpg"

        Bloom.Enabled = true
        Bloom.Intensity = 0.65
        Bloom.Size = 8
        Bloom.Threshold = 0.9

        ColorC.Brightness = 0
        ColorC.Contrast = 0.05
        ColorC.Enabled = true
        ColorC.Saturation = 0.2
        ColorC.TintColor = Color3.new(1, 1, 1)

        SunRays.Intensity = 0.25
        SunRays.Spread = 1
        SunRays.Enabled = true

        -- Parent effects to lighting
        Sky.Parent = Lighting
        Bloom.Parent = Lighting
        ColorC.Parent = Lighting
        SunRays.Parent = Lighting

        -- Configure lighting
        Lighting.Brightness = 1.43
        Lighting.Ambient = Color3.new(0.243137, 0.243137, 0.243137)
        Lighting.ShadowSoftness = 0.4
        Lighting.ClockTime = 13.4
        Lighting.OutdoorAmbient = Color3.new(0.243137, 0.243137, 0.243137)
        Lighting.GlobalShadows = true

        Rayfield:Notify({
            Title = "Lighting Changed",
            Content = "Advanced Lighting preset has been applied",
            Duration = 3,
        })
    end
})
