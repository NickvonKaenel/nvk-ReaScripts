-- @noindex
-- This script is a variation of the above, with the added feature of not selecting the same take twice in a row.
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
	for i = 0, r.CountSelectedMediaItems(0) - 1 do
		local item = r.GetSelectedMediaItem(0, i)
		RandomTakeMarkerOffset(item, true)
	end
	local s, e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
	if RESTART_PLAYBACK and r.GetPlayState() == 1 and s == e then
		r.Main_OnCommand(41173, 0) --cursor to start of items
		r.Main_OnCommand(1007, 0) --play?
	end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)