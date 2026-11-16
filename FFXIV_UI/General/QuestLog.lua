 
local addonName, addonEnv = ...

local FONT = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisMedium.ttf"
local ICON_ROOT = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Quests\\"
local GOLD = {1, 0.86, 0.55}
local BLUE = {0.66, 0.9, 1}
local modules, skins = {}, setmetatable({}, {__mode = "k"})
local poiHooks = setmetatable({}, {__mode = "k"})
local poiRegionHooks = setmetatable({}, {__mode = "k"})
local hiddenPOIRegions = setmetatable({}, {__mode = "k"})
local pending, reported = false, false
local HEADER_SIZE = 12
local LINE_SIZE = 10
local ARROW_SIZE = 14
local QUEST_ICON_COLUMN_CENTER = -16
local QUEST_ICON_COLUMN_GAP = 4
local QUEST_ITEM_BUTTON_SIZE = 26

local questCache = {}
addonEnv.QuestCache = {
    Get = function(_, questID)
        if not questID then return {isRepeatable = false} end
        local entry = questCache[questID]
        if not entry then
            entry = {isRepeatable = C_QuestLog.IsRepeatableQuest(questID) == true}
            questCache[questID] = entry
        end
        return entry
    end,
}
local QuestCache = addonEnv.QuestCache

local function IsQuestBlock(block)
    return block and modules[block.parentModule] == true
end

local function StyleText(text, size, color)
    text:SetFont(FONT, size, "OUTLINE")
    text:SetTextColor(unpack(color))
    text:SetShadowColor(0.08, 0.12, 0.16, 1)
    text:SetShadowOffset(1, -1)
    text:SetJustifyH("RIGHT")
end

local function SaveRegion(skin, region, isText, saveSize)
    if skin.regions[region] then return end
    local state = {alpha = region:GetAlpha(), points = {}}
    for index = 1, region:GetNumPoints() do state.points[index] = {region:GetPoint(index)} end
    if saveSize then state.size = {region:GetSize()} end
    if isText then
        state.font = {region:GetFont()}
        state.color = {region:GetTextColor()}
        state.shadow = {region:GetShadowColor()}
        state.shadowOffset = {region:GetShadowOffset()}
        state.justify = region:GetJustifyH()
    end
    skin.regions[region] = state
end

local function RestoreRegion(skin, region)
    local state = skin.regions[region]
    if not state then return end
    region:SetAlpha(state.alpha)
    if state.size then region:SetSize(unpack(state.size)) end
    region:ClearAllPoints()
    for _, point in ipairs(state.points) do region:SetPoint(unpack(point)) end
    if state.font then
        region:SetFont(unpack(state.font))
        region:SetTextColor(unpack(state.color))
        region:SetShadowColor(unpack(state.shadow))
        region:SetShadowOffset(unpack(state.shadowOffset))
        region:SetJustifyH(state.justify)
    end
    skin.regions[region] = nil
end

local function RestoreRegions(skin)
    for region in pairs(skin.regions) do RestoreRegion(skin, region) end
    for arrow in pairs(skin.arrows) do arrow:Hide() end
    skin.arrows = {}
end

local function RestorePOI(skin)
    if skin.poiRegions then
        for region, state in pairs(skin.poiRegions) do
            hiddenPOIRegions[region] = nil
            region:SetAlpha(state.alpha)
            region:SetShown(state.shown)
        end
    end
    skin.poiRegions, skin.poi = nil, nil
end

local function HidePOIRegion(skin, region)
    if not skin.poiRegions[region] then
        skin.poiRegions[region] = {alpha = region:GetAlpha(), shown = region:IsShown()}
    end
    hiddenPOIRegions[region] = true
    if not poiRegionHooks[region] then
        local function KeepHidden(self)
            if hiddenPOIRegions[self] then self:Hide() end
        end
        hooksecurefunc(region, "Show", KeepHidden)
        hooksecurefunc(region, "SetShown", KeepHidden)
        poiRegionHooks[region] = true
    end
    -- Alpha animations on the native POI can override SetAlpha(0).
    region:Hide()
end

local function UpdateColors(block)
    local skin = skins[block]
    if not skin or not IsQuestBlock(block) then return end
    local selected = block.isHighlighted or block.poiIsSuperTracked
    local quest = QuestCache:Get(block.id)
    local icon = block.poiIsComplete and "CompleteQuest"
        or (quest.isRepeatable and "RepeatableQuest" or "IncompleteQuest")
    skin.icon:SetTexture(ICON_ROOT .. icon .. (selected and "_Blue_Icon.tga" or "_Icon.tga"))
    StyleText(block.HeaderText, HEADER_SIZE, GOLD)
    for _, line in pairs(block.usedLines) do
        if line.Text then StyleText(line.Text, LINE_SIZE, BLUE) end
    end
end

local function UpdateObjectiveIndicator(line)
    local block = line.parentBlock
    local skin = block and skins[block]
    local arrow = line.FFXIVUIQuestArrow
    if not arrow then return end
    local isCheck = line.SetState and line.Icon
    arrow:SetShown(IsQuestBlock(block) and skin and skin.arrows[arrow]
        and (not line.Icon or (isCheck and not line.Icon:IsShown())) or false)
end

local function GetHeaderHeight(block)
    local height = block.HeaderText:GetStringHeight()
    if not height or height <= 0 then height = HEADER_SIZE end
    return height
end

local function RefreshWrappedHeaderHeight(block)
    addonEnv.DeferOutsideSecureUpdate(block, "refreshWrappedHeaderHeight", function()
        if InCombatLockdown() then pending = true; return end
        local header = block.HeaderText
        local previousHeight = header:GetHeight()
        header:SetHeight(0)
        header:SetText(header:GetText())
        local updatedHeight = header:GetHeight()
        local heightDelta = updatedHeight - previousHeight
        if heightDelta ~= 0 then
            block.height = block.height + heightDelta
            block:SetHeight(block.height)
            local module = block.parentModule
            module.contentsHeight = module.contentsHeight + heightDelta
            module:UpdateHeight()
            module:MarkDirty()
        end
    end)
end

local function SetHeaderRightInset(block, skin, inset)
    local header = block.HeaderText
    local state = skin.regions[header]
    local hasRightAnchor = false
    header:ClearAllPoints()
    if state then
        for _, point in ipairs(state.points) do
            if point[1] == "RIGHT" then
                header:SetPoint("RIGHT", block, "RIGHT", inset, 0)
                hasRightAnchor = true
            else
                header:SetPoint(unpack(point))
            end
        end
    end
    if not hasRightAnchor then header:SetPoint("RIGHT", block, "RIGHT", inset, 0) end
end

local function StyleItemButtonRegion(skin, button, region, size)
    if not region then return end
    SaveRegion(skin, region, false, true)
    region:ClearAllPoints()
    region:SetSize(size, size)
    region:SetPoint("CENTER", button)
end

local function StyleQuestItemButton(block, skin, headerHeight)
    local button = block.ItemButton
    if not button then return nil end
    SaveRegion(skin, button)
    local width = button:GetWidth()
    if not width or width <= 0 then width = QUEST_ITEM_BUTTON_SIZE end
    local center = QUEST_ICON_COLUMN_CENTER - 8 - QUEST_ICON_COLUMN_GAP - width / 2
    button:ClearAllPoints()
    button:SetPoint("CENTER", block, "TOPRIGHT", center, -headerHeight / 2)

    local iconSize = math.min(width, headerHeight + 4)
    local frameSize = math.min(width, iconSize + 4)
    StyleItemButtonRegion(skin, button, button.icon, iconSize)
    StyleItemButtonRegion(skin, button, button.NormalTexture, frameSize)
    StyleItemButtonRegion(skin, button, button.PushedTexture, frameSize)
    return center - width / 2 - QUEST_ICON_COLUMN_GAP
end

local function StyleLine(block, key)
    if not IsQuestBlock(block) then return end
    if InCombatLockdown() then pending = true; return end
    local line = block:GetExistingLine(key)
    if not line or not line.Text then return end
    local skin = skins[block]
    SaveRegion(skin, line.Text, true)
    if line.Dash then SaveRegion(skin, line.Dash) end
    if line.Icon then SaveRegion(skin, line.Icon) end
    StyleText(line.Text, LINE_SIZE, BLUE)
    line.Text:ClearAllPoints()
    line.Text:SetPoint("TOPLEFT", line, "TOPLEFT")
    line.Text:SetPoint("RIGHT", block, "RIGHT", QUEST_ICON_COLUMN_CENTER - 14 - QUEST_ICON_COLUMN_GAP, 0)
    if line.Dash then line.Dash:SetAlpha(0) end
    if not line.FFXIVUIQuestArrow then
        local arrow = line:CreateTexture(nil, "OVERLAY")
        arrow:SetTexture(ICON_ROOT .. "ObjectiveIndicator.tga")
        arrow:SetSize(ARROW_SIZE, ARROW_SIZE)
        line.FFXIVUIQuestArrow = arrow
        if line.SetState and line.Icon then
            hooksecurefunc(line.Icon, "Show", function() UpdateObjectiveIndicator(line) end)
            hooksecurefunc(line.Icon, "Hide", function() UpdateObjectiveIndicator(line) end)
        end
    end
    skin.arrows[line.FFXIVUIQuestArrow] = true
    line.FFXIVUIQuestArrow:ClearAllPoints()
    line.FFXIVUIQuestArrow:SetPoint("CENTER", line, "RIGHT",
        QUEST_ICON_COLUMN_CENTER - (block.rightEdgeOffset or 0), 0)
    UpdateObjectiveIndicator(line)
    if line.Icon then
        line.Icon:ClearAllPoints()
        line.Icon:SetPoint("CENTER", line, "RIGHT",
            QUEST_ICON_COLUMN_CENTER - (block.rightEdgeOffset or 0), 0)
    end
end

local function StyleBlockLayout(block)
    if not IsQuestBlock(block) then return end
    if InCombatLockdown() then pending = true; return end
    local skin = skins[block]
    UpdateColors(block)
    local headerHeight = GetHeaderHeight(block)
    local headerRightInset = StyleQuestItemButton(block, skin, headerHeight)
    if not headerRightInset then
        headerRightInset = QUEST_ICON_COLUMN_CENTER - 14 - QUEST_ICON_COLUMN_GAP
    end
    SetHeaderRightInset(block, skin, headerRightInset)
    RefreshWrappedHeaderHeight(block)
    skin.icon:ClearAllPoints()
    skin.icon:SetPoint("CENTER", block, "TOPRIGHT", QUEST_ICON_COLUMN_CENTER, -headerHeight / 2)
    skin.icon:Show()
    if skin.poi ~= block.poiButton then RestorePOI(skin) end
    local button = block.poiButton
    if button then
        if not skin.poiRegions then
            skin.poi, skin.poiRegions = button, {}
        end
        for _, region in ipairs({button:GetRegions()}) do HidePOIRegion(skin, region) end
        if button.Display then
            for _, region in ipairs({button.Display:GetRegions()}) do HidePOIRegion(skin, region) end
        end
        button:ClearAllPoints()
        button:SetPoint("CENTER", skin.icon, "CENTER")
        if not poiHooks[button] then
            button:HookScript("OnEnter", function(self)
                local owner = self:GetParent()
                if IsQuestBlock(owner) and skins[owner] then
                    skins[owner].icon:SetTexture(ICON_ROOT ..
                        (owner.poiIsComplete and "CompleteQuest" or (QuestCache:Get(owner.id).isRepeatable and "RepeatableQuest" or "IncompleteQuest")) ..
                        "_Blue_Icon.tga")
                end
            end)
            button:HookScript("OnLeave", function(self) UpdateColors(self:GetParent()) end)
            poiHooks[button] = true
        end
    end
end

local function MarkTrackerDirty(module)
    addonEnv.DeferOutsideSecureUpdate(module, "markDirty", function() module:MarkDirty() end)
end

local function PrepareBlock(module, id, template)
    if InCombatLockdown() then pending = true; return end
    local block = module:GetExistingBlock(id, template)
    if not block or not block.HeaderText then return end
    if block.rightEdgeOffset == 0 and not block.lastRegion then
        block:AdjustRightEdgeOffset(-34)
        MarkTrackerDirty(module)
    end
    if not skins[block] then
        local skin = {icon = block:CreateTexture(nil, "OVERLAY"), regions = {}, arrows = {}}
        skin.icon:SetSize(28, 28)
        skins[block] = skin
        hooksecurefunc(block, "GetLine", StyleLine)
        hooksecurefunc(block, "FreeLine", function(self, line)
            RestoreRegion(skin, line.Text)
            if line.Dash then RestoreRegion(skin, line.Dash) end
            if line.Icon then RestoreRegion(skin, line.Icon) end
            if line.FFXIVUIQuestArrow then
                line.FFXIVUIQuestArrow:Hide()
                skin.arrows[line.FFXIVUIQuestArrow] = nil
            end
        end)
        hooksecurefunc(block, "SetStringText", function(self, text)
            if IsQuestBlock(self) then
                SaveRegion(skins[self], text, true)
                StyleText(text, text == self.HeaderText and HEADER_SIZE or LINE_SIZE, text == self.HeaderText and GOLD or BLUE)
            end
        end)
        hooksecurefunc(block, "UpdateHighlight", UpdateColors)
        hooksecurefunc(block, "OnLayout", StyleBlockLayout)
        hooksecurefunc(block, "Free", function(self)
            skin.icon:Hide()
            RestorePOI(skin)
            RestoreRegions(skin)
        end)
    end
    SaveRegion(skins[block], block.HeaderText, true)
    StyleText(block.HeaderText, HEADER_SIZE, GOLD)
end

-- Blizzard's tracker update chain is secure; running styling or MarkDirty from inside it taints
-- the chain's later reads (e.g. scenario aura checks), so this work runs in a fresh execution.
local function Install()
    if not QuestObjectiveTracker then return end
    if not QuestObjectiveTracker.GetBlock or not QuestObjectiveTracker.GetExistingBlock then
        if not reported then
            print("FFXIV UI: Quest tracker styling unavailable: unsupported tracker layout.")
            reported = true
        end
        return
    end
    if InCombatLockdown() then pending = true; return end
    for _, module in ipairs({QuestObjectiveTracker, CampaignQuestObjectiveTracker}) do
        if not modules[module] then
            modules[module] = true
            hooksecurefunc(module, "GetBlock", function(owner, id, template)
                addonEnv.DeferOutsideSecureUpdate(owner, id, function() PrepareBlock(owner, id, template) end)
            end)
            if module.Header and module.Header.Text then
                StyleText(module.Header.Text, HEADER_SIZE, GOLD)
                for _, key in ipairs({"Background", "Shine", "Glow"}) do
                    if module.Header[key] then module.Header[key]:SetTexture(nil) end
                end
            end
            MarkTrackerDirty(module)
        end
    end
end

local handlers = {
    ADDON_LOADED = function() Install() end,
    PLAYER_LOGIN = Install,
    PLAYER_ENTERING_WORLD = Install,
    PLAYER_REGEN_ENABLED = function()
        Install()
        if pending then
            pending = false
            for module in pairs(modules) do MarkTrackerDirty(module) end
        end
    end,
}
local watcher = CreateFrame("Frame")
for event in pairs(handlers) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(self, event, ...)
    handlers[event](self, ...)
end)