-- @noindex
local is_new, name, sec, cmd, rel, res, val = reaper.get_action_context() -- has to be called first to get proper action context for mousewheel
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- USER CONFIG --
PITCH_AMOUNT = -1               -- semitones to pitch up or down
CLEAR_PRESERVEPITCH = true     -- clear preserve pitch on items
SELECT_ITEM_UNDER_MOUSE = true -- select item under mouse
-- SCRIPT --

local time

function Main(first_run)
    if not first_run then
        is_new, name, sec, cmd, rel, res, val = r.get_action_context()
    end
    if is_new or first_run then
        time = r.time_precise()
        if SELECT_ITEM_UNDER_MOUSE then
            local x, y = r.GetMousePosition()
            local item = Item(r.GetItemFromPoint(x, y, false))
            if item then
                UnselectAllItems()
                item.sel = true
                if item.folder then
                    item.track:Children(true):Items(item).sel = true
                end
            end
        end
        local items = Items()
        if #items == 0 then return end
        local playrate_mod = 2 ^ (PITCH_AMOUNT * (val > 0 and 1 or -1) / 12)
        if #items == 1 then
            items:PlayratePitch(playrate_mod, CLEAR_PRESERVEPITCH)
        else
            Columns(items):PlayratePitch(playrate_mod, CLEAR_PRESERVEPITCH)
        end
    end
    if r.time_precise() < time + 0.5 then
        r.defer(Main)
    else
        r.Undo_OnStateChange(scr.name)
    end
end

r.Undo_BeginBlock()
Main(true)
