local addonName, ns = ...
local addonEnv = ns
local Themes = addonEnv.Themes
local FONT = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf"
local Skin = {FONT = FONT}
addonEnv.Skin = Skin
local hidden = setmetatable({}, {__mode = "k"})
local kept = setmetatable({}, {__mode = "k"})
local hooks = setmetatable({}, {__mode = "k"})
local bindings = setmetatable({}, {__mode = "k"})

-- Hooks owner[method] once, even when several skins ask for the same hook.
function Skin.Hook(owner, method, callback)
    if not owner or type(owner[method]) ~= "function" then return end
    hooks[owner] = hooks[owner] or {}
    if hooks[owner][method] then return end
    hooks[owner][method] = true
    hooksecurefunc(owner, method, callback)
end

-- Fades a region out and keeps it at alpha 0 when Blizzard code restores it.
function Skin.Hide(region)
    if not region or hidden[region] then return end
    hidden[region] = true
    region:SetAlpha(0)
    hooksecurefunc(region, "SetAlpha", function(self, alpha)
        if alpha ~= 0 then self:SetAlpha(0) end
    end)
end

function Skin.HideTextures(frame, except)
    if not frame then return end
    for _, region in ipairs({frame:GetRegions()}) do
        if region:GetObjectType() == "Texture" and region ~= except then Skin.Hide(region) end
    end
end

-- Hides a region and keeps it hidden when Blizzard code shows it again.
function Skin.KeepHidden(region)
    if not region then return end
    region:Hide()
    if kept[region] then return end
    kept[region] = true
    local function Rehide(self) if self:IsShown() then self:Hide() end end
    hooksecurefunc(region, "Show", Rehide)
    hooksecurefunc(region, "SetShown", Rehide)
end

-- Clears every texture's alpha; keepHidden also holds them hidden through Show calls.
function Skin.HideArt(owner, keepHidden)
    if not owner then return end
    for _, region in ipairs({owner:GetRegions()}) do
        if region:GetObjectType() == "Texture" then
            region:SetAlpha(0)
            if keepHidden then Skin.KeepHidden(region) end
        end
    end
end

-- Applies a palette token now and again whenever the theme changes.
function Skin.Color(region, method, token)
    if not region then return end
    bindings[region] = bindings[region] or {}
    bindings[region][method] = token
    region[method](region, unpack(Themes.GetPalette()[token]))
end

-- FFXIV text always carries a faint drop shadow.
function Skin.Font(region, size)
    if not region then return end
    local _, nativeSize = region:GetFont()
    region:SetFont(ns.GetFont and ns.GetFont(FONT) or FONT, size or nativeSize or 12, "")
    region:SetShadowColor(0, 0, 0, 0.8)
    if region.SetShadowOffset then region:SetShadowOffset(1, -1) end
end

function Skin.Text(region, token, size)
    if not region then return end
    Skin.Font(region, size)
    Skin.Color(region, "SetTextColor", token or "text")
end

function Skin.Fonts(frame, token)
    if not frame then return end
    for _, region in ipairs({frame:GetRegions()}) do
        if region:GetObjectType() == "FontString" then Skin.Text(region, token) end
    end
end

-- Non-mouse overlay at the owner's level; a token adds a flat themed backdrop.
function Skin.Panel(owner, token)
    local panel = CreateFrame("Frame", nil, owner, "BackdropTemplate")
    panel:SetAllPoints(owner)
    panel:SetFrameLevel(owner:GetFrameLevel())
    panel:EnableMouse(false)
    if token then
        panel:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1, insets = {left = 1, right = 1, top = 1, bottom = 1},
        })
        Skin.Color(panel, "SetBackdropColor", token)
        Skin.Color(panel, "SetBackdropBorderColor", "border")
    end
    return panel
end

Themes.Register(function(palette)
    Skin.painting = true
    for region, methods in pairs(bindings) do
        for method, token in pairs(methods) do region[method](region, unpack(palette[token])) end
    end
    Skin.painting = false
end)
