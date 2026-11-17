-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: the options window. Every setting of the addon in one place, with a short explanation under each.
-- They live in the "Opzioni" tab of the main window (minimap button right click, /bb opzioni, and a button on the
-- AddOns page of the game settings).

local ADDON, GF = ...
local T, Lf = GF.T, GF.L
local function N(text)
    return text
end

local rows = {}

local function get(key, default)
    local v = BuildBeastDB and BuildBeastDB[key]
    if v == nil then
        return default
    end
    return v
end

local function zygorIconsOn()
    local zgv = _G.ZGV
    local p = zgv and zgv.db and zgv.db.profile
    if p and p.ta_toggle_icons ~= nil then
        return p.ta_toggle_icons and true or false
    end
    return true
end

-- EllesmereUI adds the lines "ItemID" and "IconID" to tooltips, controlled by two of its own settings
-- (EllesmereUIDB.showItemID / showIconID, the ones its options page changes). We switch them off (and back on) and keep
-- the previous values, so "off" is always undone exactly.
function GF.ApplyEllesmereIDs()
    local db = _G.EllesmereUIDB
    if type(db) ~= "table" then
        return
    end
    if get("hideIds", true) then
        if BuildBeastDB.idsWas == nil then
            BuildBeastDB.idsWas = { item = db.showItemID, icon = db.showIconID }
        end
        db.showItemID = false
        db.showIconID = false
    elseif BuildBeastDB.idsWas ~= nil then
        db.showItemID = BuildBeastDB.idsWas.item
        db.showIconID = BuildBeastDB.idsWas.icon
        BuildBeastDB.idsWas = nil
    end
end

-- BASE SETTINGS: on install (first login and every login until the player restores the originals) the addon sets what
-- we decided together in the other addons. Every value it changes is remembered first (BuildBeastDB.orig...), so the
-- "Ripristina" button puts the other addons back exactly as they were.
function GF.ApplyBase()
    if BuildBeastDB.baseOff then
        return
    end
    GF.ApplyEllesmereIDs()
    local want = BuildBeastDB.zygorIcons
    if want == nil then
        want = false -- our marks on the talent window replace Zygor's, so they are not drawn twice
    end
    GF.SetZygorTalentIcons(want, true, true)
end

-- puts the other addons back as they were and switches our changes off (a /reload completes it)
function GF.RestoreOriginals()
    local orig = BuildBeastDB.orig or {}
    BuildBeastDB.baseOff = true

    -- EllesmereUI: ItemID / IconID lines
    BuildBeastDB.hideIds = false
    GF.ApplyEllesmereIDs()

    -- Zygor: its marks on the talent window
    if orig.zygorIcons ~= nil then
        GF.SetZygorTalentIcons(orig.zygorIcons, true, true)
    end
    BuildBeastDB.zygorIcons = nil

    -- Hekili: the priority it used before ours
    local H = _G.Hekili
    if H and orig.hekili then
        for specId, name in pairs(orig.hekili) do
            local exists = H.DB and H.DB.profile and H.DB.profile.packs and rawget(H.DB.profile.packs, name)
            if exists then
                pcall(H.ActivatePack, H, specId, name)
            end
        end
    end
    BuildBeastDB.rotation = false
    if orig.hekili then
        BuildBeastDB.orig.hekili = nil
    else
        GF.say(T("Hekili: non ho registrato una priorita' precedente (la nostra era gia' attiva prima di questa versione). Scegli quella che vuoi in Hekili > Priorita'."))
    end

    -- the look of the action buttons, and the translations
    GF.SetCooldownNumbers(false)
    BuildBeastDB.glow = false
    BuildBeastDB.trHekili = false
    BuildBeastDB.trGQ = false
    GF.RefreshOptions()
    GF.say(T("impostazioni originali degli altri addon ripristinate. Fai |cff00ff00/reload|r per completare (le traduzioni tornano in inglese al prossimo accesso)."))
end

-- puts the base settings back
function GF.ReapplyBase()
    BuildBeastDB.baseOff = nil
    BuildBeastDB.hideIds = true
    BuildBeastDB.zygorIcons = nil
    BuildBeastDB.rotation = true
    BuildBeastDB.glow = true
    BuildBeastDB.trHekili = true
    BuildBeastDB.trGQ = true
    GF.SetCooldownNumbers(true)
    GF.ApplyBase()
    GF.InitRotation(true)
    GF.RefreshOptions()
    GF.say(T("impostazioni di base applicate. Fai |cff00ff00/reload|r per applicare anche le traduzioni."))
end

local OPTIONS = {
    { header = N("Impostazioni di base") },
    { text = N("Appena installato, BuildBeast imposta da solo quello che abbiamo deciso: rotazione in Hekili, illuminazione e numeri di ricarica sui tasti, righe ItemID/IconID nascoste, segni di Zygor spenti, traduzioni italiane. Prima di cambiare qualcosa negli altri addon ricorda come era.") },
    {
        button = N("Ripristina le impostazioni originali degli altri addon"),
        desc = N("Rimette Hekili, Zygor ed EllesmereUI come erano prima e spegne le nostre modifiche ai tasti. Le singole voci qui sotto restano modificabili."),
        onClick = function() GF.RestoreOriginals() end,
    },
    {
        button = N("Applica di nuovo le impostazioni di base"),
        desc = N("Rimette tutto come lo propone BuildBeast."),
        onClick = function() GF.ReapplyBase() end,
    },
    { header = N("Rotazione e tasti") },
    {
        label = N("Rotazione di BuildBeast in Hekili"),
        desc = N("Al login Hekili usa la rotazione della guida per la tua spec (niente corpo a corpo, falchi dal 25)."),
        get = function() return get("rotation", true) end,
        set = function(v)
            BuildBeastDB.rotation = v
            if v then
                GF.InitRotation(true)
            end
        end,
    },
    {
        label = N("Illumina i tasti"),
        desc = N("Oro: l'abilita' da usare ora. Blu: la prossima. Grigio: Hekili la nomina ma il gioco mostra ancora la ricarica."),
        get = function() return get("glow", true) end,
        set = function(v) GF.SetBarGlow(v, true) end,
    },
    {
        label = N("Numeri di ricarica sui tasti"),
        desc = N("Il tempo che manca scritto sul tasto: bianco, giallo sotto i 5 secondi, rosso sotto i 2."),
        get = function() return get("cd", true) end,
        set = function(v) GF.SetCooldownNumbers(v) end,
    },
    {
        label = N("Nascondi l'ombreggiatura dei cooldown"),
        desc = N("Toglie l'ombra che gira sul tasto. Parte solo dopo che i numeri hanno funzionato almeno una volta."),
        get = function() return get("swipe", false) ~= true end,
        set = function(v) GF.SetCooldownSwipeHidden(v) end,
    },
    { header = N("Talenti") },
    {
        label = N("Segni sul pannello dei talenti"),
        desc = N("+N oro: punti da spendere ora. OK verde: a posto. Liv 23 blu: il prossimo punto arriva a quel livello. X rosso: troppi punti."),
        get = function() return get("marks", true) end,
        set = function(v) GF.SetTalentMarks(v) end,
    },
    {
        label = N("Segni dei talenti di Zygor"),
        desc = N("Zygor disegna i suoi segni sugli stessi talenti. Se li vedi doppi, spegnili."),
        get = zygorIconsOn,
        set = function(v) GF.SetZygorTalentIcons(v, true, false) end,
    },
    { header = N("Oggetti") },
    {
        label = N("Parere sugli oggetti"),
        desc = N("Una riga nel tooltip: SI, NO o SIMILE rispetto a quello che indossi, secondo la tua spec."),
        get = function() return get("verdict", true) end,
        set = function(v) BuildBeastDB.verdict = v end,
    },
    {
        label = N("Frecce sulle icone degli oggetti (borse)"),
        desc = N("Freccia verde = SI, rossa = NO, trattino giallo = SIMILE, sull'icona dell'oggetto nella borsa. Se un'altra borsa ha le sue frecce, spegni quelle nelle sue opzioni: due frecce sulla stessa icona si contraddicono."),
        get = function() return get("arrows", true) end,
        set = function(v) GF.SetArrows(v) end,
    },
    {
        step = true,
        label = N("Soglia del parere"),
        desc = N("Di quanti punti deve differire l'oggetto da quello che indossi per dare SI o NO. Piu' e' bassa, meno SIMILE vedrai (di base 1)."),
        get = function() return tonumber(get("threshold", 1)) or 1 end,
        set = function(v) BuildBeastDB.threshold = v end,
        min = 0.5, max = 10, by = 0.5,
    },
    {
        label = N("Spiega il perche'"),
        desc = N("Sotto il parere scrive cosa guadagni e cosa perdi, e perche' per la tua spec conta o no."),
        get = function() return get("why", true) end,
        set = function(v) BuildBeastDB.why = v end,
    },
    {
        label = N("Nascondi ItemID e IconID nei tooltip"),
        desc = N("Sono righe aggiunte da EllesmereUI, utili solo a chi crea addon. Qui le togli o le rimetti (vale dal prossimo tooltip)."),
        get = function() return get("hideIds", true) end,
        set = function(v)
            BuildBeastDB.hideIds = v
            GF.ApplyEllesmereIDs()
        end,
    },
    { header = N("Traduzione italiana") },
    {
        label = N("Hekili in italiano"),
        desc = N("Porta le traduzioni italiane di Hekili. Vale dal prossimo /reload (qualche testo puo' restare in inglese fino al prossimo accesso)."),
        get = function() return get("trHekili", true) end,
        set = function(v)
            BuildBeastDB.trHekili = v
            GF.say(T("traduzione di Hekili: fai /reload per applicare il cambio."))
        end,
    },
    {
        label = N("GearQuest in italiano"),
        desc = N("Porta le traduzioni italiane di GearQuest (finestre, tooltip, frasi). Vale dal prossimo /reload."),
        get = function() return get("trGQ", true) end,
        set = function(v)
            BuildBeastDB.trGQ = v
            GF.say(T("traduzione di GearQuest: fai /reload per applicare il cambio."))
        end,
    },
    { header = N("Lingua") },
    {
        langs = true,
        desc = N("Scegli la lingua di BuildBeast (Auto usa quella del gioco). Per coreano e cinese serve che il gioco abbia i font di quelle lingue."),
    },
    { header = N("Altro") },
    {
        label = N("Pannello rapido"),
        desc = N("Un riquadro piccolo sempre sullo schermo con il prossimo talento da prendere. Lo sposti trascinandolo."),
        get = function() return get("quick", true) end,
        set = function(v) GF.SetQuickShown(v) end,
    },
    {
        label = N("Pulsante sulla minimappa"),
        desc = N("Clic sinistro: la guida del tuo livello. Clic destro: queste opzioni."),
        get = function() return not (BuildBeastDB.minimap and BuildBeastDB.minimap.hide) end,
        set = function(v) GF.SetMinimapShown(v) end,
    },
}

-- Builds the rows into `parent` (a frame 456 wide, inside a scroll area) and sizes it
function GF.BuildOptionsInto(parent)
    local y = -4
    for _, o in ipairs(OPTIONS) do
        if o.text then
            local t = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            t:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, y)
            t:SetWidth(440)
            t:SetJustifyH("LEFT")
            t:SetText(T(o.text))
            y = y - (t:GetStringHeight() + 10)
        elseif o.button then
            local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            b:SetSize(340, 24)
            b:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
            b:SetText(T(o.button))
            b:SetScript("OnClick", o.onClick)
            local d = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            d:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -3)
            d:SetWidth(440)
            d:SetJustifyH("LEFT")
            d:SetText(T(o.desc or ""))
            y = y - (24 + 3 + d:GetStringHeight() + 12)
        elseif o.step then
            local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("TOPLEFT", parent, "TOPLEFT", 34, y - 4)
            label:SetText(T(o.label))
            local minus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            minus:SetSize(26, 22)
            minus:SetPoint("TOPLEFT", parent, "TOPLEFT", 200, y)
            minus:SetText("-")
            local val = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            val:SetPoint("LEFT", minus, "RIGHT", 4, 0)
            val:SetWidth(40)
            local plus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            plus:SetSize(26, 22)
            plus:SetPoint("LEFT", val, "RIGHT", 4, 0)
            plus:SetText("+")
            local function upd()
                val:SetText(string.format("%.1f", o.get()))
            end
            local function change(d)
                local v = math.max(o.min, math.min(o.max, o.get() + d))
                o.set(v)
                upd()
            end
            minus:SetScript("OnClick", function() change(-o.by) end)
            plus:SetScript("OnClick", function() change(o.by) end)
            local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            desc:SetPoint("TOPLEFT", parent, "TOPLEFT", 34, y - 28)
            desc:SetWidth(400)
            desc:SetJustifyH("LEFT")
            desc:SetText(T(o.desc or ""))
            rows[#rows + 1] = { upd = upd }
            upd()
            y = y - (28 + desc:GetStringHeight() + 12)
        elseif o.langs then
            local names = {}
            local function add(code, label)
                names[#names + 1] = { code, label }
            end
            add("auto", T("Auto"))
            for _, l in ipairs(GF.LANGS) do
                add(l[1], l[2] .. (GF.LANG_EN[l[1]] and (" (" .. GF.LANG_EN[l[1]] .. ")") or ""))
            end
            local btns = {}
            for i, e in ipairs(names) do
                local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
                local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
                b:SetSize(212, 24)
                b:SetPoint("TOPLEFT", parent, "TOPLEFT", 4 + col * 218, y - row * 28)
                b:SetText(e[2])
                b:SetScript("OnClick", function()
                    GF.SetLanguage(e[1])
                end)
                btns[e[1]] = { b = b, label = e[2] }
            end
            y = y - (math.ceil(#names / 2) * 28 + 2)
            local d = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            d:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
            d:SetWidth(440)
            d:SetJustifyH("LEFT")
            d:SetText(T(o.desc or ""))
            y = y - (d:GetStringHeight() + 12)
            rows[#rows + 1] = { upd = function()
                local cur = (BuildBeastDB and BuildBeastDB.lang) or "auto"
                for code, e in pairs(btns) do
                    e.b:SetText((code == cur and "> " or "") .. e.label)
                end
            end }
        elseif o.header then
            local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            h:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, y - 4)
            h:SetText(T(o.header))
            h:SetTextColor(1, 0.82, 0)
            y = y - 26
        else
            local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
            cb:SetSize(26, 26)
            cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
            local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("TOPLEFT", cb, "TOPRIGHT", 4, -4)
            label:SetText(T(o.label))
            local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
            desc:SetWidth(400)
            desc:SetJustifyH("LEFT")
            desc:SetText(T(o.desc or ""))
            cb:SetScript("OnClick", function(self)
                o.set(self:GetChecked() and true or false)
            end)
            rows[#rows + 1] = { cb = cb, o = o }
            local h = 8 + label:GetStringHeight() + 2 + desc:GetStringHeight() + 8
            y = y - math.max(30, h)
        end
    end
    parent:SetHeight(-y + 10)
end

GF.LANG_EN = { ru = "Russian", ko = "Korean", zh = "Chinese", zt = "Chinese, traditional" }

function GF.ResetOptionRows()
    rows = {}
end

-- changes the language and redraws everything that is already on the screen
function GF.SetLanguage(code)
    BuildBeastDB.lang = code
    if GF.RebuildWindow then
        GF.RebuildWindow("opzioni")
    end
    if GF.RefreshQuick then
        GF.RefreshQuick()
    end
    if _G.BuildBeastQuick and GF.ApplyFonts then
        GF.ApplyFonts(_G.BuildBeastQuick)
    end
end

-- ticks the boxes according to the saved settings
function GF.RefreshOptions()
    for _, r in ipairs(rows) do
        if r.upd then
            r.upd()
        else
            r.cb:SetChecked(r.o.get() and true or false)
        end
    end
end

-- the options are a tab of the main window
function GF.ToggleOptions()
    GF.ShowTab("opzioni", true)
end

-- a small page in the game's AddOns settings with a button that opens the options tab
function GF.RegisterSettingsCategory()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end
    pcall(function()
        local panel = CreateFrame("Frame")
        panel.name = "BuildBeast"
        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("BuildBeast")
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetSize(200, 26)
        b:SetPoint("TOPLEFT", 16, -52)
        b:SetText("Apri le opzioni")
        b:SetScript("OnClick", function()
            GF.ShowTab("opzioni", false)
        end)
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    end)
end
