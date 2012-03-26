/**
* @class BulletColorManager
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* BulletColorManager class helps manage the default colors and palettes
* for bullet charts. With colors, we also store gradient ratios and alphas
* for certain elements.
*/
import com.fusioncharts.is.extensions.ColorExt;
class com.fusioncharts.is.colormanagers.BulletColorManager {
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
	var tickColor:Array, trendColor:Array;
	var toolTipBgColor:Array, toolTipBorderColor:Array;
	var baseFontColor:Array;
	var borderColor:Array, borderAlpha:Array;
	var plotFillColor:Array;
	/**
	 * Constructor function.
	 *	@param	paletteId	Palette Id for the chart.
	 *	@param	themeColor	Color code if the chart uses single color theme.
	*/
	function BulletColorManager(paletteId:Number, themeColor:String) {
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
		this.paletteColors[1] = new Array("A6A6A6", "CCCCCC", "E1E1E1", "F0F0F0");
		this.paletteColors[2] = new Array("A7AA95", "C4C6B7", "DEDFD7", "F2F2EE");
		this.paletteColors[3] = new Array("04C2E3","66E7FD","9CEFFE","CEF8FF");
		this.paletteColors[4] = new Array("FA9101", "FEB654", "FED7A0", "FFEDD5");
		this.paletteColors[5] = new Array("FF2B60", "FF6C92", "FFB9CB", "FFE8EE");
		//Store other colors 
		// ------------- For 2D Chart ---------------//
		//We're storing 5 combinations, as we've 5 defined palettes.
		this.bgColor = new Array("FFFFFF", "CFD4BE,F3F5DD", "C5DADD,EDFBFE", "A86402,FDC16D", "FF7CA0,FFD1DD");
		this.bgAngle = new Array(270, 270, 270, 270, 270);
		this.bgRatio = new Array("0,100", "0,100", "0,100", "0,100", "0,100");
		this.bgAlpha = new Array("100", "60,50", "40,20", "20,10", "30,30");		
		
		this.toolTipBgColor = new Array("FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF");
		this.toolTipBorderColor = new Array("545454", "545454", "415D6F", "845001", "68001B");
		
		this.baseFontColor = new Array("333333", "60634E", "025B6A", "A15E01", "68001B");		
		this.tickColor = new Array("333333", "60634E", "025B6A", "A15E01", "68001B");
		this.trendColor = new Array("545454", "60634E", "415D6F", "845001", "68001B");
		
		this.plotFillColor = new Array("545454", "60634E", "415D6F", "845001", "68001B");
		
		this.borderColor = new Array("767575", "545454", "415D6F", "845001", "68001B");
		this.borderAlpha = new Array(50, 50, 50, 50, 50);
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
		if (_iterator == (this.paletteColors[this.palette].length)) {
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
	
	public function getTickColor():String {
		//Tick mark color
		if (theme) {
			return (ColorExt.getDarkColor(this.themeColor, 0.9).toString(16));
		} else {
			return this.tickColor[this.palette-1];
		}
	}	
	public function getTrendColor():String {
		//Trend dark color
		if (theme) {
			return (ColorExt.getDarkColor(this.themeColor, 0.9).toString(16));
		} else {
			return this.trendColor[this.palette-1];
		}
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
	public function get2DPlotFillColor():String {
		//Plot Fill Color
		if (theme) {
			return (ColorExt.getDarkColor(this.themeColor, 0.85).toString(16));
		} else {
			return this.plotFillColor[this.palette-1];
		}
	}
	//Re-set method resets the iterator to 0.
	public function reset():Void {
		_iterator = 0;
	}
}