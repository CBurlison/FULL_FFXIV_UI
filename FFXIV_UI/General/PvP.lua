local addonName, ns = ...

-- Forever only (build 16001): the Camelot PVPRankFrame. Its DetailFrame is a character side pane;
-- CharacterFrame's Layout() places it beside the page, and StyleDetailPanel restyles its AddCategory headers.
local function StyleDetail()
    if select(4, GetBuildInfo()) ~= 16001 then return end
    local frame = _G.PVPRankFrame and _G.PVPRankFrame.DetailFrame
    if frame and ns.StyleDetailPanel then ns.StyleDetailPanel(frame) end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:SetScript("OnEvent", StyleDetail)
