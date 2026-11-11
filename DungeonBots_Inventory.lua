-- =========================================================================
-- DungeonBots_Inventory.lua: Consulta, Parser y Destrucción de Inventario
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal

local NowTime = DB_Internal.NowTime
local NormalizePlayerName = DB_Internal.NormalizePlayerName
local TrimText = DB_Internal.TrimText
local StripWowFormatting = DB_Internal.StripWowFormatting
local ExtractSafeHyperlinkFromText = DB_Internal.ExtractSafeHyperlinkFromText

local COLOR_HEX_TO_RARITY = {
    ["9d9d9d"] = 0,
    ["ffffff"] = 1,
    ["1eff00"] = 2,
    ["0070dd"] = 3,
    ["a335ee"] = 4,
    ["ff8000"] = 5,
    ["e5cc80"] = 6,
    ["e6cc80"] = 7,
}

local function InferRarityFromColorHex(colorHex)
    if not colorHex or #colorHex < 10 then return 1 end
    local rgb = string.lower(string.sub(colorHex, 5, 10))
    return COLOR_HEX_TO_RARITY[rgb] or 1
end

function DB_Internal.IsInventoryDumpMessage(message)
    if not message or message == "" then return false end
    local lowerMsg = string.lower(StripWowFormatting(message))
    if string.find(lowerMsg, "=== inventory ===", 1, true)
        or string.find(lowerMsg, "=== bank ===", 1, true)
        or string.find(lowerMsg, "=== keyring ===", 1, true)
        or string.find(lowerMsg, "inventory is empty", 1, true) then
        return true
    end
    if string.find(lowerMsg, "no items", 1, true) and string.find(lowerMsg, "inventory", 1, true) then
        return true
    end
    return false
end

local function ResolveItemEntryVisuals(entry, skipQueue)
    if not entry then return false end
    local changed = false
    local itemId = entry.itemId
    local rawName = entry.rawName or entry.name or "Objeto"

    local clientName, _, itemRarity, _, _, _, _, _, _, itemTexture
    if itemId and GetItemInfo then
        clientName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
    end

    local resolvedName = rawName
    if itemId and DungeonBots.GetLocalizedItemName then
        local locName = DungeonBots:GetLocalizedItemName(itemId, rawName, skipQueue)
        if locName and locName ~= "" then
            resolvedName = locName
        end
    elseif clientName and clientName ~= "" then
        resolvedName = clientName
    end
    if resolvedName ~= entry.name then
        entry.name = resolvedName
        changed = true
    end

    local baseLink = entry.rawLink or entry.plainLink
    if baseLink and baseLink ~= "" and DungeonBots.LocalizeHyperlinksInText then
        local locLink = DungeonBots:LocalizeHyperlinksInText(baseLink, skipQueue)
        if locLink ~= "" and locLink ~= entry.displayLink then
            entry.displayLink = locLink
            changed = true
        end
    elseif not entry.displayLink or entry.displayLink == "" then
        entry.displayLink = baseLink or ("[" .. resolvedName .. "]")
        changed = true
    end

    local resolvedIcon = itemTexture
    if (not resolvedIcon or resolvedIcon == "") and itemId and GetItemIcon then
        resolvedIcon = GetItemIcon(itemId)
    end
    if not resolvedIcon or resolvedIcon == "" then
        resolvedIcon = entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    if resolvedIcon ~= entry.icon then
        entry.icon = resolvedIcon
        changed = true
    end

    local resolvedRarity = itemRarity
    if resolvedRarity == nil then
        resolvedRarity = entry.rarity or InferRarityFromColorHex(entry.colorHex)
    end
    if resolvedRarity ~= entry.rarity then
        entry.rarity = resolvedRarity
        changed = true
    end

    return changed
end

function DB_Internal.RefreshInventoryItemVisuals(skipQueue)
    if not DungeonBots.inventoryDialogData then return end
    for botName, data in pairs(DungeonBots.inventoryDialogData) do
        if data and type(data.items) == "table" then
            local changed = false
            for _, item in ipairs(data.items) do
                if ResolveItemEntryVisuals(item, skipQueue) then
                    changed = true
                end
            end
            if changed and DungeonBots.UpdateInventoryDialog and DungeonBots.inventoryFrame and DungeonBots.inventoryFrame:IsShown() and DungeonBots.inventoryFrame.currentBot == botName then
                DungeonBots:UpdateInventoryDialog(botName)
            end
        end
    end
end

local function ParseCountAroundSegment(beforeSeg, afterSeg)
    if afterSeg and afterSeg ~= "" then
        local afterCount = string.match(afterSeg, "^%s*[xX]%s*(%d+)")
            or string.match(afterSeg, "^%s*%([xX]?(%d+)%)")
            or string.match(afterSeg, "^%s*(%d+)[xX]")
        if afterCount then
            return tonumber(afterCount) or 1
        end
    end
    if beforeSeg and beforeSeg ~= "" then
        local beforeCount = string.match(beforeSeg, "(%d+)[xX]%s*$")
            or string.match(beforeSeg, "[xX]%s*(%d+)%s*$")
        if beforeCount then
            return tonumber(beforeCount) or 1
        end
    end
    return 1
end

local function ExtractItemEntriesFromLine(line, currentCategory)
    local matches = {}
    local searchFrom = 1
    while true do
        local safeLink, sPos, ePos, plainH, colorHex = ExtractSafeHyperlinkFromText(line, "item", searchFrom)
        if not sPos then break end
        table.insert(matches, {
            safeLink = safeLink or plainH,
            sPos = sPos,
            ePos = ePos,
            plainH = plainH,
            colorHex = colorHex,
        })
        searchFrom = ePos + 1
    end

    if #matches == 0 then return nil end

    local extracted = {}
    for idx, m in ipairs(matches) do
        local beforeStart = (idx > 1) and (matches[idx - 1].ePos + 1) or 1
        local afterEnd = (idx < #matches) and (matches[idx + 1].sPos - 1) or #line
        local beforeSeg = string.sub(line, beforeStart, m.sPos - 1)
        local afterSeg = string.sub(line, m.ePos + 1, afterEnd)
        local count = ParseCountAroundSegment(beforeSeg, afterSeg)

        local itemId = tonumber(string.match(m.plainH, "|Hitem:(%d+)"))
        local rawName = string.match(m.plainH, "|h%[([^%]]+)%]|h") or "Objeto"

        local entry = {
            itemId = itemId,
            rawName = rawName,
            name = rawName,
            rawLink = m.safeLink,
            plainLink = m.plainH,
            displayLink = m.safeLink,
            colorHex = m.colorHex,
            rarity = InferRarityFromColorHex(m.colorHex),
            count = count,
            icon = nil,
            category = currentCategory or "General",
        }
        ResolveItemEntryVisuals(entry, false)
        table.insert(extracted, entry)
    end
    return extracted
end

local function IsInventoryNoiseOrWrongResponse(message)
    if DB_Internal.IsPureTalentResponse and DB_Internal.IsPureTalentResponse(message) then
        return true
    end
    if string.find(message, "|Hquest:", 1, true) and not string.find(message, "|Hitem:", 1, true) then
        return true
    end
    local lowerClean = string.lower(TrimText(StripWowFormatting(message)))
    if string.find(lowerClean, "active quests", 1, true)
        or string.find(lowerClean, "completed quests", 1, true)
        or string.find(lowerClean, "no active quests", 1, true) then
        return true
    end
    return false
end

function DB_Internal.ParseInventoryCaptureWhisper(cleanSender, message)
    local cap = DungeonBots.pendingInventoryCapture and DungeonBots.pendingInventoryCapture[cleanSender]
    if not cap then return false end

    local now = NowTime()
    if now > (cap.expiresAt or 0) then
        DungeonBots.pendingInventoryCapture[cleanSender] = nil
        return false
    end

    if not message or message == "" or IsInventoryNoiseOrWrongResponse(message) then
        return false
    end

    local data = DungeonBots.inventoryDialogData[cleanSender]
    if not data then return false end

    local matchedRelevantLine = false
    for rawLine in string.gmatch(message, "[^\r\n]+") do
        local line = TrimText(rawLine)
        local cleanLine = TrimText(StripWowFormatting(line))
        local lowerClean = string.lower(cleanLine)

        if cleanLine ~= "" then
            local headerText = string.match(cleanLine, "^===+%s*(.-)%s*===+$")
            if headerText and headerText ~= "" then
                matchedRelevantLine = true
                if string.lower(headerText) == "inventory" then
                    data.sawHeader = true
                    data.currentCategory = "General"
                else
                    data.currentCategory = headerText
                end
            elseif string.find(line, "|Hitem:", 1, true) then
                matchedRelevantLine = true
                local entries = ExtractItemEntriesFromLine(line, data.currentCategory)
                if entries then
                    for _, item in ipairs(entries) do
                        item.slotId = #data.items + 1
                        table.insert(data.items, item)
                    end
                end
            elseif string.find(lowerClean, "no items", 1, true)
                or string.find(lowerClean, "empty", 1, true)
                or string.find(lowerClean, "inventory", 1, true)
                or string.find(lowerClean, "slots", 1, true)
                or string.find(lowerClean, "^money:")
                or string.find(lowerClean, "^total:") then
                matchedRelevantLine = true
                if string.find(lowerClean, "^money:") or string.find(lowerClean, "gold", 1, true) then
                    data.moneyText = cleanLine
                elseif string.find(lowerClean, "slots", 1, true) then
                    data.slotsText = cleanLine
                end
            end
        end
    end

    if not matchedRelevantLine then
        return false
    end

    cap.gotAnyLine = true
    cap.finalizeAt = math.min((cap.startedAt or now) + 5.0, now + 0.55)
    cap.expiresAt = math.min((cap.startedAt or now) + 5.5, math.max(cap.expiresAt, now + 1.2))
    data.loading = false
    data.updatedAt = now

    if DungeonBots.UpdateInventoryDialog and DungeonBots.inventoryFrame and DungeonBots.inventoryFrame:IsShown() and DungeonBots.inventoryFrame.currentBot == cleanSender then
        DungeonBots:UpdateInventoryDialog(cleanSender)
    end
    return true
end

function DB_Internal.TickInventoryCapture(now)
    local hasAny = false

    if DungeonBots.pendingInventoryRefresh then
        for botName, refreshAt in pairs(DungeonBots.pendingInventoryRefresh) do
            if now >= refreshAt then
                DungeonBots.pendingInventoryRefresh[botName] = nil
                DungeonBots:QueryBotInventory(botName, true)
                hasAny = true
            else
                hasAny = true
            end
        end
    end

    if DungeonBots.pendingInventoryCapture then
        for botName, cap in pairs(DungeonBots.pendingInventoryCapture) do
            local readyToFinalize = (cap.gotAnyLine and cap.finalizeAt and now >= cap.finalizeAt)
            if readyToFinalize or now >= (cap.expiresAt or 0) then
                DungeonBots.pendingInventoryCapture[botName] = nil
                local data = DungeonBots.inventoryDialogData[botName]
                if data then
                    data.loading = false
                    data.done = true
                    if DungeonBots.UpdateInventoryDialog then
                        DungeonBots:UpdateInventoryDialog(botName)
                    end
                end
            else
                hasAny = true
            end
        end
    end

    return hasAny
end

function DungeonBots:QueryBotInventory(botName, isSilent)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot then
        if not isSilent then
            DungeonBots:Warn("No hay ningún bot seleccionado para consultar su inventario.")
        end
        return
    end

    local now = NowTime()
    DungeonBots.pendingInventoryRefresh[cleanBot] = nil
    DungeonBots.inventoryDialogData[cleanBot] = {
        botName = cleanBot,
        loading = true,
        done = false,
        sawHeader = false,
        currentCategory = "General",
        moneyText = nil,
        slotsText = nil,
        items = {},
        updatedAt = now,
    }
    DungeonBots.pendingInventoryCapture[cleanBot] = {
        startedAt = now,
        expiresAt = now + 3.5,
        finalizeAt = nil,
        gotAnyLine = false,
    }

    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end

    if not isSilent and DungeonBots.OpenInventoryDialog then
        DungeonBots:OpenInventoryDialog(cleanBot)
    elseif DungeonBots.UpdateInventoryDialog and DungeonBots.inventoryFrame and DungeonBots.inventoryFrame:IsShown() and DungeonBots.inventoryFrame.currentBot == cleanBot then
        DungeonBots:UpdateInventoryDialog(cleanBot)
    end

    DungeonBots:SendWhisperCommand(cleanBot, "c")
end

function DungeonBots:DestroyBotItem(botName, itemEntry)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or not itemEntry then return end

    local cmdLink = itemEntry.rawLink or itemEntry.plainLink or ("[" .. (itemEntry.rawName or "item") .. "]")
    if string.len("destroy " .. cmdLink) > 250 then
        if itemEntry.plainLink and string.len("destroy " .. itemEntry.plainLink) <= 250 then
            cmdLink = itemEntry.plainLink
        else
            cmdLink = "[" .. (itemEntry.rawName or "item") .. "]"
        end
    end

    DungeonBots:SendWhisperCommand(cleanBot, "destroy " .. cmdLink)
    PlaySound("igMainMenuOptionCheckBoxOff")

    local displayLink = (itemEntry.displayLink and itemEntry.displayLink ~= "") and itemEntry.displayLink or ("[" .. (itemEntry.name or itemEntry.rawName or "Objeto") .. "]")
    DungeonBots:Print("|cffffd200" .. cleanBot .. "|r destruyó: " .. displayLink)

    local data = DungeonBots.inventoryDialogData and DungeonBots.inventoryDialogData[cleanBot]
    if data and type(data.items) == "table" then
        for idx = #data.items, 1, -1 do
            local candidate = data.items[idx]
            if candidate == itemEntry or (itemEntry.slotId and candidate.slotId == itemEntry.slotId) then
                table.remove(data.items, idx)
                break
            end
        end
    end

    if DungeonBots.inventoryFrame and DungeonBots.inventoryFrame.selectedItem == itemEntry then
        DungeonBots.inventoryFrame.selectedItem = nil
    end

    if DungeonBots.UpdateInventoryDialog and DungeonBots.inventoryFrame and DungeonBots.inventoryFrame:IsShown() and DungeonBots.inventoryFrame.currentBot == cleanBot then
        DungeonBots:UpdateInventoryDialog(cleanBot)
    end

    DungeonBots.pendingInventoryRefresh[cleanBot] = NowTime() + 0.65
    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end
end
