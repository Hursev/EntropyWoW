--[[
    Copyright (C) 2026 Entropy
    License: GNU v3. See LICENSE file and <https://www.gnu.org/licenses/>

File Description:
    Displays "<Combat End>" when the character exits combat
]]
 
 -- Create the display frame
local displayFrame = CreateFrame("Frame", nil, UIParent)
displayFrame:SetSize(200, 50)
displayFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)

-- Create the text
local text = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
text:SetPoint("CENTER")
text:SetText("<Combat End>")
displayFrame:Hide()

-- Event logic
local eventHandler = CreateFrame("Frame")
eventHandler:RegisterEvent("PLAYER_REGEN_ENABLED")

eventHandler:SetScript("OnEvent", function()
    displayFrame:Show()
    
    -- Simple timer: Hide the frame after 2 seconds
    C_Timer.After(2, function()
        displayFrame:Hide()
    end)
end)
