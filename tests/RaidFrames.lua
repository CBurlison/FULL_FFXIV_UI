local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end
local xml = readFile("FFXIV_UI\\PartyFrames\\RaidFrames.xml")
for _, text in ipairs({
    '<StatusBar name="FFXIV_RaidHealthTemplate" virtual="true" enableMouse="false">',
    '<StatusBar name="FFXIV_RaidPowerTemplate" virtual="true" enableMouse="false">',
    '<BarTexture file="Interface\\Buttons\\WHITE8X8"/>',
    '<BarColor r="0.63" g="0.88" b="1"/>',
    '<Texture parentKey="background" setAllPoints="true">',
    '<Color r="0.015" g="0.025" b="0.035" a="1"/>',
}) do assert(xml:find(text, 1, true), "Raid XML missing: " .. text) end
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do index = index + 1; lines[line] = index end
    assert(assert(lines["PartyFrames/RaidFrames.xml"]) < assert(lines["PartyFrames/RaidFrames.lua"]))
end
print("PASS: raid bar XML colors, artwork, mouse handling, and both TOC orders")
for template, snippets in pairs({
    FFXIV_RaidIconBaseTemplate = {
        '<Size x="22" y="24"/>', '<Anchor point="LEFT" x="3" y="0"/>',
        '<Color r="0.13" g="0.11" b="0.065" a="1"/>',
    },
    FFXIV_RaidClassIconTemplate = {'<Size x="18" y="20"/>'},
    FFXIV_RaidGroupBackgroundTemplate = {
        '<Anchor point="TOPLEFT"/>', '<Anchor point="BOTTOMRIGHT"/>',
        '<Color r="0.055" g="0.055" b="0.045" a="0.85"/>',
    },
    FFXIV_RaidHealthShineTemplate = {
        '<Size y="1"/>', '<Color r="0.92" g="1" b="1" a="0.8"/>',
    },
}) do
    local region = assert(xml:match('<Texture name="' .. template .. '" virtual="true">.-</Texture>'))
    for _, snippet in ipairs(snippets) do
        assert(region:find(snippet, 1, true), template .. " missing: " .. snippet)
    end
end

local borderPoints = {
    TOP = {"TOPLEFT", "TOPRIGHT"},
    BOTTOM = {"BOTTOMLEFT", "BOTTOMRIGHT"},
    LEFT = {"TOPLEFT", "BOTTOMLEFT"},
    RIGHT = {"TOPRIGHT", "BOTTOMRIGHT"},
}
for side, points in pairs(borderPoints) do
    local region = assert(xml:match('<Texture name="FFXIV_RaidBorder' .. side .. 'Template" virtual="true">.-</Texture>'))
    local axis = (side == "TOP" or side == "BOTTOM") and "y" or "x"
    assert(region:find('<Size ' .. axis .. '="1"/>', 1, true))
    for _, point in ipairs(points) do
        assert(region:find('<Anchor point="' .. point .. '"/>', 1, true))
    end
end

local combat, watcher = false, nil
local frames, groups, units, created = {}, {}, {}, {}
local passed = 0
local methods = {}
local function object(kind, parent)
    local result = setmetatable({kind = kind, parent = parent, points = {}, regions = {}}, {__index = methods})
    created[#created + 1] = result
    return result
end
local function layout(self)
    assert(not combat, "Raid layout changed during combat")
end
function methods:CreateTexture(_, layer, template, subLevel)
    local texture = object("Texture", self)
    texture.layer, texture.template, texture.subLevel = layer, template, subLevel
    if template then
        assert(not combat, "Raid artwork construction must defer during combat")
        if template == "FFXIV_RaidIconBaseTemplate" then
            texture:SetSize(22, 24)
            texture:SetPoint("LEFT", self, "LEFT", 3, 0)
            texture:SetColorTexture(0.13, 0.11, 0.065, 1)
        elseif template == "FFXIV_RaidClassIconTemplate" then
            texture:SetSize(18, 20)
            texture:SetPoint("TOPLEFT", self, "TOPLEFT")
        elseif template == "FFXIV_RaidGroupBackgroundTemplate" then
            texture:SetAllPoints()
            texture:SetColorTexture(0.055, 0.055, 0.045, 0.85)
        elseif template == "FFXIV_RaidHealthShineTemplate" then
            texture:SetHeight(1)
            texture:SetColorTexture(0.92, 1, 1, 0.8)
            texture:SetPoint("CENTER", self, "CENTER")
        else
            local side = assert(template:match("^FFXIV_RaidBorder(%u+)Template$"))
            local points = assert(borderPoints[side])
            if side == "TOP" or side == "BOTTOM" then texture:SetHeight(1) else texture:SetWidth(1) end
            for _, point in ipairs(points) do texture:SetPoint(point, self, point) end
        end
    end
    self.regions[#self.regions + 1] = texture
    return texture
end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetVertexColor(...) self.vertex = {...} end
function methods:SetTexture(value) self.texture = value end
function methods:SetTexCoord(...) self.coords = {...} end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetAllPoints() layout(self); self.allPoints = true end
function methods:ClearAllPoints() layout(self); self.points = {} end
function methods:SetPoint(...) layout(self); self.points[#self.points + 1] = {...} end
function methods:SetSize(w, h) layout(self); self.width, self.height = w, h end
function methods:SetWidth(w) layout(self); self.width = w end
function methods:SetHeight(h) layout(self); self.height = h end
function methods:SetStatusBarTexture(texture)
    if not self.fill then self.fill = object("Texture", self) end
    self.fill.texture = texture
end
function methods:GetStatusBarTexture() return self.fill end
function methods:SetStatusBarColor(...) self.color = {...} end
function methods:SetMinMaxValues(low, high) self.minimum, self.maximum = low, high end
function methods:SetValue(value) self.value = value end
function methods:EnableMouse(value) self.mouseEnabled = value end
function methods:GetFrameLevel() return 2 end
function methods:SetFrameLevel(level) layout(self); self.level = level end
function methods:SetFont(font, size) self.font, self.fontSize = font, size end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:GetFontString() return self.text end
function methods:SetShouldAdjustHealthBarAnchor()
    error("Must not taint Blizzard's max-health-loss control fields")
end
function methods:SetAttribute() error("Must not change secure attributes") end
function methods:Hide() error("Must not hide Blizzard frames") end
function methods:Show() error("Must not show Blizzard frames") end
function methods:SetScript(_, callback) self.callback = callback end
function methods:RegisterEvent() end
function CreateFrame(kind, _, parent, template)
    local result = object(kind, parent)
    if kind == "StatusBar" then
        assert(not combat and parent, "Raid bar creation must defer in combat")
        assert(template == "FFXIV_RaidHealthTemplate" or template == "FFXIV_RaidPowerTemplate")
        result.template = template
        result:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        result:EnableMouse(false)
        if template == "FFXIV_RaidHealthTemplate" then
            result:SetStatusBarColor(0.63, 0.88, 1)
        else
            result.background = result:CreateTexture()
            result.background:SetAllPoints()
            result.background:SetColorTexture(0.015, 0.025, 0.035, 1)
        end
    end
    if not parent then watcher = result end
    return result
end
function hooksecurefunc(target, name, callback)
    if type(target) == "string" then target, name, callback = _G, target, name end
    local original = assert(target[name], name)
    target[name] = function(...)
        original(...)
        callback(...)
    end
end
function InCombatLockdown() return combat end
function issecretvalue(value) return type(value) == "table" and value.secret end
function UnitClass(unit) return "Mage", units[unit].class end
function UnitPowerType(unit)
    local data = units[unit]
    return data.powerType or 0, data.token or "MANA", data.altR, data.altG, data.altB
end
function UnitPowerMax(unit) return units[unit].maximum end
function UnitPower(unit) return units[unit].power end
function UnitHealthMax(unit) return units[unit].maxHealth or 1000 end
function UnitHealth(unit) return units[unit].health or 800 end
CompactRaidGroupTypeEnum = {Raid = 1, Party = 2}
DefaultCompactMiniFrameOptions = {}
CLASS_ICON_TCOORDS = {MAGE = {0.25, 0.5, 0, 0.25}}
PowerBarColor = {
    MANA = {r = 0, g = 0, b = 1},
    RAGE = {r = 1, g = 0, b = 0},
    ENERGY = {r = 1, g = 1, b = 0},
    [2] = {r = 1, g = 0.5, b = 0.25},
}
unpack = unpack or table.unpack
function DefaultCompactUnitFrameSetup() end
function CompactUnitFrame_UpdateAll() end
function CompactUnitFrame_UpdateName(frame) frame.name:SetAlpha(1) end
function CompactRaidGroup_UpdateLayout() end
CompactRaidFrameContainer = {
    ApplyToFrames = function(_, specifier, callback)
        for _, frame in ipairs(specifier == "group" and groups or frames) do callback(frame) end
    end,
}
local function member(unit, groupType)
    local frame = object("Button")
    frame.unit, frame.displayedUnit, frame.groupType = unit, unit, groupType
    frame.width, frame.height = 72, 36
    for _, key in ipairs({"healthBar", "powerBar", "background", "name", "roleIcon", "TempMaxHealthLoss"}) do
        frame[key] = object(key, frame)
    end
    frame.healthBar:SetStatusBarTexture("Native")
    units[unit] = {class = "MAGE", power = 60, maximum = 100}
    frames[#frames + 1] = frame
    return frame
end
local function powerBar(frame)
    for _, region in ipairs(created) do
        if region.kind == "StatusBar" and region.parent == frame and region.height == 3 then return region end
    end
end
local function event(name, ...) watcher.callback(watcher, name, ...) end
local function test(name, run)
    run()
    passed = passed + 1
    print("PASS: " .. name)
end

local raid = member("raid1", 1)
local party = member("party1", 2)
local nameplate = member("nameplate1", nil)
local raidPet = member("raidpet1", 1)
raidPet.optionTable = DefaultCompactMiniFrameOptions
local group = object("Group")
group.groupType = 1
group.title = object("Button", group)
group.title.text = object("FontString", group.title)
group.borderFrame = {Background = object("Texture")}
groups[1] = group
assert(loadfile("FFXIV_UI\\PartyFrames\\RaidFrames.lua"))("FFXIV_UI", {})

test("styles raid tiles only without moving or resizing subgroup members", function()
    event("PLAYER_ENTERING_WORLD")
    assert(raid.width == 72 and raid.height == 36 and #raid.points == 0)
    assert(raid.name.alpha == 0 and raid.powerBar.alpha == 0)
    assert(party.name.alpha == nil and nameplate.name.alpha == nil)
    assert(powerBar(party) == nil and powerBar(nameplate) == nil)
    assert(powerBar(raidPet) == nil and raidPet.name.alpha == nil)
    assert(raid.healthBar.points[1][4] == 28)
    assert(raid.healthBar.points[2][5] == 7)
    assert(raid.TempMaxHealthLoss.xOffset == nil and raid.TempMaxHealthLoss.yOffset == nil)
    assert(group.title.text.fontSize == 11 and group.borderFrame.Background.alpha == 0)
    local base, icon
    for _, region in ipairs(raid.regions) do
        if region.template == "FFXIV_RaidIconBaseTemplate" then base = region end
        if region.template == "FFXIV_RaidClassIconTemplate" then icon = region end
    end
    assert(base and base.layer == "BACKGROUND" and base.width == 22 and base.height == 24)
    assert(base.points[1][1] == "LEFT" and base.points[1][4] == 3)
    assert(icon and icon.layer == "ARTWORK" and icon.width == 18 and icon.height == 20)
    assert(#icon.points == 1 and icon.points[1][1] == "CENTER" and icon.points[1][2] == base)
    assert(icon.desaturated and icon.vertex[1] == 1 and icon.vertex[2] == 0.84 and icon.vertex[3] == 0.47)
    assert(icon.texture == "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
end)
test("XML subgroup background and shine preserve layering and health anchoring", function()
    local background, shine
    for _, region in ipairs(group.regions) do
        if region.template == "FFXIV_RaidGroupBackgroundTemplate" then background = region end
    end
    for _, region in ipairs(raid.regions) do
        if region.template == "FFXIV_RaidHealthShineTemplate" then shine = region end
    end
    assert(background and background.allPoints and background.layer == "BACKGROUND" and background.subLevel == -2)
    assert(background.color[1] == 0.055 and background.color[3] == 0.045 and background.color[4] == 0.85)
    assert(shine and shine.layer == "ARTWORK" and shine.height == 1 and #shine.points == 2)
    assert(shine.color[1] == 0.92 and shine.color[4] == 0.8)
    assert(shine.points[1][1] == "TOPLEFT" and shine.points[2][1] == "TOPRIGHT")
    local health = shine.points[1][2]
    assert(health.template == "FFXIV_RaidHealthTemplate" and shine.points[2][2] == health)
end)
test("XML borders retain thickness, colors, owners, and icon-relative anchors", function()
    local counts = {tile = 0, icon = 0, group = 0}
    for _, owner in ipairs({raid, group}) do
        for _, edge in ipairs(owner.regions) do
            local side = edge.template and edge.template:match("^FFXIV_RaidBorder(%u+)Template$")
            if side then
                assert(edge.layer == "BORDER" and #edge.points == 2)
                local points = borderPoints[side]
                for index, point in ipairs(edge.points) do
                    assert(point[1] == points[index] and point[3] == points[index])
                end
                assert(edge.points[1][2] == edge.points[2][2])
                assert((side == "TOP" or side == "BOTTOM") and edge.height == 1
                    or (side == "LEFT" or side == "RIGHT") and edge.width == 1)
                local kind, expected
                if owner == group then
                    kind, expected = "group", {0.5, 0.43, 0.29, 0.9}
                    assert(edge.points[1][2] == group)
                elseif edge.points[1][2] == raid then
                    kind, expected = "tile", {0.25, 0.25, 0.22, 1}
                else
                    kind, expected = "icon", {0.68, 0.55, 0.29, 1}
                    assert(edge.points[1][2].template == "FFXIV_RaidIconBaseTemplate")
                end
                counts[kind] = counts[kind] + 1
                for index, value in ipairs(expected) do assert(edge.color[index] == value) end
            end
        end
    end
    assert(counts.tile == 4 and counts.icon == 4 and counts.group == 4)
end)
test("resource strip is exactly three pixels and displays every member's primary resource", function()
    local power = assert(powerBar(raid))
    assert(power.template == "FFXIV_RaidPowerTemplate" and power.mouseEnabled == false)
    assert(power.background.allPoints and power.background.color[1] == 0.015
        and power.background.color[2] == 0.025 and power.background.color[3] == 0.035)
    assert(power.height == 3 and power.points[1][5] == 3)
    assert(power.value == 60 and power.maximum == 100)
    assert(power.color[1] == 0 and power.color[3] == 1)
    for _, token in ipairs({"RAGE", "ENERGY", "MANA"}) do
        units.raid1.token, units.raid1.power = token, 0
        event("UNIT_DISPLAYPOWER", "raid1")
        assert(power.value == 0)
        assert(power.color[1] == PowerBarColor[token].r)
        assert(power.color[2] == PowerBarColor[token].g)
    end
    units.raid1.maximum = 250
    event("UNIT_MAXPOWER", "raid1")
    assert(power.maximum == 250)
end)
test("resource colors support numeric, alternate, and unknown resource types", function()
    local power = powerBar(raid)
    units.raid1.token, units.raid1.powerType = "CUSTOM", 2
    event("UNIT_DISPLAYPOWER", "raid1")
    assert(power.color[2] == 0.5 and power.color[3] == 0.25)
    units.raid1.powerType = 99
    units.raid1.altR, units.raid1.altG, units.raid1.altB = 0.2, 0.4, 0.6
    event("UNIT_DISPLAYPOWER", "raid1")
    assert(power.color[1] == 0.2 and power.color[3] == 0.6)
    units.raid1.altR, units.raid1.altG, units.raid1.altB = nil, nil, nil
    event("UNIT_DISPLAYPOWER", "raid1")
    assert(power.color[1] == 1 and power.color[2] == 1 and power.color[3] == 1)
end)
test("native health color setter and texture state stay untouched", function()
    assert(raid.healthBar.SetStatusBarColor == methods.SetStatusBarColor)
    assert(raid.healthBar.fill.texture == "Native")
    raid.healthBar:SetStatusBarColor(0, 1, 0)
    assert(raid.healthBar.fill.vertex == nil)
    assert(raid.healthBar.fill.alpha == 0)
    local health
    for _, region in ipairs(created) do
        if region.kind == "StatusBar" and region.parent == raid and region ~= powerBar(raid) then
            health = region
        end
    end
    assert(health and health.color[1] == 0.63 and health.color[3] == 1)
    assert(health.template == "FFXIV_RaidHealthTemplate" and health.mouseEnabled == false)
    assert(health.value == 800 and health.maximum == 1000)
    units.raid1.health, units.raid1.maxHealth = 400, 1200
    event("UNIT_HEALTH", "raid1")
    assert(health.value == 400 and health.maximum == 1200)
    CompactUnitFrame_UpdateName(raid)
    assert(raid.name.alpha == 0)
    CompactUnitFrame_UpdateName(party)
    assert(party.name.alpha == 1)
end)
test("vehicle resources and secret values are passed directly to rendering APIs", function()
    units.vehicle = {token = "ENERGY", power = 99, maximum = 200, class = "MAGE"}
    raid.displayedUnit = "vehicle"
    event("UNIT_POWER_UPDATE", "vehicle")
    assert(powerBar(raid).value == 99 and powerBar(raid).color[2] == 1)
    local secret = setmetatable({secret = true}, {
        __lt = function() error("Compared secret") end,
        __le = function() error("Compared secret") end,
        __tostring = function() error("Converted secret") end,
    })
    units.vehicle.power, units.vehicle.maximum = secret, secret
    units.raid1.class = secret
    event("UNIT_NAME_UPDATE", "raid1")
    assert(powerBar(raid).value == secret and powerBar(raid).maximum == secret)
    raid.displayedUnit = "raid1"
end)
test("layout is deferred in combat but resource updates continue", function()
    combat = true
    units.raid1.power = 20
    CompactUnitFrame_UpdateAll(raid)
    assert(powerBar(raid).value == 20)
    local newcomer = member("raid2", 1)
    DefaultCompactUnitFrameSetup(newcomer)
    assert(powerBar(newcomer) == nil)
    combat = false
    event("PLAYER_REGEN_ENABLED")
    assert(powerBar(newcomer) and powerBar(newcomer).height == 3)
end)
test("setup and roster refreshes reuse artwork and hooks", function()
    local count = #created
    DefaultCompactUnitFrameSetup(raid)
    CompactUnitFrame_UpdateAll(raid)
    event("GROUP_ROSTER_UPDATE")
    assert(#created == count)
end)
print(string.format("%d raid skin tests passed", passed))
