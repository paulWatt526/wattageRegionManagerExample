--
-- created with TexturePacker (http://www.codeandweb.com/texturepacker)
--
-- $TexturePacker:SmartUpdate:997344122c52ff8f384dbf444ed600d2:b61ce68906ee7b80bda4c8921705014d:f4492607ea55a754477543692c89a688$
--
-- local sheetInfo = require("mysheet")
-- local myImageSheet = graphics.newImageSheet( "mysheet.png", sheetInfo:getSheet() )
-- local sprite = display.newSprite( myImageSheet , {frames={sheetInfo:getFrameIndex("sprite")}} )
--

local SheetInfo = {}

SheetInfo.sheet =
{
    frames = {
    
        {
            -- tiles_00
            x=1,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_01
            x=131,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_02
            x=261,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_03
            x=391,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_04
            x=521,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_05
            x=651,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_06
            x=781,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_07
            x=911,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_08
            x=1041,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_09
            x=1171,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_10
            x=1301,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_11
            x=1431,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_12
            x=1561,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_13
            x=1691,
            y=1,
            width=128,
            height=128,

        },
        {
            -- tiles_14
            x=1821,
            y=1,
            width=128,
            height=128,

        },
    },
    
    sheetContentWidth = 1950,
    sheetContentHeight = 130
}

SheetInfo.frameIndex =
{

    ["tiles_00"] = 1,
    ["tiles_01"] = 2,
    ["tiles_02"] = 3,
    ["tiles_03"] = 4,
    ["tiles_04"] = 5,
    ["tiles_05"] = 6,
    ["tiles_06"] = 7,
    ["tiles_07"] = 8,
    ["tiles_08"] = 9,
    ["tiles_09"] = 10,
    ["tiles_10"] = 11,
    ["tiles_11"] = 12,
    ["tiles_12"] = 13,
    ["tiles_13"] = 14,
    ["tiles_14"] = 15,
}

function SheetInfo:getSheet()
    return self.sheet;
end

function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name];
end

return SheetInfo
