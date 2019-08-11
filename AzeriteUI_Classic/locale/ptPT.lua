local ADDON = ...
local L = CogWheel("LibLocale"):NewLocale(ADDON, "ptPT")
if (not L) then 
	return 
end 

-- No, we don't want this. 
ADDON = ADDON:gsub("_Classic", "")
