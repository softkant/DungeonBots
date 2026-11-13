-- =========================================================================
-- DungeonBots_Events.lua: Eventos WoW y Comandos Slash
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

-- =========================================================================
-- Registro y Manejo de Eventos
-- =========================================================================
local eventFrame = CreateFrame("Frame", "DungeonBots_EventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
eventFrame:RegisterEvent("CHAT_MSG_PARTY")
eventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_SAY")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
eventFrame:RegisterEvent("LFG_LOCK_INFO_RECEIVED")
eventFrame:RegisterEvent("LFG_UPDATE")
eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
eventFrame:RegisterEvent("UNIT_CONNECTION")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

local lastInventoryFullWarnAt = {}
local lastLfgQueueMode = nil

local function NotifyBotInventoryFull(botName)
    if not botName or botName == "" then return end
    local now = NowTime()
    if (lastInventoryFullWarnAt[botName] or 0) > now then
        return
    end
    lastInventoryFullWarnAt[botName] = now + 20.0
    DungeonBots:Warn(string.format(L["BAG_FULL_WARN_FMT"], botName))
end

local function UpdateFleeStateFromMessage(cleanSender, message, isPartyChat)
    if not message or message == "" or not DungeonBots.SetFleeActive then return end
    local clean = TrimText(DB_Internal.StripWowFormatting(message))
    if clean == "" then return end
    local lowerMsg = string.lower(clean)
    local playerName = UnitName and NormalizePlayerName(UnitName("player"))

    if isPartyChat and playerName and cleanSender == playerName then
        if lowerMsg == "flee" or string.match(lowerMsg, "^@%S+%s+flee$") then
            DungeonBots:SetFleeActive(true, "chat")
        elseif lowerMsg == "follow" or lowerMsg == "stay" then
            DungeonBots:SetFleeActive(false, "chat")
        end
        return
    end

    if cleanSender and cleanSender ~= "" and DungeonBots:FindPartyUnitByName(cleanSender, true) then
        if lowerMsg == "fleeing" then
            DungeonBots:SetFleeActive(true, "chat")
        end
    end
end

local function HandlePartyChanged(isEnteringWorld)
    if isEnteringWorld then
        if DB_Internal.ClearWhisperQueue then DB_Internal.ClearWhisperQueue() end
        if DB_Internal.ClearPendingJoinQueries then DB_Internal.ClearPendingJoinQueries() end
        if DB_Internal.ClearAllPendingQuestCounts then DB_Internal.ClearAllPendingQuestCounts() end
    end
    DungeonBots:ResolvePendingPartyBots()
    if DungeonBots.ConfirmSummonedBotAdded then
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                local pName = UnitName(unit)
                if pName and pName ~= "" and pName ~= UNKNOWNOBJECT and pName ~= "Unknown" then
                    DungeonBots:ConfirmSummonedBotAdded(pName)
                end
            end
        end
    end
    if GetNumPartyMembers and GetNumPartyMembers() == 0 and DungeonBots.SetFleeActive then
        DungeonBots:SetFleeActive(false, "party_empty")
    end
    DungeonBots:SyncPartyToHistory()
    if DungeonBots.OnResummonPartyActivity then
        DungeonBots:OnResummonPartyActivity()
    end
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
    if DungeonBots.UpdateDungeonAccessUI and DungeonBots.dungeonCheckPanel and DungeonBots.dungeonCheckPanel:IsShown() then
        if DungeonBots.RequestDungeonLockInfo then
            DungeonBots:RequestDungeonLockInfo(false)
        end
        DungeonBots:UpdateDungeonAccessUI()
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
                    local cleanedActive = DungeonBots:CleanSpecText(activeSpec)
                    if not DB_Internal.IsValidSpecEntry or DB_Internal.IsValidSpecEntry(cleanedActive) then
                        DungeonBotsDB.botActiveSpec[name] = cleanedActive
                    else
                        DungeonBotsDB.botActiveSpec[name] = nil
                    end
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
                            local isValidSpec = (not DB_Internal.IsValidSpecEntry) or DB_Internal.IsValidSpecEntry(cleanedSpec)
                            if isValidSpec and cleanedSpec ~= "" and not seen[lowerSpec] then
                                seen[lowerSpec] = true
                                table.insert(deduped, cleanedSpec)
                            end
                        end
                    end
                    if #deduped >= 2 then
                        DungeonBotsDB.botSpecs[botName] = deduped
                    else
                        DungeonBotsDB.botSpecs[botName] = nil
                    end
                end
            end
        end
        DungeonBots.botSpecs = DungeonBotsDB.botSpecs or {}
        if type(DungeonBotsDB.botSpecTriplets) ~= "table" then
            DungeonBotsDB.botSpecTriplets = {}
        end
        DungeonBots.botSpecTriplets = DungeonBotsDB.botSpecTriplets
        if DungeonBotsDB.whisperMuteMode == "auto" then
            DungeonBotsDB.whisperMuteMode = "all"
        end

        DungeonBotsDB.historyMigrated = true
        if DungeonBotsDB.uiTheme ~= "dark" and DungeonBotsDB.uiTheme ~= "gold" then
            DungeonBotsDB.uiTheme = "gold"
        end

        DungeonBots:SetupChatFilters()
        DungeonBots:SetupWIMCompatibility()
        DungeonBots:HookSendChatForTalk()

        if DB_Internal.ClearWhisperQueue then
            DB_Internal.ClearWhisperQueue()
        end
        if DB_Internal.ClearPendingJoinQueries then
            DB_Internal.ClearPendingJoinQueries()
        end
        if DB_Internal.ClearAllPendingQuestCounts then
            DB_Internal.ClearAllPendingQuestCounts()
        end

        DungeonBots:Print(string.format(L["ADDON_LOADED_FMT"], tostring(DungeonBots.VERSION or "1.0.0")))
        if DungeonBots.InitUI then
            DungeonBots:InitUI()
        end
        if DungeonBots.InitHUD then
            DungeonBots:InitHUD()
        end
        if DB_Internal.RefreshTheme then
            DB_Internal.RefreshTheme()
        end
        lastLfgQueueMode = (GetLFGMode and GetLFGMode()) or nil
        DungeonBots:SyncPartyToHistory()

    elseif event == "CHAT_MSG_SYSTEM" then
        local message = ...
        local fullBot = message and DB_Internal.ExtractInventoryFullBotName and DB_Internal.ExtractInventoryFullBotName(message, nil)
        if fullBot then
            NotifyBotInventoryFull(fullBot)
            return
        end
        if message and DB_Internal.ExtractAddedBotFromSystem and DungeonBots.ConfirmPartyBotIdentity then
            local addedBot = DB_Internal.ExtractAddedBotFromSystem(message)
            if addedBot and DungeonBots:IsBot(addedBot) ~= false then
                local inResummon = DungeonBots.pendingResummonVerify and DungeonBots.pendingResummonVerify[addedBot]
                if inResummon or DungeonBots:FindPartyUnitByName(addedBot, true) or DungeonBots:IsRecentBot(addedBot) then
                    if DungeonBots.ConfirmSummonedBotAdded then
                        DungeonBots:ConfirmSummonedBotAdded(addedBot)
                    end
                    DungeonBots:ConfirmPartyBotIdentity(addedBot, DungeonBots:IsRecentBot(addedBot) and true or false)
                    return
                end
            end
        end
        if message and DB_Internal.ExtractBusyBotFromSystem then
            local busyBot, busyKind = DB_Internal.ExtractBusyBotFromSystem(message)
            if busyBot then
                local partyUnit = DungeonBots:FindPartyUnitByName(busyBot, true)
                local hasRecentInform = DungeonBots.recentUserWhisperTargets
                    and (DungeonBots.recentUserWhisperTargets[busyBot] or 0) > NowTime()
                local isTrackedBot = (partyUnit ~= nil)
                    or DungeonBots:IsRecentBot(busyBot)
                    or (DungeonBots.HasPendingHistoryInvite and DungeonBots:HasPendingHistoryInvite(busyBot))
                    or (DungeonBots.IsHistoryBotLoading and DungeonBots:IsHistoryBotLoading(busyBot))
                    or (DungeonBots.GetExternalBotBusyInfo and DungeonBots:GetExternalBotBusyInfo(busyBot) ~= nil)
                    or DungeonBots:ShouldTreatAsBot(busyBot)
                    or hasRecentInform

                if busyKind == "not_in_instance" then
                    if isTrackedBot then
                        if DungeonBots.NotifyBotInstanceMismatch then
                            DungeonBots:NotifyBotInstanceMismatch(busyBot, nil)
                        end
                        if DungeonBots.RequestBotWhoCheck then
                            DungeonBots:RequestBotWhoCheck(busyBot, "not_in_instance")
                        end
                    end
                elseif not partyUnit and busyKind == "already_in_group" then
                    if isTrackedBot then
                        local cachedWho = DungeonBots.botWhoInfo and DungeonBots.botWhoInfo[busyBot]
                        local cachedOwner = cachedWho and cachedWho.playingWith or nil
                        local cachedZone = cachedWho and cachedWho.zone or nil
                        if DungeonBots.NotifyExternalBotBusy then
                            DungeonBots:NotifyExternalBotBusy(busyBot, cachedOwner, "already_in_group", true, cachedZone)
                        end
                    end
                elseif not partyUnit and busyKind == "already_logged_in" then
                    if DungeonBots.RequestBotWhoCheck then
                        DungeonBots:RequestBotWhoCheck(busyBot, "already_logged_in")
                    end
                    -- Dar margen a 'who' antes de intentar invitar por si pertenece a otro jugador
                    if (DungeonBots:IsRecentBot(busyBot) or (DungeonBots.HasPendingHistoryInvite and DungeonBots:HasPendingHistoryInvite(busyBot)))
                        and DungeonBots.SchedulePartyInviteRetry then
                        DungeonBots:SchedulePartyInviteRetry(busyBot, 1.0, 1)
                    end
                end
            end
        end

    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local message, target = ...
        local cleanTarget = NormalizePlayerName(target)
        if cleanTarget and cleanTarget ~= "" and not DungeonBots:FindPartyUnitByName(cleanTarget, true) then
            local isTrackedBot = DungeonBots:ShouldTreatAsBot(cleanTarget)
                or (DungeonBots.HasPendingHistoryInvite and DungeonBots:HasPendingHistoryInvite(cleanTarget))
                or (DungeonBots.GetExternalBotBusyInfo and DungeonBots:GetExternalBotBusyInfo(cleanTarget) ~= nil)
            if isTrackedBot then
                DungeonBots.recentUserWhisperTargets = DungeonBots.recentUserWhisperTargets or {}
                DungeonBots.recentUserWhisperTargets[cleanTarget] = NowTime() + 10
            end
        end

    elseif event == "CHAT_MSG_WHISPER" then
        local message, sender = ...
        if not sender then return end
        local cleanSender = NormalizePlayerName(sender)
        local playerName = UnitName and NormalizePlayerName(UnitName("player"))
        if not cleanSender or cleanSender == "" or cleanSender == playerName then
            return
        end

        local fullBot = DB_Internal.ExtractInventoryFullBotName and DB_Internal.ExtractInventoryFullBotName(message, cleanSender)
        if fullBot then
            NotifyBotInventoryFull(fullBot)
            return
        end

        if not DungeonBots:FindPartyUnitByName(cleanSender, true) and DB_Internal.ExtractBusyBotOwnerFromWhisper then
            local busyOwner, isBusyWhisper = DB_Internal.ExtractBusyBotOwnerFromWhisper(message)
            local isSelfOwner = (busyOwner and playerName and busyOwner == playerName)
            if isBusyWhisper and not isSelfOwner then
                if DungeonBots.NotifyExternalBotBusy then
                    DungeonBots:NotifyExternalBotBusy(cleanSender, busyOwner, "whisper", true)
                end
                if not busyOwner and DungeonBots.RequestBotWhoCheck then
                    DungeonBots:RequestBotWhoCheck(cleanSender, "busy_owner_lookup")
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

        local whoInfo = DB_Internal.ParseWhoWhisper and DB_Internal.ParseWhoWhisper(message) or nil
        local whoOtherOwner = false
        if whoInfo then
            whoInfo.updatedAt = NowTime()
            DungeonBots.botWhoInfo = DungeonBots.botWhoInfo or {}
            DungeonBots.botWhoInfo[cleanSender] = whoInfo
            whoOtherOwner = (whoInfo.playingWith and whoInfo.playingWith ~= "" and playerName and whoInfo.playingWith ~= playerName) and true or false

            local pendingWho = DungeonBots.pendingWhoCheck and DungeonBots.pendingWhoCheck[cleanSender]
            if pendingWho then
                DungeonBots.pendingWhoCheck[cleanSender] = nil
                if whoOtherOwner and not inParty then
                    if DungeonBots.NotifyExternalBotBusy then
                        DungeonBots:NotifyExternalBotBusy(cleanSender, whoInfo.playingWith, "who", true, whoInfo.zone)
                    end
                    if DungeonBots.OnWhisperReceived then
                        DungeonBots:OnWhisperReceived(cleanSender, message)
                    end
                    return
                elseif pendingWho.reason == "not_in_instance" then
                    if DungeonBots.NotifyBotInstanceMismatch then
                        DungeonBots:NotifyBotInstanceMismatch(cleanSender, whoInfo)
                    end
                elseif pendingWho.reason == "already_logged_in" or pendingWho.reason == "already_in_group" then
                    if DungeonBots.busyExternalBots then
                        DungeonBots.busyExternalBots[cleanSender] = nil
                    end
                    if not inParty and DungeonBots.SchedulePartyInviteRetry then
                        DungeonBots:SchedulePartyInviteRetry(cleanSender, 0.05, 1)
                    end
                elseif pendingWho.reason == "invite_failed" then
                    if whoInfo.playingWith and playerName and whoInfo.playingWith == playerName and not inParty then
                        if DungeonBots.NotifyBotAlreadyOnline then
                            DungeonBots:NotifyBotAlreadyOnline(cleanSender, whoInfo)
                        end
                        if DungeonBots.SchedulePartyInviteRetry then
                            DungeonBots:SchedulePartyInviteRetry(cleanSender, 0.4, 2)
                        end
                    elseif whoInfo.zone and whoInfo.zone ~= "" and not inParty then
                        DungeonBots:Warn(string.format(L["JOIN_FAIL_ZONE_FMT"], cleanSender, whoInfo.zone) .. ".")
                    end
                elseif pendingWho.reason == "busy_owner_lookup" and not inParty and not whoOtherOwner then
                    if DungeonBots.busyExternalBots then
                        DungeonBots.busyExternalBots[cleanSender] = nil
                    end
                    if DungeonBots.NotifyBotAlreadyOnline then
                        DungeonBots:NotifyBotAlreadyOnline(cleanSender, whoInfo)
                    end
                end
            elseif whoOtherOwner and not inParty then
                if DungeonBots.NotifyExternalBotBusy then
                    DungeonBots:NotifyExternalBotBusy(cleanSender, whoInfo.playingWith, "who", false, whoInfo.zone)
                end
            end
        end

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
        local handledInventory = false
        if not handledQuestSummary and DB_Internal.ParseInventoryCaptureWhisper then
            handledInventory = DB_Internal.ParseInventoryCaptureWhisper(cleanSender, message) and true or false
        end
        local handledSpells = false
        if not handledQuestSummary and DB_Internal.ParseSpellsCaptureWhisper then
            handledSpells = DB_Internal.ParseSpellsCaptureWhisper(cleanSender, message) and true or false
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
        local foundSpecList, detectedActiveSpec, specErrorReason, isSwitchConfirmation = false, nil, nil, false
        local skipTalentParse = handledQuestShare or handledQuestSummary or handledInventory or handledSpells or (parsedStats ~= nil)
        if not skipTalentParse and DB_Internal.ParseTalentWhisper then
            foundSpecList, detectedActiveSpec, specErrorReason, isSwitchConfirmation = DB_Internal.ParseTalentWhisper(cleanSender, message)
        end
        local queryStates = DB_Internal.queryStates
        local qState = queryStates and queryStates[cleanSender]
        local pendingSwitches = DB_Internal.pendingSpecSwitches
        local pendingSwitch = pendingSwitches and pendingSwitches[cleanSender]

        if specErrorReason and pendingSwitch then
            pendingSwitches[cleanSender] = nil
            local rollbackSpec = pendingSwitch.prevSpec
            if DungeonBotsDB then
                DungeonBotsDB.botActiveSpec = DungeonBotsDB.botActiveSpec or {}
                DungeonBotsDB.botActiveSpec[cleanSender] = rollbackSpec
            end
            DungeonBots:RecordBotHistory(cleanSender, nil, rollbackSpec or "", nil)
            if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
                DungeonBots:UpdateHistoryUI()
            end
            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
            if DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() and DungeonBots.spellsFrame.currentBot == cleanSender then
                DungeonBots:UpdateSpellsDialog(cleanSender)
            end
            DungeonBots:Warn(string.format(L["SPEC_CHANGE_FAIL_FMT"], cleanSender, specErrorReason))
            if not (DungeonBots.botSpecListFetched and DungeonBots.botSpecListFetched[cleanSender]) and DungeonBots.QueryBotSpecs then
                DungeonBots:QueryBotSpecs(cleanSender, false)
            end
            detectedActiveSpec = nil
        end

        if foundSpecList and DungeonBotsDB then
            DungeonBotsDB.botSpecs = DungeonBotsDB.botSpecs or {}
            DungeonBotsDB.botSpecs[cleanSender] = DungeonBots.botSpecs[cleanSender]
            DungeonBotsDB.botSpecTriplets = DungeonBotsDB.botSpecTriplets or {}
            DungeonBotsDB.botSpecTriplets[cleanSender] = DungeonBots.botSpecTriplets[cleanSender]
            if qState then
                qState.gotSpecList = true
            end
            DungeonBots:RegisterBot(cleanSender, true)
            DungeonBots:RecordBotHistory(cleanSender)

            -- Si 'talents' llegó antes que 'talents spec list', refinar con las ramas reales recién recibidas
            if not detectedActiveSpec and not pendingSwitch then
                local refined = nil
                local lastTriplet = DungeonBots.lastDetectedTriplet and DungeonBots.lastDetectedTriplet[cleanSender]
                if lastTriplet and DungeonBots.botSpecTriplets[cleanSender] and DungeonBots.botSpecTriplets[cleanSender][lastTriplet] and DB_Internal.ResolveTripletToSpec then
                    local tp1, tp2, tp3 = string.match(lastTriplet, "^(%d+)%-(%d+)%-(%d+)$")
                    if tp1 and tp2 and tp3 then
                        refined = DB_Internal.ResolveTripletToSpec(cleanSender, tp1, tp2, tp3)
                    end
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

        if pendingSwitch then
            if isSwitchConfirmation then
                pendingSwitch.gotSwitchConfirm = true
            end
            if detectedActiveSpec and detectedActiveSpec ~= "" then
                local candSpec = DungeonBots:CanonicalizeSpec(cleanSender, detectedActiveSpec)
                local matchesTarget = (string.lower(candSpec) == string.lower(pendingSwitch.targetSpec or ""))
                if matchesTarget then
                    pendingSwitches[cleanSender] = nil
                    local displaySpec = DungeonBots.LocalizeSpecText and DungeonBots:LocalizeSpecText(candSpec) or candSpec
                    DungeonBots:Print(string.format(L["SPEC_CHANGED_FMT"], cleanSender, displaySpec))
                elseif not pendingSwitch.verifySent and not pendingSwitch.gotSwitchConfirm and (NowTime() - (pendingSwitch.sentAt or 0)) < 0.85 then
                    detectedActiveSpec = nil
                elseif pendingSwitch.verifySent then
                    pendingSwitches[cleanSender] = nil
                    local displayActual = DungeonBots.LocalizeSpecText and DungeonBots:LocalizeSpecText(candSpec) or candSpec
                    DungeonBots:Warn(string.format(L["SPEC_UNCHANGED_FMT"], cleanSender, displayActual))
                    if not (DungeonBots.botSpecListFetched and DungeonBots.botSpecListFetched[cleanSender]) and DungeonBots.QueryBotSpecs then
                        DungeonBots:QueryBotSpecs(cleanSender, false)
                    end
                end
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
            if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
                DungeonBots:UpdateHistoryUI()
            end
            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
            if DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() and DungeonBots.spellsFrame.currentBot == cleanSender then
                DungeonBots:UpdateSpellsDialog(cleanSender)
            end
        end

        local isBotResponse = (foundSpecList or detectedActiveSpec or specErrorReason or isSwitchConfirmation or isBotText or handledQuestSummary or (parsedStats ~= nil)) and true or false
        if isBotResponse then
            DungeonBots.confirmedBots[cleanSender] = true
            DungeonBots:RegisterBot(cleanSender, true)
            DungeonBots:RecordBotHistory(cleanSender)
            if DungeonBots:HasPendingScan(cleanSender) then
                DungeonBots.pendingScan[cleanSender] = nil
                DungeonBots:Print(string.format(L["BOT_CONFIRMED_FMT"], cleanSender))
            end
            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
        end

        -- Auto-invite para bots recién invocados o bots del historial con respuesta de bot/addclass pendiente
        local isExternallyBusy = (whoOtherOwner == true)
            or (DungeonBots.GetExternalBotBusyInfo and (DungeonBots:GetExternalBotBusyInfo(cleanSender) ~= nil))
        if not inParty and not isExternallyBusy and isKnownOrHistory
            and not DungeonBots:IsRecentBot(cleanSender)
            and DungeonBots:HasPendingClassSummon() then
            if DungeonBots:ConsumePendingClassSummon() then
                DungeonBots:MarkRecentBot(cleanSender, 120)
            end
        end

        local isHistoryManaged = (DungeonBots.IsHistoryBotLoading and DungeonBots:IsHistoryBotLoading(cleanSender))
            or (DungeonBots.HasPendingHistoryInvite and DungeonBots:HasPendingHistoryInvite(cleanSender))
        if isHistoryManaged and not inParty and not isExternallyBusy
            and not (DungeonBots.pendingWhoCheck and DungeonBots.pendingWhoCheck[cleanSender])
            and (DungeonBots.recentInvites[cleanSender] or 0) <= NowTime()
            and DungeonBots.SchedulePartyInviteRetry then
            DungeonBots:SchedulePartyInviteRetry(cleanSender, 0.05, 2)
        end
        local shouldAutoInvite = (not isExternallyBusy) and (not isHistoryManaged) and (DungeonBots:IsRecentBot(cleanSender) or (isKnownOrHistory and isBotResponse))
        if shouldAutoInvite and not inParty then
            if DungeonBots:CanInviteToParty() then
                if (DungeonBots.recentInvites[cleanSender] or 0) <= NowTime() then
                    DungeonBots.recentInvites[cleanSender] = NowTime() + 1.2
                    DungeonBots:RecordBotHistory(cleanSender)
                    InviteUnit(cleanSender)
                    DungeonBots:Print(string.format(L["AUTO_INVITE_BOT_FMT"], cleanSender))
                end
                if DungeonBots.SchedulePartyInviteRetry then
                    DungeonBots:SchedulePartyInviteRetry(cleanSender, 2.0, 3)
                end
            elseif DungeonBots.WarnCannotAutoInvite then
                DungeonBots:WarnCannotAutoInvite(cleanSender)
            end
        end

        -- Guardar log de último susurro para la pestaña de bots
        if inParty then
            UpdateFleeStateFromMessage(cleanSender, message, false)
        end
        if DungeonBots.OnWhisperReceived then
            DungeonBots:OnWhisperReceived(cleanSender, message)
        end

    elseif event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_SAY" then
        local message, sender = ...
        if event ~= "CHAT_MSG_SAY" then
            UpdateFleeStateFromMessage(NormalizePlayerName(sender), message, true)
        end
        local fullBot = message and DB_Internal.ExtractInventoryFullBotName and DB_Internal.ExtractInventoryFullBotName(message, sender)
        if fullBot then
            NotifyBotInventoryFull(fullBot)
        end

    elseif event == "PARTY_MEMBERS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        HandlePartyChanged(event == "PLAYER_ENTERING_WORLD")

    elseif event == "LFG_LOCK_INFO_RECEIVED" then
        DungeonBots.lfgLockInfoReceived = true
        if DungeonBots.UpdateDungeonAccessUI then
            DungeonBots:UpdateDungeonAccessUI()
        end

    elseif event == "LFG_UPDATE" then
        local newMode = (GetLFGMode and GetLFGMode()) or nil
        local prevMode = lastLfgQueueMode
        lastLfgQueueMode = newMode
        if newMode == "queued" and prevMode ~= "queued" then
            local inInstance, instanceType = IsInInstance and IsInInstance()
            local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
            if inInstance and instanceType == "party" and numParty > 0 then
                DungeonBots:Warn(L["LFG_BACKFILL_NAME_HIST_ONLY"])
            end
        end

    elseif event == "UNIT_NAME_UPDATE" then
        local unit = ...
        if unit and string.match(unit, "^party%d$") then
            HandlePartyChanged(false)
        end

    elseif event == "UNIT_CONNECTION" then
        local unit, isConnected = ...
        if unit and string.match(unit, "^party%d$") and isConnected then
            if DungeonBots.OnResummonPartyActivity then
                DungeonBots:OnResummonPartyActivity()
            end
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
            DungeonBots:Print(L["HUD_POS_RESTORED"])
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
