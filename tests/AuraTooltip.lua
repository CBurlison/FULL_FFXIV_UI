local addonName, ns = ...
local applyControlTemplate = assert(loadfile("tests\\support\\PanelTemplates.lua"))()
local methods = {}
local now = 100

local function object(kind, parent)
    local result = setmetatable({
        kind = kind or "Frame", parent = parent, shown = kind == "FontString", level = 1,
        regions = {}, children = {}, scripts = {}, points = {}, text = "", stringHeight = 10,
    }, {__index = methods})
    if parent then
        local list = (kind == "Texture" or kind == "FontString") and parent.regions or parent.children
        list[#list + 1] = result
    end
    return result
end

function CreateFrame(_, _, parent, template)
    local frame = object("Frame", parent)
    applyControlTemplate(frame, parent, template)
    return frame
end

function methods:GetObjectType() return self.kind end
function methods:CreateTexture(_, _, template)
    local texture = object("Texture", self)
    applyControlTemplate(texture, self, template)
    return texture
end
function methods:CreateFontString(_, _, template)
    local label = object("FontString", self)
    label.template = template
    applyControlTemplate(label, self, template)
    return label
end
function methods:SetFrameStrata(value) self.strata = value end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameLevel() return self.level end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetHeight() return self.height end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetBackdropBorderColor() end
function methods:SetVertexColor() end
function methods:SetTextColor() end
function methods:SetColorTexture() end
function methods:SetTexture() end
function methods:SetTexCoord() end
function methods:SetHorizTile() end
function methods:SetVertTile() end
function methods:SetAlpha() end
function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetAllPoints() end
function methods:EnableMouse() end
function methods:SetWordWrap(value) self.wrap = value end
function methods:SetJustifyH(value) self.justify = value end
function methods:SetFont(...) self.font = {...} end
function methods:SetText(text) assert(self.font, "Font not set"); self.text = text end
function methods:GetStringHeight() return self.stringHeight end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetShown(value) self.shown = value and true or false end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:HookScript() end
function methods:RegisterEvent() end
function methods:GetParent() return self.parent end

function InCombatLockdown() return false end
function GetTime() return now end
function hooksecurefunc() end
UIParent = object("Frame")

local auras = {}
C_UnitAuras = {
    GetAuraDataByAuraInstanceID = function(unit, id) return auras[id] end,
}
local descriptions = {}
C_Spell = {
    GetSpellDescription = function(spellId) return descriptions[spellId] end,
}

table.unpack = table.unpack or unpack
unpack = unpack or table.unpack

local namespace = {}
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\RoundedPanels.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\WindowControls.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Core.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Items.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Spells.lua"))("FFXIV_UI", namespace)
-- Native tooltip skinning is covered by its own suites; this suite only checks the aura frame.
namespace.RoundTooltip = function() end
local Tooltips = namespace.Tooltips
local owner = object("Frame")

local function assertEqual(actual, expected, label)
    assert(actual == expected, string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
end

-- Template geometry comes from General\Tooltips\AuraTooltip.xml; Lua only adds sibling anchors.
Tooltips.ShowAuraTooltip(owner, "player", 0)
local tooltip = UIParent.children[#UIParent.children]
assert(tooltip, "Tooltip frame not created")
for _, region in ipairs(tooltip.regions) do
    if region.template == "FFXIV_AuraTooltipTitleTemplate" then
        assertEqual(region.width, 248, "title width")
        assertEqual(region.justify, "LEFT", "title justify")
    end
end

local title, duration, description
for _, region in ipairs(tooltip.regions) do
    if region.template == "FFXIV_AuraTooltipTitleTemplate" then title = region end
    if region.template == "FFXIV_AuraTooltipDurationTemplate" then duration = region end
    if region.template == "FFXIV_AuraTooltipDescriptionTemplate" then description = region end
end
assert(title and duration and description, "Aura FontStrings must come from templates")
assertEqual(description.wrap, true, "description word wrap")
assertEqual(description.width, 248, "description width")
assertEqual(duration.width, 248, "duration width")
assert(not tooltip.shown, "Missing aura hides the tooltip")

-- Data-driven text and visibility.
auras[1] = {name = "Haste", spellId = 1, duration = 530, expirationTime = now + 530}
descriptions[1] = "Increases haste."
Tooltips.ShowAuraTooltip(owner, "player", 1)
assert(tooltip.shown, "Aura shows tooltip")
assertEqual(title.text, "Haste", "title text")
assertEqual(duration.text, "8m 50s remaining", "duration text")
assert(duration.shown, "Duration shown when time remains")
assertEqual(description.text, "Increases haste.", "description text")
assert(description.shown, "Description shown when present")

-- Expired and permanent auras hide the duration line; no description hides its line.
auras[2] = {name = "Passive", spellId = 2, duration = 0, expirationTime = 0}
Tooltips.ShowAuraTooltip(owner, "player", 2)
assert(not duration.shown, "Permanent aura hides duration")
assert(not description.shown, "Empty description hides description")
assertEqual(title.text, "Passive", "permanent title text")

-- Height is 24 + visible line heights + 12 padding; a title-only aura is 24 + 10 + 12 = 46.
Tooltips.ShowAuraTooltip(owner, "player", 2)
assertEqual(tooltip.height, 46, "title-only height")
Tooltips.ShowAuraTooltip(owner, "player", 1)
assertEqual(tooltip.height, 76, "full height")
assert(tooltip.points[#tooltip.points][1] == "BOTTOMLEFT", "Anchored to owner")

Tooltips.HideAuraTooltip()
assert(not tooltip.shown, "HideAuraTooltip hides the frame")

print("AuraTooltip tests passed")
