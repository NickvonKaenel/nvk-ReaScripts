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
function Main()
    if r.CountSelectedMediaItems(0) > 0 then
        if r.HasExtState('nvk_TAKES', 'take_name') then
            local str = r.GetExtState('nvk_TAKES', 'take_name')
            local i = 0
            for name in str:gmatch('[^\n]+') do
                local item = r.GetSelectedMediaItem(0, i)
                if not item then break end
                local take = r.GetActiveTake(item)
                if take then
                    r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', name, true)
                end
                i = i + 1
            end
        end
    end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
