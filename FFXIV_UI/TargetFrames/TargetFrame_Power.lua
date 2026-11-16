local addonName, addonEnv = ...

local function BindResourceBar(unitToken, frame, anchor, point, relativePoint, y)
    frame:SetParent(anchor)
    frame:SetPoint(point, anchor, relativePoint, 0, y)

    local background = frame.background
    local bar = frame.bar
    local textFrame = frame.textFrame
    textFrame:SetFrameLevel(bar:GetFrameLevel() + 5)
    local outline = textFrame.outline
    local label = textFrame.label
    local valueText = textFrame.valueText

    local labels = {
        MANA = "MP",
        RAGE = "RP",
        ENERGY = "EP",
        FOCUS = "FP",
        RUNIC_POWER = "RP",
        LUNAR_POWER = "AP",
        INSANITY = "IP",
        FURY = "FP",
        MAELSTROM = "MS",
    }

    local function Update()
        local exists = UnitExists(unitToken)
        if not (issecretvalue and issecretvalue(exists)) and not exists then
            frame:Hide()
            return
        end

        local powerType, powerToken, alternateR, alternateG, alternateB = UnitPowerType(unitToken)
        local maxPower = UnitPowerMax(unitToken, powerType)
        if not (issecretvalue and issecretvalue(maxPower)) and maxPower <= 0 then
            frame:Hide()
            return
        end

        bar:SetMinMaxValues(0, maxPower)
        local power = UnitPower(unitToken, powerType)
        bar:SetValue(power)
        valueText:SetText(power)
        label:SetText(labels[powerToken] or powerToken)

        local color = PowerBarColor[powerToken] or PowerBarColor[powerType]
        local r, g, b
        if color then
            r, g, b = color.r, color.g, color.b
        elseif alternateR and alternateG and alternateB then
            r, g, b = alternateR, alternateG, alternateB
        else
            r, g, b = 1, 1, 1
        end
        bar:SetStatusBarColor(r, g, b)
        background:SetVertexColor(r * 0.6, g * 0.6, b * 0.6)
        outline:SetVertexColor(r, g, b)

        frame:Show()
    end

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("UNIT_TARGET")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_ENTERING_WORLD"
            or event == "PLAYER_TARGET_CHANGED"
            or event == "PLAYER_FOCUS_CHANGED"
            or (event == "UNIT_TARGET" and unitToken == "targettarget" and unit == "target")
            or unit == unitToken then
            Update()
        end
    end)
end

BindResourceBar("target", FFTargetPowerFrame, FFXIV_UI_Anchors.TargetPower, "CENTER", "CENTER", 0)
BindResourceBar("focus", FFFocusPowerFrame, FFXIV_UI_Anchors.FocusTarget, "TOP", "BOTTOM", -2)
BindResourceBar("targettarget", FFTargetOfTargetPowerFrame, FFXIV_UI_Anchors.TargetOfTarget, "TOP", "BOTTOM", -2)
