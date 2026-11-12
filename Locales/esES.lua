-- =========================================================================
-- Locales\esES.lua: Traduccion al Espanol (esES / esMX)
-- =========================================================================

local clientLocale = GetLocale and GetLocale() or "enUS"
if clientLocale ~= "esES" and clientLocale ~= "esMX" then
    return
end

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal
local L = DungeonBots.L or {}

-- Mensajes de estado y avisos vacios del servidor
L["NO_GLYPHS_EQUIPPED"]    = "Este bot no tiene glifos equipados."
L["NO_SPELLS_FOUND"]       = "No se encontraron poderes para este bot."
L["NO_SPELLS_MATCH"]       = "Ningun poder coincide con el filtro."
L["NO_ACTIVE_QUESTS"]      = "Este bot no tiene misiones activas."
L["NO_COMPLETED_QUESTS"]   = "Sin misiones completadas."
L["QUEST_LOG_EMPTY"]       = "El registro de misiones está vacío."
L["QUEST_COMPLETE_READY"]  = "Completa (lista para entregar)"
L["INVENTORY_EMPTY"]       = "No hay objetos en las bolsas."
L["INVENTORY_LOADING"]     = "Consultando inventario..."

-- Etiquetas de hechizos, glifos y estados
L["GLYPH_MAJOR"]           = "Sublime"
L["GLYPH_MINOR"]           = "Menor"
L["GLYPH_DEFAULT"]         = "Glifo"
L["SPELL_DEFAULT"]         = "Hechizo"
L["QUEST_DEFAULT"]         = "Misión"
L["ITEM_DEFAULT"]          = "Objeto"

L["DIFF_OPTIMAL"]          = "Naranja"
L["DIFF_MEDIUM"]           = "Amarillo"
L["DIFF_EASY"]             = "Verde"
L["DIFF_TRIVIAL"]          = "Gris"

L["STATUS_COMPLETE"]       = "Completa"
L["STATUS_INCOMPLETE"]     = "Incompleta"
L["STATUS_FAILED"]         = "Fallida"
L["STATUS_READY"]          = "Lista para entregar"

L["MONEY_PREFIX"]          = "Dinero:"
L["FREE_SLOTS_PREFIX"]     = "Espacios libres:"
L["SLOTS_PREFIX"]          = "Espacios:"
L["TOTAL_PREFIX"]          = "Total:"

L["CAT_GENERAL"]           = "General"
L["CAT_BAGS"]              = "Bolsas"
L["CAT_EQUIPPED"]          = "Equipado"
L["CAT_CONSUMABLES"]       = "Consumibles"
L["CAT_TRADE_GOODS"]       = "Objetos comerciables"
L["CAT_QUEST"]             = "Misión"
L["CAT_MISC"]              = "Miscelánea"
L["CAT_REAGENTS"]          = "Componentes"
L["CAT_EQUIPMENT"]         = "Equipo"
L["CAT_KEYS"]              = "Llaves"

L["TAB2_EMPTY_NO_BOTS"]    = "|cffd8e0ecNo hay bots en tu grupo actualmente.|r\n\n|cff9ea6b5Puedes agregar uno en la primera pestaña |cffffd200\"Armar Grupo\"|r|cff9ea6b5\ny luego podrás gestionar sus talentos, equipos, misiones e inventarios acá.|r"
L["TAB2_FOOTER_NO_BOTS"]   = "|cff9ea6b5No hay bots en tu grupo. Puedes agregar uno en la primera pestaña |cffffd200\"Armar Grupo\"|r|cff9ea6b5.|r"

-- Diccionario visual de ramas y clases devueltas por mod-playerbots
DB_Internal.ES_SPEC_TOKENS = {
    -- Nombres compuestos primero
    { pat = "double aura blood", es = "Sangre Doble Aura" },
    { pat = "double aura",       es = "Doble Aura" },
    { pat = "beast mastery",     es = "Bestias" },
    { pat = "frost fire",        es = "Pirofrío" },
    { pat = "death knight",      es = "C. de la Muerte" },
    { pat = "double",            es = "Doble" },
    { pat = "aura",              es = "Aura" },

    -- Ramas completas y abreviaturas de mod-playerbots
    { pat = "beastmastery",   es = "Bestias" },
    { pat = "beast",          es = "Bestias" },
    { pat = "bm",             es = "Bestias" },
    { pat = "marksmanship",   es = "Puntería" },
    { pat = "mm",             es = "Puntería" },
    { pat = "survival",       es = "Supervivencia" },
    { pat = "surv",           es = "Supervivencia" },
    { pat = "sv",             es = "Supervivencia" },

    { pat = "protection",     es = "Protección" },
    { pat = "prot",           es = "Protección" },
    { pat = "holy",           es = "Sagrado" },
    { pat = "retribution",    es = "Reprensión" },
    { pat = "ret",            es = "Reprensión" },

    { pat = "arms",           es = "Armas" },
    { pat = "fury",           es = "Furia" },

    { pat = "blood",          es = "Sangre" },
    { pat = "frostfire",      es = "Pirofrío" },
    { pat = "ffb",            es = "Pirofrío" },
    { pat = "ff",             es = "Pirofrío" },
    { pat = "frost",          es = "Escarcha" },
    { pat = "unholy",         es = "Profano" },
    { pat = "unh",            es = "Profano" },

    { pat = "discipline",     es = "Disciplina" },
    { pat = "disc",           es = "Disciplina" },
    { pat = "shadow",         es = "Sombras" },
    { pat = "shad",           es = "Sombras" },

    { pat = "feral",          es = "Feral" },
    { pat = "balance",        es = "Equilibrio" },
    { pat = "bala",           es = "Equilibrio" },
    { pat = "bal",            es = "Equilibrio" },
    { pat = "restoration",    es = "Restauración" },
    { pat = "resto",          es = "Restauración" },

    { pat = "elemental",      es = "Elemental" },
    { pat = "elem",           es = "Elemental" },
    { pat = "elec",           es = "Elemental" },
    { pat = "ele",            es = "Elemental" },
    { pat = "enhancement",    es = "Mejora" },
    { pat = "enh",            es = "Mejora" },

    { pat = "arcane",         es = "Arcano" },
    { pat = "arc",            es = "Arcano" },
    { pat = "fire",           es = "Fuego" },

    { pat = "affliction",     es = "Aflicción" },
    { pat = "afflic",         es = "Aflicción" },
    { pat = "affli",          es = "Aflicción" },
    { pat = "aff",            es = "Aflicción" },
    { pat = "demonology",     es = "Demonología" },
    { pat = "demo",           es = "Demonología" },
    { pat = "destruction",    es = "Destrucción" },
    { pat = "destro",         es = "Destrucción" },

    { pat = "combat",         es = "Combate" },
    { pat = "assassination",  es = "Asesinato" },
    { pat = "assass",         es = "Asesinato" },
    { pat = "assas",          es = "Asesinato" },
    { pat = "as",             es = "Asesinato" },
    { pat = "subtlety",       es = "Sutileza" },
    { pat = "subt",           es = "Sutileza" },
    { pat = "sub",            es = "Sutileza" },

    -- Clases en ingles devueltas por 'talents'
    { pat = "warrior",        es = "Guerrero" },
    { pat = "paladin",        es = "Paladín" },
    { pat = "hunter",         es = "Cazador" },
    { pat = "rogue",          es = "Pícaro" },
    { pat = "priest",         es = "Sacerdote" },
    { pat = "deathknight",    es = "C. de la Muerte" },
    { pat = "dk",             es = "C. de la Muerte" },
    { pat = "shaman",         es = "Chamán" },
    { pat = "mage",           es = "Mago" },
    { pat = "warlock",        es = "Brujo" },
    { pat = "druid",          es = "Druida" },

    { pat = "pve",            es = "PvE" },
    { pat = "pvp",            es = "PvP" },
}

-- Mapeo de secciones, estados y frases cortas en ingles enviadas por el servidor
DB_Internal.ES_SERVER_SECTIONS = {
    ["general"]      = L["CAT_GENERAL"],
    ["inventory"]    = L["CAT_GENERAL"],
    ["bag"]          = L["CAT_BAGS"],
    ["bags"]         = L["CAT_BAGS"],
    ["equipped"]     = L["CAT_EQUIPPED"],
    ["equipment"]    = L["CAT_EQUIPMENT"],
    ["consumable"]   = L["CAT_CONSUMABLES"],
    ["consumables"]  = L["CAT_CONSUMABLES"],
    ["trade good"]   = L["CAT_TRADE_GOODS"],
    ["trade goods"]  = L["CAT_TRADE_GOODS"],
    ["tradegoods"]   = L["CAT_TRADE_GOODS"],
    ["quest"]        = L["CAT_QUEST"],
    ["quest items"]  = L["CAT_QUEST"],
    ["misc"]         = L["CAT_MISC"],
    ["miscellaneous"]= L["CAT_MISC"],
    ["reagent"]      = L["CAT_REAGENTS"],
    ["reagents"]     = L["CAT_REAGENTS"],
    ["key"]          = L["CAT_KEYS"],
    ["keys"]         = L["CAT_KEYS"],
}
