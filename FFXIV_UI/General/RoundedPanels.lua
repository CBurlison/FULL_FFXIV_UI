local addonName, ns = ...
local addonEnv = ns
local ROOT = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\"
local panels = {}
local anchors = {
    {"TOPLEFT", "TOP", "TOPRIGHT"},
    {"LEFT", "CENTER", "RIGHT"},
    {"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"},
}
local uv = {0, 0.25, 0.75, 1}
local windowChrome = {}

local function Material()
    local name = addonEnv.Themes.GetName()
    return name:find("^Clear ") and "Clear" or name == "Classic FF" and "Classic" or "Standard"
end
addonEnv.GetPanelMaterial = Material

local function Chrome(panel)
    if windowChrome[panel] then return end
    local rim, background, lighting = {}, {}, {}
    for row = 1, 3 do
        for column = 1, 3 do
            local suffix = row .. column .. "Template"
            local fill = panel:CreateTexture(nil, "BACKGROUND", "FFXIV_WindowBackground" .. suffix, -2)
            background[#background + 1] = {texture = fill, row = row, column = column}
            if row ~= 2 or column ~= 2 then
                local edge = panel:CreateTexture(nil, "BORDER", "FFXIV_WindowRim" .. suffix)
                rim[#rim + 1] = edge
            end
            if row <= 2 then
                local light = panel:CreateTexture(nil, "BACKGROUND", "FFXIV_WindowHeader" .. suffix, -1)
                lighting[#lighting + 1] = light
            end
        end
    end
    local function Size(_, width, height)
        for _, piece in ipairs(background) do
            local x = piece.column == 1 and 0 or piece.column == 2 and 8 or width - 8
            local y = piece.row == 1 and 0 or piece.row == 2 and 8 or height - 8
            local pieceWidth = piece.column == 2 and math.max(1, width - 16) or 8
            local pieceHeight = piece.row == 2 and math.max(1, height - 16) or 8
            piece.texture:SetTexCoord(x / 128, (x + pieceWidth) / 128, y / 128, (y + pieceHeight) / 128)
        end
    end
    panel:HookScript("OnSizeChanged", Size)
    panel:HookScript("OnShow", function() Size(panel, panel:GetSize()) end)
    Size(panel, panel:GetSize())
    windowChrome[panel] = true
    panel.FFXIVUIWindowRim = rim
    panel.FFXIVUIWindowInterior = background
    panel.FFXIVUIWindowLighting = lighting
end

function addonEnv.RoundWindow(panel, chrome)
    if panels[panel] then return end
    if panel.SetBackdrop then panel:SetBackdrop(nil) end
    if chrome then
        panels[panel] = {}
        Chrome(panel)
        return
    end
    local layers = {}
    for layer, token in ipairs({"surface", "border"}) do
        for row = 1, 3 do
            for column = 1, 3 do
                local prefix = token == "border" and "FFXIV_RoundBorder" or "FFXIV_RoundSurface"
                local texture = panel:CreateTexture(nil, "BACKGROUND", prefix .. row .. column .. "Template", layer - 3)
                layers[#layers + 1] = {texture = texture, token = token}
                texture:SetVertexColor(unpack(token == "border" and {1, 1, 1, 1} or addonEnv.Themes.GetPalette()[token]))
            end
        end
    end
    panels[panel] = layers
    local grain = panel:CreateTexture(nil, "BACKGROUND", "FFXIV_RoundGrainTemplate", -1)
    local function SizeGrain(_, width, height)
        grain:SetTexCoord(0, math.max(1, width - 16) / 128, 0, math.max(1, height - 16) / 128)
    end
    panel:HookScript("OnSizeChanged", SizeGrain)
    panel:HookScript("OnShow", function() SizeGrain(panel, panel:GetSize()) end)
    SizeGrain(panel, panel:GetSize())
    panel.FFXIVUIGrain = grain
    local name = addonEnv.Themes.GetName()
    grain:SetAlpha((name == "Dark" or name == "Light") and 0.018 or 0)
    for _, layer in ipairs(layers) do
        if layer.token == "surface" then
            layer.texture:SetTexture(ROOT .. "surface-" .. Material() .. ".tga")
        end
    end
end

-- Rounded fill drawn on owner's background layer, sized to ref.
function addonEnv.RoundFill(owner, ref, token)
    local pieces = {}
    for row = 1, 3 do
        for column = 1, 3 do
            local texture = owner:CreateTexture(nil, "BACKGROUND", "FFXIV_RoundFill" .. row .. column .. "Template", -8)
            texture:SetTexture(ROOT .. "surface-" .. Material() .. ".tga")
            local anchor = anchors[row][column]
            texture:SetPoint(anchor, ref, anchor)
            if column == 2 then
                texture:SetPoint("LEFT", ref, "LEFT", 8, 0)
                texture:SetPoint("RIGHT", ref, "RIGHT", -8, 0)
            end
            if row == 2 then
                texture:SetPoint("TOP", ref, "TOP", 0, -8)
                texture:SetPoint("BOTTOM", ref, "BOTTOM", 0, 8)
            end
            pieces[#pieces + 1] = texture
        end
    end
    addonEnv.Themes.Register(function(palette)
        for _, texture in ipairs(pieces) do texture:SetVertexColor(unpack(palette[token])) end
    end)
    return pieces
end

-- Hides the native detail frame's texture art, which Blizzard re-shows during
-- updates, and keeps it hidden. The frame is stretched to the edges of its native
-- anchor box. The panel is drawn by the main window, so it has no surround.
-- Section headers added through the side pane's AddCategory lose their framed
-- banner and get the standard divider under the label, as wide as the banner was.
local CATEGORY_ATLAS = "UI-Character-Info-Title"

local function StyleDetailCategories(frame)
    local content = frame.Content
    if not content then return end
    for _, row in ipairs({content:GetChildren()}) do
        local banner = row.Background
        if not row.FFXIVUICategoryStyled and row.Label and banner and banner.GetAtlas
            and banner:GetAtlas() == CATEGORY_ATLAS then
            row.FFXIVUICategoryStyled = true
            banner:SetAlpha(0)
            local underline = row:CreateTexture(nil, "BORDER")
            addonEnv.Themes.StyleDivider(underline, row, "BORDER")
            underline:SetHeight(1)
            underline:SetPoint("TOP", row.Label, "BOTTOM", 0, -3)
            underline:SetPoint("LEFT", row, "LEFT", 0, 0)
            underline:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            row.FFXIVUIUnderline = underline
        end
    end
end

function addonEnv.StyleDetailPanel(frame)
    if not frame or frame.FFXIVUIDetailPanel then return end
    if type(frame.AddCategory) == "function" then
        -- Rows are pooled, so each new category row is styled once and keeps its look on reuse.
        hooksecurefunc(frame, "AddCategory", StyleDetailCategories)
        StyleDetailCategories(frame)
    end
    local point1, relative1 = frame:GetPoint(1)
    local point2, relative2 = frame:GetPoint(2)
    if relative1 and relative2 then
        frame:ClearAllPoints()
        frame:SetPoint(point1, relative1, point1)
        frame:SetPoint(point2, relative2, point2)
    end
    for _, region in ipairs({frame:GetRegions()}) do
        if region:GetObjectType() == "Texture" then
            region:SetAlpha(0)
            hooksecurefunc(region, "SetAlpha", function(self, alpha)
                if alpha ~= 0 then self:SetAlpha(0) end
            end)
            hooksecurefunc(region, "Show", function(self) self:SetAlpha(0) end)
        end
    end
    frame.FFXIVUIDetailPanel = true
end


-- Border only, no fill; for framing content that draws its own background.
function addonEnv.RoundOutline(frame)
    if frame.FFXIVUIOutline then return end
    local pieces = {}
    for row = 1, 3 do
        for column = 1, 3 do
            if row ~= 2 or column ~= 2 then
                pieces[#pieces + 1] = frame:CreateTexture(nil, "OVERLAY", "FFXIV_RoundBorder" .. row .. column .. "Template")
            end
        end
    end
    frame.FFXIVUIOutline = pieces
end

addonEnv.Themes.Register(function(palette)
    for _, layers in pairs(panels) do
        for _, layer in ipairs(layers) do
            if layer.token ~= "border" then layer.texture:SetVertexColor(unpack(palette[layer.token])) end
            if layer.token == "surface" then layer.texture:SetTexture(ROOT .. "surface-" .. Material() .. ".tga") end
        end
    end
    local name = addonEnv.Themes.GetName()
    for panel in pairs(panels) do
        if not windowChrome[panel] then
            panel.FFXIVUIGrain:SetAlpha((name == "Dark" or name == "Light") and 0.018 or 0)
        end
    end
end)