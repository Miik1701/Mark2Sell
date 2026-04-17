-- Händler-Fenster: Button zum Verkaufen aller mit ItemMarker markierten Taschen-Items.

local ADDON_NAME = "Mark2Sell"
local SELL_DELAY_SEC = 0.12
local UPDATE_THROTTLE_SEC = 0.25

local button
local sellActive = false
local lastAttemptSig
local stallCount = 0
local lastButtonUpdateTime = 0
local sellDelayTimer

local function CountSellableMarkedInBags()
    local n = 0
    for bag = Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and not info.isLocked then
                local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                if loc:IsValid() and C_Item.DoesItemExist(loc) then
                    local guid = C_Item.GetItemGUID(loc)
                    if ItemMarker:IsMarkedGUID(guid) then
                        n = n + 1
                    end
                end
            end
        end
    end
    return n
end

local function FindFirstSellableMarked()
    for bag = Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and not info.isLocked then
                local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                if loc:IsValid() and C_Item.DoesItemExist(loc) then
                    local guid = C_Item.GetItemGUID(loc)
                    if ItemMarker:IsMarkedGUID(guid) then
                        return bag, slot, guid
                    end
                end
            end
        end
    end
end

local function CancelSellDelayTimer()
    if sellDelayTimer then
        sellDelayTimer:Cancel()
        sellDelayTimer = nil
    end
end

local function PositionMerchantButton()
    if not button or not MerchantFrame then
        return
    end
    button:ClearAllPoints()
    if MerchantSellAllJunkButton and MerchantSellAllJunkButton:IsShown() then
        button:SetPoint("RIGHT", MerchantSellAllJunkButton, "LEFT", -10, 0)
    elseif MerchantRepairAllButton and MerchantRepairAllButton:IsShown() then
        button:SetPoint("RIGHT", MerchantRepairAllButton, "LEFT", -10, 0)
    else
        button:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -280, 33)
    end
end

local function ApplyButtonLook()
    if not button or not button.Icon then
        return
    end
    local merchantOpen = MerchantFrame and MerchantFrame:IsShown()
    local n = CountSellableMarkedInBags()
    local hasTargets = n > 0

    if sellActive then
        button.Icon:SetDesaturated(true)
        button.Icon:SetVertexColor(0.75, 0.75, 0.75)
        button:SetAlpha(0.75)
    elseif not merchantOpen then
        button.Icon:SetDesaturated(true)
        button.Icon:SetVertexColor(1, 1, 1)
        button:SetAlpha(0.5)
    elseif hasTargets then
        button.Icon:SetDesaturated(false)
        button.Icon:SetVertexColor(1, 0.88, 0.45)
        button:SetAlpha(1)
    else
        -- Händler offen, nichts Verkaufbares: normal farbig (nicht grau), Hinweis nur im Tooltip
        button.Icon:SetDesaturated(false)
        button.Icon:SetVertexColor(1, 1, 1)
        button:SetAlpha(1)
    end
end

local function UpdateButtonState(force)
    if not button or not MerchantFrame then
        return
    end
    if sellActive then
        return
    end
    if not force then
        local t = GetTime()
        if t - lastButtonUpdateTime < UPDATE_THROTTLE_SEC then
            return
        end
        lastButtonUpdateTime = t
    end

    local merchantOpen = MerchantFrame:IsShown()
    button:SetEnabled(merchantOpen)
    ApplyButtonLook()
end

local function FinishSellingSession()
    sellActive = false
    lastAttemptSig = nil
    stallCount = 0
    CancelSellDelayTimer()
    if button then
        button:SetEnabled(MerchantFrame and MerchantFrame:IsShown() or false)
    end
    ApplyButtonLook()
    UpdateButtonState(true)
end

local function TrySellNext()
    if not sellActive or not MerchantFrame or not MerchantFrame:IsShown() then
        FinishSellingSession()
        return
    end

    local bag, slot, guid = FindFirstSellableMarked()
    if not bag then
        CancelSellDelayTimer()
        ItemMarker:Info(ItemMarker:L("MSG_ALL_SOLD"))
        ItemMarker:QueueBagOverlayRefresh()
        FinishSellingSession()
        return
    end

    local sig = ("%d:%d:%s"):format(bag, slot, tostring(guid))
    if sig == lastAttemptSig then
        stallCount = stallCount + 1
        if stallCount >= 4 then
            CancelSellDelayTimer()
            ItemMarker:Warning(ItemMarker:L("MSG_SELL_STALL"))
            ItemMarker:QueueBagOverlayRefresh()
            FinishSellingSession()
            return
        end
    else
        stallCount = 0
        lastAttemptSig = sig
    end

    ClearCursor()
    C_Container.UseContainerItem(bag, slot)

    CancelSellDelayTimer()
    sellDelayTimer = C_Timer.NewTimer(SELL_DELAY_SEC, function()
        sellDelayTimer = nil
        TrySellNext()
    end)
end

local function OnSellButtonClick()
    if sellActive or not MerchantFrame:IsShown() then
        return
    end
    local n = CountSellableMarkedInBags()
    if n == 0 then
        ItemMarker:Warning(ItemMarker:L("MSG_NO_SELLABLE_MARKED"))
        return
    end
    sellActive = true
    ApplyButtonLook()
    button:SetEnabled(false)
    lastAttemptSig = nil
    stallCount = 0
    TrySellNext()
end

local function CreateMerchantButton()
    if button or not MerchantFrame then
        return
    end

    button = CreateFrame("Button", "Mark2SellMerchantSellButton", MerchantFrame)
    button:SetSize(36, 36)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface/Buttons/UI-EmptySlot")
    bg:SetSize(64, 64)
    bg:SetPoint("TOPLEFT", -13, 14)

    button.Icon = button:CreateTexture(nil, "BORDER")
    button.Icon:SetAtlas("SpellIcon-256x256-SellJunk")
    button.Icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    button.Icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)

    button:SetPushedTexture("Interface/Buttons/UI-Quickslot-Depress")
    local hi = button:CreateTexture(nil, "HIGHLIGHT")
    hi:SetTexture("Interface/Buttons/ButtonHilight-Square")
    hi:SetBlendMode("ADD")
    hi:SetAllPoints()
    button:SetHighlightTexture(hi)

    button:SetScript("OnClick", OnSellButtonClick)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ItemMarker:L("TOOLTIP_MERCHANT_TITLE"), 1, 1, 1)
        GameTooltip:AddLine(ItemMarker:L("TOOLTIP_MERCHANT_DESC"), nil, nil, nil, true)
        local n = CountSellableMarkedInBags()
        GameTooltip:AddLine(ItemMarker:LF("TOOLTIP_MERCHANT_COUNT", n), 0.85, 0.85, 0.85)
        if n == 0 then
            GameTooltip:AddLine(ItemMarker:L("TOOLTIP_MERCHANT_HINT_ZERO"), 0.7, 0.7, 0.7, true)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    hooksecurefunc("MerchantFrame_UpdateRepairButtons", PositionMerchantButton)

    MerchantFrame:HookScript("OnShow", function()
        PositionMerchantButton()
        UpdateButtonState(true)
    end)

    MerchantFrame:HookScript("OnHide", function()
        CancelSellDelayTimer()
        sellActive = false
        lastAttemptSig = nil
        stallCount = 0
        if button then
            button:SetEnabled(true)
        end
        ApplyButtonLook()
    end)

    hooksecurefunc("MerchantFrame_Update", function()
        UpdateButtonState(false)
    end)

    PositionMerchantButton()
    UpdateButtonState(true)
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("BAG_UPDATE_DELAYED")
initFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "BAG_UPDATE_DELAYED" then
        if MerchantFrame and MerchantFrame:IsShown() and not sellActive then
            UpdateButtonState(true)
        end
    elseif event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and addonName == ADDON_NAME) then
        if MerchantFrame then
            CreateMerchantButton()
        end
    end
end)

if MerchantFrame then
    CreateMerchantButton()
end
