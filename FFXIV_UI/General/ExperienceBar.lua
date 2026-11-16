--print("FFXIV UI Player XP Frame loaded")

local f = FFPlayerXPFrame

local anchor = FFXIV_UI_Anchors.ExpBar
f:SetParent(anchor)
f:ClearAllPoints()
f:SetPoint("CENTER", anchor, "CENTER", 0, 0)

local restedBar = f.restedBar
local xpBar = f.xpBar
local restedIndicator = f.restedIndicator
local outlineFrame = f.outlineFrame
outlineFrame:SetFrameLevel(f:GetFrameLevel() + 5)

local classLabel = outlineFrame.classLabel
local LLabel = outlineFrame.LLabel
local vLabel = outlineFrame.vLabel
local levelText = outlineFrame.levelText
local xpNumbers = outlineFrame.xpNumbers
local xpPercent = outlineFrame.xpPercent

xpBar:GetStatusBarTexture():SetDrawLayer("ARTWORK", 0)
restedBar:GetStatusBarTexture():SetDrawLayer("ARTWORK", -1)

local CLASS_ABBR = {
    WARRIOR     = "WAR",
    PALADIN     = "PLD",
    HUNTER      = "HUN",
    ROGUE       = "ROG",
    PRIEST      = "PRI",
    DEATHKNIGHT = "DKN",
    SHAMAN      = "SHM",
    MAGE        = "MAG",
    WARLOCK     = "WLK",
    MONK        = "MNK",
    DRUID       = "DRU",
    DEMONHUNTER = "DHM",
    EVOKER      = "EV0",
}

local function HideDefaultXPBar()
    if MainMenuExpBar then
        MainMenuExpBar:UnregisterAllEvents()
        MainMenuExpBar:Hide()
    end
    if StatusTrackingBarManager then
        StatusTrackingBarManager:UnregisterAllEvents()
        StatusTrackingBarManager:Hide()
    end
end

HideDefaultXPBar()

local function UpdateXP()
    local currXP  = UnitXP("player")
    local maxXP   = UnitXPMax("player")
    local rested  = GetXPExhaustion() or 0
    local percent = maxXP > 0 and (currXP / maxXP) * 100 or 0

    levelText:SetText(UnitLevel("player"))
    classLabel:SetText(CLASS_ABBR[select(2, UnitClass("player"))] or "")

    xpBar:SetMinMaxValues(0, maxXP)
    xpBar:SetValue(currXP)

    if rested > 0 then
        restedBar:SetMinMaxValues(0, maxXP)
        restedBar:SetValue(math.min(currXP + rested, maxXP))
        restedBar:Show()
    else
        restedBar:Hide()
    end

    restedIndicator:SetShown(IsResting())

    xpNumbers:SetText(string.format("EXP %d/%d", currXP, maxXP))
    xpPercent:SetText(string.format("(%.0f%%)", percent))
end

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("PLAYER_UPDATE_RESTING")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")

f:SetScript("OnEvent", UpdateXP)
UpdateXP()
 