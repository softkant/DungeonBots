-- =========================================================================
-- DungeonBots_QuestTalkUI.lua: Diálogos Interactivos de Misiones y Talk
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal

local function ApplyDarkBackdrop(frame, edgeSize)
    return DB_Internal.ApplyDarkBackdrop(frame, edgeSize)
end

local function ApplyHeaderBackdrop(frame)
    return DB_Internal.ApplyHeaderBackdrop(frame)
end

local function CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
    return DB_Internal.CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
end

local function SafeShowLinkTooltip(owner, linkRef, displayLink, title, rawLine)
    return DB_Internal.SafeShowLinkTooltip(owner, linkRef, displayLink, title, rawLine)
end

-- =========================================================================
-- VENTANA DE DIÁLOGO: MISIONES DEL BOT (quests all / drop)
-- =========================================================================
local questRows = {}

local function CreateQuestRow(parent, idx)
    local row = CreateFrame("Frame", "DungeonBots_QuestRow_" .. idx, parent)
    row:SetSize(486, 36)
    row:SetPoint("TOPLEFT", 0, -((idx - 1) * 40))
    ApplyDarkBackdrop(row, 8)
    row:SetBackdropColor(0.08, 0.10, 0.14, 0.95)
    row:SetBackdropBorderColor(0.28, 0.32, 0.40, 0.85)

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

    local dropBtn = CreateRedIconButton(row, 96, 22, "Abandonar", "Interface\\Icons\\Spell_ChargeNegative")
    dropBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.dropBtn = dropBtn

    local shareBtn = CreateRedIconButton(row, 96, 22, "Compartir", "Interface\\Icons\\INV_Misc_GroupLooking")
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
    ApplyDarkBackdrop(qf, 14)
    qf:SetBackdropColor(0.04, 0.05, 0.08, 1.0)

    local solidBg = qf:CreateTexture(nil, "BACKGROUND")
    solidBg:SetPoint("TOPLEFT", qf, "TOPLEFT", 4, -4)
    solidBg:SetPoint("BOTTOMRIGHT", qf, "BOTTOMRIGHT", -4, 4)
    solidBg:SetTexture(0.04, 0.05, 0.08, 1.0)

    table.insert(UISpecialFrames, "DungeonBots_QuestFrame")

    local header = CreateFrame("Frame", nil, qf)
    header:SetPoint("TOPLEFT", qf, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", qf, "TOPRIGHT", -6, -6)
    header:SetHeight(30)
    ApplyHeaderBackdrop(header)
    header:SetBackdropColor(0.10, 0.12, 0.16, 1.0)

    local headerSolidBg = header:CreateTexture(nil, "BACKGROUND")
    headerSolidBg:SetPoint("TOPLEFT", header, "TOPLEFT", 2, -2)
    headerSolidBg:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -2, 2)
    headerSolidBg:SetTexture(0.10, 0.12, 0.16, 1.0)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("|cff00ccffMisiones:|r |cffffd200Bot|r")
    qf.title = title

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        qf:Hide()
    end)

    local statusLabel = qf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusLabel:SetPoint("TOPLEFT", 14, -44)
    statusLabel:SetText("Misiones activas: |cffffd2000|r")
    qf.statusLabel = statusLabel

    local refreshBtn = CreateFrame("Button", nil, qf, "UIPanelButtonTemplate")
    refreshBtn:SetSize(96, 22)
    refreshBtn:SetPoint("TOPRIGHT", qf, "TOPRIGHT", -14, -40)
    refreshBtn:SetText("Actualizar")
    refreshBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if qf.currentBot then
            DungeonBots:QueryQuests(qf.currentBot, true, false)
        end
    end)
    qf.refreshBtn = refreshBtn

    local scrollBg = CreateFrame("Frame", nil, qf)
    scrollBg:SetPoint("TOPLEFT", qf, "TOPLEFT", 10, -68)
    scrollBg:SetPoint("BOTTOMRIGHT", qf, "BOTTOMRIGHT", -10, 40)
    ApplyDarkBackdrop(scrollBg, 10)
    scrollBg:SetBackdropColor(0.02, 0.03, 0.05, 1.0)
    scrollBg:SetBackdropBorderColor(0.30, 0.34, 0.42, 1.0)

    local scrollSolidBg = scrollBg:CreateTexture(nil, "BACKGROUND")
    scrollSolidBg:SetPoint("TOPLEFT", scrollBg, "TOPLEFT", 3, -3)
    scrollSolidBg:SetPoint("BOTTOMRIGHT", scrollBg, "BOTTOMRIGHT", -3, 3)
    scrollSolidBg:SetTexture(0.02, 0.03, 0.05, 1.0)

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
    emptyLabel:SetText("Este bot no tiene misiones activas.")
    qf.emptyLabel = emptyLabel

    local footerHint = qf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footerHint:SetPoint("BOTTOMLEFT", 14, 15)
    footerHint:SetText("|cffaaaaaaClic en una misión para ver detalles, o pulsa 'Compartir' / 'Abandonar'.|r")

    local closeFooterBtn = CreateFrame("Button", nil, qf, "UIPanelButtonTemplate")
    closeFooterBtn:SetSize(90, 24)
    closeFooterBtn:SetPoint("BOTTOMRIGHT", qf, "BOTTOMRIGHT", -12, 10)
    closeFooterBtn:SetText("Cerrar")
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
    qf.title:SetText("|cff00ccffMisiones:|r |cffffd200" .. targetBot .. "|r")

    local data = DungeonBots.questDialogData and DungeonBots.questDialogData[targetBot]
    local quests = (data and data.quests) or {}

    if data and data.loading and #quests == 0 then
        qf.statusLabel:SetText("|cff71d5ffConsultando misiones activas...|r")
        qf.emptyLabel:SetText("|cff71d5ffConsultando misiones de " .. targetBot .. "...|r\n\n|cff888888Espera un instante mientras responde.|r")
        qf.emptyLabel:Show()
    elseif #quests == 0 then
        qf.statusLabel:SetText("Misiones activas: |cffffd2000|r")
        if data and data.emptyHint and data.emptyHint ~= "" then
            qf.emptyLabel:SetText("Este bot no tiene misiones activas.\n\n|cff888888(" .. data.emptyHint .. ")|r")
        else
            qf.emptyLabel:SetText("Este bot no tiene misiones activas.")
        end
        qf.emptyLabel:Show()
    else
        qf.statusLabel:SetText("Misiones activas: |cffffd200" .. #quests .. "|r  |cff888888(clic para ver detalles)|r")
        qf.emptyLabel:Hide()
    end

    for _, row in ipairs(questRows) do
        row:Hide()
    end

    for i, q in ipairs(quests) do
        local row = questRows[i] or CreateQuestRow(qf.scrollChild, i)
        row:Show()

        local lvlPrefix = (q.questLevel and q.questLevel ~= "") and ("|cff88aacc[" .. q.questLevel .. "]|r ") or ""
        row.titleText:SetText(lvlPrefix .. "|cffffff00" .. (q.title or "Misión") .. "|r")

        local subStr = ""
        if q.statusText and q.statusText ~= "" then
            local lowerSt = string.lower(q.statusText)
            if (string.find(lowerSt, "complete") or string.find(lowerSt, "completa")) and not string.find(lowerSt, "incomplete") then
                subStr = "|cff34c759" .. q.statusText .. "|r"
            else
                subStr = "|cff9aa5b5" .. q.statusText .. "|r"
            end
        elseif q.questId then
            subStr = "|cff777777ID: " .. q.questId .. " (clic para inspeccionar)|r"
        else
            subStr = "|cff777777Clic para ver detalle|r"
        end
        row.subText:SetText(subStr)

        row.titleBtn:SetScript("OnClick", function(self)
            PlaySound("igMainMenuOptionCheckBoxOn")
            local linkRef = q.questId and ("quest:" .. q.questId .. ":" .. (q.questLevel or "80")) or nil
            SafeShowLinkTooltip(self, linkRef, q.displayLink, q.title, q.rawLine)
        end)
        row.titleBtn:SetScript("OnEnter", function(self)
            row:SetBackdropBorderColor(0.25, 0.78, 1.0, 1.0)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(q.title or "Misión", 1, 0.85, 0.2)
            if q.statusText and q.statusText ~= "" then
                GameTooltip:AddLine("Estado: " .. q.statusText, 0.8, 0.9, 1.0, true)
            end
            if q.questId then
                GameTooltip:AddLine("Haz clic para abrir el detalle de la misión.", 0.3, 0.9, 0.5)
            end
            GameTooltip:Show()
        end)
        row.titleBtn:SetScript("OnLeave", function()
            row:SetBackdropBorderColor(0.28, 0.32, 0.40, 0.85)
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
            GameTooltip:AddLine("Compartir Misión", 0.3, 0.85, 1.0)
            if canShare then
                GameTooltip:AddLine("Ordena a " .. targetBot .. " compartir '" .. (q.title or "") .. "' contigo y el grupo.", 0.8, 0.85, 0.95, true)
            else
                GameTooltip:AddLine("No hay enlace de misión disponible para compartir.", 1.0, 0.5, 0.4, true)
            end
            GameTooltip:Show()
        end)
        row.shareBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row.dropBtn:Show()
        row.dropBtn:SetScript("OnClick", function()
            DungeonBots:DropBotQuest(targetBot, q)
        end)
        row.dropBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Abandonar Misión", 1, 0.35, 0.35)
            GameTooltip:AddLine("Ordena a " .. targetBot .. " abandonar '" .. (q.title or "") .. "' y recarga la lista.", 0.8, 0.85, 0.95, true)
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
    DungeonBots.questFrame.currentBot = botName
    DungeonBots:UpdateQuestDialog(botName)
    DungeonBots.questFrame:Show()
    if DungeonBots.questFrame.Raise then
        pcall(DungeonBots.questFrame.Raise, DungeonBots.questFrame)
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
    ApplyDarkBackdrop(row, 6)
    row:SetBackdropColor(0.08, 0.10, 0.15, 0.95)
    row:SetBackdropBorderColor(0.28, 0.34, 0.44, 0.85)

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

    local acceptBtn = CreateRedIconButton(row, 100, 20, "Aceptar", "Interface\\Icons\\INV_Misc_Book_09")
    acceptBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    acceptBtn:Hide()
    row.acceptBtn = acceptBtn

    local shareBtn = CreateRedIconButton(row, 94, 20, "Compartir", "Interface\\Icons\\INV_Misc_GroupLooking")
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
    ApplyDarkBackdrop(tf, 14)
    tf:SetBackdropColor(0.04, 0.05, 0.08, 1.0)

    local solidBg = tf:CreateTexture(nil, "BACKGROUND")
    solidBg:SetPoint("TOPLEFT", tf, "TOPLEFT", 4, -4)
    solidBg:SetPoint("BOTTOMRIGHT", tf, "BOTTOMRIGHT", -4, 4)
    solidBg:SetTexture(0.04, 0.05, 0.08, 1.0)

    table.insert(UISpecialFrames, "DungeonBots_TalkFrame")

    local header = CreateFrame("Frame", nil, tf)
    header:SetPoint("TOPLEFT", tf, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", tf, "TOPRIGHT", -6, -6)
    header:SetHeight(30)
    ApplyHeaderBackdrop(header)
    header:SetBackdropColor(0.10, 0.12, 0.16, 1.0)

    local headerSolidBg = header:CreateTexture(nil, "BACKGROUND")
    headerSolidBg:SetPoint("TOPLEFT", header, "TOPLEFT", 2, -2)
    headerSolidBg:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -2, 2)
    headerSolidBg:SetTexture(0.10, 0.12, 0.16, 1.0)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("|cff00ccffDiálogo PNJ:|r |cffffd200Bot|r")
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
    requeryBtn:SetText("Reconsultar")
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
    npcLabel:SetText("PNJ: |cffffd200Objetivo actual|r")
    tf.npcLabel = npcLabel

    local optTitle = tf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    optTitle:SetPoint("TOPLEFT", tf, "TOPLEFT", 14, -68)
    optTitle:SetText("|cffffd200Opciones y Misiones del PNJ:|r")

    local optBg = CreateFrame("Frame", nil, tf)
    optBg:SetPoint("TOPLEFT", tf, "TOPLEFT", 10, -84)
    optBg:SetPoint("BOTTOMRIGHT", tf, "BOTTOMRIGHT", -10, 40)
    ApplyDarkBackdrop(optBg, 10)
    optBg:SetBackdropColor(0.02, 0.03, 0.05, 1.0)
    optBg:SetBackdropBorderColor(0.28, 0.32, 0.40, 1.0)

    local optSolidBg = optBg:CreateTexture(nil, "BACKGROUND")
    optSolidBg:SetPoint("TOPLEFT", optBg, "TOPLEFT", 3, -3)
    optSolidBg:SetPoint("BOTTOMRIGHT", optBg, "BOTTOMRIGHT", -3, 3)
    optSolidBg:SetTexture(0.02, 0.03, 0.05, 1.0)

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
    emptyOptLabel:SetText("Esperando respuesta del PNJ...")
    tf.emptyOptLabel = emptyOptLabel

    local nextBotBtn = CreateFrame("Button", nil, tf, "UIPanelButtonTemplate")
    nextBotBtn:SetSize(122, 24)
    nextBotBtn:SetPoint("BOTTOMLEFT", tf, "BOTTOMLEFT", 12, 10)
    nextBotBtn:SetText("Siguiente Bot")
    nextBotBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if DungeonBots.CycleNextTalkBot then
            DungeonBots:CycleNextTalkBot(tf.currentBot)
        end
    end)
    nextBotBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Siguiente Bot (talk)", 1, 0.85, 0.2)
        if DungeonBots.GetTalkBotCycleInfo then
            local curIdx, total = DungeonBots:GetTalkBotCycleInfo(tf.currentBot)
            if total >= 2 then
                local posLabel = (curIdx > 0) and (curIdx .. "/" .. total) or ("0/" .. total)
                GameTooltip:AddLine("Cambia en orden por los bots del grupo y consulta 'talk' con el siguiente (" .. posLabel .. ").", 0.8, 0.9, 1.0, true)
            else
                GameTooltip:AddLine("Se necesitan al menos 2 bots en el grupo para pasar al siguiente.", 0.8, 0.8, 0.8, true)
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
    questLogBtn:SetText("Registro Misiones")
    questLogBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if tf.currentBot then
            DungeonBots:QueryQuests(tf.currentBot)
        end
    end)
    questLogBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Registro de Misiones del Bot", 1, 0.85, 0.2)
        if tf.currentBot then
            GameTooltip:AddLine("Abre la ventana de Misiones para " .. tf.currentBot .. " (quests all).", 0.8, 0.9, 1.0, true)
        else
            GameTooltip:AddLine("Abre la ventana de Misiones del bot seleccionado.", 0.8, 0.9, 1.0, true)
        end
        GameTooltip:Show()
    end)
    questLogBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local closeFooterBtn = CreateFrame("Button", nil, tf, "UIPanelButtonTemplate")
    closeFooterBtn:SetSize(90, 24)
    closeFooterBtn:SetPoint("BOTTOMRIGHT", tf, "BOTTOMRIGHT", -12, 10)
    closeFooterBtn:SetText("Cerrar")
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
        prefix = "|cff34c759[Disponible]|r ",
        showBtn = true,
        btnText = "Aceptar",
        btnIcon = "Interface\\Icons\\INV_Misc_Book_09",
        btnAction = "accept",
        rightBadge = nil,
        border = { 0.25, 0.85, 0.45, 1.0 },
        tipStatus = "Disponible",
        tipColor = { 0.2, 0.9, 0.45 },
        tipHint = "El bot puede tomar esta misión. Pulsa 'Aceptar' o haz clic para inspeccionarla.",
    },
    incompleted = {
        prefix = "|cffff9f0a[En curso]|r ",
        showBtn = true,
        btnText = "Abandonar",
        btnIcon = "Interface\\Icons\\Spell_ChargeNegative",
        btnAction = "drop",
        rightBadge = nil,
        border = { 1.0, 0.55, 0.25, 1.0 },
        tipStatus = "En curso",
        tipColor = { 1.0, 0.62, 0.15 },
        tipHint = "El bot ya lleva esta misión. Clic en el nombre para ver detalles, o pulsa 'Abandonar'.",
    },
    completed = {
        prefix = "|cff00ccff[Completa]|r ",
        showBtn = true,
        btnText = "Entregar",
        btnIcon = "Interface\\Icons\\INV_Misc_Book_09",
        btnAction = "accept",
        rightBadge = nil,
        border = { 0.25, 0.85, 1.0, 1.0 },
        tipStatus = "Completa (Lista para entregar)",
        tipColor = { 0.2, 0.85, 1.0 },
        tipHint = "Objetivos completos. Pulsa 'Entregar' o haz clic para ver detalles.",
    },
    unavailable = {
        prefix = "|cff888888[No disponible]|r ",
        showBtn = false,
        btnText = nil,
        btnIcon = nil,
        btnAction = nil,
        rightBadge = "|cff888888Bloqueada|r",
        border = { 0.5, 0.5, 0.55, 1.0 },
        tipStatus = "No disponible",
        tipColor = { 0.65, 0.65, 0.7 },
        tipHint = "El bot aún no puede tomar esta misión. Clic para ver detalles.",
    },
    unknown = {
        prefix = "|cffffd200[Misión]|r ",
        showBtn = true,
        btnText = "Aceptar",
        btnIcon = "Interface\\Icons\\INV_Misc_Book_09",
        btnAction = "accept",
        rightBadge = nil,
        border = { 1.0, 0.82, 0.25, 1.0 },
        tipStatus = nil,
        tipColor = { 1, 0.85, 0.2 },
        tipHint = "Clic para ver la descripción de la misión.",
    },
}

function DungeonBots:UpdateTalkDialog(botName)
    if not DungeonBots.talkFrame then return end
    local tf = DungeonBots.talkFrame
    local targetBot = botName or tf.currentBot
    if not targetBot then return end
    if tf:IsShown() and tf.currentBot and botName and tf.currentBot ~= botName then
        return
    end
    tf.currentBot = targetBot
    tf.title:SetText("|cff00ccffDiálogo PNJ:|r |cffffd200" .. targetBot .. "|r")

    local data = DungeonBots.talkDialogData and DungeonBots.talkDialogData[targetBot]
    local isBusy = (DungeonBots.IsTalkBusy and DungeonBots:IsTalkBusy(targetBot)) and true or false
    local npcTitle = (data and data.npcName and data.npcName ~= "") and data.npcName or "PNJ seleccionado"
    local statusTag = isBusy and "|cff71d5ff[Consultando...]|r" or "|cff34c759[Listo]|r"
    local prox = DungeonBots.GetBotProximityInfo and DungeonBots:GetBotProximityInfo(targetBot) or nil
    tf._lastProxKey = prox and prox.key or nil
    local proxSuffix = (prox and prox.badgeText) and ("  " .. prox.badgeText) or ""
    tf.npcLabel:SetText("PNJ: |cffffd200" .. npcTitle .. "|r  " .. statusTag .. proxSuffix)

    if tf.requeryBtn then
        if isBusy then
            tf.requeryBtn:Disable()
            tf.requeryBtn:SetText("Consultando...")
        else
            tf.requeryBtn:Enable()
            tf.requeryBtn:SetText("Reconsultar")
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
            tf.emptyOptLabel:SetText("|cffff5544" .. targetBot .. " está demasiado lejos del PNJ.|r" .. reasonTxt .. "\n\nAcércalo al PNJ (usa |cffffd200Seguir|r o |cffffd200Summon|r) y pulsa |cffffd200'Reconsultar'|r.")
        elseif data and (data.loading or isBusy) then
            if prox and prox.isFar then
                tf.emptyOptLabel:SetText("|cffff7b30" .. (prox.detailMsg or (targetBot .. " está lejos.")) .. "|r\n\n|cffaaaaaaConsultando a " .. targetBot .. "... Si no aparece nada, acércalo con 'Seguir' o 'Summon' y pulsa 'Reconsultar'.|r")
            elseif data.isAcceptCmd then
                tf.emptyOptLabel:SetText("|cff71d5ffAceptando misión con " .. targetBot .. "...|r")
            else
                tf.emptyOptLabel:SetText("|cff71d5ffConsultando opciones y misiones del PNJ con " .. targetBot .. "...|r")
            end
        elseif data and data.isAcceptCmd and not data.acceptError then
            if lastLocalized then
                local cleanFallback = DungeonBots:StripChatFormatting(lastLocalized)
                tf.emptyOptLabel:SetText("|cff34c759" .. cleanFallback .. "|r")
            else
                tf.emptyOptLabel:SetText("|cff34c759Misión aceptada.|r Actualizando diálogo del PNJ...")
            end
        elseif data and data.acceptError and lastLocalized then
            local cleanFallback = DungeonBots:StripChatFormatting(lastLocalized)
            tf.emptyOptLabel:SetText("|cffff5544No se pudo aceptar la misión:|r\n\n|cffffaaaa" .. cleanFallback .. "|r")
        elseif prox and prox.isFar then
            local extra = lastLocalized and ("\n\n|cffaaaaaa(" .. DungeonBots:StripChatFormatting(lastLocalized) .. ")|r") or ""
            tf.emptyOptLabel:SetText("|cffff5544" .. (prox.detailMsg or (targetBot .. " está demasiado lejos.")) .. "|r\n\nAcércalo al PNJ (usa |cffffd200Seguir|r o |cffffd200Summon|r) y pulsa |cffffd200'Reconsultar'|r." .. extra)
        elseif lastLocalized then
            local cleanFallback = DungeonBots:StripChatFormatting(lastLocalized)
            tf.emptyOptLabel:SetText("No se detectaron opciones ni misiones disponibles.\n\n|cffaaaaaa(" .. cleanFallback .. ")|r")
        elseif prox and prox.key == "medium" then
            tf.emptyOptLabel:SetText("No se detectaron opciones ni misiones disponibles.\n|cffffd200" .. targetBot .. " está a media distancia (12-28 m); puede necesitar acercarse más al PNJ y pulsar 'Reconsultar'.|r")
        else
            tf.emptyOptLabel:SetText("No se detectaron opciones ni misiones disponibles.\nAsegúrate de tener seleccionado un PNJ cerca de " .. targetBot .. " y pulsa 'Reconsultar'.")
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
                row.label:SetText(style.prefix .. (act.displayLink or act.title or "Misión"))
                row.mainBtn:SetScript("OnClick", function(self)
                    PlaySound("igMainMenuOptionCheckBoxOn")
                    local linkRef = act.questId and ("quest:" .. act.questId .. ":" .. (act.questLevel or "80")) or nil
                    SafeShowLinkTooltip(self, linkRef, act.displayLink, act.title, act.label)
                end)
                row.mainBtn:SetScript("OnEnter", function(self)
                    local b = style.border
                    row:SetBackdropBorderColor(b[1], b[2], b[3], b[4])
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine(act.title or "Misión", 1, 0.85, 0.2)
                    if style.tipStatus then
                        local c = style.tipColor
                        GameTooltip:AddLine("Estado: " .. style.tipStatus, c[1], c[2], c[3])
                    end
                    GameTooltip:AddLine(style.tipHint, 0.75, 0.85, 1.0, true)
                    GameTooltip:Show()
                end)
                row.mainBtn:SetScript("OnLeave", function()
                    row:SetBackdropBorderColor(0.28, 0.34, 0.44, 0.85)
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
                        GameTooltip:AddLine("Compartir Misión", 0.3, 0.85, 1.0)
                        GameTooltip:AddLine("Ordena a " .. targetBot .. " compartir '" .. (act.title or "") .. "' contigo y el grupo.", 0.8, 0.85, 0.95, true)
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
                    row.acceptBtn:SetText(style.btnText or "Aceptar")
                    row.acceptBtn:Show()
                    row.acceptBtn:SetScript("OnClick", function()
                        if style.btnAction == "drop" then
                            DungeonBots:DropBotQuest(targetBot, act, true)
                        else
                            DungeonBots:SendTalkCommand(targetBot, act.acceptCmd)
                        end
                    end)
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
                row.label:SetText("|cff00ccff>|r |cffffe599" .. (act.label or act.cmd or "Opción") .. "|r")
                row.mainBtn:SetScript("OnClick", function()
                    PlaySound("igMainMenuOptionCheckBoxOn")
                    DungeonBots:SendTalkCommand(targetBot, act.cmd)
                end)
                row.mainBtn:SetScript("OnEnter", function(self)
                    row:SetBackdropBorderColor(0.25, 0.78, 1.0, 1.0)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine("Enviar: " .. (act.cmd or ""), 0.45, 0.85, 1.0)
                    GameTooltip:Show()
                end)
                row.mainBtn:SetScript("OnLeave", function()
                    row:SetBackdropBorderColor(0.28, 0.34, 0.44, 0.85)
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
