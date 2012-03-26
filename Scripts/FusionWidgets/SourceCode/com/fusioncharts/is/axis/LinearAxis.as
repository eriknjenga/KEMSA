/**
* @class LinearAxis
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* LinearAxis class represents the linear axis for any single 
* y-axis real-time chart. The APIs and methods have been created
* to support real-time update of axis, when data feeds come in.
*/
import com.fusioncharts.is.helper.NumberFormatting;
import com.fusioncharts.is.helper.Utils;
class com.fusioncharts.is.axis.LinearAxis {
	//Y-max and y-min for this axis
	private var yMax:Number;
	private var yMin:Number;
	//User specifed yMin & yMax
	private var userYMin:Number;
	private var userYMax:Number;
	//Flags to indicate whether user has specified yMin and yMax at all.
	private var userYMinGiven:Boolean;
	private var userYMaxGiven:Boolean;
	//Previous y-max and y-min (for comparison purpose)
	private var prevYMax:Number;
	private var prevYMin:Number;
	//Number of divisional lines
	private var numDivLines:Number;
	//Reference to Number Formatting class applicable to this axis
	private var nf:NumberFormatting;
	//Skip index for y-axis values
	private var yAxisValuesStep:Number;
	//Y-axis values formatting related properties
	private var bFormatNumber:Boolean;
	private var bFormatNumberScale:Boolean;
	private var decimals:Number;
	private var forceDecimals:Boolean;	
	//Flags to calculate axis limits
	private var stopMaxAtZero:Boolean;
	private var setMinAsZero:Boolean;
	//Container for div lines - Includes limits & 0 plane
	private var divLines:Array;
	//Y-co-ordinates of axis
	private var startAxisPos:Number;
	private var endAxisPos:Number;
	//Axis range and interval
	private var range:Number;
	private var interval:Number;
	//Short forms for common function names
	private var getFV:Function;
	private var getFN:Function;
	private var toBoolean:Function;
	/**
	* Constructor function.
	*	@param	yAxisMinValue		User specified min value (forced). Can be empty.
	*	@param	yAxisMaxValue		User specified max value (forced). Can be empty.
	*	@param	stopMaxAtZero		Flag indicating whether maximum value can
	*								be less than 0.
	*	@param	setMinAsZero		Whether to set the lower limit as 0 or a greater
	*								appropriate value (when dealing with positive numbers)
	*	@param	numDivLines			Number of div lines opted by the user.
	*	@param	yAxisValuesStep		Skip index for y-axis values.
	*	@param	nf					Reference to number formatting class that formats
	*								all numbers for this axis.
	*	@param	bFormatNumber		Whether to format y-axis values.
	*	@param	bFormatNumberScale	Whether to format scale of y-axis values 
	*	@param	decimals			Decimals for y-axis values.
	*	@param	forceDecimals		Whether to force decimals for y-axis values
	*/
	function LinearAxis(yAxisMinValue:Number, yAxisMaxValue:Number, stopMaxAtZero:Boolean, setMinAsZero:Boolean, numDivLines:Number, yAxisValuesStep:Number, nf:NumberFormatting, bFormatNumber:Boolean, bFormatNumberScale:Boolean, decimals:Number, forceDecimals:Boolean){
		//Short forms for common function names.
		this.getFV = Utils.getFirstValue;
		this.getFN = Utils.getFirstNumber;
		this.toBoolean = Utils.toBoolean;
		//Store as instance variables
		this.userYMin = yAxisMinValue;
		this.userYMax = yAxisMaxValue;
		//Default to 4
		this.numDivLines = getFN(numDivLines,4);
		//Number formatting reference
		this.nf = nf;
		//Y-axis skip index
		this.yAxisValuesStep = yAxisValuesStep;
		//Number formatting related properties
		this.bFormatNumber = bFormatNumber;
		this.bFormatNumberScale = bFormatNumberScale;
		this.decimals = decimals;
		this.forceDecimals = forceDecimals;		
		//stopMaxAtZero and setMinAsZero
		this.stopMaxAtZero = stopMaxAtZero;
		this.setMinAsZero = setMinAsZero;
		//Store flags whether yMax and yMin have been explicity specified by the user.
		this.userYMaxGiven = (yAxisMaxValue == null || yAxisMaxValue == undefined || yAxisMaxValue == "")?false:true;
		this.userYMinGiven = (yAxisMinValue == null || yAxisMinValue == undefined || yAxisMinValue == "")?false:true;
		//Initialize div-lines container
		this.divLines = new Array();
	}
	/**
	 * setAxisCoords method sets the starting and ending y-axis position
	 * for the axis (on the chart).
 	 *	@param	startAxisPos	Pixel start position (top part of canvas) for that axis
	 *	@param	endAxisPos		Pixel end position (bottom part of canvas) for that axis
	 *	@return					Nothing
	*/
	public function setAxisCoords(startAxisPos:Number, endAxisPos:Number):Void{
		//Just store it
		this.startAxisPos = startAxisPos;
		this.endAxisPos = endAxisPos;
	}
	/**
	* calculateLimits method helps calculate the axis limits based
	* on the given maximum and minimum value.
	* 	@param	maxValue		Maximum numerical value present in data
	*	@param	minValue		Minimum numerical value present in data

	*/
	public function calculateLimits(maxValue:Number, minValue:Number):Void {
		//Store previous y-max and y-min
		this.prevYMax = this.yMax;
		this.prevYMin = this.yMin;
		//First check if both maxValue and minValue are proper numbers.
		//Else, set defaults as 90,0
		maxValue = (isNaN(maxValue) == true || maxValue == undefined)?0.9:maxValue;
		minValue = (isNaN(minValue) == true || minValue == undefined)?0:minValue;
		//Or, if only 0 data is supplied
		if ((maxValue == minValue) && (maxValue == 0)){
			maxValue = .9;
		}
		//Get the maximum power of 10 that is applicable to maxvalue
		//The Number = 10 to the power maxPowerOfTen + x (where x is another number)
		//For e.g., in 99 the maxPowerOfTen will be 1 = 10^1 + 89
		//And for 102, it will be 2 = 10^2 + 2
		var maxPowerOfTen : Number = Math.floor (Math.log (Math.abs (maxValue)) / Math.LN10);
		//Get the minimum power of 10 that is applicable to maxvalue
		var minPowerOfTen : Number = Math.floor (Math.log (Math.abs (minValue)) / Math.LN10);
		//Find which powerOfTen (the max power or the min power) is bigger
		//It is this which will be multiplied to get the y-interval
		var powerOfTen : Number = Math.max (minPowerOfTen, maxPowerOfTen);
		var y_interval : Number = Math.pow (10, powerOfTen);
		//For accomodating smaller range values (so that scale doesn't represent too large an interval
		if (Math.abs (maxValue) / y_interval < 2 && Math.abs (minValue) / y_interval < 2){
			powerOfTen --;
			y_interval = Math.pow (10, powerOfTen);
		}
		//If the y_interval of min and max is way more than that of range.
		//We need to reset the y-interval as per range
		var rangePowerOfTen : Number = Math.floor (Math.log (maxValue - minValue) / Math.LN10);
		var rangeInterval : Number = Math.pow (10, rangePowerOfTen);
		//Now, if rangeInterval is 10 times less than y_interval, we need to re-set
		//the limits, as the range is too less to adjust the axis for max,min.
		//We do this only if range is greater than 0 (in case of 1 data on chart).
		if (((maxValue - minValue) > 0) && ((y_interval / rangeInterval) >= 10)){
			y_interval = rangeInterval;
			powerOfTen = rangePowerOfTen;
		}
		//Calculate the y-axis upper limit
		var y_topBound : Number = (Math.floor (maxValue / y_interval) + 1) * y_interval;
		//Calculate the y-axis lower limit
		var y_lowerBound : Number;
		//If the min value is less than 0
		if (minValue<0){
			//Then calculate by multiplying negative numbers with y-axis interval
			y_lowerBound = - 1 * ((Math.floor (Math.abs (minValue / y_interval)) + 1) * y_interval);
		} else {
			//Else, simply set it to 0.
			if (this.setMinAsZero){
				y_lowerBound = 0;
			} else {
				y_lowerBound = Math.floor (Math.abs (minValue / y_interval) - 1) * y_interval;
				//Now, if minValue>=0, we keep x_lowerBound to 0 - as for values like minValue 2
				//lower bound goes negative, which is not required.
				y_lowerBound = (y_lowerBound < 0) ?0 : y_lowerBound;
			}
		}
		//MaxValue cannot be less than 0 if stopMaxAtZero is set to true
		if (this.stopMaxAtZero && maxValue <= 0){
			y_topBound = 0;
		}
		//If he has provided it and it is valid, we leave it as the upper limit
		//Else, we enforced the value calculate by us as the upper limit.
		if (this.userYMaxGiven == false || (this.userYMaxGiven == true && Number(this.userYMax) < maxValue)){
			this.yMax = y_topBound;
		} else {
			this.yMax = Number(userYMax);
		}
		//Now, we do the same for y-axis lower limit
		if (this.userYMinGiven == false || (this.userYMinGiven == true && Number (this.userYMin) > minValue)) {
			this.yMin = y_lowerBound;
		} else {
			this.yMin = Number (userYMin);
		}
		//Store axis range
		this.range = Math.abs (this.yMax - this.yMin);
		//Store interval
		this.interval = y_interval;
	}	
	/**
	 * calculateDivLines method calculates the div-line values for the axis.
	 *	@param			Whether to force zero plane
	 *	@return			Nothing
	*/
	public function calculateDivLines(forceZeroPlane:Boolean):Void{
		//Initialize the container - as for each call, we'll change old values
		this.divLines = new Array();
		//Div line interval for each division
		var divInterval:Number = this.range/(this.numDivLines+1);
		//Y-counter
		var yCounter = this.yMin - divInterval;
		var divValue:Number;
		var showDivValue:Boolean;
		//Flag to store whether zero plane has been automatically included
		var zeroPIncluded:Boolean = false;
		//Loop variable
		var i:Number;
		//Create all the div lines
		for (i=0; i<=this.numDivLines+1; i++){
			//Get incremental value w.r.t yMin
			divValue = yCounter + divInterval*(i+1);
			//If it's 0 value, we update zeroPIncluded flag
			zeroPIncluded = (divValue==0)?true:zeroPIncluded;
			//Based on y-axis step, set the flag whether to show/hide this div line
			showDivValue = (i % this.yAxisValuesStep == 0);
			//Push it in our divLines array
			this.divLines.push(this.returnDataAsDivLine(divValue,showDivValue, false));
		}
		//Now, all the divisional line values have been included. But, if 0 value
		//was required and has not been added to the list, do so.
		if ((forceZeroPlane==true) && (this.yMax > 0 && this.yMin < 0) && (zeroPIncluded==false)){
			//Include zero plane at the right place in the array.
			this.divLines.push(this.returnDataAsDivLine(0,true, true));
			//Now, sort on value so that 0 automatically appears at right place
			this.divLines.sortOn("value", Array.NUMERIC);
		}
	}
	/**
	* returnDataAsDivLine method returns the data provided to the method
	* as a div line object.
	*	@param	value		Value of div line
	*	@param	showValue	Whether to show value of this div line
	*	@param	zeroPlane	Whether it's a forced zero plane
	*	@return				An object with the parameters of div line	
	*/
	private function returnDataAsDivLine(value:Number, showValue:Boolean, zeroPlane:Boolean):Object {
		//Create a new object
		var divLineObject = new Object();
		//Set numerical value
		divLineObject.value = value;
		//Set display value - formatted number.
		divLineObject.displayValue = this.nf.formatNumber(value, this.bFormatNumber, this.bFormatNumberScale, this.decimals, this.forceDecimals);
		divLineObject.zeroPlane = zeroPlane;
		//Whether we've to show value for this div-line?
		divLineObject.showValue = showValue;
		//Return the object
		return divLineObject;
	}	
	// ---------------- Public APIs for accessing data ------------------//
	/**
	 * getYMax method exposes the calculated y-max of this axis.
	 *	@return		Calculated y-max for this axis.
	*/
	public function getYMax():Number{
		return this.yMax;
	}
	/**
	 * getYMin method exposes the calculated y-min of this axis.
	 *	@return		Calculated y-min for this axis.
	*/
	public function getYMin():Number{
		return this.yMin;
	}
	/**
	 * hasAxisChanged method checks whether the axis has changed it's
	 * range w.r.t last update.
	 *	@return		Boolean value indicating whether the axis range has
	 *				changed.
	*/
	public function hasAxisChanged():Boolean{
		return ((this.prevYMax!=this.yMax) || (this.prevYMin!=this.yMin));
	}
	/**
	 * getDivLines method returns the div lines for the axis
	 *	@return		Array of div lines.
	*/
	public function getDivLines():Array{
		return this.divLines;
	}
	/**
	* getAxisPosition method gets the pixel position of a particular
	* point on the axis based on its value.
	*	@param	value			Numerical value for which we need pixel axis position
	*	@param	isYAxis			Flag indicating whether it's y axis
	*	@param	xPadding		Padding at left and right sides in case of a x-axis
	*	@return				The pixel position of the value on the given axis.
	*/
	public function getAxisPosition (value:Number, inverseAxis:Boolean):Number {
		//We can calculate only if axis co-ords have been defined
		if (this.startAxisPos==undefined || this.endAxisPos==undefined){
			throw new Error("Cannot calculate position, as axis co-ordinates have not been defined. Please use setAxisCoords() method to define the same.");
		}
		//Define variables to be used locally
		var numericalInterval : Number;
		var axisLength : Number;
		var relativePosition : Number;
		var absolutePosition : Number;
		//Get the numerical difference between the limits
		numericalInterval = (this.yMax - this.yMin);
		//If it's y axis, the co-ordinates are opposite in Flash
		axisLength = (this.endAxisPos - this.startAxisPos);
		relativePosition = (axisLength / numericalInterval) * (value - this.yMin);
		if (inverseAxis){
			//If it's inverted y-axis, then we go according to normal axis
			//Add downwards to start of axis position
			absolutePosition = this.startAxisPos + relativePosition;
		}else{
			//Else, go according to Flash's co-ordinate system y decreases as we go upwards
			//Reverse from canvas end position
			absolutePosition = this.endAxisPos - relativePosition;
		}		
		return absolutePosition;
	}
}