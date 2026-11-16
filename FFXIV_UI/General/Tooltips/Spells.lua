local addonName, ns = ...
local addonEnv = ns
local Tooltips = ns.Tooltips
local L = Tooltips.L

function Tooltips.InitializeSpells(tooltipSkin, layout)
    local tooltip = tooltipSkin.tooltip
    local RestoreItemHeader = layout.RestoreItemHeader
    local GuardEquipmentAlpha = layout.GuardEquipmentAlpha
    local TraitUnderline = layout.TraitUnderline
    local ApplyContentLayout = layout.ApplyContentLayout

    local function StyleSpellTooltip()
        if Tooltips.IsAuraTooltip(tooltip) then
            if tooltipSkin.updateAuraTooltip then tooltipSkin.updateAuraTooltip() end
            return
        end
        RestoreItemHeader()
        tooltipSkin.spellLayoutActive = true
        if type(tooltip.GetSpell) ~= "function" then return end
        local tooltipSpellName, spellID = tooltip:GetSpell()
        local data = type(tooltip.GetTooltipData) == "function" and tooltip:GetTooltipData()
        if issecretvalue and issecretvalue(spellID) then spellID = nil end
        if type(spellID) ~= "number" and data and type(data.id) == "number"
            and not (issecretvalue and issecretvalue(data.id)) then spellID = data.id end
        local hasSpellID = type(spellID) == "number"
        local lineTypes = Enum and Enum.TooltipDataLineType
        local spellInfo = hasSpellID and C_Spell and type(C_Spell.GetSpellInfo) == "function"
            and C_Spell.GetSpellInfo(spellID) or nil
        if issecretvalue and issecretvalue(spellInfo) then spellInfo = nil end
        if type(spellInfo) ~= "table" then
            spellInfo = {}
            tooltipSkin.pendingSpellID = hasSpellID and spellID or nil
            if hasSpellID and C_Spell and type(C_Spell.RequestLoadSpellData) == "function" then
                C_Spell.RequestLoadSpellData(spellID)
            end
        else
            tooltipSkin.pendingSpellID = nil
        end
        local nativeTitle = tooltip.TextLeft1
        if not nativeTitle then return end
        local spellCategory, spellCategoryRegion, spellLineName
        if data and data.lines and lineTypes then
            for index, line in ipairs(data.lines) do
                local lineType = line.type
                if not (issecretvalue and issecretvalue(lineType))
                    and lineTypes.SpellName and lineType == lineTypes.SpellName then
                    local lineIndex = line.lineIndex or index
                    local right = _G[(tooltip:GetName() or "") .. "TextRight" .. lineIndex]
                    spellCategoryRegion = right
                    local leftText = line.leftText
                    if issecretvalue and issecretvalue(leftText) then leftText = nil end
                    if type(leftText) ~= "string" and nativeTitle then leftText = nativeTitle:GetText() end
                    if issecretvalue and issecretvalue(leftText) then leftText = nil end
                    if type(leftText) == "string" and leftText ~= "" then spellLineName = leftText end
                    local rightText = line.rightText
                    if issecretvalue and issecretvalue(rightText) then rightText = nil end
                    if type(rightText) ~= "string" and right then rightText = right:GetText() end
                    if issecretvalue and issecretvalue(rightText) then rightText = nil end
                    local categoryLabels = {SPELL, ABILITY, "Spell", "Ability"}
                    local isCategory = false
                    for _, category in ipairs(categoryLabels) do
                        if type(category) == "string" and rightText == category then
                            isCategory = true
                            break
                        end
                    end
                    if type(rightText) == "string" and rightText ~= "" and isCategory then
                        spellCategory = rightText
                    end
                    break
                end
            end
        end
        local spellName = spellInfo.name or tooltipSpellName or spellLineName
        if issecretvalue and issecretvalue(spellName) then spellName = nil end
        if type(spellName) ~= "string" or spellName == "" then
            spellName = nativeTitle:GetText()
            if issecretvalue and issecretvalue(spellName) then spellName = nil end
        end
        if type(spellName) ~= "string" then spellName = "" end
        local castTime = spellInfo.castTime
        if issecretvalue and issecretvalue(castTime) then castTime = nil end
        local maxRange, spellRadius = spellInfo.maxRange, spellInfo.radius
        if issecretvalue and (issecretvalue(maxRange) or issecretvalue(spellRadius)) then
            maxRange, spellRadius = nil, nil
        end

        local iconID = spellInfo.iconID
        if issecretvalue and issecretvalue(iconID) then iconID = nil end
        if hasSpellID and not iconID and C_Spell and type(C_Spell.GetSpellTexture) == "function" then
            iconID = C_Spell.GetSpellTexture(spellID)
            if issecretvalue and issecretvalue(iconID) then iconID = nil end
        end
        tooltipSkin.itemIcon = tooltipSkin.itemIcon or tooltip:CreateTexture(nil, "ARTWORK", "FFXIV_TooltipIconTemplate")
        if iconID then tooltipSkin.itemIcon:SetTexture(iconID) end
        if iconID then tooltipSkin.itemIcon:Show() else tooltipSkin.itemIcon:Hide() end
        tooltipSkin.consumableText = {}
        tooltipSkin.itemTitle = nil
        Tooltips.SaveNativeRegion(tooltipSkin.consumableText, nativeTitle, tooltipSkin.nativeSpellTitleAlpha or 1)
        GuardEquipmentAlpha(nativeTitle)
        nativeTitle:SetAlpha(0)
        if spellCategoryRegion then
            Tooltips.SaveNativeRegion(tooltipSkin.consumableText, spellCategoryRegion)
            GuardEquipmentAlpha(spellCategoryRegion)
            spellCategoryRegion:SetAlpha(0)
        end
        tooltipSkin.consumableRows = {}
        local function TraitText(key, text, fontSize, colorToken, x, y, width, justify)
            local region = tooltipSkin[key]
            if not region then
                region = tooltip:CreateFontString(nil, "OVERLAY")
                tooltipSkin[key] = region
            end
            Tooltips.StyleFont(region, fontSize, colorToken)
            region:SetText(text)
            region:ClearAllPoints()
            region:SetPoint("TOPLEFT", tooltip, "TOPLEFT", x, y)
            region:SetWidth(width)
            region:SetJustifyH(justify or "RIGHT")
            region:SetWordWrap(false)
            region:Show()
            tooltipSkin.consumableRows[region] = true
            return region
        end
        local spellTitle = TraitText("spellTitle", spellName or "", 14, "text",
            56, -10, math.max(1, tooltip:GetWidth() - 72), "LEFT")
        spellTitle:SetHeight(18)
        spellTitle:SetJustifyV("MIDDLE")
        tooltipSkin.contentLayout = {{region = spellTitle, x = 56, y = -10, spellTitle = true}}
        local spellLabel = spellCategory
        if not spellLabel then
            spellLabel = L["Spell"]
            if hasSpellID and type(GetSpellBaseCooldown) == "function" then
                local _, gcdMS = GetSpellBaseCooldown(spellID)
                if type(gcdMS) == "number" and not (issecretvalue and issecretvalue(gcdMS)) then
                    spellLabel = gcdMS > 0 and L["Spell"] or L["Ability"]
                end
            end
        end
        local isPassive = hasSpellID and C_Spell and type(C_Spell.IsSpellPassive) == "function"
            and C_Spell.IsSpellPassive(spellID)
        if issecretvalue and issecretvalue(isPassive) then isPassive = nil end
        if not isPassive and data and data.lines and lineTypes and lineTypes.SpellPassive then
            for _, line in ipairs(data.lines) do
                local lineType = line.type
                if not (issecretvalue and issecretvalue(lineType)) and lineType == lineTypes.SpellPassive then
                    isPassive = true
                    break
                end
            end
        end
        if isPassive then spellLabel = L["Passive"] end
        local rangeParts = {}
        if type(maxRange) == "number" and maxRange > 0 then
            rangeParts[#rangeParts + 1] = string.format("%s %gy", L["Range"], maxRange)
        end
        if type(spellRadius) == "number" and spellRadius > 0 then
            rangeParts[#rangeParts + 1] = string.format("%s %gy", L["Radius"], spellRadius)
        end
        local rangeInfo
        if #rangeParts > 0 then
            rangeInfo = TraitText("spellRangeInfo", table.concat(rangeParts, "  "), 11, "muted",
                0, -25, 1, "RIGHT")
            rangeInfo:ClearAllPoints()
            rangeInfo:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -16, -25)
            rangeInfo:SetWidth(rangeInfo:GetStringWidth() + 6)
            tooltipSkin.contentLayout[#tooltipSkin.contentLayout + 1] = {
                region = rangeInfo, x = -16, y = -25, point = "TOPRIGHT",
                relativePoint = "TOPRIGHT", width = rangeInfo:GetWidth(),
            }
        elseif tooltipSkin.spellRangeInfo then
            tooltipSkin.spellRangeInfo:Hide()
        end
        local abilityWidth = tooltip:GetWidth() - 72 - (rangeInfo and rangeInfo:GetWidth() + 8 or 0)
        local abilityType = TraitText("spellAbilityType", spellLabel, 11, "muted",
            56, -25, math.max(1, abilityWidth), "LEFT")
        abilityType:ClearAllPoints()
        abilityType:SetPoint("TOPLEFT", spellTitle, "BOTTOMLEFT", 0, 3)
        tooltipSkin.contentLayout[#tooltipSkin.contentLayout + 1] = {
            region = abilityType, x = 0, y = 3, point = "TOPLEFT",
            relativeTo = spellTitle, relativePoint = "BOTTOMLEFT",
            headerWidth = true, rangeInfo = rangeInfo,
        }
        tooltipSkin.originalWidth = tooltip:GetWidth()
        tooltipSkin.targetWidth = math.max(420, tooltipSkin.originalWidth)
        tooltip:SetWidth(tooltipSkin.targetWidth)

        local castText = type(castTime) ~= "number" and "--"
            or castTime > 0 and string.format("%.2fs", castTime / 1000) or L["Instant"]
        local cooldownText = "--"
        if hasSpellID then
            local cooldownMS, globalCooldownMS = Tooltips.SpellCooldownMS(spellID)
            if cooldownMS ~= nil or globalCooldownMS > 0 then
                cooldownText = string.format("%.2fs", math.max(cooldownMS or 0, globalCooldownMS) / 1000)
            end
        end

        local resourceLabel, resourceValue
        if hasSpellID and C_Spell and type(C_Spell.GetSpellPowerCost) == "function" then
            local costs = C_Spell.GetSpellPowerCost(spellID)
            if not (issecretvalue and issecretvalue(costs)) and type(costs) == "table" then
                local powerLabels = {}
                local powerNames = {
                    Mana = "MP", Rage = "RP", Focus = "FP", Energy = "EP",
                    RunicPower = "RP", ComboPoints = "CP", Runes = "RP",
                    SoulShards = "SP", LunarPower = "AP", HolyPower = "HP",
                    Maelstrom = "MP", Chi = "CP", Insanity = "IP", ArcaneCharges = "AC",
                    Fury = "FP", Pain = "PP", Essence = "EP",
                }
                for name, abbreviation in pairs(powerNames) do
                    local powerType = Enum and Enum.PowerType and Enum.PowerType[name]
                    if type(powerType) == "number" then powerLabels[powerType] = abbreviation end
                end
                local tokenLabels = {MANA = "MP", RAGE = "RP", FOCUS = "FP", ENERGY = "EP",
                    RUNIC_POWER = "RP", COMBO_POINTS = "CP", RUNES = "RP", SOUL_SHARDS = "SP",
                    LUNAR_POWER = "AP", HOLY_POWER = "HP", MAELSTROM = "MP", CHI = "CP",
                    INSANITY = "IP", ARCANE_CHARGES = "AC", FURY = "FP", PAIN = "PP", ESSENCE = "EP"}
                for _, costInfo in ipairs(costs) do
                    if not (issecretvalue and issecretvalue(costInfo)) and type(costInfo) == "table" then
                        local powerType = costInfo.type
                        local amount = costInfo.cost
                        if issecretvalue and issecretvalue(amount) then amount = nil end
                        if amount == nil then
                            amount = costInfo.minCost
                            if issecretvalue and issecretvalue(amount) then amount = nil end
                        end
                        local requiredAuraID, hasRequiredAura = costInfo.requiredAuraID, costInfo.hasRequiredAura
                        local auraValid = not (issecretvalue and
                            (issecretvalue(requiredAuraID) or issecretvalue(hasRequiredAura)))
                            and (not requiredAuraID or requiredAuraID == 0 or hasRequiredAura)
                        local label = not (issecretvalue and issecretvalue(powerType)) and powerLabels[powerType]
                        local costName = costInfo.name
                        if issecretvalue and issecretvalue(costName) then costName = nil end
                        if not label and type(costName) == "string" then
                            label = tokenLabels[costName:upper()]
                        end
                        if label and auraValid and not (issecretvalue and issecretvalue(amount))
                            and type(amount) == "number" and amount > 0 then
                            resourceLabel, resourceValue = L["%s Cost"]:format(label), string.format("%.0f", amount)
                            break
                        end
                    end
                end
            end
        end

        local tooltipWidth = tooltip:GetWidth()
        local cellWidth = (tooltipWidth - 32) / 3
        local traits = {
            {header = "spellCastHeader", value = "spellCastValue", label = L["Cast"], text = castText},
            {header = "spellCooldownHeader", value = "spellCooldownValue", label = L["Recast"], text = cooldownText},
        }
        if resourceLabel and resourceValue then
            traits[3] = {header = "spellCostHeader", value = "spellCostValue", label = resourceLabel, text = resourceValue}
        end
        if isPassive then traits = {} end
        local metricsTop = -66
        local dividerY = isPassive and -53 or metricsTop - 46
        tooltipSkin.spellRegions = tooltipSkin.spellRegions or {}
        for index, color in ipairs({{0, 0, 0, 0.85}, {1, 1, 1, 0.4}}) do
            local piece = tooltipSkin.spellRegions[index]
            if not piece then
                piece = tooltip:CreateTexture(nil, "ARTWORK")
                tooltipSkin.spellRegions[index] = piece
            end
            piece:SetColorTexture(unpack(color))
            piece:ClearAllPoints()
            piece:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, dividerY - (index - 1))
            piece:SetSize(tooltipWidth - 32, 1)
            piece:Show()
        end
        for index, trait in ipairs(traits) do
            local x = 16 + (index - 1) * cellWidth
            TraitText(trait.header, trait.label, 11, "muted", x, metricsTop, cellWidth - 8, "RIGHT")
            TraitText(trait.value, trait.text, 16, "text", x, metricsTop - 17, cellWidth - 8, "RIGHT")
            tooltipSkin.spellBars = tooltipSkin.spellBars or {}
            tooltipSkin.spellBars[index] = tooltipSkin.spellBars[index] or {}
            TraitUnderline(tooltipSkin.spellBars[index], x, metricsTop - 30, cellWidth - 8)
        end
        if data and data.lines and lineTypes then
            local tooltipName = tooltip:GetName()
            local saved, lines, seen = tooltipSkin.consumableText, {}, {}
            tooltipSkin.secretLineHeight = false
            local y = isPassive and -62 or metricsTop - 52
            for index, line in ipairs(data.lines) do
                local lineType, lineIndex = line.type, line.lineIndex or index
                if not (issecretvalue and (issecretvalue(lineType) or issecretvalue(lineIndex))) then
                    seen[lineIndex] = true
                    local left = _G[tooltipName .. "TextLeft" .. lineIndex]
                    local right = _G[tooltipName .. "TextRight" .. lineIndex]
                    local leftText = left and left:GetText()
                    local rightText = right and right:GetText()
                    local leftSecret = issecretvalue and issecretvalue(leftText)
                    local rightSecret = issecretvalue and issecretvalue(rightText)
                    local keepLine = lineType == lineTypes.SpellDescription
                        or lineType == lineTypes.FlavorText
                        or lineType == lineTypes.UsageRequirement
                        or lineType == lineTypes.ErrorLine or lineType == lineTypes.DisabledLine
                    if lineType == lineTypes.SpellName then
                        if left then
                            Tooltips.SaveNativeRegion(saved, left, tooltipSkin.nativeSpellTitleAlpha or 1)
                            GuardEquipmentAlpha(left)
                            left:SetAlpha(0)
                        end
                    elseif lineType == lineTypes.None or lineType == lineTypes.Blank or not keepLine then
                        for _, region in pairs({left = left, right = right}) do
                            if region then
                                Tooltips.SaveNativeRegion(saved, region, nil, true)
                                region:SetAlpha(0)
                            end
                        end
                    else
                        local isGenericMetadata = lineType == lineTypes.None or lineType == lineTypes.Blank
                        if left and isGenericMetadata then
                            local text = leftText
                            if not (issecretvalue and issecretvalue(text)) and type(text) == "string" then
                                local cleaned = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                                local isInstant = (type(SPELL_CAST_TIME_INSTANT) == "string"
                                    and cleaned == SPELL_CAST_TIME_INSTANT) or cleaned == "Instant"
                                local isCost = resourceValue and
                                    (cleaned:match("^%s*" .. resourceValue .. "%s+") ~= nil)
                                if isInstant or isCost then
                                    Tooltips.SaveNativeRegion(saved, left, nil, true)
                                    left:SetAlpha(0)
                                    leftText = nil
                                end
                            end
                        end
                        local hideLine = isGenericMetadata
                        if hideLine then
                            for _, region in pairs({left = left, right = right}) do
                                if region and not saved[region] then
                                    Tooltips.SaveNativeRegion(saved, region)
                                    region:SetAlpha(0)
                                end
                            end
                        elseif leftSecret or rightSecret
                            or (type(leftText) == "string" and leftText ~= "")
                            or (type(rightText) == "string" and rightText ~= "") then
                            -- Secret text cannot be read in combat, but the line still needs placing.
                            for _, region in pairs({left = left, right = right}) do
                                if region then
                                    Tooltips.SaveNativeRegion(saved, region, nil, true)
                                    region:SetAlpha(0)
                                end
                            end
                            local rightWidth = 0
                            if right and (rightSecret or type(rightText) == "string" and rightText ~= "") then
                                rightWidth = right:GetStringWidth()
                            end
                            if issecretvalue and issecretvalue(rightWidth) then rightWidth = 0 end
                            y = Tooltips.PlaceNativeLine(tooltipSkin, saved, left, right, y, rightWidth)
                            lines[#lines + 1] = lineType
                        end
                    end
                end
            end
            local lineCount = tooltip.NumLines and tooltip:NumLines()
            if not (issecretvalue and issecretvalue(lineCount)) and type(lineCount) == "number" then
                for lineIndex = 1, lineCount do
                    if not seen[lineIndex] then
                        local left = _G[tooltipName .. "TextLeft" .. lineIndex]
                        local right = _G[tooltipName .. "TextRight" .. lineIndex]
                        local leftText = left and left:GetText()
                        local rightText = right and right:GetText()
                        if not (issecretvalue and (issecretvalue(leftText) or issecretvalue(rightText)))
                            and (type(leftText) == "string" and leftText ~= ""
                                or type(rightText) == "string" and rightText ~= "") then
                            if left then Tooltips.SaveNativeRegion(saved, left) end
                            if right then Tooltips.SaveNativeRegion(saved, right) end
                            y = Tooltips.PlaceNativeLine(tooltipSkin, saved, left, right, y)
                        end
                    end
                end
            end
            tooltipSkin.consumableHeight = tooltip:GetHeight()
            tooltipSkin.fitMinimum = 0
            tooltipSkin.targetHeight = -y + (left and left:GetStringHeight() or 14) + 14
            if tooltipSkin.secretLineHeight then
                tooltipSkin.targetHeight = math.max(tooltipSkin.targetHeight, tooltipSkin.consumableHeight)
            end
            tooltip:SetHeight(tooltipSkin.targetHeight)
        end
        if ApplyContentLayout then ApplyContentLayout() end
        tooltipSkin.spellID = spellID
    end

    return StyleSpellTooltip
end