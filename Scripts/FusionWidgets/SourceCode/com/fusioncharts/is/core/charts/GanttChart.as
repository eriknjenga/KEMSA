/**
* @class GanttChart
* @author InfoSoft Global(P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright(C) InfoSoft Global Pvt. Ltd. 2005-2006
* GanttChart extends the Chart class to render the
* functionality of a Gantt chart.
*/
//Import parent class
import com.fusioncharts.is.core.Chart;
import mx.data.encoders.Num;
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
//Date-time class
import com.fusioncharts.is.helper.FCDateTime;
//Legend
import com.fusioncharts.is.helper.Legend;
//FusionCharts data-grid
import com.fusioncharts.is.helper.FCGrid;
//Color Manager
import com.fusioncharts.is.colormanagers.GanttColorManager;
//Scroll bar
import com.fusioncharts.is.components.FCChartHScrollBar;
//External Interface - to expose methods via JavaScript
import flash.external.ExternalInterface;
class com.fusioncharts.is.core.charts.GanttChart extends Chart {
	//Color Manager for this chart
	public var colorM:GanttColorManager;
	//Containers to store chart data
	private var categories:Array;
	private var processes:Array;
	private var tasks:Array;
	private var milestones:Array;
	private var trendlines:Array;
	private var connectors:Array;
	//Data grid columns
	private var dataColumn:Array;
	//Legend items
	private var legendItems:Array;
	//Counters
	private var numCat:Number;
	private var numProcess:Number;
	private var numTasks:Number;
	private var numMilestones:Number;
	private var numTrendlines:Number;
	private var numConnectors:Number;
	private var numDataColumns:Number;
	private var numLegendItems:Number;
	//Cache for styles
	private var styleCache:Object;
	//Data-grid for the chart
	private var datagrid:FCGrid;	
	//Category extension grid
	private var catExtGrid:FCGrid;
	//References to movie clips
	//Movie clip to store the entire left side data grid.
	private var datagridMC:MovieClip;
	//Movie clip that stores the entire right side scrollable content
	private var scrollContentMC:MovieClip;
	//Reference to legend component of chart
	private var lgnd:Legend;
	//Reference to legend movie clip
	private var lgndMC:MovieClip;
	/**
	* Constructor function. We invoke the super class'
	* constructor.
	*/
	function GanttChart(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Log additional information to debugger
		//We log version from this class, so that if this class version
		//is different, we can log it
		this.log("Version", _version, Logger.LEVEL.INFO);
		this.log("Chart Type", "Gantt Chart", Logger.LEVEL.INFO);
		//List Chart Objects and set them in arrObjects array defined in super parent class.
		this.arrObjects = new Array("BACKGROUND", "CANVAS", "CAPTION", "SUBCAPTION", "TASKS", "TASKLABELS", "TASKDATELABELS", "MILESTONES", "CONNECTORS", "TRENDLINES", "TRENDVALUES", "TOOLTIP", "LEGEND");
		super.setChartObjects();
		//Initialize containers
		this.categories = new Array();
		this.processes = new Array();
		this.tasks = new Array();
		this.milestones = new Array();
		this.trendlines = new Array();
		this.connectors = new Array();
		this.dataColumn = new Array();
		this.legendItems = new Array();
		//Initialize counters
		this.numCat = 0;
		this.numProcess = 0;
		this.numTasks = 0;
		this.numMilestones = 0;
		this.numTrendlines = 0;
		this.numConnectors = 0;
		this.numDataColumns = 0;
		this.numLegendItems = 0;
		//Initiate style cache
		this.styleCache = new Object();
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
		if (this.numProcess == 0)	{
			tfAppMsg = this.renderAppMessage (_global.getAppMessage ("NODATA", this.lang));
			//Add a message to log.
			this.log ("No Data to Display", "Either processes or tasks were not found in the XML data document provided. If your system generates data based on parameters passed to it using dataURL, please make sure that dataURL is URL Encoded.", Logger.LEVEL.ERROR);
			//Expose rendered method
			this.exposeChartRendered();
			//Also raise the no data event
			this.raiseNoDataExternalEvent();
		} else {			
			//Detect minimum and maximum dates
			this.detectDateLimits();			
			//Set Style defaults
			this.setStyleDefaults();
			//Cache styles that get re-used
			this.cacheStyles();
			//Allot the depths for various charts objects now
			this.allotDepths();
			//Set the container for annotation manager
			this.setupAnnotationMC();
			//Set up the main scrollable content MC
			this.setupScrollContentMC();
			//Set up the category data grids
			this.setupCatDataGrids();			
			//Set up the data grid for the chart
			this.setupDataGrid();			
			//Calculate co-ordinates
			this.calculateCoords();			
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
			//Draw the canvas
			this.config.intervals.canvas = setInterval(Delegate.create(this, drawCanvas) , this.timeElapsed);
			//Update timer
			this.timeElapsed =(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.CANVAS):0;			
			//Draw headers
			this.config.intervals.headers = setInterval(Delegate.create(this, drawHeaders) , this.timeElapsed);			
			//Legend
			this.config.intervals.legend = setInterval(Delegate.create(this, drawLegend) , this.timeElapsed);
			//Draw the categories
			this.config.intervals.categoryGrid = setInterval(Delegate.create(this, drawCategoryGrid) , this.timeElapsed);			
			//Draw the data grid
			this.config.intervals.datagrid = setInterval(Delegate.create(this, drawDataGrid) , this.timeElapsed);
			//Draw the scroll bars
			this.config.intervals.scrollBars = setInterval(Delegate.create(this, drawScrollBars) , this.timeElapsed);						
			//Draw the tasks
			this.config.intervals.tasks = setInterval(Delegate.create(this, drawTasks), this.timeElapsed);
			//Update timer
			this.timeElapsed +=(this.params.animation) ? this.styleM.getMaxAnimationTime(this.objects.CAPTION, this.objects.SUBCAPTION, this.objects.LEGEND, this.objects.TASKS):0;
			//Task Labels			
			this.config.intervals.taskLabels = setInterval(Delegate.create(this, drawTaskLabels), this.timeElapsed);			
			//Milestones
			this.config.intervals.milestones = setInterval(Delegate.create(this, drawMileStones), this.timeElapsed);			
			//Connectors
			this.config.intervals.connectors = setInterval(Delegate.create(this, drawConnectors), this.timeElapsed);			
			//Trendlines
			this.config.intervals.trend = setInterval(Delegate.create(this, drawTrend), this.timeElapsed);			
			//Render the annotations above the chart
			this.config.intervals.annotationsAbove = setInterval(Delegate.create(this, renderAnnotationAbove) , (this.params.annRenderDelay==undefined || isNaN(Number(this.params.annRenderDelay)))?(this.timeElapsed):(Number(this.params.annRenderDelay)*1000));
			//Dispatch event that the chart has loaded.
			this.config.intervals.renderedEvent = setInterval(Delegate.create(this, exposeChartRendered) , this.timeElapsed);			
		}
	}
	/**
	 * setupColorManager method sets up the color manager for the chart.
	  *	@param	paletteId	Palette Id for the chart.
	 *	@param	themeColor	Color code if the chart uses single color theme.
	*/
	private function setupColorManager(paletteId:Number, themeColor:String):Void{
		this.colorM = new GanttColorManager(paletteId,themeColor);
	}
	/**
	 * returnDataAsProcess method encapsulates the properties of each process element
	 * and returns as an Object.
	*/
	private function returnDataAsProcess(label:String, link:String, id:String, font:String, fontColor:String, fontSize:Number, isBold:Boolean, isItalic:Boolean, isUnderline:Boolean, align:String, vAlign:String, bgColor:String, bgAlpha:Number):Object {
		//Create an object to encapsulate
		var processObj:Object = new Object();
		processObj.label = label;
		processObj.link = link;
		processObj.id = id;
		//Font properties
		processObj.font = font;
		processObj.fontColor = fontColor;
		processObj.fontSize = fontSize;
		//Text bold, italics and underline properties
		processObj.isBold = isBold;
		processObj.isItalic = isItalic;
		processObj.isUnderline = isUnderline;		
		//Align positions
		processObj.align = align;
		processObj.vAlign = vAlign;
		//Alignment can either be left, center or right only
		if (processObj.align!="left" && processObj.align!="right" && processObj.align!="center"){
			//Default to left.
			processObj.align = "left";
		}
		//Fit vertical alignment for backward compatibility
		switch (processObj.vAlign){
		case "left":
			processObj.vAlign = "top";
			break;
		case "center":
			processObj.vAlign = "middle";
			break;
		case "right":
			processObj.vAlign = "bottom";
			break;
		}
		if (processObj.vAlign!="top" && processObj.vAlign!="middle" && processObj.vAlign!="bottom"){
			//Default to middle.
			processObj.align = "middle";
		}
		//Background properties
		processObj.bgColor = bgColor;
		processObj.bgAlpha = bgAlpha;
		//Return
		return processObj;
	}
	/**
	 * returnDataAsTask method encapsulates the properties of a task element and returns it
	 * as an object.
	 * 
	*/
	private function returnDataAsTask(processId:String, label:String, id:String, link:String, start:FCDateTime, end:FCDateTime, showAsGroup:Boolean, percentComplete:Number, animation:Boolean, font:String, fontColor:String, fontSize:Number, color:String, alpha:Number, showBorder:Boolean, borderColor:String, borderThickness:Number, borderAlpha:Number, height:String, topPadding:String, showLabel:Boolean, showPercentLabel:Boolean, showStartDate:Boolean, showEndDate:Boolean, toolText:String):Object {
		//Create object to return
		var taskObj:Object = new Object();
		//Process id for this task
		taskObj.processId = processId;
		//Label and id of this task
		taskObj.label = label;
		taskObj.id = id;
		//Link
		taskObj.link = link;
		//Start and end dates for same
		taskObj.start = start;
		taskObj.end = end;
		//Store formatted dates as string
		taskObj.fStartDate = taskObj.start.toString();
		taskObj.fEndDate = taskObj.end.toString();
		//showAsGroup
		taskObj.showAsGroup = showAsGroup;
		taskObj.percentComplete = percentComplete;		
		//Whether to animate or not
		taskObj.animation = animation;
		//Font properties
		taskObj.font = font;
		taskObj.fontColor = fontColor;
		taskObj.fontSize = fontSize;
		//Fill Color and alpha
		taskObj.color = color;
		taskObj.alpha = alpha;
		//Border properties
		taskObj.showBorder = showBorder;
		taskObj.borderColor = borderColor;
		taskObj.borderThickness = borderThickness;
		taskObj.borderAlpha = borderAlpha;
		//Parse the task color, ratio & alpha		
		taskObj.arrColor = ColorExt.parseColorMix(taskObj.color, this.params.taskBarFillMix);
		taskObj.arrAlpha = ColorExt.parseAlphaList(String(taskObj.alpha), taskObj.arrColor.length);
		taskObj.arrRatio = ColorExt.parseRatioList(this.params.taskBarFillRatio, taskObj.arrColor.length);
		//Height (in number/percentage)
		taskObj.height = height;
		//Top padding (vertical)
		taskObj.topPadding = topPadding;
		//Whether to show label, start date, and end date
		taskObj.showLabel = showLabel;
		taskObj.showPercentLabel = showPercentLabel;
		taskObj.showStartDate = showStartDate;
		taskObj.showEndDate = showEndDate;
		//Tool text - if user has not specified his own, we add our custom		
		taskObj.toolText = getFV(toolText, ((taskObj.label!="")?(taskObj.label + ((this.params.dateInToolTip)?", ":"")):(""))  + (this.params.dateInToolTip?(taskObj.fStartDate + " - " + taskObj.fEndDate):("")));
		//Internal positioning properties
		//Starting x position w.r.t. scrollContent MC.
		taskObj.x = 0;
		//Y represesents center Y position of horizontal task bar
		taskObj.y = 0;
		//Width of the total task bar
		taskObj.width = 0;
		//Fill Width (if user has defined percent Complete) - else assumes total width
		taskObj.fillWidth = 0;
		//Return
		return taskObj;
	};
	/**
	 * returnDataAsCategory encompasses the properties of a category object and then returns it.
	*/
	private function returnDataAsCategory(bgColor:String, bgAlpha:Number, label:String, link:String, align:String, vAlign:String, start:FCDateTime, end:FCDateTime, isBold:Boolean, isItalic:Boolean, isUnderline:Boolean, font:String, fontSize:Number, fontColor:String):Object {
		var catObj:Object = new Object();
		//Background properties
		catObj.bgColor = bgColor;
		catObj.bgAlpha = bgAlpha;
		//Label of category
		catObj.label = label;
		//Link (if any)
		catObj.link = link;
		//Text align positions
		catObj.align = align.toLowerCase();
		catObj.vAlign = vAlign.toLowerCase();
		//Alignment can either be left, center or right only
		if (catObj.align!="left" && catObj.align!="right" && catObj.align!="center"){
			//Default to center.
			catObj.align = "center";
		}
		//Fit vertical alignment for backward compatibility
		switch (catObj.vAlign){
		case "left":
			catObj.vAlign = "top";
			break;
		case "center":
			catObj.vAlign = "middle";
			break;
		case "right":
			catObj.vAlign = "bottom";
			break;
		}
		if (catObj.vAlign!="top" && catObj.vAlign!="middle" && catObj.vAlign!="bottom"){
			//Default to middle.
			catObj.align = "middle";
		}
		//Start and end dates (in date format)
		catObj.start = start;
		catObj.end = end;
		//Text bold and underline properties
		catObj.isBold = isBold;
		catObj.isItalic = isItalic;
		catObj.isUnderline = isUnderline;
		//Font properties
		catObj.font = font;
		catObj.fontSize = fontSize;
		catObj.fontColor = fontColor;
		//Return
		return catObj;
	};
	/**
	 * returnDataAsGridCell method returns the data provided to it as an object
	 * representing each cell in the data grid.
	*/
	private function returnDataAsGridCell(label:String, link:String, align:String, vAlign:String, isBold:Boolean, isItalic:Boolean, isUnderline:Boolean, font:String, fontSize:Number, fontColor:String, bgColor:String, bgAlpha:Number):Object {
		var cellObj:Object = new Object();
		//Label
		cellObj.label = label;
		//Link (if any)
		cellObj.link = link;
		//Text align positions
		cellObj.align = align;
		cellObj.vAlign = vAlign;
		//Alignment can either be left, center or right only
		if (cellObj.align!="left" && cellObj.align!="right" && cellObj.align!="center"){
			//Default to center.
			cellObj.align = "center";
		}
		//Fit vertical alignment for backward compatibility
		switch (cellObj.vAlign){
		case "left":
			cellObj.vAlign = "top";
			break;
		case "center":
			cellObj.vAlign = "middle";
			break;
		case "right":
			cellObj.vAlign = "bottom";
			break;
		}
		if (cellObj.vAlign!="top" && cellObj.vAlign!="middle" && cellObj.vAlign!="bottom"){
			//Default to middle.
			cellObj.align = "middle";
		}
		//Text bold and underline properties
		cellObj.isBold = isBold;
		cellObj.isItalic = isItalic;
		cellObj.isUnderline = isUnderline;
		//Font properties
		cellObj.font = font;
		cellObj.fontSize = fontSize;
		cellObj.fontColor = fontColor;
		//Background properties
		cellObj.bgColor = bgColor;
		cellObj.bgAlpha = bgAlpha;
		//Return
		return cellObj;
	};
	/**
	 * returnDataAsTrendline method encapsulates the properties of a trendline and returns as
	 * an object.
	*/
	private function returnDataAsTrendline(start:FCDateTime, end:FCDateTime, displayValue:String, color:String, thickness:Number, alpha:Number, isTrendZone:Boolean, dashed:Boolean, dashLen:Number, dashGap:Number):Object {
		var trendlineObj:Object = new Object();
		//Start and end dates
		trendlineObj.start = start;
		trendlineObj.end = end;
		trendlineObj.displayValue = displayValue;
		//Cosmetic properties
		trendlineObj.color = color;
		trendlineObj.thickness = thickness;
		trendlineObj.alpha = alpha;		
		trendlineObj.isTrendZone = isTrendZone;
		//Dashed properties
		trendlineObj.dashed = dashed;
		trendlineObj.dashLen = dashLen;
		trendlineObj.dashGap = dashGap;
		//Internal positioning properties
		trendlineObj.x = 0;
		trendlineObj.toX = 0;
		//Return
		return trendlineObj;
	};
	/**
	 * returnDataAsMilestone method encapsulates the properties of a milestone and returns as object.
	 * TODO: Add link, toolText for milestone.
	*/
	private function returnDataAsMilestone(taskId:String, date:FCDateTime, shape:String, numSides:Number, startAngle:Number, radius:Number, borderColor:String, borderThickness:Number, color:String, alpha:Number,  link:String, toolText:String):Object {
		var milestoneObj:Object = new Object();
		//Store
		milestoneObj.taskId = taskId;
		milestoneObj.internalTaskId = 0;
		//Date
		milestoneObj.date = date;
		//Milestone shape properties
		milestoneObj.shape = shape;
		milestoneObj.numSides = numSides;
		milestoneObj.startAngle = startAngle;
		milestoneObj.radius = radius;
		//Border properties
		milestoneObj.borderColor = borderColor;
		milestoneObj.borderThickness = borderThickness;
		//Color and Alpha
		milestoneObj.color = color;
		milestoneObj.alpha = alpha;
		//Link & tool text
		milestoneObj.link = link;
		milestoneObj.toolText = toolText;
		//Internal positioning properties
		milestoneObj.x = 0;
		milestoneObj.y = 0;
		//Return
		return milestoneObj;
	};
	/**
	 * returnDataAsConnector method returns the properties of chart connector encapsulated
	 * as an object.
	*/
	private function returnDataAsConnector(fromTaskId:String, toTaskId:String, fromTaskConnectStart:Boolean, toTaskConnectStart:Boolean, color:String, thickness:Number, alpha:Number, isDashed:Boolean):Object {
		var connectorObj:Object = new Object();		
		connectorObj.fromTaskId = fromTaskId;
		connectorObj.toTaskId = toTaskId;
		//Internal task id indexing
		connectorObj.iFromId = 0;
		connectorObj.iToId = 0;
		//Whether to connect from start or end.
		connectorObj.fromTaskConnectStart = fromTaskConnectStart;
		connectorObj.toTaskConnectStart = toTaskConnectStart;
		//Cosmetic properties
		connectorObj.color = color;
		connectorObj.thickness = thickness;
		connectorObj.alpha = alpha;
		//Dashed line 
		connectorObj.isDashed = isDashed;
		//Internal positioning properties
		connectorObj.fromY = 0;
		connectorObj.toY = 0;
		//Return
		return connectorObj;
	};
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
				//Set the date format now
				FCDateTime.setDateFormat(this.params.dateFormat, this.params.outputDateFormat);				
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
					if (arrLevel1Nodes[j].nodeName.toUpperCase() == "CATEGORIES") {
						//Parse the CATEGORIES nodes to extract sub-categories
						this.parseCategoriesXML(arrLevel1Nodes[j]);
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "PROCESSES") {
						//Parse the process nodes
						this.parseProcessXML(arrLevel1Nodes[j]);
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "DATATABLE") {
						//Parse the data table
						this.parseDataTableXML(arrLevel1Nodes[j]);
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "TASKS") {
						//Parse the tasks elements
						this.parseTasksXML(arrLevel1Nodes[j]);
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "CONNECTORS") {
						//Parse the connectors element
						this.parseConnectorsXML(arrLevel1Nodes[j]);
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "MILESTONES") {
						//Parse the milestones element
						this.parseMilestonesXML(arrLevel1Nodes[j]);
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "TRENDLINES") {
						//Parse the trend line nodes
						this.parseTrendXML(arrLevel1Nodes[j]);
					} else if (arrLevel1Nodes[j].nodeName.toUpperCase() == "LEGEND") {
						//Parse the trend line nodes
						this.parseLegendXML(arrLevel1Nodes[j]);
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
		this.params.chartLeftMargin = getFN(atts["chartleftmargin"], 15);
		this.params.chartRightMargin = getFN(atts["chartrightmargin"], 15);
		this.params.chartTopMargin = getFN(atts["charttopmargin"], 10);
		this.params.chartBottomMargin = getFN(atts["chartbottommargin"], 20);
		//Gantt specific paddings
		this.params.taskDatePadding = getFN(atts["taskDatePadding"], 3);
		//Caption padding
		this.params.captionPadding = getFN(atts ["captionpadding"] , 5);
		//Padding of legend from right/bottom side of canvas
		this.params.legendPadding = getFN(atts ["legendpadding"] , 15);
		//--------------- HEADERS / LABELS -----------------//
		//Chart Caption and sub Caption
		this.params.caption = getFV(atts ["caption"] , "");
		this.params.subCaption = getFV(atts ["subcaption"] , "");
		//----------------- GANTT SPECIFIC PROPERTIES ----------------------//
		//Date formatting option
		this.params.dateFormat = atts["dateformat"];
		//If user has not specified dateFormat explicitly, log it
		if (this.params.dateFormat==undefined || this.params.dateFormat==""){
			this.params.dateFormat = "mm/dd/yyyy";
			this.log("No date format specified.","You've not specified date format for the chart. Taking 'mm/dd/yyyy' as default. However, if dates in your XML document are in a different format, the chart would not render properly.", Logger.LEVEL.ERROR);
		}
		
		//Output date format
		this.params.outputDateFormat = getFV(atts["outputdateformat"], this.params.dateFormat);		
		//Whether to show full labels in data table - in that case, a scroll might appear.
		this.params.showFullDataTable = toBoolean(getFN(atts["showfulldatatable"],1));
		//Gantt Area width percent
		this.params.ganttWidthPercent = getFN(atts["ganttwidthpercent"], 65);
		this.params.forceGanttWidthPercent = toBoolean(getFN(atts["forceganttwidthpercent"], 0));
		//Gantt view pane duration - Lets user select what time period the gantt view pane is showing.
		//Post that, a scroll bar appears.
		this.params.ganttPaneDuration = getFN(atts["ganttpaneduration"], -1);
		this.params.ganttPaneDurationUnit = getFV(atts["ganttpanedurationunit"], "s");
		this.params.ganttPaneDurationUnit = this.params.ganttPaneDurationUnit.toLowerCase();
		//Validate & restrict to "y","m","d","h","mn","s"
		if (this.params.ganttPaneDurationUnit!="y" && this.params.ganttPaneDurationUnit!="m" && this.params.ganttPaneDurationUnit!="d" && this.params.ganttPaneDurationUnit!="h" && this.params.ganttPaneDurationUnit!="mn" && this.params.ganttPaneDurationUnit!="s"){
			//Set default as seconds
			this.params.ganttPaneDurationUnit = "s";
		}
		//Configuration to set whether to show task display textboxes
		this.params.showTaskStartDate = toBoolean(getFN(atts["showtaskstartdate"], 0));
		this.params.showTaskEndDate = toBoolean(getFN(atts["showtaskenddate"], 0));
		//Whether to show task labels over them
		this.params.showTaskLabels = toBoolean(getFN(atts["showtasklabels"], atts["showtasknames"], 0));				
		//Whether to show percent complete for each task
		this.params.showPercentLabel = toBoolean(getFN(atts["showpercentlabel"], 0));
		//Cannot be more than 100
		if (this.params.ganttWidthPercent>100) {
			this.params.ganttWidthPercent = 100;
		}	
		//Whether to extend the last category background till bottom
		this.params.extendCategoryBg = toBoolean(getFN(atts["extendcategorybg"], 0));
		//Gantt grid line properties
		this.params.ganttLineColor = formatColor(getFV(atts["ganttlinecolor"], this.colorM.getGridColor()));
		this.params.ganttLineAlpha = getFN(atts["ganttlinealpha"], 100);
		//Grid properties
		this.params.gridBorderColor = formatColor(getFV(atts["gridbordercolor"], this.colorM.getGridColor()));
		this.params.gridBorderAlpha = getFN(atts["gridborderalpha"], 100);
		//Slack fill color
		this.params.showSlackAsFill = toBoolean(getFN(atts["showslackasfill"], 1));
		this.params.slackFillColor = formatColor(getFV(atts["slackfillcolor"], "FF5E5E"));		
		//Grid resize bar properties
		this.params.gridResizeBarColor = formatColor(getFV(atts["gridresizebarcolor"], this.colorM.getGridResizeBarColor()));
		this.params.gridResizeBarThickness = getFN(atts["gridresizebarthickness"], 1);
		this.params.gridResizeBarAlpha = getFN(atts["gridresizebaralpha"], 100);
		//Task round radius
		this.params.taskBarRoundRadius = getFN(atts["taskbarroundradius"], 0);
		//Task Bar fill properties
		this.params.taskBarFillMix = atts["taskbarfillmix"];
		this.params.taskBarFillRatio = atts["taskbarfillratio"];
		//Set defaults
		if (this.params.taskBarFillMix == undefined) {
			this.params.taskBarFillMix = "{light-10},{dark-20},{light-50},{light-85}";
		}
		if (this.params.taskBarFillRatio == undefined) {
			this.params.taskBarFillRatio = "0,8,84,8";
		} 		
		//Connector extension
		this.params.connectorExtension = getFN(atts["connectortxtension"], 10);
		// --------------------- CONFIGURATION ------------------------- //
		//Whether to set animation for entire chart.
		this.params.animation = toBoolean(getFN(atts["animation"], 1));
		//Whether to set the default chart animation
		this.params.defaultAnimation = toBoolean(getFN(atts["defaultanimation"], 1));
		//Click URL
		this.params.clickURL = getFV(atts["clickurl"], "");
		//Delay in rendering annotations that are over the chart
		this.params.annRenderDelay = atts["annrenderdelay"];
		// ------------------------- GENERAL COSMETICS -----------------------------//
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
		//Canvas background properties - Gradient
		this.params.canvasBgColor = getFV(atts["canvasbgcolor"],this.colorM.get2DCanvasBgColor());
		this.params.canvasBgAlpha = getFV(atts["canvasbgalpha"],this.colorM.get2DCanvasBgAlpha());
		this.params.canvasBgRatio = getFV(atts["canvasbgratio"],this.colorM.get2DCanvasBgRatio());
		this.params.canvasBgAngle = getFV(atts["canvasbgangle"],this.colorM.get2DCanvasBgAngle());
		//Canvas Border properties
		this.params.canvasBorderColor = formatColor(getFV(atts["canvasbordercolor"],this.colorM.get2DCanvasBorderColor()));
		this.params.canvasBorderThickness = getFN(atts["canvasborderthickness"],0);
		this.params.canvasBorderAlpha = getFN(atts ["canvasborderalpha"],this.colorM.get2DCanvasBorderAlpha());		
		//Tool Tip - Show/Hide, Background Color, Border Color, Separator Character
		this.params.showToolTip = toBoolean(getFN(atts["showtooltip"],atts["showhovercap"], 1));
		this.params.toolTipBgColor = formatColor(getFV(atts["tooltipbgcolor"],atts["hovercapbgcolor"], atts["hovercapbg"], this.colorM.get2DToolTipBgColor()));
		this.params.toolTipBorderColor = formatColor(getFV(atts["tooltipbordercolor"],atts["hovercapbordercolor"], atts["hovercapborder"], this.colorM.get2DToolTipBorderColor()));
		//Whether to add dates to tool text
		this.params.dateInToolTip = toBoolean(getFN(atts["dateintooltip"],1));
		//Font Properties
		this.params.baseFont = getFV(atts["basefont"], "Verdana");
		this.params.baseFontSize = getFN(atts["basefontsize"], 10);
		this.params.baseFontColor = formatColor(getFV(atts["basefontcolor"], this.colorM.get2DBaseFontColor()));
		//Whether to show shadow for the chart
		this.params.showShadow = toBoolean(getFN(atts["showshadow"], 1));
		//-------------------- SCROLL PROPERTIES ----------------------------//
		//Scroll bar appears for 2 items - data grid.
		//Color for the scroll bar
		this.params.scrollColor = formatColor(getFV(atts["scrollcolor"], this.colorM.getScrollColor()));
		//Vertical padding between the canvas end Y and scroll bar
		this.params.scrollPadding = getFN(atts["scrollpadding"], 0);
		//Height of scroll bar
		this.params.scrollHeight = getFN(atts["scrollheight"],16);
		//Width of plus and minus button
		this.params.scrollBtnWidth = getFN(atts["scrollbtnwidth"],16);
		//Padding between the button and the face.
		this.params.scrollBtnPadding = getFN(atts["scrollbtnpadding"],0);		
		//----------------------- LEGEND PROPERTIES ---------------------------//
		//Legend properties
		this.params.showLegend = toBoolean(getFN(atts ["showlegend"] , 1));
		this.params.interactiveLegend = false;
		this.params.legendCaption = getFV(atts ["legendcaption"] , "");
		this.params.legendMarkerCircle = toBoolean(getFN(atts ["legendmarkercircle"] , 0));
		this.params.legendBorderColor = formatColor(getFV(atts ["legendbordercolor"] , this.colorM.get2DLegendBorderColor()));
		this.params.legendBorderThickness = getFN(atts ["legendborderthickness"] , 1);
		this.params.legendBorderAlpha = getFN(atts ["legendborderalpha"] , 100);
		this.params.legendBgColor = getFV(atts ["legendbgcolor"] , this.colorM.get2DLegendBgColor());
		this.params.legendBgAlpha = getFN(atts ["legendbgalpha"] , 100);
		this.params.legendShadow = toBoolean(getFN(atts ["legendshadow"] , 1));
		this.params.legendAllowDrag = toBoolean(getFN(atts ["legendallowdrag"] , 0));
		this.params.legendScrollBgColor = formatColor(getFV(atts ["legendscrollbgcolor"] , this.colorM.getScrollColor()));
		this.params.legendScrollBarColor = formatColor(getFV(atts ["legendscrollbarcolor"] , this.params.legendBorderColor));
		this.params.legendScrollBtnColor = formatColor(getFV(atts ["legendscrollbtncolor"] , this.params.legendBorderColor));			
		this.params.reverseLegend = toBoolean (getFN (atts ["reverselegend"] , 0));
	}
	/**
	 * parseCategoriesXML method parses the categories nodes.
	*/
	private function parseCategoriesXML(categoriesNode:XMLNode):Void{
		var k:Number;
		//Increment the counter
		this.numCat++;
		//Create an object container to store the parameters
		this.categories[this.numCat] = new Object();
		//Get the category attributes in array.
		var atts:Array = Utils.getAttributesArray(categoriesNode);
		//Extract the attributes
		this.categories[this.numCat].bgColor = formatColor(getFV(atts["bgcolor"], this.colorM.getCategoryBgColor()));
		this.categories[this.numCat].bgAlpha = getFN(atts["bgalpha"], 100);
		this.categories[this.numCat].font = getFV(atts["font"], this.params.baseFont);
		this.categories[this.numCat].fontSize = getFN(atts["fontsize"], this.params.baseFontSize + 1);
		this.categories[this.numCat].fontColor = formatColor(getFV(atts["fontcolor"], this.params.baseFontColor));
		this.categories[this.numCat].isBold = getFN(atts["isbold"], 1);
		this.categories[this.numCat].isItalic = getFN(atts["isitalic"], 0);
		this.categories[this.numCat].isUnderline = getFN(atts["isunderline"], 0);
		this.categories[this.numCat].verticalPadding = getFN(atts["verticalpadding"], 3);
		this.categories[this.numCat].align = getFV(atts["align"], "center");
		this.categories[this.numCat].vAlign = getFV(atts["valign"], "middle");
		//Internal counter to store number of sub-categories within this category
		this.categories[this.numCat].numSubcat = 0;
		//Create an array to store the sub-categories
		this.categories[this.numCat].category = new Array();
		//Get a reference to the categories sub nodes
		var categoryNodes:Array = categoriesNode.childNodes;
		//Now, iterate through each of the category nodes and store the data in the array
		for (var k = 0; k<=categoryNodes.length; k++) {
			//If the node is really a category subnode
			if (categoryNodes[k].nodeName.toUpperCase() == "CATEGORY") {
				
				//Get the attributes
				var catAtts:Array = Utils.getAttributesArray(categoryNodes[k]);
				//Parse the attributes
				//Flag whether the category is valid - by default, assume that it's alright.
				var validCat:Boolean = true;
				//Parse start date
				try {
					var start:FCDateTime = new FCDateTime(catAtts["start"]);
				} catch (e:Error) {
					//If the date is invalid, log the error.
					this.log("Invalid date '" + catAtts["start"] + "'", e.message, Logger.LEVEL.ERROR);
					//Update flag that the category date is invalid
					validCat = false;
				}
				//Parse end date
				try {
					var end:FCDateTime = new FCDateTime(catAtts["end"]);
				} catch (e:Error) {
					//If the date is invalid, log the error.
					this.log("Invalid category date '" + catAtts["end"] + "'", e.message, Logger.LEVEL.ERROR);
					//Update flag that the category date is invalid
					validCat = false;
				}
				//If both the start and end dates are valid, we proceed with further parsing
				if (validCat){
					//Increment count
					this.categories[this.numCat].numSubcat++;				
					//Proceed with rest of properties
					var bgColor:String = formatColor(getFV(catAtts["bgcolor"], this.categories[this.numCat].bgColor));
					var bgAlpha:Number = getFN(catAtts["bgalpha"], this.categories[this.numCat].bgAlpha);
					var label:String = getFV(catAtts["label"], catAtts["name"], "");
					var link:String = getFV(catAtts["link"], "");
					var align:String = getFV(catAtts["align"], this.categories[this.numCat].align);
					var vAlign:String = getFV(catAtts["valign"], this.categories[this.numCat].vAlign);
					var isBold:Boolean = toBoolean(getFN(catAtts["isbold"], this.categories[this.numCat].isBold));
					var isItalic:Boolean = toBoolean(getFN(catAtts["isitalic"], this.categories[this.numCat].isItalic));
					var isUnderline:Boolean = toBoolean(getFN(catAtts["isunderline"], this.categories[this.numCat].isUnderline));
					var font:String = getFV(catAtts["font"], this.categories[this.numCat].font);
					var fontSize:Number = getFN(catAtts["fontsize"], this.categories[this.numCat].fontSize);
					var fontColor:String = formatColor(getFV(catAtts["fontcolor"], this.categories[this.numCat].fontColor));
					//Store it
					this.categories[this.numCat].category[this.categories[this.numCat].numSubcat] = this.returnDataAsCategory(bgColor, bgAlpha, label, link, align, vAlign, start, end, isBold, isItalic, isUnderline, font, fontSize, fontColor);
				}
			}
		}
		//Free memory resources
		delete categoryNodes;
	}	
	/**
	 * parseProcessXML method parses the <Processes> node and it's children nodes to extract
	 * process information.
	*/
	private function parseProcessXML(processNode:XMLNode):Void{
		var k:Number;
		//Extract the attributes of <processes> element
		var atts:Array = Utils.getAttributesArray(processNode);
		//Process header text
		this.params.processHeaderText = getFV(atts["headertext"], "");
		//Header text attributes
		this.params.processHeaderFont = getFV(atts["headerfont"], this.params.baseFont);
		this.params.processHeaderFontSize = getFN(atts["headerfontsize"], this.params.baseFontSize + 3);
		this.params.processHeaderFontColor = formatColor(getFV(atts["headerfontcolor"], this.params.baseFontColor));
		this.params.processHeaderIsBold = toBoolean(getFN(atts["headerisbold"], 1));
		this.params.processHeaderIsItalic = toBoolean(getFN(atts["headerisitalic"], 0));
		this.params.processHeaderIsUnderline = toBoolean(getFN(atts["headerisunderline"], 0));
		this.params.processHeaderAlign = getFV(atts["headeralign"], "center");
		this.params.processHeaderVAlign = getFV(atts["headervalign"], "middle");
		this.params.processHeaderBgColor = formatColor(getFV(atts["headerbgcolor"], this.colorM.getDataTableBgColor()));
		this.params.processHeaderBgAlpha = getFN(atts["headerbgalpha"], 100);
		//Width
		this.params.processWidth = getFV(atts["width"], "");
		//Position of the process name column in the data grid.
		this.params.processPositionInGrid = getFV(atts["positioningrid"], "left");
		//Restrict to left or right.
		if (this.params.processPositionInGrid!="left" && this.params.processPositionInGrid!="right"){
			//Default to left.
			this.params.processPositionInGrid="left";
		}
		//Other properties
		var bgColor:String = formatColor(getFV(atts["bgcolor"], this.colorM.getDataTableBgColor()));
		var bgAlpha:Number = getFN(atts["bgalpha"], 100);
		var font:String = getFV(atts["font"], this.params.baseFont);
		var fontSize:Number = getFN(atts["fontsize"], this.params.baseFontSize);
		var fontColor:String = formatColor(getFV(atts["fontcolor"], this.params.baseFontColor));
		var isBold:Number = getFN(atts["isbold"], 0);
		var isItalic:Number = getFN(atts["isitalic"], 0);
		var isUnderline:Number = getFN(atts["isunderline"], 0);
		var align:String = getFV(atts["align"], "center");
		var vAlign:String = getFV(atts["valign"], "middle");
		//Extract the process info
		var processNodes:Array = processNode.childNodes;
		//Now, iterate through each of the process nodes and store the data in the array
		for (k=0; k<=processNodes.length; k++) {
			//If the node is really a processes subnode
			if (processNodes[k].nodeName.toUpperCase() == "PROCESS") {
				//Increment value
				this.numProcess++;
				//Extract the attributes
				var processAtts:Array = Utils.getAttributesArray(processNodes[k]);
				//Process name attributes
				var pLabel:String = getFV(processAtts["label"], processAtts["name"], "");
				//Link
				var pLink:String = getFV(processAtts["link"], "");
				//Process Id
				var pID:String = getFV(processAtts["id"].toUpperCase(),String("__FCDPID__"+this.numProcess));
				//Font properties
				var pFont:String = getFV(processAtts["font"], font);
				var pFontColor:String = formatColor(getFV(processAtts["fontcolor"], fontColor));
				var pFontSize:Number = getFN(processAtts["fontsize"], fontSize);
				var pIsBold:Boolean = toBoolean(getFN(processAtts["isbold"], isBold));
				var pIsItalic:Boolean = toBoolean(getFN(processAtts["isitalic"], isItalic));
				var pIsUnderline:Boolean = toBoolean(getFN(processAtts["isunderline"], isUnderline));
				//Align properties
				var pAlign:String = getFV(processAtts["align"], align);
				var pVAlign:String = getFV(processAtts["valign"], vAlign);
				var pBgColor:String = formatColor(getFV(processAtts["bgcolor"], bgColor));
				var pBgAlpha:Number = getFN(processAtts["bgalpha"], bgAlpha);
				//Create a process object
				this.processes[this.numProcess] = this.returnDataAsProcess(pLabel, pLink, pID, pFont, pFontColor, pFontSize, pIsBold, pIsItalic, pIsUnderline, pAlign, pVAlign, pBgColor, pBgAlpha);
			}
		}
	}
	/**
	 * parseDataTableXML method parses the XML nodes and attributes for <datatable>
	*/
	private function parseDataTableXML(dataTableNode:XMLNode):Void{
		var k:Number, l:Number;
		//Get attributes
		var atts:Array = Utils.getAttributesArray(dataTableNode);
		//Extract the attributes of DATATABLE
		var bgColor:String = formatColor(getFV(atts["bgcolor"], this.colorM.getDataTableBgColor()));
		var bgAlpha:Number = getFN(atts["bgalpha"], 100);
		var font:String = getFV(atts["font"], this.params.baseFont);
		var fontColor:String = formatColor(getFV(atts["fontcolor"], this.params.baseFontColor));
		var fontSize:Number = getFN(atts["fontsize"], this.params.baseFontSize);
		var isBold:Number = getFN(atts["isbold"], 0);
		var isItalic:Number = getFN(atts["isitalic"], 0);
		var isUnderline:Number = getFN(atts["isunderline"], 0);
		var align:String = getFV(atts["align"], "center");
		var vAlign:String = getFV(atts["vAlign"], "middle");
		//Header properties
		var headerFont:String = getFV(atts["headerfont"], font);
		var headerFontSize:Number = getFN(atts["headerfontsize"], fontSize + 3);
		var headerFontColor:String = formatColor(getFV(atts["headerfontcolor"], fontColor));
		var headerIsBold:Number = getFN(atts["headerisbold"], 1);
		var headerIsItalic:Number = getFN(atts["headerisitalic"], isItalic);
		var headerIsUnderline:Number = getFN(atts["headerisunderline"], isUnderline);
		var headerAlign:String = getFV(atts["headeralign"], "center");
		var headerVAlign:String = getFV(atts["headervalign"], vAlign);
		var headerBgColor:String = formatColor(getFV(atts["headerbgcolor"], bgColor));
		var headerBgAlpha:Number = getFN(atts["headerbgalpha"], bgAlpha);
		//Extract the Data Column info
		var dataTableNodes = dataTableNode.childNodes;
		//Now, iterate through each of the datacolumn nodes and store the data in the array
		for (k=0; k<dataTableNodes.length; k++) {
			//If the node is really a datatable subnode
			if (dataTableNodes[k].nodeName.toUpperCase() == "DATACOLUMN") {
				//Increment counter
				this.numDataColumns++;
				//Create a new object to represent
				this.dataColumn[this.numDataColumns] = new Object();
				//Retrieve the attributes 
				var colAtts:Array = Utils.getAttributesArray(dataTableNodes[k]);
				this.dataColumn[this.numDataColumns].bgColor = formatColor(getFV(colAtts["bgcolor"], bgColor));
				this.dataColumn[this.numDataColumns].bgAlpha = getFN(colAtts["bgalpha"], bgAlpha);
				this.dataColumn[this.numDataColumns].width = getFV(colAtts["width"], "");
				this.dataColumn[this.numDataColumns].font = getFV(colAtts["font"], font);
				this.dataColumn[this.numDataColumns].fontColor = formatColor(getFV(colAtts["fontcolor"], fontColor));
				this.dataColumn[this.numDataColumns].fontSize = getFN(colAtts["fontsize"], fontSize);
				this.dataColumn[this.numDataColumns].isBold = getFN(colAtts["isbold"], isBold);
				this.dataColumn[this.numDataColumns].isItalic = getFN(colAtts["isitalic"], isItalic);
				this.dataColumn[this.numDataColumns].isUnderline = getFN(colAtts["isunderline"], isUnderline);
				this.dataColumn[this.numDataColumns].align = getFV(colAtts["align"], align);
				this.dataColumn[this.numDataColumns].vAlign = getFV(colAtts["valign"], vAlign);
				//Header text for the column
				this.dataColumn[this.numDataColumns].headerText = getFV(colAtts["headertext"], "");
				//Link
				this.dataColumn[this.numDataColumns].headerLink = getFV(colAtts["headerlink"], "");
				//Header text attributes
				this.dataColumn[this.numDataColumns].headerFont = getFV(colAtts["headerfont"], headerFont);
				this.dataColumn[this.numDataColumns].headerFontSize = getFN(colAtts["headerfontsize"], headerFontSize);
				this.dataColumn[this.numDataColumns].headerFontColor = formatColor(getFV(colAtts["headerfontcolor"], headerFontColor));
				this.dataColumn[this.numDataColumns].headerIsBold = toBoolean(getFN(colAtts["headerisbold"], headerIsBold));
				this.dataColumn[this.numDataColumns].headerIsItalic = toBoolean(getFN(colAtts["headerisitalic"], headerIsItalic));
				this.dataColumn[this.numDataColumns].headerIsUnderline = toBoolean(getFN(colAtts["headerisunderline"], headerIsUnderline));
				this.dataColumn[this.numDataColumns].headerAlign = getFV(colAtts["headeralign"], headerAlign);
				this.dataColumn[this.numDataColumns].headerVAlign = getFV(colAtts["headervAlign"], headerVAlign);
				this.dataColumn[this.numDataColumns].headerBgColor = formatColor(getFV(colAtts["headerbgcolor"], headerBgColor));
				this.dataColumn[this.numDataColumns].headerBgAlpha = getFN(colAtts["headerbgalpha"], headerBgAlpha);
				//Create an array to store the cells
				this.dataColumn[this.numDataColumns].cell = new Array();
				//Extract the individual <text> info
				var colTextNodes = dataTableNodes[k].childNodes;
				//Now, iterate through each of the text nodes and store the data in the array
				//Create a counter
				var cellCount = 0;
				for (l=0; l<=colTextNodes.length; l++) {
					//If the node is really a Text node
					if (colTextNodes[l].nodeName.toUpperCase() == "TEXT") {
						//Increase the counter
						cellCount++;
						//Extract attributes
						var textAtts:Array = Utils.getAttributesArray(colTextNodes[l]);
						//Store them
						var clabel:String = getFV(textAtts["label"], "");
						var clink:String = getFV(textAtts["link"], "");
						var cbgColor:String = formatColor(getFV(textAtts["bgcolor"], this.dataColumn[this.numDataColumns].bgColor));
						var cbgAlpha:Number = getFN(textAtts["bgalpha"], this.dataColumn[this.numDataColumns].bgAlpha);
						var cfont:String = getFV(textAtts["font"], this.dataColumn[this.numDataColumns].font);
						var cfontColor:String = formatColor(getFV(textAtts["fontcolor"], this.dataColumn[this.numDataColumns].fontColor));
						var cfontSize:Number = getFN(textAtts["fontsize"], this.dataColumn[this.numDataColumns].fontSize);
						var cisBold:Boolean = toBoolean(getFN(textAtts["isbold"], this.dataColumn[this.numDataColumns].isBold));
						var cisItalic:Boolean = toBoolean(getFN(textAtts["isitalic"], this.dataColumn[this.numDataColumns].isItalic));
						var cisUnderline:Boolean = toBoolean(getFN(textAtts["isunderline"], this.dataColumn[this.numDataColumns].isUnderline));
						var calign:String = getFV(textAtts["align"], this.dataColumn[this.numDataColumns].align);
						var cvAlign:String = getFV(textAtts["valign"], this.dataColumn[this.numDataColumns].vAlign);
						//Create the cell object to represent this cell
						this.dataColumn[this.numDataColumns].cell[cellCount] = returnDataAsGridCell(clabel, clink, calign, cvAlign, cisBold, cisItalic, cisUnderline, cfont, cfontSize, cfontColor, cbgColor, cbgAlpha);
					}
				}
			}
		}
	}
	/**
	 * parseTasksXML method parses the XML for <tasks> element.
	*/
	private function parseTasksXML(tasksNode:XMLNode):Void{
		var k:Number;
		//Get the attributes
		var atts:Array = Utils.getAttributesArray(tasksNode);
		//If it's the tasks node, get the attributes
		var tFont:String = getFV(atts["font"], this.params.baseFont);
		var tFontColor:String = formatColor(getFV(atts["fontcolor"], this.params.baseFontColor));
		var tFontSize:Number = getFN(atts["fontsize"], this.params.baseFontSize);
		var tColor:String = formatColor(getFV(atts["color"], this.colorM.get2DPlotFillColor()));
		var tAlpha:Number = getFN(atts["alpha"], 100);
		var tShowBorder:Number = getFN(atts["showborder"], 1);
		var tBorderColor:String = formatColor(getFV(atts["bordercolor"], this.colorM.get2DPlotBorderColor()));
		var tBorderThickness:Number = getFN(atts["borderthickness"], 1);
		var tBorderAlpha:Number = getFN(atts["borderalpha"], 100);
		var tShowLabels:Number = getFN(atts["showlabels"], atts["showname"], this.params.showTaskLabels);
		var tShowPercentLabel:Number  = getFN(atts["showpercentlabel"], this.params.showPercentLabel);
		var tShowStartDate:Number = getFN(atts["showstartdate"], this.params.showTaskStartDate);
		var tShowEndDate:Number = getFN(atts["showenddate"], this.params.showTaskEndDate);
		//Get a reference to task Nodes
		var taskNodes:Array = tasksNode.childNodes;
		//Now, iterate through each of the task nodes and store the data in the array
		for (k=0; k<taskNodes.length; k++) {
			//If the node is really a task subnode
			if (taskNodes[k].nodeName.toUpperCase() == "TASK") {				
				//Extract the attributes
				var taskAtts:Array = Utils.getAttributesArray(taskNodes[k]);
				//Flag to store whether the task is a valid one - true by default
				var isTaskValid:Boolean = true;
				//Get the start and end date of task				
				//Parse start date
				try {
					var start:FCDateTime = new FCDateTime(taskAtts["start"]);
				} catch (e:Error) {
					//If the date is invalid, log the error.
					this.log("Invalid date '" + taskAtts["start"] + "'", e.message, Logger.LEVEL.ERROR);
					//Update flag that the task date is invalid
					isTaskValid = false;
				}
				//Parse end date
				try {
					var end:FCDateTime = new FCDateTime(taskAtts["end"]);
				} catch (e:Error) {
					//If the date is invalid, log the error.
					this.log("Invalid task date '" + taskAtts["end"] + "'", e.message, Logger.LEVEL.ERROR);
					//Update flag that the task date is invalid
					isTaskValid = false;
				}
				if (isTaskValid){
					//Increment counter
					this.numTasks++;
					//If the task is valid, proceed with parsing rest of the attributes.
					//Get the process id - by default if no process id is mentioned, we automatically serialize process wise
					var serializeProcessId:Number = ((this.numTasks%this.numProcess) == 0) ? (this.numProcess) : (this.numTasks%this.numProcess);
					var processId:String = getFV(taskAtts["processid"].toUpperCase(), this.processes[serializeProcessId].id);
					var label:String = getFV(taskAtts["label"], taskAtts["name"], "");
					var link:String = getFV(taskAtts["link"], "");
					var id:String = getFV(taskAtts["id"].toUpperCase(), "");
					var showAsGroup:Boolean = toBoolean(getFN(taskAtts["showasgroup"], 0));
					var percentComplete:Number = getFN(taskAtts["percentcomplete"], -1);
					var animation:Boolean = toBoolean(getFN(taskAtts["animation"], Utils.fromBoolean(this.params.animation)));
					var font:String = getFV(taskAtts["font"], tFont);
					var fontColor:String = formatColor(getFV(taskAtts["fontcolor"], tFontColor));
					var fontSize:Number = getFN(taskAtts["fontsize"], tFontSize);
					var color:String = getFV(taskAtts["color"], tColor);
					var alpha:Number = getFN(taskAtts["alpha"], tAlpha);
					var showBorder:Boolean = toBoolean(getFN(taskAtts["showborder"], tShowBorder));
					var borderColor:String = formatColor(getFV(taskAtts["bordercolor"], tBorderColor));
					var borderThickness:Number = getFN(taskAtts["borderthickness"], tBorderThickness);
					var borderAlpha:Number = getFN(taskAtts["borderalpha"], tBorderAlpha);
					var height:String = getFV(taskAtts["height"], "35%");
					var topPadding:String = getFV(taskAtts["toppadding"],"35%");
					var showLabel:Boolean = toBoolean(getFN(taskAtts["showlabel"], taskAtts["showname"], tShowLabels));
					var showPercentLabel:Boolean = toBoolean(getFN(taskAtts["showpercentlabel"], tShowPercentLabel));					
					var showStartDate:Boolean = toBoolean(getFN(taskAtts["showstartdate"], tShowStartDate));
					var showEndDate:Boolean = toBoolean(getFN(taskAtts["showenddate"], tShowEndDate));
					var toolText:String = getFV(taskAtts["tooltext"], taskAtts["hovertext"], "");
					//Create an object to represent the task
					this.tasks[this.numTasks] = this.returnDataAsTask(processId, label, id, link, start, end, showAsGroup, percentComplete, animation, font, fontColor, fontSize, color, alpha, showBorder, borderColor, borderThickness, borderAlpha, height, topPadding, showLabel, showPercentLabel,  showStartDate, showEndDate, toolText);
				}
			}
		}
	}
	/**
	 * parseConnectorsXML method parses the Connectors element and its children nodes.
	*/
	private function parseConnectorsXML(connectorsNode:XMLNode):Void{
		var k:Number;
		//Get the attributes array
		var atts:Array = Utils.getAttributesArray(connectorsNode);
		//Extract the attributes
		var cnColor:String = formatColor(getFV(atts["color"], this.colorM.get2DPlotBorderColor()));
		var cnAlpha:Number = getFN(atts["alpha"], 100);
		var cnThickness:Number = getFN(atts["thickness"], 1);
		var cnIsDashed:Number = getFN(atts["isdashed"], 1);
		//Get a reference to its child nodes
		var connectorNodes:Array = connectorsNode.childNodes;
		//Now, iterate through each of the process nodes and store the data in the array
		for (k=0; k<=connectorNodes.length; k++) {
			//If the node is really a connectors subnode
			if (connectorNodes[k].nodeName.toUpperCase() == "CONNECTOR") {
				//Increment
				this.numConnectors++;
				//Extract the attributes
				var cnAtts:Array = Utils.getAttributesArray(connectorNodes[k]);
				var fromTaskId:String = cnAtts["fromtaskid"].toUpperCase();
				var toTaskId:String = cnAtts["totaskid"].toUpperCase();
				var fromTaskConnectStart:Boolean = toBoolean(getFN(cnAtts["fromtaskconnectstart"], 0));
				var toTaskConnectStart:Boolean = toBoolean(getFN(cnAtts["totaskconnectstart"], 1));
				var color:String = formatColor(getFV(cnAtts["color"], cnColor));
				var thickness:Number = getFN(cnAtts["thickness"], cnThickness);
				var alpha:Number = getFN(cnAtts["alpha"], cnAlpha);
				var isDashed:Boolean = toBoolean(getFN(cnAtts["isdashed"], cnIsDashed));
				//Create the connector object				
				this.connectors[this.numConnectors] = this.returnDataAsConnector(fromTaskId, toTaskId, fromTaskConnectStart, toTaskConnectStart, color, thickness, alpha, isDashed);
			}
		}
	}
	/**
	 * parseMilestonesXML method parses the milestones XML element for the chart.
	*/
	private function parseMilestonesXML(milestoneNode:XMLNode):Void{
		var k:Number;
		var milestoneNodes:Array = milestoneNode.childNodes;
		//Now, we need to iterate through each line node
		for (k = 0; k<=milestoneNodes.length; k++) {
			//Check if the element is a LINE Element
			if (milestoneNodes[k].nodeName.toUpperCase() == "MILESTONE") {				
				//Extract attributes
				var atts:Array = Utils.getAttributesArray(milestoneNodes[k]);
				//Flag to store whether the milestone is a valid one - true by default
				var isValid:Boolean = true;
				//Parse date
				try {
					var date:FCDateTime = new FCDateTime(atts["date"]);
				} catch (e:Error) {
					//If the date is invalid, log the error.
					this.log("Invalid Milestone date '" + atts["start"] + "'", e.message, Logger.LEVEL.ERROR);
					//Update flag that the task date is invalid
					isValid = false;
				}
				if (isValid){				
					//If the milestone has a valid date, continue parsing other attributes
					//Increment the counter by 1
					this.numMilestones++;									
					var taskId:String = atts["taskid"].toUpperCase();
					var shape:String = getFV(atts["shape"], "polygon");
					//Restrict
					shape = shape.toLowerCase();
					if (shape!="star" && shape!="polygon"){
						//Default to polygon
						shape = "polygon";
					}
					var numSides:Number = getFN(atts["numsides"], 5);
					var startAngle:Number = getFN(atts["startangle"], 90);
					var radius:Number = atts["radius"];
					var color:String = formatColor(getFV(atts["color"], this.colorM.get2DLegendBorderColor()));
					var alpha:Number = getFN(atts["alpha"], 100);
					var borderColor:String = formatColor(getFV(atts["bordercolor"], color));
					var borderThickness:Number = getFN(atts["borderthickness"], 1);
					var link:String = getFV(atts["link"],"");
					var toolText:String = getFV(atts["tooltext"],"");
					//Create the object to represent it
					this.milestones[this.numMilestones] = this.returnDataAsMilestone(taskId, date, shape, numSides, startAngle, radius, borderColor, borderThickness, color, alpha, link, toolText);
				}
			}
		}
	}	
	/**
	 * parseTrendXML method parses the trend line elements of the chart.
	*/
	private function parseTrendXML(trendNode:XMLNode):Void{
		var k:Number;
		//So, get a reference to its child nodes
		var trendLineNodes:Array = trendNode.childNodes;
		//Now, we need to iterate through each line node
		for (k = 0; k<=trendLineNodes.length; k++) {
			//Check if the element is a LINE Element
			if (trendLineNodes[k].nodeName.toUpperCase() == "LINE") {
				//Get attributes
				var atts:Array = Utils.getAttributesArray(trendLineNodes[k]);
				//Flag whether the trend line is valid.
				var isTrendValid:Boolean = true;
				//Get the start and end date for trendline.
				try {
					var start:FCDateTime = new FCDateTime(atts["start"]);
				} catch (e:Error) {
					//If the date is invalid, log the error.
					this.log("Invalid Trendline start date '" + atts["start"] + "'", e.message, Logger.LEVEL.ERROR);
					//Update flag that the task date is invalid
					isTrendValid = false;
				}
				
				//Also, assume the end date, if not specified
				if (atts["end"]==undefined){
					//Clone
					var end:FCDateTime = start.clone();
				}else{
					//Parse the end date
					try {
						var end:FCDateTime = new FCDateTime(atts["end"]);
					} catch (e:Error) {
						//If the date is invalid, log the error.
						this.log("Invalid Trendline end date '" + atts["start"] + "'", e.message, Logger.LEVEL.ERROR);
						//Update flag that the task date is invalid
						isTrendValid = false;
					}
				}
				//Proceed further only if the dates are valid
				if (isTrendValid){
					//Increment the counter by 1
					this.numTrendlines++;
					var lineColor:String = formatColor(getFV(atts["color"], this.colorM.get2DLegendBorderColor()));
					var lineDisplayValue:String = getFV(atts["displayvalue"], start.toString());					
					var lineThickness:Number = getFN(atts["thickness"], 1);					
					var lineIsTrendZone:Boolean = toBoolean(getFN(atts["istrendzone"], 0));
					var lineAlpha:Number = getFN(atts["alpha"], (lineIsTrendZone) ? 40 : 99);
					var lineDashed:Boolean = toBoolean(getFN(atts["dashed"], 0));
					var lineDashLen:Number = getFN(atts["dashlen"], 3);
					var lineDashGap:Number = getFN(atts["dashgap"], 3);
					this.trendlines[this.numTrendlines] = returnDataAsTrendline(start, end, lineDisplayValue, lineColor, lineThickness, lineAlpha, lineIsTrendZone, lineDashed, lineDashLen, lineDashGap);
				}
			}
		}
	}
	/**
	 * parseLegendXML method parses the legend elements of the chart.
	*/
	private function parseLegendXML(legendNode:XMLNode):Void{
		var k:Number;
		//So, get a reference to its child nodes
		var legendNodes:Array = legendNode.childNodes;
		//Now, we need to iterate through each item node
		for (k = 0; k<=legendNodes.length; k++) {
			//Check if the element is an ITEM Element
			if (legendNodes[k].nodeName.toUpperCase() == "ITEM") {				
				//Get attributes
				var atts:Array = Utils.getAttributesArray(legendNodes[k]);			
				//Color
				var itemColor:String = formatColor(getFV(atts["color"], this.colorM.getColor()));
				var itemLabel:String = getFV(atts["label"], "");
				if (itemLabel!=""){					
					//Increment count
					this.numLegendItems++;
					this.legendItems[this.numLegendItems] = {label:itemLabel, color:itemColor};
				}
			}
		}
	}
	/**
	 * detectDateLimits method detects the smallest and largest dates present in the data.
	*/
	private function detectDateLimits():Void{
		var i:Number, j:Number;
		//------------------ FIND FIRST DATE TO COMPARE----------------//
		//Flag to indicate whether the first date was found in both case
		var firstDateFound:Boolean = false;
		//First date - the one with which we'll compare.
		var firstDate:FCDateTime;
		//To find the first date, we iterate through categories & tasks.		
		for (i=1; i<=this.numCat; i++){
			if (this.categories[i].category[1].start!=undefined){
				//Store a copy of the date
				firstDate = this.categories[i].category[1].start.clone();
				//Set flag
				firstDateFound = true;
				//Break
				break;
			}
		}
		//If we've not yet found our first date (i.e., user has not specified a category),
		//we need to check for dates specified in tasks.
		if (!firstDateFound){
			if (this.numTasks>0){
				//Assume that of the first task
				firstDate = this.tasks[1].start.clone();
				//Set flag
				firstDateFound = true;
			}
		}
		//Forced error cover: If we've not yet found a first date, we assume it to be today
		if (!firstDateFound){
			//Get from system
			var currentDate:Date = new Date();	
			//Set it
			firstDate = new FCDateTime(currentDate.getUTCFullYear(), currentDate.getUTCMonth()+1, currentDate.getUTCDate(), 0, 0, 0);			
		}		
		//----------- DETECT SMALLEST/LARGEST DATE -------------//
		var minDate:FCDateTime = firstDate.clone();
		var maxDate:FCDateTime = firstDate.clone();
		//Now, iterate through all dates in the chart (both categories & tasks) and compare
		for (i=1; i<=this.numCat; i++){
			for (j=1; j<=this.categories[i].numSubcat; j++){
				if (minDate.isGreaterThan(this.categories[i].category[j].start)){
					minDate = this.categories[i].category[j].start.clone();
				}
				if (this.categories[i].category[j].end.isGreaterThan(maxDate)){
					maxDate = this.categories[i].category[j].end.clone();
				}
			}			
		}
		//Iterate through tasks
		for (i=1; i<=this.numTasks; i++){
			if (minDate.isGreaterThan(this.tasks[i].start)){
				minDate = this.tasks[i].start.clone();
			}
			if (this.tasks[i].end.isGreaterThan(maxDate)){
				maxDate = this.tasks[i].end.clone();
			}
		}
		//------------------ STORE THEM ---------------//
		this.config.startDate = minDate.clone();
		this.config.endDate = maxDate.clone();
	}	
	/**
	* setStyleDefaults method sets the default values for styles or
	* extracts information from the attributes and stores them into
	* style objects.
	*/
	private function setStyleDefaults():Void {
		//Default font object for Caption
		//-----------------------------------------------------------------//
		var captionFont = new StyleObject ();
		captionFont.name = "_SdCaptionFont";
		captionFont.align = "center";
		captionFont.valign = "top";
		captionFont.bold = "1";
		captionFont.font = this.params.baseFont;
		captionFont.size = this.params.baseFontSize + 3;
		captionFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.CAPTION, captionFont, this.styleM.TYPE.FONT, null);
		delete captionFont;
		//-----------------------------------------------------------------//
		//Default font object for SubCaption
		//-----------------------------------------------------------------//
		var subCaptionFont = new StyleObject ();
		subCaptionFont.name = "_SdSubCaptionFont";
		subCaptionFont.align = "center";
		subCaptionFont.valign = "top";
		subCaptionFont.bold = "1";
		subCaptionFont.font = this.params.baseFont;
		subCaptionFont.size = this.params.baseFontSize + 1;
		subCaptionFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.SUBCAPTION, subCaptionFont, this.styleM.TYPE.FONT, null);
		delete subCaptionFont;
		//-----------------------------------------------------------------//
		//Default font object for task labels
		//-----------------------------------------------------------------//
		var taskLabelFont = new StyleObject ();
		taskLabelFont.name = "_SdTaskLabelFont";
		taskLabelFont.font = this.params.baseFont;
		taskLabelFont.size = this.params.baseFontSize;
		taskLabelFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.TASKLABELS, taskLabelFont, this.styleM.TYPE.FONT, null);
		delete taskLabelFont;		
		//-----------------------------------------------------------------//
		//Default font object for task date labels
		//-----------------------------------------------------------------//
		var taskDateLabelFont = new StyleObject ();
		taskDateLabelFont.name = "_SdTaskDateLabelFont";
		taskDateLabelFont.font = this.params.baseFont;
		taskDateLabelFont.size = this.params.baseFontSize;
		taskDateLabelFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.TASKDATELABELS, taskDateLabelFont, this.styleM.TYPE.FONT, null);
		delete taskDateLabelFont;		
		//-----------------------------------------------------------------//
		//Default font object for trend lines
		//-----------------------------------------------------------------//
		var trendFont = new StyleObject ();
		trendFont.name = "_SdTrendFont";
		trendFont.font = this.params.baseFont;
		trendFont.size = this.params.baseFontSize;
		trendFont.color = this.params.baseFontColor;
		//Over-ride
		this.styleM.overrideStyle (this.objects.TRENDVALUES, trendFont, this.styleM.TYPE.FONT, null);
		delete trendFont;		
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
		//Default font object for Legend
		//-----------------------------------------------------------------//
		var legendFont = new StyleObject ();
		legendFont.name = "_SdLegendFont";
		legendFont.font = this.params.baseFont;
		legendFont.size = this.params.baseFontSize;
		legendFont.color = this.params.baseFontColor;
		legendFont.ishtml = 1;
		legendFont.leftmargin = 3;
		//Over-ride
		this.styleM.overrideStyle (this.objects.LEGEND, legendFont, this.styleM.TYPE.FONT, null);
		delete legendFont;
		//------------------------------------------------------------------//
		// Shadow for Gauge
		//------------------------------------------------------------------//
		if (this.params.showShadow){
			var tasksShadow = new StyleObject ();
			tasksShadow.name = "_SdTasksShadow";
			//Over-ride
			this.styleM.overrideStyle (this.objects.TASKS, tasksShadow, this.styleM.TYPE.SHADOW, null);
		}
		//-----------------------------------------------------------------//
		//Default Effect (Shadow) object for Legend
		//-----------------------------------------------------------------//
		if (this.params.legendShadow){
			var legendShadow = new StyleObject ();
			legendShadow.name = "_SdLegendShadow";
			legendShadow.distance = 2;
			legendShadow.alpha = 90;
			legendShadow.angle = 45;
			//Over-ride
			this.styleM.overrideStyle (this.objects.LEGEND, legendShadow, this.styleM.TYPE.SHADOW, null);
			delete legendShadow;
		}
		//-----------------------------------------------------------------//
		//Default Animation objects (if required)
		//-----------------------------------------------------------------//
		if (this.params.defaultAnimation){
			//Task X Scale
			var taskXSAnim = new StyleObject ();
			taskXSAnim.name = "_SdTaskScaleAnim";
			taskXSAnim.param = "_xscale";
			taskXSAnim.easing = "regular";
			taskXSAnim.wait = 0;
			taskXSAnim.start = 0;
			taskXSAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.TASKS, taskXSAnim, this.styleM.TYPE.ANIMATION, "_xscale");
			delete taskXSAnim;			
			
			//Y-scale animation for task
			var tasksYSAnim = new StyleObject ();
			tasksYSAnim.name = "_SdTaskYScaleAnim";
			tasksYSAnim.param = "_yscale";
			tasksYSAnim.easing = "regular";
			tasksYSAnim.wait = 0.7;
			tasksYSAnim.start = 5;
			tasksYSAnim.duration = 0.5;
			//Over-ride
			this.styleM.overrideStyle (this.objects.TASKS, tasksYSAnim, this.styleM.TYPE.ANIMATION, "_yscale");
			delete tasksYSAnim;		
			
			//Animation for milestones
			//X Scale
			var milestoneXSAnim = new StyleObject ();
			milestoneXSAnim.name = "_SdMileStoneXScaleAnim";
			milestoneXSAnim.param = "_xscale";
			milestoneXSAnim.easing = "regular";
			milestoneXSAnim.wait = 0;
			milestoneXSAnim.start = 0;
			milestoneXSAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.MILESTONES, milestoneXSAnim, this.styleM.TYPE.ANIMATION, "_xscale");
			delete milestoneXSAnim;			
			
			//Y-Scale
			var milestonesYSAnim = new StyleObject ();
			milestonesYSAnim.name = "_SdMileStoneYScaleAnim";
			milestonesYSAnim.param = "_yscale";
			milestonesYSAnim.easing = "regular";
			milestonesYSAnim.wait = 0;
			milestonesYSAnim.start = 0;
			milestonesYSAnim.duration = 0.7;
			//Over-ride
			this.styleM.overrideStyle (this.objects.MILESTONES, milestonesYSAnim, this.styleM.TYPE.ANIMATION, "_yscale");
			delete milestonesYSAnim;		
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
		//Caption & sub-caption
		this.dm.reserveDepths ("CAPTION", 1);
		this.dm.reserveDepths ("SUBCAPTION", 1);
		//Movie clip that will contain the entire scrollable chart
		this.dm.reserveDepths ("SCROLLCONTENT", 1);
		//Mask for scrolling chart content
		this.dm.reserveDepths ("CONTENTSCROLLMASK", 1);
		//Scroll bar for content
		this.dm.reserveDepths ("CONTENTSCROLLBAR", 1);
		
		//--------------- SUB-DEPTHS INSIDE SCROLLCONTENTMC ------------//
		//Boundary for category grid
		this.dm.reserveDepths ("CATGRIDBOUNDARY", 1);
		//Category extension grid
		this.dm.reserveDepths ("CATEXTGRID", 1);
		//Trend lines
		this.dm.reserveDepths ("TRENDLINES", this.numTrendlines);
		//Category data-grids
		this.dm.reserveDepths ("CATDATAGRIDS", this.numCat);		
		//Trend values
		this.dm.reserveDepths ("TRENDVALUES", this.numTrendlines);
		//Connectors
		this.dm.reserveDepths ("CONNECTORS", this.numConnectors);
		//Tasks
		this.dm.reserveDepths ("TASKS", this.numTasks);		
		//Mile stones
		this.dm.reserveDepths ("MILESTONES", this.numMilestones);
		//Task Labels
		this.dm.reserveDepths ("TASKLABELS", this.numTasks);
		//Task Start Dates & End Dates
		this.dm.reserveDepths ("TASKSTARTDATES", this.numTasks);
		this.dm.reserveDepths ("TASKENDDATES", this.numTasks);		
		//--------------------------------------------------------------//
		//Main data-grid
		this.dm.reserveDepths ("DATAGRID", 1);
		//Mask for scrolling data grid
		this.dm.reserveDepths ("DATAGRIDSCROLLMASK", 1);
		//Scroll bar for data grid
		this.dm.reserveDepths ("DATAGRIDSCROLLBAR", 1);
		//Legend
		this.dm.reserveDepths ("LEGEND", 1);
		//Canvas Border
		this.dm.reserveDepths ("CANVASBORDER", 1);
		//Annotations above the chart
		this.dm.reserveDepths ("ANNOTATIONABOVE", 1);
	}
	/**
	 * cacheStyles method caches all the styles that will be used by real-time
	 * objects. This helps to avoid generating them at run time.
	*/
	private function cacheStyles(){
		//Task Labels
		this.styleCache.taskLabels = this.styleM.getTextStyle(this.objects.TASKLABELS);
		//Task Date Labels
		this.styleCache.taskDateLabels = this.styleM.getTextStyle(this.objects.TASKDATELABELS);
		//Trend line labels
		this.styleCache.trendLabels = this.styleM.getTextStyle(this.objects.TRENDVALUES);
		// ---------- CACHE ALL FILTERS NOW ----------------//
		//Task filters
		this.styleCache.taskFilters = this.styleM.getFilterStyles(this.objects.TASKS);
		//Task Label filters
		this.styleCache.taskLabelFilters = this.styleM.getFilterStyles(this.objects.TASKLABELS);
		//Task Date Label filters
		this.styleCache.taskDateFilters = this.styleM.getFilterStyles(this.objects.TASKDATELABELS);		
		//Milestone filters
		this.styleCache.milestoneFilters = this.styleM.getFilterStyles(this.objects.MILESTONES);		
		//Connectors filters
		this.styleCache.connectorFilters = this.styleM.getFilterStyles(this.objects.CONNECTORS);		
		//Trend line label filters
		this.styleCache.trendLabelFilters = this.styleM.getFilterStyles(this.objects.TRENDVALUES);
		//Trend line filters
		this.styleCache.trendLineFilters = this.styleM.getFilterStyles(this.objects.TRENDLINES);
	}
	/**
	 * setupScrollContentMC method creates the scrollable movie clip that contains
	 * the entire chart.
	*/
	private function setupScrollContentMC():Void{
		this.scrollContentMC = this.cMC.createEmptyMovieClip("ScrollContent",this.dm.getDepth("SCROLLCONTENT"));
	}
	/**
	 * setupCatDataGrids method initializes the data grids for categories.
	*/
	private function setupCatDataGrids():Void{
		//Here, we initialize (and not draw) the category grid for each category
		//Also, the width, height & size would be set later.
		var i:Number, j:Number;
		var cumYPos:Number = 0;
		var depth:Number = this.dm.getDepth("CATDATAGRIDS");
		//Global flag to store height required by all categories
		this.config.categoryHeight = 0;		
		for (i=1; i<=this.numCat; i++){
			//Create a movie clip for the grid
			var gridMC:MovieClip = this.scrollContentMC.createEmptyMovieClip("CatGrid_"+i, depth);
			//Initialize the grid
			this.categories[i].grid = new FCGrid(gridMC, 1, this.categories[i].numSubcat);
			//Store a reference to grid movie clip
			this.categories[i].gridMC = gridMC;
			//Set the cosmetic parameters
			this.categories[i].grid.setParams(false, this.params.ganttLineColor, this.params.ganttLineAlpha, this.params.gridResizeBarColor, this.params.gridResizeBarThickness, this.params.gridResizeBarAlpha);
			//Set each cell's data
			for (j=1; j<=this.categories[i].numSubcat; j++){
				this.categories[i].grid.setCell(1, j, this.categories[i].category[j].bgColor, this.categories[i].category[j].bgAlpha, this.categories[i].category[j].label, this.categories[i].category[j].font, this.categories[i].category[j].fontColor, this.categories[i].category[j].fontSize, this.categories[i].category[j].align, this.categories[i].category[j].vAlign, this.categories[i].category[j].isBold, this.categories[i].category[j].isItalic, this.categories[i].category[j].isUnderline, this.categories[i].category[j].link);
			}
			//Now, get the height required to render this grid.
			this.categories[i].gridHeight = this.categories[i].grid.getMaxRowHeight() + 2*this.categories[i].verticalPadding;
			//Set the position of movie clip- the cumulative Y for this category
			this.categories[i].cumYPos = cumYPos;			
			//Update cumulative Y (w.r.t Grid start)
			cumYPos += this.categories[i].gridHeight;
			//Update height required to render all categories
			this.config.categoryHeight += this.categories[i].gridHeight;			
			//Increment depth
			depth++;
		}
	}
	/**
	 * setupDataGrid method sets up the main data grid for the chart. 
	*/
	private function setupDataGrid():Void{
		var i:Number, j:Number;
		//Create the movie clip to contain it
		var gridMC:MovieClip = this.cMC.createEmptyMovieClip("DataGrid", this.dm.getDepth("DATAGRID"));
		//Create the grid
		this.datagrid = new FCGrid(gridMC, this.numProcess+1, this.numDataColumns+1);
		this.datagridMC = gridMC;
		//Set the parameters
		this.datagrid.setParams(true, this.params.gridBorderColor, this.params.gridBorderAlpha, this.params.gridResizeBarColor, this.params.gridResizeBarThickness, this.params.gridResizeBarAlpha);
		//Where do we've to place the process name in data grid?
		var processIndex:Number, currIndex:Number;
		if (this.params.processPositionInGrid == "right") {
			//If the process names position is to be in the right of grid.
			currIndex = 1;
			processIndex = this.numDataColumns+1;
		} else {
			//If the process names position is to be in the left of grid.
			processIndex = 1;
			currIndex = 2;
		}
		//-------------- STORE WIDTH OF EACH DATA COLUMN ------------//
		this.config.dataCellWidth = new Array();
		//Set the width of process column
		this.config.dataCellWidth[processIndex-1] = this.params.processWidth;		
		//Set the width of rest of the data columns
		for (i=currIndex; i<this.numDataColumns+currIndex; i++) {
			this.config.dataCellWidth[i-1] = this.dataColumn[i-currIndex+1].width;
		}
		//----------------- ADD CELLS TO GRID ---------------------//
		//Add the data for each column in data table now.
		for (i=1; i<=this.numDataColumns; i++) {
			//Set the header of this column - only once
			this.datagrid.setCell(1, currIndex, this.dataColumn[i].headerBgColor, this.dataColumn[i].headerBgAlpha, this.dataColumn[i].headerText, this.dataColumn[i].headerFont, this.dataColumn[i].headerFontColor, this.dataColumn[i].headerFontSize, this.dataColumn[i].headerAlign, this.dataColumn[i].headerVAlign, this.dataColumn[i].headerIsBold, this.dataColumn[i].headerIsItalic, this.dataColumn[i].headerIsUnderline, this.dataColumn[i].headerLink);
			//Now, set data for each cell
			for (j=1; j<=this.numProcess; j++) {				
				this.datagrid.setCell(j+1, currIndex, this.dataColumn[i].cell[j].bgColor, this.dataColumn[i].cell[j].bgAlpha, this.dataColumn[i].cell[j].label, this.dataColumn[i].cell[j].font, this.dataColumn[i].cell[j].fontColor, this.dataColumn[i].cell[j].fontSize, this.dataColumn[i].cell[j].align, this.dataColumn[i].cell[j].vAlign, this.dataColumn[i].cell[j].isBold, this.dataColumn[i].cell[j].isItalic, this.dataColumn[i].cell[j].isUnderline, this.dataColumn[i].cell[j].link);
			}
			//Increase the index
			currIndex++;
		}
		//Add the process names 
		//We've used a separate loop so that even if there are no extra data columns, the process has to be rendered
		for (j=1; j<=this.numProcess; j++) {
			//Set the process header
			if (j == 1) {
				this.datagrid.setCell(j, processIndex, this.params.processHeaderBgColor, this.params.processHeaderBgAlpha, this.params.processHeaderText, this.params.processHeaderFont, this.params.processHeaderFontColor, this.params.processHeaderFontSize, this.params.processHeaderAlign, this.params.processHeaderVAlign, this.params.processHeaderIsBold, this.params.processHeaderIsItalic, this.params.processHeaderIsUnderline, "");
			}
			//Set the process names
			this.datagrid.setCell(j+1, processIndex, this.processes[j].bgColor, this.processes[j].bgAlpha, this.processes[j].label, this.processes[j].font, this.processes[j].fontColor, this.processes[j].fontSize, this.processes[j].align, this.processes[j].vAlign, this.processes[j].isBold, this.processes[j].isItalic, this.processes[j].isUnderline, this.processes[j].link);
		}		
	}
	/**
	 * calculateCoords method calculates the position of the canvas and elements on chart.
	*/
	private function calculateCoords():Void{
		var i:Number;
		//In a Gantt chart, we can have the following physical elements:
		// - Caption, Subcaption
		// - Canvas
		// - Grid
		// - Gantt
		// - Legend		
		//Canvas comprises of Grid+Gantt and is represented by a border & base fill.
		//The canvas is the chart dimensions minus the caption, margins, legend
		//Initialize canvasHeight to total height minus margins
		var canvasHeight : Number = this.height - (this.params.chartTopMargin + this.params.chartBottomMargin);
		//Set canvasStartY
		var canvasStartY : Number = this.params.chartTopMargin;
		//Now, if we've to show caption
		if (this.params.caption != ""){
			//Create text field to get height
			var captionObj : Object = createText (true, this.params.caption, this.tfTestMC, 1, testTFX, testTFY, 0, this.styleM.getTextStyle (this.objects.CAPTION) , true, this.width, canvasHeight/4);
			//Store the height
			canvasStartY = canvasStartY + captionObj.height;
			canvasHeight = canvasHeight - captionObj.height;
			//Create element for caption - to store width & height
			this.elements.caption = returnDataAsElement (0, 0, captionObj.width, captionObj.height);
			delete captionObj;
		}
		//Now, if we've to show sub-caption
		if (this.params.subCaption != ""){
			//Create text field to get height
			var subCaptionObj : Object = createText (true, this.params.subCaption, this.tfTestMC, 1, testTFX, testTFY, 0, this.styleM.getTextStyle (this.objects.SUBCAPTION) , true, this.width, canvasHeight/4);
			//Store the height
			canvasStartY = canvasStartY + subCaptionObj.height;
			canvasHeight = canvasHeight - subCaptionObj.height;
			//Create element for sub caption - to store height
			this.elements.subCaption = returnDataAsElement (0, 0, subCaptionObj.width, subCaptionObj.height);
			delete subCaptionObj;
		}
		//Now, if either caption or sub-caption was shown, we also need to adjust caption padding
		if (this.params.caption != "" || this.params.subCaption != ""){
			//Account for padding
			canvasStartY = canvasStartY + this.params.captionPadding;
			canvasHeight = canvasHeight - this.params.captionPadding;
		}
		//Now, if we've to show the legend, calculate the height for that and accomodate that
		//We now check whether the legend is to be drawn
		if (this.params.showLegend && this.numLegendItems>0){
			//Object to store dimensions
			var lgndDim:Object;
			//Create container movie clip for legend
			this.lgndMC = this.cMC.createEmptyMovieClip ("Legend", this.dm.getDepth ("LEGEND"));
			//Maximum Height - 50% of stage
			lgnd = new Legend (lgndMC, this.styleM.getTextStyle (this.objects.LEGEND) , this.params.interactiveLegend, this.params.legendPosition, (this.width-(this.params.chartLeftMargin+this.params.chartRightMargin))/2, this.height / 2, this.width-(this.params.chartLeftMargin+this.params.chartRightMargin), (this.height - (this.params.chartTopMargin + this.params.chartBottomMargin)) * 0.5, this.params.legendAllowDrag, this.width, this.height, this.params.legendBgColor, this.params.legendBgAlpha, this.params.legendBorderColor, this.params.legendBorderThickness, this.params.legendBorderAlpha, this.params.legendScrollBgColor, this.params.legendScrollBarColor, this.params.legendScrollBtnColor);			
			//If user has defined a caption for the legend, set it
			if (this.params.legendCaption!=""){
				lgnd.setCaption(this.params.legendCaption);
			}
			//Whether to use circular marker
			lgnd.useCircleMarker(this.params.legendMarkerCircle);
			//Feed each item
			if (this.params.reverseLegend){
				for (i = this.numLegendItems; i >= 1; i --){
					lgnd.addItem (this.legendItems[i].label, this.legendItems[i].color, i);
				}
			}else{
				for (i = 1; i <= this.numLegendItems; i ++){
					lgnd.addItem (this.legendItems[i].label, this.legendItems[i].color, i);
				}
			}
			//Get dimensions of the legend
			lgndDim = lgnd.getDimensions();
			//Now, get the dimensions and adjust canvas
			//Deduct the height from the calculated canvas height
			canvasHeight = canvasHeight - lgndDim.height - this.params.legendPadding;
			//Re-set the legend position
			this.lgnd.resetXY (this.width/2, this.height - this.params.chartBottomMargin - lgndDim.height/2);
		}
		//---------- CREATE CANVAS ELEMENT ----------//
		this.elements.canvas = this.returnDataAsElement(this.params.chartLeftMargin, canvasStartY, this.width-(this.params.chartLeftMargin+this.params.chartRightMargin), canvasHeight);
		//Now, we calculate the grid width. The grid width is dependent on 2 things:
		//- User specified gantt width percent
		//- Actual space required to show full grid width.
		
		//Variable to store final grid width
		var gridWidth:Number;
		//Whether we've to use a scroll bar for grid - false by default
		this.config.gridScrolls = false;
		this.config.gridScrollViewWidth = 0;
		
		//Calculate the user specified grid width in pixels
		var userGridWidth:Number = ((100-this.params.ganttWidthPercent)/100)*this.elements.canvas.w;				
		//If the user has opted to force his own gantt width percent, do so.
		if (this.params.forceGanttWidthPercent){
			//Set the grid width to user specified grid
			gridWidth = userGridWidth;
		}else{
			//Get the actual width that might be required to accomodate the full grid.
			var fullGridWidth:Number = this.datagrid.getMaxCellWidth();
			//Now, get the minimum of full / user width and that'll be the actual grid width. This is because
			//if the full grid requires less width than what the user has allotted, it makes sense to curb it.
			gridWidth = Math.min(userGridWidth, fullGridWidth);
			//Also, if the user has opted to show full labels in grid, we might need
			//a scroll. So, assume grid width as the full grid with
			if (this.params.showFullDataTable){
				gridWidth = fullGridWidth;
				//Now, if the full grid width is more than user specified width, we show
				if (fullGridWidth>userGridWidth){
					//We need to scroll.
					this.config.gridScrolls = true;
					//View area will be what the user has specified.
					this.config.gridScrollViewWidth = userGridWidth;
				}
			}
		}
		//-------------------------- GANTT CALCULATIONS -------------------------//
		//Flag to indicate whether the gantt will have a scroll bar
		this.config.ganttScrolls = false;
		this.config.ganttScrollViewWidth = 0;
		//Get width of the Gantt
		var ganttWidth:Number = this.elements.canvas.w -((this.config.gridScrolls==true)?this.config.gridScrollViewWidth:gridWidth);
		//Now, if the user has opted to restrict the Gantt view pane to a given duration
		//we might need to show the scroll bar.
		if (this.params.ganttPaneDuration!=-1){
			//Get the duration of the chart in user specified unit 
			//Adding 1, as we need the inclusive difference (like Jan-Mar is 3 months diff, not 2)
			var chartDurationInUU:Number = this.config.startDate.diff(this.config.endDate,this.params.ganttPaneDurationUnit) + 1;
			//Now, if user duration<actual chart duration, we need to show scroll bar
			if (this.params.ganttPaneDuration<chartDurationInUU){
				//Set flag
				this.config.ganttScrolls = true;
				//Store the view pane width of gantt
				this.config.ganttScrollViewWidth = ganttWidth;
				//Increase gantt width in the required proportion.				
				ganttWidth = int(ganttWidth*(chartDurationInUU/this.params.ganttPaneDuration));
			}else{
				//No need to show scroll
			}
		}else{
			//We do not have to create any scroll bar. Also, the gantt can take full width available.
		}				
		//Create object to represent grid.
		this.elements.grid = this.returnDataAsElement(this.elements.canvas.x, this.elements.canvas.y, gridWidth, (this.config.gridScrolls || this.config.ganttScrolls)?(this.elements.canvas.h-(this.params.scrollHeight + this.params.scrollPadding)):(this.elements.canvas.h)); 		
		//Create objec to represent gantt
		this.elements.gantt = this.returnDataAsElement(this.elements.canvas.x + ((this.config.gridScrolls==true)?this.config.gridScrollViewWidth:gridWidth), this.elements.grid.y, ganttWidth, this.elements.grid.h);
		//Note - both grid & gantt element width and height it the full width & height that we'll utilize to draw
		//Scroll pane width and height are stored in config variables.
		//Reposition the scroll content container movie clip to its start.
		this.scrollContentMC._x = this.elements.gantt.x;
		this.scrollContentMC._y = this.elements.gantt.y;
		//Position the data grid movie clip too
		this.datagridMC._x = this.elements.grid.x;
		this.datagridMC._y = this.elements.grid.y;
	}
	/**
	 * calculatePoints method calculates all the points for the chart.
	*/	
	private function calculatePoints():Void{
		//Loop variable
		var i:Number, j:Number;
		//Calculate the difference in seconds between chart start date and end date
		//as we'll be storing everything in seconds.
		this.config.chartDuration = this.config.startDate.diff(this.config.endDate,"s");
		//Calculate the per pixel representaion of date
		this.config.perPixelRep = this.elements.gantt.w/this.config.chartDuration;
		//Now, we can calculate the positions for all elements on the chart.
		//--------------------WIDTH FOR CATEGORIES -----------------//
		var catWidth:Number;		
		for (i=1; i<=this.numCat; i++){
			//Array to push in width for grid distribution
			this.categories[i].gridWidthDis = new Array();
			for (j=1; j<this.categories[i].numSubcat; j++){
				//Tricky: We're getting width of each category NOT as self end-self start. But as (next start-this start) - so that
				//if the XML contains space between two categories (like 1/9/2004-31/12/2004, 1/1/2005-31/7/2005), we can accommodate it.
				catWidth = (this.getPosition(this.categories[i].category[j+1].start)-this.getPosition(this.categories[i].category[j].start));
				//Push in width 
				this.categories[i].gridWidthDis.push(catWidth);
			}			
		}
		//-------------------- HEIGHT FOR EACH PROCESS ------------------//
		this.config.processHeight = (this.elements.grid.h-this.config.categoryHeight)/this.numProcess;
		//Position for each process (w.r.t ScrollContentMC)
		for (i=1; i<=this.numProcess; i++){
			this.processes[i].y = this.config.categoryHeight + (this.config.processHeight*(i-1));
		}
		//------------------ POSITION FOR EACH TASK ---------------------//
		var taskProcessIndex:Number, taskYPos:Number, taskPadding:Number;
		var taskStartXPos:Number, taskEndXPos:Number;
		for (i=1; i<=this.numTasks; i++){
			//What process ID this task belongs to
			taskProcessIndex = this.getProcessIndex(this.tasks[i].processId);
			//What should be the height - if percentage.
			if (this.tasks[i].height.indexOf("%")!=-1){
				this.tasks[i].height = (parseInt(this.tasks[i].height,10)/100)*this.config.processHeight;
			}else{
				//Just store as number
				this.tasks[i].height = Number(this.tasks[i].height);
			}
			//What should be top padding - if percentage
			if (this.tasks[i].topPadding.indexOf("%")!=-1){
				taskPadding = (parseInt(this.tasks[i].topPadding,10)/100)*this.config.processHeight;
			}else{
				//Just store as number
				taskPadding = Number(this.tasks[i].topPadding);
			}
			//Restrict task padding to left over space
			if (taskPadding>(this.config.processHeight-this.tasks[i].height)){
				taskPadding = (this.config.processHeight-this.tasks[i].height)/2;
			}
			//Finally, set task y position as process Y + top padding + h/2
			this.tasks[i].y = int(this.processes[taskProcessIndex].y + taskPadding + (this.tasks[i].height/2));
			//Also, calculate the x position & width for each task
			taskStartXPos = this.getPosition(this.tasks[i].start);
			taskEndXPos = this.getPosition(this.tasks[i].end);
			//Store them
			this.tasks[i].x = taskStartXPos;
			this.tasks[i].width = taskEndXPos-taskStartXPos;
			//If user has defined percentComplete, we need to set the same
			if (this.tasks[i].percentComplete==-1){
				//No percent defined, so set full
				this.tasks[i].fillWidth = this.tasks[i].width;
			}else{
				//Else, proportionately
				this.tasks[i].fillWidth = (this.tasks[i].percentComplete/100)*this.tasks[i].width;
				//Set round radius to 0
				this.params.taskBarRoundRadius=0;
			}
		}
		//----------- POSITION FOR EACH MILESTONE ------------//
		for (i=1; i<=this.numMilestones; i++){
			//Store the milestone's id
			this.milestones[i].internalTaskId = getTaskIndex(this.milestones[i].taskId);
			//If it's -1, we log an error
			if (this.milestones[i].internalTaskId==-1){
				this.log("Invalid task ID","The task ID '" + this.milestones[i].taskId + "' specified for milestone could not be found.", Logger.LEVEL.ERROR);
			}else{
				//Do the calculations
				this.milestones[i].x = this.getPosition(this.milestones[i].date);
				this.milestones[i].y = this.tasks[this.milestones[i].internalTaskId].y;
				//Set the radius
				this.milestones[i].radius = getFN(this.milestones[i].radius, (this.tasks[this.milestones[i].internalTaskId].height/2)+2);
			}
		}
		//-------------- POSITION FOR EACH CONNECTOR ---------------//
		for (i=1; i<=this.numConnectors; i++){
			this.connectors[i].iFromId = this.getTaskIndex(this.connectors[i].fromTaskId);
			this.connectors[i].iToId  = this.getTaskIndex(this.connectors[i].toTaskId);
			//Check for errors
			if (this.connectors[i].iFromId==-1){
				this.log("Invalid task ID","The task ID '" + this.connectors[i].fromTaskId + "' specified for connector could not be found.", Logger.LEVEL.ERROR);
			}else if(this.connectors[i].iToId==-1){
				this.log("Invalid task ID","The task ID '" + this.connectors[i].toTaskId + "' specified for connector could not be found.", Logger.LEVEL.ERROR);
			}else{
				//Everything fine - so store starting and ending y position
				this.connectors[i].fromY = this.tasks[this.connectors[i].iFromId].y;
				this.connectors[i].toY = this.tasks[this.connectors[i].iToId].y;
			}
		}
		//----------------- POSITION FOR EACH TRENDLINE -----------------//
		for (i=1; i<=this.numTrendlines; i++){
			//Get x positions
			this.trendlines[i].x = this.getPosition(this.trendlines[i].start);
			this.trendlines[i].toX = this.getPosition(this.trendlines[i].end);
		}
	}
	/**
	 * getProcessIndex method returns the index of a specified process w.r.t to its
	 * external ID.
	*/
	private function getProcessIndex(id:String):Number{		
		var i:Number;
		//By default assume it to be -1;
		var processId:Number = -1;
		for (i=1; i<=this.numProcess; i++){
			if (id==this.processes[i].id){
				processId = i;
				break;
			}			
		}
		//Return
		return processId;
	}
	/**
	 * getTaskIndex method returns the index of the a specified task w.r.t to its
	 * external ID.
	*/
	private function getTaskIndex(id:String):Number{		
		var i:Number;
		//By default assume it to be -1;
		var taskId:Number = -1;
		for (i=1; i<=this.numTasks; i++){
			if (id==this.tasks[i].id){
				taskId = i;
				break;
			}
		}
		//Return
		return taskId;
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
	/**
	 * getPosition method gets the pixel position (co-ordinates) of a start/end date
	 * combination on the chart. The position is returned w.r.t the gantt start as origin.
	 * We take that as origin, as we intend to enable scroll for the entire movie clip that
	 * contains the chart.
	 *	@param	startDate	Date for which we want to get position.
	 *	@return				Relative x position of the date w.r.t start date in terms of 
	 *						grid start value.

	*/
	private function getPosition(_date:FCDateTime):Number{
		//Get the position
		var datePos:Number = MathExt.toNearestTwip(this.config.startDate.diff(_date, "s")*this.config.perPixelRep);
		return datePos;
	}
	// -------------------- Visual Rendering Methods ---------------------------//	
	/**
	* drawCanvas method renders the chart canvas. 
	*	@return	Nothing
	*/
	private function drawCanvas ():Void {
		//Create a new movie clip container for canvas
		var canvasMC = this.cMC.createEmptyMovieClip ("Canvas", this.dm.getDepth ("CANVAS"));		
		//Parse the color, alpha and ratio array
		var canvasColor:Array = ColorExt.parseColorList (this.params.canvasBgColor);
		var canvasAlpha:Array = ColorExt.parseAlphaList (this.params.canvasBgAlpha, canvasColor.length);
		var canvasRatio:Array = ColorExt.parseRatioList (this.params.canvasBgRatio, canvasColor.length);			
		//Create matrix object
		var matrix:Object = {
			matrixType:"box", w:this.elements.canvas.w, h:this.elements.canvas.h, x:- (this.elements.canvas.w / 2) , y:- (this.elements.canvas.h / 2) , r:MathExt.toRadians (this.params.canvasBgAngle)
		};
		//Start the fill.
		canvasMC.beginGradientFill ("linear", canvasColor, canvasAlpha, canvasRatio, matrix);		
		//Set border properties - invisible
		canvasMC.lineStyle ();
		//Draw the rectangle with center registration point
		canvasMC.moveTo ( - (this.elements.canvas.w / 2) , - (this.elements.canvas.h / 2));		
		canvasMC.lineTo (this.elements.canvas.w / 2, - (this.elements.canvas.h / 2));
		canvasMC.lineTo (this.elements.canvas.w / 2, this.elements.canvas.h / 2);
		canvasMC.lineTo ( - (this.elements.canvas.w / 2) , this.elements.canvas.h / 2);
		canvasMC.lineTo ( - (this.elements.canvas.w / 2) , - (this.elements.canvas.h / 2));
		//Set the x and y position
		canvasMC._x = this.elements.canvas.x + this.elements.canvas.w / 2;
		canvasMC._y = this.elements.canvas.y + this.elements.canvas.h / 2;
		//End Fill
		canvasMC.endFill ();
		// --------------------------- DRAW CANVAS BORDER --------------------------//
		//Canvas Border
		if (this.params.canvasBorderAlpha>0){
			//Create a new movie clip container for canvas
			var canvasBorderMC = this.cMC.createEmptyMovieClip ("CanvasBorder", this.dm.getDepth ("CANVASBORDER"));
			//Set border properties
			canvasBorderMC.lineStyle (this.params.canvasBorderThickness, parseInt (this.params.canvasBorderColor, 16) , this.params.canvasBorderAlpha);
			//Move to (-w/2, 0);
			canvasBorderMC.moveTo ( - (this.elements.canvas.w / 2) , - (this.elements.canvas.h / 2));
			//Draw the rectangle with center registration point
			canvasBorderMC.lineTo (this.elements.canvas.w / 2, - (this.elements.canvas.h / 2));
			canvasBorderMC.lineTo (this.elements.canvas.w / 2, this.elements.canvas.h / 2);
			canvasBorderMC.lineTo ( - (this.elements.canvas.w / 2) , this.elements.canvas.h / 2);
			canvasBorderMC.lineTo ( - (this.elements.canvas.w / 2) , - (this.elements.canvas.h / 2));
			//Set the x and y position
			canvasBorderMC._x = this.elements.canvas.x + this.elements.canvas.w / 2;
			canvasBorderMC._y = this.elements.canvas.y + this.elements.canvas.h / 2;
		}			
		//Apply animation
		if (this.params.animation){
			this.styleM.applyAnimation (canvasBorderMC, this.objects.CANVAS, this.macro, canvasBorderMC._x, - this.elements.canvas.w / 2, canvasBorderMC._y, - this.elements.canvas.h / 2, 100, 100, 100, null);
		}
		//Apply filters
		this.styleM.applyFilters (canvasMC, this.objects.CANVAS);
		//Clear Interval
		clearInterval (this.config.intervals.canvas);
	}
	//---------------------------- VISUAL RENDERING METHODS ------------------------------//
	/**
	* drawHeaders method renders the following on the chart:
	* CAPTION, SUBCAPTION, XAXISNAME, YAXISNAME
	*/
	private function drawHeaders (){
		//Render caption
		if (this.params.caption != ""){
			var captionStyleObj : Object = this.styleM.getTextStyle (this.objects.CAPTION);
			captionStyleObj.align = "center";
			captionStyleObj.vAlign = "bottom";
			var captionObj : Object = createText (false, this.params.caption, this.cMC, this.dm.getDepth ("CAPTION") , this.x + (this.width / 2) , this.params.chartTopMargin, 0, captionStyleObj, true, this.elements.caption.w, this.elements.caption.h);
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (captionObj.tf, this.objects.CAPTION, this.macro, captionObj.tf._x, captionObj.tf._y, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (captionObj.tf, this.objects.CAPTION);
			//Delete
			delete captionObj;
			delete captionStyleObj;
		}
		//Render sub caption
		if (this.params.subCaption != ""){
			var subCaptionStyleObj : Object = this.styleM.getTextStyle (this.objects.SUBCAPTION);
			subCaptionStyleObj.align = "center";
			subCaptionStyleObj.vAlign = "top";
			var subCaptionObj : Object = createText (false, this.params.subCaption, this.cMC, this.dm.getDepth ("SUBCAPTION") , this.x + (this.width / 2) , this.elements.canvas.y - this.params.captionPadding, 0, subCaptionStyleObj, true, this.elements.subCaption.w, this.elements.subCaption.h);
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (subCaptionObj.tf, this.objects.SUBCAPTION, this.macro, subCaptionObj.tf._x, subCaptionObj.tf._y, 100, null, null, null);
			}
			//Apply filters
			this.styleM.applyFilters (subCaptionObj.tf, this.objects.SUBCAPTION);
			//Delete
			delete subCaptionObj;
			delete subCaptionStyleObj;
		}		
		//Clear Interval
		clearInterval (this.config.intervals.headers);
	}	
	/**
	 * drawCategoryGrid method draws the category grids on chart.
	*/
	private function drawCategoryGrid():Void{
		//Iterate through all grids, set size and draw
		var i:Number, j:Number;
		for (i=1; i<=this.numCat; i++){
			//Set y position
			this.categories[i].gridMC._y = this.categories[i].cumYPos;
			//Set size
			//Tricky: We slice this.categories[i].gridWidthDis array and then pass it to the function. Slice
			//here basically creates a copy of the original array, so that the original array stays un-modified.
			//Inside the grid, we un-shift the array by one element, to match base index. 
			this.categories[i].grid.setSize(this.elements.gantt.w, this.categories[i].gridHeight, this.categories[i].gridWidthDis.slice(), []);			
			//Draw
			this.categories[i].grid.draw();
		}
		//We also need to draw the bottom part of grid (also, extension, if user has specified)
		//Create the movie clip for that
		var catExtGridMC:MovieClip = this.scrollContentMC.createEmptyMovieClip("CatExtGrid",this.dm.getDepth("CATEXTGRID"));
		//Set y position to start from where the categories grid ended.
		catExtGridMC._y = this.config.categoryHeight
		if (this.numCat>0){			
			//Initialize the grid
			this.catExtGrid = new FCGrid(catExtGridMC, this.numProcess, this.categories[this.numCat].numSubcat);
			//Set parameters
			this.catExtGrid.setParams(false, this.params.ganttLineColor, this.params.ganttLineAlpha, this.params.gridResizeBarColor, this.params.gridResizeBarThickness, this.params.gridResizeBarAlpha);
			//Set size
			this.catExtGrid.setSize(this.elements.gantt.w, this.elements.gantt.h - this.config.categoryHeight, this.categories[this.numCat].gridWidthDis.slice(), []);
			//Set each cell's data (basically border, bg)
			for (i=1; i<=this.numProcess; i++){
				for (j=1; j<=this.categories[this.numCat].numSubcat; j++){
					//If the user has extended the category background, we need to set cell
					//background as that of the last category
					if (this.params.extendCategoryBg) {					
						this.catExtGrid.setCell(i, j, this.categories[this.numCat].category[j].bgColor, this.categories[this.numCat].category[j].bgAlpha, "", "", "", 0, "center", "middle", false, false, false, "");
					} else {
						//Else, do not set the background - just border
						this.catExtGrid.setCell(i, j, "", 0, "", "", "", 0, "center", "middle", false, false, false, "");
					}
				}
			}			
		}else{
			//If user has not specified any category, we'll have a grid with this.numProcess rows and 1 column
			//Initialize the grid
			this.catExtGrid = new FCGrid(catExtGridMC, this.numProcess, 1);
			//Set parameters
			this.catExtGrid.setParams(false, this.params.ganttLineColor, this.params.ganttLineAlpha, this.params.gridResizeBarColor, this.params.gridResizeBarThickness, this.params.gridResizeBarAlpha);
			//Set size
			this.catExtGrid.setSize(this.elements.gantt.w, this.elements.gantt.h, [], []);
			//Set each cell's data (basically border, bg)
			for (i=1; i<=this.numProcess; i++){
				//Just border
				this.catExtGrid.setCell(i, 1, "", 0, "", "", "", 0, "center", "middle", false, false, false, "");
			}	
		}
		//Draw it
		this.catExtGrid.draw();
		//Clear Interval
		clearInterval(this.config.intervals.categoryGrid);
	}
	/**
	 * drawDataGrid method draws the data grid for the chart.
	*/
	private function drawDataGrid():Void{
		//Set size of the data grid
		//Tricky: If user has opted not to show any categories, we set the height of process header as 0.1, instead of 0.
		//As the grid assumes 0 to be non-specified value and then automatically distributes the height.
		this.datagrid.setSize(this.elements.grid.w, this.elements.grid.h, (this.params.showFullDataTable && !this.params.forceGanttWidthPercent)?([-1]):(this.config.dataCellWidth), [(this.config.categoryHeight==0)?0.1:this.config.categoryHeight]);
		//Draw it
		this.datagrid.draw();
		//Clear Interval
		clearInterval(this.config.intervals.datagrid);
	}
	/**
	 * drawScrollBars method draws the scroll bars for the grid & gantt
	*/
	private function drawScrollBars():Void{
		//First, do so for grid		
		if (this.config.gridScrolls){			
			//Create movie clip containers
			var gridMaskMC:MovieClip = this.cMC.createEmptyMovieClip("DataGridMask",this.dm.getDepth("DATAGRIDSCROLLMASK"));
			var gridScrollBarMC:MovieClip = this.cMC.createEmptyMovieClip("DataGridScrollBar",this.dm.getDepth("DATAGRIDSCROLLBAR"));
			//Set the position of scroll bar container movie clip
			gridScrollBarMC._x = this.elements.grid.x;
			gridScrollBarMC._y = this.elements.grid.toY + this.params.scrollPadding;
			//Initialize the scroll bar
			var gridScrollBar:FCChartHScrollBar = new FCChartHScrollBar(this.datagridMC, this.datagrid.getBoundaryMC(), gridScrollBarMC, gridMaskMC, this.config.gridScrollViewWidth, this.elements.grid.h, this.config.gridScrollViewWidth, this.params.scrollHeight, this.params.scrollBtnWidth, this.params.scrollBtnPadding);
			//Set the color
			gridScrollBar.setColor(this.params.scrollColor);
		}
		//Draw the gantt scroll bar
		if (this.config.ganttScrolls){
			//Create the boundary for the category grid
			//We need to create the reference boundary, as width of the elements might not be
			//equal to the total width alloted (because of summation of difference of rounding)
			var boundaryMC:MovieClip = this.scrollContentMC.createEmptyMovieClip("BoundaryMC", this.dm.getDepth("CATGRIDBOUNDARY"));
			//We set the scrolling width based on whether the user has defined any categories or not.
			var w:Number = (this.numCat>0)?this.categories[this.numCat].grid.getBoundaryMC()._width:this.catExtGrid.getBoundaryMC()._width;
			var h:Number = this.elements.gantt.h;
			//Draw rectangle
			boundaryMC.lineStyle(0,0xffffff,0);		
			boundaryMC.moveTo(0,0);
			boundaryMC.lineTo(w,0);
			boundaryMC.lineTo(w,h);
			boundaryMC.lineTo(0,h);
			boundaryMC.lineTo(0,0);			
			//-----------//
			//Create movie clip containers
			var ganttMaskMC:MovieClip = this.cMC.createEmptyMovieClip("GanttMask",this.dm.getDepth("CONTENTSCROLLMASK"));
			var ganttScrollBarMC:MovieClip = this.cMC.createEmptyMovieClip("GanttScrollBar",this.dm.getDepth("CONTENTSCROLLBAR"));
			//Set the position of scroll bar container movie clip
			ganttScrollBarMC._x = this.elements.gantt.x;
			ganttScrollBarMC._y = this.elements.gantt.toY + this.params.scrollPadding;
			//Initialize the scroll bar
			var ganttScrollBar:FCChartHScrollBar = new FCChartHScrollBar(this.scrollContentMC, boundaryMC, ganttScrollBarMC, ganttMaskMC, this.config.ganttScrollViewWidth, this.elements.gantt.h, this.config.ganttScrollViewWidth, this.params.scrollHeight, this.params.scrollBtnWidth, this.params.scrollBtnPadding);
			//Set the color
			ganttScrollBar.setColor(this.params.scrollColor);
		}
		//Clear interval
		clearInterval(this.config.intervals.scrollBars);
	}
	/**
	 * drawTasks method draws the actual task bars.
	*/
	private function drawTasks():Void{
		var i:Number;
		var depth:Number = this.dm.getDepth("TASKS");
		//Create function storage containers for Delegate functions
		var fnRollOver : Function, fnClick : Function;
		//If we've to show slack as fill, parse the slack color.
		if (this.params.showSlackAsFill){
			this.config.arrSlackColor = ColorExt.parseColorMix(this.params.slackFillColor, this.params.taskBarFillMix)
		}
		//Iterate through each task and draw
		for (i=1; i<=this.numTasks; i++){
			//Create movie clip container.
			var taskMC:MovieClip = this.scrollContentMC.createEmptyMovieClip("Task_"+i,depth);
			//Disable tabIndex
			taskMC.tabEnabled = false;
			//Create sub-movie clips for border, normalfill, slackfill
			var taskBorderMC:MovieClip = taskMC.createEmptyMovieClip("Border",3);
			var taskFillMC:MovieClip = taskMC.createEmptyMovieClip("Fill",2);
			var slackFillMC:MovieClip = taskMC.createEmptyMovieClip("Slack",1);
			//Position parent movie clip
			taskMC._x = this.tasks[i].x;
			//Set y
			taskMC._y = this.tasks[i].y;
			//Position the slack movie clip
			if (this.tasks[i].percentComplete!=-1){
				//Relative position set to fillWidth
				slackFillMC._x = this.tasks[i].fillWidth;				
			}
			// ---------------- DRAW IT ------------------//
			if (this.tasks[i].showAsGroup){
				//If the task is to be shown as a group, we'll draw it in a different shape
				if (this.tasks[i].showBorder){					
					//Vertical extension
					var ve:Number = this.tasks[i].height/2;					
					//Create matrix object
					var matrix:Object = {matrixType:"box", w:this.tasks[i].width, h:this.tasks[i].height, x:0, y:-(this.tasks[i].height)/2, r:-Math.PI/2};			
					//Start the fill.			
					taskFillMC.beginGradientFill("linear", this.tasks[i].arrColor, this.tasks[i].arrAlpha, this.tasks[i].arrRatio, matrix);
					//Set line style
					taskFillMC.lineStyle(this.tasks[i].borderThickness, parseInt(this.tasks[i].borderColor,16), this.tasks[i].borderAlpha);
					//Draw the shape					
					taskFillMC.moveTo(0,ve);
					taskFillMC.lineTo(ve,0);
					taskFillMC.lineTo(this.tasks[i].width-ve,0);
					taskFillMC.lineTo(this.tasks[i].width,ve);
					taskFillMC.lineTo(this.tasks[i].width,-ve);
					taskFillMC.lineTo(0,-ve);					
					//End fill
					taskFillMC.endFill();
				}
			}else{
				//Normal task - Draw the border first
				if (this.tasks[i].showBorder){
					var borderColor:Number = parseInt(this.tasks[i].borderColor,16);
					//Set line style
					taskBorderMC.lineStyle(this.tasks[i].borderThickness, borderColor, this.tasks[i].borderAlpha);
					//Set invisible fill - to react to tool text - in case of slack being shown as empty
					taskBorderMC.beginFill(0xffffff,0);
					//Draw rectangle
					DrawingExt.drawRoundedRect(taskBorderMC, 0, -(this.tasks[i].height)/2, this.tasks[i].width, this.tasks[i].height, {tl:this.params.taskBarRoundRadius, tr:this.params.taskBarRoundRadius, bl:this.params.taskBarRoundRadius, br:this.params.taskBarRoundRadius}, {l:borderColor, r:borderColor, t:borderColor, b:borderColor}, {l:this.tasks[i].borderAlpha, r:this.tasks[i].borderAlpha, t:this.tasks[i].borderAlpha, b:this.tasks[i].borderAlpha}, {l:this.tasks[i].borderThickness, r:this.tasks[i].borderThickness, b:this.tasks[i].borderThickness, t:this.tasks[i].borderThickness});
					//End Fill
					taskBorderMC.endFill();
				}
				//--------- Main Fill ----------//
				//Create matrix object
				var matrix:Object = {matrixType:"box", w:this.tasks[i].fillWidth, h:this.tasks[i].height, x:0, y:-(this.tasks[i].height)/2, r:-Math.PI/2};			
				//Start the fill.			
				taskFillMC.beginGradientFill("linear", this.tasks[i].arrColor, this.tasks[i].arrAlpha, this.tasks[i].arrRatio, matrix);
				//Draw rectangle
				DrawingExt.drawRoundedRect(taskFillMC, 0, -(this.tasks[i].height)/2, this.tasks[i].fillWidth, this.tasks[i].height, {tl:this.params.taskBarRoundRadius, tr:(((this.tasks[i].fillWidth+this.params.taskBarRoundRadius)<this.tasks[i].width)?0:this.params.taskBarRoundRadius), bl:this.params.taskBarRoundRadius, br:(((this.tasks[i].fillWidth+this.params.taskBarRoundRadius)<this.tasks[i].width)?0:this.params.taskBarRoundRadius)}, {l:"", r:"", t:"", b:""}, {l:0, r:0, t:0, b:0}, {l:0, r:0, b:0, t:0});
				//End the fill.
				taskFillMC.endFill();
				//------------ Slack ------------//
				if (this.params.showSlackAsFill && this.tasks[i].percentComplete!=-1 && this.tasks[i].percentComplete<100){
					//Create matrix object
					var matrix:Object = {matrixType:"box", w:this.tasks[i].width-this.tasks[i].fillWidth, h:this.tasks[i].height, x:0, y:-(this.tasks[i].height)/2, r:-Math.PI/2};			
					//Start the fill.			
					slackFillMC.beginGradientFill("linear", this.config.arrSlackColor, this.tasks[i].arrAlpha, this.tasks[i].arrRatio, matrix);
					//Draw rectangle
					DrawingExt.drawRoundedRect(slackFillMC, 0, -(this.tasks[i].height)/2, this.tasks[i].width-this.tasks[i].fillWidth, this.tasks[i].height, {tl:(((this.tasks[i].width-this.tasks[i].fillWidth)<=this.params.taskBarRoundRadius)?this.params.taskBarRoundRadius:0), tr:this.params.taskBarRoundRadius, bl:(((this.tasks[i].width-this.tasks[i].fillWidth)<=this.params.taskBarRoundRadius)?this.params.taskBarRoundRadius:0), br:this.params.taskBarRoundRadius}, {l:"", r:"", t:"", b:""}, {l:0, r:0, t:0, b:0}, {l:0, r:0, b:0, t:0});
					//End the fill.
					slackFillMC.endFill();
				}
			}
			//Apply filter
			taskMC.filters = this.styleCache.taskFilters;
			//Apply animation and filter effects
			if (this.tasks[i].animation){
				this.styleM.applyAnimation (taskMC, this.objects.TASKS, this.macro, null, null, 100, 100, 100, null);
			}			
			//Increment depth
			depth++;			
			//-------------------- SET EVENT HANDLERS ----------------------//
			//Event handlers for tool tip
			if (this.params.showToolTip && this.tasks[i].toolText!=""){
				//Create Delegate for roll over function showToolText
				fnRollOver = Delegate.create (this, showToolText);
				//Set the tool text directly
				fnRollOver.toolText = this.tasks[i].toolText;
				//Assing the delegates to movie clip handler
				taskMC.onRollOver = fnRollOver;
				//Set roll out and mouse move too.
				taskMC.onRollOut = taskMC.onReleaseOutside = Delegate.create (this, hideToolText);
				taskMC.onMouseMove = Delegate.create (this, positionToolText);
			}
			//Click handler for links - only if link for this task has been defined and click URL
			//has not been defined.
			if (this.tasks[i].link != "" && this.tasks[i].link != undefined && this.params.clickURL == ""){
				//Create delegate function
				fnClick = Delegate.create (this, activateLink);
				//Set link itself
				fnClick.link = this.tasks[i].link;
				//Assign
				taskMC.onRelease = fnClick;
			} else {
				//Do not use hand cursor
				taskMC.useHandCursor = (this.params.clickURL == "") ?false : true;
			}
		}
		//Clear interval
		clearInterval(this.config.intervals.tasks);
	}
	/**
	 * drawTaskLabels method draws the labels for each task.
	*/
	private function drawTaskLabels():Void{
		var i:Number;
		//Depths for each label
		var taskLabelDepth:Number = this.dm.getDepth("TASKLABELS");
		var taskStartDepth:Number = this.dm.getDepth("TASKSTARTDATES");
		var taskEndDepth:Number = this.dm.getDepth("TASKENDDATES");
		//Iterate through each to render.
		for (i=1; i<=this.numTasks; i++){
			//Draw the label first
			if ((this.tasks[i].showLabel && this.tasks[i].label!="") || (this.tasks[i].showPercentLabel && this.tasks[i].percentComplete!=-1)){
				//Select label to display
				var label:String = (this.tasks[i].showLabel && this.tasks[i].label!="")?(this.tasks[i].label + ((this.tasks[i].showPercentLabel && this.tasks[i].percentComplete!=-1)?" ":"")):("");
				label = label + ((this.tasks[i].showPercentLabel && this.tasks[i].percentComplete!=-1)?(this.tasks[i].percentComplete + "%"):"");
				//Set font properties
				this.styleCache.taskLabels.font = this.tasks[i].font;
				this.styleCache.taskLabels.fontSize = this.tasks[i].fontSize;
				this.styleCache.taskLabels.fontColor = this.tasks[i].fontColor;
				this.styleCache.taskLabels.align = "center";
				this.styleCache.taskLabels.vAlign = "top";
				//Create it.
				var labelObj:Object = Utils.createText(false, label, this.scrollContentMC, taskLabelDepth, this.tasks[i].x + this.tasks[i].width/2, this.tasks[i].y-(this.tasks[i].height/2), 0, this.styleCache.taskLabels, false, 0, 0);
				//Apply filters.
				labelObj.tf.filters = this.styleCache.taskLabelFilters;
				//Animate it.
				if (this.params.animation){
					this.styleM.applyAnimation (labelObj.tf, this.objects.TASKLABELS, this.macro, labelObj.tf._x, labelObj.tf._y, 100, null, null, null);
				}
				//Increase depth
				taskLabelDepth++;
			}
			//Starting date
			if (this.tasks[i].showStartDate){
				//Set font properties
				this.styleCache.taskDateLabels.font = this.tasks[i].font;
				this.styleCache.taskDateLabels.fontSize = this.tasks[i].fontSize;
				this.styleCache.taskDateLabels.fontColor = this.tasks[i].fontColor;
				this.styleCache.taskDateLabels.align = "right";
				this.styleCache.taskDateLabels.vAlign = "middle";
				//Create it.
				var startDateObj:Object = Utils.createText(false, this.tasks[i].fStartDate, this.scrollContentMC, taskStartDepth, this.tasks[i].x - this.params.taskDatePadding, this.tasks[i].y, 0, this.styleCache.taskDateLabels, false, 0, 0);
				//Apply filters.
				startDateObj.tf.filters = this.styleCache.taskDateFilters;
				//Animate it.
				if (this.params.animation){
					this.styleM.applyAnimation (startDateObj.tf, this.objects.TASKDATELABELS, this.macro, startDateObj.tf._x, startDateObj.tf._y, 100, null, null, null);
				}		
				//Increase depth
				taskStartDepth++;
			}
			//Ending date
			if (this.tasks[i].showEndDate){
				//Set font properties
				this.styleCache.taskDateLabels.font = this.tasks[i].font;
				this.styleCache.taskDateLabels.fontSize = this.tasks[i].fontSize;
				this.styleCache.taskDateLabels.fontColor = this.tasks[i].fontColor;
				this.styleCache.taskDateLabels.align = "left";
				this.styleCache.taskDateLabels.vAlign = "middle";
				//Create it.
				var endDateObj:Object = Utils.createText(false, this.tasks[i].fEndDate, this.scrollContentMC, taskEndDepth, this.tasks[i].x + this.tasks[i].width + this.params.taskDatePadding, this.tasks[i].y, 0, this.styleCache.taskDateLabels, false, 0, 0);
				//Apply filters.
				endDateObj.tf.filters = this.styleCache.taskDateFilters;
				//Animate it.
				if (this.params.animation){
					this.styleM.applyAnimation (endDateObj.tf, this.objects.TASKDATELABELS, this.macro, endDateObj.tf._x, endDateObj.tf._y, 100, null, null, null);
				}		
				//Increase depth
				taskEndDepth++;
			}
		}
		//Clear interval
		clearInterval(this.config.intervals.taskLabels);
	}
	/**
	 * drawMileStones method draws the milestones on the chart.
	*/
	private function drawMileStones():Void{
		var i:Number;
		//Depth
		var depth:Number = this.dm.getDepth("MILESTONES");
		//Create function storage containers for Delegate functions
		var fnRollOver : Function, fnClick : Function;
		//Iterate through all the milestones
		for (i=1; i<=this.numMilestones; i++){
			//If it relates to a task
			if (this.milestones[i].internalTaskId!=-1){
				//Draw it based on the parameters specified by user
				var msMC:MovieClip = this.scrollContentMC.createEmptyMovieClip("Milestone_"+i,depth);
				//Disable tab
				msMC.tabEnabled = false;
				//Position it
				msMC._x = this.milestones[i].x;
				msMC._y = this.milestones[i].y;
				//Set fill properties
				msMC.lineStyle(this.milestones[i].borderThickness, parseInt(this.milestones[i].borderColor,16),100);
				msMC.beginFill(parseInt(this.milestones[i].color,16), this.milestones[i].alpha);
				//Draw the shape
				if (this.milestones[i].shape=="polygon"){
					//Draw polygon
					DrawingExt.drawPoly(msMC, 0, 0, this.milestones[i].numSides, this.milestones[i].radius, this.milestones[i].startAngle);
				}else{
					//Draw star
					this.drawStar(msMC, 0, 0, this.milestones[i].numSides, this.milestones[i].radius/2, this.milestones[i].radius, this.milestones[i].startAngle);
				}
				//End fill
				msMC.endFill();
				//Set filters
				msMC.filters = this.styleCache.milestoneFilters;
				//Apply animation
				if (this.params.animation){
					this.styleM.applyAnimation (msMC, this.objects.MILESTONES, this.macro, msMC._x, msMC._y, 100, 100, 100, null);
				}
				//Increase depth
				depth++;
				//-------------------- SET EVENT HANDLERS ----------------------//
				//Event handlers for tool tip
				if (this.milestones[i].toolText!=""){
					//Create Delegate for roll over function showToolText
					fnRollOver = Delegate.create (this, showToolText);
					//Set the tool text directly
					fnRollOver.toolText = this.milestones[i].toolText;
					//Assing the delegates to movie clip handler
					msMC.onRollOver = fnRollOver;
					//Set roll out and mouse move too.
					msMC.onRollOut = msMC.onReleaseOutside = Delegate.create (this, hideToolText);
					msMC.onMouseMove = Delegate.create (this, positionToolText);
				}
				//Click handler for links - only if link for this task has been defined and click URL
				//has not been defined.
				if (this.milestones[i].link != "" && this.milestones[i].link != undefined && this.params.clickURL == ""){
					//Create delegate function
					fnClick = Delegate.create (this, activateLink);
					//Set link itself
					fnClick.link = this.milestones[i].link;
					//Assign
					msMC.onRelease = fnClick;
				} else {
					//Do not use hand cursor
					msMC.useHandCursor = (this.params.clickURL == "") ?false : true;
				}
			}
		}
		//Clear interval
		clearInterval(this.config.intervals.milestones);
	}
	/**
	 * drawConnectors method draws the connectors for the chart.
	*/
	private function drawConnectors():Void{
		var i:Number;
		//Get depth
		var depth:Number = this.dm.getDepth("CONNECTORS");
		//Iterate through each and draw it
		for (i=1; i<=this.numConnectors; i++){			
			//If the connector's from and to Id are defined, only then we draw the connector
			if (this.connectors[i].iToId != -1 && this.connectors[i].iFromId != -1) {
				//Create the container				
				var mcConnector:MovieClip = this.scrollContentMC.createEmptyMovieClip("Connector_"+i, depth);
				//Set the line style
				mcConnector.lineStyle(this.connectors[i].thickness, parseInt(this.connectors[i].color, 16), this.connectors[i].alpha);				
				//Check if the to and from bars are in straight line
				var isStraightLine:Boolean = (this.connectors[i].fromY == this.connectors[i].toY);
				//Dash properties
				var dashLength:Number = 3;
				var dashGap:Number = (this.connectors[i].isDashed == 1) ? (this.connectors[i].thickness+2) : 0;
				//Store id of start and end tasks
				var startTaskId:Number = this.connectors[i].iFromId;
				var endTaskId:Number = this.connectors[i].iToId;
				//X Positions
				var startTaskX1:Number = this.tasks[startTaskId].x;
				var startTaskX2:Number = this.tasks[startTaskId].x+this.tasks[startTaskId].width;
				var endTaskX1:Number = this.tasks[endTaskId].x;
				var endTaskX2:Number = this.tasks[endTaskId].x+this.tasks[endTaskId].width;
				//Y Positions
				var startTaskY:Number = this.connectors[i].fromY;
				var endTaskY:Number = this.connectors[i].toY;
				var diff:Number = 0;
				//There can be four cases if the two tasks are not in straight line
				var cnCase:Number = 0;
				//cnCase 1: End of StartTask to Start of EndTask
				if (this.connectors[i].fromTaskConnectStart == false && this.connectors[i].toTaskConnectStart == true) {
					cnCase = 1;
				}
				//cnCase 2: End of StartTask to End of EndTask			
				if (this.connectors[i].fromTaskConnectStart == false && this.connectors[i].toTaskConnectStart == false) {
					cnCase = 2;
				}
				//cnCase 3: Start of StartTask to Start of EndTask
				if (this.connectors[i].fromTaskConnectStart == true && this.connectors[i].toTaskConnectStart == true) {
					cnCase = 3;
				}
				//cnCase 4: Start of StartTask to End of EndTask
				if (this.connectors[i].fromTaskConnectStart == true && this.connectors[i].toTaskConnectStart == false) {
					cnCase = 4;
				}
				if (isStraightLine) {
					var taskHeight = this.tasks[startTaskId].height;
					//If two task bars are in a straight line, then the control comes here
					//depending on the cnCase draw lines
					switch (cnCase) {
					case 1 :
						//case 1: End of StartTask to Start of EndTask
						diff = endTaskX1-startTaskX2;						
						DrawingExt.dashTo(mcConnector,startTaskX2, startTaskY, startTaskX2+(diff/10), startTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX2+(diff/10), startTaskY, startTaskX2+(diff/10), startTaskY-taskHeight, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX2+(diff/10), startTaskY-taskHeight, endTaskX1-(diff/10), startTaskY-taskHeight, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,endTaskX1-(diff/10), startTaskY-taskHeight, endTaskX1-(diff/10), startTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,endTaskX1-(diff/10), startTaskY, endTaskX1, endTaskY, dashLength, dashGap);
						break;
					case 2 :
						//case 2: End of StartTask to End of EndTask			
						DrawingExt.dashTo(mcConnector,startTaskX2, startTaskY, startTaskX2+this.params.connectorExtension, startTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX2+this.params.connectorExtension, startTaskY, startTaskX2+this.params.connectorExtension, startTaskY-taskHeight, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX2+this.params.connectorExtension, startTaskY-taskHeight, endTaskX2+this.params.connectorExtension, startTaskY-taskHeight, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,endTaskX2+this.params.connectorExtension, endTaskY-taskHeight, endTaskX2+this.params.connectorExtension, endTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,endTaskX2+this.params.connectorExtension, endTaskY, endTaskX2, endTaskY, dashLength, dashGap);
						break;
					case 3 :
						//case 3: Start of StartTask to Start of EndTask
						DrawingExt.dashTo(mcConnector,startTaskX1, startTaskY, startTaskX1-this.params.connectorExtension, startTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX1-this.params.connectorExtension, startTaskY, startTaskX1-this.params.connectorExtension, startTaskY-taskHeight, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX1-this.params.connectorExtension, startTaskY-taskHeight, endTaskX1-this.params.connectorExtension, startTaskY-taskHeight, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,endTaskX1-this.params.connectorExtension, startTaskY-taskHeight, endTaskX1-this.params.connectorExtension, startTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,endTaskX1-this.params.connectorExtension, startTaskY, endTaskX1, startTaskY, dashLength, dashGap);
						break;
					case 4 :
						//case 4: Start of StartTask to End of EndTask
						DrawingExt.dashTo(mcConnector,startTaskX1, startTaskY, startTaskX1-this.params.connectorExtension, startTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX1-this.params.connectorExtension, startTaskY, startTaskX1-this.params.connectorExtension, startTaskY-taskHeight, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX1-this.params.connectorExtension, startTaskY-taskHeight, endTaskX2+this.params.connectorExtension, startTaskY-taskHeight, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,endTaskX2+this.params.connectorExtension, startTaskY-taskHeight, endTaskX2+this.params.connectorExtension, startTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,endTaskX2+this.params.connectorExtension, startTaskY, endTaskX2, startTaskY, dashLength, dashGap);
						break;
					}
				} else {
					//Now, depending on the case draw lines
					switch (cnCase) {
					case 1 :
						//case 1: End of StartTask to Start of EndTask					
						if (startTaskX2<=endTaskX1) {
							DrawingExt.dashTo(mcConnector,startTaskX2, startTaskY, startTaskX2+(endTaskX1-startTaskX2)/2, startTaskY, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,startTaskX2+(endTaskX1-startTaskX2)/2, startTaskY, startTaskX2+(endTaskX1-startTaskX2)/2, endTaskY, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,startTaskX2+(endTaskX1-startTaskX2)/2, endTaskY, endTaskX1, endTaskY, dashLength, dashGap);
						} else {
							//Now, if startTaskX2 > endTaskX1 
							DrawingExt.dashTo(mcConnector,startTaskX2, startTaskY, startTaskX2+this.params.connectorExtension, startTaskY, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,startTaskX2+this.params.connectorExtension, startTaskY, startTaskX2+this.params.connectorExtension, startTaskY+(endTaskY-startTaskY)/2, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,startTaskX2+this.params.connectorExtension, startTaskY+(endTaskY-startTaskY)/2, endTaskX1-this.params.connectorExtension, startTaskY+(endTaskY-startTaskY)/2, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,endTaskX1-this.params.connectorExtension, startTaskY+(endTaskY-startTaskY)/2, endTaskX1-this.params.connectorExtension, endTaskY, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,endTaskX1-this.params.connectorExtension, endTaskY, endTaskX1, endTaskY, dashLength, dashGap);
						}
						break;
					case 2 :
						//case 2: End of StartTask to End of EndTask
						diff = ((endTaskX2-startTaskX2)<0) ? (0) : (endTaskX2-startTaskX2);
						DrawingExt.dashTo(mcConnector,startTaskX2, startTaskY, startTaskX2+this.params.connectorExtension+diff, startTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX2+this.params.connectorExtension+diff, startTaskY, startTaskX2+this.params.connectorExtension+diff, endTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX2+this.params.connectorExtension+diff, endTaskY, endTaskX2, endTaskY, dashLength, dashGap);
						break;
					case 3 :
						//case 3: Start of StartTask to Start of EndTask
						diff = ((startTaskX1-endTaskX1)<0) ? (0) : (startTaskX1-endTaskX1);
						DrawingExt.dashTo(mcConnector,startTaskX1, startTaskY, startTaskX1-this.params.connectorExtension-diff, startTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX1-this.params.connectorExtension-diff, startTaskY, startTaskX1-this.params.connectorExtension-diff, endTaskY, dashLength, dashGap);
						DrawingExt.dashTo(mcConnector,startTaskX1-this.params.connectorExtension-diff, endTaskY, endTaskX1, endTaskY, dashLength, dashGap);
						break;
					case 4 :
						//case 4: Start of StartTask to End of EndTask
						if (startTaskX1>endTaskX2) {
							DrawingExt.dashTo(mcConnector,startTaskX1, startTaskY, startTaskX1-(startTaskX1-endTaskX2)/2, startTaskY, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,startTaskX1-(startTaskX1-endTaskX2)/2, startTaskY, startTaskX1-(startTaskX1-endTaskX2)/2, endTaskY, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,startTaskX1-(startTaskX1-endTaskX2)/2, endTaskY, endTaskX2, endTaskY, dashLength, dashGap);
						} else {
							DrawingExt.dashTo(mcConnector,startTaskX1, startTaskY, startTaskX1-this.params.connectorExtension, startTaskY, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,startTaskX1-this.params.connectorExtension, startTaskY, startTaskX1-this.params.connectorExtension, startTaskY+(endTaskY-startTaskY)/2, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,startTaskX1-this.params.connectorExtension, startTaskY+(endTaskY-startTaskY)/2, endTaskX2+this.params.connectorExtension, startTaskY+(endTaskY-startTaskY)/2, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,endTaskX2+this.params.connectorExtension, startTaskY+(endTaskY-startTaskY)/2, endTaskX2+this.params.connectorExtension, endTaskY, dashLength, dashGap);
							DrawingExt.dashTo(mcConnector,endTaskX2+this.params.connectorExtension, endTaskY, endTaskX2, endTaskY, dashLength, dashGap);
						}
						break;
					}
				}
				//Apply filters
				mcConnector.filters = this.styleCache.connectorFilters;
				//Apply animation
				if (this.params.animation){
					this.styleM.applyAnimation (mcConnector, this.objects.CONNECTORS, this.macro, null, null, 100, null, null, null);
				}
				//Increment depth
				depth++;
			}
		}
		//Clear Interval
		clearInterval(this.config.intervals.connectors);
	}
	/**
	 * drawTrend method draws the trend lines for the chart.
	*/
	private function drawTrend():Void{
		var i:Number;		
		//Depths
		var trendLineDepth:Number = this.dm.getDepth("TRENDLINES");
		var trendLabelDepth:Number = this.dm.getDepth("TRENDVALUES");
		//Iterate through all trend lines
		for (i=1; i<=this.numTrendlines; i++){
			//We draw the trend label first.
			var trendLabelHeight:Number = 0;
			if (this.trendlines[i].displayValue!=""){
				//Configure font properties and alignment
				this.styleCache.trendLabels.align = "center";
				//If the gantt scrolls, we place the label up
				this.styleCache.trendLabels.vAlign = (this.config.ganttScrolls)?"top":"bottom";
				this.styleCache.trendLabels.color = this.trendlines[i].color;
				//Render the text
				var trendLabelObj:Object = Utils.createText(false, this.trendlines[i].displayValue, this.scrollContentMC, trendLabelDepth, (this.trendlines[i].isTrendZone)?(this.trendlines[i].x + (this.trendlines[i].toX-this.trendlines[i].x)/2):(this.trendlines[i].toX), this.elements.gantt.h, 0, this.styleCache.trendLabels, false, 0, 0);
				//Store height
				trendLabelHeight = trendLabelObj.height;
				//Apply filters & animation
				trendLabelObj.tf.filters = this.styleCache.trendLabelFilters;
				//Apply animation
				if (this.params.animation){
					this.styleM.applyAnimation (trendLabelObj.tf, this.objects.TRENDVALUES, this.macro, null, null, 100, null, null, null);
				}
			}
			//Create container movie clip
			var trendMC:MovieClip = this.scrollContentMC.createEmptyMovieClip("TrendLine_"+i, trendLineDepth);
			//Draw
			if (this.trendlines[i].isTrendZone){
				//We need to set fill
				trendMC.beginFill(parseInt(this.trendlines[i].color,16), this.trendlines[i].alpha);
				//Draw the rectangle
				trendMC.moveTo(this.trendlines[i].x, this.config.categoryHeight);
				trendMC.lineTo(this.trendlines[i].toX, this.config.categoryHeight);
				trendMC.lineTo(this.trendlines[i].toX, this.elements.gantt.h-((this.config.ganttScrolls)?trendLabelHeight:0));
				trendMC.lineTo(this.trendlines[i].x, this.elements.gantt.h-((this.config.ganttScrolls)?trendLabelHeight:0));
				trendMC.lineTo(this.trendlines[i].x, this.config.categoryHeight);
			}else{
				//Simple line
				trendMC.lineStyle(this.trendlines[i].thickness, parseInt(this.trendlines[i].color,16), this.trendlines[i].alpha);
				//Whether to draw simple line or dashed line				
				if (this.trendlines[i].dashed){
					DrawingExt.dashTo(trendMC, this.trendlines[i].x, this.config.categoryHeight, this.trendlines[i].toX, this.elements.gantt.h-((this.config.ganttScrolls)?trendLabelHeight:0), this.trendlines[i].dashLen, this.trendlines[i].dashGap);
				}else{
					trendMC.moveTo(this.trendlines[i].x, this.config.categoryHeight);
					trendMC.lineTo(this.trendlines[i].toX, this.elements.gantt.h-((this.config.ganttScrolls)?trendLabelHeight:0));
				}
			}
			//Set filters
			trendMC.filters = this.styleCache.trendLineFilters;
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (trendMC, this.objects.TRENDLINES, this.macro, null, null, 100, null, null, null);
			}
			//Increase depth
			trendLineDepth++;
			trendLabelDepth++;
		}
		//Clear interval
		clearInterval(this.config.intervals.trend);
	}
	/**
	* drawLegend method renders the legend
	*/
	private function drawLegend():Void{
		if (this.params.showLegend && this.numLegendItems>0){
			this.lgnd.render ();
			//Apply filter
			this.styleM.applyFilters (lgndMC, this.objects.LEGEND);
			//Apply animation
			if (this.params.animation){
				this.styleM.applyAnimation (lgndMC, this.objects.LEGEND, this.macro, null, null, 100, null, null, null);
			}
		}
		//Clear interval
		clearInterval (this.config.intervals.legend);
	}	
	/**
	* setContextMenu method sets the context menu for the chart.
	* For this chart, the context items are "Print Chart".
	*/
	private function setContextMenu():Void {
		var chartMenu : ContextMenu = new ContextMenu();
		chartMenu.hideBuiltInItems();
		if (this.params.showPrintMenuItem){
			//Create a print chart contenxt menu item
			var printCMI : ContextMenuItem = new ContextMenuItem ("Print Chart", Delegate.create (this, printChart));
			//Push print item.
			chartMenu.customItems.push (printCMI);
		}
		//If the export data item is to be shown
		if (this.params.showExportDataMenuItem){
			chartMenu.customItems.push(super.returnExportDataMenuItem());
		}
		//Add export chart related menu items to the context menu
		this.addExportItemsToMenu(chartMenu);
		if (this.params.showFCMenuItem){
			//Push "About FusionCharts" Menu Item
			chartMenu.customItems.push(super.returnAbtMenuItem());		
		}
		//Assign the menu to cMC movie clip
		this.cMC.menu = chartMenu;
		//Clear interval
		clearInterval(this.config.intervals.contextMenu);
	}
	/**
	 * drawStar method helps draw a start of a given shape in the specified
	 * movie clip. You need to set the line-style and fill style before calling
	 * this method.
	 *	@param	mc			MovieClip in which we've to draw the star.
	 *	@param	x			X-position in the movie clip where we've to draw the star
	 *	@param	y			Y-position in the movie clip where we've to draw the star
	 *	@param	points		How many points the star will have?
	 *	@param	innerRadius	Inner-radius of the star.
	 *	@param	outerRadius	Outer-radius of the star.
	 *	@param	angle		Starting angle of the star in degrees.
	*/
	private function drawStar(mc:MovieClip, x, y, points, innerRadius, outerRadius, angle):Void {
		//We can have a star only if we've more than 2 points to cover.
		if (points>2) {
			//Variables to store calculation
			var step:Number, halfStep:Number, start:Number, n:Number, dx:Number, dy:Number;
			//Distance between points
			step = (Math.PI*2)/points;
			halfStep = step/2;
			//Convert starting angle in radians
			start = (angle/180)*Math.PI;
			mc.moveTo(x+(Math.cos(start)*outerRadius), y-(Math.sin(start)*outerRadius));
			//Draw connector lines of star
			for (n=1; n<=points; n++) {
				dx = x+Math.cos(start+(step*n)-halfStep)*innerRadius;
				dy = y-Math.sin(start+(step*n)-halfStep)*innerRadius;
				mc.lineTo(dx, dy);
				dx = x+Math.cos(start+(step*n))*outerRadius;
				dy = y-Math.sin(start+(step*n))*outerRadius;
				mc.lineTo(dx, dy);
			}
		}
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
	* activateLink is invoked when the user clicks any linked item.
	*/
	private function activateLink():Void {
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
		//Re-initialize containers
		this.categories = new Array();
		this.processes = new Array();
		this.tasks = new Array();
		this.milestones = new Array();
		this.trendlines = new Array();
		this.connectors = new Array();
		this.dataColumn = new Array();
		this.legendItems = new Array();
		//Initialize counters
		this.numCat = 0;
		this.numProcess = 0;
		this.numTasks = 0;
		this.numMilestones = 0;
		this.numTrendlines = 0;
		this.numConnectors = 0;
		this.numDataColumns = 0;
		this.numLegendItems = 0;
		//Initiate style cache
		this.styleCache = new Object();
		//Re-set legend
		this.lgnd.reset();
	}
	/**
	* remove method removes the chart by clearing the chart movie clip
	* and removing any listeners.
	*/
	public function remove():Void {
		var i:Number;
		//Remove all the grids
		this.datagrid.destroy();
		this.catExtGrid.destroy();
		for (i=1; i<=this.numCat; i++){
			this.categories[i].grid.destroy();
		}
		//Remove the scroll content movie clip
		this.scrollContentMC.removeMovieClip();
		//Remove legend
		this.lgnd.destroy();
		lgndMC.removeMovieClip();
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
		var taskPId:Number;
		strData = strQ + "Task ID" + strQ + strS + strQ + "Task" + strQ + strS + strQ + "Process ID" + strQ + strS + strQ + "Process" + strQ + strS + strQ + "Start Date" + strQ + strS + strQ + "End Date" + strQ;
		//Add the data column headers.
		for (i = 1; i <= this.numDataColumns; i++) {
			strData += strS + strQ + this.dataColumn[i].headerText + strQ;			
		}
		//Add line break
		strData += strLB;
		//Iterate through all tasks
		for (i = 1; i <= this.numTasks; i++) {
			//Append the task ID and task label to it first.
			strData += strQ + this.tasks[i].id + strQ + strS + strQ + this.tasks[i].label + strQ;
			//Get the process ID for this task
			taskPId = this.getProcessIndex(this.tasks[i].processId);
			//Append the process Id and label to it
			strData += strS + strQ + this.processes[taskPId].id + strQ + strS + strQ + this.processes[taskPId].label + strQ;
			//Append the start and end date
			strData += strS + strQ + ((this.params.exportDataFormattedVal == true)?(this.tasks[i].start):(this.tasks[i].fStartDate)) + strQ + strS + strQ + ((this.params.exportDataFormattedVal == true)?(this.tasks[i].end):(this.tasks[i].fEndDate)) + strQ;
			//Append data columns
			for (j = 1; j <= this.numDataColumns; j++) {
				strData += strS + strQ + this.dataColumn[j].cell[taskPId].label + strQ;				
			}
			//Append line break
			if (i < this.numTasks) {
				strData += strLB;
			}
		}
		return strData;
	}
}