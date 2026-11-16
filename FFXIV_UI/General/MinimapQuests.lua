local addonName, addonEnv = ...
local ICON_ROOT = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Quests\\"
local STEP, PER_FRAME, WAIT = 8, 24, 0.5
local frame = CreateFrame("Frame", nil, Minimap, "FFXIV_MinimapQuestOverlayTemplate")
frame:SetFrameLevel(Minimap:GetFrameLevel() + 5)
local icons, scan, wait, previous = {}, nil, 0, nil
local reported = false
local locations = {}

local function Readable(value)
    return not (issecretvalue and issecretvalue(value))
end

local function Clear()
    scan, previous, wait = nil, nil, 0
    locations = {}
    for _, icon in ipairs(icons) do icon:Hide() end
end

local function Position()
    if not C_Map or not C_Map.GetMapWorldSize or not C_Minimap or not C_Minimap.GetViewRadius then return end
    local map = C_Map.GetBestMapForUnit("player")
    if not Readable(map) or not map then return end
    local position = C_Map.GetPlayerMapPosition(map, "player")
    if not Readable(position) or not position then return end
    local x, y = position:GetXY()
    local width, height = C_Map.GetMapWorldSize(map)
    local radius = C_Minimap.GetViewRadius()
    local values = {x, y, width, height, radius}
    for index = 1, 5 do
        local value = values[index]
        if not Readable(value) or type(value) ~= "number" then return end
    end
    if width <= 0 or height <= 0 or radius <= 0 then return end
    local rotating = C_CVar and C_CVar.GetCVar("rotateMinimap") == "1"
    local angle = rotating and GetPlayerFacing() or 0
    if not Readable(angle) or type(angle) ~= "number" then return end
    return {map = map, x = x, y = y, width = width, height = height, radius = radius, angle = angle}
end

local function ScreenPoint(location, position, width, height)
    local east = (location.x - position.x) * position.width
    local north = (position.y - location.y) * position.height
    local cosine, sine = math.cos(position.angle), math.sin(position.angle)
    return width / 2 + (east * cosine + north * sine) / position.radius * width / 2,
        height / 2 + (north * cosine - east * sine) / position.radius * height / 2
end

local function Follow(position, width, height)
    for index, location in pairs(locations) do
        local icon = icons[index]
        if not position or location.map ~= position.map then
            icon:Hide()
        else
            local x, y = ScreenPoint(location, position, width, height)
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", Minimap, "BOTTOMLEFT", x, y)
            x, y = x - width / 2, y - height / 2
            if x * x + y * y <= (math.min(width, height) / 2 - 16)^2 then icon:Show() else icon:Hide() end
        end
    end
end

local function Supported()
    return Minimap and Minimap.SetUsingSoftCursor and Minimap.UpdateMouseoverAtPoint
        and C_TooltipInfo and C_TooltipInfo.GetMinimapMouseover
end

local function CompletedTitles()
    local titles, seen = {}, {}
    for index = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(index)
        if info and Readable(info) and Readable(info.title) and Readable(info.questID)
            and Readable(info.isHeader) and not info.isHeader
            and type(info.title) == "string" and type(info.questID) == "number" then
            if seen[info.title] then
                titles[info.title] = nil
            else
                seen[info.title] = true
                local complete = C_QuestLog.IsComplete(info.questID)
                if Readable(complete) and complete == true then titles[info.title] = info.questID end
            end
        end
    end
    return titles
end

local function Probe(current, point)
    Minimap:UpdateMouseoverAtPoint((current.left + point.x) * current.scale,
        (current.bottom + point.y) * current.scale)
    local data = C_TooltipInfo.GetMinimapMouseover()
    if not Readable(data) or not data or not Readable(data.lines) or not data.lines then return end
    local title
    for _, line in ipairs(data.lines) do
        if Readable(line) and Readable(line.leftText) and type(line.leftText) == "string" then
            local candidate = line.leftText
            if current.titles[candidate] then
                if title and title ~= candidate then return end
                title = candidate
            end
        end
    end
    if title then
        current.hits[title] = current.hits[title] or {}
        current.hits[title][point.key] = point
    end
end

local function Finish(current)
    local count = 0
    local confirmed = {}
    for _, location in pairs(locations) do confirmed[location.questID] = location end
    locations = {}
    for title, hits in pairs(current.hits) do
        local clusters, center = 0, nil
        while next(hits) do
            clusters = clusters + 1
            local key, point = next(hits)
            local queue, head = {point}, 1
            hits[key] = nil
            local x, y, n = 0, 0, 0
            local minX, maxX, minY, maxY = point.x, point.x, point.y, point.y
            while head <= #queue do
                point = queue[head]
                head = head + 1
                x, y, n = x + point.x, y + point.y, n + 1
                minX, maxX = math.min(minX, point.x), math.max(maxX, point.x)
                minY, maxY = math.min(minY, point.y), math.max(maxY, point.y)
                for dx = -1, 1 do
                    for dy = -1, 1 do
                        local neighbor = point.key + dx * 10000 + dy
                        if hits[neighbor] then
                            queue[#queue + 1] = hits[neighbor]
                            hits[neighbor] = nil
                        end
                    end
                end
            end
            if n >= 2 and maxX - minX <= 40 and maxY - minY <= 40 then center = {x / n, y / n} end
        end
        -- Multiple separated hits for one title cannot be identified unambiguously.
        if clusters == 1 and center then
            count = count + 1
            if not icons[count] then
                icons[count] = frame:CreateTexture(nil, "OVERLAY", "FFXIV_MinimapQuestMarkerTemplate")
            end
            local icon = icons[count]
            local selected = C_SuperTrack.GetSuperTrackedQuestID() == current.titles[title]
            icon:SetTexture(ICON_ROOT .. "CompleteQuest" .. (selected and "_Blue_Icon.tga" or "_Icon.tga"))
            local position = current.position
            if position then
                local east = (center[1] - current.width / 2) / (current.width / 2) * position.radius
                local north = (center[2] - current.height / 2) / (current.height / 2) * position.radius
                local cosine, sine = math.cos(position.angle), math.sin(position.angle)
                locations[count] = {
                    questID = current.titles[title],
                    map = position.map,
                    x = position.x + (east * cosine - north * sine) / position.width,
                    y = position.y - (north * cosine + east * sine) / position.height,
                }
                local known = confirmed[current.titles[title]]
                if known and known.map == position.map then
                    local x, y = ScreenPoint(known, position, current.width, current.height)
                    -- Keep grid-sized sampling noise from moving a confirmed marker.
                    if (x - center[1])^2 + (y - center[2])^2 <= STEP^2 then
                        locations[count] = known
                        center = {x, y}
                    end
                end
            end
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", Minimap, "BOTTOMLEFT", center[1], center[2])
            icon:Show()
        end
    end
    for index = count + 1, #icons do icons[index]:Hide() end
    scan, wait = nil, WAIT
end

local function OnUpdate(_, elapsed)
    local speed = GetUnitSpeed("player")
    if InCombatLockdown() or not Minimap:IsVisible()
        or not Readable(speed) then Clear(); return end
    local left, bottom = Minimap:GetLeft(), Minimap:GetBottom()
    if not left or not bottom then Clear(); return end
    local width, height, scale = Minimap:GetWidth(), Minimap:GetHeight(), Minimap:GetEffectiveScale()
    local facing, zoom = GetPlayerFacing(), Minimap:GetZoom()
    local position = Position()
    if not position and next(locations) then Clear() end
    if not previous or previous.width ~= width or previous.height ~= height or previous.scale ~= scale
        or previous.left ~= left or previous.bottom ~= bottom
        or (not position and (previous.facing ~= facing or previous.zoom ~= zoom)) then
        Clear()
        previous = {width = width, height = height, scale = scale, left = left, bottom = bottom, facing = facing, zoom = zoom}
    end
    if position then Follow(position, width, height) end
    if scan and position and scan.position and (position.map ~= scan.position.map
        or position.x ~= scan.position.x or position.y ~= scan.position.y
        or position.radius ~= scan.position.radius or position.angle ~= scan.position.angle) then scan = nil end
    if speed > 0 or Minimap:IsMouseOver() then
        if speed > 0 and not position then Clear() end
        scan, wait = nil, 0
        return
    end
    if not scan then
        wait = wait - elapsed
        if wait > 0 then return end
        local titles = CompletedTitles()
        if not next(titles) then Clear(); wait = WAIT; return end
        scan = {titles = titles, points = {}, hits = {}, next = 1, left = left, bottom = bottom, scale = scale,
            position = position, width = width, height = height}
        local radius = math.min(width, height) / 2 - 16
        for x = 0, math.floor(width / STEP) do
            for y = 0, math.floor(height / STEP) do
                if (x * STEP - width / 2)^2 + (y * STEP - height / 2)^2 <= radius^2 then
                    scan.points[#scan.points + 1] = {x = x * STEP, y = y * STEP, key = x * 10000 + y}
                end
            end
        end
    end
    local current = scan
    Minimap:SetUsingSoftCursor(true)
    for index = current.next, math.min(current.next + PER_FRAME - 1, #current.points) do
        Probe(current, current.points[index])
    end
    Minimap:SetUsingSoftCursor(false)
    current.next = current.next + PER_FRAME
    if current.next > #current.points then Finish(current) end
end

local function Refresh()
    Clear()
    frame:SetScript("OnUpdate", nil)
    if FFXIV_UI_DB.minimapQuestOverlayEnabled ~= true then return end
    if not Supported() then
        if not reported then
            print("FFXIV UI: minimap quest overlay unavailable; this client lacks the minimap tooltip scanning APIs.")
            reported = true
        end
        return
    end
    frame:SetScript("OnUpdate", OnUpdate)
end

addonEnv.SetMinimapQuestOverlayEnabled = function(enabled)
    FFXIV_UI_DB.minimapQuestOverlayEnabled = enabled
    Refresh()
end
for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "SUPER_TRACKING_CHANGED", "PLAYER_REGEN_DISABLED"}) do
    frame:RegisterEvent(event)
end
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then Refresh() else Clear() end
end)
