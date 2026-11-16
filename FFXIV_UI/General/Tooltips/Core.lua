local addonName, ns = ...
local addonEnv = ns
local ROOT = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\"
local uv = {0, 0.25, 0.75, 1}
local MINIMAP_TOOLTIP_MIN_WIDTH = 160
local MINIMAP_TOOLTIP_HORIZONTAL_PADDING = 64
local MINIMAP_TOOLTIP_VERTICAL_PADDING = 24
local MINIMAP_TOOLTIP_SCREEN_MARGIN = 24
local tooltipSkins = setmetatable({}, {__mode = "k"})
local Tooltips = {}
ns.Tooltips = Tooltips
Tooltips.L = ns.L or setmetatable({}, {__index = function(_, key) return key end})

function Tooltips.StyleFont(region, size, token)
    region.FFXIVUITooltipFontSize = size
    local font = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf"
    region:SetFont(ns.GetFont and ns.GetFont(font) or font, size, "")
    region:SetShadowColor(0, 0, 0, 0.55)
    region:SetShadowOffset(1, -1)
    region:SetTextColor(unpack(addonEnv.Themes.GetPalette()[token]))
end

-- 530 -> "8m 50s", 3900 -> "1h 5m"; under a minute keeps decimals only when needed.
function Tooltips.FormatDuration(seconds)
    if seconds < 60 then
        return seconds == math.floor(seconds) and string.format("%ds", seconds) or string.format("%.2fs", seconds)
    end
    seconds = math.floor(seconds + 0.5)
    local hours, minutes, remainder = math.floor(seconds / 3600), math.floor(seconds % 3600 / 60), seconds % 60
    local parts = {}
    if hours > 0 then parts[#parts + 1] = hours .. "h" end
    if minutes > 0 then parts[#parts + 1] = minutes .. "m" end
    if remainder > 0 then parts[#parts + 1] = remainder .. "s" end
    return table.concat(parts, " ")
end

function Tooltips.FindDataType(pattern)
    local types = Enum and Enum.TooltipDataType
    if not types then return nil end
    for name, value in pairs(types) do
        if type(name) == "string" and name:find(pattern) then return value end
    end
end

function Tooltips.IsAuraTooltip(tooltip)
    local auraType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.UnitAura
    local data = tooltip.GetTooltipData and tooltip:GetTooltipData()
    if data and not (issecretvalue and issecretvalue(data.type)) and auraType and data.type == auraType then
        return true
    end
    local info = tooltip.GetPrimaryTooltipInfo and tooltip:GetPrimaryTooltipInfo()
    local getter = info and info.getterName
    if issecretvalue and issecretvalue(getter) then return false end
    return getter == "GetUnitAura" or getter == "GetUnitBuff" or getter == "GetUnitDebuff"
        or getter == "GetUnitAuraByAuraInstanceID" or getter == "GetUnitBuffByAuraInstanceID"
        or getter == "GetUnitDebuffByAuraInstanceID"
        or getter == "SetUnitAura" or getter == "SetUnitBuff" or getter == "SetUnitDebuff"
        or getter == "SetUnitAuraByAuraInstanceID" or getter == "SetUnitBuffByAuraInstanceID"
        or getter == "SetUnitDebuffByAuraInstanceID"
end

-- Longest known cooldown for a spell in ms (nil if none) and its global cooldown in ms.
function Tooltips.SpellCooldownMS(spellID)
    local function Usable(value) return type(value) == "number" and not (issecretvalue and issecretvalue(value)) end
    local globalCooldownMS, cooldownMS = 0, nil
    if type(GetSpellBaseCooldown) == "function" then
        local baseMS, gcdMS = GetSpellBaseCooldown(spellID)
        if Usable(gcdMS) then globalCooldownMS = gcdMS end
        if Usable(baseMS) and baseMS >= 0 then cooldownMS = baseMS end
    end
    local function Consider(milliseconds)
        if Usable(milliseconds) and milliseconds > 0 then cooldownMS = math.max(cooldownMS or 0, milliseconds) end
    end
    -- Spells with charges report their recharge time here instead of as a base cooldown.
    local charges = C_Spell and type(C_Spell.GetSpellCharges) == "function" and C_Spell.GetSpellCharges(spellID)
    if type(charges) == "table" and not (issecretvalue and issecretvalue(charges)) and Usable(charges.cooldownDuration) then
        Consider(charges.cooldownDuration * 1000)
    end
    local current = C_Spell and type(C_Spell.GetSpellCooldown) == "function" and C_Spell.GetSpellCooldown(spellID)
    if type(current) == "table" and not (issecretvalue and issecretvalue(current)) and Usable(current.duration) then
        Consider(current.duration * 1000)
    end
    return cooldownMS, globalCooldownMS
end

function Tooltips.SaveNativeRegion(saved, region, alpha, replace)
    if not region or saved[region] and not replace then return end
    local point = {region:GetPoint(1)}
    local current = alpha or region:GetAlpha()
    -- Secret alpha can't be stored, compared or reapplied from addon code; Blizzard tooltip text is fully opaque by default.
    if issecretvalue and issecretvalue(current) then current = 1 end
    saved[region] = {point = point[1] and point or nil, alpha = current}
end

local function CanRestorePoint(point)
    if not point then return false end
    for index = 1, 5 do
        if issecretvalue and issecretvalue(point[index]) then return false end
    end
    return point[1] ~= nil
end

local function IsUsableNumber(value)
    return type(value) == "number" and not (issecretvalue and issecretvalue(value))
end

function Tooltips.PlaceNativeLine(tooltipSkin, saved, left, right, cursor, rightWidth)
    local tooltip = tooltipSkin.tooltip
    local itemRow = rightWidth == nil
    if left then tooltipSkin.consumableRows[left] = true end
    if right then
        tooltipSkin.consumableRows[right] = true
        right:ClearAllPoints()
        right:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -16, cursor)
        right:SetAlpha(saved[right].alpha)
        if itemRow then
            right:SetJustifyH("RIGHT")
            rightWidth = right:GetStringWidth()
            if issecretvalue and issecretvalue(rightWidth) then rightWidth = 0 end
        end
    end
    rightWidth = rightWidth or 0
    if left then
        left:ClearAllPoints()
        left:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, cursor)
        left:SetWidth(math.max(1, tooltip:GetWidth() - 32 - (right and rightWidth + 8 or 0)))
        left:SetAlpha(saved[left].alpha)
        left:SetWordWrap(true)
        tooltipSkin.contentLayout[#tooltipSkin.contentLayout + 1] = {
            region = left, x = 16, y = cursor,
            rightWidth = right and rightWidth + 8 or itemRow and 0 or nil,
        }
    end
    if right then
        tooltipSkin.contentLayout[#tooltipSkin.contentLayout + 1] = {
            region = right, anchor = "TOPRIGHT", x = -16, y = cursor,
        }
    end
    local height = left and left:GetStringHeight() or (itemRow and 14 or 12)
    if issecretvalue and issecretvalue(height) then
        height = itemRow and 14 or 12
        tooltipSkin.secretLineHeight = true
    end
    if type(height) ~= "number" or height <= 0 then height = 14 end
    if itemRow and right then
        local rightHeight = right:GetStringHeight()
        if not (issecretvalue and issecretvalue(rightHeight)) and type(rightHeight) == "number" then
            height = math.max(height, rightHeight)
        end
    end
    return cursor - math.max(14, height) - 4
end

function Tooltips.ApplyTrainerRecipeTooltip(tooltip)
    if not tooltip or not tooltip.GetSpell or not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeInfo then
        return false
    end
    local _, spellID = tooltip:GetSpell()
    if not spellID or (issecretvalue and issecretvalue(spellID)) then return false end
    local recipeInfo = C_TradeSkillUI.GetRecipeInfo(spellID)
    if not recipeInfo or not recipeInfo.name then return false end
    local outputData = C_TradeSkillUI.GetRecipeOutputItemData and C_TradeSkillUI.GetRecipeOutputItemData(spellID)
    if outputData and outputData.hyperlink then
        tooltip:SetHyperlink(outputData.hyperlink)
    elseif outputData and outputData.itemID then
        tooltip:SetItemByID(outputData.itemID)
    else
        return false
    end
    local rows = {{text = Tooltips.L["Profession Recipe:"] .. " " .. recipeInfo.name, color = {1, 0.82, 0}}}
    local schematic = C_TradeSkillUI.GetRecipeSchematic and C_TradeSkillUI.GetRecipeSchematic(spellID, false)
    if schematic and schematic.reagentSlotSchematics then
        rows[#rows + 1] = {text = Tooltips.L["Reagents:"], color = {1, 1, 1}}
        for _, slot in ipairs(schematic.reagentSlotSchematics) do
            local reagent = slot.reagents and slot.reagents[1]
            if reagent and reagent.itemID then
                if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(reagent.itemID) end
                rows[#rows + 1] = {itemID = reagent.itemID, count = slot.quantityRequired or 1, color = {0.8, 0.8, 0.8}}
            end
        end
    end
    tooltip.FFXIVUITrainerRecipeRows = rows
    -- The trainer hook can run on an already-visible tooltip, which does not fire OnShow again.
    local tooltipSkin = tooltipSkins[tooltip]
    if tooltipSkin then Tooltips.PlaceTrainerRecipeRows(tooltip, tooltipSkin) end
    return true
end

local function ResolveRecipeRowText(row)
    if row.text then return row.text end
    local name = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(row.itemID)
    if type(name) ~= "string" then name = "item:" .. row.itemID end
    return name .. " (" .. row.count .. ")"
end

-- Placed after the item layout so the rows sit below the item body and the frame grows to fit them.
function Tooltips.PlaceTrainerRecipeRows(tooltip, tooltipSkin)
    local rows = tooltip.FFXIVUITrainerRecipeRows
    local pool = tooltipSkin.trainerRecipeRegions or {}
    tooltipSkin.trainerRecipeRegions = pool
    for _, region in ipairs(pool) do region:Hide() end
    if not rows or #rows == 0 or not tooltipSkin.targetHeight then return end
    if tooltipSkin.targetHeight ~= tooltip.FFXIVUIRecipeHeight then
        tooltip.FFXIVUIRecipeBase = tooltipSkin.targetHeight
    end
    local base = tooltip.FFXIVUIRecipeBase or tooltipSkin.targetHeight
    local cursor = 16 - base - 10
    local width = math.max(1, tooltip:GetWidth() - 32)
    for index, row in ipairs(rows) do
        local region = pool[index]
        if not region then
            region = tooltip:CreateFontString(nil, "OVERLAY", "FFXIV_TooltipTypeTemplate")
            region.FFXIVUITrainerRecipeRow = true
            Tooltips.StyleFont(region, 11, "text")
            pool[index] = region
        end
        region:SetTextColor(unpack(row.color))
        region:SetWidth(width)
        region:SetWordWrap(true)
        region:SetJustifyH("LEFT")
        region:ClearAllPoints()
        region:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, cursor)
        region:SetText(ResolveRecipeRowText(row))
        region:Show()
        cursor = cursor - math.max(12, region:GetStringHeight() or 12) - 2
    end
    local bottomPadding = 28
    tooltip.FFXIVUIRecipeHeight = -cursor + bottomPadding
    tooltipSkin.targetHeight = tooltip.FFXIVUIRecipeHeight
    tooltip:SetHeight(tooltipSkin.targetHeight)
end

-- Every item layout pass resets targetHeight, so the recipe rows must be placed again after it.
local function RefreshItemHeader(tooltipSkin)
    if not tooltipSkin.updateItemHeader then return end
    tooltipSkin.updateItemHeader()
    Tooltips.PlaceTrainerRecipeRows(tooltipSkin.tooltip, tooltipSkin)
end

function addonEnv.RoundTooltip(tooltip)
    if not tooltip then return false end
    if tooltipSkins[tooltip] then return true end
    local consumableTemplates = {
        itemTypeText = "FFXIV_TooltipTypeTemplate",
        itemCountText = "FFXIV_TooltipCountTemplate",
        recastHeader = "FFXIV_TooltipHeadingTemplate",
        effectsHeader = "FFXIV_TooltipHeadingTemplate",
        recastText = "FFXIV_TooltipValueTemplate",
        itemDescription = "FFXIV_TooltipDescriptionTemplate",
        bindingLabel = "FFXIV_TooltipFooterTemplate",
    }
    local fillPath = ROOT .. "Tooltip-Fill-Dark.tga"
    local function TraitUnderline(pieces, x, y, width)
        for index = 1, 3 do
            local piece = pieces[index]
            if not piece then
                piece = tooltip:CreateTexture(nil, "BACKGROUND", nil, -6)
                piece:SetTexture("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Bar-Pill.tga")
                piece:SetTexCoord(index == 1 and 0 or index == 2 and 0.25 or 0.75,
                    index == 1 and 0.25 or index == 2 and 0.75 or 1, 0, 1)
                piece:SetVertexColor(0.32, 0.32, 0.32, 1)
                piece:SetHeight(5)
                if index == 1 or index == 3 then
                    local mask = tooltip:CreateMaskTexture()
                    piece:AddMaskTexture(mask)
                    piece.mask = mask
                end
                pieces[index] = piece
            end
            local offset = index == 1 and 0 or index == 2 and 2 or width - 2.5
            piece:ClearAllPoints()
            piece:SetPoint("TOPLEFT", tooltip, "TOPLEFT", x + offset, y)
            piece:SetWidth(index == 2 and width - 4 or 2.5)
            piece:Show()
        end
    end

    local function AddSlices(texturePath, layer, sublevel, includeCenter, tiledCenter, cap, verticalUV, reference)
        local tooltip = reference or tooltip
        cap = cap or 16
        verticalUV = verticalUV or uv
        local slices = {}
        for row = 1, 3 do
            for column = 1, 3 do
                if includeCenter or row ~= 2 or column ~= 2 then
                    local texture = tooltip:CreateTexture(nil, layer, nil, sublevel)
                    texture:SetTexture(texturePath)
                    texture:SetTexCoord(uv[column], uv[column + 1], verticalUV[row], verticalUV[row + 1])
                    if row == 1 then
                        if column == 2 then
                            texture:SetPoint("TOPLEFT", tooltip, "TOPLEFT", cap, 0)
                            texture:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -cap, 0)
                            texture:SetHeight(cap)
                        else
                            texture:SetPoint(column == 1 and "TOPLEFT" or "TOPRIGHT", tooltip,
                                column == 1 and "TOPLEFT" or "TOPRIGHT")
                            texture:SetSize(cap, cap)
                        end
                    elseif row == 3 then
                        if column == 2 then
                            texture:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", cap, 0)
                            texture:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -cap, 0)
                            texture:SetHeight(cap)
                        else
                            texture:SetPoint(column == 1 and "BOTTOMLEFT" or "BOTTOMRIGHT", tooltip,
                                column == 1 and "BOTTOMLEFT" or "BOTTOMRIGHT")
                            texture:SetSize(cap, cap)
                        end
                    elseif column == 1 then
                        texture:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 0, -cap)
                        texture:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", 0, cap)
                        texture:SetWidth(cap)
                    elseif column == 3 then
                        texture:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", 0, -cap)
                        texture:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 0, cap)
                        texture:SetWidth(cap)
                    elseif row == 2 then
                        texture:SetPoint("TOPLEFT", tooltip, "TOPLEFT", cap, -cap)
                        texture:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -cap, cap)
                        if tiledCenter then
                            texture:SetTexture(fillPath, "REPEAT", "REPEAT")
                            texture:SetHorizTile(true)
                            texture:SetVertTile(true)
                        end
                    end
                    slices[#slices + 1] = {texture = texture, row = row, column = column,
                        tiled = tiledCenter and row == 2 and column == 2}
                end
            end
        end
        return slices
    end
    local function AddTemplateSlices(prefix, layer, sublevel, includeCenter)
        local slices = {}
        for row = 1, 3 do
            for column = 1, 3 do
                if includeCenter or row ~= 2 or column ~= 2 then
                    local texture = tooltip:CreateTexture(nil, layer, prefix .. row .. column .. "Template", sublevel)
                    slices[#slices + 1] = {texture = texture, row = row, column = column,
                        tiled = prefix == "FFXIV_TooltipBackground" and row == 2 and column == 2}
                end
            end
        end
        return slices
    end
    local background = AddTemplateSlices("FFXIV_TooltipBackground", "BACKGROUND", -8, true)
    local shine = {}
    local cornerRadius = 16
    for index = 1, 40 do
        local offsetY = index - 1
        local inset = offsetY < cornerRadius
            and math.ceil(cornerRadius - math.sqrt(cornerRadius ^ 2 - (cornerRadius - offsetY) ^ 2)) or 0
        local strip = tooltip:CreateTexture(nil, "BACKGROUND", nil, -7)
        strip:SetColorTexture(1, 1, 1, 0.16 * (41 - index) / 40)
        strip:SetPoint("TOPLEFT", tooltip, "TOPLEFT", inset, -offsetY)
        strip:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -inset, -offsetY)
        strip:SetHeight(1)
        shine[index] = strip
    end
    local slices = AddTemplateSlices("FFXIV_TooltipRim", "OVERLAY", 7, false)
    local tooltipSkin = {tooltip = tooltip, slices = slices, background = background,
        shine = shine,
        nativeBorder = setmetatable({}, {__mode = "k"})}
    tooltipSkins[tooltip] = tooltipSkin
    if type(tooltip.SetTrainerService) == "function" then
        hooksecurefunc(tooltip, "SetTrainerService", function(self)
            Tooltips.ApplyTrainerRecipeTooltip(self)
        end)
    end
    local function ConsumableRegion(key, size, token)
        if key == "bindingLabel" then size = 10
        elseif key ~= "recastHeader" and key ~= "recastText" then size = 11 end
        if not tooltipSkin[key] then
            tooltipSkin[key] = tooltip:CreateFontString(nil, "OVERLAY", consumableTemplates[key])
            Tooltips.StyleFont(tooltipSkin[key], size, token)
        end
        local color = addonEnv.Themes.GetPalette()[token]
        tooltipSkin[key]:SetTextColor(unpack(color))
        if tooltipSkin.consumableRows then tooltipSkin.consumableRows[tooltipSkin[key]] = true end
        return tooltipSkin[key]
    end
    local function HousingIcon()
        if not tooltipSkin.housingIcon then
            local menu = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Menu\\"
            local icon = tooltip:CreateTexture(nil, "OVERLAY")
            icon:SetTexture(menu .. "Housing.tga")
            local mask = tooltip:CreateMaskTexture()
            mask:SetTexture(menu .. "CircleMask.tga", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(icon)
            icon:AddMaskTexture(mask)
            local ring = tooltip:CreateTexture(nil, "OVERLAY", nil, 1)
            ring:SetTexture(menu .. "GoldRing.tga")
            ring:SetAllPoints(icon)
            tooltipSkin.housingIcon = icon
            tooltipSkin.housingRing = ring
        end
        tooltipSkin.housingIcon:Show()
        tooltipSkin.housingRing:Show()
        return tooltipSkin.housingIcon
    end
    local function FitConsumableFrame()
        local regions = tooltipSkin.consumableRows
        if not regions or not tooltip.IsShown or not tooltip:IsShown()
            or type(tooltip.GetTop) ~= "function" then return end
        local top = tooltip:GetTop()
        if issecretvalue and issecretvalue(top) then return end
        if type(top) ~= "number" then return end
        local lowest = top
        for region in pairs(regions) do
            if region:IsShown() and type(region.GetBottom) == "function" then
                local bottom = region:GetBottom()
                if not (issecretvalue and issecretvalue(bottom)) and type(bottom) == "number" then
                    lowest = math.min(lowest, bottom)
                end
            end
        end

        local minimumHeight = tooltipSkin.fitMinimum or tooltipSkin.consumableHeight or 0
        local measuredHeight = top - lowest + (tooltipSkin.auraLayoutActive and 6 or 18)
        local targetHeight = math.max(minimumHeight, measuredHeight, tooltipSkin.targetHeight or 0)
        if targetHeight > tooltip:GetHeight() then tooltip:SetHeight(targetHeight) end
    end
    local function GuardEquipmentAlpha(region)
        tooltipSkin.equipmentAlphaHooks = tooltipSkin.equipmentAlphaHooks or {}
        if tooltipSkin.equipmentAlphaHooks[region] then return end
        tooltipSkin.equipmentAlphaHooks[region] = true
        hooksecurefunc(region, "SetAlpha", function(self, alpha)
            local binding = tooltipSkin.bindingSources and tooltipSkin.bindingSources[self] ~= nil
            local replaced = binding or tooltipSkin.consumableText and tooltipSkin.consumableText[self]
                or tooltipSkin.equipmentMoneyFrames and tooltipSkin.equipmentMoneyFrames[self] ~= nil
            -- Native lines re-placed by PlaceNativeLine must be allowed to show again.
            if replaced and tooltipSkin.consumableRows and tooltipSkin.consumableRows[self] then replaced = false end
            if replaced and not (issecretvalue and issecretvalue(alpha)) and alpha ~= 0 then
                self:SetAlpha(0)
            end
        end)
    end
    local function HideNativeMoneyFrames()
        local name = tooltip:GetName()
        if type(name) ~= "string" then return end
        tooltipSkin.equipmentMoneyFrames = tooltipSkin.equipmentMoneyFrames or {}
        for index = 1, (tooltip.numMoneyFrames or 1) do
            local frame = _G[name .. "MoneyFrame" .. index]
            if frame then
                if tooltipSkin.equipmentMoneyFrames[frame] == nil then
                    tooltipSkin.equipmentMoneyFrames[frame] = frame:GetAlpha()
                end
                GuardEquipmentAlpha(frame)
                frame:SetAlpha(0)
            end
        end
    end
    local function HideNativeSellPrices(sellIndexes, rows)
        local name = tooltip:GetName()
        if type(name) ~= "string" or type(tooltip.NumLines) ~= "function" then return end
        local prefix = (SELL_PRICE or "Sell Price") .. ":"
        tooltipSkin.consumableText = tooltipSkin.consumableText or {}
        local firstLeft
        local lineCount = tooltip:NumLines()
        for index in pairs(sellIndexes or {}) do
            if type(index) == "number" and index > lineCount then lineCount = index end
        end
        for index = 1, lineCount do
            local isSell = sellIndexes and sellIndexes[index]
            for _, side in ipairs({"TextLeft", "TextRight"}) do
                local region = _G[name .. side .. index]
                if region then
                    local text = region:GetText()
                    local matched = not (issecretvalue and issecretvalue(text)) and type(text) == "string"
                        and text:sub(1, #prefix) == prefix
                    local placed = tooltipSkin.consumableRows and tooltipSkin.consumableRows[region]
                    if (isSell or matched) and (matched or not placed) then
                        Tooltips.SaveNativeRegion(tooltipSkin.consumableText, region)
                        GuardEquipmentAlpha(region)
                        region:SetAlpha(0)
                        if rows then rows[region] = nil end
                        if side == "TextLeft" then firstLeft = firstLeft or region end
                    end
                end
            end
        end
        return firstLeft
    end
    local function HideEquipmentNative()
        if not tooltipSkin.equipmentWidth then return end
        for region in pairs(tooltipSkin.consumableText or {}) do
            GuardEquipmentAlpha(region)
            region:SetAlpha(0)
        end
        local name = tooltip:GetName()
        if type(name) ~= "string" then return end
        local lineCount = type(tooltip.NumLines) == "function" and tooltip:NumLines()
            or tooltipSkin.equipmentLineCount or 0
        for index = 1, lineCount do
            local region = _G[name .. "TextLeft" .. index]
            if region then
                local text = region:GetText()
                local prefix = (SELL_PRICE or "Sell Price") .. ":"
                if not (issecretvalue and issecretvalue(text)) and type(text) == "string"
                    and text:sub(1, #prefix) == prefix then
                    Tooltips.SaveNativeRegion(tooltipSkin.consumableText, region)
                    GuardEquipmentAlpha(region)
                    region:SetAlpha(0)
                end
            end
        end
        HideNativeMoneyFrames()
    end
    local function RestoreConsumableLayout()
        tooltipSkin.equipmentWidth = nil
        tooltipSkin.spellID = nil
        tooltipSkin.equipmentRenderedRegions = nil
        if tooltipSkin.spellTitle then tooltipSkin.spellTitle:Hide() end
        local bindings = tooltipSkin.bindingSources
        tooltipSkin.bindingSources = nil
        local nativeText = tooltipSkin.consumableText
        tooltipSkin.consumableText = nil
        local restoreRegions = {}
        for region, state in pairs(nativeText or {}) do
            if CanRestorePoint(state.point) then
                region:ClearAllPoints()
                restoreRegions[#restoreRegions + 1] = {region = region, state = state}
            end
        end
        for _, entry in ipairs(restoreRegions) do
            local region, state = entry.region, entry.state
            region:SetPoint(unpack(state.point))
        end
        for region, state in pairs(nativeText or {}) do
            region:SetAlpha(state.alpha)
        end
        tooltipSkin.consumableRows = nil
        tooltipSkin.contentLayout = nil
        tooltipSkin.targetHeight = nil
        tooltipSkin.fitMinimum = nil
        tooltipSkin.targetWidth = nil
        for region, alpha in pairs(bindings or {}) do region:SetAlpha(alpha) end
        if tooltipSkin.bindingLabel then tooltipSkin.bindingLabel:Hide() end
        for _, key in ipairs({"itemTypeText", "itemCountText", "recastHeader", "recastText",
            "effectsHeader", "itemDescription", "spellTitle", "spellAbilityType", "spellRangeInfo", "spellCastHeader",
            "spellCastValue", "spellCooldownHeader", "spellCooldownValue",
            "spellCostHeader", "spellCostValue", "toyRequirement", "sellPriceText"}) do
            if tooltipSkin[key] then tooltipSkin[key]:Hide() end
        end
        for _, region in ipairs(tooltipSkin.spellRegions or {}) do region:Hide() end
        for _, piece in ipairs(tooltipSkin.recastDivider or {}) do piece:Hide() end
        for _, pieces in ipairs(tooltipSkin.spellBars or {}) do
            for _, piece in ipairs(pieces) do piece:Hide() end
        end
        for _, owned in pairs(tooltipSkin.rowMirrors or {}) do owned:Hide() end
        if tooltipSkin.housingIcon then tooltipSkin.housingIcon:Hide() end
        if tooltipSkin.housingRing then tooltipSkin.housingRing:Hide() end
        for _, region in ipairs(tooltipSkin.equipmentRegions or {}) do region:Hide() end
        for _, icon in ipairs(tooltipSkin.equipmentSocketIcons or {}) do icon:Hide() end
        for _, region in ipairs(tooltipSkin.equipmentDividers or {}) do region:Hide() end
        for _, region in ipairs(tooltipSkin.equipmentBands or {}) do region:Hide() end
        for _, pieces in ipairs(tooltipSkin.equipmentBars or {}) do
            for _, piece in ipairs(pieces) do piece:Hide() end
        end
        local moneyFrames = tooltipSkin.equipmentMoneyFrames
        tooltipSkin.equipmentMoneyFrames = nil
        for frame, alpha in pairs(moneyFrames or {}) do frame:SetAlpha(alpha) end
        if IsUsableNumber(tooltipSkin.consumableHeight) then
            tooltip:SetHeight(tooltipSkin.consumableHeight)
        end
        tooltipSkin.consumableHeight = nil
        if IsUsableNumber(tooltipSkin.originalWidth) then
            tooltip:SetWidth(tooltipSkin.originalWidth)
        end
        tooltipSkin.originalWidth = nil
    end
    local function RestoreItemHeader()
        tooltipSkin.auraLayoutActive = false
        for region in pairs(tooltipSkin.auraDurations or {}) do region.FFXIVUITooltipFontSize = nil end
        tooltipSkin.auraDurations = nil
        for region, state in pairs(tooltipSkin.auraNativeSizes or {}) do
            if IsUsableNumber(state.width) then region:SetWidth(state.width) end
            if IsUsableNumber(state.height) then region:SetHeight(state.height) end
            if not (issecretvalue and issecretvalue(state.wordWrap)) then
                region:SetWordWrap(state.wordWrap)
            end
            if IsUsableNumber(state.maxLines) then region:SetMaxLines(state.maxLines) end
        end
        tooltipSkin.auraNativeSizes = nil
        for _, slice in ipairs(tooltipSkin.auraBackground or {}) do slice.texture:Hide() end
        for _, slice in ipairs(slices) do slice.texture:Show() end
        for _, slice in ipairs(background) do slice.texture:Show() end
        for _, strip in ipairs(shine) do strip:Show() end
        RestoreConsumableLayout()
        tooltipSkin.spellProcessing = false
        tooltipSkin.spellLayoutActive = false
        if tooltipSkin.itemIcon then tooltipSkin.itemIcon:Hide() end
        if tooltipSkin.itemTitle and tooltipSkin.originalTitlePoint then
            if CanRestorePoint(tooltipSkin.originalTitlePoint) then
                tooltipSkin.itemTitle:ClearAllPoints()
                tooltipSkin.itemTitle:SetPoint(unpack(tooltipSkin.originalTitlePoint))
            end
            if tooltipSkin.originalTitleSize then
                tooltipSkin.itemTitle:SetSize(unpack(tooltipSkin.originalTitleSize))
                tooltipSkin.itemTitle:SetWordWrap(tooltipSkin.originalTitleWrap)
                tooltipSkin.itemTitle:SetJustifyV("TOP")
            end
        end
        tooltipSkin.itemTitle = nil
        tooltipSkin.pendingItemID = nil
        tooltipSkin.pendingSpellID = nil
    end
    local function ApplyContentLayout()
        if tooltipSkin.applyingLayout then return end
        tooltipSkin.applyingLayout = true
        local targetWidth = math.max(tooltipSkin.targetWidth or 0, tooltipSkin.equipmentWidth or 0)
        if targetWidth > tooltip:GetWidth()
            or tooltipSkin.auraLayoutActive and targetWidth ~= tooltip:GetWidth() then
            tooltip:SetWidth(targetWidth)
        end
        for _, placement in ipairs(tooltipSkin.contentLayout or {}) do
            local region = placement.region
            region:ClearAllPoints()
            local point = placement.point or placement.anchor or "TOPLEFT"
            region:SetPoint(point, placement.relativeTo or tooltip,
                placement.relativePoint or placement.anchor or point, placement.x, placement.y)
            if placement.aura then
                region:SetWidth(math.max(1, tooltip:GetWidth() - 16))
                region:SetHeight(0)
                region:SetMaxLines(0)
                region:SetWordWrap(placement.wordWrap)
            elseif placement.spellTitle then
                region:SetWidth(math.max(1, tooltip:GetWidth() - 72))
                region:SetHeight(placement.height or 18)
                region:SetWordWrap(false)
                region:SetJustifyV("MIDDLE")
            elseif region == tooltipSkin.itemTitle then
                region:SetWidth(placement.width or math.max(1, tooltip:GetWidth() - 72))
                region:SetMaxLines(0)
                region:SetWordWrap(placement.wordWrap == true)
                region:SetHeight(placement.height or 32)
                region:SetJustifyV("MIDDLE")
            elseif placement.headerWidth then
                region:SetWidth(math.max(1, tooltip:GetWidth() - 72
                    - (placement.rangeInfo and placement.rangeInfo:GetWidth() + 8 or 0)))
            elseif placement.width then
                region:SetWidth(placement.width)
            end
            if placement.rightWidth then
                region:SetWidth(math.max(1, tooltip:GetWidth() - 32 - placement.rightWidth))
                region:SetWordWrap(true)
            end
        end
        if tooltipSkin.bindingLabel and tooltipSkin.bindingLabel:IsShown() then
            tooltipSkin.bindingLabel:SetWidth(math.max(1, tooltip:GetWidth() - 72))
            for region in pairs(tooltipSkin.bindingSources or {}) do region:SetAlpha(0) end
        end
        if tooltipSkin.recastHeader and tooltipSkin.recastHeader:IsShown() then
            local cellWidth = math.max(6, (tooltip:GetWidth() - 32) / 3 - 6)
            tooltipSkin.recastHeader:SetWidth(cellWidth)
            tooltipSkin.recastText:SetWidth(cellWidth)
            for index, piece in ipairs(tooltipSkin.recastDivider or {}) do
                local _, _, _, _, offsetY = piece:GetPoint(1)
                local offset = index == 1 and 0 or index == 2 and 2 or cellWidth - 2.5
                piece:ClearAllPoints()
                piece:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16 + offset, offsetY)
                piece:SetWidth(index == 2 and cellWidth - 4 or 2.5)
            end
        end
        HideEquipmentNative()
        if tooltipSkin.spellTitle and tooltipSkin.spellTitle:IsShown() and tooltip.TextLeft1 then
            tooltip.TextLeft1:SetAlpha(0)
        end
        FitConsumableFrame()
        tooltipSkin.applyingLayout = false
    end
    local layout = {
        RestoreItemHeader = RestoreItemHeader,
        GuardEquipmentAlpha = GuardEquipmentAlpha,
        Region = ConsumableRegion,
        HousingIcon = HousingIcon,
        TraitUnderline = TraitUnderline,
        HideEquipmentNative = HideEquipmentNative,
        HideNativeMoneyFrames = HideNativeMoneyFrames,
        HideNativeSellPrices = HideNativeSellPrices,
        ApplyContentLayout = ApplyContentLayout,
    }
    local StyleItemHeader = Tooltips.InitializeItems(tooltipSkin, layout)
    local StyleSpellTooltip = Tooltips.InitializeSpells(tooltipSkin, layout)
    local StyleMountTooltip = Tooltips.InitializeMounts and Tooltips.InitializeMounts(tooltipSkin, layout)
    tooltipSkin.updateMountTooltip = StyleMountTooltip
    local StyleToyTooltip = Tooltips.InitializeToys and Tooltips.InitializeToys(tooltipSkin, layout)
    tooltipSkin.updateToyTooltip = StyleToyTooltip
    local StyleSkillTooltip = Tooltips.InitializeSkillLines and Tooltips.InitializeSkillLines(tooltipSkin, layout)
    tooltipSkin.updateSkillTooltip = StyleSkillTooltip
    local StylePetTooltip = Tooltips.InitializeSkillLines
        and Tooltips.InitializeSkillLines(tooltipSkin, layout, {category = true, dropCast = true})
    tooltipSkin.updatePetTooltip = StylePetTooltip
    local StylePetAbility = tooltip.AbilityPetType and Tooltips.InitializePetAbility
        and Tooltips.InitializePetAbility(tooltipSkin, layout)
    tooltipSkin.updatePetAbility = StylePetAbility
    if StylePetAbility then tooltip:HookScript("OnShow", StylePetAbility) end
    tooltipSkin.updateItemHeader = StyleItemHeader
    tooltipSkin.updateSpellTooltip = StyleSpellTooltip
    local function StyleAuraText(region, title, duration)
        Tooltips.StyleFont(region, title and 12 or duration and 10 or 11, "text")
        if title then
            region:SetTextColor(0.88, 0.79, 0.57, 1)
        elseif duration then
            region:SetTextColor(0.67, 0.69, 0.69, 1)
        else
            region:SetTextColor(0.94, 0.94, 0.94, 1)
        end
    end
    local function StyleAuraTooltip()
        if not Tooltips.IsAuraTooltip(tooltip) then return end
        RestoreItemHeader()
        local data = tooltip.GetTooltipData and tooltip:GetTooltipData()
        local name = tooltip:GetName()
        if not data or not data.lines or type(name) ~= "string" then return end
        tooltipSkin.auraLayoutActive = true
        for _, slice in ipairs(slices) do slice.texture:Hide() end
        for _, slice in ipairs(background) do slice.texture:Hide() end
        for _, strip in ipairs(shine) do strip:Hide() end
        if not tooltipSkin.auraBackground then
            tooltipSkin.auraBackground = {}
            for layer, alpha in ipairs({0.12, 0.22, 0.38, 0.80}) do
                local inset = layer - 1
                local surface = CreateFrame("Frame", nil, tooltip)
                surface:SetFrameLevel(math.max(0, tooltip:GetFrameLevel() - 1))
                surface:SetPoint("TOPLEFT", tooltip, "TOPLEFT", inset, -inset)
                surface:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -inset, inset)
                surface:EnableMouse(false)
                local pieces = AddSlices(ROOT .. "Bar-Pill.tga", "BACKGROUND", -8,
                    true, false, 8 - inset, {0, 0.5, 0.5, 1}, surface)
                for _, slice in ipairs(pieces) do
                    slice.texture:SetVertexColor(0.16, 0.17, 0.17, alpha)
                    tooltipSkin.auraBackground[#tooltipSkin.auraBackground + 1] = slice
                end
            end
        end
        for _, slice in ipairs(tooltipSkin.auraBackground) do slice.texture:Show() end
        tooltipSkin.originalWidth = tooltip:GetWidth()
        tooltipSkin.consumableHeight = tooltip:GetHeight()
        local title = tooltip.TextLeft1
        local titleWidth = 0
        if title then
            StyleAuraText(title, true)
            if type(title.GetUnboundedStringWidth) == "function" then
                titleWidth = title:GetUnboundedStringWidth()
            else
                titleWidth = title:GetStringWidth()
            end
            if (issecretvalue and issecretvalue(titleWidth)) or type(titleWidth) ~= "number" then titleWidth = 0 end
        end
        tooltipSkin.targetWidth = math.max(240, math.ceil(titleWidth) + 16, math.min(360, tooltipSkin.originalWidth))
        tooltip:SetWidth(tooltipSkin.targetWidth)
        tooltipSkin.consumableText, tooltipSkin.consumableRows, tooltipSkin.contentLayout = {}, {}, {}
        tooltipSkin.auraDurations = {}
        tooltipSkin.auraNativeSizes = {}
        local lineTypes = Enum and Enum.TooltipDataLineType or {}
        local hasDescription = false
        for _, line in ipairs(data.lines) do
            if not (issecretvalue and issecretvalue(line.type)) and lineTypes.SpellDescription ~= nil
                and line.type == lineTypes.SpellDescription then hasDescription = true end
        end
        local cursor = -8
        for index, line in ipairs(data.lines) do
            local lineIndex = line.lineIndex
            if not (issecretvalue and (issecretvalue(lineIndex) or issecretvalue(line.type))) then
                lineIndex = lineIndex or index
                local left = _G[name .. "TextLeft" .. lineIndex]
                local right = _G[name .. "TextRight" .. lineIndex]
                local body = lineTypes.SpellDescription ~= nil and line.type == lineTypes.SpellDescription
                    or not hasDescription and (line.type == nil or line.type == lineTypes.None)
                local title = lineIndex == 1
                local text = left and left:GetText()
                local duration = not title and not (issecretvalue and issecretvalue(text))
                    and type(text) == "string" and text:match("^%d+.- remaining%.?$") ~= nil
                local visible = title or body or duration
                for _, region in pairs({left = left, right = right}) do
                    Tooltips.SaveNativeRegion(tooltipSkin.consumableText, region)
                    GuardEquipmentAlpha(region)
                    region:SetAlpha(0)
                end
                if left and visible then
                    tooltipSkin.auraNativeSizes[left] = {
                        width = left:GetWidth(), height = left:GetHeight(), wordWrap = left:CanWordWrap(),
                        maxLines = left.GetMaxLines and left:GetMaxLines(),
                    }
                    if duration then cursor = cursor - 4 end
                    tooltipSkin.consumableRows[left] = true
                    tooltipSkin.auraDurations[left] = duration or nil
                    left:SetAlpha(tooltipSkin.consumableText[left].alpha)
                    StyleAuraText(left, title, duration)
                    left:ClearAllPoints()
                    left:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 8, cursor)
                    left:SetWidth(tooltipSkin.targetWidth - 16)
                    left:SetHeight(0)
                    left:SetMaxLines(0)
                    left:SetWordWrap(not title)
                    tooltipSkin.contentLayout[#tooltipSkin.contentLayout + 1] = {
                        region = left, x = 8, y = cursor, aura = true, wordWrap = not title,
                    }
                    local height = left:GetStringHeight()
                    if (issecretvalue and issecretvalue(height)) or type(height) ~= "number" then height = 14 end
                    cursor = cursor - math.max(title and 12 or duration and 10 or 11, height) - (title and 4 or 1)
                end
            end
        end
        tooltipSkin.fitMinimum = 0
        tooltipSkin.targetHeight = math.max(24, -cursor + 5)
        tooltip:SetHeight(tooltipSkin.targetHeight)
    end
    tooltipSkin.updateAuraTooltip = StyleAuraTooltip
    local function ApplyContentLayout()
        if tooltipSkin.applyingLayout then return end
        tooltipSkin.applyingLayout = true
        local targetWidth = math.max(tooltipSkin.targetWidth or 0, tooltipSkin.equipmentWidth or 0)
        if targetWidth > tooltip:GetWidth()
            or tooltipSkin.auraLayoutActive and targetWidth ~= tooltip:GetWidth() then
            tooltip:SetWidth(targetWidth)
        end
        for _, placement in ipairs(tooltipSkin.contentLayout or {}) do
            local region = placement.region
            region:ClearAllPoints()
            local point = placement.point or placement.anchor or "TOPLEFT"
            region:SetPoint(point, placement.relativeTo or tooltip,
                placement.relativePoint or placement.anchor or point, placement.x, placement.y)
            if placement.aura then
                region:SetWidth(math.max(1, tooltip:GetWidth() - 16))
                region:SetHeight(0)
                region:SetMaxLines(0)
                region:SetWordWrap(placement.wordWrap)
            elseif placement.spellTitle then
                region:SetWidth(math.max(1, tooltip:GetWidth() - 72))
                region:SetHeight(placement.height or 18)
                region:SetWordWrap(false)
                region:SetJustifyV("MIDDLE")
            elseif region == tooltipSkin.itemTitle then
                region:SetWidth(placement.width or math.max(1, tooltip:GetWidth() - 72))
                region:SetMaxLines(0)
                region:SetWordWrap(placement.wordWrap == true)
                region:SetHeight(placement.height or 32)
                region:SetJustifyV("MIDDLE")
            elseif placement.headerWidth then
                region:SetWidth(math.max(1, tooltip:GetWidth() - 72
                    - (placement.rangeInfo and placement.rangeInfo:GetWidth() + 8 or 0)))
            elseif placement.width then
                region:SetWidth(placement.width)
            end
            if placement.rightWidth then
                region:SetWidth(math.max(1, tooltip:GetWidth() - 32 - placement.rightWidth))
                region:SetWordWrap(true)
            end
        end
        if tooltipSkin.bindingLabel and tooltipSkin.bindingLabel:IsShown() then
            tooltipSkin.bindingLabel:SetWidth(math.max(1, tooltip:GetWidth() - 72))
            for region in pairs(tooltipSkin.bindingSources or {}) do region:SetAlpha(0) end
        end
        if tooltipSkin.recastHeader and tooltipSkin.recastHeader:IsShown() then
            local cellWidth = math.max(6, (tooltip:GetWidth() - 32) / 3 - 6)
            tooltipSkin.recastHeader:SetWidth(cellWidth)
            tooltipSkin.recastText:SetWidth(cellWidth)
            for index, piece in ipairs(tooltipSkin.recastDivider or {}) do
                local _, _, _, _, offsetY = piece:GetPoint(1)
                local offset = index == 1 and 0 or index == 2 and 2 or cellWidth - 2.5
                piece:ClearAllPoints()
                piece:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16 + offset, offsetY)
                piece:SetWidth(index == 2 and cellWidth - 4 or 2.5)
            end
        end
        HideEquipmentNative()
        if tooltipSkin.spellTitle and tooltipSkin.spellTitle:IsShown() and tooltip.TextLeft1 then
            tooltip.TextLeft1:SetAlpha(0)
        end
        FitConsumableFrame()
        -- Retail reports pre-wrap string heights for several frames after wrapping, so re-measure over a short window.
        if not tooltipSkin.fitRecheckQueued then
            tooltipSkin.fitRecheckQueued = true
            local attempts = 0
            local function Recheck()
                FitConsumableFrame()
                attempts = attempts + 1
                if attempts < 4 then
                    C_Timer.After(0.05, Recheck)
                else
                    tooltipSkin.fitRecheckQueued = false
                end
            end
            C_Timer.After(0.05, Recheck)
        end
        tooltipSkin.applyingLayout = false
    end
    local function SizeTooltip()
        local width, height = tooltip:GetSize()
        for _, slice in ipairs(background) do
            if slice.tiled then
                slice.texture:SetTexCoord(0, math.max(32, width - 32) / 64,
                    0, math.max(32, height - 32) / 64)
            end
        end
    end
    local function HideNativeBorder()
        if tooltip.SetBackdrop and tooltip.GetBackdrop and tooltip:GetBackdrop() then tooltip:SetBackdrop(nil) end
        local nineSlice = tooltip.NineSlice
        if not nineSlice then return end
        -- Textures can be created after the first pass (comparison tooltips), so hide the frame too.
        nineSlice:SetAlpha(0)
        if not tooltipSkin.nativeBorder[nineSlice] then
            tooltipSkin.nativeBorder[nineSlice] = true
            hooksecurefunc(nineSlice, "SetAlpha", function(self, alpha)
                if not (issecretvalue and issecretvalue(alpha)) and alpha ~= 0 then self:SetAlpha(0) end
            end)
        end
        for _, region in ipairs({nineSlice:GetRegions()}) do
            if region:GetObjectType() == "Texture" then
                region:SetAlpha(0)
                if not tooltipSkin.nativeBorder[region] then
                    tooltipSkin.nativeBorder[region] = true
                    hooksecurefunc(region, "SetAlpha", function(self, alpha)
                        if not (issecretvalue and issecretvalue(alpha)) and alpha ~= 0 then self:SetAlpha(0) end
                    end)
                end
            end
        end
    end
    local function StyleText()
        if not tooltip.TextLeft1 then return end
        local aura = Tooltips.IsAuraTooltip(tooltip)
        local itemType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
        local itemTooltip = itemType and tooltip.IsTooltipType and tooltip:IsTooltipType(itemType)
        for _, region in ipairs({tooltip:GetRegions()}) do
            if region:GetObjectType() == "FontString" then
                local red, green, blue, alpha = region:GetTextColor()
                local title = region == tooltip.TextLeft1 or region == tooltip.TextRight1
                -- Item names keep Blizzard's quality color.
                local itemName = itemTooltip and region == tooltip.TextLeft1
                local size = title and 14 or region == tooltipSkin.recastText and 16
                    or region.FFXIVUITooltipFontSize or 11
                region:SetFont("Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf",
                    size, "")
                region:SetShadowColor(0, 0, 0, 0.55)
                region:SetShadowOffset(1, -1)
                if aura then
                    StyleAuraText(region, title, tooltipSkin.auraDurations and tooltipSkin.auraDurations[region])
                elseif title and not itemName then
                    region:SetTextColor(unpack(addonEnv.Themes.GetPalette().text))
                else
                    region:SetTextColor(red, green, blue, alpha)
                end
            end
        end
    end
    local function RestoreMinimapMouseoverLayout()
        local state = tooltipSkin.minimapMouseoverLayout
        if not state then return end
        tooltipSkin.minimapMouseoverLayout = nil
        if IsUsableNumber(state.width) then tooltip:SetWidth(state.width) end
        if IsUsableNumber(state.height) then tooltip:SetHeight(state.height) end
        local title = state.title
        if not title then return end
        if IsUsableNumber(state.titleWidth) then title:SetWidth(state.titleWidth) end
        if IsUsableNumber(state.titleHeight) then title:SetHeight(state.titleHeight) end
        if state.wordWrap ~= nil and not (issecretvalue and issecretvalue(state.wordWrap)) then
            title:SetWordWrap(state.wordWrap)
        end
        if IsUsableNumber(state.maxLines) and type(title.SetMaxLines) == "function" then
            title:SetMaxLines(state.maxLines)
        end
    end
    local function FitMinimapMouseoverLayout()
        local minimapType = Tooltips.FindDataType("MinimapMouseover")
        local isMinimapMouseover = minimapType and tooltip.IsTooltipType
            and tooltip:IsTooltipType(minimapType)
        if not isMinimapMouseover and minimapType and tooltip.GetTooltipData then
            local data = tooltip:GetTooltipData()
            isMinimapMouseover = data and not (issecretvalue and issecretvalue(data.type))
                and data.type == minimapType
        end
        if not isMinimapMouseover then
            RestoreMinimapMouseoverLayout()
            return
        end
        local lineCount = type(tooltip.NumLines) == "function" and tooltip:NumLines()
        if not IsUsableNumber(lineCount) or lineCount ~= 1 then
            RestoreMinimapMouseoverLayout()
            return
        end

        local title = tooltip.TextLeft1
        if not title or type(title.SetWidth) ~= "function" or type(title.SetWordWrap) ~= "function" then return end
        local measureWidth = title.GetUnboundedStringWidth or title.GetStringWidth
        if type(measureWidth) ~= "function" or not UIParent
            or type(UIParent.GetWidth) ~= "function" then return end
        local textWidth = measureWidth(title)
        local screenWidth = UIParent:GetWidth()
        if not IsUsableNumber(textWidth) or textWidth <= 0
            or not IsUsableNumber(screenWidth) or screenWidth <= MINIMAP_TOOLTIP_SCREEN_MARGIN * 2 then
            return
        end

        local state = tooltipSkin.minimapMouseoverLayout
        if not state then
            state = {
                width = tooltip:GetWidth(),
                height = tooltip:GetHeight(),
                title = title,
                titleWidth = title:GetWidth(),
                titleHeight = title:GetHeight(),
                wordWrap = title.CanWordWrap and title:CanWordWrap(),
                maxLines = title.GetMaxLines and title:GetMaxLines(),
            }
            tooltipSkin.minimapMouseoverLayout = state
        end

        local maxTooltipWidth = screenWidth - MINIMAP_TOOLTIP_SCREEN_MARGIN * 2
        local tooltipWidth = math.min(maxTooltipWidth,
            math.max(math.min(MINIMAP_TOOLTIP_MIN_WIDTH, maxTooltipWidth),
                math.ceil(textWidth) + MINIMAP_TOOLTIP_HORIZONTAL_PADDING))
        local textRegionWidth = math.max(1, tooltipWidth - MINIMAP_TOOLTIP_HORIZONTAL_PADDING)
        local wraps = textWidth > textRegionWidth
        tooltip:SetWidth(tooltipWidth)
        title:SetWidth(textRegionWidth)
        if type(title.SetMaxLines) == "function" then title:SetMaxLines(0) end
        title:SetWordWrap(wraps)
        title:SetHeight(0)

        local textHeight = title:GetStringHeight()
        local lineHeight = IsUsableNumber(state.titleHeight) and math.max(1, state.titleHeight) or 14
        if not IsUsableNumber(textHeight) or textHeight <= 0 then textHeight = lineHeight end
        local lineCount = math.max(1, math.ceil(textWidth / textRegionWidth))
        local contentHeight = math.max(textHeight, lineHeight * lineCount)
        local originalHeight = IsUsableNumber(state.height) and state.height or 0
        tooltip:SetHeight(math.max(originalHeight, contentHeight + MINIMAP_TOOLTIP_VERTICAL_PADDING))
    end
    tooltipSkin.updateMinimapMouseoverLayout = FitMinimapMouseoverLayout
    HideNativeBorder()
    SizeTooltip()
    tooltip:HookScript("OnSizeChanged", SizeTooltip)
    tooltip:HookScript("OnSizeChanged", function()
        if tooltipSkin.targetWidth then ApplyContentLayout() end
    end)
    tooltip:HookScript("OnShow", HideNativeBorder)
    hooksecurefunc(tooltip, "Show", HideNativeBorder)
    tooltip:HookScript("OnShow", StyleText)
    tooltip:HookScript("OnShow", FitMinimapMouseoverLayout)
    if type(tooltip.ClearLines) == "function" then
        hooksecurefunc(tooltip, "ClearLines", RestoreMinimapMouseoverLayout)
    end
    local tooltipName = tooltip:GetName()
    local isShopping = type(tooltipName) == "string" and tooltipName:find("ShoppingTooltip")
    if not isShopping then
        tooltip:HookScript("OnShow", StyleItemHeader)
    end
    tooltip:HookScript("OnShow", function()
        Tooltips.PlaceTrainerRecipeRows(tooltip, tooltipSkin)
    end)
    tooltip:HookScript("OnShow", function()
        if Tooltips.IsAuraTooltip(tooltip) then StyleAuraTooltip(); return end
        if tooltipSkin.auraLayoutActive then RestoreItemHeader() end
        if tooltipSkin.updateCurrencyTooltip then tooltipSkin.updateCurrencyTooltip() end
        local spellType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Spell
        if spellType and tooltip.IsTooltipType and tooltip:IsTooltipType(spellType) then
            StyleSpellTooltip()
        end
        local mountType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Mount
        if StyleMountTooltip and mountType and tooltip.IsTooltipType and tooltip:IsTooltipType(mountType) then
            StyleMountTooltip()
        end
        local toyType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Toy
        if StyleToyTooltip and toyType and tooltip.IsTooltipType and tooltip:IsTooltipType(toyType) then
            StyleToyTooltip()
        end
        local skillType = Tooltips.FindDataType("Flyout")
        if StyleSkillTooltip and skillType and tooltip.IsTooltipType and tooltip:IsTooltipType(skillType) then
            StyleSkillTooltip()
        end
        local petType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.CompanionPet
        if StylePetTooltip and petType and tooltip.IsTooltipType and tooltip:IsTooltipType(petType) then
            StylePetTooltip()
        end
    end)
    tooltip:HookScript("OnShow", FitConsumableFrame)
    tooltip:HookScript("OnHide", function()
        tooltipSkin.spellProcessing = false
        tooltipSkin.spellLayoutActive = false
        tooltip.FFXIVUITrainerRecipeRows = nil
        RestoreItemHeader()
        RestoreMinimapMouseoverLayout()
    end)
    hooksecurefunc(tooltip, "Show", function()
        if tooltipSkin.auraLayoutActive and not Tooltips.IsAuraTooltip(tooltip) then RestoreItemHeader() end
    end)
    hooksecurefunc(tooltip, "Show", ApplyContentLayout)
    local nativeSpellTitle = tooltip.TextLeft1
    if nativeSpellTitle and not tooltipSkin.nativeSpellTitleHooks then
        tooltipSkin.nativeSpellTitleAlpha = nativeSpellTitle:GetAlpha()
        local function IsSpellTooltip()
            return tooltipSkin.spellProcessing or tooltipSkin.spellLayoutActive
                or (tooltipSkin.spellTitle and tooltipSkin.spellTitle:IsShown())
        end
        hooksecurefunc(nativeSpellTitle, "SetText", function(self)
            if IsSpellTooltip() then self:SetAlpha(0) end
        end)
        hooksecurefunc(nativeSpellTitle, "SetAlpha", function(self, alpha)
            if IsSpellTooltip() and not (issecretvalue and issecretvalue(alpha)) and alpha ~= 0 then self:SetAlpha(0) end
        end)
        tooltipSkin.nativeSpellTitleHooks = true
    end
    for _, method in ipairs({"SetWidth", "SetHeight", "SetSize"}) do
        hooksecurefunc(tooltip, method, function()
            if tooltipSkin.targetWidth then ApplyContentLayout() end
        end)
    end
    for _, method in ipairs({"SetText", "AddLine", "AddDoubleLine"}) do
        if type(tooltip[method]) == "function" then hooksecurefunc(tooltip, method, StyleText) end
    end
    for _, method in ipairs({"AddLine", "AddDoubleLine"}) do
        if type(tooltip[method]) == "function" then
            hooksecurefunc(tooltip, method, function()
                if tooltipSkin.updateCurrencyTooltip then tooltipSkin.updateCurrencyTooltip() end
                local spellType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Spell
                if tooltipSkin.spellLayoutActive and not tooltipSkin.spellProcessing
                    and spellType and tooltip.IsTooltipType and tooltip:IsTooltipType(spellType)
                    and not Tooltips.IsAuraTooltip(tooltip) then
                    StyleSpellTooltip()
                end
                local skillType = Tooltips.FindDataType("Flyout")
                if tooltipSkin.spellLayoutActive and not tooltipSkin.spellProcessing
                    and StyleSkillTooltip and skillType and tooltip.IsTooltipType and tooltip:IsTooltipType(skillType) then
                    StyleSkillTooltip()
                end
            end)
        end
    end
    -- Comparison lines are appended after the item layout has already run, so lay it out again.
    local tooltipName = tooltip:GetName()
    if type(tooltipName) == "string" and tooltipName:find("ShoppingTooltip") then
        local reflowScheduled = false
        local function QueueReflow()
            if reflowScheduled then return end
            reflowScheduled = true
            C_Timer.After(0, function()
                reflowScheduled = false
                if tooltipSkin then RefreshItemHeader(tooltipSkin) end
            end)
        end
        for _, method in ipairs({"AddLine", "AddDoubleLine"}) do
            if type(tooltip[method]) == "function" then hooksecurefunc(tooltip, method, QueueReflow) end
        end
    end
    addonEnv.FFXIVUITooltipSkin = tooltipSkin
    addonEnv.FFXIVUITooltipSkins = tooltipSkins
    return true
end

local petAbilityHooked = false
local function RoundTooltips()
    if not petAbilityHooked and type(SharedPetBattleAbilityTooltip_SetAbility) == "function" then
        petAbilityHooked = true
        hooksecurefunc("SharedPetBattleAbilityTooltip_SetAbility", function(self)
            local tooltipSkin = tooltipSkins[self]
            if tooltipSkin and tooltipSkin.updatePetAbility then tooltipSkin.updatePetAbility() end
        end)
    end
    for _, name in ipairs({"GameTooltip", "MinimapTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
        "WorldMapTooltip", "EmbeddedItemTooltip", "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2",
        "PetJournalPrimaryAbilityTooltip", "PetJournalSecondaryAbilityTooltip", "FloatingPetBattleAbilityTooltip",
        "PetBattlePrimaryAbilityTooltip", "PetBattlePrimaryUnitTooltip", "BattlePetTooltip",
        "FloatingBattlePetTooltip"}) do
        local tooltip = _G[name]
        if tooltip then addonEnv.RoundTooltip(tooltip) end
    end
end

local tooltipWatcher = CreateFrame("Frame")
local tooltipHandlers = {
    ADDON_LOADED = function()
        RoundTooltips()
    end,
    PLAYER_LOGIN = RoundTooltips,
    ITEM_DATA_LOAD_RESULT = function(itemID, success)
        if issecretvalue and (issecretvalue(itemID) or issecretvalue(success)) then return end
        if not success then return end
        for _, tooltipSkin in pairs(tooltipSkins) do
            if tooltipSkin.pendingItemID == itemID then RefreshItemHeader(tooltipSkin) end
        end
    end,
    SPELL_DATA_LOAD_RESULT = function(spellID, success)
        if issecretvalue and (issecretvalue(spellID) or issecretvalue(success)) then return end
        if not success then return end
        for _, tooltipSkin in pairs(tooltipSkins) do
            if tooltipSkin.pendingSpellID == spellID and tooltipSkin.updateSpellTooltip
                and tooltipSkin.tooltip and tooltipSkin.tooltip:IsShown() then
                tooltipSkin.updateSpellTooltip()
            end
        end
    end,
}
local itemTooltipType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
local auraTooltipType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.UnitAura
local minimapMouseoverType = Tooltips.FindDataType("MinimapMouseover")
if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and minimapMouseoverType then
    TooltipDataProcessor.AddTooltipPostCall(minimapMouseoverType, function(tooltip)
        local tooltipSkin = tooltipSkins[tooltip]
        if tooltipSkin and tooltipSkin.updateMinimapMouseoverLayout then
            tooltipSkin.updateMinimapMouseoverLayout()
        end
    end)
end
if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and auraTooltipType then
    TooltipDataProcessor.AddTooltipPostCall(auraTooltipType, function(tooltip)
        local tooltipSkin = tooltipSkins[tooltip]
        if tooltipSkin and tooltipSkin.updateAuraTooltip then tooltipSkin.updateAuraTooltip() end
    end)
end
local currencyTooltipType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Currency
if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and currencyTooltipType then
    TooltipDataProcessor.AddTooltipPostCall(currencyTooltipType, function(tooltip)
        local tooltipSkin = tooltipSkins[tooltip]
        if tooltipSkin and tooltipSkin.updateCurrencyTooltip then
            tooltipSkin.updateCurrencyTooltip()
        end
    end)
end
if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and itemTooltipType then
    TooltipDataProcessor.AddTooltipPostCall(itemTooltipType, function(tooltip)
        local tooltipSkin = tooltipSkins[tooltip]
        if tooltipSkin then RefreshItemHeader(tooltipSkin) end
    end)
end
local spellTooltipType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Spell
if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPreCall) == "function"
    and spellTooltipType then
    TooltipDataProcessor.AddTooltipPreCall(spellTooltipType, function(tooltip)
        local tooltipSkin = tooltipSkins[tooltip]
        if not tooltipSkin then return end
        if Tooltips.IsAuraTooltip(tooltip) then return end
        tooltipSkin.spellProcessing = true
        local title = tooltip.TextLeft1
        if title then title:SetAlpha(0) end
    end)
end
if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and spellTooltipType then
    TooltipDataProcessor.AddTooltipPostCall(spellTooltipType, function(tooltip)
        local tooltipSkin = tooltipSkins[tooltip]
        if tooltipSkin and tooltipSkin.updateSpellTooltip then
            tooltipSkin.updateSpellTooltip()
        end
    end)
end
local mountTooltipType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Mount
local toyTooltipType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Toy
local skillTooltipType = Tooltips.FindDataType("Flyout")
local petTooltipType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.CompanionPet
if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPreCall) == "function"
    and skillTooltipType then
    TooltipDataProcessor.AddTooltipPreCall(skillTooltipType, function(tooltip)
        local tooltipSkin = tooltipSkins[tooltip]
        if tooltipSkin then tooltipSkin.spellProcessing = true end
    end)
end
if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and petTooltipType then
    TooltipDataProcessor.AddTooltipPostCall(petTooltipType, function(tooltip)
        local tooltipSkin = tooltipSkins[tooltip]
        if tooltipSkin and tooltipSkin.updatePetTooltip then
            tooltipSkin.updatePetTooltip()
        end
    end)
end
if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and skillTooltipType then
    TooltipDataProcessor.AddTooltipPostCall(skillTooltipType, function(tooltip)
        local tooltipSkin = tooltipSkins[tooltip]
        if tooltipSkin and tooltipSkin.updateSkillTooltip then
            tooltipSkin.updateSkillTooltip()
        end
    end)
end
if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and toyTooltipType then
    TooltipDataProcessor.AddTooltipPostCall(toyTooltipType, function(tooltip)
        local tooltipSkin = tooltipSkins[tooltip]
        if tooltipSkin and tooltipSkin.updateToyTooltip then
            tooltipSkin.updateToyTooltip()
        end
    end)
end
if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and mountTooltipType then
    TooltipDataProcessor.AddTooltipPostCall(mountTooltipType, function(tooltip)
        local tooltipSkin = tooltipSkins[tooltip]
        if tooltipSkin and tooltipSkin.updateMountTooltip then
            tooltipSkin.updateMountTooltip()
        end
    end)
end
for event in pairs(tooltipHandlers) do tooltipWatcher:RegisterEvent(event) end
tooltipWatcher:SetScript("OnEvent", function(_, event, ...)
    local handler = tooltipHandlers[event]
    if handler then handler(...) end
end)

if SlashCmdList then
    SLASH_FFXIVTOOLTIPDIAG1 = "/ffxivtooltipdiag"
    SlashCmdList.FFXIVTOOLTIPDIAG = function()
        print("FFXIVUI: show the comparison tooltips now; diagnosing in 4 seconds.")
        C_Timer.After(4, function()
            local function Show(value)
                if issecretvalue and issecretvalue(value) then return "<secret>" end
                return type(value) == "string" and string.format("%q", value) or tostring(value)
            end
            for _, name in ipairs({"ShoppingTooltip1", "ShoppingTooltip2", "GameTooltip"}) do
                local tooltip, skin = _G[name], tooltipSkins[_G[name]]
                if tooltip and skin and tooltip:IsShown() then
                    local link
                    if type(tooltip.GetItem) == "function" then _, link = tooltip:GetItem() end
                    local data = tooltip.GetTooltipData and tooltip:GetTooltipData()
                    print("FFXIVUI diag", name, "GetItem", Show(link), "hyperlink", Show(data and data.hyperlink),
                        "dataType", Show(data and data.type), "diagnostic", Show(tooltip.FFXIVUILayoutDiagnostic),
                        "equipmentWidth", Show(skin.equipmentWidth), "hasUpdate", tostring(skin.updateItemHeader ~= nil))
                    local ok, err = pcall(skin.updateItemHeader)
                    print("FFXIVUI diag rerun", name, "ok", tostring(ok), Show(err),
                        "diagnostic", Show(tooltip.FFXIVUILayoutDiagnostic),
                        "equipmentWidth", Show(skin.equipmentWidth))
                end
            end
        end)
    end
end

if SlashCmdList then
    SLASH_FFXIVTOOLTIPFRAMES1 = "/ffxivtooltipframes"
    SlashCmdList.FFXIVTOOLTIPFRAMES = function()
        print("FFXIVUI: show the tooltip now; listing visible tooltip frames in 4 seconds.")
        C_Timer.After(4, function()
            local frame = EnumerateFrames()
            while frame do
                local name = frame.GetName and frame:GetName()
                if issecretvalue and issecretvalue(name) then name = nil end
                local shown = frame:IsShown()
                if not (issecretvalue and issecretvalue(shown)) and shown
                    and (frame.TextLeft1 or (type(name) == "string" and name:find("Tooltip", 1, true))) then
                    local parent = frame:GetParent()
                    print("FFXIVUI tooltipframe", tostring(name), "type", frame:GetObjectType(),
                        "parent", tostring(parent and parent.GetName and parent:GetName()),
                        "skinned", tostring(tooltipSkins[frame] ~= nil),
                        "nine", tostring(frame.NineSlice ~= nil), "text1", tostring(frame.TextLeft1 ~= nil),
                        string.format("%.0fx%.0f", frame:GetSize()))
                end
                frame = EnumerateFrames(frame)
            end
        end)
    end
end

if SlashCmdList then
    SLASH_FFXIVFRAMEDUMP1 = "/ffxivframedump"
    SlashCmdList.FFXIVFRAMEDUMP = function(frameName)
        local function Dump(frame)
            local function Say(...) print("FFXIVUI", ...) end
            local keys = {}
            for key, value in pairs(frame) do
                if type(value) == "table" and type(value.GetObjectType) == "function" then keys[value] = key end
            end
            local function Show(value)
                if issecretvalue and issecretvalue(value) then return "<secret>" end
                return type(value) == "string" and string.format("%q", value) or tostring(value)
            end
            local function Describe(object, indent)
                local kind = object:GetObjectType()
                local line = {indent .. kind, "key", tostring(keys[object] or object.FFXIVUIKey or "-"),
                    "name", tostring(object.GetName and object:GetName() or "-")}
                if kind == "FontString" then
                    line[#line + 1] = "text " .. Show(object:GetText())
                    local stringHeight = object.GetStringHeight and object:GetStringHeight()
                    if type(stringHeight) == "number" and not (issecretvalue and issecretvalue(stringHeight)) then
                        line[#line + 1] = string.format("strH %.1f", stringHeight)
                    end
                elseif kind == "Texture" then
                    line[#line + 1] = "atlas " .. Show(object.GetAtlas and object:GetAtlas())
                    line[#line + 1] = "tex " .. Show(object:GetTexture())
                end
                if object.GetPoint then
                    local point, relativeTo, relativePoint, x, y = object:GetPoint(1)
                    line[#line + 1] = string.format("%s>%s:%s(%.0f,%.0f)", tostring(point),
                        tostring(relativeTo and relativeTo.GetName and relativeTo:GetName() or relativeTo and "obj" or "-"),
                        tostring(relativePoint), x or 0, y or 0)
                end
                if object.GetWidth then line[#line + 1] = string.format("%.0fx%.0f", object:GetWidth(), object:GetHeight()) end
                line[#line + 1] = "shown " .. tostring(object:IsShown()) .. " alpha " .. string.format("%.2f", object:GetAlpha())
                if object.GetDrawLayer then line[#line + 1] = "layer " .. tostring(object:GetDrawLayer()) end
                if object.GetFrameLevel then line[#line + 1] = "level " .. object:GetFrameLevel() end
                Say(table.concat(line, " "))
            end
            local function Walk(object, indent, depth)
                Describe(object, indent)
                if object.GetRegions then
                    for _, region in ipairs({object:GetRegions()}) do Describe(region, indent .. "  ") end
                end
                if depth > 0 and object.GetChildren then
                    for _, child in ipairs({object:GetChildren()}) do Walk(child, indent .. "  ", depth - 1) end
                end
            end
            Walk(frame, "", 2)
        end
        local name = (frameName or ""):match("^%s*(.-)%s*$")
        if name ~= "" then
            local frame = _G[name]
            if not frame then return print("FFXIVUI: no frame named " .. name) end
            print("FFXIVUI: show " .. name .. " now; dumping in 4 seconds.")
            return C_Timer.After(4, function() Dump(frame) end)
        end
        print("FFXIVUI: hover the tooltip now; inspecting in 4 seconds.")
        C_Timer.After(4, function()
            local foci = GetMouseFoci and GetMouseFoci() or {}
            local frame = foci[1]
            while frame and not (frame.GetName and frame:GetName() and frame:GetName():find("Tooltip")) do
                frame = frame:GetParent()
            end
            if not frame then return print("FFXIVUI: no tooltip frame under the mouse") end
            Dump(frame)
        end)
    end
end

if SlashCmdList then
    SLASH_FFXIVTOOLTIPDEBUG1 = "/ffxivtooltipdebug"
    SlashCmdList.FFXIVTOOLTIPDEBUG = function()
        print("FFXIVUI: hover the tooltip now; inspecting all active tooltips in 4 seconds.")
        C_Timer.After(4, function()
            local function Show(value)
                if issecretvalue and issecretvalue(value) then return "<secret>" end
                return type(value) == "string" and string.format("%q", value) or tostring(value)
            end
            local foci = GetMouseFoci and GetMouseFoci() or {}
            print("FFXIVUI --- Mouse Foci ---")
            for i, focus in ipairs(foci) do
                local name = focus.GetName and focus:GetName() or "-"
                local parent = focus.GetParent and focus:GetParent()
                local parentName = parent and parent.GetName and parent:GetName() or "-"
                print(string.format("Focus %d: name=%s type=%s parent=%s", i, tostring(name), focus:GetObjectType(), tostring(parentName)))
            end

            print("FFXIVUI --- Tooltip Inspection ---")
            local tooltipNames = {"GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "WorldMapTooltip", "EmbeddedItemTooltip", "PetJournalPrimaryAbilityTooltip"}
            for _, name in ipairs(tooltipNames) do
                local tooltip = _G[name]
                if tooltip and tooltip:IsShown() then
                    local data = tooltip.GetTooltipData and tooltip:GetTooltipData()
                    local info = tooltip.GetPrimaryTooltipInfo and tooltip:GetPrimaryTooltipInfo()
                    local getter = info and info.getterName
                    local isAura = Tooltips.IsAuraTooltip(tooltip)
                    local skin = tooltipSkins[tooltip]
                    local title = tooltip.TextLeft1 and tooltip.TextLeft1:GetText() or "-"
                    print(string.format("Tooltip: %s | Shown: true | Type: %s | Getter: %s | IsAura: %s | Skinned: %s | AuraActive: %s | Title: %s",
                        name, Show(data and data.type), Show(getter), tostring(isAura), tostring(skin ~= nil), tostring(skin and skin.auraLayoutActive), Show(title)))
                    if data and data.lines then
                        print(string.format("  -> Data lines count: %d", #data.lines))
                    end
                end
            end
        end)
    end
end

local auraTooltip
local function GetAuraTooltip()
    if auraTooltip then return auraTooltip end
    auraTooltip = CreateFrame("Frame", "FFXIV_UI_AuraTooltip", UIParent, "BackdropTemplate")
    auraTooltip:SetFrameStrata("TOOLTIP")
    auraTooltip:SetSize(280, 80)
    auraTooltip:Hide()
    addonEnv.RoundTooltip(auraTooltip)

    auraTooltip.title = auraTooltip:CreateFontString(nil, "OVERLAY", "FFXIV_AuraTooltipTitleTemplate")
    Tooltips.StyleFont(auraTooltip.title, 12, "text")
    auraTooltip.title:SetTextColor(0.88, 0.79, 0.57, 1)

    auraTooltip.duration = auraTooltip:CreateFontString(nil, "OVERLAY", "FFXIV_AuraTooltipDurationTemplate")
    Tooltips.StyleFont(auraTooltip.duration, 10, "text")
    auraTooltip.duration:SetTextColor(0.67, 0.69, 0.69, 1)
    auraTooltip.duration:SetPoint("TOPLEFT", auraTooltip.title, "BOTTOMLEFT", 0, -4)

    auraTooltip.description = auraTooltip:CreateFontString(nil, "OVERLAY", "FFXIV_AuraTooltipDescriptionTemplate")
    Tooltips.StyleFont(auraTooltip.description, 11, "text")
    auraTooltip.description:SetTextColor(0.94, 0.94, 0.94, 1)
    auraTooltip.description:SetPoint("TOPLEFT", auraTooltip.duration, "BOTTOMLEFT", 0, -6)
    auraTooltip.description:SetWordWrap(true)

    return auraTooltip
end

function Tooltips.ShowAuraTooltip(owner, unit, auraInstanceID)
    local tooltip = GetAuraTooltip()
    local aura = C_UnitAuras and type(C_UnitAuras.GetAuraDataByAuraInstanceID) == "function"
        and C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID) or nil
    if not aura then
        tooltip:Hide()
        return
    end

    local name = aura.name or ""
    local spellId = aura.spellId
    local desc = ""
    if spellId and C_Spell and type(C_Spell.GetSpellDescription) == "function" then
        desc = C_Spell.GetSpellDescription(spellId) or ""
    end

    tooltip.title:SetText(name)
    local durationText = ""
    if aura.duration and aura.duration > 0 and aura.expirationTime then
        local rem = aura.expirationTime - (GetTime and GetTime() or 0)
        if rem > 0 then
            durationText = Tooltips.FormatDuration(rem) .. " remaining"
        end
    end
    tooltip.duration:SetText(durationText)
    tooltip.duration:SetShown(durationText ~= "")

    tooltip.description:SetText(desc)
    tooltip.description:SetShown(desc ~= "")

    local height = 24 + (tooltip.title:IsShown() and tooltip.title:GetStringHeight() or 0)
        + (tooltip.duration:IsShown() and (tooltip.duration:GetStringHeight() + 4) or 0)
        + (tooltip.description:IsShown() and (tooltip.description:GetStringHeight() + 6) or 0)
    tooltip:SetHeight(math.max(40, height + 12))

    tooltip:ClearAllPoints()
    tooltip:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", 4, 4)
    tooltip:Show()
end

function Tooltips.HideAuraTooltip()
    if auraTooltip then auraTooltip:Hide() end
end