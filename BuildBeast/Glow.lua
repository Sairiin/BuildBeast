-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: the glow on the action buttons, in our own style (a pulsing frame; gold = cast now, blue = next).
-- It follows what Hekili suggests (Hekili.Engine.Output.Primary: the first and second recommendation) and lights the
-- buttons whose spell has the same name. Works on EllesmereUI's action buttons (EABButton<slot>) and on Blizzard's bars;
-- Hekili's own bar glow does not know EllesmereUI's buttons, and it only glows in combat by default.
-- Reading only: we draw a frame on top of the button, nothing is changed on the button itself.

local ADDON, GF = ...
local T, Lf = GF.T, GF.L

local COL_NOW = { 1, 0.82, 0 }
local COL_NEXT = { 0.3, 0.6, 1 }
local COL_WAIT = { 0.7, 0.7, 0.7 }

local frames = {}   -- button -> our glow frame
local lit = {}      -- buttons lit now
local lastNow, lastNext
local dirty = true

function GF.glowOn()
    return not (BuildBeastDB and BuildBeastDB.glow == false)
end

local function spellName(id)
    if type(id) ~= "number" then
        return nil
    end
    local name
    if C_Spell and C_Spell.GetSpellName then
        local ok, n = pcall(C_Spell.GetSpellName, id)
        if ok then
            name = n
        end
    end
    if not name and GetSpellInfo then
        local ok, n = pcall(GetSpellInfo, id)
        if ok then
            name = n
        end
    end
    return name
end

local function eachButton(fn)
    for i = 1, 180 do
        local b = _G["EABButton" .. i]
        if b then
            fn(b)
        end
    end
    for _, prefix in ipairs({ "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton" }) do
        for i = 1, 12 do
            local b = _G[prefix .. i]
            if b then
                fn(b)
            end
        end
    end
end

local function slotOf(b)
    local s = b._state_action
    if type(s) ~= "number" then
        s = b.action
    end
    if type(s) ~= "number" and b.GetAttribute then
        s = tonumber(b:GetAttribute("action"))
    end
    return s
end

GF.eachButton = eachButton
GF.slotOf = slotOf

-- name of the spell the button casts (a macro answers its spell when it has one)
local function buttonSpellName(b)
    local slot = slotOf(b)
    if not slot or slot == 0 then
        return nil
    end
    local t, id = GetActionInfo(slot)
    if t == "spell" then
        return spellName(id)
    elseif t == "macro" then
        local name = spellName(id)
        if name then
            return name
        end
        if GetMacroSpell then
            local sp = GetMacroSpell(id)
            if type(sp) == "number" then
                return spellName(sp)
            end
            return sp
        end
    end
end

local function getFrame(btn)
    local g = frames[btn]
    if g then
        return g
    end
    g = CreateFrame("Frame", nil, btn)
    g:SetAllPoints(btn)
    g:SetFrameLevel(btn:GetFrameLevel() + 10)
    g:EnableMouse(false)
    g.edges = {}
    local function edge(p1, x1, y1, p2, x2, y2, w, h)
        local t = g:CreateTexture(nil, "OVERLAY")
        t:SetPoint(p1, g, p1, x1, y1)
        t:SetPoint(p2, g, p2, x2, y2)
        if w then
            t:SetWidth(w)
        end
        if h then
            t:SetHeight(h)
        end
        g.edges[#g.edges + 1] = t
    end
    edge("TOPLEFT", -3, 3, "TOPRIGHT", 3, 3, nil, 3)
    edge("BOTTOMLEFT", -3, -3, "BOTTOMRIGHT", 3, -3, nil, 3)
    edge("TOPLEFT", -3, 3, "BOTTOMLEFT", -3, -3, 3, nil)
    edge("TOPRIGHT", 3, 3, "BOTTOMRIGHT", 3, -3, 3, nil)
    g.anim = g:CreateAnimationGroup()
    local a = g.anim:CreateAnimation("Alpha")
    a:SetFromAlpha(1)
    a:SetToAlpha(0.35)
    a:SetDuration(0.45)
    g.anim:SetLooping("BOUNCE")
    g:Hide()
    frames[btn] = g
    return g
end

local function setColor(g, color)
    if g.col == color then
        return
    end
    g.col = color
    for _, t in ipairs(g.edges) do
        t:SetColorTexture(color[1], color[2], color[3], 1)
    end
end

local function lightOn(btn, color, role)
    local g = getFrame(btn)
    g.col = nil
    setColor(g, color)
    g:Show()
    g.anim:Play()
    lit[btn] = role
end

-- Hekili names the ability before it is ready (it plans ahead): while the game still shows a real cooldown on the
-- button, the glow is grey ("wait"); when it is ready it turns gold (now) or blue (next).
local function recolor()
    for b, role in pairs(lit) do
        local g = frames[b]
        if g then
            local rem = GF.buttonRemaining and GF.buttonRemaining(b) or 0
            if rem > 0.3 then
                setColor(g, COL_WAIT)
            else
                setColor(g, role == "now" and COL_NOW or COL_NEXT)
            end
        end
    end
end

local function clearAll()
    for b in pairs(lit) do
        local g = frames[b]
        if g then
            g.anim:Stop()
            g:Hide()
        end
        lit[b] = nil
    end
end

local function abilityName(H, key)
    if not key then
        return nil
    end
    local ok, abilities = pcall(H.Engine.Registry.Abilities)
    local def = ok and abilities and abilities[key]
    if type(def) ~= "table" then
        return nil
    end
    return def.actualName or def.name
end

local function paint(H, key, color, role)
    local name = abilityName(H, key)
    if not name then
        return
    end
    eachButton(function(b)
        if not lit[b] and b:IsVisible() and buttonSpellName(b) == name then
            lightOn(b, color, role)
        end
    end)
end

local function tick()
    if not GF.glowOn() then
        if next(lit) then
            clearAll()
            lastNow, lastNext = nil, nil
        end
        return
    end
    local H = _G.Hekili
    local out = H and H.Engine and H.Engine.Output and H.Engine.Output.Primary
    local nowKey, nextKey
    if type(out) == "table" and (out.count or 0) > 0 and out.recs then
        nowKey = out.recs[1] and out.recs[1].actionName
        nextKey = (out.count > 1 and out.recs[2]) and out.recs[2].actionName or nil
        if nextKey == nowKey then
            nextKey = nil
        end
    end
    if nowKey == lastNow and nextKey == lastNext and not dirty then
        recolor()
        return
    end
    lastNow, lastNext, dirty = nowKey, nextKey, false
    clearAll()
    if H and nowKey then
        paint(H, nowKey, COL_NOW, "now")
        paint(H, nextKey, COL_NEXT, "next")
        recolor()
    end
end

function GF.InitGlow()
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR",
        "UPDATE_SHAPESHIFT_FORM", "PLAYER_ENTERING_WORLD" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function()
        dirty = true
    end)
    C_Timer.NewTicker(0.1, tick)
    -- the buttons can move without an event we know: look again every few seconds
    C_Timer.NewTicker(3, function()
        dirty = true
    end)
end

-- /bb glow on|off
function GF.SetBarGlow(on, quiet)
    BuildBeastDB.glow = on and true or false
    if not on then
        clearAll()
        lastNow, lastNext = nil, nil
    end
    dirty = true
    if not quiet then
        GF.say(T("illuminazione dei tasti:") .. " " .. (on and T("accesa") or T("spenta")) .. ". " .. T("Oro = da usare ora, blu = la prossima."))
    end
end
