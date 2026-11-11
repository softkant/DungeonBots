-- =========================================================================
-- DungeonBots.lua: Núcleo del Addon, Comunicación y Control de Bots
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.VERSION = "1.0.0"

-- Configuración por defecto
local DEFAULT_CONFIG = {
    autoInvite = true,
    hudLocked = false,
    hudScale = 1.0,
    hudVisible = true,
    hudOnlyInDungeon = true,
    hudPosition = { point = "BOTTOM", x = 0, y = 140 },
    minimapAngle = 195,
    lastWhisperLog = {},
    knownBots = {},
    botHistory = {},
    botSpecs = {},
    botActiveSpec = {},
}

DungeonBots.botSpecs = {}

-- Función para obtener icono oficial de Raza y Género
function DungeonBots:GetRaceIcon(unit)
    if not UnitExists(unit) then
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    local race, enRace = UnitRace(unit)
    if not enRace or enRace == "" then
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    -- Ajuste para No-Muertos (Scourge en WoW)
    if enRace == "Scourge" then
        enRace = "Undead"
    end

    local sex = UnitSex(unit)
    local gender = (sex == 3) and "Female" or "Male"
    return string.format("Interface\\Icons\\Achievement_Character_%s_%s", enRace, gender)
end

-- Clases soportadas para .playerbots bot addclass [clase]
DungeonBots.CLASSES = {
    { id = "warrior", name = "Guerrero", class = "WARRIOR", icon = "Interface\\Icons\\Ability_Warrior_OffensiveStance" },
    { id = "paladin", name = "Paladín", class = "PALADIN", icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
    { id = "hunter",  name = "Cazador",  class = "HUNTER",  icon = "Interface\\Icons\\INV_Weapon_Bow_08" },
    { id = "rogue",   name = "Pícaro",   class = "ROGUE",   icon = "Interface\\Icons\\Ability_Stealth" },
    { id = "priest",  name = "Sacerdote",class = "PRIEST",  icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
    { id = "dk",      name = "C. de la Muerte", class = "DEATHKNIGHT", icon = "Interface\\Icons\\Spell_Deathknight_ClassIcon" },
    { id = "shaman",  name = "Chamán",   class = "SHAMAN",  icon = "Interface\\Icons\\Spell_Fire_FlameShock" },
    { id = "mage",    name = "Mago",     class = "MAGE",    icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    { id = "warlock", name = "Brujo",    class = "WARLOCK", icon = "Interface\\Icons\\Spell_Nature_Drowsy" },
    { id = "druid",   name = "Druida",   class = "DRUID",   icon = "Interface\\Icons\\Ability_Druid_Maul" },
}

-- Ramas de talentos estándar por clase (para talents spec [rama])
DungeonBots.SPECS = {
    WARRIOR = {
        { id = "prot", name = "Protección (Tanque)", role = "TANK", icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance" },
        { id = "fury", name = "Furia (DPS)", role = "DPS", icon = "Interface\\Icons\\Ability_Warrior_InnerRage" },
        { id = "arms", name = "Armas (DPS)", role = "DPS", icon = "Interface\\Icons\\Ability_Warrior_SavageBlow" },
    },
    PALADIN = {
        { id = "prot", name = "Protección (Tanque)", role = "TANK", icon = "Interface\\Icons\\Spell_Holy_DevotionAura" },
        { id = "holy", name = "Sagrado (Healer)", role = "HEALER", icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
        { id = "ret",  name = "Reprensión (DPS)", role = "DPS", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight" },
    },
    DEATHKNIGHT = {
        { id = "blood", name = "Sangre (Tanque/DPS)", role = "TANK", icon = "Interface\\Icons\\Spell_Deathknight_BloodPresence" },
        { id = "frost", name = "Escarcha (DPS/Tanque)", role = "DPS", icon = "Interface\\Icons\\Spell_Deathknight_FrostPresence" },
        { id = "unholy",name = "Profano (DPS)", role = "DPS", icon = "Interface\\Icons\\Spell_Deathknight_UnholyPresence" },
    },
    PRIEST = {
        { id = "holy",   name = "Sagrado (Healer)", role = "HEALER", icon = "Interface\\Icons\\Spell_Holy_GuardianSpirit" },
        { id = "disc",   name = "Disciplina (Healer)", role = "HEALER", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
        { id = "shadow", name = "Sombras (DPS)", role = "DPS", icon = "Interface\\Icons\\Spell_Shadow_Shadowform" },
    },
    DRUID = {
        { id = "feral",   name = "Feral (Tanque/DPS)", role = "TANK", icon = "Interface\\Icons\\Ability_Racial_BearForm" },
        { id = "resto",   name = "Restauración (Healer)", role = "HEALER", icon = "Interface\\Icons\\Spell_Nature_HealingTouch" },
        { id = "balance", name = "Equilibrio (DPS Caster)", role = "DPS", icon = "Interface\\Icons\\Spell_Nature_Starfall" },
    },
    SHAMAN = {
        { id = "resto", name = "Restauración (Healer)", role = "HEALER", icon = "Interface\\Icons\\Spell_Nature_MagicImmunity" },
        { id = "elem",  name = "Elemental (DPS Caster)", role = "DPS", icon = "Interface\\Icons\\Spell_Nature_Lightning" },
        { id = "enh",   name = "Mejora (DPS Melee)", role = "DPS", icon = "Interface\\Icons\\Spell_Nature_LightningShield" },
    },
    MAGE = {
        { id = "arcane", name = "Arcano (DPS)", role = "DPS", icon = "Interface\\Icons\\Spell_Nature_WispSplode" },
        { id = "fire",   name = "Fuego (DPS)", role = "DPS", icon = "Interface\\Icons\\Spell_Fire_FlameBolt" },
        { id = "frost",  name = "Escarcha (DPS)", role = "DPS", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02" },
    },
    WARLOCK = {
        { id = "afflic", name = "Aflicción (DPS)", role = "DPS", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil" },
        { id = "demo",   name = "Demonología (DPS)", role = "DPS", icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis" },
        { id = "destro", name = "Destrucción (DPS)", role = "DPS", icon = "Interface\\Icons\\Spell_Shadow_RainOfFire" },
    },
    HUNTER = {
        { id = "mark",  name = "Puntería (DPS)", role = "DPS", icon = "Interface\\Icons\\Ability_Marksmanship" },
        { id = "surv",  name = "Supervivencia (DPS)", role = "DPS", icon = "Interface\\Icons\\Ability_Hunter_Camouflage" },
        { id = "beast", name = "Bestias (DPS)", role = "DPS", icon = "Interface\\Icons\\Ability_Hunter_BeastTaming" },
    },
    ROGUE = {
        { id = "combat", name = "Combate (DPS)", role = "DPS", icon = "Interface\\Icons\\Ability_BackStab" },
        { id = "assas",  name = "Asesinato (DPS)", role = "DPS", icon = "Interface\\Icons\\Ability_Rogue_Eviscerate" },
        { id = "subt",   name = "Sutileza (DPS)", role = "DPS", icon = "Interface\\Icons\\Ability_Stealth" },
    },
}

-- Ramas predeterminadas estándar de AzerothCore (mod-playerbots) por clase
DungeonBots.DEFAULT_CLASS_SPECS = {
    MAGE = { "arcane pve", "fire pve", "frost pve", "frostfire pve", "arcane pvp", "fire pvp", "frost pvp" },
    HUNTER = { "beastmastery pve", "marksmanship pve", "survival pve", "beastmastery pvp", "marksmanship pvp", "survival pvp" },
    PALADIN = { "protection pve", "holy pve", "retribution pve", "protection pvp", "holy pvp", "retribution pvp" },
    PRIEST = { "holy pve", "discipline pve", "shadow pve", "holy pvp", "discipline pvp", "shadow pvp" },
    WARRIOR = { "protection pve", "arms pve", "fury pve", "protection pvp", "arms pvp", "fury pvp" },
    DEATHKNIGHT = { "blood pve", "frost pve", "unholy pve", "blood pvp", "frost pvp", "unholy pvp" },
    ROGUE = { "combat pve", "assassination pve", "subtlety pve", "combat pvp", "assassination pvp", "subtlety pvp" },
    WARLOCK = { "affliction pve", "demonology pve", "destruction pve", "affliction pvp", "demonology pvp", "destruction pvp" },
    SHAMAN = { "restoration pve", "elemental pve", "enhancement pve", "restoration pvp", "elemental pvp", "enhancement pvp" },
    DRUID = { "feral pve", "balance pve", "restoration pve", "feral pvp", "balance pvp", "restoration pvp" },
}

-- Composiciones rápidas predeterminadas (1-click party)
DungeonBots.PRESETS = {
    {
        name = "Grupo Estándar",
        desc = "Paladín (Tank), Sacerdote (Heal), Mago, Cazador, DK",
        classes = { "paladin", "priest", "mage", "hunter", "dk" }
    },
    {
        name = "Fuerza Bruta (Melee)",
        desc = "Guerrero (Tank), Paladín (Heal), DK, Pícaro, Chamán",
        classes = { "warrior", "paladin", "dk", "rogue", "shaman" }
    },
    {
        name = "Casters & Rango",
        desc = "Druida (Tank), Chamán (Heal), Mago, Brujo, Cazador",
        classes = { "druid", "shaman", "mage", "warlock", "hunter" }
    },
}

-- Estado interno
DungeonBots.activeBots = {}
DungeonBots.confirmedBots = {}
DungeonBots.pendingScan = {}
DungeonBots.recentBots = {}
DungeonBots.recentInvites = {}
DungeonBots.pendingClassSummons = {}
DungeonBots.sessionQueriedBots = {}
DungeonBots.pendingSpecReset = {}
DungeonBots.pendingListReset = {}
DungeonBots.lastDetectedTriplet = {}
DungeonBots.lastDetectedTree = {}
DungeonBots.liveTreePoints = {}
DungeonBots.botSpecTriplets = {}
DungeonBots.dalaranTimeRemaining = 0
DungeonBots.isDalaranTimerRunning = false

local CLASS_TOKEN_BY_ID = {}
for _, cls in ipairs(DungeonBots.CLASSES) do
    CLASS_TOKEN_BY_ID[cls.id] = cls.class
end

-- =========================================================================
-- Sistema de Detección e Identificación de Bots vs Jugadores
-- =========================================================================
function DungeonBots:RegisterBot(name, isBot)
    if not name or name == "" then return end
    if not DungeonBotsDB then DungeonBotsDB = {} end
    if not DungeonBotsDB.knownBots then DungeonBotsDB.knownBots = {} end
    if isBot == nil then
        DungeonBotsDB.knownBots[name] = nil
    else
        DungeonBotsDB.knownBots[name] = (isBot == true)
    end
end

function DungeonBots:IsBot(name)
    if not name or name == "" then return false end
    if not DungeonBotsDB or not DungeonBotsDB.knownBots then return nil end
    return DungeonBotsDB.knownBots[name]
end

local function NowTime()
    return (GetTime and GetTime()) or 0
end

local function PrunePendingClassSummons()
    local now = NowTime()
    local list = DungeonBots.pendingClassSummons
    for i = #list, 1, -1 do
        if not list[i] or (list[i].expiresAt or 0) <= now then
            table.remove(list, i)
        end
    end
end

function DungeonBots:CanInviteToParty()
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        return false
    end
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if numParty >= 4 then
        return false
    end
    return (numParty == 0 or (IsPartyLeader and IsPartyLeader()))
end

function DungeonBots:MarkRecentBot(name, durationSeconds)
    if not name or name == "" or name == UnitName("player") then return end
    DungeonBots.recentBots[name] = NowTime() + (durationSeconds or 120)
end

function DungeonBots:IsRecentBot(name)
    if not name or name == "" then return false end
    local expiresAt = DungeonBots.recentBots and DungeonBots.recentBots[name]
    if not expiresAt then return false end
    if expiresAt <= NowTime() then
        DungeonBots.recentBots[name] = nil
        return false
    end
    return true
end

function DungeonBots:IsInHistory(name)
    if not name or name == "" then return false end
    return (DungeonBotsDB and DungeonBotsDB.botHistory and DungeonBotsDB.botHistory[name] ~= nil) and true or false
end

function DungeonBots:MarkPendingClassSummon(classId)
    PrunePendingClassSummons()
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if (GetNumRaidMembers and GetNumRaidMembers() > 0) or numParty >= 4 then
        return false
    end
    if (numParty + #DungeonBots.pendingClassSummons) >= 4 then
        return false
    end
    table.insert(DungeonBots.pendingClassSummons, {
        classId = classId,
        classToken = CLASS_TOKEN_BY_ID[classId],
        expiresAt = NowTime() + 45,
    })
    return true
end

function DungeonBots:GetPendingClassSummonCount()
    PrunePendingClassSummons()
    return #DungeonBots.pendingClassSummons
end

function DungeonBots:HasPendingClassSummon()
    PrunePendingClassSummons()
    return (#DungeonBots.pendingClassSummons > 0)
end

function DungeonBots:ConsumePendingClassSummon(expectedClassToken)
    PrunePendingClassSummons()
    local list = DungeonBots.pendingClassSummons
    if #list == 0 then return nil end

    if expectedClassToken and expectedClassToken ~= "" then
        for i, item in ipairs(list) do
            if not item.classToken or item.classToken == expectedClassToken then
                table.remove(list, i)
                return item
            end
        end
        return nil
    end

    return table.remove(list, 1)
end

function DungeonBots:HasPendingScan(name)
    if not name or name == "" then return false end
    local val = DungeonBots.pendingScan and DungeonBots.pendingScan[name]
    if not val then return false end
    if type(val) == "number" and val <= NowTime() then
        DungeonBots.pendingScan[name] = nil
        return false
    end
    return true
end

function DungeonBots:ShouldTreatAsBot(name)
    if not name or name == "" then return false end
    if UnitName and name == UnitName("player") then return false end
    local reg = DungeonBots:IsBot(name)
    if reg == false then return false end
    if DungeonBots.confirmedBots and DungeonBots.confirmedBots[name] then return true end
    if DungeonBots:IsRecentBot(name) then return true end
    if DungeonBots:IsInHistory(name) then return true end
    return false
end

function DungeonBots:ResolvePendingPartyBots()
    if not DungeonBots:HasPendingClassSummon() then return end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and name ~= UNKNOWNOBJECT and name ~= "Unknown" then
                if DungeonBots:IsBot(name) == nil and not DungeonBots:ShouldTreatAsBot(name) then
                    local _, classToken = UnitClass(unit)
                    if DungeonBots:ConsumePendingClassSummon(classToken) then
                        DungeonBots:MarkRecentBot(name, 120)
                        DungeonBots:RegisterBot(name, true)
                        DungeonBots:RecordBotHistory(name, classToken, nil, DungeonBots:GetRaceIcon(unit))
                    end
                end
            end
        end
    end
end

function DungeonBots:GetClassDisplayInfo(classToken)
    local color = (classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]) or { r = 1, g = 1, b = 1 }
    if classToken then
        for _, cls in ipairs(DungeonBots.CLASSES) do
            if cls.class == classToken then
                return cls.name, color, cls.icon
            end
        end
    end
    return classToken or "Desconocido", color, "Interface\\Icons\\INV_Misc_QuestionMark"
end

function DungeonBots:FindPartyUnitByName(name)
    if not name or name == "" then return nil end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitName(unit) == name then
            return unit
        end
    end
    return nil
end

function DungeonBots:ToggleUnitBotStatus(name)
    if not name or name == "" then return end
    local current = DungeonBots:ShouldTreatAsBot(name)
    local newState = not current
    DungeonBots:RegisterBot(name, newState)
    DungeonBots.pendingSpecReset[name] = nil
    if newState then
        DungeonBots.sessionQueriedBots[name] = nil
        DungeonBots.confirmedBots[name] = true
        DungeonBots:MarkRecentBot(name, 120)
        DungeonBots:Print("|cffffd200" .. name .. "|r marcado como: |cff00e5ff[ BOT ]|r.")
        if DungeonBots.RecordBotHistory then
            DungeonBots:RecordBotHistory(name)
        end
        if DungeonBots:FindPartyUnitByName(name) then
            DungeonBots.sessionQueriedBots[name] = true
            DungeonBots:QueryBotLiveInfo(name)
        end
    else
        DungeonBots.confirmedBots[name] = nil
        DungeonBots.recentBots[name] = nil
        DungeonBots.sessionQueriedBots[name] = nil
        DungeonBots:Print("|cffffd200" .. name .. "|r marcado como: |cffffb020[ JUGADOR HUMANO ]|r.")
        if DungeonBotsDB and DungeonBotsDB.botHistory then
            DungeonBotsDB.botHistory[name] = nil
        end
    end
    if DungeonBots.UpdateHistorySummary then
        DungeonBots:UpdateHistorySummary()
    end
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
end

-- Escaneo de miembros mediante consulta discreta por susurro
function DungeonBots:ScanPartyBots()
    local count = GetNumPartyMembers()
    if count == 0 then
        DungeonBots:Warn("No hay miembros en tu grupo para comprobar.")
        return
    end

    local checkedNames = {}
    local now = NowTime()
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and DungeonBots:IsBot(name) ~= false and not DungeonBots.confirmedBots[name] then
                DungeonBots.pendingScan[name] = now + 15
                DungeonBots:SendWhisperCommand(name, "follow info")
                table.insert(checkedNames, name)
            end
        end
    end

    if #checkedNames == 0 then
        DungeonBots:Print("Todos los bots actuales del grupo ya respondieron y están confirmados.")
    else
        DungeonBots:Print("Comprobando quién es bot en: |cffffd200" .. table.concat(checkedNames, ", ") .. "|r (los bots responderán automáticamente en el chat).")
    end
end

-- =========================================================================
-- Sistema de Notificaciones y Mensajes en Chat
-- =========================================================================
function DungeonBots:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[DungeonBots]|r " .. tostring(msg))
end

function DungeonBots:Warn(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[DungeonBots]|r |cffff3b30" .. tostring(msg) .. "|r")
end

-- =========================================================================
-- Despachador de Comandos
-- =========================================================================

-- Comandos con punto (.playerbots bot ...)
function DungeonBots:SendDotCommand(cmd)
    if not cmd or cmd == "" then return end
    SendChatMessage(cmd, "SAY")
end

-- Comandos de grupo (/p follow, /p summon, /p accept *, etc.)
function DungeonBots:SendPartyCommand(cmd)
    if not cmd or cmd == "" then return end
    if GetNumPartyMembers() > 0 then
        SendChatMessage(cmd, "PARTY")
    else
        -- Si no está en grupo, enviar a SAY por si está probando solo
        SendChatMessage(cmd, "SAY")
    end
end

-- Comandos por susurro a un bot (/w BotName talents spec ...)
function DungeonBots:SendWhisperCommand(botName, cmd)
    if not botName or botName == "" or not cmd or cmd == "" then return end
    SendChatMessage(cmd, "WHISPER", nil, botName)
end

-- =========================================================================
-- Funciones Operativas de Bots
-- =========================================================================

-- Invocar bot por clase
function DungeonBots:AddClass(classId)
    if not classId then return end
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if (GetNumRaidMembers and GetNumRaidMembers() > 0) or numParty >= 4 then
        DungeonBots:Warn("Tu grupo ya está completo (5/5); no se auto-invitará al bot.")
    else
        DungeonBots:MarkPendingClassSummon(classId)
    end
    DungeonBots:Print("Invocando bot de clase: |cffffd200" .. classId .. "|r...")
    DungeonBots:SendDotCommand(".playerbots bot addclass " .. classId)
end

-- Invocar bot por nombre
function DungeonBots:AddBot(botName)
    if not botName or botName == "" then return end
    DungeonBots:MarkRecentBot(botName, 120)
    DungeonBots:RegisterBot(botName, true)
    DungeonBots:RecordBotHistory(botName)
    DungeonBots:Print("Llamando a bot: |cffffd200" .. botName .. "|r...")
    DungeonBots:SendDotCommand(".playerbots bot add " .. botName)
end

-- Reinvocar a todos los bots del grupo (clave para entrar a mazmorra)
function DungeonBots:AddAllBots()
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and DungeonBots:ShouldTreatAsBot(name) then
                DungeonBots:MarkRecentBot(name, 60)
            end
        end
    end
    DungeonBots:Print("Reinvocando a todos los bots del grupo...")
    DungeonBots:SendDotCommand(".playerbots bot add *")
    -- Pequeño delay sugerido para que carguen antes del summon
    DungeonBots:SendPartyCommand("summon")
end

-- Remover un bot específico y sacarlo del grupo
function DungeonBots:RemoveBot(botName)
    if not botName or botName == "" then return end
    DungeonBots:Print("Despidiendo a bot: |cffffd200" .. botName .. "|r...")
    DungeonBots:SendDotCommand(".playerbots bot remove " .. botName)
    if GetNumPartyMembers() > 0 and IsPartyLeader() and DungeonBots:FindPartyUnitByName(botName) then
        UninviteUnit(botName)
    end
end

-- Remover a todos los bots y sacarlos del grupo (preservando humanos)
function DungeonBots:RemoveAllBots()
    DungeonBots:Print("Despidiendo a todos los bots del grupo...")
    DungeonBots:SendDotCommand(".playerbots bot remove *")

    if GetNumPartyMembers() > 0 then
        local botsToKick = {}
        local hasHuman = false
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                local name = UnitName(unit)
                if name and name ~= "" then
                    if not DungeonBots:ShouldTreatAsBot(name) then
                        hasHuman = true
                    else
                        table.insert(botsToKick, name)
                    end
                end
            end
        end

        if not hasHuman then
            LeaveParty()
        elseif IsPartyLeader() then
            for _, botName in ipairs(botsToKick) do
                UninviteUnit(botName)
            end
        end
    end
end

-- =========================================================================
-- Historial Persistente de Bots e Invitación Individual
-- =========================================================================
local pendingHistoryInvites = {}
local historyInviteFrame = CreateFrame("Frame")
historyInviteFrame:Hide()
historyInviteFrame:SetScript("OnUpdate", function(self, elapsed)
    local hasPending = false
    for botName, remaining in pairs(pendingHistoryInvites) do
        local nextTime = remaining - elapsed
        if nextTime <= 0 then
            pendingHistoryInvites[botName] = nil
            if not DungeonBots:FindPartyUnitByName(botName) and DungeonBots:CanInviteToParty() then
                DungeonBots.recentInvites[botName] = NowTime() + 3
                InviteUnit(botName)
            end
        else
            pendingHistoryInvites[botName] = nextTime
            hasPending = true
        end
    end
    if not hasPending then
        self:Hide()
    end
end)

function DungeonBots:CleanSpecText(specText)
    if not specText or specText == "" then return "" end
    local cleaned = string.gsub(specText, "%s*%([^%)]*%d[^%)]*%)", "")
    cleaned = string.gsub(cleaned, "^[%s:=]+", "")
    cleaned = string.gsub(cleaned, "^[Ii][Ss][%s:=]+", "")
    cleaned = string.gsub(cleaned, "^[Ee][Ss][%s:=]+", "")
    cleaned = string.gsub(cleaned, "^[%s:=]+", "")
    cleaned = string.gsub(cleaned, "^%s*(.-)%s*$", "%1")
    return cleaned
end

function DungeonBots:RecordBotHistory(name, classToken, specName, raceIcon)
    if not name or name == "" then return end
    if DungeonBots:IsBot(name) == false then return end
    if not DungeonBotsDB then DungeonBotsDB = {} end
    DungeonBotsDB.botHistory = DungeonBotsDB.botHistory or {}

    local unit = DungeonBots:FindPartyUnitByName(name)
    if unit then
        if not classToken or classToken == "" then
            local _, detectedClass = UnitClass(unit)
            classToken = detectedClass
        end
        if not raceIcon or raceIcon == "" then
            raceIcon = DungeonBots:GetRaceIcon(unit)
        end
    end

    local prev = DungeonBotsDB.botHistory[name] or {}
    local resolvedSpec = specName
    if not resolvedSpec or resolvedSpec == "" then
        resolvedSpec = (DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[name]) or prev.spec or ""
    end
    resolvedSpec = DungeonBots:CleanSpecText(resolvedSpec)

    local defaultQuestionIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
    local resolvedIcon = prev.raceIcon or defaultQuestionIcon
    if raceIcon and raceIcon ~= "" and raceIcon ~= defaultQuestionIcon then
        resolvedIcon = raceIcon
    end

    DungeonBotsDB.botHistory[name] = {
        name = name,
        class = (classToken and classToken ~= "" and classToken) or prev.class or "UNKNOWN",
        spec = resolvedSpec,
        raceIcon = resolvedIcon,
        lastSeen = (date and date("%d/%m %H:%M")) or (prev.lastSeen or ""),
        timestamp = (time and time()) or (prev.timestamp or 0),
    }
end

function DungeonBots:SyncPartyToHistory()
    if not DungeonBotsDB then DungeonBotsDB = {} end
    DungeonBotsDB.botHistory = DungeonBotsDB.botHistory or {}

    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and DungeonBots:ShouldTreatAsBot(name) then
                local _, classToken = UnitClass(unit)
                local raceIcon = DungeonBots:GetRaceIcon(unit)
                DungeonBots:RecordBotHistory(name, classToken, nil, raceIcon)
            end
        end
    end

    if DungeonBots.UpdateHistorySummary then
        DungeonBots:UpdateHistorySummary()
    end
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
end

function DungeonBots:GetBotHistoryCount()
    if not DungeonBotsDB or not DungeonBotsDB.botHistory then return 0 end
    local count = 0
    for _ in pairs(DungeonBotsDB.botHistory) do
        count = count + 1
    end
    return count
end

function DungeonBots:GetSortedBotHistory()
    local list = {}
    if not DungeonBotsDB or not DungeonBotsDB.botHistory then return list end
    for _, entry in pairs(DungeonBotsDB.botHistory) do
        if entry and entry.name then
            table.insert(list, entry)
        end
    end
    table.sort(list, function(a, b)
        local ta = a.timestamp or 0
        local tb = b.timestamp or 0
        if ta ~= tb then
            return ta > tb
        end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

function DungeonBots:RemoveFromHistory(botName)
    if not botName or not DungeonBotsDB or not DungeonBotsDB.botHistory then return end
    DungeonBotsDB.botHistory[botName] = nil
    if DungeonBotsDB.knownBots and DungeonBotsDB.knownBots[botName] == true then
        DungeonBotsDB.knownBots[botName] = nil
    end
    if DungeonBotsDB.botActiveSpec then
        DungeonBotsDB.botActiveSpec[botName] = nil
    end
    if DungeonBotsDB.botSpecs then
        DungeonBotsDB.botSpecs[botName] = nil
    end
    if DungeonBots.botSpecs then
        DungeonBots.botSpecs[botName] = nil
    end
    DungeonBots.confirmedBots[botName] = nil
    DungeonBots.recentBots[botName] = nil
    if DungeonBots.UpdateHistorySummary then
        DungeonBots:UpdateHistorySummary()
    end
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
end

function DungeonBots:ClearBotHistory()
    if not DungeonBotsDB then DungeonBotsDB = {} end
    DungeonBotsDB.botHistory = {}
    DungeonBotsDB.botActiveSpec = {}
    DungeonBotsDB.botSpecs = {}
    DungeonBotsDB.historyMigrated = true
    DungeonBots.botSpecs = DungeonBotsDB.botSpecs
    if DungeonBotsDB.knownBots then
        for name, isBot in pairs(DungeonBotsDB.knownBots) do
            if isBot == true then
                DungeonBotsDB.knownBots[name] = nil
            end
        end
    end
    DungeonBots.confirmedBots = {}
    DungeonBots.recentBots = {}
    if DungeonBots.UpdateHistorySummary then
        DungeonBots:UpdateHistorySummary()
    end
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
    DungeonBots:Print("Historial de bots limpiado.")
end

function DungeonBots:SummonAndInviteHistoryBot(botName)
    if not botName or botName == "" then return end
    if DungeonBots:FindPartyUnitByName(botName) then
        DungeonBots:Print("|cffffd200" .. botName .. "|r ya forma parte de tu grupo actual.")
        return
    end
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if (GetNumRaidMembers and GetNumRaidMembers() > 0) or numParty >= 4 then
        DungeonBots:Warn("Tu grupo ya está lleno (5/5). No se puede invitar a |cffffd200" .. botName .. "|r.")
        return
    end
    if numParty > 0 and IsPartyLeader and not IsPartyLeader() then
        DungeonBots:Warn("Debes ser el líder del grupo para invitar a |cffffd200" .. botName .. "|r.")
        return
    end
    DungeonBots:AddBot(botName)
    pendingHistoryInvites[botName] = 1.0
    historyInviteFrame:Show()
end

-- Cambiar rama de talentos de un bot
function DungeonBots:SetBotSpec(botName, specId)
    if not botName or not specId then return end
    local cleanSpec = DungeonBots:CleanSpecText(specId)
    if cleanSpec == "" then cleanSpec = specId end
    if DungeonBotsDB then
        DungeonBotsDB.botActiveSpec = DungeonBotsDB.botActiveSpec or {}
        DungeonBotsDB.botActiveSpec[botName] = cleanSpec
    end
    DungeonBots:RecordBotHistory(botName, nil, cleanSpec, nil)
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
    DungeonBots:Print("Cambiando talentos de |cffffd200" .. botName .. "|r a |cff71d5ff" .. cleanSpec .. "|r...")
    DungeonBots:SendWhisperCommand(botName, "talents spec " .. cleanSpec)
end

local whisperQueue = {}
local nextWhisperAt = 0
local whisperQueueFrame = CreateFrame("Frame")
whisperQueueFrame:Hide()

local pendingJoinQueries = {}
local queryStates = {}
local joinQueryFrame = CreateFrame("Frame")
joinQueryFrame:Hide()

whisperQueueFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = NowTime()
    if #whisperQueue == 0 then
        self:Hide()
        return
    end
    if now >= nextWhisperAt then
        local item = table.remove(whisperQueue, 1)
        if item and item.botName and item.cmd and DungeonBots:FindPartyUnitByName(item.botName) then
            DungeonBots:SendWhisperCommand(item.botName, item.cmd)
            nextWhisperAt = now + 0.30
            local st = queryStates[item.botName]
            if st then
                if not st.retrySent then
                    st.retryAt = now + 4.0
                end
                st.timeoutAt = math.max(st.timeoutAt or 0, now + 8.5)
                joinQueryFrame:Show()
            end
        end
    end
end)

function DungeonBots:QueueWhisperCommand(botName, cmd, atFront)
    if not botName or botName == "" or not cmd or cmd == "" then return end
    for _, existing in ipairs(whisperQueue) do
        if existing.botName == botName and existing.cmd == cmd then
            return
        end
    end
    local entry = { botName = botName, cmd = cmd }
    if atFront then
        table.insert(whisperQueue, 1, entry)
    else
        table.insert(whisperQueue, entry)
    end
    whisperQueueFrame:Show()
end

local function RestorePreviousSpecOnTimeout(botName, prevSpec)
    if prevSpec and prevSpec ~= "" and DungeonBotsDB then
        DungeonBotsDB.botActiveSpec = DungeonBotsDB.botActiveSpec or {}
        if not DungeonBotsDB.botActiveSpec[botName] or DungeonBotsDB.botActiveSpec[botName] == "" then
            DungeonBotsDB.botActiveSpec[botName] = prevSpec
        end
    end
end

joinQueryFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = NowTime()
    local hasPending = false

    for botName, remaining in pairs(pendingJoinQueries) do
        local nextTime = remaining - elapsed
        if nextTime <= 0 then
            pendingJoinQueries[botName] = nil
            if DungeonBots:FindPartyUnitByName(botName) and DungeonBots:ShouldTreatAsBot(botName) then
                DungeonBots.sessionQueriedBots[botName] = true
                DungeonBots:QueryBotLiveInfo(botName)
            end
        else
            pendingJoinQueries[botName] = nextTime
            hasPending = true
        end
    end

    for botName, st in pairs(queryStates) do
        if not DungeonBots:FindPartyUnitByName(botName) then
            queryStates[botName] = nil
            DungeonBots.pendingSpecReset[botName] = nil
            DungeonBots.pendingListReset[botName] = nil
        elseif st.gotActiveSpec and st.gotSpecList then
            queryStates[botName] = nil
            DungeonBots.pendingSpecReset[botName] = nil
            DungeonBots.pendingListReset[botName] = nil
        elseif now >= (st.timeoutAt or 0) then
            queryStates[botName] = nil
            DungeonBots.pendingSpecReset[botName] = nil
            DungeonBots.pendingListReset[botName] = nil
            if not st.gotActiveSpec then
                RestorePreviousSpecOnTimeout(botName, st.prevSpec)
            end
            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
        else
            hasPending = true
            if not st.retrySent and now >= (st.retryAt or 0) then
                st.retrySent = true
                st.timeoutAt = now + 4.5
                if not st.gotSpecList then
                    DungeonBots:QueueWhisperCommand(botName, "talents spec list")
                end
                if not st.gotActiveSpec then
                    DungeonBots:QueueWhisperCommand(botName, "talents")
                end
            end
        end
    end

    if not hasPending then
        self:Hide()
    end
end)

local function StartTalentQuery(botName, announceText, atFront)
    if not botName or botName == "" then return end
    local prevSpec = (DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[botName])
        or (DungeonBotsDB and DungeonBotsDB.botHistory and DungeonBotsDB.botHistory[botName] and DungeonBotsDB.botHistory[botName].spec)
        or (queryStates[botName] and queryStates[botName].prevSpec)
        or nil

    DungeonBots.pendingSpecReset[botName] = true
    DungeonBots.pendingListReset[botName] = true
    DungeonBots.liveTreePoints[botName] = {}
    DungeonBots.botSpecTriplets[botName] = {}
    DungeonBots.lastDetectedTriplet[botName] = nil
    DungeonBots.lastDetectedTree[botName] = nil

    if DungeonBotsDB and DungeonBotsDB.botActiveSpec then
        DungeonBotsDB.botActiveSpec[botName] = nil
    end

    local now = NowTime()
    queryStates[botName] = {
        prevSpec = prevSpec,
        gotSpecList = false,
        gotActiveSpec = false,
        retrySent = false,
        retryAt = now + 4.5,
        timeoutAt = now + 9.0,
    }
    joinQueryFrame:Show()

    DungeonBots:Print(announceText .. " |cffffd200" .. botName .. "|r...")
    if atFront then
        DungeonBots:QueueWhisperCommand(botName, "talents", true)
        DungeonBots:QueueWhisperCommand(botName, "talents spec list", true)
    else
        DungeonBots:QueueWhisperCommand(botName, "talents spec list")
        DungeonBots:QueueWhisperCommand(botName, "talents")
    end

    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
end

function DungeonBots:QueryBotLiveInfo(botName)
    if not botName or botName == "" then return end
    if not DungeonBots:ShouldTreatAsBot(botName) then return end
    StartTalentQuery(botName, "Consultando talentos en vivo de", false)
end

function DungeonBots:CheckPartyForNewBots()
    DungeonBots:ResolvePendingPartyBots()
    local currentMembers = {}
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and name ~= UNKNOWNOBJECT and name ~= "Unknown" then
                currentMembers[name] = true
                if DungeonBots:ShouldTreatAsBot(name) and not DungeonBots.sessionQueriedBots[name] and not pendingJoinQueries[name] then
                    DungeonBots.pendingSpecReset[name] = true
                    pendingJoinQueries[name] = 1.2
                    joinQueryFrame:Show()
                end
            end
        end
    end

    -- Si un miembro sale del grupo, volver a consultarlo si se invita nuevamente
    for queriedName in pairs(DungeonBots.sessionQueriedBots) do
        if not currentMembers[queriedName] then
            DungeonBots.sessionQueriedBots[queriedName] = nil
        end
    end
    for pendingName in pairs(pendingJoinQueries) do
        if not currentMembers[pendingName] then
            pendingJoinQueries[pendingName] = nil
        end
    end
end

-- Pedir lista de ramas y talentos activos al bot
function DungeonBots:QueryBotSpecs(botName)
    if not botName or botName == "" then return end
    StartTalentQuery(botName, "Consultando ramas disponibles de", true)
end

-- Adaptar equipo (autogear match)
function DungeonBots:AutogearMatch(botName)
    if not botName then return end
    DungeonBots:Print("Adaptando equipo a talentos para |cffffd200" .. botName .. "|r...")
    DungeonBots:SendWhisperCommand(botName, "autogear match")
end

-- Equipar ítems azules (autogear blue)
function DungeonBots:AutogearBlue(botName)
    if not botName then return end
    DungeonBots:Print("Equipando ítems azules a |cffffd200" .. botName .. "|r...")
    DungeonBots:SendWhisperCommand(botName, "autogear blue")
end

-- Ver misiones del bot
function DungeonBots:QueryQuests(botName)
    if not botName then return end
    DungeonBots:Print("Consultando misiones de |cffffd200" .. botName .. "|r...")
    DungeonBots:SendWhisperCommand(botName, "quests all")
end

-- =========================================================================
-- Asistente Dalaran y Cadena Forja/Foso/Cámaras
-- =========================================================================

-- Paso 1: Macro Dalaran
function DungeonBots:DalaranPrep()
    if not UnitExists("target") then
        DungeonBots:Warn("¡Atención! Selecciona primero al PNJ que da la misión en Dalaran.")
    end
    DungeonBots:Print("Ejecutando preparación en Dalaran (Summon + Aceptar misiones)...")
    DungeonBots:SendPartyCommand("summon")
    DungeonBots:SendPartyCommand("accept *")
    DungeonBots:StartDalaranTimer(60)
end

-- Paso 2: Reinvocar adentro de la mazmorra
function DungeonBots:DungeonReenter()
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and DungeonBots:ShouldTreatAsBot(name) then
                DungeonBots:MarkRecentBot(name, 60)
            end
        end
    end
    DungeonBots:Print("Reinvocando grupo dentro de la mazmorra...")
    DungeonBots:SendDotCommand(".playerbots bot add *")
    DungeonBots:SendPartyCommand("summon")
end

-- Paso 3: Entregar y aceptar siguiente misión
function DungeonBots:DungeonTurnInAndAccept()
    if not UnitExists("target") then
        DungeonBots:Warn("Selecciona al PNJ de la misión dentro de la mazmorra.")
    end
    DungeonBots:Print("Entregando y aceptando misiones del PNJ seleccionado...")
    DungeonBots:SendPartyCommand("accept *")
end

-- =========================================================================
-- Temporizador de Dalaran (60s)
-- =========================================================================
local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

function DungeonBots:StartDalaranTimer(seconds)
    DungeonBots.dalaranTimeRemaining = seconds or 60
    DungeonBots.isDalaranTimerRunning = true
    timerFrame.lastUpdate = 0
    timerFrame:Show()
    PlaySound("RaidWarning")
    DungeonBots:Print("|cffff3b30¡Temporizador de Dalaran iniciado (60s)!|r Los bots desaparecerán al llegar a 0.")
    if DungeonBots.UpdateDalaranTimerUI then
        DungeonBots:UpdateDalaranTimerUI(DungeonBots.dalaranTimeRemaining)
    end
end

function DungeonBots:StopDalaranTimer()
    DungeonBots.isDalaranTimerRunning = false
    DungeonBots.dalaranTimeRemaining = 0
    timerFrame:Hide()
    if DungeonBots.UpdateDalaranTimerUI then
        DungeonBots:UpdateDalaranTimerUI(0)
    end
end

timerFrame:SetScript("OnUpdate", function(self, elapsed)
    self.lastUpdate = (self.lastUpdate or 0) + elapsed
    if self.lastUpdate >= 1.0 then
        self.lastUpdate = 0
        if DungeonBots.dalaranTimeRemaining > 0 then
            DungeonBots.dalaranTimeRemaining = DungeonBots.dalaranTimeRemaining - 1
            if DungeonBots.UpdateDalaranTimerUI then
                DungeonBots:UpdateDalaranTimerUI(DungeonBots.dalaranTimeRemaining)
            end
            if DungeonBots.dalaranTimeRemaining == 15 then
                PlaySound("RaidWarning")
                DungeonBots:Warn("¡Quedan 15 segundos antes de que los bots desaparezcan en Dalaran!")
            elseif DungeonBots.dalaranTimeRemaining == 0 then
                PlaySound("igQuestFailed")
                DungeonBots:Warn("¡Tiempo expirado! Los bots han desaparecido en Dalaran. Entra a Forja y pulsa 'Reinvocar en Mazmorra'.")
                DungeonBots:StopDalaranTimer()
            end
        else
            DungeonBots:StopDalaranTimer()
        end
    end
end)

-- =========================================================================
local TREE_ALIASES = {
    ["arcane"] = "arcane", ["arcano"] = "arcane",
    ["fire"] = "fire", ["fuego"] = "fire",
    ["frost"] = "frost", ["escarcha"] = "frost",
    ["frostfire"] = "frostfire",
    ["protection"] = "protection", ["proteccion"] = "protection", ["protección"] = "protection",
    ["holy"] = "holy", ["sagrado"] = "holy",
    ["retribution"] = "retribution", ["reprension"] = "retribution", ["reprensión"] = "retribution",
    ["discipline"] = "discipline", ["disciplina"] = "discipline",
    ["shadow"] = "shadow", ["sombras"] = "shadow",
    ["feral"] = "feral",
    ["balance"] = "balance", ["equilibrio"] = "balance",
    ["restoration"] = "restoration", ["restauracion"] = "restoration", ["restauración"] = "restoration",
    ["elemental"] = "elemental",
    ["enhancement"] = "enhancement", ["mejora"] = "enhancement",
    ["affliction"] = "affliction", ["afliccion"] = "affliction", ["aflicción"] = "affliction",
    ["demonology"] = "demonology", ["demonologia"] = "demonology", ["demonología"] = "demonology",
    ["destruction"] = "destruction", ["destruccion"] = "destruction", ["destrucción"] = "destruction",
    ["beastmastery"] = "beastmastery", ["beast mastery"] = "beastmastery", ["bestias"] = "beastmastery",
    ["marksmanship"] = "marksmanship", ["punteria"] = "marksmanship", ["puntería"] = "marksmanship",
    ["survival"] = "survival", ["supervivencia"] = "survival",
    ["combat"] = "combat", ["combate"] = "combat",
    ["assassination"] = "assassination", ["asesinato"] = "assassination",
    ["subtlety"] = "subtlety", ["sutileza"] = "subtlety",
    ["arms"] = "arms", ["armas"] = "arms",
    ["fury"] = "fury", ["furia"] = "fury",
    ["blood"] = "blood", ["sangre"] = "blood",
    ["unholy"] = "unholy", ["profano"] = "unholy",
}

local CLASS_TREE_BY_TAB = {
    WARRIOR     = { "arms", "fury", "protection" },
    PALADIN     = { "holy", "protection", "retribution" },
    HUNTER      = { "beastmastery", "marksmanship", "survival" },
    ROGUE       = { "assassination", "combat", "subtlety" },
    PRIEST      = { "discipline", "holy", "shadow" },
    DEATHKNIGHT = { "blood", "frost", "unholy" },
    SHAMAN      = { "elemental", "enhancement", "restoration" },
    MAGE        = { "arcane", "fire", "frost" },
    WARLOCK     = { "affliction", "demonology", "destruction" },
    DRUID       = { "balance", "feral", "restoration" },
}

local function StripWowFormatting(text)
    if not text or text == "" then return "" end
    local clean = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    clean = string.gsub(clean, "|r", "")
    clean = string.gsub(clean, "|H[^|]*|h(.-)|h", "%1")
    return clean
end

local function EscapeLuaPattern(str)
    return string.gsub(str or "", "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

local function StripSpecNoisePrefix(text)
    if not text or text == "" then return "" end
    local s = string.gsub(text, "^%s*(.-)%s*$", "%1")
    local colonPos = string.find(s, ":", 1, true)
    if colonPos then
        local head = string.lower(string.sub(s, 1, colonPos - 1))
        if string.find(head, "spec", 1, true)
            or string.find(head, "talent", 1, true)
            or string.find(head, "available", 1, true)
            or string.find(head, "rama", 1, true) then
            s = string.sub(s, colonPos + 1)
        end
    end
    local prefixes = {
        "available talent specs", "available specs", "available spec",
        "current talent spec", "current spec", "active spec",
        "my talent spec", "my spec", "using spec",
        "current talents", "my talents", "talents",
        "rama actual", "specs", "spec",
    }
    local changed = true
    while changed do
        changed = false
        s = string.gsub(s, "^[%s%*:>%-=]+", "")
        local ls = string.lower(s)
        for _, p in ipairs(prefixes) do
            if string.sub(ls, 1, #p) == p then
                local nextCh = string.sub(ls, #p + 1, #p + 1)
                if nextCh == "" or string.match(nextCh, "[%s:=%-]") then
                    s = string.sub(s, #p + 1)
                    changed = true
                    break
                end
            end
        end
    end
    s = string.gsub(s, "^[%s%*:>%-=]+", "")
    s = string.gsub(s, "^%s*(.-)%s*$", "%1")
    return s
end

local function ResolveTreeToSpec(botName, treeKey)
    local specs = DungeonBots.botSpecs and DungeonBots.botSpecs[botName]
    if (not specs or #specs == 0) then
        local unit = DungeonBots:FindPartyUnitByName(botName)
        if unit then
            local _, classToken = UnitClass(unit)
            if classToken and DungeonBots.DEFAULT_CLASS_SPECS then
                specs = DungeonBots.DEFAULT_CLASS_SPECS[classToken]
            end
        end
    end
    if specs and treeKey and treeKey ~= "" then
        local lowerKey = string.lower(treeKey)
        local prefixPat = "^" .. EscapeLuaPattern(lowerKey) .. "[%s_-]"
        for _, s in ipairs(specs) do
            local ls = string.lower(s)
            if (ls == lowerKey or string.match(ls, prefixPat)) and string.find(ls, "pve", 1, true) then
                return s
            end
        end
        for _, s in ipairs(specs) do
            local ls = string.lower(s)
            if ls == lowerKey or string.match(ls, prefixPat) then
                return s
            end
        end
        for _, s in ipairs(specs) do
            local ls = string.lower(s)
            if string.find(ls, lowerKey, 1, true) and string.find(ls, "pve", 1, true) then
                return s
            end
        end
        for _, s in ipairs(specs) do
            if string.find(string.lower(s), lowerKey, 1, true) then
                return s
            end
        end
    end
    return treeKey
end

function DungeonBots:CanonicalizeSpec(botName, specText)
    if not specText or specText == "" then return "" end
    local cleaned = DungeonBots:CleanSpecText(specText)
    if cleaned == "" then return "" end
    local lowerCleaned = string.lower(cleaned)
    local specs = DungeonBots.botSpecs and DungeonBots.botSpecs[botName]
    if (not specs or #specs == 0) then
        local unit = DungeonBots:FindPartyUnitByName(botName)
        if unit then
            local _, classToken = UnitClass(unit)
            if classToken and DungeonBots.DEFAULT_CLASS_SPECS then
                specs = DungeonBots.DEFAULT_CLASS_SPECS[classToken]
            end
        end
    end
    if specs then
        for _, s in ipairs(specs) do
            if string.lower(s) == lowerCleaned then
                return s
            end
        end
    end
    return cleaned
end

local function ExtractSpecCandidate(chunk)
    local body = StripSpecNoisePrefix(chunk)
    if body == "" then return nil end
    local parsed = string.match(body, "([%a][%a%s_-]*)%s*%(%s*%d+%s*[-/]%s*%d+%s*[-/]%s*%d+%s*%)")
    if not parsed then
        parsed = string.match(body, "([%a][%a%s_-]*%s+pv[ep])")
    end
    if not parsed then return nil end
    parsed = StripSpecNoisePrefix(parsed)
    parsed = string.gsub(parsed, "%s*%*+%s*$", "")
    parsed = DungeonBots:CleanSpecText(parsed)
    local lowerParsed = string.lower(parsed)
    if lowerParsed == "" or string.find(lowerParsed, "available", 1, true) then
        return nil
    end
    return parsed
end

local function ResolveTripletToSpec(botName, p1, p2, p3)
    local key = p1 .. "-" .. p2 .. "-" .. p3
    if DungeonBots.botSpecTriplets and DungeonBots.botSpecTriplets[botName] and DungeonBots.botSpecTriplets[botName][key] then
        return DungeonBots.botSpecTriplets[botName][key]
    end
    local unit = DungeonBots:FindPartyUnitByName(botName)
    if unit then
        local _, classToken = UnitClass(unit)
        local tabs = classToken and CLASS_TREE_BY_TAB[classToken]
        if tabs then
            local counts = { tonumber(p1) or 0, tonumber(p2) or 0, tonumber(p3) or 0 }
            local bestIdx, bestVal = 1, counts[1]
            for idx = 2, 3 do
                if counts[idx] > bestVal then
                    bestVal = counts[idx]
                    bestIdx = idx
                end
            end
            if bestVal > 0 then
                return ResolveTreeToSpec(botName, tabs[bestIdx])
            end
        end
    end
    return nil
end

local function ParseTalentWhisper(cleanSender, message)
    local foundAnySpec = false
    local detectedActiveSpec = nil

    DungeonBots.liveTreePoints[cleanSender] = DungeonBots.liveTreePoints[cleanSender] or {}
    DungeonBots.botSpecTriplets[cleanSender] = DungeonBots.botSpecTriplets[cleanSender] or {}

    for rawLine in string.gmatch(message or "", "[^\r\n]+") do
        local line = StripWowFormatting(rawLine)
        local lowerLine = string.lower(line)
        local isAvailableListLine = (string.find(lowerLine, "available", 1, true) ~= nil)

        local directActive = string.match(lowerLine, "current%s+talent%s+spec%s+is%s*[:=%s]*(.+)")
            or string.match(lowerLine, "current%s+talent%s+spec%s*[:=%s]+(.+)")
            or string.match(lowerLine, "current%s+spec%s+is%s*[:=%s]*(.+)")
            or string.match(lowerLine, "current%s+spec%s*[:=%s]+(.+)")
            or string.match(lowerLine, "active%s+spec%s*[:=%s]+(.+)")
            or string.match(lowerLine, "my%s+spec%s+is%s*[:=%s]*(.+)")
            or string.match(lowerLine, "using%s+spec%s*[:=%s]+(.+)")
            or string.match(lowerLine, "rama%s+actual%s*[:=%s]+(.+)")
            or string.match(lowerLine, "current%s+talents%s*[:=%s]+(.+)")
            or string.match(lowerLine, "^%s*spec%s*:%s*(.+)")
        if not directActive then
            local talentsRest = string.match(lowerLine, "^%s*talents%s*:%s*(.+)")
            if talentsRest and not string.find(talentsRest, ",", 1, true) then
                directActive = talentsRest
            end
        end
        if directActive then
            directActive = string.gsub(directActive, "[%.!]+$", "")
            local dt1, dt2, dt3 = string.match(directActive, "(%d+)%s*[-/]%s*(%d+)%s*[-/]%s*(%d+)")
            if dt1 and dt2 and dt3 then
                DungeonBots.lastDetectedTriplet[cleanSender] = dt1 .. "-" .. dt2 .. "-" .. dt3
            end
            local candidate = ExtractSpecCandidate(directActive) or DungeonBots:CleanSpecText(StripSpecNoisePrefix(directActive))
            candidate = DungeonBots:CleanSpecText(candidate)
            if candidate and candidate ~= "" and string.match(candidate, "%a") then
                local normDirectTree = TREE_ALIASES[string.lower(candidate)]
                if normDirectTree then
                    DungeonBots.lastDetectedTree[cleanSender] = normDirectTree
                    local byTriplet = (dt1 and dt2 and dt3) and ResolveTripletToSpec(cleanSender, dt1, dt2, dt3) or nil
                    candidate = byTriplet or ResolveTreeToSpec(cleanSender, normDirectTree)
                end
                detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, candidate)
            elseif dt1 and dt2 and dt3 then
                local resolvedT = ResolveTripletToSpec(cleanSender, dt1, dt2, dt3)
                if resolvedT then
                    detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, resolvedT)
                end
            end
        end

        local rawChunks = {}
        local greenChunkCount = 0
        for rawChunk in string.gmatch(rawLine, "[^,;]+") do
            local cleanChunk = string.gsub(StripWowFormatting(rawChunk), "^%s*(.-)%s*$", "%1")
            if cleanChunk ~= "" then
                local chunkHasGreen = (string.find(rawChunk, "|cff00ff00", 1, true) ~= nil)
                    or (string.find(rawChunk, "|cff34c759", 1, true) ~= nil)
                if chunkHasGreen then
                    greenChunkCount = greenChunkCount + 1
                end
                table.insert(rawChunks, { text = cleanChunk, isGreen = chunkHasGreen })
            end
        end

        for _, chunkInfo in ipairs(rawChunks) do
            local cleanChunk = chunkInfo.text
            local specName = ExtractSpecCandidate(cleanChunk)
            local t1, t2, t3 = string.match(cleanChunk, "(%d+)%s*[-/]%s*(%d+)%s*[-/]%s*(%d+)")
            local isBareTreeOnly = specName and (TREE_ALIASES[string.lower(specName)] ~= nil)
                and not string.find(string.lower(specName), "pv[ep]")

            if specName and (isAvailableListLine or not isBareTreeOnly) then
                if DungeonBots.pendingListReset[cleanSender] and (isAvailableListLine or string.find(string.lower(specName), "pv[ep]")) then
                    DungeonBots.botSpecs[cleanSender] = {}
                    DungeonBots.pendingListReset[cleanSender] = nil
                end
                specName = DungeonBots:CanonicalizeSpec(cleanSender, specName)
                DungeonBots.botSpecs[cleanSender] = DungeonBots.botSpecs[cleanSender] or {}
                local alreadyExists = false
                local lowerSpecName = string.lower(specName)
                for _, s in ipairs(DungeonBots.botSpecs[cleanSender]) do
                    if string.lower(s) == lowerSpecName then
                        alreadyExists = true
                        break
                    end
                end
                if not alreadyExists then
                    table.insert(DungeonBots.botSpecs[cleanSender], specName)
                    foundAnySpec = true
                end

                if t1 and t2 and t3 then
                    DungeonBots.botSpecTriplets[cleanSender][t1 .. "-" .. t2 .. "-" .. t3] = specName
                end

                local lc = string.lower(cleanChunk)
                local activeByGreen = chunkInfo.isGreen and ((not isAvailableListLine) or greenChunkCount == 1)
                if string.find(lc, "active", 1, true)
                    or string.find(lc, "current", 1, true)
                    or string.find(lc, "actual", 1, true)
                    or string.find(lc, "activo", 1, true)
                    or string.match(cleanChunk, "^%*")
                    or string.match(cleanChunk, ":%s*%*")
                    or string.match(cleanChunk, "%*$")
                    or string.match(cleanChunk, "^%->")
                    or string.match(cleanChunk, ":%s*%->")
                    or activeByGreen then
                    detectedActiveSpec = specName
                end
            elseif (t1 and t2 and t3) and not isAvailableListLine then
                DungeonBots.lastDetectedTriplet[cleanSender] = t1 .. "-" .. t2 .. "-" .. t3
                if specName and isBareTreeOnly then
                    local normTree = TREE_ALIASES[string.lower(specName)]
                    if normTree then
                        DungeonBots.lastDetectedTree[cleanSender] = normTree
                    end
                end
                if not detectedActiveSpec then
                    local resolvedFromTriplet = ResolveTripletToSpec(cleanSender, t1, t2, t3)
                    if not resolvedFromTriplet and specName and isBareTreeOnly then
                        local normTree = TREE_ALIASES[string.lower(specName)]
                        if normTree then
                            resolvedFromTriplet = ResolveTreeToSpec(cleanSender, normTree)
                        end
                    end
                    if resolvedFromTriplet then
                        detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, resolvedFromTriplet)
                    end
                end
            end

            if not isAvailableListLine then
                for rawTree, rawPts in string.gmatch(cleanChunk, "([%a ]+)%s*[:%(]?%s*(%d+)%)?") do
                    local key = string.lower(StripSpecNoisePrefix(rawTree))
                    local normTree = TREE_ALIASES[key]
                    local pts = tonumber(rawPts)
                    if normTree and pts and pts > 0 then
                        DungeonBots.liveTreePoints[cleanSender][normTree] = math.max(
                            DungeonBots.liveTreePoints[cleanSender][normTree] or 0,
                            pts
                        )
                    end
                end

                local tripletTree = string.match(cleanChunk, "([%a ]+)%s*%(%s*%d+[-/]%d+[-/]%d+%s*%)")
                if tripletTree and t1 and t2 and t3 then
                    local normTree = TREE_ALIASES[string.lower(StripSpecNoisePrefix(tripletTree))]
                    local totalPts = (tonumber(t1) or 0) + (tonumber(t2) or 0) + (tonumber(t3) or 0)
                    if normTree and totalPts > 0 then
                        DungeonBots.liveTreePoints[cleanSender][normTree] = math.max(
                            DungeonBots.liveTreePoints[cleanSender][normTree] or 0,
                            totalPts
                        )
                    end
                end
            end
        end
    end

    if not detectedActiveSpec then
        local bestTree, bestTreePts = nil, 0
        for treeKey, pts in pairs(DungeonBots.liveTreePoints[cleanSender]) do
            if pts > bestTreePts then
                bestTreePts = pts
                bestTree = treeKey
            end
        end
        if bestTree and bestTreePts > 0 then
            DungeonBots.lastDetectedTree[cleanSender] = bestTree
            detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, ResolveTreeToSpec(cleanSender, bestTree))
        end
    elseif detectedActiveSpec ~= "" then
        detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, detectedActiveSpec)
    end

    return foundAnySpec, detectedActiveSpec
end

-- Registro y Manejo de Eventos
-- =========================================================================
local eventFrame = CreateFrame("Frame", "DungeonBots_EventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

local function HandlePartyChanged(isEnteringWorld)
    DungeonBots:ResolvePendingPartyBots()
    DungeonBots:SyncPartyToHistory()
    if DungeonBots.CheckPartyForNewBots then
        DungeonBots:CheckPartyForNewBots()
    end
    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
    if isEnteringWorld and DungeonBots.UpdateHUDVisibility then
        DungeonBots:UpdateHUDVisibility()
    end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "DungeonBots" then
            DungeonBotsDB = DungeonBotsDB or {}
            for k, v in pairs(DEFAULT_CONFIG) do
                if DungeonBotsDB[k] == nil then
                    DungeonBotsDB[k] = v
                end
            end
        end

    elseif event == "PLAYER_LOGIN" then
        DungeonBotsDB = DungeonBotsDB or {}
        for k, v in pairs(DEFAULT_CONFIG) do
            if DungeonBotsDB[k] == nil then
                if type(v) == "table" then
                    DungeonBotsDB[k] = {}
                    for tk, tv in pairs(v) do
                        DungeonBotsDB[k][tk] = tv
                    end
                else
                    DungeonBotsDB[k] = v
                end
            end
        end

        DungeonBotsDB.botHistory = DungeonBotsDB.botHistory or {}
        for _, entry in pairs(DungeonBotsDB.botHistory) do
            if entry and entry.spec and entry.spec ~= "" then
                entry.spec = DungeonBots:CleanSpecText(entry.spec)
            end
        end
        if DungeonBotsDB.botActiveSpec then
            for name, activeSpec in pairs(DungeonBotsDB.botActiveSpec) do
                if activeSpec and activeSpec ~= "" then
                    DungeonBotsDB.botActiveSpec[name] = DungeonBots:CleanSpecText(activeSpec)
                end
            end
        end
        if DungeonBotsDB.botSpecs then
            for _, specList in pairs(DungeonBotsDB.botSpecs) do
                if type(specList) == "table" then
                    for idx, specVal in ipairs(specList) do
                        if type(specVal) == "string" and specVal ~= "" then
                            specList[idx] = DungeonBots:CleanSpecText(specVal)
                        end
                    end
                end
            end
        end
        DungeonBots.botSpecs = DungeonBotsDB.botSpecs or {}

        DungeonBotsDB.historyMigrated = true

        DungeonBots:Print("v" .. DungeonBots.VERSION .. " cargado. Escribe |cffffd200/db|r o |cffffd200/bots|r, o pulsa en |cff71d5ffEl Ojo|r del Buscador de Mazmorras.")
        if DungeonBots.InitUI then
            DungeonBots:InitUI()
        end
        if DungeonBots.InitHUD then
            DungeonBots:InitHUD()
        end
        DungeonBots:SyncPartyToHistory()

    elseif event == "CHAT_MSG_WHISPER" then
        local message, sender = ...
        if not sender then return end
        local cleanSender = string.match(sender, "([^-]+)") or sender
        local playerName = UnitName and UnitName("player")
        if not cleanSender or cleanSender == "" or cleanSender == playerName then
            return
        end

        -- Si está marcado explícitamente como jugador humano, tratar siempre como jugador
        if DungeonBots:IsBot(cleanSender) == false then
            if DungeonBots.OnWhisperReceived then
                DungeonBots:OnWhisperReceived(cleanSender, message)
            end
            return
        end

        local inParty = (DungeonBots:FindPartyUnitByName(cleanSender) ~= nil)
        local isKnownOrHistory = DungeonBots:ShouldTreatAsBot(cleanSender)
        local hasPendingScan = DungeonBots:HasPendingScan(cleanSender)
        local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
        local inRaid = (GetNumRaidMembers and GetNumRaidMembers() > 0)
        local canConsumeClassSummon = (not isKnownOrHistory)
            and (not hasPendingScan)
            and (not inParty)
            and (not inRaid)
            and (numParty < 4)
            and DungeonBots:HasPendingClassSummon()

        -- Si no fue agregado recientemente ni está en el historial (ni bajo escaneo manual), tratar como jugador
        if not isKnownOrHistory and not hasPendingScan and not canConsumeClassSummon then
            if DungeonBots.OnWhisperReceived then
                DungeonBots:OnWhisperReceived(cleanSender, message)
            end
            return
        end

        local lowerMsg = string.lower(message or "")
        local isBotText = (string.find(lowerMsg, "follow distance")
            or string.find(lowerMsg, "following")
            or string.find(lowerMsg, "staying")
            or string.find(lowerMsg, "strategies:")
            or string.find(lowerMsg, "available specs")
            or string.find(lowerMsg, "talents")
            or string.find(lowerMsg, "co %+")
            or string.find(lowerMsg, "nc %+")
            or string.find(lowerMsg, "fleeing")
            or string.find(lowerMsg, "stats:")
            or string.find(lowerMsg, "money:")
            or string.find(lowerMsg, "greetings")
            or string.find(lowerMsg, "ready")
            or string.match(lowerMsg, "%d+[-/]%d+[-/]%d+")) and true or false

        -- Confirmación manual mediante "¿Quién es bot?"
        if hasPendingScan and not isKnownOrHistory then
            if not isBotText then
                DungeonBots.pendingScan[cleanSender] = nil
                if DungeonBots.OnWhisperReceived then
                    DungeonBots:OnWhisperReceived(cleanSender, message)
                end
                return
            end
            DungeonBots.pendingScan[cleanSender] = nil
            DungeonBots.confirmedBots[cleanSender] = true
            DungeonBots:MarkRecentBot(cleanSender, 120)
            DungeonBots:RegisterBot(cleanSender, true)
            DungeonBots:RecordBotHistory(cleanSender)
            DungeonBots:Print("Bot confirmado: |cff00e5ff" .. cleanSender .. "|r (respondió automáticamente como bot).")
            isKnownOrHistory = true
        end

        -- Consumo de invocación reciente por clase ("Invocar Bot por Clase")
        if canConsumeClassSummon and not isKnownOrHistory then
            if DungeonBots:ConsumePendingClassSummon() then
                DungeonBots:MarkRecentBot(cleanSender, 120)
                DungeonBots:RegisterBot(cleanSender, true)
                DungeonBots:RecordBotHistory(cleanSender)
                isKnownOrHistory = true
            end
        end

        -- Parser dinámico de ramas de talentos y especialización activa en vivo
        local foundAnySpec, detectedActiveSpec = ParseTalentWhisper(cleanSender, message)
        local qState = queryStates[cleanSender]

        if foundAnySpec and DungeonBotsDB then
            DungeonBotsDB.botSpecs = DungeonBotsDB.botSpecs or {}
            DungeonBotsDB.botSpecs[cleanSender] = DungeonBots.botSpecs[cleanSender]
            if qState then
                qState.gotSpecList = true
            end
            DungeonBots:RegisterBot(cleanSender, true)
            DungeonBots:RecordBotHistory(cleanSender)
            DungeonBots:Print("Ramas actualizadas para |cffffd200" .. cleanSender .. "|r: " .. table.concat(DungeonBots.botSpecs[cleanSender], ", "))

            -- Si 'talents' llegó antes que 'talents spec list', refinar con las ramas reales recién recibidas
            if not detectedActiveSpec then
                local refined = nil
                local lastTriplet = DungeonBots.lastDetectedTriplet and DungeonBots.lastDetectedTriplet[cleanSender]
                if lastTriplet and DungeonBots.botSpecTriplets[cleanSender] then
                    refined = DungeonBots.botSpecTriplets[cleanSender][lastTriplet]
                end
                if not refined then
                    local lastTree = DungeonBots.lastDetectedTree and DungeonBots.lastDetectedTree[cleanSender]
                    if lastTree then
                        local candidateRefined = ResolveTreeToSpec(cleanSender, lastTree)
                        if candidateRefined and candidateRefined ~= "" and string.lower(candidateRefined) ~= string.lower(lastTree) then
                            refined = candidateRefined
                        end
                    end
                end
                if not refined and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[cleanSender] then
                    refined = DungeonBots:CanonicalizeSpec(cleanSender, DungeonBotsDB.botActiveSpec[cleanSender])
                end
                if refined and refined ~= "" then
                    detectedActiveSpec = refined
                end
            end

            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
        end

        if detectedActiveSpec and detectedActiveSpec ~= "" then
            detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, detectedActiveSpec)
            if DungeonBotsDB then
                DungeonBotsDB.botActiveSpec = DungeonBotsDB.botActiveSpec or {}
                DungeonBotsDB.botActiveSpec[cleanSender] = detectedActiveSpec
            end
            if qState then
                qState.gotActiveSpec = true
            end
            DungeonBots.pendingSpecReset[cleanSender] = nil
            DungeonBots:RegisterBot(cleanSender, true)
            DungeonBots:RecordBotHistory(cleanSender, nil, detectedActiveSpec, nil)
            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
        end

        local isBotResponse = (foundAnySpec or detectedActiveSpec or isBotText) and true or false
        if isBotResponse then
            DungeonBots.confirmedBots[cleanSender] = true
            DungeonBots:RegisterBot(cleanSender, true)
            DungeonBots:RecordBotHistory(cleanSender)
            if DungeonBots:HasPendingScan(cleanSender) then
                DungeonBots.pendingScan[cleanSender] = nil
                DungeonBots:Print("Bot confirmado: |cff00e5ff" .. cleanSender .. "|r (respondió automáticamente como bot).")
            end
            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
        end

        -- Auto-invite solo para bots recién invocados o bots del historial con respuesta de bot, si hay cupo (< 5 en grupo)
        local shouldAutoInvite = DungeonBots:IsRecentBot(cleanSender) or (isKnownOrHistory and isBotResponse)
        if shouldAutoInvite and DungeonBotsDB and DungeonBotsDB.autoInvite and not inParty and DungeonBots:CanInviteToParty() then
            if (DungeonBots.recentInvites[cleanSender] or 0) <= NowTime() then
                DungeonBots.recentInvites[cleanSender] = NowTime() + 3
                DungeonBots:RecordBotHistory(cleanSender)
                InviteUnit(cleanSender)
                DungeonBots:Print("Auto-invitando bot detectado: |cffffd200" .. cleanSender .. "|r")
            end
        end

        -- Guardar log de último susurro para la pestaña de bots
        if DungeonBots.OnWhisperReceived then
            DungeonBots:OnWhisperReceived(cleanSender, message)
        end

    elseif event == "PARTY_MEMBERS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        HandlePartyChanged(event == "PLAYER_ENTERING_WORLD")

    elseif event == "UNIT_NAME_UPDATE" then
        local unit = ...
        if unit and string.match(unit, "^party%d$") then
            HandlePartyChanged(false)
        end

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        if DungeonBots.UpdateHUDVisibility then
            DungeonBots:UpdateHUDVisibility()
        end
    end
end)

-- =========================================================================
-- Comandos Slash (/db, /dungeonbots, /bots, /playerbot)
-- =========================================================================
local function CleanMsg(str)
    if not str then return "" end
    str = string.gsub(str, "^%s*(.-)%s*$", "%1")
    return string.lower(str)
end

SLASH_DUNGEONBOTS1 = "/db"
SLASH_DUNGEONBOTS2 = "/dungeonbots"
SLASH_DUNGEONBOTS3 = "/bots"
SLASH_DUNGEONBOTS4 = "/playerbot"

SlashCmdList["DUNGEONBOTS"] = function(msg)
    msg = CleanMsg(msg)
    if msg == "hud" then
        if DungeonBots.ToggleHUD then
            DungeonBots:ToggleHUD()
        end
    elseif msg == "dalaran" then
        DungeonBots:DalaranPrep()
    elseif msg == "addall" then
        DungeonBots:AddAllBots()
    elseif msg == "dismiss" or msg == "removeall" then
        DungeonBots:RemoveAllBots()
    elseif msg == "reset" then
        if DungeonBotsDB then
            DungeonBotsDB.hudPosition = { point = "BOTTOM", x = 0, y = 140 }
            if DungeonBots.hudFrame then
                DungeonBots.hudFrame:ClearAllPoints()
                DungeonBots.hudFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 140)
            end
            DungeonBots:Print("Posición del HUD restaurada.")
        end
    else
        if DungeonBots.ToggleUI then
            DungeonBots:ToggleUI()
        elseif DungeonBots.InitUI then
            DungeonBots:InitUI()
            if DungeonBots.ToggleUI then
                DungeonBots:ToggleUI()
            end
        end
    end
end

