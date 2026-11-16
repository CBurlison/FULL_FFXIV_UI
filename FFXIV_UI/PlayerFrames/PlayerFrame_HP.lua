--print("FFXIV UI Player HP loaded")

 
PlayerFrame:Hide()
hooksecurefunc(PlayerFrame, "Show", function(self)
    self:Hide()
end)

local f = Playerframe_HP

local bar = f.bar
bar:SetFrameLevel(f:GetFrameLevel() + 2)

 
local cutawayBar = f.cutawayBar
cutawayBar:SetFrameLevel(f:GetFrameLevel() + 1)   

 

 
local outlineFrame = f.outlineFrame
outlineFrame:SetFrameLevel(f:GetFrameLevel() + 5)

 
local outline = outlineFrame.outline

 
local text = outlineFrame.text

 
local hpLabel = outlineFrame.hpLabel
        
 
local clickFrame = outlineFrame.clickFrame
clickFrame:SetFrameLevel(outlineFrame:GetFrameLevel() + 10)
clickFrame:EnableMouse(true)
clickFrame:RegisterForClicks("AnyUp")
clickFrame:SetAttribute("unit", "player")
clickFrame:SetAttribute("type1", "target")
clickFrame:SetAttribute("type2", "togglemenu")

 
local combatTexture = f.combatTexture
combatTexture:Hide()   

local outOfCombatTexture = f.outOfCombatTexture
outOfCombatTexture:Show()   

 
local anchor = FFXIV_UI_Anchors.PlayerHP
f:SetParent(anchor)
f:ClearAllPoints()
f:SetPoint("CENTER", anchor, "CENTER", 0, 0)



 
local function UpdateCombatTextures(inCombat)
    if inCombat then
        combatTexture:Show()
        outOfCombatTexture:Hide()
    else
        combatTexture:Hide()
        outOfCombatTexture:Show()
    end
end

 
local function Update()
    local hp = UnitHealth("player")
    local maxHp = UnitHealthMax("player")
 
    bar:SetMinMaxValues(0, maxHp)
    bar:SetValue(hp)
    text:SetText(hp)


    cutawayBar:SetMinMaxValues(0, maxHp)
    cutawayBar:SetValue(hp, Enum.StatusBarInterpolation.ExponentialEaseOut)

end

 
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_HEALTH")
f:RegisterEvent("UNIT_MAXHEALTH")
f:RegisterEvent("PLAYER_REGEN_DISABLED")  
f:RegisterEvent("PLAYER_REGEN_ENABLED")   
f:RegisterEvent("PLAYER_LOGIN")

 
f:SetScript("OnEvent", function(_, event, unit)

    if event == "PLAYER_LOGIN" then
        Update()
        UpdateCombatTextures(InCombatLockdown())
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        UpdateCombatTextures(true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        UpdateCombatTextures(false)
    end

    if unit == "player" then
        Update()
    end
end)

 
 
