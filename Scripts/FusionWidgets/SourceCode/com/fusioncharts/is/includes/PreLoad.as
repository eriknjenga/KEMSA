/** --- PreLoad.as ---
* Copyright InfoSoft Global Private Ltd. and its licensors.  All Rights Reserved.
*
* Use and/or redistribution of this file, in whole or in part, is subject
* to the License Files, which was distributed with this component.
*
* The code in this file pre-loads the chart and after loading sends the
* control to DataLoad scene, frame 1.
*/
/*
The pre loader has a lot of cosmetic properties that can be defined. We allow
the user to take control of all those properties by specifying certain variables below.

Variables that the user can specify in the chart container:
PBarHeight - Required height for the progress bar.
PBarWidth - Required width for the progress bar.
PBarBorderColor - Border color of the progress bar
PBarBorderThickness - Border thickness of the progress bar
PBarBgColor - Progress bar background color (fill color of the bar)
PBarTextColor - Color of the text
PBarLoadingText - The actual loading text to be displayed

Define local variables to store cosmetic properties
*/
var LPBarHeight, LPBarWidth, LPBarBorderColor, LPBarBorderThickness, LPBarBgColor, LPBarTextColor, LPBarLoadingText;
//Set Progress bar Height
LPBarHeight = Number(getFirstValue(rootAttr["pbarheight"], "15"));
/*
Calculate the width of the progress bar
:Explanation: How the width of the progress bar is being calculated?
Basically, what we are aiming to do here is - Center align
the progress bar elements with respect to the chart size. So,
the width of the progress bar is set in such a way that is the
chart width is greater than 200 pixels, the progress bar width
will be 150 pixels. However, if the chart width is less than
200 pixels, then the progress bar width will be 25 pixels less
than the chart width.
*/
LPBarWidth = (_chartWidth>200) ? 150 : (_chartWidth-25);
//We also give the user an option to strong-enforce his own progress
//bar width value in case he wants something on his own.
LPBarWidth = Number(getFirstValue(rootAttr["pbarwidth"], LPBarWidth));
LPBarBorderColor = getFirstValue(rootAttr["pbarbordercolor"], "E2E2E2");
LPBarBorderThickness = Number(getFirstValue(rootAttr["pbarborderthickness"], 1));
LPBarBgColor = parseInt(getFirstValue(rootAttr["pbarbgcolor"], "E2E2E2"), 16);
LPBarTextColor = getFirstValue(rootAttr["pbartextcolor"], "666666");
LPBarLoadingText = unescape(getFirstValue(rootAttr["pbarloadingtext"], getAppMessage("LOADINGCHART", _lang)));
/**
* These variables below are declared even if the movie is playing from
* local disk, so that we can draw a progress bar, when the user loads a new
* XML data from JavaScript.
*/
//Create a movie clip container for the progress bar
var mcProgressBar:MovieClip;
//Progress bar x and y position
var pBXPos:Number = _chartXCenter-(LPBarWidth/2);
var pBYPos:Number = _chartYCenter-LPBarHeight;
/**
* If the movie is already loaded (playing from local disk or cached),
* just send the control to DataLoad scene, so as not to show preloader
*/
if (getBytesLoaded()>=getBytesTotal()) {
	gotoAndPlay("DataLoad", 1);
} else {
	/**
	* If the control comes here, it means the movie isn't still loaded
	* So, we need to build up the preloader.
	* We now draw the progress bar at the center of the stage.
	* To do this, we simply call drawProgressBar method.
	*/
	//Draw the bar
	mcProgressBar = drawProgressBar(this, 1, pBXPos, pBYPos, LPBarWidth, LPBarHeight, LPBarBorderColor, LPBarBorderThickness);
	//Create the loading text
	var tfLoad:TextField = createBasicText(LPBarLoadingText, this, 2, _chartXCenter, _chartYCenter+5, "Verdana", 10, LPBarTextColor, "center", "bottom");
	//Create the preloader sequence
	this.onEnterFrame = function() {
		if (getBytesLoaded()<getBytesTotal()) {
			//Means, the chart hasn't still loaded
			//Update the progress bar value
			setProgressValue(mcProgressBar, 0, getBytesTotal(), getBytesLoaded(), pBXPos, pBYPos, LPBarWidth, LPBarHeight, LPBarBgColor);
		} else {
			//The chart has loaded
			//Hide the progress bar
			mcProgressBar.removeMovieClip();
			//Hide the loading text
			tfLoad.removeTextField();
			//Delete the event handler
			delete this.onEnterFrame;
			//Send the control to DataLoad
			gotoAndPlay("DataLoad", 1);
		}
	};
}
