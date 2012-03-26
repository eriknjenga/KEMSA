/**
* @class SparkLineChart
* @author InfoSoft Global(P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright(C) InfoSoft Global Pvt. Ltd. 2005-2006
* SparkLineChart extends the SparkChart class to render the
* functionality of a spart line chart.
*/
//Import parent class
import com.fusioncharts.is.core.SparkChart;
//Error class
import com.fusioncharts.is.helper.FCError;
//Import Logger Class
import com.fusioncharts.is.helper.Logger;
import com.fusioncharts.is.helper.Utils;
//Style Object
import com.fusioncharts.is.core.StyleObject;
//Axis for the chart
import com.fusioncharts.is.axis.LinearAxis;
//Delegate
import mx.utils.Delegate;
//Extensions
import com.fusioncharts.is.extensions.ColorExt;
import com.fusioncharts.is.extensions.StringExt;
import com.fusioncharts.is.extensions.MathExt;
import com.fusioncharts.is.extensions.DrawingExt;
//External Interface - to expose methods via JavaScript
import flash.external.ExternalInterface;
class com.fusioncharts.is.core.charts.SparkLineChart extends SparkChart {
	
	/**
	* Constructor function. We invoke the super class'
	* constructor.
	*/
	function SparkLineChart(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Log additional information to debugger
		//We log version from this class, so that if this class version
		//is different, we can log it
		this.log("Version", _version, Logger.LEVEL.INFO);
		this.log("Chart Type", "Spark Line Chart", Logger.LEVEL.INFO);
		//List Chart Objects and set them in arrObjects array defined in super parent class.
		this.arrObjects = new Array("BACKGROUND", "CANVAS", "CAPTION", "SUBCAPTION", "PLOT", "ANCHORS", "PERIOD", "OPENVALUE", "CLOSEVALUE", "HIGHLOWVALUE", "TRENDLINES", "TOOLTIP");
		super.setChartObjects();		
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
		//If the user has not defined the value, we cannot have the chart.
		if (this.num == 0){
			tfAppMsg = this.renderAppMessage (_global.getAppMessage ("NODATA", this.lang));
			//Add a message to log.
			this.log ("No Data to Display", "No data was found in the XML data document provided. If your system generates data based on parameters passed to it using dataURL, please make sure that dataURL is URL Encoded.", Logger.LEVEL.ERROR);
			//Expose rendered method
			this.exposeChartRendered();
			//Also raise the no data event
			this.raiseNoDataExternalEvent();
		} else {
			//Setup the axis
			this.setupAxis();
			//Set Style defaults
			this.setStyleDefaults();
			//Allot the depths for various charts objects now
			this.allotDepths();
			//Set the container for annotation manager
			this.setupAnnotationMC();
			//Calculate the positions for imaginary canvas
			this.calculateCanvasPoints();			
			//Calculate Points
			this.calculatePoints();			
			//Validate and calculate trend line positions
			this.validateTrendLines();
			//Feed macro values
			this.feedMacros();			
			//Remove application message
			this.removeAppMessage(this.tfAppMsg);
			//Set tool tip parameter
			this.setToolTipParam();
			//Set the context menu
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
			//Draw trend lines			
			this.config.intervals.trend = setInterval(Delegate.create(this, drawTrendLines) , this.timeElapsed);
			//Draw period
			this.config.intervals.period = setInterval(Delegate.create(this, drawPeriod) , this.timeElapsed);
			//Update timer
			this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.TRENDLINES, this.objects.PERIOD):0;			
			//Labels
			this.config.intervals.labels = setInterval(Delegate.create(this, drawLabels) , this.timeElapsed);			
			//Draw the plot
			this.config.intervals.plot = setInterval(Delegate.create(this, drawPlot) , this.timeElapsed);						
			//Update timer
			this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.CAPTION, this.objects.SUBCAPTION, this.objects.PLOT):0;
			//Draw the plot
			this.config.intervals.anchors = setInterval(Delegate.create(this, drawAnchors) , this.timeElapsed);
			//Render the annotations above the chart
			this.config.intervals.annotationsAbove = setInterval(Delegate.create(this, renderAnnotationAbove) , (this.params.annRenderDelay==undefined || isNaN(Number(this.params.annRenderDelay)))?(this.timeElapsed):(Number(this.params.annRenderDelay)*1000));
			//Dispatch event that the chart has loaded.
			this.config.intervals.renderedEvent = setInterval(Delegate.create(this, exposeChartRendered) , this.timeElapsed);			
		}
	}
	/**
	* returnDataAsObject method creates an object out of the parameters
	* passed to this method. The idea is that we store each data point
	* as an object with multiple(flexible) properties. So, we do not
	* use a predefined class structure. Instead we use a generic object.
	*	@param	value		Value for the data.
	*	@return			An object encapsulating all these properies.
	*/
	private function returnDataAsObject(value:Number):Object {
		//Create a container
		var dataObj:Object = new Object();
		//Store the values
		dataObj.value = value;
		//If the given number is not a valid number or it's missing
		//set appropriate flags for this data point
		dataObj.isDefined =((dataObj.alpha == 0) || isNaN(value)) ? false:true;
		//Other parameters
		//X & Y Position of data point
		dataObj.x = 0;
		dataObj.y = 0;
		//Store the formatted display value
		dataObj.displayValue = (dataObj.isDefined)?(this.nf.formatNumber(value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals)):("");
		//Return the container
		return dataObj;
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
				for(j = 0; j < arrLevel1Nodes.length; j ++){
					if(arrLevel1Nodes [j].nodeName.toUpperCase() == "ANNOTATIONS" || arrLevel1Nodes [j].nodeName.toUpperCase() == "CUSTOMOBJECTS"){
						//Parse and store
						this.am.parseXML(arrLevel1Nodes [j]);
					}
				}
				//Iterate through all level 1 nodes.
				for(j = 0; j < arrLevel1Nodes.length; j ++){
					if (arrLevel1Nodes [j].nodeName.toUpperCase() == "DATASET"){						
						//Increment count
						this.numDS++;
						//Dataset node.
						var dataSetNode:XMLNode = arrLevel1Nodes[j];
						//Get attributes array
						var dsAtts:Array = Utils.getAttributesArray(dataSetNode);
						//Create storage object in dataset array						
						this.dataset [this.numDS] = new Object();
						//Create data array under it.
						this.dataset [this.numDS].data = new Array();
						//Get reference to child node.
						var arrLevel2Nodes:Array = arrLevel1Nodes [j].childNodes;
						//Iterate through all child-nodes of DATASET element
						//and search for SET node
						//Counter
						var setCount:Number = 0;
						for(k = 0; k < arrLevel2Nodes.length; k ++){
							if(arrLevel2Nodes [k].nodeName.toUpperCase() == "SET"){
								//Set Node. So extract the data.
								//Update counter
								setCount ++;
								//Get reference to node.
								setNode = arrLevel2Nodes [k];
								//Get attributes
								var atts:Array;
								atts = Utils.getAttributesArray(setNode);
								//Now, get value.
								try{
									var setValue:Number = this.nf.parseValue(atts["value"]);
								} catch (e:Error){
									//If the value is not a number, log a data
									this.log("Invalid data",e.message, Logger.LEVEL.ERROR);
									//Set as NaN - so that we can show it as empty data.
									setValue = Number("");
								}								
								//Store all these attributes as object.
								this.dataset[this.numDS].data[setCount] = this.returnDataAsObject(setValue);
							}
						}
						//Update this.num
						this.num = Math.max(setCount, this.num);
					} else if(arrLevel1Nodes [j].nodeName.toUpperCase() == "STYLES"){
						//Parse the style nodes to extract style information
						this.styleM.parseXML(arrLevel1Nodes[j].childNodes);
					} else if(arrLevel1Nodes [j].nodeName.toUpperCase() == "TRENDLINES"){
						//Parse the trend line nodes
						super.parseTrendLineXML(arrLevel1Nodes [j].childNodes);
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
		// ---------- PADDING AND SPACING RELATED ATTRIBUTES ----------- //
		//Chart Margins - Empty space at the 4 sides
		this.params.chartLeftMargin = getFN(atts["chartleftmargin"], 3);
		this.params.chartRightMargin = getFN(atts["chartrightmargin"], 3);
		this.params.chartTopMargin = getFN(atts["charttopmargin"], 3);
		this.params.chartBottomMargin = getFN(atts["chartbottommargin"], 3);
		//Canvas margins (forced by user)
		this.params.canvasLeftMargin = getFN(atts ["canvasleftmargin"] , -1);
		this.params.canvasRightMargin = getFN(atts ["canvasrightmargin"] , -1);
		// --------------------- CONFIGURATION ------------------------- //
		//Adaptive yMin - if set to true, the min will be based on the values
		//provided. It won't be set to 0 in case of all positive values
		this.params.setAdaptiveYMin = toBoolean(getFN(atts["setadaptiveymin"], 0));
		//The upper and lower limits of y and x axis
		this.params.yAxisMinValue = atts["yaxisminvalue"];
		this.params.yAxisMaxValue = atts["yaxismaxvalue"];
		//Whether null data points are to be connected or left broken
		this.params.connectNullData = toBoolean (getFN (atts ["connectnulldata"] , 0));
		//Whether to set animation for entire chart.
		this.params.animation = toBoolean(getFN(atts["animation"], 1));
		//Whether to set the default chart animation
		this.params.defaultAnimation = toBoolean(getFN(atts["defaultanimation"], 1));
		//Click URL
		this.params.clickURL = getFV(atts["clickurl"], "");
		//Delay in rendering annotations that are over the chart
		this.params.annRenderDelay = atts["annrenderdelay"];
		//--------------- LABELS -----------------//
		this.params.caption = getFV(atts["caption"],"");
		this.params.subCaption = getFV(atts["subcaption"],"");
		//Padding
		this.params.captionPadding = getFN(atts["captionpadding"], 2);		
		// ------------------------- COSMETICS -----------------------------//
		//Background properties - Gradient
		this.params.bgColor = getFV(atts["bgcolor"], this.colorM.get2DBgColor());
		this.params.bgAlpha = getFV(atts["bgalpha"], this.colorM.get2DBgAlpha());
		this.params.bgRatio = getFV(atts["bgratio"], this.colorM.get2DBgRatio());
		this.params.bgAngle = getFV(atts["bgangle"], this.colorM.get2DBgAngle());
		//Border Properties of chart
		this.params.showBorder = toBoolean(getFN(atts["showborder"], 0));
		this.params.borderColor = formatColor(getFV(atts["bordercolor"], this.colorM.get2DBorderColor()));
		this.params.borderThickness = getFN(atts["borderthickness"], 1);
		this.params.borderAlpha = getFN(atts["borderalpha"], this.colorM.get2DBorderAlpha());
		//Font Properties
		this.params.baseFont = getFV(atts["basefont"], "Verdana");
		this.params.baseFontSize = getFN(atts["basefontsize"], 10);
		this.params.baseFontColor = formatColor(getFV(atts["basefontcolor"], this.colorM.get2DBaseFontColor()));		
		//-------------------------- Graph specific properties --------------------------//		
		//Line cosmetic properties
		this.params.lineColor = formatColor(getFV(atts["linecolor"],this.colorM.get2DPlotFillColor()));
		this.params.lineThickness = getFN(atts["linethickness"],1);
		this.params.lineAlpha = getFN(atts["linealpha"],100);
		//Anchor Properties
		this.params.drawAnchors = toBoolean (getFN (atts ["drawanchors"] , atts ["showanchors"] , 0));
		this.params.anchorSides = getFN (atts ["anchorsides"] , 10);
		this.params.anchorRadius = getFN (atts ["anchorradius"] , 2);
		this.params.anchorColor = formatColor (getFV (atts ["anchorcolor"] , this.colorM.get2DPlotFillColor()));
		this.params.anchorAlpha = getFN (atts ["anchoralpha"] , 100);
		//Fill Color for high, low, open and close
		this.params.openColor = formatColor(getFV(atts["opencolor"],"0099FF"));
		this.params.closeColor = formatColor(getFV(atts["closecolor"],"0099FF"));
		this.params.highColor = formatColor(getFV(atts["highcolor"],"00CC00"));
		this.params.lowColor = formatColor(getFV(atts["lowcolor"],"CC0000"));
		//Period length and color
		this.params.periodLength = getFN(atts["periodlength"],-1);
		this.params.periodColor = formatColor(getFV(atts["periodcolor"], this.colorM.getPeriodColor()));
		this.params.periodAlpha = getFN(atts["periodalpha"], 100);
		//Whether to show anchors for open, close, high & low
		this.params.showOpenAnchor = toBoolean(getFN(atts["showopenanchor"], 1));
		this.params.showCloseAnchor = toBoolean(getFN(atts["showcloseanchor"], 1));
		this.params.showHighAnchor = toBoolean(getFN(atts["showhighanchor"], 1));
		this.params.showLowAnchor = toBoolean(getFN(atts["showlowanchor"], 1));
		//Whether to show values
		this.params.showOpenValue = toBoolean(getFN(atts["showopenvalue"], 1));
		this.params.showCloseValue = toBoolean(getFN(atts["showclosevalue"], 1));
		this.params.showHighLowValue = toBoolean(getFN(atts["showhighlowvalue"], 1));
		//Value padding
		this.params.valuePadding = getFN(atts["valuepadding"], 2);
		//Tool Tip - Show/Hide, Background Color, Border Color, Separator Character
		this.params.showToolTip = toBoolean(getFN(atts ["showtooltip"] , atts ["showhovercap"] , 1));
		this.params.toolTipBgColor = formatColor(getFV(atts ["tooltipbgcolor"] , atts ["hovercapbgcolor"] , atts ["hovercapbg"] , this.colorM.get2DToolTipBgColor()));
		this.params.toolTipBorderColor = formatColor(getFV(atts ["tooltipbordercolor"] , atts ["hovercapbordercolor"] , atts ["hovercapborder"] , this.colorM.get2DToolTipBorderColor()));
		// ------------------------- NUMBER FORMATTING ---------------------------- //
		//Option whether the format the number(using Commas)
		this.params.formatNumber = toBoolean(getFN(atts ["formatnumber"] , 1));
		//Option to format number scale
		this.params.formatNumberScale = toBoolean(getFN(atts ["formatnumberscale"] , 1));
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
		//Force Decimal Padding
		this.params.forceDecimals = toBoolean(getFN(atts ["forcedecimals"] , 0));
		//Set up number formatting 
		this.setupNumberFormatting(this.params.numberPrefix, this.params.numberSuffix, this.params.scaleRecursively, this.params.maxScaleRecursion, this.params.scaleSeparator, this.params.defaultNumberScale, this.params.numberScaleValue, this.params.numberScaleUnit, this.params.decimalSeparator, this.params.thousandSeparator, this.params.inDecimalSeparator, this.params.inThousandSeparator);		
	}	
	/**
	* setupAxis method sets the axis for the chart.
	* It gets the minimum and maximum value specified in data and
	* based on that it calls super.getAxisLimits();
	*/
	private function setupAxis():Void {
		this.pAxis = new LinearAxis(this.params.yAxisMinValue, this.params.yAxisMaxValue, false, ! this.params.setAdaptiveYMin, 0, 1, this.nf, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);
		this.pAxis.calculateLimits(this.getMaxDataValue(),this.getMinDataValue());				
	}
	/**
	* setStyleDefaults method sets the default values for styles or
	* extracts information from the attributes and stores them into
	* style objects.
	*/
	private function setStyleDefaults():Void {
		//-----------------------------------------------------------------//
		//Default font object for caption
		//-----------------------------------------------------------------//
		var captionFont = new StyleObject ();
		captionFont.name = "_SdCaptionFontFont";
		captionFont.font = this.params.baseFont;
		captionFont.size = this.params.baseFontSize + 2;
		captionFont.color = this.params.baseFontColor;
		captionFont.bold = "1";
		//Over-ride
		this.styleM.overrideStyle (this.objects.CAPTION, captionFont, this.styleM.TYPE.FONT, null);
		delete captionFont;		
		//-----------------------------------------------------------------//
		//Default font object for sub-caption
		//-----------------------------------------------------------------//
		var subCaptionFont = new StyleObject ();
		subCaptionFont.name = "_SdSubCaptionFont";
		subCaptionFont.font = this.params.baseFont;
		subCaptionFont.size = this.params.baseFontSize;
		subCaptionFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.SUBCAPTION, subCaptionFont, this.styleM.TYPE.FONT, null);
		delete subCaptionFont;
		//-----------------------------------------------------------------//
		//Default font object for high low value
		//-----------------------------------------------------------------//
		var highLowValueFont = new StyleObject ();
		highLowValueFont.name = "_SdHighLowValueFont";
		highLowValueFont.font = this.params.baseFont;
		highLowValueFont.size = this.params.baseFontSize;
		highLowValueFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.HIGHLOWVALUE, highLowValueFont, this.styleM.TYPE.FONT, null);
		delete highLowValueFont;
		//-----------------------------------------------------------------//
		//Default font object for Open value
		//-----------------------------------------------------------------//
		var openValueFont = new StyleObject ();
		openValueFont.name = "_SdOpenValueFont";
		openValueFont.font = this.params.baseFont;
		openValueFont.size = this.params.baseFontSize;
		openValueFont.color = this.params.openColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.OPENVALUE, openValueFont, this.styleM.TYPE.FONT, null);
		delete openValueFont;
		//-----------------------------------------------------------------//
		//Default font object for Close value
		//-----------------------------------------------------------------//
		var closeValueFont = new StyleObject ();
		closeValueFont.name = "_SdCloseValueFont";
		closeValueFont.font = this.params.baseFont;
		closeValueFont.size = this.params.baseFontSize;
		closeValueFont.color = this.params.closeColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.CLOSEVALUE, closeValueFont, this.styleM.TYPE.FONT, null);
		delete closeValueFont;
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
		//-----------------------------------------------------------------//
		//Default Animation objects (if required)
		//-----------------------------------------------------------------//
		if (this.params.defaultAnimation){			
			var dataPlotXSAnim = new StyleObject ();
			dataPlotXSAnim.name = "_SdDataPlotXSAnim";
			dataPlotXSAnim.param = "_xscale";
			dataPlotXSAnim.easing = "regular";
			dataPlotXSAnim.wait = 0;
			dataPlotXSAnim.start = 0;
			dataPlotXSAnim.duration = 0.5;
			//Over-ride
			this.styleM.overrideStyle (this.objects.PLOT, dataPlotXSAnim, this.styleM.TYPE.ANIMATION, "_xscale");
			delete dataPlotXSAnim;
			
			var dataPlotYSAnim = new StyleObject ();
			dataPlotYSAnim.name = "_SdDataPlotYSAnim";
			dataPlotYSAnim.param = "_yscale";
			dataPlotYSAnim.easing = "regular";
			dataPlotYSAnim.wait = 0.7;
			dataPlotYSAnim.start = 0.1;
			dataPlotYSAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.PLOT, dataPlotYSAnim, this.styleM.TYPE.ANIMATION, "_yscale");
			delete dataPlotYSAnim;
			
			//3. Alpha effect for anchors
			var anchorsAnim = new StyleObject ();
			anchorsAnim.name = "_SdDataAnchorAnim";
			anchorsAnim.param = "_alpha";
			anchorsAnim.easing = "regular";
			anchorsAnim.wait = 0;
			anchorsAnim.start = 0;
			anchorsAnim.duration = 0.5;
			//Over-ride
			this.styleM.overrideStyle (this.objects.ANCHORS, anchorsAnim, this.styleM.TYPE.ANIMATION, "_alpha");
			delete anchorsAnim;
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
		//Canvas
		this.dm.reserveDepths ("CANVAS", 1);
		//Period
		this.dm.reserveDepths ("PERIOD", 1);		
		//Caption
		this.dm.reserveDepths ("CAPTION", 1);
		this.dm.reserveDepths ("SUBCAPTION", 1);
		//Plot
		this.dm.reserveDepths ("PLOT", 1);		
		//Anchors
		this.dm.reserveDepths ("ANCHORS", this.num*this.numDS);		
		//Value textboxes
		this.dm.reserveDepths ("OPENVALUE", 1);
		this.dm.reserveDepths ("CLOSEVALUE", 1);
		this.dm.reserveDepths ("HIGHLOWVALUE", 1);
		//Trend lines
		this.dm.reserveDepths ("TRENDLINES", this.numTrendLines);
		//Canvas Border
		this.dm.reserveDepths ("CANVASBORDER", 1);		
		//Annotations above the chart
		this.dm.reserveDepths ("ANNOTATIONABOVE", 1);
	}
	/**
	 * calculateCanvasPoints method calculates the best fit co-ordinates for the invisible canvas
	*/
	private function calculateCanvasPoints():Void{
		//In this function, we calculate the best fit co-ordinates for the canvas.
		//The canvas can have the following objects group both above/below it.		
		//Margins
		//And the following at its side:
		//- canvas margins
		//- Caption
		//- Start Value, End Value, High Low Value
		//We'll calculate the space required and then block the 
		//maximum required. Rest will be alloted to the canvas.
		var canvasStartX:Number, canvasStartY:Number, canvasWidth:Number, canvasHeight:Number;
		// ----------- CANVAS Y & HEIGHT PROPERTIES -----------//
		canvasStartY = this.params.chartTopMargin;
		canvasHeight = this.height - (this.params.chartTopMargin + this.params.chartBottomMargin);
		//Now, we calculate the horizontal space that we've to block
		// -------------- CAPTION & SUB-CAPTION -------------------//
		var textFieldObj:Object;
		var captionWidth:Number = 0;
		var subCaptionWidth:Number = 0;
		var maxCaptionWidth:Number = 0;
		var captionStyle:Object = this.styleM.getTextStyle(this.objects.CAPTION);
		var subCaptionStyle:Object = this.styleM.getTextStyle(this.objects.SUBCAPTION);
		//If caption is to be shown
		if (this.params.caption!=""){
			textFieldObj = createText (true, this.params.caption, this.tfTestMC, 1, testTFX, testTFY, 0, captionStyle, false, 0, 0);
			captionWidth = textFieldObj.width;
		}
		//If sub-caption is to be shown
		if (this.params.subCaption!=""){
			textFieldObj = createText (true, this.params.subCaption, this.tfTestMC, 1, testTFX, testTFY, 0, subCaptionStyle, false, 0, 0);
			subCaptionWidth = textFieldObj.width;
		}
		maxCaptionWidth = Math.max(captionWidth, subCaptionWidth);
		//Add caption padding, if either caption or sub-caption is to be shown
		if (maxCaptionWidth>0){
			maxCaptionWidth = maxCaptionWidth + this.params.captionPadding;
		}
		//Caption can take a maximum of 50% of available width
		maxCaptionWidth = Math.min(maxCaptionWidth, this.width/2);
		//Store it
		this.config.maxCaptionWidth = maxCaptionWidth - this.params.captionPadding;
		//Restrict to 0 (can go to - this.params.captionPadding, if both caption and subcaption are not defined).
		this.config.maxCaptionWidth = Math.max(this.config.maxCaptionWidth, 0);
		//--------------- OPEN/START VALUE --------------------//
		var openValueWidth:Number = 0;
		if (this.params.showOpenValue && this.dataset[1].data[1].isDefined){
			var startValueStyle:Object = this.styleM.getTextStyle(this.objects.OPENVALUE);
			//Create the text field
			textFieldObj = createText (true, this.dataset[1].data[1].displayValue, this.tfTestMC, 1, testTFX, testTFY, 0, startValueStyle, false, 0, 0);
			//Block it's width
			openValueWidth = textFieldObj.width + this.params.valuePadding;
		}
		//------------- CLOSE/END VALUE ------------------//
		var closeValueWidth:Number = 0;
		if (this.params.showCloseValue && this.dataset[1].data[this.num].isDefined){
			var endValueStyle:Object = this.styleM.getTextStyle(this.objects.CLOSEVALUE);
			//Create the text field
			textFieldObj = createText (true, this.dataset[1].data[this.num].displayValue, this.tfTestMC, 1, testTFX, testTFY, 0, endValueStyle, false, 0, 0);
			//Block it's width
			closeValueWidth = textFieldObj.width + this.params.valuePadding;
		}
		//------------------- HIGH/LOW VALUE ---------------------//
		var highLowValueWidth:Number = 0;
		if (this.params.showHighLowValue && this.highestIndex!=undefined && this.lowestIndex!=undefined){
			var highLowValueStyle:Object = this.styleM.getTextStyle(this.objects.HIGHLOWVALUE);
			//Create the text field
			textFieldObj = createText (true, String("[" + this.dataset[1].data[this.highestIndex].displayValue + "|" + this.dataset[1].data[this.lowestIndex].displayValue + "]"), this.tfTestMC, 1, testTFX, testTFY, 0, highLowValueStyle, false, 0, 0);
			//Block it's width
			highLowValueWidth = textFieldObj.width + this.params.valuePadding;
		}
		//---------------- CANVAS X AND WIDTH PROPERTIES -------------//
		canvasStartX = this.params.chartLeftMargin + maxCaptionWidth + openValueWidth;
		canvasWidth = this.width - (this.params.chartLeftMargin + this.params.chartRightMargin + maxCaptionWidth + openValueWidth + closeValueWidth + highLowValueWidth);		
		//------------------ CREATE CANVAS ELEMENT ------------------//
		//Create an element to represent the canvas now.
		//Before doing so, we take into consideration, user's forced canvas margins (if any defined)
		if (this.params.canvasLeftMargin!=-1){
			//Update width (deduct the difference)
			canvasWidth = canvasWidth - (this.params.canvasLeftMargin-canvasStartX);
			//Update left start position
			canvasStartX = this.params.canvasLeftMargin;		
		}
		if (this.params.canvasRightMargin!=-1){
			//Update width (deduct the difference)
			canvasWidth = canvasWidth - (this.params.canvasRightMargin-(this.width - (canvasStartX+canvasWidth)));
		}
		//Now, create the canvas element accordingly.
		this.elements.canvas = this.returnDataAsElement(canvasStartX, canvasStartY, canvasWidth, canvasHeight);
	}
	/**
	 * calculatePoints method calculates all the points for plotting the graph.
	*/
	private function calculatePoints():Void{
		//Loop variable
		var i:Number, j:Number;
		//Set the axis's start and end points
		this.pAxis.setAxisCoords(this.elements.canvas.y, this.elements.canvas.toY);
		//---------- LINE POINT AND SPACING CALCULATION ---------------------//
		//Now, calculate the width between two points on chart
		var interPointWidth : Number = (this.elements.canvas.w) / (this.num - 1);		
		this.config.interPointWidth = interPointWidth;
		// -------------------- INDIVIDUAL DATA ---------------------------------//
		//We now need to calculate the position of line points on the chart.
		for (i=1; i<=this.numDS; i++){
			for (j=1; j<=this.num; j++){
				//Now, if there is only 1 point on the chart, we center it. Else, we get even X.
				this.dataset[i].data[j].x = (this.num == 1) ? (this.elements.canvas.x + this.elements.canvas.w / 2) : (this.elements.canvas.x + (interPointWidth * (j - 1)));
				//Set y position
				this.dataset[i].data[j].y = this.pAxis.getAxisPosition(this.dataset[i].data[j].value, false);
			}
		}
	}
	// -------------------- Visual Rendering Methods ---------------------------//	
	/**
	 * drawLabels method draws the caption.
	*/
	private function drawLabels():Void{
		//Container object
		var textFieldObj:Object;
		//Keeping a track of yShift for placing subcaption
		var yShift:Number = 0;
		//If caption has to be drawn
		if (this.params.caption!=""){
			var captionFont:Object = this.styleM.getTextStyle(this.objects.CAPTION);
			captionFont.align = "right";
			captionFont.vAlign = (this.params.subCaption!="")?"bottom":"middle";
			textFieldObj = createText (false, this.params.caption, this.cMC, this.dm.getDepth("CAPTION"), this.params.chartLeftMargin + this.config.maxCaptionWidth, ((this.params.subCaption!="")?(this.elements.canvas.y - 3):(this.elements.canvas.y + this.elements.canvas.h/2)), 0, captionFont, false, 0, 0);
			//Add to yShift
			yShift = textFieldObj.height + this.params.captionPadding;
			//Apply animation and filters to tick marks
			if (this.params.animation){
				this.styleM.applyAnimation (textFieldObj.tf, this.objects.CAPTION, this.macro, textFieldObj.tf._x, textFieldObj.tf._y, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (textFieldObj.tf, this.objects.CAPTION);
		}
		//If sub-caption has to be drawn
		if (this.params.subCaption!=""){
			var subCaptionFont:Object = this.styleM.getTextStyle(this.objects.SUBCAPTION);
			subCaptionFont.align = "right";
			subCaptionFont.vAlign = "bottom";
			textFieldObj = createText (false, this.params.subCaption, this.cMC, this.dm.getDepth("SUBCAPTION"), this.params.chartLeftMargin + this.config.maxCaptionWidth, this.elements.canvas.y - 3 + yShift, 0, subCaptionFont, false, 0, 0);
			//Apply animation and filters to tick marks
			if (this.params.animation){
				this.styleM.applyAnimation (textFieldObj.tf, this.objects.SUBCAPTION, this.macro, textFieldObj.tf._x, textFieldObj.tf._y, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (textFieldObj.tf, this.objects.SUBCAPTION);
		}
		//------------ OPEN VALUE -------------//
		if (this.params.showOpenValue && this.dataset[1].data[1].isDefined){
			var openValueFont:Object = this.styleM.getTextStyle(this.objects.OPENVALUE);
			openValueFont.align = "right";
			openValueFont.vAlign = "middle";
			textFieldObj = createText (false, this.dataset[1].data[1].displayValue, this.cMC, this.dm.getDepth("OPENVALUE"), this.elements.canvas.x - this.params.valuePadding, this.elements.canvas.y + this.elements.canvas.h/2, 0, openValueFont, false, 0, 0);
			//Apply animation and filters to tick marks
			if (this.params.animation){
				this.styleM.applyAnimation (textFieldObj.tf, this.objects.OPENVALUE, this.macro, textFieldObj.tf._x, textFieldObj.tf._y, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (textFieldObj.tf, this.objects.OPENVALUE);
		}
		//------------ CLOSE VALUE -------------//
		var closeValueWidth:Number = 0;
		if (this.params.showCloseValue && this.dataset[1].data[this.num].isDefined){
			var closeValueFont:Object = this.styleM.getTextStyle(this.objects.CLOSEVALUE);
			closeValueFont.align = "left";
			closeValueFont.vAlign = "middle";
			textFieldObj = createText (false, this.dataset[1].data[this.num].displayValue, this.cMC, this.dm.getDepth("CLOSEVALUE"), this.elements.canvas.toX + this.params.valuePadding, this.elements.canvas.y + this.elements.canvas.h/2, 0, closeValueFont, false, 0, 0);
			//Store width
			closeValueWidth = textFieldObj.width + this.params.valuePadding;
			//Apply animation and filters to tick marks
			if (this.params.animation){
				this.styleM.applyAnimation (textFieldObj.tf, this.objects.CLOSEVALUE, this.macro, textFieldObj.tf._x, textFieldObj.tf._y, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (textFieldObj.tf, this.objects.CLOSEVALUE);
		}
		//------------ HIGH LOW VALUE -------------//
		if (this.params.showHighLowValue && this.highestIndex!=undefined && this.lowestIndex!=undefined){
			var highLowValueFont:Object = this.styleM.getTextStyle(this.objects.HIGHLOWVALUE);
			highLowValueFont.align = "left";
			highLowValueFont.vAlign = "middle";
			highLowValueFont.isHTML = true;
			textFieldObj = createText (false, String("[" + this.dataset[1].data[this.highestIndex].displayValue + "</font>|" + this.dataset[1].data[this.lowestIndex].displayValue + "]"), this.cMC, this.dm.getDepth("HIGHLOWVALUE"), this.elements.canvas.toX + closeValueWidth + this.params.valuePadding, this.elements.canvas.y + this.elements.canvas.h/2, 0, highLowValueFont, false, 0, 0);
			//Re-set the text
			textFieldObj.tf.htmlText = String("<font color='#" + highLowValueFont.color + "'>[</font><font color='#" + this.params.highColor + "'>" + this.dataset[1].data[this.highestIndex].displayValue + "</font><font color='#" + highLowValueFont.color + "'>|</font><font color='#" + this.params.lowColor + "'>" + this.dataset[1].data[this.lowestIndex].displayValue + "</font><font color='#" + highLowValueFont.color + "'>]</font>");
			//----------------------------------------------------------------//
			//Create a text format object and set the properties (again)
			var tFormat:TextFormat = new TextFormat();
			//Font properties
			tFormat.font = highLowValueFont.font;
			tFormat.size = highLowValueFont.size;
			//Text decoration
			tFormat.bold = highLowValueFont.bold;
			tFormat.italic = highLowValueFont.italic;
			tFormat.underline = highLowValueFont.underline;
			//Margin and spacing
			tFormat.leftMargin = highLowValueFont.leftMargin;
			tFormat.letterSpacing = highLowValueFont.letterSpacing;
			//-----------------------------------------------------------------//
			textFieldObj.tf.setTextFormat(tFormat);
			//Apply animation and filters to tick marks
			if (this.params.animation){
				this.styleM.applyAnimation (textFieldObj.tf, this.objects.HIGHLOWVALUE, this.macro, textFieldObj.tf._x, textFieldObj.tf._y, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (textFieldObj.tf, this.objects.HIGHLOWVALUE);
		}
		clearInterval(this.config.intervals.labels);
	}	
	/**
	 * drawPlot method draws the lines on the chart.
	*/
	private function drawPlot():Void{
		/**
		* The movie clip structure for each line (dataset) would be :
		* |- Holder
		* |- |- Chart
		* We create child movie clip as we need to animate xscale
		* and y scale. So, we need to position Chart Movie clip at 0,0
		* inside holder movie clip and then readjust Holder movie clip's
		* X and Y Position as per chart's canvas.
		*/
		var m : Number;
		var depth : Number = this.dm.getDepth ("PLOT");
		for (m = 1; m <= this.numDS; m ++)
		{
			//Create holder movie clip
			var holderMC : MovieClip = this.cMC.createEmptyMovieClip ("ChartHolder_" + m, depth);
			//Create chart movie clip inside holder movie clip
			var chartMC : MovieClip = holderMC.createEmptyMovieClip ("Chart", 1);
			//Set line style
			chartMC.lineStyle (this.params.lineThickness, parseInt(this.params.lineColor, 16), this.params.lineAlpha);
			//Loop variables
			var i, j;
			//Variables to store the max and min Y positions
			var maxY : Number, minY : Number;
			//Find the index of the first defined data
			//Initialize with (this.num+1) so that if no defined data is found,
			//next loop automatically terminates
			var firstIndex : Number = this.num + 1;
			//Storage container for next plot index
			var nxt : Number;
			for (i = 1; i < this.num; i ++)
			{
				if (this.dataset [m].data [i].isDefined)
				{
					firstIndex = i;
					break;
				}
			}
			//Now, we draw the lines inside chart
			for (i = firstIndex; i < this.num; i ++)
			{
				//We continue only if this data index is defined
				if (this.dataset [m].data [i].isDefined)
				{
					//Get next Index
					nxt = i + 1;
					//Now, if next index is not defined, we can have two cases:
					//1. Draw gap between this data and next data.
					//2. Connect the next index which could be found as defined.
					//Case 1. If connectNullData is set to false and next data is not
					//defined. We simply continue to next value of the loop
					if (this.params.connectNullData == false && this.dataset [m].data [nxt].isDefined == false)
					{
						//Discontinuous plot. So ignore and move to next.
						continue;
					}
					//Now, if nxt data is undefined, we need to find the index of the post data
					//which is not undefined
					if (this.dataset [m].data [nxt].isDefined == false)
					{
						//Initiate nxt as -1, so that we can later break if no next defined data
						//could be found.
						nxt = - 1;
						for (j = i + 1; j <= this.num; j ++)
						{
							if (this.dataset [m].data [j].isDefined == true)
							{
								nxt = j;
								break;
							}
						}
						//If nxt is still -1, we break
						if (nxt == - 1)
						{
							break;
						}
					}
					//Move to the point
					chartMC.moveTo (this.dataset [m].data [i].x, this.dataset [m].data [i].y);
					//Draw point to next line
					chartMC.lineTo (this.dataset [m].data [nxt].x, this.dataset [m].data [nxt].y);
					//Get maxY and minY
					maxY = (maxY == undefined || (this.dataset [m].data [i].y > maxY)) ? this.dataset [m].data [i].y : maxY;
					minY = (minY == undefined || (this.dataset [m].data [i].y < minY)) ? this.dataset [m].data [i].y : minY;
					//Update loop index (required when connectNullData is true and there is
					//a sequence of empty sets.) Since we've already found the "next" defined
					//data, we update loop to that to optimize.
					i = nxt - 1;
				}
			}
			//Now, we need to adjust the chart movie clip to 0,0 position as center
			chartMC._x = - (this.elements.canvas.w / 2) - this.elements.canvas.x;
			chartMC._y = - (maxY) + ((maxY - minY) / 2);
			//Set the position of holder movie clip now
			holderMC._x = (this.elements.canvas.w / 2) + this.elements.canvas.x;
			holderMC._y = (maxY) - ((maxY - minY) / 2);
			//Apply filter
			this.styleM.applyFilters (holderMC, this.objects.PLOT);
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (holderMC, this.objects.PLOT, this.macro, holderMC._x, holderMC._y, 100, 100, 100, null);
			}
			//Increment depth
			depth ++;
		}
		clearInterval(this.config.intervals.plot);
	}
	/**
	* drawAnchors method draws the anchors on the chart
	*/
	private function drawAnchors():Void {
		//Variables
		var anchorMC : MovieClip;
		var depth : Number = this.dm.getDepth ("ANCHORS");
		var i : Number, j : Number;
		var anchorColor:String;
		var anchorAlpha:Number;
		//Iterate through all datasets
		for (i = 1; i <= this.numDS; i ++){
			for (j = 1; j <= this.num; j ++){
				//If defined
				if (this.dataset [i].data [j].isDefined){
					//Create an empty movie clip for this anchor
					anchorMC = this.cMC.createEmptyMovieClip ("Anchor_" + i + "_" + j, depth);
					//Determine the anchor color & alpha
					if (this.dataset[i].data[j].highest==true){
						//If it's highest
						anchorColor = this.params.highColor;
						anchorAlpha = (this.params.showHighAnchor)?this.params.anchorAlpha:0;
					}else if (this.dataset[i].data[j].lowest==true){
						//If it's lowest
						anchorColor = this.params.lowColor;
						anchorAlpha = (this.params.showLowAnchor)?this.params.anchorAlpha:0;
					}else if (j==1){
						//If it's opening one
						anchorColor = this.params.openColor;
						anchorAlpha = (this.params.showOpenAnchor)?this.params.anchorAlpha:0;
					}else if (j==this.num){
						//If it's closing one
						anchorColor = this.params.closeColor;
						anchorAlpha = (this.params.showCloseAnchor)?this.params.anchorAlpha:0;
					}else{
						//If it's general
						anchorColor = this.params.anchorColor;
						anchorAlpha = (this.params.drawAnchors)?this.params.anchorAlpha:0;
					}
					//Set the fill
					anchorMC.beginFill(parseInt(anchorColor, 16) , 100);
					//Draw the polygon
					DrawingExt.drawPoly (anchorMC, 0, 0, this.params.anchorSides, this.params.anchorRadius, 45);
					//Set the x and y Position
					anchorMC._x = this.dataset [i].data [j].x;
					anchorMC._y = this.dataset [i].data [j].y;
					//Set the alpha of entire anchor
					anchorMC._alpha = anchorAlpha;
					//Apply animation
					if (this.params.animation){
						this.styleM.applyAnimation (anchorMC, this.objects.ANCHORS, this.macro, anchorMC._x, anchorMC._y, anchorAlpha, 100, 100, null);
					}
					//Apply filters
					this.styleM.applyFilters (anchorMC, this.objects.ANCHORS);
					//Increase depth
					depth ++;
				}
			}
		}
		//Clear interval
		clearInterval (this.config.intervals.anchors);
	}
	/**
	 * drawPeriod method draws the period bars in background if the user has opted for
	 * a period length
	*/
	private function drawPeriod():Void{
		//Proceed only if period length is defined
		if (this.params.periodLength!=-1){
			//Create the movie clip container to hold period rectangles
			var periodMC:MovieClip = this.cMC.createEmptyMovieClip("Period",this.dm.getDepth("PERIOD"));			
			//How many periods can we draw?
			var numPeriods:Number = Math.floor(this.num/this.params.periodLength);
			//Loop variable
			var i:Number;
			//Vars to store start X and end X Positions for periods
			var startX:Number, endX:Number;
			//We jump in alternate step - block of 2
			for (i=1; i<=numPeriods; i=i+2){
				startX = this.dataset[1].data[((i-1)*this.params.periodLength) + 1].x;
				endX = this.dataset[1].data[i*this.params.periodLength].x + (((i*this.params.periodLength)<this.num)?(this.config.interPointWidth):0);
				//Set the fill
				periodMC.beginFill(parseInt(this.params.periodColor,16),this.params.periodAlpha);
				//Draw rectangle
				periodMC.moveTo(startX, this.elements.canvas.y);
				periodMC.lineTo(endX, this.elements.canvas.y);
				periodMC.lineTo(endX, this.elements.canvas.toY);
				periodMC.lineTo(startX, this.elements.canvas.toY);
				periodMC.lineTo(startX, this.elements.canvas.y);
				periodMC.endFill();
			}
		}
		//Clear interval
		clearInterval(this.config.intervals.period);
	}
	// -------------------- EVENT HANDLERS --------------------//		
	/**
	* reInit method re-initializes the chart. This method is basically called
	* when the user changes chart data through JavaScript. In that case, we need
	* to re-initialize the chart, set new XML data and again render.
	*/
	public function reInit():Void {
		//Invoke super class's reInit
		super.reInit();
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
		var i:Number, j:Number;
		//Iterate through each data-items and add it to the output
		for (i = 1; i <= this.num; i ++)
		{
			//Add the individual value for datasets
			for (j = 1; j <= this.numDS; j ++)
			{
				 strData += strQ + ((this.dataset[j].data[i].isDefined==true)?((this.params.exportDataFormattedVal==true)?(this.dataset[j].data[i].displayValue):(this.dataset[j].data[i].value)):(""))  + strQ + ((j<this.numDS)?strS:"");
			}
			if (i < this.num) {
				strData += strLB;
			}
		}
		return strData;
	}
}