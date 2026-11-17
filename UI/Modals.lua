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
    if p then
        local function StyleChoiceBtn(btn, isSelected, displayName)
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
        if sf.themeDarkBtn and sf.themeGoldBtn then
            StyleChoiceBtn(sf.themeDarkBtn, curTheme == "dark", L["THEME_DARK_LABEL"])
            StyleChoiceBtn(sf.themeGoldBtn, curTheme == "gold", L["THEME_GOLD_LABEL"])
        end
        if sf.langAutoBtn and sf.langEsBtn and sf.langEnBtn then
            local curLang = (DungeonBots.GetAddonLocaleSetting and DungeonBots:GetAddonLocaleSetting()) or "auto"
            StyleChoiceBtn(sf.langAutoBtn, curLang == "auto", L["SET_LANG_AUTO_LABEL"])
            StyleChoiceBtn(sf.langEsBtn,   curLang == "esES", L["SET_LANG_ES_LABEL"])
            StyleChoiceBtn(sf.langEnBtn,   curLang == "enUS", L["SET_LANG_EN_LABEL"])
        end
    end

    local totalH = 266 + (anyBarShow and 26 or 0) + (muteShow and 26 or 0)
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
    versionLabel:SetText(string.format(L["SETTINGS_FOOTER_VER"], (DungeonBots.VERSION or "1.2.3")))
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
            DungeonBots:UpdateSettingsDialog()
            DungeonBots:Print(labelText .. ": " .. (val and L["STATE_VISIBLE_GREEN"] or L["STATE_HIDDEN_RED"]))
            if val and DungeonBots.InitHUD and not DungeonBots[frameField] then
                DungeonBots:InitHUD()
            elseif DungeonBots.UpdateHUDVisibility then
                DungeonBots:UpdateHUDVisibility(val)
            end
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

    -- Opción 4: Selector de Idioma del Addon (Automático / Español / English)
    local langLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    langLabel:SetPoint("TOPLEFT", themeLabel, "BOTTOMLEFT", 0, -24)
    langLabel:SetText(L["SET_LANG_LABEL"])
    sf.langLabel = langLabel

    local function CreateLangChoiceBtn(name, langId, width, tipTitle, tipBody)
        local btn = CreateFrame("Button", name, sf)
        btn:SetSize(width, 24)
        ApplyInsetPanelBackdrop(btn, 8)
        btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", btn, "LEFT", 6, 0)
        label:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        label:SetJustifyH("CENTER")
        btn.label = label

        btn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            local prevSetting = (DungeonBots.GetAddonLocaleSetting and DungeonBots:GetAddonLocaleSetting()) or "auto"
            if prevSetting == langId then return end
            if DungeonBotsDB then
                DungeonBotsDB.addonLocale = langId
            end
            if DungeonBots.ApplyAddonLocale then
                DungeonBots:ApplyAddonLocale(langId)
            end
            local displayName = (langId == "esES") and L["SET_LANG_ES_LABEL"]
                or ((langId == "enUS") and L["SET_LANG_EN_LABEL"] or L["SET_LANG_AUTO_LABEL"])
            DungeonBots:UpdateSettingsDialog()
            DungeonBots:Print(string.format(L["SET_LANG_SAVED_FMT"], displayName))
            StaticPopup_Show("DUNGEONBOTS_RELOAD_LOCALE", displayName)
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

    local clientLoc = (DungeonBots.GetClientLocale and DungeonBots:GetClientLocale()) or "enUS"
    local langAutoBtn = CreateLangChoiceBtn(
        "DungeonBots_LangAutoBtn", "auto", 130,
        L["SET_LANG_AUTO_TITLE"],
        string.format(L["SET_LANG_AUTO_DESC"], clientLoc)
    )
    langAutoBtn:SetPoint("LEFT", langLabel, "RIGHT", 12, 0)
    sf.langAutoBtn = langAutoBtn

    local langEsBtn = CreateLangChoiceBtn(
        "DungeonBots_LangEsBtn", "esES", 110,
        L["SET_LANG_ES_TITLE"],
        L["SET_LANG_ES_DESC"]
    )
    langEsBtn:SetPoint("LEFT", langAutoBtn, "RIGHT", 6, 0)
    sf.langEsBtn = langEsBtn

    local langEnBtn = CreateLangChoiceBtn(
        "DungeonBots_LangEnBtn", "enUS", 110,
        L["SET_LANG_EN_TITLE"],
        L["SET_LANG_EN_DESC"]
    )
    langEnBtn:SetPoint("LEFT", langEsBtn, "RIGHT", 6, 0)
    sf.langEnBtn = langEnBtn

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
local historyTeamCards = { {}, {}, {} }
local historyTeamColumns = {}
local activeHistoryTab = 1
local historyTabButtons = {}
local historyTabFrames = {}
local HISTORY_TAB_WIDTHS = { 540, 646 }
local HISTORY_FRAME_HEIGHT = 446

StaticPopupDialogs["DUNGEONBOTS_CLEAR_HISTORY"] = {
    text = L["CLEAR_HIST_CONFIRM"],
    button1 = L["CLEAR_HIST_YES"],
    button2 = L["BTN_CANCEL"],
    OnShow = function(self)
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetFrameLevel(100)
        if self.Raise then
            self:Raise()
        end
    end,
    OnHide = function(self)
        self:SetFrameStrata("DIALOG")
    end,
    OnAccept = function()
        DungeonBots:ClearBotHistory()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["DUNGEONBOTS_RELOAD_LOCALE"] = {
    text = L["SET_LANG_RELOAD_CONFIRM"],
    button1 = L["SET_LANG_RELOAD_NOW"],
    button2 = L["SET_LANG_RELOAD_LATER"],
    OnShow = function(self)
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetFrameLevel(100)
        if self.Raise then
            self:Raise()
        end
    end,
    OnHide = function(self)
        self:SetFrameStrata("DIALOG")
    end,
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

if DB_Internal.RegisterLocaleRefresh then
    DB_Internal.RegisterLocaleRefresh(function()
        StaticPopupDialogs["DUNGEONBOTS_CLEAR_HISTORY"].text    = L["CLEAR_HIST_CONFIRM"]
        StaticPopupDialogs["DUNGEONBOTS_CLEAR_HISTORY"].button1 = L["CLEAR_HIST_YES"]
        StaticPopupDialogs["DUNGEONBOTS_CLEAR_HISTORY"].button2 = L["BTN_CANCEL"]

        StaticPopupDialogs["DUNGEONBOTS_RELOAD_LOCALE"].text    = L["SET_LANG_RELOAD_CONFIRM"]
        StaticPopupDialogs["DUNGEONBOTS_RELOAD_LOCALE"].button1 = L["SET_LANG_RELOAD_NOW"]
        StaticPopupDialogs["DUNGEONBOTS_RELOAD_LOCALE"].button2 = L["SET_LANG_RELOAD_LATER"]
    end)
end

function DungeonBots:UpdateHistorySummary()
    if not DungeonBots.historySummaryLabel then return end
    local count = DungeonBots.GetBotHistoryCount and DungeonBots:GetBotHistoryCount() or 0
    DungeonBots.historySummaryLabel:SetText(
        string.format(L["HIST_BOX_COUNT_FMT"], count)
    )
end

local historyTeamMenu = nil

local function GetBotTeamTagsText(botName)
    if not botName or not DungeonBots.IsBotInTeam then return "" end
    local tags = {}
    for teamIndex = 1, 3 do
        if DungeonBots:IsBotInTeam(teamIndex, botName) then
            table.insert(tags, tostring(teamIndex))
        end
    end
    if #tags == 0 then return "" end
    return " |cffffd100[" .. table.concat(tags, ", ") .. "]|r"
end

local function OpenHistoryTeamContextMenu(entry)
    if not entry or not entry.name then return end
    if not historyTeamMenu then
        historyTeamMenu = CreateFrame("Frame", "DungeonBots_HistoryTeamMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local targetEntry = entry
    UIDropDownMenu_Initialize(historyTeamMenu, function(self, level)
        if not level then return end
        local info = UIDropDownMenu_CreateInfo()
        info.text = targetEntry.name
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        local maxMembers = DungeonBots.MAX_BOT_TEAM_MEMBERS or 4
        for teamIndex = 1, 3 do
            local tIdx = teamIndex
            local members = (DungeonBots.GetBotTeam and DungeonBots:GetBotTeam(tIdx)) or {}
            local inTeam = DungeonBots.IsBotInTeam and DungeonBots:IsBotInTeam(tIdx, targetEntry.name)
            local isFull = (#members >= maxMembers)
            local btn = UIDropDownMenu_CreateInfo()
            btn.text = string.format(L["HIST_MENU_TEAM_FMT"], tIdx) .. " (" .. #members .. "/" .. maxMembers .. ")"
            btn.checked = inTeam and true or false
            btn.disabled = (not inTeam and isFull) and true or false
            btn.keepShownOnClick = false
            btn.func = function()
                PlaySound("igMainMenuOptionCheckBoxOn")
                if inTeam then
                    if DungeonBots.RemoveBotFromTeam then
                        DungeonBots:RemoveBotFromTeam(tIdx, targetEntry.name)
                    end
                elseif not isFull then
                    if DungeonBots.AddBotToTeam then
                        DungeonBots:AddBotToTeam(tIdx, targetEntry.name, targetEntry)
                    end
                end
            end
            UIDropDownMenu_AddButton(btn, level)
        end
    end, "MENU")

    ToggleDropDownMenu(1, nil, historyTeamMenu, "cursor", 3, -3)
    if DropDownList1 and DropDownList1:IsShown() then
        DropDownList1:SetFrameStrata("FULLSCREEN_DIALOG")
        DropDownList1:Raise()
    end
end

local function ApplyHistoryTabVisualState(selectedIdx)
    local hf = DungeonBots.historyFrame
    local baseLevel = (hf and hf.GetFrameLevel and hf:GetFrameLevel()) or 24
    for i, btn in ipairs(historyTabButtons) do
        if btn then
            local isSelected = (i == selectedIdx)
            btn:SetFrameLevel(isSelected and (baseLevel + 3) or (baseLevel + 1))
            if btn.checked then
                if isSelected then btn.checked:Show() else btn.checked:Hide() end
            end
            if btn.icon then
                local c = isSelected and 1.0 or 0.52
                btn.icon:SetVertexColor(c, c, c)
            end
            if btn.bg then
                local bgc = isSelected and 1.0 or 0.75
                btn.bg:SetVertexColor(bgc, bgc, bgc)
            end
        end
    end
end

function DungeonBots:SelectHistoryTab(tabIndex)
    if tabIndex ~= 1 and tabIndex ~= 2 then
        tabIndex = 1
    end
    activeHistoryTab = tabIndex
    CloseDropDownMenus()

    local hf = DungeonBots.historyFrame
    if not hf then return end

    local width = HISTORY_TAB_WIDTHS[tabIndex] or 540
    hf:SetSize(width, HISTORY_FRAME_HEIGHT)

    for i, frame in ipairs(historyTabFrames) do
        if frame then
            if i == tabIndex then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end

    ApplyHistoryTabVisualState(tabIndex)

    if tabIndex == 1 then
        if DungeonBots.UpdateHistoryUI then
            DungeonBots:UpdateHistoryUI()
        end
    else
        if DungeonBots.UpdateHistoryTeamsUI then
            DungeonBots:UpdateHistoryTeamsUI()
        end
    end
end

local function CreateHistoryRow(parent, idx)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(480, 50)
    row:EnableMouse(true)
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

    row:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and self.botEntry then
            PlaySound("igMainMenuOptionCheckBoxOn")
            OpenHistoryTeamContextMenu(self.botEntry)
        end
    end)
    row:SetScript("OnEnter", function(self)
        if not self.botEntry then return end
        local _, classColor = DungeonBots:GetClassDisplayInfo(self.botEntry.class)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(self.botEntry.name, classColor.r, classColor.g, classColor.b)
        GameTooltip:AddLine(L["HIST_ROW_RIGHT_CLICK_TIP"], 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    historyRows[idx] = row
    return row
end

local function CreateTeamMemberCard(parent, teamIndex, idx)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(186, 48)
    card:EnableMouse(true)
    ApplyInsetPanelBackdrop(card, 6)

    local iconFrame = CreateFrame("Frame", nil, card)
    iconFrame:SetSize(24, 24)
    iconFrame:SetPoint("LEFT", card, "LEFT", 5, 0)
    ApplyInsetPanelBackdrop(iconFrame, 4)
    local function StyleTeamIconFrame(f)
        local p = DB_Internal.GetThemePalette and DB_Internal.GetThemePalette()
        if not p then return end
        f:SetBackdropColor(p.historyIconBg[1], p.historyIconBg[2], p.historyIconBg[3], p.historyIconBg[4])
        f:SetBackdropBorderColor(p.headerBorder[1], p.headerBorder[2], p.headerBorder[3], p.headerBorder[4])
    end
    StyleTeamIconFrame(iconFrame)
    if DB_Internal.RegisterThemed then
        DB_Internal.RegisterThemed(iconFrame, StyleTeamIconFrame)
    end

    card.icon = iconFrame:CreateTexture(nil, "ARTWORK")
    card.icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 2, -2)
    card.icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
    card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    card.removeBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    card.removeBtn:SetSize(18, 18)
    card.removeBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -4, -4)
    card.removeBtn:SetText("X")
    card.removeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["HIST_TEAM_REMOVE_TIP"], 1, 0.4, 0.4)
        GameTooltip:Show()
    end)
    card.removeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    card.nameText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.nameText:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 6, 4)
    card.nameText:SetPoint("RIGHT", card.removeBtn, "LEFT", -3, 0)
    card.nameText:SetJustifyH("LEFT")
    card.nameText:SetWordWrap(false)

    card.detailText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.detailText:SetPoint("TOPLEFT", card.nameText, "BOTTOMLEFT", 0, -2)
    card.detailText:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -6, 3)
    card.detailText:SetJustifyH("LEFT")
    card.detailText:SetJustifyV("TOP")
    card.detailText:SetWordWrap(true)

    card:SetScript("OnEnter", function(self)
        if not self.botName then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(self.botName, self.classR or 1, self.classG or 1, self.classB or 1)
        if self.detailTooltip then
            GameTooltip:AddLine(self.detailTooltip, 0.75, 0.90, 1.0, true)
        end
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", function() GameTooltip:Hide() end)

    historyTeamCards[teamIndex][idx] = card
    return card
end

function DungeonBots:UpdateHistoryTeamsUI()
    if not DungeonBots.historyFrame then return end

    local maxMembers = DungeonBots.MAX_BOT_TEAM_MEMBERS or 4
    local defaultQuestionIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
    for teamIndex = 1, 3 do
        local col = historyTeamColumns[teamIndex]
        if col then
            local members = (DungeonBots.GetBotTeam and DungeonBots:GetBotTeam(teamIndex)) or {}
            col.titleText:SetText(string.format(L["HIST_TEAM_TITLE_FMT"], teamIndex))

            local cards = historyTeamCards[teamIndex]
            for _, card in ipairs(cards) do
                card:Hide()
            end

            if #members == 0 then
                col.emptyLabel:Show()
                col.summonBtn:Disable()
                col.summonBtn:SetText(L["HIST_TEAM_SUMMON_BTN"])
            else
                col.emptyLabel:Hide()
                local allInPartyOnline = true
                local visibleCount = math.min(#members, maxMembers)

                for idx = 1, visibleCount do
                    local entry = members[idx]
                    local card = cards[idx] or CreateTeamMemberCard(col.frame, teamIndex, idx)
                    card:ClearAllPoints()
                    card:SetPoint("TOPLEFT", col.frame, "TOPLEFT", 8, -36 - ((idx - 1) * 53))
                    card:Show()

                    local className, classColor, classIcon = DungeonBots:GetClassDisplayInfo(entry.class)
                    local displayIcon = entry.raceIcon
                    if not displayIcon or displayIcon == "" or displayIcon == defaultQuestionIcon then
                        displayIcon = classIcon
                    end
                    card.icon:SetTexture(displayIcon)

                    local botName = entry.name
                    local unit = DungeonBots:FindPartyUnitByName(botName)
                    local inPartyOnline = (unit ~= nil and UnitIsConnected(unit)) and true or false
                    if not inPartyOnline then
                        allInPartyOnline = false
                    end

                    card.botName = botName
                    card.classR = classColor.r
                    card.classG = classColor.g
                    card.classB = classColor.b

                    if unit ~= nil then
                        card.nameText:SetText(botName .. " |cff44ff44*|r")
                    else
                        card.nameText:SetText(botName)
                    end
                    card.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)

                    local cleanSpec = DungeonBots.CleanSpecText and DungeonBots:CleanSpecText(entry.spec) or (entry.spec or "")
                    local displaySpec = (cleanSpec ~= "")
                        and ((DungeonBots.LocalizeSpecText and DungeonBots:LocalizeSpecText(cleanSpec)) or cleanSpec)
                        or ""
                    local specText = (displaySpec ~= "") and ("|cff71d5ff" .. displaySpec .. "|r") or L["HIST_DEFAULT_TALENTS"]
                    local fullDetail = className .. " - " .. specText
                    card.detailText:SetText(fullDetail)
                    card.detailTooltip = fullDetail .. (unit ~= nil and L["HIST_IN_PARTY_TAG"] or "")

                    local tIdx = teamIndex
                    local targetBotName = botName
                    card.removeBtn:SetScript("OnClick", function()
                        PlaySound("igMainMenuOptionCheckBoxOff")
                        if DungeonBots.RemoveBotFromTeam then
                            DungeonBots:RemoveBotFromTeam(tIdx, targetBotName)
                        end
                    end)
                end

                if allInPartyOnline then
                    col.summonBtn:Disable()
                    col.summonBtn:SetText(L["HIST_TEAM_ALL_IN_PARTY"])
                else
                    col.summonBtn:Enable()
                    col.summonBtn:SetText(L["HIST_TEAM_SUMMON_BTN"])
                end
            end
        end
    end
end

function DungeonBots:BuildHistoryDialog()
    if DungeonBots.historyFrame then return end

    local hf = CreateFrame("Frame", "DungeonBots_HistoryFrame", UIParent)
    hf:SetSize(HISTORY_TAB_WIDTHS[1], HISTORY_FRAME_HEIGHT)
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
    hf:SetScript("OnHide", function() CloseDropDownMenus() end)
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

    -- Right-side SpellBook-style tabs (matching MainUI)
    historyTabButtons = {}
    historyTabFrames = {}
    local tabDefs = {
        { name = L["HIST_TAB1_NAME"], desc = L["HIST_TAB1_TIP"], icon = "Interface\\Icons\\INV_Misc_Note_01" },
        { name = L["HIST_TAB2_NAME"], desc = L["HIST_TAB2_TIP"], icon = "Interface\\Icons\\INV_Misc_GroupNeedMore" },
    }
    for i, info in ipairs(tabDefs) do
        local tabBtn = CreateFrame("Button", "DungeonBots_HistorySideTab" .. i, hf)
        tabBtn:SetSize(32, 32)
        tabBtn:SetPoint("TOPLEFT", hf, "TOPRIGHT", -1, -48 - ((i - 1) * 46))

        local bg = tabBtn:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
        bg:SetSize(64, 64)
        bg:SetPoint("TOPLEFT", tabBtn, "TOPLEFT", -3, 11)
        tabBtn.bg = bg

        local tIcon = tabBtn:CreateTexture(nil, "BORDER")
        tIcon:SetSize(26, 26)
        tIcon:SetPoint("CENTER", 0, 0)
        tIcon:SetTexture(info.icon)
        tIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        tabBtn.icon = tIcon

        tabBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        local checked = tabBtn:CreateTexture(nil, "OVERLAY")
        checked:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        checked:SetBlendMode("ADD")
        checked:SetSize(30, 30)
        checked:SetPoint("CENTER", 0, 0)
        tabBtn.checked = checked

        local tabIdx = i
        local tabInfo = info
        tabBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(tabInfo.name, 1, 0.82, 0)
            GameTooltip:AddLine(tabInfo.desc, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        tabBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        tabBtn:SetScript("OnClick", function()
            PlaySound("igCharacterInfoTab")
            DungeonBots:SelectHistoryTab(tabIdx)
        end)

        historyTabButtons[i] = tabBtn
    end

    -- Tab 1: Bot History
    local tab1Frame = CreateFrame("Frame", nil, hf)
    tab1Frame:SetAllPoints(hf)
    historyTabFrames[1] = tab1Frame

    local countLabel = tab1Frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    countLabel:SetPoint("TOPLEFT", 14, -40)
    countLabel:SetText(L["HIST_TOTAL_ZERO"])
    hf.countLabel = countLabel

    local rightClickHint = tab1Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rightClickHint:SetPoint("TOPLEFT", 14, -55)
    rightClickHint:SetText("|cffb0b0b0" .. L["HIST_RIGHT_CLICK_HINT"] .. "|r")

    local clearBtn = CreateFrame("Button", nil, tab1Frame, "UIPanelButtonTemplate")
    clearBtn:SetSize(105, 22)
    clearBtn:SetPoint("TOPRIGHT", tab1Frame, "TOPRIGHT", -14, -42)
    clearBtn:SetText(L["HIST_CLEAR_ALL"])
    clearBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        StaticPopup_Show("DUNGEONBOTS_CLEAR_HISTORY")
    end)

    local scrollBg = CreateFrame("Frame", nil, tab1Frame)
    scrollBg:SetPoint("TOPLEFT", tab1Frame, "TOPLEFT", 10, -72)
    scrollBg:SetPoint("BOTTOMRIGHT", tab1Frame, "BOTTOMRIGHT", -10, 52)
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

    local addNameLabel = tab1Frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    addNameLabel:SetPoint("BOTTOMLEFT", tab1Frame, "BOTTOMLEFT", 14, 22)
    addNameLabel:SetText(L["HIST_ADD_LABEL"])

    local addNameBox = CreateFrame("EditBox", "DungeonBots_HistAddNameBox", tab1Frame, "InputBoxTemplate")
    addNameBox:SetSize(180, 20)
    addNameBox:SetPoint("LEFT", addNameLabel, "RIGHT", 10, 0)
    addNameBox:SetAutoFocus(false)
    addNameBox:SetMaxLetters(32)
    hf.addNameBox = addNameBox

    local addNameBtn = CreateFrame("Button", nil, tab1Frame, "UIPanelButtonTemplate")
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

    -- Tab 2: 3 Saved Bot Team Columns
    local tab2Frame = CreateFrame("Frame", nil, hf)
    tab2Frame:SetAllPoints(hf)
    tab2Frame:Hide()
    historyTabFrames[2] = tab2Frame

    local teamHintLabel = tab2Frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    teamHintLabel:SetPoint("TOPLEFT", tab2Frame, "TOPLEFT", 14, -44)
    teamHintLabel:SetText("|cffb0b0b0" .. L["HIST_TEAM_FOOTER_HINT"] .. "|r")

    historyTeamColumns = {}
    local colWidth = 202
    local colGap = 8
    for teamIndex = 1, 3 do
        local startX = 12 + ((teamIndex - 1) * (colWidth + colGap))
        local colFrame = CreateFrame("Frame", nil, tab2Frame)
        colFrame:SetWidth(colWidth)
        colFrame:SetPoint("TOPLEFT", tab2Frame, "TOPLEFT", startX, -64)
        colFrame:SetPoint("BOTTOMLEFT", tab2Frame, "BOTTOMLEFT", startX, 50)
        ApplyBlizzardStonePanel(colFrame, 0.66, 0.54, 0.30, 10, 0.28)

        local colHeader = CreateFrame("Frame", nil, colFrame)
        colHeader:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 4, -4)
        colHeader:SetPoint("TOPRIGHT", colFrame, "TOPRIGHT", -4, -4)
        colHeader:SetHeight(24)
        ApplyHeaderBackdrop(colHeader)

        local colTitle = colHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        colTitle:SetPoint("CENTER", colHeader, "CENTER", 0, 0)
        colTitle:SetText(string.format(L["HIST_TEAM_TITLE_FMT"], teamIndex))

        local colEmpty = colFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        colEmpty:SetPoint("CENTER", colFrame, "CENTER", 0, 4)
        colEmpty:SetWidth(176)
        colEmpty:SetJustifyH("CENTER")
        colEmpty:SetTextColor(0.65, 0.65, 0.65)
        colEmpty:SetText(L["HIST_TEAM_EMPTY"])

        local tIdx = teamIndex
        local summonBtn = CreateFrame("Button", nil, colFrame, "UIPanelButtonTemplate")
        summonBtn:SetSize(128, 22)
        summonBtn:SetPoint("BOTTOM", colFrame, "BOTTOM", 0, 10)
        summonBtn:SetText(L["HIST_TEAM_SUMMON_BTN"])
        summonBtn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            if DungeonBots.SummonBotTeam then
                DungeonBots:SummonBotTeam(tIdx)
            end
        end)
        summonBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(L["HIST_TEAM_SUMMON_BTN"], 1, 0.85, 0.2)
            GameTooltip:AddLine(string.format(L["HIST_TEAM_SUMMON_TIP"], tIdx), 0.85, 0.85, 0.85, true)
            GameTooltip:Show()
        end)
        summonBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        historyTeamColumns[teamIndex] = {
            frame = colFrame,
            titleText = colTitle,
            emptyLabel = colEmpty,
            summonBtn = summonBtn,
        }
    end

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
    DungeonBots:SelectHistoryTab(activeHistoryTab)
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
        if DungeonBots.UpdateHistoryTeamsUI then
            DungeonBots:UpdateHistoryTeamsUI()
        end
        return
    end

    hf.emptyLabel:Hide()

    local defaultQuestionIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
    for idx, entry in ipairs(list) do
        local row = historyRows[idx] or CreateHistoryRow(hf.scrollChild, idx)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", hf.scrollChild, "TOPLEFT", 2, -((idx - 1) * 54) - 2)
        row:Show()
        row.botEntry = entry

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
        row.detailText:SetText(className .. " - " .. specText .. GetBotTeamTagsText(botName))

        local isLoading = (DungeonBots.IsHistoryBotLoading and DungeonBots:IsHistoryBotLoading(botName)) and true or false
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
        elseif isLoading then
            row.inviteBtn:SetText(L["BTN_LOADING"])
            row.inviteBtn:Disable()
            row.inviteBtn:SetScript("OnClick", nil)
            row.inviteBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(string.format(L["HIST_INVITE_TITLE"], botName), 1, 0.85, 0.2)
                GameTooltip:AddLine(L["WAIT_BOT_RESPONSE"], 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
        else
            row.inviteBtn:SetText(L["BTN_INVITE"])
            row.inviteBtn:Enable()
            row.inviteBtn:SetScript("OnClick", function()
                PlaySound("igMainMenuOptionCheckBoxOn")
                DungeonBots:SummonAndInviteHistoryBot(botName)
                DungeonBots:UpdateHistoryUI()
            end)
            row.inviteBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(string.format(L["HIST_INVITE_TITLE"], botName), 1, 1, 1)
                GameTooltip:AddLine(string.format(L["HIST_INVITE_DESC"], botName), 0.7, 0.8, 1.0, true)
                GameTooltip:Show()
            end)
        end
        row.inviteBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        if inParty then
            row.removeBtn:Disable()
            row.removeBtn:SetScript("OnClick", nil)
            row.removeBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(L["DEL_HIST_TIP_TITLE"], 0.6, 0.6, 0.6)
                GameTooltip:AddLine(L["DEL_HIST_IN_PARTY_DESC"], 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
        else
            row.removeBtn:Enable()
            row.removeBtn:SetScript("OnClick", function()
                PlaySound("igMainMenuOptionCheckBoxOff")
                DungeonBots:RemoveFromHistory(botName)
            end)
            row.removeBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(L["DEL_HIST_TIP_TITLE"], 1, 0.3, 0.3)
                GameTooltip:AddLine(L["DEL_HIST_TIP_DESC"], 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
        end
    end

    hf.scrollChild:SetHeight(math.max(1, (#list * 54) + 6))
    if DungeonBots.UpdateHistoryTeamsUI then
        DungeonBots:UpdateHistoryTeamsUI()
    end
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
