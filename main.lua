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
        local HttpService = game:GetService("HttpService")
        local success, result = pcall(function()
            -- Try GitHub API first to get a reliable download_url for the latest file
            local apiUrl = "https://api.github.com/repos/empfi/BABF-Script/contents/main.lua"
            local downloadUrl
            local ok, apiResp = pcall(function()
                return game:HttpGet(apiUrl)
            end)

            if ok and apiResp then
                local parsed
                local decOk, decErr = pcall(function()
                    parsed = HttpService:JSONDecode(apiResp)
                end)
                if decOk and parsed and parsed.download_url then
                    downloadUrl = parsed.download_url
                end
            end

            -- Fallback to raw GitHub URL if API failed or didn't provide download_url
            if not downloadUrl then
                downloadUrl = "https://raw.githubusercontent.com/empfi/BABF-Script/main/main.lua"
            end

            -- Fetch the actual script content
            local newScript = game:HttpGet(downloadUrl)
            if newScript and #newScript > 0 then
                local loadOk, loadErr = pcall(function()
                    loadstring(newScript)()
                end)
                if not loadOk then
                    error(("Failed to load updated script: %s"):format(tostring(loadErr)))
                end

                -- Clean up UI and notify
                Rayfield:Destroy()
                Rayfield:Notify({
                    Title = "empfi | Build a Brainrot Factory",
                    Content = "Script successfully updated!",
                    Duration = 5,
                    Image = "loader",
                })
            else
                error("Downloaded script is empty")
            end
        end)

        if not success then
            Rayfield:Notify({
                Title = "empfi | Build a Brainrot Factory",
                Content = "Failed to update script. Please try again later.",
                Duration = 5,
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
    "This script is free and fully keyless! Enjoy building your Brainrot Factory with ease and efficiency using this script.",
})
