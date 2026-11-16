local namespace, lastFrame = {}, nil
local scripts = {}

function CreateFrame()
    local frame = {scripts = {}}
    function frame:RegisterEvent() end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    lastFrame = frame
    return frame
end

local buildNumber
function GetBuildInfo() return "", "", "", buildNumber end

local function load(build)
    buildNumber = build
    local styled = {}
    namespace.StyleDetailPanel = function(frame) styled[#styled + 1] = frame end
    _G.PVPRankFrame = {DetailFrame = {}}
    assert(loadfile("FFXIV_UI\\General\\PvP.lua"))("FFXIV_UI", namespace)
    lastFrame.scripts.OnEvent(lastFrame, "PLAYER_LOGIN")
    return styled
end

assert(#load(110005) == 0, "Retail has no Camelot PvP rank page to style")
local styled = load(16001)
assert(#styled == 1 and styled[1] == _G.PVPRankFrame.DetailFrame,
    "Forever must give PVPRankFrame.DetailFrame the surface detail panel")
print("PASS PvP detail pane gets the surface panel on Forever only")

for _, file in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local handle = assert(io.open(file, "r"))
    local toc = handle:read("*a")
    handle:close()
    assert(assert(toc:find("General/RoundedPanels.lua", 1, true)) < assert(toc:find("General/PvP.lua", 1, true)),
        file .. " must load PvP.lua after RoundedPanels.lua")
end
print("PASS PvP.lua loads after RoundedPanels.lua in both TOCs")
