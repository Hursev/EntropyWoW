-- moves the position of Loss-of-Control indicator
--
-- ALTERNATIVE: Leatrix Plus addon/Options/Frames/Manage Control

local NAME_FOR_PRINT = "LossOfControlMover"
local X_OFFSET = 0
local Y_OFFSET = 250

local function SetLOCPosition()
    LossOfControlFrame:ClearAllPoints()
    LossOfControlFrame:SetPoint("CENTER", UIParent, "CENTER", X_OFFSET, Y_OFFSET)
end

local function PrintLOCPosition()
    local point, relativeTo, relativePoint, xOfs, yOfs = LossOfControlFrame:GetPoint(1)
    local frameName = relativeTo and relativeTo:GetName() or "Unknown"
    print(string.format("[%s] LossOfControlFrame anchor: %s, relative to: %s (%s), offset: (%.1f, %.1f)",
        NAME_FOR_PRINT, point, frameName, relativePoint, xOfs, yOfs))
end

-- Slash commands

-- Re-applies the ClearAllPoints + SetPoint call, useful if another addon or UI event moves the frame after load.
SLASH_SETLOC1 = "/SetLOC"
SlashCmdList["SETLOC"] = function()
    SetLOCPosition()
    print("[" .. NAME_FOR_PRINT .. "] LossOfControlFrame position reset.")
end

-- Reads the frame's actual current anchor and prints the point, relative frame name, relative point, and x/y offsets to chat.
SLASH_PRINTLOC1 = "/PrintLOC"
SlashCmdList["PRINTLOC"] = function()
    PrintLOCPosition()
end

-- Event registration
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    SetLOCPosition()
end)
