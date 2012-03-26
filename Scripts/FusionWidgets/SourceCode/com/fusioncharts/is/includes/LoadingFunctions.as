/** --- LoadingFunctions.as ---
* Copyright InfoSoft Global Private Ltd. and its licensors.  All Rights Reserved.
*
* Use and/or redistribution of this file, in whole or in part, is subject
* to the License Files, which was distributed with this component.
*
* This file contains a few functions that we use when the chart is loading. We're
* loading the Chart classes in post-loading frames, and as such during the loading
* process, we do not have access to any classes. Hence, we use these functions.
*/
/**
* getFirstValue method is is used to return the first non-null
* non-undefined non-empty value in a list of values provided to
* this method. To this method you can pass a list of values like
* a,b,c,d,e in a preferential order and this method will return the
* first non-null non-undefined value in this list.
*/
_global.getFirstValue = function() {
	for (var i = 0; i<arguments.length; i++) {
		if (arguments[i] != null && arguments[i] != undefined && arguments[i] != "") {
			return arguments[i];
		}
	}
	return "";
};
/**
* ProgressBar rendering functions.
* We're using functions to render a progress bar
* as all the classes are loaded after the loading
* frames.
*/
/**
* drawProgressBar method draws the progress bar border
*	@param	mcParent	Movie clip reference in which we'll draw
*						the progress bar.
*	@param	depth		Depth (in the above movie clip) at which
*						we'll draw.
*	@param	x			x co-ordinate of the top left part of bar
*	@param	y			y co-ordinate of the top left part of bar
*	@param	width		Intended width of progress bar
*	@param	height		Intended height of progress bar
*	@param	borderColor	Border Color of the progress bar
*	@param	borderThickness	Thickness of border
* 	@return			A reference to the progress bar movie clip
*/
function drawProgressBar(mcParent:MovieClip, depth:Number, x:Number, y:Number, width:Number, height:Number, borderColor:String, borderThickness:Number):MovieClip {
	//Create empty movie clip for the progress bar
	var mcPBar:MovieClip = mcParent.createEmptyMovieClip("ProgressBar", depth);
	var mcBorder:MovieClip = mcPBar.createEmptyMovieClip("Border", 2);
	mcBorder.lineStyle(borderThickness, parseInt(borderColor, 16), 100);
	mcBorder.moveTo(x, y);
	mcBorder.lineTo(x+width, y);
	mcBorder.lineTo(x+width, y+height);
	mcBorder.lineTo(x, y+height);
	mcBorder.lineTo(x, y);
	//Return the progress bar movie clip
	return mcPBar;
}
/**
* setProgressValue method is used to update the progress
* display of the progress bar
*	@param		mcProgressBar	Movie clip in which progress bar
*								is being rendered.
*	@param		minValue		Lower limit of progress bar (normally 0)
*	@param		maxValue		Upper limit of bar (total size)
*	@param		intValue		Current progress value
*	@param		x				x co-ordinate of the top left part of bar
*	@param		y				y co-ordinate of the top left part of bar
*	@param		width			Intended width of progress bar
*	@param		height			Intended height of progress bar
*	@param		bgColor			Background color of the progress bar
*/
function setProgressValue(mcProgressBar:MovieClip, minValue:Number, maxValue:Number, intValue:Number, x:Number, y:Number, width:Number, height:Number, bgColor:Number) {
	//If the given value is invalid, just return without doing anything
	if (intValue == undefined || intValue == null || isNaN(intValue) == true || (intValue<minValue) || (intValue>maxValue)) {
		return;
	}
	//Else, draw the progress bar  
	//Calculate the width required to be filled
	var fillWidth:Number;
	fillWidth = ((intValue-minValue)/maxValue)*width;
	//Draw the fill bar
	var mcBar:MovieClip = mcProgressBar.createEmptyMovieClip("Bar", 1);
	mcBar.lineStyle();
	mcBar.beginFill(bgColor, 100);
	mcBar.moveTo(x, y);
	mcBar.lineTo(x+fillWidth, y);
	mcBar.lineTo(x+fillWidth, y+height);
	mcBar.lineTo(x, y+height);
	mcBar.lineTo(x, y);
	mcBar.endFill();
}
_global.createBasicText = function(strText:String, targetMC:MovieClip, depth:Number, xPos:Number, yPos:Number, fontFace:String, fontSize:Number, fontColor:String, alignPos:String, vAlignPos:String):TextField  {
	//First up, we create a text format object and set the properties
	var tFormat:TextFormat = new TextFormat();
	//Font properties
	tFormat.font = getFirstValue(fontFace, "Verdana");
	tFormat.size = getFirstValue(fontSize, 10);
	tFormat.color = parseInt(getFirstValue(fontColor, "666666"), 16);
	//Uncomment the following lines if you need to show text decoration
	//for the application messages.
	//Text decoration
	//tFormat.bold = true;
	//tFormat.italic = false;
	//tFormat.underline = false;
	//Create the actual text field object now. - a & b are undefined variables
	//We want the initial text field size to be of flexible size
	//So we do not define the width and height here
	var tf:TextField;
	var a, b;
	tf = targetMC.createTextField("Text_"+depth, depth, xPos, yPos, a, b);
	//Set the properties
	tf.autoSize = alignPos;
	tf.selectable = false;
	tf.html = false;
	//set text
	tf.text = strText;
	//Apply the text format
	tf.setTextFormat(tFormat);
	//------------------------------------------------------------------//
	//text is horizontal, we just need to adjust the vertical
	//alignment.
	switch (vAlignPos.toUpperCase()) {
	case "TOP" :
		//Top(of the ypos mid line
		//        TEXT HERE
		//---------MID LINE---------
		//       (empty space)
		tf._y = tf._y-(tf._height);
		break;
	case "MIDDLE" :
		//       (empty space)
		//---------TEXT HERE---------
		//       (empty space)
		tf._y = tf._y-(tf._height/2);
		break;
	case "BOTTOM" :
		//Right is equivalent to bottom
		//       (empty space)
		//---------MID LINE---------
		//         TEXT HERE
		//No need to change - already at this position
		break;
	}
	//Delete the temporary objects
	delete tFormat;
	//Return the text field
	return tf;
};
/**
* getAttributesArray method helps convert the list of attributes
* for an XML node into an array.
* Reason:
* Starting ActionScript 2, OBJECT/EMBED attributes have also
* become case-sensitive. However, prior versions of FusionCharts
* supported case-insensitive attributes. So we need to parse all
* attributes as case-insensitive to maintain backward compatibility.
* To do so, we first extract all attributes, convert it into
* lower case and then store it in an array. Later, we extract value from
* this array.
* Once this array is returned, IT'S VERY NECESSARY IN THE CALLING CODE TO
* REFERENCE THE NAME OF ATTRIBUTE IN LOWER CASE (STORED IN THIS ARRAY).
* ELSE, UNDEFINED VALUE WOULD SHOW UP.
*/
function getAttributesArray(objSource:Object):Array {
	//Array that will store the attributes
	var atts:Array = new Array();
	//Object used to iterate through the attributes collection
	var obj:Object;
	//Iterate through each attribute in the attributes collection,
	//convert to lower case and store it in array.
	for (obj in objSource) {
		//Store it in array
		atts[obj.toString().toLowerCase()] = objSource[obj];
	}
	//Return the array
	return atts;
}
