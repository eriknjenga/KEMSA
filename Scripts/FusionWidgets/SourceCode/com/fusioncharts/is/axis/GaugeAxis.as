/**
* @class GaugeAxis
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* GaugeAxis class represents the generic gauge axis for any single 
* gauge. The APIs and methods have been created
* to support real-time update of gauge, when data feeds come in.
*/
import com.fusioncharts.is.helper.NumberFormatting;
import com.fusioncharts.is.helper.Utils;
import com.fusioncharts.is.extensions.MathExt;
class com.fusioncharts.is.axis.GaugeAxis {
	//Lower and upper limits
	private var max:Number;
	private var min:Number;
	//User specifed Min & Max
	private var userMin:Number;
	private var userMax:Number;
	//Whether user has explicitly specified max and min values
	private var userMaxGiven:Boolean;
	private var userMinGiven:Boolean;
	//Number of tick marks - major & minor
	private var numMajorTM:Number;
	private var numMinorTM:Number;
	//Whether to automatically adjust tick marks specified by user
	private var adjustTM:Boolean;
	//Stepping of tick values
	private var tickValueStep:Number;
	//Reference to Number Formatting class applicable to this axis
	private var nf:NumberFormatting;
	//Axis values formatting related properties
	private var bFormatNumber:Boolean;
	private var bFormatNumberScale:Boolean;
	private var decimals:Number;
	private var forceDecimals:Boolean;	
	//Flags to calculate axis limits
	private var stopMaxAtZero:Boolean;
	private var setMinAsZero:Boolean;
	//Major tick interval
	private var majorTickInt:Number;
	//Container for major tick mark values
	private var majorTM:Array;
	//Container for minor tick mark values
	private var minorTM:Array;
	//Co-ordinates of axis (can be pixel, angles etc)
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
	*	@param	minValue			User specified min value (forced). Can be empty.
	*	@param	maxValue			User specified max value (forced). Can be empty.
	*	@param	stopMaxAtZero		Flag indicating whether maximum value can
	*								be less than 0.
	*	@param	setMinAsZero		Whether to set the lower limit as 0 or a greater
	*								appropriate value (when dealing with positive numbers)
	*	@param	numMajorTM			Number of major tick marks opted by the user.
	*	@param	numMinorTM			Number of minor tick marks opted by the user.
	*	@param	adjustTM			Whether to automatically adjust tick marks given be user
	*	@param	nf					Reference to number formatting class that formats
	*								all numbers for this axis.
	*	@param	bFormatNumber		Whether to format axis values.
	*	@param	bFormatNumberScale	Whether to format scale of axis values 
	*	@param	decimals			Decimals for axis values.
	*	@param	forceDecimals		Whether to force decimals for axis values
	*/
	function GaugeAxis(minValue:Number, maxValue:Number, stopMaxAtZero:Boolean, setMinAsZero:Boolean, numMajorTM:Number, numMinorTM:Number, adjustTM:Boolean, tickValueStep:Number, nf:NumberFormatting, bFormatNumber:Boolean, bFormatNumberScale:Boolean, decimals:Number, forceDecimals:Boolean){
		//Short forms for common function names.
		this.getFV = Utils.getFirstValue;
		this.getFN = Utils.getFirstNumber;
		this.toBoolean = Utils.toBoolean;
		//Store as instance variables
		this.userMin = minValue;
		this.userMax = maxValue;
		//Default tick marks
		this.numMajorTM = getFN(numMajorTM,-1);
		this.numMinorTM = getFN(numMinorTM,5);
		this.adjustTM = adjustTM;
		this.tickValueStep = getFN(tickValueStep,1);
		//Number formatting reference
		this.nf = nf;
		//Number formatting related properties
		this.bFormatNumber = bFormatNumber;
		this.bFormatNumberScale = bFormatNumberScale;
		this.decimals = decimals;
		this.forceDecimals = forceDecimals;		
		//stopMaxAtZero and setMinAsZero
		this.stopMaxAtZero = stopMaxAtZero;
		this.setMinAsZero = setMinAsZero;
		//Store flags whether max and min have been explicity specified by the user.
		this.userMaxGiven = (userMax == null || userMax == undefined || userMax == "")?false:true;
		this.userMinGiven = (userMin == null || userMin == undefined || userMin == "")?false:true;
		//Initialize tick marks container
		this.majorTM = new Array();
		this.minorTM = new Array();
	}
	/**
	 * setAxisCoords method sets the starting and ending axis position
	 * The position can be pixels or angles. Here if the axis is reverse,
	 * we can pass reverse startAxisPos and endAxisPos, depending on which
	 * side we consider as start. getPosition() method will then automatically
	 * return the right values based on the same.
 	 *	@param	startAxisPos	Start position (or angle) for that axis
	 *	@param	endAxisPos		End position (or angle) for that axis
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
		if (this.userMaxGiven == false || (this.userMaxGiven == true && Number(this.userMax) < maxValue)){
			this.max = y_topBound;
		} else {
			this.max = Number(userMax);
		}
		//Now, we do the same for y-axis lower limit
		if (this.userMinGiven == false || (this.userMinGiven == true && Number (this.userMin) > minValue)) {
			this.min = y_lowerBound;
		} else {
			this.min = Number (userMin);
		}
		//Store axis range
		this.range = Math.abs (this.max - this.min);
		//Store interval
		this.interval = y_interval;
		//Based on this scale, calculate the tick interval
		this.calcTickInterval();
	}		
	/**
	* calcTickInterval method calculates the best division interval for the given/calculated
	* min, max specified and numMajorTM specified. Following two cases have been dealt with:
	* Case 1: If both min and max was calculated by us, we re-set them so that we get a best 
	* interval based on numMajorTM. The idea is to have equal intervals without changing numMajorTM.
	* Case 2: We change numMajorTM based on the axis limits. Also, we change only if user has 
	* opted to adjustTM.
	*/
	private function calcTickInterval():Void {
		//We cannot have a numMajorTM less than 2, if explicitly specified
		if (this.numMajorTM!=-1 && this.numMajorTM<2){
			this.numMajorTM = 2;
		}
		//Case 1: User has not specified either max or min, but specified numMajorTM
		if (this.userMinGiven == false && this.userMaxGiven == false && this.numMajorTM!=-1){
			/**
			* In this case, we first get apt divisible range based on min, max,
			* numMajorTM and the calculated interval. Thereby, get the difference
			* between original range and new range and store as delta.
			* If max>0, add this delta to max. Else substract from min.
			* In this case, we keep numMajorTM constant and vary the axis's limits.
			*/
			//If user has not specified any number of major tick marks, we default to 5.
			this.numMajorTM = (this.numMajorTM==-1)?5:this.numMajorTM;
			//Get the adjusted divisible range
			var adjRange : Number = getDivisibleRange (this.min, this.max, this.numMajorTM, this.interval, true);
			//Get delta (Calculated range minus original range)
			var deltaRange : Number = adjRange - range;
			//Update global range storage
			range = adjRange;
			//Now, add the change in range to max, if max > 0, else deduct from min
			if (this.max > 0){
				this.max = this.max + deltaRange;
			} else {
				this.min = this.min - deltaRange;
			}
		} else {
			/**
			* Here, we adjust the number of tick marks based on max, min, if 
			* user has opted to adjustTM.
			*/		
			//If the user has not specified any tick mark number, we assume a default of 5.
			this.numMajorTM = (this.numMajorTM==-1)?5:this.numMajorTM;
			//Since we're considering the upper and lower limits of axis as major tick marks,
			//so calculation is necessary only if there are more than 2 tick marks. Else, they
			//simple represent the upper and lower limit.		
			//Also, we adjust number of tick marks only if user has opted for adjustTM
			if (this.adjustTM==true){
				var counter : Number = 0;
				var multiplyFactor : Number = 1;
				var calcMajorTM:Number;
				while (1 == 1){
					//Increment,Decrement numMajorTM
					calcMajorTM = this.numMajorTM + (counter * multiplyFactor);
					//Cannot be 0
					calcMajorTM = (calcMajorTM == 0) ? 1 : calcMajorTM;
					//Check whether this number of calcMajorTM satisfies our requirement
					if (isRangeDivisible (range, calcMajorTM, interval)){
						//Exit loop
						break;
					}
					//Each counter comes twice: one for + count, one for - count
					counter = (multiplyFactor == - 1 || (counter > this.numMajorTM)) ? ( ++ counter) : (counter);
					if (counter > 25) {
						//We do not go beyond 25 count to optimize.
						//If the loop comes here, it means that divlines
						//counter is not able to achieve the target.
						//So, we assume no tick marks are possible and exit.
						//Just store the tick mark for the upper and lower limits.						
						calcMajorTM = 2;
						break;
					}
					//Switch to increment/decrement mode. If counter
					multiplyFactor = (counter <= this.numMajorTM) ? (multiplyFactor * - 1) : (1);
				}
				//Store the value in params
				this.numMajorTM = calcMajorTM;
			} else{
				//Do nothing. This case comes where user has opted not to adjust TM.
			}
		}		
		//Store the major tick interval
		this.majorTickInt = (this.max - this.min)/(this.numMajorTM-1);
	}
	/**
	* isRangeDivisible method helps us judge whether the given range is
	* perfectly divisible for specified interval & numMajorTM.
	* To check that, we divide the given range into numMajorTM section.
	* If the decimal places of this division value is <= that of interval,
	* that means, this range fits in our purpose. We return a boolean value
	* accordingly.
	*	@param	range		Range of axis (Max - Min). Absolute value
	*	@param	numMajorTM	Number of tick marks to be plotted.
	*	@param	interval	Axis Interval (power of ten).
	*	@return				Boolean value indicating whether this range is divisible
	*						by the given number of tick marks.
	*/
	public function isRangeDivisible(range:Number, numMajorTM:Number, interval:Number):Boolean {
		//Get range division
		var rangeDiv:Number = range/(numMajorTM-1);
		//Now, if the decimal places of rangeDiv and interval do not match,
		//it's not divisible, else it's divisible
		if (MathExt.numDecimals(rangeDiv)>MathExt.numDecimals(interval)){
			return false;
		} else {
			return true;
		}
	}
	/**
	* getDivisibleRange method calculates a perfectly divisible range based
	* on interval, numMajorTM, min and max specified.
	* We first get the range division for the existing range
	* and user specified number of tick marks. Now, if that division satisfies
	* our needs (decimal places of division and interval is equal), we do NOT
	* change anything. Else, we round up the division to the next higher value {big delta
	* in case of smaller values i.e., interval <1 and small delta in case of bigger values >1).
	* We multiply this range division by number of tick marks required and calculate
	* the new range.
	*	@param	min				Min value of axis
	*	@param	max				Max value of axis
	*	@param	numMajorTM		Number of major tick marks to be plotted.
	*	@param	interval		Axis Interval (power of ten).
	*	@param	interceptRange	Boolean value indicating whether we've to change the range
	*							by altering interval (based on it's own value).
	*	@return					A range that is perfectly divisible into given number of sections.
	*/
	public function getDivisibleRange(min:Number, max:Number, numMajorTM:Number, interval:Number, interceptRange:Boolean):Number{
		//If numMajorTM<3, we do not need to calculate anything, so simply return the existing range
		if (numMajorTM<3){
			return this.range;
		}
		//Get the range division for current min, max and numMajorTM
		var range = Math.abs (max - min);
		var rangeDiv:Number = range/(numMajorTM-1);
		//Now, the range is not divisible
		if (!isRangeDivisible (range, numMajorTM, interval)){
			//We need to get new rangeDiv which can be equally distributed.
			//If intercept range is set to true
			if (interceptRange){
				//Re-adjust interval so that gap is not much (conditional)
				//Condition check limit based on value
				var checkLimit:Number = (interval>1)?2:0.5;
				if ((Number(rangeDiv)/Number(interval))<checkLimit){
					//Decrease power of ten to get closer rounding
					interval = interval/10;
				}
			}
			//Adjust range division based on new interval
			rangeDiv = (Math.floor(rangeDiv/interval)+1)*interval;
			//Get new range
			range = rangeDiv*(numMajorTM-1);
		}
		//Return range
		return range;
	}	
	/**
	 * calculateTicks method calculates the tick values for the axis and stores
	 * them in instance variables.
	 *	@return			Nothing
	*/
	public function calculateTicks():Void{
		//Initialize the containers - as for each call, we'll change old values
		this.majorTM = new Array();
		this.minorTM = new Array();		
		//First, create each major tick mark and store it in this.majorTM
		var count:Number = 0;
		var tickValue:Number, showValue:Boolean;
		while (count <=(this.numMajorTM -1)){
			//Converting to string and back to number to avoid Flash's rounding problems.
			tickValue = Number(String((this.min + this.majorTickInt*count)));			
			//Whether to show this tick
			showValue = (count % this.tickValueStep == 0);
			//Push it into array
			this.majorTM.push(this.returnDataAsTick(tickValue, showValue));
			//Increment counter
			count ++;
		}
		//Now, we'll store the values of each minor tick mark
		var i:Number, j:Number;
		var minorTickInterval:Number = this.majorTickInt/(this.numMinorTM+1);
		for (i=0; i<this.numMajorTM-1; i++){
			for (j=1; j<=this.numMinorTM; j++){
				this.minorTM.push(this.majorTM[i].value + minorTickInterval*j);
			}
		}
	}
	/**
	* returnDataAsTick method returns the data provided to the method
	* as a tick value object.
	*	@param	value		Value of tick line
	*	@param	showValue	Whether to show value of this div line
	*	@return				An object with the parameters of div line	
	*/
	private function returnDataAsTick(value:Number, showValue:Boolean):Object {
		//Create a new object
		var tickObject = new Object();
		//Set numerical value
		tickObject.value = value;
		//Set display value - formatted number.
		tickObject.displayValue = this.nf.formatNumber(value, this.bFormatNumber, this.bFormatNumberScale, this.decimals, this.forceDecimals);
		//Whether we've to show value for this tick mark?
		tickObject.showValue = showValue;
		//Return the object
		return tickObject;
	}	
	// ---------------- Public APIs for accessing data ------------------//
	/**
	 * getMax method exposes the calculated max of this axis.
	 *	@return		Calculated max for this axis.
	*/
	public function getMax():Number{
		return this.max;
	}
	/**
	 * getMin method exposes the calculated min of this axis.
	 *	@return		Calculated min for this axis.
	*/
	public function getMin():Number{
		return this.min;
	}	
	/**
	 * getMajorTM method returns the major tick values for the axis
	 *	@return		Array of major tick values lines.
	*/
	public function getMajorTM():Array{
		return this.majorTM;
	}
	/**
	 * getMinorTM method returns the minor tick values for the axis
	 *	@return		Array of minor tick values lines.
	*/
	public function getMinorTM():Array{
		return this.minorTM;
	}
	/**
	* getAxisPosition method gets the pixel/angle position of a particular
	* point on the axis based on its value.
	*	@param	value		Numerical value for which we need pixel/angle axis position
	*	@return				The pixel position of the value on the given axis.
	*/
	public function getAxisPosition (value:Number):Number {
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
		numericalInterval = (this.max - this.min);
		axisLength = (this.endAxisPos - this.startAxisPos);
		relativePosition = (axisLength / numericalInterval) * (value - this.min);
		//Calculate the axis position
		absolutePosition = this.startAxisPos + relativePosition;
		return absolutePosition;
	}
	/**
	* getValueFromPosition method gets the numerical value of a particular
	* point on the axis based on its axis position.
	*	@param	position	Position on the axis. 
	*	@return				Numerical value for this position.
	*/
	public function getValueFromPosition (position:Number):Number {
		//We can calculate only if axis co-ords have been defined
		if (this.startAxisPos==undefined || this.endAxisPos==undefined){
			throw new Error("Cannot calculate value, as axis co-ordinates have not been defined. Please use setAxisCoords() method to define the same.");
		}
		//Define variables to be used locally
		var numericalInterval : Number;
		//Deltas of axis w.r.t min and max
		var dd1:Number;
		var dd2:Number;
		var value:Number;
		//Get the numerical difference between the limits
		numericalInterval = (this.max - this.min);
		//Get deltas of the position w.r.t both ends of axis.
		dd1 = position - this.startAxisPos;
		dd2 = this.endAxisPos - position;
		//Based on distribution of position on the axis scale, get value
		value = (dd1/(dd1+dd2))*numericalInterval + this.min;
		//Return it
		return value;
	}
}