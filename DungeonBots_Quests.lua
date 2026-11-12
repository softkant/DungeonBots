-- =========================================================================
-- DungeonBots_Quests.lua: Misiones de Bots, Diálogo Talk y Asistente Dalaran
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

local function ExtractSafeQuestLinkFromText(line)
    return DB_Internal.ExtractSafeQuestLinkFromText(line)
end

-- =========================================================================
-- Consulta y Abandono de Misiones del Bot (quests all / drop)
-- =========================================================================
DungeonBots.botQuestCounts = DungeonBots.botQuestCounts or {}

local pendingQuestCountQueue = {}
local nextQuestCountDispatchAt = 0

local function RemoveQueuedQuestCount(cleanBot)
    if not cleanBot then return end
    for i = #pendingQuestCountQueue, 1, -1 do
        if pendingQuestCountQueue[i].botName == cleanBot then
            table.remove(pendingQuestCountQueue, i)
        end
    end
end

local function UpdateBotQuestCountCache(cleanBot, count, timestamp)
    if not cleanBot or count == nil then return end
    DungeonBots.botQuestCounts = DungeonBots.botQuestCounts or {}
    local prev = DungeonBots.botQuestCounts[cleanBot]
    local normalized = math.max(0, tonumber(count) or 0)
    local changed = (not prev) or (prev.count ~= normalized)
    DungeonBots.botQuestCounts[cleanBot] = {
        count = normalized,
        updatedAt = timestamp or NowTime(),
    }
    if changed and DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
end

function DungeonBots:QueryQuests(botName, isSilent, suppressDialog)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot then return end
    local now = NowTime()
    if not suppressDialog then
        RemoveQueuedQuestCount(cleanBot)
    end
    DungeonBots.pendingTalkCapture[cleanBot] = nil
    DungeonBots.pendingTalkRefresh[cleanBot] = nil
    DungeonBots.pendingQuestCapture[cleanBot] = {
        startedAt = now,
        expiresAt = now + 3.5,
        finalizeAt = now + 2.2,
        gotAnyLine = false,
        silent = (suppressDialog == true),
    }
    DungeonBots.questDialogData[cleanBot] = {
        botName = cleanBot,
        loading = true,
        done = false,
        captureSection = "active",
        quests = {},
        seenKeys = {},
        rawLines = {},
        emptyHint = nil,
        updatedAt = now,
    }
    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end
    if not suppressDialog or (DungeonBots.questFrame and DungeonBots.questFrame:IsShown() and DungeonBots.questFrame.currentBot == cleanBot) then
        if DungeonBots.OpenQuestDialog then
            DungeonBots:OpenQuestDialog(cleanBot)
        end
    end
    if not isSilent then
        local muteMode = (DungeonBotsDB and DungeonBotsDB.whisperMuteMode) or "auto"
        if muteMode == "off" then
            DungeonBots:Print("Consultando misiones de |cffffd200" .. cleanBot .. "|r...")
        end
    end
    DungeonBots:SendWhisperCommand(cleanBot, "quests all")
end

function DungeonBots:QueryBotQuestCount(botName, force, delaySeconds)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot then return end
    if DungeonBots.FindPartyUnitByName and not DungeonBots:FindPartyUnitByName(cleanBot) then return end
    if DungeonBots.ShouldTreatAsBot and not DungeonBots:ShouldTreatAsBot(cleanBot) then return end

    local now = NowTime()
    local cached = DungeonBots.botQuestCounts and DungeonBots.botQuestCounts[cleanBot]
    if not force and cached and (now - (cached.updatedAt or 0)) < 10.0 then
        return
    end
    if DungeonBots.pendingQuestCapture and DungeonBots.pendingQuestCapture[cleanBot] then
        return
    end

    local sendAt = now + (delaySeconds or 0.25)
    for _, entry in ipairs(pendingQuestCountQueue) do
        if entry.botName == cleanBot then
            if force then
                entry.sendAt = math.min(entry.sendAt, sendAt)
            end
            if DungeonBots.uiCaptureFrame then
                DungeonBots.uiCaptureFrame:Show()
            end
            return
        end
    end

    table.insert(pendingQuestCountQueue, {
        botName = cleanBot,
        sendAt = sendAt,
    })
    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end
end

function DungeonBots:QueryPartyBotQuestCounts(forceAll)
    local delay = 0.25
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and DungeonBots:ShouldTreatAsBot(name) then
                DungeonBots:QueryBotQuestCount(name, forceAll, delay)
                delay = delay + 0.15
            end
        end
    end
end

-- Abandonar una misión de un bot y refrescar la ventana correspondiente
function DungeonBots:DropBotQuest(botName, questEntry, fromTalkDialog)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or not questEntry then return end
    local rawTitle = questEntry.rawTitle or questEntry.title
    local target = questEntry.safeLink or rawTitle
    if not target or target == "" then return end
    local now = NowTime()
    local qKey = questEntry.questId and ("id_" .. tostring(questEntry.questId)) or (rawTitle and ("t_" .. string.lower(rawTitle)))
    local tKey = "quest_" .. (questEntry.questId or (rawTitle and string.lower(rawTitle) or ""))

    local data = DungeonBots.questDialogData and DungeonBots.questDialogData[cleanBot]
    if data and type(data.quests) == "table" then
        for i = #data.quests, 1, -1 do
            local q = data.quests[i]
            if q == questEntry or (questEntry.questId and q.questId == questEntry.questId) then
                table.remove(data.quests, i)
            end
        end
        if data.seenKeys and qKey then
            data.seenKeys[qKey] = nil
        end
        UpdateBotQuestCountCache(cleanBot, #(data.quests), now)
    elseif DungeonBots.botQuestCounts and DungeonBots.botQuestCounts[cleanBot] then
        UpdateBotQuestCountCache(cleanBot, math.max(0, (DungeonBots.botQuestCounts[cleanBot].count or 0) - 1), now)
    end

    local talkData = DungeonBots.talkDialogData and DungeonBots.talkDialogData[cleanBot]
    if talkData and type(talkData.actions) == "table" then
        for i = #talkData.actions, 1, -1 do
            local act = talkData.actions[i]
            local actRaw = act.rawTitle or act.title
            if act == questEntry or (act.kind == "quest" and ((questEntry.questId and act.questId == questEntry.questId) or (rawTitle and actRaw == rawTitle))) then
                table.remove(talkData.actions, i)
            end
        end
        if talkData.seenActions and tKey ~= "quest_" then
            talkData.seenActions[tKey] = nil
        end
        if fromTalkDialog and #talkData.actions == 0 then
            talkData.loading = true
        end
    end

    if DungeonBots.pendingQuestCapture then
        DungeonBots.pendingQuestCapture[cleanBot] = nil
    end
    if DungeonBots.pendingTalkCapture and fromTalkDialog then
        DungeonBots.pendingTalkCapture[cleanBot] = nil
    end

    local rawDisplay = questEntry.displayLink or questEntry.safeLink or ("|cffffff00[" .. (questEntry.title or target) .. "]|r")
    local qDisplay = DungeonBots.LocalizeHyperlinksInText and DungeonBots:LocalizeHyperlinksInText(rawDisplay) or rawDisplay
    PlaySound("igQuestFailed")
    DungeonBots:SendWhisperCommand(cleanBot, "drop " .. target)
    DungeonBots:Print("|cffffd200" .. cleanBot .. "|r abandonó la misión: " .. qDisplay)

    if DungeonBots.UpdateQuestDialog and DungeonBots.questFrame and DungeonBots.questFrame:IsShown() and DungeonBots.questFrame.currentBot == cleanBot then
        DungeonBots:UpdateQuestDialog(cleanBot)
    end
    if DungeonBots.UpdateTalkDialog and DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown() and DungeonBots.talkFrame.currentBot == cleanBot then
        DungeonBots:UpdateTalkDialog(cleanBot)
    end

    if fromTalkDialog then
        DungeonBots.pendingTalkRefresh[cleanBot] = now + 0.55
    else
        DungeonBots.pendingQuestRefresh[cleanBot] = now + 0.55
        if DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown() and DungeonBots.talkFrame.currentBot == cleanBot then
            DungeonBots.pendingTalkAfterQuest[cleanBot] = true
        end
    end
    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end
end

-- =========================================================================
-- Sistema Talk e Interacción con PNJs
-- =========================================================================
function DungeonBots:HasValidNpcTarget()
    if not UnitExists("target") then
        return false
    end
    if UnitIsPlayer("target") or UnitPlayerControlled("target") then
        return false
    end
    if UnitIsDead("target") then
        return false
    end
    return true
end

function DungeonBots:IsTalkBusy(botName)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot then return false end
    local data = DungeonBots.talkDialogData and DungeonBots.talkDialogData[cleanBot]
    if data and data.loading then
        return true
    end
    if DungeonBots.pendingTalkCapture and DungeonBots.pendingTalkCapture[cleanBot] then
        return true
    end
    if DungeonBots.pendingTalkRefresh and DungeonBots.pendingTalkRefresh[cleanBot] then
        return true
    end
    return false
end

function DungeonBots:GetPartyBotsList()
    local bots = {}
    local seen = {}
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local rawName = UnitName(unit)
            local name = NormalizePlayerName(rawName)
            if name and name ~= "" and name ~= UNKNOWNOBJECT and name ~= "Unknown" and not seen[name] then
                if DungeonBots:ShouldTreatAsBot(name) then
                    seen[name] = true
                    local _, classToken = UnitClass(unit)
                    local activeSpec = DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[name]
                    table.insert(bots, {
                        unit = unit,
                        name = name,
                        classToken = classToken,
                        spec = activeSpec,
                    })
                end
            end
        end
    end
    return bots
end

function DungeonBots:GetTalkBotCycleInfo(currentBot)
    local bots = DungeonBots:GetPartyBotsList()
    local total = #bots
    if total == 0 then
        return 0, 0, nil
    end
    local cleanCurrent = NormalizePlayerName(currentBot)
    local curIdx = 0
    if cleanCurrent then
        for i, b in ipairs(bots) do
            if b.name == cleanCurrent then
                curIdx = i
                break
            end
        end
    end
    local nextIdx = (curIdx % total) + 1
    return curIdx, total, bots[nextIdx].name
end

function DungeonBots:CycleNextTalkBot(currentBot)
    local _, total, nextBot = DungeonBots:GetTalkBotCycleInfo(currentBot)
    if not nextBot or total < 2 then
        return
    end
    DungeonBots:SendTalkCommand(nextBot, "talk")
end

function DungeonBots:FindDefaultTalkBot()
    if UnitExists("target") and UnitIsPlayer("target") then
        local targetName = NormalizePlayerName(UnitName("target"))
        if targetName and DungeonBots:ShouldTreatAsBot(targetName) then
            return targetName
        end
    end
    if DungeonBots.lastTalkBot and DungeonBots:FindPartyUnitByName(DungeonBots.lastTalkBot) then
        return DungeonBots.lastTalkBot
    end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = NormalizePlayerName(UnitName(unit))
            if name and DungeonBots:ShouldTreatAsBot(name) then
                return name
            end
        end
    end
    return DungeonBots.lastTalkBot
end

function DungeonBots:ArmTalkCapture(botName, cmd, resetLines)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot then return end
    local now = NowTime()
    local lowerCmd = string.lower(TrimText(cmd or "talk"))
    local isAcceptCmd = (lowerCmd == "accept *" or lowerCmd == "accept" or string.match(lowerCmd, "^accept%s+.+$") ~= nil)
    local pendingAcceptTarget = nil
    if isAcceptCmd then
        local arg = TrimText(string.match(TrimText(cmd or ""), "^[Aa][Cc][Cc][Ee][Pp][Tt]%s+(.+)$") or "")
        if arg ~= "" and arg ~= "*" then
            pendingAcceptTarget = arg
        end
    end
    DungeonBots.pendingQuestCapture[cleanBot] = nil
    DungeonBots.pendingTalkRefresh[cleanBot] = nil
    DungeonBots.lastTalkBot = cleanBot
    local data = DungeonBots.talkDialogData[cleanBot]
    if resetLines or not data then
        data = {
            botName = cleanBot,
            npcName = (UnitExists("target") and not UnitIsPlayer("target")) and UnitName("target") or (data and data.npcName) or nil,
            lastCmd = cmd or "talk",
            isAcceptCmd = isAcceptCmd,
            acceptError = false,
            rangeError = false,
            playedAcceptSound = false,
            printedAcceptMsg = false,
            printedAcceptKeys = {},
            pendingAcceptTarget = pendingAcceptTarget,
            loading = true,
            done = false,
            lines = {},
            actions = {},
            seenActions = {},
            updatedAt = now,
        }
        DungeonBots.talkDialogData[cleanBot] = data
    else
        data.loading = true
        data.done = false
        data.lastCmd = cmd or data.lastCmd or "talk"
        data.isAcceptCmd = isAcceptCmd
        data.acceptError = false
        data.rangeError = false
        data.playedAcceptSound = false
        data.printedAcceptMsg = false
        data.printedAcceptKeys = {}
        data.pendingAcceptTarget = pendingAcceptTarget
        if UnitExists("target") and not UnitIsPlayer("target") then
            data.npcName = UnitName("target")
        end
    end
    DungeonBots.pendingTalkCapture[cleanBot] = {
        startedAt = now,
        expiresAt = now + (isAcceptCmd and 1.8 or 3.0),
        finalizeAt = nil,
        gotAnyLine = false,
        isAcceptCmd = isAcceptCmd,
    }
    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end
    if DungeonBots.OpenTalkDialog then
        DungeonBots:OpenTalkDialog(cleanBot)
    end
end

function DungeonBots:ArmPartyTalkCapture(cmd)
    local now = NowTime()
    DungeonBots.pendingPartyTalkUntil = now + 3.0
    DungeonBots.pendingPartyTalkCmd = cmd or "talk"
    DungeonBots.pendingPartyTalkNpc = (UnitExists("target") and not UnitIsPlayer("target")) and UnitName("target") or nil
end

function DungeonBots:SendTalkCommand(botName, cmd)
    local cleanBot = NormalizePlayerName(botName) or DungeonBots:FindDefaultTalkBot()
    if not cleanBot then
        DungeonBots:Warn("No hay ningún bot en el grupo para hablar con el PNJ.")
        return
    end
    local cleanCmd = TrimText(cmd or "talk")
    if cleanCmd == "" then cleanCmd = "talk" end
    DungeonBots:ArmTalkCapture(cleanBot, cleanCmd, true)
    DungeonBots:SendWhisperCommand(cleanBot, cleanCmd)
end

-- =========================================================================
-- Asistente Dalaran y Cadena Forja/Foso/Cámaras (60s Timer)
-- =========================================================================
function DungeonBots:DalaranPrep()
    if not UnitExists("target") then
        DungeonBots:Warn("¡Atención! Selecciona primero al PNJ que da la misión en Dalaran.")
    end
    DungeonBots:Print("Ejecutando preparación en Dalaran (Summon + Aceptar misiones)...")
    DungeonBots:SendPartyCommand("summon")
    DungeonBots:SendPartyCommand("accept *")
    DungeonBots:StartDalaranTimer(60)
end

function DungeonBots:DungeonReenter()
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and DungeonBots:ShouldTreatAsBot(name) then
                DungeonBots:MarkRecentBot(name, 60)
            end
        end
    end
    DungeonBots:Print("Reinvocando grupo dentro de la mazmorra...")
    DungeonBots:SendDotCommand(".playerbots bot add *")
    DungeonBots:SendPartyCommand("summon")
end

function DungeonBots:DungeonTurnInAndAccept()
    if not UnitExists("target") then
        DungeonBots:Warn("Selecciona al PNJ de la misión dentro de la mazmorra.")
    end
    DungeonBots:Print("Entregando y aceptando misiones del PNJ seleccionado...")
    DungeonBots:SendPartyCommand("accept *")
end

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

function DungeonBots:StartDalaranTimer(seconds)
    DungeonBots.dalaranTimeRemaining = seconds or 60
    DungeonBots.isDalaranTimerRunning = true
    timerFrame.lastUpdate = 0
    timerFrame:Show()
    PlaySound("RaidWarning")
    DungeonBots:Print("|cffff3b30¡Temporizador de Dalaran iniciado (60s)!|r Los bots desaparecerán al llegar a 0.")
    if DungeonBots.UpdateDalaranTimerUI then
        DungeonBots:UpdateDalaranTimerUI(DungeonBots.dalaranTimeRemaining)
    end
end

function DungeonBots:StopDalaranTimer()
    DungeonBots.isDalaranTimerRunning = false
    DungeonBots.dalaranTimeRemaining = 0
    timerFrame:Hide()
    if DungeonBots.UpdateDalaranTimerUI then
        DungeonBots:UpdateDalaranTimerUI(0)
    end
end

timerFrame:SetScript("OnUpdate", function(self, elapsed)
    self.lastUpdate = (self.lastUpdate or 0) + elapsed
    if self.lastUpdate >= 1.0 then
        self.lastUpdate = 0
        if DungeonBots.dalaranTimeRemaining > 0 then
            DungeonBots.dalaranTimeRemaining = DungeonBots.dalaranTimeRemaining - 1
            if DungeonBots.UpdateDalaranTimerUI then
                DungeonBots:UpdateDalaranTimerUI(DungeonBots.dalaranTimeRemaining)
            end
            if DungeonBots.dalaranTimeRemaining == 15 then
                PlaySound("RaidWarning")
                DungeonBots:Warn("¡Quedan 15 segundos antes de que los bots desaparezcan en Dalaran!")
            elseif DungeonBots.dalaranTimeRemaining == 0 then
                PlaySound("igQuestFailed")
                DungeonBots:Warn("¡Tiempo expirado! Los bots han desaparecido en Dalaran. Entra a Forja y pulsa 'Reinvocar en Mazmorra'.")
                DungeonBots:StopDalaranTimer()
            end
        else
            DungeonBots:StopDalaranTimer()
        end
    end
end)

-- =========================================================================
-- Frame de Captura UI y Parsers de Misiones / Diálogos Talk
-- =========================================================================
local uiCaptureFrame = CreateFrame("Frame")
uiCaptureFrame:Hide()
DungeonBots.uiCaptureFrame = uiCaptureFrame

uiCaptureFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = NowTime()
    local hasAny = false

    for botName, refreshAt in pairs(DungeonBots.pendingQuestRefresh) do
        if now >= refreshAt then
            DungeonBots.pendingQuestRefresh[botName] = nil
            local keepClosed = not (DungeonBots.questFrame and DungeonBots.questFrame:IsShown() and DungeonBots.questFrame.currentBot == botName)
            DungeonBots:QueryQuests(botName, true, keepClosed)
        else
            hasAny = true
        end
    end

    for botName, refreshAt in pairs(DungeonBots.pendingTalkRefresh) do
        if now >= refreshAt then
            DungeonBots.pendingTalkRefresh[botName] = nil
            if DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown() and DungeonBots.talkFrame.currentBot == botName then
                DungeonBots:SendTalkCommand(botName, "talk")
            end
        else
            hasAny = true
        end
    end

    for botName, cap in pairs(DungeonBots.pendingQuestCapture) do
        if now >= (cap.finalizeAt or cap.expiresAt or 0) or now >= (cap.expiresAt or 0) then
            DungeonBots.pendingQuestCapture[botName] = nil
            nextQuestCountDispatchAt = math.max(nextQuestCountDispatchAt, now + 0.15)
            local data = DungeonBots.questDialogData[botName]
            if data then
                data.loading = false
                data.done = true
                if cap.gotAnyLine or data.emptyHint or #(data.quests or {}) > 0 then
                    UpdateBotQuestCountCache(botName, #(data.quests or {}), now)
                end
                if not cap.silent or (DungeonBots.questFrame and DungeonBots.questFrame:IsShown() and DungeonBots.questFrame.currentBot == botName) then
                    if DungeonBots.UpdateQuestDialog then
                        DungeonBots:UpdateQuestDialog(botName)
                    end
                end
            end
            if DungeonBots.pendingTalkAfterQuest and DungeonBots.pendingTalkAfterQuest[botName] then
                DungeonBots.pendingTalkAfterQuest[botName] = nil
                if DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown() and DungeonBots.talkFrame.currentBot == botName then
                    DungeonBots.pendingTalkRefresh[botName] = now + 0.10
                    hasAny = true
                end
            end
        else
            hasAny = true
        end
    end

    for botName, cap in pairs(DungeonBots.pendingTalkCapture) do
        local readyToFinalize = (cap.gotAnyLine and cap.finalizeAt and now >= cap.finalizeAt)
        if readyToFinalize or now >= (cap.expiresAt or 0) then
            DungeonBots.pendingTalkCapture[botName] = nil
            local data = DungeonBots.talkDialogData[botName]
            if data then
                data.loading = false
                data.done = true
                if cap.isAcceptCmd then
                    if data.acceptError then
                        if not data.playedAcceptSound then
                            data.playedAcceptSound = true
                            PlaySound("igQuestFailed")
                        end
                    else
                        if not data.playedAcceptSound then
                            data.playedAcceptSound = true
                            PlaySound("QUESTADDED")
                        end
                        if not data.printedAcceptMsg and data.pendingAcceptTarget then
                            data.printedAcceptMsg = true
                            local acceptDisplay = DungeonBots.LocalizeHyperlinksInText and DungeonBots:LocalizeHyperlinksInText(data.pendingAcceptTarget) or data.pendingAcceptTarget
                            DungeonBots:Print("|cffffd200" .. botName .. "|r aceptó la misión: " .. acceptDisplay)
                        end
                        if DungeonBots.QueryBotQuestCount then
                            DungeonBots:QueryBotQuestCount(botName, true, 0.90)
                        end
                        if DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown() and DungeonBots.talkFrame.currentBot == botName then
                            DungeonBots.pendingTalkRefresh[botName] = now + 0.15
                            hasAny = true
                        end
                    end
                end
                if DungeonBots.UpdateTalkDialog then
                    DungeonBots:UpdateTalkDialog(botName)
                end
            end
        else
            hasAny = true
        end
    end

    if #pendingQuestCountQueue > 0 then
        local hasActiveQuestCap = next(DungeonBots.pendingQuestCapture) ~= nil
        local hasActiveTalkCap = next(DungeonBots.pendingTalkCapture) ~= nil
        local hasActiveSpellsCap = DungeonBots.pendingSpellsCapture and (next(DungeonBots.pendingSpellsCapture) ~= nil)
        if not hasActiveQuestCap and not hasActiveTalkCap and not hasActiveSpellsCap and now >= nextQuestCountDispatchAt then
            local bestIdx = nil
            local bestSendAt = nil
            for idx = 1, #pendingQuestCountQueue do
                local item = pendingQuestCountQueue[idx]
                local sAt = item.sendAt or 0
                if now >= sAt and (not bestSendAt or sAt < bestSendAt) then
                    bestIdx = idx
                    bestSendAt = sAt
                end
            end
            if bestIdx then
                local item = table.remove(pendingQuestCountQueue, bestIdx)
                if (not DungeonBots.FindPartyUnitByName or DungeonBots:FindPartyUnitByName(item.botName))
                    and (not DungeonBots.ShouldTreatAsBot or DungeonBots:ShouldTreatAsBot(item.botName)) then
                    nextQuestCountDispatchAt = now + 0.85
                    DungeonBots:QueryQuests(item.botName, true, true)
                end
            end
        end
        if #pendingQuestCountQueue > 0 then
            hasAny = true
        end
    end

    if DB_Internal.TickInventoryCapture then
        hasAny = DB_Internal.TickInventoryCapture(now) or hasAny
    end
    if DB_Internal.TickSpellsCapture then
        hasAny = DB_Internal.TickSpellsCapture(now) or hasAny
    end

    if not hasAny then
        self:Hide()
    end
end)

function DB_Internal.ParseQuestCaptureWhisper(cleanSender, message)
    local cap = DungeonBots.pendingQuestCapture[cleanSender]
    if not cap then return false end

    local now = NowTime()
    if now > (cap.expiresAt or 0) then
        DungeonBots.pendingQuestCapture[cleanSender] = nil
        return false
    end

    local data = DungeonBots.questDialogData[cleanSender]
    if not data then return false end

    if (DB_Internal.IsPureTalentResponse and DB_Internal.IsPureTalentResponse(message))
        or (DB_Internal.IsInventoryDumpMessage and DB_Internal.IsInventoryDumpMessage(message))
        or (DB_Internal.ParseBotStatsWhisper and DB_Internal.ParseBotStatsWhisper(message)) then
        return false
    end

    cap.gotAnyLine = true
    cap.finalizeAt = math.min(cap.expiresAt, now + 0.75)
    data.loading = false
    data.updatedAt = now

    for rawLine in string.gmatch(message or "", "[^\r\n]+") do
        local line = TrimText(rawLine)
        local cleanLine = TrimText(StripWowFormatting(line))
        local lowerClean = string.lower(cleanLine)

        if cleanLine ~= "" then
            table.insert(data.rawLines, line)
            local hasQuestLink = (string.find(line, "|Hquest:", 1, true) ~= nil)
            local lowerMeta = hasQuestLink
                and string.lower(TrimText(StripWowFormatting(string.gsub(line, "|Hquest:[^|]+|h%[[^%]]+%]|h", " "))))
                or lowerClean

            if string.find(lowerMeta, "quest dropped", 1, true)
                or string.find(lowerMeta, "abandoned", 1, true) then
                -- Confirmación de abandono; no agregar como fila de misión
            elseif not hasQuestLink and (
                string.find(lowerClean, "no active quests", 1, true)
                or string.find(lowerClean, "0 active quests", 1, true)
                or string.find(lowerClean, "you have no quests", 1, true)
                or lowerClean == "no quests"
                or (lowerClean == "none" and #(data.quests) == 0)
            ) then
                data.emptyHint = cleanLine
                cap.finalizeAt = math.min(cap.finalizeAt, now + 0.25)
            elseif not hasQuestLink and (
                string.find(lowerClean, "no completed quests", 1, true)
                or string.find(lowerClean, "no incompleted quests", 1, true)
                or string.find(lowerClean, "no incomplete quests", 1, true)
                or lowerClean == "none"
            ) then
                -- Encabezado o resumen informativo vacío
            elseif not hasQuestLink and (
                string.find(lowerClean, "incompleted quests", 1, true)
                or string.find(lowerClean, "incomplete quests", 1, true)
                or string.find(lowerClean, "active quests", 1, true)
                or string.find(lowerClean, "^%-*%s*incompleted?")
                or string.find(lowerClean, "^%-*%s*active")
            ) then
                data.captureSection = "active"
            elseif not hasQuestLink and (
                string.find(lowerClean, "completed quests", 1, true)
                or string.find(lowerClean, "^%-*%s*completed")
            ) then
                data.captureSection = "completed"
            elseif not hasQuestLink and string.find(lowerClean, "summary", 1, true) then
                data.captureSection = "summary"
            elseif not hasQuestLink and (
                string.find(lowerClean, "^[-=]+$")
                or string.find(lowerClean, "^[-=]+.*[-=]+$")
                or string.find(lowerClean, "^total%s*:")
                or string.find(lowerClean, "^completed%s*:")
                or string.find(lowerClean, "^incompleted?%s*:")
                or string.find(lowerClean, "^%d+%s*/%s*%d+")
                or string.find(lowerClean, "^%d+%s+quests?")
                or string.find(lowerClean, "^%d+%s+incompleted?")
                or string.find(lowerClean, "^%d+%s+completed")
            ) then
                -- Separador o resumen numérico; no agregar como fila de misión
            else
                local scanPos = 1
                local foundLinkInLine = false
                while true do
                    local subLine = string.sub(line, scanPos)
                    local safeLink, sOff, eOff, plainH = ExtractSafeQuestLinkFromText(subLine)
                    if not plainH then break end

                    foundLinkInLine = true
                    local qId, qLevel, rawTitle = string.match(plainH, "^|Hquest:(%d+):(-?%d*)|h%[([^%]]+)%]|h$")
                    rawTitle = rawTitle or StripWowFormatting(plainH)
                    local dedupKey = qId and ("id_" .. qId) or ("t_" .. string.lower(rawTitle))

                    if not data.seenKeys[dedupKey] then
                        data.seenKeys[dedupKey] = true
                        local extraText = ""
                        if scanPos == 1 and not string.find(string.sub(subLine, eOff + 1), "|Hquest:") then
                            local beforeTxt = TrimText(StripWowFormatting(string.sub(subLine, 1, sOff - 1)))
                            beforeTxt = TrimText(string.gsub(beforeTxt, "^[%d#%[%]%.%):%-]+%s*", ""))
                            local afterTxt = TrimText(StripWowFormatting(string.sub(subLine, eOff + 1)))
                            extraText = TrimText(beforeTxt .. " " .. afterTxt)
                        end
                        if extraText == "" and data.captureSection == "completed" then
                            extraText = "Completa (lista para entregar)"
                        end
                        local qLvlResolved = (qLevel and qLevel ~= "") and qLevel or "80"
                        local localizedTitle = (DungeonBots.GetLocalizedQuestTitle and qId)
                            and DungeonBots:GetLocalizedQuestTitle(qId, qLvlResolved, rawTitle)
                            or rawTitle
                        local rawDisplayLink = safeLink or ("|cffffff00" .. plainH .. "|r")
                        local localizedDisplayLink = DungeonBots.LocalizeHyperlinksInText
                            and DungeonBots:LocalizeHyperlinksInText(rawDisplayLink)
                            or rawDisplayLink

                        table.insert(data.quests, {
                            questId = qId,
                            questLevel = qLvlResolved,
                            rawTitle = rawTitle,
                            title = localizedTitle,
                            safeLink = safeLink,
                            rawDisplayLink = rawDisplayLink,
                            displayLink = localizedDisplayLink,
                            statusText = extraText,
                            canDrop = true,
                            rawLine = line,
                        })
                    end

                    scanPos = scanPos + eOff
                    if scanPos > #line then break end
                end

                if not foundLinkInLine and data.captureSection ~= "summary" then
                    local fallbackTitle = TrimText(string.gsub(cleanLine, "^[%d#]+[%.)%]:%-]+%s*", ""))
                    if fallbackTitle ~= "" and #fallbackTitle > 2 then
                        local dedupKey = "t_" .. string.lower(fallbackTitle)
                        if not data.seenKeys[dedupKey] then
                            data.seenKeys[dedupKey] = true
                            local statusBadge = (data.captureSection == "completed") and "Completa (lista para entregar)" or ""
                            table.insert(data.quests, {
                                questId = nil,
                                questLevel = nil,
                                rawTitle = fallbackTitle,
                                title = fallbackTitle,
                                safeLink = nil,
                                displayLink = nil,
                                statusText = statusBadge,
                                canDrop = true,
                                rawLine = line,
                            })
                        end
                    end
                end
            end
        end
    end

    if data.emptyHint or #(data.quests) > 0 then
        UpdateBotQuestCountCache(cleanSender, #(data.quests), now)
    end
    if not cap.silent or (DungeonBots.questFrame and DungeonBots.questFrame:IsShown() and DungeonBots.questFrame.currentBot == cleanSender) then
        if DungeonBots.UpdateQuestDialog then
            DungeonBots:UpdateQuestDialog(cleanSender)
        end
    end
    return true
end

local function AddTalkAction(data, key, actionObj)
    if not data or not key or data.seenActions[key] then return end
    data.seenActions[key] = true
    table.insert(data.actions, actionObj)
end

local function IsQuestLogDumpMessage(message)
    local lowerClean = string.lower(TrimText(StripWowFormatting(message or "")))
    if lowerClean == "" then return false end
    if string.find(lowerClean, "active quests", 1, true)
        or string.find(lowerClean, "incompleted quests", 1, true)
        or string.find(lowerClean, "incomplete quests", 1, true)
        or string.find(lowerClean, "completed quests", 1, true)
        or string.find(lowerClean, "no active quests", 1, true)
        or string.find(lowerClean, "summary", 1, true) then
        return true
    end
    return false
end

local function DetectTalkQuestState(lowerText)
    if not lowerText or lowerText == "" then return nil end
    if string.find(lowerText, "unavailable", 1, true) then
        return "unavailable"
    elseif string.find(lowerText, "incompleted", 1, true)
        or string.find(lowerText, "incomplete", 1, true)
        or string.find(lowerText, "in progress", 1, true)
        or string.find(lowerText, "already on quest", 1, true)
        or string.find(lowerText, "on quest", 1, true)
        or string.find(lowerText, "en progreso", 1, true)
        or string.find(lowerText, "en curso", 1, true)
        or string.find(lowerText, "ya tienes", 1, true) then
        return "incompleted"
    elseif string.find(lowerText, "quest completed", 1, true)
        or string.find(lowerText, "completed:", 1, true)
        or string.find(lowerText, "complete:", 1, true)
        or string.find(lowerText, "ready to turn in", 1, true)
        or string.find(lowerText, "reward", 1, true)
        or string.find(lowerText, "completada", 1, true)
        or string.find(lowerText, "lista para entregar", 1, true) then
        return "completed"
    elseif string.find(lowerText, "available", 1, true)
        or string.find(lowerText, "disponible", 1, true) then
        return "available"
    end
    return nil
end

local function ClassifyTalkQuestLine(lowerClean, isAcceptCmd)
    local isRangeError = (string.find(lowerClean, "out of range", 1, true)
        or string.find(lowerClean, "too far", 1, true)
        or string.find(lowerClean, "far away", 1, true)
        or string.find(lowerClean, "cannot reach", 1, true)
        or string.find(lowerClean, "not near", 1, true)
        or string.find(lowerClean, "demasiado lejos", 1, true)
        or string.find(lowerClean, "muy lejos", 1, true)) and true or false

    local isError = (isRangeError
        or string.find(lowerClean, "cannot", 1, true)
        or string.find(lowerClean, "couldn't", 1, true)
        or string.find(lowerClean, "could not", 1, true)
        or string.find(lowerClean, "unable", 1, true)
        or string.find(lowerClean, "not ready", 1, true)
        or string.find(lowerClean, "failed", 1, true)
        or string.find(lowerClean, "don't meet", 1, true)
        or string.find(lowerClean, "quest log is full", 1, true)
        or string.find(lowerClean, "no npc", 1, true)) and true or false

    if isAcceptCmd then
        return true, isError, nil, isRangeError
    end

    if isError
        or string.find(lowerClean, "turned in", 1, true)
        or string.find(lowerClean, "entregada", 1, true)
        or string.find(lowerClean, "accepted quest", 1, true)
        or string.find(lowerClean, "just accepted", 1, true) then
        return true, isError, nil, isRangeError
    end

    local state = DetectTalkQuestState(lowerClean)
    return false, false, state, isRangeError
end

function DB_Internal.ParseTalkCaptureWhisper(cleanSender, message)
    if DungeonBots.pendingQuestCapture and DungeonBots.pendingQuestCapture[cleanSender] then
        return false
    end

    local cap = DungeonBots.pendingTalkCapture[cleanSender]
    if not cap then
        if (DungeonBots.pendingPartyTalkUntil or 0) > NowTime()
            and DungeonBots:FindPartyUnitByName(cleanSender)
            and not (DB_Internal.IsPureTalentResponse and DB_Internal.IsPureTalentResponse(message))
            and not (DB_Internal.IsInventoryDumpMessage and DB_Internal.IsInventoryDumpMessage(message))
            and not IsQuestLogDumpMessage(message) then
            DungeonBots.pendingPartyTalkUntil = 0
            DungeonBots:ArmTalkCapture(cleanSender, DungeonBots.pendingPartyTalkCmd or "talk", true)
            local reclaimed = DungeonBots.talkDialogData[cleanSender]
            if reclaimed and DungeonBots.pendingPartyTalkNpc and not reclaimed.npcName then
                reclaimed.npcName = DungeonBots.pendingPartyTalkNpc
            end
            cap = DungeonBots.pendingTalkCapture[cleanSender]
        end
    end
    if not cap then return false end

    local now = NowTime()
    if now > (cap.expiresAt or 0) then
        DungeonBots.pendingTalkCapture[cleanSender] = nil
        return false
    end

    if (DB_Internal.IsPureTalentResponse and DB_Internal.IsPureTalentResponse(message))
        or (DB_Internal.IsInventoryDumpMessage and DB_Internal.IsInventoryDumpMessage(message))
        or IsQuestLogDumpMessage(message) then
        return false
    end

    local data = DungeonBots.talkDialogData[cleanSender]
    if not data then return false end

    cap.gotAnyLine = true
    if cap.isAcceptCmd then
        cap.finalizeAt = math.min((cap.startedAt or now) + 2.0, now + 0.22)
        cap.expiresAt = math.min((cap.startedAt or now) + 2.5, math.max(cap.expiresAt, now + 0.6))
    else
        cap.finalizeAt = math.min((cap.startedAt or now) + 4.0, now + 0.35)
        cap.expiresAt = math.min((cap.startedAt or now) + 4.5, math.max(cap.expiresAt, now + 1.0))
    end
    data.loading = false
    data.updatedAt = now

    local playerName = (UnitName and UnitName("player")) or ""

    for rawLine in string.gmatch(message or "", "[^\r\n]+") do
        local line = TrimText(rawLine)
        if line ~= "" then
            if playerName ~= "" then
                line = string.gsub(line, "%$[nN]", playerName)
            end

            local cleanLine = TrimText(StripWowFormatting(line))
            local lowerClean = string.lower(cleanLine)
            local headerNpc = string.match(cleanLine, "^%-%-+%s*(.-)%s*%-%-+$")
                or string.match(cleanLine, "^Talking to%s+([^:]+):?$")
            local isNpcHeaderLine = false
            if headerNpc and headerNpc ~= "" and not string.find(string.lower(headerNpc), "quest") then
                local targetNpc = (UnitExists and UnitExists("target") and not UnitIsPlayer("target")) and UnitName("target") or nil
                if targetNpc and targetNpc ~= "" then
                    data.npcName = targetNpc
                elseif not data.npcName or data.npcName == "" then
                    data.npcName = headerNpc
                end
                isNpcHeaderLine = true
            end

            local hasQuestLinkInLine = (string.find(line, "|Hquest:", 1, true) ~= nil)
            local probeLower = lowerClean
            if hasQuestLinkInLine then
                probeLower = string.lower(TrimText(StripWowFormatting(string.gsub(line, "|Hquest:[^|]+|h%[[^%]]+%]|h", " "))))
            end
            local skipQuestAction, isAcceptErr, lineQuestState, isRangeErr = ClassifyTalkQuestLine(probeLower, cap.isAcceptCmd)
            if isRangeErr then
                data.rangeError = true
            end
            if cap.isAcceptCmd then
                if isAcceptErr then
                    data.acceptError = true
                elseif string.find(lowerClean, "accepted", 1, true)
                    or string.find(lowerClean, "aceptada", 1, true)
                    or string.find(lowerClean, "completed", 1, true)
                    or string.find(lowerClean, "turned in", 1, true) then
                    if not data.playedAcceptSound then
                        data.playedAcceptSound = true
                        PlaySound("QUESTADDED")
                    end
                    local safeLink, _, _, rawLink = ExtractSafeQuestLinkFromText(line)
                    local rawDisplay = safeLink or (rawLink and ("|cffffff00" .. rawLink .. "|r")) or data.pendingAcceptTarget or cleanLine
                    local qDisplay = DungeonBots.LocalizeHyperlinksInText and DungeonBots:LocalizeHyperlinksInText(rawDisplay) or rawDisplay
                    local acceptKey = string.lower(tostring(rawLink or rawDisplay or ""))
                    data.printedAcceptKeys = data.printedAcceptKeys or {}
                    if not data.printedAcceptKeys[acceptKey] then
                        data.printedAcceptKeys[acceptKey] = true
                        data.printedAcceptMsg = true
                        if string.find(lowerClean, "completed", 1, true)
                            or string.find(lowerClean, "turned in", 1, true) then
                            DungeonBots:Print("|cffffd200" .. cleanSender .. "|r entregó la misión: " .. qDisplay)
                        else
                            DungeonBots:Print("|cffffd200" .. cleanSender .. "|r aceptó la misión: " .. qDisplay)
                        end
                    end
                end
            end

            -- Opciones numeradas de gossip ([0] ..., [1] ..., #1: ..., 1. ...)
            local hadHash = (string.match(line, "^%s*%[#") ~= nil) or (string.match(line, "^%s*#") ~= nil)
            local optNum, optBody = string.match(line, "^%s*%[#?(%d+)%]%s*[:%.%-]*%s*(.+)$")
            if not optNum then
                optNum, optBody = string.match(line, "^%s*#(%d+)%s*[:%.%-%)]*%s*(.+)$")
            end
            if not optNum then
                optNum, optBody = string.match(line, "^%s*(%d+)[%.%):]%s+(.+)$")
            end

            local parsedNum = optNum and tonumber(optNum) or nil
            local isOptionLine = false
            if parsedNum and parsedNum >= 0 and parsedNum <= 30 and optBody then
                local localizedOptBody = DungeonBots.LocalizeHyperlinksInText and DungeonBots:LocalizeHyperlinksInText(optBody) or optBody
                local cleanOpt = TrimText(StripWowFormatting(localizedOptBody))
                if cleanOpt ~= "" then
                    isOptionLine = true
                    if not hasQuestLinkInLine then
                        AddTalkAction(data, "gossip_" .. optNum, {
                            kind = "gossip",
                            cmd = hadHash and ("talk #" .. optNum) or ("talk " .. optNum),
                            label = cleanOpt,
                            rawBody = optBody,
                            rawText = line,
                        })
                    end
                end
            end

            if not isNpcHeaderLine then
                if isOptionLine then
                    if string.find(line, "|H") then
                        local localizedBody = DungeonBots.LocalizeHyperlinksInText and DungeonBots:LocalizeHyperlinksInText(optBody) or optBody
                        local cleanBody = TrimText(localizedBody)
                        if cleanBody ~= "" then
                            table.insert(data.lines, cleanBody)
                        end
                    end
                else
                    local localizedLine = DungeonBots.LocalizeHyperlinksInText and DungeonBots:LocalizeHyperlinksInText(line) or line
                    table.insert(data.lines, localizedLine)
                end
            end

            -- Enlaces de misión dentro del diálogo del PNJ
            if hasQuestLinkInLine and not skipQuestAction then
                local scanPos = 1
                while true do
                    local subLine = string.sub(line, scanPos)
                    local safeLink, sOff, eOff, plainH = ExtractSafeQuestLinkFromText(subLine)
                    if not plainH then break end

                    local qId, qLevel, rawTitle = string.match(plainH, "^|Hquest:(%d+):(-?%d*)|h%[([^%]]+)%]|h$")
                    rawTitle = rawTitle or StripWowFormatting(plainH)
                    local qLvlResolved = (qLevel and qLevel ~= "") and qLevel or "80"
                    local segBefore = string.lower(TrimText(StripWowFormatting(string.sub(subLine, 1, sOff - 1))))
                    local qState = DetectTalkQuestState(segBefore) or lineQuestState or "unknown"
                    local actionTarget = safeLink or rawTitle
                    local localizedTitle = (DungeonBots.GetLocalizedQuestTitle and qId)
                        and DungeonBots:GetLocalizedQuestTitle(qId, qLvlResolved, rawTitle)
                        or rawTitle
                    local rawDisplayLink = safeLink or ("|cffffff00" .. plainH .. "|r")
                    local localizedDisplayLink = DungeonBots.LocalizeHyperlinksInText
                        and DungeonBots:LocalizeHyperlinksInText(rawDisplayLink)
                        or rawDisplayLink

                    AddTalkAction(data, "quest_" .. (qId or string.lower(rawTitle)), {
                        kind = "quest",
                        questId = qId,
                        questLevel = qLvlResolved,
                        rawTitle = rawTitle,
                        title = localizedTitle,
                        safeLink = safeLink,
                        rawDisplayLink = rawDisplayLink,
                        displayLink = localizedDisplayLink,
                        acceptCmd = "accept " .. actionTarget,
                        talkCmd = "talk " .. actionTarget,
                        questState = qState,
                        label = localizedTitle,
                    })

                    scanPos = scanPos + eOff
                    if scanPos > #line then break end
                end
            end
        end
    end

    if DungeonBots.UpdateTalkDialog then
        DungeonBots:UpdateTalkDialog(cleanSender)
    end
    return true
end
