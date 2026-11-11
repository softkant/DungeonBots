-- =========================================================================
-- DungeonBots_UI.lua: Interfaz Visual Principal, Pestañas y Botón de Minimapa
-- =========================================================================

DungeonBots = DungeonBots or {}

local mainFrame = nil
local activeTab = 1
local tabFrames = {}
local botCards = {}

-- =========================================================================
-- Utilidades de Estilo y Fondos
-- =========================================================================
local function ApplyDarkBackdrop(frame, edgeSize)
    edgeSize = edgeSize or 12
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = edgeSize,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.07, 0.08, 0.11, 0.95)
    frame:SetBackdropBorderColor(0.68, 0.62, 0.44, 1.0)
end

local function ApplyHeaderBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0.12, 0.14, 0.18, 0.95)
    frame:SetBackdropBorderColor(0.35, 0.38, 0.45, 0.8)
end

local function CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, height)
    btn.iconOffsetX = centerIcon and 18 or 7

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", btn, "LEFT", btn.iconOffsetX, 0)
    icon:SetTexture(iconPath)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    local label = btn:GetFontString()
    if not label then
        label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn:SetFontString(label)
    end
    label:ClearAllPoints()
    label:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    label:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
    label:SetJustifyH(centerIcon and "LEFT" or "CENTER")
    btn:SetNormalFontObject("GameFontNormalSmall")
    btn:SetHighlightFontObject("GameFontHighlightSmall")
    btn:SetText(text)
    btn.text = label

    local function UpdateCenteredIcon()
        if not centerIcon then return end
        local textW = label:GetStringWidth() or 0
        if textW > 0 then
            local totalW = 14 + 5 + textW
            btn.iconOffsetX = math.max(7, math.floor((width - totalW) / 2))
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", btn, "LEFT", btn.iconOffsetX, 0)
            label:ClearAllPoints()
            label:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            label:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
        end
    end
    UpdateCenteredIcon()
    if centerIcon then
        btn:HookScript("OnShow", UpdateCenteredIcon)
    end

    btn:SetScript("OnMouseDown", function(self)
        self.icon:SetPoint("LEFT", self, "LEFT", self.iconOffsetX + 1, -1)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self.icon:SetPoint("LEFT", self, "LEFT", self.iconOffsetX, 0)
    end)
    btn:HookScript("OnLeave", function(self)
        self.icon:SetPoint("LEFT", self, "LEFT", self.iconOffsetX, 0)
    end)
    return btn
end

-- =========================================================================
-- Creación de la Ventana Principal
-- =========================================================================
function DungeonBots:InitUI()
    if mainFrame then return end

    local f = CreateFrame("Frame", "DungeonBots_MainFrame", UIParent)
    f:SetSize(620, 552)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")
    f:Hide()

    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    ApplyDarkBackdrop(f, 16)
    tinsert(UISpecialFrames, "DungeonBots_MainFrame")

    -- Barra de Cabecera
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", -6, -6)
    header:SetHeight(28)
    ApplyHeaderBackdrop(header)

    local icon = header:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexture("Interface\\Icons\\Spell_Arcane_MindMastery")

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    title:SetText("|cff00ccffDungeon|r|cffffd200Bots|r  |cff71d5ffAsistente de Mazmorras|r |cff888888v" .. DungeonBots.VERSION .. "|r")

    -- Botón de cerrar
    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("RIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        f:Hide()
    end)

    -- Botón de alternar HUD táctico en la cabecera
    local hudToggleBtn = CreateFrame("Button", nil, header)
    hudToggleBtn:SetSize(20, 20)
    hudToggleBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)

    local hudToggleIcon = hudToggleBtn:CreateTexture(nil, "ARTWORK")
    hudToggleIcon:SetAllPoints()
    hudToggleIcon:SetTexture("Interface\\Icons\\Ability_Warrior_OffensiveStance")
    hudToggleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    hudToggleBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    hudToggleBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:ToggleHUD()
    end)
    hudToggleBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Alternar HUD Táctico Flotante", 1, 1, 1)
        GameTooltip:AddLine("Muestra u oculta la barra rápida de combate para mazmorras.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    hudToggleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Barra de Pestañas
    local tabNames = {
        { id = 1, title = "Armar Grupo", icon = "Interface\\Icons\\INV_Misc_GroupNeedMore" },
        { id = 2, title = "Bots en el grupo (0)", icon = "Interface\\Icons\\INV_Misc_Head_ClockworkGnome_01" },
        { id = 3, title = "Forja / Foso / Cámaras", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
    }

    local tabButtons = {}
    for i, tabData in ipairs(tabNames) do
        local btn = CreateFrame("Button", "DungeonBots_TabBtn_" .. i, f)
        btn:SetSize(190, 26)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", 12 + (i - 1) * 196, -38)
        ApplyHeaderBackdrop(btn)

        local tIcon = btn:CreateTexture(nil, "ARTWORK")
        tIcon:SetSize(16, 16)
        tIcon:SetPoint("LEFT", 8, 0)
        tIcon:SetTexture(tabData.icon)
        tIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local tText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tText:SetPoint("LEFT", tIcon, "RIGHT", 6, 0)
        tText:SetText(tabData.title)
        btn.text = tText

        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        btn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:SelectTab(i)
        end)

        tabButtons[i] = btn
    end
    DungeonBots.tabButtons = tabButtons

    -- Contenedores de las 3 Pestañas
    for i = 1, 3 do
        local tabF = CreateFrame("Frame", "DungeonBots_TabFrame_" .. i, f)
        tabF:SetPoint("TOPLEFT", 10, -68)
        tabF:SetPoint("BOTTOMRIGHT", -10, 10)
        tabF:Hide()
        tabFrames[i] = tabF
    end

    mainFrame = f
    DungeonBots.mainFrame = f

    -- Construir los contenidos de cada pestaña
    DungeonBots:BuildTab1(tabFrames[1])
    DungeonBots:BuildTab2(tabFrames[2])
    DungeonBots:BuildTab3(tabFrames[3])

    -- Seleccionar primera pestaña por defecto
    DungeonBots:SelectTab(1)

    -- Inicializar botón de minimapa
    DungeonBots:InitMinimapButton()

    -- Vincular integración con El Ojo (Buscador de Mazmorras / LFD)
    DungeonBots:HookEye()
    DungeonBots:UpdatePartyUI()
end

function DungeonBots:ToggleUI()
    if not mainFrame then
        DungeonBots:InitUI()
    end
    if DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        PlaySound("igMainMenuOptionCheckBoxOff")
        DungeonBots.reopenMainAfterHistory = false
        DungeonBots.historyFrame:Hide()
        return
    end
    if mainFrame:IsShown() then
        PlaySound("igMainMenuOptionCheckBoxOff")
        DungeonBots.reopenMainAfterHistory = false
        mainFrame:Hide()
    else
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:UpdatePartyUI()
        mainFrame:Show()
    end
end

function DungeonBots:SelectTab(tabIndex)
    activeTab = tabIndex
    for i = 1, 3 do
        if i == tabIndex then
            tabFrames[i]:Show()
            if DungeonBots.tabButtons and DungeonBots.tabButtons[i] then
                DungeonBots.tabButtons[i]:SetBackdropColor(0.20, 0.25, 0.35, 1.0)
                DungeonBots.tabButtons[i]:SetBackdropBorderColor(0.9, 0.8, 0.5, 1.0)
                DungeonBots.tabButtons[i].text:SetTextColor(1, 0.85, 0.2)
            end
        else
            tabFrames[i]:Hide()
            if DungeonBots.tabButtons and DungeonBots.tabButtons[i] then
                DungeonBots.tabButtons[i]:SetBackdropColor(0.12, 0.14, 0.18, 0.95)
                DungeonBots.tabButtons[i]:SetBackdropBorderColor(0.35, 0.38, 0.45, 0.8)
                DungeonBots.tabButtons[i].text:SetTextColor(0.8, 0.8, 0.8)
            end
        end
    end

    if tabIndex == 2 then
        DungeonBots:UpdatePartyUI()
    end
end

-- =========================================================================
-- PESTAÑA 1: ARMAR GRUPO (Party Builder)
-- =========================================================================
function DungeonBots:BuildTab1(parent)
    -- Caja 1: Acceso al Historial de bots
    local historyBox = CreateFrame("Frame", nil, parent)
    historyBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -4)
    historyBox:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -4)
    historyBox:SetHeight(66)
    ApplyDarkBackdrop(historyBox, 10)
    historyBox:SetBackdropColor(0.10, 0.12, 0.16, 0.85)

    local historyTitle = historyBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    historyTitle:SetPoint("TOPLEFT", 10, -8)
    historyTitle:SetText("|cffffd200Historial de bots|r")

    local historySummary = historyBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    historySummary:SetPoint("TOPLEFT", 10, -30)
    historySummary:SetWidth(385)
    historySummary:SetJustifyH("LEFT")
    historySummary:SetText("Lista de bots invitados anteriormente: |cffffd2000|r")
    DungeonBots.historySummaryLabel = historySummary

    local viewHistoryBtn = CreateRedIconButton(historyBox, 180, 28, "Ver Historial de bots", "Interface\\Icons\\INV_Misc_Note_01", true)
    viewHistoryBtn:SetPoint("RIGHT", historyBox, "RIGHT", -12, 0)
    viewHistoryBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:ToggleHistoryDialog()
    end)
    viewHistoryBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Abrir Historial de bots", 1, 1, 1)
        GameTooltip:AddLine("Muestra la lista de bots con los que has jugado, la especialización que tenían y botones para llamarlos e invitarlos uno por uno.", 0.7, 0.8, 1.0, true)
        GameTooltip:Show()
    end)
    viewHistoryBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    DungeonBots:UpdateHistorySummary()

    -- Caja 2: Invocador por Clase
    local classBox = CreateFrame("Frame", nil, parent)
    classBox:SetPoint("TOPLEFT", historyBox, "BOTTOMLEFT", 0, -10)
    classBox:SetPoint("TOPRIGHT", historyBox, "BOTTOMRIGHT", 0, -10)
    classBox:SetHeight(185)
    ApplyDarkBackdrop(classBox, 10)
    classBox:SetBackdropColor(0.10, 0.12, 0.16, 0.85)

    local classTitle = classBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classTitle:SetPoint("TOPLEFT", 10, -8)
    classTitle:SetText("|cffffd200Invocar Bot por Clase Individual|r")

    -- 10 botones de clases distribuidos en 2 filas de 5
    local btnW = 108
    local btnH = 58
    local spacingX = 8
    local spacingY = 8

    for i, cls in ipairs(DungeonBots.CLASSES) do
        local col = ((i - 1) % 5)
        local row = math.floor((i - 1) / 5)

        local cBtn = CreateFrame("Button", "DungeonBots_ClassBtn_" .. cls.id, classBox)
        cBtn:SetSize(btnW, btnH)
        cBtn:SetPoint("TOPLEFT", classBox, "TOPLEFT", 10 + col * (btnW + spacingX), -30 - row * (btnH + spacingY))
        ApplyHeaderBackdrop(cBtn)

        local cColor = RAID_CLASS_COLORS[cls.class] or { r = 0.8, g = 0.8, b = 0.8 }
        cBtn:SetBackdropBorderColor(cColor.r, cColor.g, cColor.b, 0.7)

        local cIcon = cBtn:CreateTexture(nil, "ARTWORK")
        cIcon:SetSize(28, 28)
        cIcon:SetPoint("TOP", 0, -6)
        cIcon:SetTexture(cls.icon)
        cIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local cText = cBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cText:SetPoint("BOTTOM", 0, 6)
        cText:SetText(cls.name)
        cText:SetTextColor(cColor.r, cColor.g, cColor.b)

        cBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        cBtn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:AddClass(cls.id)
        end)

        cBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Invocar " .. cls.name, cColor.r, cColor.g, cColor.b)
            GameTooltip:AddLine("Ejecuta: |cffffd200.playerbots bot addclass " .. cls.id .. "|r", 0.7, 0.8, 1.0)
            GameTooltip:AddLine("\n|cff34c759Si el bot te susurra al aparecer, el addon lo invitará automáticamente al grupo.|r", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        cBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- Caja 3: Acciones Globales de Grupo
    local actionBox = CreateFrame("Frame", nil, parent)
    actionBox:SetPoint("TOPLEFT", classBox, "BOTTOMLEFT", 0, -10)
    actionBox:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 6)
    ApplyDarkBackdrop(actionBox, 10)
    actionBox:SetBackdropColor(0.10, 0.12, 0.16, 0.85)

    local actionTitle = actionBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    actionTitle:SetPoint("TOPLEFT", 10, -8)
    actionTitle:SetText("|cffffd200Control General del Grupo de Bots|r")

    -- Checkbox de Auto-Invite
    local autoInviteCheck = CreateFrame("CheckButton", "DungeonBots_AutoInviteCheck", actionBox, "UICheckButtonTemplate")
    autoInviteCheck:SetSize(24, 24)
    autoInviteCheck:SetPoint("TOPLEFT", 10, -26)
    autoInviteCheck:SetChecked(DungeonBotsDB and DungeonBotsDB.autoInvite)

    local checkText = autoInviteCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    checkText:SetPoint("LEFT", autoInviteCheck, "RIGHT", 4, 0)
    checkText:SetText("Auto-invitar bots que te susurren al crearse (Recomendado)")

    autoInviteCheck:SetScript("OnClick", function(self)
        local val = self:GetChecked() and true or false
        if DungeonBotsDB then DungeonBotsDB.autoInvite = val end
        PlaySound(val and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        DungeonBots:Print("Auto-invite de bots: " .. (val and "|cff34c759Activado|r" or "|cffff3b30Desactivado|r"))
    end)

    -- Checkbox de Barra Táctica solo en Mazmorras de 5 jugadores
    local hudDungeonCheck = CreateFrame("CheckButton", "DungeonBots_HudDungeonCheck", actionBox, "UICheckButtonTemplate")
    hudDungeonCheck:SetSize(24, 24)
    hudDungeonCheck:SetPoint("TOPLEFT", 10, -50)
    hudDungeonCheck:SetChecked(not DungeonBotsDB or DungeonBotsDB.hudOnlyInDungeon ~= false)

    local hudCheckText = hudDungeonCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hudCheckText:SetPoint("LEFT", hudDungeonCheck, "RIGHT", 4, 0)
    hudCheckText:SetText("Mostrar barra táctica inferior solo dentro de mazmorras de 5 jugadores")

    hudDungeonCheck:SetScript("OnClick", function(self)
        local val = self:GetChecked() and true or false
        if DungeonBotsDB then DungeonBotsDB.hudOnlyInDungeon = val end
        PlaySound(val and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        if DungeonBots.UpdateHUDVisibility then
            DungeonBots:UpdateHUDVisibility()
        end
        DungeonBots:Print("Barra táctica solo en mazmorra (5j): " .. (val and "|cff34c759Activado|r" or "|cffffb020Desactivado|r"))
    end)

    -- Checkbox principal para ocultar susurros de bots
    local muteWhispersCheck = CreateFrame("CheckButton", "DungeonBots_MuteWhispersCheck", actionBox, "UICheckButtonTemplate")
    muteWhispersCheck:SetSize(24, 24)
    muteWhispersCheck:SetPoint("TOPLEFT", 10, -74)
    muteWhispersCheck:SetChecked(not DungeonBotsDB or DungeonBotsDB.whisperMuteMode ~= "off")

    local muteWhispersText = muteWhispersCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    muteWhispersText:SetPoint("LEFT", muteWhispersCheck, "RIGHT", 4, 0)
    muteWhispersText:SetText("Ocultar susurros de bots en el chat")

    muteWhispersCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Ocultar Susurros de Bots", 1, 1, 1)
        GameTooltip:AddLine("Oculta todos los susurros entrantes y salientes con cualquier personaje identificado como bot.\n\nLos jugadores humanos reales ([JUGADOR] o desconocidos) NUNCA se ocultan.", 0.75, 0.85, 1.0, true)
        GameTooltip:Show()
    end)
    muteWhispersCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Checkbox dependiente para silenciar /p, /y y /s de bots (solo visible si el anterior está activo)
    local muteGroupCheck = CreateFrame("CheckButton", "DungeonBots_MuteGroupChatCheck", actionBox, "UICheckButtonTemplate")
    muteGroupCheck:SetSize(24, 24)
    muteGroupCheck:SetPoint("TOPLEFT", 26, -98)
    muteGroupCheck:SetChecked(DungeonBotsDB and DungeonBotsDB.muteBotGroupChat)

    local muteGroupText = muteGroupCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    muteGroupText:SetPoint("LEFT", muteGroupCheck, "RIGHT", 4, 0)
    muteGroupText:SetText("Ocultar también mensajes de bots en Grupo (/p), Grito (/y) y Decir (/s)")

    muteGroupCheck:SetScript("OnClick", function(self)
        local val = self:GetChecked() and true or false
        if DungeonBotsDB then DungeonBotsDB.muteBotGroupChat = val end
        PlaySound(val and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        DungeonBots:Print("Ocultar chat de bots en Grupo/Decir: " .. (val and "|cff34c759Activado|r" or "|cffffb020Desactivado|r"))
    end)

    -- Subtítulo de acciones rápidas
    local quickActionsLabel = actionBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    quickActionsLabel:SetText("|cffaaaaaaAcciones rápidas de grupo:|r")

    -- Fila única compacta con los 4 botones rojos clásicos e icono por función
    local addAllBtn = CreateRedIconButton(
        actionBox, 134, 24, "Reinvocar Grupo",
        "Interface\\Icons\\Spell_Nature_AstralRecalGroup"
    )

    local function UpdateMuteOptionsVisibility()
        local isEnabled = (not DungeonBotsDB) or (DungeonBotsDB.whisperMuteMode ~= "off")
        quickActionsLabel:ClearAllPoints()
        addAllBtn:ClearAllPoints()
        if isEnabled then
            muteGroupCheck:Show()
            quickActionsLabel:SetPoint("TOPLEFT", 12, -130)
            addAllBtn:SetPoint("TOPLEFT", 11, -148)
            if mainFrame then
                mainFrame:SetHeight(548)
            end
        else
            muteGroupCheck:Hide()
            quickActionsLabel:SetPoint("TOPLEFT", 12, -106)
            addAllBtn:SetPoint("TOPLEFT", 11, -124)
            if mainFrame then
                mainFrame:SetHeight(524)
            end
        end
    end

    muteWhispersCheck:SetScript("OnClick", function(self)
        local val = self:GetChecked() and true or false
        if DungeonBotsDB then
            DungeonBotsDB.whisperMuteMode = val and "all" or "off"
        end
        PlaySound(val and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        if val and DungeonBots.CloseBotWIMWindows then
            DungeonBots:CloseBotWIMWindows()
        end
        UpdateMuteOptionsVisibility()
        DungeonBots:Print("Ocultar susurros de bots: " .. (val and "|cff34c759Activado|r" or "|cffffb020Desactivado|r"))
    end)

    UpdateMuteOptionsVisibility()
    addAllBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:AddAllBots()
    end)
    addAllBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Reinvocar a Todos los Bots", 1, 1, 1)
        GameTooltip:AddLine("Ejecuta: |cffffd200.playerbots bot add *|r y los teletransporta a tu posición.", 0.7, 0.8, 1.0, true)
        GameTooltip:AddLine("\n|cffffd200Nota:|r Solo funciona con bots que aún siguen en tu grupo pero se fueron por alguna razón (relogueo, al pasar el minuto fuera de mazmorra o desconexión). Si ya fueron sacados del grupo, llámalos desde 'Ver Historial de bots'.", 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    addAllBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local removeAllBtn = CreateRedIconButton(
        actionBox, 134, 24, "Despedir a Todos",
        "Interface\\Icons\\Spell_ChargeNegative"
    )
    removeAllBtn:SetPoint("LEFT", addAllBtn, "RIGHT", 10, 0)
    removeAllBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        DungeonBots:RemoveAllBots()
    end)
    removeAllBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Despedir a Todo el Grupo", 1, 0.3, 0.3)
        GameTooltip:AddLine("Ejecuta: |cffffd200.playerbots bot remove *|r para guardar y retirar a los bots, y los saca del grupo automáticamente.", 0.7, 0.8, 1.0, true)
        GameTooltip:Show()
    end)
    removeAllBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local repairBtn = CreateRedIconButton(
        actionBox, 134, 24, "Reparar Equipo",
        "Interface\\Icons\\Trade_BlackSmithing"
    )
    repairBtn:SetPoint("LEFT", removeAllBtn, "RIGHT", 10, 0)
    repairBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:SendPartyCommand("repair")
        DungeonBots:Print("Ordenando a los bots reparar su equipo...")
    end)
    repairBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Reparar Equipo (/p repair)", 1, 1, 1)
        GameTooltip:AddLine("Ordena a los bots reparar todas sus piezas si estás cerca de un PNJ reparador o montura.", 0.7, 0.8, 1.0, true)
        GameTooltip:Show()
    end)
    repairBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local releaseBtn = CreateRedIconButton(
        actionBox, 134, 24, "Liberar alma",
        "Interface\\Icons\\Spell_Holy_GuardianSpirit"
    )
    releaseBtn:SetPoint("LEFT", repairBtn, "RIGHT", 10, 0)
    releaseBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        DungeonBots:SendPartyCommand("release")
        DungeonBots:Print("Ordenando a los bots caídos liberar su alma...")
    end)
    releaseBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Liberar Alma (/p release)", 1, 1, 1)
        GameTooltip:AddLine("Fuerza a los bots muertos a liberar su espíritu.", 0.7, 0.8, 1.0, true)
        GameTooltip:AddLine("\n|cffff3b30ADVERTENCIA:|r El bot liberará espíritu pero se quedará esperando en el cementerio.", 1, 0.35, 0.35, true)
        GameTooltip:Show()
    end)
    releaseBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
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
    hf:SetFrameLevel(20)
    hf:SetMovable(true)
    hf:EnableMouse(true)
    hf:RegisterForDrag("LeftButton")
    hf:SetScript("OnDragStart", hf.StartMoving)
    hf:SetScript("OnDragStop", hf.StopMovingOrSizing)
    hf:SetScript("OnHide", function()
        if DungeonBots.reopenMainAfterHistory and mainFrame and not mainFrame:IsShown() then
            DungeonBots.reopenMainAfterHistory = false
            DungeonBots:UpdatePartyUI()
            mainFrame:Show()
        end
    end)
    hf:Hide()
    ApplyDarkBackdrop(hf, 14)
    hf:SetBackdropColor(0.04, 0.05, 0.08, 1.0)

    local solidBg = hf:CreateTexture(nil, "BACKGROUND")
    solidBg:SetPoint("TOPLEFT", hf, "TOPLEFT", 4, -4)
    solidBg:SetPoint("BOTTOMRIGHT", hf, "BOTTOMRIGHT", -4, 4)
    solidBg:SetTexture(0.04, 0.05, 0.08, 1.0)

    table.insert(UISpecialFrames, "DungeonBots_HistoryFrame")

    -- Barra de título
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

    -- Barra superior con contador y acciones
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

    -- Contenedor con ScrollFrame
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

    -- Pie del diálogo
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
        local specText = (cleanSpec ~= "") and ("|cff71d5ff" .. cleanSpec .. "|r") or "|cff999999Talentos por defecto|r"
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

    if DungeonBots.historyFrame:IsShown() then
        PlaySound("igMainMenuOptionCheckBoxOff")
        DungeonBots.historyFrame:Hide()
    else
        PlaySound("igMainMenuOptionCheckBoxOn")
        if mainFrame and mainFrame:IsShown() then
            DungeonBots.reopenMainAfterHistory = true
            mainFrame:Hide()
        else
            DungeonBots.reopenMainAfterHistory = false
        end
        DungeonBots.historyFrame:Show()
    end
end

-- =========================================================================
-- UTILIDAD COMPARTIDA PARA HIPERVINCULOS (Misiones / Objetos / Hechizos)
-- =========================================================================
local function SafeShowLinkTooltip(owner, linkRef, displayLink, title, rawLine)
    if linkRef and linkRef ~= "" and SetItemRef then
        local ok = pcall(SetItemRef, linkRef, displayLink or title or linkRef, "LeftButton")
        if ok and ItemRefTooltip and ItemRefTooltip:IsShown() then
            return
        end
    end
    if owner then
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title or "Detalle", 1, 0.85, 0.2, true)
        if rawLine and rawLine ~= "" then
            GameTooltip:AddLine(DungeonBots:StripChatFormatting(rawLine), 0.85, 0.90, 1.0, true)
        end
        GameTooltip:Show()
    end
end

-- =========================================================================
-- VENTANA DE DIÁLOGO: MISIONES DEL BOT (quests all / drop)
-- =========================================================================
local questRows = {}

local function CreateQuestRow(parent, idx)
    local row = CreateFrame("Frame", nil, parent)
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
    titleBtn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -116, 2)
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

    local dropBtn = CreateRedIconButton(row, 104, 22, "Abandonar", "Interface\\Icons\\Spell_ChargeNegative")
    dropBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.dropBtn = dropBtn

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
    title:SetText("|cff00ccffMisiones del|r |cffffd200Bot|r")
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
            DungeonBots:QueryQuests(qf.currentBot, true)
        end
    end)

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
    footerHint:SetText("|cffaaaaaaHaz clic en una misión para ver detalles o pulsa 'Abandonar'.|r")

    local closeFooterBtn = CreateFrame("Button", nil, qf, "UIPanelButtonTemplate")
    closeFooterBtn:SetSize(90, 24)
    closeFooterBtn:SetPoint("BOTTOMRIGHT", qf, "BOTTOMRIGHT", -12, 10)
    closeFooterBtn:SetText("Cerrar")
    closeFooterBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        qf:Hide()
    end)

    DungeonBots.questFrame = qf
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
    qf.title:SetText("|cff00ccffMisiones de|r |cffffd200" .. targetBot .. "|r")

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

        row.dropBtn:Show()
        row.dropBtn:SetScript("OnClick", function()
            PlaySound("igQuestLogAbandonQuest")
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

    local acceptBtn = CreateRedIconButton(row, 96, 20, "Aceptar", "Interface\\Icons\\INV_Misc_Book_09")
    acceptBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    acceptBtn:Hide()
    row.acceptBtn = acceptBtn

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

    local npcLabel = tf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    npcLabel:SetPoint("TOPLEFT", 14, -44)
    npcLabel:SetWidth(310)
    npcLabel:SetJustifyH("LEFT")
    npcLabel:SetWordWrap(false)
    npcLabel:SetText("PNJ: |cffffd200Objetivo actual|r")
    tf.npcLabel = npcLabel

    local acceptAllBtn = CreateFrame("Button", nil, tf, "UIPanelButtonTemplate")
    acceptAllBtn:SetSize(88, 22)
    acceptAllBtn:SetPoint("TOPRIGHT", tf, "TOPRIGHT", -108, -40)
    acceptAllBtn:SetText("Aceptar *")
    acceptAllBtn:SetScript("OnClick", function()
        if tf.currentBot then
            DungeonBots:SendTalkCommand(tf.currentBot, "accept *")
        end
    end)

    local requeryBtn = CreateFrame("Button", nil, tf, "UIPanelButtonTemplate")
    requeryBtn:SetSize(92, 22)
    requeryBtn:SetPoint("TOPRIGHT", tf, "TOPRIGHT", -12, -40)
    requeryBtn:SetText("Reconsultar")
    requeryBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if tf.currentBot then
            DungeonBots:SendTalkCommand(tf.currentBot, "talk")
        end
    end)

    -- Lista principal de opciones y misiones detectadas (1 clic)
    local optTitle = tf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    optTitle:SetPoint("TOPLEFT", tf, "TOPLEFT", 14, -68)
    optTitle:SetText("|cffffd200Opciones y Misiones del PNJ:|r |cff888888(clic para ver o interactuar)|r")

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

    -- Zona inferior: pista + acceso a Registro Misiones + Cerrar
    local footerHint = tf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footerHint:SetPoint("BOTTOMLEFT", 14, 15)
    footerHint:SetWidth(268)
    footerHint:SetJustifyH("LEFT")
    footerHint:SetWordWrap(false)
    footerHint:SetText("|cffaaaaaaUsa |cffffd200/w Bot talk|r o |cffffd200/db talk|r tras elegir un PNJ.|r")

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
            GameTooltip:AddLine("Abre la ventana de misiones activas de " .. tf.currentBot .. " (quests all).", 0.8, 0.9, 1.0, true)
        else
            GameTooltip:AddLine("Abre las misiones activas del bot seleccionado.", 0.8, 0.9, 1.0, true)
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

    DungeonBots.talkFrame = tf
end

local TALK_QUEST_STYLE = {
    available = {
        prefix = "|cff34c759[Disponible]|r ",
        showBtn = true,
        btnText = "Aceptar",
        rightBadge = nil,
        border = { 0.25, 0.85, 0.45, 1.0 },
        tipStatus = "Disponible",
        tipColor = { 0.2, 0.9, 0.45 },
        tipHint = "El bot puede tomar esta misión. Pulsa 'Aceptar' o haz clic para inspeccionarla.",
    },
    incompleted = {
        prefix = "|cffff5544[Incompleta]|r ",
        showBtn = false,
        btnText = nil,
        rightBadge = "|cffff9f0aEn curso|r",
        border = { 1.0, 0.55, 0.25, 1.0 },
        tipStatus = "Incompleta (En curso)",
        tipColor = { 1.0, 0.45, 0.3 },
        tipHint = "El bot ya tomó esta misión y aún está en progreso. Clic para ver detalles.",
    },
    completed = {
        prefix = "|cff00ccff[Completa]|r ",
        showBtn = true,
        btnText = "Entregar",
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
    local npcTitle = (data and data.npcName and data.npcName ~= "") and data.npcName or "PNJ seleccionado"
    local statusTag = (data and data.loading) and "|cff71d5ff[Consultando...]|r" or "|cff34c759[Listo]|r"
    tf.npcLabel:SetText("PNJ: |cffffd200" .. npcTitle .. "|r  " .. statusTag)

    local lines = (data and data.lines) or {}
    local actions = (data and data.actions) or {}

    for _, row in ipairs(talkActionRows) do
        row:Hide()
    end

    if #actions == 0 then
        if data and data.loading then
            if data.isAcceptCmd then
                tf.emptyOptLabel:SetText("|cff71d5ffAceptando misión con " .. targetBot .. "...|r")
            else
                tf.emptyOptLabel:SetText("|cff71d5ffConsultando opciones y misiones del PNJ con " .. targetBot .. "...|r")
            end
        elseif data and data.isAcceptCmd and not data.acceptError then
            if #lines > 0 then
                local cleanFallback = DungeonBots:StripChatFormatting(lines[#lines])
                tf.emptyOptLabel:SetText("|cff34c759" .. cleanFallback .. "|r")
            else
                tf.emptyOptLabel:SetText("|cff34c759Misión aceptada.|r Actualizando diálogo del PNJ...")
            end
        elseif data and data.acceptError and #lines > 0 then
            local cleanFallback = DungeonBots:StripChatFormatting(lines[#lines])
            tf.emptyOptLabel:SetText("|cffff5544No se pudo aceptar la misión:|r\n\n|cffffaaaa" .. cleanFallback .. "|r")
        elseif #lines > 0 then
            local cleanFallback = DungeonBots:StripChatFormatting(lines[#lines])
            tf.emptyOptLabel:SetText("No se detectaron opciones ni misiones disponibles.\n\n|cffaaaaaa(" .. cleanFallback .. ")|r")
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
                row.mainBtn:ClearAllPoints()
                row.mainBtn:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -2)
                row.mainBtn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -104, 2)
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

                if style.showBtn then
                    row.statusTag:Hide()
                    row.acceptBtn:SetText(style.btnText or "Aceptar")
                    row.acceptBtn:Show()
                    row.acceptBtn:SetScript("OnClick", function()
                        DungeonBots:SendTalkCommand(targetBot, act.acceptCmd)
                    end)
                else
                    row.acceptBtn:Hide()
                    row.statusTag:SetText(style.rightBadge or "")
                    row.statusTag:Show()
                end
            else
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

-- =========================================================================
-- PESTAÑA 2: TALENTOS Y EQUIPO (Bot Manager)
-- =========================================================================
function DungeonBots:BuildTab2(parent)
    -- Barra superior de herramientas: Escanear grupo y ayuda
    local topBar = CreateFrame("Frame", nil, parent)
    topBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -4)
    topBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -4)
    topBar:SetHeight(28)
    ApplyDarkBackdrop(topBar, 8)
    topBar:SetBackdropColor(0.10, 0.12, 0.16, 0.85)

    local scanBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    scanBtn:SetSize(145, 22)
    scanBtn:SetPoint("LEFT", topBar, "LEFT", 6, 0)
    scanBtn:SetText("¿Quién es bot?")
    scanBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:ScanPartyBots()
    end)
    scanBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("¿Quién es bot?", 1, 1, 1)
        GameTooltip:AddLine("Envía una consulta discreta ('follow info') por susurro a los miembros sin verificar para saber quién responde automáticamente como bot y quién es un jugador real.", 0.7, 0.8, 1.0, true)
        GameTooltip:AddLine("\nLos bots responden solos en el chat y quedan marcados como [BOT]. También puedes pulsar la etiqueta de cada tarjeta para cambiarlo manualmente.", 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    scanBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local scanHelp = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    scanHelp:SetPoint("LEFT", scanBtn, "RIGHT", 10, 0)
    scanHelp:SetText("|cff888888Pulsa la etiqueta |cff00e5ff[BOT]|r o |cffffb020[JUGADOR]|r para cambiar el rol manualmente.|r")

    local emptyLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyLabel:SetPoint("CENTER", parent, "CENTER", 0, 20)
    emptyLabel:SetText("|cff888888No hay bots detectados en tu grupo actualmente.\n\nInvoca bots desde la pestaña 'Armar Grupo' para configurar\nsus talentos, roles y equipo.|r")
    DungeonBots.emptyPartyLabel = emptyLabel

    local cardContainer = CreateFrame("Frame", nil, parent)
    cardContainer:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -4)
    cardContainer:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    DungeonBots.cardContainer = cardContainer

    -- Crear 4 tarjetas de bots para las unidades party1 a party4
    for i = 1, 4 do
        local card = CreateFrame("Frame", "DungeonBots_BotCard_" .. i, cardContainer)
        card:SetSize(588, 86)
        card:SetPoint("TOPLEFT", cardContainer, "TOPLEFT", 6, -2 - (i - 1) * 92)
        ApplyDarkBackdrop(card, 10)
        card:SetBackdropColor(0.10, 0.12, 0.16, 0.90)

        -- Icono de raza y género
        local cIcon = card:CreateTexture(nil, "ARTWORK")
        cIcon:SetSize(38, 38)
        cIcon:SetPoint("LEFT", 10, 0)
        cIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        cIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        card.classIcon = cIcon

        -- Nombre del bot
        local nameText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("TOPLEFT", cIcon, "TOPRIGHT", 10, 8)
        nameText:SetText("Bot " .. i)
        card.nameText = nameText

        -- Información de rol / nivel
        local infoText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        infoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
        infoText:SetText("Nivel 80")
        card.infoText = infoText

        -- Etiqueta interactiva BOT / JUGADOR
        local botBadge = CreateFrame("Button", nil, card)
        botBadge:SetSize(86, 18)
        botBadge:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -6)
        ApplyHeaderBackdrop(botBadge)
        local badgeText = botBadge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        badgeText:SetPoint("CENTER", 0, 0)
        badgeText:SetText("[ BOT ]")
        botBadge.text = badgeText
        card.botBadge = botBadge

        -- Aviso para Jugador Humano Real
        local humanNotice = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        humanNotice:SetPoint("LEFT", card, "LEFT", 195, 0)
        humanNotice:SetPoint("RIGHT", card, "RIGHT", -15, 0)
        humanNotice:SetJustifyH("LEFT")
        humanNotice:SetText("|cffffb020Jugador humano real.|r\n|cff888888Las opciones de control de bot están inactivas para este miembro.|r")
        humanNotice:Hide()
        card.humanNotice = humanNotice

        -- DropDown de Especializaciones Dinámicas (Specs)
        local specDropDown = CreateFrame("Frame", "DungeonBots_SpecDropDown_" .. i, card, "UIDropDownMenuTemplate")
        specDropDown:SetPoint("TOPLEFT", card, "TOPLEFT", 175, -10)
        UIDropDownMenu_SetWidth(specDropDown, 185)
        UIDropDownMenu_JustifyText(specDropDown, "LEFT")
        card.specDropDown = specDropDown

        -- Botones de Equipo debajo del DropDown
        local matchGearBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        matchGearBtn:SetSize(118, 22)
        matchGearBtn:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 193, 12)
        matchGearBtn:SetText("Adaptar Equipo")
        card.matchGearBtn = matchGearBtn

        local blueGearBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        blueGearBtn:SetSize(114, 22)
        blueGearBtn:SetPoint("LEFT", matchGearBtn, "RIGHT", 6, 0)
        blueGearBtn:SetText("Equipar Azul")
        card.blueGearBtn = blueGearBtn

        -- Botón Misiones (quests all) arriba de Despedir
        local questsBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        questsBtn:SetSize(120, 24)
        questsBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -16)
        questsBtn:SetText("Misiones")
        card.questsBtn = questsBtn

        -- Botón Despedir bot individual
        local kickBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        kickBtn:SetSize(120, 24)
        kickBtn:SetPoint("TOP", questsBtn, "BOTTOM", 0, -6)
        kickBtn:SetText("Despedir")
        card.kickBtn = kickBtn

        card:Hide()
        botCards[i] = card
    end
end

-- Actualiza la lista de miembros y sus tarjetas
function DungeonBots:UpdatePartyUI()
    local numMembers = GetNumPartyMembers()
    local botCount = 0
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local memberName = UnitName(unit)
            if memberName and memberName ~= "" and DungeonBots:ShouldTreatAsBot(memberName) then
                botCount = botCount + 1
            end
        end
    end

    if DungeonBots.tabButtons and DungeonBots.tabButtons[2] and DungeonBots.tabButtons[2].text then
        DungeonBots.tabButtons[2].text:SetText("Bots en el grupo (" .. botCount .. ")")
    end

    DungeonBots:SyncPartyToHistory()

    if numMembers == 0 then
        if DungeonBots.emptyPartyLabel then DungeonBots.emptyPartyLabel:Show() end
        for i = 1, 4 do
            if botCards[i] then botCards[i]:Hide() end
        end
        return
    end

    if DungeonBots.emptyPartyLabel then DungeonBots.emptyPartyLabel:Hide() end

    for i = 1, 4 do
        local unit = "party" .. i
        local card = botCards[i]
        if card then
            if UnitExists(unit) then
                card:Show()
                local name = UnitName(unit)
                local _, classToken = UnitClass(unit)
                local level = UnitLevel(unit)

                local classColor = (classToken and RAID_CLASS_COLORS[classToken]) or { r = 1, g = 1, b = 1 }

                card.nameText:SetText(name)
                card.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
                card.infoText:SetText("Nivel " .. (level > 0 and level or 80) .. " (" .. (classToken or "Clase") .. ")")

                -- Identificación de Bot vs Jugador Humano (solo bot si fue agregado recientemente, está en historial o fue confirmado)
                local isBot = DungeonBots:ShouldTreatAsBot(name)

                -- Icono oficial de Raza y Género
                local raceIcon = DungeonBots:GetRaceIcon(unit)
                card.classIcon:SetTexture(raceIcon)
                card.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                if isBot then
                    card.botBadge.text:SetText("|cff00e5ff[ BOT ]|r")
                    card.botBadge:SetBackdropBorderColor(0.2, 0.8, 1.0, 0.9)
                    card.botBadge:SetBackdropColor(0.08, 0.16, 0.22, 0.95)
                    card.humanNotice:Hide()
                    card.specDropDown:Show()
                    card.matchGearBtn:Show()
                    card.blueGearBtn:Show()
                    card.questsBtn:Show()
                    card.kickBtn:Show()
                else
                    card.botBadge.text:SetText("|cffffb020[ JUGADOR ]|r")
                    card.botBadge:SetBackdropBorderColor(1.0, 0.7, 0.2, 0.9)
                    card.botBadge:SetBackdropColor(0.20, 0.14, 0.08, 0.95)
                    card.humanNotice:Show()
                    card.specDropDown:Hide()
                    card.matchGearBtn:Hide()
                    card.blueGearBtn:Hide()
                    card.questsBtn:Hide()
                    card.kickBtn:Hide()
                end

                card.botBadge:SetScript("OnClick", function()
                    PlaySound("igMainMenuOptionCheckBoxOn")
                    DungeonBots:ToggleUnitBotStatus(name)
                end)

                card.botBadge:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    if isBot then
                        GameTooltip:AddLine("Clasificado como: |cff00e5ffBOT|r", 1, 1, 1)
                        GameTooltip:AddLine("Control total activo (talentos, equipo y despido).", 0.7, 0.8, 1.0)
                        GameTooltip:AddLine("\n|cffffd200Haz clic aquí si este miembro es un jugador real.|r", 1, 0.8, 0.2)
                    else
                        GameTooltip:AddLine("Clasificado como: |cffffb020JUGADOR HUMANO|r", 1, 1, 1)
                        GameTooltip:AddLine("Los controles automáticos están pausados para no afectarlo.", 0.7, 0.8, 1.0)
                        GameTooltip:AddLine("\n|cffffd200Haz clic aquí si este miembro es un bot.|r", 1, 0.8, 0.2)
                    end
                    GameTooltip:Show()
                end)
                card.botBadge:SetScript("OnLeave", function() GameTooltip:Hide() end)

                -- Configurar DropDown dinámico de ramas oficiales (según servidor)
                local currentBotName = name
                local activeSpec = DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[currentBotName]
                if activeSpec and activeSpec ~= "" and DungeonBots.CanonicalizeSpec then
                    activeSpec = DungeonBots:CanonicalizeSpec(currentBotName, activeSpec)
                end
                local resolvedSpecs = (DungeonBots.botSpecs and DungeonBots.botSpecs[currentBotName])
                if (not resolvedSpecs or #resolvedSpecs == 0) and classToken and DungeonBots.DEFAULT_CLASS_SPECS then
                    resolvedSpecs = DungeonBots.DEFAULT_CLASS_SPECS[classToken]
                end

                UIDropDownMenu_Initialize(card.specDropDown, function(self, level)
                    local specs = (DungeonBots.botSpecs and DungeonBots.botSpecs[currentBotName])
                    if (not specs or #specs == 0) and classToken and DungeonBots.DEFAULT_CLASS_SPECS then
                        specs = DungeonBots.DEFAULT_CLASS_SPECS[classToken]
                    end

                    local currentActive = DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[currentBotName]
                    if currentActive and currentActive ~= "" and DungeonBots.CanonicalizeSpec then
                        currentActive = DungeonBots:CanonicalizeSpec(currentBotName, currentActive)
                    end
                    local optionList = {}
                    local seen = {}
                    if currentActive and currentActive ~= "" then
                        table.insert(optionList, currentActive)
                        seen[string.lower(currentActive)] = true
                    end
                    if specs then
                        for _, s in ipairs(specs) do
                            local ls = string.lower(s)
                            if not seen[ls] then
                                table.insert(optionList, s)
                                seen[ls] = true
                            end
                        end
                    end

                    if #optionList == 0 then
                        local infoHint = UIDropDownMenu_CreateInfo()
                        infoHint.text = "Sin ramas cargadas"
                        infoHint.disabled = true
                        UIDropDownMenu_AddButton(infoHint, level)
                        return
                    end

                    local infoHeader = UIDropDownMenu_CreateInfo()
                    infoHeader.text = "-- Ramas Disponibles --"
                    infoHeader.isTitle = true
                    UIDropDownMenu_AddButton(infoHeader, level)

                    for _, specName in ipairs(optionList) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = specName
                        info.value = specName
                        info.checked = (currentActive and string.lower(specName) == string.lower(currentActive)) or false
                        info.func = function()
                            UIDropDownMenu_SetSelectedValue(card.specDropDown, specName)
                            UIDropDownMenu_SetText(card.specDropDown, specName)
                            if DungeonBotsDB then
                                DungeonBotsDB.botActiveSpec = DungeonBotsDB.botActiveSpec or {}
                                DungeonBotsDB.botActiveSpec[currentBotName] = specName
                            end
                            DungeonBots:SetBotSpec(currentBotName, specName)
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end
                end)

                if activeSpec and activeSpec ~= "" then
                    UIDropDownMenu_SetSelectedValue(card.specDropDown, activeSpec)
                    UIDropDownMenu_SetText(card.specDropDown, activeSpec)
                elseif DungeonBots.pendingSpecReset and DungeonBots.pendingSpecReset[currentBotName] then
                    UIDropDownMenu_SetSelectedValue(card.specDropDown, nil)
                    UIDropDownMenu_SetText(card.specDropDown, "Consultando talentos...")
                else
                    UIDropDownMenu_SetSelectedValue(card.specDropDown, nil)
                    UIDropDownMenu_SetText(card.specDropDown, "Sin detectar")
                end

                -- Botón Misiones (quests all)
                card.questsBtn:SetScript("OnClick", function()
                    PlaySound("igMainMenuOptionCheckBoxOn")
                    DungeonBots:QueryQuests(name)
                end)
                card.questsBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine("Misiones del Bot (quests all)", 1, 1, 1)
                    GameTooltip:AddLine("Consulta 'quests all' y abre una ventana interactiva con las misiones del bot para ver sus detalles o abandonarlas.", 0.7, 0.8, 1.0, true)
                    GameTooltip:Show()
                end)
                card.questsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                -- Botón Adaptar Equipo
                card.matchGearBtn:SetScript("OnClick", function()
                    PlaySound("igMainMenuOptionCheckBoxOn")
                    DungeonBots:AutogearMatch(name)
                end)
                card.matchGearBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine("Adaptar Equipo (Autogear Match)", 1, 0.8, 0.2)
                    GameTooltip:AddLine("Ajusta su armadura a la rama de talentos activa.", 1, 1, 1)
                    GameTooltip:AddLine("\n|cffff3b30CUIDADO:|r Esto puede reducir drásticamente el Item Level de varias o todas sus piezas.", 1, 0.3, 0.3, true)
                    GameTooltip:Show()
                end)
                card.matchGearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                -- Botón Equipar Azul
                card.blueGearBtn:SetScript("OnClick", function()
                    PlaySound("igMainMenuOptionCheckBoxOn")
                    DungeonBots:AutogearBlue(name)
                end)
                card.blueGearBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine("Equipar Objetos Azules (Autogear Blue)", 0.2, 0.8, 1.0)
                    GameTooltip:AddLine("Equipa al bot con un conjunto completo de calidad rara (azul).", 0.7, 0.7, 0.7, true)
                    GameTooltip:Show()
                end)
                card.blueGearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                -- Botón Despedir
                card.kickBtn:SetScript("OnClick", function()
                    PlaySound("igMainMenuOptionCheckBoxOff")
                    DungeonBots:RemoveBot(name)
                end)
                card.kickBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine("Despedir Bot", 1, 0.3, 0.3)
                    GameTooltip:AddLine("Remueve a " .. name .. " del mundo, guarda su estado y lo saca del grupo.", 0.7, 0.7, 0.7, true)
                    GameTooltip:Show()
                end)
                card.kickBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            else
                card:Hide()
            end
        end
    end
end

-- =========================================================================
-- PESTAÑA 3: FORJA / FOSO / CÁMARAS (ICC 5-Man Wizard)
-- =========================================================================
function DungeonBots:BuildTab3(parent)
    -- Caja de Información y Advertencia
    local infoBox = CreateFrame("Frame", nil, parent)
    infoBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -4)
    infoBox:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -4)
    infoBox:SetHeight(78)
    ApplyDarkBackdrop(infoBox, 10)
    infoBox:SetBackdropColor(0.12, 0.10, 0.08, 0.90)
    infoBox:SetBackdropBorderColor(1.0, 0.6, 0.2, 0.9)

    local infoTitle = infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoTitle:SetPoint("TOPLEFT", 10, -8)
    infoTitle:SetText("|cffffd200Cadena de Misiones de ICC (Forja de Almas, Foso de Saron y Cámaras)|r")

    local infoDesc = infoBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoDesc:SetPoint("TOPLEFT", 10, -26)
    infoDesc:SetPoint("TOPRIGHT", -10, -26)
    infoDesc:SetJustifyH("LEFT")
    infoDesc:SetText("Para que los bots puedan entrar a Foso de Saron y Cámaras de Reflexión, es obligatorio que completen la cadena que inicia en Dalaran.\n|cffff3b30REGLA DEL SERVIDOR:|r Los bots fuera de mazmorra |cffff3b30desaparecen exactamente en 1 minuto (60s)|r.")

    -- Barra de Cuenta Regresiva de Dalaran
    local timerBar = CreateFrame("StatusBar", "DungeonBots_DalaranTimerBar", parent)
    timerBar:SetPoint("TOPLEFT", infoBox, "BOTTOMLEFT", 0, -8)
    timerBar:SetPoint("TOPRIGHT", infoBox, "BOTTOMRIGHT", 0, -8)
    timerBar:SetHeight(22)
    timerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    timerBar:SetStatusBarColor(0.2, 0.8, 0.2)
    timerBar:SetMinMaxValues(0, 60)
    timerBar:SetValue(0)

    local timerBg = timerBar:CreateTexture(nil, "BACKGROUND")
    timerBg:SetAllPoints()
    timerBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    timerBg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    local timerText = timerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerText:SetPoint("CENTER", 0, 0)
    timerText:SetText("Temporizador de Dalaran: Inactivo")
    timerBar.text = timerText
    DungeonBots.dalaranTimerBar = timerBar

    -- =================== PASO 1 ===================
    local step1Box = CreateFrame("Frame", nil, parent)
    step1Box:SetPoint("TOPLEFT", timerBar, "BOTTOMLEFT", 0, -8)
    step1Box:SetPoint("TOPRIGHT", timerBar, "BOTTOMRIGHT", 0, -8)
    step1Box:SetHeight(82)
    ApplyDarkBackdrop(step1Box, 10)
    step1Box:SetBackdropColor(0.10, 0.12, 0.16, 0.85)

    local step1Title = step1Box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    step1Title:SetPoint("TOPLEFT", 10, -6)
    step1Title:SetText("|cff00ccffPaso 1: Dalaran (Aceptar Primera Misión antes del minuto)|r")

    local step1Desc = step1Box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    step1Desc:SetPoint("TOPLEFT", 10, -22)
    step1Desc:SetText("1. Selecciona con el ratón al PNJ de la misión en Dalaran.\n2. Presiona este botón para teletransportar a todos los bots y hacer que acepten la misión:")

    local step1Btn = CreateFrame("Button", nil, step1Box, "UIPanelButtonTemplate")
    step1Btn:SetSize(360, 26)
    step1Btn:SetPoint("BOTTOMLEFT", 10, 8)
    step1Btn:SetText("1. ¡Traer Bots y Aceptar Misión de Dalaran! (/p summon + accept *)")
    step1Btn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:DalaranPrep()
    end)

    -- =================== PASO 2 ===================
    local step2Box = CreateFrame("Frame", nil, parent)
    step2Box:SetPoint("TOPLEFT", step1Box, "BOTTOMLEFT", 0, -8)
    step2Box:SetPoint("TOPRIGHT", step1Box, "BOTTOMRIGHT", 0, -8)
    step2Box:SetHeight(82)
    ApplyDarkBackdrop(step2Box, 10)
    step2Box:SetBackdropColor(0.10, 0.12, 0.16, 0.85)

    local step2Title = step2Box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    step2Title:SetPoint("TOPLEFT", 10, -6)
    step2Title:SetText("|cff00ccffPaso 2: Entrada a Forja de Almas (Reinvocación)|r")

    local step2Desc = step2Box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    step2Desc:SetPoint("TOPLEFT", 10, -22)
    step2Desc:SetText("Al pasar el minuto en Dalaran los bots desaparecerán. Viaja a Forja de Almas, cruza el portal\ny pulsa este botón para traerlos contigo dentro de la mazmorra:")

    local step2Btn = CreateFrame("Button", nil, step2Box, "UIPanelButtonTemplate")
    step2Btn:SetSize(360, 26)
    step2Btn:SetPoint("BOTTOMLEFT", 10, 8)
    step2Btn:SetText("2. ¡Reinvocar Grupo en Mazmorra! (.playerbots bot add *)")
    step2Btn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:DungeonReenter()
    end)

    -- =================== PASO 3 ===================
    local step3Box = CreateFrame("Frame", nil, parent)
    step3Box:SetPoint("TOPLEFT", step2Box, "BOTTOMLEFT", 0, -8)
    step3Box:SetPoint("TOPRIGHT", step2Box, "BOTTOMRIGHT", 0, -8)
    step3Box:SetHeight(82)
    ApplyDarkBackdrop(step3Box, 10)
    step3Box:SetBackdropColor(0.10, 0.12, 0.16, 0.85)

    local step3Title = step3Box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    step3Title:SetPoint("TOPLEFT", 10, -6)
    step3Title:SetText("|cff00ccffPaso 3: Entregar y Continuar Cadena (Forja -> Foso -> Cámaras)|r")

    local step3Desc = step3Box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    step3Desc:SetPoint("TOPLEFT", 10, -22)
    step3Desc:SetText("Al llegar al PNJ dentro de la mazmorra, selecciónalo (target) y pulsa este botón.\n(Pulsa 1 vez para entregar la misión, y una 2da vez para que acepten la siguiente):")

    local step3Btn = CreateFrame("Button", nil, step3Box, "UIPanelButtonTemplate")
    step3Btn:SetSize(320, 26)
    step3Btn:SetPoint("BOTTOMLEFT", 10, 8)
    step3Btn:SetText("3. Entregar y Aceptar Siguiente (/p accept *)")
    step3Btn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:DungeonTurnInAndAccept()
    end)

    local checkQuestsBtn = CreateFrame("Button", nil, step3Box, "UIPanelButtonTemplate")
    checkQuestsBtn:SetSize(220, 26)
    checkQuestsBtn:SetPoint("LEFT", step3Btn, "RIGHT", 10, 0)
    checkQuestsBtn:SetText("Verificar Misiones (/p quests)")
    checkQuestsBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:SendPartyCommand("quests")
    end)
end

function DungeonBots:UpdateDalaranTimerUI(seconds)
    if not DungeonBots.dalaranTimerBar then return end
    local bar = DungeonBots.dalaranTimerBar
    bar:SetValue(seconds)
    if seconds > 0 then
        bar.text:SetText("Tiempo restante en Dalaran: |cffffffff" .. seconds .. "s|r")
        if seconds > 30 then
            bar:SetStatusBarColor(0.2, 0.8, 0.2) -- Verde
        elseif seconds > 15 then
            bar:SetStatusBarColor(1.0, 0.8, 0.2) -- Amarillo
        else
            bar:SetStatusBarColor(1.0, 0.2, 0.2) -- Rojo alerta
        end
    else
        bar.text:SetText("Temporizador de Dalaran: Inactivo / Expirado")
        bar:SetStatusBarColor(0.4, 0.4, 0.4)
    end
end

-- =========================================================================
-- Botón de Minimapa Arrastrable (El Ojo de Mazmorras)
-- =========================================================================
function DungeonBots:InitMinimapButton()
    if DungeonBots.minimapBtn then return end

    local btn = CreateFrame("Button", "DungeonBots_MinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-Button-Highlight")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    -- Textura del Ojo Místico de Mazmorras
    icon:SetTexture("Interface\\Icons\\INV_Misc_Eye_02")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local function updatePosition()
        local angle = (DungeonBotsDB and DungeonBotsDB.minimapAngle) or 195
        local rad = math.rad(angle)
        local radius = 80
        local x = math.cos(rad) * radius
        local y = math.sin(rad) * radius
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local angle = math.deg(math.atan2(cy - my, cx - mx))
            if DungeonBotsDB then DungeonBotsDB.minimapAngle = angle end
            updatePosition()
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:ToggleHUD()
        else
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:ToggleUI()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff00ccffDungeon|r|cffffd200Bots|r |cff71d5ff(El Ojo de Mazmorras)|r", 1, 1, 1)
        GameTooltip:AddLine("Gestor táctico de bots para Mazmorras", 0.7, 0.8, 1.0)
        GameTooltip:AddLine("\n|cffffd200Clic Izquierdo:|r Abrir / Cerrar Panel Principal")
        GameTooltip:AddLine("|cffffd200Clic Derecho:|r Alternar Barra Táctica (HUD)")
        GameTooltip:AddLine("|cffffd200Arrastrar:|r Mover este ojo alrededor del minimapa")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    updatePosition()
    DungeonBots.minimapBtn = btn
end

-- =========================================================================
-- Integración con El Ojo de Mazmorras (LFDMicroButton y LFDParentFrame)
-- =========================================================================
function DungeonBots:HookEye()
    -- 1. Hook al Ojo del Micro-Menú inferior (LFDMicroButton)
    if LFDMicroButton then
        LFDMicroButton:HookScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                PlaySound("igMainMenuOptionCheckBoxOn")
                DungeonBots:ToggleUI()
            end
        end)
    end

    -- 2. Integrar botón directo dentro de la ventana del Buscador de Mazmorras (LFDParentFrame)
    local function AddLFDButton()
        if not LFDParentFrame or LFDParentFrame.dungeonBotsBtn then return end

        local btn = CreateFrame("Button", "LFDParentFrame_DungeonBotsBtn", LFDParentFrame, "UIPanelButtonTemplate")
        btn:SetSize(130, 24)
        btn:SetPoint("TOPRIGHT", LFDParentFrame, "TOPRIGHT", -38, -42)
        btn:SetText("DungeonBots")
        btn:SetFrameLevel(LFDParentFrame:GetFrameLevel() + 5)

        btn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:ToggleUI()
        end)

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("|cff00ccffDungeon|r|cffffd200Bots|r", 1, 1, 1)
            GameTooltip:AddLine("Abre el asistente de bots para mazmorras.", 0.7, 0.8, 1.0)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        LFDParentFrame.dungeonBotsBtn = btn
    end

    if LFDParentFrame then
        AddLFDButton()
    else
        local hookFrame = CreateFrame("Frame")
        hookFrame:RegisterEvent("ADDON_LOADED")
        hookFrame:SetScript("OnEvent", function(self, event, addon)
            if LFDParentFrame then
                AddLFDButton()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
end


