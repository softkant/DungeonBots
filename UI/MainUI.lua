-- =========================================================================
-- UI\MainUI.lua: Marco Principal, Pestañas 1/2/3, Minimapa y Ojo LFD
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal

local mainFrame = nil
local activeTab = 1
local tabFrames = {}
local botCards = {}

-- Utilidades visuales compartidas desde UI\Theme.lua
local function ApplyDarkBackdrop(frame, edgeSize)
    return DB_Internal.ApplyDarkBackdrop(frame, edgeSize)
end

local function ApplyInsetPanelBackdrop(frame, edgeSize)
    return DB_Internal.ApplyInsetPanelBackdrop(frame, edgeSize)
end

local function AddQuickSlotBorder(btn, size, r, g, b, a)
    return DB_Internal.AddQuickSlotBorder(btn, size, r, g, b, a)
end

local function ApplyHeaderBackdrop(frame)
    return DB_Internal.ApplyHeaderBackdrop(frame)
end

local function CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
    return DB_Internal.CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
end

local SUB_MODAL_KEYS = { "spellsFrame", "inventoryFrame", "questFrame", "settingsFrame", "historyFrame" }

local function ApplyTabButtonsVisualState(isDimmed)
    local baseLevel = (mainFrame and mainFrame.GetFrameLevel and mainFrame:GetFrameLevel()) or 10
    for i = 1, 3 do
        local btn = DungeonBots.tabButtons and DungeonBots.tabButtons[i]
        if btn then
            local isSelected = (i == activeTab)
            btn:SetFrameLevel(isSelected and (baseLevel + 3) or (baseLevel + 1))
            if btn.EnableMouse then
                btn:EnableMouse(not isDimmed)
            end
            if isDimmed then
                if btn.Disable then btn:Disable() end
                if btn.checked then btn.checked:Hide() end
                if btn.icon then btn.icon:SetVertexColor(0.20, 0.20, 0.20) end
                if btn.bg then btn.bg:SetVertexColor(0.20, 0.20, 0.20) end
                if btn.countBadgeBg then btn.countBadgeBg:SetAlpha(0.25) end
                if btn.countBadgeText then btn.countBadgeText:SetAlpha(0.25) end
                if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(btn) then
                    GameTooltip:Hide()
                end
            else
                if btn.Enable then btn:Enable() end
                if btn.checked then
                    if isSelected then btn.checked:Show() else btn.checked:Hide() end
                end
                if btn.icon then
                    local c = isSelected and 1.0 or 0.52
                    btn.icon:SetVertexColor(c, c, c)
                end
                if btn.bg then
                    local c = isSelected and 1.0 or 0.75
                    btn.bg:SetVertexColor(c, c, c)
                end
                if btn.countBadgeBg then btn.countBadgeBg:SetAlpha(1.0) end
                if btn.countBadgeText then btn.countBadgeText:SetAlpha(1.0) end
            end
        end
    end
end

function DB_Internal.UpdateMainModalDimmer()
    local mf = DungeonBots.mainFrame
    local dimmer = mf and mf.modalDimmer
    if not dimmer then return end

    local hasOpenSubModal = false
    if mf:IsShown() then
        for _, key in ipairs(SUB_MODAL_KEYS) do
            local sub = DungeonBots[key]
            if sub and sub:IsShown() then
                hasOpenSubModal = true
                break
            end
        end
    end

    ApplyTabButtonsVisualState(hasOpenSubModal)

    if hasOpenSubModal then
        dimmer:SetFrameStrata("DIALOG")
        dimmer:SetFrameLevel(2)
        dimmer:Show()
    else
        dimmer:Hide()
    end
end

function DB_Internal.RegisterSubModalDimmer(frame)
    if not frame or frame._modalDimmerHooked then return end
    frame._modalDimmerHooked = true
    frame:HookScript("OnShow", function()
        DB_Internal.UpdateMainModalDimmer()
    end)
    frame:HookScript("OnHide", function()
        DB_Internal.UpdateMainModalDimmer()
    end)
    if frame:IsShown() then
        DB_Internal.UpdateMainModalDimmer()
    end
end

function DungeonBots:UpdateHUDLockButtonState()
    local btn = DungeonBots.hudLockHeaderBtn
    if not btn or not btn.icon then return end
    local isLocked = DungeonBots.IsHUDLocked and DungeonBots:IsHUDLocked() or false
    if isLocked then
        btn.icon:SetDesaturated(true)
        btn.icon:SetVertexColor(0.66, 0.66, 0.68, 1.0)
        if btn.slotBorder then
            btn.slotBorder:SetVertexColor(0.72, 0.72, 0.76, 0.90)
        end
    else
        btn.icon:SetDesaturated(false)
        btn.icon:SetVertexColor(0.25, 1.0, 0.35, 1.0)
        if btn.slotBorder then
            btn.slotBorder:SetVertexColor(0.35, 0.92, 0.45, 0.95)
        end
    end
end

-- =========================================================================
-- Creación de la Ventana Principal
-- =========================================================================
function DungeonBots:InitUI()
    if mainFrame then return end

    local f = CreateFrame("Frame", "DungeonBots_MainFrame", UIParent)
    f:SetSize(620, 414)
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

    -- Fondo solido oscuro interno para evitar que brille o distraiga el escenario del mundo
    local solidBg = f:CreateTexture(nil, "BACKGROUND")
    solidBg:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
    solidBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    solidBg:SetTexture(0.05, 0.06, 0.09, 0.96)

    tinsert(UISpecialFrames, "DungeonBots_MainFrame")

    -- Barra de Cabecera
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", -6, -6)
    header:SetHeight(28)
    ApplyHeaderBackdrop(header)

    local headerSolidBg = header:CreateTexture(nil, "BACKGROUND")
    headerSolidBg:SetPoint("TOPLEFT", header, "TOPLEFT", 2, -2)
    headerSolidBg:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -2, 2)
    headerSolidBg:SetTexture(0.11, 0.13, 0.18, 0.98)

    local headerAccent = header:CreateTexture(nil, "BORDER")
    headerAccent:SetHeight(1)
    headerAccent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 4, 1)
    headerAccent:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -4, 1)
    headerAccent:SetTexture(0.75, 0.62, 0.36, 0.45)

    local icon = header:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexture("Interface\\Icons\\Spell_Arcane_MindMastery")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    title:SetText("|cff00ccffDungeon|r|cffffd200Bots|r")
    DungeonBots.mainTitleLabel = title

    -- Botón de cerrar
    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetSize(26, 26)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        f:Hide()
    end)

    -- Botón de configuración (engranaje) en la cabecera con marco clásico
    local settingsBtn = CreateFrame("Button", "DungeonBots_SettingsHeaderBtn", header)
    settingsBtn:SetSize(22, 22)
    settingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)

    local settingsIcon = settingsBtn:CreateTexture(nil, "ARTWORK")
    settingsIcon:SetSize(18, 18)
    settingsIcon:SetPoint("CENTER", 0, 0)
    settingsIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
    settingsIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local settingsBorder = AddQuickSlotBorder(settingsBtn, 26, 0.85, 0.85, 0.85, 0.85)
    settingsBtn.slotBorder = settingsBorder

    settingsBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    settingsBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:ToggleSettingsDialog()
    end)
    settingsBtn:SetScript("OnEnter", function(self)
        settingsBorder:SetVertexColor(1.0, 0.82, 0.0, 1.0)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Configuración", 1, 1, 1)
        GameTooltip:AddLine("Abre las opciones de las barras flotantes (Táctica y Utilidades) y filtros de chat de bots.", 0.7, 0.8, 1.0, true)
        GameTooltip:Show()
    end)
    settingsBtn:SetScript("OnLeave", function()
        settingsBorder:SetVertexColor(0.85, 0.85, 0.85, 0.85)
        GameTooltip:Hide()
    end)

    -- Botón de candado (verde = se pueden mover ambas barras; gris = ambas bloqueadas)
    local hudLockBtn = CreateFrame("Button", "DungeonBots_HudLockHeaderBtn", header)
    hudLockBtn:SetSize(22, 22)
    hudLockBtn:SetPoint("RIGHT", settingsBtn, "LEFT", -5, 0)
    hudLockBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    local hudLockIcon = hudLockBtn:CreateTexture(nil, "ARTWORK")
    hudLockIcon:SetSize(16, 16)
    hudLockIcon:SetPoint("CENTER", 0, 0)
    hudLockIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-LOCK")
    hudLockIcon:SetTexCoord(0, 0.875, 0, 0.875)
    hudLockBtn.icon = hudLockIcon
    hudLockBtn.slotBorder = AddQuickSlotBorder(hudLockBtn, 26, 0.85, 0.85, 0.85, 0.85)
    DungeonBots.hudLockHeaderBtn = hudLockBtn

    hudLockBtn:SetScript("OnClick", function(self)
        PlaySound("igMainMenuOptionCheckBoxOn")
        if DungeonBots.ToggleHUDLock then
            DungeonBots:ToggleHUDLock()
        end
        if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self) then
            local onEnter = self:GetScript("OnEnter")
            if onEnter then onEnter(self) end
        end
    end)
    hudLockBtn:SetScript("OnEnter", function(self)
        if hudLockBtn.slotBorder then
            hudLockBtn.slotBorder:SetVertexColor(1.0, 0.82, 0.0, 1.0)
        end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local isLocked = DungeonBots.IsHUDLocked and DungeonBots:IsHUDLocked()
        if isLocked then
            GameTooltip:AddLine("Barras Flotantes: |cff9d9d9dBloqueadas|r", 1, 1, 1)
            GameTooltip:AddLine("Gris: ambas barras están fijadas en su posición.", 0.75, 0.75, 0.78, true)
            GameTooltip:AddLine("Haz clic para desbloquear (verde) y poder mover las 2 barras.", 0.7, 0.85, 1.0, true)
        else
            GameTooltip:AddLine("Barras Flotantes: |cff34c759Desbloqueadas|r", 1, 1, 1)
            GameTooltip:AddLine("Verde: puedes arrastrar ambas barras flotantes.", 0.35, 0.95, 0.45, true)
            GameTooltip:AddLine("Haz clic para bloquear (gris) y fijar las 2 barras.", 0.7, 0.85, 1.0, true)
        end
        GameTooltip:Show()
    end)
    hudLockBtn:SetScript("OnLeave", function()
        DungeonBots:UpdateHUDLockButtonState()
        GameTooltip:Hide()
    end)

    if DungeonBots.UpdateHUDLockButtonState then
        DungeonBots:UpdateHUDLockButtonState()
    end

    -- Sub-barra de sección activa (como WoWAI: muestra la pestaña actual)
    local subBar = CreateFrame("Frame", nil, f)
    subBar:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -38)
    subBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -38)
    subBar:SetHeight(18)

    local sectionTitle = subBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sectionTitle:SetPoint("LEFT", subBar, "LEFT", 0, 0)
    sectionTitle:SetJustifyH("LEFT")
    DungeonBots.sectionTitle = sectionTitle

    local subRule = subBar:CreateTexture(nil, "ARTWORK")
    subRule:SetHeight(1)
    subRule:SetPoint("BOTTOMLEFT", subBar, "BOTTOMLEFT", 0, -2)
    subRule:SetPoint("BOTTOMRIGHT", subBar, "BOTTOMRIGHT", 0, -2)
    subRule:SetTexture(0.60, 0.52, 0.34, 0.45)

    -- Pestañas Verticales con Iconos al lado derecho sobresaliendo (estilo clásico SpellBook / WoWAI)
    local tabNames = {
        {
            id = 1,
            title = "Armar Grupo",
            subtitle = "Historial, clases y control de grupo",
            desc = "Invoca bots por clase individual, abre tu historial y ejecuta acciones rápidas del grupo.",
            icon = "Interface\\Icons\\Spell_ChargePositive",
        },
        {
            id = 2,
            title = "Bots en el grupo",
            subtitle = "Especialización, equipo y misiones",
            desc = "Gestiona las ramas de talentos, equipo y misiones de los bots activos en tu grupo.",
            icon = "Interface\\Icons\\INV_Misc_GroupLooking",
        },
        {
            id = 3,
            title = "Guía y Consejos",
            subtitle = "Manual de uso y solución de problemas",
            desc = "Consejos esenciales sobre misiones previas, invocación dentro de mazmorras, expulsión y bots ocupados.",
            icon = "Interface\\Icons\\INV_Misc_Book_03",
        },
    }

    local tabButtons = {}
    for i, tabData in ipairs(tabNames) do
        local btn = CreateFrame("Button", "DungeonBots_TabBtn_" .. i, f)
        btn:SetSize(32, 32)
        btn:SetPoint("TOPLEFT", f, "TOPRIGHT", -1, -48 - ((i - 1) * 46))

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
        bg:SetSize(64, 64)
        bg:SetPoint("TOPLEFT", btn, "TOPLEFT", -3, 11)
        btn.bg = bg

        local tIcon = btn:CreateTexture(nil, "BORDER")
        tIcon:SetSize(26, 26)
        tIcon:SetPoint("CENTER", 0, 0)
        tIcon:SetTexture(tabData.icon)
        tIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        btn.icon = tIcon

        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        local checked = btn:CreateTexture(nil, "OVERLAY")
        checked:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        checked:SetBlendMode("ADD")
        checked:SetSize(30, 30)
        checked:SetPoint("CENTER", 0, 0)
        btn.checked = checked

        btn.tabData = tabData
        btn.botCount = 0
        btn.tooltipTitle = (i == 2) and "Bots en el grupo (0)" or tabData.title

        if i == 2 then
            local badgeBg = btn:CreateTexture(nil, "ARTWORK")
            badgeBg:SetSize(13, 13)
            badgeBg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
            badgeBg:SetTexture(0.06, 0.08, 0.12, 0.92)
            badgeBg:Hide()
            btn.countBadgeBg = badgeBg

            local badgeText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            badgeText:SetPoint("CENTER", badgeBg, "CENTER", 0, 0)
            badgeText:SetTextColor(0.25, 0.95, 0.45)
            badgeText:SetText("")
            badgeText:Hide()
            btn.countBadgeText = badgeText
        end

        btn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:SelectTab(i)
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.tooltipTitle or tabData.title, 1, 0.82, 0)
            if tabData.desc and tabData.desc ~= "" then
                GameTooltip:AddLine(tabData.desc, 1, 1, 1, true)
            end
            if i == activeTab then
                GameTooltip:AddLine("|cff00ff00(Pestaña Activa)|r", 0.8, 0.8, 0.8)
            else
                GameTooltip:AddLine("|cff888888(Haz clic para cambiar a esta pestaña)|r", 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        tabButtons[i] = btn
    end
    DungeonBots.tabButtons = tabButtons

    -- Contenedores de las 3 Pestañas
    for i = 1, 3 do
        local tabF = CreateFrame("Frame", "DungeonBots_TabFrame_" .. i, f)
        tabF:SetPoint("TOPLEFT", 10, -60)
        tabF:SetPoint("BOTTOMRIGHT", -10, 10)
        tabF:Hide()
        tabFrames[i] = tabF
    end

    mainFrame = f
    DungeonBots.mainFrame = f

    -- Velo oscuro sobre la ventana principal cuando se abre Personaje, Inventario o Misiones
    local modalDimmer = CreateFrame("Frame", "DungeonBots_MainModalDimmer", f)
    modalDimmer:SetAllPoints(f)
    modalDimmer:SetFrameStrata("DIALOG")
    modalDimmer:SetFrameLevel(2)
    modalDimmer:EnableMouse(true)
    if modalDimmer.EnableMouseWheel then
        modalDimmer:EnableMouseWheel(true)
    end
    modalDimmer:SetScript("OnMouseDown", function() end)
    modalDimmer:SetScript("OnMouseUp", function() end)
    modalDimmer:SetScript("OnMouseWheel", function() end)
    modalDimmer:Hide()

    local dimTex = modalDimmer:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints(modalDimmer)
    dimTex:SetTexture(0.0, 0.0, 0.0, 0.76)
    modalDimmer.bg = dimTex

    f.modalDimmer = modalDimmer
    f:HookScript("OnShow", function()
        DB_Internal.UpdateMainModalDimmer()
        if DungeonBots.QueryPartyBotStats then
            DungeonBots:QueryPartyBotStats(false)
        end
    end)
    f:HookScript("OnHide", DB_Internal.UpdateMainModalDimmer)

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

function DungeonBots:UpdateActiveSectionHeader()
    local btn = DungeonBots.tabButtons and DungeonBots.tabButtons[activeTab]
    if not btn or not btn.tabData then return end
    local tabData = btn.tabData
    local titleStr = (activeTab == 2) and (btn.tooltipTitle or tabData.title) or tabData.title
    if DungeonBots.sectionTitle then
        DungeonBots.sectionTitle:SetText("|cffffd200" .. titleStr .. "|r  |cff888888- " .. (tabData.subtitle or "") .. "|r")
    end
end

function DungeonBots:ToggleUI()
    if not mainFrame then
        DungeonBots:InitUI()
    end
    if DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        PlaySound("igMainMenuOptionCheckBoxOff")
        DungeonBots.historyFrame:Hide()
        return
    end
    if mainFrame:IsShown() then
        PlaySound("igMainMenuOptionCheckBoxOff")
        mainFrame:Hide()
    else
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:UpdatePartyUI()
        mainFrame:Show()
    end
end

local TAB_HEIGHTS = { 414, 452, 492 }

function DungeonBots:SelectTab(tabIndex)
    activeTab = tabIndex
    for i = 1, 3 do
        if i == tabIndex then
            tabFrames[i]:Show()
        else
            tabFrames[i]:Hide()
        end
    end
    local isDimmed = (mainFrame and mainFrame.modalDimmer and mainFrame.modalDimmer:IsShown()) and true or false
    ApplyTabButtonsVisualState(isDimmed)

    if mainFrame then
        mainFrame:SetHeight(TAB_HEIGHTS[tabIndex] or 492)
    end
    DungeonBots:UpdateActiveSectionHeader()
    if tabIndex == 2 then
        DungeonBots:UpdatePartyUI()
        if DungeonBots.QueryPartyBotStats then
            DungeonBots:QueryPartyBotStats(false)
        end
    elseif tabIndex == 3 then
        if DungeonBots.RequestDungeonLockInfo then
            DungeonBots:RequestDungeonLockInfo(false)
        end
        if DungeonBots.UpdateDungeonAccessUI then
            DungeonBots:UpdateDungeonAccessUI()
        end
        if DungeonBots.RefreshGuideLayout then
            DungeonBots:RefreshGuideLayout()
        end
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
local function AddPanelDivider(panel, yOffset)
    local line = panel:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset or -24)
    line:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, yOffset or -24)
    line:SetTexture(0.55, 0.48, 0.32, 0.35)
    return line
end

function DungeonBots:BuildTab1(parent)
    -- Caja 1: Acceso al Historial de bots (tira compacta clásica)
    local historyBox = CreateFrame("Frame", nil, parent)
    historyBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -2)
    historyBox:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -2)
    historyBox:SetHeight(52)
    ApplyInsetPanelBackdrop(historyBox, 10)

    local histIconFrame = CreateFrame("Frame", nil, historyBox)
    histIconFrame:SetSize(28, 28)
    histIconFrame:SetPoint("LEFT", historyBox, "LEFT", 12, 0)
    local histIcon = histIconFrame:CreateTexture(nil, "ARTWORK")
    histIcon:SetSize(28, 28)
    histIcon:SetPoint("CENTER", 0, 0)
    histIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
    histIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local historyTitle = historyBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    historyTitle:SetPoint("TOPLEFT", histIconFrame, "TOPRIGHT", 10, 2)
    historyTitle:SetText("|cffffd200Historial de bots|r")

    local historySummary = historyBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    historySummary:SetPoint("TOPLEFT", historyTitle, "BOTTOMLEFT", 0, -3)
    historySummary:SetWidth(330)
    historySummary:SetJustifyH("LEFT")
    historySummary:SetText("Lista de bots invitados anteriormente: |cffffd2000|r")
    DungeonBots.historySummaryLabel = historySummary

    local viewHistoryBtn = CreateRedIconButton(historyBox, 174, 26, "Ver Historial de bots", "Interface\\Icons\\INV_Misc_Note_01", true)
    viewHistoryBtn:SetPoint("RIGHT", historyBox, "RIGHT", -10, 0)
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
    classBox:SetPoint("TOPLEFT", historyBox, "BOTTOMLEFT", 0, -8)
    classBox:SetPoint("TOPRIGHT", historyBox, "BOTTOMRIGHT", 0, -8)
    classBox:SetHeight(176)
    ApplyInsetPanelBackdrop(classBox, 10)

    local classTitle = classBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classTitle:SetPoint("TOPLEFT", 10, -8)
    classTitle:SetText("|cffffd200Invocar Bot por Clase Individual|r")

    AddPanelDivider(classBox, -24)

    -- 10 botones de clases distribuidos en 2 filas de 5
    local btnW = 108
    local btnH = 62
    local spacingX = 7
    local spacingY = 7

    for i, cls in ipairs(DungeonBots.CLASSES) do
        local col = ((i - 1) % 5)
        local row = math.floor((i - 1) / 5)
        local classDisplay = DungeonBots:GetClassDisplayInfo(cls.class, true) or cls.name

        local cBtn = CreateFrame("Button", "DungeonBots_ClassBtn_" .. cls.id, classBox)
        cBtn:SetSize(btnW, btnH)
        cBtn:SetPoint("TOPLEFT", classBox, "TOPLEFT", 10 + col * (btnW + spacingX), -32 - row * (btnH + spacingY))
        ApplyInsetPanelBackdrop(cBtn, 8)
        cBtn:SetBackdropColor(0.08, 0.09, 0.13, 0.96)
        cBtn:SetBackdropBorderColor(0.38, 0.40, 0.48, 0.90)

        local cIcon = cBtn:CreateTexture(nil, "ARTWORK")
        cIcon:SetSize(32, 32)
        cIcon:SetPoint("TOP", cBtn, "TOP", 0, -6)
        cIcon:SetTexture(cls.icon)
        cIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local cText = cBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cText:SetPoint("BOTTOM", 0, 6)
        cText:SetText(classDisplay)
        cText:SetTextColor(1.0, 0.82, 0.0)

        cBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        cBtn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:AddClass(cls.id)
        end)

        cBtn:SetScript("OnEnter", function(self)
            cBtn:SetBackdropBorderColor(0.85, 0.72, 0.42, 1.0)
            cText:SetTextColor(1.0, 1.0, 1.0)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Invocar " .. classDisplay, 1.0, 0.82, 0.0)
            GameTooltip:AddLine("Invoca un bot de clase " .. classDisplay .. ".", 0.7, 0.8, 1.0)
            GameTooltip:AddLine("\n|cff34c759Si el bot te susurra al aparecer, el addon lo invitará automáticamente al grupo.|r", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        cBtn:SetScript("OnLeave", function()
            cBtn:SetBackdropBorderColor(0.38, 0.40, 0.48, 0.90)
            cText:SetTextColor(1.0, 0.82, 0.0)
            GameTooltip:Hide()
        end)
    end

    -- Caja 3: Acciones Globales de Grupo
    local actionBox = CreateFrame("Frame", nil, parent)
    actionBox:SetPoint("TOPLEFT", classBox, "BOTTOMLEFT", 0, -8)
    actionBox:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 4)
    ApplyInsetPanelBackdrop(actionBox, 10)

    local actionTitle = actionBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    actionTitle:SetPoint("TOPLEFT", 10, -8)
    actionTitle:SetText("|cffffd200Control General del Grupo de Bots|r")

    AddPanelDivider(actionBox, -24)

    local quickActionsLabel = actionBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    quickActionsLabel:SetPoint("TOPLEFT", 12, -31)
    quickActionsLabel:SetText("|cff9ea6b5Acciones rápidas para todo el grupo:|r")

    local addAllBtn = CreateRedIconButton(
        actionBox, 136, 26, "Reinvocar Grupo",
        "Interface\\Icons\\Spell_Nature_AstralRecalGroup"
    )
    addAllBtn:SetPoint("BOTTOMLEFT", actionBox, "BOTTOMLEFT", 7, 10)
    addAllBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:AddAllBots()
    end)
    addAllBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Reinvocar a Todos los Bots", 1, 1, 1)
        GameTooltip:AddLine("Reinvoca a los bots ausentes de tu grupo y los teletransporta a tu posición.", 0.7, 0.8, 1.0, true)
        GameTooltip:AddLine("\n|cffffd200Nota:|r Solo funciona con bots que aún siguen en tu grupo pero se fueron por alguna razón (relogueo, al pasar el minuto fuera de mazmorra o desconexión). Si ya fueron sacados del grupo, llámalos desde 'Ver Historial de bots'.", 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    addAllBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local removeAllBtn = CreateRedIconButton(
        actionBox, 136, 26, "Despedir a Todos",
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
        GameTooltip:AddLine("Guarda y retira a todos los bots del mundo y los saca del grupo automáticamente.", 0.7, 0.8, 1.0, true)
        GameTooltip:Show()
    end)
    removeAllBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local repairBtn = CreateRedIconButton(
        actionBox, 136, 26, "Reparar Equipo",
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
        GameTooltip:AddLine("Reparar Equipo", 1, 1, 1)
        GameTooltip:AddLine("Ordena a los bots reparar todas sus piezas si estás cerca de un PNJ reparador o montura.", 0.7, 0.8, 1.0, true)
        GameTooltip:Show()
    end)
    repairBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local releaseBtn = CreateRedIconButton(
        actionBox, 136, 26, "Liberar alma",
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
        GameTooltip:AddLine("Liberar Alma", 1, 1, 1)
        GameTooltip:AddLine("Fuerza a los bots muertos a liberar su espíritu.", 0.7, 0.8, 1.0, true)
        GameTooltip:AddLine("\n|cffff3b30ADVERTENCIA:|r El bot liberará espíritu pero se quedará esperando en el cementerio.", 1, 0.35, 0.35, true)
        GameTooltip:Show()
    end)
    releaseBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Botones de acción rápida en cada tarjeta de bot de la pestaña "Bots en el grupo".
local CARD_ACTION_BUTTONS = {
    {
        key = "charInfoBtn",
        label = "Personaje",
        icon = "Interface\\Icons\\Achievement_Character_Human_Male",
        texCoord = { 0.08, 0.92, 0.08, 0.92 },
        tipTitle = "Información del Personaje",
        tipDesc = "Abre la ventana Información del Personaje en Equipo (ramas de talentos y equipamiento).",
        onClick = function(name)
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:QueryBotSpells(name, "gear", "", false)
        end,
    },
    {
        key = "invBtn",
        label = "Inventario",
        icon = "Interface\\Icons\\INV_Misc_Bag_08",
        texCoord = { 0.08, 0.92, 0.08, 0.92 },
        tipTitle = "Inventario del Bot",
        tipDesc = "Consulta los objetos que lleva el bot en sus bolsas.",
        onClick = function(name)
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:QueryBotInventory(name)
        end,
    },
    {
        key = "questsBtn",
        label = "Misiones",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        texCoord = { 0.13, 0.87, 0.13, 0.87 },
        tipTitle = "Misiones del Bot",
        tipDesc = "Consulta las misiones y abre la ventana de Misiones para ver detalles o abandonarlas.",
        onClick = function(name)
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:QueryQuests(name)
        end,
    },
}

-- Crea un botón con ícono enmarcado y etiqueta inferior para las tarjetas de bot.
local function CreateCardActionIconButton(parent, cfg)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(74, 48)
    btn:RegisterForClicks("LeftButtonUp")
    btn.cfg = cfg

    local slot = CreateFrame("Frame", nil, btn)
    slot:SetSize(32, 32)
    slot:SetPoint("TOP", btn, "TOP", 0, -1)
    if slot.EnableMouse then
        slot:EnableMouse(false)
    end
    ApplyHeaderBackdrop(slot)
    slot:SetBackdropColor(0.06, 0.08, 0.12, 0.95)
    slot:SetBackdropBorderColor(0.42, 0.45, 0.52, 0.90)
    btn.iconSlot = slot

    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
    icon:SetTexture(cfg.icon)
    if cfg.texCoord then
        icon:SetTexCoord(cfg.texCoord[1], cfg.texCoord[2], cfg.texCoord[3], cfg.texCoord[4])
    end
    btn.icon = icon

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", slot, "TOPLEFT", 2, -2)
    hl:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetBlendMode("ADD")
    btn.highlightTex = hl

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOP", slot, "BOTTOM", 0, -3)
    label:SetWidth(88)
    label:SetJustifyH("CENTER")
    if label.SetWordWrap then
        label:SetWordWrap(false)
    end
    label:SetText(cfg.label)
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        slot:SetBackdropBorderColor(0.95, 0.80, 0.30, 1.0)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(cfg.tipTitle, 1, 1, 1)
        GameTooltip:AddLine(cfg.tipDesc, 0.7, 0.8, 1.0, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        slot:SetBackdropBorderColor(0.42, 0.45, 0.52, 0.90)
        GameTooltip:Hide()
    end)
    return btn
end

-- Muestra u oculta los botones de acción rápida de una tarjeta de bot.
local function SetCardActionButtonsVisible(card, visible)
    for _, cfg in ipairs(CARD_ACTION_BUTTONS) do
        local btn = card[cfg.key]
        if btn then
            if visible then
                btn:Show()
            else
                btn:Hide()
            end
        end
    end
end

-- Enlaza el clic de los botones de acción rápida al bot asignado a la tarjeta.
local function BindCardActionButtons(card, name)
    for _, cfg in ipairs(CARD_ACTION_BUTTONS) do
        local btn = card[cfg.key]
        if btn then
            btn:SetScript("OnClick", function(self)
                self.cfg.onClick(name)
            end)
        end
    end
end

-- =========================================================================
-- PESTAÑA 2: TALENTOS Y EQUIPO (Bot Manager)
-- =========================================================================
function DungeonBots:BuildTab2(parent)
    local refreshStatsBtn = CreateFrame("Button", "DungeonBots_RefreshStatsBtn", parent, "UIPanelButtonTemplate")
    refreshStatsBtn:SetSize(96, 22)
    refreshStatsBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 6)
    refreshStatsBtn:SetText("Actualizar")
    refreshStatsBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if DungeonBots.QueryPartyBotStats then
            DungeonBots:QueryPartyBotStats(true)
        end
    end)
    refreshStatsBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Actualizar Estado del Grupo", 1, 1, 1)
        GameTooltip:AddLine("Actualiza el estado de armadura, espacios libres en bolsas y misiones de todos los bots del grupo.", 0.7, 0.8, 1.0, true)
        GameTooltip:Show()
    end)
    refreshStatsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    refreshStatsBtn:Hide()
    DungeonBots.refreshStatsBtn = refreshStatsBtn

    local emptyLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyLabel:SetPoint("CENTER", parent, "CENTER", 0, 12)
    emptyLabel:SetWidth(520)
    emptyLabel:SetJustifyH("CENTER")
    local emptyText = (DungeonBots.L and DungeonBots.L["TAB2_EMPTY_NO_BOTS"])
        or "|cffd8e0ecNo hay bots en tu grupo actualmente.|r\n\n|cff9ea6b5Puedes agregar uno en la primera pestaña |cffffd200\"Armar Grupo\"|r|cff9ea6b5\ny luego podrás gestionar sus talentos, equipos, misiones e inventarios acá.|r"
    emptyLabel:SetText(emptyText)
    DungeonBots.emptyPartyLabel = emptyLabel

    local cardContainer = CreateFrame("Frame", nil, parent)
    cardContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    cardContainer:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 32)
    DungeonBots.cardContainer = cardContainer

    local scanHelp = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    scanHelp:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 8, 11)
    scanHelp:SetPoint("RIGHT", refreshStatsBtn, "LEFT", -10, 0)
    scanHelp:SetJustifyH("LEFT")
    scanHelp:SetText("|cff888888Pulsa |cff00e5ff[BOT]|r o |cffffb020[JUGADOR]|r para cambiar el rol.|r")
    scanHelp:Hide()
    DungeonBots.tab2ScanHelp = scanHelp

    local noBotFooter = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    noBotFooter:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 8, 11)
    noBotFooter:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 11)
    noBotFooter:SetJustifyH("LEFT")
    noBotFooter:SetText((DungeonBots.L and DungeonBots.L["TAB2_FOOTER_NO_BOTS"])
        or "|cff9ea6b5No hay bots en tu grupo. Puedes agregar uno en la primera pestaña |cffffd200\"Armar Grupo\"|r|cff9ea6b5.|r")
    noBotFooter:Hide()
    DungeonBots.tab2NoBotFooter = noBotFooter

    -- Crear 4 tarjetas de bots para las unidades party1 a party4
    for i = 1, 4 do
        local card = CreateFrame("Frame", "DungeonBots_BotCard_" .. i, cardContainer)
        card:SetSize(588, 72)
        card:SetPoint("TOPLEFT", cardContainer, "TOPLEFT", 6, -4 - (i - 1) * 88)
        ApplyInsetPanelBackdrop(card)

        local cIcon = card:CreateTexture(nil, "ARTWORK")
        cIcon:SetSize(38, 38)
        cIcon:SetPoint("LEFT", card, "LEFT", 10, 0)
        cIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        cIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        card.classIcon = cIcon

        local nameText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("TOPLEFT", card, "TOPLEFT", 58, -6)
        nameText:SetText("Bot " .. i)
        card.nameText = nameText

        local infoText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        infoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
        infoText:SetText("Nivel 80")
        card.infoText = infoText

        local specDisplay = CreateFrame("Frame", "DungeonBots_SpecDisplay_" .. i, card)
        specDisplay:SetSize(158, 15)
        specDisplay:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -2)
        card.specDisplay = specDisplay

        local specIcon = specDisplay:CreateTexture(nil, "ARTWORK")
        specIcon:SetSize(15, 15)
        specIcon:SetPoint("LEFT", specDisplay, "LEFT", 0, 0)
        specIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        card.specIcon = specIcon

        local specText = specDisplay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        specText:SetPoint("LEFT", specIcon, "RIGHT", 5, 0)
        specText:SetPoint("RIGHT", specDisplay, "RIGHT", 0, 0)
        specText:SetJustifyH("LEFT")
        specText:SetText("Rama: |cff888888Sin detectar|r")
        card.specText = specText

        local armorDisplay = CreateFrame("Button", "DungeonBots_BotArmorBtn_" .. i, card)
        armorDisplay:SetSize(158, 15)
        armorDisplay:SetPoint("TOPLEFT", specDisplay, "BOTTOMLEFT", 0, -2)
        armorDisplay:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        card.armorDisplay = armorDisplay

        local armorIcon = armorDisplay:CreateTexture(nil, "ARTWORK")
        armorIcon:SetSize(14, 14)
        armorIcon:SetPoint("LEFT", armorDisplay, "LEFT", 0, 0)
        armorIcon:SetTexture("Interface\\Icons\\INV_Chest_Plate01")
        armorIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        card.armorIcon = armorIcon

        local armorText = armorDisplay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        armorText:SetPoint("LEFT", armorIcon, "RIGHT", 5, 0)
        armorText:SetPoint("RIGHT", armorDisplay, "RIGHT", 0, 0)
        armorText:SetJustifyH("LEFT")
        armorText:SetText("Armadura: |cff888888Consultando...|r")
        card.armorText = armorText

        local kickBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        kickBtn:SetSize(92, 22)
        kickBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -12)
        kickBtn:SetText("Despedir")
        card.kickBtn = kickBtn

        local botBadge = CreateFrame("Button", nil, card)
        botBadge:SetSize(92, 18)
        botBadge:SetPoint("TOP", kickBtn, "BOTTOM", 0, -5)
        ApplyHeaderBackdrop(botBadge)
        local badgeText = botBadge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        badgeText:SetPoint("CENTER", 0, 0)
        badgeText:SetText("[ BOT ]")
        botBadge.text = badgeText
        card.botBadge = botBadge

        for idx, cfg in ipairs(CARD_ACTION_BUTTONS) do
            local actionBtn = CreateCardActionIconButton(card, cfg)
            actionBtn:SetPoint("TOPLEFT", card, "TOPLEFT", 220 + (idx - 1) * 88, -12)
            card[cfg.key] = actionBtn
        end

        local humanNotice = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        humanNotice:SetPoint("TOPLEFT", card, "TOPLEFT", 224, -14)
        humanNotice:SetPoint("RIGHT", botBadge, "LEFT", -12, 0)
        humanNotice:SetJustifyH("LEFT")
        humanNotice:SetText("|cffffb020Jugador humano real.|r\n|cff888888Las opciones de control de bot están inactivas para este miembro.|r")
        humanNotice:Hide()
        card.humanNotice = humanNotice

        card:Hide()
        botCards[i] = card
    end
end

local function FormatBotCardArmor(botName)
    local st = DungeonBots.botStats and DungeonBots.botStats[botName]
    local armorStr = DB_Internal.FormatBotStatsDisplay(st)
    return armorStr, st
end

local function FormatBotCardInventoryLabel(botName)
    local st = DungeonBots.botStats and DungeonBots.botStats[botName]
    if DB_Internal.GetBotBagFreeInfo and st then
        local freeSlots, _, bagColor = DB_Internal.GetBotBagFreeInfo(st)
        if freeSlots ~= nil then
            return "Inventario (" .. bagColor .. tostring(freeSlots) .. "|r)", freeSlots
        end
    end
    return "Inventario (|cff888888...|r)", nil
end

local function FormatBotCardQuestsLabel(botName)
    local rec = DungeonBots.botQuestCounts and DungeonBots.botQuestCounts[botName]
    local cnt = rec and rec.count or nil
    if cnt == nil then
        local qData = DungeonBots.questDialogData and DungeonBots.questDialogData[botName]
        if qData and qData.done and not qData.timedOut and qData.quests then
            cnt = #(qData.quests)
        end
    end
    if cnt == nil then
        return "Misiones (|cff888888...|r)", nil
    end
    cnt = tonumber(cnt) or 0
    local numColor = cnt > 0 and "|cffffff00" or "|cff888888"
    return "Misiones (" .. numColor .. tostring(cnt) .. "|r)", cnt
end

-- Actualiza la lista de miembros y sus tarjetas
function DungeonBots:UpdatePartyUI()
    local numMembers = GetNumPartyMembers()
    local botCount = 0
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitIsConnected(unit) then
            local memberName = UnitName(unit)
            if memberName and memberName ~= "" and DungeonBots:ShouldTreatAsBot(memberName) then
                botCount = botCount + 1
            end
        end
    end

    local tab2 = DungeonBots.tabButtons and DungeonBots.tabButtons[2]
    if tab2 then
        tab2.botCount = botCount
        tab2.tooltipTitle = "Bots en el grupo (" .. botCount .. ")"
        if tab2.countBadgeBg and tab2.countBadgeText then
            if botCount > 0 then
                tab2.countBadgeText:SetText(tostring(botCount))
                tab2.countBadgeBg:Show()
                tab2.countBadgeText:Show()
            else
                tab2.countBadgeText:SetText("")
                tab2.countBadgeBg:Hide()
                tab2.countBadgeText:Hide()
            end
        end
    end
    if DungeonBots.UpdateActiveSectionHeader then
        DungeonBots:UpdateActiveSectionHeader()
    end

    DungeonBots:SyncPartyToHistory()

    local visibleCards = 0
    for i = 1, 4 do
        local unit = "party" .. i
        local card = botCards[i]
        if card then
            if UnitExists(unit) and UnitIsConnected(unit) then
                visibleCards = visibleCards + 1
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
                    card.specDisplay:Show()
                    card.armorDisplay:Show()
                    SetCardActionButtonsVisible(card, true)
                    card.kickBtn:Show()

                    local armorStr, st = FormatBotCardArmor(name)
                    local invLabel = FormatBotCardInventoryLabel(name)
                    local questsLabel = FormatBotCardQuestsLabel(name)
                    card.armorText:SetText(armorStr)
                    if card.invBtn and card.invBtn.label then
                        card.invBtn.label:SetText(invLabel)
                    end
                    if card.questsBtn and card.questsBtn.label then
                        card.questsBtn.label:SetText(questsLabel)
                    end
                    card.armorDisplay:SetScript("OnClick", function()
                        PlaySound("igMainMenuOptionCheckBoxOn")
                        if DungeonBots.QueryBotStats then
                            DungeonBots:QueryBotStats(name, true)
                        end
                    end)
                    card.armorDisplay:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_TOP")
                        GameTooltip:AddLine("Armadura de " .. name, 1, 1, 1)
                        if st then
                            GameTooltip:AddLine(armorStr, 1, 1, 1)
                        else
                            GameTooltip:AddLine("Consultando estado de armadura...", 0.75, 0.75, 0.78)
                        end
                        GameTooltip:AddLine("\nHaz clic para actualizar el estado ahora.", 1, 0.82, 0.2)
                        GameTooltip:Show()
                    end)
                    card.armorDisplay:SetScript("OnLeave", function() GameTooltip:Hide() end)
                else
                    card.botBadge.text:SetText("|cffffb020[ JUGADOR ]|r")
                    card.botBadge:SetBackdropBorderColor(1.0, 0.7, 0.2, 0.9)
                    card.botBadge:SetBackdropColor(0.20, 0.14, 0.08, 0.95)
                    card.humanNotice:Show()
                    card.specDisplay:Hide()
                    card.armorDisplay:Hide()
                    SetCardActionButtonsVisible(card, false)
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

                -- Mostrar rama de talentos actual en formato solo lectura (el cambio está en Información del Personaje -> Equipo)
                local currentBotName = name
                local activeSpec = DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[currentBotName]
                if activeSpec and activeSpec ~= "" and DungeonBots.CanonicalizeSpec then
                    activeSpec = DungeonBots:CanonicalizeSpec(currentBotName, activeSpec)
                end

                if activeSpec and activeSpec ~= "" then
                    local activeDisplay = DungeonBots.LocalizeSpecText
                        and DungeonBots:LocalizeSpecText(activeSpec)
                        or activeSpec
                    card.specText:SetText("Rama: |cff71d5ff" .. activeDisplay .. "|r")
                elseif DungeonBots.pendingSpecReset and DungeonBots.pendingSpecReset[currentBotName] then
                    card.specText:SetText("Rama: |cff888888Consultando talentos...|r")
                else
                    card.specText:SetText("Rama: |cff888888Sin detectar|r")
                end

                local botRole = DungeonBots.GetBotRole and DungeonBots:GetBotRole(currentBotName, classToken, activeSpec) or nil
                if DB_Internal.ApplyRoleIcon then
                    DB_Internal.ApplyRoleIcon(card.specIcon, botRole)
                end

                BindCardActionButtons(card, name)

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

    local hasBots = (botCount > 0)
    if DungeonBots.refreshStatsBtn then
        if hasBots then
            DungeonBots.refreshStatsBtn:Show()
        else
            DungeonBots.refreshStatsBtn:Hide()
        end
    end
    if DungeonBots.tab2ScanHelp then
        if hasBots then
            DungeonBots.tab2ScanHelp:Show()
        else
            DungeonBots.tab2ScanHelp:Hide()
        end
    end
    if DungeonBots.emptyPartyLabel then
        if visibleCards == 0 then
            DungeonBots.emptyPartyLabel:Show()
        else
            DungeonBots.emptyPartyLabel:Hide()
        end
    end
    if DungeonBots.tab2NoBotFooter then
        if visibleCards > 0 and not hasBots then
            DungeonBots.tab2NoBotFooter:Show()
        else
            DungeonBots.tab2NoBotFooter:Hide()
        end
    end
end

-- =========================================================================
-- PESTAÑA 3: FOSO Y CÁMARAS (Comprobador de Misiones Previas)
-- =========================================================================
-- Comprobador de Misiones Previas (Frozen Halls / Foso y Cámaras)
-- =========================================================================
local FROZEN_HALLS_DATA = {
    {
        key = "foso",
        name = "Foso de Saron",
        shortName = "1. Foso de Saron",
        icon = "Interface\\Icons\\achievement_dungeon_icecrown_pitofsaron",
        keywords = { "saron", "foso", "pit of saron" },
        excludeKeywords = { "forja", "forge", "reflex", "reflection" },
        prereq = "La Forja de Almas",
        fallbackNormalID = 253,
        fallbackHeroicID = 254,
        fallbackIDs = { 253, 254 },
    },
    {
        key = "camaras",
        name = "Cámaras de Reflexión",
        shortName = "2. Cámaras de Reflexión",
        icon = "Interface\\Icons\\achievement_dungeon_icecrown_hallsofreflection",
        keywords = { "reflexi", "reflection" },
        excludeKeywords = { "forja", "forge", "saron", "foso" },
        prereq = "Foso de Saron",
        fallbackNormalID = 255,
        fallbackHeroicID = 256,
        fallbackIDs = { 255, 256 },
    },
}
DungeonBots.FROZEN_HALLS_DATA = FROZEN_HALLS_DATA

function DungeonBots:GetConnectedPartyBotCount()
    local count = 0
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitIsConnected(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and DungeonBots:ShouldTreatAsBot(name) then
                count = count + 1
            end
        end
    end
    return count
end

local frozenHallsResolved = false
local function MatchesKeywordList(text, list)
    if not text or not list then return false end
    for _, kw in ipairs(list) do
        if string.find(text, kw, 1, true) then
            return true
        end
    end
    return false
end

local function TryRegisterFrozenHallID(id)
    if type(id) ~= "number" or id <= 0 or not GetLFGDungeonInfo then return end
    if LFGIsIDHeader and LFGIsIDHeader(id) then return end

    local name, typeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel,
          expansionLevel, groupID, textureFilename, difficulty, maxPlayers,
          description, isHoliday = GetLFGDungeonInfo(id)

    if not name or name == "" or isHoliday then return end
    -- Excluir bandas (typeID 2) y colas aleatorias (typeID 6); solo mazmorras de 5j de WotLK nivel 75+
    if typeID == 2 or typeID == 6 then return end
    if maxPlayers and maxPlayers ~= 5 then return end
    if expansionLevel and expansionLevel ~= 2 then return end
    if minLevel and minLevel > 0 and minLevel < 75 then return end

    local lowerName = string.lower(name)
    for _, def in ipairs(FROZEN_HALLS_DATA) do
        if MatchesKeywordList(lowerName, def.keywords) and not MatchesKeywordList(lowerName, def.excludeKeywords) then
            if not def.seenID[id] then
                def.seenID[id] = true
                local isHeroic = (difficulty and difficulty > 0) or (string.find(lowerName, "hero", 1, true) ~= nil)
                if isHeroic then
                    table.insert(def.heroicIDs, id)
                else
                    table.insert(def.normalIDs, id)
                end
            end
        end
    end
end

function DungeonBots:ResolveFrozenHallsIDs(force)
    if frozenHallsResolved and not force then return end

    for _, def in ipairs(FROZEN_HALLS_DATA) do
        def.normalIDs = {}
        def.heroicIDs = {}
        def.candidateIDs = {}
        def.seenID = {}
    end

    if GetLFGDungeonInfo then
        if _G.LFDDungeonList and type(_G.LFDDungeonList) == "table" then
            for _, dID in ipairs(_G.LFDDungeonList) do
                TryRegisterFrozenHallID(dID)
            end
        end

        for id = 1, 500 do
            TryRegisterFrozenHallID(id)
        end
    end

    for _, def in ipairs(FROZEN_HALLS_DATA) do
        for _, id in ipairs(def.normalIDs) do
            table.insert(def.candidateIDs, id)
        end
        for _, id in ipairs(def.heroicIDs) do
            table.insert(def.candidateIDs, id)
        end
        if #def.candidateIDs == 0 and def.fallbackIDs then
            for _, fid in ipairs(def.fallbackIDs) do
                if not def.seenID[fid] then
                    def.seenID[fid] = true
                    table.insert(def.candidateIDs, fid)
                end
            end
        end
    end

    frozenHallsResolved = true
end

local function IsQuestLockReason(lockedReason, lfgCode)
    if not lockedReason or lockedReason == 0 then return false end

    -- 1022: LFG_LOCKSTATUS_QUEST_NOT_COMPLETED en TrinityCore / AzerothCore
    if lockedReason == 1022 then
        return true
    end

    -- Solo códigos explícitos de misión en LFG_INSTANCE_INVALID_CODES (ej. "QUEST_NOT_COMPLETED")
    -- Nota: No usar "attun" porque 1001 es ATTUNEMENT_TOO_LOW_LEVEL (requisito de nivel, no misión)
    if lfgCode and type(lfgCode) == "string" then
        local lowerCode = string.lower(lfgCode)
        if string.find(lowerCode, "quest", 1, true) or string.find(lowerCode, "misi", 1, true) then
            return true
        end
    end

    if type(lockedReason) == "string" then
        local lower = string.lower(lockedReason)
        if string.find(lower, "misi", 1, true) or string.find(lower, "quest", 1, true) then
            return true
        end
    end

    return false
end

local function NormalizeMemberKey(name)
    if not name or name == "" then return "" end
    local short = string.match(name, "^([^%-]+)") or name
    return string.lower(short)
end

function DungeonBots:CheckDungeonQuestStatus(def)
    if not def then
        return nil, { { text = "Mazmorra no identificada." } }, {}
    end

    if not GetLFDLockInfo then
        return nil, { { text = "API de buscador de mazmorras no disponible." } }, {}
    end

    if not def.candidateIDs or #def.candidateIDs == 0 then
        DungeonBots:ResolveFrozenHallsIDs()
    end

    local candidateIDs = def.candidateIDs or def.fallbackIDs or {}
    local reasons = {}
    local lockedByKey = {}
    local hasAnyDataFromServer = false

    local lockCount = (GetLFDLockPlayerCount and GetLFDLockPlayerCount()) or 0
    if lockCount > 0 or DungeonBots.lfgLockInfoReceived or (_G.LFGLockList and next(_G.LFGLockList) ~= nil) then
        hasAnyDataFromServer = true
    end

    for _, dID in ipairs(candidateIDs) do
        if _G.LFGLockList and _G.LFGLockList[dID] ~= nil then
            hasAnyDataFromServer = true
        end

        for i = 1, lockCount do
            local playerName, lockedReason = GetLFDLockInfo(dID, i)

            if (playerName and playerName ~= "") or (lockedReason and lockedReason ~= 0) then
                hasAnyDataFromServer = true
            end

            if lockedReason and lockedReason ~= 0 then
                local lfgCode = LFG_INSTANCE_INVALID_CODES and LFG_INSTANCE_INVALID_CODES[lockedReason]
                if IsQuestLockReason(lockedReason, lfgCode) then
                    local isSelf = (i == 1)
                    local myName = UnitName("player")
                    if isSelf or not playerName or playerName == "" or playerName == "Desconocido" or playerName == UNKNOWN or playerName == "Unknown" then
                        if isSelf then
                            playerName = (myName and myName ~= "") and myName or "Tú"
                        else
                            local pUnit = "party" .. (i - 1)
                            playerName = (UnitExists(pUnit) and UnitName(pUnit)) or ("Miembro " .. i)
                        end
                    end
                    if myName and NormalizeMemberKey(playerName) == NormalizeMemberKey(myName) then
                        isSelf = true
                    end

                    local key = NormalizeMemberKey(playerName)
                    if key ~= "" and not lockedByKey[key] then
                        local descText
                        if def.key == "foso" then
                            descText = "no ha completado las misiones previas de La Forja de Almas."
                        elseif def.key == "camaras" then
                            descText = "no ha completado las misiones previas de Foso de Saron."
                        else
                            descText = "no ha completado la misión necesaria."
                        end

                        local reasonObj = {
                            playerName = playerName,
                            reasonCode = lockedReason,
                            text = descText,
                            isSelf = isSelf,
                        }
                        lockedByKey[key] = reasonObj
                        table.insert(reasons, reasonObj)
                    end
                end
            end
        end
    end

    if not hasAnyDataFromServer then
        return nil, { { text = "Consultando datos al servidor..." } }, {}
    end

    -- Construir el estado únicamente de los bots actuales del grupo (excluir al jugador y otros jugadores reales)
    local memberStatuses = {}
    local seenKeys = {}

    local function IsBotMemberName(name)
        if not name or name == "" then return false end
        local short = string.match(name, "^([^%-]+)") or name
        local myName = UnitName and UnitName("player")
        if myName and NormalizeMemberKey(short) == NormalizeMemberKey(myName) then
            return false
        end
        if DungeonBots.ShouldTreatAsBot then
            return DungeonBots:ShouldTreatAsBot(short) or DungeonBots:ShouldTreatAsBot(name)
        end
        if DungeonBots.IsBot then
            return DungeonBots:IsBot(short) == true
        end
        return true
    end

    for p = 1, 4 do
        local unit = "party" .. p
        if UnitExists(unit) then
            local pName = UnitName(unit)
            if pName and pName ~= "" and pName ~= "Desconocido" and pName ~= UNKNOWN and pName ~= "Unknown" then
                if IsBotMemberName(pName) then
                    local pKey = NormalizeMemberKey(pName)
                    if not seenKeys[pKey] then
                        seenKeys[pKey] = true
                        table.insert(memberStatuses, {
                            name = pName,
                            isSelf = false,
                            canEnter = (lockedByKey[pKey] == nil),
                            reason = lockedByKey[pKey],
                        })
                    end
                end
            end
        end
    end

    local botReasons = {}
    for _, m in ipairs(memberStatuses) do
        if not m.canEnter and m.reason then
            table.insert(botReasons, m.reason)
        end
    end

    local canEnter = (#botReasons == 0)
    return canEnter, botReasons, memberStatuses
end

local lastLockReqTime = 0
function DungeonBots:RequestDungeonLockInfo(force)
    local now = GetTime()
    if not force and (now - lastLockReqTime < 2) then
        return
    end
    lastLockReqTime = now
    if GetNumPartyMembers and GetNumPartyMembers() > 0 then
        if RequestLFDPartyLockInfo then
            RequestLFDPartyLockInfo()
        end
    elseif RequestLFDPlayerLockInfo then
        RequestLFDPlayerLockInfo()
    end
end

function DungeonBots:UpdateDungeonAccessUI()
    DungeonBots:ResolveFrozenHallsIDs()

    local data = DungeonBots.FROZEN_HALLS_DATA or FROZEN_HALLS_DATA
    if not data then return end

    local currentBot = DungeonBots.questFrame and DungeonBots.questFrame.currentBot
    local currentBotKey = currentBot and NormalizeMemberKey(currentBot) or ""

    for i, def in ipairs(data) do
        local btn = DungeonBots.dungeonButtons and DungeonBots.dungeonButtons[def.key]
        local canEnter, reasons, memberStatuses = DungeonBots:CheckDungeonQuestStatus(def)

        if btn then
            local botCanEnter = canEnter
            local botNotInParty = false

            if canEnter ~= nil and currentBotKey ~= "" then
                local foundBot = nil
                if memberStatuses then
                    for _, m in ipairs(memberStatuses) do
                        if not m.isSelf and NormalizeMemberKey(m.name) == currentBotKey then
                            foundBot = m
                            break
                        end
                    end
                end
                if foundBot then
                    botCanEnter = foundBot.canEnter
                else
                    botCanEnter = nil
                    botNotInParty = true
                end
            end

            if botCanEnter == true then
                btn.statusText:SetText("|cff00ff00Puede ir|r")
            elseif botCanEnter == false then
                btn.statusText:SetText("|cffff4444Falta misión|r")
            elseif botNotInParty then
                btn.statusText:SetText("|cff888888No en grupo|r")
            else
                btn.statusText:SetText("|cffaaaaaa...|r")
            end

            btn.canEnter = canEnter
            btn.botCanEnter = botCanEnter
            btn.botNotInParty = botNotInParty
            btn.currentBot = currentBot
            btn.reasons = reasons
            btn.memberStatuses = memberStatuses
            btn.dungeonName = def.name
            btn.prereq = def.prereq

            if GameTooltip and GameTooltip:IsShown() and GameTooltip:GetOwner() == btn and btn.RefreshTooltip then
                btn:RefreshTooltip()
            end
        end
    end
end

-- =========================================================================
-- Guía Interactiva Estilo WoW (Índice + Tomo / Registro de Misiones)
-- =========================================================================
local GUIDE_TOPICS = {
    {
        shortTitle = "1. Misiones previas",
        title = "Mazmorras que requieren misiones previas",
        category = "REQUISITOS DE ACCESO",
        icon = "Interface\\Icons\\Achievement_Dungeon_Icecrown_PitOfSaron",
        summary = "Algunas mazmorras (como Forja de Almas, Foso de Saron y Cámaras de Reflexión) exigen que tanto tú como cada bot tengan completada su cadena previa para poder entrar.",
        steps = {
            "En la pestaña |cffffd200Grupo de Bots|r, revisa los iconos de acceso de |cffffd200Foso de Saron|r y |cffffd200Cámaras de Reflexión|r en el pie de la ventana de Misiones.",
            "Haz clic en esos botones de acceso para consultar desde el servidor si el bot ya cumple con la misión previa.",
            "Si le falta, acércate al PNJ con el bot y usa la ventana de |cffffd200Misiones|r o |cffffd200Hablar|r para aceptar y entregar las misiones.",
        },
        note = "Si el bot acaba de entrar por primera vez, sus misiones y acceso se consultan automáticamente; si ves datos incompletos, pulsa Actualizar.",
    },
    {
        shortTitle = "2. Bot tarda en entrar",
        title = "Bot agregado que susurra, pero tarda en entrar",
        category = "INVOCACIÓN E INGRESO",
        icon = "Interface\\Icons\\INV_Misc_GroupLooking",
        summary = "A veces agregas un bot y te susurra al aparecer, pero no entra de inmediato al grupo porque todavía está terminando de cargar en el servidor.",
        steps = {
            "El addon reintenta invitar automáticamente varias veces tras detectar el susurro o llamarlo desde el historial.",
            "Comprueba que |cffffd200eres el líder|r del grupo, que no estás en banda y que tienes cupo libre (máximo 5 en grupo).",
            "Si tras los reintentos sigue fuera, el addon consulta |cffffd200who|r en silencio y te muestra en qué zona se encuentra.",
        },
        note = "También puedes abrir |cffffd200Ver Historial de bots|r en Armar Grupo y pulsar Invitar manualmente.",
    },
    {
        shortTitle = "3. Otra estancia / fase",
        title = "Bot en otra estancia o faseado dentro de mazmorra",
        category = "INSTANCIAS Y FASES",
        icon = "Interface\\Icons\\Spell_Arcane_PortalDalaran",
        summary = "Al invocar o reinvocar un bot dentro de una mazmorra, puede quedar afuera, en otra copia de la estancia o faseado (\"no está en tu estancia\").",
        steps = {
            "El addon consulta |cffffd200who|r al bot para indicarte su zona exacta sin confundirlo con un bot usado por otro jugador.",
            "Utiliza |cffffd200Summon|r y/o |cffffd200Follow|r en la barra táctica (HUD) para traerlo contigo.",
            "Si continúa en otra fase, sal un momento de la mazmorra para reagrupar o reinicia las estancias afuera y usa |cffffd200Reinvocar Grupo|r.",
        },
        note = "Al pasar directo entre mazmorras enlazadas (Forja -> Foso -> Cámaras), salir y reinvocar suele alinear la estancia.",
    },
    {
        shortTitle = "4. Bot usado por otro",
        title = "Bots usados por otro jugador vs. \"ya conectado\"",
        category = "DISPONIBILIDAD DE BOTS",
        icon = "Interface\\Icons\\Spell_Shadow_Charm",
        summary = "Un bot puede estar jugando con otro usuario en el servidor o simplemente terminando de desconectarse tras una sesión reciente.",
        steps = {
            "Si otro jugador lo tiene en su grupo, el addon cancela la auto-invitación y muestra una alerta con el |cffffd200nombre del jugador|r y la |cffffd200zona|r donde está.",
            "Si el servidor solo indica \"ya conectado\" sin dueño confirmado, el addon consulta |cffffd200who|r y reintenta invitarlo si está libre.",
            "Cuando quede disponible o lo suelte el otro jugador, vuelve a llamarlo desde el historial.",
        },
    },
    {
        shortTitle = "5. No expulsar con WoW",
        title = "Nunca expulses bots con \"Sacar del grupo\" de WoW",
        category = "ADVERTENCIA IMPORTANTE",
        critical = true,
        icon = "Interface\\Icons\\Ability_Kick",
        summary = "No |cffff3b30DEBES|r retirar a un bot usando clic derecho -> \"Sacar del grupo\" como harías con un jugador normal.",
        steps = {
            "Despídelos siempre desde el addon usando |cffffd200Despedir|r en su tarjeta o |cffffd200Despedir a Todos|r en Armar Grupo.",
            "Si los expulsas por el menú estándar de WoW, el bot quedará conectado alrededor de |cffffd2001 minuto|r y el sistema pensará que sigues teniendo ese bot ocupado.",
            "Si lo hiciste por error, espera ese minuto antes de invocar un reemplazo.",
        },
        note = "Despedir desde el addon desconecta al bot limpiamente y libera su cupo al instante.",
    },
    {
        shortTitle = "6. Hechizos y Cancelar",
        title = "Hechizos, glifos, materiales y botón Cancelar",
        category = "COMBATE Y CONTROL",
        icon = "Interface\\Icons\\Spell_Frost_IceShock",
        summary = "En la pestaña |cffffd200Hechizos|r de cada bot puedes consultar sus facultades, glifos equipados, componentes necesarios y detener un lanzamiento en curso.",
        steps = {
            "Cuando el bot esté casteando algo, se iluminará el botón |cffffd200Cancelar|r junto a Lanzar para interrumpirlo de inmediato.",
            "Los conjuros que consumen componentes (como runas de portales) muestran directamente qué material requieren.",
            "Si al cambiar rápido de pestañas ves algún glifo u objeto cargando, espera un instante o pulsa |cffffd200Actualizar|r.",
        },
    },
    {
        shortTitle = "7. PNJs e Inventario",
        title = "Hablar con PNJs e inspeccionar Inventario",
        category = "UTILIDADES DEL ADDON",
        icon = "Interface\\Icons\\INV_Misc_Bag_08",
        summary = "El addon centraliza los diálogos con PNJs y la gestión de bolsas/equipo de tus bots ocultando los susurros automáticos del chat.",
        steps = {
            "Lleva al bot junto al PNJ con |cffffd200Follow|r o |cffffd200Summon|r y pulsa |cffffd200Hablar|r desde la barra HUD o desde Misiones.",
            "Desde el diálogo del PNJ puedes interactuar y aceptar o entregar misiones del bot con un clic.",
            "En |cffffd200Inventario|r revisas equipamiento, bolsas, oro y durabilidad sin escribir comandos manuales.",
        },
    },
}

local function ApplyBlizzardStonePanel(frame, borderR, borderG, borderB)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.08, 0.07, 0.06, 0.96)
    frame:SetBackdropBorderColor(borderR or 0.65, borderG or 0.54, borderB or 0.30, 0.95)

    local stone = frame:CreateTexture(nil, "BACKGROUND")
    stone:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    stone:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    stone:SetTexture("Interface\\AchievementFrame\\UI-Achievement-AchievementBackground")
    stone:SetVertexColor(0.75, 0.70, 0.62, 0.38)

    local tint = frame:CreateTexture(nil, "BORDER")
    tint:SetAllPoints(stone)
    tint:SetTexture(0.03, 0.025, 0.02, 0.58)
end

local function ApplyBlizzardGoldTomeFrame(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.09, 0.08, 0.06, 0.98)

    local stone = frame:CreateTexture(nil, "BACKGROUND")
    stone:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
    stone:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
    stone:SetTexture("Interface\\AchievementFrame\\UI-Achievement-AchievementBackground")
    stone:SetVertexColor(0.92, 0.86, 0.74, 0.45)

    local tint = frame:CreateTexture(nil, "BORDER")
    tint:SetAllPoints(stone)
    tint:SetTexture(0.05, 0.04, 0.025, 0.52)
end

function DungeonBots:RefreshGuideLayout()
    local view = DungeonBots.guideDetailView
    if not view or not view.scrollChild or not view.scrollFrame then return end

    local y = 4
    local textW = 324
    if view.summaryText then
        view.summaryText:SetWidth(textW)
        local h = tonumber(view.summaryText:GetStringHeight()) or 0
        y = y + math.max(24, math.ceil(h)) + 14
    end

    if view.stepsHeader and view.stepsHeader:IsShown() then
        view.stepsHeader:ClearAllPoints()
        view.stepsHeader:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -y)
        y = y + 20
    end

    if view.stepRows then
        for _, row in ipairs(view.stepRows) do
            if row:IsShown() and row.text then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -y)
                row.text:SetWidth(textW - 22)
                local sh = tonumber(row.text:GetStringHeight()) or 0
                local rh = math.max(18, math.ceil(sh) + 4)
                row:SetHeight(rh)
                y = y + rh + 6
            end
        end
    end

    if view.noteBox and view.noteBox:IsShown() and view.noteText then
        y = y + 6
        view.noteBox:ClearAllPoints()
        view.noteBox:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 2, -y)
        view.noteText:SetWidth(textW - 20)
        local nh = tonumber(view.noteText:GetStringHeight()) or 0
        local bh = math.max(36, math.ceil(nh) + 18)
        view.noteBox:SetHeight(bh)
        y = y + bh + 8
    end

    view.scrollChild:SetHeight(math.max(1, y))
    if view.scrollFrame.UpdateScrollChildRect then
        view.scrollFrame:UpdateScrollChildRect()
    end
end

function DungeonBots:SelectGuideTopic(index)
    local total = #GUIDE_TOPICS
    if total == 0 then return end
    local idx = math.max(1, math.min(total, tonumber(index) or 1))
    DungeonBots.selectedGuideTopic = idx

    local topic = GUIDE_TOPICS[idx]
    local view = DungeonBots.guideDetailView
    if not view or not topic then return end

    -- Actualizar filas del índice izquierdo
    if DungeonBots.guideIndexButtons then
        for i, btn in ipairs(DungeonBots.guideIndexButtons) do
            local isSelected = (i == idx)
            local t = GUIDE_TOPICS[i]
            if isSelected then
                btn.selectedBg:Show()
                if t and t.critical then
                    btn.selectedBg:SetVertexColor(0.85, 0.25, 0.20, 0.55)
                else
                    btn.selectedBg:SetVertexColor(0.95, 0.72, 0.22, 0.45)
                end
                btn.titleText:SetTextColor(1.0, 1.0, 1.0)
                if btn.slotBorder then
                    btn.slotBorder:SetVertexColor(1.0, 0.82, 0.25, 1.0)
                end
            else
                btn.selectedBg:Hide()
                if t and t.critical then
                    btn.titleText:SetTextColor(1.0, 0.42, 0.38)
                else
                    btn.titleText:SetTextColor(1.0, 0.82, 0.0)
                end
                if btn.slotBorder then
                    btn.slotBorder:SetVertexColor(0.75, 0.65, 0.42, 0.85)
                end
            end
        end
    end

    -- Actualizar detalle del tomo derecho
    view.headerIcon:SetTexture(topic.icon)
    if topic.critical then
        view.categoryText:SetText("|cffff5544" .. (topic.category or "ADVERTENCIA") .. "|r")
        view.titleText:SetText(topic.title)
        view.titleText:SetTextColor(1.0, 0.48, 0.42)
        if view.headerSlotBorder then
            view.headerSlotBorder:SetVertexColor(0.95, 0.35, 0.30, 1.0)
        end
    else
        view.categoryText:SetText("|cffc9a96e" .. (topic.category or "GUÍA") .. "|r")
        view.titleText:SetText(topic.title)
        view.titleText:SetTextColor(1.0, 0.84, 0.16)
        if view.headerSlotBorder then
            view.headerSlotBorder:SetVertexColor(1.0, 0.82, 0.32, 1.0)
        end
    end

    view.summaryText:SetText(topic.summary or "")

    local steps = topic.steps or {}
    if #steps > 0 then
        view.stepsHeader:Show()
    else
        view.stepsHeader:Hide()
    end

    for i, row in ipairs(view.stepRows) do
        local stepText = steps[i]
        if stepText and stepText ~= "" then
            row.numText:SetText(i .. ".")
            row.text:SetText(stepText)
            row:Show()
        else
            row:Hide()
        end
    end

    if topic.note and topic.note ~= "" then
        view.noteText:SetText("|cffffd200Nota:|r " .. topic.note)
        view.noteBox:Show()
    else
        view.noteBox:Hide()
    end

    if view.pageText then
        view.pageText:SetText("Tema " .. idx .. " de " .. total)
    end
    if view.prevBtn then
        if idx > 1 then view.prevBtn:Enable() else view.prevBtn:Disable() end
    end
    if view.nextBtn then
        if idx < total then view.nextBtn:Enable() else view.nextBtn:Disable() end
    end

    if view.scrollFrame then
        view.scrollFrame:SetVerticalScroll(0)
    end
    DungeonBots:RefreshGuideLayout()
end

function DungeonBots:BuildTab3(parent)
    DungeonBots.dalaranTimerBar = nil
    DungeonBots.guideParentTab = parent

    -- Panel Izquierdo: Índice de temas (estilo Registro de Misiones de WoW)
    local indexPanel = CreateFrame("Frame", nil, parent)
    indexPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -2)
    indexPanel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4, 4)
    indexPanel:SetWidth(208)
    ApplyBlizzardStonePanel(indexPanel, 0.68, 0.56, 0.32)

    local idxHeaderIcon = indexPanel:CreateTexture(nil, "ARTWORK")
    idxHeaderIcon:SetSize(18, 18)
    idxHeaderIcon:SetPoint("TOPLEFT", indexPanel, "TOPLEFT", 11, -10)
    idxHeaderIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    idxHeaderIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local idxHeaderTitle = indexPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    idxHeaderTitle:SetPoint("LEFT", idxHeaderIcon, "RIGHT", 7, 0)
    idxHeaderTitle:SetText("Índice de la Guía")
    idxHeaderTitle:SetTextColor(1.0, 0.82, 0.0)

    local idxRule = indexPanel:CreateTexture(nil, "ARTWORK")
    idxRule:SetHeight(1)
    idxRule:SetPoint("TOPLEFT", indexPanel, "TOPLEFT", 10, -33)
    idxRule:SetPoint("TOPRIGHT", indexPanel, "TOPRIGHT", -10, -33)
    idxRule:SetTexture(0.75, 0.62, 0.34, 0.55)

    local idxScroll = CreateFrame("ScrollFrame", "DungeonBots_GuideIndexScroll", indexPanel, "UIPanelScrollFrameTemplate")
    idxScroll:SetPoint("TOPLEFT", indexPanel, "TOPLEFT", 6, -38)
    idxScroll:SetPoint("BOTTOMRIGHT", indexPanel, "BOTTOMRIGHT", -24, 8)
    local idxChild = CreateFrame("Frame", "DungeonBots_GuideIndexChild", idxScroll)
    idxChild:SetSize(176, 1)
    idxScroll:SetScrollChild(idxChild)

    DungeonBots.guideIndexButtons = {}
    local rowHeight = 48
    local totalIdxHeight = 4
    for i, topic in ipairs(GUIDE_TOPICS) do
        local row = CreateFrame("Button", nil, idxChild)
        row:SetSize(174, rowHeight)
        row:SetPoint("TOPLEFT", idxChild, "TOPLEFT", 2, -totalIdxHeight)

        local selectedBg = row:CreateTexture(nil, "BACKGROUND")
        selectedBg:SetAllPoints(row)
        selectedBg:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
        selectedBg:SetBlendMode("ADD")
        selectedBg:Hide()
        row.selectedBg = selectedBg

        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(row)
        hl:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
        hl:SetBlendMode("ADD")
        hl:SetVertexColor(1.0, 0.85, 0.35, 0.45)

        local iconHolder = CreateFrame("Frame", nil, row)
        iconHolder:SetSize(24, 24)
        iconHolder:SetPoint("LEFT", row, "LEFT", 6, 0)

        local rIcon = iconHolder:CreateTexture(nil, "ARTWORK")
        rIcon:SetAllPoints(iconHolder)
        rIcon:SetTexture(topic.icon)
        rIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.slotBorder = AddQuickSlotBorder(iconHolder, 36, 0.75, 0.65, 0.42, 0.85)

        local rTitle = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rTitle:SetPoint("TOPLEFT", iconHolder, "TOPRIGHT", 8, -2)
        rTitle:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        rTitle:SetJustifyH("LEFT")
        rTitle:SetText(topic.shortTitle)
        row.titleText = rTitle

        local rCat = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rCat:SetPoint("TOPLEFT", rTitle, "BOTTOMLEFT", 0, -2)
        rCat:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        rCat:SetJustifyH("LEFT")
        if topic.critical then
            rCat:SetText("|cffff6655Advertencia clave|r")
        else
            rCat:SetText("|cff9d9585" .. (topic.category or "") .. "|r")
        end

        local sep = row:CreateTexture(nil, "ARTWORK")
        sep:SetHeight(1)
        sep:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 6, 0)
        sep:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 0)
        sep:SetTexture(0.55, 0.46, 0.28, 0.25)

        row:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:SelectGuideTopic(i)
        end)

        DungeonBots.guideIndexButtons[i] = row
        totalIdxHeight = totalIdxHeight + rowHeight + 2
    end
    idxChild:SetHeight(math.max(1, totalIdxHeight))

    -- Panel Derecho: Detalle del Tomo con marco dorado Blizzard
    local detailPanel = CreateFrame("Frame", nil, parent)
    detailPanel:SetPoint("TOPLEFT", indexPanel, "TOPRIGHT", 8, 0)
    detailPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
    ApplyBlizzardGoldTomeFrame(detailPanel)

    local headerIconFrame = CreateFrame("Frame", nil, detailPanel)
    headerIconFrame:SetSize(38, 38)
    headerIconFrame:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 16, -15)

    local headerIcon = headerIconFrame:CreateTexture(nil, "ARTWORK")
    headerIcon:SetAllPoints(headerIconFrame)
    headerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local headerSlotBorder = AddQuickSlotBorder(headerIconFrame, 58, 1.0, 0.82, 0.32, 1.0)

    local categoryText = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    categoryText:SetPoint("TOPLEFT", headerIconFrame, "TOPRIGHT", 12, -1)
    categoryText:SetPoint("RIGHT", detailPanel, "RIGHT", -16, 0)
    categoryText:SetJustifyH("LEFT")

    local titleText = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", categoryText, "BOTTOMLEFT", 0, -2)
    titleText:SetWidth(298)
    titleText:SetJustifyH("LEFT")
    titleText:SetWordWrap(true)

    local headerRule = detailPanel:CreateTexture(nil, "ARTWORK")
    headerRule:SetHeight(1)
    headerRule:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 14, -68)
    headerRule:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -14, -68)
    headerRule:SetTexture(0.82, 0.68, 0.36, 0.60)

    local scrollFrame = CreateFrame("ScrollFrame", "DungeonBots_GuideScrollFrame", detailPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 14, -76)
    scrollFrame:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -28, 42)
    if scrollFrame.EnableMouseWheel then
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local cur = self:GetVerticalScroll() or 0
            local maxScroll = self:GetVerticalScrollRange() or 0
            self:SetVerticalScroll(math.max(0, math.min(maxScroll, cur - (delta * 26))))
        end)
    end

    local scrollChild = CreateFrame("Frame", "DungeonBots_GuideScrollChild", scrollFrame)
    scrollChild:SetSize(330, 200)
    scrollFrame:SetScrollChild(scrollChild)
    DungeonBots.guideScrollFrame = scrollFrame

    local summaryText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    summaryText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, -4)
    summaryText:SetWidth(324)
    summaryText:SetJustifyH("LEFT")
    summaryText:SetJustifyV("TOP")
    summaryText:SetWordWrap(true)
    summaryText:SetTextColor(0.95, 0.91, 0.82)
    if summaryText.SetSpacing then summaryText:SetSpacing(3) end

    local stepsHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stepsHeader:SetText("Qué debes hacer:")
    stepsHeader:SetTextColor(1.0, 0.82, 0.0)

    local stepRows = {}
    for i = 1, 4 do
        local sRow = CreateFrame("Frame", nil, scrollChild)
        sRow:SetSize(324, 24)
        local numText = sRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        numText:SetPoint("TOPLEFT", sRow, "TOPLEFT", 2, 0)
        numText:SetWidth(18)
        numText:SetJustifyH("LEFT")
        numText:SetTextColor(1.0, 0.82, 0.0)
        sRow.numText = numText

        local sText = sRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        sText:SetPoint("TOPLEFT", sRow, "TOPLEFT", 20, 0)
        sText:SetWidth(302)
        sText:SetJustifyH("LEFT")
        sText:SetJustifyV("TOP")
        sText:SetWordWrap(true)
        sText:SetTextColor(0.90, 0.88, 0.82)
        if sText.SetSpacing then sText:SetSpacing(2) end
        sRow.text = sText

        stepRows[i] = sRow
    end

    local noteBox = CreateFrame("Frame", nil, scrollChild)
    noteBox:SetSize(324, 44)
    ApplyInsetPanelBackdrop(noteBox, 10)
    noteBox:SetBackdropColor(0.10, 0.08, 0.05, 0.88)
    noteBox:SetBackdropBorderColor(0.70, 0.56, 0.28, 0.85)

    local noteText = noteBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    noteText:SetPoint("TOPLEFT", noteBox, "TOPLEFT", 10, -8)
    noteText:SetWidth(304)
    noteText:SetJustifyH("LEFT")
    noteText:SetJustifyV("TOP")
    noteText:SetWordWrap(true)
    noteText:SetTextColor(0.88, 0.84, 0.74)

    -- Pie de página con paginación WoW
    local footerRule = detailPanel:CreateTexture(nil, "ARTWORK")
    footerRule:SetHeight(1)
    footerRule:SetPoint("BOTTOMLEFT", detailPanel, "BOTTOMLEFT", 14, 38)
    footerRule:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -14, 38)
    footerRule:SetTexture(0.82, 0.68, 0.36, 0.50)

    local prevBtn = CreateFrame("Button", nil, detailPanel, "UIPanelButtonTemplate")
    prevBtn:SetSize(96, 22)
    prevBtn:SetPoint("BOTTOMLEFT", detailPanel, "BOTTOMLEFT", 14, 10)
    prevBtn:SetText("< Anterior")
    prevBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:SelectGuideTopic((DungeonBots.selectedGuideTopic or 1) - 1)
    end)

    local nextBtn = CreateFrame("Button", nil, detailPanel, "UIPanelButtonTemplate")
    nextBtn:SetSize(96, 22)
    nextBtn:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -14, 10)
    nextBtn:SetText("Siguiente >")
    nextBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:SelectGuideTopic((DungeonBots.selectedGuideTopic or 1) + 1)
    end)

    local pageText = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pageText:SetPoint("CENTER", detailPanel, "BOTTOM", 0, 21)
    pageText:SetTextColor(0.82, 0.72, 0.48)

    DungeonBots.guideDetailView = {
        headerIcon = headerIcon,
        headerSlotBorder = headerSlotBorder,
        categoryText = categoryText,
        titleText = titleText,
        scrollFrame = scrollFrame,
        scrollChild = scrollChild,
        summaryText = summaryText,
        stepsHeader = stepsHeader,
        stepRows = stepRows,
        noteBox = noteBox,
        noteText = noteText,
        prevBtn = prevBtn,
        nextBtn = nextBtn,
        pageText = pageText,
    }

    DungeonBots:SelectGuideTopic(1)

    parent:HookScript("OnShow", function()
        DungeonBots:UpdateDungeonAccessUI()
        if DungeonBots:GetConnectedPartyBotCount() > 0 then
            DungeonBots:RequestDungeonLockInfo(false)
        end
        DungeonBots:RefreshGuideLayout()
    end)
end

function DungeonBots:UpdateDalaranTimerUI(seconds)
    if not DungeonBots.dalaranTimerBar then return end
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
