--[[
    Copyright (C) 2026 Entropy
    License: GNU v3. See LICENSE file and <https://www.gnu.org/licenses/>

File Description:
    Displays a ring around the cursor when a tracked spell goes on cooldown.
    The ring starts full and drains clockwise over the cooldown duration,
    then disappears. Tracked spell is determined by the player's class and spec.

    The ring frame is mouse-passthrough so it never interferes with clicks.
]]

-------------------------------------------------
-- CONFIG
-------------------------------------------------

-- Texture used for the ring graphic.
local CFG_TEXTURE = "Interface\\AddOns\\Entropy\\Media\\Ring_30px.tga"

-- Frame strata for the ring.
local CFG_STRATA = "HIGH"

-- Size (width and height) of the ring frame in pixels.
local CFG_SIZE = 20

-- Maps [classFileName][specIndex] = { spellID, duration }
--   classFileName : uppercase WoW internal class name (e.g. "PRIEST", "PALADIN")
--   specIndex     : 1-based spec index as returned by GetSpecialization()
--   spellID       : the spell to watch for
--   duration      : how long (seconds) to display the ring after the cast
local CFG_SPEC_SPELLS = {
    PALADIN = {
        [1] = { spellID = 527, duration = 8 },  -- Holy Paladin - Purify
    },
    PRIEST = {
        -- real:
        [2] = { spellID = 527, duration = 8 },  -- Holy Priest - Purify
        -- test:
        -- [2] = { spellID = 586, duration = 8 },  -- Holy Priest - Fade
    },
}

local DEBUG = true
local TRACE = true


-------------------------------------------------
-- State
-------------------------------------------------
local ringFrame       -- the visible ring frame
local cooldownFrame   -- child Cooldown frame that drives the swipe animation
local updateFrame     -- invisible frame used for OnUpdate cursor tracking
local trackSpellID    -- currently active tracked spell ID (or nil if none)
local trackDuration   -- cooldown display duration for the tracked spell
local isShowing = false

-------------------------------------------------
-- Determine Tracked Spell for Current Class/Spec
-------------------------------------------------
local function UpdateTrackedSpell()
    local _, classFileName = UnitClass("player")
    if not classFileName then return end

    local specIndex = GetSpecialization()
    if not specIndex then return end

    local specTable = CFG_SPEC_SPELLS[classFileName]
    if not specTable then
        trackSpellID = nil
        trackDuration = nil
        if TRACE then print(string.format("|cFF00FF00[Entropy.Cursor]|r nothing tracked for %s", classFileName)) end
        return
    end

    local entry = specTable[specIndex]
    if entry then
        trackSpellID = entry.spellID
        trackDuration = entry.duration
        if TRACE then print(string.format("|cFF00FF00[Entropy.Cursor]|r tracked spell %d for %s/%d", trackSpellID, classFileName, specIndex)) end
    else
        trackSpellID = nil
        trackDuration = nil
        if TRACE then print(string.format("|cFFFFFF00[Entropy.Cursor]|r nothing tracked for %s/%d", classFileName, specIndex)) end
    end
end

-------------------------------------------------
-- Ring Frame Creation
-------------------------------------------------
local function CreateRingFrame()
    -- Outer frame: mouse-passthrough, follows cursor via OnUpdate
    ringFrame = CreateFrame("Frame", "EntropyCursorCooldownRing", UIParent)
    ringFrame:SetFrameStrata(CFG_STRATA)
    ringFrame:SetSize(CFG_SIZE, CFG_SIZE)
    ringFrame:EnableMouse(false)   -- IMPORTANT: never eat mouse events
    ringFrame:SetToplevel(false)
    ringFrame:Hide()

    -- The ring texture sits as a background on the outer frame.
    -- The Cooldown child uses it as a swipe mask.
    local tex = ringFrame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetTexture(CFG_TEXTURE)
    tex:SetVertexColor(0, 0.6, 1, 1)  -- blue tint

    cooldownFrame = CreateFrame("Cooldown", nil, ringFrame)
    cooldownFrame:SetAllPoints()
    cooldownFrame:SetDrawEdge(false)
    cooldownFrame:SetDrawSwipe(true)
    cooldownFrame:SetSwipeTexture(CFG_TEXTURE)
    cooldownFrame:SetSwipeColor(0, 1, 0, 1)  -- opaque black, grows clockwise to hide the ring
    cooldownFrame:SetReverse(true)            -- swipe grows clockwise (erasing the ring)
    cooldownFrame:SetHideCountdownNumbers(true)
    cooldownFrame:EnableMouse(false)
    --[[
    -- Cooldown frame: drives the clockwise-drain swipe animation natively.
    -- We use the ring texture as the swipe texture so the drain follows the ring shape.
    cooldownFrame = CreateFrame("Cooldown", nil, ringFrame)
    cooldownFrame:SetAllPoints()
    cooldownFrame:SetDrawEdge(false)        -- no bright edge flash
    cooldownFrame:SetDrawSwipe(true)        -- enable the swipe (drain) overlay
    cooldownFrame:SetSwipeTexture(CFG_TEXTURE)
    cooldownFrame:SetSwipeColor(0, 0, 0, 1)  -- fully transparent: erases the ring arc
    cooldownFrame:SetReverse(true)           -- true = swipe starts covering all, shrinks clockwise
    cooldownFrame:SetHideCountdownNumbers(true)
    cooldownFrame:EnableMouse(false)
    ]]
    -- OnUpdate: stick the ring to the cursor every frame
    updateFrame = CreateFrame("Frame", nil, UIParent)
    updateFrame:Hide()
    updateFrame:SetScript("OnUpdate", function()
        if not isShowing then return end
        local cx, cy = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        ringFrame:ClearAllPoints()
        ringFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx / s, cy / s)
    end)
end

-------------------------------------------------
-- Show / Hide Ring
-------------------------------------------------
local function ShowRing(duration)
    if not ringFrame then return end

    isShowing = true
    ringFrame:Show()
    updateFrame:Show()

    -- SetCooldown(startTime, duration) — this drives the swipe animation.
    -- Using GetTime() as start makes it begin right now.
    cooldownFrame:SetCooldown(GetTime(), duration)

    -- Hide the ring automatically when the cooldown expires.
    C_Timer.After(duration, function()
        isShowing = false
        ringFrame:Hide()
        updateFrame:Hide()
    end)
end

-------------------------------------------------
-- Event Handling
-------------------------------------------------
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        UpdateTrackedSpell()
        CreateRingFrame()

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if unit == "player" then
            UpdateTrackedSpell()
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- arg1=unitTarget, arg2=castGUID, arg3=spellID
        local unit, _, spellID = ...
        if unit ~= "player" then return end
        if not trackSpellID then return end
        if spellID ~= trackSpellID then return end

        ShowRing(trackDuration)
    end
end)