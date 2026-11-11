-- =========================================================================
-- DungeonBots_HUD.lua: Barra Táctica Flotante de Mazmorras
-- =========================================================================

DungeonBots = DungeonBots or {}

local hudFrame = nil

local HUD_ACTIONS = {
    {
        name = "Focus Target",
        cmd = "do attack my target",
        icon = "Interface\\Icons\\Ability_Warrior_OffensiveStance",
        title = "|cffff2020¡Atacar Mi Objetivo!|r",
        desc = "Fuerza a todos los bots a cambiar de objetivo de inmediato hacia tu objetivo actual.\n\n|cff71d5ffIdeal para adds prioritarios o emergencias.|r",
        color = { 1.0, 0.2, 0.2 }
    },
    {
        name = "Pull Tanque",
        cmd = "pull my target",
        icon = "Interface\\Icons\\Ability_Hunter_AimedShot",
        title = "|cffff9900Pull con Tanque (Pull Target)|r",
        desc = "Ordena al bot tanque jalar al objetivo seleccionado usando disparo a distancia, lanzamiento heroico o taunt sin que el resto del grupo se lance antes de tiempo.\n\n|cff71d5ffEsencial para no atraer patrullas en mazmorras.|r",
        color = { 1.0, 0.6, 0.1 }
    },
    {
        name = "Quedarse",
        cmd = "stay",
        icon = "Interface\\Icons\\Spell_Nature_TimeStop",
        title = "|cffffff00Quedarse (Stay)|r",
        desc = "Ordena a los bots frenar en seco y mantener su posición actual.\n\n|cff71d5ffÚtil antes de que jalen patrullas o para posicionar el grupo.|r",
        color = { 1.0, 0.9, 0.2 }
    },
    {
        name = "Seguir",
        cmd = "follow",
        icon = "Interface\\Icons\\Ability_Tracking",
        title = "|cff00ff00Seguir (Follow)|r",
        desc = "Ordena a todos los bots reanudar el seguimiento normal tras de ti.",
        color = { 0.2, 1.0, 0.2 }
    },
    {
        name = "Summon",
        cmd = "summon",
        icon = "Interface\\Icons\\Spell_Nature_AstralRecalGroup",
        title = "|cff00ccffTeletransportar a Mí (Summon)|r",
        desc = "Teletransporta a todos los bots directamente a tu posición.\n\n|cff71d5ffSalva a bots atascados en el suelo, rampas o puertas.|r",
        color = { 0.2, 0.8, 1.0 }
    },
    {
        name = "¡Huir!",
        cmd = "flee",
        icon = "Interface\\Icons\\Spell_Magic_LesserInvisibilty",
        title = "|cffff3b30¡HUIR! (Flee)|r",
        desc = "¡Botón de pánico! Fuerza a los bots a romper el combate y correr hacia ti.\n\n|cff71d5ffPerfecto para salvar un wipe o hacer un pull tras una esquina.|r",
        color = { 1.0, 0.3, 0.3 }
    },
    {
        name = "Descansar",
        cmd = "drink",
        icon = "Interface\\Icons\\INV_Drink_07",
        title = "|cff00e5ffDescansar / Beber|r",
        desc = "Ordena a los curadores y lanzadores de hechizos sentarse a recuperar maná y vida antes del siguiente combate.",
        color = { 0.3, 0.7, 1.0 }
    },
}

function DungeonBots:IsInFiveManDungeon()
    local inInstance, instanceType = IsInInstance()
    return (inInstance and instanceType == "party") and true or false
end

function DungeonBots:UpdateHUDVisibility()
    if not hudFrame then return end
    if DungeonBotsDB and DungeonBotsDB.hudVisible == false then
        hudFrame:Hide()
        return
    end
    local onlyInDungeon = (not DungeonBotsDB) or (DungeonBotsDB.hudOnlyInDungeon ~= false)
    if onlyInDungeon and not DungeonBots:IsInFiveManDungeon() then
        hudFrame:Hide()
    else
        hudFrame:Show()
    end
end

function DungeonBots:InitHUD()
    if hudFrame then return end

    local btnSize = 34
    local spacing = 4
    local startX = 28
    local totalWidth = startX + (#HUD_ACTIONS * (btnSize + spacing)) - spacing + 28

    local f = CreateFrame("Frame", "DungeonBots_HUDFrame", UIParent)
    f:SetSize(totalWidth, 48)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    -- Restaurar posición guardada
    local pos = (DungeonBotsDB and DungeonBotsDB.hudPosition) or { point = "BOTTOM", x = 0, y = 140 }
    f:SetPoint(pos.point or "BOTTOM", UIParent, pos.point or "BOTTOM", pos.x or 0, pos.y or 140)

    f:SetScript("OnDragStart", function(self)
        if not (DungeonBotsDB and DungeonBotsDB.hudLocked) then
            self:StartMoving()
        end
    end)

    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        if DungeonBotsDB then
            DungeonBotsDB.hudPosition = { point = point, x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
        end
    end)

    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    f:SetBackdropColor(0.07, 0.08, 0.11, 0.92)
    f:SetBackdropBorderColor(0.68, 0.62, 0.44, 1.0)

    -- Botón de bloqueo (candado nativo de WoW 3.3.5a)
    local lockBtn = CreateFrame("Button", nil, f)
    lockBtn:SetSize(18, 18)
    lockBtn:SetPoint("LEFT", f, "LEFT", 5, 0)
    lockBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    local lockIcon = lockBtn:CreateTexture(nil, "ARTWORK")
    lockIcon:SetAllPoints()
    lockIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-LOCK")
    lockIcon:SetTexCoord(0, 0.875, 0, 0.875)

    local function updateLockVisual()
        local isLocked = DungeonBotsDB and DungeonBotsDB.hudLocked
        if isLocked then
            lockIcon:SetVertexColor(1.0, 0.35, 0.35, 1.0)
        else
            lockIcon:SetVertexColor(0.35, 1.0, 0.35, 0.85)
        end
    end
    updateLockVisual()

    lockBtn:SetScript("OnClick", function()
        if DungeonBotsDB then
            DungeonBotsDB.hudLocked = not DungeonBotsDB.hudLocked
            updateLockVisual()
            if DungeonBotsDB.hudLocked then
                DungeonBots:Print("HUD Táctico: |cffff3b30Bloqueado|r.")
            else
                DungeonBots:Print("HUD Táctico: |cff34c759Desbloqueado|r (puedes arrastrarlo).")
            end
        end
    end)

    lockBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local isLocked = DungeonBotsDB and DungeonBotsDB.hudLocked
        GameTooltip:AddLine(isLocked and "HUD Bloqueado" or "HUD Desbloqueado", 1, 1, 1)
        GameTooltip:AddLine("Haz clic para " .. (isLocked and "desbloquear y poder moverlo." or "bloquear en su sitio."), 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    lockBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Crear los botones de acción
    for i, action in ipairs(HUD_ACTIONS) do
        local btn = CreateFrame("Button", "DungeonBots_HUDExtBtn_" .. i, f)
        btn:SetSize(btnSize, btnSize)
        btn:SetPoint("LEFT", f, "LEFT", startX + (i - 1) * (btnSize + spacing), 0)
        btn:RegisterForClicks("LeftButtonUp")

        -- Fondo del botón con borde estilizado y nítido
        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        btn:SetBackdropColor(0.06, 0.08, 0.12, 0.95)
        btn:SetBackdropBorderColor(action.color[1], action.color[2], action.color[3], 0.85)

        -- Textura del icono ajustada limpiamente dentro del marco
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 3, -3)
        icon:SetPoint("BOTTOMRIGHT", -3, 3)
        icon:SetTexture(action.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Textura al pasar el ratón (Highlight)
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetPoint("TOPLEFT", 3, -3)
        highlight:SetPoint("BOTTOMRIGHT", -3, 3)
        highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlight:SetBlendMode("ADD")

        btn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:SendPartyCommand(action.cmd)
        end)

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(action.title, 1, 1, 1)
            GameTooltip:AddLine(action.desc, 0.85, 0.85, 0.85, true)
            GameTooltip:AddLine("Comando enviado: |cffffd200/p " .. action.cmd .. "|r", 0.5, 0.8, 1.0)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    -- Botón de acceso al panel principal a la derecha
    local mainBtn = CreateFrame("Button", nil, f)
    mainBtn:SetSize(16, 16)
    mainBtn:SetPoint("RIGHT", f, "RIGHT", -6, 0)

    local mainIcon = mainBtn:CreateTexture(nil, "ARTWORK")
    mainIcon:SetAllPoints()
    mainIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    mainIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    mainBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DungeonBots:ToggleUI()
    end)
    mainBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Abrir Panel DungeonBots", 1, 1, 1)
        GameTooltip:AddLine("Abre la ventana completa de configuración, clases y talentos.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    mainBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    hudFrame = f
    DungeonBots.hudFrame = f

    DungeonBots:UpdateHUDVisibility()
end

function DungeonBots:ToggleHUD()
    if not hudFrame then
        DungeonBots:InitHUD()
    end
    if hudFrame:IsShown() then
        hudFrame:Hide()
        if DungeonBotsDB then DungeonBotsDB.hudVisible = false end
        DungeonBots:Print("HUD Táctico ocultado. Escribe |cffffd200/db hud|r para mostrarlo.")
    else
        if DungeonBotsDB then DungeonBotsDB.hudVisible = true end
        DungeonBots:UpdateHUDVisibility()
        if hudFrame:IsShown() then
            DungeonBots:Print("HUD Táctico visible.")
        else
            DungeonBots:Print("HUD Táctico activado (aparecerá automáticamente al entrar a una mazmorra de 5 jugadores). Puedes cambiar esto en 'Armar Grupo'.")
        end
    end
end

