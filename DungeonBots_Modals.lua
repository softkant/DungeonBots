-- =========================================================================
-- DungeonBots_Modals.lua: Modales de Configuración e Historial de Bots
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

-- =========================================================================
-- VENTANA DE DIÁLOGO: CONFIGURACIÓN (engranaje)
-- =========================================================================
local function CreateSettingsCheckbox(parent, name, labelText, tipTitle, tipBody)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetText(labelText)
    cb.label = fs
    if tipTitle then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(tipTitle, 1, 1, 1)
            GameTooltip:AddLine(tipBody or "", 0.75, 0.85, 1.0, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return cb
end

function DungeonBots:UpdateSettingsDialog()
    local sf = DungeonBots.settingsFrame
    if not sf then return end

    local hudShow = (not DungeonBotsDB) or (DungeonBotsDB.hudVisible ~= false)
    local utilHudShow = (not DungeonBotsDB) or (DungeonBotsDB.utilHudVisible ~= false)
    local formHudShow = (not DungeonBotsDB) or (DungeonBotsDB.formHudVisible ~= false)
    local anyBarShow = hudShow or utilHudShow or formHudShow
    local hudDungeonOnly = (not DungeonBotsDB) or (DungeonBotsDB.hudOnlyInDungeon ~= false)
    local muteShow = (not DungeonBotsDB) or (DungeonBotsDB.whisperMuteMode ~= "off")
    local muteGroup = (DungeonBotsDB and DungeonBotsDB.muteBotGroupChat) and true or false

    sf.hudVisibleCheck:SetChecked(hudShow)
    sf.utilHudVisibleCheck:SetChecked(utilHudShow)
    sf.formHudVisibleCheck:SetChecked(formHudShow)
    sf.hudDungeonCheck:SetChecked(hudDungeonOnly)
    sf.muteWhispersCheck:SetChecked(muteShow)
    sf.muteGroupCheck:SetChecked(muteGroup)

    sf.muteWhispersCheck:ClearAllPoints()
    if anyBarShow then
        sf.hudDungeonCheck:Show()
        sf.muteWhispersCheck:SetPoint("TOPLEFT", sf.hudDungeonCheck, "BOTTOMLEFT", -18, -10)
    else
        sf.hudDungeonCheck:Hide()
        sf.muteWhispersCheck:SetPoint("TOPLEFT", sf.formHudVisibleCheck, "BOTTOMLEFT", 0, -10)
    end

    if muteShow then
        sf.muteGroupCheck:Show()
    else
        sf.muteGroupCheck:Hide()
    end

    local totalH = 204 + (anyBarShow and 26 or 0) + (muteShow and 26 or 0)
    sf:SetHeight(totalH)
end

function DungeonBots:BuildSettingsDialog()
    if DungeonBots.settingsFrame then return end

    local sf = CreateFrame("Frame", "DungeonBots_SettingsFrame", UIParent)
    sf:SetSize(540, 204)
    sf:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    sf:SetFrameStrata("DIALOG")
    sf:SetFrameLevel(22)
    sf:SetToplevel(true)
    sf:SetMovable(true)
    sf:EnableMouse(true)
    sf:SetClampedToScreen(true)
    sf:RegisterForDrag("LeftButton")
    sf:SetScript("OnDragStart", sf.StartMoving)
    sf:SetScript("OnDragStop", sf.StopMovingOrSizing)
    sf:Hide()
    ApplyDarkBackdrop(sf, 14)
    sf:SetBackdropColor(0.04, 0.05, 0.08, 1.0)

    local solidBg = sf:CreateTexture(nil, "BACKGROUND")
    solidBg:SetPoint("TOPLEFT", sf, "TOPLEFT", 4, -4)
    solidBg:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", -4, 4)
    solidBg:SetTexture(0.04, 0.05, 0.08, 1.0)

    tinsert(UISpecialFrames, "DungeonBots_SettingsFrame")

    local header = CreateFrame("Frame", nil, sf)
    header:SetPoint("TOPLEFT", sf, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", sf, "TOPRIGHT", -6, -6)
    header:SetHeight(30)
    ApplyHeaderBackdrop(header)
    header:SetBackdropColor(0.10, 0.12, 0.16, 1.0)

    local headerSolidBg = header:CreateTexture(nil, "BACKGROUND")
    headerSolidBg:SetPoint("TOPLEFT", header, "TOPLEFT", 2, -2)
    headerSolidBg:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -2, 2)
    headerSolidBg:SetTexture(0.10, 0.12, 0.16, 1.0)

    local hIcon = header:CreateTexture(nil, "ARTWORK")
    hIcon:SetSize(16, 16)
    hIcon:SetPoint("LEFT", 10, 0)
    hIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
    hIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", hIcon, "RIGHT", 6, 0)
    title:SetText("|cff00ccffConfiguración|r |cff888888DungeonBots|r")

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        sf:Hide()
    end)

    -- Opción 1: Mostrar/Ocultar HUD Táctico
    local hudVisibleCheck = CreateSettingsCheckbox(
        sf, "DungeonBots_HudVisibleCheck",
        "Mostrar Barra Táctica flotante (HUD)",
        "Barra Táctica Flotante (HUD)",
        "Muestra la barra rápida flotante de comandos de combate.\n\nDesmarca esta opción para ocultar esta barra por completo."
    )
    hudVisibleCheck:SetPoint("TOPLEFT", sf, "TOPLEFT", 16, -46)
    sf.hudVisibleCheck = hudVisibleCheck

    -- Opción 1a: Mostrar/Ocultar Barra de Utilidades
    local utilHudVisibleCheck = CreateSettingsCheckbox(
        sf, "DungeonBots_UtilHudVisibleCheck",
        "Mostrar Barra de Utilidades flotante (PNJ / Grupo / Bolsas / Personaje / Misiones)",
        "Barra de Utilidades Flotante",
        "Muestra la segunda barra flotante con accesos rápidos para Hablar con PNJ, abrir Bots en el grupo, inspeccionar bolsas, ver Información del Personaje y ver sus misiones.\n\nDesmarca esta opción para ocultar esta barra por completo."
    )
    utilHudVisibleCheck:SetPoint("TOPLEFT", hudVisibleCheck, "BOTTOMLEFT", 0, -2)
    sf.utilHudVisibleCheck = utilHudVisibleCheck

    -- Opción 1a2: Mostrar/Ocultar Barra de Formación
    local formHudVisibleCheck = CreateSettingsCheckbox(
        sf, "DungeonBots_FormHudVisibleCheck",
        "Mostrar Barra de Formación flotante (Arrow / Far / Disperse / Separarse / Espera)",
        "Barra de Formación Flotante",
        "Muestra la tercera barra flotante especializada en formación (arrow, far y otras), disperse, move from group y control de pull/espera.\n\nDesmarca esta opción para ocultar esta barra por completo."
    )
    formHudVisibleCheck:SetPoint("TOPLEFT", utilHudVisibleCheck, "BOTTOMLEFT", 0, -2)
    sf.formHudVisibleCheck = formHudVisibleCheck

    -- Opción 1b (dependiente): Solo en mazmorras de 5 jugadores
    local hudDungeonCheck = CreateSettingsCheckbox(
        sf, "DungeonBots_HudDungeonCheck",
        "Mostrar barras flotantes solo dentro de mazmorras de 5 jugadores",
        "Solo en Mazmorras de 5 Jugadores",
        "Cuando está activa, las barras flotantes (Táctica, Utilidades y Formación) se ocultan fuera de mazmorras de 5 jugadores y aparecen automáticamente al entrar."
    )
    hudDungeonCheck:SetPoint("TOPLEFT", formHudVisibleCheck, "BOTTOMLEFT", 18, -2)
    sf.hudDungeonCheck = hudDungeonCheck

    -- Opción 2: Ocultar susurros de bots
    local muteWhispersCheck = CreateSettingsCheckbox(
        sf, "DungeonBots_MuteWhispersCheck",
        "Ocultar susurros de bots en el chat",
        "Ocultar Susurros de Bots",
        "Oculta todos los susurros entrantes y salientes con cualquier personaje identificado como bot.\n\nLos jugadores humanos reales ([JUGADOR] o desconocidos) NUNCA se ocultan."
    )
    sf.muteWhispersCheck = muteWhispersCheck

    -- Opción 2b (dependiente): Ocultar mensajes de bots en Grupo/Grito/Decir
    local muteGroupCheck = CreateSettingsCheckbox(
        sf, "DungeonBots_MuteGroupChatCheck",
        "Ocultar también mensajes de bots en Grupo (/p), Grito (/y) y Decir (/s)",
        "Ocultar Chat de Grupo/Decir de Bots",
        "También filtra los mensajes públicos de bots en canales de Grupo (/p), Grito (/y) y Decir (/s)."
    )
    muteGroupCheck:SetPoint("TOPLEFT", muteWhispersCheck, "BOTTOMLEFT", 18, -2)
    sf.muteGroupCheck = muteGroupCheck

    local function BindBarVisibilityToggle(checkBtn, dbKey, frameField, labelText)
        checkBtn:SetScript("OnClick", function(self)
            local val = self:GetChecked() and true or false
            if DungeonBotsDB then DungeonBotsDB[dbKey] = val end
            PlaySound(val and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
            if val and DungeonBots.InitHUD and not DungeonBots[frameField] then
                DungeonBots:InitHUD()
            elseif DungeonBots.UpdateHUDVisibility then
                DungeonBots:UpdateHUDVisibility()
            end
            DungeonBots:UpdateSettingsDialog()
            DungeonBots:Print(labelText .. ": " .. (val and "|cff34c759Activada|r" or "|cffff3b30Oculta|r"))
        end)
    end

    BindBarVisibilityToggle(hudVisibleCheck, "hudVisible", "hudFrame", "Barra táctica (HUD)")
    BindBarVisibilityToggle(utilHudVisibleCheck, "utilHudVisible", "utilHudFrame", "Barra de Utilidades")
    BindBarVisibilityToggle(formHudVisibleCheck, "formHudVisible", "formHudFrame", "Barra de Formación")

    hudDungeonCheck:SetScript("OnClick", function(self)
        local val = self:GetChecked() and true or false
        if DungeonBotsDB then DungeonBotsDB.hudOnlyInDungeon = val end
        PlaySound(val and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        if DungeonBots.UpdateHUDVisibility then
            DungeonBots:UpdateHUDVisibility()
        end
        DungeonBots:Print("Barras flotantes solo en mazmorra (5j): " .. (val and "|cff34c759Activado|r" or "|cffffb020Desactivado|r"))
    end)

    muteWhispersCheck:SetScript("OnClick", function(self)
        local val = self:GetChecked() and true or false
        if DungeonBotsDB then
            DungeonBotsDB.whisperMuteMode = val and "all" or "off"
        end
        PlaySound(val and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        if val and DungeonBots.CloseBotWIMWindows then
            DungeonBots:CloseBotWIMWindows()
        end
        DungeonBots:UpdateSettingsDialog()
        DungeonBots:Print("Ocultar susurros de bots: " .. (val and "|cff34c759Activado|r" or "|cffffb020Desactivado|r"))
    end)

    muteGroupCheck:SetScript("OnClick", function(self)
        local val = self:GetChecked() and true or false
        if DungeonBotsDB then DungeonBotsDB.muteBotGroupChat = val end
        PlaySound(val and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        DungeonBots:Print("Ocultar chat de bots en Grupo/Decir: " .. (val and "|cff34c759Activado|r" or "|cffffb020Desactivado|r"))
    end)

    local versionLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    versionLabel:SetPoint("BOTTOMLEFT", sf, "BOTTOMLEFT", 16, 17)
    versionLabel:SetText("|cff71d5ffAsistente de Mazmorras|r |cff888888v" .. (DungeonBots.VERSION or "1.0.0") .. "|r")
    sf.versionLabel = versionLabel

    local closeFooterBtn = CreateFrame("Button", nil, sf, "UIPanelButtonTemplate")
    closeFooterBtn:SetSize(90, 24)
    closeFooterBtn:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", -14, 12)
    closeFooterBtn:SetText("Cerrar")
    closeFooterBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        sf:Hide()
    end)

    DungeonBots.settingsFrame = sf
    if DB_Internal.RegisterSubModalDimmer then
        DB_Internal.RegisterSubModalDimmer(sf)
    end
    DungeonBots:UpdateSettingsDialog()
end

function DungeonBots:ToggleSettingsDialog()
    if not DungeonBots.settingsFrame then
        DungeonBots:BuildSettingsDialog()
    end
    local sf = DungeonBots.settingsFrame
    if sf:IsShown() then
        PlaySound("igMainMenuOptionCheckBoxOff")
        sf:Hide()
    else
        DungeonBots:UpdateSettingsDialog()
        sf:Show()
        if sf.Raise then
            pcall(sf.Raise, sf)
        end
    end
end

-- =========================================================================
-- VENTANA DE DIÁLOGO: HISTORIAL DE BOTS
-- =========================================================================
local historyRows = {}

StaticPopupDialogs["DUNGEONBOTS_CLEAR_HISTORY"] = {
    text = "¿Seguro que quieres borrar todo el historial de bots guardados?",
    button1 = "Sí, limpiar",
    button2 = "Cancelar",
    OnAccept = function()
        DungeonBots:ClearBotHistory()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

function DungeonBots:UpdateHistorySummary()
    if not DungeonBots.historySummaryLabel then return end
    local count = DungeonBots.GetBotHistoryCount and DungeonBots:GetBotHistoryCount() or 0
    DungeonBots.historySummaryLabel:SetText(
        "Lista de bots invitados anteriormente: |cffffd200" .. count .. "|r"
    )
end

local function CreateHistoryRow(parent, idx)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(480, 50)
    ApplyDarkBackdrop(row, 8)
    row:SetBackdropColor(0.10, 0.12, 0.17, 1.0)
    row:SetBackdropBorderColor(0.35, 0.40, 0.50, 0.95)

    local rowSolidBg = row:CreateTexture(nil, "BACKGROUND")
    rowSolidBg:SetPoint("TOPLEFT", row, "TOPLEFT", 3, -3)
    rowSolidBg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -3, 3)
    rowSolidBg:SetTexture(0.10, 0.12, 0.17, 1.0)

    local iconFrame = CreateFrame("Frame", nil, row)
    iconFrame:SetSize(34, 34)
    iconFrame:SetPoint("LEFT", row, "LEFT", 8, 0)
    ApplyDarkBackdrop(iconFrame, 6)
    iconFrame:SetBackdropColor(0, 0, 0, 1)

    row.icon = iconFrame:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 2, -2)
    row.icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.removeBtn:SetSize(24, 24)
    row.removeBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.removeBtn:SetText("X")
    row.removeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Eliminar del historial", 1, 0.3, 0.3)
        GameTooltip:AddLine("Borra este bot de la lista guardada.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    row.removeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row.inviteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.inviteBtn:SetSize(112, 24)
    row.inviteBtn:SetPoint("RIGHT", row.removeBtn, "LEFT", -6, 0)

    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.nameText:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 10, -2)
    row.nameText:SetPoint("RIGHT", row.inviteBtn, "LEFT", -8, 0)
    row.nameText:SetJustifyH("LEFT")

    row.detailText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.detailText:SetPoint("TOPLEFT", row.nameText, "BOTTOMLEFT", 0, -4)
    row.detailText:SetPoint("RIGHT", row.inviteBtn, "LEFT", -8, 0)
    row.detailText:SetJustifyH("LEFT")

    historyRows[idx] = row
    return row
end

function DungeonBots:BuildHistoryDialog()
    if DungeonBots.historyFrame then return end

    local hf = CreateFrame("Frame", "DungeonBots_HistoryFrame", UIParent)
    hf:SetSize(540, 420)
    hf:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    hf:SetFrameStrata("DIALOG")
    hf:SetFrameLevel(24)
    hf:SetToplevel(true)
    hf:SetMovable(true)
    hf:EnableMouse(true)
    hf:SetClampedToScreen(true)
    hf:RegisterForDrag("LeftButton")
    hf:SetScript("OnDragStart", hf.StartMoving)
    hf:SetScript("OnDragStop", hf.StopMovingOrSizing)
    hf:Hide()
    ApplyDarkBackdrop(hf, 14)
    hf:SetBackdropColor(0.04, 0.05, 0.08, 1.0)

    local solidBg = hf:CreateTexture(nil, "BACKGROUND")
    solidBg:SetPoint("TOPLEFT", hf, "TOPLEFT", 4, -4)
    solidBg:SetPoint("BOTTOMRIGHT", hf, "BOTTOMRIGHT", -4, 4)
    solidBg:SetTexture(0.04, 0.05, 0.08, 1.0)

    table.insert(UISpecialFrames, "DungeonBots_HistoryFrame")

    local header = CreateFrame("Frame", nil, hf)
    header:SetPoint("TOPLEFT", hf, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", hf, "TOPRIGHT", -6, -6)
    header:SetHeight(30)
    ApplyHeaderBackdrop(header)
    header:SetBackdropColor(0.10, 0.12, 0.16, 1.0)

    local headerSolidBg = header:CreateTexture(nil, "BACKGROUND")
    headerSolidBg:SetPoint("TOPLEFT", header, "TOPLEFT", 2, -2)
    headerSolidBg:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -2, 2)
    headerSolidBg:SetTexture(0.10, 0.12, 0.16, 1.0)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("|cff00ccffHistorial de|r |cffffd200bots|r")

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        hf:Hide()
    end)

    local countLabel = hf:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    countLabel:SetPoint("TOPLEFT", 14, -44)
    countLabel:SetText("Total guardados: |cffffd2000|r")
    hf.countLabel = countLabel

    local clearBtn = CreateFrame("Button", nil, hf, "UIPanelButtonTemplate")
    clearBtn:SetSize(105, 22)
    clearBtn:SetPoint("TOPRIGHT", hf, "TOPRIGHT", -14, -40)
    clearBtn:SetText("Limpiar Todo")
    clearBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        StaticPopup_Show("DUNGEONBOTS_CLEAR_HISTORY")
    end)

    local scrollBg = CreateFrame("Frame", nil, hf)
    scrollBg:SetPoint("TOPLEFT", hf, "TOPLEFT", 10, -68)
    scrollBg:SetPoint("BOTTOMRIGHT", hf, "BOTTOMRIGHT", -10, 40)
    ApplyDarkBackdrop(scrollBg, 10)
    scrollBg:SetBackdropColor(0.02, 0.03, 0.05, 1.0)
    scrollBg:SetBackdropBorderColor(0.30, 0.34, 0.42, 1.0)

    local scrollSolidBg = scrollBg:CreateTexture(nil, "BACKGROUND")
    scrollSolidBg:SetPoint("TOPLEFT", scrollBg, "TOPLEFT", 3, -3)
    scrollSolidBg:SetPoint("BOTTOMRIGHT", scrollBg, "BOTTOMRIGHT", -3, 3)
    scrollSolidBg:SetTexture(0.02, 0.03, 0.05, 1.0)

    local scrollFrame = CreateFrame("ScrollFrame", "DungeonBots_HistoryScrollFrame", scrollBg, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", scrollBg, "TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", scrollBg, "BOTTOMRIGHT", -26, 6)

    local scrollChild = CreateFrame("Frame", "DungeonBots_HistoryScrollChild", scrollFrame)
    scrollChild:SetSize(486, 1)
    scrollFrame:SetScrollChild(scrollChild)
    hf.scrollChild = scrollChild

    local emptyLabel = scrollBg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyLabel:SetPoint("CENTER", scrollBg, "CENTER", -8, 0)
    emptyLabel:SetWidth(420)
    emptyLabel:SetText("Aún no tienes bots registrados en el historial.\n\nInvoca bots con 'Armar Grupo' y cambia sus talentos en 'Bots en el grupo' para verlos guardados aquí.")
    hf.emptyLabel = emptyLabel

    local footerHint = hf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footerHint:SetPoint("BOTTOMLEFT", 14, 15)
    footerHint:SetText("|cffaaaaaaLos talentos mostrados corresponden a la última rama asignada.|r")

    local closeFooterBtn = CreateFrame("Button", nil, hf, "UIPanelButtonTemplate")
    closeFooterBtn:SetSize(90, 24)
    closeFooterBtn:SetPoint("BOTTOMRIGHT", hf, "BOTTOMRIGHT", -12, 10)
    closeFooterBtn:SetText("Cerrar")
    closeFooterBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        hf:Hide()
    end)

    DungeonBots.historyFrame = hf
    if DB_Internal.RegisterSubModalDimmer then
        DB_Internal.RegisterSubModalDimmer(hf)
    end
end

function DungeonBots:UpdateHistoryUI()
    local hf = DungeonBots.historyFrame
    if not hf then return end

    local list = DungeonBots:GetSortedBotHistory()
    hf.countLabel:SetText("Total guardados: |cffffd200" .. #list .. "|r")

    for _, row in ipairs(historyRows) do
        row:Hide()
    end

    if #list == 0 then
        hf.emptyLabel:Show()
        hf.scrollChild:SetHeight(1)
        return
    end

    hf.emptyLabel:Hide()

    local defaultQuestionIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
    for idx, entry in ipairs(list) do
        local row = historyRows[idx] or CreateHistoryRow(hf.scrollChild, idx)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", hf.scrollChild, "TOPLEFT", 2, -((idx - 1) * 54) - 2)
        row:Show()

        local className, classColor, classIcon = DungeonBots:GetClassDisplayInfo(entry.class)
        local displayIcon = entry.raceIcon
        if not displayIcon or displayIcon == "" or displayIcon == defaultQuestionIcon then
            displayIcon = classIcon
        end
        row.icon:SetTexture(displayIcon)

        local botName = entry.name
        local inParty = (DungeonBots:FindPartyUnitByName(botName) ~= nil)
        if inParty then
            row.nameText:SetText(botName .. "  |cff34c759[En Grupo]|r")
        else
            row.nameText:SetText(botName)
        end
        row.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)

        local cleanSpec = DungeonBots.CleanSpecText and DungeonBots:CleanSpecText(entry.spec) or (entry.spec or "")
        local displaySpec = (cleanSpec ~= "")
            and ((DungeonBots.LocalizeSpecText and DungeonBots:LocalizeSpecText(cleanSpec)) or cleanSpec)
            or ""
        local specText = (displaySpec ~= "") and ("|cff71d5ff" .. displaySpec .. "|r") or "|cff999999Talentos por defecto|r"
        row.detailText:SetText(className .. " - " .. specText)

        if inParty then
            row.inviteBtn:SetText("En Grupo")
            row.inviteBtn:Disable()
            row.inviteBtn:SetScript("OnClick", nil)
            row.inviteBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine("Ya está en tu grupo", 0.3, 1.0, 0.5)
                GameTooltip:AddLine(botName .. " ya se encuentra unido al grupo actual.", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
        else
            row.inviteBtn:SetText("Invitar")
            row.inviteBtn:Enable()
            row.inviteBtn:SetScript("OnClick", function()
                PlaySound("igMainMenuOptionCheckBoxOn")
                DungeonBots:SummonAndInviteHistoryBot(botName)
            end)
            row.inviteBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine("Invitar a " .. botName, 1, 1, 1)
                GameTooltip:AddLine("Ejecuta |cffffd200.playerbots bot add " .. botName .. "|r y lo invita a tu grupo automáticamente.", 0.7, 0.8, 1.0, true)
                GameTooltip:Show()
            end)
        end
        row.inviteBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row.removeBtn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOff")
            DungeonBots:RemoveFromHistory(botName)
        end)
    end

    hf.scrollChild:SetHeight(math.max(1, (#list * 54) + 6))
end

function DungeonBots:ToggleHistoryDialog()
    if not DungeonBots.historyFrame then
        DungeonBots:BuildHistoryDialog()
    end
    DungeonBots:SyncPartyToHistory()
    DungeonBots:UpdateHistoryUI()

    local hf = DungeonBots.historyFrame
    if hf:IsShown() then
        PlaySound("igMainMenuOptionCheckBoxOff")
        hf:Hide()
    else
        PlaySound("igMainMenuOptionCheckBoxOn")
        hf:Show()
        if hf.Raise then
            pcall(hf.Raise, hf)
        end
    end
end
