local addonName, ns = ...
local addonEnv = ns
local Tooltips = ns.Tooltips
local L = Tooltips.L

function Tooltips.InitializeItems(tooltipSkin, layout)
    local tooltip = tooltipSkin.tooltip
    local RestoreItemHeader = layout.RestoreItemHeader
    local GuardEquipmentAlpha = layout.GuardEquipmentAlpha
    local ConsumableRegion = layout.Region
    local TraitUnderline = layout.TraitUnderline
    local HideEquipmentNative = layout.HideEquipmentNative
    local HideNativeMoneyFrames = layout.HideNativeMoneyFrames
    local HideNativeSellPrices = layout.HideNativeSellPrices
    -- Reads the native row text, since the price itself can be secret.
    local function SellRowIsZero(region)
        local text = region and region:GetText()
        if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return false end
        text = text:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        return text:match(":%s*0%s*$") ~= nil
    end

    local function StyleCurrencyTooltip()
        local currencyType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Currency
        local data = tooltip.GetTooltipData and tooltip:GetTooltipData()
        if not currencyType or not data or (issecretvalue and issecretvalue(data.type))
            or data.type ~= currencyType then return end
        RestoreItemHeader()
        if not C_CurrencyInfo or type(C_CurrencyInfo.GetCurrencyInfo) ~= "function"
            or type(data.id) ~= "number" or (issecretvalue and issecretvalue(data.id)) then return end
        local info = C_CurrencyInfo.GetCurrencyInfo(data.id)
        if not info or (issecretvalue and issecretvalue(info.iconFileID)) or not info.iconFileID then return end
        local title = tooltip.TextLeft1
        local tooltipName = tooltip:GetName()
        if not title or type(tooltipName) ~= "string" or not data.lines then return end
        if not tooltipSkin.originalTitlePoint then
            tooltipSkin.originalTitlePoint = {title:GetPoint(1)}
            tooltipSkin.originalTitleSize = {title:GetSize()}
            tooltipSkin.originalTitleWrap = title:CanWordWrap()
        end
        tooltipSkin.itemTitle = title
        tooltipSkin.originalWidth = tooltip:GetWidth()
        tooltipSkin.targetWidth = math.max(320, tooltipSkin.originalWidth)
        tooltip:SetWidth(tooltipSkin.targetWidth)
        if not tooltipSkin.itemIcon then
            tooltipSkin.itemIcon = tooltip:CreateTexture(nil, "ARTWORK", "FFXIV_TooltipIconTemplate")
        end
        tooltipSkin.itemIcon:SetTexture(info.iconFileID)
        tooltipSkin.itemIcon:Show()
        title:ClearAllPoints()
        title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 56, -10)
        title:SetWidth(tooltip:GetWidth() - 72)
        title:SetWordWrap(true)
        local titleHeight = title:GetStringHeight()
        if (issecretvalue and issecretvalue(titleHeight)) or type(titleHeight) ~= "number" then
            titleHeight = 32
        end
        local headerHeight = math.max(32, titleHeight)
        title:SetHeight(headerHeight)
        title:SetJustifyV("MIDDLE")
        tooltipSkin.contentLayout = {{region = title, x = 56, y = -10,
            height = headerHeight, wordWrap = true}}
        tooltipSkin.consumableText = {}
        tooltipSkin.consumableRows = {[title] = true}
        for _, owned in pairs(tooltipSkin.rowMirrors or {}) do owned:Hide() end
        local cursor = -headerHeight - 22
        local lineCount = tooltip.NumLines and tooltip:NumLines()
        if (issecretvalue and issecretvalue(lineCount)) or type(lineCount) ~= "number" then
            lineCount = #data.lines
        end
        for lineIndex = 2, lineCount do
            local left = _G[tooltipName .. "TextLeft" .. lineIndex]
            local right = _G[tooltipName .. "TextRight" .. lineIndex]
            if left then Tooltips.SaveNativeRegion(tooltipSkin.consumableText, left) end
            if right then Tooltips.SaveNativeRegion(tooltipSkin.consumableText, right) end
            cursor = Tooltips.PlaceNativeLine(tooltipSkin, tooltipSkin.consumableText, left, right, cursor)
        end
        tooltipSkin.consumableHeight = tooltip:GetHeight()
        tooltipSkin.targetHeight = -cursor + 14
        tooltip:SetHeight(tooltipSkin.targetHeight)
    end
    tooltipSkin.updateCurrencyTooltip = StyleCurrencyTooltip

    local function StyleItemHeader(skipCompareWait)
        local itemType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
        if itemType and tooltip.IsTooltipType and not tooltip:IsTooltipType(itemType) then return end
        local data = tooltip.GetTooltipData and tooltip:GetTooltipData()
        if data and (issecretvalue and issecretvalue(data.type)) then return end
        local tooltipName = tooltip:GetName()
        local isShopping = type(tooltipName) == "string" and tooltipName:find("ShoppingTooltip")
        -- Wait one frame for comparison lines; identical items and "Equipped With" tooltips never get any.
        if isShopping and skipCompareWait ~= true then
            local numLines = type(tooltip.NumLines) == "function" and tooltip:NumLines() or 0
            local dataLinesCount = (data and data.lines and #data.lines) or 0
            local hasCompareLines = false
            for i = dataLinesCount + 1, numLines do
                local left = _G[tooltipName .. "TextLeft" .. i]
                if left and left:GetText() and left:GetText() ~= "" then
                    hasCompareLines = true
                    break
                end
            end
            if not hasCompareLines and numLines <= dataLinesCount + 2 then
                C_Timer.After(0, function()
                    if tooltip:IsShown() then StyleItemHeader(true) end
                end)
                return
            end
        end
        if itemType and data and data.type ~= nil and data.type ~= itemType then return end
        local spellType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Spell
        if spellType and tooltip.IsTooltipType and tooltip:IsTooltipType(spellType) then return end
        local mountType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Mount
        if mountType and tooltip.IsTooltipType and tooltip:IsTooltipType(mountType) then return end
        local toyType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Toy
        if toyType and tooltip.IsTooltipType and tooltip:IsTooltipType(toyType) then return end
        local skillType = Tooltips.FindDataType("Flyout")
        if skillType and tooltip.IsTooltipType and tooltip:IsTooltipType(skillType) then return end
        local petType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.CompanionPet
        if petType and tooltip.IsTooltipType and tooltip:IsTooltipType(petType) then return end
        RestoreItemHeader()
        tooltipSkin.spellProcessing = false
        tooltipSkin.spellLayoutActive = false
        if not C_Item or type(C_Item.GetItemInfo) ~= "function" then return end
        local itemLink
        if type(tooltip.GetItem) == "function" then _, itemLink = tooltip:GetItem() end
        if (type(itemLink) ~= "string" or (issecretvalue and issecretvalue(itemLink)))
            and type(tooltip.GetTooltipData) == "function" then
            -- Comparison tooltips carry the item only in their tooltip data.
            local info = tooltip:GetTooltipData()
            if info and type(info.hyperlink) == "string" then
                itemLink = info.hyperlink
            elseif info and type(info.id) == "number" and not (issecretvalue and issecretvalue(info.id)) then
                itemLink = "item:" .. info.id
            end
        end
        if issecretvalue and issecretvalue(itemLink) then return end
        if type(itemLink) ~= "string" then return end
        local _, _, _, _, _, itemType, itemSubType, maxStack, equipLocation, icon, sellPrice, itemClass,
            _, _, _, _, _, itemDescription = C_Item.GetItemInfo(itemLink)
        if issecretvalue and issecretvalue(icon) then return end
        if not icon then
            local itemID = tonumber(itemLink:match("item:(%d+)"))
            if itemID and type(C_Item.RequestLoadItemDataByID) == "function" then
                tooltipSkin.pendingItemID = itemID
                C_Item.RequestLoadItemDataByID(itemID)
            end
            return
        end
        local title = tooltip.TextLeft1
        if not title then return end
        if not tooltipSkin.itemIcon then
            tooltipSkin.itemIcon = tooltip:CreateTexture(nil, "ARTWORK", "FFXIV_TooltipIconTemplate")
        end
        if not tooltipSkin.originalTitlePoint and type(title.GetPoint) == "function" then
            tooltipSkin.originalTitlePoint = {title:GetPoint(1)}
            tooltipSkin.originalTitleSize = {title:GetSize()}
            tooltipSkin.originalTitleWrap = title:CanWordWrap()
        end
        tooltipSkin.itemTitle = title
        title:ClearAllPoints()
        title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 56, -10)
        title:SetWidth(math.max(1, tooltip:GetWidth() - 72))
        title:SetWordWrap(true)
        title:SetHeight(32)
        title:SetJustifyV("MIDDLE")
        if type(title.SetMaxLines) == "function" then title:SetMaxLines(0) end
        tooltipSkin.contentLayout = {{region = title, x = 56, y = -10, height = 32, wordWrap = true}}
        tooltipSkin.originalWidth = tooltip:GetWidth()
        tooltipSkin.targetWidth = math.max(320, tooltipSkin.originalWidth)
        tooltip:SetWidth(tooltipSkin.targetWidth)
        tooltipSkin.itemIcon:SetTexture(icon)
        tooltipSkin.itemIcon:Show()
        tooltipSkin.pendingItemID = nil

        local function DiagnosticValue(value)
            if issecretvalue and issecretvalue(value) then return "<secret>" end
            if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
                return tostring(value)
            end
            return type(value)
        end
        local function Diagnose(reason)
            tooltip.FFXIVUILayoutDiagnostic = reason
                .. "; class=" .. DiagnosticValue(itemClass)
                .. "; equip=" .. DiagnosticValue(equipLocation)
        end
        Diagnose("Checking structured layout")
        local consumableClass = Enum and Enum.ItemClass and Enum.ItemClass.Consumable
        if issecretvalue and (issecretvalue(itemClass) or issecretvalue(equipLocation)) then
            Diagnose("Restricted item classification")
            return
        end
        local useSpellID
        if type(C_Item.GetItemSpell) == "function" then
            local _, spellID = C_Item.GetItemSpell(itemLink)
            if not (issecretvalue and issecretvalue(spellID)) and type(spellID) == "number" then
                useSpellID = spellID
            end
        end
        local isConsumable = consumableClass ~= nil and itemClass == consumableClass
        if type(tooltip.GetTooltipData) ~= "function" then
            Diagnose("GetTooltipData unavailable")
            return
        end
        local data = tooltip:GetTooltipData()
        local lineTypes = Enum.TooltipDataLineType
        if not data or not data.lines or not lineTypes then
            Diagnose("Tooltip data, lines, or enums unavailable")
            return
        end
        local tooltipName = tooltip:GetName()
        if type(tooltipName) ~= "string" then
            Diagnose("Unnamed tooltip")
            return
        end
        local bindingTexts, bindingSeen = {}, {}
        tooltipSkin.bindingSources = {}
        for index, line in ipairs(data.lines) do
            local lineIndex = line.lineIndex
            if not (issecretvalue and (issecretvalue(lineIndex) or issecretvalue(line.type))) then
                local region = _G[tooltipName .. "TextLeft" .. (lineIndex or index)]
                local text = region and region:GetText()
                if not (issecretvalue and issecretvalue(text)) and type(text) == "string" and text ~= "" then
                    local isBinding = lineTypes.ItemBinding ~= nil and line.type == lineTypes.ItemBinding
                    for _, name in ipairs({"ITEM_SOULBOUND", "ITEM_ACCOUNTBOUND", "ITEM_BNETACCOUNTBOUND",
                        "ITEM_BIND_ON_PICKUP", "ITEM_BIND_ON_EQUIP", "ITEM_BIND_ON_USE",
                        "ITEM_ACCOUNTBOUND_UNTIL_EQUIP"}) do
                        if type(_G[name]) == "string" and text == _G[name] then isBinding = true end
                    end
                    local clean = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                    if (lineTypes.UniqueEquipped ~= nil and line.type == lineTypes.UniqueEquipped)
                        or (type(ITEM_UNIQUE) == "string" and (clean == ITEM_UNIQUE
                            or (clean:sub(1, #ITEM_UNIQUE) == ITEM_UNIQUE and clean:find("%(%d+%)%s*$")))) then
                        isBinding = true
                    end
                    if isBinding then
                        tooltipSkin.bindingSources[region] = region:GetAlpha()
                        GuardEquipmentAlpha(region)
                        region:SetAlpha(0)
                        if not bindingSeen[text] then
                            bindingTexts[#bindingTexts + 1] = text
                            bindingSeen[text] = true
                        end
                    end
                end
            end
        end
        -- The header always reserves the binding row, so the name, icon and body line up whether or not a binding line exists.
        local headerOffset = -8
        if #bindingTexts > 0 then
            local label = ConsumableRegion("bindingLabel", 10, "muted")
            label.FFXIVUITooltipFontSize = 10
            label:SetText(table.concat(bindingTexts, "      "))
            label:ClearAllPoints()
            label:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 56, -5)
            label:SetWidth(math.max(1, tooltip:GetWidth() - 72))
            label:SetHeight(12)
            label:SetJustifyH("CENTER")
            label:SetWordWrap(false)
            label:Show()
        end
        title:ClearAllPoints()
        title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 56, -19)
        title:SetHeight(32)
        tooltipSkin.itemIcon:ClearAllPoints()
        tooltipSkin.itemIcon:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, -19)
        tooltipSkin.contentLayout[1].y = -19
        tooltipSkin.contentLayout[1].height = 32
        local function IsUseLine(line, index)
            if issecretvalue and issecretvalue(line.type) then return false end
            if (lineTypes.ItemSpellTriggerOnUse ~= nil and line.type == lineTypes.ItemSpellTriggerOnUse)
                or (lineTypes.SpellDescription ~= nil and line.type == lineTypes.SpellDescription) then
                return true
            end
            local lineIndex = line.lineIndex
            if issecretvalue and issecretvalue(lineIndex) then return false end
            local region = _G[tooltipName .. "TextLeft" .. (lineIndex or index)]
            local text = line.leftText
            if issecretvalue and issecretvalue(text) then return false end
            if text == nil and region then text = region:GetText() end
            if issecretvalue and issecretvalue(text) then return false end
            if type(text) ~= "string" or type(ITEM_SPELL_TRIGGER_ONUSE) ~= "string" then return false end
            local prefix = ITEM_SPELL_TRIGGER_ONUSE:gsub("%%s", "")
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            return prefix ~= "" and text:sub(1, #prefix) == prefix
        end
        local isEquipment = type(equipLocation) == "string" and equipLocation ~= ""
            and equipLocation ~= "INVTYPE_NON_EQUIP" and equipLocation ~= "INVTYPE_NON_EQUIP_IGNORE"
        if isEquipment then
            local groups = {metrics = {}, level = {}, requirements = {}, bonuses = {}, effects = {}, footer = {}, compare = {}}
            local saved, rows = {}, {}
            tooltipSkin.consumableText = saved
            tooltipSkin.consumableRows = rows
            tooltipSkin.equipmentRegions = tooltipSkin.equipmentRegions or {}
            tooltipSkin.equipmentSocketIcons = tooltipSkin.equipmentSocketIcons or {}
            tooltipSkin.equipmentDividers = tooltipSkin.equipmentDividers or {}
            tooltipSkin.equipmentBands = tooltipSkin.equipmentBands or {}
            local usedBands = 0
            tooltipSkin.equipmentBars = tooltipSkin.equipmentBars or {}
            tooltipSkin.equipmentMoneyFrames = {}
            local renderedRegions = {}
            tooltipSkin.equipmentRenderedRegions = renderedRegions
            tooltipSkin.equipmentWidth = tooltip:GetWidth()
            tooltipSkin.equipmentLineCount = #data.lines + 4
            local used, usedDividers, cursor = 0, 0, -48 + headerOffset
            local seenIndices, seenFooter, hasSellPrice = {}, {}, false
            local damageMetric, dpsMetric, speedMetric
            local function ReadText(region)
                if not region then return end
                local text = region:GetText()
                if issecretvalue and issecretvalue(text) then return end
                if type(text) == "string" and text ~= "" then return text end
            end
            local function FormatSuffix(text, template)
                if type(template) ~= "string" then return end
                local suffix = template:match(".*%%[sd](.+)$")
                return suffix and text:sub(-#suffix) == suffix and suffix or nil
            end
            local function FormatValue(text, template)
                if type(template) ~= "string" then return end
                local prefix, suffix = template:match("^(.-)%%[%d%.]*[sdfg](.*)$")
                if not prefix or text:sub(1, #prefix) ~= prefix then return end
                if suffix ~= "" and text:sub(-#suffix) ~= suffix then return end
                return text:sub(#prefix + 1, #text - #suffix)
            end
            local slotText, slotColor
            -- Blizzard colors an unusable equipment type red; returns that color or nil.
            local function NativeRedColor(region)
                if not region or type(region.GetTextColor) ~= "function" then return end
                local red, green, blue = region:GetTextColor()
                if issecretvalue and (issecretvalue(red) or issecretvalue(green) or issecretvalue(blue)) then return end
                if type(red) == "number" and type(green) == "number" and type(blue) == "number"
                    and red >= 0.9 and green < 0.4 and blue < 0.4 then
                    return {red, green, blue}
                end
            end
            local inCompare = false
            -- Native gem icons are textures anchored to a tooltip text line; keep their art and hide the native placement.
            local socketIcons = {}
            for _, region in ipairs({tooltip:GetRegions()}) do
                local texture = region:GetObjectType() == "Texture" and region:GetTexture()
                local _, anchor = region:GetPoint(1)
                if texture and not (issecretvalue and issecretvalue(texture)) and type(anchor) == "table"
                    and type(anchor.GetObjectType) == "function" and anchor:GetObjectType() == "FontString" then
                    socketIcons[anchor] = {texture = texture, region = region}
                    -- A re-render sees our own alpha 0, so the original alpha is remembered on first sight.
                    tooltipSkin.socketNativeAlphas = tooltipSkin.socketNativeAlphas or {}
                    if tooltipSkin.socketNativeAlphas[region] == nil then
                        tooltipSkin.socketNativeAlphas[region] = region:GetAlpha()
                    end
                    Tooltips.SaveNativeRegion(saved, region, tooltipSkin.socketNativeAlphas[region])
                    GuardEquipmentAlpha(region)
                    region:SetAlpha(0)
                end
            end
            for index, line in ipairs(data.lines) do
                local lineIndex = line.lineIndex
                if not (issecretvalue and (issecretvalue(lineIndex) or issecretvalue(line.type))) then
                    lineIndex = lineIndex or index
                    local left = _G[tooltipName .. "TextLeft" .. lineIndex]
                    local right = _G[tooltipName .. "TextRight" .. lineIndex]
                    if lineTypes.SellPrice and line.type == lineTypes.SellPrice then
                        hasSellPrice = true
                        for _, region in pairs({left = left, right = right}) do
                            if region then
                                Tooltips.SaveNativeRegion(saved, region)
                                GuardEquipmentAlpha(region)
                                region:SetAlpha(0)
                            end
                        end
                    elseif line.type ~= lineTypes.ItemName and not seenIndices[lineIndex]
                        and not tooltipSkin.bindingSources[left] then
                        seenIndices[lineIndex] = true
                        local entry = {left = left, right = right, text = ReadText(left), rightText = ReadText(right)}
                        local socketIcon = left and socketIcons[left]
                        entry.socketTexture = socketIcon and socketIcon.texture
                        for _, region in pairs({left = left, right = right}) do
                            Tooltips.SaveNativeRegion(saved, region)
                            region:SetAlpha(0)
                        end
                        if type(ITEM_DELTA_DESCRIPTION) == "string" and entry.text
                            and (entry.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) == ITEM_DELTA_DESCRIPTION then
                            inCompare = true
                        end
                        if inCompare then
                            groups.compare[#groups.compare + 1] = entry
                        elseif lineTypes.EquipSlot and line.type == lineTypes.EquipSlot then
                            slotText = entry.text
                            slotColor = NativeRedColor(left)
                            if entry.rightText then
                                -- The armor type sits on the right side of the native line; only that segment turns red.
                                local rightDisplay = entry.rightText
                                local typeColor = NativeRedColor(right)
                                if typeColor then
                                    rightDisplay = string.format("|cff%02x%02x%02x%s|r",
                                        math.floor(typeColor[1] * 255 + 0.5), math.floor(typeColor[2] * 255 + 0.5),
                                        math.floor(typeColor[3] * 255 + 0.5), rightDisplay)
                                end
                                slotText = slotText and slotText .. " - " .. rightDisplay or rightDisplay
                            end
                        elseif lineTypes.ItemLevel and line.type == lineTypes.ItemLevel then
                            groups.level[#groups.level + 1] = entry
                        elseif (lineTypes.ItemBinding and line.type == lineTypes.ItemBinding)
                            or (lineTypes.UsageRequirement and line.type == lineTypes.UsageRequirement) then
                            groups.requirements[#groups.requirements + 1] = entry
                        elseif IsUseLine(line, index)
                            or (lineTypes.ItemSpellTriggerOnEquip and line.type == lineTypes.ItemSpellTriggerOnEquip)
                            or (lineTypes.ItemSpellTriggerOnProc and line.type == lineTypes.ItemSpellTriggerOnProc) then
                            groups.effects[#groups.effects + 1] = entry
                        elseif entry.text and (FormatSuffix(entry.text, ARMOR_TEMPLATE)
                            or FormatSuffix(entry.text, DAMAGE_TEMPLATE)) then
                            local armorSuffix = FormatSuffix(entry.text, ARMOR_TEMPLATE)
                            local suffix = armorSuffix or FormatSuffix(entry.text, DAMAGE_TEMPLATE)
                            local metric = {
                                text = entry.text:sub(1, #entry.text - #suffix),
                                left = entry.left, label = armorSuffix and L["Defense"] or L["Damage"],
                            }
                            groups.metrics[#groups.metrics + 1] = metric
                            if not armorSuffix then damageMetric = metric end
                            if entry.rightText then
                                speedMetric = {
                                    text = entry.rightText:match("(%d+[.,]%d+)%s*$")
                                        or entry.rightText:match("(%d+)%s*$") or entry.rightText,
                                    left = entry.right, label = L["Speed"],
                                }
                            end
                        elseif entry.text and FormatValue(entry.text, DPS_TEMPLATE) then
                            dpsMetric = {text = FormatValue(entry.text, DPS_TEMPLATE), left = entry.left, label = L["DPS"]}
                        elseif entry.text and entry.text:sub(1, 1) == "+" then
                            groups.bonuses[#groups.bonuses + 1] = entry
                        elseif entry.text or entry.rightText then
                            local function Normalize(text)
                                return (text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                                    :gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
                            end
                            local key = Normalize(entry.text) .. "\031" .. Normalize(entry.rightText)
                            if key ~= "\031" and not seenFooter[key] then
                                groups.footer[#groups.footer + 1] = entry
                                seenFooter[key] = true
                            end
                        end
                    end
                end
            end
            -- Comparison lines are appended to the frame after the tooltip data, so scan past it.
            local numLines = type(tooltip.NumLines) == "function" and tooltip:NumLines() or 0
            for lineIndex = #data.lines + 1, numLines do
                local left = _G[tooltipName .. "TextLeft" .. lineIndex]
                local right = _G[tooltipName .. "TextRight" .. lineIndex]
                if left and not seenIndices[lineIndex] then
                    local text = ReadText(left)
                    -- Anything the comparison manager appends past the data lines is the stat-change block.
                    if text and text:match("%S") then inCompare = true end
                    if inCompare then
                        seenIndices[lineIndex] = true
                        for _, region in pairs({left = left, right = right}) do
                            Tooltips.SaveNativeRegion(saved, region)
                            region:SetAlpha(0)
                        end
                        groups.compare[#groups.compare + 1] = {
                            left = left, right = right, text = text, rightText = ReadText(right),
                        }
                    end
                end
            end
            if damageMetric then
                groups.metrics = {damageMetric, dpsMetric or {label = L["DPS"], text = "--"},
                    speedMetric or {label = L["Speed"], text = "--"}}
            end
            local width = tooltip:GetWidth() - 32
            local function Label(text, x, y, labelWidth, size, source, justify, color)
                used = used + 1
                local label = tooltipSkin.equipmentRegions[used]
                if not label then
                    label = tooltip:CreateFontString(nil, "OVERLAY")
                    tooltipSkin.equipmentRegions[used] = label
                end
                renderedRegions[label] = true
                Tooltips.StyleFont(label, size, "text")
                if color then
                    label:SetTextColor(color[1], color[2], color[3], 1)
                elseif source then
                    local red, green, blue = source:GetTextColor()
                    label:SetTextColor(red, green, blue, 1)
                end
                label:SetAlpha(1)
                label:SetText(text)
                label:ClearAllPoints()
                label:SetPoint("TOPLEFT", tooltip, "TOPLEFT", x, y)
                label:SetWidth(labelWidth)
                label:SetJustifyH(justify or "LEFT")
                label:SetWordWrap(true)
                label:Show()
                rows[label] = true
                local height = label:GetStringHeight()
                if issecretvalue and issecretvalue(height) then return size + 2 end
                return type(height) == "number" and math.max(size + 2, height) or size + 2
            end
            local lastDividerCursor
            local function Divider()
                -- Nothing was placed since the previous divider (e.g. no stats on white items), so skip the duplicate.
                if cursor == lastDividerCursor then return end
                usedDividers = usedDividers + 1
                local divider = tooltipSkin.equipmentDividers[usedDividers]
                if not divider then
                    divider = tooltip:CreateTexture(nil, "BACKGROUND", "FFXIV_TooltipDividerTemplate", -6)
                    addonEnv.Themes.StyleDivider(divider, tooltip, "BACKGROUND", -6)
                    tooltipSkin.equipmentDividers[usedDividers] = divider
                end
                divider:ClearAllPoints()
                divider:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, cursor)
                divider:SetSize(width, 1)
                divider:Show()
                cursor = cursor - 6
                lastDividerCursor = cursor
            end
            local usedSocketIcons = 0
            local function SocketIcon(entry, x, y)
                if not entry.socketTexture then return 0 end
                usedSocketIcons = usedSocketIcons + 1
                local icon = tooltipSkin.equipmentSocketIcons[usedSocketIcons]
                if not icon then
                    icon = tooltip:CreateTexture(nil, "OVERLAY")
                    tooltipSkin.equipmentSocketIcons[usedSocketIcons] = icon
                end
                icon:SetTexture(entry.socketTexture)
                icon:ClearAllPoints()
                icon:SetPoint("TOPLEFT", tooltip, "TOPLEFT", x, y - 1)
                icon:SetSize(12, 12)
                icon:Show()
                return 16
            end
            local function Row(entry)
                local leftWidth = entry.rightText and width * 0.58 or width
                local iconOffset = SocketIcon(entry, 16, cursor)
                local height = Label(entry.text or "", 16 + iconOffset, cursor, leftWidth - iconOffset, 11, entry.left)
                if entry.rightText then
                    height = math.max(height, Label(entry.rightText, 24 + leftWidth, cursor,
                        width - leftWidth - 8, 11, entry.right, "RIGHT"))
                end
                cursor = cursor - height - 4
            end
            local typeText = itemSubType
            if issecretvalue and issecretvalue(typeText) then typeText = nil end
            Label(slotText or typeText or "", 16, cursor, width, 11, nil, nil, slotColor)
            cursor = cursor - 22
            for index = #groups.metrics + 1, #tooltipSkin.equipmentBars do
                for _, piece in ipairs(tooltipSkin.equipmentBars[index]) do piece:Hide() end
            end
            if #groups.metrics > 0 then
                local cellWidth = width / 3
                local metricHeight = 20
                for index, entry in ipairs(groups.metrics) do
                    local x = 16 + (3 - math.min(3, #groups.metrics) + index - 1) * cellWidth
                    Label(entry.label, x, cursor, cellWidth - 8, 11, nil, "RIGHT")
                    metricHeight = math.max(metricHeight,
                        Label(entry.text, x, cursor - 15, cellWidth - 8, 16, entry.left, "RIGHT"))
                    tooltipSkin.equipmentBars[index] = tooltipSkin.equipmentBars[index] or {}
                    TraitUnderline(tooltipSkin.equipmentBars[index], x, cursor - 28, cellWidth - 8)
                end
                cursor = cursor - 15 - metricHeight - 5
                if #groups.level > 0 then cursor = cursor - 6 else Divider() end
            end
            for _, entry in ipairs(groups.level) do
                usedBands = usedBands + 1
                local band = tooltipSkin.equipmentBands[usedBands]
                if not band then
                    band = tooltip:CreateTexture(nil, "BACKGROUND", "FFXIV_TooltipBandTemplate", -6)
                    tooltipSkin.equipmentBands[usedBands] = band
                end
                band:ClearAllPoints()
                band:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 4, cursor + 2)
                band:SetSize(width + 24, 18)
                band:Show()
                Row(entry)
            end
            for _, entry in ipairs(groups.requirements) do Row(entry) end
            if #groups.bonuses > 0 then
                if #groups.level > 0 then cursor = cursor - 6 else Divider() end
                Label(L["Bonuses"], 16, cursor, width, 11)
                cursor = cursor - 17
                Divider()
                for index = 1, #groups.bonuses, 2 do
                    local left, right = groups.bonuses[index], groups.bonuses[index + 1]
                    local leftOffset = SocketIcon(left, 16, cursor)
                    local height = Label(left.text, 16 + leftOffset, cursor, width / 2 - 6 - leftOffset, 11, left.left)
                    if right then
                        local rightX = 22 + width / 2
                        local rightOffset = SocketIcon(right, rightX, cursor)
                        height = math.max(height, Label(right.text, rightX + rightOffset, cursor,
                            width / 2 - 6 - rightOffset, 11, right.left, "RIGHT"))
                    end
                    cursor = cursor - height - 4
                end
            end
            if #groups.effects > 0 then
                Divider()
                Label(L["Effects"], 16, cursor, width, 11)
                cursor = cursor - 17
                for _, entry in ipairs(groups.effects) do Row(entry) end
            end
            if #groups.compare > 0 then
                Divider()
                for _, entry in ipairs(groups.compare) do
                    if (entry.text and entry.text:match("%S")) or (entry.rightText and entry.rightText:match("%S")) then
                        Row(entry)
                    end
                end
            end
            if #groups.footer > 0 then
                Divider()
                for _, entry in ipairs(groups.footer) do Row(entry) end
            end
            if hasSellPrice and not (issecretvalue and issecretvalue(sellPrice))
                and type(sellPrice) == "number" then
                local money = type(GetMoneyString) == "function" and GetMoneyString(sellPrice)
                    or string.format("%dc", sellPrice)
                local height = Label((SELL_PRICE or L["Sell Price"]) .. ": " .. money, 16, cursor, width, 11)
                cursor = cursor - height - 4
            end
            for _, region in ipairs({tooltip:GetRegions()}) do
                if region:GetObjectType() == "FontString" and region ~= title
                    and not renderedRegions[region] and region ~= tooltipSkin.bindingLabel
                    and not region.FFXIVUITrainerRecipeRow then
                    Tooltips.SaveNativeRegion(saved, region)
                    GuardEquipmentAlpha(region)
                    region:SetAlpha(0)
                end
            end
            tooltipSkin.consumableHeight = tooltip:GetHeight()
            tooltipSkin.targetHeight = -cursor + 16
            tooltipSkin.fitMinimum = 0
            tooltip:SetHeight(tooltipSkin.targetHeight)
            for index = usedSocketIcons + 1, #tooltipSkin.equipmentSocketIcons do
                tooltipSkin.equipmentSocketIcons[index]:Hide()
            end
            HideEquipmentNative()
            Diagnose("Equipment layout selected")
            return
        end
        local hasUseEffect = useSpellID ~= nil
        for index, line in ipairs(data.lines) do
            if IsUseLine(line, index) then
                hasUseEffect = true
                break
            end
        end
        local nonEquippable = equipLocation == nil or equipLocation == ""
            or equipLocation == "INVTYPE_NON_EQUIP" or equipLocation == "INVTYPE_NON_EQUIP_IGNORE"
        if not (isConsumable or nonEquippable and hasUseEffect) then
            Diagnose("Rejected: useSpell=" .. DiagnosticValue(useSpellID)
                .. "; hasUseEffect=" .. DiagnosticValue(hasUseEffect)
                .. "; prefix=" .. DiagnosticValue(ITEM_SPELL_TRIGGER_ONUSE))
            for index, line in ipairs(data.lines) do
                tooltip.FFXIVUILayoutDiagnostic = tooltip.FFXIVUILayoutDiagnostic
                    .. "; line" .. index .. "=" .. DiagnosticValue(line.type)
            end
            -- The restyled title is taller than Blizzard's, so native body lines can extend past its computed height.
            local nativeRows = {[title] = true}
            local sellIndexes = {}
            local sellPrefix = (SELL_PRICE or L["Sell Price"]) .. ":"
            for _, line in ipairs(data.lines) do
                local lineIndex = line.lineIndex
                if type(lineIndex) == "number" and lineIndex > 1 then
                    local left = _G[tooltipName .. "TextLeft" .. lineIndex]
                    local right = _G[tooltipName .. "TextRight" .. lineIndex]
                    if left then nativeRows[left] = true end
                    if right then nativeRows[right] = true end
                    if not (issecretvalue and issecretvalue(line.type)) and line.type == lineTypes.SellPrice then
                        -- Only trust the line type when the native text is unreadable or actually a sell line; a readable non-sell row must stay ours.
                        local text = left and left:GetText()
                        local readable = type(text) == "string" and not (issecretvalue and issecretvalue(text))
                        if not readable or text:sub(1, #sellPrefix) == sellPrefix then
                            sellIndexes[lineIndex] = true
                        end
                    end
                end
            end
            local nativeText = {}
            tooltipSkin.consumableText = nativeText
            tooltipSkin.consumableRows = nativeRows
            -- Title and icon share one 32px header band, so both centre on the same line.
            title:ClearAllPoints()
            title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 56, -19)
            title:SetHeight(32)
            tooltipSkin.itemIcon:ClearAllPoints()
            tooltipSkin.itemIcon:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, -19)
            tooltipSkin.contentLayout = {{region = title, x = 56, y = -19, height = 32, wordWrap = true}}
            HideNativeSellPrices(sellIndexes, nativeRows)
            -- Owned copies of the native rows: we set their text, font, colour and position, so the native regions only supply data.
            local mirrors = tooltipSkin.rowMirrors or {}
            tooltipSkin.rowMirrors = mirrors
            for _, owned in pairs(mirrors) do owned:Hide() end
            local function MirrorRow(native, key)
                if not native then return nil end
                local owned = mirrors[key]
                if not owned then
                    owned = tooltip:CreateFontString(nil, "OVERLAY")
                    mirrors[key] = owned
                end
                local font, size, flags = native:GetFont()
                if font then owned:SetFont(font, size, flags) end
                owned:SetTextColor(native:GetTextColor())
                owned:SetJustifyH(native:GetJustifyH() or "LEFT")
                -- Width and wrap must be set before the text so the measured height includes wrapped lines.
                owned:SetWidth(math.max(1, tooltip:GetWidth() - 32))
                owned:SetWordWrap(true)
                owned:SetText(native:GetText())
                owned:Show()
                return owned
            end
            local cursor = -52
            local lastNative
            local lineCount = tooltip.NumLines and tooltip:NumLines()
            if (issecretvalue and issecretvalue(lineCount)) or type(lineCount) ~= "number" then
                lineCount = #data.lines
            end
            -- NumLines can under-report on Retail; trailing rows (flavor text) must still be placed so the sell label anchors below them.
            for index, line in ipairs(data.lines) do
                local lineIndex = line.lineIndex or index
                if not (issecretvalue and issecretvalue(lineIndex)) and lineIndex > lineCount then
                    lineCount = lineIndex
                end
            end
            for lineIndex = 2, lineCount do
                local left = _G[tooltipName .. "TextLeft" .. lineIndex]
                local right = _G[tooltipName .. "TextRight" .. lineIndex]
                -- Regions hidden by the sell pass are already saved; re-placing them would show the native sell price again.
                if not sellIndexes[lineIndex] and not (left and nativeText[left]) and not (right and nativeText[right]) then
                    local ownLeft, ownRight = MirrorRow(left, "L" .. lineIndex), MirrorRow(right, "R" .. lineIndex)
                    if left then
                        Tooltips.SaveNativeRegion(nativeText, left, 1, true)
                        left:SetAlpha(0)
                    end
                    if right then
                        Tooltips.SaveNativeRegion(nativeText, right, 1, true)
                        right:SetAlpha(0)
                    end
                    if ownLeft then Tooltips.SaveNativeRegion(nativeText, ownLeft, 1, true) end
                    if ownRight then Tooltips.SaveNativeRegion(nativeText, ownRight, 1, true) end
                    cursor = Tooltips.PlaceNativeLine(tooltipSkin, nativeText, ownLeft, ownRight, cursor)
                    lastNative = ownLeft or lastNative
                end
            end
            if type(sellPrice) == "number" and not (issecretvalue and issecretvalue(sellPrice)) and sellPrice > 0 then
                local money = type(GetMoneyString) == "function" and GetMoneyString(sellPrice)
                    or string.format("%dc", sellPrice)
                local sell = ConsumableRegion("sellPriceText", 11, "text")
                sell:SetText((SELL_PRICE or L["Sell Price"]) .. ": " .. money)
                sell:ClearAllPoints()
                sell:SetWordWrap(true)
                sell:SetJustifyH("LEFT")
                sell:SetWidth(math.max(1, tooltip:GetWidth() - 32))
                if lastNative then
                    sell:SetPoint("TOPLEFT", lastNative, "BOTTOMLEFT", 0, -4)
                else
                    sell:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, cursor)
                end
                sell:Show()
                cursor = cursor - 18
            end
            HideNativeMoneyFrames()
            tooltipSkin.targetHeight = -cursor + 16
            tooltip:SetHeight(tooltipSkin.targetHeight)
            return
        end
        Diagnose("Structured layout selected")

        local nativeText, effectLines, requirementLines, descriptionLines, sellLines = {}, {}, {}, {}, {}
        local sellIndexes = {}
        -- Recipe reagents sit between the first "Use:" line and the last requirement line, and arrive untyped.
        local useIndex, requirementIndex
        for index, line in ipairs(data.lines) do
            if useIndex == nil and IsUseLine(line, index) then useIndex = index end
            if line.type == lineTypes.UsageRequirement then requirementIndex = index end
        end
        tooltipSkin.consumableText = nativeText
        tooltipSkin.consumableRows = {}
        for _, owned in pairs(tooltipSkin.rowMirrors or {}) do owned:Hide() end
        local function SaveAndHide(region)
            if not region or nativeText[region] then return end
            Tooltips.SaveNativeRegion(nativeText, region)
            region:SetAlpha(0)
        end
        -- The last placed left-column region, so following rows can anchor to its real rendered bottom edge.
        local lastRow
        -- A row re-placed here must be visible, so a saved alpha of 0 is treated as hidden-by-us, not as the original.
        local function PlaceSavedRow(line, y)
            for _, region in ipairs({line.left or false, line.right or false}) do
                local state = region and nativeText[region]
                if state and state.alpha == 0 then state.alpha = 1 end
            end
            local result = Tooltips.PlaceNativeLine(tooltipSkin, nativeText, line.left, line.right, y)
            lastRow = line.left or lastRow
            return result
        end
        local seenFrameTexts = {}
        for index, line in ipairs(data.lines) do
            local lineIndex = line.lineIndex or index
            if not (issecretvalue and (issecretvalue(lineIndex) or issecretvalue(line.type))) then
                local left = _G[tooltipName .. "TextLeft" .. lineIndex]
                local right = _G[tooltipName .. "TextRight" .. lineIndex]
                if line.type == lineTypes.SellPrice then
                    hasSellPrice = true
                    sellIndexes[lineIndex] = true
                    SaveAndHide(left)
                    SaveAndHide(right)
                -- The first line is the title and stays visible whatever its type; a repeated name row would otherwise stay at its native position.
                elseif lineIndex ~= 1 then
                    SaveAndHide(left)
                    SaveAndHide(right)
                end
                if IsUseLine(line, index) or line.type == lineTypes.ItemSpellTriggerOnEquip
                    or line.type == lineTypes.ItemSpellTriggerOnProc
                    or line.type == lineTypes.SpellDescription then
                    local function Blank(text)
                        if issecretvalue and issecretvalue(text) then return false end
                        if type(text) ~= "string" then return true end
                        return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", "")
                            :gsub("\194\160", ""):gsub("%s", "") == ""
                    end
                    -- Spell-description lines can be empty in the data but filled on screen;
                    -- a frame text already shown by an earlier line is a stale reuse, not an effect.
                    local frameText = left and left:GetText()
                    local stale = type(frameText) == "string" and not (issecretvalue and issecretvalue(frameText))
                        and seenFrameTexts[frameText]
                    local empty = Blank(line.leftText) and (stale or Blank(frameText))
                    if left and not empty then effectLines[#effectLines + 1] = {left = left, right = right} end
                elseif line.type == lineTypes.FlavorText or line.type == lineTypes.ToyDescription then
                    if left then descriptionLines[#descriptionLines + 1] = {left = left, right = right} end
                elseif line.type == lineTypes.SellPrice then
                    if left then sellLines[#sellLines + 1] = {left = left, right = right} end
                elseif left and (line.type == lineTypes.UsageRequirement
                    or (useIndex and requirementIndex and index > useIndex and index < requirementIndex)) then
                    local text = left:GetText()
                    if type(text) == "string" and not (issecretvalue and issecretvalue(text)) and text ~= "" then
                        requirementLines[#requirementLines + 1] = {left = left, right = right}
                    end
                end
                local shown = left and left:GetText()
                if type(shown) == "string" and not (issecretvalue and issecretvalue(shown)) then
                    seenFrameTexts[shown] = true
                end
            end
        end

        local itemCount = type(C_Item.GetItemCount) == "function" and C_Item.GetItemCount(itemLink)
        if issecretvalue and (issecretvalue(itemCount) or issecretvalue(maxStack)) then itemCount = nil end
        if issecretvalue and (issecretvalue(itemSubType) or issecretvalue(itemType)) then
            itemSubType, itemType = nil, nil
        end
        local typeText = itemSubType or itemType
        -- Some items (housing decor) carry their category on the first untyped line.
        local categoryLine = data.lines[2]
        local isHousingDecor = false
        if categoryLine and not (issecretvalue and (issecretvalue(categoryLine.type)
            or issecretvalue(categoryLine.leftText))) and categoryLine.type == lineTypes.None
            and type(categoryLine.leftText) == "string" then
            local category = categoryLine.leftText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            if category:gsub("%s", "") ~= "" then
                typeText = category
                isHousingDecor = category:lower():find("housing decor", 1, true) ~= nil
            end
        end
        if type(typeText) == "string" then
            local typeRegion = ConsumableRegion("itemTypeText", 12, "muted")
            typeRegion:SetText(typeText)
            typeRegion:SetJustifyH("LEFT")
            typeRegion:ClearAllPoints()
            typeRegion:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, -48 + headerOffset)
            typeRegion:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -150, -48 + headerOffset)
            typeRegion:Show()
        end
        -- Housing decor: Retail's native right text already draws the house icon, so it stays hidden
        -- and our masked house icon and owned count are drawn in the count slot.
        local nativeCount = tooltip.TextRight1
        if nativeCount and nativeCount.ffxivHidNativeCount and not isHousingDecor then
            nativeCount:Show()
            nativeCount.ffxivHidNativeCount = false
        end
        local housingOwned
        if isHousingDecor then
            if nativeCount then
                nativeCount.ffxivHidNativeCount = true
                nativeCount:Hide()
            end
            local catalogInfo = type(C_HousingCatalog) == "table"
                and type(C_HousingCatalog.GetCatalogEntryInfoByItem) == "function"
                and C_HousingCatalog.GetCatalogEntryInfoByItem(itemLink)
            if type(catalogInfo) == "table" then
                local stored, placed = catalogInfo.totalNumStored, catalogInfo.totalNumPlaced
                if not (issecretvalue and (issecretvalue(stored) or issecretvalue(placed)))
                    and type(stored) == "number" and type(placed) == "number" then
                    housingOwned = stored + placed
                end
            end
        end
        if isHousingDecor then
            local icon = layout.HousingIcon()
            icon:ClearAllPoints()
            icon:SetSize(14, 14)
            icon:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -16, -48 + headerOffset - 1)
        elseif tooltipSkin.housingIcon then
            tooltipSkin.housingIcon:Hide()
            tooltipSkin.housingRing:Hide()
        end
        if housingOwned then
            local countRegion = ConsumableRegion("itemCountText", 12, "muted")
            countRegion:SetText(tostring(housingOwned))
            countRegion:SetJustifyH("RIGHT")
            countRegion:ClearAllPoints()
            countRegion:SetPoint("TOPRIGHT", tooltipSkin.housingIcon, "TOPLEFT", -4, 1)
            countRegion:Show()
        elseif type(itemCount) == "number" and type(maxStack) == "number" then
            local countRegion = ConsumableRegion("itemCountText", 12, "muted")
            countRegion:SetText(itemCount .. "/" .. maxStack)
            countRegion:SetJustifyH("RIGHT")
            countRegion:ClearAllPoints()
            countRegion:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 170, -48 + headerOffset)
            countRegion:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -16, -48 + headerOffset)
            countRegion:Show()
        end

        local cursor = -68 + headerOffset
        do
            local duration
            if useSpellID and type(GetSpellBaseCooldown) == "function" then
                local milliseconds = GetSpellBaseCooldown(useSpellID)
                if not (issecretvalue and issecretvalue(milliseconds))
                    and type(milliseconds) == "number" and milliseconds >= 0 then
                    duration = milliseconds / 1000
                end
            end
            local itemID = tonumber(itemLink:match("item:(%d+)"))
            if itemID == 6948 then duration = 30 * 60 end
            local header = ConsumableRegion("recastHeader", 11, "muted")
            header:SetText(L["Recast"])
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, cursor)
            header:SetWidth(math.max(1, (tooltip:GetWidth() - 32) / 3 - 6))
            header:SetJustifyH("RIGHT")
            header:SetWordWrap(false)
            header:Show()
            cursor = cursor - 13
            local recast = ConsumableRegion("recastText", 16, "text")
            if duration == nil then
                recast:SetText("--")
            elseif SecondsToTimeAbbrev then
                recast:SetFormattedText(SecondsToTimeAbbrev(duration))
            else
                recast:SetText(string.format("%gs", duration))
            end
            recast:ClearAllPoints()
            recast:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, cursor)
            recast:SetWidth(math.max(1, (tooltip:GetWidth() - 32) / 3 - 6))
            recast:SetJustifyH("RIGHT")
            recast:SetWordWrap(false)
            recast:Show()
            cursor = cursor - 13
            tooltipSkin.recastDivider = tooltipSkin.recastDivider or {}
            local cellWidth = math.max(6, (tooltip:GetWidth() - 32) / 3 - 6)
            TraitUnderline(tooltipSkin.recastDivider, 16, cursor, cellWidth)
            cursor = cursor - 14
        end
        local dividerCount = 0
        local function ConsumableDivider(y)
            tooltipSkin.equipmentDividers = tooltipSkin.equipmentDividers or {}
            dividerCount = dividerCount + 1
            local divider = tooltipSkin.equipmentDividers[dividerCount]
            if not divider then
                divider = tooltip:CreateTexture(nil, "BACKGROUND", "FFXIV_TooltipDividerTemplate", -6)
                addonEnv.Themes.StyleDivider(divider, tooltip, "BACKGROUND", -6)
                tooltipSkin.equipmentDividers[dividerCount] = divider
            end
            divider:ClearAllPoints()
            divider:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, y)
            divider:SetSize(tooltip:GetWidth() - 32, 1)
            divider:Show()
        end
        if #effectLines > 0 then
            local header = ConsumableRegion("effectsHeader", 12, "muted")
            header:SetText(L["Effects"])
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, cursor)
            header:Show()
            ConsumableDivider(cursor - 16)
            cursor = cursor - 24
        end

        for _, line in ipairs(effectLines) do
            cursor = PlaceSavedRow(line, cursor)
        end
        for _, line in ipairs(requirementLines) do
            cursor = PlaceSavedRow(line, cursor)
        end
        if #descriptionLines > 0 and #effectLines > 0 then
            cursor = cursor - 2
            ConsumableDivider(cursor)
            cursor = cursor - 10
        end
        for _, line in ipairs(descriptionLines) do
            cursor = PlaceSavedRow(line, cursor)
        end
        if #descriptionLines == 0 and type(itemDescription) == "string"
            and not (issecretvalue and issecretvalue(itemDescription)) and itemDescription ~= "" then
            local description = ConsumableRegion("itemDescription", 12, "text")
            description:SetText(itemDescription)
            description:SetWordWrap(true)
            description:ClearAllPoints()
            description:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, cursor)
            description:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -16, cursor)
            description:Show()
            lastRow = description
            cursor = cursor - math.max(14, description:GetStringHeight()) - 4
        elseif tooltipSkin.itemDescription then
            tooltipSkin.itemDescription:Hide()
        end
        local customSell = hasSellPrice and not (issecretvalue and issecretvalue(sellPrice))
            and type(sellPrice) == "number" and sellPrice > 0
        local sellZero = type(sellPrice) == "number" and not (issecretvalue and issecretvalue(sellPrice))
            and sellPrice == 0
        for _, line in ipairs(sellLines) do
            if SellRowIsZero(line.left) or SellRowIsZero(line.right) then sellZero = true end
        end
        if customSell then
            local money = type(GetMoneyString) == "function" and GetMoneyString(sellPrice)
                or string.format("%dc", sellPrice)
            local sell = ConsumableRegion("sellPriceText", 11, "text")
            sell:SetText((SELL_PRICE or L["Sell Price"]) .. ": " .. money)
            sell:SetWordWrap(true)
            sell:SetJustifyH("LEFT")
            sell:SetWidth(math.max(1, tooltip:GetWidth() - 32))
            sell:ClearAllPoints()
            -- Anchored to the previous row so wrapped text above it cannot push the label into it.
            local placement = {region = sell, x = 16, y = cursor}
            if lastRow then
                placement = {region = sell, point = "TOPLEFT", relativeTo = lastRow,
                    relativePoint = "BOTTOMLEFT", x = 0, y = -4}
            end
            sell:SetPoint(placement.point or "TOPLEFT", placement.relativeTo or tooltip,
                placement.relativePoint or "TOPLEFT", placement.x, placement.y)
            sell:Show()
            tooltipSkin.contentLayout[#tooltipSkin.contentLayout + 1] = placement
            cursor = cursor - math.max(14, sell:GetStringHeight()) - 4
            HideNativeMoneyFrames()
            HideNativeSellPrices(sellIndexes)
        elseif not sellZero then
            -- Native sell rows are centred by Blizzard; left-align them to match the custom label.
            for _, line in ipairs(sellLines) do
                if line.left then line.left:SetJustifyH("LEFT") end
                cursor = PlaceSavedRow(line, cursor)
            end
        end
        tooltipSkin.consumableHeight = tooltip:GetHeight()
        tooltipSkin.fitMinimum = 0
        tooltipSkin.targetHeight = -cursor + 16
        tooltip:SetHeight(tooltipSkin.targetHeight)
    end

    return StyleItemHeader
end