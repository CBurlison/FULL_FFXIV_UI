local addonName, addonEnv = ...

local ICON_SIZE, AURA_LIMIT = 22, 8
local FONT_ROOT = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\"
local formatter = C_StringUtil.CreateNumericRuleFormatter()
formatter:AddBreakpoint({threshold = 0, format = "%d", step = 1, rounding = 1})
formatter:AddBreakpoint({
    threshold = 60,
    format = "%dm",
    components = {{div = 60, step = 1, rounding = 1}},
})
formatter:AddBreakpoint({
    threshold = 3600,
    format = "%dh",
    components = {{div = 3600, step = 1, rounding = 1}},
})

local containers = {}
local function CreateAuraRow(parent, getUnit, groupName, filter, styleName, x, y, iconSize, limit, container)
    if not container then
        container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
        container:SetSize(1, 1)
        container:SetPoint("TOPLEFT", parent, "TOPRIGHT", x, y)
        container:SetFlowLayoutAnchorPoint("TOPLEFT")
        container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
        container:SetUnit(getUnit())
    end

    local function InitializeSlot(slot)
        slot:SetSize(iconSize, iconSize)
        local icon = slot:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints()
        slot:SetIcon(icon)

        local overlay = CreateFrame("Frame", nil, slot)
        overlay:SetAllPoints()
        overlay:SetFrameLevel(slot:GetFrameLevel() + 5)
        overlay:EnableMouse(true)
        overlay:SetMouseClickEnabled(false)

        local count = overlay:CreateFontString(nil, "OVERLAY")
        count:SetFont(FONT_ROOT .. "MavenPro-Bold.ttf", 10, "OUTLINE")
        count:SetPoint("BOTTOMRIGHT", -1, 1)
        slot:SetApplicationCount(count)

        local duration = overlay:CreateFontString(nil, "OVERLAY")
        duration:SetFont(FONT_ROOT .. "AxisMedium.ttf", 10, "OUTLINE")
        duration:SetPoint("TOP", slot, "BOTTOM", 0, -1)
        slot:SetDurationText(duration, {
            textFormat = {
                formatString = "{}",
                components = {{property = 0, formatter = formatter}},
            },
        })

        addonEnv.ApplyButtonSkin(slot, {
            Icon = icon,
            Cooldown = slot.cooldown,
            Count = count,
            Duration = duration,
        }, styleName, iconSize)

        overlay:SetScript("OnEnter", function(self)
            local auraInstanceID = slot:GetAuraInstanceID()
            if not (issecretvalue and issecretvalue(auraInstanceID)) and auraInstanceID then
                if addonEnv.Tooltips and addonEnv.Tooltips.ShowAuraTooltip then
                    addonEnv.Tooltips.ShowAuraTooltip(self, getUnit(), auraInstanceID)
                end
            end
        end)
        overlay:SetScript("OnLeave", function()
            if addonEnv.Tooltips and addonEnv.Tooltips.HideAuraTooltip then
                addonEnv.Tooltips.HideAuraTooltip()
            end
        end)
    end

    container:AddAuraGroup(groupName, filter, {
        maxFrameCount = limit,
        initializeFrame = InitializeSlot,
    })
    container:SetAuraGroupLayout(groupName, {elementSpacingX = 3, elementSpacing = 3, groupSpacing = 3, forceNewLine = false})
    container:SetEnabled(true)
    return container
end

addonEnv.CreateUnitAuraRow = CreateAuraRow
local function GetPetUnit() return "pet" end
containers[1] = CreateAuraRow(PetFrame_HP, GetPetUnit, "buffs", AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Helpful), "Buffs", 6, 0, ICON_SIZE, AURA_LIMIT)
containers[2] = CreateAuraRow(PetFrame_HP, GetPetUnit, "debuffs", AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful), "Debuffs", 6, -36, ICON_SIZE, AURA_LIMIT)

local function Refresh()
    for _, container in ipairs(containers) do container:UpdateAllAuras() end
end

local handlers = {
    PLAYER_ENTERING_WORLD = Refresh,
    UNIT_PET = function(_, unit)
        if unit == "player" then Refresh() end
    end,
}
PetFrame_HP:HookScript("OnShow", Refresh)
local watcher = CreateFrame("Frame")
for event in pairs(handlers) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(self, event, ...)
    handlers[event](self, ...)
end)
