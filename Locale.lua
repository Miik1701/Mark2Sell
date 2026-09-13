-- Lokalisierung: Englisch ist eingebaut; weitere Sprachen kommen aus optionalen Language-Pack-Addons.
--
-- Language-Pack-API:
--   ItemMarker:RegisterLocale(locale, displayName, strings)
--   ItemMarker:GetRegisteredLocales()
--
-- Ein Language-Pack ist ein eigenständiges WoW-Addon mit "## Dependencies: Mark2Sell",
-- das einmal RegisterLocale aufruft. Fehlende Keys fallen automatisch auf Englisch zurück.
-- Beispiel-Pack: siehe Addon Mark2Sell_deDE.

ItemMarker = ItemMarker or {}

local DEFAULT_LOCALE = "enUS"

local EN_STRINGS = {
    BINDING_HEADER = "Mark2Sell",
    BINDING_TOGGLE = "Toggle mark on bag item under cursor",
    BINDING_CLEAR = "Clear all marks",
    BINDING_LIST = "List marked items in chat (debug mode only)",

    MSG_NO_ITEM_SLOT = "No item in this slot.",
    MSG_MARK_REMOVED = "Mark removed.",
    MSG_NO_VENDOR_VALUE = "No vendor price - item cannot be marked for sale.",
    MSG_MARKED_FOR_SELL = "Marked for sale.",
    MSG_NO_BAG_ITEM_CURSOR = "No bag item under the cursor.",
    MSG_ALL_MARKS_CLEARED = "All marks cleared.",
    MSG_NO_MARKED = "No marked items.",
    MSG_MARKED_LIST_HEADER = "Marked items (%d):",
    MSG_ALL_SOLD = "All marked items were sold.",
    MSG_SELL_STALL = "Selling stopped: an item could not be sold (locked or not sellable).",
    MSG_NO_SELLABLE_MARKED = "No marked, sellable items in bags.",

    TOOLTIP_MERCHANT_TITLE = "Mark2Sell",
    TOOLTIP_MERCHANT_DESC = "Sells all marked bag items to this merchant.",
    TOOLTIP_MERCHANT_COUNT = "Marked and sellable: %d",
    TOOLTIP_MERCHANT_HINT_ZERO = "Mark items in your bags to use this.",

    BTN_CLEAR_MARKS_TITLE = "Clear marks",
    BTN_CLEAR_MARKS_DESC = "Removes all Mark2Sell sale marks from bags (does not sell).",

    SETTINGS_DEBUG = "Debug mode",
    SETTINGS_DEBUG_TOOLTIP = "Shows extra info messages in chat (e.g. marked, sold, list). Problem hints and warnings still always appear.",
    SETTINGS_LANGUAGE = "Language",
    SETTINGS_LANGUAGE_TOOLTIP = "Addon language. Automatic uses the WoW client language when a matching language pack is installed; otherwise the addon falls back to English.",
    SETTINGS_LANG_AUTO = "Automatic (game language)",

    SETTINGS_CLEAR_BTN_OFFSET_X = "Clear-marks button: horizontal offset",
    SETTINGS_CLEAR_BTN_OFFSET_Y = "Clear-marks button: vertical offset",
    SETTINGS_CLEAR_BTN_OFFSET_TOOLTIP = "Moves the bag bar «clear marks» button relative to the default spot (to the left of the search box). Changes apply immediately; open your bags to preview.",

    SETTINGS_SETUP_RUN_NAME = "Setup wizard",
    SETTINGS_SETUP_RUN_BUTTON = "Open setup…",
    SETTINGS_SETUP_RUN_TOOLTIP = "Opens the Mark2Sell setup window: assign keybinds and adjust the clear-marks button. You can run this anytime.",

    SETUP_WIZARD_TITLE = "Mark2Sell - Setup",
    SETUP_WIZARD_BODY = "1) Click a key field below, then press the key you want (Esc cancels). Right-click a field to unbind.\n\n2) Open your bags and use the sliders further down to move the red clear-marks button (default: left of the search box).\n\n3) Click «Done» when finished. «Later» closes this window; it will appear again on the next login until you click «Done».",
    SETUP_WIZARD_KEYBIND_HEADER = "Key bindings",
    SETUP_WIZARD_POSITION_HEADER = "Clear-marks button position (see inventory)",
    SETUP_WIZARD_DONE = "Done",
    SETUP_WIZARD_LATER = "Later",

    LOG_INFO = "INFO",
    LOG_WARNING = "WARNING",
    LOG_ERROR = "ERROR",
}

-- Registry: [localeCode] = { name = "English", strings = {...} }
-- localeOrder: enUS zuerst, danach in Registrierungsreihenfolge.
local locales = {}
local localeOrder = {}

local function IsLocaleRegistered(locale)
    return type(locale) == "string" and locales[locale] ~= nil
end

local function AddToOrder(locale)
    for _, existing in ipairs(localeOrder) do
        if existing == locale then
            return
        end
    end
    table.insert(localeOrder, locale)
end

function ItemMarker:RefreshLocaleGlobals()
    BINDING_HEADER_MARK2SELL = self:L("BINDING_HEADER")
    BINDING_NAME_ITEMMARKER_TOGGLE_MARK = self:L("BINDING_TOGGLE")
    BINDING_NAME_ITEMMARKER_CLEAR_ALL = self:L("BINDING_CLEAR")
    BINDING_NAME_ITEMMARKER_SHOW_LIST = self:L("BINDING_LIST")
    if SettingsPanel and SettingsPanel.RepairDisplay then
        SettingsPanel:RepairDisplay()
    end
end

-- Migriert alte Präferenzen ("de" / "en") auf die neuen WoW-Locale-Codes.
local function MigrateLegacyLocalePreference()
    ItemMarkerDB = ItemMarkerDB or {}
    local pref = ItemMarkerDB.localePreference
    if pref == "de" then
        ItemMarkerDB.localePreference = "deDE"
    elseif pref == "en" then
        ItemMarkerDB.localePreference = "enUS"
    end
end

function ItemMarker:GetEffectiveLocaleKey()
    MigrateLegacyLocalePreference()
    ItemMarkerDB = ItemMarkerDB or {}
    local pref = ItemMarkerDB.localePreference
    if pref and pref ~= "auto" and IsLocaleRegistered(pref) then
        return pref
    end
    -- Automatik: Client-Sprache, wenn ein passendes Pack geladen ist, sonst Englisch.
    local game = GetLocale and GetLocale() or DEFAULT_LOCALE
    if IsLocaleRegistered(game) then
        return game
    end
    return DEFAULT_LOCALE
end

function ItemMarker:L(key)
    local lang = self:GetEffectiveLocaleKey()
    local pack = locales[lang]
    if pack then
        local s = pack.strings[key]
        if s then
            return s
        end
    end
    local en = locales[DEFAULT_LOCALE]
    if en then
        local s = en.strings[key]
        if s then
            return s
        end
    end
    return key
end

function ItemMarker:LF(key, ...)
    return string.format(self:L(key), ...)
end

--- Registers (or replaces) a language pack. Called by Mark2Sell for `enUS` and by
--- community language-pack addons for other locales.
--- @param locale string      WoW locale code, e.g. "deDE", "frFR" (matches GetLocale()).
--- @param displayName string Human-readable name shown in the dropdown, e.g. "Deutsch".
--- @param strings table      String table sharing keys with the English default.
function ItemMarker:RegisterLocale(locale, displayName, strings)
    if type(locale) ~= "string" or locale == "" then
        return
    end
    if type(strings) ~= "table" then
        return
    end
    local name = (type(displayName) == "string" and displayName ~= "") and displayName or locale
    locales[locale] = { name = name, strings = strings }
    AddToOrder(locale)
    -- Bindings- und Settings-Labels neu setzen, falls jetzt (nach Registrierung)
    -- die effektive Sprache wechselt.
    self:RefreshLocaleGlobals()
end

--- Returns an ordered list of registered locales as `{ code = "deDE", name = "Deutsch" }`.
--- The English default (`enUS`) is always first.
function ItemMarker:GetRegisteredLocales()
    local list = {}
    for _, code in ipairs(localeOrder) do
        local entry = locales[code]
        if entry then
            table.insert(list, { code = code, name = entry.name })
        end
    end
    return list
end

-- Englisch immer zuerst registrieren.
ItemMarker:RegisterLocale(DEFAULT_LOCALE, "English", EN_STRINGS)

-- Language Packs, die vor Mark2Sell geladen wurden, tragen sich in dieser globalen
-- Queue ein. Sie wird hier einmal geleert. Danach registrieren Packs direkt.
local function DrainLocaleQueue()
    local queue = Mark2SellLocaleQueue
    if type(queue) ~= "table" then
        return
    end
    for _, entry in ipairs(queue) do
        if type(entry) == "table" then
            ItemMarker:RegisterLocale(entry.locale, entry.name or entry.displayName, entry.strings)
        end
    end
    Mark2SellLocaleQueue = nil
end

DrainLocaleQueue()
