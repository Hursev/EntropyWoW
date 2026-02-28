-- moves the position of Loss-of-Control indicator

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    LossOfControlFrame:ClearAllPoints()
    LossOfControlFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 250) -- Adjust coordinates here
end)