-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: languages. The texts in the code are written in Italian; every other language is a table of the same texts
-- (Lang_<code>.lua), found through the short id of the Italian text (Lang_ids.lua). A missing translation falls back to
-- English, and then to the Italian text itself, so nothing is ever empty.
--   GF.T(text)        translated text
--   GF.L(text, ...)   translated text used as a string.format template

local ADDON, GF = ...

GF.TR = GF.TR or {}     -- language code -> { id = text }
GF.ITID = GF.ITID or {} -- Italian text -> id

-- code, name in its own language, game locales that choose it by themselves
GF.LANGS = {
    { "it", "Italiano" },
    { "en", "English" },
    { "es", "Espa\195\177ol" },
    { "de", "Deutsch" },
    { "fr", "Fran\195\167ais" },
    { "pt", "Portugu\195\170s" },
    { "ru", "\208\160\209\131\209\129\209\129\208\186\208\184\208\185" },
    { "ko", "\237\149\156\234\181\173\236\150\180" },
    { "zh", "\231\174\128\228\189\147\228\184\173\230\150\135" },
    { "zt", "\231\185\129\233\171\148\228\184\173\230\150\135" },
}

local LOCALE_TO_LANG = {
    itIT = "it", enUS = "en", enGB = "en", esES = "es", esMX = "es", deDE = "de", frFR = "fr",
    ptBR = "pt", ruRU = "ru", koKR = "ko", zhCN = "zh", zhTW = "zt",
}

-- the language in use: the one chosen in the options, or the one of the game client
function GF.Lang()
    local chosen = BuildBeastDB and BuildBeastDB.lang
    if chosen and chosen ~= "auto" then
        return chosen
    end
    return LOCALE_TO_LANG[GetLocale and GetLocale() or "enUS"] or "en"
end

local cacheLang, cacheIsIt

function GF.T(text)
    if type(text) ~= "string" then
        return text
    end
    local lang = GF.Lang()
    if lang == "it" then
        return text
    end
    local id = GF.ITID[text]
    if id then
        local t = GF.TR[lang] and GF.TR[lang][id]
        if t then
            return t
        end
        t = GF.TR.en and GF.TR.en[id]
        if t then
            return t
        end
    end
    return text
end

function GF.L(text, ...)
    local s = GF.T(text)
    if select("#", ...) > 0 then
        local ok, out = pcall(string.format, s, ...)
        if ok then
            return out
        end
        ok, out = pcall(string.format, text, ...)
        if ok then
            return out
        end
    end
    return s
end

-- fonts for the languages the default font cannot draw (the game ships these files)
local FONT_FOR = {
    ru = { "Fonts\\FRIZQT___CYR.TTF", "Fonts\\ARIALN.TTF" },
    ko = { "Fonts\\2002.TTF", "Fonts\\2002B.TTF" },
    zh = { "Fonts\\ARKai_T.ttf", "Fonts\\ARHei.ttf" },
    zt = { "Fonts\\bLEI00D.ttf", "Fonts\\bHEI01B.ttf", "Fonts\\bHEI00M.ttf" },
}

local function workingFont(lang)
    for _, path in ipairs(FONT_FOR[lang] or {}) do
        local probe = GF.fontProbe
        if not probe then
            probe = UIParent:CreateFontString(nil, "OVERLAY")
            GF.fontProbe = probe
        end
        if probe:SetFont(path, 12, "") then
            return path
        end
    end
    return nil
end

-- puts the right font on every text of a frame (and of everything inside it)
function GF.ApplyFonts(root)
    local path = workingFont(GF.Lang())
    if not (path and root) then
        return
    end
    local function walk(f)
        for _, r in ipairs({ f:GetRegions() }) do
            if r.GetObjectType and r:GetObjectType() == "FontString" then
                local _, size, flags = r:GetFont()
                r:SetFont(path, size or 12, flags)
            end
        end
        if f.GetFontString and f:GetFontString() then
            local fs = f:GetFontString()
            local _, size, flags = fs:GetFont()
            fs:SetFont(path, size or 12, flags)
        end
        for _, c in ipairs({ f:GetChildren() }) do
            walk(c)
        end
    end
    walk(root)
end

-- How the verdict of an item is written, in four styles chosen in the options (BuildBeastDB.verdictStyle):
--   text   : YES / NO / SIMILAR in the language in use
--   symbol : + / - / =
--   check  : the game's ready-check marks (green tick, red cross, yellow dots)
--   arrow  : green arrow up, red arrow down, yellow equal sign (our own pictures)
local function hasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) and true or false
end

function GF.VerdictWordIn(style, v)
    if style == "symbol" then
        return (v == "SI" and "+") or (v == "NO" and "-") or "="
    elseif style == "check" then
        local tex = (v == "SI" and "ReadyCheck-Ready") or (v == "NO" and "ReadyCheck-NotReady") or "ReadyCheck-Waiting"
        return "|TInterface\\RaidFrame\\" .. tex .. ":16:16|t"
    elseif style == "arrow" then
        -- our own small pictures (arrow_up, arrow_down, arrow_same in the addon folder): the game has no red down arrow
        local name = (v == "SI" and "arrow_up") or (v == "NO" and "arrow_down") or "arrow_same"
        return "|TInterface\\AddOns\\BuildBeast\\" .. name .. ":16:16|t"
    end
    if v == "SI" then
        return GF.T("SI")
    elseif v == "NO" then
        return GF.T("NO")
    end
    return GF.T("SIMILE")
end

-- the verdict word of an item, in the style and language in use
function GF.VerdictWord(v)
    return GF.VerdictWordIn((BuildBeastDB and BuildBeastDB.verdictStyle) or "text", v)
end

-- the three words of a style side by side, for the buttons of the options
function GF.VerdictPreview(style)
    local sep = (style == "text") and " / " or "   "
    return GF.VerdictWordIn(style, "SI") .. sep .. GF.VerdictWordIn(style, "NO") .. sep .. GF.VerdictWordIn(style, "SIMILE")
end
