-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: an opinion on every item you look at ("yes / no / similar") with the reason, under the other lines
-- of the tooltip. It compares the item with what you wear in the same slot, using the weights of your spec
-- (spec.itemWeights: ranged weapon DPS, Agility...). It only reads and adds lines; it changes nothing on the item.
-- Settings (saved): verdict on/off, and whether the reason is shown.

local ADDON, GF = ...
local T, Lf = GF.T, GF.L
local function N(text)
    return text
end

local STAT_NAME = {
    ITEM_MOD_AGILITY_SHORT = N("Agilita'"),
    ITEM_MOD_INTELLECT_SHORT = N("Intelletto"),
    ITEM_MOD_STAMINA_SHORT = N("Stamina"),
    ITEM_MOD_SPIRIT_SHORT = N("Spirito"),
    ITEM_MOD_STRENGTH_SHORT = N("Forza"),
    ITEM_MOD_ATTACK_POWER_SHORT = N("Potenza d'attacco"),
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = N("Potenza d'attacco a distanza"),
    ITEM_MOD_SPELL_POWER_SHORT = N("Potere magico"),
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = N("Danno magico"),
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = N("Potere di cura"),
    ITEM_MOD_MANA_REGENERATION_SHORT = N("Rigenerazione del mana"),
}

-- inventory slots an item type can go to (rings and trinkets have two; one-hand weapons go to either hand)
local SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CLOAK = { 15 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
    INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 }, INVTYPE_WEAPON = { 16, 17 }, INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
    INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 },
}
local WEAPON_SLOT = { [16] = "melee", [17] = "melee", [18] = "ranged" }

local function opt(key, default)
    local v = BuildBeastDB and BuildBeastDB[key]
    if v == nil then
        return default
    end
    return v
end

local function itemStats(link)
    local t
    if C_Item and C_Item.GetItemStats then
        local ok, r = pcall(C_Item.GetItemStats, link)
        if ok then
            t = r
        end
    end
    if not t and GetItemStats then
        local ok, r = pcall(GetItemStats, link)
        if ok then
            t = r
        end
    end
    return t or {}
end

-- damage per second of a weapon: from the stats when the client has them, else from the number in brackets of the tooltip
local scan
local dpsCache = {}
local function weaponDps(link, stats)
    if stats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT then
        return stats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT
    end
    if dpsCache[link] then
        return dpsCache[link]
    end
    scan = scan or CreateFrame("GameTooltip", "BuildBeastScan", nil, "GameTooltipTemplate")
    scan:SetOwner(UIParent, "ANCHOR_NONE")
    scan:ClearLines()
    scan:SetHyperlink(link)
    for i = 2, math.min(scan:NumLines(), 8) do
        local fs = _G["BuildBeastScanTextLeft" .. i]
        local text = fs and fs:GetText()
        local n = text and text:match("%((%d+[%.,]%d+)[^%)]*%)")
        if n then
            dpsCache[link] = tonumber((n:gsub(",", ".")))
            return dpsCache[link]
        end
    end
    return 0
end

-- score of an item in a slot, and its parts (stat key -> value, "dps" -> dps)
local function scoreOf(link, slot, w)
    local stats = itemStats(link)
    local total, parts = 0, { other = {} }
    for key, weight in pairs(w.stats) do
        local v = stats[key]
        if v and v ~= 0 then
            total = total + v * weight
            parts[key] = v
        end
    end
    for key, v in pairs(stats) do
        if w.stats[key] == nil and key ~= "ITEM_MOD_DAMAGE_PER_SECOND_SHORT" and type(v) == "number" and v ~= 0 then
            parts.other[key] = v
        end
    end
    local kind = WEAPON_SLOT[slot]
    if kind then
        local dps = weaponDps(link, stats)
        parts.dps = dps
        total = total + dps * ((kind == "ranged") and w.rangedDps or w.meleeDps)
    end
    return total, parts
end

local function sign(n)
    return (n >= 0 and "+" or "") .. string.format("%g", math.floor(n * 10 + 0.5) / 10)
end

-- green for a gain, red for a loss
local function green(text)
    return "|cff33ff33" .. text .. "|r"
end

local function red(text)
    return "|cffff4040" .. text .. "|r"
end

-- the verdict for an item link: text, colour, and the reason lines
local function judge(link)
    local spec = GF.specData()
    local w = spec and spec.itemWeights
    if not w then
        return nil
    end
    local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    local _, _, _, equipLoc = getInstant(link)
    local slots = equipLoc and SLOTS[equipLoc]
    if not slots then
        return nil
    end
    if IsEquippedItem and IsEquippedItem(link) then
        return nil
    end
    local slotUsed, kind = slots[1], nil
    -- the worst item you wear among the possible slots is the one it would replace
    local oldScore, oldParts, haveOld
    for _, s in ipairs(slots) do
        local cur = GetInventoryItemLink("player", s)
        if cur then
            local sc, parts = scoreOf(cur, s, w)
            if not haveOld or sc < oldScore then
                oldScore, oldParts, slotUsed, haveOld = sc, parts, s, true
            end
        elseif not haveOld then
            slotUsed = s
        end
    end
    kind = WEAPON_SLOT[slotUsed]
    local newScore, newParts = scoreOf(link, slotUsed, w)
    local reasons = {}

    if not haveOld then
        reasons[#reasons + 1] = T("Non hai niente in questo slot.")
        return "SI", { 0, 1, 0 }, reasons
    end
    local delta = newScore - oldScore

    -- what changes, stat by stat, and the weapon DPS
    local gains, losses = {}, {}
    for key, name in pairs(STAT_NAME) do
        local d = (newParts[key] or 0) - (oldParts[key] or 0)
        if d ~= 0 and (w.stats[key] or 0) > 0 then
            local item = sign(d) .. " " .. T(name)
            if d > 0 then
                gains[#gains + 1] = green(item)
            else
                losses[#losses + 1] = red(item)
            end
        end
    end
    table.sort(gains)
    table.sort(losses)
    if #gains > 0 then
        reasons[#reasons + 1] = green(T("Guadagni:")) .. " " .. table.concat(gains, ", ") .. "."
    end
    if #losses > 0 then
        reasons[#reasons + 1] = red(T("Perdi:")) .. " " .. table.concat(losses, ", ") .. "."
    end
    if kind then
        local dd = (newParts.dps or 0) - (oldParts.dps or 0)
        if math.abs(dd) >= 0.1 then
            if kind == "ranged" then
                reasons[#reasons + 1] = T("DPS dell'arma a distanza (o bacchetta):") .. " " .. (dd > 0 and green(sign(dd)) or red(sign(dd))) .. (((w.rangedDps or 0) >= 10) and (". " .. T("Per la tua spec e' la cosa che conta di piu'.")) or ".")
            elseif (w.meleeDps or 0) == 0 then
                reasons[#reasons + 1] = T("DPS dell'arma da mischia:") .. " " .. (dd > 0 and green(sign(dd)) or red(sign(dd))) .. ", " .. T("ma la tua spec non colpisce con quell'arma e non li usa.")
            else
                reasons[#reasons + 1] = T("DPS dell'arma da mischia:") .. " " .. (dd > 0 and green(sign(dd)) or red(sign(dd))) .. ", " .. T("che per la tua spec conta.")
            end
        end
    end
    -- differences in stats that carry no weight for this spec (armor, spell damage...)
    local otherDiff = false
    for key, v in pairs(newParts.other or {}) do
        if v ~= ((oldParts.other or {})[key] or 0) then
            otherDiff = true
        end
    end
    for key, v in pairs(oldParts.other or {}) do
        if v ~= ((newParts.other or {})[key] or 0) then
            otherDiff = true
        end
    end
    if otherDiff then
        reasons[#reasons + 1] = T("Le altre differenze (armatura, danni...) non contano per la tua spec.")
    end
    if #reasons == 0 then
        reasons[#reasons + 1] = T("Le statistiche che contano per te sono uguali.")
    end
    -- the weapon rule only under weapons; for everything else the short rule of the slot
    if kind then
        if w.why then
            reasons[#reasons + 1] = T(w.why)
        end
    else
        local topName, topWeight = nil, 0
        for key, weight in pairs(w.stats) do
            if STAT_NAME[key] and weight > topWeight then
                topName, topWeight = STAT_NAME[key], weight
            end
        end
        if topName then
            reasons[#reasons + 1] = Lf("Per la tua spec in questo slot conta soprattutto: %s.", T(topName))
        end
    end
    local limit = tonumber(BuildBeastDB and BuildBeastDB.threshold) or 1
    if delta >= limit then
        return "SI", { 0, 1, 0 }, reasons
    elseif delta <= -limit then
        return "NO", { 1, 0.25, 0.25 }, reasons
    end
    return "SIMILE", { 1, 0.85, 0.2 }, reasons
end

-- A tooltip only grows at the bottom, so to put our lines right under the suggested enchantment (GearQuest's yellow
-- line and the grey note below it) we add them at the end and then rewrite the texts of the lines from that point on,
-- in the new order. Only the texts and colours move; if the enchantment line is not there, nothing moves.
local function lineInfo(tt, i)
    local name = tt:GetName()
    local l = _G[name .. "TextLeft" .. i]
    local r = _G[name .. "TextRight" .. i]
    if not l then
        return nil
    end
    local info = { lt = l:GetText() }
    info.lr, info.lg, info.lb = l:GetTextColor()
    info.wrap = l.CanWordWrap and l:CanWordWrap() or false
    if r then
        info.rt = r:GetText()
        info.rr, info.rg, info.rb = r:GetTextColor()
    end
    return info
end

local function writeLine(tt, i, info)
    local name = tt:GetName()
    local l = _G[name .. "TextLeft" .. i]
    local r = _G[name .. "TextRight" .. i]
    l:SetText(info.lt or "")
    l:SetTextColor(info.lr or 1, info.lg or 1, info.lb or 1)
    if l.SetWordWrap then
        l:SetWordWrap(info.wrap and true or false)
    end
    if r then
        if info.rt and info.rt ~= "" then
            r:SetText(info.rt)
            r:SetTextColor(info.rr or 1, info.rg or 1, info.rb or 1)
            r:Show()
        else
            r:SetText("")
            r:Hide()
        end
    end
end

local function isEnchantLine(text)
    return text and (text:find("Incantamento consigliato", 1, true) or text:find("Recommended enchantment", 1, true))
end

local function moveAfterEnchant(tt, added)
    local n = tt:NumLines()
    local name = tt:GetName()
    local first
    for i = 2, n - added do
        local l = _G[name .. "TextLeft" .. i]
        if l and isEnchantLine(l:GetText()) then
            first = i
            break
        end
    end
    if not first then
        return
    end
    -- the grey note under it ("Per il tuo livello e' in classifica solo..." / "Only ... is ranked for your level")
    local last = first
    local nextLine = first + 1 <= n - added and _G[name .. "TextLeft" .. (first + 1)]
    local text = nextLine and nextLine:GetText()
    if text and (text:find("^Per il tuo livello") or text:find("^Only ")) then
        last = first + 1
    end
    if last >= n - added then
        return -- already the last lines
    end
    local infos = {}
    for i = 1, n do
        infos[i] = lineInfo(tt, i)
        if not infos[i] then
            return
        end
    end
    local order = {}
    for i = 1, last do
        order[#order + 1] = infos[i]
    end
    for i = n - added + 1, n do
        order[#order + 1] = infos[i]
    end
    for i = last + 1, n - added do
        order[#order + 1] = infos[i]
    end
    for i = last + 1, n do
        writeLine(tt, i, order[i])
    end
end

-- "SI" / "NO" / "SIMILE" for an item link (nil when we have no opinion); used by the arrows on the bag icons
function GF.VerdictOf(link)
    local ok, verdict = pcall(judge, link)
    if ok then
        return verdict
    end
end

local function onTooltip(tt)
    if not opt("verdict", true) then
        return
    end
    if tt ~= GameTooltip and tt ~= ItemRefTooltip then
        return
    end
    if tt.__glDone then
        return
    end
    local ok, link = pcall(function()
        local _, l = tt:GetItem()
        return l
    end)
    if not (ok and link) then
        return
    end
    local ok2, verdict, color, reasons = pcall(judge, link)
    if not (ok2 and verdict) then
        return
    end
    tt.__glDone = true
    local added = 2
    tt:AddLine(" ")
    tt:AddLine("BuildBeast: " .. GF.VerdictWord(verdict), color[1], color[2], color[3])
    if opt("why", true) then
        for _, line in ipairs(reasons) do
            tt:AddLine(line, 0.8, 0.8, 0.8, true)
            added = added + 1
        end
    end
    pcall(moveAfterEnchant, tt, added)
    tt:Show()
end

function GF.InitVerdict()
    for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
        if tt and tt.HookScript then
            tt:HookScript("OnTooltipCleared", function(t)
                t.__glDone = nil
            end)
        end
    end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onTooltip)
    else
        if GameTooltip then
            GameTooltip:HookScript("OnTooltipSetItem", onTooltip)
        end
        if ItemRefTooltip then
            ItemRefTooltip:HookScript("OnTooltipSetItem", onTooltip)
        end
    end
end
