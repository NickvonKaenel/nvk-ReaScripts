--[[
Description: nvk_LOOPMAKER
Version: 2.1.1
About:
    # nvk_LOOPMAKER
    nvk_LOOPMAKER Creates perfect zero-crossing loops out of selected items. If Loop Count is set to a number higher than 1, it will create multiple loops out of a single item that can be played back to back with sample accurate transitions.
Author: nvk
Links:
    Store Page https://store.nvk.tools/l/nvk_LOOPMAKER
    User Guide https://nvk.tools/doc/nvk_loopmaker
Changelog:
    2.1.1
        + Refactoring debugging code
    2.1.0
        + Pin button to allow script to remain open. Processed loops are unselected after applying.
        + New action: Apply (keep open)
        + UI improvements/changes to account for pin button
    2.0.2
        - Fixed: author name in reapack description
    2.0.1
        - Fixed: possible crash on load with certain machines
    2.0.0
Provides:
    **/*.dat
    **/*.otf
    [main] *.lua
--]]
SCRIPT_FOLDER = 'loopmaker'
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')