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
    frame:SetBackdropColor(0.06, 0.07, 0.10, 0.96)
    frame:SetBackdropBorderColor(0.72, 0.63, 0.42, 1.0)
end
DB_Internal.ApplyDarkBackdrop = ApplyDarkBackdrop

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

local function ApplyInsetPanelBackdrop(frame, edgeSize)
    edgeSize = edgeSize or 10
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 14, edgeSize = edgeSize,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.035, 0.045, 0.068, 0.95)
    frame:SetBackdropBorderColor(0.28, 0.31, 0.39, 0.90)
end
DB_Internal.ApplyInsetPanelBackdrop = ApplyInsetPanelBackdrop

local function AddQuickSlotBorder(btn, size, r, g, b, a)
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(size or 26, size or 26)
    border:SetPoint("CENTER", 0, 0)
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    border:SetVertexColor(r or 0.85, g or 0.85, b or 0.85, a or 0.85)
    return border
end

local function ApplyHeaderBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0.11, 0.13, 0.18, 0.98)
    frame:SetBackdropBorderColor(0.38, 0.40, 0.48, 0.85)
end
DB_Internal.ApplyHeaderBackdrop = ApplyHeaderBackdrop

local function CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, height)
    btn.iconOffsetX = centerIcon and 18 or 8

    -- Usar OVERLAY para que el icono siempre quede sobre la textura roja del boton
    local icon = btn:CreateTexture(nil, "OVERLAY")
    icon:SetSize(15, 15)
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
            icon = "Interface\\Icons\\INV_Misc_Book_09",
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
            GameTooltip:AddLine("Ejecuta: |cffffd200.playerbots bot addclass " .. cls.id .. "|r", 0.7, 0.8, 1.0)
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
        GameTooltip:AddLine("Ejecuta: |cffffd200.playerbots bot add *|r y los teletransporta a tu posición.", 0.7, 0.8, 1.0, true)
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
        GameTooltip:AddLine("Ejecuta: |cffffd200.playerbots bot remove *|r para guardar y retirar a los bots, y los saca del grupo automáticamente.", 0.7, 0.8, 1.0, true)
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
        GameTooltip:AddLine("Reparar Equipo (/p repair)", 1, 1, 1)
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
        GameTooltip:AddLine("Liberar Alma (/p release)", 1, 1, 1)
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
        icon = "Interface\\Buttons\\UI-MicroButton-Quest-Up",
        texCoord = { 0.09, 0.79, 0.38, 0.88 },
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
        GameTooltip:AddLine("Consulta |cffffd200stats|r y |cffffd200quests|r a todos los bots del grupo para refrescar armadura, espacios libres y misiones.", 0.7, 0.8, 1.0, true)
        GameTooltip:Show()
    end)
    refreshStatsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local emptyLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyLabel:SetPoint("CENTER", parent, "CENTER", 0, 20)
    emptyLabel:SetText("|cff888888No hay bots detectados en tu grupo actualmente.\n\nInvoca bots desde la pestaña 'Armar Grupo' para configurar\nsus talentos, roles y equipo.|r")
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

    if numMembers == 0 then
        if DungeonBots.emptyPartyLabel then DungeonBots.emptyPartyLabel:Show() end
        if DungeonBots.tab2ScanHelp then DungeonBots.tab2ScanHelp:Hide() end
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
            if UnitExists(unit) and UnitIsConnected(unit) then
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
                        GameTooltip:AddLine("\nHaz clic para actualizar stats ahora.", 1, 0.82, 0.2)
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

    if DungeonBots.tab2ScanHelp then
        DungeonBots.tab2ScanHelp:Show()
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
        icon = "Interface\\Icons\\Spell_Shadow_ShadowPact",
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
        icon = "Interface\\Icons\\Spell_Frost_FrostWard",
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
-- Tarjetas de Consejos de la Guía
-- =========================================================================
local function CreateGuideCard(scrollChild, prevCard, minHeight, iconPath, titleText, bodyText, borderR, borderG, borderB)
    local card = CreateFrame("Frame", nil, scrollChild)
    card:SetWidth(520)
    card:SetHeight(minHeight)
    card.minHeight = minHeight
    if prevCard then
        card:SetPoint("TOPLEFT", prevCard, "BOTTOMLEFT", 0, -7)
    else
        card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 2, -2)
    end
    ApplyInsetPanelBackdrop(card)
    if borderR then
        card:SetBackdropBorderColor(borderR, borderG, borderB, 0.85)
    end

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
    icon:SetTexture(iconPath)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    card.icon = icon

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    title:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    title:SetJustifyH("LEFT")
    title:SetText(titleText)
    card.titleText = title

    local sep = card:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -31)
    sep:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -31)
    sep:SetTexture(0.55, 0.48, 0.32, 0.40)

    -- En WoW 3.3.5a fijamos ancla + SetWidth para texto multilínea sin desbordar
    local body = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    body:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -37)
    body:SetWidth(496)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetWordWrap(true)
    body:SetText(bodyText)
    card.bodyText = body

    return card
end

function DungeonBots:RefreshGuideLayout()
    local cards = DungeonBots.guideCards
    local scrollFrame = DungeonBots.guideScrollFrame
    local scrollChild = _G["DungeonBots_GuideScrollChild"]
    if not cards or not scrollFrame or not scrollChild then return end

    local totalHeight = 4
    for _, card in ipairs(cards) do
        local textH = 0
        if card.bodyText then
            card.bodyText:SetWidth(496)
            if card.bodyText.GetStringHeight then
                textH = tonumber(card.bodyText:GetStringHeight()) or 0
            end
        end
        local cardH = math.max(card.minHeight or 82, math.ceil(textH) + 46)
        card:SetHeight(cardH)
        totalHeight = totalHeight + cardH + 7
    end

    scrollChild:SetHeight(math.max(1, totalHeight))
    if scrollFrame.UpdateScrollChildRect then
        scrollFrame:UpdateScrollChildRect()
    end
end

function DungeonBots:BuildTab3(parent)
    DungeonBots.dalaranTimerBar = nil
    DungeonBots.guideParentTab = parent

    -- ScrollFrame de las 4 tarjetas de consejos (ocupa todo el espacio de Tab 3)
    local scrollWrap = CreateFrame("Frame", nil, parent)
    scrollWrap:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -4)
    scrollWrap:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 6)
    ApplyDarkBackdrop(scrollWrap, 8)
    scrollWrap:SetBackdropColor(0.04, 0.05, 0.08, 0.92)
    scrollWrap:SetBackdropBorderColor(0.28, 0.32, 0.40, 0.90)
    DungeonBots.guideScrollWrap = scrollWrap

    local scrollFrame = CreateFrame("ScrollFrame", "DungeonBots_GuideScrollFrame", scrollWrap, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", scrollWrap, "TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", scrollWrap, "BOTTOMRIGHT", -24, 6)
    if scrollFrame.EnableMouseWheel then
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local cur = self:GetVerticalScroll() or 0
            local maxScroll = self:GetVerticalScrollRange() or 0
            local nextVal = math.max(0, math.min(maxScroll, cur - (delta * 28)))
            self:SetVerticalScroll(nextVal)
        end)
    end

    local scrollChild = CreateFrame("Frame", "DungeonBots_GuideScrollChild", scrollFrame)
    scrollChild:SetSize(522, 390)
    scrollFrame:SetScrollChild(scrollChild)
    DungeonBots.guideScrollFrame = scrollFrame

    local guideEntries = {
        {
            height = 82,
            icon = "Interface\\Icons\\INV_Misc_Key_03",
            title = "|cff00ccff1. Mazmorras que requieren misiones previas|r",
            body = "Hay mazmorras que exigen completar misiones previas antes de poder entrar (tanto tú como tus bots). Por ejemplo, |cffffd200Foso de Saron|r y |cffffd200Cámaras de Reflexión|r requieren tener hecha su cadena previa para poder ingresar.",
            border = { 0.28, 0.48, 0.68 },
        },
        {
            height = 98,
            icon = "Interface\\Icons\\Spell_Arcane_PortalDalaran",
            title = "|cff00ccff2. Un bot agregado dentro de mazmorra no entra al instante|r",
            body = "A veces agregas un bot estando dentro de la mazmorra y no ingresa inmediatamente. Sal de la mazmorra un momento para que aparezcan afuera; si no aparecen, utiliza |cffffd200Summon|r y/o |cffffd200Follow|r varias veces. Si sigue sin aparecer, quítalo del grupo desde el addon y vuélvelo a llamar.",
            border = { 0.30, 0.46, 0.62 },
        },
        {
            height = 96,
            icon = "Interface\\Icons\\Ability_Kick",
            title = "|cffff55553. Nunca expulses bots con \"Sacar del grupo\" de WoW|r",
            body = "No |cffff3b30DEBES|r sacar los bots usando \"Sacar del grupo\" como harías con un jugador normal. Lo ideal es retirarlos siempre desde el addon (|cffffd200Despedir|r o |cffffd200Despedir a Todos|r). Si no, el bot quedará ahí esperando |cffffd2001 minuto|r y el sistema pensará que sigues teniendo ese bot extra.",
            border = { 0.72, 0.25, 0.25 },
        },
        {
            height = 84,
            icon = "Interface\\Icons\\Spell_Shadow_Charm",
            title = "|cffffd2004. Bots que ya están siendo usados por otro jugador|r",
            body = "Hay veces que no puedes invocar un bot porque ya lo tiene otra persona en su grupo. Si ocurre al llamarlo o enviarle un comando, el addon cancelará la auto-invitación y te mostrará una alerta indicando quién lo tiene.",
            border = { 0.66, 0.52, 0.24 },
        },
    }

    DungeonBots.guideCards = {}
    local prevCard = nil
    for i, entry in ipairs(guideEntries) do
        local card = CreateGuideCard(
            scrollChild,
            prevCard,
            entry.height,
            entry.icon,
            entry.title,
            entry.body,
            entry.border and entry.border[1],
            entry.border and entry.border[2],
            entry.border and entry.border[3]
        )
        DungeonBots.guideCards[i] = card
        prevCard = card
    end

    DungeonBots:RefreshGuideLayout()
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
