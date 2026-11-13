-- =========================================================================
-- DungeonBots_Spells.lua: Consulta, Parser y Acciones de Poderes de Bots
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal
local L = DungeonBots.L or {}

local NowTime = DB_Internal.NowTime
local NormalizePlayerName = DB_Internal.NormalizePlayerName
local TrimText = DB_Internal.TrimText
local StripWowFormatting = DB_Internal.StripWowFormatting

DungeonBots.spellsDialogData = DungeonBots.spellsDialogData or {}
DungeonBots.pendingSpellsCapture = DungeonBots.pendingSpellsCapture or {}
DungeonBots.pendingSpellDetailCapture = DungeonBots.pendingSpellDetailCapture or {}

local DIFFICULTY_INFO = {
    gray   = { key = "gray",   label = L["DIFF_GRAY"],   colorHex = "|cff9d9d9d", r = 0.62, g = 0.62, b = 0.62 },
    grey   = { key = "gray",   label = L["DIFF_GRAY"],   colorHex = "|cff9d9d9d", r = 0.62, g = 0.62, b = 0.62 },
    green  = { key = "green",  label = L["DIFF_GREEN"],  colorHex = "|cff40bf40", r = 0.25, g = 0.75, b = 0.25 },
    yellow = { key = "yellow", label = L["DIFF_YELLOW"], colorHex = "|cffffff00", r = 1.00, g = 1.00, b = 0.00 },
    orange = { key = "orange", label = L["DIFF_ORANGE"], colorHex = "|cffff8040", r = 1.00, g = 0.50, b = 0.25 },
    red    = { key = "red",    label = L["DIFF_RED"],    colorHex = "|cffff4040", r = 1.00, g = 0.25, b = 0.25 },
}

local MODE_COMMANDS = {
    gear = "gear",
    spells = "spells",
    glyphs = "glyphs",
}

local function GetOrCreateBotSpellsRecord(cleanBot)
    local rec = DungeonBots.spellsDialogData[cleanBot]
    if not rec then
        rec = {
            botName = cleanBot,
            activeMode = "spells",
            spellsFilter = "",
            spellDetail = nil,
            tabs = {},
        }
        DungeonBots.spellsDialogData[cleanBot] = rec
    end
    rec.tabs = rec.tabs or {}
    return rec
end

local function GetOrCreateModeTab(cleanBot, mode)
    local rec = GetOrCreateBotSpellsRecord(cleanBot)
    local tab = rec.tabs[mode]
    if not tab then
        tab = {
            mode = mode,
            filterUsed = "",
            loading = false,
            done = false,
            sawHeader = false,
            items = {},
            lines = {},
            emptyHint = nil,
            updatedAt = 0,
            dirty = false,
            lastUiRefresh = 0,
        }
        rec.tabs[mode] = tab
    end
    return tab, rec
end

function DB_Internal.GetBotSpellTabData(botName, mode)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot then return nil, nil end
    local rec = DungeonBots.spellsDialogData[cleanBot]
    if not rec or not rec.tabs then return nil, rec end
    return rec.tabs[mode or rec.activeMode or "spells"], rec
end

local function ExtractOrderedHyperlinks(line)
    local links = {}
    if not line or line == "" then return links end

    local pos = 1
    while true do
        local hStart, hEnd, ltype, payload, bracketName = string.find(line, "|H([^:|]+):([^|]+)|h%[([^%]]+)%]|h", pos)
        if not hStart then break end

        local plainH = string.sub(line, hStart, hEnd)
        local fullStart, fullEnd = hStart, hEnd
        local safeLink = plainH
        local colorHex = nil

        if hStart > 10 then
            local colorPrefix = string.sub(line, hStart - 10, hStart - 1)
            local colorSuffix = string.sub(line, hEnd + 1, hEnd + 2)
            if string.match(colorPrefix, "^|c%x%x%x%x%x%x%x%x$") and colorSuffix == "|r" then
                colorHex = colorPrefix
                fullStart = hStart - 10
                fullEnd = hEnd + 2
                safeLink = string.sub(line, fullStart, fullEnd)
            end
        end

        table.insert(links, {
            linkType = string.lower(ltype or ""),
            payload = payload or "",
            rawName = bracketName or "",
            plainH = plainH,
            safeLink = safeLink,
            colorHex = colorHex,
            sPos = fullStart,
            ePos = fullEnd,
        })
        pos = fullEnd + 1
    end

    return links
end

local function ResolveSpellEntryVisuals(entry, skipQueue)
    if not entry then return false end
    local changed = false

    if entry.spellId and GetSpellInfo then
        local locName, rank, icon, cost, _, powerType, castTime, _, maxRange = GetSpellInfo(entry.spellId)
        if locName and locName ~= "" and entry.name ~= locName then
            entry.name = locName
            changed = true
        end
        if rank and rank ~= "" and entry.rank ~= rank then
            entry.rank = rank
            changed = true
        end
        if icon and icon ~= "" and entry.icon ~= icon then
            entry.icon = icon
            changed = true
        end
        if cost ~= nil and entry.cost ~= cost then
            entry.cost = cost
            entry.powerType = powerType
            changed = true
        end
        if castTime ~= nil and entry.castTime ~= castTime then
            entry.castTime = castTime
            changed = true
        end
        if maxRange ~= nil and entry.maxRange ~= maxRange then
            entry.maxRange = maxRange
            changed = true
        end
    elseif entry.itemId and GetItemInfo then
        local isPh = DB_Internal.IsPlaceholderTooltipText
        if isPh and isPh(entry.name) and entry.rawName and entry.rawName ~= "" and not isPh(entry.rawName) then
            entry.name = entry.rawName
            changed = true
        end
        if isPh and isPh(entry.displayLink) and entry.rawLink and entry.rawLink ~= "" and not isPh(entry.rawLink) then
            entry.displayLink = entry.rawLink
            changed = true
        end
        local locName, locLink, _, _, _, _, _, _, _, icon = GetItemInfo(entry.itemId)
        local validLocName = locName and locName ~= "" and not (isPh and isPh(locName))
        local validLocLink = locLink and locLink ~= "" and not (isPh and isPh(locLink))
        if not validLocName and DungeonBots.GetLocalizedItemName then
            local scanName = DungeonBots:GetLocalizedItemName(entry.itemId, nil, true)
            if scanName and scanName ~= "" and not (isPh and isPh(scanName)) then
                locName = scanName
                validLocName = true
            end
        end
        if validLocName and entry.name ~= locName then
            entry.name = locName
            changed = true
        end
        if validLocLink and entry.displayLink ~= locLink then
            entry.displayLink = locLink
            changed = true
        end
        if icon and icon ~= "" and entry.icon ~= icon then
            entry.icon = icon
            changed = true
        end
        if not validLocName and not skipQueue and DB_Internal.QueueItemLocaleResolution then
            DB_Internal.QueueItemLocaleResolution(entry.itemId)
        end
    end

    if (not entry.icon or entry.icon == "") and entry.itemId and GetItemIcon then
        local itemIcon = GetItemIcon(entry.itemId)
        if itemIcon and itemIcon ~= "" then
            entry.icon = itemIcon
            changed = true
        end
    end

    if type(entry.reagents) == "table" then
        local isPh = DB_Internal.IsPlaceholderTooltipText
        for _, reg in ipairs(entry.reagents) do
            if reg.itemId and GetItemInfo then
                local locName, locLink = GetItemInfo(reg.itemId)
                local validRegName = locName and locName ~= "" and not (isPh and isPh(locName))
                local validRegLink = locLink and locLink ~= "" and not (isPh and isPh(locLink))
                if validRegName and reg.name ~= locName then
                    reg.name = locName
                    changed = true
                end
                if validRegLink and reg.displayLink ~= locLink then
                    reg.displayLink = locLink
                    changed = true
                end
                if not validRegName and not skipQueue and DB_Internal.QueueItemLocaleResolution then
                    DB_Internal.QueueItemLocaleResolution(reg.itemId)
                end
            end
        end
    end

    return changed
end

DB_Internal.ResolveSpellEntryVisuals = ResolveSpellEntryVisuals

function DB_Internal.RefreshSpellVisuals(skipQueue)
    if not DungeonBots.spellsDialogData then return end
    for botName, rec in pairs(DungeonBots.spellsDialogData) do
        local changed = false
        for _, modeKey in ipairs({ "spells", "glyphs" }) do
            local modeTab = rec and rec.tabs and rec.tabs[modeKey]
            if modeTab and type(modeTab.items) == "table" then
                for _, entry in ipairs(modeTab.items) do
                    if ResolveSpellEntryVisuals(entry, skipQueue) then
                        changed = true
                    end
                end
            end
        end
        if changed and DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() and DungeonBots.spellsFrame.currentBot == botName then
            DungeonBots:UpdateSpellsDialog(botName)
        end
    end
end

local function ExtractDifficultySuffix(text)
    if not text or text == "" then return nil, nil end
    local clean = TrimText(StripWowFormatting(text))
    local lowerClean = string.lower(clean)
    local diffWord = string.match(lowerClean, "%-%s*(%a+)%s*$")
        or string.match(lowerClean, "%-%s*(%a+)%s*%(%s*[xX]?%d+%s*%)%s*$")
    local diffInfo = diffWord and DIFFICULTY_INFO[diffWord] or nil
    local craftCount = string.match(lowerClean, "%(%s*x?(%d+)%s*%)%s*$")
    return diffInfo, craftCount and tonumber(craftCount) or nil
end

local function ParseSpellEntryFromLine(line)
    if not line or line == "" then return nil end

    local links = ExtractOrderedHyperlinks(line)
    local mainLink = links[1]
    local rawName = nil
    local spellId = nil
    local itemId = nil
    local linkType = nil
    local rawLink = nil
    local plainLink = nil

    if mainLink then
        linkType = mainLink.linkType
        rawName = mainLink.rawName
        rawLink = mainLink.safeLink
        plainLink = mainLink.plainH
        if linkType == "spell" or linkType == "enchant" or linkType == "trade" then
            spellId = tonumber(string.match(mainLink.payload, "^(%d+)"))
        elseif linkType == "item" then
            itemId = tonumber(string.match(mainLink.payload, "^(%d+)"))
        end
    else
        local plainBracket = string.match(StripWowFormatting(line), "^%s*%[([^%]]+)%]")
        if not plainBracket or plainBracket == "" then
            return nil
        end
        rawName = plainBracket
        linkType = "text"
    end

    local diffInfo = ExtractDifficultySuffix(line)
    local reagents = {}

    if #links > 1 then
        for i = 2, #links do
            local l = links[i]
            local nextStart = (i < #links) and (links[i + 1].sPos - 1) or #line
            local segAfter = StripWowFormatting(string.sub(line, l.ePos + 1, nextStart))
            local qty = string.match(segAfter, "^%s*[xX]?(%d+)")
            local buyable = string.find(string.lower(segAfter), "buy", 1, true) and true or false
            local regItemId = (l.linkType == "item") and tonumber(string.match(l.payload, "^(%d+)")) or nil

            table.insert(reagents, {
                linkType = l.linkType,
                itemId = regItemId,
                rawName = l.rawName,
                name = l.rawName,
                rawLink = l.safeLink,
                displayLink = l.safeLink,
                count = qty and tonumber(qty) or nil,
                buyable = buyable,
            })
        end
    end

    local entry = {
        linkType = linkType,
        spellId = spellId,
        itemId = itemId,
        rawName = rawName,
        name = rawName,
        rank = nil,
        icon = nil,
        cost = nil,
        powerType = nil,
        castTime = nil,
        maxRange = nil,
        rawLink = rawLink,
        plainLink = plainLink,
        displayLink = rawLink,
        difficulty = diffInfo,
        reagents = reagents,
    }

    ResolveSpellEntryVisuals(entry, false)
    return entry
end

local function BuildSpellCommandRef(spellEntry)
    if not spellEntry then return nil end

    if spellEntry.spellId and (not spellEntry.linkType or spellEntry.linkType == "spell") then
        if GetSpellLink then
            local clientLink = GetSpellLink(spellEntry.spellId)
            if type(clientLink) == "string"
                and string.match(clientLink, "^|c%x%x%x%x%x%x%x%x|Hspell:%d+")
                and string.len(clientLink) <= 235 then
                return clientLink
            end
        end
        local spellTitle = spellEntry.name or spellEntry.rawName or tostring(spellEntry.spellId)
        local candidate = "|cff71d5ff|Hspell:" .. spellEntry.spellId .. ":0|h[" .. spellTitle .. "]|h|r"
        if string.len(candidate) <= 235 then
            return candidate
        end
    end

    if type(spellEntry.displayLink) == "string"
        and string.match(spellEntry.displayLink, "^|c%x%x%x%x%x%x%x%x|H")
        and string.len(spellEntry.displayLink) <= 235 then
        return spellEntry.displayLink
    end

    if type(spellEntry.rawLink) == "string"
        and string.match(spellEntry.rawLink, "^|c%x%x%x%x%x%x%x%x|H")
        and string.len(spellEntry.rawLink) <= 235 then
        return spellEntry.rawLink
    end

    return spellEntry.rawName or spellEntry.name
end

local function IsSpellsNoiseMessage(message, activeMode)
    if DB_Internal.IsPureTalentResponse and DB_Internal.IsPureTalentResponse(message) then
        return true
    end
    if DB_Internal.IsInventoryDumpMessage and DB_Internal.IsInventoryDumpMessage(message) then
        return true
    end
    if string.find(message, "|Hquest:", 1, true)
        and not string.find(message, "|Hspell:", 1, true)
        and not string.find(message, "|Hglyph:", 1, true) then
        return true
    end
    local lowerClean = string.lower(TrimText(StripWowFormatting(message)))
    if string.match(lowerClean, "^%d+%.%s+.+%(%d+%-%d+%-%d+%)")
        or string.find(lowerClean, "specs found", 1, true)
        or string.find(lowerClean, "active quests", 1, true)
        or string.find(lowerClean, "completed quests", 1, true)
        or string.find(lowerClean, "no active quests", 1, true)
        or string.find(lowerClean, "summary", 1, true)
        or string.match(lowerClean, "incompleted?:%s*%d+")
        or string.match(lowerClean, "total%s*:%s*%d+") then
        return true
    end
    return false
end

local function ParseSpellDetailWhisper(cleanSender, message, now)
    local cap = DungeonBots.pendingSpellDetailCapture and DungeonBots.pendingSpellDetailCapture[cleanSender]
    if not cap then return false end
    if now > (cap.expiresAt or 0) then
        DungeonBots.pendingSpellDetailCapture[cleanSender] = nil
        return false
    end
    if not message or message == "" or IsSpellsNoiseMessage(message, "spell") then
        return false
    end

    local localized = (DungeonBots.LocalizeHyperlinksInText and DungeonBots:LocalizeHyperlinksInText(message)) or message
    local matchedAny = false
    for rawLine in string.gmatch(localized, "[^\r\n]+") do
        local trimmed = TrimText(rawLine)
        if trimmed ~= "" then
            matchedAny = true
            table.insert(cap.lines, trimmed)
        end
    end
    if not matchedAny then return false end

    cap.gotAnyLine = true
    cap.finalizeAt = math.min((cap.startedAt or now) + 3.0, now + 0.40)
    cap.expiresAt = math.max(cap.expiresAt, now + 0.8)

    local rec = GetOrCreateBotSpellsRecord(cleanSender)
    rec.spellDetail = {
        title = (cap.spellEntry and (cap.spellEntry.name or cap.spellEntry.rawName)) or (DungeonBots.L and DungeonBots.L["SPELL_DEFAULT"]) or "Spell",
        spellId = cap.spellEntry and cap.spellEntry.spellId or nil,
        lines = cap.lines,
        updatedAt = now,
    }
    if DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() and DungeonBots.spellsFrame.currentBot == cleanSender then
        DungeonBots:UpdateSpellsDialog(cleanSender)
    end
    return true
end

local function ParseGlyphEntriesFromLine(line, cleanLine, tab)
    if not line or line == "" then return false end

    local L = DungeonBots.L or {}
    local lowerClean = string.lower(cleanLine or "")
    local prefixRaw = string.match(cleanLine or "", "^%s*([^:%[]+)%s*:")
    local lowerPrefix = string.lower(TrimText(prefixRaw or ""))
    local categoryTag = nil
    if string.find(lowerPrefix, "major", 1, true) or string.find(lowerPrefix, "sublim", 1, true) then
        categoryTag = L["GLYPH_MAJOR"] or "Major"
    elseif string.find(lowerPrefix, "minor", 1, true) or string.find(lowerPrefix, "menor", 1, true) then
        categoryTag = L["GLYPH_MINOR"] or "Minor"
    end

    local lineLinks = ExtractOrderedHyperlinks(line)
    if #lineLinks > 0 then
        for _, l in ipairs(lineLinks) do
            local itemId = (l.linkType == "item") and tonumber(string.match(l.payload, "^(%d+)")) or nil
            local spellId = (l.linkType == "spell" or l.linkType == "enchant") and tonumber(string.match(l.payload, "^(%d+)")) or nil
            local entry = {
                kind = "glyph",
                linkType = l.linkType,
                spellId = spellId,
                itemId = itemId,
                rawName = l.rawName,
                name = l.rawName,
                rawLink = l.safeLink,
                plainLink = l.plainH,
                displayLink = l.safeLink,
                categoryTag = categoryTag,
                index = #tab.items + 1,
            }
            ResolveSpellEntryVisuals(entry, false)
            table.insert(tab.items, entry)
        end
        return true
    end

    local addedPlain = false
    for bracketText in string.gmatch(cleanLine or "", "%[([^%]]+)%]") do
        local trimmed = TrimText(bracketText)
        if trimmed ~= "" then
            addedPlain = true
            table.insert(tab.items, {
                kind = "glyph",
                linkType = "text",
                rawName = trimmed,
                name = trimmed,
                categoryTag = categoryTag,
                index = #tab.items + 1,
            })
        end
    end
    if addedPlain then
        return true
    end

    if string.find(lowerClean, "no glyph", 1, true)
        or string.find(lowerClean, "glyphs: none", 1, true)
        or lowerClean == "none"
        or tab.sawHeader then
        tab.emptyHint = (DungeonBots.LocalizeServerHint and DungeonBots:LocalizeServerHint(cleanLine, "glyphs")) or cleanLine
        return true
    end

    return false
end

local function PruneExpiredSpellCaptures(capGroup, botName, now)
    for modeKey, cap in pairs(capGroup.modes) do
        if now > (cap.expiresAt or 0) then
            capGroup.modes[modeKey] = nil
            local tab = GetOrCreateModeTab(botName, modeKey)
            tab.loading = false
            tab.done = true
            tab.dirty = false
        end
    end
end

local function DetectHeaderCaptureMode(headerText, modes, fallbackMode)
    local lowerHeader = string.lower(headerText or "")
    if (string.find(lowerHeader, "glyph", 1, true) or string.find(lowerHeader, "glifo", 1, true)) and modes.glyphs then
        return "glyphs"
    end
    if (string.find(lowerHeader, "spell", 1, true) or string.find(lowerHeader, "hechizo", 1, true)) and modes.spells then
        return "spells"
    end
    if fallbackMode and modes[fallbackMode] then
        return fallbackMode
    end
    return modes.spells and "spells" or (modes.glyphs and "glyphs" or nil)
end

local function DetectLineCaptureMode(line, cleanLine, lowerClean, modes, currentStreamMode)
    local hasSpells = modes.spells ~= nil
    local hasGlyphs = modes.glyphs ~= nil
    local prefixRaw = string.match(cleanLine or "", "^%s*([^:%[]+)%s*:")
    if prefixRaw then
        local lowerPrefix = string.lower(TrimText(prefixRaw))
        if (string.find(lowerPrefix, "major", 1, true)
            or string.find(lowerPrefix, "sublim", 1, true)
            or string.find(lowerPrefix, "minor", 1, true)
            or string.find(lowerPrefix, "menor", 1, true)) and hasGlyphs then
            return "glyphs"
        end
    end
    if (string.find(lowerClean, "no glyph", 1, true) or string.find(lowerClean, "glyphs: none", 1, true)) and hasGlyphs then
        return "glyphs"
    end
    local tailDiff = ExtractDifficultySuffix(line)
    if (string.find(line, "|Hspell:", 1, true)
        or string.find(line, "|Henchant:", 1, true)
        or string.find(line, "|Htrade:", 1, true)
        or tailDiff ~= nil
        or string.find(lowerClean, "no spell", 1, true)
        or string.find(lowerClean, "nothing found", 1, true)
        or string.find(lowerClean, "total:", 1, true)
        or string.find(lowerClean, "spells found", 1, true)) and hasSpells then
        return "spells"
    end
    if currentStreamMode and modes[currentStreamMode] then
        return currentStreamMode
    end
    if hasGlyphs and not hasSpells then
        return "glyphs"
    end
    if hasSpells and not hasGlyphs then
        return "spells"
    end
    if string.find(line, "|Hitem:", 1, true) and hasGlyphs then
        return "glyphs"
    end
    return nil
end

function DB_Internal.ParseSpellsCaptureWhisper(cleanSender, message)
    local now = NowTime()
    local capGroup = DungeonBots.pendingSpellsCapture and DungeonBots.pendingSpellsCapture[cleanSender]
    if not capGroup or type(capGroup.modes) ~= "table" then
        return ParseSpellDetailWhisper(cleanSender, message, now)
    end

    PruneExpiredSpellCaptures(capGroup, cleanSender, now)
    if next(capGroup.modes) == nil then
        DungeonBots.pendingSpellsCapture[cleanSender] = nil
        return ParseSpellDetailWhisper(cleanSender, message, now)
    end

    local activeModeHint = capGroup.streamMode or (capGroup.modes.spells and "spells" or "glyphs")
    if not message or message == "" or IsSpellsNoiseMessage(message, activeModeHint) then
        return false
    end

    local localizedMsg = (DungeonBots.LocalizeHyperlinksInText and DungeonBots:LocalizeHyperlinksInText(message)) or message
    local touchedModes = {}
    local matchedAny = false

    for rawLine in string.gmatch(localizedMsg, "[^\r\n]+") do
        local line = TrimText(rawLine)
        local cleanLine = TrimText(StripWowFormatting(line))
        local lowerClean = string.lower(cleanLine)

        if cleanLine ~= "" then
            local headerText = string.match(cleanLine, "^===+%s*(.-)%s*===+$")
            if headerText and headerText ~= "" then
                local headerMode = DetectHeaderCaptureMode(headerText, capGroup.modes, capGroup.streamMode)
                if headerMode and capGroup.modes[headerMode] then
                    capGroup.streamMode = headerMode
                    local tab = GetOrCreateModeTab(cleanSender, headerMode)
                    tab.sawHeader = true
                    touchedModes[headerMode] = true
                    matchedAny = true
                end
            else
                local lineMode = DetectLineCaptureMode(line, cleanLine, lowerClean, capGroup.modes, capGroup.streamMode)
                if lineMode and capGroup.modes[lineMode] then
                    local tab = GetOrCreateModeTab(cleanSender, lineMode)
                    if lineMode == "spells" then
                        local tailDiff = ExtractDifficultySuffix(line)
                        if string.find(line, "|Hspell:", 1, true)
                            or string.find(line, "|Henchant:", 1, true)
                            or string.find(line, "|Htrade:", 1, true)
                            or string.find(line, "|Hitem:", 1, true)
                            or tailDiff ~= nil then
                            local entry = ParseSpellEntryFromLine(line)
                            if entry then
                                entry.index = #tab.items + 1
                                table.insert(tab.items, entry)
                                touchedModes[lineMode] = true
                                matchedAny = true
                            end
                        elseif string.find(lowerClean, "no spell", 1, true)
                            or string.find(lowerClean, "nothing found", 1, true)
                            or string.find(lowerClean, "total:", 1, true)
                            or string.find(lowerClean, "spells found", 1, true) then
                            touchedModes[lineMode] = true
                            matchedAny = true
                            if string.find(lowerClean, "no spell", 1, true) or string.find(lowerClean, "nothing found", 1, true) then
                                tab.emptyHint = (DungeonBots.LocalizeServerHint and DungeonBots:LocalizeServerHint(cleanLine, "spells")) or cleanLine
                            end
                        end
                    elseif lineMode == "glyphs" then
                        if ParseGlyphEntriesFromLine(line, cleanLine, tab) then
                            touchedModes[lineMode] = true
                            matchedAny = true
                        end
                    end
                end
            end
        end
    end

    if not matchedAny then
        return false
    end

    local shouldRender = false
    for modeKey in pairs(touchedModes) do
        local cap = capGroup.modes[modeKey]
        local tab = GetOrCreateModeTab(cleanSender, modeKey)
        if cap then
            cap.gotAnyLine = true
            cap.finalizeAt = math.min((cap.startedAt or now) + 6.5, now + 0.65)
            cap.expiresAt = math.min((cap.startedAt or now) + 7.5, math.max(cap.expiresAt, now + 1.4))
        end
        tab.updatedAt = now
        tab.dirty = true
        if (#tab.items <= 20) or ((now - (tab.lastUiRefresh or 0)) >= 0.15) then
            tab.dirty = false
            tab.lastUiRefresh = now
            shouldRender = true
        end
    end

    if shouldRender and DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() and DungeonBots.spellsFrame.currentBot == cleanSender then
        DungeonBots:UpdateSpellsDialog(cleanSender)
    end
    return true
end

function DB_Internal.TickSpellsCapture(now)
    local hasAny = false

    if DungeonBots.pendingSpellsCapture then
        for botName, capGroup in pairs(DungeonBots.pendingSpellsCapture) do
            if type(capGroup) ~= "table" or type(capGroup.modes) ~= "table" then
                DungeonBots.pendingSpellsCapture[botName] = nil
            else
                local needUiRefresh = false
                for modeKey, cap in pairs(capGroup.modes) do
                    local tab = GetOrCreateModeTab(botName, modeKey)
                    local readyToFinalize = (cap.gotAnyLine and cap.finalizeAt and now >= cap.finalizeAt)
                    if readyToFinalize or now >= (cap.expiresAt or 0) then
                        capGroup.modes[modeKey] = nil
                        tab.loading = false
                        tab.done = true
                        tab.timedOut = (not cap.gotAnyLine) and true or false
                        tab.dirty = false
                        tab.lastUiRefresh = now
                        needUiRefresh = true
                    else
                        if DB_Internal.TryRetryWhisperCapture then
                            DB_Internal.TryRetryWhisperCapture(cap, botName, now, cap.cmd)
                        end
                        if tab.dirty and ((now - (tab.lastUiRefresh or 0)) >= 0.15) then
                            tab.dirty = false
                            tab.lastUiRefresh = now
                            needUiRefresh = true
                        end
                        hasAny = true
                    end
                end
                if next(capGroup.modes) == nil then
                    DungeonBots.pendingSpellsCapture[botName] = nil
                end
                if needUiRefresh and DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() and DungeonBots.spellsFrame.currentBot == botName then
                    DungeonBots:UpdateSpellsDialog(botName)
                end
            end
        end
    end

    if DungeonBots.pendingSpellDetailCapture then
        for botName, cap in pairs(DungeonBots.pendingSpellDetailCapture) do
            local readyToFinalize = (cap.gotAnyLine and cap.finalizeAt and now >= cap.finalizeAt)
            if readyToFinalize or now >= (cap.expiresAt or 0) then
                DungeonBots.pendingSpellDetailCapture[botName] = nil
                if cap.gotAnyLine and #cap.lines > 0 then
                    local summary = table.concat(cap.lines, " | ")
                    DungeonBots:Print("|cffffd200" .. botName .. "|r (" .. ((cap.spellEntry and (cap.spellEntry.name or cap.spellEntry.rawName)) or L["SPELL_DEFAULT"]) .. "): " .. summary)
                else
                    DungeonBots:Warn(string.format(L["SPELL_NO_DETAIL_FMT"], botName))
                end
            else
                hasAny = true
            end
        end
    end

    return hasAny
end

function DungeonBots:QueryBotSpells(botName, mode, filterText, isSilent)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot then
        if not isSilent then
            DungeonBots:Warn(L["SPELL_NO_BOT_SEL"])
        end
        return
    end

    local targetMode = MODE_COMMANDS[mode] and mode or "gear"
    local cleanFilter = TrimText(filterText or "")
    local now = NowTime()

    local tab, rec = GetOrCreateModeTab(cleanBot, targetMode)
    rec.activeMode = targetMode
    if targetMode == "gear" then
        tab.loading = false
        tab.done = true
        tab.updatedAt = now
        if not isSilent and DungeonBots.EnsureGearTabData then
            DungeonBots:EnsureGearTabData(cleanBot, false)
        end
        if not isSilent and DungeonBots.OpenSpellsDialog then
            DungeonBots:OpenSpellsDialog(cleanBot, "gear")
        elseif DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() and DungeonBots.spellsFrame.currentBot == cleanBot then
            DungeonBots:UpdateSpellsDialog(cleanBot)
        end
        return
    end
    if targetMode == "spells" then
        rec.spellsFilter = cleanFilter
    end

    tab.loading = true
    tab.done = false
    tab.timedOut = false
    tab.sawHeader = false
    tab.items = {}
    tab.lines = {}
    tab.emptyHint = nil
    tab.filterUsed = cleanFilter
    tab.updatedAt = now
    tab.dirty = false
    tab.lastUiRefresh = now

    local cmd = MODE_COMMANDS[targetMode]
    if targetMode == "spells" and cleanFilter ~= "" then
        cmd = "spells " .. cleanFilter
    end
    local unit = DungeonBots.FindPartyUnitByName and DungeonBots:FindPartyUnitByName(cleanBot)
    local canSend = (unit and UnitIsConnected(unit)) and true or false

    local capGroup = DungeonBots.pendingSpellsCapture[cleanBot]
    if type(capGroup) ~= "table" or type(capGroup.modes) ~= "table" then
        capGroup = { streamMode = targetMode, modes = {} }
        DungeonBots.pendingSpellsCapture[cleanBot] = capGroup
    end
    capGroup.streamMode = targetMode
    capGroup.modes[targetMode] = {
        mode = targetMode,
        startedAt = now,
        expiresAt = canSend and (now + 6.0) or now,
        retryAt = canSend and (now + 2.8) or nil,
        retrySent = false,
        cmd = cmd,
        finalizeAt = nil,
        gotAnyLine = false,
        queryParam = cleanFilter,
    }

    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end

    if not isSilent and DungeonBots.OpenSpellsDialog then
        DungeonBots:OpenSpellsDialog(cleanBot, targetMode)
    elseif DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() and DungeonBots.spellsFrame.currentBot == cleanBot then
        DungeonBots:UpdateSpellsDialog(cleanBot)
    end

    DungeonBots:SendWhisperCommand(cleanBot, cmd)
end

function DungeonBots:QueryBotSpellDetail(botName, spellEntry)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or not spellEntry then return end

    local ref = BuildSpellCommandRef(spellEntry)
    if not ref or ref == "" then return end

    local now = NowTime()
    DungeonBots.pendingSpellDetailCapture[cleanBot] = {
        spellEntry = spellEntry,
        startedAt = now,
        expiresAt = now + 2.5,
        finalizeAt = nil,
        lines = {},
        gotAnyLine = false,
    }

    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end

    PlaySound("igMainMenuOptionCheckBoxOn")
    DungeonBots:SendWhisperCommand(cleanBot, "spell " .. ref)
end

function DungeonBots:CastBotSpell(botName, spellEntry)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or not spellEntry then return end

    local ref = BuildSpellCommandRef(spellEntry)
    if not ref or ref == "" then return end

    DungeonBots:SendWhisperCommand(cleanBot, "cast " .. ref)
    PlaySound("igMainMenuOptionCheckBoxOn")

    local display = (spellEntry.displayLink and spellEntry.displayLink ~= "")
        and spellEntry.displayLink
        or ("|cff71d5ff[" .. (spellEntry.name or spellEntry.rawName or L["SPELL_DEFAULT"]) .. "]|r")
    DungeonBots:Print(string.format(L["SPELL_ORDER_CAST_FMT"], cleanBot, display))
end

function DungeonBots:CancelBotSpell(botName)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or cleanBot == "" then return end

    DungeonBots:SendWhisperCommand(cleanBot, "reset")
    PlaySound("igMainMenuOptionCheckBoxOn")
    DungeonBots:Print(string.format(L["SPELL_ORDER_CANCEL"], cleanBot))
end

function DungeonBots:CycleNextSpellsBot(currentBot, activeMode, serverFilter)
    if not DungeonBots.GetTalkBotCycleInfo then return nil end
    local _, total, nextBot = DungeonBots:GetTalkBotCycleInfo(currentBot)
    if not nextBot or total < 2 then
        return nil
    end
    local targetMode = MODE_COMMANDS[activeMode] and activeMode or "gear"
    DungeonBots:QueryBotSpells(nextBot, targetMode, serverFilter, false)
    return nextBot
end
