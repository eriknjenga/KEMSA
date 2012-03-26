/**
* @class HBulletGraph
* @author InfoSoft Global(P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright(C) InfoSoft Global Pvt. Ltd. 2005-2006
* HBulletGraph extends the BulletChart class to render the
* functionality of a horizontal bullet graph.
*/
//Import parent class
import com.fusioncharts.is.core.BulletChart;
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
//External Interface - to expose methods via JavaScript
import flash.external.ExternalInterface;
class com.fusioncharts.is.core.charts.HBulletGraph extends BulletChart {
	/**
	* Constructor function. We invoke the super class'
	* constructor.
	*/
	function HBulletGraph(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Log additional information to debugger
		//We log version from this class, so that if this class version
		//is different, we can log it
		this.log("Version", _version, Logger.LEVEL.INFO);
		this.log("Chart Type", "Horizontal Bullet Graph", Logger.LEVEL.INFO);
		//List Chart Objects and set them in arrObjects array defined in super parent class.
		this.arrObjects = new Array("BACKGROUND", "CAPTION", "SUBCAPTION", "TICKMARKS", "TICKVALUES", "LIMITVALUES", "PLOT", "COLORRANGE", "TARGET", "TOOLTIP");
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
		if (this.value == undefined || isNaN(this.value)){
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
			//Validate the color ranges
			this.validateColorRange();
			//Set Style defaults
			this.setStyleDefaults();
			//Now, validate target
			this.validateTarget();			
			//Allot the depths for various charts objects now
			this.allotDepths();
			//Set the container for annotation manager
			this.setupAnnotationMC();
			//Set display values
			this.setDisplayValue();
			//Calculate the positions for imaginary canvas
			this.calculateCanvasPoints();			
			//Calculate Points
			this.calculatePoints();			
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
			//Draw the color range
			this.config.intervals.colorRange = setInterval(Delegate.create(this, drawColorRange) , this.timeElapsed);
			//Update timer
			this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.COLORRANGE):0;			
			//Labels
			this.config.intervals.labels = setInterval(Delegate.create(this, drawLabels) , this.timeElapsed);
			//Draw tick marks
			this.config.intervals.tickMarks = setInterval(Delegate.create(this, drawTicks) , this.timeElapsed);						
			//Update timer
			this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.CAPTION, this.objects.SUBCAPTION, this.objects.LIMITVALUES, this.objects.TICKMARKS, this.objects.TICKVALUES):0;
			//Draw the plot
			this.config.intervals.plot = setInterval(Delegate.create(this, drawPlot) , this.timeElapsed);						
			//Pointer values
			this.config.intervals.valueTB = setInterval(Delegate.create(this, drawValue) , this.timeElapsed);			
			//Update timer
			this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.PLOT, this.objects.VALUE):0;
			//Draw trend lines			
			this.config.intervals.target = setInterval(Delegate.create(this, drawTarget) , this.timeElapsed);						
			//Render the annotations above the chart
			this.config.intervals.annotationsAbove = setInterval(Delegate.create(this, renderAnnotationAbove) , (this.params.annRenderDelay==undefined || isNaN(Number(this.params.annRenderDelay)))?(this.timeElapsed):(Number(this.params.annRenderDelay)*1000));
			//Dispatch event that the chart has loaded.
			this.config.intervals.renderedEvent = setInterval(Delegate.create(this, exposeChartRendered) , this.timeElapsed);			
		}
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
						//Add value to our class store
						this.value = pValue;
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "TARGET") {
						var pTarget:Number;
						//Now, get value.
						try {
							var pTarget:Number = this.nf.parseValue(arrLevel1Nodes[j].childNodes[0].nodeValue);
						} catch (e:Error) {
							//If the value is not a number, log a data
							this.log("Invalid data", e.message, Logger.LEVEL.ERROR);
							//Set as NaN - so that we can show it as empty data.
							pTarget = Number("");
						}
						//Add target to our class store
						this.target = pTarget;
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "STYLES") {
						//Parse the style nodes to extract style information
						this.styleM.parseXML(arrLevel1Nodes[j].childNodes);
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
		// ---------- PADDING AND SPACING RELATED ATTRIBUTES ----------- //
		//Chart Margins - Empty space at the 4 sides
		this.params.chartLeftMargin = getFN(atts["chartleftmargin"], 10);
		this.params.chartRightMargin = getFN(atts["chartrightmargin"], 15);
		this.params.chartTopMargin = getFN(atts["charttopmargin"], 5);
		this.params.chartBottomMargin = getFN(atts["chartbottommargin"], 5);
		//Canvas margins (forced by user)
		this.params.canvasLeftMargin = getFN(atts ["canvasleftmargin"] , -1);
		this.params.canvasRightMargin = getFN(atts ["canvasrightmargin"] , -1);
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
		//Delay in rendering annotations that are over the chart
		this.params.annRenderDelay = atts["annrenderdelay"];
		//--------------- LABELS -----------------//
		this.params.caption = getFV(atts["caption"],"");
		this.params.subCaption = getFV(atts["subcaption"],"");
		//Padding
		this.params.captionPadding = getFN(atts["captionpadding"], 2);		
		//Whether to show shadow for the graph
		this.params.showShadow = toBoolean(getFN(atts["showshadow"], 1));
		//---------- PLACEMENT OF VARIOUS OBJECTS W.R.T GRAPH ------------//
		//Whether to show ticks above chart or below graph
		this.params.ticksBelowGraph = toBoolean(getFN(atts["ticksbelowgraph"], 1));
		//Whether to show value
		this.params.showValue = toBoolean(getFN(atts["showvalue"], 0));
		//Value padding
		this.params.valuePadding = getFN(atts["valuepadding"], 4);				
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
		this.params.majorTMHeight = getFN(atts["majortmheight"], 4);
		this.params.majorTMThickness = getFN(atts["majortmthickness"], 1);
		this.params.minorTMNumber = getFN(atts["minortmnumber"], 0);
		this.params.minorTMColor = formatColor(getFV(atts["minortmcolor"], this.params.majorTMColor));
		this.params.minorTMAlpha = getFN(atts["minortmalpha"], this.params.majorTMAlpha);
		this.params.minorTMHeight = getFN(atts["minortmheight"], Math.round(this.params.majorTMHeight/2));
		this.params.minorTMThickness = getFN(atts["minortmthickness"], 1);
		//Padding between tick mark start position and graph
		this.params.tickMarkDistance = getFN(atts["tickmarkdistance"], atts["tickmarkgap"], (this.params.showShadow)?1:0);		
		//Tick value distance
		this.params.tickValueDistance = getFN(atts["tickvaluedistance"], atts["displayvaluedistance"], 0);
		//Tick value step
		this.params.tickValueStep = int(getFN(atts["tickvaluestep"], atts["tickvaluesstep"], 1));
		//Cannot be less than 1
		this.params.tickValueStep = (this.params.tickValueStep<1) ? 1 : this.params.tickValueStep;
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
		//-------------------------- Graph specific properties --------------------------//
		//Color Range fill properties
		this.params.colorRangeFillMix = atts["colorrangefillmix"];
		this.params.colorRangeFillRatio = atts["colorrangefillratio"];
		//Set defaults
		if (this.params.colorRangeFillMix == undefined) {
			this.params.colorRangeFillMix = "{light-10},{dark-10},{light-10},{dark-10}";
		}
		if (this.params.colorRangeFillRatio == undefined) {
			this.params.colorRangeFillRatio = "0,10,80,10";
		} 
		//Color Range Border properties  
		this.params.showColorRangeBorder = toBoolean(getFN(atts["showcolorrangeborder"], 0));
		this.params.colorRangeBorderColor = formatColor(getFV(atts["colorrangebordercolor"], "{dark-10}"));
		this.params.colorRangeBorderThickness = getFN(atts["colorrangeborderthickness"], 1);
		this.params.colorRangeBorderAlpha = getFN(atts["colorrangeborderalpha"], 100);
		
		//Whether to use dot as indicator
		this.params.plotAsDot = toBoolean(getFN(atts["plotasdot"], 0));
		
		//Bar (plot) properties
		this.params.plotFillPercent = Math.round(getFN(atts["plotfillpercent"], (this.params.plotAsDot)?25:40));
		this.params.targetFillPercent = getFN(atts["targetfillpercent"], this.params.plotFillPercent + 20);	
		
		//Cannot be less than 5 and more than 100
		this.params.plotFillPercent = Math.max(this.params.plotFillPercent, 5);
		this.params.plotFillPercent = Math.min(this.params.plotFillPercent, 100);
		
		this.params.targetFillPercent = Math.min(this.params.targetFillPercent,100);
		
		this.params.plotFillColor = formatColor(getFV(atts["plotfillcolor"], this.colorM.get2DPlotFillColor()));
		this.params.plotFillAlpha = getFN(atts["plotfillalpha"], 100);
		this.params.showPlotBorder = toBoolean(getFN(atts["showplotborder"], 0));
		this.params.plotBorderColor = formatColor(getFV(atts["plotbordercolor"], "{dark-20}"));
		this.params.plotBorderThickness = getFN(atts["plotborderthickness"], 1);
		this.params.plotBorderAlpha = getFN(atts["plotborderalpha"], 100);
		
		//Target properties
		this.params.targetColor = formatColor(getFV(atts["targetcolor"], this.colorM.getTrendColor()));
		this.params.targetThickness = getFN(atts["targetthickness"], 3);

		//Round radius - if graph is to be drawn as rounded
		this.params.roundRadius = getFN(atts["roundradius"], 0);
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
		subCaptionFont.name = "_SdSubCaptionFontFont";
		subCaptionFont.font = this.params.baseFont;
		subCaptionFont.size = this.params.baseFontSize;
		subCaptionFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.SUBCAPTION, subCaptionFont, this.styleM.TYPE.FONT, null);
		delete subCaptionFont;
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
		// Shadow for Color Range
		//------------------------------------------------------------------//
		if (this.params.showShadow){
			var rangeShadow = new StyleObject ();
			rangeShadow.name = "_SdRangeShadow";
			rangeShadow.alpha = "100";
			//Over-ride
			this.styleM.overrideStyle (this.objects.COLORRANGE, rangeShadow, this.styleM.TYPE.SHADOW, null);
		}
		//-----------------------------------------------------------------//
		//Default Animation objects (if required)
		//-----------------------------------------------------------------//
		if (this.params.defaultAnimation){			
			//Animation for color range
			var crXSAnim = new StyleObject ();
			crXSAnim.name = "_SdColorRangeXScaleAnim";
			crXSAnim.param = "_xscale";
			crXSAnim.easing = "regular";
			crXSAnim.wait = 0;
			crXSAnim.start = 0;
			crXSAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.COLORRANGE, crXSAnim, this.styleM.TYPE.ANIMATION, "_xscale");
			delete crXSAnim;			
			
			//Y-scale animation for color range
			var crYSAnim = new StyleObject ();
			crYSAnim.name = "_SdColorRangeYScaleAnim";
			crYSAnim.param = "_yscale";
			crYSAnim.easing = "regular";
			crYSAnim.wait = 0.7;
			crYSAnim.start = 5;
			crYSAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.COLORRANGE, crYSAnim, this.styleM.TYPE.ANIMATION, "_yscale");
			delete crYSAnim;			
			
			//Plot animation
			if (this.params.plotAsDot){
				//Simple x shift animation
				var plotXAnim = new StyleObject ();
				plotXAnim.name = "_SdPlotXAnim";
				plotXAnim.param = "_x";
				plotXAnim.easing = "regular";
				plotXAnim.wait = 0;
				plotXAnim.start = "$canvasStartX";
				plotXAnim.duration = 0.7;
				//Over-ride
				this.styleM.overrideStyle (this.objects.PLOT, plotXAnim, this.styleM.TYPE.ANIMATION, "_x");
				delete plotXAnim;
			}else{
				//XScale animation
				var plotXSAnim = new StyleObject ();
				plotXSAnim.name = "_SdPlotXScaleAnim";
				plotXSAnim.param = "_xscale";
				plotXSAnim.easing = "regular";
				plotXSAnim.wait = 0;
				plotXSAnim.start = 0;
				plotXSAnim.duration = 0.7;
				//Over-ride
				this.styleM.overrideStyle (this.objects.PLOT, plotXSAnim, this.styleM.TYPE.ANIMATION, "_xscale");
				delete plotXSAnim;
			}
			
			//Amimation for target - xshift
			var targetXAnim = new StyleObject ();
			targetXAnim.name = "_SdTargetXAnim";
			targetXAnim.param = "_x";
			targetXAnim.easing = "regular";
			targetXAnim.wait = 0;
			targetXAnim.start = "$canvasStartX";
			targetXAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.TARGET, targetXAnim, this.styleM.TYPE.ANIMATION, "_x");
			delete targetXAnim;
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
		//Color range
		this.dm.reserveDepths ("COLORRANGE", 1);
		//Tick Marks
		this.dm.reserveDepths ("TICKMARKS", 1);		
		//Tick values
		this.dm.reserveDepths ("TICKVALUES", this.majorTM.length+1);
		//Caption and sub-caption
		this.dm.reserveDepths ("CAPTION", 1);
		this.dm.reserveDepths ("SUBCAPTION", 1);
		//Plot
		this.dm.reserveDepths ("PLOT", 1);
		//Target
		this.dm.reserveDepths ("TARGET", 1);
		//Value text box
		this.dm.reserveDepths ("VALUE", 1);		
		//Annotations above the chart
		this.dm.reserveDepths ("ANNOTATIONABOVE", 1);
	}
	/**
	 * calculateCanvasPoints method calculates the best fit co-ordinates for the invisible canvas
	*/
	private function calculateCanvasPoints():Void{
		//In this function, we calculate the best fit co-ordinates for the canvas.
		//The (color range) can have the following objects group both above/below it.		
		//Tick Padding + Tick Marks Height + Tick Value Padding + Tick Values Height
		//We'll calculate the top and bottom space required and then block the 
		//maximum required. Rest will be alloted to the canvas.
		var canvasStartX:Number, canvasStartY:Number, canvasWidth:Number, canvasHeight:Number;
		//Variables to store top and bottom space required
		var tickTopHeight:Number = 0;
		var tickBottomHeight:Number = 0;
		//Now, do group wise calculation
		var i:Number, j:Number;
		var calcHolder:Number;
		//------------- TICK MARKS, VALUES, PADDING -------------//
		var tickMarkHeight:Number = 0;
		var tickValueHeight:Number = 0;
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
					tickValueHeight = Math.max(tickValueHeight, tickValueObj.height);
				}
			}
			//Add the padding
			tickValueHeight = tickValueHeight + this.params.tickValueDistance;
		}
		//Now, calculate the tick marks height
		if (this.params.showTickMarks){
			tickMarkHeight = Math.max(this.params.majorTMHeight, this.params.minorTMHeight) + this.params.tickMarkDistance;
		}
		//Now, based on where we've to position the ticks, allot the space
		if (this.params.ticksBelowGraph){
			tickBottomHeight = tickMarkHeight + tickValueHeight;
		}else{
			tickTopHeight = tickMarkHeight + tickValueHeight;
		}
		// ----------- CANVAS Y & HEIGHT PROPERTIES -----------//
		canvasStartY = this.params.chartTopMargin+ tickTopHeight;
		canvasHeight = this.height - (this.params.chartTopMargin + this.params.chartBottomMargin + tickTopHeight + tickBottomHeight);
		
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
		//------------- VALUE TEXT BOX --------------//		
		var valueObj:Object;
		var valueWidth:Number = 0;
		var valueStyle:Object = this.styleM.getTextStyle(this.objects.VALUE);
		if (this.params.showValue){
			valueObj = createText (true, this.valueDisplay, this.tfTestMC, 1, testTFX, testTFY, 0, valueStyle, false, 0, 0);
			valueWidth = valueObj.width + this.params.valuePadding;
		}

		//---------------- CANVAS X AND WIDTH PROPERTIES -------------//
		canvasStartX = this.params.chartLeftMargin + maxCaptionWidth;
		canvasWidth = this.width - (this.params.chartLeftMargin + this.params.chartRightMargin + maxCaptionWidth + valueWidth);
		
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
		var i:Number;
		//Set the axis's start and end points
		this.pAxis.setAxisCoords(this.elements.canvas.x, this.elements.canvas.toX);
		
		//Calculate the span x-range for each of the color range segment
		for (i=1; i<=this.numCR; i++) {
			this.colorR[i].fromX = this.pAxis.getAxisPosition((i==1)?this.pAxis.getMin():this.colorR[i].minValue);
			this.colorR[i].toX = this.pAxis.getAxisPosition((i==this.numCR)?this.pAxis.getMax():this.colorR[i].maxValue);
		}
		//Calculate the base position (from where bars would emanate)
		//Can be 3 cases, if min,max<0, min<0, max>=0, min>0, max>0
		if (this.pAxis.getMin()<0 && this.pAxis.getMax()<0){
			//Bars would emanate from right. So keep base position as that of max
			this.config.basePos = this.pAxis.getAxisPosition(this.pAxis.getMax());
		}else if (this.pAxis.getMin()<0 && this.pAxis.getMax()>=0){
			//Bars should emanate from 0
			this.config.basePos = this.pAxis.getAxisPosition(0);
		}else{
			//Else, bars should emanate from min value
			this.config.basePos = this.pAxis.getAxisPosition(this.pAxis.getMin());
		}
		//Also, calculate the position of the value and trend
		this.config.valuePos = this.pAxis.getAxisPosition(this.value);
		if (this.showTarget){
			this.config.targetPos = this.pAxis.getAxisPosition(this.target);
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
		//Canvas related macros		
		this.macro.addMacro ("$canvasStartX", this.elements.canvas.x);
		this.macro.addMacro ("$canvasEndX", this.elements.canvas.toX);		
		this.macro.addMacro ("$canvasStartY", this.elements.canvas.y);
		this.macro.addMacro ("$canvasEndY", this.elements.canvas.toY);		
	}
	// -------------------- Visual Rendering Methods ---------------------------//	
	/**
	 * drawColorRange method draws the base (color range) of the graph
	*/
	private function drawColorRange(){
		//Loop var
		var i:Number;
		//Storage for colors
		var crColor:Array, crAlpha:Array, crRatio:Array;		
		var arrBorderColor:Array, borderColor:Number;
		//Create a movie clip for this
		var crMC:MovieClip = this.cMC.createEmptyMovieClip("ColorRange",this.dm.getDepth("COLORRANGE"));
		var colorRangeWidth:Number;
		var colorRangeRelativeX:Number;
		var borderColor:Number, borderAlpha:Number;
		//Set it's start position
		crMC._x = this.elements.canvas.x;
		crMC._y = this.elements.canvas.y + this.elements.canvas.h/2;
		//Create each color range with it's own properties, but inside the color range movie clip.
		for (i=1; i<=this.numCR; i++){
			//Width of the color range
			colorRangeWidth = this.colorR[i].toX - this.colorR[i].fromX;
			colorRangeRelativeX = this.colorR[i].fromX - this.elements.canvas.x;
			//Parse the color, alpha and ratio array for each color range arc.
			crColor = ColorExt.parseColorMix(this.colorR[i].color, this.params.colorRangeFillMix);			
			crAlpha = ColorExt.parseAlphaList(this.colorR[i].alpha, crColor.length);
			crRatio = ColorExt.parseRatioList(this.params.colorRangeFillRatio, crColor.length);
			//Create matrix object
			var matrix:Object = {matrixType:"box", w:colorRangeWidth, h:this.elements.canvas.h, x:colorRangeRelativeX, y:-(this.elements.canvas.h)/2, r:-Math.PI/2};
			//Draw rounded rectangle
			//Set border propeties
			if (this.params.showColorRangeBorder){
				//Which border color to use - between actual color and color mix specified?
				if (this.colorR[i].borderColor.indexOf("{")==-1){
					borderColor = parseInt(this.colorR[i].borderColor,16);
				} else {
					arrBorderColor = ColorExt.parseColorMix(this.colorR[i].color, this.colorR[i].borderColor);
					borderColor = arrBorderColor[0];
				}				
				//Set line style
				crMC.lineStyle(this.params.colorRangeBorderThickness, borderColor, this.colorR[i].borderAlpha);
				//Store in local var
				borderAlpha = this.colorR[i].borderAlpha;
			}else{
				borderAlpha = 0;
			}
			//Start the fill.			
			crMC.beginGradientFill ("linear", crColor, crAlpha, crRatio, matrix);
			//Draw rounded rectangle
			DrawingExt.drawRoundedRect(crMC, colorRangeRelativeX, -(this.elements.canvas.h)/2, colorRangeWidth, this.elements.canvas.h, {tl:((i==1)?this.params.roundRadius:0), tr:((i==this.numCR)?this.params.roundRadius:0), bl:((i==1)?this.params.roundRadius:0), br:((i==this.numCR)?this.params.roundRadius:0)}, {l:borderColor, r:borderColor, t:borderColor, b:borderColor}, {l:borderAlpha, r:borderAlpha, t:borderAlpha, b:borderAlpha}, {l:this.params.colorRangeBorderThickness, r:this.params.colorRangeBorderThickness, b:this.params.colorRangeBorderThickness, t:this.params.colorRangeBorderThickness});
			//End the fill.
			crMC.endFill();
			//-------------------------------------------------------------//			
		}
		//Apply animation and filter effects
		if (this.params.animation){
			this.styleM.applyAnimation (crMC, this.objects.COLORRANGE, this.macro, crMC._x, crMC._y, 100, 100, 100, null);
		}
		//Apply filters
		this.styleM.applyFilters (crMC, this.objects.COLORRANGE);
		//Clear Interval
		clearInterval(this.config.intervals.colorRange);
	}
	/**
	 * drawTicks method draws the tick marks and all their values for the chart.
	*/
	private function drawTicks():Void{
		//Calculate the y position for tick marks - based on ticksBelowGraph & placeTicksInside
		var ticksY:Number, tickValuesY:Number;
		var tickValueVAlign:String;
		//Maximum tick height - based on which tick is bigger
		var maxTickHeight:Number = (this.params.showTickMarks)?(Math.max(this.params.majorTMHeight, this.params.minorTMHeight)):(0);
		//Multiply factor to indicate which direction the ticks would extend to
		var multiplyF:Number;
		if (this.params.ticksBelowGraph){
			//Ticks below graph - ticks outside - value outside
			ticksY = this.elements.canvas.toY + this.params.tickMarkDistance;
			multiplyF = 1;
			//Position for tick values
			tickValuesY = this.elements.canvas.toY + ((this.params.showTickMarks)?this.params.tickMarkDistance:0) + maxTickHeight + this.params.tickValueDistance;
			tickValueVAlign = "bottom";
		}else{
			//Ticks above graph - ticks outside - value outside					
			ticksY = this.elements.canvas.y - this.params.tickMarkDistance;
			multiplyF = -1;			
			//Position for tick values
			tickValuesY = this.elements.canvas.y - ((this.params.showTickMarks)?this.params.tickMarkDistance:0) - maxTickHeight - this.params.tickValueDistance;
			tickValueVAlign = "top";
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
			//tickMC.moveTo(this.elements.canvas.x, tickStartY);
			//tickMC.lineTo(this.elements.canvas.toX, tickStartY);
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
	 * drawLabels method draws the caption and sub-caption.
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
			captionFont.vAlign = "bottom";
			textFieldObj = createText (false, this.params.caption, this.cMC, this.dm.getDepth("CAPTION"), this.elements.canvas.x - this.params.captionPadding, this.elements.canvas.y - 3, 0, captionFont, false, 0, 0);
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
			textFieldObj = createText (false, this.params.subCaption, this.cMC, this.dm.getDepth("SUBCAPTION"), this.elements.canvas.x - this.params.captionPadding, this.elements.canvas.y - 3 + yShift, 0, subCaptionFont, false, 0, 0);
			//Apply animation and filters to tick marks
			if (this.params.animation){
				this.styleM.applyAnimation (textFieldObj.tf, this.objects.SUBCAPTION, this.macro, textFieldObj.tf._x, textFieldObj.tf._y, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (textFieldObj.tf, this.objects.SUBCAPTION);
		}
		clearInterval(this.config.intervals.labels);
	}
	/*
	 * drawPlot method draws the plot on the chart.
	*/
	private function drawPlot():Void{
		//Create a movie clip to contain the plot
		var plotMC:MovieClip = this.cMC.createEmptyMovieClip("Plot",this.dm.getDepth("PLOT"));		
		//Plot height
		var plotHeight:Number = (this.params.plotFillPercent/100)*this.elements.canvas.h;
		//Calculate border properties
		var plotBorderColor:Number;
		if (this.params.showPlotBorder){
			//Which border color to use - between actual color and color mix specified?
			if (this.params.plotBorderColor.indexOf("{")==-1){
				plotBorderColor = parseInt(this.params.plotBorderColor,16);
			} else {
				var arrBorderColor:Array = ColorExt.parseColorMix(this.params.plotFillColor, this.params.plotBorderColor);
				plotBorderColor = arrBorderColor[0];
			}
			//Set the line style
			plotMC.lineStyle(this.params.plotBorderThickness, plotBorderColor, this.params.plotBorderAlpha);				
		}
		//Set fill
		plotMC.beginFill(parseInt(this.params.plotFillColor,16), this.params.plotFillAlpha);
		
		//Now, draw the movie clip, based on what we've to draw
		if (this.params.plotAsDot){
			//Draw a simple rectangle			
			//Draw the rectangle at required place
			DrawingExt.drawRoundedRect(plotMC, -(plotHeight/2), -(plotHeight/2), plotHeight, plotHeight, {tl:0, tr:0, bl:0, br:0}, {l:plotBorderColor, r:plotBorderColor, t:plotBorderColor, b:plotBorderColor}, {l:this.params.plotBorderAlpha, r:this.params.plotBorderAlpha, t:this.params.plotBorderAlpha, b:this.params.plotBorderAlpha}, {l:this.params.plotBorderThickness, r:this.params.plotBorderThickness, b:this.params.plotBorderThickness, t:this.params.plotBorderThickness});
			//Shift the movie clip
			plotMC._x = this.config.valuePos;
			plotMC._y = this.elements.canvas.y + this.elements.canvas.h/2;
		}else{
			//We need to plot it as rectangle
			var rectWidth:Number = this.config.valuePos - this.config.basePos;
			//Draw the bar
			DrawingExt.drawRoundedRect(plotMC, 0, -(plotHeight/2), rectWidth, plotHeight, {tl:0, tr:0, bl:0, br:0}, {l:plotBorderColor, r:plotBorderColor, t:plotBorderColor, b:plotBorderColor}, {l:this.params.plotBorderAlpha, r:this.params.plotBorderAlpha, t:this.params.plotBorderAlpha, b:this.params.plotBorderAlpha}, {l:this.params.plotBorderThickness, r:this.params.plotBorderThickness, b:this.params.plotBorderThickness, t:this.params.plotBorderThickness});
			//Shift the movie clip
			plotMC._x = this.config.basePos;
			plotMC._y = this.elements.canvas.y + this.elements.canvas.h/2;
		}
		//------------- TOOL TIP ----------------//
		if (this.params.showToolTip){
			//Function reference containers		
			var fnRollOver:Function;
			//Create Delegate for roll over function showToolText
			fnRollOver = Delegate.create (this, showToolText);
			//Set the tool text 
			fnRollOver.toolText = this.valueDisplay;
			//No hand cursor
			plotMC.useHandCursor = false;
			//Assing the delegates to movie clip handler
			plotMC.onRollOver = fnRollOver;
			//Set roll out and mouse move too.
			plotMC.onRollOut = plotMC.onReleaseOutside = Delegate.create (this, hideToolText);
			plotMC.onMouseMove = Delegate.create(this, positionToolText);
		}
		// ----------------------------------------//
		//Apply filters and animation
		if (this.params.animation){
			this.styleM.applyAnimation (plotMC, this.objects.PLOT, this.macro, plotMC._x, plotMC._y, 100, 100, 100, null);
		}
		//Apply filters
		this.styleM.applyFilters (plotMC, this.objects.PLOT);
		//Clear Interval
		clearInterval(this.config.intervals.plot);
	}
	/**
	 * drawTarget method draws the target for the chart.
	*/
	private function drawTarget():Void{
		//If we've to show target
		if (this.showTarget){
			//Create a movie clip to contain the target
			var targetMC:MovieClip = this.cMC.createEmptyMovieClip("Target",this.dm.getDepth("TARGET"));		
			//Target height
			var targetHeight:Number = (this.params.targetFillPercent/100)*this.elements.canvas.h;
			//Set line style
			targetMC.lineStyle(this.params.targetThickness, parseInt(this.params.targetColor,16), 100);
			targetMC.moveTo(0,-targetHeight/2);
			targetMC.lineTo(0,targetHeight/2);
			//Shift the entire line
			targetMC._x = this.config.targetPos;
			targetMC._y = this.elements.canvas.y + this.elements.canvas.h/2;
			//------------- TOOL TIP ----------------//
			if (this.params.showToolTip){
				//Function reference containers		
				var fnRollOver:Function;
				//Create Delegate for roll over function showToolText
				fnRollOver = Delegate.create (this, showToolText);
				//Set the tool text 
				fnRollOver.toolText = this.targetDisplay;
				//No hand cursor
				targetMC.useHandCursor = false;
				//Assing the delegates to movie clip handler
				targetMC.onRollOver = fnRollOver;
				//Set roll out and mouse move too.
				targetMC.onRollOut = targetMC.onReleaseOutside = Delegate.create (this, hideToolText);
				targetMC.onMouseMove = Delegate.create(this, positionToolText);
			}
			// ----------------------------------------//
			//Apply filters and animation
			if (this.params.animation){
				this.styleM.applyAnimation (targetMC, this.objects.TARGET, this.macro, targetMC._x, targetMC._y, 100, 100, 100, null);
			}
			//Apply filters
			this.styleM.applyFilters (targetMC, this.objects.TARGET);
		}
		//Clear Interval
		clearInterval(this.config.intervals.target);
	}
	/**
	 * drawValue method draws the value of the chart.
	*/
	private function drawValue():Void{
		//If the value is to be shown
		if (this.params.showValue){
			//Create local objects.
			var valueObj:Object;
			var valueStyleObj:Object = this.styleM.getTextStyle(this.objects.VALUE);
			valueStyleObj.align = "left";
			valueStyleObj.vAlign = "middle";
			valueObj = createText (false, this.valueDisplay, this.cMC, this.dm.getDepth("VALUE"), this.elements.canvas.toX + this.params.valuePadding, this.elements.canvas.y + this.elements.canvas.h/2, 0, valueStyleObj, false, 0, 0);
			//Apply filter
			this.styleM.applyFilters(valueObj.tf, this.objects.VALUE);
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (valueObj.tf, this.objects.VALUE, this.macro, valueObj.tf._x, valueObj.tf._y, 100, null, null, null);
			}
		}
		//Clear Interval
		clearInterval(this.config.intervals.valueTB);
	}
	// -------------------- EVENT HANDLERS --------------------//	
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
		//Add the labels
		strData = strQ + ((this.params.caption!="")?(this.params.caption):("Value")) + strQ + strS + strQ + "Target" + strQ + strLB;
		//Add the value and target
		strData += strQ + ((this.params.exportDataFormattedVal==true)?(this.valueDisplay):(this.value)) + strQ + strS + strQ + ((this.showTarget==true)?((this.params.exportDataFormattedVal==true)?(this.targetDisplay):(this.target)):("")) + strQ; 		
		return strData;
	}
}
