-- Taschen-UI: Button zum Löschen aller Markierungen (Standard: links vom Taschen-Suchfeld).

local ADDON_NAME = "Mark2Sell"
local eventRegistryOwner = {}

local clearBtn
local hooksRegistered = false

local BASE_GAP = 8

local function GetClearBtnOffset()
    ItemMarkerDB = ItemMarkerDB or {}
    local x = ItemMarkerDB.clearBtnOffsetX
    local y = ItemMarkerDB.clearBtnOffsetY
    if type(x) ~= "number" then
        x = 0
    end
    if type(y) ~= "number" then
        y = 0
    end
    return x, y
end

local function EnsureButton()
    if clearBtn then
        return
    end
    if not BagItemAutoSortButton then
        return
    end

    clearBtn = CreateFrame("Button", "Mark2SellBagClearMarksButton", BagItemAutoSortButton:GetParent())
    clearBtn:SetSize(28, 26)
    clearBtn:SetNormalAtlas("auctionhouse-ui-filter-redx")
    clearBtn:SetPushedAtlas("auctionhouse-ui-filter-redx")

    local hi = clearBtn:CreateTexture(nil, "HIGHLIGHT")
    hi:SetTexture("Interface/Buttons/ButtonHilight-Square")
    hi:SetBlendMode("ADD")
    hi:SetAllPoints()
    clearBtn:SetHighlightTexture(hi)

    clearBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        ItemMarker:ClearAllMarks()
    end)

    clearBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(ItemMarker:L("BTN_CLEAR_MARKS_TITLE"), 1, 1, 1)
        GameTooltip:AddLine(ItemMarker:L("BTN_CLEAR_MARKS_DESC"), nil, nil, nil, true)
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave", GameTooltip_Hide)
end

local function RefreshClearMarksButton()
    if not BagItemAutoSortButton then
        return
    end
    EnsureButton()
    if not clearBtn then
        return
    end

    if BagItemAutoSortButton:IsShown() then
        local parent = BagItemAutoSortButton:GetParent()
        clearBtn:SetParent(parent)
        clearBtn:ClearAllPoints()
        local dx, dy = GetClearBtnOffset()
        -- Standard: links vom Suchfeld (rechte Kante des Buttons am linken Rand der Suche).
        if BagItemSearchBox and BagItemSearchBox:IsShown() then
            clearBtn:SetPoint("RIGHT", BagItemSearchBox, "LEFT", -BASE_GAP + dx, dy)
        else
            clearBtn:SetPoint("RIGHT", BagItemAutoSortButton, "LEFT", -BASE_GAP + dx, dy)
        end
        clearBtn:SetFrameStrata(BagItemAutoSortButton:GetFrameStrata())
        clearBtn:SetFrameLevel(BagItemAutoSortButton:GetFrameLevel() + 1)
        clearBtn:Show()
    else
        clearBtn:Hide()
    end
end

function ItemMarker:RefreshBagClearMarksButton()
    RefreshClearMarksButton()
end

local function RegisterHooks()
    if hooksRegistered then
        return
    end
    if not hooksecurefunc or not ContainerFrame_UpdateAll then
        return
    end
    hooksecurefunc("ContainerFrame_UpdateAll", function()
        RefreshClearMarksButton()
    end)
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("ContainerFrame.OpenBag", function()
            RefreshClearMarksButton()
        end, eventRegistryOwner)
    end
    hooksRegistered = true
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and addonName == ADDON_NAME) then
        RegisterHooks()
        RefreshClearMarksButton()
    end
end)

RegisterHooks()
RefreshClearMarksButton()
