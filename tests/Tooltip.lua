local applyControlTemplate = assert(loadfile("tests\\support\\PanelTemplates.lua"))()
local methods = {}

local function object(kind, parent)
    local result = setmetatable({
        kind = kind or "Frame", parent = parent, shown = kind == "FontString", level = 1,
        regions = {}, children = {}, scripts = {}, hooks = {}, points = {}, text = "", stringHeight = 10,
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
function methods:CreateTexture(_, layer, template, sublevel)
    local texture = object("Texture", self)
    texture.layer, texture.sublevel, texture.template = layer, sublevel, template
    applyControlTemplate(texture, self, template)
    return texture
end
function methods:CreateMaskTexture() return object("Texture", self) end
function methods:CreateFontString(_, layer, template)
    local region = object("FontString", self)
    region.template = template
    applyControlTemplate(region, self, template)
    return region
end
function methods:SetTexture(path, horizWrap, vertWrap)
    self.file, self.horizWrap, self.vertWrap = path, horizWrap, vertWrap
end
function methods:SetHorizTile(value) self.horizTile = value end
function methods:SetVertTile(value) self.vertTile = value end
function methods:SetTexCoord(...) self.texCoord = {...} end
function methods:SetColorTexture() end
function methods:SetVertexColor() end
function methods:SetAlpha() end
function methods:SetAllPoints() end
function methods:EnableMouse() end
function methods:SetJustifyH() end
function methods:SetTextColor() end
function methods:GetTextColor() return 1, 1, 1, 1 end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:ClearAllPoints() self.points = {} end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width or 0 end
function methods:GetHeight() return self.height end
function methods:GetSize() return self.width or 0, self.height or 0 end
function methods:GetName() return self.name end
function methods:SetFrameStrata(value) self.strata = value end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameLevel() return self.level end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetBackdropBorderColor() end
function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetFont(...) self.font = {...} end
function methods:SetText(text) assert(self.font, "Font not set"); self.text = text end
function methods:GetStringHeight()
    if self.wrap and self.unboundedWidth and self.width and self.width > 0 then
        return math.max(self.stringHeight, math.ceil(self.unboundedWidth / self.width) * self.stringHeight)
    end
    return self.stringHeight
end
function methods:GetStringWidth() return self.stringWidth or self.unboundedWidth or 0 end
function methods:GetUnboundedStringWidth() return self.unboundedWidth or self.stringWidth or 0 end
function methods:SetWordWrap(value) self.wrap = value end
function methods:CanWordWrap() return self.wrap end
function methods:SetMaxLines(value) self.maxLines = value end
function methods:GetMaxLines() return self.maxLines or 1 end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetShown(value) self.shown = value and true or false end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:HookScript(name, callback)
    self.hooks[name] = self.hooks[name] or {}
    self.hooks[name][#self.hooks[name] + 1] = callback
end
function methods:RegisterEvent() end
function methods:GetParent() return self.parent end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetAlpha() return self.alpha or 1 end
function methods:IsTooltipType(kind) return self.dataType == kind end
function methods:GetTooltipData() return {type = self.dataType} end

function InCombatLockdown() return false end
function GetTime() return 100 end
function hooksecurefunc() end
UIParent = object("Frame")

table.unpack = table.unpack or unpack
unpack = unpack or table.unpack

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local tocLines = {}
for _, tocPath in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines = {}
    for line in readFile(tocPath):gmatch("[^\r\n]+") do
        lines[#lines + 1] = line
    end
    local index = {}
    for position, line in ipairs(lines) do index[line] = position end
    assert(index["General/Tooltips/Tooltip.xml"], tocPath .. " must load Tooltip.xml")
    assert(index["General/Tooltips/Tooltip.xml"] < index["General/Tooltips/Core.lua"],
        tocPath .. " must load Tooltip.xml before Core.lua")
    tocLines[tocPath] = index
end

local templateXml = readFile("FFXIV_UI\\General\\Tooltips\\Tooltip.xml")
local expectedRim = {"11", "12", "13", "21", "23", "31", "32", "33"}
local expectedBackground = {"11", "12", "13", "21", "22", "23", "31", "32", "33"}
for _, slice in ipairs(expectedRim) do
    assert(templateXml:find('name="FFXIV_TooltipRim' .. slice .. 'Template"', 1, true),
        "missing rim template " .. slice)
end
for _, slice in ipairs(expectedBackground) do
    assert(templateXml:find('name="FFXIV_TooltipBackground' .. slice .. 'Template"', 1, true),
        "missing background template " .. slice)
end

local namespace = {}
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\RoundedPanels.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\WindowControls.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Core.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Items.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Spells.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Mounts.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Toys.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Skills.lua"))("FFXIV_UI", namespace)

local function assertEqual(actual, expected, label)
    assert(actual == expected, string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
end

local tooltip = CreateFrame("Frame")
assert(namespace.RoundTooltip(tooltip), "tooltip was not rounded")
assert(namespace.RoundTooltip(tooltip), "second call should succeed")

local rimTextures, backgroundTextures = {}, {}
for _, region in ipairs(tooltip.regions) do
    if region.template and region.template:find("^FFXIV_TooltipRim") then
        rimTextures[#rimTextures + 1] = region
    elseif region.template and region.template:find("^FFXIV_TooltipBackground") then
        backgroundTextures[#backgroundTextures + 1] = region
    end
end
assertEqual(#rimTextures, #expectedRim, "rim slice count")
assertEqual(#backgroundTextures, #expectedBackground, "background slice count")

local rimFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Tooltip-Rim-Dark.tga"
local backgroundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Tooltip-Background-Dark.tga"
local fillFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Tooltip-Fill-Dark.tga"

for _, texture in ipairs(rimTextures) do
    assertEqual(texture.layer, "OVERLAY", "rim layer " .. texture.template)
    assertEqual(texture.sublevel, 7, "rim sublevel " .. texture.template)
    assertEqual(texture.file, rimFile, "rim file " .. texture.template)
    assert(not texture.tiled, "rim slices must not tile")
end

for _, texture in ipairs(backgroundTextures) do
    assertEqual(texture.layer, "BACKGROUND", "background layer " .. texture.template)
    assertEqual(texture.sublevel, -8, "background sublevel " .. texture.template)
    if texture.template == "FFXIV_TooltipBackground22Template" then
        assertEqual(texture.file, fillFile, "centre fill file")
        assert(texture.horizTile and texture.vertTile, "centre fill must tile both ways")
    else
        assertEqual(texture.file, backgroundFile, "background file " .. texture.template)
    end
end

local function findTexture(templateName)
    for _, region in ipairs(tooltip.regions) do
        if region.template == templateName then return region end
    end
    error("missing texture " .. templateName)
end

local centre = findTexture("FFXIV_TooltipBackground22Template")
assertEqual(centre.horizWrap, "REPEAT", "centre horizontal wrap")
assertEqual(centre.vertWrap, "REPEAT", "centre vertical wrap")
assert(templateXml:find('<TexCoords left="0.25" right="0.75" top="0.25" bottom="0.75"/>', 1, true),
    "centre template must declare its fill coordinates")
assertEqual(centre.texCoord[1], 0, "runtime tiled left")
assertEqual(centre.texCoord[2], 0.5, "runtime tiled right for a zero-size tooltip")
assertEqual(centre.texCoord[4], 0.5, "runtime tiled bottom for a zero-size tooltip")

local topLeft = findTexture("FFXIV_TooltipRim11Template")
assertEqual(topLeft.width, 16, "rim corner width")
assertEqual(topLeft.height, 16, "rim corner height")
assertEqual(topLeft.texCoord[2], 0.25, "rim corner right coordinate")

local topEdge = findTexture("FFXIV_TooltipRim12Template")
assertEqual(#topEdge.points, 2, "top edge anchor count")
assertEqual(topEdge.points[1][1], "TOPLEFT", "top edge left anchor")
assertEqual(topEdge.points[2][1], "TOPRIGHT", "top edge right anchor")
assertEqual(topEdge.points[1][4], 16, "top edge inset")
assertEqual(topEdge.points[2][4], -16, "top edge right inset")

local leftEdge = findTexture("FFXIV_TooltipBackground21Template")
assertEqual(leftEdge.points[2][1], "BOTTOMLEFT", "left edge bottom anchor")
assertEqual(leftEdge.points[2][5], 16, "left edge bottom inset")

local shineStrips = 0
for _, region in ipairs(tooltip.regions) do
    if region.layer == "BACKGROUND" and region.sublevel == -7 then shineStrips = shineStrips + 1 end
end
assertEqual(shineStrips, 40, "shine strips kept in Lua")

local coreSource = readFile("FFXIV_UI\\General\\Tooltips\\Core.lua")
for name in coreSource:gmatch('"(FFXIV_Tooltip%w+Template)"') do
    assert(templateXml:find('name="' .. name .. '"', 1, true), "Core.lua uses missing template " .. name)
end
for name in templateXml:gmatch('<FontString name="([^"]+)"') do
    assert(templateXml:find('<FontString name="' .. name .. '" virtual="true" inherits="', 1, true),
        name .. " must inherit a Blizzard font")
end
local countText = tooltip:CreateFontString(nil, "OVERLAY", "FFXIV_TooltipCountTemplate")
assertEqual(countText.font[1], "GameFontNormal", "count template font")
assertEqual(countText.template, "FFXIV_TooltipCountTemplate", "count template name")

local icon = tooltip:CreateTexture(nil, "ARTWORK", "FFXIV_TooltipIconTemplate")
assertEqual(icon.width, 32, "icon template width")
assertEqual(icon.height, 32, "icon template height")
assertEqual(icon.points[1][1], "TOPLEFT", "icon template anchor")
assertEqual(icon.points[1][4], 16, "icon template x")
assertEqual(icon.points[1][5], -10, "icon template y")

for name, colour in pairs({FFXIV_TooltipBandTemplate = 'a="0.35"', FFXIV_TooltipDividerTemplate = 'a="0.85"'}) do
    local start = assert(templateXml:find('name="' .. name .. '"', 1, true), name .. " template missing")
    local finish = templateXml:find("</Texture>", start, true)
    assert(templateXml:find(colour, start, true) and templateXml:find(colour, start, true) < finish,
        name .. " colour")
end

for _, module in ipairs({"Items", "Spells", "Mounts", "Toys", "Skills"}) do
    local source = readFile("FFXIV_UI\\General\\Tooltips\\" .. module .. ".lua")
    assert(source:find('"ARTWORK", "FFXIV_TooltipIconTemplate")', 1, true), module .. " must use the icon template")
    assert(not source:find('itemIcon:SetSize(32, 32)', 1, true), module .. " must not size the icon in code")
end

local itemsSource = readFile("FFXIV_UI\\General\\Tooltips\\Items.lua")
assert(itemsSource:find('tooltipSkin.equipmentDividers[usedDividers] = divider', 1, true),
    "equipment dividers must be cached so they are hidden on refresh")
local dividerStart = assert(itemsSource:find("local function Divider()", 1, true), "equipment Divider helper missing")
local dividerSkip = itemsSource:find("if cursor == lastDividerCursor then return end", dividerStart, true)
local dividerCount = itemsSource:find("usedDividers = usedDividers + 1", dividerStart, true)
assert(dividerSkip and dividerSkip < dividerCount,
    "equipment Divider must skip a second divider when nothing was placed after the first (stat-less items)")
assert(itemsSource:find("lastDividerCursor = cursor", dividerStart, true),
    "equipment Divider must record where it ended")

for _, name in ipairs({"FFXIV_TooltipTitleTemplate", "FFXIV_TooltipStatLabelTemplate",
    "FFXIV_TooltipStatValueTemplate", "FFXIV_TooltipMoneyTemplate"}) do
    assert(templateXml:find('<FontString name="' .. name .. '" virtual="true" inherits="', 1, true),
        name .. " must be a FontString that inherits a font")
end
local rowStart = assert(templateXml:find('<Frame name="FFXIV_TooltipRowTemplate" virtual="true" hidden="true">', 1, true),
    "row pool template must be a virtual hidden Frame")
assert(templateXml:find("</Frame>", rowStart, true), "row pool template must close")
local row = CreateFrame(nil, nil, nil, "FFXIV_TooltipRowTemplate")
assertEqual(row.kind, "Frame", "row pool kind")
assertEqual(row.width, 248, "row pool width")
assertEqual(row.height, 16, "row pool height")

assert(itemsSource:find("height = 32, wordWrap = true}}", 1, true),
    "item name layout must record the 32px wrapped header height")
assert(itemsSource:find('if type(title.SetMaxLines) == "function" then title:SetMaxLines(0) end', 1, true),
    "item name must lift the native line limit so it wraps in full")
assert(not itemsSource:find("title:SetHeight(26)", 1, true),
    "binding-line layout must not shrink the item name below the two-line 32px header")
assert(itemsSource:find('tooltipSkin.itemIcon:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, -19)', 1, true),
    "binding-line layout must move the header icon with the name so they share one row")
assert(itemsSource:find("headerOffset = -8", 1, true)
    and itemsSource:find("-48 + headerOffset", 1, true),
    "binding-line layout must push the type row and body below the taller name header")
local coreSource = readFile("FFXIV_UI\\General\\Tooltips\\Core.lua")
local titleBranch = assert(coreSource:find("elseif region == tooltipSkin.itemTitle then", 1, true),
    "reflow must handle the item title")
local branchLimit = assert(coreSource:find("region:SetMaxLines(0)", titleBranch, true),
    "reflow must lift the item title line limit")
assert(branchLimit - titleBranch < 200, "item title line limit must be set in its reflow branch")
local styleTextStart = assert(coreSource:find("local function StyleText()", 1, true), "StyleText missing")
assert(coreSource:find("local itemName = itemTooltip and region == tooltip.TextLeft1", styleTextStart, true),
    "item names must be detected in StyleText so they keep their quality color")
assert(coreSource:find("elseif title and not itemName then", styleTextStart, true),
    "only non-item titles may be forced to the theme text color")

-- Comparison tooltips without stat-change lines (identical item, "Equipped With") must still be styled.
do
    local previousEnum, previousTimer, previousItem = Enum, C_Timer, C_Item
    local queued = {}
    Enum = {TooltipDataType = {Item = 0}}
    C_Timer = {After = function(_, callback) queued[#queued + 1] = callback end}
    C_Item = nil
    local shopping = CreateFrame("Frame")
    shopping.shown = true
    function shopping:GetName() return "ShoppingTooltip1" end
    function shopping:IsTooltipType(kind) return kind == 0 end
    function shopping:GetTooltipData() return {type = 0, id = 1, lines = {{}, {}, {}}} end
    function shopping:NumLines() return 3 end
    local restored = 0
    local styleShopping = namespace.Tooltips.InitializeItems({tooltip = shopping},
        {RestoreItemHeader = function() restored = restored + 1 end})
    styleShopping()
    assertEqual(restored, 0, "shopping tooltip waits one frame for comparison lines")
    assertEqual(#queued, 1, "shopping tooltip queues one retry")
    queued[1]()
    assertEqual(restored, 1, "shopping tooltip without comparison lines is styled after the retry")
    assertEqual(#queued, 1, "shopping tooltip retry must not defer again")
    Enum, C_Timer, C_Item = previousEnum, previousTimer, previousItem
end

do
    local previousTradeSkill, previousItem = C_TradeSkillUI, C_Item
    local calls = {}
    local tooltip = CreateFrame("Frame")
    function tooltip:GetSpell() return "Handstitched Leather Pants", 1234 end
    function tooltip:SetHyperlink(link) calls[#calls + 1] = {"SetHyperlink", link} end
    function tooltip:SetItemByID(id) calls[#calls + 1] = {"SetItemByID", id} end
    function tooltip:AddLine(text) calls[#calls + 1] = {"AddLine", text} end
    C_TradeSkillUI = {
        GetRecipeInfo = function(id) return id == 1234 and {name = "Handstitched Leather Pants"} or nil end,
        GetRecipeOutputItemData = function() return {itemID = 5001, hyperlink = "|Hitem:5001|h[Pants]|h"} end,
        GetRecipeSchematic = function()
            return {reagentSlotSchematics = {
                {quantityRequired = 4, reagents = {{itemID = 2001}}},
                {quantityRequired = 1, reagents = {{itemID = 2002}}},
            }}
        end,
    }
    C_Item = {
        GetItemInfo = function(id) return id == 2001 and "Light Leather" or nil end,
        RequestLoadItemDataByID = function() end,
    }
    assertEqual(namespace.Tooltips.ApplyTrainerRecipeTooltip(tooltip), true, "trainer recipe is rebuilt")
    assertEqual(calls[1][1], "SetHyperlink", "trainer recipe uses the output item hyperlink")
    assertEqual(calls[1][2], "|Hitem:5001|h[Pants]|h", "output item hyperlink is used")
    local rows = tooltip.FFXIVUITrainerRecipeRows
    assertEqual(rows[1].text, "Profession Recipe: Handstitched Leather Pants", "recipe name row is stored")
    assertEqual(rows[2].text, "Reagents:", "reagents heading row is stored")
    assertEqual(rows[3].itemID, 2001, "first reagent row keeps its item id")
    assertEqual(rows[3].count, 4, "first reagent row keeps its count")

    tooltip.GetWidth = function() return 300 end
    local skin = {targetHeight = 100}
    namespace.Tooltips.PlaceTrainerRecipeRows(tooltip, skin)
    local regions = skin.trainerRecipeRegions
    assertEqual(regions[1].text, "Profession Recipe: Handstitched Leather Pants", "recipe row is placed")
    assertEqual(regions[3].text, "Light Leather (4)", "cached reagent name is placed")
    assertEqual(regions[4].text, "item:2002 (1)", "uncached reagent falls back to item id")
    assertEqual(skin.targetHeight, 178, "frame grows to fit the rows plus bottom padding")
    assertEqual(tooltip.height, 178, "tooltip height matches the placed rows")
    namespace.Tooltips.PlaceTrainerRecipeRows(tooltip, skin)
    assertEqual(skin.targetHeight, 178, "re-placing does not stack the padding")


    tooltip.GetSpell = function() return "Unknown", 9999 end
    calls = {}
    assertEqual(namespace.Tooltips.ApplyTrainerRecipeTooltip(tooltip), false, "non-recipe spells keep the spell path")
    assertEqual(#calls, 0, "non-recipe spells must not be rebuilt")
    C_TradeSkillUI, C_Item = previousTradeSkill, previousItem
end

do
    local previousEnum, previousScreenWidth, previousHook = Enum, UIParent.width, hooksecurefunc
    Enum = {TooltipDataType = {Item = 0, MinimapMouseover = 21}}
    UIParent.width = 1920
    hooksecurefunc = function(frame, method, callback)
        frame.methodHooks = frame.methodHooks or {}
        frame.methodHooks[method] = frame.methodHooks[method] or {}
        table.insert(frame.methodHooks[method], callback)
    end

    local minimapTooltip = object("Frame")
    minimapTooltip.name = "MinimapTooltip"
    minimapTooltip.width, minimapTooltip.height, minimapTooltip.dataType = 430, 60, 21
    minimapTooltip.lineCount = 1
    function minimapTooltip:NumLines() return self.lineCount end
    function minimapTooltip:ClearLines()
        self.lineCount = 0
        for _, callback in ipairs(self.methodHooks.ClearLines) do callback(self) end
    end
    function minimapTooltip:AddLine()
        self.lineCount = self.lineCount + 1
        for _, callback in ipairs(self.methodHooks.AddLine) do callback(self) end
    end
    local title = minimapTooltip:CreateFontString(nil, "OVERLAY")
    title.width, title.height, title.stringHeight = 380, 20, 20
    title.maxLines, title.wrap, title.unboundedWidth = 1, false, 180
    minimapTooltip.TextLeft1 = title
    assert(namespace.RoundTooltip(minimapTooltip), "minimap tooltip was not rounded")
    local fitMinimap = namespace.FFXIVUITooltipSkins[minimapTooltip].updateMinimapMouseoverLayout
    assert(type(fitMinimap) == "function", "minimap tooltip layout was not installed")

    fitMinimap()
    assertEqual(minimapTooltip.width, 244, "short minimap title fits its text")
    assertEqual(title.width, 180, "short minimap title retains its unbounded width")
    assertEqual(title.maxLines, 0, "minimap title line limit is removed")
    assertEqual(title.wrap, false, "short minimap title stays on one line")

    UIParent.width, title.unboundedWidth = 480, 900
    fitMinimap()
    assertEqual(minimapTooltip.width, 432, "long minimap title respects available screen width")
    assertEqual(title.width, 368, "long minimap title uses the available text width")
    assertEqual(title.wrap, true, "long minimap title wraps instead of truncating")
    assert(minimapTooltip.height > 60, "wrapped minimap title grows the tooltip height")

    UIParent.width, title.unboundedWidth = 1920, 180
    fitMinimap()
    assertEqual(minimapTooltip.width, 244, "reused minimap tooltip shrinks for a shorter title")
    assertEqual(minimapTooltip.height, 60, "reused minimap tooltip restores its base height")

    minimapTooltip.dataType = 0
    fitMinimap()
    assertEqual(minimapTooltip.width, 430, "other tooltip types restore the native width")
    assertEqual(minimapTooltip.height, 60, "other tooltip types restore the native height")
    assertEqual(title.width, 380, "other tooltip types restore the native title width")
    assertEqual(title.maxLines, 1, "other tooltip types restore the native line limit")

    minimapTooltip.dataType, UIParent.width, title.unboundedWidth = 21, 480, 900
    fitMinimap()
    minimapTooltip.hooks.OnHide[1](minimapTooltip)
    assertEqual(minimapTooltip.width, 430, "hiding minimap tooltip restores the native width")
    assertEqual(title.width, 380, "hiding minimap tooltip restores the native title width")
    assertEqual(title.maxLines, 1, "hiding minimap tooltip restores the native line limit")

    minimapTooltip.height, minimapTooltip.lineCount = 60, 1
    fitMinimap()
    minimapTooltip:ClearLines()
    assertEqual(minimapTooltip.width, 430, "clearing a visible tooltip restores its native width")
    assertEqual(title.width, 380, "clearing a visible tooltip restores its native title width")

    minimapTooltip:AddLine()
    assertEqual(minimapTooltip.width, 430, "styling an intermediate line does not resize the tooltip")
    minimapTooltip:AddLine()
    minimapTooltip:AddLine()
    minimapTooltip.height = 110
    fitMinimap()
    assertEqual(minimapTooltip.width, 430, "multi-line minimap tooltip keeps its native width")
    assertEqual(minimapTooltip.height, 110, "multi-line minimap tooltip keeps all its lines")
    assertEqual(title.width, 380, "multi-line minimap tooltip keeps its native title width")

    Enum, UIParent.width, hooksecurefunc = previousEnum, previousScreenWidth, previousHook
end

print("Tooltip tests passed")
