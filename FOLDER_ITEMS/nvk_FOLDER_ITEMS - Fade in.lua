-- @noindex
-- USER CONFIG --
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT ---
local r = reaper
local function fadein(item, cursorPos)
    if cursorPos > item.e then
        item.fadeinpos = item.e - defaultFadeLen
    elseif cursorPos < item.pos then
        item.fadeinlen = defaultFadeLen
    else
        item.fadeinpos = cursorPos
    end
    if not item.folder and FADE_OVERSHOOT then
        item:FadeOvershoot()
    end
end

local function get_vol_env(track)
    local env = r.GetTrackEnvelopeByName(track, 'Volume')
    if not env then
        r.Main_OnCommand(40406, 0) -- show volume env
        env = r.GetTrackEnvelopeByName(track, 'Volume')
    end
    if r.GetEnvelopeInfo_Value(env, 'I_TCPH_USED') == 0 then
        r.SetOnlyTrackSelected(track)
        r.Main_OnCommand(40406, 0) -- toggle track volume envelope visible
    end
    return env
end

local function fadein_auto(item)
    local itemFadeIn = item.fadeinlen >= item.len and item.len - 0.00001 or item.fadeinlen
    local itemFadeOut = item.fadeoutlen >= item.len and item.len - 0.00001 or item.fadeoutlen
    local itemFadeInDir = item.fadeindir * 0.75
    local itemFadeOutDir = item.fadeoutdir * 0.75
    if itemFadeOut == defaultFadeLen then itemFadeOut = 0 end
    if itemFadeIn == defaultFadeLen then itemFadeIn = 0 end
    local fadeInEnd = item.pos + itemFadeIn
    local fadeOutStart = item.pos + item.len - itemFadeOut
    local track = item.track.track
    local env = get_vol_env(track)
    local autoitemIdx = GetAutoitem(env, item.pos)
    if autoitemIdx then
        r.Main_OnCommand(40769, 0) -- unselect all tracks/items/env
        r.GetSetAutomationItemInfo(env, autoitemIdx, 'D_UISEL', 1, true)
        local retval, time, value, shape, tension, selected = r.GetEnvelopePointEx(env, autoitemIdx, 3)
        if retval then
            retval, time, value, shape, tension, selected = r.GetEnvelopePointEx(env, autoitemIdx, 2)
            if retval then
                itemFadeOut = item.e - time
                fadeOutStart = time
                itemFadeOutDir = tension
            end
        else
            retval, time, value, shape, tension, selected = r.GetEnvelopePointEx(env, autoitemIdx, 2)
            if retval then
                retval, time, value, shape, tension, selected = r.GetEnvelopePointEx(env, autoitemIdx, 1)
                itemFadeOutDir = tension
            end
        end
        r.Main_OnCommand(42086, 0) -- delete automation item
        r.SetOnlyTrackSelected(track)
    end
    if itemFadeIn > 0 or itemFadeOut > 0 then
        autoitemIdx = r.InsertAutomationItem(env, -1, item.pos, item.len)
        r.GetSetAutomationItemInfo(env, autoitemIdx, 'D_LOOPSRC', 0, true)
        r.DeleteEnvelopePointRangeEx(env, autoitemIdx, item.pos, item.pos + item.len)
        local fadeInCurve = itemFadeInDir == 0 and 0 or 5
        local fadeOutCurve = itemFadeOutDir == 0 and 0 or 5
        if itemFadeIn > 0 then
            r.InsertEnvelopePointEx(env, autoitemIdx, item.pos, 0, fadeInCurve,
                itemFadeInDir, 0, true)
            if fadeOutStart > fadeInEnd then
                r.InsertEnvelopePointEx(env, autoitemIdx, fadeInEnd, 1, 0, 0, 0, true)
            else
                r.InsertEnvelopePointEx(env, autoitemIdx, fadeInEnd, 1, fadeOutCurve, itemFadeOutDir, 0, true)
            end
        end
        if itemFadeOut > 0 then
            if fadeOutStart > fadeInEnd then
                r.InsertEnvelopePointEx(env, autoitemIdx, fadeOutStart, 1, fadeOutCurve, itemFadeOutDir, 0, true)
            end
            r.InsertEnvelopePointEx(env, autoitemIdx, item.pos + item.len - 0.000001, 0, 0, 0, 0, true)
        end
        r.Envelope_SortPointsEx(env, autoitemIdx)
    end
end

function Main()
    local item, cursorPos = SelectVisibleItemNearMouseCursor()
    if not item then return end
    item = Item(item)
    if item.folder then
        if FADE_FOLDER_ENVELOPE then
            item.fadeinpos = cursorPos
            fadein(item, cursorPos)
            fadein_auto(item)
            groupSelect(item.item)
            item.sel = true
            return
        else
            groupSelect(item.item)
        end
    end

    local items = Items()

    local init_fade_pos = items[1].fadeinpos

    for i, item in ipairs(items) do
        local doFade = FADE_CHILD_LATCH_ALL or i == 1
        if FADE_CHILD_LATCH_SMART then
            if item.fadeinpos < cursorPos or item.pos == items[1].pos or item.fadeinpos == init_fade_pos then
                doFade = true
            end
        else     -- default behavior, check if overlapping or shared edge
            if item.pos <= cursorPos or item.pos == items[1].pos then
                doFade = true
            end
        end
        if doFade then fadein(item, cursorPos) end
    end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
