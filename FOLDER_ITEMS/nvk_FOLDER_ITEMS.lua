--[[
Description: nvk_FOLDER_ITEMS
Version: 2.2.2
About:
    # nvk_FOLDER_ITEMS

    nvk_FOLDER_ITEMS is a collection of scripts which are used for a quick and flexible workflow for managing and rendering assets using blank items created on folder tracks that act as regions for items.
Author: nvk
Links:
    Store Page https://gum.co/nvk_WORKFLOW
    User Guide https://nvk.tools/doc/nvk_workflow
Changelog:
    2.2.2
        + Improvement: Mousewheel pitch shift now only creates single undo point
        + Rename: manually adding underscore/hyphen at the end of the name will now not get replaced (allowing for names like "My Sound_01")
        + Rename: separator option added to specify what character to use for separating name and number
        + Reposition: change time with mousewheel over input box
        + Settings: new options for overshoot volume envelopes on fades. Previous "Write volume automation" setting changed to Fade->Folder items: Track. Hover tooltips for more info.
        - Fixed: crash when using clean up renders option with track in renders folder selected
    2.2.1
        - Fixed: Deselect non-folder items still not working properly with nvk_FOLDER_ITEMS.lua when used with a hotkey and a single foder item selected
    2.2.0
        + Numpad Enter now works as enter key for scripts with UI
        - Fixed: Remove script not working with hidden tracks
        + Can specify paths relative to the project location in copy directories
        - Fixed: Deselect non-folder items not working properly with nvk_FOLDER_ITEMS.lua when used with a hotkey
        + Replacing top-level folder items only settings with drop down (add setting to only create bottom-level folder items)
        + New hotkeys for repositioning script: can use number keys to instantly change seconds of reposition time, [T] to change time unit, and [F] to change repositioning from start/end of item.
        - Fixed: the first time you tab in the reposition script it correctly focuses the time input
        - Fixed: bugs with repositioning script when using hotkeys while changing preset name
    2.1.2
        - Fixed: Renaming reposition presets bug
    2.1.1
        - Fixed: Crash when opening repositioning script the first time with items selected
    2.1.0
        + Reposition presets: create repositioning presets with the Reposition script and assign them to hotkeys with the preset scripts!
    2.0.29
        - Fixed: Incorrect display of leading zeros when switching tabs in folder items settings
    2.0.28
        - Fixed: Trim scripts not working properly on takes with playrate changes
    2.0.27
        + Improved: better handling of multiple numbers in item names
        + Add new items to existing folder script now compatible with v2 user settings
        - Fixed: Mouse modifier to toggle track visibility not grouping items properly with new "hidden" track setting
    2.0.26
        - Fixed: Trim scripts not working properly with hidden tracks in Reaper 7
    2.0.25
        - Fixed: item colors not changing region colors properly in certain situations
        - Fixed: crash when adding new items to a folder track with certain region color settings
        - Fixed: grouping items not working properly with the the new "hidden" track setting in Reaper 7
        - Fixed: unable to select regions in region render matrix with certain region color settings
        + Added: Add new items to existing folder no longer removed
Provides:
    **/*.dat
    **/*.otf
    [windows] Data/curl/*.*
    [main] *.lua
--]]
-- SETUP --
local is_new_value, filename, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()
isDefer = true
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local function Exit()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    ClearMarkers()
end

local prevProjState, projUpdate, prevProj
local r = reaper

local function Main()
    local context = r.GetCursorContext()
    local mouseState = r.JS_Mouse_GetState(0x00000001)
    local projState = r.GetProjectStateChangeCount(0)
    if projState ~= prevProjState then
        if r.HasExtState('nvk_FOLDER_ITEMS', 'projUpdateFreeze') then
            r.DeleteExtState('nvk_FOLDER_ITEMS', 'projUpdateFreeze', true)
        else
            projUpdate = true
        end
        prevProjState = projState
    end
    local curProj = r.EnumProjects(-1)
    local settingsChanged = r.HasExtState('nvk_FOLDER_ITEMS', 'settingsChanged')
    if curProj ~= prevProj or settingsChanged then
        prevProj = curProj
        r.DeleteExtState('nvk_FOLDER_ITEMS', 'settingsChanged', true)
        LoadSettings()
        projUpdate = true
        SETTINGS_LOADED = true
        FolderItemCleanup()
    else
        SETTINGS_LOADED = false
    end
    local itemCount = r.CountSelectedMediaItems(0)
    if itemCount == 1 and context == 1 and autoSelect and mouseState == 1 then -- if mouse down
        GroupSelectCheck(r.GetSelectedMediaItem(0, 0))
    elseif projUpdate and mouseState == 0 then                                 -- if mouse is not down
        if autoSelect and context >= 0 then
            for i = 0, itemCount - 1 do
                GroupSelectCheck(r.GetSelectedMediaItem(0, i))
            end
        end
    end
    if projUpdate and itemCount == r.CountSelectedMediaItems(0) then
        if disableFolderItems then
            if settingsChanged then
                ClearMarkers()
            end
        else
            FolderItems.Fix(true)
        end
        projUpdate = false
    end
    scr.init = nil
    r.defer(Main)
end

if r.APIExists('JS_Mouse_GetState') and r.APIExists('CF_GetClipboard') then
    r.SetToggleCommandState(sectionID, cmdID, 1)
    r.RefreshToolbar2(sectionID, cmdID)
    r.defer(Main)
    r.atexit(Exit)
else
    if not r.APIExists('JS_Mouse_GetState') then
        r.ShowMessageBox('Please install js_ReaScript API via ReaPack before using script', scr.name, 0)
        if r.ReaPack_GetRepositoryInfo and r.ReaPack_GetRepositoryInfo('ReaTeam Extensions') then
            r.ReaPack_BrowsePackages([[^"js_ReaScriptAPI: API functions for ReaScripts"$ ^"ReaTeam Extensions"$]])
        end
    end
    if not r.APIExists('CF_GetClipboard') then
        r.ShowMessageBox('Please install the latest version of SWS Extension from:\nhttps://sws-extension.org/', scr
            .name, 0)
    end
end
