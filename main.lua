local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local plrs = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Lightweight local module loader (executor FS or fallback)
local function loadLocalModule(path)
    local ok, src = pcall(function()
        return readfile and readfile(path)
    end)
    if ok and type(src) == "string" and #src > 0 then
        local fn = loadstring(src)
        if fn then
            local success, mod = pcall(fn)
            if success then return mod end
        end
    end
    return nil
end

local LightingMod = loadLocalModule("lighting.lua")
local Config = loadLocalModule("config.lua")
local cfg = Config and Config.load() or {
    autoCollect = false,
    antiLagEnabled = false,
    autoBuyEnabled = false,
    selectedItems = {"Basic Conveyor"},
    lighting = { preset = "none", shadowsDisabled = false },
}

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
    Icon = 0,  -- Add back icon
    LoadingTitle = "empfi loading...",
    LoadingSubtitle = "by empfi",
    ShowText = "empfi",  -- Add back ShowText
    Theme = "Default",   -- Add back Theme
    ToggleUIKeybind = "K", -- Add back keybind
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = false,
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
getgenv().autoBuyEnabled, getgenv().autoCollect = cfg.autoBuyEnabled, cfg.autoCollect
getgenv().selectedItems = cfg.selectedItems or { "Basic Conveyor" }

-- Auto Buy
local function tryPurchaseViaRemote(item)
    local ok = pcall(function()
        game:GetService("ReplicatedStorage")
            :WaitForChild("Remotes")
            :WaitForChild("Game")
            :WaitForChild("PurchaseItem")
            :FireServer(item)
    end)
    return ok
end

local function tryPurchaseViaPrompts(item)
    if not f then return false end
    local matched = false
    for _, obj in ipairs(f:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parentName = obj.Parent and obj.Parent.Name or ""
            local action = (obj.ActionText or "") .. " " .. (obj.ObjectText or "")
            if string.find(string.lower(parentName), string.lower(item), 1, true)
                or string.find(string.lower(action), string.lower(item), 1, true) then
                pcall(function() fireproximityprompt(obj) end)
                matched = true
            end
        end
    end
    return matched
end

function autoBuy()
    while getgenv().autoBuyEnabled do
        if getgenv().selectedItems and #getgenv().selectedItems > 0 then
            for _, item in ipairs(getgenv().selectedItems) do
                local okRemote = tryPurchaseViaRemote(item)
                if not okRemote then
                    tryPurchaseViaPrompts(item)
                else
                    -- Also try prompts as a backup to ensure pad purchases
                    tryPurchaseViaPrompts(item)
                end
            end
        end
        task.wait(1)
    end
end

local collectLabel = MainTab:CreateLabel("Stand on the middle of collectors", "info")
local Toggle = MainTab:CreateToggle({
    Name = "Auto Collect Nearby Collectors",
    CurrentValue = cfg.autoCollect,
    Flag = "AutoCollectToggle",
    Callback = function(state)
        getgenv().autoCollect = state
        cfg.autoCollect = state
        if Config then Config.save(cfg) end
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
getgenv().antiLagEnabled = cfg.antiLagEnabled

local lagToggle = MainTab:CreateToggle({
    Name = "Anti Lag",
    CurrentValue = cfg.antiLagEnabled,
    Flag = "AntiLagToggle",
    Callback = function(state)
        getgenv().antiLagEnabled = state
        cfg.antiLagEnabled = state
        if Config then Config.save(cfg) end
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
    CurrentOption = getgenv().selectedItems,
    MultipleOptions = true,
    Flag = "selectedItems",
    Callback = function(Options)
        getgenv().selectedItems = Options
        cfg.selectedItems = Options
        if Config then Config.save(cfg) end
        --print("Selected:", table.concat(getgenv().selectedItems, ", "))
    end,
})

-- Toggle for auto-buy
local buyToggle = MainTab:CreateToggle({
    Name = "Auto Buy",
    CurrentValue = cfg.autoBuyEnabled,
    Flag = "AutoBuyToggle",
    Callback = function(state)
        getgenv().autoBuyEnabled = state
        cfg.autoBuyEnabled = state
        if Config then Config.save(cfg) end
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

-- RTX Lighting Button
lightingTab:CreateButton({
    Name = "RTX Lighting",
    Callback = function()
        -- Confirm before applying
        if Window.CreatePrompt then -- Check if prompt exists
            Window:CreatePrompt({
                Title = "Apply RTX Lighting?",
                Content = "This will change your lighting settings and may affect performance.",
                Actions = {
                    Accept = {
                        Name = "Apply",
                        Callback = function()
                            if LightingMod and LightingMod.applyRTX then
                                LightingMod.applyRTX()
                            end
                            cfg.lighting.preset = "rtx"
                            if Config then Config.save(cfg) end
                            Rayfield:Notify({
                                Title = "Success",
                                Content = "RTX Lighting applied",
                                Duration = 3,
                            })
                        end
                    },
                    Cancel = {
                        Name = "Cancel"
                    }
                }
            })
        else
            if LightingMod and LightingMod.applyRTX then
                LightingMod.applyRTX()
            end
            cfg.lighting.preset = "rtx"
            if Config then Config.save(cfg) end
            Rayfield:Notify({
                Title = "Success",
                Content = "RTX Lighting applied",
                Duration = 3,
            })
        end
    end
})

-- Advanced Lighting Button  
lightingTab:CreateButton({
    Name = "Advanced Lighting",
    Callback = function()
        -- Confirm before applying
        if Window.CreatePrompt then -- Check if prompt exists
            Window:CreatePrompt({
                Title = "Apply Advanced Lighting?", 
                Content = "This will change your lighting settings and may affect performance.",
                Actions = {
                    Accept = {
                        Name = "Apply",
                        Callback = function()
                            if LightingMod and LightingMod.applyAdvanced then
                                LightingMod.applyAdvanced()
                            end
                            cfg.lighting.preset = "advanced"
                            if Config then Config.save(cfg) end
                            Rayfield:Notify({
                                Title = "Success",
                                Content = "Advanced Lighting applied",
                                Duration = 3,
                            })
                        end
                    },
                    Cancel = {
                        Name = "Cancel"
                    }
                }
            })
        else
            if LightingMod and LightingMod.applyAdvanced then
                LightingMod.applyAdvanced()
            end
            cfg.lighting.preset = "advanced"
            if Config then Config.save(cfg) end
            Rayfield:Notify({
                Title = "Success",
                Content = "Advanced Lighting applied",
                Duration = 3,
            })
        end
    end
})

-- Lighting: Disable Shadows toggle
local disableShadowsToggle = lightingTab:CreateToggle({
    Name = "Disable Shadows",
    CurrentValue = cfg.lighting and cfg.lighting.shadowsDisabled or false,
    Flag = "DisableShadowsToggle",
    Callback = function(state)
        if LightingMod and LightingMod.disableShadows then
            LightingMod.disableShadows(state)
        else
            local Lighting = game:GetService("Lighting")
            Lighting.GlobalShadows = not state
            Lighting.ShadowSoftness = state and 0 or 0.4
        end
        cfg.lighting = cfg.lighting or {}
        cfg.lighting.shadowsDisabled = state
        if Config then Config.save(cfg) end
        Rayfield:Notify({
            Title = "Lighting",
            Content = state and "Shadows disabled" or "Shadows enabled",
            Duration = 3,
        })
    end,
})

-- Apply saved lighting preset on load
task.spawn(function()
    if LightingMod then
        if cfg.lighting and cfg.lighting.preset == "rtx" and LightingMod.applyRTX then
            LightingMod.applyRTX()
        elseif cfg.lighting and cfg.lighting.preset == "advanced" and LightingMod.applyAdvanced then
            LightingMod.applyAdvanced()
        end
        if cfg.lighting and cfg.lighting.shadowsDisabled and LightingMod.disableShadows then
            LightingMod.disableShadows(true)
        end
    end
end)
