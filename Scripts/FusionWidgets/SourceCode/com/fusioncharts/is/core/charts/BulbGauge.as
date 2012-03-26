/**
* @class BulbGauge
* @author InfoSoft Global(P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright(C) InfoSoft Global Pvt. Ltd. 2005-2006
* BulbGauge extends the RealTimeGauge class to render the
* functionality of a bulb gauge.
*/
//Import parent class
import com.fusioncharts.is.core.RealTimeGauge;
//Error class
import com.fusioncharts.is.helper.FCError;
//Import Logger Class
import com.fusioncharts.is.helper.Logger;
import com.fusioncharts.is.helper.Utils;
//Style Object
import com.fusioncharts.is.core.StyleObject;
//Delegate
import mx.utils.Delegate;
//Extensions
import com.fusioncharts.is.extensions.ColorExt;
import com.fusioncharts.is.extensions.StringExt;
import com.fusioncharts.is.extensions.MathExt;
import com.fusioncharts.is.extensions.DrawingExt;
//Axis for the chart
import com.fusioncharts.is.axis.GaugeAxis;
//External Interface - to expose methods via JavaScript
import flash.external.ExternalInterface;
class com.fusioncharts.is.core.charts.BulbGauge extends RealTimeGauge {
	//Value of the chart.
	private var value:Number;	
	//Last Color range index which was represted on chart.
	private var lastCRIndex:Number;
	/**
	* Constructor function. We invoke the super class'
	* constructor.
	*/
	function BulbGauge(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Log additional information to debugger
		//We log version from this class, so that if this class version
		//is different, we can log it
		this.log("Version", _version, Logger.LEVEL.INFO);
		this.log("Chart Type", "Real-time Bulb Gauge", Logger.LEVEL.INFO);
		//List Chart Objects and set them in arrObjects array defined in super parent class.
		this.arrObjects = new Array("BACKGROUND", "VALUE", "GAUGE");
		super.setChartObjects();		
		//Initialize last drawn index to 0 (as nothing has been drawn till now)
		this.lastCRIndex = 0;
		//Expose the methods to JavaScript using ExternalInterface		
		if (ExternalInterface.available && this.registerWithJS==true){
			//feedData method
			ExternalInterface.addCallback("feedData", this, feedData);
			//getData method
			ExternalInterface.addCallback("getData", this, getData);						
			//setData method
			ExternalInterface.addCallback("setData", this, setData);
			//stopUpdate method
			ExternalInterface.addCallback("stopUpdate", this, stopUpdate);
			//restartUpdate method
			ExternalInterface.addCallback("restartUpdate", this, restartUpdate);		
		}
	}
	/**
	* render method is the single call method that does the rendering of chart:
	* - Parsing XML
	* - Calculating values and co-ordinates
	* - Visual layout and rendering
	* - Event handling
	*/
	public function render():Void {
		//Parse the XML Data document
		this.parseXML();		
		//Setup axis
		this.setupAxis();
		//Validate the color ranges
		this.validateColorRange();
		//Calculate scale factor
		this.calculateScaleFactor();
		//Set Style defaults
		this.setStyleDefaults();
		//Cache styles that get re-used
		this.cacheStyles();
		//Allot the depths for various charts objects now
		this.allotDepths();
		//Set the container for annotation manager
		this.setupAnnotationMC();
		//Set the container for alert manager
		this.setupAlertManagerMC();
		//Set-up message log
		this.setupMessageLog();	
		//Calculate Points
		this.calculatePoints();			
		//Feed macro values
		this.feedMacros();			
		//Set tool tip parameter
		this.setToolTipParam();
		//Remove application message
		this.removeAppMessage(this.tfAppMsg);
		//Set the context menu - initially
		this.setContextMenu();
		//-----Start Visual Rendering Now------//
		//Draw background
		this.drawBackground();
		//Set click handler
		this.drawClickURLHandler();
		//Load background SWF
		this.loadBgSWF();
		//Update timer
		this.timeElapsed =(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.BACKGROUND):0;
		//Render the annotations below
		this.config.intervals.annotationsBelow = setInterval(Delegate.create(this, renderAnnotationBelow) , this.timeElapsed);								
		//Draw the gauge - background
		this.config.intervals.gauge = setInterval(Delegate.create(this, drawGauge) , this.timeElapsed);		
		//Update timer
		this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.GAUGE):0;		
		//Values textbox
		this.config.intervals.valueTB = setInterval(Delegate.create(this, drawValue) , this.timeElapsed);			
		//Update timer
		this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.VALUE):0;					
		//Render the annotations above the chart
		this.config.intervals.annotationsAbove = setInterval(Delegate.create(this, renderAnnotationAbove) , (this.params.annRenderDelay==undefined || isNaN(Number(this.params.annRenderDelay)))?(this.timeElapsed):(Number(this.params.annRenderDelay)*1000));		
		//Now, that everything has rendered, we can start our cycle for real-time data retrieval.
		this.config.intervals.refreshInterval = setInterval(Delegate.create(this, setRefreshInterval) , this.timeElapsed);
		//Update rendered flag.
		this.config.intervals.renderedFlag = setInterval(Delegate.create(this, updateRenderedFlag) , this.timeElapsed);			
		//Dispatch event that the chart has loaded.
		this.config.intervals.renderedEvent = setInterval(Delegate.create(this, exposeChartRendered) , this.timeElapsed);			
		//Set context menu
		this.config.intervals.contextMenu = setInterval(Delegate.create(this, setContextMenu) , this.timeElapsed);		
	}	
	/**
	* parseXML method parses the XML data, sets defaults and validates
	* the attributes before storing them to data storage objects.
	*/
	private function parseXML():Void {
		//Get the element nodes
		var arrDocElement:Array = this.xmlData.childNodes;
		//Loop variable
		var i:Number;
		var j:Number;
		var k:Number;
		//Look for <graph> element
		for (i=0; i<arrDocElement.length; i++) {
			//If it's a <graph> element, proceed.
			//Do case in-sensitive mathcing by changing to upper case
			if (arrDocElement[i].nodeName.toUpperCase() == "GRAPH" || arrDocElement[i].nodeName.toUpperCase() == "CHART") {
				//Extract attributes of <graph> element
				this.parseAttributes(arrDocElement[i]);
				//Extract common attributes/over-ride chart specific ones
				this.parseCommonAttributes (arrDocElement [i], true);
				//Now, get the child nodes - first level nodes
				//Level 1 nodes can be - CATEGORIES, DATASET, TRENDLINES, STYLES etc.
				var arrLevel1Nodes:Array = arrDocElement[i].childNodes;
				var setNode:XMLNode;
				//Before we iterate through other level 1 nodes, we necessarily need
				//to parse the ANNOTATIONS or customObjects node, as the object IDs of 
				//the annotations would be validated by Style Manager. 
				for (j=0; j<arrLevel1Nodes.length; j++) {
					if (arrLevel1Nodes[j].nodeName.toUpperCase() == "ANNOTATIONS" || arrLevel1Nodes[j].nodeName.toUpperCase() == "CUSTOMOBJECTS") {
						//Parse and store
						this.am.parseXML(arrLevel1Nodes[j]);
					}
				}
				//Iterate through all level 1 nodes.
				for (j=0; j<arrLevel1Nodes.length; j++) {
					if (arrLevel1Nodes[j].nodeName.toUpperCase() == "COLORRANGE") {
						//Call the super function to parse and store color range
						this.parseColorRange(arrLevel1Nodes[j].childNodes);
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "VALUE") {
						//Extract value and store						
						var pValue:Number;
						//Now, get value.
						try {
							var pValue:Number = this.nf.parseValue(arrLevel1Nodes[j].childNodes[0].nodeValue);
						} catch (e:Error) {
							//If the value is not a number, log a data
							this.log("Invalid data", e.message, Logger.LEVEL.ERROR);
							//Set as NaN - so that we can show it as empty data.
							pValue = Number("");
						}
						//Store it
						this.value = pValue;
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "STYLES") {
						//Parse the style nodes to extract style information
						this.styleM.parseXML(arrLevel1Nodes[j].childNodes);
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "ALERTS") {
						//Alerts - check if it has any child nodes
						if (arrLevel1Nodes[j].hasChildNodes()) {
							//Extract alert information
							super.setupAlertManager(arrLevel1Nodes[j]);
						}
					} 
				}
			}
		}
		//Delete all temporary objects used for parsing XML Data document
		delete setNode;
		delete arrDocElement;
		delete arrLevel1Nodes;
	}
	/**
	* parseAttributes method parses the attributes and stores them in
	* chart storage objects.
	* Starting ActionScript 2, the parsing of XML attributes have also
	* become case-sensitive. However, prior versions of FusionCharts
	* supported case-insensitive attributes. So we need to parse all
	* attributes as case-insensitive to maintain backward compatibility.
	* To do so, we first extract all attributes from XML, convert it into
	* lower case and then store it in an array. Later, we extract value from
	* this array.
	* @param	graphElement	XML Node containing the <graph> element
	*							and it's attributes
	*/
	private function parseAttributes(graphElement:XMLNode):Void {
		//Array to store the attributes
		var atts:Array = Utils.getAttributesArray(graphElement);
		//NOW IT'S VERY NECCESARY THAT WHEN WE REFERENCE THIS ARRAY
		//TO GET AN ATTRIBUTE VALUE, WE SHOULD PROVIDE THE ATTRIBUTE
		//NAME IN LOWER CASE. ELSE, UNDEFINED VALUE WOULD SHOW UP.
		//Extract attributes pertinent to this chart
		//Which palette to use?
		this.params.palette = getFN(atts["palette"], 1);
		//If single color them is to be used
		this.params.paletteThemeColor = formatColor(getFV(atts["palettethemecolor"], ""));
		//Setup the color manager
		this.setupColorManager(this.params.palette, this.params.paletteThemeColor);
		//Whether to show real time related context menu items
		this.params.showRTMenuItem = toBoolean(getFN(atts["showrtmenuitem"], 1));
		// ---------- PADDING AND SPACING RELATED ATTRIBUTES ----------- //
		//Chart Margins - Empty space at the 4 sides
		this.params.chartLeftMargin = getFN(atts["chartleftmargin"], 10);
		this.params.chartRightMargin = getFN(atts["chartrightmargin"], 10);
		this.params.chartTopMargin = getFN(atts["charttopmargin"], 10);
		this.params.chartBottomMargin = getFN(atts["chartbottommargin"], 10);
		// --------------------- CONFIGURATION ------------------------- //
		//The upper and lower limits of axis
		this.params.upperLimit = atts["upperlimit"];
		this.params.lowerLimit = atts["lowerlimit"];
		//Whether to set animation for entire chart.
		this.params.animation = toBoolean(getFN(atts["animation"], 1));
		//Whether to set the default chart animation
		this.params.defaultAnimation = toBoolean(getFN(atts["defaultanimation"], 1));
		//Click URL
		this.params.clickURL = getFV(atts["clickurl"], "");
		//Whether to auto-scale itself with respect to previous size
		this.params.autoScale = toBoolean(getFN(atts["autoscale"], 1));
		//Original width and height of chart
		this.params.origW = getFN(atts["origw"], this.width);
		this.params.origH = getFN(atts["origh"], this.height);
		//Delay in rendering annotations that are over the chart
		this.params.annRenderDelay = atts["annrenderdelay"];		
		// ------------------- REAL-TIME CHART RELATED ATTRIBUTES -----------------//
		//Message Logger
		this.params.useMessageLog = toBoolean(getFN(atts["usemessagelog"], 0));
		this.params.messageLogWPercent = getFN(atts["messagelogwpercent"], 80);
		this.params.messageLogHPercent = getFN(atts["messageloghpercent"], 70);
		this.params.messageLogShowTitle = toBoolean(getFN(atts["messagelogshowtitle"], 1));
		this.params.messageLogTitle = getFV(atts["messagelogtitle"], "Message Log");
		this.params.messageLogColor = getFV(atts["messagelogcolor"], this.colorM.get2DMsgLogColor());
		this.params.messageGoesToLog = toBoolean(getFN(atts["messagegoestolog"], 1));
		this.params.messageGoesToJS = toBoolean(getFN(atts["messagegoestojs"], 0));
		this.params.messageJSHandler = getFV(atts["messagejshandler"], "alert");
		this.params.messagePassAllToJS = toBoolean(getFN(atts["messagepassalltojs"], 0));
		//Whether to show the value below the chart
		this.params.showValue = toBoolean(getFN(atts["showvalue"], atts["showrealtimevalue"], 1));
		//Whether to use color name as value
		this.params.useColorNameAsValue = toBoolean(getFN(atts["usecolornameasvalue"], 0));
		//Whether to show values inside gauge
		this.params.placeValuesInside = toBoolean(getFN(atts["placevaluesinside"], 0));
		//Padding between the value and end of gauge
		this.params.valuePadding = getFN(atts["valuepadding"], (this.params.placeValuesInside)?0:4);
		//Whether to pull feeds from
		this.params.dataStreamURL = unescape(getFV(atts["datastreamurl"], ""));
		//Check whether dataStreamURL contains ?
		this.params.streamURLQMarkPresent = (this.params.dataStreamURL.indexOf("?") != -1);
		//In what time to update the chart
		this.params.refreshInterval = getFN(atts["refreshinterval"], -1);
		//Data stamp for first data.
		this.params.dataStamp = getFV(atts["datastamp"], "");
		// ------------------------- COSMETICS -----------------------------//
		//Background properties - Gradient
		this.params.bgColor = getFV(atts["bgcolor"], this.colorM.get2DBgColor());
		this.params.bgAlpha = getFV(atts["bgalpha"], this.colorM.get2DBgAlpha());
		this.params.bgRatio = getFV(atts["bgratio"], this.colorM.get2DBgRatio());
		this.params.bgAngle = getFV(atts["bgangle"], this.colorM.get2DBgAngle());
		//Border Properties of chart
		this.params.showBorder = toBoolean(getFN(atts["showborder"], 1));
		this.params.borderColor = formatColor(getFV(atts["bordercolor"], this.colorM.get2DBorderColor()));
		this.params.borderThickness = getFN(atts["borderthickness"], 1);
		this.params.borderAlpha = getFN(atts["borderalpha"], this.colorM.get2DBorderAlpha());
		//Font Properties
		this.params.baseFont = getFV(atts["basefont"], "Verdana");
		this.params.baseFontSize = getFN(atts["basefontsize"], 10);
		this.params.baseFontColor = formatColor(getFV(atts["basefontcolor"], this.colorM.get2DBaseFontColor()));
		//Tool Tip - Show/Hide, Background Color, Border Color, Separator Character
		this.params.showToolTip = toBoolean(getFN(atts ["showtooltip"] , atts ["showhovercap"] , 1));
		this.params.toolTipBgColor = formatColor(getFV(atts ["tooltipbgcolor"] , atts ["hovercapbgcolor"] , atts ["hovercapbg"] , this.colorM.get2DToolTipBgColor()));
		this.params.toolTipBorderColor = formatColor(getFV(atts ["tooltipbordercolor"] , atts ["hovercapbordercolor"] , atts ["hovercapborder"] , this.colorM.get2DToolTipBorderColor()));
		//-------------------------- Gauge specific properties --------------------------//		
		//Gauge Border properties  
		this.params.showGaugeBorder = toBoolean(getFN(atts["showgaugeborder"], 0));
		this.params.gaugeBorderColor = formatColor(getFV(atts["gaugebordercolor"], "{dark-30}"));
		this.params.gaugeBorderThickness = getFN(atts["gaugeborderthickness"], (this.params.showGaugeBorder)?1:0);
		this.params.gaugeBorderAlpha = getFN(atts["gaugeborderalpha"], 90);
		//Gauge fill alpha
		this.params.gaugeFillAlpha = getFN(atts["gaugefillalpha"], atts["bulbalpha"], 100);
		//Gauge origin X, Y
		this.params.gaugeOriginX = getFN(atts["gaugeoriginx"], atts["bulboriginx"], -1);
		this.params.gaugeOriginY = getFN(atts["gaugeoriginy"], atts["bulboriginy"], -1);
		this.params.gaugeRadius = getFN(atts["gaugeradius"], atts["bulbradius"], -1);		
		//Whether 3D?
		this.params.is3D = getFN(atts["is3d"],1);		
		// ------------------------- NUMBER FORMATTING ---------------------------- //
		//Option whether the format the number(using Commas)
		this.params.formatNumber = toBoolean(getFN(atts["formatnumber"], 1));
		//Option to format number scale
		this.params.formatNumberScale = toBoolean(getFN(atts["formatnumberscale"], 0));
		//Number Scales
		this.params.defaultNumberScale = getFV(atts["defaultnumberscale"], "");
		this.params.numberScaleUnit = getFV(atts["numberscaleunit"], "K,M");
		this.params.numberScaleValue = getFV(atts["numberscalevalue"], "1000,1000");
		//Recursive scale properties
		this.params.scaleRecursively = toBoolean(getFN(atts["scalerecursively"], 0));
		//By default we show all - so set as -1
		this.params.maxScaleRecursion = getFN(atts["maxscalerecursion"], -1);
		//Setting space as default scale separator.
		this.params.scaleSeparator = getFV(atts["scaleseparator"], " ");
		//Number prefix and suffix
		this.params.numberPrefix = getFV(atts["numberprefix"], "");
		this.params.numberSuffix = getFV(atts["numbersuffix"], "");
		//Decimal Separator Character
		this.params.decimalSeparator = getFV(atts["decimalseparator"], ".");
		//Thousand Separator Character
		this.params.thousandSeparator = getFV(atts["thousandseparator"], ",");
		//Input decimal separator and thousand separator. In some european countries,
		//commas are used as decimal separators and dots as thousand separators. In XML,
		//if the user specifies such values, it will give a error while converting to
		//number. So, we accept the input decimal and thousand separator from user, so that
		//we can covert it accordingly into the required format.
		this.params.inDecimalSeparator = getFV(atts["indecimalseparator"], "");
		this.params.inThousandSeparator = getFV(atts["inthousandseparator"], "");
		//Decimal Precision(number of decimal places to be rounded to)
		this.params.decimals = getFV(atts["decimals"], atts["decimalprecision"], 2);
		//Force Decimal Padding
		this.params.forceDecimals = toBoolean(getFN(atts["forcedecimals"], 0));
		//Set up number formatting 
		this.setupNumberFormatting(this.params.numberPrefix, this.params.numberSuffix, this.params.scaleRecursively, this.params.maxScaleRecursion, this.params.scaleSeparator, this.params.defaultNumberScale, this.params.numberScaleValue, this.params.numberScaleUnit, this.params.decimalSeparator, this.params.thousandSeparator, this.params.inDecimalSeparator, this.params.inThousandSeparator);		
	}
	/**
	* setupAxis method sets the axis for the chart.
	* It gets the minimum and maximum value specified in data and
	* based on that it calls super.getAxisLimits();
	*/
	private function setupAxis():Void {
		this.pAxis = new GaugeAxis(this.params.lowerLimit, this.params.upperLimit, false, !this.params.setAdaptiveMin, this.params.majorTMNumber, this.params.minorTMNumber, this.params.adjustTM, this.params.tickValueStep, this.nf, this.params.formatNumber, this.params.formatNumberScale, this.params.tickValueDecimals, this.params.forceTickValueDecimals);
		this.pAxis.calculateLimits(this.value,this.value);
	}	
	/**
	* setStyleDefaults method sets the default values for styles or
	* extracts information from the attributes and stores them into
	* style objects.
	*/
	private function setStyleDefaults():Void {		
		//-----------------------------------------------------------------//
		//Default font object for DataValues
		//-----------------------------------------------------------------//
		var dataValuesFont = new StyleObject ();
		dataValuesFont.name = "_SdDataValuesFont";
		dataValuesFont.align = "center";
		dataValuesFont.valign = "middle";
		dataValuesFont.bold = "1";
		dataValuesFont.font = this.params.baseFont;
		dataValuesFont.size = this.params.baseFontSize;
		dataValuesFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.VALUE, dataValuesFont, this.styleM.TYPE.FONT, null);
		delete dataValuesFont;
		//-----------------------------------------------------------------//
		//Default Animation object for gauge (if required)
		//-----------------------------------------------------------------//
		if (this.params.defaultAnimation){
			//Y-scale animation for gauge
			var gaugeYSAnim = new StyleObject ();
			gaugeYSAnim.name = "_SdGaugeYScaleAnim";
			gaugeYSAnim.param = "_yscale";
			gaugeYSAnim.easing = "regular";
			gaugeYSAnim.wait = 0;
			gaugeYSAnim.start = 0;
			gaugeYSAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.GAUGE, gaugeYSAnim, this.styleM.TYPE.ANIMATION, "_yscale");
			delete gaugeYSAnim;			
			
			//Animation for gauge
			var gaugeXSAnim = new StyleObject ();
			gaugeXSAnim.name = "_SdGaugeXScaleAnim";
			gaugeXSAnim.param = "_xscale";
			gaugeXSAnim.easing = "regular";
			gaugeXSAnim.wait = 0;
			gaugeXSAnim.start = 0;
			gaugeXSAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.GAUGE, gaugeXSAnim, this.styleM.TYPE.ANIMATION, "_xscale");
			delete gaugeXSAnim;						
		}
	}	
	/**
	* allotDepths method allots the depths for various chart objects
	* to be rendered. We do this before hand, so that we can later just
	* go on rendering chart objects, without swapping.
	*/
	private function allotDepths():Void{
		//Background
		this.dm.reserveDepths ("BACKGROUND", 1);
		//Click URL Handler
		this.dm.reserveDepths ("CLICKURLHANDLER", 1);
		//Background SWF
		this.dm.reserveDepths ("BGSWF", 1);
		//Annotations below the chart
		this.dm.reserveDepths ("ANNOTATIONBELOW", 1);
		//Movie clip holder for Alert Manager
		this.dm.reserveDepths ("ALERTMANAGER", 1);		
		//Gauge Background
		this.dm.reserveDepths ("GAUGE", 1);
		//Value text box
		this.dm.reserveDepths ("VALUE", 1);		
		//Annotations above the chart
		this.dm.reserveDepths ("ANNOTATIONABOVE", 1);
	}
	/**
	 * cacheStyles method caches all the styles that will be used by real-time
	 * objects. This helps to avoid generating them at run time.
	*/
	private function cacheStyles(){
		//Data values
		this.styleCache.dataValue = this.styleM.getTextStyle(this.objects.VALUE);
		// ---------- CACHE ALL FILTERS NOW ----------------//
		//Gauge filters
		this.styleCache.gaugeFilters = this.styleM.getFilterStyles(this.objects.GAUGE);
		//Data value filters
		this.styleCache.dataValueFilters = this.styleM.getFilterStyles(this.objects.VALUE);
		
	}
	/**
	 * calculatePoints method calculates all the points and angles for plotting the gauge.
	*/
	private function calculatePoints():Void{		
		//In this function, we calculate the best fit co-ordinates for the gauge.
		var i:Number, j:Number;
		//If value is NaN, assume it to be min
		if (isNaN(this.value)){
			this.value = this.pAxis.getMin();
		}
		//If the value is beyond range, restrict it
		if (this.value>this.pAxis.getMax()){
			this.value = this.pAxis.getMax();
		}
		if (this.value<this.pAxis.getMin()){
			this.value = this.pAxis.getMin();
		}
		
		//------------ VALUE TEXT HEIGHT ---------------//
		var valueHeight:Number = 0;				
		//Now, if value is to be shown (and below the gauge)
		if (this.params.showValue && !this.params.placeValuesInside){			
			var valueObj:Object;
			var valueStyle:Object = this.styleM.getTextStyle(this.objects.VALUE);		
			//Also add the height of value - using dummy text
			valueObj = createText (true, "123456789%$#@AWXGagypq", this.tfTestMC, 1, testTFX, testTFY, 0, valueStyle, false, 0, 0);
			valueHeight = this.params.valuePadding + valueObj.height;
		}		
		//Calculate the radius and origin for gauge.
		var gaugeOriginX:Number, gaugeOriginY:Number, gaugeRadius:Number;
		//Calculate radius based on margins and whether we've to show value outside
		gaugeRadius = (Math.min(this.width - (this.params.chartLeftMargin + this.params.chartRightMargin), this.height -(this.params.chartTopMargin + this.params.chartBottomMargin + valueHeight)))/2;
		//Calculate our default origin X & Y
		gaugeOriginX = this.params.chartLeftMargin + (this.width - (this.params.chartLeftMargin + this.params.chartRightMargin))/2;
		gaugeOriginY = this.params.chartTopMargin + (this.height - (this.params.chartTopMargin + this.params.chartBottomMargin + valueHeight))/2;
		//Over-ride (if user has not specified)
		if (this.params.gaugeRadius==-1){
			this.params.gaugeRadius = gaugeRadius;
		}else{
			//Apply scaling factor
			this.params.gaugeRadius = this.params.gaugeRadius * this.scaleFactor;
		}
		if (this.params.gaugeOriginX ==-1){
			this.params.gaugeOriginX = gaugeOriginX;
		}else{
			//Apply scaling factor
			this.params.gaugeOriginX = this.params.gaugeOriginX * this.scaleFactor;
		}
		if (this.params.gaugeOriginY ==-1){
			this.params.gaugeOriginY = gaugeOriginY;
		}else{
			//Apply scaling factor
			this.params.gaugeOriginY = this.params.gaugeOriginY * this.scaleFactor;
		}
		//----------------------------------------------------------------------------//
		//Now, create the gauge element accordingly.
		this.elements.gauge = this.returnDataAsElement(this.params.gaugeOriginX, this.params.gaugeOriginY, this.params.gaugeRadius, this.params.gaugeRadius);		
	}
	/**
	* feedMacros method feeds macros and their respective values
	* to the macro instance. This method is to be called after
	* calculatePoints, as we set the canvas and chart co-ordinates
	* in this method, which is known to us only after calculatePoints.
	*	@return	Nothing
	*/
	private function feedMacros ():Void {
		//Feed macros one by one
		//Chart dimension macros
		this.macro.addMacro ("$chartStartX", this.x);
		this.macro.addMacro ("$chartStartY", this.y);
		this.macro.addMacro ("$chartWidth", this.width);
		this.macro.addMacro ("$chartHeight", this.height);
		this.macro.addMacro ("$chartEndX", this.width);
		this.macro.addMacro ("$chartEndY", this.height);
		this.macro.addMacro ("$chartCenterX", this.width / 2);
		this.macro.addMacro ("$chartCenterY", this.height / 2);
		//Gauge angle related macros		
		this.macro.addMacro ("$gaugeCenterX", this.elements.gauge.x);
		this.macro.addMacro ("$gaugeCenterY", this.elements.gauge.y);		
		this.macro.addMacro ("$gaugeRadius", this.elements.gauge.w);
	}
	// -------------------- Visual Rendering Methods ---------------------------//	
	/**
	 * drawGauge method draws the actual gauge.
	*/
	private function drawGauge(firstTime:Boolean){		
		//Get a value for firstTime
		firstTime = toBoolean(getFN(firstTime,1));
		//Get the index in which the gauge color falls
		var index:Number = this.getValueCRIndex();
		//Store the index
		lastCRIndex = index;
		//Create a movie clip for this
		var gaugeMC:MovieClip = this.cMC.createEmptyMovieClip("Gauge",this.dm.getDepth("GAUGE"));
		//Set it's start position
		gaugeMC._x = this.elements.gauge.x;
		gaugeMC._y = this.elements.gauge.y;		
		//Set border propeties
		var borderColor:Number;
		//If we've to show gauge border at all
		if (this.params.showGaugeBorder){
			//Now, if the border color contains color formula, we need to parse it.
			if (this.params.gaugeBorderColor.indexOf("{")==-1){
				//It doesn't contain. So take simple gauge border color
				borderColor = parseInt(this.params.gaugeBorderColor,16);
			} else {
				//It contains. So parse and take the first color.
				var arrBorderColor:Array = ColorExt.parseColorMix(this.colorR[index].color, this.params.gaugeBorderColor);
				borderColor = arrBorderColor[0];
			}
			//Set linestyle
			gaugeMC.lineStyle(this.params.gaugeBorderThickness, borderColor, this.params.gaugeBorderAlpha);
		}else{
			//Nor border needed.
			borderColor = 0;
			gaugeMC.lineStyle();
		}
		//Set the fill based on whether we've to create 2D or 3D effect?
		if (this.params.is3D) {
			//Create 3D Bulb
			gaugeMC.beginGradientFill("radial", [ColorExt.getLightColor(this.colorR[index].color, 0.65), parseInt(this.colorR[index].color, 16), ColorExt.getDarkColor(this.colorR[index].color, 0.65)], [50, 50, 100], [10, 100, 255], {matrixType:"box", x:-(1.5*this.elements.gauge.w), y:-(this.elements.gauge.w*1.5), w:this.elements.gauge.w*2.5, h:this.elements.gauge.w*2.5, r:(1/180)*Math.PI});
		} else {
			//Create 2D Bulb
			gaugeMC.beginFill(parseInt(this.colorR[index].color, 16), 100);
		}
		//Draw the circle
		DrawingExt.drawCircle(gaugeMC, 0, 0, this.elements.gauge.w, this.elements.gauge.h, 0, 360);
		//End the fill.
		gaugeMC.endFill();
		//Set alpha
		gaugeMC._alpha = this.params.gaugeFillAlpha;
		//Apply animation and filter effects
		if (firstTime && this.params.animation){
			this.styleM.applyAnimation (gaugeMC, this.objects.GAUGE, this.macro, gaugeMC._x, gaugeMC._y, this.params.gaugeFillAlpha, 100, 100, null);
		}
		//Apply filters
		gaugeMC.filters = this.styleCache.gaugeFilters;
		//Clear Interval
		clearInterval(this.config.intervals.gauge);
	}
	/**
	 * getValueCRIndex method returns the index of the color range in which the value
	 * falls.
	*/
	private function getValueCRIndex():Number{
		//Assuming max color range index, as we check for < and not <= for upper range
		var index:Number = this.numCR;
		var i:Number;
		//Iterate through each color range to find the value's position
		for (i=1; i<=this.numCR; i++){
			if (this.colorR[i].minValue<=this.value && this.value<this.colorR[i].maxValue){
				index = i;
				break;
			}
		}
		//Return index
		return index;
	}
	/**
	* drawValue method draws the value textbox.
	*/
	private function drawValue(firstTime:Boolean):Void{
		//Get a value for firstTime
		firstTime = toBoolean(getFN(firstTime,1));
		//If the value is to be shown
		if (this.params.showValue){
			var valueObj:Object;
			var valueY:Number;
			var depth:Number = this.dm.getDepth("VALUE");
			var valueStyleObj:Object = this.styleCache.dataValue;		
			//Which value to show
			var valueStr:Number = (this.params.useColorNameAsValue)?(this.colorR[this.getValueCRIndex()].label):(this.nf.formatNumber(this.value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals));
			valueStyleObj.align = "center";
			//Set alignment of value based on position - i.e., if values are to be placed inside
			if (this.params.placeValuesInside){							
				valueStyleObj.vAlign = "middle";
				valueY = this.elements.gauge.y;
			}else{
				valueStyleObj.vAlign = "bottom";
				valueY = this.elements.gauge.toY + this.params.valuePadding;
			}
			valueObj = createText (false,valueStr , this.cMC, depth, this.elements.gauge.x, valueY, 0, valueStyleObj, false, 0, 0);
			//Apply filter
			valueObj.tf.filters = this.styleCache.dataValueFilters;
			//Apply animation
			if (firstTime && this.params.animation){
				this.styleM.applyAnimation(valueObj.tf, this.objects.VALUE, this.macro, valueObj.tf._x, valueObj.tf._y, 100, null, null, null);
			}
		}
		//Clear interval
		if (firstTime){
			clearInterval (this.config.intervals.valueTB);
		}
	}	
	/**
	 * updateChartData method is called to change chart's value. This method
	 * is either called from JavaScript or parseDataFromLV function (real-time update method).
	 *	@param	value	New value for the chart..
	*/
	private function updateChartData(value:Number):Void{
		//Now, we proceed only if the new value is within the range of chart
		if (value>=this.pAxis.getMin() && value<=this.pAxis.getMax()){
			//We need to update chart only if value is different from existing id
			if (this.value!=value){
				//Store pointers value			
				this.value = value;
				//Now, feed it to alert manager (if required)
				if (this.useAlerts){
					this.alertM.check(value);
				}
				//Update the drawing only if last index is different from current one
				if (this.lastCRIndex!=this.getValueCRIndex()){
					this.drawGauge(false);
				}
				//Update display value
				if (this.params.showValue){
					this.drawValue(false);
				}
			}
		}else{
			this.log("Value of range","The given value " + String(value) + " is out of chart axis range, and as such is not being plotted",Logger.LEVEL.ERROR);
		}
	}
	// ------------ REAL TIME UPDATE/REFRESH HANDLERS ----------//	
	/**
	 * parseDataFromLV method is called when the server has responded with data 
	 * feed and the chart has picked it up properly. Here, we parse the same and
	 * store it in our data structures.
	*/
	private function parseDataFromLV():Void{			
		//Update flag that we're done with loading - so that next loadvars can stream
		//in the background, meanwhile.
		this.inLoadingProcess = false;
		//Loop variables
		var i:Number, j:Number;
		//Get case insensitive representation of all data received in Loadvars
		var dt:Array = Utils.getParamsArray(this.lv);
		//------------ GET VALUE --------------------//
		//Final value string container
		var strVal:String;
		//Flag to store whether we've been provided data at all
		var valueProvided:Boolean = false;
		//Now, we check for &value.
		if (dt["value"]!=undefined){
			//If provided, we store value string and update flag
			strVal = dt["value"];
			valueProvided = true;
		}
		//--------------- END GET VALUE ----------------//	
		//Send the data to Message Handler (if required)
		//Message to data logger goes irrespective of whether the user has defined
		//a pointer value.
		if (this.params.useMessageLog){
			this.msgLgr.feedQS(this.lv);
		}		
		//Now, if we've been provided with a value, only then do we proceed		
		//This allows the user to skip chart update by not defining
		//&value in the real time feed. 
		if (valueProvided){
			// -----  Extract data from Loadvars and store in local vars ----- //
			//Whether to stop update
			var _stopUpdate:Boolean = toBoolean(getFN(dt["stopupdate"],0));
			//If we've to stop update, do so,
			if (_stopUpdate){
				this.stopUpdate();
				//Clear up existing allocations
				delete dt;
				//Exit
				return;
			}			
			//Update dataStamp
			this.params.dataStamp = getFV(dt["datastamp"],"");
			// --------------- Parse into local containers ------------------- //		
			var setValue:Number;
			var newValue:Number;			
			try{
				setValue = this.nf.parseValue(dt["value"]);
			} catch (e:Error){
				//If the value is not a number, log a data
				this.log("Invalid data","Non-numeric data " + dt["value"] + " received in data stream.", Logger.LEVEL.ERROR);
				//Set as NaN - so that we can show it as empty data.
				setValue = Number("");
			}finally{
				//Store the updated value in array.
				newValue = setValue;					
			}
			// --------- Update chart now ---------//			
			var chartChanged:Boolean = false;
			//Update the chart based on this value.
			if (!isNaN(newValue)){
				//If the value has changed at all
				if (this.value!=newValue){
					this.updateChartData(newValue);
					//Update flag
					chartChanged = true;
				}
			}
			//Convey event to JavaScript that we've received new data.
			if (chartChanged && ExternalInterface.available && this.registerWithJS==true){
				ExternalInterface.call("FC_ChartUpdated", this.DOMId);
			}
			//Delete all values from lv - so that it doesn't cache the same from previous call. 
			this.deleteLoadVarsCache();			
		}else{
			//If the control comes here, it means that the chart has not been
			//provided with a real-time update containing value. So, log it
			this.log("No data received","The chart couldn't find any data values in the real-time feed.",Logger.LEVEL.INFO);
		}
	}
	/**
	 * getData method returns the data of the chart.
	*/
	public function getData():Number{
		//Return the value
		return this.value;
	}
	/**
	 * setData method sets the value for the chart from External
	 * interface or external flash movies.
	 *	@param	value	New value for the chart
	*/
	public function setData(value:Number):Void{
		//Update the chart with new value
		this.updateChartData(value);
	}	
	/**
	* reInit method re-initializes the chart. This method is basically called
	* when the user changes chart data through JavaScript. In that case, we need
	* to re-initialize the chart, set new XML data and again render.
	*/
	public function reInit():Void {
		//Invoke super class's reInit
		super.reInit();	
		this.lastCRIndex = 0;
		delete this.value;
	}
	/**
	* remove method removes the chart by clearing the chart movie clip
	* and removing any listeners.
	*/
	public function remove():Void {
		//Invoke super function
		super.remove();
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
		strData = strQ + ((this.params.exportDataFormattedVal==true)?(this.nf.formatNumber(this.value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals)):(this.value)) + strQ;
		return strData;
	}
}
