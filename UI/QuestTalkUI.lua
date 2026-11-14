-- =========================================================================
-- DungeonBots_QuestTalkUI.lua: Diálogos Interactivos de Misiones y Talk
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal
local L = DungeonBots.L or {}

local function ApplyDarkBackdrop(frame, edgeSize)
    return DB_Internal.ApplyDarkBackdrop(frame, edgeSize)
end

local function ApplyHeaderBackdrop(frame)
    return DB_Internal.ApplyHeaderBackdrop(frame)
end

local function ApplyInsetPanelBackdrop(frame, edgeSize)
    if DB_Internal.ApplyInsetPanelBackdrop then
        return DB_Internal.ApplyInsetPanelBackdrop(frame, edgeSize)
    else
        return ApplyDarkBackdrop(frame, edgeSize)
    end
end

local function ApplyBlizzardGoldWindow(frame, edgeSize)
    if DB_Internal.ApplyBlizzardGoldWindow then
        return DB_Internal.ApplyBlizzardGoldWindow(frame, edgeSize)
    end
    return ApplyDarkBackdrop(frame, edgeSize)
end

local function ApplyBlizzardStonePanel(frame, r, g, b, edgeSize, bgAlpha)
    if DB_Internal.ApplyBlizzardStonePanel then
        return DB_Internal.ApplyBlizzardStonePanel(frame, r, g, b, edgeSize, bgAlpha)
    end
    return ApplyInsetPanelBackdrop(frame, edgeSize)
end

local function SetThemedBorder(frame, isHover)
    local p = DB_Internal.GetThemePalette and DB_Internal.GetThemePalette()
    local c = p and (isHover and p.hoverBorder or p.insetBorder) or (isHover and { 1.0, 0.82, 0.28, 1.0 } or { 0.54, 0.44, 0.26, 0.85 })
    frame:SetBackdropBorderColor(c[1], c[2], c[3], c[4])
end

local function CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
    return DB_Internal.CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
end

local function SafeShowLinkTooltip(owner, linkRef, displayLink, title, rawLine)
    return DB_Internal.SafeShowLinkTooltip(owner, linkRef, displayLink, title, rawLine)
end

StaticPopupDialogs["DUNGEONBOTS_DROP_BOT_QUEST"] = {
    text = L["QUEST_DROP_CONFIRM"],
    button1 = L["BTN_ABANDON"],
    button2 = L["BTN_CANCEL"],
    OnAccept = function(self, data)
        if data and data.botName and data.questEntry and DungeonBots.DropBotQuest then
            DungeonBots:DropBotQuest(data.botName, data.questEntry, data.fromTalkDialog)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
if DB_Internal.RegisterLocaleRefresh then
    DB_Internal.RegisterLocaleRefresh(function()
        StaticPopupDialogs["DUNGEONBOTS_DROP_BOT_QUEST"].text = L["QUEST_DROP_CONFIRM"]
        StaticPopupDialogs["DUNGEONBOTS_DROP_BOT_QUEST"].button1 = L["BTN_ABANDON"]
        StaticPopupDialogs["DUNGEONBOTS_DROP_BOT_QUEST"].button2 = L["BTN_CANCEL"]
    end)
end

local function ConfirmDropBotQuest(botName, questEntry, fromTalkDialog)
    if not botName or not questEntry then return end
    local rawDisplay = questEntry.displayLink or questEntry.safeLink
        or ("|cffffff00[" .. (questEntry.title or questEntry.rawTitle or L["QUEST_DEFAULT"]) .. "]|r")
    local questDisplay = DungeonBots.LocalizeHyperlinksInText
        and DungeonBots:LocalizeHyperlinksInText(rawDisplay)
        or rawDisplay
    PlaySound("igMainMenuOptionCheckBoxOn")
    StaticPopup_Show("DUNGEONBOTS_DROP_BOT_QUEST", botName, questDisplay, {
        botName = botName,
        questEntry = questEntry,
        fromTalkDialog = fromTalkDialog,
    })
end

-- =========================================================================
-- VENTANA DE DIÁLOGO: MISIONES DEL BOT (quests all / drop)
-- =========================================================================
local questRows = {}

local function CreateQuestRow(parent, idx)
    local row = CreateFrame("Frame", "DungeonBots_QuestRow_" .. idx, parent)
    row:SetSize(486, 36)
    row:SetPoint("TOPLEFT", 0, -((idx - 1) * 40))
    ApplyInsetPanelBackdrop(row, 8)
    if DB_Internal.AddGoldWarmFill then
        DB_Internal.AddGoldWarmFill(row, "BORDER", "warmFillSlot")
    end

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local titleBtn = CreateFrame("Button", nil, row)
    titleBtn:SetPoint("TOPLEFT", row, "TOPLEFT", 32, -2)
    titleBtn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -208, 2)
    row.titleBtn = titleBtn

    local titleText = titleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("TOPLEFT", 2, -4)
    titleText:SetPoint("TOPRIGHT", -2, -4)
    titleText:SetJustifyH("LEFT")
    titleText:SetWordWrap(false)
    row.titleText = titleText

    local subText = titleBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)
    subText:SetPoint("TOPRIGHT", titleText, "BOTTOMRIGHT", 0, -2)
    subText:SetJustifyH("LEFT")
    subText:SetWordWrap(false)
    row.subText = subText

    local dropBtn = CreateRedIconButton(row, 96, 22, L["BTN_ABANDON"], "Interface\\Icons\\Spell_ChargeNegative")
    dropBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.dropBtn = dropBtn

    local shareBtn = CreateRedIconButton(row, 96, 22, L["BTN_SHARE"], "Interface\\Icons\\INV_Misc_GroupLooking")
    shareBtn:SetPoint("RIGHT", dropBtn, "LEFT", -6, 0)
    row.shareBtn = shareBtn

    questRows[idx] = row
    return row
end

function DungeonBots:BuildQuestDialog()
    if DungeonBots.questFrame then return end

    local qf = CreateFrame("Frame", "DungeonBots_QuestFrame", UIParent)
    qf:SetSize(540, 420)
    qf:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    qf:SetFrameStrata("DIALOG")
    qf:SetFrameLevel(28)
    qf:SetToplevel(true)
    qf:SetMovable(true)
    qf:EnableMouse(true)
    qf:SetClampedToScreen(true)
    qf:RegisterForDrag("LeftButton")
    qf:SetScript("OnDragStart", qf.StartMoving)
    qf:SetScript("OnDragStop", qf.StopMovingOrSizing)
    qf:Hide()
    ApplyBlizzardGoldWindow(qf, 16)

    table.insert(UISpecialFrames, "DungeonBots_QuestFrame")

    local header = CreateFrame("Frame", nil, qf)
    header:SetPoint("TOPLEFT", qf, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", qf, "TOPRIGHT", -6, -6)
    header:SetHeight(30)
    ApplyHeaderBackdrop(header)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 10, 0)
    title:SetText(L["QUEST_WIN_DEFAULT"])
    qf.title = title

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        qf:Hide()
    end)

    local statusLabel = qf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusLabel:SetPoint("TOPLEFT", 14, -44)
    statusLabel:SetText(L["QUEST_ACTIVE_ZERO"])
    qf.statusLabel = statusLabel

    local refreshBtn = CreateFrame("Button", nil, qf, "UIPanelButtonTemplate")
    refreshBtn:SetSize(96, 22)
    refreshBtn:SetPoint("TOPRIGHT", qf, "TOPRIGHT", -14, -40)
    refreshBtn:SetText(L["BTN_REFRESH"])
    refreshBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if qf.currentBot then
            local curData = DungeonBots.questDialogData and DungeonBots.questDialogData[qf.currentBot]
            if curData and curData.loading then
                return
            end
            DungeonBots:QueryQuests(qf.currentBot, true, false)
        end
    end)
    qf.refreshBtn = refreshBtn

    local scrollBg = CreateFrame("Frame", nil, qf)
    scrollBg:SetPoint("TOPLEFT", qf, "TOPLEFT", 10, -68)
    scrollBg:SetPoint("BOTTOMRIGHT", qf, "BOTTOMRIGHT", -10, 96)
    ApplyBlizzardStonePanel(scrollBg, 0.66, 0.54, 0.30, 10, 0.30)

    local scrollFrame = CreateFrame("ScrollFrame", "DungeonBots_QuestScrollFrame", scrollBg, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", scrollBg, "TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", scrollBg, "BOTTOMRIGHT", -26, 6)

    local scrollChild = CreateFrame("Frame", "DungeonBots_QuestScrollChild", scrollFrame)
    scrollChild:SetSize(486, 1)
    scrollFrame:SetScrollChild(scrollChild)
    qf.scrollChild = scrollChild

    local emptyLabel = scrollBg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyLabel:SetPoint("CENTER", scrollBg, "CENTER", -8, 0)
    emptyLabel:SetWidth(420)
    emptyLabel:SetText(L["QUEST_NONE_ACTIVE"])
    qf.emptyLabel = emptyLabel

    -- Contenedor de Comprobación de Mazmorras (Foso de Saron y Cámaras de Reflexión)
    local checkPanel = CreateFrame("Frame", "DungeonBots_QuestDungeonCheckPanel", qf)
    checkPanel:SetPoint("BOTTOMLEFT", qf, "BOTTOMLEFT", 10, 40)
    checkPanel:SetPoint("BOTTOMRIGHT", qf, "BOTTOMRIGHT", -10, 40)
    checkPanel:SetHeight(48)
    DungeonBots.dungeonCheckPanel = checkPanel

    DungeonBots.dungeonButtons = {}
    local frozenHallsData = DungeonBots.FROZEN_HALLS_DATA or {
        {
            key = "foso",
            name = L["DUNGEON_PIT_NAME"],
            shortName = L["DUNGEON_PIT_NAME"],
            icon = "Interface\\Icons\\achievement_dungeon_icecrown_pitofsaron",
            keywords = { "saron", "foso", "pit of saron" },
            excludeKeywords = { "forja", "forge", "reflex", "reflection" },
            prereq = L["DUNGEON_FOS_NAME"],
            fallbackIDs = { 253, 254 },
        },
        {
            key = "camaras",
            name = L["DUNGEON_HOR_NAME"],
            shortName = L["DUNGEON_HOR_NAME"],
            icon = "Interface\\Icons\\achievement_dungeon_icecrown_hallsofreflection",
            keywords = { "reflexi", "reflection" },
            excludeKeywords = { "forja", "forge", "saron", "foso" },
            prereq = L["DUNGEON_PIT_NAME"],
            fallbackIDs = { 255, 256 },
        },
    }

    local prevDungeonBtn = nil
    for _, def in ipairs(frozenHallsData) do
        local btn = CreateFrame("Button", "DungeonBots_QuestDungeonBtn_" .. def.key, checkPanel)
        btn:SetSize(256, 46)
        if prevDungeonBtn then
            btn:SetPoint("RIGHT", checkPanel, "RIGHT", 0, 0)
        else
            btn:SetPoint("LEFT", checkPanel, "LEFT", 0, 0)
        end
        ApplyInsetPanelBackdrop(btn, 8)
        if DB_Internal.AddGoldWarmFill then
            DB_Internal.AddGoldWarmFill(btn, "BORDER", "warmFillSlot")
        end

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(34, 34)
        icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
        icon:SetTexture(def.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        btn.icon = icon

        local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
        nameText:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(def.shortName)
        btn.nameText = nameText

        local statusText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        local sFontPath, _, sFontFlags = statusText:GetFont()
        if sFontPath then
            statusText:SetFont(sFontPath, 11, sFontFlags)
        end
        statusText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2)
        statusText:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
        statusText:SetJustifyH("LEFT")
        statusText:SetText("|cffaaaaaa...|r")
        btn.statusText = statusText

        local function PopulateDungeonTooltip(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(self.dungeonName or def.name, 1, 0.82, 0)

            if self.canEnter == nil and self.botCanEnter == nil and not self.botNotInParty then
                GameTooltip:AddLine(L["DUNG_TIP_STATUS_WAIT"], 1, 1, 1)
                GameTooltip:AddLine(L["DUNG_TIP_CLICK_QUERY"], 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
                return
            end

            local activeBot = (DungeonBots.questFrame and DungeonBots.questFrame.currentBot) or self.currentBot
            if activeBot and activeBot ~= "" then
                if self.botCanEnter == true then
                    GameTooltip:AddLine(string.format(L["DUNG_TIP_BOT_OK"], activeBot), 1, 1, 1)
                elseif self.botCanEnter == false then
                    GameTooltip:AddLine(string.format(L["DUNG_TIP_BOT_MISS"], activeBot), 1, 1, 1)
                elseif self.botNotInParty then
                    GameTooltip:AddLine(string.format(L["DUNG_TIP_BOT_NOTIN"], activeBot), 1, 1, 1)
                end
            end

            local prereqName = self.prereq or def.prereq or L["DUNG_PREV_FALLBACK"]
            GameTooltip:AddLine(string.format(L["DUNG_REQ_CHAIN_FMT"], prereqName), 0.85, 0.85, 0.85, true)

            if self.memberStatuses and #self.memberStatuses > 0 then
                GameTooltip:AddLine(" ", 1, 1, 1)
                GameTooltip:AddLine(L["DUNG_BOT_STATUS_HDR"], 1, 0.82, 0)
                local curKey = activeBot and string.lower(string.match(activeBot, "^([^%-]+)") or activeBot) or ""
                for _, m in ipairs(self.memberStatuses) do
                    local mShort = string.match(m.name or "", "^([^%-]+)") or (m.name or "Bot")
                    local mKey = string.lower(mShort)
                    local nameLabel
                    if curKey ~= "" and mKey == curKey then
                        nameLabel = "|cffffd200" .. mShort .. "|r " .. L["DUNG_CUR_TAG"]
                    else
                        nameLabel = "|cffffd200" .. mShort .. "|r"
                    end
                    local statusStr = m.canEnter and L["DUNG_CAN_ENTER"] or L["DUNG_MISSING_Q"]
                    GameTooltip:AddLine(string.format(L["DUNG_LINE_FMT"], nameLabel, statusStr), 1, 1, 1, true)
                end
            else
                GameTooltip:AddLine(" ", 1, 1, 1)
                GameTooltip:AddLine(L["DUNG_NO_BOTS_IN_GRP"], 0.7, 0.7, 0.7)
            end

            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine(L["DUNG_CLICK_REFRESH"], 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end
        btn.RefreshTooltip = PopulateDungeonTooltip

        btn:SetScript("OnClick", function(self)
            PlaySound("igMainMenuOptionCheckBoxOn")
            if DungeonBots.RequestDungeonLockInfo then
                DungeonBots:RequestDungeonLockInfo(true)
            end
            if DungeonBots.UpdateDungeonAccessUI then
                DungeonBots:UpdateDungeonAccessUI()
            end
            PopulateDungeonTooltip(self)
        end)

        btn:SetScript("OnEnter", function(self)
            SetThemedBorder(self, true)
            PopulateDungeonTooltip(self)
        end)
        btn:SetScript("OnLeave", function(self)
            SetThemedBorder(self, false)
            GameTooltip:Hide()
        end)

        DungeonBots.dungeonButtons[def.key] = btn
        prevDungeonBtn = btn
    end

    local nextBotBtn = CreateFrame("Button", nil, qf, "UIPanelButtonTemplate")
    nextBotBtn:SetSize(120, 24)
    nextBotBtn:SetPoint("BOTTOMLEFT", qf, "BOTTOMLEFT", 12, 10)
    nextBotBtn:SetText(L["BTN_NEXT_BOT"])
    nextBotBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if DungeonBots.CycleNextQuestBot then
            DungeonBots:CycleNextQuestBot(qf.currentBot)
        end
    end)
    nextBotBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["BTN_NEXT_BOT"], 1, 0.85, 0.2)
        if DungeonBots.GetTalkBotCycleInfo then
            local curIdx, total = DungeonBots:GetTalkBotCycleInfo(qf.currentBot)
            if total >= 2 then
                local posLabel = (curIdx > 0) and (curIdx .. "/" .. total) or ("0/" .. total)
                GameTooltip:AddLine(string.format(L["QUEST_NEXT_BOT_TIP"], posLabel), 0.85, 0.85, 0.85, true)
            else
                GameTooltip:AddLine(L["QUEST_NEED_2_BOTS"], 0.8, 0.8, 0.8, true)
            end
        end
        GameTooltip:Show()
    end)
    nextBotBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    qf.nextBotBtn = nextBotBtn

    local botCycleLabel = qf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    botCycleLabel:SetPoint("LEFT", nextBotBtn, "RIGHT", 8, 0)
    botCycleLabel:SetWidth(42)
    botCycleLabel:SetJustifyH("LEFT")
    botCycleLabel:SetText("|cff888888(0/0)|r")
    qf.botCycleLabel = botCycleLabel

    local closeFooterBtn = CreateFrame("Button", nil, qf, "UIPanelButtonTemplate")
    closeFooterBtn:SetSize(90, 24)
    closeFooterBtn:SetPoint("BOTTOMRIGHT", qf, "BOTTOMRIGHT", -12, 10)
    closeFooterBtn:SetText(L["BTN_CLOSE"])
    closeFooterBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        qf:Hide()
    end)

    DungeonBots.questFrame = qf
    if DB_Internal.RegisterSubModalDimmer then
        DB_Internal.RegisterSubModalDimmer(qf)
    end
end

function DungeonBots:UpdateQuestDialog(botName)
    if not DungeonBots.questFrame then return end
    local qf = DungeonBots.questFrame
    local targetBot = botName or qf.currentBot
    if not targetBot then return end
    if qf.currentBot and botName and qf.currentBot ~= botName then
        return
    end
    qf.currentBot = targetBot
    qf.title:SetText(string.format(L["QUEST_WIN_FMT"], targetBot))

    if qf.nextBotBtn and qf.botCycleLabel and DungeonBots.GetTalkBotCycleInfo then
        local curIdx, total = DungeonBots:GetTalkBotCycleInfo(targetBot)
        if total > 0 and curIdx > 0 then
            qf.botCycleLabel:SetText(string.format("|cff888888(%d/%d)|r", curIdx, total))
        else
            qf.botCycleLabel:SetText("|cff888888(0/0)|r")
        end
        if total >= 2 then
            qf.nextBotBtn:Enable()
        else
            qf.nextBotBtn:Disable()
        end
    end

    local data = DungeonBots.questDialogData and DungeonBots.questDialogData[targetBot]
    local quests = (data and data.quests) or {}

    if qf.refreshBtn then
        if data and data.loading then
            qf.refreshBtn:Disable()
            qf.refreshBtn:SetText(L["BTN_QUERYING"])
        else
            qf.refreshBtn:Enable()
            qf.refreshBtn:SetText(L["BTN_REFRESH"])
        end
    end

    if data and data.loading and not data.done and #quests == 0 then
        qf.statusLabel:SetText(L["QUEST_QUERY_STATUS"])
        qf.emptyLabel:SetText(string.format(L["QUEST_QUERY_WAIT_FMT"], targetBot))
        qf.emptyLabel:Show()
    elseif #quests == 0 and data and data.timedOut then
        qf.statusLabel:SetText(string.format(L["QUEST_NO_RESP_TITLE"], targetBot))
        local baseMsg = string.format(L["QUEST_NO_RESP_BODY"], targetBot)
        qf.emptyLabel:SetText(DungeonBots.FormatNoResponseBody and DungeonBots:FormatNoResponseBody(baseMsg, targetBot) or baseMsg)
        qf.emptyLabel:Show()
    elseif #quests == 0 then
        qf.statusLabel:SetText(L["QUEST_ACTIVE_ZERO"])
        local baseEmptyMsg = L["QUEST_NONE_ACTIVE"]
        local hintText = (data and data.emptyHint and data.emptyHint ~= "")
            and ((DungeonBots.LocalizeServerHint and DungeonBots:LocalizeServerHint(data.emptyHint, "quests")) or data.emptyHint)
            or nil
        if hintText and hintText ~= "" and hintText ~= baseEmptyMsg then
            qf.emptyLabel:SetText(baseEmptyMsg .. "\n\n|cff888888(" .. hintText .. ")|r")
        else
            qf.emptyLabel:SetText(baseEmptyMsg)
        end
        qf.emptyLabel:Show()
    else
        if data and data.timedOut then
            qf.statusLabel:SetText(string.format(L["QUEST_ACTIVE_FMT"], #quests) .. L["QUEST_ACTIVE_STALE"])
        else
            qf.statusLabel:SetText(string.format(L["QUEST_ACTIVE_FMT"], #quests) .. L["QUEST_ACTIVE_HINT"])
        end
        qf.emptyLabel:Hide()
    end

    for i = #quests + 1, #questRows do
        questRows[i]:Hide()
    end

    for i, q in ipairs(quests) do
        local row = questRows[i] or CreateQuestRow(qf.scrollChild, i)
        row:Show()

        local lvlPrefix = (q.questLevel and q.questLevel ~= "") and ("|cff88aacc[" .. q.questLevel .. "]|r ") or ""
        row.titleText:SetText(lvlPrefix .. "|cffffff00" .. (q.title or L["QUEST_DEFAULT"]) .. "|r")

        local subStr = ""
        if q.statusText and q.statusText ~= "" then
            local lowerSt = string.lower(q.statusText)
            if (string.find(lowerSt, "complete") or string.find(lowerSt, "completa")) and not string.find(lowerSt, "incomplete") then
                subStr = "|cff34c759" .. q.statusText .. "|r"
            else
                subStr = "|cff9aa5b5" .. q.statusText .. "|r"
            end
        elseif q.questId then
            subStr = string.format(L["QUEST_ID_CLICK_FMT"], tostring(q.questId))
        else
            subStr = L["QUEST_CLICK_DETAIL"]
        end
        row.subText:SetText(subStr)

        row.titleBtn:SetScript("OnClick", function(self)
            PlaySound("igMainMenuOptionCheckBoxOn")
            local linkRef = q.questId and ("quest:" .. q.questId .. ":" .. (q.questLevel or "80")) or nil
            SafeShowLinkTooltip(self, linkRef, q.displayLink, q.title, q.rawLine)
        end)
        row.titleBtn:SetScript("OnEnter", function(self)
            SetThemedBorder(row, true)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(q.title or L["QUEST_DEFAULT"], 1, 0.85, 0.2)
            if q.statusText and q.statusText ~= "" then
                GameTooltip:AddLine(L["QUEST_STATUS_PREFIX"] .. q.statusText, 0.8, 0.9, 1.0, true)
            end
            if q.questId then
                GameTooltip:AddLine(L["QUEST_OPEN_DETAIL_TIP"], 0.3, 0.9, 0.5)
            end
            GameTooltip:Show()
        end)
        row.titleBtn:SetScript("OnLeave", function()
            SetThemedBorder(row, false)
            GameTooltip:Hide()
        end)

        local canShare = (q.safeLink ~= nil or q.rawDisplayLink ~= nil or q.questId ~= nil)
        row.shareBtn:Show()
        if canShare then
            row.shareBtn:Enable()
            row.shareBtn:SetAlpha(1.0)
        else
            row.shareBtn:Disable()
            row.shareBtn:SetAlpha(0.45)
        end
        row.shareBtn:SetScript("OnClick", function()
            DungeonBots:ShareBotQuest(targetBot, q)
        end)
        row.shareBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(L["QUEST_SHARE_TIP"], 0.9, 0.92, 0.95, true)
            GameTooltip:Show()
        end)
        row.shareBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row.dropBtn:Show()
        row.dropBtn:SetScript("OnClick", function()
            ConfirmDropBotQuest(targetBot, q, false)
        end)
        row.dropBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(L["QUEST_DROP_TIP"], 1, 0.4, 0.4, true)
            GameTooltip:Show()
        end)
        row.dropBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    qf.scrollChild:SetHeight(math.max(1, (#quests * 40) + 4))
end

function DungeonBots:OpenQuestDialog(botName)
    if not DungeonBots.questFrame then
        DungeonBots:BuildQuestDialog()
    end
    local qf = DungeonBots.questFrame
    local wasShown = qf:IsShown()
    qf.currentBot = botName
    DungeonBots:UpdateQuestDialog(botName)
    if not wasShown then
        qf:Show()
        if qf.Raise then
            pcall(qf.Raise, qf)
        end
        if DungeonBots.RequestDungeonLockInfo then
            DungeonBots:RequestDungeonLockInfo(false)
        end
    end
    if DungeonBots.UpdateDungeonAccessUI then
        DungeonBots:UpdateDungeonAccessUI()
    end
end

-- =========================================================================
-- VENTANA DE DIÁLOGO: INTERACCIÓN CON PNJ (talk)
-- =========================================================================
local talkActionRows = {}

local function CreateTalkActionRow(parent, idx)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(486, 26)
    row:SetPoint("TOPLEFT", 0, -((idx - 1) * 30))
    ApplyInsetPanelBackdrop(row, 6)

    local mainBtn = CreateFrame("Button", nil, row)
    mainBtn:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -2)
    mainBtn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 2)
    row.mainBtn = mainBtn

    local label = mainBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", 4, 0)
    label:SetPoint("RIGHT", -4, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    row.label = label

    local acceptBtn = CreateRedIconButton(row, 100, 20, L["BTN_ACCEPT"], "Interface\\Icons\\INV_Misc_Book_09")
    acceptBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    acceptBtn:Hide()
    row.acceptBtn = acceptBtn

    local shareBtn = CreateRedIconButton(row, 94, 20, L["BTN_SHARE"], "Interface\\Icons\\INV_Misc_GroupLooking")
    shareBtn:SetPoint("RIGHT", acceptBtn, "LEFT", -4, 0)
    shareBtn:Hide()
    row.shareBtn = shareBtn

    local statusTag = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusTag:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    statusTag:SetWidth(90)
    statusTag:SetJustifyH("RIGHT")
    statusTag:SetWordWrap(false)
    statusTag:Hide()
    row.statusTag = statusTag

    talkActionRows[idx] = row
    return row
end

function DungeonBots:BuildTalkDialog()
    if DungeonBots.talkFrame then return end

    local tf = CreateFrame("Frame", "DungeonBots_TalkFrame", UIParent)
    tf:SetSize(540, 360)
    tf:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    tf:SetFrameStrata("DIALOG")
    tf:SetFrameLevel(25)
    tf:SetToplevel(true)
    tf:SetMovable(true)
    tf:EnableMouse(true)
    tf:SetClampedToScreen(true)
    tf:RegisterForDrag("LeftButton")
    tf:SetScript("OnDragStart", tf.StartMoving)
    tf:SetScript("OnDragStop", tf.StopMovingOrSizing)
    tf:Hide()
    ApplyBlizzardGoldWindow(tf, 16)

    table.insert(UISpecialFrames, "DungeonBots_TalkFrame")

    local header = CreateFrame("Frame", nil, tf)
    header:SetPoint("TOPLEFT", tf, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", tf, "TOPRIGHT", -6, -6)
    header:SetHeight(30)
    ApplyHeaderBackdrop(header)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 10, 0)
    title:SetText(L["TALK_WIN_DEFAULT"])
    tf.title = title

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        tf:Hide()
    end)

    local requeryBtn = CreateFrame("Button", nil, tf, "UIPanelButtonTemplate")
    requeryBtn:SetSize(106, 22)
    requeryBtn:SetPoint("TOPRIGHT", tf, "TOPRIGHT", -12, -40)
    requeryBtn:SetText(L["BTN_REQUERY"])
    requeryBtn:SetScript("OnClick", function()
        if not tf.currentBot then return end
        if DungeonBots.IsTalkBusy and DungeonBots:IsTalkBusy(tf.currentBot) then
            return
        end
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:SendTalkCommand(tf.currentBot, "talk")
    end)
    tf.requeryBtn = requeryBtn

    local npcLabel = tf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    npcLabel:SetPoint("TOPLEFT", 14, -44)
    npcLabel:SetPoint("RIGHT", requeryBtn, "LEFT", -8, 0)
    npcLabel:SetJustifyH("LEFT")
    npcLabel:SetWordWrap(false)
    npcLabel:SetText(L["TALK_NPC_DEFAULT"])
    tf.npcLabel = npcLabel

    local optTitle = tf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    optTitle:SetPoint("TOPLEFT", tf, "TOPLEFT", 14, -68)
    optTitle:SetText(L["TALK_OPTIONS_HDR"])

    local optBg = CreateFrame("Frame", nil, tf)
    optBg:SetPoint("TOPLEFT", tf, "TOPLEFT", 10, -84)
    optBg:SetPoint("BOTTOMRIGHT", tf, "BOTTOMRIGHT", -10, 40)
    ApplyBlizzardStonePanel(optBg, 0.66, 0.54, 0.30, 10, 0.30)

    local optScroll = CreateFrame("ScrollFrame", "DungeonBots_TalkOptScroll", optBg, "UIPanelScrollFrameTemplate")
    optScroll:SetPoint("TOPLEFT", optBg, "TOPLEFT", 6, -6)
    optScroll:SetPoint("BOTTOMRIGHT", optBg, "BOTTOMRIGHT", -26, 6)

    local optChild = CreateFrame("Frame", "DungeonBots_TalkOptChild", optScroll)
    optChild:SetSize(486, 1)
    optScroll:SetScrollChild(optChild)
    tf.optChild = optChild

    local emptyOptLabel = optBg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyOptLabel:SetPoint("CENTER", optBg, "CENTER", -8, 0)
    emptyOptLabel:SetWidth(430)
    emptyOptLabel:SetText(L["TALK_WAIT_NPC"])
    tf.emptyOptLabel = emptyOptLabel

    local nextBotBtn = CreateFrame("Button", nil, tf, "UIPanelButtonTemplate")
    nextBotBtn:SetSize(122, 24)
    nextBotBtn:SetPoint("BOTTOMLEFT", tf, "BOTTOMLEFT", 12, 10)
    nextBotBtn:SetText(L["BTN_NEXT_BOT"])
    nextBotBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if DungeonBots.CycleNextTalkBot then
            DungeonBots:CycleNextTalkBot(tf.currentBot)
        end
    end)
    nextBotBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["BTN_NEXT_BOT"], 1, 0.85, 0.2)
        if DungeonBots.GetTalkBotCycleInfo then
            local curIdx, total = DungeonBots:GetTalkBotCycleInfo(tf.currentBot)
            if total >= 2 then
                local posLabel = (curIdx > 0) and (curIdx .. "/" .. total) or ("0/" .. total)
                GameTooltip:AddLine(string.format(L["TALK_NEXT_BOT_TIP"], posLabel), 0.8, 0.9, 1.0, true)
            else
                GameTooltip:AddLine(L["QUEST_NEED_2_BOTS"], 0.8, 0.8, 0.8, true)
            end
        end
        GameTooltip:Show()
    end)
    nextBotBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    tf.nextBotBtn = nextBotBtn

    local botCycleLabel = tf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    botCycleLabel:SetPoint("LEFT", nextBotBtn, "RIGHT", 8, 0)
    botCycleLabel:SetWidth(60)
    botCycleLabel:SetJustifyH("LEFT")
    botCycleLabel:SetWordWrap(false)
    botCycleLabel:SetText("")
    tf.botCycleLabel = botCycleLabel

    local questLogBtn = CreateFrame("Button", nil, tf, "UIPanelButtonTemplate")
    questLogBtn:SetSize(134, 24)
    questLogBtn:SetPoint("BOTTOMRIGHT", tf, "BOTTOMRIGHT", -108, 10)
    questLogBtn:SetText(L["TALK_QUEST_LOG_BTN"])
    questLogBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if tf.currentBot then
            DungeonBots:QueryQuests(tf.currentBot)
        end
    end)
    questLogBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["TALK_QUEST_LOG_TIP"], 1, 0.85, 0.2)
        if tf.currentBot then
            GameTooltip:AddLine(string.format(L["TALK_QUEST_LOG_FOR"], tf.currentBot), 0.8, 0.9, 1.0, true)
        else
            GameTooltip:AddLine(L["TALK_QUEST_LOG_SEL"], 0.8, 0.9, 1.0, true)
        end
        GameTooltip:Show()
    end)
    questLogBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local closeFooterBtn = CreateFrame("Button", nil, tf, "UIPanelButtonTemplate")
    closeFooterBtn:SetSize(90, 24)
    closeFooterBtn:SetPoint("BOTTOMRIGHT", tf, "BOTTOMRIGHT", -12, 10)
    closeFooterBtn:SetText(L["BTN_CLOSE"])
    closeFooterBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        tf:Hide()
    end)

    -- Actualiza en vivo el indicador de cercanía cuando el diálogo está abierto
    tf._proxAcc = 0
    tf:SetScript("OnUpdate", function(self, elapsed)
        if not self.currentBot or not DungeonBots.GetBotProximityInfo then return end
        self._proxAcc = (self._proxAcc or 0) + (elapsed or 0)
        if self._proxAcc < 0.6 then return end
        self._proxAcc = 0
        local prox = DungeonBots:GetBotProximityInfo(self.currentBot)
        local newKey = prox and prox.key or nil
        if newKey and newKey ~= self._lastProxKey then
            DungeonBots:UpdateTalkDialog(self.currentBot)
        end
    end)

    DungeonBots.talkFrame = tf
end

local TALK_QUEST_STYLE = {
    available = {
        prefix = L["TALK_TAG_AVAILABLE"],
        showBtn = true,
        btnText = L["BTN_ACCEPT"],
        btnIcon = "Interface\\Icons\\INV_Misc_Book_09",
        btnAction = "accept",
        rightBadge = nil,
        border = { 0.25, 0.85, 0.45, 1.0 },
        tipStatus = L["STATUS_INCOMPLETE"],
        tipColor = { 0.2, 0.9, 0.45 },
        tipHint = L["TALK_TIP_AVAILABLE"],
    },
    incompleted = {
        prefix = L["TALK_TAG_INPROGRESS"],
        showBtn = true,
        btnText = L["BTN_ABANDON"],
        btnIcon = "Interface\\Icons\\Spell_ChargeNegative",
        btnAction = "drop",
        rightBadge = nil,
        border = { 1.0, 0.55, 0.25, 1.0 },
        tipStatus = L["TALK_LBL_INPROGRESS"],
        tipColor = { 1.0, 0.62, 0.15 },
        tipHint = L["TALK_TIP_INPROGRESS"],
    },
    completed = {
        prefix = L["TALK_TAG_COMPLETE"],
        showBtn = true,
        btnText = L["BTN_TURN_IN"],
        btnIcon = "Interface\\Icons\\INV_Misc_Book_09",
        btnAction = "accept",
        rightBadge = nil,
        border = { 0.25, 0.85, 1.0, 1.0 },
        tipStatus = L["TALK_LBL_COMPLETE"],
        tipColor = { 0.2, 0.85, 1.0 },
        tipHint = L["TALK_TIP_COMPLETE"],
    },
    unavailable = {
        prefix = L["TALK_TAG_UNAVAIL"],
        showBtn = false,
        btnText = nil,
        btnIcon = nil,
        btnAction = nil,
        rightBadge = L["TALK_LBL_LOCKED"],
        border = { 0.5, 0.5, 0.55, 1.0 },
        tipStatus = L["TALK_LBL_UNAVAIL"],
        tipColor = { 0.65, 0.65, 0.7 },
        tipHint = L["TALK_TIP_UNAVAIL"],
    },
    unknown = {
        prefix = L["TALK_TAG_QUEST"],
        showBtn = true,
        btnText = L["BTN_ACCEPT"],
        btnIcon = "Interface\\Icons\\INV_Misc_Book_09",
        btnAction = "accept",
        rightBadge = nil,
        border = { 1.0, 0.82, 0.25, 1.0 },
        tipStatus = nil,
        tipColor = { 1, 0.85, 0.2 },
        tipHint = L["TALK_TIP_QUEST"],
    },
}
if DB_Internal.RegisterLocaleRefresh then
    DB_Internal.RegisterLocaleRefresh(function()
        TALK_QUEST_STYLE.available.prefix    = L["TALK_TAG_AVAILABLE"]
        TALK_QUEST_STYLE.available.btnText   = L["BTN_ACCEPT"]
        TALK_QUEST_STYLE.available.tipStatus = L["STATUS_INCOMPLETE"]
        TALK_QUEST_STYLE.available.tipHint   = L["TALK_TIP_AVAILABLE"]

        TALK_QUEST_STYLE.incompleted.prefix    = L["TALK_TAG_INPROGRESS"]
        TALK_QUEST_STYLE.incompleted.btnText   = L["BTN_ABANDON"]
        TALK_QUEST_STYLE.incompleted.tipStatus = L["TALK_LBL_INPROGRESS"]
        TALK_QUEST_STYLE.incompleted.tipHint   = L["TALK_TIP_INPROGRESS"]

        TALK_QUEST_STYLE.completed.prefix    = L["TALK_TAG_COMPLETE"]
        TALK_QUEST_STYLE.completed.btnText   = L["BTN_TURN_IN"]
        TALK_QUEST_STYLE.completed.tipStatus = L["TALK_LBL_COMPLETE"]
        TALK_QUEST_STYLE.completed.tipHint   = L["TALK_TIP_COMPLETE"]

        TALK_QUEST_STYLE.unavailable.prefix     = L["TALK_TAG_UNAVAIL"]
        TALK_QUEST_STYLE.unavailable.rightBadge = L["TALK_LBL_LOCKED"]
        TALK_QUEST_STYLE.unavailable.tipStatus  = L["TALK_LBL_UNAVAIL"]
        TALK_QUEST_STYLE.unavailable.tipHint    = L["TALK_TIP_UNAVAIL"]

        TALK_QUEST_STYLE.unknown.prefix  = L["TALK_TAG_QUEST"]
        TALK_QUEST_STYLE.unknown.btnText = L["BTN_ACCEPT"]
        TALK_QUEST_STYLE.unknown.tipHint = L["TALK_TIP_QUEST"]
    end)
end

function DungeonBots:UpdateTalkDialog(botName)
    if not DungeonBots.talkFrame then return end
    local tf = DungeonBots.talkFrame
    local targetBot = botName or tf.currentBot
    if not targetBot then return end
    if tf:IsShown() and tf.currentBot and botName and tf.currentBot ~= botName then
        return
    end
    tf.currentBot = targetBot
    tf.title:SetText(string.format(L["TALK_WIN_FMT"], targetBot))

    local data = DungeonBots.talkDialogData and DungeonBots.talkDialogData[targetBot]
    local isBusy = (DungeonBots.IsTalkBusy and DungeonBots:IsTalkBusy(targetBot)) and true or false
    local npcTitle = (data and data.npcName and data.npcName ~= "") and data.npcName or L["TALK_NPC_SELECTED"]
    local statusTag = isBusy and L["TALK_STATE_QUERYING"] or L["TALK_STATE_READY"]
    local prox = DungeonBots.GetBotProximityInfo and DungeonBots:GetBotProximityInfo(targetBot) or nil
    tf._lastProxKey = prox and prox.key or nil
    local proxSuffix = (prox and prox.badgeText) and ("  " .. prox.badgeText) or ""
    tf.npcLabel:SetText(string.format(L["TALK_NPC_FMT"], npcTitle, statusTag) .. proxSuffix)

    if tf.requeryBtn then
        if isBusy then
            tf.requeryBtn:Disable()
            tf.requeryBtn:SetText(L["BTN_QUERYING"])
        else
            tf.requeryBtn:Enable()
            tf.requeryBtn:SetText(L["BTN_REQUERY"])
        end
    end

    if tf.nextBotBtn and DungeonBots.GetTalkBotCycleInfo then
        local curIdx, total = DungeonBots:GetTalkBotCycleInfo(targetBot)
        if total >= 2 then
            tf.nextBotBtn:Enable()
            if tf.botCycleLabel then
                local posStr = (curIdx > 0) and (curIdx .. "/" .. total) or ("0/" .. total)
                tf.botCycleLabel:SetText("|cffaaaaaa(" .. posStr .. ")|r")
            end
        else
            tf.nextBotBtn:Disable()
            if tf.botCycleLabel then
                tf.botCycleLabel:SetText(total == 1 and "|cff777777(1/1)|r" or "")
            end
        end
    end

    local lines = (data and data.lines) or {}
    local actions = (data and data.actions) or {}

    for _, row in ipairs(talkActionRows) do
        row:Hide()
    end

    if #actions == 0 then
        local lastLocalized = (#lines > 0)
            and ((DungeonBots.LocalizeHyperlinksInText and DungeonBots:LocalizeHyperlinksInText(lines[#lines])) or lines[#lines])
            or nil
        if data and data.rangeError then
            local reasonTxt = lastLocalized and ("\n|cffaaaaaa(" .. DungeonBots:StripChatFormatting(lastLocalized) .. ")|r") or ""
            tf.emptyOptLabel:SetText(string.format(L["TALK_FAR_ERR_FMT"], targetBot) .. reasonTxt)
        elseif data and (data.loading or isBusy) then
            if prox and prox.isFar then
                tf.emptyOptLabel:SetText(string.format(L["TALK_FAR_WAIT_FMT"], (prox.detailMsg or targetBot), targetBot))
            elseif data.isAcceptCmd then
                tf.emptyOptLabel:SetText(string.format(L["TALK_ACCEPTING_FMT"], targetBot))
            else
                tf.emptyOptLabel:SetText(string.format(L["TALK_QUERYING_OPT_FMT"], targetBot))
            end
        elseif data and data.isAcceptCmd and not data.acceptError then
            if lastLocalized then
                local cleanFallback = DungeonBots:StripChatFormatting(lastLocalized)
                tf.emptyOptLabel:SetText("|cff34c759" .. cleanFallback .. "|r")
            else
                tf.emptyOptLabel:SetText(L["TALK_QUEST_ACCEPTED"])
            end
        elseif data and data.acceptError and lastLocalized then
            local cleanFallback = DungeonBots:StripChatFormatting(lastLocalized)
            tf.emptyOptLabel:SetText(string.format(L["TALK_ACCEPT_FAIL_FMT"], cleanFallback))
        elseif prox and prox.isFar then
            local extra = lastLocalized and ("\n\n|cffaaaaaa(" .. DungeonBots:StripChatFormatting(lastLocalized) .. ")|r") or ""
            tf.emptyOptLabel:SetText(string.format(L["TALK_TOO_FAR_SHORT"], (prox.detailMsg or targetBot)) .. extra)
        elseif lastLocalized then
            local cleanFallback = DungeonBots:StripChatFormatting(lastLocalized)
            tf.emptyOptLabel:SetText("No se detectaron opciones ni misiones disponibles.\n\n|cffaaaaaa(" .. cleanFallback .. ")|r")
        elseif prox and prox.key == "medium" then
            tf.emptyOptLabel:SetText(string.format(L["TALK_NO_OPTS_MID"], targetBot))
        else
            tf.emptyOptLabel:SetText(string.format(L["TALK_NO_OPTS_NEAR"], targetBot))
        end
        tf.emptyOptLabel:Show()
    else
        tf.emptyOptLabel:Hide()
        for i, act in ipairs(actions) do
            local row = talkActionRows[i] or CreateTalkActionRow(tf.optChild, i)
            row:Show()

            if act.kind == "quest" then
                local style = TALK_QUEST_STYLE[act.questState or "unknown"] or TALK_QUEST_STYLE.unknown
                local showShare = (style.showBtn and style.btnAction == "drop")
                row.mainBtn:ClearAllPoints()
                row.mainBtn:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -2)
                row.mainBtn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", showShare and -206 or -112, 2)
                row.label:SetText(style.prefix .. (act.displayLink or act.title or L["QUEST_DEFAULT"]))
                row.mainBtn:SetScript("OnClick", function(self)
                    PlaySound("igMainMenuOptionCheckBoxOn")
                    local linkRef = act.questId and ("quest:" .. act.questId .. ":" .. (act.questLevel or "80")) or nil
                    SafeShowLinkTooltip(self, linkRef, act.displayLink, act.title, act.label)
                end)
                row.mainBtn:SetScript("OnEnter", function(self)
                    local b = style.border
                    row:SetBackdropBorderColor(b[1], b[2], b[3], b[4])
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine(act.title or L["QUEST_DEFAULT"], 1, 0.85, 0.2)
                    if style.tipStatus then
                        local c = style.tipColor
                        GameTooltip:AddLine(L["QUEST_STATUS_PREFIX"] .. style.tipStatus, c[1], c[2], c[3])
                    end
                    GameTooltip:AddLine(style.tipHint, 0.75, 0.85, 1.0, true)
                    GameTooltip:Show()
                end)
                row.mainBtn:SetScript("OnLeave", function()
                    SetThemedBorder(row, false)
                    GameTooltip:Hide()
                end)

                if showShare and row.shareBtn then
                    local canShare = (act.safeLink ~= nil or act.rawDisplayLink ~= nil or act.questId ~= nil)
                    row.shareBtn:Show()
                    if canShare then
                        row.shareBtn:Enable()
                        row.shareBtn:SetAlpha(1.0)
                    else
                        row.shareBtn:Disable()
                        row.shareBtn:SetAlpha(0.45)
                    end
                    row.shareBtn:SetScript("OnClick", function()
                        DungeonBots:ShareBotQuest(targetBot, act)
                    end)
                    row.shareBtn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_TOP")
                        GameTooltip:AddLine(L["QUEST_SHARE_TIP"], 0.9, 0.92, 0.95, true)
                        GameTooltip:Show()
                    end)
                    row.shareBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                elseif row.shareBtn then
                    row.shareBtn:Hide()
                end

                if style.showBtn then
                    row.statusTag:Hide()
                    if row.acceptBtn.icon then
                        row.acceptBtn.icon:SetTexture(style.btnIcon or "Interface\\Icons\\INV_Misc_Book_09")
                    end
                    row.acceptBtn:SetText(style.btnText or L["BTN_ACCEPT"])
                    row.acceptBtn:Show()
                    row.acceptBtn:SetScript("OnClick", function()
                        if style.btnAction == "drop" then
                            ConfirmDropBotQuest(targetBot, act, true)
                        else
                            DungeonBots:SendTalkCommand(targetBot, act.acceptCmd)
                        end
                    end)
                    if style.btnAction == "drop" then
                        row.acceptBtn:SetScript("OnEnter", function(self)
                            GameTooltip:SetOwner(self, "ANCHOR_TOP")
                            GameTooltip:AddLine(L["QUEST_DROP_TIP"], 1, 0.4, 0.4, true)
                            GameTooltip:Show()
                        end)
                        row.acceptBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                    else
                        row.acceptBtn:SetScript("OnEnter", nil)
                        row.acceptBtn:SetScript("OnLeave", nil)
                    end
                else
                    row.acceptBtn:Hide()
                    row.statusTag:SetText(style.rightBadge or "")
                    row.statusTag:Show()
                end
            else
                if row.shareBtn then
                    row.shareBtn:Hide()
                end
                row.acceptBtn:Hide()
                row.statusTag:Hide()
                row.mainBtn:ClearAllPoints()
                row.mainBtn:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -2)
                row.mainBtn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 2)
                row.label:SetText(string.format(L["TALK_OPTION_FMT"], (act.label or act.cmd or L["TALK_OPTION_DEFAULT"])))
                row.mainBtn:SetScript("OnClick", function()
                    PlaySound("igMainMenuOptionCheckBoxOn")
                    DungeonBots:SendTalkCommand(targetBot, act.cmd)
                end)
                row.mainBtn:SetScript("OnEnter", function(self)
                    SetThemedBorder(row, true)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine(act.label or L["TALK_OPT_TIP_TITLE"], 0.45, 0.85, 1.0)
                    GameTooltip:AddLine(L["TALK_OPT_TIP_DESC"], 0.85, 0.85, 0.85, true)
                    GameTooltip:Show()
                end)
                row.mainBtn:SetScript("OnLeave", function()
                    SetThemedBorder(row, false)
                    GameTooltip:Hide()
                end)
            end
        end
    end

    tf.optChild:SetHeight(math.max(1, (#actions * 30) + 4))
end

function DungeonBots:OpenTalkDialog(botName)
    if not DungeonBots.talkFrame then
        DungeonBots:BuildTalkDialog()
    end
    DungeonBots.talkFrame.currentBot = botName
    DungeonBots:UpdateTalkDialog(botName)
    DungeonBots.talkFrame:Show()
    if DungeonBots.talkFrame.Raise then
        pcall(DungeonBots.talkFrame.Raise, DungeonBots.talkFrame)
    end
end
