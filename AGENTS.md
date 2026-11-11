# AGENTS.md — Coding Agent Guide for DungeonBots

This document defines the architecture, repository map, technical constraints, commit conventions, and verification workflow for coding agents working on **DungeonBots** (`World of Warcraft 3.3.5a`, Interface `30300`).

---

## 1. Repository Map

- `DungeonBots.toc` — Addon manifest (`## Interface: 30300`, `SavedVariables: DungeonBotsDB`).
- `DungeonBots.lua` — Core logic: bot identity/history persistence (`DungeonBotsDB`), party join tracking (`PARTY_MEMBERS_CHANGED`, `UNIT_NAME_UPDATE`), staggered whisper command queue (`whisperQueueFrame`, `joinQueryFrame`) with retries, live talent whisper parser (`ParseTalentWhisper`, `CanonicalizeSpec`), command dispatchers (`SendDotCommand`, `SendPartyCommand`, `SendWhisperCommand`), Dalaran timer, and slash commands (`/db`, `/dungeonbots`, `/bots`, `/playerbot`).
- `DungeonBots_HUD.lua` — Floating 7-button Combat HUD (`InitHUD`, `UpdateHUDVisibility`, `ToggleHUD`, `/p` tactical commands).
- `DungeonBots_UI.lua` — Main 3-tab window (`BuildTab1`, `BuildTab2`, `BuildTab3`), Bot History modal dialog (`BuildHistoryDialog`, `UpdateHistoryUI`), party member cards (`UpdatePartyUI` with dynamic spec dropdown, `Adaptar Equipo`, `Equipar Azul`, `Misiones` -> `quests all`, and `Despedir`), draggable minimap eye button (`InitMinimapButton`), and LFD frame hook (`HookEye`).
- `README.md` — English user documentation describing all features, UI controls, and slash commands.

---

## 2. Strict WoW 3.3.5a Technical Rules

1. **Lua 5.1 & WotLK `30300` API Only:**
   - Never use Retail/Cataclysm+ APIs (`C_Timer`, `C_Map`, `C_Container`, `BackdropTemplate`, `GetSpecialization`, `strsplit` incompatibilities without checking WotLK availability).
   - Use `OnUpdate` frames for delayed/staggered timers and `GetTime()` (`NowTime()`) as done in `DungeonBots.lua`.
2. **Character Encoding (Latin-1 Safe in `.lua` Files):**
   - WoW 3.3.5a UI fonts / Lua strings in this addon must stay within **ASCII + Latin-1 (`<= U+00FF`)** (standard Spanish accents `á é í ó ú ñ ¿ ¡` are fine; **never** insert emojis or Unicode characters `> U+00FF` such as `U+2014`, `U+2022`, `U+2192` inside `.lua` files).
   - If you ever use `$` in markdown artifacts or prose, escape properly; in `.lua`, write plain ASCII punctuation like `--` instead of em-dashes.
3. **In-Game UI Text Language:**
   - User-facing UI labels, tooltips, and chat notifications inside the `.lua` files are in **Spanish** unless the user specifically asks otherwise.
4. **Documentation & Commit Language:**
   - **`README.md`, `AGENTS.md`, and ALL Git commit messages must be written in English.**

---

## 3. Scope & Safety Rules

- **Only edit files inside `DungeonBots/`** unless the user explicitly asks to inspect or modify another folder. Never modify or delete other addons in `Interface/AddOns/` (such as `WIM`, `KkthnxUI`, `WoWAI`, `Carbonite`, etc.).
- **Preserve bot vs. real player safety:** Never bypass `ShouldTreatAsBot` / `IsBot(name) == false` / `CanInviteToParty()` guards. Human party members must remain safe from automatic whispers, spec/gear commands, or dismiss actions.
- **No external SavedVariables pollution:** Never write to another addon's `SavedVariables` (for example, do not mutate `WIM3_Filters`, `WIM3_Data`, or `WIM3_History` if integrating WIM compatibility).
- **Reload reminder:** Because WoW 3.3.5a compiles `.lua` files only at load time and persists `DungeonBotsDB` across reloads, remind the user to run `/reload` in-game to test code changes.

---

## 4. Verification Before Committing

Since there is no live WoW client or `luac` binary in the agent shell environment, always run static checks after final `.lua` edits (from `d:\world of warcraft 3.3.5a hd\interface\addons` or inside `DungeonBots/`):

1. **Check Lua syntax / block balance** across all addon `.lua` files (verify every `function`/`if`/`for`/`while`/`repeat`/`do` matches `end`/`until` cleanly and quotes/brackets balance).
2. **Verify Latin-1 compliance (`<= U+00FF`) in all `.lua` files:**
   ```powershell
   python -c "import glob; bad=[(f,i+1,hex(ord(c))) for f in sorted(glob.glob('DungeonBots/*.lua')) for i,c in enumerate(open(f,encoding='utf-8').read()) if ord(c)>255]; print('non_latin1:', len(bad), bad[:20])"
   ```
   Expect `non_latin1: 0 []`.
3. **Review diff & status before committing:**
   ```powershell
   git -C DungeonBots status
   git -C DungeonBots diff --stat
   ```
4. **Commit in English** with a clear, concise summary of what changed and why.
