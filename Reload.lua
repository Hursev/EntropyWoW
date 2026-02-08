--[[
    Copyright (C) 2026 Entropy
    License: GNU v3. See LICENSE file and <https://www.gnu.org/licenses/>
    
File Description:
    Adds Slash commands for Reload UI:
        /reload
        /reloadui
        /rl
]]


-- globals for bindings
_G.BINDING_NAME_ENTROPY_RELOADUI = "|cffff8822[Reload]|r Reload UI";

-- slash commands
SlashCmdList["ENTROPY_RELOADUI"] = function()
    ENTROPY_RELOADUI();
end
SLASH_ENTROPY_RELOADUI1 = "/reload";
SLASH_ENTROPY_RELOADUI2 = "/reloadui";
SLASH_ENTROPY_RELOADUI3 = "/rl";

function ENTROPY_RELOADUI()
	ReloadUI();
end
