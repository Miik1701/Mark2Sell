-- Mark2Sell integration for BagBrother / Bagnon / Bagnonium.
-- Activates only when one of those addons is loaded; all hooks are purely additive.
-- Blizzard-bag behaviour in ItemMarker.lua is completely unchanged.

local function GetBagBrotherAddon()
    return _G["BagBrother"] or _G["Bagnon"] or _G["Bagnonium"]
end

local function GetBagBrotherAddonName()
    for _, name in ipairs({"BagBrother", "Bagnon", "Bagnonium"}) do
        if _G[name] then return name end
    end
end

-- Weak-keyed table: tracks every ItemGroup instance that has called Layout() at least
-- once.  Weak keys mean the GC can collect instances that are no longer referenced.
local liveItemGroups = setmetatable({}, {__mode = "k"})

local function RefreshItemGroup(itemGroup)
    if not itemGroup or type(itemGroup.buttons) ~= "table" then return end
    for _, button in ipairs(itemGroup.buttons) do
        -- BagBrother item buttons always have .bag (set in Item:New) and .info.
        if button.bag ~= nil and button:GetID() then
            ItemMarker:UpdateButtonOverlay(button)
        end
    end
end

local hooked = false

local function SetupBagBrotherHooks()
    if hooked then return end
    local BB = GetBagBrotherAddon()
    if not BB or not BB.ItemGroup then return end

    -- Hook the base ItemGroup:Layout, which is called after every content rebuild
    -- (bag update, rule change, UPDATE_ALL, etc.).  All subclasses (ContainerItemGroup,
    -- VaultItemGroup, …) look up Layout through __index on BB.ItemGroup, so this
    -- single hook covers inventory, bank and vault grids.
    hooksecurefunc(BB.ItemGroup, "Layout", function(self)
        liveItemGroups[self] = true
        -- A zero-delay defers until after the layout pass sets button positions.
        C_Timer.After(0, function()
            RefreshItemGroup(self)
        end)
    end)

    -- When the player toggles a mark (keybind or clear-all), QueueBagOverlayRefresh
    -- already redraws Blizzard frames.  We extend it here to also redraw BB grids.
    hooksecurefunc(ItemMarker, "QueueBagOverlayRefresh", function()
        for itemGroup in pairs(liveItemGroups) do
            RefreshItemGroup(itemGroup)
        end
    end)

    hooked = true
    ItemMarker:Info("[Mark2Sell] BagBrother integration active (" .. (GetBagBrotherAddonName() or "?") .. ")")
end

-- ── Clear-marks button in BagBrother frame ────────────────────────────────────

-- BagBrother's sort button has the global name {AddonName}SortButton (one instance
-- is created for the inventory frame via Poncho's frame pool).  When found, we anchor
-- the existing clearBtn to its left so it mirrors the Blizzard layout.
local function TryAnchorClearButtonToBagBrother()
    local addonName = GetBagBrotherAddonName()
    if not addonName then return end

    -- The sort button widget lives inside the inventory frame.  Its global name is
    -- produced by Poncho as {ADDON}SortButton (with a numeric suffix for pooled frames,
    -- starting at 1).
    local sortBtn = _G[addonName .. "SortButton"] or _G[addonName .. "SortButton1"]
    if not sortBtn or not sortBtn:IsShown() then return end

    local clearBtn = _G["Mark2SellBagClearMarksButton"]
    if not clearBtn then return end

    clearBtn:SetParent(sortBtn:GetParent())
    clearBtn:ClearAllPoints()
    clearBtn:SetPoint("RIGHT", sortBtn, "LEFT", -4, 0)
    clearBtn:SetFrameStrata(sortBtn:GetFrameStrata())
    clearBtn:SetFrameLevel(sortBtn:GetFrameLevel() + 1)
    clearBtn:Show()
end

-- Hook ItemMarker's refresh-button call so the BB anchor is retried whenever the
-- standard button positioning runs (e.g. on frame open/close).
local function HookClearButton()
    if ItemMarker.RefreshBagClearMarksButton then
        hooksecurefunc(ItemMarker, "RefreshBagClearMarksButton", function()
            TryAnchorClearButtonToBagBrother()
        end)
    end
end

-- ── Initialisation ─────────────────────────────────────────────────────────────

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "PLAYER_LOGIN" then
        SetupBagBrotherHooks()
        HookClearButton()
        TryAnchorClearButtonToBagBrother()
    elseif event == "ADDON_LOADED" then
        if addonName == "BagBrother" or addonName == "Bagnon" or addonName == "Bagnonium" then
            SetupBagBrotherHooks()
            HookClearButton()
        end
        if addonName == "Mark2Sell" then
            -- Our own TOC finished loading — hooks not yet possible, but register intent.
            C_Timer.After(0, function()
                SetupBagBrotherHooks()
                HookClearButton()
                TryAnchorClearButtonToBagBrother()
            end)
        end
    end
end)
