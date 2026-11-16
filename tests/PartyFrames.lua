local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end
local xml = readFile("FFXIV_UI\\PartyFrames\\PartyFrames.xml")
local barArt = {
    FFXIV_PartyBarEdgeTemplate = {
        layer = "BACKGROUND", subLevel = -2, color = {0.05, 0.22, 0.3, 0.9},
        anchors = {{point = "TOPLEFT", x = -1, y = 1}, {point = "BOTTOMRIGHT", x = 1, y = -1}},
    },
    FFXIV_PartyBarBackgroundTemplate = {
        layer = "BACKGROUND", subLevel = -1, color = {0.02, 0.07, 0.1, 0.9},
        anchors = {{point = "TOPLEFT"}, {point = "BOTTOMRIGHT"}},
    },
    FFXIV_PartyBarShineTemplate = {
        layer = "OVERLAY", height = 1, color = {0.75, 0.94, 1, 0.65},
        anchors = {{point = "TOPLEFT"}, {point = "TOPRIGHT"}},
    },
}
for template, spec in pairs(barArt) do
    local region = assert(xml:match('<Texture name="' .. template .. '" virtual="true">.-</Texture>'))
    local color = string.format('<Color r="%s" g="%s" b="%s" a="%s"/>', unpack(spec.color))
    assert(region:find(color, 1, true), template .. " color mismatch")
    if spec.height then assert(region:find('<Size y="1"/>', 1, true)) end
    for _, anchor in ipairs(spec.anchors) do
        local text = '<Anchor point="' .. anchor.point .. '"'
            .. (anchor.x and string.format(' x="%d" y="%d"', anchor.x, anchor.y) or "") .. '/>'
        assert(region:find(text, 1, true), template .. " anchor mismatch")
    end
end
assert(xml:find('name="FFXIV_PartyRowVisualTemplate" virtual="true" setAllPoints="true" enableMouse="false"', 1, true))
for _, spec in ipairs({
    {"iconBorder", "26", "28", "TOPLEFT", nil, "0", "-1"},
    {"badge", "11", "12", "TOPLEFT", nil, "33", "-1"},
    {"iconBackground", "24", "26", "TOPLEFT", nil, "1", "-2"},
    {"icon", "20", "20", "TOPLEFT", nil, "3", "-5"},
    {"level", "32", "13", "TOPLEFT", nil, "47", "-1"},
    {"name", "180", "15", "TOPLEFT", nil, "80", "0"},
    {"healthValue", nil, nil, "TOPRIGHT", "TOPLEFT", "142", "-22"},
    {"powerValue", nil, nil, "TOPRIGHT", "TOPLEFT", "260", "-22"},
}) do
    local key, width, height, point, relativePoint, x, y = unpack(spec, 1, 7)
    local region = assert(xml:match('<%w+ parentKey="' .. key .. '".-</%w+>'))
    if width then assert(region:find('<Size x="' .. width .. '" y="' .. height .. '"/>', 1, true)) end
    local anchor = '<Anchor point="' .. point .. '"'
        .. (relativePoint and ' relativePoint="' .. relativePoint .. '"' or "")
        .. ' x="' .. x .. '" y="' .. y .. '"/>'
    assert(region:find(anchor, 1, true), key .. " anchor changed")
end
for _, key in ipairs({"order", "level", "name", "healthValue", "powerValue"}) do
    local region = assert(xml:match('<FontString parentKey="' .. key .. '".-</FontString>'))
    local font = (key == "healthValue" or key == "powerValue") and "EurostileExtended" or "AxisMedium"
    assert(region:find('font="Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\' .. font .. '.ttf" outline="NORMAL"', 1, true))
    assert(region:find('<FontHeight val="' .. (key == "name" and "13" or "11") .. '"/>', 1, true))
    assert(region:find('<Color r="0" g="0.12" b="0.2"/>', 1, true))
    assert(region:find('<Offset x="1" y="-1"/>', 1, true))
end
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do index = index + 1; lines[line] = index end
    assert(assert(lines["PartyFrames/PartyFrames.xml"]) < assert(lines["PartyFrames/PartyFrames.lua"]))
    assert(lines["PartyFrames/PartyFrames.lua"] < assert(lines["PartyFrames/EnemyList.lua"]))
end
print("PASS: shared row XML geometry, text styling, and both TOC orders")
local playerTemplate = assert(xml:match('<Button name="FFXIV_PartyPlayerTemplate".-</Button>'))
for _, text in ipairs({
    'virtual="true" inherits="SecureUnitButtonTemplate" hidden="true"',
    '<Size x="284" y="32"/>',
    '<StatusBar parentKey="health" inherits="FFXIV_PartyPlayerBarTemplate">',
    '<StatusBar parentKey="ManaBar" inherits="FFXIV_PartyPlayerBarTemplate">',
    '<Anchor point="TOPLEFT" x="34" y="-16"/>',
    '<Anchor point="TOPLEFT" x="152" y="-16"/>',
    '<BarColor r="0.36" g="0.78" b="1"/>',
}) do assert(playerTemplate:find(text, 1, true), "Player row XML missing: " .. text) end
local barTemplate = assert(xml:match('<StatusBar name="FFXIV_PartyPlayerBarTemplate".-</StatusBar>'))
for _, text in ipairs({
    'virtual="true" enableMouse="false"',
    '<Size x="108" y="5"/>',
    '<BarTexture file="Interface\\Buttons\\WHITE8X8"/>',
}) do assert(barTemplate:find(text, 1, true), "Player bar XML missing: " .. text) end

local combat = false
local members, visuals, units = {}, {}, {}
local watcher, layouts = nil, 0
local build = 16001
local passed = 0
local playerButton
local methods = {}

local function object(protected)
    return setmetatable({protected = protected, texts = {}}, {__index = methods})
end

local function checkLayout(self)
    assert(not (combat and self.protected), "Protected layout changed in combat")
end

function methods:SetSize(width, height)
    checkLayout(self)
    self.width, self.height = width, height
end
function methods:SetHeight(height) checkLayout(self); self.height = height end
function methods:ClearAllPoints() checkLayout(self); self.point = nil end
function methods:SetPoint(...) checkLayout(self); self.point = {...} end
function methods:SetAllPoints(relativeTo) checkLayout(self); self.allPoints = relativeTo or true end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:SetTexture(texture) self.texture = texture end
function methods:SetTexCoord(...) self.coords = {...} end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetVertexColor(...) self.vertexColor = {...} end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:SetFont(font, size) self.font, self.size = font, size end
function methods:SetText(text) self.text = text end
function methods:SetFormattedText(format, value)
    self.text = type(value) == "table" and value or string.format(format, value)
end
function methods:SetTextColor(...) self.color = {...} end
function methods:SetShadowColor(...) self.shadowColor = {...} end
function methods:SetShadowOffset(...) self.shadowOffset = {...} end
function methods:SetJustifyH(value) self.justifyH = value end
function methods:SetWordWrap(value) self.wordWrap = value end
function methods:EnableMouse(value) self.mouseEnabled = value end
function methods:SetFrameLevel(value) self.frameLevel = value end
function methods:GetFrameLevel() return self.frameLevel or 2 end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetScript(script, callback) self.scripts[script] = callback end
function methods:SetStatusBarTexture(texture) self.fill:SetTexture(texture) end
function methods:GetStatusBarTexture() return self.fill end
function methods:SetStatusBarColor(...) self.color = {...} end
function methods:SetValue(value) self.value = value end
function methods:CreateTexture(_, layer, template, subLevel)
    local texture = object(false)
    if template then
        local spec = assert(barArt[template], "Unknown bar artwork template")
        assert(layer == spec.layer and subLevel == spec.subLevel, "Bar artwork layering changed")
        texture.template, texture.parent = template, self
        self.barTextures = self.barTextures or {}
        self.barTextures[#self.barTextures + 1] = texture
    end
    return texture
end
function methods:CreateFontString()
    local text = object(false)
    self.texts[#self.texts + 1] = text
    return text
end
function methods:SetAttribute(key, value)
    assert(self == playerButton, "Must not change Blizzard's secure attributes")
    self.attributes[key] = value
end
function methods:RegisterForClicks(...) self.clicks = {...} end
function methods:SetMinMaxValues(low, high) self.minimum, self.maximum = low, high end
function methods:Show()
    assert(not self.protected, "Must not show Blizzard's protected frames")
    self.shown = true
end
function methods:Hide()
    assert(not self.protected, "Must not hide Blizzard's protected frames")
    self.shown = false
end

function CreateFrame(kind, name, parent, template)
    local frame = object(false)
    frame.events, frame.scripts = {}, {}
    if kind == "StatusBar" then
        frame.fill = object(false)
    elseif parent then
        visuals[parent] = frame
    else
        watcher = frame
    end
    if name == "FFXIV_PartyPlayer" then
        assert(not combat and kind == "Button" and template == "FFXIV_PartyPlayerTemplate")
        playerButton = frame
        frame.attributes = {}
        frame.template = template
        frame:SetSize(284, 32)
        frame:Hide()
        for key, x in pairs({health = 34, ManaBar = 152}) do
            local bar = object(false)
            bar.fill = object(false)
            bar:SetSize(108, 5)
            bar:SetPoint("TOPLEFT", x, -16)
            bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
            bar:EnableMouse(false)
            frame[key] = bar
        end
        frame.health:SetStatusBarColor(0.36, 0.78, 1)
    end
    if template == "FFXIV_PartyRowVisualTemplate" then
        assert(kind == "Frame" and parent)
        frame.template = template
        frame:SetAllPoints()
        frame:EnableMouse(false)
        frame.icon, frame.badge = object(false), object(false)
        for _, key in ipairs({"order", "level", "name", "healthValue", "powerValue"}) do
            frame[key] = frame:CreateFontString()
        end
        frame.order:SetPoint("TOPLEFT", frame, "TOPLEFT")
    end
    return frame
end
function RegisterStateDriver(frame, state, condition)
    assert(not combat and frame == playerButton and state == "visibility")
    frame.visibilityCondition = condition
end
function hooksecurefunc(target, name, callback)
    local original = assert(target[name], "Missing hook method: " .. name)
    target[name] = function(...)
        original(...)
        callback(...)
    end
end
function InCombatLockdown() return combat end
function GetBuildInfo() return "", "", "", build end
function issecretvalue(value) return type(value) == "table" and value.secret end
function UnitHealth(unit) return units[unit].health end
function UnitPower(unit) return units[unit].power end
function UnitHealthMax() return 1000 end
function UnitPowerMax() return 100 end
function UnitPowerType(unit)
    local data = units[unit]
    return data.powerType or 0, data.powerToken or "MANA", data.alternateR, data.alternateG, data.alternateB
end
function UnitIsConnected(unit) return units[unit].connected end
function UnitIsDeadOrGhost(unit) return units[unit].dead end
function UnitLevel(unit) return units[unit].level end
function UnitClass(unit) return "Mage", units[unit].class end
function UnitName(unit) return units[unit].firstName end
function GetUnitName(unit) return units[unit].name end

CLASS_ICON_TCOORDS = {MAGE = {0.25, 0.5, 0, 0.25}, WARRIOR = {0, 0.25, 0, 0.25}}
PowerBarColor = {
    MANA = {r = 0, g = 0, b = 1},
    RAGE = {r = 1, g = 0, b = 0},
    ENERGY = {r = 1, g = 1, b = 0},
    [2] = {r = 1, g = 0.5, b = 0.25},
}
PLAYER_OFFLINE, DEAD = "Offline", "Dead"
unpack = unpack or table.unpack

local function bar()
    local result = object(true)
    result.fill = object(false)
    for _, key in ipairs({"CenterText", "LeftText", "RightText", "ManaBarMask"}) do
        result[key] = object(false)
    end
    return result
end

local function member(index)
    local result = object(true)
    result.unit, result.unitToken, result.layoutIndex = "party" .. index, "party" .. index, index
    result.GetUnit = function(self) return self.overrideUnit or self.unit end
    result.ToPlayerArt = function(self)
        self.unit, self.overrideUnit = self.unitToken, nil
        self.HealthBarContainer.point = {"Blizzard reset"}
    end
    result.ToVehicleArt = function(self)
        self.overrideUnit, self.unit = self.unitToken, "partypet" .. index
        self.HealthBarContainer.point = {"Blizzard reset"}
    end
    result.UpdateMember = function() end
    result.HealthBarContainer = object(true)
    result.HealthBarContainer.HealthBar = bar()
    for _, key in ipairs({"HealthBarMask", "CenterText", "LeftText", "RightText"}) do
        result.HealthBarContainer[key] = object(false)
    end
    result.ManaBar = bar()
    for _, key in ipairs({"Portrait", "Texture", "VehicleTexture", "Flash", "Name", "ResurrectableIndicator"}) do
        result[key] = object(false)
    end
    for _, key in ipairs({"AuraFrameContainer", "PetFrame", "ReadyCheck", "PowerBarAlt"}) do
        result[key] = object(true)
    end
    result.PartyMemberOverlay = object(false)
    for _, key in ipairs({"Status", "LeaderIcon", "GuideIcon", "RoleIcon", "PVPIcon", "Disconnect"}) do
        result.PartyMemberOverlay[key] = object(false)
    end
    units[result.unit] = {
        name = "First Last", firstName = "First", class = "MAGE",
        level = 50, health = 5975, power = 1965, connected = true, dead = false,
    }
    members[#members + 1] = result
    return result
end

local function setup(clientBuild)
    combat, members, visuals, units, layouts = false, {}, {}, {}, 0
    playerButton = nil
    units.player = {
        name = "Player Surname", firstName = "Player", class = "MAGE",
        level = 50, health = 900, power = 80, connected = true, dead = false,
    }
    build = clientBuild
    PartyFrame = {
        Background = object(false),
        PartyMemberFramePool = {
            EnumerateActive = function()
                local index = 0
                return function()
                    index = index + 1
                    return members[index]
                end
            end,
        },
        InitializePartyMemberFrames = function() end,
        Layout = function() assert(not combat); layouts = layouts + 1 end,
    }
    local namespace = {}
    assert(loadfile("FFXIV_UI\\PartyFrames\\PartyFrames.lua"))("FFXIV_UI", namespace)
    return namespace
end

local function event(name, ...)
    assert(watcher.events[name], "Event not registered: " .. name)
    watcher.scripts.OnEvent(watcher, name, ...)
end

local function test(name, run)
    run()
    passed = passed + 1
    print("PASS: " .. name)
end

test("skins Blizzard's member rows and preserves unit interactions", function()
    setup(16001)
    local first, second = member(1), member(2)
    local nativeUpdate, nativeGetUnit = first.UpdateMember, first.GetUnit
    event("PLAYER_ENTERING_WORLD")
    assert(first.width == 284 and first.height == 32)
    assert(second.width == 284)
    assert(first.unit == "party1" and first.GetUnit == nativeGetUnit)
    assert(first.UpdateMember ~= nativeUpdate)
    assert(first.HealthBarContainer.width == 108)
    assert(first.HealthBarContainer.HealthBar.allPoints == first.HealthBarContainer)
    assert(first.ManaBar.width == 108 and first.ManaBar.height == 5)
    assert(first.Portrait.alpha == 0 and first.Name.alpha == 0)
    assert(first.PartyMemberOverlay.Status.color[4] == 0.12)
    assert(first.PartyMemberOverlay.Status.allPoints == first)
    assert(first.PartyMemberOverlay.LeaderIcon.alpha == nil)
    assert(first.ReadyCheck.point[1] == "CENTER")
    assert(first.ReadyCheck.point[2].desaturated == true)
    assert(visuals[first].texts[1].text == 2 and visuals[second].texts[1].text == 3)
    assert(visuals[first].texts[2].text == "Lv50")
    assert(visuals[first].texts[3].text == "First Last")
    assert(visuals[first].texts[4].text == 5975 and visuals[first].texts[5].text == 1965)
    assert(first.AuraFrameContainer.point[3] == "TOPRIGHT")
    assert(first.PetFrame.point[5] == -35)
    assert(visuals[first].mouseEnabled == false)
    local visual = visuals[first]
    assert(visual.template == "FFXIV_PartyRowVisualTemplate")
    assert(visual.frameLevel == first:GetFrameLevel() + 1 and visual.allPoints)
    assert(visual.order.point[1] == "CENTER" and visual.order.point[2] == visual.badge)
    assert(visual.icon.desaturated and visual.icon.vertexColor[2] == 0.84)
    for index, key in ipairs({"order", "level", "name", "healthValue", "powerValue"}) do
        assert(visual[key] == visual.texts[index], "Shared row must bind XML text children")
    end
    assert(#members == 2 and PartyFrame.Background.alpha == 0)
end)

test("player is first, party-only, securely clickable, and updates health and power", function()
    assert(playerButton and playerButton.unit == "player")
    assert(playerButton.template == "FFXIV_PartyPlayerTemplate")
    assert(playerButton.width == 284 and playerButton.height == 32)
    assert(playerButton.HealthBarContainer.HealthBar == playerButton.health)
    for _, bar in ipairs({playerButton.health, playerButton.ManaBar}) do
        assert(bar.width == 108 and bar.height == 5 and bar.mouseEnabled == false)
        assert(bar.frameLevel == playerButton:GetFrameLevel() + 1)
        assert(bar.fill.texture == "Interface\\Buttons\\WHITE8X8")
    end
    assert(playerButton.health.point[2] == 34 and playerButton.ManaBar.point[2] == 152)
    assert(playerButton.health.color[1] == 0.36 and playerButton.health.color[2] == 0.78)
    for _, bar in ipairs({members[1].HealthBarContainer.HealthBar, members[1].ManaBar,
        playerButton.health, playerButton.ManaBar}) do
        assert(#bar.barTextures == 3, "Each bar must receive exactly three artwork textures")
        for index, template in ipairs({"FFXIV_PartyBarEdgeTemplate",
            "FFXIV_PartyBarBackgroundTemplate", "FFXIV_PartyBarShineTemplate"}) do
            assert(bar.barTextures[index].template == template and bar.barTextures[index].parent == bar)
        end
    end
    assert(playerButton.ignoreLayout)
    assert(playerButton.attributes.unit == "player" and playerButton.attributes.type1 == "target")
    assert(playerButton.attributes.type2 == "togglemenu")
    assert(playerButton.visibilityCondition == "[group:raid] hide; [group:party] show; hide")
    assert(playerButton.point[1] == "BOTTOMLEFT" and playerButton.point[2] == members[1])
    local text = visuals[playerButton].texts
    assert(text[1].text == 1 and text[3].text == "Player Surname")
    units.player.health, units.player.power, units.player.powerToken = 700, 20, "RAGE"
    event("UNIT_HEALTH", "player")
    assert(playerButton.HealthBarContainer.HealthBar.value == 700 and text[4].text == 700)
    event("UNIT_DISPLAYPOWER", "player")
    assert(playerButton.ManaBar.fill.vertexColor[1] == 1 and playerButton.ManaBar.fill.vertexColor[2] == 0)
    assert(text[5].text == 20)
    combat = true
    local point = playerButton.point
    event("GROUP_ROSTER_UPDATE")
    assert(playerButton.point == point)
    combat = false
    event("PLAYER_REGEN_ENABLED")
    assert(playerButton.point[2] == members[1])
end)

test("portrait pulsing cannot restore the old portrait and combat cues remain", function()
    local first = members[1]
    first.Portrait:Show()
    first.Portrait:SetAlpha(1)
    assert(first.Portrait.shown == false)
    first.Flash:Show()
    first.Flash:SetAlpha(0.5)
    assert(first.Flash.shown == true)
    assert(first.Flash.color[1] == 1 and first.Flash.color[4] == 0.12)
    assert(first.Flash.allPoints == first)
end)

test("native value updates and resource changes refresh current numbers", function()
    local first = members[1]
    units.party1.health, units.party1.power = 4200, 0
    first.HealthBarContainer.HealthBar:SetValue(4200)
    assert(visuals[first].texts[4].text == 4200)
    assert(visuals[first].texts[5].text == 0)
    units.party1.power = 40
    first.ManaBar:SetValue(40)
    assert(visuals[first].texts[5].text == 40)
    first.ManaBar:SetStatusBarColor(1, 0, 0)
    assert(first.ManaBar.fill.vertexColor[1] == 0)
    assert(first.ManaBar.fill.vertexColor[3] == 1)
end)

test("resource colors follow power type while health remains blue", function()
    local first = members[1]
    for _, token in ipairs({"MANA", "RAGE", "ENERGY"}) do
        units.party1.powerToken = token
        event("UNIT_DISPLAYPOWER", "party1")
        local expected = PowerBarColor[token]
        local actual = first.ManaBar.fill.vertexColor
        assert(actual[1] == expected.r and actual[2] == expected.g and actual[3] == expected.b)
        first.ManaBar:SetStatusBarColor(0.36, 0.78, 1)
        assert(first.ManaBar.fill.vertexColor[1] == expected.r)
    end
    first.HealthBarContainer.HealthBar:SetStatusBarColor(1, 0, 0)
    assert(first.HealthBarContainer.HealthBar.fill.vertexColor[1] == 0.36)
    units.party1.powerToken, units.party1.powerType = "UNKNOWN", 2
    event("UNIT_DISPLAYPOWER", "party1")
    assert(first.ManaBar.fill.vertexColor[2] == 0.5)
    units.party1.powerType = 99
    units.party1.alternateR, units.party1.alternateG, units.party1.alternateB = 0.2, 0.4, 0.6
    event("UNIT_DISPLAYPOWER", "party1")
    assert(first.ManaBar.fill.vertexColor[1] == 0.2)
    assert(first.ManaBar.fill.vertexColor[3] == 0.6)
    units.party1.alternateR, units.party1.alternateG, units.party1.alternateB = nil, nil, nil
    event("UNIT_DISPLAYPOWER", "party1")
    assert(first.ManaBar.fill.vertexColor[1] == 1 and first.ManaBar.fill.vertexColor[3] == 1)
end)

test("offline, dead, level, and full-name updates are event-driven", function()
    local first = members[1]
    units.party1.connected = false
    event("UNIT_CONNECTION", "party1")
    assert(visuals[first].texts[4].text == PLAYER_OFFLINE)
    units.party1.connected, units.party1.dead = true, true
    event("UNIT_FLAGS", "party1")
    assert(visuals[first].texts[4].text == DEAD)
    units.party1.dead, units.party1.level = false, -1
    event("UNIT_LEVEL", "party1")
    assert(visuals[first].texts[2].text == "Lv??")
    units.party1.name = "New Surname"
    event("UNIT_NAME_UPDATE", "party1")
    assert(visuals[first].texts[3].text == "New Surname")
end)

test("secret health, power, names, levels, and flags are not inspected", function()
    local secret = setmetatable({secret = true}, {
        __le = function() error("Compared secret") end,
        __lt = function() error("Compared secret") end,
        __tostring = function() error("Converted secret") end,
    })
    local first = members[1]
    for _, key in ipairs({"health", "power", "name", "level", "connected", "dead", "class"}) do
        units.party1[key] = secret
    end
    event("UNIT_NAME_UPDATE", "party1")
    for index = 2, 5 do assert(visuals[first].texts[index].text == secret) end
end)

test("vehicle art resets defer protected layout until combat ends", function()
    setup(16001)
    local first = member(1)
    units.partypet1 = {health = 9000, power = 100, connected = true, dead = false}
    event("PLAYER_ENTERING_WORLD")
    combat = true
    first:ToVehicleArt()
    assert(first.HealthBarContainer.point[1] == "Blizzard reset")
    assert(visuals[first].texts[3].text == "First Last")
    assert(visuals[first].texts[4].text == 9000)
    assert(visuals[first].texts[5].text == 100)
    combat = false
    event("PLAYER_REGEN_ENABLED")
    assert(first.HealthBarContainer.point[1] == "TOPLEFT")
    assert(first.HealthBarContainer.point[4] == 34)
    first:ToPlayerArt()
    assert(visuals[first].texts[4].text == 5975)
end)

test("new party members in combat are skinned after combat without duplicate hooks", function()
    local first = members[1]
    local firstVisual = visuals[first]
    combat = true
    local second = member(2)
    event("GROUP_ROSTER_UPDATE")
    assert(visuals[second] == nil)
    combat = false
    event("PLAYER_REGEN_ENABLED")
    assert(visuals[second] and visuals[second].texts[1].text == 3)
    assert(visuals[first] == firstVisual and #firstVisual.texts == 5)
    PartyFrame:InitializePartyMemberFrames()
    assert(visuals[first] == firstVisual and #firstVisual.texts == 5)
end)

test("Mainline uses the native name rather than Forever's full name", function()
    setup(120001)
    local first = member(1)
    event("PLAYER_ENTERING_WORLD")
    assert(visuals[first].texts[3].text == "First")
end)

test("pet row follows the party list, solo, roster, raid-style, and combat transitions", function()
    local namespace = setup(16001)
    local pet = object(false)
    pet.attributes, pet.scripts, pet.events = {}, {}, {}
    pet.visual = object(false)
    pet.visual.icon = object(false)
    pet.visual.badge = object(false)
    local petTexts = {}
    for _, key in ipairs({"order", "level", "name", "healthValue", "powerValue"}) do
        pet.visual[key] = object(false)
        petTexts[#petTexts + 1] = pet.visual[key]
    end
    pet.health, pet.power = object(false), object(false)
    local petBars = {pet.health, pet.power}
    PetFrame_HP = pet
    local xmlFile = assert(io.open("FFXIV_UI\\PlayerFrames\\PetFrame_HP.xml", "r"))
    local xml = xmlFile:read("*a")
    xmlFile:close()
    assert(xml:find('name="PetFrame_HP"', 1, true) and xml:find('inherits="SecureUnitButtonTemplate"', 1, true))
    assert(xml:find('parentKey="health"', 1, true) and xml:find('parentKey="power"', 1, true))
    function methods:GetEffectiveScale() return self.scale or 1 end
    function methods:SetScale(value) checkLayout(self); self.scale = value end
    function methods:SetFrameStrata(value) self.strata = value end
    function methods:RegisterForClicks(...) self.clicks = {...} end
    function methods:SetMinMaxValues(low, high) self.minimum, self.maximum = low, high end
    function methods:HookScript(script, callback)
        local previous = self.scripts[script]
        self.scripts[script] = function(...)
            if previous then previous(...) end
            callback(...)
        end
    end
    function methods:IsShown() return self.shown ~= false end
    function methods:SetAttribute(key, value)
        assert(self == pet, "Must only set secure attributes on our own pet button")
        self.attributes[key] = value
    end
    UIParent = object(false)
    PartyFrame.shown, PartyFrame.scale, PartyFrame.scripts = false, 1.4, {}
    PartyFrame.IsShown = methods.IsShown
    PartyFrame.GetEffectiveScale = methods.GetEffectiveScale
    PartyFrame.SetScale = methods.SetScale
    PartyFrame.HookScript = methods.HookScript
    PartyFrame.spacing = 10
    local petExists = true
    function UnitExists(unit) return unit == "pet" and petExists or units[unit] ~= nil end
    function UnitHealthMax() return 1000 end
    function UnitPowerMax() return 100 end
    function RegisterUnitWatch(frame)
        assert(not combat and frame == pet)
        frame.unitWatch = true
        frame.shown = petExists
    end
    units.pet = {
        name = "Gobrot", health = 203, power = 60, level = 12,
        powerToken = "ENERGY", connected = true, dead = false,
    }
    assert(loadfile("FFXIV_UI\\PlayerFrames\\PetFrame_HP.lua"))("FFXIV_UI", namespace)
    event("PLAYER_ENTERING_WORLD")
    assert(pet.unitWatch and pet.shown and pet.attributes.unit == "pet")
    assert(pet.attributes.type1 == "target" and pet.attributes.type2 == "togglemenu")
    assert(pet.point[2] == PartyFrame and pet.point[3] == "TOPLEFT")
    assert(pet.scale == 1.4)
    assert(petTexts[1].text == "P" and petTexts[3].text == "Gobrot")
    assert(petBars[1].value == 203 and petBars[1].maximum == 1000)
    assert(petBars[2].value == 60 and petBars[2].color[1] == 1 and petBars[2].color[2] == 1)
    local setPoint, setScale = pet.SetPoint, pet.SetScale
    pet.SetPoint = function(self, ...)
        assert(not combat, "Pet row moved during combat")
        setPoint(self, ...)
    end
    pet.SetScale = function(self, ...)
        assert(not combat, "Pet row scaled during combat")
        setScale(self, ...)
    end

    PartyFrame.shown = true
    local first, second = member(1), member(2)
    event("GROUP_ROSTER_UPDATE")
    assert(pet.point[2] == second and pet.point[3] == "BOTTOMLEFT" and pet.point[5] == -10)
    units.party2 = nil
    PartyFrame:Layout()
    assert(pet.point[2] == first)
    units.party1 = nil
    PartyFrame:Layout()
    assert(pet.point[2] == PartyFrame)
    units.party1 = {health = 10}
    combat = true
    event("GROUP_ROSTER_UPDATE")
    assert(pet.point[2] == PartyFrame)
    combat = false
    event("PLAYER_REGEN_ENABLED")
    assert(pet.point[2] == first)

    PartyFrame.shown = false
    PartyFrame.scripts.OnHide()
    assert(pet.point[2] == PartyFrame and pet.shown)
    PartyFrame:SetScale(1.8)
    assert(pet.scale == 1.8)
    units.pet.health, units.pet.powerToken = 150, "RAGE"
    event("UNIT_HEALTH", "pet")
    assert(petBars[1].value == 150 and petTexts[4].text == 150)
    event("UNIT_DISPLAYPOWER", "pet")
    assert(petBars[2].color[1] == 1 and petBars[2].color[2] == 0)
    local secret = setmetatable({secret = true}, {
        __le = function() error("Compared secret pet value") end,
        __tostring = function() error("Converted secret pet value") end,
    })
    units.pet.health, units.pet.power, units.pet.level, units.pet.name, units.pet.dead = secret, secret, secret, secret, secret
    event("UNIT_NAME_UPDATE", "pet")
    assert(petTexts[2].text == secret and petTexts[3].text == secret)
    assert(petTexts[4].text == secret and petTexts[5].text == secret)
end)

print(string.format("%d party/pet frame tests passed", passed))
