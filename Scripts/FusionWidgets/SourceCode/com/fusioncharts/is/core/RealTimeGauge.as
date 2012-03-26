/**
* @class RealTimeGauge
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd. 2005-2006
* RealTimeGauge extends Chart class to encapsulate
* functionalities of a gauges with real time capabilities. 
* It contains the functionalities that are common to all
* real time gauges - like Message logger handling etc.
* All charts then extend this class.
*/
//Import parent class
import com.fusioncharts.is.core.Chart;
//Axis for the chart
import com.fusioncharts.is.axis.GaugeAxis;
//Utility functions
import com.fusioncharts.is.helper.Utils;
//Logger
import com.fusioncharts.is.helper.Logger;
//Message Handler
import com.fusioncharts.is.realtime.MessageHandler;
//Alert Manager
import com.fusioncharts.is.realtime.AlertManager;
//Color Manager
import com.fusioncharts.is.colormanagers.GaugeColorManager;
//Object Manager
import com.fusioncharts.is.helper.ObjectManager;
//Number formatting
import com.fusioncharts.is.helper.NumberFormatting;
//Extensions
import com.fusioncharts.is.extensions.MathExt;
import com.fusioncharts.is.extensions.ColorExt;
//Delegate
import mx.utils.Delegate;
class com.fusioncharts.is.core.RealTimeGauge extends Chart {
	//Reference to primary axis of the chart
	private var pAxis:GaugeAxis;
	//Number formatting class for this axis
	private var nf:NumberFormatting;
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
	public var colorM:GaugeColorManager;
	//Objects and flags to load and store real-time data.
	private var lv:LoadVars;
	//Flag to indicate whether a loading process is active
	private var inLoadingProcess:Boolean;	
	//Flag whether the chart is currently in self-updating mode
	private var isUpdating:Boolean;
	//Interval Ids for update and refresh
	private var rIntervalId:Number;
	//Cache for styles
	private var styleCache:Object;
	//Major and minor tick marks
	private var majorTM:Array;
	private var minorTM:Array;
	//Container to hold defined Color ranges
	private var colorR:Array;
	//Number of defined color range
	private var numCR:Number;	
	//Scale factor for the chart
	private var scaleFactor:Number;
	/**
	* Constructor function. We invoke the super class'  constructor.
	* And also initialize local instance properties.
	*/
	function RealTimeGauge(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String) {
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
		//Set flag that it's not currently updating itself
		this.isUpdating = false;
		//Initiate style cache
		this.styleCache = new Object();
		//Color Range containers
		this.colorR = new Array();
		this.numCR = 0;
		//Initialize scale factor
		this.scaleFactor = 1;
	}
	/**
	 * returnDataAsColorRange method returns an object encapsulating all the
	 * properties of a Color Range object.
	 *	@param 	minValue		Minimum value for this color range
	 *	@param 	maxValue		Maximum value for this color range
	 * 	@param 	label			Label for this color range
	 * 	@param 	color			Color for this color range
	 * 	@param 	alpha			Alpha for this range
	 *	@param 	borderColor		Border Color for the range
	 *	@param 	borderAlpha		Border Alpha for the range
	*/
	private function returnDataAsColorRange(minValue:Number, maxValue:Number, label:String, color:String, alpha:String, borderColor:String, borderAlpha:Number):Object{
		//Create an obejct to represent it
		var objCR:Object = new Object();		
		//Store
		objCR.minValue = minValue;
		objCR.maxValue = maxValue;
		objCR.label = label;
		objCR.color = color;
		objCR.alpha = alpha;
		objCR.borderColor = borderColor;
		objCR.borderAlpha = borderAlpha;
		//Internal properties for angular gauge
		objCR.startAngle = 0;
		objCR.endAngle = 0;
		//Internal properties for other charts
		objCR.fromX = 0;
		objCR.fromY = 0;
		objCR.toX = 0;
		objCR.toY = 0;
		//Return it
		return objCR;
	}
	/**
	 * parseColorRange method parses the color ranges for the gauge.
	 *	@param	arrColorRange	Array of color range nodes.
	*/
	private function parseColorRange(arrColorRange:Array):Void{
		//Loop variable
		var i:Number;
		//Local variables to store property
		var minValue:Number, maxValue:Number, label:String, code:String, alpha:String, borderColor:String, borderAlpha:Number;
		//Previous range's min value
		var prevMinValue:Number = 0;
		//Iterate and find color range nodes
		for (i=0; i<arrColorRange.length; i++){
			//If it's a COLOR node
			if (arrColorRange[i].nodeName.toUpperCase()=="COLOR"){
				//Increment
				this.numCR++;
				//Get atts
				var atts:Array = Utils.getAttributesArray(arrColorRange[i]);
				//Extract attributes
				minValue = getFN(atts["minvalue"], prevMinValue);
				maxValue = getFN(atts["maxvalue"], minValue);
				label = getFV(atts["label"], atts["name"], "");
				code = formatColor(getFV(atts["code"], this.colorM.getColor()));				
				alpha = getFV(atts["alpha"], "100");
				borderColor = formatColor(getFV(atts["bordercolor"], this.params.gaugeBorderColor));
				borderAlpha = getFN(atts["borderalpha"], this.params.gaugeBorderAlpha);
				this.colorR[this.numCR] = returnDataAsColorRange(minValue, maxValue, label, code, alpha, borderColor, borderAlpha);
				//We take the maximum value of this color range to the default minimum of the next one
				prevMinValue = maxValue;
			}
		}
	}
	/**
	 * validateColorRange method valides all the color ranges so as to form
	 * proper sequence.
	*/
	private function validateColorRange():Void{
		if (this.numCR>0){
			//First color range's minValue should be equal to lowerLimit
			this.colorR[1].minValue = this.pAxis.getMin();
			//Forced upper limit scaling for the last color range 
			//as the last color range's upper value has to be equal to upperLimit
			this.colorR[this.numCR].maxValue = this.pAxis.getMax();
			//For all the values in between, the minValue and maxValue should 
			//lie between the upper and lower limit
			var i:Number;
			for (i=1; i<=this.numCR; i++) {
				//Fill all missing values with extremities
				if (this.colorR[i].maxValue>this.pAxis.getMax()) {
					this.colorR[i].maxValue = this.pAxis.getMax();
				}
				if (this.colorR[i].maxValue<this.pAxis.getMin()) {
					this.colorR[i].maxValue = this.pAxis.getMin();
				}
				if (this.colorR[i].minValue<this.pAxis.getMin()) {
					this.colorR[i].minValue = this.pAxis.getMin();
				}
				if (this.colorR[i].minValue>this.pAxis.getMax()) {
					this.colorR[i].minValue = this.pAxis.getMax();
				}
			}
			//Create the sequence - serialize
			for (i=1; i<this.numCR; i++) {
				//If max value of present is equal to upper limit, but minValue of next is greater than min value of present, set max to min of next
				if ((this.colorR[i].maxValue>=this.pAxis.getMax()) && (this.colorR[i+1].minValue>this.colorR[i].minValue)) {
					this.colorR[i].maxValue = this.colorR[i+1].minValue;
				}
				//If max value of current is greater than min value of next, set min value of next to max value of current
				if (this.colorR[i].maxValue>this.colorR[i+1].minValue) {
					this.colorR[i+1].minValue = this.colorR[i].maxValue;
				}
				//If max value of current is less than min value of next, set max value of current to min value of next
				if (this.colorR[i].maxValue<this.colorR[i+1].minValue) {
					this.colorR[i].maxValue = this.colorR[i+1].minValue;
				}
			}
		}
	}
	/**
	 * calculateScaleFactor method calculates the scaling required for the chart	 
	 * required for dynamic scaling from original width and height
	*/
	private function calculateScaleFactor():Void{
		//We do so, only if we've to auto scale the gauge
		if (this.params.autoScale){
			//Now, if the ratio of original width,height & stage width,height are same
			if ((this.params.origW / this.width) == (this.params.origH / this.height)){
				//In this case, the transformation value would be the same, as the ratio
				//of transformation of width and height is same.
				this.scaleFactor = this.width/this.params.origW;
			}else{
				//If the transformation factors are different, we do a constrained scaling
				//We get the aspect whose delta is on the lower side.
				this.scaleFactor = Math.min((this.width/this.params.origW),(this.height/this.params.origH));
			}
		}else{
			//Set to 1.
			this.scaleFactor = 1;
		}	
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
			this.msgLgr = new MessageHandler(this.msgLogMC, this.width, this.height, this.registerWithJS);
			this.msgLgr.setParams(this.params.messageLogWPercent, this.params.messageLogHPercent, this.params.messageLogShowTitle, this.params.messageLogTitle, this.params.messageLogColor, this.params.messageGoesToLog, this.params.messageGoesToJS, this.params.messageJSHandler, this.params.messagePassAllToJS);
		}
	}
	/**
	 * setupColorManager method sets up the color manager for the chart.
	  *	@param	paletteId	Palette Id for the chart.
	 *	@param	themeColor	Color code if the chart uses single color theme.
	*/
	private function setupColorManager(paletteId:Number, themeColor:String):Void{
		this.colorM = new GaugeColorManager(paletteId,themeColor);
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
		//Clear interval - to avoid recursive calls to this function
		clearInterval(this.config.intervals.renderedFlag);
	}	
	// ------------ REAL TIME UPDATE/REFRESH HANDLERS ----------//
	/**
	 * setRefreshInterval method is called to set the refresh cycle
	 * interval for the chart. 
	*/
	private function setRefreshInterval():Void{
		if (this.params.dataStreamURL!="" && this.params.refreshInterval>0){
			//Initialize LoadVars object
			this.lv = new LoadVars();		
			//Set flag that the chart is in self-updating mode
			this.isUpdating = true;
			//Reference to class
			var classRef = this;			
			//Define the events for LoadVars object - we define it only once.
			this.lv.onHTTPStatus = function(httpStatus:Number){
				//Just store the HTTP status in self
				this.httpStatus = httpStatus;				
			}
			this.lv.onLoad = function(success:Boolean){
				if (success){
					//We've successfully loaded data stream. So, carry on with parsing.
					classRef.parseDataFromLV();
				}else{
					//An error has occurred while loading the data. So, take action.
					classRef.handleLoadError();					
				}
			}
			//Set the interval call
			this.rIntervalId = setInterval(Delegate.create(this,fetchData),this.params.refreshInterval*1000);
			//Log info			
			this.log("data Stream URL provided", "<A HREF='"+this.params.dataStreamURL+"' target='_blank'>"+this.params.dataStreamURL+"</A>", Logger.LEVEL.LINK);			
			this.log("INFO","Setting the chart to update itself in " + this.params.refreshInterval + " seconds.", Logger.LEVEL.INFO);
		}
		//Clear time interval - so that this method is called only once
		clearInterval(this.config.intervals.refreshInterval);
	}
	/**
	 * fetchData method is invoked by setRefreshInterval method every refreshInterval
	 * second to send command for data stream feed load.
	*/
	private function fetchData():Void{
		//This method actually loads the data at the specified interval
		//We fetch data only if a previous LoadVars has complete, else we ignore
		//the call.
		if (!this.inLoadingProcess){
			//Update flag that we're now beginning the loading process
			this.inLoadingProcess = true;
			//Prepare the URL by adding the datastamp and timestamp (to avoid caching).
			var strURL = this.params.dataStreamURL + ((this.params.streamURLQMarkPresent)?("&FCTimeIndex="+getTimer()+"_"+Math.random()+"&dataStamp="+this.params.dataStamp):("?FCTimeIndex="+getTimer()+"_"+Math.random()+"&dataStamp="+this.params.dataStamp));
			//Invoke the URL to load data.
			this.lv.load(strURL);			
		} else {
			//We ignore overlapping calls to prevent memory leaks and/or browser crashes.
			//Can log messages here.
		}
	}
	/**
	 * stopUpdate method stops the automatic update of the chart.
 	 * Make this function public, so that if the real time chart is loaded inside other 
	 * Flash movies too, it can be stopped using this API.
	*/
	public function stopUpdate():Void{
		//We stop update only if the chart is in update mode
		if (this.isUpdating){
			//Log the event.
			this.log("Stopping Update","Forcing chart to stop update. The chart would not self-update any more.",Logger.LEVEL.INFO);
			//Clear the interval.
			clearInterval(this.rIntervalId);
			//Set the flag that chart is not updating anymore
			this.isUpdating = false;
			//Re-set flags
			this.inLoadingProcess = false;
			//Delete the cache of Loadvars
			this.deleteLoadVarsCache();		
			//Delete loadVars events too
			delete this.lv.onHTTPStatus;
			delete this.lv.onLoad;
			//And finally delete the loadvars object itself
			delete this.lv;
			//Re-set context menu item
			this.setContextMenu();
		}
	}
	/**
	 * restartUpdate method restarts the update of the chart, after stopping it.
	 * Make this function public, so that if the real time chart is loaded inside other 
	 * Flash movies too, it can be restarted using this API.
	*/
	public function restartUpdate():Void{
		//We restart update, only if the update is stopped.
		if (!this.isUpdating){
			//Log a message, that the chart is set to restart
			this.log("Restarting Update","Restarting self update of the chart.",Logger.LEVEL.INFO);			
			//Re-set the interval
			this.setRefreshInterval();			
		}
		//Re-set context menu item
		this.setContextMenu();
	}
	/**
	 * parseMultipleData data parses real time data feed containing 
	 * multiple data or values.
	*/
	private function parseMultipleData(str:String):Array{
		//Loop variable
		var i:Number;
		//Split on | to separate out the data.
		var ar:Array = str.split("|");
		//Return the array.
		return ar;
	}
	/**
	 * deleteLoadVarsCache method deletes the data present in loadvars
	 * cache. This is to avoid pulling old data. We do NOT delete lv and re-initialize, 
	 * as that deletes the events too and also un-optimizes.
	*/
	private function deleteLoadVarsCache():Void{
		if (this.lv!=undefined){
			var item;
			for (item in this.lv){
				//If it's not onLoad on onHTTPStatus handler, delete it
				if (item!="onLoad" && item!="onHTTPStatus" && item!="onData"){
					//Delete it from loadvars
					delete this.lv[item];
				}
			}
		}
	}
	/**
	* handleLoadError method is called when an error occurred during loading data.
	*/
	private function handleLoadError():Void{
		//We first log the error in debug
		this.log("Error in loading stream data","The chart couldn't load data from the specified data stream URL. Error HTTP Status returned was: " + this.lv.httpStatus + ". Please make sure that your data stream provider page is present in the same sub-domain as the chart.", Logger.LEVEL.ERROR);
		//Update in-loading process, so that next stream can load
		this.inLoadingProcess = false; 
		//Now, individually deal with known error codes.		
		//Note that individual errors codes are not supplied to the chart by browsers
		//like Mozilla, Netscape, Opera etc. As such, those browsers will simply return 
		//a 0 value.
		if (this.lv.httpStatus==404) {
			//If status is 404, we set loadingProcess to true, as it makes no point
			//to make recusive calls to the same stream URL, when it's a 404 status			
			this.inLoadingProcess = true; 
			//Also, we can stop the chart from self updating here.
			this.stopUpdate();
			//Log the error
			this.log("Data Stream URL Not Found","The specified data stream URL doesn't exist. Stopping any further calls to the data stream URL.", Logger.LEVEL.ERROR);
		}
	}
	/**
	 * feedData accepts data as a string from the external interface and passes
	 * to chart for parsing. Make this function public, so that if the real time
	 * chart is loaded inside other Flash movies too, it can be updated using this
	 * API.
	 *	@param	dataStream	Querystring containing the data that is to be conveyed to chart.
	 *	@return				Nothing.
	*/
	public function feedData(dataStream:String):Void{
		//Parse the data in Loadvars object if stream is not null/undefined
		if (dataStream!="" && dataStream!=undefined && dataStream.length>1){
			//We first need to check if LoadVars is active- because any previous
			//stopUpdate calls could have nullified LoadVars. So, if it's undefined
			//we need to re-define the same.
			if (this.lv==undefined){
				this.lv = new LoadVars();
			}
			this.lv.decode(dataStream);
			//Now, parse the data into local objects and render chart.
			this.parseDataFromLV();
		}
	}	
	// --------------------- FORWARD DECLARATIONS ------------------------//	
	public function parseDataFromLV():Void{
	}
	// -------------------------------------------------------------------//
	/**
	* setContextMenu method sets the context menu for the chart.
	* For this chart, the context items are "Print Chart".
	*/
	private function setContextMenu():Void {
		var chartMenu : ContextMenu = new ContextMenu();
		chartMenu.hideBuiltInItems();
		//If we've to create the real-time items
		if (this.params.showRTMenuItem && this.params.chartRendered && (this.params.refreshInterval!=-1) && (this.params.dataStreamURL!="")){
			if (this.isUpdating){
				//Stop Update menu item
				var updateCMI:ContextMenuItem = new ContextMenuItem ("Stop Update", Delegate.create (this, stopUpdate));
			}else{
				//Create restart update
				var updateCMI:ContextMenuItem = new ContextMenuItem ("Start Update", Delegate.create (this, restartUpdate));
			}			
			chartMenu.customItems.push (updateCMI);
		}		
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
		if (this.params.chartRendered){
			clearInterval(this.config.intervals.contextMenu);
		}
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
		this.isUpdating = false;
		//Initiate style cache
		this.styleCache = new Object();
		//Set scale factor back to 1
		this.scaleFactor = 1;
		//Defaults for color range
		this.colorR = new Array();
		this.numCR = 0;
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
		clearInterval(this.rIntervalId);
		//Delete LoadVars & events
		delete this.lv.onData;
		delete this.lv.onLoad;
 		delete this.lv;
		//Bubble the call up 
		super.remove();
	}
}
