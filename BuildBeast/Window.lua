-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: the main window. Own style (dark panel, gold border). Five tabs:
--   Livello   : what to do at one level (talent point, new spells, rotation, next talents)
--   Talenti   : the whole plan of the 51 talent points
--   Rotazione : the rotation, in steps by level
--   Oggetti   : how items are judged for the spec
--   Macro     : the macros suggested for the spec, with a button to create them
--   Razza     : which race to pick for the class and spec (difficulty, pros and cons), for any class
--   Guida     : how to use and set up the addon, the addons that work with it, the Italian translations
-- Above the tabs: the spec buttons of the class (the spec Hekili detects is selected until you pick another).

local ADDON, GF = ...
local T, Lf = GF.T, GF.L
local function N(text)
    return text
end

local frame
local viewLevel
local currentTab = "livello"
local raceClass     -- class shown in the Razza tab (nil: the player's own)
local prevTab = "livello" -- tab to go back to from the Razza tab
local raceSpec = {} -- class -> spec key chosen in the Razza tab
local CLASS_ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

local GOLD = "|cffffd100"
local GREEN = "|cff33ff33"
local RED = "|cffff4040"
local GREY = "|cff9aa5b8"
local WHITE = "|cffffffff"
local END = "|r"

local TABS = {
    { "livello", N("Livello") },
    { "talenti", N("Talenti") },
    { "rotazione", N("Rotazione") },
    { "oggetti", N("Oggetti") },
    { "macro", N("Macro") },
    { "razza", N("Razza") },
    { "guida", N("Guida") },
    { "opzioni", N("Opzioni") },
}

local function currentBand(spec, level)
    local best
    for _, b in ipairs(spec.bands) do
        if b[1] <= level then
            best = b
        end
    end
    return best
end

local function title(s)
    return GOLD .. s .. END
end

-- The tabs, drawn as cards (see View.lua) --------------------------------------------------------------------------------
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local GREY_RGB = { 0.6, 0.65, 0.72 }
local C_GREEN, C_GREEN_BG = { 0.2, 1, 0.2 }, { 0.09, 0.17, 0.11 }
local C_BLUE, C_BLUE_BG = { 0.29, 0.64, 1 }, { 0.09, 0.12, 0.19 }
local C_GOLD, C_GOLD_BG = { 0.85, 0.68, 0.2 }, { 0.15, 0.13, 0.08 }
local C_RED, C_RED_BG = { 1, 0.3, 0.3 }, { 0.2, 0.09, 0.09 }
local C_DIM, C_DIM_BG = { 0.4, 0.42, 0.48 }, { 0.09, 0.09, 0.11 }
local C_PLAIN, C_PLAIN_BG = { 0.55, 0.65, 0.85 }, { 0.11, 0.12, 0.15 }

local function iconOf(name)
    return (GF.IconFor and GF.IconFor(name)) or QUESTION
end

-- Livello
local function fillLevel(v, spec, level)
    local plan = GF.plan(spec)
    local final = GF.ranksAt(spec, 60)
    v:Begin()

    v:Heading(T("Talento di questo livello"))
    if level < 10 then
        v:Card({ lines = T("I talenti si sbloccano al livello 10."), bar = C_DIM })
    else
        local n = plan[level]
        if n then
            local have = GF.ranksAt(spec, level)[n]
            v:Card({ icon = iconOf(n), size = 44, title = Lf("Prendi %s (punto %d di %d)", GREEN .. n .. END, have, final[n] or have),
                bar = C_GREEN, bg = C_GREEN_BG })
        else
            v:Card({ lines = T("Nessun punto talento a questo livello."), bar = C_DIM })
        end
    end

    v:Heading(T("Abilita' nuove"))
    if spec.spells[level] then
        for raw in T(spec.spells[level]):gmatch("[^,;]+") do
            local piece = raw:gsub("^%s+", ""):gsub("%s+$", "")
            local name = (piece:match(":%s*(.+)$") or piece):gsub("^e%s+", "")
            v:Card({ icon = iconOf(name), size = 28, title = piece, bar = C_BLUE, bg = C_BLUE_BG })
        end
    else
        v:Para(T("Nessuna a questo livello."), GREY_RGB[1], GREY_RGB[2], GREY_RGB[3])
    end
    for lvl = level + 1, 60 do
        if spec.spells[lvl] then
            v:Para(Lf("Prossime (livello %d): %s", lvl, T(spec.spells[lvl])), GREY_RGB[1], GREY_RGB[2], GREY_RGB[3])
            break
        end
    end

    local band = currentBand(spec, level)
    v:Heading(band and Lf("Rotazione (da livello %d)", band[1]) or T("Rotazione"))
    if band then
        local text = T(band[2])
        local strip = GF.IconsInText(spec, text, 22, 8)
        v:Card({ lines = (strip ~= "" and (strip .. "\n") or "") .. text, bar = C_GOLD, bg = C_GOLD_BG })
    else
        v:Para("-")
    end

    v:Heading(T("Prossimi talenti"))
    local shown = 0
    for lvl = level + 1, 60 do
        if plan[lvl] and shown < 6 then
            v:Card({ icon = iconOf(plan[lvl]), size = 28, title = Lf("Livello %d: %s", lvl, plan[lvl]), bar = C_PLAIN, bg = C_PLAIN_BG })
            shown = shown + 1
        end
    end
    if shown == 0 then
        v:Para(T("Nessuno."), GREY_RGB[1], GREY_RGB[2], GREY_RGB[3])
    end
    return v:End()
end

-- Talenti: one card per run of points; done = dim, this level = gold, later = plain
local function fillTalents(v, spec, _, _, _, mine)
    v:Begin()
    v:Heading(T("Piano dei 51 punti talento (livelli 10-60)"))
    v:Para(T("Grigio: gia' fatto. Oro: il punto di questo livello. I segni sul pannello dei talenti seguono questo piano."), GREY_RGB[1], GREY_RGB[2], GREY_RGB[3])
    for _, run in ipairs(spec.talentRuns) do
        local a, b, name = run[1], run[2], run[3]
        local points = b - a + 1
        local range = (a == b) and Lf("Liv %d", a) or Lf("Liv %d-%d", a, b)
        local card = { icon = iconOf(name), size = 28, title = range .. ":  " .. name, tag = points > 1 and ("x" .. points) or nil }
        if b < mine then
            card.bar, card.bg = C_DIM, C_DIM_BG
            card.title = GREY .. card.title .. END
        elseif a <= mine and mine <= b then
            card.bar, card.bg = C_GOLD, C_GOLD_BG
            card.title = GOLD .. "> " .. card.title .. END
        else
            card.bar, card.bg = C_PLAIN, C_PLAIN_BG
        end
        v:Card(card)
    end
    return v:End()
end

-- Rotazione: one card per band of levels
local function fillRotation(v, spec, level)
    v:Begin()
    v:Heading(T("Rotazione, a passi di livello"))
    v:Para(T("Hekili sceglie da solo le abilita' che hai gia' imparato: queste note spiegano il perche'."), GREY_RGB[1], GREY_RGB[2], GREY_RGB[3])
    local current = currentBand(spec, level)
    for _, b in ipairs(spec.bands) do
        local text = T(b[2])
        local strip = GF.IconsInText(spec, text, 22, 8)
        local body = (strip ~= "" and (strip .. "\n") or "")
        if current and b[1] == current[1] then
            v:Card({ title = GOLD .. "> " .. Lf("Da livello %d (ora)", b[1]) .. END, lines = body .. text, bar = C_GOLD, bg = C_GOLD_BG })
        elseif b[1] < level then
            v:Card({ title = GREY .. Lf("Da livello %d", b[1]) .. END, lines = body .. GREY .. text .. END, bar = C_DIM, bg = C_DIM_BG })
        else
            v:Card({ title = Lf("Da livello %d", b[1]), lines = body .. text, bar = C_PLAIN, bg = C_PLAIN_BG })
        end
    end
    return v:End()
end

-- Oggetti
local STAT_LABEL = {
    ITEM_MOD_AGILITY_SHORT = N("Agilita'"),
    ITEM_MOD_INTELLECT_SHORT = N("Intelletto"),
    ITEM_MOD_STAMINA_SHORT = N("Stamina"),
    ITEM_MOD_SPIRIT_SHORT = N("Spirito"),
    ITEM_MOD_STRENGTH_SHORT = N("Forza"),
    ITEM_MOD_ATTACK_POWER_SHORT = N("Potenza d'attacco"),
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = N("Potenza d'attacco a distanza"),
    ITEM_MOD_SPELL_POWER_SHORT = N("Potere magico"),
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = N("Danno magico"),
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = N("Potere di cura"),
    ITEM_MOD_MANA_REGENERATION_SHORT = N("Rigenerazione del mana"),
}

local function fillItems(v, spec, _, class)
    v:Begin()
    local w = spec.itemWeights
    v:Heading(T("Come valuto gli oggetti"))
    if not w then
        v:Para(T("Per questa spec non ci sono ancora le regole sugli oggetti."))
        return v:End()
    end
    v:Para(T("Ogni statistica vale un numero di 'punti Agilita'': piu' e' alto, piu' conta."), GREY_RGB[1], GREY_RGB[2], GREY_RGB[3])

    v:Heading(T("Cosa conta, in ordine"))
    local list = {}
    if (w.rangedDps or 0) > 0 then
        -- the ranged weapon is a wand for the casters, a bow, crossbow or gun for the hunter, something else for the rest
        local label = T("DPS dell'arma a distanza")
        if class == "HUNTER" then
            label = T("DPS dell'arma a distanza (arco, balestra, fucile)")
        elseif class == "MAGE" or class == "PRIEST" or class == "WARLOCK" then
            label = T("DPS dell'arma a distanza (bacchetta)")
        end
        list[#list + 1] = { label, w.rangedDps }
    end
    if (w.meleeDps or 0) > 0 then
        list[#list + 1] = { T("DPS dell'arma da mischia"), w.meleeDps }
    end
    local seen = {}
    for key, weight in pairs(w.stats) do
        local label = STAT_LABEL[key] and T(STAT_LABEL[key]) or key
        if weight > 0 and not seen[label .. weight] then
            seen[label .. weight] = true
            list[#list + 1] = { label, weight }
        end
    end
    table.sort(list, function(a, b)
        if a[2] ~= b[2] then
            return a[2] > b[2]
        end
        return a[1] < b[1]
    end)
    local rows = {}
    for i, e in ipairs(list) do
        rows[#rows + 1] = i .. ".  " .. e[1] .. GREY .. "  " .. Lf("(vale %s)", string.format("%g", e[2])) .. END
    end
    v:Card({ lines = table.concat(rows, "\n"), bar = C_GREEN, bg = C_GREEN_BG })
    local no = {}
    if (w.meleeDps or 0) == 0 then
        no[#no + 1] = RED .. "-" .. END .. "  " .. T("DPS dell'arma da mischia") .. GREY .. "  " .. T("(non conta: conta solo cio' che da' in statistiche)") .. END
    end
    if (w.rangedDps or 0) == 0 then
        no[#no + 1] = RED .. "-" .. END .. "  " .. T("DPS dell'arma a distanza") .. GREY .. "  " .. T("(non conta per questa spec)") .. END
    end
    if #no > 0 then
        v:Card({ lines = table.concat(no, "\n"), bar = C_RED, bg = C_RED_BG })
    end

    v:Heading(T("Il parere nel tooltip"))
    local limit = tonumber(BuildBeastDB and BuildBeastDB.threshold) or 1
    v:Card({ title = GREEN .. GF.VerdictWord("SI") .. END, lines = Lf("ti da' almeno %s punti in piu' di quello che indossi.", limit), bar = C_GREEN, bg = C_GREEN_BG })
    v:Card({ title = RED .. GF.VerdictWord("NO") .. END, lines = Lf("ne perdi almeno %s.", limit), bar = C_RED, bg = C_RED_BG })
    v:Card({ title = "|cffffd933" .. GF.VerdictWord("SIMILE") .. "|r", lines = T("la differenza e' piccola."), bar = { 1, 0.85, 0.2 }, bg = C_GOLD_BG })
    v:Para(GREEN .. T("Verde") .. END .. " = " .. T("cosa guadagni,") .. " " .. RED .. T("rosso") .. END .. " = " .. T("cosa perdi."))

    v:Heading(T("Incantamenti"))
    v:Para(T("Li propone GearQuest (la riga gialla \"Recommended enchantment\" nel tooltip dell'oggetto)."))
    if w.why then
        v:Heading(T("Perche'"))
        v:Card({ lines = T(w.why), bar = C_PLAIN, bg = C_PLAIN_BG })
    end
    return v:End()
end

-- Macro
local function fillMacros(v, _, _, class, specKey)
    v:Begin()
    local list = GF.macrosFor(class, specKey)
    if #list == 0 then
        v:Heading(T("Macro"))
        v:Para(T("Per questa spec non ci sono macro suggerite."))
        return v:End()
    end
    v:Heading(T("Macro suggerite per questa spec"))
    v:Para(T("Il bottone qui sopra le crea nel gioco (con conferma). Poi le trovi in /macro e le trascini sulle barre. I nomi dei colpi sono quelli inglesi."), GREY_RGB[1], GREY_RGB[2], GREY_RGB[3])
    for _, m in ipairs(list) do
        -- the picture the macro gets when it is created, shown here before the macro
        v:Card({ icon = m.icon and ("Interface\\Icons\\" .. m.icon) or QUESTION, size = 36, title = m.name,
            lines = T(m.why) .. "\n" .. GREY .. m.body .. END, bar = C_GOLD, bg = C_GOLD_BG })
    end
    return v:End()
end

-- Guida and the addons that work with BuildBeast
local function addonInfo(name)
    local loaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        loaded = C_AddOns.IsAddOnLoaded(name) and true or false
    elseif IsAddOnLoaded then
        loaded = IsAddOnLoaded(name) and true or false
    end
    local version
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        version = C_AddOns.GetAddOnMetadata(name, "Version")
    elseif GetAddOnMetadata then
        version = GetAddOnMetadata(name, "Version")
    end
    return loaded, version
end

local function fillGuide(v)
    v:Begin()
    for _, sec in ipairs(GF.GuideSections()) do
        v:Heading(sec.head)
        if sec.grey then
            v:Para(sec.grey, GREY_RGB[1], GREY_RGB[2], GREY_RGB[3])
        end
        if sec.para then
            v:Para(sec.para)
        end
        for _, text in ipairs(sec.cards or {}) do
            v:Card({ lines = text, bar = C_GOLD, bg = C_GOLD_BG })
        end
    end

    v:Heading(T("Addon che lavorano con BuildBeast"))
    local function entry(name, label, what)
        local loaded, version = addonInfo(name)
        v:Card({
            title = T(label) .. (version and (GREY .. "  " .. Lf("(versione %s)", version) .. END) or ""),
            tag = loaded and T("attivo") or T("non trovato"),
            tagColor = loaded and C_GREEN or C_RED,
            lines = T(what),
            bar = loaded and C_GREEN or C_RED,
            bg = loaded and C_GREEN_BG or C_RED_BG,
        })
    end
    entry("Hekili", N("Hekili (consigliato)"), N("Calcola la rotazione. BuildBeast gli da' la sua priorita' e illumina i tasti. Senza Hekili non ci sono suggerimenti di abilita'."))
    entry("GearQuestForever", N("GearQuest Forever (consigliato)"), N("Suggerisce oggetti e incantamenti per livello. BuildBeast aggiunge il suo parere, e spiega il perche'."))
    entry("ZygorGuidesViewerForever", N("Zygor (facoltativo)"), N("Guida di zona e missioni. Se i suoi segni sui talenti ti disturbano, spegnili nelle Opzioni."))

    v:Heading(T("Traduzioni italiane"))
    local tr = GF.TranslationStatus and GF.TranslationStatus() or {}
    v:Card({ lines = "Hekili: " .. tostring(tr.hekili or "?") .. "\nGearQuest: " .. tostring(tr.gq or "?") .. "\n"
        .. GREY .. T("Le porta BuildBeast, cosi' un aggiornamento di Hekili o di GearQuest non le cancella. Si accendono e si spengono nelle Opzioni (poi /reload).") .. END,
        bar = C_BLUE, bg = C_BLUE_BG })
    return v:End()
end

-- the tabs drawn as cards: the ones that need the guide of the spec, and the ones that do not
local SPEC_CARD_TABS = { livello = fillLevel, talenti = fillTalents, rotazione = fillRotation, oggetti = fillItems }
local FREE_CARD_TABS = { macro = fillMacros, guida = fillGuide }

local function cardView()
    if not frame.cardView then
        frame.cardView = GF.View.New(frame.content)
    end
    return frame.cardView
end

-- Tab: Razza -------------------------------------------------------------------------------------------------------------
local TIER_RGB = { { 0.2, 1, 0.2 }, { 0.29, 0.64, 1 }, { 0.8, 0.8, 0.8 } }
local TIER_BG = { { 0.09, 0.17, 0.11 }, { 0.09, 0.12, 0.19 }, { 0.13, 0.13, 0.15 } }
local DIFFICULTY = { f = { "easy", 0.25, 0.83, 0.35 }, m = { "medium", 0.88, 0.69, 0.19 }, d = { "hard", 1, 0.42, 0.42 } }
local RACE_W = GF.View.W -- refreshed at every fill (the window can be resized)
local RACE_TOKEN = { Human = "hu", Dwarf = "dw", NightElf = "ne", Gnome = "gn", Orc = "or", Scourge = "un", Tauren = "ta", Troll = "tr" }

local function newFS(parent, template)
    return GF.View.NewFS(parent, template)
end

local function newBox(parent, r, g, b)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    box:SetBackdropColor(r or 0.1, g or 0.1, b or 0.13, 1)
    return box
end

-- the frame that holds the Razza tab (cards instead of plain text), made once inside the scroll area
local function raceView()
    if frame.raceView then
        return frame.raceView
    end
    local v = CreateFrame("Frame", nil, frame.content)
    v:SetPoint("TOPLEFT", 0, 0)
    v:SetSize(RACE_W, 10)
    v.cards, v.heads = {}, {}
    v:Hide()
    frame.raceView = v
    return v
end

local function lines(prefix, list)
    local out = {}
    for _, x in ipairs(list) do
        out[#out + 1] = prefix .. T(x)
    end
    return table.concat(out, "\n")
end

-- fills the Razza tab for a class and spec; returns the height used
local function fillRaceView(class, specKey)
    RACE_W = GF.View.W
    local v = raceView()
    v:SetWidth(RACE_W)
    local lab = GF.RACE_LABELS
    local data = GF.RACE_SPECS and GF.RACE_SPECS[class] and GF.RACE_SPECS[class][specKey]
    if v.head then
        v.head:Hide()
    end
    for _, c in ipairs(v.cards) do
        c:Hide()
    end
    for _, h in ipairs(v.heads) do
        h:Hide()
    end
    if not (lab and data) then
        v:SetHeight(10)
        return 10
    end

    -- panel with difficulty, what it does, pros and cons
    local h = v.head
    if not h then
        h = newBox(v, 0.11, 0.11, 0.15)
        h:SetWidth(RACE_W)
        h.icon = h:CreateTexture(nil, "ARTWORK")
        h.icon:SetSize(40, 40)
        h.icon:SetPoint("TOPLEFT", 10, -10)
        h.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        h.title = newFS(h, "GameFontNormalLarge")
        h.title:SetPoint("TOPLEFT", 60, -10)
        h.diffLabel = newFS(h)
        h.diffLabel:SetPoint("TOPLEFT", 60, -34)
        h.badge = newBox(h)
        h.badge:SetHeight(18)
        h.badge:SetPoint("LEFT", h.diffLabel, "RIGHT", 8, 0)
        h.badgeText = newFS(h.badge, "GameFontNormalSmall")
        h.badgeText:SetPoint("CENTER", 0, 0)
        h.summary = newFS(h)
        h.summary:SetPoint("TOPLEFT", 10, -58)
        h.summary:SetWidth(RACE_W - 20)
        h.proT, h.pro = newFS(h, "GameFontNormal"), newFS(h)
        h.conT, h.con = newFS(h, "GameFontNormal"), newFS(h)
        h.pro:SetWidth(228)
        h.con:SetWidth(228)
        v.head = h
    end
    local diff = DIFFICULTY[data.difficulty]
    local colW = math.floor((RACE_W - 44) / 2)
    h:SetWidth(RACE_W)
    h.summary:SetWidth(RACE_W - 20)
    h.pro:SetWidth(colW)
    h.con:SetWidth(colW)
    h.icon:SetTexture(data.icon)
    h.title:SetText(T(lab.title))
    h.diffLabel:SetText(T(lab.difficulty) .. ":")
    h.badgeText:SetText(T(lab[diff[1]]))
    h.badgeText:SetTextColor(0.06, 0.06, 0.06)
    h.badge:SetBackdropColor(diff[2], diff[3], diff[4], 1)
    h.badge:SetWidth(h.badgeText:GetStringWidth() + 16)
    h.summary:SetText(T(data.summary))
    local y = 58 + h.summary:GetStringHeight() + 12
    h.proT:SetText(T(lab.pros))
    h.proT:SetTextColor(0.25, 0.83, 0.35)
    h.proT:ClearAllPoints()
    h.proT:SetPoint("TOPLEFT", 10, -y)
    h.pro:SetText(lines("+ ", data.pros))
    h.pro:ClearAllPoints()
    h.pro:SetPoint("TOPLEFT", 10, -(y + 18))
    h.conT:SetText(T(lab.cons))
    h.conT:SetTextColor(1, 0.42, 0.42)
    h.conT:ClearAllPoints()
    h.conT:SetPoint("TOPLEFT", 20 + colW, -y)
    h.con:SetText(lines("- ", data.cons))
    h.con:ClearAllPoints()
    h.con:SetPoint("TOPLEFT", 20 + colW, -(y + 18))
    local colH = math.max(h.pro:GetStringHeight(), h.con:GetStringHeight())
    h:SetHeight(y + 18 + colH + 12)
    h:ClearAllPoints()
    h:SetPoint("TOPLEFT", v, "TOPLEFT", 0, 0)
    h:Show()
    local top = h:GetHeight() + 10

    -- races of each faction, best first
    local nh, nc = 0, 0
    local ownFaction = BuildBeastDB and BuildBeastDB.raceOwnFaction and UnitFactionGroup and UnitFactionGroup("player")
    local _, raceToken = UnitRace("player")
    local ownRace = RACE_TOKEN[raceToken or ""]
    local mineClass = (class == GF.playerClass())
    local facs = { "H", "A" }
    if ownFaction then
        facs = { ownFaction == "Horde" and "H" or "A" }
    end
    for _, fac in ipairs(facs) do
        local rows = {}
        for i, r in ipairs(data.races) do
            if GF.RACES[r[1]].faction == fac then
                rows[#rows + 1] = { r = r, i = i }
            end
        end
        table.sort(rows, function(a, b)
            if a.r[2] ~= b.r[2] then
                return a.r[2] < b.r[2]
            end
            return a.i < b.i
        end)
        if #rows > 0 then
            nh = nh + 1
            local fs = v.heads[nh]
            if not fs then
                fs = newFS(v, "GameFontNormalLarge")
                v.heads[nh] = fs
            end
            fs:SetText(T(fac == "H" and lab.horde or lab.alliance))
            fs:SetTextColor(fac == "H" and 1 or 0.35, fac == "H" and 0.35 or 0.6, fac == "H" and 0.3 or 1)
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", v, "TOPLEFT", 2, -top)
            fs:Show()
            top = top + 26
            for _, row in ipairs(rows) do
                nc = nc + 1
                local c = v.cards[nc]
                if not c then
                    c = newBox(v)
                    c:SetWidth(RACE_W)
                    c.bar = c:CreateTexture(nil, "ARTWORK")
                    c.bar:SetPoint("TOPLEFT", 0, 0)
                    c.bar:SetPoint("BOTTOMLEFT", 0, 0)
                    c.bar:SetWidth(4)
                    c.ib = c:CreateTexture(nil, "BACKGROUND")
                    c.ib:SetSize(44, 44)
                    c.ib:SetPoint("TOPLEFT", 12, -8)
                    c.ib:SetColorTexture(0.42, 0.35, 0.16, 1)
                    c.icon = c:CreateTexture(nil, "ARTWORK")
                    c.icon:SetSize(40, 40)
                    c.icon:SetPoint("TOPLEFT", 14, -10)
                    c.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                    c.name = newFS(c, "GameFontNormalLarge")
                    c.name:SetPoint("TOPLEFT", 68, -10)
                    c.name:SetTextColor(1, 1, 1)
                    c.tag = newFS(c, "GameFontNormalSmall")
                    c.tag:SetPoint("LEFT", c.name, "RIGHT", 10, 0)
                    c.mine = newFS(c, "GameFontNormalSmall")
                    c.mine:SetPoint("TOPRIGHT", -12, -14)
                    c.mine:SetTextColor(1, 0.82, 0)
                    c.traits = newFS(c)
                    c.traits:SetPoint("TOPLEFT", 68, -34)
                    c.traits:SetWidth(RACE_W - 84)
                    v.cards[nc] = c
                end
                c:SetWidth(RACE_W)
                c.traits:SetWidth(RACE_W - 84)
                local race = GF.RACES[row.r[1]]
                local tier = row.r[2]
                local rgb, bg = TIER_RGB[tier], TIER_BG[tier]
                c:SetBackdropColor(bg[1], bg[2], bg[3], 1)
                c.bar:SetColorTexture(rgb[1], rgb[2], rgb[3], 1)
                c.icon:SetTexture(race.icon)
                c.name:SetText(T(race.name))
                c.tag:SetText(T(lab["tier" .. tier]))
                c.tag:SetTextColor(rgb[1], rgb[2], rgb[3])
                c.mine:SetText((mineClass and ownRace == row.r[1]) and ("* " .. T("LA TUA RAZZA")) or "")
                local tl = {}
                for _, n in ipairs(row.r[3]) do
                    tl[#tl + 1] = race.traits[n]
                end
                c.traits:SetText(lines("+ ", tl))
                c:SetHeight(math.max(62, 34 + c.traits:GetStringHeight() + 12))
                c:ClearAllPoints()
                c:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -top)
                c:Show()
                top = top + c:GetHeight() + 6
            end
            top = top + 6
        end
    end
    v:SetHeight(top)
    return top
end

-- Window ----------------------------------------------------------------------------------------------------------------
function GF.RefreshWindow()
    if not (frame and frame:IsShown()) then
        return
    end
    local spec, specKey, class = GF.specData()
    local mine = UnitLevel("player") or 1
    local raceMode = (currentTab == "razza")
    if raceMode then
        local own = class
        class = raceClass or own
        if class ~= own or raceSpec[class] then
            specKey = raceSpec[class] or GF.SPECS[class][1][1]
        end
    end
    viewLevel = math.max(1, math.min(60, viewLevel or mine))

    -- spec buttons
    for _, b in ipairs(frame.specButtons) do
        b:Hide()
    end
    local list = GF.SPECS[class] or {}
    local n = #list
    local w = n > 0 and math.floor((frame:GetWidth() - 34 - (n - 1) * 6) / n) or 100
    for i, s in ipairs(list) do
        local b = frame.specButtons[i]
        if not b then
            b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            b:SetHeight(26)
            frame.specButtons[i] = b
        end
        b:SetWidth(w)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 16 + (i - 1) * (w + 6), -60)
        local has = GF.DATA and GF.DATA[class] and GF.DATA[class][s[1]]
        b:SetText(s[2] .. ((has or raceMode) and "" or (" " .. T("(in arrivo)"))))
        if s[1] == specKey then
            b:LockHighlight()
        else
            b:UnlockHighlight()
        end
        GF.FitButton(b)
        b:SetScript("OnClick", function()
            if raceMode then
                raceSpec[class] = s[1]
                GF.RefreshWindow()
            else
                GF.ChooseSpec(s[1])
            end
        end)
        b:Show()
    end

    if GF.RefreshQuick then
        GF.RefreshQuick()
    end
    local classLabel = GF.CLASS_LABEL[class] and T(GF.CLASS_LABEL[class]) or tostring(class)
    local suffix = (viewLevel == mine) and ("  " .. T("(il tuo livello)")) or ""
    if raceMode then
        frame.sub:SetText(classLabel .. " - " .. GF.specLabel(class, specKey))
    else
        frame.sub:SetText(classLabel .. " - " .. GF.specLabel(class, specKey) .. " - " .. Lf("livello %d", viewLevel) .. suffix)
    end

    frame.content:SetWidth(GF.View.W)
    frame.text:SetWidth(GF.View.W)
    cardView():SetWidth(GF.View.W)
    -- what to draw: the Razza view, a tab made of cards, or (no guide for this spec) a short message
    local cardFn = (not raceMode) and (FREE_CARD_TABS[currentTab] or (spec and SPEC_CARD_TABS[currentTab]))
    local text = ""
    if not raceMode and not cardFn then
        text = title(T("Guida non ancora disponibile")) .. "\n"
            .. Lf("Per %s la guida non c'e' ancora: il video da cui prendiamo i dati non ha una build per questa spec.", classLabel .. " " .. GF.specLabel(class, specKey))
    end
    frame.text:SetText(text)
    local rv = raceView()
    local cv = cardView()
    rv:SetShown(raceMode)
    cv:SetShown(cardFn and true or false)
    frame.text:SetShown(not raceMode and not cardFn)
    if raceMode then
        frame.content:SetHeight(math.max(10, fillRaceView(class, specKey) + 8))
    elseif cardFn then
        frame.content:SetHeight(math.max(10, cardFn(cv, spec, viewLevel, class, specKey, mine) + 8))
    else
        frame.content:SetHeight(math.max(10, frame.text:GetStringHeight() + 8))
    end
    frame.scroll:SetVerticalScroll(0)

    -- tabs and level buttons
    local tabW = math.floor((frame:GetWidth() - 34 - (#TABS - 1) * 4) / #TABS)
    for i, t in ipairs(frame.tabButtons) do
        t.btn:SetWidth(tabW)
        t.btn:ClearAllPoints()
        t.btn:SetPoint("TOPLEFT", 16 + (i - 1) * (tabW + 4), -92)
        t.btn:SetText(T(t.label))
        if t.key == currentTab then
            t.btn:LockHighlight()
        else
            t.btn:UnlockHighlight()
        end
        GF.FitButton(t.btn)
        t.btn:SetShown(not raceMode)
    end
    frame.raceBack:SetText("< " .. T("Torna indietro"))
    GF.FitButton(frame.raceBack)
    frame.raceBack:SetShown(raceMode)
    local isOptions = (currentTab == "opzioni")
    frame.scroll:SetShown(not isOptions)
    frame.optScroll:SetShown(isOptions)
    if isOptions then
        GF.RefreshOptions()
        frame.sub:SetText(T("Opzioni"))
    end
    if GF.ApplyFonts then
        GF.ApplyFonts(frame)
    end
    frame.macroBtn:SetShown(currentTab == "macro" and #GF.macrosFor(class, specKey) > 0)
    for _, b in ipairs(frame.raceNav) do
        b:SetShown(raceMode)
    end
    frame.raceLabel:SetText(T("Classe") .. ": " .. classLabel)
    frame.raceMine:SetText(T("La mia classe"))
    GF.FitButton(frame.raceMine)
    frame.raceFac:SetText((BuildBeastDB.raceOwnFaction and T("Tutte le fazioni")) or T("Solo la mia fazione"))
    GF.FitButton(frame.raceFac)
    frame.raceLabel:SetShown(raceMode)
    local showNav = (currentTab == "livello" or currentTab == "rotazione")
    for _, b in ipairs(frame.navButtons) do
        if showNav then
            b:Show()
        else
            b:Hide()
        end
    end
end

local function build()
    local f = CreateFrame("Frame", "BuildBeastFrame", UIParent, "BackdropTemplate")
    local w0 = math.max(540, math.min(1400, tonumber(BuildBeastDB and BuildBeastDB.winW) or 640))
    local h0 = math.max(480, math.min(1400, tonumber(BuildBeastDB and BuildBeastDB.winH) or 720))
    f:SetSize(w0, h0)
    GF.View.W = w0 - 64
    f:SetResizable(true)
    if f.SetResizeBounds then
        f:SetResizeBounds(540, 480, 1400, 1400)
    elseif f.SetMinResize then
        f:SetMinResize(540, 480)
    end
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.06, 0.07, 0.09, 0.96)
    f:SetBackdropBorderColor(0.85, 0.68, 0.2, 1)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    if UISpecialFrames and not GF.specialAdded then
        GF.specialAdded = true
        table.insert(UISpecialFrames, "BuildBeastFrame")
    end

    local ttl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ttl:SetPoint("TOPLEFT", 16, -14)
    ttl:SetText("BuildBeast")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.sub:SetPoint("TOPLEFT", 16, -40)

    f.specButtons = {}

    -- tabs
    f.tabButtons = {}
    local tw = math.floor((606 - (#TABS - 1) * 4) / #TABS)
    for i, t in ipairs(TABS) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(tw, 28)
        b:SetPoint("TOPLEFT", 16 + (i - 1) * (tw + 4), -92)
        b:SetScript("OnClick", function()
            if t[1] == "razza" and currentTab ~= "razza" then
                prevTab = currentTab
            end
            currentTab = t[1]
            GF.RefreshWindow()
        end)
        f.tabButtons[#f.tabButtons + 1] = { key = t[1], label = t[2], btn = b }
    end

    -- level navigation (Livello and Rotazione)
    f.navButtons = {}
    local function nav(label, width, x, fn)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(width, 26)
        b:SetPoint("TOPLEFT", x, -128)
        b:SetText(label)
        b:SetScript("OnClick", fn)
        f.navButtons[#f.navButtons + 1] = b
    end
    nav("<", 40, 16, function()
        viewLevel = (viewLevel or UnitLevel("player") or 1) - 1
        GF.RefreshWindow()
    end)
    nav(">", 40, 60, function()
        viewLevel = (viewLevel or UnitLevel("player") or 1) + 1
        GF.RefreshWindow()
    end)
    nav(T("Il mio livello"), 150, 104, function()
        viewLevel = UnitLevel("player") or 1
        GF.RefreshWindow()
    end)

    -- class buttons of the Razza tab: look at the races of any class, also the ones you do not play
    f.raceNav = {}
    local function raceStep(delta)
        local _, _, own = GF.specData()
        local cur = raceClass or own
        local idx = 1
        for i, c in ipairs(CLASS_ORDER) do
            if c == cur then
                idx = i
            end
        end
        raceClass = CLASS_ORDER[((idx - 1 + delta) % #CLASS_ORDER) + 1]
        GF.RefreshWindow()
    end
    for i, def in ipairs({ { "<", -1, 16 }, { ">", 1, 254 } }) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(40, 26)
        b:SetPoint("TOPLEFT", def[3], -128)
        b:SetText(def[1])
        b:SetScript("OnClick", function()
            raceStep(def[2])
        end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(def[2] < 0 and T("Classe precedente") or T("Classe successiva"))
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        b:Hide()
        f.raceNav[#f.raceNav + 1] = b
    end
    local mine = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    mine:SetSize(140, 26)
    mine:SetPoint("TOPLEFT", 300, -128)
    mine:SetScript("OnClick", function()
        raceClass = nil
        GF.RefreshWindow()
    end)
    mine:Hide()
    f.raceMine = mine
    f.raceNav[#f.raceNav + 1] = mine
    local facBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    facBtn:SetSize(162, 26)
    facBtn:SetPoint("TOPLEFT", 444, -128)
    facBtn:SetScript("OnClick", function()
        BuildBeastDB.raceOwnFaction = not BuildBeastDB.raceOwnFaction
        GF.RefreshWindow()
    end)
    facBtn:Hide()
    f.raceFac = facBtn
    f.raceNav[#f.raceNav + 1] = facBtn

    -- back button of the Razza tab (the tabs are hidden there, so only the class arrows and the specs stay)
    local back = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    back:SetSize(200, 28)
    back:SetPoint("TOPLEFT", 16, -92)
    back:SetScript("OnClick", function()
        currentTab = prevTab or "livello"
        GF.RefreshWindow()
    end)
    back:Hide()
    f.raceBack = back

    -- what the arrows change: "Class: Hunter", between the two arrows
    local rl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rl:SetPoint("TOPLEFT", 60, -134)
    rl:SetSize(190, 14)
    rl:SetJustifyH("CENTER")
    rl:Hide()
    f.raceLabel = rl

    local mb = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    mb:SetSize(260, 26)
    mb:SetPoint("TOPLEFT", 16, -128)
    mb:SetText(T("Crea le macro di questa spec"))
    mb:SetScript("OnClick", function()
        GF.CreateMacros()
    end)
    mb:Hide()
    f.macroBtn = mb

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -166)
    scroll:SetPoint("BOTTOMRIGHT", -34, 44)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(GF.View.W, 10)
    scroll:SetScrollChild(content)
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetWidth(GF.View.W)
    GF.View.Track(text, "GameFontHighlight")
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    f.text, f.scroll, f.content = text, scroll, content

    -- the Opzioni tab: its own scroll area with the check boxes of Options.lua
    local optScroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    optScroll:SetPoint("TOPLEFT", 16, -130)
    optScroll:SetPoint("BOTTOMRIGHT", -34, 44)
    local optContent = CreateFrame("Frame", nil, optScroll)
    optContent:SetSize(GF.View.W, 10)
    optScroll:SetScrollChild(optContent)
    f.optScroll = optScroll
    optScroll:Hide()
    GF.BuildOptionsInto(optContent)

    -- size of the text: + and - at the bottom (only the letters change, not the window)
    local sizeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeLabel:SetPoint("BOTTOMLEFT", 16, 18)
    sizeLabel:SetText(T("Dimensione"))
    local minus = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    minus:SetSize(28, 22)
    minus:SetPoint("LEFT", sizeLabel, "RIGHT", 10, 0)
    minus:SetText("-")
    minus:SetScript("OnClick", function()
        GF.ChangeScale(-0.1)
    end)
    local pct = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    pct:SetPoint("LEFT", minus, "RIGHT", 8, 0)
    pct:SetWidth(46)
    local plus = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    plus:SetSize(28, 22)
    plus:SetPoint("LEFT", pct, "RIGHT", 4, 0)
    plus:SetText("+")
    plus:SetScript("OnClick", function()
        GF.ChangeScale(0.1)
    end)
    function GF.RefreshScaleLabel()
        pct:SetText(string.format("%d%%", math.floor(GF.GetScale() * 100 + 0.5)))
    end
    GF.RefreshScaleLabel()
    f:SetScale(1)
    GF.ApplyDarkBackground(f)
    if GF.ApplyFonts then
        C_Timer.After(0, function()
            GF.ApplyFonts(f)
        end)
    end
    f:SetClampedToScreen(true)

    -- drag the right edge, the bottom edge or the corner to resize the window; the size is remembered
    local function grip(point, w, h, a1, a2)
        local g = CreateFrame("Frame", nil, f)
        g:SetFrameLevel(f:GetFrameLevel() + 20)
        g:EnableMouse(true)
        if w then
            g:SetWidth(w)
        end
        if h then
            g:SetHeight(h)
        end
        g:SetPoint(a1[1], f, a1[2], a1[3], a1[4])
        if a2 then
            g:SetPoint(a2[1], f, a2[2], a2[3], a2[4])
        end
        g:SetScript("OnMouseDown", function()
            f:StartSizing(point)
        end)
        g:SetScript("OnMouseUp", function()
            f:StopMovingOrSizing()
            BuildBeastDB.winW, BuildBeastDB.winH = math.floor(f:GetWidth() + 0.5), math.floor(f:GetHeight() + 0.5)
        end)
        return g
    end
    grip("RIGHT", 8, nil, { "TOPRIGHT", "TOPRIGHT", 0, -40 }, { "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 20 })
    grip("BOTTOM", nil, 8, { "BOTTOMLEFT", "BOTTOMLEFT", 20, 0 }, { "BOTTOMRIGHT", "BOTTOMRIGHT", -20, 0 })
    local corner = grip("BOTTOMRIGHT", 20, 20, { "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0 })
    corner:SetFrameLevel(f:GetFrameLevel() + 25)
    corner.tex = corner:CreateTexture(nil, "OVERLAY")
    corner.tex:SetAllPoints()
    corner.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    f:SetScript("OnSizeChanged", function(self, w)
        GF.View.W = math.max(300, math.floor(w - 64))
        if not self.resizeQueued then
            self.resizeQueued = true
            C_Timer.After(0.05, function()
                self.resizeQueued = false
                GF.RefreshWindow()
            end)
        end
    end)

    f:SetScript("OnShow", function()
        if GF.ScanTalentIcons then
            GF.ScanTalentIcons()
        end
        viewLevel = UnitLevel("player") or 1
        GF.RefreshWindow()
    end)
    return f
end

-- opens the window on a tab (toggle: true closes it when that tab is already showing)
function GF.ShowTab(key, toggle)
    if not frame then
        frame = build()
    end
    if toggle and frame:IsShown() and currentTab == key then
        frame:Hide()
        return
    end
    currentTab = key
    if frame:IsShown() then
        GF.RefreshWindow()
    else
        frame:Show()
    end
end

-- throws the window away and builds it again (after a change of language), on the same tab
function GF.RebuildWindow(tab)
    local wasShown = frame and frame:IsShown()
    if frame then
        frame:Hide()
        frame:SetParent(nil)
    end
    frame = nil
    if GF.ResetOptionRows then
        GF.ResetOptionRows()
    end
    GF.ShowTab(tab or currentTab)
    if not wasShown and frame then
        frame:Hide()
    end
end

function GF.ToggleWindow()
    if not frame then
        frame = build()
    end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
