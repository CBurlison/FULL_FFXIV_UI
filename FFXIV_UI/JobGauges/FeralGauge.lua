--print("Feral Gauge Loaded")

local _, class = UnitClass("player")
if class ~= "DRUID" then return end

local addonName, addonEnv = ...
local MAX_COMBO_POINTS = 5
local POWER_TYPE = 4  
addonEnv.OnPlayerPowerReady(POWER_TYPE, function()
local FADE_TIME = 0.2

local gaugeFullSFX = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg"
local function PlayGaugeSFX(filePath)
    if FFXIV_UI_DB and FFXIV_UI_DB.sfxEnabled then
        PlaySoundFile(filePath, "Master")
    end
end
 
local frame = ComboTrackerFrame

local anchor = FFXIV_UI_Anchors.JobGauge
frame:SetParent(anchor)
frame:SetPoint("CENTER", anchor, "CENTER", 0, 0)

frame.orbs = {frame.orb1, frame.orb2, frame.orb3, frame.orb4, frame.orb5}
frame.currentPoints = 0

local function InCatForm()
    return GetShapeshiftFormID() == 1
end

local function FadeInOrb(orb)
    orb:Show()
    UIFrameFadeIn(orb, FADE_TIME, orb:GetAlpha(), 1)
    orb.fadingOut = nil
end

local function FadeOutOrb(orb)
    UIFrameFadeOut(orb, FADE_TIME, orb:GetAlpha(), 0)
    orb.fadingOut = true
    C_Timer.After(FADE_TIME, function()
        if orb.fadingOut and orb:GetAlpha() == 0 then
            orb:Hide()
        end
    end)
end

local function UpdateVisibility()
    if InCatForm() then
        frame:Show()
    else
        frame:Hide()
    end
end

local previousFeralPoints = nil

local function UpdateComboPoints()
    if not InCatForm() then return end

    local comboPoints
    if GetComboPoints then
        comboPoints = GetComboPoints("player", "target") or 0
    else
        comboPoints = UnitPower("player", POWER_TYPE) or 0
    end

    if comboPoints > 0 or (UnitExists("target") and UnitCanAttack("player", "target")) then
        if not frame.base:IsShown() or frame.base.fadingOut then
            FadeInOrb(frame.base)
        end
    elseif frame.base:IsShown() and not frame.base.fadingOut then
        FadeOutOrb(frame.base)
    end

    if previousFeralPoints == nil then
        previousFeralPoints = comboPoints
    end

    if comboPoints ~= frame.currentPoints then
        for i = 1, MAX_COMBO_POINTS do
            if i <= comboPoints and i > frame.currentPoints then
                FadeInOrb(frame.orbs[i])
            elseif i > comboPoints and i <= frame.currentPoints then
                FadeOutOrb(frame.orbs[i])
            end
        end
    end

if comboPoints == MAX_COMBO_POINTS and previousFeralPoints < MAX_COMBO_POINTS then
    PlayGaugeSFX(gaugeFullSFX)
end

    frame.currentPoints = comboPoints
    previousFeralPoints = comboPoints
end

frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_FACTION")

frame:SetScript("OnEvent", function(self, event, unit, powerType)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateVisibility()
        UpdateComboPoints()
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        UpdateVisibility()
        UpdateComboPoints()
    elseif event == "UNIT_POWER_UPDATE" and unit == "player" and powerType == "COMBO_POINTS" then
        UpdateComboPoints()
    elseif event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_FACTION" and unit == "target") then
        UpdateComboPoints()
    end
end)

UpdateVisibility()
UpdateComboPoints()
end)
