/**
* @class ColorExt
* @author InfoSoft Global (P) Ltd.
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd. 2006
*
* ColorExt class groups a bunch of Color related functions.
*/
import com.fusioncharts.is.extensions.StringExt;
class com.fusioncharts.is.extensions.ColorExt {
	/**
	* Since ColorExt class is just a grouping of color related methods,
	* we do not want any instances of it (as all methods wil be static).
	* So, we declare a private constructor
	*/
	private function ColorExt() {
		//Private constructor to avoid creation of instances
	}
	/**
	* formatHexColor method helps us format a given hexadecimal color
	* in the format as required by FusionCharts. FusionCharts needs that
	*  - the hex value shouldn't contain leading spaces
	*  - the hex value shouldn't contain # character
	* @param	sourceHexColor	The hex color code to be formatted
	* @return					The formatted hex color code without
	*							spaces or #.
	*/
	public static function formatHexColor(sourceHexColor:String):String {
		//Trim the leading spaces before #
		sourceHexColor = StringExt.leftTrimChar(sourceHexColor, " ");
		//Trim the #
		sourceHexColor = StringExt.leftTrimChar(sourceHexColor, "#");
		//Return the formatted color
		return sourceHexColor;
	}
	/**
	* getDarkColor method helps us find a darker shade for a given
	* hex color string, based on the intensity specified.
	* @param	sourceHexColor	The hex color code (without #) for which
	*							we need a darker shade.
	* @param	intensity		Intensity of the darker shade which we need.
	*							It can be between 0 and 1. Lower the intensity,
	*							darker the color i.e., 0 is black and 1 is original
	*							color specified.
	* @return					The RGB numeric value of the darker color calculated.
	*/
	public static function getDarkColor(sourceHexColor:String, intensity:Number):Number {
		//Check whether the intensity is in right range
		intensity = ((intensity>1) || (intensity<0)) ? 1 : intensity;
		//Format the color in RGB notation
		var sourceclrRGB:Number = parseInt(sourceHexColor, 16);
		//Now, get the r,g,b values separated out of the specified color
		var r:Number = Math.floor(sourceclrRGB/65536);
		var g:Number = Math.floor((sourceclrRGB-r*65536)/256);
		var b:Number = sourceclrRGB-r*65536-g*256;
		//Now, get the darker color based on the Intesity Specified
		var darkColor:Number = (r*intensity) << 16 | (g*intensity) << 8 | (b*intensity);
		return (darkColor);
	}
	/**
	* getLightColor method helps us find a lighter shade for a given
	* hex color string, based on the intensity specified.
	* @param	sourceHexColor	The hex color code (without #) for which
	*							we need a lighter shade.
	* @param	intensity		Intensity of the lighter shade which we need.
	*							It can be between 0 and 1. Lower the intensity,
	*							lighter the color. 
	* @return					The RGB numeric value of the lighter color calculated.
	*/
	public static function getLightColor(sourceHexColor:String, intensity:Number):Number {
		//0 intensity returns white
		if (intensity==0){
			return parseInt("FFFFFF",16);
		}
		//Check whether the intensity is in right range
		intensity = ((intensity>1) || (intensity<0)) ? 1 : intensity;
		//Format the color in RGB notation
		var sourceclrRGB:Number = parseInt(sourceHexColor, 16);
		//Now, get the r,g,b values separated out of the specified color
		var r:Number = Math.floor(sourceclrRGB/65536);
		var g:Number = Math.floor((sourceclrRGB-r*65536)/256);
		var b:Number = sourceclrRGB-r*65536-g*256;
		//Now, get the lighter color based on the Intesity Specified
		var lightColor:Number = (256-((256-r)*intensity)) << 16 | (256-((256-g)*intensity)) << 8 | (256-((256-b)*intensity));
		return (lightColor);
	}
	/**
	* parseColorList method takes a list of hex colors separated
	* by comma and returns an array of the individual hex colors
	* after validating each color code.
	*	@param	strColors	List of colors separated by comma e.g.,
	*						FF0000,F1F1F1,FFCCDD etc.
	*	@return			An array whose each cell contains a single
	*						color code (validated).
	*/
	public static function parseColorList(strColors:String):Array {
		//Create am array to store input colors and final colors
		var arrInputColors:Array = new Array();
		//Output colors
		var arrColors:Array = new Array();
		//Count of valid colors
		var numCount:Number = 0;
		var i:Number;
		var strColor:String;
		//Split the colors which are separated by comma
		arrInputColors = strColors.split(",");
		//Now, run through each color in the input array and check for it's validity
		for (i=0; i<arrInputColors.length; i++) {
			//Check for the validity of hex color
			strColor = ColorExt.formatHexColor(arrInputColors[i]);
			//Now, if the color is empty, we do not add it - else we do
			if (strColor != "" && strColor != null) {
				//Store it in the array
				arrColors[numCount] = parseInt(strColor, 16);
				//Increase the counter
				numCount++;
			}
		}
		//Return the final list of colors
		return arrColors;
	}
	/**
	* parseAlphaList method takes a list of alphas separated
	* by comma and returns an array of the individual alphas
	*	@param	strAlphas	List of alphas separated by comma e.g.,
	*						20,30,40 etc.
	*	@param	numColors	Number of colors for which we've to build
	*						the alpha list
	*	@return			An array whose each cell contains a single
	*						alpha value (validated).
	*/
	public static function parseAlphaList(strAlphas:String, numColors:Number):Array {
		//Input list of alpha
		var arrInputAlphas:Array = new Array();
		//Final list
		var arrAlphas:Array = new Array();
		//Extract the input alphas
		arrInputAlphas = strAlphas.split(",");
		//Count of valid alphas
		var alpha:Number;
		//Loop variable
		var i:Number;
		//Change the alpha matrix to number (from string base)
		for (i=0; i<numColors; i++) {
			//Get the alpha
			alpha = arrInputAlphas[i];
			//Now, if the alpha is non-numeric or undefined, we set our own values
			alpha = (isNaN(alpha) || (alpha == undefined)) ? 100 : Number(alpha);
			//Store it in the array
			arrAlphas[i] = alpha;
		}
		//Return the array
		return arrAlphas;
	}
	/**
	* parseRatioList method takes a list of color division ratios
	* (on base of 100%) separated by comma and returns an array of
	* the individual ratios (on base of 255 hex).
	*	@param	strRatios	List of ratios (on base of 100%) separated by
	*						comma e.g., 20,40,40 or 5,5,90 etc.
	*	@param	numColors	Number of colors for which we've to build
	*						the ratio list
	*	@return				An array whose each cell contains a single
	*						ratio value (on base of 255 hex).
	*/
	public static function parseRatioList(strRatios:String, numColors:Number):Array {
		//Arrays to store input and final ratio
		var arrInputRatios:Array = new Array();
		var arrRatios:Array = new Array();
		//Split the user input ratios
		arrInputRatios = strRatios.split(",");
		//Sum of ratios
		var sumRatio:Number = 0;
		var ratio:Number;
		//Loop variable
		var i:Number;
		//First, check if all ratios are numbers and calculate sum
		for (i=0; i<numColors; i++) {
			//Get the ratio
			ratio = arrInputRatios[i];
			//Now, if the ratio is non-numeric or undefined, we set our own values
			ratio = (isNaN(ratio) || (ratio == undefined)) ? 0 : Math.abs(Number(ratio));
			//If ratio is greater than 100, restrict it to 100
			ratio = (ratio>100) ? 100 : ratio;
			//Allot it to final array
			arrRatios[i] = ratio;
			//Add to sum
			sumRatio += ratio;
		}
		//Total ratio inputted by user should not exceed 100
		sumRatio = (sumRatio>100) ? 100 : sumRatio;
		//If more colors are present than the number of ratios, we need to
		//proportionately append the rest of values
		if (arrInputRatios.length<numColors) {
			for (i=arrInputRatios.length; i<numColors; i++) {
				arrRatios[i] = (100-sumRatio)/(numColors-arrInputRatios.length);
			}
		}
		//Now, convert ratio percentage to actual values from 0 to 255 (Hex base)  
		arrRatios[-1] = 0;
		var prevRatio:Number = 0;
		for (i=0; i<numColors; i++) {
			prevRatio = Number(arrRatios[i-1]);
			arrRatios[i] = prevRatio+Number(arrRatios[i]/100*255);
			//Bind to ceiling limit - 255 for hex ratio
			arrRatios[i] = (arrRatios[i]>255) ? 255 : arrRatios[i];
		}
		//Return the ratios array
		return arrRatios;
	}
	/**
	 * RGB2HSL method returns the Hue, Luminance and Saturation color
	 * values for a given RGB value. Hue is returned in degree (base 360),
	 * luminance (light) in % and saturation in % too.
	 *	@param	rgbCode		RGB color code.
	 *	@return				Object having the following properties
	 *						h - hue
	 *						l - luminance
	 *						s - saturation
	 * Due to approximations in rounding, there might be a slight variation 
	 * in color in 35% of conversions from HSL to RGB and back. The variation
	 * is minute (shift of 1 hex channel) and occurs only in one color channel.
	*/
	public static function RGB2HSL(rgbCode:Number):Object {
		//Extract r,g & b components from the color.	
		var r:Number = rgbCode/65536;
		var g:Number = (rgbCode-(Math.floor(r)*65536))/256;
		var b:Number = (rgbCode-(Math.floor(r)*65536)-(Math.floor(g)*256));
		//Make in ratio of 255
		r = r/255;
		g = g/255;
		b = b/255;
		//Initialize Variables
		var v:Number, m:Number, vm:Number;
		var r2:Number, g2:Number, b2:Number;
		//Hue, Saturation and Light
		var h:Number = 0;
		//Default to Black
		var s:Number = 0;
		var l:Number = 0;
		v = Math.max(Math.max(r, g), b);
		m = Math.min(Math.min(r, g), b);
		//Light
		l = (m+v)/2;
		//Light cannot be less than 0
		if (l<0) {
			throw new Error("Invalid Hex Code Specified");
			return new Object();
		}
		vm = v-m;
		s = vm;
		if (s>=0) {
			var d:Number = (l<=0.5) ? (v+m) : (2-v-m);
			s = s/d;
		} else {
			throw new Error("Invalid Hex Code Specified");
			return new Object();
		}
		r2 = (v-r)/vm;
		g2 = (v-g)/vm;
		b2 = (v-b)/vm;
		if (r == v) {
			h = (g == m ? 5+b2 : 1-g2);
		} else if (g == v) {
			h = (b == m ? 1+r2 : 3-b2);
		} else {
			h = (r == m ? 3+g2 : 5-r2);
		}
		//Convert hue into degrees
		h = (h/6)*360;
		h = (h>=360) ? 0 : h;
		//Saturation and Light into 100%
		l = l*100;
		s = s*100;
		//Create an object representation of the same
		var rtnObj:Object = new Object();
		rtnObj.h = h;
		rtnObj.l = l;
		rtnObj.s = s;
		return rtnObj;
	}
	/**
	 * HSL2RGB method converts HSL color code into RGB code.
	 *	@param	h	Hue component of color (in base 360 degree).
	 *	@param	s	Saturation component of color (in base 100%)
	 *	@param	l	Luminance component of color (in base 100%)
	 *	@return		RGB code for the color
	*/
	public static function HSL2RGB(h:Number, s:Number, l:Number):Number {
		var v:Number;
		//RGB Components
		var r:Number, g:Number, b:Number;
		//Convert h, s, l from respective bases to 0-1 ratio
		h = h/360;
		s = s/100;
		l = l/100;
		//Default to gray color
		r = l;
		g = l;
		b = l;
		v = (l<=0.5) ? (l*(1+s)) : (l+s-l*s);
		if (v>0) {
			var m:Number, sv:Number, sextant:Number;
			var fract:Number, vsf:Number, mid1:Number, mid2:Number;
			m = l+l-v;
			sv = (v-m)/v;
			h *= 6;
			sextant = Math.floor(h);
			fract = h-sextant;
			vsf = v*sv*fract;
			mid1 = m+vsf;
			mid2 = v-vsf;
			switch (sextant) {
			case 0 :
				r = v;
				g = mid1;
				b = m;
				break;
			case 1 :
				r = mid2;
				g = v;
				b = m;
				break;
			case 2 :
				r = m;
				g = v;
				b = mid1;
				break;
			case 3 :
				r = m;
				g = mid2;
				b = v;
				break;
			case 4 :
				r = mid1;
				g = m;
				b = v;
				break;
			case 5 :
				r = v;
				g = m;
				b = mid2;
				break;
			}
		}
		//Multiply by 255  
		r = r*255;
		g = g*255;
		b = b*255;
		//Join them back using Bit operators
		var rgb:Number = r << 16 | g << 8 | b;
		return rgb;
	}
	/**
	 * parseColorMix method parses the color mix formula and returns
	 * an array of colors depending of the constituents specified in
	 * the formula.
	 *	@param	aColor		Actual color on which calculations will be based on.
	 *	@param	mix			Formula containing the mix of colors.
	 *						Example: ("943A0A","{light-50},FFFFFF,{color},{dark-25}")
	 *	@return				Array of colors containing the required mix of colors (in RGB) - not HEX
	*/
	public static function parseColorMix(aColor:String, mix:String):Array {
		//Remove all spaces from the formula
		mix = StringExt.replace(mix, " ", "");
		//Convert to lower case for case insensitive comparison
		mix = mix.toLowerCase();
		//If mix is blank, undefined or null, return the single color
		if (mix == "" || mix == null || mix == undefined) {
			return [parseInt(aColor, 16)];
		}
		//Loop variables 
		var i:Number, j:Number;
		var dashIndex:Number, intensity:Number;
		//Now, split into main tokens	
		var tokens:Array = mix.split(",");
		//Create a return array
		var rtnArr:Array = new Array();
		//Iterate through each token to check what it is.
		for (i=0; i<tokens.length; i++) {
			//Remove { and } from token.
			tokens[i] = StringExt.replace(tokens[i], "{", "");
			tokens[i] = StringExt.replace(tokens[i], "}", "");
			//Now, based on what token is, we take action
			if (tokens[i] == "color") {
				//If actual color
				rtnArr.push(parseInt(aColor, 16));
			} else if (tokens[i].substr(0, 5) == "light") {
				//Need to find lighter shade
				//First find the intensity, which the user has specified.
				//Get dash index
				dashIndex = tokens[i].indexOf("-");
				intensity = (dashIndex == -1) ? 1 : (tokens[i].substr(dashIndex+1, tokens[i].length-dashIndex));
				//Now in actual method, 0 means lightest and 1 means normal. So, we've to reverse
				intensity = (100-intensity)/100;
				//Push the lighter color in array
				rtnArr.push(ColorExt.getLightColor(aColor, intensity));
			} else if (tokens[i].substr(0, 4) == "dark") {
				//Need to find darker shade
				//First find the intensity, which the user has specified.
				//Get dash index
				dashIndex = tokens[i].indexOf("-");
				intensity = (dashIndex == -1) ? 1 : (tokens[i].substr(dashIndex+1, tokens[i].length-dashIndex));
				//Now in actual method, 0 means darkest and 1 means normal. So, we've to reverse
				intensity = (100-intensity)/100;
				//Push the darker color in array
				rtnArr.push(ColorExt.getDarkColor(aColor, intensity));
			} else {
				//User has himself given a normal hex color code.
				//So, convert and append
				rtnArr.push(parseInt(tokens[i], 16));
			}
		}
		//Return array
		return rtnArr;
	}	
}
