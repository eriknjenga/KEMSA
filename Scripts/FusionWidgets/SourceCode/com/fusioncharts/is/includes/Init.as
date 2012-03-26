/** --- Init.as ---
* Copyright InfoSoft Global Private Ltd. and its licensors.  All Rights Reserved.
*
* Use and/or redistribution of this file, in whole or in part, is subject
* to the License Files, which was distributed with this component.
*
* Chart Initialization functions
* This file contains functions and constant definitions only, and is not
* associated with a class/movie clip.
*/
//Get all the attributes specified to chart as an array.
//This is done to get it in case-insensitive form.
var rootAttr:Array = getAttributesArray(_root);
//Set the chart's scale mode and align position
var _scaleMode:String = getFirstValue(rootAttr["scalemode"], "noScale");
//Loading mode of chart
var _loadMode:String  = getFirstValue(rootAttr["mode"], "");
_loadMode = _loadMode.toLowerCase();

if (!(_loadMode=="flex" || _loadMode=="laszlo")){
	//If we're not loading the SWF for Laszlo or Flex mode, set the scaling 
	//and alignment of movie
	//Set the scale mode of stage
	Stage.scaleMode = _scaleMode;
	//Set align to Top-left
	Stage.align = "TL";
}
/*
* To include or load  XML data files that are not Unicode-encoded,
* we set system.useCodepage to true. The Flash Player will now interpret
* the XML file using the traditional code page of the operating system
* running the Flash Player. This is generally CP1252 for an English
* Windows operating system and Shift-JIS for a Japanese operating system.
*/
System.useCodepage = true;
/*
* _isOnline represents whether the chart is working in Local or online mode.
* If it's local mode, FusionCharts would cache the data, else it would apply
* methods to always received updated data from the defined source
*/
var _isOnline:Boolean = (this._url.subStr(0, 7) == "http://") || (this._url.subStr(0, 8) == "https://");
//Get chart width and height
var _chartWidth:Number = Stage.width;
var _chartHeight:Number = Stage.height;
//If chart width and chart height have registered as 0, we update to Flashvars value
if (_loadMode=="flex" || _loadMode=="laszlo" || _chartWidth == 0 || _chartHeight == 0) {
	//Also, if we're loading for Flex/Laszlo, we just set the width/height provided.
	_chartWidth = Number(rootAttr["chartwidth"]);
	_chartHeight = Number(rootAttr["chartheight"]);
}
//Get chart horizontal and vertical center 
var _chartXCenter:Number = _chartWidth/2;
var _chartYCenter:Number = _chartHeight/2;
/**
* _lang sets the language in which we've to display application
* message
*/
var _lang:String = getFirstValue(rootAttr["lang"], "EN");
//Convert to upper case
_lang = _lang.toUpperCase();
/**
* _debugMode sets whether the chart is operating in debug
* mode or end-user mode. In debug mode, we show the debugger
* to the developer.
*/
var _debugMode:Number = Number(getFirstValue(rootAttr["debugmode"], 0));
/**
* _DOMId represents the DOM Id of the chart. DOM id is the id of
* the chart in HTML container.
*/
var _DOMId:String = rootAttr["domid"];
/**
* _registerWithJS indicates whether this movie will register with JavaScript
* contained in the container HTML page. If yes, the movie will convey
* events to JavaScript functions present in the page.
*/
var _registerWithJS:Boolean = (Number(getFirstValue(rootAttr["registerwithjs"], 0)) == 1) ? true : false;
/**
* defaultDataFile represents the XML data file URI which would
* be loaded if no other URI or XML data has been provided to us.
*/
var _defaultDataFile:String = unescape(getFirstValue(rootAttr["defaultdatafile"], "Data.xml"));
/**
* _isSafeDataURL flag keeps a track of whether the user has provided a safe dataURL.
* If not, we do not add that to debug Mode.
*/
var _isSafeDataURL:Boolean = true;

