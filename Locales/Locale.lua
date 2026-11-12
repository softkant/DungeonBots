-- =========================================================================
-- DungeonBots_Locale.lua: Localización Automática según Idioma del Cliente
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal

local function NowTime()
    return DB_Internal.NowTime and DB_Internal.NowTime() or ((GetTime and GetTime()) or 0)
end

local function TrimText(str)
    if DB_Internal.TrimText then
        return DB_Internal.TrimText(str)
    end
    return str and string.gsub(str, "^%s*(.-)%s*$", "%1") or ""
end

local function StripWowFormatting(text)
    return DungeonBots.StripChatFormatting and DungeonBots:StripChatFormatting(text) or (text or "")
end

-- =========================================================================
-- Detección de Idioma del Cliente
-- =========================================================================
function DungeonBots:GetClientLocale()
    if GetLocale then
        return GetLocale() or "enUS"
    end
    return "enUS"
end

function DungeonBots:IsSpanishLocale()
    local loc = DungeonBots:GetClientLocale()
    return (loc == "esES" or loc == "esMX")
end

function DungeonBots:IsNonEnglishLocale()
    local loc = DungeonBots:GetClientLocale()
    return (loc ~= "enUS" and loc ~= "enGB")
end

-- =========================================================================
-- Localización de Clases y Especializaciones (Solo Visual, No Comandos)
-- =========================================================================
function DungeonBots:GetLocalizedClassName(classToken, compactName)
    if not classToken or classToken == "" then return nil end
    if compactName and classToken == "DEATHKNIGHT" and DungeonBots:IsSpanishLocale() then
        return "C. de la Muerte"
    end
    if _G.LOCALIZED_CLASS_NAMES_MALE and _G.LOCALIZED_CLASS_NAMES_MALE[classToken] then
        return _G.LOCALIZED_CLASS_NAMES_MALE[classToken]
    end
    return nil
end

function DungeonBots:LocalizeSpecText(specText)
    if not specText or specText == "" then return "" end
    local plain = TrimText(StripWowFormatting(specText))
    if plain == "" then return "" end
    local tokenList = DB_Internal.ES_SPEC_TOKENS
    if not DungeonBots:IsSpanishLocale() or type(tokenList) ~= "table" then
        return plain
    end

    local lower = string.lower(plain)
    lower = string.gsub(lower, "[_%-]+", " ")
    lower = string.gsub(lower, "%s+", " ")

    local normalized = " " .. lower .. " "
    for _, entry in ipairs(tokenList) do
        local searchKey = " " .. entry.pat .. " "
        local startPos, endPos = string.find(normalized, searchKey, 1, true)
        while startPos do
            normalized = string.sub(normalized, 1, startPos) .. entry.es .. string.sub(normalized, endPos)
            startPos, endPos = string.find(normalized, searchKey, startPos + #entry.es, true)
        end
    end

    local result = TrimText(normalized)
    if result == lower then
        return plain
    end
    return result
end

function DungeonBots:LocalizeServerHint(rawText, kind)
    local clean = TrimText(StripWowFormatting(rawText or ""))
    if clean == "" then return clean end

    local L = DungeonBots.L or {}
    local lower = string.lower(clean)

    if kind == "glyphs" or string.find(lower, "glyph", 1, true) then
        if string.find(lower, "no glyph", 1, true)
            or string.find(lower, "0 glyph", 1, true)
            or string.find(lower, "glyphs: none", 1, true)
            or lower == "none"
            or lower == "nothing" then
            return L["NO_GLYPHS_EQUIPPED"] or clean
        end
    end

    if kind == "spells" or string.find(lower, "spell", 1, true) then
        if string.find(lower, "no spell", 1, true)
            or string.find(lower, "0 spell", 1, true)
            or string.find(lower, "nothing found", 1, true)
            or lower == "none" then
            return L["NO_SPELLS_FOUND"] or clean
        end
    end

    if kind == "quests" or string.find(lower, "quest", 1, true) then
        if string.find(lower, "quest log is empty", 1, true) then
            return L["QUEST_LOG_EMPTY"] or clean
        elseif string.find(lower, "no completed quests", 1, true) then
            return L["NO_COMPLETED_QUESTS"] or clean
        elseif string.find(lower, "no active quests", 1, true)
            or string.find(lower, "0 active quests", 1, true)
            or string.find(lower, "you have no quests", 1, true)
            or string.find(lower, "you don't have any quests", 1, true)
            or string.find(lower, "has no quests", 1, true)
            or lower == "no quests"
            or lower == "none" then
            return L["NO_ACTIVE_QUESTS"] or clean
        end
    end

    if kind == "inventory" then
        if string.find(lower, "no items", 1, true)
            or lower == "empty"
            or lower == "none" then
            return L["INVENTORY_EMPTY"] or clean
        end
    end

    return clean
end

function DungeonBots:LocalizeServerSection(rawText)
    local clean = TrimText(StripWowFormatting(rawText or ""))
    if clean == "" then return clean end
    if not DungeonBots:IsSpanishLocale() then return clean end

    local L = DungeonBots.L or {}
    local lower = string.lower(clean)
    local secMap = DB_Internal.ES_SERVER_SECTIONS
    if secMap and secMap[lower] then
        return secMap[lower]
    end

    if string.find(lower, "^money:%s*") then
        return string.gsub(clean, "^[Mm]oney:", L["MONEY_PREFIX"] or "Dinero:")
    elseif string.find(lower, "^free%s+slots:%s*") then
        return string.gsub(clean, "^[Ff]ree%s+[Ss]lots:", L["FREE_SLOTS_PREFIX"] or "Espacios libres:")
    elseif string.find(lower, "^slots:%s*") then
        return string.gsub(clean, "^[Ss]lots:", L["SLOTS_PREFIX"] or "Espacios:")
    elseif string.find(lower, "ready to turn in", 1, true) then
        return string.gsub(clean, "[Rr]eady to turn in", L["STATUS_READY"] or "Lista para entregar")
    elseif string.find(lower, "incomplete", 1, true) then
        return string.gsub(clean, "[Ii]ncomplete", L["STATUS_INCOMPLETE"] or "Incompleta")
    elseif string.find(lower, "complete", 1, true) then
        return string.gsub(clean, "[Cc]omplete", L["STATUS_COMPLETE"] or "Completa")
    elseif string.find(lower, "failed", 1, true) then
        return string.gsub(clean, "[Ff]ailed", L["STATUS_FAILED"] or "Fallida")
    end

    return clean
end

-- =========================================================================
-- Tooltip Oculto de Consulta al Cliente / WDB y Cola Asíncrona
-- =========================================================================
local scanTip = nil
local pendingLocaleResolves = {}
local localeResolveFrame = CreateFrame("Frame")
localeResolveFrame:Hide()

local RETRY_DELAYS = { 0.25, 0.50, 0.85, 1.30, 2.00, 3.00 }

local function EnsureScanTooltip()
    if scanTip then return scanTip end
    scanTip = CreateFrame("GameTooltip", "DungeonBots_LocaleScanTooltip", nil, "GameTooltipTemplate")
    scanTip:SetOwner(WorldFrame or UIParent, "ANCHOR_NONE")
    return scanTip
end

local function IsPlaceholderTooltipText(text)
    if not text then return true end
    local trimmed = TrimText(text)
    if trimmed == "" then return true end
    local lower = string.lower(trimmed)
    if _G.RETRIEVING_DATA and lower == string.lower(_G.RETRIEVING_DATA) then return true end
    if _G.RETRIEVING_ITEM_INFO and lower == string.lower(_G.RETRIEVING_ITEM_INFO) then return true end
    if _G.UNKNOWN and lower == string.lower(_G.UNKNOWN) then return true end
    if _G.UNKNOWNOBJECT and lower == string.lower(_G.UNKNOWNOBJECT) then return true end
    if string.find(lower, "^retrieving")
        or string.find(lower, "^recuperando")
        or string.find(lower, "^obteniendo")
        or string.find(lower, "^cargando")
        or lower == "loading..."
        or lower == "loading"
        or lower == "unknown"
        or lower == "desconocido" then
        return true
    end
    return false
end
DB_Internal.IsPlaceholderTooltipText = IsPlaceholderTooltipText

local function ScanHyperlinkTitle(hyperlink)
    if not hyperlink or hyperlink == "" then return nil end
    local tip = EnsureScanTooltip()
    tip:SetOwner(WorldFrame or UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    local ok = pcall(tip.SetHyperlink, tip, hyperlink)
    if not ok then
        tip:Hide()
        return nil
    end
    local left1 = _G["DungeonBots_LocaleScanTooltipTextLeft1"]
    local text = left1 and left1:GetText() or nil
    tip:Hide()
    if IsPlaceholderTooltipText(text) then
        return nil
    end
    return TrimText(text)
end

local function QueueLocaleResolve(kind, idStr, extra)
    if not kind or not idStr or idStr == "" then return end
    local key = kind .. ":" .. idStr
    if pendingLocaleResolves[key] then return end
    pendingLocaleResolves[key] = {
        kind = kind,
        id = idStr,
        extra = extra,
        tries = 0,
        nextAt = NowTime() + RETRY_DELAYS[1],
    }
    localeResolveFrame:Show()
end

function DB_Internal.QueueItemLocaleResolution(itemId)
    local idNum = itemId and tonumber(itemId) or nil
    if not idNum then return end
    QueueLocaleResolve("item", tostring(idNum), nil)
end

-- =========================================================================
-- Resolución Localizada de Misiones, Objetos y Hechizos
-- =========================================================================
function DungeonBots:GetLocalizedQuestTitle(questId, questLevel, fallbackTitle, skipQueue)
    if not DungeonBots:IsNonEnglishLocale() then
        return fallbackTitle
    end
    local qIdNum = questId and tonumber(questId) or nil
    if not qIdNum then
        return fallbackTitle
    end
    local qIdStr = tostring(qIdNum)

    DungeonBots.localizedQuestTitles = DungeonBots.localizedQuestTitles or {}
    local cached = DungeonBots.localizedQuestTitles[qIdStr]
    if cached and cached ~= "" and not IsPlaceholderTooltipText(cached) then
        return cached
    end
    if cached then
        DungeonBots.localizedQuestTitles[qIdStr] = nil
    end

    -- 1. Consultar el registro de misiones del propio jugador
    if GetNumQuestLogEntries and GetQuestLogTitle then
        local numEntries = GetNumQuestLogEntries() or 0
        for i = 1, numEntries do
            local logTitle, _, _, _, isHeader, _, _, _, logQuestId = GetQuestLogTitle(i)
            if not isHeader and logTitle and logTitle ~= "" and not IsPlaceholderTooltipText(logTitle) then
                local matched = (logQuestId and tonumber(logQuestId) == qIdNum)
                if not matched and GetQuestLink then
                    local qLink = GetQuestLink(i)
                    local linkId = qLink and string.match(qLink, "|Hquest:(%d+):")
                    if linkId and linkId == qIdStr then
                        matched = true
                    end
                end
                if matched then
                    DungeonBots.localizedQuestTitles[qIdStr] = logTitle
                    return logTitle
                end
            end
        end
    end

    -- 2. Consultar cache/WDB mediante tooltip oculto (dispara CMSG_QUEST_QUERY si no está en caché)
    local lvlStr = (questLevel and questLevel ~= "") and tostring(questLevel) or "80"
    local scanned = ScanHyperlinkTitle("quest:" .. qIdStr .. ":" .. lvlStr)
    if scanned and scanned ~= "" then
        DungeonBots.localizedQuestTitles[qIdStr] = scanned
        return scanned
    end

    -- 3. Reintentar brevemente mientras el servidor responde a CMSG_QUEST_QUERY
    if not skipQueue then
        QueueLocaleResolve("quest", qIdStr, lvlStr)
    end
    return fallbackTitle
end

function DungeonBots:GetLocalizedItemName(itemId, fallbackName, skipQueue)
    if not DungeonBots:IsNonEnglishLocale() then
        return fallbackName
    end
    local idNum = itemId and tonumber(itemId) or nil
    if not idNum then
        return fallbackName
    end
    local idStr = tostring(idNum)

    DungeonBots.localizedItemNames = DungeonBots.localizedItemNames or {}
    local cached = DungeonBots.localizedItemNames[idStr]
    if cached and cached ~= "" and not IsPlaceholderTooltipText(cached) then
        return cached
    end
    if cached then
        DungeonBots.localizedItemNames[idStr] = nil
    end

    if GetItemInfo then
        local itemName = GetItemInfo(idNum)
        if itemName and itemName ~= "" and not IsPlaceholderTooltipText(itemName) then
            DungeonBots.localizedItemNames[idStr] = itemName
            return itemName
        end
    end

    local scanned = ScanHyperlinkTitle("item:" .. idStr .. ":0:0:0:0:0:0:0")
    if scanned and scanned ~= "" then
        DungeonBots.localizedItemNames[idStr] = scanned
        return scanned
    end

    if not skipQueue then
        QueueLocaleResolve("item", idStr, nil)
    end
    return fallbackName
end

function DungeonBots:GetLocalizedSpellName(spellId, fallbackName)
    if not DungeonBots:IsNonEnglishLocale() then
        return fallbackName
    end
    local idNum = spellId and tonumber(spellId) or nil
    if not idNum or not GetSpellInfo then
        return fallbackName
    end
    local spellName = GetSpellInfo(idNum)
    if spellName and spellName ~= "" and not IsPlaceholderTooltipText(spellName) then
        return spellName
    end
    return fallbackName
end

function DungeonBots:LocalizeHyperlinksInText(text, skipQueue)
    if not text or text == "" then return text end
    if not DungeonBots:IsNonEnglishLocale() then return text end

    local localized = text
    if string.find(localized, "|Hquest:", 1, true) then
        localized = string.gsub(localized, "|Hquest:(%d+):(-?%d*)|h%[([^%]]+)%]|h", function(qId, qLvl, qTitle)
            local resolved = DungeonBots:GetLocalizedQuestTitle(qId, qLvl, qTitle, skipQueue)
            return "|Hquest:" .. qId .. ":" .. qLvl .. "|h[" .. (resolved or qTitle) .. "]|h"
        end)
    end
    if string.find(localized, "|Hitem:", 1, true) then
        localized = string.gsub(localized, "|Hitem:(%d+)([^|]*)|h%[([^%]]+)%]|h", function(itemId, rest, itemName)
            local resolved = DungeonBots:GetLocalizedItemName(itemId, itemName, skipQueue)
            return "|Hitem:" .. itemId .. rest .. "|h[" .. (resolved or itemName) .. "]|h"
        end)
    end
    if string.find(localized, "|Hspell:", 1, true) then
        localized = string.gsub(localized, "|Hspell:(%d+)|h%[([^%]]+)%]|h", function(spellId, spellName)
            local resolved = DungeonBots:GetLocalizedSpellName(spellId, spellName)
            return "|Hspell:" .. spellId .. "|h[" .. (resolved or spellName) .. "]|h"
        end)
    end
    return localized
end

-- =========================================================================
-- Refresco en Vivo de Ventanas Abiertas tras Cacheo Asíncrono
-- =========================================================================
function DungeonBots:ApplyCachedLocaleToStoredDialogs()
    if DungeonBots.questDialogData then
        for botName, data in pairs(DungeonBots.questDialogData) do
            if data and type(data.quests) == "table" then
                local changed = false
                for _, q in ipairs(data.quests) do
                    if q.questId then
                        local resolvedTitle = DungeonBots:GetLocalizedQuestTitle(q.questId, q.questLevel, nil, true)
                        if resolvedTitle and resolvedTitle ~= "" and resolvedTitle ~= q.title then
                            q.title = resolvedTitle
                            changed = true
                        end
                    end
                    local baseLink = q.rawDisplayLink or q.displayLink
                    if baseLink and baseLink ~= "" then
                        local newLink = DungeonBots:LocalizeHyperlinksInText(baseLink, true)
                        if newLink ~= q.displayLink then
                            q.displayLink = newLink
                            changed = true
                        end
                    end
                end
                if changed and DB_Internal.IsQuestDialogOpenFor and DB_Internal.IsQuestDialogOpenFor(botName) and DungeonBots.UpdateQuestDialog then
                    DungeonBots:UpdateQuestDialog(botName)
                end
            end
        end
    end

    if DungeonBots.talkDialogData then
        for botName, data in pairs(DungeonBots.talkDialogData) do
            if data then
                local changed = false
                if type(data.actions) == "table" then
                    for _, act in ipairs(data.actions) do
                        if act.kind == "quest" then
                            if act.questId then
                                local resolvedTitle = DungeonBots:GetLocalizedQuestTitle(act.questId, act.questLevel, nil, true)
                                if resolvedTitle and resolvedTitle ~= "" and resolvedTitle ~= act.title then
                                    act.title = resolvedTitle
                                    act.label = resolvedTitle
                                    changed = true
                                end
                            end
                            local baseLink = act.rawDisplayLink or act.displayLink
                            if baseLink and baseLink ~= "" then
                                local newLink = DungeonBots:LocalizeHyperlinksInText(baseLink, true)
                                if newLink ~= act.displayLink then
                                    act.displayLink = newLink
                                    changed = true
                                end
                            end
                        elseif act.rawBody and act.rawBody ~= "" then
                            local newLabel = TrimText(StripWowFormatting(DungeonBots:LocalizeHyperlinksInText(act.rawBody, true)))
                            if newLabel ~= "" and newLabel ~= act.label then
                                act.label = newLabel
                                changed = true
                            end
                        end
                    end
                end
                if type(data.lines) == "table" then
                    for idx, lineText in ipairs(data.lines) do
                        local localizedLine = DungeonBots:LocalizeHyperlinksInText(lineText, true)
                        if localizedLine ~= lineText then
                            data.lines[idx] = localizedLine
                            changed = true
                        end
                    end
                end
                if changed and DungeonBots.UpdateTalkDialog and DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown() and DungeonBots.talkFrame.currentBot == botName then
                    DungeonBots:UpdateTalkDialog(botName)
                end
            end
        end
    end

    if DB_Internal.RefreshInventoryItemVisuals then
        DB_Internal.RefreshInventoryItemVisuals(true)
    end
    if DB_Internal.RefreshSpellVisuals then
        DB_Internal.RefreshSpellVisuals(true)
    end
end

localeResolveFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = NowTime()
    local hasPending = false
    local resolvedAny = false

    for key, req in pairs(pendingLocaleResolves) do
        if now >= (req.nextAt or 0) then
            local resolved = nil
            if req.kind == "quest" then
                resolved = DungeonBots:GetLocalizedQuestTitle(req.id, req.extra, nil, true)
            elseif req.kind == "item" then
                resolved = DungeonBots:GetLocalizedItemName(req.id, nil, true)
                if (not resolved or resolved == "") and GetItemInfo then
                    local idNum = tonumber(req.id)
                    local itemName = idNum and GetItemInfo(idNum)
                    if itemName and itemName ~= "" and not IsPlaceholderTooltipText(itemName) then
                        resolved = itemName
                    end
                end
                if not resolved or resolved == "" then
                    local scanned = ScanHyperlinkTitle("item:" .. tostring(req.id) .. ":0:0:0:0:0:0:0")
                    if scanned and scanned ~= "" then
                        resolved = scanned
                    end
                end
            end

            if resolved and resolved ~= "" then
                pendingLocaleResolves[key] = nil
                resolvedAny = true
            else
                req.tries = (req.tries or 0) + 1
                if req.tries >= #RETRY_DELAYS then
                    pendingLocaleResolves[key] = nil
                else
                    req.nextAt = now + RETRY_DELAYS[req.tries + 1]
                    hasPending = true
                end
            end
        else
            hasPending = true
        end
    end

    if resolvedAny then
        DungeonBots:ApplyCachedLocaleToStoredDialogs()
    end

    if not hasPending then
        self:Hide()
    end
end)
