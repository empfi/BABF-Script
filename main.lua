local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

Rayfield:Notify({
    Title = "empfi | Build a Brainrot Factory",
    Content = "Loading!",
    Duration = 5,
    Image = "loader",
})
local Window = Rayfield:CreateWindow({
    Name = "empfi | Build a Brainrot Factory",
    Icon = 0,
    LoadingTitle = "empfi loading...",
    LoadingSubtitle = "by empfi",
    ShowText = "empfi",
    Theme = "Default",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = false,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "empfi",
        FileName = "BABF"
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", "tractor")
local Divider = MainTab:CreateDivider()
local aboutTab = Window:CreateTab("About", "info")
local Divider = aboutTab:CreateDivider()

-- Dev Tab (holds developer tools like the updater)
local devTab = Window:CreateTab("Dev", "folder")
local Divider = devTab:CreateDivider()

-- Update Button (use r.jina.ai first, fallback to raw.githubusercontent)
local updateButton = devTab:CreateButton({
    Name = "Update Script",
    Callback = function()
        local sources = {
            { name = "r.jina.ai (proxy)", url = "https://r.jina.ai/http://raw.githubusercontent.com/empfi/BABF-Script/main/main.lua" },
            { name = "GitHub Raw (fallback)", url = "https://raw.githubusercontent.com/empfi/BABF-Script/main/main.lua" },
        }

        local errors = {}
        for _, src in ipairs(sources) do
            local ok, content = pcall(function() return game:HttpGet(src.url) end)
            if not ok or not content or #content == 0 then
                table.insert(errors, (src.name .. ": fetch failed"))
            else
                local loaded, loadErr = pcall(function() loadstring(content)() end)
                if loaded then
                    Rayfield:Destroy()
                    Rayfield:Notify({
                        Title = "empfi | Build a Brainrot Factory",
                        Content = "Script updated successfully from " .. src.name,
                        Duration = 5,
                        Image = "loader",
                    })
                    return
                else
                    table.insert(errors, (src.name .. ": load error - " .. tostring(loadErr)))
                end
            end
        end

        -- All sources failed: open API page in host browser as a fallback for inspection
        local apiUrl = "https://api.github.com/repos/empfi/BABF-Script/contents/main.lua"
        pcall(function()
            if type(os) == "table" and type(os.execute) == "function" then
                os.execute(string.format('$BROWSER "%s"', apiUrl))
            end
        end)

        Rayfield:Notify({
            Title = "empfi | Build a Brainrot Factory",
            Content = "Update failed: " .. table.concat(errors, " | "),
            Duration = 8,
            Image = "loader",
        })
    end,
})

local plrs = game:GetService("Players")
local p = plrs.LocalPlayer
local f = workspace:WaitForChild(p.Name .. "Factory")
local c = f:WaitForChild("Collectors")

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
            autoBuy()
        else
            print("Auto Buy: OFF")
        end
    end,
})

local Paragraph = aboutTab:CreateParagraph({
    Title = "About Script",
    Content =
    "Hey! This script is free and fully keyless! Enjoy building your Brainrot Factory with ease and efficiency using this script.",
})

-- Experience Tab: mute/unmute all game sounds
local experienceTab = Window:CreateTab("Experience", "music") -- icon name may vary by theme
local Divider = experienceTab:CreateDivider()

getgenv().muteSounds = false
local prevVolumes = {}
local soundConn
local SoundService = game:GetService("SoundService")
local prevSoundServiceVolume = SoundService.Volume

local function muteAllSounds()
    prevVolumes = {}
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("Sound") then
            prevVolumes[obj] = obj.Volume
            pcall(function() obj.Volume = 0 end)
        end
    end
    prevSoundServiceVolume = SoundService.Volume
    pcall(function() SoundService.Volume = 0 end)
    soundConn = game.DescendantAdded:Connect(function(desc)
        if desc:IsA("Sound") then
            prevVolumes[desc] = desc.Volume
            pcall(function() desc.Volume = 0 end)
        end
    end)
end

local function restoreAllSounds()
    if soundConn then
        pcall(function() soundConn:Disconnect() end)
        soundConn = nil
    end
    for s, vol in pairs(prevVolumes) do
        if s and s.Parent then
            pcall(function() s.Volume = vol end)
        end
    end
    prevVolumes = {}
    pcall(function() SoundService.Volume = prevSoundServiceVolume end)
end

local muteToggle = experienceTab:CreateToggle({
    Name = "Mute All Sounds",
    CurrentValue = false,
    Flag = "MuteSoundsToggle",
    Callback = function(state)
        getgenv().muteSounds = state
        if state then
            muteAllSounds()
            Rayfield:Notify({
                Title = "empfi | Build a Brainrot Factory",
                Content = "All sounds muted.",
                Duration = 4,
                Image = "loader",
            })
        else
            restoreAllSounds()
            Rayfield:Notify({
                Title = "empfi | Build a Brainrot Factory",
                Content = "Sounds restored.",
                Duration = 4,
                Image = "loader",
            })
        end
    end,
})
