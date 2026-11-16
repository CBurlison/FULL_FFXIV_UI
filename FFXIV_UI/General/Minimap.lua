local addonName, ns = ...
local addon = CreateFrame("Frame")
addon:RegisterEvent("PLAYER_LOGIN")

local function MoveZoomButtons()
    local zoomIn  = Minimap.ZoomIn
    local zoomOut = Minimap.ZoomOut
    if not zoomIn or not zoomOut then return end


    zoomIn:SetParent(FFXIV_MinimapFrame)
    zoomOut:SetParent(FFXIV_MinimapFrame)

    zoomIn:ClearAllPoints()
    zoomOut:ClearAllPoints()
    zoomIn:SetPoint("RIGHT", Minimap, "RIGHT", 9, 20)
    zoomOut:SetPoint("RIGHT", Minimap, "RIGHT", 9, -18)
    zoomIn:SetScale(1.2)
    zoomOut:SetScale(1.2)

    local overlayLevel = FFXIV_MinimapFrame:GetFrameLevel()
    zoomIn:SetFrameLevel(overlayLevel + 2)
    zoomOut:SetFrameLevel(overlayLevel + 2)
end

addon:SetScript("OnEvent", function()

    if FFXIV_MinimapFrame then return end

 
    local elements = {
        MinimapBorder, MinimapBorderTop, MiniMapTracking, 
        MiniMapMailFrame, MinimapZoneTextButton, TimeManagerClockButton
    }
    for _, el in pairs(elements) do if el then el:Hide() end end


    local frame = CreateFrame("Frame", "FFXIV_MinimapFrame", Minimap, "FFXIV_MinimapTemplate")
    frame:Show()

local texture2 = frame.texture2
local coordsFrame = frame.coordsFrame
local xInt = coordsFrame.xInt
local xDec = coordsFrame.xDec
xDec:ClearAllPoints()
xDec:SetPoint("LEFT", xInt, "RIGHT", 0, 0)

local yInt = coordsFrame.yInt
yInt:ClearAllPoints()
yInt:SetPoint("LEFT", xDec, "RIGHT", 8, 0)  

local yDec = coordsFrame.yDec
yDec:ClearAllPoints()
yDec:SetPoint("LEFT", yInt, "RIGHT", 0, 0)


local function splitCoord(val)
    local total = val * 100
    local intPart = math.floor(total)
    local decPart = math.floor((total - intPart) * 10)
    return intPart, decPart
end


local function UpdateCoords()
    if UnitIsDeadOrGhost("player") then
        texture2:Hide()
        xInt:SetText("")
        xDec:SetText("")
        yInt:SetText("")
        yDec:SetText("")
        return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        texture2:Hide()
        xInt:SetText("")
        xDec:SetText("")
        yInt:SetText("")
        yDec:SetText("")
        return
    end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then
        local x, y = pos:GetXY()
        local xI, xD = splitCoord(x)
        local yI, yD = splitCoord(y)

        xInt:SetText("X: "..xI)
        xDec:SetText("."..xD)
        yInt:SetText("Y: "..yI)
        yDec:SetText("."..yD)
        texture2:Show()
    else
        xInt:SetText("")
        xDec:SetText("")
        yInt:SetText("")
        yDec:SetText("")
        texture2:Hide()
    end
end



C_Timer.NewTicker(0.2, UpdateCoords)



    MoveZoomButtons()
end)


