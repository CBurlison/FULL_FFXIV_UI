local addonName, ns = ...
local addonEnv = ns
local Themes = addonEnv.Themes
local Skin = addonEnv.Skin
local SIDEBAR = 204
local GRID_SCALE = 0.8
local CARD_GAP = 8
local BOOK_TOP = 34
local styled, tabs, modes = {}, {}, {}
local pending, updating, queued = false, false, false
local watcher = CreateFrame("Frame")
local Install, Layout

local function QueueInstall()
    if queued then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        Install()
    end)
end

local Hook, Hide, HideTextures, Color, Text, Panel = Skin.Hook, Skin.Hide, Skin.HideTextures, Skin.Color,
    Skin.Text, Skin.Panel

local function Header(owner)
    local panel = Panel(owner)
    local borders = {}
    local uv = {0, 0.25, 0.75, 1}
    local anchors = {{"TOPLEFT", "TOP", "TOPRIGHT"}, {"LEFT", "CENTER", "RIGHT"},
        {"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}}
    local shades = {0.29, 0.27, 0.15, 0.13}
    for layer, token in ipairs({"surface", "border"}) do
        for row = 1, 3 do
            for column = 1, 3 do
                local texture = panel:CreateTexture(nil, "BACKGROUND", nil, layer - 3)
                texture:SetTexture("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\" .. token .. ".tga")
                texture:SetTexCoord(uv[column], uv[column + 1], uv[row], uv[row + 1])
                texture:SetPoint(anchors[row][column], panel, anchors[row][column])
                if column == 2 then
                    texture:SetPoint("LEFT", panel, "LEFT", 6, 0)
                    texture:SetPoint("RIGHT", panel, "RIGHT", -6, 0)
                else texture:SetWidth(6) end
                if row == 2 then
                    texture:SetPoint("TOP", panel, "TOP", 0, -6)
                    texture:SetPoint("BOTTOM", panel, "BOTTOM", 0, 6)
                else texture:SetHeight(6) end
                if token == "surface" then
                    local bottom, top = shades[row + 1], shades[row]
                    texture:SetGradient("VERTICAL", CreateColor(bottom, bottom, bottom, 1), CreateColor(top, top, top, 1))
                else borders[#borders + 1] = texture end
            end
        end
    end
    local function UpdateBorder()
        local dark = Themes.GetName() == "Dark"
        for _, texture in ipairs(borders) do
            texture:SetTexture("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\"
                .. (dark and "Panel-Border-Dark" or "border") .. ".tga")
            texture:SetVertexColor(unpack(dark and {1, 1, 1, 1} or Themes.GetPalette().border))
        end
    end
    Themes.Register(UpdateBorder)
    UpdateBorder()
    owner.FFXIVUIHeader = panel
end

local function SpellCard(row)
    local panel = Panel(row)
    local fill = {}
    local uv = {0, 0.25, 0.75, 1}
    local anchors = {{"TOPLEFT", "TOP", "TOPRIGHT"}, {"LEFT", "CENTER", "RIGHT"},
        {"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}}
    for y = 1, 3 do
        for x = 1, 3 do
            local texture = panel:CreateTexture(nil, "BACKGROUND")
            texture:SetTexture("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\surface.tga")
            texture:SetTexCoord(uv[x], uv[x + 1], uv[y], uv[y + 1])
            texture:SetPoint(anchors[y][x], panel, anchors[y][x])
            if x == 2 then
                texture:SetPoint("LEFT", panel, "LEFT", 6, 0)
                texture:SetPoint("RIGHT", panel, "RIGHT", -6, 0)
            else texture:SetWidth(6) end
            if y == 2 then
                texture:SetPoint("TOP", panel, "TOP", 0, -6)
                texture:SetPoint("BOTTOM", panel, "BOTTOM", 0, 6)
            else texture:SetHeight(6) end
            fill[#fill + 1] = texture
        end
    end
    local function Update()
        local palette = Themes.GetPalette()
        for _, texture in ipairs(fill) do
            texture:SetVertexColor(unpack(palette.tab))
        end
    end
    Themes.Register(Update)
    row.FFXIVUISpellCard = panel
end

local function Arrow(button, direction)
    if not button then return end
    addonEnv.StyleFlatArrowButton(button, direction, 30, -4)
    button:SetSize(22, 22)
end

local function Settings(button)
    addonEnv.StyleButton(button)
    addonEnv.StyleComboBoxMenu(button)
    for index = 1, 3 do
        local line = button:CreateTexture(nil, "OVERLAY")
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetSize(12, 2)
        line:SetPoint("CENTER", button, "CENTER", 0, 4 - (index - 1) * 4)
        Color(line, "SetVertexColor", "text")
    end
end

local function Tab(tab)
    local function HideLabel(region)
        if not region or region == tab.FFXIVUICategoryLabel then return end
        Hide(region)
        region:Hide()
        Hook(region, "Show", function(self) self:Hide() end)
        Hook(region, "SetShown", function(self, shown) if shown then self:Hide() end end)
    end
    local function HideNativeLabels(owner)
        if owner.GetFontString then HideLabel(owner:GetFontString()) end
        for _, region in ipairs({owner:GetRegions()}) do
            if region:GetObjectType() == "FontString" then HideLabel(region) end
        end
        for _, child in ipairs({owner:GetChildren()}) do HideNativeLabels(child) end
    end
    HideNativeLabels(tab)
    if tabs[tab] then return end
    HideTextures(tab)
    Hide(tab.Icon)
    local label = tab:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", tab, "LEFT", 12, 0)
    label:SetPoint("RIGHT", tab, "RIGHT", -12, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetHeight(28)
    -- A separate label avoids changing native icon-tab identity or width calculations.
    Hide(tab.Text)
    tab.FFXIVUICategoryLabel = label
    local highlight = {}
    for index = 1, 2 do
        local texture = tab:CreateTexture(nil, "BACKGROUND")
        texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        texture:SetPoint("TOP", tab, "TOP", 0, -2)
        texture:SetPoint("BOTTOM", tab, "BOTTOM", 0, 2)
        if index == 1 then
            texture:SetPoint("LEFT", tab, "LEFT")
            texture:SetWidth(10)
        else
            texture:SetPoint("LEFT", tab, "LEFT", 10, 0)
            texture:SetPoint("RIGHT", tab, "RIGHT")
        end
        highlight[index] = texture
    end
    tab.FFXIVUICategoryHighlight = highlight
    local hovered = false
    local function Update()
        local palette = Themes.GetPalette()
        local selected = tab:IsSelected()
        local color = selected and palette.accent or palette.selected
        local alpha = selected and 0.24 or hovered and 0.6 or 0
        for index, texture in ipairs(highlight) do
            local clear = CreateColor(color[1], color[2], color[3], 0)
            local solid = CreateColor(color[1], color[2], color[3], alpha)
            texture:SetGradient("HORIZONTAL", index == 1 and clear or solid, index == 1 and solid or clear)
            texture:SetShown(selected or hovered)
        end
        Text(label, tab:IsForceDisabled() and "muted" or "accent", 18)
    end
    tabs[tab] = Update
    Hook(tab, "SetTabSelected", Update)
    Hook(tab, "SetTabEnabled", Update)
    tab:HookScript("OnEnter", function() hovered = true; Update() end)
    local function Reset() hovered = false; Update() end
    tab:HookScript("OnLeave", Reset)
    tab:HookScript("OnHide", Reset)
    Update()
end

local function Row(row)
    if not row.Button or not row.Button.Icon then
        if row.Text then
            Hide(row.Backplate)
            Hide(row.Border)
            if not row.FFXIVUIHeader then Header(row) end
            Text(row.Text, "accent", 16)
        end
        return
    end
    if not styled[row] then
        styled[row] = true
        Hide(row.Backplate)
        local button = row.Button
        for _, key in ipairs({"Border", "BorderShadow", "TrainableShadow", "TrainableBackplate", "BorderSheen"}) do
            Hide(button[key])
        end
        SpellCard(row)
        addonEnv.ApplyButtonSkin(button, {Icon = button.Icon, Cooldown = button.Cooldown}, "Equipment")
        Hook(row, "UpdateVisuals", function()
            local defer = addonEnv.DeferOutsideSecureUpdate
            if defer then
                defer(row, "UpdateVisuals", function() Row(row) end)
            else
                Row(row)
            end
        end)
    end
    Text(row.Name or row.TextContainer and row.TextContainer.Name, "text", 12)
    Text(row.SubName or row.TextContainer and row.TextContainer.SubName, "muted", 10)
    Text(row.RequiredLevel or row.TextContainer and row.TextContainer.RequiredLevel, "accent", 10)
end

-- Native sizing can keep expanded widths after collapse, so fit to the current page.
local function CanModifyGeometry(frame)
    if not InCombatLockdown() or not frame then return true end
    return type(frame.IsProtected) == "function" and not frame:IsProtected()
end

local function FitElement(book, frame)
    local limit = book.FFXIVUIPageWidth
    if not limit or not frame then return end
    if not CanModifyGeometry(frame) then
        pending = true
        return
    end
    if frame.Button then
        frame:SetWidth(math.max(1, limit / 2 - CARD_GAP))
    else
        frame:SetWidth(limit)
    end
end

local function ReserveSidebarWidth(book, widthKey, nativeWidthKey)
    local nativeWidth = book[nativeWidthKey]
    if not nativeWidth or book[widthKey] ~= nativeWidth + SIDEBAR then
        nativeWidth = book[widthKey]
        book[nativeWidthKey] = nativeWidth
    end
    book[widthKey] = nativeWidth + SIDEBAR
end

local function ReserveSidebarWidths(book)
    ReserveSidebarWidth(book, "minimizedWidth", "FFXIVUINativeMinimizedWidth")
    ReserveSidebarWidth(book, "maximizedWidth", "FFXIVUINativeMaximizedWidth")
end

local function CompactGrid(book)
    local paged = book.PagedSpellsFrame
    if not paged.ViewFrames or not paged.InternalGetTemplateInfo or not paged.UpdateLayouts then return end
    local function Template(_, info)
        info.FFXIVUINativeHeight = info.FFXIVUINativeHeight or info.height
        info.height = info.FFXIVUINativeHeight * GRID_SCALE
    end
    for _, info in pairs(paged.cachedTemplateInfos or {}) do Template(paged, info) end
    Hook(paged, "ProcessTemplateInfo", Template)
    Hook(paged, "ProcessElementFrame", function(self, frame, data)
        if not CanModifyGeometry(frame) then
            pending = true
            return
        end
        frame:SetHeight(self:InternalGetTemplateInfo(data.templateKey).height)
        FitElement(book, frame)
        if frame.Button and CanModifyGeometry(frame.Button) then
            frame.Button:ClearAllPoints()
            frame.Button:SetPoint("LEFT", frame, "LEFT", 10, 0)
        elseif frame.Button then
            pending = true
        end
        if frame.TextContainer and CanModifyGeometry(frame.TextContainer) then
            frame.TextContainer:ClearAllPoints()
            frame.TextContainer:SetPoint("LEFT", frame, "LEFT", 60, -1)
            frame.TextContainer:SetPoint("RIGHT", frame, "RIGHT", -10, -1)
        elseif frame.Text and CanModifyGeometry(frame) then
            frame.Text:ClearAllPoints()
            frame.Text:SetPoint("LEFT", frame, "LEFT", 10, 0)
            frame.Text:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
        end
    end)
    paged.yPadding = 10 * GRID_SCALE
    paged.spacerSize = 20 * GRID_SCALE
    book.FFXIVUICompactGrid = true
end

local function Rows(book)
    if InCombatLockdown() then pending = true; return end
    if book.PagedSpellsFrame and book.PagedSpellsFrame.EnumerateFrames then
        for _, frame in book.PagedSpellsFrame:EnumerateFrames() do Row(frame) end
    elseif book.ForEachDisplayedSpell then
        book:ForEachDisplayedSpell(Row)
    end
    local paging = book.PagedSpellsFrame and book.PagedSpellsFrame.PagingControls
    if paging then
        Arrow(paging.PrevPageButton, "Left")
        Arrow(paging.NextPageButton, "Right")
        for _, region in ipairs({paging:GetRegions()}) do
            if region:GetObjectType() == "FontString" then Text(region, "muted", 12) end
        end
    end
end

local function Preview(book)
    local preview = book.SearchPreviewContainer
    if not preview or styled[preview] then return end
    styled[preview] = true
    HideTextures(preview)
    addonEnv.RoundWindow(Panel(preview))
    Text(preview.OverflowCount and preview.OverflowCount.Text, "muted", 11)
    local box = preview.ScrollBox
    if not box then return end
    local function Result(_, row)
        Text(row.Name, "text", 12)
        Text(row.Text, "muted", 12)
        if not styled[row] then
            styled[row] = true
            Hide(row.IconFrame)
            if row.HighlightTexture then
                row.HighlightTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
                Color(row.HighlightTexture, "SetVertexColor", "selected")
            end
        end
    end
    ScrollUtil.AddInitializedFrameCallback(box, Result, watcher)
    box:ForEachFrame(function(row) Result(watcher, row) end)
end

local function DisplayMode(host, book)
    local control = CreateFrame("Frame", nil, book)
    control:SetPoint("BOTTOMRIGHT", book, "BOTTOMRIGHT", -22, 6)
    control:SetSize(106, 30)
    local caption = control:CreateFontString(nil, "OVERLAY")
    caption:SetPoint("RIGHT", control, "LEFT", -10, 0)
    Text(caption, "accent", 12)
    caption:SetText(DISPLAY_MODE or "Display Mode")
    control.buttons = {}
    for index = 1, 2 do
        local button = CreateFrame("Button", nil, control)
        button:SetSize(50, 28)
        button:SetPoint("LEFT", control, "LEFT", (index - 1) * 54, 0)
        local art = addonEnv.CreateControlArtwork(Panel(button), "Square")
        local icon = {}
        for row = 1, 3 do
            for column = 1, index == 1 and 1 or 2 do
                local square = button:CreateTexture(nil, "ARTWORK")
                square:SetTexture("Interface\\Buttons\\WHITE8X8")
                square:SetSize(3, 3)
                square:SetPoint("TOPLEFT", button, "TOPLEFT", 12 + (column - 1) * 14, -7 - (row - 1) * 6)
                icon[#icon + 1] = square
                local line = button:CreateTexture(nil, "ARTWORK")
                line:SetTexture("Interface\\Buttons\\WHITE8X8")
                line:SetSize(index == 1 and 18 or 7, 2)
                line:SetPoint("LEFT", square, "RIGHT", 2, 0)
                icon[#icon + 1] = line
            end
        end
        local hovered = false
        local function Update()
            local selected = (index == 1) == (not not book.isMinimized)
            local palette = Themes.GetPalette()
            button.FFXIVUISelected = selected
            button:SetEnabled(not InCombatLockdown())
            addonEnv.UpdateControlMaterial(art, "Square")
            for _, texture in ipairs(art.fill) do
                texture:SetVertexColor(unpack((selected or hovered) and palette.selected or palette.tab))
            end
            for _, texture in ipairs(art.border) do
                texture:SetVertexColor(unpack(selected and palette.indicator or palette.border))
            end
            for _, texture in ipairs(icon) do
                texture:SetVertexColor(unpack(selected and palette.accent or palette.muted))
            end
        end
        modes[button] = Update
        button:SetScript("OnClick", function()
            if InCombatLockdown() then return end
            local minimize = index == 1
            if book.isMinimized ~= minimize then
                if minimize then host.MaximizeMinimizeButton:Minimize()
                else host.MaximizeMinimizeButton:Maximize() end
            end
            Install()
            QueueInstall()
        end)
        button:HookScript("OnEnter", function() hovered = true; Update() end)
        button:HookScript("OnLeave", function() hovered = false; Update() end)
        control.buttons[index] = button
        Update()
    end
    book.FFXIVUIDisplayMode = control
end

Layout = function()
    local host = PlayerSpellsFrame
    local book = host and host.SpellBookFrame
    if not book or updating then return end
    if InCombatLockdown() then
        pending = true
        for _, update in pairs(modes) do update() end
    end
    updating = true
    if CanModifyGeometry(book) then
        book:SetWidth(book.isMinimized and book.minimizedWidth or book.maximizedWidth)
    else
        pending = true
    end
    local bookHeight = book.FFXIVUINativeHeight or book:GetHeight() or 812
    local gridHeight = bookHeight - 72
    if book:IsShown() and book.FFXIVUICompactGrid then
        if CanModifyGeometry(book) then
            book:ClearAllPoints()
            book:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -BOOK_TOP)
            book:SetHeight(bookHeight)
        else
            pending = true
        end
        if CanModifyGeometry(host) then
            host:SetHeight(BOOK_TOP + bookHeight + 4)
            local widthOffset = book.isMinimized and book.FFXIVUIHostMinWidthOffset
                or book.FFXIVUIHostMaxWidthOffset or 3
            host:SetWidth(book:GetWidth() + widthOffset)
        else
            pending = true
        end
    elseif book.FFXIVUINativeHostHeight then
        if CanModifyGeometry(host) then host:SetHeight(book.FFXIVUINativeHostHeight)
        else pending = true end
    end
    if CanModifyGeometry(book.SearchBox) then
        book.SearchBox:ClearAllPoints()
        book.SearchBox:SetPoint("TOPLEFT", book, "TOPLEFT", 14, -22)
        book.SearchBox:SetSize(152, 28)
    else
        pending = true
    end
    if CanModifyGeometry(book.SettingsDropdown) then
        book.SettingsDropdown:ClearAllPoints()
        book.SettingsDropdown:SetPoint("LEFT", book.SearchBox, "RIGHT", 4, 0)
        book.SettingsDropdown:SetSize(24, 24)
    else
        pending = true
    end
    local rotation = book.AssistedCombatRotationSpellFrame
    if rotation then
        if CanModifyGeometry(rotation) then
            rotation:ClearAllPoints()
            rotation:SetPoint("BOTTOMLEFT", book, "BOTTOMLEFT", 14, 10)
            rotation:SetSize(SIDEBAR - 28, 40)
        else
            pending = true
        end
    end
    local system = book.CategoryTabSystem
    if CanModifyGeometry(system) then
        system:Show()
        system:SetAlpha(1)
        system:ClearAllPoints()
        system:SetPoint("TOPLEFT", book, "TOPLEFT", 10, -62)
    else
        pending = true
    end
    local count = 0
    for _, category in ipairs(book.categoryMixins or {}) do
        local tab = system:GetTabButton(category:GetTabID())
        if tab then
            local available = category:IsAvailable()
            if CanModifyGeometry(tab) then
                if tabs[tab] or not InCombatLockdown() then Tab(tab)
                else pending = true end
                tab.ignoreInLayout = true
                tab:SetShown(available)
                if available then
                    if tabs[tab] then
                        local info = category.skillLineIndex
                            and C_SpellBook.GetSpellBookSkillLineInfo(category.skillLineIndex)
                        tab.FFXIVUICategoryLabel:SetText(info and info.name
                            or category:GetName() or tab:GetTooltipText())
                        tab.FFXIVUICategoryLabel:Show()
                        tab.FFXIVUICategoryLabel:SetAlpha(1)
                        tabs[tab]()
                    end
                    tab:SetAlpha(1)
                    tab:ClearAllPoints()
                    tab:SetPoint("TOPLEFT", system, "TOPLEFT", 0, -count * 36)
                    tab:SetSize(SIDEBAR - 20, 32)
                end
            else
                pending = true
            end
            if available then count = count + 1 end
        end
    end
    for _, update in pairs(modes) do update() end
    -- Native search resizing measures this container's right edge, not its tabs.
    if CanModifyGeometry(system) then
        system:SetSize(1, math.max(1, count * 36))
        system.fixedWidth, system.fixedHeight = 1, math.max(1, count * 36)
    end
    local paged = book.PagedSpellsFrame
    if CanModifyGeometry(paged) then
        paged:ClearAllPoints()
        paged:SetPoint("TOPLEFT", book, "TOPLEFT", SIDEBAR, -8)
        paged:SetPoint("BOTTOMRIGHT", book, "BOTTOMRIGHT")
    else
        pending = true
    end
    if book.FFXIVUICompactGrid then
        local totalWidth = book:GetWidth() - SIDEBAR
        local pageWidth = book.isMinimized and totalWidth or (totalWidth / 2)
        book.FFXIVUIPageWidth = math.max(1, pageWidth - 32)
        for index, view in ipairs(paged.ViewFrames or {}) do
            if CanModifyGeometry(view) then
                view:ClearAllPoints()
                local anchor = index == 1 and "TOPLEFT" or "TOPRIGHT"
                view:SetPoint(anchor, paged, anchor, index == 1 and 16 or -16, -12)
                view:SetSize(pageWidth - 32, gridHeight)
            else
                pending = true
            end
        end
        if paged.EnumerateFrames then
            for _, frame in paged:EnumerateFrames() do FitElement(book, frame) end
        end
    end
    if paged.PagingControls then
        if CanModifyGeometry(paged.PagingControls) then
            paged.PagingControls:ClearAllPoints()
            paged.PagingControls:SetPoint("LEFT", book, "BOTTOMLEFT", SIDEBAR + 16, 21)
        else
            pending = true
        end
    end
    for index, key in ipairs({"PreviousCategoryIcon", "NextCategoryIcon", "SearchBoxIcon", "SettingsTopFaceIcon"}) do
        local prompt = book[key]
        if prompt then
            if CanModifyGeometry(prompt) then
                prompt:ClearAllPoints()
                prompt:SetPoint("BOTTOMLEFT", book, "BOTTOMLEFT", 18 + (index - 1) * 42,
                    rotation and rotation:IsShown() and 64 or 16)
            else
                pending = true
            end
        end
    end
    updating = false
end

local function Shell(host, book)
    local panel = Panel(host)
    addonEnv.RoundWindow(panel, true)
    local native = {}
    local function Capture(region)
        if not region or native[region] then return end
        native[region] = region:GetAlpha()
        Hook(region, "SetAlpha", function(self, alpha)
            if book:IsShown() and alpha ~= 0 then self:SetAlpha(0) end
        end)
    end
    local function CaptureTextures(owner)
        if not owner then return end
        for _, region in ipairs({owner:GetRegions()}) do
            if region:GetObjectType() == "Texture" then Capture(region) end
        end
    end
    for _, region in ipairs({host:GetRegions()}) do
        if region:GetObjectType() == "Texture" then Capture(region) end
    end
    for _, key in ipairs({"NineSlice", "PortraitContainer", "PortraitFrame"}) do Capture(host[key]) end
    CaptureTextures(host.NineSlice)
    CaptureTextures(host.PortraitContainer)
    CaptureTextures(host.TitleContainer)
    local close = host.CloseButton
    local closePoints, closeWidth, closeHeight = {}
    if close then
        closeWidth, closeHeight = close:GetSize()
        for index = 1, close:GetNumPoints() do closePoints[index] = {close:GetPoint(index)} end
        for _, region in ipairs({close:GetRegions()}) do
            if region:GetObjectType() == "Texture" then Capture(region) end
        end
        addonEnv.SkinWindowClose(close)
    end
    local maximize = host.MaximizeMinimizeButton
    if maximize then Capture(maximize); CaptureTextures(maximize.MaximizeButton); CaptureTextures(maximize.MinimizeButton) end
    local title = host.TitleContainer and host.TitleContainer.TitleText
    Capture(title)
    local header = CreateFrame("Frame", nil, host, "FFXIV_SpellbookHeaderTemplate")
    header:SetFrameLevel(host.TitleContainer and host.TitleContainer:GetFrameLevel() or host:GetFrameLevel() + 1)
    header:EnableMouse(false)
    local label = header:CreateFontString(nil, "OVERLAY", "FFXIV_SpellbookHeaderTitleTemplate")
    Text(label, "text", 18)
    host.FFXIVUISpellbookTitle = label
    local divider = header:CreateTexture(nil, "BACKGROUND", "FFXIV_SpellbookHeaderDividerTemplate")
    Themes.StyleDivider(divider, header)
    local sidebarDivider = book:CreateTexture(nil, "BACKGROUND")
    sidebarDivider:SetPoint("TOP", header, "BOTTOM", 0, -1)
    sidebarDivider:SetPoint("LEFT", book, "LEFT", SIDEBAR, 0)
    sidebarDivider:SetPoint("BOTTOM", book, "BOTTOM", 0, 6)
    sidebarDivider:SetWidth(1)
    Themes.StyleDivider(sidebarDivider, book, "BACKGROUND", 0, true)
    book.FFXIVUISidebarDivider = sidebarDivider
    local footerDivider = book:CreateTexture(nil, "BACKGROUND")
    footerDivider:SetPoint("BOTTOMLEFT", book, "BOTTOMLEFT", SIDEBAR+2, 42)
    footerDivider:SetPoint("BOTTOMRIGHT", book, "BOTTOMRIGHT", -10, 42)
    footerDivider:SetHeight(1)
    Themes.StyleDivider(footerDivider, book)
    book.FFXIVUIFooterDivider = footerDivider
    DisplayMode(host, book)
    local function Update()
        local active = book:IsShown()
        if not active then
            if InCombatLockdown() then pending = true
            else
                host:SetHeight(book.FFXIVUINativeHostHeight)
                book:ClearAllPoints()
                for _, point in ipairs(book.FFXIVUINativePoints) do book:SetPoint(unpack(point)) end
                book:SetHeight(book.FFXIVUINativeHeight)
            end
        end
        panel:SetShown(active)
        header:SetShown(active)
        for region, alpha in pairs(native) do region:SetAlpha(active and 0 or alpha) end
        if close and close.FFXIVUICloseIcon then
            local talentsOwnClose = not active and addonEnv.TalentsUI
                and addonEnv.TalentsUI.UpdateCloseButton(host)
            if not talentsOwnClose then close.FFXIVUICloseIcon:SetShown(active) end
            if InCombatLockdown() then pending = true
            elseif not talentsOwnClose then
                close:ClearAllPoints()
                if active then
                    close:SetSize(24, 24)
                    close:SetPoint("RIGHT", header, "RIGHT", -2, 0)
                else
                    close:SetSize(closeWidth, closeHeight)
                    for _, point in ipairs(closePoints) do close:SetPoint(unpack(point)) end
                end
            end
        end
        label:SetText(title and title:GetText() or SPELLBOOK)
    end
    book:HookScript("OnShow", Update)
    book:HookScript("OnHide", Update)
    host:HookScript("OnShow", Update)
    Hook(host, "UpdatePortrait", Update)
    Hook(host, "UpdateFrameTitle", Update)
    book.FFXIVUIUpdateShell = Update
    Update()
end

Install = function()
    local host = PlayerSpellsFrame
    local book = host and host.SpellBookFrame
    if not book or updating then return end
    if InCombatLockdown() then
        pending = true
        if styled[book] and book:IsShown() then
            Layout()
        else
            for _, update in pairs(modes) do update() end
        end
        return
    end
    pending = false
    if not styled[book] then
        styled[book] = true
        -- Reserve the sidebar through native sizing so both page widths stay intact.
        book.FFXIVUIHostMinWidthOffset = type(host.spellBookMinimizedWidth) == "number"
            and host.spellBookMinimizedWidth - book.minimizedWidth or 3
        book.FFXIVUIHostMaxWidthOffset = type(host.spellBookMaximizedWidth) == "number"
            and host.spellBookMaximizedWidth - book.maximizedWidth or 6
        for _, key in ipairs({"spellBookMinimizedWidth", "spellBookMaximizedWidth"}) do
            if type(host[key]) == "number" then host[key] = host[key] + SIDEBAR end
        end
        ReserveSidebarWidths(book)
        book.FFXIVUINativeHeight = book:GetHeight()
        book.FFXIVUINativeHostHeight = host:GetHeight()
        book.FFXIVUINativePoints = {}
        for index = 1, book:GetNumPoints() do book.FFXIVUINativePoints[index] = {book:GetPoint(index)} end
        CompactGrid(book)
        book.FFXIVUIGridNeedsLayout = book.FFXIVUICompactGrid
        HideTextures(book)
        local help = book.HelpPlateButton
        if help then
            help:Hide()
            help:EnableMouse(false)
            Hook(help, "Show", function(self) self:Hide() end)
            Hook(help, "SetShown", function(self, shown) if shown then self:Hide() end end)
        end
        Shell(host, book)
        addonEnv.StyleEditBox(book.SearchBox, 11)
        Settings(book.SettingsDropdown)
        Preview(book)
        for _, method in ipairs({"CreateCategoryMixins", "UpdateAllSpellData", "UpdateDisplayedSpells",
            "OnPagedSpellsUpdate", "SetMinimized"}) do Hook(book, method, Install) end
        Hook(book, "ApplyInputModeSizing", function()
            ReserveSidebarWidths(book)
            Layout()
        end)
        for _, method in ipairs({"ResizeSearchBox", "UpdateAttic"}) do Hook(book, method, Layout) end
        Hook(book.CategoryTabSystem, "Layout", QueueInstall)
        Hook(book.CategoryTabSystem, "OnCleaned", QueueInstall)
        Hook(book.CategoryTabSystem, "SetTabShown", Layout)
        -- The original callback resized search for a horizontal category bar.
        book.CategoryTabSystem:SetScript("OnSizeChanged", Layout)
        Hook(host, "UpdateSize", Layout)
        Hook(host, "SetMinimized", Install)
        Hook(host, "SetMinimized", QueueInstall)
        book:HookScript("OnShow", Install)
        book:HookScript("OnShow", QueueInstall)
        host:HookScript("OnShow", QueueInstall)
        Hook(book, "CreateCategoryMixins", QueueInstall)
        if book:IsShown() and type(host.UpdateSize) == "function" then host:UpdateSize() end
    end
    Layout()
    if book.FFXIVUIGridNeedsLayout and book.PagedSpellsFrame.dataProvider then
        book.FFXIVUIGridNeedsLayout = false
        book.PagedSpellsFrame:UpdateLayouts()
    end
    Rows(book)
    book.FFXIVUIUpdateShell()
end

Themes.Register(function()
    for _, update in pairs(tabs) do update() end
    for _, update in pairs(modes) do update() end
end)
if EventRegistry then
    EventRegistry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged", function()
        Install()
    end, watcher)
end
local handlers = {
    ADDON_LOADED = Install,
    PLAYER_LOGIN = Install,
    PLAYER_REGEN_ENABLED = function() if pending then Install() end end,
    PLAYER_REGEN_DISABLED = Install,
}
for event in pairs(handlers) do
    watcher:RegisterEvent(event)
end
watcher:SetScript("OnEvent", function(_, event)
    local handler = handlers[event]
    if handler then handler() end
end)
Install()
