-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --

function GetItemPosition(item)
    local s = r.GetMediaItemInfo_Value(item, "D_POSITION")
    local e = s + r.GetMediaItemInfo_Value(item, "D_LENGTH")
    return s, e
end

function Main()
    local items = SaveSelectedItems()
    r.Main_OnCommand(40796, 0) -- Clear take preserve pitch
    for i, item in ipairs(items) do
        local take = r.GetActiveTake(item)
        local itemLength = r.GetMediaItemInfo_Value(item, "D_LENGTH")
        local playrate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        for i = r.GetTakeNumStretchMarkers(take) - 1, 0, -1 do
            r.DeleteTakeStretchMarkers(take, i)
        end
        r.SetTakeStretchMarker(take, -1, 0)
        r.SetTakeStretchMarker(take, -1, itemLength*playrate)
    end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
