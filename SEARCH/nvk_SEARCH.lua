--[[
Description: nvk_SEARCH
Version: 1.6.4
About:
  # nvk_SEARCH

  This script is used to quickly search for FX, chains, actions, projects, etc in Reaper. Requires REAPER 7 or higher.
Author: nvk
Links:
  REAPER forum thread https://forum.cockos.com/showthread.php?t=286729
  User Guide: https://nvk.tools/doc/nvk_SEARCH
Changelog:
  + 1.6.4
    - Fixed: when adding fx from sidebar to current selected folder, the folder was not being updated
  + 1.6.3
    - Fixed: incorrect link to forum thread
  + 1.6.2
    - Fixed: cleared recent projects list was still showing up in results
  + 1.6.1
    - Improved speed of adding multiple fx in a row with enter
  + 1.6.0
    + New feature: add custom project paths in preferences
      + Paths will be scanned recursively for .rpp files on add. They can be rescanned manually. Recent project files will still show up in the results so this won't need to be done often.
      + Scanned projects can be sorted by name or last modified date (note: last modified date can slow down startup times if there are a lot of projects)
      + When adding a path, a new folder will be created with that project path in the sidebar. FYI, if removed from this folder, it may be re-added next time a project path is added or removed.
      + Recent projects will show up first in the results
    + Rearranged preferences to make better use of space and fit new projects feature
    + Preferences no longer behaves as a popup, and must be manually closed. It will reopen if the script is restarted while it is open.
    + Tooltips when hovering over folders and project paths that are too long to display
    - Fixed: Esc key was not closing the keyboard shortcut popup
  + 1.5.3
    - Fixed: Crash with project names that are just .rpp
  + 1.5.2
    - Crash when adding fx
  + 1.5.1
    - Fix for possible crash with some project names
  + 1.5.0
    + Multiple selection of items allowing for adding multiple FX at once or dragging/removing multiple results from a folder
    + New options: open projects in new tab, hide project patch, keep search on folder change
    + New context menu option: Open project/track template in new tab
    + Display user keyboard shortcuts in context menu
    + FX duplicates are now removed in order of fx display options
    + VST3 and VST3i are now separate from VST and VSTi
    + Projects added to folders are now saved permanently
    - Fixed: certain C++ extensions could cause actions to not be scanned properly
    + Rearranged preferences
    + Favorites section: favorites can be displayed at the top in their own section regardless of result type
    + Favorites can now be rearranged with drag and drop
    + Support for matching multiple words in quotes
    + Menu bar: show fx window after insertion
    + Option to disable certain results from being displayed with alt-click
    + If filter is set to an excluded result type, it will show the results regardless of global settings, allowing you to temporarily find results that are normally hidden
    + Alt fx add (insert fx for non-inst fx and create midi track for inst fx) with alt + enter or alt + drag to track (can alt-click from sidebar fx list or alt-double click from results list)
    + FX can be added to master track by dragging directly on the master track
    + To add fx to monitor fx chain, hold alt while dragging the fx to the master track
    + Context menu to add fx to master track or monitor fx chain
    + More compact keyboard shortcuts name display
    ! Toggle favorites mouse click modifier changed to ctrl/cmd+shift instead of alt
    + Exclude filters from search with hyphen prefix i.e. "-f" will exclude fx from the results
  + 1.0.3
    + Drag and drop all valid results to folders, not just FX
    + New option: reveal hidden tracks when selected in results list
  + 1.0.2
    - Fixed: Crash on load for certain systems due to actions.dat loading out of order
  + 1.0.1
    - Fixed: Duplicate tooltip on hover esc always closes script option
    - Fixed: AU plugins not adding properly
  + 1.0.0
    + Initial release
Provides:
  **/*.dat
  **/*.otf
  [main] *.lua
--]]
SCRIPT_FOLDER = 'search'
r = reaper
if not r.APIExists('EnumInstalledFX') then
    r.MB('Please update to REAPER 7 or higher to use the script.', 'nvk_SEARCH', 0)
    return
end
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
