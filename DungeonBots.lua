-- =========================================================================
-- DungeonBots.lua: Núcleo del Addon, Constantes, Estado y Utilidades Base
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.VERSION = "1.0.0"
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal

-- Configuración por defecto
local DEFAULT_CONFIG = {
    autoInvite = true,
    hudLocked = false,
    hudScale = 1.0,
    hudVisible = true,
    utilHudVisible = true,
    utilHudLocked = false,
    formHudVisible = true,
    formHudLocked = false,
    hudOnlyInDungeon = true,
    whisperMuteMode = "all",
    muteBotGroupChat = false,
    closeWimBotWindows = true,
    hudPosition = { point = "BOTTOM", x = 0, y = 140 },
    utilHudPosition = { point = "BOTTOM", x = 0, y = 194 },
    formHudPosition = { point = "BOTTOM", x = 0, y = 248 },
    minimapAngle = 195,
    lastWhisperLog = {},
    knownBots = {},
    botHistory = {},
    botSpecs = {},
    botActiveSpec = {},
}
DB_Internal.DEFAULT_CONFIG = DEFAULT_CONFIG

DungeonBots.botSpecs = {}

-- Clases soportadas para .playerbots bot addclass [clase]
DungeonBots.CLASSES = {
    { id = "warrior", name = "Guerrero",       class = "WARRIOR",     icon = "Interface\\Icons\\Ability_Warrior_OffensiveStance" },
    { id = "paladin", name = "Paladín",        class = "PALADIN",     icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
    { id = "hunter",  name = "Cazador",        class = "HUNTER",      icon = "Interface\\Icons\\INV_Weapon_Bow_08" },
    { id = "rogue",   name = "Pícaro",         class = "ROGUE",       icon = "Interface\\Icons\\Ability_Stealth" },
    { id = "priest",  name = "Sacerdote",      class = "PRIEST",      icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
    { id = "dk",      name = "C. de la Muerte",class = "DEATHKNIGHT", icon = "Interface\\Icons\\Spell_Deathknight_ClassIcon" },
    { id = "shaman",  name = "Chamán",         class = "SHAMAN",      icon = "Interface\\Icons\\Spell_Fire_FlameShock" },
    { id = "mage",    name = "Mago",           class = "MAGE",        icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    { id = "warlock", name = "Brujo",          class = "WARLOCK",     icon = "Interface\\Icons\\Spell_Nature_Drowsy" },
    { id = "druid",   name = "Druida",         class = "DRUID",       icon = "Interface\\Icons\\Ability_Druid_Maul" },
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
    DEATHKNIGHT = { "blood pve", "frost pve", "unholy pve", "double aura blood pve", "blood pvp", "frost pvp", "unholy pvp" },
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
DungeonBots.busyExternalBots = {}
DungeonBots.busyBotLastAlert = {}
DungeonBots.lastBotCallAttempt = {}
DungeonBots.recentUserWhisperTargets = {}
DungeonBots.botStats = {}
DungeonBots.pendingQuestCapture = {}
DungeonBots.questDialogData = {}
DungeonBots.pendingQuestRefresh = {}
DungeonBots.pendingTalkCapture = {}
DungeonBots.talkDialogData = {}
DungeonBots.pendingTalkRefresh = {}
DungeonBots.pendingTalkAfterQuest = {}
DungeonBots.pendingInventoryCapture = {}
DungeonBots.inventoryDialogData = {}
DungeonBots.pendingInventoryRefresh = {}
DungeonBots.pendingPartyTalkUntil = 0
DungeonBots.lastTalkBot = nil
DungeonBots.localizedQuestTitles = {}
DungeonBots.localizedItemNames = {}

DB_Internal.CLASS_TOKEN_BY_ID = {}
for _, cls in ipairs(DungeonBots.CLASSES) do
    DB_Internal.CLASS_TOKEN_BY_ID[cls.id] = cls.class
end

-- =========================================================================
-- Utilidades Base Compartidas entre Módulos
-- =========================================================================
function DB_Internal.NowTime()
    return (GetTime and GetTime()) or 0
end

function DB_Internal.NormalizePlayerName(name)
    if not name or name == "" then return nil end
    return string.match(name, "([^-]+)") or name
end

function DB_Internal.TrimText(str)
    if not str then return "" end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function DungeonBots:StripChatFormatting(text)
    if not text or text == "" then return "" end
    local clean = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    clean = string.gsub(clean, "|r", "")
    clean = string.gsub(clean, "|T[^|]*|t", "")
    clean = string.gsub(clean, "|H[^|]*|h(.-)|h", "%1")
    clean = string.gsub(clean, "|H[^|]*|h", "")
    clean = string.gsub(clean, "|h", "")
    clean = string.gsub(clean, "|H[^|]*", "")
    return clean
end

function DB_Internal.StripWowFormatting(text)
    return DungeonBots:StripChatFormatting(text)
end

function DB_Internal.EscapeLuaPattern(str)
    return string.gsub(str or "", "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

function DB_Internal.ExtractSafeHyperlinkFromText(line, linkType, startPos)
    if not line or line == "" then return nil end
    local ltype = linkType or "quest"
    local pattern = "|H" .. ltype .. ":[^|]+|h%[[^%]]+%]|h"
    local hStart, hEnd = string.find(line, pattern, startPos or 1)
    if not hStart then return nil end
    local plainH = string.sub(line, hStart, hEnd)
    if hStart > 10 then
        local colorPrefix = string.sub(line, hStart - 10, hStart - 1)
        local colorSuffix = string.sub(line, hEnd + 1, hEnd + 2)
        if string.match(colorPrefix, "^|c%x%x%x%x%x%x%x%x$") and colorSuffix == "|r" then
            return string.sub(line, hStart - 10, hEnd + 2), hStart - 10, hEnd + 2, plainH, colorPrefix
        end
    end
    return nil, hStart, hEnd, plainH, nil
end

function DB_Internal.ExtractSafeQuestLinkFromText(line)
    return DB_Internal.ExtractSafeHyperlinkFromText(line, "quest")
end

-- Función para obtener icono oficial de Raza y Género
function DungeonBots:GetRaceIcon(unit)
    if not UnitExists(unit) then
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    local _, enRace = UnitRace(unit)
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

function DungeonBots:GetClassDisplayInfo(classToken, compactName)
    local color = (classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]) or { r = 1, g = 1, b = 1 }
    if classToken then
        local localized = DungeonBots.GetLocalizedClassName and DungeonBots:GetLocalizedClassName(classToken, compactName)
        for _, cls in ipairs(DungeonBots.CLASSES) do
            if cls.class == classToken then
                return localized or cls.name, color, cls.icon
            end
        end
        if localized then
            return localized, color, "Interface\\Icons\\INV_Misc_QuestionMark"
        end
    end
    return classToken or "Desconocido", color, "Interface\\Icons\\INV_Misc_QuestionMark"
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
