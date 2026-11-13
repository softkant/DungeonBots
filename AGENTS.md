# AGENTS.md — Coding Agent Guide for DungeonBots

This document defines the architecture, repository map, technical constraints, commit conventions, and verification workflow for coding agents working on **DungeonBots** (`World of Warcraft 3.3.5a`, Interface `30300`), built for servers running the [mod-playerbots](https://github.com/mod-playerbots/mod-playerbots/) (`https://github.com/mod-playerbots/mod-playerbots/`) module.

---

## 1. Repository Map

- `DungeonBots.toc` — Addon manifest (`## Interface: 30300`, `SavedVariables: DungeonBotsDB`) loading `Core/`, `Locales/`, `Modules/`, and `UI/` in dependency order.
- `Core/Core.lua` — Core namespace initialization (`DungeonBots`, `DungeonBots.Internal`), default config (`hudVisible`, `utilHudVisible`, `hudOnlyInDungeon`, `uiTheme = "gold"`, `attackWaitSeconds = 2`, `pullWaitSeconds = 6`, `fleeActive`, positions, locks), static data tables (`CLASSES`, `SPECS`, `DEFAULT_CLASS_SPECS`, `PRESETS`), runtime state, shared utilities (`NowTime`, `NormalizePlayerName`, `TrimText`, `StripChatFormatting`, `EscapeLuaPattern`, `ExtractSafeHyperlinkFromText`, `ExtractSafeQuestLinkFromText`), `GetRaceIcon`, `GetClassDisplayInfo`, and chat output helpers (`Print`, `Warn`).
- `Locales/enUS.lua` — Base `DungeonBots.L` localization table with metatable fallback and English default server-hint / status labels (keep exact key parity with `Locales/esES.lua`).
- `Locales/esES.lua` — Spanish (`esES` / `esMX`) `DungeonBots.L` strings, spec token mappings (`ES_SPEC_TOKENS`), and inventory/status translations (`ES_SERVER_SECTIONS`).
- `Locales/Locale.lua` — Client-language localization engine (`GetLocale()`): spec/class/server-hint localization (`LocalizeSpecText`, `LocalizeServerHint`, `LocalizeServerSection`), quest log lookup + hidden tooltip hyperlink scan (`DungeonBots_LocaleScanTooltip`) with async WDB retry queue (`localeResolveFrame`, `QueueItemLocaleResolution`, `ApplyCachedLocaleToStoredDialogs`), `GetItemInfo` / `GetSpellInfo` resolution, and `LocalizeHyperlinksInText`.
- `Core/Roster.lua` — Bot identity/persistence (`RegisterBot`, `IsBot`, `ShouldTreatAsBot`, `ToggleUnitBotStatus`), party unit, proximity & no-response diagnostic helpers (`FindPartyUnitByName`, `GetBotProximityInfo`, `FormatNoResponseBody`), party join & summon tracking (`MarkPendingClassSummon`, `ResolvePendingPartyBots`), discreet party probing (`ScanPartyBots`), bot add/remove actions with LFD queue guard on `AddClass` (`AddClass`, `AddBot`, `AddAllBots`, `RemoveBot`, `RemoveAllBots`), and Bot History persistence (`RecordBotHistory`, `SyncPartyToHistory`, `SummonAndInviteHistoryBot`).
- `Core/Comms.lua` — Chat command dispatchers (`SendDotCommand`, `SendPartyCommand`, `SendWhisperCommand`), shared capture retry helper (`TryRetryWhisperCapture`), outgoing anti-echo whisper tracker, staggered whisper queue (`whisperQueueFrame`, `QueueWhisperCommand`), bot message detection, Blizzard chat filters (`SetupChatFilters`), WIM compatibility (`SetupWIMCompatibility`, `CloseBotWIMWindows`), and `SendChatMessage` hook for `talk` (`HookSendChatForTalk`).
- `Modules/Talents.lua` — Spec normalization (`CleanSpecText`, `CanonicalizeSpec`), live talent whisper parser (`ParseTalentWhisper`), join/retry talent polling (`joinQueryFrame`, `QueryBotLiveInfo`, `QueryBotSpecs`), `SetBotSpec`, `AutogearMatch`, and `AutogearBlue`.
- `Modules/Quests.lua` — Bot quest log commands & parser (`QueryQuests`, `DropBotQuest`, `ParseQuestCaptureWhisper`), NPC Talk commands & parser (`HasValidNpcTarget`, `IsTalkBusy`, sequential `CycleNextTalkBot`, `ArmTalkCapture`, `SendTalkCommand`, `ParseTalkCaptureWhisper`), `uiCaptureFrame`, and the Dalaran 60s timer & ICC helpers (`DalaranPrep`, `DungeonReenter`, `DungeonTurnInAndAccept`, `StartDalaranTimer`, `StopDalaranTimer`).
- `Modules/Inventory.lua` — Bot bag inventory query & parser (`QueryBotInventory`, `ParseInventoryCaptureWhisper`, `TickInventoryCapture`, `RefreshInventoryItemVisuals`) and verified item destruction command (`DestroyBotItem`).
- `Modules/Spells.lua` — Bot powers query, concurrent streaming whisper parser (`spells` & `glyphs`), inspect talent reader, and action dispatch (`QueryBotSpells`, `CastBotSpell`, `CancelBotSpell`, `ParseSpellsCaptureWhisper`, `HandleInspectTalentReady`, `SelectBotTalentTree`, `TickSpellsCapture`, `RefreshSpellVisuals`, `CycleNextSpellsBot`).
- `Core/Events.lua` — Unified `eventFrame` (`ADDON_LOADED`, `PLAYER_LOGIN`, `CHAT_MSG_WHISPER`, `CHAT_MSG_WHISPER_INFORM`, `CHAT_MSG_PARTY`, `CHAT_MSG_PARTY_LEADER`, `CHAT_MSG_SAY`, `PARTY_MEMBERS_CHANGED`, `LFG_LOCK_INFO_RECEIVED`, `LFG_UPDATE`, `UNIT_NAME_UPDATE`, `PLAYER_ENTERING_WORLD`, `ZONE_CHANGED_NEW_AREA`, `PLAYER_TARGET_CHANGED`, `INSPECT_TALENT_READY`), flee-state tracking, and slash commands (`/db`, `/dungeonbots`, `/bots`, `/playerbot`).
- `UI/Theme.lua` — Visual theme engine (`"gold"` default on first run / `"dark"` slate-blue), backdrop primitives (`ApplyDarkBackdrop`, `ApplyBlizzardGoldWindow`, `ApplyBlizzardStonePanel`, `ApplyInsetPanelBackdrop`, `ApplyHeaderBackdrop`, `AddQuickSlotBorder`, `CreateRedIconButton`, `SafeShowLinkTooltip`), and live theme switching (`SetUITheme`, `RefreshTheme`).
- `UI/HUD.lua` — Shared floating toolbar builder (`CreateFloatingToolbar`, shared `OpenPartyBotDropdown`) powering the Tactical Combat Bar (focus target with conditional flee-recovery `follow`, pull timer, stay/follow/summon/flee, formation cycle, spread Left/Right-click toggle) and Utility Bar (`talk`, `quests`, `party`, `inventory`, `spells`), with unified lock helpers (`IsHUDLocked`, `SetHUDLocked`, `ToggleHUDLock`), independent bar positions, and shared `hudOnlyInDungeon` gating.
- `UI/MainUI.lua` — Main 3-tab window (`InitUI`, `UpdateHUDLockButtonState`, `ToggleUI`, `SelectTab`, `OpenTab`, `BuildTab1`, `BuildTab2`, `UpdatePartyUI`, `BuildTab3`, `UpdateDalaranTimerUI`, `UpdateMainModalDimmer`, `RegisterSubModalDimmer`), LFD Pit of Saron / Halls of Reflection access checks (`UpdateDungeonAccessUI`), draggable minimap button (`InitMinimapButton`), and LFD eye integration (`HookEye`).
- `UI/Modals.lua` — Settings modal dialog (`BuildSettingsDialog`, `UpdateSettingsDialog`, `ToggleSettingsDialog`, visual theme switcher, `@Shahak` footer & Discord contact notice) and Bot History modal dialog (`BuildHistoryDialog`, `UpdateHistoryUI`, `ToggleHistoryDialog`, including manual bot-name input `DungeonBots_HistAddNameBox`).
- `UI/QuestTalkUI.lua` — Interactive Bot Quest Log dialog (`BuildQuestDialog`, `UpdateQuestDialog`, `OpenQuestDialog`) and NPC Talk dialog (`BuildTalkDialog`, `UpdateTalkDialog`, `OpenTalkDialog`).
- `UI/InventoryUI.lua` — Bag-style Bot Inventory grid viewer (`BuildInventoryDialog`, `UpdateInventoryDialog`, `OpenInventoryDialog`) with live search filter, quality-colored slot borders, stack counts, sequential bot cycling, client-localized item tooltips, and confirmed item destruction.
- `UI/SpellsUI.lua` — Interactive Character Info window (`Información del Personaje`, `BuildSpellsDialog`, `UpdateSpellsDialog`, `OpenSpellsDialog`) featuring 3 compact icon-badged mode buttons (`Equipo`, `Hechizos`, `Glifos`), local search filter, reagent/difficulty badges, per-glyph rows, cast & cancel (`reset`) controls with live cast detection, and sequential `Siguiente Bot` cycling.
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
   - User-facing UI labels, tooltips, and chat notifications inside the `.lua` files are in **Spanish** unless the user specifically asks otherwise, while quests, items, spells, classes, specs, and targeted NPCs localize automatically via `Locales/`.
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
   python -c "import pathlib; bad=[(str(p),i+1,hex(ord(c))) for p in sorted(pathlib.Path('.').rglob('*.lua')) for i,c in enumerate(p.read_text(encoding='utf-8')) if ord(c)>255]; print('non_latin1:', len(bad), bad[:20])"
   ```
   Expect `non_latin1: 0 []` (also verify `Locales/enUS.lua` and `Locales/esES.lua` key parity and zero unused keys).
3. **Review diff & status before committing:**
   ```powershell
   git -C DungeonBots status
   git -C DungeonBots diff --stat
   ```
4. **Commit in English** with a clear, concise summary of what changed and why.
