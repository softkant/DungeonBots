# AGENTS.md — Coding Agent Guide for DungeonBots

This document defines the architecture, repository map, technical constraints, commit conventions, and verification workflow for coding agents working on **DungeonBots** (`World of Warcraft 3.3.5a`, Interface `30300`).

---

## 1. Repository Map

- `DungeonBots.toc` — Addon manifest (`## Interface: 30300`, `SavedVariables: DungeonBotsDB`) loading modules in dependency order.
- `DungeonBots.lua` — Core namespace initialization (`DungeonBots`, `DungeonBots.Internal`), default config (`hudVisible`, `utilHudVisible`, `hudOnlyInDungeon`, positions, locks), static data tables (`CLASSES`, `SPECS`, `DEFAULT_CLASS_SPECS`, `PRESETS`), runtime state, shared utilities (`NowTime`, `NormalizePlayerName`, `TrimText`, `StripChatFormatting`, `EscapeLuaPattern`, `ExtractSafeHyperlinkFromText`, `ExtractSafeQuestLinkFromText`), `GetRaceIcon`, `GetClassDisplayInfo`, and chat output helpers (`Print`, `Warn`).
- `DungeonBots_Locale.lua` — Client-language localization (`GetLocale()`): quest log lookup + hidden tooltip hyperlink scan (`DungeonBots_LocaleScanTooltip`) with async WDB retry queue (`localeResolveFrame`, `ApplyCachedLocaleToStoredDialogs`), `GetItemInfo` / `GetSpellInfo` resolution, visible `LocalizeSpecText` mapping (`esES`/`esMX`) while preserving canonical command strings, `GetLocalizedClassName`, and `LocalizeHyperlinksInText`.
- `DungeonBots_Roster.lua` — Bot identity/persistence (`RegisterBot`, `IsBot`, `ShouldTreatAsBot`, `ToggleUnitBotStatus`), party join & summon tracking (`MarkPendingClassSummon`, `ResolvePendingPartyBots`), discreet party probing (`ScanPartyBots`), bot add/remove actions (`AddClass`, `AddBot`, `AddAllBots`, `RemoveBot`, `RemoveAllBots`), and Bot History persistence (`RecordBotHistory`, `SyncPartyToHistory`, `SummonAndInviteHistoryBot`).
- `DungeonBots_Comms.lua` — Chat command dispatchers (`SendDotCommand`, `SendPartyCommand`, `SendWhisperCommand`), outgoing anti-echo whisper tracker, staggered whisper queue (`whisperQueueFrame`, `QueueWhisperCommand`), bot message detection (including `=== Inventory ===`), Blizzard chat filters (`SetupChatFilters` with link localization for non-suppressed bot messages), WIM compatibility (`SetupWIMCompatibility`, `CloseBotWIMWindows`), and `SendChatMessage` hook for `talk` (`HookSendChatForTalk`).
- `DungeonBots_Talents.lua` — Spec normalization (`CleanSpecText`, `CanonicalizeSpec`), live talent whisper parser (`ParseTalentWhisper`), join/retry talent polling (`joinQueryFrame`, `QueryBotLiveInfo`, `QueryBotSpecs`), `SetBotSpec` (sends canonical English `talents spec <spec>` while printing localized spec names), `AutogearMatch`, and `AutogearBlue`.
- `DungeonBots_Quests.lua` — Bot quest log commands & parser (`QueryQuests`, `DropBotQuest`, `ParseQuestCaptureWhisper`), NPC Talk commands & parser (`HasValidNpcTarget`, `IsTalkBusy`, sequential `CycleNextTalkBot`, `ArmTalkCapture`, `SendTalkCommand`, `ParseTalkCaptureWhisper` preferring `UnitName("target")` and localizing quest/item/spell links without altering `safeLink`/`rawTitle`/`acceptCmd`/`talkCmd`), `uiCaptureFrame`, and the Dalaran 60s timer & ICC helpers (`DalaranPrep`, `DungeonReenter`, `DungeonTurnInAndAccept`, `StartDalaranTimer`, `StopDalaranTimer`).
- `DungeonBots_Inventory.lua` — Bot bag inventory query & parser (`QueryBotInventory`, `ParseInventoryCaptureWhisper`, `TickInventoryCapture`, `RefreshInventoryItemVisuals` via client `GetItemInfo`/`GetItemIcon`) and verified item destruction command (`DestroyBotItem` whispering client-normalized `destroy <itemLink>` with feedback capture and delayed `c` verification).
- `DungeonBots_Spells.lua` — Bot powers query, streaming whisper parser, and action dispatch (`QueryBotSpells` supporting `spells` + filter params, `glyphs`, `trainer`, `stats`, plus `QueryBotSpellDetail` for `spell [link]`, `CastBotSpell` for `cast [link]`, `ParseSpellsCaptureWhisper`, `TickSpellsCapture`, `RefreshSpellVisuals`, and `CycleNextSpellsBot`).
- `DungeonBots_Events.lua` — Unified `eventFrame` (`ADDON_LOADED`, `PLAYER_LOGIN`, `CHAT_MSG_WHISPER`, `PARTY_MEMBERS_CHANGED`, `UNIT_NAME_UPDATE`, `PLAYER_ENTERING_WORLD`, `ZONE_CHANGED_NEW_AREA`, `PLAYER_TARGET_CHANGED`) and slash commands (`/db`, `/dungeonbots`, `/bots`, `/playerbot`).
- `DungeonBots_HUD.lua` — Shared floating toolbar builder (`CreateFloatingToolbar`, shared `OpenPartyBotDropdown`) powering both the 6-button Combat Tactical Bar (`HUD_ACTIONS`) and the 4-button Utility Bar (`UTIL_ACTIONS`: NPC `talk`, open Tab 2 `Bots en el grupo`, Bot Bag Inventory dropdown selector, and Bot Powers dropdown selector), with independent position/lock state and shared `hudOnlyInDungeon` gating (`UpdateHUDVisibility`, `UpdateHUDTalkButtonState`, `ResetHUDPositions`, `ToggleHUD`).
- `DungeonBots_UI.lua` — Shared UI skin helpers (`ApplyDarkBackdrop`, `ApplyHeaderBackdrop`, `CreateRedIconButton`, `SafeShowLinkTooltip`), main 3-tab window (`InitUI`, `ToggleUI`, `SelectTab`, `OpenTab`, `BuildTab1`, `BuildTab2`, `UpdatePartyUI`, `BuildTab3`, `UpdateDalaranTimerUI`), draggable minimap button (`InitMinimapButton`), and LFD eye integration (`HookEye`).
- `DungeonBots_Modals.lua` — Settings modal dialog (`BuildSettingsDialog`, `UpdateSettingsDialog`, `ToggleSettingsDialog`, with independent show/hide toggles for both floating bars and shared dungeon-only filtering) and Bot History modal dialog (`BuildHistoryDialog`, `UpdateHistoryUI`, `ToggleHistoryDialog`).
- `DungeonBots_QuestTalkUI.lua` — Interactive Bot Quest Log dialog (`BuildQuestDialog`, `UpdateQuestDialog`, `OpenQuestDialog`) and NPC Talk dialog (`BuildTalkDialog`, `UpdateTalkDialog`, `OpenTalkDialog`).
- `DungeonBots_InventoryUI.lua` — Bag-style Bot Inventory grid viewer (`BuildInventoryDialog`, `UpdateInventoryDialog`, `OpenInventoryDialog`) with live search filter, quality-colored slot borders, stack counts, sequential bot cycling (`Siguiente Bot`), client-localized item tooltips, and confirmed item destruction (`DUNGEONBOTS_DESTROY_BOT_ITEM`).
- `DungeonBots_SpellsUI.lua` — Interactive Bot Powers window (`BuildSpellsDialog`, `UpdateSpellsDialog`, `OpenSpellsDialog`) featuring 4 mode tabs (`Hechizos`, `Glifos`, `Entrenador`, `Stats`), local + server `spells <filter>` bars, reagent/difficulty badges, native spell tooltips, inline `spell` detail box, `cast` trigger, shortcut to Talents, and sequential `Siguiente Bot` cycling.
- `README.md` — English user documentation describing all features, localization behavior, UI controls, and slash commands.

---

## 2. Strict WoW 3.3.5a Technical Rules

1. **Lua 5.1 & WotLK `30300` API Only:**
   - Never use Retail/Cataclysm+ APIs (`C_Timer`, `C_Map`, `C_Container`, `BackdropTemplate`, `GetSpecialization`, `strsplit` incompatibilities without checking WotLK availability).
   - Use `OnUpdate` frames for delayed/staggered timers and `GetTime()` (`DB_Internal.NowTime()`) as used across modules.
2. **Character Encoding (Latin-1 Safe in `.lua` Files):**
   - WoW 3.3.5a UI fonts / Lua strings in this addon must stay within **ASCII + Latin-1 (`<= U+00FF`)** (standard Spanish accents `á é í ó ú ñ ¿ ¡` are fine; **never** insert emojis or Unicode characters `> U+00FF` such as `U+2014`, `U+2022`, `U+2192` inside `.lua` files).
   - If you ever use `$` in markdown artifacts or prose, escape properly; in `.lua`, write plain ASCII punctuation like `--` instead of em-dashes.
3. **In-Game UI Text Language & Command Safety:**
   - User-facing UI labels, tooltips, and chat notifications inside the `.lua` files are in **Spanish** unless the user specifically asks otherwise, while quests, items, spells, classes, specs, and targeted NPCs localize automatically via `DungeonBots_Locale.lua`.
   - Never alter canonical command strings sent to `mod-playerbots` (`safeLink`, `rawTitle`, `acceptCmd`, `talkCmd`, `talents spec <cleanSpec>`). Plain-text NPC gossip without hyperlinks/IDs has no client-side translation key in 3.3.5a and must remain unmodified.
4. **Documentation & Commit Language:**
   - **`README.md`, `AGENTS.md`, and ALL Git commit messages must be written in English.**

---

## 3. Scope & Safety Rules

- **Only edit files inside `DungeonBots/`** unless the user explicitly asks to inspect or modify another folder. Never modify or delete other addons in `Interface/AddOns/` (such as `WIM`, `KkthnxUI`, `WoWAI`, `Carbonite`, etc.).
- **Preserve bot vs. real player safety:** Never bypass `ShouldTreatAsBot` / `IsBot(name) == false` / `CanInviteToParty()` guards. Human party members must remain safe from automatic whispers, spec/gear commands, or dismiss actions.
- **No external SavedVariables pollution:** Never write to another addon's `SavedVariables` (for example, do not mutate `WIM3_Filters`, `WIM3_Data`, or `WIM3_History` when integrating WIM compatibility).
- **Reload reminder:** Because WoW 3.3.5a compiles `.lua` files only at load time and persists `DungeonBotsDB` across reloads, remind the user to run `/reload` in-game to test code changes.

---

## 4. Verification Before Committing

Since there is no live WoW client or `luac` binary in the agent shell environment, always run static checks after final `.lua` edits (from `d:\world of warcraft 3.3.5a hd\interface\addons` or inside `DungeonBots/`):

1. **Check Lua syntax / block balance** across all `DungeonBots/*.lua` files and confirm `DungeonBots.toc` lists every `.lua` file cleanly.
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
