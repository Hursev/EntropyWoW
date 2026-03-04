-- moves the position of Loss-of-Control indicator
--
-- ALTERNATIVE: Leatrix Plus addon/Options/Frames/Manage Control

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    LossOfControlFrame:ClearAllPoints()
    LossOfControlFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 250) -- Adjust coordinates here
end)