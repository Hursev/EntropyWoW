-- prints boss casts during fights
-- TTS boss casts during fights

-- SavedVariables
--      EntropyBossEvents.bossEventsEnabled bool    - on/off the TTS
--      EntropyBossEvents.bossOnly bool             - true restricts the TTS to Boss spells only
local useDifferentVoices = true
local maxVoiceToUse = 2
local maxMessagesPerSecond = 2

-- Two events arriving within this many seconds of each other are considered
-- duplicates of the same cast (same mob seen under different unit tokens).
-- castGUID and spellID are secrets and MUST NOT be used as keys or in comparisons.
-- We identify duplicates purely by arrival time.
local DEDUP_WINDOW = 0.1

local speachStartedTime = nil -- last time we started speaking. If we queue second message right after this one we do not update the time because we consider them in one time frame

local isInCombat = false -- player in combat
local isInPartyInstance = false
local isInRaidInstance = false
local isInScenarioInstance = false

-- When we want to start new speach:
--  if the prev speach was more than 1 sec ago consider all previous speach already finished and reset this counter. Then Increment it to 1
--  if the prev speach was less than 1 sec ago increment this counter
local speachStartedCount = 0

local VOLUME_BOSS = 90
local VOLUME_NONBOSS = 75

local LOGGING = true
local LOG_DETAILS = false

-------------------------------------------------
-- String Helpers
-------------------------------------------------

local function ToStringEx(x)
    return tostring(x) .. (issecretvalue(x) and "(S)" or "")
end

local function PrintConfig(suffix)
    suffix = suffix or ""
    if EntropyBossEvents then
        local s = " "
        if EntropyBossEvents.bossOnly then s = " (bossOnly) " end
        print("|cFFFF0000[BossEvents]|r Enabled: " .. tostring(EntropyBossEvents.bossEventsEnabled) .. s .. suffix)
    else
        print("|cFFFF0000[BossEvents]|r NO CONFIG!")
    end
end

local function LogTextFromSpellInfo(spellInfo)
    if spellInfo then
        return ToStringEx(spellInfo.name) .. " (id " .. ToStringEx(spellInfo.spellID) ..") " .. ToStringEx(spellInfo.castTime) .. "ms;" -- .."(" .. ToStringEx(castGUID) .. ")"
    else
        return "unknown spell"
    end
end

-- seems always nil in m+
local function LogTextFromCastingInfo(castingInfo)
--[[
    name        = name        ,    
    displayName = displayName ,
    textureID   = textureID   ,
    startTimeMs = startTimeMs , 
    endTimeMs   = endTimeMs   
]]
    if castingInfo then
        return " (CI:" .. ToStringEx(castingInfo.startTimeMs) .."-" .. ToStringEx(castingInfo.endTimeMs) .. ")"
    else
        return "(no castingInfo)"
    end
end


-------------------------------------------------
-- API Helpers
-------------------------------------------------

local function LogTextFromSpellID(spellID)
	local spellInfo = spellID and C_Spell.GetSpellInfo(spellID)
    return LogTextFromSpellInfo(spellInfo)
end

local function GetUnitCastingInfo(unit, isChannel)
    local name, displayName, textureID, startTimeMs, endTimeMs
    if isChannel then
        -- name, displayName, textureID, startTimeMs, endTimeMs, isTradeskill,         notInterruptible, spellID, isEmpowered, numEmpowerStages, castBarID = UnitChannelInfo(unit)
        name, displayName, textureID, startTimeMs, endTimeMs = UnitChannelInfo(unit)
    else
        -- name, displayName, textureID, startTimeMs, endTimeMs, isTradeskill, castID, notInterruptible, spellID, castBarID, delayTimeMs = UnitCastingInfo(unit)
        name, displayName, textureID, startTimeMs, endTimeMs = UnitCastingInfo(unit)
    end
    return {
        name        = name        ,    
        displayName = displayName ,
        textureID   = textureID   ,
        startTimeMs = startTimeMs , 
        endTimeMs   = endTimeMs   
    }
end

-------------------------------------------------
-- Impl
-------------------------------------------------

-- isBoss and unit are optional
local function ProcessCast(event, spellID, isBoss, unit, tNow, isChannel)
    if isBoss == nil then isBoss = true end
    if tNow == nil then tNow = GetTime() end

    local volume = isBoss and VOLUME_BOSS or VOLUME_NONBOSS  -- local volume = isBoss ? 100 : 80

    -- spellID is often nil on Stop/Interrupt events
    local spellInfo = spellID and C_Spell.GetSpellInfo(spellID)

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
        
        local castingInfo = GetUnitCastingInfo(unit, isChannel)

        if lastSpeachFinished then
            speachStartedCount = 1
        else
            speachStartedCount = speachStartedCount + 1
        end

        local skip = speachStartedCount > maxMessagesPerSecond
        local sSkip = " "
        if skip then sSkip = "(no voice) " end

        local iVoice = 0
        if useDifferentVoices then
            iVoice = (speachStartedCount - 1) % maxVoiceToUse -- note that speachStartedCount always >= 1
        end

        -- local sCastingInfo = LogTextFromCastingInfo(castingInfo) -- always nil in m+

        --print("|cFFFF0000[BossEvents]|r" .. ToStringEx(unit) .. ": " .. LogTextFromSpellInfo(spellInfo) .. " Queue:" .. tostring(speachStartedCount) .. sSkip .. " " .. tostring(iVoice))
        print("|cFFFF0000[BossEvents]|r" .. ToStringEx(unit) .. ":" .. LogTextFromSpellInfo(spellInfo) .. sSkip .. "t:" .. tNow)
        
        if not skip then
            -- C_VoiceChat.SpeakText(voiceID, text, rate, volume [, overlap]))
            -- works well with secret in spellInfo.name
            C_VoiceChat.SpeakText(iVoice, spellInfo.name, 3, volume, true)

            if lastSpeachFinished then
                speachStartedTime = tNow
            end
        else 
            print("|cFFFF0000[BossEvents]|r Skipped TTS - too busy " .. tostring(skip))
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


-------------------------------------------------------------------------------
-- Deduplication
--
-- When multiple unit tokens fire for the same cast (e.g. "boss1" and
-- "nameplate3" both emit UNIT_SPELLCAST_START for the same ability), the
-- events arrive within DEDUP_WINDOW seconds of each other.
--
-- castGUID and spellID are SECRET values. We must not use them as table keys
-- or in any comparison. Deduplication is based on arrival time only.
--
-- Strategy:
--   • Boss events (unit matches "^boss") fire immediately and mark a
--     dedup slot as "boss handled" so any non-boss duplicate is dropped.
--   • Non-boss events are held for DEDUP_WINDOW seconds. If a boss event
--     fires during that window (or already fired just before), the non-boss
--     event is dropped. Otherwise the oldest non-boss event is processed.
--
-- pendingSlots is a list (array) of entries. We match a new arrival to an
-- existing slot purely by checking whether it arrived within DEDUP_WINDOW
-- of that slot's first arrival time.
--
-- pendingSlots[i] = {
--   arrivedAt  = GetTime() of the first event in this slot,
--   bossWon    = true if a boss event already fired for this slot,
--   isFriendly = true if event in this slot came from Player or Party unit
--   event      = event string of the oldest non-boss arrival (may be nil),
--   spellID    = spellID of that non-boss event (secret – stored, not compared),
--   unit       = unit token of that non-boss event,
-- }
-------------------------------------------------------------------------------
local pendingSlots = {}

-- Find an existing pending slot whose window overlaps the current time.
-- Returns the slot table, or nil if none found.
local function FindPendingSlot(tNow)
    for i = #pendingSlots, 1, -1 do
        local slot = pendingSlots[i]
        if (tNow - slot.arrivedAt) < DEDUP_WINDOW then
            return slot
        end
        -- Slots are appended chronologically; once one is too old, all before
        -- it are also too old, so we can stop early.
        break
    end
    return nil
end

-- Called after DEDUP_WINDOW seconds for a captured slot reference.
local function OnPendingSlotTimer(slot)
    if slot.bossWon then
        -- Boss already handled this cast; discard the non-boss duplicate.
        if LOG_DETAILS then
            if slot.unit then -- always true
                print("|cFFFF0000[BossEvents]|r Boss won! this=" .. ToStringEx(slot.unit) .. " " .. LogTextFromSpellID(slot.spellID) .. " t:" .. slot.arrivedAt)
            end
        end
        return
    end

    if slot.event and not slot.isFriendly then
        -- No boss event arrived – process the oldest non-boss event.
        ProcessCast(slot.event, slot.spellID, false, slot.unit, slot.arrivedAt, slot.isChannel)
    end
end


-- Main routing called from OnEvent for UNIT_SPELLCAST_START / CHANNEL_START.
local function HandleSpellCastEvent(event, unit, castGUID, spellID, isChannel)
    if not EntropyBossEvents then return end -- settings not loaded yet
    if not EntropyBossEvents.bossEventsEnabled then return end

    if unit == "target" or unit == "targettarget" or unit == "focus" then return end -- really don't care about these

    local tNow = GetTime()
    local isBoss = unit:match("^boss") ~= nil

    if isBoss then
        -- ------------------ Boss path: fire immediately ------------------
        ProcessCast(event, spellID, true, unit, tNow, isChannel)
        if EntropyBossEvents.bossOnly then return end

        -- Mark any open dedup slot as boss-handled so its pending non-boss
        -- event (if any) will be dropped when the timer fires.
        local slot = FindPendingSlot(tNow)
        if slot then
            slot.bossWon = true
            slot.nCasts  = slot.nCasts + 1
        else
            -- No non-boss event arrived yet; open a slot so that if one arrives
            -- within the window it will see bossWon = true and be dropped.
            local newSlot = {
                arrivedAt  = tNow,
                bossWon    = true,
		        isFriendly = false,
                event      = event,
                spellID    = spellID,
                castGUID   = castGUID,
                unit       = unit,
                isChannel  = isChannel,
                nCasts     = 1,
            }
            table.insert(pendingSlots, newSlot)
        end
    elseif EntropyBossEvents.bossOnly then
        return
    else
        -- ------------------ Non-boss path: delay, deduplicate ------------------
        local slot = FindPendingSlot(tNow)
        if slot then
            slot.nCasts  = slot.nCasts + 1

            if LOG_DETAILS then
                local msg;
                if slot.bossWon then
                    -- Boss already fired; drop this non-boss event immediately.
                    msg = "|cFFFFFF00[BossEvents]|r Boss already fired"
                elseif slot.isFriendly then
                    -- Another non-boss event is already pending for this window and it was from friently unit.
                    msg = "|cFFFFFF00[BossEvents]|r Duplicate Friently spell"
                else
                    -- Another non-boss event is already pending for this window.
                    -- Keep the oldest (already stored in slot); drop this one.
                    msg = "|cFFFFFF00[BossEvents]|r Duplicate from non-boss"
                end
            
                print(msg .. ", " .. ToStringEx(unit) .. ", t:" .. tNow, ", ", LogTextFromSpellID(spellID))
            end

            return
        end

        -- player / party units are friendly – we never TTS their casts.
        -- We mark the slot, so the timer won't call ProcessCast.
        local isFriendly = unit == "player"
            or unit:match("^party") ~= nil
            or unit == "softfriend"

        -- First event in a new dedup window: open a slot and schedule processing.
        local newSlot = {
            arrivedAt  = tNow,
            bossWon    = false,
            isFriendly = isFriendly,
            event      = event,
            spellID    = spellID, -- secret value: stored for later ProcessCast call, never compared
            castGUID   = castGUID,
            unit       = unit,
            isChannel  = isChannel,
            nCasts     = 1,
        }
        table.insert(pendingSlots, newSlot)
        C_Timer.After(DEDUP_WINDOW, function()
            OnPendingSlotTimer(newSlot)
        end)
    end
end

-----------------------------------

local function OnCombatEnd()
    isInCombat = false
    wipe(pendingSlots)
end

local function OnCombatStart()
	isInCombat = true 
end

-----------------------------------
-- SLASH COMMANDS

-- /BossEvents on|off|?|
--    Shows/hides the texts
SLASH_BOSSEVENTS1 = "/BossEvents"
SlashCmdList["BOSSEVENTS"] = function(msg)
    msg = msg:lower()
    if msg == "on" or not msg or msg == "" then
        EntropyBossEvents.bossEventsEnabled = true
        EntropyBossEvents.bossOnly = false
        print("|cFFFF0000[BossEvents]|r |cFF00FF00BossEvents on|r")
    elseif msg == "off" then
        EntropyBossEvents.bossEventsEnabled = false
        print("|cFFFF0000[BossEvents]|r |cFFFF0000BossEvents off|r")
    elseif msg == "bossonly" then
        EntropyBossEvents.bossEventsEnabled = true
        EntropyBossEvents.bossOnly = true
        print("|cFFFF0000[BossEvents]|r |cFF00FF00BossEvents on|r")
    elseif msg == "test" then
        test()
    elseif msg:match("^testvoice ") then
        local sVoice = string.sub(msg, 10, -1)
        local iVoice = tonumber(sVoice)
        local volume = 100
        C_VoiceChat.SpeakText(iVoice, "Voice " .. sVoice, 3, volume, true)
    else
        print("|cFFFF0000[BossEvents]|r Usage: /BossEvents [on | off | bossOnly | test | testvoice n]")
        print("|cFFFF0000[BossEvents]|r on - TTS Boss and Other spells, bossOnly - TTS only Boss spells")
    end
    PrintConfig()
end

-----------------------------------
-- Frame and events

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
--frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED") -- When a channeled spell is interrupted, UNIT_SPELLCAST_INTERRUPTED usually fires first, followed by UNIT_SPELLCAST_CHANNEL_STOP
--frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP") -- fires every time a cast ends (even if it was successful). If you only care about the cast being cut short, use UNIT_SPELLCAST_INTERRUPTED.

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- combat end
frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- combat starts

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
            PrintConfig()
        -- else
        --     print("|cFFFF0000[BossEvents]|r Addon: " .. addonName)
        end
        
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        if not isInPartyInstance and not isInRaidInstance and not isInScenarioInstance then
            return
        end
        
        local unit, castGUID, spellID = ...
        local isChannel = event == "UNIT_SPELLCAST_START"
        
        --local spellInfo = spellID and C_Spell.GetSpellInfo(spellID)
        --if spellInfo then
        --    print("|cFFFF00FF[BossEvents]|r " .. unit .." ".. ToStringEx(spellInfo.name) .. ": " .. ToStringEx(castGUID))
        --end

        HandleSpellCastEvent(event, unit, castGUID, spellID, isChannel)

    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...

        -- GetInstanceInfo returns data about the current location https://wowpedia.fandom.com/wiki/API_GetInstanceInfo
        local name, instanceType, difficultyID, difficultyName = GetInstanceInfo() 
        -- instanceType: string - "none" if the player is not in an instance, "scenario" for scenarios, "party" for dungeons, "raid" for raids, "arena" for arenas, and "pvp" for battlegrounds. Many of the following return values will be nil or otherwise useless in the case of "none".

        isInPartyInstance = instanceType == "party"
        isInRaidInstance = instanceType == "raid"
        isInScenarioInstance = instanceType == "scenario"

        print("|cFFFF0000[BossEvents]|rYou have entered a ".. instanceType .." instance: " .. name .. ", " .. difficultyName)
        PrintConfig(" use /BossEvents on|off|bossOnly to change.")        

        if not isInPartyInstance and not isInRaidInstance then
            return
        end

        if not isReloadingUi then
            if (isInPartyInstance and not EntropyBossEvents.bossEventsEnabled) or (isInRaidInstance and EntropyBossEvents.bossEventsEnabled) then
                C_VoiceChat.SpeakText(1, "Boss cast TTS is " .. tostring(EntropyBossEvents.bossEventsEnabled) .. ". Consider changing.", 2, 80, true)
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        OnCombatEnd()
    elseif event == "PLAYER_REGEN_DISABLED" then
        OnCombatStart()
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
