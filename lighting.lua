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
    local tab = Window:CreateTab("Lighting", 0)
    
    tab:CreateButton({
        Name = "Enhanced RTX",
        Description = "Brighter RTX preset",
        Callback = function()
            local Lighting = game:GetService("Lighting")
            for _, v in pairs(Lighting:GetChildren()) do v:Destroy() end
            
            -- Enhanced brightness values
            local settings = {
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
                },
                Atmosphere = {
                    Density = 0.2,
                    Offset = 0.5,
                    Color = Color3.fromRGB(200, 200, 200),
                    Decay = Color3.fromRGB(100, 100, 100),
                    Glare = 0.3,
                    Haze = 1.5
                }
            }

            -- Apply settings
            for name, props in pairs(settings) do
                local effect = Instance.new(name .. "Effect")
                for prop, value in pairs(props) do
                    effect[prop] = value
                end
                effect.Parent = Lighting
            end

            Lighting.Brightness = 2.8
            Lighting.Ambient = Color3.fromRGB(25, 25, 25)
            Lighting.ClockTime = 14
            Lighting.ExposureCompensation = 0.8
        end
    })

    return tab
end

return {
    createLightingTab = createLightingTab
}
