local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end
local xml = readFile("FFXIV_UI\\General\\Chat.xml")
local modeXml = assert(xml:match('<Button name="FFXIV_ChatModeButtonTemplate".-</Button>'))
assert(modeXml:find('virtual="true" inherits="FFXIV_ChatIconButtonTemplate"', 1, true))
assert(modeXml:find('<Anchor point="TOPLEFT" relativePoint="BOTTOMLEFT" x="-5" y="-21"/>', 1, true))
assert(xml:find('<Button name="FFXIV_ChatIconButtonTemplate"', 1, true)
    < xml:find('<Button name="FFXIV_ChatModeButtonTemplate"', 1, true))
local toolbarXml = assert(xml:match('<Frame name="FFXIV_ChatToolbarTemplate".-</Frame>'))
local toolbarButtons = {}
for key, block in toolbarXml:gmatch('<Button parentKey="([^"]+)" inherits="FFXIV_ChatIconButtonTemplate">(.-)</Button>') do
    table.insert(toolbarButtons, {key = key, block = block})
end
assert(#toolbarButtons == 3 and toolbarButtons[1].key == "add"
    and toolbarButtons[2].key == "settings" and toolbarButtons[3].key == "close")
assert(xml:find('<Button name="FFXIV_ChatIconButtonTemplate"', 1, true)
    < xml:find('<Frame name="FFXIV_ChatToolbarTemplate"', 1, true))
local logBackgroundXml = assert(xml:match('<Frame name="FFXIV_ChatLogBackgroundTemplate".-</Frame>'))
assert(logBackgroundXml:find('virtual="true" enableMouse="false"', 1, true))
assert(logBackgroundXml:find('<Anchor point="TOPLEFT" x="-12" y="8"/>', 1, true))
assert(logBackgroundXml:find('<Anchor point="BOTTOMRIGHT" x="12" y="-8"/>', 1, true))
assert(logBackgroundXml:find('<Layer level="BACKGROUND">', 1, true))
assert(xml:find('<Texture name="FFXIV_ChatLogFadeTemplate"', 1, true)
    < xml:find('<Frame name="FFXIV_ChatLogBackgroundTemplate"', 1, true),
    "Log material must load before its inheriting slices")
local logSlices = {}
for block in logBackgroundXml:gmatch('<Texture inherits="FFXIV_ChatLogFadeTemplate">(.-)</Texture>') do
    table.insert(logSlices, block)
end
assert(#logSlices == 9, "Log XML must own exactly nine fade slices")
local inputBackgroundXml = assert(xml:match('<Frame name="FFXIV_ChatInputBackgroundTemplate".-</Frame>'))
assert(inputBackgroundXml:find('virtual="true" enableMouse="false" setAllPoints="true"', 1, true))
local inputLayers = {}
for attributes, block in inputBackgroundXml:gmatch("<Layer (.-)>(.-)</Layer>") do
    assert(attributes:match('level="([^"]+)"') == "BACKGROUND")
    local layer = {subLevel = assert(tonumber(attributes:match('textureSubLevel="([^"]+)"'))), slices = {}}
    for template, slice in block:gmatch('<Texture inherits="([^"]+)">(.-)</Texture>') do
        table.insert(layer.slices, {template = template, block = slice})
        assert(assert(xml:find('<Texture name="' .. template .. '"', 1, true))
            < xml:find('<Frame name="FFXIV_ChatInputBackgroundTemplate"', 1, true),
            "Input materials must load before their inheriting slices")
    end
    assert(#layer.slices == 9, "Each input material must have nine XML slices")
    table.insert(inputLayers, layer)
end
assert(#inputLayers == 2 and inputLayers[1].subLevel == -2 and inputLayers[2].subLevel == -1)
local logTexture = {
    file = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Chat\\LogFade.tga",
    color = {0.025, 0.025, 0.025, 0.28},
}
local logXml = assert(xml:match('<Texture name="FFXIV_ChatLogFadeTemplate".-</Texture>'))
assert(logXml:find('virtual="true" file="' .. logTexture.file .. '"', 1, true))
assert(logXml:find('<Color r="0.025" g="0.025" b="0.025" a="0.28"/>', 1, true))
local inputTextures = {
    FFXIV_ChatInputSurfaceTemplate = {
        file = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\surface.tga",
        color = {0.025, 0.025, 0.025, 0.3},
    },
    FFXIV_ChatInputBorderTemplate = {
        file = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\border.tga",
        color = {0.6, 0.58, 0.52, 0.4},
    },
}
for template, data in pairs(inputTextures) do
    local block = assert(xml:match('<Texture name="' .. template .. '".-</Texture>'))
    assert(block:find('virtual="true" file="' .. data.file .. '"', 1, true))
    local r, g, b, a = block:match('<Color r="([^"]+)" g="([^"]+)" b="([^"]+)" a="([^"]+)"/>')
    for index, value in ipairs({r, g, b, a}) do
        assert(tonumber(value) == data.color[index], "Input material color changed")
    end
    assert(a, "Input material needs an RGBA color")
end
local tabTextures = {
    FFXIV_ChatTabFillTemplate = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Button-fill-Standard.tga",
    FFXIV_ChatTabBorderTemplate = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Button-border-Standard.tga",
    FFXIV_ChatTabIndicatorTemplate = "Interface\\COMMON\\Indicator-Yellow",
}
for template, path in pairs(tabTextures) do
    assert(xml:find('<Texture name="' .. template .. '" virtual="true" file="' .. path .. '"', 1, true))
end
local indicatorXml = assert(xml:match('<Texture name="FFXIV_ChatTabIndicatorTemplate".-</Texture>'))
local tabBodies = {}
for _, material in ipairs({"Fill", "Border"}) do
    for _, section in ipairs({"Left", "Center", "Right"}) do
        local template = "FFXIV_ChatTab" .. material .. section .. "Template"
        local block = assert(xml:match('<Texture name="' .. template .. '".-</Texture>'))
        local base = "FFXIV_ChatTab" .. material .. "Template"
        assert(block:find('virtual="true" inherits="' .. base .. '"', 1, true))
        assert(xml:find('<Texture name="' .. base .. '"', 1, true)
            < xml:find('<Texture name="' .. template .. '"', 1, true))
        tabBodies[template] = {base = base, block = block, section = section}
    end
end
assert(indicatorXml:find('<Size x="8" y="8"/>', 1, true))
local tabCaps = {}
for _, material in ipairs({"Fill", "Border"}) do
    for _, edge in ipairs({"Left", "Right"}) do
        local template = "FFXIV_ChatTab" .. material .. edge .. "CapTemplate"
        local block = assert(xml:match('<Texture name="' .. template .. '".-</Texture>'))
        local base = "FFXIV_ChatTab" .. material .. "Template"
        assert(block:find('virtual="true" inherits="' .. base .. '"', 1, true))
        assert(xml:find('<Texture name="' .. base .. '"', 1, true)
            < xml:find('<Texture name="' .. template .. '"', 1, true))
        tabCaps[template] = {base = base, block = block, edge = edge}
    end
end
assert(indicatorXml:find('<Anchor point="LEFT" x="5" y="0"/>', 1, true))
for _, text in ipairs({
    '<Button name="FFXIV_ChatIconButtonTemplate" virtual="true">',
    '<Size x="24" y="24"/>',
    '<Layer level="ARTWORK">',
    '<Frame name="FFXIV_ChatToolbarTemplate" virtual="true">',
    '<Size x="84" y="26"/>',
    '<Anchor point="TOPRIGHT" relativePoint="BOTTOMRIGHT" x="0" y="-50"/>',
}) do assert(xml:find(text, 1, true), "Chat XML missing: " .. text) end
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do index = index + 1; lines[line] = index end
    assert(assert(lines["General/Chat.xml"]) < assert(lines["General/Chat.lua"]))
    assert(assert(lines["General/WindowControls.lua"]) < lines["General/Chat.lua"],
        "Shared popup styling must load before chat on both clients")
end
print("PASS chat control XML geometry, icon layers, and both TOC orders")

local methods, created, combat = {}, {}, false
local function applyIcon(button, block)
    assert(block:find('<Layer level="ARTWORK">', 1, true))
    local file = assert(block:match('<Texture parentKey="icon" setAllPoints="true" file="([^"]+)"/>'))
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexture(file)
end
local function applySlice(texture, parent, block)
    texture:ClearAllPoints()
    local size = block:match("<Size (.-)/>")
    if size then
        local width, height = size:match('x="([^"]+)"'), size:match('y="([^"]+)"')
        if width then texture:SetWidth(assert(tonumber(width))) end
        if height then texture:SetHeight(assert(tonumber(height))) end
    end
    local left, right, top, bottom = block:match('<TexCoords left="([^"]+)" right="([^"]+)" top="([^"]+)" bottom="([^"]+)"/>')
    texture:SetTexCoord(assert(tonumber(left)), assert(tonumber(right)),
        assert(tonumber(top)), assert(tonumber(bottom)))
    for anchor in block:gmatch("<Anchor (.-)/>") do
        local point = assert(anchor:match('point="([^"]+)"'))
        local x, y = anchor:match('x="([^"]+)"'), anchor:match('y="([^"]+)"')
        local relativePoint = anchor:match('relativePoint="([^"]+)"') or point
        texture:SetPoint(point, parent, relativePoint, x and assert(tonumber(x)) or 0,
            y and assert(tonumber(y)) or 0)
    end
end
local function object(kind, name, parent)
    local value = setmetatable({kind = kind or "Frame", name = name, parent = parent,
        shown = true, regions = {}, scripts = {}, points = {}, width = 430, level = 5}, {__index = methods})
    if kind == "Texture" or kind == "FontString" then table.insert(parent.regions, value) end
    if name then _G[name] = value end
    table.insert(created, value)
    return value
end
function CreateFrame(kind, name, parent, template)
    local value = object(kind, name, parent)
    value.template = template
    if template == "FFXIV_ChatIconButtonTemplate" or template == "FFXIV_ChatModeButtonTemplate" then
        assert(not combat and kind == "Button")
        value:SetSize(24, 24)
        if template == "FFXIV_ChatModeButtonTemplate" then
            applyIcon(value, modeXml)
            value:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", -5, -21)
        end
    elseif template == "FFXIV_ChatToolbarTemplate" then
        assert(not combat and kind == "Frame")
        value:SetSize(84, 26)
        value:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", 0, -50)
        for _, definition in ipairs(toolbarButtons) do
            local button = CreateFrame("Button", nil, value, "FFXIV_ChatIconButtonTemplate")
            value[definition.key] = button
            applyIcon(button, definition.block)
            local anchor = assert(definition.block:match("<Anchor (.-)/>"))
            local point = assert(anchor:match('point="([^"]+)"'))
            local sibling = anchor:match('relativeKey="%$parent%.([^"]+)"')
            local relative = sibling and assert(value[sibling]) or value
            local relativePoint = anchor:match('relativePoint="([^"]+)"') or point
            button:SetPoint(point, relative, relativePoint,
                tonumber(anchor:match('x="([^"]+)"')) or 0,
                tonumber(anchor:match('y="([^"]+)"')) or 0)
        end
    elseif template == "FFXIV_ChatLogBackgroundTemplate" then
        assert(not combat and kind == "Frame")
        value:EnableMouse(false)
        value:SetPoint("TOPLEFT", parent, "TOPLEFT", -12, 8)
        value:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 12, -8)
        for _, block in ipairs(logSlices) do
            local texture = value:CreateTexture(nil, "BACKGROUND", "FFXIV_ChatLogFadeTemplate")
            applySlice(texture, value, block)
        end
    elseif template == "FFXIV_ChatInputBackgroundTemplate" then
        assert(not combat and kind == "Frame")
        value:EnableMouse(false)
        value:SetAllPoints(parent)
        for _, layer in ipairs(inputLayers) do
            for _, slice in ipairs(layer.slices) do
                local texture = value:CreateTexture(nil, "BACKGROUND", slice.template, layer.subLevel)
                applySlice(texture, value, slice.block)
            end
        end
    end
    return value
end
function methods:GetName() return self.name end
function methods:GetID() return self.id end
function methods:GetObjectType() return self.kind end
function methods:GetRegions() return table.unpack(self.regions) end
function methods:CreateTexture(_, layer, template, subLevel)
    local texture = object("Texture", nil, self)
    texture.layer, texture.template, texture.subLevel = layer, template, subLevel
    if template then
        assert(not combat, "Chat artwork must be created outside combat")
        local body = tabBodies[template]
        local cap = tabCaps[template]
        local material = inputTextures[template]
            or template == "FFXIV_ChatLogFadeTemplate" and logTexture
        texture:SetTexture(material and material.file or assert(tabTextures[body and body.base
            or cap and cap.base or template], "Unknown texture template"))
        if material then texture:SetVertexColor(unpack(material.color)) end
        if cap then
            applySlice(texture, self, cap.block)
            assert(texture.width == 10 and #texture.points == 3)
            assert(texture.points[1][1] == (cap.edge == "Left" and "RIGHT" or "LEFT")
                and texture.points[1][3] == (cap.edge == "Left" and "LEFT" or "RIGHT"))
            assert(texture.points[2][1] == "TOP" and texture.points[2][5] == -3)
            assert(texture.points[3][1] == "BOTTOM" and texture.points[3][5] == 3)
        elseif body then
            applySlice(texture, self, body.block)
            assert(texture.points[1][1] == "TOP" and texture.points[1][5] == -3)
            assert(texture.points[2][1] == "BOTTOM" and texture.points[2][5] == 3)
            if body.section == "Center" then
                assert(#texture.points == 4 and texture.points[3][1] == "LEFT"
                    and texture.points[3][4] == 10 and texture.points[4][1] == "RIGHT"
                    and texture.points[4][4] == -10)
            else
                assert(texture.width == 10 and #texture.points == 3)
                assert(texture.points[3][1] == (body.section == "Left" and "LEFT" or "RIGHT"))
            end
        elseif template == "FFXIV_ChatTabIndicatorTemplate" then
            texture:SetSize(8, 8)
            texture:SetPoint("LEFT", self, "LEFT", 5, 0)
        else
            texture:SetPoint("TOPLEFT", self, "TOPLEFT")
            texture:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
        end
    end
    return texture
end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(value) self.level = value end
function methods:SetAllPoints(value) self.allPoints = value end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetBackdrop(value) self.backdrop = value end
function methods:SetBackdropColor(...) self.fill = {...} end
function methods:SetBackdropBorderColor(...) self.border = {...} end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetTexture(value) self.texture = value end
function methods:SetTexCoord(...) self.coords = {...} end
function methods:SetTextInsets(...) self.insets = {...} end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width end
function methods:SetPoint(...) table.insert(self.points, {...}) end
function methods:ClearAllPoints() self.points = {} end
function methods:SetFont(...) self.font = {...} end
function methods:GetFont() return "native", 18, "" end
function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetTextColor(...) self.color = {...} end
function methods:SetText(value) self.text = value end
function methods:GetText() return self.text end
function methods:GetUnboundedStringWidth() return #(self.text or "General") * 7 end
function methods:GetScrollChild() return self.child end
function methods:SetJustifyH() end
function methods:SetWordWrap() end
function methods:GetFontString() return self.Text end
function methods:SetEnabled(value) self.enabled = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:HookScript(name, fn)
    local old = self.scripts[name]
    self.scripts[name] = function(...) if old then old(...) end; fn(...) end
end
function methods:RegisterEvent() end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetShown(value) self.shown = value end
function InCombatLockdown() return combat end
function hooksecurefunc(owner, key, callback)
    if type(owner) == "string" then owner, key, callback = _G, owner, key end
    local old = assert(owner[key], key)
    owner[key] = function(...) local result = old(...); callback(...); return result end
end
table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
local styledMenus, styledOpenings = {}, {}
local addonEnv = {}
function addonEnv.StyleComboBoxMenu(button)
    assert(type(button.OnMenuOpened) == "function" and not styledMenus[button])
    styledMenus[button] = true
    hooksecurefunc(button, "OnMenuOpened", function(owner, popup)
        assert(popup.owner == owner, "Popup styling must target its associated mode button")
        table.insert(styledOpenings, popup)
    end)
end
local styledScrollBars = {}
function addonEnv.StyleScrollBar(bar, variant)
    table.insert(styledScrollBars, {bar = bar, variant = variant})
end
assert(loadfile("FFXIV_UI\\General\\Chat.lua"))("FFXIV_UI", addonEnv)
local watcher = created[1]
assert(#created == 1, "chat must wait for native loading")
local function frame(id)
    local value = object("ScrollingMessageFrame", "ChatFrame" .. id)
    value.id = id
    value.editBox = object("EditBox", nil, value)
    value.editBox.text = "draft"
    value.editBox.header = object("FontString", nil, value.editBox)
    value.editBox.art = value.editBox:CreateTexture()
    value.ScrollBar = object("Frame", nil, value)
    value.ScrollToBottomButton = object("Button", nil, value)
    value.buttonFrame = object("Frame", nil, value)
    value.buttonFrame.art = value.buttonFrame:CreateTexture()
    value.art = value:CreateTexture()
    value.tab = object("Button", value.name .. "Tab")
    value.tab.Text = object("FontString", nil, value.tab)
    value.tab.art = value.tab:CreateTexture()
    value.tab.scripts.OnClick = function() return "native tab" end
    value.editBox.scripts.OnEnterPressed = function() return "native send" end
    value.OnHyperlinkClick = function() return "native item link" end
    return value
end
local first, second, detached = frame(1), frame(2), frame(3)
first.isDocked, second.isDocked = true, true
first.isStaticDocked, second.isStaticDocked = true, true
first.tab.width = 50
CHAT_FRAMES = {"ChatFrame1", "ChatFrame2", "ChatFrame3"}
GENERAL_CHAT_DOCK = object()
GENERAL_CHAT_DOCK.primary = first
GENERAL_CHAT_DOCK.frames = {first, second}
GENERAL_CHAT_DOCK.selected = first
GENERAL_CHAT_DOCK.scrollFrame = object()
GENERAL_CHAT_DOCK.scrollFrame.child = object()
function FCFDock_GetSelectedWindow(dock) return dock.selected end
function FCFDock_GetChatFrames(dock) return dock.frames end
local nativeUpdates = 0
for _, key in ipairs({"FCFDock_UpdateTabs", "FCFDock_SetPrimary", "FCF_SetTabPosition",
    "FCF_OpenNewWindow", "FCF_OpenTemporaryWindow", "FCF_DockFrame", "FCF_UnDockFrame",
    "FCF_SetButtonSide", "FCFTab_UpdateColors"}) do
    _G[key] = function() nativeUpdates = nativeUpdates + 1 end
end
function IsBuiltinChatWindow(value) return value.id <= 2 end
local newCalls, closed, settings = 0
function FCF_NewChatWindow() newCalls = newCalls + 1 end
function FCF_PopInWindow(_, value) closed = value end
function ShowUIPanel(value) settings = {value, CURRENT_CHAT_FRAME_ID} end
ChatConfigFrame = object()
ChatFrameMenuButton = object("Button")
GameTooltip = object()
function GameTooltip:SetOwner() end
local replyFrame
ChatFrameMenuButtonMixin = {}
local menu
MenuUtil = {}
local nextMenuUnavailable = false
function MenuUtil.CreateContextMenu(owner, builder)
    menu = {}
    builder(nil, {CreateButton = function(_, name, fn) menu[name] = fn end})
    if nextMenuUnavailable then nextMenuUnavailable = false; return nil end
    return {owner = owner}
end
ChatFrameUtil = {}
function ChatFrameUtil.OpenChat(text, value) value.editBox.text = text; return value.editBox end
function ChatFrameUtil.SetLastActiveWindow(edit) replyFrame = edit end
function ChatFrameUtil.ReplyTell() end
function methods:SetChannelTarget(value) self.channel = value end
function methods:SetChatType(value) self.chatType = value end
function methods:UpdateHeader()
    self.headerUpdated = true
    self.header:SetText(self.chatType or "SAY")
    self:SetTextInsets(90, 13, 0, 0)
end
function GetChannelList() return 1, "General", false, 2, "Unavailable", true end
SAY_MESSAGE, PARTY_MESSAGE, RAID_MESSAGE = "Say", "Party", "Raid"
INSTANCE_CHAT_MESSAGE, GUILD_MESSAGE, YELL_MESSAGE, EMOTE_MESSAGE = "Instance", "Guild", "Yell", "Emote"
WHISPER_MESSAGE, REPLY_MESSAGE = "Whisper", "Reply"
SLASH_SAY1, SLASH_PARTY1, SLASH_RAID1, SLASH_INSTANCE_CHAT1 = "/s", "/p", "/raid", "/i"
SLASH_GUILD1, SLASH_YELL1, SLASH_EMOTE1, SLASH_SMART_WHISPER1 = "/g", "/y", "/e", "/w"
combat = true
watcher.scripts.OnEvent(watcher, "ADDON_LOADED")
assert(not first.FFXIVUIChat, "chat geometry changed in combat")
combat = false
watcher.scripts.OnEvent(watcher, "PLAYER_REGEN_ENABLED")
assert(first.FFXIVUIChat and detached.FFXIVUIChat)
local skin = first.FFXIVUIChat
for _, chat in ipairs({first, second, detached}) do
    local art = chat.FFXIVUIChat
    for layer, key in ipairs({"fill", "border"}) do
        local template = layer == 1 and "FFXIV_ChatTabFillTemplate" or "FFXIV_ChatTabBorderTemplate"
        for _, collection in ipairs({art.tabArt[key], art.caps[key]}) do
            for index, texture in ipairs(collection) do
                local expected = collection == art.tabArt[key]
                    and "FFXIV_ChatTab" .. (layer == 1 and "Fill" or "Border")
                        .. ({"Left", "Center", "Right"})[index] .. "Template"
                    or "FFXIV_ChatTab" .. (layer == 1 and "Fill" or "Border")
                        .. ({"Left", "Right"})[index] .. "CapTemplate"
                assert(texture.template == expected and texture.parent == chat.tab)
                assert(texture.texture == tabTextures[template])
                if collection == art.tabArt[key] then
                    assert(texture.coords[1] == (index == 3 and 0.875 or 0.125)
                        and texture.coords[2] == (index == 1 and 0.125 or 0.875)
                        and texture.coords[3] == 0 and texture.coords[4] == 1)
                else
                    assert(texture.coords[1] == (index == 1 and 0 or 0.875)
                        and texture.coords[2] == (index == 1 and 0.125 or 1)
                        and texture.coords[3] == 0 and texture.coords[4] == 1)
                end
                assert(texture.layer == "BACKGROUND" and texture.subLevel == layer - 3)
                for _, point in ipairs(texture.points) do
                    assert(point[1] ~= "TOPLEFT" and point[1] ~= "BOTTOMRIGHT",
                        "Template corner anchors must be cleared before tab layout")
                end
            end
        end
    end
    assert(art.dot.template == "FFXIV_ChatTabIndicatorTemplate" and art.dot.layer == "OVERLAY")
    assert(art.dot.parent == chat.tab and art.dot.width == 8 and art.dot.height == 8)
    assert(#art.dot.points == 1 and art.dot.points[1][1] == "LEFT" and art.dot.points[1][4] == 5)
end
for _, chat in ipairs({first, second, detached}) do
    local controls = chat.FFXIVUIChat
    assert(styledMenus[controls.mode], "Mode popup must use the shared combo-menu styling")
    assert(controls.controls.template == "FFXIV_ChatToolbarTemplate")
    assert(controls.controls.width == 84 and controls.controls.height == 26)
    assert(controls.controls.points[1][2] == chat and controls.controls.points[1][5] == -50)
    assert(controls.add == controls.controls.add and controls.settings == controls.controls.settings
        and controls.close == controls.controls.close, "Lua must bind XML-created toolbar children")
    for index, key in ipairs({"add", "settings", "close"}) do
        local button = controls[key]
        local relative = index == 1 and controls.controls or controls[index == 2 and "add" or "settings"]
        assert(button.parent == controls.controls and #button.points == 1)
        local point = button.points[1]
        assert(point[1] == "LEFT" and point[2] == relative
            and point[3] == (index == 1 and "LEFT" or "RIGHT")
            and point[4] == (index == 1 and 0 or 4) and point[5] == 0)
    end
    for key, image in pairs({add = "Add", settings = "Settings", close = "Close", mode = "Mode"}) do
        local button = controls[key]
        assert(button.template == (key == "mode" and "FFXIV_ChatModeButtonTemplate"
            or "FFXIV_ChatIconButtonTemplate"))
        if key == "mode" then
            assert(button.parent == chat and #button.points == 1)
            local point = button.points[1]
            assert(point[1] == "TOPLEFT" and point[2] == chat and point[3] == "BOTTOMLEFT"
                and point[4] == -5 and point[5] == -21)
        end
        assert(button.width == 24 and button.height == 24 and button.icon.allPoints == button)
        assert(button.icon.texture == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Chat\\" .. image .. ".tga")
        button.scripts.OnEnter(button)
        assert(button.icon.color[1] == 1.2 and GameTooltip.shown)
        button.scripts.OnLeave(button)
        assert(button.icon.color[1] == 1 and not GameTooltip.shown)
    end
end
assert(skin.background.backdrop == nil and skin.background.level < first.level
    and #skin.background.regions == 9, "log must have a borderless nine-slice fade behind its text")
for _, value in ipairs({first, second, detached}) do
    local background = value.FFXIVUIChat.background
    assert(background.backdrop == nil and not background.mouse)
    assert(background.template == "FFXIV_ChatLogBackgroundTemplate" and background.parent == value)
    assert(background.level == math.max(0, value.level - 1))
    assert(#background.points == 2 and background.points[1][1] == "TOPLEFT"
        and background.points[1][2] == value and background.points[1][3] == "TOPLEFT"
        and background.points[1][4] == -12 and background.points[1][5] == 8
        and background.points[2][1] == "BOTTOMRIGHT" and background.points[2][2] == value
        and background.points[2][3] == "BOTTOMRIGHT" and background.points[2][4] == 12
        and background.points[2][5] == -8)
    for index, texture in ipairs(background.regions) do
        assert(texture.template == "FFXIV_ChatLogFadeTemplate" and texture.texture == logTexture.file)
        assert(texture.parent == background and texture.layer == "BACKGROUND" and texture.subLevel == nil)
        for component = 1, 4 do assert(texture.color[component] == logTexture.color[component]) end
        local row, column = math.floor((index - 1) / 3) + 1, (index - 1) % 3 + 1
        if column ~= 2 then assert(texture.width == 8) end
        if row ~= 2 then assert(texture.height == 8) end
        local coords = {0, 0.25, 0.75, 1}
        assert(texture.coords[1] == coords[column] and texture.coords[2] == coords[column + 1]
            and texture.coords[3] == coords[row] and texture.coords[4] == coords[row + 1])
        local anchor = ({{"TOPLEFT", "TOP", "TOPRIGHT"}, {"LEFT", "CENTER", "RIGHT"},
            {"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}})[row][column]
        assert(texture.points[1][1] == anchor and texture.points[1][2] == background
            and texture.points[1][3] == anchor)
        local count = 1
        if column == 2 then
            count = count + 2
            assert(texture.points[2][1] == "LEFT" and texture.points[2][4] == 8)
            assert(texture.points[3][1] == "RIGHT" and texture.points[3][4] == -8)
        end
        if row == 2 then
            local top = column == 2 and 4 or 2
            count = count + 2
            assert(texture.points[top][1] == "TOP" and texture.points[top][5] == -8)
            assert(texture.points[top + 1][1] == "BOTTOM" and texture.points[top + 1][5] == 8)
        end
        assert(#texture.points == count, "Log template anchors must not survive runtime layout")
    end
end
print("PASS log fade XML material, nine-slice geometry, ownership and draw layer")
assert(first.font[2] == 18, "native message font size must remain unchanged")
assert(first.width == 430 and first.editBox.points[1][5] == -20 and first.editBox.height == 28)
assert(GENERAL_CHAT_DOCK.points[1][3] == "BOTTOMLEFT" and GENERAL_CHAT_DOCK.points[1][5] == -48)
assert(skin.input.backdrop == nil and #skin.input.regions == 18,
    "input must use rounded nine-slice artwork without a square backdrop")
for _, chat in ipairs({first, second, detached}) do
    local input = chat.FFXIVUIChat.input
    assert(not input.mouse and input.level == chat.editBox.level - 1)
    assert(input.template == "FFXIV_ChatInputBackgroundTemplate" and input.parent == chat.editBox
        and input.allPoints == chat.editBox and input.backdrop == nil)
    for index, texture in ipairs(input.regions) do
        local layer = math.floor((index - 1) / 9) + 1
        local cell = (index - 1) % 9
        local row, column = math.floor(cell / 3) + 1, cell % 3 + 1
        local template = layer == 1 and "FFXIV_ChatInputSurfaceTemplate" or "FFXIV_ChatInputBorderTemplate"
        local data = inputTextures[template]
        assert(texture.parent == input and texture.template == template and texture.texture == data.file)
        assert(texture.layer == "BACKGROUND" and texture.subLevel == layer - 3)
        for component = 1, 4 do assert(texture.color[component] == data.color[component]) end
        local coords = {0, 0.25, 0.75, 1}
        assert(texture.coords[1] == coords[column] and texture.coords[2] == coords[column + 1]
            and texture.coords[3] == coords[row] and texture.coords[4] == coords[row + 1])
        local anchor = ({{"TOPLEFT", "TOP", "TOPRIGHT"}, {"LEFT", "CENTER", "RIGHT"},
            {"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}})[row][column]
        assert(texture.points[1][1] == anchor and texture.points[1][2] == input
            and texture.points[1][3] == anchor)
        local count = 1
        if column == 2 then
            count = count + 2
            assert(texture.points[2][1] == "LEFT" and texture.points[2][4] == 4)
            assert(texture.points[3][1] == "RIGHT" and texture.points[3][4] == -4)
        else assert(texture.width == 4) end
        if row == 2 then
            local top = column == 2 and 4 or 2
            count = count + 2
            assert(texture.points[top][1] == "TOP" and texture.points[top][5] == -4)
            assert(texture.points[top + 1][1] == "BOTTOM" and texture.points[top + 1][5] == 4)
        else assert(texture.height == 4) end
        assert(#texture.points == count, "Input template anchors must not survive runtime layout")
    end
end
print("PASS input XML materials, nine-slice geometry, ownership and draw layers")
assert(first.editBox.header.points[1][3] == "TOPLEFT" and first.editBox.header.points[1][5] == 2)
assert(first.editBox.header.text == "SAY" and first.editBox.insets[1] == 12
    and first.editBox.insets[2] == 12 and first.editBox.insets[3] == 4 and first.editBox.insets[4] == 4)
assert(first.tab.width >= first.tab.Text:GetUnboundedStringWidth() + 28,
    "static tab width must accommodate its entire label and indicator")
assert(first.ScrollBar.points[1][3] == "TOPLEFT" and first.ScrollBar.points[1][4] == -16)
local chatBarStyled = false
for _, entry in ipairs(styledScrollBars) do
    if entry.bar == first.ScrollBar and entry.variant == "Chat" then chatBarStyled = true end
end
assert(chatBarStyled, "chat scroll bar must use the Chat variant")
assert(skin.background.points[1][4] == -12 and skin.background.points[1][5] == 8
    and skin.background.points[2][4] == 12 and skin.background.points[2][5] == -8,
    "message background must leave padding around native text without changing message history or wrapping")
assert(first.ScrollToBottomButton.points[1][3] == "BOTTOMLEFT",
    "native scrollbar and return-to-bottom button must both move left")
assert(GENERAL_CHAT_DOCK.points[2][4] == -100, "dock must reserve room for toolbar and separate end cap")
assert(detached.tab.points[1][3] == "BOTTOMLEFT" and detached.tab.width == 340)
assert(skin.dot.shown and not second.FFXIVUIChat.dot.shown)
first.tab:SetAlpha(0.2)
assert(first.tab.alpha == 1, "bottom navigation must remain readable when native chat fades")
assert(skin.tabArt.fill[3].coords[2] == 0.875 and second.FFXIVUIChat.tabArt.fill[1].coords[1] == 0.125)
assert(skin.tabArt.fill[1].coords[1] == 0.125 and second.FFXIVUIChat.tabArt.fill[3].coords[2] == 0.875,
    "first and last tab bodies must have square ends")
assert(skin.caps.fill[1].shown and not skin.caps.fill[2].shown
    and not second.FFXIVUIChat.caps.fill[1].shown and second.FFXIVUIChat.caps.fill[2].shown)
assert(skin.caps.fill[1].points[1][1] == "RIGHT" and skin.caps.fill[1].points[1][3] == "LEFT",
    "end cap must sit beside rather than round the first tab body")
first.art:Show()
first.editBox.art:SetShown(true)
ChatFrameMenuButton:Show()
assert(not first.art.shown and not first.editBox.art.shown and not ChatFrameMenuButton.shown)
assert(first.tab.scripts.OnClick() == "native tab" and first.editBox.scripts.OnEnterPressed() == "native send")
assert(first.OnHyperlinkClick() == "native item link" and first.editBox.text == "draft")
print("PASS native content/handlers preserved, dark materials, bottom dock/input, detached tabs, connected endcaps")
skin.add.scripts.OnClick()
assert(newCalls == 1)
skin.settings.scripts.OnClick()
assert(settings[1] == ChatConfigFrame and settings[2] == 1)
skin.close.scripts.OnClick()
assert(closed == nil and not skin.close.enabled, "built-in tabs must not be deleted")
detached.FFXIVUIChat.close.scripts.OnClick()
assert(closed == detached)
detached.FFXIVUIChat.mode.scripts.OnClick(detached.FFXIVUIChat.mode)
assert(#styledOpenings == 1 and styledOpenings[1].owner == detached.FFXIVUIChat.mode)
nextMenuUnavailable = true
detached.FFXIVUIChat.mode.scripts.OnClick(detached.FFXIVUIChat.mode)
assert(#styledOpenings == 1, "A menu that did not open must not be styled")
menu.Party()
assert(detached.editBox.chatType == "PARTY" and detached.editBox.header.text == "PARTY"
    and detached.editBox.text == "draft")
for _, chat in ipairs({first, detached}) do
    local other = chat == first and detached or first
    local otherType = other.editBox.chatType
    chat.FFXIVUIChat.mode.scripts.OnClick(chat.FFXIVUIChat.mode)
    for label, chatType in pairs({Say = "SAY", Party = "PARTY", Raid = "RAID",
        Instance = "INSTANCE_CHAT", Guild = "GUILD", Yell = "YELL", Emote = "EMOTE"}) do
        menu[label]()
        assert(chat.editBox.chatType == chatType and chat.editBox.header.text == chatType)
        assert(chat.editBox.text == "draft" and other.editBox.chatType == otherType,
            "Mode selection must preserve drafts and target only its own window")
    end
end
print("PASS all standard chat modes without a private Blizzard menu helper")
menu["1. General"]()
assert(detached.editBox.channel == 1 and detached.editBox.chatType == "CHANNEL" and detached.editBox.text == "draft")
assert(detached.editBox.header.text == "CHANNEL" and detached.editBox.insets[1] == 12,
    "native mode updates must remain above input and not reserve inline header space")
assert(menu["2. Unavailable"] == nil)
menu.Reply()
assert(replyFrame == detached.editBox)
print("PASS add/settings/close actions, built-in protection, detached mode/channel targeting and draft preservation")
GENERAL_CHAT_DOCK.selected = second
FCFDock_UpdateTabs()
assert(not skin.dot.shown and second.FFXIVUIChat.dot.shown)
local before = #created
FCFDock_SetPrimary()
watcher.scripts.OnEvent(watcher, "ADDON_LOADED")
assert(#created == before, "refresh duplicated artwork or controls")
combat = true
detached.width = 500
detached.scripts.OnSizeChanged(detached)
assert(detached.tab.width == 340)
combat = false
watcher.scripts.OnEvent(watcher, "PLAYER_REGEN_ENABLED")
assert(detached.tab.width == 410)
local temporary = frame(4)
temporary.level, temporary.editBox.level = 0, 0
table.insert(CHAT_FRAMES, "ChatFrame4")
temporary.isDocked = true
table.insert(GENERAL_CHAT_DOCK.frames, temporary)
FCF_OpenTemporaryWindow()
assert(temporary.FFXIVUIChat, "new temporary frames must be styled")
assert(temporary.FFXIVUIChat.background.level == 0 and temporary.FFXIVUIChat.input.level == 0,
    "background frame levels must clamp to zero for low-level native parents")
assert(temporary.FFXIVUIChat.background.template == "FFXIV_ChatLogBackgroundTemplate"
    and temporary.FFXIVUIChat.input.template == "FFXIV_ChatInputBackgroundTemplate",
    "temporary windows must use the same background templates")
assert(temporary.tab.height == first.tab.height and temporary.tab.height == 26)
assert(temporary.tab.points[1][2] == GENERAL_CHAT_DOCK.scrollFrame.child
    and temporary.tab.points[1][5] == 0, "new dynamic tabs must share the static tabs' vertical center")
assert(GENERAL_CHAT_DOCK.scrollFrame.height == 26 and GENERAL_CHAT_DOCK.scrollFrame.child.height == 26)
temporary.tab:SetHeight(32)
temporary.tab:ClearAllPoints()
temporary.tab:SetPoint("LEFT", GENERAL_CHAT_DOCK.scrollFrame.child, "LEFT", 0, -1)
assert(watcher.scripts.OnUpdate, "late native tab geometry must queue a final layout pass")
watcher.scripts.OnUpdate(watcher)
assert(temporary.tab.height == 26 and temporary.tab.points[1][5] == 0,
    "new-tab geometry must be corrected after native creation finishes, without reloading")
assert(watcher.scripts.OnUpdate == nil, "layout correction must not become a permanent update loop")
local another = frame(5)
another.isDocked = true
table.insert(CHAT_FRAMES, "ChatFrame5")
table.insert(GENERAL_CHAT_DOCK.frames, another)
FCF_OpenNewWindow()
second.tab:ClearAllPoints()
second.tab:SetPoint("LEFT", first.tab, "RIGHT", 20, -3)
another.tab:SetPoint("CENTER", GENERAL_CHAT_DOCK.scrollFrame.child, "CENTER", 0, 5)
another.tab.Text:SetPoint("CENTER", another.tab, "CENTER", 0, -4)
GENERAL_CHAT_DOCK.scrollFrame.child:SetHeight(32)
watcher.scripts.OnUpdate(watcher)
assert(second.tab.points[1][1] == "BOTTOMLEFT" and second.tab.points[1][2] == first.tab
    and second.tab.points[1][4] == 1 and second.tab.points[1][5] == 0)
assert(another.tab.points[1][1] == "BOTTOMLEFT" and another.tab.points[1][2] == temporary.tab
    and another.tab.points[1][4] == 1 and another.tab.points[1][5] == 0)
assert(#another.tab.Text.points == 2 and another.tab.Text.points[1][1] == "LEFT"
    and another.tab.Text.points[1][5] == 0, "native label center offsets must not survive restyling")
assert(GENERAL_CHAT_DOCK.scrollFrame.child.height == 26)
local scrollPoints = GENERAL_CHAT_DOCK.scrollFrame.points
assert(scrollPoints[#scrollPoints][2] == second.tab and scrollPoints[#scrollPoints][4] == 1,
    "dynamic tab viewport must start directly after resized static tabs")
assert(watcher.scripts.OnUpdate == nil)
assert(nativeUpdates > 0)
print("PASS native dock refresh/selection, resize, combat deferral, idempotency and newly-created windows")
