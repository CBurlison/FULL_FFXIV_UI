local addonID, addonEnv = ...

local SCALE = 100
local function s(x)
    return x * SCALE / 100
end

local AURA_ICON_SIZE, AURA_GAP, AURA_LIMIT = s(34), s(0), 20

local formatter = C_StringUtil.CreateNumericRuleFormatter()
formatter:AddBreakpoint({
	threshold = 0,
	format = "%d",
	step = 1,
	rounding = 1,
})
formatter:AddBreakpoint({
	threshold = 60,
	format = "%dm",
	components = { { div = 60, step = 1, rounding = 1 } },
})
formatter:AddBreakpoint({
	threshold = 3600,
	format = "%dh",
	components = { { div = 3600, step = 1, rounding = 1 } },
})

local rootFrame = CreateFrame("AuraContainer", addonID .. "_Debuffs", UIParent, "CustomAuraContainerTemplate")
rootFrame:SetSize(1, 1)
rootFrame.bg = rootFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
rootFrame.bg:SetAllPoints()

rootFrame:SetFlowLayoutAnchorPoint("LEFT")
rootFrame:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
rootFrame:SetUnit("target")

local playerHarmfulFilter = "HARMFUL|PLAYER"
local otherHarmfulFilter = "HARMFUL|!PLAYER"
local PLAYER_DEBUFF_COLOR = { 0.6, 1, 0.6, 1 }

local function InitializeAuraSlot(slot)
    slot:SetSize(AURA_ICON_SIZE, AURA_ICON_SIZE)

    slot.texture = slot:CreateTexture(nil, "BACKGROUND")
    slot.texture:SetAllPoints()
    slot.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    slot:SetIcon(slot.texture)

    local overlay = CreateFrame("Frame", nil, slot)
    overlay:SetAllPoints(slot)
    overlay:SetFrameLevel(slot:GetFrameLevel() + 5)
    overlay:EnableMouse(true)
    overlay:SetMouseClickEnabled(false)

    slot.stackText = overlay:CreateFontString(nil, "OVERLAY")
    slot.stackText:SetFont(STANDARD_TEXT_FONT, s(12), "OUTLINE")
    slot.stackText:SetPoint("BOTTOMRIGHT", s(-2), s(2))
    slot:SetApplicationCount(slot.stackText)

    slot.cooldownText = overlay:CreateFontString(nil, "OVERLAY")
    slot.cooldownText:SetFont("Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisMedium.ttf", s(14))
    slot.cooldownText:SetPoint("CENTER", overlay, "CENTER", 0, s(-20))

    slot:SetDurationText(slot.cooldownText, {
		textFormat = {
			formatString = "{}",
			components = {
				{
					property = 0,
					formatter = formatter
				}
			}
		}
	})

    overlay:SetScript("OnEnter", function(self)
        local parentSlot = self:GetParent()
        local auraInstanceID = parentSlot and parentSlot:GetAuraInstanceID()
        if auraInstanceID and addonEnv.Tooltips and addonEnv.Tooltips.ShowAuraTooltip then
            addonEnv.Tooltips.ShowAuraTooltip(self, "target", auraInstanceID)
        end
    end)
    overlay:SetScript("OnLeave", function()
        if addonEnv.Tooltips and addonEnv.Tooltips.HideAuraTooltip then
            addonEnv.Tooltips.HideAuraTooltip()
        end
    end)

    addonEnv.ApplyButtonSkin(slot, {
        Icon = slot.texture,
        Cooldown = slot.cooldown,
        Count = slot.stackText,
        Duration = slot.cooldownText
    }, "Debuffs")
end

local function InitializePlayerAuraSlot(slot)
    InitializeAuraSlot(slot)
    slot.cooldownText:SetTextColor(unpack(PLAYER_DEBUFF_COLOR))
    slot.stackText:SetTextColor(unpack(PLAYER_DEBUFF_COLOR))
end

-- Groups are laid out in the order they are added, so the player's debuffs come first.
rootFrame:AddAuraGroup("playerDebuffs", playerHarmfulFilter, {
    maxFrameCount = AURA_LIMIT,
    initializeFrame = InitializePlayerAuraSlot
})
rootFrame:SetAuraGroupLayout("playerDebuffs", { elementSpacingX = AURA_GAP })

rootFrame:AddAuraGroup("debuffs", otherHarmfulFilter, {
    maxFrameCount = AURA_LIMIT,
    initializeFrame = InitializeAuraSlot
})
rootFrame:SetAuraGroupLayout("debuffs", { elementSpacingX = AURA_GAP })
rootFrame:SetEnabled(true)

local eventWatcher = CreateFrame("Frame")
eventWatcher:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_TARGET_CHANGED" then
        if not UnitExists("target") then
            rootFrame:SetEnabled(false)
            rootFrame:Hide()
        else
            rootFrame:SetEnabled(true)
            rootFrame:Show()
            rootFrame:UpdateAllAuras()
        end
    end
end)
eventWatcher:RegisterEvent("PLAYER_TARGET_CHANGED")

local function AnchorToFFTargetFrame()
    assert(FFTargetFrame, "FFTargetFrame not found")
    rootFrame:ClearAllPoints()
    rootFrame:SetPoint("TOPLEFT", FFTargetFrame, "BOTTOMLEFT", s(5), s(250))
end

AnchorToFFTargetFrame()

local anchor = FFXIV_UI_Anchors.TargetDebuffs
rootFrame:SetParent(anchor)
rootFrame:ClearAllPoints()
rootFrame:SetPoint("LEFT", anchor, "LEFT", 0, 0)
