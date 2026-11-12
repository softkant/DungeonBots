-- =========================================================================
-- DungeonBots_Events.lua: Eventos WoW y Comandos Slash
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

-- =========================================================================
-- Registro y Manejo de Eventos
-- =========================================================================
local eventFrame = CreateFrame("Frame", "DungeonBots_EventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

local function HandlePartyChanged(isEnteringWorld)
    DungeonBots:ResolvePendingPartyBots()
    DungeonBots:SyncPartyToHistory()
    if DungeonBots.CheckPartyForNewBots then
        DungeonBots:CheckPartyForNewBots()
    end
    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
    if DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown() and DungeonBots.UpdateTalkDialog then
        DungeonBots:UpdateTalkDialog()
    end
    if isEnteringWorld and DungeonBots.UpdateHUDVisibility then
        DungeonBots:UpdateHUDVisibility()
    end
    if isEnteringWorld and DungeonBots.UpdateHUDTalkButtonState then
        DungeonBots:UpdateHUDTalkButtonState()
    end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local DEFAULT_CONFIG = DB_Internal.DEFAULT_CONFIG or {}
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "DungeonBots" then
            DungeonBotsDB = DungeonBotsDB or {}
            for k, v in pairs(DEFAULT_CONFIG) do
                if DungeonBotsDB[k] == nil then
                    DungeonBotsDB[k] = v
                end
            end
            DungeonBotsDB.autoInvite = true
            if DungeonBotsDB.whisperMuteMode == "auto" then
                DungeonBotsDB.whisperMuteMode = "all"
            end
            if DungeonBots.SetupChatFilters then
                DungeonBots:SetupChatFilters()
            end
        elseif addonName == "WIM" then
            if DungeonBots.SetupWIMCompatibility then
                DungeonBots:SetupWIMCompatibility()
            end
        end

    elseif event == "PLAYER_LOGIN" then
        DungeonBotsDB = DungeonBotsDB or {}
        for k, v in pairs(DEFAULT_CONFIG) do
            if DungeonBotsDB[k] == nil then
                if type(v) == "table" then
                    DungeonBotsDB[k] = {}
                    for tk, tv in pairs(v) do
                        DungeonBotsDB[k][tk] = tv
                    end
                else
                    DungeonBotsDB[k] = v
                end
            end
        end
        DungeonBotsDB.autoInvite = true

        DungeonBotsDB.botHistory = DungeonBotsDB.botHistory or {}
        for _, entry in pairs(DungeonBotsDB.botHistory) do
            if entry and entry.spec and entry.spec ~= "" then
                entry.spec = DungeonBots:CleanSpecText(entry.spec)
            end
        end
        if DungeonBotsDB.botActiveSpec then
            for name, activeSpec in pairs(DungeonBotsDB.botActiveSpec) do
                if activeSpec and activeSpec ~= "" then
                    DungeonBotsDB.botActiveSpec[name] = DungeonBots:CleanSpecText(activeSpec)
                end
            end
        end
        if DungeonBotsDB.botSpecs then
            for botName, specList in pairs(DungeonBotsDB.botSpecs) do
                if type(specList) == "table" then
                    local deduped = {}
                    local seen = {}
                    for _, specVal in ipairs(specList) do
                        if type(specVal) == "string" and specVal ~= "" then
                            local cleanedSpec = DungeonBots:CleanSpecText(specVal)
                            local lowerSpec = string.lower(cleanedSpec)
                            if cleanedSpec ~= "" and not seen[lowerSpec] then
                                seen[lowerSpec] = true
                                table.insert(deduped, cleanedSpec)
                            end
                        end
                    end
                    DungeonBotsDB.botSpecs[botName] = deduped
                end
            end
        end
        DungeonBots.botSpecs = DungeonBotsDB.botSpecs or {}
        if DungeonBotsDB.whisperMuteMode == "auto" then
            DungeonBotsDB.whisperMuteMode = "all"
        end

        DungeonBotsDB.historyMigrated = true

        DungeonBots:SetupChatFilters()
        DungeonBots:SetupWIMCompatibility()
        DungeonBots:HookSendChatForTalk()

        DungeonBots:Print("v" .. DungeonBots.VERSION .. " cargado. Escribe |cffffd200/db|r o |cffffd200/bots|r, o pulsa en |cff71d5ffEl Ojo|r del Buscador de Mazmorras.")
        if DungeonBots.InitUI then
            DungeonBots:InitUI()
        end
        if DungeonBots.InitHUD then
            DungeonBots:InitHUD()
        end
        DungeonBots:SyncPartyToHistory()

    elseif event == "CHAT_MSG_SYSTEM" then
        local message = ...
        if message and DB_Internal.ExtractBusyBotFromSystem then
            local busyBot, busyKind = DB_Internal.ExtractBusyBotFromSystem(message)
            if busyBot and not DungeonBots:FindPartyUnitByName(busyBot) then
                local shouldNotify = (busyKind == "already_logged_in")
                if not shouldNotify and busyKind == "not_in_instance" then
                    local hasRecentInform = DungeonBots.recentUserWhisperTargets
                        and (DungeonBots.recentUserWhisperTargets[busyBot] or 0) > NowTime()
                    shouldNotify = DungeonBots:IsRecentBot(busyBot)
                        or (DungeonBots.HasPendingHistoryInvite and DungeonBots:HasPendingHistoryInvite(busyBot))
                        or (DungeonBots.GetExternalBotBusyInfo and DungeonBots:GetExternalBotBusyInfo(busyBot) ~= nil)
                        or DungeonBots:ShouldTreatAsBot(busyBot)
                        or hasRecentInform
                end
                if shouldNotify and DungeonBots.NotifyExternalBotBusy then
                    local prevInfo = DungeonBots.busyExternalBots and DungeonBots.busyExternalBots[busyBot]
                    local knownOwner = prevInfo and prevInfo.owner or nil
                    DungeonBots:NotifyExternalBotBusy(busyBot, knownOwner, busyKind, busyKind == "not_in_instance")
                end
            end
        end

    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local message, target = ...
        local cleanTarget = NormalizePlayerName(target)
        if cleanTarget and cleanTarget ~= "" and not DungeonBots:FindPartyUnitByName(cleanTarget) then
            local isTrackedBot = DungeonBots:ShouldTreatAsBot(cleanTarget)
                or (DungeonBots.HasPendingHistoryInvite and DungeonBots:HasPendingHistoryInvite(cleanTarget))
                or (DungeonBots.GetExternalBotBusyInfo and DungeonBots:GetExternalBotBusyInfo(cleanTarget) ~= nil)
            if isTrackedBot then
                DungeonBots.recentUserWhisperTargets = DungeonBots.recentUserWhisperTargets or {}
                DungeonBots.recentUserWhisperTargets[cleanTarget] = NowTime() + 10
            end
            local busyInfo = DungeonBots.GetExternalBotBusyInfo and DungeonBots:GetExternalBotBusyInfo(cleanTarget)
            if busyInfo and DungeonBots.NotifyExternalBotBusy then
                DungeonBots:NotifyExternalBotBusy(cleanTarget, busyInfo.owner, "whisper_inform", true)
            end
        end

    elseif event == "CHAT_MSG_WHISPER" then
        local message, sender = ...
        if not sender then return end
        local cleanSender = NormalizePlayerName(sender)
        local playerName = UnitName and UnitName("player")
        if not cleanSender or cleanSender == "" or cleanSender == playerName then
            return
        end

        if not DungeonBots:FindPartyUnitByName(cleanSender) and DB_Internal.ExtractBusyBotOwnerFromWhisper then
            local busyOwner, isBusyWhisper = DB_Internal.ExtractBusyBotOwnerFromWhisper(message)
            if isBusyWhisper then
                if DungeonBots.NotifyExternalBotBusy then
                    DungeonBots:NotifyExternalBotBusy(cleanSender, busyOwner, "whisper", true)
                end
                if DungeonBots.OnWhisperReceived then
                    DungeonBots:OnWhisperReceived(cleanSender, message)
                end
                return
            end
        end

        local evalResult = DungeonBots:EvaluateWhisperSender(cleanSender, message, true)
        if not evalResult or not evalResult.isBot then
            if DungeonBots.OnWhisperReceived then
                DungeonBots:OnWhisperReceived(cleanSender, message)
            end
            return
        end

        local inParty = evalResult.inParty
        local isKnownOrHistory = evalResult.isKnownOrHistory
        local isBotText = evalResult.isBotText

        local handledQuestShare = false
        if DB_Internal.ParseQuestShareWhisper then
            handledQuestShare = DB_Internal.ParseQuestShareWhisper(cleanSender, message) and true or false
        end
        local handledQuestSummary = false
        if not handledQuestShare and DB_Internal.ParseQuestSummaryWhisper then
            handledQuestSummary = DB_Internal.ParseQuestSummaryWhisper(cleanSender, message) and true or false
        end
        if not handledQuestShare and not handledQuestSummary and DB_Internal.ParseQuestCaptureWhisper then
            DB_Internal.ParseQuestCaptureWhisper(cleanSender, message)
        end
        if not handledQuestShare and not handledQuestSummary and DB_Internal.ParseTalkCaptureWhisper then
            DB_Internal.ParseTalkCaptureWhisper(cleanSender, message)
        end
        if not handledQuestSummary and DB_Internal.ParseInventoryCaptureWhisper then
            DB_Internal.ParseInventoryCaptureWhisper(cleanSender, message)
        end
        if not handledQuestSummary and DB_Internal.ParseSpellsCaptureWhisper then
            DB_Internal.ParseSpellsCaptureWhisper(cleanSender, message)
        end

        local parsedStats = nil
        if DB_Internal.ParseBotStatsWhisper then
            parsedStats = DB_Internal.ParseBotStatsWhisper(message)
        end
        if parsedStats then
            parsedStats.updatedAt = NowTime()
            DungeonBots.botStats = DungeonBots.botStats or {}
            DungeonBots.botStats[cleanSender] = parsedStats
            if DungeonBots.UpdateInventoryDialog and DungeonBots.inventoryFrame and DungeonBots.inventoryFrame:IsShown() and DungeonBots.inventoryFrame.currentBot == cleanSender then
                DungeonBots:UpdateInventoryDialog(cleanSender)
            end
        end

        -- Parser dinámico de ramas de talentos y especialización activa en vivo
        local foundAnySpec, detectedActiveSpec = false, nil
        if DB_Internal.ParseTalentWhisper then
            foundAnySpec, detectedActiveSpec = DB_Internal.ParseTalentWhisper(cleanSender, message)
        end
        local queryStates = DB_Internal.queryStates
        local qState = queryStates and queryStates[cleanSender]

        if foundAnySpec and DungeonBotsDB then
            DungeonBotsDB.botSpecs = DungeonBotsDB.botSpecs or {}
            DungeonBotsDB.botSpecs[cleanSender] = DungeonBots.botSpecs[cleanSender]
            if qState then
                qState.gotSpecList = true
            end
            DungeonBots:RegisterBot(cleanSender, true)
            DungeonBots:RecordBotHistory(cleanSender)

            -- Si 'talents' llegó antes que 'talents spec list', refinar con las ramas reales recién recibidas
            if not detectedActiveSpec then
                local refined = nil
                local lastTriplet = DungeonBots.lastDetectedTriplet and DungeonBots.lastDetectedTriplet[cleanSender]
                if lastTriplet and DungeonBots.botSpecTriplets[cleanSender] then
                    refined = DungeonBots.botSpecTriplets[cleanSender][lastTriplet]
                end
                if not refined then
                    local lastTree = DungeonBots.lastDetectedTree and DungeonBots.lastDetectedTree[cleanSender]
                    if lastTree and DB_Internal.ResolveTreeToSpec then
                        local candidateRefined = DB_Internal.ResolveTreeToSpec(cleanSender, lastTree)
                        if candidateRefined and candidateRefined ~= "" and string.lower(candidateRefined) ~= string.lower(lastTree) then
                            refined = candidateRefined
                        end
                    end
                end
                if not refined and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[cleanSender] then
                    refined = DungeonBots:CanonicalizeSpec(cleanSender, DungeonBotsDB.botActiveSpec[cleanSender])
                end
                if refined and refined ~= "" then
                    detectedActiveSpec = refined
                end
            end

            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
            if DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() and DungeonBots.spellsFrame.currentBot == cleanSender then
                DungeonBots:UpdateSpellsDialog(cleanSender)
            end
        end

        if detectedActiveSpec and detectedActiveSpec ~= "" then
            detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, detectedActiveSpec)
            if DungeonBotsDB then
                DungeonBotsDB.botActiveSpec = DungeonBotsDB.botActiveSpec or {}
                DungeonBotsDB.botActiveSpec[cleanSender] = detectedActiveSpec
            end
            if qState then
                qState.gotActiveSpec = true
            end
            DungeonBots.pendingSpecReset[cleanSender] = nil
            DungeonBots:RegisterBot(cleanSender, true)
            DungeonBots:RecordBotHistory(cleanSender, nil, detectedActiveSpec, nil)
            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
            if DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() and DungeonBots.spellsFrame.currentBot == cleanSender then
                DungeonBots:UpdateSpellsDialog(cleanSender)
            end
        end

        local isBotResponse = (foundAnySpec or detectedActiveSpec or isBotText or handledQuestSummary or (parsedStats ~= nil)) and true or false
        if isBotResponse then
            DungeonBots.confirmedBots[cleanSender] = true
            DungeonBots:RegisterBot(cleanSender, true)
            DungeonBots:RecordBotHistory(cleanSender)
            if DungeonBots:HasPendingScan(cleanSender) then
                DungeonBots.pendingScan[cleanSender] = nil
                DungeonBots:Print("Bot confirmado: |cff00e5ff" .. cleanSender .. "|r (respondió automáticamente como bot).")
            end
            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
        end

        -- Auto-invite solo para bots recién invocados o bots del historial con respuesta de bot, si hay cupo (< 5 en grupo)
        local isExternallyBusy = DungeonBots.GetExternalBotBusyInfo and (DungeonBots:GetExternalBotBusyInfo(cleanSender) ~= nil)
        local shouldAutoInvite = (not isExternallyBusy) and (DungeonBots:IsRecentBot(cleanSender) or (isKnownOrHistory and isBotResponse))
        if shouldAutoInvite and not inParty and DungeonBots:CanInviteToParty() then
            if (DungeonBots.recentInvites[cleanSender] or 0) <= NowTime() then
                DungeonBots.recentInvites[cleanSender] = NowTime() + 3
                DungeonBots:RecordBotHistory(cleanSender)
                InviteUnit(cleanSender)
                DungeonBots:Print("Auto-invitando bot detectado: |cffffd200" .. cleanSender .. "|r")
            end
        end

        -- Guardar log de último susurro para la pestaña de bots
        if DungeonBots.OnWhisperReceived then
            DungeonBots:OnWhisperReceived(cleanSender, message)
        end

    elseif event == "PARTY_MEMBERS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        HandlePartyChanged(event == "PLAYER_ENTERING_WORLD")

    elseif event == "UNIT_NAME_UPDATE" then
        local unit = ...
        if unit and string.match(unit, "^party%d$") then
            HandlePartyChanged(false)
        end

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        if DungeonBots.UpdateHUDVisibility then
            DungeonBots:UpdateHUDVisibility()
        end

    elseif event == "PLAYER_TARGET_CHANGED" then
        if DungeonBots.UpdateHUDTalkButtonState then
            DungeonBots:UpdateHUDTalkButtonState()
        end
    end
end)

-- =========================================================================
-- Comandos Slash (/db, /dungeonbots, /bots, /playerbot)
-- =========================================================================
local function CleanMsg(str)
    if not str then return "" end
    str = string.gsub(str, "^%s*(.-)%s*$", "%1")
    return string.lower(str)
end

SLASH_DUNGEONBOTS1 = "/db"
SLASH_DUNGEONBOTS2 = "/dungeonbots"
SLASH_DUNGEONBOTS3 = "/bots"
SLASH_DUNGEONBOTS4 = "/playerbot"

local function ResolveBotNameArg(botArg)
    local cleanArg = TrimText(botArg or "")
    if cleanArg == "" then return nil end
    local lowerArg = string.lower(cleanArg)
    for i = 1, 4 do
        local pName = UnitName("party" .. i)
        if pName and string.lower(pName) == lowerArg then
            return pName
        end
    end
    if DungeonBotsDB and DungeonBotsDB.botHistory then
        for hName in pairs(DungeonBotsDB.botHistory) do
            if string.lower(hName) == lowerArg then
                return hName
            end
        end
    end
    return cleanArg
end

SlashCmdList["DUNGEONBOTS"] = function(rawMsg)
    local trimmed = TrimText(rawMsg or "")
    local msg = CleanMsg(trimmed)
    if msg == "hud" then
        if DungeonBots.ToggleHUD then
            DungeonBots:ToggleHUD()
        end
    elseif msg == "talk" or string.match(msg, "^talk%s+") then
        local resolvedBot = ResolveBotNameArg(string.sub(trimmed, 5))
        DungeonBots:SendTalkCommand(resolvedBot, "talk")
    elseif msg == "inv" or msg == "inventory" or string.match(msg, "^inv%s+") or string.match(msg, "^inventory%s+") then
        local botArg = string.match(trimmed, "^%S+%s+(.+)$")
        local resolvedBot = ResolveBotNameArg(botArg) or (DungeonBots.FindDefaultTalkBot and DungeonBots:FindDefaultTalkBot())
        if DungeonBots.QueryBotInventory then
            DungeonBots:QueryBotInventory(resolvedBot)
        end
    elseif msg == "spells" or msg == "poderes" or string.match(msg, "^spells%s+") or string.match(msg, "^poderes%s+") then
        local arg1, arg2 = string.match(trimmed, "^%S+%s+(%S+)%s*(.-)$")
        local resolvedBot = ResolveBotNameArg(arg1)
        local filterArg = arg2 or ""
        if not arg1 or arg1 == "" or (DungeonBots.FindPartyUnitByName and not DungeonBots:FindPartyUnitByName(resolvedBot) and not (DungeonBotsDB and DungeonBotsDB.botHistory and DungeonBotsDB.botHistory[resolvedBot])) then
            resolvedBot = DungeonBots.FindDefaultTalkBot and DungeonBots:FindDefaultTalkBot()
            filterArg = string.match(trimmed, "^%S+%s+(.+)$") or ""
        end
        if DungeonBots.QueryBotSpells then
            DungeonBots:QueryBotSpells(resolvedBot, "spells", filterArg, false)
        end
    elseif msg == "dalaran" then
        DungeonBots:DalaranPrep()
    elseif msg == "addall" then
        DungeonBots:AddAllBots()
    elseif msg == "dismiss" or msg == "removeall" then
        DungeonBots:RemoveAllBots()
    elseif msg == "reset" then
        if DungeonBots.ResetHUDPositions then
            DungeonBots:ResetHUDPositions()
            DungeonBots:Print("Posición de las barras flotantes restaurada.")
        end
    else
        if DungeonBots.ToggleUI then
            DungeonBots:ToggleUI()
        elseif DungeonBots.InitUI then
            DungeonBots:InitUI()
            if DungeonBots.ToggleUI then
                DungeonBots:ToggleUI()
            end
        end
    end
end
