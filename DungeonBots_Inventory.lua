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

DungeonBots.pendingDestroyRequests = DungeonBots.pendingDestroyRequests or {}

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

local function HandleDestroyFeedbackWhisper(cleanSender, message, now)
    local req = DungeonBots.pendingDestroyRequests and DungeonBots.pendingDestroyRequests[cleanSender]
    if not req then return false end
    if now > (req.expiresAt or 0) then
        DungeonBots.pendingDestroyRequests[cleanSender] = nil
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
        DungeonBots:Warn(cleanSender .. ": " .. cleanDisplay)
        return true
    end

    local isConfirm = string.find(lowerClean, "destroy", 1, true)
        or string.find(lowerClean, "destru", 1, true)
        or string.find(lowerClean, "dropped", 1, true)
        or string.find(lowerClean, "removed", 1, true)
        or string.find(message, "|Hitem:", 1, true)

    if isConfirm then
        req.gotReply = true
        if DungeonBots.pendingInventoryRefresh and DungeonBots.pendingInventoryRefresh[cleanSender] then
            DungeonBots.pendingInventoryRefresh[cleanSender] = math.min(
                DungeonBots.pendingInventoryRefresh[cleanSender],
                now + 0.45
            )
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
                    if DungeonBots.UpdateInventoryDialog and DungeonBots.inventoryFrame and DungeonBots.inventoryFrame:IsShown() and DungeonBots.inventoryFrame.currentBot == botName then
                        DungeonBots:UpdateInventoryDialog(botName)
                    end
                end

                local req = DungeonBots.pendingDestroyRequests and DungeonBots.pendingDestroyRequests[botName]
                local waitingForRefresh = DungeonBots.pendingInventoryRefresh and DungeonBots.pendingInventoryRefresh[botName]
                if req and not waitingForRefresh then
                    DungeonBots.pendingDestroyRequests[botName] = nil
                    if cap.gotAnyLine then
                        local afterCount = CountInventoryItemsByIdOrName(botName, req.itemId, req.rawName)
                        if (req.prevTotalCount or 0) > 0 and afterCount < req.prevTotalCount then
                            DungeonBots:Print("|cffffd200" .. botName .. "|r destruyó: " .. req.displayLink)
                        elseif req.replyText and req.replyText ~= "" then
                            DungeonBots:Warn(botName .. ": " .. req.replyText)
                        else
                            DungeonBots:Warn(botName .. " no pudo destruir " .. req.displayLink .. " (es posible que esté equipado o bloqueado).")
                        end
                    elseif req.gotReply then
                        DungeonBots:Print("|cffffd200" .. botName .. "|r destruyó: " .. req.displayLink)
                    else
                        DungeonBots:Warn("No se pudo confirmar si " .. botName .. " destruyó " .. req.displayLink .. " (sin respuesta al refrescar inventario).")
                    end
                end
            else
                hasAny = true
            end
        end
    end

    if DungeonBots.pendingDestroyRequests then
        for botName, req in pairs(DungeonBots.pendingDestroyRequests) do
            local hasPendingRefresh = DungeonBots.pendingInventoryRefresh and DungeonBots.pendingInventoryRefresh[botName]
            local hasPendingCapture = DungeonBots.pendingInventoryCapture and DungeonBots.pendingInventoryCapture[botName]
            if now >= (req.expiresAt or 0) and not hasPendingRefresh and not hasPendingCapture then
                DungeonBots.pendingDestroyRequests[botName] = nil
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
    if not isSilent and DungeonBots.QueryBotStats then
        DungeonBots:QueryBotStats(cleanBot, false)
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

    local cmdLink = BuildDestroyCommandLink(itemEntry)
    if not cmdLink or cmdLink == "" then return end

    local now = NowTime()
    local displayLink = (itemEntry.displayLink and itemEntry.displayLink ~= "") and itemEntry.displayLink or ("[" .. (itemEntry.name or itemEntry.rawName or "Objeto") .. "]")
    local prevTotalCount = CountInventoryItemsByIdOrName(cleanBot, itemEntry.itemId, itemEntry.rawName)

    DungeonBots.pendingDestroyRequests = DungeonBots.pendingDestroyRequests or {}
    DungeonBots.pendingDestroyRequests[cleanBot] = {
        itemId = itemEntry.itemId,
        rawName = itemEntry.rawName,
        prevTotalCount = prevTotalCount,
        displayLink = displayLink,
        startedAt = now,
        expiresAt = now + 5.5,
        gotReply = false,
        replyText = nil,
    }

    DungeonBots:SendWhisperCommand(cleanBot, "destroy " .. cmdLink)
    PlaySound("igMainMenuOptionCheckBoxOff")
    DungeonBots:Print("Enviando orden de destruir a |cffffd200" .. cleanBot .. "|r: " .. displayLink)

    DungeonBots.pendingInventoryRefresh[cleanBot] = now + 1.15
    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end
end
