-- =========================================================================
-- DungeonBots_Roster.lua: Registro, Invocación e Historial de Bots
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

-- =========================================================================
-- Sistema de Detección e Identificación de Bots vs Jugadores
-- =========================================================================
function DungeonBots:RegisterBot(name, isBot)
    if not name or name == "" then return end
    if not DungeonBotsDB then DungeonBotsDB = {} end
    if not DungeonBotsDB.knownBots then DungeonBotsDB.knownBots = {} end
    if isBot == nil then
        DungeonBotsDB.knownBots[name] = nil
    else
        DungeonBotsDB.knownBots[name] = (isBot == true)
    end
end

function DungeonBots:IsBot(name)
    if not name or name == "" then return false end
    if not DungeonBotsDB or not DungeonBotsDB.knownBots then return nil end
    return DungeonBotsDB.knownBots[name]
end

local function PrunePendingClassSummons()
    local now = NowTime()
    local list = DungeonBots.pendingClassSummons
    for i = #list, 1, -1 do
        if not list[i] or (list[i].expiresAt or 0) <= now then
            table.remove(list, i)
        end
    end
end

function DungeonBots:CanInviteToParty()
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        return false
    end
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if numParty >= 4 then
        return false
    end
    return (numParty == 0 or (IsPartyLeader and IsPartyLeader()))
end

function DungeonBots:MarkRecentBot(name, durationSeconds)
    if not name or name == "" or name == UnitName("player") then return end
    DungeonBots.recentBots[name] = NowTime() + (durationSeconds or 120)
end

function DungeonBots:IsRecentBot(name)
    if not name or name == "" then return false end
    local expiresAt = DungeonBots.recentBots and DungeonBots.recentBots[name]
    if not expiresAt then return false end
    if expiresAt <= NowTime() then
        DungeonBots.recentBots[name] = nil
        return false
    end
    return true
end

function DungeonBots:ClearRecentBot(name)
    local cleanName = NormalizePlayerName(name)
    if not cleanName or cleanName == "" or not DungeonBots.recentBots then return end
    DungeonBots.recentBots[cleanName] = nil
end

function DungeonBots:IsInHistory(name)
    if not name or name == "" then return false end
    return (DungeonBotsDB and DungeonBotsDB.botHistory and DungeonBotsDB.botHistory[name] ~= nil) and true or false
end

function DungeonBots:MarkPendingClassSummon(classId)
    PrunePendingClassSummons()
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if (GetNumRaidMembers and GetNumRaidMembers() > 0) or numParty >= 4 then
        return false
    end
    if (numParty + #DungeonBots.pendingClassSummons) >= 4 then
        return false
    end
    table.insert(DungeonBots.pendingClassSummons, {
        classId = classId,
        classToken = DB_Internal.CLASS_TOKEN_BY_ID and DB_Internal.CLASS_TOKEN_BY_ID[classId] or nil,
        expiresAt = NowTime() + 45,
    })
    return true
end

function DungeonBots:GetPendingClassSummonCount()
    PrunePendingClassSummons()
    return #DungeonBots.pendingClassSummons
end

function DungeonBots:HasPendingClassSummon()
    PrunePendingClassSummons()
    return (#DungeonBots.pendingClassSummons > 0)
end

function DungeonBots:ConsumePendingClassSummon(expectedClassToken)
    PrunePendingClassSummons()
    local list = DungeonBots.pendingClassSummons
    if #list == 0 then return nil end

    if expectedClassToken and expectedClassToken ~= "" then
        for i, item in ipairs(list) do
            if not item.classToken or item.classToken == expectedClassToken then
                table.remove(list, i)
                return item
            end
        end
        return nil
    end

    return table.remove(list, 1)
end

function DungeonBots:HasPendingScan(name)
    if not name or name == "" then return false end
    local val = DungeonBots.pendingScan and DungeonBots.pendingScan[name]
    if not val then return false end
    if type(val) == "number" and val <= NowTime() then
        DungeonBots.pendingScan[name] = nil
        return false
    end
    return true
end

function DungeonBots:ShouldTreatAsBot(name)
    if not name or name == "" then return false end
    if UnitName and name == UnitName("player") then return false end
    local reg = DungeonBots:IsBot(name)
    if reg == false then return false end
    if DungeonBots.confirmedBots and DungeonBots.confirmedBots[name] then return true end
    if DungeonBots:IsRecentBot(name) then return true end
    if DungeonBots:IsInHistory(name) then return true end
    return false
end

function DungeonBots:ResolvePendingPartyBots()
    if not DungeonBots:HasPendingClassSummon() then return end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitIsConnected(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and name ~= UNKNOWNOBJECT and name ~= "Unknown" then
                if DungeonBots:IsBot(name) == nil and not DungeonBots:ShouldTreatAsBot(name) then
                    local _, classToken = UnitClass(unit)
                    if DungeonBots:ConsumePendingClassSummon(classToken) then
                        DungeonBots:MarkRecentBot(name, 120)
                        DungeonBots:RegisterBot(name, true)
                        DungeonBots:RecordBotHistory(name, classToken, nil, DungeonBots:GetRaceIcon(unit))
                    end
                end
            end
        end
    end
end

function DungeonBots:FindPartyUnitByName(name, includeDisconnected)
    if not name or name == "" then return nil end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitName(unit) == name then
            if includeDisconnected or UnitIsConnected(unit) then
                return unit
            end
        end
    end
    return nil
end

function DungeonBots:GetBotProximityInfo(botName)
    local cleanName = (DB_Internal.NormalizePlayerName and DB_Internal.NormalizePlayerName(botName)) or tostring(botName or "Bot")
    if cleanName == "" then cleanName = "Bot" end
    local unit = self:FindPartyUnitByName(cleanName)
    if not unit then
        return {
            key = "missing",
            isNear = false,
            isFar = true,
            canTalkRange = false,
            canInspectRange = false,
            shortLabel = "Fuera del grupo",
            badgeText = "|cff9d9d9d[No está en grupo]|r",
            colorHex = "|cff9d9d9d",
            detailMsg = cleanName .. " no está en tu grupo actual.",
        }
    end
    if UnitIsConnected and not UnitIsConnected(unit) then
        return {
            key = "offline",
            isNear = false,
            isFar = true,
            canTalkRange = false,
            canInspectRange = false,
            shortLabel = "Desconectado",
            badgeText = "|cff9d9d9d[Desconectado]|r",
            colorHex = "|cff9d9d9d",
            detailMsg = cleanName .. " está desconectado.",
        }
    end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then
        return {
            key = "dead",
            isNear = false,
            isFar = true,
            canTalkRange = false,
            canInspectRange = false,
            shortLabel = "Muerto",
            badgeText = "|cffff5544[Muerto]|r",
            colorHex = "|cffff5544",
            detailMsg = cleanName .. " está muerto o en espíritu.",
        }
    end
    if UnitIsVisible and not UnitIsVisible(unit) then
        return {
            key = "out_of_sight",
            isNear = false,
            isFar = true,
            canTalkRange = false,
            canInspectRange = false,
            shortLabel = "Muy lejos / otra zona",
            badgeText = "|cffff5544[Muy lejos]|r",
            colorHex = "|cffff5544",
            detailMsg = cleanName .. " está muy lejos (más de 100 m) o en otra zona.",
        }
    end

    local inCloseTalk = (CheckInteractDistance and CheckInteractDistance(unit, 2)) and true or false
    local inInspectRange = false
    if CheckInteractDistance then
        inInspectRange = CheckInteractDistance(unit, 1) and true or false
    elseif CanInspect then
        inInspectRange = CanInspect(unit) and true or false
    end
    local inPartyRange = (UnitInRange and UnitInRange(unit)) and true or false

    if CheckInteractDistance then
        if inCloseTalk then
            return {
                key = "close",
                isNear = true,
                isFar = false,
                canTalkRange = true,
                canInspectRange = true,
                shortLabel = "Cerca",
                badgeText = "|cff34c759[Cerca]|r",
                colorHex = "|cff34c759",
                detailMsg = nil,
            }
        elseif inInspectRange then
            return {
                key = "medium",
                isNear = true,
                isFar = false,
                canTalkRange = true,
                canInspectRange = true,
                shortLabel = "< 28 m",
                badgeText = "|cffffd200[< 28 m]|r",
                colorHex = "|cffffd200",
                detailMsg = cleanName .. " está a media distancia (12-28 m). Si no responde al PNJ, acércalo un poco más.",
            }
        elseif inPartyRange then
            return {
                key = "far_40",
                isNear = false,
                isFar = true,
                canTalkRange = false,
                canInspectRange = false,
                shortLabel = "Lejos (> 28 m)",
                badgeText = "|cffff7b30[Lejos (> 28 m)]|r",
                colorHex = "|cffff7b30",
                detailMsg = cleanName .. " está lejos (a más de 28 m de ti).",
            }
        else
            return {
                key = "far",
                isNear = false,
                isFar = true,
                canTalkRange = false,
                canInspectRange = false,
                shortLabel = "Muy lejos (> 40 m)",
                badgeText = "|cffff5544[Muy lejos (> 40 m)]|r",
                colorHex = "|cffff5544",
                detailMsg = cleanName .. " está muy lejos (a más de 40 m de ti).",
            }
        end
    end

    if CanInspect and CanInspect(unit) then
        return {
            key = "close",
            isNear = true,
            isFar = false,
            canTalkRange = true,
            canInspectRange = true,
            shortLabel = "Cerca",
            badgeText = "|cff34c759[Cerca]|r",
            colorHex = "|cff34c759",
            detailMsg = nil,
        }
    end
    return {
        key = inPartyRange and "far_40" or "far",
        isNear = false,
        isFar = true,
        canTalkRange = false,
        canInspectRange = false,
        shortLabel = inPartyRange and "Lejos (> 28 m)" or "Muy lejos (> 40 m)",
        badgeText = inPartyRange and "|cffff7b30[Lejos (> 28 m)]|r" or "|cffff5544[Muy lejos (> 40 m)]|r",
        colorHex = inPartyRange and "|cffff7b30" or "|cffff5544",
        detailMsg = cleanName .. (inPartyRange and " está lejos (a más de 28 m de ti)." or " está muy lejos (a más de 40 m de ti)."),
    }
end

function DungeonBots:ToggleUnitBotStatus(name)
    if not name or name == "" then return end
    local current = DungeonBots:ShouldTreatAsBot(name)
    local newState = not current
    DungeonBots:RegisterBot(name, newState)
    DungeonBots.pendingSpecReset[name] = nil
    if newState then
        DungeonBots.sessionQueriedBots[name] = nil
        DungeonBots.confirmedBots[name] = true
        DungeonBots:MarkRecentBot(name, 120)
        DungeonBots:Print("|cffffd200" .. name .. "|r marcado como: |cff00e5ff[ BOT ]|r.")
        if DungeonBots.RecordBotHistory then
            DungeonBots:RecordBotHistory(name)
        end
        if DungeonBots:FindPartyUnitByName(name) then
            DungeonBots.sessionQueriedBots[name] = true
            DungeonBots:QueryBotLiveInfo(name)
        end
    else
        DungeonBots.confirmedBots[name] = nil
        DungeonBots.recentBots[name] = nil
        DungeonBots.sessionQueriedBots[name] = nil
        DungeonBots:Print("|cffffd200" .. name .. "|r marcado como: |cffffb020[ JUGADOR HUMANO ]|r.")
        if DungeonBotsDB and DungeonBotsDB.botHistory then
            DungeonBotsDB.botHistory[name] = nil
        end
    end
    if DungeonBots.UpdateHistorySummary then
        DungeonBots:UpdateHistorySummary()
    end
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
end

-- Escaneo de miembros mediante consulta discreta por susurro
function DungeonBots:ScanPartyBots()
    local count = GetNumPartyMembers()
    if count == 0 then
        DungeonBots:Warn("No hay miembros en tu grupo para comprobar.")
        return
    end

    local checkedNames = {}
    local now = NowTime()
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitIsConnected(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and DungeonBots:IsBot(name) ~= false and not DungeonBots.confirmedBots[name] then
                DungeonBots.pendingScan[name] = now + 15
                DungeonBots:SendWhisperCommand(name, "follow info")
                table.insert(checkedNames, name)
            end
        end
    end

    if #checkedNames == 0 then
        DungeonBots:Print("Todos los bots actuales del grupo ya respondieron y están confirmados.")
    else
        local muteMode = (DungeonBotsDB and DungeonBotsDB.whisperMuteMode) or "auto"
        if muteMode ~= "off" then
            DungeonBots:Print("Comprobación silenciosa de bots en: |cffffd200" .. table.concat(checkedNames, ", ") .. "|r...")
        else
            DungeonBots:Print("Comprobando quién es bot en: |cffffd200" .. table.concat(checkedNames, ", ") .. "|r (los bots responderán automáticamente en el chat).")
        end
    end
end

-- =========================================================================
-- Funciones Operativas de Invocación y Despido de Bots
-- =========================================================================

-- Invocar bot por clase
function DungeonBots:AddClass(classId)
    if not classId then return end
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if (GetNumRaidMembers and GetNumRaidMembers() > 0) or numParty >= 4 then
        DungeonBots:Warn("Tu grupo ya está completo (5/5); no se auto-invitará al bot.")
    else
        DungeonBots:MarkPendingClassSummon(classId)
    end
    local classToken = DB_Internal.CLASS_TOKEN_BY_ID and DB_Internal.CLASS_TOKEN_BY_ID[classId]
    local classDisplay = classToken and DungeonBots:GetClassDisplayInfo(classToken) or classId
    DungeonBots:Print("Invocando bot de clase: |cffffd200" .. classDisplay .. "|r...")
    DungeonBots:SendDotCommand(".playerbots bot addclass " .. classId)
end

-- Invocar bot por nombre
function DungeonBots:AddBot(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return end
    DungeonBots.lastBotCallAttempt = DungeonBots.lastBotCallAttempt or {}
    DungeonBots.lastBotCallAttempt[cleanName] = NowTime()
    if DungeonBots.busyExternalBots and DungeonBots.busyExternalBots[cleanName] then
        -- Reiniciar ventana activa para permitir reintentar si el otro jugador lo solto, conservando dueno previo
        DungeonBots.busyExternalBots[cleanName].expiresAt = 0
    end
    DungeonBots:MarkRecentBot(cleanName, 120)
    DungeonBots:RegisterBot(cleanName, true)
    DungeonBots:RecordBotHistory(cleanName)
    DungeonBots:Print("Llamando a bot: |cffffd200" .. cleanName .. "|r...")
    DungeonBots:SendDotCommand(".playerbots bot add " .. cleanName)
end

-- Reinvocar a todos los bots del grupo (clave para entrar a mazmorra)
function DungeonBots:AddAllBots()
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitIsConnected(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and DungeonBots:ShouldTreatAsBot(name) then
                DungeonBots:MarkRecentBot(name, 60)
            end
        end
    end
    DungeonBots:Print("Reinvocando a todos los bots del grupo...")
    DungeonBots:SendDotCommand(".playerbots bot add *")
    -- Pequeño delay sugerido para que carguen antes del summon
    DungeonBots:SendPartyCommand("summon")
end

-- Remover un bot específico y sacarlo del grupo
function DungeonBots:RemoveBot(botName)
    if not botName or botName == "" then return end
    DungeonBots:Print("Despidiendo a bot: |cffffd200" .. botName .. "|r...")
    DungeonBots:SendDotCommand(".playerbots bot remove " .. botName)
    if GetNumPartyMembers() > 0 and IsPartyLeader() and DungeonBots:FindPartyUnitByName(botName) then
        UninviteUnit(botName)
    end
end

-- Remover a todos los bots y sacarlos del grupo (preservando humanos)
function DungeonBots:RemoveAllBots()
    DungeonBots:Print("Despidiendo a todos los bots del grupo...")
    DungeonBots:SendDotCommand(".playerbots bot remove *")

    if GetNumPartyMembers() > 0 then
        local botsToKick = {}
        local hasHuman = false
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                local name = UnitName(unit)
                if name and name ~= "" then
                    if not DungeonBots:ShouldTreatAsBot(name) then
                        hasHuman = true
                    else
                        table.insert(botsToKick, name)
                    end
                end
            end
        end

        if not hasHuman then
            LeaveParty()
        elseif IsPartyLeader() then
            for _, botName in ipairs(botsToKick) do
                UninviteUnit(botName)
            end
        end
    end
end

-- =========================================================================
-- Historial Persistente de Bots e Invitación Individual
-- =========================================================================
StaticPopupDialogs["DUNGEONBOTS_BOT_BUSY_ALERT"] = {
    text = "%s",
    button1 = "Entendido",
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

local pendingHistoryInvites = {}
local historyInviteFrame = CreateFrame("Frame", "DungeonBots_HistoryInviteFrame")
historyInviteFrame:Hide()
historyInviteFrame:SetScript("OnUpdate", function(self, elapsed)
    local hasPending = false
    for botName, remaining in pairs(pendingHistoryInvites) do
        local nextTime = remaining - elapsed
        if nextTime <= 0 then
            pendingHistoryInvites[botName] = nil
            if not DungeonBots:FindPartyUnitByName(botName)
                and not DungeonBots:GetExternalBotBusyInfo(botName)
                and DungeonBots:CanInviteToParty() then
                DungeonBots.recentInvites[botName] = NowTime() + 3
                InviteUnit(botName)
            end
        else
            pendingHistoryInvites[botName] = nextTime
            hasPending = true
        end
    end
    if not hasPending then
        self:Hide()
    end
end)

function DungeonBots:CancelPendingHistoryInvite(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return end
    if pendingHistoryInvites[cleanName] then
        pendingHistoryInvites[cleanName] = nil
        if not next(pendingHistoryInvites) then
            historyInviteFrame:Hide()
        end
    end
end

function DungeonBots:HasPendingHistoryInvite(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return false end
    return pendingHistoryInvites[cleanName] ~= nil
end

function DungeonBots:GetExternalBotBusyInfo(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return nil end
    if DungeonBots:FindPartyUnitByName(cleanName) then
        if DungeonBots.busyExternalBots then
            DungeonBots.busyExternalBots[cleanName] = nil
        end
        return nil
    end
    local info = DungeonBots.busyExternalBots and DungeonBots.busyExternalBots[cleanName]
    if not info then return nil end
    if (info.expiresAt or 0) <= NowTime() then
        return nil
    end
    return info
end

local function ClearBotPendingEntryAndClose(captureMap, refreshMap, frameObj, cleanName)
    local hadPending = false
    if captureMap and captureMap[cleanName] then
        captureMap[cleanName] = nil
        hadPending = true
    end
    if refreshMap and refreshMap[cleanName] then
        refreshMap[cleanName] = nil
    end
    if hadPending and frameObj and frameObj.IsShown and frameObj:IsShown() and frameObj.currentBot == cleanName then
        if not DungeonBots:FindPartyUnitByName(cleanName) then
            frameObj:Hide()
        end
    end
end

function DungeonBots:ClearPendingBotInteractions(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return end
    DungeonBots:CancelPendingHistoryInvite(cleanName)
    DungeonBots:ClearRecentBot(cleanName)
    if DungeonBots.recentInvites then DungeonBots.recentInvites[cleanName] = nil end
    if DungeonBots.pendingScan then DungeonBots.pendingScan[cleanName] = nil end
    if DungeonBots.pendingSpecReset then DungeonBots.pendingSpecReset[cleanName] = nil end
    if DungeonBots.pendingListReset then DungeonBots.pendingListReset[cleanName] = nil end

    ClearBotPendingEntryAndClose(DungeonBots.pendingQuestCapture, DungeonBots.pendingQuestRefresh, DungeonBots.questFrame, cleanName)
    if DungeonBots.pendingQuestCountCapture then
        DungeonBots.pendingQuestCountCapture[cleanName] = nil
    end
    ClearBotPendingEntryAndClose(DungeonBots.pendingTalkCapture, DungeonBots.pendingTalkRefresh, DungeonBots.talkFrame, cleanName)
    ClearBotPendingEntryAndClose(DungeonBots.pendingInventoryCapture, DungeonBots.pendingInventoryRefresh, DungeonBots.inventoryFrame, cleanName)
    ClearBotPendingEntryAndClose(DungeonBots.pendingSpellsCapture, nil, DungeonBots.spellsFrame, cleanName)
    if DungeonBots.pendingSpellDetailCapture then
        DungeonBots.pendingSpellDetailCapture[cleanName] = nil
    end
end

function DungeonBots:NotifyExternalBotBusy(botName, ownerName, sourceTag, forceAlert)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return false end
    if DungeonBots:FindPartyUnitByName(cleanName) then
        if DungeonBots.busyExternalBots then
            DungeonBots.busyExternalBots[cleanName] = nil
        end
        return false
    end

    local now = NowTime()
    DungeonBots.busyExternalBots = DungeonBots.busyExternalBots or {}
    local prev = DungeonBots.busyExternalBots[cleanName]
    local resolvedOwner = NormalizePlayerName(ownerName)
    if (not resolvedOwner or resolvedOwner == "") and prev and prev.owner and prev.owner ~= "" then
        resolvedOwner = prev.owner
    end

    DungeonBots.busyExternalBots[cleanName] = {
        owner = resolvedOwner,
        expiresAt = now + 45,
        source = sourceTag or "system",
    }

    DungeonBots:ClearPendingBotInteractions(cleanName)

    DungeonBots.busyBotLastAlert = DungeonBots.busyBotLastAlert or {}
    local last = DungeonBots.busyBotLastAlert[cleanName]
    local gainedOwner = (resolvedOwner ~= nil and resolvedOwner ~= "") and (not last or not last.owner or last.owner ~= resolvedOwner)
    local callTs = DungeonBots.lastBotCallAttempt and DungeonBots.lastBotCallAttempt[cleanName] or 0
    local newCallSinceLastAlert = (callTs > (last and last.at or 0))
    local expiredDebounce = (not last) or ((now - (last.at or 0)) >= 4.0)

    if not forceAlert and not gainedOwner and not newCallSinceLastAlert and not expiredDebounce then
        return true
    end

    DungeonBots.busyBotLastAlert[cleanName] = {
        at = now,
        owner = resolvedOwner,
    }

    local chatMsg
    local plainMsg
    if resolvedOwner and resolvedOwner ~= "" then
        chatMsg = "¡ALERTA! El bot |cffffd200" .. cleanName .. "|r ya está en uso por otro jugador (en grupo con |cffffd200" .. resolvedOwner .. "|r). No puedes invocarlo ahora."
        plainMsg = "¡ALERTA! El bot " .. cleanName .. " ya pertenece a otro jugador (en grupo con " .. resolvedOwner .. ")."
    else
        chatMsg = "¡ALERTA! El bot |cffffd200" .. cleanName .. "|r ya está conectado y ocupado por otro jugador. No puedes invocarlo ahora."
        plainMsg = "¡ALERTA! El bot " .. cleanName .. " ya está ocupado por otro jugador."
    end

    DungeonBots:Warn(chatMsg)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(plainMsg, 1.0, 0.22, 0.22, 1.0)
    end
    if PlaySound then
        PlaySound("igQuestFailed")
    end
    if StaticPopup_Show then
        if StaticPopup_Hide then
            StaticPopup_Hide("DUNGEONBOTS_BOT_BUSY_ALERT")
        end
        StaticPopup_Show("DUNGEONBOTS_BOT_BUSY_ALERT", chatMsg)
    end
    return true
end

function DungeonBots:RecordBotHistory(name, classToken, specName, raceIcon)
    if not name or name == "" then return end
    if DungeonBots:IsBot(name) == false then return end
    if not DungeonBotsDB then DungeonBotsDB = {} end
    DungeonBotsDB.botHistory = DungeonBotsDB.botHistory or {}

    local unit = DungeonBots:FindPartyUnitByName(name)
    if unit then
        if not classToken or classToken == "" then
            local _, detectedClass = UnitClass(unit)
            classToken = detectedClass
        end
        if not raceIcon or raceIcon == "" then
            raceIcon = DungeonBots:GetRaceIcon(unit)
        end
    end

    local prev = DungeonBotsDB.botHistory[name] or {}
    local resolvedSpec = specName
    if not resolvedSpec or resolvedSpec == "" then
        resolvedSpec = (DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[name]) or prev.spec or ""
    end
    if DungeonBots.CleanSpecText then
        resolvedSpec = DungeonBots:CleanSpecText(resolvedSpec)
    end

    local defaultQuestionIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
    local resolvedIcon = prev.raceIcon or defaultQuestionIcon
    if raceIcon and raceIcon ~= "" and raceIcon ~= defaultQuestionIcon then
        resolvedIcon = raceIcon
    end

    DungeonBotsDB.botHistory[name] = {
        name = name,
        class = (classToken and classToken ~= "" and classToken) or prev.class or "UNKNOWN",
        spec = resolvedSpec,
        raceIcon = resolvedIcon,
        lastSeen = (date and date("%d/%m %H:%M")) or (prev.lastSeen or ""),
        timestamp = (time and time()) or (prev.timestamp or 0),
    }
end

function DungeonBots:SyncPartyToHistory()
    if not DungeonBotsDB then DungeonBotsDB = {} end
    DungeonBotsDB.botHistory = DungeonBotsDB.botHistory or {}

    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitIsConnected(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and DungeonBots:ShouldTreatAsBot(name) then
                local _, classToken = UnitClass(unit)
                local raceIcon = DungeonBots:GetRaceIcon(unit)
                DungeonBots:RecordBotHistory(name, classToken, nil, raceIcon)
            end
        end
    end

    if DungeonBots.UpdateHistorySummary then
        DungeonBots:UpdateHistorySummary()
    end
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
end

function DungeonBots:GetBotHistoryCount()
    if not DungeonBotsDB or not DungeonBotsDB.botHistory then return 0 end
    local count = 0
    for _ in pairs(DungeonBotsDB.botHistory) do
        count = count + 1
    end
    return count
end

function DungeonBots:GetSortedBotHistory()
    local list = {}
    if not DungeonBotsDB or not DungeonBotsDB.botHistory then return list end
    for _, entry in pairs(DungeonBotsDB.botHistory) do
        if entry and entry.name then
            table.insert(list, entry)
        end
    end
    table.sort(list, function(a, b)
        local ta = a.timestamp or 0
        local tb = b.timestamp or 0
        if ta ~= tb then
            return ta > tb
        end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

function DungeonBots:RemoveFromHistory(botName)
    if not botName or not DungeonBotsDB or not DungeonBotsDB.botHistory then return end
    DungeonBotsDB.botHistory[botName] = nil
    if DungeonBotsDB.knownBots and DungeonBotsDB.knownBots[botName] == true then
        DungeonBotsDB.knownBots[botName] = nil
    end
    if DungeonBotsDB.botActiveSpec then
        DungeonBotsDB.botActiveSpec[botName] = nil
    end
    if DungeonBotsDB.botSpecs then
        DungeonBotsDB.botSpecs[botName] = nil
    end
    if DungeonBots.botSpecs then
        DungeonBots.botSpecs[botName] = nil
    end
    DungeonBots.confirmedBots[botName] = nil
    DungeonBots.recentBots[botName] = nil
    if DungeonBots.UpdateHistorySummary then
        DungeonBots:UpdateHistorySummary()
    end
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
end

function DungeonBots:ClearBotHistory()
    if not DungeonBotsDB then DungeonBotsDB = {} end
    DungeonBotsDB.botHistory = {}
    DungeonBotsDB.botActiveSpec = {}
    DungeonBotsDB.botSpecs = {}
    DungeonBotsDB.historyMigrated = true
    DungeonBots.botSpecs = DungeonBotsDB.botSpecs
    if DungeonBotsDB.knownBots then
        for name, isBot in pairs(DungeonBotsDB.knownBots) do
            if isBot == true then
                DungeonBotsDB.knownBots[name] = nil
            end
        end
    end
    DungeonBots.confirmedBots = {}
    DungeonBots.recentBots = {}
    if DungeonBots.UpdateHistorySummary then
        DungeonBots:UpdateHistorySummary()
    end
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
    DungeonBots:Print("Historial de bots limpiado.")
end

function DungeonBots:SummonAndInviteHistoryBot(botName)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or cleanBot == "" then return end
    if DungeonBots:FindPartyUnitByName(cleanBot) then
        DungeonBots:Print("|cffffd200" .. cleanBot .. "|r ya forma parte de tu grupo actual.")
        return
    end
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if (GetNumRaidMembers and GetNumRaidMembers() > 0) or numParty >= 4 then
        DungeonBots:Warn("Tu grupo ya está lleno (5/5). No se puede invitar a |cffffd200" .. cleanBot .. "|r.")
        return
    end
    if numParty > 0 and IsPartyLeader and not IsPartyLeader() then
        DungeonBots:Warn("Debes ser el líder del grupo para invitar a |cffffd200" .. cleanBot .. "|r.")
        return
    end
    DungeonBots:AddBot(cleanBot)
    pendingHistoryInvites[cleanBot] = 1.0
    historyInviteFrame:Show()
end
