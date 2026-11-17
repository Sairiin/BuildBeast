-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: the "Guida" tab, how to use and set up the addon, with the credit line. It gives the sections; the window
-- draws them as cards (Window.lua, fillGuide).

local ADDON, GF = ...
local T, Lf = GF.T, GF.L

local GOLD = "|cffffd100"
local GREEN = "|cff33ff33"
local WHITE = "|cffffffff"
local END = "|r"

-- list of sections: { head = title, grey = grey line, para = paragraph, cards = { text, ... } }
function GF.GuideSections()
    local function tab(name)
        return GOLD .. T(name) .. END
    end
    local function num(n)
        return WHITE .. n .. "." .. END
    end
    local bb = GREEN .. "/bb" .. END

    return {
        {
            head = T("BuildBeast: la guida per salire da 1 a 60"),
            grey = T("Realizzato da Sairiin."),
            para = T("BuildBeast ti dice, livello dopo livello, cosa fare con il tuo personaggio: quale talento prendere, quali abilita' ti arrivano, come usarle, quale oggetto indossare. Funziona con tutte le classi e tutte le spec."),
        },
        {
            head = T("Come si usa"),
            cards = {
                Lf("%s Apri la finestra con il pulsante sulla minimappa (clic sinistro) o con %s. Il clic destro apre le Opzioni.", num(1), bb),
                Lf("%s In alto scegli la tua spec. Quella che Hekili riconosce e' gia' selezionata; le spec senza guida dicono \"in arrivo\".", num(2)),
                Lf("%s Scheda %s: il talento da prendere ora, le abilita' nuove e come usarle. Con le frecce < > guardi i livelli vicini.", num(3), tab("Livello")),
                Lf("%s Scheda %s: tutto il piano dei 51 punti. Nel pannello dei talenti del gioco trovi i segni colorati: +N oro = punti da spendere, OK verde = a posto, Liv blu = il prossimo punto arriva a quel livello, X rosso = troppi punti.", num(4), tab("Talenti")),
                Lf("%s Scheda %s: come giocare a ogni fascia di livello. Se c'e' Hekili, i tasti giusti si illuminano sulle barre: oro = adesso, blu = il prossimo, grigio = in attesa.", num(5), tab("Rotazione")),
                Lf("%s Scheda %s: come valuto gli oggetti. Nel tooltip leggi SI, NO o SIMILE rispetto a quello che indossi, con il perche'; nelle borse compare una freccia verde, rossa o un trattino giallo.", num(6), tab("Oggetti")),
                Lf("%s Scheda %s: le macro utili per la tua spec. Un bottone le crea nel gioco, poi le trascini sulle barre.", num(7), tab("Macro")),
                Lf("%s Il riquadro piccolo sullo schermo ti ricorda il prossimo talento da prendere. In fondo alla finestra, + e - cambiano la dimensione del testo.", num(8)),
            },
        },
        {
            head = T("Configurazione consigliata"),
            cards = {
                Lf("- Installa %s (rotazione) e %s (oggetti e incantamenti): BuildBeast li completa e li traduce.", WHITE .. "Hekili" .. END, WHITE .. "GearQuest Forever" .. END),
                T("- Alla prima installazione BuildBeast imposta da solo le opzioni consigliate (per esempio toglie le righe ItemID e IconID dai tooltip). In Opzioni c'e' il bottone per rimettere tutto com'era."),
                T("- Se un altro addon disegna le sue frecce sulle icone della borsa, spegni le sue: due frecce sullo stesso oggetto si contraddicono."),
                T("- La soglia del parere (Opzioni, sezione Oggetti) decide quanto deve essere meglio un oggetto per dare SI o NO. Di base e' 1: alzala se vuoi vedere piu' SIMILE."),
                T("- I numeri dei cooldown sulle abilita' e l'illuminazione dei tasti si accendono e si spengono dalle Opzioni."),
                T("- La lingua si cambia dalle Opzioni (sezione Lingua)."),
            },
        },
        {
            head = T("Comandi"),
            cards = {
                Lf("%s  apre la finestra     %s  le opzioni     %s  questa pagina", bb, GREEN .. "/bb opzioni" .. END, GREEN .. "/bb guida" .. END),
                Lf("%s  cosa suggerisce Hekili     %s  controlla le icone", GREEN .. "/bb rot" .. END, GREEN .. "/bb icone" .. END),
            },
        },
    }
end
