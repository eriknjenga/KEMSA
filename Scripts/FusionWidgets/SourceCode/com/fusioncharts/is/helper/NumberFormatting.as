/**
* @class NumberFormatting
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* NumberFormatting helps format a number in FusionCharts format
* using the various parameters specified by the user. Each number formatting
* class instance applies to a set of numbers on the chart. For example, in a single
* axis chart, all the numbers get formatted by the same number formatting class 
* (with maybe different decimal places). Similarly, on a multi-axis chart, each
* axis will need to have its own number formatting instance, as it can have different
* formatting properties.
*
* All the numbers under a single number formatting class share the following properties:
* - numberPrefix, numberSuffix
* - Decimal and thousands separator
* - Formatting scale value, units, default scale
*
* During formatting, each number can be formatted with the following different attributes:
* - FormatNumber, FormatNumberScale, Decimals, ForceDecimals?
*/
import com.fusioncharts.is.extensions.MathExt;
import com.fusioncharts.is.extensions.StringExt;
class com.fusioncharts.is.helper.NumberFormatting {
	//Prefix & Suffix for all the numbers belonging to this set
	private var numberPrefix:String;
	private var numberSuffix:String;
	//Boolean value whether number scale has been defined
	private var bNumberScaleDefined:Boolean;
	//Number scale containers
	private var scaleRecursively:Boolean;
	private var maxScaleRecursion:Number;
	private var scaleSeparator:String;
	private var defaultNumberScale:String;
	private var nsu:Array;
	private var nsv:Array;
	//Separator characters
	private var decimalSeparator:String;
	private var thousandSeparator:String;
	private var inDecimalSeparator:String;
	private var inThousandSeparator:String;
	/**
	 * Constructor function.
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
	*/
	function NumberFormatting(numberPrefix:String, numberSuffix:String, scaleRecursively:Boolean, maxScaleRecursion:Number, scaleSeparator:String, defaultNumberScale:String, numberScaleValues:String, numberScaleUnits:String, decimalSeparator:String, thousandSeparator:String, inDecimalSeparator:String, inThousandSeparator:String) {
		//Store parameters into instance variables
		this.numberPrefix = this.unescapeChar(numberPrefix);
		this.numberSuffix = this.unescapeChar(numberSuffix);
		this.scaleRecursively = scaleRecursively;
		this.maxScaleRecursion = maxScaleRecursion;
		this.scaleSeparator = scaleSeparator;
		this.defaultNumberScale = defaultNumberScale;
		this.decimalSeparator = decimalSeparator;
		this.thousandSeparator = thousandSeparator;
		this.inDecimalSeparator = inDecimalSeparator;
		this.inThousandSeparator = inThousandSeparator;
		//Max recursion scale cannot be 0.
		this.maxScaleRecursion = (this.maxScaleRecursion == 0 || this.maxScaleRecursion == null) ? -1 : this.maxScaleRecursion;
		//Initialize the number scaling containers
		this.nsu = new Array();
		this.nsv = new Array();
		//Parse number scale units & values
		this.parseNumberScale(numberScaleValues, numberScaleUnits);
	}
	/**
	* parseNumberScale method checks whether we've been provided
	* with number scales. If yes, we parse them and store them in 
	* local containers.
	*	@return	Nothing.
	*/
	private function parseNumberScale(numberScaleValues:String, numberScaleUnits:String):Void {
		//Check if either has been defined
		if (numberScaleValues.length == 0 || numberScaleUnits.length == 0) {
			//Set flag to false
			bNumberScaleDefined = false;
			scaleRecursively = false;
		} else {
			//Set flag to true
			bNumberScaleDefined = true;
			//Split the data into arrays
			this.nsv = new Array();
			this.nsu = new Array();
			//Parse the number scale value
			this.nsv = numberScaleValues.split(",");
			//Convert all number scale values to numbers as they're
			//currently in string format.
			var i:Number;
			for (i=0; i<this.nsv.length; i++) {
				this.nsv[i] = Number(this.nsv[i]);
				//If any of numbers are NaN, set defined to false
				if (isNaN(this.nsv[i])) {
					bNumberScaleDefined = false;
					scaleRecursively = false;
				}
			}
			//Parse the number scale unit
			this.nsu = numberScaleUnits.split(",");
			//If the length of two arrays do not match, set defined to false.
			if (this.nsu.length != this.nsv.length) {
				bNumberScaleDefined = false;
				scaleRecursively = false;
			}
			//Push the default scales at start - Value as 1 (universal divisor)			    
			this.nsv.push(1);
			this.nsu.unshift(this.defaultNumberScale);
			//If number scale is not defined, clear up
			if (!bNumberScaleDefined) {
				delete this.nsu;
				delete this.nsv;
			}
		}
	}
	/**
	* unescapeChar method helps to unescape certain escape characters
	* which might have got through the XML. Like, %25 is escaped back to %.
	* This function would be used to format the number prefixes and suffixes.
	*	@param	strChar		The character or character sequence to be unescaped.
	*	@return			The unescaped character
	*/
	private function unescapeChar(strChar:String):String {
		//Perform only if strChar is defined
		if (strChar == "" || strChar == undefined) {
			return "";
		}
		//If it doesnt contain a %, return the original string          
		if (strChar.indexOf("%") == -1) {
			return strChar;
		}
		//We're not doing a case insensitive search, as there might be other          
		//characters provided in the Prefix/Suffix, which need to be present in lowe case.
		//Create the conversion table.
		var cTable:Array = new Array();
		cTable.push({char:"%", encoding:"%25"});
		cTable.push({char:"&", encoding:"%26"});
		cTable.push({char:"£", encoding:"%A3"});
		cTable.push({char:"€", encoding:"%E2%82%AC"});
		//v2.3 Backward compatible Euro
		cTable.push({char:"€", encoding:"%80"});
		cTable.push({char:"¥", encoding:"%A5"});
		cTable.push({char:"¢", encoding:"%A2"});
		cTable.push({char:"₣", encoding:"%E2%82%A3"});
		cTable.push({char:"+", encoding:"%2B"});
		cTable.push({char:"#", encoding:"%23"});
		//Loop variable
		var i:Number;
		//Return string (escaped)
		var rtnStr:String = strChar;
		for (i=0; i<cTable.length; i++) {
			if (strChar == cTable[i].encoding) {
				//If the given character matches the encoding, convert to character
				rtnStr = cTable[i].char;
				break;
			}
		}
		//Return it
		return rtnStr;
		//Clean up
		delete cTable;
	}
	/**
	* formatNumber method helps format a number as per the specified
	* parameters.
	*	@param		intNum				Number to be formatted
	*	@param		bFormatNumber		Flag whether we've to format
	*									decimals and add commas
	*	@param		bFormatNumberScale	Flag whether we've to format number
	*									scale
	*	@param		decimals			Number of decimal places we need to
	*									round the number to.
	*	@param		forceDecimals		Whether we force decimal padding.
	*	@return							Formatted number as string.
	*
	*/
	public function formatNumber(intNum:Number, bFormatNumber:Boolean, bFormatNumberScale:Boolean, decimals:Number, forceDecimals:Boolean):String {
		if (intNum == undefined || intNum == null || isNaN(intNum)) {
			return "";
		}
		//Convert number to String format    
		var strNum:String = String(intNum);
		//If we do not have to scale the number, set recursive to false (saves a few conditions)
		//Reason: when we don't have to scale, recursive is not a question only.
		scaleRecursively = (bFormatNumberScale == false) ? false : this.scaleRecursively;
		//Determine default number scale - empty if we're using recursive scaling.
		var strScale:String = (bFormatNumberScale && this.bNumberScaleDefined && !scaleRecursively) ? this.defaultNumberScale : "";
		//If number scale is defined, and we've to format the scale of this number, proceed.
		if (bFormatNumberScale && this.bNumberScaleDefined) {
			//We get array of values & scales.
			var objNum:Object = this.formatNumberScale(intNum);
			//Store from return in local primitive variables
			if (this.scaleRecursively) {
				//Store the list of numbers and scales.
				var numList:Array = objNum.value;
				var scaleList:Array = objNum.scale;
			} else {
				strNum = String(objNum.value[0]);
				intNum = objNum.value[0];
				strScale = objNum.scale[0];
			}
			//Clear up
			delete objNum;
		}
		//Loop differently based on whether we've to scale recursively or normally.   
		if (this.scaleRecursively) {
			//Based on max scale recursion, we decide the upper index to which we've to iterate
			var upperIndex:Number = ((this.maxScaleRecursion == -1) ? numList.length : Math.min(numList.length, this.maxScaleRecursion));
			//Now, based on whether we've to format decimals and commas.
			if (bFormatNumber) {
				//If recursive scaling was applied and format number is true, we need to :
				//- format comma of all values
				//- format decimals of just the last value (last based on max recursion or actual).
				strNum = "";
				var tempNum:Number, tempStr:String;
				for (var i:Number = 0; i<upperIndex; i++) {
					//Convert all but first number to absolute values.
					tempNum = (i == 0) ? numList[i] : Math.abs(numList[i]);
					tempStr = String(tempNum);
					//If it's the last value, format decimals					
					if (i == upperIndex-1) {
						tempStr = this.formatDecimals(tempNum, decimals, forceDecimals);
					}
					//Append to strNum after formatting commas    
					//We separate the scales using scale separator. The last token doesn't append
					//the scale separator, as we append number suffix after that.
					strNum = strNum+formatCommas(tempStr)+scaleList[i]+(i<upperIndex-1 ? this.scaleSeparator : "");
				}
			} else {
				strNum = "";
				for (var i:Number = 0; i<upperIndex; i++) {
					//Convert all but first number to absolute values and append to strNum.
					//We separate the scales using scale separator. The last token doesn't append
					//the scale separator, as we append number suffix after that.
					strNum = strNum+String((i == 0) ? numList[i] : Math.abs(numList[i]))+scaleList[i]+(i<upperIndex-1 ? this.scaleSeparator : "");
				}
			}
			//Clear up
			delete numList;
			delete scaleList;
		} else {
			if (bFormatNumber) {
				//Format decimals
				strNum = formatDecimals(intNum, decimals, forceDecimals);
				//Format commas now
				strNum = formatCommas(strNum);
			}
		}
		//Finally, add scale, number prefix and suffix    
		strNum = this.numberPrefix+strNum+strScale+this.numberSuffix;
		return strNum;
	}
	/**
	* formatNumberScale formats the number as per given scale.
	* For example, if number Scale Values are 1000,1000 and
	* number Scale Units are K,M, this method will divide any
	* value over 1000000 using M and any value over 1000 (<1M) using K
	* so as to give abbreviated figures.
	* Number scaling lets you define your own scales for numbers.
	* To clarify further, let's consider an example. Say you're plotting
	* a chart which indicates the time taken by a list of automated
	* processes. Each process in the list can take time ranging from a
	* few seconds to few days. And you've the data for each process in
	* seconds itself. Now, if you were to show all the data on the chart
	* in seconds only, it won't appear too legible. What you can do is
	* build a scale of yours and then specify it to the chart. A scale,
	* in human terms, would look something as under:
	* 60 seconds = 1 minute
	* 60 minute = 1 hr
	* 24 hrs = 1 day
	* 7 days = 1 week
	* First you would need to define the unit of the data which you're providing.
	* Like, in this example, you're providing all data in seconds. So, default
	* number scale would be represented in seconds. You can represent it as under:
	* <graph defaultNumberScale='s' ...>
	* Next, the scale for the chart is defined as under:
	* <graph numberScaleValue='60,60,24,7' numberScaleUnit='min,hr,day,wk' >
	* If you carefully see this and match it with our range, whatever numeric
	* figure was present on the left hand side of the range is put in
	* numberScaleValue and whatever unit was present on the right side of
	* the scale has been put under numberScaleUnit - all separated by commas.
	*
	* Additionally, you can also recursively scale the numbers to format like
	* 6days 8hrs 30 mins instead of 6.xxyyzz days. 
	*	@param	intNum	The number to be scaled.
	*	@returns		The formatted number as an object - array of scales & values.
	*/
	private function formatNumberScale(intNum:Number):Object {
		//Create an object, which will be returned
		var objRtn:Object = new Object();
		//Array of values & scales to be returned.
		var arrValues:Array = new Array();
		var arrScales:Array = new Array();
		var i:Number = 0;
		//Determine the scales, based on whether we've to do recursive parsing
		if (this.scaleRecursively) {
			for (i=0; i<this.nsv.length; i++) {
				if (Math.abs(Number(intNum))>=this.nsv[i] && i<this.nsv.length-1) {
					//Carry over from division
					var carry:Number = intNum%this.nsv[i];
					//Deduct carry over and then divide.
					intNum = (intNum-carry)/this.nsv[i];
					//Push to return array if carry is non 0
					if (carry != 0) {
						arrValues.push(carry);
						arrScales.push(this.nsu[i]);
					}
				} else {
					//This loop executes for first token value (l to r) during recusrive scaling
					//Or, if original number < first number scale value.
					arrValues.push(intNum);
					arrScales.push(this.nsu[i]);
					break;
				}
			}
			//Reverse the arrays - So that lead value stays at 0 index.
			arrValues.reverse();
			arrScales.reverse();
		} else {
			var strScale:String = this.defaultNumberScale;
			for (i=0; i<this.nsv.length-1; i++) {
				if (Math.abs(Number(intNum))>=this.nsv[i]) {
					strScale = this.nsu[i+1];
					intNum = Number(intNum)/this.nsv[i];
				} else {
					break;
				}
			}
			//We need to push only a single value in non recursive case.
			arrValues.push(intNum);
			arrScales.push(strScale);
		}
		//Set the values as properties of objRtn 
		objRtn.value = arrValues;
		objRtn.scale = arrScales;
		//Clear up
		delete arrValues;
		delete arrScales;
		return objRtn;
	}
	/**
	* formatDecimals method formats the decimal places of a number.
	* Requires the following to be defined:
	* this.decimalSeparator
	* this.thousandSeparator
	*	@param	intNum				Number on which we've to work.
	*	@param	decimalPrecision	Number of decimal places to which we've
	*								to format the number to.
	*	@param	forceDecimals		Boolean value indicating whether to add decimal
	*								padding to numbers which are falling as whole
	*								numbers?
	*	@return						A number with the required number of decimal places
	*								in String format. If we return as Number, Flash will remove
	*								our decimal padding or un-wanted decimals.
	*/
	private function formatDecimals(intNum:Number, decimalPrecision:Number, forceDecimals:Boolean):String {
		//If no decimal places are needed, just round the number and return
		if (decimalPrecision<=0) {
			return String(Math.round(intNum));
		}
		//Round the number to specified decimal places       
		//e.g. 12.3456 to 3 digits (12.346)
		//Step 1: Multiply by 10^decimalPrecision - 12345.6
		//Step 2: Round it - i.e., 12346
		//Step 3: Divide by 10^decimalPrecision - 12.346
		var tenToPower:Number = Math.pow(10, decimalPrecision);
		var strRounded:String = String(Math.round(intNum*tenToPower)/tenToPower);
		//Now, strRounded might have a whole number or a number with required
		//decimal places. Our next job is to check if we've to force Decimals.
		//If yes, we add decimal padding by adding 0s at the end.
		if (forceDecimals) {
			//Add a decimal point if missing
			//At least one decimal place is required (as we split later on .)
			//10 -> 10.0
			if (strRounded.indexOf(".") == -1) {
				strRounded += ".0";
			}
			//Finally, we start add padding of 0s.       
			//Split the number into two parts - pre & post decimal
			var parts:Array = strRounded.split(".");
			//Get the numbers falling right of the decimal
			//Compare digits in right half of string to digits wanted
			var paddingNeeded:Number = decimalPrecision-parts[1].length;
			//Number of zeros to add
			for (var i = 1; i<=paddingNeeded; i++) {
				//Add them
				strRounded += "0";
			}
		}
		//Clear up    
		delete parts;
		return (strRounded);
	}
	/**
	* formatCommas method adds proper commas to a number in blocks of 3
	* i.e., 123456 would be formatted as 123,456
	*	@param	strNum	The number to be formatted (as string).
	*					Why are numbers taken in string format?
	*					Here, we are asking for numbers in string format
	*					to preserve the leading and padding 0s of decimals
	*					Like as in -20.00, if number is just passed as number,
	*					Flash automatically reduces it to -20. But, we've to
	*					make sure that we do not disturb the original number.
	*	@return		Formatted number with commas.
	*/
	private function formatCommas(strNum:String):String {
		//intNum would represent the number in number format
		var intNum:Number = Number(strNum);
		//If the number is invalid, return an empty value
		if (isNaN(intNum)) {
			return "";
		}
		var strDecimalPart:String = "";
		var boolIsNegative:Boolean = false;
		var strNumberFloor:String = "";
		var formattedNumber:String = "";
		var startPos:Number = 0;
		var endPos:Number = 0;
		//Define startPos and endPos
		startPos = 0;
		endPos = strNum.length;
		//Extract the decimal part
		if (strNum.indexOf(".") != -1) {
			strDecimalPart = strNum.substring(strNum.indexOf(".")+1, strNum.length);
			endPos = strNum.indexOf(".");
		}
		//Now, if the number is negative, get the value into the flag       
		if (intNum<0) {
			boolIsNegative = true;
			startPos = 1;
		}
		//Now, extract the floor of the number       
		strNumberFloor = strNum.substring(startPos, endPos);
		//Now, strNumberFloor contains the actual number to be formatted with commas
		// If it's length is greater than 3, then format it
		if (strNumberFloor.length>3) {
			// Get the length of the number
			var lenNumber:Number = strNumberFloor.length;
			for (var i:Number = 0; i<=lenNumber; i++) {
				//Append proper commans
				if ((i>2) && ((i-1)%3 == 0)) {
					formattedNumber = strNumberFloor.charAt(lenNumber-i)+this.thousandSeparator+formattedNumber;
				} else {
					formattedNumber = strNumberFloor.charAt(lenNumber-i)+formattedNumber;
				}
			}
		} else {
			formattedNumber = strNumberFloor;
		}
		// Now, append the decimal part back
		if (strDecimalPart != "") {
			formattedNumber = formattedNumber+this.decimalSeparator+strDecimalPart;
		}
		//Now, if neg num       
		if (boolIsNegative == true) {
			formattedNumber = "-"+formattedNumber;
		}
		//Return       
		return formattedNumber;
	}
	/**
	* parseValue method parses the numeric value from the user specified value.
	* If the value is not numeric, we take steps accordingly and return values.
	*	@param	num		Number (in string/object format) which we've to check.
	*	@return		Numeric value of the number. (or NaN)
	*/
	public function parseValue(num):Number {
		//If it's not a number, or if input separators characters
		//are explicity defined, we need to convert value.
		var setValue:Number;
		if (isNaN(num) || (this.inThousandSeparator != "") || (this.inDecimalSeparator != "")) {
			//Number in XML can be invalid or missing (discontinuous data)
			//So, if the length is undefined, it's missing.
			if (num.length == undefined) {
				//Missing data. So just add it as NaN.
				setValue = Number(num);
			} else {
				//It means the number can have different separator, or
				//it can be non-numeric.
				setValue = this.convertNumberSeps(num);
			}
		} else {
			//Simply convert it to numeric form.
			setValue = Number(num);
		}
		//Return value  
		return setValue;
	}
	/**
	* convertNumberSeps method helps us convert the separator (thousands and decimal)
	* character from the user specified input separator characters to normal numeric
	* values that Flash can handle. In some european countries, commas are used as
	* decimal separators and dots as thousand separators. In XML, if the user specifies
	* such values, it will give a error while converting to number. So, we accept the
	* input decimal and thousand separator from user, so that we can covert it accordingly
	* into the required format.
	* If the number is still not a valid number after converting the characters, we log
	* the error and return 0.
	*	@param	strNum	Number in string format containing user defined separator characters.
	*	@return		Number in numeric format.
	*/
	private function convertNumberSeps(strNum:String):Number {
		//If thousand separator is defined, replace the thousand separators
		//in number
		//Store a copy
		var origNum:String = strNum;
		if (this.inThousandSeparator != "") {
			strNum = StringExt.replace(strNum, this.inThousandSeparator, "");
		}
		//Now, if decimal separator is defined, convert it to . 
		if (this.inDecimalSeparator != "") {
			strNum = StringExt.replace(strNum, this.inDecimalSeparator, ".");
		}
		//Now, if the original number was in a valid format(with just different sep chars), 
		//it has now been converted to normal format. But, if it's still giving a NaN, it means
		//that the number is not valid. So, we store it as undefined data.
		if (isNaN(strNum)) {
			throw new Error("Invalid number "+origNum+" specified in XML. FusionCharts can accept number in pure numerical form only. If your number formatting (thousand and decimal separator) is different, please specify so in XML. Also, do not add any currency symbols or other signs to the numbers.");
		}
		return Number(strNum);
	}
}
