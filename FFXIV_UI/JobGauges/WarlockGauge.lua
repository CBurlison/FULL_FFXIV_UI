--print("Warlock Soul Shard Gauge Loaded")

local _, class = UnitClass("player")
if class ~= "WARLOCK" then return end

local addonName, addonEnv = ...
local MAX_SOUL_SHARDS = 5
local POWER_TYPE = 7  
addonEnv.OnPlayerPowerReady(POWER_TYPE, function()
local gaugeFullSFX = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg" 
 local function PlayGaugeSFX(filePath)
    if FFXIV_UI_DB and FFXIV_UI_DB.sfxEnabled then
        PlaySoundFile(filePath, "Master")
    end
end

local frame = SoulShardTrackerFrame

local anchor = FFXIV_UI_Anchors.JobGauge
frame:SetParent(anchor)
frame:ClearAllPoints()
frame:SetPoint("CENTER", anchor, "CENTER", 0, 0)

frame.orbs = {frame.orb1, frame.orb2, frame.orb3, frame.orb4, frame.orb5}

local previousShards = nil

local FADE_TIME = 0.15
local function UpdateSoulShards()
    local shards = UnitPower("player", POWER_TYPE) or 0

    if previousShards == nil then
        previousShards = shards
    end

    for i = 1, MAX_SOUL_SHARDS do
        if i <= shards then
            frame.orbs[i]:Show()
            UIFrameFadeIn(frame.orbs[i], FADE_TIME, frame.orbs[i]:GetAlpha(), 1)
        else
            frame.orbs[i]:Hide()
            UIFrameFadeOut(frame.orbs[i], FADE_TIME, frame.orbs[i]:GetAlpha(), 0)
        end
    end

    if shards == MAX_SOUL_SHARDS and previousShards < MAX_SOUL_SHARDS then
         PlayGaugeSFX(gaugeFullSFX)
    end

    previousShards = shards
end

frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, unit, powerType)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateSoulShards()
    elseif unit == "player" and powerType == "SOUL_SHARDS" then
        UpdateSoulShards()
    end
end)

UpdateSoulShards()
frame:Show()
end)

