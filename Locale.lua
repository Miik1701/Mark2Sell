-- Lokalisierung: Auto = Spielsprache (nur de/en unterstützt, sonst en).

ItemMarker = ItemMarker or {}

local STRINGS = {
    en = {
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
        SETTINGS_LANGUAGE_TOOLTIP = "Addon language. Automatic uses WoW client language (German or English); other clients use English.",
        SETTINGS_LANG_AUTO = "Automatic (game language)",
        SETTINGS_LANG_DE = "Deutsch",
        SETTINGS_LANG_EN = "English",

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
    },
    de = {
        BINDING_HEADER = "Mark2Sell",
        BINDING_TOGGLE = "Item markieren / Markierung entfernen (Maus über Taschen-Slot)",
        BINDING_CLEAR = "Alle Markierungen löschen",
        BINDING_LIST = "Markierte Items auflisten (nur bei aktivem Debug-Modus)",

        MSG_NO_ITEM_SLOT = "Kein Item in diesem Slot.",
        MSG_MARK_REMOVED = "Markierung entfernt.",
        MSG_NO_VENDOR_VALUE = "Kein Händlerwert - Gegenstand kann nicht zum Verkauf markiert werden.",
        MSG_MARKED_FOR_SELL = "Zum Verkauf markiert.",
        MSG_NO_BAG_ITEM_CURSOR = "Kein Taschen-Item unter dem Mauszeiger.",
        MSG_ALL_MARKS_CLEARED = "Alle Markierungen gelöscht.",
        MSG_NO_MARKED = "Keine markierten Items.",
        MSG_MARKED_LIST_HEADER = "Markierte Items (%d):",
        MSG_ALL_SOLD = "Alle markierten Items wurden verkauft.",
        MSG_SELL_STALL = "Verkauf gestoppt: Ein Item ließ sich nicht verkaufen (gesperrt oder nicht verkaufbar).",
        MSG_NO_SELLABLE_MARKED = "Keine markierten, verkaufbaren Items in den Taschen.",

        TOOLTIP_MERCHANT_TITLE = "Mark2Sell",
        TOOLTIP_MERCHANT_DESC = "Verkauft alle in den Taschen markierten Gegenstände an diesen Händler.",
        TOOLTIP_MERCHANT_COUNT = "Verkaufbar markiert: %d",
        TOOLTIP_MERCHANT_HINT_ZERO = "Zum Aktivieren Items in den Taschen markieren.",

        BTN_CLEAR_MARKS_TITLE = "Markierungen löschen",
        BTN_CLEAR_MARKS_DESC = "Entfernt alle Mark2Sell-Verkaufsmarkierungen in den Taschen (verkauft nichts).",

        SETTINGS_DEBUG = "Debug-Modus",
        SETTINGS_DEBUG_TOOLTIP = "Zeigt zusätzliche Info-Meldungen im Chat (z. B. markiert, verkauft, Liste). Hinweise und Warnungen bei Problemen erscheinen weiterhin immer.",
        SETTINGS_LANGUAGE = "Sprache",
        SETTINGS_LANGUAGE_TOOLTIP = "Sprache des Addons. „Automatisch“ nutzt die WoW-Client-Sprache (Deutsch oder Englisch); andere Clients nutzen Englisch.",
        SETTINGS_LANG_AUTO = "Automatisch (Spielsprache)",
        SETTINGS_LANG_DE = "Deutsch",
        SETTINGS_LANG_EN = "English",

        SETTINGS_CLEAR_BTN_OFFSET_X = "Button «Markierungen löschen»: horizontal",
        SETTINGS_CLEAR_BTN_OFFSET_Y = "Button «Markierungen löschen»: vertikal",
        SETTINGS_CLEAR_BTN_OFFSET_TOOLTIP = "Verschiebt den Button zum Löschen der Markierungen relativ zur Standardposition (links vom Taschen-Suchfeld). Wirkt sofort; Taschen öffnen zum Ansehen.",

        SETTINGS_SETUP_RUN_NAME = "Einrichtungsassistent",
        SETTINGS_SETUP_RUN_BUTTON = "Einrichtung öffnen…",
        SETTINGS_SETUP_RUN_TOOLTIP = "Öffnet das Mark2Sell-Setup: Tastenbelegung und Position des Löschen-Buttons. Jederzeit wiederholbar.",

        SETUP_WIZARD_TITLE = "Mark2Sell - Einrichtung",
        SETUP_WIZARD_BODY = "1) Unten ein Tastenfeld anklicken, dann die gewünschte Taste drücken (Esc bricht ab). Rechtsklick auf ein Feld entfernt die Belegung.\n\n2) Taschen öffnen und die Regler weiter unten verschieben, bis der rote Löschen-Button passt (Standard: links vom Suchfeld).\n\n3) Mit «Fertig» abschließen. «Später» schließt nur das Fenster; beim nächsten Login erscheint die Einrichtung erneut, bis du «Fertig» wählst.",
        SETUP_WIZARD_KEYBIND_HEADER = "Tastenbelegung",
        SETUP_WIZARD_POSITION_HEADER = "Position: Markierungen löschen (siehe Inventar)",
        SETUP_WIZARD_DONE = "Fertig",
        SETUP_WIZARD_LATER = "Später",

        LOG_INFO = "INFO",
        LOG_WARNING = "WARNING",
        LOG_ERROR = "ERROR",
    },
}

function ItemMarker:GetEffectiveLocaleKey()
    ItemMarkerDB = ItemMarkerDB or {}
    local pref = ItemMarkerDB.localePreference
    if pref == "de" or pref == "en" then
        return pref
    end
    local game = GetLocale and GetLocale() or "enUS"
    if game == "deDE" then
        return "de"
    end
    return "en"
end

function ItemMarker:L(key)
    local lang = self:GetEffectiveLocaleKey()
    local pack = STRINGS[lang] or STRINGS.en
    local s = pack[key]
    if s then
        return s
    end
    return STRINGS.en[key] or key
end

function ItemMarker:LF(key, ...)
    return string.format(self:L(key), ...)
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

ItemMarker:RefreshLocaleGlobals()
