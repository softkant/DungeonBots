-- =========================================================================
-- UI\Theme.lua: Primitivas Visuales, Estilos de Panel, Botones y Tooltips
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal

local THEME_PALETTES = {
    gold = {
        id = "gold",
        label = "Dorado",
        windowEdge = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        windowBorderColor = { 1.0, 1.0, 1.0, 1.0 },
        windowBg = { 0.09, 0.08, 0.06, 0.98 },
        windowStone = { 0.88, 0.82, 0.70, 0.44 },
        windowTint = { 0.045, 0.035, 0.022, 0.54 },

        panelEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
        panelBg = { 0.08, 0.07, 0.055, 0.96 },
        panelBorder = { 0.66, 0.54, 0.30, 0.95 },
        panelStone = { 0.76, 0.70, 0.60, 0.32 },
        panelTint = { 0.03, 0.025, 0.02, 0.56 },

        insetBg = { 0.095, 0.080, 0.060, 0.95 },
        insetBorder = { 0.54, 0.44, 0.26, 0.90 },
        darkBg = { 0.085, 0.072, 0.055, 0.96 },
        darkBorder = { 0.70, 0.56, 0.30, 0.95 },
        hoverBorder = { 1.0, 0.82, 0.28, 1.0 },

        headerBg = { 0.15, 0.115, 0.08, 0.98 },
        headerBorder = { 0.74, 0.60, 0.32, 0.95 },
        headerAccent = { 0.82, 0.68, 0.36, 0.45 },

        ruleLine = { 0.76, 0.62, 0.32, 0.48 },
        quickSlot = { 0.85, 0.70, 0.36, 0.95 },
        quickSlotBright = { 1.0, 0.82, 0.32, 1.0 },

        hudBorder = { 0.78, 0.64, 0.34, 0.95 },
        hudBtnBg = { 0.09, 0.075, 0.055, 0.95 },
        slotEmptyBorder = { 0.36, 0.30, 0.20, 0.55 },
        slotDefaultBg = { 0.08, 0.068, 0.05, 0.96 },
        historyIconBg = { 0.04, 0.03, 0.02, 1.0 },

        specActiveBg = { 0.22, 0.17, 0.09, 0.96 },
        specActiveBorder = { 1.0, 0.82, 0.24, 0.95 },
        specActiveHex = "|cffffd100",
        specInactiveHex = "|cffeeddb8",

        guideTitle = { 1.0, 0.82, 0.0 },
        guideSummary = { 0.95, 0.91, 0.82 },
        guideStep = { 0.90, 0.88, 0.82 },
        guideCatHex = "|cffc9a96e",
        guideCatSubHex = "|cff9d9585",
        guideSelectedBg = { 0.95, 0.72, 0.22, 0.45 },
        guideHighlightBg = { 1.0, 0.85, 0.35, 0.45 },
        guideDetailTitle = { 1.0, 0.84, 0.16 },
        guideNoteBg = { 0.10, 0.08, 0.05, 0.88 },
        guideNoteBorder = { 0.70, 0.56, 0.28, 0.85 },
        guideNoteText = { 0.88, 0.84, 0.74 },
        guidePageText = { 0.82, 0.72, 0.48 },
        warmFillPanel = { 0.16, 0.12, 0.078, 0.48 },
        warmFillSlot = { 0.15, 0.115, 0.075, 0.72 },
        warmFillActive = { 0.24, 0.18, 0.09, 0.80 },
    },
    dark = {
        id = "dark",
        label = "Oscuro Azulado",
        windowEdge = "Interface\\DialogFrame\\UI-DialogBox-Border",
        windowBorderColor = { 0.62, 0.70, 0.84, 1.0 },
        windowBg = { 0.058, 0.072, 0.105, 0.98 },
        windowStone = { 0.62, 0.70, 0.84, 0.36 },
        windowTint = { 0.025, 0.032, 0.052, 0.58 },

        panelEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
        panelBg = { 0.055, 0.068, 0.098, 0.96 },
        panelBorder = { 0.36, 0.44, 0.58, 0.95 },
        panelStone = { 0.58, 0.66, 0.80, 0.28 },
        panelTint = { 0.022, 0.030, 0.048, 0.58 },

        insetBg = { 0.072, 0.088, 0.125, 0.95 },
        insetBorder = { 0.34, 0.42, 0.56, 0.90 },
        darkBg = { 0.062, 0.076, 0.110, 0.96 },
        darkBorder = { 0.38, 0.48, 0.64, 0.95 },
        hoverBorder = { 0.42, 0.76, 0.98, 1.0 },

        headerBg = { 0.090, 0.115, 0.165, 0.98 },
        headerBorder = { 0.42, 0.52, 0.68, 0.95 },
        headerAccent = { 0.42, 0.68, 0.92, 0.45 },

        ruleLine = { 0.40, 0.52, 0.70, 0.45 },
        quickSlot = { 0.62, 0.70, 0.86, 0.90 },
        quickSlotBright = { 0.55, 0.82, 1.0, 1.0 },

        hudBorder = { 0.44, 0.56, 0.76, 0.95 },
        hudBtnBg = { 0.068, 0.084, 0.120, 0.95 },
        slotEmptyBorder = { 0.24, 0.30, 0.40, 0.60 },
        slotDefaultBg = { 0.065, 0.080, 0.115, 0.96 },
        historyIconBg = { 0.03, 0.04, 0.06, 1.0 },

        specActiveBg = { 0.10, 0.20, 0.32, 0.96 },
        specActiveBorder = { 0.40, 0.78, 0.98, 0.95 },
        specActiveHex = "|cff66d4ff",
        specInactiveHex = "|cffe2e8f2",

        guideTitle = { 0.55, 0.84, 1.0 },
        guideSummary = { 0.90, 0.93, 0.98 },
        guideStep = { 0.86, 0.90, 0.96 },
        guideCatHex = "|cff78a8d8",
        guideCatSubHex = "|cff8896ab",
        guideSelectedBg = { 0.28, 0.62, 0.95, 0.42 },
        guideHighlightBg = { 0.40, 0.76, 1.0, 0.40 },
        guideDetailTitle = { 0.55, 0.86, 1.0 },
        guideNoteBg = { 0.07, 0.09, 0.14, 0.90 },
        guideNoteBorder = { 0.36, 0.52, 0.74, 0.85 },
        guideNoteText = { 0.80, 0.87, 0.96 },
        guidePageText = { 0.65, 0.76, 0.90 },
        warmFillPanel = { 0.085, 0.115, 0.175, 0.50 },
        warmFillSlot = { 0.085, 0.115, 0.175, 0.72 },
        warmFillActive = { 0.12, 0.23, 0.36, 0.82 },
    },
}

local function GetThemeId()
    if DungeonBotsDB and DungeonBotsDB.uiTheme == "gold" then
        return "gold"
    end
    return "dark"
end
DB_Internal.GetThemeId = GetThemeId

local function GetThemePalette()
    return THEME_PALETTES[GetThemeId()] or THEME_PALETTES.dark
end
DB_Internal.GetThemePalette = GetThemePalette

local themedEntries = {}

local function RegisterThemed(target, fn)
    if not target or not fn then return end
    target._dbThemeFn = fn
    if not target._dbThemeTracked then
        target._dbThemeTracked = true
        table.insert(themedEntries, target)
    end
end
DB_Internal.RegisterThemed = RegisterThemed

local function EnsureStoneTextures(frame, pad, stoneColor, stoneAlphaOverride, tintColor)
    if not frame._dbStoneBg then
        local stone = frame:CreateTexture(nil, "BACKGROUND")
        stone:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -pad)
        stone:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pad, pad)
        stone:SetTexture("Interface\\AchievementFrame\\UI-Achievement-AchievementBackground")
        frame._dbStoneBg = stone

        local tint = frame:CreateTexture(nil, "BORDER")
        tint:SetAllPoints(stone)
        frame._dbStoneTint = tint
    end
    frame._dbStoneBg:SetVertexColor(stoneColor[1], stoneColor[2], stoneColor[3], stoneAlphaOverride or stoneColor[4])
    frame._dbStoneTint:SetTexture(tintColor[1], tintColor[2], tintColor[3], tintColor[4])
end

local function ApplyWindowStyle(frame)
    local p = GetThemePalette()
    local edgeSize = frame._dbWindowEdgeSize or 16
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = p.windowEdge,
        tile = true, tileSize = 32, edgeSize = edgeSize,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(p.windowBg[1], p.windowBg[2], p.windowBg[3], p.windowBg[4])
    frame:SetBackdropBorderColor(p.windowBorderColor[1], p.windowBorderColor[2], p.windowBorderColor[3], p.windowBorderColor[4])
    EnsureStoneTextures(frame, 5, p.windowStone, nil, p.windowTint)
end

local function ApplyBlizzardGoldWindow(frame, edgeSize)
    frame._dbWindowEdgeSize = edgeSize or 16
    ApplyWindowStyle(frame)
    RegisterThemed(frame, ApplyWindowStyle)
end
DB_Internal.ApplyBlizzardGoldWindow = ApplyBlizzardGoldWindow

local function ApplyStonePanelStyle(frame)
    local p = GetThemePalette()
    local edgeSize = frame._dbStoneEdgeSize or 12
    local bc = frame._dbStoneCustomBorder or p.panelBorder
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = p.panelEdge,
        tile = true, tileSize = 16, edgeSize = edgeSize,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(p.panelBg[1], p.panelBg[2], p.panelBg[3], p.panelBg[4])
    frame:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4] or 0.95)
    EnsureStoneTextures(frame, 3, p.panelStone, frame._dbStoneAlpha, p.panelTint)
end

local function ApplyBlizzardStonePanel(frame, borderR, borderG, borderB, edgeSize, bgAlpha)
    frame._dbStoneEdgeSize = edgeSize or 12
    frame._dbStoneAlpha = bgAlpha
    -- Si el borde es nil o corresponde a variantes neutras del marco, usar la paleta activa.
    -- Reservamos _dbStoneCustomBorder solo si explícitamente se define aparte.
    ApplyStonePanelStyle(frame)
    RegisterThemed(frame, ApplyStonePanelStyle)
end
DB_Internal.ApplyBlizzardStonePanel = ApplyBlizzardStonePanel

local function ApplyDarkBackdropStyle(frame)
    local p = GetThemePalette()
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = p.panelEdge,
        tile = true, tileSize = 16, edgeSize = frame._dbDarkEdgeSize or 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(p.darkBg[1], p.darkBg[2], p.darkBg[3], p.darkBg[4])
    frame:SetBackdropBorderColor(p.darkBorder[1], p.darkBorder[2], p.darkBorder[3], p.darkBorder[4])
end

local function ApplyDarkBackdrop(frame, edgeSize)
    frame._dbDarkEdgeSize = edgeSize or 12
    ApplyDarkBackdropStyle(frame)
    RegisterThemed(frame, ApplyDarkBackdropStyle)
end
DB_Internal.ApplyDarkBackdrop = ApplyDarkBackdrop

local function ApplyInsetBackdropStyle(frame)
    local p = GetThemePalette()
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = p.panelEdge,
        tile = true, tileSize = 14, edgeSize = frame._dbInsetEdgeSize or 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(p.insetBg[1], p.insetBg[2], p.insetBg[3], p.insetBg[4])
    frame:SetBackdropBorderColor(p.insetBorder[1], p.insetBorder[2], p.insetBorder[3], p.insetBorder[4])
end

local function ApplyInsetPanelBackdrop(frame, edgeSize)
    frame._dbInsetEdgeSize = edgeSize or 10
    ApplyInsetBackdropStyle(frame)
    RegisterThemed(frame, ApplyInsetBackdropStyle)
end
DB_Internal.ApplyInsetPanelBackdrop = ApplyInsetPanelBackdrop

local function ApplyGoldWarmFill(tex)
    local c
    if tex and tex._dbFillKey then
        local p = GetThemePalette()
        c = p and p[tex._dbFillKey]
    elseif tex and GetThemeId() == "gold" then
        c = tex._dbGoldFill
    end
    if c then
        tex:SetTexture(c[1], c[2], c[3], c[4])
        tex:Show()
    else
        tex:Hide()
    end
end
DB_Internal.ApplyGoldWarmFill = ApplyGoldWarmFill

local function AddGoldWarmFill(frame, layer, rOrKey, g, b, a, pad)
    local isKey = (type(rOrKey) == "string")
    local p = isKey and (g or 3) or (pad or 3)
    local tex = frame:CreateTexture(nil, layer or "BORDER")
    tex:SetPoint("TOPLEFT", frame, "TOPLEFT", p, -p)
    tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -p, p)
    if isKey then
        tex._dbFillKey = rOrKey
    else
        tex._dbGoldFill = { rOrKey, g, b, a }
    end
    ApplyGoldWarmFill(tex)
    RegisterThemed(tex, ApplyGoldWarmFill)
    return tex
end
DB_Internal.AddGoldWarmFill = AddGoldWarmFill

local function ApplyQuickSlotStyle(border)
    local p = GetThemePalette()
    local c = border._dbSlotBright and p.quickSlotBright or p.quickSlot
    border:SetVertexColor(c[1], c[2], c[3], c[4])
end

local function AddQuickSlotBorder(btn, size, r, g, b, a)
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(size or 26, size or 26)
    border:SetPoint("CENTER", 0, 0)
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    if r and r >= 0.95 then
        border._dbSlotBright = true
    end
    ApplyQuickSlotStyle(border)
    RegisterThemed(border, ApplyQuickSlotStyle)
    return border
end
DB_Internal.AddQuickSlotBorder = AddQuickSlotBorder

local function ApplyRuleStyle(tex)
    local p = GetThemePalette()
    local c = p.ruleLine
    tex:SetTexture(c[1], c[2], c[3], tex._dbRuleAlpha or c[4])
end

local function RegisterRuleTexture(tex, customAlpha)
    tex._dbRuleAlpha = customAlpha
    ApplyRuleStyle(tex)
    RegisterThemed(tex, ApplyRuleStyle)
    return tex
end
DB_Internal.RegisterRuleTexture = RegisterRuleTexture

local function ApplyHeaderBackdropStyle(frame)
    local p = GetThemePalette()
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = p.panelEdge,
        tile = true, tileSize = 12, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(p.headerBg[1], p.headerBg[2], p.headerBg[3], p.headerBg[4])
    frame:SetBackdropBorderColor(p.headerBorder[1], p.headerBorder[2], p.headerBorder[3], p.headerBorder[4])

    if not frame._dbHeaderBg then
        local hBg = frame:CreateTexture(nil, "BACKGROUND")
        hBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        hBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
        frame._dbHeaderBg = hBg

        local hLine = frame:CreateTexture(nil, "BORDER")
        hLine:SetHeight(1)
        hLine:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 1)
        hLine:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 1)
        frame._dbHeaderAccent = hLine
    end
    frame._dbHeaderBg:SetTexture(p.headerBg[1], p.headerBg[2], p.headerBg[3], 0.96)
    frame._dbHeaderAccent:SetTexture(p.headerAccent[1], p.headerAccent[2], p.headerAccent[3], p.headerAccent[4])
end

local function ApplyHeaderBackdrop(frame)
    ApplyHeaderBackdropStyle(frame)
    RegisterThemed(frame, ApplyHeaderBackdropStyle)
end
DB_Internal.ApplyHeaderBackdrop = ApplyHeaderBackdrop

local function RefreshTheme()
    for _, target in ipairs(themedEntries) do
        if target and target._dbThemeFn then
            pcall(target._dbThemeFn, target)
        end
    end
    if DungeonBots.UpdateSettingsDialog then DungeonBots:UpdateSettingsDialog() end
    if DungeonBots.UpdatePartyUI then DungeonBots:UpdatePartyUI() end
    if DungeonBots.UpdateHistoryDialog then DungeonBots:UpdateHistoryDialog() end
    if DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() then
        DungeonBots:UpdateSpellsDialog(DungeonBots.spellsFrame.currentBot)
    end
    if DungeonBots.UpdateInventoryDialog and DungeonBots.inventoryFrame and DungeonBots.inventoryFrame:IsShown() then
        DungeonBots:UpdateInventoryDialog(DungeonBots.inventoryFrame.currentBot)
    end
    if DungeonBots.UpdateQuestDialog and DungeonBots.questFrame and DungeonBots.questFrame:IsShown() then
        DungeonBots:UpdateQuestDialog(DungeonBots.questFrame.currentBot)
    end
    if DungeonBots.UpdateTalkDialog and DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown() then
        DungeonBots:UpdateTalkDialog(DungeonBots.talkFrame.currentBot)
    end
    if DungeonBots.SelectGuideTopic and DungeonBots.guideDetailView then
        DungeonBots:SelectGuideTopic(DungeonBots.selectedGuideTopic or 1)
    end
end
DB_Internal.RefreshTheme = RefreshTheme

function DungeonBots:SetUITheme(themeId)
    local normalized = (themeId == "gold") and "gold" or "dark"
    if DungeonBotsDB then
        DungeonBotsDB.uiTheme = normalized
        DungeonBotsDB.uiThemeDefaultDarkV1 = true
    end
    RefreshTheme()
end

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
