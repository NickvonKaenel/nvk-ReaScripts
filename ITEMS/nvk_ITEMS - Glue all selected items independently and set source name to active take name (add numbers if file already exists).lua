-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a, b)
    if not b then
        b = ".dat"
    end
    local c = scrPath .. "Data" .. sep .. a .. b;
    return c
end
OS = reaper.GetOS()
sep = OS:match "Win" and "\\" or "/"
scrPath, scrName = ({reaper.get_action_context()})[2]:match "(.-)([^/\\]+).lua$"
loadfile(GetPath "functions")()
if not functionsLoaded then
    return
end
-- SCRIPT --

function copyFile(file, newFile)
    local f = io.open(file, "rb")
    local content = f:read("*a")
    f:close()
    local f = io.open(newFile, "wb")
    f:write(content)
    f:close()
end


function renameFile(file, newName)
    if newName:match('(.+)(%..+)') then -- if newName has extension
        newName = newName:match('(.+)(%..+)')
    end
    local path, name, ext = file:match('^(.+)[\\/](.+)(%..+)$')
    local newFile = path .. sep .. newName
    if reaper.file_exists(newFile .. ext) then
        newFile = newFile .. "_"
        local i = 1
        while true do
            num = string.format("%03d", tostring(i))
            if not reaper.file_exists(newFile .. num .. ext) then
                break
            end
            i = i + 1
        end
        newFile = newFile .. num
    end
    copyFile(file, newFile .. ext)
    return newFile .. ext
end

function RenameTakeSource(take, name)
    local src = reaper.GetMediaItemTake_Source(take)
    local file = reaper.GetMediaSourceFileName(src)
    local newFile = renameFile(file, name)
    if newFile then
        reaper.BR_SetTakeSourceFromFile(take, newFile, false)
    end
end

function Main()
    local items = {}
    local newItems = {}
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        table.insert(items, reaper.GetSelectedMediaItem(0, i))
    end
    for i, item in ipairs(items) do
        reaper.SelectAllMediaItems(0, false)
        reaper.SetMediaItemSelected(item, true)
        local take = reaper.GetActiveTake(item)
        local name = reaper.GetTakeName(take)
        if reaper.TakeIsMIDI(take) then
            reaper.Main_OnCommand(40361, 0) -- Apply fx to items (mono)
        end
        reaper.Main_OnCommand(42432, 0) -- Glue items
        local newItem = reaper.GetSelectedMediaItem(0, 0)
        newItems[i] = newItem
        local newTake = reaper.GetActiveTake(newItem)
        reaper.GetSetMediaItemTakeInfo_String(newTake, "P_NAME", name, true)
        RenameTakeSource(newTake, name)
    end
    for i = 1, #newItems do
        reaper.SetMediaItemSelected(newItems[i], true)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
