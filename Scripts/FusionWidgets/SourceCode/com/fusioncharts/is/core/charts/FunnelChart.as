/**
 * FunnelChart chart extends the Chart class to render a 
 * Funnel Chart.
 */
// Import parent Chart class
import com.fusioncharts.is.core.Chart; 
// Funnel Class
import com.fusioncharts.is.core.chartobjects.Funnel;
// Import the Error class
import com.fusioncharts.is.helper.FCError;
// Import Logger Class
import com.fusioncharts.is.helper.Logger;
// Utilities
import com.fusioncharts.is.helper.Utils;
// Import the MathExt class
import com.fusioncharts.is.extensions.MathExt;
// Import the ColorExt class
import com.fusioncharts.is.extensions.ColorExt;
// Import the Style Object
import com.fusioncharts.is.core.StyleObject;
// Number formatting
import com.fusioncharts.is.helper.NumberFormatting;
// Color Manager
import com.fusioncharts.is.colormanagers.AxisChartColorManager;
// Import the Delegate class
import mx.utils.Delegate;
// Import the Tween class
import mx.transitions.Tween;
/**
 * @class 		FunnelChart
 * @version		3.0
 * @author		InfoSoft Global (P) Ltd.
 *
 * Copyright (C) InfoSoft Global Pvt. Ltd.
 
 * FunnelChart chart extends the Chart class to render a 
 * Funnel Chart. Here, all parameters required for creating the
 * the funnel elements are evaluated and all interactive 
 * functionalities set.
 */
class com.fusioncharts.is.core.charts.FunnelChart extends Chart {
	//Container for data
	private var data:Array;
	//num keeps a count of number of data sets provided to the chart
	private var num:Number = 0;
	//Number formatting class for this chart
	private var nf:NumberFormatting;
	//Color Manager for this chart
	public var colorM:AxisChartColorManager;
	//Plot area is the rectangle in which the entire funnel chart
	//will be contained. The caption, sub caption and chart margins
	//do NOT form a part of the plot area.
	//Plot height - pertinent to funnel only
	private var plotHeight:Number;
	//Plot width - pertinent to funnel only
	private var plotWidth:Number;
	//X and Y position of plot area
	private var plotX:Number;
	private var plotY:Number;
	//Movie clip container to hold all funnels
	private var mcFunnelH:MovieClip;
	// stores all created bitmaps of the chart
	private var arrBmps:Array;	
	/**
	 * Constructor function. We invoke the super class'
	 * constructor and then set the objects for this chart.
	 */
	function FunnelChart(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Log additional information to debugger
		//We log version from this class, so that if this class version
		//is different, we can log it
		this.log("Version", _version, Logger.LEVEL.INFO);
		this.log("Chart Type", "Funnel Chart", Logger.LEVEL.INFO);
		//List Chart Objects and set them in arrObjects array defined in super parent class.
		this.arrObjects = new Array("BACKGROUND", "CANVAS", "CAPTION", "SUBCAPTION", "DATALABELS", "DATAPLOT", "TOOLTIP");
		super.setChartObjects();
		//-------------------- Initialize Instance variables/containers -----------------------//
		//Initialize data container
		this.data = new Array();
		//By default assume that the plot area width and height
		//will be same as the width and height of the funnel chart.
		//We later deduct caption and subcaption space if required.
		plotWidth = this.width;
		plotHeight = this.height;
		//Variable to store the sum of all funnel values the chart
		this.config.sumOfValues = 0;
		// number of funnels to be sliced
		this.config.numSlicedFunnels = 0;
		// is any link defined for any funnel
		this.config.linksDefined = false;
		// total number of links in the chart
		this.config.totalLinks = 0;
	}
	/**
	 * initContainers method is called to initiate properties
	 * to be used by the chart.
	 */
	private function initContainers():Void {
		// setting funnel squeeze factor in 0-1 scale
		this.config.funnelYScale = this.params.funnelYScale/100;
		// the number of funnels finishing initial slicing motion
		this.config.finishStatusNum = 0;
		// the funnel currently under slicing animation
		this.config.slicingMcRef = null;
		// the funnel in sliced state
		this.config.slicedOneMcRef = null;
		// is the chart undergoing change in interactive mode
		this.config.isChangingMode = false;
		// can the funnels be clicked to slice
		this.config.sliceAble = true;
		// is the chart in slicing mode
		this.config.enableSlicing = false;
		// is the chart in linking mode
		this.config.enableLinks = false;
		// is the chart currently changing dimension (2D/3D)
		this.config.changingDimension = false;
		// percentage of plot width to be covered by the ultimate funnelchart (excluding labels)
		this.config.effectivePlotRatio = 0.8;
		// ratio set for calculating maximum width of funnel
		this.config.effectivePlotWidthRatio = this.config.effectivePlotRatio
		// ratio yet to be set
		this.config.ratioSet =  false
		// abscissa of top label yet to be set
		this.config.topLabelX = null
		// is the chart initialised completing all initial animations and effects
		this.config.isInitialised = false;
		// consolidated container to hold references of all the funnel instances
		this.config.objFunnels = new Object();
		// consolidated container to hold references of all the tween instances linked to the funnels
		this.config.objTweens = new Object();
		// Initialize container to store bitmaps of the funnels
		this.arrBmps = new Array();
	}
	/**
	 * reInit method re-initializes the chart. This method is basically called
	 * when the user changes chart data through JavaScript. In that case, we need
	 * to re-initialize the chart, set new XML data and again render.
	*/
	public function reInit():Void {		
		//Invoke super class's reInit
		super.reInit();
		//Initialize things that are pertinent to this class
		//but not defined in super class.
		this.num = 0;
		//Initialize data container
		this.data = new Array();
		//Variable to store the sum of all values in funnel
		this.config.sumOfValues = 0;
		// the number of funnels finishing initial slicing motion
		this.config.finishStatusNum = 0;
		//Configuration whether links have been defined - by default assume no.
		this.config.linksDefined = false;
		// total number of links in the chart
		this.config.totalLinks = 0;
		//Configuration whether funnels can be clicked to slice
		this.config.sliceAble = true;
		//Configuration whether chart have been initialised completing all initial animations
		this.config.isInitialised = false;
		// ratio reset for calculating maximum width of funnel
		this.config.effectivePlotWidthRatio = this.config.effectivePlotRatio
		// ratio yet to be set
		this.config.ratioSet =  false
		// abscissa of top label yet to be set
		this.config.topLabelX = null
	}
	/**
	 * remove method removes the chart by clearing the chart movie clip
	 * and removing any listeners. However, the logger still stays on.
	 * To remove the logger too, you need to call destroy method of chart.
	*/
	public function remove():Void {
		//Remove listeners associated with this class.
		Mouse.removeListener(this);
		// deleting tween instances
		for(var i:String in this.config.objTweens){
			delete this.config.objTweens[i]
		}
		// to cleanUp funnelChart
		this.cleanUp();
		//Call super remove
		super.remove();
	}
	/**
	 * destroy method destroys the chart by removing the chart movie clip,
	 * logger movie clip, and removing any listeners. 
	*/
	public function destroy():Void {
		//Destroy chart
		super.destroy();
		//Now destroy anything additional pertinent to this chart, but
		//not included as a part of parent Chart class.
	}
	// -------------------- CORE CHART METHODS -------------------------- //
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
		//Now, if the number of data elements is 0, we show pertinent
		//error.
		if (this.num == 0) {
			tfAppMsg = this.renderAppMessage(_global.getAppMessage("NODATA", this.lang));
			//Add a message to log.
			this.log("No Data to Display", "No data was found in the XML data document provided. Possible cases can be: <LI>There isn't any data generated by your system. If your system generates data based on parameters passed to it using dataURL, please make sure dataURL is URL Encoded.</LI><LI>You might be using a Single Series Chart .swf file instead of Multi-series .swf file and providing multi-series data or vice-versa.</LI>", Logger.LEVEL.ERROR);
			//Expose rendered method
			this.exposeChartRendered();
			//Also raise the no data event
			this.raiseNoDataExternalEvent();
		} else {
			//Set style defaults
			this.setStyleDefaults();
			//Allot the depths for various charts objects now
			this.allotDepths();
			//Set the container for annotation manager
			this.setupAnnotationMC();
			//Calculate Points
			this.calculatePoints();			
			//Feed macro values
			this.feedMacros();
			//Remove application message
			this.removeAppMessage(this.tfAppMsg);
			//Set tool tip parameter
			this.setToolTipParam();
			//-------- Start Visual Rendering Now ------//
			//Draw background
			this.drawBackground();
			// set the global URL click
			this.drawClickURLHandler();
			// load the background SWF, if any
			this.loadBgSWF();
			//Update timer
			this.timeElapsed = (this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.BACKGROUND) : 0;
			//Render the annotations below
			this.config.intervals.annotationsBelow = setInterval(Delegate.create(this, renderAnnotationBelow) , this.timeElapsed);
			//Draw headers - caption and sub-caption
			this.config.intervals.headers = setInterval(Delegate.create(this, drawHeaders), this.timeElapsed);
			//Update timer
			this.timeElapsed += (this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.CAPTION, this.objects.SUBCAPTION) : 0;
			//Call the unified draw method to render chart.
			this.config.intervals.plot = setInterval(Delegate.create(this, draw), this.timeElapsed);
			////Update timer
			this.timeElapsed += (this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.DATAPLOT) : 0;
			//call to set initial slicing funnel animations
			this.config.intervals.sliceAnimation = setInterval(Delegate.create(this, sliceFunnels), this.timeElapsed);
			//Set context menu
			this.config.intervals.menu = setInterval(Delegate.create(this, setContextMenu), this.timeElapsed);
			//Render the annotations above the chart
			this.config.intervals.annotationsAbove = setInterval(Delegate.create(this, renderAnnotationAbove) , (this.params.annRenderDelay==undefined || isNaN(Number(this.params.annRenderDelay)))?(this.timeElapsed):(Number(this.params.annRenderDelay)*1000));
			//Dispatch event that the chart has loaded.
			this.config.intervals.renderedEvent = setInterval(Delegate.create(this, exposeChartRendered) , this.timeElapsed);						
		}
	}
	/**
	 * allotDepths method allots the depths for various chart objects
	 * to be rendered. We do this before hand, so that we can later just
	 * go on rendering chart objects, without swapping.
	*/
	private function allotDepths():Void {
		//Background
		this.dm.reserveDepths("BACKGROUND", 1);
		//Click URL Handler
		this.dm.reserveDepths("CLICKURLHANDLER", 1);
		//Background SWF
		this.dm.reserveDepths("BGSWF", 1);
		//Annotations below the chart
		this.dm.reserveDepths("ANNOTATIONBELOW", 1);
		//Caption
		this.dm.reserveDepths("CAPTION", 1);
		//Sub-caption
		this.dm.reserveDepths("SUBCAPTION", 1);
		// funnelchart holder
		this.dm.reserveDepths("DATAPLOT", 1);
		//Annotations above the chart
		this.dm.reserveDepths("ANNOTATIONABOVE", 1);
	}
	/** 
	 * feedMacros method feeds macros and their respective values
	 * to the macro instance. This method is to be called after
	 * calculatePoints, as we set the canvas and chart co-ordinates
	 * in this method, which is known to us only after calculatePoints.
	 *	@returns	Nothing
	*/
	private function feedMacros():Void {
		//Feed macros one by one
		//Chart dimension macros
		this.macro.addMacro("$chartStartX", this.x);
		this.macro.addMacro("$chartStartY", this.y);
		this.macro.addMacro("$chartWidth", this.width);
		this.macro.addMacro("$chartHeight", this.height);
		this.macro.addMacro("$chartEndX", this.width);
		this.macro.addMacro("$chartEndY", this.height);
		this.macro.addMacro("$chartCenterX", this.width/2);
		this.macro.addMacro("$chartCenterY", this.height/2);
		//Canvas dimension macros
		this.macro.addMacro("$canvasStartX", this.x);
		this.macro.addMacro("$canvasStartY", this.y);
		this.macro.addMacro("$canvasWidth", this.width);
		this.macro.addMacro("$canvasHeight", this.height);
		this.macro.addMacro("$canvasEndX", this.width);
		this.macro.addMacro("$canvasEndY", this.height);
		this.macro.addMacro("$canvasCenterX", this.width/2);
		this.macro.addMacro("$canvasCenterY", this.height/2);
	}
	/**
	 * setStyleDefaults method sets the default values for styles or
	 * extracts information from the attributes and stores them into
	 * style objects.
	*/
	private function setStyleDefaults():Void {
		/**
		 * For the funnel chart, we need to set defaults for the
		 * following object - property combinations:
		 * CAPTION - FONT
		 * SUBCAPTION - FONT
		 * DATALABELS - FONT
		 * TOOLTIP - FONT
		 * DATAPLOT - Default Animation (Alpha)
		 */
		//Default font object for Caption
		//-----------------------------------------------------------------//
		var captionFont = new StyleObject();
		captionFont.name = "_SdCaptionFont";
		captionFont.align = "center";
		captionFont.valign = "top";
		captionFont.bold = "1";
		captionFont.font = this.params.baseFont;
		captionFont.size = this.params.baseFontSize;
		captionFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle(this.objects.CAPTION, captionFont, this.styleM.TYPE.FONT, null);
		delete captionFont;
		//-----------------------------------------------------------------//
		//Default font object for SubCaption
		//-----------------------------------------------------------------//
		var subCaptionFont = new StyleObject();
		subCaptionFont.name = "_SdSubCaptionFont";
		subCaptionFont.align = "center";
		subCaptionFont.valign = "top";
		subCaptionFont.bold = "1";
		subCaptionFont.font = this.params.baseFont;
		subCaptionFont.size = this.params.baseFontSize;
		subCaptionFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle(this.objects.SUBCAPTION, subCaptionFont, this.styleM.TYPE.FONT, null);
		delete subCaptionFont;
		//-----------------------------------------------------------------//
		//Default font object for DataLabels
		//-----------------------------------------------------------------//
		var dataLabelsFont = new StyleObject();
		dataLabelsFont.name = "_SdDataLabelsFont";
		dataLabelsFont.align = "center";
		dataLabelsFont.valign = "bottom";
		dataLabelsFont.font = this.params.baseFont;
		dataLabelsFont.size = this.params.baseFontSize;
		dataLabelsFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle(this.objects.DATALABELS, dataLabelsFont, this.styleM.TYPE.FONT, null);
		delete dataLabelsFont;
		//-----------------------------------------------------------------//
		//Default font object for ToolTip
		//-----------------------------------------------------------------//
		var toolTipFont = new StyleObject();
		toolTipFont.name = "_SdToolTipFont";
		toolTipFont.font = this.params.baseFont;
		toolTipFont.size = this.params.baseFontSize;
		toolTipFont.color = this.params.baseFontColor;
		toolTipFont.bgcolor = this.params.toolTipBgColor;
		toolTipFont.bordercolor = this.params.toolTipBorderColor;
		//Over-ride
		this.styleM.overrideStyle(this.objects.TOOLTIP, toolTipFont, this.styleM.TYPE.FONT, null);
		delete toolTipFont;		
		//-----------------------------------------------------------------//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
		//Default Animation object for DataPlot (if required)
		//-----------------------------------------------------------------//
		if (this.params.defaultAnimation) {
			var dataPlotAnim = new StyleObject();
			dataPlotAnim.name = "_SdDataPlotAnim";
			dataPlotAnim.easing = "regular";
			dataPlotAnim.start = 0;
			dataPlotAnim.duration = 1;
			var strEffect:String = "_alpha";
			dataPlotAnim.param = strEffect;
			//Over-ride
			this.styleM.overrideStyle(this.objects.DATAPLOT, dataPlotAnim, this.styleM.TYPE.ANIMATION, strEffect);
			delete dataPlotAnim;
		}
		//-----------------------------------------------------------------//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
	}
	/**
	 * cleanUp method is called to purge the basics before
	 * regeneration process of chart can begin.
	 */
	private function cleanUp():Void {
		// iterating to get all movieclip and funnel instances in funnelchart holder movieclip in order 
		// to clean them up and set the stage ready for next redraw
		for (var p:String in mcFunnelH) {
			if (mcFunnelH[p] instanceof MovieClip) {
				// clearing all event handlers from the movieclips to be removed
				delete mcFunnelH[p].onRollOver;
				delete mcFunnelH[p].onRollOut;
				delete mcFunnelH[p].onRelease;
				delete mcFunnelH[p].onReleaseOutside;
				mcFunnelH[p].removeMovieClip();
			}
		}
		// deleting all Funnel instances
		for (var p:String in this.config.objFunnels) {
			delete this.config.objFunnels[p];
		}
	}
	// ----------------- DATA READING, PARSING AND STORING -----------------//
	/**
	 * parseXML method parses the XML data, sets defaults and validates
	 * the attributes before storing them to data storage objects.
	*/
	private function parseXML():Void {
		//Get the element nodes
		var arrDocElement:Array = this.xmlData.childNodes;
		//Look for <graph> element
		for (var i = 0; i<arrDocElement.length; i++) {
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
				for(j = 0; j < arrLevel1Nodes.length; j ++){
					if(arrLevel1Nodes [j].nodeName.toUpperCase() == "ANNOTATIONS" || arrLevel1Nodes [j].nodeName.toUpperCase() == "CUSTOMOBJECTS"){
						//Parse and store
						this.am.parseXML(arrLevel1Nodes [j]);
					}
				}
				//Iterate through all level 1 nodes.
				for (var j = 0; j<arrLevel1Nodes.length; j++) {
					//If it's Data nodes
					if (arrLevel1Nodes[j].nodeName.toUpperCase() == "SET") {
						//Set Node. So extract the data.
						//Get reference to node.
						setNode = arrLevel1Nodes[j];
						//Get attributes
						var atts:Array;
						atts = Utils.getAttributesArray(setNode);
						//Extract values.
						var setValue:Number;
						//Now, get value.
						try{
							var setValue:Number = this.nf.parseValue(atts["value"]);
						} catch (e:Error){
							//If the value is not a number, log a data
							this.log("Invalid data",e.message, Logger.LEVEL.ERROR);
							//Set as NaN - so that we can show it as empty data.
							setValue = Number("");
						}						
						// if this data is worth display in the chart
						if (setValue>=0 && !isNaN(setValue)) {
							//First, updated counter
							this.num++;
							var setLabel:String = getFV(atts["label"], atts["name"], "");
							var setLink:String = getFV(atts["link"], "");
							var setToolText:String = getFV(atts["tooltext"], atts["hovertext"]);
							//
							// string form of hexadecimal code stored, but in a form whose number equivalent can't be 
							// recognised by flash as hexadecimal
							var color:String = String(formatColor(getFV(atts["color"])));
							// funnel fill opacity
							var setFillAlpha:Number = getFN(atts["alpha"], this.params.funnelFillAlpha);
							// hexadecimal color code stored for the funnel
							var setColor:Number = (color != '') ? parseInt(color, 16) : null;
							// hexadecimal color code stored for the funnel border
							var setBorderColor:Number = parseInt(formatColor(((this.params.is2D)? getFV(atts["bordercolor"], this.params.funnelBorderColor):this.params.funnelBorderColor)), 16);							
							// funnel border opacity
							var setBorderAlpha:Number = (this.params.showPlotBorder)? getFN(atts["borderalpha"], this.params.funnelBorderAlpha):this.params.funnelBorderAlpha;
							// slicing status
							var setIsSliced:Boolean = toBoolean(getFN(atts["issliced"], 0));	
							// value to be displayed in label or not
							var setShowValue:Boolean = toBoolean(getFN(atts["showvalue"], ((this.params.showValues)? 1 : 0)));
							//Summing up the values
							this.config.numSlicedFunnels += (setIsSliced) ? 1 : 0;
							// flag to be used to enable links for user interaction, initially and to keep the same option in the context menu
							this.config.totalLinks += (setLink.length>1) ? 1 : 0;
							// to enable linking mode initially and to keep option for in context menu for the same
							this.config.linksDefined = (setLink.length>1) ? true : this.config.linksDefined;
							// Store all these attributes as object.
							this.config.sumOfValues += setValue;
							this.data[this.num-1] = this.returnDataAsObject(setLabel, setValue, setColor, setBorderColor, setFillAlpha, setBorderAlpha, setToolText, setLink, setIsSliced, setShowValue);
							// for finner sorting algorithm support, in case of streamlined data
							if(this.params.streamlinedData){								
								this.data[this.num-1].id = this.num-1
							}
						}
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
		// global URL
		this.params.clickURL = getFV(atts["clickurl"], "");
		//Delay in rendering annotations that are over the chart
		this.params.annRenderDelay = atts["annrenderdelay"];
		//Chart Caption and sub Caption
		this.params.caption = getFV(atts["caption"], "");
		this.params.subCaption = getFV(atts["subcaption"], "");
		//captionPadding = Space between caption/subcaption and canvas start Y
		this.params.captionPadding = getFN(atts["captionpadding"], 10);
		//Whether to set animation for entire chart.                                                                                                                                      
		this.params.animation = toBoolean(getFN(atts["animation"], 1));
		//Whether to set the default chart animation
		this.params.defaultAnimation = toBoolean(getFN(atts["defaultanimation"], 1));
		//Configuration to set whether to show the names or not
		this.params.showNames = toBoolean(getFN(atts["showlabels"], atts["shownames"], 1));
		this.params.showValues = toBoolean(getFN(atts["showvalues"], 1));
		//Percentage values in data labels?
		this.params.showPercentValues = toBoolean(getFN(atts["showpercentvalues"], atts["showpercentagevalues"], atts["showpercentageinlabel"], 0));
		//Percentage values in tool tip
		this.params.showPercentInToolTip = toBoolean(getFN(atts["showpercentintooltip"], 1));
		this.params.percentOfPrevious = toBoolean(getFN(atts["percentofprevious"], 0));
		//Tool Tip - Show/Hide, Background Color, Border Color, Separator Character
		this.params.showToolTip = toBoolean(getFN(atts["showtooltip"], atts["showhovercap"], 1));
		this.params.toolTipBgColor = String(formatColor(getFV(atts["tooltipbgcolor"], atts["hovercapbgcolor"], atts["hovercapbg"], this.colorM.get2DToolTipBgColor())));
		this.params.toolTipBorderColor = String(formatColor(getFV(atts["tooltipbordercolor"], atts["hovercapbordercolor"], atts["hovercapborder"], this.colorM.get2DToolTipBorderColor())));
		//Seperator character
		this.params.toolTipSepChar = getFV(atts["tooltipsepchar"], atts["hovercapsepchar"], ", ");
		this.params.labelSepChar = getFV(atts["labelsepchar"], this.params.toolTipSepChar);
		//Font Properties
		this.params.baseFont = getFV(atts["basefont"], "Verdana");
		this.params.baseFontSize = getFN(atts["basefontsize"], 9);
		this.params.baseFontColor = String(formatColor(getFV(atts["basefontcolor"], this.colorM.get2DBaseFontColor())));		
		// FunnelChart related properties 		
		this.params.funnelYScale = this.setFunnelYScale(getFN(atts["funnelyscale"], 15));
		// 1 gives funnel chart while 0 gives section chart
		this.params.streamlinedData = toBoolean(getFN(atts["streamlineddata"], 1));
		this.params.is2D = toBoolean(getFN(atts["is2d"], 0));
		this.params.isSliced = toBoolean(getFN(atts["issliced"], 0));
		this.params.isHollow = toBoolean(getFN(atts["ishollow"], ((this.params.streamlinedData)?1:0)));
		this.params.useSameSlantAngle = toBoolean(getFN(atts["usesameslantangle"], 0));
		// funnel related properties                                                                                                                                                                            
		// Plot properties
		this.params.showPlotBorder = toBoolean(getFN(atts["showplotborder"], 0));
		this.params.funnelBorderColor = this.setFunnelBorderColor(getFV(atts["plotbordercolor"],atts["funnelbordercolor"],""));
		this.params.funnelBorderThickness = (this.params.is2D)? getFN(atts["plotborderthickness"], atts["funnelborderthickness"], 1) : 2;
		this.params.funnelBorderAlpha = (this.params.showPlotBorder == true) ? getFN(atts["plotborderalpha"], atts["funnelborderalpha"], 80): 0;
		this.params.funnelFillAlpha = getFN(atts["plotfillalpha"], atts["funnelfillalpha"], atts["fillalpha"], 100);
		// label properties
		this.params.showLabelsAtCenter = toBoolean(getFN(atts["showlabelsatcenter"], 0));		
		//Label Distance indicates the space (pixels)
		this.params.labelDistance = Math.abs(getFN(atts["labeldistance"], atts["nametbdistance"], 50));
		//Attributes relating to Smart Label
		//Whether to enable smart labels
		this.params.enableSmartLabels = toBoolean(getFN(atts["enablesmartlabels"], atts["enablesmartlabel"], 1));
		//Smart line cosmetic properties
		this.params.smartLineColor = String(formatColor(getFV(atts["smartlinecolor"], this.colorM.get2DBaseFontColor())));
		this.params.smartLineThickness = getFN(atts["smartlinethickness"], 1);
		this.params.smartLineAlpha = getFN(atts["smartlinealpha"], 100);
		//Chart Margins                      
		this.params.chartLeftMargin = getFN(atts["chartleftmargin"], 15);
		this.params.chartRightMargin = getFN(atts["chartrightmargin"], 15);
		this.params.chartTopMargin = getFN(atts["charttopmargin"], 15);
		this.params.chartBottomMargin = getFN(atts["chartbottommargin"], 15);
		//-----------Number formatting--------------//
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
	 * returnDataAsObject method creates an object out of the parameters
	 * passed to this method. The idea is that we store each data point
	 * as an object with multiple (flexible) properties. So, we do not 
	 * use a predefined class structure. Instead we use a generic object.
	 */
	private function returnDataAsObject(dataLabel:String, dataValue:Number, color:Number, bordercolor:Number, fillAlpha:Number, borderAlpha:Number, toolText:String, link:String, isSliced:Boolean, showValue:Boolean):Object {
		//Create a container
		var dataObj:Object = new Object();
		//Store the values
		dataObj.label = dataLabel;
		dataObj.value = dataValue;
		dataObj.color = color;
		dataObj.borderColor = bordercolor;
		dataObj.fillAlpha = fillAlpha;
		dataObj.borderAlpha = borderAlpha;
		dataObj.toolText = toolText;
		dataObj.link = link;
		dataObj.isSliced = isSliced;
		dataObj.showValue = showValue;
		//Return the container
		return dataObj;
	}
	/**
	 * setupNumberFormatting method sets up the number formatting instance
	 * for the class.
	 *	@param		numberPrefix		Number prefix to be added to number.
	 *	@param		numberSuffix		Number Suffix to be added.
	 *	@param		scaleRecursively	Whether to scale the number recursively as per defined scale.
	 *	@param		maxScaleRecursion	Maximum recursion to set in scaling.
	 *	@param		defaultNumberScale	Default scale of the number provided.
	 *	@param		numberScaleValues	Values for scaling (string). 
	 *	@param		numberScaleUnits	Units for scaling (string).
	 *	@param		decimalSeparator	Separator character for decimal representation.
	 *	@param		thousandSeparator	Thousands separator character.
	 *	@param		inDecimalSeparator	Input decimal character
	 *	@param		inThousandSeparator	Input thousand separator character
	 *	@return							Nothing
	*/
	private function setupNumberFormatting(numberPrefix:String, numberSuffix:String, scaleRecursively:Boolean, maxScaleRecursion:Number, scaleSeparator:String, defaultNumberScale:String, numberScaleValues:String, numberScaleUnits:String, decimalSeparator:String, thousandSeparator:String, inDecimalSeparator:String, inThousandSeparator:String):Void {
		//Setup the number formatting instance for this class.
		this.nf = new NumberFormatting(numberPrefix, numberSuffix, scaleRecursively, maxScaleRecursion, scaleSeparator, defaultNumberScale, numberScaleValues, numberScaleUnits, decimalSeparator, thousandSeparator, inDecimalSeparator, inThousandSeparator);
	}
	/**
	 * setupColorManager method sets up the color manager for the chart.
	  *	@param	paletteId	Palette Id for the chart.
	 *	@param	themeColor	Color code if the chart uses single color theme.
	*/
	private function setupColorManager(paletteId:Number, themeColor:String):Void{
		this.colorM = new AxisChartColorManager(paletteId,themeColor);
	}
	/**
	 * setFunnelBorderColor method evaluates to return the 
	 * final border color of the funnels.
	 * @param	color	color value specified
	 * @return			evaluated final color value
	 */
	private function setFunnelBorderColor(color:String):String{
		if(!this.params.is2D){
			color = "FFFFFF"
		}
		return this.formatColor(color)
	}
	/**
	 * setFunnelYScale method validates to return the 
	 * final scaleValue of the funnels.
	 * @param	scaleValue	scale value in 0-100 scale
	 * @return				validated final value
	*/
	private function setFunnelYScale(scaleValue:Number):Number{
		if(scaleValue>15){
			// maximum permissible
			scaleValue = 15
		}else if(scaleValue<=0){
			// minimum permissible
			scaleValue = 0
		}
		return Math.floor(scaleValue)
	}
	// ---------------- CALCULATION AND OPTIMIZATION -----------------//
	/**
	* calculatePoints method calculates the various points 
	* on the chart.
	*/
	private function calculatePoints():Void {
		// this.data repository is pre-processed
		if (this.params.streamlinedData) {
			// for the case of non-section funnelChart
			// dataset sorted in numerically ascending order, with finer sorting in case of same data values,
			// to maintain same order in chart as in XML (visually downwards).
			this.data.sortOn(['value','id'], [16 , 16|2]);	
		}else{
			// for the case of section funnelChart
			this.data.reverse()
		}
		//Format all the numbers on the chart and store their display and percent values                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
		//We format and store here itself, so that later, whenever needed,
		//we just access displayValue instead of formatting once again.
		var displayNumToolTip:String, displayNumLabel:String, denominator:Number;
		// custom NumberFormatting instance for percentage value calculations
		var nfForPercent:NumberFormatting = new NumberFormatting('', '',  this.params.scaleRecursively, this.params.maxScaleRecursion,  this.params.scaleSeparator, this.params.defaultNumberScale,  this.params.numberScaleValue, this.params.numberScaleUnit,  this.params.decimalSeparator, this.params.thousandSeparator,  this.params.inDecimalSeparator, this.params.inThousandSeparator);
		// loop runs to set values for display associated with the funnels
		for (var i:Number = 0; i<this.num; i++) {
			//Format and store
			this.data[i].displayValue = this.nf.formatNumber(this.data[i].value, this.params.formatNumber, this.params.formatNumberScale, this.params.decimals, this.params.forceDecimals);			
			// setting the denominaor factor for evaluating percentage value for the funnel
			if (this.params.streamlinedData) {
				// for a funnel chart
				denominator = (this.params.percentOfPrevious) ? this.data[i+1].value : this.data[this.num-1].value;
			} else {
				// for a section chart
				denominator = this.config.sumOfValues;
			}
			// percentage stored in central repository after calculation and formatting
			this.data[i].percentValue = nfForPercent.formatNumber((this.data[i].value/denominator)*100, true, false, this.params.decimals, this.params.forceDecimals);			
			//
			var strPercentValue:String = ((this.data[i].percentValue!='')?this.data[i].percentValue:'100') + "%";
			// Set default values for toolText if not specified
			displayNumToolTip = (this.params.showPercentInToolTip) ? strPercentValue : this.data[i].displayValue;
			// Set default values for toolText if not specified:
			// setting the seperation character, if any
			var toolSepChar:String = (this.data[i].label != '') ? this.params.toolTipSepChar : '';
			// toolTip text is set and stored for ready reference
			this.data[i].toolText = getFV(this.data[i].toolText, this.data[i].label+toolSepChar+displayNumToolTip);
			// Set values for label text
			displayNumLabel = (this.params.showPercentValues) ? strPercentValue : this.data[i].displayValue;
			// Set values for label text; initialised to a blank string
			var strLabel:String = '';
			// if name of the funnel entity is to be displayed
			if (this.params.showNames) {
				strLabel += this.data[i].label;
			}
			// if value of the funnel entity is to be displayed                                                                                                       
			if (this.data[i].showValue) {
				// setting the seperation character, if any, label is already having characters for display
				if (this.params.showNames && this.data[i].label != '') {
						strLabel += this.params.labelSepChar;
				}
					strLabel += displayNumLabel;
			}
			// label text is set and stored for ready reference                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
			this.data[i].labelText = strLabel;
		}
		//We now need to calculate the available plot Width on the canvas.
		//Available width = total Chart width minus 
		// - Left and Right Margin
		var canvasWidth:Number = this.width-(this.params.chartLeftMargin+this.params.chartRightMargin);
		//Set canvas startX
		var canvasStartX:Number = this.params.chartLeftMargin;
		//We finally have canvas Width and canvas Start X
		//-----------------------------------------------------------------------------------//
		//Now, we need to calculate the available plot Height on the canvas.
		//Available height = total Chart height minus the list below
		// - Chart Top and Bottom Margins
		// - Space for Caption, Sub Caption and caption padding
		//Initialize canvasHeight to total height minus margins
		var canvasHeight:Number = this.height-(this.params.chartTopMargin+this.params.chartBottomMargin);
		//Set canvasStartY
		var canvasStartY:Number = this.params.chartTopMargin;
		//Now, if we've to show caption
		if (this.params.caption != "") {
			//Create text field to get height
			var captionObj:Object = createText(true, this.params.caption, this.tfTestMC, 1, testTFX, testTFY, 0, this.styleM.getTextStyle(this.objects.CAPTION),  true, canvasWidth, canvasHeight/4);
			//Store the height
			canvasStartY = canvasStartY+captionObj.height;
			canvasHeight = canvasHeight-captionObj.height;
			//Create element for caption - to store width & height
			this.elements.caption = returnDataAsElement(0, 0, captionObj.width, captionObj.height);
			delete captionObj;
		}
		//Now, if we've to show sub-caption                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
		if (this.params.subCaption != "") {
			//Create text field to get height
			var subCaptionObj:Object = createText(true, this.params.subCaption, this.tfTestMC, 1, testTFX, testTFY, 0, this.styleM.getTextStyle(this.objects.SUBCAPTION),  true, canvasWidth, canvasHeight/4);
			//Store the height
			canvasStartY = canvasStartY+subCaptionObj.height;
			canvasHeight = canvasHeight-subCaptionObj.height;
			//Create element for sub caption - to store height
			this.elements.subCaption = returnDataAsElement(0, 0, subCaptionObj.width, subCaptionObj.height);
			delete subCaptionObj;
		}
		//Now, if either caption or sub-caption was shown, we also need to adjust caption padding                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
		if (this.params.caption != "" || this.params.subCaption != "") {
			//Account for padding
			canvasStartY = canvasStartY+this.params.captionPadding;
			canvasHeight = canvasHeight-this.params.captionPadding;
		}
		//We now have canvasStartX, canvasStartY, canvasPlot & canvasHeight.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
		//Allot canvasWidth & canvasHeight to plotWidth and plotHeight
		this.plotWidth = canvasWidth;
		this.plotHeight = canvasHeight;
		//Also store X and Y Position
		this.plotX = canvasStartX;
		this.plotY = canvasStartY;
		//----------------------------------------------------------------------//
		//Now to initialise all other calculating methods before the chart can be drawn.
		//initialise containers and flags
		this.initContainers();
		// this.data is populated and hence called for initial processing of dataset                  
		this.calculateFunnelProps();
		// tracking whether the chart should have slicing functionlity; default is true
		if (this.params.isSliced || this.config.numSlicedFunnels>1) {
			// setting it to false
			this.config.sliceAble = false;
		}
		// method called to set initial functional behavior of the chart                                                                                                      
		this.setInitialMode();
	}
	/**
	 * setFunnelColors method sets fill and border colors
	 * of the funnels.
	 * @param 	arrStore	array with sub-arrays to store color
	 * 						values in
	 */
	private function setFunnelColors(arrStore:Array):Void {
		for (var p = 0; p<arrStore.length; ++p) {
			var objData:Object = arrStore[p];
			// string form of hexadecimal code stored, but in a form whose number equivalent can't be 
			// recognised by flash as hexadecimal
			var color:String = '';
			if (objData.color == undefined) {
				color = String(formatColor(this.colorM.getColor()));
				// hexadecimal color code stored for the funnel
				objData.color = parseInt(color, 16);
				// funnel color stored
				this.data[arrStore.length-p-1].color = objData.color;
			} else {
				// used to rectify the color in objData, stored in reverse order from this.data,
				// in the first for-loop in calculateFunnelProps method.
				objData.color = this.data[arrStore.length-p-1].color;
			}
			// border color evaluation                                            
			if (isNaN(objData.borderColor)) {				
				// we need string form of the funnel color to evaluate border color using ColorExt.getLightColor();
				// for color specified from XML, we don't have it stored in string format
				if (color == '') {
					// XML specified color formatted to string form
					var color:String = (objData.color).toString(16);
				}
				// border color evaluated                                                    
				objData.borderColor = parseInt(formatColor(ColorExt.getLightColor(color, 0.25).toString(16)), 16);
				// funnel border color stored
				this.data[arrStore.length-p-1].borderColor = objData.borderColor;
			} else {				
				// used to rectify the borderColor in objData, stored in reverse order from this.data,
				// in the first for-loop in calculateFunnelProps method.
				objData.borderColor = this.data[arrStore.length-p-1].borderColor;
			}
		}
	}
	/**
	 * calculateFunnelProps method calculates all requisites
	 * for rendering the funnels.
	 * @param	resetting	boolean to indicate if this call
	 *						is simply to find a better labeling
	 */
	private function calculateFunnelProps(resetting:Boolean):Void {
		// setting squeeze factor of the funnels (ellipses)
		if (this.params.is2D) {
			// if 2D, ellipse squeeze to straight line
			this.config.squeeze = 0;
		} else {
			// if 3D, funnel ellipses are real ellipses
			this.config.squeeze = this.config.funnelYScale;
		}
		// filtering data set and config if data to be streamlined for display (for funnelChart)
		if (this.params.streamlinedData) {
			if (!this.config.isInitialised && !resetting) {
				// decrementing the total number of funnels by one (top value doesnot corresponds to funnelling)
				this.num--;
				// if data with top value (array sorted) is set to slice, decrement the number of funnels to be sliced for
				// proper slicing ability of the chart (chart with more than one funnel sliced will lack slicing ability)
				if (this.data[this.data.length-1].isSliced) {
					this.config.numSlicedFunnels--;
				}
				// if data with top value (array sorted) is set to link and none others, then chart lacks linking option                                                                                                        
				// (chart with atleast one funnel linked will possess linking ability)
				if (this.data[this.data.length-1].link != '' && this.config.totalLinks == 1) {
					this.config.linksDefined = false;
				}
			}
			// setting top label in case of data streamlining                                                                                       
			var topLabel:String = this.data[this.data.length-1].labelText;
		}
		// proportion of plot area to be used for funnel rendering (excluding labels)                                                                                                        
		var ratio:Number = this.config.effectivePlotRatio;
		// upper width of topmost funnel (the broadest one)
		var maxWidth:Number = this.config.effectivePlotWidthRatio*this.plotWidth;
		//total height of all funnels cumulatively when all sliced in
		var maxHeight:Number = ratio*this.plotHeight;
		//----------------------------------------------//
		// to prevent odd shaped funnels, limitation applied on maxWidth
		// very wide issue
		if(maxWidth>maxHeight*3){
			// let maxWidth have the upper limit of thrice maxHeight
			maxWidth = maxHeight*3
			// config updated with the effective ratio value
			this.config.effectivePlotWidthRatio = MathExt.roundUp(maxWidth/this.plotWidth)
			// very thin issue
		}else if(maxWidth*3<maxHeight){
			// let maxWidth have the lower limit of one third maxHeight
			maxWidth = maxHeight/3
			// config updated with the effective ratio value
			this.config.effectivePlotWidthRatio = MathExt.roundUp(maxWidth/this.plotWidth)
			// flag updated
			this.config.ratioSet = true
		}
		//----------------------------------------------//
		// semi-minor axis lenght of the uppermost funnel
		// semi-minor axis length of upper ellipse of uppermost funnel will add up to make effective height=ratio*plotHeight 
		var topAdjust:Number = this.config.squeeze*maxWidth/2;
		// total free space vertically, to be distributed in a slicing funnel system (including uppermost and bottommost free spaces)
		var vFreeSpace:Number = (1-ratio)*this.plotHeight;
		// a temporary array created to process dataset
		var arrTemp:Array = new Array();
		// number of funnels to be rendered
		var funnelNum:Number = (this.params.streamlinedData) ? this.data.length-1 : this.data.length;
		// first loop to process dataset 
		for (var p = 0; p<funnelNum; ++p) {
			var objData:Object = new Object();
			// input value of the funnel
			objData.inputValue = (!this.params.streamlinedData && p == funnelNum-1) ? null : this.data[p+1].value;
			// output value of the funnel ()
			objData.outputValue = this.data[p].value;
			// replicating dataset in a local sub-repository
			for (var q:String in this.data[p]) {
				objData[q] = this.data[p][q];
			}
			// funnel slice status stored
			objData.isSliced = (this.params.isSliced) ? true : objData.isSliced;
			//-------------------------------// 
			// preassigned id value is no more required ! We need a different value by the same name
			objData.id = p;
			objData.topLabel = (p == funnelNum-1 && this.params.streamlinedData) ? topLabel : null;
			//----------------global properties stored-------------------//  
			objData.objLabelProps = this.styleM.getTextStyle(this.objects.DATALABELS);
			objData.showLabelsAtCenter = this.params.showLabelsAtCenter;
			objData.lineThickness = this.params.funnelBorderThickness;
			objData.squeeze = this.config.squeeze;
			objData.is2D = this.params.is2D;
			objData.smartLineColor = this.params.smartLineColor;
			objData.smartLineThickness = this.params.smartLineThickness;
			objData.smartLineAlpha = this.params.smartLineAlpha;
			objData.enableSmartLabels = this.params.enableSmartLabels
			//-------------------------------------//   
			// local sub-repository stored in local repository
			arrTemp.push(objData);
		}
		// for funnel chart
		if (this.params.streamlinedData) {
			// getting difference between output and input values for the funnel
			var netFunneledValue:Number = arrTemp[arrTemp.length-1].inputValue-arrTemp[0].outputValue;
		}
		// local repository reversed for further processing w.r.t input/output values                                                          
		arrTemp.reverse();
		// method called to set colors for the funnels; called at this point
		this.setFunnelColors(arrTemp);
		// local variables declared 
		var r1:Number, r2:Number, v1:Number, v2:Number, h:Number;
		// loop runs for further processing
		for (var t = 0; t<arrTemp.length; ++t) {
			// for funnel chart
			if (this.params.streamlinedData) {
				v1 = arrTemp[t].inputValue;
				v2 = arrTemp[t].outputValue;
				// top ellipse radius
				r1 = (t == 0) ? maxWidth/2 : arrTemp[t-1].r2;
				// bottom ellipse radius
				if (this.params.useSameSlantAngle) {
					// for uniform slanting angle of funnels
					r2 = MathExt.roundUp(r1*v2/v1);
				} else {
					// for non-uniform slanting angle of funnels
					r2 = MathExt.roundUp(r1*Math.sqrt(v2/v1));
				}
				// radii stored in local repository
				arrTemp[t].r1 = r1;
				arrTemp[t].r2 = r2;
				// a Catch-22 situation exists here for calculation of funnel heights, so will work over 
				// it few steps later after calculating a prerequisite
			}
		}
		// minimum ellipse radius in the chart
		var r2Min:Number = (this.params.streamlinedData) ? arrTemp[arrTemp.length-1].r2 : 0.1*maxWidth;
		// vertical adjustment value due to lowermost ellipse bulging downward
		var bottomAdjust:Number = r2Min*this.config.squeeze;
		// Catch-22 requisite calculated for funnel chart		
		var netHeight:Number = maxHeight-topAdjust-bottomAdjust;		
		// for section chart
		if (!this.params.streamlinedData) {
			// uniform slanting angle of the funnels
			var funnelAng:Number = Math.atan(Number(String(maxWidth/2-r2Min))/netHeight);
		}
		// loop runs again (for Catch-22 issue)                                                     
		for (var t = 0; t<arrTemp.length; ++t) {
			if (this.params.streamlinedData) {
				// for funnel chart
				v1 = arrTemp[t].inputValue;
				v2 = arrTemp[t].outputValue;
				// height calculated overcoming Catch-22
				h = MathExt.roundUp(((v1-v2)/netFunneledValue)*netHeight);
			} else {
				// for section chart (no Catch-22 situation here)
				v1 = arrTemp[t].inputValue;
				v2 = arrTemp[t].outputValue;
				// height calculated 
				h = MathExt.roundUp((v2/this.config.sumOfValues)*netHeight);
				// radius of upper ellipse
				r1 = (t == 0) ? maxWidth/2 : arrTemp[t-1].r2;
				// radius of lower ellipse (uniform slanting angle of funnels always)
				r2 = MathExt.roundUp(Number(String(r1-h*Math.tan(funnelAng))));
				// radii stored in local repository
				arrTemp[t].r1 = r1;
				arrTemp[t].r2 = r2;
			}
			// remaining funnel parameters stored in repository
			arrTemp[t].h = h;
			arrTemp[t].x = this.plotWidth/2;
			arrTemp[t].y = Number(String(((t == 0) ? this.plotHeight-(vFreeSpace/2+maxHeight-topAdjust) : arrTemp[t-1].y+arrTemp[t-1].h)));
			arrTemp[t].gap = arrTemp[t].y;
			// for label placement support, a new property "R" denoting the abscissa is set
			if(!this.params.streamlinedData || (this.params.streamlinedData && this.params.useSameSlantAngle)){
				// property set simply to the lower ellipse radius
				arrTemp[t].R = arrTemp[t].r2 
			}else{
				// for non-uniform funnels:
				// if the required ratio is yet to obtain (can take this condition for any number 
				// of times initially, until it gets a non-zero height funnel)
				if(tanTheta==undefined){
					// checking for non-zero funnel height
					if(arrTemp[t].h != 0){
						// ratio evaluated to be used hence forth
						var tanTheta:Number = (arrTemp[t].r1-arrTemp[t].r2)/arrTemp[t].h
					}
					// property set simply to the lower ellipse radius (ratio is yet to use)
					arrTemp[t].R = arrTemp[t].r2
					// since ratio is known
				}else{
					// property set to value evaluated using ratio
					arrTemp[t].R = arrTemp[t-1].R-tanTheta*arrTemp[t].h
				}
			}
		}
		// a ratio calculated before reversing the temporary repository, to be passed 
		// in call for setting label text positions; will be used to displace labels 
		// horizontally to adjust change in its ordinate, maintaining slope on the funnel stack
		var ratio:Number = (arrTemp[0].r1-arrTemp[arrTemp.length-1].R)/netHeight
		// work done w.r.t. input/output value and hence repository reverted back to original order
		arrTemp.reverse();
		// local repository assigned to global one
		this.config.arrFunnel = arrTemp;
		// method called to set label positions and storage in repository
		this.setTxtPos(vFreeSpace/2, ratio);
	}
	/**
	 * setTxtPos method evaluates the label positions.
	 * @param	vFreeSpace	space available below or above
	 *						collapsed funnel stack
	 */
	private function setTxtPos(vFreeSpace:Number, ratio:Number):Void {
		// local references
		var squeeze:Number = this.config.squeeze;
		var lineThickness:Number = this.params.funnelBorderThickness;
		var labelDistance:Number = this.params.labelDistance;
		// declaring variables
		var txtWidth:Number, txtHeight:Number, objItem:Object, xPos:Number, yPos:Number, yMinMc:Number, objMetrics:Object;
		// TextFormat object instantiated to be used for text formatting (simulation only to obtain proper textfield dimensions)
		var fmtTest:TextFormat = new TextFormat();
		// getting the formatting parameters encapsulated in object
		var objTextProp:Object = this.styleM.getTextStyle(this.objects.DATALABELS);
		// assigning formatting parameters to the TextFormat instance
		fmtTest.font = objTextProp.font;
		fmtTest.size = objTextProp.size;
		fmtTest.bold = objTextProp.bold;
		fmtTest.italic = objTextProp.italic;
		fmtTest.underline = objTextProp.underline;
		fmtTest.letterSpacing = objTextProp.letterSpacing;
		fmtTest.leftMargin = objTextProp.leftMargin;
		// loop runs to set text positions		
		for (var i = 0; i<this.config.arrFunnel.length; ++i) {
			// reference of a specific funnel properties encapsulated
			objItem = this.config.arrFunnel[i];
			// ordinate of lower extremity of the funnel MC
			yMinMc = objItem.y+objItem.h+(objItem.r2*squeeze)+lineThickness/2;
			// getting the metrics of the text field for its label and formatted (simulation)
			objMetrics = fmtTest.getTextExtent(objItem.labelText);
			// width and height of the simulated textfield
			txtWidth = objMetrics.width;
			txtHeight = objMetrics.height;
			// setting initial label textfield position w.r.t funnel MC
			if (this.params.showLabelsAtCenter) {
				// for labels to be centered over the funnel
				xPos = Math.round(objItem.x-txtWidth/2);
				var yAdjustFactor:Number = (objItem.h<txtHeight*1.5) ? 1 : 1.5;
				yPos = Math.round(yMinMc-txtHeight*yAdjustFactor);
			} else {
				// for adjacent (right) placement of the labels 
				yPos = Math.round(yMinMc-(objItem.r2*squeeze)-txtHeight);				
				xPos = Math.round(objItem.x+objItem.R+labelDistance);				
			}			
			// saving label position and a label metric (textfield height)in central repository
			objItem.xTxt = xPos;
			objItem.yTxt = yPos;
			objItem.txtHeight = txtHeight;
			// for funnelChart mode and for top most funnel
			if(this.params.streamlinedData && i==this.config.arrFunnel.length-1){
				// abscissa of top label stored in respective location in repository
				objItem.topLabelX = this.config.topLabelX
			}
		}		
		// smart label algorithm follows (only for adjacent labeling)
		if (!this.params.showLabelsAtCenter && this.params.enableSmartLabels) {
			// array to store available vertical spaces for accomodation of labels without overlapping
			var arrSpace:Array = new Array();
			// array to store groups of overlapping labels
			var arrGroups:Array = new Array();
			// keeping track of if any overlapping label group is under tracking process
			var found:Boolean = false;
			// group numbering index initialised
			var groupIndex:Number = -1;
			// to record the number of labels in such a group
			var counter:Number;
			// loop runs to figure out such overlapping group of labels;
			// loop counter starts with penultimate funnel from bottom in stack order (since will work with pairs)
			for (var i = 1; i<this.config.arrFunnel.length; ++i) {
				// upper funnel of the pair
				var objItem1 = this.config.arrFunnel[i];
				// lower funnel of the pair
				var objItem2 = this.config.arrFunnel[i-1];
				// searching for overlap
				if (objItem2.h/2<objItem1.txtHeight/2) {
					// if a working group exists, will append to it, else will form a new group;
					// new group forming
					if (!found) {
						// counter initialised to one (since working on pair)
						counter = 1;
						// flag updated to show that a working group exists
						found = true;
						// sub-array formed for the new group
						arrGroups[++groupIndex] = new Array();
						// starting funnel id stored for the new group
						arrGroups[groupIndex][0] = i-1;
					}
					// counter incremented for the other one of the pair, irrespective of new group formed or not                                            
					counter++;
					// if no overlap found for the current pair
				} else {
					// if a working group exists
					if (found) {
						// update flag to show that there is no working group in existence,
						// to be used by following iterations
						found = false;
						// total number of members in the group recorded
						arrGroups[groupIndex][1] = counter;
					}
				}
				// termination of a working group at stack end
				if (i == this.config.arrFunnel.length-1 && found) {
					// though not required any more
					found = false;
					// total number of members in the group recorded
					arrGroups[groupIndex][1] = counter;
				}
				// space available for the current funnel for label placement (upper one of the pair)                                            
				arrSpace[i] = objItem2.h-objItem1.txtHeight/2-objItem2.txtHeight/2;
				// space available for the lowermost funnel for label placement
				if (i == 1) {
					arrSpace[0] = (this.plotHeight-(objItem2.y+objItem2.h)-objItem2.txtHeight)/2
				}
				// space available along the uppermost funnel for label placement                                            
				if (i == this.config.arrFunnel.length-1) {
					arrSpace[i+1] = objItem1.h-objItem1.txtHeight/2+this.config.squeeze*objItem1.r1+vFreeSpace;
				}
			}
			// loop runs to set label positions for no overlapping
			for (var i = 0; i<arrGroups.length; ++i) {
				// a temporary array formed to store the funnel ids of each group
				var arrTemp:Array = new Array();
				// id of funnel preceding the group
				var id:Number = arrGroups[i][0]-1;
				// ids of all funnels of the group stored
				for (var j = 0; j<arrGroups[i][1]; ++j) {
					arrTemp[j] = ++id;
				}
				// vertical space available below the grouped overlap
				var d1:Number = arrSpace[arrTemp[0]];
				// vertical space available above the grouped overlap
				var d2:Number = arrSpace[arrTemp[arrTemp.length-1]+1];
				//total overlapped amount to be calculated and hence initialised to zero
				var shortage:Number = 0;
				//total overlapped amount calculated 
				for (var u = 1; u<arrTemp.length; ++u) {
					shortage += arrSpace[arrTemp[u]];
				}
				shortage = Math.abs(shortage)
				// amount of downward shift of the group to avoid overlappings
				var downIniY:Number;
				// getting downward shift required
				if (shortage/2<=d1 && shortage/2<=d2) {
					// if shortage can be met by dispersing both ways equally (vertically)
					downIniY = shortage/2;
				} else if (shortage/2>d1) {
					// if shortage cannot be met by dispersing downward equally
					downIniY = d1;
				} else if (shortage/2>d2) {
					// if shortage cannot be met by dispersing upward equally
					downIniY = shortage-d2;
				} 
				// update space available above the uppermost funnel of the group;                                           
				// to be used in next group, if required
				var changeD2:Number = shortage-downIniY;
				// updated by decrementing the amount of space used up by this group
				arrSpace[arrTemp[arrTemp.length-1]+1] -= changeD2;
				// ordinate of the lowermost label of the group
				var yIni:Number = this.config.arrFunnel[arrTemp[0]].yTxt+downIniY;
				// resaving label ordinate (textfield height) in central repository
				for (var k = 0; k<arrTemp.length; ++k) {
					// funnel id in repository
					var id:Number = arrTemp[k];
					// reference of sub-repository for the funnel
					var objItem = this.config.arrFunnel[id];
					// variable to evaluate displacement in label ordinate initialised
					var delY:Number = objItem.yTxt
					// resaving ordinate of label for the funnel			
					objItem.yTxt = yIni-k*objItem.txtHeight;
					// displacement in label ordinate evaluated
					delY -= objItem.yTxt
					// label abscissa displaced to maintain funnel slope
					objItem.xTxt += delY*ratio					
				}				
			}
			// final step to eliminate any resulting overlap
			for (var i = 1; i<this.config.arrFunnel.length; ++i) {
				// upper funnel of the pair
				var objItem1:Object = this.config.arrFunnel[i];
				// lower funnel of the pair
				var objItem2:Object = this.config.arrFunnel[i-1];
				// searching for overlap
				if (objItem2.yTxt-objItem1.yTxt<objItem1.txtHeight/2+objItem2.txtHeight/2) {					
					// variable to evaluate displacement in label ordinate initialised
					var delY:Number = objItem1.yTxt					
					// textfield ordinate to match with the top of label of next lower funnel
					objItem1.yTxt = objItem2.yTxt-objItem2.txtHeight
					// displacement in label ordinate evaluated
					delY -= objItem1.yTxt
					// label abscissa displaced to maintain funnel slope
					objItem1.xTxt += delY*ratio					
				}
			}
		}		
	}
	/**
	 * setInitialMode method is called to determine initial 
	 * functional behavior of the chart.
	 */
	private function setInitialMode():Void {
		// chart be functioning to link specified references
		if (this.config.linksDefined) {
			this.config.enableSlicing = false;
			this.config.enableLinks = true;
			// chart be functioning so that funnels can be sliced in and out
		} else if (this.config.sliceAble) {
			this.config.enableSlicing = true;
			this.config.enableLinks = false;
		}
	}
	/**
	 * validateData method checks for if data provided are
	 * valid/proper to plot the chart (either streamlined or 
	 * not).
	 * @returns		result as true or false
	 */
	 private function validateData():Boolean {
		 var dataValue:Number
		 var arrTest:Array = this.config.arrFunnel
		 // testing for streamlined data
		 if (this.params.streamlinedData) {
			 // initial input value of the whole process
			 dataValue = this.data[this.data.length-1].value
			 // iterating over the dataset
			 for (var i=0;i<arrTest.length;++i) {
				 // seeking a different data value
				 if (dataValue != arrTest[i].value) {
					 // testing ends with success
					 return true
				 }
				 // value updated
				 dataValue = arrTest[i].value
			 }
			  // testing for sectionChart data
		 } else {
			 // if total of all data values is positive
			 if(this.config.sumOfValues>0){
				  // testing ends with success
				 return true
			 }
		 }
		 return false
	 }
	// -------------- VISUAL RENDERING METHODS ---------------------//
	/**
	* drawHeaders method renders the following on the chart:
	* CAPTION, SUBCAPTION
	*/
	private function drawHeaders():Void {
		//Sub-caption start y position
		var subCaptionY:Number = this.params.chartTopMargin;
		//Render caption
		if (this.params.caption != "") {
			var captionStyleObj:Object = this.styleM.getTextStyle(this.objects.CAPTION);
			captionStyleObj.align = "center";
			captionStyleObj.vAlign = "bottom";
			var captionObj:Object = createText(false, this.params.caption, this.cMC, this.dm.getDepth("CAPTION"), this.x + (this.width / 2), this.params.chartTopMargin, 0, captionStyleObj, true, this.elements.caption.w, this.elements.caption.h);
			//Add for sub-caption y position
			subCaptionY = subCaptionY+captionObj.height;
			//Apply animation
			if (this.params.animation) {
				this.styleM.applyAnimation(captionObj.tf, this.objects.CAPTION, this.macro, this.x + (this.width / 2) - (this.elements.caption.w/2), captionObj.tf._y, 100, null, null, null);
			}
			//Apply filters                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
			this.styleM.applyFilters(captionObj.tf, this.objects.CAPTION);
			//Delete
			delete captionObj;
			delete captionStyleObj;
		}
		//Render sub caption                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
		if (this.params.subCaption != "") {
			var subCaptionStyleObj:Object = this.styleM.getTextStyle(this.objects.SUBCAPTION);
			subCaptionStyleObj.align = "center";
			subCaptionStyleObj.vAlign = "bottom";
			var subCaptionObj:Object = createText(false, this.params.subCaption, this.cMC, this.dm.getDepth("SUBCAPTION"), this.x + (this.width / 2), subCaptionY, 0, subCaptionStyleObj, true, this.elements.subCaption.w, this.elements.subCaption.h);
			//Apply animation
			if (this.params.animation) {
				this.styleM.applyAnimation(subCaptionObj.tf, this.objects.SUBCAPTION, this.macro, this.x + (this.width / 2) - (this.elements.subCaption.w / 2), subCaptionObj.tf._y, 100, null, null, null);
			}
			//Apply filters                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
			this.styleM.applyFilters(subCaptionObj.tf, this.objects.SUBCAPTION);
			//Delete
			delete subCaptionObj;
			delete subCaptionStyleObj;
		}
		//Clear interval                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
		clearInterval(this.config.intervals.headers);
	}
	/** 
	 * draw method draws the funnel chart by calling various other 
	 * methods of this class.
	*/
	private function draw():Void {
		// if data set is appropriate for the chart rendering
		if(this.validateData()){
			// Create movie clip to hold funnels
			mcFunnelH = this.cMC.createEmptyMovieClip("mainHolder_mc", this.dm.getDepth('DATAPLOT'));		
			// Set it's X and Y
			mcFunnelH._x = this.plotX;
			mcFunnelH._y = this.plotY;
			// final call to draw chart from this class instance                                                                                                 
			this.drawChart();
			// invokation of initial chart animation by framework styleManager
			if (this.params.animation) {
				this.styleM.applyAnimation(mcFunnelH, this.objects.DATAPLOT, this.macro, mcFunnelH._x, mcFunnelH._y, 100, 100, -100, null);
			}
			this.styleM.applyFilters(mcFunnelH, this.objects.DATAPLOT);
		}
		// Clear sequence interval                                                                                                                                                                                                                                         
		clearInterval(this.config.intervals.plot);
	}
	/**
	 * drawChart method is the main method of this class
	 * responsible for rendering the funnels and setting
	 * interactivities.
	 */
	private function drawChart():Void {
		// storing reference of the this class instance, locally
		var insRef:FunnelChart = this;
		// loop runs to call for each funnel rendering
		for (var i = 0; i<this.config.arrFunnel.length; i++) {
			// movieclip created in respective depth to draw a full funnel in
			var mcTarget:MovieClip = mcFunnelH.createEmptyMovieClip('mcFunnel_'+i, i);
			// few global properties to be used by funnel instances
			this.config.arrFunnel[i].isInitialised = this.config.isInitialised;
			this.config.arrFunnel[i].isHollow = this.params.isHollow;
			this.config.arrFunnel[i].mc = mcTarget;
			// name of funnel instances
			var strName:String = 'funnel_'+i;
			// ultimately, Funnel class instantiated to render the full full funnel graphics and label
			// and, reference of the funnel instance stored in a central sub-repository under config
			this.config.objFunnels[strName] = new Funnel(this, mcTarget, this.config.arrFunnel[i]);
			// method called after this instantiation, to set its interactivities
			this.setEventHandlers(mcTarget, this.config.arrFunnel[i], this[strName]);
			// keeping reference of the movieclip associated with the funnel to be sliced due this drawChart call
			if (this.config.sliceAble && this.config.arrFunnel[i].isSliced) {
				this.config.slicedOneMcRef = mcTarget;
			}
			// disabling automatic tab indexing of funnel MCs
			mcTarget.tabEnabled = false
		}
		// funnels need to be placed vertically as required in overall slicing status
		if (this.num>1 && this.config.isInitialised) {
			// called without parameters - cause no slicing animation
			this.sliceFunnels();
		}
		// initially                                                                                           
		if (!this.config.isInitialised) {
			// method called to set horizontal placement of the funnelChart for best label accomodation 
			// visually, at the cost of left margin 
			if(!this.params.showLabelsAtCenter){
				this.resetChartForLabels();
			}
			// programmed to notify chart initialisation end
			mcFunnelH.onEnterFrame = function() {
				// for initial animation, after all funnels complete initial slicing animation
				// or, if initial animation is not required for the chart, by user specification
				if (insRef.config.finishStatusNum>=insRef.num || !insRef.params.animation || insRef.num == 1) {
					// chart initialisation status updated
					insRef.config.isInitialised = true;
					// notification call for chart initialisation end
					insRef.onChartRendered();
					// initialisation notification programme no more required
					delete this.onEnterFrame;
				}
			};
		}
	}
	/**
	 * onChartRendered method is called to notify end of chart
	 * initialisation.
	 */
	private function onChartRendered():Void {
		//Here, we can do any other action
	}
	/**
	 * resetChartForLabels method checks over best and most 
	 * visual display of the chart w.r.t label which may be 
	 * long enough to be truncated and reset chart for the 
	 * same.
	 */
	private function resetChartForLabels():Void {		
		// getting the bounding extremities of the funnel Chart along with labels
		var objMcMetrics:Object = mcFunnelH.getBounds(this.cMC);
		// evaluating need of chart shift to the left for best labels display
		var plotShiftX:Number = (objMcMetrics.xMax>this.plotWidth+this.params.chartLeftMargin) ? (objMcMetrics.xMax-this.plotWidth-this.params.chartLeftMargin) : 0;
		// evaluating maximum possible chart shifting to the left
		var maxShift:Number = (1-this.config.effectivePlotWidthRatio)*this.plotWidth/2;
		// amount of width to be decreased
		var widthCrunch:Number = Math.ceil(plotShiftX - maxShift)
		// ratio recalculation and chart recreation
		if (widthCrunch>0 && !this.config.ratioSet) {
			// ratio reset
			this.config.effectivePlotWidthRatio = MathExt.roundUp(((this.config.effectivePlotWidthRatio*this.plotWidth)-widthCrunch)/this.plotWidth, 3)
			// redraw process:
			// individual funnel properties need to be recalculated for redraw
			calculateFunnelProps(true);
			// to generate the chart
			drawChart();
			// no more recreation of chart, only shifting
		}else{
			// if ratio already set, without a single recreation (due special cases)
			if(this.config.ratioSet){
				// if required shift is more than  maximum possible
				if (plotShiftX>maxShift) {
					// alter to maximum possible value
					plotShiftX = maxShift;
				}
				// chart shifted                                                                                           
				mcFunnelH._x -= plotShiftX;
				// due recreations and ratio resets, situation obtained requiring no more recreation and ratio reset
			}else{
				// update flag
				this.config.ratioSet = true
				// chart shifted                                                                                           
				mcFunnelH._x -= plotShiftX;
			}
			// for the case of top label existing
			if(this.params.streamlinedData){
				// reference of the repository
				var _arr:Array = this.config.arrFunnel
				// text value of the topLabel
				var txtLabel:String = _arr[_arr.length-1].topLabel
				// reference of the topMost funnel MC, holding the topLabel
				var mcTop:MovieClip = _arr[_arr.length-1].mc
				// iterates to track the required textfield
				for(var i:String in mcTop){
					// selecting the required textfield
					if(mcTop[i] instanceof TextField && mcTop[i].text == txtLabel){
						// reference of the textfield obtained and stored in local variable
						var txtBox:TextField = mcTop[i]
					}
				}
				// conversion of textfield coordinates to global, for checking
				var objPt:Object = {x:txtBox._x, y:txtBox._y}
				mcTop.localToGlobal(objPt)
				this.cMC.globalToLocal(objPt)
				// if topLabel textfield is at all required to be shifted to right
				if(objPt.x<this.params.chartLeftMargin){
					// amount in pixels to be shifted to the right
					var txtXshift:Number = Math.round(this.params.chartLeftMargin-objPt.x)
					// textfield taking up final and proper position
					txtBox._x += txtXshift
					// to be used in chart recreation processes due interactions
					this.config.topLabelX = txtBox._x
				}
			}
		}
	}
	/**
	 * recreate method is called to regenerate the funnels
	 * with different parameters with fresh rendering.
	 */
	public function recreate():Void {
		// there are elements to be cleaned for proper next redraw
		cleanUp();
		// individual funnel properties need to be recalculated for redraw
		calculateFunnelProps();
		// to generate the chart
		drawChart();
	}
	/**
	 * createNewTween method creates Tween instances per
	 * funnel to control its slicing motions.
	 */
	private function createNewTween(mc:MovieClip, id:Number):Void {
		var insRef:FunnelChart = this;
		// generating tween instance name as string
		var tweenName:String = 'tween'+id;
		// tween instantiated
		this.config.objTweens[tweenName] = new Tween(mc, "_y", mx.transitions.easing.Strong.easeInOut, mc._y, mc._y, 0, true);
		// continuing animation stopped if any
		this.config.objTweens[tweenName].stop();
		// animation end event handling defined
		this.config.objTweens[tweenName].onMotionFinished = function() {
			if (!insRef.config.isInitialised) {
				// for initial animation, status of this funnel animation end updated by incrementing global counter
				insRef.config.finishStatusNum++;
			}
			// otherwise, set slicing funnel reference to none                                                                  
			insRef.config.slicingMcRef = null;
		};
	}
	//------------------------ Animating methods --------------------------//
	/**
	 * sliceFunnels method is called to slice the funnel set
	 * either animating or displacement in a shot.
	 */
	private function sliceFunnels():Void {
		// slicing is relevant for a multi-funnel chart only
		if (this.num>1) {
			// arguments passed by delegation, when slicing animation is required
			// the funnel MC in focus for slicing
			var mc:MovieClip = arguments.caller.mc;
			// local reference of final repository
			var arrTemp:Array = this.config.arrFunnel;
			// local reference of initial repository
			var arrPerm:Array = this.data;
			// Invoked due user interaction   
			if (arguments.caller.mc != undefined) {
				// if funnel clicked is the funnel currently sliced
				if (this.config.slicedOneMcRef == mc) {
					// slicing status of the funnel updated
					mc.isSliced = false;
					// global reference of sliced funnel is set to none
					this.config.slicedOneMcRef = null;
					// both repositories updated
					arrTemp[mc.id].isSliced = false;
					arrPerm[mc.id].isSliced = false;
					// else if, funnel clicked is not the funnel currently sliced
				} else {
					// current funnel's slicing status updated
					this.config.slicedOneMcRef.isSliced = false;
					// both repositories updated for current funnel
					arrTemp[this.config.slicedOneMcRef.id].isSliced = false;
					arrPerm[this.config.slicedOneMcRef.id].isSliced = false;
					// slicing status of the funnel clicked is updated
					mc.isSliced = true;
					// both repositories updated for clicked funnel
					arrTemp[mc.id].isSliced = true;
					arrPerm[mc.id].isSliced = true;
					// global reference of sliced funnel is set to the clicked one
					this.config.slicedOneMcRef = mc;
				}
				//not invoked by user (due chart recreation)
			} else {
			}
			//---------------------------------------------------//
			// number of seperations vertically in the chart (top, bottom and any in between funnels);
			// here 2 is the initialisation value for chart not sliced globally and final value evaluated in 
			// following steps
			var sepSpaceNum:Number = (this.params.isSliced) ? ((this.params.streamlinedData)?this.data.length:this.data.length+1) : 2;
			// loop runs to evaluate the final value of sepSpaceNum, for chart not sliced globally
			if (!this.params.isSliced) {
				for (var p = 0; p<arrTemp.length; ++p) {
					if (arrTemp[p].isSliced) {
						if (p == 0) {
							sepSpaceNum++;
						} else if (p == arrTemp.length-1) {
							if (!arrTemp[p-1].isSliced) {
								sepSpaceNum++;
							}
						} else {
							sepSpaceNum++;
							if (!arrTemp[p-1].isSliced) {
								sepSpaceNum++;
							}
						}
					}
				}
			}
			// total free space available vertically                                                                          
			var vFreeSpace:Number = (1-this.config.effectivePlotRatio)*this.plotHeight;
			// vertical free space available for each space
			var vSpace:Number = MathExt.roundUp(vFreeSpace/sepSpaceNum);
			//---------------------------------------------------//
			// ordinate of funnels initialised and will be updated incrementally within loop 
			// while traversing up the funnel stack (bottom to top visually)
			// lower bulge height of lowermost funnel
			var bottomAdjust:Number = arrTemp[0].r2*this.config.squeeze;
			// ordinate value initialised (center of lower ellipse of lowermost funnel)
			var yPos:Number = this.plotHeight-vSpace-bottomAdjust;
			// loop runs to set funnel ordinates
			for (var i = 0; i<arrTemp.length; ++i) {
				// reference of the funnel MC
				var _mc:MovieClip = arrTemp[i].mc;
				// decremented by height difference between upper an lower ellipses (w.r.t. center)of the funnel				
				yPos -= arrTemp[i].h;
				// since checking for space below a funnel, so first one or lowest one is excluded
				if (i != 0) {
					var mcNextLower:MovieClip = _mc._parent.getInstanceAtDepth(_mc.getDepth()-1);
					// If space required between this and the next lower one ... second condition 
					// is for if funnel.isSliced is true for i=0
					if (_mc.isSliced || mcNextLower.isSliced) {
						// vertical free spacing added
						yPos -= vSpace;
					}
				}
				var addToY:Number;
				// getting current ordinate of the funnel
				// if chart static currently
				if (this.config.slicingMcRef == null) {
					addToY = arrTemp[i].y;
					// else if, chart undergoing slicing animation due interaction
				} else {
					addToY = arrTemp[i].gap+_mc._y;
				}
				// change in ordinate to occur for the funnel
				var delY:Number = MathExt.roundUp(yPos-addToY)
				// ordinate of the funnel MC updated
				arrTemp[i].y = yPos;
				// creating Tween instance for each funnel to handle slicing animation
				if (!this.config.isInitialised) {
					this.createNewTween(_mc, i);
				}
				if (this.config.changingDimension || !(this.config.isInitialised || this.params.animation) || this.config.isChangingMode) {
					//('case 1');
					//1. chart recreation occuring due changing dimension (2D/3D)
					//2. initial creation of chart without animation
					//3. chart recreation occuring due change in interactivity mode (enabling links/slicing)
					_mc._y += delY;
				} else if ((!this.config.isInitialised && this.params.animation) || (this.config.isInitialised && this.config.enableSlicing)) {
					//('case 2');
					//1. initial creation of chart with animation
					//2. due slicing interactivity
					var tweenName:String = 'tween'+i;
					var tweenInsRef:Tween = this.config.objTweens[tweenName];
					tweenInsRef.stop();
					tweenInsRef.continueTo(_mc._y+delY, 0.4);
				} else {
					//('case 3');
				}
			}
			// updating mode toggling process status
			if (this.config.isChangingMode) {
				this.config.isChangingMode = false;
			}
			// updating reference of slicing funnel MC                                                                    
			this.config.slicingMcRef = mc;
		}
		if (!this.config.isInitialised) {
			// clearing programmed initial animation 
			clearInterval(this.config.intervals.sliceAnimation);
		}
	}
	/**
	 * animateTo2D is the method called to change the dimension
	 * of the chart in animation, from 3D to 2D.
	 */
	private function animateTo2D():Void {
		// storing the reference of the funnelChart instance
		var instanceRef = this;
		// applying a blank onRelease function on the parent mc of the funnels to disable the funnel(mc) level 
		// mouse interaction during transition
		mcFunnelH.onRelease = function() {
		};
		// hand cursor due to former action is avoided
		mcFunnelH.useHandCursor = false;
		// flag updated to indicate that dimension changing animation is under progress
		this.config.changingDimension = true;		
		// intended number of steps to change the dimension 
		var steps:Number = 5;
		// perspective incrementing factor (3D to 2D) in each 'step'
		var scaleDecrement:Number = Math.ceil(this.config.funnelYScale*100/steps);
		// name of control movieclip as string
		var strMcName:String = 'mcControl';
		// clearing any uncleared continuing transtion to 3D call due to premature toggling of                                                                        
		// context menu option (2D/3D)
		delete this.cMC[strMcName].onEnterFrame;
		// removing the MC if any
		this.cMC[strMcName].removeMovieClip();
		// creating the control MC
		var mcControl:MovieClip = this.cMC.createEmptyMovieClip(strMcName, this.cMC.getNextHighestDepth());
		// all set to go for the required transtion
		mcControl.onEnterFrame = function() {			
			// getting the current status of the yScale of the funnelChart in scale of 100
			var scale:Number = instanceRef.config.funnelYScale*100;			
			// if perspective is yet to give the final 2D look
			if (scale>0) {				
				// if scaling can be altered by the value of 'scaleDecrement'
				if (scale>scaleDecrement) {					
					scale -= scaleDecrement;					
					// else, just set the value to minimum (i.e 0)
				} else {
					scale = 0;
				}				
				// scale value assigned on the scale of 1 (not 100)
				instanceRef.config.funnelYScale =  MathExt.roundUp(scale/100);				
				// call to recreate chart
				instanceRef.recreate();
				// else if transition is over, put an end to the process
			} else {				
				// flag updated to indicate that dimension changing animation is over
				instanceRef.config.changingDimension = false;
				// empty onRelease handler set previously to disable funnel(mc) mouse interaction requirement is over and hence deleted
				delete instanceRef.mcFunnelH.onRelease;
				// to end up the process
				delete this.onEnterFrame;
				// garbage cleaned
				this.removeMovieClip();
			}
		};
	}
	/**
	 * animateTo3D is the method called to change the dimension
	 * of the chart in animation, from 2D to 3D.
	 */
	private function animateTo3D():Void {
		// storing the reference of the funnelChart instance
		var instanceRef = this;
		// applying a blank onRelease function on the parent mc of the funnels to disable the funnel(mc) level 
		// mouse interaction during transtion
		mcFunnelH.onRelease = function() {
		};
		// hand cursor due to former action is avoided
		mcFunnelH.useHandCursor = false;
		// flag updated to indicate that dimension changing animation is under progress
		this.config.changingDimension = true;
		// intended number of steps to change the dimension
		var steps:Number = 5;
		// perspective decrementing factor (2D to 3D) in each 'step'
		var scaleIncrement:Number = this.params.funnelYScale/steps;		
		scaleIncrement = Math.ceil(scaleIncrement)		
		// name of control movieclip as string
		var strMcName:String = 'mcControl';
		// clearing any uncleared continuing transtion to 3D call due to premature toggling of                                                                        
		// context menu option (2D/3D)
		delete this.cMC[strMcName].onEnterFrame;
		// removing the MC if any
		this.cMC[strMcName].removeMovieClip();
		// creating the control MC
		var mcControl:MovieClip = this.cMC.createEmptyMovieClip(strMcName, this.cMC.getNextHighestDepth());
		// all set to go for the required transtion
		mcControl.onEnterFrame = function() {
			// getting the current status of the yScale of the funnelChart in scale of 100
			var scale:Number = instanceRef.config.funnelYScale*100;
			// if perspective is yet to give the final 3D look
			if (scale<instanceRef.params.funnelYScale) {
				// if scaling can be altered by the value of 'scaleIncrement'
				if (instanceRef.params.funnelYScale-scale>scaleIncrement) {
					scale += scaleIncrement;
					// else, just assign the final scale value
				} else {
					scale = instanceRef.params.funnelYScale;
				}
				// scale value assigned on the scale of 1 (not 100)
				instanceRef.config.funnelYScale = MathExt.roundUp(scale/100);
				// call to recreate chart
				instanceRef.recreate();
			} else {
				// flag updated to indicate that dimension changing animation is over
				instanceRef.config.changingDimension = false;
				// empty onRelease handler set previously to disable funnel(mc) mouse interaction requirement is over and hence deleted
				delete instanceRef.mcFunnelH.onRelease;
				// to end up the process
				delete this.onEnterFrame;
				// garbage cleaned
				this.removeMovieClip();
			}
		};
	}
	//---------------------------Interactivity Methods---------------------------------//
	/**
	 * setEventHandlers method sets interactivity of the funnels
	 * through event handlers assigned to the respective movieclips.
	 */
	private function setEventHandlers(_mc:MovieClip, objProps:Object, funnelRef):Void {
		var funnelInsRef = funnelRef;
		var link:String = objProps.link;
		var toolText:String = objProps.toolText;
		var insRef:FunnelChart = this;
		//---------------------//
		var fnRollOver:Function;
		//Create Delegate for RollOver function funnelOnRollOver
		fnRollOver = Delegate.create(this, funnelOnRollOver);
		//Set the mc
		fnRollOver.mc = _mc;
		//Set the link
		fnRollOver.link = link;
		//Set the tooltext
		fnRollOver.toolText = toolText;
		//assigning the delegates to movie clip handler
		_mc.onRollOver = fnRollOver;
		//---------------------//
		var fnRollOut:Function;
		//Create Delegate for RollOut function funnelOnRollOut
		fnRollOut = Delegate.create(this, funnelOnRollOut);
		//Set the mc
		fnRollOut.mc = _mc;
		//assigning the delegates to movie clip handler
		_mc.onRollOut = _mc.onReleaseOutside=fnRollOut;
		//---------------------//
		if (this.params.clickURL == '') {
			var fnRelease:Function;
			if (this.config.enableLinks && link != '') {
				//Create Delegate for onRelease function funnelOnClick
				fnRelease = Delegate.create(this, funnelOnClick);
				//Set the link
				fnRelease.link = link;
				//assigning the delegates to movie clip handler
				_mc.onRelease = fnRelease;
			}
			// setting the mouse release interaction of slicing in and out of individual funnels                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
			if (this.config.enableSlicing && this.config.arrFunnel.length>1) {
				// Create Delegate for onRelease function sliceFunnels;
				// parameters will be passed for slicing animation
				fnRelease = Delegate.create(this, sliceFunnels);
				//set reference of the clicked funnel mc
				fnRelease.mc = _mc;
				//assigning the delegates to movie clip handler
				_mc.onRelease = fnRelease;
			}
		}
	}
	/**
	 * funnelOnRollOver method controls rollover event of funnels.
	 */
	private function funnelOnRollOver():Void {
		var _mc:MovieClip = arguments.caller.mc;
		var link:String = arguments.caller.link;
		//
		var strDisplay:String = arguments.caller.toolText;
		if (strDisplay != '' && this.params.showToolTip) {
			this.tTip.setText(strDisplay);
			this.tTip.show();
		}
		if ((link == '' || link == undefined || !this.config.enableLinks) && this.params.clickURL == '') {
			_mc.useHandCursor = false;
		}
		_mc.onMouseMove = Delegate.create(this, funnelOnMouseMove);
	}
	/**
	 * funnelOnRollOut method controls rollout event of funnels.
	 */
	private function funnelOnRollOut():Void {
		this.tTip.hide();
		var _mc:MovieClip = arguments.caller.mc;
		delete _mc.onMouseMove;
	}
	/**
	 * funnelOnMouseMove method controls tooltip display.
	 */
	private function funnelOnMouseMove():Void {
		this.tTip.rePosition();
	}
	/**
	 * funnelOnClick method controls release event of funnels.
	 */
	private function funnelOnClick():Void {
		super.invokeLink(arguments.caller.link);
	}
	/**
	 * setContextMenu method sets context menu options and its 
	 * functionalities.
	 */
	private function setContextMenu():Void {
		// ContextMenu instance is created
		var cmCustom:ContextMenu = new ContextMenu();
		// hide the default menu items
		cmCustom.hideBuiltInItems();
		if (this.params.showPrintMenuItem){
			//Create a print chart contenxt menu item
			var printCMI : ContextMenuItem = new ContextMenuItem ("Print Chart", Delegate.create (this, printChart));
			//Push print item.
			cmCustom.customItems.push (printCMI);
		}
		//If the export data item is to be shown
		if (this.params.showExportDataMenuItem){
			cmCustom.customItems.push(super.returnExportDataMenuItem());
		}
		//Add export chart related menu items to the context menu
		this.addExportItemsToMenu(cmCustom);
		if (this.params.showFCMenuItem){
			//Push "About FusionCharts" Menu Item
			cmCustom.customItems.push(super.returnAbtMenuItem());		
		}
		// enabled status of the view 2D/3D options (always true, their visibility changes only) 
		var isTo2DCMIEnabled:Boolean = true;
		var isTo3DCMIEnabled:Boolean = true;
		// initially, if links are defined for atleast one funnel, then the initial mode of user interaction is set to 'Enable Links'
		if (this.config.linksDefined && this.config.sliceAble && this.config.arrFunnel.length>1 && this.params.clickURL=='') {
			// setting enable status of the 2 menu items
			var isSlicingCMIEnabled:Boolean = true;
			var isLinkCMIEnabled:Boolean = false;
			// instantiating ContextMenuItem for each menu item
			var cmiSlicing:ContextMenuItem = new ContextMenuItem("Enable Slicing Movement", movementHandler, true, isSlicingCMIEnabled);
			var cmiLink:ContextMenuItem = new ContextMenuItem("Enable Links", linkHandler, false, isLinkCMIEnabled);
		}
		//------------------------------------------------------------------------------------------------//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
		if (!this.params.is2D) {
			var cmiTo2D:ContextMenuItem = new ContextMenuItem("View 2D", to2DHandler, true, isTo2DCMIEnabled);
			var cmiTo3D:ContextMenuItem = new ContextMenuItem("View 3D", to3DHandler, true, isTo3DCMIEnabled, false);
		}
		//------------------------------------------------------------------------------------------------//                                                                                                                                                                            
		// inclusion of the items in the custom items section of context menu 
		if (this.config.linksDefined && this.config.sliceAble && this.config.arrFunnel.length>1 && this.params.clickURL=='') {
			cmCustom.customItems.push(cmiSlicing);
			cmCustom.customItems.push(cmiLink);
		}
		if (!this.params.is2D) {
			cmCustom.customItems.push(cmiTo2D);
			cmCustom.customItems.push(cmiTo3D);
		}
		// FunnelChart instance reference is stored                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
		var instanceRef = this;
		// functions invoked due selection of the menu items are defined
		function to2DHandler(obj, item) {
			cmiTo2D.visible = false;
			cmiTo3D.visible = true;
			instanceRef.animateTo2D();
		}
		function to3DHandler(obj, item) {
			cmiTo2D.visible = true;
			cmiTo3D.visible = false;
			instanceRef.animateTo3D();
		}
		function linkHandler(obj, item) {
			// disabling action due choice of this option during transition between 2D and 3D
			if (!instanceRef.config.changingDimension) {
				instanceRef.config.isChangingMode = true;
				// enabling/disabling the ContextMenuItems
				cmiSlicing.enabled = true;
				cmiLink.enabled = false;
				// updating flags about current menu enable status
				instanceRef.config.enableLinks = true;
				instanceRef.config.enableSlicing = false;
				// call to redraw; no change in overall view
				instanceRef.recreate();
			}
		}
		function movementHandler(obj, item) {
			// disabling action due choice of this option during transition between 2D and 3D
			if (!instanceRef.config.changingDimension) {
				instanceRef.config.isChangingMode = true;
				cmiSlicing.enabled = false;
				cmiLink.enabled = true;
				instanceRef.config.enableLinks = false;
				instanceRef.config.enableSlicing = true;
				// call to redraw; no change in overall view
				instanceRef.recreate();
			}
		}	
		// applying the custom menu formed to the chart movieclip
		mcFunnelH._parent.menu = cmCustom;
		//Clear interval
		clearInterval(this.config.intervals.menu);
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
		strData = strQ + "Label" + strQ + strS + strQ + "Value" + strQ + strLB;
		//Iterate through each data-item and add it to the output
		for (i = this.num; i >= 0; i--) {
			strData += strQ + this.data[i].label + strQ + strS + strQ + ((this.params.exportDataFormattedVal==true)?((this.params.showPercentValues==true)?(this.data[i].percentValue + "%"):(this.data[i].displayValue)):(this.data[i].value)) + strQ + ((i>0)?strLB:""); 
		}
		return strData;
	}
}
