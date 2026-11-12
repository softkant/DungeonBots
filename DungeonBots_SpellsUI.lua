-- =========================================================================
-- DungeonBots_SpellsUI.lua: Ventana de Poderes, Glifos y Talentos
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

local MODE_TABS = {
    { id = "spells",  label = "Hechizos", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    { id = "glyphs",  label = "Glifos",   icon = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
    { id = "talents", label = "Talentos", icon = "Interface\\Icons\\Ability_Marksmanship" },
}

local SPELL_ROW_HEIGHT = 40
local SPELL_ROW_PITCH = 43

local spellRowButtons = {}

local function ConfigureIconTabButton(btn, iconPath)
    local tex = btn:CreateTexture(nil, "OVERLAY")
    tex:SetSize(14, 14)
    tex:SetPoint("LEFT", btn, "LEFT", 9, 0)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
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

    row:SetScript("OnEnter", function(self)
        local entry = self.spellEntry
        if not entry then return end

        local isGlyph = (entry.kind == "glyph")
        local isTalent = (entry.kind == "talent")
        local linkToShow = entry.displayLink or entry.rawLink

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local loadedRich = false
        if isTalent then
            if entry.talentLink and string.find(entry.talentLink, "|H", 1, true) and GameTooltip.SetHyperlink then
                loadedRich = pcall(GameTooltip.SetHyperlink, GameTooltip, entry.talentLink)
            end
            local curBot = DungeonBots.spellsFrame and DungeonBots.spellsFrame.currentBot
            if (not loadedRich or (GameTooltip.NumLines and GameTooltip:NumLines() == 0))
                and GameTooltip.SetTalent and entry.tabIndex and entry.talentIndex
                and curBot and DungeonBots.lastInspectedTalentBot == curBot then
                loadedRich = pcall(GameTooltip.SetTalent, GameTooltip, entry.tabIndex, entry.talentIndex, true)
            end
        elseif isGlyph and linkToShow and string.find(linkToShow, "|H", 1, true) and GameTooltip.SetHyperlink then
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
            local fallbackTitle = entry.name or entry.rawName or (isTalent and "Talento" or (isGlyph and "Glifo" or "Hechizo"))
            GameTooltip:AddLine(fallbackTitle, 0.45, 0.85, 1.0)
        end

        if isTalent then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Rango: |cffffffff" .. (entry.currentRank or 0) .. "/" .. (entry.maxRank or 0) .. "|r  (" .. (entry.treeName or "Talentos") .. ")", 0.44, 0.84, 1.0)
            GameTooltip:AddLine("Shift + Clic: |cffffffffInsertar enlace en el chat|r", 0.8, 0.8, 0.8)
            GameTooltip:Show()
            return
        end

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
        if entry.craftableCount then
            GameTooltip:AddLine("Crafteables disponibles: x" .. entry.craftableCount, 0.25, 0.88, 0.45)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Clic izquierdo: |cffffffffSeleccionar|r  |  Shift + Clic: |cff71d5ffEnlazar|r", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
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

        if entry.kind == "glyph" or entry.kind == "talent" then return end

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
    hIcon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_02")
    hIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", hIcon, "RIGHT", 6, 0)
    title:SetText("|cffb266ffInformación del Personaje:|r")
    sp.title = title

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        sp:Hide()
    end)

    local refreshBtn = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    refreshBtn:SetSize(86, 20)
    refreshBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
    refreshBtn:SetText("Actualizar")
    refreshBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if sp.currentBot and DungeonBots.QueryBotSpells then
            DungeonBots:QueryBotSpells(sp.currentBot, sp.activeMode, "", false)
        end
    end)
    sp.refreshBtn = refreshBtn

    -- Subpestanas de modo: Hechizos / Glifos / Talentos (tamano compacto y equilibrado)
    sp.modeButtons = {}
    local modeBtnW = 124
    local modeBtnGap = 10
    local modeStartX = math.floor((560 - (3 * modeBtnW + 2 * modeBtnGap)) / 2)
    for idx, tabDef in ipairs(MODE_TABS) do
        local mBtn = CreateFrame("Button", "DungeonBots_SpellsModeTab_" .. tabDef.id, sp, "UIPanelButtonTemplate")
        mBtn:SetSize(modeBtnW, 22)
        mBtn:SetPoint("TOPLEFT", sp, "TOPLEFT", modeStartX + ((idx - 1) * (modeBtnW + modeBtnGap)), -40)
        mBtn:SetText(tabDef.label)
        ConfigureIconTabButton(mBtn, tabDef.icon)
        mBtn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            sp.activeMode = tabDef.id
            sp.selectedSpell = nil
            local existingTab, rec = DB_Internal.GetBotSpellTabData(sp.currentBot, tabDef.id)
            if rec then
                rec.activeMode = tabDef.id
            end
            if sp.currentBot and (not existingTab or (existingTab.updatedAt == 0 and not existingTab.loading) or (tabDef.id == "talents" and existingTab.inspectError)) then
                DungeonBots:QueryBotSpells(sp.currentBot, tabDef.id, "", false)
            else
                DungeonBots:UpdateSpellsDialog(sp.currentBot)
            end
        end)
        sp.modeButtons[tabDef.id] = mBtn
    end

    -- Barra de busqueda local (visible en modo Hechizos)
    local filterBar = CreateFrame("Frame", nil, sp)
    filterBar:SetPoint("TOPLEFT", sp, "TOPLEFT", 10, -66)
    filterBar:SetPoint("TOPRIGHT", sp, "TOPRIGHT", -10, -66)
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

    -- Selector de las 3 ramas de talentos (tira plana oscura distinta a los botones principales)
    local talentTreeBar = CreateFrame("Frame", "DungeonBots_TalentTreeBar", sp)
    talentTreeBar:SetPoint("TOPLEFT", sp, "TOPLEFT", 10, -66)
    talentTreeBar:SetPoint("TOPRIGHT", sp, "TOPRIGHT", -10, -66)
    talentTreeBar:SetHeight(24)
    talentTreeBar:Hide()
    sp.talentTreeBar = talentTreeBar

    sp.talentTreeButtons = {}
    for t = 1, 3 do
        local treeIndex = t
        local tBtn = CreateFrame("Button", "DungeonBots_TalentTreeTab_" .. t, talentTreeBar)
        tBtn:SetSize(176, 24)
        tBtn:SetPoint("TOPLEFT", talentTreeBar, "TOPLEFT", (t - 1) * 182, 0)
        ApplyDarkBackdrop(tBtn, 8)
        tBtn:SetBackdropColor(0.05, 0.06, 0.09, 0.90)
        tBtn:SetBackdropBorderColor(0.28, 0.32, 0.40, 0.75)
        tBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

        local tIcon = tBtn:CreateTexture(nil, "ARTWORK")
        tIcon:SetSize(15, 15)
        tIcon:SetPoint("LEFT", tBtn, "LEFT", 8, 0)
        tIcon:SetTexture("Interface\\Icons\\Ability_Marksmanship")
        tIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        tBtn.tabIcon = tIcon

        local tLabel = tBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tLabel:SetPoint("LEFT", tIcon, "RIGHT", 5, 0)
        tLabel:SetPoint("RIGHT", tBtn, "RIGHT", -6, 0)
        tLabel:SetJustifyH("CENTER")
        tLabel:SetText("Rama " .. t)
        tBtn:SetFontString(tLabel)
        tBtn.text = tLabel

        local accentBar = tBtn:CreateTexture(nil, "OVERLAY")
        accentBar:SetHeight(2)
        accentBar:SetPoint("BOTTOMLEFT", tBtn, "BOTTOMLEFT", 4, 2)
        accentBar:SetPoint("BOTTOMRIGHT", tBtn, "BOTTOMRIGHT", -4, 2)
        accentBar:SetTexture(0.35, 0.80, 1.0, 0.95)
        accentBar:Hide()
        tBtn.accentBar = accentBar
        tBtn.isDarkTreeTab = true

        tBtn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            if sp.currentBot and DB_Internal.SelectBotTalentTree then
                DB_Internal.SelectBotTalentTree(sp.currentBot, treeIndex)
            end
        end)
        sp.talentTreeButtons[t] = tBtn
    end

    -- Hint de modo secundario (cuando NO esta en modo Hechizos)
    local modeHintLabel = sp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modeHintLabel:SetPoint("TOPLEFT", sp, "TOPLEFT", 14, -72)
    modeHintLabel:SetPoint("TOPRIGHT", sp, "TOPRIGHT", -14, -72)
    modeHintLabel:SetJustifyH("LEFT")
    modeHintLabel:Hide()
    sp.modeHintLabel = modeHintLabel

    -- Panel de lista con scroll
    local listBg = CreateFrame("Frame", nil, sp)
    listBg:SetPoint("TOPLEFT", sp, "TOPLEFT", 10, -96)
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

    -- Barra inferior: Siguiente Bot + (idx/total) + Talentos  |  Lanzar (cast)
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

    local talentsBtn = CreateFrame("Button", nil, sp, "UIPanelButtonTemplate")
    talentsBtn:SetSize(104, 24)
    talentsBtn:SetPoint("LEFT", botCycleLabel, "RIGHT", 6, 0)
    talentsBtn:SetText("Cambiar Rama")
    talentsBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if DungeonBots.OpenTab then
            DungeonBots:OpenTab(2)
        end
    end)
    talentsBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Cambiar Rama / Grupo", 1, 0.82, 0)
        GameTooltip:AddLine("Abre la pestaña Bots en el grupo para cambiar su especialización.", 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    talentsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    sp.talentsBtn = talentsBtn

    local castBtn = CreateRedIconButton(sp, 98, 24, "Lanzar", "Interface\\Icons\\Spell_Holy_MagicalSentry")
    castBtn:SetPoint("BOTTOMRIGHT", sp, "BOTTOMRIGHT", -12, 10)
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

    DungeonBots.spellsFrame = sp
end

local function IsValidMode(mode)
    return mode == "spells" or mode == "glyphs" or mode == "talents"
end

local function FormatCachedTalentSummary(botName)
    local activeSpec = DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[botName]
    local triplet = DungeonBots.lastDetectedTriplet and DungeonBots.lastDetectedTriplet[botName]
    local specTxt = activeSpec and ((DungeonBots.LocalizeSpecText and DungeonBots:LocalizeSpecText(activeSpec)) or activeSpec) or nil
    if specTxt and triplet then
        return "|cff71d5ffRama activa:|r |cffffd200" .. specTxt .. "|r |cff8899aa(" .. triplet .. ")|r"
    elseif specTxt then
        return "|cff71d5ffRama activa:|r |cffffd200" .. specTxt .. "|r"
    elseif triplet then
        return "|cff71d5ffReparto de talentos:|r |cffffd200" .. triplet .. "|r"
    end
    return "|cff71d5ffTalentos:|r Pasa el ratón por cada talento para ver su descripción."
end

local function RenderTalentTreeBar(sp, tab)
    local trees = (tab and type(tab.trees) == "table") and tab.trees or {}
    if #trees == 0 then
        sp.talentTreeBar:Hide()
        return false, nil
    end

    sp.talentTreeBar:Show()
    local selectedTree = tab.selectedTree or 1
    local activeTreeName = trees[selectedTree] and trees[selectedTree].name or ("Rama " .. selectedTree)

    for t = 1, 3 do
        local tBtn = sp.talentTreeButtons[t]
        local treeInfo = trees[t]
        if tBtn and treeInfo then
            local pts = treeInfo.pointsSpent or 0
            local labelTxt = (treeInfo.name or ("Rama " .. t)) .. " (" .. pts .. ")"
            if tBtn.tabIcon then
                tBtn.tabIcon:SetTexture(treeInfo.icon or "Interface\\Icons\\Ability_Marksmanship")
            end
            if tBtn.text then
                tBtn.text:SetText(labelTxt)
            end
            tBtn:SetText(labelTxt)

            if t == selectedTree then
                tBtn:SetAlpha(1.0)
                tBtn:SetBackdropColor(0.11, 0.22, 0.36, 0.96)
                tBtn:SetBackdropBorderColor(0.35, 0.78, 1.0, 0.95)
                if tBtn.text then tBtn.text:SetTextColor(1.0, 1.0, 1.0) end
                if tBtn.tabIcon then tBtn.tabIcon:SetVertexColor(1.0, 1.0, 1.0, 1.0) end
                if tBtn.accentBar then tBtn.accentBar:Show() end
                tBtn.isSelectedTree = true
            else
                tBtn:SetAlpha(0.92)
                if pts > 0 then
                    tBtn:SetBackdropColor(0.06, 0.08, 0.12, 0.92)
                    tBtn:SetBackdropBorderColor(0.32, 0.36, 0.45, 0.85)
                    if tBtn.text then tBtn.text:SetTextColor(0.90, 0.82, 0.55) end
                    if tBtn.tabIcon then tBtn.tabIcon:SetVertexColor(0.95, 0.95, 0.95, 0.95) end
                else
                    tBtn:SetBackdropColor(0.04, 0.05, 0.08, 0.80)
                    tBtn:SetBackdropBorderColor(0.20, 0.22, 0.27, 0.65)
                    if tBtn.text then tBtn.text:SetTextColor(0.55, 0.57, 0.62) end
                    if tBtn.tabIcon then tBtn.tabIcon:SetVertexColor(0.65, 0.65, 0.65, 0.80) end
                end
                if tBtn.accentBar then tBtn.accentBar:Hide() end
                tBtn.isSelectedTree = false
            end
            tBtn:Show()
        elseif tBtn then
            tBtn:Hide()
        end
    end
    return true, activeTreeName
end

function DungeonBots:UpdateSpellsDialog(botName)
    local sp = DungeonBots.spellsFrame
    if not sp then return end

    local targetBot = botName or sp.currentBot
    if not targetBot then return end
    sp.currentBot = targetBot

    local mode = IsValidMode(sp.activeMode) and sp.activeMode or "spells"
    sp.activeMode = mode
    local tab = DB_Internal.GetBotSpellTabData(targetBot, mode)

    local unit = DungeonBots.FindPartyUnitByName and DungeonBots:FindPartyUnitByName(targetBot)
    local classHex = "|cffffd200"
    if unit and UnitClass and RAID_CLASS_COLORS then
        local _, classToken = UnitClass(unit)
        local c = classToken and RAID_CLASS_COLORS[classToken]
        if c then
            classHex = string.format("|cff%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
        end
    end
    sp.title:SetText("|cffb266ffInformación del Personaje:|r " .. classHex .. targetBot .. "|r")

    for tabId, mBtn in pairs(sp.modeButtons) do
        if tabId == mode then
            mBtn:SetAlpha(1.0)
            mBtn:LockHighlight()
        else
            mBtn:SetAlpha(0.75)
            mBtn:UnlockHighlight()
        end
    end

    local allItems = (tab and tab.items) or {}
    local visibleEntries = {}
    local filterRaw = ""
    local activeTreeName = nil

    if mode == "spells" then
        sp.filterBar:Show()
        sp.talentTreeBar:Hide()
        sp.modeHintLabel:Hide()
        sp.castBtn:Show()

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
    elseif mode == "glyphs" then
        sp.filterBar:Hide()
        sp.talentTreeBar:Hide()
        sp.modeHintLabel:Hide()
        sp.castBtn:Hide()
        sp.selectedSpell = nil
        visibleEntries = allItems
    else
        sp.filterBar:Hide()
        sp.castBtn:Hide()
        sp.selectedSpell = nil
        local hasTreeBar, treeName = RenderTalentTreeBar(sp, tab)
        activeTreeName = treeName
        if hasTreeBar then
            sp.modeHintLabel:Hide()
        else
            sp.modeHintLabel:Show()
            sp.modeHintLabel:SetText(FormatCachedTalentSummary(targetBot))
        end
        visibleEntries = allItems
    end

    if sp.listBg then
        local listTopY = (mode == "glyphs") and -68 or -96
        sp.listBg:ClearAllPoints()
        sp.listBg:SetPoint("TOPLEFT", sp, "TOPLEFT", 10, listTopY)
        sp.listBg:SetPoint("BOTTOMRIGHT", sp, "BOTTOMRIGHT", -10, 42)
    end

    if #visibleEntries == 0 then
        sp.emptyLabel:Show()
        if tab and tab.loading then
            local what = (mode == "talents" and "talentos") or (mode == "glyphs" and "glifos") or "hechizos"
            sp.emptyLabel:SetText("Consultando " .. what .. " de |cffffd200" .. targetBot .. "|r...")
        elseif tab and tab.inspectError then
            sp.emptyLabel:SetText(tab.inspectError)
        elseif tab and tab.emptyHint then
            sp.emptyLabel:SetText(tab.emptyHint)
        elseif mode == "talents" and activeTreeName then
            sp.emptyLabel:SetText("Sin puntos asignados en la rama |cffffd200" .. activeTreeName .. "|r.")
        elseif #allItems == 0 then
            if mode == "talents" then
                sp.emptyLabel:SetText("No se encontraron talentos asignados para |cffffd200" .. targetBot .. "|r.")
            elseif mode == "glyphs" then
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
        local isTalent = (entry.kind == "talent")
        local titleTxt = entry.name or entry.rawName or (isTalent and "Talento" or (isGlyph and "Glifo" or "Hechizo"))
        if entry.rank and entry.rank ~= "" then
            titleTxt = titleTxt .. " |cff888888(" .. entry.rank .. ")|r"
        end
        row.nameLabel:SetText(titleTxt)

        if isTalent then
            local currRank = entry.currentRank or 0
            local maxRank = entry.maxRank or currRank
            local maxed = (maxRank > 0 and currRank >= maxRank)
            row.diffBadge:SetText((maxed and "|cffffd200" or "|cff34c759") .. currRank .. "/" .. maxRank .. "|r")
            row.subLabel:SetText("|cff8899aa" .. (entry.treeName or "Talento") .. "  ·  Nivel " .. (entry.tier or 1) .. "  |  Shift + Clic: enlazar|r")
        elseif isGlyph then
            local glyphType = entry.categoryTag or "Glifo"
            row.diffBadge:SetText("|cff71d5ff" .. glyphType .. " #" .. i .. "|r")
            row.subLabel:SetText("|cff8899aaGlifo equipado  |  Pasa el ratón para ver detalles|r")
        else
            local badgeParts = {}
            if entry.craftableCount then
                table.insert(badgeParts, "|cff34c759x" .. entry.craftableCount .. "|r")
            end
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

    for i = #visibleEntries + 1, #spellRowButtons do
        spellRowButtons[i].spellEntry = nil
        spellRowButtons[i]:Hide()
    end

    sp.scrollChild:SetHeight(math.max(1, (#visibleEntries * SPELL_ROW_PITCH) + 8))
    UpdateSpellSelectionUI()

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
        sp.activeMode = "spells"
    end
    sp.currentBot = botName
    DungeonBots:UpdateSpellsDialog(botName)
    sp:Show()
    if sp.Raise then
        pcall(sp.Raise, sp)
    end
end
