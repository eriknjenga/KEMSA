/**
* @class AxisChartColorManager
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* AxisChartColorManager class helps manage the default colors and palettes
* for a real-time axis chart. With colors, we also store gradient ratios and alphas
* for certain elements.
*/
import com.fusioncharts.is.extensions.ColorExt;
class com.fusioncharts.is.colormanagers.AxisChartColorManager {
	//Reference to the palette that this color Manager class uses
	private var palette:Number;
	//If the color manager has to work on a single color them
	private var themeColor:String;
	//Flag indicating whether we're using a theme color, or a single color
	private var theme:Boolean;
	//Number of defined palettes. 
	private var numPalettes:Number = 5;
	//Arrays to store palette colors
	private var paletteColors:Array;
	//Iterator Count
	private var _iterator:Number;
	//Containers to store colors, ratios and alphas for 2D Chart
	//For 2D Chart
	var bgColor:Array, bgAlpha:Array, bgAngle:Array, bgRatio:Array;
	var canvasBgColor:Array, canvasBgAngle:Array, canvasBgAlpha:Array, canvasBgRatio:Array;
	var canvasBorderColor:Array, canvasBorderAlpha:Array;
	var divLineColor:Array, divLineAlpha:Array;
	var altHGridColor:Array, altHGridAlpha:Array;
	var altVGridColor:Array, altVGridAlpha:Array;
	var showShadow:Array;
	var anchorBgColor:Array;
	var toolTipBgColor:Array, toolTipBorderColor:Array;
	var baseFontColor:Array;
	var borderColor:Array, borderAlpha:Array;
	var legendBgColor:Array, legendBorderColor:Array;
	var plotFillColor:Array, plotBorderColor:Array, plotGradientColor:Array;
	var msgLogColor:Array;
	/**
	 * Constructor function.
	 *	@param	paletteId	Palette Id for the chart.
	 *	@param	themeColor	Color code if the chart uses single color theme.
	*/
	function AxisChartColorManager(paletteId:Number, themeColor:String) {
		//Store parameters
		this.palette = paletteId;
		//Validation: If palette is undefined or <1 or >5, we select 1 as default palette
		if (this.palette == undefined || this.palette == null || this.palette<1 || this.palette>this.numPalettes) {
			this.palette = 1;
		}
		//Theme color  
		this.themeColor = themeColor;
		//Update flag theme, if we've to use theme color
		this.theme = (this.themeColor == "" || this.themeColor == undefined) ? false : true;
		//Initialize class containers
		this.paletteColors = new Array();
		//Create sub-arrays for paletteColors
		for (var i:Number = 1; i<=this.numPalettes; i++) {
			this.paletteColors[i] = new Array();
		}
		this._iterator = 0;
		//Store colors now
		//Colors for gauge "339900", "DD9B02", "943A0A", 
		this.paletteColors[1] = new Array("AFD8F8", "F6BD0F", "8BBA00", "FF8E46", "008E8E", "D64646", "8E468E", "588526", "B3AA00", "008ED6", "9D080D", "A186BE", "CC6600", "FDC689", "ABA000", "F26D7D", "FFF200", "0054A6", "F7941C", "CC3300", "006600", "663300", "6DCFF6");
		this.paletteColors[2] = new Array("AFD8F8", "F6BD0F", "8BBA00", "FF8E46", "008E8E", "D64646", "8E468E", "588526", "B3AA00", "008ED6", "9D080D", "A186BE", "CC6600", "FDC689", "ABA000", "F26D7D", "FFF200", "0054A6", "F7941C", "CC3300", "006600", "663300", "6DCFF6");
		this.paletteColors[3] = new Array("AFD8F8", "F6BD0F", "8BBA00", "FF8E46", "008E8E", "D64646", "8E468E", "588526", "B3AA00", "008ED6", "9D080D", "A186BE", "CC6600", "FDC689", "ABA000", "F26D7D", "FFF200", "0054A6", "F7941C", "CC3300", "006600", "663300", "6DCFF6");
		this.paletteColors[4] = new Array("AFD8F8", "F6BD0F", "8BBA00", "FF8E46", "008E8E", "D64646", "8E468E", "588526", "B3AA00", "008ED6", "9D080D", "A186BE", "CC6600", "FDC689", "ABA000", "F26D7D", "FFF200", "0054A6", "F7941C", "CC3300", "006600", "663300", "6DCFF6");
		this.paletteColors[5] = new Array("AFD8F8", "F6BD0F", "8BBA00", "FF8E46", "008E8E", "D64646", "8E468E", "588526", "B3AA00", "008ED6", "9D080D", "A186BE", "CC6600", "FDC689", "ABA000", "F26D7D", "FFF200", "0054A6", "F7941C", "CC3300", "006600", "663300", "6DCFF6");
		//Store other colors 
		// ------------- For 2D Chart ---------------//
		//We're storing 5 combinations, as we've 5 defined palettes.
		this.bgColor = new Array("CBCBCB,E9E9E9", "CFD4BE,F3F5DD", "C5DADD,EDFBFE", "A86402,FDC16D", "FF7CA0,FFD1DD");
		this.bgAngle = new Array(270, 270, 270, 270, 270);
		this.bgRatio = new Array("0,100", "0,100", "0,100", "0,100", "0,100");
		this.bgAlpha = new Array("50,50", "60,50", "40,20", "20,10", "30,30");
		this.canvasBgColor = new Array("FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF");
		this.canvasBgAngle = new Array(0, 0, 0, 0, 0);
		this.canvasBgAlpha = new Array("100", "100", "100", "100", "100");
		this.canvasBgRatio = new Array("", "", "", "", "");
		this.canvasBorderColor = new Array("545454", "545454", "415D6F", "845001", "68001B");
		this.canvasBorderAlpha = new Array(100, 100, 100, 90, 100);
		this.showShadow = new Array(0, 1, 1, 1, 1);
		this.divLineColor = new Array("717170", "7B7D6D", "92CDD6", "965B01", "68001B");		
		this.divLineAlpha = new Array(40, 45, 65, 40, 30);
		this.altHGridColor = new Array("EEEEEE", "D8DCC5", "99C4CD", "DEC49C", "FEC1D0");
		this.altHGridAlpha = new Array(50, 35, 10, 20, 15);
		this.altVGridColor = new Array("767575", "D8DCC5", "99C4CD", "DEC49C", "FEC1D0");
		this.altVGridAlpha = new Array(10, 20, 10, 15, 10);
		this.anchorBgColor = new Array("FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF");
		this.toolTipBgColor = new Array("FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF");
		this.toolTipBorderColor = new Array("545454", "545454", "415D6F", "845001", "68001B");
		this.baseFontColor = new Array("555555", "60634E", "025B6A", "A15E01", "68001B");
		this.borderColor = new Array("767575", "545454", "415D6F", "845001", "68001B");
		this.borderAlpha = new Array(50, 50, 50, 50, 50);
		this.legendBgColor = new Array("ffffff", "ffffff", "ffffff", "ffffff", "ffffff");
		this.legendBorderColor = new Array("545454", "545454", "415D6F", "845001", "D55979");
		this.plotGradientColor = new Array("ffffff", "ffffff", "ffffff", "ffffff", "ffffff");
		this.plotBorderColor = new Array("333333", "8A8A8A", "ffffff", "ffffff", "ffffff");
		this.plotFillColor = new Array("767575", "D8DCC5", "99C4CD", "DEC49C", "FEC1D0");
		this.msgLogColor = new Array("717170", "7B7D6D", "92CDD6", "965B01", "68001B");
	}
	/**
	* getColor method cylic-iterates through the palette colors array
	* and returns a single color, based on user's selection of palette.
	*/
	public function getColor():String {
		//Get the color
		var strColor:String = this.paletteColors[this.palette][_iterator];
		//Increment iterator
		_iterator++;
		//If _iterator is out of bound, reset it to 0
		if (_iterator == (this.paletteColors[this.palette].length-1)) {
			_iterator = 0;
		}
		//Return color   
		return strColor;
	}
	// ----------- Accessor functions to access colors for different elements ------------//
	/**
	* The following functions return default colors for a 2D Chart, based on the palette
	* selected by the user. Also, if the user has selected a single color theme, we calculate
	* the same and return accordingly.
	*/
	public function get2DBgColor():String {
		//Background color for 2D Chart
		if (theme) {
			return (ColorExt.getLightColor(this.themeColor, 0.35).toString(16)+","+ColorExt.getLightColor(this.themeColor, 0.1).toString(16));
		} else {
			return this.bgColor[this.palette-1];
		}
	}
	public function get2DBgAlpha():String {
		//Background alpha for 2D Chart
		return this.bgAlpha[this.palette-1];
	}
	public function get2DBgAngle():Number {
		//Background angle for 2D Chart
		return this.bgAngle[this.palette-1];
	}
	public function get2DBgRatio():String {
		//Background ratio for 2D Chart
		return this.bgRatio[this.palette-1];
	}
	public function get2DCanvasBgColor():String {
		//Canvas background color for 2D Chart
		return this.canvasBgColor[this.palette-1];
	}
	public function get2DCanvasBgAngle():Number {
		//Canvas background angle for 2D Chart
		return this.canvasBgAngle[this.palette-1];
	}
	public function get2DCanvasBgAlpha():String {
		//Canvas background alpha for 2D Chart
		return this.canvasBgAlpha[this.palette-1];
	}
	public function get2DCanvasBgRatio():String {
		//Canvas background ratio for 2D Chart
		return this.canvasBgRatio[this.palette-1];
	}
	public function get2DCanvasBorderColor():String {
		//Canvas border color for 2D Chart
		if (theme) {
			return (ColorExt.getDarkColor(this.themeColor, 0.8).toString(16));
		} else {
			return this.canvasBorderColor[this.palette-1];
		}
	}
	public function get2DCanvasBorderAlpha():Number {
		//Canvas border alpha for 2D Chart
		return this.canvasBorderAlpha[this.palette-1];
	}
	public function get2DShadow():Number {
		//Show Shadow for 2D Chart?
		return this.showShadow[this.palette-1];
	}
	public function get2DDivLineColor():String {
		//Div line color for 2D Chart
		if (theme) {
			return (ColorExt.getLightColor(this.themeColor, 0.8).toString(16));
		} else {
			return this.divLineColor[this.palette-1];
		}
	}
	public function get2DDivLineAlpha():Number {
		//Div Line alpha for 2D Chart
		return this.divLineAlpha[this.palette-1];
	}
	public function get2DAltHGridColor():String {
		//Alternate horizontal grid color for 2D Chart
		if (theme) {
			return (ColorExt.getLightColor(this.themeColor, 0.2).toString(16));
		} else {
			return this.altHGridColor[this.palette-1];
		}
	}
	public function get2DAltHGridAlpha():Number {
		//Alternate horizontal grid alpha for 2D Chart
		return this.altHGridAlpha[this.palette-1];
	}
	public function get2DAltVGridColor():String {
		//Alternate vertical grid color for 2D Chart
		if (theme) {
			return (ColorExt.getLightColor(this.themeColor, 0.8).toString(16));
		} else {
			return this.altVGridColor[this.palette-1];
		}
	}
	public function get2DAltVGridAlpha():Number {
		//Alternate vertical grid alpha for 2D Chart
		return this.altVGridAlpha[this.palette-1];
	}
	public function get2DAnchorBgColor():String {
		//Anchor background Color for 2D Chart
		return this.anchorBgColor[this.palette-1];
	}
	public function get2DToolTipBgColor():String {
		//Tool Tip background Color for 2D Chart
		return this.toolTipBgColor[this.palette-1];
	}
	public function get2DToolTipBorderColor():String {
		//Tool tip Border Color for 2D Chart
		if (theme) {
			return (ColorExt.getDarkColor(this.themeColor, 0.8).toString(16));
		} else {
			return this.toolTipBorderColor[this.palette-1];
		}
	}
	public function get2DBaseFontColor():String {
		//Base Font for 2D Chart
		if (theme) {
			return (this.themeColor);
		} else {
			return this.baseFontColor[this.palette-1];
		}
	}
	public function get2DBorderColor():String {
		//Chart Border Color
		if (theme) {
			return (ColorExt.getDarkColor(this.themeColor, 0.6).toString(16));
		} else {
			return this.borderColor[this.palette-1];
		}
	}
	public function get2DBorderAlpha():Number {
		//Chart Border Alpha 2D Chart
		return this.borderAlpha[this.palette-1];
	}
	public function get2DLegendBgColor():String {
		//Legend background Color for 2D Chart
		return this.legendBgColor[this.palette-1];
	}
	public function get2DLegendBorderColor():String {
		//Legend Border Color
		if (theme) {
			return (ColorExt.getDarkColor(this.themeColor, 0.8).toString(16));
		} else {
			return this.legendBorderColor[this.palette-1];
		}
	}
	public function get2DPlotGradientColor():String {
		//Plot Gradient Color
		return this.plotGradientColor[this.palette-1];
	}
	public function get2DPlotBorderColor():String {
		//Plot Border Color
		if (theme) {
			return (ColorExt.getDarkColor(this.themeColor, 0.85).toString(16));
		} else {
			return this.plotBorderColor[this.palette-1];
		}
	}
	public function get2DPlotFillColor():String {
		//Plot Fill Color
		if (theme) {
			return (ColorExt.getDarkColor(this.themeColor, 0.85).toString(16));
		} else {
			return this.plotFillColor[this.palette-1];
		}
	}
	public function get2DMsgLogColor():String {
		//Plot Fill Color
		if (theme) {
			return (ColorExt.getLightColor(this.themeColor, 0.8).toString(16));
		} else {
			return this.msgLogColor[this.palette-1];
		}
	}
	//Re-set method resets the iterator to 0.
	public function reset():Void {
		_iterator = 0;
	}
}
