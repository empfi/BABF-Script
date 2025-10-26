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
    -- Wait for player with timeout
    local startTime = tick()
    local p
    repeat
        p = plrs.LocalPlayer
        task.wait(0.1)
    until p or (tick() - startTime) > 10
    
    if not p then
        error("Failed to get LocalPlayer after 10 seconds")
    end
    
    debugLog("Loading Rayfield...")
    -- Initialize Rayfield with retry
    local Rayfield
    for i = 1, 3 do
        local ok, res = pcall(function()
            return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
        end)
        if ok and res then
            Rayfield = res
            break
        end
        task.wait(1)
    end
    
    if not Rayfield then
        error("Failed to load Rayfield after 3 attempts")
    end

    task.wait(1) -- Extended wait for Rayfield

    debugLog("Creating window...")
    -- Create window with all required properties
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
    
    if not Window then
        error("Failed to create window")
    end

    task.wait(1) -- Extended wait after window creation
    debugLog("Window created successfully")

    -- Safe factory initialization
    local f = workspace:FindFirstChild(p.Name .. "Factory")
    if not f then
        f = Instance.new("Folder")
        f.Name = p.Name .. "Factory"
        f.Parent = workspace
        warn("Created placeholder factory")
    end

    -- Safe collectors initialization
    local c = f:FindFirstChild("Collectors")
    if not c then
        c = Instance.new("Folder")
        c.Name = "Collectors"
        c.Parent = f
        warn("Created placeholder collectors")
    end

    task.wait(0.5) -- Wait before creating tabs

    debugLog("Creating tabs...")
    -- Create tabs safely
    local tabs = {
        Main = Window:CreateTab("Main", 0),
        Experience = Window:CreateTab("Experience", 0),
        Lighting = Window:CreateTab("Lighting", 0),
        About = Window:CreateTab("About", 0),
        Dev = Window:CreateTab("Dev", 0)
    }

    -- Verify tabs created successfully
    for name, tab in pairs(tabs) do
        if not tab then
            error("Failed to create " .. name .. " tab")
        end
        debugLog(name .. " tab created successfully")
    end

    -- Add lighting controls directly instead of loading external module
    debugLog("Adding lighting controls...")
    tabs.Lighting:CreateButton({
        Name = "Enhanced RTX",
        Description = "Brighter RTX preset",
        Callback = function()
            local Lighting = game:GetService("Lighting")
            local success, err = pcall(function()
                -- Clean up existing effects
                for _, v in pairs(Lighting:GetChildren()) do v:Destroy() end
                
                -- Create new effects
                local effects = {
                    Bloom = {
                        Intensity = 0.5,
                        Size = 12,
                        Threshold = 0.8
                    },
                    ColorCorrection = {
                        Brightness = 0.25,
                        Contrast = 0.5,
                        Saturation = -0.1,
                        TintColor = Color3.fromRGB(255, 245, 235)
                    },
                    SunRays = {
                        Intensity = 0.15,
                        Spread = 0.8
                    }
                }

                -- Apply effects
                for name, props in pairs(effects) do
                    local effect = Instance.new(name .. "Effect")
                    for prop, value in pairs(props) do
                        effect[prop] = value
                    end
                    effect.Parent = Lighting
                end

                -- Configure lighting
                Lighting.Brightness = 2.8
                Lighting.Ambient = Color3.fromRGB(25, 25, 25)
                Lighting.ClockTime = 14
                Lighting.ExposureCompensation = 0.8
            end)

            if not success then
                warn("Failed to apply lighting:", err)
                debugLog("Lighting error: " .. tostring(err))
            else
                debugLog("Lighting applied successfully")
            end
        end
    })

    -- Dev Tab (holds developer tools like the updater)
    local Divider = tabs.Dev:CreateDivider()

    -- Update Button
    local updateButton = tabs.Dev:CreateButton({
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

    local collectLabel = tabs.Main:CreateLabel("Stand on the middle of collectors", "info")
    local Toggle = tabs.Main:CreateToggle({
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

    local lagToggle = tabs.Main:CreateToggle({
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
    local buyDropdown = tabs.Main:CreateDropdown({
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
    local buyToggle = tabs.Main:CreateToggle({
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

    local Paragraph = tabs.About:CreateParagraph({
        Title = "About Script",
        Content =
        "Hey! This script is free and fully keyless! Enjoy building your Brainrot Factory with ease and efficiency using this script.",
    })
end)

if not success then
    warn("Script crashed: " .. tostring(result))
    if game:GetService("Players").LocalPlayer then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Script Error",
            Text = tostring(result),
            Duration = 10
        })
    end
end
