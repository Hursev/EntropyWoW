--[[
    Copyright (C) 2026 Entropy
    License: GNU v3. See LICENSE file and <https://www.gnu.org/licenses/>

File Description:
    Creates a small minimap-attached panel showing your guild information.
    The panel itself shows online/total guild members count.
    On mouse-over - if in guild and out of combat - shows a sortable table of online
        guild members with details.
    Clicking on a guild member will print short RaiderIO info.    
]]

local ADDON_NAME = ...
local GP = CreateFrame("Frame")

-- Libraries
-- local AceConfig = LibStub("AceConfig-3.0")
-- local AceConfigDialog = LibStub("AceConfigDialog-3.0")
-- local AceDB = LibStub("AceDB-3.0")

-------------------------------------------------
-- CONFIG
-------------------------------------------------
--local defaults = {
--  profile = {
local CFG = {

        FONT_SIZE = 12,            -- Font size used for all table text

        PANEL_W = 80,             -- Width of the minimap attached summary panel
        PANEL_H = 24,              -- Height of the minimap summary panel

        PANEL_OFFSET_X = 0,        -- Offset of the main panel 
        PANEL_OFFSET_Y = -20,    

        ROW_H = 18,                -- Height of each table row (affects virtualization math)
        HEADER_H = 20,             -- Height of table header row

        TABLE_W = 760,             -- Width of hover table frame
        TABLE_H = 800,             -- Max Height of hover table frame (viewport height)

        BG_ALPHA = 0.90,           -- Background transparency of table (0=transparent,1=opaque)

        ZONE_COLOR = {0.4,1,0.4},  -- RGB color used when guild member is in player's zone

        HOVER_CLOSE_DIST = 20,     -- Distance in pixels mouse can leave table before closing

        INITIAL_DELAY = 3,         -- Seconds after login before initial async cache build starts

        CACHE_CHUNK = 50,          -- Number of roster entries processed per async chunk

        REGION = "us",             -- RaiderIO region used when querying profiles

        VIRTUAL_EXTRA_ROWS = 3,    -- Extra rows rendered above/below viewport to prevent pop-in
    }
--    }
--}

--local db = LibStub("AceDB-3.0"):New("Entropy_Guild", defaults); -- true)
--local function CFG() return db.profile end
-- Then throughout your code, replace `CFG.FONT_SIZE` with `CFG().FONT_SIZE`
--local CFG = db.profile -- CFG points to saved settings
-- CFG = LibStub("AceDBOptions-3.0"):GetOptionsTable(db);

local TABLE_TOP_PADDING = 8
local TABLE_BOTTOM_PADDING = 8

local COLOR_HEADER = {131/255, 244/255, 239/255} -- Header light blue (131,244,239)
local COLOR_TEXT_DEFAULT = {255/255, 232/255, 52/255} -- Default yellow text (255,232,52)
local COLOR_DIVIDER = {180/255, 150/255, 20/255} -- Dark yellow divider (darker than default text)

local COLOR_RANK_1 = {131/255, 244/255, 239/255} -- light blue
local COLOR_RANK_2 = {255/255, 143/255, 16/255} -- orange
local COLOR_RANK_3 = {255/255, 232/255, 52/255} -- yellow
local COLOR_RANK_4 = {1,1,1} -- white
local COLOR_RANK_5 = {110/255, 225/255, 48/255} -- green
local COLOR_RANK_6 = {128/255, 128/255, 128/255} -- grey
local COLOR_UNKNOWN = {219/255, 48/255, 225/255} -- pink
--local c = rgb(219, 48, 225) -- don't delete me - this is used to invoke color picker in the VS Code

local DEBUG = false

--[[
-------------------------------------------------
-- UI Options
-------------------------------------------------

-- Options table definition
local options = {
    type = "group",
    name = "Guild Panel",
    args = {
        display = {
            type = "group",
            name = "Display Settings",
            inline = true,
            args = {
                FONT_SIZE = {
                    type = "range",
                    name = "Font Size",
                    desc = "Size of text in the guild panel",
                    min = 8,
                    max = 20,
                    step = 1,
                    order = 1,
                    get = function() return CFG.FONT_SIZE end,
                    set = function(_, val) 
                        CFG.FONT_SIZE = val
                        -- You may want to call a refresh function here
                    end,
                },
                PANEL_W = {
                    type = "range",
                    name = "Panel Width",
                    desc = "Width of the minimap panel",
                    min = 50,
                    max = 150,
                    step = 5,
                    order = 2,
                    get = function() return CFG.PANEL_W end,
                    set = function(_, val) 
                        CFG.PANEL_W = val
                        main:SetWidth(val)
                    end,
                },
                PANEL_H = {
                    type = "range",
                    name = "Panel Height",
                    desc = "Height of the minimap panel",
                    min = 16,
                    max = 40,
                    step = 2,
                    order = 3,
                    get = function() return CFG.PANEL_H end,
                    set = function(_, val) 
                        CFG.PANEL_H = val
                        --main:SetHeight(val)
                    end,
                },
                PANEL_OFFSET_X = {
                    type = "range",
                    name = "Panel X Offset",
                    desc = "Horizontal offset from minimap",
                    min = -100,
                    max = 100,
                    step = 1,
                    order = 4,
                    get = function() return CFG.PANEL_OFFSET_X end,
                    set = function(_, val) 
                        CFG.PANEL_OFFSET_X = val
                        main:ClearAllPoints()
                        main:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", CFG.PANEL_OFFSET_X, CFG.PANEL_OFFSET_Y)
                    end,
                },
                PANEL_OFFSET_Y = {
                    type = "range",
                    name = "Panel Y Offset",
                    desc = "Vertical offset from minimap",
                    min = -100,
                    max = 100,
                    step = 1,
                    order = 5,
                    get = function() return CFG.PANEL_OFFSET_Y end,
                    set = function(_, val) 
                        CFG.PANEL_OFFSET_Y = val
                        main:ClearAllPoints()
                        main:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", CFG.PANEL_OFFSET_X, CFG.PANEL_OFFSET_Y)
                    end,
                },
                BG_ALPHA = {
                    type = "range",
                    name = "Background Opacity",
                    desc = "Transparency of the table background",
                    min = 0,
                    max = 1,
                    step = 0.05,
                    isPercent = true,
                    order = 6,
                    get = function() return CFG.BG_ALPHA end,
                    set = function(_, val) 
                        CFG.BG_ALPHA = val
                        panel:SetBackdropColor(0, 0, 0, CFG.BG_ALPHA)
                    end,
                },
            },
        },
        table = {
            type = "group",
            name = "Table Settings",
            inline = true,
            args = {
                TABLE_W = {
                    hidden = true,
                    type = "range",
                    name = "Table Width",
                    desc = "Width of the guild member table",
                    min = 400,
                    max = 1200,
                    step = 20,
                    order = 1,
                    get = function() return CFG.TABLE_W end,
                    set = function(_, val) 
                        CFG.TABLE_W = val
                        panel:SetWidth(val)
                        content:SetWidth(val - 30)
                    end,
                },
                TABLE_H = {
                    type = "range",
                    name = "Table Max Height",
                    desc = "Maximum height of the guild member table",
                    min = 400,
                    max = 1500,
                    step = 50,
                    order = 2,
                    get = function() return CFG.TABLE_H end,
                    set = function(_, val) 
                        CFG.TABLE_H = val
                        UpdatePanelHeight()
                    end,
                },
                ROW_H = {
                    type = "range",
                    name = "Row Height",
                    desc = "Height of each row in the table",
                    min = 14,
                    max = 24,
                    step = 2,
                    order = 3,
                    get = function() return CFG.ROW_H end,
                    set = function(_, val) 
                        CFG.ROW_H = val
                        -- Would need to rebuild table rows
                        if tableOpen then
                            CloseTable()
                            C_Timer.After(0.1, OpenTable)
                        end
                    end,
                },
                HOVER_CLOSE_DIST = {
                    type = "range",
                    name = "Hover Close Distance",
                    desc = "Distance in pixels mouse can leave table before it closes",
                    min = 0,
                    max = 100,
                    step = 5,
                    order = 4,
                    get = function() return CFG.HOVER_CLOSE_DIST end,
                    set = function(_, val) 
                        CFG.HOVER_CLOSE_DIST = val
                    end,
                },
            },
        },
        colors = {
            type = "group",
            name = "Color Settings",
            inline = true,
            args = {
                ZONE_COLOR = {
                    type = "color",
                    name = "Same Zone Color",
                    desc = "Color used when a guild member is in your zone",
                    order = 1,
                    hasAlpha = false,
                    get = function() 
                        return CFG.ZONE_COLOR[1], CFG.ZONE_COLOR[2], CFG.ZONE_COLOR[3]
                    end,
                    set = function(_, r, g, b) 
                        CFG.ZONE_COLOR[1] = r
                        CFG.ZONE_COLOR[2] = g
                        CFG.ZONE_COLOR[3] = b
                        if tableOpen then
                            UpdateVisibleRows()
                        end
                    end,
                },
            },
        },
        raiderio = {
            type = "group",
            name = "RaiderIO Settings",
            inline = true,
            args = {
                REGION = {
                    type = "select",
                    name = "Region",
                    desc = "Your region for RaiderIO lookups",
                    order = 1,
                    values = {
                        us = "US - Americas",
                        eu = "EU - Europe",
                        kr = "KR - Korea",
                        tw = "TW - Taiwan",
                        cn = "CN - China",
                    },
                    get = function() return CFG.REGION end,
                    set = function(_, val) 
                        CFG.REGION = val
                        -- Clear cache to force re-fetch with new region
                        if cacheReady then
                            wipe(cacheByName)
                            cacheReady = false
                            StartInitialBuild()
                        end
                    end,
                },
            },
        },
    },
}

-- Register options
--AceConfig:RegisterOptionsTable("Entropy_Guild", options)
--AceConfigDialog:AddToBlizOptions("Entropy_Guild", "Guild Panel") -- , "Entropy"
AceConfig:RegisterOptionsTable("Entropy_Guild", options)
AceConfigDialog:AddToBlizOptions("Entropy_Guild", "Entropy_Guild") -- , "Entropy"

-- Slash command to open settings
SLASH_ENTROPY1 = "/entropyguild"
SLASH_ENTROPY2 = "/my"
SlashCmdList["ENTROPY"] = function()
    AceConfigDialog:Open("Entropy_Guild")
end
]]
-------------------------------------------------
-- State
-------------------------------------------------
local cacheByName = {}
local cacheArray = {} -- sorted list reference
local guildTotal
local cacheReady = false
local buildingCache = false

-- Ordered list of sort columns. First entry is the primary sort key.
-- 'index' is always appended implicitly as the final tiebreaker.
local sortList = {
    { key="level", asc=false },
    { key="name",  asc=true  },
    { key="rank",  asc=true  },
}

-- Default sort direction (asc=true means ASC) when a column is first activated
local SORT_DEFAULT_ASC = {
    name  = true,
    zone  = true,
    mplus = false,
    rank  = true,
    level = false,
    note  = false,
}

local rosterIndex = 1
local rosterTotal = 0

local playerZone = ""
local partyMembers = {}

-------------------------------------------------
-- Fonts
-------------------------------------------------
local FONT_N = "Interface\\AddOns\\Entropy\\Media\\PTSansNarrow.ttf"
local FONT_B = "Interface\\AddOns\\Entropy\\Media\\PTSansNarrow-Bold.ttf"


-------------------------------------------------
-- UI Creation
-------------------------------------------------
local main = CreateFrame("Frame", nil, Minimap)
main:SetSize(CFG.PANEL_W, CFG.PANEL_H)
main:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", CFG.PANEL_OFFSET_X, CFG.PANEL_OFFSET_Y)
main:SetFrameStrata("MEDIUM")

main.bg = main:CreateTexture(nil,"BACKGROUND")
main.bg:SetAllPoints()
main.bg:SetColorTexture(0,0,0,0.4)

main.txt = main:CreateFontString(nil,"OVERLAY")
main.txt:SetFont(FONT_N, CFG.FONT_SIZE)
main.txt:SetPoint("CENTER")

-------------------------------------------------
-- Table Panel + Scroll
-------------------------------------------------
local panel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
panel:SetFrameStrata("TOOLTIP")
panel:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background"})
panel:SetBackdropColor(0,0,0,CFG.BG_ALPHA)
panel:SetSize(CFG.TABLE_W, CFG.TABLE_H)
panel:Hide()

local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",5,-CFG.HEADER_H-8)
scroll:SetPoint("BOTTOMRIGHT",-28,5)

local content = CreateFrame("Frame", nil, scroll)
scroll:SetScrollChild(content)
content:SetWidth(CFG.TABLE_W - 30) -- subtract scrollbar + padding

panel.rows = {}

-------- Table Header Divider
local headerDivider = panel:CreateTexture(nil, "ARTWORK")
headerDivider:SetHeight(1)
headerDivider:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, -CFG.HEADER_H - 4)
headerDivider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -CFG.HEADER_H - 4)
headerDivider:SetColorTexture(unpack(COLOR_DIVIDER))

--[[    Alternative with gradient
local headerShadow = panel:CreateTexture(nil, "ARTWORK")
headerShadow:SetHeight(12)
headerShadow:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, -CFG.HEADER_H - 4)
headerShadow:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -CFG.HEADER_H - 4)

-- ERROR - SetGradientAlpha missing
headerShadow:SetGradientAlpha(
    "VERTICAL",
    COLOR_DIVIDER[1], COLOR_DIVIDER[2], COLOR_DIVIDER[3], 0.35,
    COLOR_DIVIDER[1], COLOR_DIVIDER[2], COLOR_DIVIDER[3], 0.0
)
]]


-------------------------------------------------
-- String Helpers (No regex)
-------------------------------------------------
local function StripRealm(full)
    if not full then return "" end
    local pos = string.find(full, "-", 1, true)
    if pos then return string.sub(full,1,pos-1) end
    return full
end

local function SplitFull(full)
    local pos = string.find(full, "-", 1, true)
    if not pos then return full,nil end
    return string.sub(full,1,pos-1), string.sub(full,pos+1)
end

local function IsNilString(a)
    if a == nil then return "is nil" end
    return "is not nil"
end

local function PrintNonZero(text, value)
    if (value and value > 0) then
        print(text .. value)
    end
end

local function PrintTable(p)
    if DEBUG then
        for key, value in pairs(p) do
            print(key .. " = " .. tostring(value))
        end
    end
end

-------------------------------------------------
-- Party Cache
-------------------------------------------------
local function UpdateParty()
    wipe(partyMembers)

    if not IsInGroup() then return end

    local n = GetNumGroupMembers()
    for i=1,n do
        local unit = IsInRaid() and ("raid"..i) or ("party"..i)
        if UnitExists(unit) then
            local n,r = UnitName(unit)
            if n then
                if r and r~="" then
                    partyMembers[n.."-"..r] = true
                else
                    partyMembers[n] = true
                end
            end
        end
    end
end

-------------------------------------------------
-- Colors
-------------------------------------------------
local levelColorCache = {}

local function LevelColor(level)
    if not level then return 1,1,1 end
    if not levelColorCache[level] then
        local c = GetQuestDifficultyColor(level)
        levelColorCache[level] = {c.r,c.g,c.b}
    end
    local t = levelColorCache[level]
    return t[1],t[2],t[3]
end

local function MPlusColor(score)
    if not score or score==0 then return 1,1,1 end

    if RaiderIO and RaiderIO.GetScoreColor then
        local r, g, b = RaiderIO.GetScoreColor(score)
        return r,g,b
    end

    local c = C_ChallengeMode.GetDungeonScoreRarityColor(score)
    if c then return c.r,c.g,c.b end

    return 1,1,1
end

-------------------------------------------------
-- Build Single Member Entry
-------------------------------------------------

local function BuildMemberEntryDump(index)
    --ElvUI:
    local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(index)
--    local name, rank,     rankIndex, level, class,            zone, note,       officernote, online,   isAway, classFileName, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i)
   
    print(string.format("|cFF00FF00[My.Guild]|r BuildMemberEntryDump index: %d", index))
    print(string.format("name: %s", tostring(name)))
    print(string.format("rankName: %s", tostring(rankName)))
    print(string.format("rankIndex: %s", tostring(rankIndex)))
    print(string.format("level: %s", tostring(level)))
    print(string.format("classDisplayName: %s", tostring(classDisplayName)))
    print(string.format("zone: %s", tostring(zone)))
    print(string.format("publicNote: %s", tostring(publicNote)))
    print(string.format("officerNote: %s", tostring(officerNote)))
    print(string.format("isOnline: %s", tostring(isOnline)))
    print(string.format("status: %s", tostring(status)))
    print(string.format("class: %s", tostring(class)))
    print(string.format("achievementPoints: %s", tostring(achievementPoints)))
    print(string.format("achievementRank: %s", tostring(achievementRank)))
    print(string.format("isMobile: %s", tostring(isMobile)))
    print(string.format("canSoR: %s", tostring(canSoR)))
    print(string.format("repStanding: %s", tostring(repStanding)))
    print(string.format("guid: %s", tostring(guid)))	
end
local function GetAfkText(status)
    --status,number,"0 = Online, 1 = Away (AFK), 2 = Busy (DND)."
    if status == 0 then return "" 
    elseif status == 1 then return " (AFK)"
    elseif status == 2 then return " (DND)"
    else
        return "?"
    end
end
local DUMP_MEMEBR = 1
local function BuildMemberEntry(index)
    --[[Key,Type,Description
        name,string,Full name (Name-Realm).
        rankName,string,"The string name of their rank (e.g., ""Officer"")."
        rankIndex,number,The numeric rank (0 is Guild Master).
        level,number,Current character level.
        classID,number,The numeric ID of the class. - Like "Demon Hunter"
        zone,string,Current zone name (returns nil or empty if offline).
        publicNote,string,The text in the Public Note field.
        officerNote,string,The text in the Officer Note field (if you have permission).
        isOnline,boolean,true if they are currently logged in.
        status,number,"0 = Online, 1 = Away (AFK), 2 = Busy (DND)."
        class, string, like "DEMONHUNTER"
        achievementPoints,
         achievementRank
         isMobile,boolean,true if they are logged in via the WoW Companion App.
         isSoREligible,boolean,"Legacy field for ""Scroll of Resurrection."""
         repStanding
         guid,string,The unique character ID (Use this for tooltips!).
        ]]
    local name, rank, rankIndex, level, classDisplayName, zone,
          note, officerNote, online,
           status, -- "0 = Online, 1 = Away (AFK), 2 = Busy (DND)."
           class,
           _, _, isMobile,
           _, repStanding, guid = GetGuildRosterInfo(index)

    if not name then return end

    if online and not isMobile then

        local short, realm = SplitFull(name)

        local score = 0

        if RaiderIO and RaiderIO.GetProfile then
            local p = RaiderIO.GetProfile(short, realm, CFG.REGION)
            if p and p.mythicKeystoneProfile then
                score = p.mythicKeystoneProfile.currentScore or 0
            end
        end
        local sAfk = GetAfkText(status)
        local res = {
            full=name,
            name=short,
            realm=realm,
            rank=rank,
            rankIndex=rankIndex or 999,
            level=level,
            zone=zone,
            note=note or "",
            officerNote=officerNote or "",
            class=class,
            classDisplayName=classDisplayName,
            afkStatus=sAfk,
            mplus=score,
            index=index,
            guid=guid
        }
        cacheByName[name] = res;
        
        -- if DEBUG and DUMP_MEMEBR and DUMP_MEMEBR > 0 then 
        --     BuildMemberEntryDump(index)
        --     DUMP_MEMEBR = DUMP_MEMEBR - 1
        -- end
        return res;
    else
        cacheByName[name] = nil
        return null
    end
end

-------------------------------------------------
-- Main Text
-------------------------------------------------
local function UpdateMain()
    if not IsInGuild() then
        main.txt:SetText("No Guild")
        return
    end

    if not cacheReady then
        main.txt:SetText("Guild: ...")
        return
    end

    local online=0
    for _ in pairs(cacheByName) do online=online+1 end

    main.txt:SetText("Guild: "..online.."/"..(guildTotal or "?"))
end


-------------------------------------------------
-- Async Initial Build
-------------------------------------------------
local DEBUG_log = 0;
local function ProcessChunk()
    --if DEBUG and rosterIndex < 2 then print(string.format("|cFF00FF00[My.Guild]|r ProcessChunk rosterIndex %d of total %d", rosterIndex, rosterTotal)) end
    local processed=0

    while rosterIndex<=rosterTotal and processed<CFG.CACHE_CHUNK do
        local res = BuildMemberEntry(rosterIndex)
        rosterIndex=rosterIndex+1
        processed=processed+1
        if DEBUG and res then
            if DEBUG_log > 0 then
                DEBUG_log = DEBUG_log - 1
                print(string.format("|cFF00FF00[My.Guild]|r BuildMemberEntry(%d) name: %s", rosterIndex, res.name))
            end
        end
    end

    if rosterIndex<=rosterTotal then
        C_Timer.After(0, ProcessChunk)
    else
        buildingCache=false
        cacheReady=true
        -- if DEBUG then print(string.format("|cFF0FF000[My.Guild]|r ProcessChunk done")) end
        UpdateMain() -- update the main panel text
    end
end

local function StartInitialBuild()

    if buildingCache then return end

    --if not C_GuildInfo.IsGuildMemberInfoLoaded() then
--        C_GuildInfo.QueryGuildMembers()
    --    return
    --end

    wipe(cacheByName)

    rosterTotal = GetNumGuildMembers()
    --if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r rosterTotal %d", rosterTotal)) end

    guildTotal = rosterTotal
    rosterIndex = 1

    buildingCache=true
    cacheReady=false

    ProcessChunk()
end

-------------------------------------------------
-- Smart Diff Update
-------------------------------------------------
local function SmartRosterDiff()

    --if not C_GuildInfo.IsGuildMemberInfoLoaded() then
        --C_GuildInfo.QueryGuildMembers()
    --    return
    --end

    local total = GetNumGuildMembers()
    guildTotal = total

    local seen = {}

    for i=1,total do
        local name = GetGuildRosterInfo(i)
        if name then
            seen[name]=true
            BuildMemberEntry(i)
        end
    end

    for name in pairs(cacheByName) do
        if not seen[name] then
            cacheByName[name]=nil
        end
    end

    cacheReady=true
end

-------------------------------------------------
-- Sorting
-------------------------------------------------

local function cmpMain(asc, v1, v2)
    if v1 and not v2 then return true end
    if v2 and not v1 then return false end
    if asc then return v1<v2 else return v1>v2 end
end

local function cmp(v1, v2)
    if v1 and not v2 then return true end
    if v2 and not v1 then return false end
    return v1<v2
end

local function cmpRev(v1, v2)
    if v1 and not v2 then return true end
    if v2 and not v1 then return false end
    return v1>v2
end

-- Maps a sort key to the actual field value on a member record.
-- 'rank' sorts by numeric rankIndex; everything else uses the named field directly.
local function FieldValue(member, key)
    if key == "rank" then return member.rankIndex end
    return member[key]
end

local function Compare(a, b)
    if a and not b then return true end
    if b and not a then return false end

    -- Party members always float to the top
    local pa = partyMembers[a.full]
    local pb = partyMembers[b.full]
    if pa ~= pb then return pa end

    -- Walk the ordered sort list
    for _, col in ipairs(sortList) do
        local va = FieldValue(a, col.key)
        local vb = FieldValue(b, col.key)
        if va ~= vb then
            return cmpMain(col.asc, va, vb)
        end
    end

    -- Final tiebreaker: roster index (always ascending)
    return a.index < b.index
end


local function CompareDbg(a,b)
    local res = Compare(a,b)

    if a and b then
        print(string.format("|cFFFF0000[My.Guild]|r Compare %d.%s / %d.%s -> %s", a.index, a.full, b.index, b.full, tostring(res)))
    else
        print(string.format("|cFFFF0000[My.Guild]|r Compare a %s / b %s -> %s", IsNilString(a), IsNilString(b), tostring(res)))
    end

    return res
end

local function RebuildSortedArray()
    wipe(cacheArray)
    for _,v in pairs(cacheByName) do
        table.insert(cacheArray,v)
        if v == nil then 
            print(string.format("|cFFFF0000[My.Guild]|r RebuildSortedArray ERROR - v=nil"))
        end
    end
    if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r RebuildSortedArray n=%d by %s", #cacheArray, sortList[1] and sortList[1].key or "?")) end
    table.sort(cacheArray, Compare)
end


-------------------------------------------------
-- Virtualization
-------------------------------------------------
local function PrintRaiderIODetails(member)
    if not RaiderIO or not RaiderIO.GetProfile then
        print("RaiderIO not available")
        return
    end

    local name, realm = member.name, member.realm

    local profile = RaiderIO.GetProfile(name, realm)
    if not profile then
        print(string.format("|cFF00FF00[My.Guild]|r No RaiderIO data for %s, %s", name, realm))
        return
    end
    
    print("|cFF00FF00[My.Guild]|r " .. name .. "-" .. realm ..":")

    local p = profile.mythicKeystoneProfile
    --PrintTable(p)

    local score = p.currentScore or 0
    local previousScore = p.previousScore or 0
    if (previousScore > score) then
        print("|cFF00FF00[My.Guild]|r M+ Score: " .. score .. " (prev:" .. previousScore .. ")")
    else
        print("|cFF00FF00[My.Guild]|r M+ Score: " .. score)
    end
    if p.mainCurrentScore and p.mainCurrentScore > score then
        PrintNonZero("|cFF00FF00[My.Guild]|r Main's Score:", p.mainCurrentScore); -- also p.mplusMainCurrent.score
    end
    PrintNonZero("|cFF00FF00[My.Guild]|r Max Key: ", p.maxDungeonLevel);
    PrintNonZero("|cFF00FF00[My.Guild]|r 4+  Runs: ", p.keystoneMilestone4);
    PrintNonZero("|cFF00FF00[My.Guild]|r 7+  Runs: ", p.keystoneMilestone7);
    PrintNonZero("|cFF00FF00[My.Guild]|r 10+ Runs: ", p.keystoneMilestone10);
    PrintNonZero("|cFF00FF00[My.Guild]|r 12+ Runs: ", p.keystoneMilestone12);
    PrintNonZero("|cFF00FF00[My.Guild]|r 15+ Runs: ", p.keystoneMilestone15);
end

local visibleRows = math.ceil(CFG.TABLE_H / CFG.ROW_H) + CFG.VIRTUAL_EXTRA_ROWS

local function EnsureRow(i)
    if panel.rows[i] then return panel.rows[i] end

    local r = CreateFrame("Button", nil, content)
    r:SetHeight(CFG.ROW_H)
    r:SetPoint("LEFT")
    r:SetPoint("RIGHT")

    r.bg = r:CreateTexture(nil,"BACKGROUND")
    r.bg:SetAllPoints()
    r.bg:SetColorTexture(1,1,1,0)

    r.cols={}
    local x=0

    local cols = {
        {"level",50},
        {"mplus",60},
        {"name",130},
        {"zone",170},
        {"rank",130},
        {"note",200},
    }

    for _,c in ipairs(cols) do
        local fs=r:CreateFontString(nil,"OVERLAY")
        fs:SetFont(FONT_N, CFG.FONT_SIZE)
        fs:SetPoint("LEFT",x+4,0)
        fs:SetWidth(c[2])
        fs:SetJustifyH("LEFT")
        r.cols[c[1]]=fs
        x=x+c[2]+4
    end

    r:EnableMouse(true)
    r:RegisterForClicks("LeftButtonUp")
--[[Data:
        full=name,
        name=short,
        realm=realm,
        rank=rank,
        rankIndex=rankIndex or 999,
        level=level,
        zone=zone,
        note=note or "",
        class=class,
        mplus=score,
        index=index
    ]]
    r:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(1,1,1,0.1)

        if not self.data then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        --GameTooltip:SetGuildRoster(self.data.index)
        if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r SetGuildMember data.index: %s, guid %s", tostring(self.data.index), tostring(self.data.guid))) end
        GameTooltip:SetUnit(self.data.guid)
        --GameTooltip:SetUnit("unit:" .. self.data.guid)
        GameTooltip:Show()
    end)

    r:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(1,1,1,0)
        GameTooltip:Hide()
    end)

    r:SetScript("OnClick", function(self, button)
        --if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r Row Click %s %s", tostring(self.member), button)) end
        --if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r Row Click data: %s", tostring(self.data))) end
        if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r Row Click data.index: %s, class %s", tostring(self.data.index), tostring(self.data.class))) end
        if not self.data then return end
        if button ~= "LeftButton" then return end

        local name = self.data.name
        local full = self.data.full
        if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r Row Click name: %s", name)) end

        if IsShiftKeyDown() then
            ChatFrame_SendTell(full)
        else
            PrintRaiderIODetails(self.data)
        end
    end)

    panel.rows[i]=r

    --if DEBUG and i < 5 then print(string.format("|cFF00FF00[My.Guild]|r EnsureRow create panel %d", i)) end
    return r
end
local function GetGuildRankColor(r) -- COLOR_TEXT_DEFAULT
    if r < 2 then return COLOR_RANK_1 end
    if r < 4 then return COLOR_RANK_2 end
    if r < 6 then return COLOR_RANK_3 end
    if r < 8 then return COLOR_RANK_4 end
    if r < 9 then return COLOR_RANK_5 end
    if r < 10 then return COLOR_RANK_6 end
    return COLOR_UNKNOWN
end
local function UpdateVisibleRows()
    -- if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r UpdateVisibleRows visibleRows=%d", visibleRows)) end

    local offset = scroll:GetVerticalScroll()
    local firstIndex = math.floor(offset / CFG.ROW_H) + 1

    for i=1,visibleRows do
        local dataIndex = firstIndex + i - 1
        local data = cacheArray[dataIndex]

        local row = EnsureRow(i)

        if data then
            row:Show()
            row:SetPoint("TOPLEFT",0,-((dataIndex-1)*CFG.ROW_H))

            row.data=data

            local cr=RAID_CLASS_COLORS[data.class or "PRIEST"] or {r=1,g=1,b=1}
            local lr,lg,lb=LevelColor(data.level)
            local mr,mg,mb=MPlusColor(data.mplus)

            row.cols.level:SetTextColor(lr,lg,lb)
            row.cols.level:SetText(data.level or "")

            row.cols.mplus:SetTextColor(mr,mg,mb)
            row.cols.mplus:SetText(data.mplus or 0)

            if partyMembers[data.full] then
                row.cols.name:SetFont(FONT_B, CFG.FONT_SIZE)
            else
                row.cols.name:SetFont(FONT_N, CFG.FONT_SIZE)
            end

            row.cols.name:SetTextColor(cr.r,cr.g,cr.b)
            row.cols.name:SetText(data.name .. data.afkStatus)

            if data.zone==playerZone then
                local c=CFG.ZONE_COLOR
                row.cols.zone:SetTextColor(c[1],c[2],c[3])
            else
                -- row.cols.zone:SetTextColor(1,1,1)
                row.cols.zone:SetTextColor(unpack(COLOR_TEXT_DEFAULT))
            end

            row.cols.zone:SetText(data.zone or "")
            
            row.cols.rank:SetTextColor(unpack(GetGuildRankColor(data.rankIndex))) -- COLOR_TEXT_DEFAULT
            row.cols.rank:SetText(data.rank or "")
            --row.cols.rank:SetText(data.rank .. " (" .. tostring(data.rankIndex) .. ")")
            
            --row.cols.note:SetTextColor(unpack(COLOR_TEXT_DEFAULT))
            row.cols.note:SetText(data.note or "")

            --if DEBUG and i < 5 then print(string.format("|cFF00FF00[My.Guild]|r UpdateVisibleRows added row %d: %s", i, data.name)) end
        else
            --if DEBUG and i < 5 then print(string.format("|cFF00FF00[My.Guild]|r UpdateVisibleRows missing row data %d", i)) end
            row:Hide()
        end
    end
end

scroll:SetScript("OnVerticalScroll", function(self,offset)
    self:SetVerticalScroll(offset)
    UpdateVisibleRows()
end)

local function ClampPanelToScreen(frame)
    local physW, physH = GetPhysicalScreenSize()
    local scale = UIParent:GetEffectiveScale()

    local sw = physW / scale
    local sh = physH / scale

    local left = frame:GetLeft()
    local right = frame:GetRight()
    local top = frame:GetTop()
    local bottom = frame:GetBottom()

    local dx, dy = 0,0

    if left < 0 then dx = -left end
    if right > sw then dx = sw - right end
    if bottom < 0 then dy = -bottom end
    if top > sh then dy = sh - top end

    if dx ~= 0 or dy ~= 0 then
        local p, rel, rp, x, y = frame:GetPoint(1)
        frame:SetPoint(p, rel, rp, x+dx, y+dy)
    end
end

local function UpdatePanelHeight()

    if not cacheReady then
        panel:SetHeight(CFG.TABLE_H)
        return
    end

    local totalRows = #cacheArray
    local rowsHeight = totalRows * CFG.ROW_H

    local headerArea = CFG.HEADER_H + TABLE_TOP_PADDING
    local footerArea = TABLE_BOTTOM_PADDING

    local desiredHeight = headerArea + rowsHeight + footerArea

    local finalHeight = math.min(CFG.TABLE_H, desiredHeight)

    panel:SetHeight(finalHeight)

    if (#cacheArray * CFG.ROW_H) <= scroll:GetHeight() then
        scroll.ScrollBar:Hide()
    else
        scroll.ScrollBar:Show()
    end
end

-------------------------------------------------
-- Populate Entry
-------------------------------------------------
local function RefreshTable()
    if not cacheReady then return end
    RebuildSortedArray()
    content:SetHeight(#cacheArray * CFG.ROW_H)
    UpdatePanelHeight()
    UpdateVisibleRows()
end


-------------------------------------------------
-- Open Close
-------------------------------------------------
local tableOpen=false
local refreshRunning=false

local function OpenTable()
    if InCombatLockdown() then return end
    if not IsInGuild() then return end

    
    local mainCenterX = main:GetLeft() + main:GetWidth()/2
    local mainBottomY = main:GetBottom()

    panel:ClearAllPoints()
    panel:SetPoint(
        "TOP",
        UIParent,
        "BOTTOMLEFT",
        mainCenterX,
        mainBottomY - 6
    )

    panel:Show()
    tableOpen = true

    ClampPanelToScreen(panel)

    RefreshTable()
    --[[
        local x,y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        
        panel:ClearAllPoints()
        panel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x/s, y/s)
        panel:Show()
        
        tableOpen=true
        
        RefreshTable()
        --ClampPanelToScreen(panel)
    ]]

    if not refreshRunning then
        refreshRunning=true
        C_Timer.After(1,function()
            if tableOpen then
                SmartRosterDiff()
                RefreshTable()
            end
            refreshRunning=false
        end)
    end
end

local function CloseTable()
    panel:Hide()
    tableOpen=false
end

-------------------------------------------------
-- Table Header
-------------------------------------------------
local headers = {}

local HEADER_DEF = {
 {key="level", label="Level", w=50},
 {key="mplus", label="M+", w=60},
 {key="name", label="Name", w=130},
 {key="zone", label="Zone", w=170},
 {key="rank", label="Rank", w=130},
 {key="note", label="Note", w=200},
}

local function CreateHeaders()
    local x = 5

    for i,h in ipairs(HEADER_DEF) do
        local b = CreateFrame("Button", nil, panel)
        b:SetSize(h.w, CFG.HEADER_H)
        b:SetPoint("TOPLEFT", x, -5)
        b.key = h.key

        local t = b:CreateFontString(nil,"OVERLAY")
        t:SetFont(FONT_B, CFG.FONT_SIZE)
        t:SetTextColor(unpack(COLOR_HEADER))
        t:SetPoint("LEFT",2,0)
        t:SetText(h.label)

        b:SetScript("OnClick", function(self)
            local clickedKey = self.key

            -- Find if this key already exists somewhere in the sort list
            local existingPos = nil
            for i, col in ipairs(sortList) do
                if col.key == clickedKey then
                    existingPos = i
                    break
                end
            end

            if existingPos == 1 then
                -- Already the primary sort key: just flip its direction
                sortList[1].asc = not sortList[1].asc
            elseif existingPos then
                -- Exists but not primary: promote to front, keep its current direction
                local col = table.remove(sortList, existingPos)
                 
                table.insert(sortList, 1, col) -- preserve the previous sort direction by that column
                -- table.insert(sortList, 1, { key=clickedKey, asc=SORT_DEFAULT_ASC[clickedKey] }) -- use default sort direction for the newly clicked header
            else
                -- Not in list yet: insert at front with the column's default direction
                table.insert(sortList, 1, { key=clickedKey, asc=SORT_DEFAULT_ASC[clickedKey] })
            end

            RefreshTable()
        end)

        headers[i] = b
        x = x + h.w + 4
    end
end
CreateHeaders()

-------------------------------------------------
-- Events
-------------------------------------------------
GP:RegisterEvent("PLAYER_LOGIN")
GP:RegisterEvent("GUILD_ROSTER_UPDATE")
GP:RegisterEvent("ZONE_CHANGED_NEW_AREA")
GP:RegisterEvent("GROUP_ROSTER_UPDATE")

GP:SetScript("OnEvent", function(self,e)

    if e=="PLAYER_LOGIN" then
        -- print(string.format("|cFF00FF00[My.Guild]|r SetFont %s, %s", FONT_N, tostring(CFG.FONT_SIZE)))
        playerZone=GetRealZoneText() or ""

        C_Timer.After(CFG.INITIAL_DELAY,function()
            if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r Initial")) end
            StartInitialBuild()
            UpdateMain()
        end)

    elseif e=="GUILD_ROSTER_UPDATE" then
        
            if buildingCache then return end -- don't process GUILD_ROSTER_UPDATE if we are currently building the cache
            if not cacheReady then return end -- don't process GUILD_ROSTER_UPDATE before the initial build
            --if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r GUILD_ROSTER_UPDATE")) end
            SmartRosterDiff()
            UpdateMain()
            if tableOpen then RefreshTable() end
        --[[]]
            
    elseif e=="ZONE_CHANGED_NEW_AREA" then
        if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r ZONE_CHANGED_NEW_AREA")) end
        playerZone=GetRealZoneText() or ""
        if tableOpen then UpdateVisibleRows() end

    elseif e=="GROUP_ROSTER_UPDATE" then
        if DEBUG then print(string.format("|cFF00FF00[My.Guild]|r GROUP_ROSTER_UPDATE")) end
        UpdateParty()
        if tableOpen then UpdateVisibleRows() end
    end
end)

-------------------------------------------------
-- Hover Logic
-------------------------------------------------
main:SetScript("OnEnter", function()
    -- if the user is dragging something don't pop-up the Table
    if IsMouseButtonDown("LeftButton") then --  or IsMouseButtonDown("RightButton") or IsMouseButtonDown("MiddleButton") 
        return
    end

    if not cacheReady then
        StartInitialBuild()
        UpdateMain()
    end
    OpenTable()
end)

main:SetScript("OnLeave", function()
    C_Timer.After(0.1,function()
        if not MouseIsOver(panel) then CloseTable() end
    end)
end)

panel:SetScript("OnUpdate", function()

    if not tableOpen then return end

    local cx,cy=GetCursorPosition()
    local s=UIParent:GetEffectiveScale()
    cx=cx/s
    cy=cy/s

    local l,r=panel:GetLeft(),panel:GetRight()
    local t,b=panel:GetTop(),panel:GetBottom()

    if cx<l-CFG.HOVER_CLOSE_DIST or cx>r+CFG.HOVER_CLOSE_DIST
    or cy<b-CFG.HOVER_CLOSE_DIST or cy>t+CFG.HOVER_CLOSE_DIST then
        CloseTable()
    end
end)
