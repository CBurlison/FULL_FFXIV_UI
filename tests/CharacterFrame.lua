local addonName, ns = ...
local combat, created = false, {}
local unavailableTextures = {}
local interfaceVersion = 120000
function GetBuildInfo() return "", "", "", interfaceVersion end
local methods = {}
local applyControlTemplate = assert(loadfile("tests\\support\\PanelTemplates.lua"))()
local characterHeaderSource = assert(io.open("FFXIV_UI\\General\\CharacterFrame.xml", "rb")):read("*a")
local function applyCharacterHeaderTemplate(value, parent, template)
    if not template or not template:match("^FFXIV_Character") then return end
    local kind, attributes, body = characterHeaderSource:match('<(%w+) name="' .. template .. '"([^>]-)>(.-)</%1>')
    assert(kind == value:GetObjectType(), "Unexpected CharacterFrame template: " .. template)
    value.template = template
    if kind == "FontString" then
        local inherits = attributes:match('inherits="([^"]+)"')
        value.font = inherits and {inherits, 12, ""} or nil
    end
    local width, height = body:match('<Size x="([^"]+)" y="([^"]+)"/>')
    if not width then height = body:match('<Size y="([^"]+)"/>') end
    if width then value.width = tonumber(width) end
    if height then value.height = tonumber(height) end
    for anchor in body:gmatch("<Anchor (.-)/>") do
        local point = assert(anchor:match('point="([^"]+)"'))
        value:SetPoint(point, parent, point, tonumber(anchor:match('x="([^"]+)"')) or 0,
            tonumber(anchor:match('y="([^"]+)"')) or 0)
    end
end
local function object(kind, parent)
    local result = setmetatable({
        kind = kind or "Frame", parent = parent, shown = true, alpha = 1,
        points = {}, scripts = {}, events = {}, children = {}, regions = {}, level = 1,
    }, {__index = methods})
    if parent then
        local list
        if kind == "Texture" or kind == "FontString" then list = parent.regions else list = parent.children end
        list[#list + 1] = result
    end
    created[#created + 1] = result
    return result
end
function methods:GetObjectType() return self.kind end
function methods:GetParent() return self.parent end
function methods:GetName() return self.name end
function methods:GetRegions() return table.unpack(self.regions) end
function methods:GetChildren() return table.unpack(self.children) end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameStrata() return self.strata or "MEDIUM" end
function methods:IsProtected() return self.protected == true end
function methods:SetFrameStrata(strata) self.strata = strata end
function methods:SetAllPoints(target) self.allPoints = target end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetBackdrop(value) self.backdrop = value end
function methods:SetBackdropColor(...) self.backdropColor = {...} end
function methods:SetBackdropBorderColor(...) self.borderColor = {...} end
function methods:SetAlpha(value) self.alpha = value end
function methods:GetAlpha() return self.alpha or 1 end
function methods:CreateTexture(_, layer, template, subLevel)
    local texture = object("Texture", self)
    texture.layer, texture.template, texture.subLevel = layer, template, subLevel
    applyControlTemplate(texture, self, template)
    applyCharacterHeaderTemplate(texture, self, template)
    if template == "FFXIV_CircularArrowBaseTemplate" or template == "FFXIV_CircularArrowGlyphTemplate"
        or template == "FFXIV_WindowCloseIconTemplate" then
        local file = assert(io.open("FFXIV_UI\\General\\WindowControls.xml", "rb"))
        local xml = file:read("*a")
        file:close()
        texture:SetTexture(assert(xml:match('<Texture name="' .. template .. '" virtual="true" file="([^"]+)"/>')))
    end
    return texture
end
function methods:CreateMaskTexture() return object("Texture", self) end
function methods:AddMaskTexture(mask) self.mask = mask end
function methods:CreateFontString(_, _, template)
    local result = object("FontString", self)
    if template and not template:match("^FFXIV_Character") then result.font = {template, 12, ""} end
    applyCharacterHeaderTemplate(result, self, template)
    return result
end
function methods:SetFont(...) self.font = {...} end
function methods:SetFontObject(value) self.fontObject = value end
function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetTextColor(...) self.color = {...} end
function methods:GetTextColor() return table.unpack(self.color or {1, 1, 1, 1}) end
function methods:GetFont() return "Fonts\\FRIZQT__.TTF", 12, "" end
function methods:GetJustifyH() return self.justify or "LEFT" end
function methods:GetFontString() return self.Text end
function methods:SetText(value)
    assert(self.font, "FontString:SetText(): Font not set")
    self.text = value
end
function methods:SetFormattedText(format, ...)
    assert(self.font)
    self.text = string.format(format, ...)
end
function methods:SetStatusBarTexture(value) self.statusTexture = value end
function methods:SetStatusBarColor(...) self.statusColor = {...} end
function methods:SetMinMaxValues(...) self.range = {...} end
function methods:SetValue(value) self.value = value end
function methods:RegisterUnitEvent(name, unit) self.events[name] = unit end
function methods:GetStringWidth() return #self.text * self.font[2] * 0.5 end
function methods:GetText() return self.text end
function methods:GetStringHeight() return self.height or self.font and self.font[2] or 14 end
function methods:GetPoint(index) return table.unpack(self.points[index or 1] or {}) end
function methods:SetWordWrap(value) self.wrap = value end
function methods:CanWordWrap() return self.wrap == true end
function methods:SetMaxLines(value) self.maxLines = value end
function methods:GetMaxLines() return self.maxLines or 0 end
function methods:SetJustifyV(value) self.justifyV = value end
function methods:SetJustifyH(value) self.justify = value end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetTexture(value, horizontalWrap, verticalWrap)
    if unavailableTextures[value] then self.texture = nil; return false end
    self.texture = value
    self.horizontalWrap, self.verticalWrap = horizontalWrap, verticalWrap
    return true
end
function methods:SetGradient(direction, startColor, endColor)
    self.gradient = {direction, startColor, endColor}
end
function methods:GetTexture() return self.texture end
function methods:SetAtlas(value) self.atlas = value; self.texture = "native atlas" end
function methods:GetAtlas() return self.atlas end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:RemoveMaskTexture(value) self.removedMask = value end
function methods:IsEnabled() return self.enabled ~= false end
function methods:SetEnabled(value)
    self.enabled = value
    local handler = self.scripts[value and "OnEnable" or "OnDisable"]
    if handler then handler(self) end
end
function SetPortraitTexture(texture) texture.texture = "native portrait" end
function GetFileIDFromPath(path)
    local tooltipAssets = {
        ["Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Tooltip-Rim-Dark.tga"] = 721001,
        ["Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Tooltip-Background-Dark.tga"] = 721002,
        ["Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Tooltip-Fill-Dark.tga"] = 721003,
    }
    return tooltipAssets[path]
end
function CreateColor(r, g, b, a) return {r = r, g = g, b = b, a = a} end
function methods:SetTexCoord(...) self.texCoords = {...} end
function methods:GetTexCoord() return table.unpack(self.texCoords or {0, 1, 0, 1}) end
function methods:SetHorizTile(value) self.horizTile = value end
function methods:SetVertTile(value) self.vertTile = value end
function methods:SetVertexColor(...) self.vertexColor = {...}; self.color = {...} end
function methods:SetRotation(value) self.rotation = value end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:SetWidth(value) self.width = math.max(self.minWidth or 0, value) end
function methods:SetHeight(value) self.height = value end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:GetWidth() return self.width or 0 end
function methods:GetSize() return self.width or 0, self.height or 0 end
function methods:GetHeight() return self.height or 0 end
function methods:GetTop() return self.top or 500 end
function methods:GetBottom()
    local point = self.points[1]
    local relative = point and point[2]
    local top = relative and relative.GetTop and relative:GetTop() or self.parent and self.parent:GetTop() or 500
    local offset = point and type(point[5]) == "number" and point[5] or 0
    local height = self.height or self.font and self.font[2] or 0
    return top + offset - height
end
function methods:IsShown() return self.shown end
function methods:Show()
    local changed = not self.shown
    self.shown = true
    if self.nativeHeight then self.height = self.nativeHeight end
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
    if self.nativeLayout then self.nativeLayout(self) end
end
function methods:Hide()
    local changed = self.shown
    self.shown = false
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:HookScript(name, callback)
    assert(not (name == "OnClick" and self.noClickScript),
        "Cannot assign script handler for 'onclick' (script type not supported by this object)")
    local old = self.scripts[name]
    self.scripts[name] = function(...)
        if old then old(...) end
        callback(...)
    end
end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:GetScript(name) return self.scripts[name] end
function methods:RegisterEvent(name) self.events[name] = true end
function methods:UnregisterEvent(name) self.events[name] = nil end
function methods:RegisterCallback(name, callback) self[name] = callback end
function methods:EnumerateFrames()
    return ipairs(self.rows)
end
function CreateFrame(_, _, parent, template)
    local frame = object("Frame", parent)
    frame.template = template
    applyControlTemplate(frame, parent, template)
    if template == "CharacterStatFrameCategoryScrollBoxElementTemplate" then
        frame.Title = frame:CreateFontString(nil, nil, "GameFontHighlight")
        frame.Background = frame:CreateTexture()
        function frame:Init(data) self.Title:SetText(data.name) end
    elseif template == "CharacterStatFrameScrollBoxLabelElementTemplate" then
        frame.Label = frame:CreateFontString(nil, nil, "GameFontNormal")
        frame.Value = frame:CreateFontString(nil, nil, "GameFontHighlight")
        frame.Background = frame:CreateTexture()
        function frame:Init(data)
            self.Background:SetShown(data.statIndex % 2 == 1)
            self.data, self.tooltip = data, data.tooltip or data.name
            self.Label:SetText(data.labelText or data.name)
            self.Value:SetText(data.valueText or tostring(data.value or 10))
            self.Value:SetTextColor(table.unpack(data.color or {1, 1, 1}))
        end
        frame.scripts.OnEnter = function(self) return self.tooltip end
    end
    return frame
end
function InCombatLockdown() return combat end
function UnitPVPName() return "Test Paladin" end
local playerLevel, effectiveLevel = 12, 12
function UnitLevel() return playerLevel end
function UnitEffectiveLevel() return effectiveLevel end
function UnitClass() return "Paladin", "PALADIN" end
local healthValue, healthMax, powerValue, powerMax, powerToken = 250, 306, 100, 419, "MANA"
function UnitHealth(unit) return unit == "pet" and 80 or healthValue end
function UnitHealthMax(unit) return unit == "pet" and 120 or healthMax end
function UnitPowerType() return powerToken == "MANA" and 0 or 3, powerToken end
function UnitPower() return powerValue end
function UnitPowerMax() return powerMax end
PowerBarColor = {MANA = {r = 0, g = 0.4, b = 1}, ENERGY = {r = 1, g = 1, b = 0}}
ENERGY = "Energy"
LEVEL, EFFECTIVE_LEVEL_FORMAT = "Level", "%s (%s)"
CLASS_ICON_TCOORDS = {PALADIN = {0, 0.25, 0.5, 0.75}}
function PaperDollFrame_SetLevel() end
function PaperDollFrame_SetPetLevel() end
function PanelTemplates_GetSelectedTab(panel) return panel.selectedTab end
function PanelTemplates_SetTab(panel, selectedTab) panel.selectedTab = selectedTab end
local pendingTimers = {}
local elapsedFrames = 0
C_Timer = {After = function(_, callback) pendingTimers[#pendingTimers + 1] = callback end}
local function FlushTimers()
    for _ = 1, 5 do
        if #pendingTimers == 0 then return end
        elapsedFrames = elapsedFrames + 1
        local queued = pendingTimers
        pendingTimers = {}
        for _, callback in ipairs(queued) do callback() end
    end
end
function hooksecurefunc(target, method, callback)
    if type(target) == "string" then target, method, callback = _G, target, method end
    local original = assert(target[method], "missing native method: " .. method)
    target[method] = function(...)
        original(...)
        callback(...)
    end
end
CHARACTER = "Character"
CHARACTER_FRAME_HEIGHT = 484
STAT_CATEGORY_GENERAL, STAT_CATEGORY_PRIMARY_ATTRIBUTES = "General", "Primary Attributes"
STAT_CATEGORY_WEAPONS, STAT_CATEGORY_MODIFIERS = "Weapons", "Modifiers"
STAT_CATEGORY_DEFENSE, STAT_CATEGORY_RESISTANCE = "Defense", "Resistances"
ScrollBoxListMixin = {Event = {OnUpdate = "Updated"}}
SMART_NAV_INPUT_DIRECTION = {LEFT = "left", RIGHT = "right"}
function SmartNavigation_RegisterOutgoingDirNavCallback(button, direction, callback)
    button.callbacks = button.callbacks or {}
    button.callbacks[direction] = button.callbacks[direction] or {}
    table.insert(button.callbacks[direction], callback)
end
function SmartNavigation_ClearJumpNavigationOverridesInDirection(button, direction)
    button.jumps = button.jumps or {}
    button.jumps[direction] = nil
end
function SmartNavigation_AddJumpNavigationOverride(button, direction, target)
    button.jumps = button.jumps or {}
    button.jumps[direction] = target
end
local namespace, skinned = {}, {}
namespace.ApplyButtonSkin = function(button, _, style) skinned[button] = style end
table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
SPELL, ABILITY = "Spell", "Ability"
local secretStatText = {}
issecretvalue = function(value) return value == secretStatText end
Enum = {
    TooltipDataType = {Item = 1, Spell = 2, Currency = 3, UnitAura = 4, Flyout = 5, Mount = 6, Toy = 7},
    PowerType = {Mana = 0, Rage = 1, Focus = 2, Energy = 3, RunicPower = 6},
    ItemClass = {Consumable = 0, Recipe = 9},
    TooltipDataLineType = {
        ItemName = 22, ItemBinding = 20, ItemSpellTriggerOnUse = 44,
        SpellDescription = 34, FlavorText = 37, SellPrice = 11,
        EquipSlot = 21, ItemLevel = 31, UsageRequirement = 43,
        SpellName = 13, SpellPassive = 33, None = 0, Blank = 1, AuraCaster = 51,
    },
}
local tooltipPostCalls, itemTooltipPostCall, spellTooltipPreCall, spellTooltipPostCall = {}, nil, nil, nil
local tooltipPreCalls = {}
TooltipDataProcessor = {AddTooltipPostCall = function(tooltipType, callback)
    assert(tooltipType == Enum.TooltipDataType.Item or tooltipType == Enum.TooltipDataType.Spell
        or tooltipType == Enum.TooltipDataType.Currency or tooltipType == Enum.TooltipDataType.UnitAura
        or tooltipType == Enum.TooltipDataType.Flyout
        or tooltipType == Enum.TooltipDataType.Mount or tooltipType == Enum.TooltipDataType.Toy)
    tooltipPostCalls[tooltipType] = callback
    if tooltipType == Enum.TooltipDataType.Item then itemTooltipPostCall = callback end
    if tooltipType == Enum.TooltipDataType.Spell then spellTooltipPostCall = callback end
end}
TooltipDataProcessor.AddTooltipPreCall = function(tooltipType, callback)
    assert(tooltipType == Enum.TooltipDataType.Spell or tooltipType == Enum.TooltipDataType.Flyout)
    tooltipPreCalls[tooltipType] = callback
    if tooltipType == Enum.TooltipDataType.Spell then spellTooltipPreCall = callback end
end
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\RoundedPanels.lua"))("FFXIV_UI", namespace)
do
    local panel = object("Frame")
    panel:SetSize(400, 300)
    namespace.RoundWindow(panel, true)
    local rim, interior, lighting = panel.FFXIVUIWindowRim, panel.FFXIVUIWindowInterior, panel.FFXIVUIWindowLighting
    assert(#panel.regions == 23 and #rim == 8 and #interior == 9 and #lighting == 6)
    local geometry = {
        {8, 8, {"TOPLEFT", 0, 0}},
        {nil, 8, {"TOPLEFT", 8, 0}, {"TOPRIGHT", -8, 0}},
        {8, 8, {"TOPRIGHT", 0, 0}},
        {8, nil, {"TOPLEFT", 0, -8}, {"BOTTOMLEFT", 0, 8}},
        {nil, nil, {"TOPLEFT", 8, -8}, {"TOPRIGHT", -8, -8}, {"BOTTOMLEFT", 8, 8}, {"BOTTOMRIGHT", -8, 8}},
        {8, nil, {"TOPRIGHT", 0, -8}, {"BOTTOMRIGHT", 0, 8}},
        {8, 8, {"BOTTOMLEFT", 0, 0}},
        {nil, 8, {"BOTTOMLEFT", 8, 0}, {"BOTTOMRIGHT", -8, 0}},
        {8, 8, {"BOTTOMRIGHT", 0, 0}},
    }
    local function CheckGeometry(texture, expected)
        assert(texture.parent == panel and texture.width == expected[1] and texture.height == expected[2])
        local anchorCount = 0
        for index = 3, 6 do
            if not expected[index] then break end
            anchorCount = anchorCount + 1
            local actual, point = texture.points[index - 2], expected[index]
            assert(actual[1] == point[1] and actual[2] == panel and actual[3] == point[1]
                and actual[4] == point[2] and actual[5] == point[3])
        end
        assert(#texture.points == anchorCount)
    end
    local uv, edgeIndex = {0, 0.25, 0.75, 1}, 0
    local root = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\"
    for index, piece in ipairs(interior) do
        local row, column = math.floor((index - 1) / 3) + 1, (index - 1) % 3 + 1
        local texture = piece.texture
        CheckGeometry(texture, geometry[index])
        assert(texture.template == "FFXIV_WindowBackground" .. row .. column .. "Template")
        assert(piece.row == row and piece.column == column and texture.layer == "BACKGROUND" and texture.subLevel == -2)
        assert(texture.texture == root .. "Window-Background-Dark.tga")
        assert(texture.horizontalWrap == "REPEAT" and texture.verticalWrap == "REPEAT"
            and texture.horizTile and texture.vertTile)
        assert(texture.alpha == ((row ~= 2 and column ~= 2) and 0 or 1))
        local x = column == 1 and 0 or column == 2 and 8 or 392
        local y = row == 1 and 0 or row == 2 and 8 or 292
        assert(texture.texCoords[1] == x / 128 and texture.texCoords[2] == (x + (column == 2 and 384 or 8)) / 128
            and texture.texCoords[3] == y / 128 and texture.texCoords[4] == (y + (row == 2 and 284 or 8)) / 128)
        if index ~= 5 then
            edgeIndex = edgeIndex + 1
            local edge = rim[edgeIndex]
            CheckGeometry(edge, geometry[index])
            assert(edge.template == "FFXIV_WindowRim" .. row .. column .. "Template"
                and edge.layer == "BORDER" and edge.subLevel == nil and edge.alpha == 1)
            assert(edge.texture == root .. "Window-Rim-Dark.tga")
            assert(edge.texCoords[1] == uv[column] and edge.texCoords[2] == uv[column + 1]
                and edge.texCoords[3] == uv[row] and edge.texCoords[4] == uv[row + 1])
        end
    end
    for index, texture in ipairs(lighting) do
        local row, column = math.floor((index - 1) / 3) + 1, (index - 1) % 3 + 1
        local expected = row == 1 and geometry[index] or {
            column ~= 2 and 8 or nil, 40,
            {column == 3 and "TOPRIGHT" or "TOPLEFT", column == 2 and 8 or 0, -8},
        }
        if row == 2 and column == 2 then expected[4] = {"TOPRIGHT", -8, -8} end
        CheckGeometry(texture, expected)
        assert(texture.template == "FFXIV_WindowHeader" .. row .. column .. "Template")
        assert(texture.texture == root .. "Window-Header-Dark.tga" and texture.layer == "BACKGROUND"
            and texture.subLevel == -1 and texture.alpha == ((row == 1 and column ~= 2) and 0 or 1))
        local expectedUV = {(column - 1) / 3, column / 3, row == 1 and 0 or 1 / 6, row == 1 and 1 / 6 or 1}
        for channel = 1, 4 do assert(math.abs(texture.texCoords[channel] - expectedUV[channel]) < 1e-14) end
    end
    for _, size in ipairs({{400, 300}, {900, 600}, {16, 16}, {10, 7}}) do
        panel:SetSize(unpack(size))
        panel.scripts.OnSizeChanged(panel, unpack(size))
        for _, piece in ipairs(interior) do
            local x = piece.column == 1 and 0 or piece.column == 2 and 8 or size[1] - 8
            local y = piece.row == 1 and 0 or piece.row == 2 and 8 or size[2] - 8
            local width = piece.column == 2 and math.max(1, size[1] - 16) or 8
            local height = piece.row == 2 and math.max(1, size[2] - 16) or 8
            local coords = piece.texture.texCoords
            assert(coords[1] == x / 128 and coords[2] == (x + width) / 128
                and coords[3] == y / 128 and coords[4] == (y + height) / 128)
        end
    end
    interior[5].texture:SetTexCoord(0, 0, 0, 0)
    panel.scripts.OnShow(panel)
    assert(interior[5].texture.texCoords[2] == 9 / 128, "show failed to refresh small-panel tiling")
    local count, resize, show = #created, panel.scripts.OnSizeChanged, panel.scripts.OnShow
    namespace.RoundWindow(panel, true)
    assert(#created == count and resize == panel.scripts.OnSizeChanged and show == panel.scripts.OnShow)
    for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
        local file = assert(io.open(path, "rb"))
        local toc = file:read("*a")
        file:close()
        assert(assert(toc:find("General/RoundedPanels.xml", 1, true))
            < assert(toc:find("General/RoundedPanels.lua", 1, true)))
    end
    print("PASS XML window chrome: all 23 slices, geometry, materials, UVs, tiling, small/large resize and reuse")
end
do
    local root = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\"
    local uv = {0, 0.25, 0.75, 1}
    local names = {{"TOPLEFT", "TOP", "TOPRIGHT"}, {"LEFT", "CENTER", "RIGHT"}, {"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}}
    local function ExpectedAnchors(row, column, relative)
        local list = {{names[row][column], relative, 0, 0}}
        if column == 2 then
            list[#list + 1] = {"LEFT", relative, 8, 0}
            list[#list + 1] = {"RIGHT", relative, -8, 0}
        end
        if row == 2 then
            list[#list + 1] = {"TOP", relative, 0, -8}
            list[#list + 1] = {"BOTTOM", relative, 0, 8}
        end
        return list
    end
    local function CheckAnchors(texture, row, column, relative)
        local expected = ExpectedAnchors(row, column, relative)
        assert(#texture.points == #expected, "anchor count mismatch")
        for _, point in ipairs(expected) do
            local found = false
            for _, actual in ipairs(texture.points) do
                if actual[1] == point[1] and actual[2] == point[2] and (actual[4] or 0) == point[3] and (actual[5] or 0) == point[4] then
                    found = true
                end
            end
            assert(found, "missing anchor " .. point[1])
        end
    end
    local function CheckCell(texture, row, column, expectedFile)
        assert(texture.texCoords[1] == uv[column] and texture.texCoords[2] == uv[column + 1]
            and texture.texCoords[3] == uv[row] and texture.texCoords[4] == uv[row + 1], "UV mismatch")
        assert(texture.width == (column ~= 2 and 8 or nil) and texture.height == (row ~= 2 and 8 or nil), "size mismatch")
        assert(texture.texture == expectedFile, "file mismatch")
    end

    local panel = object("Frame")
    panel:SetSize(400, 300)
    namespace.RoundWindow(panel)
    assert(#panel.regions == 19, "generic panel should create 18 slices plus grain, got " .. #panel.regions)
    local material = namespace.GetPanelMaterial()
    local index = 0
    for layerIndex, token in ipairs({"surface", "border"}) do
        for row = 1, 3 do
            for column = 1, 3 do
                index = index + 1
                local texture = panel.regions[index]
                local prefix = token == "border" and "FFXIV_RoundBorder" or "FFXIV_RoundSurface"
                assert(texture.template == prefix .. row .. column .. "Template", "template mismatch for " .. token)
                assert(texture.parent == panel and texture.layer == "BACKGROUND" and texture.subLevel == layerIndex - 3)
                CheckCell(texture, row, column, token == "border" and root .. "Panel-Border-Dark.tga"
                    or root .. "surface-" .. material .. ".tga")
                CheckAnchors(texture, row, column, panel)
            end
        end
    end
    local grain = panel.regions[19]
    assert(grain.template == "FFXIV_RoundGrainTemplate" and grain.layer == "BACKGROUND" and grain.subLevel == -1)
    assert(grain.texture == root .. "Grain.tga" and grain.horizontalWrap == "REPEAT" and grain.verticalWrap == "REPEAT"
        and grain.horizTile and grain.vertTile)
    assert(grain.texCoords[2] == 384 / 128 and grain.texCoords[4] == 284 / 128, "grain initial tiling mismatch")
    local dark = namespace.Themes.GetName()
    local expectedGrainAlpha = (dark == "Dark" or dark == "Light") and 0.018 or 0
    assert(grain.alpha == expectedGrainAlpha, "grain alpha mismatch")
    panel:SetSize(900, 600)
    panel.scripts.OnSizeChanged(panel, 900, 600)
    assert(grain.texCoords[2] == 884 / 128 and grain.texCoords[4] == 584 / 128, "grain did not resize")
    local count = #created
    namespace.RoundWindow(panel)
    assert(#created == count and #panel.regions == 19, "repeat RoundWindow should be a no-op")

    local owner, ref = object("Frame"), object("Frame")
    ref:SetSize(200, 100)
    local pieces = namespace.RoundFill(owner, ref, "surface")
    assert(#pieces == 9, "RoundFill should create 9 pieces")
    for position, texture in ipairs(pieces) do
        local row, column = math.floor((position - 1) / 3) + 1, (position - 1) % 3 + 1
        assert(texture.template == "FFXIV_RoundFill" .. row .. column .. "Template" and texture.parent == owner)
        assert(texture.layer == "BACKGROUND" and texture.subLevel == -8)
        CheckCell(texture, row, column, root .. "surface-" .. material .. ".tga")
        CheckAnchors(texture, row, column, ref)
    end

    local anchorBox = object("Frame")
    local detail = object("Frame")
    detail:SetSize(200, 400)
    detail:SetPoint("TOPLEFT", anchorBox, "TOPLEFT", 16, -14)
    detail:SetPoint("BOTTOMRIGHT", anchorBox, "BOTTOMRIGHT", -12, 14)
    local nativeArt = object("Texture", detail)
    namespace.StyleDetailPanel(detail)
    namespace.StyleDetailPanel(detail)
    assert(nativeArt.alpha == 0, "native detail art must be hidden")
    assert(detail.FFXIVUIWindowInterior == nil and detail.FFXIVUIWindowRim == nil,
        "detail panel must not add a surround; the main panel draws the background")
    assert(#detail.children == 0, "StyleDetailPanel must not add child overlays")
    local topPoint = detail.points[1]
    local bottomPoint = detail.points[2]
    assert(topPoint[1] == "TOPLEFT" and topPoint[2] == anchorBox and (topPoint[4] or 0) == 0 and (topPoint[5] or 0) == 0,
        "detail frame must fill the anchor box from the top left")
    assert(bottomPoint[1] == "BOTTOMRIGHT" and bottomPoint[2] == anchorBox and (bottomPoint[4] or 0) == 0 and (bottomPoint[5] or 0) == 0,
        "detail frame must fill the anchor box to the bottom right")
    assert(namespace.CenterDetailContent == nil, "detail content must not be centered")

    -- Forever side panes add framed section headers (CharacterFrameSidePaneCategoryTemplate) from a row pool.
    local sidePane = object("Frame")
    sidePane.Content = object("Frame", sidePane)
    local function category(text)
        local row = object("Frame", sidePane.Content)
        row:SetSize(195, 40)
        row.Background = object("Texture", row)
        row.Background.atlas = "UI-Character-Info-Title"
        row.Label = object("FontString", row)
        row.Label.text = text
        return row
    end
    local sameLevel = category("Equal-Level Enemy")
    function sidePane:AddCategory(text) return category(text) end
    namespace.StyleDetailPanel(sidePane)
    sidePane:AddCategory("Against Raid Bosses")
    local bosses = sidePane.Content.children[#sidePane.Content.children]
    local wrapped = object("Frame", sidePane.Content)
    wrapped.Label = object("FontString", wrapped)
    sidePane:AddCategory("Third")
    for _, row in ipairs({sameLevel, bosses}) do
        assert(row.Background.alpha == 0, "the framed category banner must be hidden")
        local line = row.FFXIVUIUnderline
        assert(line and line.parent == row and line.height == 1, "category headers must get the standard divider")
        assert(line.color and line.color[4] == 0.85, "the underline must use Themes.StyleDivider")
        local top, left, right = line.points[1], line.points[2], line.points[3]
        assert(top[1] == "TOP" and top[2] == row.Label and top[3] == "BOTTOM" and top[5] == -3,
            "the divider must sit under the header text")
        assert(left[1] == "LEFT" and left[2] == row and right[1] == "RIGHT" and right[2] == row,
            "the divider must span the full banner width")
    end
    local lineCount = 0
    for _, region in ipairs(bosses.regions) do
        if region.color and region.color[4] == 0.85 then lineCount = lineCount + 1 end
    end
    assert(lineCount == 1, "a pooled category row must not get a second divider")
    assert(wrapped.FFXIVUIUnderline == nil, "only category rows get the underline")

    local frame = object("Frame")
    namespace.RoundOutline(frame)
    namespace.RoundOutline(frame)
    local outline = frame.FFXIVUIOutline
    assert(#outline == 8, "RoundOutline should create 8 border pieces, got " .. #outline)
    local outlineIndex = 0
    for row = 1, 3 do
        for column = 1, 3 do
            if row ~= 2 or column ~= 2 then
                outlineIndex = outlineIndex + 1
                local texture = outline[outlineIndex]
                assert(texture.template == "FFXIV_RoundBorder" .. row .. column .. "Template" and texture.parent == frame)
                assert(texture.layer == "OVERLAY")
                CheckCell(texture, row, column, root .. "Panel-Border-Dark.tga")
                CheckAnchors(texture, row, column, frame)
            end
        end
    end
    print("PASS XML generic surfaces: 18 slices, grain, fill, outline geometry, anchors and reuse")
end
assert(loadfile("FFXIV_UI\\General\\WindowControls.lua"))("FFXIV_UI", namespace)
do
    for _, style in ipairs({"Square", "Search", "Tab", "Button", "Input"}) do
        local panel = object("Frame")
        local art = namespace.CreateControlArtwork(panel, style)
        local count = #panel.regions
        assert(namespace.CreateControlArtwork(panel, style) == art and #panel.regions == count)
        local cap = style == "Tab" and 10 or style == "Button" and 12 or 4
        for layer, key in ipairs({"fill", "border"}) do
            assert(#art[key] == (style == "Search" and layer == 2 and 0 or style == "Square" and 1 or 3))
            for index, texture in ipairs(art[key]) do
                assert(texture.parent == panel and texture.layer == "BACKGROUND" and texture.subLevel == layer - 3)
                if style == "Square" then
                    assert(texture.allPoints == panel and texture.template == "FFXIV_ControlFullTemplate")
                else
                    assert(texture.template == "FFXIV_Control" .. cap .. ({"Left", "Center", "Right"})[index] .. "Template")
                    assert(texture.points[1][1] == "TOP" and texture.points[2][1] == "BOTTOM")
                    assert(texture.texCoords[1] == ({0, 0.125, 0.875})[index]
                        and texture.texCoords[2] == ({0.125, 0.875, 1})[index]
                        and texture.texCoords[3] == 0 and texture.texCoords[4] == 1)
                    if index == 2 then
                        assert(#texture.points == 4 and texture.points[3][1] == "LEFT"
                            and texture.points[3][4] == cap and texture.points[4][1] == "RIGHT"
                            and texture.points[4][4] == -cap)
                    else
                        assert(#texture.points == 3 and texture.width == cap
                            and texture.points[3][1] == (index == 1 and "LEFT" or "RIGHT"))
                    end
                end
            end
        end
    end
    local panel = object("Frame")
    local art = namespace.CreateExtractedTabArtwork(panel)
    assert(namespace.CreateExtractedTabArtwork(panel) == art and #art.fill == 3)
    for index, texture in ipairs(art.fill) do
        assert(texture.parent == panel and texture.layer == "BACKGROUND" and texture.subLevel == nil)
        assert(texture.points[1][1] == "TOP" and texture.points[2][1] == "BOTTOM")
        if index == 2 then
            assert(#texture.points == 4 and texture.points[3][4] == 23 and texture.points[4][4] == -17)
        else
            assert(texture.width == (index == 1 and 23 or 17) and #texture.points == 3)
            assert(texture.points[3][1] == (index == 1 and "LEFT" or "RIGHT"))
        end
    end
    namespace.UpdateExtractedTabArtwork(art, true, true)
    assert(art.fill[1].vertexColor[1] == 1.12 and art.fill[1].texture:find("Tab-Selected-", 1, true))
    namespace.UpdateExtractedTabArtwork(art, false, false)
    assert(art.fill[1].vertexColor[1] == 1 and art.fill[1].texture:find("Tab-Inactive-", 1, true))
    print("PASS XML shared control/tab geometry, layers, dynamic materials and reuse")
end
do
    local owner = object("Frame")
    owner:SetFrameLevel(7)
    local source = owner:CreateTexture()
    source:SetTexture("initial shadow material")
    source:SetTexCoord(0.1, 0.3, 0.4, 0.8)
    namespace.AddTextureShadow(owner, source)
    local shadow = assert(owner.FFXIVUIControlShadow)
    assert(shadow.template == "FFXIV_ControlShadowTemplate" and shadow.parent == owner)
    assert(shadow.allPoints == owner and shadow.mouse == false and shadow.level == 6)
    for index, expected in ipairs({{0, -2, 0.18}, {-1, -2, 0.09}, {1, -2, 0.09}}) do
        local texture = shadow.sources[source][index]
        assert(texture.parent == shadow and texture.layer == "BACKGROUND")
        for point, anchor in ipairs({"TOPLEFT", "BOTTOMRIGHT"}) do
            local actual = texture.points[point]
            assert(actual[1] == anchor and actual[2] == source and actual[3] == anchor
                and actual[4] == expected[1] and actual[5] == expected[2])
        end
        assert(texture.vertexColor[1] == 0 and texture.vertexColor[2] == 0
            and texture.vertexColor[3] == 0 and texture.vertexColor[4] == expected[3])
        assert(texture.texture == source.texture and texture.texCoords[4] == 0.8)
    end
    source:SetTexture("updated shadow material")
    source:SetTexCoord(0, 1, 0, 1)
    for _, texture in ipairs(shadow.sources[source]) do
        assert(texture.texture == source.texture and texture.texCoords[4] == 1)
    end
    owner:SetFrameLevel(0)
    assert(shadow.level == 0)
    owner:SetFrameLevel(12)
    assert(shadow.level == 11)
    local count = #created
    namespace.AddTextureShadow(owner, source)
    assert(#created == count, "shadow styling duplicated existing regions")
    local secondSource = owner:CreateTexture()
    namespace.AddTextureShadow(owner, secondSource)
    assert(owner.FFXIVUIControlShadow == shadow and #shadow.regions == 6)
    print("PASS XML shadow container, source anchors, tint, synchronization, levels and reuse")
end
do
    local button = object("Button")
    button:SetScript("OnClick", function() return "native close" end)
    namespace.SkinWindowClose(button)
    local icon = button.FFXIVUICloseIcon
    assert(icon.template == "FFXIV_WindowCloseIconTemplate" and icon.layer == "OVERLAY")
    assert(icon.texture == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Close.tga")
    assert(icon.parent == button and icon.allPoints == button and icon.vertexColor[1] == 0.85)
    local count, enter = #button.regions, button.scripts.OnEnter
    namespace.SkinWindowClose(button)
    assert(#button.regions == count and button.scripts.OnEnter == enter)
    button.scripts.OnEnter()
    assert(icon.vertexColor[1] == 1 and icon.vertexColor[4] == 1)
    button.scripts.OnLeave()
    assert(icon.vertexColor[1] == 0.85 and icon.vertexColor[4] == 1)
    assert(button.scripts.OnClick() == "native close")
    print("PASS XML close icon ownership, layer, hover, native click and reuse")
end
do
    local button = object("Button")
    button:SetSize(32, 32)
    button:SetScript("OnClick", function() return "native arrow click" end)
    local art = namespace.StyleCircularArrowButton(button, "left")
    for index, key in ipairs({"base", "shadow", "glyph"}) do
        local texture = art[key]
        assert(texture.parent == button and texture.layer == "ARTWORK" and texture.subLevel == index - 1)
        assert(texture.template == (index == 1 and "FFXIV_CircularArrowBaseTemplate" or "FFXIV_CircularArrowGlyphTemplate"))
    end
    for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
        local file = assert(io.open(path, "rb"))
        local toc = file:read("*a")
        file:close()
        assert(assert(toc:find("General/WindowControls.xml", 1, true))
            < assert(toc:find("General/WindowControls.lua", 1, true)))
    end
    local regionCount = #button.regions
    local enter = button.scripts.OnEnter
    assert(art.base.texture:find("Arrow-Button-Circle.tga", 1, true))
    assert(art.glyph.texture:find("Arrow-Button-Glyph.tga", 1, true) and art.shadow.texture == art.glyph.texture)
        for direction, offset in pairs({left = {-2, 0, 0, 1}, right = {2, 0, 1, 0},
            up = {0, 2, 1, 1}, down = {0, -2, 0, 0}}) do
        assert(namespace.StyleCircularArrowButton(button, direction) == art)
        assert(art.glyph.points[1][4] == offset[1] and art.glyph.points[1][5] == offset[2])
        assert(art.shadow.points[1][4] == offset[1] and art.shadow.points[1][5] == offset[2] + 2.5)
        assert(#art.glyph.texCoords == 8)
        assert(art.glyph.texCoords[1] == offset[3] and art.glyph.texCoords[2] == offset[4],
            "circular glyph coordinates must rotate the supplied down arrow into the requested direction")
        for index, value in ipairs(art.glyph.texCoords) do assert(art.shadow.texCoords[index] == value) end
    end
    assert(#button.regions == regionCount and button.scripts.OnEnter == enter,
        "restyling circular arrows must reuse regions and hooks")
    assert(button.scripts.OnClick() == "native arrow click")
    namespace.StyleCircularArrowButton(button, "down")
    button.scripts.OnEnter()
    assert(art.glyph.vertexColor[1] == 1.18)
    button.scripts.OnMouseDown()
    assert(art.glyph.vertexColor[1] == 0.8 and art.glyph.points[1][5] == -3)
    button.scripts.OnMouseUp()
    button:SetEnabled(false)
    assert(art.glyph.vertexColor[4] == 0.4 and art.shadow.vertexColor[4] == 0.85 * 0.4)
    button:SetEnabled(true)
    button.scripts.OnLeave()
    assert(art.glyph.vertexColor[1] == 1 and art.glyph.vertexColor[4] == 1)
    button.scripts.OnMouseDown()
    button:SetEnabled(false)
    button:SetEnabled(true)
    assert(not art.pressed and art.glyph.vertexColor[1] == 1,
        "disabling a pressed arrow must clear its transient state")
    button:SetSize(96, 96)
    button.scripts.OnSizeChanged()
    assert(art.glyph.width == 96 and art.glyph.points[1][5] == -6 and art.shadow.points[1][5] == 1.5)
    namespace.StyleCircularArrowButton(button, "left")
    button:SetSize(96, 48)
    button.scripts.OnSizeChanged()
    assert(art.base.width == 48 and art.base.height == 48 and art.glyph.points[1][4] == -3,
        "non-square hit regions must retain a circular visual")
    print("PASS shared circular arrow directions, optical centering, shadow, states, resizing and idempotence")
end
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Core.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Items.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Spells.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Mounts.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Toys.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Skills.lua"))("FFXIV_UI", namespace)
do
    local helpers = namespace.Tooltips
    assert(type(helpers.InitializeItems) == "function" and type(helpers.InitializeSpells) == "function",
        "tooltip layout modules did not load")
    local tooltip = object("Frame")
    tooltip:SetSize(320, 120)
    local left, right = tooltip:CreateFontString(), tooltip:CreateFontString()
    helpers.StyleFont(left, 11, "text")
    helpers.StyleFont(right, 11, "muted")
    left:SetText("Left")
    right:SetText("Right")
    left:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 10, -20)
    left:SetAlpha(0.6)
    right:SetAlpha(0.4)
    left:SetHeight(18)
    right:SetHeight(30)
    local saved = {}
    helpers.SaveNativeRegion(saved, left)
    helpers.SaveNativeRegion(saved, right)
    left:SetAlpha(0)
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 99, -99)
    helpers.SaveNativeRegion(saved, left)
    assert(saved[left].alpha == 0.6 and saved[left].point[4] == 10,
        "repeated native-region capture replaced the original state")
    local zeroAlpha = {}
    helpers.SaveNativeRegion(zeroAlpha, left, 0)
    assert(zeroAlpha[left].alpha == 0, "explicit zero alpha was not preserved")
    helpers.SaveNativeRegion(zeroAlpha, left, 0.8, true)
    assert(zeroAlpha[left].alpha == 0.8, "explicit snapshot replacement failed")
    local skin = {tooltip = tooltip, contentLayout = {}, consumableRows = {}}
    local cursor = helpers.PlaceNativeLine(skin, saved, left, right, -40)
    assert(cursor == -74 and left.alpha == 0.6 and right.alpha == 0.4
        and #skin.contentLayout == 2 and skin.consumableRows[left] and skin.consumableRows[right],
        "item rows lost native alpha, placement, or right-column height")
    assert(helpers.PlaceNativeLine(skin, saved, left, right, -40, 0) == -62
        and left.width == 280, "spell rows changed their height or supplied right-column width")
    local placements = #skin.contentLayout
    helpers.PlaceNativeLine(skin, saved, nil, right, -40, 0)
    assert(#skin.contentLayout == placements + 1 and skin.contentLayout[#skin.contentLayout].region == right,
        "right-only rows created an invalid left-column placement")
end
GameTooltip = object("Frame")
GameTooltip.minWidth = 320
GameTooltip:SetSize(320, 120)
GameTooltip.nativeHeight = 120
GameTooltip.NineSlice = object("Frame", GameTooltip)
local tooltipNativeBorder = GameTooltip.NineSlice:CreateTexture()
local tooltipBody = GameTooltip:CreateFontString()
tooltipBody:SetFont("native", 12)
tooltipBody:SetText("Native tooltip contents")
GameTooltip.TextLeft1 = tooltipBody
tooltipBody:SetPoint("TOPLEFT", GameTooltip, "TOPLEFT", 16, -12)
GameTooltip.TextLeft2 = GameTooltip:CreateFontString()
_G.GameTooltipTextLeft2 = GameTooltip.TextLeft2
GameTooltip.TextLeft2:SetFont("native", 12)
GameTooltip.TextLeft2:SetPoint("TOPLEFT", GameTooltip, "TOPLEFT", 16, -30)
GameTooltip.TextLeft2:SetText("Soulbound")
GameTooltip.TextLeft2:SetTextColor(0.2, 0.8, 1, 1)
local useEffect = GameTooltip:CreateFontString()
useEffect:SetFont("native", 12)
useEffect:SetText("Use: Restores health")
GameTooltip.TextLeft3 = useEffect
_G.GameTooltipTextLeft3 = useEffect
local useEffectRight = GameTooltip:CreateFontString()
useEffectRight:SetFont("native", 12)
useEffectRight:SetText("Right side")
useEffectRight:SetPoint("TOPRIGHT", useEffect, "TOPLEFT")
_G.GameTooltipTextRight3 = useEffectRight
local useDescription = GameTooltip:CreateFontString()
useDescription:SetFont("native", 12)
useDescription:SetText("Restores health")
GameTooltip.TextLeft4 = useDescription
_G.GameTooltipTextLeft4 = useDescription
local flavor = GameTooltip:CreateFontString()
flavor:SetFont("native", 12)
flavor:SetText("A restorative draught")
GameTooltip.TextLeft5 = flavor
_G.GameTooltipTextLeft5 = flavor
local sellPrice = GameTooltip:CreateFontString()
sellPrice:SetFont("native", 12)
sellPrice:SetText("Sell Price: 1 gold")
GameTooltip.TextLeft6 = sellPrice
_G.GameTooltipTextLeft6 = sellPrice
local semanticTooltipColor = {0.2, 0.8, 1, 1}
C_Spell = {
    GetSpellInfo = function(spellID)
        return {name = "Arcane Bolt", spellID = spellID, iconID = 123456,
            castTime = 1500, maxRange = 10, radius = 10}
    end,
    GetSpellPowerCost = function()
        return {{type = Enum.PowerType.Mana, cost = 107, minCost = 107}}
    end,
}
C_Item = {
    GetItemInfo = function()
        return "Healing Potion", "|Hitem:12345|h[Healing Potion]|h", 1, 5, 1,
            "Consumable", "Potion", 20, "", 987654, 100, 0, 0, 0, nil, false, nil,
            "A restorative draught"
    end,
    GetItemCount = function() return 4 end,
    GetItemCooldown = function() error("Recast must not query the current item cooldown") end,
    GetItemSpell = function() return "Healing Potion", 123 end,
    RequestLoadItemDataByID = function() end,
}
local baseCooldown = 90000
GetSpellBaseCooldown = function(spellID)
    assert(spellID == 123 or spellID == 456)
    if spellID == 456 then return 30000, 1500 end
    return baseCooldown
end
SecondsToTimeAbbrev = function(seconds) return "%d s", seconds end
GameTooltip.GetName = function() return "GameTooltip" end
GameTooltip.GetTooltipData = function()
    return {lines = {
        {type = Enum.TooltipDataLineType.ItemName, lineIndex = 1},
        {type = Enum.TooltipDataLineType.ItemBinding, lineIndex = 2},
        {type = Enum.TooltipDataLineType.ItemSpellTriggerOnUse, lineIndex = 3, rightText = "Right side"},
        {type = Enum.TooltipDataLineType.SpellDescription, lineIndex = 4},
        {type = Enum.TooltipDataLineType.FlavorText, lineIndex = 5},
        {type = Enum.TooltipDataLineType.SellPrice, lineIndex = 6},
    }}
end
GameTooltip.GetItem = function() return "Healing Potion", "|Hitem:12345|h[Healing Potion]|h" end
assert(namespace.RoundTooltip(GameTooltip), "available tooltip outline asset was not installed")
local tooltipSkin = assert(namespace.FFXIVUITooltipSkin)
useEffect:SetAlpha(0)
GameTooltip.scripts.OnShow(GameTooltip)
assert(type(itemTooltipPostCall) == "function", "item tooltip post-call was not registered")
itemTooltipPostCall(GameTooltip)
local effectY = useEffect.points[1][5]
GameTooltip.nativeLayout = function(self)
    self.TextLeft1:ClearAllPoints()
    self.TextLeft1:SetPoint("TOPLEFT", self, "TOPLEFT", 16, -12)
    useEffect:ClearAllPoints()
    useEffect:SetPoint("TOPLEFT", self, "TOPLEFT", 16, -60)
end
GameTooltip:Show()
GameTooltip:Show()
assert(useEffect.points[1][5] == effectY and tooltipBody.points[1][4] == 56,
    "native Show layout overwrote custom title and effect anchors")
GameTooltip.nativeLayout = nil
assert(tooltipSkin.itemIcon.texture == 987654 and tooltipSkin.itemIcon.width == 32
    and tooltipBody.points[1][4] == 56 and tooltipBody.points[1][5] == -19
    and tooltipSkin.itemTypeText.text == "Potion" and tooltipSkin.itemCountText.text == "4/20"
    and tooltipSkin.recastHeader.text == "Recast" and tooltipSkin.recastText.text == "90 s"
    and tooltipSkin.effectsHeader.text == "Effects" and GameTooltip.TextLeft2.alpha == 0
    and useEffect.alpha == 1 and useDescription.alpha == 1 and flavor.alpha == 1 and sellPrice.alpha == 0
    and tooltipSkin.sellPriceText.text:find("Sell Price: ", 1, true) and tooltipSkin.sellPriceText.alpha == 1
    and tooltipSkin.itemTypeText.points[1][5] > tooltipSkin.recastHeader.points[1][5]
    and tooltipSkin.recastHeader.points[1][5] > tooltipSkin.recastText.points[1][5]
    and tooltipSkin.recastText.points[1][5] > tooltipSkin.effectsHeader.points[1][5]
    and tooltipSkin.effectsHeader.points[1][5] > useEffect.points[1][5]
    and useEffect.points[1][5] > useDescription.points[1][5]
    and useDescription.points[1][5] > flavor.points[1][5]
    and tooltipSkin.sellPriceText.points[1][2] == flavor and tooltipSkin.sellPriceText.points[1][3] == "BOTTOMLEFT"
    and tooltipSkin.sellPriceText.points[1][1] == "TOPLEFT"    and useEffectRight.points[1][2] == GameTooltip
    and useEffect.points[1][2] == GameTooltip and useEffect.width > 0,
    "consumable tooltip rows did not follow the requested semantic order")
assert(GameTooltip:GetHeight() > GameTooltip.nativeHeight,
    "tooltip height was not restored after Blizzard's Show layout pass")
flavor:SetText(string.rep("A restorative draught brewed from rare herbs. ", 8))
-- Retail reports the pre-wrap size for several frames after wrapping, then settles.
local flavorSettleFrames = 3
local flavorWrapFrame = nil
flavor.GetStringHeight = function(self)
    if not flavorWrapFrame or elapsedFrames - flavorWrapFrame < flavorSettleFrames then return 14 end
    local width = self.width or GameTooltip:GetWidth() - 32
    return math.max(1, math.ceil(#self.text * 6 / width)) * 14
end
flavor.GetBottom = function(self)
    return GameTooltip:GetTop() + self.points[1][5] - self:GetStringHeight()
end
flavorWrapFrame = elapsedFrames
itemTooltipPostCall(GameTooltip)
FlushTimers()
assert(flavor.width == GameTooltip:GetWidth() - 32,
    "flavor text must wrap at the final tooltip width")
assert(GameTooltip:GetHeight() >= -flavor.points[1][5] + flavor:GetStringHeight() + 16,
    "tooltip height must hold the wrapped flavor text at the final width")
GameTooltip:SetWidth(330)
GameTooltip.scripts.OnSizeChanged(GameTooltip, 330, GameTooltip:GetHeight())
assert(flavor.width == GameTooltip:GetWidth() - 32,
    "flavor text must re-wrap when the tooltip width changes after measurement")
assert(GameTooltip:GetHeight() >= -flavor.points[1][5] + flavor:GetStringHeight() + 16,
    "tooltip height must grow to hold flavor text re-wrapped at a narrower width")
GameTooltip:SetWidth(110)
GameTooltip.scripts.OnSizeChanged(GameTooltip, 110, GameTooltip:GetHeight())
assert(GameTooltip:GetWidth() >= 320 and tooltipBody.width == GameTooltip:GetWidth() - 72
    and tooltipSkin.recastText.width == (GameTooltip:GetWidth() - 32) / 3 - 6,
    "late native tooltip resizing must not collapse structured content width")
assert(tooltipBody.width == GameTooltip:GetWidth() - 72 and tooltipBody.wrap
    and tooltipBody.height == 32 and tooltipBody.justifyV == "MIDDLE"
    and tooltipSkin.bindingLabel.text == "Soulbound" and tooltipSkin.bindingLabel.justify == "CENTER"
    and tooltipSkin.bindingLabel.points[1][4] == 56 and tooltipSkin.bindingLabel.points[1][5] == -5
    and tooltipSkin.bindingLabel.width == tooltipBody.width,
    "binding tags must be centered above the name between the icon and right frame inset")
assert(tooltipSkin.recastHeader.width == (GameTooltip:GetWidth() - 32) / 3 - 6
    and tooltipSkin.recastHeader.points[1][4] == 16
    and tooltipSkin.recastHeader.points[1][5] - tooltipSkin.recastText.points[1][5] == 13,
    "recast does not use a compact first-third cell")
assert(#tooltipSkin.recastDivider == 3 and tooltipSkin.recastDivider[1].height == 5
    and tooltipSkin.recastDivider[3].width == 2.5
    and tooltipSkin.recastDivider[1].mask and tooltipSkin.recastDivider[3].mask
    and tooltipSkin.recastDivider[1].color[1] == 0.32
    and tooltipSkin.recastHeader.justify == "RIGHT" and tooltipSkin.recastText.justify == "RIGHT"
    and tooltipSkin.recastHeader.font[2] == 11 and tooltipSkin.recastText.font[2] == 16,
    "recast underline does not have fixed rounded caps")
local bar = tooltipSkin.recastDivider
assert(bar[1].points[1][4] + bar[1].width > bar[2].points[1][4]
    and bar[2].points[1][4] + bar[2].width > bar[3].points[1][4],
    "recast underline caps must overlap the center to prevent seams")
baseCooldown = 0
itemTooltipPostCall(GameTooltip)
assert(tooltipSkin.recastText.text == "0 s", "confirmed zero base cooldown must display zero")
baseCooldown = secretStatText
itemTooltipPostCall(GameTooltip)
assert(tooltipSkin.recastText.text == "--", "secret base cooldown must remain unknown")
local baseCooldownLookup = GetSpellBaseCooldown
GetSpellBaseCooldown = nil
itemTooltipPostCall(GameTooltip)
assert(tooltipSkin.recastText.text == "--", "unavailable base cooldown API must remain unknown")
GetSpellBaseCooldown = baseCooldownLookup
baseCooldown = 90000
itemTooltipPostCall(GameTooltip)
local originalItemInfo = C_Item.GetItemInfo
local originalHearthstoneGetItem = GameTooltip.GetItem
GameTooltip.GetItem = function() return "Hearthstone", "|Hitem:6948|h[Hearthstone]|h" end
baseCooldown = 0
C_Item.GetItemInfo = function()
    return "Hearthstone", "|Hitem:6948|h[Hearthstone]|h", 1, 1, 1,
        "Miscellaneous", "Junk", 1, "INVTYPE_NON_EQUIP_IGNORE", 134414, 0, 15
end
itemTooltipPostCall(GameTooltip)
assert(tooltipSkin.itemTypeText.text == "Junk" and tooltipSkin.itemCountText.text == "4/1"
    and tooltipSkin.effectsHeader:IsShown() and tooltipSkin.recastText.text == "1800 s"
    and useEffect.points[1][5] < tooltipSkin.effectsHeader.points[1][5],
    "Hearthstone INVTYPE_NON_EQUIP_IGNORE must receive the structured effects/recast layout")
local originalItemSpell = C_Item.GetItemSpell
C_Item.GetItemSpell = function() return nil end
C_Item.GetItemInfo = function()
    return "Hearthstone", "|Hitem:6948|h[Hearthstone]|h", 1, 1, 1,
        "Miscellaneous", "Junk", 1, nil, 134414, 0, 15
end
itemTooltipPostCall(GameTooltip)
assert(tooltipSkin.effectsHeader:IsShown() and tooltipSkin.itemTypeText:IsShown()
    and tooltipSkin.recastText.text == "1800 s",
    "typed use effects must enable Hearthstone layout without cached spell or equipment location")
local originalTooltipData = GameTooltip.GetTooltipData
local originalUsePrefix = ITEM_SPELL_TRIGGER_ONUSE
ITEM_SPELL_TRIGGER_ONUSE = "Use:"
GameTooltip.GetTooltipData = function()
    return {lines = {
        {type = Enum.TooltipDataLineType.ItemName, lineIndex = 1},
        {type = Enum.TooltipDataLineType.ItemBinding, lineIndex = 2},
        {type = 0, lineIndex = 3, leftText = "Use: Returns you home"},
    }}
end
itemTooltipPostCall(GameTooltip)
assert(tooltipSkin.effectsHeader:IsShown() and tooltipSkin.itemCountText:IsShown()
    and tooltipSkin.recastText:IsShown() and tooltipSkin.consumableText ~= nil
    and useEffect.points[1][5] < tooltipSkin.effectsHeader.points[1][5],
    "generic Hearthstone use lines must receive the complete structured layout")
GameTooltip.GetTooltipData = originalTooltipData
ITEM_SPELL_TRIGGER_ONUSE = "Use:"
C_Item.GetItemInfo = function()
    return "Decor Chair", "|Hitem:13579|h[Decor Chair]|h", 1, 1, 1,
        "Miscellaneous", "Miscellaneous", 1, "", 134414, 0, 1
end
local nativeText = "|A:housing-item-icon:14:14|a 3"
GameTooltip.TextRight1 = {
    shown = true,
    GetText = function() return nativeText end,
    Hide = function(self) self.shown = false end,
    Show = function(self) self.shown = true end,
}
C_HousingCatalog = {GetCatalogEntryInfoByItem = function()
    return {totalNumStored = 2, totalNumPlaced = 1}
end}
GameTooltip.GetTooltipData = function()
    return {lines = {
        {type = Enum.TooltipDataLineType.ItemName, lineIndex = 1},
        {type = Enum.TooltipDataLineType.None, lineIndex = 2, leftText = "Housing Decor"},
        {type = 0, lineIndex = 3, leftText = "Use: Place in your house"},
    }}
end
itemTooltipPostCall(GameTooltip)
local housingIcon = tooltipSkin.housingIcon
assert(housingIcon and housingIcon:IsShown() and housingIcon.mask ~= nil and housingIcon.points[1][4] == -16
    and housingIcon.points[1][5] == -48 + -8 - 1,
    "housing decor must draw the masked house icon in the count slot")
assert(tooltipSkin.itemCountText:IsShown() and tooltipSkin.itemCountText.text == "3",
    "housing decor must show the owned count (stored + placed) beside the icon")
assert(GameTooltip.TextRight1.shown == false, "the native house line must be hidden for housing decor")
C_HousingCatalog = nil
GameTooltip.GetTooltipData = function()
    return {lines = {
        {type = Enum.TooltipDataLineType.ItemName, lineIndex = 1},
        {type = Enum.TooltipDataLineType.None, lineIndex = 2, leftText = "Miscellaneous"},
        {type = 0, lineIndex = 3, leftText = "Use: Returns you home"},
    }}
end
itemTooltipPostCall(GameTooltip)
assert(not housingIcon:IsShown(), "the house icon must hide for non-housing items")
assert(GameTooltip.TextRight1.shown == true, "the native right text must be restored for non-housing items")
assert(tooltipSkin.itemCountText.text == "4/1",
    "non-housing items must use the owned/max count")
ITEM_SPELL_TRIGGER_ONUSE = originalUsePrefix
GameTooltip.GetTooltipData = originalTooltipData
C_Item.GetItemInfo = function()
    return "Usable Trinket", "|Hitem:12345|h[Usable Trinket]|h", 1, 1, 1,
        "Armor", "Miscellaneous", 1, "INVTYPE_TRINKET", 134414, 0, 4
end
itemTooltipPostCall(GameTooltip)
assert(not tooltipSkin.effectsHeader:IsShown() and not tooltipSkin.recastText:IsShown()
    and tooltipSkin.consumableText ~= nil and #tooltipSkin.equipmentRegions > 0,
    "equippable on-use items must use the equipment renderer without consumable recast rows")
local recipeTexts = {GameTooltip.TextLeft2.text, GameTooltip.TextLeft3.text, GameTooltip.TextLeft4.text,
    GameTooltip.TextLeft5.text, GameTooltip.TextLeft6.text}
C_Item.GetItemInfo = function()
    return "Fillet of Frenzy Recipe", "|Hitem:34567|h[Recipe]|h", 1, 1, 5,
        "Recipe", "Cooking", 1, "", 134414, 0, Enum.ItemClass.Recipe
end
GameTooltip.TextLeft2:SetText("Fillet of Frenzy")
GameTooltip.TextLeft3:SetText("Use: Teaches you how to cook a Fillet of Frenzy")
GameTooltip.TextLeft4:SetText("Requires Level 5")
GameTooltip.TextLeft5:SetText("Soft Frenzy Flesh, Mild Spices")
GameTooltip.TextLeft6:SetText("Requires Cooking (50)")
GameTooltip.GetTooltipData = function()
    return {lines = {
        {type = Enum.TooltipDataLineType.None, lineIndex = 1},
        {type = Enum.TooltipDataLineType.ItemName, lineIndex = 2},
        {type = Enum.TooltipDataLineType.ItemSpellTriggerOnUse, lineIndex = 3},
        {type = Enum.TooltipDataLineType.UsageRequirement, lineIndex = 4},
        {type = Enum.TooltipDataLineType.None, lineIndex = 5},
        {type = Enum.TooltipDataLineType.UsageRequirement, lineIndex = 6},
    }}
end
itemTooltipPostCall(GameTooltip)
assert(GameTooltip.TextLeft1.alpha == 1 and GameTooltip.TextLeft5.shown ~= false and GameTooltip.TextLeft5.alpha == 1
    and GameTooltip.TextLeft6.alpha == 1 and GameTooltip.TextLeft2.alpha == 0,
    "recipe title must stay visible, reagent and requirement rows must be shown, and the repeated name row must stay hidden")
assert(GameTooltip.TextLeft3.points[1][5] > GameTooltip.TextLeft5.points[1][5]
    and GameTooltip.TextLeft5.points[1][5] > GameTooltip.TextLeft6.points[1][5],
    "recipe reagent and requirement rows must follow the use line in order")
GameTooltip.TextLeft2:SetText(recipeTexts[1])
GameTooltip.TextLeft3:SetText(recipeTexts[2])
GameTooltip.TextLeft4:SetText(recipeTexts[3])
GameTooltip.TextLeft5:SetText(recipeTexts[4])
GameTooltip.TextLeft6:SetText(recipeTexts[5])
GameTooltip:SetWidth(110)
GameTooltip.scripts.OnSizeChanged(GameTooltip, 110, GameTooltip:GetHeight())
assert(GameTooltip:GetWidth() >= 320 and tooltipBody.width == GameTooltip:GetWidth() - 72
    and tooltipSkin.consumableText ~= nil,
    "equipment tooltip headers must resist native width collapse")
local equipmentTooltip = object("Frame")
equipmentTooltip:SetSize(360, 180)
local equipmentMoney = object("Frame", equipmentTooltip)
_G.EquipmentTooltipMoneyFrame1 = equipmentMoney
local originalMoneyString, originalSellLabel = GetMoneyString, SELL_PRICE
GetMoneyString = function(value) assert(value == 100); return "1 gold" end
SELL_PRICE = "Sell Price"
equipmentTooltip.GetName = function() return "EquipmentTooltip" end
equipmentTooltip.GetItem = function() return "Equipment", "|Hitem:23456|h[Equipment]|h" end
local equipmentLines = {}
equipmentTooltip.GetTooltipData = function() return {lines = equipmentLines} end
local originalArmorTemplate, originalDamageTemplate, originalDPSTemplate = ARMOR_TEMPLATE, DAMAGE_TEMPLATE, DPS_TEMPLATE
ARMOR_TEMPLATE, DAMAGE_TEMPLATE = "%s Armor", "%s - %s Damage"
DPS_TEMPLATE = "(%.1f damage per second)"
local equipmentLocation = "INVTYPE_CHEST"
local equipmentBindingText = "Soulbound"
C_Item.GetItemInfo = function()
    return "Equipment", "|Hitem:23456|h[Equipment]|h", 3, 20, 10,
        "Armor", "Cloth", 1, equipmentLocation, 134414, 100, 4
end
local function EquipmentFixture(metric, right, bonus)
    equipmentLines = {}
    local entries = {
        {Enum.TooltipDataLineType.ItemName, "Equipment"},
        {Enum.TooltipDataLineType.EquipSlot, "Chest", "Cloth"},
        {0, metric, right},
        {Enum.TooltipDataLineType.ItemLevel, "Item Level 20"},
        {Enum.TooltipDataLineType.UsageRequirement, "Requires Level 10"},
        {0, bonus}, {0, "+5 Stamina"},
        {0, "Durability 40 / 45"},
        {0, "Durability 40 / 45"},
        {Enum.TooltipDataLineType.SellPrice, "Sell Price: 1 gold"},
    }
    if equipmentBindingText then entries[#entries + 1] = {Enum.TooltipDataLineType.ItemBinding, equipmentBindingText} end
    if right then entries[#entries + 1] = {0, "(5.8 damage per second)"} end
    for index, entry in ipairs(entries) do
        local left = equipmentTooltip["TextLeft" .. index]
        if not left then
            left = equipmentTooltip:CreateFontString()
            left:SetFont("native", 12)
            equipmentTooltip["TextLeft" .. index] = left
            _G["EquipmentTooltipTextLeft" .. index] = left
        end
        left:ClearAllPoints()
        left:SetPoint("TOPLEFT", equipmentTooltip, "TOPLEFT", 16, -12 - (index - 1) * 16)
        left:SetText(entry[2])
        left:SetTextColor(0.1, 1, 0.1, 1)
        left.GetTextColor = function(self)
            return self.color[1], self.color[2], self.color[3], self.alpha
        end
        local rightRegion = equipmentTooltip["TextRight" .. index]
        if entry[3] or rightRegion then
            if not rightRegion then
                rightRegion = equipmentTooltip:CreateFontString()
                rightRegion:SetFont("native", 12)
                equipmentTooltip["TextRight" .. index] = rightRegion
                _G["EquipmentTooltipTextRight" .. index] = rightRegion
            end
            rightRegion:SetText(entry[3] or "")
        end
        equipmentLines[index] = {type = entry[1], lineIndex = index}
    end
end
EquipmentFixture("12 Armor", nil, "+3 Intellect")
assert(namespace.RoundTooltip(equipmentTooltip))
itemTooltipPostCall(equipmentTooltip)
local equipmentSkin = namespace.FFXIVUITooltipSkins[equipmentTooltip]
local function EquipmentLabel(text)
    for _, region in ipairs(equipmentSkin.equipmentRegions) do
        if region:IsShown() and region:GetText() == text then return region end
    end
end
assert(EquipmentLabel("Chest - Cloth") and EquipmentLabel("Defense")
    and EquipmentLabel("12") and EquipmentLabel("Bonuses")
    and EquipmentLabel("Item Level 20") and EquipmentLabel("Requires Level 10")
    and EquipmentLabel("Durability 40 / 45") and EquipmentLabel("Sell Price: 1 gold"),
    "armor tooltip is missing reference-style sections or native information")
assert(EquipmentLabel("+3 Intellect").color[2] == 1
    and EquipmentLabel("+3 Intellect").color[4] == 1
    and EquipmentLabel("+3 Intellect").alpha == 1
    and EquipmentLabel("12").color[4] == 1 and EquipmentLabel("Item Level 20").color[4] == 1
    and EquipmentLabel("+3 Intellect").points[1][5] == EquipmentLabel("+5 Stamina").points[1][5]
    and equipmentTooltip.TextLeft6.alpha == 0,
    "equipment bonuses must keep native colors and use a two-column row")
assert(not EquipmentLabel("4") and EquipmentLabel("Chest - Cloth").width == equipmentTooltip:GetWidth() - 32,
    "equipment tooltips must omit the owned count and give the type row full width")
assert(equipmentSkin.bindingLabel.text == "Soulbound" and not EquipmentLabel("Soulbound")
    and equipmentSkin.bindingLabel.justify == "CENTER" and equipmentTooltip.TextLeft11.alpha == 0,
    "equipment binding tags must appear only in the centered header")
equipmentTooltip.TextLeft11:SetAlpha(1)
assert(equipmentTooltip.TextLeft11.alpha == 0, "native binding text must stay hidden after alpha refresh")
assert(EquipmentLabel("Defense").points[1][5] > EquipmentLabel("Item Level 20").points[1][5]
    and EquipmentLabel("Item Level 20").points[1][5] > EquipmentLabel("Bonuses").points[1][5],
    "equipment metric, level, and bonus sections are out of order")
assert(EquipmentLabel("Defense").points[1][4] == 16 + 2 * (360 - 32) / 3
    and EquipmentLabel("12").justify == "RIGHT"
    and EquipmentLabel("12").width == (360 - 32) / 3 - 8
    and #equipmentSkin.equipmentBars[1] == 3 and equipmentSkin.equipmentBars[1][1].mask,
    "a single equipment metric must use the rightmost third with a rounded underline")
local durabilityCount = 0
for _, label in ipairs(equipmentSkin.equipmentRegions) do
    if label:IsShown() and label:GetText() == "Durability 40 / 45" then durabilityCount = durabilityCount + 1 end
end
assert(durabilityCount == 1 and equipmentMoney.alpha == 0
    and equipmentTooltip.TextLeft8.alpha == 0 and equipmentTooltip.TextLeft9.alpha == 0
    and equipmentTooltip.TextLeft10.alpha == 0,
    "durability must not be copied from money data and native money widgets must stay hidden")
assert(equipmentTooltip.TextLeft10.alpha == 0,
    "the native money post-call text line must be hidden alongside money frame widgets")
equipmentTooltip.TextLeft8:SetAlpha(1)
equipmentMoney:SetAlpha(1)
assert(equipmentTooltip.TextLeft8.alpha == 0 and equipmentMoney.alpha == 0,
    "native alpha setters must not resurrect replaced equipment rows or money widgets")
equipmentTooltip:SetSize(110, 90)
equipmentTooltip:Show()
assert(equipmentTooltip:GetWidth() >= 360 and equipmentTooltip:GetHeight() >= equipmentSkin.targetHeight
    and equipmentTooltip.TextLeft8.alpha == 0 and equipmentMoney.alpha == 0,
    "late native resizing or visibility refresh must not collapse or duplicate equipment content")
EquipmentFixture("12 Armor", nil, "+3 Intellect")
equipmentTooltip.TextRight2:SetTextColor(1, 0.125, 0.125, 1)
itemTooltipPostCall(equipmentTooltip)
assert(EquipmentLabel("Chest - |cffff2020Cloth|r") and not EquipmentLabel("Chest - Cloth"),
    "an armor type the character cannot equip must render only its type text red")
EquipmentFixture("12 Armor", nil, "+3 Intellect")
equipmentTooltip.TextRight2:SetTextColor(0.1, 1, 0.1, 1)
equipmentTooltip.TextLeft2:SetTextColor(1, 0.125, 0.125, 1)
itemTooltipPostCall(equipmentTooltip)
assert(EquipmentLabel("Chest - Cloth").color[1] == 1 and EquipmentLabel("Chest - Cloth").color[2] == 0.125
    and EquipmentLabel("Chest - Cloth").color[3] == 0.125,
    "a red native slot line must render its type text red")
EquipmentFixture("12 Armor", nil, "+3 Intellect")
equipmentTooltip.TextRight2:SetTextColor(0.1, 1, 0.1, 1)
equipmentTooltip.TextLeft2:SetTextColor(0.1, 1, 0.1, 1)
itemTooltipPostCall(equipmentTooltip)
assert(EquipmentLabel("Chest - Cloth") and EquipmentLabel("Chest - Cloth").color[2] ~= 0.125,
    "an armor type the character can equip must not render its type text red")
equipmentLocation = "INVTYPE_WEAPON"
EquipmentFixture("10 - 20 Damage", "Speed 2.60", "+4 Intellect")
itemTooltipPostCall(equipmentTooltip)
assert(EquipmentLabel("Damage") and EquipmentLabel("10 - 20") and EquipmentLabel("Speed")
    and EquipmentLabel("2.60") and EquipmentLabel("DPS") and EquipmentLabel("5.8")
    and not EquipmentLabel("(5.8 damage per second)") and EquipmentLabel("+4 Intellect")
    and EquipmentLabel("Damage").points[1][4] == 16
    and EquipmentLabel("DPS").points[1][4] == 16 + (360 - 32) / 3
    and EquipmentLabel("Speed").points[1][4] == 16 + 2 * (360 - 32) / 3,
    "caster weapons must retain their native damage, speed, and intellect")
equipmentLocation = "INVTYPE_CHEST"
EquipmentFixture("12 Armor", nil, "+3 Intellect")
itemTooltipPostCall(equipmentTooltip)
assert(EquipmentLabel("Defense") and equipmentSkin.equipmentBars[1][1]:IsShown()
    and not equipmentSkin.equipmentBars[2][1]:IsShown() and not equipmentSkin.equipmentBars[3][1]:IsShown(),
    "a single armor metric after a weapon must hide the stale weapon underlines")
local comparedLeft = equipmentTooltip:CreateFontString()
comparedLeft:SetFont("native", 12)
comparedLeft:SetText("Stamina: +5 (+2)")
comparedLeft:SetTextColor(0.1, 1, 0.1, 1)
comparedLeft.GetTextColor = function(self) return self.color[1], self.color[2], self.color[3], self.alpha end
equipmentTooltip.TextLeft12 = comparedLeft
_G["EquipmentTooltipTextLeft12"] = comparedLeft
local emptyCompareLeft = equipmentTooltip:CreateFontString()
emptyCompareLeft:SetFont("native", 12)
emptyCompareLeft:SetText("")
emptyCompareLeft:SetTextColor(0.1, 1, 0.1, 1)
emptyCompareLeft.GetTextColor = function(self) return self.color[1], self.color[2], self.color[3], self.alpha end
equipmentTooltip.TextLeft13 = emptyCompareLeft
_G["EquipmentTooltipTextLeft13"] = emptyCompareLeft
equipmentTooltip.NumLines = function() return 13 end
itemTooltipPostCall(equipmentTooltip)
assert(EquipmentLabel("Stamina: +5 (+2)") and EquipmentLabel("Stamina: +5 (+2)").color[2] == 1
    and comparedLeft.alpha == 0
    and EquipmentLabel("Stamina: +5 (+2)").points[1][5] < EquipmentLabel("+3 Intellect").points[1][5],
    "comparison rows must render below the stats with native text hidden")
equipmentTooltip.NumLines = nil
equipmentLocation = "INVTYPE_WEAPON"

EquipmentFixture("20 - 30 Damage", "Speed 3.20", "+4 Strength")
equipmentTooltip.TextLeft11:SetText("Warbound")
itemTooltipPostCall(equipmentTooltip)
assert(equipmentSkin.bindingLabel.text == "Warbound" and not EquipmentLabel("Warbound"),
    "Warbound must use the same header placement without duplicating a body row")
assert(EquipmentLabel("20 - 30") and EquipmentLabel("+4 Strength")
    and not EquipmentLabel("+4 Intellect"), "weapon switching retained stale equipment text")
equipmentBindingText = nil
EquipmentFixture("20 - 30 Damage", "Speed 3.20", "+4 Strength")
itemTooltipPostCall(equipmentTooltip)
assert(not equipmentSkin.bindingLabel:IsShown() and equipmentTooltip.TextLeft1.points[1][5] == -19,
    "switching to an unbound item must hide the tag line and keep the name in the reserved binding row")
equipmentTooltip:Hide()
assert(equipmentTooltip.TextLeft6.alpha == 1 and not EquipmentLabel("Bonuses"),
    "equipment tooltip hide must restore native rows and hide custom sections")
assert(equipmentMoney.alpha == 1 and not equipmentSkin.equipmentBars[1][1]:IsShown(),
    "equipment tooltip cleanup must restore money widgets and hide metric underlines")
do
    equipmentLocation = "INVTYPE_CHEST"
    EquipmentFixture("12 Armor", nil, "+3 Intellect")
    local nativeGem = equipmentTooltip:CreateTexture(nil, "BACKGROUND")
    nativeGem:SetTexture(463466)
    nativeGem:SetSize(12, 12)
    nativeGem:SetPoint("TOPRIGHT", equipmentTooltip.TextLeft7, "TOPLEFT", -8, 0)
    equipmentTooltip:Show()
    itemTooltipPostCall(equipmentTooltip)
    local gemSkin = namespace.FFXIVUITooltipSkins[equipmentTooltip]
    local gemIcon = gemSkin.equipmentSocketIcons[1]
    assert(nativeGem.alpha == 0 and gemIcon ~= nil and gemIcon:IsShown() and gemIcon.texture == 463466,
        "the native gem texture must be hidden and replaced by a custom icon with the same art")
    assert(gemIcon.points[1][4] == 22 + (360 - 32) / 2 and EquipmentLabel("+5 Stamina").points[1][4] == gemIcon.points[1][4] + 16,
        "the gem bonus must sit after its icon in the right column, with the rest of the bonus grid unchanged")
    assert(EquipmentLabel("+3 Intellect").points[1][4] == 16,
        "non-socket bonuses must not shift")
    equipmentTooltip:Hide()
    assert(nativeGem.alpha == 1 and not gemIcon:IsShown(),
        "hiding the equipment tooltip must restore the native gem texture and hide the custom icon")
end
GetMoneyString, SELL_PRICE = originalMoneyString, originalSellLabel
_G.EquipmentTooltipMoneyFrame1 = nil
ARMOR_TEMPLATE, DAMAGE_TEMPLATE = originalArmorTemplate, originalDamageTemplate
DPS_TEMPLATE = originalDPSTemplate
C_Item.GetItemSpell = originalItemSpell
C_Item.GetItemInfo = originalItemInfo
GameTooltip.GetItem = originalHearthstoneGetItem
baseCooldown = 90000
itemTooltipPostCall(GameTooltip)
do
    GameTooltip:SetHeight(900)
    itemTooltipPostCall(GameTooltip)
    assert(GameTooltip:GetHeight() < 900 and tooltipSkin.fitMinimum == 0,
        "usable item tooltips must shrink from a previous tall action-bar tooltip")
    local compactHeight = GameTooltip:GetHeight()
    itemTooltipPostCall(GameTooltip)
    assert(GameTooltip:GetHeight() == compactHeight,
        "repeated usable-item formatting must not restore a previous tall height")
end
do
    local function SpecializedTooltip(kind)
        local tooltip = object("Frame")
        tooltip:SetSize(420, 900)
        local tooltipName = "Reusable" .. kind .. "Tooltip"
        local tooltipType = Enum.TooltipDataType[kind]
        local description = string.rep("Native description of this collectible. ", 18)
        tooltip.GetName = function() return tooltipName end
        tooltip.IsTooltipType = function(_, value) return value == tooltipType end
        local lines = {
            {type = Enum.TooltipDataLineType.SpellName, lineIndex = 1, leftText = "Collectible " .. kind},
            {type = Enum.TooltipDataLineType.None, lineIndex = 2, leftText = kind},
            {type = Enum.TooltipDataLineType.FlavorText, lineIndex = 3, leftText = description},
        }
        tooltip.GetTooltipData = function() return {type = tooltipType, lines = lines} end
        local createFontString = tooltip.CreateFontString
        function tooltip:CreateFontString(...)
            local region = createFontString(self, ...)
            function region:GetStringHeight()
                if self.height and self.height > 0 then return self.height end
                local width = self.width or tooltip:GetWidth() - 32
                local naturalWidth = type(self.text) == "string" and #self.text * self.font[2] * 0.5 or 0
                local count = self.wrap and math.ceil(naturalWidth / width) or 1
                return math.max(1, count) * self.font[2]
            end
            return region
        end
        for index, line in ipairs(lines) do
            local region = tooltip:CreateFontString()
            region:SetFont("native", 12)
            region:SetText(line.leftText)
            region:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 12, -index * 14)
            tooltip["TextLeft" .. index] = region
            _G[tooltipName .. "TextLeft" .. index] = region
        end
        assert(namespace.RoundTooltip(tooltip))
        local refresh = assert(tooltipPostCalls[tooltipType])
        refresh(tooltip)
        local skin = namespace.FFXIVUITooltipSkins[tooltip]
        assert(tooltip:GetHeight() < 900 and skin.fitMinimum == 0,
            kind .. " tooltip must not keep the previous native height minimum")
        local longHeight = tooltip:GetHeight()
        tooltip.TextLeft3:SetText("A short description.")
        lines[3].leftText = "A short description."
        refresh(tooltip)
        local shortHeight = tooltip:GetHeight()
        assert(shortHeight < longHeight and skin.itemDescription.text == "A short description.",
            kind .. " tooltip must shrink when switching from a long description to a shorter one")
        assert(shortHeight >= -skin.itemDescription.points[1][5] + skin.itemDescription:GetStringHeight() + 14,
            kind .. " tooltip must retain bottom padding around its current description")
        refresh(tooltip)
        assert(tooltip:GetHeight() == shortHeight,
            kind .. " tooltip must not accumulate height on repeated refreshes")
    end
    SpecializedTooltip("Mount")
    SpecializedTooltip("Toy")
end
print("PASS usable-item, mount and toy tooltips shrink to current content without retained-height growth")
do
    local originalMountJournal, originalItemIcon = C_MountJournal, C_Item.GetItemIconByID
    local originalItemSpellFn, originalSpellInfoFn = C_Item.GetItemSpell, C_Spell.GetSpellInfo
    local originalMinLevel = ITEM_MIN_LEVEL
    ITEM_MIN_LEVEL = "Requires Level %d"
    local function ProbeTooltip(name, kind, id, lines)
        local tooltip = object("Frame")
        tooltip:SetSize(420, 900)
        tooltip.GetName = function() return name end
        tooltip.IsTooltipType = function(_, value) return value == Enum.TooltipDataType[kind] end
        tooltip.GetTooltipData = function() return {type = Enum.TooltipDataType[kind], id = id, lines = lines} end
        for index, line in ipairs(lines) do
            local region = tooltip:CreateFontString()
            region:SetFont("native", 12)
            region:SetText(line.leftText)
            region:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 12, -index * 14)
            tooltip["TextLeft" .. index] = region
            _G[name .. "TextLeft" .. index] = region
        end
        assert(namespace.RoundTooltip(tooltip))
        return tooltip, assert(tooltipPostCalls[Enum.TooltipDataType[kind]]), namespace.FFXIVUITooltipSkins[tooltip]
    end

    C_MountJournal = {GetMountInfoByID = function(id)
        assert(id == 4242, "mount tooltip must look up its mount ID")
        return "Test Mount", 67890, 555001
    end}
    local mountTooltip, refreshMount, mountSkin = ProbeTooltip("MountLayoutProbeTooltip", "Mount", 4242, {
        {type = Enum.TooltipDataLineType.SpellName, lineIndex = 1, leftText = "Test Mount"},
        {type = Enum.TooltipDataLineType.None, lineIndex = 2, leftText = "Mount"},
        {type = Enum.TooltipDataLineType.None, lineIndex = 3, leftText = "1.5 sec cast"},
        {type = Enum.TooltipDataLineType.None, lineIndex = 4, leftText = "Native mount description."},
    })
    refreshMount(mountTooltip)
    assert(mountSkin.itemIcon.texture == 555001 and mountSkin.itemIcon:IsShown(),
        "mount header must use the mount journal icon")
    assert(mountSkin.spellCastHeader.text == "Cast" and mountSkin.spellCastValue.text == "1.50s",
        "mount Cast cell must come from the native cast line")
    assert(not (mountSkin.spellCooldownHeader and mountSkin.spellCooldownHeader:IsShown())
        and not (mountSkin.spellCostHeader and mountSkin.spellCostHeader:IsShown()),
        "mounts must not show a Recast or resource cell")
    assert(mountSkin.itemTypeText.text == "Mount" and mountSkin.itemDescription.text == "Native mount description.",
        "mount category and native description must be kept")

    local originalBaseCooldown = GetSpellBaseCooldown
    GetSpellBaseCooldown = function(spellID)
        assert(spellID == 8888, "toy cooldown must query the toy's associated spell")
        return nil, 0
    end
    C_Item.GetItemIconByID = function(id) return id == 7777 and 666002 or nil end
    C_Item.GetItemSpell = function() return "Toy Effect", 8888 end
    C_Spell.GetSpellInfo = function(spellID)
        assert(spellID == 8888, "toy Cast must come from the item's associated spell")
        return {name = "Toy Effect", castTime = 1500}
    end
    local toyTooltip, refreshToy, toySkin = ProbeTooltip("ToyLayoutProbeTooltip", "Toy", 7777, {
        {type = Enum.TooltipDataLineType.SpellName, lineIndex = 1, leftText = "Test Toy"},
        {type = Enum.TooltipDataLineType.None, lineIndex = 2, leftText = "Toy"},
        {type = Enum.TooltipDataLineType.None, lineIndex = 3, leftText = "Native toy effect."},
        {type = Enum.TooltipDataLineType.None, lineIndex = 4, leftText = "Requires Level 60"},
    })
    refreshToy(toyTooltip)
    assert(toySkin.itemIcon.texture == 666002 and toySkin.itemIcon:IsShown(),
        "toy header must use the item icon")
    assert(toySkin.spellCastHeader.text == "Cast" and toySkin.spellCastValue.text == "1.50s"
        and toySkin.spellCooldownHeader.text == "Recast" and toySkin.spellCooldownValue.text == "--",
        "toy Cast and Recast cells must use the associated spell, with -- for a missing cooldown")
    assert(toySkin.toyRequirement.text == "Requires Level 60"
        and toySkin.itemDescription.text == "Native toy effect.",
        "toy level requirement must be separated from the native description")

    C_MountJournal, C_Item.GetItemIconByID = originalMountJournal, originalItemIcon
    C_Item.GetItemSpell, C_Spell.GetSpellInfo = originalItemSpellFn, originalSpellInfoFn
    GetSpellBaseCooldown = originalBaseCooldown
    ITEM_MIN_LEVEL = originalMinLevel
end
print("PASS mount and toy layouts use journal icons, Cast/Recast cells, and separated requirements")
do
    local currencyTooltip = object("Frame")
    currencyTooltip:SetSize(340, 140)
    currencyTooltip.GetName = function() return "CurrencyTestTooltip" end
    local currencyID = 3008
    local currencyLines = {}
    for index, text in ipairs({"Trader's Tender", "Warband Currency",
        "Trader's Tender is exchanged for goods with the Trading Post.", "Total: 2,010"}) do
        local region = currencyTooltip:CreateFontString()
        region:SetFont("native", 12)
        region:SetText(text)
        region:SetPoint("TOPLEFT", currencyTooltip, "TOPLEFT", 12, -index * 14)
        currencyTooltip["TextLeft" .. index] = region
        _G["CurrencyTestTooltipTextLeft" .. index] = region
        currencyLines[index] = {lineIndex = index, leftText = text}
    end
    local currencyLineCount = #currencyLines
    currencyTooltip.NumLines = function() return currencyLineCount end
    function currencyTooltip:AddLine(text, red, green, blue)
        currencyLineCount = currencyLineCount + 1
        local region = self:CreateFontString()
        region:SetFont("native", 12)
        region:SetText(text)
        region:SetTextColor(red or 1, green or 1, blue or 1, 1)
        region:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -currencyLineCount * 14)
        self["TextLeft" .. currencyLineCount] = region
        _G["CurrencyTestTooltipTextLeft" .. currencyLineCount] = region
    end
    currencyTooltip.TextLeft2:SetTextColor(0, 0.8, 1, 1)
    currencyTooltip.GetTooltipData = function()
        return {type = Enum.TooltipDataType.Currency, id = currencyID, lines = currencyLines}
    end
    local originalCurrencyInfo, originalItemInfo = C_CurrencyInfo, C_Item.GetItemInfo
    C_CurrencyInfo = {GetCurrencyInfo = function(id)
        assert(id == currencyID)
        return {iconFileID = id == 3008 and 463446 or 777001}
    end}
    C_Item.GetItemInfo = function() error("currency IDs must never be looked up as item IDs") end
    assert(namespace.RoundTooltip(currencyTooltip))
    currencyTooltip.scripts.OnShow(currencyTooltip)
    local currencySkin = namespace.FFXIVUITooltipSkins[currencyTooltip]
    local updateCurrency = assert(tooltipPostCalls[Enum.TooltipDataType.Currency])
    updateCurrency(currencyTooltip)
    itemTooltipPostCall(currencyTooltip)
    assert(currencySkin.itemIcon.texture == 463446 and currencySkin.itemIcon:IsShown(),
        "currency header must use the currency icon rather than an item with the same ID")
    assert(currencyTooltip.TextLeft1.points[1][4] == 56
        and currencyTooltip.TextLeft2.points[1][4] == 16
        and currencyTooltip.TextLeft2.points[1][5] <= -54,
        "currency title must sit beside its icon with native details below the header")
    assert(currencyTooltip.TextLeft2.text == "Warband Currency"
        and currencyTooltip.TextLeft2.color[2] == 0.8
        and currencyTooltip.TextLeft4.text == "Total: 2,010"
        and not currencySkin.itemTypeText,
        "currency styling must retain native labels, colors and totals without item categories")
    local previousHeight = currencyTooltip.height
    updateCurrency(currencyTooltip)
    assert(currencyTooltip.height == previousHeight, "currency refresh grew the tooltip")
    currencyTooltip:AddLine(" ")
    currencyTooltip:AddLine("<Click to view options>", 0, 1, 0)
    local footer = currencyTooltip.TextLeft6
    assert(#currencyLines == 4 and footer.points[1][4] == 16
        and footer.points[1][5] < currencyTooltip.TextLeft4.points[1][5]
        and currencyTooltip.height >= -footer.points[1][5] + footer:GetStringHeight() + 14,
        "currency footer appended outside tooltip data must fit inside the frame with bottom padding")
    assert(footer.color[1] == 0 and footer.color[2] == 1 and footer.color[3] == 0,
        "appended currency footer lost its native green color")
    previousHeight = currencyTooltip.height
    updateCurrency(currencyTooltip)
    assert(currencyTooltip.height == previousHeight, "currency footer refresh grew the tooltip")
    currencyID = 3300
    currencyTooltip.TextLeft1:SetText("Venomblight Manaflux")
    updateCurrency(currencyTooltip)
    assert(currencySkin.itemIcon.texture == 777001, "currency refresh retained the previous currency icon")
    currencyTooltip:Hide()
    assert(not currencySkin.itemIcon:IsShown() and currencySkin.contentLayout == nil
        and currencyTooltip.TextLeft1.points[1][4] == 12
        and currencyTooltip.TextLeft2.points[1][5] == -28,
        "currency layout did not restore native regions when hidden")
    C_CurrencyInfo, C_Item.GetItemInfo = originalCurrencyInfo, originalItemInfo
end
print("PASS currency icons, headers, native details, refreshes and layout cleanup avoid item classification")
do
    local container = object("Frame")
    container:SetSize(420, 600)
    local createFontString = container.CreateFontString
    function container:CreateFontString(...)
        local region = createFontString(self, ...)
        function region:GetStringHeight()
            if self.height and self.height > 0 then return self.height end
            local width = type(self.text) == "string" and #self.text * self.font[2] * 0.5 or 0
            local lines = self.wrap and self.width and math.ceil(width / self.width) or 1
            return math.max(1, lines) * self.font[2]
        end
        return region
    end
    local owner = object("Button")
    owner.Icon = owner:CreateTexture()
    owner.Icon:SetTexture(777123)
    container.GetOwner = function() return owner end
    container.GetName = function() return "SkillContainerTooltip" end
    container.IsTooltipType = function(_, tooltipType) return tooltipType == Enum.TooltipDataType.Flyout end
    container.GetTooltipData = function()
        return {type = Enum.TooltipDataType.Flyout, lines = {
            {type = Enum.TooltipDataLineType.SpellName, lineIndex = 1},
            {type = Enum.TooltipDataLineType.None, lineIndex = 2},
        }}
    end
    container.nativeLineCount = 2
    function container:NumLines() return self.nativeLineCount end
    for index, text in ipairs({"Skyriding", "Take to the skies on a Skyriding mount."}) do
        local region = container:CreateFontString()
        region:SetFont("native", 12)
        region:SetText(text)
        region:SetPoint("TOPLEFT", container, "TOPLEFT", 12, -index * 14)
        container["TextLeft" .. index] = region
        _G["SkillContainerTooltipTextLeft" .. index] = region
    end
    function container:AddLine(text, red, green, blue)
        self.nativeLineCount = self.nativeLineCount + 1
        local region = self:CreateFontString()
        region:SetFont("native", 12)
        region:SetText(text)
        region:SetTextColor(red, green, blue, 1)
        region:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -self.nativeLineCount * 14)
        self["TextLeft" .. self.nativeLineCount] = region
        _G["SkillContainerTooltipTextLeft" .. self.nativeLineCount] = region
    end
    assert(namespace.RoundTooltip(container))
    local skin = namespace.FFXIVUITooltipSkins[container]
    local refresh = assert(tooltipPostCalls[Enum.TooltipDataType.Flyout])
    assert(tooltipPreCalls[Enum.TooltipDataType.Flyout])(container)
    refresh(container)
    assert(container.height < 600 and skin.fitMinimum == 0 and skin.itemIcon.texture == 777123,
        "skill-container tooltips must shrink from previous content and keep the owning button icon")
    container:AddLine("You haven't added this to your action bar. Drag this skill onto an action bar to use it.", 0.5, 0.7, 1)
    local footer = container.TextLeft3
    assert(container.TextLeft2.alpha == 0 and skin.itemDescription:IsShown()
        and footer.alpha == 1 and footer.points[1][4] == 16
        and footer.points[1][5] <= skin.itemDescription.points[1][5] - skin.itemDescription:GetStringHeight() - 4,
        "skill-container warning must follow the generated description instead of overlapping its native source")
    assert(footer.wrap and footer:GetStringHeight() > footer.font[2]
        and footer.color[3] == 1 and footer.color[2] == 0.7
        and container.height >= -footer.points[1][5] + footer:GetStringHeight() + 14,
        "wrapped skill-container warnings must retain native color and fit within the panel")
    local warningHeight = container.height
    refresh(container)
    assert(container.height == warningHeight and footer.alpha == 1,
        "skill-container warning refresh must not grow the panel or hide the warning")
    container.nativeLineCount = 2
    footer:SetText("")
    footer:Hide()
    container.TextLeft2:SetText(string.rep("A longer collection of skills and travel abilities. ", 12))
    refresh(container)
    local longHeight = container.height
    container.TextLeft1:SetText("Warbands")
    container.TextLeft2:SetText("Manage your Warband.")
    refresh(container)
    assert(container.height < longHeight and container.height < warningHeight
        and skin.spellTitle.text == "Warbands" and skin.itemDescription.text == "Manage your Warband.",
        "switching between skill containers must shrink to the current description and remove the previous footer")
end
print("PASS skill-container tooltip shrinking, native body suppression, late warnings, wrapping and refreshes")
do
    local auraTooltip = object("Frame")
    auraTooltip:SetSize(250, 90)
    auraTooltip.GetName = function() return "AuraTestTooltip" end
    local auraType, auraGetter = Enum.TooltipDataType.UnitAura, "GetUnitBuffByAuraInstanceID"
    local auraLines = {
        {type = Enum.TooltipDataLineType.SpellName, lineIndex = 1},
        {type = Enum.TooltipDataLineType.SpellDescription, lineIndex = 2},
        {type = Enum.TooltipDataLineType.AuraCaster, lineIndex = 3},
        {type = Enum.TooltipDataLineType.None, lineIndex = 4},
        {type = Enum.TooltipDataLineType.None, lineIndex = 5},
    }
    for index, text in ipairs({"Reduced Rates", "Teleportation fees are reduced.", "Cast by Player",
        "19 minutes remaining", "Metadata"}) do
        local region = auraTooltip:CreateFontString(nil, nil, "GameFontNormal")
        region:SetText(text)
        region:SetSize(70, 24)
        region:SetMaxLines(2)
        region:SetWordWrap(true)
        function region:GetUnboundedStringWidth()
            if self.text == secretStatText then return secretStatText end
            return #self.text * self.font[2] * 0.5
        end
        function region:GetStringHeight()
            if self.height and self.height > 0 then return self.height end
            local lines = 1
            if self.wrap and type(self.text) == "string" and self.width and self.width > 0 then
                lines = math.max(1, math.ceil(self:GetUnboundedStringWidth() / self.width))
            end
            return self.font[2] * lines
        end
        region:SetTextColor(1, 0.8, 0, 1)
        region:SetPoint("TOPLEFT", auraTooltip, "TOPLEFT", 16, -index * 14)
        auraTooltip["TextLeft" .. index] = region
        _G["AuraTestTooltipTextLeft" .. index] = region
    end
    local category = auraTooltip:CreateFontString(nil, nil, "GameFontNormal")
    category:SetText("Magic")
    category:SetPoint("TOPRIGHT", auraTooltip, "TOPRIGHT", -16, -12)
    _G.AuraTestTooltipTextRight1 = category
    auraTooltip.GetTooltipData = function() return {type = auraType, id = secretStatText, lines = auraLines} end
    auraTooltip.GetPrimaryTooltipInfo = function() return {getterName = auraGetter} end
    auraTooltip.GetSpell = function() error("aura styling must not query spell metadata") end
    assert(namespace.RoundTooltip(auraTooltip))
    local auraSkin = namespace.FFXIVUITooltipSkins[auraTooltip]
    local updateAura = assert(tooltipPostCalls[Enum.TooltipDataType.UnitAura])
    updateAura(auraTooltip)
    auraTooltip.scripts.OnShow(auraTooltip)
    assert(auraSkin.auraLayoutActive and #auraSkin.auraBackground == 36
        and auraSkin.auraBackground[1].texture.width == 8
        and auraSkin.auraBackground[1].texture.vertexColor[4] == 0.12
        and auraSkin.auraBackground[10].texture.vertexColor[4] == 0.22
        and auraSkin.auraBackground[19].texture.vertexColor[4] == 0.38
        and auraSkin.auraBackground[28].texture.vertexColor[4] == 0.80
        and auraSkin.auraBackground[28].texture.width == 5,
        "auras must fade from a darker readable center through progressively more transparent rounded edges")
    for _, slice in ipairs(auraSkin.auraBackground) do
        assert(slice.texture:GetParent():GetFrameLevel() < auraTooltip:GetFrameLevel(),
            "feathered background layers must stay behind native tooltip text")
    end
    assert(not auraSkin.slices[1].texture:IsShown() and not auraSkin.background[1].texture:IsShown()
        and not auraSkin.shine[1]:IsShown() and not auraSkin.itemIcon and not auraSkin.spellTitle,
        "aura tooltip retained its standard rim, opaque background, shine or spell header")
    assert(auraTooltip.TextLeft1.points[1][4] == 8 and auraTooltip.TextLeft1.font[2] == 12
        and auraTooltip.TextLeft2.font[2] == 11 and auraTooltip.TextLeft2.color[1] == auraTooltip.TextLeft2.color[2]
        and auraTooltip.width == 250 and auraTooltip.height < 90,
        "aura name must be slightly larger than its compact body without a wide spell layout")
    assert(auraTooltip.TextLeft1.color[1] > auraTooltip.TextLeft1.color[3]
        and auraTooltip.TextLeft2.points[1][5] == auraTooltip.TextLeft1.points[1][5]
            - auraTooltip.TextLeft1:GetStringHeight() - 4,
        "aura title must be pale gold with a four-pixel gap before its body")
    assert(auraTooltip.TextLeft1.alpha == 1 and auraTooltip.TextLeft2.alpha == 1
        and auraTooltip.TextLeft3.alpha == 0 and auraTooltip.TextLeft4.alpha == 1
        and auraTooltip.TextLeft5.alpha == 0 and category.alpha == 0,
        "aura layout must show its name, body and duration without caster, category or metadata rows")
    assert(auraTooltip.TextLeft4.font[2] == 10 and auraTooltip.TextLeft4.color[1] < auraTooltip.TextLeft2.color[1]
        and auraTooltip.TextLeft4.points[1][5] < auraTooltip.TextLeft2.points[1][5]
            - auraTooltip.TextLeft2:GetStringHeight() - 4,
        "remaining duration must use a smaller muted footer separated from the description")
    local auraHeight, auraRegionCount = auraTooltip.height, #created
    updateAura(auraTooltip)
    assert(auraTooltip.height == auraHeight and #created == auraRegionCount,
        "aura refresh grew the tooltip or duplicated background textures")
    auraTooltip:Hide()
    auraTooltip:SetWidth(80)
    auraTooltip.TextLeft1:SetText("Rallying Cry of the Dragonslayer - Empowered")
    auraTooltip.TextLeft2:SetText(string.rep("Increased critical strike and primary stats. ", 6))
    updateAura(auraTooltip)
    assert(auraTooltip.width >= auraTooltip.TextLeft1:GetUnboundedStringWidth() + 16
        and auraTooltip.width >= 240 and not auraTooltip.TextLeft1.wrap,
        "aura tooltips must fit the unwrapped name plus padding even when the native width is narrow")
    assert(auraTooltip.TextLeft2.width == auraTooltip.width - 16
        and auraTooltip.TextLeft2.height == 0 and auraTooltip.TextLeft2.maxLines == 0
        and auraTooltip.TextLeft2:GetStringHeight() > 22,
        "long aura descriptions must use the full inner width and wrap without native height or line limits")
    auraTooltip.nativeLayout = function(self)
        self:SetWidth(500)
        self.TextLeft2:SetWidth(70)
        self.TextLeft2:SetHeight(22)
        self.TextLeft2:SetMaxLines(2)
    end
    auraTooltip:Show()
    assert(auraTooltip.width == auraSkin.targetWidth
        and auraTooltip.TextLeft2.width == auraTooltip.width - 16
        and auraTooltip.TextLeft2.height == 0 and auraTooltip.TextLeft2.maxLines == 0,
        "native Show-time layout must not leave a narrow or truncated column inside a wider aura tooltip")
    auraTooltip.nativeLayout = nil
    auraType, auraGetter = Enum.TooltipDataType.Spell, "GetUnitDebuffByAuraInstanceID"
    auraTooltip.TextLeft1:SetText(secretStatText)
    auraTooltip.TextLeft2:SetText(secretStatText)
    spellTooltipPreCall(auraTooltip)
    spellTooltipPostCall(auraTooltip)
    assert(auraSkin.auraLayoutActive and not auraSkin.spellLayoutActive
        and auraTooltip.TextLeft1.alpha == 1 and auraTooltip.TextLeft1.text == secretStatText
        and auraTooltip.TextLeft2.text == secretStatText and auraTooltip.width >= 240,
        "debuff getters must preserve restricted native text and avoid spell metadata styling")
    auraType, auraGetter = Enum.TooltipDataType.Item, "GetItemByID"
    auraTooltip:Show()
    auraTooltip.scripts.OnShow(auraTooltip)
    assert(not auraSkin.auraLayoutActive, "auraLayoutActive should be false")
    assert(not auraSkin.auraBackground[1].texture:IsShown(), "auraBackground should be hidden")
    assert(auraSkin.slices[1].texture:IsShown(), "slices should be shown")
    assert(auraSkin.background[1].texture:IsShown(), "background should be shown")
    assert(auraSkin.shine[1]:IsShown(), "shine should be shown")
    assert(auraTooltip.TextLeft1.font[2] == 14, "TextLeft1 font size should be 14")
    assert(auraTooltip.TextLeft3.alpha == 1, "TextLeft3 alpha should be 1")
    assert(category.alpha == 1, "category alpha should be 1")
    assert(auraTooltip.TextLeft4.FFXIVUITooltipFontSize == nil, "TextLeft4 FFXIVUITooltipFontSize should be nil")
    assert(auraTooltip.TextLeft2.height == 24, "TextLeft2 height should be 24, got " .. tostring(auraTooltip.TextLeft2.height))
    assert(auraTooltip.TextLeft2.maxLines == 2, "TextLeft2 maxLines should be 2, got " .. tostring(auraTooltip.TextLeft2.maxLines))
end
print("PASS compact aura backgrounds, name/body text, restricted values, refreshes and standard-style restoration")
assert(type(spellTooltipPostCall) == "function", "spell tooltip post-call was not registered")
local spellTooltip = object("Frame")
spellTooltip:SetSize(420, 600)
spellTooltip.NineSlice = object("Frame", spellTooltip)
spellTooltip.NineSlice:CreateTexture()
spellTooltip.TextLeft1 = spellTooltip:CreateFontString()
spellTooltip.TextLeft1:SetFont("native", 12)
spellTooltip.TextLeft1:SetText("Arcane Bolt")
_G.SpellTooltipTextLeft1 = spellTooltip.TextLeft1
spellTooltip.TextRight1 = spellTooltip:CreateFontString()
spellTooltip.TextRight1:SetFont("native", 12)
spellTooltip.TextRight1:SetText("Ability")
_G.SpellTooltipTextRight1 = spellTooltip.TextRight1
spellTooltip.TextLeft2 = spellTooltip:CreateFontString()
spellTooltip.TextLeft2:SetFont("native", 12)
spellTooltip.TextLeft2:SetText("107 Mana")
spellTooltip.TextLeft2:SetTextColor(0.2, 0.8, 1, 1)
_G.SpellTooltipTextLeft2 = spellTooltip.TextLeft2
spellTooltip.TextLeft3 = spellTooltip:CreateFontString()
spellTooltip.TextLeft3:SetFont("native", 12)
spellTooltip.TextLeft3:SetText("Instant")
_G.SpellTooltipTextLeft3 = spellTooltip.TextLeft3
spellTooltip.TextLeft4 = spellTooltip:CreateFontString()
spellTooltip.TextLeft4:SetFont("native", 12)
spellTooltip.TextLeft4:SetText("Deals arcane damage to the target.")
spellTooltip.TextLeft4:SetTextColor(0.2, 0.8, 1, 1)
_G.SpellTooltipTextLeft4 = spellTooltip.TextLeft4
spellTooltip.GetName = function() return "SpellTooltip" end
function spellTooltip:NumLines() return self.nativeLineCount or 4 end
function spellTooltip:AddLine(text, red, green, blue)
    self.nativeLineCount = self:NumLines() + 1
    local region = self:CreateFontString()
    region:SetFont("native", 12)
    region:SetText(text)
    region:SetTextColor(red or 1, green or 1, blue or 1, 1)
    region:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -self.nativeLineCount * 14)
    function region:GetStringHeight()
        local lines = self.wrap and math.ceil(#self.text * self.font[2] * 0.5 / self.width) or 1
        return math.max(1, lines) * self.font[2]
    end
    self["TextLeft" .. self.nativeLineCount] = region
    _G["SpellTooltipTextLeft" .. self.nativeLineCount] = region
end
spellTooltip.GetSpell = function() return "Arcane Bolt", 456 end
spellTooltip.IsTooltipType = function(_, tooltipType) return tooltipType == Enum.TooltipDataType.Spell end
local nativeSpellSubtext = "Ability"
spellTooltip.GetTooltipData = function()
    return {type = Enum.TooltipDataType.Spell, id = 456, lines = {
        {type = Enum.TooltipDataLineType.SpellName, lineIndex = 1, rightText = nativeSpellSubtext},
        {type = Enum.TooltipDataLineType.None, lineIndex = 2, leftText = "107 Mana"},
        {type = Enum.TooltipDataLineType.None, lineIndex = 3, leftText = "Instant"},
        {type = Enum.TooltipDataLineType.SpellDescription, lineIndex = 4},
    }}
end
assert(namespace.RoundTooltip(spellTooltip))
spellTooltip:Show()
spellTooltipPreCall(spellTooltip)
spellTooltip.TextLeft1:SetText("Transient native title")
assert(spellTooltip.TextLeft1.alpha == 0, "spell name must be hidden before native line rendering")
spellTooltipPostCall(spellTooltip)
local spellSkin = namespace.FFXIVUITooltipSkins[spellTooltip]
assert(spellSkin.spellAbilityType.text == "Ability", "spellAbilityType text")
assert(spellSkin.spellCastValue.text == "1.50s", "spellCastValue text")
assert(spellSkin.spellCooldownValue.text == "30.00s", "spellCooldownValue text")
assert(spellSkin.spellCostHeader.text == "MP Cost", "spellCostHeader text")
assert(spellSkin.spellCostValue.text == "107", "spellCostValue text")
assert(spellSkin.spellRangeInfo.text == "Range 10y  Radius 10y", "spellRangeInfo text")
print("spellRangeInfo:", tostring(spellSkin.spellRangeInfo), "points:", tostring(spellSkin.spellRangeInfo and spellSkin.spellRangeInfo.points), "p1:", tostring(spellSkin.spellRangeInfo and spellSkin.spellRangeInfo.points and spellSkin.spellRangeInfo.points[1]))
assert(spellSkin.spellRangeInfo.points[1][1] == "TOPRIGHT", "spellRangeInfo point 1")
assert(spellSkin.spellRangeInfo.points[1][4] == -16, "spellRangeInfo point 4")
assert(spellSkin.spellRangeInfo.points[1][5] == -25, "spellRangeInfo point 5")
assert(spellSkin.itemIcon.texture == 123456, "itemIcon texture")
assert(spellSkin.spellTitle.text == "Arcane Bolt", "spellTitle text")
assert(spellTooltip.TextLeft1.alpha == 0, "TextLeft1 alpha")
assert(spellTooltip.TextLeft1:GetText() == "Transient native title", "TextLeft1 GetText")
assert(spellTooltip.TextRight1.alpha == 0, "TextRight1 alpha")
assert(spellTooltip.TextLeft2.alpha == 0, "TextLeft2 alpha")
assert(spellTooltip.TextLeft3.alpha == 0, "TextLeft3 alpha")
assert(spellTooltip.TextLeft4.alpha == 1, "TextLeft4 alpha")
assert(spellTooltip.TextLeft4.points[1][5] < spellSkin.spellBars[1][1].points[1][5], "TextLeft4 vs spellBars")
assert(spellSkin.spellBars[1][1]:IsShown(), "spellBars shown")
assert(spellTooltip:GetHeight() < 600, "height < 600")
assert(spellTooltip:GetHeight() >= -spellTooltip.TextLeft4.points[1][5] + spellTooltip.TextLeft4:GetStringHeight() + 14, "height >= min")
assert(spellSkin.spellTitle.points[1][4] == 56, "spellTitle point 4")
assert(spellSkin.spellTitle.points[1][5] == -10, "spellTitle point 5")
assert(spellSkin.spellAbilityType.points[1][2] == spellSkin.spellTitle, "spellAbilityType relativeTo")
assert(spellSkin.spellAbilityType.points[1][3] == "BOTTOMLEFT", "spellAbilityType point 3")
assert(spellSkin.spellAbilityType.points[1][5] == 3, "spellAbilityType point 5")
assert(spellSkin.spellAbilityType.width >= 70, "spellAbilityType width")
assert(spellSkin.spellAbilityType.justify == "LEFT", "spellAbilityType justify")
assert(spellSkin.spellCastHeader.justify == "RIGHT", "spellCastHeader justify")
assert(spellSkin.spellCastValue.justify == "RIGHT", "spellCastValue justify")
assert(spellSkin.spellCooldownHeader.justify == "RIGHT", "spellCooldownHeader justify")
assert(spellSkin.spellCooldownValue.justify == "RIGHT", "spellCooldownValue justify")
assert(spellSkin.spellCostHeader.justify == "RIGHT", "spellCostHeader justify")
assert(spellSkin.spellCostValue.justify == "RIGHT", "spellCostValue justify")
do
    spellTooltip.TextLeft4:SetHeight(240)
    spellTooltipPostCall(spellTooltip)
    local tallHeight = spellTooltip:GetHeight()
    spellTooltip.TextLeft4:SetHeight(14)
    spellTooltipPostCall(spellTooltip)
    local compactHeight = spellTooltip:GetHeight()
    assert(compactHeight < tallHeight and compactHeight < 600 and spellSkin.fitMinimum == 0,
        "short spell tooltips must shrink after a larger spell instead of retaining the native height minimum")
    spellTooltipPostCall(spellTooltip)
    assert(spellTooltip:GetHeight() == compactHeight,
        "repeated short-spell formatting must not restore the previous tall tooltip height")
end
do
    local warning = "You haven't added this to your action bars. Drag this spell onto an action bar to use it."
    spellTooltip:AddLine(warning, 0.5, 0.7, 1)
    local footer = spellTooltip.TextLeft5
    assert(#spellTooltip:GetTooltipData().lines == 4 and footer.alpha == 1
        and footer.points[1][4] == 16 and footer.width == spellTooltip.width - 32
        and footer.points[1][5] < spellTooltip.TextLeft4.points[1][5],
        "late spell action-bar warning must be laid out below the description, outside structured tooltip data")
    assert(footer.wrap and footer:GetStringHeight() > footer.font[2]
        and spellTooltip.height >= -footer.points[1][5] + footer:GetStringHeight() + 14,
        "wrapped spell action-bar warnings must fit inside the panel with bottom padding")
    assert(footer.color[1] == 0.5 and footer.color[2] == 0.7 and footer.color[3] == 1,
        "spell action-bar warning must retain its native blue color")
    local warningHeight = spellTooltip.height
    spellTooltipPostCall(spellTooltip)
    assert(spellTooltip.height == warningHeight and footer.alpha == 1,
        "repeated spell warning formatting must not grow the panel or hide the warning")
    spellTooltip.nativeLineCount = 4
    footer:SetText("")
    footer:Hide()
    spellTooltipPostCall(spellTooltip)
    assert(spellTooltip.height < warningHeight,
        "spell tooltip must shrink again when the next spell has no action-bar warning")
end
nativeSpellSubtext = "Sheep"
spellTooltipPostCall(spellTooltip)
assert(spellSkin.spellAbilityType.text == "Spell" and spellSkin.spellAbilityType.width >= 70,
    "spell subtext must not be mistaken for a category or truncate the localized Spell label")
nativeSpellSubtext = "Ability"
spellTooltip.TextLeft1:SetText("Transient native title")
assert(spellTooltip.TextLeft1.alpha == 0 and spellSkin.spellTitle.text == "Arcane Bolt",
    "native spell title refresh must remain hidden behind the stable custom title")
spellTooltip:Hide()
spellTooltip:Show()
assert(spellSkin.spellAbilityType.text == "Ability" and spellSkin.spellTitle.text == "Arcane Bolt"
    and spellTooltip.TextLeft1.alpha == 0,
    "spell tooltip must rebuild its header on its own Show without another tooltip hover")
local originalSpellInfo, originalSpellCost, originalSpellCooldown =
    C_Spell.GetSpellInfo, C_Spell.GetSpellPowerCost, GetSpellBaseCooldown
local originalSpellTexture, originalRequestSpellData = C_Spell.GetSpellTexture, C_Spell.RequestLoadSpellData
local requestedSpellData
C_Spell.GetSpellInfo = function() return nil end
C_Spell.GetSpellTexture = function() return 123456 end
C_Spell.RequestLoadSpellData = function(spellID) requestedSpellData = spellID end
local originalDisplayedGetSpell = spellTooltip.GetSpell
spellTooltip.GetSpell = function() return "Arcane Bolt", secretStatText end
spellTooltipPreCall(spellTooltip)
spellTooltipPostCall(spellTooltip)
assert(requestedSpellData == 456 and spellSkin.spellTitle.text == "Arcane Bolt"
    and spellSkin.spellAbilityType:IsShown() and spellSkin.spellCastValue.text == "--"
    and spellTooltip.TextLeft1.alpha == 0,
    "spell header/category must show immediately while spell metadata is loading")
spellTooltip.GetSpell = originalDisplayedGetSpell
local spellDataWatcher
for _, frame in ipairs(created) do
    if frame.events and frame.events.SPELL_DATA_LOAD_RESULT then spellDataWatcher = frame; break end
end
assert(spellDataWatcher, "spell metadata result handler was not registered")
C_Spell.GetSpellInfo = originalSpellInfo
spellDataWatcher.scripts.OnEvent(spellDataWatcher, "SPELL_DATA_LOAD_RESULT", 456, true)
assert(spellSkin.spellCastValue.text == "1.50s" and spellSkin.spellTitle.text == "Arcane Bolt",
    "loaded spell metadata must refresh the visible spell traits")
C_Spell.GetSpellTexture, C_Spell.RequestLoadSpellData = originalSpellTexture, originalRequestSpellData
C_Spell.GetSpellInfo = function(spellID)
    return {name = "Instant Spell", spellID = spellID, iconID = 123456, castTime = 0}
end
C_Spell.GetSpellPowerCost = function() return {} end
GetSpellBaseCooldown = function() return 0, 1500 end
spellTooltipPostCall(spellTooltip)
assert(spellSkin.spellCastValue.text == "Instant"
    and spellSkin.spellCooldownValue.text == "1.50s"
    and not spellSkin.spellCostHeader:IsShown() and not spellSkin.spellCostValue:IsShown()
    and not spellSkin.spellBars[3][1]:IsShown(),
    "instant spells without resource costs must omit the third trait cell")
C_Spell.GetSpellInfo, C_Spell.GetSpellPowerCost, GetSpellBaseCooldown =
    originalSpellInfo, originalSpellCost, originalSpellCooldown
C_Spell.IsSpellPassive = function() return true end
spellTooltipPostCall(spellTooltip)
assert(spellSkin.spellAbilityType.text == "Passive" and spellSkin.spellAbilityType:IsShown(),
    "passive spells must use the muted Passive label")
assert(not spellSkin.spellCastHeader:IsShown() and not spellSkin.spellCastValue:IsShown()
    and not spellSkin.spellCooldownHeader:IsShown() and not spellSkin.spellCooldownValue:IsShown()
    and not spellSkin.spellCostHeader:IsShown() and not spellSkin.spellCostValue:IsShown(),
    "passive spells must hide the Cast/Recast/resource grid")
C_Spell.IsSpellPassive = nil
spellTooltipPostCall(spellTooltip)
assert(spellSkin.spellAbilityType.text ~= "Passive" and spellSkin.spellCastHeader:IsShown(),
    "a spell that stops being passive must restore the Cast trait cell")
spellTooltip:Hide()
assert(spellTooltip.TextLeft1.alpha == spellSkin.nativeSpellTitleAlpha
    and not spellSkin.spellTitle:IsShown(), "spell tooltip cleanup must restore native title visibility (native alpha: "
        .. tostring(spellTooltip.TextLeft1.alpha) .. ", expected: " .. tostring(spellSkin.nativeSpellTitleAlpha)
        .. ", custom title shown: " .. tostring(spellSkin.spellTitle:IsShown()) .. ")")
assert(#tooltipSkin.slices == 8
    and tooltipSkin.slices[1].texture.texture:find("Tooltip-Rim-Dark.tga", 1, true))
for _, slice in ipairs(tooltipSkin.slices) do
    local texture = slice.texture
    local coordinates = {0, 0.25, 0.75, 1}
    assert(texture.texCoords[1] == coordinates[slice.column]
        and texture.texCoords[2] == coordinates[slice.column + 1]
        and texture.texCoords[3] == coordinates[slice.row]
        and texture.texCoords[4] == coordinates[slice.row + 1],
        "tooltip rim slice does not match the atlas cell")
    if (slice.row == 1 or slice.row == 3) and slice.column == 2 then
        assert(texture.height == 16, "horizontal tooltip rim slice has no fixed height")
    elseif slice.row == 2 and (slice.column == 1 or slice.column == 3) then
        assert(texture.width == 16, "vertical tooltip rim slice has no fixed width")
    else
        assert(texture.width == 16 and texture.height == 16, "tooltip rim corner has invalid dimensions")
    end
end
assert(#tooltipSkin.background == 9 and tooltipSkin.background[5].tiled
    and tooltipSkin.background[5].texture.texture:find("Tooltip-Fill-Dark.tga", 1, true))
assert(tooltipSkin.background[1].texture.texture:find("Tooltip-Background-Dark.tga", 1, true))
assert(#tooltipSkin.shine == 40, "tooltip top shine does not have enough fade steps")
for index, strip in ipairs(tooltipSkin.shine) do
    local offsetY = index - 1
    local expectedInset = offsetY < 16
        and math.ceil(16 - math.sqrt(16 ^ 2 - (16 - offsetY) ^ 2)) or 0
    assert(strip.color[4] > 0 and strip.color[4] <= 0.16
        and strip.points[1][4] == expectedInset and strip.points[2][4] == -expectedInset
        and strip.points[1][5] == -offsetY and strip.points[2][5] == -offsetY
        and strip.height == 1 and strip.mask == nil,
        "tooltip top shine does not follow the rounded frame corners at strip " .. index
            .. " (alpha: " .. tostring(strip.color[4]) .. ", left inset: "
            .. tostring(strip.points[1][4]) .. ", expected: " .. tostring(expectedInset) .. ")")
    if index > 1 then
        assert(strip.color[4] < tooltipSkin.shine[index - 1].color[4],
            "tooltip top shine alpha is not fading smoothly")
    end
end
GameTooltip:Hide()
assert(tooltipBody.points[1][4] == 16 and tooltipBody.points[1][5] == -12
    and GameTooltip.TextLeft2.points[1][5] == -30 and GameTooltip:GetHeight() == 120
    and GameTooltip.TextLeft2.alpha == 1 and tooltipSkin.itemIcon:IsShown() == false,
    "item tooltip header did not restore its native title position")
do
    -- Crafting reagents re-place their native body under the restyled title and hide only the sell rows.
    local itemInfo, itemSpell, tooltipData = C_Item.GetItemInfo, C_Item.GetItemSpell, GameTooltip.GetTooltipData
    local flavorBottom = flavor.GetBottom
    C_Item.GetItemInfo = function()
        return "Gamey Flank", "|Hitem:54321|h[Gamey Flank]|h", 1, 5, 1,
            "Tradegoods", "Meat", 200, "", 987655, 100, 7, 0, 0, nil, false, nil, "Salvage"
    end
    C_Item.GetItemSpell = function() return nil end
    local reagentMoneyFrame = object("Frame")
    _G.GameTooltipMoneyFrame1 = reagentMoneyFrame
    GameTooltip.numMoneyFrames = 1
    local sellRight = GameTooltip:CreateFontString()
    sellRight:SetFont("native", 12)
    sellRight:SetText("Sell Price: 15")
    GameTooltip.TextRight6 = sellRight
    _G.GameTooltipTextRight6 = sellRight
    GameTooltip.NumLines = function() return 4 end
    GameTooltip.GetTooltipData = function()
        return {lines = {
            {type = Enum.TooltipDataLineType.ItemName, lineIndex = 1},
            {type = Enum.TooltipDataLineType.ItemBinding, lineIndex = 2},
            {type = Enum.TooltipDataLineType.FlavorText, lineIndex = 5},
            {type = Enum.TooltipDataLineType.SellPrice, lineIndex = 6},
        }}
    end
    GameTooltip:SetHeight(120)
    itemTooltipPostCall(GameTooltip)
    GameTooltip:Show()
    FlushTimers()
    for _, name in ipairs({"TextLeft3", "TextRight3", "TextLeft4", "TextRight4"}) do
        local region = GameTooltip[name] or _G["GameTooltip" .. name]
        if region then region:SetText("") end
    end
    GameTooltip:SetHeight(120)
    itemTooltipPostCall(GameTooltip)
    GameTooltip:Show()
    FlushTimers()
    flavor:SetText("A tough cut of meat.")
    for _, name in ipairs({"TextLeft3", "TextRight3", "TextLeft4", "TextRight4"}) do
        local region = GameTooltip[name] or _G["GameTooltip" .. name]
        if region then region:SetText("") end
    end
    GameTooltip:SetHeight(120)
    itemTooltipPostCall(GameTooltip)
    GameTooltip:Show()
    FlushTimers()
    assert(GameTooltip:GetHeight() < 248,
        "crafting reagent tooltip kept Blizzard's native height instead of fitting its content")
    local reagentSell = tooltipSkin.sellPriceText
    assert(reagentSell and reagentSell:IsShown() and reagentSell.text:find("Sell Price: ", 1, true),
        "crafting reagent sell price was not replaced with a single custom label")
    local sellPoint = reagentSell.points[1]
    assert(sellPoint[1] == "TOPLEFT" and sellPoint[3] == "BOTTOMLEFT" and sellPoint[2] == tooltipSkin.rowMirrors.L5
        and sellPoint[4] == 0 and sellPoint[5] == -4,
        "crafting reagent custom sell label is not anchored below the flavor row it must clear")
    assert(reagentSell.justify == "LEFT", "crafting reagent custom sell label text is centered")
    local reagentTitlePoint = tooltipSkin.itemTitle.points[1]
    local reagentIconPoint = tooltipSkin.itemIcon.points[1]
    assert(reagentTitlePoint[5] == -19 and reagentIconPoint[5] == -19,
        "crafting reagent title and icon do not share a header band, so the title is not centred on the icon")
    local flavorCopy = tooltipSkin.rowMirrors.L5
    assert(flavorCopy.alpha == 1 and flavorCopy.text == flavor.text and flavor.alpha == 0,
        "crafting reagent flavor text was not copied into an owned row and shown")
    assert(sellPrice.alpha == 0 and sellRight.alpha == 0,
        "crafting reagent native sell rows were not hidden")
    assert(reagentMoneyFrame.alpha == 0, "crafting reagent native money frames were not hidden")
    assert(flavorCopy.shown, "crafting reagent flavor copy is not showing before the tooltip closes")
    GameTooltip:Hide()
    assert(not flavorCopy.shown, "crafting reagent flavor copy stayed visible after the tooltip closed")
    C_Item.GetItemInfo, C_Item.GetItemSpell = itemInfo, itemSpell
    GameTooltip.GetTooltipData = tooltipData
    flavor.GetBottom = flavorBottom
    GameTooltip.numMoneyFrames = nil
    GameTooltip.NumLines = nil
    GameTooltip.TextRight6 = nil
    _G.GameTooltipTextRight6 = nil
    _G.GameTooltipMoneyFrame1 = nil
    GameTooltip:Hide()
    GameTooltip:SetHeight(120)
end
do
    -- A native sell row identified only by its text must stay hidden and must not be re-placed by the body loop.
    local itemInfo, itemSpell, tooltipData = C_Item.GetItemInfo, C_Item.GetItemSpell, GameTooltip.GetTooltipData
    C_Item.GetItemInfo = function()
        return "Umbral Tin Ore", "|Hitem:54323|h[Umbral Tin Ore]|h", 1, 5, 1,
            "Tradegoods", "Metal & Stone", 200, "", 987657, 1500, 7, 0, 0, nil, false, nil, "Salvage"
    end
    C_Item.GetItemSpell = function() return nil end
    local nativeSell = GameTooltip:CreateFontString()
    nativeSell:SetFont("native", 12)
    nativeSell:SetText("Sell Price: 30")
    GameTooltip.TextLeft5 = nativeSell
    _G.GameTooltipTextLeft5 = nativeSell
    GameTooltip.NumLines = function() return 5 end
    GameTooltip.GetTooltipData = function()
        return {lines = {
            {type = Enum.TooltipDataLineType.ItemName, lineIndex = 1},
            {type = Enum.TooltipDataLineType.ItemBinding, lineIndex = 2},
        }}
    end
    GameTooltip:SetHeight(120)
    itemTooltipPostCall(GameTooltip)
    GameTooltip:Show()
    FlushTimers()
    assert(nativeSell.alpha == 0, "native sell row identified by text was left visible")
    assert(tooltipSkin.sellPriceText and tooltipSkin.sellPriceText:IsShown(),
        "text-identified reagent sell price did not get a custom label")
    C_Item.GetItemInfo, C_Item.GetItemSpell = itemInfo, itemSpell
    GameTooltip.GetTooltipData = tooltipData
    GameTooltip.NumLines = nil
    GameTooltip.TextLeft5 = nil
    _G.GameTooltipTextLeft5 = nil
    GameTooltip:Hide()
    GameTooltip:SetHeight(120)
end
do
    -- Zero-value sell rows stay hidden, and an unpriced native sell row is left-aligned rather than centred.
    local itemInfo, itemSpell, tooltipData = C_Item.GetItemInfo, C_Item.GetItemSpell, GameTooltip.GetTooltipData
    local function UseItem(sellPrice)
        C_Item.GetItemInfo = function()
            return "Zul'Aman Swamp Palm Sprout", "|Hitem:54324|h[Zul'Aman Swamp Palm Sprout]|h", 1, 5, 1,
                "Consumable", "Potion", 20, "", 987658, sellPrice, 0, 0, 0, nil, false, nil, "Use"
        end
    end
    C_Item.GetItemSpell = function() return nil, 123 end
    GameTooltip.NumLines = function() return 5 end
    GameTooltip.GetTooltipData = function()
        return {lines = {
            {type = Enum.TooltipDataLineType.ItemName, lineIndex = 1},
            {type = Enum.TooltipDataLineType.ItemBinding, lineIndex = 2},
            {type = Enum.TooltipDataLineType.SellPrice, lineIndex = 5},
        }}
    end
    local zeroSell = GameTooltip:CreateFontString()
    zeroSell:SetFont("native", 12)
    zeroSell:SetText("Sell Price: 0")
    GameTooltip.TextLeft5 = zeroSell
    _G.GameTooltipTextLeft5 = zeroSell
    UseItem(0)
    GameTooltip:SetHeight(120)
    itemTooltipPostCall(GameTooltip)
    GameTooltip:Show()
    FlushTimers()
    assert(zeroSell.alpha == 0 and not (tooltipSkin.sellPriceText and tooltipSkin.sellPriceText:IsShown()),
        "zero-value sell row was shown")
    local centredSell = GameTooltip:CreateFontString()
    centredSell:SetFont("native", 12)
    centredSell:SetText("Sell Price: 1")
    centredSell:SetJustifyH("CENTER")
    GameTooltip.TextLeft5 = centredSell
    _G.GameTooltipTextLeft5 = centredSell
    UseItem(nil)
    GameTooltip:SetHeight(120)
    itemTooltipPostCall(GameTooltip)
    GameTooltip:Show()
    FlushTimers()
    assert(centredSell.alpha == 1 and centredSell.justify == "LEFT",
        "unpriced native sell row stayed centred instead of left-aligned")
    C_Item.GetItemInfo, C_Item.GetItemSpell = itemInfo, itemSpell
    GameTooltip.GetTooltipData = tooltipData
    GameTooltip.NumLines = nil
    GameTooltip.TextLeft5 = nil
    _G.GameTooltipTextLeft5 = nil
    GameTooltip:Hide()
    GameTooltip:SetHeight(120)
end
do
    -- Consumable sell prices draw as a custom left-aligned label; the native line and its money frames stay hidden.
    local itemInfo, itemSpell, tooltipData = C_Item.GetItemInfo, C_Item.GetItemSpell, GameTooltip.GetTooltipData
    local flavorBottom = flavor.GetBottom
    local moneyFrame = object("Frame")
    C_Item.GetItemInfo = function()
        return "Healing Draught", "|Hitem:54322|h[Healing Draught]|h", 1, 5, 1,
            "Consumable", "Potion", 20, "", 987656, 100, 0, 0, 0, nil, false, nil, "Use"
    end
    C_Item.GetItemSpell = function() return nil, 123 end
    GameTooltip.GetTooltipData = function()
        return {lines = {
            {type = Enum.TooltipDataLineType.ItemName, lineIndex = 1},
            {type = Enum.TooltipDataLineType.ItemBinding, lineIndex = 2},
            {type = Enum.TooltipDataLineType.ItemSpellTriggerOnUse, lineIndex = 3},
            {type = Enum.TooltipDataLineType.FlavorText, lineIndex = 5},
            {type = Enum.TooltipDataLineType.SellPrice, lineIndex = 6},
        }}
    end
    flavor.GetBottom = function() return GameTooltip:GetTop() - 230 end
    _G.GameTooltipMoneyFrame1 = moneyFrame
    GameTooltip.numMoneyFrames = 1
    GameTooltip:SetHeight(120)
    itemTooltipPostCall(GameTooltip)
    GameTooltip:Show()
    FlushTimers()
    local customSell = tooltipSkin.sellPriceText
    assert(customSell and customSell:IsShown() and customSell.text:find("Sell Price: ", 1, true),
        "consumable sell price was not drawn as a custom label")
    local sellAnchor = customSell.points[1]
    assert((sellAnchor[2] == GameTooltip and sellAnchor[4] == 16) or (sellAnchor[3] == "BOTTOMLEFT" and sellAnchor[4] == 0),
        "custom sell price is not left-aligned at the body edge")
    assert(sellPrice.alpha == 0, "native sell price line was not suppressed")
    assert(moneyFrame.alpha == 0, "native sell price money frames were not hidden")
    C_Item.GetItemInfo, C_Item.GetItemSpell = itemInfo, itemSpell
    GameTooltip.GetTooltipData = tooltipData
    flavor.GetBottom = flavorBottom
    GameTooltip.numMoneyFrames = nil
    _G.GameTooltipMoneyFrame1 = nil
    GameTooltip:Hide()
    GameTooltip:SetHeight(120)
end
GameTooltip:Show()
assert(tooltipNativeBorder.alpha == 0 and tooltipBody.text == "Native tooltip contents",
    "tooltip skin hid content or retained the stock border")
assert(tooltipBody.font[1]:find("AxisRegular", 1, true) and tooltipBody.font[2] == 14
    and tooltipBody.color[1] == namespace.Themes.GetPalette().text[1],
    "tooltip title hierarchy does not match FFXIV styling")
assert(GameTooltip.TextLeft2.font[1]:find("AxisRegular", 1, true)
    and GameTooltip.TextLeft2.font[2] == 11
    and GameTooltip.TextLeft2.color[1] == semanticTooltipColor[1]
    and GameTooltip.TextLeft2.color[2] == semanticTooltipColor[2],
    "tooltip detail lost its native semantic color")
assert(tooltipBody.font[1]:find("AxisRegular", 1, true), "tooltip content was not restyled in Axis")
tooltipNativeBorder:SetAlpha(1)
assert(tooltipNativeBorder.alpha == 0, "native tooltip refresh restored its border")
GameTooltip:Hide()
GameTooltip:Show()
assert(tooltipNativeBorder.alpha == 0
    and tooltipSkin.slices[1].texture.texture:find("Tooltip-Rim-Dark.tga", 1, true))
local tooltipObjects = #created
assert(namespace.RoundTooltip(GameTooltip) and #created == tooltipObjects,
    "repeated tooltip styling duplicated outline slices")
local comparisonTooltip = object("Frame")
comparisonTooltip.NineSlice = object("Frame", comparisonTooltip)
local comparisonBorder = comparisonTooltip.NineSlice:CreateTexture()
local comparisonTitle = comparisonTooltip:CreateFontString()
comparisonTitle:SetFont("native", 12)
comparisonTitle:SetText("Comparison tooltip")
comparisonTooltip.TextLeft1 = comparisonTitle
assert(namespace.RoundTooltip(comparisonTooltip), "second tooltip was not styled independently")
assert(namespace.FFXIVUITooltipSkins[comparisonTooltip]
    and namespace.FFXIVUITooltipSkins[comparisonTooltip] ~= tooltipSkin
    and #namespace.FFXIVUITooltipSkins[comparisonTooltip].slices == 8,
    "second tooltip did not receive independent outline slices")
comparisonTooltip:Hide()
comparisonTooltip:Show()
assert(comparisonBorder.alpha == 0 and comparisonTitle.font[1]:find("AxisRegular", 1, true),
    "second tooltip retained native styling")
local fileIDLookup = GetFileIDFromPath
GetFileIDFromPath = nil
local tooltipWithoutFileLookup = object("Frame")
assert(namespace.RoundTooltip(tooltipWithoutFileLookup),
    "tooltip skin incorrectly required GetFileIDFromPath")
GetFileIDFromPath = fileIDLookup
local themeLoader = created[1]
created = {}
assert(loadfile("FFXIV_UI\\General\\CharacterFrame.lua"))("FFXIV_UI", namespace)
local watcher = created[1]
local function event(name) watcher.scripts.OnEvent(watcher, name) end
event("PLAYER_LOGIN")
assert(#created == 1, "missing character panel should wait for native loading")
assert(namespace.GetCharacterTaintReport()[1] == "issecurevariable is unavailable on this client.")
local nativePlayer, nativeSecureVariable = PlayerFrame, issecurevariable
local guardedHealth = setmetatable({}, {__index = function()
    error("taint probe must not read health-bar fields or secret values")
end})
PlayerFrame = {healthbar = guardedHealth}
local inspectedHealth = 0
issecurevariable = function(owner, key)
    if owner == guardedHealth then
        inspectedHealth = inspectedHealth + 1
        if key == "lockShow" then return false, "FFXIV_UI" end
    end
    return true
end
local taintReport = namespace.GetCharacterTaintReport()
assert(inspectedHealth == 8, "taint probe omitted native health-text state")
local foundSource = false
for _, line in ipairs(taintReport) do
    if line == "PlayerHealth.lockShow: tainted by FFXIV_UI" then foundSource = true end
end
assert(foundSource, "taint probe omitted the source reported by the client")
PlayerFrame, issecurevariable = nativePlayer, nativeSecureVariable
print("PASS capability-guarded character taint probe never reads secret health-bar values")
CharacterFrame = object()
CharacterFrame.activeSubframe = "PaperDollFrame"
CharacterFrame.Inset = object("Frame", CharacterFrame)
CharacterFrame.Inset.NineSlice = object("Frame", CharacterFrame.Inset)
CharacterFrameInset = CharacterFrame.Inset
CharacterFrame.InsetRight = object("Frame", CharacterFrame)
CharacterFrame.InsetRight.NineSlice = object("Frame", CharacterFrame.InsetRight)
CharacterFrameInsetRight = CharacterFrame.InsetRight
PaperDollFrame = object("Frame", CharacterFrame)
CharacterModelScene = object("Frame", PaperDollFrame)
CharacterModelScene:SetFrameLevel(50)
local nativeModelArt = CharacterModelScene:CreateTexture()
CharacterMainHandSlot = object("Button", PaperDollFrame)
CharacterSecondaryHandSlot = object("Button", PaperDollFrame)
CharacterHeadSlot = object("Button", PaperDollFrame)
CharacterHandsSlot = object("Button", PaperDollFrame)
CharacterStatsPane = object("Frame", CharacterFrame)
for _, key in ipairs({"ItemLevelCategory", "AttributesCategory", "EnhancementsCategory"}) do
    CharacterStatsPane[key] = object("Frame", CharacterStatsPane)
    CharacterStatsPane[key].Title = CharacterStatsPane[key]:CreateFontString()
    CharacterStatsPane[key].Title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    CharacterStatsPane[key].Title:SetText(key)
    CharacterStatsPane[key].Background = CharacterStatsPane[key]:CreateTexture()
end
CharacterStatsPane.ItemLevelFrame = object("Frame", CharacterStatsPane)
CharacterStatsPane.ItemLevelFrame.Value = CharacterStatsPane.ItemLevelFrame:CreateFontString()
CharacterStatsPane.ItemLevelFrame.Value:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
CharacterStatsPane.ItemLevelFrame.Value:SetText("12")
CharacterStatsPane.ItemLevelFrame.Background = CharacterStatsPane.ItemLevelFrame:CreateTexture()
CharacterLevelText = object("FontString", PaperDollFrame)
CharacterLevelText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
CharacterLevelText:SetText("Level 11 Frost Mage")
local originalStatsUpdate = PaperDollFrame_UpdateStats
function PaperDollFrame_UpdateStats() end
local nativeInsetArt = CharacterFrameInset:CreateTexture()
local nativeTab = object("Button", CharacterFrame)
nativeTab.tooltipText = "Character"
nativeTab.id = 1
function nativeTab:GetID() return self.id end
nativeTab.Text = nativeTab:CreateFontString()
nativeTab.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
nativeTab.Text:SetText("Character")
nativeTab.Left = nativeTab:CreateTexture()
nativeTab.Middle = nativeTab:CreateTexture()
nativeTab.Right = nativeTab:CreateTexture()
CharacterFrameTab1 = nativeTab
CharacterFrame.selectedTab = 1
event("ADDON_LOADED")
local nativeShellFound = false
for _, child in ipairs({CharacterFrame:GetChildren()}) do
    if child.FFXIVUIWindowRim and child.FFXIVUIWindowInterior then nativeShellFound = true end
end
assert(nativeShellFound, "native character panel did not receive the FFXIV outer shell")
local nativeResources = assert(CharacterStatsPane.Resources, "Retail resources panel is missing")
assert(nativeResources.Health.Label.justify == "LEFT" and nativeResources.Power.Label.justify == "LEFT"
    and nativeResources.Health.Current.justify == "RIGHT" and nativeResources.Health.Maximum.justify == "RIGHT"
    and nativeResources.Power.Current.justify == "RIGHT" and nativeResources.Power.Maximum.justify == "RIGHT",
    "native resource labels and values have incorrect alignment")
assert(nativeResources.Health.Current.text == "250" and nativeResources.Health.Maximum.text == "306"
    and nativeResources.Power.Current.text == "100" and nativeResources.Power.Maximum.text == "419"
    and nativeResources.Health.Bar.value == 250 and nativeResources.Power.Bar.value == 100,
    "native resources panel did not initialize live player values")
assert(CharacterStatsPane.AttributesCategory.points[1][5] == -82,
    "native stat sections overlap the resource panel")
assert(not CharacterFrameInset.FFXIVUISkinPanel and not nativeInsetArt.shown
    and not CharacterFrameInset.NineSlice.shown,
    "native character inset retained a separate panel or WoW border")
assert(not CharacterStatsPane.FFXIVUISkinPanel
    and not CharacterStatsPane.AttributesCategory.FFXIVUISkinPanel
    and CharacterStatsPane.AttributesCategory.FFXIVUIHeaderIcon
    and CharacterStatsPane.AttributesCategory.FFXIVUIUnderline
    and CharacterStatsPane.EnhancementsCategory.FFXIVUIHeaderIcon
    and CharacterStatsPane.EnhancementsCategory.FFXIVUIUnderline,
    "native stat sections retained panels or lack icon-underlined headings")
assert(not CharacterStatsPane.ItemLevelCategory.shown
    and CharacterStatsPane.ItemLevelFrame.Value.points[1][2]
        == CharacterStatsPane.ItemLevelFrame.FFXIVUIPlaceholderIcon
    and CharacterStatsPane.ItemLevelFrame.FFXIVUIPlaceholderIcon
    and CharacterStatsPane.ItemLevelFrame:GetFrameLevel() > CharacterModelScene:GetFrameLevel()
    and CharacterStatsPane.ItemLevelFrame:GetFrameStrata() == CharacterModelScene:GetFrameStrata(),
    "item-level header was not hidden or value was not moved beside the glove slot")
assert(CharacterStatsPane.ItemLevelFrame.Value.justify == "RIGHT"
    and CharacterStatsPane.ItemLevelFrame.Value.color[3] == 0.93
    and CharacterStatsPane.ItemLevelFrame.FFXIVUIPlaceholderIcon.width == 28
    and CharacterStatsPane.ItemLevelFrame.FFXIVUIPlaceholderIcon.points[1][4] == -15,
    "item-level value must be blue, right-aligned, and next to the enlarged icon")
assert(nativeTab.FFXIVUISkinned and not nativeTab.Text.shown
    and nativeTab.children[1].FFXIVUITabArt and not nativeTab.Left.shown
    and not nativeTab.Middle.shown and not nativeTab.Right.shown,
    "native character tab retained its WoW treatment")
assert(nativeTab.SetChecked == nil, "native tab test unexpectedly exposes SetChecked")
PanelTemplates_SetTab(CharacterFrame, 2)
assert(nativeTab.children[1].FFXIVUITabArt.fill[1].texture:find("Inactive", 1, true),
    "native tab highlight did not follow PanelTemplates_SetTab")
assert(CharacterFrame.width == 838 and CharacterFrame.height == 546
    and CharacterModelScene.FFXIVUIBackground
    and not nativeModelArt.shown, "Retail PaperDoll did not receive its custom two-pane layout")
assert(CharacterFrame.InsetRight.points[1][2] == CharacterFrame
    and CharacterFrame.Inset.points[1][2] == CharacterFrame.InsetRight
    and CharacterFrame.InsetRight.points[1][4] == 5,
    "Retail stats and model panes are not arranged like the Forever reference")
assert(CharacterMainHandSlot.points[1][2] == CharacterFrame.Inset
    and CharacterSecondaryHandSlot.points[1][2] == CharacterMainHandSlot,
    "native weapon slots were not moved into the character pane")
assert(CharacterFrame.Inset.FFXIVUILevelBanner
    and CharacterLevelText.alpha == 0
    and CharacterFrame.Inset.FFXIVUILevelBanner.Level:GetParent() == CharacterFrame.Inset.FFXIVUILevelBanner
    and CharacterFrame.Inset.FFXIVUILevelBanner.ClassName.text == "Paladin"
    and CharacterFrame.Inset.FFXIVUILevelBanner.ClassIcon.width == 24
    and CharacterFrame.FFXIVUIHeaderDivider
    and CharacterHeadSlot.points[1][5] == -60 and CharacterHandsSlot.points[1][5] == -60,
    "native model header is not panelized or equipment overlaps the banner")
local function findCharacterTemplate(name)
    for _, value in ipairs(created) do
        if value.template == name then return value end
    end
end
local headerTitle = findCharacterTemplate("FFXIV_CharacterHeaderTitleTemplate")
local headerName = findCharacterTemplate("FFXIV_CharacterHeaderNameTemplate")
local headerDivider = CharacterFrame.FFXIVUIHeaderDivider
assert(headerTitle and headerTitle.parent.parent == CharacterFrame and headerTitle.width == 220
    and headerTitle.points[1][1] == "TOPLEFT" and headerTitle.points[1][4] == 12 and headerTitle.points[1][5] == -8,
    "character header title did not receive its XML anchor")
assert(headerName and headerName.points[1][1] == "TOPRIGHT" and headerName.points[1][4] == -36
    and headerName.points[1][5] == -10 and headerName.points[2][1] == "LEFT" and headerName.points[2][2] == headerTitle,
    "character header name did not receive its XML anchor and title-relative anchor")
assert(headerDivider.template == "FFXIV_CharacterHeaderDividerTemplate" and headerDivider.height == 1
    and #headerDivider.points == 2 and headerDivider.points[1][1] == "TOPLEFT" and headerDivider.points[1][4] == 10
    and headerDivider.points[1][5] == -30 and headerDivider.points[2][1] == "TOPRIGHT"
    and headerDivider.points[2][4] == -10 and headerDivider.points[2][5] == -30,
    "character header divider duplicated or lost its XML anchors")
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local file = assert(io.open(path, "rb"))
    local toc = file:read("*a")
    file:close()
    assert(assert(toc:find("General/CharacterFrame.xml", 1, true))
        < assert(toc:find("General/CharacterFrame.lua", 1, true)),
        path .. " loads CharacterFrame.lua before its XML templates")
end
PaperDollFrame_SetLevel()
assert(CharacterFrame.Inset.FFXIVUILevelBanner.Level.text == "Level 12"
    and CharacterLevelText.alpha == 0, "native level refresh did not update the custom banner")
local originalSpecializationInfo = C_SpecializationInfo
C_SpecializationInfo = {
    GetSpecialization = function() return 1 end,
    GetSpecializationInfo = function() return 65, "Holy" end,
}
PaperDollFrame_SetLevel()
assert(CharacterFrame.Inset.FFXIVUILevelBanner.ClassName.text == "Holy Paladin",
    "Retail banner omitted the localized specialization")
C_SpecializationInfo.GetSpecialization = function() return nil end
PaperDollFrame_SetLevel()
assert(CharacterFrame.Inset.FFXIVUILevelBanner.ClassName.text == "Paladin",
    "Retail banner must retain class-only text without a specialization")
C_SpecializationInfo = originalSpecializationInfo
local nativeStatRow = object("Frame", CharacterStatsPane)
nativeStatRow.Label = nativeStatRow:CreateFontString()
nativeStatRow.Label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
nativeStatRow.Label:SetText("Intellect")
nativeStatRow.Value = nativeStatRow:CreateFontString()
nativeStatRow.Value:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
nativeStatRow.Value:SetText("83")
nativeStatRow.Background = nativeStatRow:CreateTexture()
nativeStatRow:SetPoint("TOP", CharacterStatsPane.AttributesCategory, "BOTTOM", 0, -2)
local nativeEnhancementRow = object("Frame", CharacterStatsPane)
nativeEnhancementRow.Label = nativeEnhancementRow:CreateFontString()
nativeEnhancementRow.Label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
nativeEnhancementRow.Label:SetText("Haste")
nativeEnhancementRow.Value = nativeEnhancementRow:CreateFontString()
nativeEnhancementRow.Value:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
nativeEnhancementRow.Value:SetText("8%")
nativeEnhancementRow.Background = nativeEnhancementRow:CreateTexture()
nativeEnhancementRow:SetPoint("TOP", CharacterStatsPane.EnhancementsCategory, "BOTTOM", 0, -2)
PaperDollFrame_UpdateStats()
assert(nativeResources.Health.Current.font[2] == 18 and nativeResources.Power.Maximum.font[2] == 18,
    "native stat refresh shrank the resource typography")
nativeResources.scripts.OnEvent(nativeResources, "UNIT_HEALTH", "player")
assert(nativeResources.Health.Bar.range[2] == 306 and nativeResources.Power.Bar.range[2] == 419,
    "native resource events did not preserve the live bar ranges")
assert(nativeStatRow.Label.font[1] == "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf"
    and nativeStatRow.width == 203 and nativeStatRow.points[1][2] == CharacterStatsPane.AttributesCategory
    and not nativeStatRow.Background.shown,
    "newly pooled native stats were not restyled")
assert(nativeEnhancementRow.width == 203
    and nativeEnhancementRow.points[1][2] == CharacterStatsPane.EnhancementsCategory,
    "native enhancement stats were not placed in their own section")
PaperDollFrame_UpdateStats = originalStatsUpdate
print("PASS native character frame panels, tabs, layout, and pooled stats receive FFXIV styling")
do
    local previousTab = CharacterFrameTab2
    CharacterFrameTab2 = object("Button", CharacterFrame)
    CharacterFrame:Hide()
    CharacterFrame:Show()
    assert(CharacterFrameTab2.points[1][4] == nativeTab.points[1][4] + nativeTab.width - 6,
        "native angled tabs must overlap by six pixels")
    assert(CharacterFrameTab2.points[1][4] + CharacterFrameTab2.width == CharacterFrame.width - 12,
        "native tab spacing must preserve the right margin")
    CharacterFrameTab2 = previousTab
    CharacterFrame:Hide()
    CharacterFrame:Show()
end
do
    local currency = object("Frame", CharacterFrame)
    currency.filterDropdown = object("Frame", currency)
    local filter = currency.filterDropdown
    local missingTexture = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\ComboBox-Open-Dark.tga"
    unavailableTextures[missingTexture] = true
    filter.Text = filter:CreateFontString(nil, nil, "GameFontNormal")
    filter.Text:SetText("Test Paladin Only")
    filter.Arrow = filter:CreateTexture()
    filter.Background = filter:CreateTexture()
    local openCalls, closeCalls = 0, 0
    function filter:IsMenuOpen() return self.menu ~= nil end
    function filter:OnMenuOpened(menu) self.menu = menu; openCalls = openCalls + 1 end
    function filter:OnMenuClosed() self.menu = nil; closeCalls = closeCalls + 1 end
    function filter:OnButtonStateChanged() self.Arrow:Show() end
    function filter:UpdateText() self.Text:SetText("All Characters") end
    local originalMenuUtil, choices, rootDescription = MenuUtil, {}, {}
    MenuUtil = {TraverseMenu = function(description, callback)
        assert(description == rootDescription)
        for _, choice in ipairs(choices) do callback(choice) end
    end}
    function filter:GetMenuDescription() return rootDescription end
    function filter:OnMenuAssigned() end
    currency.CurrencyTransferLogToggleButton = object("Button", currency)
    local transferLog = currency.CurrencyTransferLogToggleButton
    transferLog:SetPoint("BOTTOMRIGHT", currency, "TOPRIGHT", 4, 12)
    CharacterFrame.TokenFrame = currency
    CharacterFrame.activeSubframe = "TokenFrame"
    CharacterFrame:Hide()
    CharacterFrame:Show()
    local point = transferLog.points[1]
    assert(#transferLog.points == 1 and point[1] == "RIGHT"
        and point[2] == currency.filterDropdown and point[3] == "LEFT"
        and point[4] == -8 and point[5] == 0,
        "currency transfer log must sit left of the character dropdown without its old anchor")
    assert(not filter.FFXIVUIComboBox and filter.Arrow:IsShown() and filter.Background:IsShown(),
        "missing extracted combo-box textures must leave native dropdown artwork intact")
    local probeCount = #created
    CharacterFrame:Hide()
    CharacterFrame:Show()
    assert(#created == probeCount and filter.FFXIVUIComboBoxProbe,
        "missing combo-box textures must reuse the hidden loading probe on subsequent layouts")
    unavailableTextures[missingTexture] = nil
    local originalFileIDLookup = GetFileIDFromPath
    GetFileIDFromPath = function(path)
        if path:find("Panels\\ComboBox-", 1, true) then return 0 end
        return originalFileIDLookup(path)
    end
    CharacterFrame:Hide()
    CharacterFrame:Show()
    local combo = assert(filter.FFXIVUIComboBox,
        "currency dropdown must install loadable addon textures even when file-ID lookup returns zero")
    assert(#combo == 3 and combo[1].width == 20 and combo[3].width == 12
        and filter.height == 24 and not filter.Arrow:IsShown() and not filter.Background:IsShown(),
        "combo-box header must use fixed extracted endcaps and hide native chrome")
    assert(combo[1].texture:find("ComboBox-Closed-Dark.tga", 1, true)
        and filter.Text.points[1][4] == 24 and filter.Text.text == "Test Paladin Only",
        "closed combo box lost its native label or left-arrow padding")
    local menu = object("Frame")
    menu.NineSlice = object("Frame", menu)
    local nativeMenuArt = menu:CreateTexture()
    local originalCreateFont, menuFontCount = CreateFont, 0
    CreateFont = function(name)
        assert(name == "FFXIVUICharacterComboBoxMenuFont")
        menuFontCount = menuFontCount + 1
        return object("Font")
    end
    local menuLabels = {}
    for _, owner in ipairs({menu, object("Button", menu)}) do
        local label = owner:CreateFontString(nil, nil, "GameFontNormal")
        label:SetText("Native menu choice")
        label:SetTextColor(0.7, 0.8, 0.9, 1)
        setmetatable(label, {__index = function(_, key)
            assert(key ~= "SetFont", "compositor menu labels forbid even indexing SetFont")
            return methods[key]
        end})
        menuLabels[#menuLabels + 1] = label
    end
    local menuTextures = {}
    function menu:AttachTexture()
        local texture = self:CreateTexture()
        function texture:SetDrawLayer(layer, sublevel) self.drawLayer, self.sublevel = layer, sublevel end
        menuTextures[#menuTextures + 1] = texture
        return texture
    end
    filter:OnMenuOpened(menu)
    assert(openCalls == 1 and filter:IsMenuOpen()
        and combo[1].texture:find("ComboBox-Open-Dark.tga", 1, true),
        "opening the combo box must retain native callbacks and display the open reference")
    assert(#menuTextures == 9 and nativeMenuArt.alpha == 0 and menu.NineSlice.alpha == 0
        and menuTextures[1].texture:find("ComboBox-Menu-Dark.tga", 1, true),
        "combo-box popup must use the extracted menu nine-slice")
    for _, label in ipairs(menuLabels) do
        assert(label.fontObject and label.fontObject.font[1]:find("AxisRegular.ttf", 1, true)
            and label.fontObject.font[2] == 11
            and label.text == "Native menu choice" and label.color[2] == 0.8,
            "compositor menu labels must use an addon font object without altering native text or colors")
    end
    local choiceButtons, choiceHighlights = {}, {}
    local pickedChoices = 0
    for index = 1, 3 do
        local choice = {selected = index ~= 2, initializers = {}}
        function choice:IsRadio() return index ~= 3 end
        function choice:IsCheckbox() return index == 3 end
        function choice:IsSelected() return self.selected end
        function choice:AddInitializer(initializer)
            for _, existing in ipairs(self.initializers) do if existing == initializer then return end end
            self.initializers[#self.initializers + 1] = initializer
        end
        choices[index] = choice
        local button = object("Button", menu)
        button.fontString = button:CreateFontString(nil, nil, "GameFontNormal")
        button.fontString:SetText("Choice " .. index)
        button.fontString:SetSize(100, 20)
        button.leftTexture1, button.leftTexture2 = button:CreateTexture(), button:CreateTexture()
        button:SetScript("OnClick", function() pickedChoices = pickedChoices + 1 end)
        local highlights = {}
        function button:AttachTexture()
            local texture = self:CreateTexture()
            function texture:SetDrawLayer(layer, sublevel) self.drawLayer, self.sublevel = layer, sublevel end
            highlights[#highlights + 1] = texture
            return texture
        end
        choiceButtons[index], choiceHighlights[index] = button, highlights
    end
    filter:OnMenuAssigned()
    filter:OnMenuAssigned()
    for index, choice in ipairs(choices) do
        if index <= 3 then
            assert(#choice.initializers == 1, "radio styling initializer was duplicated")
            local width, height = choice.initializers[1](choiceButtons[index], choice)
            assert(width == 134 and height == 20, "radio styling changed the native text or row height")
            assert(not choiceButtons[index].leftTexture1:IsShown()
                and not choiceButtons[index].leftTexture2:IsShown()
                and choiceButtons[index].fontString.points[1][4] == 26,
                "radio and checkbox choices must remove indicators and align labels after the state art")
            local expected = index == 3 and "Checked.tga" or index == 2 and "Unselected.tga" or "Selected.tga"
            assert(choiceButtons[index].FFXIVUICheckArt.texture:find(index == 3 and "Checkboxes" or "Radio-Buttons", 1, true)
                and choiceButtons[index].FFXIVUICheckArt.texture:find(expected, 1, true),
                "selected radio and checkbox choices must use the reference state textures")
        end
        choiceButtons[index].scripts.OnClick()
    end
    for _, highlights in ipairs(choiceHighlights) do
        assert(#highlights == 0, "checkbox and radio choices must not use highlight bands")
    end
    choices[2].selected = true
    choices[2].initializers[1](choiceButtons[2], choices[2])
    assert(choiceButtons[2].FFXIVUICheckArt.texture:find("Selected.tga", 1, true) and pickedChoices == 3,
        "menu reinitialization must reflect the current selection without replacing native clicks")
    filter:OnMenuClosed(menu)
    assert(closeCalls == 1 and not filter:IsMenuOpen()
        and combo[1].texture:find("ComboBox-Closed-Dark.tga", 1, true),
        "closing the combo box must retain native callbacks and restore the closed reference")
    filter:OnMenuOpened(menu)
    filter:OnMenuClosed(menu)
    assert(menuFontCount == 1, "reopening a combo box must reuse its addon-owned menu font object")
    CreateFont = originalCreateFont
    filter:UpdateText()
    filter:OnButtonStateChanged()
    assert(filter.Text.text == "All Characters" and not filter.Arrow:IsShown(),
        "native selection and button-state updates must preserve the extracted combo-box skin")
    filter:SetEnabled(false)
    assert(combo[1].alpha == 0.5, "disabled combo box must dim its extracted artwork")
    filter:SetEnabled(true)
    local comboCount = #created
    CharacterFrame:Hide()
    CharacterFrame:Show()
    assert(#created == comboCount, "character relayout duplicated combo-box artwork")
    local reputationPage = object("Frame", CharacterFrame)
    reputationPage.FilterDropdown = object("Frame", reputationPage)
    reputationPage.FilterDropdown.OnMenuOpened = function() end
    reputationPage.FilterDropdown.OnMenuClosed = function() end
    CharacterFrame.ReputationFrame = reputationPage
    CharacterFrame.activeSubframe = "ReputationFrame"
    GetFileIDFromPath = nil
    CharacterFrame:Hide()
    CharacterFrame:Show()
    assert(reputationPage.FilterDropdown.FFXIVUIComboBox,
        "reputation filter must load extracted textures without the file-ID lookup API")
    MenuUtil = originalMenuUtil
    GetFileIDFromPath = originalFileIDLookup
    CharacterFrame.activeSubframe = "PaperDollFrame"
    CharacterFrame:Hide()
    CharacterFrame:Show()
end
print("PASS native currency transfer log is anchored left of the character dropdown")
print("PASS extracted reputation/currency combo boxes preserve native states, menus, labels and missing-asset fallback")
interfaceVersion = 16001
CharacterFrame = object()
local foreverWatcherCount = #created
assert(loadfile("FFXIV_UI\\General\\CharacterFrame.lua"))("FFXIV_UI", namespace)
local foreverWatcher = created[foreverWatcherCount + 1]
foreverWatcher.scripts.OnEvent(foreverWatcher, "ADDON_LOADED", "FFXIV_UI")
assert(#CharacterFrame.children == 0, "hostless Forever character panel must remain unchanged")
watcher = foreverWatcher
interfaceVersion = 120000
print("PASS hostless Forever panels are excluded from the Retail fallback")

local root = CharacterFrame
root.nativeHeader = root:CreateTexture()
root.width, root.activeSubframe = 631, "PaperDollFrame"
root.NineSlice, root.PortraitContainer, root.TitleContainer = object(), object(), object()
root.CloseButton = object("Frame", root)
root.RightPaneToggleButton = object("Button", root)
root.RightPaneToggleButton.NativeArt = root.RightPaneToggleButton:CreateTexture()
root.RightPaneToggleButton.scripts.OnClick = function() return "native collapse" end
root.CloseButton.nativeArt = root.CloseButton:CreateTexture()
root.CloseButton.scripts.OnClick = function() root:Hide() end
root.LeftPaneHost, root.RightPaneHost = object("Frame", root), object("Frame", root)
root.LeftPaneHost.width, root.RightPaneHost.width = 398, 233
root.LeftPaneHost.art = root.LeftPaneHost:CreateTexture()
root.RightPaneHost.StoneBg = root.RightPaneHost:CreateTexture()
root.ModeTabs = object("Frame", root)
root.ModeTabs.Tabs = {}
local nativeClicks = 0
for index, label in ipairs({"Character", "Reputation", "Skills", "Player vs. Player", "Currency", "Statistics"}) do
    local tab = object("Frame", root.ModeTabs)
    tab.noClickScript = true
    tab.tooltipText, tab.frameName = label, index == 1 and "PaperDollFrame" or label .. "Frame"
    if index == 4 then tab.frameName = "PVPRankFrame" end
    for _, key in ipairs({"Icon", "Background", "SelectedTexture", "HighlightTexture", "TabGlow"}) do
        tab[key] = tab:CreateTexture()
    end
    function tab:SetChecked(value) self.SelectedTexture:SetShown(value) end
    tab.scripts.OnMouseUp = function(self)
        nativeClicks = nativeClicks + 1
        root.activeSubframe = self.frameName
        root:RefreshDisplay()
    end
    root.ModeTabs.Tabs[index] = tab
end
function root:IsRightPaneCollapsed() return self.collapsed == true end
function root:UpdateSize() self:SetSize(self.collapsed and 398 or 631, 484) end
function root:UpdateTabLayout()
    for _, tab in ipairs(self.ModeTabs.Tabs) do tab:ClearAllPoints(); tab:SetPoint("TOPLEFT", self.ModeTabs) end
end
local nativeModeSelection, modeSelections = false, 0
function root:SetSelectedModeTabByFrame(name)
    assert(nativeModeSelection, "addon installation must not enter Blizzard's mode-selection refresh path")
    modeSelections = modeSelections + 1
    for _, tab in ipairs(self.ModeTabs.Tabs) do tab:SetChecked(tab.frameName == name) end
end
function root:UpdateTitle() end
function root:SetUIPanelAttribute()
    error("addon layout must not write Blizzard's UIPanelLayout attributes")
end
function root:SetupGamepad()
    self.TabIndicators.isVertical = true
    self.leftFooter = {}
    for index, button in ipairs(PaperDollItemsFrame.EquipmentSlots) do
        if index > 8 then SmartNavigation_AddJumpNavigationOverride(button, "right", "native wrong-side jump") end
    end
end
function root:SwapToLeftSide() self.focus = "equipment" end
function root:SwapToRightSide() self.focus = "details" end
function root:RightSideSwapSmartNavigationJumpOverride()
    if self.equipmentSets then return self.equipmentSets end
end
function root:RefreshDisplay()
    self:UpdateSize()
    self:UpdateTitle()
    nativeModeSelection = true
    self:SetSelectedModeTabByFrame(self.activeSubframe)
    nativeModeSelection = false
end
root.TabIndicators = object()
function root.TabIndicators:UpdateTabVisibility() self.updated = (self.updated or 0) + 1 end
local contentPages = {}
for index = 2, #root.ModeTabs.Tabs do
    local name = root.ModeTabs.Tabs[index].frameName
    local page = object("Frame", root.LeftPaneHost)
    page:SetSize(398, 402)
    page.ScrollBox, page.Inset, page.FilterBar = object("Frame", page), object("Frame", page), object("Frame", page)
    page.ScrollBox:SetSize(350, 320)
    page.Inset:SetSize(386, 390)
    page.FilterBar:SetSize(374, 26)
    page.ScrollBar = object("Frame", page)
    page.ScrollBar:SetSize(12, 320)
    page.nativeShowCount = 0
    page.scripts.OnShow = function(self) self.nativeShowCount = self.nativeShowCount + 1 end
    root[name], _G[name], contentPages[index] = page, page, page
end
PaperDollFrame = object("Frame", root)
PaperDollFrame.TopBackgroundStripHost = object("Frame", PaperDollFrame)
PaperDollFrame.TopBackgroundStripHost.TopBackgroundStrip = PaperDollFrame.TopBackgroundStripHost:CreateTexture()
PaperDollFrame.CharacterModelScene = object("Frame", PaperDollFrame)
local model = PaperDollFrame.CharacterModelScene
model.art, model.ControlFrame = model:CreateTexture(), object("Frame", model)
local function pane()
    local result = object("Frame", root)
    result.Border, result.ClassBackground = result:CreateTexture(), result:CreateTexture()
    result.ScrollBox = object("Frame", result)
    result.ScrollBar = object("Frame", result)
    result.ScrollBox.rows = {}
    local header, stat = object(), object()
    header.Title, header.Background = header:CreateFontString(), header:CreateTexture()
    stat.Label, stat.Value, stat.Background = stat:CreateFontString(), stat:CreateFontString(), stat:CreateTexture()
    stat.Value.color, stat.Value.text = {0, 1, 0}, "36"
    stat.scripts.OnEnter = function() return "native stat tooltip" end
    result.ScrollBox.rows = {header, stat}
    result.elementData = {
        {isHeader = true, name = "General"},
        {name = "HEALTH", unit = "player", value = 306},
        {name = "POWER", unit = "player", value = 419},
        {isHeader = true, name = "Primary Attributes"},
        {name = "STRENGTH", unit = "player", value = 36, color = {0, 1, 0}},
        {isHeader = true, name = "Weapons"},
        {name = "MAINHAND_DAMAGE", unit = "player", valueText = "26 - 37"},
        {isHeader = true, name = "Modifiers"},
        {name = "CRITCHANCE", unit = "player", valueText = "5%"},
        {name = "SPELLPOWER", unit = "player", value = 15},
        {isHeader = true, name = "Defense"},
        {name = "ARMOR", unit = "player", value = 200},
        {isHeader = true, name = "Resistances"},
        {labelText = "Fire", valueText = "0", tooltip = "Fire resistance tooltip", statIndex = 1},
    }
    local index = 0
    for _, data in ipairs(result.elementData) do
        if data.isHeader then index = 0 else index = index + 1; data.statIndex = index end
    end
    function result:UpdateStats() self.updates = (self.updates or 0) + 1 end
    return result
end
CharacterStatsPaneScrollBox, CharacterStatsPanePetScrollBox = pane(), pane()
PaperDollFrame.EquipmentManagerPane = pane()
for _, key in ipairs({"EquipSet", "SaveSet"}) do
    local button = object("Button", PaperDollFrame.EquipmentManagerPane)
    button.Text = button:CreateFontString(nil, nil, "GameFontNormal")
    button.scripts.OnClick = function() return key end
    PaperDollFrame.EquipmentManagerPane[key] = button
end
PaperDollSidebarTabs, PaperDollLevelInfo = object(), object()
PaperDollSidebarTab1, PaperDollSidebarTab2, PaperDollSidebarTab3 = object(), object(), object()
local sidebarButtons = {PaperDollSidebarTab1, PaperDollSidebarTab2, PaperDollSidebarTab3}
local sidebarClicks, sidebarTooltips = {}, {}
for index, sidebar in ipairs(sidebarButtons) do
    sidebar:SetSize(36, 36)
    sidebar.Icon = sidebar:CreateTexture()
    sidebar.Icon:SetTexture("native sidebar")
    sidebar.CircleMask = sidebar:CreateTexture()
    sidebar.TabBg = sidebar:CreateTexture()
    sidebar.NativeNormal = sidebar:CreateTexture()
    function sidebar:GetNormalTexture() return self.NativeNormal end
    sidebar.Highlight = sidebar:CreateTexture()
    sidebar.scripts.OnClick = function() sidebarClicks[index] = (sidebarClicks[index] or 0) + 1 end
    sidebar.scripts.OnEnter = function() return "native sidebar tooltip" end
    sidebarTooltips[index] = sidebar.scripts.OnEnter
end
CharacterLevelTextBackground, CharacterLevelText = object("Texture"), object("FontString")
CharacterLevelTextBackground.parent = PaperDollLevelInfo
table.insert(PaperDollLevelInfo.regions, CharacterLevelTextBackground)
PaperDollLevelInfo.SetBackdrop = false
PaperDollItemsFrame = object("Frame", PaperDollFrame)
PaperDollItemsFrame.EquipmentSlots, PaperDollItemsFrame.WeaponSlots = {}, {}
for index = 1, 19 do
    local button = object("Frame", PaperDollItemsFrame)
    button.BorderFrame = object("Frame", button)
    button.BorderFrame.art = button.BorderFrame:CreateTexture()
    button.scripts.OnClick = function() return "native equip" end
    local slots = index <= 16 and PaperDollItemsFrame.EquipmentSlots or PaperDollItemsFrame.WeaponSlots
    slots[#slots + 1] = button
end
CharacterAmmoSlot = object("Frame", PaperDollItemsFrame)
function PaperDollItemSlotButton_Update(button) button.updates = (button.updates or 0) + 1 end
combat = true
root.protected = true
local before = #created
event("ADDON_LOADED")
assert(#created == before and root.height == nil, "installation changed protected geometry in combat")
combat = false
root.protected = nil
event("PLAYER_REGEN_ENABLED")
assert(root.height == 530 and root.width == 838 and root.panelWidth == nil,
    "host-based character layout dimensions were unexpected (width: " .. tostring(root.width)
        .. ", height: " .. tostring(root.height) .. ")")
assert(modeSelections == 0, "installation must style selection without invoking native mode selection")
assert(root.LeftPaneHost.points[1][4] == 440 and root.RightPaneHost.points[1][4] == 0,
    "host-based pane origins were unexpected (left: " .. tostring(root.LeftPaneHost.points[1][4])
        .. ", right: " .. tostring(root.RightPaneHost.points[1][4]) .. ")")
assert(root.LeftPaneHost.points[1][5] == -66)
assert(not root.NineSlice.shown and root.PortraitContainer.alpha == 0)
root.NineSlice:SetAlpha(1)
root.NineSlice:Show()
root.LeftPaneHost.art:SetAlpha(1)
root.LeftPaneHost.art:Show()
root.RightPaneHost.StoneBg:SetShown(true)
assert(not root.NineSlice.shown and not root.LeftPaneHost.art.shown and not root.RightPaneHost.StoneBg.shown,
    "native pane and nine-slice refresh must not restore the collapse header strip")
assert(root.CloseButton.nativeArt.alpha == 0 and root.CloseButton.scripts.OnClick ~= nil)
assert(root.CloseButton.FFXIVUICloseIcon.texture == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Close.tga")
assert(root.CloseButton.FFXIVUICloseIcon.allPoints == root.CloseButton)
assert(not root.LeftPaneHost.art.shown and root.RightPaneHost.StoneBg.alpha == 0 and model.art.alpha == 0)
assert(not root.nativeHeader.shown and not model.art.shown)
root.nativeHeader:SetAlpha(1)
root.nativeHeader:Show()
model.art:SetShown(true)
assert(not root.nativeHeader.shown and not model.art.shown, "native refresh restored the old header artwork")
assert(model.points[2][4] == -8 and model.points[2][5] == 8,
    "model panel must sit inside the right and bottom window borders")
assert(model.points[1][1] == "TOPLEFT" and model.points[1][2] == PaperDollLevelInfo
    and model.points[1][3] == "BOTTOMLEFT" and model.points[1][4] == 0 and model.points[1][5] == -4,
    "model viewport must start below the banner and share its left edge")
local modelBorder = model.children[#model.children]
assert(modelBorder.allPoints == model and modelBorder.FFXIVUIOutline and #modelBorder.FFXIVUIOutline == 8,
    "paperdoll outline must frame the model viewport, not the full pane (which runs past the banner)")
local modelBackground = model.regions[#model.regions]
assert(modelBackground.points[1][2] == modelBorder,
    "paperdoll rounded fill must use the model-sized frame so its corners match the outline")

assert(root.TabIndicators.isVertical == false and root.TabIndicators.updated > 0)
assert(PaperDollLevelInfo.points[1][2] == root.LeftPaneHost)
assert(model.ControlFrame.points[1][2] == PaperDollLevelInfo
    and model.ControlFrame.points[1][3] == "BOTTOM" and model.ControlFrame.points[1][5] == -4,
    "model controls must start below the class banner, not overlap it")
local banner = PaperDollLevelInfo
local strip = PaperDollFrame.TopBackgroundStripHost
strip:Show()
strip:SetShown(true)
assert(not strip.shown, "native top background strip host must stay hidden after native refreshes")
banner:SetFrameStrata("HIGH")
banner:SetFrameLevel(520)
assert(root.RightPaneToggleButton:GetFrameStrata() == "HIGH"
    and root.RightPaneToggleButton:GetFrameLevel() == 521,
    "collapse button must render above the native high-strata level panel")
assert(banner.height == 48 and banner.points[1][4] == -1 and banner.points[1][5] == 2
    and banner.points[2][4] == -8 and banner.points[2][5] == 2,
    "class plate must extend to the divider and rise over the underlying top corners")
assert(banner.FFXIVUIBanner == nil, "native panel must be restyled directly without an overlay frame")
assert(root.RightPaneToggleButton.points[1][2] == banner
    and root.RightPaneToggleButton.scripts.OnClick() == "native collapse")
local paneArrow = root.RightPaneToggleButton.FFXIVUISideArrow
local circularArrow = assert(root.RightPaneToggleButton.FFXIVUICircularArrow)
local arrowShadow = circularArrow.shadow
assert(paneArrow == circularArrow.glyph and arrowShadow.texture == paneArrow.texture)
assert(paneArrow.texture:find("Arrow-Button-Glyph.tga", 1, true) and circularArrow.direction == "left"
    and paneArrow.points[1][4] == -2 * 26 / 32,
    "expanded character pane must use the approved left-facing circular arrow and optical centering")
assert(circularArrow.base.texture:find("Arrow-Button-Circle.tga", 1, true))
assert(root.RightPaneToggleButton.width == 26 and root.RightPaneToggleButton.NativeArt.shown == false)
root.RightPaneToggleButton.NativeArt:Show()
assert(not root.RightPaneToggleButton.NativeArt.shown, "native toggle artwork returned over the extracted arrow")
root.RightPaneToggleButton.scripts.OnEnter()
assert(paneArrow.vertexColor[1] == 1.18)
root.RightPaneToggleButton.scripts.OnLeave()
assert(paneArrow.vertexColor[1] == 1)
root.RightPaneToggleButton:SetEnabled(false)
assert(paneArrow.vertexColor[4] == 0.4)
root.RightPaneToggleButton:SetEnabled(true)
assert(paneArrow.vertexColor[4] == 1)
CharacterLevelTextBackground:Show()
assert(not CharacterLevelTextBackground.shown, "native level background must not return")
assert(banner.Level.text == "Level 12" and banner.ClassName.text == "Paladin")
assert(banner.Level.font[2] == 11 and banner.ClassName.font[2] == 20)
assert(banner.ClassIcon.texCoords[3] == 0.5 and CharacterLevelText.alpha == 0)
assert(banner.Level.template == "FFXIV_CharacterLevelTemplate"
    and banner.ClassName.template == "FFXIV_CharacterClassNameTemplate"
    and banner.ClassIcon.template == "FFXIV_CharacterClassIconTemplate"
    and banner.ClassIcon.width == 24 and banner.ClassIcon.height == 24
    and banner.Level.points[1][4] == 13 and banner.Level.points[1][5] == -5
    and banner.Level.points[2][4] == -38 and banner.ClassName.points[1][4] == -38,
    "banner text and icon must come from the XML templates")
playerLevel, effectiveLevel = 13, 10
PaperDollFrame_SetLevel()
assert(banner.Level.text == "Level 10 (13)", "effective level must remain visible")
PaperDollFrame_SetPetLevel()
assert(banner.shown and not banner.Level.shown and not banner.ClassName.shown
    and not banner.ClassIcon.shown and CharacterLevelText.alpha == 1, "pet label must remain native")
PaperDollFrame_SetLevel()
assert(banner.Level.shown and banner.ClassName.shown and banner.ClassIcon.shown and CharacterLevelText.alpha == 0)
print("PASS two-line localized class banner, native class icon, effective levels and pet label restoration")
assert(PaperDollSidebarTabs.height == 46)
local sidebarNames = {"CharacterStatus", "EquipmentManager", "Titles"}
local nativeInputUtil = InputUtil
InputUtil = {IsGamepadUIEnabled = function() return false end}
for index, sidebar in ipairs(sidebarButtons) do
    local expected = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\Sidebar-" .. sidebarNames[index] .. "-Dark.tga"
    assert(sidebar.Icon.texture == expected and sidebar.Icon.removedMask == sidebar.CircleMask)
    assert(sidebar.TabBg.alpha == 0 and sidebar.NativeNormal.alpha == 0,
        "native sidebar outline remains behind the extracted button")
    sidebar.TabBg:SetAlpha(1)
    sidebar.NativeNormal:SetAlpha(1)
    assert(sidebar.TabBg.alpha == 0 and sidebar.NativeNormal.alpha == 0,
        "native refresh restored duplicate sidebar decoration")
    assert(sidebar.Highlight.alpha == 1, "native sidebar highlight was suppressed")
    assert(sidebar.Icon.width == 36 and sidebar.Icon.height == 36
        and sidebar.Icon.points[1][2] == sidebar, "sidebar artwork uses inconsistent native dimensions")
    sidebar.Icon:SetTexture("refreshed native sidebar")
    sidebar.Icon:SetAtlas("refreshed native atlas")
    sidebar.Icon:SetTexCoord(0.2, 0.4, 0.6, 0.8)
    assert(sidebar.Icon.texture == expected and sidebar.Icon.texCoords[1] == 0 and sidebar.Icon.texCoords[2] == 1)
    SetPortraitTexture(sidebar.Icon)
    assert(sidebar.Icon.texture == expected, "native portrait refresh restored the old sidebar icon")
    sidebar:SetEnabled(false)
    assert(sidebar.Icon.desaturated)
    sidebar:SetEnabled(true)
    assert(not sidebar.Icon.desaturated)
    sidebar.scripts.OnClick(sidebar)
    assert(sidebarClicks[index] == 1 and sidebar.scripts.OnEnter == sidebarTooltips[index])
end
InputUtil = nativeInputUtil
local unrelatedPortrait = object("Texture")
SetPortraitTexture(unrelatedPortrait)
assert(unrelatedPortrait.texture == "native portrait", "sidebar skin replaced an unrelated portrait")
print("PASS ordered FFXIV sidebar icons, native refreshes, masks, disabled states, clicks and tooltips")
for index, tab in ipairs(root.ModeTabs.Tabs) do
    assert(tab.width == (838 - 44 + 30) / 6 and tab.height == 24)
    assert(tab.points[1][4] == (index - 1) * (tab.width - 6))
    if index > 1 then
        local previous = root.ModeTabs.Tabs[index - 1]
        assert(tab.points[1][4] == previous.points[1][4] + previous.width - 6,
            "angled tabs do not interlock by the intended six pixels")
    end
    assert(not tab.Icon:IsShown() and not tab.SelectedTexture:IsShown())
    local panel = tab.children[1]
    assert(panel.regions[1].text == tab.tooltipText and panel.mouse == false)
    assert(panel.regions[1].points[1][4] == 18, "tab label lacks marker padding")
    local state = index == 1 and "Selected" or "Inactive"
    assert(panel.regions[2].texture:find("Tab-" .. state .. "-Dark.tga", 1, true),
        "selected/unselected extracted tab state incorrect")
    assert(not panel.backdrop, "square backdrop remained behind pointed tabs")
    assert(#panel.FFXIVUITabArt.fill == 3 and #panel.FFXIVUITabArt.border == 0 and #panel.regions == 4,
        "drawn border or duplicate indicator remains over extracted artwork")
    assert(panel.FFXIVUITabArt.fill[1].width == 23 and panel.FFXIVUITabArt.fill[3].width == 17,
        "tab endcaps must not stretch with tab width")
    assert(panel.regions[2].texCoords[1] == 39 / 512 and panel.regions[2].texCoords[3] == 10 / 64
        and panel.regions[2].texCoords[4] == 53 / 64, "transparent texture padding was not cropped")
end
print("PASS expanded character page uses stats left, model right, and six horizontal labeled native tabs")
for _, key in ipairs({"EquipSet", "SaveSet"}) do
    local button = PaperDollFrame.EquipmentManagerPane[key]
    local art = button.children[1].FFXIVUIControlArt
    assert(art.fill[1].texture:find("Button-fill-Standard.tga", 1, true))
    assert(button.scripts.OnClick() == key, "capsule styling replaced native equipment-set action")
    button.scripts.OnEnter(button)
    button:SetEnabled(false)
    assert(art.fill[1].texture:find("Button-fill-Disabled-Standard.tga", 1, true)
        and art.border[1].texture:find("Button-border-Disabled-Standard.tga", 1, true)
        and art.fill[1].color[1] == namespace.Themes.GetPalette().tab[1],
        "disabled buttons must use the extracted disabled artwork")
    button:SetEnabled(true)
    assert(art.fill[1].texture:find("Button-fill-Standard.tga", 1, true)
        and art.border[1].texture:find("Button-border-Standard.tga", 1, true)
        and art.fill[1].color[1] == namespace.Themes.GetPalette().selected[1],
        "enabled buttons must restore the extracted enabled artwork")
    button.scripts.OnLeave(button)
end

local reputation = root.ModeTabs.Tabs[2]
reputation.scripts.OnMouseUp(reputation)
assert(nativeClicks == 1 and root.activeSubframe == "ReputationFrame")
assert(root.LeftPaneHost.points[1][4] == 0 and root.RightPaneHost.points[1][4] == 540)
assert(root.width == 540 and root.LeftPaneHost.width == 540 and root.RightPaneHost.width == 233,
    "non-Character tab did not use the fixed page width")
interfaceVersion = 16001
local detailShown = false
local reputationDetail = object("Frame")
reputationDetail.IsShown = function() return detailShown end
_G.ReputationFrame = {ReputationDetailFrame = reputationDetail}
local function FindSeam(frame)
    for _, child in ipairs(frame.children or {}) do
        for _, region in ipairs(child.regions or {}) do
            local point = region.points and region.points[1]
            if point and point[1] == "TOPLEFT" and point[4] == 535 and point[5] == -30 then return region end
        end
    end
end
root:RefreshDisplay()
local seam = FindSeam(root)
assert(root.width == 540 and seam and not seam.shown, "the seam must stay hidden while the detail panel is closed")
detailShown = true
root:RefreshDisplay()
assert(root.width == 786, "the main panel must expand behind the open detail panel, got " .. tostring(root.width))
assert(root.ModeTabs.width == 496, "the tab row must keep its page width while the detail panel is open, got " .. tostring(root.ModeTabs.width))
assert(reputationDetail.points[1][1] == "TOPLEFT" and reputationDetail.points[1][4] == 545
    and reputationDetail.points[1][5] == -66 and reputationDetail.width == 233,
    "the detail panel must sit right of the seam below the header")
assert(seam.shown and seam.width == 1 and seam.points[2][5] == 10 and seam.points[2][4] == 535,
    "the seam must run from the header divider to 10px above the bottom while expanded")
detailShown = false
root:RefreshDisplay()
assert(root.width == 540 and not seam.shown, "closing the detail panel must collapse the main panel and hide the seam")
local skillDetail = object("Frame")
skillDetail.IsShown = function() return true end
_G.SkillsFrame = {SkillDetailFrame = skillDetail}
root.activeSubframe = "SkillsFrame"
root:RefreshDisplay()
assert(root.width == 786 and seam.shown, "the Skills detail panel must expand the main panel like Reputation")
assert(skillDetail.points[1][1] == "TOPLEFT" and skillDetail.points[1][4] == 545
    and skillDetail.points[1][5] == -66 and skillDetail.width == 233,
    "the Skills detail panel must sit right of the seam below the header")
root.activeSubframe = "ReputationFrame"
root:RefreshDisplay()
assert(root.width == 540 and not seam.shown, "a hidden Reputation detail must not keep the Skills expansion")
_G.SkillsFrame = nil
local pvpDetail = object("Frame")
pvpDetail.IsShown = function() return true end
_G.PVPRankFrame = {DetailFrame = pvpDetail}
root.activeSubframe = "PVPRankFrame"
root:RefreshDisplay()
assert(root.width == 786 and seam.shown, "the PvP detail pane must expand the main panel like Reputation")
assert(pvpDetail.points[1][1] == "TOPLEFT" and pvpDetail.points[1][4] == 545
    and pvpDetail.points[1][5] == -66 and pvpDetail.width == 233,
    "the PvP detail pane must sit right of the seam below the header")
root.activeSubframe = "ReputationFrame"
root:RefreshDisplay()
_G.PVPRankFrame = nil
local tokenDetail = object("Frame")
tokenDetail.IsShown = function() return true end
_G.TokenFrame = object("Frame")
_G.TokenFrame.DetailFrame = tokenDetail
root.activeSubframe = "TokenFrame"
root:RefreshDisplay()
assert(root.width == 786 and seam.shown, "the Currency detail pane must expand the main panel like Reputation")
assert(tokenDetail.points[1][1] == "TOPLEFT" and tokenDetail.points[1][4] == 545
    and tokenDetail.points[1][5] == -66 and tokenDetail.width == 233,
    "the Currency detail pane must sit right of the seam below the header")
root.activeSubframe = "ReputationFrame"
root:RefreshDisplay()
_G.TokenFrame = nil
_G.ReputationFrame = nil
interfaceVersion = 120000
assert(reputation.children[1].regions[2].texture:find("Tab-Selected-Dark.tga", 1, true)
    and root.ModeTabs.Tabs[1].children[1].regions[2].texture:find("Tab-Inactive-Dark.tga", 1, true))
local reputationArt = reputation.children[1].regions[2]
reputation.scripts.OnEnter(reputation)
assert(reputationArt.vertexColor[1] == 1.12)
reputation.scripts.OnLeave(reputation)
assert(reputationArt.vertexColor[1] == 1)
local inactiveTab = root.ModeTabs.Tabs[1]
inactiveTab.scripts.OnEnter(inactiveTab)
assert(inactiveTab.children[1].regions[2].texture:find("Tab-Inactive-Dark.tga", 1, true),
    "hover shows a selected indicator on an inactive tab")
inactiveTab.scripts.OnLeave(inactiveTab)
reputation.SelectedTexture:Show()
reputation.HighlightTexture:SetShown(true)
assert(not reputation.SelectedTexture.shown and not reputation.HighlightTexture.shown)
local charTab = root.ModeTabs.Tabs[1]
charTab.scripts.OnMouseUp(charTab)
assert(nativeClicks == 2 and root.LeftPaneHost.points[1][4] == 440)
for index = 2, #root.ModeTabs.Tabs do
    local page = contentPages[index]
    root.activeSubframe = root.ModeTabs.Tabs[index].frameName
    for _ = 1, 3 do root:RefreshDisplay() end
    assert(root.width == 540 and root.LeftPaneHost.width == 540 and root.RightPaneHost.width == 233)
    assert(page.allPoints == root.LeftPaneHost and page.width == 540,
        "active content container did not follow the fixed page width")
    assert(page.ScrollBox.width == 492 and page.Inset.width == 528 and page.FilterBar.width == 516,
        "fixed-width page contents did not widen by the pane-width increase")
    assert(page.ScrollBar.width == 12 and page.nativeShowCount == 0,
        "page layout resized the scrollbar or invoked a native show callback")
    local pvpLabel = root.ModeTabs.Tabs[4].children[1].regions[1]
    assert(not pvpLabel.wrap and pvpLabel.maxLines == 1 and pvpLabel.height == 20
        and pvpLabel.width == root.ModeTabs.Tabs[4].width - 30,
        "non-Character tab labels are not single-line at the fixed page width")
end
root.activeSubframe = "PaperDollFrame"
root:RefreshDisplay()
assert(root.LeftPaneHost.width == 398 and root.RightPaneHost.width == 440 and root.width == 838,
    "returning to Character did not restore its original pane widths")
root.collapsed = true
root:RefreshDisplay()
assert(circularArrow.direction == "right" and paneArrow.texCoords[1] == 1 and paneArrow.texCoords[2] == 0,
    "collapsed character pane must show the right-facing arrow")
assert(arrowShadow.texCoords[1] == paneArrow.texCoords[1] and arrowShadow.texCoords[2] == paneArrow.texCoords[2],
    "arrow shadow did not mirror with the collapse arrow")
assert(root.width == 407 and root.LeftPaneHost.points[1][4] == 9 and root.height == 484 + 46 + 33,
    "collapsed paperdoll must keep the same 8px padding on the left as on the right")
assert(root.LeftPaneHost.points[1][5] == -99 and root.RightPaneHost.points[1][5] == -99)
assert(charTab.width == (407 - 44 + 12) / 3 and root.ModeTabs.height == 57)
for index, tab in ipairs(root.ModeTabs.Tabs) do
    local label = tab.children[1].regions[1]
    assert(label.font[2] == 10 and label.wrap, "collapsed label was shrunk instead of given room")
    assert(label.width == tab.width - 30 and label.height == 28 and label.maxLines == 2,
        "collapsed label lacks a bounded two-line area")
    assert(tab.points[1][4] == ((index - 1) % 3) * (tab.width - 6))
    assert(tab.points[1][5] == -math.floor((index - 1) / 3) * 33)
end
root.ModeTabs.Tabs[5]:Hide()
assert(charTab.width == (407 - 44 + 12) / 3, "hidden tabs changed the three-column layout")
assert(root.ModeTabs.Tabs[6].points[1][4] == charTab.width - 6
    and root.ModeTabs.Tabs[6].points[1][5] == -33, "hidden tabs left a gap")
root.ModeTabs.Tabs[5]:Show()
root.collapsed = false
root:RefreshDisplay()
assert(circularArrow.direction == "left" and paneArrow.texCoords[1] == 0 and paneArrow.texCoords[2] == 1)
root:UpdateTabLayout()
root:SetupGamepad()
assert(root.height == 530 and root.ModeTabs.height == 24 and root.LeftPaneHost.points[1][5] == -66)
for _, tab in ipairs(root.ModeTabs.Tabs) do
    local label = tab.children[1].regions[1]
    assert(tab.points[1][5] == 0, "expanded buttons did not return to one row")
    assert(not label.wrap and label.maxLines == 1 and label.width == tab.width - 30
        and label.height == 20 and label.justifyV == "MIDDLE" and label.font[2] == 10,
        "expanded labels must stay on one line without shrinking")
end
assert(charTab.points[1][4] == 0 and root.ModeTabs.Tabs[2].points[1][4] > 0)
assert(root.TabIndicators.isVertical == false)
local firstSlot, lastSlot = PaperDollItemsFrame.EquipmentSlots[1], PaperDollItemsFrame.EquipmentSlots[16]
assert(lastSlot.jumps.right == nil and type(firstSlot.jumps.left) == "function")
root.equipmentSets = {}
assert(firstSlot.jumps.left() == root.equipmentSets)
firstSlot.callbacks.left[1]()
assert(root.focus == "details")
CharacterStatsPaneScrollBox.FFXIVUISections.statRows["player:ARMOR:"].callbacks.right[1]()
assert(root.focus == "equipment")
local gearRow = PaperDollFrame.EquipmentManagerPane.ScrollBox.rows[1]
PaperDollFrame.EquipmentManagerPane.ScrollBox.Updated()
gearRow.callbacks.right[1]()
assert(root.focus == "equipment" and #gearRow.callbacks.right == 1)
local newEquipmentRow = object("Button", PaperDollFrame.EquipmentManagerPane.ScrollBox)
table.insert(PaperDollFrame.EquipmentManagerPane.ScrollBox.rows, newEquipmentRow)
PaperDollFrame.EquipmentManagerPane.ScrollBox.Updated()
PaperDollFrame.EquipmentManagerPane.ScrollBox.Updated()
assert(#newEquipmentRow.callbacks.right == 1, "new equipment-set row has missing or duplicate navigation callbacks")
newEquipmentRow.callbacks.right[1]()
assert(root.focus == "equipment", "new equipment-set row cannot navigate back to equipment")
root:SetupGamepad()
assert(#firstSlot.callbacks.left == 1 and lastSlot.jumps.right == nil)
print("PASS native tab clicks, selection, hidden tabs, collapse, expansion and controller indicator orientation")
print("PASS controller pane crossing follows the reversed layout without duplicate callbacks or wrong-side jumps")

local sections = CharacterStatsPaneScrollBox.FFXIVUISections
for _, statsPane in ipairs({CharacterStatsPaneScrollBox, CharacterStatsPanePetScrollBox}) do
    local nativeUpdates = statsPane.updates
    local existingRows = #created
    for _ = 1, 3 do
        statsPane:Hide()
        statsPane:Show()
    end
    assert(statsPane.updates == nativeUpdates,
        "addon OnShow must not invoke Blizzard's native stats updater")
    assert(#created == existingRows, "reopening stats duplicated custom rows")
end
print("PASS stats-pane show hooks rebuild custom rows without invoking native stat refreshes")
assert(not CharacterStatsPaneScrollBox.ScrollBox.shown and not CharacterStatsPaneScrollBox.ScrollBar.shown)
CharacterStatsPaneScrollBox.ScrollBox:Show()
CharacterStatsPaneScrollBox.ScrollBar:SetShown(true)
assert(not CharacterStatsPaneScrollBox.ScrollBox.shown and not CharacterStatsPaneScrollBox.ScrollBar.shown)
assert(#sections.rows == 11, "health and power must move out of the native stat list")
assert(not sections.statRows["player:HEALTH:"] and not sections.statRows["player:POWER:"])
local resources = sections.Resources
assert(resources.width == 416 and resources.height == 62)
assert(resources.Health.Current.text == "250" and resources.Health.Maximum.text == "306")
assert(resources.Power.Current.text == "100" and resources.Power.Maximum.text == "419")
assert(resources.Health.Bar.value == 250 and resources.Health.Bar.range[2] == 306)
local petResources = CharacterStatsPanePetScrollBox.FFXIVUISections.Resources
assert(petResources.Health.Current.text == "80" and petResources.Health.Maximum.text == "120")
local initialResourceCount = #created
combat = true
healthValue, healthMax, powerValue, powerMax, powerToken = 37, 450, 55, 100, "ENERGY"
resources.scripts.OnEvent(resources, "UNIT_HEALTH", "player")
assert(resources.Health.Current.text == "37" and resources.Health.Maximum.text == "450")
assert(resources.Power.Label.text == "Energy" and resources.Power.Current.text == "55"
    and resources.Power.Maximum.text == "100" and resources.Power.Bar.value == 55)
assert(resources.Power.Bar.statusColor[1] == 1 and resources.Power.Bar.statusColor[2] == 1)
assert(#created == initialResourceCount and resources.events.UNIT_HEALTH == "player",
    "live combat resource updates must not recreate or relayout controls")
powerToken = "MANA"
resources.scripts.OnShow(resources)
assert(resources.Power.Label.text == "MP", "showing the pane must restore current power type")
combat = false
print("PASS full-width live current/max HP and active power row, combat events, power swaps and separate pet resources")
table.insert(CharacterStatsPaneScrollBox.elementData, 4,
    {name = "MOVESPEED", unit = "player", valueText = "100%", statIndex = 3})
CharacterStatsPaneScrollBox:UpdateStats()
assert(sections.headers[1].shown and sections.statRows["player:MOVESPEED:"].Value.text == "100%",
    "moving resources must not remove other General stats")
local moveRow = sections.statRows["player:MOVESPEED:"]
local nativeInit = moveRow.Init
moveRow.tooltip = "Movement tooltip"
function moveRow:Init()
    self.tooltip = nil
    error("attempt to perform arithmetic on local 'runSpeed' (a secret number value)")
end
CharacterStatsPaneScrollBox:UpdateStats()
assert(moveRow.Value.text == "100%" and moveRow.tooltip == "Movement tooltip",
    "secret stat refresh failures must keep the last good row state")
moveRow.Value:SetText(secretStatText)
assert(moveRow.Value:GetText() == secretStatText,
    "secret stat text must pass through without string processing")
moveRow.Value:SetText("100%")
assert(moveRow.Value:GetText() == "100%", "stat text processing did not resume after secret text")
assert(sections.events.PLAYER_REGEN_ENABLED, "secret stat refresh failures must retry after combat")
moveRow.Init = nativeInit
CharacterStatsPaneScrollBox.elementData[4].valueText = "110%"
sections.scripts.OnEvent(sections, "PLAYER_REGEN_ENABLED")
assert(moveRow.Value.text == "110%" and not sections.events.PLAYER_REGEN_ENABLED)
table.remove(CharacterStatsPaneScrollBox.elementData, 4)
CharacterStatsPaneScrollBox:UpdateStats()
do
    local strengthRow = sections.statRows["player:STRENGTH:"]
    local savedInit, savedLabel, savedValue = strengthRow.Init, strengthRow.Label.text, strengthRow.Value.text
    local savedGlobal = SPELL_STAT1_NAME
    SPELL_STAT1_NAME = "Strength"
    function strengthRow:Init() error("attempt to compare local 'negBuff' (a secret number value)") end
    strengthRow.Label:SetText("")
    CharacterStatsPaneScrollBox:UpdateStats()
    local expected = STAT_FORMAT and string.format(STAT_FORMAT, "Strength") or "Strength"
    assert(strengthRow.Label.text == expected and strengthRow.Value.text == "--",
        "combat stat failures must fall back to the native localized label, not the raw stat token")
    strengthRow.Init, SPELL_STAT1_NAME = savedInit, savedGlobal
    sections.scripts.OnEvent(sections, "PLAYER_REGEN_ENABLED")
    assert(strengthRow.Label.text == savedLabel and strengthRow.Value.text == savedValue)
end
assert(sections.headers[3].Title.text == "Offensive Properties")
assert(sections.headers[4].Title.text == "Defensive Properties")
for index, name in ipairs({"Role", "Attributes", "Offensive", "Defensive", "Mental", "Physical"}) do
    local header = sections.headers[index]
    if index > 1 then
        local icon = header.FFXIVUIHeaderIcon
        assert(icon and icon.texture == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\" .. name .. ".tga")
        assert(icon.width == 22 and icon.height == 22 and icon.points[1][4] == 3)
        assert(header.Title.points[1][4] == 28, "header text overlaps icon")
        assert(header.Title:GetStringWidth() <= header.width - 36, "header label does not fit beside icon")
        assert(-header.points[1][5] >= 78, "stat headers overlap resource row")
    end
end
assert(sections.statRows["player:CRITCHANCE:"].FFXIVUIStatColumn == 1)
assert(sections.statRows["player:SPELLPOWER:"].FFXIVUIStatColumn == 2)
assert(sections.statRows[":Fire:"].scripts.OnEnter(sections.statRows[":Fire:"]) == "Fire resistance tooltip")
local originalData = CharacterStatsPaneScrollBox.elementData
local health = sections.statRows["player:STRENGTH:"]
health:HookScript("OnHide", function() error("live stat refresh hid a still-present tooltip target") end)
originalData[5].value = 450
local beforeRefresh = #created
CharacterStatsPaneScrollBox:UpdateStats()
assert(health.Value.text == "450" and #created == beforeRefresh, "live refresh failed or duplicated rows")
originalData[5].value = 36
originalData[10].shouldRemove = true
CharacterStatsPaneScrollBox:UpdateStats()
assert(not sections.statRows["player:SPELLPOWER:"].shown and not sections.headers[5].shown)
originalData[10].shouldRemove = nil
CharacterStatsPaneScrollBox:UpdateStats()
assert(sections.statRows["player:SPELLPOWER:"].shown and sections.headers[5].shown)
local extended = {{isHeader = true, name = "Weapons"}}
for index = 1, 30 do
    extended[#extended + 1] = {name = "TEST_STAT_" .. index, unit = "player", value = index, statIndex = index}
end
extended[#extended + 1] = {isHeader = true, name = "Future Native Category"}
extended[#extended + 1] = {name = "FUTURE_STAT", unit = "player", value = 99, statIndex = 1}
health.scripts.OnHide = nil
CharacterStatsPaneScrollBox.elementData = extended
CharacterStatsPaneScrollBox:UpdateStats()
assert(root.height > 530)
assert(root.height == 66 + 48 + sections.requiredHeight, "overflow stats clipped instead of growing window")
assert(sections.headers[7].Title.text == "Future Native Category", "unknown native category discarded")
assert(not sections.headers[7].FFXIVUIHeaderIcon and sections.headers[7].Title.points[1][4] == 10,
    "unknown native category received an unrelated icon or unnecessary indent")
for _, row in ipairs(sections.rows) do
    local x, y = row.points[1][4], -row.points[1][5]
    assert(x >= 12 and x + row.width <= 440 and y + row.height <= sections.requiredHeight,
        "section row exceeds two-column content bounds")
end
combat = true
extended[2].value = 123
CharacterStatsPaneScrollBox:UpdateStats()
assert(sections.statRows["player:TEST_STAT_1:"].Value.text == "123", "combat prevented live value updates")
combat = false
CharacterStatsPaneScrollBox.elementData = originalData
CharacterStatsPaneScrollBox:UpdateStats()
assert(root.height == 530 and not sections.statRows["player:TEST_STAT_1:"].shown)
assert(CharacterStatsPanePetScrollBox.FFXIVUISections ~= sections, "pet shares player rows")
InputUtil = {IsGamepadUIEnabled = function() return true end}
SmartNavigation = {
    GetActiveFrame = function() return root end,
    SetScrollFrameForFrame = function(self, owner, scroll) self.scroll = scroll; assert(owner == root) end,
    SelectButton = function(self, button) self.selected = button end,
}
GamepadScrollBarHint = object()
PaperDollSidebarTab1.scripts.OnClick(PaperDollSidebarTab1)
assert(SmartNavigation.selected == health and not GamepadScrollBarHint.shown and SmartNavigation.scroll == nil)
PaperDollSidebarTab3.scripts.OnClick(PaperDollSidebarTab3)
assert(SmartNavigation.selected == CharacterStatsPanePetScrollBox.FFXIVUISections.statRows["player:STRENGTH:"])
print("PASS two-column sections, hidden native list, live refresh, row reuse, optional stats, overflow and unknown native categories")
local header, stat = sections.headers[2], sections.statRows["player:STRENGTH:"]
assert(header.Title.font[2] == 12 and header.height == 24)
assert(stat.Label.font[2] == 10 and stat.Value.font[2] == 10 and stat.height == 18)
assert(stat.width == 202 and stat.Value.width == 40, "compact stat sizing not applied")
assert(header.Title.justify == "LEFT" and header.FFXIVUILine)
assert(stat.Value.text == "36" and stat.Value.color[2] == 1)
assert(stat.scripts.OnEnter(stat) == "STRENGTH")
local line = header.FFXIVUILine
CharacterStatsPaneScrollBox.ScrollBox.Updated()
assert(header.FFXIVUILine == line and stat.Background.alpha == 0)
local total = 0
local itemSlots = {}
for _, slots in ipairs({PaperDollItemsFrame.EquipmentSlots, PaperDollItemsFrame.WeaponSlots}) do
    for _, button in ipairs(slots) do itemSlots[button] = true end
end
for button, style in pairs(skinned) do
    if itemSlots[button] or button == CharacterAmmoSlot then
        assert(style == "Equipment" and (button.scripts.OnClick ~= nil or button == CharacterAmmoSlot))
        total = total + 1
    else
        assert(style == "Equipment" and (button == CharacterHeadSlot or button == CharacterHandsSlot
            or button == CharacterMainHandSlot or button == CharacterSecondaryHandSlot),
            "unexpected button skinned as equipment")
    end
end
assert(total == 20)
local slot = PaperDollItemsFrame.EquipmentSlots[1]
skinned[slot] = nil
PaperDollItemSlotButton_Update(slot)
assert(skinned[slot] == "Equipment" and slot.updates == 1 and slot.scripts.OnClick() == "native equip")
assert(slot.BorderFrame.art.alpha == 0 and slot.BorderFrame.shown, "native slot border still overlaps square skin")
local unrelated = object("Frame", object())
PaperDollItemSlotButton_Update(unrelated)
assert(skinned[unrelated] == nil, "shared slot update skinned an unrelated panel")
print("PASS native stat values, buff colors, tooltips, pooled rows and equipment actions are preserved")

combat = true
root.protected = true
root.activeSubframe = "ReputationFrame"
root:RefreshDisplay()
assert(root.LeftPaneHost.points[1][4] == 440, "addon moved pane hosts of a protected frame during combat")
combat = false
event("PLAYER_REGEN_ENABLED")
assert(root.LeftPaneHost.points[1][4] == 0 and root.height == 530)
root.protected = nil
root.activeSubframe = "PaperDollFrame"
root:RefreshDisplay()
local laidOutX, laidOutWidth = root.LeftPaneHost.points[1][4], root.width
assert(laidOutX ~= 0, "paper doll layout did not offset the model pane")
combat = true
root.activeSubframe = "ReputationFrame"
root:RefreshDisplay()
assert(root.LeftPaneHost.points[1][4] == 0 and root.height == 530,
    "unprotected character frame kept native geometry when opened in combat")
root.activeSubframe = "PaperDollFrame"
root:RefreshDisplay()
assert(root.LeftPaneHost.points[1][4] == laidOutX and root.width == laidOutWidth,
    "combat paper doll layout differs from the out-of-combat layout")
root.activeSubframe = "ReputationFrame"
root:RefreshDisplay()
combat = false
event("PLAYER_REGEN_ENABLED")
local count = #created
event("ADDON_LOADED")
event("PLAYER_LOGIN")
assert(#created == count, "repeated loading duplicated artwork or hooks")
print("PASS layout applies in combat while unprotected, defers when protected, and installation is idempotent")
for _ = 1, 4 do
    root.CloseButton.scripts.OnClick()
    assert(not root:IsShown(), "native character close action stopped working")
    root:Show()
    root:RefreshDisplay()
    assert(root:IsShown() and root.height == 530 and root.panelWidth == nil,
        "reopening the character frame changed native panel-manager state")
end
assert(#created == count, "repeated character open/close duplicated artwork")
print("PASS repeated character open/close avoids addon writes to native panel-manager attributes")

local themes = namespace.Themes
assert(themes.GetName() == "Dark" and #themes.GetNames() == 1 and themes.GetNames()[1] == "Dark")
local normal = CharacterStatsPanePetScrollBox.FFXIVUISections.statRows["player:STRENGTH:"].Value
local colored = stat.Value
normal:SetTextColor(1, 1, 1)
local shell
for _, child in ipairs(root.children) do
    for _, region in ipairs(child.regions) do
        if region.texture == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Window-Background-Dark.tga" then shell = child end
    end
end
assert(shell)
assert(not shell.backdrop, "square backdrop fills rounded character corners")
local rim = assert(shell.FFXIVUIWindowRim, "main character window lacks gold chrome")
local lighting = assert(shell.FFXIVUIWindowLighting)
assert(#rim == 8 and #lighting == 6, "extracted window must use eight rim and six header slices")
assert(rim[1].texture:find("Window-Rim-Dark.tga", 1, true)
    and rim[1].width == 8 and rim[1].height == 8, "window corners are not fixed-size extracted artwork")
assert(lighting[1].texture:find("Window-Header-Dark.tga", 1, true)
    and lighting[1].points[1][5] == 0, "header light is inset behind a dark inner seam")
assert(not shell.FFXIVUIGrain, "main window still allocates procedural grain")
assert(#shell.FFXIVUIWindowInterior == 9)
for _, index in ipairs({1, 3, 7, 9}) do
    local piece = shell.FFXIVUIWindowInterior[index]
    assert(piece.texture.alpha == 0 and not piece.texture.mask,
        "background corner must come from the composited frame rather than a runtime mask")
end
assert(lighting[1].alpha == 0 and lighting[3].alpha == 0
    and not lighting[1].mask and not lighting[3].mask,
    "header corner still relies on the problematic runtime mask")
assert(not banner.FFXIVUIWindowRim, "main-window chrome leaked into an inset banner")
local chromeCount = #created
namespace.RoundWindow(shell, true)
assert(#created == chromeCount, "repeated window styling duplicated chrome")
local function same(actual, expected)
    for i = 1, 3 do assert(actual[i] == expected[i], "theme color mismatch") end
end
for _, name in ipairs(themes.GetNames()) do
    combat = true
    local x = root.LeftPaneHost.points[1][4]
    assert(themes.Set(name))
    local palette = themes.GetPalette()
    assert(rim[1].vertexColor == nil and lighting[1].vertexColor == nil,
        "theme refresh tinted the extracted artwork")
    assert(shell.FFXIVUIWindowInterior[1].texture.texture:find("Window-Background-Dark.tga", 1, true))
    assert(FFXIV_UI_Theme.name == name)
    same(header.Title.color, palette.muted)
    assert(header.FFXIVUIHeaderIcon.color == nil, "theme recolored supplied gold artwork")
    same(normal.color, palette.text)
    same(resources.Health.Current.color, palette.text)
    same(resources.Power.Maximum.color, palette.text)
    same(colored.color, palette.beneficial)
    local themeName = name:gsub(" ", "-")
    assert(paneArrow.texture:find("Arrow-Button-Glyph.tga", 1, true)
        and circularArrow.base.texture:find("Arrow-Button-Circle.tga", 1, true),
        "theme refresh replaced the approved neutral circular-arrow artwork")
    assert(arrowShadow.texture == paneArrow.texture, "arrow shadow did not retain the supplied glyph")
    for index, sidebar in ipairs(sidebarButtons) do
        local expected = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\Sidebar-"
            .. sidebarNames[index] .. "-" .. themeName .. ".tga"
        assert(sidebar.Icon.texture == expected, "sidebar button did not follow the active theme")
        SetPortraitTexture(sidebar.Icon)
        assert(sidebar.Icon.texture == expected, "native refresh lost the themed sidebar button")
    end
    assert(charTab.children[1].regions[2].texture:find("Tab-Inactive-" .. themeName .. ".tga", 1, true))
    assert(not charTab.children[1].backdrop and not reputation.children[1].backdrop)
    for _, texture in ipairs(reputation.children[1].FFXIVUITabArt.fill) do
        assert(texture.texture:find("Tab-Selected-" .. themeName .. ".tga", 1, true),
            "character tab does not use its theme's extracted selected artwork")
        same(texture.vertexColor, {1, 1, 1})
    end
    assert(root.LeftPaneHost.points[1][4] == x, "theme switch changed geometry in combat")
end
normal:SetTextColor(1, 0, 0)
themes.Set("Dark")
same(normal.color, themes.GetPalette().detrimental)
normal:SetTextColor(0.1, 1, 0.1)
same(normal.color, themes.GetPalette().beneficial)
normal:SetTextColor(1, 0.1, 0.1)
same(normal.color, themes.GetPalette().detrimental)
normal:SetTextColor(0.3, 0.5, 0.8, 0.7)
themes.Set("Dark")
same(normal.color, {0.3, 0.5, 0.8})
assert(normal.color[4] == 0.7, "unrelated native color/alpha must be preserved")
themes.Set("Dark")
normal:SetTextColor(1, 1, 1)
same(normal.color, themes.GetPalette().text)
themes.Set("Dark")
same(normal.color, themes.GetPalette().text)
colored:SetTextColor(0.1, 1, 0)
same(colored.color, themes.GetPalette().beneficial)
colored:SetText("|cff00ff0036|r / |cffff000020|r")
assert(colored.text == "|cff00ff0036|r / |cffff4d4d20|r", "embedded stat colors must use Dark-theme colors")
themes.Set("Dark")
assert(colored.text == "|cff00ff0036|r / |cffff4d4d20|r", "theme switching must use original text, not already-remapped markup")
themes.Set("Dark")
colored:SetFormattedText("|cnGREEN_FONT_COLOR:%d|r", 44)
assert(colored.text == "|cff00ff0044|r", "named color markup and formatted native updates must be themed")
themes.Set("Dark")
assert(colored.text == "|cff00ff0044|r", "formatted updates must retain original markup across theme changes")
themes.Set("Dark")
colored:SetText("|cff7788ffOther|r")
assert(colored.text == "|cff7788ffOther|r", "unrelated embedded colors must remain unchanged")
colored:SetText("36")
assert(colored.text == "36", "buff removal must not retain previous color markup")
local copy = themes.GetNames()
copy[1] = "changed"
assert(themes.GetNames()[1] == "Dark")
local oldPrint, messages = print, {}
print = function(message) messages[#messages + 1] = message end
assert(themes.Set("Invalid") == false and themes.GetName() == "Dark")
FFXIV_UI_Theme.name = "Invalid"
themeLoader.scripts.OnEvent(themeLoader, "ADDON_LOADED", "FFXIV_UI")
print = oldPrint
assert(#messages == 2 and FFXIV_UI_Theme.name == "Dark")
FFXIV_UI_Theme.name = "Clear Blue"
themeLoader.scripts.OnEvent(themeLoader, "ADDON_LOADED", "FFXIV_UI")
assert(themes.GetName() == "Dark" and FFXIV_UI_Theme.name == "Dark")
local originalPrint = print
print = function() end
for _, unavailable in ipairs({"Light", "Classic FF", "Clear Blue", "Clear White", "Clear Green", "Clear Grey", "Clear Pink"}) do
    assert(themes.Set(unavailable) == false and themes.GetName() == "Dark" and FFXIV_UI_Theme.name == "Dark",
        "temporarily disabled theme could still be selected")
end
print = originalPrint
same(header.Title.color, themes.GetPalette().muted)
print("PASS extracted Dark window artwork, theme lock, saved selection migration and native stat color transitions")
local originalDB, originalSlashCommands = FFXIV_UI_DB, SlashCmdList
FFXIV_UI_DB = {anchorProfile = "Default", characterSkinDiagnosticDisabled = true}
SlashCmdList = {}
local beforeIsolation = #created
assert(loadfile("FFXIV_UI\\General\\CharacterFrame.lua"))("FFXIV_UI", namespace)
local isolatedWatcher = created[#created]
assert(#created == beforeIsolation + 1, "module installed before reading saved isolation state")
for _, eventName in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED"}) do
    isolatedWatcher.scripts.OnEvent(isolatedWatcher, eventName, "FFXIV_UI")
end
assert(#created == beforeIsolation + 1, "isolated character skin still installed artwork or hooks")
local diagnosticCommand = assert(SlashCmdList.FFXIVUICHARTAINT)
print = function() end
diagnosticCommand("resume")
assert(FFXIV_UI_DB.characterSkinDiagnosticDisabled == nil and FFXIV_UI_DB.anchorProfile == "Default")
isolatedWatcher.scripts.OnEvent(isolatedWatcher, "PLAYER_LOGIN")
assert(#created == beforeIsolation + 1, "resume must not install hooks until the next session")
diagnosticCommand("isolate")
assert(FFXIV_UI_DB.characterSkinDiagnosticDisabled == true)
diagnosticCommand("noresources")
assert(FFXIV_UI_DB.characterSkinDiagnosticDisabled == nil
    and FFXIV_UI_DB.characterResourcesDiagnosticDisabled == true
    and FFXIV_UI_DB.anchorProfile == "Default", "resource isolation must enable the remaining skin")
local originalHealth = UnitHealth
UnitHealth = function() error("resource-isolated skin must not read health") end
local beforeResourceIsolation = #created
CharacterFrame = object()
CharacterStatsPane.Resources = nil
CharacterStatsPaneScrollBox.FFXIVUISections = nil
CharacterStatsPanePetScrollBox.FFXIVUISections = nil
assert(loadfile("FFXIV_UI\\General\\CharacterFrame.lua"))("FFXIV_UI", namespace)
local resourceWatcher = created[#created]
resourceWatcher.scripts.OnEvent(resourceWatcher, "ADDON_LOADED", "FFXIV_UI")
assert(#created > beforeResourceIsolation + 1, "resource isolation disabled the whole character skin")
assert(not (CharacterStatsPane.Resources or CharacterStatsPaneScrollBox.FFXIVUISections and CharacterStatsPaneScrollBox.FFXIVUISections.Resources)
    and not (CharacterStatsPanePetScrollBox.FFXIVUISections and CharacterStatsPanePetScrollBox.FFXIVUISections.Resources),
    "resource isolation still created player or pet resource displays")
UnitHealth = originalHealth
diagnosticCommand("resume")
assert(FFXIV_UI_DB.characterSkinDiagnosticDisabled == nil
    and FFXIV_UI_DB.characterResourcesDiagnosticDisabled == nil,
    "resume must restore the full character skin")
print = oldPrint
FFXIV_UI_DB, SlashCmdList = originalDB, originalSlashCommands
print("PASS reversible saved character-skin isolation waits for addon loading and preserves profile settings")
print("PASS resource-only isolation skips health reads and player/pet resource displays while retaining the skin")

do
    local row = object("Frame")
    row.Name = object("FontString", row)
    row.Name:SetFont("Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf", 12, "")
    row.Name:SetText("Reputation")
    row.StateIcon = object("Texture", row)
    row.StateIcon:SetAtlas("common-button-list-minus")
    namespace.StyleForeverCollapsibleHeader(row)
    assert(row.FFXIVUIHeader, "Forever header row was not styled")
    assert(row.StateIcon.alpha == 0, "native StateIcon must stay hidden")
    local header = row.FFXIVUIHeader
    assert(header.pieces[1].texture:find("ComboBox%-Open%-Dark%.tga$"), "expanded header must use the Open ComboBox bar")
    assert(header.pieces[2].texture == header.pieces[1].texture, "all bar pieces must share the ComboBox texture")
    assert(not header.arrow, "header must not add a circle arrow; the ComboBox bar includes one")
    row.StateIcon:SetAtlas("common-button-list-plus")
    assert(header.pieces[1].texture:find("ComboBox%-Closed%-Dark%.tga$"), "collapsed header must use the Closed ComboBox bar")
    print("PASS Forever header rows hide the native StateIcon and drive the ComboBox bar from its atlas")
end

