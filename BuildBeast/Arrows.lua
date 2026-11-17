-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: our own upgrade arrow on the item icons of the bags, following our verdict:
--   green arrow up = SI, red arrow down = NO, small yellow dash = SIMILE, nothing = not an item we judge.
-- It is written on the game's public item button interface only: a button that answers GetBagID() and GetID() (the
-- standard ItemButton of any bag window) tells which bag and slot it shows, and C_Container tells the item there.
-- We do not know or use the inner workings of any other addon. If a bag window does not answer that way, no arrow is
-- drawn there (/bb frames shows what a button under the mouse answers).
-- Other addons' own arrows can be switched off in their own options: two arrows on one icon would contradict each other.

local ADDON, GF = ...

local overlays = {}
local queued = false

local function on()
    return not (BuildBeastDB and BuildBeastDB.arrows == false)
end

local function getOverlay(btn)
    local o = overlays[btn]
    if o then
        return o
    end
    o = CreateFrame("Frame", nil, btn)
    o:SetAllPoints(btn)
    o:SetFrameLevel(btn:GetFrameLevel() + 15)
    o:EnableMouse(false)
    local hasAtlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("bags-greenarrow")
    o.up = o:CreateTexture(nil, "OVERLAY")
    o.up:SetSize(15, 15)
    o.up:SetPoint("TOPRIGHT", -1, -1)
    o.down = o:CreateTexture(nil, "OVERLAY")
    o.down:SetSize(15, 15)
    o.down:SetPoint("TOPRIGHT", -1, -1)
    if hasAtlas then
        o.up:SetAtlas("bags-greenarrow")
        o.down:SetAtlas("bags-greenarrow")
    else
        o.up:SetTexture("Interface\\Buttons\\UI-MicroStream-Green")
        o.down:SetTexture("Interface\\Buttons\\UI-MicroStream-Green")
    end
    o.down:SetRotation(math.pi)
    o.down:SetDesaturated(true)
    o.down:SetVertexColor(1, 0.25, 0.2)
    o.same = o:CreateTexture(nil, "OVERLAY")
    o.same:SetSize(10, 4)
    o.same:SetPoint("TOPRIGHT", -3, -5)
    o.same:SetColorTexture(1, 0.85, 0.2, 1)
    overlays[btn] = o
    return o
end

-- the item a bag button shows, through the standard item button interface
local function itemLinkOf(btn)
    if type(btn.GetBagID) ~= "function" then
        return nil
    end
    local ok, bag = pcall(btn.GetBagID, btn)
    if not ok or type(bag) ~= "number" then
        return nil
    end
    local slot = btn:GetID()
    if not slot or slot <= 0 then
        return nil
    end
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot), bag, slot
    elseif GetContainerItemLink then
        return GetContainerItemLink(bag, slot), bag, slot
    end
end

local function show(o, verdict)
    o.up:SetShown(verdict == "SI")
    o.down:SetShown(verdict == "NO")
    o.same:SetShown(verdict == "SIMILE")
    o:SetShown(verdict ~= nil)
end

local function scan()
    queued = false
    if not on() or not GF.VerdictOf then
        for _, o in pairs(overlays) do
            o:Hide()
        end
        return
    end
    local active = {}
    local f = EnumerateFrames()
    while f do
        if type(f.GetBagID) == "function" and f:IsShown() then
            local link = itemLinkOf(f)
            if link then
                active[f] = link
            end
        end
        f = EnumerateFrames(f)
    end
    for btn, o in pairs(overlays) do
        if not active[btn] then
            o:Hide()
        end
    end
    for btn, link in pairs(active) do
        local verdict = GF.VerdictOf(link)
        if verdict then
            show(getOverlay(btn), verdict)
        elseif overlays[btn] then
            overlays[btn]:Hide()
        end
    end
end

local function queue()
    if queued then
        return
    end
    queued = true
    C_Timer.After(0.3, function()
        pcall(scan)
    end)
end

function GF.InitArrows()
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "ITEM_LOCK_CHANGED", "PLAYER_LEVEL_UP",
        "BAG_NEW_ITEMS_UPDATED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", queue)
    C_Timer.NewTicker(2, function()
        pcall(scan)
    end)
end

function GF.SetArrows(on_)
    BuildBeastDB.arrows = on_ and true or false
    queue()
end

-- /bb frames: what the button under the mouse answers (for diagnosis)
function GF.DebugFrames()
    local f
    if GetMouseFoci then
        f = GetMouseFoci()[1]
    elseif GetMouseFocus then
        f = GetMouseFocus()
    end
    if not f then
        GF.say("nessun elemento sotto il mouse.")
        return
    end
    for i = 1, 4 do
        if not f then
            break
        end
        local name = f.GetName and f:GetName() or "(senza nome)"
        local kind = f.GetObjectType and f:GetObjectType() or "?"
        local bag, id, link = "-", "-", "-"
        if type(f.GetBagID) == "function" then
            local ok, b = pcall(f.GetBagID, f)
            bag = ok and tostring(b) or "errore"
            id = tostring(f:GetID())
            local l = itemLinkOf(f)
            link = l and l:match("%[(.-)%]") or "nessuno"
        end
        GF.say(string.format("livello %d: %s (%s)  GetBagID=%s  GetID=%s  oggetto=%s", i, tostring(name), kind, bag, id, link))
        f = f.GetParent and f:GetParent() or nil
    end
end
