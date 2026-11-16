local addonName, ns = ...
local Tooltips = ns.Tooltips
local L = Tooltips.L

local function Plain(value)
    if type(value) ~= "string" or (issecretvalue and issecretvalue(value)) then return nil end
    return (value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", "\n"))
end

-- Restyles the pet battle ability tooltip in place after Blizzard has filled it in.
function Tooltips.InitializePetAbility(tooltipSkin, layout)
    local tooltip = tooltipSkin.tooltip
    local TraitUnderline = layout.TraitUnderline
    local dividers, bars = {}, {}
    local hidden = false
    local wantedWidth, wantedHeight, applying

    -- Blizzard resizes the frame after filling it in, so reassert our size.
    local function Reassert()
        if applying or not wantedHeight then return end
        applying = true
        if math.abs(tooltip:GetHeight() - wantedHeight) > 0.5 then tooltip:SetHeight(wantedHeight) end
        if math.abs(tooltip:GetWidth() - wantedWidth) > 0.5 then tooltip:SetWidth(wantedWidth) end
        applying = false
    end
    for _, method in ipairs({"SetHeight", "SetWidth", "SetSize"}) do
        hooksecurefunc(tooltip, method, Reassert)
    end

    local function Text(key, text, size, token, x, y, width, justify)
        local region = tooltipSkin[key]
        if not region then
            region = tooltip:CreateFontString(nil, "OVERLAY")
            tooltipSkin[key] = region
        end
        Tooltips.StyleFont(region, size, token)
        region:SetText(text)
        region:ClearAllPoints()
        region:SetPoint("TOPLEFT", tooltip, "TOPLEFT", x, y)
        region:SetWidth(width)
        region:SetJustifyH(justify or "LEFT")
        region:SetWordWrap(false)
        region:Show()
        return region
    end

    local function Divider(index, y)
        local pieces = dividers[index]
        if not pieces then
            pieces = {}
            for piece = 1, 2 do
                pieces[piece] = tooltip:CreateTexture(nil, "ARTWORK")
                pieces[piece]:SetColorTexture(unpack(piece == 1 and {0, 0, 0, 0.85} or {1, 1, 1, 0.4}))
            end
            dividers[index] = pieces
        end
        for piece, texture in ipairs(pieces) do
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, y - (piece - 1))
            texture:SetSize(tooltip:GetWidth() - 32, 1)
            texture:Show()
        end
    end

    return function()
        if not tooltip.Name or not tooltip.Description then return end
        if not hidden then
            hidden = true
            for _, key in ipairs({"Duration", "MaxCooldown", "CurrentCooldown", "AdditionalText",
                "Description", "Delimiter1", "Delimiter2"}) do
                if tooltip[key] then tooltip[key]:SetAlpha(0) end
            end
        end

        local width = math.max(300, wantedWidth or 0, tooltip:GetWidth())
        applying = true
        tooltip:SetWidth(width)
        applying = false

        local cooldown
        if tooltip.MaxCooldown:IsShown() then
            local text = Plain(tooltip.MaxCooldown:GetText())
            cooldown = text and text:match("%d+")
        end
        local hit, paragraphs = nil, {}
        local raw = Plain(tooltip.Description:GetText())
        if raw then
            for paragraph in raw:gmatch("[^\r\n]+") do
                paragraph = paragraph:match("^%s*(.-)%s*$")
                if paragraph ~= "" then
                    local percent = not hit and paragraph:match("^(%d+%%)")
                    if percent then hit = percent else paragraphs[#paragraphs + 1] = paragraph end
                end
            end
        end
        if tooltip.AdditionalText:IsShown() then
            local extra = Plain(tooltip.AdditionalText:GetText())
            if extra and extra:match("%S") then paragraphs[#paragraphs + 1] = extra end
        end

        local icon = tooltip.AbilityPetType
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, -10)
        icon:SetSize(32, 32)
        local name = tooltip.Name
        Tooltips.StyleFont(name, 14, "text")
        name:ClearAllPoints()
        name:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 56, -10)
        name:SetSize(math.max(1, width - 72), 32)
        name:SetJustifyH("LEFT")
        name:SetJustifyV("MIDDLE")

        local cellWidth = (width - 32) / 3
        local metricsTop = -54
        local cooldownValue = cooldown and (cooldown .. " " .. (tonumber(cooldown) == 1 and L["Round"] or L["Rounds"])) or "--"
        for index, trait in ipairs({{"petCooldown", L["Cooldown"], cooldownValue}, {"petHit", L["Hit"], hit or "--"}}) do
            local x = 16 + (index - 1) * cellWidth
            Text(trait[1] .. "Header", trait[2], 11, "muted", x, metricsTop, cellWidth - 8, "RIGHT")
            Text(trait[1] .. "Value", trait[3], 16, "text", x, metricsTop - 17, cellWidth - 8, "RIGHT")
            bars[index] = bars[index] or {}
            TraitUnderline(bars[index], x, metricsTop - 30, cellWidth - 8)
        end

        local usedDividers = 1
        Divider(1, metricsTop - 46)
        local y = metricsTop - 56
        if #paragraphs > 0 then
            local description = Text("petDescription", table.concat(paragraphs, "\n\n"), 12, "text", 16, y, width - 32, "LEFT")
            description:SetTextColor(1, 0.82, 0)
            description:SetWordWrap(true)
            description:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -16, y)
            local height = description:GetStringHeight()
            if issecretvalue and issecretvalue(height) then height = 14 end
            y = y - math.max(14, height) - 8
        elseif tooltipSkin.petDescription then
            tooltipSkin.petDescription:Hide()
        end

        local rows = {}
        for _, prefix in ipairs({"StrongAgainst", "WeakAgainst"}) do
            local arrow = tooltip[prefix .. "Icon"] or (prefix == "WeakAgainst" and tooltip.bottomFrame)
            local typeIcon, label, typeLabel = tooltip[prefix .. "Type1"], tooltip[prefix .. "Label"], tooltip[prefix .. "Type1Label"]
            if arrow and typeIcon and typeLabel and arrow:IsShown() then
                rows[#rows + 1] = {arrow = arrow, label = label, icon = typeIcon, name = typeLabel}
            end
        end
        if #rows > 0 then
            usedDividers = 2
            Divider(2, y)
            y = y - 10
            for _, row in ipairs(rows) do
                row.arrow:ClearAllPoints()
                row.arrow:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 16, y)
                row.arrow:SetSize(28, 28)
                if row.label then
                    Tooltips.StyleFont(row.label, 12, "muted")
                    row.label:ClearAllPoints()
                    row.label:SetPoint("LEFT", tooltip, "TOPLEFT", 52, y - 14)
                end
                row.icon:ClearAllPoints()
                row.icon:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 84, y)
                row.icon:SetSize(28, 28)
                Tooltips.StyleFont(row.name, 12, "text")
                row.name:ClearAllPoints()
                row.name:SetPoint("LEFT", tooltip, "TOPLEFT", 120, y - 14)
                y = y - 34
            end
        end
        for index = usedDividers + 1, #dividers do
            for _, texture in ipairs(dividers[index]) do texture:Hide() end
        end
        applying = true
        wantedWidth, wantedHeight = width, -y + 14
        tooltip:SetHeight(wantedHeight)
        applying = false
    end
end
