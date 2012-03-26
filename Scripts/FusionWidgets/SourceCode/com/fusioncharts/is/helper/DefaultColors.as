/**
* @class DefaultColors
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd. 2005-2006
*
* DefaultColors class stores arrays of default colors to
* be used by a chart
*/
class com.fusioncharts.is.helper.DefaultColors {
	//Array to store colors
	var colors:Array;
	//Iterator Count
	var _iterator:Number;
	//Number of defined palettes. If you want to add your own palette to the chart,
	//feed the color for the new palettes in arrays below and increase the variable
	//count below.
	var numPalettes:Number = 5;
	//Array to store palette colors for different palettes
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
	//For 3D Chart
	var bgColor3D:Array, bgAlpha3D:Array, bgAngle3D:Array, bgRatio3D:Array;
	var canvasbgColor3D:Array, canvasBaseColor3D:Array;
	var legendbgColor3D:Array, legendBorderColor3D:Array;
	var divLineColor3D:Array;
	var toolTipbgColor3D:Array, toolTipBorderColor3D:Array;
	var baseFontColor3D:Array;
	var anchorbgColor3D:Array;
	//Constructor method
	function DefaultColors() {
		//Initialize the array and store colors
		//Colors are to be stored in HEX without #.
		//If you want to add your list of colors, just add
		//them to the array below and recompile the chart.
		//colors = new Array("0099CC", "FF0000", "006F00", "FF66CC", "0099FF", "996600", "669966", "7C7CB4", "FF9933", "CCCC00", "9900FF", "999999", "99FFCC", "CCCCFF", "669900", "1941A5");
		colors = new Array("AFD8F8", "F6BD0F", "8BBA00", "FF8E46", "008E8E", "D64646", "8E468E", "588526", "B3AA00", "008ED6", "9D080D", "A186BE", "CC6600", "FDC689", "ABA000", "F26D7D", "FFF200", "0054A6", "F7941C", "CC3300", "006600", "663300", "6DCFF6");
		//Initialize Iterator
		_iterator = 0;
		//Palette color arrays
		// ------------- For 2D Chart ---------------//
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
		// -------------- For 3D Chart --------------//
		this.bgColor3D = new Array("FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF");
		this.bgAlpha3D = new Array("100", "100", "100", "100", "100");
		this.bgAngle3D = new Array(90, 90, 90, 90, 90);
		this.bgRatio3D = new Array("", "", "", "", "");
		this.canvasbgColor3D = new Array("DDE3D5", "D8D8D7", "EEDFCA", "CFD2D8", "FEE8E0");
		this.canvasBaseColor3D = new Array("ACBB99", "BCBCBD", "C8A06C", "96A4AF", "FAC7BC");
		this.divLineColor3D = new Array("ACBB99", "A4A4A4", "BE9B6B", "7C8995", "D49B8B");
		this.legendbgColor3D = new Array("F0F3ED", "F3F3F3", "F7F0E8", "EEF0F2", "FEF8F5");
		this.legendBorderColor3D = new Array("C6CFB8", "C8C8C8", "DFC29C", "CFD5DA", "FAD1C7");
		this.toolTipbgColor3D = new Array("FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF");
		this.toolTipBorderColor3D = new Array("49563A", "666666", "49351D", "576373", "681C09");
		this.baseFontColor3D = new Array("49563A", "4A4A4A", "49351D", "48505A", "681C09");
		this.anchorbgColor3D = new Array("FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF");
	}	
	/**
	* getColor method cylic-iterates through the colors array
	* and returns a single color
	*/
	public function getColor():String {
		//Get the color
		var strColor:String = colors[_iterator];
		//Increment iterator
		_iterator++;
		//If _iterator is out of bound, reset it to 0
		if (_iterator == (colors.length-1)) {
			_iterator = 0;
		}
		//Return color 
		return strColor;
	}
	/**
	* getPaletteIndex method checks whether the given palette index
	* is proper. If not, it returns 0
	*/
	private function getPaletteIndex(index:Number):Number {
		//If palette index is more than numPalettes or <1
		if (index == undefined || isNaN(index) || (index<1) || (index>numPalettes)) {
			return 0;
		} else {
			//Return original index -1 (for array index)
			return index-1;
		}
	}
	/**
	* The following functions return default colors for a 2D Chart.
	* Colors follow the palette index.
	*/
	function get2DBgColor(index:Number):String {
		//Background color for 2D Chart
		return bgColor[getPaletteIndex(index)];
	}
	function get2DBgAlpha(index:Number):String {
		//Background alpha for 2D Chart
		return bgAlpha[getPaletteIndex(index)];
	}
	function get2DBgAngle(index:Number):Number {
		//Background angle for 2D Chart
		return bgAngle[getPaletteIndex(index)];
	}
	function get2DBgRatio(index:Number):String {
		//Background ratio for 2D Chart
		return bgRatio[getPaletteIndex(index)];
	}
	function get2DCanvasBgColor(index:Number):String {
		//Canvas background color for 2D Chart
		return canvasBgColor[getPaletteIndex(index)];
	}
	function get2DCanvasBgAngle(index:Number):Number {
		//Canvas background angle for 2D Chart
		return canvasBgAngle[getPaletteIndex(index)];
	}
	function get2DCanvasBgAlpha(index:Number):String {
		//Canvas background alpha for 2D Chart
		return canvasBgAlpha[getPaletteIndex(index)];
	}
	function get2DCanvasBgRatio(index:Number):String {
		//Canvas background ratio for 2D Chart
		return canvasBgRatio[getPaletteIndex(index)];
	}
	function get2DCanvasBorderColor(index:Number):String {
		//Canvas border color for 2D Chart
		return canvasBorderColor[getPaletteIndex(index)];
	}
	function get2DCanvasBorderAlpha(index:Number):Number {
		//Canvas border alpha for 2D Chart
		return canvasBorderAlpha[getPaletteIndex(index)];
	}
	function get2DShadow(index:Number):Number {
		//Show Shadow for 2D Chart?
		return showShadow[getPaletteIndex(index)];
	}
	function get2DDivLineColor(index:Number):String {
		//Div line color for 2D Chart
		return divLineColor[getPaletteIndex(index)];
	}
	function get2DDivLineAlpha(index:Number):Number {
		//Div Line alpha for 2D Chart
		return divLineAlpha[getPaletteIndex(index)];
	}
	function get2DAltHGridColor(index:Number):String {
		//Alternate horizontal grid color for 2D Chart
		return altHGridColor[getPaletteIndex(index)];
	}
	function get2DAltHGridAlpha(index:Number):Number {
		//Alternate horizontal grid alpha for 2D Chart
		return altHGridAlpha[getPaletteIndex(index)];
	}
	function get2DAltVGridColor(index:Number):String {
		//Alternate vertical grid color for 2D Chart
		return altVGridColor[getPaletteIndex(index)];
	}
	function get2DAltVGridAlpha(index:Number):Number {
		//Alternate vertical grid alpha for 2D Chart
		return altVGridAlpha[getPaletteIndex(index)];
	}
	function get2DAnchorBgColor(index:Number):String {
		//Anchor background Color for 2D Chart
		return anchorBgColor[getPaletteIndex(index)];
	}
	function get2DToolTipBgColor(index:Number):String {
		//Tool Tip background Color for 2D Chart
		return toolTipBgColor[getPaletteIndex(index)];
	}
	function get2DToolTipBorderColor(index:Number):String {
		//Tool tip Border Color for 2D Chart
		return toolTipBorderColor[getPaletteIndex(index)];
	}
	function get2DBaseFontColor(index:Number):String {
		//Base Font for 2D Chart
		return baseFontColor[getPaletteIndex(index)];
	}
	function get2DBorderColor(index:Number):String {
		//Chart Border Color
		return borderColor[getPaletteIndex(index)];
	}
	function get2DBorderAlpha(index:Number):Number {
		//Chart Border Alpha 2D Chart
		return borderAlpha[getPaletteIndex(index)];
	}
	function get2DLegendBgColor(index:Number):String {
		//Legend background Color for 2D Chart
		return legendBgColor[getPaletteIndex(index)];
	}
	function get2DLegendBorderColor(index:Number):String {
		//Legend Border Color
		return legendBorderColor[getPaletteIndex(index)];
	}
	function get2DPlotGradientColor(index:Number):String {
		//Plot Gradient Color
		return plotGradientColor[getPaletteIndex(index)];
	}
	function get2DPlotBorderColor(index:Number):String {
		//Plot Border Color
		return plotBorderColor[getPaletteIndex(index)];
	}
	function get2DPlotFillColor(index:Number):String {
		//Plot Fill Color
		return plotFillColor[getPaletteIndex(index)];
	}
	/**
	* Default palette properties for 3D Chart.
	*/
	function getBgColor3D(index:Number):String {
		//Background Color
		return bgColor3D[getPaletteIndex(index)];
	}
	function getBgAlpha3D(index:Number):Number {
		//Background Alpha
		return bgAlpha3D[getPaletteIndex(index)];
	}
	function getBgAngle3D(index:Number):Number {
		//Background Angle
		return bgAngle3D[getPaletteIndex(index)];
	}
	function getBgRatio3D(index:Number):String {
		//Background Ratio
		return bgRatio3D[getPaletteIndex(index)];
	}
	function getCanvasBgColor3D(index:Number):String {
		//Canvas background color
		return canvasbgColor3D[getPaletteIndex(index)];
	}
	function getCanvasBaseColor3D(index:Number):String {
		//Canvas Base color
		return canvasBaseColor3D[getPaletteIndex(index)];
	}
	function getLegendBgColor3D(index:Number):String {
		//Legend background color
		return legendbgColor3D[getPaletteIndex(index)];
	}
	function getLegendBorderColor3D(index:Number):String {
		//Legend border color
		return legendBorderColor3D[getPaletteIndex(index)];
	}
	function getDivLineColor3D(index:Number):String {
		//Div line color
		return divLineColor3D[getPaletteIndex(index)];
	}
	function getToolTipBgColor3D(index:Number):String {
		//Tool tip background color
		return toolTipbgColor3D[getPaletteIndex(index)];
	}
	function getToolTipBorderColor3D(index:Number):String {
		//Tool tip border color
		return toolTipBorderColor3D[getPaletteIndex(index)];
	}
	function getBaseFontColor3D(index:Number):String {
		//Base Fontcolor
		return baseFontColor3D[getPaletteIndex(index)];
	}
	function getAnchorBgColor3D(index:Number):String {
		//Anchor background
		return anchorbgColor3D[getPaletteIndex(index)];
	}
	//Re-set method resets the iterator to 0.
	public function reset():Void {
		_iterator = 0;
	}
}
