-- =========================================================================
-- DungeonBots_InventoryUI.lua: Ventana Estilo Bolsas para Inventario de Bots
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal
local L = DungeonBots.L or {}

local function ApplyBlizzardGoldWindow(frame, edgeSize)
    return DB_Internal.ApplyBlizzardGoldWindow(frame, edgeSize)
end

local function ApplyBlizzardStonePanel(frame, borderR, borderG, borderB, edgeSize, bgAlpha)
    return DB_Internal.ApplyBlizzardStonePanel(frame, borderR, borderG, borderB, edgeSize, bgAlpha)
end

local function ApplyHeaderBackdrop(frame)
    return DB_Internal.ApplyHeaderBackdrop(frame)
end

local function CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
    return DB_Internal.CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
end

local function FormatDestroyItemLine(itemEntry)
    if not itemEntry then return "" end
    local itemDisplay = (itemEntry.displayLink and itemEntry.displayLink ~= "")
        and itemEntry.displayLink
        or ("[" .. (itemEntry.name or itemEntry.rawName or L["ITEM_DEFAULT"]) .. "]")
    if (itemEntry.count or 1) > 1 then
        itemDisplay = itemDisplay .. " |cffffffffx" .. itemEntry.count .. "|r"
    end
    return itemDisplay
end

local UpdateSlotSelectionUI

StaticPopupDialogs["DUNGEONBOTS_DESTROY_BOT_ITEM"] = {
    text = L["INV_DESTROY_CONFIRM"],
    button1 = L["BTN_DESTROY"],
    button2 = L["BTN_CANCEL"],
    OnShow = function(self, data)
        if data and data.confirmText then
            local textFS = self.text or _G[self:GetName() .. "Text"]
            if textFS then
                textFS:SetText(data.confirmText)
                if StaticPopup_Resize then
                    StaticPopup_Resize(self, "DUNGEONBOTS_DESTROY_BOT_ITEM")
                end
            end
        end
    end,
    OnAccept = function(self, data)
        if not data or not data.botName then return end
        local items = data.items
        if (not items or #items == 0) and data.item then
            items = { data.item }
        end
        if not items or #items == 0 then return end

        local inv = DungeonBots.inventoryFrame
        if inv and inv.currentBot == data.botName and inv.selectedItems then
            local acceptedSet = {}
            for _, entry in ipairs(items) do
                acceptedSet[entry] = true
            end
            for i = #inv.selectedItems, 1, -1 do
                if acceptedSet[inv.selectedItems[i]] then
                    table.remove(inv.selectedItems, i)
                end
            end
            if UpdateSlotSelectionUI then
                UpdateSlotSelectionUI()
            end
        end

        if #items > 1 and DungeonBots.DestroyBotItems then
            DungeonBots:DestroyBotItems(data.botName, items)
        elseif DungeonBots.DestroyBotItem then
            DungeonBots:DestroyBotItem(data.botName, items[1])
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
if DB_Internal.RegisterLocaleRefresh then
    DB_Internal.RegisterLocaleRefresh(function()
        StaticPopupDialogs["DUNGEONBOTS_DESTROY_BOT_ITEM"].text = L["INV_DESTROY_CONFIRM"]
        StaticPopupDialogs["DUNGEONBOTS_DESTROY_BOT_ITEM"].button1 = L["BTN_DESTROY"]
        StaticPopupDialogs["DUNGEONBOTS_DESTROY_BOT_ITEM"].button2 = L["BTN_CANCEL"]
    end)
end

local function ConfirmDestroyBotItems(botName, itemList)
    if not botName or type(itemList) ~= "table" or #itemList == 0 then return end
    PlaySound("igMainMenuOptionCheckBoxOn")

    if #itemList == 1 then
        local itemEntry = itemList[1]
        local itemDisplay = FormatDestroyItemLine(itemEntry)
        StaticPopup_Show("DUNGEONBOTS_DESTROY_BOT_ITEM", botName, itemDisplay, {
            botName = botName,
            item = itemEntry,
            items = { itemEntry },
        })
        return
    end

    local lines = {}
    local maxPreview = 8
    local limit = math.min(#itemList, maxPreview)
    for idx = 1, limit do
        table.insert(lines, "- " .. FormatDestroyItemLine(itemList[idx]))
    end
    if #itemList > maxPreview then
        table.insert(lines, string.format(L["INV_DESTROY_MORE_FMT"], #itemList - maxPreview))
    end

    local confirmText = string.format(L["INV_DESTROY_MULTI_CONFIRM"], botName, #itemList, table.concat(lines, "\n"))
    StaticPopup_Show("DUNGEONBOTS_DESTROY_BOT_ITEM", botName, "", {
        botName = botName,
        items = itemList,
        confirmText = confirmText,
    })
end

local GRID_COLS = 9
local SLOT_SIZE = 44
local SLOT_GAP = 6
local SLOT_PITCH = SLOT_SIZE + SLOT_GAP
local GRID_PAD_X = 16
local GRID_PAD_Y = 12

local invSlotButtons = {}

local function GetQualityColor(rarity)
    if ITEM_QUALITY_COLORS and rarity ~= nil and ITEM_QUALITY_COLORS[rarity] then
        local q = ITEM_QUALITY_COLORS[rarity]
        return q.r, q.g, q.b
    end
    return 0.55, 0.58, 0.65
end

local function GetSelectedItems(inv)
    if not inv then return {} end
    if not inv.selectedItems then
        inv.selectedItems = {}
    end
    return inv.selectedItems
end

local function IsItemSelected(inv, itemEntry)
    if not inv or not itemEntry or not inv.selectedItems then return false end
    for _, sel in ipairs(inv.selectedItems) do
        if sel == itemEntry then
            return true
        end
    end
    return false
end

local function ClearSelectedItems(inv)
    if inv and inv.selectedItems then
        inv.selectedItems = {}
    end
end

local function ToggleSelectedItem(inv, itemEntry)
    if not inv or not itemEntry then return end
    local list = GetSelectedItems(inv)
    for i, sel in ipairs(list) do
        if sel == itemEntry then
            table.remove(list, i)
            return
        end
    end
    table.insert(list, itemEntry)
end

local function PruneSelectedItems(inv, visibleItems)
    if not inv or not inv.selectedItems or #inv.selectedItems == 0 then return end
    local visibleSet = {}
    for _, item in ipairs(visibleItems) do
        visibleSet[item] = true
    end
    for i = #inv.selectedItems, 1, -1 do
        if not visibleSet[inv.selectedItems[i]] then
            table.remove(inv.selectedItems, i)
        end
    end
end

UpdateSlotSelectionUI = function()
    local inv = DungeonBots.inventoryFrame
    if not inv then return end

    local selectedList = GetSelectedItems(inv)
    local selCount = #selectedList
    for _, slot in ipairs(invSlotButtons) do
        if slot:IsShown() and slot.itemEntry then
            local isSel = IsItemSelected(inv, slot.itemEntry)
            if isSel then
                slot.selOverlay:Show()
                slot:SetBackdropBorderColor(1.0, 0.85, 0.15, 1.0)
            else
                slot.selOverlay:Hide()
                local r, g, b = GetQualityColor(slot.itemEntry.rarity)
                slot:SetBackdropBorderColor(r, g, b, 0.92)
            end
        end
    end

    if selCount > 0 then
        inv.destroyBtn:SetText(string.format(L["BTN_DESTROY_MULTI_FMT"], selCount))
        inv.destroyBtn:Enable()
        inv.destroyBtn:SetAlpha(1.0)
    else
        inv.destroyBtn:SetText(L["BTN_DESTROY"])
        inv.destroyBtn:Disable()
        inv.destroyBtn:SetAlpha(0.45)
    end
end

local function CreateInventorySlotButton(parent, idx)
    local btn = CreateFrame("Button", "DungeonBots_InvSlot_" .. idx, parent)
    btn:SetSize(SLOT_SIZE, SLOT_SIZE)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local col = (idx - 1) % GRID_COLS
    local row = math.floor((idx - 1) / GRID_COLS)
    btn:SetPoint("TOPLEFT", GRID_PAD_X + (col * SLOT_PITCH), -(GRID_PAD_Y + (row * SLOT_PITCH)))

    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 10, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    local function StyleInvSlot(s)
        local p = DB_Internal.GetThemePalette and DB_Internal.GetThemePalette()
        if not p then return end
        s:SetBackdropColor(p.slotDefaultBg[1], p.slotDefaultBg[2], p.slotDefaultBg[3], p.slotDefaultBg[4])
        if not s.itemEntry then
            local eb = p.slotEmptyBorder
            s:SetBackdropBorderColor(eb[1], eb[2], eb[3], eb[4])
        end
    end
    StyleInvSlot(btn)
    if DB_Internal.RegisterThemed then
        DB_Internal.RegisterThemed(btn, StyleInvSlot)
    end

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 4, -4)
    icon:SetPoint("BOTTOMRIGHT", -4, 4)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetPoint("TOPLEFT", 3, -3)
    highlight:SetPoint("BOTTOMRIGHT", -3, 3)
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")

    local selOverlay = btn:CreateTexture(nil, "OVERLAY")
    selOverlay:SetPoint("TOPLEFT", 2, -2)
    selOverlay:SetPoint("BOTTOMRIGHT", -2, 2)
    selOverlay:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    selOverlay:SetBlendMode("ADD")
    selOverlay:SetVertexColor(1.0, 0.85, 0.2, 0.85)
    selOverlay:Hide()
    btn.selOverlay = selOverlay

    local countText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    countText:SetPoint("BOTTOMRIGHT", -4, 4)
    countText:SetJustifyH("RIGHT")
    btn.countText = countText

    btn:SetScript("OnEnter", function(self)
        local item = self.itemEntry
        if not item then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local ok = false
        if item.rawLink and item.rawLink ~= "" then
            ok = pcall(GameTooltip.SetHyperlink, GameTooltip, item.rawLink)
        end
        if (not ok or GameTooltip:NumLines() == 0) and item.itemId then
            GameTooltip:ClearLines()
            ok = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. tostring(item.itemId))
        end
        if not ok or GameTooltip:NumLines() == 0 then
            GameTooltip:ClearLines()
            local r, g, b = GetQualityColor(item.rarity)
            GameTooltip:AddLine(item.name or item.rawName or L["ITEM_DEFAULT"], r, g, b)
            GameTooltip:AddLine(L["INV_TIP_WAIT_SRV"], 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine(" ")
        if (item.count or 1) > 1 then
            GameTooltip:AddLine(string.format(L["INV_TIP_QTY_FMT"], tostring(item.count)), 0.75, 0.85, 0.95)
        end
        if item.category and item.category ~= "" and item.category ~= "General" and item.category ~= L["CAT_GENERAL"] then
            local dispCat = DungeonBots.LocalizeServerSection and DungeonBots:LocalizeServerSection(item.category) or item.category
            GameTooltip:AddLine(string.format(L["INV_TIP_SEC_FMT"], dispCat), 0.75, 0.75, 0.75)
        end
        GameTooltip:AddLine(L["INV_TIP_ACTIONS"], 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function(self, mouseBtn)
        local inv = DungeonBots.inventoryFrame
        local item = self.itemEntry
        if not inv or not item then return end

        if mouseBtn == "RightButton" then
            ConfirmDestroyBotItems(inv.currentBot, { item })
            return
        end

        if IsModifiedClick and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
            local link = item.displayLink or item.rawLink or item.plainLink
            if link and ChatEdit_InsertLink(link) then
                return
            end
        end

        PlaySound("igMainMenuOptionCheckBoxOn")
        ToggleSelectedItem(inv, item)
        UpdateSlotSelectionUI()
    end)

    invSlotButtons[idx] = btn
    return btn
end

function DungeonBots:BuildInventoryDialog()
    if DungeonBots.inventoryFrame then return end

    local inv = CreateFrame("Frame", "DungeonBots_InventoryFrame", UIParent)
    inv:SetSize(540, 424)
    inv:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    inv:SetFrameStrata("DIALOG")
    inv:SetFrameLevel(25)
    inv:SetToplevel(true)
    inv:SetMovable(true)
    inv:EnableMouse(true)
    inv:SetClampedToScreen(true)
    inv:RegisterForDrag("LeftButton")
    inv:SetScript("OnDragStart", inv.StartMoving)
    inv:SetScript("OnDragStop", inv.StopMovingOrSizing)
    inv:Hide()
    ApplyBlizzardGoldWindow(inv, 16)

    table.insert(UISpecialFrames, "DungeonBots_InventoryFrame")

    local header = CreateFrame("Frame", nil, inv)
    header:SetPoint("TOPLEFT", inv, "TOPLEFT", 7, -7)
    header:SetPoint("TOPRIGHT", inv, "TOPRIGHT", -7, -7)
    header:SetHeight(30)
    ApplyHeaderBackdrop(header)

    local hIcon = header:CreateTexture(nil, "ARTWORK")
    hIcon:SetSize(18, 18)
    hIcon:SetPoint("LEFT", 10, 0)
    hIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
    hIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", hIcon, "RIGHT", 6, 0)
    title:SetText(L["INV_WIN_DEFAULT"])
    inv.title = title

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        inv:Hide()
    end)

    local searchLabel = inv:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    searchLabel:SetPoint("TOPLEFT", inv, "TOPLEFT", 14, -44)
    searchLabel:SetText(L["SEARCH_LABEL"])

    local searchBox = CreateFrame("EditBox", "DungeonBots_InvSearchBox", inv, "InputBoxTemplate")
    searchBox:SetSize(165, 20)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    searchBox:SetScript("OnTextChanged", function()
        if inv.currentBot then
            DungeonBots:UpdateInventoryDialog(inv.currentBot)
        end
    end)
    inv.searchBox = searchBox

    local refreshBtn = CreateFrame("Button", nil, inv, "UIPanelButtonTemplate")
    refreshBtn:SetSize(102, 22)
    refreshBtn:SetPoint("TOPRIGHT", inv, "TOPRIGHT", -12, -39)
    refreshBtn:SetText(L["BTN_REFRESH"])
    refreshBtn:SetScript("OnClick", function()
        if not inv.currentBot then return end
        local pendingCap = DungeonBots.pendingInventoryCapture and DungeonBots.pendingInventoryCapture[inv.currentBot]
        if pendingCap then return end
        PlaySound("igMainMenuOptionCheckBoxOn")
        ClearSelectedItems(inv)
        if DungeonBots.QueryBotInventory then
            DungeonBots:QueryBotInventory(inv.currentBot, false, true)
        elseif DungeonBots.QueryBotStats then
            DungeonBots:QueryBotStats(inv.currentBot, true)
        end
    end)
    inv.refreshBtn = refreshBtn

    local bagSpaceIcon = inv:CreateTexture(nil, "ARTWORK")
    bagSpaceIcon:SetSize(14, 14)
    bagSpaceIcon:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
    bagSpaceIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
    bagSpaceIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    inv.bagSpaceIcon = bagSpaceIcon

    local bagSpaceLabel = inv:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bagSpaceLabel:SetPoint("LEFT", bagSpaceIcon, "RIGHT", 5, 0)
    bagSpaceLabel:SetPoint("RIGHT", refreshBtn, "LEFT", -8, 0)
    bagSpaceLabel:SetJustifyH("LEFT")
    bagSpaceLabel:SetWordWrap(false)
    bagSpaceLabel:SetText(L["INV_BAGS_QUERYING"])
    inv.bagSpaceLabel = bagSpaceLabel

    local bagBg = CreateFrame("Frame", nil, inv)
    bagBg:SetPoint("TOPLEFT", inv, "TOPLEFT", 10, -68)
    bagBg:SetPoint("BOTTOMRIGHT", inv, "BOTTOMRIGHT", -10, 42)
    ApplyBlizzardStonePanel(bagBg, 0.66, 0.54, 0.30, 10, 0.30)

    local scroll = CreateFrame("ScrollFrame", "DungeonBots_InvScroll", bagBg, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", bagBg, "TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", bagBg, "BOTTOMRIGHT", -26, 6)

    local scrollChild = CreateFrame("Frame", "DungeonBots_InvScrollChild", scroll)
    scrollChild:SetSize(486, 1)
    scroll:SetScrollChild(scrollChild)
    inv.scrollChild = scrollChild

    local emptyLabel = bagBg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyLabel:SetPoint("CENTER", bagBg, "CENTER", -8, 0)
    emptyLabel:SetWidth(420)
    emptyLabel:SetText(L["WAIT_BOT_RESPONSE"])
    inv.emptyLabel = emptyLabel

    local nextBotBtn = CreateFrame("Button", nil, inv, "UIPanelButtonTemplate")
    nextBotBtn:SetSize(120, 24)
    nextBotBtn:SetPoint("BOTTOMLEFT", inv, "BOTTOMLEFT", 12, 10)
    nextBotBtn:SetText(L["BTN_NEXT_BOT"])
    nextBotBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        ClearSelectedItems(inv)
        if DungeonBots.CycleNextInventoryBot then
            DungeonBots:CycleNextInventoryBot(inv.currentBot)
        end
    end)
    nextBotBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["BTN_NEXT_BOT"], 1, 0.82, 0)
        GameTooltip:AddLine(L["INV_NEXT_BOT_TIP"], 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    nextBotBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    inv.nextBotBtn = nextBotBtn

    local botCycleLabel = inv:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    botCycleLabel:SetPoint("LEFT", nextBotBtn, "RIGHT", 8, 0)
    botCycleLabel:SetWidth(42)
    botCycleLabel:SetJustifyH("LEFT")
    botCycleLabel:SetText("|cff888888(0/0)|r")
    inv.botCycleLabel = botCycleLabel

    local closeFooterBtn = CreateFrame("Button", nil, inv, "UIPanelButtonTemplate")
    closeFooterBtn:SetSize(90, 24)
    closeFooterBtn:SetPoint("BOTTOMRIGHT", inv, "BOTTOMRIGHT", -12, 10)
    closeFooterBtn:SetText(L["BTN_CLOSE"])
    closeFooterBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        inv:Hide()
    end)
    inv.closeFooterBtn = closeFooterBtn

    local destroyBtn = CreateRedIconButton(inv, 122, 24, L["BTN_DESTROY"], "Interface\\Icons\\Spell_ChargeNegative")
    destroyBtn:SetPoint("RIGHT", closeFooterBtn, "LEFT", -8, 0)
    destroyBtn:Disable()
    destroyBtn:SetAlpha(0.45)
    destroyBtn:SetScript("OnClick", function()
        local selected = GetSelectedItems(inv)
        if not inv.currentBot or #selected == 0 then return end
        ConfirmDestroyBotItems(inv.currentBot, selected)
    end)
    destroyBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["INV_DESTROY_TIP_TITLE"], 1, 0.35, 0.35)
        GameTooltip:AddLine(L["INV_DESTROY_TIP_DESC"], 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    destroyBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    inv.destroyBtn = destroyBtn

    DungeonBots.inventoryFrame = inv
    if DB_Internal.RegisterSubModalDimmer then
        DB_Internal.RegisterSubModalDimmer(inv)
    end
end

function DungeonBots:UpdateInventoryDialog(botName)
    local inv = DungeonBots.inventoryFrame
    if not inv then return end

    local targetBot = botName or inv.currentBot
    if not targetBot then return end
    inv.currentBot = targetBot

    local unit = DungeonBots.FindPartyUnitByName and DungeonBots:FindPartyUnitByName(targetBot)
    local classHex = "|cffffd200"
    if unit and UnitClass and RAID_CLASS_COLORS then
        local _, classToken = UnitClass(unit)
        local c = classToken and RAID_CLASS_COLORS[classToken]
        if c then
            classHex = string.format("|cff%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
        end
    end
    inv.title:SetText(string.format(L["INV_WIN_FMT"], classHex, targetBot))

    local data = DungeonBots.inventoryDialogData and DungeonBots.inventoryDialogData[targetBot]
    local allItems = (data and data.items) or {}

    local filterRaw = inv.searchBox and inv.searchBox:GetText() or ""
    local filterText = string.lower(string.gsub(filterRaw, "^%s*(.-)%s*$", "%1"))

    local visibleItems = {}
    for _, item in ipairs(allItems) do
        local match = true
        if filterText ~= "" then
            local locName = string.lower(item.name or "")
            local rawName = string.lower(item.rawName or "")
            local catName = string.lower(item.category or "")
            if not (string.find(locName, filterText, 1, true)
                or string.find(rawName, filterText, 1, true)
                or string.find(catName, filterText, 1, true)) then
                match = false
            end
        end
        if match then
            table.insert(visibleItems, item)
        end
    end
    PruneSelectedItems(inv, visibleItems)

    if inv.bagSpaceLabel then
        local st = DungeonBots.botStats and DungeonBots.botStats[targetBot]
        if DB_Internal.GetBotBagFreeInfo and st then
            local freeSlots, totalSlots, bagColor = DB_Internal.GetBotBagFreeInfo(st)
            if freeSlots ~= nil then
                inv.bagSpaceLabel:SetText(string.format(L["INV_BAGS_FREE_FMT"], bagColor, tonumber(freeSlots) or 0, tonumber(totalSlots) or 0))
            else
                inv.bagSpaceLabel:SetText(L["INV_BAGS_QUERYING"])
            end
        elseif data and data.slotsText and data.slotsText ~= "" then
            inv.bagSpaceLabel:SetText("|cffe6ecf5" .. data.slotsText .. "|r")
        else
            inv.bagSpaceLabel:SetText(L["INV_BAGS_QUERYING"])
        end
    end

    if inv.refreshBtn then
        local isCapPending = DungeonBots.pendingInventoryCapture and DungeonBots.pendingInventoryCapture[targetBot] ~= nil
        if isCapPending or (data and data.loading) then
            inv.refreshBtn:Disable()
            inv.refreshBtn:SetText(L["BTN_QUERYING"])
        else
            inv.refreshBtn:Enable()
            inv.refreshBtn:SetText(L["BTN_REFRESH"])
        end
    end

    if #visibleItems == 0 then
        inv.emptyLabel:Show()
        if data and data.loading then
            inv.emptyLabel:SetText(string.format(L["INV_STATUS_QUERY_FMT"], targetBot))
        elseif data and data.timedOut and #allItems == 0 then
            local baseMsg = string.format(L["INV_STATUS_NORESP_FMT"], targetBot)
            inv.emptyLabel:SetText(DungeonBots.FormatNoResponseBody and DungeonBots:FormatNoResponseBody(baseMsg, targetBot) or baseMsg)
        elseif #allItems == 0 then
            inv.emptyLabel:SetText(string.format(L["INV_STATUS_EMPTY_FMT"], targetBot))
        else
            inv.emptyLabel:SetText(string.format(L["INV_STATUS_NOMATCH_FMT"], filterRaw))
        end
    else
        inv.emptyLabel:Hide()
    end

    local totalSlotsToShow = 0
    if #visibleItems > 0 then
        if filterText == "" then
            totalSlotsToShow = math.max(GRID_COLS * 3, math.ceil(#visibleItems / GRID_COLS) * GRID_COLS)
        else
            totalSlotsToShow = #visibleItems
        end
    end

    for i = 1, totalSlotsToShow do
        local slot = invSlotButtons[i] or CreateInventorySlotButton(inv.scrollChild, i)
        local item = visibleItems[i]
        if item then
            slot.itemEntry = item
            slot:Enable()
            slot.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            slot.icon:Show()

            if (item.count or 1) > 1 then
                slot.countText:SetText(tostring(item.count))
                slot.countText:Show()
            else
                slot.countText:Hide()
            end
        else
            slot.itemEntry = nil
            slot:Disable()
            slot.icon:Hide()
            slot.countText:Hide()
            slot.selOverlay:Hide()
            local eb = (DB_Internal.GetThemePalette and DB_Internal.GetThemePalette().slotEmptyBorder) or { 0.36, 0.30, 0.20, 0.55 }
            slot:SetBackdropBorderColor(eb[1], eb[2], eb[3], eb[4])
        end
        slot:Show()
    end

    for i = totalSlotsToShow + 1, #invSlotButtons do
        invSlotButtons[i].itemEntry = nil
        invSlotButtons[i]:Hide()
    end

    local totalRows = math.max(1, math.ceil(totalSlotsToShow / GRID_COLS))
    inv.scrollChild:SetHeight((GRID_PAD_Y * 2) + (totalRows * SLOT_PITCH) - SLOT_GAP)

    if inv.nextBotBtn and inv.botCycleLabel and DungeonBots.GetTalkBotCycleInfo then
        local curIdx, total = DungeonBots:GetTalkBotCycleInfo(targetBot)
        if total > 0 then
            inv.botCycleLabel:SetText(string.format("|cff888888(%d/%d)|r", curIdx, total))
        else
            inv.botCycleLabel:SetText("|cff888888(0/0)|r")
        end
        if total >= 2 then
            inv.nextBotBtn:Enable()
        else
            inv.nextBotBtn:Disable()
        end
    end

    UpdateSlotSelectionUI()
end

function DungeonBots:OpenInventoryDialog(botName)
    if not DungeonBots.inventoryFrame then
        DungeonBots:BuildInventoryDialog()
    end
    local inv = DungeonBots.inventoryFrame
    if inv.currentBot ~= botName then
        ClearSelectedItems(inv)
        if inv.searchBox then
            inv.searchBox:SetText("")
        end
    end
    inv.currentBot = botName
    DungeonBots:UpdateInventoryDialog(botName)
    inv:Show()
    if inv.Raise then
        pcall(inv.Raise, inv)
    end
end
