-- =========================================================================
-- DungeonBots_HUD.lua: Barras Flotantes (HUD Táctico y Barra de Utilidades)
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal
local L = DungeonBots.L or {}
local hudFrame = nil
local utilHudFrame = nil
local hudBotDropDown = nil
local hudTalkBtn = nil
local hudAttackBtn = nil
local hudPullBtn = nil
local hudFormCycleBtn = nil
local hudMenuWatcher = nil
local hudMenuAnchorBtn = nil
local hudMenuMouseWasDown = false

local ATTACK_WAIT_OPTIONS = { 0, 2, 5, 8 }
local PULL_WAIT_OPTIONS = { 4, 8, 12 }

local TACTICAL_ACTIONS = {
    {
        name = L["HUD_FOCUS_NAME"],
        actionKind = "attack_target",
        hasRightClickMenu = true,
        requiresTarget = true,
        icon = "Interface\\Icons\\Ability_Warrior_OffensiveStance",
        title = L["HUD_FOCUS_TITLE"],
        desc = L["HUD_FOCUS_DESC"],
        color = { 1.0, 0.2, 0.2 }
    },
    {
        name = L["HUD_PULL_NAME"],
        actionKind = "pull_back",
        hasRightClickMenu = true,
        requiresTarget = true,
        icon = "Interface\\Icons\\Ability_Hunter_AimedShot",
        title = L["HUD_PULL_TITLE"],
        desc = L["HUD_PULL_DESC"],
        color = { 1.0, 0.6, 0.1 }
    },
    {
        name = L["HUD_STAY_NAME"],
        cmds = { "reset", "stay" },
        icon = "Interface\\Icons\\Spell_Nature_TimeStop",
        title = L["HUD_STAY_TITLE"],
        desc = L["HUD_STAY_DESC"],
        color = { 1.0, 0.9, 0.2 }
    },
    {
        name = L["HUD_FOLLOW_NAME"],
        cmds = { "reset", "follow" },
        icon = "Interface\\Icons\\Ability_Tracking",
        title = L["HUD_FOLLOW_TITLE"],
        desc = L["HUD_FOLLOW_DESC"],
        color = { 0.2, 1.0, 0.2 }
    },
    {
        name = L["HUD_SUMMON_NAME"],
        cmd = "summon",
        icon = "Interface\\Icons\\Spell_Nature_AstralRecalGroup",
        title = L["HUD_SUMMON_TITLE"],
        desc = L["HUD_SUMMON_DESC"],
        color = { 0.2, 0.8, 1.0 }
    },
    {
        name = L["HUD_FLEE_NAME"],
        cmd = "flee",
        icon = "Interface\\Icons\\Spell_Magic_PolymorphChicken",
        title = L["HUD_FLEE_TITLE"],
        desc = L["HUD_FLEE_DESC"],
        color = { 1.0, 0.3, 0.3 }
    },
    {
        name = L["HUD_FORM_CYCLE_NAME"],
        actionKind = "formation_cycle",
        isFormationCycle = true,
        icon = "Interface\\Icons\\Ability_TrueShot",
        title = L["HUD_FORM_CYCLE_TITLE"],
        desc = L["HUD_FORM_CYCLE_DESC"],
        color = { 0.55, 0.55, 0.58 }
    },
    {
        name = L["HUD_MOVEGRP_NAME"],
        cmd = "move from group",
        icon = "Interface\\Icons\\Ability_Rogue_Sprint",
        title = L["HUD_MOVEGRP_TITLE"],
        desc = L["HUD_MOVEGRP_DESC"],
        color = { 0.34, 0.85, 0.55 }
    },
}

local UTIL_ACTIONS = {
    {
        name = L["HUD_TALK_NAME"],
        actionKind = "talk",
        isTalkPicker = true,
        icon = "Interface\\Icons\\Achievement_Reputation_01",
        title = L["HUD_TALK_TITLE"],
        desc = L["HUD_TALK_DESC"],
        color = { 0.2, 0.8, 1.0 }
    },
    {
        name = L["HUD_QUESTS_NAME"],
        actionKind = "quests",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        texCoord = { 0.13, 0.87, 0.13, 0.87 },
        title = L["HUD_QUESTS_TITLE"],
        desc = L["HUD_QUESTS_DESC"],
        color = { 1.0, 0.62, 0.15 }
    },
    {
        name = L["HUD_PARTY_NAME"],
        actionKind = "party_tab",
        icon = "Interface\\Icons\\INV_Misc_GroupLooking",
        title = L["HUD_PARTY_TITLE"],
        desc = L["HUD_PARTY_DESC"],
        color = { 0.95, 0.78, 0.25 }
    },
    {
        name = L["HUD_INV_NAME"],
        actionKind = "inventory",
        icon = "Interface\\Icons\\INV_Misc_Bag_08",
        title = L["HUD_INV_TITLE"],
        desc = L["HUD_INV_DESC"],
        color = { 0.35, 0.88, 0.45 }
    },
    {
        name = L["HUD_CHAR_NAME"],
        actionKind = "spells",
        icon = "Interface\\Icons\\Achievement_Character_Human_Male",
        title = L["HUD_CHAR_TITLE"],
        desc = L["HUD_CHAR_DESC"],
        color = { 0.68, 0.45, 1.0 }
    },
}

local function GetOrCreateHudBotDropDown()
    if hudBotDropDown then return hudBotDropDown end
    hudBotDropDown = CreateFrame("Frame", "DungeonBots_HUDTalkDropDown", UIParent, "UIDropDownMenuTemplate")
    hudBotDropDown.displayMode = "MENU"
    hudBotDropDown:Hide()
    return hudBotDropDown
end

local function IsCursorOverFrame(frame)
    if not frame or not frame.IsShown or not frame:IsShown() then
        return false
    end
    if MouseIsOver then
        return MouseIsOver(frame)
    end
    local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
    if not (left and right and top and bottom) then
        return false
    end
    local scale = frame:GetEffectiveScale() or 1
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    return cx >= left and cx <= right and cy >= bottom and cy <= top
end

local function EnsureHudMenuWatcher()
    if hudMenuWatcher then return hudMenuWatcher end
    hudMenuWatcher = CreateFrame("Frame", nil, UIParent)
    hudMenuWatcher:Hide()
    hudMenuWatcher:SetScript("OnUpdate", function(self)
        local list1 = _G.DropDownList1
        if not hudBotDropDown or UIDROPDOWNMENU_OPEN_MENU ~= hudBotDropDown or not list1 or not list1:IsShown() then
            self:Hide()
            hudMenuAnchorBtn = nil
            hudMenuMouseWasDown = false
            return
        end
        local down = IsMouseButtonDown and (
            IsMouseButtonDown("LeftButton")
            or IsMouseButtonDown("RightButton")
            or IsMouseButtonDown("MiddleButton")
        )
        if down then
            if not hudMenuMouseWasDown then
                hudMenuMouseWasDown = true
                local list2 = _G.DropDownList2
                local insideMenu = IsCursorOverFrame(list1) or IsCursorOverFrame(list2) or IsCursorOverFrame(hudMenuAnchorBtn)
                if not insideMenu and CloseDropDownMenus then
                    CloseDropDownMenus()
                end
            end
        else
            hudMenuMouseWasDown = false
        end
    end)
    return hudMenuWatcher
end

local function OpenAnchoredHudMenu(anchorBtn, buildMenuFn)
    local dd = GetOrCreateHudBotDropDown()
    if UIDROPDOWNMENU_OPEN_MENU ~= dd and CloseDropDownMenus then
        CloseDropDownMenus()
    end
    local bottomY = anchorBtn.GetBottom and anchorBtn:GetBottom() or 0
    local opensUp = (bottomY < 220)
    if opensUp then
        dd.point = "BOTTOMLEFT"
        dd.relativePoint = "TOPLEFT"
    else
        dd.point = "TOPLEFT"
        dd.relativePoint = "BOTTOMLEFT"
    end
    UIDropDownMenu_Initialize(dd, buildMenuFn, "MENU")
    ToggleDropDownMenu(1, nil, dd, anchorBtn, 0, opensUp and 4 or -4)

    local list1 = _G.DropDownList1
    if UIDROPDOWNMENU_OPEN_MENU == dd and list1 and list1:IsShown() then
        hudMenuAnchorBtn = anchorBtn
        hudMenuMouseWasDown = IsMouseButtonDown and (
            IsMouseButtonDown("LeftButton")
            or IsMouseButtonDown("RightButton")
            or IsMouseButtonDown("MiddleButton")
        ) and true or false
        EnsureHudMenuWatcher():Show()
    else
        hudMenuAnchorBtn = nil
        hudMenuMouseWasDown = false
        if hudMenuWatcher then hudMenuWatcher:Hide() end
    end
end

local function OpenHudBotDropdown(anchorBtn, headerTitle, emptyWarnMsg, onSelectBot, directIfSingle, showProximity)
    local bots = DungeonBots.GetPartyBotsList and DungeonBots:GetPartyBotsList() or {}
    if #bots == 0 then
        if CloseDropDownMenus then CloseDropDownMenus() end
        DungeonBots:Warn(emptyWarnMsg)
        return
    end
    if directIfSingle and #bots == 1 then
        if CloseDropDownMenus then CloseDropDownMenus() end
        onSelectBot(bots[1].name)
        return
    end

    OpenAnchoredHudMenu(anchorBtn, function(self, level)
        local infoTitle = UIDropDownMenu_CreateInfo()
        infoTitle.text = headerTitle or L["HUD_PICK_BOT"]
        infoTitle.isTitle = true
        infoTitle.notCheckable = true
        UIDropDownMenu_AddButton(infoTitle, level)

        for _, bot in ipairs(bots) do
            local info = UIDropDownMenu_CreateInfo()
            local c = (bot.classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[bot.classToken]) or { r = 1.0, g = 0.82, b = 0.0 }
            local hex = string.format("|cff%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
            local rowText = hex .. bot.name .. "|r"
            if showProximity and DungeonBots.GetBotProximityInfo then
                local prox = DungeonBots:GetBotProximityInfo(bot.name)
                if prox and prox.shortLabel then
                    rowText = rowText .. " " .. (prox.colorHex or "|cffaaaaaa") .. "(" .. prox.shortLabel .. ")|r"
                end
            end
            info.text = rowText
            info.notCheckable = true
            local chosenName = bot.name
            info.func = function()
                if CloseDropDownMenus then CloseDropDownMenus() end
                onSelectBot(chosenName)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end
DB_Internal.OpenPartyBotDropdown = OpenHudBotDropdown

local function GetFormationCycleState()
    local active = (DungeonBotsDB and DungeonBotsDB.activeFormation) or "chaos"
    if active == "arrow" then
        return "arrow", L["HUD_FORM_LBL_ARROW"], { 0.20, 0.85, 1.0 }
    elseif active == "near" then
        return "near", L["HUD_FORM_LBL_NEAR"], { 1.0, 0.82, 0.20 }
    end
    return "chaos", L["HUD_FORM_LBL_CHAOS"], { 0.55, 0.55, 0.58 }
end

local function UpdateFormationCycleButtonVisual()
    if not hudFormCycleBtn then return end
    local _, _, color = GetFormationCycleState()
    hudFormCycleBtn:SetBackdropBorderColor(color[1], color[2], color[3], 0.90)
end

local function CycleFormationMode()
    local curId = GetFormationCycleState()
    local nextId
    if curId == "arrow" then
        nextId = "near"
    elseif curId == "near" then
        nextId = "chaos"
    else
        nextId = "arrow"
    end
    if DungeonBotsDB then
        DungeonBotsDB.activeFormation = nextId
    end
    DungeonBots:SendPartyCommand("formation " .. nextId)
    local _, labelText = GetFormationCycleState()
    DungeonBots:Print(string.format(L["HUD_MSG_FORMATION"], labelText))
    UpdateFormationCycleButtonVisual()
end

local function GetSavedSeconds(dbKey, defaultVal, validList)
    local val = DungeonBotsDB and tonumber(DungeonBotsDB[dbKey])
    if val then
        for _, v in ipairs(validList) do
            if val == v then return val end
        end
    end
    return defaultVal
end

local function ApplyDpsWaitStrategy(secs)
    if secs > 0 then
        DungeonBots:SendPartyCommand("@dps co +wait for attack")
        DungeonBots:SendPartyCommand("@dps wait for attack time " .. secs)
    else
        DungeonBots:SendPartyCommand("@dps co -wait for attack")
    end
end

local function UpdateCombatActionWaitBadges()
    if hudAttackBtn and hudAttackBtn.waitBadge then
        local secs = GetSavedSeconds("attackWaitSeconds", 0, ATTACK_WAIT_OPTIONS)
        hudAttackBtn.waitBadge:SetText(secs .. "s")
    end
    if hudPullBtn and hudPullBtn.waitBadge then
        local secs = GetSavedSeconds("pullWaitSeconds", 8, PULL_WAIT_OPTIONS)
        hudPullBtn.waitBadge:SetText(secs .. "s")
    end
end

local function OpenWaitDelayDropdown(anchorBtn, cfgMenu)
    local cur = GetSavedSeconds(cfgMenu.dbKey, cfgMenu.defaultVal, cfgMenu.options)
    OpenAnchoredHudMenu(anchorBtn, function(_, level)
        local titleInfo = UIDropDownMenu_CreateInfo()
        titleInfo.text = cfgMenu.menuTitle
        titleInfo.isTitle = true
        titleInfo.notCheckable = true
        UIDropDownMenu_AddButton(titleInfo, level)

        for _, secs in ipairs(cfgMenu.options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = (secs == 0) and L["HUD_ATK_OPT_NOWAIT"] or string.format(L["HUD_WAIT_SEC_FMT"], secs)
            info.checked = (cur == secs)
            local chosen = secs
            info.func = function()
                if CloseDropDownMenus then CloseDropDownMenus() end
                if DungeonBotsDB then
                    DungeonBotsDB[cfgMenu.dbKey] = chosen
                end
                ApplyDpsWaitStrategy(chosen)
                UpdateCombatActionWaitBadges()
                if chosen == 0 and cfgMenu.setZeroMsg then
                    DungeonBots:Print(cfgMenu.setZeroMsg)
                else
                    DungeonBots:Print(string.format(cfgMenu.setSecFmt, chosen))
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end

local function ExecuteAttackTargetSequence()
    if CloseDropDownMenus then CloseDropDownMenus() end
    DungeonBots:SendPartyCommand("reset")
    DungeonBots:SendPartyCommand("follow")
    local forceNoWait = IsShiftKeyDown and IsShiftKeyDown()
    local secs = forceNoWait and 0 or GetSavedSeconds("attackWaitSeconds", 0, ATTACK_WAIT_OPTIONS)
    ApplyDpsWaitStrategy(secs)
    DungeonBots:SendPartyCommand("@tank attack")
    DungeonBots:SendPartyCommand("@dps attack")
end

local function ExecutePullBackSequence()
    if CloseDropDownMenus then CloseDropDownMenus() end
    DungeonBots:SendPartyCommand("reset")
    local secs = GetSavedSeconds("pullWaitSeconds", 8, PULL_WAIT_OPTIONS)
    ApplyDpsWaitStrategy(secs)
    DungeonBots:SendPartyCommand("@tank pull back")
end

local function HasLivingTarget()
    return UnitExists("target") and not UnitIsDeadOrGhost("target")
end

local function ShowHudButtonTooltip(btn, action)
    GameTooltip:SetOwner(btn, "ANCHOR_TOP")
    GameTooltip:AddLine(action.title, 1, 1, 1)
    GameTooltip:AddLine(action.desc, 0.85, 0.85, 0.85, true)
    if action.actionKind == "attack_target" then
        local secs = GetSavedSeconds("attackWaitSeconds", 0, ATTACK_WAIT_OPTIONS)
        GameTooltip:AddLine(" ")
        if secs == 0 then
            GameTooltip:AddLine(L["HUD_ATK_CUR_NOWAIT"], 1, 1, 1)
        else
            GameTooltip:AddLine(string.format(L["HUD_ATK_CUR_SEC_FMT"], secs), 1, 1, 1)
        end
    elseif action.actionKind == "pull_back" then
        local secs = GetSavedSeconds("pullWaitSeconds", 8, PULL_WAIT_OPTIONS)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format(L["HUD_PULL_CUR_SEC_FMT"], secs), 1, 1, 1)
    elseif action.isFormationCycle then
        local _, labelText = GetFormationCycleState()
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format(L["HUD_FORM_CUR_FMT"], labelText), 1, 1, 1)
    elseif action.isTalkPicker and DungeonBots.HasValidNpcTarget and not DungeonBots:HasValidNpcTarget() then
        GameTooltip:AddLine(L["HUD_NOTE_VALID_NPC"], 1.0, 0.72, 0.25, true)
    end
    if action.requiresTarget and not HasLivingTarget() then
        if not UnitExists("target") then
            GameTooltip:AddLine(L["HUD_NOTE_TARGET_FIRST"], 1.0, 0.72, 0.25, true)
        else
            GameTooltip:AddLine(L["HUD_NOTE_TARGET_DEAD"], 1.0, 0.40, 0.35, true)
        end
    end
    GameTooltip:Show()
end

local function HandleHudTalkClick(anchorBtn)
    if DungeonBots.HasValidNpcTarget and not DungeonBots:HasValidNpcTarget() then
        PlaySound("igQuestFailed")
        DungeonBots:Warn(L["HUD_SELECT_VALID_NPC"])
        return
    end
    OpenHudBotDropdown(
        anchorBtn,
        L["HUD_PICK_BOT"],
        L["HUD_NO_BOTS_TALK"],
        function(chosenName)
            DungeonBots:SendTalkCommand(chosenName, "talk")
        end,
        true,
        true
    )
end

local function HandleUtilActionClick(anchorBtn, action)
    if action.actionKind == "talk" then
        HandleHudTalkClick(anchorBtn)
    elseif action.actionKind == "party_tab" then
        if CloseDropDownMenus then CloseDropDownMenus() end
        if DungeonBots.OpenTab then
            DungeonBots:OpenTab(2)
        end
    elseif action.actionKind == "inventory" then
        OpenHudBotDropdown(
            anchorBtn,
            L["HUD_PICK_BOT_INV"],
            L["HUD_NO_BOTS_INV"],
            function(chosenName)
                if DungeonBots.QueryBotInventory then
                    DungeonBots:QueryBotInventory(chosenName)
                end
            end,
            true
        )
    elseif action.actionKind == "spells" then
        OpenHudBotDropdown(
            anchorBtn,
            L["HUD_PICK_BOT_CHAR"],
            L["HUD_NO_BOTS_CHAR"],
            function(chosenName)
                if DungeonBots.QueryBotSpells then
                    DungeonBots:QueryBotSpells(chosenName, "gear", "", false)
                end
            end,
            true,
            true
        )
    elseif action.actionKind == "quests" then
        OpenHudBotDropdown(
            anchorBtn,
            L["HUD_PICK_BOT_QUESTS"],
            L["HUD_NO_BOTS_QUESTS"],
            function(chosenName)
                if DungeonBots.QueryQuests then
                    DungeonBots:QueryQuests(chosenName)
                end
            end,
            true
        )
    end
end

function DungeonBots:IsInFiveManDungeon()
    local inInstance, instanceType = IsInInstance()
    return (inInstance and instanceType == "party") and true or false
end

function DungeonBots:UpdateHUDTalkButtonState()
    if not hudTalkBtn then return end
    local canTalk = (DungeonBots.HasValidNpcTarget and DungeonBots:HasValidNpcTarget()) and true or false
    local c = (hudTalkBtn.actionDef and hudTalkBtn.actionDef.color) or { 0.2, 0.8, 1.0 }
    -- Mantener siempre su aspecto de color normal y habilitado para hover/clic
    hudTalkBtn:Enable()
    hudTalkBtn.isTalkReady = canTalk
    hudTalkBtn:SetAlpha(1.0)
    if hudTalkBtn.icon then
        hudTalkBtn.icon:SetDesaturated(false)
        hudTalkBtn.icon:SetVertexColor(1, 1, 1, 1)
    end
    hudTalkBtn:SetBackdropBorderColor(c[1], c[2], c[3], 0.85)
    if hudTalkBtn.highlightTex then
        hudTalkBtn.highlightTex:Show()
    end
    if not canTalk and hudBotDropDown and UIDROPDOWNMENU_OPEN_MENU == hudBotDropDown and CloseDropDownMenus then
        CloseDropDownMenus()
    end
end

local function ApplyBarVisibility(barFrame, visibleKey)
    if not barFrame then return false end
    if DungeonBotsDB and DungeonBotsDB[visibleKey] == false then
        barFrame:Hide()
        return false
    end
    local onlyInDungeon = (not DungeonBotsDB) or (DungeonBotsDB.hudOnlyInDungeon ~= false)
    if onlyInDungeon and not DungeonBots:IsInFiveManDungeon() then
        barFrame:Hide()
        return false
    end
    barFrame:Show()
    return true
end

function DungeonBots:UpdateHUDVisibility()
    ApplyBarVisibility(hudFrame, "hudVisible")
    if ApplyBarVisibility(utilHudFrame, "utilHudVisible") then
        DungeonBots:UpdateHUDTalkButtonState()
    end
end

function DungeonBots:IsHUDLocked()
    return (DungeonBotsDB and DungeonBotsDB.hudLocked) and true or false
end

function DungeonBots:SetHUDLocked(locked, silent)
    local isLocked = locked and true or false
    if DungeonBotsDB then
        DungeonBotsDB.hudLocked = isLocked
        DungeonBotsDB.utilHudLocked = isLocked
    end
    if DungeonBots.UpdateHUDLockButtonState then
        DungeonBots:UpdateHUDLockButtonState()
    end
    if not silent then
        if isLocked then
            DungeonBots:Print(L["HUD_BARS_LOCKED"])
        else
            DungeonBots:Print(L["HUD_BARS_UNLOCKED"])
        end
    end
end

function DungeonBots:ToggleHUDLock()
    DungeonBots:SetHUDLocked(not DungeonBots:IsHUDLocked(), false)
end

local function CreateFloatingToolbar(cfg)
    local actions = cfg.actions or {}
    local btnSize = 34
    local spacing = 4
    local startX = 8
    local rightPad = cfg.showMainPanelBtn and 28 or 8
    local totalWidth = startX + (#actions * (btnSize + spacing)) - spacing + rightPad

    local f = CreateFrame("Frame", cfg.frameName, UIParent)
    f:SetSize(totalWidth, 48)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    local pos = (DungeonBotsDB and DungeonBotsDB[cfg.posKey]) or cfg.defaultPos
    f:SetPoint(pos.point or "BOTTOM", UIParent, pos.point or "BOTTOM", pos.x or 0, pos.y or cfg.defaultPos.y)

    f:SetScript("OnDragStart", function(self)
        if not DungeonBots:IsHUDLocked() then
            self:StartMoving()
        end
    end)

    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        if DungeonBotsDB then
            DungeonBotsDB[cfg.posKey] = { point = point, x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
        end
    end)

    if DB_Internal and DB_Internal.ApplyBlizzardStonePanel then
        DB_Internal.ApplyBlizzardStonePanel(f, 0.78, 0.64, 0.34, 12, 0.30)
    else
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0.09, 0.075, 0.055, 0.94)
        f:SetBackdropBorderColor(0.78, 0.64, 0.34, 1.0)
    end

    for i, action in ipairs(actions) do
        local btn = CreateFrame("Button", cfg.btnPrefix .. i, f)
        btn:SetSize(btnSize, btnSize)
        btn:SetPoint("LEFT", f, "LEFT", startX + (i - 1) * (btnSize + spacing), 0)
        if action.hasRightClickMenu then
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        else
            btn:RegisterForClicks("LeftButtonUp")
        end

        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        local function StyleHudBtn(b)
            local p = DB_Internal and DB_Internal.GetThemePalette and DB_Internal.GetThemePalette()
            local c = p and p.hudBtnBg or { 0.09, 0.075, 0.055, 0.95 }
            b:SetBackdropColor(c[1], c[2], c[3], c[4])
        end
        StyleHudBtn(btn)
        if DB_Internal and DB_Internal.RegisterThemed then
            DB_Internal.RegisterThemed(btn, StyleHudBtn)
        end
        btn:SetBackdropBorderColor(action.color[1], action.color[2], action.color[3], 0.85)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        local pad = action.iconInset or 3
        icon:SetPoint("TOPLEFT", pad, -pad)
        icon:SetPoint("BOTTOMRIGHT", -pad, pad)
        icon:SetTexture(action.icon)
        if action.texCoord then
            icon:SetTexCoord(action.texCoord[1], action.texCoord[2], action.texCoord[3], action.texCoord[4])
        elseif action.fullTexCoord then
            icon:SetTexCoord(0, 1, 0, 1)
        else
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetPoint("TOPLEFT", 3, -3)
        highlight:SetPoint("BOTTOMRIGHT", -3, 3)
        highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlight:SetBlendMode("ADD")

        btn.icon = icon
        btn.highlightTex = highlight
        btn.actionDef = action
        if action.actionKind == "attack_target" or action.actionKind == "pull_back" then
            local badge = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
            badge:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 2)
            badge:SetJustifyH("RIGHT")
            btn.waitBadge = badge
            if action.actionKind == "attack_target" then
                hudAttackBtn = btn
            else
                hudPullBtn = btn
            end
        elseif action.isTalkPicker then
            hudTalkBtn = btn
        elseif action.isFormationCycle then
            hudFormCycleBtn = btn
            UpdateFormationCycleButtonVisual()
        end

        btn:SetScript("OnClick", function(self, mouseBtn)
            if mouseBtn == "RightButton" then
                if action.hasRightClickMenu and cfg.onRightClick then
                    PlaySound("igMainMenuOptionCheckBoxOn")
                    cfg.onRightClick(self, action)
                end
                return
            end
            if action.requiresTarget and not HasLivingTarget() then
                return
            end
            if action.isTalkPicker and DungeonBots.HasValidNpcTarget and not DungeonBots:HasValidNpcTarget() then
                cfg.onActionClick(self, action)
                return
            end
            PlaySound("igMainMenuOptionCheckBoxOn")
            cfg.onActionClick(self, action)
            if action.isFormationCycle and GameTooltip and GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
                ShowHudButtonTooltip(self, action)
            end
        end)

        btn:SetScript("OnEnter", function(self)
            ShowHudButtonTooltip(self, action)
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    if cfg.showMainPanelBtn then
        local mainBtn = CreateFrame("Button", "DungeonBots_HUDMainPanelBtn", f)
        mainBtn:SetSize(16, 16)
        mainBtn:SetPoint("RIGHT", f, "RIGHT", -6, 0)
        mainBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        local mainIcon = mainBtn:CreateTexture(nil, "ARTWORK")
        mainIcon:SetAllPoints()
        mainIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
        mainIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        mainBtn.icon = mainIcon
        f.mainPanelBtn = mainBtn

        mainBtn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            DungeonBots:ToggleUI()
        end)
        mainBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(L["HUD_TIP_OPEN_TITLE"], 1, 1, 1)
            GameTooltip:AddLine(L["HUD_TIP_OPEN_DESC"], 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        mainBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return f
end

function DungeonBots:InitHUD()
    if DungeonBotsDB then
        local locked = DungeonBots:IsHUDLocked()
        DungeonBotsDB.hudLocked = locked
        DungeonBotsDB.utilHudLocked = locked
    end

    if not hudFrame then
        hudFrame = CreateFloatingToolbar({
            frameName = "DungeonBots_HUDFrame",
            posKey = "hudPosition",
            defaultPos = { point = "BOTTOM", x = 0, y = 140 },
            actions = TACTICAL_ACTIONS,
            btnPrefix = "DungeonBots_HUDExtBtn_",
            showMainPanelBtn = false,
            onActionClick = function(_, action)
                if action.actionKind == "attack_target" then
                    ExecuteAttackTargetSequence()
                    return
                elseif action.actionKind == "pull_back" then
                    ExecutePullBackSequence()
                    return
                elseif action.actionKind == "formation_cycle" then
                    CycleFormationMode()
                    return
                elseif action.cmds then
                    for _, c in ipairs(action.cmds) do
                        DungeonBots:SendPartyCommand(c)
                    end
                    return
                end
                DungeonBots:SendPartyCommand(action.cmd)
                if action.cmd == "move from group" then
                    DungeonBots:Print(L["HUD_MSG_SPREAD_SENT"])
                end
            end,
            onRightClick = function(btn, action)
                if action.actionKind == "attack_target" then
                    OpenWaitDelayDropdown(btn, {
                        dbKey = "attackWaitSeconds",
                        defaultVal = 0,
                        options = ATTACK_WAIT_OPTIONS,
                        menuTitle = L["HUD_ATK_MENU_TITLE"],
                        setZeroMsg = L["HUD_ATK_SET_NOWAIT"],
                        setSecFmt = L["HUD_ATK_SET_SEC_FMT"],
                    })
                elseif action.actionKind == "pull_back" then
                    OpenWaitDelayDropdown(btn, {
                        dbKey = "pullWaitSeconds",
                        defaultVal = 8,
                        options = PULL_WAIT_OPTIONS,
                        menuTitle = L["HUD_PULL_MENU_TITLE"],
                        setSecFmt = L["HUD_PULL_SET_SEC_FMT"],
                    })
                end
            end,
        })
        DungeonBots.hudFrame = hudFrame
    end

    if not utilHudFrame then
        utilHudFrame = CreateFloatingToolbar({
            frameName = "DungeonBots_UtilHUDFrame",
            posKey = "utilHudPosition",
            defaultPos = { point = "BOTTOM", x = 0, y = 194 },
            actions = UTIL_ACTIONS,
            btnPrefix = "DungeonBots_UtilExtBtn_",
            showMainPanelBtn = true,
            onActionClick = function(btn, action)
                HandleUtilActionClick(btn, action)
            end,
        })
        DungeonBots.utilHudFrame = utilHudFrame
    end

    UpdateCombatActionWaitBadges()
    UpdateFormationCycleButtonVisual()
    DungeonBots:UpdateHUDTalkButtonState()
    DungeonBots:UpdateHUDVisibility()
    if DungeonBots.UpdateHUDLockButtonState then
        DungeonBots:UpdateHUDLockButtonState()
    end
end

function DungeonBots:ResetHUDPositions()
    if not DungeonBotsDB then return end
    DungeonBotsDB.hudPosition = { point = "BOTTOM", x = 0, y = 140 }
    DungeonBotsDB.utilHudPosition = { point = "BOTTOM", x = 0, y = 194 }
    if hudFrame then
        hudFrame:ClearAllPoints()
        hudFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 140)
    end
    if utilHudFrame then
        utilHudFrame:ClearAllPoints()
        utilHudFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 194)
    end
end

function DungeonBots:ToggleHUD()
    if not hudFrame then
        DungeonBots:InitHUD()
    end
    if hudFrame:IsShown() then
        hudFrame:Hide()
        if DungeonBotsDB then DungeonBotsDB.hudVisible = false end
        DungeonBots:Print(L["HUD_HIDDEN_MSG"])
    else
        if DungeonBotsDB then DungeonBotsDB.hudVisible = true end
        DungeonBots:UpdateHUDVisibility()
        if hudFrame:IsShown() then
            DungeonBots:Print(L["HUD_VISIBLE_MSG"])
        else
            DungeonBots:Print(L["HUD_ARMED_DUNGEON_MSG"])
        end
    end
    if DungeonBots.UpdateSettingsDialog then
        DungeonBots:UpdateSettingsDialog()
    end
end
