local HttpService = game:GetService("HttpService")

local Config = {}
local FOLDER = "empfi"
local FILE = "BABF_config.json"
local DEFAULTS = {
    autoCollect = false,
    antiLagEnabled = false,
    autoBuyEnabled = false,
    selectedItems = {"Basic Conveyor"},
    lighting = {
        preset = "none", -- none | rtx | advanced
        shadowsDisabled = false,
    },
}

local function deepCopy(tbl)
    local t = {}
    for k, v in pairs(tbl) do
        t[k] = type(v) == "table" and deepCopy(v) or v
    end
    return t
end

local function merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = dst[k] or {}
            merge(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local function canFS()
    return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfolder) == "function" and typeof(makefolder) == "function"
end

local function getPath()
    return FOLDER .. "/" .. FILE
end

function Config.load()
    local cfg = deepCopy(DEFAULTS)

    if canFS() then
        pcall(function()
            if not isfolder(FOLDER) then makefolder(FOLDER) end
            if isfile(getPath()) then
                local contents = readfile(getPath())
                if contents and #contents > 0 then
                    local parsed = HttpService:JSONDecode(contents)
                    if type(parsed) == "table" then
                        merge(cfg, parsed)
                    end
                end
            end
        end)
    elseif getgenv and type(getgenv) == "function" then
        local g = getgenv()
        if g.__empfi_cfg then
            merge(cfg, g.__empfi_cfg)
        end
    end

    return cfg
end

function Config.save(cfg)
    if type(cfg) ~= "table" then return end

    if canFS() then
        pcall(function()
            if not isfolder(FOLDER) then makefolder(FOLDER) end
            writefile(getPath(), HttpService:JSONEncode(cfg))
        end)
    elseif getgenv and type(getgenv) == "function" then
        local g = getgenv()
        g.__empfi_cfg = cfg
    end
end

return Config
