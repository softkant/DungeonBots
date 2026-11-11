-- =========================================================================
-- DungeonBots_UI.lua: Marco Principal, Pestañas 1/2/3, Minimapa y Ojo LFD
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal

local mainFrame = nil
local activeTab = 1
local tabFrames = {}
local botCards = {}

-- =========================================================================
-- Utilidades de Estilo, Fondos e Hipervínculos (Compartidas con Modales)
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
DB_Internal.ApplyDarkBackdrop = ApplyDarkBackdrop

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
DB_Internal.ApplyHeaderBackdrop = ApplyHeaderBackdrop

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
DB_Internal.CreateRedIconButton = CreateRedIconButton

local function SafeShowLinkTooltip(owner, linkRef, displayLink, title, rawLine)
    local shownDisplay = (displayLink and DungeonBots.LocalizeHyperlinksInText)
        and DungeonBots:LocalizeHyperlinksInText(displayLink)
        or displayLink
    if linkRef and linkRef ~= "" and SetItemRef then
        local ok = pcall(SetItemRef, linkRef, shownDisplay or title or linkRef, "LeftButton")
        if ok and ItemRefTooltip and ItemRefTooltip:IsShown() then
            return
        end
    end
    if owner then
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title or "Detalle", 1, 0.85, 0.2, true)
        if rawLine and rawLine ~= "" then
            local localizedRaw = DungeonBots.LocalizeHyperlinksInText
                and DungeonBots:LocalizeHyperlinksInText(rawLine)
                or rawLine
            GameTooltip:AddLine(DungeonBots:StripChatFormatting(localizedRaw), 0.85, 0.90, 1.0, true)
        end
        GameTooltip:Show()
    end
end
DB_Internal.SafeShowLinkTooltip = SafeShowLinkTooltip

-- =========================================================================
-- Creación de la Ventana Principal
-- =========================================================================
function DungeonBots:InitUI()
    if mainFrame then return end

    local f = CreateFrame("Frame", "DungeonBots_MainFrame", UIParent)
    f:SetSize(620, 448)
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
    closeBtn:SetSize(32, 32)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", 2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        f:Hide()
    end)

    -- Botón de configuración (engranaje) en la cabecera
    local settingsBtn = CreateFrame("Button", "DungeonBots_SettingsHeaderBtn", header)
    settingsBtn:SetSize(20, 20)
    settingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)

    local settingsIcon = settingsBtn:CreateTexture(nil, "ARTWORK")
    settingsIcon:SetAllPoints()
    settingsIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
    settingsIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    settingsBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    settingsBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:ToggleSettingsDialog()
    end)
    settingsBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Configuración", 1, 1, 1)
        GameTooltip:AddLine("Abre las opciones de la Barra Táctica (HUD) y filtros de chat de bots.", 0.7, 0.8, 1.0, true)
        GameTooltip:Show()
    end)
    settingsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

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

    if mainFrame then
        mainFrame:SetHeight((tabIndex == 1) and 448 or 524)
    end
    if tabIndex == 2 then
        DungeonBots:UpdatePartyUI()
    end
end

function DungeonBots:OpenTab(tabIndex)
    if not mainFrame then
        DungeonBots:InitUI()
    end
    DungeonBots:SelectTab(tabIndex or 1)
    if mainFrame then
        mainFrame:Show()
        if mainFrame.Raise then
            pcall(mainFrame.Raise, mainFrame)
        end
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

    if DungeonBots.UpdateHistorySummary then
        DungeonBots:UpdateHistorySummary()
    end

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
        local classDisplay = DungeonBots:GetClassDisplayInfo(cls.class, true) or cls.name

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
        cText:SetText(classDisplay)
        cText:SetTextColor(cColor.r, cColor.g, cColor.b)

        cBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        cBtn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:AddClass(cls.id)
        end)

        cBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Invocar " .. classDisplay, cColor.r, cColor.g, cColor.b)
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

    local quickActionsLabel = actionBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    quickActionsLabel:SetPoint("TOPLEFT", 12, -32)
    quickActionsLabel:SetText("|cffaaaaaaAcciones rápidas de grupo:|r")

    local addAllBtn = CreateRedIconButton(
        actionBox, 134, 24, "Reinvocar Grupo",
        "Interface\\Icons\\Spell_Nature_AstralRecalGroup"
    )
    addAllBtn:SetPoint("TOPLEFT", 11, -50)
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
-- PESTAÑA 2: TALENTOS Y EQUIPO (Bot Manager)
-- =========================================================================
function DungeonBots:BuildTab2(parent)
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

        local cIcon = card:CreateTexture(nil, "ARTWORK")
        cIcon:SetSize(38, 38)
        cIcon:SetPoint("LEFT", 10, 0)
        cIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        cIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        card.classIcon = cIcon

        local nameText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("TOPLEFT", cIcon, "TOPRIGHT", 10, 8)
        nameText:SetText("Bot " .. i)
        card.nameText = nameText

        local infoText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        infoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
        infoText:SetText("Nivel 80")
        card.infoText = infoText

        local botBadge = CreateFrame("Button", nil, card)
        botBadge:SetSize(86, 18)
        botBadge:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -6)
        ApplyHeaderBackdrop(botBadge)
        local badgeText = botBadge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        badgeText:SetPoint("CENTER", 0, 0)
        badgeText:SetText("[ BOT ]")
        botBadge.text = badgeText
        card.botBadge = botBadge

        local humanNotice = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        humanNotice:SetPoint("LEFT", card, "LEFT", 195, 0)
        humanNotice:SetPoint("RIGHT", card, "RIGHT", -15, 0)
        humanNotice:SetJustifyH("LEFT")
        humanNotice:SetText("|cffffb020Jugador humano real.|r\n|cff888888Las opciones de control de bot están inactivas para este miembro.|r")
        humanNotice:Hide()
        card.humanNotice = humanNotice

        local specDropDown = CreateFrame("Frame", "DungeonBots_SpecDropDown_" .. i, card, "UIDropDownMenuTemplate")
        specDropDown:SetPoint("TOPLEFT", card, "TOPLEFT", 175, -10)
        UIDropDownMenu_SetWidth(specDropDown, 185)
        UIDropDownMenu_JustifyText(specDropDown, "LEFT")
        card.specDropDown = specDropDown

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

        local questsBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        questsBtn:SetSize(120, 24)
        questsBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -16)
        questsBtn:SetText("Misiones")
        card.questsBtn = questsBtn

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
                local classDisplay = classToken and DungeonBots:GetClassDisplayInfo(classToken, true) or "Clase"

                card.nameText:SetText(name)
                card.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
                card.infoText:SetText("Nivel " .. (level > 0 and level or 80) .. " (" .. classDisplay .. ")")

                local isBot = DungeonBots:ShouldTreatAsBot(name)

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

                -- Configurar DropDown dinámico de ramas oficiales (con etiqueta localizada y valor canónico)
                local currentBotName = name
                local activeSpec = DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[currentBotName]
                if activeSpec and activeSpec ~= "" and DungeonBots.CanonicalizeSpec then
                    activeSpec = DungeonBots:CanonicalizeSpec(currentBotName, activeSpec)
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
                        local displaySpec = DungeonBots.LocalizeSpecText
                            and DungeonBots:LocalizeSpecText(specName)
                            or specName
                        info.text = displaySpec
                        info.value = specName
                        info.checked = (currentActive and string.lower(specName) == string.lower(currentActive)) or false
                        info.func = function()
                            UIDropDownMenu_SetSelectedValue(card.specDropDown, specName)
                            UIDropDownMenu_SetText(card.specDropDown, displaySpec)
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
                    local activeDisplay = DungeonBots.LocalizeSpecText
                        and DungeonBots:LocalizeSpecText(activeSpec)
                        or activeSpec
                    UIDropDownMenu_SetSelectedValue(card.specDropDown, activeSpec)
                    UIDropDownMenu_SetText(card.specDropDown, activeDisplay)
                elseif DungeonBots.pendingSpecReset and DungeonBots.pendingSpecReset[currentBotName] then
                    UIDropDownMenu_SetSelectedValue(card.specDropDown, nil)
                    UIDropDownMenu_SetText(card.specDropDown, "Consultando talentos...")
                else
                    UIDropDownMenu_SetSelectedValue(card.specDropDown, nil)
                    UIDropDownMenu_SetText(card.specDropDown, "Sin detectar")
                end

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
            bar:SetStatusBarColor(0.2, 0.8, 0.2)
        elseif seconds > 15 then
            bar:SetStatusBarColor(1.0, 0.8, 0.2)
        else
            bar:SetStatusBarColor(1.0, 0.2, 0.2)
        end
    else
        bar.text:SetText("Temporizador de Dalaran: Inactivo / Expirado")
        bar:SetStatusBarColor(0.4, 0.4, 0.4)
    end
end

-- =========================================================================
-- Botón de Minimapa Arrastrable y Gancho en El Ojo de Mazmorras (LFD)
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

function DungeonBots:HookEye()
    if LFDMicroButton then
        LFDMicroButton:HookScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                PlaySound("igMainMenuOptionCheckBoxOn")
                DungeonBots:ToggleUI()
            end
        end)
    end

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
