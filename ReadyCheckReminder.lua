--[[
    Copyright (C) 2026 Entropy
    License: GNU v3. See LICENSE file and <https://www.gnu.org/licenses/>

File Description:
    On ReadyCheck sends chat whisper and/or voice alert to yourself, like "Did you start Recording?"
]]

-------------------------------------------------
-- CONFIG
-------------------------------------------------

local CFG = {

    Enabled = false,    -- Enable/Disable the entire functionality

    SendWhisper = true, -- Send the whisper to yourself
    WhisperText = "Did you start Recording?", -- Whisper Text

    Speak = true,       -- Enable Spoken warning
    SpeakText = "Did you start Recording?", -- The text you want the game to say.
    SpeakSpeed = 3,     -- The speed of the speech. 0 is normal speed. Range is usually -10 to 10.
    SpeakVolume = 50,   -- How loud it is. 100 is max volume.
}

-------------------------------------------------
-- Code
-------------------------------------------------

local thisCharacter -- player's full name. Lazy init.

local reminderHandler = CreateFrame("Frame")
reminderHandler:RegisterEvent("READY_CHECK")

reminderHandler:SetScript("OnEvent", function(self, event)
    if CFG.Enabled == true and event == "READY_CHECK" then
        -- Send the whisper to yourself
        if CFG.SendWhisper then
            -- "true" includes the server name, making it foolproof for whispers
            thisCharacter = thisCharacter or GetUnitName("player", true)
            SendChatMessage(CFG.WhisperText, "WHISPER", nil, thisCharacter)
        end

        if CFG.Speak then
            -- Usage: C_VoiceChat.SpeakText(voiceID, text, rate, volume [, overlap]))
            --  Voice ID (0): Usually set to 0 to use the system default voice.
            --  Text: The string you want the game to say.
            --  Rate: The speed of the speech. 0 is normal speed. Range is usually -10 to 10.
            --  Volume: How loud it is. 100 is max volume.
            C_VoiceChat.SpeakText(0, CFG.SpeakText, CFG.SpeakSpeed, CFG.SpeakVolume, true)
        end
    end
end)