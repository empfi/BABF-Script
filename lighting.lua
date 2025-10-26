local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local function applyRTXLighting()
    local Lighting = game:GetService("Lighting")
    for i, v in pairs(Lighting:GetChildren()) do
        if v then v:Destroy() end
    end

    local effects = {
        Bloom = {
            Intensity = 0.4, -- Increased from 0.3
            Size = 10,
            Threshold = 0.8
        },
        Blur = { Size = 3 }, -- Reduced blur
        ColorCorrection = {
            Brightness = 0.2, -- Increased from 0.1
            Contrast = 0.5,
            Saturation = -0.2, -- Reduced negative saturation
            TintColor = Color3.fromRGB(255, 240, 215) -- Warmer tint
        },
        SunRays = {
            Intensity = 0.1, -- Increased from 0.075
            Spread = 0.727
        },
        Sky = {
            SkyboxBk = "http://www.roblox.com/asset/?id=151165214",
            SkyboxDn = "http://www.roblox.com/asset/?id=151165197",
            SkyboxFt = "http://www.roblox.com/asset/?id=151165224",
            SkyboxLf = "http://www.roblox.com/asset/?id=151165191",
            SkyboxRt = "http://www.roblox.com/asset/?id=151165206",
            SkyboxUp = "http://www.roblox.com/asset/?id=151165227",
            SunAngularSize = 10
        },
        Atmosphere = {
            Density = 0.1, -- Added some atmosphere
            Offset = 0.556,
            Color = Color3.fromRGB(199, 199, 199),
            Decay = Color3.fromRGB(92, 92, 92),
            Glare = 0.2,
            Haze = 1.72
        }
    }

    -- Create and configure effects
    for name, props in pairs(effects) do
        local effect = Instance.new(name .. (name ~= "Sky" and "Effect" or ""))
        for prop, value in pairs(props) do
            effect[prop] = value
        end
        effect.Parent = Lighting
    end

    -- Configure lighting properties
    Lighting.Ambient = Color3.fromRGB(5, 5, 5) -- Brighter ambient
    Lighting.Brightness = 2.5 -- Increased from 2.25
    Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
    Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    Lighting.EnvironmentDiffuseScale = 0.2
    Lighting.EnvironmentSpecularScale = 0.2
    Lighting.GlobalShadows = true
    Lighting.OutdoorAmbient = Color3.fromRGB(5, 5, 5)
    Lighting.ShadowSoftness = 0.2
    Lighting.ClockTime = 14 -- Changed to mid-day
    Lighting.GeographicLatitude = 25
    Lighting.ExposureCompensation = 0.6 -- Increased from 0.5
end

local function createLightingTab(Window)
    local lightingTab = Window:CreateTab("Lighting", 0)
    local Divider = lightingTab:CreateDivider()

    lightingTab:CreateButton({
        Name = "RTX Lighting",
        Description = "Enhanced brightness RTX preset",
        Callback = function()
            applyRTXLighting()
            Rayfield:Notify({
                Title = "Success",
                Content = "Enhanced RTX Lighting applied",
                Duration = 3,
            })
        end
    })

    -- Keep existing Advanced Lighting button
    lightingTab:CreateButton({
        Name = "Advanced Lighting",
        Description = "Load preset in lighting",
        Callback = function()
            -- ...existing Advanced Lighting implementation...
        end
    })

    return lightingTab
end

return {
    createLightingTab = createLightingTab,
    applyRTXLighting = applyRTXLighting
}
