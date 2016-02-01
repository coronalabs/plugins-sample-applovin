
-- Abstract: AppLovin
-- Version: 1.0
-- Sample code is MIT licensed; see https://www.coronalabs.com/links/code/license
---------------------------------------------------------------------------------------

display.setStatusBar( display.HiddenStatusBar )

------------------------------
-- RENDER THE SAMPLE CODE UI
------------------------------
local sampleUI = require( "sampleUI.sampleUI" )
sampleUI:newUI( { theme="darkgrey", title="AppLovin", showBuildNum=true } )

------------------------------
-- CONFIGURE STAGE
------------------------------
display.getCurrentStage():insert( sampleUI.backGroup )
local mainGroup = display.newGroup()
display.getCurrentStage():insert( sampleUI.frontGroup )

----------------------
-- BEGIN SAMPLE CODE
----------------------

-- Require libraries/plugins
local widget = require( "widget" )
local applovin = require( "plugin.applovin" )

-- Set app font
local appFont = sampleUI.appFont

-- Preset the AppLovin SDK key (replace this with your own for testing/release)
-- This key must be generated within the AppLovin developer portal: https://www.applovin.com/manage
local sdkKey = "[YOUR-SDK-KEY]"

-- Set local variables
local setupComplete = false
local loadButton
local showButton

-- Create object to visually prompt action
local prompt = display.newPolygon( mainGroup, 62, 210, { 0,-12, 12,0, 0,12 } )
prompt:setFillColor( 0.8 )
prompt.alpha = 0


-- Function to prompt/alert user for setup
local function checkSetup()

	if ( system.getInfo( "environment" ) ~= "device" ) then return end

	if ( tostring(sdkKey) == "[YOUR-SDK-KEY]" ) then
		local alert = native.showAlert( "Important", 'Confirm that you have specified your unique AppLovin SDK key within "main.lua" on line 35. See our documentation for details on where to find this key within the AppLovin developer portal.', { "OK", "documentation" },
			function( event )
				if ( event.action == "clicked" and event.index == 2 ) then
					system.openURL( "https://docs.coronalabs.com/plugin/applovin/" )
				end
			end )
	else
		setupComplete = true
	end
end


-- Function to update button visibility/state
local function updateUI( params )

	-- Disable inactive buttons
	if ( params["disable"] ) then
		for i = 1,#params["disable"] do
			params["disable"][i]:setEnabled( false )
			params["disable"][i].alpha = 0.3
		end
	end

	-- Move/transition prompt
	if ( params["promptTo"] ) then
		transition.to( prompt, { y=params["promptTo"].y, alpha=1, time=400, transition=easing.outQuad } )
	end

	-- Enable new active buttons
	if ( params["enable"] ) then
		timer.performWithDelay( 400,
			function()
				for i = 1,#params["enable"] do
					params["enable"][i]:setEnabled( true )
					params["enable"][i].alpha = 1
				end
			end
		)
	end
end


-- Ad listener function
local function adListener( event )

	-- Exit function if user hasn't set up testing parameters
	if ( setupComplete == false ) then return end
	
	-- Successful initialization of the AppLovin plugin
	if ( event.phase == "init" ) then
		print( "AppLovin event: initialization successful" )
		updateUI( { enable={ loadButton }, disable={ showButton }, promptTo=loadButton } )

	-- An ad loaded successfully
	elseif ( event.phase == "loaded" ) then
		print( "AppLovin event: " .. tostring(event.type) .. " ad loaded successfully" )
		updateUI( { enable={ showButton }, disable={ loadButton }, promptTo=showButton } )

	-- The ad was displayed/played
	elseif ( event.phase == "displayed" or event.phase == "playbackBegan" ) then
		print( "AppLovin event: " .. tostring(event.type) .. " ad displayed" )
		updateUI( { disable={ showButton } } )

	-- The ad was closed/hidden
	elseif ( event.phase == "hidden" or event.phase == "playbackEnded" ) then
		print( "AppLovin event: " .. tostring(event.type) .. " ad closed/hidden" )
		updateUI( { enable={ loadButton }, disable={ showButton }, promptTo=loadButton } )

	-- The ad failed to load
	elseif ( event.phase == "failed" ) then
		print( "AppLovin event: " .. tostring(event.type) .. " ad failed to load" )
	end
end


-- Button handler function
local function onButtonRelease( event )

	if ( event.target.id == "load" ) then
		applovin.load()
	elseif ( event.target.id == "show" ) then
		applovin.show()
	end
	return true
end


-- Create buttons
loadButton = widget.newButton(
	{
		label = "load AppLovin ad",
		id = "load",
		shape = "rectangle",
		x = display.contentCenterX + 10,
		y = 210,
		width = 188,
		height = 32,
		font = appFont,
		fontSize = 16,
		fillColor = { default={ 0.16,0.36,0.56,1 }, over={ 0.16,0.36,0.56,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,0.8 } },
		onRelease = onButtonRelease
	})
loadButton:setEnabled( false )
loadButton.alpha = 0.3
mainGroup:insert( loadButton )

showButton = widget.newButton(
	{
		label = "show AppLovin ad",
		id = "show",
		shape = "rectangle",
		x = display.contentCenterX + 10,
		y = 260,
		width = 188,
		height = 32,
		font = appFont,
		fontSize = 16,
		fillColor = { default={ 0.16,0.36,0.56,1 }, over={ 0.16,0.36,0.56,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,0.8 } },
		onRelease = onButtonRelease
	})
showButton:setEnabled( false )
showButton.alpha = 0.3
mainGroup:insert( showButton )


-- Initially alert user to set up device for testing
checkSetup()

-- Init the Applovin plugin
applovin.init( adListener, { sdkKey=sdkKey, verboseLogging=false } )
