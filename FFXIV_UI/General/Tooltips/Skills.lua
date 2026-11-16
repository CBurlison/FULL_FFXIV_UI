local addonName, ns = ...
local Tooltips = ns.Tooltips

local function Plain(value)
    if type(value) ~= "string" or (issecretvalue and issecretvalue(value)) then return nil end
    return (value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " "):match("^%s*(.-)%s*$"))
end

-- The tooltip data carries no icon, so take it from the button the tooltip is attached to.
local function OwnerIcon(owner, depth)
    if not owner or (depth or 0) > 2 then return nil end
    for _, key in ipairs({"Icon", "icon", "IconTexture"}) do
        local texture = owner[key]
        if type(texture) == "table" and texture.GetObjectType and texture:GetObjectType() == "Texture" then
            local atlas = texture.GetAtlas and texture:GetAtlas()
            local file = texture:GetTexture()
            if type(atlas) == "string" and atlas ~= "" then return atlas, true end
            if file ~= nil and not (issecretvalue and issecretvalue(file)) then return file, false end
        end
    end
    if type(owner.GetChildren) == "function" then
        for _, child in ipairs({owner:GetChildren()}) do
            local value, isAtlas = OwnerIcon(child, (depth or 0) + 1)
            if value then return value, isAtlas end
        end
    end
end

local function SkillLineIcon(skillLineID, name)
    local book = C_SpellBook
    if not book or type(book.GetNumSpellBookSkillLines) ~= "function"
        or type(book.GetSpellBookSkillLineInfo) ~= "function" then return nil end
    for index = 1, book.GetNumSpellBookSkillLines() do
        local info = book.GetSpellBookSkillLineInfo(index)
        if type(info) == "table" and not (issecretvalue and issecretvalue(info.iconID)) then
            if (skillLineID and info.skillLineID == skillLineID) or (name and info.name == name) then
                return info.iconID
            end
        end
    end
end

-- Companion pet tooltips carry no ID, so find the pet by name in the journal.
local function PetIcon(name)
    local journal = C_PetJournal
    if not journal or type(journal.FindPetIDByName) ~= "function" or not name then return nil end
    local first, second = journal.FindPetIDByName(name)
    for _, value in ipairs({first, second}) do
        if type(value) == "string" and type(journal.GetPetInfoByPetID) == "function" then
            local _, _, _, _, _, _, _, _, icon = journal.GetPetInfoByPetID(value)
            if icon then return icon end
        elseif type(value) == "number" and type(journal.GetPetInfoBySpeciesID) == "function" then
            local _, icon = journal.GetPetInfoBySpeciesID(value)
            if icon then return icon end
        end
    end
end

-- Simple tooltips (Warbands, companion pets): icon, name beside it, text below.
-- options.category puts line 2 under the icon; options.dropCast discards a cast-time line.
function Tooltips.InitializeSkillLines(tooltipSkin, layout, options)
    options = options or {}
    local tooltip = tooltipSkin.tooltip
    local RestoreItemHeader = layout.RestoreItemHeader
    local GuardEquipmentAlpha = layout.GuardEquipmentAlpha
    local ConsumableRegion = layout.Region

    return function()
        RestoreItemHeader()
        local data = type(tooltip.GetTooltipData) == "function" and tooltip:GetTooltipData()
        local tooltipName = tooltip:GetName()
        if not data or not data.lines or type(tooltipName) ~= "string" then return end
        tooltipSkin.spellLayoutActive = true
        tooltipSkin.originalWidth = tooltip:GetWidth()
        tooltipSkin.targetWidth = math.max(320, tooltipSkin.originalWidth)
        tooltip:SetWidth(tooltipSkin.targetWidth)

        local saved = {}
        tooltipSkin.consumableText = saved
        tooltipSkin.consumableRows = {}
        local entries, seen = {}, {}
        for index, line in ipairs(data.lines) do
            local lineIndex = line.lineIndex
            if issecretvalue and issecretvalue(lineIndex) then lineIndex = index end
            lineIndex = lineIndex or index
            seen[lineIndex] = true
            local left = _G[tooltipName .. "TextLeft" .. lineIndex]
            local right = _G[tooltipName .. "TextRight" .. lineIndex]
            for _, region in pairs({left = left, right = right}) do
                Tooltips.SaveNativeRegion(saved, region)
                GuardEquipmentAlpha(region)
                region:SetAlpha(0)
            end
            local text = Plain(left and left:GetText()) or Plain(line.leftText)
            if text and text ~= "" then entries[#entries + 1] = text end
        end
        if not entries[1] then return end
        local category = options.category and #entries >= 2 and table.remove(entries, 2) or nil
        if options.dropCast and #entries >= 3 then table.remove(entries, 2) end

        local skillLineID = type(data.id) == "number" and not (issecretvalue and issecretvalue(data.id)) and data.id or nil
        local owner = type(tooltip.GetOwner) == "function" and tooltip:GetOwner()
        local iconID, isAtlas = OwnerIcon(owner)
        if not iconID then iconID, isAtlas = SkillLineIcon(skillLineID, entries[1]), false end
        if not iconID and options.category then iconID, isAtlas = PetIcon(entries[1]), false end
        tooltipSkin.itemIcon = tooltipSkin.itemIcon or tooltip:CreateTexture(nil, "ARTWORK", "FFXIV_TooltipIconTemplate")
        tooltipSkin.itemIcon:SetTexCoord(0, 1, 0, 1)
        if iconID then
            if isAtlas then tooltipSkin.itemIcon:SetAtlas(iconID) else tooltipSkin.itemIcon:SetTexture(iconID) end
        end
        tooltipSkin.itemIcon:SetShown(iconID ~= nil)
        local titleX = iconID and 56 or 16

        local title = tooltipSkin.spellTitle
        if not title then
            title = tooltip:CreateFontString(nil, "OVERLAY")
            tooltipSkin.spellTitle = title
        end
        Tooltips.StyleFont(title, 14, "text")
        title:SetText(entries[1])
        title:ClearAllPoints()
        title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", titleX, -10)
        title:SetWidth(math.max(1, tooltip:GetWidth() - titleX - 16))
        title:SetHeight(32)
        title:SetJustifyH("LEFT")
        title:SetJustifyV("MIDDLE")
        title:SetWordWrap(false)
        title:Show()
        tooltipSkin.consumableRows[title] = true
        tooltipSkin.contentLayout = {{region = title, x = titleX, y = -10, spellTitle = true, height = 32}}

        local y = -52
        local dividerY = -50
        if category then
            local typeRegion = ConsumableRegion("itemTypeText", 12, "muted")
            typeRegion:SetText(category)
            typeRegion:SetJustifyH("LEFT")
            typeRegion:ClearAllPoints()
            typeRegion:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, -48)
            typeRegion:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -16, -48)
            typeRegion:Show()
            dividerY = -68
        end
        if entries[2] then
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
            y = dividerY - 10
            local lines = {}
            for index = 2, #entries do lines[#lines + 1] = entries[index] end
            local description = ConsumableRegion("itemDescription", 12, "text")
            description:SetTextColor(1, 0.82, 0)
            description:SetText(table.concat(lines, "\n"))
            description:SetJustifyH("LEFT")
            description:SetHeight(0)
            description:SetMaxLines(0)
            description:SetWordWrap(true)
            description:ClearAllPoints()
            description:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, y)
            description:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -16, y)
            description:SetWidth(tooltip:GetWidth() - 32)
            description:Show()
            tooltipSkin.contentLayout[#tooltipSkin.contentLayout + 1] = {
                region = description, x = 16, y = y, rightWidth = 0,
            }
            local height = description:GetStringHeight()
            if issecretvalue and issecretvalue(height) then height = 14 end
            y = y - math.max(14, height) - 4
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
        tooltipSkin.targetHeight = math.max(-y + 14, 54)
        tooltip:SetHeight(tooltipSkin.targetHeight)
    end
end
