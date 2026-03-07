-- Adds a line about the maximum item's stack size in the game tooltip

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
    --[[ data:
        Field       Type    Description
        --------------------------------
        id          number  Item ID
        name        string  Item name
        link        string  Full item link
        quality     number  Item quality (0=poor, 1=common, etc.)
        hyperlink   string  The hyperlink string
        lines       table   Array of tooltip lines already added
    ]]
    
    -- local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, iconID, vendorPrice = GetItemInfo(itemID)
    local maxStack = select(8, GetItemInfo(data.id))

    if maxStack and maxStack > 1 then
        tooltip:AddDoubleLine("Max Stack:", tostring(maxStack), 1,1,0.6, 1,0.82,0)
        --tooltip:AddDoubleLine("1. Max Stack:", tostring(maxStack), 1,1,0.4, 1,0.82,0) -- value on right column
        --tooltip:AddLine("|cFFFFFF66Max Stack:|r " .. maxStack, 1, 1, 1) -- everything on the left column
    end
end)

--[[
GameTooltip:HookScript("OnTooltipSetItem", function(self)
    local _, link = self:GetItem()
    if link then
        local maxStack = select(8, GetItemInfo(link))
        if maxStack and maxStack > 1 then
            self:AddLine("Max Stack: " .. maxStack, 1, 1, 1)
        end
    end
end)
]]