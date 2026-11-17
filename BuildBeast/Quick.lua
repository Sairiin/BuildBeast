-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: the small always-visible panel (next talent to take), the message at every level up, and the size of the
-- interface (+ / - at the bottom of the window; it scales the window and the panel, text and icons included).

local ADDON, GF = ...
local T, Lf = GF.T, GF.L

local frame

local SCALE_MIN, SCALE_MAX, SCALE_STEP = 0.7, 1.8, 0.1

local function scale()
    local s = tonumber(BuildBeastDB and BuildBeastDB.scale) or 1
    return math.max(SCALE_MIN, math.min(SCALE_MAX, s))
end

-- the next talent of the plan that you do not have yet: level, name. With the talent data we skip what you already
-- took (so the panel moves on as soon as you spend the point); without it we go by level only.
local function nextTalent(spec, level)
    local plan = GF.plan(spec)
    local ranks = GF.TalentRanks and GF.TalentRanks()
    if ranks then
        local count = {}
        for lvl = 10, 60 do
            local name = plan[lvl]
            if name then
                count[name] = (count[name] or 0) + 1
                if (ranks[name] or 0) < count[name] then
                    return lvl, name
                end
            end
        end
        return nil
    end
    for lvl = math.max(10, level), 60 do
        if plan[lvl] then
            return lvl, plan[lvl]
        end
    end
end

-- a solid dark background (no transparency) for the window and the panel; on by default, optional
function GF.ApplyDarkBackground(f)
    if not f then
        return
    end
    if not f.dark then
        local t = f:CreateTexture(nil, "BACKGROUND", nil, -6)
        t:SetPoint("TOPLEFT", 1, -1)
        t:SetPoint("BOTTOMRIGHT", -1, 1)
        t:SetColorTexture(0.03, 0.035, 0.045, 1)
        f.dark = t
    end
    f.dark:SetShown(not (BuildBeastDB and BuildBeastDB.darkBg == false))
end

function GF.SetDarkBackground(on)
    BuildBeastDB.darkBg = on and true or false
    GF.ApplyDarkBackground(_G.BuildBeastFrame)
    GF.ApplyDarkBackground(_G.BuildBeastQuick)
end

local function build()
    local f = CreateFrame("Frame", "BuildBeastQuick", UIParent, "BackdropTemplate")
    f:SetSize(250, 48)
    f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f:SetBackdropColor(0.06, 0.07, 0.09, 0.92)
    f:SetBackdropBorderColor(0.85, 0.68, 0.2, 1)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local l, b = self:GetLeft(), self:GetBottom()
        if l and b and BuildBeastDB then
            BuildBeastDB.quickPos = { l = l, b = b }
        end
    end)
    -- small x to hide the panel (it comes back from the options)
    local x = CreateFrame("Button", nil, f)
    x:SetSize(16, 16)
    x:SetPoint("TOPRIGHT", -3, -3)
    x.t = x:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    x.t:SetPoint("CENTER", 0, 0)
    x.t:SetText("x")
    x:SetScript("OnClick", function()
        GF.SetQuickShown(false)
        if GF.RefreshOptions then
            GF.RefreshOptions()
        end
    end)
    x:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText(T("Nascondi il pannello (lo riattivi nelle Opzioni)"))
        GameTooltip:Show()
    end)
    x:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(34, 34)
    f.icon:SetPoint("LEFT", 7, 0)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.title:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 8, -1)
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.text:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -2)
    f.text:SetWidth(190)
    f.text:SetJustifyH("LEFT")
    local pos = BuildBeastDB and BuildBeastDB.quickPos
    if pos then
        f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", pos.l, pos.b)
    else
        f:SetPoint("TOP", UIParent, "TOP", 0, -150)
    end
    GF.ApplyDarkBackground(f)
    return f
end

function GF.RefreshQuick()
    if not frame then
        return
    end
    if BuildBeastDB and BuildBeastDB.quick == false then
        frame:Hide()
        return
    end
    local spec = GF.specData()
    if not spec then
        frame:Hide()
        return
    end
    local level = UnitLevel("player") or 1
    local lvl, name = nextTalent(spec, level)
    if not lvl then
        frame:Hide()
        return
    end
    frame.title:SetText(T("BuildBeast: prossimo talento"))
    local tex = GF.IconFor and GF.IconFor(name)
    frame.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
    local when = (lvl <= level) and ("|cff33ff33" .. T("ora") .. "|r") or Lf("livello %s", "|cffffd100" .. lvl .. "|r")
    frame.text:SetText(name .. "  (" .. when .. ")")
    frame:SetScale(scale())
    frame:Show()
end

function GF.SetQuickShown(show)
    BuildBeastDB.quick = show and true or false
    GF.RefreshQuick()
end

function GF.InitQuick()
    frame = build()
    GF.RefreshQuick()
    -- the icons and the spec may be known a little later
    C_Timer.After(4, GF.RefreshQuick)
    C_Timer.After(14, GF.RefreshQuick)
    -- and every few seconds, in case a talent change did not send its event
    C_Timer.NewTicker(5, GF.RefreshQuick)
end

-- message at every level up
function GF.AnnounceLevel(level)
    local spec = GF.specData()
    if not (spec and level) then
        return
    end
    local parts = {}
    local plan = GF.plan(spec)
    if level >= 10 and plan[level] then
        parts[#parts + 1] = Lf("prendi il talento %s", "|cff33ff33" .. plan[level] .. "|r")
    end
    if spec.spells and spec.spells[level] then
        parts[#parts + 1] = Lf("abilita' nuove: %s", T(spec.spells[level]))
    end
    if #parts > 0 then
        GF.say(Lf("livello %d", level) .. ": " .. table.concat(parts, "; ") .. ". " .. T("(/bb per la guida)"))
    end
    GF.RefreshQuick()
end

-- size of the interface ---------------------------------------------------------------------------------------------------
function GF.GetScale()
    return scale()
end

function GF.ChangeScale(delta)
    local s = math.floor((scale() + delta) * 10 + 0.5) / 10
    s = math.max(SCALE_MIN, math.min(SCALE_MAX, s))
    BuildBeastDB.scale = s
    -- the window only changes the size of its text; the small panel is scaled as a whole
    if frame then
        frame:SetScale(s)
    end
    if GF.RefreshWindow then
        GF.RefreshWindow()
    end
    if GF.RefreshScaleLabel then
        GF.RefreshScaleLabel()
    end
end
