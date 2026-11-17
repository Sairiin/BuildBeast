-- BuildBeast (c) 2026 Sairiin. All rights reserved. Copying, modification or redistribution of this code is forbidden without written permission.
-- BuildBeast: core. Shared helpers, plan maths, events, slash commands and the minimap button.
-- Only ASCII in this file (the WoW client may mangle other characters in addon text).

local ADDON, GF = ...
local T, Lf = GF.T, GF.L
GF.PREFIX = "|cff66ccffBuildBeast|r: "

function GF.say(msg)
    print(GF.PREFIX .. tostring(msg))
end
local say = GF.say

function GF.playerClass()
    local _, file = UnitClass("player")
    return file
end

-- Plan maths ---------------------------------------------------------------------------------------------------------
-- plan[level] = talent that gets the point of that level (levels 10..60).
function GF.plan(spec)
    if spec._plan then
        return spec._plan
    end
    local plan = {}
    for _, run in ipairs(spec.talentRuns) do
        for lvl = run[1], run[2] do
            plan[lvl] = run[3]
        end
    end
    spec._plan = plan
    return plan
end

-- name -> rank the plan wants at this level
function GF.ranksAt(spec, level)
    local plan, out = GF.plan(spec), {}
    for lvl = 10, math.min(level, 60) do
        local n = plan[lvl]
        if n then
            out[n] = (out[n] or 0) + 1
        end
    end
    return out
end

-- level at which the plan gives this talent its (have + 1)th point, or nil
function GF.nextLevelFor(spec, name, have)
    local plan, c = GF.plan(spec), 0
    for lvl = 10, 60 do
        if plan[lvl] == name then
            c = c + 1
            if c > have then
                return lvl
            end
        end
    end
end

-- Events ---------------------------------------------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LEVEL_UP")

local minimapButton

local function setupButton()
    local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
    local dbicon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not (ldb and dbicon) then
        return false
    end
    local object = ldb:GetDataObjectByName("BuildBeast") or ldb:NewDataObject("BuildBeast", {
        type = "launcher",
        text = "BuildBeast",
        icon = "Interface/AddOns/BuildBeast/icon",
        OnClick = function(_, button)
            if button == "RightButton" then
                GF.ToggleOptions()
            else
                GF.ToggleWindow()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("BuildBeast")
            tooltip:AddLine(T("Realizzato da Sairiin"), 1, 0.82, 0)
            tooltip:AddLine(T("Clic sinistro: la guida del tuo livello"), 0.8, 0.8, 0.8)
            tooltip:AddLine(T("Clic destro: le opzioni"), 0.8, 0.8, 0.8)
        end,
    })
    BuildBeastDB.minimap = BuildBeastDB.minimap or { hide = false }
    dbicon:Register("BuildBeast", object, BuildBeastDB.minimap)
    minimapButton = dbicon:GetMinimapButton("BuildBeast")
    return true
end

function GF.SetMinimapShown(show)
    local dbicon = LibStub and LibStub("LibDBIcon-1.0", true)
    BuildBeastDB.minimap = BuildBeastDB.minimap or { hide = false }
    BuildBeastDB.minimap.hide = not show
    if dbicon and minimapButton then
        if show then
            dbicon:Show("BuildBeast")
        else
            dbicon:Hide("BuildBeast")
        end
    end
end

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            -- the addon used to be called "Guida Livelli": take its saved settings over once
            if BuildBeastDB == nil and type(_G.GuidaLivelliDB) == "table" then
                BuildBeastDB = _G.GuidaLivelliDB
            end
            local fresh = (BuildBeastDB == nil) or (next(BuildBeastDB) == nil)
            BuildBeastDB = BuildBeastDB or {}
            if BuildBeastDB.lang == nil then
                -- a new user follows the language of the game; whoever used the Italian version keeps Italian
                BuildBeastDB.lang = fresh and "auto" or "it"
            end
        end
        return
    end
    if event == "PLAYER_LEVEL_UP" then
        if GF.AnnounceLevel then
            GF.AnnounceLevel(tonumber(arg1))
        end
        if GF.QueueTalentRefresh then
            GF.QueueTalentRefresh()
        end
        if GF.RefreshWindow then
            GF.RefreshWindow()
        end
        return
    end
    -- PLAYER_LOGIN
    BuildBeastDB = BuildBeastDB or {}
    if GF.ApplyTranslations then
        GF.ApplyTranslations()
    end
    if GF.ApplyBase then
        GF.ApplyBase()
    end
    setupButton()
    if GF.InitTalents then
        GF.InitTalents()
    end
    if GF.ScanTalentIcons then
        GF.ScanTalentIcons()
        C_Timer.After(5, GF.ScanTalentIcons)
    end
    if GF.InitGlow then
        GF.InitGlow()
    end
    if GF.InitCooldowns then
        GF.InitCooldowns()
    end
    if GF.InitVerdict then
        GF.InitVerdict()
    end
    if GF.InitArrows then
        GF.InitArrows()
    end
    if GF.InitQuick then
        GF.InitQuick()
    end
    if GF.RegisterSettingsCategory then
        GF.RegisterSettingsCategory()
    end
    -- Hekili and the other addons may still be starting: give them time, and run after BuildSetter's own check (8 s)
    C_Timer.After(12, function()
        if GF.ApplyBase then
            GF.ApplyBase()
        end
        if GF.InitRotation then
            GF.InitRotation()
        end
    end)
end)

-- Slash commands -------------------------------------------------------------------------------------------------------
SLASH_BUILDBEAST1 = "/bb"
SLASH_BUILDBEAST2 = "/buildbeast"
SlashCmdList["BUILDBEAST"] = function(msg)
    local cmd, arg, arg2 = string.lower(msg or ""):match("^%s*(%S*)%s*(%S*)%s*(%S*)")
    if cmd == "" then
        GF.ToggleWindow()
    elseif cmd == "cd" then
        GF.CooldownCommand(arg, arg2)
    elseif cmd == "frames" then
        GF.DebugFrames()
    elseif cmd == "opzioni" or cmd == "options" or cmd == "menu" then
        GF.ToggleOptions()
    elseif cmd == "rot" then
        GF.PrintRotation()
    elseif cmd == "apply" then
        GF.InitRotation(true)
    elseif cmd == "glow" then
        GF.SetBarGlow(arg == "on")
    elseif cmd == "zygor" then
        GF.SetZygorTalentIcons(arg == "on")
    elseif cmd == "icone" then
        GF.IconsReport()
    elseif cmd == "guida" or cmd == "aiuto" or cmd == "help" then
        GF.ShowTab("guida")
    elseif cmd == "dump" then
        GF.DumpTalents()
    elseif cmd == "minimap" then
        local dbicon = LibStub and LibStub("LibDBIcon-1.0", true)
        if dbicon and minimapButton then
            BuildBeastDB.minimap.hide = not BuildBeastDB.minimap.hide
            if BuildBeastDB.minimap.hide then
                dbicon:Hide("BuildBeast")
            else
                dbicon:Show("BuildBeast")
            end
        end
    else
        say(T("comandi:") .. " |cff00ff00/bb|r (" .. T("guida") .. "), |cff00ff00opzioni|r (" .. T("menu con tutte le impostazioni") .. "), |cff00ff00rot|r (" .. T("cosa suggerisce Hekili") .. "), |cff00ff00apply|r (" .. T("rotazione in Hekili") .. "), |cff00ff00glow on|off|r (" .. T("illuminazione dei tasti") .. "), |cff00ff00cd on|off|r (" .. T("numeri dei cooldown") .. "), |cff00ff00cd swipe on|off|r (" .. T("ombreggiatura") .. "), |cff00ff00zygor on|off|r (" .. T("segni talenti di Zygor") .. "), |cff00ff00dump|r (" .. T("controllo talenti") .. "), |cff00ff00minimap|r, |cff00ff00guida|r (" .. T("come si usa") .. "), |cff00ff00icone|r (" .. T("controllo icone") .. ").")
    end
end
