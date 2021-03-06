
-- Abstract: AppLovin
-- Version: 1.1
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
local applovin = require( "plugin.applovin" )
local widget = require( "widget" )

-- Set app font
local appFont = sampleUI.appFont

-- Preset the AppLovin SDK key (replace this with your own for testing/release)
-- This key must be generated within the AppLovin developer portal: https://www.applovin.com/manage
local sdkKey = "[YOUR-SDK-KEY]"

-- Set local variables
local setupComplete = false
local useRewarded = false
local alertRewarded = true
local loadButton
local showButton

-- Create asset image sheet
local assets = graphics.newImageSheet( "assets.png",
	{
		frames = {
			{ x=0, y=0, width=35, height=35 },
			{ x=0, y=35, width=35, height=35 },
		},
		sheetContentWidth=35, sheetContentHeight=70
	}
)

-- Create object to visually prompt action
local prompt = display.newPolygon( mainGroup, 142, 170, { 0,-12, 12,0, 0,12 } )
prompt:setFillColor( 0.8 )
prompt.alpha = 0

-- Create spinner widget for indicating ad status
local spinner = widget.newSpinner( { x=display.contentCenterX, y=275, deltaAngle=10, incrementEvery=10 } )
mainGroup:insert( spinner )
spinner.alpha = 0


-- Function to manage spinner appearance/animation
local function manageSpinner( action )
	if ( action == "show" ) then
		spinner:start()
		transition.cancel( "spinner" )
		transition.to( spinner, { alpha=1, tag="spinner", time=((1-spinner.alpha)*320), transition=easing.outQuad } )
	elseif ( action == "hide" ) then
		transition.cancel( "spinner" )
		transition.to( spinner, { alpha=0, tag="spinner", time=((1-(1-spinner.alpha))*320), transition=easing.outQuad,
			onComplete=function() spinner:stop(); end } )
	end
end


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
		manageSpinner( "hide" )

	-- The ad was displayed/played
	elseif ( event.phase == "displayed" or event.phase == "playbackBegan" ) then
		print( "AppLovin event: " .. tostring(event.type) .. " ad displayed" )
		updateUI( { disable={ showButton } } )

	-- The ad was closed/hidden
	elseif ( event.phase == "hidden" or event.phase == "playbackEnded" ) then
		print( "AppLovin event: " .. tostring(event.type) .. " ad closed/hidden" )
		updateUI( { enable={ loadButton }, disable={ showButton }, promptTo=loadButton } )

	-- The user clicked/tapped an ad
	elseif ( event.phase == "clicked" ) then
		print( "AppLovin event: " .. tostring(event.type) .. " ad clicked/tapped" )

	-- The ad failed to load
	elseif ( event.phase == "failed" ) then
		print( "AppLovin event: " .. tostring(event.type) .. " ad failed to load" )
		manageSpinner( "hide" )

	-- The user declined to view a rewarded/incentivized video ad
	elseif ( event.phase == "declinedToView" ) then
		print( "AppLovin event: user declined to view " .. tostring(event.type) .. " ad" )
		updateUI( { enable={ loadButton }, disable={ showButton }, promptTo=loadButton } )

	-- The user viewed a rewarded/incentivized video ad
	elseif ( event.phase == "validationSucceeded" ) then
		print( "AppLovin event: " .. tostring(event.type) .. " ad viewed and reward approved by AppLovin server" )
		local alert = native.showAlert( "Note", "AppLovin reward of " .. tostring(event.data.amount) .. " " .. tostring(event.data.currency) .. " registered!", { "OK" } )
		updateUI( { disable={ showButton } } )

	-- The incentivized/rewarded video ad and/or reward exceeded quota, failed, or was rejected
	elseif ( event.phase == "validationExceededQuota" or event.phase == "validationFailed" or event.phase == "validationRejected" ) then
		print( "AppLovin event: " .. tostring(event.type) .. " ad and/or reward exceeded quota, failed, or was rejected" )
	end
end


-- Button handler function
local function uiEvent( event )

	if ( event.target.id == "load" ) then
		if ( useRewarded == true ) then
			applovin.load( "rewardedVideo" )
		else
			applovin.load( "interstitial" )
		end
		manageSpinner( "show" )
	elseif ( event.target.id == "show" ) then
		if ( useRewarded == true and applovin.isLoaded( "rewardedVideo" ) ) then
			applovin.show( "rewardedVideo" )
		elseif ( useRewarded == false and applovin.isLoaded( "interstitial" ) ) then
			applovin.show( "interstitial" )
		end
	elseif ( event.target.id == "useRewarded" ) then
		if ( event.target.isOn == true ) then
			useRewarded = true
			-- Initially alert for incentivized/rewarded setup
			if ( alertRewarded == true ) then
				alertRewarded = false
				local alert = native.showAlert( "Note", 'To receive incentivized/rewarded video ads in your app, ensure that you have enabled the feature in the AppLovin developer portal. Also note that activation of this feature does not take effect instantaneously, so it may require some time before these ads can be served.', { "OK" } )
			end
		else
			useRewarded = false
		end
	end
	return true
end

-- Create rewarded/incentivized switch/label
local irLabel = display.newText( mainGroup, "Use Incentivized/Rewarded", display.contentCenterX+16, 105, appFont, 16 )
local irSwitch = widget.newSwitch(
	{
		sheet = assets,
		width = 35,
		height = 35,
		frameOn = 1,
		frameOff = 2,
		x = irLabel.contentBounds.xMin-22,
		y = irLabel.y,
		style = "checkbox",
		id = "useRewarded",
		initialSwitchState = false,
		onPress = uiEvent
	})
mainGroup:insert( irSwitch )

-- Create buttons
loadButton = widget.newButton(
	{
		label = "Load AppLovin Ad",
		id = "load",
		shape = "rectangle",
		x = display.contentCenterX + 10,
		y = 170,
		width = 188,
		height = 32,
		font = appFont,
		fontSize = 16,
		fillColor = { default={ 0.12,0.32,0.52,1 }, over={ 0.132,0.352,0.572,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = uiEvent
	})
loadButton:setEnabled( false )
loadButton.alpha = 0.3
mainGroup:insert( loadButton )

showButton = widget.newButton(
	{
		label = "Show AppLovin Ad",
		id = "show",
		shape = "rectangle",
		x = display.contentCenterX + 10,
		y = 220,
		width = 188,
		height = 32,
		font = appFont,
		fontSize = 16,
		fillColor = { default={ 0.12,0.32,0.52,1 }, over={ 0.132,0.352,0.572,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = uiEvent
	})
showButton:setEnabled( false )
showButton.alpha = 0.3
mainGroup:insert( showButton )


-- Initially alert user to set up device for testing
checkSetup()

-- Init the Applovin plugin
applovin.init( adListener, { sdkKey=sdkKey, verboseLogging=false, testMode=true } )
