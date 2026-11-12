-- =========================================================================
-- DungeonBots_Talents.lua: Análisis de Talentos, Especializaciones y Autogear
-- =========================================================================

DungeonBots = DungeonBots or {}
DungeonBots.Internal = DungeonBots.Internal or {}

local DB_Internal = DungeonBots.Internal

local function NowTime()
    return DB_Internal.NowTime()
end

local function StripWowFormatting(text)
    return DB_Internal.StripWowFormatting(text)
end

local function EscapeLuaPattern(str)
    return DB_Internal.EscapeLuaPattern(str)
end

-- =========================================================================
-- Limpieza y Normalización de Ramas de Talentos
-- =========================================================================
local SPEC_NOISE_PREFIXES = {
    "available talent specs", "available specs", "available spec",
    "current talent spec", "current spec", "active spec",
    "my talent spec", "my spec", "using spec",
    "current talents", "my talents", "talents",
    "picking spec", "picked spec", "selecting spec", "selected spec",
    "choosing spec", "chose spec",
    "switching to spec", "switching to", "switched to spec", "switched to",
    "changing to spec", "changing to", "changed to spec", "changed to",
    "picking", "picked", "selecting", "selected",
    "choosing", "chose", "switching", "switched",
    "changing", "changed", "applying", "applied", "using",
    "rama actual", "specs", "spec",
}

local function StripSpecNoisePrefix(text)
    if not text or text == "" then return "" end
    local s = StripWowFormatting(text)
    s = string.gsub(s, "^%s*%d+%s*[%.%)%]:%-]+%s*", "")
    s = string.gsub(s, "^%s*(.-)%s*$", "%1")
    local colonPos = string.find(s, ":", 1, true)
    if colonPos then
        local head = string.lower(string.sub(s, 1, colonPos - 1))
        if string.find(head, "spec", 1, true)
            or string.find(head, "talent", 1, true)
            or string.find(head, "available", 1, true)
            or string.find(head, "rama", 1, true) then
            s = string.sub(s, colonPos + 1)
        end
    end
    local changed = true
    while changed do
        changed = false
        s = string.gsub(s, "^[%s%*:>%-=]+", "")
        local ls = string.lower(s)
        for _, p in ipairs(SPEC_NOISE_PREFIXES) do
            if string.sub(ls, 1, #p) == p then
                local nextCh = string.sub(ls, #p + 1, #p + 1)
                if nextCh == "" or string.match(nextCh, "[%s:=%-]") then
                    s = string.sub(s, #p + 1)
                    changed = true
                    break
                end
            end
        end
    end
    s = string.gsub(s, "^[%s%*:>%-=]+", "")
    s = string.gsub(s, "^%s*(.-)%s*$", "%1")
    return s
end

function DungeonBots:CleanSpecText(specText)
    if not specText or specText == "" then return "" end
    local cleaned = StripWowFormatting(specText)
    cleaned = string.gsub(cleaned, "%s*%([^%)]*%d[^%)]*%)", "")
    cleaned = string.gsub(cleaned, "^[%s:=]+", "")
    cleaned = string.gsub(cleaned, "^[Ii][Ss][%s:=]+", "")
    cleaned = string.gsub(cleaned, "^[Ee][Ss][%s:=]+", "")
    cleaned = StripSpecNoisePrefix(cleaned)
    cleaned = string.gsub(cleaned, "^[Ii][Ss][%s:=]+", "")
    cleaned = string.gsub(cleaned, "^[Ee][Ss][%s:=]+", "")
    cleaned = string.gsub(cleaned, "^[%s:=]+", "")
    cleaned = string.gsub(cleaned, "^%s*(.-)%s*$", "%1")
    return cleaned
end

local TREE_ALIASES = {
    ["arcane"] = "arcane", ["arcano"] = "arcane",
    ["fire"] = "fire", ["fuego"] = "fire",
    ["frost"] = "frost", ["escarcha"] = "frost",
    ["frostfire"] = "frostfire",
    ["protection"] = "protection", ["proteccion"] = "protection", ["protección"] = "protection",
    ["holy"] = "holy", ["sagrado"] = "holy",
    ["retribution"] = "retribution", ["reprension"] = "retribution", ["reprensión"] = "retribution",
    ["discipline"] = "discipline", ["disciplina"] = "discipline",
    ["shadow"] = "shadow", ["sombras"] = "shadow",
    ["feral"] = "feral",
    ["balance"] = "balance", ["equilibrio"] = "balance",
    ["restoration"] = "restoration", ["restauracion"] = "restoration", ["restauración"] = "restoration",
    ["elemental"] = "elemental",
    ["enhancement"] = "enhancement", ["mejora"] = "enhancement",
    ["affliction"] = "affliction", ["afliccion"] = "affliction", ["aflicción"] = "affliction",
    ["demonology"] = "demonology", ["demonologia"] = "demonology", ["demonología"] = "demonology",
    ["destruction"] = "destruction", ["destruccion"] = "destruction", ["destrucción"] = "destruction",
    ["beastmastery"] = "beastmastery", ["beast mastery"] = "beastmastery", ["bestias"] = "beastmastery",
    ["marksmanship"] = "marksmanship", ["punteria"] = "marksmanship", ["puntería"] = "marksmanship",
    ["survival"] = "survival", ["supervivencia"] = "survival",
    ["combat"] = "combat", ["combate"] = "combat",
    ["assassination"] = "assassination", ["asesinato"] = "assassination",
    ["subtlety"] = "subtlety", ["sutileza"] = "subtlety",
    ["arms"] = "arms", ["armas"] = "arms",
    ["fury"] = "fury", ["furia"] = "fury",
    ["blood"] = "blood", ["sangre"] = "blood",
    ["double aura blood"] = "double aura blood", ["double aura"] = "double aura blood",
    ["unholy"] = "unholy", ["profano"] = "unholy",
}

local CLASS_TREE_BY_TAB = {
    WARRIOR     = { "arms", "fury", "protection" },
    PALADIN     = { "holy", "protection", "retribution" },
    HUNTER      = { "beastmastery", "marksmanship", "survival" },
    ROGUE       = { "assassination", "combat", "subtlety" },
    PRIEST      = { "discipline", "holy", "shadow" },
    DEATHKNIGHT = { "blood", "frost", "unholy" },
    SHAMAN      = { "elemental", "enhancement", "restoration" },
    MAGE        = { "arcane", "fire", "frost" },
    WARLOCK     = { "affliction", "demonology", "destruction" },
    DRUID       = { "balance", "feral", "restoration" },
}

local function ResolveTreeToSpec(botName, treeKey)
    local specs = DungeonBots.botSpecs and DungeonBots.botSpecs[botName]
    if (not specs or #specs == 0) then
        local unit = DungeonBots:FindPartyUnitByName(botName)
        if unit then
            local _, classToken = UnitClass(unit)
            if classToken and DungeonBots.DEFAULT_CLASS_SPECS then
                specs = DungeonBots.DEFAULT_CLASS_SPECS[classToken]
            end
        end
    end
    if specs and treeKey and treeKey ~= "" then
        local lowerKey = string.lower(treeKey)
        local prefixPat = "^" .. EscapeLuaPattern(lowerKey) .. "[%s_-]"
        for _, s in ipairs(specs) do
            local ls = string.lower(s)
            if (ls == lowerKey or string.match(ls, prefixPat)) and string.find(ls, "pve", 1, true) then
                return s
            end
        end
        for _, s in ipairs(specs) do
            local ls = string.lower(s)
            if ls == lowerKey or string.match(ls, prefixPat) then
                return s
            end
        end
        for _, s in ipairs(specs) do
            local ls = string.lower(s)
            if string.find(ls, lowerKey, 1, true) and string.find(ls, "pve", 1, true) then
                return s
            end
        end
        for _, s in ipairs(specs) do
            if string.find(string.lower(s), lowerKey, 1, true) then
                return s
            end
        end
    end
    return treeKey
end
DB_Internal.ResolveTreeToSpec = ResolveTreeToSpec

function DungeonBots:CanonicalizeSpec(botName, specText)
    if not specText or specText == "" then return "" end
    local cleaned = DungeonBots:CleanSpecText(specText)
    if cleaned == "" then return "" end
    local lowerCleaned = string.lower(cleaned)
    local specs = DungeonBots.botSpecs and DungeonBots.botSpecs[botName]
    if (not specs or #specs == 0) then
        local unit = DungeonBots:FindPartyUnitByName(botName)
        if unit then
            local _, classToken = UnitClass(unit)
            if classToken and DungeonBots.DEFAULT_CLASS_SPECS then
                specs = DungeonBots.DEFAULT_CLASS_SPECS[classToken]
            end
        end
    end
    if specs then
        for _, s in ipairs(specs) do
            if string.lower(s) == lowerCleaned then
                return s
            end
        end
    end
    return cleaned
end

local function ExtractSpecCandidate(chunk)
    local body = StripSpecNoisePrefix(chunk)
    if body == "" then return nil end
    local parsed = string.match(body, "([%a][%a%s_-]*)%s*%(%s*%d+%s*[-/]%s*%d+%s*[-/]%s*%d+%s*%)")
    if not parsed then
        parsed = string.match(body, "([%a][%a%s_-]*%s+pv[ep])")
    end
    if not parsed then return nil end
    parsed = StripSpecNoisePrefix(parsed)
    parsed = string.gsub(parsed, "%s*%*+%s*$", "")
    parsed = DungeonBots:CleanSpecText(parsed)
    local lowerParsed = string.lower(parsed)
    if lowerParsed == "" or string.find(lowerParsed, "available", 1, true) then
        return nil
    end
    return parsed
end

local function ResolveTripletToSpec(botName, p1, p2, p3)
    local key = p1 .. "-" .. p2 .. "-" .. p3
    if DungeonBots.botSpecTriplets and DungeonBots.botSpecTriplets[botName] and DungeonBots.botSpecTriplets[botName][key] then
        return DungeonBots.botSpecTriplets[botName][key]
    end
    local unit = DungeonBots:FindPartyUnitByName(botName)
    if unit then
        local _, classToken = UnitClass(unit)
        local tabs = classToken and CLASS_TREE_BY_TAB[classToken]
        if tabs then
            local counts = { tonumber(p1) or 0, tonumber(p2) or 0, tonumber(p3) or 0 }
            local bestIdx, bestVal = 1, counts[1]
            for idx = 2, 3 do
                if counts[idx] > bestVal then
                    bestVal = counts[idx]
                    bestIdx = idx
                end
            end
            if bestVal > 0 then
                return ResolveTreeToSpec(botName, tabs[bestIdx])
            end
        end
    end
    return nil
end

function DB_Internal.ParseTalentWhisper(cleanSender, message)
    local foundAnySpec = false
    local detectedActiveSpec = nil

    DungeonBots.liveTreePoints[cleanSender] = DungeonBots.liveTreePoints[cleanSender] or {}
    DungeonBots.botSpecTriplets[cleanSender] = DungeonBots.botSpecTriplets[cleanSender] or {}

    for rawLine in string.gmatch(message or "", "[^\r\n]+") do
        local line = StripWowFormatting(rawLine)
        local lowerLine = string.lower(line)
        local isAvailableListLine = (string.find(lowerLine, "available", 1, true) ~= nil)

        local directActive = string.match(lowerLine, "current%s+talent%s+spec%s+is%s*[:=%s]*(.+)")
            or string.match(lowerLine, "current%s+talent%s+spec%s*[:=%s]+(.+)")
            or string.match(lowerLine, "current%s+spec%s+is%s*[:=%s]*(.+)")
            or string.match(lowerLine, "current%s+spec%s*[:=%s]+(.+)")
            or string.match(lowerLine, "active%s+spec%s*[:=%s]+(.+)")
            or string.match(lowerLine, "my%s+spec%s+is%s*[:=%s]*(.+)")
            or string.match(lowerLine, "using%s+spec%s*[:=%s]+(.+)")
            or string.match(lowerLine, "rama%s+actual%s*[:=%s]+(.+)")
            or string.match(lowerLine, "current%s+talents%s*[:=%s]+(.+)")
            or string.match(lowerLine, "^%s*spec%s*:%s*(.+)")
        if not directActive then
            local talentsRest = string.match(lowerLine, "^%s*talents%s*:%s*(.+)")
            if talentsRest and not string.find(talentsRest, ",", 1, true) then
                directActive = talentsRest
            end
        end
        if directActive then
            directActive = string.gsub(directActive, "[%.!]+$", "")
            local dt1, dt2, dt3 = string.match(directActive, "(%d+)%s*[-/]%s*(%d+)%s*[-/]%s*(%d+)")
            local exactTripletSpec = nil
            if dt1 and dt2 and dt3 then
                local tripletKey = dt1 .. "-" .. dt2 .. "-" .. dt3
                DungeonBots.lastDetectedTriplet[cleanSender] = tripletKey
                if DungeonBots.botSpecTriplets and DungeonBots.botSpecTriplets[cleanSender] then
                    exactTripletSpec = DungeonBots.botSpecTriplets[cleanSender][tripletKey]
                end
            end
            local candidate = ExtractSpecCandidate(directActive) or DungeonBots:CleanSpecText(StripSpecNoisePrefix(directActive))
            candidate = DungeonBots:CleanSpecText(candidate)
            if exactTripletSpec and exactTripletSpec ~= "" then
                detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, exactTripletSpec)
            elseif candidate and candidate ~= "" and string.match(candidate, "%a") then
                local normDirectTree = TREE_ALIASES[string.lower(candidate)]
                if normDirectTree then
                    DungeonBots.lastDetectedTree[cleanSender] = normDirectTree
                    local byTriplet = (dt1 and dt2 and dt3) and ResolveTripletToSpec(cleanSender, dt1, dt2, dt3) or nil
                    candidate = byTriplet or ResolveTreeToSpec(cleanSender, normDirectTree)
                end
                detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, candidate)
            elseif dt1 and dt2 and dt3 then
                local resolvedT = ResolveTripletToSpec(cleanSender, dt1, dt2, dt3)
                if resolvedT then
                    detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, resolvedT)
                end
            end
        end

        local rawChunks = {}
        local greenChunkCount = 0
        for rawChunk in string.gmatch(rawLine, "[^,;]+") do
            local cleanChunk = string.gsub(StripWowFormatting(rawChunk), "^%s*(.-)%s*$", "%1")
            if cleanChunk ~= "" then
                local chunkHasGreen = (string.find(rawChunk, "|cff00ff00", 1, true) ~= nil)
                    or (string.find(rawChunk, "|cff34c759", 1, true) ~= nil)
                if chunkHasGreen then
                    greenChunkCount = greenChunkCount + 1
                end
                table.insert(rawChunks, { text = cleanChunk, isGreen = chunkHasGreen })
            end
        end

        for _, chunkInfo in ipairs(rawChunks) do
            local cleanChunk = chunkInfo.text
            local specName = ExtractSpecCandidate(cleanChunk)
            local t1, t2, t3 = string.match(cleanChunk, "(%d+)%s*[-/]%s*(%d+)%s*[-/]%s*(%d+)")
            local isBareTreeOnly = specName and (TREE_ALIASES[string.lower(specName)] ~= nil)
                and not string.find(string.lower(specName), "pv[ep]")

            if specName and (isAvailableListLine or not isBareTreeOnly) then
                if DungeonBots.pendingListReset[cleanSender] and (isAvailableListLine or string.find(string.lower(specName), "pv[ep]")) then
                    DungeonBots.botSpecs[cleanSender] = {}
                    DungeonBots.pendingListReset[cleanSender] = nil
                end
                specName = DungeonBots:CanonicalizeSpec(cleanSender, specName)
                DungeonBots.botSpecs[cleanSender] = DungeonBots.botSpecs[cleanSender] or {}
                local alreadyExists = false
                local lowerSpecName = string.lower(specName)
                for _, s in ipairs(DungeonBots.botSpecs[cleanSender]) do
                    if string.lower(s) == lowerSpecName then
                        alreadyExists = true
                        break
                    end
                end
                if not alreadyExists then
                    table.insert(DungeonBots.botSpecs[cleanSender], specName)
                    foundAnySpec = true
                end

                if t1 and t2 and t3 then
                    DungeonBots.botSpecTriplets[cleanSender][t1 .. "-" .. t2 .. "-" .. t3] = specName
                end

                local lc = string.lower(cleanChunk)
                local activeByGreen = chunkInfo.isGreen and ((not isAvailableListLine) or greenChunkCount == 1)
                if string.find(lc, "active", 1, true)
                    or string.find(lc, "current", 1, true)
                    or string.find(lc, "actual", 1, true)
                    or string.find(lc, "activo", 1, true)
                    or string.match(cleanChunk, "^%*")
                    or string.match(cleanChunk, ":%s*%*")
                    or string.match(cleanChunk, "%*$")
                    or string.match(cleanChunk, "^%->")
                    or string.match(cleanChunk, ":%s*%->")
                    or activeByGreen then
                    detectedActiveSpec = specName
                end
            elseif (t1 and t2 and t3) and not isAvailableListLine then
                DungeonBots.lastDetectedTriplet[cleanSender] = t1 .. "-" .. t2 .. "-" .. t3
                if specName and isBareTreeOnly then
                    local normTree = TREE_ALIASES[string.lower(specName)]
                    if normTree then
                        DungeonBots.lastDetectedTree[cleanSender] = normTree
                    end
                end
                if not detectedActiveSpec then
                    local resolvedFromTriplet = ResolveTripletToSpec(cleanSender, t1, t2, t3)
                    if not resolvedFromTriplet and specName and isBareTreeOnly then
                        local normTree = TREE_ALIASES[string.lower(specName)]
                        if normTree then
                            resolvedFromTriplet = ResolveTreeToSpec(cleanSender, normTree)
                        end
                    end
                    if resolvedFromTriplet then
                        detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, resolvedFromTriplet)
                    end
                end
            end

            if not isAvailableListLine then
                for rawTree, rawPts in string.gmatch(cleanChunk, "([%a ]+)%s*[:%(]?%s*(%d+)%)?") do
                    local key = string.lower(StripSpecNoisePrefix(rawTree))
                    local normTree = TREE_ALIASES[key]
                    local pts = tonumber(rawPts)
                    if normTree and pts and pts > 0 then
                        DungeonBots.liveTreePoints[cleanSender][normTree] = math.max(
                            DungeonBots.liveTreePoints[cleanSender][normTree] or 0,
                            pts
                        )
                    end
                end

                local tripletTree = string.match(cleanChunk, "([%a ]+)%s*%(%s*%d+[-/]%d+[-/]%d+%s*%)")
                if tripletTree and t1 and t2 and t3 then
                    local normTree = TREE_ALIASES[string.lower(StripSpecNoisePrefix(tripletTree))]
                    local totalPts = (tonumber(t1) or 0) + (tonumber(t2) or 0) + (tonumber(t3) or 0)
                    if normTree and totalPts > 0 then
                        DungeonBots.liveTreePoints[cleanSender][normTree] = math.max(
                            DungeonBots.liveTreePoints[cleanSender][normTree] or 0,
                            totalPts
                        )
                    end
                end
            end
        end
    end

    if not detectedActiveSpec then
        local bestTree, bestTreePts = nil, 0
        for treeKey, pts in pairs(DungeonBots.liveTreePoints[cleanSender]) do
            if pts > bestTreePts then
                bestTreePts = pts
                bestTree = treeKey
            end
        end
        if bestTree and bestTreePts > 0 then
            DungeonBots.lastDetectedTree[cleanSender] = bestTree
            detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, ResolveTreeToSpec(cleanSender, bestTree))
        end
    elseif detectedActiveSpec ~= "" then
        detectedActiveSpec = DungeonBots:CanonicalizeSpec(cleanSender, detectedActiveSpec)
    end

    return foundAnySpec, detectedActiveSpec
end

-- =========================================================================
-- Motor de Consultas en Vivo, Cambio de Talentos y Autogear
-- =========================================================================
local STATS_AUTO_CACHE_TTL = 60.0
local STATS_PENDING_RETRY_COOLDOWN = 10.0
local SPECS_PENDING_RETRY_COOLDOWN = 15.0

local pendingJoinQueries = {}
local queryStates = {}
local lastStatsQueryAt = {}
local lastSpecListQueryAt = {}
DB_Internal.queryStates = queryStates

local joinQueryFrame = CreateFrame("Frame")
joinQueryFrame:Hide()

function DB_Internal.ShowJoinQueryFrame()
    joinQueryFrame:Show()
end

local function RestorePreviousSpecOnTimeout(botName, prevSpec)
    if prevSpec and prevSpec ~= "" and DungeonBotsDB then
        DungeonBotsDB.botActiveSpec = DungeonBotsDB.botActiveSpec or {}
        if not DungeonBotsDB.botActiveSpec[botName] or DungeonBotsDB.botActiveSpec[botName] == "" then
            DungeonBotsDB.botActiveSpec[botName] = prevSpec
        end
    end
end

joinQueryFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = NowTime()
    local hasPending = false

    for botName, remaining in pairs(pendingJoinQueries) do
        local nextTime = remaining - elapsed
        if nextTime <= 0 then
            pendingJoinQueries[botName] = nil
            if DungeonBots:FindPartyUnitByName(botName) and DungeonBots:ShouldTreatAsBot(botName) then
                DungeonBots.sessionQueriedBots[botName] = true
                DungeonBots:QueryBotLiveInfo(botName)
            end
        else
            pendingJoinQueries[botName] = nextTime
            hasPending = true
        end
    end

    for botName, st in pairs(queryStates) do
        if not DungeonBots:FindPartyUnitByName(botName) then
            queryStates[botName] = nil
            DungeonBots.pendingSpecReset[botName] = nil
            DungeonBots.pendingListReset[botName] = nil
        elseif st.gotActiveSpec and st.gotSpecList then
            queryStates[botName] = nil
            DungeonBots.pendingSpecReset[botName] = nil
            DungeonBots.pendingListReset[botName] = nil
        elseif now >= (st.timeoutAt or 0) then
            queryStates[botName] = nil
            DungeonBots.pendingSpecReset[botName] = nil
            DungeonBots.pendingListReset[botName] = nil
            if not st.gotActiveSpec then
                RestorePreviousSpecOnTimeout(botName, st.prevSpec)
            end
            if DungeonBots.UpdatePartyUI then
                DungeonBots:UpdatePartyUI()
            end
        else
            hasPending = true
            if not st.retrySent and now >= (st.retryAt or 0) then
                st.retrySent = true
                st.timeoutAt = now + 4.5
                if not st.gotSpecList then
                    DungeonBots:QueueWhisperCommand(botName, "talents spec list")
                end
                if not st.gotActiveSpec then
                    DungeonBots:QueueWhisperCommand(botName, "talents")
                end
            end
        end
    end

    if not hasPending then
        self:Hide()
    end
end)

local function IsMainFrameCurrentlyVisible()
    local mf = DungeonBots.mainFrame or _G["DungeonBots_MainFrame"]
    return (mf and mf:IsShown()) and true or false
end

local function HasCachedActiveSpec(botName)
    local cached = DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[botName]
    return (cached ~= nil and cached ~= "")
end

local function HasCachedSpecList(botName)
    local specs = (DungeonBots.botSpecs and DungeonBots.botSpecs[botName])
        or (DungeonBotsDB and DungeonBotsDB.botSpecs and DungeonBotsDB.botSpecs[botName])
    return (specs and #specs > 0) and true or false
end

local function StartTalentQuery(botName, atFront, includeSpecList, clearActiveCache)
    if not botName or botName == "" then return end
    local wantSpecList = (includeSpecList ~= false)
    local prevSpec = (DungeonBotsDB and DungeonBotsDB.botActiveSpec and DungeonBotsDB.botActiveSpec[botName])
        or (DungeonBotsDB and DungeonBotsDB.botHistory and DungeonBotsDB.botHistory[botName] and DungeonBotsDB.botHistory[botName].spec)
        or (queryStates[botName] and queryStates[botName].prevSpec)
        or nil

    DungeonBots.pendingSpecReset[botName] = true
    DungeonBots.liveTreePoints[botName] = {}
    if wantSpecList then
        DungeonBots.pendingListReset[botName] = true
        DungeonBots.botSpecTriplets[botName] = {}
    else
        DungeonBots.pendingListReset[botName] = nil
        DungeonBots.botSpecTriplets[botName] = DungeonBots.botSpecTriplets[botName] or {}
    end
    DungeonBots.lastDetectedTriplet[botName] = nil
    DungeonBots.lastDetectedTree[botName] = nil

    if clearActiveCache and DungeonBotsDB and DungeonBotsDB.botActiveSpec then
        DungeonBotsDB.botActiveSpec[botName] = nil
    end

    local now = NowTime()
    queryStates[botName] = {
        prevSpec = prevSpec,
        gotSpecList = (not wantSpecList),
        gotActiveSpec = false,
        retrySent = false,
        retryAt = now + 4.5,
        timeoutAt = now + 9.0,
    }
    joinQueryFrame:Show()

    if wantSpecList then
        if atFront then
            DungeonBots:QueueWhisperCommand(botName, "talents", true)
            DungeonBots:QueueWhisperCommand(botName, "talents spec list", true)
        else
            DungeonBots:QueueWhisperCommand(botName, "talents spec list")
            DungeonBots:QueueWhisperCommand(botName, "talents")
        end
    else
        DungeonBots:QueueWhisperCommand(botName, "talents", atFront == true)
    end

    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
end

function DungeonBots:QueryBotLiveInfo(botName)
    if not botName or botName == "" then return end
    if not DungeonBots:ShouldTreatAsBot(botName) then return end

    -- Al entrar al mundo o unirse un bot: 0 comandos si su rama ya esta guardada (/reload);
    -- si es un bot nuevo sin rama en cache, consulta unicamente 'talents' (ligero).
    if not HasCachedActiveSpec(botName) then
        StartTalentQuery(botName, false, false, false)
    end

    -- 'stats' y 'quests all' solo se consultan al entrar si la ventana principal esta visible.
    if IsMainFrameCurrentlyVisible() then
        DungeonBots:QueryBotStats(botName, false)
        if DungeonBots.QueryBotQuestCount then
            DungeonBots:QueryBotQuestCount(botName, false, 0.90)
        end
    end
end

function DungeonBots:QueryBotStats(botName, force)
    if not botName or botName == "" then return end
    if not DungeonBots:FindPartyUnitByName(botName) then return end
    if not DungeonBots:ShouldTreatAsBot(botName) then return end
    local now = NowTime()
    local st = DungeonBots.botStats and DungeonBots.botStats[botName]
    if not force then
        if st and (now - (st.updatedAt or 0)) < STATS_AUTO_CACHE_TTL then
            return
        end
        local lastReq = lastStatsQueryAt[botName]
        if lastReq and (now - lastReq) < STATS_PENDING_RETRY_COOLDOWN then
            return
        end
    end
    lastStatsQueryAt[botName] = now
    DungeonBots:QueueWhisperCommand(botName, "stats")
end

function DungeonBots:QueryPartyBotStats(forceAll)
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and DungeonBots:ShouldTreatAsBot(name) then
                DungeonBots:QueryBotStats(name, forceAll)
                if forceAll and not HasCachedActiveSpec(name) and not queryStates[name] then
                    StartTalentQuery(name, false, false, false)
                end
            end
        end
    end
    if DungeonBots.QueryPartyBotQuestCounts then
        DungeonBots:QueryPartyBotQuestCounts(forceAll)
    end
end

function DungeonBots:CheckPartyForNewBots()
    DungeonBots:ResolvePendingPartyBots()
    local currentMembers = {}
    local mainVisible = IsMainFrameCurrentlyVisible()
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= "" and name ~= UNKNOWNOBJECT and name ~= "Unknown" then
                currentMembers[name] = true
                if DungeonBots:ShouldTreatAsBot(name) and not DungeonBots.sessionQueriedBots[name] and not pendingJoinQueries[name] then
                    if HasCachedActiveSpec(name) and not mainVisible then
                        DungeonBots.sessionQueriedBots[name] = true
                    else
                        pendingJoinQueries[name] = 1.2
                        joinQueryFrame:Show()
                    end
                end
            end
        end
    end

    -- Si un miembro sale del grupo, limpiar estado de sesion para reconsultar si vuelve a unirse
    for queriedName in pairs(DungeonBots.sessionQueriedBots) do
        if not currentMembers[queriedName] then
            DungeonBots.sessionQueriedBots[queriedName] = nil
            lastStatsQueryAt[queriedName] = nil
            lastSpecListQueryAt[queriedName] = nil
            if DungeonBots.botStats then
                DungeonBots.botStats[queriedName] = nil
            end
            if DungeonBots.botQuestCounts then
                DungeonBots.botQuestCounts[queriedName] = nil
            end
            if DB_Internal.ClearBotQuestCountCooldown then
                DB_Internal.ClearBotQuestCountCooldown(queriedName)
            end
        end
    end
    for pendingName in pairs(pendingJoinQueries) do
        if not currentMembers[pendingName] then
            pendingJoinQueries[pendingName] = nil
        end
    end
end

-- Pedir lista de ramas y talentos activos al bot (under-demand con onlyIfMissing=true o forzado al Actualizar)
function DungeonBots:QueryBotSpecs(botName, onlyIfMissing)
    if not botName or botName == "" then return end
    if onlyIfMissing then
        if HasCachedSpecList(botName) then
            return
        end
        local now = NowTime()
        local lastReq = lastSpecListQueryAt[botName]
        if lastReq and (now - lastReq) < SPECS_PENDING_RETRY_COOLDOWN then
            return
        end
        lastSpecListQueryAt[botName] = now
        StartTalentQuery(botName, false, true, false)
        return
    end
    lastSpecListQueryAt[botName] = NowTime()
    StartTalentQuery(botName, true, true, true)
end

-- Carga bajo demanda para Informacion del Personaje -> Equipo
function DungeonBots:EnsureGearTabData(botName, force)
    if not botName or botName == "" then return end
    if force then
        DungeonBots:QueryBotSpecs(botName, false)
        DungeonBots:QueryBotStats(botName, true)
    else
        DungeonBots:QueryBotStats(botName, false)
        DungeonBots:QueryBotSpecs(botName, true)
    end
end

-- Cambiar rama de talentos de un bot (mantiene comando canónico para el servidor)
function DungeonBots:SetBotSpec(botName, specId)
    if not botName or not specId then return end
    local cleanSpec = DungeonBots:CleanSpecText(specId)
    if cleanSpec == "" then cleanSpec = specId end
    if DungeonBotsDB then
        DungeonBotsDB.botActiveSpec = DungeonBotsDB.botActiveSpec or {}
        DungeonBotsDB.botActiveSpec[botName] = cleanSpec
    end
    DungeonBots:RecordBotHistory(botName, nil, cleanSpec, nil)
    if DungeonBots.UpdateHistoryUI and DungeonBots.historyFrame and DungeonBots.historyFrame:IsShown() then
        DungeonBots:UpdateHistoryUI()
    end
    if DungeonBots.UpdatePartyUI then
        DungeonBots:UpdatePartyUI()
    end
    if DungeonBots.UpdateSpellsDialog and DungeonBots.spellsFrame and DungeonBots.spellsFrame:IsShown() and DungeonBots.spellsFrame.currentBot == botName then
        DungeonBots:UpdateSpellsDialog(botName)
    end
    local displaySpec = DungeonBots.LocalizeSpecText and DungeonBots:LocalizeSpecText(cleanSpec) or cleanSpec
    DungeonBots:Print("Talentos de |cffffd200" .. botName .. "|r fueron cambiados a |cff71d5ff" .. displaySpec .. "|r.")
    DungeonBots:SendWhisperCommand(botName, "talents spec " .. cleanSpec)
end

-- Adaptar equipo (autogear match)
function DungeonBots:AutogearMatch(botName)
    if not botName then return end
    DungeonBots:Print("Adaptando equipo a talentos para |cffffd200" .. botName .. "|r...")
    DungeonBots:SendWhisperCommand(botName, "autogear match")
    DungeonBots:QueueWhisperCommand(botName, "stats")
end

-- Equipar ítems azules (autogear blue)
function DungeonBots:AutogearBlue(botName)
    if not botName then return end
    DungeonBots:Print("Equipando ítems azules a |cffffd200" .. botName .. "|r...")
    DungeonBots:SendWhisperCommand(botName, "autogear blue")
    DungeonBots:QueueWhisperCommand(botName, "stats")
end
