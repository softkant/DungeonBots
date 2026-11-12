-- =========================================================================
-- UI\Theme.lua: Primitivas Visuales, Estilos de Panel, Botones y Tooltips
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal

local function EnsureStoneTextures(frame, pad, stoneR, stoneG, stoneB, stoneA, tintR, tintG, tintB, tintA)
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
    frame._dbStoneBg:SetVertexColor(stoneR, stoneG, stoneB, stoneA)
    frame._dbStoneTint:SetTexture(tintR, tintG, tintB, tintA)
end

local function ApplyBlizzardGoldWindow(frame, edgeSize)
    edgeSize = edgeSize or 16
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = edgeSize,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.09, 0.08, 0.06, 0.98)
    EnsureStoneTextures(frame, 5, 0.88, 0.82, 0.70, 0.44, 0.045, 0.035, 0.022, 0.54)
end
DB_Internal.ApplyBlizzardGoldWindow = ApplyBlizzardGoldWindow

local function ApplyBlizzardStonePanel(frame, borderR, borderG, borderB, edgeSize, bgAlpha)
    edgeSize = edgeSize or 12
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = edgeSize,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.08, 0.07, 0.055, 0.96)
    frame:SetBackdropBorderColor(borderR or 0.68, borderG or 0.56, borderB or 0.32, 0.95)
    EnsureStoneTextures(frame, 3, 0.76, 0.70, 0.60, bgAlpha or 0.34, 0.03, 0.025, 0.02, 0.56)
end
DB_Internal.ApplyBlizzardStonePanel = ApplyBlizzardStonePanel

local function ApplyDarkBackdrop(frame, edgeSize)
    edgeSize = edgeSize or 12
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = edgeSize,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.085, 0.072, 0.055, 0.96)
    frame:SetBackdropBorderColor(0.70, 0.56, 0.30, 0.95)
end
DB_Internal.ApplyDarkBackdrop = ApplyDarkBackdrop

local function ApplyInsetPanelBackdrop(frame, edgeSize)
    edgeSize = edgeSize or 10
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 14, edgeSize = edgeSize,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.095, 0.080, 0.060, 0.95)
    frame:SetBackdropBorderColor(0.54, 0.44, 0.26, 0.90)
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
DB_Internal.AddQuickSlotBorder = AddQuickSlotBorder

local function ApplyHeaderBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0.15, 0.115, 0.08, 0.98)
    frame:SetBackdropBorderColor(0.74, 0.60, 0.32, 0.95)

    if not frame._dbHeaderBg then
        local hBg = frame:CreateTexture(nil, "BACKGROUND")
        hBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        hBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
        hBg:SetTexture(0.15, 0.115, 0.08, 0.96)
        frame._dbHeaderBg = hBg

        local hLine = frame:CreateTexture(nil, "BORDER")
        hLine:SetHeight(1)
        hLine:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 1)
        hLine:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 1)
        hLine:SetTexture(0.82, 0.68, 0.36, 0.45)
        frame._dbHeaderAccent = hLine
    end
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
