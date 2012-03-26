/**
* @class RealTimeMSLineChart
* @author InfoSoft Global(P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright(C) InfoSoft Global Pvt. Ltd. 2005-2006
* AngularGauge extends the RealTimeGauge class to render the
* functionality of a Real-time angular gauge.
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
//Tween for animating dials
import mx.transitions.Tween;
import mx.transitions.easing.*;
//External Interface - to expose methods via JavaScript
import flash.external.ExternalInterface;
class com.fusioncharts.is.core.charts.AngularGauge extends RealTimeGauge {
	//Number of dials
	private var numDials:Number;
	//Container for all dials
	private var dials:Array;
	//Array to store trend points
	private var trendPoints:Array;
	//Number of trend points
	private var numTrendPoints:Number;
	//Array to store references of value textboxes
	private var arrValueTF:Array;
	/**
	* Constructor function. We invoke the super class'
	* constructor.
	*/
	function AngularGauge(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Log additional information to debugger
		//We log version from this class, so that if this class version
		//is different, we can log it
		this.log("Version", _version, Logger.LEVEL.INFO);
		this.log("Chart Type", "Real-time Angular Gauge", Logger.LEVEL.INFO);
		//List Chart Objects and set them in arrObjects array defined in super parent class.
		this.arrObjects = new Array("BACKGROUND", "TICKMARKS", "TICKVALUES", "LIMITVALUES", "VALUE", "DIAL", "PIVOT", "GAUGE", "TRENDPOINTS", "TRENDVALUES", "TRENDMARKERS", "TOOLTIP");
		super.setChartObjects();
		//Initialize containers
		this.dials = new Array();
		this.trendPoints = new Array();
		this.arrValueTF = new Array();
		this.numDials = 0;
		this.numTrendPoints = 0;
		
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
			//getDataForId method - based on ID
			ExternalInterface.addCallback("getDataForId", this, getDataForId);			
			//Setting individual dial data - based on index
			ExternalInterface.addCallback("setData", this, setData);
			//Setting dial value from ID
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
		//Now, in a real-time chart, even if we do not have any data to start with,
		//we continue plotting, as chart can start without data and update itself
		//in real-time.		
		//But, if we do not have a defined dataset, we cannot map incoming data. So,
		//show an error.
		//error.
		if (this.numDials== 0)	{
			tfAppMsg = this.renderAppMessage (_global.getAppMessage ("NODATA", this.lang));
			//Add a message to log.
			this.log ("No Data to Display", "No dial was found in the XML data document provided. If your system generates data based on parameters passed to it using dataURL, please make sure that dataURL is URL Encoded.", Logger.LEVEL.ERROR);
			//Expose rendered method
			this.exposeChartRendered();
			//Also raise the no data event
			this.raiseNoDataExternalEvent();
		} else {
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
			//Calculate gauge default values
			this.calculateGaugeDefaults();
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
			//Draw line chart
			this.config.intervals.gauge = setInterval(Delegate.create(this, drawGauge) , this.timeElapsed);
			//Draw pivot 
			this.config.intervals.pivot = setInterval(Delegate.create(this, drawPivot) , this.timeElapsed);			
			//Update timer
			this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.GAUGE, this.objects.PIVOT):0;
			//Draw pivot 
			this.config.intervals.tickMarks = setInterval(Delegate.create(this, drawTick) , this.timeElapsed);
			//Dials
			this.config.intervals.dials = setInterval(Delegate.create(this, drawDials) , this.timeElapsed);						
			//Update timer
			this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.LIMITVALUES, this.objects.TICKMARKS, this.objects.TICKVALUES, this.objects.DIAL):0;						
			//Real-time value			
			this.config.intervals.valueTB = setInterval(Delegate.create(this, drawValue) , this.timeElapsed);
			//Draw trend lines			
			this.config.intervals.trend = setInterval(Delegate.create(this, drawTrendPoints) , this.timeElapsed);			
			//Update timer
			this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.VALUE, this.objects.TRENDPOINTS, this.objects.TRENDVALUES, this.objects.TRENDMARKERS):0;			
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
	}
	/**
	 * returnDataAsDial object creates a dial object from the given
	 * parameters and returns it.
	 *	@param	id					String identifier of this dial
	 *	@param	value				Value of this dial
	 *	@param	showValue			Whether to show value of this dial?
	 *	@param	valueX				X Position of the value textbox
	 *	@param	valueY				Y Position of the value textbox
	 *	@param	editable			Whether the dial is editable
	 *	@param	borderColor			Border color of this dial
	 *	@param	borderThickness		Border thickness of this dial
	 *	@param	borderAlpha			Border alpha of the dial
	 *	@param	bgColor				Background color list (separated by comma)
	 *	@param	radius				Radius of the dial
	 *	@param	baseWidth			Width of the base of dial.
	 *	@param	topWidth			Width of top part of the dial.
	 *	@param	rearExtension		How much to extend beyond the pivot?
	 *	@param	link				Link for the dial.
	 *	@param	toolText			Custom tool text for the dial.
	*/
	private function returnDataAsDial(id:String, value:Number, showValue:Boolean, valueX:Number, valueY:Number, editable:Boolean, borderColor:String, borderThickness:Number, borderAlpha:Number, bgColor:String, radius:Number, baseWidth:Number, topWidth:Number, rearExtension:Number, link:String, toolText:String):Object{
		//Create a dial object
		var dialObject:Object = new Object();
		dialObject.id = id;
		dialObject.value = value;
		dialObject.showValue = showValue;
		dialObject.valueX = valueX;
		dialObject.valueY = valueY;
		dialObject.editable = editable;
		dialObject.borderColor = borderColor;
		dialObject.borderThickness = borderThickness;
		dialObject.borderAlpha = borderAlpha;
		dialObject.bgColor = bgColor;
		dialObject.radius = radius;
		dialObject.baseWidth = baseWidth;
		dialObject.topWidth = topWidth;
		dialObject.rearExtension = rearExtension;
		dialObject.link = link;
		//Set display value for the dial
		dialObject.displayValue = this.nf.formatNumber(value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);
		//Set tool text - get the first of tool text, display value		
		dialObject.toolText = getFV(toolText,dialObject.displayValue);				
		//Storing a copy of original tool text - for use later
		dialObject.cToolText = toolText;
		//Storage for internal properties
		dialObject.angle = 0;
		//Return it 
		return dialObject;
	}
	/**
	 * returnDataAsTrendPoint method returns an object representing the trend obj.
	 *	@param	startValue			Start value of trend point
	 *	@param	endValue			End value of trend point (becomes a zone)
	 *	@param	displayValue		Display label for the trend point/zone
	 *	@param	valueInside			Whether to show the value inside?
	 *	@param	color				Color of the zone/line
	 *	@param	showBorder			Whether to show border for this trend line?
	 *	@param	borderColor			Border color of the zone
	 *	@param	thickness			Thickness of the line/border
	 *	@param	alpha				Alpha of the zone
	 *	@param	radius				Radius of the zone
	 *	@param	innerRadius			Innerradius of the zone
	 *	@param	dashed				Whether the trend line is dashed
	 *	@param	dashLen				Dash length
	 *	@param	dashGap				Dash gap
	 *	@param	useMarker			Whether to show a marker (triangle) at the point
	 *	@param	markerColor			Fill color of the marker
	 *	@param	markerBorderColor	Border Color of the marker	 
	 *	@param	markerRadius		Radius of the marker
	 *	@param	markerToolText		Marker tool text
	*/
	private function returnDataAsTrendPoint(startValue:Number, endValue:Number, displayValue:String, valueInside:Boolean, color:String, showBorder:Boolean, borderColor:String, thickness:Number, alpha:Number, radius:Number, innerRadius:Number, dashed:Boolean, dashLen:Number, dashGap:Number, useMarker:Boolean, markerColor:String, markerBorderColor:String, markerRadius:Number, markerToolText:String):Object{
		//Create a return object
		var trendObj:Object = new Object;
		trendObj.startValue = startValue;
		trendObj.endValue = endValue;
		trendObj.displayValue = displayValue;
		trendObj.valueInside = valueInside;
		trendObj.color = color;
		trendObj.showBorder = showBorder;
		trendObj.borderColor = borderColor;
		trendObj.thickness = thickness;
		trendObj.alpha = alpha;
		trendObj.radius = radius;
		trendObj.innerRadius = innerRadius;
		trendObj.dashed = dashed;
		trendObj.dashLen = dashLen;
		trendObj.dashGap = dashGap;
		trendObj.useMarker = useMarker;
		trendObj.markerColor = markerColor;
		trendObj.markerBorderColor = markerBorderColor;
		trendObj.markerRadius = markerRadius; 
		trendObj.markerToolText = markerToolText;
		//Internal representation of whether this is a trend zone.
		trendObj.isZone = (startValue!=endValue);
		//Flag to store the validity of the trend point
		trendObj.isValid = true;
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
		for(i = 0; i < arrDocElement.length; i ++){
			//If it's a <graph> element, proceed.
			//Do case in-sensitive mathcing by changing to upper case
			if(arrDocElement [i].nodeName.toUpperCase() == "GRAPH" || arrDocElement [i].nodeName.toUpperCase() == "CHART") {
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
				for(j = 0; j < arrLevel1Nodes.length; j ++){
					if(arrLevel1Nodes [j].nodeName.toUpperCase() == "ANNOTATIONS" || arrLevel1Nodes [j].nodeName.toUpperCase() == "CUSTOMOBJECTS"){
						//Parse and store
						this.am.parseXML(arrLevel1Nodes [j]);
					}
				}
				//Iterate through all level 1 nodes.
				for(j = 0; j < arrLevel1Nodes.length; j ++){
					if(arrLevel1Nodes [j].nodeName.toUpperCase() == "COLORRANGE"){
						//Call the super function to parse and store color range
						this.parseColorRange(arrLevel1Nodes[j].childNodes);
					} else if(arrLevel1Nodes [j].nodeName.toUpperCase() == "DIALS"){
						//Get reference to child DIAL nodes.
						var arrLevel2Nodes:Array = arrLevel1Nodes [j].childNodes;
						for(k = 0; k < arrLevel2Nodes.length; k ++){
							if(arrLevel2Nodes [k].nodeName.toUpperCase() == "DIAL"){								
								//Increase count
								this.numDials++;
								//Extract attributes into array.
								var dialAtt:Array = Utils.getAttributesArray(arrLevel2Nodes[k]);
								//Extract each attribute
								var dID:String = getFV(dialAtt["id"],String(this.numDials));
								//Convert to lower case for case insensitive match
								dID = dID.toLowerCase();
								//Now, get value.
								try{
									var dValue:Number = this.nf.parseValue(dialAtt["value"]);
								} catch (e:Error){
									//If the value is not a number, log a data
									this.log("Invalid data",e.message, Logger.LEVEL.ERROR);
									//Set as NaN - so that we can show it as empty data.
									dValue = Number("");
								}
								var dShowValue = toBoolean(getFN(dialAtt["showvalue"],Utils.fromBoolean(this.params.showValue))); 
								var dValueX = dialAtt["valuex"];
								var dValueY = dialAtt["valuey"];
								var dEditMode = toBoolean(getFN(dialAtt["editmode"],Utils.fromBoolean(this.params.editMode)));
								var dBorderColor = formatColor(getFV(dialAtt["bordercolor"], this.colorM.getDialBorderColor()));
								var dBorderThickness = getFN(dialAtt["borderthickness"],1);
								var dBorderAlpha = getFN(dialAtt["borderalpha"],100);
								var dBgColor = getFV(dialAtt["color"], dialAtt["bgcolor"], this.colorM.getDialColor());
								var dRadius = dialAtt["radius"];
								var dBaseWidth = dialAtt["basewidth"];
								var dTopWidth = getFN(dialAtt["topwidth"], 0);
								var dRearExtension = getFN(dialAtt["rearextension"], 0);
								var dLink = getFV(dialAtt["link"], "");
								var dToolText = getFV(dialAtt["tooltext"], dialAtt["hovertext"]);
								//Create the dial object
								this.dials[this.numDials] = this.returnDataAsDial(dID, dValue, dShowValue, dValueX, dValueY, dEditMode, dBorderColor, dBorderThickness, dBorderAlpha, dBgColor, dRadius, dBaseWidth, dTopWidth, dRearExtension, dLink, dToolText);
							}
						}
						
					} else if(arrLevel1Nodes [j].nodeName.toUpperCase() == "STYLES"){
						//Parse the style nodes to extract style information
						this.styleM.parseXML(arrLevel1Nodes[j].childNodes);
					} else if(arrLevel1Nodes[j].nodeName.toUpperCase() == "ALERTS"){
						//Alerts - check if it has any child nodes
						if (arrLevel1Nodes[j].hasChildNodes()){							
							//Extract alert information
							super.setupAlertManager(arrLevel1Nodes[j]);
						}
					} else if(arrLevel1Nodes [j].nodeName.toUpperCase() == "TRENDPOINTS"){
						//Parse the trend line nodes
						this.parseTrendPointXML(arrLevel1Nodes [j].childNodes);
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
	private function parseAttributes(graphElement:XMLNode):Void{
		//Array to store the attributes
		var atts:Array = Utils.getAttributesArray(graphElement);
		//NOW IT'S VERY NECCESARY THAT WHEN WE REFERENCE THIS ARRAY
		//TO GET AN ATTRIBUTE VALUE, WE SHOULD PROVIDE THE ATTRIBUTE
		//NAME IN LOWER CASE. ELSE, UNDEFINED VALUE WOULD SHOW UP.
		//Extract attributes pertinent to this chart
		//Which palette to use?
		this.params.palette = getFN(atts ["palette"] , 1);
		//If single color them is to be used
		this.params.paletteThemeColor = getFV(atts["palettethemecolor"], "");
		//Setup the color manager
		this.setupColorManager(this.params.palette, this.params.paletteThemeColor);
		//Whether to show real time related context menu items
		this.params.showRTMenuItem = toBoolean(getFN(atts ["showrtmenuitem"] , 1));
		//Whether the chart is in edit mode
		this.params.editMode = toBoolean(getFN(atts ["editmode"] , 0));		
		// ---------- PADDING AND SPACING RELATED ATTRIBUTES ----------- //
		//Chart Margins - Empty space at the 4 sides
		this.params.chartLeftMargin = getFN(atts ["chartleftmargin"] , 15);
		this.params.chartRightMargin = getFN(atts ["chartrightmargin"] , 15);
		this.params.chartTopMargin = getFN(atts ["charttopmargin"] , 15);
		this.params.chartBottomMargin = getFN(atts ["chartbottommargin"] , 15);
		// --------------------- CONFIGURATION ------------------------- //
		//Adaptive yMin - if set to true, the min will be based on the values
		//provided. It won't be set to 0 in case of all positive values
		this.params.setAdaptiveMin = toBoolean(getFN(atts ["setadaptivemin"] , 0));
		//The upper and lower limits of y and x axis
		this.params.upperLimit = atts["upperlimit"];
		this.params.lowerLimit = atts["lowerlimit"];
		//Display values for upper and lower limit
		this.params.upperLimitDisplay = atts["upperlimitdisplay"];
		this.params.lowerLimitDisplay = atts["lowerlimitdisplay"];
		//Whether to set animation for entire chart.
		this.params.animation = toBoolean(getFN(atts ["animation"] , 1));
		//Whether to set the default chart animation
		this.params.defaultAnimation = toBoolean(getFN(atts ["defaultanimation"] , 1));		
		//Click URL
		this.params.clickURL = getFV(atts ["clickurl"] , "");
		//Whether to auto-scale itself with respect to previous size
		this.params.autoScale = toBoolean(getFN(atts ["autoscale"] , 1));
		//Original width and height of chart
		this.params.origW = getFN(atts["origw"], this.width);
		this.params.origH = getFN(atts["origh"], this.height);
		//Delay in rendering annotations that are over the chart
		this.params.annRenderDelay = atts["annrenderdelay"];
		//----------------------- TICK PROPERTIES -----------------------------//
		//Tick marks and related properties
		//Whether to automatically adjust TM
		this.params.showTickMarks = toBoolean(getFN(atts["showtickmarks"], 1));
		this.params.showTickValues = toBoolean(getFN(atts["showtickvalues"], this.params.showTickMarks));		
		this.params.showLimits = toBoolean(getFN(atts ["showlimits"] , this.params.showTickValues));
		this.params.placeTicksInside = toBoolean(getFN(atts["placeticksinside"], 0));
		this.params.placeValuesInside = toBoolean(getFN(atts["placevaluesinside"], 0));
		this.params.adjustTM = toBoolean(getFN(atts["adjusttm"],1));
		//Tick properties
		this.params.majorTMNumber = getFN(atts["majortmnumber"], -1);
		this.params.majorTMColor = formatColor(getFV(atts["majortmcolor"], this.colorM.getTickColor()));
		this.params.majorTMAlpha = getFN(atts["majortmalpha"], 100);
		this.params.majorTMHeight = atts["majortmheight"];
		this.params.majorTMThickness = getFN(atts["majortmthickness"], 1);
		this.params.minorTMNumber = getFN(atts["minortmnumber"], 4);
		this.params.minorTMColor = formatColor(getFV(atts["minortmcolor"], this.params.majorTMColor));
		this.params.minorTMAlpha = getFN(atts["minortmalpha"], this.params.majorTMAlpha);
		this.params.minorTMHeight = atts["minortmheight"];
		this.params.minorTMThickness = getFN(atts["minortmthickness"], 1);
		//Tick value distance
		this.params.tickValueDistance = getFN(atts["tickvaluedistance"], atts["displayvaluedistance"], 15);
		//Trend value distance
		this.params.trendValueDistance = getFN(atts["trendvaluedistance"], this.params.tickValueDistance);
		//Tick value step
		this.params.tickValueStep = int(getFN(atts ["tickvaluestep"] , atts ["tickvaluesstep"] , 1));
		//Cannot be less than 1
		this.params.tickValueStep =(this.params.tickValueStep< 1) ? 1:this.params.tickValueStep;		
		// ------------------- REAL-TIME CHART RELATED ATTRIBUTES -----------------//
		//Message Logger
		this.params.useMessageLog = toBoolean(getFN(atts ["usemessagelog"] , 0));
		this.params.messageLogWPercent = getFN(atts ["messagelogwpercent"] , 80);
		this.params.messageLogHPercent = getFN(atts ["messageloghpercent"] , 70);
		this.params.messageLogShowTitle = toBoolean(getFN(atts ["messagelogshowtitle"] , 1));
		this.params.messageLogTitle = getFV(atts["messagelogtitle"] , "Message Log");
		this.params.messageLogColor = getFV(atts["messagelogcolor"] , this.colorM.get2DMsgLogColor());		
		this.params.messageGoesToLog = toBoolean(getFN(atts ["messagegoestolog"] , 1));
		this.params.messageGoesToJS = toBoolean(getFN(atts ["messagegoestojs"] , 0));
		this.params.messageJSHandler = getFV(atts["messagejshandler"] , "alert");
		this.params.messagePassAllToJS = toBoolean(getFN(atts["messagepassalltojs"] , 0));
		//Whether to show the value below the chart
		this.params.showValue = toBoolean(getFN(atts ["showvalue"] , atts ["showrealtimevalue"] , 0));
		//Whether to show value below or above
		this.params.valueBelowPivot = toBoolean(getFN(atts ["valuebelowpivot"] ,  0));
		//Whether to pull feeds from
		this.params.dataStreamURL = unescape(getFV(atts ["datastreamurl"] , ""));
		//Check whether dataStreamURL contains ?
		this.params.streamURLQMarkPresent = (this.params.dataStreamURL.indexOf("?") != -1);
		//In what time to update the chart
		this.params.refreshInterval = getFN(atts["refreshinterval"] , -1);
		//Data stamp for first data.
		this.params.dataStamp = getFV(atts ["datastamp"] , "");
		// ------------------------- COSMETICS -----------------------------//
		//Background properties - Gradient
		this.params.bgColor = getFV(atts ["bgcolor"] , this.colorM.get2DBgColor());
		this.params.bgAlpha = getFV(atts ["bgalpha"] , this.colorM.get2DBgAlpha());
		this.params.bgRatio = getFV(atts ["bgratio"] , this.colorM.get2DBgRatio());
		this.params.bgAngle = getFV(atts ["bgangle"] , this.colorM.get2DBgAngle());
		//Border Properties of chart
		this.params.showBorder = toBoolean(getFN(atts ["showborder"] , 1));
		this.params.borderColor = formatColor(getFV(atts ["bordercolor"] , this.colorM.get2DBorderColor()));
		this.params.borderThickness = getFN(atts ["borderthickness"] , 1);
		this.params.borderAlpha = getFN(atts ["borderalpha"] , this.colorM.get2DBorderAlpha());
		//Tool Tip - Show/Hide, Background Color, Border Color, Separator Character
		this.params.showToolTip = toBoolean(getFN(atts ["showtooltip"] , atts ["showhovercap"] , 1));
		this.params.toolTipBgColor = formatColor(getFV(atts ["tooltipbgcolor"] , atts ["hovercapbgcolor"] , atts ["hovercapbg"] , this.colorM.get2DToolTipBgColor()));
		this.params.toolTipBorderColor = formatColor(getFV(atts ["tooltipbordercolor"] , atts ["hovercapbordercolor"] , atts ["hovercapborder"] , this.colorM.get2DToolTipBorderColor()));
		//Font Properties
		this.params.baseFont = getFV(atts ["basefont"] , "Verdana");
		this.params.baseFontSize = getFN(atts ["basefontsize"] , 10);
		this.params.baseFontColor = formatColor(getFV(atts ["basefontcolor"] , this.colorM.get2DBaseFontColor()));
		//Whether to show shadow for the gauge
		this.params.showShadow = toBoolean(getFN(atts["showshadow"],1));
		//-------------------------- Gauge specific properties --------------------------//
		//Gauge Functional properties
		this.params.gaugeScaleAngle = getFN(atts["gaugescaleangle"], 180);
		//Cannot be greater than 360
		if (this.params.gaugeScaleAngle>360) {
			this.params.gaugeScaleAngle = 360;
		}		
		this.params.gaugeStartAngle = atts["gaugestartangle"];
		this.params.gaugeEndAngle = atts["gaugeendangle"];
		this.params.gaugeOriginX = atts["gaugeoriginx"];
		this.params.gaugeOriginY = atts["gaugeoriginy"];
		this.params.gaugeOuterRadius = atts["gaugeouterradius"];		
		//Asume gauge inner radius to be a default of 70% of gauge outer radius
		this.params.gaugeInnerRadius = getFV(atts["gaugeinnerradius"],"70%");		
		//Gauge fill properties
		this.params.gaugeFillMix = atts["gaugefillmix"];
		this.params.gaugeFillRatio = atts["gaugefillratio"];
		//Set defaults
		if (this.params.gaugeFillMix==undefined){
			this.params.gaugeFillMix = "{light-10},{light-70},{dark-10}";
		}
		if (this.params.gaugeFillRatio==undefined){
			this.params.gaugeFillRatio = ",6";
		}else if (this.params.gaugeFillRatio!=""){
			//Append a comma before the ratio
			this.params.gaugeFillRatio = "," + this.params.gaugeFillRatio;
		}
		//Gauge Border properties
		this.params.showGaugeBorder = toBoolean(getFN(atts["showgaugeborder"], 1));
		this.params.gaugeBorderColor = formatColor(getFV(atts["gaugebordercolor"], "{dark-20}"));
		this.params.gaugeBorderThickness = getFN(atts["gaugeborderthickness"], 1);
		this.params.gaugeBorderAlpha = getFN(atts["gaugeborderalpha"], 100);
		//Pivot properties
		this.params.pivotRadius = atts["pivotradius"];
		this.params.pivotFillColor = formatColor(getFV(atts["pivotfillcolor"], atts["pivotcolor"], atts["pivotbgcolor"], this.colorM.getPivotColor()));
		this.params.pivotFillAlpha = getFV(atts["pivotfillalpha"], "100");
		this.params.pivotFillRatio = getFV(atts["pivotfillratio"], "0");
		this.params.pivotFillAngle = getFN(atts["pivotfillangle"], 0);
		this.params.pivotFillType = getFV(atts["pivotfilltype"], "radial");
		this.params.pivotFillMix = atts["pivotfillmix"];
		//Set default for fill mix
		if (this.params.pivotFillMix==undefined){
			this.params.pivotFillMix = "{light-10},{light-30},{dark-20}"
		}
		//Pivot border properties
		this.params.showPivotBorder = toBoolean(getFN(atts["showpivotborder"], 0));
		this.params.pivotBorderThickness = getFN(atts["pivotborderthickness"], 1);
		this.params.pivotBorderColor = formatColor(getFV(atts["pivotbordercolor"], this.colorM.getPivotBorderColor()));
		this.params.pivotBorderAlpha = getFN(atts["pivotborderalpha"], 100);		
		// ------------------------- NUMBER FORMATTING ---------------------------- //
		//Option whether the format the number(using Commas)
		this.params.formatNumber = toBoolean(getFN(atts ["formatnumber"] , 1));
		//Option to format number scale
		this.params.formatNumberScale = toBoolean(getFN(atts ["formatnumberscale"] , 0));
		//Number Scales
		this.params.defaultNumberScale = getFV(atts ["defaultnumberscale"] , "");
		this.params.numberScaleUnit = getFV(atts ["numberscaleunit"] , "K,M");
		this.params.numberScaleValue = getFV(atts ["numberscalevalue"] , "1000,1000");
		//Recursive scale properties
		this.params.scaleRecursively = toBoolean(getFN(atts["scalerecursively"], 0));
		//By default we show all - so set as -1
		this.params.maxScaleRecursion = getFN(atts["maxscalerecursion"], -1);
		//Setting space as default scale separator.
		this.params.scaleSeparator = getFV(atts["scaleseparator"] , " ");		
		//Number prefix and suffix
		this.params.numberPrefix = getFV(atts ["numberprefix"] , "");
		this.params.numberSuffix = getFV(atts ["numbersuffix"] , "");
		//Decimal Separator Character
		this.params.decimalSeparator = getFV(atts ["decimalseparator"] , ".");
		//Thousand Separator Character
		this.params.thousandSeparator = getFV(atts ["thousandseparator"] , ",");
		//Input decimal separator and thousand separator. In some european countries,
		//commas are used as decimal separators and dots as thousand separators. In XML,
		//if the user specifies such values, it will give a error while converting to
		//number. So, we accept the input decimal and thousand separator from user, so that
		//we can covert it accordingly into the required format.
		this.params.inDecimalSeparator = getFV(atts ["indecimalseparator"] , "");
		this.params.inThousandSeparator = getFV(atts ["inthousandseparator"] , "");
		//Decimal Precision(number of decimal places to be rounded to)
		this.params.decimals = getFV(atts ["decimals"] , atts ["decimalprecision"], 2);
		//y-Axis values decimals
		this.params.tickValueDecimals = getFN(atts ["tickvaluedecimals"] , atts ["tickvaluesdecimals"], atts["tickmarkdecimalprecision"], this.params.decimals);
		//Force Decimal Padding
		this.params.forceDecimals = toBoolean(getFN(atts ["forcedecimals"] , 0));
		this.params.forceTickValueDecimals = toBoolean(getFN(atts ["forcetickvaluedecimals"] , Utils.fromBoolean(this.params.forceDecimals)));				
		//Set up number formatting 
		this.setupNumberFormatting(this.params.numberPrefix, this.params.numberSuffix, this.params.scaleRecursively, this.params.maxScaleRecursion, this.params.scaleSeparator, this.params.defaultNumberScale, this.params.numberScaleValue, this.params.numberScaleUnit, this.params.decimalSeparator, this.params.thousandSeparator, this.params.inDecimalSeparator, this.params.inThousandSeparator);	
	}
	/**
	 * parseTrendPointXML method parses the trend points for the chart.
	 *	@param	arrTrendNodes	Array containing trend points nodes.
	*/
	private function parseTrendPointXML(arrTrendNodes:Array):Void{
		//Loop variables
		var i:Number;		
		//Define variables for local use
		var startValue:Number, endValue:Number, displayValue:String;
		var valueInside:Boolean;
		var radius:Number, innerRadius:Number;
		var color:String, thickness:Number, alpha:Number, showBorder:Boolean, borderColor:String;
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
				valueInside = toBoolean (Number (getFV(atts["valueinside"] , Utils.fromBoolean(this.params.placeValuesInside))));
				color = formatColor(getFV(atts["color"],this.colorM.getTrendLightColor()));
				showBorder = toBoolean(Number(getFV(atts["showborder"],1)));
				borderColor = formatColor(getFV(atts["bordercolor"],atts["color"],this.colorM.getTrendDarkColor()));
				thickness = getFN(atts["thickness"],1);
				alpha = getFN(atts["alpha"],99);
				radius = atts["radius"]; 
				innerRadius = atts["innerradius"]; 
				dashed = toBoolean (getFN (atts ["dashed"] , 0));
				dashLen = getFN(atts["dashlen"],4);
				dashGap = getFN(atts["dashgap"],3);
				//Marker properties
				useMarker = toBoolean(getFN(atts["usemarker"],0));
				markerColor = formatColor(getFV(atts["markercolor"],atts["color"],this.colorM.getTrendLightColor()));
				markerBorderColor = formatColor(getFV(atts["markerbordercolor"],atts["bordercolor"],this.colorM.getTrendDarkColor()));
				markerRadius = atts["markerradius"];
				markerToolText = getFV(atts["markertooltext"],"");
				//Create trend points object
				this.trendPoints[this.numTrendPoints] = returnDataAsTrendPoint(startValue, endValue, displayValue, valueInside, color, showBorder, borderColor, thickness, alpha, radius, innerRadius, dashed, dashLen, dashGap, useMarker, markerColor, markerBorderColor, markerRadius, markerToolText);
			}
		}
	}	
	/**
	* getMaxDataValue method gets the maximum data value present
	* in the data.
	*	@return	The maximum value present in the data provided.
	*/
	private function getMaxDataValue():Number{
		//Assume max to be that of first dial
		var maxValue:Number = this.dials[1].value;
		var i:Number;
		for (i=2; i<=this.numDials; i ++){
			//Store the greater number
			maxValue = Math.max(this.dials[i].value, maxValue);
		}
		return maxValue;
	}
	/**
	* getMinDataValue method gets the minimum data value present
	* in the data
	*	@reurns		The minimum value present in data
	*/
	private function getMinDataValue():Number{
		//Assume min to be that of first dial
		var minValue:Number = this.dials[1].value;
		var i:Number;
		for (i=2; i<=this.numDials; i ++){
			//Store the lesser number
			minValue = Math.min(this.dials[i].value, minValue);
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
		delete dataValuesFont;
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
			this.styleM.overrideStyle (this.objects.PIVOT, gaugeShadow, this.styleM.TYPE.SHADOW, null);
			this.styleM.overrideStyle (this.objects.DIAL, gaugeShadow, this.styleM.TYPE.SHADOW, null);
			this.styleM.overrideStyle (this.objects.TRENDMARKERS, gaugeShadow, this.styleM.TYPE.SHADOW, null);
		}
		//-----------------------------------------------------------------//
		//Default Animation object for dials (if required)
		//-----------------------------------------------------------------//
		if (this.params.defaultAnimation){
			var dialsAnim = new StyleObject ();
			dialsAnim.name = "_SdDataPlotGaugeXScale";
			dialsAnim.param = "_xscale";
			dialsAnim.easing = "regular";
			dialsAnim.wait = 0;
			dialsAnim.start = 0;
			dialsAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.DIAL, dialsAnim, this.styleM.TYPE.ANIMATION, "_xscale");
			delete dialsAnim;
			
			//Rotation animation
			var dialsAnimRotate = new StyleObject ();
			dialsAnimRotate.name = "_SdDataPlotGaugeRotation";
			dialsAnimRotate.param = "_rotation";
			dialsAnimRotate.easing = "strong";
			dialsAnimRotate.wait = 0.7;
			dialsAnimRotate.start = "$gaugeStartAngle";
			dialsAnimRotate.duration = 1;
			//Over-ride
			this.styleM.overrideStyle (this.objects.DIAL, dialsAnimRotate, this.styleM.TYPE.ANIMATION, "_rotation");
			delete dialsAnimRotate;
		}
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
		//Trend zones
		this.dm.reserveDepths ("TRENDZONES", this.numTrendPoints);
		//Gauge Scale
		this.dm.reserveDepths ("GAUGE", 1);		
		//Trend zones
		this.dm.reserveDepths ("TRENDPOINTS", this.numTrendPoints);
		//Tick Marks & values
		this.dm.reserveDepths ("TICKMARKS", 1);
		this.dm.reserveDepths ("TICKVALUES", this.majorTM.length+1);
		//Trend markers
		this.dm.reserveDepths ("TRENDMARKERS", this.numTrendPoints);		
		//Trend values
		this.dm.reserveDepths ("TRENDVALUES", this.numTrendPoints);
		//Value text box
		this.dm.reserveDepths ("VALUE", this.numDials);		
		//Dials
		this.dm.reserveDepths ("DIALS", this.numDials);		
		//Pivot
		this.dm.reserveDepths ("PIVOT", 1);						
		//Annotations above the chart
		this.dm.reserveDepths ("ANNOTATIONABOVE", 1);
	}
	/**
	* calculateGaugeDefaults method calculates the default positions and angles for gauge.
	*/
	private function calculateGaugeDefaults(){		
		var innerRadius:Number, outerRadius:Number, originX:Number, originY:Number;
		var startAngle:Number, endAngle:Number;
		var dialRadius:Number, i:Number;
		var centerW:Number, centerH:Number, centerX:Number, centerY:Number;
		//Here, we already have a valid value for gauge scale angle - 0-360 - either use defined
		//or our default value (180). We now need to calculate the gaugeStartAngle and gaugeEndAngle,
		//if not given
		// -------------- CALCULATE GAUGE ANGLES -----------------------//
		//Now, calculate the start angle of the chart
		if (this.params.gaugeStartAngle == "" || this.params.gaugeStartAngle == undefined || this.params.gaugeStartAngle == null) {
			//If the gauge scale angle is not defined by user, we try to place the scale in center
			//horizontally. The angle is stored is actual angles (and not Flash angles).
			startAngle = this.params.gaugeScaleAngle+(180-this.params.gaugeScaleAngle)/2;
			//Exceptional cases
			//*********************************//
			//When total angle is 360
			if (Math.abs(this.params.gaugeScaleAngle) == 360) {
				//Set different start angle.
				startAngle = 180;
			}
			//*********************************//
		}
		//Store all angles and finalize
		this.params.gaugeStartAngle = getFN(this.params.gaugeStartAngle, startAngle);
		//If gauge end angle is not defined, assume to start angle + span
		this.params.gaugeEndAngle = getFN(this.params.gaugeEndAngle, this.params.gaugeStartAngle - this.params.gaugeScaleAngle);
		//Restrict angles to the range of -360 to +360
		this.params.gaugeStartAngle = this.restrictAngle(this.params.gaugeStartAngle);
		this.params.gaugeEndAngle = this.restrictAngle(this.params.gaugeEndAngle);
		//Finally, recalculate gaugeScaleAngle based on start and end angle.
		this.params.gaugeScaleAngle = Math.abs(this.params.gaugeStartAngle-this.params.gaugeEndAngle);
		//Calculated values of center X and center Y
		centerW = this.width-(this.params.chartLeftMargin+this.params.chartRightMargin);
		centerH = this.height-(this.params.chartTopMargin+this.params.chartBottomMargin);
		centerX = this.params.chartLeftMargin+(centerW)/2;
		centerY = this.params.chartTopMargin+(centerH)/2;
		//Now that we've the gauge angles sorted out, we need to find the gauge center and radius (auto).
		//If the user doesn't explicitly specify a value for the gauge center and radius, we use these
		//auto values.
		if (this.params.gaugeScaleAngle>180){
			//Case 1: Gauge Scale angle is more than 180 degrees. 
			//So, in this case, we necessarily need to put the gauge at the center of
			//chart.
			outerRadius = Math.min(this.height-(this.params.chartTopMargin+this.params.chartBottomMargin), this.width-(this.params.chartLeftMargin+this.params.chartRightMargin))/2;
			originX = centerX;
			originY = centerY;
		} else if (this.params.gaugeScaleAngle>90 && this.params.gaugeScaleAngle<=180){
			//The gauge spans between 90 and 180 degrees. Based on the same, we can divide this
			//case into 5 sub-case (actually 8, but 4 cases are similar).
			//Common outer radius in all case:
			if ((this.getQuadrant(this.params.gaugeStartAngle)==5  || this.getQuadrant(this.params.gaugeStartAngle)==1) && (this.getQuadrant(this.params.gaugeEndAngle)==1 || this.getQuadrant(this.params.gaugeEndAngle)==5)) {
				outerRadius = Math.min(this.height-(this.params.chartTopMargin+this.params.chartBottomMargin), (this.width-(this.params.chartLeftMargin+this.params.chartRightMargin))/2);
				originX = centerX;
				originY = this.height - this.params.chartBottomMargin;
			} else if ((this.getQuadrant(this.params.gaugeStartAngle)==-5  || this.getQuadrant(this.params.gaugeStartAngle)==-1) && (this.getQuadrant(this.params.gaugeEndAngle)==-1 || this.getQuadrant(this.params.gaugeEndAngle)==1 || this.getQuadrant(this.params.gaugeEndAngle)==-5)){				
				outerRadius = Math.min(this.height-(this.params.chartTopMargin+this.params.chartBottomMargin), (this.width-(this.params.chartLeftMargin+this.params.chartRightMargin))/2);
				originX = centerX;
				originY = this.params.chartTopMargin;
			} else if ((this.getQuadrant(this.params.gaugeStartAngle)==3 || this.getQuadrant(this.params.gaugeStartAngle)==7) && (this.getQuadrant(this.params.gaugeEndAngle)==3 || this.getQuadrant(this.params.gaugeEndAngle)==7)) {
				outerRadius = Math.min((this.height-(this.params.chartTopMargin+this.params.chartBottomMargin))/2, this.width-(this.params.chartLeftMargin+this.params.chartRightMargin));
				originX = this.width - this.params.chartRightMargin;
				originY = centerY;
			} else if ((this.getQuadrant(this.params.gaugeStartAngle)==-7 || this.getQuadrant(this.params.gaugeStartAngle)==-3) && (this.getQuadrant(this.params.gaugeEndAngle)==3 || this.getQuadrant(this.params.gaugeEndAngle)==-3 || this.getQuadrant(this.params.gaugeEndAngle)==-7)) {
				outerRadius = Math.min((this.height-(this.params.chartTopMargin+this.params.chartBottomMargin))/2, this.width-(this.params.chartLeftMargin+this.params.chartRightMargin));
				originX = this.params.chartLeftMargin;
				originY = centerY;
			} else {
				//All other cases
				outerRadius = Math.min(this.height-(this.params.chartTopMargin+this.params.chartBottomMargin), this.width-(this.params.chartLeftMargin+this.params.chartRightMargin))/2;
				originX = centerX;
				originY = centerY;
			}
		} else {
			if ((this.getQuadrant(this.params.gaugeStartAngle)==3  || this.getQuadrant(this.params.gaugeStartAngle)==-3 || this.getQuadrant(this.params.gaugeStartAngle)==1 || this.getQuadrant(this.params.gaugeStartAngle)==-1) && (this.getQuadrant(this.params.gaugeEndAngle)==3 || this.getQuadrant(this.params.gaugeEndAngle)==-3 || this.getQuadrant(this.params.gaugeEndAngle)==1 || this.getQuadrant(this.params.gaugeEndAngle)==-1)) {
				outerRadius = Math.min(this.height-(this.params.chartTopMargin+this.params.chartBottomMargin), this.width-(this.params.chartLeftMargin+this.params.chartRightMargin));
				originX = this.params.chartLeftMargin;
				originY = this.height - this.params.chartBottomMargin;
			} else if ((this.getQuadrant(this.params.gaugeStartAngle)==3  || this.getQuadrant(this.params.gaugeStartAngle)==-3 || this.getQuadrant(this.params.gaugeStartAngle)==5 || this.getQuadrant(this.params.gaugeStartAngle)==-5) && (this.getQuadrant(this.params.gaugeEndAngle)==3 || this.getQuadrant(this.params.gaugeEndAngle)==-3 || this.getQuadrant(this.params.gaugeEndAngle)==5 || this.getQuadrant(this.params.gaugeEndAngle)==-5)){				
				outerRadius = Math.min(this.height-(this.params.chartTopMargin+this.params.chartBottomMargin), this.width-(this.params.chartLeftMargin+this.params.chartRightMargin));
				originX = this.width - this.params.chartRightMargin;
				originY = this.height - this.params.chartBottomMargin;
			} else if ((this.getQuadrant(this.params.gaugeStartAngle)==5 || this.getQuadrant(this.params.gaugeStartAngle)==-5  || this.getQuadrant(this.params.gaugeStartAngle)==7 || this.getQuadrant(this.params.gaugeStartAngle)==-7) && (this.getQuadrant(this.params.gaugeEndAngle)==5 || this.getQuadrant(this.params.gaugeEndAngle)==-5 || this.getQuadrant(this.params.gaugeEndAngle)==7 || this.getQuadrant(this.params.gaugeEndAngle)==-7)) {
				outerRadius = Math.min(this.height-(this.params.chartTopMargin+this.params.chartBottomMargin), this.width-(this.params.chartLeftMargin+this.params.chartRightMargin));
				originX = this.width - this.params.chartRightMargin;
				originY = this.params.chartTopMargin;
			} else if ((this.getQuadrant(this.params.gaugeStartAngle)==7 || this.getQuadrant(this.params.gaugeStartAngle)==1  || this.getQuadrant(this.params.gaugeStartAngle)==-1 || this.getQuadrant(this.params.gaugeStartAngle)==-7) && (this.getQuadrant(this.params.gaugeEndAngle)==7 || this.getQuadrant(this.params.gaugeEndAngle)==-7 || this.getQuadrant(this.params.gaugeEndAngle)==1 || this.getQuadrant(this.params.gaugeEndAngle)==-1)) {
				outerRadius = Math.min(this.height-(this.params.chartTopMargin+this.params.chartBottomMargin), this.width-(this.params.chartLeftMargin+this.params.chartRightMargin));
				originX = this.params.chartLeftMargin;
				originY = this.params.chartTopMargin;
			} else {				
				//All other cases
				outerRadius = Math.min((this.height-(this.params.chartTopMargin+this.params.chartBottomMargin))/2, (this.width-(this.params.chartLeftMargin+this.params.chartRightMargin))/2);
				originX = centerX;
				originY = centerY;
			}
		}
		
		//Allot 15% space if labels are to be plotted outside
		if ((this.params.showTickValues || this.params.showLimits) && (this.params.placeValuesInside==false)) {
			outerRadius = outerRadius*0.85;
			//Do NOT need to adjust origin X, Y as the center position stays same. Only
			//radius decreases.
		}
		//Store our values (thereby, over-riding user values, if needed)
		this.params.gaugeOuterRadius = getFN(this.params.gaugeOuterRadius * this.scaleFactor, outerRadius);		
		//Now for the inner Radius - if it's specified in %, we calculate it accordingly.
		if (this.params.gaugeInnerRadius.indexOf("%")!=-1){
			//Multiply gauge outer radius by the number and store it
			this.params.gaugeInnerRadius = (parseInt(this.params.gaugeInnerRadius,10)/100)*this.params.gaugeOuterRadius;
		}else{
			//Store the numerical value
			this.params.gaugeInnerRadius = Number(this.params.gaugeInnerRadius) * this.scaleFactor;
		}
		//Also, multiply with scale factors to create resolution independent gauges.				
		this.params.gaugeOriginX = getFN(this.params.gaugeOriginX * this.scaleFactor, originX);
		this.params.gaugeOriginY = getFN(this.params.gaugeOriginY * this.scaleFactor, originY);
		//Multiply pivot radius
		this.params.pivotRadius = getFN(this.params.pivotRadius * this.scaleFactor, 5);
		// ----------------------- SET DIAL RADIUS ------------------------//
		//Calculate the radius for each dial
		dialRadius = this.params.gaugeInnerRadius+((this.params.gaugeOuterRadius-this.params.gaugeInnerRadius)/2);
		for (i=1; i<=this.numDials; i++){
			this.dials[i].radius = getFN(this.dials[i].radius * this.scaleFactor,dialRadius);
		}
	}
	/**
	 * getQuadrant method returns which quadrant (-1 to -8 or 1 to 8) the angle falls in.
	 * The angle can either be either positive angle (0-360) or negative (0 to -360).
	 *	@param	angle	Angle to check.
	 *	@return			Which quadrant the angle lines in range -1 to -8 or 1 to 8
	*/
	private function getQuadrant(angle:Number):Number {
		//Reduce angle to -360 to +360
		angle = angle%360;
		//Based on which angle the quadrant lies in, return the same
		switch (true) {
		case (angle>=0 && angle<45) :
			return 1;
			break;
		case (angle>=-360 && angle<-315) :
			return -1;
			break;
		case (angle>=45 && angle<90) :
			return 2;
			break;
		case (angle>=-315 && angle<-270) :
			return -2;
			break;
		case (angle>=90 && angle<135) :
			return 3;
			break;
		case (angle>=-270 && angle<-225) :
			return -3;
			break;
		case (angle>=135 && angle<180) :
			return 4;
			break;
		case (angle>=-225 && angle<-180) :
			return -4;
			break;
		case (angle>=180 && angle<225) :
			return 5;
			break;
		case (angle>=-180 && angle<-135) :
			return -5;
			break;
		case (angle>=225 && angle<270) :
			return 6;
			break;
		case (angle>=-135 && angle<-90) :
			return -6;
			break;
		case (angle>=270 && angle<315) :
			return 7;
			break;
		case (angle>=-90 && angle<-45) :
			return -7;
			break;
		case (angle>=315 && angle<=360) :
			return 8;
			break;
		case (angle>=-45 && angle<0) :
			return -8;
			break;
		}
	} 
	/**
	 * restrictAngle method restricts an angle in the range of -360 to +360.
	*/
	private function restrictAngle(angle:Number):Number{
		if (angle>360){
			return angle%360;
		}else if (angle<-360){
			return angle%(-360);
		}else{
			return angle;
		}
	}
	/**
	 * calculatePoints method calculates all the points and angles for plotting the gauge.
	*/
	private function calculatePoints():Void{
		//Loop variable
		var i:Number;
		//Set the axis's start and end andle
		this.pAxis.setAxisCoords(this.params.gaugeStartAngle, this.params.gaugeEndAngle);
		//Now, for each dial, calculate the angle.		
		for (i=1; i<=this.numDials; i++) {
			//Restrict dial value within upper and lower limit.
			if (this.dials[i].value>this.pAxis.getMax()) {
				this.dials[i].value = this.pAxis.getMax();
			}
			//If it's less than lower limit, set it to lower limit
			if (this.dials[i].value<this.pAxis.getMin()) {
				this.dials[i].value = this.pAxis.getMin();
			}
			//Assign the angle of each dial
			this.dials[i].angle = this.pAxis.getAxisPosition(this.dials[i].value);
			//Adjust the dial's base width based on scale factor
			this.dials[i].baseWidth = getFN(this.dials[i].baseWidth * this.scaleFactor, (this.params.pivotRadius*1.6));
			//Apply scale factor to rear extension
			this.dials[i].rearExtension = this.dials[i].rearExtension * this.scaleFactor;
			//Set default values for value x and y
			this.dials[i].valueX = getFN(this.dials[i].valueX * this.scaleFactor, this.params.gaugeOriginX);
			this.dials[i].valueY = getFN(this.dials[i].valueY * this.scaleFactor, this.params.gaugeOriginY + (((this.params.valueBelowPivot==true)?1:-1)*(this.params.pivotRadius*1.3)) + (((this.params.valueBelowPivot)?1:-1)*(i*this.params.baseFontSize*1.5)));
		}		
		//Now, calculate the angles for each of the color range segment
		for (i=1; i<=this.numCR; i++) {
			this.colorR[i].startAngle = this.pAxis.getAxisPosition(this.colorR[i].minValue);
			this.colorR[i].endAngle = this.pAxis.getAxisPosition(this.colorR[i].maxValue);
		}
		//Calculate the angle for each trend point
		for (i=1; i<=this.numTrendPoints; i++) {
			if (this.trendPoints[i].isValid){
				//Set the start and end angle
				this.trendPoints[i].startAngle = this.pAxis.getAxisPosition(this.trendPoints[i].startValue);
				this.trendPoints[i].endAngle = this.pAxis.getAxisPosition(this.trendPoints[i].endValue);
				//Set default radius values - and apply scale factors				
				//Reducing -2 from outer radius, else the jagged border was showing from behind
				this.trendPoints[i].radius = getFN(this.trendPoints[i].radius * this.scaleFactor, this.params.gaugeOuterRadius - 2);
				this.trendPoints[i].innerRadius = getFN(this.trendPoints[i].innerRadius * this.scaleFactor, ((this.trendPoints[i].isZone)?(Math.max((this.params.gaugeInnerRadius-15),0)):(this.params.gaugeInnerRadius)));			
				//Assume default value for marker radius - apply scaling too
				this.trendPoints[i].markerRadius = getFN(this.trendPoints[i].markerRadius * this.scaleFactor, 5);
			}
		}
		//Apply scaling factors to various objects.
		//To tick mark height
		this.params.majorTMHeight = getFN(this.params.majorTMHeight * this.scaleFactor, 6);
		this.params.minorTMHeight = getFN(this.params.minorTMHeight * this.scaleFactor, 3);
		//To tick value distance
		this.params.tickValueDistance = this.params.tickValueDistance * this.scaleFactor;
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
		this.macro.addMacro ("$gaugeStartAngle", MathExt.standardToFlashAngle(this.params.gaugeStartAngle));
		this.macro.addMacro ("$gaugeEndAngle", MathExt.standardToFlashAngle(this.params.gaugeEndAngle));		
	}
	// -------------------- Visual Rendering Methods ---------------------------//	
	/**
	 * drawGauge method draws the base (color range) of the gauge.
	*/
	private function drawGauge(){
		//Loop var
		var i:Number;
		//Container for storing end points
		var ax:Number, ay:Number;
		var bx:Number, by:Number;
		//Storage for colors
		var crColor:Array, crAlpha:Array, crRatio:Array;		
		var arrBorderColor:Array, borderColor:Number;
		//Create a movie clip for this
		var gaugeMC:MovieClip = this.cMC.createEmptyMovieClip("Gauge",this.dm.getDepth("GAUGE"));
		//Set it's center position
		gaugeMC._x = this.params.gaugeOriginX;
		gaugeMC._y = this.params.gaugeOriginY;
		//Create each color range with it's own properties, but inside the Gauge movie clip.
		for (i=1; i<=this.numCR; i++){
			//We need to create an arc for each of these color range			
			//Parse the color, alpha and ratio array for each color range arc.
			crColor = ColorExt.parseColorMix(this.colorR[i].color, this.params.gaugeFillMix);
			crAlpha = ColorExt.parseAlphaList(this.colorR[i].alpha, crColor.length);
			crRatio = ColorExt.parseRatioList(String((this.params.gaugeInnerRadius/this.params.gaugeOuterRadius)*100) + this.params.gaugeFillRatio, crColor.length);		
			//Create matrix object
			var matrix:Object = {matrixType:"box", w:this.params.gaugeOuterRadius*2, h:this.params.gaugeOuterRadius*2, x:-(this.params.gaugeOuterRadius) , y:-(this.params.gaugeOuterRadius), r:0};
			//Store properties locally for easy and quick access.
			var radius:Number = this.params.gaugeOuterRadius;
			var innerRadius:Number = this.params.gaugeInnerRadius;			
			var startAngle:Number = this.colorR[i].startAngle;
			var endAngle:Number = this.colorR[i].endAngle;
			var sweepAngle:Number = endAngle-startAngle;			
			//Calculate end points (for connecting lines)
			ax = Math.cos(endAngle/180*Math.PI)*innerRadius;
			ay = Math.sin(-endAngle/180*Math.PI)*innerRadius;
			bx = Math.cos(startAngle/180*Math.PI)*radius;
			by = Math.sin(-startAngle/180*Math.PI)*radius;			
			//We'll draw the border and fill separately 			
			//--------- DRAW THE FILL OF ARC FIRST -----------//			
			//Move to the start of gauge
			gaugeMC.moveTo(bx, by);
			//Set the line style to no lines
			gaugeMC.lineStyle();
			//Start the fill.			
			gaugeMC.beginGradientFill ("radial", crColor, crAlpha, crRatio, matrix);
			//Draw outer circle
			DrawingExt.drawCircle(gaugeMC, 0, 0, radius, radius, startAngle, endAngle-startAngle);
			//Connect via line to inner circle
			gaugeMC.lineTo(ax, ay);
			//Draw inner circle
			DrawingExt.drawCircle(gaugeMC, 0, 0, innerRadius, innerRadius, endAngle, -(endAngle-startAngle));
			//Connect back to outer circle
			gaugeMC.lineTo(bx, by);
			//End the fill.
			gaugeMC.endFill();
			//--------------------------------------------------------------//
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
				//Draw the outer arc
				DrawingExt.drawCircle(gaugeMC, 0, 0, radius, radius, startAngle, endAngle-startAngle);
				//Move to left side start of inner circle
				//If it's more than 360, we do not draw any internal line connectors.
				if (Math.abs(sweepAngle)<360) {
					gaugeMC.lineTo(ax, ay);
				}
				DrawingExt.drawCircle(gaugeMC, 0, 0, innerRadius, innerRadius, endAngle, -(endAngle-startAngle));
				//Join with outer circle
				if (Math.abs(sweepAngle)<360) {
					gaugeMC.lineStyle(this.params.gaugeBorderThickness, borderColor, this.colorR[i].borderAlpha);
					gaugeMC.lineTo(bx, by);
				}
			}			
		}
		//Apply animation and filter effects
		if (this.params.animation){
			this.styleM.applyAnimation (gaugeMC, this.objects.GAUGE, this.macro, gaugeMC._x, gaugeMC._y, 100, 100, 100, gaugeMC._rotation);
		}
		//Apply filters
		this.styleM.applyFilters (gaugeMC, this.objects.GAUGE);
		//Clear Interval
		clearInterval(this.config.intervals.gauge);
	}
	/**
	 * drawPivot method draws the pivot for the gauge.
	*/
	private function drawPivot(){
		//Storage for colors
		var pvColor:Array, pvAlpha:Array, pvRatio:Array;		
		//Create a movie clip for this
		var pivotMC:MovieClip = this.cMC.createEmptyMovieClip("Pivot",this.dm.getDepth("PIVOT"));
		//Set it's center position
		pivotMC._x = this.params.gaugeOriginX;
		pivotMC._y = this.params.gaugeOriginY;
		//Parse the color, alpha and ratio array for each color range arc.
		pvColor = ColorExt.parseColorMix(this.params.pivotFillColor, this.params.pivotFillMix);
		pvAlpha = ColorExt.parseAlphaList(this.params.pivotFillAlpha, pvColor.length);
		pvRatio = ColorExt.parseRatioList(this.params.pivotFillRatio, pvColor.length);		
		//Create matrix object
		var matrix:Object = {matrixType:"box", w:this.params.pivotRadius*2, h:this.params.pivotRadius*2, x:-(this.params.pivotRadius) , y:-(this.params.pivotRadius), r:MathExt.toRadians(this.params.pivotFillAngle)};
		//--------- DRAW THE FILL OF ARC FIRST -----------//			
		//Set the line style to no lines
		if (this.params.showPivotBorder){
			pivotMC.lineStyle(this.params.pivotBorderThickness, parseInt(this.params.pivotBorderColor,16), this.params.pivotBorderAlpha);
		}else{
			pivotMC.lineStyle();
		}
		//Start the fill.			
		pivotMC.beginGradientFill (this.params.pivotFillType, pvColor, pvAlpha, pvRatio, matrix);
		//Draw the pivot 
		DrawingExt.drawCircle(pivotMC, 0, 0, this.params.pivotRadius, this.params.pivotRadius, 0, 360);
		//End the fill.
		pivotMC.endFill();
			
		//Apply animation and filter effects
		if (this.params.animation){
			this.styleM.applyAnimation (pivotMC, this.objects.PIVOT, this.macro, pivotMC._x, pivotMC._y, 100, 100, 100, null);
		}
		//Apply filters
		this.styleM.applyFilters (pivotMC, this.objects.PIVOT);
		//Clear Interval
		clearInterval(this.config.intervals.pivot);
	}
	/**
	 * drawTick method draws the tick marks and tick values.
	*/
	private function drawTick():Void{
		//If at all, we've to show tick marks
		if (this.params.showTickMarks){			
			//First draw all the major ticks
			var i:Number;
			var angle:Number;
			var startPoint:Object, endPoint:Object;
			//Create a container movie clip
			var tickMC:MovieClip = this.cMC.createEmptyMovieClip("TickMarks",this.dm.getDepth("TICKMARKS"));
			//Set the line style
			tickMC.lineStyle(this.params.majorTMThickness, parseInt(this.params.majorTMColor,16), this.params.majorTMAlpha);
			for (i=0; i<this.majorTM.length; i++){
				//Get the angle
				angle = this.pAxis.getAxisPosition(this.majorTM[i].value);
				//Calculate start point and end point
				startPoint = MathExt.getAngularPoint(this.params.gaugeOriginX, this.params.gaugeOriginY, ((this.params.placeTicksInside==false)?(this.params.gaugeOuterRadius-this.params.majorTMHeight):(this.params.gaugeInnerRadius)), angle);
				endPoint = MathExt.getAngularPoint(this.params.gaugeOriginX, this.params.gaugeOriginY, ((this.params.placeTicksInside==false)?(this.params.gaugeOuterRadius):(this.params.gaugeInnerRadius+this.params.majorTMHeight)), angle);
				//Draw the line
				tickMC.moveTo(startPoint.x, startPoint.y);
				tickMC.lineTo(endPoint.x, endPoint.y);
			}
			//Also, create the minor tick marks
			tickMC.lineStyle(this.params.minorTMThickness, parseInt(this.params.minorTMColor,16), this.params.minorTMAlpha);
			for (i=0; i<this.minorTM.length; i++){
				//Get the angle
				angle = this.pAxis.getAxisPosition(this.minorTM[i]);
				//Calculate start point and end point
				startPoint = MathExt.getAngularPoint(this.params.gaugeOriginX, this.params.gaugeOriginY, ((this.params.placeTicksInside==false)?(this.params.gaugeOuterRadius-this.params.minorTMHeight):(this.params.gaugeInnerRadius)), angle);
				endPoint = MathExt.getAngularPoint(this.params.gaugeOriginX, this.params.gaugeOriginY, ((this.params.placeTicksInside==false)?(this.params.gaugeOuterRadius):(this.params.gaugeInnerRadius+this.params.minorTMHeight)), angle);
				//Draw the line
				tickMC.moveTo(startPoint.x, startPoint.y);
				tickMC.lineTo(endPoint.x, endPoint.y);
			}
		}
		//Apply animation and filters to tick marks
		if (this.params.animation){
			this.styleM.applyAnimation (tickMC, this.objects.TICKMARKS, this.macro, tickMC._x, tickMC._y, 100, null, null, null);
		}
		//Apply filters
		this.styleM.applyFilters (tickMC, this.objects.TICKMARKS);
		//---------------- CREATE TICK VALUES ---------------------//
		if (this.params.showTickValues){
			var tickValue:String;
			var tickPoint:Object;
			//Get tick font style object
			var tickStyle:Object = this.styleM.getTextStyle(this.objects.TICKVALUES);
			var limitStyle:Object  = this.styleM.getTextStyle(this.objects.LIMITVALUES);
			tickStyle.align = "center";
			tickStyle.vAlign = "middle";			
			limitStyle.align = "center";
			limitStyle.vAlign = "middle";
			//Tick text field
			var tickValueObj:Object;
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
					//Get the angle
					angle = this.pAxis.getAxisPosition(this.majorTM[i].value);
					//Calculate start point and end point
					tickPoint = MathExt.getAngularPoint(this.params.gaugeOriginX, this.params.gaugeOriginY, ((this.params.placeValuesInside==false)?(this.params.gaugeOuterRadius+this.params.tickValueDistance):(this.params.gaugeInnerRadius-this.params.tickValueDistance)), angle);
					//Create the tick value
					tickValueObj = createText (false, tickValue, this.cMC, depth, tickPoint.x, tickPoint.y, 0, ((i==0 || i==this.majorTM.length-1)?limitStyle:tickStyle), false, 0, 0);
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
	 * drawDials method draws all the dials on the chart.
	*/
	private function drawDials():Void{
		//Loop variable
		var i:Number;
		var dialMC:MovieClip;
		var spindleMC:MovieClip;
		var dialColors:Array, dialAlpha:Array, dialRatio:Array;
		var depth:Number = this.dm.getDepth("DIALS");
		//Delegate function containers
		var fnRollOver:Function, fnClick:Function;
		//Reference to chart
		var chartRef = this;				
		//Create all the dials
		for (i=1; i<=this.numDials; i++){
			//Create movie clip container
			dialMC = this.cMC.createEmptyMovieClip("Dial_"+i,depth);
			//Create a spindle inside it (for rotation at registration point)
			spindleMC = dialMC.createEmptyMovieClip("Spindle",1);
			//Parse dial color, alpha and ratio
			dialColors = ColorExt.parseColorList(this.dials[i].bgColor);
			dialAlpha = ColorExt.parseAlphaList("100",dialColors.length);
			dialRatio = ColorExt.parseRatioList("0",dialColors.length);			
			//Start creating now
			spindleMC.lineStyle(this.dials[i].borderThickness, parseInt(this.dials[i].borderColor, 16), this.dials[i].borderAlpha);
			spindleMC.beginGradientFill("linear", dialColors, dialAlpha, dialRatio, {matrixType:"box", x:0, y:-(this.dials[i].baseWidth/2), w:(this.dials[i].radius), h:(this.dials[i].baseWidth), r:Math.PI/2});
			spindleMC.moveTo(-1*this.dials[i].rearExtension, -(this.dials[i].baseWidth)/2);
			spindleMC.lineTo(this.dials[i].radius, -(this.dials[i].topWidth)/2);
			spindleMC.lineTo(this.dials[i].radius, this.dials[i].topWidth/2);
			spindleMC.lineTo(-1*this.dials[i].rearExtension, this.dials[i].baseWidth/2);
			spindleMC.lineTo(-1*this.dials[i].rearExtension, 0);
			spindleMC.endFill();
			//Set its origin		
			dialMC._x = this.params.gaugeOriginX;
			dialMC._y = this.params.gaugeOriginY;
			//Set the rotation of the dial
			dialMC._rotation = MathExt.standardToFlashAngle(this.dials[i].angle);
			//Store the final rotated angle (our angle format) in a property
			dialMC.finalAngle = this.dials[i].angle;
			//Set dragging flag to false.
			dialMC.dragging = false;
			//Set its rotation in the required way
			if (this.params.animation){				
				this.styleM.applyAnimation (dialMC, this.objects.DIAL, this.macro, dialMC._x, dialMC._y, 100, 100, 100, MathExt.standardToFlashAngle(this.dials[i].angle));
			}			
			//Apply filters
			this.styleM.applyFilters (dialMC, this.objects.DIAL);
			//Event handlers for tool tip
			if (this.params.showToolTip){
				//Create Delegate for roll over function dataOnRollOver
				fnRollOver = Delegate.create (this, dataOnRollOver);
				//Set the index of the dial
				fnRollOver.index = i;
				//Assing the delegates to movie clip handler
				dialMC.onRollOver = fnRollOver;
				//Set roll out and mouse move too.
				dialMC.onRollOut = dialMC.onReleaseOutside = Delegate.create (this, dataOnRollOut);
				dialMC.onMouseMove = Delegate.create (this, dataOnMouseMove);
			}
			//Now, if the dial is editable
			if (this.dials[i].editable){				
				//Set the index
				dialMC.index = i;
				//Store the start and end angle of the gauge.
				var startA:Number = this.params.gaugeStartAngle;
				var endA:Number = this.params.gaugeEndAngle;				
				//Convey it to the dial.
				dialMC.minAngle = Math.min(startA,endA);
				dialMC.maxAngle = Math.max(startA,endA);				
				//Set flag whether it has to show value
				dialMC.showValue = this.dials[i].showValue;								
				//Define the rotation
				dialMC.onPress = function(){
					//Hide the tool tip, as we do NOT need it during dragging
					chartRef.tTip.hide();
					//Now, define the mouse move function
					this.onMouseMove = function(){						
						//Set flag to true
						this.dragging = true;
						//Get the rotation angle in terms of Flash (0 to 180) and (0 to -180)
						var newAngle:Number = Math.atan2(_ymouse-this._y, _xmouse - this._x) * 180/Math.PI;
						//Convert that to a scale of (0 to 360)
						var cnvtAngle:Number = MathExt.flash180ToStandardAngle(newAngle);
						//Based on the gauge angles, now manipulate convert angles to come in same 
						//terms as the gauge angle (our, not Flash angles).						
						if (dialMC.minAngle>=0 && dialMC.maxAngle>=0){
							//Now, if the entire gauge is based on positive values.
							//We do not need to manipulate converted angle, as that already represents
							//simple 0 to 360 scale. So, simply rotate the gauge.							
						} else if (dialMC.minAngle<=0 && dialMC.maxAngle>=0){
							//One angle is negative and the other positive
							//Calculate the start angle of gauge in terms of 360
							var gStart360T:Number = 360 + dialMC.minAngle;							
							//Update converted angle
							if (cnvtAngle>gStart360T){
								//Calculate the difference in angle
								var diffAngle:Number = cnvtAngle - gStart360T;
								cnvtAngle = dialMC.minAngle + diffAngle;
							}
						}
						//Round off, if at the end of the dial - for smooth user interaction
						//We take a relaxation of 1.5 degrees.
						if (Math.abs(cnvtAngle-this.minAngle)<1.5){
							newAngle = newAngle + (cnvtAngle-this.minAngle);
							cnvtAngle = this.minAngle;
						}
						if (Math.abs(cnvtAngle-this.maxAngle)<1.5){
							newAngle = newAngle + (cnvtAngle-this.maxAngle);
							cnvtAngle = this.maxAngle;
						}
						if (cnvtAngle>=this.minAngle && cnvtAngle<=this.maxAngle){
								this._rotation = newAngle;
								//Update value (if value for this dial has to be shown)
								if (this.showValue){
									chartRef.updateDialValue(this.index, this, this.finalAngle);
								}
								//Store final angle
								this.finalAngle = cnvtAngle;
						}else{
							//Can do if required.
							//Delete mouse move event so that it cannot complete a full circle
							//delete this.onMouseMove;
						}
					}
				}
				dialMC.onRelease = dialMC.onReleaseOutside = function(){
					//Delete the mouse move event.
					delete this.onMouseMove;
					if (this.dragging){
						//Reset flag
						this.dragging = false;
						//Call dialUpdated method of the chart class to proceed with rest of work.
						chartRef.dialUpdated(this.index, this, this.finalAngle);						
					}
				}
			}else{
				//Click handler for links - only if link for this dial has been defined and click URL
				//has not been defined and the dial is not editable
				if (this.dials[i].link != "" && this.dials[i].link != undefined && this.params.clickURL == ""){
					//Create delegate function
					fnClick = Delegate.create (this, dataOnClick);
					//Set link itself
					fnClick.link = this.dials[i].link;
					//Assign
					dialMC.onRelease = fnClick;
				} else {
					//Do not use hand cursor
					dialMC.useHandCursor = (this.params.clickURL=="")?false : true;
				}
			}
			//Increase depth
			depth++;
		}
		//Clear Interval
		clearInterval(this.config.intervals.dials);
	}
	/**
	 * updateDial method is called to change a particular dial's value. This method
	 * is either called from JavaScript or parseDataFromLV function (real-time update method).
	 *	@param	id		Internal ID of the dial.
	 *	@param	value	New value of the dial.
	*/
	private function updateDial(id:Number, value:Number):Void{
		//Get reference to the movie clip of the dial
		var dialMC:MovieClip = this.cMC["Dial_"+id];		
		//We can proceed only if the dial is not being dragged, as it'll create
		//interface confusion for the user, when the dial gets update while he is
		//dragging it.
		if (dialMC.dragging == false){		
			//Now, we proceed only if the new value is within the range of dial 
			if (value>=this.pAxis.getMin() && value<=this.pAxis.getMax()){
				//Store dial value			
				this.dials[id].value = value;
				//Get the display value.
				this.dials[id].displayValue = this.nf.formatNumber(this.dials[id].value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);
				//Set tool text
				this.dials[id].toolText = getFV(this.dials[id].cToolText,this.dials[id].displayValue);
				//Now, feed it to alert manager (if required)
				if (this.useAlerts){
					this.alertM.check(value);
				}
				//Calculate the new rotation angle
				this.dials[id].angle = this.pAxis.getAxisPosition(value);
				//Store previous final angle in local variable
				var prevAngle:Number = dialMC.finalAngle;
				//Update angle
				dialMC.finalAngle = this.dials[id].angle;
				//Animate the change (if required)
				if (!this.params.animation){
					dialMC._rotation = MathExt.standardToFlashAngle(this.dials[id].angle);
				}else{
					//Animate using tween class
					var dialRotate:Tween = new Tween(dialMC, "_rotation", Strong.easeOut, MathExt.standardToFlashAngle(prevAngle), MathExt.standardToFlashAngle(this.dials[id].angle), 1, true);
				}
				//Update dial display value
				if (this.dials[id].showValue){
					this.drawDialValue(id,false);
				}
			}else{
				this.log("Value of range","The given value " + String(value) + " is out of chart axis range, and as such is not being plotted",Logger.LEVEL.ERROR);
			}
		}
	}
	/**
	 * updateDialValue method is called when user drags a dial. We instantly update
	 * the dial's value. 
	 * Note: This method is called constantly during the onMouseMove event of an
	 * editable dial.
	 *	@param	dialId			Internal ID of the dial which was updated.
	 *	@param	dialMC			Movieclip representing the dial
	 *	@param	dialPosition	New position of the dial
	*/
	private function updateDialValue(dialId:Number, dialMC:MovieClip, dialPosition:Number):Void{
		//Get the value representing the new position.
		this.dials[dialId].value = this.pAxis.getValueFromPosition(dialPosition);
		//Get the display value.
		this.dials[dialId].displayValue = this.nf.formatNumber(this.dials[dialId].value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);		
		//Update value - No need to check for showValue, as that's already been checked in onMouseMove event
		this.drawDialValue(dialId, false);
	}
	/**
	 * dialUpdated method is called when a user drags an editable dial and updates it.
	 * Note: This method is invoked when user has released the dial.
	 *	@param	dialId			Internal ID of the dial which was updated.
	 *	@param	dialMC			Movieclip representing the dial
	 *	@param	dialPosition	New position of the dial
	*/
	private function dialUpdated(dialId:Number, dialMC:MovieClip, dialPosition:Number):Void{		
		//Update the values of dial
		this.dials[dialId].value = this.pAxis.getValueFromPosition(dialPosition);
		//Set display value for the dial
		this.dials[dialId].displayValue = this.nf.formatNumber(this.dials[dialId].value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);
		//Set tool text - get the first of tool text, display value	
		//Tool tip gets updated automatically, as the event handler directly accesses data store to get values.
		this.dials[dialId].toolText = getFV(this.dials[dialId].cToolText,this.dials[dialId].displayValue);
		//If we've to update dial's value
		if (this.dials[dialId].showValue){
			this.drawDialValue(dialId, false);
		}
		//Expose event and the value that the dial has been updated.
		if (ExternalInterface.available && this.registerWithJS==true){
			ExternalInterface.call("FC_ChartUpdated", this.DOMId);
		}
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
		//Object to store reference of trend
		var trendObj:Object;
		//Style object to represent trend values
		var trendStyle:Object = this.styleM.getTextStyle(this.objects.TRENDVALUES);
		trendStyle.align = "center";
		trendStyle.vAlign = "middle";
		//Object to store point locations
		var pointLocation:Object, pointLocation2:Object;
		//More variables
		var ax:Number, ay:Number, bx:Number, by:Number;
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
					pointMC._x = this.params.gaugeOriginX;
					pointMC._y = this.params.gaugeOriginY;
					//Arc shaped trend zone
					//Store properties locally for easy and quick access.
					var radius:Number = this.trendPoints[i].radius;
					var innerRadius:Number = this.trendPoints[i].innerRadius;			
					var startAngle:Number = this.trendPoints[i].startAngle;
					var endAngle:Number = this.trendPoints[i].endAngle;
					var sweepAngle:Number = endAngle-startAngle;			
					//Calculate end points (for connecting lines)
					ax = Math.cos(endAngle/180*Math.PI)*innerRadius;
					ay = Math.sin(-endAngle/180*Math.PI)*innerRadius;
					bx = Math.cos(startAngle/180*Math.PI)*radius;
					by = Math.sin(-startAngle/180*Math.PI)*radius;			
					//We'll draw the border and fill separately 			
					//--------- DRAW THE FILL OF ARC FIRST -----------//			
					//Move to the start of gauge
					pointMC.moveTo(bx, by);
					//Set the line style to no lines
					pointMC.lineStyle();
					//Start the fill.
					pointMC.beginFill(parseInt(this.trendPoints[i].color,16), this.trendPoints[i].alpha);
					//Draw outer circle
					DrawingExt.drawCircle(pointMC, 0, 0, radius, radius, startAngle, endAngle-startAngle);
					//Connect via line to inner circle
					pointMC.lineTo(ax, ay);
					//Draw inner circle
					DrawingExt.drawCircle(pointMC, 0, 0, innerRadius, innerRadius, endAngle, -(endAngle-startAngle));
					//Connect back to outer circle
					pointMC.lineTo(bx, by);
					//End the fill.
					pointMC.endFill();
					//--------------------------------------------------------------//
					//Set border propeties
					if (this.trendPoints[i].showBorder){
						//Set line style
						pointMC.lineStyle(this.trendPoints[i].thickness, parseInt(this.trendPoints[i].borderColor,16), this.trendPoints[i].alpha);
						//Draw the outer arc
						DrawingExt.drawCircle(pointMC, 0, 0, radius, radius, startAngle, endAngle-startAngle);
						//Move to left side start of inner circle
						//If it's more than 360, we do not draw any internal line connectors.
						if (Math.abs(sweepAngle)<360) {
							pointMC.lineTo(ax, ay);
						}
						DrawingExt.drawCircle(pointMC, 0, 0, innerRadius, innerRadius, endAngle, -(endAngle-startAngle));
						//Join with outer circle
						if (Math.abs(sweepAngle)<360) {
							pointMC.lineStyle(this.trendPoints[i].thickness, parseInt(this.trendPoints[i].borderColor,16), 100);
							pointMC.lineTo(bx, by);
						}
					}			
				}else{
					//Create movie clip for trend point
					var pointMC:MovieClip = this.cMC.createEmptyMovieClip("TrendPoint_"+i,pointDepth);
					//dashed:Boolean, dashLen:Number, dashGap:Number, 
					pointLocation = MathExt.getAngularPoint(this.params.gaugeOriginX, this.params.gaugeOriginY, this.trendPoints[i].radius, this.trendPoints[i].startAngle);
					pointLocation2 = MathExt.getAngularPoint(this.params.gaugeOriginX, this.params.gaugeOriginY, this.trendPoints[i].innerRadius, this.trendPoints[i].startAngle);
					//Set line style
					pointMC.lineStyle(this.trendPoints[i].thickness, parseInt(this.trendPoints[i].borderColor,16), this.trendPoints[i].alpha);
					//Draw the line now.
					if (this.trendPoints[i].dashed){
						DrawingExt.dashTo(pointMC, pointLocation.x, pointLocation.y, pointLocation2.x, pointLocation2.y, this.trendPoints[i].dashLen, this.trendPoints[i].dashGap);
					}else{
						pointMC.moveTo(pointLocation.x, pointLocation.y);
						pointMC.lineTo(pointLocation2.x, pointLocation2.y);
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
					//Find the position of value text box based on whether it's a trend point/zone
					pointLocation = MathExt.getAngularPoint(this.params.gaugeOriginX, this.params.gaugeOriginY, ((this.trendPoints[i].valueInside)?(this.trendPoints[i].innerRadius-this.params.trendValueDistance):(this.trendPoints[i].radius+this.params.trendValueDistance)), ((this.trendPoints[i].isZone)?(this.trendPoints[i].startAngle + ((this.trendPoints[i].endAngle-this.trendPoints[i].startAngle)/2)):(this.trendPoints[i].startAngle)));
					//Create the text
					trendObj = createText (false, this.trendPoints[i].displayValue, this.cMC, valueDepth, pointLocation.x, pointLocation.y, 0, trendStyle, false, 0, 0);					
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
					DrawingExt.drawPoly(markerMC, 0, 0, 3, this.trendPoints[i].markerRadius, this.trendPoints[i].startAngle+180);
					//Now, position it at the required location
					pointLocation = MathExt.getAngularPoint(this.params.gaugeOriginX, this.params.gaugeOriginY, this.params.gaugeOuterRadius, this.trendPoints[i].startAngle);
					//Set at the required location
					markerMC._x = pointLocation.x;
					markerMC._y = pointLocation.y;
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
	* drawValue method draws the value textboxes for all dials.
	*/
	private function drawValue():Void{		
		//Draw all dial values
		var i:Number
		for (i=1; i<=this.numDials; i++){
			this.drawDialValue(i, true);
		}
		//Clear interval
		clearInterval (this.config.intervals.valueTB);
	}
	/**
	 * drawDialValue method draws the value for a particular dial
	 *	@param	i			Index of dial whose value is to be drawn.
	 *	@param	firstTime	Whether it's being drawn for the first time.
	*/
	private function drawDialValue(i:Number, firstTime:Boolean):Void{		
		//Create local objects.
		var valueObj:Object;
		var depth:Number = this.dm.getDepth("VALUE") + (i-1);
		var valueStyleObj:Object = this.styleCache.dataValue;
		if (this.dials[i].showValue){
			//Render normal label
			valueStyleObj.align = "center";
			valueStyleObj.vAlign = "middle";
			valueObj = createText (false, this.dials[i].displayValue, this.cMC, depth, this.dials[i].valueX, this.dials[i].valueY, 0, valueStyleObj, false, 0, 0);
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
		//Now, data can be provided in two ways to angular gauge chart:
		//&value=12|23|54 or &id_1=12&id_2=23&id_3=54 (where id_x represents "defined" dial-id)
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
		//Iterate through each dial to check for ID based data
		for (i=1; i<=this.numDials; i++){
			if (dt[this.dials[i].id]!=undefined && dt[this.dials[i].id]!=""){
				//Add data to string
				strIDVal = strIDVal + dt[this.dials[i].id];
				//Update flag that we've been provided data using id.
				idDataProvided = true;
				valueProvided = true;
			}
			//Add the pipe character (necessarily for all data - even those whose IDs are
			//not specified), as else if we've missing data in mid, the data in end will be
			//mis-mapped to that of one between.
			strIDVal = strIDVal + ((i<this.numDials)?"|":"");				
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
		//a dial value.
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
			//Make sure that for each of our dials, we've a value in values array (be it actual or NaN)
			for (i=1; i<=this.numDials; i++){
				//Get the value. If it's undefined, set NaN, else actual
				setValue = (values[i-1]==undefined)?(Number("")):(values[i-1]);
				//Update the chart based on this value.
				if (!isNaN(setValue)){
					//If the value has changed at all
					if (this.dials[i].value!=setValue){
						this.updateDial(i,setValue);
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
	 * getIndexFromId method returns the index of a particular dial based on
	 * it's id. If it's not found, -1 is returned.
	 *	@param	id		ID of the dial.
	 *	@return			Numerical index of the dial
	*/
	private function getIndexFromId(id:String):Number{
		//Convert to lower case for case in-sensitive match
		id = id.toLowerCase();
		//Assume that id doesn't exist
		var index = -1;
		//Iterate and find
		var i:Number;
		for (i=1; i<=this.numDials; i++){
			if (this.dials[i].id==id){
				index = i;
				break;
			}
		}
		//Return
		return index;
	}
	/**
	 * getData method returns the data for a particular dial based on index.
	*/
	public function getData(index:Number):Number{
		//If index is within our range
		if (index>0 && index<=this.numDials){
			//Return the value
			return this.dials[index].value;
		}else{
			//Log the error
			this.log("Invalid Index","Invalid dial index " + String(index) + " specified in getData() retrieval method. If you're providing the ID of dial instead of numerical index, please use getDataForId() method.", Logger.LEVEL.ERROR);
			//Return NaN
			return Number("");
		}		
	}
	/**
	 * getDataForId method returns the data for a particular dial based on id.
	*/
	public function getDataForId(id:String):Number{
		//Get the index for the id
		var index:Number = this.getIndexFromId(id);
		//If index is valid
		if (index!=-1){
			//Return the value
			return this.dials[index].value;
		}else{
			//Log the error
			this.log("Invalid Id","Invalid dial id " + id + " specified in getDataForId() retrieval method. If you're providing the numerical index of the dial, please use getData() method.", Logger.LEVEL.ERROR);
			//Return NaN
			return Number("");
		}		
	}
	/**
	 * setData method sets the value for a particular dial using External
	 * interface or external flash movies.
	 *	@param	index	Numerical index of the dial whose value is to be updated.
	 *	@param	value	New value for the dial/
	*/
	public function setData(index:Number, value:Number):Void{
		//If index is within our range
		if (index>0 && index<=this.numDials){
			//Update the dial with new value
			this.updateDial(index, value);
		}else{
			//Log the error
			this.log("Invalid Index","Invalid dial index " + String(index) + " specified in setData() method. If you're providing the ID of dial instead of numerical index, please use setDataForId() method.", Logger.LEVEL.ERROR);
		}		
	}
	/**
	 * setDataForId method sets the value for a particular dial using External
	 * interface or external flash movies. It uses ID instead of index.
	 *	@param	id		Id of the dial whose value is to be updated.
	 *	@param	value	New value for the dial
	*/
	public function setDataForId(id:String, value:Number):Void{
		//Get the index for the id
		var index:Number = this.getIndexFromId(id);
		//If index is within our range
		if (index>0 && index<=this.numDials){
			//Update the dial with new value
			this.updateDial(index, value);
		}else{
			//Log the error
			this.log("Invalid Id","Invalid dial ID " + id + " specified in setDataForId() method. If you're providing the numerical index of the dial, please use setData() method.", Logger.LEVEL.ERROR);
		}		
	}
	// -------------------- EVENT HANDLERS --------------------//
	/**
	* dataOnRollOver is the delegat-ed event handler method that'll
	* be invoked when the user rolls his mouse over a dial.
	* This function is invoked, only if the tool tip is to be shown.
	* Here, we show the tool tip.
	*/
	private function dataOnRollOver():Void {
		//Index of dial is stored in arguments.caller.index
		var toolText:String = this.dials[arguments.caller.index].toolText;
		//Set tool tip text
		this.tTip.setText(toolText);
		//Show the tool tip
		this.tTip.show();
	}	
	/*
	* dataOnMouseMove is called when the mouse position has changed
	* over dial. We reposition the tool tip.
	*/
	private function dataOnMouseMove():Void{
		//Reposition the tool tip only if it's in visible state
		if (this.tTip.visible()){
			this.tTip.rePosition ();
		}
	}
	/**
	* dataOnRollOut method is invoked when the mouse rolls out
	* of dial. We just hide the tool tip here.
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
	* dataOnClick is invoked when the user clicks on a dial (if link
	* has been defined). We invoke the required link.
	*/
	private function dataOnClick():Void {
		//Link of dial is stored in arguments.caller.link
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
		this.dials = new Array();
		this.arrValueTF = new Array();
		this.numDials = 0;
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
		for (i = 1; i <= this.numDials; i++) {
			strData += strQ + this.dials[i].id + strQ + strS + strQ + ((this.params.exportDataFormattedVal==true)?(this.dials[i].displayValue):(this.dials[i].value)) + strQ + ((i<this.numDials)?strLB:""); 
		}
		return strData;
	}
}
