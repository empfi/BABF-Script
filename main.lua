local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local plrs = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

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
    antiAfkEnabled = false,
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

-- Tabs
local MainTab = Window:CreateTab("Main")
local Divider = MainTab:CreateDivider()
local experienceTab = Window:CreateTab("Experience")
local Divider = experienceTab:CreateDivider()
local aboutTab = Window:CreateTab("About")
local Divider = aboutTab:CreateDivider()

-- Dev Tab (holds developer tools like the updater)
local devTab = Window:CreateTab("Dev")
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
        })
        warn("Update Script errors:\n" .. table.concat(errors, "\n"))
    end,
})

-- Anti-AFK initialization
if getgenv().afk_toggle == nil then
    getgenv().afk_toggle = (cfg.antiAfkEnabled == true)
end
local VirtualUser = game:GetService("VirtualUser")
local status = getgenv().afk_toggle
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
getgenv().afk_toggle = cfg.antiAfkEnabled == true

-- Auto Buy
local function findAssetByName(name)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local assets = ReplicatedStorage:FindFirstChild("Assets") or ReplicatedStorage:WaitForChild("Assets", 2)
    if not assets then return nil end
    local lower = string.lower(name)
    for _, d in ipairs(assets:GetDescendants()) do
        if d.Name and string.lower(d.Name) == lower then
            return d
        end
    end
    return nil
end

local function tryPurchaseViaRemote(item)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ok = pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 2)
        if not remotes then return end
        local gameFolder = remotes:FindFirstChild("Game") or remotes:WaitForChild("Game", 2)
        if not gameFolder then return end
        local purchase = gameFolder:FindFirstChild("PurchaseItem") or gameFolder:WaitForChild("PurchaseItem", 2)
        if not purchase then return end
        local asset = findAssetByName(item)
        if asset then
            -- Try instance-based first, then name as fallback
            pcall(function() purchase:FireServer(asset) end)
        end
        pcall(function() purchase:FireServer(item) end)
    end)
    return ok
end

local function tryPurchaseViaPrompts(item)
    if not f then return false end
    local matched = false
    local keywords = {"buy","purchase","unlock","acquire"}
    for _, obj in ipairs(f:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parentName = obj.Parent and obj.Parent.Name or ""
            local actionText = string.lower((obj.ActionText or ""))
            local objectText = string.lower((obj.ObjectText or ""))
            local fullname = string.lower(parentName .. " " .. actionText .. " " .. objectText)
            local it = string.lower(item)
            local keywordHit = false
            for _, kw in ipairs(keywords) do
                if string.find(fullname, kw, 1, true) then keywordHit = true break end
            end
            if (string.find(fullname, it, 1, true) or keywordHit) and obj.Enabled ~= false then
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
        task.wait(0.5)
    end
end

local collectLabel = MainTab:CreateLabel("Stand on the middle of collectors", "info")
local __collectConn
local Toggle = MainTab:CreateToggle({
    Name = "Auto Collect Nearby Collectors",
    CurrentValue = cfg.autoCollect,
    Flag = "AutoCollectToggle",
    Callback = function(state)
        getgenv().autoCollect = state
        cfg.autoCollect = state
        if Config then Config.save(cfg) end
        if __collectConn then __collectConn:Disconnect(); __collectConn = nil end
        if state then
            print("Auto Collect: ON")
            __collectConn = RunService.Heartbeat:Connect(function()
                nearbyCollect()
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
-- Robust sound mute that persists and handles new sounds without touching SoundService.Volume
local __empfi_sound_conns = {}
local function muteSoundInstance(snd)
    if not snd or not snd:IsA("Sound") then return end
    if snd:GetAttribute("empfi_prevVol") == nil then
        snd:SetAttribute("empfi_prevVol", snd.Volume)
    end
    snd.Volume = 0
end
local function unmuteSoundInstance(snd)
    if not snd or not snd:IsA("Sound") then return end
    local prev = snd:GetAttribute("empfi_prevVol")
    if typeof(prev) == "number" then snd.Volume = prev end
end
local function setGlobalMute(state)
    if state then
        for _, s in ipairs(game:GetDescendants()) do
            if s:IsA("Sound") then
                pcall(muteSoundInstance, s)
            end
        end
        if not __empfi_sound_conns.desc then
            __empfi_sound_conns.desc = game.DescendantAdded:Connect(function(obj)
                if obj:IsA("Sound") then
                    pcall(muteSoundInstance, obj)
                end
            end)
        end
    else
        if __empfi_sound_conns.desc then
            __empfi_sound_conns.desc:Disconnect()
            __empfi_sound_conns.desc = nil
        end
        for _, s in ipairs(game:GetDescendants()) do
            if s:IsA("Sound") then
                pcall(unmuteSoundInstance, s)
            end
        end
    end
end

local soundToggle = experienceTab:CreateToggle({
    Name = "Disable Game Sounds",
    CurrentValue = false,
    Flag = "DisableSoundsToggle",
    Callback = function(state)
        setGlobalMute(state)
        Rayfield:Notify({
            Title = "empfi | Build a Brainrot Factory",
            Content = state and "Game sounds disabled" or "Game sounds enabled",
            Duration = 3,
        })
    end,
})

local Paragraph = aboutTab:CreateParagraph({
    Title = "About Script",
    Content =
    "Hey! This script is free and fully keyless! Enjoy building your Brainrot Factory with ease and efficiency using this script.",
})

-- Add Lighting tab and buttons
local lightingTab = Window:CreateTab("Lighting")
local Divider = lightingTab:CreateDivider()

-- Graphics section
lightingTab:CreateLabel("Graphics Presets")
local rtxToggleUI, advToggleUI
local __suppressLightingToggle = false
local function applyLighting(preset)
    if not LightingMod then return end
    if preset == "rtx" and LightingMod.applyRTX then
        LightingMod.applyRTX()
    elseif preset == "advanced" and LightingMod.applyAdvanced then
        LightingMod.applyAdvanced()
    elseif LightingMod.applyDefault then
        LightingMod.applyDefault()
    end
    -- short watchdog: some games override lighting immediately; reapply once if stripped
    task.delay(0.2, function()
        local Lighting = game:GetService("Lighting")
        local hasEffects = false
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect") then
                hasEffects = true; break
            end
        end
        if preset ~= "none" and not hasEffects then
            if preset == "rtx" and LightingMod.applyRTX then
                LightingMod.applyRTX()
            elseif preset == "advanced" and LightingMod.applyAdvanced then
                LightingMod.applyAdvanced()
            end
        end
        if cfg.lighting and cfg.lighting.shadowsDisabled and LightingMod.disableShadows then
            LightingMod.disableShadows(true)
        end
    end)
end

rtxToggleUI = lightingTab:CreateToggle({
    Name = "RTX Lighting",
    CurrentValue = cfg.lighting and cfg.lighting.preset == "rtx",
    Flag = "RTXLightingToggle",
    Callback = function(state)
        if __suppressLightingToggle then return end
        if state then
            applyLighting("rtx")
            cfg.lighting.preset = "rtx"
            if advToggleUI and advToggleUI.Set then
                __suppressLightingToggle = true
                advToggleUI:Set(false)
                __suppressLightingToggle = false
            end
        else
            -- On disable, always reset to default graphics
            if cfg.lighting.preset == "rtx" then
                cfg.lighting.preset = "none"
                applyLighting("none")
            end
        end
        if Config then Config.save(cfg) end
    end
})

advToggleUI = lightingTab:CreateToggle({
    Name = "Advanced Lighting",
    CurrentValue = cfg.lighting and cfg.lighting.preset == "advanced",
    Flag = "AdvancedLightingToggle",
    Callback = function(state)
        if __suppressLightingToggle then return end
        if state then
            applyLighting("advanced")
            cfg.lighting.preset = "advanced"
            if rtxToggleUI and rtxToggleUI.Set then
                __suppressLightingToggle = true
                rtxToggleUI:Set(false)
                __suppressLightingToggle = false
            end
        else
            -- On disable, always reset to default graphics
            if cfg.lighting.preset == "advanced" then
                cfg.lighting.preset = "none"
                applyLighting("none")
            end
        end
        if Config then Config.save(cfg) end
    end
})

lightingTab:CreateButton({
    Name = "Reset to Default Graphics",
    Callback = function()
        applyLighting("none")
        cfg.lighting.preset = "none"
        if rtxToggleUI and rtxToggleUI.Set then rtxToggleUI:Set(false) end
        if advToggleUI and advToggleUI.Set then advToggleUI:Set(false) end
        if Config then Config.save(cfg) end
        Rayfield:Notify({ Title = "Graphics", Content = "Reset to default", Duration = 3 })
    end
})

-- Advanced Graphics section
lightingTab:CreateLabel("Advanced Graphics")
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

-- Farm tab
local farmTab = Window:CreateTab("Farm")
local antiAfkToggle = farmTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = cfg.antiAfkEnabled == true,
    Flag = "AntiAfkToggle",
    Callback = function(state)
        cfg.antiAfkEnabled = state
        getgenv().afk_toggle = state
        if Config then Config.save(cfg) end
        Rayfield:Notify({
            Title = "Farm",
            Content = state and "Anti-AFK enabled" or "Anti-AFK disabled",
            Duration = 3,
        })
    end,
})

-- Apply saved lighting preset on load (requires lighting.lua present)
task.spawn(function()
    if LightingMod and cfg.lighting then
        applyLighting(cfg.lighting.preset or "none")
    end
end)

-- (removed stray connections)
