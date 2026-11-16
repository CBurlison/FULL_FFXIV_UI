local addonName, ns = ...
local Tooltips = ns.Tooltips
local L = Tooltips.L

local function Plain(value)
    if type(value) ~= "string" or (issecretvalue and issecretvalue(value)) then return nil end
    return (value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " "):match("^%s*(.-)%s*$"))
end

local function IsRequirement(text)
    if type(ITEM_MIN_LEVEL) ~= "string" then return false end
    local pattern = "^" .. (ITEM_MIN_LEVEL:gsub("%p", "%%%0"):gsub("%%%%d", "%%d+")) .. "$"
    return text:match(pattern) ~= nil
end

local function DurationText(milliseconds)
    return Tooltips.FormatDuration(milliseconds / 1000)
end

function Tooltips.InitializeToys(tooltipSkin, layout)
    local tooltip = tooltipSkin.tooltip
    local RestoreItemHeader = layout.RestoreItemHeader
    local GuardEquipmentAlpha = layout.GuardEquipmentAlpha
    local ConsumableRegion = layout.Region
    local TraitUnderline = layout.TraitUnderline

    return function()
        RestoreItemHeader()
        local data = type(tooltip.GetTooltipData) == "function" and tooltip:GetTooltipData()
        local tooltipName = tooltip:GetName()
        if not data or not data.lines or type(tooltipName) ~= "string" then return end
        tooltipSkin.spellLayoutActive = true

        local saved = {}
        tooltipSkin.consumableText = saved
        tooltipSkin.consumableRows = {}
        local entries = {}
        for index, line in ipairs(data.lines) do
            local left = _G[tooltipName .. "TextLeft" .. index]
            local right = _G[tooltipName .. "TextRight" .. index]
            for _, region in pairs({left = left, right = right}) do
                Tooltips.SaveNativeRegion(saved, region)
                GuardEquipmentAlpha(region)
                region:SetAlpha(0)
            end
            -- The on-screen text has plural and gender escapes resolved.
            local text = Plain(left and left:GetText()) or Plain(line.leftText)
            if text and text ~= "" then entries[#entries + 1] = {text = text} end
        end
        local name, category = entries[1], entries[2]
        if not name then return end
        local body, requirement = {}, nil
        for index = 3, #entries do
            if IsRequirement(entries[index].text) then
                requirement = entries[index].text
            else
                body[#body + 1] = entries[index].text
            end
        end

        local itemID = type(data.id) == "number" and not (issecretvalue and issecretvalue(data.id)) and data.id or nil
        local iconID = itemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)
        if issecretvalue and issecretvalue(iconID) then iconID = nil end
        tooltipSkin.itemIcon = tooltipSkin.itemIcon or tooltip:CreateTexture(nil, "ARTWORK", "FFXIV_TooltipIconTemplate")
        if iconID then tooltipSkin.itemIcon:SetTexture(iconID) end
        tooltipSkin.itemIcon:SetShown(iconID ~= nil)

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

        tooltipSkin.originalWidth = tooltip:GetWidth()
        tooltipSkin.targetWidth = math.max(420, tooltipSkin.originalWidth)
        tooltip:SetWidth(tooltipSkin.targetWidth)

        local title = TraitText("spellTitle", name.text, 14, "text", 56, -10,
            math.max(1, tooltip:GetWidth() - 72), "LEFT")
        title:SetHeight(32)
        title:SetJustifyV("MIDDLE")
        tooltipSkin.contentLayout = {{region = title, x = 56, y = -10, spellTitle = true, height = 32}}

        local typeRegion = ConsumableRegion("itemTypeText", 12, "muted")
        typeRegion:SetText(category and category.text or "")
        typeRegion:SetJustifyH("LEFT")
        typeRegion:ClearAllPoints()
        typeRegion:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, -48)
        typeRegion:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -150, -48)
        typeRegion:Show()

        local castText, cooldownText = "--", "--"
        local spellID = itemID and C_Item and C_Item.GetItemSpell and select(2, C_Item.GetItemSpell(itemID))
        if type(spellID) == "number" and not (issecretvalue and issecretvalue(spellID)) then
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
            local castTime = type(info) == "table" and info.castTime
            if type(castTime) == "number" and not (issecretvalue and issecretvalue(castTime)) then
                castText = castTime > 0 and string.format("%.2fs", castTime / 1000) or L["Instant"]
            end
            local cooldownMS, globalCooldownMS = Tooltips.SpellCooldownMS(spellID)
            if cooldownMS ~= nil or globalCooldownMS > 0 then
                cooldownText = DurationText(math.max(cooldownMS or 0, globalCooldownMS))
            end
        end

        local cellWidth = (tooltip:GetWidth() - 32) / 3
        local metricsTop = -66
        tooltipSkin.spellBars = tooltipSkin.spellBars or {}
        for index, trait in ipairs({
            {"spellCast", L["Cast"], castText}, {"spellCooldown", L["Recast"], cooldownText},
        }) do
            local x = 16 + (index - 1) * cellWidth
            TraitText(trait[1] .. "Header", trait[2], 11, "muted", x, metricsTop, cellWidth - 8, "RIGHT")
            TraitText(trait[1] .. "Value", trait[3], 16, "text", x, metricsTop - 17, cellWidth - 8, "RIGHT")
            tooltipSkin.spellBars[index] = tooltipSkin.spellBars[index] or {}
            TraitUnderline(tooltipSkin.spellBars[index], x, metricsTop - 30, cellWidth - 8)
        end

        local dividerY = metricsTop - 46
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
            piece:SetSize(tooltip:GetWidth() - 32, 1)
            piece:Show()
        end

        local y = metricsTop - 52
        local function Paragraph(key, text, token)
            local region = ConsumableRegion(key, 12, token)
            region:SetText(text)
            region:SetJustifyH("LEFT")
            region:SetWordWrap(true)
            region:ClearAllPoints()
            region:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, y)
            region:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -16, y)
            region:Show()
            local height = region:GetStringHeight()
            if issecretvalue and issecretvalue(height) then height = 14 end
            y = y - math.max(14, height) - 4
        end
        if #body > 0 then Paragraph("itemDescription", table.concat(body, "\n"), "text") end
        if requirement then Paragraph("toyRequirement", requirement, "muted") end
        tooltipSkin.consumableHeight = tooltip:GetHeight()
        tooltipSkin.fitMinimum = 0
        tooltipSkin.targetHeight = -y + 14
        tooltip:SetHeight(tooltipSkin.targetHeight)
    end
end
