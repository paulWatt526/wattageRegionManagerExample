local composer = require( "composer" )

system.activate( "multitouch" )
display.setStatusBar(display.HiddenStatusBar)
display.setDefault( "background", 0, 0, 0)

composer.gotoScene( "tileEngineScene" )