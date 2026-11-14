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

-- =========================================================================
-- Core: Clases, Ramas, Presets, Estadisticas y General
-- =========================================================================
L["CLASS_WARRIOR"]       = "Guerrero"
L["CLASS_PALADIN"]       = "Paladín"
L["CLASS_HUNTER"]        = "Cazador"
L["CLASS_ROGUE"]         = "Pícaro"
L["CLASS_PRIEST"]        = "Sacerdote"
L["CLASS_DK"]            = "C. de la Muerte"
L["CLASS_SHAMAN"]        = "Chamán"
L["CLASS_MAGE"]          = "Mago"
L["CLASS_WARLOCK"]       = "Brujo"
L["CLASS_DRUID"]         = "Druida"
L["UNKNOWN"]             = "Desconocido"

L["SPEC_PROT_TANK"]      = "Protección (Tanque)"
L["SPEC_FURY_DPS"]       = "Furia (DPS)"
L["SPEC_ARMS_DPS"]       = "Armas (DPS)"
L["SPEC_HOLY_HEAL"]      = "Sagrado (Healer)"
L["SPEC_RET_DPS"]        = "Reprensión (DPS)"
L["SPEC_BLOOD_TANK"]     = "Sangre (Tanque/DPS)"
L["SPEC_FROST_DK"]       = "Escarcha (DPS/Tanque)"
L["SPEC_UNHOLY_DPS"]     = "Profano (DPS)"
L["SPEC_DISC_HEAL"]      = "Disciplina (Healer)"
L["SPEC_SHADOW_DPS"]     = "Sombras (DPS)"
L["SPEC_FERAL_TANK"]     = "Feral (Tanque/DPS)"
L["SPEC_RESTO_HEAL"]     = "Restauración (Healer)"
L["SPEC_BALANCE_DPS"]    = "Equilibrio (DPS Caster)"
L["SPEC_ELEM_DPS"]       = "Elemental (DPS Caster)"
L["SPEC_ENH_DPS"]        = "Mejora (DPS Melee)"
L["SPEC_ARCANE_DPS"]     = "Arcano (DPS)"
L["SPEC_FIRE_DPS"]       = "Fuego (DPS)"
L["SPEC_FROST_DPS"]      = "Escarcha (DPS)"
L["SPEC_AFFLIC_DPS"]     = "Aflicción (DPS)"
L["SPEC_DEMO_DPS"]       = "Demonología (DPS)"
L["SPEC_DESTRO_DPS"]     = "Destrucción (DPS)"
L["SPEC_MARK_DPS"]       = "Puntería (DPS)"
L["SPEC_SURV_DPS"]       = "Supervivencia (DPS)"
L["SPEC_BEAST_DPS"]      = "Bestias (DPS)"
L["SPEC_COMBAT_DPS"]     = "Combate (DPS)"
L["SPEC_ASSAS_DPS"]      = "Asesinato (DPS)"
L["SPEC_SUBT_DPS"]       = "Sutileza (DPS)"

L["PRESET_STANDARD_NAME"] = "Grupo Estándar"
L["PRESET_STANDARD_DESC"] = "Paladín (Tank), Sacerdote (Heal), Mago, Cazador, DK"
L["PRESET_MELEE_NAME"]    = "Fuerza Bruta (Melee)"
L["PRESET_MELEE_DESC"]    = "Guerrero (Tank), Paladín (Heal), DK, Pícaro, Chamán"
L["PRESET_CASTER_NAME"]   = "Casters & Rango"
L["PRESET_CASTER_DESC"]   = "Druida (Tank), Chamán (Heal), Mago, Brujo, Cazador"

L["STATS_QUERYING_GRAY"]  = "|cff888888Consultando...|r"
L["STATS_ARMOR_PREFIX"]   = "Armadura: "
L["STATS_BAGS_PREFIX"]    = "Bolsas: "
L["YOU_LABEL"]            = "Tú"
L["MEMBER_PREFIX"]        = "Miembro "

-- =========================================================================
-- Mensajes de estado, categorias de objetos y colores compartidos
-- =========================================================================
L["NO_GLYPHS_EQUIPPED"]    = "Este bot no tiene glifos equipados."
L["NO_SPELLS_FOUND"]       = "No se encontraron poderes para este bot."
L["NO_SPELLS_MATCH"]       = "Ningun poder coincide con el filtro."
L["NO_ACTIVE_QUESTS"]      = "Este bot no tiene misiones activas."
L["NO_COMPLETED_QUESTS"]   = "Sin misiones completadas."
L["QUEST_LOG_EMPTY"]       = "El registro de misiones está vacío."
L["QUEST_COMPLETE_READY"]  = "Completa (lista para entregar)"
L["INVENTORY_EMPTY"]       = "No hay objetos en las bolsas."
L["INVENTORY_LOADING"]     = "Consultando inventario..."

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
L["DIFF_GRAY"]             = "Gris"
L["DIFF_GREEN"]            = "Verde"
L["DIFF_YELLOW"]           = "Amarillo"
L["DIFF_ORANGE"]           = "Naranja"
L["DIFF_RED"]              = "Rojo"

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

-- =========================================================================
-- Etiquetas y botones comunes de UI
-- =========================================================================
L["BTN_CLOSE"]             = "Cerrar"
L["BTN_CANCEL"]            = "Cancelar"
L["BTN_REFRESH"]           = "Actualizar"
L["BTN_QUERYING"]          = "Consultando..."
L["BTN_REQUERY"]           = "Reconsultar"
L["BTN_NEXT_BOT"]          = "Siguiente Bot"
L["BTN_INVITE"]            = "Invitar"
L["BTN_ACCEPT"]            = "Aceptar"
L["BTN_TURN_IN"]           = "Entregar"
L["BTN_SHARE"]             = "Compartir"
L["BTN_ABANDON"]           = "Abandonar"
L["BTN_DESTROY"]           = "Destruir"
L["BTN_DISMISS"]           = "Despedir"
L["BTN_LOADING"]           = "Cargando..."
L["BTN_UNDERSTOOD"]        = "Entendido"
L["SEARCH_LABEL"]          = "Buscar:"
L["WAIT_BOT_RESPONSE"]     = "Esperando respuesta del bot..."
L["DETAIL_LABEL"]          = "Detalle"

-- =========================================================================
-- Mensajes de Roster y Proximidad
-- =========================================================================
L["PROX_MISSING_SHORT"]    = "Fuera del grupo"
L["PROX_MISSING_BADGE"]    = "|cff9d9d9d[No está en grupo]|r"
L["PROX_MISSING_DETAIL"]   = "%s no está en tu grupo actual."
L["PROX_OFFLINE_SHORT"]    = "Desconectado"
L["PROX_OFFLINE_BADGE"]    = "|cff9d9d9d[Desconectado]|r"
L["PROX_OFFLINE_DETAIL"]   = "%s está desconectado."
L["PROX_DEAD_SHORT"]       = "Muerto"
L["PROX_DEAD_BADGE"]       = "|cffff5544[Muerto]|r"
L["PROX_DEAD_DETAIL"]      = "%s está muerto o en espíritu."
L["PROX_OOS_SHORT"]        = "Muy lejos / otra zona"
L["PROX_OOS_BADGE"]        = "|cffff5544[Muy lejos]|r"
L["PROX_OOS_DETAIL"]       = "%s está muy lejos (más de 100 m) o en otra zona."
L["PROX_CLOSE_SHORT"]      = "Cerca"
L["PROX_CLOSE_BADGE"]      = "|cff34c759[Cerca]|r"
L["PROX_MID_SHORT"]        = "< 28 m"
L["PROX_MID_BADGE"]        = "|cffffd200[< 28 m]|r"
L["PROX_MID_DETAIL"]       = "%s está a media distancia (12-28 m). Si no responde al PNJ, acércalo un poco más."
L["PROX_FAR28_SHORT"]      = "Lejos (> 28 m)"
L["PROX_FAR28_BADGE"]      = "|cffff7b30[Lejos (> 28 m)]|r"
L["PROX_FAR28_DETAIL"]     = "%s está lejos (a más de 28 m de ti)."
L["PROX_FAR40_SHORT"]      = "Muy lejos (> 40 m)"
L["PROX_FAR40_BADGE"]      = "|cffff5544[Muy lejos (> 40 m)]|r"
L["PROX_FAR40_DETAIL"]     = "%s está muy lejos (a más de 40 m de ti)."

L["MARKED_BOT"]            = "|cffffd200%s|r marcado como: |cff00e5ff[ BOT ]|r."
L["MARKED_HUMAN"]          = "|cffffd200%s|r marcado como: |cffffb020[ JUGADOR HUMANO ]|r."
L["NO_MEMBERS_CHECK"]      = "No hay miembros en tu grupo para comprobar."
L["ALL_BOTS_CONFIRMED"]    = "Todos los bots actuales del grupo ya respondieron y están confirmados."
L["SCAN_SILENT_FMT"]       = "Comprobación silenciosa de bots en: |cffffd200%s|r..."
L["SCAN_VISIBLE_FMT"]      = "Comprobando quién es bot en: |cffffd200%s|r (los bots responderán automáticamente en el chat)."
L["GROUP_FULL_CANT_ADD"]   = "Tu grupo ya está completo (5/5). No puedes agregar más bots."
L["LFG_QUEUED_CANT_ADD"]   = "El Buscador de Mazmorras está buscando jugador (en cola). En este estado solo puedes agregar un bot desde el |cffffd200Historial de Bots|r."
L["LFG_BACKFILL_NAME_HIST_ONLY"] = "El Ojo está buscando reemplazo: ahora solo podrás agregar un bot desde el |cffffd200Historial de Bots|r (agregar por clase queda bloqueado en cola)."
L["BOT_SUMMONING_FMT"]     = "Invocando bot: |cffffd200%s|r..."
L["BOT_ADDED_FMT"]         = "Bot agregado: |cffffd200%s|r."
L["BOTS_RESUMMONED_N"]     = "Bots del grupo reinvocados (%d)."
L["BOTS_RESUMMONED"]       = "Bots del grupo reinvocados."
L["NO_BOTS_TO_RESUMMON"]   = "No hay bots en tu grupo para reinvocar."
L["DISMISSING_BOT_FMT"]    = "Despidiendo a bot: |cffffd200%s|r..."
L["DISMISSING_ALL_BOTS"]   = "Despidiendo a todos los bots del grupo..."

L["REASON_NOT_LEADER"]     = "no eres el líder del grupo"
L["REASON_IN_RAID"]        = "estás en banda"
L["REASON_GROUP_FULL"]     = "tu grupo está completo (5/5)"
L["AUTO_INVITE_FAIL_FMT"]  = "No se pudo auto-invitar a |cffffd200%s|r: %s."
L["INSTANCE_MISMATCH_Z"]   = "|cffff9900[Estancia/Fase]|r |cffffd200%s|r está en \"|cffffd200%s|r\" pero no en tu estancia/fase. Utiliza Summon, sal un momento de la mazmorra o reloguea."
L["INSTANCE_MISMATCH"]     = "|cffff9900[Estancia/Fase]|r |cffffd200%s|r no está en tu estancia o quedó faseado. Utiliza Summon o sal un momento de la mazmorra para reagruparse con los bots o reloguea."
L["ZONE_PAREN_FMT"]        = " (en |cffffd200%s|r)"
L["ZONE_IN_FMT"]           = " en |cffffd200%s|r"
L["BOT_ONLINE_LINKED"]     = "|cffffd200%s|r ya está conectado y vinculado contigo%s. Reintentando invitación al grupo..."
L["BOT_ONLINE_FREE"]       = "|cffffd200%s|r ya está conectado libremente%s. Intentando invitar al grupo..."
L["BOT_ONLINE_UNKNOWN"]    = "|cffffd200%s|r ya estaba conectado en el servidor (puede estar desconectándose o en otro grupo). Reintenta en unos segundos."
L["ALERT_BOT_OWNER_CHAT"]  = "¡ALERTA! El bot |cffffd200%s|r ya está en uso por otro jugador (en grupo con |cffffd200%s|r%s). No puedes invocarlo ahora."
L["ALERT_BOT_OWNER_UI"]    = "¡ALERTA! El bot %s ya pertenece a otro jugador (en grupo con %s)."
L["ALERT_BOT_GROUP_CHAT"]  = "¡ALERTA! El bot |cffffd200%s|r ya está en otro grupo%s. No puedes invocarlo ahora."
L["ALERT_BOT_GROUP_UI"]    = "¡ALERTA! El bot %s ya está en otro grupo."
L["BOT_HISTORY_CLEARED"]   = "Historial de bots limpiado."
L["ALREADY_IN_PARTY_FMT"]  = "|cffffd200%s|r ya forma parte de tu grupo actual."
L["PARTY_FULL_INVITE_FMT"] = "Tu grupo ya está lleno (5/5). No se puede invitar a |cffffd200%s|r."
L["MUST_BE_LEADER_FMT"]    = "Debes ser el líder del grupo para invitar a |cffffd200%s|r."

-- =========================================================================
-- Eventos del nucleo y notificaciones de modulos
-- =========================================================================
L["BAG_FULL_WARN_FMT"]     = "El inventario de |cffffd200%s|r está lleno. Puedes abrir su |cffffd200Inventario|r para destruir objetos y liberar espacio."
L["ADDON_LOADED_FMT"]      = "v%s cargado. Escribe |cffffd200/db|r o |cffffd200/bots|r, o pulsa en |cff71d5ffEl Ojo|r del Buscador de Mazmorras o en el |cff71d5ffcomplemento del minimapa|r."
L["JOIN_FAIL_ZONE_FMT"]    = "|cffffd200%s|r no pudo unirse al grupo (ubicación actual: |cffffd200%s|r)"
L["SPEC_CHANGE_FAIL_FMT"]  = "No se pudo cambiar la rama de |cffffd200%s|r (%s)."
L["SPEC_CHANGED_FMT"]      = "Talentos de |cffffd200%s|r cambiados a |cff71d5ff%s|r."
L["SPEC_UNCHANGED_FMT"]    = "La rama de |cffffd200%s|r sigue en |cff71d5ff%s|r (el bot no aplicó el cambio)."
L["BOT_CONFIRMED_FMT"]     = "Bot confirmado: |cff00e5ff%s|r (respondió automáticamente como bot)."
L["AUTO_INVITE_BOT_FMT"]   = "Auto-invitando bot detectado: |cffffd200%s|r"
L["HUD_POS_RESTORED"]      = "Posición de las barras flotantes restaurada."

L["SPEC_SET_OFFLINE_FMT"]  = "No se pudo cambiar la rama de |cffffd200%s|r porque no está en grupo o está desconectado."
L["SPEC_SET_HUMAN_FMT"]    = "|cffffd200%s|r está marcado como jugador humano; no se enviará cambio de talentos."
L["SPEC_CHANGING_FMT"]     = "Cambiando talentos de |cffffd200%s|r a |cff71d5ff%s|r..."
L["AUTOGEAR_SENDING_FMT"]  = "Enviando orden de autoequipar equipo a |cffffd200%s|r..."

L["QUEST_QUERYING_FMT"]    = "Consultando misiones de |cffffd200%s|r..."
L["QUEST_DROPPED_FMT"]     = "|cffffd200%s|r abandonó la misión: %s"
L["QUEST_CANT_SHARE"]      = "|cffff5544No se puede compartir:|r falta el enlace de la misión."
L["QUEST_SHARED_FMT"]      = "|cffffd200%s|r compartió la misión: %s"
L["QUEST_SHARED_PLAIN"]    = "|cffffd200%s|r compartió la misión."
L["QUEST_ACCEPTED_FMT"]    = "|cffffd200%s|r aceptó la misión: %s"
L["QUEST_TURNED_IN_FMT"]   = "|cffffd200%s|r entregó la misión: %s"
L["NO_BOT_FOR_NPC"]        = "No hay ningún bot en el grupo para hablar con el PNJ."
L["DALARAN_SELECT_NPC"]    = "¡Atención! Selecciona primero al PNJ que da la misión en Dalaran."
L["DALARAN_PREP_START"]    = "Ejecutando preparación en Dalaran (Summon + Aceptar misiones)..."
L["DUNGEON_REENTERED"]     = "Grupo reinvocado dentro de la mazmorra."
L["DUNGEON_SELECT_NPC"]    = "Selecciona al PNJ de la misión dentro de la mazmorra."
L["DUNGEON_TURNIN_ACCEPT"] = "Entregando y aceptando misiones del PNJ seleccionado..."
L["DALARAN_TIMER_START"]   = "|cffff3b30¡Temporizador de Dalaran iniciado (60s)!|r Los bots desaparecerán al llegar a 0."
L["DALARAN_TIMER_15S"]     = "¡Quedan 15 segundos antes de que los bots desaparezcan en Dalaran!"
L["DALARAN_TIMER_EXPIRED"] = "¡Tiempo expirado! Los bots han desaparecido en Dalaran. Entra a Forja y pulsa 'Reinvocar en Mazmorra'."

L["INV_NO_RESP_FMT"]       = "%s no respondió al actualizar el inventario."
L["INV_DESTROY_FAIL_FMT"]  = "No se recibió confirmación de %s al intentar destruir %s"
L["INV_DESTROYED_FMT"]     = "|cffffd200%s|r destruyó: %s"
L["INV_NO_BOT_SEL"]        = "No hay ningún bot seleccionado para consultar su inventario."
L["INV_SEND_DESTROY_FMT"]  = "Enviando orden de destruir a |cffffd200%s|r: %s"
L["SPELL_NO_DETAIL_FMT"]   = "%s no devolvió detalles para ese hechizo."
L["SPELL_NO_BOT_SEL"]      = "No hay ningún bot seleccionado para consultar sus poderes."
L["SPELL_ORDER_CAST_FMT"]  = "Orden enviada a |cffffd200%s|r -> lanzar %s"
L["SPELL_ORDER_CANCEL"]    = "Orden enviada a |cffffd200%s|r -> cancelar hechizo."

-- =========================================================================
-- Temas visuales
-- =========================================================================
L["THEME_GOLD_LABEL"]      = "Dorado"
L["THEME_DARK_LABEL"]      = "Oscuro Azulado"

-- =========================================================================
-- HUD y menus desplegables
-- =========================================================================
L["HUD_FOCUS_NAME"]        = "Ataque"
L["HUD_FOCUS_TITLE"]       = "|cffff2020Atacar Objetivo|r"
L["HUD_FOCUS_DESC"]        = "Clic izquierdo: Ordena al tank y a los DPS atacar tu objetivo aplicando la espera elegida.\nShift + Clic izquierdo: Atacar sin espera (al instante, sin cambiar tu opción guardada).\nClic derecho: Elegir espera de los DPS (Sin espera / 2s / 5s / 8s)."
L["HUD_PULL_NAME"]         = "Pull"
L["HUD_PULL_TITLE"]        = "|cffff9900Pull (Tank Retrocede)|r"
L["HUD_PULL_DESC"]         = "Clic izquierdo: Configura la espera de los DPS y ordena al tank pullear a rango y regresar.\nClic derecho: Elegir espera de los DPS (4s / 6s / 8s / 12s)."
L["HUD_ATK_MENU_TITLE"]    = "-- Ataque: Espera DPS --"
L["HUD_ATK_OPT_NOWAIT"]    = "Sin espera (al mismo tiempo)"
L["HUD_WAIT_SEC_FMT"]      = "%d segundos"
L["HUD_ATK_CUR_NOWAIT"]    = "Espera DPS: |cff34c759Sin espera (0s - simultáneo)|r"
L["HUD_ATK_CUR_SEC_FMT"]   = "Espera DPS: |cffffd200%d seg|r"
L["HUD_ATK_SET_NOWAIT"]    = "Ataque: espera de DPS desactivada (|cff34c759atacan al mismo tiempo|r)."
L["HUD_ATK_SET_SEC_FMT"]   = "Ataque: espera de DPS fijada en |cffffd200%d seg|r."
L["HUD_PULL_MENU_TITLE"]   = "-- Pull: Espera DPS --"
L["HUD_PULL_CUR_SEC_FMT"]  = "Espera DPS: |cffffd200%d seg|r"
L["HUD_PULL_SET_SEC_FMT"]  = "Pull: espera de DPS fijada en |cffffd200%d seg|r."
L["HUD_NOTE_TARGET_FIRST"] = "Nota: Marca un objetivo primero para usar clic izquierdo."
L["HUD_NOTE_TARGET_DEAD"]  = "Nota: El objetivo seleccionado está muerto."
L["HUD_STAY_NAME"]         = "Quedarse"
L["HUD_STAY_TITLE"]        = "|cffffff00Quedarse|r"
L["HUD_STAY_DESC"]         = "Ordena a los bots frenar en seco y mantener su posición actual.\n\n|cff71d5ffÚtil antes de que jalen patrullas o para posicionar el grupo.|r"
L["HUD_FOLLOW_NAME"]       = "Seguir"
L["HUD_FOLLOW_TITLE"]      = "|cff00ff00Seguir|r"
L["HUD_FOLLOW_DESC"]       = "Ordena a todos los bots reanudar el seguimiento normal tras de ti."
L["HUD_SUMMON_NAME"]       = "Summon"
L["HUD_SUMMON_TITLE"]      = "|cff00ccffTeletransportar a Mí|r"
L["HUD_SUMMON_DESC"]       = "Teletransporta a todos los bots directamente a tu posición.\n\n|cff71d5ffSalva a bots atascados en el suelo, rampas o puertas.|r"
L["HUD_FLEE_NAME"]         = "¡Huir!"
L["HUD_FLEE_TITLE"]        = "|cffff3b30¡HUIR! (Modo Pasivo)|r"
L["HUD_FLEE_DESC"]         = "Funciona como poner a los bots en \"Pasivo\": dejan de pelear, rompen el combate y corren hacia ti."

L["HUD_TALK_NAME"]         = "Hablar PNJ"
L["HUD_TALK_TITLE"]        = "|cff00e5ffHablar con PNJ|r"
L["HUD_TALK_DESC"]         = "Consulta los diálogos y misiones del PNJ seleccionado mediante un bot.\n\n|cff71d5ffSi hay varios bots en grupo abre un menú para elegir cuál; si solo hay uno, lo envía directo.|r"
L["HUD_QUESTS_NAME"]       = "Misiones de Bot"
L["HUD_QUESTS_TITLE"]      = "|cffffd200Misiones de Bot|r"
L["HUD_QUESTS_DESC"]       = "Abre las misiones activas del bot del grupo (o un menú si hay 2 o más bots).\n\n|cff71d5ffPermite consultar los detalles de cada misión o abandonarla.|r"
L["HUD_PARTY_NAME"]        = "Bots en el Grupo"
L["HUD_PARTY_TITLE"]       = "|cffffd200Bots en el Grupo|r"
L["HUD_PARTY_DESC"]        = "Abre directamente la pestaña de gestión del grupo actual (talentos, equipo y misiones).\n\n|cff71d5ffAtajo rápido a la segunda pestaña de DungeonBots.|r"
L["HUD_INV_NAME"]          = "Inventario de Bot"
L["HUD_INV_TITLE"]         = "|cff34c759Inventario y Bolsas de Bot|r"
L["HUD_INV_DESC"]          = "Abre las bolsas del bot del grupo (o un menú si hay 2 o más bots).\n\n|cff71d5ffPermite inspeccionar sus objetos y destruir los que no necesites.|r"
L["HUD_CHAR_NAME"]         = "Información del Personaje"
L["HUD_CHAR_TITLE"]        = "|cffb266ffInformación del Personaje|r"
L["HUD_CHAR_DESC"]         = "Abre la ventana del personaje (o un menú si hay 2 o más bots) para gestionar equipo, hechizos y glifos.\n\n|cff71d5ffPermite cambiar rama/equipo, consultar sus poderes y lanzar sus hechizos.|r"

L["HUD_FORM_CYCLE_NAME"]   = "Ciclo de Formación"
L["HUD_FORM_CYCLE_TITLE"]  = "|cff33d9ffFormación (Flecha / Near / Desactivar)|r"
L["HUD_FORM_CYCLE_DESC"]   = "Alterna la formación del grupo en cada clic:\n\n Arrow (Flecha) -> Near (Cerca) ->  Chaos (Defecto / Desactivar)"
L["HUD_FORM_CUR_FMT"]      = "Actual: %s"
L["HUD_FORM_LBL_ARROW"]    = "|cff33d9ffArrow (Flecha)|r"
L["HUD_FORM_LBL_NEAR"]     = "|cffffd200Near (Cerca)|r"
L["HUD_FORM_LBL_CHAOS"]    = "|cffaaaaaaChaos (Por defecto / Desactivada)|r"
L["HUD_MOVEGRP_NAME"]      = "Move From Group"
L["HUD_MOVEGRP_TITLE"]     = "|cff57d98cSepararse del Grupo|r"
L["HUD_MOVEGRP_DESC"]      = "Clic izquierdo: Ordena a los bots separarse del grupo.\nClic derecho: Quita la estrategia de separarse (nc y co -move from group)."

L["HUD_PICK_BOT"]          = "-- Elegir Bot --"
L["HUD_PICK_BOT_INV"]      = "-- Elegir Bot (Inventario) --"
L["HUD_PICK_BOT_CHAR"]     = "-- Información del Personaje --"
L["HUD_PICK_BOT_QUESTS"]   = "-- Elegir Bot (Misiones) --"
L["HUD_NO_BOTS_TALK"]      = "No hay bots detectados en el grupo para hablar con el PNJ."
L["HUD_NO_BOTS_INV"]       = "No hay bots detectados en el grupo para abrir su inventario."
L["HUD_NO_BOTS_CHAR"]      = "No hay bots detectados en el grupo para ver su información."
L["HUD_NO_BOTS_QUESTS"]    = "No hay bots detectados en el grupo para ver sus misiones."
L["HUD_SELECT_VALID_NPC"]  = "Selecciona primero un PNJ válido."
L["HUD_NOTE_VALID_NPC"]    = "Nota: Haz clic primero en un PNJ válido."

L["HUD_MSG_FORMATION"]     = "Formación del grupo: |cff33d9ff%s|r."
L["HUD_MSG_SPREAD_SENT"]   = "Orden enviada: |cff57d98cSepararse del grupo activado|r."
L["HUD_MSG_SPREAD_OFF"]    = "Orden enviada: |cffffb020Separarse del grupo desactivado|r (nc / co)."
L["STATE_ENABLED_GREEN"]   = "|cff34c759Activado|r"
L["STATE_DISABLED_AMBER"]  = "|cffffb020Desactivado|r"
L["STATE_VISIBLE_GREEN"]   = "|cff34c759Activada|r"
L["STATE_HIDDEN_RED"]      = "|cffff3b30Oculta|r"

L["HUD_BARS_LOCKED"]       = "Barras flotantes: |cff9d9d9dBloqueadas|r (fijadas en su posición)."
L["HUD_BARS_UNLOCKED"]     = "Barras flotantes: |cff34c759Desbloqueadas|r (puedes mover todas las barras)."
L["HUD_TIP_OPEN_TITLE"]    = "Abrir Panel DungeonBots"
L["HUD_TIP_OPEN_DESC"]     = "Abre la ventana completa de configuración, clases y talentos."
L["HUD_HIDDEN_MSG"]        = "HUD Táctico ocultado. Escribe |cffffd200/db hud|r para mostrarlo."
L["HUD_VISIBLE_MSG"]       = "HUD Táctico visible."
L["HUD_ARMED_DUNGEON_MSG"] = "HUD Táctico activado (aparecerá automáticamente al entrar a una mazmorra de 5 jugadores). Puedes cambiar esto en Configuración (el engranaje)."

-- =========================================================================
-- Ventana Principal, Pestanas 1-3, Mazmorras, Guia y Minimapa
-- =========================================================================
L["SETTINGS_TITLE"]        = "Configuración"
L["SETTINGS_TIP"]          = "Abre las opciones de las barras flotantes (Táctica y Utilidades) y filtros de chat de bots."
L["LOCK_TIP_LOCKED_TITLE"] = "Barras Flotantes: |cff9d9d9dBloqueadas|r"
L["LOCK_TIP_LOCKED_L1"]    = "Gris: ambas barras están fijadas en su posición."
L["LOCK_TIP_LOCKED_L2"]    = "Haz clic para desbloquear (verde) y poder mover las 2 barras."
L["LOCK_TIP_UNLOCK_TITLE"] = "Barras Flotantes: |cff34c759Desbloqueadas|r"
L["LOCK_TIP_UNLOCK_L1"]    = "Verde: puedes arrastrar ambas barras flotantes."
L["LOCK_TIP_UNLOCK_L2"]    = "Haz clic para bloquear (gris) y fijar las 2 barras."

L["TAB1_NAME"]             = "Armar Grupo"
L["TAB1_SUB"]              = "Historial, clases y control de grupo"
L["TAB1_TIP"]              = "Invoca bots por clase individual, abre tu historial y ejecuta acciones rápidas del grupo."
L["TAB2_NAME"]             = "Bots en el grupo"
L["TAB2_NAME_FMT"]         = "Bots en el grupo (%d)"
L["TAB2_SUB"]              = "Especialización, equipo y misiones"
L["TAB2_TIP"]              = "Gestiona las ramas de talentos, equipo y misiones de los bots activos en tu grupo."
L["TAB3_NAME"]             = "Guía y Consejos"
L["TAB3_SUB"]              = "Manual de uso y solución de problemas"
L["TAB3_TIP"]              = "Consejos esenciales sobre misiones previas, invocación dentro de mazmorras, expulsión y bots ocupados."
L["TAB_ACTIVE_HINT"]       = "|cff00ff00(Pestaña Activa)|r"
L["TAB_SWITCH_HINT"]       = "|cff888888(Haz clic para cambiar a esta pestaña)|r"

L["HIST_BOX_TITLE"]        = "|cffffd200Historial de bots|r"
L["HIST_BOX_COUNT_FMT"]    = "Lista de bots invitados anteriormente: |cffffd200%d|r"
L["HIST_BTN_VIEW"]         = "Historial/Agregar"
L["HIST_BTN_TIP_TITLE"]    = "Abrir Historial de bots"
L["HIST_BTN_TIP_DESC"]     = "Muestra la lista de bots con los que has jugado, la especialización que tenían y botones para llamarlos e invitarlos uno por uno."
L["CLASS_BOX_TITLE"]       = "|cffffd200Invocar Bot por Clase Individual|r"
L["CLASS_SUMMON_TITLE"]    = "Invocar %s"
L["CLASS_SUMMON_DESC"]     = "Invoca un bot de clase %s."
L["CLASS_SUMMON_NOTE"]     = "\n|cff34c759Si el bot te susurra al aparecer, el addon lo invitará automáticamente al grupo.|r"
L["OPTIONS_BOX_TITLE"]     = "|cffffd200Opciones Generales|r"
L["OPTIONS_BOX_SUB"]       = "|cff9ea6b5Acciones rápidas para todo el grupo:|r"

L["ACT_RESUMMON"]          = "Reinvocar Grupo"
L["ACT_RESUMMON_TITLE"]    = "Reinvocar a Todos los Bots"
L["ACT_RESUMMON_DESC"]     = "Reinvoca a los bots ausentes de tu grupo y los teletransporta a tu posición."
L["ACT_RESUMMON_NOTE"]     = "\n|cffffd200Nota:|r Solo funciona con bots que aún siguen en tu grupo pero se fueron por alguna razón (relogueo, al pasar el minuto fuera de mazmorra o desconexión). Si ya fueron sacados del grupo, llámalos desde 'Ver Historial de bots'."
L["ACT_DISMISS_ALL"]       = "Despedir a Todos"
L["ACT_DISMISS_TITLE"]     = "Despedir a Todo el Grupo"
L["ACT_DISMISS_DESC"]      = "Guarda y retira a todos los bots del mundo y los saca del grupo automáticamente."
L["ACT_REPAIR"]            = "Reparar Equipo"
L["ACT_REPAIR_MSG"]        = "Ordenando a los bots reparar su equipo..."
L["ACT_REPAIR_DESC"]       = "Ordena a los bots reparar todas sus piezas si estás cerca de un PNJ reparador o montura."
L["ACT_RELEASE"]           = "Liberar alma"
L["ACT_RELEASE_MSG"]       = "Ordenando a los bots caídos liberar su alma..."
L["ACT_RELEASE_DESC"]      = "Fuerza a los bots muertos a liberar su espíritu."
L["ACT_RELEASE_WARN"]      = "\n|cffff3b30ADVERTENCIA:|r El bot liberará espíritu pero se quedará esperando en el cementerio."

L["TAB2_EMPTY_NO_BOTS"]    = "|cffd8e0ecNo hay bots en tu grupo actualmente.|r\n\n|cff9ea6b5Puedes agregar uno en la primera pestaña |cffffd200\"Armar Grupo\"|r|cff9ea6b5\ny luego podrás gestionar sus talentos, equipos, misiones e inventarios acá.|r"
L["TAB2_FOOTER_NO_BOTS"]   = "|cff9ea6b5No hay bots en tu grupo. Puedes agregar uno en la primera pestaña |cffffd200\"Armar Grupo\"|r|cff9ea6b5.|r"
L["TAB2_ROLE_HINT"]        = "|cff888888Pulsa |cff00e5ff[BOT]|r o |cffffb020[JUGADOR]|r para cambiar el rol.|r"
L["TAB2_REFRESH_TITLE"]    = "Actualizar Estado del Grupo"
L["TAB2_REFRESH_DESC"]     = "Actualiza el estado de armadura, espacios libres en bolsas y misiones de todos los bots del grupo."

L["CARD_CHAR_BTN"]         = "Personaje"
L["CARD_CHAR_DESC"]        = "Abre la ventana Información del Personaje en Equipo (ramas de talentos y equipamiento)."
L["CARD_INV_BTN"]          = "Inventario"
L["CARD_INV_DESC"]         = "Consulta los objetos que lleva el bot en sus bolsas."
L["CARD_QUEST_BTN"]        = "Misiones"
L["CARD_QUEST_DESC"]       = "Consulta las misiones y abre la ventana de Misiones para ver detalles o abandonarlas."
L["CARD_PORTRAIT_TIP"]     = "Clic izquierdo para seleccionar."
L["CARD_LEVEL_DEFAULT"]    = "Nivel 80"
L["CARD_LEVEL_FMT"]        = "Nivel %s (%s)"
L["CARD_SPEC_NONE"]        = "Rama: |cff888888Sin detectar|r"
L["CARD_SPEC_QUERYING"]    = "Rama: |cff888888Consultando talentos...|r"
L["CARD_SPEC_FMT"]         = "Rama: |cff71d5ff%s|r"
L["CARD_ARMOR_QUERYING"]   = "Armadura: |cff888888Consultando...|r"
L["CARD_INV_QUERYING"]     = "Inventario (|cff888888...|r)"
L["CARD_INV_FMT"]          = "Inventario (%s)"
L["CARD_QUEST_QUERYING"]   = "Misiones (|cff888888...|r)"
L["CARD_QUEST_FMT"]        = "Misiones (%s%s|r)"
L["CARD_TAG_BOT"]          = "[ BOT ]"
L["CARD_TAG_BOT_RICH"]     = "|cff00e5ff[ BOT ]|r"
L["CARD_TAG_HUMAN_RICH"]   = "|cffffb020[ JUGADOR ]|r"
L["CARD_HUMAN_LOCK_NOTE"]  = "|cffffb020Jugador humano real.|r\n|cff888888Las opciones de control de bot están inactivas para este miembro.|r"
L["CARD_ROLE_BOT_TITLE"]   = "Clasificado como: |cff00e5ffBOT|r"
L["CARD_ROLE_BOT_DESC"]    = "Control total activo (talentos, equipo y despido)."
L["CARD_ROLE_BOT_CLICK"]   = "\n|cffffd200Haz clic aquí si este miembro es un jugador real.|r"
L["CARD_ROLE_HUM_TITLE"]   = "Clasificado como: |cffffb020JUGADOR HUMANO|r"
L["CARD_ROLE_HUM_DESC"]    = "Los controles automáticos están pausados para no afectarlo."
L["CARD_ROLE_HUM_CLICK"]   = "\n|cffffd200Haz clic aquí si este miembro es un bot.|r"
L["CARD_DISMISS_TITLE"]    = "Despedir Bot"
L["CARD_DISMISS_FMT"]      = "Remueve a %s del mundo, guarda su estado y lo saca del grupo."

L["DUNGEON_PIT_NAME"]      = "Foso de Saron"
L["DUNGEON_HOR_NAME"]      = "Cámaras de Reflexión"
L["DUNGEON_FOS_NAME"]      = "La Forja de Almas"
L["DUNG_UNKNOWN"]          = "Mazmorra no identificada."
L["DUNG_NO_API"]           = "API de buscador de mazmorras no disponible."
L["DUNG_MISSING_FOS"]      = "no ha completado las misiones previas de La Forja de Almas."
L["DUNG_MISSING_PIT"]      = "no ha completado las misiones previas de Foso de Saron."
L["DUNG_MISSING_REQ"]      = "no ha completado la misión necesaria."
L["DUNG_QUERYING_SRV"]     = "Consultando datos al servidor..."
L["DUNG_CAN_ENTER"]        = "|cff00ff00Puede ir|r"
L["DUNG_MISSING_Q"]        = "|cffff4444Falta misión|r"
L["DUNG_NOT_IN_PARTY"]     = "|cff888888No en grupo|r"

-- Guia (Pestana 3)
L["GUIDE_INDEX_HEADER"]    = "Índice de la Guía"
L["GUIDE_BADGE_WARN"]      = "|cffff5544ADVERTENCIA|r"
L["GUIDE_BADGE_GUIDE"]     = "|cffc9a96eGUÍA|r"
L["GUIDE_WARN_UPPER"]      = "|cffff6655ADVERTENCIA|r"
L["GUIDE_NOTE_PREFIX"]     = "|cffffd200Nota:|r "
L["GUIDE_TOPIC_OF_FMT"]    = "Tema %d de %d"
L["GUIDE_WHAT_TO_DO"]      = "Qué debes hacer:"
L["GUIDE_PREV"]            = "< Anterior"
L["GUIDE_NEXT"]            = "Siguiente >"

L["GUIDE_T1_SHORT"] = "1. Misiones previas"
L["GUIDE_T1_TITLE"] = "Mazmorras que requieren misiones previas"
L["GUIDE_T1_CAT"]   = "REQUISITOS DE ACCESO"
L["GUIDE_T1_SUM"]   = "Algunas mazmorras (como Forja de Almas, Foso de Saron y Cámaras de Reflexión) exigen que tanto tú como cada bot tengan completada su cadena previa para poder entrar."
L["GUIDE_T1_S1"]    = "En la pestaña |cffffd200Grupo de Bots|r, revisa los iconos de acceso de |cffffd200Foso de Saron|r y |cffffd200Cámaras de Reflexión|r en el pie de la ventana de Misiones."
L["GUIDE_T1_S2"]    = "Haz clic en esos botones de acceso para consultar desde el servidor si el bot ya cumple con la misión previa."
L["GUIDE_T1_S3"]    = "Si le falta, acércate al PNJ con el bot y usa la ventana de |cffffd200Misiones|r o |cffffd200Hablar|r para aceptar y entregar las misiones."
L["GUIDE_T1_NOTE"]  = "Ten en cuenta que te puede tocar hacer la misma misión más de una vez, debido a un inconveniente del sistema de bots al ellos compartirse con diferentes jugadores de niveles bajos."

L["GUIDE_T2_SHORT"] = "2. Otra estancia / fase"
L["GUIDE_T2_TITLE"] = "Bot en otra estancia o faseado dentro de mazmorra"
L["GUIDE_T2_CAT"]   = "INSTANCIAS Y FASES"
L["GUIDE_T2_SUM"]   = "Al invocar o reinvocar un bot dentro de una mazmorra, puede quedar afuera, en otra copia de la estancia o faseado (\"no está en tu estancia\")."
L["GUIDE_T2_S1"]    = "El addon te mostrará una alerta de estancia/fase con su zona exacta."
L["GUIDE_T2_S2"]    = "Utiliza |cffffd200Summon|r y/o |cffffd200Follow|r en la barra táctica (HUD) para traerlo contigo."
L["GUIDE_T2_S3"]    = "Si continúa en otra fase, sal un momento de la mazmorra para reagrupar o reinicia las estancias afuera y usa |cffffd200Summon|r varias veces."
L["GUIDE_T2_NOTE"]  = "Al pasar directo entre mazmorras enlazadas (Forja -> Foso -> Cámaras), salir y reinvocar suele alinear la estancia en caso de error."

L["GUIDE_T3_SHORT"] = "3. IDs compartidas / carga"
L["GUIDE_T3_TITLE"] = "Bots que no entran a mazmorra o datos sin cargar (IDs)"
L["GUIDE_T3_CAT"]   = "REGISTRO DE ESTANCIAS"
L["GUIDE_T3_SUM"]   = "Hay ocasiones en que un bot definitivamente no entra a la mazmorra o alguna información suya no carga en el addon. Al igual que los jugadores, los bots tienen su propio ID de mazmorras."
L["GUIDE_T3_S1"]    = "Cuando un bot ya tiene |cffffd200ID registrada|r en una mazmorra (especialmente Heroicas o Bandas), el servidor bloqueará su entrada hasta que pase el tiempo de reinicio."
L["GUIDE_T3_S2"]    = "Ten en cuenta que este registro es |cffffd200compartido|r: si otro jugador ya hizo mazmorras con ese bot antes, al llamarlo tú después seguirá conservando esas IDs."
L["GUIDE_T3_S3"]    = "Tras un tiempo, cuando se reinicien las estancias, esas mazmorras volverán a habilitarse para ese bot. Mientras tanto, prueba otro bot distinto o revisa la dificultad."
L["GUIDE_T3_NOTE"]  = "Si alguna información del bot sigue sin cargar en el addon o continúa sin poder entrar, reemplázalo por otro bot desde Armar Grupo o el Historial."

L["GUIDE_T4_SHORT"] = "4. Bot usado por otro"
L["GUIDE_T4_TITLE"] = "Bots usados por otro jugador vs. \"ya conectado\""
L["GUIDE_T4_CAT"]   = "DISPONIBILIDAD"
L["GUIDE_T4_SUM"]   = "Un bot puede estar jugando con otro usuario en el servidor o simplemente terminando de desconectarse tras una sesión reciente."
L["GUIDE_T4_S1"]    = "Si otro jugador lo tiene en su grupo, el addon cancela la auto-invitación y muestra una alerta con el |cffffd200nombre del jugador|r y la |cffffd200zona|r donde está."
L["GUIDE_T4_S2"]    = "Si el servidor solo indica \"ya conectado\" sin dueño confirmado, el addon espera unos instantes y vuelve a intentar invitarlo si está libre."
L["GUIDE_T4_S3"]    = "Cuando quede disponible o lo suelte el otro jugador, vuelve a llamarlo desde el historial."

L["GUIDE_T5_SHORT"] = "5. No expulses normal"
L["GUIDE_T5_TITLE"] = "Nunca expulses bots con \"Expulsar\""
L["GUIDE_T5_CAT"]   = "ADVERTENCIA IMPORTANTE"
L["GUIDE_T5_SUM"]   = "No |cffff3b30DEBES|r retirar a un bot usando clic derecho -> \"Expulsar\" como harías con un jugador normal."
L["GUIDE_T5_S1"]    = "Despídelos siempre desde el addon usando |cffffd200Despedir|r en su tarjeta o |cffffd200Despedir a Todos|r en Armar Grupo."
L["GUIDE_T5_S2"]    = "Si los expulsas por el menú estándar de WoW, el bot quedará conectado alrededor de |cffffd2001 minuto|r y el sistema pensará que sigues teniendo ese bot ocupado."
L["GUIDE_T5_S3"]    = "Si lo hiciste por error, espera ese minuto antes de invocar un reemplazo."
L["GUIDE_T5_NOTE"]  = "Despedir desde el addon desconecta al bot limpiamente y libera su cupo al instante."

L["GUIDE_T6_SHORT"] = "6. Equipo y Talentos"
L["GUIDE_T6_TITLE"] = "Gestión de equipo y autoequipado"
L["GUIDE_T6_CAT"]   = "EQUIPO DEL BOT"
L["GUIDE_T6_SUM"]   = "Cada bot conserva el equipamiento de su especialización base; desde |cffffd200Información -> Equipo|r puedes cambiar de rama o pulsar |cffffd200Autoequipar|r."
L["GUIDE_T6_S1"]    = "El botón |cffffd200Autoequipar|r reajusta la armadura actual del bot, pero al hacerlo su equipo se degradará respecto a sus piezas originales."
L["GUIDE_T6_S2"]    = "Por ello, se recomienda dejar su armadura como está y buscar otro bot que ya cuente con el equipamiento acorde a los talentos que necesitas."
L["GUIDE_T6_S3"]    = "Si el inventario del bot está lleno, es posible que no pueda cambiar el set correctamente al autoequipar por falta de espacio en las bolsas."
L["GUIDE_T6_NOTE"]  = "Si despúes de autoequipar ves el mensaje de |cffffd200inventario|r lleno, puedes liberar espacio de las bolsas."

L["MINIMAP_TITLE"]         = "|cff00ccffDungeon|r|cffffd200Bots|r |cff71d5ff(El Ojo de Mazmorras)|r"
L["MINIMAP_SUB"]           = "Gestor táctico de bots para Mazmorras"
L["MINIMAP_LCLICK"]        = "\n|cffffd200Clic Izquierdo:|r Abrir / Cerrar Panel Principal"
L["MINIMAP_RCLICK"]        = "|cffffd200Clic Derecho:|r Alternar Barra Táctica (HUD)"
L["MINIMAP_DRAG"]          = "|cffffd200Arrastrar:|r Mover este ojo alrededor del minimapa"
L["LFG_EYE_TIP"]           = "Abre el asistente de bots para mazmorras."

-- =========================================================================
-- Modales: Configuracion e Historial
-- =========================================================================
L["MODAL_ACTIVE_SUFFIX"]   = " (Activo)|r"
L["SETTINGS_MODAL_TITLE"]  = "|cff00ccffConfiguración|r |cff888888DungeonBots|r"
L["SET_SHOW_HUD_LABEL"]    = "Mostrar Barra Táctica flotante (HUD)"
L["SET_SHOW_HUD_TITLE"]    = "Barra Táctica Flotante (HUD)"
L["SET_SHOW_HUD_DESC"]     = "Muestra la barra rápida flotante de comandos de combate.\n\nDesmarca esta opción para ocultar esta barra por completo."
L["SET_SHOW_UTIL_LABEL"]   = "Mostrar Barra de Utilidades flotante"
L["SET_SHOW_UTIL_TITLE"]   = "Barra de Utilidades Flotante"
L["SET_SHOW_UTIL_DESC"]    = "Muestra la segunda barra flotante con accesos rápidos para Hablar con PNJ, abrir Bots en el grupo, inspeccionar bolsas, ver Información del Personaje y ver sus misiones.\n\nDesmarca esta opción para ocultar esta barra por completo."
L["SET_DUNGEON_ONLY_LBL"]  = "Mostrar barras flotantes solo dentro de mazmorras de 5 jugadores"
L["SET_DUNGEON_ONLY_TTL"]  = "Solo en Mazmorras de 5 Jugadores"
L["SET_DUNGEON_ONLY_DSC"]  = "Cuando está activa, las barras flotantes (Táctica y Utilidades) se ocultan fuera de mazmorras de 5 jugadores y aparecen automáticamente al entrar."
L["SET_MUTE_WHISPER_LBL"]  = "Ocultar susurros de bots en el chat"
L["SET_MUTE_WHISPER_TTL"]  = "Ocultar Susurros de Bots"
L["SET_MUTE_WHISPER_DSC"]  = "Oculta todos los susurros entrantes y salientes con cualquier personaje identificado como bot.\n\nLos jugadores humanos reales ([JUGADOR] o desconocidos) NUNCA se ocultan."
L["SET_MUTE_GROUP_LBL"]    = "Ocultar también mensajes de bots en Grupo (/p), Grito (/y) y Decir (/s)"
L["SET_MUTE_GROUP_TTL"]    = "Ocultar Chat de Grupo/Decir de Bots"
L["SET_MUTE_GROUP_DSC"]    = "También filtra los mensajes públicos de bots en canales de Grupo (/p), Grito (/y) y Decir (/s)."

L["SET_BAR_HUD"]           = "Barra táctica (HUD)"
L["SET_BAR_UTIL"]          = "Barra de Utilidades"
L["SET_MSG_DUNG_ONLY"]     = "Barras flotantes solo en mazmorra (5j): %s"
L["SET_MSG_MUTE_WHISP"]    = "Ocultar susurros de bots: %s"
L["SET_MSG_MUTE_GROUP"]    = "Ocultar chat de bots en Grupo/Decir: %s"
L["SET_THEME_LABEL"]       = "|cffffd200Tema visual:|r"
L["SET_THEME_CHANGED"]     = "Tema de interfaz cambiado a: %s"
L["SET_THEME_DARK_TITLE"]  = "Tema: Oscuro Azulado"
L["SET_THEME_DARK_DESC"]   = "Variante oscura azulada y acero con textura de piedra Blizzard y bordes plateados."
L["SET_THEME_GOLD_TITLE"]  = "Tema: Dorado"
L["SET_THEME_GOLD_DESC"]   = "Estilo clásico Blizzard WotLK con bordes dorados tallados y paneles piedra/bronce cálidos."
L["SETTINGS_FOOTER_VER"]   = "|cff888888v%s|r"
L["SETTINGS_DISCORD_ERR"]  = "|cff999999Si hay algún error, puedes contactar con |r|cff71d5ff@Shahak|r|cff999999 por Discord.|r"

L["CLEAR_HIST_CONFIRM"]    = "¿Seguro que quieres borrar todo el historial de bots guardados?"
L["CLEAR_HIST_YES"]        = "Sí, limpiar"
L["DEL_HIST_TIP_TITLE"]    = "Eliminar del historial"
L["DEL_HIST_TIP_DESC"]     = "Borra este bot de la lista guardada."
L["DEL_HIST_IN_PARTY_DESC"]= "No se puede quitar mientras el bot esté en tu grupo."
L["HIST_MODAL_TITLE"]      = "|cff00ccffHistorial de|r |cffffd200bots|r"
L["HIST_TOTAL_ZERO"]       = "Total guardados: |cffffd2000|r"
L["HIST_TOTAL_FMT"]        = "Total guardados: |cffffd200%d|r"
L["HIST_CLEAR_ALL"]        = "Limpiar Todo"
L["HIST_EMPTY_TEXT"]       = "Aún no tienes bots registrados en el historial.\n\nInvoca bots con 'Armar Grupo' y cambia sus talentos en 'Bots en el grupo' para verlos guardados aquí."
L["HIST_ADD_LABEL"]        = "Nombre:"
L["BTN_ADD_BOT"]           = "Agregar"
L["HIST_ADD_MANUAL_TIP"]   = "Invoca e invita manualmente a un bot escribiendo su nombre."
L["HIST_IN_PARTY_TAG"]     = "  |cff34c759[En Grupo]|r"
L["HIST_DEFAULT_TALENTS"]  = "|cff999999Talentos por defecto|r"
L["HIST_IN_PARTY_BTN"]     = "En Grupo"
L["HIST_ALREADY_TITLE"]    = "Ya está en tu grupo"
L["HIST_ALREADY_DESC"]     = "%s ya se encuentra unido al grupo actual."
L["HIST_INVITE_TITLE"]     = "Invitar a %s"
L["HIST_INVITE_DESC"]      = "Invoca a %s y lo invita a tu grupo automáticamente."
L["HIST_TAB1_NAME"]        = "Historial de Bots"
L["HIST_TAB1_TIP"]         = "Consulta tus bots anteriores, invítalos uno por uno o haz clic derecho para guardarlos en un equipo."
L["HIST_TAB2_NAME"]        = "Equipos de Bots"
L["HIST_TAB2_TIP"]         = "Organiza hasta 3 equipos armados e invoca un grupo completo con un solo clic."
L["HIST_RIGHT_CLICK_HINT"] = "|cff888888Consejo: Clic derecho en un bot para asignarlo a Equipo 1, 2 o 3.|r"
L["HIST_ROW_RIGHT_CLICK_TIP"] = "Clic derecho: Asignar o quitar de Equipo 1 / 2 / 3"
L["HIST_MENU_TEAM_FMT"]    = "Equipo %d"
L["HIST_TEAM_TITLE_FMT"]   = "Equipo %d"
L["HIST_TEAM_EMPTY"]       = "Sin bots guardados.\n\nHaz clic derecho en un bot\ndel Historial para agregarlo."
L["HIST_TEAM_SUMMON_BTN"]  = "Invocar Equipo"
L["HIST_TEAM_ALL_IN_PARTY"]= "Ya en el grupo"
L["HIST_TEAM_SUMMON_TIP"]  = "Invoca e invita al grupo a los bots guardados en Equipo %d."
L["HIST_TEAM_REMOVE_TIP"]  = "Quitar del equipo"
L["HIST_TEAM_ADDED_FMT"]   = "|cffffd200%s|r guardado en |cff71d5ffEquipo %d|r."
L["HIST_TEAM_REMOVED_FMT"] = "|cffffd200%s|r quitado de |cff71d5ffEquipo %d|r."
L["HIST_TEAM_FULL_FMT"]    = "|cff71d5ffEquipo %d|r ya está completo (máximo 4 bots)."
L["HIST_TEAM_NO_SLOTS"]    = "No hay espacios libres en el grupo para invocar bots de |cff71d5ffEquipo %d|r."
L["HIST_TEAM_SUMMONING_FMT"]= "Invocando |cff71d5ffEquipo %d|r (%d bot(s))..."
L["HIST_TEAM_FOOTER_HINT"] = "|cff888888Clic derecho en un bot del Historial para armar tus equipos.|r"

-- =========================================================================
-- Ventanas de Misiones y Dialogo PNJ
-- =========================================================================
L["QUEST_DROP_CONFIRM"]    = "¿Seguro que quieres abandonar esta misión con |cffffd200%s|r?\n\n%s\n\n|cffff3b30Se ordenará al bot abandonar la misión.|r"
L["QUEST_WIN_DEFAULT"]     = "|cff00ccffMisiones:|r |cffffd200Bot|r"
L["QUEST_WIN_FMT"]         = "|cff00ccffMisiones:|r |cffffd200%s|r"
L["QUEST_ACTIVE_ZERO"]     = "Misiones activas: |cffffd2000|r"
L["QUEST_ACTIVE_FMT"]      = "Misiones activas: |cffffd200%d|r"
L["QUEST_ACTIVE_STALE"]    = "  |cffff9f0a(sin respuesta; lista previa)|r"
L["QUEST_ACTIVE_HINT"]     = "  |cff888888(clic para ver detalles)|r"
L["QUEST_NONE_ACTIVE"]     = "Este bot no tiene misiones activas."
L["QUEST_QUERY_STATUS"]    = "|cff71d5ffConsultando misiones activas...|r"
L["QUEST_QUERY_WAIT_FMT"]  = "|cff71d5ffConsultando misiones de %s...|r\n\n|cff888888Espera un instante mientras responde.|r"
L["QUEST_NO_RESP_TITLE"]   = "|cffff9f0aSin respuesta de %s|r"
L["QUEST_NO_RESP_BODY"]    = "No se recibió respuesta de %s."
L["NORESP_DEAD_HINT"]      = "Revive o invoca al bot y pulsa 'Actualizar'."
L["NORESP_OOS_DETAIL"]     = "%s está muy lejos, en otra zona/instancia o en otra fase."
L["NORESP_OOS_HINT"]       = "Asegúrate de que esté cerca y en la misma estancia (usa 'Summon' o llámalo) y pulsa 'Actualizar'."
L["NORESP_FAR_HINT"]       = "Asegúrate de que esté cerca (usa 'Seguir' o 'Summon') y pulsa 'Actualizar'."
L["NORESP_NEAR_HINT"]      = "El bot puede estar ocupado o filtrando comandos repetidos.\nAsegúrate de que esté cerca y en la misma estancia, y pulsa 'Actualizar' en unos segundos."
L["QUEST_ID_CLICK_FMT"]    = "|cff777777ID: %s (clic para inspeccionar)|r"
L["QUEST_CLICK_DETAIL"]    = "|cff777777Clic para ver detalle|r"
L["QUEST_STATUS_PREFIX"]   = "Estado: "
L["QUEST_OPEN_DETAIL_TIP"] = "Haz clic para abrir el detalle de la misión."
L["QUEST_SHARE_TIP"]       = "Se compartirá la misión con jugadores y bots. Los bots solo aceptarán si el jugador que los invocó acepta la misión"
L["QUEST_DROP_TIP"]        = "Abandonarás la misión con este bot"
L["QUEST_NEXT_BOT_TIP"]    = "Pasa al siguiente bot del grupo para ver sus misiones (%s)."
L["QUEST_NEED_2_BOTS"]     = "Se necesitan al menos 2 bots en el grupo para pasar al siguiente."

L["DUNG_TIP_STATUS_WAIT"]  = "Estado: |cffaaaaaaConsultando al servidor...|r"
L["DUNG_TIP_CLICK_QUERY"]  = "Haz clic para solicitar la información de acceso actualizada."
L["DUNG_TIP_BOT_OK"]       = "%s: |cff00ff00Puede ir|r"
L["DUNG_TIP_BOT_MISS"]     = "%s: |cffff4444Falta misión previa|r"
L["DUNG_TIP_BOT_NOTIN"]    = "%s: |cffaaaaaaNo está en el grupo actual|r"
L["DUNG_PREV_FALLBACK"]    = "Mazmorra anterior"
L["DUNG_REQ_CHAIN_FMT"]    = "Requiere cadena previa: |cffffd200%s|r"
L["DUNG_BOT_STATUS_HDR"]   = "Estado de los bots:"
L["DUNG_CUR_TAG"]          = " |cff88ccff(Actual)|r"
L["DUNG_LINE_FMT"]         = "  - %s: %s"
L["DUNG_NO_BOTS_IN_GRP"]   = "|cff888888No hay bots en el grupo actual.|r"
L["DUNG_CLICK_REFRESH"]    = "|cff888888Clic para actualizar desde el servidor.|r"

L["TALK_WIN_DEFAULT"]      = "|cff00ccffDiálogo PNJ:|r |cffffd200Bot|r"
L["TALK_WIN_FMT"]          = "|cff00ccffDiálogo PNJ:|r |cffffd200%s|r"
L["TALK_NPC_DEFAULT"]      = "PNJ: |cffffd200Objetivo actual|r"
L["TALK_NPC_SELECTED"]     = "PNJ seleccionado"
L["TALK_NPC_FMT"]          = "PNJ: |cffffd200%s|r  %s"
L["TALK_OPTIONS_HDR"]      = "|cffffd200Opciones y Misiones del PNJ:|r"
L["TALK_WAIT_NPC"]         = "Esperando respuesta del PNJ..."
L["TALK_NEXT_BOT_TIP"]     = "Pasa al siguiente bot del grupo para hablar con el PNJ (%s)."
L["TALK_QUEST_LOG_BTN"]    = "Registro Misiones"
L["TALK_QUEST_LOG_TIP"]    = "Registro de Misiones del Bot"
L["TALK_QUEST_LOG_FOR"]    = "Abre la ventana de Misiones para %s."
L["TALK_QUEST_LOG_SEL"]    = "Abre la ventana de Misiones del bot seleccionado."
L["TALK_TAG_AVAILABLE"]    = "|cff34c759[Disponible]|r "
L["TALK_TIP_AVAILABLE"]    = "El bot puede tomar esta misión. Pulsa 'Aceptar' o haz clic para inspeccionarla."
L["TALK_TAG_INPROGRESS"]   = "|cffff9f0a[En curso]|r "
L["TALK_LBL_INPROGRESS"]   = "En curso"
L["TALK_TIP_INPROGRESS"]   = "El bot ya lleva esta misión. Clic en el nombre para ver detalles, o pulsa 'Abandonar'."
L["TALK_TAG_COMPLETE"]     = "|cff00ccff[Completa]|r "
L["TALK_LBL_COMPLETE"]     = "Completa (Lista para entregar)"
L["TALK_TIP_COMPLETE"]     = "Objetivos completos. Pulsa 'Entregar' o haz clic para ver detalles."
L["TALK_TAG_UNAVAIL"]      = "|cff888888[No disponible]|r "
L["TALK_LBL_LOCKED"]       = "|cff888888Bloqueada|r"
L["TALK_LBL_UNAVAIL"]      = "No disponible"
L["TALK_TIP_UNAVAIL"]      = "El bot aún no puede tomar esta misión. Clic para ver detalles."
L["TALK_TAG_QUEST"]        = "|cffffd200[Misión]|r "
L["TALK_TIP_QUEST"]        = "Clic para ver la descripción de la misión."
L["TALK_STATE_QUERYING"]   = "|cff71d5ff[Consultando...]|r"
L["TALK_STATE_READY"]      = "|cff34c759[Listo]|r"
L["TALK_FAR_ERR_FMT"]      = "|cffff5544%s está demasiado lejos del PNJ.|r\n\nAcércalo al PNJ (usa |cffffd200Seguir|r o |cffffd200Summon|r) y pulsa |cffffd200'Reconsultar'|r."
L["TALK_FAR_WAIT_FMT"]     = "|cffff7b30%s está lejos.|r\n\n|cffaaaaaaConsultando a %s... Si no aparece nada, acércalo con 'Seguir' o 'Summon' y pulsa 'Reconsultar'.|r"
L["TALK_ACCEPTING_FMT"]    = "|cff71d5ffAceptando misión con %s...|r"
L["TALK_QUERYING_OPT_FMT"] = "|cff71d5ffConsultando opciones y misiones del PNJ con %s...|r"
L["TALK_QUEST_ACCEPTED"]   = "|cff34c759Misión aceptada.|r Actualizando diálogo del PNJ..."
L["TALK_ACCEPT_FAIL_FMT"]  = "|cffff5544No se pudo aceptar la misión:|r\n\n|cffffaaaa%s|r"
L["TALK_TOO_FAR_SHORT"]    = "|cffff5544%s está demasiado lejos.|r\n\nAcércalo al PNJ (usa |cffffd200Seguir|r o |cffffd200Summon|r) y pulsa |cffffd200'Reconsultar'|r."
L["TALK_NO_OPTS_MID"]      = "No se detectaron opciones ni misiones disponibles.\n|cffffd200%s está a media distancia (12-28 m); puede necesitar acercarse más al PNJ y pulsar 'Reconsultar'.|r"
L["TALK_NO_OPTS_NEAR"]     = "No se detectaron opciones ni misiones disponibles.\nAsegúrate de tener seleccionado un PNJ cerca de %s y pulsa 'Reconsultar'."
L["TALK_OPTION_FMT"]       = "|cff00ccff>|r |cffffe599%s|r"
L["TALK_OPTION_DEFAULT"]   = "Opción"
L["TALK_OPT_TIP_TITLE"]    = "Seleccionar opción"
L["TALK_OPT_TIP_DESC"]     = "Haz clic para elegir esta opción con el bot."

-- =========================================================================
-- Ventana de Inventario
-- =========================================================================
L["INV_DESTROY_CONFIRM"]   = "¿Seguro que quieres ordenar a |cffffd200%s|r destruir este objeto?\n\n%s\n\n|cffff3b30Esta acción no se puede deshacer.|r"
L["INV_TIP_WAIT_SRV"]      = "Esperando información del servidor..."
L["INV_TIP_QTY_FMT"]       = "Cantidad en bolsa: |cffffffff%s|r"
L["INV_TIP_SEC_FMT"]       = "Sección: |cffaaaaaa%s|r"
L["INV_TIP_ACTIONS"]       = "Clic izquierdo: |cffffffffSeleccionar|r  |  Clic derecho: |cffff3b30Destruir|r"
L["INV_WIN_DEFAULT"]       = "|cff00ccffInventario:|r |cffffd200Bot|r"
L["INV_WIN_FMT"]           = "|cff00ccffInventario:|r %s%s|r"
L["INV_BAGS_QUERYING"]     = "Bolsas: |cff888888Consultando...|r"
L["INV_BAGS_FREE_FMT"]     = "Bolsas: %s%d/%d|r libres"
L["INV_NEXT_BOT_TIP"]      = "Pasa al siguiente bot del grupo para ver su inventario."
L["INV_DESTROY_TIP_TITLE"] = "Destruir objeto seleccionado"
L["INV_DESTROY_TIP_DESC"]  = "Ordena al bot destruir el objeto seleccionado tras confirmar."
L["INV_STATUS_QUERY_FMT"]  = "Consultando el inventario de |cffffd200%s|r..."
L["INV_STATUS_NORESP_FMT"] = "No se recibió respuesta de |cffffd200%s|r al consultar su inventario."
L["INV_STATUS_EMPTY_FMT"]  = "|cffffd200%s|r no tiene objetos visibles en sus bolsas."
L["INV_STATUS_NOMATCH_FMT"]= "Ningún objeto coincide con \"%s\"."

-- =========================================================================
-- Ventana de Personaje (Equipo / Hechizos / Glifos)
-- =========================================================================
L["CHAR_TAB_GEAR"]         = "Equipo"
L["CHAR_TAB_SPELLS"]       = "Hechizos"
L["CHAR_TAB_GLYPHS"]       = "Glifos"
L["CHAR_WIN_DEFAULT"]      = "|cffb266ffPersonaje:|r"
L["CHAR_WIN_FMT"]          = "|cffb266ffPersonaje:|r %s%s|r"
L["CHAR_SPEC_SECTION"]     = "|cff71d5ffRama de Talentos|r"
L["CHAR_SPEC_SUB"]         = "|cff9aa5b4Elige la especialización que utilizará el bot:|r"
L["CHAR_SPEC_EMPTY"]       = "|cff888888Sin ramas cargadas todavía.|r"
L["CHAR_SPEC_ACTIVE_FMT"]  = "%s%s (Activa)|r"
L["CHAR_SPEC_TIP_TITLE"]   = "Cambiar rama a %s"
L["CHAR_SPEC_TIP_DESC"]    = "Cambia la especialización activa de %s a %s."

L["CHAR_GEAR_SECTION"]     = "|cffffd200Gestión de Equipo|r"
L["CHAR_GEAR_SUB"]         = "|cff9aa5b4Ajuste rápido del equipamiento actual del bot:|r"
L["CHAR_AUTOGEAR_BTN"]     = "Autoequipar"
L["CHAR_AUTOGEAR_DESC"]    = "|cffff5555Advertencia:|r Si usas esta opción, la armadura actual del bot se degradará.\n\n|cffffd200Recomendación:|r Es mejor dejar su equipo como está y buscar otro bot que ya tenga el equipamiento acorde a los talentos que necesita."
L["CHAR_AUTOGEAR_TIP_DESC"]= "Aplica el autoequipamiento al bot actual."
L["CHAR_AUTOGEAR_TIP_WARN"]= "\nAdvertencia: La armadura actual se degradará. Se recomienda dejar su equipo como está y buscar otro bot que ya cuente con el equipamiento de los talentos que necesitas."

L["SPELL_BUY_TAG"]         = " |cff34c759(compra)|r"
L["SPELL_MAT_PREFIX"]      = "|cffaaaaaaMat.:|r "
L["SPELL_MANA"]            = "maná"
L["SPELL_RAGE"]            = "ira"
L["SPELL_FOCUS"]           = "enfoque"
L["SPELL_ENERGY"]          = "energía"
L["SPELL_RUNIC"]           = "poder rúnico"
L["SPELL_COST"]            = "coste"
L["SPELL_TYPE_GLYPHS"]     = "glifos"
L["SPELL_TYPE_SPELLS"]     = "hechizos"
L["SPELL_INSTANT"]         = "Instantáneo"
L["SPELL_CAST_SEC_FMT"]    = "%.1f s"
L["SPELL_RANGE_YD_FMT"]    = "%d m"
L["SPELL_TIP_TYPE_FMT"]    = "Tipo: %s"
L["SPELL_TIP_SHIFT_CHAT"]  = "Shift + Clic: |cffffffffInsertar enlace en el chat|r"
L["SPELL_TIP_MATS"]        = "Materiales:"
L["SPELL_TIP_VENDOR"]      = " (vendedor)"
L["SPELL_TIP_DIFF_FMT"]    = "Dificultad: %s"
L["SPELL_TIP_ACTIONS"]     = "Clic izquierdo: |cffffffffSeleccionar|r  |  Shift + Clic: |cff71d5ffEnlazar|r"
L["SPELL_BTN_CAST"]        = "Lanzar"
L["SPELL_CAST_TIP_TITLE"]  = "Lanzar hechizo"
L["SPELL_CAST_TIP_DESC"]   = "Ordena al bot seleccionado lanzar el hechizo elegido."
L["SPELL_CANCEL_TIP_TTL"]  = "Cancelar hechizo"
L["SPELL_CANCEL_NOW_FMT"]  = "Casteando ahora: |cffffd200%s|r"
L["SPELL_CANCEL_CLICK"]    = "Haz clic para detener el lanzamiento actual del bot."
L["SPELL_CANCEL_IDLE"]     = "Detiene el lanzamiento actual del bot (se ilumina y habilita cuando está casteando o canalizando)."
L["SPELL_QUERYING_FMT"]    = "Consultando %s de |cffffd200%s|r..."
L["SPELL_NO_GLYPHS_FMT"]   = "No se recibieron glifos para |cffffd200%s|r."
L["SPELL_NO_SPELLS_FMT"]   = "No se recibieron poderes para |cffffd200%s|r."
L["SPELL_NOMATCH_FMT"]     = "Ningún poder coincide con \"%s\"."
L["GLYPH_EQUIPPED_HINT"]   = "|cff8899aaGlifo equipado  |  Pasa el ratón para ver detalles|r"
L["SPELL_ROW_HINT"]        = "|cff667788Clic izq.: seleccionar  |  Shift + Clic: enlazar|r"

-- =========================================================================
-- Diccionario visual de ramas y clases devueltas por mod-playerbots
-- =========================================================================
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
