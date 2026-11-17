-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: macros suggested for each build. The window shows them (tab "Macro") and a button
-- creates them in the game, after a confirmation. Names start with "BB " so they are easy to find and to update.
-- Spell names in the macro text are the English ones (that is what the WoW Forever client uses).

local ADDON, GF = ...
local T, Lf = GF.T, GF.L

local D = {}

local function def(id, name, why, ...)
    D[id] = { name = name, why = why, body = table.concat({ ... }, "\n") }
end

-- Hunter
def("h_autoshot", "GL Auto Shot", "Cambi bersaglio senza fermare il tiro automatico.",
    "#showtooltip Auto Shot", "/cleartarget [dead]", "/targetenemy [noharm]", "/cast !Auto Shot")
def("h_mark", "GL Marchio", "Il pet attacca il bersaglio che marchi con Hunter's Mark.",
    "#showtooltip Hunter's Mark", "/petattack", "/cast Hunter's Mark")
def("h_melee_bm", "GL Mischia", "Un solo tasto per le abilita' da mischia, quando ti attaccano.",
    "#showtooltip", "/startattack", "/cast Raptor Strike", "/cast Mongoose Bite")
def("h_melee_sv", "GL Mischia", "Un solo tasto per le abilita' da mischia, quando ti attaccano.",
    "#showtooltip", "/startattack", "/cast Raptor Strike", "/cast Strider's Kick")
def("h_counter", "GL Contrattacco", "Alterna Mongoose Bite e Counterattack con un tasto solo, dopo una schivata o una parata.",
    "/startattack", "/cast Mongoose Bite", "/cast Counterattack")

-- Warrior
def("w_start", "GL Avvia attacco", "Lancia l'abilita' e fa partire l'attacco automatico, anche prima di ingaggiare. Al posto di Heroic Strike puoi mettere un'altra abilita'. Serve rabbia sufficiente.",
    "#showtooltip", "/cast Heroic Strike", "/startattack")
def("w_sunder", "GL Sunder mouse", "Sunder Armor sul nemico sotto il cursore, senza selezionarlo.",
    "#showtooltip Sunder Armor", "/cast [@mouseover] Sunder Armor")

-- Paladin
def("p_bop", "GL Protezione", "Blessing of Protection sull'alleato sotto il cursore (se non c'e', sul bersaglio).",
    "#showtooltip Blessing of Protection", "/cast [@mouseover,help][] Blessing of Protection")
def("p_bof", "GL Liberta'", "Blessing of Freedom sull'alleato sotto il cursore.",
    "#showtooltip Blessing of Freedom", "/cast [@mouseover,help][] Blessing of Freedom")
def("p_cleanse", "GL Purifica", "Cleanse sull'alleato sotto il cursore.",
    "#showtooltip Cleanse", "/cast [@mouseover,help][] Cleanse")
def("p_dummy", "GL Manichino", "Evoca l'Advanced Target Dummy sul cursore e gli lancia Blessing of Protection: tienilo premuto due volte, senza ricarica globale attiva.",
    "#showtooltip Advanced Target Dummy", "/use [@cursor] Advanced Target Dummy", "/cleartarget",
    "/target Advanced Target Dummy", "/stopmacro [noexists][dead]", "/cast [@target] Blessing of Protection")
def("p_bubble", "GL Bolla", "Divine Shield su di te; premendo di nuovo lo togli subito. Premila due volte, senza ricarica globale attiva.",
    "#showtooltip", "/cast Divine Shield", "/cancelaura Divine Shield")
def("p_holystrike", "GL Holy Strike", "Fa partire l'attacco automatico e lancia Holy Strike. Non metterla su Holy Shield.",
    "#showtooltip Holy Strike", "/startattack", "/cast Holy Strike")

-- Priest
def("pr_pws", "GL Scudo mouse", "Power Word: Shield sul cursore, se no su di te.",
    "#showtooltip Power Word: Shield", "/cast [@mouseover,help,nodead][@player] Power Word: Shield")
def("pr_gheal", "GL Cura mouse", "Greater Heal sul cursore, se no sul bersaglio, se no su di te.",
    "#showtooltip Greater Heal", "/cast [@mouseover,help,nodead][@target,help,nodead][@player] Greater Heal")
def("pr_cancel", "GL Cura nuova", "Ferma il lancio in corso e rilancia Greater Heal: per quando un altro healer ha gia' curato quel bersaglio.",
    "#showtooltip Greater Heal", "/stopcasting", "/cast [@mouseover,help,nodead][@target,help,nodead][@player] Greater Heal")
def("pr_if", "GL Focus+Preghiera", "Inner Focus e subito Prayer of Healing: per le emergenze.",
    "#showtooltip Inner Focus", "/cast Inner Focus", "/cast [@mouseover,help,nodead][@target,help,nodead][@player] Prayer of Healing")
def("pr_dispel", "GL Dissolvi", "Dispel Magic furbo: toglie magie dannose agli alleati e benefici ai nemici.",
    "#showtooltip Dispel Magic",
    "/cast [@mouseover,help,nodead] Dispel Magic; [@mouseover,harm,nodead] Dispel Magic; [@target,help,nodead] Dispel Magic; [@target,harm,nodead] Dispel Magic; [@player] Dispel Magic")
def("pr_pom", "GL Prayer Mending", "Prayer of Mending sul cursore, se no sul bersaglio, se no su di te.",
    "#showtooltip Prayer of Mending", "/cast [@mouseover,help,nodead][@target,help,nodead][@player] Prayer of Mending")
def("pr_swd", "GL Morte Ombra", "Ferma il lancio e usa Shadow Word: Death su un mostro quasi morto che scappa o su un totem.",
    "#showtooltip Shadow Word: Death", "/stopcasting", "/cast [@mouseover,harm,nodead][@target,harm,nodead] Shadow Word: Death")

-- Rogue
def("r_main", "GL Veleno mano 1", "Applica Deadly Poison all'arma della mano principale; l'icona mostra la durata.",
    "#showtooltip 16", "/use Deadly Poison", "/use 16")
def("r_off", "GL Veleno mano 2", "Applica Instant Poison all'arma della mano secondaria; l'icona mostra la durata.",
    "#showtooltip 17", "/use Instant Poison", "/use 17")
def("r_pick", "GL Borseggio", "Pick Pocket come apertura, poi Garrote (puoi cambiarlo con Cheap Shot o Ambush).",
    "#showtooltip Garrote", "/cast Pick Pocket", "/cast Garrote")

-- Shaman
def("s_attack", "GL Attacco", "Mandi all'attacco pet e personaggio con un solo tasto: cosi' non resti fermo mentre sali.",
    "/petattack", "/startattack")
def("s_storm", "GL Stormstrike", "Come BB Attacco, ma lancia anche Stormstrike (al posto della macro precedente).",
    "#showtooltip", "/petattack", "/startattack", "/cast Stormstrike")
def("s_proj", "GL Proiezione", "Totemic Projection dove si trova il cursore.",
    "#showtooltip", "/cast [@cursor] Totemic Projection")
def("s_ns", "GL Cura veloce", "Nature's Swiftness e subito Healing Wave sul cursore: cura d'emergenza istantanea. Togli [@mouseover] se non vuoi la cura col cursore.",
    "#showtooltip", "/cast Nature's Swiftness", "/cast [@mouseover] Healing Wave")

-- Mage
def("m_poly", "GL Polimorfo", "Polymorph sul bersaglio focus; se non c'e' o non e' nemico, sul bersaglio attuale.",
    "#showtooltip Polymorph", "/cast [@focus,harm,nodead][] Polymorph")
def("m_trinket", "GL Monili", "Usa i due monili con un tasto solo (slot 13 e 14).",
    "#showtooltip", "/use 13", "/use 14")
def("m_comb", "GL Combustione", "Combustion insieme ai due monili.",
    "#showtooltip Combustion", "/use Combustion", "/use 13", "/use 14")

-- Warlock
def("l_pet", "GL Pet", "Manda il pet all'attacco e poi lo mette passivo, come in guida.",
    "#showtooltip", "/petattack", "/petpassive")
def("l_amp", "GL Amplify Agony", "Amplify Curse e Bane of Agony insieme: per l'apertura o quando Amplify Curse e' pronta.",
    "#showtooltip", "/cast Amplify Curse", "/cast Bane of Agony")
def("l_drain", "GL Drain Life", "Drain Life che si puo' premere piu' volte senza interrompersi.",
    "#showtooltip Drain Life", "/cast [nochanneling:Drain Life] Drain Life")
def("l_dot", "GL DOT mouse", "Corruption sul bersaglio sotto il cursore: per mettere DOT su piu' nemici. Cambia Corruption per un altro DOT.",
    "/cast [@mouseover,exists] Corruption")
def("l_fel_imp", "GL Fel Imp", "Fel Domination e subito Imp: per richiamare il pet dopo la morte, o per la build execute.",
    "#showtooltip Fel Domination", "/cast Fel Domination", "/stopcasting", "/cast Summon Imp")
def("l_fel_suc", "GL Fel Succubus", "Fel Domination e subito Succubus: per richiamare il pet dopo la morte.",
    "#showtooltip Fel Domination", "/cast Fel Domination", "/stopcasting", "/cast Summon Succubus")
def("l_havoc", "GL Havoc mouse", "Bane of Havoc sul bersaglio sotto il cursore.",
    "#showtooltip", "/cast [@mouseover,exists] Bane of Havoc")
def("l_f_immo", "GL Focus Immolate", "Immolate sul focus (il bersaglio di Bane of Havoc).",
    "#showtooltip", "/cast [@focus] Immolate")
def("l_f_corr", "GL Focus Corrupt", "Corruption sul focus.",
    "#showtooltip", "/cast [@focus] Corruption")
def("l_f_doom", "GL Focus Doom", "Bane of Doom sul focus.",
    "#showtooltip", "/cast [@focus] Bane of Doom")
def("l_f_agony", "GL Focus Agony", "Bane of Agony sul focus.",
    "#showtooltip", "/cast [@focus] Bane of Agony")

-- Druid
def("d_hurr", "GL Hurricane", "Hurricane che non si interrompe da solo se premi il tasto durante il lancio.",
    "#showtooltip", "/cast [nochanneling:Hurricane] Hurricane")
def("d_moon", "GL Moonfire mouse", "Moonfire sul cursore: per mettere DOT su piu' nemici (cambia con Insect Swarm per l'altro).",
    "#showtooltip", "/cast [@mouseover,exists] Moonfire")
def("d_leap", "GL Balzo+Prowl", "Feral Charge (gatto) e poi Prowl, se non sei gia' furtivo.",
    "#showtooltip", "/cast Feral Charge (Cat)", "/cast [nostealth] Prowl")
def("d_shift", "GL Power Shift", "Cambia forma per liberarti da radici e rallentamenti: da orso a gatto, da gatto a gatto.",
    "#showtooltip", "/cast [form:1] Dire Bear Form; [form:3] Cat Form; Cat Form")
def("d_travel", "GL Viaggio", "Un tasto solo: Aquatic Form in acqua, Travel Form all'aperto, altrimenti Cat Form.",
    "#showtooltip", "/cast [swimming] Aquatic Form; [outdoors] Travel Form; Cat Form")
def("d_bear", "GL Orso", "Entra in Dire Bear Form una volta sola, senza uscirne se premi di nuovo.",
    "#showtooltip Dire Bear Form", "/cast [noform:1] Dire Bear Form")
def("d_taunt", "GL Provoca", "Growl sul focus, poi sul cursore, poi sul bersaglio.",
    "#showtooltip", "/cast [@focus,harm,nodead] Growl; [@mouseover,harm,nodead] Growl; Growl")
def("d_ns", "GL Swift+Touch", "Nature's Swiftness e subito Healing Touch: cura d'emergenza istantanea (esce dalla forma e ferma il lancio).",
    "#showtooltip", "/stopcasting", "/stopattack", "/cancelform [noform:0]", "/use Nature's Swiftness", "/use Healing Touch")

-- New names (a macro name holds 16 characters at most) and a picture for each macro (the name of a game icon). `old` is
-- the name it had before ("GL ..."): a macro that already exists under the old name is renamed, not duplicated.
local LOOK = {
    h_autoshot = { "BB Tiro Continuo", "ability_whirlwind" },
    h_mark = { "BB Marchio+Pet", "ability_hunter_snipershot" },
    h_melee_bm = { "BB Mischia", "ability_meleedamage" },
    h_melee_sv = { "BB Mischia", "ability_meleedamage" },
    h_counter = { "BB Contrattacco", "ability_warrior_challange" },
    w_start = { "BB Attacca", "ability_rogue_ambush" },
    w_sunder = { "BB Sunder Mouse", "ability_warrior_sunder" },
    p_bop = { "BB Protezione", "spell_holy_sealofprotection" },
    p_bof = { "BB Liberta'", "spell_holy_sealofvalor" },
    p_cleanse = { "BB Purifica", "spell_holy_renew" },
    p_dummy = { "BB Manichino", "inv_misc_gear_01" },
    p_bubble = { "BB Bolla", "spell_holy_divineintervention" },
    p_holystrike = { "BB Holy Strike", "spell_holy_sealofmight" },
    pr_pws = { "BB Scudo Mouse", "spell_holy_powerwordshield" },
    pr_gheal = { "BB Cura Mouse", "spell_holy_greaterheal" },
    pr_cancel = { "BB Cura Nuova", "spell_holy_flashheal" },
    pr_if = { "BB Emergenza", "spell_frost_windwalkon" },
    pr_dispel = { "BB Dissolvi", "spell_holy_dispelmagic" },
    pr_pom = { "BB Mending", "spell_holy_prayerofhealing" },
    pr_swd = { "BB Morte Ombra", "spell_shadow_demonicfortitude" },
    r_main = { "BB Veleno Mano 1", "ability_poisons" },
    r_off = { "BB Veleno Mano 2", "spell_nature_nullifypoison" },
    r_pick = { "BB Borseggio", "ability_rogue_garrote" },
    s_attack = { "BB Attacco", "ability_dualwield" },
    s_storm = { "BB Stormstrike", "ability_thunderbolt" },
    s_proj = { "BB Proiezione", "spell_nature_stoneskintotem" },
    s_ns = { "BB Cura Veloce", "spell_nature_ravenform" },
    m_poly = { "BB Polimorfo", "spell_nature_polymorph" },
    m_trinket = { "BB Monili", "inv_misc_pocketwatch_01" },
    m_comb = { "BB Combustione", "spell_fire_sealoffire" },
    l_pet = { "BB Pet", "spell_shadow_summonimp" },
    l_amp = { "BB Amplify Agony", "spell_shadow_contagion" },
    l_drain = { "BB Drain Life", "spell_shadow_lifedrain02" },
    l_dot = { "BB DOT Mouse", "spell_shadow_abominationexplosion" },
    l_fel_imp = { "BB Fel Imp", "spell_nature_removecurse" },
    l_fel_suc = { "BB Fel Succubus", "spell_shadow_summonsuccubus" },
    l_havoc = { "BB Havoc Mouse", "spell_shadow_deathpact" },
    l_f_immo = { "BB Focus Immo", "spell_fire_immolation" },
    l_f_corr = { "BB Focus Corrup", "spell_shadow_abominationexplosion" },
    l_f_doom = { "BB Focus Doom", "spell_shadow_auraofdarkness" },
    l_f_agony = { "BB Focus Agony", "spell_shadow_curseofsargeras" },
    d_hurr = { "BB Hurricane", "spell_nature_cyclone" },
    d_moon = { "BB Lunare Mouse", "spell_nature_starfall" },
    d_leap = { "BB Balzo+Prowl", "ability_ambush" },
    d_shift = { "BB Power Shift", "ability_druid_catform" },
    d_travel = { "BB Viaggio", "ability_druid_travelform" },
    d_bear = { "BB Orso", "ability_racial_bearform" },
    d_taunt = { "BB Provoca", "ability_physical_taunt" },
    d_ns = { "BB Swift+Touch", "spell_nature_ravenform" },
}
for id, look in pairs(LOOK) do
    local m = D[id]
    assert(m and #look[1] <= 16, id)
    m.old, m.name, m.icon = m.name, look[1], look[2]
end

local HEALER_PRIEST = { "pr_gheal", "pr_cancel", "pr_if", "pr_dispel", "pr_pom", "pr_swd" }
local PALADIN_BASE = { "p_bop", "p_bof", "p_cleanse", "p_dummy" }
local WARRIOR = { "w_start", "w_sunder" }
local ROGUE = { "r_main", "r_off", "r_pick" }
local MAGE = { "m_poly", "m_trinket" }

GF.MACRO_DEFS = D
GF.MACROS = {
    WARRIOR = { arms = WARRIOR, fury = WARRIOR, protection = WARRIOR },
    PALADIN = {
        retribution = PALADIN_BASE,
        protection = { "p_bop", "p_bof", "p_cleanse", "p_bubble", "p_holystrike", "p_dummy" },
    },
    HUNTER = {
        beast_mastery = { "h_autoshot", "h_mark", "h_melee_bm" },
        marksmanship = { "h_autoshot", "h_mark", "h_melee_bm" },
        survival = { "h_autoshot", "h_mark", "h_melee_sv", "h_counter" },
    },
    ROGUE = { assassination = ROGUE, combat = ROGUE, subtlety = ROGUE },
    PRIEST = {
        shadow = { "pr_pws" },
        holy = HEALER_PRIEST,
        discipline = HEALER_PRIEST,
    },
    SHAMAN = {
        elemental = { "s_attack", "s_proj" },
        enhancement = { "s_attack", "s_storm", "s_proj" },
        restoration = { "s_attack", "s_proj", "s_ns" },
    },
    MAGE = { arcane = MAGE, fire = { "m_poly", "m_comb" }, frost = MAGE },
    WARLOCK = {
        affliction = { "l_pet", "l_amp", "l_drain", "l_dot" },
        demonology = { "l_pet", "l_fel_imp", "l_fel_suc" },
        destruction = { "l_pet", "l_havoc", "l_f_immo", "l_f_corr", "l_f_doom", "l_f_agony" },
    },
    DRUID = {
        balance = { "d_hurr", "d_moon" },
        feral = { "d_leap", "d_shift", "d_travel" },
        guardian = { "d_bear", "d_shift", "d_taunt", "d_travel" },
        restoration = { "d_ns", "d_travel" },
    },
}

-- list of macro definitions for a class/spec (can be empty)
function GF.macrosFor(class, specKey)
    local out = {}
    local ids = GF.MACROS[class] and GF.MACROS[class][specKey]
    for _, id in ipairs(ids or {}) do
        out[#out + 1] = D[id]
    end
    return out
end

local function doCreate(list)
    if InCombatLockdown and InCombatLockdown() then
        GF.say(T("In combattimento non si possono creare macro: riprova dopo."))
        return
    end
    local made, updated, skipped = 0, 0, 0
    for _, m in ipairs(list) do
        local idx = GetMacroIndexByName and GetMacroIndexByName(m.name) or 0
        if (not idx or idx == 0) and m.old then
            idx = GetMacroIndexByName(m.old) or 0 -- the macro of an earlier version: rename it
        end
        if idx and idx > 0 then
            if not pcall(EditMacro, idx, m.name, m.icon, m.body) then
                EditMacro(idx, m.name, nil, m.body)
            end
            updated = updated + 1
        else
            local _, numChar = GetNumMacros()
            if numChar < 18 then
                if not pcall(CreateMacro, m.name, m.icon or "INV_Misc_QuestionMark", m.body, true) then
                    CreateMacro(m.name, "INV_Misc_QuestionMark", m.body, true)
                end
                made = made + 1
            else
                skipped = skipped + 1
            end
        end
    end
    GF.say(Lf("Macro: %d create, %d aggiornate%s. Aprile con /macro e trascinale sulle barre.",
        made, updated, skipped > 0 and (", " .. Lf("%d non create (hai gia' 18 macro del personaggio)", skipped)) or ""))
end

-- asks for confirmation first
function GF.CreateMacros()
    local _, specKey, class = GF.specData()
    local list = GF.macrosFor(class, specKey)
    if #list == 0 then
        GF.say(T("Per questa spec non ci sono macro."))
        return
    end
    local names = {}
    for _, m in ipairs(list) do
        names[#names + 1] = m.name
    end
    StaticPopupDialogs["BUILDBEAST_MACROS"] = {
        text = T("BuildBeast creera' %s macro per il tuo personaggio:\n%s\n\nSe esistono gia' le aggiorna. Poi le trascini sulle barre."),
        button1 = T("Crea"),
        button2 = T("Annulla"),
        OnAccept = function(_, data)
            doCreate(data)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    local dialog = StaticPopup_Show("BUILDBEAST_MACROS", #list, table.concat(names, ", "))
    if dialog then
        dialog.data = list
    end
end
