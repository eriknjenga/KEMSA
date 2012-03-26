/**
* @class BulletChart
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd. 2005-2006
* BulletChart extends Chart class to encapsulate
* functionalities of bullet charts.
* It contains the functionalities that are common to all
* bubble charts - like scale, target value etc.
* All charts then extend this class.
*/
//Import parent class
import com.fusioncharts.is.core.Chart;
//Axis for the chart
import com.fusioncharts.is.axis.GaugeAxis;
//Utility functions
import com.fusioncharts.is.helper.Utils;
//Logger
import com.fusioncharts.is.helper.Logger;
//Color Manager
import com.fusioncharts.is.colormanagers.BulletColorManager;
//Number formatting
import com.fusioncharts.is.helper.NumberFormatting;
//Extensions
import com.fusioncharts.is.extensions.MathExt;
import com.fusioncharts.is.extensions.ColorExt;
//Delegate
import mx.utils.Delegate;
class com.fusioncharts.is.core.BulletChart extends Chart {
	//Reference to primary axis of the chart
	private var pAxis:GaugeAxis;
	//Number formatting class for this axis
	private var nf:NumberFormatting;
	//Color Manager for the charts
	public var colorM:BulletColorManager;
	//Major and minor tick marks
	private var majorTM:Array;
	private var minorTM:Array;
	//Container to hold defined Color ranges
	private var colorR:Array;
	//Number of defined color range
	private var numCR:Number;	
	//Value for the chart
	private var value:Number;
	//Display value
	private var valueDisplay:String;
	//Target value
	private var target:Number;
	//Target display value
	private var targetDisplay:String;
	//Whether to show target
	private var showTarget:Boolean;
	/**
	* Constructor function. We invoke the super class'  constructor.
	* And also initialize local instance properties.
	*/
	function BulletChart(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Color Range containers
		this.colorR = new Array();
		this.numCR = 0;
		this.valueDisplay = "";
		this.targetDisplay = "";
	}
	/**
	 * returnDataAsColorRange method returns an object encapsulating all the
	 * properties of a Color Range object.
	 *	@param 	minValue		Minimum value for this color range
	 *	@param 	maxValue		Maximum value for this color range
	 * 	@param 	label			Label for this color range
	 * 	@param 	color			Color for this color range
	 * 	@param 	alpha			Alpha for this range
	 *	@param 	borderColor		Border Color for the range
	 *	@param 	borderAlpha		Border Alpha for the range
	*/
	private function returnDataAsColorRange(minValue:Number, maxValue:Number, label:String, color:String, alpha:String, borderColor:String, borderAlpha:Number):Object{
		//Create an obejct to represent it
		var objCR:Object = new Object();		
		//Store
		objCR.minValue = minValue;
		objCR.maxValue = maxValue;
		objCR.label = label;
		objCR.color = color;
		objCR.alpha = alpha;
		objCR.borderColor = borderColor;
		objCR.borderAlpha = borderAlpha;
		//Internal properties
		objCR.fromX = 0;
		objCR.fromY = 0;
		objCR.toX = 0;
		objCR.toY = 0;
		//Return it
		return objCR;
	}
	/**
	 * parseColorRange method parses the color ranges for the gauge.
	 *	@param	arrColorRange	Array of color range nodes.
	*/
	private function parseColorRange(arrColorRange:Array):Void{
		//Loop variable
		var i:Number;
		//Local variables to store property
		var minValue:Number, maxValue:Number, label:String, code:String, alpha:String, borderColor:String, borderAlpha:Number;
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
				alpha = getFV(atts["alpha"], "100");
				borderColor = formatColor(getFV(atts["bordercolor"], this.params.colorRangeBorderColor));
				borderAlpha = getFN(atts["borderalpha"], this.params.colorRangeBorderAlpha);
				this.colorR[this.numCR] = returnDataAsColorRange(minValue, maxValue, label, code, alpha, borderColor, borderAlpha);
				//We take the maximum value of this color range to the default minimum of the next one
				prevMinValue = maxValue;
			}
		}
	}
	/**
	 * validateColorRange method valides all the color ranges so as to form
	 * proper sequence.
	*/
	private function validateColorRange():Void{
		if (this.numCR>0){
			//First color range's minValue should be equal to lowerLimit
			this.colorR[1].minValue = this.pAxis.getMin();
			//Forced upper limit scaling for the last color range 
			//as the last color range's upper value has to be equal to upperLimit
			this.colorR[this.numCR].maxValue = this.pAxis.getMax();
			//For all the values in between, the minValue and maxValue should 
			//lie between the upper and lower limit
			var i:Number;
			for (i=1; i<=this.numCR; i++) {
				//Fill all missing values with extremities
				if (this.colorR[i].maxValue>this.pAxis.getMax()) {
					this.colorR[i].maxValue = this.pAxis.getMax();
				}
				if (this.colorR[i].maxValue<this.pAxis.getMin()) {
					this.colorR[i].maxValue = this.pAxis.getMin();
				}
				if (this.colorR[i].minValue<this.pAxis.getMin()) {
					this.colorR[i].minValue = this.pAxis.getMin();
				}
				if (this.colorR[i].minValue>this.pAxis.getMax()) {
					this.colorR[i].minValue = this.pAxis.getMax();
				}
			}
			//Create the sequence - serialize
			for (i=1; i<this.numCR; i++) {
				//If max value of present is equal to upper limit, but minValue of next is greater than min value of present, set max to min of next
				if ((this.colorR[i].maxValue>=this.pAxis.getMax()) && (this.colorR[i+1].minValue>this.colorR[i].minValue)) {
					this.colorR[i].maxValue = this.colorR[i+1].minValue;
				}
				//If max value of current is greater than min value of next, set min value of next to max value of current
				if (this.colorR[i].maxValue>this.colorR[i+1].minValue) {
					this.colorR[i+1].minValue = this.colorR[i].maxValue;
				}
				//If max value of current is less than min value of next, set max value of current to min value of next
				if (this.colorR[i].maxValue<this.colorR[i+1].minValue) {
					this.colorR[i].maxValue = this.colorR[i+1].minValue;
				}
			}
		}
	}
	/**
	* getMaxDataValue method gets the maximum data value present
	* in the data - either a color range, or target or value.
	*	@return	The maximum value present in the data provided.
	*/
	private function getMaxDataValue():Number{
		//Find the max of value and target
		var maxValue:Number = Math.max(this.value, this.target); 
		var i:Number;
		for (i=1; i<=this.numCR; i ++){
			//Store the greater number
			maxValue = Math.max(this.colorR[i].maxValue, maxValue);
		}
		return maxValue;
	}
	/**
	* getMinDataValue method gets the minimum data value present
	* in the data  - either a color range, or target or value.
	*	@reurns		The minimum value present in data
	*/
	private function getMinDataValue():Number{
		//Find the min of value and target
		var minValue:Number = Math.min(this.value, this.target);
		var i:Number;
		for (i=1; i<=this.numCR; i ++){
			//Store the lesser number
			minValue = Math.min(this.colorR[i].minValue, minValue);
		}
		return minValue;
	}
	/**
	* setupAxis method sets the axis for the chart.
	* It gets the minimum and maximum value specified in data and
	* based on that it calls super.getAxisLimits();
	*/
	private function setupAxis():Void {
		this.pAxis = new GaugeAxis(this.params.lowerLimit, this.params.upperLimit, false, !this.params.setAdaptiveMin, this.params.majorTMNumber, this.params.minorTMNumber, this.params.adjustTM, this.params.tickValueStep, this.nf, this.params.formatNumber, this.params.formatNumberScale, this.params.tickValueDecimals, this.params.forceTickValueDecimals);
		this.pAxis.calculateLimits(this.getMaxDataValue(),this.getMinDataValue());
		//Calcuate tick marks - based on the initial data.
		this.pAxis.calculateTicks();
		//Store copy of tick marks in local array
		this.majorTM = this.pAxis.getMajorTM();		
		this.minorTM = this.pAxis.getMinorTM();		
	}
	/**
	 * setDisplayValue method sets the display value for both the value and target
	*/
	private function setDisplayValue():Void{
		//Set display value
		this.valueDisplay = this.nf.formatNumber(this.value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);
		//Set target display value, if target is provided.
		if (this.showTarget){
			this.targetDisplay = this.nf.formatNumber(this.target, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);
		}
	}
	
	/**
	 * validateTarget method validates whether the target specified by user is
	 * correct and within range.
	*/
	private function validateTarget():Void{
		//Check whether we've to show the target at all
		if (this.target==undefined || isNaN(this.target)){
			//If the user has not defined any target only
			this.showTarget = false;
		}else{
			//Set flag
			this.showTarget = true;
			//Now restrict it to our range
			this.target = Math.max(this.target, this.pAxis.getMin());
			this.target = Math.min(this.target, this.pAxis.getMax());
		}
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
		this.colorM = new BulletColorManager(paletteId,themeColor);
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
	/**
	* reInit method re-initializes the chart. 
	*/
	public function reInit():Void{
		//Bubble up
		super.reInit();	
		//Defaults for color range
		this.colorR = new Array();
		this.numCR = 0;
		//Delete value and target
		delete this.value;
		delete this.valueDisplay;
		delete this.target;
		delete this.targetDisplay;		
		//We're not re-intializing color Manager, as it is not
		//setup in constructor. Instead, setup methods are being called to set it
		//from render() function of the chart. So, when the chart is changed, the setup
		//methods will be automatically called again.
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
