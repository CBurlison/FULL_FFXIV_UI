 --print ("Paladin Gauge Loaded")
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local ADDON_NAME = ...
local MAX_HOLY_POWER = 5
local addonName, addonEnv = ...
local POWER_TYPE = Enum and Enum.PowerType and Enum.PowerType.HolyPower
addonEnv.OnPlayerPowerReady(POWER_TYPE, function()

local gaugeFullSFX = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg"  
local function PlayGaugeSFX(filePath)
    if FFXIV_UI_DB and FFXIV_UI_DB.sfxEnabled then
        PlaySoundFile(filePath, "Master")
    end
end
 
local frame = HolyPowerTrackerFrame

local anchor = FFXIV_UI_Anchors.JobGauge

 
frame:SetParent(anchor)
frame:ClearAllPoints()
frame:SetPoint("CENTER", anchor, "CENTER", 0, 0)
 
frame.orbs = {frame.orb1, frame.orb2, frame.orb3, frame.orb4, frame.orb5}

local previousHolyPower = nil

local FADE_TIME = 0.15 

local function UpdateHolyPower()
    local power = UnitPower("player", POWER_TYPE) or 0

    if previousHolyPower == nil then
        previousHolyPower = power
    end

    for i = 1, MAX_HOLY_POWER do
        if i <= power then
            frame.orbs[i]:Show()
            UIFrameFadeIn(frame.orbs[i], FADE_TIME, frame.orbs[i]:GetAlpha(), 1)
        else
            frame.orbs[i]:Hide()
            UIFrameFadeOut(frame.orbs[i], FADE_TIME, frame.orbs[i]:GetAlpha(), 0)
        end
    end

    if power == MAX_HOLY_POWER and previousHolyPower < MAX_HOLY_POWER then
          PlayGaugeSFX(gaugeFullSFX)
    end

    previousHolyPower = power
end

 
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, unit, powerType)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateHolyPower()
    elseif unit == "player" and powerType == "HOLY_POWER" then
        UpdateHolyPower()
    end
end)

UpdateHolyPower()
frame:Show()
end)
