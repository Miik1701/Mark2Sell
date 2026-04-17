-- Logging.lua
ItemMarker = ItemMarker or {}

-- Farben
local COLORS = {
    INFO    = "|cff00ccff",
    WARNING = "|cffffaa00",
    ERROR   = "|cffff5555",
}

local PREFIX = "|cffffff00Mark2Sell:|r "

local function IsDebugLoggingEnabled()
    ItemMarkerDB = ItemMarkerDB or {}
    return ItemMarkerDB.debugMode == true
end

function ItemMarker:IsDebugMode()
    return IsDebugLoggingEnabled()
end

local function Log(level, msg)
    local labelKey = (level == "INFO" and "LOG_INFO")
        or (level == "WARNING" and "LOG_WARNING")
        or "LOG_ERROR"
    print(PREFIX .. COLORS[level] .. ItemMarker:L(labelKey) .. ":|r " .. msg)
end

--- Nur bei aktiviertem Debug-Modus (Optionen → Addons → Mark2Sell).
function ItemMarker:Info(msg)
    if not IsDebugLoggingEnabled() then
        return
    end
    Log("INFO", msg)
end

function ItemMarker:Warning(msg)
    Log("WARNING", msg)
end

function ItemMarker:Error(msg)
    Log("ERROR", msg)
end
