local addonName, ns = ...
table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
local objects, methods, combat = {}, {}, false
local ns = {}

local function object(kind, parent)
    local value = setmetatable({kind = kind or "Frame", parent = parent, regions = {}, children = {}, scripts = {},
        points = {}, shown = true, alpha = 1, width = 40, height = 32, level = 5},
        {__index = methods})
    objects[#objects + 1] = value
    if parent and (kind == "Texture" or kind == "FontString") then
        parent.regions[#parent.regions + 1] = value
    elseif parent then
        parent.children[#parent.children + 1] = value
    end
    return value
end

local templateSource = assert(io.open("FFXIV_UI\\General\\Talents.xml", "rb")):read("*a")

local function applyTemplate(value, parent, template)
    local kind, attributes, body = templateSource:match('<(%w+) name="' .. template .. '"([^>]-)>(.-)</%1>')
    assert(kind, "Missing Talents template: " .. template)
    assert(kind == value:GetObjectType(), "Unexpected Talents template type: " .. template)
    value.template = template
    if attributes:find('enableMouse="false"', 1, true) then value:EnableMouse(false) end
    local justify = attributes:match('justifyH="([^"]+)"')
    if justify then value:SetJustifyH(justify) end
    local height = body:match('<Size y="([^"]+)"/>')
    if height then value:SetHeight(tonumber(height)) end
    for anchor in body:gmatch("<Anchor (.-)/>") do
        local point = assert(anchor:match('point="([^"]+)"'))
        value:SetPoint(point, parent, point, tonumber(anchor:match('x="([^"]+)"')) or 0,
            tonumber(anchor:match('y="([^"]+)"')) or 0)
    end
end

function CreateFrame(kind, _, parent, template)
    local value = object(kind, parent)
    if template then applyTemplate(value, parent, template) end
    return value
end
function methods:CreateTexture(_, _, template)
    local value = object("Texture", self)
    if template then applyTemplate(value, self, template) end
    return value
end
function methods:CreateFontString(_, _, template)
    local value = object("FontString", self)
    if template then applyTemplate(value, self, template) end
    return value
end
function methods:GetObjectType() return self.kind end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetChildren() return unpack(self.children) end
function methods:GetNumChildren() return #self.children end
function methods:GetParent() return self.parent end
function methods:SetAllPoints(owner) self.allPoints = owner end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:GetAlpha() return self.alpha end
function methods:GetPoint(index) local p = self.points[index or 1]; return p and p[1] end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetText() return self.text end
function methods:GetChecked() return self.checked == true end
function methods:SetChecked(value) self.checked = value end
function methods:SetTexture(value) self.texture = value end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:SetHeight(h) self.height = h end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:IsShown() return self.shown end
function methods:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:HookScript(name, callback) self.scripts[name] = callback end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetFrameLevel(level) self.level = level end
function methods:SetFont(...) end
function methods:SetTextColor(...) end
function methods:SetJustifyH(justify) self.justify = justify end
function methods:SetText(t) self.text = t end
function methods:RegisterEvent() end
function methods:EnableMouse(...) end
function methods:SetScript() end
function InCombatLockdown() return combat end
function hooksecurefunc(target, method, func)
    if type(target) == "table" and type(target[method]) == "function" then
        local original = target[method]
        target[method] = function(...)
            original(...)
            func(...)
        end
    end
end

_G = _G or {}
local host = object("Frame")
host.TalentsFrame = object("Frame", host)
host.SpecFrame = object("Frame", host)
host.SpecFrame.shown = false
host.CloseButton = object("Button", host)
host.CloseButton.native = host.CloseButton:CreateTexture()
host.CloseButton.scripts.OnClick = function() return "native close" end
_G.PlayerSpellsFrame = host

ns.RoundWindow = function(frame) frame.rounded = true end
ns.SkinWindowClose = function(button)
    if not button.FFXIVUICloseIcon then button.FFXIVUICloseIcon = button:CreateTexture() end
end
function methods:GetFont() return "native", 12, "" end
function methods:SetShadowColor() end
function methods:UnregisterEvent() end
function methods:SetVertexColor() end
function methods:SetSize(w, h) self.width, self.height = w, h end
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", ns)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", ns)
local styledAs = {}
ns.StyleButton = function(control) styledAs[control] = "button" end
ns.StyleEditBox = function(control) styledAs[control] = "edit" end
ns.StyleComboBox = function(control) styledAs[control] = "combo" end
ns.StyleComboBoxMenu = function(control) styledAs[control] = "menu" end
local circled = {}
ns.StyleCircularArrowButton = function(control, direction) circled[control] = direction end
ns.CreateExtractedTabArtwork = function(panel) return {panel = panel} end
ns.UpdateExtractedTabArtwork = function(art, selected) art.selected = selected end
local apply = object("Button", host.TalentsFrame)
apply.Left, apply.Middle, apply.Right = apply:CreateTexture(), apply:CreateTexture(), apply:CreateTexture()
local node = object("Button", host.TalentsFrame)
local search = object("EditBox", host.TalentsFrame)
local loadout = object("Frame", host.TalentsFrame)
loadout.Text = loadout:CreateFontString()
function loadout:OnMenuOpened() end
local reset = object("DropdownButton", host.TalentsFrame)
function reset:OnMenuOpened() end
function reset:GetMenuDescription() end

-- Load General/Talents.lua
local fn, err = loadfile("FFXIV_UI/General/Talents.lua")
assert(fn, err)
fn("FFXIV_UI", ns)

assert(ns.TalentsUI, "TalentsUI should be defined")
assert(ns.TalentsUI.TankIcon:match("Tank.tga"), "Tank icon should be configured")
assert(ns.TalentsUI.HealerIcon:match("Healer.tga"), "Healer icon should be configured")
assert(ns.TalentsUI.DpsIcon:match("DPS.tga"), "DPS icon should be configured")
assert(host.TalentsFrame.rounded, "TalentsFrame should be styled with RoundWindow")
assert(host.SpecFrame.rounded, "SpecFrame should be styled with RoundWindow")
assert(host.TalentsFrame.FFXIVUIHeaderTitle.text == "Talents", "TalentsFrame title should be 'Talents'")
assert(host.SpecFrame.FFXIVUIHeaderTitle.text == "Specializations", "SpecFrame title should be 'Specializations'")
assert(styledAs[apply] == "button" and styledAs[search] == "edit" and styledAs[loadout] == "combo")
assert(styledAs[reset] == "menu", "icon dropdown should only receive the popup skin")
assert(styledAs[node] == nil, "talent node buttons must keep their native art")
local spec = object("Button", host.SpecFrame)
spec.Left, spec.Middle, spec.Right = spec:CreateTexture(), spec:CreateTexture(), spec:CreateTexture()
host.SpecFrame:Show()
assert(styledAs[spec] == "button", "controls created after install should be styled on show")
host.SpecFrame.shown = false

local header = host.TalentsFrame.FFXIVUIHeader
assert(header.template == "FFXIV_TalentsHeaderTemplate", "Header should use the Talents header template")
assert(header.height == 30 and #header.points == 2, "Header geometry should come from the template")
assert(header.points[1][1] == "TOPLEFT" and header.points[1][4] == 8 and header.points[1][5] == -4)
assert(header.points[2][1] == "TOPRIGHT" and header.points[2][4] == -8 and header.points[2][5] == -4)
local title = host.TalentsFrame.FFXIVUIHeaderTitle
assert(title.template == "FFXIV_TalentsHeaderTitleTemplate", "Title should use the title template")
assert(title.height == 26 and title.justify == "LEFT", "Title size and justification should come from the template")
assert(title.points[1][1] == "LEFT" and title.points[1][4] == 12)
assert(title.points[2][1] == "RIGHT" and title.points[2][4] == -36)
local divider = header.regions[2]
assert(divider.template == "FFXIV_TalentsHeaderDividerTemplate", "Divider should use the divider template")
assert(divider.height == 1 and divider.points[1][1] == "BOTTOMLEFT" and divider.points[1][5] == 5)
assert(divider.points[2][1] == "BOTTOMRIGHT")

local roleTex = object("Texture", host.SpecFrame)
roleTex.GetAtlas = function() return "groupfinder-icon-role-tank" end
ns.TalentsUI.StyleRoleIcon(roleTex)
assert(roleTex.texture:match("Tank.tga"), "Role icon texture should be updated to Tank.tga")

local close = host.CloseButton
assert(close.width == 24 and close.height == 24 and close.native.alpha == 0)
assert(close.points[1][2] == host.TalentsFrame.FFXIVUIHeader and close.points[1][4] == -2)
host.TalentsFrame:Hide()
host.SpecFrame:Show()
assert(close.points[1][2] == host.SpecFrame.FFXIVUIHeader)
assert(close.FFXIVUICloseIcon:IsShown() and close.scripts.OnClick() == "native close")
combat = true
host.SpecFrame:Hide()
host.TalentsFrame:Show()
assert(close.points[1][2] == host.SpecFrame.FFXIVUIHeader, "Close moved in combat")
combat = false
ns.TalentsUI.Install()
assert(close.points[1][2] == host.TalentsFrame.FFXIVUIHeader)
host.SpellBookFrame = object("Frame", host)
assert(not ns.TalentsUI.UpdateCloseButton(host), "Talents claimed the active spellbook close button")
local legacy = object("Frame")
legacy.width = 400
legacy.CloseButton = object("Button", legacy)
local banner = legacy:CreateTexture()
banner.width, banner.height = 400, 128
banner:SetPoint("TOP", legacy, "TOP")
legacy.TopBackground = legacy:CreateTexture()
local function ForeverTab(label)
    local tab = object("Button", legacy)
    tab.Left, tab.Middle, tab.Right = tab:CreateTexture(), tab:CreateTexture(), tab:CreateTexture()
    tab.Text = tab:CreateFontString()
    tab.Text:SetText(label)
    return tab
end
legacy.Primary, legacy.Secondary = ForeverTab("Primary"), ForeverTab("Secondary")
local counter = legacy:CreateFontString()
counter:SetText("Unspent Talents: 3")
local legacySearch = object("EditBox", legacy)
legacy.SearchBox = legacySearch
local legacyOpener = object("Button", legacy)
legacyOpener.width = 25
legacy.SearchOptionsDropdown = legacyOpener
local legacyApply = object("Button", legacy)
legacyApply.Text = legacyApply:CreateFontString()
legacyApply.Text:SetText("Apply Changes")
PlayerTalentFrame = legacy
ns.TalentsUI.Install()
assert(legacy.CloseButton.points[1][2] == legacy.FFXIVUIHeader)
assert(banner.alpha == 0 and legacy.TopBackground.alpha == 0, "Forever top art should be hidden")
assert(legacy.Primary.FFXIVUITab and legacy.Secondary.FFXIVUITab, "Primary and Secondary should be tabs")
assert(styledAs[legacy.Primary] == nil, "tabs must not also receive the generic button skin")
local p1, p2 = legacy.Primary.points[1], legacy.Secondary.points[1]
assert(p1[1] == "TOPLEFT" and p1[2] == legacy.FFXIVUIHeader and p1[4] == 8 and p1[5] == -10, "first tab should sit left under the header")
assert(p2[1] == "LEFT" and p2[2] == legacy.Primary and p2[3] == "RIGHT" and p2[4] == -6, "second tab should follow the first")
assert(legacy.Primary.width == 130 and legacy.Primary.height == 30, "tabs should use the fixed tab size")
legacy.Primary:ClearAllPoints()
legacy.Primary:SetPoint("TOPLEFT", legacy, "TOPLEFT", 0, 0)
assert(#legacy.Primary.points == 1 and legacy.Primary.points[1][2] == legacy.FFXIVUIHeader and legacy.Primary.points[1][5] == -10,
    "Blizzard re-anchoring a tab should be restored under the header")
assert(#legacy.Secondary.points == 1 and legacy.Secondary.points[2] == nil and legacy.Secondary.points[1][2] == legacy.Primary,
    "the second tab should keep following the first")
assert(legacy.Primary.FFXIVUITabArt.selected == false and legacy.Secondary.FFXIVUITabArt.selected == false, "tabs start unselected without a native checked state")
legacy.Secondary.scripts.OnClick(legacy.Secondary)
assert(legacy.Secondary.FFXIVUITabArt.selected == true and legacy.Primary.FFXIVUITabArt.selected == false, "clicking a tab should select it")
local sp = legacySearch.points[1]
assert(sp[1] == "RIGHT" and sp[2] == legacyOpener and sp[3] == "LEFT" and sp[4] == -6, "search should sit left of the options button on the Apply row")
assert(legacySearch.width == 180 and legacySearch.height == 24)
assert(styledAs[legacySearch] == "edit", "search should keep the FFXIV_UI edit box skin")
assert(circled[legacyOpener] == "down", "opener should become a down circle button")
local op = legacyOpener.points[1]
assert(op[1] == "RIGHT" and op[2] == legacyApply and op[4] == -12 and legacyOpener.width == 24, "opener should sit left of Apply Changes")
assert(styledAs[legacyApply] == "button", "Apply Changes should be textured")
print("PASS Forever talents layout: top art, tabs, search placement, circle opener, apply skin")

-- Mirrors the in-game PlayerSpellsFrame.TalentsFrame: named search, opener, counter and background children.
local spells = object("Frame")
spells.TopTileStreaks = spells:CreateTexture()
local view = object("Frame", spells)
spells.TalentsFrame = view
view.width = 1212
view.Background = view:CreateTexture()
view.Background.width = 1212
view.Background.height = 1212
object("Frame", view).width = 1212
local tabRow = object("Frame", view)
tabRow.width = 301
local tabA, tabB = object("Button", tabRow), object("Button", tabRow)
local viewSearch = object("EditBox", view)
view.SearchBox = viewSearch
local viewOpener = object("Button", view)
viewOpener.width = 25
view.SearchOptionsDropdown = viewOpener
local viewApply = object("Button", view)
viewApply.width = 164
viewApply.Left, viewApply.Middle, viewApply.Right = viewApply:CreateTexture(), viewApply:CreateTexture(), viewApply:CreateTexture()
viewApply.Text = viewApply:CreateFontString()
viewApply.Text:SetText("Apply Changes")
local currency = object("Frame", view)
currency.Border = currency:CreateTexture()
view.ClassCurrencyDisplay = currency
local viewCounter = currency:CreateFontString()
viewCounter:SetText("Unspent Talents: 3")
local plainFrame = object("Frame", view)
plainFrame.Left, plainFrame.Middle, plainFrame.Right = plainFrame:CreateTexture(), plainFrame:CreateTexture(), plainFrame:CreateTexture()
_G.PlayerSpellsFrame = spells
ns.TalentsUI.Install()
assert(styledAs[plainFrame] == nil, "non-Button frames with side textures must not receive the button skin")
assert(view.FFXIVUITabs and #view.FFXIVUITabs == 2, "a non-button child must not stop the Forever layout")
assert(view.FFXIVUIHeader, "the TalentsFrame should receive the FFXIV_UI header")
assert(spells.TopTileStreaks.alpha == 0, "PlayerSpellsFrame top art should hide while Talents is shown")
assert(tabA.FFXIVUITab and tabB.FFXIVUITab, "the wide two-button row should become tabs")
assert(styledAs[viewSearch] == "edit", "search should keep the FFXIV_UI edit box skin")
assert(viewSearch.points[1][1] == "RIGHT" and viewSearch.points[1][2] == viewOpener, "search should sit left of the options button on the Apply row")
assert(viewOpener.points[1][1] == "RIGHT" and viewOpener.points[1][2] == viewApply, "options button should sit left of Apply Changes")
assert(currency.Border.alpha == 0, "the unspent counter background should be hidden")
assert(circled[viewOpener] == "down", "opener should become a down circle button")
assert(viewOpener.Arrow == nil or viewOpener.Arrow.alpha == 0, "opener's native arrow should be hidden")
assert(styledAs[viewApply] == "button", "Apply Changes should be textured")
view:Hide()
assert(spells.TopTileStreaks.alpha == 1, "top art should restore when Talents hides so Spellbook is unaffected")
view:Show()
assert(spells.TopTileStreaks.alpha == 0, "top art should hide again when Talents shows")
print("PASS PlayerSpellsFrame.TalentsFrame: tabs, search, opener, counter, Apply Changes and gated top art")


print("PASS talent/spec/legacy close styling, native clicks, shared ownership and combat deferral")

print("PASS: Talents UI initial implementation, TGA icons, and role icon replacement configured successfully")
