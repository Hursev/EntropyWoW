-- Prints in chat window when you apply to join a thing like an M+ group in LFG and when they accept/decline you

local function OnLfgListApplicationStatus(id, newStatus, oldStatus, desc)
    local group = C_LFGList.GetSearchResultInfo(id)
    if not group then return end
    
    if type(group.activityIDs) ~= "table" then return end
    local activityID = group.activityIDs[1]
    if not activityID then return end
    
    local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
    if not activityInfo then return end
    local dungeon = activityInfo.fullName -- "Lower Karazhan (Mythic Keystone)"
    if not dungeon then return end
    dungeon = string.gsub(dungeon, " %(.*%)$", "")
    local action = string.gsub(newStatus, "_(.*)$", " (%1)") -- "declined_delisted" -> "declined (delisted)"
    if action == "inviteaccepted" then action = "joined" end
    local color = ({
            applied = "FFFFA0",
            invited = "00FF00",
            joined = "D0D0FF",
    })[action]
    if not color then color = "FF0000" end
    local msg = string.format("LFG: |cFF%s%s|r for |cFFFFFFA0%s|r/|cFFFFFFA0%s|r", color, action, dungeon, desc)
    if group.leaderName then
        msg = msg .. string.format(" by |cFFFFFFA0%s|r", group.leaderName)
    end
    
    print(msg)
end


local reminderHandler = CreateFrame("Frame")
reminderHandler:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")

reminderHandler:SetScript("OnEvent", function(self, event, ...)
    if event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
        local id, newStatus, oldStatus, desc = ...
        OnLfgListApplicationStatus(id, newStatus, oldStatus, desc)
    end
end)


