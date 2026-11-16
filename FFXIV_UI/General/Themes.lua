local addonName, ns = ...
local addonEnv = ns
local Themes = {}
addonEnv.Themes = Themes
local listeners = {}
local names = {"Dark", "Light", "Classic FF", "Clear Blue", "Clear White", "Clear Green", "Clear Grey", "Clear Pink"}
local palettes = {}

local function Palette(name, surface, inset, border, text, muted, accent, tab, selected)
    palettes[name] = {
        surface = surface, inset = inset, border = border, text = text, muted = muted,
        accent = accent, tab = tab, selected = selected,
        tabText = {0.96, 0.95, 0.92, 1}, indicator = {1, 0.82, 0.3, 1},
        beneficial = {0, 1, 0, 1}, detrimental = {1, 0.3, 0.3, 1},
    }
end
Palette("Dark", {0.16, 0.16, 0.16, 0.98}, {0.11, 0.11, 0.11, 1}, {0.4, 0.39, 0.35, 1},
    {0.88, 0.86, 0.8, 1}, {0.76, 0.73, 0.65, 1}, {0.85, 0.75, 0.51, 1},
    {0.25, 0.25, 0.24, 1}, {0.12, 0.12, 0.11, 1})
Palette("Light", {0.93, 0.85, 0.69, 0.98}, {0.86, 0.77, 0.62, 1}, {0.43, 0.31, 0.21, 1},
    {0.29, 0.19, 0.15, 1}, {0.39, 0.28, 0.21, 1}, {0.4, 0.25, 0.12, 1},
    {0.45, 0.34, 0.24, 1}, {0.25, 0.16, 0.07, 1})
Palette("Classic FF", {0.13, 0.02, 0.61, 1}, {0.08, 0.01, 0.4, 1}, {0.85, 0.85, 0.9, 1},
    {1, 1, 1, 1}, {0.8, 0.82, 1, 1}, {1, 1, 1, 1},
    {0.2, 0.15, 0.8, 1}, {0.05, 0.02, 0.38, 1})
Palette("Clear Blue", {0.12, 0.23, 0.43, 0.96}, {0.08, 0.16, 0.31, 1}, {0.15, 0.39, 0.8, 1},
    {0.96, 0.97, 1, 1}, {0.75, 0.82, 0.96, 1}, {0.8, 0.89, 1, 1},
    {0.23, 0.34, 0.54, 1}, {0.05, 0.15, 0.36, 1})
Palette("Clear White", {0.78, 0.79, 0.79, 0.98}, {0.68, 0.7, 0.7, 1}, {0.87, 0.88, 0.88, 1},
    {0.29, 0.2, 0.17, 1}, {0.36, 0.3, 0.27, 1}, {0.3, 0.22, 0.18, 1},
    {0.55, 0.56, 0.56, 1}, {0.36, 0.37, 0.37, 1})
Palette("Clear Green", {0.19, 0.4, 0.12, 0.96}, {0.1, 0.26, 0.05, 1}, {0.35, 0.63, 0.17, 1},
    {0.97, 1, 0.94, 1}, {0.8, 0.9, 0.7, 1}, {0.91, 1, 0.77, 1},
    {0.18, 0.37, 0.07, 1}, {0.05, 0.19, 0.01, 1})
Palette("Clear Grey", {0.27, 0.28, 0.29, 0.96}, {0.19, 0.2, 0.21, 1}, {0.49, 0.5, 0.5, 1},
    {0.96, 0.96, 0.94, 1}, {0.77, 0.78, 0.78, 1}, {0.88, 0.88, 0.84, 1},
    {0.3, 0.3, 0.3, 1}, {0.15, 0.15, 0.15, 1})
Palette("Clear Pink", {0.92, 0.66, 0.85, 0.98}, {0.82, 0.53, 0.74, 1}, {1, 0.8, 0.93, 1},
    {0.3, 0.18, 0.21, 1}, {0.4, 0.24, 0.32, 1}, {0.42, 0.18, 0.31, 1},
    {0.88, 0.4, 0.74, 1}, {0.72, 0.23, 0.57, 1})

for _, name in ipairs({"Light", "Clear White", "Clear Pink"}) do
    palettes[name].beneficial = {0.03, 0.24, 0.06, 1}
    palettes[name].detrimental = {0.42, 0.025, 0.07, 1}
end

function Themes.GetNames() return {"Dark"} end
function Themes.GetName()
    return "Dark"
end
function Themes.GetPalette() return palettes[Themes.GetName()] end
function Themes.Register(callback)
    listeners[#listeners + 1] = callback
    callback(Themes.GetPalette())
end
function Themes.Set(name)
    if not palettes[name] then
        print("FFXIV UI: unknown color theme: " .. tostring(name))
        return false
    end
    if name ~= "Dark" then
        print("FFXIV UI: other themes are temporarily disabled while the Dark skin is refined.")
        return false
    end
    FFXIV_UI_Theme = FFXIV_UI_Theme or {}
    FFXIV_UI_Theme.name = name
    for _, callback in ipairs(listeners) do callback(Themes.GetPalette()) end
    return true
end

-- Dark line with a light accent beside it; the accent follows the line's visibility.
function Themes.StyleDivider(line, parent, layer, sublevel, vertical)
    line:SetColorTexture(0, 0, 0, 0.85)
    local accent = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
    accent:SetColorTexture(1, 1, 1, 0.4)
    if vertical then
        accent:SetPoint("TOPLEFT", line, "TOPRIGHT")
        accent:SetPoint("BOTTOMLEFT", line, "BOTTOMRIGHT")
        accent:SetWidth(1)
    else
        accent:SetPoint("TOPLEFT", line, "BOTTOMLEFT")
        accent:SetPoint("TOPRIGHT", line, "BOTTOMRIGHT")
        accent:SetHeight(1)
    end
    hooksecurefunc(line, "Show", function() accent:Show() end)
    hooksecurefunc(line, "Hide", function() accent:Hide() end)
    hooksecurefunc(line, "SetShown", function(_, shown) accent:SetShown(shown) end)
    return accent
end
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, name)
    if name ~= "FFXIV_UI" then return end
    FFXIV_UI_Theme = FFXIV_UI_Theme or {}
    if FFXIV_UI_Theme.name and not palettes[FFXIV_UI_Theme.name] then
        print("FFXIV UI: unknown saved color theme; restoring Dark.")
    end
    Themes.Set(Themes.GetName())
end)
