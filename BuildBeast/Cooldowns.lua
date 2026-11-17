-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: the remaining cooldown as a number on each action button (own style), instead of the shading that
-- sweeps away. Colours: white, yellow under 5 s, red under 2 s; tenths of a second under 3 s.
-- It only reads the cooldown of the spell on the button and draws a number on top; the global cooldown (1.5 s) is ignored.
-- The shading of the buttons is hidden ONLY after the numbers have worked at least once (so you never end up with neither).
--   /bb cd on|off          the numbers
--   /bb cd swipe on|off    the shading: "on" shows it again, "off" hides it (default once the numbers work)
--   /bb cd test            what the game answers for the buttons (for diagnosis)

local ADDON, GF = ...
local T, Lf = GF.T, GF.L

local overlays = {}   -- button -> { frame, text }
local applied = {}    -- button -> "state" last applied to its cooldown frame
local working = false -- a number has been drawn at least once

local function numbersOn()
    return not (BuildBeastDB and BuildBeastDB.cd == false)
end

local function hideSwipe()
    return numbersOn() and working and not (BuildBeastDB and BuildBeastDB.swipe == true)
end

-- start, duration from whatever shape the client answers (a table, or the old multiple returns)
local function unpack_(a, b)
    if type(a) == "table" then
        return a.startTime or a.start, a.duration
    end
    return a, b
end

local function isSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

local function spellCooldown(id)
    if type(id) ~= "number" then
        return nil
    end
    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, a, b = pcall(C_Spell.GetSpellCooldown, id)
        if ok and a ~= nil then
            return unpack_(a, b)
        end
    end
    if GetSpellCooldown then
        local ok, a, b = pcall(GetSpellCooldown, id)
        if ok and a ~= nil then
            return unpack_(a, b)
        end
    end
end

local function slotCooldown(slot)
    if C_ActionBar and C_ActionBar.GetActionCooldown then
        local ok, a, b = pcall(C_ActionBar.GetActionCooldown, slot)
        if ok and a ~= nil then
            return unpack_(a, b)
        end
    end
    if GetActionCooldown then
        local ok, a, b = pcall(GetActionCooldown, slot)
        if ok and a ~= nil then
            return unpack_(a, b)
        end
    end
end

-- cooldown of what the button holds: its spell first (as Hekili reads it), then the slot itself
local function buttonCooldown(btn)
    local slot = GF.slotOf(btn)
    if not slot or slot == 0 then
        return nil
    end
    local t, id = GetActionInfo(slot)
    local start, dur
    if t == "spell" then
        start, dur = spellCooldown(id)
    elseif t == "macro" then
        local sp = spellCooldown(id)
        if sp == nil and GetMacroSpell then
            local m = GetMacroSpell(id)
            if type(m) == "number" then
                start, dur = spellCooldown(m)
            end
        else
            start, dur = spellCooldown(id)
        end
    end
    if start == nil then
        start, dur = slotCooldown(slot)
    end
    return start, dur
end

-- Seconds of REAL cooldown left on what the button holds (the 1.5 s global cooldown does not count); 0 when ready.
function GF.buttonRemaining(btn)
    local ok, r = pcall(function()
        local start, dur = buttonCooldown(btn)
        if isSecret(start) or isSecret(dur) then
            return 0
        end
        if type(start) == "number" and type(dur) == "number" and start > 0 and dur > 1.6 then
            return math.max(0, start + dur - GetTime())
        end
        return 0
    end)
    return ok and r or 0
end

-- The same for a spell id, and the raw answer (start, duration) for diagnosis.
function GF.spellCooldownRaw(id)
    return spellCooldown(id)
end

local function getOverlay(btn)
    local o = overlays[btn]
    if o then
        return o
    end
    local f = CreateFrame("Frame", nil, btn)
    f:SetAllPoints(btn)
    f:SetFrameLevel(btn:GetFrameLevel() + 12)
    f:EnableMouse(false)
    local t = f:CreateFontString(nil, "OVERLAY")
    local h = btn:GetHeight() or 40
    t:SetFont("Fonts\\FRIZQT__.TTF", math.max(12, math.min(24, math.floor(h * 0.42))), "OUTLINE")
    t:SetPoint("CENTER", f, "CENTER", 0, 0)
    o = { frame = f, text = t }
    overlays[btn] = o
    return o
end

local function format_(r)
    if r >= 60 then
        return string.format("%dm", math.ceil(r / 60))
    elseif r >= 3 then
        return string.format("%d", math.ceil(r))
    end
    return string.format("%.1f", r)
end

-- keeps the cooldown frame of a button in the state we want (swipe hidden or shown, Blizzard's own numbers hidden)
local function setCooldownLook(btn)
    local cd = btn.cooldown
    if not (cd and cd.SetDrawSwipe) then
        return
    end
    local want
    if not numbersOn() or not working then
        want = "default"
    else
        want = hideSwipe() and "ours-noswipe" or "ours-swipe"
    end
    if applied[btn] == want then
        return
    end
    applied[btn] = want
    pcall(cd.SetDrawSwipe, cd, want ~= "ours-noswipe")
    if cd.SetHideCountdownNumbers then
        pcall(cd.SetHideCountdownNumbers, cd, want ~= "default")
    end
end

local function update(btn)
    local o = overlays[btn]
    if not numbersOn() then
        if o then
            o.frame:Hide()
        end
        setCooldownLook(btn)
        return
    end
    local shown = false
    if btn:IsVisible() then
        local start, dur = buttonCooldown(btn)
        local ok, remaining = pcall(function()
            if isSecret(start) or isSecret(dur) then
                return nil
            end
            if type(start) == "number" and type(dur) == "number" and start > 0 and dur > 1.6 then
                return start + dur - GetTime()
            end
        end)
        if ok and remaining and remaining > 0 then
            o = getOverlay(btn)
            o.text:SetText(format_(remaining))
            if remaining < 2 then
                o.text:SetTextColor(1, 0.25, 0.2)
            elseif remaining < 5 then
                o.text:SetTextColor(1, 0.85, 0.2)
            else
                o.text:SetTextColor(1, 1, 1)
            end
            o.frame:Show()
            shown = true
            working = true
        end
    end
    if not shown and o then
        o.frame:Hide()
    end
    setCooldownLook(btn)
end

local function tick()
    GF.eachButton(update)
end

function GF.InitCooldowns()
    C_Timer.NewTicker(0.1, tick)
end

-- /bb cd test: raw answers of the client for the first buttons that hold a spell (cast one with a cooldown first)
local function describe(v)
    if type(v) == "table" then
        return "tabella(startTime=" .. tostring(v.startTime) .. " duration=" .. tostring(v.duration) .. ")"
    end
    return type(v) .. ":" .. tostring(v)
end

local function test()
    local n = 0
    GF.eachButton(function(b)
        if n >= 5 or not b:IsVisible() then
            return
        end
        local slot = GF.slotOf(b)
        if not slot or slot == 0 then
            return
        end
        local t, id = GetActionInfo(slot)
        if t ~= "spell" then
            return
        end
        n = n + 1
        local sc, ac, ga
        if C_Spell and C_Spell.GetSpellCooldown then
            local ok, a = pcall(C_Spell.GetSpellCooldown, id)
            sc = ok and describe(a) or "errore"
        else
            sc = "non esiste"
        end
        if C_ActionBar and C_ActionBar.GetActionCooldown then
            local ok, a = pcall(C_ActionBar.GetActionCooldown, slot)
            ac = ok and describe(a) or "errore"
        else
            ac = "non esiste"
        end
        if GetActionCooldown then
            local ok, a, d = pcall(GetActionCooldown, slot)
            ga = ok and (describe(a) .. " " .. describe(d)) or "errore"
        else
            ga = "non esiste"
        end
        GF.say("tasto " .. tostring(b:GetName()) .. " slot " .. slot .. " spell " .. tostring(id)
            .. " | C_Spell: " .. sc .. " | C_ActionBar: " .. ac .. " | GetActionCooldown: " .. ga
            .. " | cooldown frame: " .. tostring(b.cooldown ~= nil))
    end)
    if n == 0 then
        GF.say("nessun tasto con un incantesimo trovato.")
    end
    GF.say("numeri funzionanti finora: " .. tostring(working))
end

local function resetApplied()
    for btn in pairs(applied) do
        applied[btn] = nil
    end
end

function GF.SetCooldownNumbers(on)
    BuildBeastDB.cd = on and true or false
    resetApplied()
end

function GF.SetCooldownSwipeHidden(hidden)
    BuildBeastDB.swipe = not hidden
    resetApplied()
end

-- /bb cd on|off   and   /bb cd swipe on|off   and   /bb cd test
function GF.CooldownCommand(a, b)
    if a == "test" then
        test()
        return
    elseif a == "swipe" then
        BuildBeastDB.swipe = (b == "on")
        GF.say(T("ombreggiatura dei cooldown:") .. " " .. ((b == "on") and T("visibile") or T("nascosta")))
    elseif a == "on" or a == "off" then
        BuildBeastDB.cd = (a == "on")
        GF.say(T("numeri dei cooldown sui tasti:") .. " " .. ((a == "on") and T("accesi") or T("spenti")))
    else
        GF.say("usa |cff00ff00/bb cd on|off|r (numeri), |cff00ff00/bb cd swipe on|off|r (ombreggiatura), |cff00ff00/bb cd test|r (diagnosi).")
        return
    end
    for btn in pairs(applied) do
        applied[btn] = nil
    end
end
