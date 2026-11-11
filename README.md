# DungeonBots — Tactical Dungeon Bot Assistant (WoW 3.3.5a)

**DungeonBots** is a lightweight World of Warcraft 3.3.5a (`Interface: 30300`) addon designed for players using `mod-playerbots` / Playerbots in 5-player dungeons. It provides a modular, visual interface to summon, invite, configure, inspect, gear, and direct party bots without typing chat commands manually.

---

## Key Features

### 1. Client-Language Localization (`GetLocale()`)
* **Automatic Hyperlink Localization:** Quest titles (`|Hquest:...|h`), item links (`|Hitem:...|h`), and spells (`|Hspell:...|h`) returned by bots in Quest Log, NPC Talk dialogs, tooltips, chat notifications, and visible bot whispers automatically resolve in your WoW client's configured language (`esES`, `esMX`, etc.). Uncached quests and items automatically trigger client WDB queries and update open dialogs in place once cached.
* **Localized Classes, Specs & Targets:** Party cards, spec dropdowns, and Bot History display localized class names (`_G.LOCALIZED_CLASS_NAMES_MALE`) and localized talent spec names (`esES`/`esMX`) while keeping canonical command tokens (`talents spec`, `accept`, `drop`, `talk`) untouched so bot commands always execute cleanly. When targeting an NPC, the client's localized `UnitName("target")` is preferred over English server whisper headers. *(Plain-text NPC gossip without IDs/links remains unmodified due to WoW 3.3.5a client limitations.)*

---

### 2. Party Builder (`Armar Grupo` — Tab 1)
* **Bot History (`Historial de bots` / `Ver Historial de bots`):** Automatically records bots you group with (name, class, race/gender portrait, and last known talent spec). Open the history window to individually summon & invite previous bots (`Invitar`, runs `.playerbots bot add <name>` + party invite), remove individual entries, or clear the list.
* **Summon by Class (`Invocar Bot por Clase Individual`):** 10 class buttons that run `.playerbots bot addclass <class>`.
* **Smart Auto-Invite & Human Safety:** Newly summoned bots that whisper on creation (within the summon window, when party size < 5) are invited automatically. Real players are never treated as bots unless explicitly confirmed or toggled.
* **Settings Modal (Header Gear Icon):**
  * Independently show or hide the Floating Combat HUD and the Floating Utility Bar (both enabled by default) and toggle hiding floating bars outside 5-player dungeons (`IsInInstance() == "party"`, enabled by default).
  * **Bot Whisper Hiding:** Toggle hiding all incoming and outgoing whispers with known bots (compatible with Blizzard chat and WIM without touching WIM's SavedVariables); when enabled, reveals an additional option to also hide bot messages in `/p`, `/y`, and `/s`. Real human players (`[JUGADOR]` or unknown players) are never filtered.
* **Global Group Controls:**
  * **`Reinvocar Grupo`:** Runs `.playerbots bot add *` + `/p summon` to recall absent bots that are still in your party.
  * **`Despedir a Todos`:** Runs `.playerbots bot remove *` and removes confirmed bots from the party while preserving human players.
  * **`Reparar Equipo`:** Sends `/p repair`.
  * **`Liberar alma`:** Sends `/p release` (note: bots release spirit at the graveyard).

---

### 3. Party Bot Manager (`Bots en el grupo` — Tab 2)
Displays one tactical card per party slot (`party1` to `party4`):
* **Bot vs. Human Identification (`¿Quién es bot?`):** Probes unverified party members via discreet `follow info` whispers or lets you click the `[ BOT ]` / `[ JUGADOR ]` badge directly to toggle protection for human friends.
* **Race & Gender Portraits:** Displays matching character icons per race and sex.
* **Automatic Live Spec Detection & Switching:**
  * Whenever a bot joins the party (including staggered/late joins via `PARTY_MEMBERS_CHANGED` and `UNIT_NAME_UPDATE`), DungeonBots queues staggered whisper queries (`talents spec list` and `talents`) with automatic retry and fallback so each bot's dropdown populates with real server specs and active specialization.
  * Selecting any spec from the dropdown switches the bot via `talents spec <spec>`.
* **Gear Controls (Below Dropdown):**
  * **`Adaptar Equipo`:** Whispers `autogear match` to adapt gear to the active talent spec (includes an item level warning tooltip).
  * **`Equipar Azul`:** Whispers `autogear blue` to equip rare quality gear.
* **Quests & Dismiss (Right Column):**
  * **`Misiones`:** Silently queries `quests all` and opens the interactive **Quest Dialog** showing all active quests (or an empty notice when none are active). Click any quest to inspect its details, or click `Abandonar` to send `drop`, play `igQuestFailed`, and automatically refresh the list.
  * **`Despedir`:** Dismisses the bot (`.playerbots bot remove <name>`) and uninvites it from the party if needed.
* **NPC Talk Dialog (`talk`):**
  * Selecting an NPC and querying `talk` (via HUD **Hablar PNJ**, `/w <bot> talk`, `/p talk`, `/s talk`, or `/db talk [bot]`) captures the reply out of chat/WIM and opens an interactive **NPC Dialog** window with clickable gossip options (`talk 0` / `talk #n`), quest accept/turn-in/abandon buttons (`Aceptar`, `Entregar`, `Abandonar`), sequential party bot cycling (**`Siguiente Bot`** with `(index/total)` indicator), **`Reconsultar`**, and **`Registro Misiones`**.

---

### 4. ICC 5-Man Quest Assistant (`Forja / Foso / Cámaras` — Tab 3)
Automates the Forge of Souls -> Pit of Saron -> Halls of Reflection quest chain under the 60-second out-of-dungeon bot timer:
1. **60s Dalaran Countdown Bar:** Color-coded progress bar (`green -> yellow -> red`) with a sound warning at 15 seconds remaining.
2. **Step 1 (`Dalaran`):** Target the quest NPC and press the Step 1 button (`/p summon` + `/p accept *` + starts the 60s timer).
3. **Step 2 (`Entrada a Forja`):** Enter the dungeon portal and press Step 2 (`.playerbots bot add *` + `/p summon`).
4. **Step 3 (`Entregar y Continuar`):** Target the NPC inside the instance to turn in and accept the next quest (`/p accept *`), plus a quick **`Verificar Misiones`** (`/p quests`) button.

---

### 5. Floating Combat Bar & Utility Bar
Both floating bars are draggable, independently lockable, individually toggleable in Settings (gear icon, both enabled by default), and share the 5-player dungeon visibility toggle:

#### Floating Combat HUD (`Barra Táctica`)
Compact bar (plus quick lock toggle and main panel book button) with 6 party combat actions sent to `/p`:
1. **Focus Target:** `do attack my target`
2. **Pull con Tanque:** `pull my target`
3. **Quedarse:** `stay`
4. **Seguir:** `follow`
5. **Summon:** `summon`
6. **¡Huir!:** `flee`

#### Floating Utility Bar (`Barra de Utilidades`)
Positioned cleanly above the Tactical HUD by default:
1. **Hablar PNJ:** `talk` (opens a bot selector dropdown if 2+ party bots are present, or queries the single bot directly and opens the interactive NPC Talk dialog; visually dimmed when no living non-player NPC is targeted while keeping its hover tooltip active).
2. **Bots en el Grupo:** Opens the main `DungeonBots` window directly onto Tab 2 (`Bots en el grupo`).
3. **Inventario de Bot:** Opens a party bot dropdown selector (`c`) and opens the **Bot Inventory / Bag Viewer**, rendering bag items in a visual grid with quality-colored borders, stack counts, search filter, localized tooltips, sequential party bot cycling (**`Siguiente Bot`** with `(index/total)` indicator), and verified item destruction (`destroy [itemLink]` normalized to client 3.3.5a link format; no trade UI).
4. **Poderes de Bot:** Opens a party bot dropdown selector (`spells`) and opens the **Bot Powers / Spellbook Viewer** with 4 sub-tabs (**`Hechizos`**, **`Glifos`**, **`Entrenador`**, **`Stats`**), native `GetSpellInfo` / tooltip integration, reagent parsing (with item localization & buyable tags), local search, server `spells <filter>` querying (`<name>`, `<profession>`, `+<profession>`, `20-40`, `<slot>`), **`Detalle`** (`spell [link]`), **`Lanzar`** (`cast [link]`), shortcut to **`Talentos`**, and sequential party bot cycling (**`Siguiente Bot`**).

---

## Architecture (Modular Files)

- `DungeonBots.toc` — Module manifest (`30300`)
- `DungeonBots.lua` — Core namespace, defaults, data tables, shared helpers
- `DungeonBots_Locale.lua` — Client-language localization and async WDB resolution
- `DungeonBots_Roster.lua` — Bot detection, summoning, dismissing, and Bot History
- `DungeonBots_Comms.lua` — Chat command dispatch, staggered queue, filters, and WIM hooks
- `DungeonBots_Talents.lua` — Talent parsing, live queries, spec switching, and autogear
- `DungeonBots_Quests.lua` — Quest Log & Talk capture engine plus Dalaran timer helpers
- `DungeonBots_Inventory.lua` — Bot bag query (`c`), whisper parser, and `destroy` dispatcher
- `DungeonBots_Spells.lua` — Bot `spells`/`spell`/`cast`/`glyphs`/`trainer`/`stats` query & parser engine
- `DungeonBots_Events.lua` — WoW event dispatcher and slash commands
- `DungeonBots_HUD.lua` — Floating Combat Tactical HUD and Floating Utility Bar
- `DungeonBots_UI.lua` — Main 3-tab UI frame, minimap icon, and LFD eye hooks
- `DungeonBots_Modals.lua` — Settings and Bot History modal windows
- `DungeonBots_QuestTalkUI.lua` — Quest Log and NPC Talk modal windows
- `DungeonBots_InventoryUI.lua` — Bag-grid Bot Inventory window and item destruction confirmation
- `DungeonBots_SpellsUI.lua` — Interactive Bot Powers window (`spells`, `glyphs`, `trainer`, `stats`, `spell`, `cast`)

---

## Shortcuts & Slash Commands

* **Minimap Eye Button:**
  * **Left Click:** Open / close the main DungeonBots window.
  * **Right Click:** Show / hide the floating Combat HUD.
  * **Drag:** Reposition around the minimap.
* **LFD Integration:**
  * **Right Click** on `LFDMicroButton` opens DungeonBots.
  * **`DungeonBots` button** embedded on `LFDParentFrame`.
* **Slash Commands (`/db`, `/dungeonbots`, `/bots`, `/playerbot`):**
  * `/db` — Toggle main window.
  * `/db hud` — Toggle the floating Combat HUD.
  * `/db talk [bot]` — Query a bot's current NPC dialog (`talk`) and open the NPC Talk dialog.
  * `/db inv [bot]` — Query a bot's bags (`c`) and open the Bot Inventory window.
  * `/db spells [bot] [filter]` — Query a bot's active spells/recipes (`spells` or `spells <filter>`) and open the Bot Powers window.
  * `/db dalaran` — Trigger the Dalaran prep step.
  * `/db addall` — Recall all bots (`.playerbots bot add *`).
  * `/db dismiss` (or `/db removeall`) — Dismiss all bots (`.playerbots bot remove *`).
  * `/db reset` — Reset both floating bars (Combat HUD & Utility Bar) to bottom-center.
