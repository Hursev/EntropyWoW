-- CursorLocator.lua
--
-- PURPOSE:
--   Helps players quickly find their mouse cursor during hectic combat by
--   drawing an animated "bullseye" effect: a series of concentric rings that
--   start large and rapidly shrink down to the exact cursor position.
--
-- USAGE:
--   Make a macro with one of the commande below and assign it to the keybind you like:
--   /findcursor                — trigger the animation (recommended)
--   /run CursorLocator:Show()  — trigger the animation
--
-- CONFIGURATION:
--   Edit the CONFIG table below to change colours, size, speed and ring count.
--
-- TEXTURE:
--   Uses  Interface\AddOns\Entropy\Media\Ring_30px.tga
--   (a pre-made ring / circle texture; alpha channel defines the ring shape)
--
-- NOTES:
--   • All frames are created with mouse-passthrough (EnableMouse(false)) so
--     the animation never interferes with clicks, targeting or UI interaction.
--   • Animation is driven by C_Timer.NewTicker so it is frame-rate independent
--     and safe to call inside combat lockdown.
--   • Each ring is an independent frame that scales from CONFIG.startScale down
--     to 1 over CONFIG.duration seconds, then fades out and hides itself.

-- ─────────────────────────────────────────────────────────────────────────────
-- CONFIGURATION  ←  edit these values to taste
-- ─────────────────────────────────────────────────────────────────────────────
local CONFIG = {
    -- Base size of the ring texture in pixels (the texture is square).
    -- Each ring is rendered at this logical size; scaling is applied on top.
    baseSize        = 30,

    -- Maximum scale applied to the ring at the START of the animation.
    -- Think of this as the starting width in pixels for the outermost ring.
    startScale      = 400,

    -- Total duration of one full shrink animation per ring (seconds).
    duration        = 0.30,

    -- Number of concentric rings to draw simultaneously.
    ringCount       = 2,

    -- Delay between each successive ring launch (seconds).
    -- Set to 0 to have them all start at the same moment.
    ringStagger     = 0.04,

    -- Colour of the rings  (RGBA, each component 0–1).
    color           = { r = 1.0, g = 0.85, b = 0.0, a = 0.5 }, -- yellow and transparent

    -- Texture path for the ring.
    texture         = "Interface\\AddOns\\Entropy\\Media\\Ring_30px.tga",

    -- Tick interval for the animation update loop (seconds).
    -- Smaller = smoother but slightly more CPU; 0.016 ≈ 60 fps.
    tickInterval    = 0.016,
}
-- ─────────────────────────────────────────────────────────────────────────────

CursorLocator = {}
local CL = CursorLocator

-- Pool of ring frames (created once, reused on every activation).
local ringPool   = {}
-- Active animation state table for each ring.
local ringState  = {}
-- Master ticker reference (so we can cancel it).
local ticker     = nil
-- How many rings are still animating (used to stop the ticker early).
local activeCount = 0

local uiScale = UIParent:GetEffectiveScale()

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────────────────────────────────────

--- Create (or reuse) a single ring frame at the given index.
local function GetRingFrame(idx)
    if ringPool[idx] then return ringPool[idx] end

    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("TOOLTIP")          -- always on top
    f:SetFrameLevel(500 + idx)
    f:SetSize(CONFIG.baseSize, CONFIG.baseSize)
    f:EnableMouse(false)                 -- NEVER block mouse input
    f:SetClampedToScreen(false)
    f:Hide()

    local tex = f:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(f)
    tex:SetTexture(CONFIG.texture)
    tex:SetVertexColor(CONFIG.color.r, CONFIG.color.g, CONFIG.color.b, CONFIG.color.a)
    tex:SetBlendMode("ADD")              -- additive blend looks great on dark backgrounds
    f._tex = tex

    ringPool[idx] = f
    return f
end

--- Stop the master ticker if it is running.
local function StopTicker()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

--- Read the current cursor position in UI coordinates (scale-adjusted).
local function GetCursorUI()
    local cx, cy = GetCursorPosition()
    return cx / uiScale, cy / uiScale
end

--- Per-tick update: advance every active ring's animation.
local function OnTick(elapsed)
    -- elapsed is NOT passed by NewTicker; we track our own time.
    -- Instead we advance by tickInterval each call.
    local dt = CONFIG.tickInterval
    local stillAlive = 0

    -- Sample the live cursor position once per tick so all rings converge
    -- on the same point (wherever the cursor actually is right now).
    local cx, cy = GetCursorUI()

    for i = 1, CONFIG.ringCount do
        local s = ringState[i]
        if s and s.active then
            s.delay = s.delay - dt
            if s.delay > 0 then
                stillAlive = stillAlive + 1
            else
                s.t = s.t + dt
                local progress = s.t / CONFIG.duration   -- 0 → 1

                if progress >= 1 then
                    -- Animation finished for this ring.
                    ringPool[i]:Hide()
                    s.active = false
                else
                    local f = ringPool[i]
                    -- Scale: starts at CONFIG.startScale, shrinks to baseSize.
                    local currentSize = CONFIG.startScale + (CONFIG.baseSize - CONFIG.startScale) * progress
                    f:SetSize(currentSize, currentSize)

                    -- Alpha: full for most of the animation, then fade out in last 20%.
                    local alpha
                    if progress < 0.8 then
                        alpha = CONFIG.color.a
                    else
                        alpha = CONFIG.color.a * (1 - (progress - 0.8) / 0.2)
                    end
                    f._tex:SetVertexColor(CONFIG.color.r, CONFIG.color.g, CONFIG.color.b, alpha)

                    -- Track the LIVE cursor position every tick.
                    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)

                    stillAlive = stillAlive + 1
                end
            end
        end
    end

    -- If nothing is animating any more, cancel the ticker to save CPU.
    if stillAlive == 0 then
        StopTicker()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

--- Trigger the cursor-locator animation.
--- Safe to call in combat (no protected frame manipulation).
function CL:Show()
    -- Grab cursor position right now in UI coordinates.
    uiScale = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorUI()

    -- Cancel any running animation before starting a new one.
    StopTicker()
    for i = 1, CONFIG.ringCount do
        if ringPool[i] then ringPool[i]:Hide() end
    end

    -- Initialise state for each ring.
    for i = 1, CONFIG.ringCount do
        local f = GetRingFrame(i)

        -- Position the frame at the current cursor location.
        f:SetSize(CONFIG.startScale, CONFIG.startScale)
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
        f._tex:SetVertexColor(CONFIG.color.r, CONFIG.color.g, CONFIG.color.b, CONFIG.color.a)
        f:Show()

        ringState[i] = {
            active = true,
            t      = 0,
            delay  = (i - 1) * CONFIG.ringStagger,  -- stagger outward rings
        }
    end

    -- Start the master update ticker.
    ticker = C_Timer.NewTicker(CONFIG.tickInterval, OnTick)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Slash command  /findcursor
-- ─────────────────────────────────────────────────────────────────────────────
SLASH_CURSORLOCATOR1 = "/findcursor"
SlashCmdList["CURSORLOCATOR"] = function()
    CursorLocator:Show()
end
