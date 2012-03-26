/**
* @class SYRealTimeChart
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd. 2005-2006
* SYRealTimeChart extends RealTimeAxisChart class to encapsulate
* functionalities of a single y axis chart with real time capabilities. 
* All individual charts then extend this class.
*/
//Import parent class
import com.fusioncharts.is.core.RealTimeAxisChart;
//Utilities
import com.fusioncharts.is.helper.Utils;
//Linear axis for the chart (primary)
import com.fusioncharts.is.axis.LinearAxis;
//Number formatting
import com.fusioncharts.is.helper.NumberFormatting;
//Logger for logging errors
import com.fusioncharts.is.helper.Logger;
//Legend Class
import com.fusioncharts.is.helper.Legend;
//Extensions
import com.fusioncharts.is.extensions.DrawingExt;
//Delegate
import mx.utils.Delegate;
class com.fusioncharts.is.core.SYRealTimeChart extends RealTimeAxisChart {
	//Reference to primary axis of the chart
	private var pAxis:LinearAxis;
	//Number formatting class for this axis
	private var nf:NumberFormatting;
	//Containers for data.	
	//Array to store x-axis categories (labels)
	private var categories:Array;
	//Array to store datasets
	private var dataset:Array;
	//Array to store the divlines for the axis
	private var divLines:Array;
	//Number of data sets
	private var numDS:Number;
	//Number of data items
	private var num:Number;		
	//Array to store x positions for all items on the chart
	private var dataPosX:Array;
	//Axis charts can have vertical lines dividing the x-axis
	//Number of vertical lines
	private var numVLines:Number = 0;
	//labels. Container to store those vLines.
	private var vLines:Array;	
	//Axis charts can have trend lines. trendLines array	
	//stores the trend lines for an axis chart.
	private var trendLines:Array;
	//numTrendLines stores the number of trend lines
	private var numTrendLines:Number;
	//Number of trend lines below
	private var numTrendLinesBelow:Number;
	//Reference to legend component of chart
	private var lgnd:Legend;
	//Reference to legend movie clip
	private var lgndMC:MovieClip;
	/**
	* Constructor function. We invoke the super class'
	* constructor.
	*/
	function SYRealTimeChart(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Initialize the containers for chart
		this.categories = new Array();
		this.dataset = new Array();
		this.vLines = new Array();
		this.trendLines = new Array();
		this.divLines = new Array();
		//Initialize the data container array
		this.dataPosX = new Array();
		//Initialize the number of data elements present
		this.numDS = 0;
		this.num = 0;
		this.numVLines = 0;
		this.numTrendLines = 0;
		this.numTrendLinesBelow = 0;
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
	 * selectToolText method selects the tool text to be displayed for
	 * a data item.
	*/
	private function selectToolText():Void{
		var i:Number, j:Number;
		//Set tool tip text values for each data
		var toolText : String
		for (i = 1; i <= this.numDS; i ++){
			for (j = 1; j <= this.num; j ++){
				//Preferential Order - Set Tool Text (No concatenation) > SeriesName + Cat Name + Value
				if (this.dataset [i].data [j].toolText == undefined || this.dataset [i].data [j].toolText == ""){
					//If the tool tip text is not already defined
					//If labels have been defined
					toolText = (this.params.seriesNameInToolTip && this.dataset[i].seriesName != "") ? (this.dataset [i].seriesName + this.params.toolTipSepChar) : "";
					toolText = toolText + ((this.categories[j].toolText != "") ? (this.categories [j].toolText + this.params.toolTipSepChar) : "");
					toolText = toolText + this.dataset [i].data [j].displayValue;
					this.dataset [i].data [j].toolText = toolText;
				}
			}
		}
	}
	/**
	 * selectsLabelsToShow method select which labels we've to show on the
	 * chart, based on the parameters set by user
	*/
	private function selectLabelsToShow():Void{
		var i:Number;
		//Based on label step, set showLabel of each data point as required.
		//Visible label count
		var visibleCount : Number = 0;		
		//Storage in global container
		this.params.finalVisibleCount = 0;
		for (i = 1; i <= this.num; i ++){
			//We alter the label visibility only if originally it's not set to false.
			if (this.categories [i].oShowLabel==true){
				//If label step is defined, we need to set showLabel of those
				//labels which fall on step as false.
				if ((i - 1)%this.params.labelStep != 0){
					this.categories [i].showLabel = false;
				} else {
					this.categories [i].showLabel = true;
				}
				//Update counter
				this.params.finalVisibleCount = (this.categories [i].showLabel) ? (this.params.finalVisibleCount + 1) : (this.params.finalVisibleCount);
			}			
		}
		//If num is < this.params.numDisplaySets, we count for the extra labels,
		//as we're calculating the allotted width for each label (in wrap mode) only initially.
		if (this.num<this.params.numDisplaySets){
			this.params.finalVisibleCount += Math.round((this.params.numDisplaySets-this.num)/this.params.labelStep) + 1;
		}
	}
	/**
	* returnDataAsTrendObj method takes in functional parameters, and creates
	* an object to represent the trend line as a unified object.
	*	@param	startValue		Starting value of the trend line.
	*	@param	endValue		End value of the trend line (if different from start)
	*	@param	displayValue	Display value for the trend (if custom).
	*	@param	color			Color of the trend line
	*	@param	thickness		Thickness (in pixels) of line
	*	@param	alpha			Alpha of the line
	*	@param	isTrendZone		Flag to control whether to show trend as a line or block(zone)
	*	@param	showOnTop		Whether to show trend over data plot or under it.
	*	@param	isDashed		Whether the line would appear dashed.
	*	@param	dashLen			Length of dash (if isDashed selected)
	*	@param	dashGap			Gap of dash (if isDashed selected)
	*	@param	valueOnRight	Whether to put the trend value on right side of canvas
	*	@return					An object encapsulating these values.
	*/
	private function returnDataAsTrendObj(startValue:Number, endValue:Number, displayValue:String, color:String, thickness:Number, alpha:Number, isTrendZone:Boolean, showOnTop:Boolean, isDashed:Boolean, dashLen:Number, dashGap:Number, valueOnRight:Boolean):Object{
		//Create an object that will be returned.
		var rtnObj:Object = new Object ();
		//Store parameters as object properties
		rtnObj.startValue = startValue;
		rtnObj.endValue = endValue;
		rtnObj.displayValue = displayValue;
		rtnObj.color = color;
		rtnObj.thickness = thickness;
		rtnObj.alpha = alpha;
		rtnObj.isTrendZone = isTrendZone;
		rtnObj.showOnTop = showOnTop;
		rtnObj.isDashed = isDashed;
		rtnObj.dashLen = dashLen;
		rtnObj.dashGap = dashGap;
		rtnObj.valueOnRight = valueOnRight;
		//Flag whether trend line is proper
		rtnObj.isValid = true;
		//Holders for dimenstions
		rtnObj.y = 0;
		rtnObj.toY = 0;
		//Text box y position
		rtnObj.tbY = 0;
		//Return
		return rtnObj;
	}
	/**
	* returnDataAsVLineObj method takes in functional parameters, and creates
	* an object to represent the vertical axis distribution line as a unified object.
	*	@param	index		Index of the vertical line w.r.t data specified.
	*	@param	label		Label of the vLine
	*	@param	color		Color of the vertical line.
	*	@param	thickness	Thickness of the line.
	*	@param	alpha		Alpha of the line.
	*	@param	isDashed	Whether the line should appear as dashed.
	*	@param	dashLen		Length of dash (if isDashed).
	*	@param	dashGap		Gap length (if isDashed)
	*	@return				An object encapsulating these values.
	*/
	private function returnDataAsVLineObj(index:Number, label:String, color:String, thickness:Number, alpha:Number, isDashed:Boolean, dashLen:Number, dashGap:Number):Object {
		//Create an object that will be returned.
		var rtnObj:Object = new Object ();
		//Store parameters as object properties
		rtnObj.index = index;
		rtnObj.label = label;
		rtnObj.color = color;
		rtnObj.thickness = thickness;
		rtnObj.alpha = alpha;
		rtnObj.isDashed = isDashed;
		rtnObj.dashLen = dashLen;
		rtnObj.dashGap = dashGap;
		//Set a flag for validity
		rtnObj.isValid = true;
		//Holders for dimenstions
		rtnObj.x = 0;
		//Return
		return rtnObj;
	}
	/**
	* parseVLineNode method parses the vertical line node and stores it in
	* local objects
	*	@param	vLineNode	XML Node representing the vertical axis division
	*						line.
	*	@param	index		Index of the division line. Index represents the
	*						numerical index of data item/category on the left
	*						side of v line.
	*/
	private function parseVLineNode (vLineNode:XMLNode, index:Number):Void{
		//Variables for local use
		var label:String, color:String, thickness:Number, alpha:Number;
		var isDashed:Boolean, dashLen:Number, dashGap:Number;
		//Increment count
		this.numVLines ++;
		//Get attributes array
		var lineAttr:Array = Utils.getAttributesArray (vLineNode);
		//Extract attributes
		label = getFV(lineAttr["label"],"");
		color = String (formatColor (getFV (lineAttr ["color"] , "333333")));
		thickness = getFN (lineAttr ["thickness"] , 1);
		alpha = getFN (lineAttr ["alpha"] , 80);
		isDashed = toBoolean (Number (getFV (lineAttr ["dashed"] , 0)));
		dashLen = getFN (lineAttr ["dashlen"] , 5);
		dashGap = getFN (lineAttr ["dashgap"] , 2);
		//Create object and store
		this.vLines[this.numVLines] = this.returnDataAsVLineObj(index, label, color, thickness, alpha, isDashed, dashLen, dashGap);
	}
	/**
	* parseTrendLineXML method parses the XML node containing trend line nodes
	* and then stores it in local objects.
	*	@param		arrTrendLineNodes		Array containing Trend LINE nodes.
	*	@return							Nothing.
	*/
	private function parseTrendLineXML (arrTrendLineNodes:Array):Void {
		//Define variables for local use
		var startValue:Number, endValue:Number, displayValue:String;
		var color:String, thickness:Number, alpha:Number;
		var isTrendZone:Boolean, showOnTop:Boolean, isDashed:Boolean;
		var dashLen:Number, dashGap:Number, valueOnRight:Boolean;
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
				displayValue = lineAttr["displayvalue"];
				color = String (formatColor (getFV (lineAttr ["color"] , "333333")));
				thickness = getFN (lineAttr ["thickness"] , 1);
				isTrendZone = toBoolean (Number (getFV (lineAttr ["istrendzone"] , 0)));
				alpha = getFN (lineAttr ["alpha"] , (isTrendZone == true) ? 40:99);
				showOnTop = toBoolean (getFN (lineAttr ["showontop"] , 0));
				isDashed = toBoolean (getFN (lineAttr ["dashed"] , 0));
				dashLen = getFN (lineAttr ["dashlen"] , 5);
				dashGap = getFN (lineAttr ["dashgap"] , 2);
				valueOnRight = toBoolean (getFN (lineAttr ["valueonright"] , 0));
				//Create trend line object
				this.trendLines[numTrendLines] = returnDataAsTrendObj (startValue, endValue, displayValue, color, thickness, alpha, isTrendZone, showOnTop, isDashed, dashLen, dashGap, valueOnRight);
				//Update numTrendLinesBelow
				numTrendLinesBelow = (showOnTop == false) ? (++numTrendLinesBelow):numTrendLinesBelow;
			}
		}
	}
	/**
	 * setTrendDisplayValues method sets the formatted display value
	 * for each trend line. This is because, the trend lines for a chart
	 * are defined only once (from initial XML). As such, we store all formatted
	 * display values initially, and later just show them after validating/in-validating
	 * each trend line.
	 * Here, we also eliminate those trend lines, whose values are non numeric.
	*/
	private function setTrendDisplayValues():Void{
		//Loop variable
		var i:Number;
		//Array to store indexes of trendlines that we've to filter out (bad ones)
		var slIndex:Array = new Array();
		//Number of trend lines below, that we've to filter
		var slCntBelow:Number = 0;
		for (i=1; i <=this.numTrendLines; i++){
			//If the trend line start/end value is NaN, we remove the trend line from our storage
			//This optimizes the run, as we do not have to iterate through an invalid trend-line
			//each time.
			if (isNaN(this.trendLines[i].startValue) || isNaN(this.trendLines[i].endValue)){
				//Push the index of this trend line in our removal index array
				slIndex.push(i);
				//If the trend line was to show below, increase count to remove that.
				if (!this.trendLines[i].showOnTop){
					slCntBelow++;
				}				
			} else {
				//We set displayValue				
				this.trendLines [i].displayValue = getFV(this.trendLines[i].displayValue, this.nf.formatNumber(this.trendLines[i].startValue, this.params.formatNumber, this.params.formatNumberScale, this.params.yAxisValueDecimals, this.params.forceYAxisDecimals));
			}
		}
		//Now, if we've to remove any trendlines, do so
		if (slIndex.length>0){
			//Decrease global count
			this.numTrendLines = this.numTrendLines - slIndex.length;
			//Decrease count of global below-plot trendlines
			this.numTrendLinesBelow = this.numTrendLinesBelow - slCntBelow;
			//Slice out the trendlines one by one
			for (i=0; i<slIndex.length; i++){
				//Account for trend lines filtered in this loop itself
				this.trendLines.splice(slIndex[i]-i,1);
			}
		}
	}
	/**
	* validateTrendLines method helps us validate the different trend line
	* points entered by user in XML. Some trend points may fall out of
	* chart range (yMin,yMax) and we need to invalidate them. 
	* Whenever the chart axis gets updated in real-time (changed), this method
	* is invoked to check which trendlines are valid again.
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
			//We do not have to check for NaN, as those trend lines have already been 
			//eliminated by setTrendDisplayValues method.
			if ((this.trendLines [i].startValue<this.pAxis.getYMin()) || (this.trendLines [i].startValue > this.pAxis.getYMax()) || (this.trendLines [i].endValue < this.pAxis.getYMin()) || (this.trendLines[i].endValue>this.pAxis.getYMax())){
				//Invalidate it
				this.trendLines [i].isValid = false;
			} else {
				//Mark it as valid
				this.trendLines [i].isValid = true;
			}
		}
	}
	/**
	 * calculateCanvasCoords method calculates the co-ordinates for the 
	 * chart canvas, keeping all the chart elements in consideration. It finally
	 * stores the dimensions of the canvas in this.elements.canvas chart object.
	*/
	private function calculateCanvasCoords():Void{
		//Loop variable
		var i : Number;
		var j : Number;
		//We now need to calculate the available Width on the canvas.
		//Available width = total Chart width minus the list below
		// - Left and Right Margin
		// - yAxisName (if to be shown)
		// - yAxisValues
		// - Trend line display values (both left side and right side).
		// - Legend (If to be shown at right)
		var canvasWidth : Number = this.width - (this.params.chartLeftMargin + this.params.chartRightMargin);
		//Set canvas startX
		var canvasStartX : Number = this.params.chartLeftMargin;
		//Now, if y-axis name is to be shown, simulate it and get the width
		if (this.params.yAxisName != ""){
			//Get style object
			var yAxisNameStyle : Object = this.styleM.getTextStyle(this.objects.YAXISNAME);
			if (this.params.rotateYAxisName){
				//Create text field to get width
				var yAxisNameObj : Object = createText (true, this.params.yAxisName, this.tfTestMC, 1, testTFX, testTFY, 90, yAxisNameStyle, false, 0, 0);
				//Accomodate width and padding
				canvasStartX = canvasStartX + yAxisNameObj.width + this.params.yAxisNamePadding;
				canvasWidth = canvasWidth - yAxisNameObj.width - this.params.yAxisNamePadding;
				//Create element for yAxisName - to store width/height
				this.elements.yAxisName = returnDataAsElement (0, 0, yAxisNameObj.width, yAxisNameObj.height);
			} else {
				//If the y-axis name is not to be rotated
				//Calculate the width of the text if in full horizontal mode
				//Create text field to get width
				var yAxisNameObj : Object = createText (true, this.params.yAxisName, this.tfTestMC, 1, testTFX, testTFY, 0, yAxisNameStyle, false, 0, 0);
				//Get a value for this.params.yAxisNameWidth
				this.params.yAxisNameWidth = Number (getFV (this.params.yAxisNameWidth, yAxisNameObj.width));
				//Get the lesser of the width (to avoid un-necessary space)
				this.params.yAxisNameWidth = Math.min (this.params.yAxisNameWidth, yAxisNameObj.width);
				//Accomodate width and padding
				canvasStartX = canvasStartX + this.params.yAxisNameWidth + this.params.yAxisNamePadding;
				canvasWidth = canvasWidth - this.params.yAxisNameWidth - this.params.yAxisNamePadding;
				//Create element for yAxisName - to store width/height
				this.elements.yAxisName = returnDataAsElement (0, 0, this.params.yAxisNameWidth, yAxisNameObj.height);
			}
			delete yAxisNameStyle;
			delete yAxisNameObj;
		}
		//Accomodate width for y-axis values. Now, y-axis values conists of two parts
		//(for backward compatibility) - limits (upper and lower) and div line values.
		//So, we'll have to individually run through both of them.
		var yAxisValMaxWidth : Number = 0;
		var divLineObj : Object;
		var divStyle : Object = this.styleM.getTextStyle (this.objects.YAXISVALUES);
		//Iterate through all the div line values
		for (i = 1; i < this.divLines.length; i ++){
			//If div line value is to be shown
			if (this.divLines [i].showValue){
				//If it's the first or last div Line (limits), and it's to be shown
				if ((i == 1) || (i == this.divLines.length - 1)){
					if (this.params.showLimits)	{
						//Get the width of the text
						divLineObj = createText (true, this.divLines [i].displayValue, this.tfTestMC, 1, testTFX, testTFY, 0, divStyle, false, 0, 0);
						//Accomodate
						yAxisValMaxWidth = (divLineObj.width > yAxisValMaxWidth) ? (divLineObj.width) : (yAxisValMaxWidth);
					}
				} else 	{
					//It's a div interval - div line
					//So, check if we've to show div line values
					if (this.params.showDivLineValues){
						//Get the width of the text
						divLineObj = createText (true, this.divLines [i].displayValue, this.tfTestMC, 1, testTFX, testTFY, 0, divStyle, false, 0, 0);
						//Accomodate
						yAxisValMaxWidth = (divLineObj.width > yAxisValMaxWidth) ? (divLineObj.width) : (yAxisValMaxWidth);
					}
				}
			}
		}
		delete divLineObj;
		//Also iterate through all trend lines whose values are to be shown on
		//left side of the canvas.
		//Get style object
		var trendStyle : Object = this.styleM.getTextStyle (this.objects.TRENDVALUES);
		var trendObj : Object;
		for (i = 1; i <= this.numTrendLines; i ++){
			if (this.trendLines [i].isValid == true && this.trendLines [i].valueOnRight == false){
				//If it's a valid trend line and value is to be shown on left
				//Get the width of the text
				trendObj = createText (true, this.trendLines [i].displayValue, this.tfTestMC, 1, testTFX, testTFY, 0, trendStyle, false, 0, 0);
				//Accomodate
				yAxisValMaxWidth = (trendObj.width > yAxisValMaxWidth) ? (trendObj.width) : (yAxisValMaxWidth);
			}
		}
		//Accomodate for y-axis/left-trend line values text width
		if (yAxisValMaxWidth > 0){
			canvasStartX = canvasStartX + yAxisValMaxWidth + this.params.yAxisValuesPadding;
			canvasWidth = canvasWidth - yAxisValMaxWidth - this.params.yAxisValuesPadding;
		}
		var trendRightWidth : Number = 0;
		//Now, also check for trend line values that fall on right
		for (i = 1; i <= this.numTrendLines; i ++){
			if (this.trendLines [i].isValid == true && this.trendLines [i].valueOnRight == true){
				//If it's a valid trend line and value is to be shown on right
				//Get the width of the text
				trendObj = createText (true, this.trendLines [i].displayValue, this.tfTestMC, 1, testTFX, testTFY, 0, trendStyle, false, 0, 0);
				//Accomodate
				trendRightWidth = (trendObj.width > trendRightWidth) ? (trendObj.width) : (trendRightWidth);
			}
		}
		delete trendObj;
		//Accomodate trend right text width
		if (trendRightWidth>0){
			canvasWidth = canvasWidth - trendRightWidth - this.params.yAxisValuesPadding;
		}
		//Round them off finally to avoid distorted pixels
		canvasStartX = int (canvasStartX);
		canvasWidth = int (canvasWidth);		
		//We finally have canvas Width and canvas Start X
		//-----------------------------------------------------------------------------------//
		//Now, we need to calculate the available Height on the canvas.
		//Available height = total Chart height minus the list below
		// - Chart Top and Bottom Margins
		// - Space for Caption, Sub Caption and caption padding
		// - Height of data labels
		// - Height of real time value box
		// - xAxisName
		// - Legend (If to be shown at bottom position)
		//Initialize canvasHeight to total height minus margins
		var canvasHeight : Number = this.height - (this.params.chartTopMargin + this.params.chartBottomMargin);
		//Set canvasStartY
		var canvasStartY : Number = this.params.chartTopMargin;
		//Now, if we've to show caption
		if (this.params.caption != ""){
			//Create text field to get height
			var captionObj : Object = createText (true, this.params.caption, this.tfTestMC, 1, testTFX, testTFY, 0, this.styleM.getTextStyle (this.objects.CAPTION) , true, canvasWidth, canvasHeight/4);
			//Store the height
			canvasStartY = canvasStartY + captionObj.height;
			canvasHeight = canvasHeight - captionObj.height;
			//Create element for caption - to store width & height
			this.elements.caption = returnDataAsElement (0, 0, captionObj.width, captionObj.height);
			delete captionObj;
		}
		//Now, if we've to show sub-caption
		if (this.params.subCaption != ""){
			//Create text field to get height
			var subCaptionObj : Object = createText (true, this.params.subCaption, this.tfTestMC, 1, testTFX, testTFY, 0, this.styleM.getTextStyle (this.objects.SUBCAPTION) , true, canvasWidth, canvasHeight/4);
			//Store the height
			canvasStartY = canvasStartY + subCaptionObj.height;
			canvasHeight = canvasHeight - subCaptionObj.height;
			//Create element for sub caption - to store height
			this.elements.subCaption = returnDataAsElement (0, 0, subCaptionObj.width, subCaptionObj.height);
			delete subCaptionObj;
		}
		//Now, if either caption or sub-caption was shown, we also need to adjust caption padding
		if (this.params.caption != "" || this.params.subCaption != ""){
			//Account for padding
			canvasStartY = canvasStartY + this.params.captionPadding;
			canvasHeight = canvasHeight - this.params.captionPadding;
		}
		//Now, if data labels are to be shown, we need to account for their heights
		//Data labels can be rendered in 3 ways:
		//1. Normal - no staggering - no wrapping - no rotation
		//2. Wrapped - no staggering - no rotation
		//3. Staggered - no wrapping - no rotation
		//4. Rotated - no staggering - no wrapping
		//Placeholder to store max height
		this.config.maxLabelHeight = 0;
		this.config.labelAreaHeight = 0;
		var labelObj : Object;
		var labelStyleObj : Object = this.styleM.getTextStyle (this.objects.DATALABELS);
		if (this.params.labelDisplay == "ROTATE"){
			//Case 4: If the labels are rotated, we iterate through all the string labels
			//provided to us and get the height and store max.
			for (i = 1; i <= this.num; i ++){
				//If the label is to be shown
				if (this.categories [i].showLabel){
					//Create text box and get height
					labelObj = createText (true, this.categories [i].label, this.tfTestMC, 1, testTFX, testTFY, this.config.labelAngle, labelStyleObj, false, 0, 0);
					//Store the larger
					this.config.maxLabelHeight = (labelObj.height > this.config.maxLabelHeight) ? (labelObj.height) : (this.config.maxLabelHeight);
				}
			}
			//Store max label height as label area height.
			this.config.labelAreaHeight = this.config.maxLabelHeight;
		} else if (this.params.labelDisplay == "WRAP"){
			//Case 2 (WRAP): Create all the labels on the chart. Set width as
			//totalAvailableWidth/finalVisibleCount.
			//Set max height as 50% of available canvas height at this point of time. Find all
			//and select the max one.
			var maxLabelWidth : Number = (canvasWidth / this.params.finalVisibleCount);
			var maxLabelHeight : Number = (canvasHeight / 2);
			//Store it in config for later usage
			this.config.wrapLabelWidth = maxLabelWidth;
			this.config.wrapLabelHeight = maxLabelHeight;
			for (i = 1; i <= this.num; i ++){
				//If the label is to be shown
				if (this.categories [i].showLabel){
					//Create text box and get height
					labelObj = createText (true, this.categories [i].label, this.tfTestMC, 1, testTFX, testTFY, 0, labelStyleObj, true, maxLabelWidth, maxLabelHeight);
					//Store the larger
					this.config.maxLabelHeight = (labelObj.height > this.config.maxLabelHeight) ? (labelObj.height) : (this.config.maxLabelHeight);
				}
			}
			//Store max label height as label area height.
			this.config.labelAreaHeight = this.config.maxLabelHeight;
		} else {
			//Case 1,3: Normal or Staggered Label
			//We iterate through all the labels, and if any of them has &lt or < (HTML marker)
			//embedded in them, we add them to the array, as for them, we'll need to individually
			//create and see the text height. Also, the first element in the array - we set as
			//ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890_=....
			//Create array to store labels.
			var strLabels : Array = new Array ();
			strLabels.push ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890_=/*-+~`");
			//Now, iterate through all the labels and for those visible labels, whcih have < sign,
			//add it to array.
			for (i = 1; i <= this.num; i ++){
				//If the label is to be shown
				if (this.categories [i].showLabel){
					if ((this.categories [i].label.indexOf ("&lt;") > - 1) || (this.categories [i].label.indexOf ("<") > - 1)){
						strLabels.push (this.categories [i].label);
					}
				}
			}
			//Now, we've the array for which we've to check height (for each element).
			for (i = 0; i < strLabels.length; i ++){
				//Create text box and get height
				labelObj = createText (true, this.categories [i].label, this.tfTestMC, 1, testTFX, testTFY, 0, labelStyleObj, false, 0, 0);
				//Store the larger
				this.config.maxLabelHeight = (labelObj.height > this.config.maxLabelHeight) ? (labelObj.height) : (this.config.maxLabelHeight);
			}
			//We now have the max label height. If it's staggered, then store accordingly, else
			//simple mode
			if (this.params.labelDisplay == "STAGGER"){
				//Multiply max label height by stagger lines.
				this.config.labelAreaHeight = this.params.staggerLines * this.config.maxLabelHeight;
			} else {
				this.config.labelAreaHeight = this.config.maxLabelHeight;
			}
		}
		if (this.config.labelAreaHeight > 0){
			//Deduct the calculated label height from canvas height
			canvasHeight = canvasHeight - this.config.labelAreaHeight - this.params.labelPadding;
		}
		//Delete objects
		delete labelObj;
		delete labelStyleObj;
		//Accomodate space for real-time value (if to be shown);
		//Object to store properties of real time value - we keep it outside loop, as x-axis name
		//also uses it. Else, it would return undefined
		this.elements.realTimeValue = returnDataAsElement (0, 0, 0, 0);
		if (this.params.showRealTimeValue){
			//Create text field to get height
			var realTimeValueObj: Object = createText (true, "123", this.tfTestMC, 1, testTFX, testTFY, 0, this.styleM.getTextStyle(this.objects.REALTIMEVALUE) , false, 0, 0);
			//Store the height
			canvasHeight = canvasHeight - realTimeValueObj.height - this.params.realTimeValuePadding;
			//Update properties
			this.elements.realTimeValue.w = realTimeValueObj.width;
			this.elements.realTimeValue.h = realTimeValueObj.height;
			delete realTimeValueObj;
		}
		
		//Accomodate space for xAxisName (if to be shown);
		if (this.params.xAxisName != ""){
			//Create text field to get height
			var xAxisNameObj : Object = createText (true, this.params.xAxisName, this.tfTestMC, 1, testTFX, testTFY, 0, this.styleM.getTextStyle (this.objects.XAXISNAME) , false, 0, 0);
			//Store the height
			canvasHeight = canvasHeight - xAxisNameObj.height - this.params.xAxisNamePadding;
			//Object to store width and height of xAxisName
			this.elements.xAxisName = returnDataAsElement (0, 0, xAxisNameObj.width, xAxisNameObj.height);
			delete xAxisNameObj;
		}
		//We have canvas start Y and canvas height
		//We now check whether the legend is to be drawn
		if (this.params.showLegend){
			//Object to store dimensions
			var lgndDim:Object;
			//Create container movie clip for legend
			this.lgndMC = this.cMC.createEmptyMovieClip ("Legend", this.dm.getDepth ("LEGEND"));
			//Create instance of legend
			if (this.params.legendPosition == "BOTTOM"){
				//Maximum Height - 50% of stage
				lgnd = new Legend (lgndMC, this.styleM.getTextStyle (this.objects.LEGEND) , this.params.interactiveLegend, this.params.legendPosition, canvasStartX + canvasWidth / 2, this.height / 2, canvasWidth, (this.height - (this.params.chartTopMargin + this.params.chartBottomMargin)) * 0.5, this.params.legendAllowDrag, this.width, this.height, this.params.legendBgColor, this.params.legendBgAlpha, this.params.legendBorderColor, this.params.legendBorderThickness, this.params.legendBorderAlpha, this.params.legendScrollBgColor, this.params.legendScrollBarColor, this.params.legendScrollBtnColor);
			} else {
				//Maximum Width - 40% of stage
				lgnd = new Legend (lgndMC, this.styleM.getTextStyle (this.objects.LEGEND) , this.params.interactiveLegend, this.params.legendPosition, this.width / 2, canvasStartY + canvasHeight / 2, (this.width - (this.params.chartLeftMargin + this.params.chartRightMargin)) * 0.4, canvasHeight, this.params.legendAllowDrag, this.width, this.height, this.params.legendBgColor, this.params.legendBgAlpha, this.params.legendBorderColor, this.params.legendBorderThickness, this.params.legendBorderAlpha, this.params.legendScrollBgColor, this.params.legendScrollBarColor, this.params.legendScrollBtnColor);
			}
			//If user has defined a caption for the legend, set it
			if (this.params.legendCaption!=""){
				lgnd.setCaption(this.params.legendCaption);
			}
			//Whether to use circular marker
			lgnd.useCircleMarker(this.params.legendMarkerCircle);
			//Feed data set series Name for legend
			if (this.params.reverseLegend){
				for (i = this.numDS; i >=1; i --)
				{
					if (this.dataset [i].includeInLegend && this.dataset [i].seriesName != "")
					{
						lgnd.addItem (this.dataset [i].seriesName, this.dataset [i].color);
					}
				}
			}else{
				for (i = 1; i <= this.numDS; i ++){
					if (this.dataset [i].includeInLegend && this.dataset [i].seriesName != ""){
						lgnd.addItem (this.dataset [i].seriesName, this.dataset [i].color, i);
					}
				}
			}
			//Get dimensions of the legend
			lgndDim = lgnd.getDimensions ();
			//Now, based on whether we've to show the legend at right or bottom, adjust the
			//canvas accordingly
			if (this.params.legendPosition == "BOTTOM"){
				//Now deduct the height from the calculated canvas height
				canvasHeight = canvasHeight - lgndDim.height - this.params.legendPadding;
				//Re-set the legend position
				this.lgnd.resetXY (canvasStartX + canvasWidth / 2, this.height - this.params.chartBottomMargin - lgndDim.height / 2);
			} else {				
				//Now deduct the width from the calculated canvas width
				canvasWidth = canvasWidth - lgndDim.width - this.params.legendPadding;
				//Right position
				this.lgnd.resetXY (this.width - this.params.chartRightMargin - lgndDim.width / 2, canvasStartY + canvasHeight / 2);
			}
		}
		//Create an element to represent the canvas now.
		//Before doing so, we take into consideration, user's forced canvas margins (if any defined)
		//If the user's forced values result in overlapping of chart items, we ignore.
		if (this.params.canvasLeftMargin!=-1 && this.params.canvasLeftMargin>canvasStartX){
			//Update width (deduct the difference)
			canvasWidth = canvasWidth - (this.params.canvasLeftMargin-canvasStartX);
			//Update left start position
			canvasStartX = this.params.canvasLeftMargin;		
		}
		if (this.params.canvasRightMargin!=-1 && (this.params.canvasRightMargin>(this.width - (canvasStartX+canvasWidth)))){
			//Update width (deduct the difference)
			canvasWidth = canvasWidth - (this.params.canvasRightMargin-(this.width - (canvasStartX+canvasWidth)));			
		}
		if (this.params.canvasTopMargin!=-1 && this.params.canvasTopMargin>canvasStartY){
			//Update height (deduct the difference)
			canvasHeight = canvasHeight - (this.params.canvasTopMargin-canvasStartY);
			//Update top start position
			canvasStartY = this.params.canvasTopMargin;		
		}
		if (this.params.canvasBottomMargin!=-1 && (this.params.canvasBottomMargin>(this.height - (canvasStartY+canvasHeight)))){
			//Update height(deduct the difference)
			canvasHeight = canvasHeight - (this.params.canvasBottomMargin-(this.height - (canvasStartY+canvasHeight)));
		}
		//Finally, we've sorted out canvas positions. So, create an element.
		this.elements.canvas = returnDataAsElement (canvasStartX, canvasStartY, canvasWidth, canvasHeight);
		//Also, convey it to our axis
		this.pAxis.setAxisCoords(this.elements.canvas.y, this.elements.canvas.toY);
	}
	/**
	* calcTrendLinePos method helps us calculate the y-co ordinates for the
	* trend lines
	* NOTE: validateTrendLines and calcTrendLinePos could have been composed
	*			into a single method. However, in calcTrendLinePos, we need the
	*			canvas position, which is possible only after calculatePoints
	*			method has been called. But, in calculatePoints, we need the
	*			displayValue of each trend line, which is being set in
	*			validateTrendLines. So, validateTrendLines is invoked before
	*			calculatePoints method and calcTrendLinePos is invoked after.
	*	@return		Nothing
	*/
	private function calcTrendLinePos():Void{
		//Loop variable
		var i:Number;
		for (i = 1; i <= this.numTrendLines; i ++){
			//We proceed only if the trend line is valid
			if (this.trendLines [i].isValid == true){
				//Calculate and store y-positions
				this.trendLines [i].y = this.pAxis.getAxisPosition (this.trendLines[i].startValue, false);
				//If end value is different from start value
				if (this.trendLines [i].startValue != this.trendLines [i].endValue)	{
					//Calculate y for end value
					this.trendLines [i].toY = this.pAxis.getAxisPosition (this.trendLines [i].endValue, false);
					//Now, if it's a trend zone, we need mid value
					if (this.trendLines [i].isTrendZone){
						//For textbox y position, we need mid value.
						this.trendLines [i].tbY = Math.min (this.trendLines [i].y, this.trendLines [i].toY) + (Math.abs (this.trendLines [i].y - this.trendLines [i].toY) / 2);
					} else {
						//If the value is to be shown on left, then at left
						if (this.trendLines [i].valueOnRight){
							this.trendLines [i].tbY = this.trendLines [i].toY;
						} else {
							this.trendLines [i].tbY = this.trendLines [i].y;
						}
					}
					//Height
					this.trendLines [i].h = (this.trendLines [i].toY - this.trendLines [i].y);
				} else {
					//Just copy
					this.trendLines [i].toY = this.trendLines [i].y;
					//Set same position for value tb
					this.trendLines [i].tbY = this.trendLines [i].y;
					//Height
					this.trendLines [i].h = 0;
				}
			}
		}
	}
	/**
	* calcVLinesPos method calculates the x position for the various
	* vLines defined. Also, it validates them.
	*/
	private function calcVLinesPos(){
		//Array to store indexes of vLines that we've to filter out (invalid ones)
		var slIndex:Array = new Array();
		var i:Number;
		//Iterate through all the vLines
		for (i = 1; i <= this.numVLines; i ++){
			//If the vLine is after 1st data and before last data
			if (this.vLines [i].index > 0 && this.vLines [i].index < this.params.numDisplaySets){
				//Set it's x position
				this.vLines [i].x = this.dataPosX[this.vLines[i].index] + (this.dataPosX[this.vLines [i].index + 1] - this.dataPosX[this.vLines [i].index]) / 2;
			} else {
				//Push the index of this vLine in our removal index array
				slIndex.push(i);				
			}
		}
		//Now, if we've to remove any vLines, do so
		if (slIndex.length>0){
			//Decrease global count
			this.numVLines = this.numVLines - slIndex.length;
			//Slice out the vLines one by one
			for (i=0; i<slIndex.length; i++){
				//Account for vLines spliced previously in this loop itself.
				this.vLines.splice((slIndex[i]-i),1);
			}
		}
	}
	// ------------ REAL TIME UPDATE/REFRESH HANDLERS ----------//
	/**
	 * setUpdateInterval method is called to set the data fetch cycle
	 * interval for the chart. 
	*/
	private function setUpdateInterval():Void{
		if (this.params.dataStreamURL!="" && this.params.updateInterval>0){
			//Initialize LoadVars object
			this.lv = new LoadVars();		
			//Set flag that the chart is in self-updating mode
			this.isUpdating = true;
			//Reference to class
			var classRef = this;			
			//Define the events for LoadVars object - we define it only once.
			this.lv.onHTTPStatus = function(httpStatus:Number){
				//Just store the HTTP status in self
				this.httpStatus = httpStatus;				
			}
			this.lv.onLoad = function(success:Boolean){
				if (success){
					//We've successfully loaded data stream. So, carry on with parsing.
					classRef.parseDataFromLV();
				}else{
					//An error has occurred while loading the data. So, take action.
					classRef.handleLoadError();					
				}
			}
			this.uIntervalId = setInterval(Delegate.create(this,fetchData),this.params.updateInterval*1000);
			//Log info
			this.log("data Stream URL provided", "<A HREF='"+this.params.dataStreamURL+"' target='_blank'>"+this.params.dataStreamURL+"</A>", Logger.LEVEL.LINK);
			this.log("INFO","Setting the chart to update its data in " + this.params.updateInterval + " seconds.", Logger.LEVEL.INFO);
		}
		//Clear time interval - so that this method is called only once
		clearInterval(this.config.intervals.updateInterval);
	}	
	/**
	 * setRefreshInterval method is called to set the refresh cycle
	 * interval for the chart. 
	*/
	private function setRefreshInterval():Void{
		if (this.params.dataStreamURL!="" && this.params.refreshInterval>0){
			//Set the interval call
			this.rIntervalId = setInterval(Delegate.create(this,redrawChart),this.params.refreshInterval*1000);
			//Log info
			this.log("INFO","Setting the chart to re-draw itself in " + this.params.refreshInterval + " seconds.", Logger.LEVEL.INFO);
		}
		//Clear time interval - so that this method is called only once
		clearInterval(this.config.intervals.refreshInterval);
	}
	/**
	 * setClearChartInterval method is called to clear the chart at defined interval.
	*/
	private function setClearChartInterval():Void{
		if (this.params.clearChartInterval!=0){
			//Set the interval call
			this.cIntervalId = setInterval(Delegate.create(this,clearChart),this.params.clearChartInterval*1000);
			//Log info
			this.log("INFO","The chart will clear itself every " + this.params.clearChartInterval + " seconds.", Logger.LEVEL.INFO);
		}
		//Clear time interval - so that it's called only once
		clearInterval(this.config.intervals.clearChartInterval);
	}
	/**
	 * fetchData method is invoked by setUpdateInterval method every updateInterval
	 * second to send command for data stream feed load.
	*/
	private function fetchData():Void{
		//This method actually loads the data at the specified interval
		//We fetch data only if a previous LoadVars has complete, else we ignore
		//the call.
		if (!this.inLoadingProcess){
			//Update flag that we're now beginning the loading process
			this.inLoadingProcess = true;
			//Prepare the URL by adding the datastamp and timestamp (to avoid caching).
			var strURL = this.params.dataStreamURL + ((this.params.streamURLQMarkPresent)?("&FCTimeIndex="+getTimer()+"_"+Math.random()+"&dataStamp="+this.params.dataStamp):("?FCTimeIndex="+getTimer()+"_"+Math.random()+"&dataStamp="+this.params.dataStamp));
			//Invoke the URL to load data.
			this.lv.load(strURL);			
		} else {
			//We ignore overlapping calls to prevent memory leaks and/or browser crashes.
			//Can log messages here.
		}
	}
	/**
	 * stopUpdate method stops the automatic update of the chart.
 	 * Make this function public, so that if the real time chart is loaded inside other 
	 * Flash movies too, it can be stopped using this API.
	*/
	public function stopUpdate():Void{
		//We stop update only if the chart is in update mode
		if (this.isUpdating){
			//Log the event.
			this.log("Stopping Update","Forcing chart to stop update. The chart would not self-update any more.",Logger.LEVEL.INFO);
			//Clear the intervals.
			clearInterval(this.uIntervalId);
			clearInterval(this.rIntervalId);
			clearInterval(this.cIntervalId);
			//Set the flag that chart is not updating anymore
			this.isUpdating = false;
			//Re-set flags
			this.inLoadingProcess = false;
			this.chartDataChanged = false;
			//Delete the cache of Loadvars
			this.deleteLoadVarsCache();		
			//Delete loadVars events too
			delete this.lv.onHTTPStatus;
			delete this.lv.onLoad;
			//And finally delete the loadvars object itself
			delete this.lv;
			//Re-set context menu item
			this.setContextMenu();
		}
	}
	/**
	 * restartUpdate method restarts the update of the chart, after stopping it.
	 * Make this function public, so that if the real time chart is loaded inside other 
	 * Flash movies too, it can be restarted using this API.
	*/
	public function restartUpdate():Void{
		//We restart update, only if the update is stopped.
		if (!this.isUpdating){
			//Log a message, that the chart is set to restart
			this.log("Restarting Update","Restarting self update of the chart.",Logger.LEVEL.INFO);
			//Re-set the intervals
			this.setUpdateInterval();
			this.setRefreshInterval();
			this.setClearChartInterval();
			//Re-set context menu item
			this.setContextMenu();
		}
	}
	/**
	 * parseMultipleData data parses real time data feed containing 
	 * multiple data or values for multiple datasets.
	*/
	private function parseMultipleData(str:String):Array{
		//Loop variable
		var i:Number;
		//First split on | to separate out the datasets.
		var ar:Array = str.split("|");
		//Now, iterate through each dataset's values and separate on ,
		for (i=0; i<ar.length; i++){
			ar[i] = ar[i].split(",");
		}
		//Return the array.
		return ar;
	}
	/**
	 * deleteLoadVarsCache method deletes the data present in loadvars
	 * cache. This is to avoid pulling old data. We do NOT delete lv and re-initialize, 
	 * as that deletes the events too and also un-optimizes.
	*/
	private function deleteLoadVarsCache():Void{
		if (this.lv!=undefined){
			var item;
			for (item in this.lv){
				//If it's not onLoad on onHTTPStatus handler, delete it
				if (item!="onLoad" && item!="onHTTPStatus" && item!="onData"){
					//Delete it from loadvars
					delete this.lv[item];
				}
			}
		}
	}
	/**
	* handleLoadError method is called when an error occurred during loading data.
	*/
	private function handleLoadError():Void{
		//We first log the error in debug
		this.log("Error in loading stream data","The chart couldn't load data from the specified data stream URL. Error HTTP Status returned was: " + this.lv.httpStatus + ". Please make sure that your data stream provider page is present in the same sub-domain as the chart.", Logger.LEVEL.ERROR);
		//Update in-loading process, so that next stream can load
		this.inLoadingProcess = false; 
		//Now, individually deal with known error codes.		
		//Note that individual errors codes are not supplied to the chart by browsers
		//like Mozilla, Netscape, Opera etc. As such, those browsers will simply return 
		//a 0 value.
		if (this.lv.httpStatus==404) {
			//If status is 404, we set loadingProcess to true, as it makes no point
			//to make recusive calls to the same stream URL, when it's a 404 status			
			this.inLoadingProcess = true; 
			//Also, we can stop the chart from self updating here.
			this.stopUpdate();
			//Log the error
			this.log("Data Stream URL Not Found","The specified data stream URL doesn't exist. Stopping any further calls to the data stream URL.", Logger.LEVEL.ERROR);
		}
	}
	/**
	 * feedData accepts data as a string from the external interface and passes
	 * to chart for parsing. Make this function public, so that if the real time
	 * chart is loaded inside other Flash movies too, it can be updated using this
	 * API.
	 *	@param	dataStream	Querystring containing the data that is to be conveyed to chart.
	 *	@return				Nothing.
	*/
	public function feedData(dataStream:String):Void{
		//Parse the data in Loadvars object if stream is not null/undefined
		if (dataStream!="" && dataStream!=undefined && dataStream.length>1){
			//We first need to check if LoadVars is active- because any previous
			//stopUpdate calls could have nullified LoadVars. So, if it's undefined
			//we need to re-define the same.
			if (this.lv==undefined){
				this.lv = new LoadVars();
			}
			this.lv.decode(dataStream);
			//Now, parse the data into local objects and render chart.
			this.parseDataFromLV();
			//Re-draw the chart now
			this.redrawChart();
		}
	}
	/**
	 * getData method returns the data for the current state of chart.
	*/
	public function getData():Array{
		//Create a container array for returning
		var arrData:Array = new Array();
		//Initialize the arrData
		for (var i:Number=0; i<=this.num; i++) {
			//Create sub-arrays
			arrData[i] = new Array();
		}
		//Set 0,0 as empty
		arrData[0][0] ="";
		//Now, generate the categories elements
		for (i=1; i<=this.numDS; i++) {
			arrData[0][i] = this.dataset[i].seriesName;
			for (var j:Number=1; j<=this.num; j++) {
				arrData[j][0] = this.categories[j].label;
				if(this.dataset[i].data[j].isDefined) {
					arrData[j][i] = this.dataset[i].data[j].value;
				} else {
					arrData[j][i] = null;
				}
			}
		}
		return (arrData);		
	}
	// --------------------- FORWARD DECLARATIONS ------------------------//	
	public function clearChart():Void{
	}
	public function parseDataFromLV():Void{
	}
	public function redrawChart():Void{
	}
	//---------------------------- VISUAL RENDERING METHODS ------------------------------//
	/**
	* drawHeaders method renders the following on the chart:
	* CAPTION, SUBCAPTION, XAXISNAME, YAXISNAME
	*/
	private function drawHeaders (){
		//Render caption
		if (this.params.caption != ""){
			var captionStyleObj : Object = this.styleM.getTextStyle (this.objects.CAPTION);
			captionStyleObj.align = "center";
			captionStyleObj.vAlign = "bottom";
			var captionObj : Object = createText (false, this.params.caption, this.cMC, this.dm.getDepth ("CAPTION") , this.x + (this.width / 2) , this.params.chartTopMargin, 0, captionStyleObj, true, this.elements.caption.w, this.elements.caption.h);
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (captionObj.tf, this.objects.CAPTION, this.macro, this.x + (this.width / 2) - (this.elements.caption.w/2) , this.params.chartTopMargin, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (captionObj.tf, this.objects.CAPTION);
			//Delete
			delete captionObj;
			delete captionStyleObj;
		}
		//Render sub caption
		if (this.params.subCaption != ""){
			var subCaptionStyleObj : Object = this.styleM.getTextStyle (this.objects.SUBCAPTION);
			subCaptionStyleObj.align = "center";
			subCaptionStyleObj.vAlign = "top";
			var subCaptionObj : Object = createText (false, this.params.subCaption, this.cMC, this.dm.getDepth ("SUBCAPTION") , this.x + (this.width / 2) , this.elements.canvas.y - this.params.captionPadding, 0, subCaptionStyleObj, true, this.elements.subCaption.w, this.elements.subCaption.h);
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (subCaptionObj.tf, this.objects.SUBCAPTION, this.macro, this.x + (this.width / 2) - (this.elements.subCaption.w / 2) , this.elements.canvas.y - this.params.captionPadding - this.elements.subCaption.h, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (subCaptionObj.tf, this.objects.SUBCAPTION);
			//Delete
			delete subCaptionObj;
			delete subCaptionStyleObj;
		}
		//Render x-axis name
		if (this.params.xAxisName != ""){
			var xAxisNameStyleObj : Object = this.styleM.getTextStyle (this.objects.XAXISNAME);
			xAxisNameStyleObj.align = "center";
			xAxisNameStyleObj.vAlign = "bottom";
			var xAxisNameObj : Object = createText (false, this.params.xAxisName, this.cMC, this.dm.getDepth ("XAXISNAME") , this.elements.canvas.x + (this.elements.canvas.w / 2) , this.elements.canvas.toY + this.params.labelPadding + this.config.labelAreaHeight + this.params.realTimeValuePadding + this.elements.realTimeValue.h + this.params.xAxisNamePadding, 0, xAxisNameStyleObj, false, 0, 0);
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (xAxisNameObj.tf, this.objects.XAXISNAME, this.macro, this.elements.canvas.x + (this.elements.canvas.w / 2) - (this.elements.subCaption.w / 2) , this.elements.canvas.toY + this.config.labelAreaHeight + this.params.xAxisNamePadding + this.elements.realTimeValue.h + this.params.xAxisNamePadding, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (xAxisNameObj.tf, this.objects.XAXISNAME);
			//Delete
			delete xAxisNameObj;
			delete xAxisNameStyleObj;
		}
		//Render y-axis name
		if (this.params.yAxisName != ""){
			var yAxisNameStyleObj : Object = this.styleM.getTextStyle (this.objects.YAXISNAME);
			//Set alignment parameters
			yAxisNameStyleObj.align = "left";
			yAxisNameStyleObj.vAlign = "middle";
			//If the name is to be rotated
			if (this.params.rotateYAxisName){
				var yAxisNameObj : Object = createText (false, this.params.yAxisName, this.cMC, this.dm.getDepth ("YAXISNAME") , this.params.chartLeftMargin, this.elements.canvas.y + (this.elements.canvas.h / 2) , 270, yAxisNameStyleObj, false, 0, 0);
				//Apply animation
				if (this.params.animation){
					this.styleM.applyAnimation (yAxisNameObj.tf, this.objects.YAXISNAME, this.macro, this.params.chartLeftMargin, this.elements.canvas.y + (this.elements.canvas.h / 2) + (this.elements.yAxisName.h / 2) , 100, null, null, null);
				}
			} else {
				//We show horizontal name
				//Adding 1 to this.params.yAxisNameWidth and then passing to avoid line breaks
				var yAxisNameObj : Object = createText (false, this.params.yAxisName, this.cMC, this.dm.getDepth ("YAXISNAME") , this.params.chartLeftMargin, this.elements.canvas.y + (this.elements.canvas.h / 2) , 0, yAxisNameStyleObj, true, this.params.yAxisNameWidth + 1, this.elements.canvas.h);
				//Apply animation
				if (this.params.animation){
					this.styleM.applyAnimation (yAxisNameObj.tf, this.objects.YAXISNAME, this.macro, this.params.chartLeftMargin, yAxisNameObj.tf._y, 100, null, null, null);
				}
			}
			//Apply filters
			this.styleM.applyFilters (yAxisNameObj.tf, this.objects.YAXISNAME);
			//Delete
			delete yAxisNameObj;
			delete yAxisNameStyleObj;
		}
		//Clear Interval
		clearInterval (this.config.intervals.headers);
	}	
	/**
	* drawLabels method draws the x-axis labels based on the parameters.
	*/
	private function drawLabels(){
		//Clear existing data labels
		this.objM.removeGroupTF("DATALABELS");		
		var labelObj : Object;
		var labelStyleObj : Object = this.styleCache.dataLabels;
		var labelYShift : Number;
		var staggerCycle : Number = 0;
		var staggerAddFn : Number = 1;
		var depth : Number = this.dm.getDepth ("DATALABELS");
		var i : Number;
		for (i = 1; i <= this.num; i ++){
			//If the label is to be shown
			if (this.categories [i].showLabel){
				if (this.params.labelDisplay == "ROTATE"){
					labelStyleObj.align = "center";
					labelStyleObj.vAlign = "bottom";
					//Create text box and get height
					labelObj = createText (false, this.categories[i].label, this.cMC, depth, this.dataPosX[this.params.numDisplaySets-this.num+i], this.elements.canvas.toY + this.params.labelPadding, this.config.labelAngle, labelStyleObj, false, 0, 0);
				} else if (this.params.labelDisplay == "WRAP"){
					//Case 2 (WRAP)
					//Set alignment
					labelStyleObj.align = "center";
					labelStyleObj.vAlign = "bottom";
					labelObj = createText (false, this.categories [i].label, this.cMC, depth, this.dataPosX[this.params.numDisplaySets-this.num+i], this.elements.canvas.toY + this.params.labelPadding, 0, labelStyleObj, true, this.config.wrapLabelWidth, this.config.wrapLabelHeight);
				} else if (this.params.labelDisplay == "STAGGER"){
					//Case 3 (Stagger)
					//Set alignment
					labelStyleObj.align = "center";
					labelStyleObj.vAlign = "bottom";
					//Need to get cyclic position for staggered textboxes
					//Matrix formed is of 2*this.params.staggerLines - 2 rows
					var pos : Number = i % (2 * this.params.staggerLines - 2);
					//Last element needs to be reset
					pos = (pos == 0) ? (2 * this.params.staggerLines - 2) : pos;
					//Cyclic iteration
					pos = (pos > this.params.staggerLines) ? (this.params.staggerLines - (pos % this.params.staggerLines)) : pos;
					//Get position to 0 base
					pos --;
					//Shift accordingly
					var labelYShift : Number = this.config.maxLabelHeight * pos;
					labelObj = createText (false, this.categories [i].label, this.cMC, depth, this.dataPosX[this.params.numDisplaySets-this.num+i], this.elements.canvas.toY + this.params.labelPadding + labelYShift, 0, labelStyleObj, false, 0, 0);
				} else {
					//Render normal label
					labelStyleObj.align = "center";
					labelStyleObj.vAlign = "bottom";
					labelObj = createText (false, this.categories [i].label, this.cMC, depth, this.dataPosX[this.params.numDisplaySets-this.num+i], this.elements.canvas.toY + this.params.labelPadding, 0, labelStyleObj, false, 0, 0);
				}
				//Apply filter
				labelObj.tf.filters = this.styleCache.dataLabelFilters;
				//Apply animation
				if (this.params.animation){
					this.styleM.applyAnimation (labelObj.tf, this.objects.DATALABELS, this.macro, labelObj.tf._x, labelObj.tf._y, 100, null, null, null);
				}
				//Register
				this.objM.register(labelObj.tf, "DATALABEL_"+i, "DATALABELS");
				//Increase depth
				depth ++;
			}
		}
		//Clear interval
		if (!this.params.chartRendered){
			clearInterval (this.config.intervals.labels);
		}
	}
	/**
	* drawVLines method draws the vertical axis lines on the chart
	*/
	private function drawVLines ():Void {
		//Clear existing vlines lines.
		this.objM.removeGroupMC("VLINES");
		this.objM.removeGroupTF("VLINELABELS");
		//VLine text object
		var vLineLabel:Object;
		//Depth for vLine labels		
		var depth:Number = this.dm.getDepth ("VLINELABELS");
		//Text format for vLine labels
		var vLineFontObj = this.styleCache.vLineLabels;
		vLineFontObj.align = "center";
		vLineFontObj.vAlign = "bottom";
		//Create the movie clip container to store all vLines
		var vLineMC:MovieClip = this.cMC.createEmptyMovieClip("VLINES",this.dm.getDepth("VLINES"));
		//Register them with object manager
		this.objM.register(vLineMC, "VLINES", "VLINES");
		//Loop var
		var i:Number;
		var labelHeight:Number = 0;
		//Iterate through all the v lines
		for (i = 1; i <= this.numVLines; i ++){					
			//Set cosmetics for font.
			vLineFontObj.borderColor = this.vLines[i].color;
			vLineFontObj.color = this.vLines[i].color;			
			//Create vLine label too
			//Re-set to 0
			labelHeight = 0;
			if (this.vLines[i].label!=""){
				//Create label
				vLineLabel = createText (false, this.vLines[i].label, this.cMC, depth, this.vLines[i].x, this.elements.canvas.y, 0, vLineFontObj, false, 0, 0);
				//Store label height
				labelHeight = vLineLabel.height;
				//Register with Object Manager
				this.objM.register(vLineLabel.tf,"VLINELABELS_"+i,"VLINELABELS");				
				//Animation and filter effect
				if (this.params.animation){
					this.styleM.applyAnimation (vLineLabel.tf, this.objects.VLINELABELS, this.macro, vLineLabel.tf._x, vLineLabel.tf._y, 100, null, null, null);
				}
				//Apply filters
				vLineLabel.tf.filters = this.styleCache.vLineLabelFilters;
				//Increase depth
				depth ++;
			}
			
			vLineMC.lineStyle (this.vLines[i].thickness, parseInt(this.vLines[i].color, 16) , this.vLines[i].alpha);
			//Now, if dashed line is to be drawn
			if (!this.vLines [i].isDashed){
				//Draw normal line line
				vLineMC.moveTo (this.vLines [i].x, this.elements.canvas.y + labelHeight);
				vLineMC.lineTo (this.vLines [i].x, this.elements.canvas.toY);
			} else {
				//Dashed Line line
				DrawingExt.dashTo (vLineMC, this.vLines [i].x, this.elements.canvas.y + labelHeight, this.vLines [i].x, this.elements.canvas.toY, this.vLines [i].dashLen, this.vLines [i].dashGap);
			}
			
		}
		//Apply animation and filters to vLine collectively
		if (this.params.animation){
			this.styleM.applyAnimation (vLineMC, this.objects.VLINES, this.macro, null, null, 100, null, null, null);
		}
		//Apply filters
		vLineMC.filters = this.styleCache.vLineFilters;
		delete vLineMC;
		//Clear interval
		if (!this.params.chartRendered){
			clearInterval (this.config.intervals.vLine);
		}
	}
	/**
	* drawTrendLines method draws the trend lines on the chart
	* with their respective values.
	*/
	private function drawTrendLines():Void {
		//Clear existing trend lines.
		this.objM.removeGroupMC("TRENDLINES");
		this.objM.removeGroupTF("TRENDVALUES");
		
		var trendFontObj:Object;
		var trendValueObj:Object;
		
		//Depth counter for trend values.
		var depth:Number = this.dm.getDepth ("TRENDVALUES");
		
		//Create 2 containers - one for trend lines below, and 1 for above
		var trendBelowMC:MovieClip = this.cMC.createEmptyMovieClip("TrendLines_Below",this.dm.getDepth("TRENDLINESBELOW"));
		var trendAboveMC:MovieClip = this.cMC.createEmptyMovieClip("TrendLines_Below",this.dm.getDepth("TRENDLINESABOVE"));
		
		//Register them with object manager
		this.objM.register(trendBelowMC, "TRENDBELOW", "TRENDLINES");
		this.objM.register(trendAboveMC, "TRENDABOVE", "TRENDLINES");
		
		//Dynamic reference pointer
		var trendLineMC:MovieClip;

		//Get font
		trendFontObj = this.styleCache.trendValues;
		//Set vertical alignment
		trendFontObj.vAlign = "middle";
		//Loop variable
		var i:Number;
		var tbAnimX:Number;
		//Iterate through all the trend lines
		for (i = 1; i <= this.numTrendLines; i ++){
			//If it's a valid trend line			
			if (this.trendLines [i].isValid == true){
				//Get reference to the correct movie clip, based on whether we've to show
				//the trend line/zone below/above data points
				trendLineMC = (this.trendLines [i].showOnTop)?trendAboveMC:trendBelowMC;
				//Now, draw the line or trend zone
				if (this.trendLines [i].isTrendZone){
					//Create rectangle
					trendLineMC.lineStyle();
					//Begin fill
					trendLineMC.beginFill(parseInt (this.trendLines [i].color, 16) , this.trendLines [i].alpha);
					//Draw rectangle
					trendLineMC.moveTo(this.elements.canvas.x, this.trendLines[i].y);
					trendLineMC.lineTo(this.elements.canvas.toX, this.trendLines[i].y);
					trendLineMC.lineTo(this.elements.canvas.toX, this.trendLines[i].toY);
					trendLineMC.lineTo(this.elements.canvas.x, this.trendLines[i].toY);
					trendLineMC.lineTo(this.elements.canvas.x, this.trendLines[i].y);
				} else {
					//Just draw line
					trendLineMC.lineStyle (this.trendLines [i].thickness, parseInt (this.trendLines [i].color, 16) , this.trendLines [i].alpha);
					//Now, if dashed line is to be drawn
					if (!this.trendLines [i].isDashed){
						//Draw normal line line keeping 0,0 as registration point
						trendLineMC.moveTo (this.elements.canvas.x, this.trendLines[i].y);
						trendLineMC.lineTo (this.elements.canvas.toX, this.trendLines[i].toY);
					} else {
						//Dashed Line line
						DrawingExt.dashTo (trendLineMC, this.elements.canvas.x, this.trendLines[i].y, this.elements.canvas.toX, this.trendLines[i].toY, this.trendLines [i].dashLen, this.trendLines [i].dashGap);
					}
				}				
				//---------------------------------------------------------------------------//
				//Set color for font object
				trendFontObj.color = this.trendLines [i].color;
				//Now, render the trend line value, based on its position
				if (this.trendLines [i].valueOnRight == false){
					//Value to be placed on right
					trendFontObj.align = "right";
					//Create text
					trendValueObj = createText (false, this.trendLines [i].displayValue, this.cMC, depth, this.elements.canvas.x - this.params.yAxisValuesPadding, this.trendLines [i].tbY, 0, trendFontObj, false, 0, 0);					
					//X-position for text box animation
					tbAnimX = this.elements.canvas.x - this.params.yAxisValuesPadding - trendValueObj.width;
				} else {
					//Left side
					trendFontObj.align = "left";
					//Create text
					trendValueObj = createText (false, this.trendLines [i].displayValue, this.cMC, depth, this.elements.canvas.toX + this.params.yAxisValuesPadding, this.trendLines [i].tbY, 0, trendFontObj, false, 0, 0);
					//X-position for text box animation
					tbAnimX = this.elements.canvas.toX + this.params.yAxisValuesPadding;
				}
				//Register the text field with object manager
				this.objM.register(trendValueObj.tf,"TRENDVALUE_"+i,"TRENDVALUES");				
				//Animation and filter effect
				if (this.params.animation){
					this.styleM.applyAnimation (trendValueObj.tf, this.objects.TRENDVALUES, this.macro, tbAnimX, this.trendLines [i].tbY - (trendValueObj.height / 2) , 100, null, null, null);
				}
				//Apply filters
				trendValueObj.tf.filters = this.styleCache.trendValueFilters;
				//Increase depth
				depth++;
			}
			//Apply animation collectively to all trend lines contained in the single MC
			if (this.params.animation){
				this.styleM.applyAnimation(trendBelowMC, this.objects.TRENDLINES, this.macro, null, null, 100, null, null, null);
				this.styleM.applyAnimation(trendAboveMC, this.objects.TRENDLINES, this.macro, null, null, 100, null, null, null);
			}
			//Apply filters collectively
			trendBelowMC.filters = this.styleCache.trendLineFilters;
			trendAboveMC.filters = this.styleCache.trendLineFilters;
		}
		delete trendLineMC;
		delete trendValueObj;
		delete trendFontObj;
		//Clear interval - only if first time
		if (!this.params.chartRendered){
			clearInterval (this.config.intervals.trend);
		}
	}
	/**
	* drawDivLines method draws the div lines on the chart
	*/	
	private function drawDivLines():Void{
		//First, clear up existing div lines and their values
		this.objM.removeGroupMC("DIVLINES");
		this.objM.removeGroupTF("DIVVALUES");
		//Object containers
		var divLineValueObj:Object;
		var divLineFontObj:Object;
		var yPos:Number;
		//Single movie clip container for all div lines
		var divLineMC:MovieClip = this.cMC.createEmptyMovieClip ("DivLines", this.dm.getDepth("DIVLINES"));
		//Register it with object manager
		this.objM.register(divLineMC,"DIVLINES","DIVLINES");
		//Set cosmetic properties for line
		divLineMC.lineStyle (this.params.divLineThickness, parseInt (this.params.divLineColor, 16) , this.params.divLineAlpha);				
		//Get depth counter for labels
		var depth:Number = this.dm.getDepth("DIVVALUES")-1;
		//Get div line font
		divLineFontObj = this.styleCache.divLineValues;
		//Set alignment
		divLineFontObj.align = "right";
		divLineFontObj.vAlign = "middle";
		//Iterate through all the div line values
		var i:Number;
		for (i = 0; i < this.divLines.length; i ++){
			//If it's the first or last div Line (limits), and limits are to be shown
			if ((i == 0) || (i == this.divLines.length - 1)){
				if (this.params.showLimits && this.divLines [i].showValue){
					depth++;
					//Get y position for textbox
					yPos = this.pAxis.getAxisPosition (this.divLines[i].value, false);
					//Create the limits text
					divLineValueObj = createText (false, this.divLines [i].displayValue, this.cMC, depth, this.elements.canvas.x - this.params.yAxisValuesPadding, yPos, 0, divLineFontObj, false, 0, 0);
					//Register it with object manager
					this.objM.register(divLineValueObj.tf, "DIVVALUE_"+i, "DIVVALUES");
				}
			} else if (this.divLines [i].value == 0){
				//It's a zero value div line - check if we've to show
				if (this.params.showZeroPlane){
					//Depth for zero plane
					var zpDepth:Number = this.dm.getDepth ("ZEROPLANE");
					//Depth for zero plane value
					var zpVDepth:Number = zpDepth++;
					//Get y position
					yPos = this.pAxis.getAxisPosition (0, false);
					//Render the line
					var zeroPlaneMC = this.cMC.createEmptyMovieClip ("ZeroPlane", zpDepth);
					//Register with object manager under group DIVLINES - for single clear command
					this.objM.register(zeroPlaneMC, "ZEROPLANE", "DIVLINES");
					//Draw the line
					zeroPlaneMC.lineStyle (this.params.zeroPlaneThickness, parseInt (this.params.zeroPlaneColor, 16) , this.params.zeroPlaneAlpha);					
					if (this.params.divLineIsDashed){
						//Dashed line
						DrawingExt.dashTo (zeroPlaneMC, this.elements.canvas.x, yPos - (this.params.zeroPlaneThickness / 2), this.elements.canvas.toX, yPos - (this.params.zeroPlaneThickness / 2), this.params.divLineDashLen, this.params.divLineDashGap);
					} else {
						zeroPlaneMC.moveTo(this.elements.canvas.x, yPos - (this.params.zeroPlaneThickness / 2));
						//Normal line
						zeroPlaneMC.lineTo(this.elements.canvas.toX, yPos - (this.params.zeroPlaneThickness / 2));
					}
					//Apply animation and filter effects to div line
					if (this.params.animation){
						this.styleM.applyAnimation (zeroPlaneMC, this.objects.DIVLINES, this.macro, null, null, 100, null, null, null);
					}
					//Apply filters
					zeroPlaneMC.filters = this.styleCache.divLineFilters;
					//So, check if we've to show div line values
					if (this.params.showDivLineValues && this.divLines[i].showValue){
						//Create the text
						divLineValueObj = createText (false, this.divLines[i].displayValue, this.cMC, zpVDepth, this.elements.canvas.x - this.params.yAxisValuesPadding, yPos, 0, divLineFontObj, false, 0, 0);						
						//Register with object manager - under group DIVLINES itself
						this.objM.register(divLineValueObj.tf, "ZEROPLANEVALUE", "DIVVALUES");
					}
					//Apply animation and filter effects to div line (y-axis) values
					if (this.divLines [i].showValue){
						if (this.params.animation){
							this.styleM.applyAnimation (divLineValueObj.tf, this.objects.YAXISVALUES, this.macro, this.elements.canvas.x - this.params.yAxisValuesPadding - divLineValueObj.width, yPos - (divLineValueObj.height / 2), 100, null, null, null);
						}
						//Apply filters
						divLineValueObj.tf.filters = this.styleCache.divLineValueFilters;
					}
				}
			} else {
				//It's a div interval - div line
				//Get y position
				yPos = this.pAxis.getAxisPosition (this.divLines [i].value, false);
				if (this.params.divLineIsDashed){
					//Dashed line
					DrawingExt.dashTo (divLineMC, this.elements.canvas.x, yPos - (this.params.divLineThickness / 2), this.elements.canvas.toX, yPos - (this.params.divLineThickness / 2), this.params.divLineDashLen, this.params.divLineDashGap);
				} else {
					//Normal line
					divLineMC.moveTo (this.elements.canvas.x, yPos - (this.params.divLineThickness / 2));
					divLineMC.lineTo (this.elements.canvas.toX, yPos - (this.params.divLineThickness / 2));
				}
				//So, check if we've to show div line values
				if (this.params.showDivLineValues && this.divLines [i].showValue){
					//Increase Depth
					depth ++;
					//Create the text
					divLineValueObj = createText (false, this.divLines [i].displayValue, this.cMC, depth, this.elements.canvas.x - this.params.yAxisValuesPadding, yPos, 0, divLineFontObj, false, 0, 0);
					//Register
					this.objM.register(divLineValueObj.tf, "DIVVALUE_"+i, "DIVVALUES");
				}
			}
			//Apply animation and filter effects to div line (y-axis) values
			if (this.divLines[i].showValue)	{
				if (this.params.animation){
					this.styleM.applyAnimation (divLineValueObj.tf, this.objects.YAXISVALUES, this.macro, this.elements.canvas.x - this.params.yAxisValuesPadding - divLineValueObj.width, yPos - (divLineValueObj.height / 2) , 100, null, null, null);
				}
				//Apply filters
				divLineValueObj.tf.filters = this.styleCache.divLineValueFilters;
			}
		}
		//Apply animation and filter effects to div line collectively
		//Animation on zero plane was applied separately
		if (this.params.animation){
			this.styleM.applyAnimation (divLineMC, this.objects.DIVLINES, this.macro, null, null, 100, null, null, null);
		}
		divLineMC.filters = this.styleCache.divLineFilters;
		//Clear up memory
		delete divLineValueObj;
		delete divLineFontObj;
		//Clear interval - if first time
		if (!this.params.chartRendered){
			clearInterval (this.config.intervals.divLines);
		}
	}
	/**
	* drawHGrid method draws the horizontal grid background color
	*/
	private function drawHGrid():Void 	{
		//First, clear up existing Horizontal grid bands
		if (this.params.showAlternateHGridColor){
			this.objM.removeGroupMC("HGRID");		
		}
		//Now, if we're required to draw horizontal grid color and numDivLines > 3
		if (this.params.showAlternateHGridColor && this.divLines.length > 3){
			//Movie clip container
			var gridMC:MovieClip = this.cMC.createEmptyMovieClip ("HGRID", this.dm.getDepth("HGRID"));;
			//Register it with object manager
			this.objM.register(gridMC,"HGRID","HGRID");
			//Set cosmetics - line style to null
			gridMC.lineStyle();
			//Loop variable
			var i:Number;
			//Y Position
			var yPos:Number, yPosEnd:Number;
			for (i=1; i<this.divLines.length-1; i=i+2){
				//Get y position
				yPos = this.pAxis.getAxisPosition(this.divLines[i].value, false);
				yPosEnd = this.pAxis.getAxisPosition(this.divLines[i + 1].value, false);
				//Set fill color
				gridMC.beginFill (parseInt(this.params.alternateHGridColor, 16) , this.params.alternateHGridAlpha);
				//Create the rectangle for grid.
				gridMC.moveTo(this.elements.canvas.x , yPos);
				gridMC.lineTo(this.elements.canvas.toX , yPos);
				gridMC.lineTo(this.elements.canvas.toX , yPosEnd);
				gridMC.lineTo(this.elements.canvas.x , yPosEnd);
				gridMC.lineTo(this.elements.canvas.x , yPos);
				//End Fill
				gridMC.endFill ();				
			}
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (gridMC, this.objects.HGRID, this.macro, null, null, 100, null, null, null);
			}
			//Apply filters
			gridMC.filters = this.styleCache.hGridFilters;
		}
		//Clear interval
		if (!this.params.chartRendered){
			clearInterval (this.config.intervals.hGrid);
		}
	}
	/**
	* drawRealTimeValue method draws the real-time value textbox.
	*/
	private function drawRealTimeValue():Void{		
		//Clear existing real-time value
		this.objM.removeGroupTF("REALTIMEVALUE");		
		if (this.params.showRealTimeValue && this.num>0){			
			//Create local objects.
			var valueObj:Object;
			var valueStyleObj:Object = this.styleCache.realTimeValue;
			var i:Number
			var str:String="";
			for (i=1; i <= this.numDS; i ++){							
				str = str + this.dataset[i].data[this.num].displayValue + (((i<this.numDS) && (this.dataset[i+1].data[this.num].isDefined==true))?this.params.realTimeValueSep:"");
			}
			//Render normal label
			valueStyleObj.align = "center";
			valueStyleObj.vAlign = "bottom";
			valueObj = createText (false, str, this.cMC, depth, this.elements.canvas.x + this.elements.canvas.w/2, this.elements.canvas.toY + this.params.labelPadding + this.config.labelAreaHeight + this.params.realTimeValuePadding, 0, valueStyleObj, false, 0, 0);
			//Apply filter
			valueObj.tf.filters = this.styleCache.realTimeValueFilters;
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (valueObj.tf, this.objects.REALTIMEVALUE, this.macro, valueObj.tf._x, valueObj.tf._y, 100, null, null, null);
			}
			//Register
			this.objM.register(valueObj.tf, "REALTIMEVALUE", "REALTIMEVALUE");
		}
		//Clear interval
		if (!this.params.chartRendered){
			clearInterval (this.config.intervals.realTimeValue);
		}
	}
	// -------------------- EVENT HANDLERS --------------------//
	/**
	* dataOnRollOver is the delegat-ed event handler method that'll
	* be invoked when the user rolls his mouse over a column.
	* This function is invoked, only if the tool tip is to be shown.
	* Here, we show the tool tip.
	*/
	private function dataOnRollOver():Void {
		//Text of tooltip is stored in arguments.caller.text
		var toolText:String = arguments.caller.text;
		//Set tool tip text
		this.tTip.setText(toolText);
		//Show the tool tip
		this.tTip.show();
	}
	/*
	* dataOnMouseMove is called when the mouse position has changed
	* over column. We reposition the tool tip.
	*/
	private function dataOnMouseMove():Void{
		//Reposition the tool tip only if it's in visible state
		if (this.tTip.visible()){
			this.tTip.rePosition ();
		}
	}
	/**
	* dataOnRollOut method is invoked when the mouse rolls out
	* of column. We just hide the tool tip here.
	*/
	private function dataOnRollOut():Void{
		//Hide the tool tip
		this.tTip.hide();
	}
	/**
	* dataOnClick is invoked when the user clicks on a column (if link
	* has been defined). We invoke the required link.
	*/
	private function dataOnClick():Void {
		//Link of column is stored in arguments.caller.link
		var link:String = arguments.caller.link;
		//Invoke the link
		Utils.invokeLink(link, this);
	}
	// ------------------------------------------------//
	/**
	* setContextMenu method sets the context menu for the chart.
	* For this chart, the context items are "Print Chart".
	*/
	private function setContextMenu():Void {
		var chartMenu : ContextMenu = new ContextMenu();
		chartMenu.hideBuiltInItems();
		//If we've to create the real-time items
		if (this.params.showRTMenuItem && this.params.chartRendered && this.params.refreshInterval!=-1 && this.params.dataStreamURL!=""){
			if (this.isUpdating){
				//Stop Update menu item
				var updateCMI:ContextMenuItem = new ContextMenuItem ("Stop Update", Delegate.create (this, stopUpdate));
			}else{
				//Create restart update
				var updateCMI:ContextMenuItem = new ContextMenuItem ("Start Update", Delegate.create (this, restartUpdate));
			}			
			//Clear Chart Item
			var clearChartCMI:ContextMenuItem = new ContextMenuItem ("Clear Chart", Delegate.create (this, clearChart));
			chartMenu.customItems.push (updateCMI);
			chartMenu.customItems.push (clearChartCMI);
		}		
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
		if (this.params.chartRendered){
			clearInterval(this.config.intervals.contextMenu);
		}
	}
	/**
	* reInit method re-initializes the chart. This method is basically called
	* when the user changes chart data through JavaScript. In that case, we need
	* to re-initialize the chart, set new XML data and again render.
	*/
	public function reInit():Void {
		//Invoke super class's reInit
		super.reInit();
		//Re-set data containers
		this.categories = new Array ();
		this.dataset = new Array ();		
		//Re-set indexes to 0
		this.numDS = 0;
		this.num = 0;
		this.numTrendLines = 0;		
		this.numTrendLinesBelow = 0;
		this.numVLines = 0;
		//Re-create container arrays
		this.trendLines = new Array();
		this.vLines = new Array();
		this.divLines = new Array();
	}
	//---------------DATA EXPORT HANDLERS-------------------//
	/**
	 * Returns the data of the chart in CSV/TSV format. The separator, qualifier and line
	 * break character is stored in params (during common parsing).
	 * @return	The data of the chart in CSV/TSV format, as specified in the XML.
	 */
	public function exportChartDataCSV():String {
		var strData:String = "";
		var strQ:String = this.params.exportDataQualifier;
		var strS:String = this.params.exportDataSeparator;
		var strLB:String = this.params.exportDataLineBreak;
		var i:Number, j:Number;
		strData = strQ + ((this.params.xAxisName!="")?(this.params.xAxisName):("Label")) + strQ + strS;
		//Add all the series names
		for (i = 1; i <= this.numDS; i++) {
			strData += strQ + ((this.dataset[i].seriesName != "")?(this.dataset[i].seriesName):("")) + strQ + ((i < this.numDS)?(strS):(strLB));
		}
		//Iterate through each data-items and add it to the output
		for (i = 1; i <= this.num; i ++)
		{
			//Add the category label
			strData += strQ + (this.categories [i].label)  + strQ + strS;
			//Add the individual value for datasets
			for (j = 1; j <= this.numDS; j ++)
			{
				 strData += strQ + ((this.dataset[j].data[i].isDefined==true)?((this.params.exportDataFormattedVal==true)?(this.dataset[j].data[i].displayValue):(this.dataset[j].data[i].value)):(""))  + strQ + ((j<this.numDS)?strS:"");
			}
			if (i < this.num) {
				strData += strLB;
			}
		}
		return strData;
	}
}
