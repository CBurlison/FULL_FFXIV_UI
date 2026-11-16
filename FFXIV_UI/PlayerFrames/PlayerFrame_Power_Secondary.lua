--print("FFXIV UI Player Power Secondary (MP / Brewmaster Stagger) loaded")


local f = PlayerFrame_Power_Secondary

f:SetFrameStrata("MEDIUM")

local bar = f.bar

local tex = bar:GetStatusBarTexture()
tex:SetDrawLayer("ARTWORK", 0)
tex:SetTexCoord(0.5, 1, 0, 1)

local outlineFrame = f.outlineFrame
outlineFrame:SetFrameLevel(f:GetFrameLevel() + 5)

local text = outlineFrame.text


local powerLabel = outlineFrame.powerLabel


local anchor = FFXIV_UI_Anchors.PlayerPowerSec
f:SetParent(anchor)
f:ClearAllPoints()
f:SetPoint("CENTER", anchor, "CENTER", 0, 0)


local textures = {
    default = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\Mana",
    mana = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\Mana",
    stagger = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\Stagger",
}

local getSpecialization = GetSpecialization or (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization)
local isForever = select(4, GetBuildInfo()) == 16001

local function Update()
    local _, class = UnitClass("player")
    local spec = getSpecialization and getSpecialization()


    f:Hide()


    local druidUsesSecondaryMana = false
    if class == "DRUID" then
        local formID = GetShapeshiftFormID()
        druidUsesSecondaryMana = formID == 1 or formID == 5 or formID == 8
    end

    if class == "MONK" and spec == 1 then
        local stagger = UnitStagger("player") or 0
        local maxHealth = UnitHealthMax("player")

        bar:SetStatusBarTexture(textures.stagger)
        bar:SetMinMaxValues(0, maxHealth)
        bar:SetValue(stagger)

        text:SetText(stagger)
        powerLabel:SetText("SP")

        f:Show()


    elseif (not isForever and class == "SHAMAN" and spec == 1)
        or druidUsesSecondaryMana
        or (not isForever and class == "PRIEST" and spec == 3) then

        local mana = UnitPower("player", Enum.PowerType.Mana)
        local maxMana = UnitPowerMax("player", Enum.PowerType.Mana)

        bar:SetStatusBarTexture(textures.mana)
        bar:SetMinMaxValues(0, maxMana)
        bar:SetValue(mana)

        text:SetText(mana)
        powerLabel:SetText("MP")

        f:Show()
    end

    local tex = bar:GetStatusBarTexture()
    tex:SetDrawLayer("ARTWORK", 0)
    tex:SetTexCoord(0.5, 1, 0, 1)
end



f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("UNIT_POWER_UPDATE")
f:RegisterEvent("UNIT_MAXPOWER")
f:RegisterEvent("UNIT_DISPLAYPOWER")
f:RegisterEvent("UNIT_HEALTH")
f:RegisterEvent("UNIT_MAXHEALTH")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

f:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" or not unit or unit == "player" then
        Update()
    end
end)

 