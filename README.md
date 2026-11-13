# DungeonBots — Tactical Dungeon Bot Assistant (WoW 3.3.5a)

**DungeonBots** is a lightweight World of Warcraft 3.3.5a (`Interface: 30300`) addon designed for players using the **[mod-playerbots](https://github.com/mod-playerbots/mod-playerbots/)** module (`https://github.com/mod-playerbots/mod-playerbots/`) in 5-player dungeons. It provides a modular, visual interface to summon, invite, configure, inspect, gear, and direct party bots without typing chat commands manually.

---

## Key Features

### 1. Client-Language Localization (`GetLocale()`)
* **Multi-Language UI (`enUS` & `esES` / `esMX`):** Automatically displays all menus, tooltips, dialogs, and notifications in English by default or Spanish on `esES`/`esMX` clients.
* **Automatic Hyperlink Localization:** Quest titles (`|Hquest:...|h`), item links (`|Hitem:...|h`), and spells (`|Hspell:...|h`) returned by bots in Quest Log, NPC Dialogs, tooltips, chat notifications, and visible bot whispers automatically resolve in your WoW client's language. Uncached quests and items automatically trigger client WDB queries and update open dialogs in place once cached.
* **Localized Classes, Specs & Targets:** Party cards, talent selectors, and Bot History display localized class names (`_G.LOCALIZED_CLASS_NAMES_MALE`) and localized talent spec names while keeping canonical bot commands (`talents spec`, `accept`, `drop`, `talk`) untouched so commands always execute cleanly. When targeting an NPC, `UnitName("target")` is preferred over raw server whisper headers. *(Plain-text NPC gossip without IDs/links remains unmodified due to WoW 3.3.5a client limitations.)*

---

### 2. Build Party (Tab 1)
* **Bot History (`History/Add`):** Automatically records bots you group with (name, class, race/gender portrait, and last known talent spec). Open the history window to individually summon and invite previous bots (`Invite`, runs `.playerbots bot add <name>` + party invite), manually add any bot by typing its name in the `Bot name:` + `Add` input, remove individual entries, or clear the list.
* **Summon Bot by Class:** 10 class buttons that run `.playerbots bot addclass <class>`.
* **LFD Backfill Queue Guard (`LFG_UPDATE`):** If the Dungeon Finder Eye enters replacement search (`"queued"`, after accepting "Find another player"), DungeonBots notifies you and blocks `addclass` so you add bots directly via **Bot History** instead.
* **Smart Auto-Invite & Human Safety:** Newly summoned bots that whisper on creation (within the summon window, when party size < 5) are invited automatically. Real players are never treated as bots unless explicitly confirmed or toggled.
* **Floating Bar Lock Toggle (Header Padlock Icon next to Settings):**
  * Single lock button next to the header gear icon controlling **both** floating bars together: **green** = unlocked (both bars can be dragged), **gray** = locked (both bars fixed in place).
* **Settings Modal (Header Gear Icon):**
  * **Visual Theme:** Switch live between **Gold** (classic WotLK style, default on first launch) and **Slate Blue** (dark steel and silver).
  * Independently show or hide the Floating Tactical Bar and the Floating Utility Bar (both enabled by default), and toggle showing floating bars only inside 5-player dungeons (`IsInInstance() == "party"`, disabled by default).
  * **Hide Bot Whispers:** Toggle hiding all incoming and outgoing whispers with known bots (compatible with Blizzard chat and WIM without touching WIM's SavedVariables); when enabled, reveals an additional option to also hide bot messages in `/p`, `/y`, and `/s`. Real human players (`[PLAYER]` or unknown players) are never filtered.
* **General Options:**
  * **`Resummon Party`:** Runs `.playerbots bot add *` + `/p summon` to recall absent bots still in your party.
  * **`Dismiss All`:** Runs `.playerbots bot remove *` and removes confirmed bots from the party while preserving human players.
  * **`Repair Gear`:** Sends `/p repair`.
  * **`Release Spirit`:** Sends `/p release` (note: dead bots release spirit at the graveyard).

---

### 3. Party Bots (Tab 2)
Displays one tactical card per party slot (`party1` to `party4`):
* **Bot vs. Human Protection (`[ BOT ]` / `[ PLAYER ]`):** Probes unverified party members via discreet `follow info` whispers, or lets you click the `[ BOT ]` / `[ PLAYER ]` badge directly to protect human friends from bot commands.
* **Race & Gender Portraits:** Displays matching character icons per race and sex, along with level, class, active talent spec, and armor durability.
* **Card Controls:**
  * **`Character`:** Opens **Character Info** directly on **`Gear`**, letting you inspect and switch live talent specializations (`NotifyInspect`) or use **`Autogear`** (with downgrade warning).
  * **`Inventory`:** Queries `c` (with automatic retry and proximity diagnostics on timeout) and opens the visual **Bot Inventory** bag viewer.
  * **`Quests`:** Silently queries `quests all` (with automatic retry and proximity/instance/phase diagnostics on timeout) and opens the interactive **Quests** window showing active quests, plus live per-bot prerequisite status for **Pit of Saron** and **Halls of Reflection** (`(Current)` highlights the active bot as you cycle with **`Next Bot`**). Click any quest for details, or click **`Abandon`** to send `drop`, play `igQuestFailed`, and refresh automatically.
  * **`Dismiss`:** Cleanly logs out the bot (`.playerbots bot remove <name>`) and uninvites it from the party if needed.
* **NPC Dialog (`talk`):**
  * Selecting an NPC and querying `talk` (via HUD **`Talk NPC`**, `/w <bot> talk`, `/p talk`, `/s talk`, or `/db talk [bot]`) captures the reply out of chat/WIM and opens an interactive **NPC Dialog** window with clickable gossip options (`talk 0` / `talk #n`), quest actions (**`Accept`**, **`Turn In`**, **`Abandon`**), sequential party bot cycling (**`Next Bot`** with `(index/total)` indicator), **`Re-query`**, and **`Quest Log`**.

---

### 4. Guide & Tips (Tab 3)
Built-in WoW Quest-Log-style reference guide (`Guide Index` + topic viewer) covering 6 key topics:
1. **Quest prereqs:** Forge of Souls / Pit of Saron / Halls of Reflection access checks and why shared bots may repeat prerequisite quests across low-level players.
2. **Bot slow to join:** Auto-invite retries, party leader requirements, and zone lookup fallbacks.
3. **Other instance / phase:** Resolving instance/phase mismatches using `Summon`, `Follow`, or stepping out briefly.
4. **Bot used by other:** Distinguishing bots grouped with another player vs. bots still logging out (`"already online"`).
5. **Do not kick normally:** Why bots must always be dismissed from DungeonBots instead of WoW's right-click **Uninvite**.
6. **Gear & Talents:** Keeping base-spec gear intact and avoiding bag-space issues during `Autogear`.

*(For the Icecrown Citadel 5-man quest chain under the 60-second Dalaran out-of-dungeon timer, `/db dalaran` triggers the Dalaran prep macro `/p summon` + `/p accept *`.)*

---

### 5. Floating Combat Bar & Utility Bar
Both floating bars are draggable, locked/unlocked together from the padlock button next to Settings on the main window header (**green** = movable, **gray** = locked), individually toggleable in Settings, and share the 5-player dungeon visibility toggle:

#### Floating Tactical Bar (`HUD`)
Compact bar with 8 party combat and formation actions sent to `/p`:
1. **`Attack` (`Attack Target`):** Orders tank and `@dps` to focus your target (configurable right-click DPS delay `0 / 2 / 5 / 8s`, default `2s`; only sends `follow` beforehand if bots are flagged in `flee` state; `@heal` uses `0s`).
2. **`Pull` (`Tank Pull Back`):** Orders `@tank pull` with configurable right-click engage delay (`4 / 6 / 8 / 12s`, default `6s`; `@dps` joins after the timer while `@heal` uses `0s`).
3. **`Stay`:** `reset` + `stay` (clears `flee` state).
4. **`Follow`:** `reset` + `follow` (clears `flee` state).
5. **`Summon`:** `summon`.
6. **`Flee!`:** `flee` (sets passive flee state so bots stay retreating until ordered otherwise).
7. **`Formation Cycle`:** Cycles party formation (`Arrow` -> `Near` -> `Chaos (Default / Off)`).
8. **`Move From Group` (`Spread Out`):** Left-click enables spread (`move from group`); Right-click disables it (`nc -move from group` + `co -move from group`).

#### Floating Utility Bar
Positioned cleanly above the Tactical HUD by default (with main panel shortcut button):
1. **`Talk NPC`:** `talk` (opens a bot picker dropdown with live proximity indicators if 2+ bots are present, or queries the single bot directly; opens **NPC Dialog** showing proximity status and faraway warnings when distant, dead, or out of range).
2. **`Bot Quests`:** Opens the **Quests** dialog directly for a party bot.
3. **`Party Bots`:** Opens the main `DungeonBots` window directly onto Tab 2 (**`Party Bots`**).
4. **`Bot Inventory`:** Opens a party bot picker (`c`, with auto-retry and proximity diagnostics on timeout) and opens the **Inventory** bag grid viewer with quality-colored slot borders, stack counts, search filter, localized tooltips, sequential **`Next Bot`** cycling, and verified item destruction (`destroy [itemLink]` normalized to client 3.3.5a link format).
5. **`Character Info`:** Opens a party bot picker with live proximity indicators (`spells` / `< 28 yd` inspect range, auto-retry, and proximity diagnostics on timeout) and opens the **Character** viewer with 3 compact icon-badged sub-tabs (**`Gear`**, **`Spells`**, and **`Glyphs`**), live `NotifyInspect` / `INSPECT_TALENT_READY` talent tree selector, native tooltips, reagent/vendor tags, local search, **`Cast`** (`cast [link]`), cast cancel (`reset`), and sequential **`Next Bot`** cycling.

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
- `UI/HUD.lua` — Floating Tactical HUD and Floating Utility Bar
- `UI/MainUI.lua` — Main 3-tab UI frame (`Build Party`, `Party Bots`, `Guide & Tips`), Frozen Halls access checks, minimap icon, and LFD eye hooks
- `UI/Modals.lua` — Settings modal (theme picker, bar/chat toggles) and Bot History modal (saved list & manual bot-name invite)
- `UI/QuestTalkUI.lua` — Quest Log and NPC Dialog modal windows
- `UI/InventoryUI.lua` — Bag-grid Bot Inventory window and item destruction confirmation
- `UI/SpellsUI.lua` — Interactive Character Info window (`Gear`, `Spells`, `Glyphs`, inspected talents, `cast`)

---

## Shortcuts & Slash Commands

* **Minimap Addon Button:**
  * **Left Click:** Open / close the main DungeonBots window.
  * **Right Click:** Show / hide the floating Tactical HUD.
  * **Drag:** Reposition around the minimap.
* **LFD Integration:**
  * **Right Click** on `LFDMicroButton` opens DungeonBots.
  * **`DungeonBots` button** embedded on `LFDParentFrame`.
* **Slash Commands (`/db`, `/dungeonbots`, `/bots`, `/playerbot`):**
  * `/db` — Toggle main window.
  * `/db hud` — Toggle the floating Tactical HUD.
  * `/db talk [bot]` — Query a bot's current NPC dialog (`talk`) and open the NPC Dialog window.
  * `/db inv [bot]` — Query a bot's bags (`c`) and open the Bot Inventory window.
  * `/db spells [bot] [filter]` — Query a bot's active spells/recipes (`spells` or `spells <filter>`) and open Character Info (`Spells`).
  * `/db dalaran` — Trigger the Dalaran prep step.
  * `/db addall` — Recall all bots (`.playerbots bot add *`).
  * `/db dismiss` (or `/db removeall`) — Dismiss all bots (`.playerbots bot remove *`).
  * `/db reset` — Reset both floating bars (Tactical HUD & Utility Bar) to bottom-center.
