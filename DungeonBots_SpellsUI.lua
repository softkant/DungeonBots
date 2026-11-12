-- =========================================================================
-- DungeonBots_SpellsUI.lua: Ventana de Información del Personaje
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

local MODE_TABS = {
    { id = "gear",   label = "Equipo",   icon = "Interface\\Icons\\INV_Chest_Plate01" },
    { id = "spells", label = "Hechizos", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    { id = "glyphs", label = "Glifos",   icon = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
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
    specCard:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    specCard:SetBackdropColor(0.03, 0.04, 0.07, 1.0)
    specCard:SetBackdropBorderColor(0.28, 0.32, 0.40, 1.0)
    gearPanel.specCard = specCard

    local specHeaderIcon = specCard:CreateTexture(nil, "ARTWORK")
    specHeaderIcon:SetSize(18, 18)
    specHeaderIcon:SetPoint("TOPLEFT", specCard, "TOPLEFT", 12, -10)
    specHeaderIcon:SetTexture("Interface\\Icons\\Ability_Marksmanship")
    specHeaderIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local specTitle = specCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specTitle:SetPoint("LEFT", specHeaderIcon, "RIGHT", 7, 0)
    specTitle:SetText("|cff71d5ffRama de Talentos|r")

    local activeSpecLabel = specCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    activeSpecLabel:SetPoint("TOPRIGHT", specCard, "TOPRIGHT", -12, -12)
    activeSpecLabel:SetJustifyH("RIGHT")
    activeSpecLabel:SetText("Rama actual: |cff888888Sin detectar|r")
    gearPanel.activeSpecLabel = activeSpecLabel

    local specSubLabel = specCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    specSubLabel:SetPoint("TOPLEFT", specCard, "TOPLEFT", 12, -33)
    specSubLabel:SetText("|cff9aa5b4Elige la especialización que utilizará el bot (talents spec):|r")

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
        sBtn:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        sBtn:SetBackdropColor(0.07, 0.09, 0.14, 0.95)
        sBtn:SetBackdropBorderColor(0.28, 0.32, 0.42, 0.85)
        sBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

        local accentBar = sBtn:CreateTexture(nil, "OVERLAY")
        accentBar:SetHeight(2)
        accentBar:SetPoint("BOTTOMLEFT", sBtn, "BOTTOMLEFT", 4, 2)
        accentBar:SetPoint("BOTTOMRIGHT", sBtn, "BOTTOMRIGHT", -4, 2)
        accentBar:SetTexture(0.0, 0.85, 1.0, 1.0)
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
    emptySpecsLabel:SetText("|cff888888Sin ramas cargadas todavía.|r")
    emptySpecsLabel:Hide()
    gearPanel.emptySpecsLabel = emptySpecsLabel

    -- Seccion 2: Cambio y adaptacion de equipo (Autogear Match / Blue)
    local autogearCard = CreateFrame("Frame", "DungeonBots_GearAutogearCard", gearPanel)
    autogearCard:SetPoint("TOPLEFT", specCard, "BOTTOMLEFT", 0, -10)
    autogearCard:SetPoint("TOPRIGHT", specCard, "BOTTOMRIGHT", 0, -10)
    autogearCard:SetPoint("BOTTOMRIGHT", gearPanel, "BOTTOMRIGHT", 0, 0)
    autogearCard:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    autogearCard:SetBackdropColor(0.03, 0.04, 0.07, 1.0)
    autogearCard:SetBackdropBorderColor(0.28, 0.32, 0.40, 1.0)
    gearPanel.autogearCard = autogearCard

    local gearHeaderIcon = autogearCard:CreateTexture(nil, "ARTWORK")
    gearHeaderIcon:SetSize(18, 18)
    gearHeaderIcon:SetPoint("TOPLEFT", autogearCard, "TOPLEFT", 12, -10)
    gearHeaderIcon:SetTexture("Interface\\Icons\\INV_Chest_Plate01")
    gearHeaderIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local gearTitle = autogearCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gearTitle:SetPoint("LEFT", gearHeaderIcon, "RIGHT", 7, 0)
    gearTitle:SetText("|cffffd200Gestión de Equipo|r")

    local gearSubLabel = autogearCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    gearSubLabel:SetPoint("TOPLEFT", autogearCard, "TOPLEFT", 12, -33)
    gearSubLabel:SetText("|cff9aa5b4Adapta el equipo del bot según su rama o equípale un conjunto raro:|r")

    local matchBox = CreateFrame("Frame", nil, autogearCard)
    matchBox:SetSize(248, 108)
    matchBox:SetPoint("TOPLEFT", autogearCard, "TOPLEFT", 14, -56)
    matchBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    matchBox:SetBackdropColor(0.06, 0.08, 0.12, 0.90)
    matchBox:SetBackdropBorderColor(0.30, 0.34, 0.42, 0.80)

    local matchBtn = CreateFrame("Button", "DungeonBots_GearMatchBtn", matchBox, "UIPanelButtonTemplate")
    matchBtn:SetSize(224, 26)
    matchBtn:SetPoint("TOP", matchBox, "TOP", 0, -10)
    matchBtn:SetText("Adaptar Equipo")
    gearPanel.matchBtn = matchBtn

    local matchDesc = matchBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    matchDesc:SetPoint("TOPLEFT", matchBtn, "BOTTOMLEFT", 2, -8)
    matchDesc:SetPoint("TOPRIGHT", matchBtn, "BOTTOMRIGHT", -2, -8)
    matchDesc:SetJustifyH("CENTER")
    matchDesc:SetText("|cffccccccAjusta su armadura a la rama activa.|r\n|cffff3b30CUIDADO:|r Puede reducir drásticamente el Item Level de sus piezas.")

    local blueBox = CreateFrame("Frame", nil, autogearCard)
    blueBox:SetSize(248, 108)
    blueBox:SetPoint("TOPRIGHT", autogearCard, "TOPRIGHT", -14, -56)
    blueBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    blueBox:SetBackdropColor(0.06, 0.08, 0.12, 0.90)
    blueBox:SetBackdropBorderColor(0.30, 0.34, 0.42, 0.80)

    local blueBtn = CreateFrame("Button", "DungeonBots_GearBlueBtn", blueBox, "UIPanelButtonTemplate")
    blueBtn:SetSize(224, 26)
    blueBtn:SetPoint("TOP", blueBox, "TOP", 0, -10)
    blueBtn:SetText("Equipar Azul")
    gearPanel.blueBtn = blueBtn

    local blueDesc = blueBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    blueDesc:SetPoint("TOPLEFT", blueBtn, "BOTTOMLEFT", 2, -8)
    blueDesc:SetPoint("TOPRIGHT", blueBtn, "BOTTOMRIGHT", -2, -8)
    blueDesc:SetJustifyH("CENTER")
    blueDesc:SetText("|cffccccccEquipa al bot con un conjunto completo de calidad rara (|cff0070ddazul|r|cffcccccc).|r")
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
        local label = reg.displayLink or ("[" .. (reg.name or reg.rawName or "Objeto") .. "]")
        if reg.count and reg.count > 1 then
            label = label .. " x" .. reg.count
        end
        if reg.buyable then
            label = label .. " |cff34c759(compra)|r"
        end
        table.insert(parts, label)
    end
    return "|cffaaaaaaMat.:|r " .. table.concat(parts, ", ")
end

local function FormatPowerAndCastMeta(entry)
    if not entry then return nil end
    local parts = {}
    if entry.cost and entry.cost > 0 then
        local powerLabels = {
            [0] = "maná",
            [1] = "ira",
            [2] = "enfoque",
            [3] = "energía",
            [6] = "poder rúnico",
        }
        local unitTxt = powerLabels[entry.powerType] or "coste"
        table.insert(parts, entry.cost .. " " .. unitTxt)
    end
    if entry.castTime ~= nil then
        if entry.castTime == 0 then
            table.insert(parts, "Instantáneo")
        else
            table.insert(parts, string.format("%.1f s", entry.castTime / 1000))
        end
    end
    if entry.maxRange and entry.maxRange > 0 then
        table.insert(parts, string.format("%d m", entry.maxRange))
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
                    row:SetBackdropBorderColor(0.26, 0.34, 0.50, 0.85)
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
    ApplyDarkBackdrop(row, 8)
    row:SetBackdropColor(0.06, 0.08, 0.12, 0.94)
    row:SetBackdropBorderColor(0.26, 0.34, 0.50, 0.85)
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
            local titleTxt = entry.name or entry.rawName or (entry.kind == "glyph" and "Glifo" or "Hechizo")
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
            local fallbackTitle = entry.name or entry.rawName or (isGlyph and "Glifo" or "Hechizo")
            GameTooltip:AddLine(fallbackTitle, 0.45, 0.85, 1.0)
        end

        SyncRowVisuals(self, entry)

        if isGlyph then
            if entry.categoryTag then
                GameTooltip:AddLine("Tipo: " .. entry.categoryTag, 0.44, 0.84, 1.0)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Shift + Clic: |cffffffffInsertar enlace en el chat|r", 0.8, 0.8, 0.8)
            GameTooltip:Show()
            return
        end

        if entry.reagents and #entry.reagents > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Materiales:", 1, 0.82, 0)
            for _, reg in ipairs(entry.reagents) do
                local lineTxt = reg.name or reg.rawName or "Material"
                if reg.count and reg.count > 1 then
                    lineTxt = lineTxt .. " x" .. reg.count
                end
                if reg.buyable then
                    lineTxt = lineTxt .. " (vendedor)"
                end
                GameTooltip:AddLine("  - " .. lineTxt, 0.9, 0.9, 0.9)
            end
        end

        if entry.difficulty then
            GameTooltip:AddLine("Dificultad: " .. entry.difficulty.label, entry.difficulty.r, entry.difficulty.g, entry.difficulty.b)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Clic izquierdo: |cffffffffSeleccionar|r  |  Shift + Clic: |cff71d5ffEnlazar|r", 0.8, 0.8, 0.8)
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
    ApplyDarkBackdrop(sp, 14)
    sp:SetBackdropColor(0.04, 0.05, 0.08, 1.0)

    local solidBg = sp:CreateTexture(nil, "BACKGROUND")
    solidBg:SetPoint("TOPLEFT", sp, "TOPLEFT", 4, -4)
    solidBg:SetPoint("BOTTOMRIGHT", sp, "BOTTOMRIGHT", -4, 4)
    solidBg:SetTexture(0.04, 0.05, 0.08, 1.0)

    tinsert(UISpecialFrames, "DungeonBots_SpellsFrame")
    sp.activeMode = "spells"

    local header = CreateFrame("Frame", nil, sp)
    header:SetPoint("TOPLEFT", sp, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", sp, "TOPRIGHT", -6, -6)
    header:SetHeight(30)
    ApplyHeaderBackdrop(header)
    header:SetBackdropColor(0.10, 0.12, 0.16, 1.0)

    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT", header, "TOPLEFT", 2, -2)
    headerBg:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -2, 2)
    headerBg:SetTexture(0.10, 0.12, 0.16, 1.0)

    local hIcon = header:CreateTexture(nil, "ARTWORK")
    hIcon:SetSize(18, 18)
    hIcon:SetPoint("LEFT", header, "LEFT", 10, 0)
    hIcon:SetTexture("Interface\\Icons\\Achievement_Character_Human_Male")
    hIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", hIcon, "RIGHT", 6, 0)
    title:SetText("|cffb266ffPersonaje:|r")
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
    localLbl:SetText("Buscar:")

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
    ApplyDarkBackdrop(listBg, 10)
    listBg:SetBackdropColor(0.02, 0.03, 0.05, 1.0)
    listBg:SetBackdropBorderColor(0.28, 0.32, 0.40, 1.0)
    sp.listBg = listBg

    local listSolid = listBg:CreateTexture(nil, "BACKGROUND")
    listSolid:SetPoint("TOPLEFT", listBg, "TOPLEFT", 3, -3)
    listSolid:SetPoint("BOTTOMRIGHT", listBg, "BOTTOMRIGHT", -3, 3)
    listSolid:SetTexture(0.02, 0.03, 0.05, 1.0)

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
    emptyLabel:SetText("Esperando respuesta del bot...")
    sp.emptyLabel = emptyLabel

    BuildGearPanel(sp)

    -- Barra inferior: Siguiente Bot + (idx/total)  |  Lanzar (cast)
    local nextBotBtn = CreateFrame("Button", nil, sp, "UIPanelButtonTemplate")
    nextBotBtn:SetSize(118, 24)
    nextBotBtn:SetPoint("BOTTOMLEFT", sp, "BOTTOMLEFT", 12, 10)
    nextBotBtn:SetText("Siguiente Bot")
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
    closeFooterBtn:SetText("Cerrar")
    closeFooterBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        sp:Hide()
    end)
    sp.closeFooterBtn = closeFooterBtn

    local castBtn = CreateRedIconButton(sp, 98, 24, "Lanzar", "Interface\\Icons\\Spell_Holy_MagicalSentry")
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
        GameTooltip:AddLine("Ordenar lanzamiento ('cast')", 0.45, 0.85, 1.0)
        GameTooltip:AddLine("Envía 'cast [link]' directamente al bot seleccionado.", 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    castBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    sp.castBtn = castBtn

    local cancelBtn = CreateRedIconButton(sp, 98, 24, "Cancelar", "Interface\\Icons\\Ability_Kick")
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
        GameTooltip:AddLine("Cancelar hechizo ('reset')", 1.0, 0.45, 0.35)
        if self.activeCastSpell then
            GameTooltip:AddLine("Casteando ahora: |cffffd200" .. self.activeCastSpell .. "|r", 1, 1, 1, true)
            GameTooltip:AddLine("Haz clic para enviar 'reset' al bot actual y detener el lanzamiento.", 0.85, 0.85, 0.85, true)
        else
            GameTooltip:AddLine("Envía 'reset' al bot actual (se ilumina y habilita cuando está casteando o canalizando).", 0.85, 0.85, 0.85, true)
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
    if activeSpec and activeSpec ~= "" then
        local activeDisplay = DungeonBots.LocalizeSpecText and DungeonBots:LocalizeSpecText(activeSpec) or activeSpec
        gp.activeSpecLabel:SetText("Rama actual: |cff00e5ff" .. activeDisplay .. "|r")
    elseif DungeonBots.pendingSpecReset and DungeonBots.pendingSpecReset[targetBot] then
        gp.activeSpecLabel:SetText("Rama actual: |cff888888Consultando talentos...|r")
    else
        gp.activeSpecLabel:SetText("Rama actual: |cff888888Sin detectar|r")
    end

    local specs = (DungeonBots.botSpecs and DungeonBots.botSpecs[targetBot])
    if (not specs or #specs == 0) and classToken and DungeonBots.DEFAULT_CLASS_SPECS then
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
    if activeSpec and activeSpec ~= "" and not seen[string.lower(activeSpec)] then
        table.insert(optionList, 1, activeSpec)
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
            if isActive then
                sBtn.label:SetText("|cff00e5ff" .. displaySpec .. " (Activa)|r")
                sBtn:SetBackdropColor(0.08, 0.22, 0.34, 0.96)
                sBtn:SetBackdropBorderColor(0.25, 0.80, 1.0, 0.95)
                sBtn.accentBar:Show()
            else
                sBtn.label:SetText("|cffe6ecf5" .. displaySpec .. "|r")
                sBtn:SetBackdropColor(0.07, 0.09, 0.14, 0.95)
                sBtn:SetBackdropBorderColor(0.28, 0.32, 0.42, 0.85)
                sBtn.accentBar:Hide()
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
                GameTooltip:AddLine("Cambiar rama a " .. displaySpec, 0.45, 0.85, 1.0)
                GameTooltip:AddLine("Envía '/w " .. targetBot .. " talents spec " .. specName .. "'.", 0.85, 0.85, 0.85, true)
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

    gp.matchBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if DungeonBots.AutogearMatch then
            DungeonBots:AutogearMatch(targetBot)
        end
    end)
    gp.matchBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Adaptar Equipo (Autogear Match)", 1, 0.8, 0.2)
        GameTooltip:AddLine("Ajusta su armadura a la rama de talentos activa.", 1, 1, 1)
        GameTooltip:AddLine("\n|cffff3b30CUIDADO:|r Esto puede reducir drásticamente el Item Level de varias o todas sus piezas.", 1, 0.3, 0.3, true)
        GameTooltip:Show()
    end)
    gp.matchBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    gp.blueBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if DungeonBots.AutogearBlue then
            DungeonBots:AutogearBlue(targetBot)
        end
    end)
    gp.blueBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Equipar Objetos Azules (Autogear Blue)", 0.2, 0.8, 1.0)
        GameTooltip:AddLine("Equipa al bot con un conjunto completo de calidad rara (azul).", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    gp.blueBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
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
    sp.title:SetText("|cffb266ffPersonaje:|r " .. classHex .. targetBot .. "|r")

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
            local what = (mode == "glyphs" and "glifos") or "hechizos"
            sp.emptyLabel:SetText("Consultando " .. what .. " de |cffffd200" .. targetBot .. "|r...")
        elseif tab and tab.emptyHint then
            sp.emptyLabel:SetText(tab.emptyHint)
        elseif #allItems == 0 then
            if mode == "glyphs" then
                sp.emptyLabel:SetText("No se recibieron glifos para |cffffd200" .. targetBot .. "|r.")
            else
                sp.emptyLabel:SetText("No se recibieron poderes para |cffffd200" .. targetBot .. "|r.")
            end
        else
            sp.emptyLabel:SetText("Ningún poder coincide con \"" .. filterRaw .. "\".")
        end
    else
        sp.emptyLabel:Hide()
    end

    for i, entry in ipairs(visibleEntries) do
        local row = spellRowButtons[i] or CreateSpellRowButton(sp.scrollChild, i)
        row.spellEntry = entry
        row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

        local isGlyph = (entry.kind == "glyph")
        local titleTxt = entry.name or entry.rawName or (isGlyph and "Glifo" or "Hechizo")
        if entry.rank and entry.rank ~= "" then
            titleTxt = titleTxt .. " |cff888888(" .. entry.rank .. ")|r"
        end
        row.nameLabel:SetText(titleTxt)

        if isGlyph then
            local glyphType = entry.categoryTag or "Glifo"
            row.diffBadge:SetText("|cff71d5ff" .. glyphType .. " #" .. i .. "|r")
            row.subLabel:SetText("|cff8899aaGlifo equipado  |  Pasa el ratón para ver detalles|r")
        else
            local badgeParts = {}
            if entry.difficulty then
                table.insert(badgeParts, entry.difficulty.colorHex .. entry.difficulty.label .. "|r")
            end
            row.diffBadge:SetText(table.concat(badgeParts, " "))

            local regText = FormatReagentsSummary(entry.reagents)
            local metaText = FormatPowerAndCastMeta(entry)
            row.subLabel:SetText(regText or metaText or "|cff667788Clic izq.: seleccionar  |  Shift + Clic: enlazar|r")
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
