-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    retval, retvals_csv = reaper.GetUserInputs("Select Takes Containing Text", 1, "Text", "")
    if retval then
        reaper.Main_OnCommand(40289, 0) -- unselect all items
        for i = 0, reaper.CountMediaItems(0) - 1 do
            item = reaper.GetMediaItem(0, i)
            take = reaper.GetActiveTake(item)
            if take then
                name = reaper.GetTakeName(take)
                name = string.upper(name)
                retvals_csv = string.upper(retvals_csv)
                if string.find(name, retvals_csv) then
                    reaper.SetMediaItemSelected(item, 1)
                end
            end
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
