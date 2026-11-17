-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: the rotation. A custom Hekili priority (builtIn = false, a supported Hekili feature that Hekili never
-- replaces) made from the rotation of the guide, plus switches for Hekili's action bar glow.
-- Hekili already knows which abilities you have learned at each level (action.X.known), so one priority per spec serves
-- every level; the glow on the real action button is Hekili's own (Displays > Action Bar Glow).
-- Only criteria that Hekili's own wowsims priorities use, plus active_enemies and target.time_to_die.

local ADDON, GF = ...
local T, Lf = GF.T, GF.L
local function N(text)
    return text
end

local VERSION = 20261117002

local function E(action, criteria, offgcd)
    local e = { enabled = true, action = action }
    if criteria then
        e.criteria = criteria
    end
    if offgcd then
        e.use_off_gcd = 1
    end
    return e
end

local PACKS = {
    [100031] = {
        name = "BuildBeast - Beast Mastery",
        desc = N("Rotazione Beast Mastery della guida (livellamento 1-60): niente corpo a corpo; Hunter's Mark e Serpent Sting come apertura, falchi (Summon Hawk) dal 25, Aimed Shot e Arcane Shot, Multi-Shot ed Explosive Trap con piu' mostri. Cooldown (Bestial Wrath, Rapid Fire, razziali) fuori dalla rotazione, da usare a mano. Creata da BuildBeast."),
        precombat = {
            E("hunters_mark", "!debuff.hunters_mark.up"),
            E("aspect_of_the_hawk", "!buff.aspect_of_the_hawk.up"),
        },
        default = {
            -- Bestial Wrath, Rapid Fire and the racials stay out of the rotation (the guide: use them by hand on a
            -- dangerous pull); Hekili cannot tell a dangerous pull from an easy one on a fresh target.
            E("aspect_of_the_hawk", "!buff.aspect_of_the_hawk.up"),
            E("hunters_mark", "!debuff.hunters_mark.up"),
            E("explosive_trap", "active_enemies>=2"),
            E("multi_shot", "active_enemies>=2"),
            E("volley", "active_enemies>=4&target.time_to_die>20"),
            E("serpent_sting", "!debuff.serpent_sting.up&target.time_to_die>20"),
            E("summon_hawk", "window.hha.next.summon_hawk"),
            E("aimed_shot"),
            E("arcane_shot", "window.hha.next.arcane_shot"),
            E("arcane_shot", "!action.summon_hawk.known"),
        },
    },
}

local function copyList(l)
    local out = {}
    for i, e in ipairs(l) do
        local c = {}
        for k, v in pairs(e) do
            c[k] = v
        end
        out[i] = c
    end
    return out
end

-- Creates (or updates, when the version is newer) our priority of this spec in Hekili. Returns its name or nil.
local function ensurePack(spec)
    local H = _G.Hekili
    local def = spec and spec.hekili and PACKS[spec.hekili]
    if not (def and H and H.DB and H.DB.profile and type(H.DB.profile.packs) == "table") then
        return nil
    end
    local packs = H.DB.profile.packs
    local cur = rawget(packs, def.name)
    if type(cur) == "table" and (cur.version or 0) >= VERSION then
        return def.name
    end
    pcall(function()
        packs[def.name] = {
            builtIn = false,
            spec = spec.hekili,
            author = "BuildBeast",
            desc = T(def.desc),
            date = VERSION,
            version = VERSION,
            lists = { precombat = copyList(def.precombat), default = copyList(def.default) },
        }
        if type(H.EmbedPackOptions) == "function" then
            H:EmbedPackOptions()
        end
        if type(H.LoadScripts) == "function" then
            H:LoadScripts()
        end
    end)
    if rawget(packs, def.name) then
        return def.name
    end
    return nil
end

-- Create the priority and make Hekili use it for this spec. verbose: also tell when there is nothing to do.
function GF.InitRotation(verbose)
    if not verbose and BuildBeastDB and BuildBeastDB.rotation == false then
        return
    end
    local spec = GF.specData()
    local H = _G.Hekili
    if not (spec and spec.hekili) then
        if verbose then
            GF.say(T("per questa spec BuildBeast non ha ancora una rotazione sua: Hekili usa la sua."))
        end
        return
    end
    if not H then
        if verbose then
            GF.say(T("Hekili non e' caricato."))
        end
        return
    end
    -- the priority used to be called "Guida Livelli - ...": it goes away once ours is active
    local name = ensurePack(spec)
    if not name then
        GF.say("|cffff8800NO|r " .. T("non sono riuscito a creare la priorita' in Hekili."))
        return
    end
    local current
    pcall(function()
        current = H.Engine.settings.specs[spec.hekili].package
    end)
    local oldName = "Guida Livelli - " .. tostring(name):gsub("^BuildBeast %- ", "")
    if current == oldName then
        current = nil -- not a real original: ours, under the old name
    end
    if current == name then
        if verbose then
            GF.say("|cff00ff00OK|r " .. Lf("Hekili usa gia' la priorita': %s", name))
        end
        return
    end
    if current and current ~= name then
        BuildBeastDB.orig = BuildBeastDB.orig or {}
        BuildBeastDB.orig.hekili = BuildBeastDB.orig.hekili or {}
        if BuildBeastDB.orig.hekili[spec.hekili] == nil then
            BuildBeastDB.orig.hekili[spec.hekili] = current
        end
    end
    local ok, res = pcall(H.ActivatePack, H, spec.hekili, name)
    pcall(function()
        if rawget(H.DB.profile.packs, oldName) then
            H.DB.profile.packs[oldName] = nil
            if type(H.EmbedPackOptions) == "function" then
                H:EmbedPackOptions()
            end
        end
    end)
    if ok and res == true then
        GF.say("|cff00ff00OK|r " .. Lf("priorita' di Hekili impostata: %s", name))
    else
        GF.say("|cffff8800NO|r " .. T("Hekili non ha accettato la priorita'."))
    end
end

-- /bb rot: what Hekili suggests right now, by ability name
function GF.PrintRotation()
    local H = _G.Hekili
    local spec = GF.specData()
    if not H then
        GF.say(T("Hekili non e' caricato."))
        return
    end
    local ok, pkg = pcall(function()
        return H.Engine.settings.specs[spec.hekili].package
    end)
    GF.say("priorita' Hekili in uso: " .. tostring(ok and pkg or "?"))
    local shown = false
    pcall(function()
        for id, d in pairs(H.Engine.Output) do
            if type(d) == "table" and type(d.recs) == "table" and (d.count or 0) > 0 then
                local names = {}
                for i = 1, d.count do
                    local r = d.recs[i]
                    local label = tostring(r and r.actionName or "?")
                    -- when Hekili says it will be ready, and what the game says about the real cooldown
                    pcall(function()
                        local now = GetTime()
                        local delay = r.exact_time and (r.exact_time - now) or 0
                        local def = H.Engine.Registry.Abilities()[r.actionName]
                        local s, du = GF.spellCooldownRaw(def.id)
                        local left = 0
                        if type(s) == "number" and type(du) == "number" and s > 0 and du > 0 then
                            left = math.max(0, s + du - now)
                        end
                        label = label .. string.format("[Hekili tra %.1fs, gioco %s]", math.max(0, delay),
                            left > 0 and string.format("%.1fs", left) or "pronta")
                    end)
                    names[#names + 1] = label
                end
                GF.say("  " .. tostring(id) .. ": " .. table.concat(names, " > "))
                shown = true
            end
        end
    end)
    if not shown then
        GF.say("  Hekili non ha suggerimenti in questo momento (seleziona un bersaglio e riprova).")
    end
end

