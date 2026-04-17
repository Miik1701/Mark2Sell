-- Mark2Sell: markiert Taschen-Items zum späteren Verkauf (pro Item-Instanz via Item-GUID).

ItemMarker = ItemMarker or {}

local DB_KEY_MARKED = "marked"
local LEGACY_OVERLAY_KEY = "Mark2SellOverlay"
local OVERLAY_TINT_KEY = "Mark2SellOverlayTint"
local OVERLAY_ICON_KEY = "Mark2SellSellBadge"

-- Soft gold wash (vendor / coin) — not the old highlighter yellow.
local MARK_TINT_R, MARK_TINT_G, MARK_TINT_B, MARK_TINT_A = 0.72, 0.52, 0.18, 0.42
local SELL_ICON_ATLAS = "SpellIcon-256x256-SellJunk"
local SELL_ICON_SIZE = 18

local initFrame = CreateFrame("Frame")
local hooksRegistered = false
local overlayRefreshTimer

local function GetMarkedTable()
    ItemMarkerDB = ItemMarkerDB or {}
    ItemMarkerDB[DB_KEY_MARKED] = ItemMarkerDB[DB_KEY_MARKED] or {}
    return ItemMarkerDB[DB_KEY_MARKED]
end

local function GetBagSlotGUID(bagID, slot)
    local loc = ItemLocation:CreateFromBagAndSlot(bagID, slot)
    if loc and loc:IsValid() and C_Item.DoesItemExist(loc) then
        return C_Item.GetItemGUID(loc)
    end
end

--- Findet einen ContainerFrame-Item-Button unter dem Mauszeiger (Standard-Taschen-UI).
local function GetContainerItemButtonUnderCursor()
    for _, focus in ipairs(GetMouseFoci()) do
        local region = focus
        local depth = 0
        while region and depth < 24 do
            if region.GetBagID and region.GetID and region.HasItem then
                local bagID = region:GetBagID()
                local slot = region:GetID()
                if bagID ~= nil and slot and region:HasItem() then
                    return bagID, slot
                end
            end
            region = region:GetParent()
            depth = depth + 1
        end
    end
end

function ItemMarker:IsMarkedGUID(guid)
    return guid and GetMarkedTable()[guid] == true
end

--- true, wenn der Slot einen Händler-Verkaufspreis hat (kein „Kein Händlerwert“ / sellPrice > 0).
local function IsVendorSellableBagSlot(bagID, slot)
    local info = C_Container.GetContainerItemInfo(bagID, slot)
    if not info then
        return false
    end
    if info.hasNoValue then
        return false
    end
    local token = info.hyperlink or info.itemID
    if not token then
        return false
    end
    local itemName, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(token)
    if not itemName then
        return false
    end
    if type(sellPrice) ~= "number" or sellPrice <= 0 then
        return false
    end
    return true
end

function ItemMarker:ToggleMarkBagSlot(bagID, slot)
    local guid = GetBagSlotGUID(bagID, slot)
    if not guid then
        ItemMarker:Warning(ItemMarker:L("MSG_NO_ITEM_SLOT"))
        return
    end
    local t = GetMarkedTable()
    if t[guid] then
        t[guid] = nil
        ItemMarker:Info(ItemMarker:L("MSG_MARK_REMOVED"))
    else
        if not IsVendorSellableBagSlot(bagID, slot) then
            ItemMarker:Warning(ItemMarker:L("MSG_NO_VENDOR_VALUE"))
            return
        end
        t[guid] = true
        ItemMarker:Info(ItemMarker:L("MSG_MARKED_FOR_SELL"))
    end
    ItemMarker:QueueBagOverlayRefresh()
end

function ItemMarker:ToggleMarkUnderCursor()
    local bagID, slot = GetContainerItemButtonUnderCursor()
    if not bagID then
        ItemMarker:Warning(ItemMarker:L("MSG_NO_BAG_ITEM_CURSOR"))
        return
    end
    self:ToggleMarkBagSlot(bagID, slot)
end

function ItemMarker:ClearAllMarks()
    wipe(GetMarkedTable())
    ItemMarker:Info(ItemMarker:L("MSG_ALL_MARKS_CLEARED"))
    ItemMarker:QueueBagOverlayRefresh()
end

function ItemMarker:ShowMarkedList()
    local t = GetMarkedTable()
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    if count == 0 then
        ItemMarker:Info(ItemMarker:L("MSG_NO_MARKED"))
        return
    end
    ItemMarker:Info(ItemMarker:LF("MSG_MARKED_LIST_HEADER", count))
    for bag = Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local guid = GetBagSlotGUID(bag, slot)
            if guid and t[guid] then
                local info = C_Container.GetContainerItemInfo(bag, slot)
                local link = info and info.hyperlink
                if link then
                    ItemMarker:Info(link)
                end
            end
        end
    end
end

function ItemMarker:UpdateButtonOverlay(button)
    local bagID = button:GetBagID()
    local slot = button:GetID()
    local guid = GetBagSlotGUID(bagID, slot)
    local show = guid and GetMarkedTable()[guid]

    local legacy = button[LEGACY_OVERLAY_KEY]
    if legacy then
        legacy:Hide()
        button[LEGACY_OVERLAY_KEY] = nil
    end

    local tint = button[OVERLAY_TINT_KEY]
    local badge = button[OVERLAY_ICON_KEY]

    if show then
        local itemIcon = GetItemButtonIconTexture(button)
        if not tint then
            tint = button:CreateTexture(nil, "OVERLAY", nil, 6)
            if itemIcon then
                tint:SetAllPoints(itemIcon)
            else
                tint:SetAllPoints(button)
            end
            button[OVERLAY_TINT_KEY] = tint
        elseif itemIcon then
            tint:ClearAllPoints()
            tint:SetAllPoints(itemIcon)
        else
            tint:ClearAllPoints()
            tint:SetAllPoints(button)
        end
        tint:SetBlendMode("BLEND")
        tint:SetColorTexture(MARK_TINT_R, MARK_TINT_G, MARK_TINT_B, MARK_TINT_A)
        tint:Show()

        if not badge then
            badge = button:CreateTexture(nil, "OVERLAY", nil, 7)
            button[OVERLAY_ICON_KEY] = badge
        end
        badge:SetAtlas(SELL_ICON_ATLAS)
        badge:SetSize(SELL_ICON_SIZE, SELL_ICON_SIZE)
        badge:SetVertexColor(1, 0.94, 0.78)
        badge:ClearAllPoints()
        if itemIcon then
            badge:SetPoint("TOPRIGHT", itemIcon, "TOPRIGHT", -1, -1)
        else
            badge:SetPoint("TOPRIGHT", button, "TOPRIGHT", -3, -3)
        end
        badge:Show()
    else
        if tint then
            tint:Hide()
        end
        if badge then
            badge:Hide()
        end
    end
end

function ItemMarker:RefreshContainerFrame(containerFrame)
    if not containerFrame or not containerFrame.EnumerateValidItems then
        return
    end
    for _, itemButton in containerFrame:EnumerateValidItems() do
        self:UpdateButtonOverlay(itemButton)
    end
end

function ItemMarker:RefreshAllOpenBagOverlays()
    if not ContainerFrameUtil_EnumerateContainerFrames then
        return
    end
    for _, frame in ContainerFrameUtil_EnumerateContainerFrames() do
        if frame:IsShown() then
            self:RefreshContainerFrame(frame)
        end
    end
end

function ItemMarker:QueueBagOverlayRefresh()
    self:RefreshAllOpenBagOverlays()
    if overlayRefreshTimer then
        overlayRefreshTimer:Cancel()
    end
    overlayRefreshTimer = C_Timer.NewTimer(0.15, function()
        overlayRefreshTimer = nil
        ItemMarker:RefreshAllOpenBagOverlays()
    end)
end

local function RegisterHooksAndEvents()
    if hooksRegistered then
        return
    end
    if not hooksecurefunc or not ContainerFrame_UpdateAll then
        return
    end
    hooksecurefunc("ContainerFrame_UpdateAll", function()
        ItemMarker:QueueBagOverlayRefresh()
    end)
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("ContainerFrame.OpenBag", function()
            ItemMarker:QueueBagOverlayRefresh()
        end, ItemMarker)
    end
    hooksRegistered = true
end

local function OnInit()
    RegisterHooksAndEvents()
    ItemMarker:QueueBagOverlayRefresh()
end

initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("BAG_UPDATE_DELAYED")
initFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "BAG_UPDATE_DELAYED" then
        ItemMarker:QueueBagOverlayRefresh()
    elseif event == "PLAYER_LOGIN" then
        OnInit()
    elseif event == "ADDON_LOADED" and addonName == "Mark2Sell" then
        OnInit()
    end
end)

OnInit()

-- Keybinds (Bindings.xml)
function ItemMarker_ToggleMark()
    ItemMarker:ToggleMarkUnderCursor()
end

function ItemMarker_ClearAllMark()
    ItemMarker:ClearAllMarks()
end

function ItemMarker_ShowList()
    if not ItemMarker:IsDebugMode() then
        return
    end
    ItemMarker:ShowMarkedList()
end
