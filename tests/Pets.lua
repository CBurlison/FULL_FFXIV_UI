local addonName, ns = ...
table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
local objects, methods, combat, timers = {}, {}, false, {}
local pickupCalls = {}
local pets = {}
local ns = {}

local function object(kind, parent)
    local value = setmetatable({kind = kind or "Frame", parent = parent, regions = {}, children = {}, scripts = {},
        points = {}, shown = true, alpha = 1, width = 40, height = 32, level = 5, id = 0},
        {__index = methods})
    objects[#objects + 1] = value
    if parent and (kind == "Texture" or kind == "FontString") then
        parent.regions[#parent.regions + 1] = value
    elseif parent then
        parent.children[#parent.children + 1] = value
    end
    return value
end

function CreateFrame(kind, _, parent)
    return object(kind, parent)
end
function methods:CreateTexture() return object("Texture", self) end
function methods:CreateFontString() return object("FontString", self) end
function methods:GetObjectType() return self.kind end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetChildren() return unpack(self.children) end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(point, rel, relPoint, x, y)
    self.points[#self.points + 1] = {point, rel, relPoint or point, x or 0, y or 0}
end
function methods:SetAllPoints() end
function methods:GetText() return self.text or "" end
function methods:SetText(text)
    self.text = text
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetHeight(height) self.height = height end
function methods:SetWidth(width) self.width = width end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:IsShown() return self.shown end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetShown(shown) self.shown = shown end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:GetAlpha() return self.alpha end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetVertexColor(...) self.vertexColor = {...} end
function methods:SetTexture(texture) self.texture = texture end
function methods:SetDesaturated(desaturated) self.desaturated = desaturated end
function methods:SetChecked(checked) self.checked = checked and true or false end
function methods:GetChecked() return self.checked end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameLevel() return self.level end
function methods:EnableMouseWheel(enabled) self.wheel = enabled end
function methods:SetScrollChild(child) self.scrollChild = child end
function methods:SetVerticalScroll(value) self.verticalScroll = value end
function methods:GetVerticalScroll() return self.verticalScroll or 0 end
function methods:HookScript(name, callback) self.scripts[name] = callback end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
function methods:RegisterForDrag(...) self.dragButtons = {...} end
function methods:SetDrawLayer() end
function methods:SetBlendMode() end

function InCombatLockdown() return combat end
function hooksecurefunc(target, method, callback)
    if type(target) == "string" then
        callback = method
        local original = _G[target]
        _G[target] = function(...)
            local result = original(...)
            callback(...)
            return result
        end
    end
end

C_Timer = {After = function(_, callback) timers[#timers + 1] = callback end}
local function flushTimers()
    while #timers > 0 do table.remove(timers, 1)() end
end

local function fire(event)
    for _, frame in ipairs(objects) do
        if frame.events and frame.events[event] and frame.scripts.OnEvent then
            frame.scripts.OnEvent(frame, event)
        end
    end
end

local function assertEq(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local function petRecord(index, owned, customName)
    return {
        id = owned and ("Pet-" .. index) or nil,
        speciesId = 1000 + index,
        owned = owned,
        customName = customName,
        name = "Pet " .. index,
        icon = 7000 + index,
    }
end
for index = 1, 12 do
    pets[index] = petRecord(index, index % 2 == 1, index == 1 and "Fluffy" or nil)
end

C_PetJournal = {
    GetNumPets = function() return #pets, 6 end,
    GetPetInfoByIndex = function(index)
        local pet = pets[index]
        return pet.id, pet.speciesId, pet.owned, pet.customName, 25, false, false, pet.name, pet.icon
    end,
    PickupPet = function(petId) pickupCalls[#pickupCalls + 1] = petId end,
}
PetJournalPetCard = {petIndex = 3}
function PetJournal_ShowPetCard(index) PetJournalPetCard.petIndex = index end
function PetJournal_UpdatePetList() end
function CollectionsJournal_LoadUI() end
function ToggleCollectionsJournal() end
function CollectionsJournal_SetTab() end

ns.MountGridPosition = function(index)
    local zero = index - 1
    return zero % 5 * 50, -math.floor(zero / 5) * 52
end
ns.ApplyButtonSkin = function(button, parts, style)
    button.skinStyle = style
    button.skinIcon = parts.Icon
end
ns.StyleEditBox = function(box) box.styled = true end
ns.StyleButton = function(button) if button then button.styled = true end end
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", ns)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", ns)

local function makeJournal()
    local journal = object("Frame")
    local pj = object("Frame", journal)
    pj.ScrollBox = object("Frame", pj)
    pj.ScrollBar = object("Frame", pj)
    pj.LeftInset = object("Frame", pj)
    object("Texture", pj.LeftInset)
    pj.LeftInset.NineSlice = object("Frame", pj.LeftInset)
    pj.RightInset = object("Frame", pj)
    object("Texture", pj.RightInset)
    pj.RightInset.NineSlice = object("Frame", pj.RightInset)
    pj.searchBox = object("EditBox", pj)
    _G.PetJournal = pj
    _G.CollectionsJournal = journal
    return pj
end

local function gridOf(pj)
    for _, child in ipairs({pj:GetChildren()}) do
        if child.kind == "ScrollFrame" then return child end
    end
end

local function cellsOf(scroll)
    local cells = {}
    for _, child in ipairs({scroll.scrollChild:GetChildren()}) do
        if child.kind == "CheckButton" then cells[#cells + 1] = child end
    end
    return cells
end

assert(loadfile("FFXIV_UI\\General\\Pets.Lua"))("FFXIV_UI", ns)
local pj = makeJournal()
combat = true
fire("ADDON_LOADED")
flushTimers()
assertEq(gridOf(pj), nil, "combat defers the grid build")
combat = false
fire("PLAYER_REGEN_ENABLED")
flushTimers()

local scroll = gridOf(pj)
assertEq(scroll ~= nil, true, "grid scroll frame built")
assertEq(scroll.wheel, true, "mouse wheel enabled")
assertEq(pj.ScrollBox.shown, false, "native ScrollBox hidden")
assertEq(pj.ScrollBar.shown, false, "native ScrollBar hidden")
assertEq(pj.searchBox.styled, true, "search box styled")

local cells = cellsOf(scroll)
assertEq(#cells, 12, "one cell per journal pet")
assertEq(cells[1].Icon.texture, 7001, "pet icon loaded from journal index")
assertEq(cells[1].Icon.desaturated, false, "owned pet icon stays colored")
assertEq(cells[2].Icon.desaturated, true, "unowned pet icon is desaturated")
assertEq(cells[1].name, "Fluffy", "custom name is displayed")
assertEq(cells[3].checked, true, "selected pet index is checked")
assertEq(cells[1].checked, false, "other pet is unchecked")
assertEq(cells[6].points[1][4], 0, "sixth pet wraps to first column")
assertEq(cells[6].points[1][5], -52, "sixth pet is placed on second row")
assertEq(scroll.scrollChild.height, 3 * 52 - 6, "content height covers all rows")

GameTooltip = {log = {}}
function GameTooltip:SetOwner(owner, anchor) self.log[#self.log + 1] = {"owner", owner, anchor} end
function GameTooltip:SetText(text) self.log[#self.log + 1] = {"text", text} end
function GameTooltip:AddLine(text) self.log[#self.log + 1] = {"line", text} end
function GameTooltip:Show() self.shown = true end
function GameTooltip:Hide() self.shown = false end
cells[2].scripts.OnEnter(cells[2])
assertEq(GameTooltip.log[2][2], "Pet 2", "tooltip shows the pet name")
assertEq(GameTooltip.log[3][2], "Not collected", "unowned tooltip reports collection state")
cells[2].scripts.OnLeave(cells[2])
assertEq(GameTooltip.shown, false, "tooltip hides on leave")

pj.searchBox:SetText("FLUFFY")
assertEq(cells[1].shown, true, "search matches custom pet names")
assertEq(cells[2].shown, false, "search hides non-matching pets")
pj.searchBox:SetText("")
assertEq(cells[2].shown, true, "clearing search shows all pets")

cells[4].scripts.OnClick(cells[4])
assertEq(PetJournalPetCard.petIndex, 4, "click selects the journal index")
assertEq(cells[4].checked, true, "clicked pet becomes selected")

cells[5].scripts.OnDragStart(cells[5])
assertEq(pickupCalls[#pickupCalls], "Pet-5", "drag picks up an owned pet by ID")
local pickupCount = #pickupCalls
cells[2].scripts.OnDragStart(cells[2])
assertEq(#pickupCalls, pickupCount, "unowned species cannot be picked up")

scroll.height = 40
scroll.scripts.OnMouseWheel(scroll, -1)
assertEq(scroll.verticalScroll, 52, "wheel scrolls one row per notch")
scroll.scripts.OnMouseWheel(scroll, -100)
assertEq(scroll.verticalScroll, scroll.scrollChild.height - 40, "wheel clamps at bottom")
scroll.scripts.OnMouseWheel(scroll, 100)
assertEq(scroll.verticalScroll, 0, "wheel clamps at top")

pets[1].name = "Updated Pet"
fire("PET_JOURNAL_LIST_UPDATE")
flushTimers()
assertEq(cells[1].name, "Fluffy", "custom name remains preferred after list update")
pets[1].customName = nil
fire("PET_JOURNAL_LIST_UPDATE")
flushTimers()
assertEq(cells[1].name, "Updated Pet", "list update refreshes pet data")

print("Pets tests passed")
