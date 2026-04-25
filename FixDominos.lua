-- For some reason Dominos re-enables the spell animation on buttons after reload
-- So we call its function to disable that shortly after login.
-- The user can also do that manually by typing /fixbuttons

function FixDominosButtonAnimation()
    if Dominos and Dominos.ActionButtons and Dominos.ActionButtons.SetShowSpellAnimations then
        print("|cFFFF0000[Fix Dominos]|r Call Dominos.ActionButtons:SetShowSpellAnimations(false)")
        Dominos.ActionButtons:SetShowSpellAnimations(false)
    else
        if not Dominos then 
            print("|cFFFF0000[Fix Dominos]|r Dominos nil: " .. tostring((Dominos == nil)))
        elseif not Dominos.ActionButtons then 
            print("|cFFFF0000[Fix Dominos]|r Dominos ActionButtons nil: " .. tostring((Dominos.ActionButtons == nil)))
        elseif not Dominos.ActionButtons.SetShowSpellAnimations then
            print("|cFFFF0000[Fix Dominos]|r Dominos.ActionButtons.SetShowSpellAnimations nil: " .. tostring((Dominos.ActionButtons.SetShowSpellAnimations == nil)))
        end
    end
end

SLASH_FIXBUTTONS1 = "/fixbuttons"
SlashCmdList["FIXBUTTONS"] = FixDominosButtonAnimation
--function()
--end
    
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    C_Timer.After(5, function()
        FixDominosButtonAnimation()
    end)
end)
