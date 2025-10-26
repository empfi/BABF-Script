-- Debug function
local function debugLog(msg)
    print("[DEBUG] " .. msg)
    if game:GetService("Players").LocalPlayer then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Debug",
            Text = msg,
            Duration = 3
        })
    end
end

local success, result = pcall(function()
    debugLog("Starting initialization...")
    
    -- Initialize core services first
    local plrs = game:GetService("Players")
    local replicatedStorage = game:GetService("ReplicatedStorage")
    
    debugLog("Waiting for player...")
    local p = plrs.LocalPlayer
    if not p then
        error("No LocalPlayer found")
    end

    debugLog("Loading UI...")
    -- Simplified Rayfield initialization
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    if not Rayfield then error("Failed to load Rayfield") end

    -- Simple window creation with minimal properties
    local Window = Rayfield:CreateWindow({
        Name = "empfi | Build a Brainrot Factory",
        LoadingTitle = "Loading...",
        LoadingSubtitle = "by empfi",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "empfi",
            FileName = "BABF"
        }
    })
    
    if not Window then error("Failed to create window") end
    debugLog("Window created")

    -- Create basic tabs first
    local MainTab = Window:CreateTab("Main", 0)
    if not MainTab then error("Failed to create Main tab") end
    debugLog("Main tab created")

    -- Create a simple test button to verify UI works
    local success, err = pcall(function()
        MainTab:CreateButton({
            Name = "Test Button",
            Callback = function()
                debugLog("Test button works!")
            end
        })
    end)

    if not success then
        error("Failed to create test button: " .. tostring(err))
    end
    debugLog("Test button created")

    -- If we got this far, try creating the rest
    local tabs = {
        Experience = Window:CreateTab("Experience", 0),
        About = Window:CreateTab("About", 0)
    }

    for name, tab in pairs(tabs) do
        if not tab then error("Failed to create " .. name .. " tab") end
        debugLog(name .. " tab created")
    end

    -- Create minimal content for testing
    tabs.Experience:CreateToggle({
        Name = "Sound Toggle",
        CurrentValue = false,
        Flag = "SoundToggle",
        Callback = function(state)
            local sound = game:GetService("SoundService")
            sound.Volume = state and 0 or 1
        end
    })

    -- Basic about content
    tabs.About:CreateParagraph({
        Title = "About",
        Content = "Test Version"
    })

    debugLog("Basic UI setup complete")
end)

if not success then
    warn("SCRIPT ERROR: " .. tostring(result))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Critical Error",
            Text = tostring(result),
            Duration = 30
        })
    end)
end
