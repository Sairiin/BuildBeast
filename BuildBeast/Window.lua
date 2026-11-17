-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: the main window. Own style (dark panel, gold border). Five tabs:
--   Livello   : what to do at one level (talent point, new spells, rotation, next talents)
--   Talenti   : the whole plan of the 51 talent points
--   Rotazione : the rotation, in steps by level
--   Oggetti   : how items are judged for the spec
--   Macro     : the macros suggested for the spec, with a button to create them
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

-- Tab: Livello ----------------------------------------------------------------------------------------------------------
local function tabLevel(spec, level)
    local L = {}
    local plan = GF.plan(spec)
    local final = GF.ranksAt(spec, 60)

    L[#L + 1] = title(T("Talento di questo livello"))
    if level < 10 then
        L[#L + 1] = T("I talenti si sbloccano al livello 10.")
    else
        local n = plan[level]
        if n then
            local have = GF.ranksAt(spec, level)[n]
            L[#L + 1] = Lf("Prendi %s (punto %d di %d)", GF.IconTag(n, 20) .. GREEN .. n .. END, have, final[n] or have)
        else
            L[#L + 1] = T("Nessun punto talento a questo livello.")
        end
    end
    L[#L + 1] = ""

    L[#L + 1] = title(T("Abilita' nuove"))
    if spec.spells[level] then
        for piece in T(spec.spells[level]):gmatch("[^,;]+") do
            piece = piece:gsub("^%s+", ""):gsub("%s+$", "")
            local name = (piece:match(":%s*(.+)$") or piece):gsub("^e%s+", "")
            L[#L + 1] = GF.IconTag(name, 16) .. piece
        end
    else
        L[#L + 1] = GREY .. T("Nessuna a questo livello.") .. END
    end
    for lvl = level + 1, 60 do
        if spec.spells[lvl] then
            L[#L + 1] = GREY .. Lf("Prossime (livello %d): %s", lvl, T(spec.spells[lvl])) .. END
            break
        end
    end
    L[#L + 1] = ""

    local band = currentBand(spec, level)
    L[#L + 1] = title(band and Lf("Rotazione (da livello %d)", band[1]) or T("Rotazione"))
    if band then
        local text = T(band[2])
        local strip = GF.IconsInText(spec, text, 22, 8)
        if strip ~= "" then
            L[#L + 1] = strip
        end
        L[#L + 1] = text
    else
        L[#L + 1] = "-"
    end
    L[#L + 1] = ""

    L[#L + 1] = title(T("Prossimi talenti"))
    local shown = 0
    for lvl = level + 1, 60 do
        if plan[lvl] and shown < 6 then
            L[#L + 1] = Lf("Livello %d: %s", lvl, GF.IconTag(plan[lvl], 16) .. plan[lvl])
            shown = shown + 1
        end
    end
    if shown == 0 then
        L[#L + 1] = GREY .. T("Nessuno.") .. END
    end
    return table.concat(L, "\n")
end

-- Tab: Talenti ----------------------------------------------------------------------------------------------------------
local function tabTalents(spec, level)
    local L = { title(T("Piano dei 51 punti talento (livelli 10-60)")),
        GREY .. T("Grigio: gia' fatto. Oro: il punto di questo livello. I segni sul pannello dei talenti seguono questo piano.") .. END, "" }
    for _, run in ipairs(spec.talentRuns) do
        local a, b, name = run[1], run[2], run[3]
        local points = b - a + 1
        local range = (a == b) and Lf("Liv %d", a) or Lf("Liv %d-%d", a, b)
        local line = range .. ":  " .. GF.IconTag(name, 18) .. name .. (points > 1 and (" x" .. points) or "")
        if b < level then
            line = GREY .. line .. END
        elseif a <= level and level <= b then
            line = GOLD .. "> " .. line .. END
        else
            line = WHITE .. line .. END
        end
        L[#L + 1] = line
    end
    return table.concat(L, "\n")
end

-- Tab: Rotazione --------------------------------------------------------------------------------------------------------
local function tabRotation(spec, level)
    local L = { title(T("Rotazione, a passi di livello")),
        GREY .. T("Hekili sceglie da solo le abilita' che hai gia' imparato: queste note spiegano il perche'.") .. END, "" }
    local current = currentBand(spec, level)
    for _, b in ipairs(spec.bands) do
        local text = T(b[2])
        local strip = GF.IconsInText(spec, text, 22, 8)
        if current and b[1] == current[1] then
            L[#L + 1] = GOLD .. "> " .. Lf("Da livello %d (ora)", b[1]) .. END
            if strip ~= "" then
                L[#L + 1] = strip
            end
            L[#L + 1] = text
        else
            local color = (b[1] < level) and GREY or WHITE
            L[#L + 1] = color .. Lf("Da livello %d", b[1]) .. END
            if strip ~= "" then
                L[#L + 1] = strip
            end
            L[#L + 1] = color .. text .. END
        end
        L[#L + 1] = ""
    end
    return table.concat(L, "\n")
end

-- Tab: Oggetti ----------------------------------------------------------------------------------------------------------
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

local function tabItems(spec)
    local L = {}
    local w = spec.itemWeights
    L[#L + 1] = title(T("Come valuto gli oggetti"))
    if not w then
        L[#L + 1] = T("Per questa spec non ci sono ancora le regole sugli oggetti.")
        return table.concat(L, "\n")
    end
    L[#L + 1] = GREY .. T("Ogni statistica vale un numero di 'punti Agilita'': piu' e' alto, piu' conta.") .. END
    L[#L + 1] = ""
    L[#L + 1] = title(T("Cosa conta, in ordine"))
    local list = {}
    if (w.rangedDps or 0) > 0 then
        list[#list + 1] = { T("DPS dell'arma a distanza (bacchetta)"), w.rangedDps }
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
        return a[2] > b[2]
    end)
    for i, e in ipairs(list) do
        L[#L + 1] = i .. ".  " .. e[1] .. GREY .. "  " .. Lf("(vale %s)", string.format("%g", e[2])) .. END
    end
    if (w.meleeDps or 0) == 0 then
        L[#L + 1] = RED .. "-" .. END .. "  " .. T("DPS dell'arma da mischia") .. GREY .. "  " .. T("(non conta: conta solo cio' che da' in statistiche)") .. END
    end
    if (w.rangedDps or 0) == 0 then
        L[#L + 1] = RED .. "-" .. END .. "  " .. T("DPS dell'arma a distanza") .. GREY .. "  " .. T("(non conta per questa spec)") .. END
    end
    L[#L + 1] = ""
    L[#L + 1] = title(T("Il parere nel tooltip"))
    local limit = tonumber(BuildBeastDB and BuildBeastDB.threshold) or 1
    L[#L + 1] = GREEN .. GF.VerdictWord("SI") .. END .. ": " .. Lf("ti da' almeno %s punti in piu' di quello che indossi.", limit)
    L[#L + 1] = RED .. GF.VerdictWord("NO") .. END .. ": " .. Lf("ne perdi almeno %s.", limit)
    L[#L + 1] = "|cffffd933" .. GF.VerdictWord("SIMILE") .. "|r: " .. T("la differenza e' piccola.")
    L[#L + 1] = GREEN .. T("Verde") .. END .. " = " .. T("cosa guadagni,") .. " " .. RED .. T("rosso") .. END .. " = " .. T("cosa perdi.")
    L[#L + 1] = ""
    L[#L + 1] = title(T("Incantamenti"))
    L[#L + 1] = T("Li propone GearQuest (la riga gialla \"Recommended enchantment\" nel tooltip dell'oggetto).")
    if spec.itemWeights.why then
        L[#L + 1] = ""
        L[#L + 1] = title(T("Perche'"))
        L[#L + 1] = T(spec.itemWeights.why)
    end
    return table.concat(L, "\n")
end

-- Tab: Addon ------------------------------------------------------------------------------------------------------------
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

local function tabAddons()
    local L = { title(T("Addon che lavorano con BuildBeast")), "" }
    local function entry(name, label, what)
        local loaded, version = addonInfo(name)
        local state = loaded and (GREEN .. T("attivo") .. END) or (RED .. T("non trovato") .. END)
        L[#L + 1] = WHITE .. T(label) .. END .. "  " .. state .. (version and (GREY .. "  " .. Lf("(versione %s)", version) .. END) or "")
        L[#L + 1] = GREY .. T(what) .. END
        L[#L + 1] = ""
    end
    entry("Hekili", N("Hekili (consigliato)"), N("Calcola la rotazione. BuildBeast gli da' la sua priorita' e illumina i tasti. Senza Hekili non ci sono suggerimenti di abilita'."))
    entry("GearQuestForever", N("GearQuest Forever (consigliato)"), N("Suggerisce oggetti e incantamenti per livello. BuildBeast aggiunge il suo parere, e spiega il perche'."))
    entry("ZygorGuidesViewerForever", N("Zygor (facoltativo)"), N("Guida di zona e missioni. Se i suoi segni sui talenti ti disturbano, spegnili nelle Opzioni."))
    L[#L + 1] = title(T("Traduzioni italiane"))
    local tr = GF.TranslationStatus and GF.TranslationStatus() or {}
    L[#L + 1] = "Hekili: " .. tostring(tr.hekili or "?")
    L[#L + 1] = "GearQuest: " .. tostring(tr.gq or "?")
    L[#L + 1] = GREY .. T("Le porta BuildBeast, cosi' un aggiornamento di Hekili o di GearQuest non le cancella. Si accendono e si spengono nelle Opzioni (poi /reload).") .. END
    return table.concat(L, "\n")
end

-- Tab: Macro ------------------------------------------------------------------------------------------------------------
local function tabMacros(class, specKey)
    local list = GF.macrosFor(class, specKey)
    if #list == 0 then
        return title(T("Macro")) .. "\n" .. T("Per questa spec non ci sono macro suggerite.")
    end
    local L = { title(T("Macro suggerite per questa spec")),
        GREY .. T("Il bottone qui sopra le crea nel gioco (con conferma). Poi le trovi in /macro e le trascini sulle barre. I nomi dei colpi sono quelli inglesi.") .. END, "" }
    for _, m in ipairs(list) do
        L[#L + 1] = WHITE .. m.name .. END .. "  " .. T(m.why)
        L[#L + 1] = GREY .. m.body .. END
        L[#L + 1] = ""
    end
    return table.concat(L, "\n")
end

-- Window ----------------------------------------------------------------------------------------------------------------
function GF.RefreshWindow()
    if not (frame and frame:IsShown()) then
        return
    end
    local spec, specKey, class = GF.specData()
    local mine = UnitLevel("player") or 1
    viewLevel = math.max(1, math.min(60, viewLevel or mine))

    -- spec buttons
    for _, b in ipairs(frame.specButtons) do
        b:Hide()
    end
    local list = GF.SPECS[class] or {}
    local n = #list
    local w = n > 0 and math.floor((486 - (n - 1) * 6) / n) or 100
    for i, s in ipairs(list) do
        local b = frame.specButtons[i]
        if not b then
            b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            b:SetHeight(22)
            frame.specButtons[i] = b
        end
        b:SetWidth(w)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 16 + (i - 1) * (w + 6), -62)
        local has = GF.DATA and GF.DATA[class] and GF.DATA[class][s[1]]
        b:SetText((s[1] == specKey and "> " or "") .. s[2] .. (has and "" or (" " .. T("(in arrivo)"))))
        b:SetScript("OnClick", function()
            GF.ChooseSpec(s[1])
        end)
        b:Show()
    end

    if GF.RefreshQuick then
        GF.RefreshQuick()
    end
    local classLabel = GF.CLASS_LABEL[class] and T(GF.CLASS_LABEL[class]) or tostring(class)
    local suffix = (viewLevel == mine) and ("  " .. T("(il tuo livello)")) or ""
    frame.sub:SetText(classLabel .. " - " .. GF.specLabel(class, specKey) .. " - " .. Lf("livello %d", viewLevel) .. suffix)

    local text
    if currentTab == "macro" then
        text = tabMacros(class, specKey)
    elseif currentTab == "guida" then
        text = GF.GuideText() .. "\n" .. tabAddons()
    elseif not spec then
        text = title(T("Guida non ancora disponibile")) .. "\n"
            .. Lf("Per %s la guida non c'e' ancora: il video da cui prendiamo i dati non ha una build per questa spec.", classLabel .. " " .. GF.specLabel(class, specKey))
    elseif currentTab == "talenti" then
        text = tabTalents(spec, mine)
    elseif currentTab == "rotazione" then
        text = tabRotation(spec, viewLevel)
    elseif currentTab == "oggetti" then
        text = tabItems(spec)
    else
        text = tabLevel(spec, viewLevel)
    end
    frame.text:SetText(text)
    frame.content:SetHeight(math.max(10, frame.text:GetStringHeight() + 8))
    frame.scroll:SetVerticalScroll(0)

    -- tabs and level buttons
    for _, t in ipairs(frame.tabButtons) do
        t.btn:SetText((t.key == currentTab) and ("> " .. T(t.label)) or T(t.label))
    end
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
    f:SetSize(520, 600)
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
    local tw = math.floor((486 - (#TABS - 1) * 4) / #TABS)
    for i, t in ipairs(TABS) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(tw, 24)
        b:SetPoint("TOPLEFT", 16 + (i - 1) * (tw + 4), -90)
        b:SetScript("OnClick", function()
            currentTab = t[1]
            GF.RefreshWindow()
        end)
        f.tabButtons[#f.tabButtons + 1] = { key = t[1], label = t[2], btn = b }
    end

    -- level navigation (Livello and Rotazione)
    f.navButtons = {}
    local function nav(label, width, x, fn)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(width, 22)
        b:SetPoint("TOPLEFT", x, -120)
        b:SetText(label)
        b:SetScript("OnClick", fn)
        f.navButtons[#f.navButtons + 1] = b
    end
    nav("<", 36, 16, function()
        viewLevel = (viewLevel or UnitLevel("player") or 1) - 1
        GF.RefreshWindow()
    end)
    nav(">", 36, 56, function()
        viewLevel = (viewLevel or UnitLevel("player") or 1) + 1
        GF.RefreshWindow()
    end)
    nav(T("Il mio livello"), 110, 96, function()
        viewLevel = UnitLevel("player") or 1
        GF.RefreshWindow()
    end)

    local mb = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    mb:SetSize(220, 22)
    mb:SetPoint("TOPLEFT", 16, -120)
    mb:SetText(T("Crea le macro di questa spec"))
    mb:SetScript("OnClick", function()
        GF.CreateMacros()
    end)
    mb:Hide()
    f.macroBtn = mb

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -150)
    scroll:SetPoint("BOTTOMRIGHT", -34, 44)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(456, 10)
    scroll:SetScrollChild(content)
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetWidth(456)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    f.text, f.scroll, f.content = text, scroll, content

    -- the Opzioni tab: its own scroll area with the check boxes of Options.lua
    local optScroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    optScroll:SetPoint("TOPLEFT", 16, -122)
    optScroll:SetPoint("BOTTOMRIGHT", -34, 44)
    local optContent = CreateFrame("Frame", nil, optScroll)
    optContent:SetSize(456, 10)
    optScroll:SetScrollChild(optContent)
    f.optScroll = optScroll
    optScroll:Hide()
    GF.BuildOptionsInto(optContent)

    -- size of the interface: + and - at the bottom (scales the whole window, text and icons included)
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
    f:SetScale(GF.GetScale())
    if GF.ApplyFonts then
        C_Timer.After(0, function()
            GF.ApplyFonts(f)
        end)
    end
    f:SetClampedToScreen(true)

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
