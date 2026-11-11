# DungeonBots — Tactical Dungeon Bot Assistant (WoW 3.3.5a)

**DungeonBots** is a lightweight World of Warcraft 3.3.5a (`Interface: 30300`) addon designed for players using `mod-playerbots` / Playerbots in 5-player dungeons. It provides a visual interface to summon, invite, configure, inspect, gear, and direct party bots without typing chat commands manually.

---

## Key Features

### 1. Party Builder (`Armar Grupo` — Tab 1)
* **Bot History (`Historial de bots` / `Ver Historial de bots`):** Automatically records bots you group with (name, class, race/gender portrait, and last known talent spec). Open the history window to individually summon & invite previous bots (`Invitar`, runs `.playerbots bot add <name>` + party invite), remove individual entries, or clear the list.
* **Summon by Class (`Invocar Bot por Clase Individual`):** 10 class buttons that run `.playerbots bot addclass <class>`.
* **Smart Auto-Invite & Human Safety:** Newly summoned bots that whisper on creation (within the summon window, when party size < 5) are invited automatically. Real players are never treated as bots unless explicitly confirmed or toggled.
* **Global Group Controls & Chat Hiding:**
  * Toggle auto-invite for newly summoned bots.
  * Toggle whether the floating Combat HUD appears only inside 5-player dungeons (`IsInInstance()` == `"party"`).
  * **Bot Whisper Hiding (Blizzard Chat & WIM Compatible):** Choose between `Desactivado` (Off), `Automáticos` (hides technical queries, summon greetings, quests, NPC talk captures, and addon outgoing whispers while keeping manual whispers visible), and `Todos` (hides all incoming and outgoing whispers with known bots). Includes an optional toggle to also hide bot messages in `/p`, `/y`, and `/s`. Real human players (`[JUGADOR]` or unknown players) are never filtered, and WIM's SavedVariables are never modified.
  * **`Reinvocar Grupo`:** Runs `.playerbots bot add *` to recall absent bots that are still in your party.
  * **`Despedir a Todos`:** Runs `.playerbots bot remove *` and removes confirmed bots from the party while preserving human players.
  * **`Reparar Equipo`:** Sends `/p repair`.
  * **`Liberar alma`:** Sends `/p release` (note: bots release spirit at the graveyard).

---

### 2. Party Bot Manager (`Bots en el grupo` — Tab 2)
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
  * **`Misiones`:** Silently queries `quests all` and opens the interactive **Quest Dialog** showing all active quests (or an empty notice when none are active). Click any quest to inspect its details, or click `Abandonar` to send `drop` and automatically refresh the list.
  * **`Despedir`:** Dismisses the bot (`.playerbots bot remove <name>`) and uninvites it from the party if needed.
* **NPC Talk Dialog (`talk`):**
  * Selecting an NPC and whispering `talk` to a bot (`/w <bot> talk`, `/p talk`, `/s talk`, or `/db talk [bot]`) captures the bot's reply cleanly out of chat/WIM and opens an interactive **NPC Dialog** window with clickable quest/item hyperlinks, 1-click numbered gossip options (`talk #n`), quest accept/turn-in buttons (`accept` / `accept *`), and a direct follow-up command bar.

---

### 3. ICC 5-Man Quest Assistant (`Forja / Foso / Cámaras` — Tab 3)
Automates the Forge of Souls -> Pit of Saron -> Halls of Reflection quest chain under the 60-second out-of-dungeon bot timer:
1. **60s Dalaran Countdown Bar:** Color-coded progress bar (`green -> yellow -> red`) with a sound warning at 15 seconds remaining.
2. **Step 1 (`Dalaran`):** Target the quest NPC and press the Step 1 button (`/p summon` + `/p accept *` + starts the 60s timer).
3. **Step 2 (`Entrada a Forja`):** Enter the dungeon portal and press Step 2 (`.playerbots bot add *` + `/p summon`).
4. **Step 3 (`Entregar y Continuar`):** Target the NPC inside the instance to turn in and accept the next quest (`/p accept *`), plus a quick **`Verificar Misiones`** (`/p quests`) button.

---

### 4. Floating Tactical Bar (`Combat HUD`)
Compact, draggable, and lockable floating bar (shown only inside 5-player dungeons by default) with 7 combat actions sent to `/p`:
1. **Focus Target:** `do attack my target`
2. **Pull con Tanque:** `pull my target`
3. **Quedarse:** `stay`
4. **Seguir:** `follow`
5. **Summon:** `summon`
6. **¡Huir!:** `flee`
7. **Descansar:** `drink`

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
  * `/db dalaran` — Trigger the Dalaran prep step.
  * `/db addall` — Recall all bots (`.playerbots bot add *`).
  * `/db dismiss` (or `/db removeall`) — Dismiss all bots (`.playerbots bot remove *`).
  * `/db reset` — Reset the Combat HUD position to bottom-center.
