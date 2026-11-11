-- =========================================================================
-- DungeonBots_Comms.lua: Comandos, Cola de Susurros, Filtros de Chat y WIM
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal

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
    DungeonBots:MarkAddonOutgoingWhisper(botName, cmd, 4.0)
    isSendingAddonWhisper = true
    SendChatMessage(cmd, "WHISPER", nil, botName)
    isSendingAddonWhisper = false
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
        if item and item.botName and item.cmd and DungeonBots:FindPartyUnitByName(item.botName) then
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

function DungeonBots:QueueWhisperCommand(botName, cmd, atFront)
    if not botName or botName == "" or not cmd or cmd == "" then return end
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
        or string.find(lowerMsg, "money:")
        or string.find(lowerMsg, "greetings")
        or string.find(lowerMsg, "ready")
        or string.find(lowerMsg, "active quests")
        or string.find(lowerMsg, "completed quests")
        or string.find(lowerMsg, "no active quests")
        or string.find(lowerMsg, "no quests")
        or string.find(lowerMsg, "|hquest:")
        or string.find(lowerMsg, "autogear")
        or string.find(lowerMsg, "nothing to say")
        or string.find(lowerMsg, "no npc")
        or string.find(lowerMsg, "=== inventory ===")
        or string.find(lowerMsg, "inventory is empty")
        or string.match(lowerMsg, "%d+[-/]%d+[-/]%d+")) and true or false
end

function DungeonBots:EvaluateWhisperSender(cleanSender, message, allowPromote)
    if not cleanSender or cleanSender == "" then
        return { isBot = false }
    end
    if DungeonBots:IsBot(cleanSender) == false then
        return { isBot = false, explicitHuman = true }
    end

    local inParty = (DungeonBots:FindPartyUnitByName(cleanSender) ~= nil)
    local isKnownOrHistory = DungeonBots:ShouldTreatAsBot(cleanSender)
    local hasPendingScan = DungeonBots:HasPendingScan(cleanSender)
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    local inRaid = (GetNumRaidMembers and GetNumRaidMembers() > 0)
    local canConsumeClassSummon = (not isKnownOrHistory)
        and (not hasPendingScan)
        and (not inParty)
        and (not inRaid)
        and (numParty < 4)
        and DungeonBots:HasPendingClassSummon()

    local isBotText = DB_Internal.IsBotDetectionText(message)
    local justPromoted = ((DungeonBots.justPromotedBotWhisper[cleanSender] or 0) > NowTime())

    if not isKnownOrHistory and not hasPendingScan and not canConsumeClassSummon then
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
            DungeonBots.pendingScan[cleanSender] = nil
            DungeonBots.confirmedBots[cleanSender] = true
            DungeonBots:MarkRecentBot(cleanSender, 120)
            DungeonBots:RegisterBot(cleanSender, true)
            DungeonBots:RecordBotHistory(cleanSender)
            DungeonBots.justPromotedBotWhisper[cleanSender] = NowTime() + 1.0
            DungeonBots:Print("Bot confirmado: |cff00e5ff" .. cleanSender .. "|r (respondió automáticamente como bot).")
            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
            isKnownOrHistory = true
            justPromoted = true
        end

        if canConsumeClassSummon and not isKnownOrHistory then
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
        or event == "CHAT_MSG_SAY"
        or event == "CHAT_MSG_YELL" then
        if whisperMode == "off" or not muteGroup then
            return false
        end
        return DungeonBots:ShouldTreatAsBot(cleanName)
    end

    return false
end

local function ChatEventFilterFunc(self, event, message, sender, ...)
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
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_AFK",
        "CHAT_MSG_DND",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
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

function DungeonBots:SetupWIMCompatibility()
    local wim = _G.WIM
    if not wim or not wim.modules then return end

    if wim.modules.Filters then
        WrapWIMController("Filters", wim.modules.Filters, "CHAT_MSG_WHISPER_CONTROLLER", true)
        WrapWIMController("Filters", wim.modules.Filters, "CHAT_MSG_WHISPER_INFORM_CONTROLLER", true)
    end
    if wim.modules.ChatFilters then
        WrapWIMController("ChatFilters", wim.modules.ChatFilters, "CHAT_MSG_PARTY_CONTROLLER", true)
        WrapWIMController("ChatFilters", wim.modules.ChatFilters, "CHAT_MSG_PARTY_LEADER_CONTROLLER", true)
        WrapWIMController("ChatFilters", wim.modules.ChatFilters, "CHAT_MSG_SAY_CONTROLLER", true)
    end
    if wim.modules.WhisperEngine then
        WrapWIMController("WhisperEngine", wim.modules.WhisperEngine, "CHAT_MSG_AFK", true)
        WrapWIMController("WhisperEngine", wim.modules.WhisperEngine, "CHAT_MSG_DND", true)
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
