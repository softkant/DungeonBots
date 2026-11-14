-- =========================================================================
-- DungeonBots_Roster.lua: Registro, Invocación e Historial de Bots
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

local function IsLfgQueueBlockingInvite()
    local lfgMode = GetLFGMode and GetLFGMode() or nil
    if lfgMode == "queued" or lfgMode == "proposal" or lfgMode == "rolecheck" then
        return lfgMode
    end
    return nil
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
    if reg == true then return true end
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
            shortLabel = L["PROX_MISSING_SHORT"],
            badgeText = L["PROX_MISSING_BADGE"],
            colorHex = "|cff9d9d9d",
            detailMsg = string.format(L["PROX_MISSING_DETAIL"], cleanName),
        }
    end
    if UnitIsConnected and not UnitIsConnected(unit) then
        return {
            key = "offline",
            isNear = false,
            isFar = true,
            canTalkRange = false,
            canInspectRange = false,
            shortLabel = L["PROX_OFFLINE_SHORT"],
            badgeText = L["PROX_OFFLINE_BADGE"],
            colorHex = "|cff9d9d9d",
            detailMsg = string.format(L["PROX_OFFLINE_DETAIL"], cleanName),
        }
    end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then
        return {
            key = "dead",
            isNear = false,
            isFar = true,
            canTalkRange = false,
            canInspectRange = false,
            shortLabel = L["PROX_DEAD_SHORT"],
            badgeText = L["PROX_DEAD_BADGE"],
            colorHex = "|cffff5544",
            detailMsg = string.format(L["PROX_DEAD_DETAIL"], cleanName),
        }
    end
    if UnitIsVisible and not UnitIsVisible(unit) then
        return {
            key = "out_of_sight",
            isNear = false,
            isFar = true,
            canTalkRange = false,
            canInspectRange = false,
            shortLabel = L["PROX_OOS_SHORT"],
            badgeText = L["PROX_OOS_BADGE"],
            colorHex = "|cffff5544",
            detailMsg = string.format(L["PROX_OOS_DETAIL"], cleanName),
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
                shortLabel = L["PROX_CLOSE_SHORT"],
                badgeText = L["PROX_CLOSE_BADGE"],
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
                shortLabel = L["PROX_MID_SHORT"],
                badgeText = L["PROX_MID_BADGE"],
                colorHex = "|cffffd200",
                detailMsg = string.format(L["PROX_MID_DETAIL"], cleanName),
            }
        elseif inPartyRange then
            return {
                key = "far_40",
                isNear = false,
                isFar = true,
                canTalkRange = false,
                canInspectRange = false,
                shortLabel = L["PROX_FAR28_SHORT"],
                badgeText = L["PROX_FAR28_BADGE"],
                colorHex = "|cffff7b30",
                detailMsg = string.format(L["PROX_FAR28_DETAIL"], cleanName),
            }
        else
            return {
                key = "far",
                isNear = false,
                isFar = true,
                canTalkRange = false,
                canInspectRange = false,
                shortLabel = L["PROX_FAR40_SHORT"],
                badgeText = L["PROX_FAR40_BADGE"],
                colorHex = "|cffff5544",
                detailMsg = string.format(L["PROX_FAR40_DETAIL"], cleanName),
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
            shortLabel = L["PROX_CLOSE_SHORT"],
            badgeText = L["PROX_CLOSE_BADGE"],
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
        shortLabel = inPartyRange and L["PROX_FAR28_SHORT"] or L["PROX_FAR40_SHORT"],
        badgeText = inPartyRange and L["PROX_FAR28_BADGE"] or L["PROX_FAR40_BADGE"],
        colorHex = inPartyRange and "|cffff7b30" or "|cffff5544",
        detailMsg = string.format(inPartyRange and L["PROX_FAR28_DETAIL"] or L["PROX_FAR40_DETAIL"], cleanName),
    }
end

-- Anexa al mensaje de sin respuesta un diagnóstico de cercanía/estancia
function DungeonBots:FormatNoResponseBody(headlineText, botName)
    local head = tostring(headlineText or "")
    local cleanName = (DB_Internal.NormalizePlayerName and DB_Internal.NormalizePlayerName(botName)) or tostring(botName or "Bot")
    if cleanName == "" then cleanName = "Bot" end
    local prox = self.GetBotProximityInfo and self:GetBotProximityInfo(cleanName) or nil
    if prox then
        if prox.key == "missing" or prox.key == "offline" then
            return head .. "\n\n|cffff7b30" .. (prox.detailMsg or "") .. "|r"
        elseif prox.key == "dead" then
            return head .. "\n\n|cffff7b30" .. (prox.detailMsg or "") .. "|r\n|cff888888" .. (L["NORESP_DEAD_HINT"] or "") .. "|r"
        elseif prox.key == "out_of_sight" then
            local detail = string.format(L["NORESP_OOS_DETAIL"] or "%s", cleanName)
            return head .. "\n\n|cffff7b30" .. detail .. "|r\n|cff888888" .. (L["NORESP_OOS_HINT"] or "") .. "|r"
        elseif prox.isFar then
            return head .. "\n\n|cffff7b30" .. (prox.detailMsg or "") .. "|r\n|cff888888" .. (L["NORESP_FAR_HINT"] or "") .. "|r"
        end
    end
    return head .. "\n\n|cff888888" .. (L["NORESP_NEAR_HINT"] or "") .. "|r"
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
        DungeonBots:Print(string.format(L["MARKED_BOT"], name))
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
        DungeonBots:Print(string.format(L["MARKED_HUMAN"], name))
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
        DungeonBots:Warn(L["NO_MEMBERS_CHECK"])
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
        DungeonBots:Print(L["ALL_BOTS_CONFIRMED"])
    else
        local muteMode = (DungeonBotsDB and DungeonBotsDB.whisperMuteMode) or "auto"
        if muteMode ~= "off" then
            DungeonBots:Print(string.format(L["SCAN_SILENT_FMT"], table.concat(checkedNames, ", ")))
        else
            DungeonBots:Print(string.format(L["SCAN_VISIBLE_FMT"], table.concat(checkedNames, ", ")))
        end
    end
end

-- =========================================================================
-- Funciones Operativas de Invocación y Despido de Bots
-- =========================================================================

local function CheckCanSummonBot(allowWhenLfgQueued)
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if (GetNumRaidMembers and GetNumRaidMembers() > 0) or numParty >= 4 then
        DungeonBots:Warn(L["GROUP_FULL_CANT_ADD"])
        return false
    end
    if not allowWhenLfgQueued and IsLfgQueueBlockingInvite() then
        DungeonBots:Warn(L["LFG_QUEUED_CANT_ADD"])
        return false
    end
    return true
end

-- Invocar bot por clase
function DungeonBots:AddClass(classId)
    if not classId then return false end
    if not CheckCanSummonBot(false) then return false end
    DungeonBots:MarkPendingClassSummon(classId)
    local classToken = DB_Internal.CLASS_TOKEN_BY_ID and DB_Internal.CLASS_TOKEN_BY_ID[classId]
    local classDisplay = classToken and DungeonBots:GetClassDisplayInfo(classToken) or classId
    DungeonBots:Print(string.format(L["BOT_ADDED_FMT"], classDisplay))
    DungeonBots:SendDotCommand(".playerbots bot addclass " .. classId)
    return true
end

-- Invocar bot por nombre
local pendingHistoryLoading = {}
local pendingSummonConfirm = {}

local function RefreshHistoryUIIfVisible()
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
end

function DungeonBots:SetHistoryBotLoading(botName, durationSeconds)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return end
    pendingHistoryLoading[cleanName] = NowTime() + (durationSeconds or 10.0)
    RefreshHistoryUIIfVisible()
end

function DungeonBots:ClearHistoryBotLoading(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return end
    if pendingHistoryLoading[cleanName] then
        pendingHistoryLoading[cleanName] = nil
        RefreshHistoryUIIfVisible()
    end
end

function DungeonBots:IsHistoryBotLoading(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return false end
    if DungeonBots:FindPartyUnitByName(cleanName, true) then
        pendingHistoryLoading[cleanName] = nil
        return false
    end
    local expiresAt = pendingHistoryLoading[cleanName]
    if not expiresAt then return false end
    if expiresAt <= NowTime() then
        pendingHistoryLoading[cleanName] = nil
        return false
    end
    return true
end

function DungeonBots:ConfirmSummonedBotAdded(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return false end
    local confirmed = false
    if pendingSummonConfirm[cleanName] and pendingSummonConfirm[cleanName] > NowTime() then
        pendingSummonConfirm[cleanName] = nil
        DungeonBots:Print(string.format(L["BOT_ADDED_FMT"], cleanName))
        confirmed = true
    end
    if DungeonBots:FindPartyUnitByName(cleanName, true) or not DungeonBots:HasPendingHistoryInvite(cleanName) then
        DungeonBots:ClearHistoryBotLoading(cleanName)
    end
    return confirmed
end

function DungeonBots:AddBot(botName, inviteDelay, silentPrint)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return false end
    if not CheckCanSummonBot(true) then return false end
    local now = NowTime()
    DungeonBots.lastBotCallAttempt = DungeonBots.lastBotCallAttempt or {}
    DungeonBots.lastBotCallAttempt[cleanName] = now
    if DungeonBots.busyExternalBots and DungeonBots.busyExternalBots[cleanName] then
        -- Reiniciar ventana activa para permitir reintentar si el otro jugador lo solto, conservando dueno previo
        DungeonBots.busyExternalBots[cleanName].expiresAt = 0
    end
    local wasKnown = DungeonBots:IsInHistory(cleanName) or (DungeonBots:IsBot(cleanName) == true)
    DungeonBots:MarkRecentBot(cleanName, 120)
    if wasKnown then
        DungeonBots:RegisterBot(cleanName, true)
    end
    pendingSummonConfirm[cleanName] = now + 12.0
    DungeonBots:SetHistoryBotLoading(cleanName, 12.0)
    if not silentPrint then
        DungeonBots:Print(string.format(L["BOT_SUMMONING_FMT"], cleanName))
    end
    DungeonBots:SendDotCommand(".playerbots bot add " .. cleanName)
    if DungeonBots.SchedulePartyInviteRetry then
        DungeonBots:SchedulePartyInviteRetry(cleanName, inviteDelay or 0.9, 2)
    end
    return true
end

-- Verificación automática tras reinvocar miembros desconocidos del grupo
DungeonBots.pendingResummonVerify = DungeonBots.pendingResummonVerify or {}

local resummonVerifyFrame = CreateFrame("Frame", "DungeonBots_ResummonVerifyFrame")
resummonVerifyFrame:Hide()
resummonVerifyFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = NowTime()
    local hasPending = false
    for botName, entry in pairs(DungeonBots.pendingResummonVerify) do
        if not entry or (entry.expiresAt or 0) <= now or DungeonBots:IsBot(botName) == false or DungeonBots:ShouldTreatAsBot(botName) then
            DungeonBots.pendingResummonVerify[botName] = nil
        else
            local unit = DungeonBots:FindPartyUnitByName(botName, true)
            if not unit then
                DungeonBots.pendingResummonVerify[botName] = nil
            else
                hasPending = true
                if UnitIsConnected(unit) and (entry.scansLeft or 0) > 0 and now >= (entry.nextScanAt or 0) then
                    entry.scansLeft = entry.scansLeft - 1
                    entry.nextScanAt = now + 2.5
                    DungeonBots.pendingScan[botName] = now + 15
                    DungeonBots:SendWhisperCommand(botName, "follow info")
                end
            end
        end
    end
    if not hasPending then
        self:Hide()
    end
end)

function DungeonBots:ConfirmPartyBotIdentity(botName, silent)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return false end
    if UnitName and cleanName == UnitName("player") then return false end
    if DungeonBots:IsBot(cleanName) == false then return false end

    local alreadyBot = DungeonBots:ShouldTreatAsBot(cleanName)
    if DungeonBots.pendingScan then
        DungeonBots.pendingScan[cleanName] = nil
    end
    if DungeonBots.pendingResummonVerify then
        DungeonBots.pendingResummonVerify[cleanName] = nil
    end
    DungeonBots.confirmedBots[cleanName] = true
    DungeonBots:MarkRecentBot(cleanName, 120)
    DungeonBots:RegisterBot(cleanName, true)
    DungeonBots:RecordBotHistory(cleanName)

    if not alreadyBot and not silent then
        DungeonBots:Print(string.format(L["BOT_CONFIRMED_FMT"], cleanName))
    end
    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
    if DungeonBots:FindPartyUnitByName(cleanName, true) and DungeonBots.CheckPartyForNewBots then
        DungeonBots:CheckPartyForNewBots()
    end
    return true
end

function DungeonBots:ScheduleResummonBotVerification(members)
    if not members or #members == 0 then return end
    local now = NowTime()
    local addedAny = false
    for _, botName in ipairs(members) do
        local cleanName = NormalizePlayerName(botName)
        if cleanName and cleanName ~= "" and DungeonBots:IsBot(cleanName) ~= false and not DungeonBots:ShouldTreatAsBot(cleanName) then
            DungeonBots.pendingResummonVerify[cleanName] = {
                expiresAt = now + 15.0,
                nextScanAt = now + 0.9,
                scansLeft = 3,
            }
            addedAny = true
        end
    end
    if addedAny then
        resummonVerifyFrame:Show()
    end
end

function DungeonBots:OnResummonPartyActivity()
    local now = NowTime()
    local hasPending = false
    for botName, entry in pairs(DungeonBots.pendingResummonVerify) do
        if not entry or (entry.expiresAt or 0) <= now or DungeonBots:IsBot(botName) == false or DungeonBots:ShouldTreatAsBot(botName) then
            DungeonBots.pendingResummonVerify[botName] = nil
        else
            local unit = DungeonBots:FindPartyUnitByName(botName, true)
            if not unit then
                DungeonBots.pendingResummonVerify[botName] = nil
            else
                hasPending = true
                if UnitIsConnected(unit) and (entry.nextScanAt or 0) > (now + 0.6) then
                    -- Acelerar la comprobación cuando el miembro recién pasa a conectado
                    entry.nextScanAt = now + 0.6
                end
            end
        end
    end
    if hasPending then
        resummonVerifyFrame:Show()
    end
end

-- Reinvocar a todos los bots del grupo (clave para entrar a mazmorra)
function DungeonBots:AddAllBots()
    local partyBots = {}
    local unverifiedMembers = {}
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and name ~= UNKNOWNOBJECT and name ~= "Unknown" then
                if DungeonBots:ShouldTreatAsBot(name) then
                    DungeonBots:MarkRecentBot(name, 60)
                    table.insert(partyBots, name)
                elseif DungeonBots:IsBot(name) ~= false then
                    table.insert(unverifiedMembers, name)
                end
            end
        end
    end

    if #partyBots > 0 and #unverifiedMembers == 0 then
        for _, botName in ipairs(partyBots) do
            DungeonBots:SendDotCommand(".playerbots bot add " .. botName)
        end
        DungeonBots:SendPartyCommand("summon")
        DungeonBots:Print(string.format(L["BOTS_RESUMMONED_N"], #partyBots))
    elseif numParty > 0 then
        DungeonBots:SendDotCommand(".playerbots bot add *")
        DungeonBots:SendPartyCommand("summon")
        DungeonBots:Print(L["BOTS_RESUMMONED"])
        DungeonBots:ScheduleResummonBotVerification(unverifiedMembers)
    else
        DungeonBots:Warn(L["NO_BOTS_TO_RESUMMON"])
    end
end

-- Cola diferida de comandos .playerbots bot remove tras enviar susurro 'leave'
local pendingDismissQueue = {}
local pendingDismissSeen = {}
local dismissDelayFrame = CreateFrame("Frame", "DungeonBots_DismissDelayFrame")
dismissDelayFrame:Hide()
dismissDelayFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = NowTime()
    while #pendingDismissQueue > 0 do
        local nextItem = pendingDismissQueue[1]
        if not nextItem then
            table.remove(pendingDismissQueue, 1)
        elseif now < (nextItem.executeAt or 0) then
            break
        else
            table.remove(pendingDismissQueue, 1)
            if nextItem.cmd and nextItem.cmd ~= "" then
                pendingDismissSeen[nextItem.cmd] = nil
                DungeonBots:SendDotCommand(nextItem.cmd)
            end
        end
    end
    if #pendingDismissQueue == 0 then
        self:Hide()
    end
end)

local function QueueDeferredDotCommand(cmd, delaySeconds)
    if not cmd or cmd == "" then return end
    if pendingDismissSeen[cmd] then return end
    pendingDismissSeen[cmd] = true
    table.insert(pendingDismissQueue, {
        cmd = cmd,
        executeAt = NowTime() + (delaySeconds or 0.35),
    })
    dismissDelayFrame:Show()
end

local function FindDismissUnitByName(name)
    local partyUnit = DungeonBots:FindPartyUnitByName(name, true)
    if partyUnit then
        return partyUnit, false
    end
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        for i = 1, 40 do
            local unit = "raid" .. i
            if UnitExists(unit) and (not UnitIsUnit or not UnitIsUnit(unit, "player")) and UnitName(unit) == name then
                return unit, true
            end
        end
    end
    return nil, false
end

local function SendBotLeaveWhisper(botName, inRaid)
    if not botName or botName == "" then return end
    if inRaid then
        DungeonBots:SendBotWhisperUnchecked(botName, "leave")
    else
        DungeonBots:SendWhisperCommand(botName, "leave")
    end
end

-- Remover un bot específico y sacarlo del grupo
function DungeonBots:RemoveBot(botName)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or cleanBot == "" then return end
    if DungeonBots:IsBot(cleanBot) == false then return end

    DungeonBots:Print(string.format(L["DISMISSING_BOT_FMT"], cleanBot))

    local unit, inRaid = FindDismissUnitByName(cleanBot)
    local isLfgRestricted = (HasLFGRestrictions and HasLFGRestrictions()) and true or false
    local inGroup = (GetNumPartyMembers and GetNumPartyMembers() > 0) or (GetNumRaidMembers and GetNumRaidMembers() > 0)
    local isConnected = unit and UnitIsConnected(unit) and true or false

    if isConnected then
        -- Solicitar primero que abandone el grupo mientras sigue conectado
        SendBotLeaveWhisper(cleanBot, inRaid)
        if inGroup and IsPartyLeader() and not isLfgRestricted then
            UninviteUnit(cleanBot)
        end
        QueueDeferredDotCommand(".playerbots bot remove " .. cleanBot, 0.35)
    else
        if unit and inGroup and IsPartyLeader() and not isLfgRestricted then
            UninviteUnit(cleanBot)
        end
        DungeonBots:SendDotCommand(".playerbots bot remove " .. cleanBot)
    end
end

-- Remover a todos los bots y sacarlos del grupo (preservando humanos)
function DungeonBots:RemoveAllBots()
    DungeonBots:Print(L["DISMISSING_ALL_BOTS"])

    local numRaid = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    local numParty = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    local inRaid = (numRaid > 0)
    local inGroup = inRaid or (numParty > 0)

    if not inGroup then
        DungeonBots:SendDotCommand(".playerbots bot remove *")
        return
    end

    local botsToDismiss = {}
    local hasHuman = false
    local prefix = inRaid and "raid" or "party"
    local maxUnits = inRaid and 40 or 4

    for i = 1, maxUnits do
        local unit = prefix .. i
        if UnitExists(unit) and (not inRaid or not UnitIsUnit or not UnitIsUnit(unit, "player")) then
            local name = UnitName(unit)
            if name and name ~= "" then
                if not DungeonBots:ShouldTreatAsBot(name) then
                    hasHuman = true
                else
                    table.insert(botsToDismiss, {
                        name = name,
                        connected = UnitIsConnected(unit) and true or false,
                    })
                end
            end
        end
    end

    if #botsToDismiss == 0 then
        DungeonBots:SendDotCommand(".playerbots bot remove *")
        return
    end

    local isLfgRestricted = (HasLFGRestrictions and HasLFGRestrictions()) and true or false
    local isLeader = (IsPartyLeader and IsPartyLeader()) or (inRaid and IsRaidLeader and IsRaidLeader()) or false
    local sentAnyLeaveWhisper = false

    for _, bot in ipairs(botsToDismiss) do
        if bot.connected then
            SendBotLeaveWhisper(bot.name, inRaid)
            sentAnyLeaveWhisper = true
        end
    end

    if not sentAnyLeaveWhisper then
        DungeonBots:SendDotCommand(".playerbots bot remove *")
    end

    if isLeader and not isLfgRestricted then
        for _, bot in ipairs(botsToDismiss) do
            UninviteUnit(bot.name)
        end
    end

    if not hasHuman and not isLfgRestricted then
        LeaveParty()
    end

    if sentAnyLeaveWhisper then
        for _, bot in ipairs(botsToDismiss) do
            QueueDeferredDotCommand(".playerbots bot remove " .. bot.name, 0.35)
        end
    end
end

-- =========================================================================
-- Historial Persistente de Bots e Invitación Individual
-- =========================================================================
StaticPopupDialogs["DUNGEONBOTS_BOT_BUSY_ALERT"] = {
    text = "%s",
    button1 = L["BTN_UNDERSTOOD"],
    OnShow = function(self)
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetFrameLevel(100)
        if self.Raise then
            self:Raise()
        end
    end,
    OnHide = function(self)
        self:SetFrameStrata("DIALOG")
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

local pendingInviteRetries = {}
local historyInviteFrame = CreateFrame("Frame", "DungeonBots_HistoryInviteFrame")
historyInviteFrame:Hide()
historyInviteFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = NowTime()
    local hasPending = false
    local loadingChanged = false
    for botName, expiresAt in pairs(pendingHistoryLoading) do
        if not expiresAt or expiresAt <= now or DungeonBots:FindPartyUnitByName(botName, true) then
            pendingHistoryLoading[botName] = nil
            loadingChanged = true
        elseif not pendingInviteRetries[botName]
            and not (DungeonBots.pendingWhoCheck and DungeonBots.pendingWhoCheck[botName]) then
            pendingHistoryLoading[botName] = nil
            loadingChanged = true
        else
            hasPending = true
        end
    end
    if loadingChanged then
        RefreshHistoryUIIfVisible()
    end

    for botName, entry in pairs(pendingInviteRetries) do
        if DungeonBots:FindPartyUnitByName(botName, true) or DungeonBots:GetExternalBotBusyInfo(botName) then
            pendingInviteRetries[botName] = nil
            DungeonBots:ClearHistoryBotLoading(botName)
        elseif now >= (entry.nextAt or 0) then
            if not DungeonBots:CanInviteToParty() then
                pendingInviteRetries[botName] = nil
                DungeonBots:ClearHistoryBotLoading(botName)
                if DungeonBots.WarnCannotAutoInvite then
                    DungeonBots:WarnCannotAutoInvite(botName)
                end
            elseif (entry.attemptsLeft or 0) > 0 then
                entry.attemptsLeft = entry.attemptsLeft - 1
                entry.nextAt = now + 2.0
                DungeonBots.recentInvites[botName] = now + 1.2
                InviteUnit(botName)
                hasPending = true
            else
                pendingInviteRetries[botName] = nil
                local sentWho = false
                if DungeonBots.RequestBotWhoCheck and DungeonBots:ShouldTreatAsBot(botName) then
                    sentWho = DungeonBots:RequestBotWhoCheck(botName, "invite_failed")
                end
                if not sentWho then
                    DungeonBots:ClearHistoryBotLoading(botName)
                else
                    hasPending = true
                end
            end
        else
            hasPending = true
        end
    end
    if not hasPending then
        self:Hide()
    end
end)

local whoCheckFrame = CreateFrame("Frame", "DungeonBots_WhoCheckFrame")
whoCheckFrame:Hide()
whoCheckFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = NowTime()
    local hasPending = false
    local list = DungeonBots.pendingWhoCheck
    if not list then
        self:Hide()
        return
    end
    for botName, entry in pairs(list) do
        if entry.reason ~= "not_in_instance" and DungeonBots:FindPartyUnitByName(botName, true) then
            list[botName] = nil
            DungeonBots:ClearHistoryBotLoading(botName)
        elseif now >= (entry.expiresAt or 0) then
            list[botName] = nil
            if not pendingInviteRetries[botName] then
                DungeonBots:ClearHistoryBotLoading(botName)
            end
        elseif (entry.reason == "already_logged_in" or entry.reason == "already_in_group") and not entry.warnedTimeout and now >= ((entry.requestedAt or 0) + 2.5) then
            entry.warnedTimeout = true
            list[botName] = nil
            DungeonBots:ClearHistoryBotLoading(botName)
            if entry.reason == "already_in_group" then
                if DungeonBots.NotifyExternalBotBusy then
                    DungeonBots:NotifyExternalBotBusy(botName, nil, "already_in_group", true)
                end
            elseif DungeonBots.NotifyBotAlreadyOnline then
                DungeonBots:NotifyBotAlreadyOnline(botName, nil)
            end
        else
            hasPending = true
        end
    end
    if not hasPending then
        self:Hide()
    end
end)

function DB_Internal.ShowWhoCheckFrame()
    whoCheckFrame:Show()
end

function DungeonBots:SchedulePartyInviteRetry(botName, initialDelay, maxAttempts)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return end
    if DungeonBots:FindPartyUnitByName(cleanName, true) then return end
    if DungeonBots:GetExternalBotBusyInfo(cleanName) then return end

    local now = NowTime()
    local existing = pendingInviteRetries[cleanName]
    local minDelay = 0
    if DungeonBots.recentInvites and (DungeonBots.recentInvites[cleanName] or 0) > now then
        minDelay = (DungeonBots.recentInvites[cleanName] - now) + 0.8
    end
    local delay = math.max(initialDelay or 1.5, minDelay)
    local attempts = maxAttempts or 3
    if existing then
        existing.nextAt = math.min(existing.nextAt or (now + delay), now + delay)
        existing.attemptsLeft = math.max(existing.attemptsLeft or 0, attempts)
    else
        pendingInviteRetries[cleanName] = {
            nextAt = now + delay,
            attemptsLeft = attempts,
        }
    end
    historyInviteFrame:Show()
end

function DungeonBots:CancelPendingHistoryInvite(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return end
    if pendingInviteRetries[cleanName] then
        pendingInviteRetries[cleanName] = nil
        if not next(pendingInviteRetries) then
            historyInviteFrame:Hide()
        end
    end
end

function DungeonBots:HasPendingHistoryInvite(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return false end
    return pendingInviteRetries[cleanName] ~= nil
end

function DungeonBots:WarnCannotAutoInvite(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return end
    local now = NowTime()
    DungeonBots.inviteRetryLastWarn = DungeonBots.inviteRetryLastWarn or {}
    if (DungeonBots.inviteRetryLastWarn[cleanName] or 0) > now then
        return
    end
    DungeonBots.inviteRetryLastWarn[cleanName] = now + 10.0

    local reason = L["REASON_NOT_LEADER"]
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        reason = L["REASON_IN_RAID"]
    elseif (GetNumPartyMembers and GetNumPartyMembers() or 0) >= 4 then
        reason = L["REASON_GROUP_FULL"]
    end
    DungeonBots:Warn(string.format(L["AUTO_INVITE_FAIL_FMT"], cleanName, reason))
end

function DungeonBots:NotifyBotInstanceMismatch(botName, whoInfo)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return end
    local now = NowTime()
    DungeonBots.instanceWarnLastAt = DungeonBots.instanceWarnLastAt or {}
    local last = DungeonBots.instanceWarnLastAt[cleanName]
    local hasZone = (whoInfo and whoInfo.zone and whoInfo.zone ~= "") and true or false
    if last and (last.expiresAt or 0) > now and not (hasZone and not last.hadZone) then
        return
    end
    DungeonBots.instanceWarnLastAt[cleanName] = {
        expiresAt = now + 8.0,
        hadZone = hasZone,
    }
    if hasZone then
        DungeonBots:Warn(string.format(L["INSTANCE_MISMATCH_Z"], cleanName, whoInfo.zone))
    else
        DungeonBots:Warn(string.format(L["INSTANCE_MISMATCH"], cleanName))
    end
end

local alreadyOnlineLastWarn = {}
function DungeonBots:NotifyBotAlreadyOnline(botName, whoInfo)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return end
    local now = NowTime()
    local myName = UnitName and NormalizePlayerName(UnitName("player"))
    local hasWho = (whoInfo ~= nil)
    local last = alreadyOnlineLastWarn[cleanName]
    if last and (last.expiresAt or 0) > now and not (hasWho and not last.hadWho) then
        return
    end
    alreadyOnlineLastWarn[cleanName] = {
        expiresAt = now + 6.0,
        hadWho = hasWho,
    }
    local zoneSuffix = (whoInfo and whoInfo.zone and whoInfo.zone ~= "")
        and string.format(L["ZONE_PAREN_FMT"], whoInfo.zone) or ""
    if whoInfo and whoInfo.playingWith and myName and whoInfo.playingWith == myName then
        DungeonBots:Warn(string.format(L["BOT_ONLINE_LINKED"], cleanName, zoneSuffix))
    elseif whoInfo then
        DungeonBots:Warn(string.format(L["BOT_ONLINE_FREE"], cleanName, zoneSuffix))
    else
        DungeonBots:Warn(string.format(L["BOT_ONLINE_UNKNOWN"], cleanName))
    end
end

function DungeonBots:GetExternalBotBusyInfo(botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return nil end
    if DungeonBots:FindPartyUnitByName(cleanName, true) then
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
    pendingSummonConfirm[cleanName] = nil
    DungeonBots:ClearHistoryBotLoading(cleanName)
    DungeonBots:ClearRecentBot(cleanName)
    if DungeonBots.pendingWhoCheck then DungeonBots.pendingWhoCheck[cleanName] = nil end
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

function DungeonBots:NotifyExternalBotBusy(botName, ownerName, sourceTag, forceAlert, zoneName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return false end
    if DungeonBots:FindPartyUnitByName(cleanName, true) then
        if DungeonBots.busyExternalBots then
            DungeonBots.busyExternalBots[cleanName] = nil
        end
        return false
    end

    local resolvedOwner = NormalizePlayerName(ownerName)
    local myName = UnitName and NormalizePlayerName(UnitName("player"))
    if resolvedOwner and myName and resolvedOwner == myName then
        return false
    end

    local now = NowTime()
    DungeonBots.busyExternalBots = DungeonBots.busyExternalBots or {}
    local prev = DungeonBots.busyExternalBots[cleanName]
    if (not resolvedOwner or resolvedOwner == "") and prev and prev.owner and prev.owner ~= "" then
        resolvedOwner = prev.owner
    end

    local resolvedZone = zoneName
    if (not resolvedZone or resolvedZone == "") and DungeonBots.botWhoInfo and DungeonBots.botWhoInfo[cleanName] then
        resolvedZone = DungeonBots.botWhoInfo[cleanName].zone
    end
    local zoneSuffix = (resolvedZone and resolvedZone ~= "") and string.format(L["ZONE_IN_FMT"], resolvedZone) or ""

    DungeonBots.busyExternalBots[cleanName] = {
        owner = resolvedOwner,
        zone = resolvedZone,
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
        chatMsg = string.format(L["ALERT_BOT_OWNER_CHAT"], cleanName, resolvedOwner, zoneSuffix)
        plainMsg = string.format(L["ALERT_BOT_OWNER_UI"], cleanName, resolvedOwner)
    else
        chatMsg = string.format(L["ALERT_BOT_GROUP_CHAT"], cleanName, zoneSuffix)
        plainMsg = string.format(L["ALERT_BOT_GROUP_UI"], cleanName)
    end

    DungeonBots:Warn(chatMsg)
    if PlaySound then
        PlaySound("igQuestFailed")
    end
    if StaticPopup_Show then
        if StaticPopup_Hide then
            StaticPopup_Hide("DUNGEONBOTS_BOT_BUSY_ALERT")
        end
        StaticPopup_Show("DUNGEONBOTS_BOT_BUSY_ALERT", chatMsg)
    elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(plainMsg, 1.0, 0.22, 0.22, 1.0)
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

    if DungeonBotsDB.botTeams then
        local saved = DungeonBotsDB.botHistory[name]
        for teamIdx = 1, 3 do
            local teamList = DungeonBotsDB.botTeams[teamIdx]
            if type(teamList) == "table" then
                for _, member in ipairs(teamList) do
                    if type(member) == "table" and member.name == name then
                        if saved.class and saved.class ~= "UNKNOWN" then
                            member.class = saved.class
                        end
                        if saved.spec and saved.spec ~= "" then
                            member.spec = saved.spec
                        end
                        if saved.raceIcon and saved.raceIcon ~= "" and saved.raceIcon ~= defaultQuestionIcon then
                            member.raceIcon = saved.raceIcon
                        end
                    end
                end
            end
        end
    end
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
    -- Conservar la identidad de bot conocida aunque se quite la entrada visible del historial
    if DungeonBots:IsBot(botName) ~= false then
        DungeonBots:RegisterBot(botName, true)
    end
    DungeonBotsDB.botHistory[botName] = nil
    if not FindDismissUnitByName(botName) then
        if DungeonBotsDB.botActiveSpec then
            DungeonBotsDB.botActiveSpec[botName] = nil
        end
        if DungeonBotsDB.botSpecs then
            DungeonBotsDB.botSpecs[botName] = nil
        end
        if DungeonBots.botSpecs then
            DungeonBots.botSpecs[botName] = nil
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

function DungeonBots:ClearBotHistory()
    if not DungeonBotsDB then DungeonBotsDB = {} end
    -- Preservar conocidos como bots para evitar que vuelvan a aparecer como humanos al reingresar
    if DungeonBotsDB.botHistory then
        for name, _ in pairs(DungeonBotsDB.botHistory) do
            if name and name ~= "" and DungeonBots:IsBot(name) ~= false then
                DungeonBots:RegisterBot(name, true)
            end
        end
    end
    DungeonBotsDB.botHistory = {}
    local keptActiveSpec = {}
    if DungeonBotsDB.botActiveSpec then
        for name, specVal in pairs(DungeonBotsDB.botActiveSpec) do
            if FindDismissUnitByName(name) then
                keptActiveSpec[name] = specVal
            end
        end
    end
    DungeonBotsDB.botActiveSpec = keptActiveSpec
    local keptBotSpecs = {}
    if DungeonBotsDB.botSpecs then
        for name, specList in pairs(DungeonBotsDB.botSpecs) do
            if FindDismissUnitByName(name) then
                keptBotSpecs[name] = specList
            end
        end
    end
    DungeonBotsDB.botSpecs = keptBotSpecs
    DungeonBotsDB.historyMigrated = true
    DungeonBots.botSpecs = DungeonBotsDB.botSpecs
    if DungeonBots.UpdateHistorySummary then
        DungeonBots:UpdateHistorySummary()
    end
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
    DungeonBots:Print(L["BOT_HISTORY_CLEARED"])
end

function DungeonBots:SummonAndInviteHistoryBot(botName)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or cleanBot == "" then return end
    if DungeonBots:FindPartyUnitByName(cleanBot, true) then
        DungeonBots:Print(string.format(L["ALREADY_IN_PARTY_FMT"], cleanBot))
        return
    end
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if (GetNumRaidMembers and GetNumRaidMembers() > 0) or numParty >= 4 then
        DungeonBots:Warn(string.format(L["PARTY_FULL_INVITE_FMT"], cleanBot))
        return
    end
    if numParty > 0 and IsPartyLeader and not IsPartyLeader() then
        DungeonBots:Warn(string.format(L["MUST_BE_LEADER_FMT"], cleanBot))
        return
    end
    DungeonBots:AddBot(cleanBot)
end

-- =========================================================================
-- Equipos Guardados de Bots (3 Columnas)
-- =========================================================================
local MAX_BOT_TEAMS = 3

local function EnsureBotTeamsTable()
    if not DungeonBotsDB then DungeonBotsDB = {} end
    if type(DungeonBotsDB.botTeams) ~= "table" then
        DungeonBotsDB.botTeams = {}
    end
    for i = 1, MAX_BOT_TEAMS do
        if type(DungeonBotsDB.botTeams[i]) ~= "table" then
            DungeonBotsDB.botTeams[i] = {}
        end
    end
    return DungeonBotsDB.botTeams
end

local function BuildTeamBotSnapshot(botName, hintEntry)
    local cleanName = NormalizePlayerName(botName)
    local hist = DungeonBotsDB and DungeonBotsDB.botHistory and DungeonBotsDB.botHistory[cleanName]
    local defaultQuestionIcon = "Interface\\Icons\\INV_Misc_QuestionMark"

    local classToken = (hintEntry and hintEntry.class) or (hist and hist.class) or "UNKNOWN"
    local raceIcon = (hintEntry and hintEntry.raceIcon) or (hist and hist.raceIcon) or defaultQuestionIcon
    local spec = (hintEntry and hintEntry.spec) or (DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[cleanName]) or (hist and hist.spec) or ""

    local unit = DungeonBots:FindPartyUnitByName(cleanName, true)
    if unit then
        if not classToken or classToken == "" or classToken == "UNKNOWN" then
            local _, detectedClass = UnitClass(unit)
            if detectedClass then classToken = detectedClass end
        end
        if not raceIcon or raceIcon == "" or raceIcon == defaultQuestionIcon then
            local detectedIcon = DungeonBots:GetRaceIcon(unit)
            if detectedIcon and detectedIcon ~= "" then raceIcon = detectedIcon end
        end
    end
    if DungeonBots.CleanSpecText then
        spec = DungeonBots:CleanSpecText(spec)
    end
    return {
        name = cleanName,
        class = (classToken and classToken ~= "" and classToken) or "UNKNOWN",
        spec = spec or "",
        raceIcon = (raceIcon and raceIcon ~= "" and raceIcon) or defaultQuestionIcon,
    }
end

function DungeonBots:GetBotTeam(teamIndex)
    local idx = tonumber(teamIndex)
    if not idx or idx < 1 or idx > MAX_BOT_TEAMS then return {} end
    local teams = EnsureBotTeamsTable()
    local rawList = teams[idx]
    local resolved = {}
    local seen = {}
    for i = 1, #rawList do
        local item = rawList[i]
        local rawName = (type(item) == "table") and item.name or item
        local cleanName = NormalizePlayerName(rawName)
        if cleanName and cleanName ~= "" and not seen[cleanName] then
            seen[cleanName] = true
            local snap = BuildTeamBotSnapshot(cleanName, type(item) == "table" and item or nil)
            rawList[i] = snap
            table.insert(resolved, snap)
        end
    end
    return resolved
end

function DungeonBots:IsBotInTeam(teamIndex, botName)
    local cleanName = NormalizePlayerName(botName)
    if not cleanName or cleanName == "" then return false end
    local list = DungeonBots:GetBotTeam(teamIndex)
    for _, entry in ipairs(list) do
        if entry.name == cleanName then
            return true
        end
    end
    return false
end

function DungeonBots:AddBotToTeam(teamIndex, botName, hintEntry)
    local idx = tonumber(teamIndex)
    local cleanName = NormalizePlayerName(botName)
    if not idx or idx < 1 or idx > MAX_BOT_TEAMS or not cleanName or cleanName == "" then
        return false
    end
    local teams = EnsureBotTeamsTable()
    local list = teams[idx]
    for i, item in ipairs(list) do
        local itemName = (type(item) == "table") and item.name or item
        if NormalizePlayerName(itemName) == cleanName then
            list[i] = BuildTeamBotSnapshot(cleanName, hintEntry or (type(item) == "table" and item or nil))
            RefreshHistoryUIIfVisible()
            return false
        end
    end
    table.insert(list, BuildTeamBotSnapshot(cleanName, hintEntry))
    if DungeonBots:IsBot(cleanName) ~= false then
        DungeonBots:RegisterBot(cleanName, true)
    end
    DungeonBots:Print(string.format(L["HIST_TEAM_ADDED_FMT"], cleanName, idx))
    RefreshHistoryUIIfVisible()
    return true
end

function DungeonBots:RemoveBotFromTeam(teamIndex, botName)
    local idx = tonumber(teamIndex)
    local cleanName = NormalizePlayerName(botName)
    if not idx or idx < 1 or idx > MAX_BOT_TEAMS or not cleanName or cleanName == "" then
        return false
    end
    local teams = EnsureBotTeamsTable()
    local list = teams[idx]
    for i = #list, 1, -1 do
        local item = list[i]
        local itemName = (type(item) == "table") and item.name or item
        if NormalizePlayerName(itemName) == cleanName then
            table.remove(list, i)
            DungeonBots:Print(string.format(L["HIST_TEAM_REMOVED_FMT"], cleanName, idx))
            RefreshHistoryUIIfVisible()
            return true
        end
    end
    return false
end

function DungeonBots:SummonBotTeam(teamIndex)
    local idx = tonumber(teamIndex)
    if not idx or idx < 1 or idx > MAX_BOT_TEAMS then return end
    local team = DungeonBots:GetBotTeam(idx)
    if #team == 0 then return end

    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        DungeonBots:Warn(L["GROUP_FULL_CANT_ADD"])
        return
    end

    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    local toSummon = {}
    local hasConnectedBot = false
    for _, entry in ipairs(team) do
        local unit = DungeonBots:FindPartyUnitByName(entry.name, true)
        if unit then
            if not UnitIsConnected(unit) then
                table.insert(toSummon, { name = entry.name, alreadyInParty = true })
            else
                hasConnectedBot = true
            end
        else
            table.insert(toSummon, { name = entry.name, alreadyInParty = false })
        end
    end

    if #toSummon == 0 then
        if hasConnectedBot then
            DungeonBots:Print(string.format(L["ALREADY_IN_PARTY_FMT"], string.format(L["HIST_TEAM_TITLE_FMT"], idx)))
        end
        return
    end

    if numParty > 0 and IsPartyLeader and not IsPartyLeader() then
        local hasNewInvite = false
        for _, item in ipairs(toSummon) do
            if not item.alreadyInParty then
                hasNewInvite = true
                break
            end
        end
        if hasNewInvite then
            DungeonBots:Warn(string.format(L["MUST_BE_LEADER_FMT"], string.format(L["HIST_TEAM_TITLE_FMT"], idx)))
            return
        end
    end

    local freeSlots = math.max(0, 4 - numParty)
    local summonedList = {}
    for _, item in ipairs(toSummon) do
        if item.alreadyInParty then
            table.insert(summonedList, item)
        elseif freeSlots > 0 then
            freeSlots = freeSlots - 1
            table.insert(summonedList, item)
        end
    end

    if #summonedList == 0 then
        DungeonBots:Warn(string.format(L["HIST_TEAM_NO_SLOTS"], idx))
        return
    end

    DungeonBots:Print(string.format(L["HIST_TEAM_SUMMONING_FMT"], idx, #summonedList))
    for orderIdx, item in ipairs(summonedList) do
        if item.alreadyInParty then
            DungeonBots:MarkRecentBot(item.name, 60)
            DungeonBots:SendDotCommand(".playerbots bot add " .. item.name)
        else
            DungeonBots:AddBot(item.name, 0.9 + ((orderIdx - 1) * 0.30), true)
        end
    end
    RefreshHistoryUIIfVisible()
end
