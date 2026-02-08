--[[
    Copyright (C) 2026 Entropy
    License: GNU v3. See LICENSE file and <https://www.gnu.org/licenses/>
    
File Description:
    This is a small extension for the Unhalted Unit Frames.
    If you enable 'Tag 4' and 'Tag 5' for the Target Unit Frame and set their 
        text to '.' then the code in this file will replace them 
        Guild name and Guild Rank text.
]]

local function UpdateGuildTag()
    -- Final safety check: ensure the target still exists and is a player
    if not UnitExists("target") or not UnitIsPlayer("target") then
        return
    end

    -- Check if the specific UI element exists
    if UUF_Target_TagFour then
        local currentText = UUF_Target_TagFour:GetText()

        local guildName, guildRankName = "", ""

        if currentText == "." then
            guildName, guildRankName = GetGuildInfo("target")
            if not guildName then
                guildName, guildRankName = "", ""
            end
        end

        -- Set text to: Guild Name (Rank)
        UUF_Target_TagFour:SetText(guildName)
        UUF_Target_TagFive:SetText(guildRankName)
    end
end

local guildFixer = CreateFrame("Frame")
guildFixer:RegisterEvent("PLAYER_TARGET_CHANGED")

guildFixer:SetScript("OnEvent", function(self, event)
    -- Exit if player is in combat
    if UnitAffectingCombat("player") then 
        return 
    end

    -- Pass the named function as the callback
    C_Timer.After(0.2, UpdateGuildTag)
end)

