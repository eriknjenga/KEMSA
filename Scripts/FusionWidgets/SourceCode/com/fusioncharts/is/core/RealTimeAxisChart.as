/**
* @class RealTimeAxisChart
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd. 2005-2006
* RealTimeAxisChart extends Chart class to encapsulate
* functionalities of a chart with real time capabilities. 
* It contains the functionalities that are common to all
* real time charts with axis - like Message logger handling etc.
* All charts then extend this class.
*/
//Import parent class
import com.fusioncharts.is.core.Chart;
//Message Handler
import com.fusioncharts.is.realtime.MessageHandler;
//Alert Manager
import com.fusioncharts.is.realtime.AlertManager;
//Color Manager
import com.fusioncharts.is.colormanagers.AxisChartColorManager;
//Object Manager
import com.fusioncharts.is.helper.ObjectManager;
//Extensions
import com.fusioncharts.is.extensions.MathExt;
import com.fusioncharts.is.extensions.ColorExt;
class com.fusioncharts.is.core.RealTimeAxisChart extends Chart {
	//Movie clip reference for message log MC. The message logger 
	//is contained as a part of this movie clip. Even if the
	//user has not requested to show message log, we create the
	//parent message log movie clip.
	private var msgLogMC:MovieClip;
	//Reference to message logger class instane
	private var msgLgr:MessageHandler;
	//Reference to alert manager for this chart.
	private var alertM:AlertManager;
	//Flag to check whether alert manager is used for this chart
	private var useAlerts:Boolean;
	//Reference to object maanger
	private var objM:ObjectManager;
	//Color Manager for the charts
	public var colorM:AxisChartColorManager;
	//Objects and flags to load and store real-time data.
	private var lv:LoadVars;
	//Flag to indicate whether a loading process is active
	private var inLoadingProcess:Boolean;
	//Flag to indicate whether the data fetch updated chart's data
	private var chartDataChanged:Boolean;
	//Flag whether the chart is currently in self-updating mode
	private var isUpdating:Boolean;
	//Interval Ids for update and refresh
	private var uIntervalId:Number;
	private var rIntervalId:Number;
	//Interval id for clearing chart
	private var cIntervalId:Number;
	//Cache for styles
	private var styleCache:Object;
	/**
	* Constructor function. We invoke the super class'  constructor.
	* And also initialize local instance properties.
	*/
	function RealTimeAxisChart(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
		//Invoke the super class constructor
		super(targetMC, depth, width, height, x, y, debugMode, registerWithJS, DOMId, lang);
		//Set default false flag for alert manager
		this.useAlerts = false;
		//Initialize object manager
		this.objM = new ObjectManager();
		//Set the flag initially that the chart has not yet started rendering
		this.params.chartRendered = false;
		//Setup the real-time objects		
		this.inLoadingProcess = false;
		this.chartDataChanged = false;
		//Set flag that it's not currently updating itself
		this.isUpdating = false;
		//Initiate style cache
		this.styleCache = new Object();
	}
	/**
	 * setupMessageLog method sets up the message log handler.
	*/
	private function setupMessageLog():Void {
		//If the message log needs to be set up
		if (this.params.useMessageLog) {
			//Create the movie clip holder for message log
			this.msgLogMC = this.parentMC.createEmptyMovieClip("MsgLog", this.depth+2);
			//Re-position the message log Movie clip to required x and y position
			this.msgLogMC._x = this.x;
			this.msgLogMC._y = this.y;
			//Instantiate message handler
			this.msgLgr = new MessageHandler(this.msgLogMC, this.width, this.height, registerWithJS);
			this.msgLgr.setParams(this.params.messageLogWPercent, this.params.messageLogHPercent, this.params.messageLogShowTitle, this.params.messageLogTitle, this.params.messageLogColor, this.params.messageGoesToLog, this.params.messageGoesToJS, this.params.messageJSHandler, this.params.messagePassAllToJS);
		}
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
	 * setupAlertManager method sets the alert manager for this chart
 	 *	@param	alertsNode	<Alerts> node and it's child nodes.
	*/
	private function setupAlertManager(alertsNode:XMLNode):Void{
		//Update the alert flag to use alert manager
		this.useAlerts = true;
		//Create alert manager - we feed MC later
		this.alertM = new AlertManager(this, this.am);
		//Feed the XML data 
		this.alertM.parseXML(alertsNode);
	}
	/**
	* setupAlertManagerMC method sets the container for alert manager.
	*/
	private function setupAlertManagerMC():Void{
		//Create a new movie clip in the allotted depth.
		var alertMC:MovieClip = this.cMC.createEmptyMovieClip("AlertManagerHolder",this.dm.getDepth("ALERTMANAGER"));
		//Convey it to alert manager class
		this.alertM.setContainerMC(alertMC);
	}
	/**
	 * updateRenderedFlag method updates the flag that the chart has been rendered
	 * once and as such shouldn't animate for the second time.
	*/
	private function updateRenderedFlag():Void{
		//Update that the chart has renderd.
		this.params.chartRendered = true;
		//Set animation to false, as we do not want to re-animate during self updation
		this.params.animation = false;
		//Clear interval - to avoid recursive calls to this function
		clearInterval(this.config.intervals.renderedFlag);
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
		//Canvas dimension macros
		this.macro.addMacro ("$canvasStartX", this.elements.canvas.x);
		this.macro.addMacro ("$canvasStartY", this.elements.canvas.y);
		this.macro.addMacro ("$canvasWidth", this.elements.canvas.w);
		this.macro.addMacro ("$canvasHeight", this.elements.canvas.h);
		this.macro.addMacro ("$canvasEndX", this.elements.canvas.toX);
		this.macro.addMacro ("$canvasEndY", this.elements.canvas.toY);
		this.macro.addMacro ("$canvasCenterX", this.elements.canvas.x + (this.elements.canvas.w / 2));
		this.macro.addMacro ("$canvasCenterY", this.elements.canvas.y + (this.elements.canvas.h / 2));
	}
	// ------------ VISUAL RENDERING METHODS -------------//
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
		clearInterval (this.config.intervals.canvas);
	}
	/**
	* reInit method re-initializes the chart. 
	*/
	public function reInit():Void{
		//Bubble up
		super.reInit();	
		//Set default false flag for alert manager
		this.useAlerts = false;
		//Re-initialize object manager
		this.objM.reset();
		//Setup the real-time objects
		this.inLoadingProcess = false;
		this.chartDataChanged = false;
		this.isUpdating = false;
		//Initiate style cache
		this.styleCache = new Object();
		//We're not re-intializing message logger or color Manager, as they're not
		//setup in constructor. Instead, setup methods are being called to set them up
		//from render() function of the chart. So, when the chart is changed, the setup
		//methods will be automatically called again.
	}
	/**
	* remove method removes the chart by clearing the chart movie clip
	* and removing any listeners. 
	*/
	public function remove():Void {
		//If the message log was set up, remove the same.
		if (this.params.useMessageLog) {
			//Destroy message logger (if it was instantiated)
			this.msgLgr.destroy();
			//Remove the associated message logger movie clip
			this.msgLogMC.removeMovieClip();
		}
		//If alert manager was set up, we need to destroy
		if (this.useAlerts){
			this.alertM.destroy();
		}
		//Clear existing real-time intervals
		clearInterval(this.uIntervalId);
		clearInterval(this.rIntervalId);
		clearInterval(this.cIntervalId)
		//Delete LoadVars & events
		delete this.lv.onData;
		delete this.lv.onLoad;
 		delete this.lv;
		//Bubble the call up 
		super.remove();
	}	
}
