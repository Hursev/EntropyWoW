-- prints boss casts during fights
-- TTS boss casts during fights

local bossEventsOn = true

-- SLASH COMMANDS

-- /printevents on|off|?|
--    Shows/hides the texts
SLASH_BOSSEVENTS1 = "/bossevents"
SlashCmdList["PRINTEVENTS"] = function(msg)
    if msg == "on" or not msg or msg == "" then
        bossEventsOn = true
        print("|cFFFF0000[BossEvents]|r |cFF00FF00BossEvents on|r")
    elseif msg == "hide" then
        bossEventsOn = false
        print("|cFFFF0000[BossEvents]|r |cFFFF0000BossEvents off|r")
    else
        print("|cFFFF0000[BossEvents]|r Usage: /BossEvents [on | off]")
    end
    print("|cFFFF0000[BossEvents]|r Enabled: " .. tostring(bossEventsOn))
end

local function ToStringEx(x)
    return tostring(x) .. (issecretvalue(x) and "(S)" or "")
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
--frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED") -- When a channeled spell is interrupted, UNIT_SPELLCAST_INTERRUPTED usually fires first, followed by UNIT_SPELLCAST_CHANNEL_STOP
--frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP") -- fires every time a cast ends (even if it was successful). If you only care about the cast being cut short, use UNIT_SPELLCAST_INTERRUPTED.

frame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    if not bossEventsOn then return end
    if not unit:match("^boss") then return end

    -- spellID is often nil on Stop/Interrupt events
    local spellInfo = spellID and C_Spell.GetSpellInfo(spellID)

    if event == "UNIT_SPELLCAST_INTERRUPTED" then
        if spellInfo then
            print("|cFFFF0000[PrintEvents]|r " .. "Interrupted: " .. ToStringEx(spellInfo.name))
        else
            -- for single boss fights we can assume it is the last spell that they started casting
            print("|cFFFF0000[PrintEvents]|r " .. "Interrupted: a spell")
        end        
    else
        if not spellInfo then return end -- no meaningful actions if we don't have the spell id

        print("|cFFFF0000[PrintEvents]|r Boss: " .. ToStringEx(unit) .. ": " .. ToStringEx(spellInfo.name) .. " (id: " .. ToStringEx(spellID) .."), " .. ToStringEx(spellInfo.castTime) .. "ms")
        
        -- C_VoiceChat.SpeakText(voiceID, text, rate, volume [, overlap]))
        -- works well with secret in spellInfo.name
        C_VoiceChat.SpeakText(0, spellInfo.name, 3, 100, true)
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
        print("|cFFFF0000[PrintEvents]|r B: " .. ToStringEx(unit) .. ": " .. ToStringEx(spellName) .. " (id: " .. ToStringEx(spellID) .."), " .. ToStringEx(castTime) .. "ms")

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
        print("|c33AA0000[PrintEvents]|r N: " .. ToStringEx(unit) .. ": " .. ToStringEx(spellName) .. " (id: " .. ToStringEx(spellID) .."), " .. ToStringEx(castTime) .. "ms")
        --C_VoiceChat.SpeakText(0, spellName, 3, 50, true) <- works OK
    end
end)
]]
