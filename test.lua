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
