-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: talent hints on Blizzard's talent window, in our own style.
-- On every talent button we draw a coloured frame and a small badge:
--   gold  "+N"  : the plan wants N more points in this talent at your level
--   green "OK"  : this talent has all the points the plan wants (at its final rank)
--   blue  "Liv 23" : the next point of this talent comes at that level (nothing to do yet)
--   red   "X"   : you have more points here than the plan ever wants
-- It only reads the talent window and draws on top of it; it never spends points.
-- The talent window is found through PlayerSpellsFrame.TalentsFrame (the same frame Zygor uses in WoW Forever).

local ADDON, GF = ...
local T, Lf = GF.T, GF.L

local COL = {
    need = { 1, 0.82, 0 },
    ok = { 0.25, 0.9, 0.35 },
    later = { 0.55, 0.65, 0.85 },
    bad = { 1, 0.25, 0.2 },
}

local marks = {}
local refreshQueued = false
local hooked = false

local function talentFrame()
    local p = _G.PlayerSpellsFrame
    return p and p.TalentsFrame
end

-- (tree, row, column) of a talent node from its position: the trees start at x = 1020, 5020 and 9080, the grid step is 600.
local function cellKey(info)
    local x, y = info.posX, info.posY
    if not (x and y) then
        return nil
    end
    local tree = (x < 4000) and 0 or ((x < 8000) and 1 or 2)
    local base = (tree == 0 and 1020) or (tree == 1 and 5020) or 9080
    local col = math.floor((x - base) / 600 + 0.5)
    local row = math.floor((y - 2130) / 600 + 0.5)
    return tree .. "," .. row .. "," .. col
end

local function newMark(btn)
    local m = CreateFrame("Frame", nil, btn)
    m:SetAllPoints(btn)
    m:SetFrameLevel(btn:GetFrameLevel() + 6)
    m.edges = {}
    local function edge(p1, x1, y1, p2, x2, y2, w, h)
        local t = m:CreateTexture(nil, "OVERLAY")
        t:SetPoint(p1, m, p1, x1, y1)
        t:SetPoint(p2, m, p2, x2, y2)
        if w then
            t:SetWidth(w)
        end
        if h then
            t:SetHeight(h)
        end
        m.edges[#m.edges + 1] = t
    end
    edge("TOPLEFT", -2, 2, "TOPRIGHT", 2, 2, nil, 2)
    edge("BOTTOMLEFT", -2, -2, "BOTTOMRIGHT", 2, -2, nil, 2)
    edge("TOPLEFT", -2, 2, "BOTTOMLEFT", -2, -2, 2, nil)
    edge("TOPRIGHT", 2, 2, "BOTTOMRIGHT", 2, -2, 2, nil)
    -- the badge sits under the icon (there is room between the rows), big and with an outline so it reads well
    m.bg = m:CreateTexture(nil, "ARTWORK")
    m.bg:SetColorTexture(0, 0, 0, 0.88)
    m.text = m:CreateFontString(nil, "OVERLAY")
    m.text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    m.text:SetPoint("TOP", m, "BOTTOM", 0, -3)
    m.bg:SetPoint("TOPLEFT", m.text, "TOPLEFT", -5, 3)
    m.bg:SetPoint("BOTTOMRIGHT", m.text, "BOTTOMRIGHT", 5, -3)
    return m
end

local function paint(m, color, text, border)
    for _, t in ipairs(m.edges) do
        if border then
            t:SetColorTexture(color[1], color[2], color[3], 1)
            t:Show()
        else
            t:Hide()
        end
    end
    m.text:SetText(text or "")
    m.text:SetTextColor(color[1], color[2], color[3])
    if text and text ~= "" then
        m.bg:Show()
    else
        m.bg:Hide()
    end
    m:Show()
end

function GF.RefreshTalents()
    refreshQueued = false
    local frame = talentFrame()
    local buttons = frame and frame.nodeIDToButton
    if not (frame and frame:IsShown() and buttons) then
        return
    end
    for _, m in pairs(marks) do
        m:Hide()
    end
    if BuildBeastDB and BuildBeastDB.marks == false then
        return
    end
    local spec, _, class = GF.specData()
    local cells = BuildBeastCells and BuildBeastCells[class]
    if not (spec and cells) then
        return
    end
    local level = UnitLevel("player") or 1
    local target = GF.ranksAt(spec, level)
    local final = GF.ranksAt(spec, 60)
    local configID = frame.configurationInfo and frame.configurationInfo.ID
    for nodeID, btn in pairs(buttons) do
        local info = btn.nodeInfo
        if configID and C_Traits and C_Traits.GetNodeInfo then
            local ok, fresh = pcall(C_Traits.GetNodeInfo, configID, nodeID)
            if ok and type(fresh) == "table" and fresh.ID then
                info = fresh
            end
        end
        local key = info and cellKey(info)
        local name = key and cells[key]
        if name then
            local tex = (btn.Icon and btn.Icon.GetTexture and btn.Icon:GetTexture())
                or (btn.icon and btn.icon.GetTexture and btn.icon:GetTexture())
            if tex and GF.RememberIcon then
                GF.RememberIcon(name, tex)
            end
            local rank = (info.activeEntry and info.activeEntry.rank) or info.activeRank or 0
            local want, fin = target[name] or 0, final[name] or 0
            local m = marks[btn]
            if not m then
                m = newMark(btn)
                marks[btn] = m
            end
            if rank > fin then
                paint(m, COL.bad, "X", true)
            elseif want > rank then
                paint(m, COL.need, "+" .. (want - rank), true)
            elseif rank < fin then
                paint(m, COL.later, "Liv " .. tostring(GF.nextLevelFor(spec, name, rank) or "?"), false)
            elseif fin > 0 then
                paint(m, COL.ok, "OK", true)
            elseif marks[btn] then
                marks[btn]:Hide()
            end
        end
    end
end

function GF.QueueTalentRefresh()
    if refreshQueued then
        return
    end
    refreshQueued = true
    C_Timer.After(0.15, GF.RefreshTalents)
end

local function tryHook()
    if hooked then
        return true
    end
    local f = talentFrame()
    if f and f.HookScript then
        hooked = true
        f:HookScript("OnShow", GF.QueueTalentRefresh)
        return true
    end
    return false
end

function GF.InitTalents()
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "TRAIT_CONFIG_UPDATED", "TRAIT_TREE_CURRENCY_INFO_UPDATED", "TRAIT_NODE_CHANGED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", GF.QueueTalentRefresh)
    -- The talent window is loaded on demand and builds its buttons a moment after it is shown, so the first opening
    -- can be missed by a hook. A small watcher (twice a second, 52 buttons to count) draws the marks as soon as the
    -- window is shown and its buttons exist, and again whenever the buttons change.
    local wasShown, lastCount, shownTicks = false, 0, 0
    C_Timer.NewTicker(0.5, function()
        tryHook()
        local f = talentFrame()
        if not f then
            return
        end
        local shown = f:IsShown() and true or false
        if not shown then
            wasShown, shownTicks = false, 0
            return
        end
        local n = 0
        for _ in pairs(f.nodeIDToButton or {}) do
            n = n + 1
        end
        shownTicks = shownTicks + 1
        if not wasShown or n ~= lastCount or shownTicks == 2 or shownTicks == 4 then
            GF.RefreshTalents()
        end
        wasShown, lastCount = true, n
    end)
end

-- /bb dump: how many nodes of the talent window got a name from our map (open the talent window first)
function GF.DumpTalents()
    local frame = talentFrame()
    if not (frame and frame.nodeIDToButton) then
        GF.say("apri prima il pannello dei talenti, poi scrivi di nuovo /bb dump")
        return
    end
    local _, _, class = GF.specData()
    local cells = BuildBeastCells and BuildBeastCells[class]
    local n, named, lines = 0, 0, {}
    for nodeID, btn in pairs(frame.nodeIDToButton) do
        local info = btn.nodeInfo
        n = n + 1
        local key = info and cellKey(info)
        if key and cells and cells[key] then
            named = named + 1
        else
            lines[#lines + 1] = tostring(nodeID) .. " x=" .. tostring(info and info.posX) .. " y=" .. tostring(info and info.posY)
        end
    end
    GF.say("nodi nel pannello: " .. n .. ", riconosciuti: " .. named)
    for i = 1, math.min(#lines, 10) do
        GF.say("  non riconosciuto: " .. lines[i])
    end
end

-- /bb zygor on|off: Zygor draws its own marks on the same buttons; this switches them off so they do not overlap
function GF.SetTalentMarks(on)
    BuildBeastDB.marks = on and true or false
    GF.QueueTalentRefresh()
end

function GF.SetZygorTalentIcons(on, quiet, fromBase)
    local zgv = _G.ZGV
    if not (zgv and zgv.db and zgv.db.profile) then
        if not fromBase then
            GF.say(T("Zygor non e' pronto."))
        end
        return
    end
    -- what Zygor had before we touched it, kept once so "ripristina" can put it back
    BuildBeastDB.orig = BuildBeastDB.orig or {}
    if BuildBeastDB.orig.zygorIcons == nil then
        BuildBeastDB.orig.zygorIcons = (zgv.db.profile.ta_toggle_icons ~= false)
    end
    if not fromBase then
        BuildBeastDB.zygorIcons = on and true or false
    end
    zgv.db.profile.ta_toggle_icons = on and true or false
    pcall(function()
        local TA = zgv.TalentAdvisor
        if TA and TA.Initialised and TA.Toggle then
            TA:Toggle(zgv.db.profile.ta_toggle_icons)
        end
    end)
    if not quiet then
        GF.say(T("segni dei talenti di Zygor:") .. " " .. (on and T("accesi") or T("spenti")) .. ". " .. T("Riapri il pannello dei talenti."))
    end
end
