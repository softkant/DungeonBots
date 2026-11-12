-- =========================================================================
-- UI\Theme.lua: Primitivas Visuales, Estilos de Panel, Botones y Tooltips
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal

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
DB_Internal.AddQuickSlotBorder = AddQuickSlotBorder

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
