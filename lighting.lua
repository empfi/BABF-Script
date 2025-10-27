local LightingService = game:GetService("Lighting")

local LightingMod = {}

local function clearEffects()
    for _, v in ipairs(LightingService:GetChildren()) do
        if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect")
            or v:IsA("SunRaysEffect") or v:IsA("Sky") or v:IsA("Atmosphere")
            or v:IsA("DepthOfFieldEffect") or v:IsA("ColorCorrectionEffect") then
            v:Destroy()
        end
    end
end

function LightingMod.disableShadows(disabled)
    LightingService.GlobalShadows = not disabled
    LightingService.ShadowSoftness = disabled and 0 or 0.4
end

function LightingMod.applyRTX()
    clearEffects()
    local Bloom = Instance.new("BloomEffect")
    local Blur = Instance.new("BlurEffect")
    local ColorCor = Instance.new("ColorCorrectionEffect")
    local SunRays = Instance.new("SunRaysEffect")
    local Sky = Instance.new("Sky")
    local Atm = Instance.new("Atmosphere")
    local DoF = Instance.new("DepthOfFieldEffect")

    Bloom.Intensity = 0.4
    Bloom.Size = 12
    Bloom.Threshold = 0.85

    Blur.Size = 2

    ColorCor.Brightness = 0.15
    ColorCor.Contrast = 0.5
    ColorCor.Saturation = -0.05
    ColorCor.TintColor = Color3.fromRGB(255, 245, 235)

    SunRays.Intensity = 0.15
    SunRays.Spread = 0.8

    DoF.FarIntensity = 0.2
    DoF.FocusDistance = 35
    DoF.InFocusRadius = 25
    DoF.NearIntensity = 0.15

    Sky.SkyboxBk = "http://www.roblox.com/asset/?id=151165214"
    Sky.SkyboxDn = "http://www.roblox.com/asset/?id=151165197"
    Sky.SkyboxFt = "http://www.roblox.com/asset/?id=151165224"
    Sky.SkyboxLf = "http://www.roblox.com/asset/?id=151165191"
    Sky.SkyboxRt = "http://www.roblox.com/asset/?id=151165206"
    Sky.SkyboxUp = "http://www.roblox.com/asset/?id=151165227"
    Sky.SunAngularSize = 12

    Bloom.Parent = LightingService
    Blur.Parent = LightingService
    ColorCor.Parent = LightingService
    SunRays.Parent = LightingService
    Sky.Parent = LightingService
    Atm.Parent = LightingService
    DoF.Parent = LightingService

    LightingService.Ambient = Color3.fromRGB(20, 20, 25)
    LightingService.Brightness = 3
    LightingService.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
    LightingService.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    LightingService.EnvironmentDiffuseScale = 0.25
    LightingService.EnvironmentSpecularScale = 0.3
    LightingService.GlobalShadows = true
    LightingService.OutdoorAmbient = Color3.fromRGB(20, 20, 25)
    LightingService.ShadowSoftness = 0.25
    LightingService.ClockTime = 7.25
    LightingService.GeographicLatitude = 25
    LightingService.ExposureCompensation = 0.35

    Atm.Density = 0.05
    Atm.Offset = 0.5
    Atm.Color = Color3.fromRGB(200, 210, 235)
    Atm.Decay = Color3.fromRGB(120, 140, 160)
    Atm.Glare = 0
    Atm.Haze = 2
end

function LightingMod.applyAdvanced()
    clearEffects()

    local Sky = Instance.new("Sky")
    local Bloom = Instance.new("BloomEffect")
    local ColorC = Instance.new("ColorCorrectionEffect")
    local SunRays = Instance.new("SunRaysEffect")

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
    ColorC.Contrast = 0.08
    ColorC.Enabled = true
    ColorC.Saturation = 0.2
    ColorC.TintColor = Color3.new(1, 1, 1)

    SunRays.Intensity = 0.25
    SunRays.Spread = 1
    SunRays.Enabled = true

    Sky.Parent = LightingService
    Bloom.Parent = LightingService
    ColorC.Parent = LightingService
    SunRays.Parent = LightingService

    LightingService.Brightness = 1.6
    LightingService.Ambient = Color3.new(0.25, 0.25, 0.25)
    LightingService.ShadowSoftness = 0.4
    LightingService.ClockTime = 13.4
    LightingService.OutdoorAmbient = Color3.new(0.25, 0.25, 0.25)
    LightingService.GlobalShadows = true
end

function LightingMod.clear()
    clearEffects()
end

return LightingMod
