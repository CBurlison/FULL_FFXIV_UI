--print("Rogue Combo Point Gauge Loaded")

local _, class = UnitClass("player")
if class ~= "ROGUE" then return end
local addonName, addonEnv = ...
local gaugeFullSFX = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg"
 local function PlayGaugeSFX(filePath)
    if FFXIV_UI_DB and FFXIV_UI_DB.sfxEnabled then
        PlaySoundFile(filePath, "Master")
    end
end
local POWER_TYPE = Enum and Enum.PowerType and Enum.PowerType.ComboPoints
addonEnv.OnPlayerPowerReady(POWER_TYPE, function()

 
local FRAME_TEXTURE_5 =
    "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\Rogue\\FFRogueFrame"

local FRAME_TEXTURE_6 =
    "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\Rogue\\FFRogueFrame6"

local FRAME_TEXTURE_7 =
    "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\Rogue\\FFRogueFrame7"

 
local frame = ComboPointTrackerFrame

local anchor = FFXIV_UI_Anchors.JobGauge
frame:SetParent(anchor)
frame:SetPoint("CENTER", anchor, "CENTER", 0, 0)

frame.orbs = {frame.orb1, frame.orb2, frame.orb3, frame.orb4, frame.orb5, frame.orb6, frame.orb7}
 
local MAX_COMBO_POINTS = 5

 
local function ConfigureComboPoints()
    local max = UnitPowerMax("player", POWER_TYPE) or 5

    if max < 5 then max = 5 end
    if max > 7 then max = 7 end

    if MAX_COMBO_POINTS == max then return end
    MAX_COMBO_POINTS = max

    if max == 5 then
        frame.base:SetTexture(FRAME_TEXTURE_5)
    elseif max == 6 then
        frame.base:SetTexture(FRAME_TEXTURE_6)
    elseif max == 7 then
        frame.base:SetTexture(FRAME_TEXTURE_7)
    else
        frame.base:SetTexture(FRAME_TEXTURE_5)
    end
end


local previousComboPoints = nil

local FADE_TIME = 0.15  

local function UpdateComboPoints()
    local points
    if GetComboPoints then
        points = GetComboPoints("player", "target") or 0
    else
        points = UnitPower("player", POWER_TYPE) or 0
    end
    if points > 0 or (UnitExists("target") and UnitCanAttack("player", "target")) then
        if not frame.base:IsShown() or frame.base.fadingOut then
            UIFrameFadeIn(frame.base, FADE_TIME, frame.base:GetAlpha(), 1)
            frame.base.fadingOut = nil
        end
    elseif frame.base:IsShown() and not frame.base.fadingOut then
        UIFrameFadeOut(frame.base, FADE_TIME, frame.base:GetAlpha(), 0)
        frame.base.fadingOut = true
    end

    if previousComboPoints == nil then
        previousComboPoints = points
    end

    for i = 1, 7 do
        if i <= MAX_COMBO_POINTS and i <= points then
            if not frame.orbs[i]:IsShown() or frame.orbs[i].fadingOut then
                
                UIFrameFadeIn(frame.orbs[i], FADE_TIME, frame.orbs[i]:GetAlpha(), 1)
                frame.orbs[i].fadingOut = nil
            end
        else
            if frame.orbs[i]:IsShown() and not frame.orbs[i].fadingOut then
                
                UIFrameFadeOut(frame.orbs[i], FADE_TIME, frame.orbs[i]:GetAlpha(), 0)
                frame.orbs[i].fadingOut = true
            end
        end
    end

    if points == MAX_COMBO_POINTS and previousComboPoints < MAX_COMBO_POINTS then
         PlayGaugeSFX(gaugeFullSFX)
    end

    previousComboPoints = points
end


 

 
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_FACTION")
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("UNIT_MAXPOWER")           
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")

frame:SetScript("OnEvent", function(self, event, unit, powerType)
    if event == "UNIT_FACTION" and unit ~= "target" then return end
    if event == "UNIT_POWER_UPDATE" then
        if unit == "player" and powerType == "COMBO_POINTS" then
            UpdateComboPoints()
        end
        return
    end

    ConfigureComboPoints()
    UpdateComboPoints()
end)

end)

