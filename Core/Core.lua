-- =========================================================================
-- DungeonBots.lua: Núcleo del Addon, Constantes, Estado y Utilidades Base
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.VERSION = "1.2.5"
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal
local L = DungeonBots.L or {}

-- Configuración por defecto
local DEFAULT_CONFIG = {
    autoInvite = true,
    hudLocked = false,
    hudScale = 1.0,
    hudVisible = true,
    utilHudVisible = true,
    utilHudLocked = false,
    hudOnlyInGroup = true,
    hudOnlyInDungeon = false,
    attackWaitSeconds = 2,
    pullWaitSeconds = 6,
    fleeActive = false,
    whisperMuteMode = "all",
    muteBotGroupChat = false,
    closeWimBotWindows = true,
    uiTheme = "gold",
    addonLocale = "auto",
    hudPosition = { point = "BOTTOM", x = 0, y = 140 },
    utilHudPosition = { point = "BOTTOM", x = 0, y = 194 },
    minimapAngle = 195,
    lastWhisperLog = {},
    knownBots = {},
    botHistory = {},
    botTeams = { {}, {}, {} },
    botSpecs = {},
    botSpecTriplets = {},
    botActiveSpec = {},
}
DB_Internal.DEFAULT_CONFIG = DEFAULT_CONFIG

DungeonBots.botSpecs = {}

-- Clases soportadas para .playerbots bot addclass [clase]
DungeonBots.CLASSES = {
    { id = "warrior", name = L["CLASS_WARRIOR"], class = "WARRIOR",     icon = "Interface\\Icons\\Ability_Warrior_OffensiveStance" },
    { id = "paladin", name = L["CLASS_PALADIN"], class = "PALADIN",     icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
    { id = "hunter",  name = L["CLASS_HUNTER"],  class = "HUNTER",      icon = "Interface\\Icons\\INV_Weapon_Bow_08" },
    { id = "rogue",   name = L["CLASS_ROGUE"],   class = "ROGUE",       icon = "Interface\\Icons\\Ability_Stealth" },
    { id = "priest",  name = L["CLASS_PRIEST"],  class = "PRIEST",      icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
    { id = "dk",      name = L["CLASS_DK"],      class = "DEATHKNIGHT", icon = "Interface\\Icons\\Spell_Deathknight_ClassIcon" },
    { id = "shaman",  name = L["CLASS_SHAMAN"],  class = "SHAMAN",      icon = "Interface\\Icons\\Spell_Fire_FlameShock" },
    { id = "mage",    name = L["CLASS_MAGE"],    class = "MAGE",        icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    { id = "warlock", name = L["CLASS_WARLOCK"], class = "WARLOCK",     icon = "Interface\\Icons\\Spell_Nature_Drowsy" },
    { id = "druid",   name = L["CLASS_DRUID"],   class = "DRUID",       icon = "Interface\\Icons\\Ability_Druid_Maul" },
}

-- Ramas de talentos estándar por clase (para talents spec [rama])
DungeonBots.SPECS = {
    WARRIOR = {
        { id = "prot", name = L["SPEC_PROT_TANK"], role = "TANK", icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance" },
        { id = "fury", name = L["SPEC_FURY_DPS"], role = "DPS", icon = "Interface\\Icons\\Ability_Warrior_InnerRage" },
        { id = "arms", name = L["SPEC_ARMS_DPS"], role = "DPS", icon = "Interface\\Icons\\Ability_Warrior_SavageBlow" },
    },
    PALADIN = {
        { id = "prot", name = L["SPEC_PROT_TANK"], role = "TANK", icon = "Interface\\Icons\\Spell_Holy_DevotionAura" },
        { id = "holy", name = L["SPEC_HOLY_HEAL"], role = "HEALER", icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
        { id = "ret",  name = L["SPEC_RET_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight" },
    },
    DEATHKNIGHT = {
        { id = "blood", name = L["SPEC_BLOOD_TANK"], role = "TANK", icon = "Interface\\Icons\\Spell_Deathknight_BloodPresence" },
        { id = "frost", name = L["SPEC_FROST_DK"], role = "DPS", icon = "Interface\\Icons\\Spell_Deathknight_FrostPresence" },
        { id = "unholy",name = L["SPEC_UNHOLY_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Deathknight_UnholyPresence" },
    },
    PRIEST = {
        { id = "holy",   name = L["SPEC_HOLY_HEAL"], role = "HEALER", icon = "Interface\\Icons\\Spell_Holy_GuardianSpirit" },
        { id = "disc",   name = L["SPEC_DISC_HEAL"], role = "HEALER", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
        { id = "shadow", name = L["SPEC_SHADOW_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Shadow_Shadowform" },
    },
    DRUID = {
        { id = "feral",   name = L["SPEC_FERAL_TANK"], role = "TANK", icon = "Interface\\Icons\\Ability_Racial_BearForm" },
        { id = "resto",   name = L["SPEC_RESTO_HEAL"], role = "HEALER", icon = "Interface\\Icons\\Spell_Nature_HealingTouch" },
        { id = "balance", name = L["SPEC_BALANCE_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Nature_Starfall" },
    },
    SHAMAN = {
        { id = "resto", name = L["SPEC_RESTO_HEAL"], role = "HEALER", icon = "Interface\\Icons\\Spell_Nature_MagicImmunity" },
        { id = "elem",  name = L["SPEC_ELEM_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Nature_Lightning" },
        { id = "enh",   name = L["SPEC_ENH_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Nature_LightningShield" },
    },
    MAGE = {
        { id = "arcane", name = L["SPEC_ARCANE_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Nature_WispSplode" },
        { id = "fire",   name = L["SPEC_FIRE_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Fire_FlameBolt" },
        { id = "frost",  name = L["SPEC_FROST_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02" },
    },
    WARLOCK = {
        { id = "afflic", name = L["SPEC_AFFLIC_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil" },
        { id = "demo",   name = L["SPEC_DEMO_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis" },
        { id = "destro", name = L["SPEC_DESTRO_DPS"], role = "DPS", icon = "Interface\\Icons\\Spell_Shadow_RainOfFire" },
    },
    HUNTER = {
        { id = "mark",  name = L["SPEC_MARK_DPS"], role = "DPS", icon = "Interface\\Icons\\Ability_Marksmanship" },
        { id = "surv",  name = L["SPEC_SURV_DPS"], role = "DPS", icon = "Interface\\Icons\\Ability_Hunter_Camouflage" },
        { id = "beast", name = L["SPEC_BEAST_DPS"], role = "DPS", icon = "Interface\\Icons\\Ability_Hunter_BeastTaming" },
    },
    ROGUE = {
        { id = "combat", name = L["SPEC_COMBAT_DPS"], role = "DPS", icon = "Interface\\Icons\\Ability_BackStab" },
        { id = "assas",  name = L["SPEC_ASSAS_DPS"], role = "DPS", icon = "Interface\\Icons\\Ability_Rogue_Eviscerate" },
        { id = "subt",   name = L["SPEC_SUBT_DPS"], role = "DPS", icon = "Interface\\Icons\\Ability_Stealth" },
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
        name = L["PRESET_STANDARD_NAME"],
        desc = L["PRESET_STANDARD_DESC"],
        classes = { "paladin", "priest", "mage", "hunter", "dk" }
    },
    {
        name = L["PRESET_MELEE_NAME"],
        desc = L["PRESET_MELEE_DESC"],
        classes = { "warrior", "paladin", "dk", "rogue", "shaman" }
    },
    {
        name = L["PRESET_CASTER_NAME"],
        desc = L["PRESET_CASTER_DESC"],
        classes = { "druid", "shaman", "mage", "warlock", "hunter" }
    },
}

function DungeonBots:RefreshCoreLocaleTables()
    local classKeys = { "CLASS_WARRIOR", "CLASS_PALADIN", "CLASS_HUNTER", "CLASS_ROGUE", "CLASS_PRIEST", "CLASS_DK", "CLASS_SHAMAN", "CLASS_MAGE", "CLASS_WARLOCK", "CLASS_DRUID" }
    for i, key in ipairs(classKeys) do
        if DungeonBots.CLASSES[i] then
            DungeonBots.CLASSES[i].name = L[key]
        end
    end
    local specKeys = {
        WARRIOR     = { "SPEC_PROT_TANK", "SPEC_FURY_DPS", "SPEC_ARMS_DPS" },
        PALADIN     = { "SPEC_PROT_TANK", "SPEC_HOLY_HEAL", "SPEC_RET_DPS" },
        DEATHKNIGHT = { "SPEC_BLOOD_TANK", "SPEC_FROST_DK", "SPEC_UNHOLY_DPS" },
        PRIEST      = { "SPEC_HOLY_HEAL", "SPEC_DISC_HEAL", "SPEC_SHADOW_DPS" },
        DRUID       = { "SPEC_FERAL_TANK", "SPEC_RESTO_HEAL", "SPEC_BALANCE_DPS" },
        SHAMAN      = { "SPEC_RESTO_HEAL", "SPEC_ELEM_DPS", "SPEC_ENH_DPS" },
        MAGE        = { "SPEC_ARCANE_DPS", "SPEC_FIRE_DPS", "SPEC_FROST_DPS" },
        WARLOCK     = { "SPEC_AFFLIC_DPS", "SPEC_DEMO_DPS", "SPEC_DESTRO_DPS" },
        HUNTER      = { "SPEC_MARK_DPS", "SPEC_SURV_DPS", "SPEC_BEAST_DPS" },
        ROGUE       = { "SPEC_COMBAT_DPS", "SPEC_ASSAS_DPS", "SPEC_SUBT_DPS" },
    }
    for cls, keys in pairs(specKeys) do
        local list = DungeonBots.SPECS[cls]
        if list then
            for i, key in ipairs(keys) do
                if list[i] then list[i].name = L[key] end
            end
        end
    end
    local presetKeys = {
        { "PRESET_STANDARD_NAME", "PRESET_STANDARD_DESC" },
        { "PRESET_MELEE_NAME", "PRESET_MELEE_DESC" },
        { "PRESET_CASTER_NAME", "PRESET_CASTER_DESC" },
    }
    for i, pairKeys in ipairs(presetKeys) do
        if DungeonBots.PRESETS[i] then
            DungeonBots.PRESETS[i].name = L[pairKeys[1]]
            DungeonBots.PRESETS[i].desc = L[pairKeys[2]]
        end
    end
end

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
DungeonBots.pendingWhoCheck = {}
DungeonBots.botWhoInfo = {}
DungeonBots.instanceWarnLastAt = {}
DungeonBots.inviteRetryLastWarn = {}
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
    return classToken or L["UNKNOWN"], color, "Interface\\Icons\\INV_Misc_QuestionMark"
end

local PURE_DPS_CLASSES = {
    MAGE = true,
    WARLOCK = true,
    HUNTER = true,
    ROGUE = true,
}

local ROLE_TEX_COORDS = {
    TANK   = { 0, 67 / 256, 67 / 256, 134 / 256 },
    HEALER = { 67 / 256, 134 / 256, 0, 67 / 256 },
    DPS    = { 67 / 256, 134 / 256, 67 / 256, 134 / 256 },
}

local function ResolveRoleFromSpecText(specText, classToken)
    if not specText or specText == "" then return nil end
    local norm = string.lower(specText)
    norm = string.gsub(norm, "[_%-%(%)/,:%.]+", " ")
    norm = string.gsub(norm, "%s+", " ")
    local padded = " " .. norm .. " "

    local function hasToken(tok)
        return string.find(padded, " " .. tok .. " ", 1, true) ~= nil
    end

    if hasToken("heal") or hasToken("healer") or hasToken("sanador")
        or hasToken("holy") or hasToken("sagrado")
        or hasToken("disc") or hasToken("discipline") or hasToken("disciplina")
        or hasToken("resto") or hasToken("restoration") or hasToken("restauracion") or hasToken("restauración") then
        return "HEALER"
    end

    if hasToken("tank") or hasToken("tanque")
        or hasToken("prot") or hasToken("protection") or hasToken("proteccion") or hasToken("protección")
        or hasToken("blood") or hasToken("sangre")
        or hasToken("bear") or hasToken("oso") then
        return "TANK"
    end

    if hasToken("feral") then
        if hasToken("cat") or hasToken("gato") or hasToken("dps") then
            return "DPS"
        end
        return "TANK"
    end

    if hasToken("arms") or hasToken("armas")
        or hasToken("fury") or hasToken("furia")
        or hasToken("ret") or hasToken("retribution") or hasToken("reprension") or hasToken("reprensión")
        or hasToken("shadow") or hasToken("sombras") or hasToken("shad")
        or hasToken("balance") or hasToken("equilibrio") or hasToken("bal") or hasToken("bala")
        or hasToken("elem") or hasToken("elemental") or hasToken("ele") or hasToken("elec")
        or hasToken("enh") or hasToken("enhancement") or hasToken("mejora")
        or hasToken("unholy") or hasToken("profano") or hasToken("unh")
        or hasToken("frost") or hasToken("escarcha")
        or hasToken("frostfire") or hasToken("pirofrio") or hasToken("pirofrío") or hasToken("ffb") or hasToken("ff")
        or hasToken("arcane") or hasToken("arcano") or hasToken("arc")
        or hasToken("fire") or hasToken("fuego")
        or hasToken("afflic") or hasToken("affliction") or hasToken("afliccion") or hasToken("aflicción") or hasToken("affli") or hasToken("aff")
        or hasToken("demo") or hasToken("demonology") or hasToken("demonologia") or hasToken("demonología")
        or hasToken("destro") or hasToken("destruction") or hasToken("destruccion") or hasToken("destrucción")
        or hasToken("beast") or hasToken("beastmastery") or hasToken("bestias") or hasToken("bm")
        or hasToken("mark") or hasToken("marksmanship") or hasToken("punteria") or hasToken("puntería") or hasToken("mm")
        or hasToken("surv") or hasToken("survival") or hasToken("supervivencia") or hasToken("sv")
        or hasToken("combat") or hasToken("combate")
        or hasToken("assas") or hasToken("assassination") or hasToken("asesinato") or hasToken("assass")
        or hasToken("subt") or hasToken("subtlety") or hasToken("sutileza") or hasToken("sub")
        or hasToken("dps") or hasToken("damager") or hasToken("cat") then
        return "DPS"
    end

    return nil
end

function DungeonBots:GetBotRole(botName, classToken, specText)
    local resolvedClass = classToken
    if (not resolvedClass or resolvedClass == "") and botName and DungeonBots.FindPartyUnitByName and UnitClass then
        local unit = DungeonBots:FindPartyUnitByName(botName)
        if unit then
            local _, ct = UnitClass(unit)
            resolvedClass = ct
        end
    end

    local candidateSpec = specText
    if (not candidateSpec or candidateSpec == "") and botName and DungeonBotsDB and DungeonBotsDB.botActiveSpec then
        candidateSpec = DungeonBotsDB.botActiveSpec[botName]
    end
    local role = ResolveRoleFromSpecText(candidateSpec, resolvedClass)
    if role then return role end

    if botName and DungeonBots.lastDetectedTree and DungeonBots.lastDetectedTree[botName] then
        role = ResolveRoleFromSpecText(DungeonBots.lastDetectedTree[botName], resolvedClass)
        if role then return role end
    end

    if resolvedClass and PURE_DPS_CLASSES[resolvedClass] then
        return "DPS"
    end
    return nil
end

function DB_Internal.ApplyRoleIcon(tex, role)
    if not tex then return end
    local coords = role and ROLE_TEX_COORDS[role]
    if coords then
        tex:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
        tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        tex.role = role
    else
        tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        tex.role = nil
    end
end

-- Resuelve espacios libres, total y color de bolsas a partir de stats.
function DB_Internal.GetBotBagFreeInfo(st)
    if not st or st.bagUsed == nil then
        return nil, nil, "|cff888888"
    end
    local freeSlots = math.max(0, tonumber(st.bagUsed) or 0)
    local totalSlots = math.max(freeSlots, tonumber(st.bagTotal) or 0)
    local bagColor = st.bagColorHex
    if not bagColor or bagColor == "" then
        if freeSlots <= 5 then
            bagColor = "|cffff3b30"
        elseif totalSlots > 0 and (freeSlots / totalSlots) <= 0.35 then
            bagColor = "|cffffff00"
        else
            bagColor = "|cff34c759"
        end
    end
    return freeSlots, totalSlots, bagColor
end

function DB_Internal.FormatBotStatsDisplay(st, fallbackValueText)
    local fallback = fallbackValueText or L["STATS_QUERYING_GRAY"]
    if not st then
        return L["STATS_ARMOR_PREFIX"] .. fallback, L["STATS_BAGS_PREFIX"] .. fallback, nil
    end

    -- En mod-playerbots 'stats' reporta 0% (0) Dur cuando toda la armadura esta al 100%;
    -- cuando ya tiene desgaste reporta directamente el % restante (ej. 91%).
    local armorPct = math.max(0, math.min(100, math.floor((tonumber(st.durPct) or 0) + 0.5)))
    if armorPct == 0 then
        local extraNum = tonumber(st.durExtra)
        local lowerColor = string.lower(st.durColorHex or "")
        local isRedColor = (lowerColor == "|cffff0000" or lowerColor == "|cffff3b30")
        if not isRedColor or extraNum == 0 then
            armorPct = 100
        end
    end
    local durColor = st.durColorHex
    if not durColor or durColor == "" then
        if armorPct >= 80 then
            durColor = "|cff34c759"
        elseif armorPct >= 40 then
            durColor = "|cffffd200"
        else
            durColor = "|cffff3b30"
        end
    end

    local armorStr = L["STATS_ARMOR_PREFIX"] .. durColor .. armorPct .. "%|r"
    local freeSlots, totalSlots, bagColor = DB_Internal.GetBotBagFreeInfo(st)
    local bagStr = L["STATS_BAGS_PREFIX"] .. bagColor .. tostring(freeSlots) .. "/" .. tostring(totalSlots) .. "|r"
    return armorStr, bagStr, st
end

function DungeonBots:IsFleeActive()
    if DungeonBotsDB and DungeonBotsDB.fleeActive ~= nil then
        return DungeonBotsDB.fleeActive and true or false
    end
    return self._fleeActive and true or false
end

function DungeonBots:SetFleeActive(active, source)
    local val = active and true or false
    local now = DB_Internal.NowTime()
    if val then
        -- Evita que el eco retrasado de /p flee o "Fleeing" reactive flee justo tras limpiarlo
        if source == "chat" and self._lastFleeClearedAt and (now - self._lastFleeClearedAt) < 2.0 then
            return
        end
    else
        self._lastFleeClearedAt = now
    end
    self._fleeActive = val
    if DungeonBotsDB then
        DungeonBotsDB.fleeActive = val
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
