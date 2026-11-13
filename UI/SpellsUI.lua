-- =========================================================================
-- DungeonBots_SpellsUI.lua: Ventana de Información del Personaje
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
    end
    return ApplyDarkBackdrop(frame, edgeSize)
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

local function CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
    return DB_Internal.CreateRedIconButton(parent, width, height, text, iconPath, centerIcon)
end

local function SafeShowLinkTooltip(owner, linkRef, displayLink, title, rawLine)
    return DB_Internal.SafeShowLinkTooltip(owner, linkRef, displayLink, title, rawLine)
end

local MODE_TABS = {
    { id = "gear",   label = L["CHAR_TAB_GEAR"],   icon = "Interface\\Icons\\INV_Chest_Plate01" },
    { id = "spells", label = L["CHAR_TAB_SPELLS"], icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    { id = "glyphs", label = L["CHAR_TAB_GLYPHS"], icon = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
}

local function BuildGearPanel(sp)
    local gearPanel = CreateFrame("Frame", "DungeonBots_GearPanel", sp)
    gearPanel:SetPoint("TOPLEFT", sp, "TOPLEFT", 10, -76)
    gearPanel:SetPoint("BOTTOMRIGHT", sp, "BOTTOMRIGHT", -10, 42)
    gearPanel:Hide()
    sp.gearPanel = gearPanel

    -- Seccion 1: Cambio de rama de talentos
    local specCard = CreateFrame("Frame", "DungeonBots_GearSpecCard", gearPanel)
    specCard:SetPoint("TOPLEFT", gearPanel, "TOPLEFT", 0, 0)
    specCard:SetPoint("TOPRIGHT", gearPanel, "TOPRIGHT", 0, 0)
    specCard:SetHeight(168)
    ApplyBlizzardStonePanel(specCard, 0.66, 0.54, 0.30, 12, 0.30)
    gearPanel.specCard = specCard

    local specHeaderIcon = specCard:CreateTexture(nil, "ARTWORK")
    specHeaderIcon:SetSize(18, 18)
    specHeaderIcon:SetPoint("TOPLEFT", specCard, "TOPLEFT", 12, -10)
    specHeaderIcon:SetTexture("Interface\\Icons\\Ability_Marksmanship")
    specHeaderIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local specTitle = specCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specTitle:SetPoint("LEFT", specHeaderIcon, "RIGHT", 7, 0)
    specTitle:SetText(L["CHAR_SPEC_SECTION"])

    local specSubLabel = specCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    specSubLabel:SetPoint("TOPLEFT", specCard, "TOPLEFT", 12, -33)
    specSubLabel:SetText(L["CHAR_SPEC_SUB"])

    gearPanel.specButtons = {}
    local btnW, btnH = 164, 26
    local gapX, gapY = 8, 6
    local startX, startY = 14, -54
    for idx = 1, 9 do
        local col = (idx - 1) % 3
        local row = math.floor((idx - 1) / 3)
        local sBtn = CreateFrame("Button", "DungeonBots_GearSpecBtn_" .. idx, specCard)
        sBtn:SetSize(btnW, btnH)
        sBtn:SetPoint("TOPLEFT", specCard, "TOPLEFT", startX + (col * (btnW + gapX)), startY - (row * (btnH + gapY)))
        ApplyInsetPanelBackdrop(sBtn, 8)
        if DB_Internal.AddGoldWarmFill then
            sBtn.goldWarmFill = DB_Internal.AddGoldWarmFill(sBtn, "BORDER", "warmFillSlot")
        end
        sBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

        local accentBar = sBtn:CreateTexture(nil, "OVERLAY")
        accentBar:SetHeight(2)
        accentBar:SetPoint("BOTTOMLEFT", sBtn, "BOTTOMLEFT", 4, 2)
        accentBar:SetPoint("BOTTOMRIGHT", sBtn, "BOTTOMRIGHT", -4, 2)
        accentBar:SetTexture(1.0, 0.82, 0.24, 1.0)
        accentBar:Hide()
        sBtn.accentBar = accentBar

        local label = sBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", sBtn, "LEFT", 8, 0)
        label:SetPoint("RIGHT", sBtn, "RIGHT", -8, 0)
        label:SetJustifyH("CENTER")
        sBtn.label = label
        sBtn:Hide()
        gearPanel.specButtons[idx] = sBtn
    end

    local emptySpecsLabel = specCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptySpecsLabel:SetPoint("CENTER", specCard, "CENTER", 0, -18)
    emptySpecsLabel:SetWidth(460)
    emptySpecsLabel:SetText(L["CHAR_SPEC_EMPTY"])
    emptySpecsLabel:Hide()
    gearPanel.emptySpecsLabel = emptySpecsLabel

    -- Seccion 2: Gestion de equipo (d autogear)
    local autogearCard = CreateFrame("Frame", "DungeonBots_GearAutogearCard", gearPanel)
    autogearCard:SetPoint("TOPLEFT", specCard, "BOTTOMLEFT", 0, -10)
    autogearCard:SetPoint("TOPRIGHT", specCard, "BOTTOMRIGHT", 0, -10)
    autogearCard:SetPoint("BOTTOMRIGHT", gearPanel, "BOTTOMRIGHT", 0, 0)
    ApplyBlizzardStonePanel(autogearCard, 0.66, 0.54, 0.30, 12, 0.30)
    gearPanel.autogearCard = autogearCard

    local gearHeaderIcon = autogearCard:CreateTexture(nil, "ARTWORK")
    gearHeaderIcon:SetSize(18, 18)
    gearHeaderIcon:SetPoint("TOPLEFT", autogearCard, "TOPLEFT", 12, -10)
    gearHeaderIcon:SetTexture("Interface\\Icons\\INV_Chest_Plate01")
    gearHeaderIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local gearTitle = autogearCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gearTitle:SetPoint("LEFT", gearHeaderIcon, "RIGHT", 7, 0)
    gearTitle:SetText(L["CHAR_GEAR_SECTION"])

    local gearSubLabel = autogearCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    gearSubLabel:SetPoint("TOPLEFT", autogearCard, "TOPLEFT", 12, -33)
    gearSubLabel:SetPoint("TOPRIGHT", autogearCard, "TOPRIGHT", -12, -33)
    gearSubLabel:SetJustifyH("LEFT")
    gearSubLabel:SetText(L["CHAR_GEAR_SUB"])

    local autogearBox = CreateFrame("Frame", nil, autogearCard)
    autogearBox:SetPoint("TOPLEFT", autogearCard, "TOPLEFT", 14, -56)
    autogearBox:SetPoint("BOTTOMRIGHT", autogearCard, "BOTTOMRIGHT", -14, 14)
    ApplyInsetPanelBackdrop(autogearBox, 8)
    if DB_Internal.AddGoldWarmFill then
        DB_Internal.AddGoldWarmFill(autogearBox, "BORDER", "warmFillSlot")
    end

    local autogearBtn = CreateFrame("Button", "DungeonBots_GearAutogearBtn", autogearBox, "UIPanelButtonTemplate")
    autogearBtn:SetSize(120, 30)
    autogearBtn:SetPoint("LEFT", autogearBox, "LEFT", 16, 0)
    autogearBtn:SetText(L["CHAR_AUTOGEAR_BTN"])
    gearPanel.autogearBtn = autogearBtn

    local autogearDesc = autogearBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autogearDesc:SetPoint("LEFT", autogearBtn, "RIGHT", 16, 0)
    autogearDesc:SetPoint("RIGHT", autogearBox, "RIGHT", -16, 0)
    autogearDesc:SetPoint("TOP", autogearBox, "TOP", 0, -10)
    autogearDesc:SetPoint("BOTTOM", autogearBox, "BOTTOM", 0, 10)
    autogearDesc:SetJustifyH("LEFT")
    autogearDesc:SetJustifyV("MIDDLE")
    autogearDesc:SetText(L["CHAR_AUTOGEAR_DESC"])
end

local SPELL_ROW_HEIGHT = 40
local SPELL_ROW_PITCH = 43

local spellRowButtons = {}

local function HideRowPool(pool, fromIndex)
    for i = (fromIndex or 1), #pool do
        local row = pool[i]
        row.spellEntry = nil
        row:Hide()
    end
end

local function ConfigureIconTabButton(btn, iconPath, texCoord)
    local tex = btn:CreateTexture(nil, "OVERLAY")
    tex:SetSize(16, 16)
    tex:SetPoint("LEFT", btn, "LEFT", 10, 0)
    local tc = texCoord or { 0.08, 0.92, 0.08, 0.92 }
    tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
    if iconPath then
        tex:SetTexture(iconPath)
    end
    btn.tabIcon = tex

    local fs = btn.GetFontString and btn:GetFontString()
    if fs then
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", tex, "RIGHT", 4, 0)
        fs:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
        fs:SetJustifyH("CENTER")
    end
end

local function FormatReagentsSummary(reagents)
    if type(reagents) ~= "table" or #reagents == 0 then
        return nil
    end
    local parts = {}
    for _, reg in ipairs(reagents) do
        local label = reg.displayLink or ("[" .. (reg.name or reg.rawName or L["ITEM_DEFAULT"]) .. "]")
        if reg.count and reg.count > 1 then
            label = label .. " x" .. reg.count
        end
        if reg.buyable then
            label = label .. L["SPELL_BUY_TAG"]
        end
        table.insert(parts, label)
    end
    return L["SPELL_MAT_PREFIX"] .. table.concat(parts, ", ")
end

local function FormatPowerAndCastMeta(entry)
    if not entry then return nil end
    local parts = {}
    if entry.cost and entry.cost > 0 then
        local powerLabels = {
            [0] = L["SPELL_MANA"],
            [1] = L["SPELL_RAGE"],
            [2] = L["SPELL_FOCUS"],
            [3] = L["SPELL_ENERGY"],
            [6] = L["SPELL_RUNIC"],
        }
        local unitTxt = powerLabels[entry.powerType] or L["SPELL_COST"]
        table.insert(parts, entry.cost .. " " .. unitTxt)
    end
    if entry.castTime ~= nil then
        if entry.castTime == 0 then
            table.insert(parts, L["SPELL_INSTANT"])
        else
            table.insert(parts, string.format(L["SPELL_CAST_SEC_FMT"], entry.castTime / 1000))
        end
    end
    if entry.maxRange and entry.maxRange > 0 then
        table.insert(parts, string.format(L["SPELL_RANGE_YD_FMT"], entry.maxRange))
    end
    if #parts == 0 then return nil end
    return "|cff8899aa" .. table.concat(parts, "  |  ") .. "|r"
end

local function IsBotCastingNow(botName)
    if not botName or botName == "" then return false, nil end
    local unit = DungeonBots.FindPartyUnitByName and DungeonBots:FindPartyUnitByName(botName)
    if not unit then return false, nil end
    local castSpell = UnitCastingInfo and UnitCastingInfo(unit)
    if castSpell then
        return true, castSpell
    end
    local chanSpell = UnitChannelInfo and UnitChannelInfo(unit)
    if chanSpell then
        return true, chanSpell
    end
    return false, nil
end

local UpdateCancelCastButtonState

local function OnCastWatchUpdate(self, elapsed)
    self._acc = (self._acc or 0) + (elapsed or 0)
    if self._acc < 0.1 then return end
    self._acc = 0
    if UpdateCancelCastButtonState then
        UpdateCancelCastButtonState()
    end
end

UpdateCancelCastButtonState = function()
    local sp = DungeonBots.spellsFrame
    if not sp or not sp.cancelBtn then return end

    if not sp:IsShown() or sp.activeMode ~= "spells" then
        sp.cancelBtn:UnlockHighlight()
        sp.cancelBtn:Disable()
        sp.cancelBtn:SetAlpha(0.45)
        if sp.castWatchFrame then
            sp.castWatchFrame:SetScript("OnUpdate", nil)
        end
        return
    end

    local isCasting, spellName = IsBotCastingNow(sp.currentBot)
    sp.cancelBtn.activeCastSpell = spellName
    if isCasting then
        sp.cancelBtn:Enable()
        sp.cancelBtn:SetAlpha(1.0)
        sp.cancelBtn:LockHighlight()
        if sp.castWatchFrame then
            sp.castWatchFrame._acc = 0
            sp.castWatchFrame:SetScript("OnUpdate", OnCastWatchUpdate)
        end
    else
        sp.cancelBtn:UnlockHighlight()
        sp.cancelBtn:Disable()
        sp.cancelBtn:SetAlpha(0.45)
        if sp.castWatchFrame then
            sp.castWatchFrame:SetScript("OnUpdate", nil)
        end
    end

    if GameTooltip and GameTooltip:IsShown() and GameTooltip:GetOwner() == sp.cancelBtn and sp.cancelBtn.RefreshTooltip then
        sp.cancelBtn:RefreshTooltip()
    end
end

local function UpdateSpellSelectionUI()
    local sp = DungeonBots.spellsFrame
    if not sp then return end

    local selected = sp.selectedSpell
    for _, row in ipairs(spellRowButtons) do
        if row:IsShown() and row.spellEntry then
            if row.spellEntry.kind == "glyph" then
                row.selOverlay:Hide()
                row:SetBackdropBorderColor(0.25, 0.52, 0.85, 0.90)
            elseif row.spellEntry.kind == "talent" then
                row.selOverlay:Hide()
                local isMax = (row.spellEntry.currentRank or 0) >= (row.spellEntry.maxRank or 1)
                if isMax then
                    row:SetBackdropBorderColor(0.90, 0.72, 0.18, 0.90)
                else
                    row:SetBackdropBorderColor(0.25, 0.78, 0.45, 0.85)
                end
            elseif selected ~= nil and row.spellEntry == selected then
                row.selOverlay:Show()
                row:SetBackdropBorderColor(1.0, 0.85, 0.15, 1.0)
            else
                row.selOverlay:Hide()
                local diff = row.spellEntry.difficulty
                if diff then
                    row:SetBackdropBorderColor(diff.r, diff.g, diff.b, 0.70)
                else
                    local ib = (DB_Internal.GetThemePalette and DB_Internal.GetThemePalette().insetBorder) or { 0.54, 0.44, 0.26, 0.85 }
                    row:SetBackdropBorderColor(ib[1], ib[2], ib[3], ib[4])
                end
            end
        end
    end

    if sp.activeMode == "spells" then
        if selected then
            sp.castBtn:Enable()
            sp.castBtn:SetAlpha(1.0)
        else
            sp.castBtn:Disable()
            sp.castBtn:SetAlpha(0.45)
        end
        if UpdateCancelCastButtonState then
            UpdateCancelCastButtonState()
        end
    end
end

local function CreateSpellRowButton(parent, idx)
    local row = CreateFrame("Button", "DungeonBots_SpellRow_" .. idx, parent)
    row:SetSize(492, SPELL_ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -((idx - 1) * SPELL_ROW_PITCH) - 4)
    ApplyInsetPanelBackdrop(row, 8)
    row:RegisterForClicks("LeftButtonUp")

    local iconBg = row:CreateTexture(nil, "BACKGROUND")
    iconBg:SetSize(32, 32)
    iconBg:SetPoint("LEFT", row, "LEFT", 6, 0)
    iconBg:SetTexture(0.02, 0.02, 0.03, 1.0)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(30, 30)
    icon:SetPoint("CENTER", iconBg, "CENTER", 0, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local diffBadge = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    diffBadge:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -5)
    diffBadge:SetWidth(90)
    diffBadge:SetJustifyH("RIGHT")
    row.diffBadge = diffBadge

    local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", iconBg, "TOPRIGHT", 8, -1)
    nameLabel:SetPoint("RIGHT", diffBadge, "LEFT", -6, 0)
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetWordWrap(false)
    row.nameLabel = nameLabel

    local subLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subLabel:SetPoint("BOTTOMLEFT", iconBg, "BOTTOMRIGHT", 8, 1)
    subLabel:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    subLabel:SetJustifyH("LEFT")
    subLabel:SetWordWrap(false)
    row.subLabel = subLabel

    local selOverlay = row:CreateTexture(nil, "OVERLAY")
    selOverlay:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -2)
    selOverlay:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 2)
    selOverlay:SetTexture(1.0, 0.85, 0.15, 0.12)
    selOverlay:Hide()
    row.selOverlay = selOverlay

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -2)
    hl:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 2)
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetBlendMode("ADD")
    hl:SetAlpha(0.18)

    local function SyncRowVisuals(self, entry)
        if not entry or not DB_Internal.ResolveSpellEntryVisuals then return end
        if DB_Internal.ResolveSpellEntryVisuals(entry, false) then
            self.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            local titleTxt = entry.name or entry.rawName or (entry.kind == "glyph" and L["GLYPH_DEFAULT"] or L["SPELL_DEFAULT"])
            if entry.rank and entry.rank ~= "" then
                titleTxt = titleTxt .. " |cff888888(" .. entry.rank .. ")|r"
            end
            self.nameLabel:SetText(titleTxt)
        end
    end

    row:SetScript("OnEnter", function(self)
        local entry = self.spellEntry
        if not entry then return end

        local isGlyph = (entry.kind == "glyph")
        local linkToShow = entry.displayLink or entry.rawLink

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local loadedRich = false
        if isGlyph and linkToShow and string.find(linkToShow, "|H", 1, true) and GameTooltip.SetHyperlink then
            loadedRich = pcall(GameTooltip.SetHyperlink, GameTooltip, linkToShow)
        end
        if not loadedRich then
            if entry.spellId and GameTooltip.SetHyperlink then
                loadedRich = pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. entry.spellId)
            elseif entry.itemId and GameTooltip.SetHyperlink then
                loadedRich = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. entry.itemId)
            elseif linkToShow and string.find(linkToShow, "|H", 1, true) and GameTooltip.SetHyperlink then
                loadedRich = pcall(GameTooltip.SetHyperlink, GameTooltip, linkToShow)
            end
        end
        if not loadedRich or (GameTooltip.NumLines and GameTooltip:NumLines() == 0) then
            GameTooltip:ClearLines()
            local fallbackTitle = entry.name or entry.rawName or (isGlyph and L["GLYPH_DEFAULT"] or L["SPELL_DEFAULT"])
            GameTooltip:AddLine(fallbackTitle, 0.45, 0.85, 1.0)
        end

        SyncRowVisuals(self, entry)

        if isGlyph then
            if entry.categoryTag then
                GameTooltip:AddLine(string.format(L["SPELL_TIP_TYPE_FMT"], entry.categoryTag), 0.44, 0.84, 1.0)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["SPELL_TIP_SHIFT_CHAT"], 0.8, 0.8, 0.8)
            GameTooltip:Show()
            return
        end

        if entry.reagents and #entry.reagents > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["SPELL_TIP_MATS"], 1, 0.82, 0)
            for _, reg in ipairs(entry.reagents) do
                local lineTxt = reg.name or reg.rawName or L["ITEM_DEFAULT"]
                if reg.count and reg.count > 1 then
                    lineTxt = lineTxt .. " x" .. reg.count
                end
                if reg.buyable then
                    lineTxt = lineTxt .. L["SPELL_TIP_VENDOR"]
                end
                GameTooltip:AddLine("  - " .. lineTxt, 0.9, 0.9, 0.9)
            end
        end

        if entry.difficulty then
            GameTooltip:AddLine(string.format(L["SPELL_TIP_DIFF_FMT"], entry.difficulty.label), entry.difficulty.r, entry.difficulty.g, entry.difficulty.b)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["SPELL_TIP_ACTIONS"], 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        SyncRowVisuals(self, self.spellEntry)
        GameTooltip:Hide()
    end)

    row:SetScript("OnClick", function(self)
        local sp = DungeonBots.spellsFrame
        local entry = self.spellEntry
        if not sp or not entry then return end

        if IsModifiedClick and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
            local link = entry.displayLink or entry.rawLink or entry.plainLink
            if link and ChatEdit_InsertLink(link) then
                return
            end
        end

        if entry.kind == "glyph" then return end

        PlaySound("igMainMenuOptionCheckBoxOn")
        if sp.selectedSpell == entry then
            sp.selectedSpell = nil
        else
            sp.selectedSpell = entry
        end
        UpdateSpellSelectionUI()
    end)

    spellRowButtons[idx] = row
    return row
end

function DungeonBots:BuildSpellsDialog()
    if DungeonBots.spellsFrame then return end

    local sp = CreateFrame("Frame", "DungeonBots_SpellsFrame", UIParent)
    sp:SetSize(560, 472)
    sp:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    sp:SetFrameStrata("DIALOG")
    sp:SetFrameLevel(25)
    sp:SetToplevel(true)
    sp:SetMovable(true)
    sp:EnableMouse(true)
    sp:SetClampedToScreen(true)
    sp:RegisterForDrag("LeftButton")
    sp:SetScript("OnDragStart", sp.StartMoving)
    sp:SetScript("OnDragStop", sp.StopMovingOrSizing)
    sp:Hide()
    ApplyBlizzardGoldWindow(sp, 16)

    tinsert(UISpecialFrames, "DungeonBots_SpellsFrame")
    sp.activeMode = "spells"

    local header = CreateFrame("Frame", nil, sp)
    header:SetPoint("TOPLEFT", sp, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", sp, "TOPRIGHT", -6, -6)
    header:SetHeight(30)
    ApplyHeaderBackdrop(header)

    local hIcon = header:CreateTexture(nil, "ARTWORK")
    hIcon:SetSize(18, 18)
    hIcon:SetPoint("LEFT", header, "LEFT", 10, 0)
    hIcon:SetTexture("Interface\\Icons\\Achievement_Character_Human_Male")
    hIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", hIcon, "RIGHT", 6, 0)
    title:SetText(L["CHAR_WIN_DEFAULT"])
    sp.title = title

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        sp:Hide()
    end)

    -- Subpestanas de modo: Equipo / Hechizos / Glifos
    sp.modeButtons = {}
    local numTabs = #MODE_TABS
    local modeBtnW = 148
    local modeBtnH = 30
    local modeBtnGap = 14
    local modeStartX = math.floor((560 - (numTabs * modeBtnW + (numTabs - 1) * modeBtnGap)) / 2)
    for idx, tabDef in ipairs(MODE_TABS) do
        local mBtn = CreateFrame("Button", "DungeonBots_SpellsModeTab_" .. tabDef.id, sp, "UIPanelButtonTemplate")
        mBtn:SetSize(modeBtnW, modeBtnH)
        mBtn:SetPoint("TOPLEFT", sp, "TOPLEFT", modeStartX + ((idx - 1) * (modeBtnW + modeBtnGap)), -40)
        mBtn:SetText(tabDef.label)
        ConfigureIconTabButton(mBtn, tabDef.icon, tabDef.texCoord)
        mBtn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            sp.activeMode = tabDef.id
            sp.selectedSpell = nil
            local existingTab, rec = DB_Internal.GetBotSpellTabData(sp.currentBot, tabDef.id)
            if rec then
                rec.activeMode = tabDef.id
            end
            if tabDef.id == "gear" then
                if sp.currentBot and DungeonBots.EnsureGearTabData then
                    DungeonBots:EnsureGearTabData(sp.currentBot, false)
                end
                DungeonBots:UpdateSpellsDialog(sp.currentBot)
            elseif sp.currentBot and (not existingTab or (existingTab.updatedAt == 0 and not existingTab.loading)) then
                DungeonBots:QueryBotSpells(sp.currentBot, tabDef.id, "", false)
            else
                DungeonBots:UpdateSpellsDialog(sp.currentBot)
            end
        end)
        sp.modeButtons[tabDef.id] = mBtn
    end

    -- Barra de busqueda local (visible en modo Hechizos)
    local filterBar = CreateFrame("Frame", nil, sp)
    filterBar:SetPoint("TOPLEFT", sp, "TOPLEFT", 10, -74)
    filterBar:SetPoint("TOPRIGHT", sp, "TOPRIGHT", -10, -74)
    filterBar:SetHeight(24)
    sp.filterBar = filterBar

    local localLbl = filterBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    localLbl:SetPoint("LEFT", filterBar, "LEFT", 2, 0)
    localLbl:SetText(L["SEARCH_LABEL"])

    local localSearchBox = CreateFrame("EditBox", "DungeonBots_SpellsLocalSearchBox", filterBar, "InputBoxTemplate")
    localSearchBox:SetSize(468, 20)
    localSearchBox:SetPoint("LEFT", localLbl, "RIGHT", 8, 0)
    localSearchBox:SetAutoFocus(false)
    localSearchBox:SetScript("OnTextChanged", function()
        if DungeonBots.UpdateSpellsDialog then
            DungeonBots:UpdateSpellsDialog(sp.currentBot)
        end
    end)
    localSearchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    sp.localSearchBox = localSearchBox

    -- Panel de lista con scroll
    local listBg = CreateFrame("Frame", nil, sp)
    listBg:SetPoint("TOPLEFT", sp, "TOPLEFT", 10, -104)
    listBg:SetPoint("BOTTOMRIGHT", sp, "BOTTOMRIGHT", -10, 42)
    ApplyBlizzardStonePanel(listBg, 0.66, 0.54, 0.30, 10, 0.30)
    sp.listBg = listBg

    local scroll = CreateFrame("ScrollFrame", "DungeonBots_SpellsScroll", listBg, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", listBg, "TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", listBg, "BOTTOMRIGHT", -26, 6)

    local scrollChild = CreateFrame("Frame", "DungeonBots_SpellsScrollChild", scroll)
    scrollChild:SetSize(506, 1)
    scroll:SetScrollChild(scrollChild)
    sp.scrollChild = scrollChild

    local emptyLabel = listBg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyLabel:SetPoint("CENTER", listBg, "CENTER", -8, 0)
    emptyLabel:SetWidth(430)
    emptyLabel:SetText(L["WAIT_BOT_RESPONSE"])
    sp.emptyLabel = emptyLabel

    BuildGearPanel(sp)

    -- Barra inferior: Siguiente Bot + (idx/total)  |  Lanzar (cast)
    local nextBotBtn = CreateFrame("Button", nil, sp, "UIPanelButtonTemplate")
    nextBotBtn:SetSize(118, 24)
    nextBotBtn:SetPoint("BOTTOMLEFT", sp, "BOTTOMLEFT", 12, 10)
    nextBotBtn:SetText(L["BTN_NEXT_BOT"])
    nextBotBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        sp.selectedSpell = nil
        if DungeonBots.CycleNextSpellsBot then
            DungeonBots:CycleNextSpellsBot(sp.currentBot, sp.activeMode, "")
        end
    end)
    sp.nextBotBtn = nextBotBtn

    local botCycleLabel = sp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    botCycleLabel:SetPoint("LEFT", nextBotBtn, "RIGHT", 6, 0)
    botCycleLabel:SetWidth(40)
    botCycleLabel:SetJustifyH("LEFT")
    botCycleLabel:SetText("|cff888888(0/0)|r")
    sp.botCycleLabel = botCycleLabel

    local closeFooterBtn = CreateFrame("Button", "DungeonBots_SpellsCloseFooterBtn", sp, "UIPanelButtonTemplate")
    closeFooterBtn:SetSize(90, 24)
    closeFooterBtn:SetPoint("BOTTOMRIGHT", sp, "BOTTOMRIGHT", -12, 10)
    closeFooterBtn:SetText(L["BTN_CLOSE"])
    closeFooterBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        sp:Hide()
    end)
    sp.closeFooterBtn = closeFooterBtn

    local castBtn = CreateRedIconButton(sp, 98, 24, L["SPELL_BTN_CAST"], "Interface\\Icons\\Spell_Holy_MagicalSentry")
    castBtn:SetPoint("RIGHT", closeFooterBtn, "LEFT", -8, 0)
    castBtn:Disable()
    castBtn:SetAlpha(0.45)
    castBtn:SetScript("OnClick", function()
        if not sp.currentBot or not sp.selectedSpell then return end
        if DungeonBots.CastBotSpell then
            DungeonBots:CastBotSpell(sp.currentBot, sp.selectedSpell)
        end
    end)
    castBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["SPELL_CAST_TIP_TITLE"], 0.45, 0.85, 1.0)
        GameTooltip:AddLine(L["SPELL_CAST_TIP_DESC"], 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    castBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    sp.castBtn = castBtn

    local cancelBtn = CreateRedIconButton(sp, 98, 24, L["BTN_CANCEL"], "Interface\\Icons\\Ability_Kick")
    cancelBtn:SetPoint("RIGHT", castBtn, "LEFT", -8, 0)
    cancelBtn:Disable()
    cancelBtn:SetAlpha(0.45)
    cancelBtn:SetScript("OnClick", function()
        if not sp.currentBot then return end
        if DungeonBots.CancelBotSpell then
            DungeonBots:CancelBotSpell(sp.currentBot)
        end
        if UpdateCancelCastButtonState then
            UpdateCancelCastButtonState()
        end
    end)
    local function RefreshCancelTooltip(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["SPELL_CANCEL_TIP_TTL"], 1.0, 0.45, 0.35)
        if self.activeCastSpell then
            GameTooltip:AddLine(string.format(L["SPELL_CANCEL_NOW_FMT"], self.activeCastSpell), 1, 1, 1, true)
            GameTooltip:AddLine(L["SPELL_CANCEL_CLICK"], 0.85, 0.85, 0.85, true)
        else
            GameTooltip:AddLine(L["SPELL_CANCEL_IDLE"], 0.85, 0.85, 0.85, true)
        end
        GameTooltip:Show()
    end
    cancelBtn.RefreshTooltip = RefreshCancelTooltip
    cancelBtn:SetScript("OnEnter", RefreshCancelTooltip)
    cancelBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    sp.cancelBtn = cancelBtn

    local castWatchFrame = CreateFrame("Frame", nil, sp)
    local CAST_WATCH_EVENTS = {
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_SUCCEEDED",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_CHANNEL_UPDATE",
        "UNIT_SPELLCAST_DELAYED",
        "PARTY_MEMBERS_CHANGED",
    }
    castWatchFrame:SetScript("OnEvent", function(_, event, unitArg)
        if not sp:IsShown() or sp.activeMode ~= "spells" then return end
        if event == "PARTY_MEMBERS_CHANGED" or not unitArg or string.sub(unitArg, 1, 5) == "party" then
            UpdateCancelCastButtonState()
        end
    end)
    sp.castWatchFrame = castWatchFrame

    sp:HookScript("OnShow", function()
        for _, ev in ipairs(CAST_WATCH_EVENTS) do
            castWatchFrame:RegisterEvent(ev)
        end
        UpdateCancelCastButtonState()
    end)
    sp:HookScript("OnHide", function()
        castWatchFrame:UnregisterAllEvents()
        castWatchFrame:SetScript("OnUpdate", nil)
    end)

    DungeonBots.spellsFrame = sp
    if DB_Internal.RegisterSubModalDimmer then
        DB_Internal.RegisterSubModalDimmer(sp)
    end
end

local function IsValidMode(mode)
    return mode == "gear" or mode == "spells" or mode == "glyphs"
end

local function UpdateCycleFooter(sp, targetBot)
    if sp.nextBotBtn and sp.botCycleLabel and DungeonBots.GetTalkBotCycleInfo then
        local curIdx, total = DungeonBots:GetTalkBotCycleInfo(targetBot)
        if total > 0 then
            sp.botCycleLabel:SetText(string.format("|cff888888(%d/%d)|r", curIdx, total))
        else
            sp.botCycleLabel:SetText("|cff888888(0/0)|r")
        end
        if total >= 2 then
            sp.nextBotBtn:Enable()
        else
            sp.nextBotBtn:Disable()
        end
    end
end

local function RenderGearPanel(sp, targetBot, classToken)
    local gp = sp.gearPanel
    if not gp then return end

    local activeSpec = DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[targetBot]
    if activeSpec and activeSpec ~= "" and DungeonBots.CanonicalizeSpec then
        activeSpec = DungeonBots:CanonicalizeSpec(targetBot, activeSpec)
    end

    local rawSpecs = (DungeonBots.botSpecs and DungeonBots.botSpecs[targetBot])
    local validSpecs = {}
    if rawSpecs then
        for _, s in ipairs(rawSpecs) do
            if type(s) == "string" and (not DB_Internal.IsValidSpecEntry or DB_Internal.IsValidSpecEntry(s)) then
                table.insert(validSpecs, s)
            end
        end
    end
    local specs = validSpecs
    if #specs < 2 and classToken and DungeonBots.DEFAULT_CLASS_SPECS then
        specs = DungeonBots.DEFAULT_CLASS_SPECS[classToken]
    end
    local optionList = {}
    local seen = {}
    if specs then
        for _, s in ipairs(specs) do
            local ls = string.lower(s)
            if not seen[ls] then
                table.insert(optionList, s)
                seen[ls] = true
            end
        end
    end
    if activeSpec and activeSpec ~= "" then
        local resolvedActive = activeSpec
        if not seen[string.lower(resolvedActive)] and DungeonBots.CanonicalizeSpec then
            local cand = DungeonBots:CanonicalizeSpec(targetBot, resolvedActive)
            if cand and cand ~= "" and seen[string.lower(cand)] then
                resolvedActive = cand
            end
        end
        if seen[string.lower(resolvedActive)] then
            activeSpec = resolvedActive
        elseif not DB_Internal.IsValidSpecEntry or DB_Internal.IsValidSpecEntry(activeSpec) then
            table.insert(optionList, activeSpec)
        end
    end

    if #optionList == 0 then
        gp.emptySpecsLabel:Show()
    else
        gp.emptySpecsLabel:Hide()
    end

    for idx, sBtn in ipairs(gp.specButtons) do
        local specName = optionList[idx]
        if specName then
            local displaySpec = DungeonBots.LocalizeSpecText and DungeonBots:LocalizeSpecText(specName) or specName
            local isActive = (activeSpec and string.lower(specName) == string.lower(activeSpec)) and true or false
            local p = DB_Internal.GetThemePalette and DB_Internal.GetThemePalette()
            if isActive then
                sBtn.label:SetText(string.format(L["CHAR_SPEC_ACTIVE_FMT"], (p and p.specActiveHex or "|cffffd100"), displaySpec))
                if p then
                    sBtn:SetBackdropColor(p.specActiveBg[1], p.specActiveBg[2], p.specActiveBg[3], p.specActiveBg[4])
                    sBtn:SetBackdropBorderColor(p.specActiveBorder[1], p.specActiveBorder[2], p.specActiveBorder[3], p.specActiveBorder[4])
                    sBtn.accentBar:SetTexture(p.specActiveBorder[1], p.specActiveBorder[2], p.specActiveBorder[3], 1.0)
                else
                    sBtn:SetBackdropColor(0.22, 0.17, 0.09, 0.96)
                    sBtn:SetBackdropBorderColor(1.0, 0.82, 0.24, 0.95)
                end
                sBtn.accentBar:Show()
            else
                sBtn.label:SetText((p and p.specInactiveHex or "|cffeeddb8") .. displaySpec .. "|r")
                if p then
                    sBtn:SetBackdropColor(p.insetBg[1], p.insetBg[2], p.insetBg[3], p.insetBg[4])
                    sBtn:SetBackdropBorderColor(p.insetBorder[1], p.insetBorder[2], p.insetBorder[3], p.insetBorder[4])
                else
                    sBtn:SetBackdropColor(0.095, 0.080, 0.060, 0.95)
                    sBtn:SetBackdropBorderColor(0.56, 0.46, 0.28, 0.85)
                end
                sBtn.accentBar:Hide()
            end
            if sBtn.goldWarmFill and DB_Internal.ApplyGoldWarmFill then
                sBtn.goldWarmFill._dbFillKey = isActive and "warmFillActive" or "warmFillSlot"
                DB_Internal.ApplyGoldWarmFill(sBtn.goldWarmFill)
            end
            sBtn.specValue = specName
            sBtn.isActiveSpec = isActive
            sBtn:SetScript("OnClick", function()
                PlaySound("igMainMenuOptionCheckBoxOn")
                if DungeonBots.SetBotSpec then
                    DungeonBots:SetBotSpec(targetBot, specName)
                end
            end)
            sBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(string.format(L["CHAR_SPEC_TIP_TITLE"], displaySpec), 0.45, 0.85, 1.0)
                GameTooltip:AddLine(string.format(L["CHAR_SPEC_TIP_DESC"], targetBot, displaySpec), 0.85, 0.85, 0.85, true)
                GameTooltip:Show()
            end)
            sBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            sBtn:Show()
        else
            sBtn.specValue = nil
            sBtn.isActiveSpec = false
            sBtn:Hide()
        end
    end

    gp.autogearBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if DungeonBots.Autogear then
            DungeonBots:Autogear(targetBot)
        end
    end)
    gp.autogearBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["CHAR_AUTOGEAR_BTN"], 1, 0.8, 0.2)
        GameTooltip:AddLine(L["CHAR_AUTOGEAR_TIP_DESC"], 1, 1, 1, true)
        GameTooltip:AddLine(L["CHAR_AUTOGEAR_TIP_WARN"], 1, 0.35, 0.35, true)
        GameTooltip:Show()
    end)
    gp.autogearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end


function DungeonBots:UpdateSpellsDialog(botName)
    local sp = DungeonBots.spellsFrame
    if not sp then return end

    local targetBot = botName or sp.currentBot
    if not targetBot then return end
    sp.currentBot = targetBot

    local mode = IsValidMode(sp.activeMode) and sp.activeMode or "gear"
    sp.activeMode = mode
    local tab = DB_Internal.GetBotSpellTabData(targetBot, mode)

    local unit = DungeonBots.FindPartyUnitByName and DungeonBots:FindPartyUnitByName(targetBot)
    local targetClassToken = nil
    local classHex = "|cffffd200"
    if unit and UnitClass and RAID_CLASS_COLORS then
        local _, classToken = UnitClass(unit)
        targetClassToken = classToken
        local c = classToken and RAID_CLASS_COLORS[classToken]
        if c then
            classHex = string.format("|cff%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
        end
    end
    sp.title:SetText(string.format(L["CHAR_WIN_FMT"], classHex, targetBot))

    for tabId, mBtn in pairs(sp.modeButtons) do
        if tabId == mode then
            mBtn:SetAlpha(1.0)
            mBtn:LockHighlight()
        else
            mBtn:SetAlpha(0.75)
            mBtn:UnlockHighlight()
        end
    end

    if mode == "gear" then
        sp.filterBar:Hide()
        sp.listBg:Hide()
        sp.castBtn:Hide()
        if sp.cancelBtn then sp.cancelBtn:Hide() end
        sp.emptyLabel:Hide()
        HideRowPool(spellRowButtons, 1)
        if sp.gearPanel then
            sp.gearPanel:Show()
            RenderGearPanel(sp, targetBot, targetClassToken)
        end
        UpdateCycleFooter(sp, targetBot)
        UpdateCancelCastButtonState()
        return
    end

    if sp.gearPanel then
        sp.gearPanel:Hide()
    end
    if sp.listBg then
        sp.listBg:Show()
    end

    local allItems = (tab and tab.items) or {}
    local visibleEntries = {}
    local filterRaw = ""

    if mode == "spells" then
        sp.filterBar:Show()
        sp.castBtn:Show()
        if sp.cancelBtn then sp.cancelBtn:Show() end

        filterRaw = sp.localSearchBox and sp.localSearchBox:GetText() or ""
        local filterText = string.lower(string.gsub(filterRaw, "^%s*(.-)%s*$", "%1"))

        local selectedVisible = false
        for _, entry in ipairs(allItems) do
            local match = true
            if filterText ~= "" then
                local lName = string.lower(entry.name or "")
                local rName = string.lower(entry.rawName or "")
                local diffTxt = entry.difficulty and string.lower(entry.difficulty.label .. " " .. entry.difficulty.key) or ""
                local regMatched = false
                if entry.reagents then
                    for _, reg in ipairs(entry.reagents) do
                        if string.find(string.lower(reg.name or reg.rawName or ""), filterText, 1, true) then
                            regMatched = true
                            break
                        end
                    end
                end
                if not (string.find(lName, filterText, 1, true)
                    or string.find(rName, filterText, 1, true)
                    or string.find(diffTxt, filterText, 1, true)
                    or regMatched) then
                    match = false
                end
            end
            if match then
                table.insert(visibleEntries, entry)
                if sp.selectedSpell and sp.selectedSpell == entry then
                    selectedVisible = true
                end
            end
        end
        if not selectedVisible then
            sp.selectedSpell = nil
        end
    else
        sp.filterBar:Hide()
        sp.castBtn:Hide()
        if sp.cancelBtn then sp.cancelBtn:Hide() end
        sp.selectedSpell = nil
        visibleEntries = allItems
        UpdateCancelCastButtonState()
    end

    if sp.listBg then
        local listTopY = (mode == "glyphs") and -76 or -104
        sp.listBg:ClearAllPoints()
        sp.listBg:SetPoint("TOPLEFT", sp, "TOPLEFT", 10, listTopY)
        sp.listBg:SetPoint("BOTTOMRIGHT", sp, "BOTTOMRIGHT", -10, 42)
    end

    if #visibleEntries == 0 then
        sp.emptyLabel:Show()
        if tab and tab.loading then
            local what = (mode == "glyphs" and L["SPELL_TYPE_GLYPHS"]) or L["SPELL_TYPE_SPELLS"]
            sp.emptyLabel:SetText(string.format(L["SPELL_QUERYING_FMT"], what, targetBot))
        elseif tab and tab.emptyHint then
            local hintText = (DungeonBots.LocalizeServerHint and DungeonBots:LocalizeServerHint(tab.emptyHint, mode)) or tab.emptyHint
            sp.emptyLabel:SetText(hintText)
        elseif #allItems == 0 then
            local fmt = (mode == "glyphs") and L["SPELL_NO_GLYPHS_FMT"] or L["SPELL_NO_SPELLS_FMT"]
            local baseMsg = string.format(fmt, targetBot)
            if tab and tab.timedOut and DungeonBots.FormatNoResponseBody then
                sp.emptyLabel:SetText(DungeonBots:FormatNoResponseBody(baseMsg, targetBot))
            else
                sp.emptyLabel:SetText(baseMsg)
            end
        else
            sp.emptyLabel:SetText(string.format(L["SPELL_NOMATCH_FMT"], filterRaw))
        end
    else
        sp.emptyLabel:Hide()
    end

    for i, entry in ipairs(visibleEntries) do
        local row = spellRowButtons[i] or CreateSpellRowButton(sp.scrollChild, i)
        row.spellEntry = entry
        row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

        local isGlyph = (entry.kind == "glyph")
        local titleTxt = entry.name or entry.rawName or (isGlyph and L["GLYPH_DEFAULT"] or L["SPELL_DEFAULT"])
        if entry.rank and entry.rank ~= "" then
            titleTxt = titleTxt .. " |cff888888(" .. entry.rank .. ")|r"
        end
        row.nameLabel:SetText(titleTxt)

        if isGlyph then
            local glyphType = entry.categoryTag or L["GLYPH_DEFAULT"]
            row.diffBadge:SetText("|cff71d5ff" .. glyphType .. " #" .. i .. "|r")
            row.subLabel:SetText(L["GLYPH_EQUIPPED_HINT"])
        else
            local badgeParts = {}
            if entry.difficulty then
                table.insert(badgeParts, entry.difficulty.colorHex .. entry.difficulty.label .. "|r")
            end
            row.diffBadge:SetText(table.concat(badgeParts, " "))

            local regText = FormatReagentsSummary(entry.reagents)
            local metaText = FormatPowerAndCastMeta(entry)
            row.subLabel:SetText(regText or metaText or L["SPELL_ROW_HINT"])
        end
        row:Show()
    end

    HideRowPool(spellRowButtons, #visibleEntries + 1)

    sp.scrollChild:SetHeight(math.max(1, (#visibleEntries * SPELL_ROW_PITCH) + 8))
    UpdateSpellSelectionUI()
    UpdateCycleFooter(sp, targetBot)
end

function DungeonBots:OpenSpellsDialog(botName, mode)
    if not DungeonBots.spellsFrame then
        DungeonBots:BuildSpellsDialog()
    end
    local sp = DungeonBots.spellsFrame
    if sp.currentBot ~= botName then
        sp.selectedSpell = nil
        if sp.localSearchBox then
            sp.localSearchBox:SetText("")
        end
    end
    if IsValidMode(mode) then
        sp.activeMode = mode
    elseif not IsValidMode(sp.activeMode) then
        sp.activeMode = "gear"
    end
    sp.currentBot = botName
    DungeonBots:UpdateSpellsDialog(botName)
    sp:Show()
    if sp.Raise then
        pcall(sp.Raise, sp)
    end
end
