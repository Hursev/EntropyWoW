-- ============================================================
-- GliderSpeed.lua
-- A World of Warcraft addon for WoW Midnight (11.x+)
--
-- Monitors your character's movement speed while Skyriding
-- and displays two values side-by-side on screen:
--
--   1. Current flight speed – always shown as % of base run speed
--
--   2. Speed change (delta)  – shown only when current speed
--      GREEN  = accelerating
--      RED    = decelerating
--
-- Configuration:
--   Edit the variables in the CONFIG block below to set the
--   default on-screen position and the speed threshold.
--
-- Slash command:
--   /gliderspeed x y   – move the display to screen coords (x, y)
--   /gliderspeed       – print current position
-- ============================================================

-- ============================================================
-- CONFIG  –  edit these to suit your UI
-- ============================================================
local DISPLAY_X             = 1024     -- pixels from screen left
local DISPLAY_Y             = -950     -- pixels from screen top (negative = downward)
local SPEED_DELTA_THRESHOLD = 789      -- delta label only shown when speed < this value
local UPDATE_INTERVAL       = 0.1      -- refresh rate in seconds (0.1 = 10 times/sec)
-- ============================================================

-- -- Skyriding state table (populated each tick) ---------------
local AdvFlying = {
    Enabled      = false,
    IsFlying     = false,
    ForwardSpeed = 0.0,
    IsRacing     = false,
}
local GetGlidingInfo = C_PlayerInfo.GetGlidingInfo

local function RefreshGlidingInfo()
    local isGliding, canGlide, forwardSpeed = GetGlidingInfo()
    AdvFlying.Enabled      = canGlide    or false
    AdvFlying.IsFlying     = isGliding   or false
    AdvFlying.ForwardSpeed = forwardSpeed or 0.0
end

--- Returns true when the Skyriding action bar is active.
--- Bonus bar index 11 + offset 5 is set exclusively by the
--- Skyriding / Dragonriding locomotion system.
local function IsSkyriding()
    local hasSkyridingBar = (GetBonusBarIndex() == 11 and GetBonusBarOffset() == 5)
    return hasSkyridingBar 
    -- if hasSkyridingBar then
    --    return true
    -- end
end

-- -- Frame & font strings --------------------------------------
local display = CreateFrame("Frame", "GliderSpeedFrame", UIParent)
display:SetSize(280, 28)
display:SetPoint("TOPLEFT", UIParent, "TOPLEFT", DISPLAY_X, DISPLAY_Y)
display:EnableMouse(false)   -- never block player clicks

-- Speed value – white
local speedText = display:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
speedText:SetPoint("LEFT", display, "LEFT", 0, 0)
speedText:SetTextColor(1, 1, 1, 1)

-- Delta value – coloured per-frame
local deltaText = display:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
-- deltaText:SetPoint("LEFT", speedText, "RIGHT", 14, 0)
deltaText:SetPoint("LEFT", display, "LEFT", 50, 0)

display:Hide()

-- -- Helpers ---------------------------------------------------
local function ApplyPosition(x, y)
    display:ClearAllPoints()
    display:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
end

-- -- Main update loop ------------------------------------------
local lastSpeed  = 0
local lastUpdate = 0

local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = 0

    -- Only active when the Skyriding bar is shown
    if not IsSkyriding() then
        display:Hide()
        lastSpeed = 0
        return
    end

    RefreshGlidingInfo()

    -- Hide when not actually gliding/flying
    if not AdvFlying.IsFlying then
        display:Hide()
        lastSpeed = 0
        return
    end

    display:Show()

    local currentSpeed = AdvFlying.ForwardSpeed
    local delta        = currentSpeed - lastSpeed

    -- 1. Speed label (always visible while skyriding)
    speedText:SetText(string.format("%.1f", currentSpeed))

    -- 2. Delta label (only when below threshold)
    if currentSpeed < SPEED_DELTA_THRESHOLD then
        local sign = delta >= 0 and "+" or ""
        local r, g, b
        if delta >= 0 then
            r, g, b = 0, 1, 0   -- green: gaining speed
        else
            r, g, b = 1, 0, 0   -- red: losing speed
        end
        deltaText:SetText(string.format("%s%.1f", sign, delta))
        deltaText:SetTextColor(r, g, b, 1)
        deltaText:Show()
    else
        deltaText:Hide()
    end

    lastSpeed = currentSpeed
end)

-- -- Slash command ---------------------------------------------
SLASH_GLIDERSPEED1 = "/gliderspeed"
SlashCmdList["GLIDERSPEED"] = function(msg)
    local x, y = msg:match("^%s*(%-?%d+)%s+(%-?%d+)%s*$")
    if x and y then
        DISPLAY_X = tonumber(x)
        DISPLAY_Y = tonumber(y)
        ApplyPosition(DISPLAY_X, DISPLAY_Y)
        print(string.format("|cff00ff00[GliderSpeed]|r Position set to (%d, %d)", DISPLAY_X, DISPLAY_Y))
    else
        print(string.format("|cff00ff00[GliderSpeed]|r Current position: (%d, %d)", DISPLAY_X, DISPLAY_Y))
        print("|cff00ff00[GliderSpeed]|r Usage: /gliderspeed x y")
    end
end

-- -- Login message ---------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    print(string.format(
        "|cff00ff00[GliderSpeed]|r loaded. Delta shown below %.0f. Position: (%d, %d). Type /gliderspeed for help.",
        SPEED_DELTA_THRESHOLD, DISPLAY_X, DISPLAY_Y
    ))
end)