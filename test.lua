local function benchmark1(iterations, str, prefix)
    --local str = "abcdefghijklmnopqrstuvwxyz"
    --local prefix = "abc"
    local len = #prefix
    local pattern = "^"..prefix
    print(string.format("benchmark1 %d str:'%s', sub:'%s'", iterations, str, prefix))
    
    -- Localize functions for speed
    local sub = string.sub
    local find = string.find
    local getTime = GetTimePreciseSec -- High precision WoW function

    -- Method 1: string.sub
    local start = getTime()
    for i = 1, iterations do
        local _ = sub(str, 1, len) == prefix
    end
    print(string.format("string.sub:               %.4f seconds", getTime() - start))

    -- Method 2: string.find (Plain)
    start = getTime()
    for i = 1, iterations do
        local _ = find(str, prefix, 1, true) == 1
    end
    print(string.format("string.find (plain):    %.4f seconds", getTime() - start))

    -- Method 3: string.find (Pattern)
    start = getTime()
    for i = 1, iterations do
        local _ = str:match(pattern) ~= nil
    end
    print(string.format("string.match (pattern): %.4f seconds", getTime() - start))
   
end

--10000000

SLASH_MYTEST1 = "/mytest"
SlashCmdList["MYTEST"] = function(msg)
    local n = tonumber(msg)

    print("|cFFFF0000[MYTEST]|r" .. msg)
    -- local n = 100000 --00
    benchmark1(n, "boss2", "boss");
    benchmark1(n, "aboss2", "boss");
    benchmark1(n, "a123123 123123 boss2", "boss");
    benchmark1(n, "a123123 123123 123123", "boss");
end

-- -- **********************************************
-- -------------- Secure Value formatting
-- 
-- -- fs:SetText("***")
-- 
-- -- HealthDeficit.lua
-- -- Displays the player's health deficit (missing HP) as floating text.
-- -- Uses SecureHandlerTimerTemplate so it works in combat and M+ (no taint).
-- 
-- local UPDATE_INTERVAL = 0.2  -- seconds
-- 
-- -- ─── Display frame ────────────────────────────────────────────────────────────
-- -- SecureUnitButtonTemplate  → lets restricted env call secure unit functions
-- -- SecureHandlerTimerTemplate → provides the built-in restricted timer mechanism
-- 
-- local f = CreateFrame(
--     "Button",
--     "HealthDeficitFrame",
--     UIParent,
--     "SecureUnitButtonTemplate"
-- )
-- f:SetSize(1, 1)
-- f:SetPoint("CENTER", UIParent, "CENTER", -200, 300)
-- f:SetAttribute("unit", "player")
-- 
-- -- Font string
-- local fs = f:CreateFontString(nil, "OVERLAY")
-- fs:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
-- fs:SetTextColor(1, 0.25, 0.25, 1)
-- fs:SetPoint("CENTER", f, "CENTER", 0, 0)
-- f:SetFontString(fs)  -- links fs so the restricted :SetText() targets it
-- 
-- fs:SetText("***")
-- 
-- -- ─── Restricted attribute handler ─────────────────────────────────────────────
-- -- Fires whenever the "deficit" attribute is written (by the timer below).
-- f:SetAttribute("_onattributechanged", [[
--     if name ~= "deficit" then return end
--     local val = tonumber(value) or 0
--     if val == 0 then
--         self:SetText("")
--     elseif val >= 1000000 then
--         self:SetText(format("%.1fM", val / 1000000))
--     elseif val >= 1000 then
--         self:SetText(format("%.1fk", val / 1000))
--     else
--         self:SetText(format("%.0f", val))
--     end
-- ]])
-- 
-- local function MyRepeatingTask()
--     -- Your logic for the secret value or abbreviation goes here
--     local value = 5400 -- Example value
--     
--     if value > 0 then
--         local deficit = UnitHealthMissing("player")
--         print(string.format("%.0f", deficit))
--         f:SetAttribute("deficit", deficit)
--     end
-- end
-- 
-- -- Create the ticker: (interval in seconds, function to call)
-- --C_Timer.NewTicker(2, MyRepeatingTask)
-- 

-- -- ─── Restricted timer snippet ──────────────────────────────────────────────────
-- -- Runs every UPDATE_INTERVAL seconds in the secure environment.
-- -- UnitHealthMissing is whitelisted here, safe in M+ / combat.
-- f:SetAttribute("_ontimer", [[
-- ]])
-- 
-- -- ─── Start the timer on login ──────────────────────────────────────────────────
-- local boot = CreateFrame("Frame")
-- boot:RegisterEvent("PLAYER_LOGIN")
-- boot:SetScript("OnEvent", function(self)
--     f:SetAttribute("timer-interval", UPDATE_INTERVAL)
--     self:UnregisterAllEvents()
-- end)