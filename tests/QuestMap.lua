local watcher
local methods = {}
local function object()
    return setmetatable({alpha = 1, shown = true, scripts = {}, textures = {}}, {__index = methods})
end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:GetAlpha() return self.alpha end
function methods:SetTexture(texture) self.texture = texture end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetPoint(...) self.point = {...} end
function methods:Show()
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    self.shown = false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:CreateTexture()
    local texture = object()
    self.textures[#self.textures + 1] = texture
    return texture
end
function methods:HookScript(name, callback)
    local original = self.scripts[name]
    self.scripts[name] = function(...)
        if original then original(...) end
        callback(...)
    end
end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:RegisterEvent() end
function CreateFrame() watcher = object(); return watcher end
function hooksecurefunc(target, name, callback)
    if type(target) == "string" then
        target, name, callback = _G, target, name
    end
    local original = assert(target[name], name)
    target[name] = function(...)
        local result = original(...)
        callback(...)
        return result
    end
end
Enum = {QuestClassification = {Normal = 1, Recurring = 2}}
POIButtonUtil = {Style = {QuestInProgress = 1, QuestComplete = 2, Waypoint = 3, QuestDisabled = 4}}
local addonEnv = {QuestCache = {Get = function(_, id) return {isRepeatable = id == 2} end}}
local function pin(offer)
    local result = object()
    result.questID, result.style = 1, POIButtonUtil.Style.QuestInProgress
    result.Texture, result.NormalTexture = object(), object()
    result.PushedTexture, result.HighlightTexture, result.Display = object(), object(), object()
    function result:GetStyle() return self.style end
    function result:GetQuestID() return self.questID end
    function result:IsSuperTracked() return self.selected end
    function result:SetSelected(selected) self.selected = selected end
    function result:SetSuperTracked(selected) self.selected = selected end
    function result:UpdateButtonAlpha()
        local alpha = self.style == POIButtonUtil.Style.QuestDisabled and 0 or 1
        self.NormalTexture:SetAlpha(alpha)
        self.PushedTexture:SetAlpha(alpha)
    end
    function result:UpdateButtonStyle()
        self.NormalTexture:SetTexture("native")
        self:UpdateButtonAlpha()
    end
    function result:EvaluateManagedHighlight() self.HighlightTexture:SetAlpha(1) end
    function result:OnMouseEnter() self.tooltip = true end
    function result:OnMouseLeave() self.tooltip = false end
    result.scripts.OnEnter = result.OnMouseEnter
    result.scripts.OnLeave = result.OnMouseLeave
    function result:OnAcquired(data)
        self.questID = data.questID
        if offer then
            self.pinAlpha = data.pinAlpha
            self.questClassification = data.questClassification
            self.Texture:SetAlpha(data.pinAlpha)
        end
    end
    return result
end
local map = {pins = {}}
function map:EnumeratePinsByTemplate(template)
    local index = 0
    return function()
        index = index + 1
        return (self.pins[template] or {})[index]
    end
end
function map:AcquirePin(template, data)
    local result = pin(template == "QuestOfferPinTemplate")
    self.pins[template] = self.pins[template] or {}
    table.insert(self.pins[template], result)
    if data then result:OnAcquired(data) end
    return result
end
assert(loadfile("FFXIV_UI\\General\\QuestMap.lua"))("FFXIV_UI", addonEnv)
assert(not WorldMapFrame, "test late-loaded map")
WorldMapFrame = map
watcher.scripts.OnEvent(watcher, "ADDON_LOADED")
local quest = map:AcquirePin("QuestPinTemplate")
local icon = quest.textures[1]
local function expect(name, blue, texture)
    assert((texture or icon).texture:match(name .. (blue and "_Blue" or "") .. "_Icon.tga$"))
end
expect("IncompleteQuest")
assert(icon.width == 32 and icon.height == 32)
assert(quest.NormalTexture.alpha == 0 and quest.Display.alpha == 0)
quest.scripts.OnEnter(quest)
expect("IncompleteQuest", true)
assert(quest.tooltip, "native hover retained")
quest.scripts.OnLeave(quest)
expect("IncompleteQuest")
assert(not quest.tooltip)
print("PASS active quest and hover")

quest:SetSelected(true)
expect("IncompleteQuest", true)
quest.scripts.OnEnter(quest)
quest.scripts.OnLeave(quest)
expect("IncompleteQuest", true)
quest:SetSelected(false)
quest.questID = 2
quest:UpdateButtonStyle()
expect("RepeatableQuest")
quest.style = POIButtonUtil.Style.QuestComplete
quest:UpdateButtonStyle()
expect("CompleteQuest")
quest:EvaluateManagedHighlight()
assert(quest.HighlightTexture.alpha == 0)
print("PASS selected, repeatable, complete and refresh")

quest.style = POIButtonUtil.Style.Waypoint
quest:UpdateButtonStyle()
assert(not icon.shown and quest.Display.alpha == 1 and quest.NormalTexture.alpha == 1)
quest.style = POIButtonUtil.Style.QuestDisabled
quest:UpdateButtonStyle()
assert(not icon.shown and quest.NormalTexture.alpha == 0)
quest.style = POIButtonUtil.Style.QuestInProgress
quest:UpdateButtonStyle()
quest.scripts.OnEnter(quest)
quest:Hide()
assert(not icon.shown and quest.Display.alpha == 1)
quest:Show()
assert(icon.shown and quest.Display.alpha == 0, "reopening map reapplies artwork")
quest:OnAcquired({questID = 1})
quest:UpdateButtonStyle()
expect("IncompleteQuest")
assert(#quest.textures == 1, "pooled pin must not duplicate icon")
print("PASS waypoint, disabled style and pooled reuse")

local offer = map:AcquirePin("QuestOfferPinTemplate", {
    questID = 3, pinAlpha = 0.5, questClassification = Enum.QuestClassification.Normal,
})
local offerIcon = offer.textures[1]
expect("NewQuest", false, offerIcon)
assert(offer.Texture.alpha == 0 and offerIcon.alpha == 0.5)
offer:SetSuperTracked(true)
expect("NewQuest", true, offerIcon)
offer:SetSuperTracked(false)
offer:OnAcquired({questID = 4, pinAlpha = 1, questClassification = Enum.QuestClassification.Recurring})
expect("RepeatableQuest", false, offerIcon)
assert(offerIcon.alpha == 1)
offer.scripts.OnEnter(offer)
expect("RepeatableQuest", true, offerIcon)
offer.scripts.OnLeave(offer)
expect("RepeatableQuest", false, offerIcon)
offer:Hide()
assert(not offerIcon.shown and offer.Texture.alpha == 1)
print("PASS available and recurring offers, fading and selection")

local unrelated = map:AcquirePin("WorldQuestPinTemplate")
assert(#unrelated.textures == 0)
local acquire = map.AcquirePin
watcher.scripts.OnEvent(watcher, "PLAYER_LOGIN")
assert(map.AcquirePin == acquire, "install must be idempotent")
watcher.scripts.OnEvent(watcher, "SUPER_TRACKING_CHANGED")
assert(#quest.textures == 1)
print("PASS unrelated pins and event installation")

local logButton = pin()
local title = object()
title.questID = 1
title.scripts.OnEnter = function(self) self.tooltip = true end
title.scripts.OnLeave = function(self) self.tooltip = false end
local function pool(values)
    return {EnumerateActive = function()
        local index = 0
        return function()
            index = index + 1
            return values[index]
        end
    end}
end
QuestScrollFrame = {
    Contents = {
        buttonPool = pool({logButton}),
        FindButtonByQuestID = function(_, id)
            if logButton.questID == id then return logButton end
        end,
    },
    titleFramePool = pool({title}),
}
local updates = 0
function QuestLogQuests_Update() updates = updates + 1 end
watcher.scripts.OnEvent(watcher, "ADDON_LOADED")
local logIcon = logButton.textures[1]
expect("IncompleteQuest", false, logIcon)
title.scripts.OnEnter(title)
expect("IncompleteQuest", true, logIcon)
assert(title.tooltip, "native quest-row hover retained")
title.scripts.OnLeave(title)
expect("IncompleteQuest", false, logIcon)
assert(not title.tooltip)
logButton:SetSelected(true)
title.scripts.OnEnter(title)
title.scripts.OnLeave(title)
expect("IncompleteQuest", true, logIcon)
logButton:SetSelected(false)
logButton.style = POIButtonUtil.Style.QuestComplete
QuestLogQuests_Update()
expect("CompleteQuest", false, logIcon)
assert(updates == 1, "native quest list update retained")
logButton:Hide()
logButton.questID = 2
title.questID = 2
logButton.style = POIButtonUtil.Style.QuestInProgress
logButton:Show()
QuestLogQuests_Update()
expect("RepeatableQuest", false, logIcon)
assert(#logButton.textures == 1, "quest-list reuse duplicated icon")
local update = QuestLogQuests_Update
watcher.scripts.OnEvent(watcher, "ADDON_LOADED")
assert(QuestLogQuests_Update == update, "quest-log hook installed twice")
print("PASS full quest log: late load, row hover, selection, completion, repeatable, pooling and native update")
