local namespace = {}
local created, lastFrame, hooks = {}, nil, {}
local methods = {}

local function widget(kind, parent)
    local result = setmetatable({
        kind = kind, parent = parent, alpha = 1, shown = true,
        points = {}, scripts = {}, children = {}, regions = {},
    }, {__index = methods})
    created[#created + 1] = result
    lastFrame = result
    return result
end

function methods:GetObjectType() return self.kind end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:GetAlpha() return self.alpha end
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
function methods:GetText() return self.text end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:HookScript(name, callback) self.scripts[name] = callback end
function methods:RegisterEvent() end
function methods:CreateTexture(_, layer, _, sublevel)
    local texture = widget("Texture", self)
    texture.layer, texture.sublevel = layer, sublevel
    return texture
end
function methods:CreateFontString(_, layer)
    local text = widget("FontString", self)
    text.layer = layer
    return text
end

function CreateFrame(kind)
    return widget(kind or "Frame")
end

-- Wraps the existing method so both the original and the hook run, matching Blizzard's post-hook behaviour.
function hooksecurefunc(target, method, callback)
    local original = target[method]
    hooks[#hooks + 1] = {target = target, method = method}
    target[method] = function(self, ...)
        if original then original(self, ...) end
        callback(self, ...)
    end
end

local function point(region, index)
    return region.points[index]
end

local function assertPoint(region, index, expected, label)
    local actual = point(region, index)
    assert(actual, label .. " has no point " .. index)
    assert(actual.point == expected.point and actual.relativePoint == expected.relativePoint
        and actual.relative == expected.relative and actual.x == (expected.x or 0) and actual.y == (expected.y or 0),
        label .. " anchored incorrectly")
end

local styledHeaders = {}
local buildNumber = 16001
function GetBuildInfo() return "", "", "", buildNumber end
namespace.StyleForeverCollapsibleHeader = function(row) styledHeaders[#styledHeaders + 1] = row end
namespace.Themes = {GetPalette = function() return {text = {0.9, 0.9, 0.9, 1}} end}

local function entry(standing, progress)
    local frame = widget("Frame")
    local content = widget("Frame", frame)
    frame.Content = content
    frame.ToggleCollapseButton = widget("Button", frame)
    content.Name = widget("FontString", content)
    content.AccountWideIcon = widget("Texture", content)
    local bar = widget("StatusBar", content)
    content.ReputationBar = bar
    bar.LeftTexture = widget("Texture", bar)
    bar.RightTexture = widget("Texture", bar)
    bar.Background = widget("Texture", bar)
    bar.BarText = widget("FontString", bar)
    bar.statusTexture = widget("Texture", bar)
    bar.GetStatusBarTexture = function(self) return self.statusTexture end
    bar.GetStatusBarColor = function() return 0.5, 0.8, 0.2 end
    bar.GetWidth = function() return 200 end
    bar.GetMinMaxValues = function() return 0, 100 end
    bar.GetValue = function() return 50 end
    bar.reputationStandingText = standing
    bar.barProgressText = progress
    return frame
end

local function header()
    local row = widget("Frame")
    row.Name = widget("FontString", row)
    row.StateIcon = widget("Texture", row)
    return row
end

-- Forever (build 16001): ReputationBarTemplate inherits ColoredProgressBarTemplate, a plain Frame.
local function foreverBar(parent, standing, progress, percent)
    local bar = widget("Frame", parent)
    bar.FillArea = widget("Frame", bar)
    local background = widget("Texture", bar)
    bar.Fill = widget("Texture", bar)
    bar.Fill.GetVertexColor = function() return 0, 0.6, 0.1, 1 end
    bar.Mask = widget("MaskTexture", bar)
    bar.Text = widget("FontString", bar)
    bar.nativeRegions = {background, bar.Fill, bar.Mask, bar.Text}
    bar.GetRegions = function(self) return unpack(self.nativeRegions) end
    bar.GetWidth = function() return 400 end
    bar.fillPercent = percent
    function bar:SetFillPercent(value) self.fillPercent = value end
    function bar:UpdateBarColor(color) self.Fill:SetVertexColor(color:GetRGB()) end
    bar.reputationStandingText = standing
    bar.barProgressText = progress
    return bar
end

local function foreverEntry(standing, progress, percent)
    local frame = widget("Button")
    local content = widget("Frame", frame)
    frame.Content = content
    content.Name = widget("FontString", content)
    content.AccountWideIcon = widget("Frame", content)
    content.ReputationBar = foreverBar(content, standing, progress, percent)
    return frame
end

local frames = {}
local extentCalculator
_G.ReputationFrame = {
    ScrollBox = {
        GetView = function()
            return {SetElementExtentCalculator = function(_, calculator) extentCalculator = calculator end}
        end,
        ForEachFrame = function(_, callback)
            for _, frame in ipairs(frames) do callback(frame) end
        end,
        FullUpdate = function() end,
    },
}

local header1 = header()
local rep = entry("Revered", "12,920 / 21,000")
local foreverRep = foreverEntry("Friendly", "450 / 3,000", 0.15)
frames = {header1, rep, foreverRep}

local styledPage
namespace.StyleListScrollBar = function(page) styledPage = page end
_G.ReputationFrame.ScrollBar = {}
assert(loadfile("FFXIV_UI\\General\\ProgressBars.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Reputation.lua"))("FFXIV_UI", namespace)
local watcher = lastFrame
watcher.scripts.OnEvent(watcher, "PLAYER_LOGIN")

assert(styledPage == _G.ReputationFrame, "reputation page scroll bar must use the Menu style")
assert(#styledHeaders == 1 and styledHeaders[1] == header1, "header rows must route to the Forever header path")
print("PASS Reputation header rows route to the Forever header path")

assert(extentCalculator(nil, {}) == 56, "entry rows must keep the entry extent")
assert(extentCalculator(nil, {isHeader = true}) == 26, "headers must keep the header extent")
print("PASS Reputation keeps the entry and header extent calculators")

local content, bar = rep.Content, rep.Content.ReputationBar
assert(bar.LeftTexture.alpha == 0 and bar.RightTexture.alpha == 0, "Blizzard bar caps must stay hidden")
assert(bar.Background.alpha == 0 and bar.statusTexture.alpha == 0, "Blizzard bar background and fill must stay hidden")
bar.BarText:SetAlpha(1)
assert(bar.BarText.alpha == 0, "native BarText must not reappear after SetAlpha")
bar.BarText:Show()
assert(bar.BarText.alpha == 0, "native BarText must not reappear after Show")
print("PASS Reputation native bar textures and BarText stay hidden")

assertPoint(content.Name, 1, {point = "TOPLEFT", relative = content, relativePoint = "TOPLEFT", x = 30, y = -1},
    "faction name")
assertPoint(bar, 1, {point = "TOPLEFT", relative = content, relativePoint = "TOPLEFT", x = 8, y = -23},
    "track")
assert(bar.height == 10, "track must stay thin")

local standing, progress
for _, region in ipairs(created) do
    if region.kind == "FontString" and region.text == "Revered" then standing = region end
    if region.kind == "FontString" and region.text == "12,920 / 21,000" then progress = region end
end
assert(standing and progress, "standing and progress labels were not created")
assertPoint(standing, 1, {point = "TOPLEFT", relative = bar, relativePoint = "BOTTOMLEFT", x = 0, y = -3},
    "standing text")
assertPoint(progress, 1, {point = "TOPRIGHT", relative = bar, relativePoint = "BOTTOMRIGHT", x = 0, y = -3},
    "progress text")
assert(standing.shown and progress.shown, "standing and progress must show with the bar")
assert(progress.justify == "RIGHT" and standing.justify == "LEFT", "labels must align to the Retail layout")
assert(bar.scripts.OnEnter == nil and bar.scripts.OnLeave == nil and progress.scripts.OnEnter == nil,
    "current / max must not depend on hover")
print("PASS Reputation labels use the Retail layout with current / max always visible")

do
    local fContent, fBar = foreverRep.Content, foreverRep.Content.ReputationBar
    local background, fill, mask, text = unpack(fBar.nativeRegions)
    assert(background.alpha == 0 and fill.alpha == 0, "Forever stat-bar background and fill must be hidden")
    assert(mask.alpha == 1, "Forever mask texture is left alone")
    assert(text.alpha == 0, "Forever centred Text must be hidden")
    text:Show()
    fill:SetAlpha(1)
    assert(text.alpha == 0 and fill.alpha == 0, "Forever native Text and Fill must stay hidden")
    print("PASS Reputation hides the Forever ColoredProgressBar visuals")

    assertPoint(fContent.Name, 1, {point = "TOPLEFT", relative = fContent, relativePoint = "TOPLEFT", x = 8, y = -1},
        "Forever faction name")
    assertPoint(fBar, 1, {point = "TOPLEFT", relative = fContent, relativePoint = "TOPLEFT", x = 8, y = -23},
        "Forever track")
    assertPoint(fBar, 2, {point = "TOPRIGHT", relative = fContent, relativePoint = "TOPRIGHT", x = -8, y = -23},
        "Forever track right edge")
    assert(fBar.height == 10, "Forever track must stay thin")

    local fStanding, fProgress = fContent.FFXIVUIStanding, fContent.FFXIVUIProgress
    assert(fStanding.text == "Friendly" and fProgress.text == "450 / 3,000", "Forever labels must use the bar texts")
    assertPoint(fStanding, 1, {point = "TOPLEFT", relative = fBar, relativePoint = "BOTTOMLEFT", x = 0, y = -3},
        "Forever standing text")
    assertPoint(fProgress, 1, {point = "TOPRIGHT", relative = fBar, relativePoint = "BOTTOMRIGHT", x = 0, y = -3},
        "Forever progress text")
    assert(fStanding.shown and fProgress.shown, "Forever labels must show with the bar")
    print("PASS Reputation Forever rows use the Retail label layout")

    local function fillWidth()
        local total = 0
        for _, region in ipairs(created) do
            if region.parent == fBar and region.layer == "BORDER" and region.shown and region.width then
                total = total + region.width
            end
        end
        return total
    end
    local before = fillWidth()
    assert(before > 0, "Forever fill must follow fillPercent")
    fBar:SetFillPercent(0.6)
    assert(fillWidth() > before, "Forever fill must refresh when SetFillPercent runs")

    fBar.reputationStandingText, fBar.barProgressText = "Honored", "100 / 6,000"
    fBar:UpdateBarColor({GetRGB = function() return 0, 0.6, 0.1 end})
    assert(fStanding.text == "Honored" and fProgress.text == "100 / 6,000",
        "Forever labels must refresh when the bar is re-initialised")
    assert(fStanding.textColor[2] > 0.6, "Forever standing text must use the lightened rank colour")
    print("PASS Reputation Forever fill and labels follow native updates")
end

local detailPanels = {}
namespace.StyleDetailPanel = function(frame) detailPanels[#detailPanels + 1] = frame end
local function loadDetail(build)
    buildNumber = build
    detailPanels = {}
    local detail = widget("Frame")
    detail.Divider = widget("Texture", detail)
    detail.StandingBar = foreverBar(detail, "Honored", "5,250 / 12,000", 0.4)
    detail.GetChildren = function() return end
    _G.ReputationFrame.ReputationDetailFrame = detail
    assert(loadfile("FFXIV_UI\\General\\ProgressBars.lua"))("FFXIV_UI", namespace)
    assert(loadfile("FFXIV_UI\\General\\Reputation.lua"))("FFXIV_UI", namespace)
    local loader = lastFrame
    loader.scripts.OnEvent(loader, "PLAYER_LOGIN")
    return detailPanels
end

local retailPanels = loadDetail(110005)
assert(#retailPanels == 0, "Retail must keep its expanded reputation frame")
assert(not _G.ReputationFrame.ReputationDetailFrame.StandingBar.FFXIVUITrack,
    "Retail must keep its native detail standing bar")
local foreverPanels = loadDetail(16001)
assert(#foreverPanels == 1 and foreverPanels[1] == _G.ReputationFrame.ReputationDetailFrame,
    "Forever must style ReputationDetailFrame with the surface panel")
print("PASS Reputation expanded frame gets the surface panel on Forever only")

do
    local detail = _G.ReputationFrame.ReputationDetailFrame
    local dBar = detail.StandingBar
    local background, fill, _, text = unpack(dBar.nativeRegions)
    assert(dBar.FFXIVUITrack and dBar.FFXIVUIFill, "Forever detail bar must use the pill track and fill")
    assert(background.alpha == 0 and fill.alpha == 0 and text.alpha == 0,
        "Forever detail bar must hide the native stat-bar art and centred Text")
    assertPoint(dBar, 1, {point = "TOP", relative = detail.Divider, relativePoint = "BOTTOM", x = 0, y = -6},
        "detail bar top")
    assertPoint(dBar, 2, {point = "LEFT", relative = detail, relativePoint = "LEFT"}, "detail bar left")
    assertPoint(dBar, 3, {point = "RIGHT", relative = detail, relativePoint = "RIGHT", x = -14}, "detail bar right")
    assert(dBar.height == nil, "detail bar keeps its native height so Description stays below the text")

    local dProgress = dBar.FFXIVUIProgress
    assert(dProgress and dProgress.parent == dBar, "detail progress text must belong to the bar")
    assert(dProgress.text == "5,250 / 12,000", "detail progress text must use barProgressText")
    assert(dProgress.justify == "LEFT", "detail progress text must be left-aligned")
    assertPoint(dProgress, 1, {point = "TOPLEFT", relative = dBar, relativePoint = "TOPLEFT", x = 0, y = -13},
        "detail progress text below the track")
    assert(dBar.FFXIVUIStanding == nil, "detail bar shows no standing label; the pane title already has it")

    dBar.barProgressText = "6,000 / 12,000"
    dBar:UpdateBarColor({GetRGB = function() return 0, 0.6, 0.1 end})
    assert(dProgress.text == "6,000 / 12,000", "detail progress text must refresh on faction change")
    print("PASS Reputation Forever detail bar uses the pill track with progress text below, left-aligned")
end
