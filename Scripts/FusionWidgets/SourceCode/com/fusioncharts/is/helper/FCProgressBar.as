/**
 * @class FCProgressBar
 * @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
 * @version 1.0
 *
 * Copyright (C) InfoSoft Global Pvt. Ltd.
 *
 * FCProgressBar class provides functionality to build a light weight
 * progress bar to show progress of any type.
*/
class com.fusioncharts.is.helper.FCProgressBar {
	//Parent movie clip in which we build the progress bar
	private var parentMC:MovieClip;
	//Internal movie clips
	private var mcPBar:MovieClip;
	private var mcBar:MovieClip;
	private var mcBorder:MovieClip;
	//Depth in which we build.
	private var depth:Number;
	//Position
	private var x:Number;
	private var y:Number;
	//Width and height
	private var width:Number;
	private var height:Number;
	//Min and max value
	private var minValue:Number;
	private var maxValue:Number;
	//Cosmetics
	private var bgColor:Number;
	private var borderColor:String;
	private var borderThickness:Number;
	/**
	 * Constructor function.
	*/
	function FCProgressBar(parentMC:MovieClip, depth:Number, minValue:Number, maxValue:Number, x:Number, y:Number, width:Number, height:Number, bgColor:String, borderColor:String, borderThickness:Number) {
		//Store the parameters
		this.parentMC = parentMC;
		this.depth = depth;
		this.minValue = minValue;
		this.maxValue = maxValue;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.bgColor = parseInt(bgColor,16);
		this.borderColor = borderColor;
		this.borderThickness = borderThickness;
		//Draw the base of the progress bar
		this.drawBase();
	}
	/**
	 * Draws the base of the progress bar.
	 */
	private function drawBase():Void {
		//Create empty movie clip for the progress bar
		mcPBar = parentMC.createEmptyMovieClip("ProgressBar", depth);
		mcBar = mcPBar.createEmptyMovieClip("Bar", 1);
		mcBorder = mcPBar.createEmptyMovieClip("Border", 2);
		mcBorder.lineStyle(borderThickness, parseInt(borderColor, 16), 100);
		mcBorder.moveTo(x, y);
		mcBorder.lineTo(x+width, y);
		mcBorder.lineTo(x+width, y+height);
		mcBorder.lineTo(x, y+height);
		mcBorder.lineTo(x, y);
	}
	/**
	 * Updates the value of the progress bar.
	*/
	public function setValue(intValue:Number) {
		//If the given value is invalid, just return without doing anything
		if (intValue == undefined || intValue == null || isNaN(intValue) == true || (intValue<minValue) || (intValue>maxValue)) {
			return;
		}
		//Else, draw the progress bar 
		//Calculate the width required to be filled
		var fillWidth:Number;
		fillWidth = ((intValue-minValue)/maxValue)*width;
		//Draw the fill bar
		mcBar.clear();
		mcBar.lineStyle();
		mcBar.beginFill(bgColor, 100);
		mcBar.moveTo(x, y);
		mcBar.lineTo(x+fillWidth, y);
		mcBar.lineTo(x+fillWidth, y+height);
		mcBar.lineTo(x, y+height);
		mcBar.lineTo(x, y);
		mcBar.endFill();
	}
	/**
	 * Destroys the progress bar and removes all pertinent movie clips.
	*/
	public function destroy():Void{
		mcPBar.removeMovieClip();
	}
}
