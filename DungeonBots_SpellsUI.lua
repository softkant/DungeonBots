-- =========================================================================
-- DungeonBots_SpellsUI.lua: Ventana de Poderes, Glifos, Entrenador y Stats
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
    { id = "spells",  label = "Hechizos" },
    { id = "glyphs",  label = "Glifos" },
    { id = "trainer", label = "Entrenador" },
    { id = "stats",   label = "Stats" },
}

local SPELL_ROW_HEIGHT = 40
local SPELL_ROW_PITCH = 43
local TEXT_ROW_HEIGHT = 24
local TEXT_ROW_PITCH = 26

local spellRowButtons = {}
local textRowButtons = {}

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
            local isSel = (selected ~= nil and row.spellEntry == selected)
            if isSel then
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
            sp.detailBtn:Enable()
            sp.detailBtn:SetAlpha(1.0)
            sp.castBtn:Enable()
            sp.castBtn:SetAlpha(1.0)
        else
            sp.detailBtn:Disable()
            sp.detailBtn:SetAlpha(0.45)
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
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

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

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local loadedRich = false
        if entry.spellId and GameTooltip.SetHyperlink then
            loadedRich = pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. entry.spellId)
        elseif entry.itemId and GameTooltip.SetHyperlink then
            loadedRich = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. entry.itemId)
        end
        if not loadedRich or (GameTooltip.NumLines and GameTooltip:NumLines() == 0) then
            GameTooltip:ClearLines()
            GameTooltip:AddLine(entry.name or entry.rawName or "Hechizo", 0.45, 0.85, 1.0)
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
        GameTooltip:AddLine("Clic izquierdo: |cffffffffSeleccionar|r  |  Clic derecho: |cff71d5ffInfo ('spell')|r", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    row:SetScript("OnClick", function(self, mouseBtn)
        local sp = DungeonBots.spellsFrame
        local entry = self.spellEntry
        if not sp or not entry then return end

        if mouseBtn == "RightButton" then
            sp.selectedSpell = entry
            UpdateSpellSelectionUI()
            if DungeonBots.QueryBotSpellDetail then
                DungeonBots:QueryBotSpellDetail(sp.currentBot, entry)
            end
            return
        end

        if IsModifiedClick and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
            local link = entry.displayLink or entry.rawLink or entry.plainLink
            if link and ChatEdit_InsertLink(link) then
                return
            end
        end

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

local function CreateTextRowButton(parent, idx)
    local row = CreateFrame("Button", "DungeonBots_SpellTextRow_" .. idx, parent)
    row:SetSize(492, TEXT_ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -((idx - 1) * TEXT_ROW_PITCH) - 4)
    row:RegisterForClicks("LeftButtonUp")

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("LEFT", row, "LEFT", 6, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:Hide()
    row.icon = icon

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", row, "LEFT", 8, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    row.label = label

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetBlendMode("ADD")
    hl:SetAlpha(0.12)

    row:SetScript("OnEnter", function(self)
        local data = self.lineData
        if not data then return end
        if data.firstLink and GameTooltip.SetHyperlink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, data.firstLink)
            if ok and (not GameTooltip.NumLines or GameTooltip:NumLines() > 0) then
                GameTooltip:Show()
                return
            end
        end
        if data.cleanText and data.cleanText ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(data.cleanText, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    textRowButtons[idx] = row
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
    hIcon:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry")
    hIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", hIcon, "RIGHT", 6, 0)
    title:SetText("|cffb266ffPoderes:|r")
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
            local filterTxt = (sp.activeMode == "spells" and sp.serverFilterBox) and sp.serverFilterBox:GetText() or ""
            DungeonBots:QueryBotSpells(sp.currentBot, sp.activeMode, filterTxt, false)
        end
    end)
    sp.refreshBtn = refreshBtn

    local statusLabel = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusLabel:SetPoint("RIGHT", refreshBtn, "LEFT", -8, 0)
    statusLabel:SetWidth(150)
    statusLabel:SetJustifyH("RIGHT")
    sp.statusLabel = statusLabel

    -- Subpestanas de modo: Hechizos / Glifos / Entrenador / Stats
    sp.modeButtons = {}
    for idx, tabDef in ipairs(MODE_TABS) do
        local mBtn = CreateFrame("Button", "DungeonBots_SpellsModeTab_" .. tabDef.id, sp, "UIPanelButtonTemplate")
        mBtn:SetSize(132, 22)
        mBtn:SetPoint("TOPLEFT", sp, "TOPLEFT", 10 + ((idx - 1) * 136), -40)
        mBtn:SetText(tabDef.label)
        mBtn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            sp.activeMode = tabDef.id
            sp.selectedSpell = nil
            local existingTab, rec = DB_Internal.GetBotSpellTabData(sp.currentBot, tabDef.id)
            if rec then
                rec.activeMode = tabDef.id
            end
            if sp.currentBot and (not existingTab or (existingTab.updatedAt == 0 and not existingTab.loading)) then
                local fTxt = (tabDef.id == "spells" and sp.serverFilterBox) and sp.serverFilterBox:GetText() or ""
                DungeonBots:QueryBotSpells(sp.currentBot, tabDef.id, fTxt, false)
            else
                DungeonBots:UpdateSpellsDialog(sp.currentBot)
            end
        end)
        sp.modeButtons[tabDef.id] = mBtn
    end

    -- Barra de filtros (visible en modo Hechizos)
    local filterBar = CreateFrame("Frame", nil, sp)
    filterBar:SetPoint("TOPLEFT", sp, "TOPLEFT", 10, -66)
    filterBar:SetPoint("TOPRIGHT", sp, "TOPRIGHT", -10, -66)
    filterBar:SetHeight(24)
    sp.filterBar = filterBar

    local localLbl = filterBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    localLbl:SetPoint("LEFT", filterBar, "LEFT", 2, 0)
    localLbl:SetText("Buscar:")

    local localSearchBox = CreateFrame("EditBox", "DungeonBots_SpellsLocalSearchBox", filterBar, "InputBoxTemplate")
    localSearchBox:SetSize(142, 20)
    localSearchBox:SetPoint("LEFT", localLbl, "RIGHT", 8, 0)
    localSearchBox:SetAutoFocus(false)
    localSearchBox:SetScript("OnTextChanged", function()
        if DungeonBots.UpdateSpellsDialog then
            DungeonBots:UpdateSpellsDialog(sp.currentBot)
        end
    end)
    localSearchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    sp.localSearchBox = localSearchBox

    local serverLbl = filterBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    serverLbl:SetPoint("LEFT", localSearchBox, "RIGHT", 14, 0)
    serverLbl:SetText("Filtro 'spells':")

    local serverFilterBox = CreateFrame("EditBox", "DungeonBots_SpellsServerFilterBox", filterBar, "InputBoxTemplate")
    serverFilterBox:SetSize(124, 20)
    serverFilterBox:SetPoint("LEFT", serverLbl, "RIGHT", 8, 0)
    serverFilterBox:SetAutoFocus(false)
    serverFilterBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if sp.currentBot and DungeonBots.QueryBotSpells then
            DungeonBots:QueryBotSpells(sp.currentBot, "spells", self:GetText(), false)
        end
    end)
    serverFilterBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    serverFilterBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Filtro de comando 'spells <parámetro>'", 1, 0.82, 0)
        GameTooltip:AddLine("Ejemplos compatibles:", 1, 1, 1)
        GameTooltip:AddLine("  <nombre>       - Filtra por nombre de poder", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("  tailoring      - Recetas de profesión", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("  +first aid     - Solo lo crafteable ahora", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("  20-40          - Crafteos de nivel 20 a 40", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("  head / chest   - Recetas por hueco de equipo", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("Pulsa Enter o 'Consultar' (vacío = todos).", 0.5, 0.8, 1.0)
        GameTooltip:Show()
    end)
    serverFilterBox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    sp.serverFilterBox = serverFilterBox

    local queryFilterBtn = CreateFrame("Button", nil, filterBar, "UIPanelButtonTemplate")
    queryFilterBtn:SetSize(74, 20)
    queryFilterBtn:SetPoint("LEFT", serverFilterBox, "RIGHT", 6, 0)
    queryFilterBtn:SetText("Consultar")
    queryFilterBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if sp.currentBot and DungeonBots.QueryBotSpells then
            DungeonBots:QueryBotSpells(sp.currentBot, "spells", serverFilterBox:GetText(), false)
        end
    end)

    local clearFilterBtn = CreateFrame("Button", nil, filterBar, "UIPanelButtonTemplate")
    clearFilterBtn:SetSize(52, 20)
    clearFilterBtn:SetPoint("LEFT", queryFilterBtn, "RIGHT", 4, 0)
    clearFilterBtn:SetText("Todos")
    clearFilterBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        localSearchBox:SetText("")
        serverFilterBox:SetText("")
        if sp.currentBot and DungeonBots.QueryBotSpells then
            DungeonBots:QueryBotSpells(sp.currentBot, "spells", "", false)
        end
    end)

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

    -- Caja inferior opcional de detalle ('spell [link]')
    local detailBox = CreateFrame("Frame", nil, sp)
    detailBox:SetPoint("BOTTOMLEFT", sp, "BOTTOMLEFT", 10, 42)
    detailBox:SetPoint("BOTTOMRIGHT", sp, "BOTTOMRIGHT", -10, 42)
    detailBox:SetHeight(58)
    ApplyDarkBackdrop(detailBox, 8)
    detailBox:SetBackdropColor(0.05, 0.07, 0.11, 1.0)
    detailBox:SetBackdropBorderColor(0.45, 0.35, 0.75, 0.90)
    detailBox:Hide()
    sp.detailBox = detailBox

    local detailTitle = detailBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detailTitle:SetPoint("TOPLEFT", detailBox, "TOPLEFT", 8, -6)
    detailTitle:SetPoint("RIGHT", detailBox, "RIGHT", -28, 0)
    detailTitle:SetJustifyH("LEFT")
    sp.detailTitle = detailTitle

    local detailBody = detailBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detailBody:SetPoint("TOPLEFT", detailTitle, "BOTTOMLEFT", 0, -3)
    detailBody:SetPoint("BOTTOMRIGHT", detailBox, "BOTTOMRIGHT", -8, 6)
    detailBody:SetJustifyH("LEFT")
    detailBody:SetJustifyV("TOP")
    sp.detailBody = detailBody

    local detailCloseBtn = CreateFrame("Button", nil, detailBox, "UIPanelCloseButton")
    detailCloseBtn:SetSize(18, 18)
    detailCloseBtn:SetPoint("TOPRIGHT", detailBox, "TOPRIGHT", -2, -2)
    detailCloseBtn:SetScript("OnClick", function()
        local _, rec = DB_Internal.GetBotSpellTabData(sp.currentBot, sp.activeMode)
        if rec then rec.spellDetail = nil end
        DungeonBots:UpdateSpellsDialog(sp.currentBot)
    end)

    -- Barra inferior: Siguiente Bot + (idx/total) + Talentos  |  Info (spell) + Lanzar (cast)
    local nextBotBtn = CreateFrame("Button", nil, sp, "UIPanelButtonTemplate")
    nextBotBtn:SetSize(118, 24)
    nextBotBtn:SetPoint("BOTTOMLEFT", sp, "BOTTOMLEFT", 12, 10)
    nextBotBtn:SetText("Siguiente Bot")
    nextBotBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        sp.selectedSpell = nil
        if DungeonBots.CycleNextSpellsBot then
            local filterTxt = sp.serverFilterBox and sp.serverFilterBox:GetText() or ""
            DungeonBots:CycleNextSpellsBot(sp.currentBot, sp.activeMode, filterTxt)
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
    talentsBtn:SetSize(78, 24)
    talentsBtn:SetPoint("LEFT", botCycleLabel, "RIGHT", 6, 0)
    talentsBtn:SetText("Talentos")
    talentsBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if DungeonBots.OpenTab then
            DungeonBots:OpenTab(2)
        end
    end)
    talentsBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Ver Talentos y Grupo", 1, 0.82, 0)
        GameTooltip:AddLine("Abre la pestaña Bots en el grupo para cambiar ramas ('talents').", 0.85, 0.85, 0.85, true)
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

    local detailBtn = CreateFrame("Button", nil, sp, "UIPanelButtonTemplate")
    detailBtn:SetSize(96, 24)
    detailBtn:SetPoint("RIGHT", castBtn, "LEFT", -6, 0)
    detailBtn:SetText("Detalle")
    detailBtn:Disable()
    detailBtn:SetAlpha(0.45)
    detailBtn:SetScript("OnClick", function()
        if not sp.currentBot or not sp.selectedSpell then return end
        if DungeonBots.QueryBotSpellDetail then
            DungeonBots:QueryBotSpellDetail(sp.currentBot, sp.selectedSpell)
        end
    end)
    detailBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Consultar info del hechizo ('spell')", 1, 0.82, 0)
        GameTooltip:AddLine("Envía 'spell [link]' al bot para ver detalles del servidor.", 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    detailBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    sp.detailBtn = detailBtn

    local modeRefreshBtn = CreateFrame("Button", nil, sp, "UIPanelButtonTemplate")
    modeRefreshBtn:SetSize(112, 24)
    modeRefreshBtn:SetPoint("BOTTOMRIGHT", sp, "BOTTOMRIGHT", -12, 10)
    modeRefreshBtn:SetText("Reconsultar")
    modeRefreshBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if sp.currentBot and DungeonBots.QueryBotSpells then
            DungeonBots:QueryBotSpells(sp.currentBot, sp.activeMode, "", false)
        end
    end)
    modeRefreshBtn:Hide()
    sp.modeRefreshBtn = modeRefreshBtn

    DungeonBots.spellsFrame = sp
end

function DungeonBots:UpdateSpellsDialog(botName)
    local sp = DungeonBots.spellsFrame
    if not sp then return end

    local targetBot = botName or sp.currentBot
    if not targetBot then return end
    sp.currentBot = targetBot

    local mode = sp.activeMode or "spells"
    local tab, rec = DB_Internal.GetBotSpellTabData(targetBot, mode)

    local unit = DungeonBots.FindPartyUnitByName and DungeonBots:FindPartyUnitByName(targetBot)
    local classHex = "|cffffd200"
    if unit and UnitClass and RAID_CLASS_COLORS then
        local _, classToken = UnitClass(unit)
        local c = classToken and RAID_CLASS_COLORS[classToken]
        if c then
            classHex = string.format("|cff%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
        end
    end
    sp.title:SetText("|cffb266ffPoderes:|r " .. classHex .. targetBot .. "|r")

    for tabId, mBtn in pairs(sp.modeButtons) do
        if tabId == mode then
            mBtn:SetAlpha(1.0)
            mBtn:LockHighlight()
        else
            mBtn:SetAlpha(0.75)
            mBtn:UnlockHighlight()
        end
    end

    local hasDetail = (mode == "spells" and rec and rec.spellDetail ~= nil)
    if hasDetail then
        sp.detailTitle:SetText("|cffb266ffInfo 'spell':|r |cffffd200" .. (rec.spellDetail.title or "Hechizo") .. "|r")
        sp.detailBody:SetText(table.concat(rec.spellDetail.lines or {}, "  |  "))
        sp.detailBox:Show()
    else
        sp.detailBox:Hide()
    end

    sp.listBg:ClearAllPoints()
    sp.listBg:SetPoint("TOPLEFT", sp, "TOPLEFT", 10, -96)
    sp.listBg:SetPoint("BOTTOMRIGHT", sp, "BOTTOMRIGHT", -10, hasDetail and 106 or 42)

    if mode == "spells" then
        sp.filterBar:Show()
        sp.modeHintLabel:Hide()
        sp.detailBtn:Show()
        sp.castBtn:Show()
        sp.modeRefreshBtn:Hide()

        local allSpells = (tab and tab.items) or {}
        local filterRaw = sp.localSearchBox and sp.localSearchBox:GetText() or ""
        local filterText = string.lower(string.gsub(filterRaw, "^%s*(.-)%s*$", "%1"))

        local visibleSpells = {}
        local selectedVisible = false
        for _, entry in ipairs(allSpells) do
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
                table.insert(visibleSpells, entry)
                if sp.selectedSpell and sp.selectedSpell == entry then
                    selectedVisible = true
                end
            end
        end
        if not selectedVisible then
            sp.selectedSpell = nil
        end

        if tab and tab.loading then
            sp.statusLabel:SetText("|cffffd200Consultando...|r (" .. #allSpells .. ")")
        elseif #allSpells == 0 then
            sp.statusLabel:SetText("|cff8888880 hechizos|r")
        elseif filterText ~= "" then
            sp.statusLabel:SetText("|cff34c759" .. #visibleSpells .. "/" .. #allSpells .. "|r")
        else
            sp.statusLabel:SetText("|cff34c759" .. #allSpells .. "|r poderes")
        end

        for _, tRow in ipairs(textRowButtons) do
            tRow:Hide()
        end

        if #visibleSpells == 0 then
            sp.emptyLabel:Show()
            if tab and tab.loading then
                sp.emptyLabel:SetText("Consultando poderes de |cffffd200" .. targetBot .. "|r...")
            elseif tab and tab.emptyHint then
                sp.emptyLabel:SetText(tab.emptyHint)
            elseif #allSpells == 0 then
                sp.emptyLabel:SetText("No se recibieron poderes para |cffffd200" .. targetBot .. "|r.")
            else
                sp.emptyLabel:SetText("Ningún poder coincide con \"" .. filterRaw .. "\".")
            end
        else
            sp.emptyLabel:Hide()
        end

        for i, entry in ipairs(visibleSpells) do
            local row = spellRowButtons[i] or CreateSpellRowButton(sp.scrollChild, i)
            row.spellEntry = entry
            row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

            local titleTxt = entry.name or entry.rawName or "Hechizo"
            if entry.rank and entry.rank ~= "" then
                titleTxt = titleTxt .. " |cff888888(" .. entry.rank .. ")|r"
            end
            row.nameLabel:SetText(titleTxt)

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
            row.subLabel:SetText(regText or metaText or "|cff667788Clic izq.: sel.  |  Clic der.: 'spell'|r")
            row:Show()
        end

        for i = #visibleSpells + 1, #spellRowButtons do
            spellRowButtons[i].spellEntry = nil
            spellRowButtons[i]:Hide()
        end

        local totalHeight = math.max(1, (#visibleSpells * SPELL_ROW_PITCH) + 8)
        sp.scrollChild:SetHeight(totalHeight)
        UpdateSpellSelectionUI()
    else
        sp.filterBar:Hide()
        sp.modeHintLabel:Show()
        sp.detailBtn:Hide()
        sp.castBtn:Hide()
        sp.modeRefreshBtn:Show()

        if mode == "glyphs" then
            sp.modeHintLabel:SetText("|cff71d5ffGlifos equipados ('glyphs'):|r Pasa el ratón por las líneas con enlaces para ver su descripción.")
        elseif mode == "trainer" then
            sp.modeHintLabel:SetText("|cff71d5ffEntrenador ('trainer'):|r Muestra los hechizos aprendibles si el bot tiene un instructor cerca/seleccionado.")
        else
            sp.modeHintLabel:SetText("|cff71d5ffEstadísticas ('stats'):|r Resumen de atributos, equipo y estado reportado por el bot.")
        end

        for _, sRow in ipairs(spellRowButtons) do
            sRow.spellEntry = nil
            sRow:Hide()
        end

        local lines = (tab and tab.lines) or {}
        if tab and tab.loading then
            sp.statusLabel:SetText("|cffffd200Consultando...|r")
        else
            sp.statusLabel:SetText("|cff34c759" .. #lines .. "|r línea(s)")
        end

        if #lines == 0 then
            sp.emptyLabel:Show()
            if tab and tab.loading then
                sp.emptyLabel:SetText("Consultando '" .. mode .. "' a |cffffd200" .. targetBot .. "|r...")
            else
                sp.emptyLabel:SetText("No se recibieron líneas para '" .. mode .. "' de |cffffd200" .. targetBot .. "|r.")
            end
        else
            sp.emptyLabel:Hide()
        end

        for i, lData in ipairs(lines) do
            local row = textRowButtons[i] or CreateTextRowButton(sp.scrollChild, i)
            row.lineData = lData
            if lData.icon then
                row.icon:SetTexture(lData.icon)
                row.icon:Show()
                row.label:ClearAllPoints()
                row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            else
                row.icon:Hide()
                row.label:ClearAllPoints()
                row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            end
            row.label:SetText(lData.text or "")
            row:Show()
        end

        for i = #lines + 1, #textRowButtons do
            textRowButtons[i].lineData = nil
            textRowButtons[i]:Hide()
        end

        sp.scrollChild:SetHeight(math.max(1, (#lines * TEXT_ROW_PITCH) + 8))
    end

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
    if mode then
        sp.activeMode = mode
    end
    local _, rec = DB_Internal.GetBotSpellTabData(botName, sp.activeMode)
    if sp.serverFilterBox and rec then
        sp.serverFilterBox:SetText(rec.spellsFilter or "")
    end
    sp.currentBot = botName
    DungeonBots:UpdateSpellsDialog(botName)
    sp:Show()
    if sp.Raise then
        pcall(sp.Raise, sp)
    end
end
