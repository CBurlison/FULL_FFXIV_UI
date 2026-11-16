local combat = false
local frames = {}
Enum = {PowerType = {Rage = 1, Energy = 3, Mana = 0}}
function InCombatLockdown() return combat end
function CreateFrame()
    local frame = {events = {}}
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:RegisterUnitEvent(event) self.events[event] = true end
    function frame:SetScript(_, callback) self.callback = callback end
    frames[#frames + 1] = frame
    return frame
end
function hooksecurefunc()
    error("Skins must not hook Blizzard methods (taint)")
end
C_Timer = {After = function(_, callback) callback() end}
local function divider(alpha)
    local texture = {alpha = alpha}
    function texture:GetObjectType() return "Texture" end
    function texture:GetAlpha() return self.alpha end
    function texture:SetAlpha(value) self.alpha = value end
    local frame = {texture = texture, shown = true}
    function frame:GetRegions() return self.texture end
    function frame:Hide() error("Must not hide a protected divider") end
    function frame:SetShown() error("Must not change protected divider visibility") end
    return frame
end
local horizontal, vertical = {divider(0.8)}, {divider(1)}
local function pool(active)
    return {EnumerateActive = function()
        local index = 0
        return function()
            index = index + 1
            return active[index]
        end
    end}
end
MainActionBar = {
    HorizontalDividersPool = pool(horizontal),
    VerticalDividersPool = pool(vertical),
}
function MainActionBar:UpdateDividers()
    for _, active in ipairs({horizontal, vertical}) do
        for _, frame in ipairs(active) do frame.shown = true end
    end
end
FFXIV_UI_DB = {hideBlizzardHotbarBackground = true}
local namespace = {}
assert(loadfile("FFXIV_UI\\General\\ButtonSkins.lua"))("FFXIV_UI", namespace)
local skinWatcher = frames[#frames]
local function refresh() skinWatcher.callback(nil, "PLAYER_ENTERING_WORLD") end
local function S(button) return namespace.GetButtonSkinState(button) or {} end
namespace.SetHotbarBackgroundHidden(true)
assert(horizontal[1].texture.alpha == 0 and vertical[1].texture.alpha == 0)
print("PASS: divider textures hidden without changing protected frames")

combat = true
horizontal[2] = divider(0.6)
MainActionBar:UpdateDividers()
namespace.SetHotbarBackgroundHidden(true)
assert(horizontal[1].texture.alpha == 0 and horizontal[2].texture.alpha == 0)
assert(vertical[1].texture.alpha == 0)
assert(horizontal[2].shown)
print("PASS: newly acquired dividers are hidden during combat refreshes")

MainActionBar:UpdateDividers()
FFXIV_UI_DB.hideBlizzardHotbarBackground = false
namespace.SetHotbarBackgroundHidden(false)
assert(horizontal[1].texture.alpha == 0.8 and horizontal[2].texture.alpha == 0.6)
assert(vertical[1].texture.alpha == 1)
print("PASS: repeated hiding preserves original opacity for restoring artwork")

combat = false
frames[#frames].callback(nil, "PLAYER_REGEN_ENABLED")
assert(horizontal[1].texture.alpha == 0.8 and horizontal[2].texture.alpha == 0.6)
FFXIV_UI_DB.hideBlizzardHotbarBackground = true
namespace.SetHotbarBackgroundHidden(true)
assert(horizontal[2].texture.alpha == 0)
print("PASS: deferred art refresh preserves the preference after combat")

local regionMethods = {}
local function region()
    return setmetatable({}, {__index = regionMethods})
end
function regionMethods:ClearAllPoints() self.anchor = nil; self.point = nil end
function regionMethods:SetAllPoints(anchor) self.anchor = anchor end
function regionMethods:SetPoint(...) self.point = {...} end
function regionMethods:SetSize(w, h) self.width, self.height = w, h end
function regionMethods:SetTexture(value) self.texture = value end
function regionMethods:SetAtlas(value) self.atlas = value end
function regionMethods:SetTexCoord(...) self.texCoords = {...} end
function regionMethods:SetVertexColor() end
function regionMethods:SetDrawLayer() end
function regionMethods:SetBlendMode(value) self.blendMode = value end
function regionMethods:SetAlpha(value) self.alpha = value end
function regionMethods:GetAlpha() return self.alpha or 1 end
function regionMethods:SetShown(shown) self.shown = shown end
function regionMethods:Show() self.shown = true end
function regionMethods:Hide() self.shown = false end
function regionMethods:IsShown() return self.shown ~= false end
function regionMethods:GetWidth() return self.width or 32 end
function regionMethods:GetFrameLevel() return 1 end
function regionMethods:SetFrameLevel() end
function regionMethods:EnableMouse() end
function regionMethods:CreateTexture() return region() end
function regionMethods:CreateMaskTexture() return region() end
function regionMethods:AddMaskTexture(mask)
    self.masks = self.masks or {}
    self.masks[mask] = true
end
function regionMethods:RemoveMaskTexture(mask)
    if self.masks then self.masks[mask] = nil end
end
function regionMethods:HookScript()
    error("Skins must not hook frame scripts (taint)")
end
function regionMethods:SetInputKey(key) self.mappedButtonKey = key end
function regionMethods:IsProtected() return self.protected == true end
CreateFrame = function(_, _, parent, template)
    local result = region()
    result.parent, result.template = parent, template
    return result
end
local petButton = region()
petButton.icon = region()
petButton.AutoCastOverlay = region()
petButton.AutoCastOverlay.shown = true
namespace.ApplyButtonSkin(petButton, nil, "Pet")
assert(petButton.icon.width == 32 and petButton.icon.height == 32)
assert(petButton.AutoCastOverlay.anchor == petButton.icon)
assert(petButton.AutoCastOverlay.shown == true)
assert(petButton.icon.point[5] == 1)
print("PASS: pet autocast overlay follows the smaller offset icon without changing activation")
local generalButton = region()
generalButton.icon, generalButton.AutoCastOverlay = region(), region()
namespace.ApplyButtonSkin(generalButton, nil, "General")
assert(generalButton.icon.width == 46 and generalButton.AutoCastOverlay.anchor == nil)
print("PASS: other action bars keep their existing autocast geometry")

local equipment = region()
equipment.width = 36
equipment.icon, equipment.Cooldown = region(), region()
equipment.HighlightTexture = region()
function equipment:GetHighlightTexture() return self.HighlightTexture end
equipment.nativeAction = "equip"
namespace.ApplyButtonSkin(equipment, nil, "Equipment")
assert(equipment.icon.width == 36 and equipment.Cooldown.anchor == equipment.icon)
assert(S(equipment).style == "Equipment" and equipment.nativeAction == "equip")
assert(math.abs(S(equipment).normal.width - 36 * 58 * 0.92 / 52) < 0.001)
assert(math.abs(S(equipment).backdrop.width * 56 / 64 / (36 * 58 / 64) - 0.92) < 0.001)
assert(equipment.icon.point[5] == 0)
assert(S(equipment).backdrop.point[2] == equipment.icon)
assert(S(equipment).normal.point[2] == equipment.icon)
assert(S(equipment).overlay.Gloss:IsShown())
assert(equipment.HighlightTexture.texture:match("General\\Highlight$")
    and equipment.HighlightTexture.blendMode == "ADD")
assert(equipment.HighlightTexture.point[2] == equipment.icon
    and math.abs(equipment.HighlightTexture.width - 36 * 60 / 46) < 0.001,
    "equipment hover does not match proportional action-bar highlight")
print("PASS: equipment reuses proportional square skins and gloss without action costs")


combat = true
local aura = region()
aura.icon = region()
namespace.ApplyButtonSkin(aura, {Icon = aura.icon}, "Debuffs", 18)
assert(S(aura).normal.width == 18 and S(aura).normal.height == 18)
assert(S(aura).style == "Debuffs")
local protectedAura = region()
protectedAura.icon, protectedAura.protected = region(), true
namespace.ApplyButtonSkin(protectedAura, {Icon = protectedAura.icon}, "Buffs", 22)
assert(S(protectedAura).normal == nil)
local action = region()
action.icon = region()
namespace.ApplyButtonSkin(action, nil, "Pet")
assert(S(action).normal == nil)
print("PASS: new unprotected aura slots are styled in combat, but protected slots and actions still defer")
combat = false
skinWatcher.callback(nil, "PLAYER_REGEN_ENABLED")
assert(S(protectedAura).normal.width == 22)
assert(action.icon.width == 32)
print("PASS: deferred aura sizing and action skins apply after combat")

local gamepadTouched = false
GamepadMainActionBarFrame = region()
function GamepadMainActionBarFrame:GetActionBars() gamepadTouched = true; return {} end
skinWatcher.callback(nil, "ADDON_LOADED", "Blizzard_GamepadActionBars")
refresh()
assert(not gamepadTouched, "Blizzard gamepad action buttons must not be skinned (taints secure updates)")
print("PASS: Blizzard gamepad action buttons are left untouched")

local stanceButton = region()
stanceButton.icon = region()
namespace.ApplyButtonSkin(stanceButton, nil, "Stance")
assert(stanceButton.icon.width == 32 and stanceButton.icon.height == 32)
assert(S(stanceButton).style == "Stance")
assert(stanceButton.icon.point[5] == 1)
print("PASS: stance action bar icons match pet action bar icon size (32px)")
