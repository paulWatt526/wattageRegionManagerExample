local AnalogControlStick = require "analogControlStick"
local Composer = require( "composer" )
local FrameRateUI = require "frameRateUI"
local Physics = require "physics"
local TileEngine = require "plugin.wattageTileEngine"
local RegionManager = TileEngine.RegionManager

local scene = Composer.newScene()

local scaleFactor = 1.0
local physicsData = (require "tilePhysicsBodies").physicsData(scaleFactor)

-- -----------------------------------------------------------------------------------
-- This table represents a simple environment.  Replace this with
-- the model needed for your application.
-- -----------------------------------------------------------------------------------
local REGION_VALUE_TO_TILE_NAME_MAP = {
    [0] = "tiles_00",
    [1] = "tiles_01",
    [2] = "tiles_02",
    [3] = "tiles_03",
    [4] = "tiles_04",
    [5] = "tiles_05",
    [6] = "tiles_06",
    [7] = "tiles_07",
    [8] = "tiles_08",
    [9] = "tiles_09",
    [10] = "tiles_10",
    [11] = "tiles_11",
    [12] = "tiles_12",
    [13] = "tiles_13",
    [14] = "tiles_14"
}

local REGION_WIDTH_IN_TILES = 3
local REGION_HEIGHT_IN_TILES = 3
local BUFFER_TILE_LAYER_INDEX = 1
local ENTITY_LAYER_INDEX = 2

local VERTICAL_HALL_REGION = {
    {1,4,3},
    {1,4,3},
    {1,4,3}
}

local HORIZONTAL_HALL_REGION = {
    {2,2,2},
    {4,4,4},
    {0,0,0}
}

local CROSS_REGION = {
    { 5, 4, 12},
    { 4, 4,  4},
    {10, 4, 11}
}

local TILE_SIZE         = 128               -- Constant for the tile size
local BUFFER_LAYER_ROW_COUNT    = 180       -- Row count of the buffer layer
local BUFFER_LAYER_COLUMN_COUNT = 180       -- Column count of the buffer layer
local MAX_FORCE         = 500               -- The maximum force that will be applied to the player entity
local LINEAR_DAMPING    = 1                 -- Provides a little resistance to linear motion.

local tileEngine                            -- Reference to the tile engine
local lightingModel                         -- Reference to the lighting model
local tileEngineViewControl                 -- Reference to the UI view control
local regionManager                         -- Reference to the region manager
local controlStick                          -- Reference to the control stick
local playerEntityId                        -- ID used to interact with the player entity
local playerSprite                          -- Sprite for the player
local lastTime                              -- Used to track how much time passes between frames

local frameRateUI                           -- Used to show framerate

-- -----------------------------------------------------------------------------------
-- This will load in the example sprite sheet.  Replace this with the sprite
-- sheet needed for your application.
-- -----------------------------------------------------------------------------------
local spriteSheetInfo = require "tiles"
local spriteSheet = graphics.newImageSheet("tiles.png", spriteSheetInfo:getSheet())

-- -----------------------------------------------------------------------------------
-- A sprite resolver is required by the engine.  Its function is to create a
-- SpriteInfo object for the supplied key.  This function will utilize the
-- example sprite sheet.
-- -----------------------------------------------------------------------------------
local spriteResolver = {}
spriteResolver.resolveForKey = function(key)
    local name = REGION_VALUE_TO_TILE_NAME_MAP[key]
    local frameIndex = spriteSheetInfo:getFrameIndex(name)
    local frame = spriteSheetInfo.sheet.frames[frameIndex]
    local displayObject = display.newImageRect(spriteSheet, frameIndex, frame.width, frame.height)
    return {
        imageRect = displayObject,
        width = frame.width,
        height = frame.height
    }
end

local cameraX = 0
-- -----------------------------------------------------------------------------------
-- This will be called every frame.  It is responsible for setting the camera
-- positiong, updating the lighting model, rendering the tiles, and reseting
-- the dirty tiles on the lighting model.
-- -----------------------------------------------------------------------------------
local function onFrame(event)
    local camera = tileEngineViewControl.getCamera()
    local lightingModel = tileEngine.getActiveModule().lightingModel

    if lastTime ~= 0 then
        -- Determine the amount of time that has passed since the last frame and
        -- record the current time in the lastTime variable to be used in the next
        -- frame.
        local curTime = event.time
        local deltaTime = curTime - lastTime
        lastTime = curTime

        -- Get the direction vectors from the control stick
        local cappedPercentVector = controlStick.getCurrentValues().cappedDirectionVector

        -- If the control stick is currently being pressed, then apply the appropriate force
        if cappedPercentVector.x ~= nil and cappedPercentVector.y ~= nil then
            -- Determine the percent of max force to apply.  The magnitude of the vector from the
            -- conrol stick indicates the percentate of the max force to apply.
            local forceVectorX = cappedPercentVector.x * MAX_FORCE
            local forceVectorY = cappedPercentVector.y * MAX_FORCE
            -- Apply the force to the center of the player entity.
            playerSprite:applyForce(forceVectorX, forceVectorY, playerSprite.x, playerSprite.y)
        end

        -- Have the camera follow the player
        local playerX, playerY = regionManager.getEntityLocation(2, playerEntityId)
        local tileXCoord = playerX / TILE_SIZE
        local tileYCoord = playerY / TILE_SIZE
        regionManager.setCameraLocation(tileXCoord, tileYCoord)

        -- Update the lighting model passing the amount of time that has passed since
        -- the last frame.
        lightingModel.update(deltaTime)

        frameRateUI.update(deltaTime)
    else
        -- This is the first call to onFrame, so lastTime needs to be initialized.
        lastTime = event.time

        -- This is the initial position of the camera
        regionManager.setCameraLocation(1.5,1.5)

        -- Since a time delta cannot be calculated on the first frame, 1 is passed
        -- in here as a placeholder.
        lightingModel.update(1)
    end

    -- Render the tiles visible to the passed in camera.
    tileEngine.render(camera)

    -- The lighting model tracks changes, then acts on all accumulated changes in
    -- the lightingModel.update() function.  This call resets the change tracking
    -- and must be called after lightingModel.update().
    lightingModel.resetDirtyFlags()
end

local function createPhysicsObjects(regionTemplate, topRowOffset, leftColumnOffset)
    local physicsObjects = {}

    -- Physics objects will be added to the tile engine's master
    -- group, but will not be visible.
    local physicsGroup = tileEngine.getMasterGroup()

    -- Iterate through the rows and columns of the region template
    -- The template dimensions must match the dimensions specified
    -- to the RegionManager.
    for regionRow=1,REGION_HEIGHT_IN_TILES do
        for regionCol=1,REGION_WIDTH_IN_TILES do

            -- Obtain the value of the region tile
            local value = regionTemplate[regionRow][regionCol]

            -- Check to see if any physics bodies are associated with this tile value
            local firstPhysicsBody = physicsData:get(REGION_VALUE_TO_TILE_NAME_MAP[value])
            if firstPhysicsBody ~= nil then

                -- This tile value has physics bodies
                -- Calculate the center x, y coordinate where the physics
                -- body will be placed.  Use the offset values to properly
                -- place the body.  NOTE: regionCol and regionRow are reduced
                -- by 0.5 so that x and y reflect the center of the tile.
                local x = (leftColumnOffset + regionCol - 0.5) * TILE_SIZE
                local y = (topRowOffset + regionRow - 0.5) * TILE_SIZE

                -- Create an invisible displayObject to attach physics data to
                local physicsObject = display.newRect(
                    physicsGroup,
                    x,
                    y,
                    TILE_SIZE,
                    TILE_SIZE)
                physicsObject.isVisible = false

                -- Add the physics body information
                Physics.addBody(
                    physicsObject,
                    "static",
                    physicsData:get(REGION_VALUE_TO_TILE_NAME_MAP[value]))

                -- Add the physics objects to the collection
                table.insert(physicsObjects, physicsObject)
            end
        end
    end

    return physicsObjects
end

-- -----------------------------------------------------------------------------------
-- EndlessWorldRegionManager listener functions
-- -----------------------------------------------------------------------------------
function scene.getRegion(params)
    local absoluteRegionRow = params.absoluteRegionRow
    local absoluteRegionCol = params.absoluteRegionCol
    local topRowOffset = params.topRowOffset
    local leftColumnOffset = params.leftColumnOffset

    if absoluteRegionRow % 2 == 0 and absoluteRegionCol % 2 == 0 then
        local regionTemplate = CROSS_REGION
        local physicsObjects = createPhysicsObjects(regionTemplate, topRowOffset, leftColumnOffset)

        return {
            physicsObjects = physicsObjects,
            tilesByLayerIndex = {
                regionTemplate
            }
        }
    end

    if absoluteRegionRow % 2 == 0 then
        local regionTemplate = HORIZONTAL_HALL_REGION
        local physicsObjects = createPhysicsObjects(regionTemplate, topRowOffset, leftColumnOffset)

        return {
            physicsObjects = physicsObjects,
            tilesByLayerIndex = {
                regionTemplate
            }
        }
    end

    if absoluteRegionCol % 2 == 0 then
        local regionTemplate = VERTICAL_HALL_REGION
        local physicsObjects = createPhysicsObjects(regionTemplate, topRowOffset, leftColumnOffset)

        return {
            physicsObjects = physicsObjects,
            tilesByLayerIndex = {
                regionTemplate
            }
        }
    end

    return {}
end

-- -----------------------------------------------------------------------------------
-- This listener function is called when a region is no longer valid and
-- has been released.  Anything that was allocated and attached to the
-- regionData in the getRegion() function must be released here.  In this
-- example, the physics objects created in getRegion() need to be cleaned
-- up.
-- -----------------------------------------------------------------------------------
function scene.regionReleased(regionData)
    if regionData ~= nil and regionData.physicsObjects ~= nil then
        local physicsObjects = regionData.physicsObjects

        -- Release the physics objects, they are no longer valid.
        for i=1,#physicsObjects do
            physicsObjects[i]:removeSelf()
        end
        regionData.physicsObjects = nil
    end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )
    local sceneGroup = self.view

    -- Start physics
    Physics.start()
    -- This example does not want any gravity, set it to 0.
    Physics.setGravity(0,0)
    -- Set scale (determined by trial and error for what feels right)
    Physics.setScale(32)

    -- Create a group to act as the parent group for all tile engine DisplayObjects.
    local tileEngineLayer = display.newGroup()
    sceneGroup:insert(tileEngineLayer)

    -- Create an instance of TileEngine.
    tileEngine = TileEngine.Engine.new({
        parentGroup=tileEngineLayer,
        tileSize=TILE_SIZE,
        spriteResolver=spriteResolver,
        compensateLightingForViewingPosition=false,
        hideOutOfSightElements=false
    })

    -- The tile engine needs at least one Module.  It can support more than
    -- one, but this template sets up only one which should meet most use cases.
    -- A module is composed of a LightingModel and a number of Layers
    -- (TileLayer or EntityLayer).  An instance of the lighting model is created
    -- first since it is needed to instantiate the Module.
    lightingModel = TileEngine.LightingModel.new({
        isTransparent = function() return true end,
        isTileAffectedByAmbient = function() return true end,
        useTransitioners = false,
        compensateLightingForViewingPosition = false
    })

    -- Instantiate the module.
    local module = TileEngine.Module.new({
        name="moduleMain",
        rows= BUFFER_LAYER_ROW_COUNT,
        columns= BUFFER_LAYER_COLUMN_COUNT,
        lightingModel=lightingModel,
        losModel=TileEngine.LineOfSightModel.ALL_VISIBLE
    })

    -- Next, create the buffer layer
    local bufferLayer = TileEngine.TileLayer.new({
        rows = BUFFER_LAYER_ROW_COUNT,
        columns = BUFFER_LAYER_COLUMN_COUNT
    })
    bufferLayer.setLightingMode(TileEngine.LayerConstants.LIGHTING_MODE_NONE)
    bufferLayer.resetDirtyTileCollection()

    -- Add the layer to the module at index 1 (indexes start at 1, not 0).  Set
    -- the scaling delta to zero.
    module.insertLayerAtIndex(bufferLayer, BUFFER_TILE_LAYER_INDEX, 0)

    -- Next create the entity layer for the player token
    -- Add an entity layer for the player
    local entityLayer = TileEngine.EntityLayer.new({
        tileSize = TILE_SIZE,
        spriteResolver = spriteResolver
    })

    -- Add the entity layer to the module at index 2 (indexes start at 1, not 0).  Set
    -- the scaling delta to zero.
    module.insertLayerAtIndex(entityLayer, ENTITY_LAYER_INDEX, 0)

    -- Add the module to the engine.
    tileEngine.addModule({module = module})

    -- Set the module as the active module.
    tileEngine.setActiveModule({
        moduleName = "moduleMain"
    })

    -- To render the tiles to the screen, create a ViewControl.  This example
    -- creates a ViewControl to fill the entire screen, but one may be created
    -- to fill only a portion of the screen if needed.
    tileEngineViewControl = TileEngine.ViewControl.new({
        parentGroup = sceneGroup,
        centerX = display.contentCenterX,
        centerY = display.contentCenterY,
        pixelWidth = display.actualContentWidth,
        pixelHeight = display.actualContentHeight,
        tileEngineInstance = tileEngine
    })

    -- Now create the endless world region manager.  Notice that
    -- no tiles have been added to the buffer layer.  This manager
    -- will utilize the listener passed in to query for regions of
    -- tiles when they are needed and will also inform the listener
    -- when regions have been released.
    regionManager = RegionManager.new({
        regionWidthInTiles = REGION_WIDTH_IN_TILES,
        regionHeightInTiles = REGION_HEIGHT_IN_TILES,
        renderRegionWidth = 5,
        renderRegionHeight = 3,
        tileSize = 128,
        tileLayersByIndex = { [1] = bufferLayer },
        entityLayersByIndex = { [2] = entityLayer },
        camera = tileEngineViewControl.getCamera(),
        listener = scene
    })

    -- Add the player entity to the entity layer
    local spriteInfo
    playerEntityId, spriteInfo = entityLayer.addEntity(14)

    -- Store a reference to the player entity sprite.  It will be
    -- used to apply forces to and to align the camera with.
    playerSprite = spriteInfo.imageRect

    -- Make the player sprite a physical entity
    Physics.addBody( playerSprite, "dynamic", physicsData:get(REGION_VALUE_TO_TILE_NAME_MAP[14]) )

    -- Handle the player sprite as a bullet to prevent passing through walls
    -- when moving very quickly.
    playerSprite.isBullet = true

    -- This will prevent the player from "sliding" too much.
    playerSprite.linearDamping = LINEAR_DAMPING

    -- Move the player entity to the center of the middle cross.
    regionManager.centerEntityOnTile(2, playerEntityId, 1, 1)

    local radius = 150
    controlStick = AnalogControlStick.new({
        parentGroup = sceneGroup,
        centerX = display.screenOriginX + radius,
        centerY = display.screenOriginY + display.viewableContentHeight - radius,
        centerDotRadius = 0.1 * radius,
        outerCircleRadius = radius
    })

    frameRateUI = FrameRateUI.new(sceneGroup)
end


-- show()
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

        -- Set the lastTime variable to 0.  This will indicate to the onFrame event handler
        -- that it is the first frame.
        lastTime = 0

        -- Register the onFrame event handler to be called before each frame.
        Runtime:addEventListener( "enterFrame", onFrame )
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
    end
end


-- hide()
function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)

        -- Remove the onFrame event handler.
        Runtime:removeEventListener( "enterFrame", onFrame )
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
    end
end


-- destroy()
function scene:destroy( event )

    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view

    -- Set the reference to the regionManager to nil
    regionManager = nil

    -- Destroy the tile engine instance to release all of the resources it is using
    tileEngine.destroy()
    tileEngine = nil

    -- Destroy the ViewControl to release all of the resources it is using
    tileEngineViewControl.destroy()
    tileEngineViewControl = nil

    -- Destroy the control stick
    controlStick.destroy()
    controlStick = nil

    -- Set the reference to the lighting model to nil.
    lightingModel = nil
end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene