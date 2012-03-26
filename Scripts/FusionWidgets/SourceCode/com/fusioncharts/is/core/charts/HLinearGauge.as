/**
* @class HLinearGauge
* @author InfoSoft Global(P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright(C) InfoSoft Global Pvt. Ltd. 2005-2006
* HLinearGauge extends the RealTimeGauge class to render the
* functionality of a horizontal linear gauge.
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
//Axis for the chart
import com.fusioncharts.is.axis.GaugeAxis;
//Extensions
import com.fusioncharts.is.extensions.ColorExt;
import com.fusioncharts.is.extensions.StringExt;
import com.fusioncharts.is.extensions.MathExt;
import com.fusioncharts.is.extensions.DrawingExt;
//Tween for animating pointers
import mx.transitions.Tween;
import mx.transitions.easing.*;
//External Interface - to expose methods via JavaScript
import flash.external.ExternalInterface;
class com.fusioncharts.is.core.charts.HLinearGauge extends RealTimeGauge {
	//Numbe of pointers defined for the chart
	private var numPointers:Number;
	//Array to store all pointers
	private var pointers:Array;
	//Array to store trend points
	private var trendPoints:Array;
	//Number of trend points
	private var numTrendPoints:Number;
	//References of value textboxes
	private var arrValueTF:Array;
	/**
	* Constructor function. We invoke the super class'
	* constructor.
	*/
	function HLinearGauge(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Log additional information to debugger
		//We log version from this class, so that if this class version
		//is different, we can log it
		this.log("Version", _version, Logger.LEVEL.INFO);
		this.log("Chart Type", "Real-time Horizontal Linear Gauge", Logger.LEVEL.INFO);
		//List Chart Objects and set them in arrObjects array defined in super parent class.
		this.arrObjects = new Array("BACKGROUND", "TICKMARKS", "TICKVALUES", "LIMITVALUES", "VALUE", "POINTER", "GAUGE", "GAUGELABELS", "TRENDPOINTS", "TRENDVALUES", "TRENDMARKERS", "TOOLTIP");
		super.setChartObjects();
		//Initialize containers
		this.pointers = new Array();
		this.trendPoints = new Array();
		this.arrValueTF = new Array();
		this.numTrendPoints = 0;
		this.numPointers = 0;
		//Expose the methods to JavaScript using ExternalInterface		
		if (ExternalInterface.available && this.registerWithJS==true){
			//feedData method
			ExternalInterface.addCallback("feedData", this, feedData);
			//stopUpdate method
			ExternalInterface.addCallback("stopUpdate", this, stopUpdate);
			//restartUpdate method
			ExternalInterface.addCallback("restartUpdate", this, restartUpdate);
			//getData method - based on index
			ExternalInterface.addCallback("getData", this, getData);						
			//getDataForId method - based on Id
			ExternalInterface.addCallback("getDataForId", this, getDataForId);			
			//Setting individual pointer data
			ExternalInterface.addCallback("setData", this, setData);
			//Setting pointer value from ID
			ExternalInterface.addCallback("setDataForId", this, setDataForId);
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
		//Validate the color ranges
		this.validateColorRange();
		//Calculate scale factor
		this.calculateScaleFactor();
		//Set Style defaults
		this.setStyleDefaults();
		//Cache styles that get re-used
		this.cacheStyles();
		//Now, validate trend lines
		this.validateTrendLines();
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
		//Remove application message
		this.removeAppMessage(this.tfAppMsg);
		//Set tool tip parameter
		this.setToolTipParam();
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
		//Draw the gauge - color range
		this.config.intervals.gauge = setInterval(Delegate.create(this, drawGauge) , this.timeElapsed);
		//Update timer
		this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.GAUGE):0;
		//Draw the gauge labels
		this.config.intervals.gaugeLabels = setInterval(Delegate.create(this, drawGaugeLabels) , this.timeElapsed);						
		//Draw pivot 
		this.config.intervals.tickMarks = setInterval(Delegate.create(this, drawTicks) , this.timeElapsed);
		//Draw trend lines			
		this.config.intervals.trend = setInterval(Delegate.create(this, drawTrendPoints) , this.timeElapsed);			
		//Update timer
		this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.GAUGELABELS, this.objects.TRENDPOINTS, this.objects.TRENDVALUES, this.objects.TRENDMARKERS, this.objects.LIMITVALUES, this.objects.TICKMARKS, this.objects.TICKVALUES):0;
		//Pointers
		this.config.intervals.pointers = setInterval(Delegate.create(this, drawPointers) , this.timeElapsed);									
		//Update timer
		this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.POINTER):0;						
		//Pointer values
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
	 * returnDataAsPointer object creates a pointer object from the given
	 * parameters and returns it.
	 *	@param	id					String identifier of this pointer
	 *	@param	value				Value of this pointer
	 *	@param	showValue			Whether to show value of this ponter?
	 *	@param	editable			Whether the pointer is editable
	 *	@param	borderColor			Border color of this ponter
	 *	@param	borderThickness		Border thickness of this ponter
	 *	@param	borderAlpha			Border alpha of the ponter
	 *	@param	bgColor				Background color 
	 *	@param	bgAlpha				Background alpha for the pointer
	 *	@param	radius				Radius of the ponter
	 *	@param	sides				Number of sides required for this pointer.
	 *	@param	link				Link for the pointer.
	 *	@param	toolText			Custom tool text for the ponter.
	*/
	private function returnDataAsPointer(id:String, value:Number, showValue:Boolean, editable:Boolean, borderColor:String, borderThickness:Number, borderAlpha:Number, bgColor:String, bgAlpha:Number, radius:Number, sides:Number, link:String, toolText:String):Object {
		//Create a pointer object
		var pointerObject:Object = new Object();
		pointerObject.id = id;
		pointerObject.value = value;
		pointerObject.showValue = showValue;
		pointerObject.editable = editable;
		pointerObject.borderColor = borderColor;
		pointerObject.borderThickness = borderThickness;
		pointerObject.borderAlpha = borderAlpha;
		pointerObject.bgColor = bgColor;
		pointerObject.bgAlpha = bgAlpha;
		pointerObject.radius = radius;
		//Restrict sides to a minimum of 3.
		pointerObject.sides = (sides<3)?3:sides;		
		pointerObject.link = link;
		//Set display value for the pointer
		pointerObject.displayValue = this.nf.formatNumber(value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);
		//Set tool text - get the first of tool text, display value		
		pointerObject.toolText = getFV(toolText, pointerObject.displayValue);
		//Storing a copy of original tool text - for use later
		pointerObject.cToolText = toolText;
		//Based on the sides of this pointer, store angle (for drawing)
		pointerObject.startAngle = 0;
		switch (pointerObject.sides){
			case 3 :
				pointerObject.startAngle = (this.params.pointerOnTop)?30:210;
				break;
			case 4 :
				pointerObject.startAngle = 0;
				break;
			case 5 :
				pointerObject.startAngle = (this.params.pointerOnTop)?-17.5:161.5;
				break;
			case 6 :
				pointerObject.startAngle = -30;
				break;
			default:
				pointerObject.startAngle = 0;
				break;
		}
		//Storage for internal properties
		pointerObject.x = 0;
		pointerObject.y = 0;
		//Return it 
		return pointerObject;
	}
	/**
	 * returnDataAsTrendPoint method returns an object representing the trend obj.
	 *	@param	startValue			Start value of trend point
	 *	@param	endValue			End value of trend point (becomes a zone)
	 *	@param	displayValue		Display label for the trend point/zone
	 *	@param	showOnTop			Whether to show on top of gauge?
	 *	@param	color				Color of the zone/line
	 *	@param	thickness			Thickness of the line/border
	 *	@param	alpha				Alpha of the zone
	 *	@param	dashed				Whether the trend line is dashed
	 *	@param	dashLen				Dash length
	 *	@param	dashGap				Dash gap
	 *	@param	useMarker			Whether to show a marker (triangle) at the point
	 *	@param	markerColor			Fill color of the marker
	 *	@param	markerBorderColor	Border Color of the marker	 
	 *	@param	markerRadius		Radius of the marker
	 *	@param	markerToolText		Marker tool text
	*/
	private function returnDataAsTrendPoint(startValue:Number, endValue:Number, displayValue:String, showOnTop:Boolean, color:String, thickness:Number, alpha:Number, dashed:Boolean, dashLen:Number, dashGap:Number, useMarker:Boolean, markerColor:String, markerBorderColor:String, markerRadius:Number, markerToolText:String):Object {
		//Create a return object
		var trendObj:Object = new Object();
		trendObj.startValue = startValue;
		trendObj.endValue = endValue;
		trendObj.displayValue = displayValue;
		trendObj.showOnTop = showOnTop;
		trendObj.color = color;
		trendObj.thickness = thickness;
		trendObj.alpha = alpha;
		trendObj.dashed = dashed;
		trendObj.dashLen = dashLen;
		trendObj.dashGap = dashGap;
		trendObj.useMarker = useMarker;
		trendObj.markerColor = markerColor;
		trendObj.markerBorderColor = markerBorderColor;
		trendObj.markerRadius = markerRadius;
		trendObj.markerToolText = markerToolText;
		trendObj.markerAngle = (trendObj.showOnTop)?-90:90;
		//Internal representation of whether this is a trend zone.
		trendObj.isZone = (startValue != endValue);
		//Flag to store the validity of the trend point
		trendObj.isValid = true;
		//Internal plot properties
		trendObj.fromX = 0;
		trendObj.toX = 0;
		//Return it
		return trendObj;
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
						//Backward compatibility - Instrumentation v2 charts used to provide
						//value to linear gauge using <value></value>. So extract it and store.
						this.numPointers++;
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
						//Add value to data store
						this.pointers[this.numPointers] = returnDataAsPointer(String(this.numPointers), pValue, this.params.showValue, this.params.editMode, this.params.pointerBorderColor, this.params.pointerBorderThickness, this.params.pointerBorderAlpha, this.params.pointerBgColor, this.params.pointerBgAlpha, this.params.pointerRadius, this.params.pointerSides, "", "");
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "POINTERS") {
						//Get reference to child pointer nodes.
						var arrLevel2Nodes:Array = arrLevel1Nodes[j].childNodes;
						for (k=0; k<arrLevel2Nodes.length; k++) {
							if (arrLevel2Nodes[k].nodeName.toUpperCase() == "POINTER") {
								//Increase count
								this.numPointers++;
								//Extract attributes into array.
								var pointerAtt:Array = Utils.getAttributesArray(arrLevel2Nodes[k]);
								//Extract each attribute
								var pID:String = getFV(pointerAtt["id"], String(this.numPointers));
								//Convert to lower case for case insensitive match
								pID = pID.toLowerCase();
								//Now, get value.
								try {
									var pValue:Number = this.nf.parseValue(pointerAtt["value"]);
								} catch (e:Error) {
									//If the value is not a number, log a data
									this.log("Invalid data", e.message, Logger.LEVEL.ERROR);
									//Set as NaN - so that we can show it as empty data.
									pValue = Number("");
								}
								var pShowValue:Boolean = toBoolean(getFN(pointerAtt["showvalue"], Utils.fromBoolean(this.params.showValue)));
								var pEditMode:Boolean = toBoolean(getFN(pointerAtt["editmode"], Utils.fromBoolean(this.params.editMode)));
								var pBorderColor:String = formatColor(getFV(pointerAtt["bordercolor"], this.params.pointerBorderColor));
								var pBorderThickness:Number = getFN(pointerAtt["borderthickness"], this.params.pointerBorderThickness);
								var pBorderAlpha:Number = getFN(pointerAtt["borderalpha"], this.params.pointerBorderAlpha);
								var pBgColor:String = formatColor(getFV(pointerAtt["color"], pointerAtt["bgcolor"], this.params.pointerBgColor));
								var pBgAlpha:Number = getFN(pointerAtt["bgalpha"], this.params.pointerBgAlpha);
								var pRadius:Number = getFN(pointerAtt["radius"], this.params.pointerRadius);
								var pSides:Number = getFN(pointerAtt["sides"], this.params.pointerSides);
								var pLink:String = getFV(pointerAtt["link"], "");
								var pToolText:String = getFV(pointerAtt["tooltext"], pointerAtt["hovertext"]);
								//Create the pointer object
								this.pointers[this.numPointers] = this.returnDataAsPointer(pID, pValue, pShowValue, pEditMode, pBorderColor, pBorderThickness, pBorderAlpha, pBgColor, pBgAlpha, pRadius, pSides, pLink, pToolText);
							}
						}
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "STYLES") {
						//Parse the style nodes to extract style information
						this.styleM.parseXML(arrLevel1Nodes[j].childNodes);
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "ALERTS") {
						//Alerts - check if it has any child nodes
						if (arrLevel1Nodes[j].hasChildNodes()) {
							//Extract alert information
							super.setupAlertManager(arrLevel1Nodes[j]);
						}
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "TRENDPOINTS") {
						//Parse the trend line nodes
						this.parseTrendPointXML(arrLevel1Nodes[j].childNodes);
					}
				}
			}
		}
		//Delete all temporary objects used for parsing XML Data document
		delete setNode;
		delete arrDocElement;
		delete arrLevel1Nodes;
		delete arrLevel2Nodes;
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
		//Whether the chart is in edit mode
		this.params.editMode = toBoolean(getFN(atts["editmode"], 0));
		// ---------- PADDING AND SPACING RELATED ATTRIBUTES ----------- //
		//Chart Margins - Empty space at the 4 sides
		this.params.chartLeftMargin = getFN(atts["chartleftmargin"], 15);
		this.params.chartRightMargin = getFN(atts["chartrightmargin"], 15);
		this.params.chartTopMargin = getFN(atts["charttopmargin"], 5);
		this.params.chartBottomMargin = getFN(atts["chartbottommargin"], 5);
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
		//Whether to show ticks above gauge or below gauge
		this.params.ticksBelowGauge = toBoolean(getFN(atts["ticksbelowgauge"], 1));
		//Whether to place pointer on top part of gauge or bottom part.
		this.params.pointerOnTop = toBoolean(getFN(atts["pointerontop"], Utils.fromBoolean(this.params.ticksBelowGauge)));
		//Whether to place value above pointer or value below pointer
		this.params.valueAbovePointer = toBoolean(getFN(atts["valueabovepointer"], Utils.fromBoolean(this.params.pointerOnTop)));
		//----------------------- TICK PROPERTIES -----------------------------//
		//Tick marks and related properties		
		this.params.showTickMarks = toBoolean(getFN(atts["showtickmarks"], 1));
		this.params.showTickValues = toBoolean(getFN(atts["showtickvalues"], this.params.showTickMarks));
		this.params.placeTicksInside = toBoolean(getFN(atts["placeticksinside"], 0));
		this.params.placeValuesInside = toBoolean(getFN(atts["placevaluesinside"], 0));		
		this.params.showLimits = toBoolean(getFN(atts["showlimits"], this.params.showTickValues));		
		//Whether to automatically adjust TM
		this.params.adjustTM = toBoolean(getFN(atts["adjusttm"], 1));
		//Tick properties
		this.params.majorTMNumber = getFN(atts["majortmnumber"], -1);
		this.params.majorTMColor = formatColor(getFV(atts["majortmcolor"], this.colorM.getTickColor()));
		this.params.majorTMAlpha = getFN(atts["majortmalpha"], 100);
		this.params.majorTMHeight = getFN(atts["majortmheight"], 6);
		this.params.majorTMThickness = getFN(atts["majortmthickness"], 1);
		this.params.minorTMNumber = getFN(atts["minortmnumber"], 4);
		this.params.minorTMColor = formatColor(getFV(atts["minortmcolor"], this.params.majorTMColor));
		this.params.minorTMAlpha = getFN(atts["minortmalpha"], this.params.majorTMAlpha);
		this.params.minorTMHeight = getFN(atts["minortmheight"], Math.round(this.params.majorTMHeight/2));
		this.params.minorTMThickness = getFN(atts["minortmthickness"], 1);
		//Padding between tick mark start position and gauge
		this.params.tickMarkDistance = getFN(atts["tickmarkdistance"], atts["tickmarkgap"], 3);		
		//Tick value distance
		this.params.tickValueDistance = getFN(atts["tickvaluedistance"], atts["displayvaluedistance"], 3);
		//Trend value distance
		this.params.trendValueDistance = getFN(atts["trendvaluedistance"], this.params.tickValueDistance);
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
		//Padding between the pointer and value
		this.params.valuePadding = getFN(atts["valuepadding"], 0);
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
		//Tool Tip - Show/Hide, Background Color, Border Color, Separator Character
		this.params.showToolTip = toBoolean(getFN(atts["showtooltip"], atts["showhovercap"], 1));
		this.params.toolTipBgColor = formatColor(getFV(atts["tooltipbgcolor"], atts["hovercapbgcolor"], atts["hovercapbg"], this.colorM.get2DToolTipBgColor()));
		this.params.toolTipBorderColor = formatColor(getFV(atts["tooltipbordercolor"], atts["hovercapbordercolor"], atts["hovercapborder"], this.colorM.get2DToolTipBorderColor()));
		//Font Properties
		this.params.baseFont = getFV(atts["basefont"], "Verdana");
		this.params.baseFontSize = getFN(atts["basefontsize"], 10);
		this.params.baseFontColor = formatColor(getFV(atts["basefontcolor"], this.colorM.get2DBaseFontColor()));
		//Whether to show shadow for the gauge
		this.params.showShadow = toBoolean(getFN(atts["showshadow"], 1));
		//-------------------------- Gauge specific properties --------------------------//
		//Whether to show gauge labels
		this.params.showGaugeLabels = toBoolean(getFN(atts["showgaugelabels"], atts["showcolornames"], 1));
		//Gauge fill properties
		this.params.gaugeFillMix = atts["gaugefillmix"];
		this.params.gaugeFillRatio = atts["gaugefillratio"];
		//Set defaults
		if (this.params.gaugeFillMix == undefined) {
			this.params.gaugeFillMix = "{light-10},{dark-20},{light-50},{light-85}";
		}
		if (this.params.gaugeFillRatio == undefined) {
			this.params.gaugeFillRatio = "0,8,84,8";
		} 
		//Gauge Border properties  
		this.params.showGaugeBorder = toBoolean(getFN(atts["showgaugeborder"], 1));
		this.params.gaugeBorderColor = formatColor(getFV(atts["gaugebordercolor"], "{dark-20}"));
		this.params.gaugeBorderThickness = getFN(atts["gaugeborderthickness"], 1);
		this.params.gaugeBorderAlpha = getFN(atts["gaugeborderalpha"], 100);
		//Round radius - if gauge is to be drawn as rounded
		this.params.gaugeRoundRadius = getFN(atts["gaugeroundradius"], 0);
		//Pointer properties
		this.params.pointerRadius = getFN(atts["pointerradius"],10);
		this.params.pointerBgColor = formatColor(getFV(atts["pointerbgcolor"], atts["pointercolor"], this.colorM.getPointerBgColor()));
		this.params.pointerBgAlpha = getFN(atts["pointerbgalpha"], 100);
		this.params.pointerBorderColor = formatColor(getFV(atts["pointerbordercolor"], this.colorM.getPointerBorderColor()));
		this.params.pointerBorderThickness = getFN(atts["pointerborderthickness"], 1);
		this.params.pointerBorderAlpha = getFN(atts["pointerborderalpha"], 100);
		this.params.pointerSides = getFN(atts["pointersides"], 3);
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
	 * parseTrendPointXML method parses the trend points for the chart.
	 *	@param	arrTrendNodes	Array containing trend points nodes.
	*/
	private function parseTrendPointXML(arrTrendNodes:Array):Void {
		//Loop variables
		var i:Number;		
		//Define variables for local use
		var startValue:Number, endValue:Number, displayValue:String;
		var showOnTop:Boolean;
		var radius:Number, innerRadius:Number;
		var color:String, thickness:Number, alpha:Number;
		var dashed:Boolean, dashLen:Number, dashGap:Number;
		var useMarker:Boolean, markerColor:String, markerBorderColor:String, markerRadius:Number, markerToolText:String;
		//Iterate through all POINT tags
		for (i=0; i<arrTrendNodes.length; i++){
			//Check if it's a trendpoint
			if (arrTrendNodes[i].nodeName.toUpperCase()=="POINT"){
				//Update count
				this.numTrendPoints++;
				//Store the node reference
				var pointNode:XMLNode = arrTrendNodes[i];
				//Get attributes array
				var atts:Array = Utils.getAttributesArray(pointNode);
				//Extract and store attributes
				try{
					startValue = this.nf.parseValue(getFV(atts["startvalue"], atts["value"]));
				}catch (e:Error){
					//If the value is not a number, log a data
					this.log("Invalid trend point value", e.message, Logger.LEVEL.ERROR);
					//Set as NaN - so that we can track and ignore it later
					startValue = Number("");
				}
				try{
					endValue = this.nf.parseValue(getFV(atts["endvalue"], startValue));					
				}catch (e:Error){
					//If the value is not a number, log a data
					this.log("Invalid trend point end value", e.message, Logger.LEVEL.ERROR);
					//Set as NaN - so that we can track and ignore it later
					endValue = Number("");
				}
				displayValue = atts["displayvalue"];
				showOnTop = toBoolean (Number (getFV(atts["showontop"] , Utils.fromBoolean(this.params.ticksBelowGauge))));
				color = formatColor(getFV(atts["color"],this.colorM.getTrendLightColor()));
				thickness = getFN(atts["thickness"],1);
				alpha = getFN(atts["alpha"],99);
				dashed = toBoolean (getFN (atts ["dashed"] , 0));
				dashLen = getFN(atts["dashlen"],4);
				dashGap = getFN(atts["dashgap"],3);
				//Marker properties
				useMarker = toBoolean(getFN(atts["usemarker"],0));
				markerColor = formatColor(getFV(atts["markercolor"],atts["color"],this.colorM.getTrendLightColor()));
				markerBorderColor = formatColor(getFV(atts["markerbordercolor"],atts["bordercolor"],this.colorM.getTrendDarkColor()));
				markerRadius = getFN(atts["markerradius"],5);
				markerToolText = getFV(atts["markertooltext"],"");
				//Create trend points object
				this.trendPoints[this.numTrendPoints] = returnDataAsTrendPoint(startValue, endValue, displayValue, showOnTop, color, thickness, alpha, dashed, dashLen, dashGap, useMarker, markerColor, markerBorderColor, markerRadius, markerToolText);
			}
		}
	}
	/**
	* getMaxDataValue method gets the maximum data value present
	* in the data.
	*	@return	The maximum value present in the data provided.
	*/
	private function getMaxDataValue():Number{
		//Assume max to be that of first pointer
		var maxValue:Number = this.pointers[1].value;
		var i:Number;
		for (i=2; i<=this.numPointers; i ++){
			//Store the greater number
			maxValue = Math.max(this.pointers[i].value, maxValue);
		}
		return maxValue;
	}
	/**
	* getMinDataValue method gets the minimum data value present
	* in the data
	*	@reurns		The minimum value present in data
	*/
	private function getMinDataValue():Number{
		//Assume min to be that of first pointer
		var minValue:Number = this.pointers[1].value;
		var i:Number;
		for (i=2; i<=this.numPointers; i ++){
			//Store the lesser number
			minValue = Math.min(this.pointers[i].value, minValue);
		}
		return minValue;
	}
	/**
	* setupAxis method sets the axis for the chart.
	* It gets the minimum and maximum value specified in data and
	* based on that it calls super.getAxisLimits();
	*/
	private function setupAxis():Void {
		this.pAxis = new GaugeAxis(this.params.lowerLimit, this.params.upperLimit, false, !this.params.setAdaptiveMin, this.params.majorTMNumber, this.params.minorTMNumber, this.params.adjustTM, this.params.tickValueStep, this.nf, this.params.formatNumber, this.params.formatNumberScale, this.params.tickValueDecimals, this.params.forceTickValueDecimals);
		this.pAxis.calculateLimits(this.getMaxDataValue(),this.getMinDataValue());
		//Calcuate tick marks - based on the initial data.
		this.pAxis.calculateTicks();
		//Store copy of tick marks in local array
		this.majorTM = this.pAxis.getMajorTM();		
		this.minorTM = this.pAxis.getMinorTM();		
	}
	/**
	 * validateTrendLines method validates the trend lines and sets their display
	 * values.
	*/
	private function validateTrendLines():Void{
		//Loop var
		var i:Number;
		//Iterate through all trend lines
		for (i=1; i<=this.numTrendPoints; i++){
			//Check the validity of value.
			if (isNaN(this.trendPoints[i].startValue) || isNaN(this.trendPoints[i].endValue) || (this.trendPoints[i].startValue<this.pAxis.getMin()) || (this.trendPoints[i].startValue>this.pAxis.getMax()) || (this.trendPoints[i].endValue<this.pAxis.getMin()) || (this.trendPoints[i].endValue>this.pAxis.getMax())){
				//Set invalid
				this.trendPoints[i].isValid = false;
			}else{
				//Valid trend point - So, calculate display value
				//Now, if it's a trend zone, we keep an empty display value. Else, we format the
				//number and assume that to be display value.
				if (this.trendPoints[i].isZone){
					this.trendPoints[i].displayValue = getFV(this.trendPoints[i].displayValue,"");
				}else{
					this.trendPoints[i].displayValue = getFV(this.trendPoints[i].displayValue,this.nf.formatNumber(this.trendPoints[i].startValue, this.params.formatNumber, this.params.formatNumberScale, this.params.tickValueDecimals, this.params.forceTickValueDecimals));
				}
			}
		}
	}
	/**
	* setStyleDefaults method sets the default values for styles or
	* extracts information from the attributes and stores them into
	* style objects.
	*/
	private function setStyleDefaults():Void {
		//-----------------------------------------------------------------//
		//Default font object for trend lines
		//-----------------------------------------------------------------//
		var trendFont = new StyleObject ();
		trendFont.name = "_SdTrendFontFont";
		trendFont.font = this.params.baseFont;
		trendFont.size = this.params.baseFontSize;
		trendFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.TRENDVALUES, trendFont, this.styleM.TYPE.FONT, null);
		delete trendFont;
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
		//-----------------------------------------------------------------//
		//Default font object for GaugeLabels
		//-----------------------------------------------------------------//
		var gaugeLabelsFont = new StyleObject ();
		gaugeLabelsFont.name = "_SdGaugeLabelsFont";
		gaugeLabelsFont.align = "center";
		gaugeLabelsFont.valign = "middle";
		gaugeLabelsFont.font = this.params.baseFont;
		gaugeLabelsFont.size = this.params.baseFontSize;
		gaugeLabelsFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.GAUGELABELS, gaugeLabelsFont, this.styleM.TYPE.FONT, null);
		delete gaugeLabelsFont;
		//-----------------------------------------------------------------//
		//Default font object for ToolTip
		//-----------------------------------------------------------------//
		var toolTipFont = new StyleObject ();
		toolTipFont.name = "_SdToolTipFont";
		toolTipFont.font = this.params.baseFont;
		toolTipFont.size = this.params.baseFontSize;
		toolTipFont.color = this.params.baseFontColor;
		toolTipFont.bgcolor = this.params.toolTipBgColor;
		toolTipFont.bordercolor = this.params.toolTipBorderColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.TOOLTIP, toolTipFont, this.styleM.TYPE.FONT, null);
		delete toolTipFont;		
		//------------------------------------------------------------------//
		// Shadow for Gauge
		//------------------------------------------------------------------//
		if (this.params.showShadow){
			var gaugeShadow = new StyleObject ();
			gaugeShadow.name = "_SdGaugeShadow";
			gaugeShadow.alpha = "100";
			//Over-ride
			this.styleM.overrideStyle (this.objects.GAUGE, gaugeShadow, this.styleM.TYPE.SHADOW, null);
			this.styleM.overrideStyle (this.objects.POINTER, gaugeShadow, this.styleM.TYPE.SHADOW, null);
			this.styleM.overrideStyle (this.objects.TRENDMARKERS, gaugeShadow, this.styleM.TYPE.SHADOW, null);
		}
		//-----------------------------------------------------------------//
		//Default Animation object for pointer (if required)
		//-----------------------------------------------------------------//
		if (this.params.defaultAnimation){
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
			
			//Y-scale animation for gauge
			var gaugeYSAnim = new StyleObject ();
			gaugeYSAnim.name = "_SdGaugeYScaleAnim";
			gaugeYSAnim.param = "_yscale";
			gaugeYSAnim.easing = "regular";
			gaugeYSAnim.wait = 0.7;
			gaugeYSAnim.start = 5;
			gaugeYSAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.GAUGE, gaugeYSAnim, this.styleM.TYPE.ANIMATION, "_yscale");
			delete gaugeYSAnim;			
			
			//Pointer animation
			var pointerAlphaAnim = new StyleObject ();
			pointerAlphaAnim.name = "_SdPointerAlphaAnim";
			pointerAlphaAnim.param = "_alpha";
			pointerAlphaAnim.easing = "regular";
			pointerAlphaAnim.wait = 0;
			pointerAlphaAnim.start = 0;
			pointerAlphaAnim.duration = 0.5;
			//Over-ride
			this.styleM.overrideStyle (this.objects.POINTER, pointerAlphaAnim, this.styleM.TYPE.ANIMATION, "_alpha");
			delete pointerAlphaAnim;
			
			var pointerXAnim = new StyleObject ();
			pointerXAnim.name = "_SdPointerXAnim";
			pointerXAnim.param = "_x";
			pointerXAnim.easing = "regular";
			pointerXAnim.wait = 0.4;
			pointerXAnim.start = "$gaugeStartX";
			pointerXAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.POINTER, pointerXAnim, this.styleM.TYPE.ANIMATION, "_x");
			delete pointerXAnim;
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
		//Gauge Scale
		this.dm.reserveDepths ("GAUGE", 1);
		//Gauge Labels
		this.dm.reserveDepths ("GAUGELABELS", this.numCR);
		//Trend zones
		this.dm.reserveDepths ("TRENDZONES", this.numTrendPoints);
		//Tick Marks
		this.dm.reserveDepths ("TICKMARKS", 1);		
		//Trend zones
		this.dm.reserveDepths ("TRENDPOINTS", this.numTrendPoints);		
		//Tick values
		this.dm.reserveDepths ("TICKVALUES", this.majorTM.length+1);
		//Trend markers
		this.dm.reserveDepths ("TRENDMARKERS", this.numTrendPoints);		
		//Trend values
		this.dm.reserveDepths ("TRENDVALUES", this.numTrendPoints);
		//Value text box
		this.dm.reserveDepths ("VALUE", this.numPointers);		
		//Pointers
		this.dm.reserveDepths ("POINTERS", this.numPointers);		
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
		//The gauge (color range) can have the following objects group both above and below it.
		//Group 1 - Trend marker height /2 Trend value distance + trend value height
		//Group 2 - Tick Padding + Tick Marks Height + Tick Value Padding + Tick Values Height
		//Group 3 - Pointer Radius / 2 + {Value Padding + Value Height} --> if show values
		//We'll calculate the top and bottom space required by each group and then block the 
		//maximum required. Rest will be alloted to the gauge.
		var startY:Number = this.params.chartTopMargin;
		//Variables to store top and bottom space required for each group
		var trendTopHeight:Number = 0;
		var trendBottomHeight:Number = 0;
		var tickTopHeight:Number = 0;
		var tickBottomHeight:Number = 0;
		var pointerTopHeight:Number = 0;
		var pointerBottomHeight:Number = 0;
		//Now, do group wise calculation
		var i:Number, j:Number;
		var calcHolder:Number;
		//------------------ GROUP 1 - TREND LINES & VALUES ----------------//
		var trendObj:Object;
		var trendStyle:Object = this.styleM.getTextStyle(this.objects.TRENDVALUES);
		for (i=1; i<=this.numTrendPoints; i++){
			calcHolder = 0;
			//If marker is to be shown, allot 1/2 of marker radius
			if (this.trendPoints[i].useMarker){
				calcHolder = calcHolder + this.trendPoints[i].markerRadius/2;
			}
			//Add trend value distance
			calcHolder = calcHolder + this.params.trendValueDistance;
			//If it's display value is to be shown
			if (this.trendPoints[i].displayValue!=""){
				trendObj = createText (true, this.trendPoints[i].displayValue, this.tfTestMC, 1, testTFX, testTFY, 0, trendStyle, false, 0, 0);
				calcHolder = calcHolder + trendObj.height;
			}
			if (this.trendPoints[i].showOnTop){
				//If the trend point is to be shown at top, reserve at top
				trendTopHeight = Math.max(trendTopHeight, calcHolder);
			}else{
				//Else if the trend point is to be shown at bottom, reserver at bottom
				trendBottomHeight = Math.max(trendBottomHeight, calcHolder);
			}
		}
		//------------- GROUP 2 - TICK MARKS, VALUES, PADDING -------------//
		var tickMarkHeight:Number = 0;
		var tickValueHeight:Number = 0;
		var tickValueObj:Object;
		var tickValue:String;
		var tickFontStyle:Object = this.styleM.getTextStyle(this.objects.TICKVALUES);
		var limitFontStyle:Object = this.styleM.getTextStyle(this.objects.LIMITVALUES);
		//First get the height for tick values if it's to be shown and if to be shown outside
		if (this.params.showTickValues && !this.params.placeValuesInside){			
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
					tickValueHeight = Math.max(tickValueHeight, tickValueObj.height);
				}
			}
			//Add the padding
			tickValueHeight = tickValueHeight + this.params.tickValueDistance;
		}
		//Now, calculate the tick marks height
		if (this.params.showTickMarks && !this.params.placeTicksInside){
			tickMarkHeight = Math.max(this.params.majorTMHeight, this.params.minorTMHeight) + this.params.tickMarkDistance;
		}
		//Now, based on where we've to position the ticks, allot the space
		if (this.params.ticksBelowGauge){
			tickBottomHeight = tickMarkHeight + tickValueHeight;
		}else{
			tickTopHeight = tickMarkHeight + tickValueHeight;
		}
		//------------- GROUP 3 - POINTER, VALUE & VALUE PADDING --------------//		
		var valueObj:Object;
		var valueStyle:Object = this.styleM.getTextStyle(this.objects.VALUE);
		for (i=1; i<=this.numPointers; i++){
			//Half extension beyond gauge
			calcHolder = this.pointers[i].radius;			
			//Now, if value is to be shown & outside gauge
			if (this.pointers[i].showValue && ((this.params.pointerOnTop==true && this.params.valueAbovePointer==true) || (this.params.pointerOnTop==false && this.params.valueAbovePointer==false))){
				calcHolder = calcHolder + this.params.valuePadding;
				//Also add the height of value - using dummy text
				valueObj = createText (true, "123456789%$#@AWXGagypq", this.tfTestMC, 1, testTFX, testTFY, 0, valueStyle, false, 0, 0);
				calcHolder = calcHolder + valueObj.height;
			}
			//Now, based on whether the pointer and value is to be shown, allot
			if (this.params.pointerOnTop){
				pointerTopHeight = calcHolder;
			}else{
				pointerBottomHeight = calcHolder;
			}
		}
		//----------------------------------------------------------------------------//
		//We finally have the maximum top and bottom heights for each possible group.		
		//From this we've to select the max grouped top height and bottom height.
		var maxTopHeight:Number = Math.max(Math.max(trendTopHeight, tickTopHeight),pointerTopHeight)
		var maxBottomHeight:Number = Math.max(Math.max(trendBottomHeight, tickBottomHeight),pointerBottomHeight);
		//Now, create the gauge element accordingly.
		this.elements.gauge = this.returnDataAsElement(this.params.chartLeftMargin, this.params.chartTopMargin + maxTopHeight, this.width-(this.params.chartLeftMargin + this.params.chartRightMargin), this.height-(this.params.chartTopMargin + this.params.chartBottomMargin + maxTopHeight + maxBottomHeight));
	}
	/**
	 * calculatePoints method calculates all the points and angles for plotting the gauge.
	*/
	private function calculatePoints():Void{
		//Loop variable
		var i:Number;
		//Set the axis's start and end points
		this.pAxis.setAxisCoords(this.elements.gauge.x, this.elements.gauge.toX);
		//Now, for each pointer, calculate the value.
		//Also, store the position for pointer values and their alignment.
		var pointerValY:Number, pointerValAlign:String;
		for (i=1; i<=this.numPointers; i++) {
			//Restrict pointer value within upper and lower limit.
			if (this.pointers[i].value>this.pAxis.getMax()) {
				this.pointers[i].value = this.pAxis.getMax();
			}
			//If it's less than lower limit, set it to lower limit
			if (this.pointers[i].value<this.pAxis.getMin()) {
				this.pointers[i].value = this.pAxis.getMin();
			}
			//Set position for each pointer.
			this.pointers[i].x = this.pAxis.getAxisPosition(this.pointers[i].value);
			this.pointers[i].y = (this.params.pointerOnTop)?this.elements.gauge.y:this.elements.gauge.toY;
			
			//-------------- CALCULATION OF VALUE POSITION -----------------//			
			if (this.pointers[i].showValue){
				//Whether pointer is to be on top/bottom
				if (this.params.pointerOnTop){
					pointerValY = this.elements.gauge.y;
				}else{
					pointerValY = this.elements.gauge.toY;
				}
				//Now if the value is to be show above pointer
				if (this.params.valueAbovePointer){
					pointerValY = pointerValY - this.pointers[i].radius - this.params.valuePadding;
					pointerValAlign = "top";
				}else{
					pointerValY = pointerValY + this.pointers[i].radius + this.params.valuePadding;
					pointerValAlign = "bottom";
				}
				//Store
				this.pointers[i].valY = pointerValY;
				this.pointers[i].valAlign = pointerValAlign;
			}
			//--------------------------------------------------------//
		}		
		//Now, calculate the span x-range for each of the color range segment
		for (i=1; i<=this.numCR; i++) {
			this.colorR[i].fromX = this.pAxis.getAxisPosition((i==1)?this.pAxis.getMin():this.colorR[i].minValue);
			this.colorR[i].toX = this.pAxis.getAxisPosition((i==this.numCR)?this.pAxis.getMax():this.colorR[i].maxValue);
		}
		//Calculate the position for each trend point
		for (i=1; i<=this.numTrendPoints; i++) {
			if (this.trendPoints[i].isValid){
				//Set the start and end x pos
				this.trendPoints[i].fromX = this.pAxis.getAxisPosition(this.trendPoints[i].startValue);
				this.trendPoints[i].toX = this.pAxis.getAxisPosition(this.trendPoints[i].endValue);
				//Assume default value for marker radius - apply scaling too
				this.trendPoints[i].markerRadius = this.trendPoints[i].markerRadius;
			}
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
		//Gauge angle related macros		
		this.macro.addMacro ("$gaugeStartX", this.elements.gauge.x);
		this.macro.addMacro ("$gaugeEndX", this.elements.gauge.toX);		
		this.macro.addMacro ("$gaugeStartY", this.elements.gauge.y);
		this.macro.addMacro ("$gaugeEndY", this.elements.gauge.toY);		
	}
	// -------------------- Visual Rendering Methods ---------------------------//	
	/**
	 * drawGauge method draws the base (color range) of the gauge.
	*/
	private function drawGauge(){
		//Loop var
		var i:Number;
		//Storage for colors
		var crColor:Array, crAlpha:Array, crRatio:Array;		
		var arrBorderColor:Array, borderColor:Number;
		//Create a movie clip for this
		var gaugeMC:MovieClip = this.cMC.createEmptyMovieClip("Gauge",this.dm.getDepth("GAUGE"));
		var colorRangeWidth:Number;
		var colorRangeRelativeX:Number;
		var borderColor:Number, borderAlpha:Number;
		//Set it's start position
		gaugeMC._x = this.elements.gauge.x;
		gaugeMC._y = this.elements.gauge.y + (this.elements.gauge.toY-this.elements.gauge.y)/2;
		//Create each color range with it's own properties, but inside the Gauge movie clip.
		for (i=1; i<=this.numCR; i++){
			//Width of the color range
			colorRangeWidth = this.colorR[i].toX - this.colorR[i].fromX;
			colorRangeRelativeX = this.colorR[i].fromX - this.elements.gauge.x;
			//Parse the color, alpha and ratio array for each color range arc.
			//this.params.gaugeFillMix = "{color}";
			crColor = ColorExt.parseColorMix(this.colorR[i].color, this.params.gaugeFillMix);			
			crAlpha = ColorExt.parseAlphaList(this.colorR[i].alpha, crColor.length);
			crRatio = ColorExt.parseRatioList(this.params.gaugeFillRatio, crColor.length);
			//Create matrix object
			var matrix:Object = {matrixType:"box", w:colorRangeWidth, h:this.elements.gauge.h, x:colorRangeRelativeX, y:-(this.elements.gauge.h)/2, r:-Math.PI/2};
			//Draw rounded rectangle
			//Set border propeties
			if (this.params.showGaugeBorder){
				//Which border color to use - between actual color and color mix specified?
				if (this.colorR[i].borderColor.indexOf("{")==-1){
					borderColor = parseInt(this.colorR[i].borderColor,16);
				} else {
					arrBorderColor = ColorExt.parseColorMix(this.colorR[i].color, this.colorR[i].borderColor);
					borderColor = arrBorderColor[0];
				}				
				//Set line style
				gaugeMC.lineStyle(this.params.gaugeBorderThickness, borderColor, this.colorR[i].borderAlpha);
				//Store in local var
				borderAlpha = this.colorR[i].borderAlpha;
			}else{
				borderAlpha = 0;
			}
			//Start the fill.			
			gaugeMC.beginGradientFill ("linear", crColor, crAlpha, crRatio, matrix);
			//Draw rounded rectangle
			DrawingExt.drawRoundedRect(gaugeMC, colorRangeRelativeX, -(this.elements.gauge.h)/2, colorRangeWidth, this.elements.gauge.h, {tl:((i==1)?this.params.gaugeRoundRadius:0), tr:((i==this.numCR)?this.params.gaugeRoundRadius:0), bl:((i==1)?this.params.gaugeRoundRadius:0), br:((i==this.numCR)?this.params.gaugeRoundRadius:0)}, {l:borderColor, r:borderColor, t:borderColor, b:borderColor}, {l:borderAlpha, r:borderAlpha, t:borderAlpha, b:borderAlpha}, {l:this.params.gaugeBorderThickness, r:this.params.gaugeBorderThickness, b:this.params.gaugeBorderThickness, t:this.params.gaugeBorderThickness});
			//End the fill.
			gaugeMC.endFill();
			//-------------------------------------------------------------//			
		}
		//Apply animation and filter effects
		if (this.params.animation){
			this.styleM.applyAnimation (gaugeMC, this.objects.GAUGE, this.macro, gaugeMC._x, gaugeMC._y, 100, 100, 100, null);
		}
		//Apply filters
		this.styleM.applyFilters (gaugeMC, this.objects.GAUGE);
		//Clear Interval
		clearInterval(this.config.intervals.gauge);
	}
	/**
	 * drawGaugeLabels method draws the label of each color range.
	*/
	private function drawGaugeLabels():Void{
		//If we've to show gauge labels at all
		if (this.numCR>0 && this.params.showGaugeLabels){
			var i:Number;
			var depth:Number = this.dm.getDepth("GAUGELABELS");
			var gaugeLabel:Object;
			//Y Position would be center of gauge
			var yPos:Number = this.elements.gauge.y + this.elements.gauge.h/2;
			var xPos:Number;
			//Get text style
			var gaugeLabelStyle:Object = this.styleM.getTextStyle(this.objects.GAUGELABELS);
			//Set alignment
			gaugeLabelStyle.align = "center";
			gaugeLabelStyle.vAlign = "middle";
			for (i=1; i<=this.numCR; i++){
				//If there's a label for this color range
				if (this.colorR[i].label!=""){
					//Calculate xposition - center of each color range
					xPos = this.colorR[i].fromX + (this.colorR[i].toX - this.colorR[i].fromX)/2;
					//Create a text field
					gaugeLabel = createText (false, this.colorR[i].label, this.cMC, depth, xPos, yPos, 0, gaugeLabelStyle, false, 0, 0);
					//Apply animation and filters to tick marks
					if (this.params.animation){
						this.styleM.applyAnimation (gaugeLabel.tf, this.objects.GAUGELABELS, this.macro, gaugeLabel.tf._x, gaugeLabel.tf._y, 100, null, null, null);
					}
					//Apply filters
					this.styleM.applyFilters (gaugeLabel.tf, this.objects.GAUGELABELS);
					//Increment depth
					depth++;
				}				
			}
		}
		clearInterval(this.config.intervals.gaugeLabels);
	}
	/**
	 * drawTicks method draws the tick marks and all their values for the chart.
	*/
	private function drawTicks():Void{
		//Calculate the y position for tick marks - based on ticksBelowGauge & placeTicksInside
		var ticksY:Number, tickValuesY:Number;
		var tickValueVAlign:String;
		//Maximum tick height - based on which tick is bigger
		var maxTickHeight:Number = (this.params.showTickMarks)?(Math.max(this.params.majorTMHeight, this.params.minorTMHeight)):(0);
		//Multiply factor to indicate which direction the ticks would extend to
		var multiplyF:Number;
		if (this.params.ticksBelowGauge){
			//Ticks below gauge - again 2 cases here - inside or outside
			if (this.params.placeTicksInside){
				ticksY = this.elements.gauge.toY - this.params.tickMarkDistance;
				multiplyF = -1;
			}else{
				ticksY = this.elements.gauge.toY + this.params.tickMarkDistance;
				multiplyF = 1;
			}
		}else{
			//Ticks above gauge - again 2 cases here - inside or outside
			if (this.params.placeTicksInside){
				ticksY = this.elements.gauge.y + this.params.tickMarkDistance;
				multiplyF = 1;
			}else{
				ticksY = this.elements.gauge.y - this.params.tickMarkDistance;
				multiplyF = -1;
			}
		}
		// ------------------------------------------------------------------------//
		//Need to run similar calculations for tick value y position
		if (this.params.ticksBelowGauge){
			//Ticks below gauge - again 2 cases here - inside or outside
			if (this.params.placeTicksInside){
				//Now, two possible cases - values inside or outside
				if (this.params.placeValuesInside){
					//Ticks below gauge - ticks inside - value inside
					tickValuesY = this.elements.gauge.toY - ((this.params.showTickMarks)?this.params.tickMarkDistance:0) - maxTickHeight - this.params.tickValueDistance;
					tickValueVAlign = "top";
				}else{
					//Ticks below gauge - ticks inside - value outside
					tickValuesY = this.elements.gauge.toY + this.params.tickValueDistance;
					tickValueVAlign = "bottom";
				}				
			}else{				
				if (this.params.placeValuesInside){
					//Ticks below gauge - ticks ouside - value inside
					tickValuesY = this.elements.gauge.toY - this.params.tickValueDistance;
					tickValueVAlign = "top";
				}else{
					//Ticks below gauge - ticks outside - value outside
					tickValuesY = this.elements.gauge.toY + ((this.params.showTickMarks)?this.params.tickMarkDistance:0) + maxTickHeight + this.params.tickValueDistance;
					tickValueVAlign = "bottom";
				}				
			}
		}else{
			//Ticks above gauge - again 2 cases here - inside or outside
			if (this.params.placeTicksInside){
				if (this.params.placeValuesInside){
					//Ticks above gauge - ticks inside - value inside					
					tickValuesY = this.elements.gauge.y + ((this.params.showTickMarks)?this.params.tickMarkDistance:0) + maxTickHeight + this.params.tickValueDistance;
					tickValueVAlign = "botom";
				}else{
					//Ticks above gauge - ticks inside - value outside					
					tickValuesY = this.elements.gauge.y - this.params.tickValueDistance;
					tickValueVAlign = "top";
				}	
			}else{
				if (this.params.placeValuesInside){
					//Ticks above gauge - ticks outside - value inside					
					tickValuesY = this.elements.gauge.y + this.params.tickValueDistance;;
					tickValueVAlign = "bottom";
				}else{
					//Ticks above gauge - ticks outside - value outside					
					tickValuesY = this.elements.gauge.y - ((this.params.showTickMarks)?this.params.tickMarkDistance:0) - maxTickHeight - this.params.tickValueDistance;
					tickValueVAlign = "top";
				}	
			}
		}
		//-------------------------------------------------------------------------------//
		//Now, if we've to show tick marks
		if (this.params.showTickMarks){					
			//First draw all the major ticks
			var i:Number;			
			var startPoint:Object, endPoint:Object;
			var tickPosX:Number;
			var tickStartY:Number = ticksY;
			var tickEndY:Number = tickStartY + this.params.majorTMHeight*multiplyF;
			//Create a container movie clip
			var tickMC:MovieClip = this.cMC.createEmptyMovieClip("TickMarks",this.dm.getDepth("TICKMARKS"));
			//Set the line style
			tickMC.lineStyle(this.params.majorTMThickness, parseInt(this.params.majorTMColor,16), this.params.majorTMAlpha);
			//Create the base line
			tickMC.moveTo(this.elements.gauge.x, tickStartY);
			tickMC.lineTo(this.elements.gauge.toX, tickStartY);
			//Draw the major ticks now
			for (i=0; i<this.majorTM.length; i++){
				//Get the tick x position
				tickPosX = this.pAxis.getAxisPosition(this.majorTM[i].value);
				//Draw the line
				tickMC.moveTo(tickPosX, tickStartY);
				tickMC.lineTo(tickPosX, tickEndY);
			}
			//Also, create the minor tick marks
			var tickEndY:Number = tickStartY + this.params.minorTMHeight*multiplyF;
			tickMC.lineStyle(this.params.minorTMThickness, parseInt(this.params.minorTMColor,16), this.params.minorTMAlpha);
			for (i=0; i<this.minorTM.length; i++){
				//Get the tick x position
				tickPosX = this.pAxis.getAxisPosition(this.minorTM[i]);
				//Draw the line
				tickMC.moveTo(tickPosX, tickStartY);
				tickMC.lineTo(tickPosX, tickEndY);
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
			tickStyle.align = "center";
			tickStyle.vAlign = tickValueVAlign;
			limitStyle.align = "center";
			limitStyle.vAlign = tickValueVAlign;
			//Tick text field
			var tickValueObj:Object;
			var tickValXPos:Number;
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
					tickValXPos = this.pAxis.getAxisPosition(this.majorTM[i].value);
					//Create the tick value
					tickValueObj = createText (false, tickValue, this.cMC, depth, tickValXPos, tickValuesY, 0, ((i==0 || i==this.majorTM.length-1)?limitStyle:tickStyle), false, 0, 0);
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
	 * drawTrendPoints method draws all the trend points on the gauge.
	*/
	private function drawTrendPoints():Void{
		//Loop variable
		var i:Number;
		//Depth for various trend related objects
		var zoneDepth:Number = this.dm.getDepth("TRENDZONES");
		var pointDepth:Number = this.dm.getDepth("TRENDPOINTS");
		var markerDepth:Number = this.dm.getDepth("TRENDMARKERS");
		var valueDepth:Number = this.dm.getDepth("TRENDVALUES");
		//Style object to represent trend values
		var trendStyle:Object = this.styleM.getTextStyle(this.objects.TRENDVALUES);
		trendStyle.align = "center";
		//Object to store reference of trend
		var trendObj:Object;
		//To store display label pos
		var trendDisplayX:Number, trendDisplayY:Number;		
		//Function reference containers
		var fnRollOver:Function;
		//Iterate through each trend point
		for (i=1; i<=this.numTrendPoints; i++){
			//Proceed only if the trend point is valid
			if (this.trendPoints[i].isValid){				
				//If we need to draw this point as zone or a single
				if (this.trendPoints[i].isZone){
					//Create movie clip for trend zone
					var pointMC:MovieClip = this.cMC.createEmptyMovieClip("TrendPoint_"+i,zoneDepth);							
					//Set the line style to no style
					pointMC.lineStyle();
					//Start the fill.					
					pointMC.beginFill(parseInt(this.trendPoints[i].color,16), this.trendPoints[i].alpha);
					//Draw rounded rectangle
					DrawingExt.drawRoundedRect(pointMC, this.trendPoints[i].fromX, this.elements.gauge.y+1, this.trendPoints[i].toX-this.trendPoints[i].fromX, this.elements.gauge.h-2, {tl:(this.trendPoints[i].fromX>(this.elements.gauge.x+this.params.gaugeRoundRadius))?0:this.params.gaugeRoundRadius, tr:(this.trendPoints[i].toX<(this.elements.gauge.toX-this.params.gaugeRoundRadius))?0:this.params.gaugeRoundRadius, bl:(this.trendPoints[i].fromX>(this.elements.gauge.x+this.params.gaugeRoundRadius))?0:this.params.gaugeRoundRadius, br:(this.trendPoints[i].toX<(this.elements.gauge.toX-this.params.gaugeRoundRadius))?0:this.params.gaugeRoundRadius}, {l:0, r:0, t:0, b:0}, {l:0, r:0, t:0, b:0}, {l:0, r:0, b:0, t:0});					
					//End the fill.
					pointMC.endFill();
				}else{
					//Create movie clip for trend point
					var pointMC:MovieClip = this.cMC.createEmptyMovieClip("TrendPoint_"+i,pointDepth);
					//Set line style
					pointMC.lineStyle(this.trendPoints[i].thickness, parseInt(this.trendPoints[i].color,16), this.trendPoints[i].alpha);
					//Draw the line now.
					if (this.trendPoints[i].dashed){
						DrawingExt.dashTo(pointMC, this.trendPoints[i].fromX, this.elements.gauge.y, this.trendPoints[i].fromX, this.elements.gauge.toY, this.trendPoints[i].dashLen, this.trendPoints[i].dashGap);
					}else{
						pointMC.moveTo(this.trendPoints[i].fromX, this.elements.gauge.y);
						pointMC.lineTo(this.trendPoints[i].fromX, this.elements.gauge.toY);
					}	
				}
				//Apply animation & filter effects
				if (this.params.animation){
					this.styleM.applyAnimation (pointMC, this.objects.TRENDPOINTS, this.macro, null, null, 100, null, null, null);
				}
				//Apply filters
				this.styleM.applyFilters (pointMC, this.objects.TRENDPOINTS);
					
				//Draw the display value for the trend line
				if (this.trendPoints[i].displayValue!='' && this.trendPoints[i].displayValue!=' '){
					//Get the vertical alignment position for trend value
					if (this.trendPoints[i].showOnTop){
						trendStyle.vAlign = "top";
					}else{
						trendStyle.vAlign = "bottom";
					}
					//Calculate the X and Y display values
					trendDisplayX = (this.trendPoints[i].isZone)?(this.trendPoints[i].fromX + (this.trendPoints[i].toX - this.trendPoints[i].fromX)/2):(this.trendPoints[i].fromX);
					trendDisplayY = ((this.trendPoints[i].showOnTop)?(this.elements.gauge.y-this.params.trendValueDistance-((this.trendPoints[i].useMarker)?(this.trendPoints[i].markerRadius/2):(0))):(this.elements.gauge.toY+this.params.trendValueDistance+((this.trendPoints[i].useMarker)?(this.trendPoints[i].markerRadius/2):(0))))
					//Create the text
					trendObj = createText (false, this.trendPoints[i].displayValue, this.cMC, valueDepth, trendDisplayX, trendDisplayY, 0, trendStyle, false, 0, 0);					
					//Apply animation & filter effects
					if (this.params.animation){
						this.styleM.applyAnimation (trendObj.tf, this.objects.TRENDVALUES, this.macro, trendObj.tf._x, trendObj.tf._y, 100, null, null, null);
					}
					//Apply filters
					this.styleM.applyFilters (trendObj.tf, this.objects.TRENDVALUES);
				}								
				//If we need to draw the marker for this point
				if (this.trendPoints[i].useMarker){
					var markerMC:MovieClip = this.cMC.createEmptyMovieClip("TrendMarker_"+i,markerDepth);
					//Set the line style and fill properties
					markerMC.lineStyle(1,parseInt(this.trendPoints[i].markerBorderColor,16),100);
					markerMC.beginFill(parseInt(this.trendPoints[i].markerColor,16),100);
					//Draw the required marker at start angle
					DrawingExt.drawPoly(markerMC, 0, 0, 3, this.trendPoints[i].markerRadius, this.trendPoints[i].markerAngle);
					//Set at the required location
					markerMC._x = this.trendPoints[i].fromX;
					markerMC._y = (this.trendPoints[i].showOnTop)?this.elements.gauge.y:this.elements.gauge.toY;
					//If tool text is present, show so
					if (this.trendPoints[i].markerToolText!=""){
						//Create Delegate for roll over function showToolText
						fnRollOver = Delegate.create (this, showToolText);
						//Set the tool text 
						fnRollOver.toolText = this.trendPoints[i].markerToolText;
						//No hand cursor
						markerMC.useHandCursor = false;
						//Assing the delegates to movie clip handler
						markerMC.onRollOver = fnRollOver;
						//Set roll out and mouse move too.
						markerMC.onRollOut = markerMC.onReleaseOutside = Delegate.create (this, hideToolText);
						markerMC.onMouseMove = Delegate.create(this, positionToolText);
					}
					//Apply animation & filter effects
					if (this.params.animation){
						this.styleM.applyAnimation (markerMC, this.objects.TRENDMARKERS, this.macro, markerMC._x, markerMC._y, 100, 100, 100, null);
					}
					//Apply filters
					this.styleM.applyFilters (markerMC, this.objects.TRENDMARKERS);
				}
				//Increment all depths
				pointDepth++;
				zoneDepth++;
				markerDepth++;
				valueDepth++;
			}
		}		
		//Clear interval
		clearInterval(this.config.intervals.trend);
	}	
	
	/**
	 * drawPointers method draws all the pointers on the chart.
	*/
	private function drawPointers():Void{
		//Loop variable
		var i:Number;		
		var depth:Number = this.dm.getDepth("POINTERS");
		//Delegate function containers
		var fnRollOver:Function, fnClick:Function;
		//Reference to chart
		var chartRef = this;				
		//Create all the pointers
		for (i=1; i<=this.numPointers; i++){
			//Create movie clip container
			var pointerMC:MovieClip = this.cMC.createEmptyMovieClip("Pointer_"+i,depth);
			//Start creating now
			pointerMC.lineStyle(this.pointers[i].borderThickness, parseInt(this.pointers[i].borderColor, 16), this.pointers[i].borderAlpha);
			pointerMC.beginFill(parseInt(this.pointers[i].bgColor,16), this.pointers[i].bgAlpha);
			//Draw the required shape
			DrawingExt.drawPoly(pointerMC, 0, 0, this.pointers[i].sides, this.pointers[i].radius, this.pointers[i].startAngle)
			pointerMC.endFill();
			//Set its position
			pointerMC._x = this.pointers[i].x;
			pointerMC._y = this.pointers[i].y;
			//Set dragging flag to false.
			pointerMC.dragging = false;
			//Apply filters
			this.styleM.applyFilters (pointerMC, this.objects.POINTER);
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (pointerMC, this.objects.POINTER, this.macro, pointerMC._x, pointerMC._y, 100, 100, 100, null);
			}
			//Event handlers for tool tip
			if (this.params.showToolTip){
				//Create Delegate for roll over function dataOnRollOver
				fnRollOver = Delegate.create (this, dataOnRollOver);
				//Set the index of the pointer
				fnRollOver.index = i;
				//Assing the delegates to movie clip handler
				pointerMC.onRollOver = fnRollOver;
				//Set roll out and mouse move too.
				pointerMC.onRollOut = pointerMC.onReleaseOutside = Delegate.create(this, dataOnRollOut);
				pointerMC.onMouseMove = Delegate.create (this, dataOnMouseMove);
			}			
			//Now, if the pointerMC is editable
			if (this.pointers[i].editable){				
				//Set the index
				pointerMC.index = i;
				//Store the start and end position of the gauge
				pointerMC.gaugeStartX = this.elements.gauge.x;
				pointerMC.gaugeEndX = this.elements.gauge.toX;				
				pointerMC.gaugeY = this.pointers[i].y;
				//Set flag whether it has to show value
				pointerMC.showValue = this.pointers[i].showValue;								
				//Define the rotation
				pointerMC.onPress = function(){
					//Hide the tool tip, as we do NOT need it during dragging
					chartRef.tTip.hide();
					//Set dragging flag to true.
					this.dragging = true;
					//Set it's start drag
					this.startDrag(true,this.gaugeStartX,this.gaugeY,this.gaugeEndX,this.gaugeY);
					//Now, define the enter frame function
					this.onEnterFrame = function(){
						//Store final position
						this.finalPos = this._x;
						//Update value (if value for this pointer has to be shown)
						if (this.showValue){
							chartRef.updatePointerValue(this.index, this, this.finalPos);
						}
					}
				}
				pointerMC.onRelease = pointerMC.onReleaseOutside = function(){					
					//Delete the enter frame event.
					delete this.onEnterFrame;
					//Stop dragging
					this.stopDrag();
					//Reset flag
					this.dragging = false;
					//Call pointerUpdated method of the chart class to proceed with rest of work.
					chartRef.pointerUpdated(this.index, this, this.finalPos);					
				}
			}else{
				//Click handler for links - only if link for this pointer has been defined and click URL
				//has not been defined and the pointer is not editable
				if (this.pointers[i].link != "" && this.pointers[i].link != undefined && this.params.clickURL == ""){
					//Create delegate function
					fnClick = Delegate.create (this, dataOnClick);
					//Set link itself
					fnClick.link = this.pointers[i].link;
					//Assign
					pointerMC.onRelease = fnClick;
				} else {
					//Do not use hand cursor
					pointerMC.useHandCursor = (this.params.clickURL=="")?false : true;
				}
			}
			//Increase depth
			depth++;
		}
		//Clear Interval
		clearInterval(this.config.intervals.pointers);
	}
	/**
	 * pointerUpdated method is called when a user drags an editable pointer and updates it.
	 * Note: This method is invoked when user has released the pointer.
	 *	@param	pointerId		Internal ID of the pointer which was updated.
	 *	@param	pointerMC		Movieclip representing the pointer
	 *	@param	pointerPosition	New position of the pointer
	*/
	private function pointerUpdated(pointerId:Number, pointerMC:MovieClip, pointerPosition:Number):Void{		
		//Update the value of pointer
		this.pointers[pointerId].value = this.pAxis.getValueFromPosition(pointerPosition);
		//Set display value for the pointer
		this.pointers[pointerId].displayValue = this.nf.formatNumber(this.pointers[pointerId].value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);
		//Set tool text - get the first of tool text, display value	
		//Tool tip gets updated automatically, as the event handler directly accesses data store to get values.
		this.pointers[pointerId].toolText = getFV(this.pointers[pointerId].cToolText,this.pointers[pointerId].displayValue);
		//If we've to update pointer's value
		if (this.pointers[pointerId].showValue){
			this.drawPointerValue(pointerId, false);
		}
		//Expose event and the value that the pointer has been updated.
		if (ExternalInterface.available && this.registerWithJS==true){
			ExternalInterface.call("FC_ChartUpdated", this.DOMId);
		}
	}
	/**
	 * updatePointerValue method is called when user drags a pointer. We instantly update
	 * the pointers's value. 
	 * Note: This method is called constantly during the onMouseMove event of an
	 * editable pointer.
	 *	@param	pointerId			Internal ID of the pointer which was updated.
	 *	@param	pointerMC			Movieclip representing the pointer
	 *	@param	pointerPosition		New position of the pointer
	*/
	private function updatePointerValue(pointerId:Number, pointerMC:MovieClip, pointerPosition:Number):Void{
		//Get the value representing the new position.
		this.pointers[pointerId].value = this.pAxis.getValueFromPosition(pointerPosition);
		//Get the display value.
		this.pointers[pointerId].displayValue = this.nf.formatNumber(this.pointers[pointerId].value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);				
		//Update value - No need to check for showValue, as that's already been checked in onMouseMove event
		this.drawPointerValue(pointerId, false);
	}
	/**
	* drawValue method draws the value textboxes for all pointers.
	*/
	private function drawValue():Void{		
		//Draw all pointer values
		var i:Number;
		//Now, draw each pointer's value.
		for (i=1; i<=this.numPointers; i++){
			this.drawPointerValue(i, true);
		}
		//Clear interval
		clearInterval (this.config.intervals.valueTB);
	}
	/**
	 * drawPointerValue method draws the value for a particular pointer
	 *	@param	i			Index of pointer whose value is to be drawn.
	 *	@param	firstTime	Whether it's being drawn for the first time.
	*/
	private function drawPointerValue(i:Number, firstTime:Boolean):Void{		
		//Create local objects.
		var valueObj:Object;
		var depth:Number = this.dm.getDepth("VALUE") + (i-1);
		var valueStyleObj:Object = this.styleCache.dataValue;
		//Now, if the value is to be shown.
		if (this.pointers[i].showValue){			
			//Get reference to pointer movie clip
			var pointerMC:MovieClip = this.cMC["Pointer_"+i];
			//Render normal label
			valueStyleObj.align = "center";
			valueStyleObj.vAlign = this.pointers[i].valAlign;
			valueObj = createText (false, this.pointers[i].displayValue, this.cMC, depth, ((firstTime)?(this.pointers[i].x):(pointerMC._x)), this.pointers[i].valY, 0, valueStyleObj, false, 0, 0);
			//Apply filter
			valueObj.tf.filters = this.styleCache.dataValueFilters;
			//Apply animation
			if (firstTime && this.params.animation){
				this.styleM.applyAnimation (valueObj.tf, this.objects.VALUE, this.macro, valueObj.tf._x, valueObj.tf._y, 100, null, null, null);
			}
			//Store reference
			this.arrValueTF[i] = valueObj.tf;			
		}
	}
	/**
	 * updatePointer method is called to change a particular pointer's value. This method
	 * is either called from JavaScript or parseDataFromLV function (real-time update method).
	 *	@param	id		Internal ID of the pointer.
	 *	@param	value	New value of the pointer.
	*/
	private function updatePointer(id:Number, value:Number):Void{
		//Get reference to the movie clip of the pointer
		var pointerMC:MovieClip = this.cMC["Pointer_"+id];		
		//We can proceed only if the pointer is not being dragged, as it'll create
		//interface confusion for the user, when the pointer gets update while he is
		//dragging it.
		if (pointerMC.dragging == false){		
			//Now, we proceed only if the new value is within the range of pointer 
			if (value>=this.pAxis.getMin() && value<=this.pAxis.getMax()){
				//Store pointers value			
				this.pointers[id].value = value;
				//Get the display value.
				this.pointers[id].displayValue = this.nf.formatNumber(this.pointers[id].value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);
				//Set tool text
				this.pointers[id].toolText = getFV(this.pointers[id].cToolText,this.pointers[id].displayValue);
				//Now, feed it to alert manager (if required)
				if (this.useAlerts){
					this.alertM.check(value);
				}
				//Calculate the new position
				this.pointers[id].x = this.pAxis.getAxisPosition(value);
				//Update final position
				pointerMC.finalPos = this.pointers[id].x;
				//Update pointer display value
				if (this.pointers[id].showValue){
					this.drawPointerValue(id,false);
					if (this.params.animation){
						//Animate it with the pointer
						var pointerValueMove:Tween = new Tween(arrValueTF[id], "_x", Strong.easeOut, pointerMC._x - (arrValueTF[id]._width/2), this.pointers[id].x-(arrValueTF[id]._width/2), 1, true);					
					}else{
						arrValueTF[id]._x = this.pointers[id].x-(arrValueTF[id]._width/2);
					}
				}
				//Animate the change (if required)
				if (!this.params.animation){
					pointerMC._x = this.pointers[id].x;
				}else{
					//Animate using tween class
					var pointerMove:Tween = new Tween(pointerMC, "_x", Strong.easeOut, pointerMC._x, this.pointers[id].x, 1, true);					
				}
				
			}else{
				this.log("Value of range","The given value " + String(value) + " is out of chart axis range, and as such is not being plotted",Logger.LEVEL.ERROR);
			}
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
		//------------ GET LIST OF VALUES --------------------//
		//Now, data can be provided in two ways to linear gauge chart:
		//&value=12|23|54 or &id_1=12&id_2=23&id_3=54 (where id_x represents "defined" pointer-id)
		//Based on these two, we've to select which one was specified by the user.		
		//Priority is Id.
		//Final value string container
		var strVal:String;
		//Container for ID based values - separated by | (in a similar fashion to &value=..|..)
		var strIDVal:String = "";
		//Flag to store whether we've been provided data at all
		var valueProvided:Boolean = false;
		//Flag to check whether we've been provided data using id
		var idDataProvided:Boolean = false;		
		//Iterate through each pointer to check for ID based data
		for (i=1; i<=this.numPointers; i++){
			if (dt[this.pointers[i].id]!=undefined && dt[this.pointers[i].id]!=""){
				//Add data to string
				strIDVal = strIDVal + dt[this.pointers[i].id];
				//Update flag that we've been provided data using id.
				idDataProvided = true;
				valueProvided = true;
			}
			//Add the pipe character (necessarily for all data - even those whose IDs are
			//not specified), as else if we've missing data in mid, the data in end will be
			//mis-mapped to that of one between.
			strIDVal = strIDVal + ((i<this.numPointers)?"|":"");				
		}		
		//Priority - check on ID based data. 
		if (idDataProvided){
			//Store final value string in strVal
			strVal = strIDVal;
		}else {
			//Now, if ID based data has not been provided, we check for &value.
			if (dt["value"]!=undefined){
				//If provided, we store value string and update flag
				strVal = dt["value"];
				valueProvided = true;
			}
		}
		//--------------- END GET LIST OF VALUES ----------------//	
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
			//Actual Data string (values)
			var _value:String = getFV(strVal,"");
			//Update dataStamp
			this.params.dataStamp = getFV(dt["datastamp"],"");
			// --------------- Parse into local containers ------------------- //		
			var values:Array = this.parseMultipleData(_value);			
			//Local variables to help in extracing data
			var setValue:Number;
			//Parse each number and store
			for (i=0; i<values.length; i++){				
				try{
					setValue = this.nf.parseValue(values[i]);
				} catch (e:Error){
					//If the value is not a number, log a data
					this.log("Invalid data","Non-numeric data " + values[i] + " received in data stream.", Logger.LEVEL.ERROR);
					//Set as NaN - so that we can show it as empty data.
					setValue = Number("");
				}finally{
					//Store the updated value in array.
					values[i] = setValue;					
				}
			}
			// --------- Store the data in our data structures now ---------//			
			var chartChanged:Boolean = false;
			//Make sure that for each of our pointers, we've a value in values array (be it actual or NaN)
			for (i=1; i<=this.numPointers; i++){
				//Get the value. If it's undefined, set NaN, else actual
				setValue = (values[i-1]==undefined)?(Number("")):(values[i-1]);
				//Update the chart based on this value.
				if (!isNaN(setValue)){
					//If the value has changed at all
					if (this.pointers[i].value!=setValue){
						this.updatePointer(i,setValue);
						//Update flag
						chartChanged = true;
					}
				}				
			}
			//Convey event to JavaScript that we've received new data.
			if (chartChanged && ExternalInterface.available && this.registerWithJS==true){
				ExternalInterface.call("FC_ChartUpdated", this.DOMId);
			}
			//Delete all values from lv - so that it doesn't cache the same from previous call. 
			this.deleteLoadVarsCache();			
			//Free memory
			delete values;			
		}else{
			//If the control comes here, it means that the chart has not been
			//provided with a real-time update containing value. So, log it
			this.log("No data received","The chart couldn't find any data values in the real-time feed.",Logger.LEVEL.INFO);
		}
	}
	/**
	 * getIndexFromId method returns the index of a particular pointer based on
	 * it's id. If it's not found, -1 is returned.
	 *	@param	id		ID of the pointer.
	 *	@return			Numerical index of the pointer
	*/
	private function getIndexFromId(id:String):Number{
		//Convert to lower case for case in-sensitive match
		id = id.toLowerCase();
		//Assume that id doesn't exist
		var index = -1;
		//Iterate and find
		var i:Number;
		for (i=1; i<=this.numPointers; i++){
			if (this.pointers[i].id==id){
				index = i;
				break;
			}
		}
		//Return
		return index;
	}
	/**
	 * getData method returns the data for a particular pointer based on index.
	*/
	public function getData(index:Number):Number{
		//If index is within our range
		if (index>0 && index<=this.numPointers){
			//Return the value
			return this.pointers[index].value;
		}else{
			//Log the error
			this.log("Invalid Index","Invalid pointer index " + String(index) + " specified in getData() retrieval method. If you're providing the ID of pointer instead of numerical index, please use getDataForId() method.", Logger.LEVEL.ERROR);
			//Return NaN
			return Number("");
		}		
	}
	/**
	 * getDataForId method returns the data for a particular pointer based on id.
	*/
	public function getDataForId(id:String):Number{
		//Get the index for the id
		var index:Number = this.getIndexFromId(id);
		//If index is valid
		if (index!=-1){
			//Return the value
			return this.pointers[index].value;
		}else{
			//Log the error
			this.log("Invalid Id","Invalid pointer id " + id + " specified in getDataForId() retrieval method. If you're providing the numerical index of the pointer, please use getData() method.", Logger.LEVEL.ERROR);
			//Return NaN
			return Number("");
		}		
	}
	/**
	 * setData method sets the value for a particular pointer using External
	 * interface or external flash movies.
	 *	@param	index	Numerical index of the pointer whose value is to be updated.
	 *	@param	value	New value for the pointer/
	*/
	public function setData(index:Number, value:Number):Void{
		//If index is within our range
		if (index>0 && index<=this.numPointers){
			//Update the pointer with new value
			this.updatePointer(index, value);
		}else{
			//Log the error
			this.log("Invalid Index","Invalid pointer index " + String(index) + " specified in setData() method. If you're providing the ID of pointer instead of numerical index, please use setDataForId() method.", Logger.LEVEL.ERROR);
		}		
	}
	/**
	 * setDataForId method sets the value for a particular pointer using External
	 * interface or external flash movies. It uses ID instead of index.
	 *	@param	id		Id of the pointer whose value is to be updated.
	 *	@param	value	New value for the pointer
	*/
	public function setDataForId(id:String, value:Number):Void{
		//Get the index for the id
		var index:Number = this.getIndexFromId(id);
		//If index is within our range
		if (index>0 && index<=this.numPointers){
			//Update the pointer with new value
			this.updatePointer(index, value);
		}else{
			//Log the error
			this.log("Invalid Id","Invalid pointer ID " + id + " specified in setDataForId() method. If you're providing the numerical index of the pointer, please use setData() method.", Logger.LEVEL.ERROR);
		}		
	}
	
	// -------------------- EVENT HANDLERS --------------------//
	/**
	* dataOnRollOver is the delegat-ed event handler method that'll
	* be invoked when the user rolls his mouse over a pointer.
	* This function is invoked, only if the tool tip is to be shown.
	* Here, we show the tool tip.
	*/
	private function dataOnRollOver():Void {
		//Index of pointer is stored in arguments.caller.index
		var toolText:String = this.pointers[arguments.caller.index].toolText;
		//Set tool tip text
		this.tTip.setText(toolText);
		//Show the tool tip
		this.tTip.show();
	}	
	/*
	* dataOnMouseMove is called when the mouse position has changed
	* over pointer. We reposition the tool tip.
	*/
	private function dataOnMouseMove():Void{
		//Reposition the tool tip only if it's in visible state
		if (this.tTip.visible()){
			this.tTip.rePosition ();
		}
	}
	/**
	* dataOnRollOut method is invoked when the mouse rolls out
	* of pointer. We just hide the tool tip here.
	*/
	private function dataOnRollOut():Void{
		//Hide the tool tip
		this.tTip.hide();
	}
	/**
	 * showToolText method shows the tool text for any entity
	*/
	private function showToolText():Void{
		//Set tool tip text
		this.tTip.setText(arguments.caller.toolText);
		//Show the tool tip
		this.tTip.show();
	}
	/**
	 * hideToolText method hides the tool text
	*/
	private function hideToolText():Void{
		//Show the tool tip
		this.tTip.hide();
	}
	/**
	 * positionToolText method repositions the tool text
	*/
	private function positionToolText():Void{
		//Reposition the tool tip only if it's in visible state
		if (this.tTip.visible()){
			this.tTip.rePosition ();
		}
	}
	/**
	* dataOnClick is invoked when the user clicks on a pointer (if link
	* has been defined). We invoke the required link.
	*/
	private function dataOnClick():Void {
		//Link of pointer is stored in arguments.caller.link
		var link:String = arguments.caller.link;
		//Invoke the link
		Utils.invokeLink(link, this);
	}
	/**
	* reInit method re-initializes the chart. This method is basically called
	* when the user changes chart data through JavaScript. In that case, we need
	* to re-initialize the chart, set new XML data and again render.
	*/
	public function reInit():Void {
		//Invoke super class's reInit
		super.reInit();
		//Re-initialize local
		this.trendPoints = new Array();
		this.pointers = new Array();
		this.arrValueTF = new Array();
		this.numPointers = 0;
		this.numTrendPoints = 0;
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
		var strS:String = this.params.exportDataSeparator;
		var strLB:String = this.params.exportDataLineBreak;
		var i:Number;
		strData = strQ + "Id" + strQ + strS + strQ + "Value" + strQ + strLB;
		//Iterate through each data-item and add it to the output
		for (i = 1; i <= this.numPointers; i++) {
			strData += strQ + this.pointers[i].id + strQ + strS + strQ + ((this.params.exportDataFormattedVal==true)?(this.pointers[i].displayValue):(this.pointers[i].value)) + strQ + ((i<this.numPointers)?strLB:""); 
		}
		return strData;
	}
}
