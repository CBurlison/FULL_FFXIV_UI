local methods, watcher = {}, nil
local combat, secureUpdate = false, false
local function object()
    return setmetatable({points = {}, scripts = {}, alpha = 1, shown = true,
        font = "NativeFont", size = 12, flags = "", justify = "LEFT",
        color = {1, 1, 1, 1}, shadow = {0, 0, 0, 1}, shadowOffset = {0, 0}}, {__index = methods})
end
function methods:GetFont() return self.font, self.size, self.flags end
function methods:GetText() return self.text end
function methods:GetTextColor() return unpack(self.color) end
function methods:GetShadowColor() return unpack(self.shadow) end
function methods:GetShadowOffset() return unpack(self.shadowOffset) end
function methods:GetJustifyH() return self.justify end
function methods:GetNumPoints() return #self.points end
function methods:GetPoint(index) return unpack(self.points[index]) end
function methods:GetSize() return self.width or 0, self.height or 0 end
function methods:GetWidth() return self.width or 0 end
function methods:GetHeight() return self.height or 0 end
function methods:GetStringHeight() return self.stringHeight or self.size end
function methods:SetFont(path, size, flags) self.font, self.size, self.flags = path, size, flags end
function methods:SetTextColor(...) self.color = {...} end
function methods:SetShadowColor(...) self.shadow = {...} end
function methods:SetShadowOffset(...) self.shadowOffset = {...} end
function methods:SetJustifyH(value) self.justify = value end
function methods:SetText(value)
    self.text = value
    if self.height == 0 then self.height = self.stringHeight or self.size end
end
function methods:SetTexture(value) self.texture = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:GetAlpha() return self.alpha end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetHeight(value) self.height = value end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:ClearAllPoints() self.points = {} end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetShown(value) self.shown = value end
function methods:IsShown() return self.shown end
function methods:GetParent() return self.parent end
function methods:HookScript(name, callback)
    local old = self.scripts[name]
    self.scripts[name] = function(...)
        if old then old(...) end
        callback(...)
    end
end
function methods:CreateTexture() return object() end
function methods:CreateFontString() return object() end
function methods:RegisterEvent() end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:GetRegions() return self.region end
function CreateFrame()
    watcher = object()
    return watcher
end
function InCombatLockdown() return combat end
function hooksecurefunc(target, name, callback)
    local original = assert(target[name], name)
    target[name] = function(...)
        local result = original(...)
        callback(...)
        return result
    end
end
C_QuestLog = C_QuestLog or {}
C_QuestLog.IsRepeatableQuest = function(id) return id == 2 end
local function module()
    local result = object()
    result.Header = {Text = object(), Background = object(), Shine = object(), Glow = object()}
    result.blocks = {}
    result.contentsHeight = 0
    function result:MarkDirty() self.dirty = (self.dirty or 0) + 1 end
    function result:UpdateHeight() self.height = self.contentsHeight end
    function result:GetExistingBlock(id)
        assert(not secureUpdate, "block lookup ran inside the secure tracker update")
        return self.blocks[id]
    end
    function result:GetBlock(id)
        local block = self.blocks[id]
        if block.rightEdgeOffset == nil then block.rightEdgeOffset = 0 end
        return block
    end
    return result
end
local function block(module, id)
    local result = object()
    result.parentModule, result.id = module, id
    result.HeaderText, result.usedLines = object(), {}
    result.HeaderText.height, result.height = result.HeaderText.size, result.HeaderText.size
    function result:AdjustRightEdgeOffset(offset)
        assert(not secureUpdate, "block layout mutation ran inside the secure tracker update")
        assert(not self.lastRegion, "AdjustRightEdgeOffset after lines were added")
        self.rightEdgeOffset = self.rightEdgeOffset + offset
    end
    function result:GetExistingLine(key) return self.usedLines[key] end
    function result:GetLine(key)
        local line = self.usedLines[key]
        if not line then
            line = object()
            line.Text, line.Dash = object(), object()
            line.Icon = object()
            line.Icon:Hide()
            line.parentBlock = self
            line:SetPoint("TOPLEFT", self.HeaderText, "BOTTOMLEFT", 0, -4)
            function line:SetState(complete)
                if complete then self.Icon:Show() else self.Icon:Hide() end
            end
            self.usedLines[key] = line
        end
        return line
    end
    function result:SetStringText(text, value)
        text:SetText(value)
        text:SetTextColor(1, 1, 0)
        self.measuredSize = text.size
    end
    function result:UpdateHighlight() self.HeaderText:SetTextColor(1, 1, 1) end
    function result:OnLayout() end
    function result:FreeLine(line)
        for key, value in pairs(self.usedLines) do
            if value == line then self.usedLines[key] = nil end
        end
    end
    function result:Free()
        self.usedLines = {}
        self.poiButton = nil
    end
    result.poiButton = object()
    result.poiButton.parent = result
    result.poiButton.region = object()
    result.poiButton.Display = {region = object(), GetRegions = methods.GetRegions}
    result.poiButton.scripts.OnEnter = function(self) self.nativeEnter = true end
    module.blocks[id] = result
    return result
end
local deferred, deferredWork = {}, setmetatable({}, {__mode = "k"})
local function flush()
    local queue = deferred
    deferred = {}
    for _, callback in ipairs(queue) do callback() end
end
local env = {DeferOutsideSecureUpdate = function(owner, tag, callback)
    local tags = deferredWork[owner]
    if not tags then tags = {}; deferredWork[owner] = tags end
    if tags[tag] then return end
    tags[tag] = true
    deferred[#deferred + 1] = function()
        tags[tag] = nil
        callback()
    end
end}
assert(loadfile("FFXIV_UI\\General\\QuestLog.lua"))("FFXIV_UI", env)
local function event(name, ...) watcher.scripts.OnEvent(watcher, name, ...); flush() end
local function getBlock(module, id)
    secureUpdate = true
    module:GetBlock(id)
    secureUpdate = false
end
event("ADDON_LOADED", "FFXIV_UI")
QuestObjectiveTracker, CampaignQuestObjectiveTracker = module(), nil
local normal = block(QuestObjectiveTracker, 1)
event("PLAYER_LOGIN")
assert(QuestObjectiveTracker.dirty == 1 and not CampaignQuestObjectiveTracker)
event("PLAYER_ENTERING_WORLD")
assert(QuestObjectiveTracker.dirty == 1)
assert(QuestObjectiveTracker.Header.Text.flags == "OUTLINE")
assert(QuestObjectiveTracker.Header.Text.justify == "RIGHT")
CampaignQuestObjectiveTracker = module()
local repeatable = block(CampaignQuestObjectiveTracker, 2)
event("ADDON_LOADED", "Blizzard_ObjectiveTracker")
assert(CampaignQuestObjectiveTracker.dirty == 1)
print("PASS: tracker installs at login, handles late campaign loading, and styles headers")

getBlock(QuestObjectiveTracker, 1)
assert(normal.rightEdgeOffset == 0, "block layout must not be inspected or changed inline")
flush()
assert(normal.rightEdgeOffset == -34, "icon column must be reserved before lines are added")
assert(normal.rightEdgeOffset == -34 and normal.HeaderText.size == 12)
normal:SetStringText(normal.HeaderText, "Quest title")
assert(normal.measuredSize == 12 and normal.HeaderText.color[2] == 0.86)
local line = normal:GetLine(1)
normal:SetStringText(line.Text, "Collect 0/5")
assert(normal.measuredSize == 10 and line.Text.color[3] == 1 and line.Text.color[1] == 0.66)
assert(line.Text.justify == "RIGHT" and line.Text.flags == "OUTLINE" and line.Dash.alpha == 0)
assert(line.FFXIVUIQuestArrow.shown and line.FFXIVUIQuestArrow.texture:match("ObjectiveIndicator.tga$"))
assert(line.FFXIVUIQuestArrow.width == 14 and line.FFXIVUIQuestArrow.points[1][1] == "CENTER")
assert(line.FFXIVUIQuestArrow.points[1][3] == "RIGHT" and line.FFXIVUIQuestArrow.points[1][4] == 18)
assert(line.Text.points[2][2] == normal and line.Text.points[2][4] == -34)
line:SetState(true)
assert(line.Icon.shown and not line.FFXIVUIQuestArrow.shown)
assert(line.Icon.points[1][3] == "RIGHT" and line.Icon.points[1][4] == 18)
line:SetState(false)
assert(not line.Icon.shown and line.FFXIVUIQuestArrow.shown)
print("PASS: extracted indicator appears on the right and is replaced by the native check on completion")
normal:OnLayout()
local icon = normal.poiButton.points[1][2]
assert(icon.texture:match("IncompleteQuest_Icon.tga$"))
assert(not normal.poiButton.region.shown and not normal.poiButton.Display.region.shown)
assert(icon.points[1][1] == "CENTER" and icon.points[1][3] == "TOPRIGHT")
assert(icon.points[1][4] == -16)
local noItemHeaderRight = normal.HeaderText.points[#normal.HeaderText.points]
assert(noItemHeaderRight[1] == "RIGHT" and noItemHeaderRight[4] == -34)
print("PASS: fonts are set before measurement, icons reserve width, and objectives are blue/right-aligned")

normal.HeaderText.height, normal.HeaderText.stringHeight = 12, 24
normal.height = 40
QuestObjectiveTracker.contentsHeight = 40
local dirtyBeforeWrappedHeader = QuestObjectiveTracker.dirty
assert(line.points[1][2] == normal.HeaderText, "first objective must remain anchored below the title")
normal:OnLayout()
flush()
flush()
assert(normal.HeaderText.height == 24, "wrapped header height must be refreshed after layout")
assert(normal.height == 52 and normal:GetHeight() == 52,
    "block height must include the wrapped header's additional row")
assert(QuestObjectiveTracker.contentsHeight == 52 and QuestObjectiveTracker.height == 52,
    "tracker height must include the wrapped header's additional row")
assert(QuestObjectiveTracker.dirty > dirtyBeforeWrappedHeader,
    "tracker must relayout so blocks below the wrapped quest move down: "
        .. tostring(dirtyBeforeWrappedHeader) .. " -> " .. tostring(QuestObjectiveTracker.dirty))
print("PASS: wrapped quest titles reserve height for their first objective")
normal.HeaderText.height, normal.HeaderText.stringHeight, normal.height = 12, nil, 12
QuestObjectiveTracker.contentsHeight, QuestObjectiveTracker.height = 0, nil

for _, region in ipairs({normal.poiButton.region, normal.poiButton.Display.region}) do
    region:SetAlpha(1)
    region:Show()
    assert(not region.shown, "native POI Show restored old quest artwork")
    region:SetShown(true)
    assert(not region.shown, "native POI SetShown restored old quest artwork")
end
assert(icon.shown, "native artwork suppression hid custom icon")
print("PASS: acceptance/completion alpha and visibility refreshes cannot reveal native POI artwork")

normal.poiIsSuperTracked = true
normal:OnLayout()
assert(icon.texture:match("IncompleteQuest_Blue_Icon.tga$"))
normal.poiIsComplete = true
normal:OnLayout()
assert(icon.texture:match("CompleteQuest_Blue_Icon.tga$"))
normal.poiIsSuperTracked = false
normal.isHighlighted = true
normal:UpdateHighlight()
assert(icon.texture:match("CompleteQuest_Blue_Icon.tga$"))
normal.isHighlighted = false
normal:UpdateHighlight()
assert(icon.texture:match("CompleteQuest_Icon.tga$"))
normal.poiButton.scripts.OnEnter(normal.poiButton)
assert(normal.poiButton.nativeEnter and icon.texture:match("CompleteQuest_Blue_Icon.tga$"))
normal.poiButton.scripts.OnLeave(normal.poiButton)
assert(icon.texture:match("CompleteQuest_Icon.tga$"))
getBlock(CampaignQuestObjectiveTracker, 2)
flush()
repeatable.poiButton.region:Hide()
repeatable:OnLayout()
assert(repeatable.poiButton.points[1][2].texture:match("RepeatableQuest_Icon.tga$"))
local repeatableButton = repeatable.poiButton
repeatable:Free()
assert(not repeatableButton.region.shown, "originally hidden native artwork was revealed on release")
repeatableButton.region:Show()
assert(repeatableButton.region.shown, "released native artwork must be usable by other modules")
print("PASS: completion, repeatable, selected, and hover icon variants update without replacing native interactions")

local withItem = block(QuestObjectiveTracker, 4)
withItem.rightEdgeOffset = -28
local itemButton = object()
itemButton.width, itemButton.height = 26, 26
itemButton.icon, itemButton.NormalTexture, itemButton.PushedTexture = object(), object(), object()
itemButton.icon:SetSize(26, 26)
itemButton.NormalTexture:SetSize(42, 42)
itemButton.PushedTexture:SetSize(42, 42)
itemButton:SetPoint("TOPRIGHT", withItem, "TOPRIGHT", 0, 0)
withItem.ItemButton = itemButton
getBlock(QuestObjectiveTracker, 4)
flush()
withItem:OnLayout()
local headerRight = withItem.HeaderText.points[#withItem.HeaderText.points]
assert(headerRight[1] == "RIGHT", "header must have a right anchor. Current: " .. headerRight[1])
assert(headerRight[4] == -58, "header right inset must be -58.  Current: " .. headerRight[4])
assert(itemButton.points[1][1] == "CENTER", "item button must be centered. Current: " .. itemButton.points[1][1])
assert(itemButton.points[1][4] == -41, "item button must have a horizontal offset of -41. Current: " .. itemButton.points[1][4])
assert(itemButton.width == 26 and itemButton.height == 26, "quest item hit target must keep its native size")
assert(itemButton.icon.width == 16 and itemButton.icon.height == 16, "item button icon must be 16x16. Current: " .. itemButton.icon.width .. "x" .. itemButton.icon.height)
assert(itemButton.NormalTexture.width == 20 and itemButton.PushedTexture.width == 20, "item button textures must be 20x20. Current: " .. itemButton.NormalTexture.width .. "x" .. itemButton.PushedTexture.width)
local itemLine = withItem:GetLine(1)
assert(itemLine.FFXIVUIQuestArrow.points[1][4] == 12)
assert(withItem.poiButton.points[1][2].points[1][4] == -16)
withItem:Free()
assert(itemButton.icon.width == 26 and itemButton.NormalTexture.width == 42)
assert(itemButton.points[1][1] == "TOPRIGHT")
print("PASS: quest item buttons are reduced to title height between the title and aligned quest icon column")

normal:FreeLine(line)
assert(line.Text.font == "NativeFont" and line.Dash.alpha == 1 and not line.FFXIVUIQuestArrow.shown)
line.Icon:Hide()
assert(not line.FFXIVUIQuestArrow.shown)
local otherModule = module()
local otherBlock = block(otherModule, 3)
otherBlock.usedLines[1] = line
line.Text:SetFont("OtherModuleFont", 13, "")
local button = normal.poiButton
normal:Free()
assert(not icon.shown and button.region.alpha == 1 and button.Display.region.alpha == 1)
assert(button.region.shown and button.Display.region.shown)
button.region:Hide()
button.region:Show()
button.Display.region:SetShown(true)
assert(button.region.shown and button.Display.region.shown, "released POI remains suppressed")
assert(normal.HeaderText.font == "NativeFont" and normal.HeaderText.justify == "LEFT")
assert(line.Text.font == "OtherModuleFont")
getBlock(QuestObjectiveTracker, 1)
flush()
assert(normal.rightEdgeOffset == -34)
combat = true
local late = block(QuestObjectiveTracker, 3)
getBlock(QuestObjectiveTracker, 3)
flush()
assert(late.rightEdgeOffset == 0, "protected layout mutation must wait until combat ends")
combat = false
local dirtyBeforeRegen = QuestObjectiveTracker.dirty
event("PLAYER_REGEN_ENABLED")
assert(QuestObjectiveTracker.dirty > dirtyBeforeRegen)
getBlock(QuestObjectiveTracker, 3)
flush()
assert(late.rightEdgeOffset == -34)
print("PASS: pooled POI artwork is restored, icon width never accumulates, and combat layout defers until regen")
assert(otherBlock:GetLine(1).Text.font == "OtherModuleFont")
print("PASS: released objective lines are restored before pool reuse and unrelated objective modules remain unchanged")
