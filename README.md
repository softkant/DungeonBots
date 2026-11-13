# DungeonBots — Tactical Dungeon Bot Assistant (WoW 3.3.5a)

**DungeonBots** is a lightweight World of Warcraft 3.3.5a (`Interface: 30300`) addon designed for players using the **[mod-playerbots](https://github.com/mod-playerbots/mod-playerbots/)** module (`https://github.com/mod-playerbots/mod-playerbots/`) in 5-player dungeons. It provides a modular, visual interface to summon, invite, configure, inspect, gear, and direct party bots without typing chat commands manually.

---

## Key Features

### 1. Client-Language Localization (`GetLocale()`)
* **Automatic Hyperlink Localization:** Quest titles (`|Hquest:...|h`), item links (`|Hitem:...|h`), and spells (`|Hspell:...|h`) returned by bots in Quest Log, NPC Talk dialogs, tooltips, chat notifications, and visible bot whispers automatically resolve in your WoW client's configured language (`esES`, `esMX`, etc.). Uncached quests and items automatically trigger client WDB queries and update open dialogs in place once cached.
* **Localized Classes, Specs & Targets:** Party cards, spec dropdowns, and Bot History display localized class names (`_G.LOCALIZED_CLASS_NAMES_MALE`) and localized talent spec names (`esES`/`esMX`) while keeping canonical command tokens (`talents spec`, `accept`, `drop`, `talk`) untouched so bot commands always execute cleanly. When targeting an NPC, the client's localized `UnitName("target")` is preferred over English server whisper headers. *(Plain-text NPC gossip without IDs/links remains unmodified due to WoW 3.3.5a client limitations.)*

---

### 2. Party Builder (`Armar Grupo` — Tab 1)
* **Bot History (`Historial de Bots` / `Historial/Agregar`):** Automatically records bots you group with (name, class, race/gender portrait, and last known talent spec). Open the history window to individually summon & invite previous bots (`Invitar`, runs `.playerbots bot add <name>` + party invite), manually add any bot by typing its name in the bottom-left `Nombre` + `Agregar` input, remove individual entries, or clear the list.
* **Summon by Class (`Invocar Bot por Clase Individual`):** 10 class buttons that run `.playerbots bot addclass <class>`.
* **LFD Backfill Queue Guard (`LFG_UPDATE`):** If the Dungeon Finder Eye enters replacement search (`"queued"`, after accepting "Find another player"), DungeonBots notifies you and blocks `addclass` so you add bots directly via **Bot History** instead.
* **Smart Auto-Invite & Human Safety:** Newly summoned bots that whisper on creation (within the summon window, when party size < 5) are invited automatically. Real players are never treated as bots unless explicitly confirmed or toggled.
* **Floating Bar Lock Toggle (Header Lock Icon next to Settings):**
  * Single lock button next to the header gear icon controlling **both** floating bars together: **green** = unlocked (both bars can be dragged), **gray** = locked (both bars fixed in place).
* **Settings Modal (Header Gear Icon):**
  * **Visual Theme:** Switch live between **Dorado** (classic WotLK gold, default on first launch) and **Oscuro Azulado** (dark slate-blue steel).
  * Independently show or hide the Floating Combat HUD and the Floating Utility Bar (both enabled by default) and toggle hiding floating bars outside 5-player dungeons (`IsInInstance() == "party"`, enabled by default).
  * **Bot Whisper Hiding:** Toggle hiding all incoming and outgoing whispers with known bots (compatible with Blizzard chat and WIM without touching WIM's SavedVariables); when enabled, reveals an additional option to also hide bot messages in `/p`, `/y`, and `/s`. Real human players (`[JUGADOR]` or unknown players) are never filtered.
  * **Version & Support:** Shows `v1.0.0` next to the header title and a Discord contact notice (`@Shahak`) at the bottom-left for reporting issues.
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
  * **`Misiones`:** Silently queries `quests all` (with automatic retry and proximity/instance/phase diagnostics on timeout) and opens the interactive **Quest Dialog** showing all active quests (or an empty notice when none are active), plus live per-bot access status for **Pit of Saron** and **Halls of Reflection** (`(Actual)` highlights the active bot as you cycle with `Siguiente Bot`). Click any quest to inspect its details, or click `Abandonar` to send `drop`, play `igQuestFailed`, and automatically refresh the list.
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
Both floating bars are draggable, locked/unlocked together from the padlock button next to the Settings gear on the main window header (**green** = movable, **gray** = locked), individually toggleable in Settings (gear icon, both enabled by default), and share the 5-player dungeon visibility toggle:

#### Floating Combat HUD (`Barra Táctica`)
Compact bar with 8 party combat & formation actions sent to `/p`:
1. **Atacar al objetivo (`Focus Target`):** Orders `@dps` to focus your target (with configurable right-click delay `0 / 2 / 5 / 8s`, default `2s`; only sends `follow` beforehand if bots are flagged in `flee` state; `@heal` uses `0s`).
2. **Pull con Tanque (`Pull`):** Orders `@tank pull` with configurable right-click engage delay (`4 / 6 / 8 / 12s`, default `6s`; `@dps` joins after the timer while `@heal` uses `0s`).
3. **Quedarse:** `reset` + `stay` (clears `flee` state).
4. **Seguir:** `reset` + `follow` (clears `flee` state).
5. **Summon:** `summon`.
6. **¡Huir!:** `flee` (sets passive flee state so bots stay retreating until ordered otherwise).
7. **Formación:** Cycles party formation (`arrow` -> `queue` -> `near` -> `melee` -> `circle`).
8. **Separarse (`move from group`):** Left-click enables spread (`move from group`); Right-click disables it (`nc -move from group` + `co -move from group`).

#### Floating Utility Bar (`Barra de Utilidades`)
Positioned cleanly above the Tactical HUD by default (with main panel shortcut button):
1. **Hablar PNJ:** `talk` (opens a bot selector dropdown with live proximity indicators like `Cerca` / `Lejos` if 2+ party bots are present, or queries the single bot directly; opens the interactive NPC Talk dialog showing immediate proximity status and faraway warnings if the bot is distant, dead, or out of range, while keeping normal icon colors on the toolbar at all times).
2. **Misiones:** Opens the **Quest Dialog** directly for a party bot.
3. **Bots en el Grupo:** Opens the main `DungeonBots` window directly onto Tab 2 (`Bots en el grupo`).
4. **Inventario de Bot:** Opens a party bot dropdown selector (`c`, with auto-retry and proximity diagnostics on timeout) and opens the **Bot Inventory / Bag Viewer**, rendering bag items in a visual grid with quality-colored borders, stack counts, search filter, localized tooltips, sequential party bot cycling (**`Siguiente Bot`** with `(index/total)` indicator), and verified item destruction (`destroy [itemLink]` normalized to client 3.3.5a link format; no trade UI).
5. **Información del Personaje:** Opens a party bot dropdown selector with live proximity indicators (`spells` / `< 28 m` inspect range, auto-retry, and proximity diagnostics on timeout) and opens the **Character Info / Spellbook Viewer** with 3 compact icon-badged sub-tabs (**`Equipo`**, **`Hechizos`**, and **`Glifos`**, with live `NotifyInspect` / `INSPECT_TALENT_READY` tree selector & spec summary inside `Equipo`), native `GetSpellInfo` / item / talent tooltip integration, reagent parsing (with item localization & buyable tags), live local search, **`Lanzar`** (`cast [link]`), **`Cancelar`**, and sequential party bot cycling (**`Siguiente Bot`**).

---

## Architecture (Modular Files)

Files listed in `DungeonBots.toc` (`30300`) load order:
- `Locales/enUS.lua` — Base English localization strings & fallback table
- `Locales/esES.lua` — Spanish (`esES` / `esMX`) strings, spec tokens, and server translations
- `Core/Core.lua` — Core namespace, defaults, data tables, shared helpers
- `Locales/Locale.lua` — Client-language localization and async WDB resolution
- `Core/Roster.lua` — Bot detection, proximity/no-response diagnostics, LFD guard, summoning, dismissing, and Bot History
- `Core/Comms.lua` — Chat command dispatch, capture retry helper, staggered queue, filters, and WIM hooks
- `Modules/Talents.lua` — Talent parsing, live queries, spec switching, and autogear
- `Modules/Quests.lua` — Quest Log & Talk capture engine plus Dalaran timer helpers
- `Modules/Inventory.lua` — Bot bag query (`c`), whisper parser, and `destroy` dispatcher
- `Modules/Spells.lua` — Bot `spells`/`cast`/`glyphs` parser and `NotifyInspect` talent reader
- `Core/Events.lua` — WoW event dispatcher (including `LFG_UPDATE` & `LFG_LOCK_INFO_RECEIVED`) and slash commands
- `UI/Theme.lua` — Visual theme engine (`"gold"` default / `"dark"`), shared backdrop & icon-button primitives
- `UI/HUD.lua` — Floating Combat Tactical HUD and Floating Utility Bar
- `UI/MainUI.lua` — Main 3-tab UI frame, Frozen Halls access checks, minimap icon, and LFD eye hooks
- `UI/Modals.lua` — Settings modal (header version, bottom-left Discord contact notice, theme picker) and Bot History modal (`Nombre` + `Agregar`)
- `UI/QuestTalkUI.lua` — Quest Log and NPC Talk modal windows
- `UI/InventoryUI.lua` — Bag-grid Bot Inventory window and item destruction confirmation
- `UI/SpellsUI.lua` — Interactive Character Info window (`Equipo`, `Hechizos`, `Glifos`, inspected talents, `cast`)

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
