
--print("FFXIV UI Target Frame loaded")

TargetFrame:Hide()
TargetFrame:UnregisterAllEvents()
TargetFrame.Show = function() end  


local SCALE = 103
local function s(x) return x * SCALE / 100 end  
local isForever = select(4, GetBuildInfo()) == 16001


FFTargetFrame:EnableMouse(false)
local f = FFTargetFrame

local COLORS = {
    hostile  = {200/255, 50/255, 8/255},       
    friendly = {228/255,255/255,204/255},      
    neutral  = {1.0, 0.87, 0.0},               
    player   = {0.6, 0.8, 1.0},                
    dead     = {0.35, 0.35, 0.35},             
}


local bg = f.bg
bg:SetVertexColor(unpack(COLORS.neutral))

local bar = f.bar
bar:EnableMouse(false)

local outlineFrame = f.outlineFrame
outlineFrame:SetFrameLevel(f:GetFrameLevel() + 5)
outlineFrame:EnableMouse(false)

local outline = outlineFrame.outline
outline:SetVertexColor(unpack(COLORS.neutral))

local classificationIcon = outlineFrame.classificationIcon
local LLabel = outlineFrame.LLabel
local vLabel = outlineFrame.vLabel
local levelText = outlineFrame.levelText
local nameText = outlineFrame.nameText
local hpPercentText = outlineFrame.hpPercentText

local raidIcon = outlineFrame.raidIcon
raidIcon:SetPoint("RIGHT", bar, "LEFT", s(-8), 0)

local clickFrame = outlineFrame.clickFrame
clickFrame:SetFrameLevel(f:GetFrameLevel() - 1)
clickFrame:SetAttribute("unit", "target")
clickFrame:SetAttribute("type1", "target")
clickFrame:SetAttribute("type2", "togglemenu")
clickFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
clickFrame:EnableMouse(true)

local anchor = FFXIV_UI_Anchors.TargetHP
f:SetParent(anchor)
f:ClearAllPoints()
f:SetPoint("CENTER", anchor, "CENTER", 0, -15)

local function ShowFrame() f:SetAlpha(1) end
local function HideFrame() f:SetAlpha(0) end

local function DarkenColor(r, g, b, factor)
    factor = factor or 0.6
    return r * factor, g * factor, b * factor
end

local function SetBarAndTextColor(r, g, b)
    bar:SetStatusBarColor(r, g, b, 1)
    local sr, sg, sb = DarkenColor(r, g, b, 0.6)
    LLabel:SetTextColor(r, g, b); LLabel:SetShadowColor(sr, sg, sb)
    vLabel:SetTextColor(r, g, b); vLabel:SetShadowColor(sr, sg, sb)
    levelText:SetTextColor(r, g, b); levelText:SetShadowColor(sr, sg, sb)
    nameText:SetTextColor(r, g, b); nameText:SetShadowColor(sr, sg, sb)
    hpPercentText:SetTextColor(r, g, b); hpPercentText:SetShadowColor(sr, sg, sb)
end

local function UpdateColors()
    if not UnitExists("target") then return end

    if UnitIsUnit("target", "player") or (UnitIsPlayer("target") and (UnitInParty("target") or UnitInRaid("target"))) then
        bg:SetVertexColor(unpack(COLORS.player))
        outline:SetVertexColor(unpack(COLORS.player))
        bar:SetStatusBarColor(1,1,1)
        local r,g,b = unpack(COLORS.player)
        local sr,sg,sb = DarkenColor(r,g,b,0.6)
        LLabel:SetTextColor(r,g,b); LLabel:SetShadowColor(sr,sg,sb)
        vLabel:SetTextColor(r,g,b); vLabel:SetShadowColor(sr,sg,sb)
        levelText:SetTextColor(r,g,b); levelText:SetShadowColor(sr,sg,sb)
        nameText:SetTextColor(r,g,b); nameText:SetShadowColor(sr,sg,sb)
        hpPercentText:SetTextColor(r,g,b); hpPercentText:SetShadowColor(sr,sg,sb)
        return
    end

    local inCombatWithTarget = UnitAffectingCombat("player") and UnitCanAttack("player", "target")

    if UnitIsDeadOrGhost("target") then
        bg:SetVertexColor(unpack(COLORS.dead))
        outline:SetVertexColor(unpack(COLORS.dead))
        SetBarAndTextColor(0.4,0.4,0.4)
        return
    end

    if inCombatWithTarget then
        bg:SetVertexColor(unpack(COLORS.hostile))
        outline:SetVertexColor(unpack(COLORS.hostile))
        SetBarAndTextColor(1.0,0.8,0.8)
        return
    end

    if UnitIsPlayer("target") then
        bg:SetVertexColor(unpack(COLORS.player))
        outline:SetVertexColor(unpack(COLORS.player))
        SetBarAndTextColor(unpack(COLORS.player))
        return
    end

    local reaction = UnitReaction("target","player")
    if reaction then
        if reaction <= 3 then
            bg:SetVertexColor(unpack(COLORS.hostile))
            outline:SetVertexColor(unpack(COLORS.hostile))
            SetBarAndTextColor(1.0,0.8,0.8)
        elseif reaction == 4 then
            bg:SetVertexColor(unpack(COLORS.neutral))
            outline:SetVertexColor(unpack(COLORS.neutral))
            SetBarAndTextColor(235/255,222/255,129/255)
        else
            --bg:SetVertexColor(unpack(COLORS.friendly))
            --outline:SetVertexColor(unpack(COLORS.friendly))
            --SetBarAndTextColor(0.4,1.0,0.4)


             bg:SetVertexColor(113/255, 214/255, 64/255)
             outline:SetVertexColor(113/255, 214/255, 64/255)
             bar:SetStatusBarColor(228/255,255/255,204/255)

             local r,g,b = unpack(COLORS.friendly)
             local sr,sg,sb = DarkenColor(r,g,b,0.6)
             LLabel:SetTextColor(r,g,b); LLabel:SetShadowColor(113/255, 214/255, 64/255)
             vLabel:SetTextColor(r,g,b); vLabel:SetShadowColor(113/255, 214/255, 64/255)
             levelText:SetTextColor(r,g,b); levelText:SetShadowColor(113/255, 214/255, 64/255)
             nameText:SetTextColor(r,g,b); nameText:SetShadowColor(113/255, 214/255, 64/255)
             hpPercentText:SetTextColor(r,g,b); hpPercentText:SetShadowColor(113/255, 214/255, 64/255)



        end


        local classification = UnitClassification("target")

  


    else
        bg:SetVertexColor(unpack(COLORS.neutral))
        outline:SetVertexColor(unpack(COLORS.neutral))
        SetBarAndTextColor(235/255,222/255,129/255)
    end

    
 
end
local function UpdateClassificationIcon()
    if not UnitExists("target") then
        classificationIcon:Hide()
        return
    end

    local classification = UnitClassification("target")
    if classification == "worldboss" or classification == "boss" then
        classificationIcon:SetTexture("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Boss-Icon")
        classificationIcon:Show()
    elseif classification == "rareelite" then
        classificationIcon:SetTexture("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Rare-Boss-Icon")
        classificationIcon:Show()
    elseif classification == "elite" or classification == "player" then
        classificationIcon:SetTexture("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Elite-Icon")
        classificationIcon:Show()
    elseif classification == "rare" then
        classificationIcon:SetTexture("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Rare-Icon")
        classificationIcon:Show()
    else
        classificationIcon:SetTexture("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Normal-Icon")
        classificationIcon:Show()
    end
end

local function Update()
    if UnitExists("target") then
        ShowFrame()

        local hp = UnitHealth("target")
        local maxHp = UnitHealthMax("target")
        local name
        if isForever then
            name = GetUnitName("target", false)
        else
            name = UnitName("target")
        end
        local level = UnitLevel("target")

        bar:SetMinMaxValues(0, maxHp)
        bar:SetValue(hp, Enum.StatusBarInterpolation.ExponentialEaseOut)

        nameText:SetText(name)
        levelText:SetText(level == -1 and "??" or level)

        UpdateColors()
        UpdateClassificationIcon()

        local statusTextEnabled = GetCVar("statusText") == "1"
        local displayMode = GetCVar("statusTextDisplay")
        local showHealthText = statusTextEnabled and
            (displayMode == "NUMERIC" or displayMode == "PERCENT" or displayMode == "BOTH")

        if showHealthText then
            if displayMode == "NUMERIC" then
                hpPercentText:SetFormattedText("%s / %s", hp, maxHp)
            else
                local percent
                if UnitHealthPercent then
                    percent = UnitHealthPercent("target", true, CurveConstants.ScaleTo100)
                else
                    percent = maxHp > 0 and hp / maxHp * 100 or 0
                end
                if displayMode == "BOTH" then
                    hpPercentText:SetFormattedText("%s / %s (%.0f%%)", hp, maxHp, percent)
                else
                    hpPercentText:SetFormattedText("%.0f%%", percent)
                end
            end
            hpPercentText:Show()
            nameText:ClearAllPoints()
            nameText:SetPoint("LEFT", levelText, "RIGHT", s(5), s(2))
            nameText:SetPoint("RIGHT", hpPercentText, "LEFT", -s(8), 0)
        else
            hpPercentText:Hide()
            nameText:ClearAllPoints()
            nameText:SetPoint("LEFT", levelText, "RIGHT", s(5), s(2))
        end
        LLabel:Show()
        vLabel:Show()
        levelText:Show()

  
        local raidIndex = GetRaidTargetIndex("target")
        if raidIndex then
            SetRaidTargetIconTexture(raidIcon, raidIndex)
            raidIcon:Show()
        else
            raidIcon:Hide()
        end

         

    else
        HideFrame()
    end
end

local function targetChanged()
   local hp = UnitHealth("target")
     bar:SetValue(hp)

end



f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("UNIT_HEALTH")
f:RegisterEvent("UNIT_MAXHEALTH")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("RAID_TARGET_UPDATE")
f:RegisterEvent("CVAR_UPDATE")

f:SetScript("OnEvent", function(_, event, unit)
    if event == "CVAR_UPDATE" then
        local cvar = unit and string.lower(unit)
        if cvar == "statustext" or cvar == "statustextdisplay" then
            Update()
        end
        return
    end

    if event == "PLAYER_TARGET_CHANGED"
    or event == "PLAYER_ENTERING_WORLD"
    or event == "PLAYER_REGEN_DISABLED"
    or event == "PLAYER_REGEN_ENABLED"
    or event == "RAID_TARGET_UPDATE"
    or unit == "target" then
        Update()
    end

    if event == "PLAYER_TARGET_CHANGED" then
targetChanged()

    end

 
end)

HideFrame()
