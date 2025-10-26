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

-- Update Button
local updateButton = devTab:CreateButton({
    Name = "Update Script",
    Callback = function()
        local success, result = pcall(function()
            local rawUrl = "https://raw.githubusercontent.com/empfi/BABF-Script/main/main.lua"
            local newScript = game:HttpGet(rawUrl)
            
            if newScript and #newScript > 0 then
                -- Simple loadstring with error catching
                local fn, loadErr = loadstring(newScript)
                if not fn then error("Failed to compile: " .. tostring(loadErr)) end
                
                fn()  -- Execute the new script
                Rayfield:Destroy()
                Rayfield:Notify({
                    Title = "empfi | Build a Brainrot Factory",
                    Content = "Script successfully updated!",
                    Duration = 5,
                    Image = "loader",
                })
            else
                error("Empty script received")
            end
        end)
        
        if not success then
            Rayfield:Notify({
                Title = "empfi | Build a Brainrot Factory",
                Content = "Update failed: " .. tostring(result),
                Duration = 6,
                Image = "loader",
            })
        end
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

-- Add Experience tab with sound mute toggle
local experienceTab = Window:CreateTab("Experience", "speaker")
local Divider = experienceTab:CreateDivider()

-- Sound mute state and helpers
getgenv().soundsMuted = false
local originalVolumes = {}
local soundConn

local function muteSoundInstance(snd)
	-- ...only operate on Sound instances
	if not snd or not snd:IsA or not snd:IsA("Sound") then return end
	-- save original once
	if originalVolumes[snd] == nil then
		originalVolumes[snd] = snd.Volume
	end
	-- mute client-side
	pcall(function() snd.Volume = 0 end)
end

local function unmuteSoundInstance(snd)
	if not snd or not snd:IsA or not snd:IsA("Sound") then return end
	local orig = originalVolumes[snd]
	if orig ~= nil then
		pcall(function() snd.Volume = orig end)
		originalVolumes[snd] = nil
	else
		-- fallback restore to 1 if unknown
		pcall(function() snd.Volume = 1 end)
	end
end

local function muteAllSounds()
	-- mute existing sounds
	for _, inst in ipairs(game:GetDescendants()) do
		if inst:IsA("Sound") then
			muteSoundInstance(inst)
		end
	end
	-- ensure new sounds are muted while toggled
	if not soundConn then
		soundConn = game.DescendantAdded:Connect(function(inst)
			if inst and inst:IsA and inst:IsA("Sound") then
				muteSoundInstance(inst)
			end
		end)
	end
end

local function unmuteAllSounds()
	-- stop listening for new sounds
	if soundConn then
		pcall(function() soundConn:Disconnect() end)
		soundConn = nil
	end
	-- restore saved volumes
	for snd, _ in pairs(originalVolumes) do
		if snd and snd:IsA and snd:IsA("Sound") then
			unmuteSoundInstance(snd)
		end
	end
	-- clear storage
	originalVolumes = {}
end

-- Toggle UI: disable game sounds (client-side)
local soundToggle = experienceTab:CreateToggle({
	Name = "Disable Game Sounds (client-side)",
	CurrentValue = false,
	Flag = "DisableSoundsToggle",
	Callback = function(state)
		getgenv().soundsMuted = state
		if state then
			muteAllSounds()
			Rayfield:Notify({
				Title = "empfi | Experience",
				Content = "Game sounds disabled (client-side).",
				Duration = 4,
				Image = "loader",
			})
		else
			unmuteAllSounds()
			Rayfield:Notify({
				Title = "empfi | Experience",
				Content = "Game sounds restored.",
				Duration = 4,
				Image = "loader",
			})
		end
	end,
})
