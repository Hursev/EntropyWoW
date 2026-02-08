--[[
    Copyright (C) 2026 Entropy
    License: GNU v3. See LICENSE file and <https://www.gnu.org/licenses/>
    
File Description:
    Displays static texts on top of with high Strata, on specific positions on the screen.
    
    The texts are specific for player's class and current specialization.
    You need to edit the content of 'local OVERLAY_CONFIG' to define what and where texts 
        should be displayed.
    
    Supports console commands:
      /staticShow show|hide
         Shows/hides the texts
      /staticmove <index of the text> <X> <Y>
         Moves the text with that index for the current specialization to new position
      /staticText <index of the text> <text>
         Changes the text for that index for the current specialization
]]

-- CONFIGURATION
local STRATA = "HIGH"
local FONT_PATH = [[Fonts\FRIZQT__.TTF]]
local FONT_SIZE = 13

local LastClassSpec = ""

-- Format: [CLASS_ENGLISH] = { [SpecIndex] = { {text = "Text", x = 0, y = 0}, ... } }
local OVERLAY_CONFIG = {
    ["PRIEST"] = {
    --[[
        [2] = { -- Holy
            {text = "c-F             T      A                       s-G              5", x = -453, y = 52},
            {text = "sX", x = -365, y = 12},
            {text = "sT      sR    sF2", x = -280, y = 12},
        },
        [3] = { -- Shadow
            {text = "R", x = 109, y = -79},
        },
    ]]
    },
    -- Add other classes/specs here
}

-- INTERNAL STATE
local framePool = {}
local isHiddenManually = false

-- FUNCTION: Create or fetch a frame from the pool
local function GetFrameFromPool(index)
    if not framePool[index] then
        local f = CreateFrame("Frame", "StaticTextOverlayFrame" .. index, UIParent) --CreateFrame("Frame", nil, UIParent)
        f:SetFrameStrata(STRATA)

        f:SetSize(1, 1) -- todo: fix me
        
        --Font
        local myText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        -- Get the current font path so you don't have to hardcode a .ttf file
        local fontPath, _, fontFlags = myText:GetFont()
        -- Set the size to 24 (or whatever number you prefer)
        myText:SetFont(fontPath, FONT_SIZE, "OUTLINE") -- , fontFlags
        myText:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        myText:SetTextColor(1, 1, 1, 1) -- r,g,b,a

        f.Text = myText
        framePool[index] = f
    end
    return framePool[index]
end

-- FUNCTION: Update and Position Frames
local function UpdateOverlay()
    -- Hide all existing frames first
    for _, f in ipairs(framePool) do f:Hide() end
    
    if isHiddenManually then return end

    local _, class = UnitClass("player")
    local specIndex = GetSpecialization()

    local newSpec = LastClassSpec == (class .. specIndex)
    
    if not specIndex or not OVERLAY_CONFIG[class] or not OVERLAY_CONFIG[class][specIndex] then
        print(string.format("|cFFFF0000[StaticText]|r Static Texts: no config for %s spec %d", class, specIndex))
        return
    end

    local specData = OVERLAY_CONFIG[class][specIndex]
    for i, data in ipairs(specData) do
        local f = GetFrameFromPool(i)
        f:SetPoint("CENTER", UIParent, "CENTER", data.x, data.y)
        f.Text:SetText(data.text)
        f:Show()
        --print(string.format("|cFFFF0000[StaticText]|r Show {text = \"%s\", x = %d, y = %d},", data.text, data.x, data.y))
    end
end

-- SLASH COMMANDS

-- /staticshow show|hide
--    Shows/hides the texts
SLASH_STATICSHOW1 = "/staticshow"
SlashCmdList["STATICSHOW"] = function(msg)
    if msg == "show" or not msg or msg == "" then
        isHiddenManually = false
        UpdateOverlay()
        print("|cFFFF0000[StaticText]|r |cFF00FF00StaticShow Shown|r")
    elseif msg == "hide" then
        isHiddenManually = true
        UpdateOverlay()
        print("|cFFFF0000[StaticText]|r |cFFFF0000StaticShow Hidden|r")
    else
        print("|cFFFF0000[StaticText]|r Usage: /staticShow [show | hide]")
    end
end

-- SLASH COMMAND: /staticmove <index> <x> <y>
--      Moves the text with that index for the current specialization to new position
SLASH_STATICMOVE1 = "/staticmove"
SlashCmdList["STATICMOVE"] = function(msg)
    local index, x, y = msg:match("^(%d+)%s+([%-?%d+.]+)%s+([%-?%d+.]+)$")
    index, x, y = tonumber(index), tonumber(x), tonumber(y)

    if not index or not x or not y then
        print("|cFFFF0000[StaticText]|r Usage: /staticmove <index> <x> <y> (e.g., /staticmove 1 -150 100)")
        return
    end

    local _, class = UnitClass("player")
    local specIndex = GetSpecialization()

    local classTable = OVERLAY_CONFIG[class]
    local specTable = classTable and classTable[specIndex]
    local entry = specTable and specTable[index]

    if entry then
        -- Update the live table
        entry.x = x
        entry.y = y
        UpdateOverlay()
        
        -- Print the new config line for easy copy-pasting
        print(string.format("|cFFFF0000[StaticText]|r Moved index %d. New config line:", index))
        print(string.format("|cFFFF0000[StaticText]|r {text = \"%s\", x = %d, y = %d},", entry.text, entry.x, entry.y))
    else
        print("|cFFFF0000[StaticText]|r Invalid index for current class/spec.")
    end
end

-- SLASH COMMAND: /statictext <index> <text>
--      Changes the text for that index for the current specialization.
SLASH_STATICTEXT1 = "/statictext"
SlashCmdList["STATICTEXT"] = function(msg)
    local index, text = msg:match("^(%d+)%s+(.*)$")
    index = tonumber(index)

    if not index or not text then
        print("|cFFFF0000[StaticText]|r Usage: /statictext <index> <text> (e.g., /statictext 1 hello kitty)")
        return
    end

    local _, class = UnitClass("player")
    local specIndex = GetSpecialization()

    local classTable = OVERLAY_CONFIG[class]
    local specTable = classTable and classTable[specIndex]
    local entry = specTable and specTable[index]

    if entry then
        -- Update the live table
        entry.text = text
        UpdateOverlay()
        
        -- Print the new config line for easy copy-pasting
        print(string.format("|cFFFF0000[StaticText]|r Moved index %d. New config line:", index))
        print(string.format("|cFFFF0000[StaticText]|r {text = \"%s\", x = %d, y = %d},", entry.text, entry.x, entry.y))
    else
        print("|cFFFF0000[StaticText]|r Invalid index for current class/spec.")
    end
end

-- EVENT HANDLER
local eventHandler = CreateFrame("Frame")
eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
eventHandler:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

eventHandler:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end
    UpdateOverlay()
end)
