-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: the "Guida" tab, how to use and set up the addon, with the credit line.

local ADDON, GF = ...
local T, Lf = GF.T, GF.L

local GOLD = "|cffffd100"
local GREEN = "|cff33ff33"
local GREY = "|cff9aa5b8"
local WHITE = "|cffffffff"
local END = "|r"

function GF.GuideText()
    local L = {}
    local function head(s)
        L[#L + 1] = GOLD .. s .. END
    end
    local function line(s)
        L[#L + 1] = s
    end
    local function gap()
        L[#L + 1] = ""
    end
    local function tab(name)
        return GOLD .. T(name) .. END
    end
    local function num(n)
        return WHITE .. n .. "." .. END
    end
    local bb = GREEN .. "/bb" .. END

    head(T("BuildBeast: la guida per salire da 1 a 60"))
    line(GREY .. T("Realizzato da Sairiin.") .. END)
    gap()
    line(T("BuildBeast ti dice, livello dopo livello, cosa fare con il tuo personaggio: quale talento prendere, quali abilita' ti arrivano, come usarle, quale oggetto indossare. Funziona con tutte le classi e tutte le spec."))
    gap()

    head(T("Come si usa"))
    line(Lf("%s Apri la finestra con il pulsante sulla minimappa (clic sinistro) o con %s. Il clic destro apre le Opzioni.", num(1), bb))
    line(Lf("%s In alto scegli la tua spec. Quella che Hekili riconosce e' gia' selezionata; le spec senza guida dicono \"in arrivo\".", num(2)))
    line(Lf("%s Scheda %s: il talento da prendere ora, le abilita' nuove e come usarle. Con le frecce < > guardi i livelli vicini.", num(3), tab("Livello")))
    line(Lf("%s Scheda %s: tutto il piano dei 51 punti. Nel pannello dei talenti del gioco trovi i segni colorati: +N oro = punti da spendere, OK verde = a posto, Liv blu = il prossimo punto arriva a quel livello, X rosso = troppi punti.", num(4), tab("Talenti")))
    line(Lf("%s Scheda %s: come giocare a ogni fascia di livello. Se c'e' Hekili, i tasti giusti si illuminano sulle barre: oro = adesso, blu = il prossimo, grigio = in attesa.", num(5), tab("Rotazione")))
    line(Lf("%s Scheda %s: come valuto gli oggetti. Nel tooltip leggi SI, NO o SIMILE rispetto a quello che indossi, con il perche'; nelle borse compare una freccia verde, rossa o un trattino giallo.", num(6), tab("Oggetti")))
    line(Lf("%s Scheda %s: le macro utili per la tua spec. Un bottone le crea nel gioco, poi le trascini sulle barre.", num(7), tab("Macro")))
    line(Lf("%s Il riquadro piccolo sullo schermo ti ricorda il prossimo talento da prendere. In fondo alla finestra, + e - cambiano la dimensione di tutto.", num(8)))
    gap()

    head(T("Configurazione consigliata"))
    line(Lf("- Installa %s (rotazione) e %s (oggetti e incantamenti): BuildBeast li completa e li traduce.", WHITE .. "Hekili" .. END, WHITE .. "GearQuest Forever" .. END))
    line(T("- Alla prima installazione BuildBeast imposta da solo le opzioni consigliate (per esempio toglie le righe ItemID e IconID dai tooltip). In Opzioni c'e' il bottone per rimettere tutto com'era."))
    line(T("- Se un altro addon disegna le sue frecce sulle icone della borsa, spegni le sue: due frecce sullo stesso oggetto si contraddicono."))
    line(T("- La soglia del parere (Opzioni, sezione Oggetti) decide quanto deve essere meglio un oggetto per dare SI o NO. Di base e' 1: alzala se vuoi vedere piu' SIMILE."))
    line(T("- I numeri dei cooldown sulle abilita' e l'illuminazione dei tasti si accendono e si spengono dalle Opzioni."))
    line(T("- La lingua si cambia dalle Opzioni (sezione Lingua)."))
    gap()

    head(T("Comandi"))
    line(Lf("%s  apre la finestra     %s  le opzioni     %s  questa pagina", bb, GREEN .. "/bb opzioni" .. END, GREEN .. "/bb guida" .. END))
    line(Lf("%s  cosa suggerisce Hekili     %s  controlla le icone", GREEN .. "/bb rot" .. END, GREEN .. "/bb icone" .. END))
    gap()
    return table.concat(L, "\n")
end
