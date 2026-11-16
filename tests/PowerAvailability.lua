local maxPower = 0

local function newFrame()
    local frame = {events = {}, scripts = {}}
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:UnregisterAllEvents() self.events = {} end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    return frame
end

local createdFrames = {}
CreateFrame = function()
    local frame = newFrame()
    createdFrames[#createdFrames + 1] = frame
    return frame
end
UnitPowerMax = function(unit, powerType)
    assert(unit == "player")
    return maxPower
end

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local addonEnv = {}
local source = readFile("FFXIV_UI\\General\\PowerAvailability.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "PowerAvailability.lua"))("FFXIV_UI", addonEnv)

local POWER = 9

-- Ready at load: callback runs immediately and no waiter frame is created.
maxPower = 5
local calls = 0
addonEnv.OnPlayerPowerReady(POWER, function() calls = calls + 1 end)
assert(calls == 1, "callback should run immediately when power is ready")
assert(#createdFrames == 0, "no waiter needed when power is ready")

-- Not ready at load (the fresh-login case): callback waits for later events.
maxPower = 0
createdFrames = {}
calls = 0
addonEnv.OnPlayerPowerReady(POWER, function() calls = calls + 1 end)
assert(calls == 0, "callback must not run while max power reads 0")
assert(#createdFrames == 1, "a waiter frame should be created")
local waiter = createdFrames[1]
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_SPECIALIZATION_CHANGED", "UNIT_MAXPOWER"}) do
    assert(waiter.events[event], "waiter should listen for " .. event)
end

-- Still 0 on an event: keep waiting.
waiter.scripts.OnEvent(waiter, "PLAYER_ENTERING_WORLD")
assert(calls == 0, "callback must not run while max power is still 0")
assert(waiter.scripts.OnEvent ~= nil, "waiter should keep listening")

-- Max power becomes readable on a later event: callback runs once and the waiter stops.
maxPower = 5
waiter.scripts.OnEvent(waiter, "UNIT_MAXPOWER", "player")
assert(calls == 1, "callback should run once power is ready")
assert(next(waiter.events) == nil, "waiter should unregister its events")
assert(waiter.scripts.OnEvent == nil, "waiter should clear its handler")

-- Every gated gauge must use the deferred helper instead of returning at file load.
local gauges = {
    "PaladinGauge", "WarlockGauge", "MonkGauge", "RogueGauge",
    "EvokerGauge", "MageGauge", "FeralGauge",
}
for _, name in ipairs(gauges) do
    local text = readFile("FFXIV_UI\\JobGauges\\" .. name .. ".lua")
    assert(text:find("addonEnv.OnPlayerPowerReady(POWER_TYPE, function()", 1, true),
        name .. " should defer setup through OnPlayerPowerReady")
    assert(not text:find("HasPlayerPower(POWER_TYPE) then return end", 1, true),
        name .. " must not return at file load when power is not yet readable")
end

print("PowerAvailability tests passed")
