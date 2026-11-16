 --print ("Mage Gauge Loaded")
local _, class = UnitClass("player")
if class ~= "MAGE" then return end

local ADDON_NAME = ...
local MAX_ARCANE_CHARGES = 4
local addonName, addonEnv = ...
local POWER_TYPE = Enum and Enum.PowerType and Enum.PowerType.ArcaneCharges
addonEnv.OnPlayerPowerReady(POWER_TYPE, function()

local gaugeFullSFX = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg"    
local function PlayGaugeSFX(filePath)
    if FFXIV_UI_DB and FFXIV_UI_DB.sfxEnabled then
        PlaySoundFile(filePath, "Master")
    end
end
 
local frame = ArcaneChargeFrame

local anchor = FFXIV_UI_Anchors.JobGauge
local ARCANE_SPEC_ID = 62

local function IsArcaneSpec()
    if not GetSpecialization then return true end
    local index = GetSpecialization()
    if not index then return false end
    return GetSpecializationInfo(index) == ARCANE_SPEC_ID
end

 
frame:SetParent(anchor)
frame:ClearAllPoints()
frame:SetPoint("CENTER", anchor, "CENTER", 0, 0)
 
frame.orbs = {frame.orb1, frame.orb2, frame.orb3, frame.orb4}

local previousArcaneCharges = nil

local FADE_TIME = 0.15
 
local function UpdateArcaneCharges()
    if not IsArcaneSpec() then
        frame:Hide()
        return
    end

    local power = UnitPower("player", POWER_TYPE) or 0
    frame:Show()

    if previousArcaneCharges == nil then
        previousArcaneCharges = power
    end

    for i = 1, MAX_ARCANE_CHARGES do
        if i <= power then
            frame.orbs[i]:Show()
            UIFrameFadeIn(frame.orbs[i], FADE_TIME, frame.orbs[i]:GetAlpha(), 1)
        else
            frame.orbs[i]:Hide()
            UIFrameFadeOut(frame.orbs[i], FADE_TIME, frame.orbs[i]:GetAlpha(), 0)
        end
    end

    if power == MAX_ARCANE_CHARGES and previousArcaneCharges < MAX_ARCANE_CHARGES then
         PlayGaugeSFX(gaugeFullSFX)
    end

    previousArcaneCharges = power
end

 
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")

frame:SetScript("OnEvent", function(self, event, unit, powerType)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        UpdateArcaneCharges()
    elseif unit == "player" and powerType == "ARCANE_CHARGES" then
        UpdateArcaneCharges()
    end
end)
UpdateArcaneCharges()
end)
