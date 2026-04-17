-- Ersteinrichtung: Tastenbelegung + Position des Clear-Buttons (erneut über Addon-Optionen).

local SLIDER_MIN, SLIDER_MAX, SLIDER_STEPS = -150, 150, 300

local KEYBIND_ACTIONS = {
    "ITEMMARKER_TOGGLE_MARK",
    "ITEMMARKER_CLEAR_ALL",
}

local win
local sliderXFrame, sliderYFrame
local updatingSliders
local ui = {
    keybindRows = {},
}

local keybindSelectionClearers = {}
local keybindHookOwner = {}
local keybindHooksRegistered

local function SafeSaveBindings()
    pcall(function()
        SaveBindings(GetCurrentBindingSet())
    end)
end

local function ClearWizardKeybindVisualSelection()
    for _, clear in ipairs(keybindSelectionClearers) do
        clear()
    end
end

local function OnKeybindSessionFinished()
    SafeSaveBindings()
    ClearWizardKeybindVisualSelection()
end

local function EnsureSaveBindingsHooks()
    if keybindHooksRegistered or not EventRegistry or not EventRegistry.RegisterCallback then
        return
    end
    keybindHooksRegistered = true
    EventRegistry:RegisterCallback("KeybindListener.RebindSuccess", OnKeybindSessionFinished, keybindHookOwner)
    EventRegistry:RegisterCallback("KeybindListener.StoppedListening", OnKeybindSessionFinished, keybindHookOwner)
    EventRegistry:RegisterCallback("KeybindListener.RebindFailed", OnKeybindSessionFinished, keybindHookOwner)
    EventRegistry:RegisterCallback("KeybindListener.UnbindFailed", OnKeybindSessionFinished, keybindHookOwner)
end

local function EnsureBlizzardKeybindUILoaded()
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(function()
            C_AddOns.LoadAddOn("Blizzard_Settings")
        end)
    end
end

local function NormalizeOffset(n)
    if type(n) ~= "number" then
        return 0
    end
    if n < SLIDER_MIN then
        return SLIDER_MIN
    end
    if n > SLIDER_MAX then
        return SLIDER_MAX
    end
    return math.floor(n + 0.5)
end

local function GetOffsets()
    ItemMarkerDB = ItemMarkerDB or {}
    return NormalizeOffset(ItemMarkerDB.clearBtnOffsetX), NormalizeOffset(ItemMarkerDB.clearBtnOffsetY)
end

local function ApplyOffsets(x, y)
    ItemMarkerDB = ItemMarkerDB or {}
    ItemMarkerDB.clearBtnOffsetX = x
    ItemMarkerDB.clearBtnOffsetY = y
    if ItemMarker.RefreshBagClearMarksButton then
        ItemMarker:RefreshBagClearMarksButton()
    end
    if Settings and Settings.NotifyUpdate then
        Settings.NotifyUpdate("MARK2SELL_CLEAR_BTN_OFF_X")
        Settings.NotifyUpdate("MARK2SELL_CLEAR_BTN_OFF_Y")
    end
end

local function GetWizardLocaleValue()
    ItemMarkerDB = ItemMarkerDB or {}
    local v = ItemMarkerDB.localePreference
    if v == "de" or v == "en" or v == "auto" then
        return v
    end
    return "auto"
end

local function GetLocaleChoiceLabel(value)
    if value == "auto" then
        return ItemMarker:L("SETTINGS_LANG_AUTO")
    end
    if value == "de" then
        return ItemMarker:L("SETTINGS_LANG_DE")
    end
    return ItemMarker:L("SETTINGS_LANG_EN")
end

local function RefreshKeybindRowLabels()
    for _, row in ipairs(ui.keybindRows) do
        if row._bindingLabel and row._bindingAction then
            row._bindingLabel:SetText(GetBindingName(row._bindingAction))
        end
    end
end

local function SyncSlidersFromDB()
    if not sliderXFrame or not sliderYFrame then
        return
    end
    updatingSliders = true
    local x, y = GetOffsets()
    sliderXFrame:SetValue(x)
    sliderYFrame:SetValue(y)
    updatingSliders = false
end

local function RefreshLangDropdownDisplay()
    if ui.langDropdown and UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(ui.langDropdown, GetLocaleChoiceLabel(GetWizardLocaleValue()))
    end
end

local function RefreshWizardTexts()
    if not win then
        return
    end
    ui.title:SetText(ItemMarker:L("SETUP_WIZARD_TITLE"))
    ui.body:SetText(ItemMarker:L("SETUP_WIZARD_BODY"))
    if ui.langHeader then
        ui.langHeader:SetText(ItemMarker:L("SETTINGS_LANGUAGE"))
    end
    if ui.keybindHeader then
        ui.keybindHeader:SetText(ItemMarker:L("SETUP_WIZARD_KEYBIND_HEADER"))
    end
    ui.posHeader:SetText(ItemMarker:L("SETUP_WIZARD_POSITION_HEADER"))
    ui.xLabel:SetText(ItemMarker:L("SETTINGS_CLEAR_BTN_OFFSET_X"))
    ui.yLabel:SetText(ItemMarker:L("SETTINGS_CLEAR_BTN_OFFSET_Y"))
    ui.doneBtn:SetText(ItemMarker:L("SETUP_WIZARD_DONE"))
    ui.laterBtn:SetText(ItemMarker:L("SETUP_WIZARD_LATER"))
    RefreshLangDropdownDisplay()
    if ui.langPickFb then
        for _, val in ipairs({ "auto", "de", "en" }) do
            local btn = ui.langPickFb[val]
            if btn then
                btn:SetText(GetLocaleChoiceLabel(val))
                btn:SetAlpha(GetWizardLocaleValue() == val and 1 or 0.55)
            end
        end
    end
    RefreshKeybindRowLabels()
end

local function ApplyWizardLocalePreference(value)
    ItemMarkerDB = ItemMarkerDB or {}
    ItemMarkerDB.localePreference = value
    ItemMarker:RefreshLocaleGlobals()
    if Settings and Settings.NotifyUpdate then
        Settings.NotifyUpdate("MARK2SELL_LOCALE")
    end
    RefreshWizardTexts()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

local function Mark2Sell_LangDropInit(_, level)
    if level and level > 1 then
        return
    end
    local cur = GetWizardLocaleValue()
    for _, val in ipairs({ "auto", "de", "en" }) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = GetLocaleChoiceLabel(val)
        info.value = val
        info.checked = (cur == val)
        info.func = function()
            ApplyWizardLocalePreference(val)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info)
    end
end

local function CreateWizardKeybindRow(parent, relFrame, relPoint, ox, oy, bindingIndex)
    local action = select(1, GetBinding(bindingIndex))
    if not action or action == "" then
        return nil
    end

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(500, 28)
    row:SetPoint("TOPLEFT", relFrame, relPoint, ox, oy)

    local lbl = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", row, "LEFT", 4, 0)
    lbl:SetWidth(200)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(GetBindingName(action))
    row._bindingLabel = lbl
    row._bindingAction = action

    local initializer = {
        data = { bindingIndex = bindingIndex, search = false },
        selectedIndex = nil,
    }

    local btn1 = CreateFrame("Button", nil, row, "KeyBindingFrameBindingButtonTemplate")
    btn1:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
    local btn2 = CreateFrame("Button", nil, row, "KeyBindingFrameBindingButtonTemplate")
    btn2:SetPoint("LEFT", btn1, "RIGHT", 4, 0)
    local buttons = { btn1, btn2 }

    local function ClearSelections()
        initializer.selectedIndex = nil
        for _, b in ipairs(buttons) do
            b:SetSelected(false)
        end
    end

    local function RefreshState()
        local ctx = C_KeyBindings.GetBindingContextForAction(action)
        local key1, key2 = GetBindingKey(action, nil, ctx)
        for _, b in ipairs(buttons) do
            local fs = b.Text or b.GetFontString and b:GetFontString()
            if fs then
                fs:SetText("")
            end
        end
        BindingButtonTemplate_SetupBindingButton(key1, btn1)
        BindingButtonTemplate_SetupBindingButton(key2, btn2)
        for i, b in ipairs(buttons) do
            b:SetSelected(initializer.selectedIndex == i)
        end
    end

    for index, button in ipairs(buttons) do
        button:SetScript("OnClick", function(b, buttonName, down)
            if buttonName == "LeftButton" then
                local oldSelected = initializer.selectedIndex == index
                KeybindListener:StopListening()
                if not oldSelected then
                    initializer.selectedIndex = index
                    for i, bt in ipairs(buttons) do
                        bt:SetSelected(i == index)
                    end
                    KeybindListener:StartListening(action, index)
                else
                    ClearSelections()
                end
            elseif buttonName == "RightButton" then
                KeybindListener:StopListening()
                ClearSelections()
                local ctx = C_KeyBindings.GetBindingContextForAction(action)
                local unbindKey = select(index, GetBindingKey(action, nil, ctx))
                if unbindKey then
                    SetBinding(unbindKey, nil, ctx)
                    SafeSaveBindings()
                end
                RefreshState()
            end
        end)

        if button.SetTooltipFunc then
            button:SetTooltipFunc(function()
                local bindingName = GetBindingName(action)
                local ctx = C_KeyBindings.GetBindingContextForAction(action)
                local key = select(index, GetBindingKey(action, nil, ctx))
                if Settings and Settings.InitTooltip and KEY_BINDING_NAME_AND_KEY and key then
                    Settings.InitTooltip(KEY_BINDING_NAME_AND_KEY:format(bindingName, GetBindingText(key)), KEY_BINDING_TOOLTIP)
                elseif Settings and Settings.InitTooltip then
                    Settings.InitTooltip(bindingName, KEY_BINDING_TOOLTIP)
                end
            end)
        end
        if button.SetCustomTooltipAnchoring then
            button:SetCustomTooltipAnchoring(button, "ANCHOR_RIGHT", 0, 0)
        end
    end

    row:RegisterEvent("UPDATE_BINDINGS")
    row:SetScript("OnEvent", RefreshState)
    RefreshState()

    tinsert(keybindSelectionClearers, ClearSelections)
    tinsert(ui.keybindRows, row)

    return row
end

local function MakeOffsetSliderRow(parent, rel, relPoint, ox, oy, labelKey, initial, onCommit)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", rel, relPoint, ox, oy)
    label:SetWidth(400)
    label:SetJustifyH("LEFT")
    label:SetText(ItemMarker:L(labelKey))

    local s = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    s:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -10)
    s:SetWidth(320)

    local formatters = {
        [MinimalSliderWithSteppersMixin.Label.Right] = function(v)
            return tostring(math.floor((v or 0) + 0.5))
        end,
    }
    s:Init(initial, SLIDER_MIN, SLIDER_MAX, SLIDER_STEPS, formatters)

    s:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if updatingSliders then
            return
        end
        onCommit(NormalizeOffset(value))
    end)

    return s, label
end

local function EnsureWindow()
    if win then
        return
    end

    EnsureBlizzardKeybindUILoaded()
    EnsureSaveBindingsHooks()

    win = CreateFrame("Frame", "Mark2SellSetupWizard", UIParent, "BackdropTemplate")
    win:SetSize(540, 600)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    win:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    win:SetBackdropColor(0, 0, 0, 0.92)

    win:SetScript("OnHide", function()
        KeybindListener:StopListening()
        ClearWizardKeybindVisualSelection()
        SafeSaveBindings()
    end)

    tinsert(UISpecialFrames, win:GetName())

    ui.title = win:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ui.title:SetPoint("TOP", 0, -18)

    ui.body = win:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    ui.body:SetPoint("TOPLEFT", 24, -52)
    ui.body:SetPoint("TOPRIGHT", -24, -52)
    ui.body:SetJustifyH("LEFT")
    ui.body:SetSpacing(4)

    ui.langHeader = win:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ui.langHeader:SetPoint("TOPLEFT", ui.body, "BOTTOMLEFT", 0, -14)

    if UIDropDownMenu_Initialize and UIDropDownMenu_CreateInfo and UIDropDownMenu_AddButton and UIDropDownMenu_SetWidth then
        ui.langDropdown = CreateFrame("Frame", "Mark2SellWizardLangDrop", win, "UIDropDownMenuTemplate")
        ui.langDropdown:SetPoint("TOPLEFT", ui.langHeader, "BOTTOMLEFT", -14, -4)
        UIDropDownMenu_SetWidth(ui.langDropdown, 300)
        UIDropDownMenu_Initialize(ui.langDropdown, Mark2Sell_LangDropInit)
        UIDropDownMenu_SetText(ui.langDropdown, GetLocaleChoiceLabel(GetWizardLocaleValue()))

        local dropBtn = _G["Mark2SellWizardLangDropButton"]
        if dropBtn then
            dropBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(ItemMarker:L("SETTINGS_LANGUAGE_TOOLTIP"), 1, 1, 1)
                GameTooltip:Show()
            end)
            dropBtn:SetScript("OnLeave", GameTooltip_Hide)
        end
    else
        ui.langPickFb = {}
        local gap = 6
        local firstBtn
        local prevBtn
        for i, val in ipairs({ "auto", "de", "en" }) do
            local b = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
            b:SetSize(100, 24)
            b:SetScript("OnClick", function()
                ApplyWizardLocalePreference(val)
            end)
            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(ItemMarker:L("SETTINGS_LANGUAGE_TOOLTIP"), 1, 1, 1)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", GameTooltip_Hide)
            if i == 1 then
                b:SetPoint("TOPLEFT", ui.langHeader, "BOTTOMLEFT", 0, -8)
                firstBtn = b
            else
                b:SetPoint("LEFT", prevBtn, "RIGHT", gap, 0)
            end
            ui.langPickFb[val] = b
            prevBtn = b
        end
        ui.langAnchorBelowLang = firstBtn
    end

    ui.keybindHeader = win:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    if ui.langDropdown then
        ui.keybindHeader:SetPoint("TOPLEFT", ui.langDropdown, "BOTTOMLEFT", 14, -14)
    elseif ui.langAnchorBelowLang then
        ui.keybindHeader:SetPoint("TOPLEFT", ui.langAnchorBelowLang, "BOTTOMLEFT", 0, -14)
    else
        ui.keybindHeader:SetPoint("TOPLEFT", ui.langHeader, "BOTTOMLEFT", 0, -36)
    end

    wipe(ui.keybindRows)
    local lastAnchor = ui.keybindHeader
    local anchorPoint = "BOTTOMLEFT"
    local yOff = -6

    if C_KeyBindings and C_KeyBindings.GetBindingIndex and KeybindListener and CreateFrame then
        for _, actionName in ipairs(KEYBIND_ACTIONS) do
            local idx = C_KeyBindings.GetBindingIndex(actionName)
            if idx then
                local row = CreateWizardKeybindRow(win, lastAnchor, anchorPoint, 0, yOff, idx)
                if row then
                    lastAnchor = row
                    anchorPoint = "BOTTOMLEFT"
                    yOff = -4
                end
            end
        end
    end

    ui.posHeader = win:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ui.posHeader:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -16)

    local x0, y0 = GetOffsets()
    sliderXFrame, ui.xLabel = MakeOffsetSliderRow(win, ui.posHeader, "BOTTOMLEFT", 0, -8, "SETTINGS_CLEAR_BTN_OFFSET_X", x0, function(v)
        local _, y = GetOffsets()
        ApplyOffsets(v, y)
    end)

    sliderYFrame, ui.yLabel = MakeOffsetSliderRow(win, sliderXFrame, "BOTTOMLEFT", 0, -36, "SETTINGS_CLEAR_BTN_OFFSET_Y", y0, function(v)
        local x = select(1, GetOffsets())
        ApplyOffsets(x, v)
    end)

    ui.laterBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    ui.laterBtn:SetSize(120, 28)
    ui.laterBtn:SetPoint("BOTTOMRIGHT", -24, 24)
    ui.laterBtn:SetScript("OnClick", function()
        SafeSaveBindings()
        win:Hide()
        PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT)
    end)

    ui.doneBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    ui.doneBtn:SetSize(120, 28)
    ui.doneBtn:SetPoint("RIGHT", ui.laterBtn, "LEFT", -12, 0)
    ui.doneBtn:SetScript("OnClick", function()
        ItemMarkerDB = ItemMarkerDB or {}
        ItemMarkerDB.setupWizardCompleted = true
        SafeSaveBindings()
        win:Hide()
        PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK)
    end)

    RefreshWizardTexts()
end

function ItemMarker:OpenSetupWizard()
    EnsureWindow()
    RefreshWizardTexts()
    SyncSlidersFromDB()
    win:Show()
    win:Raise()
end

function ItemMarker:ShouldOfferFirstTimeSetup()
    ItemMarkerDB = ItemMarkerDB or {}
    return ItemMarkerDB.setupWizardCompleted ~= true
end

local function MigrateSetupWizardForExistingProfiles()
    ItemMarkerDB = ItemMarkerDB or {}
    if ItemMarkerDB._mark2sellSetupIntro ~= nil then
        return
    end
    ItemMarkerDB._mark2sellSetupIntro = 1
    local marked = ItemMarkerDB.marked
    local hasMarks = type(marked) == "table" and next(marked) ~= nil
    local hasPriorUse = hasMarks
        or ItemMarkerDB.debugMode == true
        or (type(ItemMarkerDB.clearBtnOffsetX) == "number" and ItemMarkerDB.clearBtnOffsetX ~= 0)
        or (type(ItemMarkerDB.clearBtnOffsetY) == "number" and ItemMarkerDB.clearBtnOffsetY ~= 0)
        or (ItemMarkerDB.localePreference ~= nil and ItemMarkerDB.localePreference ~= "auto")
    if hasPriorUse and ItemMarkerDB.setupWizardCompleted == nil then
        ItemMarkerDB.setupWizardCompleted = true
    end
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function()
    MigrateSetupWizardForExistingProfiles()
    if not ItemMarker:ShouldOfferFirstTimeSetup() then
        return
    end
    C_Timer.After(1.5, function()
        if ItemMarker:ShouldOfferFirstTimeSetup() and not (win and win:IsShown()) then
            ItemMarker:OpenSetupWizard()
        end
    end)
end)

SLASH_MARK2SELL1 = "/m2s"
SlashCmdList["MARK2SELL"] = function()
    ItemMarker:OpenSetupWizard()
end
