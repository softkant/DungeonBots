-- =========================================================================
-- DungeonBots_Inventory.lua: Consulta, Parser y Destrucción de Inventario
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal
local L = DungeonBots.L or {}

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
    local rawName = entry.rawName or entry.name or (DungeonBots.L and DungeonBots.L["ITEM_DEFAULT"]) or "Item"

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
        local rawName = string.match(m.plainH, "|h%[([^%]]+)%]|h") or (DungeonBots.L and DungeonBots.L["ITEM_DEFAULT"]) or "Item"

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
            category = currentCategory or (DungeonBots.L and DungeonBots.L["CAT_GENERAL"]) or "General",
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
        or string.find(lowerClean, "no active quests", 1, true)
        or string.find(lowerClean, "summary", 1, true)
        or string.match(lowerClean, "incompleted?:%s*%d+")
        or string.match(lowerClean, "total%s*:%s*%d+") then
        return true
    end
    return false
end

DungeonBots.pendingDestroyRequests = DungeonBots.pendingDestroyRequests or {}
DungeonBots.pendingDestroyQueues = DungeonBots.pendingDestroyQueues or {}
DungeonBots.pendingDestroyBatches = DungeonBots.pendingDestroyBatches or {}

local MAX_DESTROY_ITEMS = 5
DB_Internal.MAX_DESTROY_ITEMS = MAX_DESTROY_ITEMS

local function NotifyDestroyDialogChanged(cleanBot)
    local inv = DungeonBots.inventoryFrame
    if inv and inv:IsShown() and inv.currentBot == cleanBot and DungeonBots.UpdateInventoryDialog then
        DungeonBots:UpdateInventoryDialog(cleanBot)
    end
end

local function AdvanceDestroyBatchDone(cleanBot)
    local batch = DungeonBots.pendingDestroyBatches and DungeonBots.pendingDestroyBatches[cleanBot]
    if batch then
        batch.done = (batch.done or 0) + 1
    end
end

function DungeonBots:GetDestroyInventoryProgress(botName)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot then return false, 0, 0 end
    local req = DungeonBots.pendingDestroyRequests and DungeonBots.pendingDestroyRequests[cleanBot]
    local q = DungeonBots.pendingDestroyQueues and DungeonBots.pendingDestroyQueues[cleanBot]
    local hasQueued = (q and q.items and #q.items > 0) and true or false
    if not req and not hasQueued then
        if DungeonBots.pendingDestroyBatches then
            DungeonBots.pendingDestroyBatches[cleanBot] = nil
        end
        return false, 0, 0
    end
    local batch = DungeonBots.pendingDestroyBatches and DungeonBots.pendingDestroyBatches[cleanBot]
    local total = (batch and batch.total) or ((req and 1 or 0) + ((q and q.items) and #q.items or 0))
    local done = (batch and batch.done) or 0
    local current = math.min(math.max(1, total), math.max(1, done + 1))
    return true, current, total
end

function DungeonBots:IsDestroyingBotInventory(botName)
    local active = self:GetDestroyInventoryProgress(botName)
    return active
end

local function NormalizeItemPayloadColons(payload)
    if not payload or payload == "" then return nil end
    local parts = {}
    for seg in string.gmatch(payload .. ":", "([^:]*):") do
        table.insert(parts, seg)
    end
    if parts[1] ~= "item" or not tonumber(parts[2]) then
        return nil
    end
    for i = 3, 9 do
        if not parts[i] or parts[i] == "" then
            parts[i] = "0"
        end
    end
    if not parts[10] or parts[10] == "" then
        parts[10] = "80"
    end
    local out = {}
    for i = 1, 10 do
        out[i] = parts[i]
    end
    return table.concat(out, ":")
end

local function NormalizeColorHexForLink(colorHex)
    if type(colorHex) == "string" and string.match(colorHex, "^|c%x%x%x%x%x%x%x%x$") then
        if string.lower(string.sub(colorHex, 1, 4)) == "|c00" then
            return "|cff" .. string.sub(colorHex, 5)
        end
        return string.lower(colorHex)
    end
    return "|cffffffff"
end

local function BuildDestroyCommandLink(itemEntry)
    if not itemEntry then return nil end

    -- 1) Preferir GetItemInfo(itemId), que produce el mismo enlace 3.3.5a que Shift-Click
    if itemEntry.itemId and GetItemInfo then
        local _, clientLink = GetItemInfo(itemEntry.itemId)
        if type(clientLink) == "string"
            and string.match(clientLink, "^|c%x%x%x%x%x%x%x%x|Hitem:%d+:")
            and string.len("destroy " .. clientLink) <= 250 then
            return clientLink
        end
    end

    -- 2) Respaldo normalizando enlace crudo del bot (9 campos tras item:, color |cff..., cierre |r)
    local rawSrc = itemEntry.rawLink or itemEntry.plainLink
    if type(rawSrc) == "string" and rawSrc ~= "" then
        local colorPrefix = string.match(rawSrc, "^(|c%x%x%x%x%x%x%x%x)") or itemEntry.colorHex
        local payload, bracketName = string.match(rawSrc, "|H(item:[^|]+)|h%[([^%]]+)%]|h")
        if payload then
            local normPayload = NormalizeItemPayloadColons(payload)
            if normPayload then
                local cleanColor = NormalizeColorHexForLink(colorPrefix)
                local safeName = (bracketName and bracketName ~= "") and bracketName or (itemEntry.rawName or itemEntry.name or "item")
                local candidate = cleanColor .. "|H" .. normPayload .. "|h[" .. safeName .. "]|h|r"
                if string.len("destroy " .. candidate) <= 250 then
                    return candidate
                end
            end
        end
    end

    local fallbackName = itemEntry.rawName or itemEntry.name or "item"
    return "[" .. fallbackName .. "]"
end

local function CountInventoryItemsByIdOrName(botName, itemId, rawName)
    local data = DungeonBots.inventoryDialogData and DungeonBots.inventoryDialogData[botName]
    if not data or type(data.items) ~= "table" then return 0 end
    local total = 0
    for _, entry in ipairs(data.items) do
        local matched = false
        if itemId and entry.itemId == itemId then
            matched = true
        elseif (not itemId) and rawName and entry.rawName == rawName then
            matched = true
        end
        if matched then
            total = total + (tonumber(entry.count) or 1)
        end
    end
    return total
end

local function RemoveDestroyedItemFromInventoryData(botName, req)
    local data = DungeonBots.inventoryDialogData and DungeonBots.inventoryDialogData[botName]
    if not data or not data.items or not req then return false end

    local removed = false
    local removedEntry = nil
    for idx = #data.items, 1, -1 do
        if req.itemEntry and data.items[idx] == req.itemEntry then
            removedEntry = table.remove(data.items, idx)
            removed = true
            break
        end
    end

    if not removed then
        local targetId = req.itemId
        local targetRaw = req.rawName and string.lower(req.rawName) or nil
        for idx = #data.items, 1, -1 do
            local item = data.items[idx]
            if (targetId and item.itemId == targetId)
                or (targetRaw and item.rawName and string.lower(item.rawName) == targetRaw) then
                removedEntry = table.remove(data.items, idx)
                removed = true
                break
            end
        end
    end

    if not removed then return false end

    for idx, item in ipairs(data.items) do
        item.slotId = idx
    end
    data.updatedAt = NowTime()

    local inv = DungeonBots.inventoryFrame
    if inv and inv:IsShown() and inv.currentBot == botName then
        if inv.selectedItems then
            for i = #inv.selectedItems, 1, -1 do
                local sel = inv.selectedItems[i]
                if sel == req.itemEntry or (removedEntry and sel == removedEntry) then
                    table.remove(inv.selectedItems, i)
                end
            end
        end
        if DungeonBots.UpdateInventoryDialog then
            DungeonBots:UpdateInventoryDialog(botName)
        end
    end
    return true
end

local function IsExplicitDestroyMessage(lowerClean)
    return string.find(lowerClean, "destroy", 1, true) ~= nil
        or string.find(lowerClean, "destru", 1, true) ~= nil
        or string.find(lowerClean, "dropped", 1, true) ~= nil
        or string.find(lowerClean, "removed", 1, true) ~= nil
        or string.find(lowerClean, "cannot", 1, true) ~= nil
        or string.find(lowerClean, "can't", 1, true) ~= nil
        or string.find(lowerClean, "unable", 1, true) ~= nil
        or string.find(lowerClean, "not found", 1, true) ~= nil
        or string.find(lowerClean, "equipped", 1, true) ~= nil
        or string.find(lowerClean, "no se puede", 1, true) ~= nil
        or string.find(lowerClean, "no encontrado", 1, true) ~= nil
end

local function ScheduleNextQueuedDestroy(cleanBot, delaySec)
    local q = DungeonBots.pendingDestroyQueues and DungeonBots.pendingDestroyQueues[cleanBot]
    if not q or #q.items == 0 then
        if DungeonBots.pendingDestroyQueues then
            DungeonBots.pendingDestroyQueues[cleanBot] = nil
        end
        return false
    end
    local readyAt = NowTime() + (delaySec or 0.35)
    if not q.nextAt or readyAt > q.nextAt then
        q.nextAt = readyAt
    end
    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end
    return true
end

local function SendSingleDestroyRequest(cleanBot, itemEntry, isQuiet)
    local unit = DungeonBots.FindPartyUnitByName and DungeonBots:FindPartyUnitByName(cleanBot)
    if not unit or not UnitIsConnected(unit) then
        return false
    end

    local cmdLink = BuildDestroyCommandLink(itemEntry)
    if not cmdLink or cmdLink == "" then return false end

    local now = NowTime()
    local displayLink = (itemEntry.displayLink and itemEntry.displayLink ~= "") and itemEntry.displayLink or ("[" .. (itemEntry.name or itemEntry.rawName or L["ITEM_DEFAULT"]) .. "]")

    DungeonBots.pendingDestroyBatches = DungeonBots.pendingDestroyBatches or {}
    if not DungeonBots.pendingDestroyBatches[cleanBot] then
        DungeonBots.pendingDestroyBatches[cleanBot] = { total = 1, done = 0 }
    end

    DungeonBots.pendingDestroyRequests = DungeonBots.pendingDestroyRequests or {}
    DungeonBots.pendingDestroyRequests[cleanBot] = {
        itemEntry = itemEntry,
        itemId = itemEntry.itemId,
        rawName = itemEntry.rawName,
        displayLink = displayLink,
        startedAt = now,
        expiresAt = now + 5.0,
        gotReply = false,
        replyText = nil,
    }

    DungeonBots:SendWhisperCommand(cleanBot, "destroy " .. cmdLink)
    if not isQuiet then
        PlaySound("igMainMenuOptionCheckBoxOff")
        DungeonBots:Print(string.format(L["INV_SEND_DESTROY_FMT"], cleanBot, displayLink))
    end

    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end
    NotifyDestroyDialogChanged(cleanBot)
    return true
end

local function DispatchNextQueuedDestroy(cleanBot, now)
    local q = DungeonBots.pendingDestroyQueues and DungeonBots.pendingDestroyQueues[cleanBot]
    if not q or #q.items == 0 then
        if DungeonBots.pendingDestroyQueues then
            DungeonBots.pendingDestroyQueues[cleanBot] = nil
        end
        return false
    end
    if DungeonBots.pendingDestroyRequests and DungeonBots.pendingDestroyRequests[cleanBot] then
        return true
    end
    if q.nextAt and now < q.nextAt then
        return true
    end

    while #q.items > 0 do
        local nextItem = table.remove(q.items, 1)
        if SendSingleDestroyRequest(cleanBot, nextItem, q.isBatch) then
            q.nextAt = now + 0.35
            if #q.items == 0 then
                DungeonBots.pendingDestroyQueues[cleanBot] = nil
            end
            return true
        end
    end

    DungeonBots.pendingDestroyQueues[cleanBot] = nil
    if not (DungeonBots.pendingDestroyRequests and DungeonBots.pendingDestroyRequests[cleanBot]) then
        if DungeonBots.pendingDestroyBatches then
            DungeonBots.pendingDestroyBatches[cleanBot] = nil
        end
        NotifyDestroyDialogChanged(cleanBot)
    end
    return false
end

local function HandleDestroyFeedbackWhisper(cleanSender, message, now)
    local req = DungeonBots.pendingDestroyRequests and DungeonBots.pendingDestroyRequests[cleanSender]
    if not req then return false end
    if now > (req.expiresAt or 0) then
        DungeonBots.pendingDestroyRequests[cleanSender] = nil
        AdvanceDestroyBatchDone(cleanSender)
        local hasMoreQueued = ScheduleNextQueuedDestroy(cleanSender, 0.25)
        if not hasMoreQueued and DungeonBots.pendingDestroyBatches then
            DungeonBots.pendingDestroyBatches[cleanSender] = nil
        end
        NotifyDestroyDialogChanged(cleanSender)
        return false
    end
    if not message or message == "" or IsInventoryNoiseOrWrongResponse(message) then
        return false
    end

    local localizedMsg = (DungeonBots.LocalizeHyperlinksInText and DungeonBots:LocalizeHyperlinksInText(message)) or message
    local cleanDisplay = TrimText(localizedMsg)
    local lowerClean = string.lower(TrimText(StripWowFormatting(localizedMsg)))
    if lowerClean == "" then return false end

    -- Ignorar líneas normales del comando de inventario 'c' si llegaran solapadas
    if string.match(lowerClean, "^===+.*===+$") or string.find(lowerClean, "^money:") then
        return false
    end

    req.replyText = cleanDisplay

    local isRefusal = string.find(lowerClean, "cannot", 1, true)
        or string.find(lowerClean, "can't", 1, true)
        or string.find(lowerClean, "unable", 1, true)
        or string.find(lowerClean, "not found", 1, true)
        or string.find(lowerClean, "nothing", 1, true)
        or string.find(lowerClean, "equipped", 1, true)
        or string.find(lowerClean, "invalid", 1, true)
        or string.find(lowerClean, "usage:", 1, true)
        or string.find(lowerClean, "no se puede", 1, true)
        or string.find(lowerClean, "no encontrado", 1, true)

    if isRefusal then
        DungeonBots.pendingDestroyRequests[cleanSender] = nil
        AdvanceDestroyBatchDone(cleanSender)
        DungeonBots:Warn(cleanSender .. ": " .. cleanDisplay)
        local hasMoreQueued = ScheduleNextQueuedDestroy(cleanSender, 0.35)
        if not hasMoreQueued and DungeonBots.pendingDestroyBatches then
            DungeonBots.pendingDestroyBatches[cleanSender] = nil
        end
        NotifyDestroyDialogChanged(cleanSender)
        return true
    end

    local isConfirm = string.find(lowerClean, "destroy", 1, true)
        or string.find(lowerClean, "destru", 1, true)
        or string.find(lowerClean, "dropped", 1, true)
        or string.find(lowerClean, "removed", 1, true)
        or string.find(message, "|Hitem:", 1, true)

    if isConfirm then
        req.gotReply = true
        DungeonBots.pendingDestroyRequests[cleanSender] = nil
        AdvanceDestroyBatchDone(cleanSender)
        local hasMoreQueued = ScheduleNextQueuedDestroy(cleanSender, 0.35)
        if not hasMoreQueued and DungeonBots.pendingDestroyBatches then
            DungeonBots.pendingDestroyBatches[cleanSender] = nil
        end
        local removedLocally = RemoveDestroyedItemFromInventoryData(cleanSender, req)
        if not removedLocally then
            NotifyDestroyDialogChanged(cleanSender)
        end
        DungeonBots:Print(string.format(L["INV_DESTROYED_FMT"], cleanSender, (req.displayLink or cleanDisplay)))
        if not hasMoreQueued and DungeonBots.QueryBotStats then
            DungeonBots:QueryBotStats(cleanSender, true)
        end
        return true
    end

    return false
end

function DB_Internal.ParseInventoryCaptureWhisper(cleanSender, message)
    local now = NowTime()
    local cap = DungeonBots.pendingInventoryCapture and DungeonBots.pendingInventoryCapture[cleanSender]
    if not cap then
        return HandleDestroyFeedbackWhisper(cleanSender, message, now)
    end

    if now > (cap.expiresAt or 0) then
        DungeonBots.pendingInventoryCapture[cleanSender] = nil
        return HandleDestroyFeedbackWhisper(cleanSender, message, now)
    end

    if not message or message == "" or IsInventoryNoiseOrWrongResponse(message) then
        return false
    end

    local cleanFull = TrimText(StripWowFormatting(message))
    local lowerFull = string.lower(cleanFull)
    if DungeonBots.pendingDestroyRequests and DungeonBots.pendingDestroyRequests[cleanSender] and IsExplicitDestroyMessage(lowerFull) then
        if HandleDestroyFeedbackWhisper(cleanSender, message, now) then
            return true
        end
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
                    cap.sawHeader = true
                    cap.currentCategory = (DungeonBots.L and DungeonBots.L["CAT_GENERAL"]) or "General"
                else
                    cap.currentCategory = (DungeonBots.LocalizeServerSection and DungeonBots:LocalizeServerSection(headerText)) or headerText
                end
            elseif string.find(line, "|Hitem:", 1, true) then
                matchedRelevantLine = true
                local entries = ExtractItemEntriesFromLine(line, cap.currentCategory)
                if entries then
                    for _, item in ipairs(entries) do
                        item.slotId = #cap.items + 1
                        table.insert(cap.items, item)
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
                    cap.moneyText = (DungeonBots.LocalizeServerSection and DungeonBots:LocalizeServerSection(cleanLine)) or cleanLine
                elseif string.find(lowerClean, "slots", 1, true) then
                    cap.slotsText = (DungeonBots.LocalizeServerSection and DungeonBots:LocalizeServerSection(cleanLine)) or cleanLine
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

    if not cap.hadPrevItems then
        data.items = cap.items
        if cap.moneyText then data.moneyText = cap.moneyText end
        if cap.slotsText then data.slotsText = cap.slotsText end
        data.timedOut = false
        data.loading = (#cap.items == 0)
        data.updatedAt = now
        if DungeonBots.UpdateInventoryDialog and DungeonBots.inventoryFrame and DungeonBots.inventoryFrame:IsShown() and DungeonBots.inventoryFrame.currentBot == cleanSender then
            DungeonBots:UpdateInventoryDialog(cleanSender)
        end
    end

    return true
end

function DB_Internal.TickInventoryCapture(now)
    local hasAny = false

    if DungeonBots.pendingInventoryCapture then
        for botName, cap in pairs(DungeonBots.pendingInventoryCapture) do
            local readyToFinalize = (cap.gotAnyLine and cap.finalizeAt and now >= cap.finalizeAt)
            if readyToFinalize or now >= (cap.expiresAt or 0) then
                DungeonBots.pendingInventoryCapture[botName] = nil
                local data = DungeonBots.inventoryDialogData[botName]
                local isDialogShowing = DungeonBots.inventoryFrame and DungeonBots.inventoryFrame:IsShown() and DungeonBots.inventoryFrame.currentBot == botName
                if data then
                    if cap.gotAnyLine then
                        data.items = cap.items or data.items or {}
                        data.sawHeader = cap.sawHeader
                        if cap.moneyText then data.moneyText = cap.moneyText end
                        if cap.slotsText then data.slotsText = cap.slotsText end
                        data.timedOut = false
                        data.updatedAt = now
                    else
                        data.timedOut = true
                        if cap.hadPrevItems and isDialogShowing then
                            DungeonBots:Warn(string.format(L["INV_NO_RESP_FMT"], botName))
                        end
                    end
                    data.loading = false
                    data.done = true
                    if DungeonBots.UpdateInventoryDialog and isDialogShowing then
                        DungeonBots:UpdateInventoryDialog(botName)
                    end
                end
            else
                if DB_Internal.TryRetryWhisperCapture then
                    DB_Internal.TryRetryWhisperCapture(cap, botName, now, "c")
                end
                hasAny = true
            end
        end
    end

    if DungeonBots.pendingDestroyRequests then
        for botName, req in pairs(DungeonBots.pendingDestroyRequests) do
            if now >= (req.expiresAt or 0) then
                DungeonBots.pendingDestroyRequests[botName] = nil
                AdvanceDestroyBatchDone(botName)
                if not req.gotReply then
                    DungeonBots:Warn(string.format(L["INV_DESTROY_FAIL_FMT"], botName, (req.displayLink or L["ITEM_DEFAULT"])))
                end
                local hasMoreQueued = ScheduleNextQueuedDestroy(botName, 0.25)
                if hasMoreQueued then
                    hasAny = true
                elseif DungeonBots.pendingDestroyBatches then
                    DungeonBots.pendingDestroyBatches[botName] = nil
                end
                NotifyDestroyDialogChanged(botName)
            else
                hasAny = true
            end
        end
    end

    if DungeonBots.pendingDestroyQueues then
        for botName in pairs(DungeonBots.pendingDestroyQueues) do
            if DispatchNextQueuedDestroy(botName, now) then
                hasAny = true
            end
        end
    end

    return hasAny
end

function DungeonBots:QueryBotInventory(botName, isSilent, forceStats)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot then
        if not isSilent then
            DungeonBots:Warn(L["INV_NO_BOT_SEL"])
        end
        return
    end

    local now = NowTime()
    if DungeonBots.pendingInventoryRefresh then
        DungeonBots.pendingInventoryRefresh[cleanBot] = nil
    end

    local existingCap = DungeonBots.pendingInventoryCapture and DungeonBots.pendingInventoryCapture[cleanBot]
    if existingCap and now < (existingCap.expiresAt or 0) then
        if DungeonBots.uiCaptureFrame then
            DungeonBots.uiCaptureFrame:Show()
        end
        if not isSilent and DungeonBots.OpenInventoryDialog then
            DungeonBots:OpenInventoryDialog(cleanBot)
        elseif DungeonBots.UpdateInventoryDialog and DungeonBots.inventoryFrame and DungeonBots.inventoryFrame:IsShown() and DungeonBots.inventoryFrame.currentBot == cleanBot then
            DungeonBots:UpdateInventoryDialog(cleanBot)
        end
        return
    end

    local data = DungeonBots.inventoryDialogData[cleanBot]
    local hadPrevItems = (data and data.items and #data.items > 0) and true or false
    if not data then
        data = {
            botName = cleanBot,
            items = {},
        }
        DungeonBots.inventoryDialogData[cleanBot] = data
    end
    data.botName = cleanBot
    data.loading = true
    data.done = false
    data.timedOut = false
    data.updatedAt = now

    local unit = DungeonBots.FindPartyUnitByName and DungeonBots:FindPartyUnitByName(cleanBot)
    local canSend = (unit and UnitIsConnected(unit)) and true or false

    DungeonBots.pendingInventoryCapture[cleanBot] = {
        startedAt = now,
        expiresAt = canSend and (now + 6.0) or now,
        retryAt = canSend and (now + 2.8) or nil,
        retrySent = false,
        finalizeAt = nil,
        gotAnyLine = false,
        hadPrevItems = hadPrevItems,
        sawHeader = false,
        currentCategory = (DungeonBots.L and DungeonBots.L["CAT_GENERAL"]) or "General",
        moneyText = nil,
        slotsText = nil,
        items = {},
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
    if DungeonBots.QueryBotStats and ((not isSilent) or forceStats) then
        DungeonBots:QueryBotStats(cleanBot, true)
    end
end

function DungeonBots:CycleNextInventoryBot(currentBot)
    if not DungeonBots.GetTalkBotCycleInfo then return nil end
    local _, total, nextBot = DungeonBots:GetTalkBotCycleInfo(currentBot)
    if not nextBot or total < 2 then
        return nil
    end
    DungeonBots:QueryBotInventory(nextBot, false)
    return nextBot
end

function DungeonBots:DestroyBotItem(botName, itemEntry)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or not itemEntry then return end

    if (DungeonBots.pendingDestroyRequests and DungeonBots.pendingDestroyRequests[cleanBot])
        or (DungeonBots.pendingDestroyQueues and DungeonBots.pendingDestroyQueues[cleanBot]) then
        self:DestroyBotItems(cleanBot, { itemEntry })
        return
    end

    SendSingleDestroyRequest(cleanBot, itemEntry, false)
end

function DungeonBots:DestroyBotItems(botName, itemList)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or type(itemList) ~= "table" or #itemList == 0 then return end

    local validItems = {}
    for _, itemEntry in ipairs(itemList) do
        local cmdLink = itemEntry and BuildDestroyCommandLink(itemEntry)
        if cmdLink and cmdLink ~= "" then
            table.insert(validItems, itemEntry)
            if #validItems >= MAX_DESTROY_ITEMS then
                break
            end
        end
    end
    if #validItems == 0 then return end

    local hasActive = (DungeonBots.pendingDestroyRequests and DungeonBots.pendingDestroyRequests[cleanBot])
        or (DungeonBots.pendingDestroyQueues and DungeonBots.pendingDestroyQueues[cleanBot])
    if #validItems == 1 and not hasActive then
        SendSingleDestroyRequest(cleanBot, validItems[1], false)
        return
    end

    DungeonBots.pendingDestroyQueues = DungeonBots.pendingDestroyQueues or {}
    local queue = DungeonBots.pendingDestroyQueues[cleanBot]
    if not queue then
        queue = { items = {}, nextAt = NowTime(), isBatch = (#validItems > 1) }
        DungeonBots.pendingDestroyQueues[cleanBot] = queue
    elseif #validItems > 1 then
        queue.isBatch = true
    end

    local seen = {}
    for _, queuedItem in ipairs(queue.items) do
        seen[queuedItem] = true
    end
    local added = 0
    for _, itemEntry in ipairs(validItems) do
        if not seen[itemEntry] then
            seen[itemEntry] = true
            table.insert(queue.items, itemEntry)
            added = added + 1
        end
    end
    if added == 0 then return end

    DungeonBots.pendingDestroyBatches = DungeonBots.pendingDestroyBatches or {}
    local batch = DungeonBots.pendingDestroyBatches[cleanBot]
    if not batch then
        DungeonBots.pendingDestroyBatches[cleanBot] = { total = added, done = 0 }
    else
        batch.total = (batch.total or 0) + added
    end

    if added > 1 then
        PlaySound("igMainMenuOptionCheckBoxOff")
        DungeonBots:Print(string.format(L["INV_SEND_DESTROY_BATCH_FMT"], cleanBot, added))
    end

    DispatchNextQueuedDestroy(cleanBot, NowTime())
    NotifyDestroyDialogChanged(cleanBot)
end
