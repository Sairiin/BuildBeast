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

-- the next talent of the plan at or after `level`: level, name
local function nextTalent(spec, level)
    local plan = GF.plan(spec)
    for lvl = math.max(10, level), 60 do
        if plan[lvl] then
            return lvl, plan[lvl]
        end
    end
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
    local w = _G.BuildBeastFrame
    if w then
        w:SetScale(s)
    end
    if frame then
        frame:SetScale(s)
    end
    if GF.RefreshScaleLabel then
        GF.RefreshScaleLabel()
    end
end
