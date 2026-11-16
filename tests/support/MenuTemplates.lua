local file = assert(io.open("FFXIV_UI\\General\\FFXIV_UI_Menu.xml", "rb"))
local xml = file:read("*a")
file:close()

local body = assert(xml:match('<Frame name="FFXIV_AnchorVisualTemplate"[^>]*>(.-)</Frame>'),
    "Missing anchor visual template")

local function readAnchors(inner, record)
    record.points = {}
    for point, x, y in inner:gmatch('<Anchor point="(%u+)" x="([^"]+)" y="([^"]+)"/>') do
        record.points[#record.points + 1] = {point = point, x = tonumber(x), y = tonumber(y)}
    end
end

return function(visual)
    for key, inherits, inner in body:gmatch('<FontString parentKey="(%w+)" inherits="([^"]+)">(.-)</FontString>') do
        local text = visual:CreateFontString(nil, "OVERLAY", inherits)
        text.font = inherits
        readAnchors(inner, text)
        visual[key] = text
    end
    for key, inner in body:gmatch('<Button parentKey="(%w+)">(.-)</Button>') do
        local button = CreateFrame("Button", nil, visual)
        local width, height = inner:match('<Size x="([^"]+)" y="([^"]+)"/>')
        button.width, button.height = tonumber(width), tonumber(height)
        readAnchors(inner, button)
        button.normalFile = inner:match('<NormalTexture file="([^"]+)"/>')
        button.pushedFile = inner:match('<PushedTexture file="([^"]+)"/>')
        button.highlightFile, button.highlightAlphaMode =
            inner:match('<HighlightTexture file="([^"]+)" alphaMode="([^"]+)"/>')
        visual[key] = button
    end
end
