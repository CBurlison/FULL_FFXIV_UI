FFXIV_UI = FFXIV_UI or {}

local frame = CreateFrame("Frame")

local events = {
    "ADDON_LOADED",  
    "PLAYER_LOGOUT",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_TARGET_CHANGED",
    "UI_ERROR_MESSAGE",
    "LOOT_OPENED",
    "PLAYER_LEVEL_UP",
    "RAID_INSTANCE_WELCOME",
    "CHAT_MSG_WHISPER",
    "QUEST_ACCEPTED",
    "QUEST_TURNED_IN"
}

for _, event in ipairs(events) do 
    frame:RegisterEvent(event) 
end

 
local lastPlayTime = 0
local lastTargetGUID = nil

 
local DEBUG_MODE = false

local function DebugPrint(...)
    if DEBUG_MODE then
        print("|cff00ffff[FFXIV_UI Debug]|r", ...)
    end
end


local QuestAcceptSounds = {
     "FFXIV_Quest_Accepted.ogg",
     "FFXIV_Quest_Accepted_HW.ogg",
     "FFXIV_Quest_Accepted_SB.ogg",
     "FFXIV_Quest_Accepted_ShB.ogg",
     "FFXIV_Quest_Accepted_EW.ogg",
     "FFXIV_Quest_Accepted_DT.mp3",

      "FFXIV_Quest_Accepted_Island.ogg",
      "FFXIV_Quest_Accepted_Tribal.ogg",
}

local QuestCompleteSounds = {
     "FFXIV_Quest_Complete.ogg",
     "FFXIV_Quest_Complete_HW.ogg",
     "FFXIV_Quest_Complete_SB.ogg",
     "FFXIV_Quest_Complete_ShB.ogg",
     "FFXIV_Quest_Complete_EW.ogg",
     "FFXIV_Quest_Complete_DT.mp3",

     "FFXIV_Quest_Complete_Island.ogg",
}

local questSoundGroups = {
    { setting = "questAcceptSFX", replacements = QuestAcceptSounds, soundIDs = {567400} },
    { setting = "questCompleteSFX", replacements = QuestCompleteSounds, soundIDs = {567439, 567476} },
}

function FFXIV_UI.UpdateQuestSoundMutes(restoreDefaults)
    local settings = FFXIV_UI_DB or {}
    for _, group in ipairs(questSoundGroups) do
        local replaceSound = not restoreDefaults and settings.sfxEnabled and group.replacements[settings[group.setting] or 1] ~= nil
        local soundFunction = replaceSound and MuteSoundFile or UnmuteSoundFile
        if type(soundFunction) == "function" then
            for _, soundID in ipairs(group.soundIDs) do
                soundFunction(soundID)
            end
        end
    end
end


function FFXIV_UI.GetCustomSFXPath(fileName)
    local audioFolder = FFXIV_UI_DB.reduceAudioVolume ~= false and "Quiet\\" or ""
    return "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\" .. audioFolder .. fileName
end

local function PlayCustomSFX(fileName)

    if not FFXIV_UI_DB or not FFXIV_UI_DB.sfxEnabled then
        return
    end

    if fileName == "FFXIV_Error.mp3" and not FFXIV_UI_DB.errorSfxEnabled then
        return
    end

    local path = FFXIV_UI.GetCustomSFXPath(fileName)

    DebugPrint("Attempting to play:", path)

    return PlaySoundFile(path, "SFX")
end

local questSoundHandle, questSoundType

local function PlayQuestSFX(fileName, soundType)
    if not FFXIV_UI_DB or not FFXIV_UI_DB.sfxEnabled then
        return
    end

    if questSoundHandle and C_Sound.IsPlaying(questSoundHandle) then
        if questSoundType == soundType then
            return
        end
        StopSound(questSoundHandle)
    end

    questSoundHandle, questSoundType = nil, nil
    local willPlay, soundHandle = PlayCustomSFX(fileName)
    if willPlay and soundHandle then
        questSoundHandle, questSoundType = soundHandle, soundType
    end
end


frame:SetScript("OnEvent", function(self, event, arg1)

    if event == "ADDON_LOADED" and arg1 == "FFXIV_UI" then

        if FFXIV_UI_DB == nil then
            FFXIV_UI_DB = {}
        end

        if FFXIV_UI_DB.sfxEnabled == nil then
            FFXIV_UI_DB.sfxEnabled = true
        end

        if FFXIV_UI_DB.errorSfxEnabled == nil then
            FFXIV_UI_DB.errorSfxEnabled = true
        end

        if FFXIV_UI_DB.reduceAudioVolume == nil then
            FFXIV_UI_DB.reduceAudioVolume = true
        end

        if FFXIV_UI_DB.questAcceptSFX == nil then
            FFXIV_UI_DB.questAcceptSFX = 1
        end

        if FFXIV_UI_DB.questCompleteSFX == nil then
            FFXIV_UI_DB.questCompleteSFX = 1
        end
         
        lastTargetGUID = UnitExists("target") and UnitGUID("target") or nil

        DebugPrint("Addon loaded. Initial target GUID:", lastTargetGUID)

        FFXIV_UI.UpdateQuestSoundMutes()
        return
    end

    local now = GetTime()


    if event == "PLAYER_LOGOUT" then

        FFXIV_UI.UpdateQuestSoundMutes(true)

    elseif event == "PLAYER_REGEN_DISABLED" then

        DebugPrint("PLAYER_REGEN_DISABLED triggered")

        PlayCustomSFX("FFXIV_Aggro.mp3")


    elseif event == "PLAYER_TARGET_CHANGED" then

        local hasTarget = UnitExists("target")
        
        if now - lastPlayTime < 0.1 then
            return
        end

 
        if not lastTargetGUID or not UnitIsUnit("target", "playertarget") then

            if hasTarget then

                DebugPrint("Playing Switch_Target SFX")

                PlayCustomSFX("FFXIV_Switch_Target.mp3")
               
                lastTargetGUID = UnitGUID("target")

            else

                DebugPrint("Playing Untarget SFX")

                PlayCustomSFX("FFXIV_Untarget.mp3")

                lastTargetGUID = nil
            end

            lastPlayTime = now
        end

        lastTargetGUID = currentGUID


    elseif event == "UI_ERROR_MESSAGE" then

        DebugPrint("UI_ERROR_MESSAGE triggered")

        PlayCustomSFX("FFXIV_Error.mp3")


    elseif event == "LOOT_OPENED" then

        DebugPrint("LOOT_OPENED triggered")

        PlayCustomSFX("FFXIV_Obtain_Item.mp3")


    elseif event == "PLAYER_LEVEL_UP" then

        DebugPrint("PLAYER_LEVEL_UP triggered")

        PlayCustomSFX("FFXIV_Level_Up.mp3")


    elseif event == "RAID_INSTANCE_WELCOME" then

        DebugPrint("RAID_INSTANCE_WELCOME triggered")

        PlayCustomSFX("FFXIV_Enter_Instance.mp3")


    elseif event == "CHAT_MSG_WHISPER" then

        DebugPrint("CHAT_MSG_WHISPER triggered")

        PlayCustomSFX("FFXIV_Incoming_Tell_1.mp3")


  elseif event == "QUEST_ACCEPTED" then

    DebugPrint("QUEST_ACCEPTED triggered")

    local index = FFXIV_UI_DB.questAcceptSFX or 1

    if index > 0 then
        local file = QuestAcceptSounds[index]
        if file then
            PlayQuestSFX(file, "accept")
        end
    end

elseif event == "QUEST_TURNED_IN" then

    DebugPrint("QUEST_TURNED_IN triggered")

    local index = FFXIV_UI_DB.questCompleteSFX or 1

    if index > 0 then
        local file = QuestCompleteSounds[index]
        if file then
            PlayQuestSFX(file, "complete")
        end
    end

    end

end)


SLASH_FFXIVSFX1 = "/FFXIVSFX"

SlashCmdList["FFXIVSFX"] = function()

    FFXIV_UI_DB.sfxEnabled = not FFXIV_UI_DB.sfxEnabled
    FFXIV_UI.UpdateQuestSoundMutes()

    print(
        FFXIV_UI_DB.sfxEnabled
        and "|cff00ff00FFXIV_UI sounds enabled|r"
        or "|cffff0000FFXIV_UI sounds disabled|r"
    )

end


SLASH_FFXIVQUESTACCEPT1 = "/ffxivquestaccept"

SlashCmdList["FFXIVQUESTACCEPT"] = function(msg)

    local num = tonumber(msg)

    if not num or num < 1 or num > 6 then
        print("|cffffcc00Usage: /ffxivquestaccept 1-8|r")
        return
    end

    FFXIV_UI_DB.questAcceptSFX = num
    FFXIV_UI.UpdateQuestSoundMutes()
    print("|cff00ff00Quest Accept sound set to:", num, "|r")

end


SLASH_FFXIVQUESTCOMPLETE1 = "/ffxivquestcomplete"

SlashCmdList["FFXIVQUESTCOMPLETE"] = function(msg)

    local num = tonumber(msg)

    if not num or num < 1 or num > 6 then
        print("|cffffcc00Usage: /ffxivquestcomplete 1-7|r")
        return
    end

    FFXIV_UI_DB.questCompleteSFX = num
    FFXIV_UI.UpdateQuestSoundMutes()
    print("|cff00ff00Quest Complete sound set to:", num, "|r")

end