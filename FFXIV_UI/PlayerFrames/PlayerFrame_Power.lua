--print("FFXIV UI Player Power loaded")


  


local f = PlayerFrame_Power

f:SetFrameStrata("MEDIUM")



local bg = f.bg


local bar = f.bar

local tex = bar:GetStatusBarTexture()
tex:SetDrawLayer("ARTWORK", 0)
tex:SetTexCoord(0.5, 1, 0, 1)

local outlineFrame = f.outlineFrame
outlineFrame:SetFrameLevel(f:GetFrameLevel() + 5)

local outline = outlineFrame.outline

local text = outlineFrame.text


local powerLabel = outlineFrame.powerLabel


local defaultTexture = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\Mana"
local furyTexture   = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\Fury"  
local rageTexture   = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\Rage"
local astralPowerTexture   = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\AstralPower"
local energyTexture   = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\Energy"
local insanityTexture   = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\Insanity"
local manaTexture   = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\Mana"
local runicPowerTexture   = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\RunicPower"
local focusTexture   = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\Focus"
local maelstromTexture   = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\Maelstrom"

local anchor = FFXIV_UI_Anchors.PlayerPower
f:SetParent(anchor)
f:ClearAllPoints()
f:SetPoint("CENTER", anchor, "CENTER", 0, 0)

local function Update()
    local powerType, powerToken = UnitPowerType("player") 
    local power = UnitPower("player", powerType)
    local maxPower = UnitPowerMax("player", powerType)

    bar:SetMinMaxValues(0, maxPower)
    bar:SetValue(power)

    if powerToken == "FURY" then
        bar:SetStatusBarTexture(furyTexture)
        powerLabel:SetText("FP")

    elseif powerToken == "MANA" then
        bar:SetStatusBarTexture(manaTexture)
        powerLabel:SetText("MP")

    elseif powerToken == "RAGE" then
        bar:SetStatusBarTexture(rageTexture)
        powerLabel:SetText("RP")

    elseif powerToken == "ENERGY" then
        bar:SetStatusBarTexture(energyTexture)
        powerLabel:SetText("EP")

    elseif powerToken == "INSANITY" then
        bar:SetStatusBarTexture(insanityTexture)
        powerLabel:SetText("IP")

    elseif powerToken == "LUNAR_POWER" then
        bar:SetStatusBarTexture(astralPowerTexture)
        powerLabel:SetText("AP")
    
    elseif powerToken == "RUNIC_POWER" then
        bar:SetStatusBarTexture(runicPowerTexture)
        powerLabel:SetText("RP")

    elseif powerToken == "FOCUS" then
        bar:SetStatusBarTexture(focusTexture)
        powerLabel:SetText("FP")

   elseif powerToken == "MAELSTROM" then
        bar:SetStatusBarTexture(maelstromTexture)
        powerLabel:SetText("MS")

    else
        bar:SetStatusBarTexture(defaultTexture)
        powerLabel:SetText(powerToken)
    end

    local tex = bar:GetStatusBarTexture()
    tex:SetDrawLayer("ARTWORK", 0)
    tex:SetTexCoord(0.5, 1, 0, 1)

    text:SetText(power)
end

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("UNIT_POWER_UPDATE")
f:RegisterEvent("UNIT_MAXPOWER")
f:RegisterEvent("UNIT_DISPLAYPOWER")

f:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" or not unit or unit == "player" then
        Update()
    end
end)

 
