local namespace = {}
local created, lastFrame = {}, nil
local methods = {}

local function widget(kind, parent)
    local result = setmetatable({
        kind = kind, parent = parent, alpha = 1, shown = true,
        points = {}, scripts = {},
    }, {__index = methods})
    created[#created + 1] = result
    lastFrame = result
    return result
end

function methods:GetObjectType() return self.kind end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetShown(value) self.shown = value and true or false end
function methods:IsShown() return self.shown end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(point, relative, relativePoint, x, y)
    self.points[#self.points + 1] = {point = point, relative = relative, relativePoint = relativePoint, x = x or 0, y = y or 0}
end
function methods:SetHeight(height) self.height = height end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetFont() end
function methods:SetShadowColor() end
function methods:SetTexture() end
function methods:SetTexCoord() end
function methods:SetVertexColor() end
function methods:SetJustifyH(justify) self.justify = justify end
function methods:SetText(text) self.text = text end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:HookScript(name, callback) self.scripts[name] = callback end
function methods:RegisterEvent() end
function methods:CreateTexture(_, layer)
    local texture = widget("Texture", self)
    texture.layer = layer
    return texture
end
function methods:CreateFontString(_, layer)
    local text = widget("FontString", self)
    text.layer = layer
    return text
end

function CreateFrame(kind) return widget(kind or "Frame") end

function hooksecurefunc(target, method, callback)
    local original = target[method]
    target[method] = function(self, ...)
        if original then original(self, ...) end
        callback(self, ...)
    end
end

local function assertPoint(region, index, expected, label)
    local actual = region.points[index]
    assert(actual, label .. " has no point " .. index)
    assert(actual.point == expected.point and actual.relativePoint == expected.relativePoint
        and actual.relative == expected.relative and actual.x == (expected.x or 0) and actual.y == (expected.y or 0),
        label .. " anchored incorrectly")
end

local buildNumber = 16001
function GetBuildInfo() return "", "", "", buildNumber end
local styledHeaders, detailPanels = {}, {}
namespace.StyleForeverCollapsibleHeader = function(row) styledHeaders[#styledHeaders + 1] = row end
namespace.StyleDetailPanel = function(frame) detailPanels[#detailPanels + 1] = frame end
namespace.Themes = {GetPalette = function() return {text = {0.9, 0.9, 0.9, 1}} end}

-- Forever SkillsBarTemplate: a StatusBar that inherits ColoredProgressBarTemplate and SkillsBarMixin.
local function skillsBar(parent, progress, percent)
    local bar = widget("StatusBar", parent)
    bar.FillArea = widget("Frame", bar)
    local background = widget("Texture", bar)
    bar.Fill = widget("Texture", bar)
    bar.Fill.GetVertexColor = function() return 1, 1, 1, 1 end
    bar.Mask = widget("MaskTexture", bar)
    bar.Text = widget("FontString", bar)
    bar.nativeRegions = {background, bar.Fill, bar.Mask, bar.Text}
    bar.GetRegions = function(self) return unpack(self.nativeRegions) end
    bar.GetStatusBarTexture = function() return nil end
    bar.GetWidth = function() return 400 end
    bar.fillPercent = percent
    bar.barProgressText = progress
    function bar:SetFillPercent(value) self.fillPercent = value end
    function bar:UpdateBarColor(color) self.Fill:SetVertexColor(color:GetRGB()) end
    function bar:UpdateBarProgressText(text) self.barProgressText = text end
    return bar
end

local function entry(progress, percent, subHeader)
    local frame = widget("Button")
    local content = widget("Frame", frame)
    frame.Content = content
    content.Name = widget("FontString", content)
    content.SkillsBar = skillsBar(content, progress, percent)
    if subHeader then frame.ToggleCollapseButton = widget("Button", frame) end
    return frame
end

local function header()
    local row = widget("Button")
    row.Name = widget("FontString", row)
    row.StateIcon = widget("Texture", row)
    return row
end

local frames, extentCalculator = {}, nil
local function load(build)
    buildNumber = build
    styledHeaders, detailPanels, extentCalculator = {}, {}, nil
    local detail = widget("Frame")
    detail.Divider = widget("Texture", detail)
    detail.RankBar = skillsBar(detail, "150 / 300", 0.5)
    _G.SkillsFrame = {
        SkillDetailFrame = detail,
        ScrollBox = {
            GetView = function()
                return {SetElementExtentCalculator = function(_, calculator) extentCalculator = calculator end}
            end,
            ForEachFrame = function(_, callback) for _, frame in ipairs(frames) do callback(frame) end end,
            FullUpdate = function() end,
        },
    }
    assert(loadfile("FFXIV_UI\\General\\ProgressBars.lua"))("FFXIV_UI", namespace)
    assert(loadfile("FFXIV_UI\\General\\Skills.lua"))("FFXIV_UI", namespace)
    local watcher = lastFrame
    watcher.scripts.OnEvent(watcher, "PLAYER_LOGIN")
    return detail
end

local retailHeader, retailRow = header(), entry("1 / 1", 1)
frames = {retailHeader, retailRow}
local retailDetail = load(110005)
assert(extentCalculator == nil and #styledHeaders == 0 and #detailPanels == 0, "Retail has no Skills tab to style")
assert(not retailRow.Content.SkillsBar.FFXIVUITrack and not retailDetail.RankBar.FFXIVUITrack,
    "Retail must leave skill bars untouched")
print("PASS Skills styling is Forever only")

local skillHeader = header()
local swords = entry("75 |cnPURE_GREEN_COLOR:(+5)|r / 300", 0.25)
local subHeader = entry("10 / 75", 0.1, true)
frames = {skillHeader, swords, subHeader}
local detail = load(16001)

assert(#styledHeaders == 1 and styledHeaders[1] == skillHeader, "Skills headers must use the Forever ComboBox header")
assert(extentCalculator(nil, {isHeader = true}) == 26, "top-level headers keep the header extent")
assert(extentCalculator(nil, {}) == 56, "entries get room for the name, track and progress")
assert(extentCalculator(nil, {isHeader = true, isChild = true}) == 56, "sub-headers keep their bar, so use the entry extent")
print("PASS Skills headers route to the Forever header path with matching extents")

local content, bar = swords.Content, swords.Content.SkillsBar
local background, fill, mask, text = unpack(bar.nativeRegions)
assert(background.alpha == 0 and fill.alpha == 0 and text.alpha == 0, "native stat-bar art and centred text must be hidden")
assert(mask.alpha == 1, "the fill mask is left alone")
text:Show()
assert(text.alpha == 0, "native centred text must stay hidden")
assert(bar.FFXIVUITrack and bar.FFXIVUIFill, "skill rows must use the pill track")
print("PASS Skills rows hide the native ColoredProgressBar art")

assertPoint(content.Name, 1, {point = "TOPLEFT", relative = content, relativePoint = "TOPLEFT", x = 8, y = -1}, "skill name")
assertPoint(bar, 1, {point = "TOPLEFT", relative = content, relativePoint = "TOPLEFT", x = 8, y = -23}, "skill track")
assertPoint(bar, 2, {point = "TOPRIGHT", relative = content, relativePoint = "TOPRIGHT", x = -8, y = -23}, "skill track right")
assert(bar.height == 10, "skill track must stay thin")
local progress = content.FFXIVUIProgress
assert(progress and progress.text == "75 |cnPURE_GREEN_COLOR:(+5)|r / 300", "progress keeps Blizzard's text and modifier")
assertPoint(progress, 1, {point = "TOPLEFT", relative = bar, relativePoint = "BOTTOMLEFT", x = 0, y = -3}, "skill progress")
assert(progress.justify == "LEFT", "skill progress must be left-aligned")
assert(content.FFXIVUIStanding == nil, "skills have no named rank, so no standing label")
assertPoint(subHeader.Content.Name, 1,
    {point = "TOPLEFT", relative = subHeader.Content, relativePoint = "TOPLEFT", x = 30, y = -1}, "sub-header name")
print("PASS Skills rows show the name, pill track and only the progress number, left-aligned")

local function fillWidth(target)
    local total = 0
    for _, region in ipairs(created) do
        if region.parent == target and region.layer == "BORDER" and region.shown and region.width then
            total = total + region.width
        end
    end
    return total
end
local before = fillWidth(bar)
assert(before > 0, "fill must follow fillPercent")
bar:SetFillPercent(0.8)
assert(fillWidth(bar) > before, "fill must refresh when SetFillPercent runs")
bar:UpdateBarColor({GetRGB = function() return 1, 1, 1 end})
bar:UpdateBarProgressText("80 / 300")
assert(progress.text == "80 / 300", "progress must refresh when Blizzard sets the progress text last")
print("PASS Skills fill and progress follow native updates")

assert(#detailPanels == 1 and detailPanels[1] == detail, "SkillDetailFrame must get the surface panel")
local rankBar = detail.RankBar
assert(rankBar.FFXIVUITrack, "detail RankBar must use the pill track")
assertPoint(rankBar, 1, {point = "TOP", relative = detail.Divider, relativePoint = "BOTTOM", x = 0, y = -6}, "RankBar top")
assertPoint(rankBar, 2, {point = "LEFT", relative = detail, relativePoint = "LEFT"}, "RankBar left")
assertPoint(rankBar, 3, {point = "RIGHT", relative = detail, relativePoint = "RIGHT", x = -14}, "RankBar right")
local rankProgress = rankBar.FFXIVUIProgress
assert(rankProgress.parent == rankBar and rankProgress.text == "150 / 300" and rankProgress.justify == "LEFT",
    "detail progress text must sit on the bar, left-aligned")
assertPoint(rankProgress, 1, {point = "TOPLEFT", relative = rankBar, relativePoint = "TOPLEFT", x = 0, y = -13},
    "detail progress below the track")
rankBar:UpdateBarProgressText("151 / 300")
assert(rankProgress.text == "151 / 300", "detail progress must refresh on skill change")
print("PASS Skills detail RankBar uses the pill track with progress below, left-aligned")

for _, file in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local handle = assert(io.open(file, "r"))
    local toc = handle:read("*a")
    handle:close()
    local shared = assert(toc:find("General/ProgressBars.lua", 1, true), file .. " must load ProgressBars.lua")
    assert(shared < assert(toc:find("General/Reputation.lua", 1, true)), file .. " must load ProgressBars before Reputation")
    assert(shared < assert(toc:find("General/Skills.lua", 1, true)), file .. " must load ProgressBars before Skills")
end
print("PASS Skills and Reputation load after the shared progress bar module in both TOCs")
