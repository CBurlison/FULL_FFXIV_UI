local addonName, ns = ...

local locale = type(GetLocale) == "function" and GetLocale() or "enUS"
local L = setmetatable({}, {__index = function(_, key) return key end})
ns.L = L
ns.locale = locale

-- Prefer Blizzard's own localized globals where an equivalent exists.
local blizzard = {
    ["Spell"] = SPELL, ["Ability"] = ABILITY, ["Range"] = RANGE, ["Radius"] = RADIUS,
    ["Damage"] = DAMAGE, ["Defense"] = DEFENSE, ["Speed"] = SPEED,
    ["DPS"] = STAT_DPS_SHORT, ["Sell Price"] = SELL_PRICE, ["Passive"] = SPELL_PASSIVE,
}
for key, value in pairs(blizzard) do
    if type(value) == "string" and value ~= "" then rawset(L, key, value) end
end

function ns.RegisterLocale(code, strings)
    if code ~= locale then return end
    for key, value in pairs(strings) do rawset(L, key, value) end
end

-- The bundled fonts lack Cyrillic and CJK glyphs.
local fallbackLocales = {ruRU = true, koKR = true, zhCN = true, zhTW = true}
function ns.GetFont(path)
    if fallbackLocales[locale] and type(STANDARD_TEXT_FONT) == "string" then return STANDARD_TEXT_FONT end
    return path
end
