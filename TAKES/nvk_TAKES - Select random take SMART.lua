-- @noindex
-- USER CONFIG --
restartPlayback = true --if true will restart playback to start of items when playing unless time selection
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		local item = reaper.GetSelectedMediaItem(0, i)
		RandomTakeMarkerOffset(item)
	end
	local s, e = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
	if restartPlayback and reaper.GetPlayState() == 1 and s == e then
		reaper.Main_OnCommand(41173, 0) --cursor to start of items
		reaper.Main_OnCommand(1007, 0) --play?
	end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)