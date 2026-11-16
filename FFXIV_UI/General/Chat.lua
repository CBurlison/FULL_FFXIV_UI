local addonName, addonEnv = ...
local FONT = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf"
local skins, installed, refreshing, pending = {}, false, false, false
local watcher = CreateFrame("Frame")
local Refresh

local function QueueRefresh()
    if refreshing then return end
    watcher:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        Refresh()
    end)
end

local function HideTexture(texture)
    texture:Hide()
    hooksecurefunc(texture, "Show", function(self) self:Hide() end)
    hooksecurefunc(texture, "SetShown", function(self) self:Hide() end)
end

local function HideArtwork(owner)
    for _, region in ipairs({owner:GetRegions()}) do
        if region:GetObjectType() == "Texture" then HideTexture(region) end
    end
end

local function Box(parent, template)
    local box = CreateFrame("Frame", nil, parent, template)
    box:SetFrameLevel(math.max(0, parent:GetFrameLevel() - 1))
    return box
end

local function IconButton(button, tooltip, callback)
    local icon = button.icon
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function(self)
        icon:SetVertexColor(1.2, 1.2, 1.2)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        icon:SetVertexColor(1, 1, 1)
        GameTooltip:Hide()
    end)
    return button
end

local function ModeMenu(button, frame)
    local menu = MenuUtil.CreateContextMenu(button, function(_, root)
        for _, entry in ipairs({
            {SAY_MESSAGE, "SAY"}, {PARTY_MESSAGE, "PARTY"},
            {RAID_MESSAGE, "RAID"}, {INSTANCE_CHAT_MESSAGE, "INSTANCE_CHAT"},
            {GUILD_MESSAGE, "GUILD"}, {YELL_MESSAGE, "YELL"},
            {EMOTE_MESSAGE, "EMOTE"},
        }) do
            local chatType = entry[2]
            root:CreateButton(entry[1], function()
                local edit = ChatFrameUtil.OpenChat(frame.editBox:GetText(), frame)
                edit:SetChatType(chatType)
                edit:UpdateHeader()
            end)
        end
        root:CreateButton(WHISPER_MESSAGE, function()
            ChatFrameUtil.OpenChat(SLASH_SMART_WHISPER1 .. " ", frame)
        end)
        root:CreateButton(REPLY_MESSAGE, function()
            ChatFrameUtil.SetLastActiveWindow(frame.editBox)
            ChatFrameUtil.ReplyTell()
        end)
        local channels = {GetChannelList()}
        for index = 1, #channels, 3 do
            local id, name, disabled = channels[index], channels[index + 1], channels[index + 2]
            if not disabled then
                root:CreateButton(id .. ". " .. name, function()
                    local edit = ChatFrameUtil.OpenChat(frame.editBox:GetText(), frame)
                    edit:SetChannelTarget(id)
                    edit:SetChatType("CHANNEL")
                    edit:UpdateHeader()
                end)
            end
        end
    end)
    if menu then button:OnMenuOpened(menu) end
end

local function TabArtwork(tab)
    local art = {}
    for layer, name in ipairs({"fill", "border"}) do
        art[name] = {}
        for index, section in ipairs({"Left", "Center", "Right"}) do
            local material = layer == 1 and "Fill" or "Border"
            local template = "FFXIV_ChatTab" .. material .. section .. "Template"
            art[name][index] = tab:CreateTexture(nil, "BACKGROUND", template, layer - 3)
        end
    end
    return art
end

local function UpdateTab(frame, first, last)
    local skin = skins[frame]
    local selected = not frame.isDocked or FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK) == frame
    for name, textures in pairs(skin.tabArt) do
        for index, edge in ipairs({"LEFT", "RIGHT"}) do
            local cap = skin.caps[name][index]
            cap:SetShown(index == 1 and first or index == 2 and last)
            textures[index == 1 and 1 or 3]:SetPoint(edge, skin.tab, edge, 0, 0)
            textures[2]:SetPoint(edge, skin.tab, edge, index == 1 and 10 or -10, 0)
            if name == "fill" then cap:SetVertexColor(0.23, 0.23, 0.23, 0.95)
            else cap:SetVertexColor(0.65, 0.63, 0.57, 0.75) end
        end
        for _, texture in ipairs(textures) do
            if name == "fill" then texture:SetVertexColor(selected and 0.38 or 0.23, selected and 0.38 or 0.23, selected and 0.38 or 0.23, 0.95)
            else texture:SetVertexColor(0.65, 0.63, 0.57, 0.75) end
        end
    end
    skin.tab:GetFontString():SetTextColor(0.9, 0.87, 0.78)
    local label = skin.tab:GetFontString()
    label:ClearAllPoints()
    label:SetPoint("LEFT", skin.tab, "LEFT", 14, 0)
    label:SetPoint("RIGHT", skin.tab, "RIGHT", -5, 0)
    skin.dot:SetShown(selected)
end

local function StyleFrame(frame)
    if skins[frame] then return end
    local tab = _G[frame:GetName() .. "Tab"]
    if not tab or not frame.editBox then return end
    HideArtwork(frame)
    HideArtwork(frame.buttonFrame)
    HideArtwork(tab)
    HideArtwork(frame.editBox)
    tab:SetAlpha(1)
    hooksecurefunc(tab, "SetAlpha", function(self, alpha)
        if alpha ~= 1 then self:SetAlpha(1) end
    end)
    local skin = {tab = tab}
    skins[frame] = skin
    frame.FFXIVUIChat = skin
    skin.background = Box(frame, "FFXIV_ChatLogBackgroundTemplate")
    for _, method in ipairs({"SetPoint", "SetSize", "SetHeight", "SetWidth"}) do
        hooksecurefunc(tab, method, QueueRefresh)
    end
    hooksecurefunc(tab:GetFontString(), "SetPoint", QueueRefresh)
    local _, size, flags = frame:GetFont()
    frame:SetFont(FONT, size, flags)
    frame:SetShadowColor(0, 0, 0, 0.85)
    frame:SetShadowOffset(1, -1)
    local label = tab:GetFontString()
    label:SetFont(FONT, 12, "")
    label:ClearAllPoints()
    label:SetPoint("LEFT", tab, "LEFT", 14, 0)
    label:SetPoint("RIGHT", tab, "RIGHT", -5, 0)
    label:SetJustifyH("CENTER")
    label:SetWordWrap(false)
    skin.tabArt = TabArtwork(tab)
    skin.caps = {fill = {}, border = {}}
    for layer, name in ipairs({"fill", "border"}) do
        for index, edge in ipairs({"Left", "Right"}) do
            local material = layer == 1 and "Fill" or "Border"
            local template = "FFXIV_ChatTab" .. material .. edge .. "CapTemplate"
            skin.caps[name][index] = tab:CreateTexture(nil, "BACKGROUND", template, layer - 3)
        end
    end
    skin.dot = tab:CreateTexture(nil, "OVERLAY", "FFXIV_ChatTabIndicatorTemplate")
    skin.input = Box(frame.editBox, "FFXIV_ChatInputBackgroundTemplate")
    local edit = frame.editBox
    edit.header:ClearAllPoints()
    edit.header:SetPoint("BOTTOMLEFT", edit, "TOPLEFT", 8, 2)
    edit.header:SetFont(FONT, 14, "")
    local settingInsets = false
    hooksecurefunc(edit, "SetTextInsets", function(self)
        if settingInsets then return end
        settingInsets = true
        self:SetTextInsets(12, 12, 4, 4)
        settingInsets = false
    end)
    edit:UpdateHeader()
    skin.controls = CreateFrame("Frame", nil, frame, "FFXIV_ChatToolbarTemplate")
    skin.add = IconButton(skin.controls.add, NEW_CHAT_WINDOW, FCF_NewChatWindow)
    skin.settings = IconButton(skin.controls.settings, CHAT_CONFIGURATION, function()
        CURRENT_CHAT_FRAME_ID = frame:GetID()
        ShowUIPanel(ChatConfigFrame)
    end)
    skin.close = IconButton(skin.controls.close, CLOSE, function()
        if not IsBuiltinChatWindow(frame) then FCF_PopInWindow(nil, frame) end
    end)
    skin.mode = IconButton(CreateFrame("Button", nil, frame, "FFXIV_ChatModeButtonTemplate"),
        CHAT, function(self) ModeMenu(self, frame) end)
    skin.mode.OnMenuOpened = function() end
    addonEnv.StyleComboBoxMenu(skin.mode)
    frame:HookScript("OnShow", function() Refresh() end)
    frame:HookScript("OnSizeChanged", function() Refresh() end)
end

Refresh = function()
    if refreshing then return end
    if InCombatLockdown() then pending = true; return end
    refreshing, pending = true, false
    for _, name in ipairs(CHAT_FRAMES) do
        local frame = _G[name]
        if frame then StyleFrame(frame) end
    end
    for frame, skin in pairs(skins) do
        local edit = frame.editBox
        edit:ClearAllPoints()
        edit:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 24, -20)
        edit:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -20)
        edit:SetHeight(28)
        skin.tab:SetHeight(26)
        if frame.ScrollBar then
            frame.ScrollBar:ClearAllPoints()
            frame.ScrollBar:SetPoint("TOPRIGHT", frame, "TOPLEFT", -16, 0)
            frame.ScrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", -16, 17)
            addonEnv.StyleScrollBar(frame.ScrollBar, "Chat")
        end
        if frame.ScrollToBottomButton then
            frame.ScrollToBottomButton:ClearAllPoints()
            frame.ScrollToBottomButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", -16, 0)
        end
        skin.close:SetEnabled(not IsBuiltinChatWindow(frame))
        if not frame.isDocked then
            skin.tab:ClearAllPoints()
            skin.tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -5, -48)
            skin.tab:SetWidth(math.max(60, frame:GetWidth() - 90))
            UpdateTab(frame, true, true)
        end
    end
    local dock = GENERAL_CHAT_DOCK
    if dock and dock.primary then
        dock:ClearAllPoints()
        dock:SetPoint("TOPLEFT", dock.primary, "BOTTOMLEFT", 5, -48)
        dock:SetPoint("TOPRIGHT", dock.primary, "BOTTOMRIGHT", -100, -48)
        local frames = FCFDock_GetChatFrames(dock)
        local previousStatic, previousDynamic
        if dock.scrollFrame then
            dock.scrollFrame:SetHeight(26)
            dock.scrollFrame:SetPoint("BOTTOMRIGHT", dock, "BOTTOMRIGHT", 0, 0)
            local child = dock.scrollFrame:GetScrollChild()
            child:ClearAllPoints()
            child:SetPoint("BOTTOMLEFT", dock.scrollFrame, "BOTTOMLEFT", 0, 0)
            child:SetHeight(26)
            if not dock.FFXIVUILayoutHooks then
                dock.FFXIVUILayoutHooks = true
                for _, owner in ipairs({dock.scrollFrame, child}) do
                    for _, method in ipairs({"SetPoint", "SetSize", "SetHeight"}) do
                        hooksecurefunc(owner, method, QueueRefresh)
                    end
                end
            end
        end
        for index, frame in ipairs(frames) do
            if skins[frame] then
                local tab = skins[frame].tab
                if frame.isStaticDocked then
                    tab:SetWidth(tab:GetFontString():GetUnboundedStringWidth() + 28)
                    tab:ClearAllPoints()
                    if previousStatic then tab:SetPoint("BOTTOMLEFT", previousStatic, "BOTTOMRIGHT", 1, 0)
                    else tab:SetPoint("BOTTOMLEFT", dock, "BOTTOMLEFT", 0, 0) end
                    previousStatic = tab
                elseif dock.scrollFrame then
                    tab:ClearAllPoints()
                    if previousDynamic then tab:SetPoint("BOTTOMLEFT", previousDynamic, "BOTTOMRIGHT", 1, 0)
                    else tab:SetPoint("BOTTOMLEFT", dock.scrollFrame:GetScrollChild(), "BOTTOMLEFT", 0, 0) end
                    previousDynamic = tab
                end
                UpdateTab(frame, index == 1, index == #frames)
            end
        end
        if dock.scrollFrame and previousStatic then
            dock.scrollFrame:SetPoint("LEFT", previousStatic, "RIGHT", 1, 0)
        end
    end
    refreshing = false
end

local function Install()
    if installed or not ChatFrame1 or not FCFDock_UpdateTabs or not ChatFrameMenuButtonMixin then return end
    if InCombatLockdown() then pending = true; return end
    installed = true
    if ChatFrameMenuButton then
        ChatFrameMenuButton:Hide()
        hooksecurefunc(ChatFrameMenuButton, "Show", function(self) self:Hide() end)
        hooksecurefunc(ChatFrameMenuButton, "SetShown", function(self) self:Hide() end)
    end
    for _, name in ipairs({"FCFDock_UpdateTabs", "FCFDock_SetPrimary", "FCF_SetTabPosition",
        "FCF_OpenNewWindow", "FCF_OpenTemporaryWindow", "FCF_DockFrame", "FCF_UnDockFrame",
        "FCF_SetButtonSide", "FCFTab_UpdateColors"}) do
        hooksecurefunc(name, function()
            Refresh()
            QueueRefresh()
        end)
    end
    if FCF_UpdateScrollbarAnchors then hooksecurefunc("FCF_UpdateScrollbarAnchors", Refresh) end
    Refresh()
    if GENERAL_CHAT_DOCK and GENERAL_CHAT_DOCK.primary then
        FCFDock_UpdateTabs(GENERAL_CHAT_DOCK, true)
    end
end

watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function()
    Install()
    if installed and pending then Refresh() end
end)
Install()
