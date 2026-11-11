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
    whisperMuteMode = "all",
    muteBotGroupChat = false,
    closeWimBotWindows = true,
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
DungeonBots.recentOutgoingAddonWhispers = {}
DungeonBots.justPromotedBotWhisper = {}
DungeonBots.pendingQuestCapture = {}
DungeonBots.questDialogData = {}
DungeonBots.pendingQuestRefresh = {}
DungeonBots.pendingTalkCapture = {}
DungeonBots.talkDialogData = {}
DungeonBots.pendingTalkRefresh = {}
DungeonBots.pendingPartyTalkUntil = 0
DungeonBots.lastTalkBot = nil

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
        local muteMode = (DungeonBotsDB and DungeonBotsDB.whisperMuteMode) or "auto"
        if muteMode ~= "off" then
            DungeonBots:Print("Comprobación silenciosa de bots en: |cffffd200" .. table.concat(checkedNames, ", ") .. "|r...")
        else
            DungeonBots:Print("Comprobando quién es bot en: |cffffd200" .. table.concat(checkedNames, ", ") .. "|r (los bots responderán automáticamente en el chat).")
        end
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

local isSendingAddonWhisper = false

local function NormalizePlayerName(name)
    if not name or name == "" then return nil end
    return string.match(name, "([^-]+)") or name
end

local function TrimText(str)
    if not str then return "" end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function DungeonBots:StripChatFormatting(text)
    if not text or text == "" then return "" end
    local clean = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    clean = string.gsub(clean, "|r", "")
    clean = string.gsub(clean, "|H[^|]*|h(.-)|h", "%1")
    return clean
end

local function PruneOutgoingWhispers(list, now)
    if not list then return end
    for i = #list, 1, -1 do
        if not list[i] or (list[i].expiresAt or 0) <= now then
            table.remove(list, i)
        end
    end
end

function DungeonBots:MarkAddonOutgoingWhisper(botName, cmd, ttlSeconds)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or not cmd or cmd == "" then return end
    local now = NowTime()
    DungeonBots.recentOutgoingAddonWhispers = DungeonBots.recentOutgoingAddonWhispers or {}
    local list = DungeonBots.recentOutgoingAddonWhispers[cleanBot]
    if not list then
        list = {}
        DungeonBots.recentOutgoingAddonWhispers[cleanBot] = list
    end
    PruneOutgoingWhispers(list, now)
    table.insert(list, {
        cmd = string.lower(TrimText(cmd)),
        expiresAt = now + (ttlSeconds or 4.0),
    })
end

function DungeonBots:IsRecentAddonOutgoingWhisper(botName, message)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or not DungeonBots.recentOutgoingAddonWhispers then return false end
    local list = DungeonBots.recentOutgoingAddonWhispers[cleanBot]
    if not list or #list == 0 then return false end
    local now = NowTime()
    PruneOutgoingWhispers(list, now)
    if #list == 0 then return false end
    local lowerMsg = string.lower(TrimText(message or ""))
    for _, entry in ipairs(list) do
        if entry.cmd == lowerMsg then
            return true
        end
    end
    return false
end

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
    DungeonBots:MarkAddonOutgoingWhisper(botName, cmd, 4.0)
    isSendingAddonWhisper = true
    SendChatMessage(cmd, "WHISPER", nil, botName)
    isSendingAddonWhisper = false
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

local function ExtractSafeQuestLinkFromText(line)
    if not line or line == "" then return nil end
    local hStart, hEnd = string.find(line, "|Hquest:[^|]+|h%[[^%]]+%]|h")
    if not hStart then return nil end
    if hStart > 10 then
        local colorPrefix = string.sub(line, hStart - 10, hStart - 1)
        local colorSuffix = string.sub(line, hEnd + 1, hEnd + 2)
        if string.match(colorPrefix, "^|c%x%x%x%x%x%x%x%x$") and colorSuffix == "|r" then
            return string.sub(line, hStart - 10, hEnd + 2), hStart - 10, hEnd + 2, string.sub(line, hStart, hEnd)
        end
    end
    return nil, hStart, hEnd, string.sub(line, hStart, hEnd)
end

-- Ver misiones del bot (y mostrar en ventana interactiva)
function DungeonBots:QueryQuests(botName, isSilent)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot then return end
    local now = NowTime()
    DungeonBots.pendingTalkCapture[cleanBot] = nil
    DungeonBots.pendingTalkRefresh[cleanBot] = nil
    DungeonBots.pendingQuestCapture[cleanBot] = {
        startedAt = now,
        expiresAt = now + 3.5,
        finalizeAt = now + 2.2,
        gotAnyLine = false,
    }
    DungeonBots.questDialogData[cleanBot] = {
        botName = cleanBot,
        loading = true,
        done = false,
        captureSection = "active",
        quests = {},
        seenKeys = {},
        rawLines = {},
        emptyHint = nil,
        updatedAt = now,
    }
    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end
    if DungeonBots.OpenQuestDialog then
        DungeonBots:OpenQuestDialog(cleanBot)
    end
    if not isSilent then
        local muteMode = (DungeonBotsDB and DungeonBotsDB.whisperMuteMode) or "auto"
        if muteMode == "off" then
            DungeonBots:Print("Consultando misiones de |cffffd200" .. cleanBot .. "|r...")
        end
    end
    DungeonBots:SendWhisperCommand(cleanBot, "quests all")
end

-- Abandonar una misión de un bot y refrescar la lista
function DungeonBots:DropBotQuest(botName, questEntry)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot or not questEntry then return end
    local target = questEntry.safeLink or questEntry.title
    if not target or target == "" then return end
    local now = NowTime()

    local data = DungeonBots.questDialogData and DungeonBots.questDialogData[cleanBot]
    if data and type(data.quests) == "table" then
        for i = #data.quests, 1, -1 do
            local q = data.quests[i]
            if q == questEntry or (questEntry.questId and q.questId == questEntry.questId) then
                table.remove(data.quests, i)
            end
        end
        if data.seenKeys then
            local key = questEntry.questId and ("id_" .. tostring(questEntry.questId)) or (questEntry.title and ("t_" .. string.lower(questEntry.title)))
            if key then
                data.seenKeys[key] = nil
            end
        end
    end
    if DungeonBots.pendingQuestCapture then
        DungeonBots.pendingQuestCapture[cleanBot] = nil
    end

    DungeonBots:SendWhisperCommand(cleanBot, "drop " .. target)
    if DungeonBots.UpdateQuestDialog then
        DungeonBots:UpdateQuestDialog(cleanBot)
    end
    DungeonBots.pendingQuestRefresh[cleanBot] = now + 0.55
    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end
end

function DungeonBots:GetPartyBotsList()
    local bots = {}
    local seen = {}
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local rawName = UnitName(unit)
            local name = NormalizePlayerName(rawName)
            if name and name ~= "" and name ~= UNKNOWNOBJECT and name ~= "Unknown" and not seen[name] then
                if DungeonBots:ShouldTreatAsBot(name) then
                    seen[name] = true
                    local _, classToken = UnitClass(unit)
                    local activeSpec = DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[name]
                    table.insert(bots, {
                        unit = unit,
                        name = name,
                        classToken = classToken,
                        spec = activeSpec,
                    })
                end
            end
        end
    end
    return bots
end

function DungeonBots:FindDefaultTalkBot()
    if UnitExists("target") and UnitIsPlayer("target") then
        local targetName = NormalizePlayerName(UnitName("target"))
        if targetName and DungeonBots:ShouldTreatAsBot(targetName) then
            return targetName
        end
    end
    if DungeonBots.lastTalkBot and DungeonBots:FindPartyUnitByName(DungeonBots.lastTalkBot) then
        return DungeonBots.lastTalkBot
    end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = NormalizePlayerName(UnitName(unit))
            if name and DungeonBots:ShouldTreatAsBot(name) then
                return name
            end
        end
    end
    return DungeonBots.lastTalkBot
end

function DungeonBots:ArmTalkCapture(botName, cmd, resetLines)
    local cleanBot = NormalizePlayerName(botName)
    if not cleanBot then return end
    local now = NowTime()
    local lowerCmd = string.lower(TrimText(cmd or "talk"))
    local isAcceptCmd = (lowerCmd == "accept *" or lowerCmd == "accept" or string.match(lowerCmd, "^accept%s+.+$") ~= nil)
    DungeonBots.pendingQuestCapture[cleanBot] = nil
    DungeonBots.pendingTalkRefresh[cleanBot] = nil
    DungeonBots.lastTalkBot = cleanBot
    local data = DungeonBots.talkDialogData[cleanBot]
    if resetLines or not data then
        data = {
            botName = cleanBot,
            npcName = (UnitExists("target") and not UnitIsPlayer("target")) and UnitName("target") or (data and data.npcName) or nil,
            lastCmd = cmd or "talk",
            isAcceptCmd = isAcceptCmd,
            acceptError = false,
            loading = true,
            done = false,
            lines = {},
            actions = {},
            seenActions = {},
            updatedAt = now,
        }
        DungeonBots.talkDialogData[cleanBot] = data
    else
        data.loading = true
        data.done = false
        data.lastCmd = cmd or data.lastCmd or "talk"
        data.isAcceptCmd = isAcceptCmd
        data.acceptError = false
        if UnitExists("target") and not UnitIsPlayer("target") then
            data.npcName = UnitName("target")
        end
    end
    DungeonBots.pendingTalkCapture[cleanBot] = {
        startedAt = now,
        expiresAt = now + (isAcceptCmd and 1.4 or 3.2),
        finalizeAt = now + (isAcceptCmd and 0.85 or 2.0),
        gotAnyLine = false,
        isAcceptCmd = isAcceptCmd,
    }
    if DungeonBots.uiCaptureFrame then
        DungeonBots.uiCaptureFrame:Show()
    end
    if DungeonBots.OpenTalkDialog then
        DungeonBots:OpenTalkDialog(cleanBot)
    end
end

function DungeonBots:ArmPartyTalkCapture(cmd)
    local now = NowTime()
    DungeonBots.pendingPartyTalkUntil = now + 3.0
    DungeonBots.pendingPartyTalkCmd = cmd or "talk"
    DungeonBots.pendingPartyTalkNpc = (UnitExists("target") and not UnitIsPlayer("target")) and UnitName("target") or nil
end

function DungeonBots:SendTalkCommand(botName, cmd)
    local cleanBot = NormalizePlayerName(botName) or DungeonBots:FindDefaultTalkBot()
    if not cleanBot then
        DungeonBots:Warn("No hay ningún bot en el grupo para hablar con el PNJ.")
        return
    end
    local cleanCmd = TrimText(cmd or "talk")
    if cleanCmd == "" then cleanCmd = "talk" end
    DungeonBots:ArmTalkCapture(cleanBot, cleanCmd, true)
    DungeonBots:SendWhisperCommand(cleanBot, cleanCmd)
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
    return DungeonBots:StripChatFormatting(text)
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

-- =========================================================================
-- Ocultamiento de Mensajes de Bots (Blizzard Chat + WIM) y Capturas UI
-- =========================================================================
local chatFiltersRegistered = false
local sendChatHooked = false
local wimWrappedMethods = {}

local function IsPureTalentResponse(message)
    local lowerMsg = string.lower(TrimText(StripWowFormatting(message or "")))
    if lowerMsg == "" then return false end
    if string.find(string.lower(message or ""), "|hquest:") then
        return false
    end
    if string.find(lowerMsg, "^available specs")
        or string.find(lowerMsg, "^talents")
        or (string.find(lowerMsg, "talents") and string.find(lowerMsg, "%d+/%d+/%d+")) then
        return true
    end
    return false
end

local function IsBotDetectionText(message)
    local lowerMsg = string.lower(message or "")
    return (string.find(lowerMsg, "follow distance")
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
        or string.find(lowerMsg, "active quests")
        or string.find(lowerMsg, "completed quests")
        or string.find(lowerMsg, "no active quests")
        or string.find(lowerMsg, "no quests")
        or string.find(lowerMsg, "|hquest:")
        or string.find(lowerMsg, "autogear")
        or string.find(lowerMsg, "nothing to say")
        or string.find(lowerMsg, "no npc")
        or string.match(lowerMsg, "%d+[-/]%d+[-/]%d+")) and true or false
end

function DungeonBots:EvaluateWhisperSender(cleanSender, message, allowPromote)
    if not cleanSender or cleanSender == "" then
        return { isBot = false }
    end
    if DungeonBots:IsBot(cleanSender) == false then
        return { isBot = false, explicitHuman = true }
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

    local isBotText = IsBotDetectionText(message)
    local justPromoted = ((DungeonBots.justPromotedBotWhisper[cleanSender] or 0) > NowTime())

    if not isKnownOrHistory and not hasPendingScan and not canConsumeClassSummon then
        return {
            isBot = false,
            isKnownOrHistory = false,
            inParty = inParty,
            isBotText = isBotText,
            justPromoted = justPromoted,
        }
    end

    if allowPromote then
        if hasPendingScan and not isKnownOrHistory then
            if not isBotText then
                DungeonBots.pendingScan[cleanSender] = nil
                return {
                    isBot = false,
                    isKnownOrHistory = false,
                    inParty = inParty,
                    rejectedScan = true,
                }
            end
            DungeonBots.pendingScan[cleanSender] = nil
            DungeonBots.confirmedBots[cleanSender] = true
            DungeonBots:MarkRecentBot(cleanSender, 120)
            DungeonBots:RegisterBot(cleanSender, true)
            DungeonBots:RecordBotHistory(cleanSender)
            DungeonBots.justPromotedBotWhisper[cleanSender] = NowTime() + 1.0
            DungeonBots:Print("Bot confirmado: |cff00e5ff" .. cleanSender .. "|r (respondió automáticamente como bot).")
            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
            isKnownOrHistory = true
            justPromoted = true
        end

        if canConsumeClassSummon and not isKnownOrHistory then
            if DungeonBots:ConsumePendingClassSummon() then
                DungeonBots:MarkRecentBot(cleanSender, 120)
                DungeonBots:RegisterBot(cleanSender, true)
                DungeonBots:RecordBotHistory(cleanSender)
                DungeonBots.justPromotedBotWhisper[cleanSender] = NowTime() + 1.0
                isKnownOrHistory = true
                justPromoted = true
            end
        end
    end

    return {
        isBot = isKnownOrHistory,
        isKnownOrHistory = isKnownOrHistory,
        inParty = inParty,
        hasPendingScan = hasPendingScan,
        canConsumeClassSummon = canConsumeClassSummon,
        isBotText = isBotText,
        justPromoted = justPromoted,
    }
end

function DungeonBots:ShouldSuppressChatEvent(event, message, sender)
    if not DungeonBotsDB or not sender or sender == "" then
        return false
    end

    local cleanName = NormalizePlayerName(sender)
    if not cleanName or cleanName == "" then
        return false
    end

    local playerName = UnitName and UnitName("player")
    if event ~= "CHAT_MSG_WHISPER_INFORM" and cleanName == playerName then
        return false
    end

    -- Nunca ocultar a jugadores marcados explícitamente como humanos
    if DungeonBots:IsBot(cleanName) == false then
        return false
    end

    local whisperMode = (DungeonBotsDB.whisperMuteMode == "off") and "off" or "all"
    local muteGroup = DungeonBotsDB.muteBotGroupChat and true or false

    if event == "CHAT_MSG_WHISPER_INFORM" then
        if whisperMode == "off" then
            return false
        end
        if DungeonBots:IsRecentAddonOutgoingWhisper(cleanName, message) then
            return true
        end
        return DungeonBots:ShouldTreatAsBot(cleanName)

    elseif event == "CHAT_MSG_WHISPER" then
        if whisperMode == "off" then
            return false
        end
        local eval = DungeonBots:EvaluateWhisperSender(cleanName, message, true)
        if not eval or not eval.isBot then
            return false
        end
        return true

    elseif event == "CHAT_MSG_AFK" or event == "CHAT_MSG_DND" then
        if whisperMode == "off" then
            return false
        end
        return DungeonBots:ShouldTreatAsBot(cleanName)

    elseif event == "CHAT_MSG_PARTY"
        or event == "CHAT_MSG_PARTY_LEADER"
        or event == "CHAT_MSG_SAY"
        or event == "CHAT_MSG_YELL" then
        if whisperMode == "off" or not muteGroup then
            return false
        end
        return DungeonBots:ShouldTreatAsBot(cleanName)
    end

    return false
end

local function ChatEventFilterFunc(self, event, message, sender, ...)
    if DungeonBots:ShouldSuppressChatEvent(event, message, sender) then
        return true
    end
    return false
end

function DungeonBots:SetupChatFilters()
    if chatFiltersRegistered or not ChatFrame_AddMessageEventFilter then return end
    chatFiltersRegistered = true
    local events = {
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_AFK",
        "CHAT_MSG_DND",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
    }
    for _, ev in ipairs(events) do
        ChatFrame_AddMessageEventFilter(ev, ChatEventFilterFunc)
    end
end

function DungeonBots:CloseBotWIMWindows()
    local wim = _G.WIM
    if not wim or not wim.windows or not wim.windows.active or not wim.windows.active.whisper then
        return
    end
    for winName, win in pairs(wim.windows.active.whisper) do
        local clean = NormalizePlayerName(winName)
        if clean and DungeonBots:ShouldTreatAsBot(clean) and win then
            if type(win) == "table" then
                if win.unreadCount ~= nil then
                    win.unreadCount = 0
                end
                if type(win.Hide) == "function" then
                    win:Hide()
                end
            end
        end
    end
end

local function WrapWIMController(modName, mod, methodName, blockItem)
    if not mod or type(mod[methodName]) ~= "function" then return end
    local key = modName .. ":" .. methodName
    if wimWrappedMethods[key] then return end
    wimWrappedMethods[key] = true

    local orig = mod[methodName]
    mod[methodName] = function(self, firstArg, ...)
        if type(firstArg) == "table" and type(firstArg.GetArgs) == "function" and type(firstArg.GetEvent) == "function" then
            local ev = firstArg:GetEvent()
            local msg, sender = firstArg:GetArgs()
            if DungeonBots:ShouldSuppressChatEvent(ev, msg, sender) then
                if blockItem and type(firstArg.Block) == "function" then
                    firstArg:Block()
                end
                return
            end
        end
        return orig(self, firstArg, ...)
    end
end

function DungeonBots:SetupWIMCompatibility()
    local wim = _G.WIM
    if not wim or not wim.modules then return end

    if wim.modules.Filters then
        WrapWIMController("Filters", wim.modules.Filters, "CHAT_MSG_WHISPER_CONTROLLER", true)
        WrapWIMController("Filters", wim.modules.Filters, "CHAT_MSG_WHISPER_INFORM_CONTROLLER", true)
    end
    if wim.modules.ChatFilters then
        WrapWIMController("ChatFilters", wim.modules.ChatFilters, "CHAT_MSG_PARTY_CONTROLLER", true)
        WrapWIMController("ChatFilters", wim.modules.ChatFilters, "CHAT_MSG_PARTY_LEADER_CONTROLLER", true)
        WrapWIMController("ChatFilters", wim.modules.ChatFilters, "CHAT_MSG_SAY_CONTROLLER", true)
    end
    if wim.modules.WhisperEngine then
        WrapWIMController("WhisperEngine", wim.modules.WhisperEngine, "CHAT_MSG_AFK", true)
        WrapWIMController("WhisperEngine", wim.modules.WhisperEngine, "CHAT_MSG_DND", true)
    end
end

function DungeonBots:HookSendChatForTalk()
    if sendChatHooked or not hooksecurefunc then return end
    sendChatHooked = true
    hooksecurefunc("SendChatMessage", function(msg, chatType, language, channel)
        if isSendingAddonWhisper or not msg or msg == "" then return end
        local cleanMsg = TrimText(msg)
        local lowerMsg = string.lower(cleanMsg)
        local isTalkCmd = (lowerMsg == "talk") or (string.match(lowerMsg, "^talk%s+.+$") ~= nil)
        local isAcceptFollowup = (DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown())
            and (lowerMsg == "accept *" or (string.match(lowerMsg, "^accept%s+.+$") ~= nil))

        if not isTalkCmd and not isAcceptFollowup then
            return
        end

        if chatType == "WHISPER" and channel then
            local cleanTarget = NormalizePlayerName(channel)
            if cleanTarget and DungeonBots:ShouldTreatAsBot(cleanTarget) then
                DungeonBots:MarkAddonOutgoingWhisper(cleanTarget, msg, 4.0)
                DungeonBots:ArmTalkCapture(cleanTarget, cleanMsg, isTalkCmd or isAcceptFollowup)
            end
        elseif (chatType == "PARTY" or chatType == "SAY") and isTalkCmd then
            DungeonBots:ArmPartyTalkCapture(cleanMsg)
        end
    end)
end

local uiCaptureFrame = CreateFrame("Frame")
uiCaptureFrame:Hide()
DungeonBots.uiCaptureFrame = uiCaptureFrame

uiCaptureFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = NowTime()
    local hasAny = false

    for botName, refreshAt in pairs(DungeonBots.pendingQuestRefresh) do
        if now >= refreshAt then
            DungeonBots.pendingQuestRefresh[botName] = nil
            DungeonBots:QueryQuests(botName, true)
        else
            hasAny = true
        end
    end

    for botName, refreshAt in pairs(DungeonBots.pendingTalkRefresh) do
        if now >= refreshAt then
            DungeonBots.pendingTalkRefresh[botName] = nil
            if DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown() and DungeonBots.talkFrame.currentBot == botName then
                DungeonBots:SendTalkCommand(botName, "talk")
            end
        else
            hasAny = true
        end
    end

    for botName, cap in pairs(DungeonBots.pendingQuestCapture) do
        if now >= (cap.finalizeAt or cap.expiresAt or 0) or now >= (cap.expiresAt or 0) then
            DungeonBots.pendingQuestCapture[botName] = nil
            local data = DungeonBots.questDialogData[botName]
            if data then
                data.loading = false
                data.done = true
                if DungeonBots.UpdateQuestDialog then
                    DungeonBots:UpdateQuestDialog(botName)
                end
            end
        else
            hasAny = true
        end
    end

    for botName, cap in pairs(DungeonBots.pendingTalkCapture) do
        if now >= (cap.finalizeAt or cap.expiresAt or 0) or now >= (cap.expiresAt or 0) then
            DungeonBots.pendingTalkCapture[botName] = nil
            local data = DungeonBots.talkDialogData[botName]
            if data then
                data.loading = false
                data.done = true
                if cap.isAcceptCmd then
                    if data.acceptError then
                        if not data.playedAcceptSound then
                            data.playedAcceptSound = true
                            PlaySound("igQuestFailed")
                        end
                    else
                        if not data.playedAcceptSound then
                            data.playedAcceptSound = true
                            PlaySound("QUESTADDED")
                        end
                        if DungeonBots.talkFrame and DungeonBots.talkFrame:IsShown() and DungeonBots.talkFrame.currentBot == botName then
                            DungeonBots.pendingTalkRefresh[botName] = now + 0.15
                            hasAny = true
                        end
                    end
                end
                if DungeonBots.UpdateTalkDialog then
                    DungeonBots:UpdateTalkDialog(botName)
                end
            end
        else
            hasAny = true
        end
    end

    if not hasAny then
        self:Hide()
    end
end)

local function ParseQuestCaptureWhisper(cleanSender, message)
    local cap = DungeonBots.pendingQuestCapture[cleanSender]
    if not cap then return false end

    local now = NowTime()
    if now > (cap.expiresAt or 0) then
        DungeonBots.pendingQuestCapture[cleanSender] = nil
        return false
    end

    local data = DungeonBots.questDialogData[cleanSender]
    if not data then return false end

    local fullCleanLower = string.lower(TrimText(StripWowFormatting(message or "")))
    if IsPureTalentResponse(message) then
        return false
    end

    cap.gotAnyLine = true
    cap.finalizeAt = math.min(cap.expiresAt, now + 0.75)
    data.loading = false
    data.updatedAt = now

    for rawLine in string.gmatch(message or "", "[^\r\n]+") do
        local line = TrimText(rawLine)
        local cleanLine = TrimText(StripWowFormatting(line))
        local lowerClean = string.lower(cleanLine)

        if cleanLine ~= "" then
            table.insert(data.rawLines, line)

            if string.find(lowerClean, "no active quests")
                or string.find(lowerClean, "0 active quests")
                or lowerClean == "no quests"
                or lowerClean == "none" then
                data.emptyHint = cleanLine
                cap.finalizeAt = math.min(cap.finalizeAt, now + 0.25)
            elseif string.find(lowerClean, "^[-=]+$")
                or string.find(lowerClean, "^summary:")
                or string.find(lowerClean, "^total:")
                or string.find(lowerClean, "no completed quests")
                or string.find(lowerClean, "no incompleted quests")
                or string.find(lowerClean, "no incomplete quests")
                or string.find(lowerClean, "quest dropped")
                or string.find(lowerClean, "abandoned") then
                -- Encabezado o resumen informativo; no agregar como fila de misión
            elseif string.find(lowerClean, "incompleted quests")
                or string.find(lowerClean, "incomplete quests")
                or string.find(lowerClean, "active quests")
                or string.find(lowerClean, "^%-*%s*incompleted?")
                or string.find(lowerClean, "^%-*%s*active") then
                data.captureSection = "active"
            elseif string.find(lowerClean, "completed quests") or string.find(lowerClean, "^%-*%s*completed") then
                data.captureSection = "completed"
            else
                local scanPos = 1
                local foundLinkInLine = false
                while true do
                    local subLine = string.sub(line, scanPos)
                    local safeLink, sOff, eOff, plainH = ExtractSafeQuestLinkFromText(subLine)
                    if not plainH then break end

                    foundLinkInLine = true
                    local qId, qLevel, qTitle = string.match(plainH, "^|Hquest:(%d+):(-?%d*)|h%[([^%]]+)%]|h$")
                    qTitle = qTitle or StripWowFormatting(plainH)
                    local dedupKey = qId and ("id_" .. qId) or ("t_" .. string.lower(qTitle))

                    if not data.seenKeys[dedupKey] then
                        data.seenKeys[dedupKey] = true
                        local extraText = ""
                        if scanPos == 1 and not string.find(string.sub(subLine, eOff + 1), "|Hquest:") then
                            local beforeTxt = TrimText(StripWowFormatting(string.sub(subLine, 1, sOff - 1)))
                            beforeTxt = TrimText(string.gsub(beforeTxt, "^[%d#%[%]%.%):%-]+%s*", ""))
                            local afterTxt = TrimText(StripWowFormatting(string.sub(subLine, eOff + 1)))
                            extraText = TrimText(beforeTxt .. " " .. afterTxt)
                        end
                        if extraText == "" and data.captureSection == "completed" then
                            extraText = "Completa (lista para entregar)"
                        end
                        table.insert(data.quests, {
                            questId = qId,
                            questLevel = (qLevel and qLevel ~= "") and qLevel or "80",
                            title = qTitle,
                            safeLink = safeLink,
                            displayLink = safeLink or ("|cffffff00" .. plainH .. "|r"),
                            statusText = extraText,
                            canDrop = true,
                            rawLine = line,
                        })
                    end

                    scanPos = scanPos + eOff
                    if scanPos > #line then break end
                end

                if not foundLinkInLine then
                    local fallbackTitle = TrimText(string.gsub(cleanLine, "^[%d#]+[%.)%]:%-]+%s*", ""))
                    if fallbackTitle ~= "" and #fallbackTitle > 2 then
                        local dedupKey = "t_" .. string.lower(fallbackTitle)
                        if not data.seenKeys[dedupKey] then
                            data.seenKeys[dedupKey] = true
                            local statusBadge = (data.captureSection == "completed") and "Completa (lista para entregar)" or ""
                            table.insert(data.quests, {
                                questId = nil,
                                questLevel = nil,
                                title = fallbackTitle,
                                safeLink = nil,
                                displayLink = nil,
                                statusText = statusBadge,
                                canDrop = true,
                                rawLine = line,
                            })
                        end
                    end
                end
            end
        end
    end

    if DungeonBots.UpdateQuestDialog then
        DungeonBots:UpdateQuestDialog(cleanSender)
    end
    return true
end

local function AddTalkAction(data, key, actionObj)
    if not data or not key or data.seenActions[key] then return end
    data.seenActions[key] = true
    table.insert(data.actions, actionObj)
end

local function IsQuestLogDumpMessage(message)
    local lowerClean = string.lower(TrimText(StripWowFormatting(message or "")))
    if lowerClean == "" then return false end
    if string.find(lowerClean, "active quests", 1, true)
        or string.find(lowerClean, "completed quests", 1, true)
        or string.find(lowerClean, "no active quests", 1, true)
        or string.find(lowerClean, "^summary:", 1, false) then
        return true
    end
    return false
end

local function ClassifyTalkQuestLine(lowerClean, isAcceptCmd)
    local isError = (string.find(lowerClean, "cannot", 1, true)
        or string.find(lowerClean, "couldn't", 1, true)
        or string.find(lowerClean, "could not", 1, true)
        or string.find(lowerClean, "unable", 1, true)
        or string.find(lowerClean, "not ready", 1, true)
        or string.find(lowerClean, "failed", 1, true)
        or string.find(lowerClean, "don't meet", 1, true)
        or string.find(lowerClean, "quest log is full", 1, true)
        or string.find(lowerClean, "no npc", 1, true)
        or string.find(lowerClean, "out of range", 1, true)) and true or false

    if isAcceptCmd then
        return true, isError
    end

    local isAlreadyOrBlocked = isError
        or string.find(lowerClean, "in progress", 1, true)
        or string.find(lowerClean, "incomplete", 1, true)
        or string.find(lowerClean, "already", 1, true)
        or string.find(lowerClean, "on quest", 1, true)
        or string.find(lowerClean, "accepted", 1, true)
        or string.find(lowerClean, "turned in", 1, true)
        or string.find(lowerClean, "aceptada", 1, true)
        or string.find(lowerClean, "en progreso", 1, true)
        or string.find(lowerClean, "en curso", 1, true)
        or string.find(lowerClean, "ya tienes", 1, true)
        or string.find(lowerClean, "entregada", 1, true)

    return isAlreadyOrBlocked and true or false, false
end

local function ParseTalkCaptureWhisper(cleanSender, message)
    if DungeonBots.pendingQuestCapture and DungeonBots.pendingQuestCapture[cleanSender] then
        return false
    end

    local cap = DungeonBots.pendingTalkCapture[cleanSender]
    if not cap then
        if (DungeonBots.pendingPartyTalkUntil or 0) > NowTime()
            and DungeonBots:FindPartyUnitByName(cleanSender)
            and not IsPureTalentResponse(message)
            and not IsQuestLogDumpMessage(message) then
            DungeonBots.pendingPartyTalkUntil = 0
            DungeonBots:ArmTalkCapture(cleanSender, DungeonBots.pendingPartyTalkCmd or "talk", true)
            local reclaimed = DungeonBots.talkDialogData[cleanSender]
            if reclaimed and DungeonBots.pendingPartyTalkNpc and not reclaimed.npcName then
                reclaimed.npcName = DungeonBots.pendingPartyTalkNpc
            end
            cap = DungeonBots.pendingTalkCapture[cleanSender]
        end
    end
    if not cap then return false end

    local now = NowTime()
    if now > (cap.expiresAt or 0) then
        DungeonBots.pendingTalkCapture[cleanSender] = nil
        return false
    end

    if IsPureTalentResponse(message) or IsQuestLogDumpMessage(message) then
        return false
    end

    local data = DungeonBots.talkDialogData[cleanSender]
    if not data then return false end

    cap.gotAnyLine = true
    if cap.isAcceptCmd then
        cap.finalizeAt = math.min((cap.startedAt or now) + 2.0, now + 0.20)
        cap.expiresAt = math.min((cap.startedAt or now) + 2.5, math.max(cap.expiresAt, now + 0.6))
    else
        cap.finalizeAt = math.min((cap.startedAt or now) + 5.0, now + 0.50)
        cap.expiresAt = math.min((cap.startedAt or now) + 5.5, math.max(cap.expiresAt, now + 1.5))
    end
    data.loading = false
    data.updatedAt = now

    local playerName = (UnitName and UnitName("player")) or ""

    for rawLine in string.gmatch(message or "", "[^\r\n]+") do
        local line = TrimText(rawLine)
        if line ~= "" then
            if playerName ~= "" then
                line = string.gsub(line, "%$[nN]", playerName)
            end

            local cleanLine = TrimText(StripWowFormatting(line))
            local lowerClean = string.lower(cleanLine)
            local headerNpc = string.match(cleanLine, "^%-%-+%s*(.-)%s*%-%-+$")
                or string.match(cleanLine, "^Talking to%s+([^:]+):?$")
            local isNpcHeaderLine = false
            if headerNpc and headerNpc ~= "" and not string.find(string.lower(headerNpc), "quest") then
                data.npcName = headerNpc
                isNpcHeaderLine = true
            end

            local hasQuestLinkInLine = (string.find(line, "|Hquest:", 1, true) ~= nil)
            local skipQuestAction, isAcceptErr = ClassifyTalkQuestLine(lowerClean, cap.isAcceptCmd)
            if cap.isAcceptCmd then
                if isAcceptErr then
                    data.acceptError = true
                elseif (string.find(lowerClean, "accepted", 1, true)
                    or string.find(lowerClean, "aceptada", 1, true)
                    or string.find(lowerClean, "completed", 1, true)
                    or string.find(lowerClean, "turned in", 1, true))
                    and not data.playedAcceptSound then
                    data.playedAcceptSound = true
                    PlaySound("QUESTADDED")
                end
            end

            -- Opciones numeradas de gossip ([0] ..., [1] ..., #1: ..., 1. ...)
            local hadHash = (string.match(line, "^%s*%[#") ~= nil) or (string.match(line, "^%s*#") ~= nil)
            local optNum, optBody = string.match(line, "^%s*%[#?(%d+)%]%s*[:%.%-]*%s*(.+)$")
            if not optNum then
                optNum, optBody = string.match(line, "^%s*#(%d+)%s*[:%.%-%)]*%s*(.+)$")
            end
            if not optNum then
                optNum, optBody = string.match(line, "^%s*(%d+)[%.%):]%s+(.+)$")
            end

            local parsedNum = optNum and tonumber(optNum) or nil
            local isOptionLine = false
            if parsedNum and parsedNum >= 0 and parsedNum <= 30 and optBody then
                local cleanOpt = TrimText(StripWowFormatting(optBody))
                if cleanOpt ~= "" then
                    isOptionLine = true
                    if not hasQuestLinkInLine then
                        AddTalkAction(data, "gossip_" .. optNum, {
                            kind = "gossip",
                            cmd = hadHash and ("talk #" .. optNum) or ("talk " .. optNum),
                            label = cleanOpt,
                            rawText = line,
                        })
                    end
                end
            end

            if not isNpcHeaderLine then
                if isOptionLine then
                    if string.find(line, "|H") then
                        local cleanBody = TrimText(optBody)
                        if cleanBody ~= "" then
                            table.insert(data.lines, cleanBody)
                        end
                    end
                else
                    table.insert(data.lines, line)
                end
            end

            -- Enlaces de misión dentro del diálogo del PNJ
            if hasQuestLinkInLine and not skipQuestAction then
                local scanPos = 1
                while true do
                    local subLine = string.sub(line, scanPos)
                    local safeLink, sOff, eOff, plainH = ExtractSafeQuestLinkFromText(subLine)
                    if not plainH then break end

                    local qId, qLevel, qTitle = string.match(plainH, "^|Hquest:(%d+):(-?%d*)|h%[([^%]]+)%]|h$")
                    qTitle = qTitle or StripWowFormatting(plainH)
                    local actionTarget = safeLink or qTitle
                    AddTalkAction(data, "quest_" .. (qId or string.lower(qTitle)), {
                        kind = "quest",
                        questId = qId,
                        questLevel = (qLevel and qLevel ~= "") and qLevel or "80",
                        title = qTitle,
                        safeLink = safeLink,
                        displayLink = safeLink or ("|cffffff00" .. plainH .. "|r"),
                        acceptCmd = "accept " .. actionTarget,
                        talkCmd = "talk " .. actionTarget,
                        label = qTitle,
                    })

                    scanPos = scanPos + eOff
                    if scanPos > #line then break end
                end
            end
        end
    end

    if DungeonBots.UpdateTalkDialog then
        DungeonBots:UpdateTalkDialog(cleanSender)
    end
    return true
end

-- =========================================================================
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
            if DungeonBotsDB.whisperMuteMode == "auto" then
                DungeonBotsDB.whisperMuteMode = "all"
            end
        elseif addonName == "WIM" then
            if DungeonBots.SetupWIMCompatibility then
                DungeonBots:SetupWIMCompatibility()
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
        if DungeonBotsDB.whisperMuteMode == "auto" then
            DungeonBotsDB.whisperMuteMode = "all"
        end

        DungeonBotsDB.historyMigrated = true

        DungeonBots:SetupChatFilters()
        DungeonBots:SetupWIMCompatibility()
        DungeonBots:HookSendChatForTalk()

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
        local cleanSender = NormalizePlayerName(sender)
        local playerName = UnitName and UnitName("player")
        if not cleanSender or cleanSender == "" or cleanSender == playerName then
            return
        end

        local evalResult = DungeonBots:EvaluateWhisperSender(cleanSender, message, true)
        if not evalResult or not evalResult.isBot then
            if DungeonBots.OnWhisperReceived then
                DungeonBots:OnWhisperReceived(cleanSender, message)
            end
            return
        end

        local inParty = evalResult.inParty
        local isKnownOrHistory = evalResult.isKnownOrHistory
        local isBotText = evalResult.isBotText

        ParseQuestCaptureWhisper(cleanSender, message)
        ParseTalkCaptureWhisper(cleanSender, message)

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

SlashCmdList["DUNGEONBOTS"] = function(rawMsg)
    local trimmed = TrimText(rawMsg or "")
    local msg = CleanMsg(trimmed)
    if msg == "hud" then
        if DungeonBots.ToggleHUD then
            DungeonBots:ToggleHUD()
        end
    elseif msg == "talk" or string.match(msg, "^talk%s+") then
        local botArg = TrimText(string.sub(trimmed, 5))
        local resolvedBot = nil
        if botArg ~= "" then
            local lowerArg = string.lower(botArg)
            for i = 1, 4 do
                local pName = UnitName("party" .. i)
                if pName and string.lower(pName) == lowerArg then
                    resolvedBot = pName
                    break
                end
            end
            if not resolvedBot and DungeonBotsDB and DungeonBotsDB.botHistory then
                for hName in pairs(DungeonBotsDB.botHistory) do
                    if string.lower(hName) == lowerArg then
                        resolvedBot = hName
                        break
                    end
                end
            end
            resolvedBot = resolvedBot or botArg
        end
        DungeonBots:SendTalkCommand(resolvedBot, "talk")
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

