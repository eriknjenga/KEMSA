/**
* @class CylinderGauge
* @author InfoSoft Global(P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright(C) InfoSoft Global Pvt. Ltd. 2005-2006
* CylinderGauge extends the RealTimeGauge class to render the
* functionality of a vertical cylinder gauge.
*/
//Import parent class
import com.fusioncharts.is.core.RealTimeGauge;
//Cylinder chart object
import com.fusioncharts.is.core.chartobjects.Cylinder;
//Error class
import com.fusioncharts.is.helper.FCError;
//Import Logger Class
import com.fusioncharts.is.helper.Logger;
import com.fusioncharts.is.helper.Utils;
//Style Object
import com.fusioncharts.is.core.StyleObject;
//Delegate
import mx.utils.Delegate;
//Axis for the chart
import com.fusioncharts.is.axis.GaugeAxis;
//Extensions
import com.fusioncharts.is.extensions.ColorExt;
import com.fusioncharts.is.extensions.StringExt;
import com.fusioncharts.is.extensions.MathExt;
import com.fusioncharts.is.extensions.DrawingExt;
//Tween for animating fill
import mx.transitions.Tween;
import mx.transitions.easing.*;
//External Interface - to expose methods via JavaScript
import flash.external.ExternalInterface;
class com.fusioncharts.is.core.charts.CylinderGauge extends RealTimeGauge {
	//Value of the chart.
	private var value:Number;
	//Cylinder object;
	var cyl:Cylinder;
	/**
	* Constructor function. We invoke the super class'
	* constructor.
	*/
	function CylinderGauge(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Log additional information to debugger
		//We log version from this class, so that if this class version
		//is different, we can log it
		this.log("Version", _version, Logger.LEVEL.INFO);
		this.log("Chart Type", "Real-time Cylinder", Logger.LEVEL.INFO);
		//List Chart Objects and set them in arrObjects array defined in super parent class.
		this.arrObjects = new Array("BACKGROUND", "TICKMARKS", "TICKVALUES", "LIMITVALUES", "VALUE", "GAUGE");
		super.setChartObjects();		
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
		//Setup the axis
		this.setupAxis();
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
		//Calculate gauge points
		this.calculateGaugePoints();			
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
		//Draw the gauge - cylinder
		this.config.intervals.gauge = setInterval(Delegate.create(this, drawGauge) , this.timeElapsed);		
		//Update timer
		this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.GAUGE):0;		
		//Draw tick marks
		this.config.intervals.tickMarks = setInterval(Delegate.create(this, drawTicks) , this.timeElapsed);
		//Update timer
		this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.LIMITVALUES, this.objects.TICKMARKS, this.objects.TICKVALUES):0;				
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
		//Set context menu finally
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
					if (arrLevel1Nodes[j].nodeName.toUpperCase() == "VALUE") {
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
		//Adaptive yMin - if set to true, the min will be based on the values
		//provided. It won't be set to 0 in case of all positive values
		this.params.setAdaptiveMin = toBoolean(getFN(atts["setadaptivemin"], 0));
		//The upper and lower limits of y and x axis
		this.params.upperLimit = atts["upperlimit"];
		this.params.lowerLimit = atts["lowerlimit"];
		//Display values for upper and lower limit
		this.params.upperLimitDisplay = atts["upperlimitdisplay"];
		this.params.lowerLimitDisplay = atts["lowerlimitdisplay"];
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
		//---------- PLACEMENT OF VARIOUS OBJECTS W.R.T GAUGE ------------//
		//Whether to show ticks on the left of gauge or right
		this.params.ticksOnRight = toBoolean(getFN(atts["ticksonright"], 1));
		//----------------------- TICK PROPERTIES -----------------------------//
		//Tick marks and related properties		
		this.params.showTickMarks = toBoolean(getFN(atts["showtickmarks"], 1));
		this.params.showTickValues = toBoolean(getFN(atts["showtickvalues"], this.params.showTickMarks));
		this.params.showLimits = toBoolean(getFN(atts["showlimits"], this.params.showTickValues));		
		//Whether to automatically adjust TM
		this.params.adjustTM = toBoolean(getFN(atts["adjusttm"], 1));
		//Tick properties
		this.params.majorTMNumber = getFN(atts["majortmnumber"], -1);
		this.params.majorTMColor = formatColor(getFV(atts["majortmcolor"], this.colorM.getTickColor()));
		this.params.majorTMAlpha = getFN(atts["majortmalpha"], 100);
		this.params.majorTMHeight = getFN(atts["majortmheight"], atts["majortmwidth"], 6);
		this.params.majorTMThickness = getFN(atts["majortmthickness"], 1);
		this.params.minorTMNumber = getFN(atts["minortmnumber"], 4);
		this.params.minorTMColor = formatColor(getFV(atts["minortmcolor"], this.params.majorTMColor));
		this.params.minorTMAlpha = getFN(atts["minortmalpha"], this.params.majorTMAlpha);
		this.params.minorTMHeight = getFN(atts["minortmheight"], atts["minortmwidth"], Math.round(this.params.majorTMHeight/2));
		this.params.minorTMThickness = getFN(atts["minortmthickness"], 1);
		//Padding between tick mark start position and gauge
		this.params.tickMarkDistance = getFN(atts["tickmarkdistance"], atts["tickmarkgap"], 1);		
		//Tick value distance
		this.params.tickValueDistance = getFN(atts["tickvaluedistance"], atts["displayvaluedistance"], 2);
		//Tick value step
		this.params.tickValueStep = int(getFN(atts["tickvaluestep"], atts["tickvaluesstep"], 1));
		//Cannot be less than 1
		this.params.tickValueStep = (this.params.tickValueStep<1) ? 1 : this.params.tickValueStep;
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
		//Padding between the tick mark values
		this.params.valuePadding = getFN(atts["valuepadding"], 4);
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
		this.params.cylOriginX = atts["cyloriginx"];
		this.params.cylOriginY = atts["cyloriginy"];
		this.params.cylRadius = atts["cylradius"];
		this.params.cylHeight = atts["cylheight"];
		this.params.cylYScale = getFN(atts["cylyscale"],30);
		//Y-Scale cannot be more than 50 or less than 0
		if (this.params.cylYScale>50 || this.params.cylYScale<0){
			//Set to 30
			this.params.cylYScale = 30;
		}
		//Put in range 0-1
		this.params.cylYScale = this.params.cylYScale/100;
		
		//Cylinder fill color
		this.params.cylFillColor = formatColor(getFV(atts["gaugefillcolor"], atts["cylfillcolor"], this.colorM.getCylFillColor()));
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
		//y-Axis values decimals
		this.params.tickValueDecimals = getFN(atts["tickvaluedecimals"], atts["tickvaluesdecimals"], atts["tickmarkdecimalprecision"], this.params.decimals);
		//Force Decimal Padding
		this.params.forceDecimals = toBoolean(getFN(atts["forcedecimals"], 0));
		this.params.forceTickValueDecimals = toBoolean(getFN(atts["forcetickvaluedecimals"], Utils.fromBoolean(this.params.forceDecimals)));
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
		//Calcuate tick marks - based on the initial data.
		this.pAxis.calculateTicks();
		//Store copy of tick marks in local array
		this.majorTM = this.pAxis.getMajorTM();		
		this.minorTM = this.pAxis.getMinorTM();		
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
		//Default font object for LimitValues
		//-----------------------------------------------------------------//
		var limitValuesFont = new StyleObject ();
		limitValuesFont.name = "_SdLimitValuesFont";
		limitValuesFont.align = "center";
		limitValuesFont.valign = "middle";
		limitValuesFont.font = this.params.baseFont;
		limitValuesFont.size = this.params.baseFontSize;
		limitValuesFont.color = this.params.baseFontColor;
		//limitValuesFont.bold = "1";
		//Over-ride
		this.styleM.overrideStyle (this.objects.LIMITVALUES, limitValuesFont, this.styleM.TYPE.FONT, null);
		delete limitValuesFont;
		//-----------------------------------------------------------------//
		//Default font object for TickValues
		//-----------------------------------------------------------------//
		var tickValuesFont = new StyleObject ();
		tickValuesFont.name = "_SdTickValuesFont";
		tickValuesFont.align = "center";
		tickValuesFont.valign = "middle";
		tickValuesFont.font = this.params.baseFont;
		tickValuesFont.size = this.params.baseFontSize;
		tickValuesFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.TICKVALUES, tickValuesFont, this.styleM.TYPE.FONT, null);
		delete tickValuesFont;		
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
		//Cylinder
		this.dm.reserveDepths ("GAUGE", 1);		
		//Tick Marks
		this.dm.reserveDepths ("TICKMARKS", 1);		
		//Tick values
		this.dm.reserveDepths ("TICKVALUES", this.majorTM.length+1);
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
		//Data value filters
		this.styleCache.dataValueFilters = this.styleM.getFilterStyles(this.objects.VALUE);
	}
	/**
	 * calculateGaugePoints method calculates the best fit co-ordinates for the gauge
	*/
	private function calculateGaugePoints():Void{
		//In this function, we calculate the best fit co-ordinates for the gauge.
		var i:Number, j:Number;
		var calcHolder:Number;		
		//In cylinder gauge, we can have the tick marks/values on the left or right of gauge
		//So, first accomodate that
		//----------TICK MARKS & VALUES------------//
		var tickLeftWidth:Number = 0
		var tickRightWidth:Number = 0;
		//Local containers
		var tickMarkWidth:Number = 0;
		var tickValueWidth:Number = 0;
		var tickValueObj:Object;
		var tickValue:String;
		var tickFontStyle:Object = this.styleM.getTextStyle(this.objects.TICKVALUES);
		var limitFontStyle:Object = this.styleM.getTextStyle(this.objects.LIMITVALUES);
		//First get the height for tick values if it's to be shown and if to be shown outside
		if (this.params.showTickValues){			
			for (i=0; i<this.majorTM.length; i++){
				//Get tick value
				tickValue = this.majorTM[i].displayValue;
				//Get lower/upper limit display				
				if (i==0){
					tickValue = getFV(this.params.lowerLimitDisplay, this.majorTM[i].displayValue);
				}else if (i==this.majorTM.length-1){
					tickValue = getFV(this.params.upperLimitDisplay, this.majorTM[i].displayValue);
				}
				//If it's the limit values, we check and render
				if (((i==0 || i==this.majorTM.length-1) && this.params.showLimits) || (i>0 && i<this.majorTM.length-1 && this.majorTM[i].showValue)){
					tickValueObj = createText (true, tickValue, this.tfTestMC, 1, testTFX, testTFY, 0, ((i==0 || i==this.majorTM.length-1)?limitFontStyle:tickFontStyle), false, 0, 0);
					tickValueWidth = Math.max(tickValueWidth, tickValueObj.width);
				}
			}
			//Add the padding
			tickValueWidth = tickValueWidth + this.params.tickValueDistance;
		}
		//Now, calculate the tick marks height
		if (this.params.showTickMarks){			
			tickMarkWidth = Math.max(this.params.majorTMHeight, this.params.minorTMHeight) + this.params.tickMarkDistance;
		}
		//Now, based on where we've to position the ticks, allot the space
		if (this.params.ticksOnRight){
			tickRightWidth = tickMarkWidth + tickValueWidth;
		}else{
			tickLeftWidth = tickMarkWidth + tickValueWidth;
		}		
		//------------ VALUE TEXT HEIGHT ---------------//
		var valueHeight:Number = 0;		
		var valueObj:Object;
		var valueStyle:Object = this.styleM.getTextStyle(this.objects.VALUE);		
		calcHolder = 0;
		//Now, if value is to be shown
		if (this.params.showValue){			
			calcHolder = this.params.valuePadding;
			//Also add the height of value - using dummy text
			valueObj = createText (true, "123456789%$#@AWXGagypq", this.tfTestMC, 1, testTFX, testTFY, 0, valueStyle, false, 0, 0);
			calcHolder = calcHolder + valueObj.height;
		}
		valueHeight = calcHolder;
		//----------------------------------------------------------------------------//
		//We finally have the maximum space to be alloted
		var maxRadius:Number = (this.width-(this.params.chartLeftMargin + this.params.chartRightMargin + tickLeftWidth + tickRightWidth))/2;
		//Restrict to a minimum of 10
		maxRadius = Math.max(maxRadius, 5);
		//Allot the radius
		this.params.cylRadius = getFN(this.params.cylRadius * this.scaleFactor, maxRadius);
		//Now, calculate the maximum possible height
		var maxHeight:Number = this.height-(this.params.chartTopMargin + this.params.chartBottomMargin + valueHeight);		
		var marVerticalHeight:Number = maxHeight - (this.params.cylRadius*(2.15*this.params.cylYScale));
		//Now, over-ride user values, and apply scale factor
		this.params.cylOriginX = getFN(this.params.cylOriginX*this.scaleFactor, this.params.chartLeftMargin+tickLeftWidth);
		this.params.cylOriginY = getFN(this.params.cylOriginY*this.scaleFactor, this.params.chartTopMargin + 1.05*this.params.cylRadius*this.params.cylYScale + marVerticalHeight);
		this.params.cylHeight = getFN(this.params.cylHeight*this.scaleFactor, marVerticalHeight);
		//Create the entire gauge element
		this.elements.gauge = this.returnDataAsElement(this.params.cylOriginX, this.params.cylOriginY-this.params.cylHeight, this.params.cylRadius*2, this.params.cylHeight);				
	}
	/**
	 * calculatePoints method calculates all the points and angles for plotting the gauge.
	*/
	private function calculatePoints():Void{
		//Loop variable
		var i:Number;
		//Set the axis's start and end points
		this.pAxis.setAxisCoords(this.elements.gauge.toY, this.elements.gauge.y);	
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
	}
	// -------------------- Visual Rendering Methods ---------------------------//	
	/**
	 * drawGauge method draws the base of the gauge (cylinder).
	*/
	private function drawGauge(){
		//Create a movie clip for this
		var gaugeMC:MovieClip = this.cMC.createEmptyMovieClip("Gauge",this.dm.getDepth("GAUGE"));
		//Store properties in local variables and assign to object to pass
		var interval:Number = (this.params.refreshInterval==-1)?2.5:this.params.refreshInterval;
		var objProp:Object = new Object();
		//Store properties in object to pass
		objProp.animation = this.params.animation;
		objProp.OriginX = this.params.cylOriginX;
		objProp.OriginY = this.params.cylOriginY;
		objProp.hCylinder = this.params.cylHeight;
		objProp.rCylinder = this.params.cylRadius;
		objProp.squeeze = this.params.cylYScale;
		objProp.fluidColor = parseInt(this.params.cylFillColor, 16);
		//Transition time - based on interval.
		objProp.alphaTransTime = (0.2*interval>=0.5) ? 0.5 :0.2*interval;
		objProp.heightTransTime = (0.7*interval>=1.5) ? 1.5 : 0.7*interval;
		// assign the lower end ordinate of plot
		gaugeMC._y = this.height;
		//Create the cylinder 
		cyl = new Cylinder(gaugeMC, objProp);
		cyl.setSystem();
		//Update the fill
		this.updateFill();
		//Apply filters
		this.styleM.applyFilters (gaugeMC, this.objects.GAUGE);
		//Clear Interval
		clearInterval(this.config.intervals.gauge);
	}
	/**
	 * drawTicks method draws the tick marks and all their values for the chart.
	*/
	private function drawTicks():Void{
		//Calculate the x position for tick marks - based on ticksOnRight
		var ticksX:Number, tickValuesX:Number;
		var tickValueHAlign:String;
		//Maximum tick height (actually width)- based on which tick is bigger
		var maxTickHeight:Number = (this.params.showTickMarks)?(Math.max(this.params.majorTMHeight, this.params.minorTMHeight)):(0);
		//Multiply factor to indicate which direction the ticks would extend to
		var multiplyF:Number;
		if (this.params.ticksOnRight){
			ticksX = this.elements.gauge.toX + this.params.tickMarkDistance;
			multiplyF = 1;
			//Calculate for value - Ticks below gauge - ticks outside - value outside
			tickValuesX = this.elements.gauge.toX + ((this.params.showTickMarks)?this.params.tickMarkDistance:0) + maxTickHeight + this.params.tickValueDistance;
			tickValueHAlign = "left";				
		}else{
			ticksX = this.elements.gauge.x - this.params.tickMarkDistance;
			multiplyF = -1;
			//Calculate for tick values - Ticks above gauge - ticks outside - value outside					
			tickValuesX = this.elements.gauge.x - ((this.params.showTickMarks)?this.params.tickMarkDistance:0) - maxTickHeight - this.params.tickValueDistance;
			tickValueHAlign = "right";
		}
		//Now, if we've to show tick marks
		if (this.params.showTickMarks){					
			//First draw all the major ticks
			var i:Number;			
			var startPoint:Object, endPoint:Object;
			var tickPosY:Number;
			var tickStartX:Number = ticksX;
			var tickEndX:Number = tickStartX + this.params.majorTMHeight*multiplyF;
			//Create a container movie clip
			var tickMC:MovieClip = this.cMC.createEmptyMovieClip("TickMarks",this.dm.getDepth("TICKMARKS"));
			//Set the line style
			tickMC.lineStyle(this.params.majorTMThickness, parseInt(this.params.majorTMColor,16), this.params.majorTMAlpha);
			//Create the base line
			//tickMC.moveTo(tickStartX, this.elements.gauge.y);
			//tickMC.lineTo(tickStartX, this.elements.gauge.toY);
			//Draw the major ticks now
			for (i=0; i<this.majorTM.length; i++){
				//Get the tick x position
				tickPosY = this.pAxis.getAxisPosition(this.majorTM[i].value);
				//Draw the line
				tickMC.moveTo(tickStartX, tickPosY);
				tickMC.lineTo(tickEndX, tickPosY);
			}
			
			//Also, create the minor tick marks
			var tickEndX:Number = tickStartX + this.params.minorTMHeight*multiplyF;
			tickMC.lineStyle(this.params.minorTMThickness, parseInt(this.params.minorTMColor,16), this.params.minorTMAlpha);
			for (i=0; i<this.minorTM.length; i++){
				//Get the tick x position
				tickPosY = this.pAxis.getAxisPosition(this.minorTM[i]);
				//Draw the line
				tickMC.moveTo(tickStartX, tickPosY);
				tickMC.lineTo(tickEndX, tickPosY);
			}
			//Apply animation and filters to tick marks
			if (this.params.animation){
				this.styleM.applyAnimation (tickMC, this.objects.TICKMARKS, this.macro, tickMC._x, tickMC._y, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (tickMC, this.objects.TICKMARKS);
		}
		// ---------------- DRAW TICK VALUES -----------------//
		if (this.params.showTickValues == 1){
			var tickValue:String;
			var tickPoint:Object;
			//Get tick font style object
			var tickStyle:Object = this.styleM.getTextStyle(this.objects.TICKVALUES);
			var limitStyle:Object  = this.styleM.getTextStyle(this.objects.LIMITVALUES);
			tickStyle.align = tickValueHAlign;
			tickStyle.vAlign = "middle";
			limitStyle.align = tickValueHAlign;
			limitStyle.vAlign = "middle";
			//Tick text field
			var tickValueObj:Object;
			var tickValYPos:Number;
			var depth:Number = this.dm.getDepth("TICKVALUES");
			for (i=0; i<this.majorTM.length; i++){
				//Get tick value
				tickValue = this.majorTM[i].displayValue;
				//Get lower/upper limit display				
				if (i==0){
					tickValue = getFV(this.params.lowerLimitDisplay, this.majorTM[i].displayValue);
				}else if (i==this.majorTM.length-1){
					tickValue = getFV(this.params.upperLimitDisplay, this.majorTM[i].displayValue);
				}
				//If it's the limit values, we check and render
				if (((i==0 || i==this.majorTM.length-1) && this.params.showLimits) || (i>0 && i<this.majorTM.length-1 && this.majorTM[i].showValue)){
					//Get the x position
					tickValYPos = this.pAxis.getAxisPosition(this.majorTM[i].value);
					//Create the tick value
					tickValueObj = createText (false, tickValue, this.cMC, depth, tickValuesX, tickValYPos, 0, ((i==0 || i==this.majorTM.length-1)?limitStyle:tickStyle), false, 0, 0);
					//Apply animation and filters to tick marks
					if (this.params.animation){
						this.styleM.applyAnimation (tickValueObj.tf, ((i==0 || i==this.majorTM.length-1)?this.objects.LIMITVALUES:this.objects.TICKVALUES), this.macro, tickValueObj.tf._x, tickValueObj.tf._y, 100, null, null, null);
					}
					//Apply filters
					this.styleM.applyFilters (tickValueObj.tf, ((i==0 || i==this.majorTM.length-1)?this.objects.LIMITVALUES:this.objects.TICKVALUES));
					//Increase depth 
					depth++;
				}
			}
		}
		//Clear Interval
		clearInterval(this.config.intervals.tickMarks);
	}
	/**
	 * updateFill method updates the height of the fill.
	*/
	private function updateFill():Void{
		//Calculate value y position
		this.config.valueY = this.pAxis.getAxisPosition(this.value);
		//What percent to fill
		this.config.percentFill = Math.abs((this.config.valueY-this.elements.gauge.toY)/this.elements.gauge.h)*100;
		//Update
		this.cyl.updateFluid(this.config.percentFill);
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
			var depth:Number = this.dm.getDepth("VALUE");
			var valueStyleObj:Object = this.styleCache.dataValue;		
			//Render normal label
			valueStyleObj.align = "center";
			valueStyleObj.vAlign = "bottom";
			valueObj = createText (false, this.nf.formatNumber(this.value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals), this.cMC, depth, this.elements.gauge.x + this.elements.gauge.w/2, this.elements.gauge.toY + (1.15*this.params.cylRadius*this.params.cylYScale) + this.params.valuePadding, 0, valueStyleObj, false, 0, 0);
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
				//Update chart.
				this.updateFill();
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
		delete this.value;
	}
	/**
	* remove method removes the chart by clearing the chart movie clip
	* and removing any listeners.
	*/
	public function remove():Void {
		//Destroy cylinder
		this.cyl.destroy();
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
