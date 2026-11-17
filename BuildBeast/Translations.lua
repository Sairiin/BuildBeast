-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: carries the Italian translations of Hekili and GearQuest (Translations_Data.lua) and applies them at
-- login, so an update of those addons cannot erase them any more. Each can be switched off in the options
-- (a /reload applies the change).
-- Honest limits: GearQuest reads its texts when it needs them, so the translation reaches its tooltips and windows;
-- Hekili may have built a few texts before we run, those stay English until the next login. If something is wrong,
-- switch the translation off: nothing is written in the other addons.

local ADDON, GF = ...

local status = { hekili = "non applicata", gq = "non applicata" }

function GF.TranslationStatus()
    return status
end

local function short(err)
    return tostring(err):gsub("%s+", " "):sub(1, 90)
end

function GF.ApplyTranslations()
    local tr = GF.TR
    if not tr then
        return
    end

    -- Hekili: its own itIT file did a rawset on its AceLocale table; the same file runs from here
    if BuildBeastDB.trHekili == false then
        status.hekili = "spenta"
    elseif not _G.Hekili then
        status.hekili = "Hekili non trovato"
    else
        local loc = GetLocale and GetLocale() or "enUS"
        if loc ~= "enUS" and loc ~= "enGB" then
            status.hekili = "non serve (il gioco non e' in inglese)"
        else
            local ok, err = pcall(tr.hekili)
            status.hekili = ok and "applicata" or ("errore: " .. short(err))
        end
    end

    -- GearQuest: its language packs fill GQ.L (and the phrase rules and sentences) only when GQ.ActiveLocale matches
    -- their language, so the files run with it set to itIT; if one fails the previous values come back.
    local GQ = _G.GearQuest
    if BuildBeastDB.trGQ == false then
        status.gq = "spenta"
    elseif not GQ then
        status.gq = "GearQuest non trovato"
    elseif GQ.ActiveLocale == "itIT" then
        status.gq = "gia' in italiano (file dell'addon)"
    else
        local oldActive, oldFlag = GQ.ActiveLocale, GQ.LocaleActive
        GQ.ActiveLocale, GQ.LocaleActive = "itIT", true
        local failed, partial
        local ok, err = pcall(tr.gq_ui)
        if not ok then
            failed = short(err)
        end
        -- the phrase rules and the sentences use the rule engine (Rules.lua) that lives in GearQuest's language addon,
        -- loaded on demand: load it now (its own language files do nothing, none of them is itIT)
        if not failed and not GQ.AddPhraseRules then
            local name = GQ.LOCALE_ADDON or "GearQuestForever_Languages"
            pcall(function()
                if C_AddOns and C_AddOns.LoadAddOn then
                    C_AddOns.LoadAddOn(name)
                elseif LoadAddOn then
                    LoadAddOn(name)
                end
            end)
        end
        if not failed then
            if GQ.AddPhraseRules then
                for _, key in ipairs({ "gq_rules", "gq_sentences" }) do
                    local ok2, err2 = pcall(tr[key])
                    if not ok2 and not failed then
                        failed = short(err2)
                    end
                end
            else
                partial = true
            end
        end
        if failed then
            GQ.ActiveLocale, GQ.LocaleActive = oldActive, oldFlag
            status.gq = "errore: " .. failed
        elseif partial then
            status.gq = "applicata in parte (le frasi delle missioni no: manca l'addon delle lingue di GearQuest)"
        else
            status.gq = "applicata"
        end
    end
end
