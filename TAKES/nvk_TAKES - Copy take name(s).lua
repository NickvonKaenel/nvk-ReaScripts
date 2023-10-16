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

if r.CountSelectedMediaItems(0)  == 0 then return end
function Main()
    local str = ''
    for i = 1, r.CountSelectedMediaItems(0) do
        local item = r.GetSelectedMediaItem(0, i - 1)
        local take = r.GetActiveTake(item)
        local takeName = r.GetTakeName(take)
        if takeName then
            str = str .. takeName .. '\n'
        end
    end
    r.SetExtState('nvk_TAKES', 'take_name', str, false)
    r.CF_SetClipboard(StripNumbersAndExtensions(str))
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
