/**
* @class SparkColumnChart
* @author InfoSoft Global(P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright(C) InfoSoft Global Pvt. Ltd. 2005-2006
* SparkColumnChart extends the SparkChart class to render the
* functionality of a spart column chart.
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
class com.fusioncharts.is.core.charts.SparkColumnChart extends SparkChart {
	/**
	* Constructor function. We invoke the super class'
	* constructor.
	*/
	function SparkColumnChart(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Log additional information to debugger
		//We log version from this class, so that if this class version
		//is different, we can log it
		this.log("Version", _version, Logger.LEVEL.INFO);
		this.log("Chart Type", "Spark Column Chart", Logger.LEVEL.INFO);
		//List Chart Objects and set them in arrObjects array defined in super parent class.
		this.arrObjects = new Array("BACKGROUND", "CANVAS", "CAPTION", "SUBCAPTION", "PLOT", "PERIOD", "TRENDLINES", "TOOLTIP");
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
			//Canvas
			this.config.intervals.canvas = setInterval(Delegate.create(this, drawCanvas) , this.timeElapsed);
			//Update timer
			this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.CANVAS):0;
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
	*	@param	color		Color for the set
	*	@return			An object encapsulating all these properies.
	*/
	private function returnDataAsObject(value:Number, color:String):Object {
		//Create a container
		var dataObj:Object = new Object();
		//Store the values
		dataObj.value = value;
		dataObj.color = color;
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
					if (arrLevel1Nodes[j].nodeName.toUpperCase() == "COLORRANGE") {
						//Call the super function to parse and store color range
						this.parseColorRange(arrLevel1Nodes[j].childNodes);
					}else if (arrLevel1Nodes [j].nodeName.toUpperCase() == "DATASET"){						
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
								var setColor:String = atts["color"];
								//Store all these attributes as object.
								this.dataset[this.numDS].data[setCount] = this.returnDataAsObject(setValue,setColor);
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
		//Canvas background properties - Gradient
		this.params.canvasBgColor = getFV(atts ["canvasbgcolor"] , this.colorM.get2DCanvasBgColor());
		this.params.canvasBgAlpha = getFV(atts ["canvasbgalpha"] , this.colorM.get2DCanvasBgAlpha());
		this.params.canvasBgRatio = getFV(atts ["canvasbgratio"] , this.colorM.get2DCanvasBgRatio());
		this.params.canvasBgAngle = getFV(atts ["canvasbgangle"] , this.colorM.get2DCanvasBgAngle());		
		//Canvas Border properties
		this.params.showCanvasBorder = toBoolean(getFN(atts ["showcanvasborder"] , 1));
		this.params.canvasBorderColor = formatColor(getFV(atts ["canvasbordercolor"] , this.colorM.get2DCanvasBorderColor()));
		this.params.canvasBorderThickness = getFN(atts ["canvasborderthickness"] , 1);
		this.params.canvasBorderAlpha = getFN(atts ["canvasborderalpha"] , this.params.showCanvasBorder?100:0);
		//Border Properties of chart
		this.params.showBorder = toBoolean(getFN(atts["showborder"], 0));
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
		//Percentage space on the plot area
		this.params.plotSpacePercent = getFN (atts ["plotspacepercent"] , 10);
		///Cannot be less than 0 and more than 80
		if ((this.params.plotSpacePercent < 0) || (this.params.plotSpacePercent > 80)){
			//Reset to 10
			this.params.plotSpacePercent = 10;
		}
		this.params.plotFillColor = formatColor(getFV(atts["plotfillcolor"], this.colorM.get2DPlotFillColor()));
		this.params.plotFillAlpha = getFN(atts["plotfillalpha"], 100);
		//Fill Color for high column and low column
		this.params.highColor = atts["highcolor"];
		this.params.lowColor = atts["lowcolor"];		
		//Period length and color
		this.params.periodLength = getFN(atts["periodlength"],-1);
		this.params.periodColor = formatColor(getFV(atts["periodcolor"], this.colorM.getPeriodColor()));
		this.params.periodAlpha = getFN(atts["periodalpha"], 100);		
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
			var dataPlotAnim = new StyleObject ();
			dataPlotAnim.name = "_SdDataPlotAnim";
			dataPlotAnim.param = "_yscale";
			dataPlotAnim.easing = "strong";
			dataPlotAnim.wait = 0;
			dataPlotAnim.start = 0;
			dataPlotAnim.duration = 1;
			//Over-ride
			this.styleM.overrideStyle (this.objects.PLOT, dataPlotAnim, this.styleM.TYPE.ANIMATION, "_yscale");
			delete dataPlotAnim;
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
		this.dm.reserveDepths ("PLOT", this.numDS*this.num);		
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
		//The (color range) can have the following objects group both above/below it.		
		//Margins
		//And the following at its side:
		//Caption, canvas margins
		//We'll calculate the top and bottom space required and then block the 
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
		//---------------- CANVAS X AND WIDTH PROPERTIES -------------//
		canvasStartX = this.params.chartLeftMargin + maxCaptionWidth;
		canvasWidth = this.width - (this.params.chartLeftMargin + this.params.chartRightMargin + maxCaptionWidth);
		
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
		//---------- COLUMN WIDTH AND SPACING CALCULATION ---------------------//
		//Now, calculate the spacing on canvas and individual column width
		var plotSpace : Number = (this.params.plotSpacePercent / 100) * this.elements.canvas.w;
		//Block Width
		var blockWidth : Number = (this.elements.canvas.w - plotSpace) / this.num;
		//Individual column space.
		var columnWidth : Number = blockWidth / this.numDS;
		//Max column width can be 50 - so if exceeded, reset width and space
		//Now, there can be an exception if this.params.plotSpacePercent has
		//been defined
		if (columnWidth > 50 && (this.params.plotSpacePercent == 10)){
			columnWidth = 50;
			blockWidth = columnWidth * this.numDS;
			plotSpace = this.elements.canvas.w - (this.num * blockWidth);
		}
		//We finally have total plot space and column width
		//Store it in config
		this.config.plotSpace = plotSpace;
		this.config.blockWidth = blockWidth;
		this.config.columnWidth = columnWidth;
		//Get space between two blocks
		var interBlockSpace : Number = plotSpace / (this.num + 1);
		//Store in config.
		this.config.interBlockSpace = interBlockSpace;
		// -------------------------------------------------------------------------//
		//Base Plane position - Base plane is the y-plane from which columns start.
		//If there's a 0 value in between yMin,yMax, base plane represents 0 value.
		//Else, it's yMin
		if (this.pAxis.getYMax() >= 0 && this.pAxis.getYMin() < 0)	{
			//Negative number present - so set basePlanePos as 0 value
			this.config.basePlanePos = this.pAxis.getAxisPosition(0, false);
		} else {
			//No negative numbers - so set basePlanePos as yMin value
			this.config.basePlanePos = this.pAxis.getAxisPosition(this.pAxis.getYMin(), false);
		}
		// -------------------- INDIVIDUAL DATA ---------------------------------//
		//We now need to calculate the position of columns on the chart.
		var dataEndY : Number;		
		for (i=1; i<=this.num; i++){
			for (j=1; j<=this.numDS; j++){
				//Get the x position for column
				this.dataset[j].data [i].x = this.elements.canvas.x + (interBlockSpace * i) + columnWidth * (j - 0.5) + (columnWidth * this.numDS * (i - 1));
				//Set y position
				this.dataset[j].data[i].y = this.config.basePlanePos;
				//Get end y position
				dataEndY = isNaN(this.dataset[j].data[i].value)?this.config.basePlanePos:this.pAxis.getAxisPosition(this.dataset[j].data[i].value, false);				
				//Get the height relative to base plane position
				this.dataset[j].data [i].h = (dataEndY - this.config.basePlanePos);
				//Width - Decrement 1 to show space between columns of 2 dataset
				this.dataset [j].data [i].w = this.config.columnWidth - 1;
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
	/**
	 * drawPlot method draws the columns on the chart.
	*/
	private function drawPlot():Void{
		//Variables
		var colMC:MovieClip;		
		var depth:Number = this.dm.getDepth ("PLOT");
		var i:Number, j:Number;
		var columnColor:Object;
		//Create function storage containers for Delegate functions
		var fnRollOver:Function, fnClick:Function;
		//Iterate through all columns
		for (i = 1; i <= this.numDS; i ++){
			for (j = 1; j <= this.num; j ++){
				//If defined
				if (this.dataset [i].data [j].isDefined){
					//Get the column color
					columnColor = this.identifyColumnColor(i, j);
					//Create an empty movie clip for this column
					colMC = this.cMC.createEmptyMovieClip ("Column_" + i + "_" + j, depth);
					//Shift the entire column
					colMC._x = this.dataset[i].data[j].x;
					colMC._y = this.dataset[i].data[j].y;
					//Draw the column
					colMC.beginFill(parseInt(columnColor.color,16),columnColor.alpha);
					colMC.moveTo(-(this.dataset[i].data[j].w/2), 0);
					colMC.lineTo(-(this.dataset[i].data[j].w/2), (this.dataset[i].data[j].h));
					colMC.lineTo((this.dataset[i].data[j].w/2), (this.dataset[i].data[j].h));
					colMC.lineTo((this.dataset[i].data[j].w/2), 0);
					colMC.lineTo(-(this.dataset[i].data[j].w/2), 0);
					colMC.endFill();
					//Apply animation
					if (this.params.animation){
						this.styleM.applyAnimation (colMC, this.objects.PLOT, this.macro, this.dataset [i].data [j].x, this.dataset [i].data [j].y, 100, 100, 100, null);
					}
					//Apply filters
					this.styleM.applyFilters (colMC, this.objects.DATAPLOT);
					//Event handlers for tool tip
					if (this.params.showToolTip){
						//Create Delegate for roll over function showToolText
						fnRollOver = Delegate.create (this, showToolText);
						//Set the text
						fnRollOver.toolText = this.dataset[i].data[j].displayValue;
						//Assing the delegates to movie clip handler
						colMC.onRollOver = fnRollOver;
						//Set roll out and mouse move too.
						colMC.onRollOut = colMC.onReleaseOutside = Delegate.create (this, hideToolText);
						colMC.onMouseMove = Delegate.create (this, positionToolText);
					}
					//Do not use hand cursor
					colMC.useHandCursor = (this.params.clickURL == "") ?false : true;					
					//Increase depth
					depth ++;
				}
			}
		}
		clearInterval(this.config.intervals.plot);
	}
	/**
	 * identifyColumnColor method identifies the color using which the column has to be
	 * colored. Rules:
	 * 1. If user has specified the color for column explicitly, return that.
	 * 2. If the column is highest/lowest and highest/lowest color value is specified, we
	 * return that color & alpha.
	 * 3. If condition 1,2 fails & color range is defined, we find the index of the color range
	 * which satisfies this column value and return the same.
	 * 4. Fill it with this.params.plotFillColor
	 *	@param	ds		Dataset index to which this column belongs to.
	 *	@param	num		Index within the dataset
	 *	@return			Object containing color & alpha in which the column should be plotted.
	*/
	private function identifyColumnColor(ds, num):Object{
		if ((this.dataset[ds].data[num].color!=undefined && this.dataset[ds].data[num].color!=null)){
			return {color:this.dataset[ds].data[num].color, alpha:this.params.plotFillAlpha};
		}
		else if((this.dataset[ds].data[num].highest==true) && (this.params.highColor!=undefined && this.params.highColor!=null)){
			//If it's the highest column and the high color is defined
			return {color:this.params.highColor, alpha:this.params.plotFillAlpha};
		}else if((this.dataset[ds].data[num].lowest==true) && (this.params.lowColor!=undefined && this.params.lowColor!=null)){
			//If it's the lowest column and the low color is defined
			return {color:this.params.lowColor, alpha:this.params.plotFillAlpha};
		}else if (this.numCR>0){
			//Find which CR this number belongs to
			//Assuming max color range index, as we check for < and not <= for upper range
			var index:Number = this.numCR;
			var i:Number;
			//Iterate through each color range to find the value's position
			for (i=1; i<=this.numCR; i++){
				if (this.colorR[i].minValue<=this.dataset[ds].data[num].value && this.dataset[ds].data[num].value<this.colorR[i].maxValue){
					index = i;
					break;
				}
			}
			//Return
			return {color:this.colorR[index].color, alpha:this.colorR[index].alpha};
		}else{
			//No rules matched - simply fill with plotFillColor
			return {color:this.params.plotFillColor, alpha:this.params.plotFillAlpha};
		}
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
				startX = this.dataset[1].data[((i-1)*this.params.periodLength) + 1].x - this.config.columnWidth/2 - this.config.interBlockSpace/2;
				endX = this.dataset[this.numDS].data[i*this.params.periodLength].x  + this.config.columnWidth/2 + this.config.interBlockSpace/2;
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