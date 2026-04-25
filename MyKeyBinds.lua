-- Function to set F to Interact With Target
local function SetFToInteract()
    if InCombatLockdown() then
        print("|cffff0000MidnightBindings: Cannot change bindings in combat!|r")
        return
    end
    SetBinding("F", "INTERACTTARGET")
    print("|cff00ff00F is now bound to Interact With Target.|r")
end

-- Function to set F to Action Bar 4, Button 7
local function SetFToBar4()
    if InCombatLockdown() then
        print("|cffff0000MidnightBindings: Cannot change bindings in combat!|r")
        return
    end
    SetBinding("F", "MULTIACTIONBAR4BUTTON7")
    print("|cff00ff00F is now bound to Action Bar 4, Button 7.|r")
end

-- Register the Slash Commands
SLASH_SETFTOINTERACT1 = "/SetFToInteract"
SlashCmdList["SETFTOINTERACT"] = SetFToInteract

SLASH_SETFTOBAR41 = "/SetFToBar4"
SlashCmdList["SETFTOBAR4"] = SetFToBar4
