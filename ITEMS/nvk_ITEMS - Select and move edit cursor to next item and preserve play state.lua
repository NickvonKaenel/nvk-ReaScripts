-- @noindex
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    local playstate = reaper.GetPlayState()
    if playstate & 1 == 1 then -- if playback is on
        reaper.SelectAllMediaItems(0, false)
        reaper.UpdateArrange()
        reaper.Main_OnCommand(40434, 0) --  edit cursor to play cursor
        reaper.OnStopButton()
        reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        if playstate & 4 == 4 then
            reaper.CSurf_OnRecord()
        else
            reaper.OnPlayButton()
        end
    else
        reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
