-- =========================================================================
-- DungeonBots_Comms.lua: Comandos, Cola de Susurros, Filtros de Chat y WIM
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal
local L = DungeonBots.L or {}

local function NowTime()
    return DB_Internal.NowTime()
end

local function NormalizePlayerName(name)
    return DB_Internal.NormalizePlayerName(name)
end

local function TrimText(str)
    return DB_Internal.TrimText(str)
end

local function StripWowFormatting(text)
    return DB_Internal.StripWowFormatting(text)
end

-- =========================================================================
-- Despachador de Comandos y Control Anti-Eco
-- =========================================================================
local isSendingAddonWhisper = false

local function PruneOutgoingWhispers(list, now)
    if not list then return end
    for i = #list, 1, -1 do
        if not list[i] or (list[i].expiresAt or 0) <= now then
            table.remove(list, i)
        end
    end
end

function DungeonBots:MarkAddonOutgoingWhisper(botName, cmd, ttlSeconds)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or not cmd or cmd == "" then return end
    local now = NowTime()
    DungeonBots.recentOutgoingAddonWhispers = DungeonBots.recentOutgoingAddonWhispers or {}
    local list = DungeonBots.recentOutgoingAddonWhispers[cleanBot]
    if not list then
        list = {}
        DungeonBots.recentOutgoingAddonWhispers[cleanBot] = list
    end
    PruneOutgoingWhispers(list, now)
    table.insert(list, {
        cmd = string.lower(TrimText(cmd)),
        expiresAt = now + (ttlSeconds or 4.0),
    })
end

function DungeonBots:IsRecentAddonOutgoingWhisper(botName, message)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or not DungeonBots.recentOutgoingAddonWhispers then return false end
    local list = DungeonBots.recentOutgoingAddonWhispers[cleanBot]
    if not list or #list == 0 then return false end
    local now = NowTime()
    PruneOutgoingWhispers(list, now)
    if #list == 0 then return false end
    local lowerMsg = string.lower(TrimText(message or ""))
    for _, entry in ipairs(list) do
        if entry.cmd == lowerMsg then
            return true
        end
    end
    return false
end

-- Comandos con punto (.playerbots bot ...)
function DungeonBots:SendDotCommand(cmd)
    if not cmd or cmd == "" then return end
    SendChatMessage(cmd, "SAY")
end

-- Comandos de grupo (/p follow, /p summon, /p accept *, etc.)
function DungeonBots:SendPartyCommand(cmd)
    if not cmd or cmd == "" then return end
    if GetNumPartyMembers() > 0 then
        SendChatMessage(cmd, "PARTY")
    else
        -- Si no está en grupo, enviar a SAY por si está probando solo
        SendChatMessage(cmd, "SAY")
    end
end

-- Comandos por susurro a un bot (/w BotName talents spec ...)
function DungeonBots:SendWhisperCommand(botName, cmd)
    if not botName or botName == "" or not cmd or cmd == "" then return end
    local cleanBot = NormalizePlayerName(botName)
    local unit = DungeonBots:FindPartyUnitByName(cleanBot)
    if not unit or not UnitIsConnected(unit) then
        return
    end
    DungeonBots:MarkAddonOutgoingWhisper(botName, cmd, 4.0)
    isSendingAddonWhisper = true
    SendChatMessage(cmd, "WHISPER", nil, botName)
    isSendingAddonWhisper = false
end

function DungeonBots:SendBotWhisperUnchecked(botName, cmd)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or cleanBot == "" or not cmd or cmd == "" then return false end
    local playerName = UnitName and UnitName("player")
    if cleanBot == playerName then return false end
    DungeonBots:MarkAddonOutgoingWhisper(cleanBot, cmd, 4.0)
    isSendingAddonWhisper = true
    SendChatMessage(cmd, "WHISPER", nil, cleanBot)
    isSendingAddonWhisper = false
    return true
end

-- Reintenta una vez por susurro si la captura aún no recibe respuesta
function DB_Internal.TryRetryWhisperCapture(cap, botName, now, cmd)
    if not cap or cap.gotAnyLine or cap.retrySent or not cap.retryAt or now < cap.retryAt then
        return false
    end
    cap.retrySent = true
    local unit = DungeonBots.FindPartyUnitByName and DungeonBots:FindPartyUnitByName(botName)
    if unit and UnitIsConnected(unit) and cmd and cmd ~= "" then
        DungeonBots:SendWhisperCommand(botName, cmd)
        return true
    end
    cap.expiresAt = now
    return false
end

function DungeonBots:RequestBotWhoCheck(botName, reason, force)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or cleanBot == "" then return false end
    local now = NowTime()
    DungeonBots.pendingWhoCheck = DungeonBots.pendingWhoCheck or {}
    DungeonBots.whoCheckLastSentAt = DungeonBots.whoCheckLastSentAt or {}
    local existing = DungeonBots.pendingWhoCheck[cleanBot]
    if not force and existing and (existing.requestedAt or 0) + 15.0 > now then
        if reason and reason ~= "" then
            existing.reason = reason
        end
        return false
    end
    local lastSent = DungeonBots.whoCheckLastSentAt[cleanBot] or 0
    if not force and (lastSent + 15.0) > now then
        return false
    end
    DungeonBots.whoCheckLastSentAt[cleanBot] = now
    DungeonBots.pendingWhoCheck[cleanBot] = {
        reason = reason or "check",
        requestedAt = now,
        expiresAt = now + 8.0,
        warnedTimeout = false,
    }
    if DB_Internal.ShowWhoCheckFrame then
        DB_Internal.ShowWhoCheckFrame()
    end
    return DungeonBots:SendBotWhisperUnchecked(cleanBot, "who")
end

-- =========================================================================
-- Cola Escalonada de Susurros para Evitar Saturación
-- =========================================================================
local whisperQueue = {}
local nextWhisperAt = 0
local whisperQueueFrame = CreateFrame("Frame")
whisperQueueFrame:Hide()

whisperQueueFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = NowTime()
    if #whisperQueue == 0 then
        self:Hide()
        return
    end
    if now >= nextWhisperAt then
        local item = table.remove(whisperQueue, 1)
        local unit = item and item.botName and DungeonBots:FindPartyUnitByName(item.botName)
        if unit and UnitIsConnected(unit) and item.cmd then
            DungeonBots:SendWhisperCommand(item.botName, item.cmd)
            nextWhisperAt = now + 0.30
            local queryStates = DB_Internal.queryStates
            local st = queryStates and queryStates[item.botName]
            if st then
                if not st.retrySent then
                    st.retryAt = now + 4.0
                end
                st.timeoutAt = math.max(st.timeoutAt or 0, now + 8.5)
                if DB_Internal.ShowJoinQueryFrame then
                    DB_Internal.ShowJoinQueryFrame()
                end
            end
        end
    end
end)

function DB_Internal.ClearWhisperQueue()
    whisperQueue = {}
end

function DungeonBots:QueueWhisperCommand(botName, cmd, atFront)
    if not botName or botName == "" or not cmd or cmd == "" then return end
    local cleanBot = NormalizePlayerName(botName)
    local unit = DungeonBots:FindPartyUnitByName(cleanBot)
    if not unit or not UnitIsConnected(unit) then
        return
    end
    for _, existing in ipairs(whisperQueue) do
        if existing.botName == botName and existing.cmd == cmd then
            return
        end
    end
    local entry = { botName = botName, cmd = cmd }
    if atFront then
        table.insert(whisperQueue, 1, entry)
    else
        table.insert(whisperQueue, entry)
    end
    whisperQueueFrame:Show()
end

-- =========================================================================
-- Ocultamiento de Mensajes de Bots (Blizzard Chat + WIM) y Traducción de Enlaces
-- =========================================================================
local chatFiltersRegistered = false
local sendChatHooked = false
local wimWrappedMethods = {}

function DB_Internal.IsPureTalentResponse(message)
    local lowerMsg = string.lower(TrimText(StripWowFormatting(message or "")))
    if lowerMsg == "" then return false end
    if string.find(string.lower(message or ""), "|hquest:") then
        return false
    end
    if string.find(lowerMsg, "^available specs")
        or string.find(lowerMsg, "^talents")
        or (string.find(lowerMsg, "talents") and string.find(lowerMsg, "%d+/%d+/%d+")) then
        return true
    end
    return false
end

function DB_Internal.IsBotDetectionText(message)
    local lowerMsg = string.lower(message or "")
    local lowerClean = string.lower(TrimText(StripWowFormatting(message or "")))
    return (string.find(lowerMsg, "follow distance")
        or string.find(lowerMsg, "following")
        or string.find(lowerMsg, "staying")
        or string.find(lowerMsg, "strategies:")
        or string.find(lowerMsg, "available specs")
        or string.find(lowerMsg, "talents")
        or string.find(lowerMsg, "co %+")
        or string.find(lowerMsg, "nc %+")
        or string.find(lowerMsg, "fleeing")
        or string.find(lowerMsg, "stats:")
        or (string.find(lowerMsg, "bag", 1, true) and string.find(lowerMsg, "dur", 1, true) and string.find(lowerMsg, "%d+/%d+"))
        or string.find(lowerMsg, "money:")
        or string.find(lowerMsg, "greetings")
        or string.find(lowerMsg, "ready")
        or string.find(lowerMsg, "active quests")
        or string.find(lowerMsg, "completed quests")
        or string.find(lowerMsg, "no active quests")
        or string.find(lowerMsg, "no quests")
        or string.find(lowerMsg, "--- summary ---", 1, true)
        or string.find(lowerMsg, "incompleted:", 1, true)
        or string.find(lowerMsg, "quest_shared", 1, true)
        or string.find(lowerMsg, "|hquest:")
        or string.find(lowerMsg, "autogear")
        or string.find(lowerMsg, "nothing to say")
        or string.find(lowerMsg, "no npc")
        or string.find(lowerMsg, "=== inventory ===")
        or string.find(lowerMsg, "=== spells ===")
        or string.find(lowerMsg, "=== glyphs ===")
        or string.find(lowerMsg, "inventory is empty")
        or string.find(lowerClean, "playing with", 1, true)
        or (string.find(lowerClean, "lvl)", 1, true) and string.find(lowerClean, "gs (", 1, true))
        or string.match(lowerMsg, "%d+[-/]%d+[-/]%d+")) and true or false
end

function DB_Internal.ParseBotStatsWhisper(message)
    if not message or message == "" then return nil end
    local rawMsg = TrimText(message)
    local cleanFull = TrimText(StripWowFormatting(rawMsg))
    if cleanFull == "" then return nil end

    local goldText = nil
    local bagNum, bagTotal, bagColor = nil, nil, nil
    local durPct, durExtra, durColor = nil, nil, nil

    for seg in string.gmatch(rawMsg, "([^,]+)") do
        local segColor = string.match(seg, "(|c%x%x%x%x%x%x%x%x)")
        local cleanSeg = TrimText(StripWowFormatting(seg))
        local lowerSeg = string.lower(cleanSeg)

        if not bagNum then
            local bA, bB = string.match(cleanSeg, "(%d+)%s*/%s*(%d+)%s+[Bb][Aa][Gg]")
            if bA and bB then
                bagNum = tonumber(bA)
                bagTotal = tonumber(bB)
                bagColor = segColor
            end
        end
        if not durPct and string.find(lowerSeg, "dur", 1, true) then
            local dP, dEx = string.match(cleanSeg, "(%d+)%%%s*%(([^%)]+)%)%s+[Dd][Uu][Rr]")
            if not dP then
                dP = string.match(cleanSeg, "(%d+)%%%s+[Dd][Uu][Rr]")
            end
            if dP then
                durPct = tonumber(dP)
                durExtra = dEx and TrimText(dEx) or nil
                durColor = segColor
            end
        end
        if not goldText then
            local gMatch = string.match(cleanSeg, "(%d+g[%d%s%a]*)")
            if gMatch then
                goldText = TrimText(gMatch)
            end
        end
    end

    if not bagNum or not bagTotal or not durPct then
        return nil
    end

    return {
        goldText = goldText,
        bagUsed = bagNum,
        bagTotal = bagTotal,
        bagColorHex = bagColor,
        durPct = durPct,
        durExtra = durExtra,
        durColorHex = durColor,
        rawText = cleanFull,
    }
end

function DB_Internal.ParseWhoWhisper(message)
    local cleanMsg = TrimText(StripWowFormatting(message or ""))
    if cleanMsg == "" then return nil end
    local lowerMsg = string.lower(cleanMsg)

    local hasLvlAndGs = (string.find(lowerMsg, "lvl)", 1, true) and string.find(lowerMsg, "gs (", 1, true))
    local hasPlayingWith = (string.find(lowerMsg, "playing with", 1, true) ~= nil)
    if not hasLvlAndGs and not hasPlayingWith then
        return nil
    end

    local playingWith = string.match(cleanMsg, "[Pp]laying%s+with%s+([^%s,%.%!%?]+)")
    if playingWith then
        playingWith = NormalizePlayerName(playingWith)
    end

    local zone = nil
    local withoutOwner = string.gsub(cleanMsg, ",?%s*[Pp]laying%s+with%s+.*$", "")
    local afterGs = string.match(withoutOwner, "[Gg][Ss]%s*%b()%s*,%s*(.+)$")
    if afterGs then
        zone = string.match(afterGs, "%(([^%)]+)%)")
    end
    if not zone then
        local afterLvl = string.match(withoutOwner, "lvl%)%s*,%s*(.+)$")
        if afterLvl then
            local candidate = nil
            for paren in string.gmatch(afterLvl, "%(([^%)]+)%)") do
                candidate = paren
            end
            if candidate and not string.match(candidate, "^%d+$") then
                zone = candidate
            end
        end
    end
    if zone then
        zone = TrimText(zone)
        if zone == "" then zone = nil end
    end

    return {
        isWho = true,
        zone = zone,
        playingWith = playingWith,
        raw = cleanMsg,
    }
end

function DB_Internal.ExtractBusyBotOwnerFromWhisper(message)
    local cleanMsg = TrimText(StripWowFormatting(message or ""))
    if cleanMsg == "" then return nil, false end
    local lowerMsg = string.lower(cleanMsg)

    local owner = string.match(cleanMsg, "[Ii] am in a group with%s+([^%.%!%?,%s]+)")
        or string.match(cleanMsg, "[Ii]'m in a group with%s+([^%.%!%?,%s]+)")
        or string.match(cleanMsg, "[Ee]stoy en un grupo con%s+([^%.%!%?,%s]+)")
    if owner and owner ~= "" then
        return NormalizePlayerName(owner), true
    end

    if string.find(lowerMsg, "in a group with", 1, true)
        or string.find(lowerMsg, "already in a group", 1, true)
        or string.find(lowerMsg, "you can ask him for invite", 1, true)
        or string.find(lowerMsg, "you can ask her for invite", 1, true)
        or string.find(lowerMsg, "you can ask them for invite", 1, true) then
        return nil, true
    end
    return nil, false
end

function DB_Internal.ExtractBusyBotFromSystem(message)
    local cleanMsg = TrimText(StripWowFormatting(message or ""))
    if cleanMsg == "" then return nil, nil end

    local addTarget, addDetail = string.match(cleanMsg, "^[Aa][Dd][Dd]:%s*([^%s%-]+)%s*%-%s*(.+)$")
    if addTarget and addDetail then
        local lowerDetail = string.lower(addDetail)
        if string.find(lowerDetail, "already logged in", 1, true)
            or string.find(lowerDetail, "ya conectado", 1, true) then
            return NormalizePlayerName(addTarget), "already_logged_in"
        end
    end

    local firstWord, rest = string.match(cleanMsg, "^([^%s]+)%s+(.+)$")
    if firstWord and rest then
        local lowerRest = string.lower(rest)
        if string.find(lowerRest, "is already logged in", 1, true)
            or string.find(lowerRest, "player already logged in", 1, true)
            or (string.find(lowerRest, "ya est", 1, true) and string.find(lowerRest, "conectado", 1, true)) then
            return NormalizePlayerName(firstWord), "already_logged_in"
        end
        if string.find(lowerRest, "is already in a group", 1, true)
            or string.find(lowerRest, "is already in another group", 1, true)
            or (string.find(lowerRest, "ya est", 1, true) and string.find(lowerRest, "en un grupo", 1, true))
            or string.find(lowerRest, "ya forma parte de un grupo", 1, true) then
            return NormalizePlayerName(firstWord), "already_in_group"
        end
        if (string.find(lowerRest, "no est", 1, true) and string.find(lowerRest, "en tu estancia", 1, true))
            or string.find(lowerRest, "is not in your instance", 1, true) then
            return NormalizePlayerName(firstWord), "not_in_instance"
        end
    end
    return nil, nil
end

function DB_Internal.ExtractAddedBotFromSystem(message)
    local cleanMsg = TrimText(StripWowFormatting(message or ""))
    if cleanMsg == "" then return nil end

    local addTarget, addDetail = string.match(cleanMsg, "^[Aa][Dd][Dd]:%s*([^%s%-]+)%s*%-%s*(.+)$")
    if addTarget and addDetail then
        local lowerDetail = string.lower(TrimText(addDetail))
        if string.find(lowerDetail, "already", 1, true)
            or string.find(lowerDetail, "ya ", 1, true)
            or string.find(lowerDetail, "error", 1, true)
            or string.find(lowerDetail, "fail", 1, true)
            or string.find(lowerDetail, "not ", 1, true)
            or string.find(lowerDetail, "no ", 1, true)
            or string.find(lowerDetail, "cannot", 1, true)
            or string.find(lowerDetail, "can't", 1, true)
            or string.find(lowerDetail, "offline", 1, true)
            or string.find(lowerDetail, "unknown", 1, true)
            or string.find(lowerDetail, "desconectad", 1, true)
            or string.find(lowerDetail, "desconocid", 1, true)
            or string.find(lowerDetail, "busy", 1, true)
            or string.find(lowerDetail, "ocupad", 1, true) then
            return nil
        end
        return NormalizePlayerName(addTarget)
    end
    return nil
end

function DungeonBots:EvaluateWhisperSender(cleanSender, message, allowPromote)
    if not cleanSender or cleanSender == "" then
        return { isBot = false }
    end
    if DungeonBots:IsBot(cleanSender) == false then
        return { isBot = false, explicitHuman = true }
    end

    local inParty = (DungeonBots:FindPartyUnitByName(cleanSender, true) ~= nil)
    local isKnownOrHistory = DungeonBots:ShouldTreatAsBot(cleanSender)
    local hasPendingScan = DungeonBots:HasPendingScan(cleanSender)
    local hasPendingWho = (DungeonBots.pendingWhoCheck and DungeonBots.pendingWhoCheck[cleanSender] ~= nil) and true or false
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    local inRaid = (GetNumRaidMembers and GetNumRaidMembers() > 0)
    local canConsumeClassSummon = (not isKnownOrHistory)
        and (not hasPendingScan)
        and (not inParty)
        and (not inRaid)
        and (numParty < 4)
        and DungeonBots:HasPendingClassSummon()

    local isBotText = DB_Internal.IsBotDetectionText(message)
    local whoInfo = hasPendingWho and DB_Internal.ParseWhoWhisper(message) or nil
    local busyOwner, isBusyWhisper = DB_Internal.ExtractBusyBotOwnerFromWhisper(message)
    local myName = UnitName and NormalizePlayerName(UnitName("player"))
    if busyOwner and myName and busyOwner == myName then
        isBusyWhisper = false
    end
    local justPromoted = ((DungeonBots.justPromotedBotWhisper[cleanSender] or 0) > NowTime())

    if isBusyWhisper and not inParty then
        return {
            isBot = isKnownOrHistory,
            isKnownOrHistory = isKnownOrHistory,
            inParty = false,
            isBusyExternal = true,
            isBotText = true,
            justPromoted = false,
        }
    end

    if whoInfo and hasPendingWho and not isKnownOrHistory then
        isKnownOrHistory = true
    end

    if not isKnownOrHistory and not hasPendingScan and not (canConsumeClassSummon and isBotText) then
        return {
            isBot = false,
            isKnownOrHistory = false,
            inParty = inParty,
            isBotText = isBotText,
            justPromoted = justPromoted,
        }
    end

    if allowPromote then
        if hasPendingScan and not isKnownOrHistory then
            if not isBotText then
                DungeonBots.pendingScan[cleanSender] = nil
                return {
                    isBot = false,
                    isKnownOrHistory = false,
                    inParty = inParty,
                    rejectedScan = true,
                }
            end
            if DungeonBots.ConfirmPartyBotIdentity then
                DungeonBots:ConfirmPartyBotIdentity(cleanSender, false)
            end
            DungeonBots.justPromotedBotWhisper[cleanSender] = NowTime() + 1.0
            isKnownOrHistory = true
            justPromoted = true
        end

        if canConsumeClassSummon and not isKnownOrHistory and isBotText then
            if DungeonBots:ConsumePendingClassSummon() then
                DungeonBots:MarkRecentBot(cleanSender, 120)
                DungeonBots:RegisterBot(cleanSender, true)
                DungeonBots:RecordBotHistory(cleanSender)
                DungeonBots.justPromotedBotWhisper[cleanSender] = NowTime() + 1.0
                isKnownOrHistory = true
                justPromoted = true
            end
        end
    end

    return {
        isBot = isKnownOrHistory,
        isKnownOrHistory = isKnownOrHistory,
        inParty = inParty,
        hasPendingScan = hasPendingScan,
        canConsumeClassSummon = canConsumeClassSummon,
        isBotText = isBotText,
        justPromoted = justPromoted,
    }
end

function DungeonBots:ShouldSuppressChatEvent(event, message, sender)
    if not DungeonBotsDB or not sender or sender == "" then
        return false
    end

    local cleanName = NormalizePlayerName(sender)
    if not cleanName or cleanName == "" then
        return false
    end

    local playerName = UnitName and UnitName("player")
    if event ~= "CHAT_MSG_WHISPER_INFORM" and cleanName == playerName then
        return false
    end

    -- Nunca ocultar a jugadores marcados explícitamente como humanos
    if DungeonBots:IsBot(cleanName) == false then
        return false
    end

    local whisperMode = (DungeonBotsDB.whisperMuteMode == "off") and "off" or "all"
    local muteGroup = DungeonBotsDB.muteBotGroupChat and true or false

    if event == "CHAT_MSG_WHISPER_INFORM" then
        if whisperMode == "off" then
            return false
        end
        if DungeonBots:IsRecentAddonOutgoingWhisper(cleanName, message) then
            return true
        end
        return DungeonBots:ShouldTreatAsBot(cleanName)

    elseif event == "CHAT_MSG_WHISPER" then
        if whisperMode == "off" then
            return false
        end
        local eval = DungeonBots:EvaluateWhisperSender(cleanName, message, true)
        if eval and eval.isBusyExternal then
            return true
        end
        if not eval or not eval.isBot then
            return false
        end
        return true

    elseif event == "CHAT_MSG_AFK" or event == "CHAT_MSG_DND" then
        if whisperMode == "off" then
            return false
        end
        return DungeonBots:ShouldTreatAsBot(cleanName)

    elseif event == "CHAT_MSG_PARTY"
        or event == "CHAT_MSG_PARTY_LEADER"
        or event == "CHAT_MSG_RAID"
        or event == "CHAT_MSG_RAID_LEADER"
        or event == "CHAT_MSG_SAY"
        or event == "CHAT_MSG_YELL" then
        if whisperMode == "off" or not muteGroup then
            return false
        end
        return DungeonBots:ShouldTreatAsBot(cleanName)
    end

    return false
end

local function IsInventoryFullText(lowerText)
    if not lowerText or lowerText == "" then return false end
    return (string.find(lowerText, "my inventory is full", 1, true) ~= nil)
        or (string.find(lowerText, "inventory is full", 1, true) ~= nil)
        or (string.find(lowerText, "my bags are full", 1, true) ~= nil)
        or (string.find(lowerText, "bags are full", 1, true) ~= nil)
end

function DB_Internal.ExtractInventoryFullBotName(message, sender)
    if not message or message == "" then return nil end
    local clean = TrimText(StripWowFormatting(message))
    if clean == "" then return nil end

    local cand = nil
    local prefixName, rest = string.match(clean, "^(.-):%s*(.+)$")
    if prefixName and rest and IsInventoryFullText(string.lower(rest)) then
        cand = NormalizePlayerName(prefixName)
    elseif sender and sender ~= "" and IsInventoryFullText(string.lower(clean)) then
        cand = NormalizePlayerName(sender)
    end

    if not cand or cand == "" then return nil end
    local playerName = UnitName and NormalizePlayerName(UnitName("player"))
    if playerName and cand == playerName then return nil end

    if DungeonBots:ShouldTreatAsBot(cand) then
        return cand
    end
    return nil
end

local function ChatEventFilterFunc(self, event, message, sender, ...)
    if event ~= "CHAT_MSG_WHISPER_INFORM" and DB_Internal.ExtractInventoryFullBotName and DB_Internal.ExtractInventoryFullBotName(message, sender) then
        return true
    end
    if event == "CHAT_MSG_SYSTEM" then
        if not message or message == "" then return false end
        local clean = TrimText(StripWowFormatting(message))
        local lower = string.lower(clean)
        local isDismissWindow = (DungeonBots.suppressDismissNoiseUntil and NowTime() <= DungeonBots.suppressDismissNoiseUntil) and true or false
        if string.find(lower, "you have added too many bots", 1, true)
            or string.find(lower, "more than 4", 1, true)
            or string.find(lower, "demasiados bots", 1, true)
            or string.find(lower, "character '*' not found", 1, true)
            or string.match(lower, "^add:%s+.+%s+%-%s+ok%s*$")
            or string.match(lower, "^remove:%s+.+%s+%-%s+ok%s*$")
            or string.match(lower, "^remove:%s+.+%s+%-%s+player is offline%s*$")
            or string.match(lower, "^remove:%s+.+%s+%-%s+player not found%s*$")
            or string.match(lower, "^remove:%s+.+%s+%-%s+not found%s*$")
            or (isDismissWindow and string.match(lower, "^remove:%s+.+%s+%-%s+"))
            or (isDismissWindow and _G.ERR_NOT_IN_GROUP and _G.ERR_NOT_IN_GROUP ~= "" and lower == string.lower(_G.ERR_NOT_IN_GROUP))
            or string.find(lower, "^add class ")
            or string.find(lower, "^add class\r")
            or string.find(lower, "^add class\n") then
            return true
        end
        if DB_Internal.ExtractBusyBotFromSystem then
            local busyBot, busyKind = DB_Internal.ExtractBusyBotFromSystem(clean)
            if busyBot and (busyKind == "already_logged_in" or busyKind == "already_in_group") then
                local isTracked = DungeonBots:IsRecentBot(busyBot)
                    or (DungeonBots.HasPendingHistoryInvite and DungeonBots:HasPendingHistoryInvite(busyBot))
                    or (DungeonBots.IsHistoryBotLoading and DungeonBots:IsHistoryBotLoading(busyBot))
                    or (DungeonBots.GetExternalBotBusyInfo and DungeonBots:GetExternalBotBusyInfo(busyBot) ~= nil)
                    or (DungeonBots.pendingWhoCheck and DungeonBots.pendingWhoCheck[busyBot] ~= nil)
                if isTracked then
                    return true
                end
            end
        end
        return false
    end
    if DungeonBots:ShouldSuppressChatEvent(event, message, sender) then
        return true
    end
    if message and sender and string.find(message, "|H", 1, true) and DungeonBots.LocalizeHyperlinksInText then
        local cleanName = NormalizePlayerName(sender)
        if cleanName and DungeonBots:ShouldTreatAsBot(cleanName) then
            local localizedMsg = DungeonBots:LocalizeHyperlinksInText(message)
            if localizedMsg and localizedMsg ~= message then
                return false, localizedMsg, sender, ...
            end
        end
    end
    return false
end

function DungeonBots:SetupChatFilters()
    if chatFiltersRegistered or not ChatFrame_AddMessageEventFilter then return end
    chatFiltersRegistered = true
    local events = {
        "CHAT_MSG_SYSTEM",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_AFK",
        "CHAT_MSG_DND",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
    }
    for _, ev in ipairs(events) do
        ChatFrame_AddMessageEventFilter(ev, ChatEventFilterFunc)
    end
end

function DungeonBots:CloseBotWIMWindows()
    local wim = _G.WIM
    if not wim or not wim.windows or not wim.windows.active or not wim.windows.active.whisper then
        return
    end
    for winName, win in pairs(wim.windows.active.whisper) do
        local clean = NormalizePlayerName(winName)
        if clean and DungeonBots:ShouldTreatAsBot(clean) and win then
            if type(win) == "table" then
                if win.unreadCount ~= nil then
                    win.unreadCount = 0
                end
                if type(win.Hide) == "function" then
                    win:Hide()
                end
            end
        end
    end
end

local function WrapWIMController(modName, mod, methodName, blockItem)
    if not mod or type(mod[methodName]) ~= "function" then return end
    local key = modName .. ":" .. methodName
    if wimWrappedMethods[key] then return end
    wimWrappedMethods[key] = true

    local orig = mod[methodName]
    mod[methodName] = function(self, firstArg, ...)
        if type(firstArg) == "table" and type(firstArg.GetArgs) == "function" and type(firstArg.GetEvent) == "function" then
            local ev = firstArg:GetEvent()
            local msg, sender = firstArg:GetArgs()
            if DungeonBots:ShouldSuppressChatEvent(ev, msg, sender) then
                if blockItem and type(firstArg.Block) == "function" then
                    firstArg:Block()
                end
                return
            end
        end
        return orig(self, firstArg, ...)
    end
end

local function WrapWIMSound(modName, mod, methodName, fixedEvent)
    if not mod or type(mod[methodName]) ~= "function" then return end
    local key = modName .. ":" .. methodName
    if wimWrappedMethods[key] then return end
    wimWrappedMethods[key] = true

    local orig = mod[methodName]
    mod[methodName] = function(self, firstArg, secondArg, thirdArg, ...)
        local ev = fixedEvent or firstArg
        local msg = fixedEvent and firstArg or secondArg
        local sender = fixedEvent and secondArg or thirdArg
        if type(ev) == "string" and DungeonBots:ShouldSuppressChatEvent(ev, msg, sender) then
            return
        end
        return orig(self, firstArg, secondArg, thirdArg, ...)
    end
end

local WIM_CONTROLLER_MAP = {
    Filters = { "CHAT_MSG_WHISPER_CONTROLLER", "CHAT_MSG_WHISPER_INFORM_CONTROLLER" },
    WhisperEngine = { "CHAT_MSG_WHISPER_CONTROLLER", "CHAT_MSG_WHISPER_INFORM_CONTROLLER", "CHAT_MSG_AFK_CONTROLLER", "CHAT_MSG_DND_CONTROLLER" },
    ChatFilters = { "CHAT_MSG_PARTY_CONTROLLER", "CHAT_MSG_PARTY_LEADER_CONTROLLER", "CHAT_MSG_RAID_CONTROLLER", "CHAT_MSG_RAID_LEADER_CONTROLLER", "CHAT_MSG_SAY_CONTROLLER" },
    PartyChat = { "CHAT_MSG_PARTY_CONTROLLER", "CHAT_MSG_PARTY_LEADER_CONTROLLER" },
    RaidChat = { "CHAT_MSG_RAID_CONTROLLER", "CHAT_MSG_RAID_LEADER_CONTROLLER" },
    SayChat = { "CHAT_MSG_SAY_CONTROLLER" },
    BattlegroundChat = { "CHAT_MSG_BATTLEGROUND_CONTROLLER", "CHAT_MSG_BATTLEGROUND_LEADER_CONTROLLER" },
}

function DungeonBots:SetupWIMCompatibility()
    local wim = _G.WIM
    if not wim or not wim.modules then return end

    for modName, methods in pairs(WIM_CONTROLLER_MAP) do
        local mod = wim.modules[modName]
        if mod then
            for _, methodName in ipairs(methods) do
                WrapWIMController(modName, mod, methodName, true)
            end
        end
    end
    if wim.modules.Sounds then
        WrapWIMSound("Sounds", wim.modules.Sounds, "PostEvent_Whisper", "CHAT_MSG_WHISPER")
        WrapWIMSound("Sounds", wim.modules.Sounds, "PostEvent_WhisperInform", "CHAT_MSG_WHISPER_INFORM")
    end
    if wim.modules.ChatSounds then
        WrapWIMSound("ChatSounds", wim.modules.ChatSounds, "PostEvent_ChatMessage", nil)
    end
end

function DungeonBots:HookSendChatForTalk()
    if sendChatHooked or not hooksecurefunc then return end
    sendChatHooked = true
    hooksecurefunc("SendChatMessage", function(msg, chatType, language, channel)
        if isSendingAddonWhisper or not msg or msg == "" then return end
        local cleanMsg = TrimText(msg)
        local lowerMsg = string.lower(cleanMsg)
        local isTalkCmd = (lowerMsg == "talk") or (string.match(lowerMsg, "^talk%s+.+$") ~= nil)
        local isAcceptFollowup = (DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown())
            and (lowerMsg == "accept *" or (string.match(lowerMsg, "^accept%s+.+$") ~= nil))

        if not isTalkCmd and not isAcceptFollowup then
            return
        end

        if chatType == "WHISPER" and channel then
            local cleanTarget = NormalizePlayerName(channel)
            if cleanTarget and DungeonBots:ShouldTreatAsBot(cleanTarget) then
                DungeonBots:MarkAddonOutgoingWhisper(cleanTarget, msg, 4.0)
                DungeonBots:ArmTalkCapture(cleanTarget, cleanMsg, isTalkCmd or isAcceptFollowup)
            end
        elseif (chatType == "PARTY" or chatType == "SAY") and isTalkCmd then
            DungeonBots:ArmPartyTalkCapture(cleanMsg)
        end
    end)
end

-- =========================================================================
-- Chequeo Silencioso de Versión entre Clientes (SendAddonMessage)
-- =========================================================================
local ADDON_COMM_PREFIX = "DungeonBots"
local VERSION_BROADCAST_COOLDOWN = {
    GUILD = 300.0,
    RAID = 60.0,
    PARTY = 60.0,
}

local versionBroadcastLastAt = {}
local versionReplyLastAt = {}
local outdatedVersionNotified = false
local versionCheckPendingAt = nil
local versionCheckFrame = CreateFrame("Frame")
versionCheckFrame:Hide()

local function ParseSemverTuple(verStr)
    if type(verStr) ~= "string" then return nil end
    local maj, min, pat = string.match(verStr, "^(%d+)%.(%d+)%.?(%d*)$")
    if not maj or not min then return nil end
    return { tonumber(maj) or 0, tonumber(min) or 0, tonumber(pat) or 0 }
end

local function CompareVersionStrings(verA, verB)
    local a = ParseSemverTuple(verA)
    local b = ParseSemverTuple(verB)
    if not a or not b then return 0 end
    for i = 1, 3 do
        if a[i] > b[i] then return 1 end
        if a[i] < b[i] then return -1 end
    end
    return 0
end

local function PartyHasPotentialHumanMember()
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        return true
    end
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if numParty <= 0 then return false end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists and UnitExists(unit) then
            local memberName = UnitName and UnitName(unit)
            if memberName and memberName ~= "" and memberName ~= UNKNOWNOBJECT and memberName ~= "Unknown" then
                if not (DungeonBots.ShouldTreatAsBot and DungeonBots:ShouldTreatAsBot(memberName)) then
                    return true
                end
            end
        end
    end
    return false
end

local function SafeSendVersionAddonMessage(channel, target)
    if not SendAddonMessage or not DungeonBots.VERSION then return end
    local localVer = tostring(DungeonBots.VERSION)
    if not ParseSemverTuple(localVer) then return end
    pcall(SendAddonMessage, ADDON_COMM_PREFIX, "VER:" .. localVer, channel, target)
end

function DungeonBots:BroadcastAddonVersion(forceGuild)
    if not SendAddonMessage then return end
    local now = NowTime()
    if IsInGuild and IsInGuild() then
        local lastGuild = versionBroadcastLastAt.GUILD or 0
        if forceGuild or (lastGuild + VERSION_BROADCAST_COOLDOWN.GUILD) <= now then
            versionBroadcastLastAt.GUILD = now
            SafeSendVersionAddonMessage("GUILD")
        end
    end
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        if (versionBroadcastLastAt.RAID or 0) + VERSION_BROADCAST_COOLDOWN.RAID <= now then
            versionBroadcastLastAt.RAID = now
            SafeSendVersionAddonMessage("RAID")
        end
    elseif GetNumPartyMembers and GetNumPartyMembers() > 0 and PartyHasPotentialHumanMember() then
        if (versionBroadcastLastAt.PARTY or 0) + VERSION_BROADCAST_COOLDOWN.PARTY <= now then
            versionBroadcastLastAt.PARTY = now
            SafeSendVersionAddonMessage("PARTY")
        end
    end
end

function DungeonBots:ScheduleVersionBroadcast(delaySeconds, includeGuild)
    local now = NowTime()
    local targetAt = now + (delaySeconds or 3.5)
    if not versionCheckPendingAt or targetAt < versionCheckPendingAt then
        versionCheckPendingAt = targetAt
    end
    if includeGuild then
        versionCheckFrame.includeGuild = true
    end
    versionCheckFrame:Show()
end

versionCheckFrame:SetScript("OnUpdate", function(self)
    if not versionCheckPendingAt then
        self:Hide()
        return
    end
    if NowTime() >= versionCheckPendingAt then
        local forceGuild = self.includeGuild and true or false
        versionCheckPendingAt = nil
        self.includeGuild = false
        self:Hide()
        DungeonBots:BroadcastAddonVersion(forceGuild)
    end
end)

function DB_Internal.HandleVersionAddonMessage(prefix, message, channel, sender)
    if prefix ~= ADDON_COMM_PREFIX or type(message) ~= "string" then return end
    if channel ~= "GUILD" and channel ~= "PARTY" and channel ~= "RAID" and channel ~= "BATTLEGROUND" and channel ~= "WHISPER" then
        return
    end
    local cleanSender = NormalizePlayerName(sender)
    local myName = UnitName and NormalizePlayerName(UnitName("player"))
    if not cleanSender or cleanSender == "" or (myName and cleanSender == myName) then
        return
    end

    local remoteVer = string.match(message, "^VER:(%d+%.%d+%.?%d*)$")
    if not remoteVer then return end

    local localVer = tostring(DungeonBots.VERSION or "")
    local cmp = CompareVersionStrings(remoteVer, localVer)
    if cmp > 0 then
        if not outdatedVersionNotified then
            outdatedVersionNotified = true
            local msgFmt = (DungeonBots.L and DungeonBots.L["OUTDATED_VERSION_FMT"]) or L["OUTDATED_VERSION_FMT"]
            if DungeonBots.Print and msgFmt then
                DungeonBots:Print(string.format(msgFmt, remoteVer, localVer))
            end
        end
    elseif cmp < 0 then
        local now = NowTime()
        if (versionReplyLastAt[cleanSender] or 0) + 300.0 <= now then
            versionReplyLastAt[cleanSender] = now
            SafeSendVersionAddonMessage("WHISPER", cleanSender)
        end
    end
end
