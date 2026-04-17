-- Esc → Optionen → Addons: Mark2Sell (Sprache, Debug, Tastenbelegung)

local ADDON_NAME = "Mark2Sell"
local didRegister = false

local function AddKeybindingRows(layout)
    if not layout or not layout.AddInitializer then
        return
    end
    if not CreateKeybindingEntryInitializer or not C_KeyBindings or not C_KeyBindings.GetBindingIndex then
        return
    end

    local actions = {
        "ITEMMARKER_TOGGLE_MARK",
        "ITEMMARKER_CLEAR_ALL",
        "ITEMMARKER_SHOW_LIST",
    }

    for _, action in ipairs(actions) do
        local idx = C_KeyBindings.GetBindingIndex(action)
        if idx then
            local init = CreateKeybindingEntryInitializer(idx, false)
            if action == "ITEMMARKER_SHOW_LIST" and init.AddShownPredicate then
                init:AddShownPredicate(function()
                    ItemMarkerDB = ItemMarkerDB or {}
                    return ItemMarkerDB.debugMode == true
                end)
            end
            layout:AddInitializer(init)
        end
    end
end

local function GetLocaleDropdownOptions()
    local container = Settings.CreateControlTextContainer()
    container:Add("auto", ItemMarker:L("SETTINGS_LANG_AUTO"))
    container:Add("de", ItemMarker:L("SETTINGS_LANG_DE"))
    container:Add("en", ItemMarker:L("SETTINGS_LANG_EN"))
    return container:GetData()
end

local function InitOptions()
    if didRegister then
        return
    end
    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        return
    end

    ItemMarkerDB = ItemMarkerDB or {}

    local category, layout = Settings.RegisterVerticalLayoutCategory("Mark2Sell")

    -- RegisterAddOnSetting darf keinen Funktions-„name“ über Secure Attributes; sonst schlägt
    -- die Setting-Erzeugung fehl und es wird fälschlich die Category zurückgegeben.
    local function GetLocalePreference()
        ItemMarkerDB = ItemMarkerDB or {}
        local v = ItemMarkerDB.localePreference
        if v == "de" or v == "en" or v == "auto" then
            return v
        end
        return "auto"
    end

    local function SetLocalePreference(value)
        ItemMarkerDB = ItemMarkerDB or {}
        ItemMarkerDB.localePreference = value
        ItemMarker:RefreshLocaleGlobals()
    end

    local localeSetting = Settings.RegisterProxySetting(
        category,
        "MARK2SELL_LOCALE",
        Settings.VarType.String,
        function()
            return ItemMarker:L("SETTINGS_LANGUAGE")
        end,
        "auto",
        GetLocalePreference,
        SetLocalePreference
    )

    Settings.CreateDropdown(
        category,
        localeSetting,
        GetLocaleDropdownOptions,
        function()
            return ItemMarker:L("SETTINGS_LANGUAGE_TOOLTIP")
        end
    )

    if CreateSettingsButtonInitializer then
        layout:AddInitializer(CreateSettingsButtonInitializer(
            ItemMarker:L("SETTINGS_SETUP_RUN_NAME"),
            ItemMarker:L("SETTINGS_SETUP_RUN_BUTTON"),
            function()
                ItemMarker:OpenSetupWizard()
            end,
            ItemMarker:L("SETTINGS_SETUP_RUN_TOOLTIP"),
            false,
            nil,
            nil
        ))
    end

    local debugSetting = Settings.RegisterAddOnSetting(
        category,
        "MARK2SELL_DEBUG_MODE",
        "debugMode",
        ItemMarkerDB,
        Settings.VarType.Boolean,
        ItemMarker:L("SETTINGS_DEBUG"),
        Settings.Default.False
    )

    Settings.CreateCheckbox(
        category,
        debugSetting,
        ItemMarker:L("SETTINGS_DEBUG_TOOLTIP")
    )

    local function RefreshClearMarksLayout()
        if ItemMarker.RefreshBagClearMarksButton then
            ItemMarker:RefreshBagClearMarksButton()
        end
    end

    local clearOffX = Settings.RegisterAddOnSetting(
        category,
        "MARK2SELL_CLEAR_BTN_OFF_X",
        "clearBtnOffsetX",
        ItemMarkerDB,
        Settings.VarType.Number,
        ItemMarker:L("SETTINGS_CLEAR_BTN_OFFSET_X"),
        0
    )
    clearOffX:SetValueChangedCallback(RefreshClearMarksLayout)

    local clearOffY = Settings.RegisterAddOnSetting(
        category,
        "MARK2SELL_CLEAR_BTN_OFF_Y",
        "clearBtnOffsetY",
        ItemMarkerDB,
        Settings.VarType.Number,
        ItemMarker:L("SETTINGS_CLEAR_BTN_OFFSET_Y"),
        0
    )
    clearOffY:SetValueChangedCallback(RefreshClearMarksLayout)

    local sliderMin, sliderMax, sliderStep = -150, 150, 1
    local function MakeClearOffsetSliderOptions()
        local o = Settings.CreateSliderOptions(sliderMin, sliderMax, sliderStep)
        if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
            o:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
                return tostring(math.floor((value or 0) + 0.5))
            end)
        end
        return o
    end
    local clearTooltip = ItemMarker:L("SETTINGS_CLEAR_BTN_OFFSET_TOOLTIP")
    Settings.CreateSlider(category, clearOffX, MakeClearOffsetSliderOptions(), clearTooltip)
    Settings.CreateSlider(category, clearOffY, MakeClearOffsetSliderOptions(), clearTooltip)

    AddKeybindingRows(layout)

    Settings.RegisterAddOnCategory(category)
    didRegister = true
end

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
    EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, InitOptions)
else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(_, _, name)
        if name == ADDON_NAME then
            InitOptions()
        end
    end)
end

local retryFrame = CreateFrame("Frame")
retryFrame:RegisterEvent("PLAYER_LOGIN")
retryFrame:SetScript("OnEvent", function()
    InitOptions()
end)
