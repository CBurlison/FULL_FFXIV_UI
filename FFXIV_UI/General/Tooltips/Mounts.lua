local addonName, ns = ...
local Tooltips = ns.Tooltips
local L = Tooltips.L

local function Plain(value)
    if type(value) ~= "string" or (issecretvalue and issecretvalue(value)) then return nil end
    return (value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " "):match("^%s*(.-)%s*$"))
end

function Tooltips.InitializeMounts(tooltipSkin, layout)
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
            local text = Plain(line.leftText)
            if text and text ~= "" then
                entries[#entries + 1] = {
                    left = left, type = line.type, text = text, rightText = Plain(line.rightText) or "",
                }
            end
        end
        local name, category = entries[1], entries[2]
        if not name then return end
        local nextEntry = 3
        local cast = entries[3] and entries[3].type == entries[2].type and entries[3] or nil
        if cast then nextEntry = 4 end

        local iconID
        if C_MountJournal and type(C_MountJournal.GetMountInfoByID) == "function"
            and type(data.id) == "number" and not (issecretvalue and issecretvalue(data.id)) then
            local _, spellID, icon = C_MountJournal.GetMountInfoByID(data.id)
            iconID = icon
            if not iconID and spellID and C_Spell and C_Spell.GetSpellTexture then
                iconID = C_Spell.GetSpellTexture(spellID)
            end
            if issecretvalue and issecretvalue(iconID) then iconID = nil end
        end
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
        title:SetHeight(18)
        title:SetJustifyV("MIDDLE")
        tooltipSkin.contentLayout = {{region = title, x = 56, y = -10, spellTitle = true}}
        local movement = TraitText("spellAbilityType", category and category.rightText or "", 11, "muted",
            56, -25, math.max(1, tooltip:GetWidth() - 72), "LEFT")
        movement:ClearAllPoints()
        movement:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 3)
        tooltipSkin.contentLayout[2] = {
            region = movement, x = 0, y = 3, point = "TOPLEFT",
            relativeTo = title, relativePoint = "BOTTOMLEFT", headerWidth = true,
        }

        local typeRegion = ConsumableRegion("itemTypeText", 12, "muted")
        typeRegion:SetText(category and category.text or "")
        typeRegion:SetJustifyH("LEFT")
        typeRegion:ClearAllPoints()
        typeRegion:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, -48)
        typeRegion:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -150, -48)
        typeRegion:Show()

        local castText = L["Instant"]
        if cast then
            local number = cast.text:match("(%d+[%.,]?%d*)")
            local seconds = number and tonumber((number:gsub(",", ".")))
            castText = seconds and string.format("%.2fs", seconds) or cast.text
        end
        local cellWidth = (tooltip:GetWidth() - 32) / 3
        local metricsTop = -66
        TraitText("spellCastHeader", L["Cast"], 11, "muted", 16, metricsTop, cellWidth - 8, "RIGHT")
        TraitText("spellCastValue", castText, 16, "text", 16, metricsTop - 17, cellWidth - 8, "RIGHT")
        tooltipSkin.spellBars = tooltipSkin.spellBars or {}
        tooltipSkin.spellBars[1] = tooltipSkin.spellBars[1] or {}
        TraitUnderline(tooltipSkin.spellBars[1], 16, metricsTop - 30, cellWidth - 8)

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
        local lines = {}
        for index = nextEntry, #entries do lines[#lines + 1] = entries[index].text end
        if #lines > 0 then
            local description = ConsumableRegion("itemDescription", 12, "text")
            description:SetText(table.concat(lines, "\n"))
            description:SetJustifyH("LEFT")
            description:SetWordWrap(true)
            description:ClearAllPoints()
            description:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, y)
            description:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -16, y)
            description:Show()
            local height = description:GetStringHeight()
            if issecretvalue and issecretvalue(height) then height = 14 end
            y = y - math.max(14, height) - 4
        end
        tooltipSkin.consumableHeight = tooltip:GetHeight()
        tooltipSkin.fitMinimum = 0
        tooltipSkin.targetHeight = -y + 14
        tooltip:SetHeight(tooltipSkin.targetHeight)
    end
end
