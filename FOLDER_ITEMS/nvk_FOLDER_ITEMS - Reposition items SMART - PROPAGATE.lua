-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
	TrackDoubleClick()
	GetItemsSnapOffsetsAndRemove()
	RepositionSelectedItemsSMART()
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_RS6fa1efbf615b0c385fc6bb27ca7865918dfc19a6"), 0) --nvk_PROPAGATE
	RestoreItemsSnapOffsets()
	reaper.Main_OnCommand(40290, 0) --Time selection: Set time selection to items
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)