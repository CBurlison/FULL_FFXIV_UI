local frame
function CreateFrame()
    frame = {scripts = {}, events = {}}
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    return frame
end

local playing, played, stopped = {}, {}, {}
local nextHandle, failPlayback = 0, false
function PlaySoundFile(path, channel)
    played[#played + 1] = {path = path, channel = channel}
    if failPlayback then return nil end
    nextHandle = nextHandle + 1
    playing[nextHandle] = true
    return true, nextHandle
end
C_Sound = {IsPlaying = function(handle) return playing[handle] == true end}
function StopSound(handle)
    stopped[#stopped + 1] = handle
    playing[handle] = nil
end
function GetTime() return 1 end
function UnitExists() return false end
SlashCmdList = {}

assert(loadfile("FFXIV_UI\\General\\SoundEffects.lua"))()
local function event(name, ...)
    assert(frame.events[name], "event not registered: " .. name)
    frame.scripts.OnEvent(frame, name, ...)
end
event("ADDON_LOADED", "FFXIV_UI")

event("QUEST_ACCEPTED")
assert(#played == 1 and played[1].path:find("Quiet\\FFXIV_Quest_Accepted.ogg", 1, true))
assert(played[1].channel == "SFX")
FFXIV_UI_DB.questAcceptSFX = 2
event("QUEST_ACCEPTED")
assert(#played == 1 and #stopped == 0, "same type must not interrupt even after selection changes")

event("QUEST_TURNED_IN")
assert(#played == 2 and stopped[1] == 1, "completion must interrupt acceptance")
event("QUEST_TURNED_IN")
assert(#played == 2 and #stopped == 1, "repeated completion must be ignored")
event("QUEST_ACCEPTED")
assert(#played == 3 and stopped[2] == 2, "acceptance must interrupt completion")
assert(played[3].path:find("FFXIV_Quest_Accepted_HW.ogg", 1, true))

playing[3] = nil
event("QUEST_ACCEPTED")
assert(#played == 4 and #stopped == 2, "a finished sound must be allowed to play again")
FFXIV_UI_DB.sfxEnabled = false
event("QUEST_TURNED_IN")
assert(#played == 4 and #stopped == 2, "disabled sounds must not interrupt playback")
FFXIV_UI_DB.sfxEnabled = true
FFXIV_UI_DB.questCompleteSFX = 0
event("QUEST_TURNED_IN")
assert(#played == 4 and #stopped == 2, "a disabled quest sound must not interrupt playback")

FFXIV_UI_DB.questCompleteSFX = 1
failPlayback = true
event("QUEST_TURNED_IN")
assert(#played == 5 and stopped[3] == 4, "opposite sound must stop before playback is attempted")
failPlayback = false
event("QUEST_TURNED_IN")
assert(#played == 6 and #stopped == 3, "failed playback must not block a later attempt")

event("PLAYER_LEVEL_UP")
assert(#played == 7 and #stopped == 3, "unrelated sound effects must remain independent")
event("QUEST_TURNED_IN")
assert(#played == 7, "unrelated sound effects must not replace the tracked quest sound")

print("PASS: quest sound deduplication, interruption, completion, disabled settings, and playback failure")
