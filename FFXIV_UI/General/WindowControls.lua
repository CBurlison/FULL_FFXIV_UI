local addonName, ns = ...
local addonEnv = ns
local Skin = addonEnv.Skin
local ROOT = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\"
local CHECK_TEXTURE_PATH = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Checkboxes\\"
local RADIO_TEXTURE_PATH = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Radio-Buttons\\"
local DISABLED_BRIGHTNESS = 0.6
local PRESS_OFFSET = 2
local controls = {}
local headers = {}
local comboHeaders = setmetatable({}, {__mode = "k"})
local comboMenus = setmetatable({}, {__mode = "k"})
-- Menu compositors flush keys written onto pooled rows on release, so row state lives here instead.
local choiceStates = setmetatable({}, {__mode = "k"})
local boundScripts = setmetatable({}, {__mode = "k"})
local comboMenuFont

local circularDirections = {
    down = {x = 0, y = -2, coords = {0, 0, 0, 1, 1, 0, 1, 1}},
    up = {x = 0, y = 2, coords = {1, 1, 1, 0, 0, 1, 0, 0}},
    left = {x = -2, y = 0, coords = {0, 1, 1, 1, 0, 0, 1, 0}},
    right = {x = 2, y = 0, coords = {1, 0, 0, 0, 1, 1, 0, 1}},
}

function addonEnv.StyleCircularArrowButton(button, direction)
    if not button then return end
    local art = button.FFXIVUICircularArrow
    direction = direction or art and art.direction or "down"
    assert(circularDirections[direction], "Unknown circular arrow direction")
    if not art then
        art = {
            base = button:CreateTexture(nil, "ARTWORK", "FFXIV_CircularArrowBaseTemplate", 0),
            shadow = button:CreateTexture(nil, "ARTWORK", "FFXIV_CircularArrowGlyphTemplate", 1),
            glyph = button:CreateTexture(nil, "ARTWORK", "FFXIV_CircularArrowGlyphTemplate", 2),
        }
        button.FFXIVUICircularArrow = art
        art.update = function()
            local specification = circularDirections[art.direction]
            local size = math.min(button:GetWidth(), button:GetHeight())
            local scale = size / 32
            local disabled = not button:IsEnabled()
            local brightness = not disabled and (art.pressed and 0.8 or art.hovered and 1.18) or 1
            local alpha = disabled and 0.4 or 1
            art.base:ClearAllPoints()
            art.base:SetPoint("CENTER", button, "CENTER")
            art.base:SetSize(size, size)
            art.base:SetVertexColor(brightness, brightness, brightness, alpha)
            for _, texture in ipairs({art.shadow, art.glyph}) do
                texture:ClearAllPoints()
                local vertical = specification.y + (texture == art.shadow and 2.5 or 0)
                texture:SetPoint("CENTER", button, "CENTER", specification.x * scale,
                    vertical * scale - (art.pressed and not disabled and 1 or 0))
                texture:SetSize(size, size)
                texture:SetTexCoord(unpack(specification.coords))
            end
            art.glyph:SetVertexColor(brightness, brightness, brightness, alpha)
            art.shadow:SetVertexColor(0, 0, 0, 0.85 * alpha)
        end
        button:HookScript("OnSizeChanged", art.update)
        button:HookScript("OnEnable", art.update)
        button:HookScript("OnEnter", function() art.hovered = true; art.update() end)
        local function Reset() art.hovered = false; art.pressed = false; art.update() end
        button:HookScript("OnDisable", Reset)
        button:HookScript("OnLeave", Reset)
        button:HookScript("OnHide", Reset)
        button:HookScript("OnMouseDown", function() art.pressed = true; art.update() end)
        button:HookScript("OnMouseUp", function() art.pressed = false; art.update() end)
    end
    art.direction = direction
    art.update()
    return art
end

-- Menus clear pooled button scripts on close, so re-bind whenever the current script is not ours.
function addonEnv.BindButtonScript(button, name, handler)
    local scripts = boundScripts[button]
    if not scripts then
        scripts = {}
        boundScripts[button] = scripts
    end
    local bound = scripts[name]
    if bound and button:GetScript(name) == bound.script and bound.handler == handler then return end
    local original = button:GetScript(name)
    if bound and original == bound.script then original = bound.original end
    local script = function(...)
        if original then original(...) end
        handler(...)
    end
    scripts[name] = {script = script, original = original, handler = handler}
    bound = script
    button:SetScript(name, bound)
end

function addonEnv.StyleComboBoxMenu(dropdown)
    if not dropdown or comboMenus[dropdown] then return end
    if type(dropdown.OnMenuOpened) ~= "function" then return end
    local probe = dropdown.FFXIVUIComboMenuProbe
    if not probe then
        probe = dropdown:CreateTexture(nil, "BACKGROUND")
        probe:Hide()
        dropdown.FFXIVUIComboMenuProbe = probe
    end
    if not probe:SetTexture(ROOT .. "ComboBox-Menu-Dark.tga") then return end
    comboMenus[dropdown] = true
    local function StyleChoice(button, description)
        local radio = description.IsRadio and description:IsRadio()
        local checkbox = description.IsCheckbox and description:IsCheckbox()
        if not (radio or checkbox) then return end
        for _, key in ipairs({"leftTexture1", "leftTexture2"}) do
            if button[key] then button[key]:Hide() end
        end
        local label = button.fontString or (type(button.GetFontString) == "function" and button:GetFontString())
        if not label then return end
        local state = choiceStates[button]
        if not state then
            local host = CreateFrame("Frame", nil, button)
            local art = host:CreateTexture(nil, "OVERLAY")
            art:SetSize(16, 16)
            state = {host = host, art = art}
            state.refresh = function()
                local choice = state.choice
                if not choice then return end
                local selected = choice:IsSelected() and true or false
                if state.radio then
                    art:SetTexture(RADIO_TEXTURE_PATH .. (selected and "Selected.tga" or "Unselected.tga"))
                else
                    art:SetTexture(CHECK_TEXTURE_PATH .. (selected and "Checked.tga" or "Unchecked.tga"))
                end
            end
            state.click = function() C_Timer.After(0, state.refresh) end
            choiceStates[button] = state
        end
        state.choice = description
        state.radio = radio
        state.owner = dropdown
        local host, art = state.host, state.art
        button.FFXIVUICheckArt = art
        host:SetFrameLevel(button:GetFrameLevel() + 10)
        host:SetAllPoints(button)
        host:Show()
        art:ClearAllPoints()
        art:SetPoint("LEFT", host, "LEFT", 4, 0)
        art:Show()
        addonEnv.BindButtonScript(button, "OnShow", state.refresh)
        addonEnv.BindButtonScript(button, "OnClick", state.click)
        state.refresh()
        label:ClearAllPoints()
        label:SetPoint("LEFT", button, "LEFT", 26, 0)
        local width = label:GetWidth() + 34 + (button.arrow and 20 or 0)
        local height = math.max(20, label:GetHeight())
        return width, height
    end
    local function StyleChoices()
        if not dropdown.GetMenuDescription or not MenuUtil or type(MenuUtil.TraverseMenu) ~= "function" then return end
        local description = dropdown:GetMenuDescription()
        if not description then return end
        MenuUtil.TraverseMenu(description, function(choice)
            local selectable = choice.IsRadio and choice:IsRadio() or choice.IsCheckbox and choice:IsCheckbox()
            if selectable and not choice.FFXIVUIStyled then
                choice.FFXIVUIStyled = true
                choice:AddInitializer(StyleChoice)
            end
        end)
    end
    if type(dropdown.OnMenuAssigned) == "function" then hooksecurefunc(dropdown, "OnMenuAssigned", StyleChoices) end
    if type(dropdown.GenerateMenu) == "function" then hooksecurefunc(dropdown, "GenerateMenu", StyleChoices) end
    StyleChoices()
    if type(dropdown.OnMenuClosed) == "function" then
        hooksecurefunc(dropdown, "OnMenuClosed", function()
            for _, state in pairs(choiceStates) do
                if state.owner == dropdown then
                    state.host:Hide()
                    state.choice = nil
                    state.owner = nil
                end
            end
        end)
    end
    hooksecurefunc(dropdown, "OnMenuOpened", function(_, menu)
        if not menu or type(menu.AttachTexture) ~= "function" then return end
        for _, region in ipairs({menu:GetRegions()}) do
            if region:GetObjectType() == "Texture" then region:SetAlpha(0) end
        end
        if menu.NineSlice then menu.NineSlice:SetAlpha(0) end
        if not comboMenuFont and type(CreateFont) == "function" then
            comboMenuFont = CreateFont("FFXIVUICharacterComboBoxMenuFont")
            comboMenuFont:SetFont("Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf", 11, "")
            comboMenuFont:SetShadowColor(0, 0, 0, 0.8)
            comboMenuFont:SetShadowOffset(1, -1)
        end
        local function StyleFonts(frame)
            if not comboMenuFont then return end
            for _, region in ipairs({frame:GetRegions()}) do
                if region:GetObjectType() == "FontString" then region:SetFontObject(comboMenuFont) end
            end
            for _, child in ipairs({frame:GetChildren()}) do StyleFonts(child) end
        end
        StyleFonts(menu)
        local edges = {0, 8 / 64, 56 / 64, 1}
        for row = 1, 3 do
            for column = 1, 3 do
                local texture = menu:AttachTexture()
                texture:SetTexture(ROOT .. "ComboBox-Menu-Dark.tga")
                texture:SetDrawLayer("BACKGROUND", -7)
                texture:SetTexCoord(edges[column], edges[column + 1], edges[row], edges[row + 1])
                if column == 2 then
                    texture:SetPoint("LEFT", menu, "LEFT", 6, 0)
                    texture:SetPoint("RIGHT", menu, "RIGHT", -6, 0)
                else
                    local anchor = column == 1 and "LEFT" or "RIGHT"
                    texture:SetPoint(anchor, menu, anchor)
                    texture:SetWidth(6)
                end
                if row == 2 then
                    texture:SetPoint("TOP", menu, "TOP", 0, -6)
                    texture:SetPoint("BOTTOM", menu, "BOTTOM", 0, 6)
                else
                    local anchor = row == 1 and "TOP" or "BOTTOM"
                    texture:SetPoint(anchor, menu, anchor)
                    texture:SetHeight(6)
                end
            end
        end
    end)
end

function addonEnv.AddTextureShadow(owner, source)
    local shadow = owner.FFXIVUIControlShadow
    if not shadow then
        shadow = CreateFrame("Frame", nil, owner, "FFXIV_ControlShadowTemplate")
        shadow.sources = {}
        owner.FFXIVUIControlShadow = shadow
        local function Layer() shadow:SetFrameLevel(math.max(0, owner:GetFrameLevel() - 1)) end
        hooksecurefunc(owner, "SetFrameLevel", Layer)
        Layer()
    end
    if shadow.sources[source] then return end
    local textures = {}
    shadow.sources[source] = textures
    for index, offset in ipairs({{0, -2, 0.18}, {-1, -2, 0.09}, {1, -2, 0.09}}) do
        local texture = shadow:CreateTexture(nil, "BACKGROUND")
        texture:SetPoint("TOPLEFT", source, "TOPLEFT", offset[1], offset[2])
        texture:SetPoint("BOTTOMRIGHT", source, "BOTTOMRIGHT", offset[1], offset[2])
        texture:SetVertexColor(0, 0, 0, offset[3])
        textures[index] = texture
    end
    local function Image(_, path)
        for _, texture in ipairs(textures) do texture:SetTexture(path) end
    end
    local function Coordinates(_, ...)
        for _, texture in ipairs(textures) do texture:SetTexCoord(...) end
    end
    hooksecurefunc(source, "SetTexture", Image)
    hooksecurefunc(source, "SetTexCoord", Coordinates)
    if source.GetTexture then Image(source, source:GetTexture()) end
    if source.GetTexCoord then Coordinates(source, source:GetTexCoord()) end
end

function addonEnv.CreateExtractedTabArtwork(panel)
    if panel.FFXIVUIExtractedTabArt then return panel.FFXIVUIExtractedTabArt end
    local art = {fill = {}, border = {}}
    for index, section in ipairs({"Left", "Center", "Right"}) do
        art.fill[index] = panel:CreateTexture(nil, "BACKGROUND", "FFXIV_ExtractedTab" .. section .. "Template")
    end
    panel.FFXIVUIExtractedTabArt = art
    return art
end

function addonEnv.UpdateExtractedTabArtwork(art, selected, hovered, disabled)
    local state = selected and "Selected" or "Inactive"
    local theme = addonEnv.Themes.GetName():gsub(" ", "-")
    local width = selected and 433 or 434
    local coordinates = {39 / 512, 71 / 512, (39 + width - 24) / 512, (39 + width) / 512}
    local brightness = disabled and DISABLED_BRIGHTNESS or hovered and 1.12 or 1
    for index, texture in ipairs(art.fill) do
        texture:SetTexture(ROOT .. "Tab-" .. state .. "-" .. theme .. ".tga")
        texture:SetTexCoord(coordinates[index], coordinates[index + 1], 10 / 64, 53 / 64)
        texture:SetVertexColor(brightness, brightness, brightness, 1)
    end
end

function addonEnv.UpdateControlMaterial(art, style, disabled)
    local material = addonEnv.GetPanelMaterial()
    local state = style == "Button" and disabled and "-Disabled" or ""
    for name, textures in pairs(art) do
        for _, texture in ipairs(textures) do
            texture:SetTexture(ROOT .. style .. "-" .. name .. state .. "-" .. material .. ".tga")
        end
    end
end

function addonEnv.CreateControlArtwork(panel, style)
    if panel.FFXIVUIControlArt then return panel.FFXIVUIControlArt end
    panel:SetBackdrop(nil)
    local art = {fill = {}, border = {}}
    if style == "Square" then
        for layer, name in ipairs({"fill", "border"}) do
            local texture = panel:CreateTexture(nil, "BACKGROUND", "FFXIV_ControlFullTemplate", layer - 3)
            art[name][1] = texture
        end
        panel.FFXIVUIControlArt = art
        addonEnv.UpdateControlMaterial(art, style)
        return art
    end
    local cap = style == "Tab" and 10 or style == "Button" and 12 or 4
    for layer, name in ipairs(style == "Search" and {"fill"} or {"fill", "border"}) do
        for index, section in ipairs({"Left", "Center", "Right"}) do
            local template = "FFXIV_Control" .. cap .. section .. "Template"
            art[name][index] = panel:CreateTexture(nil, "BACKGROUND", template, layer - 3)
        end
    end
    panel.FFXIVUIControlArt = art
    addonEnv.UpdateControlMaterial(art, style)
    return art
end

local function Shade(color, brightness)
    return color[1] * brightness, color[2] * brightness, color[3] * brightness, color[4]
end

local function UpdateControl(panel)
    local control, palette = controls[panel], addonEnv.Themes.GetPalette()
    local owner = control.owner
    local disabled = type(owner.IsEnabled) == "function" and not owner:IsEnabled()
    addonEnv.UpdateControlMaterial(control.art, control.style, disabled)
    local hovered = control.hovered and not disabled
    local color = palette[control.style == "Search" and "tab" or hovered and "selected" or "tab"]
    -- Button has dedicated disabled art; the other styles are only darkened.
    local brightness = disabled and control.style ~= "Button" and DISABLED_BRIGHTNESS or 1
    for _, texture in ipairs(control.art.fill) do texture:SetVertexColor(Shade(color, brightness)) end
    for _, texture in ipairs(control.art.border) do texture:SetVertexColor(Shade(palette.border, brightness)) end
    local pressed = control.pressed and not disabled
    if control.shifted ~= pressed then
        control.shifted = pressed
        local parent = panel:GetParent()
        panel:ClearAllPoints()
        if pressed then
            panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -PRESS_OFFSET)
            panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, -PRESS_OFFSET)
        else
            panel:SetAllPoints(parent)
        end
    end
end

local FOCUS_TEXTURE = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\ButtonSkins\\General\\Highlight"
-- The texture's glow ring sits about 48 of its 128 texels in from each edge, and its centre is transparent.
local FOCUS_SLICE = 48 / 128
local FOCUS_CORNER = 12
local FOCUS_OUTWARD = 5

-- Nine-slice: eight border pieces stretched around the box; the transparent centre is skipped.
local function CreateFocusOutline(panel)
    local o, c, s = FOCUS_OUTWARD, FOCUS_CORNER, FOCUS_SLICE
    local pieces = {
        {"TOPLEFT", "TOPLEFT", -o, o, "BOTTOMRIGHT", "TOPLEFT", c - o, o - c, 0, s, 0, s},
        {"TOPLEFT", "TOPLEFT", c - o, o, "BOTTOMRIGHT", "TOPRIGHT", o - c, o - c, s, 1 - s, 0, s},
        {"TOPLEFT", "TOPRIGHT", o - c, o, "BOTTOMRIGHT", "TOPRIGHT", o, o - c, 1 - s, 1, 0, s},
        {"TOPLEFT", "TOPLEFT", -o, o - c, "BOTTOMRIGHT", "BOTTOMLEFT", c - o, c - o, 0, s, s, 1 - s},
        {"TOPLEFT", "TOPRIGHT", o - c, o - c, "BOTTOMRIGHT", "BOTTOMRIGHT", o, c - o, 1 - s, 1, s, 1 - s},
        {"TOPLEFT", "BOTTOMLEFT", -o, c - o, "BOTTOMRIGHT", "BOTTOMLEFT", c - o, -o, 0, s, 1 - s, 1},
        {"TOPLEFT", "BOTTOMLEFT", c - o, c - o, "BOTTOMRIGHT", "BOTTOMRIGHT", o - c, -o, s, 1 - s, 1 - s, 1},
        {"TOPLEFT", "BOTTOMRIGHT", o - c, c - o, "BOTTOMRIGHT", "BOTTOMRIGHT", o, -o, 1 - s, 1, 1 - s, 1},
    }
    local outline = {}
    for _, p in ipairs(pieces) do
        local texture = panel:CreateTexture(nil, "OVERLAY")
        texture:SetTexture(FOCUS_TEXTURE)
        texture:SetTexCoord(p[9], p[10], p[11], p[12])
        texture:SetBlendMode("ADD")
        texture:ClearAllPoints()
        texture:SetPoint(p[1], panel, p[2], p[3], p[4])
        texture:SetPoint(p[5], panel, p[6], p[7], p[8])
        texture:Hide()
        outline[#outline + 1] = texture
    end
    return outline
end

local function SetFocusOutline(outline, focused)
    local indicator = addonEnv.Themes.GetPalette().indicator
    for _, texture in ipairs(outline) do
        if focused then
            texture:SetVertexColor(unpack(indicator))
            texture:Show()
        else
            texture:Hide()
        end
    end
end

local BUTTON_TYPES = {Button = true, CheckButton = true, DropdownButton = true}

-- Only button widgets have OnEnable/OnDisable scripts; other owners are hooked by method.
local function HookEnabledState(owner, callback)
    if BUTTON_TYPES[owner:GetObjectType()] then
        owner:HookScript("OnEnable", callback)
        owner:HookScript("OnDisable", callback)
    else
        for _, method in ipairs({"Enable", "Disable", "SetEnabled"}) do Skin.Hook(owner, method, callback) end
    end
end

function addonEnv.StyleWindowControl(panel, owner, style)
    if controls[panel] then return end
    controls[panel] = {style = style, owner = owner, art = addonEnv.CreateControlArtwork(panel, style)}
    local control = controls[panel]
    local function RefreshState() UpdateControl(panel) end
    HookEnabledState(owner, RefreshState)
    if style == "Button" then
        for _, texture in ipairs(control.art.fill) do addonEnv.AddTextureShadow(panel, texture) end
        if type(owner.SetPushedTextOffset) == "function" then owner:SetPushedTextOffset(0, -PRESS_OFFSET) end
        owner:HookScript("OnEnter", function() control.hovered = true; UpdateControl(panel) end)
        owner:HookScript("OnMouseDown", function() control.pressed = true; UpdateControl(panel) end)
        owner:HookScript("OnMouseUp", function() control.pressed = false; UpdateControl(panel) end)
        local function Reset() control.hovered = false; control.pressed = false; UpdateControl(panel) end
        owner:HookScript("OnLeave", Reset)
        owner:HookScript("OnHide", Reset)
    end
    if style == "Search" and owner:GetObjectType() == "EditBox" then
        local outline = CreateFocusOutline(panel)
        panel.FFXIVUIFocusOutline = outline
        owner:HookScript("OnEditFocusGained", function() SetFocusOutline(outline, true) end)
        owner:HookScript("OnEditFocusLost", function() SetFocusOutline(outline, false) end)
        owner:HookScript("OnHide", function() SetFocusOutline(outline, false) end)
    end
    UpdateControl(panel)
end

local checkButtons = setmetatable({}, {__mode = "k"})
local CHECK_SIZE = 16

local SCROLL_VARIANTS = {
    Chat = {
        line = {0.784, 0.784, 0.8, 0.55},
        thumbWidth = 4,
        base = {0.851, 0.749, 0.51, 1},
        hover = {0.91, 0.812, 0.584, 1},
        drag = {0.769, 0.663, 0.424, 1},
    },
    Menu = {
        thumbFile = ROOT .. "Bar-Pill.tga",
        pill = true,
        base = {0.337, 0.337, 0.337, 1},
        hover = {0.373, 0.373, 0.373, 1},
        drag = {0.302, 0.302, 0.302, 1},
    },
}
-- Bar-Pill.tga is a horizontal 32x16 pill; its 8px end caps are the left and right quarters.
local PILL_SLICES = {Begin = {0, 0.25}, Middle = {0.25, 0.75}, End = {0.75, 1}}
local PILL_CAP_HEIGHT = 8

-- Overlay textures live on the native thumb so they follow its position and size.
local function BuildThumbOverlay(parent, anchor, spec)
    if spec.pill then
        local top = parent:CreateTexture(nil, "ARTWORK")
        top:SetPoint("TOPLEFT", anchor, "TOPLEFT")
        top:SetPoint("TOPRIGHT", anchor, "TOPRIGHT")
        top:SetHeight(PILL_CAP_HEIGHT)
        local bottom = parent:CreateTexture(nil, "ARTWORK")
        bottom:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT")
        bottom:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT")
        bottom:SetHeight(PILL_CAP_HEIGHT)
        local middle = parent:CreateTexture(nil, "ARTWORK")
        middle:SetPoint("TOPLEFT", top, "BOTTOMLEFT")
        middle:SetPoint("BOTTOMRIGHT", bottom, "TOPRIGHT")
        return {{top, PILL_SLICES.Begin}, {middle, PILL_SLICES.Middle}, {bottom, PILL_SLICES.End}}
    end
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOP", anchor, "TOP")
    line:SetPoint("BOTTOM", anchor, "BOTTOM")
    line:SetWidth(spec.thumbWidth)
    return {{line}}
end

-- Hides the native thumb art by alpha and draws addon-owned thumb art over it. Blizzard keeps its hit regions and dragging.
function addonEnv.StyleScrollBar(bar, variant)
    if not bar then return end
    local spec = assert(SCROLL_VARIANTS[variant], "Unknown scroll bar variant")
    local style = bar.FFXIVUIScrollBar
    if not style then
        style = {}
        bar.FFXIVUIScrollBar = style
        for _, key in ipairs({"Back", "Forward", "ScrollUpButton", "ScrollDownButton"}) do
            if bar[key] then bar[key]:Hide() end
        end
        local track = bar.Track
        local thumb = track and track.Thumb
        if thumb then
            for _, slice in ipairs({"Begin", "Middle", "End"}) do
                if thumb[slice] then thumb[slice]:SetAlpha(0) end
            end
        end
        if bar.ThumbTexture then bar.ThumbTexture:SetAlpha(0) end
        if track then
            for _, region in ipairs({track:GetRegions()}) do
                if region:GetObjectType() == "Texture" then region:Hide() end
            end
        end
        if track and spec.line then
            local line = track:CreateTexture(nil, "BACKGROUND")
            line:SetPoint("TOP", track, "TOP", 0, 0)
            line:SetPoint("BOTTOM", track, "BOTTOM", 0, 0)
            line:SetWidth(1)
            line:SetColorTexture(unpack(spec.line))
        end
        local anchor = thumb or bar.ThumbTexture
        style.pieces = anchor and BuildThumbOverlay(thumb or bar, anchor, spec) or {}
        local hit = thumb or bar
        local function apply()
            local color = style.dragging and spec.drag or style.hovered and spec.hover or spec.base
            for _, piece in ipairs(style.pieces) do
                local texture, slice = piece[1], piece[2]
                if spec.pill then
                    texture:SetTexture(spec.thumbFile)
                    texture:SetTexCoord(slice[1], 0, slice[2], 0, slice[1], 1, slice[2], 1)
                    texture:SetVertexColor(unpack(color))
                else
                    texture:SetColorTexture(unpack(color))
                end
            end
        end
        hit:HookScript("OnEnter", function() style.hovered = true; apply() end)
        hit:HookScript("OnLeave", function() style.hovered = false; apply() end)
        hit:HookScript("OnMouseDown", function() style.dragging = true; apply() end)
        hit:HookScript("OnMouseUp", function() style.dragging = false; apply() end)
        style.apply = apply
    end
    style.apply()
end

-- Styles a list page's native ScrollBar with the Menu variant when it has one.
function addonEnv.StyleListScrollBar(list)
    if list and list.ScrollBar then addonEnv.StyleScrollBar(list.ScrollBar, "Menu") end
end

-- Unchecked and checked box art extracted from the Media/References enlarged checkbox captures.
function addonEnv.StyleCheckButton(button)
    if not button or checkButtons[button] then return end
    checkButtons[button] = true
    Skin.HideTextures(button)
    local art = button:CreateTexture(nil, "ARTWORK")
    art:SetSize(CHECK_SIZE, CHECK_SIZE)
    art:SetPoint("LEFT", button, "LEFT", 4, 0)
    local label = button.Text or button.text
    local function Refresh()
        local disabled = not button:IsEnabled()
        local brightness = disabled and DISABLED_BRIGHTNESS or 1
        local checked = button:GetChecked() and true or false
        art:SetTexture(CHECK_TEXTURE_PATH .. (checked and "Checked.tga" or "Unchecked.tga"))
        art:SetVertexColor(brightness, brightness, brightness, 1)
        if label then label:SetAlpha(disabled and DISABLED_BRIGHTNESS or 1) end
    end
    Refresh()
    Skin.Hook(button, "SetChecked", Refresh)
    button:HookScript("OnClick", Refresh)
    HookEnabledState(button, Refresh)
end

local radioButtons = setmetatable({}, {__mode = "k"})
local RADIO_SIZE = 16

-- Unselected and selected ring art extracted from the Media/References radio captures.
function addonEnv.StyleRadioButton(button)
    if not button or radioButtons[button] then return end
    radioButtons[button] = true
    Skin.HideTextures(button)
    local art = button:CreateTexture(nil, "ARTWORK")
    art:SetSize(RADIO_SIZE, RADIO_SIZE)
    art:SetPoint("LEFT", button, "LEFT", 4, 0)
    local label = button.Text or button.text
    local function Refresh()
        local disabled = not button:IsEnabled()
        local brightness = disabled and DISABLED_BRIGHTNESS or 1
        local checked = button:GetChecked() and true or false
        art:SetTexture(RADIO_TEXTURE_PATH .. (checked and "Selected.tga" or "Unselected.tga"))
        art:SetVertexColor(brightness, brightness, brightness, 1)
        if label then label:SetAlpha(disabled and DISABLED_BRIGHTNESS or 1) end
    end
    Refresh()
    Skin.Hook(button, "SetChecked", Refresh)
    button:HookScript("OnClick", Refresh)
    HookEnabledState(button, Refresh)
end

function addonEnv.SkinWindowClose(button)
    if button.FFXIVUICloseIcon then return end
    local icon = button:CreateTexture(nil, "OVERLAY", "FFXIV_WindowCloseIconTemplate")
    icon:SetAllPoints(button)
    icon:SetVertexColor(0.85, 0.85, 0.85, 1)
    button.FFXIVUICloseIcon = icon
    button:HookScript("OnEnter", function() icon:SetVertexColor(1, 1, 1, 1) end)
    button:HookScript("OnLeave", function() icon:SetVertexColor(0.85, 0.85, 0.85, 1) end)
end

local styledControls = setmetatable({}, {__mode = "k"})

-- style: "Button" (default), "Square", "Search", or "Dropdown" (a button-style combo box
-- that shows no value). label overrides the native font string.
function addonEnv.StyleButton(button, style, label)
    if not button or styledControls[button] then return end
    styledControls[button] = true
    style = style or "Button"
    if style == "Dropdown" then
        for _, key in ipairs({"NineSlice", "Background", "Left", "Middle", "Right"}) do Skin.Hide(button[key]) end
    else
        Skin.HideTextures(button, button.searchIcon)
        Skin.Hide(button.NineSlice)
    end
    addonEnv.StyleWindowControl(Skin.Panel(button), button, style == "Dropdown" and "Button" or style)
    if style == "Search" then return end
    label = label or (button.GetFontString and button:GetFontString()) or button.Text
    local function Update() Skin.Text(label, button:IsEnabled() and "tabText" or "muted", 12) end
    button:HookScript("OnEnable", Update)
    button:HookScript("OnDisable", Update)
    Update()
end

function addonEnv.StyleEditBox(box, promptSize)
    if not box or styledControls[box] then return end
    addonEnv.StyleButton(box, "Search")
    Skin.Text(box, "text", 12)
    Skin.Text(box.Instructions or box.PromptText, "muted", promptSize or 12)
end

local COMBO_STATES = {"Closed", "Open", "Menu"}

-- Value combo box: a dropdown that displays its current selection.
function addonEnv.StyleComboBox(dropdown)
    if not dropdown or dropdown.FFXIVUIComboBox or type(dropdown.OnMenuOpened) ~= "function" then return end
    local probe = dropdown.FFXIVUIComboBoxProbe
    if not probe then
        probe = dropdown:CreateTexture(nil, "BACKGROUND")
        probe:Hide()
        dropdown.FFXIVUIComboBoxProbe = probe
    end
    for _, state in ipairs(COMBO_STATES) do
        if not probe:SetTexture(ROOT .. "ComboBox-" .. state .. "-Dark.tga") then return end
    end
    Skin.HideTextures(dropdown, probe)
    Skin.Hide(dropdown.NineSlice)
    local panel = CreateFrame("Frame", nil, dropdown)
    panel:SetAllPoints(dropdown)
    panel:SetFrameLevel(dropdown:GetFrameLevel())
    panel:EnableMouse(false)
    local pieces = {}
    for index = 1, 3 do
        local texture = panel:CreateTexture(nil, "BACKGROUND")
        texture:SetPoint("TOP", panel, "TOP")
        texture:SetPoint("BOTTOM", panel, "BOTTOM")
        if index == 1 then
            texture:SetPoint("LEFT", panel, "LEFT")
            texture:SetWidth(20)
            texture:SetTexCoord(0, 26 / 512, 0, 1)
        elseif index == 2 then
            texture:SetPoint("LEFT", panel, "LEFT", 20, 0)
            texture:SetPoint("RIGHT", panel, "RIGHT", -12, 0)
            texture:SetTexCoord(26 / 512, 323 / 512, 0, 1)
        else
            texture:SetPoint("RIGHT", panel, "RIGHT")
            texture:SetWidth(12)
            texture:SetTexCoord(323 / 512, 339 / 512, 0, 1)
        end
        pieces[index] = texture
    end
    dropdown.FFXIVUIComboBox = pieces
    dropdown:SetHeight(24)
    local function Update()
        local opened = (dropdown.IsMenuOpen and dropdown:IsMenuOpen())
            or (dropdown.GetMenuOpen and dropdown:GetMenuOpen())
        local path = ROOT .. "ComboBox-" .. (opened and "Open" or "Closed") .. "-Dark.tga"
        local enabled = dropdown:IsEnabled()
        for _, texture in ipairs(pieces) do
            texture:SetTexture(path)
            texture:SetAlpha(enabled and 1 or 0.5)
        end
        local label = dropdown.Text or (dropdown.GetFontString and dropdown:GetFontString())
        if label then
            label:ClearAllPoints()
            label:SetPoint("LEFT", dropdown, "LEFT", 24, 0)
            label:SetPoint("RIGHT", dropdown, "RIGHT", -12, 0)
            label:SetJustifyH("LEFT")
            label:SetWordWrap(false)
            Skin.Text(label, enabled and "text" or "muted", 11)
        end
    end
    addonEnv.StyleComboBoxMenu(dropdown)
    for _, method in ipairs({"OnMenuOpened", "OnMenuClosed", "OnButtonStateChanged", "UpdateText"}) do
        Skin.Hook(dropdown, method, Update)
    end
    dropdown:HookScript("OnShow", Update)
    dropdown:HookScript("OnEnable", Update)
    dropdown:HookScript("OnDisable", Update)
    Update()
end

-- Flat Left/Right paging arrow; glyphSize and offsetY place the glyph on the button.
function addonEnv.StyleFlatArrowButton(button, direction, glyphSize, offsetY)
    if not button or button.FFXIVUIArrowTexture then return end
    Skin.HideTextures(button)
    Skin.Hide(button.NineSlice)
    local arrow = button:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(glyphSize or 22, glyphSize or 22)
    arrow:SetPoint("CENTER", button, "CENTER", 0, offsetY or 0)
    button.FFXIVUIArrowTexture = arrow
    local hovered = false
    local function Update()
        local enabled = button:IsEnabled() and "Enabled" or "Disabled"
        arrow:SetTexture(ROOT .. "Arrow-" .. direction .. "-" .. enabled .. ".tga")
        local brightness = hovered and 1.12 or 1
        arrow:SetVertexColor(brightness, brightness, brightness, 1)
        button:SetAlpha(1)
    end
    button:HookScript("OnEnter", function() hovered = true; Update() end)
    button:HookScript("OnLeave", function() hovered = false; Update() end)
    button:HookScript("OnEnable", Update)
    button:HookScript("OnDisable", Update)
    Update()
end

local HideTextures = Skin.HideTextures

-- Builds the Social pill on a header row. title is the row's label FontString,
-- collapse receives the pill textures, and isCollapsed reports the current state.
local function StyleHeader(row, title, collapse, isCollapsed)
    HideTextures(row)
    HideTextures(collapse)
    local panel = CreateFrame("Frame", nil, row, "FFXIV_CollapsibleHeaderPanelTemplate")
    panel:SetFrameLevel(row:GetFrameLevel())
    addonEnv.StyleWindowControl(panel, row, "Button")
    local horizontal = collapse:CreateTexture(nil, "OVERLAY", "FFXIV_CollapsibleHeaderHorizontalTemplate")
    local vertical = collapse:CreateTexture(nil, "OVERLAY", "FFXIV_CollapsibleHeaderVerticalTemplate")
    local function UpdateTitle()
        Skin.Font(title, 12)
        title:SetTextColor(unpack(addonEnv.Themes.GetPalette().text))
    end
    local function UpdateCollapsed() vertical:SetShown(isCollapsed() == true) end
    if row.CheckHighlightTitle then hooksecurefunc(row, "CheckHighlightTitle", UpdateTitle) end
    headers[row] = {horizontal = horizontal, vertical = vertical, update = UpdateTitle}
    row.FFXIVUIHeader = headers[row]
    horizontal:SetVertexColor(unpack(addonEnv.Themes.GetPalette().accent))
    vertical:SetVertexColor(unpack(addonEnv.Themes.GetPalette().accent))
    UpdateTitle()
    UpdateCollapsed()
    return UpdateCollapsed
end

function addonEnv.StyleCollapsibleHeader(row)
    if headers[row] then return end
    local collapse = row.CollapseButton
    local update = StyleHeader(row, row.ButtonText, collapse, function() return collapse.collapsed end)
    hooksecurefunc(collapse, "UpdateCollapsedState", update)
end

local FOREVER_PLUS = "common-button-list-plus"
local FOREVER_GLYPH = "common-button-list-collapseExpand"
local COMBO_PIECES = {
    {point = "LEFT", width = 20, coords = {0, 26 / 512}},
    {point = "MIDDLE", coords = {26 / 512, 323 / 512}},
    {point = "RIGHT", width = 12, coords = {323 / 512, 339 / 512}},
}

-- Draws the dark ComboBox bar behind a header row. The Closed/Open texture
-- already includes the arrow, so only the title needs restyling.
local function CreateComboHeader(row, title, isCollapsed)
    local bar = CreateFrame("Frame", nil, row)
    bar:SetAllPoints(row)
    bar:SetFrameLevel(row:GetFrameLevel())
    bar:EnableMouse(false)
    local pieces = {}
    for index, spec in ipairs(COMBO_PIECES) do
        local texture = bar:CreateTexture(nil, "BACKGROUND")
        texture:SetPoint("TOP", bar, "TOP")
        texture:SetPoint("BOTTOM", bar, "BOTTOM")
        if spec.point == "LEFT" then
            texture:SetPoint("LEFT", bar, "LEFT")
            texture:SetWidth(spec.width)
        elseif spec.point == "RIGHT" then
            texture:SetPoint("RIGHT", bar, "RIGHT")
            texture:SetWidth(spec.width)
        else
            texture:SetPoint("LEFT", bar, "LEFT", COMBO_PIECES[1].width, 0)
            texture:SetPoint("RIGHT", bar, "RIGHT", -COMBO_PIECES[3].width, 0)
        end
        texture:SetTexCoord(spec.coords[1], spec.coords[2], 0, 1)
        pieces[index] = {region = texture}
    end

    title:ClearAllPoints()
    title:SetPoint("LEFT", bar, "LEFT", 26, 0)
    title:SetPoint("RIGHT", bar, "RIGHT", -12, 0)
    title:SetJustifyH("LEFT")

    local function Update()
        local palette = addonEnv.Themes.GetPalette()
        local path = ROOT .. (isCollapsed() and "ComboBox-Closed-Dark.tga" or "ComboBox-Open-Dark.tga")
        for _, piece in ipairs(pieces) do
            piece.texture = path
            piece.region:SetTexture(path)
        end
        Skin.Font(title, 12)
        title:SetTextColor(unpack(palette.text))
    end
    local header = {bar = bar, pieces = pieces, update = Update}
    comboHeaders[row] = header
    row.FFXIVUIHeader = header
    if row.CheckHighlightTitle then hooksecurefunc(row, "CheckHighlightTitle", Update) end
    Update()
    return header
end

-- Forever header rows have no CollapseButton. The row's StateIcon atlas is the
-- collapse state (plus = collapsed) and its static glyph children are hidden.
-- The dark ComboBox bar texture already includes the arrow.
function addonEnv.StyleForeverCollapsibleHeader(row)
    if comboHeaders[row] or not row.Name or not row.StateIcon then return end
    local state = row.StateIcon
    local function IsCollapsed() return state:GetAtlas() == FOREVER_PLUS end
    local function HideGlyphs()
        for _, child in ipairs({row:GetChildren()}) do
            if child.GetAtlas and child:GetAtlas() == FOREVER_GLYPH then child:SetAlpha(0) end
        end
        for _, region in ipairs({row:GetRegions()}) do
            if region.GetAtlas and region:GetAtlas() == FOREVER_GLYPH then region:SetAlpha(0) end
        end
    end
    HideGlyphs()
    HideTextures(row)
    state:SetAlpha(0)
    hooksecurefunc(state, "SetAlpha", function(self, alpha)
        if alpha ~= 0 then self:SetAlpha(0) end
    end)
    local header = CreateComboHeader(row, row.Name, IsCollapsed)
    hooksecurefunc(state, "SetAtlas", header.update)
end

-- Retail header rows (Social lists) toggle through a native CollapseButton.
-- The button stays clickable; only its artwork is hidden behind the combo bar.
function addonEnv.StyleComboCollapsibleHeader(row)
    if comboHeaders[row] or not row.ButtonText or not row.CollapseButton then return end
    local collapse = row.CollapseButton
    HideTextures(row)
    HideTextures(collapse)
    local header = CreateComboHeader(row, row.ButtonText, function() return collapse.collapsed == true end)
    if type(collapse.UpdateCollapsedState) == "function" then
        hooksecurefunc(collapse, "UpdateCollapsedState", header.update)
    end
end

addonEnv.Themes.Register(function(palette)
    for _, header in pairs(headers) do
        header.horizontal:SetVertexColor(unpack(palette.accent))
        header.vertical:SetVertexColor(unpack(palette.accent))
        header.update()
    end
    for _, header in pairs(comboHeaders) do header.update() end
    for panel in pairs(controls) do UpdateControl(panel) end
end)
