/**
* @class ColorManager
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* ColorManager class helps manage the default colors and palettes
* for a chart. This is base class which can be extended by each chart's
* own color manager.
*/
import com.fusioncharts.is.extensions.ColorExt;
class com.fusioncharts.is.colormanagers.ColorManager{
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
	/**
	 * Constructor function.
	 *	@param	paletteId	Palette Id for the chart.
	 *	@param	themeColor	Color code if the chart uses single color theme.
	*/
	function ColorManager(paletteId:Number, themeColor:String){
		//Store parameters
		this.palette = paletteId;
		//Validation: If palette is undefined or <1 or >5, we select 1 as default palette
		if(this.palette==undefined || this.palette==null || this.palette<1 || this.palette>this.numPalettes){
			this.palette = 1;
		}
		//Theme color
		this.themeColor = themeColor;
		//Update flag theme, if we've to use theme color
		this.theme = (this.themeColor=="" || this.themeColor==undefined)?false:true;
		//Initialize class containers
		this.paletteColors = new Array();
		//Create sub-arrays for paletteColors
		for (var i:Number=1; i<=this.numPalettes; i++){
			this.paletteColors[i] = new Array();
		}
		this._iterator = 0;
		//Store colors now
		this.paletteColors[1] = new Array("AFD8F8", "F6BD0F", "8BBA00", "FF8E46", "008E8E", "D64646", "8E468E", "588526", "B3AA00", "008ED6", "9D080D", "A186BE", "CC6600", "FDC689", "ABA000", "F26D7D", "FFF200", "0054A6", "F7941C", "CC3300", "006600", "663300", "6DCFF6");
		this.paletteColors[2] = new Array("AFD8F8", "F6BD0F", "8BBA00", "FF8E46", "008E8E", "D64646", "8E468E", "588526", "B3AA00", "008ED6", "9D080D", "A186BE", "CC6600", "FDC689", "ABA000", "F26D7D", "FFF200", "0054A6", "F7941C", "CC3300", "006600", "663300", "6DCFF6");
		this.paletteColors[3] = new Array("AFD8F8", "F6BD0F", "8BBA00", "FF8E46", "008E8E", "D64646", "8E468E", "588526", "B3AA00", "008ED6", "9D080D", "A186BE", "CC6600", "FDC689", "ABA000", "F26D7D", "FFF200", "0054A6", "F7941C", "CC3300", "006600", "663300", "6DCFF6");
		this.paletteColors[4] = new Array("AFD8F8", "F6BD0F", "8BBA00", "FF8E46", "008E8E", "D64646", "8E468E", "588526", "B3AA00", "008ED6", "9D080D", "A186BE", "CC6600", "FDC689", "ABA000", "F26D7D", "FFF200", "0054A6", "F7941C", "CC3300", "006600", "663300", "6DCFF6");
		this.paletteColors[5] = new Array("AFD8F8", "F6BD0F", "8BBA00", "FF8E46", "008E8E", "D64646", "8E468E", "588526", "B3AA00", "008ED6", "9D080D", "A186BE", "CC6600", "FDC689", "ABA000", "F26D7D", "FFF200", "0054A6", "F7941C", "CC3300", "006600", "663300", "6DCFF6");
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
}