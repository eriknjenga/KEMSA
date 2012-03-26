/**
* @class SparkChart
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd. 2005-2006
* SparkChart extends Chart class to encapsulate
* functionalities of spark charts.
* It contains the functionalities that are common to all
* spark charts - like scale, trendlines etc.
* All spark charts then extend this class.
*/
//Import parent class
import com.fusioncharts.is.core.Chart;
//Axis for the chart
import com.fusioncharts.is.axis.LinearAxis;
//Utility functions
import com.fusioncharts.is.helper.Utils;
//Logger
import com.fusioncharts.is.helper.Logger;
//Color Manager
import com.fusioncharts.is.colormanagers.SparkColorManager;
//Number formatting
import com.fusioncharts.is.helper.NumberFormatting;
//Extensions
import com.fusioncharts.is.extensions.MathExt;
import com.fusioncharts.is.extensions.ColorExt;
import com.fusioncharts.is.extensions.DrawingExt;
//Delegate
import mx.utils.Delegate;
class com.fusioncharts.is.core.SparkChart extends Chart {
	//Reference to linear axis of the chart
	private var pAxis:LinearAxis;
	//Number formatting class for this axis
	private var nf:NumberFormatting;
	//Color Manager for the charts
	public var colorM:SparkColorManager;
	//Array to store datasets
	private var dataset:Array;
	//Number of data items
	private var num:Number;		
	private var numDS:Number;
	//Container to hold defined Color ranges
	private var colorR:Array;
	//Number of defined color range
	private var numCR:Number;	
	//Axis charts can have trend lines. trendLines array	
	//stores the trend lines for an axis chart.
	private var trendLines:Array;
	//numTrendLines stores the number of trend lines
	private var numTrendLines:Number;	
	//Indexes of highest and lowest value
	private var highestIndex:Number;
	private var lowestIndex:Number;
	/**
	* Constructor function. We invoke the super class'  constructor.
	* And also initialize local instance properties.
	*/
	function SparkChart(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Initialize the containers for chart
		this.dataset = new Array();
		this.trendLines = new Array();
		//Initialize the number of data elements present
		this.num = 0;
		this.numDS = 0;
		this.numTrendLines = 0;
		//Color Range containers
		this.colorR = new Array();
		this.numCR = 0;
	}	
	/**
	* getMaxDataValue method gets the maximum y-axis data value present
	* in the data.
	*	@return	The maximum value present in the data provided.
	*/
	private function getMaxDataValue():Number{
		var maxValue : Number;
		var firstNumberFound : Boolean = false;
		var i : Number, j : Number;
		for (i = 1; i <= this.numDS; i ++){
			for (j = 1; j <= this.num; j ++){
				//By default assume the first non-null number to be maximum
				if (firstNumberFound == false){
					if (this.dataset [i].data [j].isDefined == true){
						//Set the flag that "We've found first non-null number".
						firstNumberFound = true;
						//Also assume this value to be maximum.
						maxValue = this.dataset [i].data [j].value;
					}
				} else {
					//If the first number has been found and the current data is defined, compare
					if (this.dataset [i].data [j].isDefined){
						//Store the greater number
						maxValue = (this.dataset [i].data [j].value > maxValue) ? this.dataset [i].data [j].value : maxValue;
					}
				}
			}
		}
		//Do a second iteration and set the flag for the highest value
		if (firstNumberFound){
			for (i = 1; i <= this.numDS; i ++){
				for (j = 1; j <= this.num; j ++){
					if (this.dataset[i].data[j].value == maxValue){
						this.dataset[i].data[j].highest = true;						
						//Also, store the index (for line chart)
						this.highestIndex = j;
					}
				}
			}
		}		
		//If no number was found, return 0
		return ((firstNumberFound==true)?maxValue:0);
	}
	/**
	* getMinDataValue method gets the minimum y-axis data value present
	* in the data
	*	@reurns		The minimum value present in data
	*/
	private function getMinDataValue():Number{
		var minValue : Number;
		var firstNumberFound : Boolean = false;
		var i : Number, j : Number;
		for (i = 1; i <= this.numDS; i ++){
			for (j = 1; j <= this.num; j ++){
				//By default assume the first non-null number to be minimum
				if (firstNumberFound == false){
					if (this.dataset [i].data [j].isDefined == true){
						//Set the flag that "We've found first non-null number".
						firstNumberFound = true;
						//Also assume this value to be minimum.
						minValue = this.dataset [i].data [j].value;
					}
				} else {
					//If the first number has been found and the current data is defined, compare
					if (this.dataset [i].data [j].isDefined){
						//Store the lesser number
						minValue = (this.dataset [i].data [j].value < minValue) ? this.dataset [i].data [j].value : minValue;
					}
				}
			}
		}
		//Do a second iteration and set the flag for the lowest value
		if (firstNumberFound){
			for (i = 1; i <= this.numDS; i ++){
				for (j = 1; j <= this.num; j ++){
					if (this.dataset[i].data[j].value == minValue){
						this.dataset[i].data[j].lowest = true;
						//Also, store the index (for line chart)
						this.lowestIndex = j;
					}
				}
			}
		}
		//If no number was found, return 0
		return ((firstNumberFound==true)?minValue:0);
	}
	/**
	* setupAxis method sets the axis for the chart.
	* It gets the minimum and maximum value specified in data and
	* based on that it calls super.getAxisLimits();
	*/
	private function setupAxis():Void {
		this.pAxis = new LinearAxis(this.params.yAxisMinValue, this.params.yAxisMaxValue, true, ! this.params.setAdaptiveYMin, 0, 1, this.nf, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);
		this.pAxis.calculateLimits(this.getMaxDataValue(),this.getMinDataValue());				
	}
	/**
	 * setupNumberFormatting method sets up the number formatting instance
	 * for the class.
	 *	@param		numberPrefix		Number prefix to be added to number.
	 *	@param		numberSuffix		Number Suffix to be added.
	 *	@param		scaleRecursively	Whether to scale the number recursively as per defined scale.
	 *	@param		maxScaleRecursion	Maximum recursion to set in scaling.
	 *	@param		defaultNumberScale	Default scale of the number provided.
	 *	@param		numberScaleValues	Values for scaling (string). 
	 *	@param		numberScaleUnits	Units for scaling (string).
	 *	@param		decimalSeparator	Separator character for decimal representation.
	 *	@param		thousandSeparator	Thousands separator character.
	 *	@param		inDecimalSeparator	Input decimal character
	 *	@param		inThousandSeparator	Input thousand separator character
	 *	@return							Nothing
	*/
	private function setupNumberFormatting(numberPrefix:String, numberSuffix:String, scaleRecursively:Boolean, maxScaleRecursion:Number, scaleSeparator:String, defaultNumberScale:String, numberScaleValues:String, numberScaleUnits:String, decimalSeparator:String, thousandSeparator:String, inDecimalSeparator:String, inThousandSeparator:String):Void {
		//Setup the number formatting instance for this class.
		this.nf = new NumberFormatting(numberPrefix, numberSuffix, scaleRecursively, maxScaleRecursion, scaleSeparator, defaultNumberScale, numberScaleValues, numberScaleUnits, decimalSeparator, thousandSeparator, inDecimalSeparator, inThousandSeparator);
	}
	/**
	 * setupColorManager method sets up the color manager for the chart.
	  *	@param	paletteId	Palette Id for the chart.
	 *	@param	themeColor	Color code if the chart uses single color theme.
	*/
	private function setupColorManager(paletteId:Number, themeColor:String):Void{
		this.colorM = new SparkColorManager(paletteId,themeColor);
	}
	/**
	 * returnDataAsColorRange method returns an object encapsulating all the
	 * properties of a Color Range object.
	 *	@param 	minValue		Minimum value for this color range
	 *	@param 	maxValue		Maximum value for this color range
	 * 	@param 	label			Label for this color range
	 * 	@param 	color			Color for this color range
	 * 	@param 	alpha			Alpha for this range
	*/
	private function returnDataAsColorRange(minValue:Number, maxValue:Number, label:String, color:String, alpha:String):Object{
		//Create an obejct to represent it
		var objCR:Object = new Object();		
		//Store
		objCR.minValue = minValue;
		objCR.maxValue = maxValue;
		objCR.label = label;
		objCR.color = color;
		objCR.alpha = alpha;
		//Return it
		return objCR;
	}
	/**
	* returnDataAsTrendObj method takes in functional parameters, and creates
	* an object to represent the trend line as a unified object.
	*	@param	startValue		Starting value of the trend line.
	*	@param	endValue		End value of the trend line (if different from start)
	*	@param	color			Color of the trend line
	*	@param	thickness		Thickness (in pixels) of line
	*	@param	alpha			Alpha of the line
	*	@param	isTrendZone		Flag to control whether to show trend as a line or block(zone)
	*	@param	isDashed		Whether the line would appear dashed.
	*	@param	dashLen			Length of dash (if isDashed selected)
	*	@param	dashGap			Gap of dash (if isDashed selected)
	*	@return					An object encapsulating these values.
	*/
	private function returnDataAsTrendObj(startValue:Number, endValue:Number, color:String, thickness:Number, alpha:Number, isTrendZone:Boolean, isDashed:Boolean, dashLen:Number, dashGap:Number):Object{
		//Create an object that will be returned.
		var rtnObj:Object = new Object ();
		//Store parameters as object properties
		rtnObj.startValue = startValue;
		rtnObj.endValue = endValue;
		rtnObj.color = color;
		rtnObj.thickness = thickness;
		rtnObj.alpha = alpha;
		rtnObj.isTrendZone = isTrendZone;
		rtnObj.isDashed = isDashed;
		rtnObj.dashLen = dashLen;
		rtnObj.dashGap = dashGap;
		//Flag whether trend line is proper
		rtnObj.isValid = true;
		//Holders for dimenstions
		rtnObj.y = 0;
		rtnObj.toY = 0;
		//Return
		return rtnObj;
	}
	/**
	* feedMacros method feeds macros and their respective values
	* to the macro instance. This method is to be called after
	* calculatePoints, as we set the canvas and chart co-ordinates
	* in this method, which is known to us only after calculatePoints.
	*	@return	Nothing
	*/
	private function feedMacros ():Void {
		//Feed macros one by one
		//Chart dimension macros
		this.macro.addMacro ("$chartStartX", this.x);
		this.macro.addMacro ("$chartStartY", this.y);
		this.macro.addMacro ("$chartWidth", this.width);
		this.macro.addMacro ("$chartHeight", this.height);
		this.macro.addMacro ("$chartEndX", this.width);
		this.macro.addMacro ("$chartEndY", this.height);
		this.macro.addMacro ("$chartCenterX", this.width / 2);
		this.macro.addMacro ("$chartCenterY", this.height / 2);
		//Canvas related macros		
		this.macro.addMacro ("$canvasStartX", this.elements.canvas.x);
		this.macro.addMacro ("$canvasEndX", this.elements.canvas.toX);		
		this.macro.addMacro ("$canvasStartY", this.elements.canvas.y);
		this.macro.addMacro ("$canvasEndY", this.elements.canvas.toY);		
		this.macro.addMacro ("$canvasCenterX", this.elements.canvas.x + this.elements.canvas.w/2);
		this.macro.addMacro ("$canvasCenterY", this.elements.canvas.y + this.elements.canvas.h/2);
	}
	// -------------------------- PARSING XML ----------------------------//
	/**
	 * parseColorRange method parses the color ranges for the gauge.
	 *	@param	arrColorRange	Array of color range nodes.
	*/
	private function parseColorRange(arrColorRange:Array):Void{
		//Loop variable
		var i:Number;
		//Local variables to store property
		var minValue:Number, maxValue:Number, label:String, code:String, alpha:String;
		//Previous range's min value
		var prevMinValue:Number = 0;
		//Iterate and find color range nodes
		for (i=0; i<arrColorRange.length; i++){
			//If it's a COLOR node
			if (arrColorRange[i].nodeName.toUpperCase()=="COLOR"){
				//Increment
				this.numCR++;
				//Get atts
				var atts:Array = Utils.getAttributesArray(arrColorRange[i]);
				//Extract attributes
				minValue = getFN(atts["minvalue"], prevMinValue);
				maxValue = getFN(atts["maxvalue"], minValue);
				label = getFV(atts["label"], atts["name"], "");
				code = formatColor(getFV(atts["code"], this.colorM.getColor()));				
				alpha = getFV(atts["alpha"], this.params.plotFillAlpha);
				this.colorR[this.numCR] = returnDataAsColorRange(minValue, maxValue, label, code, alpha);
				//We take the maximum value of this color range to the default minimum of the next one
				prevMinValue = maxValue;
			}
		}
	}
	/**
	* parseTrendLineXML method parses the XML node containing trend line nodes
	* and then stores it in local objects.
	*	@param		arrTrendLineNodes		Array containing Trend LINE nodes.
	*	@return							Nothing.
	*/
	private function parseTrendLineXML (arrTrendLineNodes:Array):Void {
		//Define variables for local use
		var startValue:Number, endValue:Number;
		var color:String, thickness:Number, alpha:Number;
		var isTrendZone:Boolean, isDashed:Boolean;
		var dashLen:Number, dashGap:Number;
		//Loop variable
		var i:Number;
		//Iterate through all nodes in array
		for (i = 0; i <= arrTrendLineNodes.length; i ++){
			//Check if LINE node
			if (arrTrendLineNodes [i].nodeName.toUpperCase () == "LINE"){
				//Update count
				numTrendLines++;
				//Store the node reference
				var lineNode:XMLNode = arrTrendLineNodes [i];
				//Get attributes array
				var lineAttr:Array = Utils.getAttributesArray (lineNode);
				//Extract and store attributes
				try{
					startValue = this.nf.parseValue(getFV(lineAttr["startvalue"], lineAttr["value"]));
				}catch (e:Error){
					//If the value is not a number, log a data
					this.log("Invalid trend value", e.message, Logger.LEVEL.ERROR);
					//Set as NaN - so that we can track and ignore it later
					startValue = Number("");
				}
				try{
					endValue = this.nf.parseValue(getFV(lineAttr["endvalue"], startValue));					
				}catch (e:Error){
					//If the value is not a number, log a data
					this.log("Invalid trend end value", e.message, Logger.LEVEL.ERROR);
					//Set as NaN - so that we can track and ignore it later
					endValue = Number("");
				}				
				color = String (formatColor (getFV (lineAttr ["color"] , this.colorM.getTrendColor())));
				thickness = getFN (lineAttr ["thickness"] , 1);
				isTrendZone = toBoolean (Number (getFV (lineAttr ["istrendzone"] , 0)));
				alpha = getFN (lineAttr ["alpha"] , (isTrendZone == true) ? 20:60);				
				isDashed = toBoolean (getFN (lineAttr ["dashed"] , 0));
				dashLen = getFN (lineAttr ["dashlen"] , 5);
				dashGap = getFN (lineAttr ["dashgap"] , 2);
				//Create trend line object
				this.trendLines[numTrendLines] = returnDataAsTrendObj (startValue, endValue, color, thickness, alpha, isTrendZone, isDashed, dashLen, dashGap);
			}
		}
	}
	//-------------------------- VALIDATORS -----------------------------//
	/**
	* validateTrendLines method helps us validate the different trend line
	* points entered by user in XML. Some trend points may fall out of
	* chart range (yMin,yMax) and we need to invalidate them. 
	* We also calculate the position for trend lines.
	*	@return		Nothing
	*/
	private function validateTrendLines():Void{
		//Sequentially do the following.
		//- Check range of each trend line against chart yMin,yMax and
		//  invalidate wrong ones.
		//Loop variable
		var i:Number;
		for (i = 1; i <= this.numTrendLines; i ++){
			//If the trend line start/end value out of range
			//or, if they are non-numeric.
			if (isNaN(this.trendLines [i].startValue) || isNaN(this.trendLines [i].endValue) || (this.trendLines [i].startValue<this.pAxis.getYMin()) || (this.trendLines [i].startValue > this.pAxis.getYMax()) || (this.trendLines [i].endValue < this.pAxis.getYMin()) || (this.trendLines[i].endValue>this.pAxis.getYMax())){
				//Invalidate it
				this.trendLines [i].isValid = false;
			} else {
				//Mark it as valid
				this.trendLines [i].isValid = true;
				//Calculate the position of trend points
				this.trendLines [i].y = this.pAxis.getAxisPosition(this.trendLines[i].startValue, false);
				//If end value is different from start value
				if (this.trendLines [i].startValue != this.trendLines [i].endValue)	{
					//Calculate y for end value
					this.trendLines [i].toY = this.pAxis.getAxisPosition (this.trendLines [i].endValue, false);
					//Height
					this.trendLines [i].h = (this.trendLines [i].toY - this.trendLines [i].y);
				} else {
					//Just copy
					this.trendLines [i].toY = this.trendLines [i].y;
					//Height
					this.trendLines [i].h = 0;
				}
			}
		}
	}
	// ------------ VISUAL RENDERING METHODS -------------//
	/**
	* drawCanvas method renders the chart canvas. 
	*	@return	Nothing
	*/
	private function drawCanvas ():Void {
		//Create a new movie clip container for canvas
		var canvasMC = this.cMC.createEmptyMovieClip ("Canvas", this.dm.getDepth ("CANVAS"));		

		//Parse the color, alpha and ratio array
		var canvasColor:Array = ColorExt.parseColorList (this.params.canvasBgColor);
		var canvasAlpha:Array = ColorExt.parseAlphaList (this.params.canvasBgAlpha, canvasColor.length);
		var canvasRatio:Array = ColorExt.parseRatioList (this.params.canvasBgRatio, canvasColor.length);			
		//Create matrix object
		var matrix:Object = {
			matrixType:"box", w:this.elements.canvas.w, h:this.elements.canvas.h, x:- (this.elements.canvas.w / 2) , y:- (this.elements.canvas.h / 2) , r:MathExt.toRadians (this.params.canvasBgAngle)
		};
		//Start the fill.
		canvasMC.beginGradientFill ("linear", canvasColor, canvasAlpha, canvasRatio, matrix);		
		//Set border properties - invisible
		canvasMC.lineStyle ();
		//Draw the rectangle with center registration point
		canvasMC.moveTo ( - (this.elements.canvas.w / 2) , - (this.elements.canvas.h / 2));		
		canvasMC.lineTo (this.elements.canvas.w / 2, - (this.elements.canvas.h / 2));
		canvasMC.lineTo (this.elements.canvas.w / 2, this.elements.canvas.h / 2);
		canvasMC.lineTo ( - (this.elements.canvas.w / 2) , this.elements.canvas.h / 2);
		canvasMC.lineTo ( - (this.elements.canvas.w / 2) , - (this.elements.canvas.h / 2));
		//Set the x and y position
		canvasMC._x = this.elements.canvas.x + this.elements.canvas.w / 2;
		canvasMC._y = this.elements.canvas.y + this.elements.canvas.h / 2;
		//End Fill
		canvasMC.endFill ();
		// --------------------------- DRAW CANVAS BORDER --------------------------//
		//Canvas Border
		if (this.params.canvasBorderAlpha>0){
			//Create a new movie clip container for canvas
			var canvasBorderMC = this.cMC.createEmptyMovieClip ("CanvasBorder", this.dm.getDepth ("CANVASBORDER"));
			//Set border properties
			canvasBorderMC.lineStyle (this.params.canvasBorderThickness, parseInt (this.params.canvasBorderColor, 16) , this.params.canvasBorderAlpha);
			//Move to (-w/2, 0);
			canvasBorderMC.moveTo ( - (this.elements.canvas.w / 2) , - (this.elements.canvas.h / 2));
			//Draw the rectangle with center registration point
			canvasBorderMC.lineTo (this.elements.canvas.w / 2, - (this.elements.canvas.h / 2));
			canvasBorderMC.lineTo (this.elements.canvas.w / 2, this.elements.canvas.h / 2);
			canvasBorderMC.lineTo ( - (this.elements.canvas.w / 2) , this.elements.canvas.h / 2);
			canvasBorderMC.lineTo ( - (this.elements.canvas.w / 2) , - (this.elements.canvas.h / 2));
			//Set the x and y position
			canvasBorderMC._x = this.elements.canvas.x + this.elements.canvas.w / 2;
			canvasBorderMC._y = this.elements.canvas.y + this.elements.canvas.h / 2;
		}			
		//Apply animation
		if (this.params.animation){
			this.styleM.applyAnimation (canvasBorderMC, this.objects.CANVAS, this.macro, canvasBorderMC._x, - this.elements.canvas.w / 2, canvasBorderMC._y, - this.elements.canvas.h / 2, 100, 100, 100, null);
		}
		//Apply filters
		this.styleM.applyFilters (canvasMC, this.objects.CANVAS);
		clearInterval (this.config.intervals.canvas);
	}
	/**
	* drawTrendLines method draws the trend lines on the chart
	* with their respective values.
	*/
	private function drawTrendLines():Void {
		var depth:Number = this.dm.getDepth ("TRENDLINES");
		//Movie clip container
		var trendLineMC:MovieClip;
		//Loop variable
		var i : Number;
		//Iterate through all the trend lines
		for (i = 1; i <= this.numTrendLines; i ++){
			if (this.trendLines [i].isValid == true){
				trendLineMC = this.cMC.createEmptyMovieClip ("TrendLine_" + i, depth);
				//Now, draw the line or trend zone
				if (this.trendLines [i].isTrendZone){
					//Create rectangle
					trendLineMC.lineStyle ();
					//Re-position
					trendLineMC._x = this.elements.canvas.x;
					trendLineMC._y = this.trendLines[i].y + (this.trendLines [i].h/2);
					//Absolute height value
					this.trendLines [i].h = Math.abs (this.trendLines [i].h);
					//We need to align rectangle at L,M
					trendLineMC.moveTo (0, 0);
					//Begin fill
					trendLineMC.beginFill (parseInt (this.trendLines [i].color, 16) , this.trendLines [i].alpha);
					//Draw rectangle
					trendLineMC.lineTo (0, - (this.trendLines [i].h / 2));
					trendLineMC.lineTo (this.elements.canvas.w, - (this.trendLines [i].h / 2));
					trendLineMC.lineTo (this.elements.canvas.w, (this.trendLines [i].h / 2));
					trendLineMC.lineTo (0, (this.trendLines [i].h / 2));
					trendLineMC.lineTo (0, 0);
				} else {
					//Just draw line
					trendLineMC.lineStyle (this.trendLines [i].thickness, parseInt (this.trendLines [i].color, 16) , this.trendLines [i].alpha);
					//Now, if dashed line is to be drawn
					if (!this.trendLines [i].isDashed){
						//Draw normal line line keeping 0,0 as registration point
						trendLineMC.moveTo (0, 0);
						trendLineMC.lineTo (this.elements.canvas.w, this.trendLines [i].h);
					} else {
						//Dashed Line line
						DrawingExt.dashTo (trendLineMC, 0, 0, this.elements.canvas.w, this.trendLines [i].h, this.trendLines [i].dashLen, this.trendLines [i].dashGap);
					}
					//Re-position line
					trendLineMC._x = this.elements.canvas.x;
					trendLineMC._y = this.trendLines[i].y;
				}
				//Apply animation
				if (this.params.animation){
					this.styleM.applyAnimation (trendLineMC, this.objects.TRENDLINES, this.macro, null, 0, trendLineMC._y, 0, 100, 100, 100, null);
				}
				//Apply filters
				this.styleM.applyFilters (trendLineMC, this.objects.TRENDLINES);
				//Increase depth
				depth++;
			}
		}
		delete trendLineMC;
		//Clear interval
		clearInterval (this.config.intervals.trend);
	}
	/**
	* setContextMenu method sets the context menu for the chart.
	* For this chart, the context items are "Print Chart".
	*/
	private function setContextMenu():Void {
		var chartMenu : ContextMenu = new ContextMenu();
		chartMenu.hideBuiltInItems();
		if (this.params.showPrintMenuItem){
			//Create a print chart contenxt menu item
			var printCMI : ContextMenuItem = new ContextMenuItem ("Print Chart", Delegate.create (this, printChart));
			//Push print item.
			chartMenu.customItems.push (printCMI);
		}
		//If the export data item is to be shown
		if (this.params.showExportDataMenuItem){
			chartMenu.customItems.push(super.returnExportDataMenuItem());
		}
		//Add export chart related menu items to the context menu
		this.addExportItemsToMenu(chartMenu);
		if (this.params.showFCMenuItem){
			//Push "About FusionCharts" Menu Item
			chartMenu.customItems.push(super.returnAbtMenuItem());		
		}
		//Assign the menu to cMC movie clip
		this.cMC.menu = chartMenu;
		//Clear interval
		clearInterval(this.config.intervals.contextMenu);
	}
	//---------------------- CLASS RELATED ------------------------//
	/**
	* reInit method re-initializes the chart. 
	*/
	public function reInit():Void{
		//Bubble up
		super.reInit();	
		//Re-create container arrays
		this.dataset = new Array ();		
		this.trendLines = new Array();
		this.colorR = new Array();
		//Re-set indexes to 0
		this.num = 0;
		this.numDS = 0;
		this.numTrendLines = 0;	
		this.numCR = 0;
		//Delete indexes
		delete this.highestIndex;
		delete this.lowestIndex;
	}
	/**
	* remove method removes the chart by clearing the chart movie clip
	* and removing any listeners. 
	*/
	public function remove():Void {
		//Bubble the call up 
		super.remove();
	}
}