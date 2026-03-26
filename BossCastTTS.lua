-- prints boss casts during fights
-- TTS boss casts during fights

-- SavedVariable: EntropyBossEvents.bossEventsEnabled bool
local useDifferentVoices = true
local maxVoiceToUse = 2
local maxMessagesPerSecond = 2

local speachStartedTime = nil -- leat time we started speaking. If we queue second message right after this one we do not update the time because we consider them in one time frame

-- When we want to start new speach:
--  if the prev speach was more than 1 sec ago consider all previous speach already finished and reset this counter. Then Increment it to 1
--  if the prev speach was less than 1 sec ago increment this counter
local speachStartedCount = 0

local function ToStringEx(x)
    return tostring(x) .. (issecretvalue(x) and "(S)" or "")
end

local function ProcessCast(event, spellID)
    -- spellID is often nil on Stop/Interrupt events
    local spellInfo = spellID and C_Spell.GetSpellInfo(spellID)

    local tNow = GetTime()
    local lastSpeachFinished = true
    if speachStartedTime and (tNow - speachStartedTime) < 1 then lastSpeachFinished = false end


    if event == "UNIT_SPELLCAST_INTERRUPTED" then
        if spellInfo then
            print("|cFFFF0000[BossEvents]|r " .. "Interrupted: " .. ToStringEx(spellInfo.name))
        else
            -- for single boss fights we can assume it is the last spell that they started casting
            print("|cFFFF0000[BossEvents]|r " .. "Interrupted: a spell")
        end        
    else
        if not spellInfo then return end -- no meaningful actions if we don't have the spell id

        if lastSpeachFinished then
            speachStartedCount = 1
        else
            speachStartedCount = speachStartedCount + 1
        end

        local skip = speachStartedCount > maxMessagesPerSecond
        local sSkip = ""
        if skip then sSkip = "(skip)" end

        local iVoice = 0
        if useDifferentVoices then
            iVoice = (speachStartedCount - 1) % maxVoiceToUse -- note that speachStartedCount always >= 1
        end

        print("|cFFFF0000[BossEvents]|r Boss: " .. ToStringEx(unit) .. ": " .. ToStringEx(spellInfo.name) .. " (id: " .. ToStringEx(spellID) .."), " .. ToStringEx(spellInfo.castTime) .. "ms; Queue:" .. tostring(speachStartedCount) .. sSkip .. " " .. tostring(iVoice))
        
        if not skip then
            -- C_VoiceChat.SpeakText(voiceID, text, rate, volume [, overlap]))
            -- works well with secret in spellInfo.name
            C_VoiceChat.SpeakText(iVoice, spellInfo.name, 3, 100, true)

            if lastSpeachFinished then
                speachStartedTime = tNow
            end
        else 
            print("|cFFFF0000[BossEvents]|r Skipped " .. tostring(skip))
        end
    end
end

local function test()
    print("|cFFFF0000[BossEvents]|r Test. 3 calls fast:")
	ProcessCast("UNIT_SPELLCAST_START", 1224299)
    ProcessCast("UNIT_SPELLCAST_START", 1224299)
    ProcessCast("UNIT_SPELLCAST_START", 1224299)
    print("|cFFFF0000[BossEvents]|r Test. 1 with delay:")
    C_Timer.After(1.2,function()
        ProcessCast("UNIT_SPELLCAST_START", 1224299)
    end)
end


-- SLASH COMMANDS

-- /BossEvents on|off|?|
--    Shows/hides the texts
SLASH_BOSSEVENTS1 = "/BossEvents"
SlashCmdList["BOSSEVENTS"] = function(msg)
    if msg == "on" or not msg or msg == "" then
        EntropyBossEvents.bossEventsEnabled = true
        print("|cFFFF0000[BossEvents]|r |cFF00FF00BossEvents on|r")
    elseif msg == "off" then
        EntropyBossEvents.bossEventsEnabled = false
        print("|cFFFF0000[BossEvents]|r |cFFFF0000BossEvents off|r")
    elseif msg == "test" then
        test()
    else
        print("|cFFFF0000[BossEvents]|r Usage: /BossEvents [on | off | test]")
    end
    print("|cFFFF0000[BossEvents]|r Enabled: " .. tostring(EntropyBossEvents.bossEventsEnabled))
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
--frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED") -- When a channeled spell is interrupted, UNIT_SPELLCAST_INTERRUPTED usually fires first, followed by UNIT_SPELLCAST_CHANNEL_STOP
--frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP") -- fires every time a cast ends (even if it was successful). If you only care about the cast being cut short, use UNIT_SPELLCAST_INTERRUPTED.
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Entropy" then
            if EntropyBossEvents == nil then
                EntropyBossEvents = {
                    bossEventsEnabled = true
                }
                print("|cFFFF0000[BossEvents]|r Config not found")
            end
            print("|cFFFF0000[BossEvents]|r Enabled: " .. tostring(EntropyBossEvents.bossEventsEnabled))
        -- else
        --     print("|cFFFF0000[BossEvents]|r Addon: " .. addonName)
        end
        
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        if not EntropyBossEvents.bossEventsEnabled then return end

        local unit, castGUID, spellID = ...
        if not unit:match("^boss") then return end
        
        ProcessCast(event, spellID)

    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...

        -- GetInstanceInfo returns data about the current location https://wowpedia.fandom.com/wiki/API_GetInstanceInfo
        local name, instanceType, difficultyID, difficultyName = GetInstanceInfo() 
        -- instanceType: string - "none" if the player is not in an instance, "scenario" for scenarios, "party" for dungeons, "raid" for raids, "arena" for arenas, and "pvp" for battlegrounds. Many of the following return values will be nil or otherwise useless in the case of "none".

        if instanceType ~= "party" and instanceType ~= "raid" then
            return
        end

        print("|cFFFF0000[BossEvents]|rYou have entered a ".. instanceType .." instance: " .. name .. ", " .. difficultyName)
        print("|cFFFF0000[BossEvents]|r Enabled: " .. tostring(EntropyBossEvents.bossEventsEnabled) .. " use /BossEvents on|off to change.")
        if not isReloadingUi then
            C_VoiceChat.SpeakText(1, "Boss cast TTS is " .. tostring(EntropyBossEvents.bossEventsEnabled), 2, 80, true)
        end
    end
end)

--[[

-- Define what happens when the event fires
frame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    -- Only trigger if the unit is a boss (boss1, boss2, etc.)
    -- unit may be "boss", "boss1", "target", "focus", "nameplate1", etc.
    --  It may be nil in edge conditions (rare but possible)
    if unit:match("^boss") then
        -- Key,Type,Description
        -- --------------------
        -- name,string,"The localized name of the spell (e.g., ""Fireball"")."
        -- iconID,number,The FileDataID for the spell's icon texture.
        -- castTime,number,The cast time in milliseconds (0 for instant spells).
        -- minRange,number,The minimum range required to cast the spell.
        -- maxRange,number,The maximum range allowed for the spell.
        -- spellID,number,The actual ID of the spell (useful if you passed a name).
        -- originalIconID,number,The original icon if the spell is being overridden.
        local spellInfo = C_Spell.GetSpellInfo(spellID)

        local spellName = spellInfo.name
        local iconID    = spellInfo.iconID
        local castTime  = spellInfo.castTime
        
        -- Basic alert in chat
        print("|cFFFF0000[BossEvents]|r B: " .. ToStringEx(unit) .. ": " .. ToStringEx(spellName) .. " (id: " .. ToStringEx(spellID) .."), " .. ToStringEx(castTime) .. "ms")

        --C_VoiceChat.SpeakText(voiceID, text, rate, volume [, overlap]))
        C_VoiceChat.SpeakText(0, spellName, 3, 50, true)
        -- Optional: Play a built-in game sound
        --PlaySound(8959, "Master") -- Generic "Warning" sound
    end
    if unit:match("^nameplate") then
        local spellInfo = C_Spell.GetSpellInfo(spellID)

        local spellName = spellInfo.name
        local iconID    = spellInfo.iconID
        local castTime  = spellInfo.castTime
        
        -- Basic alert in chat
        print("|c33AA0000[BossEvents]|r N: " .. ToStringEx(unit) .. ": " .. ToStringEx(spellName) .. " (id: " .. ToStringEx(spellID) .."), " .. ToStringEx(castTime) .. "ms")
        --C_VoiceChat.SpeakText(0, spellName, 3, 50, true) <- works OK
    end
end)
]]
