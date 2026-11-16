table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end
local xml = readFile("FFXIV_UI\\General\\MicroMenu.xml")
local maskFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Menu\\CircleMask.tga"
assert(not xml:find("<MaskTexture", 1, true),
    "Micro menu must not depend on unsupported standalone mask templates")
assert(xml:find('<Texture name="FFXIV_MicroMenuIconTemplate" virtual="true">', 1, true))
assert(xml:find('<Anchor point="CENTER"/>', 1, true))
local iconTemplates = {}
for template, file in xml:gmatch('<Texture name="([^"]+)" virtual="true" inherits="FFXIV_MicroMenuIconTemplate" file="([^"]+)"/>') do
    assert(xml:find('<Texture name="FFXIV_MicroMenuIconTemplate"', 1, true)
        < xml:find('<Texture name="' .. template .. '"', 1, true))
    iconTemplates[template] = file
end
local iconCount = 0
for _ in pairs(iconTemplates) do iconCount = iconCount + 1 end
assert(iconCount == 14, "All fourteen distinct micro-menu icons must be defined in XML")
local ringFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Menu\\GoldRing.tga"
assert(xml:find('<Texture name="FFXIV_MicroMenuRingTemplate" virtual="true" file="' .. ringFile .. '"/>', 1, true))
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do index = index + 1; lines[line] = index end
    assert(assert(lines["General/MicroMenu.xml"]) < assert(lines["General/MicroMenu.lua"]))
end
local methods, created, combat = {}, {}, false
local function object(kind, parent)
    local value = setmetatable({kind = kind or "Frame", parent = parent, regions = {}, scripts = {},
        points = {}, alpha = 1, width = 40, height = 48, enabled = true, state = "NORMAL", shown = true},
        {__index = methods})
    if kind == "Texture" or kind == "MaskTexture" then parent.regions[#parent.regions + 1] = value end
    created[#created + 1] = value
    return value
end
function CreateFrame(kind, _, parent) return object(kind, parent) end
function methods:GetObjectType() return self.kind end
function methods:GetRegions() return table.unpack(self.regions) end
function methods:CreateTexture(_, layer, template, subLevel)
    local texture = object("Texture", self)
    texture.layer, texture.template, texture.subLevel = layer, template, subLevel
    if template then
        assert(not combat, "Micro menu artwork created in combat")
        if iconTemplates[template] then
            texture:SetPoint("CENTER", self, "CENTER")
            texture:SetTexture(iconTemplates[template])
        else
            assert(template == "FFXIV_MicroMenuRingTemplate")
            texture:SetTexture(ringFile)
            texture:SetPoint("TOPLEFT", self, "TOPLEFT")
            texture:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
        end
    end
    return texture
end
function methods:CreateMaskTexture(_, layer, template)
    assert(not combat, "Micro menu mask created in combat")
    assert(template == nil, "CreateMaskTexture must not inherit the unavailable mask node")
    local mask = object("MaskTexture", self)
    mask.layer, mask.template = layer, template
    return mask
end
function methods:SetTexture(value, h, v) self.texture, self.wrapH, self.wrapV = value, h, v end
function methods:GetTexture() return self.texture end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:ClearAllPoints() self.points = {} end
function methods:SetAllPoints(value) self.allPoints = value end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:AddMaskTexture(value) self.mask = value end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:SetBlendMode(value) self.blendMode = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:GetButtonState() return self.state end
function methods:SetButtonState(value) self.state = value end
function methods:IsEnabled() return self.enabled end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:HookScript(name, callback)
    local old = self.scripts[name]
    self.scripts[name] = function(...) if old then old(...) end; callback(...) end
end
function methods:RegisterEvent() end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function InCombatLockdown() return combat end
function hooksecurefunc(owner, name, callback)
    local original = assert(owner[name], name)
    owner[name] = function(...) original(...); callback(...) end
end
for _, state in ipairs({"Normal", "Pushed", "Disabled", "Highlight"}) do
    methods["Get" .. state .. "Texture"] = function(self) return self[state] end
    methods["Set" .. state .. "Texture"] = function(self, image)
        self[state] = self[state] or self:CreateTexture()
        self[state]:SetTexture(image)
    end
    methods["Set" .. state .. "Atlas"] = methods["Set" .. state .. "Texture"]
end
assert(loadfile("FFXIV_UI\\General\\MicroMenu.lua"))("FFXIV_UI", {})
local watcher = created[1]
local function event(name) watcher.scripts.OnEvent(watcher, name) end
event("PLAYER_LOGIN")
assert(#created == 1, "module should wait for native menu")
local function button(name)
    local value = object("Button")
    _G[name] = value
    value:SetPoint("LEFT", "native previous button", "RIGHT", 2, 0)
    for _, key in ipairs({"Background", "PushedBackground", "Portrait", "Shadow", "PushedShadow",
        "Emblem", "HighlightEmblem", "FlashBorder", "FlashContent"}) do value[key] = value:CreateTexture() end
    value.NotificationOverlay = object()
    for _, state in ipairs({"Normal", "Pushed", "Disabled", "Highlight"}) do
        value["Set" .. state .. "Atlas"](value, "native-" .. state)
    end
    value.scripts.OnClick = function() return "native click", name end
    value.scripts.OnEnter = function(self) self.tooltip = "native localized tooltip"; self.Normal:SetAlpha(0) end
    value.scripts.OnLeave = function(self) self.tooltip = nil; self.Normal:SetAlpha(1) end
    value.scripts.OnDisable = function(self) self.enabled = false; self:SetAlpha(0.5) end
    value.scripts.OnEnable = function(self) self.enabled = true; self:SetAlpha(1) end
    return value
end
MicroMenu = object()
MicroMenu.childXPadding, MicroMenu.childYPadding = -5, -5
function MicroMenu:MarkDirty() self.dirty = true end
local horizontal, layoutCount = true, 0
function MicroMenu:Layout()
    layoutCount = layoutCount + 1
    self.testStride = 40 + (horizontal and self.childXPadding or self.childYPadding)
end
MicroMenuContainer = object()
function MicroMenuContainer:Layout()
    MicroMenu:Layout()
    self.width = MicroMenu.testStride * 3 - MicroMenu.childXPadding
end
MicroMenu.BorderArt, MicroMenu.BackgroundArt = MicroMenu:CreateTexture(), MicroMenu:CreateTexture()
local expected = {
    CharacterMicroButton = "Character", ProfessionMicroButton = "CraftingLog", SpellbookMicroButton = "Actions",
    TalentMicroButton = "Talents", LegacyMicroButton = "Legacy", AchievementMicroButton = "Achievements", QuestLogMicroButton = "Journal",
    GuildMicroButton = "FreeCompany", LFDMicroButton = "DutyFinder", CollectionsMicroButton = "Collection",
    EJMicroButton = "AdventureGuide", HousingMicroButton = "Housing",
    StoreMicroButton = "Shop", MainMenuMicroButton = "GameMenu", HelpMicroButton = "GameMenu",
}
for name in pairs(expected) do button(name) end
combat = true
local before = #created
event("ADDON_LOADED")
assert(#created == before and not CharacterMicroButton.FFXIVUIMicroMenu, "installed in combat")
assert(MicroMenu.childXPadding == -5 and layoutCount == 0, "spacing changed in combat")
combat = false
event("PLAYER_REGEN_ENABLED")
assert(MicroMenu.childXPadding == 2 and MicroMenu.childYPadding == 4
    and MicroMenu.dirty and MicroMenu.testStride == 42 and MicroMenuContainer.width == 124,
    "native menu must relayout with correct spacing and update its container bounds")
horizontal = false
MicroMenuContainer:Layout()
assert(MicroMenu.testStride == 44, "vertical menu must retain spacing")
horizontal = true
MicroMenuContainer:Layout()
local root = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Menu\\"
for name, image in pairs(expected) do
    local value, skin = _G[name], _G[name].FFXIVUIMicroMenu
    assert(skin and skin.icon.texture == root .. image .. ".tga", "wrong icon mapping")
    assert(skin.icon.width == 40 and skin.icon.height == 40)
    assert(skin.icon.template == "FFXIV_MicroMenu" .. image .. "IconTemplate" and skin.icon.layer == "ARTWORK"
        and skin.icon.parent == value and #skin.icon.points == 1
        and skin.icon.points[1][1] == "CENTER" and skin.icon.points[1][2] == value
        and skin.icon.points[1][3] == "CENTER")
    assert(skin.ring.template == "FFXIV_MicroMenuRingTemplate" and skin.ring.layer == "OVERLAY"
        and skin.ring.subLevel == 1 and skin.ring.parent == value and #skin.ring.points == 0,
        "Ring template anchors must clear before binding to the icon")
    assert(skin.icon.mask == skin.mask and skin.mask.allPoints == skin.icon)
    assert(skin.mask.texture == maskFile and skin.mask.wrapH == "CLAMPTOBLACKADDITIVE")
    assert(skin.mask.wrapV == "CLAMPTOBLACKADDITIVE"
        and skin.mask.template == nil
        and skin.mask.parent == value and #skin.mask.points == 0,
        "Lua-created mask must preserve wrapping, ownership and icon coverage")
    assert(skin.ring.texture == root .. "GoldRing.tga" and skin.ring.allPoints == skin.icon)
    assert(value.width == 40 and value.height == 48 and value.points[1][4] == 2,
        "native layout or click targets changed")
    local action, clicked = value.scripts.OnClick()
    assert(action == "native click" and clicked == name)
    assert(value.NotificationOverlay.shown and value.NotificationOverlay.alpha == 1)
    assert(value.FlashBorder.texture == root .. "GoldRing.tga" and value.FlashBorder.width == 40
        and value.FlashBorder.height == 40 and value.FlashBorder.blendMode == "ADD",
        "native alert pulse must use a bright circular gold outline")
    assert(value.Background.alpha == 0 and value.Portrait.alpha == 0 and value.Emblem.alpha == 0
        and value.FlashContent.alpha == 0 and value.Normal.alpha == 0 and value.Highlight.alpha == 0)
end
assert(MicroMenu.BorderArt.alpha == 0 and MicroMenu.BackgroundArt.alpha == 0)
MicroMenu.BorderArt:SetAlpha(1)
assert(MicroMenu.BorderArt.alpha == 0, "native rectangular bar art returned")
print("PASS all supplied menu mappings, circular mask/gold outline, native layout/actions and alert/notification preservation")

local value, skin = CharacterMicroButton, CharacterMicroButton.FFXIVUIMicroMenu
value.scripts.OnEnter(value)
assert(value.tooltip == "native localized tooltip" and skin.icon.color[1] == 1.15)
value:SetButtonState("PUSHED")
assert(skin.icon.color[1] == 0.7 and skin.ring.color[1] == 0.7)
value:SetButtonState("NORMAL"); value.scripts.OnLeave(value)
assert(not value.tooltip and skin.icon.color[1] == 1 and value.Normal.alpha == 0)
value.scripts.OnDisable(value)
assert(skin.icon.desaturated and value.alpha == 0.5)
value.scripts.OnEnter(value); assert(skin.icon.color[1] == 1)
value.scripts.OnEnable(value); assert(not skin.icon.desaturated and value.alpha == 1)
value.scripts.OnLeave(value)
combat = true
value:SetButtonState("PUSHED"); value.scripts.OnDisable(value)
assert(skin.icon.desaturated and skin.icon.color[1] == 0.7)
value:SetHighlightAtlas("native pushed atlas")
value.Highlight:SetAlpha(0.5)
assert(value.Highlight.alpha == 0)
value.Normal = nil
value:SetNormalTexture("replacement native texture")
assert(value.Normal.alpha == 0, "new native state texture was not hidden")
value.Background:Show(); value.Background:SetAlpha(1)
assert(value.Background.alpha == 0)
value.FlashBorder:SetAlpha(0.8)
assert(value.FlashBorder.alpha == 0.8, "native pulse alpha must not be suppressed")
combat = false
print("PASS hover/pressed/disabled states, native tooltips, combat-safe visuals and native artwork refresh suppression")

local regions = #value.regions
event("PLAYER_LOGIN"); event("ADDON_LOADED")
assert(#value.regions == regions and value.FFXIVUIMicroMenu == skin, "duplicate skin")
button("PlayerSpellsMicroButton")
combat = true; event("ADDON_LOADED")
assert(not PlayerSpellsMicroButton.FFXIVUIMicroMenu)
combat = false; event("PLAYER_REGEN_ENABLED")
assert(PlayerSpellsMicroButton.FFXIVUIMicroMenu.icon.texture == root .. "Talents.tga")
assert(PlayerSpellsMicroButton.FFXIVUIMicroMenu.icon.template == "FFXIV_MicroMenuTalentsIconTemplate")
local fallback = button("HelpMicroButton")
fallback.width, fallback.height, fallback.FlashBorder = 52, 28, nil
MicroMenuContainer = nil
event("ADDON_LOADED")
assert(fallback.FFXIVUIMicroMenu.icon.width == 28 and fallback.FFXIVUIMicroMenu.icon.height == 28,
    "Runtime sizing must use the smaller native button dimension")
assert(fallback.FFXIVUIMicroMenu.icon.texture == root .. "GameMenu.tga"
    and fallback.FFXIVUIMicroMenu.ring.texture == ringFile,
    "Buttons without native flash borders must still receive the complete artwork")
assert(MicroMenu.testStride == 42, "Native menu-only layout fallback must remain functional")
assert(watcher.scripts.OnUpdate == nil)
print("PASS idempotency, late-loaded buttons, combat deferral and no permanent update loop")
