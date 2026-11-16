local addonName, ns = ...

-- Pill-track styling shared by the character-screen progress bars (Reputation, Skills).
local ProgressBars = {}
ns.ProgressBars = ProgressBars

local FONT = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf"
local PILL = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Bar-Pill.tga"
local TRACK_HEIGHT, FILL_HEIGHT, FILL_INSET = 10, 6, 2
local BAR_FILL, BAR_TRACK = {0.55, 0.72, 0.18, 1}, {0.24, 0.24, 0.24, 1}
ProgressBars.TRACK_HEIGHT = TRACK_HEIGHT

function ProgressBars.Font(region, size)
    region:SetFont(ns.GetFont and ns.GetFont(FONT) or FONT, size, "")
    region:SetShadowColor(0, 0, 0, 0)
end
local Font = ProgressBars.Font

local function Label(owner, key)
    local label = owner[key]
    if not label then
        label = owner:CreateFontString(nil, "OVERLAY")
        owner[key] = label
    end
    return label
end

-- Three-slice pill: rounded caps around a stretched middle.
local function Pill(bar, layer, sublevel, color)
    local pieces = {}
    local coords = {{0, 0.25}, {0.25, 0.75}, {0.75, 1}}
    for index = 1, 3 do
        local piece = bar:CreateTexture(nil, layer, nil, sublevel)
        piece:SetTexture(PILL)
        piece:SetTexCoord(coords[index][1], coords[index][2], 0, 1)
        piece:SetVertexColor(unpack(color))
        pieces[index] = piece
    end
    local pill = {}
    function pill:Hide() for _, piece in ipairs(pieces) do piece:Hide() end end
    function pill:Place(x, y, width, height)
        local cap = height / 2
        width = math.max(width, height)
        local layout = {{x, cap}, {x + cap, width - height}, {x + width - cap, cap}}
        for index, piece in ipairs(pieces) do
            piece:ClearAllPoints()
            piece:SetPoint("TOPLEFT", bar, "TOPLEFT", layout[index][1], -y)
            piece:SetSize(layout[index][2], height)
            piece:Show()
        end
    end
    return pill
end

-- Forever bars inherit ColoredProgressBarTemplate (fillPercent, Fill, Text). Skills bars are
-- StatusBar widgets built on it, so the widget type alone does not identify them.
local function IsColoredProgressBar(bar)
    return type(bar.SetFillPercent) == "function"
end

local function BarRatio(bar)
    if IsColoredProgressBar(bar) then return bar.fillPercent or 0 end
    local minValue, maxValue = bar:GetMinMaxValues()
    return maxValue > minValue and (bar:GetValue() - minValue) / (maxValue - minValue) or 0
end

function ProgressBars.Refresh(bar)
    local width = bar:GetWidth()
    if not bar.FFXIVUITrack or not width or width <= 0 then return end
    bar.FFXIVUITrack:Place(0, 0, width, TRACK_HEIGHT)
    local ratio = math.max(0, math.min(1, BarRatio(bar)))
    if ratio <= 0 then
        bar.FFXIVUIFill:Hide()
    else
        bar.FFXIVUIFill:Place(FILL_INSET, (TRACK_HEIGHT - FILL_HEIGHT) / 2,
            (width - 2 * FILL_INSET) * ratio, FILL_HEIGHT)
    end
end
local Refresh = ProgressBars.Refresh

-- Blizzard's standing colours are dark for text on a dark panel.
local function Lighten(r, g, b)
    return r * 0.75 + 0.25, g * 0.75 + 0.25, b * 0.75 + 0.25
end

-- Blizzard re-shows some regions during updates, so hide them and re-hide on any change.
local function HideKeptHidden(region)
    if not region then return end
    region:SetAlpha(0)
    hooksecurefunc(region, "SetAlpha", function(self, alpha)
        if alpha ~= 0 then self:SetAlpha(0) end
    end)
    hooksecurefunc(region, "Show", function(self) self:SetAlpha(0) end)
end

local function HideNativeBar(bar)
    if not IsColoredProgressBar(bar) then
        bar.LeftTexture:SetAlpha(0)
        bar.RightTexture:SetAlpha(0)
        HideKeptHidden(bar.BarText)
        bar.Background:SetAlpha(0)
        bar:GetStatusBarTexture():SetAlpha(0)
        return {bar:GetStatusBarColor()}
    end
    -- The unnamed common-stat-bar-BG texture, Fill and the centred Text. The Mask only clips Fill.
    for _, region in ipairs({bar:GetRegions()}) do
        if region ~= bar.Text and region:GetObjectType() ~= "MaskTexture" then HideKeptHidden(region) end
    end
    HideKeptHidden(bar.Text)
    hooksecurefunc(bar, "SetFillPercent", Refresh)
    return bar.Fill and {bar.Fill:GetVertexColor()} or {}
end

function ProgressBars.UpdateLabels(bar)
    local standing, progress = bar.FFXIVUIStanding, bar.FFXIVUIProgress
    if standing then
        local color = bar.FFXIVUIStandingColor or {}
        standing:SetTextColor(Lighten(color[1] or 1, color[2] or 1, color[3] or 1))
        standing:SetText(bar.reputationStandingText or "")
        standing:SetShown(bar:IsShown())
    end
    if progress then
        progress:SetText(bar.barProgressText or "")
        progress:SetShown(bar:IsShown())
    end
end
local UpdateLabels = ProgressBars.UpdateLabels

-- Replaces the native bar art with the pill track and fill. Labels refresh after the hooks Blizzard's
-- initializers call: Reputation calls UpdateBarColor last, Skills calls UpdateBarProgressText last.
function ProgressBars.Skin(bar)
    if bar.FFXIVUITrack then return end
    bar.FFXIVUIStandingColor = HideNativeBar(bar)
    bar.FFXIVUITrack = Pill(bar, "BACKGROUND", 1, BAR_TRACK)
    bar.FFXIVUIFill = Pill(bar, "BORDER", 1, BAR_FILL)
    if type(bar.UpdateBarColor) == "function" then
        hooksecurefunc(bar, "UpdateBarColor", function(self, color)
            self.FFXIVUIStandingColor = {color:GetRGB()}
            UpdateLabels(self)
        end)
    end
    if type(bar.UpdateBarProgressText) == "function" then
        hooksecurefunc(bar, "UpdateBarProgressText", UpdateLabels)
    end
    bar:HookScript("OnSizeChanged", Refresh)
end

-- List row: name top-left, full-width track, labels below. With a standing label the progress
-- sits bottom-right (Retail reputation layout); without one it sits bottom-left.
function ProgressBars.LayoutRow(content, bar, nameLeft, withStanding)
    local palette = ns.Themes.GetPalette()
    content.Name:ClearAllPoints()
    content.Name:SetPoint("TOPLEFT", content, "TOPLEFT", nameLeft, -1)
    content.Name:SetPoint("TOPRIGHT", content, "TOPRIGHT", -28, -1)
    content.Name:SetTextColor(unpack(palette.text))

    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -23)
    bar:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -23)
    bar:SetHeight(TRACK_HEIGHT)
    Refresh(bar)

    if withStanding then
        local standing = Label(content, "FFXIVUIStanding")
        Font(standing, 12)
        standing:ClearAllPoints()
        standing:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -3)
        standing:SetJustifyH("LEFT")
        bar.FFXIVUIStanding = standing
    end

    local progress = Label(content, "FFXIVUIProgress")
    Font(progress, 12)
    progress:ClearAllPoints()
    if withStanding then
        progress:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -3)
        progress:SetJustifyH("RIGHT")
    else
        progress:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -3)
        progress:SetJustifyH("LEFT")
    end
    progress:SetTextColor(unpack(palette.text))
    bar.FFXIVUIProgress = progress
    UpdateLabels(bar)
end

-- Detail-pane bar: spans the Description width with the progress text below, left-aligned.
-- The bar frame keeps its native 29px height so Blizzard's Description anchor below it still clears
-- the track and the progress text drawn inside it.
function ProgressBars.StyleDetailBar(frame, bar)
    if not bar or bar.FFXIVUITrack then return end
    ProgressBars.Skin(bar)
    if frame.Divider then
        bar:ClearAllPoints()
        bar:SetPoint("TOP", frame.Divider, "BOTTOM", 0, -6)
        bar:SetPoint("LEFT", frame, "LEFT", 0, 0)
        bar:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
    end
    local progress = bar:CreateFontString(nil, "OVERLAY")
    Font(progress, 12)
    progress:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -(TRACK_HEIGHT + 3))
    progress:SetJustifyH("LEFT")
    progress:SetTextColor(unpack(ns.Themes.GetPalette().text))
    bar.FFXIVUIProgress = progress
    UpdateLabels(bar)
    Refresh(bar)
end
