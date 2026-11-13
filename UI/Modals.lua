-- =========================================================================
-- DungeonBots_Modals.lua: Modales de Configuración e Historial de Bots
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal
local L = DungeonBots.L or {}

local function ApplyBlizzardGoldWindow(frame, edgeSize)
    return DB_Internal.ApplyBlizzardGoldWindow(frame, edgeSize)
end

local function ApplyBlizzardStonePanel(frame, borderR, borderG, borderB, edgeSize, bgAlpha)
    return DB_Internal.ApplyBlizzardStonePanel(frame, borderR, borderG, borderB, edgeSize, bgAlpha)
end

local function ApplyInsetPanelBackdrop(frame, edgeSize)
    return DB_Internal.ApplyInsetPanelBackdrop(frame, edgeSize)
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
    local anyBarShow = hudShow or utilHudShow
    local hudDungeonOnly = (DungeonBotsDB and DungeonBotsDB.hudOnlyInDungeon == true) and true or false
    local muteShow = (not DungeonBotsDB) or (DungeonBotsDB.whisperMuteMode ~= "off")
    local muteGroup = (DungeonBotsDB and DungeonBotsDB.muteBotGroupChat) and true or false

    sf.hudVisibleCheck:SetChecked(hudShow)
    sf.utilHudVisibleCheck:SetChecked(utilHudShow)
    sf.hudDungeonCheck:SetChecked(hudDungeonOnly)
    sf.muteWhispersCheck:SetChecked(muteShow)
    sf.muteGroupCheck:SetChecked(muteGroup)

    sf.muteWhispersCheck:ClearAllPoints()
    if anyBarShow then
        sf.hudDungeonCheck:Show()
        sf.muteWhispersCheck:SetPoint("TOPLEFT", sf.hudDungeonCheck, "BOTTOMLEFT", -18, -10)
    else
        sf.hudDungeonCheck:Hide()
        sf.muteWhispersCheck:SetPoint("TOPLEFT", sf.utilHudVisibleCheck, "BOTTOMLEFT", 0, -10)
    end

    sf.themeLabel:ClearAllPoints()
    if muteShow then
        sf.muteGroupCheck:Show()
        sf.themeLabel:SetPoint("TOPLEFT", sf.muteGroupCheck, "BOTTOMLEFT", -18, -22)
    else
        sf.muteGroupCheck:Hide()
        sf.themeLabel:SetPoint("TOPLEFT", sf.muteWhispersCheck, "BOTTOMLEFT", 0, -22)
    end

    local curTheme = DB_Internal.GetThemeId and DB_Internal.GetThemeId() or "dark"
    local p = DB_Internal.GetThemePalette and DB_Internal.GetThemePalette()
    if sf.themeDarkBtn and sf.themeGoldBtn and p then
        local function StyleThemeChoice(btn, isSelected, displayName)
            if isSelected then
                btn:SetBackdropColor(p.specActiveBg[1], p.specActiveBg[2], p.specActiveBg[3], p.specActiveBg[4])
                btn:SetBackdropBorderColor(p.specActiveBorder[1], p.specActiveBorder[2], p.specActiveBorder[3], p.specActiveBorder[4])
                btn.label:SetText(p.specActiveHex .. displayName .. L["MODAL_ACTIVE_SUFFIX"])
            else
                btn:SetBackdropColor(p.insetBg[1], p.insetBg[2], p.insetBg[3], p.insetBg[4])
                btn:SetBackdropBorderColor(p.insetBorder[1], p.insetBorder[2], p.insetBorder[3], p.insetBorder[4])
                btn.label:SetText(p.specInactiveHex .. displayName .. "|r")
            end
        end
        StyleThemeChoice(sf.themeDarkBtn, curTheme == "dark", L["THEME_DARK_LABEL"])
        StyleThemeChoice(sf.themeGoldBtn, curTheme == "gold", L["THEME_GOLD_LABEL"])
    end

    local totalH = 232 + (anyBarShow and 26 or 0) + (muteShow and 26 or 0)
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
    ApplyBlizzardGoldWindow(sf, 16)

    tinsert(UISpecialFrames, "DungeonBots_SettingsFrame")

    local header = CreateFrame("Frame", nil, sf)
    header:SetPoint("TOPLEFT", sf, "TOPLEFT", 7, -7)
    header:SetPoint("TOPRIGHT", sf, "TOPRIGHT", -7, -7)
    header:SetHeight(30)
    ApplyHeaderBackdrop(header)

    local hIcon = header:CreateTexture(nil, "ARTWORK")
    hIcon:SetSize(16, 16)
    hIcon:SetPoint("LEFT", 10, 0)
    hIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
    hIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", hIcon, "RIGHT", 6, 0)
    title:SetText(L["SETTINGS_MODAL_TITLE"])

    local versionLabel = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    versionLabel:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 6, 1)
    versionLabel:SetText(string.format(L["SETTINGS_FOOTER_VER"], (DungeonBots.VERSION or "1.0.0")))
    sf.versionLabel = versionLabel

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        sf:Hide()
    end)

    -- Opción 1: Mostrar/Ocultar HUD Táctico
    local hudVisibleCheck = CreateSettingsCheckbox(
        sf, "DungeonBots_HudVisibleCheck",
        L["SET_SHOW_HUD_LABEL"],
        L["SET_SHOW_HUD_TITLE"],
        L["SET_SHOW_HUD_DESC"]
    )
    hudVisibleCheck:SetPoint("TOPLEFT", sf, "TOPLEFT", 16, -46)
    sf.hudVisibleCheck = hudVisibleCheck

    -- Opción 1a: Mostrar/Ocultar Barra de Utilidades
    local utilHudVisibleCheck = CreateSettingsCheckbox(
        sf, "DungeonBots_UtilHudVisibleCheck",
        L["SET_SHOW_UTIL_LABEL"],
        L["SET_SHOW_UTIL_TITLE"],
        L["SET_SHOW_UTIL_DESC"]
    )
    utilHudVisibleCheck:SetPoint("TOPLEFT", hudVisibleCheck, "BOTTOMLEFT", 0, -2)
    sf.utilHudVisibleCheck = utilHudVisibleCheck

    -- Opción 1b (dependiente): Solo en mazmorras de 5 jugadores
    local hudDungeonCheck = CreateSettingsCheckbox(
        sf, "DungeonBots_HudDungeonCheck",
        L["SET_DUNGEON_ONLY_LBL"],
        L["SET_DUNGEON_ONLY_TTL"],
        L["SET_DUNGEON_ONLY_DSC"]
    )
    hudDungeonCheck:SetPoint("TOPLEFT", utilHudVisibleCheck, "BOTTOMLEFT", 18, -2)
    sf.hudDungeonCheck = hudDungeonCheck

    -- Opción 2: Ocultar susurros de bots
    local muteWhispersCheck = CreateSettingsCheckbox(
        sf, "DungeonBots_MuteWhispersCheck",
        L["SET_MUTE_WHISPER_LBL"],
        L["SET_MUTE_WHISPER_TTL"],
        L["SET_MUTE_WHISPER_DSC"]
    )
    sf.muteWhispersCheck = muteWhispersCheck

    -- Opción 2b (dependiente): Ocultar mensajes de bots en Grupo/Grito/Decir
    local muteGroupCheck = CreateSettingsCheckbox(
        sf, "DungeonBots_MuteGroupChatCheck",
        L["SET_MUTE_GROUP_LBL"],
        L["SET_MUTE_GROUP_TTL"],
        L["SET_MUTE_GROUP_DSC"]
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
            DungeonBots:Print(labelText .. ": " .. (val and L["STATE_VISIBLE_GREEN"] or L["STATE_HIDDEN_RED"]))
        end)
    end

    BindBarVisibilityToggle(hudVisibleCheck, "hudVisible", "hudFrame", L["SET_BAR_HUD"])
    BindBarVisibilityToggle(utilHudVisibleCheck, "utilHudVisible", "utilHudFrame", L["SET_BAR_UTIL"])

    hudDungeonCheck:SetScript("OnClick", function(self)
        local val = self:GetChecked() and true or false
        if DungeonBotsDB then DungeonBotsDB.hudOnlyInDungeon = val end
        PlaySound(val and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        if DungeonBots.UpdateHUDVisibility then
            DungeonBots:UpdateHUDVisibility()
        end
        DungeonBots:Print(string.format(L["SET_MSG_DUNG_ONLY"], (val and L["STATE_ENABLED_GREEN"] or L["STATE_DISABLED_AMBER"])))
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
        DungeonBots:Print(string.format(L["SET_MSG_MUTE_WHISP"], (val and L["STATE_ENABLED_GREEN"] or L["STATE_DISABLED_AMBER"])))
    end)

    muteGroupCheck:SetScript("OnClick", function(self)
        local val = self:GetChecked() and true or false
        if DungeonBotsDB then DungeonBotsDB.muteBotGroupChat = val end
        PlaySound(val and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        DungeonBots:Print(string.format(L["SET_MSG_MUTE_GROUP"], (val and L["STATE_ENABLED_GREEN"] or L["STATE_DISABLED_AMBER"])))
    end)

    -- Opción 3: Selector de Tema visual (Oscuro Azulado / Dorado)
    local themeLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    themeLabel:SetText(L["SET_THEME_LABEL"])
    sf.themeLabel = themeLabel

    local function CreateThemeChoiceBtn(name, themeId, tipTitle, tipBody)
        local btn = CreateFrame("Button", name, sf)
        btn:SetSize(166, 24)
        ApplyInsetPanelBackdrop(btn, 8)
        btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", btn, "LEFT", 6, 0)
        label:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        label:SetJustifyH("CENTER")
        btn.label = label

        btn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            if DungeonBots.SetUITheme then
                DungeonBots:SetUITheme(themeId)
            end
            local labelText = (themeId == "dark") and ("|cff66d4ff" .. L["THEME_DARK_LABEL"] .. "|r") or ("|cffffd100" .. L["THEME_GOLD_LABEL"] .. "|r")
            DungeonBots:Print(string.format(L["SET_THEME_CHANGED"], labelText))
        end)
        btn:SetScript("OnEnter", function(self)
            local p = DB_Internal.GetThemePalette and DB_Internal.GetThemePalette()
            if p then
                self:SetBackdropBorderColor(p.hoverBorder[1], p.hoverBorder[2], p.hoverBorder[3], p.hoverBorder[4])
            end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(tipTitle, 1, 1, 1)
            GameTooltip:AddLine(tipBody, 0.75, 0.85, 1.0, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
            DungeonBots:UpdateSettingsDialog()
        end)
        return btn
    end

    local themeDarkBtn = CreateThemeChoiceBtn(
        "DungeonBots_ThemeDarkBtn", "dark",
        L["SET_THEME_DARK_TITLE"],
        L["SET_THEME_DARK_DESC"]
    )
    themeDarkBtn:SetPoint("LEFT", themeLabel, "RIGHT", 12, 0)
    sf.themeDarkBtn = themeDarkBtn

    local themeGoldBtn = CreateThemeChoiceBtn(
        "DungeonBots_ThemeGoldBtn", "gold",
        L["SET_THEME_GOLD_TITLE"],
        L["SET_THEME_GOLD_DESC"]
    )
    themeGoldBtn:SetPoint("LEFT", themeDarkBtn, "RIGHT", 8, 0)
    sf.themeGoldBtn = themeGoldBtn

    local closeFooterBtn = CreateFrame("Button", nil, sf, "UIPanelButtonTemplate")
    closeFooterBtn:SetSize(90, 24)
    closeFooterBtn:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", -14, 12)
    closeFooterBtn:SetText(L["BTN_CLOSE"])
    closeFooterBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        sf:Hide()
    end)

    local contactLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    contactLabel:SetPoint("LEFT", sf, "BOTTOMLEFT", 16, 24)
    contactLabel:SetPoint("RIGHT", closeFooterBtn, "LEFT", -10, 0)
    contactLabel:SetJustifyH("LEFT")
    contactLabel:SetText(L["SETTINGS_DISCORD_ERR"])
    sf.contactLabel = contactLabel

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
    text = L["CLEAR_HIST_CONFIRM"],
    button1 = L["CLEAR_HIST_YES"],
    button2 = L["BTN_CANCEL"],
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
        string.format(L["HIST_BOX_COUNT_FMT"], count)
    )
end

local function CreateHistoryRow(parent, idx)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(480, 50)
    ApplyInsetPanelBackdrop(row, 8)

    local iconFrame = CreateFrame("Frame", nil, row)
    iconFrame:SetSize(34, 34)
    iconFrame:SetPoint("LEFT", row, "LEFT", 8, 0)
    ApplyInsetPanelBackdrop(iconFrame, 6)
    local function StyleHistoryIconFrame(f)
        local p = DB_Internal.GetThemePalette and DB_Internal.GetThemePalette()
        if not p then return end
        f:SetBackdropColor(p.historyIconBg[1], p.historyIconBg[2], p.historyIconBg[3], p.historyIconBg[4])
        f:SetBackdropBorderColor(p.headerBorder[1], p.headerBorder[2], p.headerBorder[3], p.headerBorder[4])
    end
    StyleHistoryIconFrame(iconFrame)
    if DB_Internal.RegisterThemed then
        DB_Internal.RegisterThemed(iconFrame, StyleHistoryIconFrame)
    end

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
        GameTooltip:AddLine(L["DEL_HIST_TIP_TITLE"], 1, 0.3, 0.3)
        GameTooltip:AddLine(L["DEL_HIST_TIP_DESC"], 0.8, 0.8, 0.8)
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
    hf:SetSize(540, 446)
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
    ApplyBlizzardGoldWindow(hf, 16)

    table.insert(UISpecialFrames, "DungeonBots_HistoryFrame")

    local header = CreateFrame("Frame", nil, hf)
    header:SetPoint("TOPLEFT", hf, "TOPLEFT", 7, -7)
    header:SetPoint("TOPRIGHT", hf, "TOPRIGHT", -7, -7)
    header:SetHeight(30)
    ApplyHeaderBackdrop(header)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 10, 0)
    title:SetText(L["HIST_MODAL_TITLE"])

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        hf:Hide()
    end)

    local countLabel = hf:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    countLabel:SetPoint("TOPLEFT", 14, -44)
    countLabel:SetText(L["HIST_TOTAL_ZERO"])
    hf.countLabel = countLabel

    local clearBtn = CreateFrame("Button", nil, hf, "UIPanelButtonTemplate")
    clearBtn:SetSize(105, 22)
    clearBtn:SetPoint("TOPRIGHT", hf, "TOPRIGHT", -14, -40)
    clearBtn:SetText(L["HIST_CLEAR_ALL"])
    clearBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        StaticPopup_Show("DUNGEONBOTS_CLEAR_HISTORY")
    end)

    local scrollBg = CreateFrame("Frame", nil, hf)
    scrollBg:SetPoint("TOPLEFT", hf, "TOPLEFT", 10, -68)
    scrollBg:SetPoint("BOTTOMRIGHT", hf, "BOTTOMRIGHT", -10, 52)
    ApplyBlizzardStonePanel(scrollBg, 0.66, 0.54, 0.30, 10, 0.28)

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
    emptyLabel:SetText(L["HIST_EMPTY_TEXT"])
    hf.emptyLabel = emptyLabel

    local addNameLabel = hf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    addNameLabel:SetPoint("BOTTOMLEFT", hf, "BOTTOMLEFT", 14, 22)
    addNameLabel:SetText(L["HIST_ADD_LABEL"])

    local addNameBox = CreateFrame("EditBox", "DungeonBots_HistAddNameBox", hf, "InputBoxTemplate")
    addNameBox:SetSize(180, 20)
    addNameBox:SetPoint("LEFT", addNameLabel, "RIGHT", 10, 0)
    addNameBox:SetAutoFocus(false)
    addNameBox:SetMaxLetters(32)
    hf.addNameBox = addNameBox

    local addNameBtn = CreateFrame("Button", nil, hf, "UIPanelButtonTemplate")
    addNameBtn:SetSize(92, 24)
    addNameBtn:SetPoint("LEFT", addNameBox, "RIGHT", 8, 0)
    addNameBtn:SetText(L["BTN_ADD_BOT"])
    hf.addNameBtn = addNameBtn

    local function SubmitManualBotAdd()
        local raw = addNameBox:GetText() or ""
        local trimmed = (DB_Internal.TrimText and DB_Internal.TrimText(raw)) or string.gsub(raw, "^%s*(.-)%s*$", "%1")
        local cleanBot = (DB_Internal.NormalizePlayerName and DB_Internal.NormalizePlayerName(trimmed)) or trimmed
        if not cleanBot or cleanBot == "" then
            addNameBox:SetFocus()
            return
        end
        if not string.find(cleanBot, "[\128-\255]") then
            cleanBot = string.upper(string.sub(cleanBot, 1, 1)) .. string.lower(string.sub(cleanBot, 2))
        end
        PlaySound("igMainMenuOptionCheckBoxOn")
        addNameBox:SetText("")
        addNameBox:ClearFocus()
        if DungeonBots.SummonAndInviteHistoryBot then
            DungeonBots:SummonAndInviteHistoryBot(cleanBot)
        elseif DungeonBots.AddBot then
            DungeonBots:AddBot(cleanBot)
        end
        if DungeonBots.UpdateHistoryUI then
            DungeonBots:UpdateHistoryUI()
        end
    end

    addNameBox:SetScript("OnEnterPressed", SubmitManualBotAdd)
    addNameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    addNameBtn:SetScript("OnClick", SubmitManualBotAdd)
    addNameBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["BTN_ADD_BOT"], 1, 0.85, 0.2)
        GameTooltip:AddLine(L["HIST_ADD_MANUAL_TIP"], 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    addNameBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local closeFooterBtn = CreateFrame("Button", nil, hf, "UIPanelButtonTemplate")
    closeFooterBtn:SetSize(90, 24)
    closeFooterBtn:SetPoint("BOTTOMRIGHT", hf, "BOTTOMRIGHT", -12, 16)
    closeFooterBtn:SetText(L["BTN_CLOSE"])
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
    hf.countLabel:SetText(string.format(L["HIST_TOTAL_FMT"], #list))

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
            row.nameText:SetText(botName .. L["HIST_IN_PARTY_TAG"])
        else
            row.nameText:SetText(botName)
        end
        row.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)

        local cleanSpec = DungeonBots.CleanSpecText and DungeonBots:CleanSpecText(entry.spec) or (entry.spec or "")
        local displaySpec = (cleanSpec ~= "")
            and ((DungeonBots.LocalizeSpecText and DungeonBots:LocalizeSpecText(cleanSpec)) or cleanSpec)
            or ""
        local specText = (displaySpec ~= "") and ("|cff71d5ff" .. displaySpec .. "|r") or L["HIST_DEFAULT_TALENTS"]
        row.detailText:SetText(className .. " - " .. specText)

        if inParty then
            row.inviteBtn:SetText(L["HIST_IN_PARTY_BTN"])
            row.inviteBtn:Disable()
            row.inviteBtn:SetScript("OnClick", nil)
            row.inviteBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(L["HIST_ALREADY_TITLE"], 0.3, 1.0, 0.5)
                GameTooltip:AddLine(string.format(L["HIST_ALREADY_DESC"], botName), 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
        else
            row.inviteBtn:SetText(L["BTN_INVITE"])
            row.inviteBtn:Enable()
            row.inviteBtn:SetScript("OnClick", function()
                PlaySound("igMainMenuOptionCheckBoxOn")
                DungeonBots:SummonAndInviteHistoryBot(botName)
            end)
            row.inviteBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(string.format(L["HIST_INVITE_TITLE"], botName), 1, 1, 1)
                GameTooltip:AddLine(string.format(L["HIST_INVITE_DESC"], botName), 0.7, 0.8, 1.0, true)
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
