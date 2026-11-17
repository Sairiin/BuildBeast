-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: the specs of every class (the addon is meant for all of them; the data is filled class by class).
-- hekili = the id Hekili uses for the spec: it lets us detect the spec you play, from Hekili's own detection.

local _, GF = ...
local function N(text)
    return text
end

GF.CLASS_LABEL = {
    WARRIOR = N("Guerriero"), PALADIN = N("Paladino"), HUNTER = N("Cacciatore"), ROGUE = N("Ladro"), PRIEST = N("Sacerdote"),
    SHAMAN = N("Sciamano"), MAGE = N("Mago"), WARLOCK = N("Stregone"), DRUID = N("Druido"),
}

GF.SPECS = {
    WARRIOR = { { "arms", "Arms", 100011 }, { "fury", "Fury", 100012 }, { "protection", "Protection", 100013 } },
    PALADIN = { { "holy", "Holy", 100021 }, { "protection", "Protection", 100022 }, { "retribution", "Retribution", 100023 } },
    HUNTER = { { "beast_mastery", "Beast Mastery", 100031 }, { "marksmanship", "Marksmanship", 100032 }, { "survival", "Survival", 100033 } },
    ROGUE = { { "assassination", "Assassination", 100041 }, { "combat", "Combat", 100042 }, { "subtlety", "Subtlety", 100043 } },
    PRIEST = { { "discipline", "Discipline", 100051 }, { "holy", "Holy", 100052 }, { "shadow", "Shadow", 100053 } },
    SHAMAN = { { "elemental", "Elemental", 100071 }, { "enhancement", "Enhancement", 100072 }, { "restoration", "Restoration", 100073 } },
    MAGE = { { "arcane", "Arcane", 100081 }, { "fire", "Fire", 100082 }, { "frost", "Frost", 100083 } },
    WARLOCK = { { "affliction", "Affliction", 100091 }, { "demonology", "Demonology", 100092 }, { "destruction", "Destruction", 100093 } },
    DRUID = { { "balance", "Balance", 100111 }, { "feral", "Feral", 100112 }, { "guardian", "Guardian", 100113 }, { "restoration", "Restoration", 100114 } },
}

-- the spec key Hekili is using right now for the player (nil when unknown)
local function hekiliSpecKey(class)
    local H = _G.Hekili
    local list = GF.SPECS[class]
    if not (H and list) then
        return nil
    end
    local ok, id = pcall(function()
        return H.Engine.Output.status.specID
    end)
    if not (ok and id) then
        return nil
    end
    for _, s in ipairs(list) do
        if s[3] == id then
            return s[1]
        end
    end
end

-- The spec the guide shows: the one chosen in the window for this class, else the one Hekili detects, else the first
-- spec that has data. Returns: data (nil when that spec has no guide yet), key, class.
function GF.specData()
    local class = GF.playerClass()
    local list = GF.SPECS[class]
    if not list then
        return nil, nil, class
    end
    local key = BuildBeastDB and BuildBeastDB.specChoice and BuildBeastDB.specChoice[class]
    if not key then
        key = hekiliSpecKey(class)
    end
    if not key then
        for _, s in ipairs(list) do
            if GF.DATA and GF.DATA[class] and GF.DATA[class][s[1]] then
                key = s[1]
                break
            end
        end
    end
    key = key or list[1][1]
    return GF.DATA and GF.DATA[class] and GF.DATA[class][key], key, class
end

function GF.specLabel(class, key)
    for _, s in ipairs(GF.SPECS[class] or {}) do
        if s[1] == key then
            return s[2]
        end
    end
    return tostring(key)
end

-- the player picks a spec in the window (nil: back to automatic)
function GF.ChooseSpec(key)
    local class = GF.playerClass()
    BuildBeastDB.specChoice = BuildBeastDB.specChoice or {}
    BuildBeastDB.specChoice[class] = key
    if GF.QueueTalentRefresh then
        GF.QueueTalentRefresh()
    end
    if GF.RefreshWindow then
        GF.RefreshWindow()
    end
end
