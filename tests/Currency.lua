local namespace, lastFrame = {}, nil

function CreateFrame()
    local frame = {scripts = {}}
    function frame:RegisterEvent() end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    lastFrame = frame
    return frame
end

ScrollBoxListMixin = {Event = {OnInitializedFrame = "init", OnDataRangeChanged = "range"}}
local buildNumber
function GetBuildInfo() return "", "", "", buildNumber end

local function header() return {Name = {}, StateIcon = {}} end
-- TokenEntryTemplate rows and TokenSubHeaderTemplate rows have no StateIcon.
local function entry() return {Content = {Name = {}, Count = {}, CurrencyIcon = {}}} end
local function subHeader() return {Text = {}, ToggleCollapseButton = {}} end

local styledHeaders, styledPanels, callbacks
local registrations = 0
local function load(build, tokenFrame)
    buildNumber = build
    styledHeaders, styledPanels, callbacks = {}, {}, {}
    namespace.StyleForeverCollapsibleHeader = function(row) styledHeaders[#styledHeaders + 1] = row end
    namespace.StyleDetailPanel = function(frame) styledPanels[#styledPanels + 1] = frame end
    _G.TokenFrame = tokenFrame
    assert(loadfile("FFXIV_UI\\General\\Currency.lua"))("FFXIV_UI", namespace)
    return lastFrame
end

local function tokenFrame(frames)
    return {
        DetailFrame = {},
        ScrollBox = {
            ForEachFrame = function(_, callback) for _, frame in ipairs(frames) do callback(frame) end end,
            RegisterCallback = function(_, event, callback)
                callbacks[event] = callback
                registrations = registrations + 1
            end,
        },
    }
end

local retail = load(110005, tokenFrame({header()}))
retail.scripts.OnEvent(retail, "PLAYER_LOGIN")
assert(#styledHeaders == 0 and #styledPanels == 0, "Retail keeps its own Currency tab")
print("PASS Currency styling is Forever only")

-- Blizzard_TokenUI is load-on-demand: nothing exists at login, so styling waits for ADDON_LOADED.
local watcher = load(16001, nil)
watcher.scripts.OnEvent(watcher, "PLAYER_LOGIN")
assert(#styledHeaders == 0 and #styledPanels == 0, "nothing to style before Blizzard_TokenUI loads")
local first, row, sub = header(), entry(), subHeader()
_G.TokenFrame = tokenFrame({first, row, sub})
watcher.scripts.OnEvent(watcher, "ADDON_LOADED", "Blizzard_TokenUI")
assert(#styledHeaders == 1 and styledHeaders[1] == first, "only top-level currency headers get the ComboBox header")
assert(#styledPanels == 1 and styledPanels[1] == _G.TokenFrame.DetailFrame, "TokenDetailFrame must get the surface panel")
print("PASS Currency headers and detail pane are styled once Blizzard_TokenUI loads")

local late = header()
callbacks.init(nil, late)
assert(styledHeaders[#styledHeaders] == late, "headers created later by the ScrollBox must be styled")
watcher.scripts.OnEvent(watcher, "ADDON_LOADED", "Other")
assert(registrations == 2, "re-running the watcher must not re-register ScrollBox callbacks")
print("PASS Currency styles recycled and late header rows")

for _, file in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local handle = assert(io.open(file, "r"))
    local toc = handle:read("*a")
    handle:close()
    assert(assert(toc:find("General/WindowControls.lua", 1, true)) < assert(toc:find("General/Currency.lua", 1, true)),
        file .. " must load Currency.lua after WindowControls.lua")
end
print("PASS Currency.lua loads after the shared header styling in both TOCs")
