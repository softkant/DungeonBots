-- =========================================================================
-- Locales\enUS.lua: Base Localization Table and English Defaults
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local L = DungeonBots.L or {}
setmetatable(L, {
    __index = function(tbl, key)
        if key == nil then return "" end
        return key
    end
})
DungeonBots.L = L

-- Mensajes de estado y avisos vacios del servidor
L["NO_GLYPHS_EQUIPPED"]    = "No glyphs equipped."
L["NO_SPELLS_FOUND"]       = "No spells found."
L["NO_SPELLS_MATCH"]       = "No spells match the filter."
L["NO_ACTIVE_QUESTS"]      = "No active quests."
L["NO_COMPLETED_QUESTS"]   = "No completed quests."
L["QUEST_LOG_EMPTY"]       = "Quest log is empty."
L["QUEST_COMPLETE_READY"]  = "Complete (ready to turn in)"
L["INVENTORY_EMPTY"]       = "No items in bags."
L["INVENTORY_LOADING"]     = "Querying inventory..."

-- Etiquetas de hechizos, glifos y estados
L["GLYPH_MAJOR"]           = "Major"
L["GLYPH_MINOR"]           = "Minor"
L["GLYPH_DEFAULT"]         = "Glyph"
L["SPELL_DEFAULT"]         = "Spell"
L["QUEST_DEFAULT"]         = "Quest"
L["ITEM_DEFAULT"]          = "Item"

L["DIFF_OPTIMAL"]          = "Orange"
L["DIFF_MEDIUM"]           = "Yellow"
L["DIFF_EASY"]             = "Green"
L["DIFF_TRIVIAL"]          = "Gray"

L["STATUS_COMPLETE"]       = "Complete"
L["STATUS_INCOMPLETE"]     = "Incomplete"
L["STATUS_FAILED"]         = "Failed"
L["STATUS_READY"]          = "Ready to turn in"

L["MONEY_PREFIX"]          = "Money:"
L["FREE_SLOTS_PREFIX"]     = "Free slots:"
L["SLOTS_PREFIX"]          = "Slots:"
L["TOTAL_PREFIX"]          = "Total:"

L["CAT_GENERAL"]           = "General"
L["CAT_BAGS"]              = "Bags"
L["CAT_EQUIPPED"]          = "Equipped"
L["CAT_CONSUMABLES"]       = "Consumables"
L["CAT_TRADE_GOODS"]       = "Trade Goods"
L["CAT_QUEST"]             = "Quest"
L["CAT_MISC"]              = "Miscellaneous"
L["CAT_REAGENTS"]          = "Reagents"
L["CAT_EQUIPMENT"]         = "Equipment"
L["CAT_KEYS"]              = "Keys"
