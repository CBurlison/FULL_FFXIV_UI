local sources = {}
for _, path in ipairs({"FFXIV_UI\\General\\WindowControls.xml", "FFXIV_UI\\General\\RoundedPanels.xml", "FFXIV_UI\\General\\Inventory.xml", "FFXIV_UI\\General\\Social.xml", "FFXIV_UI\\General\\Tooltips\\AuraTooltip.xml", "FFXIV_UI\\General\\Tooltips\\Tooltip.xml"}) do
    local file = assert(io.open(path, "rb"))
    sources[#sources + 1] = file:read("*a")
    file:close()
end
local xml = table.concat(sources, "\n")

return function(texture, parent, template)
    if not template or not (template:find("^FFXIV_Control") or template:find("^FFXIV_ExtractedTab")
        or template:find("^FFXIV_CollapsibleHeader") or template:find("^FFXIV_WindowBackground")
        or template:find("^FFXIV_WindowRim") or template:find("^FFXIV_WindowHeader")
        or template:find("^FFXIV_RoundSurface") or template:find("^FFXIV_RoundBorder")
        or template:find("^FFXIV_RoundFill") or template:find("^FFXIV_RoundGrain")
        or template:find("^FFXIV_Inventory") or template:find("^FFXIV_Social")
        or template:find("^FFXIV_AuraTooltip") or template:find("^FFXIV_Tooltip")) then
        return false
    end
    local kind, attributes = xml:match('<(%w+) name="' .. template .. '"([^>]-)>')
    assert(attributes,
        "Missing shared control template: " .. template)
    assert(kind == texture:GetObjectType(), "Unexpected shared control template type: " .. template)
    local body = ""
    if attributes:sub(-1) ~= "/" then
        body = assert(xml:match('<' .. kind .. ' name="' .. template .. '"[^>]*>(.-)</' .. kind .. '>'))
    end
    if kind == "FontString" then
        local inherits = attributes:match('inherits="([^"]+)"')
        texture.font = inherits and {inherits, 12, ""} or nil
        local justify = attributes:match('justifyH="([^"]+)"')
        if justify then texture:SetJustifyH(justify) end
    end
    if attributes:find('setAllPoints="true"', 1, true) then texture:SetAllPoints(parent) end
    if attributes:find('enableMouse="false"', 1, true) then texture:EnableMouse(false) end
    local path = attributes:match('file="([^"]+)"')
    if path then
        texture:SetTexture(path, attributes:match('hWrapMode="([^"]+)"'), attributes:match('vWrapMode="([^"]+)"'))
    end
    local alpha = attributes:match('alpha="([^"]+)"')
    if alpha then texture:SetAlpha(assert(tonumber(alpha))) end
    if attributes:find('horizTile="true"', 1, true) then texture:SetHorizTile(true) end
    if attributes:find('vertTile="true"', 1, true) then texture:SetVertTile(true) end
    local size = body:match("<Size (.-)/>")
    if size then
        local width, height = size:match('x="([^"]+)"'), size:match('y="([^"]+)"')
        if width then texture:SetWidth(assert(tonumber(width))) end
        if height then texture:SetHeight(assert(tonumber(height))) end
    end
    for anchor in body:gmatch("<Anchor (.-)/>") do
        local point = assert(anchor:match('point="([^"]+)"'))
        texture:SetPoint(point, parent, point, tonumber(anchor:match('x="([^"]+)"')) or 0,
            tonumber(anchor:match('y="([^"]+)"')) or 0)
    end
    local left, right, top, bottom = body:match('<TexCoords left="([^"]+)" right="([^"]+)" top="([^"]+)" bottom="([^"]+)"/>')
    if left then texture:SetTexCoord(tonumber(left), tonumber(right), tonumber(top), tonumber(bottom)) end
    local r, g, b, a = body:match('<Color r="([^"]+)" g="([^"]+)" b="([^"]+)" a="([^"]+)"/>')
    if r then texture:SetColorTexture(tonumber(r), tonumber(g), tonumber(b), tonumber(a)) end
    return true
end
