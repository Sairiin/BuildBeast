-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: icons of talents and abilities for the window. Names in our data are the English ones; the icon comes from
-- (1) what we already saw (saved in the settings), (2) the talent tree of the class (public C_Traits API), (3) the list of
-- abilities Hekili keeps, (4) the game's spell info by name. Whatever is found is remembered, so it works after the first time.

local ADDON, GF = ...

local byName = {}   -- lower-case name -> texture
local hekiliLoaded = false
local names = nil   -- candidate names of the current spec: name -> true

local function norm(name)
    if type(name) ~= "string" then
        return nil
    end
    name = name:gsub("%s*%b()", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        return nil
    end
    return name:lower()
end

local function put(name, tex)
    local k = norm(name)
    if k and tex and not byName[k] then
        byName[k] = tex
    end
end

-- called by Talents.lua with what the talent buttons show: the most reliable source
function GF.RememberIcon(name, tex)
    local k = norm(name)
    if not (k and tex) then
        return
    end
    byName[k] = tex
    if BuildBeastDB then
        BuildBeastDB.icons = BuildBeastDB.icons or {}
        BuildBeastDB.icons[k] = tex
    end
end

local function spellTexture(spellID)
    if not spellID then
        return nil
    end
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, t = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and t then
            return t
        end
    end
    return nil
end

-- the whole talent tree of the class, without opening the talent window
function GF.ScanTalentIcons()
    pcall(function()
        local cfg = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
        if not (cfg and C_Traits) then
            return
        end
        local info = C_Traits.GetConfigInfo(cfg)
        local tree = info and info.treeIDs and info.treeIDs[1]
        if not tree then
            return
        end
        for _, nodeID in ipairs(C_Traits.GetTreeNodes(tree) or {}) do
            local n = C_Traits.GetNodeInfo(cfg, nodeID)
            for _, entryID in ipairs(n and n.entryIDs or {}) do
                local e = C_Traits.GetEntryInfo(cfg, entryID)
                local def = e and e.definitionID and C_Traits.GetDefinitionInfo(e.definitionID)
                if def then
                    local sid = def.spellID
                    local name = def.overrideName
                    if not name and sid and C_Spell and C_Spell.GetSpellName then
                        name = C_Spell.GetSpellName(sid)
                    end
                    put(name, def.overrideIcon or spellTexture(sid))
                end
            end
        end
    end)
end

local function loadHekili()
    if hekiliLoaded then
        return
    end
    local H = _G.Hekili
    local list = H and H.Class and H.Class.abilities
    if type(list) ~= "table" then
        return
    end
    hekiliLoaded = true
    pcall(function()
        for _, a in pairs(list) do
            if type(a) == "table" and type(a.name) == "string" then
                put(a.name, spellTexture(a.id) or a.texture)
            end
        end
    end)
end

-- icon of an ability or talent by its (English) name; nil when unknown
function GF.IconFor(name)
    local k = norm(name)
    if not k then
        return nil
    end
    local saved = BuildBeastDB and BuildBeastDB.icons and BuildBeastDB.icons[k]
    if saved then
        return saved
    end
    if byName[k] then
        return byName[k]
    end
    loadHekili()
    if byName[k] then
        return byName[k]
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, (name:gsub("%s*%b()", "")))
        if ok and type(info) == "table" and info.iconID then
            byName[k] = info.iconID
            return info.iconID
        end
    end
    return nil
end

function GF.IconTag(name, size)
    local tex = GF.IconFor(name)
    if not tex then
        return ""
    end
    return "|T" .. tostring(tex) .. ":" .. (size or 16) .. ":" .. (size or 16) .. ":0:0|t "
end

-- the pieces of a "spells" text ("Wrath, Healing Touch; missione: Stoneskin Totem") as clean names
function GF.SplitSpells(text)
    local out = {}
    for piece in tostring(text or ""):gmatch("[^,;]+") do
        piece = piece:gsub("^%s+", ""):gsub("%s+$", "")
        piece = piece:match(":%s*(.+)$") or piece
        piece = piece:gsub("^e%s+", "")
        if piece ~= "" then
            out[#out + 1] = piece
        end
    end
    return out
end

-- names of abilities and talents of a spec that can be mentioned in its texts
local function candidates(spec)
    local set = {}
    for _, text in pairs(spec.spells or {}) do
        for _, n in ipairs(GF.SplitSpells(text)) do
            local clean = n:gsub("%s*%b()", "")
            set[clean] = true
        end
    end
    for _, run in ipairs(spec.talentRuns or {}) do
        set[run[3]] = true
    end
    local H = _G.Hekili
    local list = H and H.Class and H.Class.abilities
    if type(list) == "table" then
        for _, a in pairs(list) do
            if type(a) == "table" and type(a.name) == "string" and #a.name > 4 then
                set[a.name] = true
            end
        end
    end
    return set
end

local cache = {}
-- icons of the abilities named in a text (in order of appearance, at most `max`), as a string of texture tags
function GF.IconsInText(spec, text, size, max)
    cache[spec] = cache[spec] or candidates(spec)
    local found = {}
    for name in pairs(cache[spec]) do
        local from = 1
        while true do
            local a, b = text:find(name, from, true)
            if not a then
                break
            end
            local before = a > 1 and text:sub(a - 1, a - 1) or " "
            local after = b < #text and text:sub(b + 1, b + 1) or " "
            if not before:match("%a") and not after:match("%a") then
                if not found[name] or a < found[name] then
                    found[name] = a
                end
                break
            end
            from = b + 1
        end
    end
    local list = {}
    for name, pos in pairs(found) do
        if GF.IconFor(name) then
            list[#list + 1] = { name, pos }
        end
    end
    table.sort(list, function(x, y)
        return x[2] < y[2]
    end)
    local out = {}
    for i, e in ipairs(list) do
        if i > (max or 8) then
            break
        end
        out[#out + 1] = GF.IconTag(e[1], size or 20):gsub(" $", "")
    end
    return table.concat(out, " ")
end

-- /bb icone: how many names we can draw
function GF.IconsReport()
    GF.ScanTalentIcons()
    local spec = GF.specData()
    if not spec then
        GF.say("icone: nessuna guida per questa spec.")
        return
    end
    local have, miss = 0, {}
    for _, run in ipairs(spec.talentRuns or {}) do
        if GF.IconFor(run[3]) then
            have = have + 1
        else
            miss[#miss + 1] = run[3]
        end
    end
    GF.say("icone dei talenti: " .. have .. " trovate, " .. #miss .. " no" .. (#miss > 0 and (" (" .. table.concat(miss, ", ") .. ")") or "") .. ".")
end
