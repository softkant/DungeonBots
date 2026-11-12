-- =========================================================================
-- DungeonBots_HUD.lua: Barras Flotantes (HUD Táctico y Barra de Utilidades)
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal
local hudFrame = nil
local utilHudFrame = nil
local formHudFrame = nil
local hudBotDropDown = nil
local hudTalkBtn = nil
local hudMenuWatcher = nil
local hudMenuAnchorBtn = nil
local hudMenuMouseWasDown = false

local TACTICAL_ACTIONS = {
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
}

local UTIL_ACTIONS = {
    {
        name = "Hablar PNJ",
        actionKind = "talk",
        isTalkPicker = true,
        icon = "Interface\\Icons\\Achievement_Reputation_01",
        title = "|cff00e5ffHablar con PNJ (Talk)|r",
        desc = "Consulta los diálogos y misiones del PNJ seleccionado mediante un bot.\n\n|cff71d5ffSi hay varios bots en grupo abre un menú para elegir cuál; si solo hay uno, lo envía directo.|r",
        tooltipCmd = "Acción: |cffffd200/w <Bot> talk|r (menú si hay 2+ bots)",
        color = { 0.2, 0.8, 1.0 }
    },
    {
        name = "Misiones de Bot",
        actionKind = "quests",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        texCoord = { 0.08, 0.92, 0.08, 0.92 },
        title = "|cffffd200Misiones de Bot|r",
        desc = "Abre un menú desplegable para elegir un bot del grupo y ver sus misiones activas.\n\n|cff71d5ffPermite consultar los detalles de cada misión o abandonarla.|r",
        tooltipCmd = "Acción: |cffffd200Elegir bot -> /w <Bot> quests all|r",
        color = { 1.0, 0.62, 0.15 }
    },
    {
        name = "Bots en el Grupo",
        actionKind = "party_tab",
        icon = "Interface\\Icons\\INV_Misc_GroupLooking",
        title = "|cffffd200Bots en el Grupo|r",
        desc = "Abre directamente la pestaña de gestión del grupo actual (talentos, equipo y misiones).\n\n|cff71d5ffAtajo rápido a la segunda pestaña de DungeonBots.|r",
        tooltipCmd = "Acción: |cffffd200Abrir pestaña Bots en el grupo|r",
        color = { 0.95, 0.78, 0.25 }
    },
    {
        name = "Inventario de Bot",
        actionKind = "inventory",
        icon = "Interface\\Icons\\INV_Misc_Bag_08",
        title = "|cff34c759Inventario y Bolsas de Bot|r",
        desc = "Abre un menú desplegable para elegir un bot del grupo y ver sus bolsas.\n\n|cff71d5ffPermite inspeccionar sus objetos y destruir los que no necesites.|r",
        tooltipCmd = "Acción: |cffffd200Elegir bot -> /w <Bot> c|r",
        color = { 0.35, 0.88, 0.45 }
    },
    {
        name = "Información del Personaje",
        actionKind = "spells",
        icon = "Interface\\Icons\\Achievement_Character_Human_Male",
        title = "|cffb266ffInformación del Personaje|r",
        desc = "Abre un menú desplegable para elegir un bot del grupo y gestionar su equipo, hechizos y glifos.\n\n|cff71d5ffPermite cambiar rama/equipo, consultar sus poderes y lanzar 'cast'.|r",
        tooltipCmd = "Acción: |cffffd200Elegir bot -> Info. Personaje|r",
        color = { 0.68, 0.45, 1.0 }
    },
}

local FORMATION_ACTIONS = {
    {
        name = "Formación Arrow",
        cmd = "formation arrow",
        formationId = "arrow",
        icon = "Interface\\Icons\\Ability_TrueShot",
        title = "|cff33d9ffFormación: Flecha (Arrow)|r",
        desc = "Coloca a tus bots en punta de flecha detrás de ti al moverse.\n\n|cff71d5ffIdeal para avanzar ordenado por pasillos de mazmorra.|r",
        color = { 0.20, 0.85, 1.0 }
    },
    {
        name = "Formación Far",
        cmd = "formation far",
        formationId = "far",
        icon = "Interface\\Icons\\Ability_Hunter_EagleEye",
        title = "|cff60b3ffFormación: Lejos (Far)|r",
        desc = "Mantiene a tus bots posicionados más atrás de ti.\n\n|cff71d5ffÚtil para asomarte a esquinas o pasillos sin que el grupo jale patrullas por error.|r",
        color = { 0.38, 0.70, 1.0 }
    },
    {
        name = "Otras Formaciones",
        actionKind = "formation_menu",
        icon = "Interface\\Icons\\Ability_Hunter_HuntingParty",
        title = "|cffffd200Otras Formaciones y Combate|r",
        desc = "Cambia entre el resto de formaciones (|cffffd200chaos|r por defecto, |cffffd200shield|r, |cffffd200circle|r, |cffffd200near|r, |cffffd200line|r, etc.), consulta la actual o fija la formación durante el combate.",
        tooltipCmd = "Menú: |cffffd200formation ... / co ±combat formation|r",
        color = { 0.95, 0.78, 0.25 }
    },
    {
        name = "Disperse",
        actionKind = "disperse_menu",
        icon = "Interface\\Icons\\Spell_Arcane_Blink",
        title = "|cffc673ffDisperse (Separación mínima)|r",
        desc = "Fija una distancia mínima en metros entre cada bot para que NO se queden apilados encima uno de otro.\n\n|cff71d5ffCómo usarlo:|r Actívalo (p. ej. 12m) antes de jefes con bombas, cadenas o daño AoE, y desactívalo al terminar.",
        tooltipCmd = "Menú: |cffffd200disperse set <m> / disperse disable|r",
        color = { 0.78, 0.45, 1.0 }
    },
    {
        name = "Move From Group",
        cmd = "move from group",
        icon = "Interface\\Icons\\Ability_Rogue_Sprint",
        title = "|cff57d98cSepararse del Grupo (Move From Group)|r",
        desc = "Orden puntual e inmediata para que los bots se aparten del montón en ese instante.\n\n|cff71d5ffIdeal en emergencias cuando cae un charco o mecánica AoE justo donde están parados.|r",
        color = { 0.34, 0.85, 0.55 }
    },
    {
        name = "Control de Pull y Espera",
        actionKind = "pull_wait_menu",
        icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
        title = "|cffff9e26Control de Pull y Espera|r",
        desc = "Configura cuántos segundos esperan los DPS/Healers antes de atacar al iniciar combate (|cffffd200wait for attack|r), además de pull hacia atrás, ataque solo del tanque y modo pasivo.",
        tooltipCmd = "Menú: |cffffd200wait for attack / pull back / tank attack / passive|r",
        color = { 1.0, 0.62, 0.15 }
    },
}

local function GetOrCreateHudBotDropDown()
    if hudBotDropDown then return hudBotDropDown end
    hudBotDropDown = CreateFrame("Frame", "DungeonBots_HUDTalkDropDown", UIParent, "UIDropDownMenuTemplate")
    hudBotDropDown.displayMode = "MENU"
    hudBotDropDown:Hide()
    return hudBotDropDown
end

local function IsCursorOverFrame(frame)
    if not frame or not frame.IsShown or not frame:IsShown() then
        return false
    end
    if MouseIsOver then
        return MouseIsOver(frame)
    end
    local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
    if not (left and right and top and bottom) then
        return false
    end
    local scale = frame:GetEffectiveScale() or 1
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    return cx >= left and cx <= right and cy >= bottom and cy <= top
end

local function EnsureHudMenuWatcher()
    if hudMenuWatcher then return hudMenuWatcher end
    hudMenuWatcher = CreateFrame("Frame", nil, UIParent)
    hudMenuWatcher:Hide()
    hudMenuWatcher:SetScript("OnUpdate", function(self)
        local list1 = _G.DropDownList1
        if not hudBotDropDown or UIDROPDOWNMENU_OPEN_MENU ~= hudBotDropDown or not list1 or not list1:IsShown() then
            self:Hide()
            hudMenuAnchorBtn = nil
            hudMenuMouseWasDown = false
            return
        end
        local down = IsMouseButtonDown and (
            IsMouseButtonDown("LeftButton")
            or IsMouseButtonDown("RightButton")
            or IsMouseButtonDown("MiddleButton")
        )
        if down then
            if not hudMenuMouseWasDown then
                hudMenuMouseWasDown = true
                local list2 = _G.DropDownList2
                local insideMenu = IsCursorOverFrame(list1) or IsCursorOverFrame(list2) or IsCursorOverFrame(hudMenuAnchorBtn)
                if not insideMenu and CloseDropDownMenus then
                    CloseDropDownMenus()
                end
            end
        else
            hudMenuMouseWasDown = false
        end
    end)
    return hudMenuWatcher
end

local function OpenAnchoredHudMenu(anchorBtn, buildMenuFn)
    local dd = GetOrCreateHudBotDropDown()
    if UIDROPDOWNMENU_OPEN_MENU ~= dd and CloseDropDownMenus then
        CloseDropDownMenus()
    end
    local bottomY = anchorBtn.GetBottom and anchorBtn:GetBottom() or 0
    local opensUp = (bottomY < 220)
    if opensUp then
        dd.point = "BOTTOMLEFT"
        dd.relativePoint = "TOPLEFT"
    else
        dd.point = "TOPLEFT"
        dd.relativePoint = "BOTTOMLEFT"
    end
    UIDropDownMenu_Initialize(dd, buildMenuFn, "MENU")
    ToggleDropDownMenu(1, nil, dd, anchorBtn, 0, opensUp and 4 or -4)

    local list1 = _G.DropDownList1
    if UIDROPDOWNMENU_OPEN_MENU == dd and list1 and list1:IsShown() then
        hudMenuAnchorBtn = anchorBtn
        hudMenuMouseWasDown = IsMouseButtonDown and (
            IsMouseButtonDown("LeftButton")
            or IsMouseButtonDown("RightButton")
            or IsMouseButtonDown("MiddleButton")
        ) and true or false
        EnsureHudMenuWatcher():Show()
    else
        hudMenuAnchorBtn = nil
        hudMenuMouseWasDown = false
        if hudMenuWatcher then hudMenuWatcher:Hide() end
    end
end

local function OpenHudBotDropdown(anchorBtn, headerTitle, emptyWarnMsg, onSelectBot, directIfSingle, showProximity)
    local bots = DungeonBots.GetPartyBotsList and DungeonBots:GetPartyBotsList() or {}
    if #bots == 0 then
        if CloseDropDownMenus then CloseDropDownMenus() end
        DungeonBots:Warn(emptyWarnMsg)
        return
    end
    if directIfSingle and #bots == 1 then
        if CloseDropDownMenus then CloseDropDownMenus() end
        onSelectBot(bots[1].name)
        return
    end

    OpenAnchoredHudMenu(anchorBtn, function(self, level)
        local infoTitle = UIDropDownMenu_CreateInfo()
        infoTitle.text = headerTitle or "-- Elegir Bot --"
        infoTitle.isTitle = true
        infoTitle.notCheckable = true
        UIDropDownMenu_AddButton(infoTitle, level)

        for _, bot in ipairs(bots) do
            local info = UIDropDownMenu_CreateInfo()
            local c = (bot.classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[bot.classToken]) or { r = 1.0, g = 0.82, b = 0.0 }
            local hex = string.format("|cff%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
            local rowText = hex .. bot.name .. "|r"
            if showProximity and DungeonBots.GetBotProximityInfo then
                local prox = DungeonBots:GetBotProximityInfo(bot.name)
                if prox and prox.shortLabel then
                    rowText = rowText .. " " .. (prox.colorHex or "|cffaaaaaa") .. "(" .. prox.shortLabel .. ")|r"
                end
            end
            info.text = rowText
            info.notCheckable = true
            local chosenName = bot.name
            info.func = function()
                if CloseDropDownMenus then CloseDropDownMenus() end
                onSelectBot(chosenName)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end
DB_Internal.OpenPartyBotDropdown = OpenHudBotDropdown

local function AddHudMenuTitle(level, titleText)
    local info = UIDropDownMenu_CreateInfo()
    info.text = titleText
    info.isTitle = true
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)
end

local function AddHudMenuAction(level, text, checked, onClickFn)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    if checked == nil then
        info.notCheckable = true
    else
        info.checked = checked and true or false
    end
    info.func = function()
        if CloseDropDownMenus then CloseDropDownMenus() end
        onClickFn()
    end
    UIDropDownMenu_AddButton(info, level)
end

local function ApplyFormationCommand(formationId, labelText)
    if DungeonBotsDB then
        DungeonBotsDB.activeFormation = formationId
    end
    DungeonBots:SendPartyCommand("formation " .. formationId)
    DungeonBots:Print("Formación del grupo: |cff33d9ff" .. (labelText or formationId) .. "|r (/p formation " .. formationId .. ").")
end

local function ApplyDisperseSetting(yards)
    if yards and yards > 0 then
        if DungeonBotsDB then DungeonBotsDB.activeDisperse = yards end
        DungeonBots:SendPartyCommand("disperse set " .. yards)
        DungeonBots:Print("Disperse activado: separación mínima de |cffc673ff" .. yards .. " metros|r entre bots.")
    else
        if DungeonBotsDB then DungeonBotsDB.activeDisperse = 0 end
        DungeonBots:SendPartyCommand("disperse disable")
        DungeonBots:Print("Disperse desactivado (los bots vuelven a agruparse normalmente).")
    end
end

local function ApplyWaitForAttackSeconds(seconds)
    local secs = tonumber(seconds) or 0
    if DungeonBotsDB then DungeonBotsDB.waitAttackSeconds = secs end
    if secs > 0 then
        DungeonBots:SendPartyCommand("co +wait for attack")
        DungeonBots:SendPartyCommand("wait for attack time " .. secs)
        DungeonBots:Print("Espera de pull activada: los bots esperarán |cffffd200" .. secs .. " seg|r antes de atacar.")
    else
        DungeonBots:SendPartyCommand("wait for attack time 0")
        DungeonBots:SendPartyCommand("co -wait for attack")
        DungeonBots:Print("Espera de pull desactivada (|cff34c759atacar de inmediato|r).")
    end
end

local function HandleFormationActionClick(anchorBtn, action)
    if action.cmd then
        if CloseDropDownMenus then CloseDropDownMenus() end
        if action.formationId then
            ApplyFormationCommand(action.formationId, action.formationId)
        else
            DungeonBots:SendPartyCommand(action.cmd)
            if action.cmd == "move from group" then
                DungeonBots:Print("Orden enviada: |cff57d98cSepararse del grupo|r (/p move from group).")
            end
        end
        return
    end

    if action.actionKind == "formation_menu" then
        local activeForm = (DungeonBotsDB and DungeonBotsDB.activeFormation) or "chaos"
        local combatForm = (DungeonBotsDB and DungeonBotsDB.combatFormationActive) and true or false
        OpenAnchoredHudMenu(anchorBtn, function(_, level)
            AddHudMenuTitle(level, "-- Formaciones --")
            local list = {
                { id = "chaos",  label = "Chaos (Por defecto)" },
                { id = "shield", label = "Shield (Tanques delante, resto detrás)" },
                { id = "circle", label = "Circle (Rodear objetivo)" },
                { id = "near",   label = "Near (Quietos cerca)" },
                { id = "line",   label = "Line (En fila)" },
                { id = "queue",  label = "Queue (En cola)" },
                { id = "melee",  label = "Melee (Pegados al líder)" },
            }
            for _, f in ipairs(list) do
                AddHudMenuAction(level, f.label, activeForm == f.id, function()
                    ApplyFormationCommand(f.id, f.label)
                end)
            end
            AddHudMenuTitle(level, "-- Combate y Mapa --")
            AddHudMenuAction(level, "Mantener formación en combate (+combat formation)", combatForm, function()
                local nextVal = not combatForm
                if DungeonBotsDB then DungeonBotsDB.combatFormationActive = nextVal end
                DungeonBots:SendPartyCommand(nextVal and "co +combat formation" or "co -combat formation")
                DungeonBots:Print("Mantener formación en combate: " .. (nextVal and "|cff34c759Activado|r" or "|cffffb020Desactivado|r"))
            end)
            AddHudMenuAction(level, "Mostrar puntos en mapa (formation show)", nil, function()
                DungeonBots:SendPartyCommand("formation show")
            end)
            AddHudMenuAction(level, "Consultar formación actual (formation ?)", nil, function()
                DungeonBots:SendPartyCommand("formation ?")
            end)
        end)
    elseif action.actionKind == "disperse_menu" then
        local activeDisp = (DungeonBotsDB and DungeonBotsDB.activeDisperse) or 0
        OpenAnchoredHudMenu(anchorBtn, function(_, level)
            AddHudMenuTitle(level, "-- Disperse (Distancia mínima) --")
            AddHudMenuAction(level, "Dispersar 8 metros (Evitar cleaves)", activeDisp == 8, function()
                ApplyDisperseSetting(8)
            end)
            AddHudMenuAction(level, "Dispersar 12 metros (AoE / Bombas)", activeDisp == 12, function()
                ApplyDisperseSetting(12)
            end)
            AddHudMenuAction(level, "Dispersar 18 metros (Separación amplia)", activeDisp == 18, function()
                ApplyDisperseSetting(18)
            end)
            AddHudMenuAction(level, "Desactivar Disperse (Volver a juntarse)", activeDisp == 0, function()
                ApplyDisperseSetting(0)
            end)
        end)
    elseif action.actionKind == "pull_wait_menu" then
        local curWait = (DungeonBotsDB and DungeonBotsDB.waitAttackSeconds) or 0
        local isPassive = (DungeonBotsDB and DungeonBotsDB.passiveModeActive) and true or false
        OpenAnchoredHudMenu(anchorBtn, function(_, level)
            AddHudMenuTitle(level, "-- Espera antes de atacar --")
            AddHudMenuAction(level, "Esperar 3 seg (Pull rápido)", curWait == 3, function()
                ApplyWaitForAttackSeconds(3)
            end)
            AddHudMenuAction(level, "Esperar 5 seg (Recomendado mazmorra)", curWait == 5, function()
                ApplyWaitForAttackSeconds(5)
            end)
            AddHudMenuAction(level, "Esperar 8 seg (Pull lento / LoS)", curWait == 8, function()
                ApplyWaitForAttackSeconds(8)
            end)
            AddHudMenuAction(level, "Sin espera / Atacar ya (0 seg)", curWait == 0, function()
                ApplyWaitForAttackSeconds(0)
            end)
            AddHudMenuTitle(level, "-- Control de Pull y Pasivo --")
            AddHudMenuAction(level, "Pull hacia atrás (pull back)", nil, function()
                DungeonBots:SendPartyCommand("pull back")
                DungeonBots:Print("Orden enviada: |cffff9e26Pull hacia atrás|r (/p pull back).")
            end)
            AddHudMenuAction(level, "Solo Tanque ataca mi target (tank attack)", nil, function()
                DungeonBots:SendPartyCommand("tank attack")
                DungeonBots:Print("Orden enviada: |cffff9e26Solo el tanque ataca tu objetivo|r (/p tank attack).")
            end)
            AddHudMenuAction(level, "Modo Pasivo (No atacar / para skips)", isPassive, function()
                local nextPassive = not isPassive
                if DungeonBotsDB then DungeonBotsDB.passiveModeActive = nextPassive end
                DungeonBots:SendPartyCommand(nextPassive and "co +passive" or "co -passive")
                DungeonBots:Print("Modo Pasivo de bots: " .. (nextPassive and "|cffff3b30ACTIVADO (no atacarán)|r" or "|cff34c759DESACTIVADO (combate normal)|r"))
            end)
        end)
    end
end

local function HandleHudTalkClick(anchorBtn)
    if DungeonBots.HasValidNpcTarget and not DungeonBots:HasValidNpcTarget() then
        PlaySound("igQuestFailed")
        DungeonBots:Warn("Selecciona primero un PNJ válido (los bots no cuentan).")
        return
    end
    OpenHudBotDropdown(
        anchorBtn,
        "-- Elegir Bot --",
        "No hay bots detectados en el grupo para hablar con el PNJ.",
        function(chosenName)
            DungeonBots:SendTalkCommand(chosenName, "talk")
        end,
        true,
        true
    )
end

local function HandleUtilActionClick(anchorBtn, action)
    if action.actionKind == "talk" then
        HandleHudTalkClick(anchorBtn)
    elseif action.actionKind == "party_tab" then
        if CloseDropDownMenus then CloseDropDownMenus() end
        if DungeonBots.OpenTab then
            DungeonBots:OpenTab(2)
        end
    elseif action.actionKind == "inventory" then
        OpenHudBotDropdown(
            anchorBtn,
            "-- Elegir Bot (Inventario) --",
            "No hay bots detectados en el grupo para abrir su inventario.",
            function(chosenName)
                if DungeonBots.QueryBotInventory then
                    DungeonBots:QueryBotInventory(chosenName)
                end
            end,
            true
        )
    elseif action.actionKind == "spells" then
        OpenHudBotDropdown(
            anchorBtn,
            "-- Información del Personaje --",
            "No hay bots detectados en el grupo para ver su información.",
            function(chosenName)
                if DungeonBots.QueryBotSpells then
                    DungeonBots:QueryBotSpells(chosenName, "gear", "", false)
                end
            end,
            true,
            true
        )
    elseif action.actionKind == "quests" then
        OpenHudBotDropdown(
            anchorBtn,
            "-- Elegir Bot (Misiones) --",
            "No hay bots detectados en el grupo para ver sus misiones.",
            function(chosenName)
                if DungeonBots.QueryQuests then
                    DungeonBots:QueryQuests(chosenName)
                end
            end,
            true
        )
    end
end

function DungeonBots:IsInFiveManDungeon()
    local inInstance, instanceType = IsInInstance()
    return (inInstance and instanceType == "party") and true or false
end

function DungeonBots:UpdateHUDTalkButtonState()
    if not hudTalkBtn then return end
    local canTalk = (DungeonBots.HasValidNpcTarget and DungeonBots:HasValidNpcTarget()) and true or false
    local c = (hudTalkBtn.actionDef and hudTalkBtn.actionDef.color) or { 0.2, 0.8, 1.0 }
    -- Mantener siempre su aspecto de color normal y habilitado para hover/clic
    hudTalkBtn:Enable()
    hudTalkBtn.isTalkReady = canTalk
    hudTalkBtn:SetAlpha(1.0)
    if hudTalkBtn.icon then
        hudTalkBtn.icon:SetDesaturated(false)
        hudTalkBtn.icon:SetVertexColor(1, 1, 1, 1)
    end
    hudTalkBtn:SetBackdropBorderColor(c[1], c[2], c[3], 0.85)
    if hudTalkBtn.highlightTex then
        hudTalkBtn.highlightTex:Show()
    end
    if not canTalk and hudBotDropDown and UIDROPDOWNMENU_OPEN_MENU == hudBotDropDown and CloseDropDownMenus then
        CloseDropDownMenus()
    end
end

local function ApplyBarVisibility(barFrame, visibleKey)
    if not barFrame then return false end
    if DungeonBotsDB and DungeonBotsDB[visibleKey] == false then
        barFrame:Hide()
        return false
    end
    local onlyInDungeon = (not DungeonBotsDB) or (DungeonBotsDB.hudOnlyInDungeon ~= false)
    if onlyInDungeon and not DungeonBots:IsInFiveManDungeon() then
        barFrame:Hide()
        return false
    end
    barFrame:Show()
    return true
end

function DungeonBots:UpdateHUDVisibility()
    ApplyBarVisibility(hudFrame, "hudVisible")
    if ApplyBarVisibility(utilHudFrame, "utilHudVisible") then
        DungeonBots:UpdateHUDTalkButtonState()
    end
    ApplyBarVisibility(formHudFrame, "formHudVisible")
end

function DungeonBots:IsHUDLocked()
    return (DungeonBotsDB and DungeonBotsDB.hudLocked) and true or false
end

function DungeonBots:SetHUDLocked(locked, silent)
    local isLocked = locked and true or false
    if DungeonBotsDB then
        DungeonBotsDB.hudLocked = isLocked
        DungeonBotsDB.utilHudLocked = isLocked
        DungeonBotsDB.formHudLocked = isLocked
    end
    if DungeonBots.UpdateHUDLockButtonState then
        DungeonBots:UpdateHUDLockButtonState()
    end
    if not silent then
        if isLocked then
            DungeonBots:Print("Barras flotantes: |cff9d9d9dBloqueadas|r (fijadas en su posición).")
        else
            DungeonBots:Print("Barras flotantes: |cff34c759Desbloqueadas|r (puedes mover todas las barras).")
        end
    end
end

function DungeonBots:ToggleHUDLock()
    DungeonBots:SetHUDLocked(not DungeonBots:IsHUDLocked(), false)
end

local function CreateFloatingToolbar(cfg)
    local actions = cfg.actions or {}
    local btnSize = 34
    local spacing = 4
    local startX = 8
    local rightPad = cfg.showMainPanelBtn and 28 or 8
    local totalWidth = startX + (#actions * (btnSize + spacing)) - spacing + rightPad

    local f = CreateFrame("Frame", cfg.frameName, UIParent)
    f:SetSize(totalWidth, 48)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    local pos = (DungeonBotsDB and DungeonBotsDB[cfg.posKey]) or cfg.defaultPos
    f:SetPoint(pos.point or "BOTTOM", UIParent, pos.point or "BOTTOM", pos.x or 0, pos.y or cfg.defaultPos.y)

    f:SetScript("OnDragStart", function(self)
        if not DungeonBots:IsHUDLocked() then
            self:StartMoving()
        end
    end)

    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        if DungeonBotsDB then
            DungeonBotsDB[cfg.posKey] = { point = point, x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
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

    for i, action in ipairs(actions) do
        local btn = CreateFrame("Button", cfg.btnPrefix .. i, f)
        btn:SetSize(btnSize, btnSize)
        btn:SetPoint("LEFT", f, "LEFT", startX + (i - 1) * (btnSize + spacing), 0)
        btn:RegisterForClicks("LeftButtonUp")

        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        btn:SetBackdropColor(0.06, 0.08, 0.12, 0.95)
        btn:SetBackdropBorderColor(action.color[1], action.color[2], action.color[3], 0.85)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        local pad = action.iconInset or 3
        icon:SetPoint("TOPLEFT", pad, -pad)
        icon:SetPoint("BOTTOMRIGHT", -pad, pad)
        icon:SetTexture(action.icon)
        if action.texCoord then
            icon:SetTexCoord(action.texCoord[1], action.texCoord[2], action.texCoord[3], action.texCoord[4])
        elseif action.fullTexCoord then
            icon:SetTexCoord(0, 1, 0, 1)
        else
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetPoint("TOPLEFT", 3, -3)
        highlight:SetPoint("BOTTOMRIGHT", -3, 3)
        highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlight:SetBlendMode("ADD")

        btn.icon = icon
        btn.highlightTex = highlight
        btn.actionDef = action
        if action.isTalkPicker then
            hudTalkBtn = btn
        end

        btn:SetScript("OnClick", function(self)
            if action.isTalkPicker and DungeonBots.HasValidNpcTarget and not DungeonBots:HasValidNpcTarget() then
                cfg.onActionClick(self, action)
                return
            end
            PlaySound("igMainMenuOptionCheckBoxOn")
            cfg.onActionClick(self, action)
        end)

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(action.title, 1, 1, 1)
            GameTooltip:AddLine(action.desc, 0.85, 0.85, 0.85, true)
            if action.isTalkPicker and DungeonBots.HasValidNpcTarget and not DungeonBots:HasValidNpcTarget() then
                GameTooltip:AddLine("Nota: Haz clic primero en un PNJ válido (los bots no cuentan).", 1.0, 0.72, 0.25, true)
            elseif action.tooltipCmd then
                GameTooltip:AddLine(action.tooltipCmd, 0.5, 0.8, 1.0)
            elseif action.cmd then
                GameTooltip:AddLine("Comando enviado: |cffffd200/p " .. action.cmd .. "|r", 0.5, 0.8, 1.0)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    if cfg.showMainPanelBtn then
        local mainBtn = CreateFrame("Button", "DungeonBots_HUDMainPanelBtn", f)
        mainBtn:SetSize(16, 16)
        mainBtn:SetPoint("RIGHT", f, "RIGHT", -6, 0)
        mainBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        local mainIcon = mainBtn:CreateTexture(nil, "ARTWORK")
        mainIcon:SetAllPoints()
        mainIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
        mainIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        mainBtn.icon = mainIcon
        f.mainPanelBtn = mainBtn

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
    end

    return f
end

function DungeonBots:InitHUD()
    if DungeonBotsDB then
        local locked = DungeonBots:IsHUDLocked()
        DungeonBotsDB.hudLocked = locked
        DungeonBotsDB.utilHudLocked = locked
        DungeonBotsDB.formHudLocked = locked
    end

    if not hudFrame then
        hudFrame = CreateFloatingToolbar({
            frameName = "DungeonBots_HUDFrame",
            posKey = "hudPosition",
            defaultPos = { point = "BOTTOM", x = 0, y = 140 },
            actions = TACTICAL_ACTIONS,
            btnPrefix = "DungeonBots_HUDExtBtn_",
            showMainPanelBtn = true,
            onActionClick = function(_, action)
                DungeonBots:SendPartyCommand(action.cmd)
            end,
        })
        DungeonBots.hudFrame = hudFrame
    end

    if not utilHudFrame then
        utilHudFrame = CreateFloatingToolbar({
            frameName = "DungeonBots_UtilHUDFrame",
            posKey = "utilHudPosition",
            defaultPos = { point = "BOTTOM", x = 0, y = 194 },
            actions = UTIL_ACTIONS,
            btnPrefix = "DungeonBots_UtilExtBtn_",
            showMainPanelBtn = false,
            onActionClick = function(btn, action)
                HandleUtilActionClick(btn, action)
            end,
        })
        DungeonBots.utilHudFrame = utilHudFrame
    end

    if not formHudFrame then
        formHudFrame = CreateFloatingToolbar({
            frameName = "DungeonBots_FormHUDFrame",
            posKey = "formHudPosition",
            defaultPos = { point = "BOTTOM", x = 0, y = 248 },
            actions = FORMATION_ACTIONS,
            btnPrefix = "DungeonBots_FormExtBtn_",
            showMainPanelBtn = false,
            onActionClick = function(btn, action)
                HandleFormationActionClick(btn, action)
            end,
        })
        DungeonBots.formHudFrame = formHudFrame
    end

    DungeonBots:UpdateHUDTalkButtonState()
    DungeonBots:UpdateHUDVisibility()
    if DungeonBots.UpdateHUDLockButtonState then
        DungeonBots:UpdateHUDLockButtonState()
    end
end

function DungeonBots:ResetHUDPositions()
    if not DungeonBotsDB then return end
    DungeonBotsDB.hudPosition = { point = "BOTTOM", x = 0, y = 140 }
    DungeonBotsDB.utilHudPosition = { point = "BOTTOM", x = 0, y = 194 }
    DungeonBotsDB.formHudPosition = { point = "BOTTOM", x = 0, y = 248 }
    if hudFrame then
        hudFrame:ClearAllPoints()
        hudFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 140)
    end
    if utilHudFrame then
        utilHudFrame:ClearAllPoints()
        utilHudFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 194)
    end
    if formHudFrame then
        formHudFrame:ClearAllPoints()
        formHudFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 248)
    end
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
            DungeonBots:Print("HUD Táctico activado (aparecerá automáticamente al entrar a una mazmorra de 5 jugadores). Puedes cambiar esto en Configuración (el engranaje).")
        end
    end
    if DungeonBots.UpdateSettingsDialog then
        DungeonBots:UpdateSettingsDialog()
    end
end
