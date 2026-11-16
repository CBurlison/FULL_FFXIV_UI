local methods = {}
local createdFrames = {}
local buildAnchorVisual = assert(loadfile("tests\\support\\MenuTemplates.lua"))()
local function object()
    return setmetatable({scripts = {}, shown = true}, {__index = methods})
end
function CreateFrame(kind, name, parent, template)
    local frame = object()
    createdFrames[#createdFrames + 1] = frame
    frame.parent = parent
    if name then _G[name] = frame end
    if kind == "CheckButton" then frame.Text = object() end
    if template == "UIDropDownMenuTemplate" then frame.entries = {} end
    if template == "FFXIV_AnchorVisualTemplate" then buildAnchorVisual(frame) end
    return frame
end
function methods:CreateFontString() return object() end
function methods:CreateTexture() return object() end
function methods:CreateMaskTexture() return object() end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetPoint() end
function methods:SetMovable() end
function methods:SetFrameStrata() end
function methods:SetFrameLevel() end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetBackdropBorderColor() end
function methods:SetText(text) self.text = text end
function methods:SetFont() end
function methods:SetFontObject() end
function methods:SetTextColor() end
function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetNormalTexture() end
function methods:SetPushedTexture() end
function methods:SetHighlightTexture() self.highlight = object() end
function methods:GetHighlightTexture() return self.highlight end
function methods:SetTexture() end
function methods:SetAllPoints() end
function methods:AddMaskTexture() end
function methods:SetBlendMode() end
function methods:SetAlpha() end
function methods:SetVertexColor() end
function methods:ClearAllPoints() end
function methods:RegisterForDrag() end
function methods:RegisterForClicks() end
function methods:RegisterEvent() end
function methods:EnableMouse() end
function methods:EnableMouseWheel() end
function methods:EnableKeyboard() end
function methods:SetPropagateKeyboardInput() end
function methods:SetWordWrap() end
function methods:Hide() self.shown = false end
function methods:SetShown(value) self.shown = value end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:HookScript(name, callback)
    local old = self.scripts[name]
    self.scripts[name] = function(...) if old then old(...) end; callback(...) end
end
function CreateFont() return object() end
function InCombatLockdown() return false end
function PlaySoundFile() end
UIParent, Minimap, NumberFontNormalSmallGray = object(), object(), object()
SlashCmdList, StaticPopupDialogs = {}, {}
local registered, opened, building, shownPopup
function StaticPopup_Show(name) shownPopup = name end
function IsShiftKeyDown() return true end
Settings = {}
function Settings.RegisterCanvasLayoutCategory(panel, name)
    assert(name == "FFXIV UI")
    return {ID = 42, panel = panel}
end
function Settings.RegisterAddOnCategory(category) registered = category end
function Settings.OpenToCategory(id) opened = id end
function UIDropDownMenu_SetWidth(frame, width) frame.width = width end
function UIDropDownMenu_SetText(frame, text) frame.text = text end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton(info)
    building.entries[#building.entries + 1] = info
end
function UIDropDownMenu_Initialize(frame, callback)
    frame.initialize, frame.entries, building = callback, {}, frame
    -- Native initialization immediately calls the builder, before subsequent TOC files load.
    callback(frame, 1)
    building = nil
end
table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
local namespace = {Profiles = {GetAnchors = function() return nil end}}
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", namespace)
assert(namespace.GetInventoryLayout == nil)
assert(loadfile("FFXIV_UI\\General\\FFXIV_UI_Menu.lua"))("FFXIV_UI", namespace)
assert(namespace.GetInventoryLayout == nil, "test must construct settings before the inventory module")
assert(registered and registered.panel.name == "FFXIV UI", "settings category was not registered")
assert(FFXIVUIMinimapButton and FFXIVUIMinimapButton.scripts.OnClick, "minimap handler was not installed")
FFXIVUIMinimapButton.scripts.OnClick(FFXIVUIMinimapButton, "LeftButton")
assert(opened == registered.ID, "minimap did not open the registered options category")
assert(FFXIV_UI_InventoryLayoutDropdown.initialize == nil, "inventory dropdown initialized before its API loaded")
assert(SlashCmdList.FFXIVUIRESET == nil, "anchor reset must not be exposed as a slash command")
assert(type(StaticPopupDialogs.FFXIV_UI_RESET_ANCHORS.OnAccept) == "function", "anchor reset confirmation is missing")
local resetButton
for _, frame in ipairs(createdFrames) do
    if frame.text == "Reset All Anchors" then resetButton = frame end
end
assert(resetButton, "settings reset button was not created")
resetButton.scripts.OnClick()
assert(shownPopup == "FFXIV_UI_RESET_ANCHORS", "settings reset did not ask for confirmation")
shownPopup = nil
FFXIVUIMinimapButton.scripts.OnClick(FFXIVUIMinimapButton, "RightButton")
assert(shownPopup == nil, "Shift-right-click opened the anchor reset confirmation")
print("PASS full menu registers options and minimap click handler before inventory API exists")

local visual
for _, frame in ipairs(createdFrames) do
    if frame.parent == FFXIV_UI_Anchors.ExpBar and frame.nameText then visual = frame end
end
assert(visual, "anchor visual was not built from its XML template")
local nameText, percentText, inc, dec = visual.nameText, visual.percentText, visual.btnInc, visual.btnDec
assert(nameText.font == "GameFontNormalSmall" and nameText.text == "Experience Bar", "name text lost its template or label")
assert(nameText.points[1].point == "TOPLEFT" and nameText.points[1].x == 4 and nameText.points[1].y == -4, "name text anchor changed")
assert(percentText.font == "GameFontNormalSmall" and percentText.text == "100%", "percent text lost its template or value")
assert(percentText.points[1].point == "TOPRIGHT" and percentText.points[1].x == -4 and percentText.points[1].y == -4, "percent text anchor changed")
assert(inc.width == 25 and inc.height == 25 and inc.points[1].point == "CENTER" and inc.points[1].x == -14 and inc.points[1].y == 0, "increase button geometry changed")
assert(dec.width == 25 and dec.height == 25 and dec.points[1].point == "CENTER" and dec.points[1].x == 14 and dec.points[1].y == 0, "decrease button geometry changed")
assert(inc.normalFile:find("Plus.tga", 1, true) and inc.pushedFile == inc.normalFile and inc.highlightFile == inc.normalFile and inc.highlightAlphaMode == "ADD", "increase textures changed")
assert(dec.normalFile:find("Minus.tga", 1, true) and dec.pushedFile == dec.normalFile and dec.highlightFile == dec.normalFile and dec.highlightAlphaMode == "ADD", "decrease textures changed")
assert(inc.scripts.OnClick and dec.scripts.OnClick, "anchor scale buttons lost their handlers")
print("PASS anchor visual builds name, percent and scale buttons from XML template")

assert(loadfile("FFXIV_UI\\General\\Inventory.lua"))("FFXIV_UI", namespace)
local dropdown = FFXIV_UI_InventoryLayoutDropdown
dropdown.scripts.OnShow(dropdown)
assert(dropdown.text == "Unified grid" and #dropdown.entries == 2 and dropdown.entries[1].checked)
dropdown.entries[2].func()
assert(namespace.GetInventoryLayout() == "bags" and dropdown.text == "Per-bag grids")
assert(FFXIV_UI_DB.inventoryLayout == "bags")
dropdown.scripts.OnShow(dropdown)
assert(#dropdown.entries == 2 and dropdown.entries[2].checked and not dropdown.entries[1].checked)
dropdown.entries[1].func()
assert(namespace.GetInventoryLayout() == "unified" and dropdown.text == "Unified grid")
FFXIVUIMinimapButton.scripts.OnClick(FFXIVUIMinimapButton, "LeftButton")
assert(opened == registered.ID)
print("PASS inventory dropdown initializes on show, restores selection and switches both layouts")
