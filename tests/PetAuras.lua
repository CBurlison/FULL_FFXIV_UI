local rows, slots, overlays = {}, {}, {}
local watcher
local methods = {}
local function object()
    return setmetatable({scripts = {}, events = {}}, {__index = methods})
end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetPoint(...) self.point = {...} end
function methods:SetAllPoints() end
function methods:SetFlowLayoutAnchorPoint(point) self.flowPoint = point end
function methods:SetFlowLayoutGrowthDirection(x, y) self.growth = {x, y} end
function methods:SetUnit(unit) self.unit = unit end
function methods:CreateTexture() return object() end
function methods:CreateFontString() return object() end
function methods:SetFont(font, size) self.font, self.fontSize = font, size end
function methods:SetIcon(icon) self.icon = icon end
function methods:SetApplicationCount(count) self.count = count end
function methods:SetDurationText(text, options) self.duration, self.durationOptions = text, options end
function methods:SetFrameLevel() end
function methods:GetFrameLevel() return 1 end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetMouseClickEnabled(value) self.clicks = value end
function methods:SetScript(script, callback) self.scripts[script] = callback end
function methods:HookScript(script, callback) self.scripts[script] = callback end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetEnabled(value) self.enabled = value end
function methods:UpdateAllAuras() self.refreshes = (self.refreshes or 0) + 1 end
function methods:GetAuraInstanceID() return self.auraInstanceID end
function methods:AddAuraGroup(name, filter, options)
    self.groups = self.groups or {}
    self.group, self.filter, self.limit = name, filter, options.maxFrameCount
    local slot = object()
    slots[name] = slot
    options.initializeFrame(slot)
    self.groups[#self.groups + 1] = {name = name, filter = filter, limit = options.maxFrameCount, slot = slot}
end
function methods:SetAuraGroupLayout(name, layout)
    self.layout = layout
    self.layouts = self.layouts or {}
    self.layouts[name] = layout
end
function CreateFrame(kind, _, parent, template)
    local frame = object()
    frame.parent = parent
    if kind == "AuraContainer" then
        assert(template == "CustomAuraContainerTemplate")
        rows[#rows + 1] = frame
    elseif parent then
        overlays[#overlays + 1] = frame
    else
        watcher = frame
    end
    return frame
end
local breakpoints = {}
C_StringUtil = {CreateNumericRuleFormatter = function()
    return {AddBreakpoint = function(_, point) breakpoints[#breakpoints + 1] = point end}
end}
AnchorUtil = {FlowDirection = {Right = 1, Down = 2}}
AuraUtil = {
    AuraFilters = {Helpful = "HELPFUL", Harmful = "HARMFUL"},
    CreateFilterString = function(filter) return filter end,
}
PetFrame_HP = object()
local TestAuraTooltipUnit, TestAuraTooltipID
local namespace = {
    ApplyButtonSkin = function(slot, regions, style, size)
        slot.skinStyle, slot.regions = style, regions
        slot.FFXIVUISkinNormal = object()
        slot.FFXIVUISkinNormal:SetSize(size, size)
    end,
    Tooltips = {
        ShowAuraTooltip = function(owner, unit, id)
            TestAuraTooltipUnit = unit
            TestAuraTooltipID = id
        end,
        HideAuraTooltip = function() end,
    }
}
assert(loadfile("FFXIV_UI\\PlayerFrames\\PetAuras.lua"))("FFXIV_UI", namespace)
assert(#rows == 2 and rows[1].filter == "HELPFUL" and rows[2].filter == "HARMFUL")
for _, row in ipairs(rows) do
    assert(row.unit == "pet" and row.parent == PetFrame_HP and row.enabled)
    assert(row.limit == 8 and row.layout.elementSpacingX == 3)
    assert(row.point[1] == "TOPLEFT" and row.point[3] == "TOPRIGHT")
end
assert(rows[1].point[5] == 0 and rows[2].point[5] == -36)
print("PASS: separate capped buff/debuff rows follow the pet parent")
for name, slot in pairs(slots) do
    assert(slot.width == 22 and slot.height == 22)
    assert(slot.FFXIVUISkinNormal.width == 22)
    assert(slot.count.fontSize == 10 and slot.duration.fontSize == 10)
    assert(slot.durationOptions.textFormat.components[1].property == 0)
    assert(slot.skinStyle == (name == "buffs" and "Buffs" or "Debuffs"))
end
assert(#breakpoints == 3)
assert(overlays[1].mouse and overlays[1].clicks == false)
print("PASS: small skins, stack counts, and duration formatter are configured")
slots.buffs.auraInstanceID = 101
overlays[1].scripts.OnEnter(overlays[1])
assert(TestAuraTooltipUnit == "pet" and TestAuraTooltipID == 101)
slots.debuffs.auraInstanceID = 202
overlays[2].scripts.OnEnter(overlays[2])
assert(TestAuraTooltipUnit == "pet" and TestAuraTooltipID == 202)
print("PASS: tooltips use pet aura instance IDs with ShowAuraTooltip")
watcher.scripts.OnEvent(watcher, "PLAYER_ENTERING_WORLD")
watcher.scripts.OnEvent(watcher, "UNIT_PET", "player")
PetFrame_HP.scripts.OnShow()
assert(rows[1].refreshes == 3 and rows[2].refreshes == 3)
watcher.scripts.OnEvent(watcher, "UNIT_PET", "party1")
assert(rows[1].refreshes == 3)
print("PASS: login, pet replacement, and visibility refresh both rows")

local enemyUnit = "nameplate1"
local function GetEnemyUnit() return enemyUnit end
local enemy = object()
local combined = namespace.CreateUnitAuraRow(enemy, GetEnemyUnit, "buffs", "HELPFUL", "Buffs", 6, 0, 18, 4)
local same = namespace.CreateUnitAuraRow(enemy, GetEnemyUnit, "debuffs", "HARMFUL", "Debuffs", 6, 0, 18, 8, combined)
assert(same == combined and #rows == 3 and #combined.groups == 2)
assert(combined.groups[1].filter == "HELPFUL" and combined.groups[1].limit == 4)
assert(combined.groups[2].filter == "HARMFUL" and combined.groups[2].limit == 8)
for _, group in ipairs(combined.groups) do
    local layout = combined.layouts[group.name]
    assert(layout.forceNewLine == false and layout.elementSpacing == 3 and layout.groupSpacing == 3)
    assert(group.slot.width == 18 and group.slot.FFXIVUISkinNormal.width == 18)
end
assert(combined.point[4] == 6 and combined.point[5] == 0)
print("PASS: enemy buffs and debuffs share one native flow container with no fixed second anchor")
enemyUnit = "nameplate2"
combined:SetUnit(enemyUnit)
combined.groups[1].slot.auraInstanceID = 303
combined.groups[2].slot.auraInstanceID = 404
overlays[3].scripts.OnEnter(overlays[3])
assert(TestAuraTooltipUnit == "nameplate2" and TestAuraTooltipID == 303)
overlays[4].scripts.OnEnter(overlays[4])
assert(TestAuraTooltipUnit == "nameplate2" and TestAuraTooltipID == 404)
print("PASS: combined aura groups retain distinct skins and correct tooltips after unit rebinding")
