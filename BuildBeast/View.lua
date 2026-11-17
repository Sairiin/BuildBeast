-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: the building blocks of the window's tabs: headings, paragraphs and cards (coloured bar, icon, title, tag and
-- text) stacked one under the other inside the scroll area. A tab fills a view like this:
--   v:Begin(); v:Heading("Title"); v:Card({ icon = tex, title = "...", lines = "...", bar = {r,g,b}, bg = {r,g,b} }); return v:End()
-- The frames are made once and reused, so changing tab or level does not create new ones.

local _, GF = ...
local V = {}
GF.View = V

V.W = 576 -- width of the cards: follows the width of the window (Window.lua changes it when you drag the border)

-- size of the text in the window: the + / - buttons change only this (BuildBeastDB.scale, 0.7 to 1.8)
function V.Scale()
    local s = tonumber(BuildBeastDB and BuildBeastDB.scale) or 1
    return math.max(0.7, math.min(1.8, s))
end

-- makes a font string follow the text size: every SetText first sets the size of its font object times the scale
function V.Track(s, template)
    s._tmpl = template or "GameFontHighlight"
    local raw = s.SetText
    s.SetText = function(self, t)
        local obj = _G[self._tmpl]
        local base
        if obj and obj.GetFont then
            local _, size = obj:GetFont()
            base = size
        end
        local path, _, flags = self:GetFont()
        if type(path) == "string" and type(base) == "number" then
            self:SetFont(path, base * V.Scale(), flags)
        end
        raw(self, t)
    end
    return s
end

function V.NewFS(parent, template)
    local s = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    s:SetJustifyH("LEFT")
    s:SetJustifyV("TOP")
    return V.Track(s, template)
end

local function newFS(parent, template)
    return V.NewFS(parent, template)
end

-- shrinks the text of a button until it fits inside it (long words in some languages)
function GF.FitButton(b, pad)
    local fs = b.GetFontString and b:GetFontString()
    if not fs then
        return
    end
    local path, _, flags = fs:GetFont()
    if type(path) ~= "string" then
        return
    end
    local size = 12
    fs:SetFont(path, size, flags)
    local avail = b:GetWidth() - (pad or 16)
    while fs:GetStringWidth() > avail and size > 8 do
        size = size - 1
        fs:SetFont(path, size, flags)
    end
end

local function newBox(parent)
    local b = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    return b
end

local M = {}

function M:Begin()
    for _, list in pairs(self.pool) do
        for _, w in ipairs(list) do
            w:Hide()
        end
    end
    self.used = { head = 0, card = 0, para = 0 }
    self.y = 0
end

local function take(self, kind, make)
    local n = self.used[kind] + 1
    self.used[kind] = n
    local w = self.pool[kind][n]
    if not w then
        w = make(self)
        self.pool[kind][n] = w
    end
    return w
end

function M:Heading(text, r, g, b)
    local h = take(self, "head", function(v)
        return newFS(v, "GameFontNormalLarge")
    end)
    if self.y > 0 then
        self.y = self.y + 6
    end
    h:SetText(text)
    h:SetTextColor(r or 1, g or 0.82, b or 0)
    h:ClearAllPoints()
    h:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -self.y)
    h:Show()
    self.y = self.y + 26
end

function M:Para(text, r, g, b)
    local p = take(self, "para", function(v)
        local s = newFS(v)
        return s
    end)
    p:SetWidth(V.W - 4)
    p:SetText(text)
    p:SetTextColor(r or 0.9, g or 0.9, b or 0.9)
    p:ClearAllPoints()
    p:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -self.y)
    p:Show()
    self.y = self.y + p:GetStringHeight() + 8
end

-- c = { icon, size, title, tag, tagColor, lines, bar = {r,g,b}, bg = {r,g,b} }
function M:Card(c)
    local card = take(self, "card", function(v)
        local x = newBox(v)
        x.bar = x:CreateTexture(nil, "ARTWORK")
        x.bar:SetPoint("TOPLEFT", 0, 0)
        x.bar:SetPoint("BOTTOMLEFT", 0, 0)
        x.bar:SetWidth(4)
        x.ib = x:CreateTexture(nil, "BACKGROUND")
        x.ib:SetColorTexture(0.42, 0.35, 0.16, 1)
        x.icon = x:CreateTexture(nil, "ARTWORK")
        x.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        x.title = newFS(x, "GameFontNormal")
        x.title:SetTextColor(1, 1, 1)
        x.tag = newFS(x, "GameFontNormalSmall")
        x.body = newFS(x)
        return x
    end)
    card:SetWidth(V.W)
    local bar, bg = c.bar or { 0.55, 0.65, 0.85 }, c.bg or { 0.11, 0.12, 0.15 }
    card:SetBackdropColor(bg[1], bg[2], bg[3], 1)
    card.bar:SetColorTexture(bar[1], bar[2], bar[3], 1)

    local size = c.size or 40
    local padX = 16
    if c.icon then
        padX = size + 28
        card.ib:SetSize(size + 4, size + 4)
        card.ib:ClearAllPoints()
        card.ib:SetPoint("TOPLEFT", 12, -8)
        card.icon:SetSize(size, size)
        card.icon:ClearAllPoints()
        card.icon:SetPoint("TOPLEFT", 14, -10)
        card.icon:SetTexture(c.icon)
        card.ib:Show()
        card.icon:Show()
    else
        card.ib:Hide()
        card.icon:Hide()
    end

    local textW = V.W - padX - 14
    local used = 10
    card.title:SetWidth(c.tag and (textW - 130) or textW)
    card.tag:ClearAllPoints()
    if c.title and c.title ~= "" then
        card.title._tmpl = size >= 36 and "GameFontNormalLarge" or "GameFontNormal"
        card.title:SetFontObject(card.title._tmpl)
        card.title:SetTextColor(1, 1, 1)
        card.title:SetText(c.title)
        card.title:ClearAllPoints()
        card.title:SetPoint("TOPLEFT", padX, -10)
        card.title:Show()
        used = used + card.title:GetStringHeight()
        if c.tag then
            card.tag:SetText(c.tag)
            card.tag:SetTextColor((c.tagColor or bar)[1], (c.tagColor or bar)[2], (c.tagColor or bar)[3])
            card.tag:SetPoint("TOPRIGHT", -12, -12)
            card.tag:Show()
        else
            card.tag:Hide()
        end
    else
        card.title:Hide()
        card.tag:Hide()
    end
    if c.lines and c.lines ~= "" then
        card.body:SetWidth(textW)
        card.body:SetText(c.lines)
        card.body:ClearAllPoints()
        card.body:SetPoint("TOPLEFT", padX, -(used + ((c.title and c.title ~= "") and 4 or 0)))
        card.body:Show()
        used = used + ((c.title and c.title ~= "") and 4 or 0) + card.body:GetStringHeight()
    else
        card.body:Hide()
    end
    local h = math.max(c.icon and (size + 20) or 0, used + 12)
    card:SetHeight(h)
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -self.y)
    card:Show()
    self.y = self.y + h + 6
end

function M:End()
    self:SetHeight(math.max(10, self.y))
    return self.y
end

function V.New(parent)
    local v = CreateFrame("Frame", nil, parent)
    v:SetPoint("TOPLEFT", 0, 0)
    v:SetSize(V.W, 10)
    v.pool = { head = {}, card = {}, para = {} }
    v.used = { head = 0, card = 0, para = 0 }
    v.y = 0
    for k, fn in pairs(M) do
        v[k] = fn
    end
    v:Hide()
    return v
end
