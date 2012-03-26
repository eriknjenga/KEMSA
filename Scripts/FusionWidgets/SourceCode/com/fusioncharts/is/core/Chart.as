 /**
* @class Chart
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.1
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* Chart class is the super class for a FusionCharts chart from
* which individual chart classes inherit. The chart class is
* responsible for a lot of features inherited by child classes.
* Chart class also bunches code that is used by all other charts
* so as to avoid code duplication.
*/
//Utilities
import com.fusioncharts.is.helper.Utils;
//Log class
import com.fusioncharts.is.helper.Logger;
//Enumeration class
import com.fusioncharts.is.helper.FCEnum;
//String extension
import com.fusioncharts.is.extensions.StringExt;
//Color Extension
import com.fusioncharts.is.extensions.ColorExt;
//Math Extension
import com.fusioncharts.is.extensions.MathExt;
//Drawing Extension
import com.fusioncharts.is.extensions.DrawingExt;
//Custom Error Object
import com.fusioncharts.is.helper.FCError;
//Tool Tip
import com.fusioncharts.is.helper.ToolTip;
//Style Managers
import com.fusioncharts.is.core.StyleObject;
import com.fusioncharts.is.core.StyleManager;
//Anotation Mananger
import com.fusioncharts.is.helper.AnnotationManager;
//Macro Class
import com.fusioncharts.is.helper.Macros;
//Depth Manager
import com.fusioncharts.is.helper.DepthManager;
//Class to help as saving as image
import com.fusioncharts.is.helper.BitmapSave;
import com.fusioncharts.is.helper.FCProgressBar;
//Delegate
import mx.utils.Delegate;
//Event Dispatcher
import mx.events.EventDispatcher;
//External Interface - to expose methods via JavaScript
import flash.external.ExternalInterface;
//Drop-shadow filter
import flash.filters.DropShadowFilter;
//Class Definition
class com.fusioncharts.is.core.Chart{
	//Instance properties
	//Version
	private var _version:String = "3.1.1";
	//XML data object for the chart.
	private var xmlData:XML;
	//Array and Enumeration listing charts objects
	//arrObjects array would store the list of chart
	//objects as string. The motive is to retrieve this
	//string information to be added to log.
	public var arrObjects:Array;
	//Object Enumeration stores the above array elements
	//(chart objects) as enumeration, so that we can refer
	//to each chart element as a numeric value.
	public var objects:FCEnum;
	//Object to store chart elements
	private var elements:Object;
	//Object to store chart parameters
	//All attributes retrieved from XML will be stored in
	//params object.
	private var params:Object;
	//Object to store chart configuration
	//Any calculation done by our code will be stored in
	//config object. Or, if we over-ride any param values
	//we store in config.
	private var config:Object;
	//DepthManager instance. The DepthManager class helps us
	//allot and retrieve depths of various objects in the chart.
	private var dm:DepthManager;
	//Movie clip in which the entire chart will be built.
	//If chart is not being loaded into another Flash movie,
	//parentMC is set as _root (as we need only 1 chart per
	//movie timeline).
	private var parentMC:MovieClip;
	//Movie clip reference for actual chart MC
	//All chart objects (movie clips) would be rendered as
	//sub-movie clips of this movie clip.
	private var cMC:MovieClip;	
	//Movie clip reference for log MC. The logger elements
	//are contained as a part of this movie clip. Even if the
	//movie is not in debug mode, we create at least the
	//parent log movie clip.
	private var logMC:MovieClip;
	//Movie clip reference for tool tip. We created a separate
	//tool tip movie clip because of two reasons. One, tool tip
	//always appears above the chart. So, we've created tool tip
	//movie clip at a depth greater than that of cMC(chart movie
	//clip). Secondly, the tool tip is not an integral part of
	//chart - it's a helper class.
	private var ttMC:MovieClip;
	//Movie clip reference to hold any overlay logo for the chart.
	private var logoMC : MovieClip;
	//Movie clip loader for the logo.
	private var logoMCLoader:MovieClipLoader;
	//Listener object for the logo MC
	private var logoMCListener : Object;
	//Tool Tip Object. This object is common to all charts.
	//Whenever we need to show/hide tool tips, we called methods
	//of this class.
	private var tTip:ToolTip;
	//Movie clip reference for text box which will be used to determine
	//text width, height for various text fields. During calculation
	//of points (width/height) for chart, we need to simulate various
	//text fields so that we come to know their exact width/height.
	//Based on that, we accomodate other elements on chart. This
	//movie clip is the container for that test text field movie clip.
	//This text field never shows on the chart canvas.
	private var tfTestMC:MovieClip;
	//Co-ordinates for generating test TF
	//We put it outside stage so that it is never visible.
	private var testTFX:Number = - 2000;
	private var testTFY:Number = - 2000;
	//Embedded Font
	//Denotes which font is embedded as a part of the chart. If you're
	//loading the chart in your movie, you need to embed the same font
	//face (plain - not bold - not italics) in your movie, to enable
	//rotated labels. Else, the rotated labels won't show up at all.
	//[Deprecated] - As we not longer used embedded fonts. Instead,
	//bitmapdata is used.
	private var _embeddedFont:String = "Verdana";
	//Reference to logger class instance.
	private var lgr;
	//Depth in parent movie clip in which we've to create chart
	//This is useful when you are loading this chart class as a part
	//of your Flash movie, as then you can create various charts at
	//various depths of a single movie clip. In case of single chart
	//(non-load), this is set to 3 (as 1 and 2 are reserved for global
	//progress bar and global application text).
	private var depth:Number;
	//Width & Height of chart in pixels. If the chart is in exactFit
	//mode, the width and height remains the same as that of original
	//document (.fla). However, everything is scaled in proportion.
	//In case of noScale, these variables assume the width and height
	//provided either by chart constructor (when loading chart in your
	//flash movie) or HTML page.
	private var width:Number, height:Number;
	//X and Y Position of top left of chart. When loading the chart in
	//your flash movie, you might want to shift the chart to particular
	//position. These x and y denote that shift.
	private var x:Number, y:Number;
	//Debug mode - Flag whether the chart is in debug mode. It's passed
	//from the HTML page as OBJECT/EMBED variable debugMode=1/0.
	private var debugMode:Boolean;
	//Counter to store timeElapsed. The chart animates sequentially.
	//e.g., the background comes first, then canvas, then div lines.
	//So, we internally need to keep a track of time passed, so that
	//we can call next what to render.
	private var timeElapsed:Number = 0;
	//Language for application messages. By default, we show application
	//messages in English. However, if you need to define your application
	//messages, you can do so in com\fusioncharts\includes\AppMessages.as
	//This value is passed from HTML page as OBJECT/EMBED variable.
	private var lang:String;
	//Scale mode - noScale or exactFit.
	//This value is passed from HTML page as OBJECT/EMBED variable.
	private var scaleMode:String;
	//Is Online Mode. If the chart is working online, we avoid caching
	//of data. Else, we cache data.
	private var isOnline:Boolean;
	//Style Manager object. The style manager object handles the style
	//quotient (FONT, BLUR, BEVEL, GLOW, SHADOW, ANIMATION) of different
	//elements of chart.
	private var styleM:StyleManager;
	//Reference to annotation Manager for this chart
	private var am:AnnotationManager;
	//Macros container. Macros help the user define pre-defined dynamic
	//values in XML for setting animation position.
	private var macro:Macros;	
	//Store a short name reference for Utils.getFirstValue function
	//and Utils.getFirstNumber function
	//As we'll be using this function a lot.
	private var getFV:Function;
	private var getFN:Function;
	private var toBoolean:Function;
	//Short name for ColorExt.formatHexColor function
	private var formatColor:Function;
	//Short name for Utils.createText function
	private var createText:Function;
	//Error handler. We've a custom error object to represent
	//any chart error. All such errors get logged and none are visible
	//to end user, to make their experience smooth.
	var e:FCError;
	//Whether to register chart with JS
	private var registerWithJS:Boolean;
	//Flag to indicate whether the chart capture process is on
	private var exportCaptureProcessOn:Boolean = false;	
	//DOM Id
	private var DOMId:String;
	//Flag to indicate whether we've conveyed the chart rendering event
	//to JavaScript and loader Flash
	private var renderEventConveyed:Boolean = false;
	//Flag to indicate whether the chat has finished rendering.
	private var chartRendered:Boolean = false;
	//Text field to hold application messages.
	private var tfAppMsg:TextField;
	//Global object references pertaining to export chart dialog box
	//The movie clip encompassing dialog box
	private var exportDialogMC:MovieClip;
	//The text field showing progress
	private var exportDialogTF:TextField;
	//The progree bar showing progress
	private var exportDialogPB:FCProgressBar;
	/**
	* Constructor method for chart. Here, we store the
	* properties of the chart from constructor parameters
	* in instance variables.
	* @param	targetMC		Parent movie clip reference in which
	*							we'll create chart movie clips
	* @param	depth			Depth inside parent movie clip in which
	*							we'll create chart movie clips
	* @param	width			Width of chart
	* @param	height			Height of chart
	* @param	x				x Position of chart
	* @param	y				y Position of chart
	* @param	debugMode		Boolean value indicating whether the chart
	*							is in debug mode.
	* @param	registerWithJS	Whether to register the chart with JavaScript.
	* @param	DOMId			DOM Id of the chart.
	* @param	lang			2 Letter ISO code for the language of application
	*							messages
	* @param	scaleMode		Scale mode of the movie - noScale or exactFit
	*/
	function Chart(targetMC:MovieClip, depth:Number, width:Number, height:Number, x:Number, y:Number, debugMode:Boolean, registerWithJS:Boolean, DOMId:String, lang:String, scaleMode:String){
		//Get the reference to Utils.getFirstValue
		this.getFV = Utils.getFirstValue;
		//Get the reference to getFirstNumber
		this.getFN = Utils.getFirstNumber;
		//Get reference to toBoolean function
		this.toBoolean = Utils.toBoolean;
		//Get reference to ColorExt.formatHexColor
		this.formatColor = ColorExt.formatHexColor;
		//Get reference to Utils.createText
		this.createText = Utils.createText;
		//Store properties in instance variables
		this.parentMC = targetMC;
		this.depth = depth;
		this.width = width;
		this.height = height;
		this.x = getFN (x, 0);
		this.y = getFN (y, 0);
		this.debugMode = getFV (debugMode, false);
		this.registerWithJS = getFV(registerWithJS, false);
		this.DOMId = getFV(DOMId, "");
		this.lang = getFV (lang, "EN");
		this.scaleMode = getFV (scaleMode, "noScale");		
		//Create an empty enumeration for list of objects
		//We'll feed values to this from setChartObjects() method.
		this.objects = new FCEnum();
		//Initialize parameter storage object
		this.params = new Object();
		//Initialize chart configuration storage object
		this.config = new Object();
		//Object to store chart rendering intervals
		this.config.intervals = new Object();
		//Elements object to store the various elements of chart.
		this.elements = new Object();
		//Initialize style manager
		this.styleM = new StyleManager(this, this.objects);
		//Initialize Macros
		this.macro = new Macros();
		//Initialize Depth Manager
		this.dm = new DepthManager(0);
		//Movie clip loader for the logo.
		this.logoMCLoader = new MovieClipLoader();
		//Listener object for the logo MC
		this.logoMCListener = new Object();
		//When the chart has started, it is not in export capture process
		this.exportCaptureProcessOn = false;
		// ----- CREATE REQUIRED MOVIE CLIPS NOW -----//
		//Create the chart movie clip container
		this.cMC = parentMC.createEmptyMovieClip ("Chart", depth + 1);
		//Re-position the chart Movie clip to required x and y position
		this.cMC._x = this.x;
		this.cMC._y = this.y;
		//Create movie clip for tool tip
		this.ttMC = parentMC.createEmptyMovieClip ("ToolTip", depth + 4);
		//Initialize tool tip by setting co-ordinates and span area
		this.tTip = new ToolTip (this.ttMC, this.x, this.y, this.width, this.height, 8);
		//Tool tip has been created - so initialize Annotation Manager		
		this.am = new AnnotationManager(this, this.objects, this.styleM, this.macro, this.tTip, this.width, this.height, this.registerWithJS);		
		//Text-field test movie clip
		this.tfTestMC = parentMC.createEmptyMovieClip ("TestTF", depth + 5);		
		//Logo holder - Setting at depth 100000 in cMC
		this.logoMC  = this.cMC.createEmptyMovieClip ("Logo", 100000);
		//We do NOT reposition logoMC to x,y here as it's done during rendering.		
		//Create the movie clip holder for log
		this.logMC = parentMC.createEmptyMovieClip ("Log", depth + 3);
		//Re-position the log Movie clip to required x and y position
		this.logMC._x = this.x;
		this.logMC._y = this.y;
		//Create the log instance
		this.lgr = new Logger (logMC, this.width, this.height);
		if (this.debugMode){
			/**
			* If the chart is in debug mode, we:
			* - Add parameters to the chart.
			* - Show log.
			*/
			//Log the chart parameters
			this.log ("Info", "Chart loaded and initialized.", Logger.LEVEL.INFO);
			this.log ("Initial Width", String (this.width) , Logger.LEVEL.INFO);
			this.log ("Initial Height", String (this.height) , Logger.LEVEL.INFO);
			this.log ("Scale Mode", this.scaleMode, Logger.LEVEL.INFO);
			this.log ("Debug Mode", (this.debugMode == true) ? "Yes":"No", Logger.LEVEL.INFO);
			this.log ("Application Message Language", this.lang, Logger.LEVEL.INFO);
			//Now show the log
			lgr.show();
		}
		if (this.registerWithJS==true && ExternalInterface.available){
			//Expose image saving functionality to JS. 
			ExternalInterface.addCallback("saveAsImage",this, exportTriggerHandlerJS);
			//Expose the methods to JavaScript using ExternalInterface		
			ExternalInterface.addCallback("print", this, printChart);
			//Export chart as image
			ExternalInterface.addCallback("exportChart", this, exportTriggerHandlerJS);
			//Get chart's image date
			ExternalInterface.addCallback("getImageData", this, exportTriggerHandlerGI);
			//Returns the XML data of chart
			ExternalInterface.addCallback("getXML", this, returnXML);
			//Returns the attribute of a specified chart element
			ExternalInterface.addCallback("getChartAttribute", this, returnChartAttribute);
			//Returns the data of chart as CSV/TSV
			ExternalInterface.addCallback("getDataAsCSV", this, exportChartDataCSV);
			//Returns whether the chart has rendered
			ExternalInterface.addCallback("hasRendered", this, hasChartRendered);
			//Returns the signature of the chart
			ExternalInterface.addCallback("signature", this, signature);
		}
		//Initialize EventDispatcher to implement the event handling functions
		mx.events.EventDispatcher.initialize(this);
	}
	//These functions are defined in the class to prevent
	//the compiler from throwing an error when they are called
	//They are not implemented until EventDispatcher.initalize(this)
	//overwrites them.
	public function dispatchEvent() {
	}
	public function addEventListener() {
	}
	public function removeEventListener() {
	}
	public function dispatchQueue() {
	}
	/**
	 * exposeChartRendered method is called when the chart has rendered. 
	 * Here, we expose the event to JS (if required) & also dispatch a
	 * event (so that, if other movies are loading this chart, they can listen).
	*/
	private function exposeChartRendered():Void {
		//Set flag that chart has rendered as true
		this.chartRendered = true;
		//Proceed, if we've not already conveyed the event
		if (this.renderEventConveyed==false){
			//Expose event to JS
			if (this.registerWithJS==true &&  ExternalInterface.available){
				ExternalInterface.call("FC_Rendered", this.DOMId);
			}
			//Dispatch an event to loader class
			this.dispatchEvent({type:"rendered", target:this});
			//Update flag that we've conveyed both rendered events now.
			this.renderEventConveyed = true;
		}
		//Clear calling interval
		clearInterval(this.config.intervals.renderedEvent);
	}
	/**
	 * Raises the FC_NoDataToDisplay event to ExternalInterface, when the
	 * chart doesn't have any data to display.
	 */
	private function raiseNoDataExternalEvent():Void {
		if (this.registerWithJS==true &&  ExternalInterface.available){
			ExternalInterface.call("FC_NoDataToDisplay", this.DOMId);
		}
	}
	//----------- DATA RELATED AND PARSING METHODS ----------------//
	/**
	* setXMLData helps set the XML data for the chart. The XML data
	* is acquired from external source. Like, if you load the chart
	* in your movie, you need to create/load the XML data and handle
	* the loading events (etc.). Finally, when the proper XML is loaded,
	* you need to pass it to Chart class. When FusionCharts is loaded
	* in HTML, the .fla file loads the XML and displays loading progress
	* bar and text. Finally, when loaded, errors are checked for, and if
	* ok, the XML is passed to chart for further processing and rendering.
	*	@param	objXML	XML Object containing the XML Data
	*	@return		Nothing.
	*/
	public function setXMLData(objXML:XML):Void {
		//If the XML data has no child nodes, we display error
		if (!objXML.hasChildNodes()){
			//Show "No data to display" error
			tfAppMsg = this.renderAppMessage(_global.getAppMessage("NODATA", this.lang));
			//Add a message to the log.
			this.log("ERROR", "No data to display. There isn't any node/element in the XML document. Please check if your dataURL is properly URL Encoded or, if XML has been correctly embedded in case of dataXML.", Logger.LEVEL.ERROR);
		} else {
			//We've data.
			//Store the XML data in class
			this.xmlData = new XML();
			this.xmlData = objXML;
			//Show rendering chart message
			tfAppMsg = this.renderAppMessage (_global.getAppMessage("RENDERINGCHART", this.lang));
			//If the chart is in debug mode, then add XML data to log
			if (this.debugMode){
				var strXML:String = this.xmlData.toString();
				//First we need to convert < and > in XML to &lt; and &gt;
				//As our logger textbox is HTML enabled.
				strXML = StringExt.replace (strXML, "<", "&lt;");
				strXML = StringExt.replace (strXML, ">", "&gt;");
				//Also convert carriage returns to <BR> for better viewing.
				strXML = StringExt.replace (strXML, "/r", "<BR>");
				this.log ("XML Data", strXML, Logger.LEVEL.CODE);
			}
		}
	}
	/**
	 * returnXML method returns the XML data of the chart as string
	*/
	public function returnXML():String{
		//If the XML data's status is 0 (loaded and parsed), we return it
		//Else, we just return an empty chart element.
		if (this.xmlData.status==0){
			return this.xmlData.toString();
		}else{
			return "<chart></chart>";
		}
	}
	/**
	 * Returns the value for a specified attribute. The attribute value is returned from 
	 * the values initially specified in the XML. We do not take into consideration any 
	 * forced values imposed in the code.
	 * @param	strAttribute	Name of the attribute whose value is to be returned.
	 * @return	The value of the attribute, as specified in the XML. Returns an empty
	 * 			string, if the attribute was not found in XML.
	 */
	public function returnChartAttribute(strAttribute:String):String {
		//To get the attribute's value, we directly parse the XML of the chart.
		var i : Number;
		//Get the element nodes
		var arrDocElement : Array = this.xmlData.childNodes;
		//Look for <graph> or <chart> element
		for (i = 0; i < arrDocElement.length; i ++)
		{
			//If it's a <graph> or <chart> element, proceed.
			//Do case in-sensitive mathcing by changing to upper case
			if (arrDocElement [i].nodeName.toUpperCase () == "GRAPH" || arrDocElement [i].nodeName.toUpperCase () == "CHART")
			{
				//Now, get the list of attributes for <chart> element and get the required value
				var chartElement:XMLNode = arrDocElement [i];
				//Get the list of attributes as array
				//Array to store the attributes
				var atts : Array = Utils.getAttributesArray (chartElement);
				//Now, return the value
				return (getFV(atts[strAttribute.toLowerCase()], ""));
			}
		}
	}
	/**
	 * Parses attributes that are common to all charts and have same default values across.
	 * This method can also be used to over-ride any attributes that have been 
	 * parsed at common level and then needs to be generalized.
	 * @param	graphElement	Reference to <chart> element node.
	 * @param	is2D			Whether the chart is a 2D chart; Required for selection of palette
	 */
	private function parseCommonAttributes (graphElement : XMLNode, is2D:Boolean) : Void 
	{
		//Array to store the attributes
		var atts : Array = Utils.getAttributesArray (graphElement);
		//NOW IT'S VERY NECCESARY THAT WHEN WE REFERENCE THIS ARRAY
		//TO GET AN ATTRIBUTE VALUE, WE SHOULD PROVIDE THE ATTRIBUTE
		//NAME IN LOWER CASE. ELSE, UNDEFINED VALUE WOULD SHOW UP.
		//Whether to show about Menu Item - by default set to on
		this.params.showFCMenuItem = toBoolean(getFN (atts["showaboutmenuitem"], atts ["showfcmenuitem"] , 1));
		//Additional parameters of about menu item
		this.params.aboutMenuItemLabel = getFV(atts["aboutmenuitemlabel"], "About FusionCharts");
		this.params.aboutMenuItemLink = getFV(atts["aboutmenuitemlink"], "n-http://www.fusioncharts.com/?BS=AboutMenuLink");
		//Whether to show print Menu Item - by default set to on
		this.params.showPrintMenuItem = toBoolean(getFN(atts ["showprintmenuitem"] , 1));
		//Options related to export of chart data
		this.params.showExportDataMenuItem = toBoolean(getFN(atts["showexportdatamenuitem"], 0));
		this.params.exportDataMenuItemLabel = getFV(atts["exportdatamenuitemlabel"], "Copy data to clipboard");
		this.params.exportDataSeparator = getFV(atts["exportdataseparator"], ",");
		//Whether to export formatted values
		this.params.exportDataFormattedVal = toBoolean(getFN(atts["exportdataformattedval"], 0));
		//Normalize the export data separator for special characters
		this.params.exportDataSeparator = this.normalizeKeyword(this.params.exportDataSeparator);
		//Qualifier for the exported data
		this.params.exportDataQualifier = getFV(atts["exportdataqualifier"], "{quot}");
		//If it's empty space, we assume no qualifiers are needed
		this.params.exportDataQualifier = (this.params.exportDataQualifier == " ")?"":this.params.exportDataQualifier;
		//Normalize the qualifier
		this.params.exportDataQualifier = this.normalizeKeyword(this.params.exportDataQualifier);
		//Fixed line break for export data
		this.params.exportDataLineBreak = "\r\n";
		//Background swf
		this.params.bgSWF = getFV (atts ["bgswf"] , "");
		this.params.bgSWFAlpha = getFN (atts ["bgswfalpha"] , 100);
		//Overlay (foreground) logo parameters
		this.params.logoURL = getFV(atts["logourl"], "");
		this.params.logoPosition = getFV(atts["logoposition"], "TL");
		this.params.logoAlpha = getFN(atts["logoalpha"], 100);
		this.params.logoLink = getFV(atts["logolink"], "");
		this.params.logoScale = getFN(atts["logoscale"], 100);
		//Tool Tip - Shadow
		this.params.showToolTipShadow = toBoolean (getFN (atts ["showtooltipshadow"] , 0));
		//Whether to show v-line label borders
		this.params.showVLineLabelBorder = toBoolean(getFN(atts["showvlinelabelborder"], 1));
		//Export chart related attributes
		this.params.exportEnabled = toBoolean (getFN (atts ["exportenabled"], atts ["imagesave"] , 0));
		//Whether to show export Menu items
		this.params.exportShowMenuItem = toBoolean(getFN(atts["exportshowmenuitem"], atts["showexportmenuitem"], this.params.exportEnabled?1:0));
		//Export formats to be supported, along with their names in context menu
		this.params.exportFormats = getFV(atts["exportformats"], "JPG=Save as JPEG Image|PNG=Save as PNG Image|PDF=Save as PDF");
		//Whether to save the chart at client? Default is server side export
		this.params.exportAtClient = toBoolean (getFN (atts ["exportatclient"] , 0));
		//Export action - Save or Download. Only applicable when exporting at server.
		this.params.exportAction = String(getFV(atts["exportaction"], "download")).toLowerCase();
		//Can only be save or download
		this.params.exportAction = (this.params.exportAction != "save" && this.params.exportAction != "download")?"download":this.params.exportAction;
		//Target window for download of image - only applicable during server-side download
		//Currently, we support only _self and _blank
		this.params.exportTargetWindow = String(getFV(atts["exporttargetwindow"], "_self")).toLowerCase();
		//Can only be _self or _blank
		this.params.exportTargetWindow = (this.params.exportTargetWindow != "_self" && this.params.exportTargetWindow != "_blank")?"_self":this.params.exportTargetWindow;
		//URL of server side script, or DOM ID of the DIV that contains export component
		this.params.exportHandler = getFV (atts["exporthandler"], atts ["imagesaveurl"] , "");
		//File name to be exported
		this.params.exportFileName = getFV(atts["exportfilename"], "FusionCharts");
		//Export parameters - for future use (gets passed to server/client exporter)
		this.params.exportParameters = getFV(atts["exportparameters"], "");
		//Export call back function name
		//This attribute specifies the name of the callback JavaScript function which would 
		//be called when the export event is complete.
		//Scenarios:
		//Server-side Save: the chart would call this function passing all the 
		//confirm-response received from the server. 
		//Server-side Download:  no callback
		//Client-side export: The client side exporter component (SWF) would call 
		//the function once the export event complete.
		this.params.exportCallback = getFV(atts["exportcallback"], "FC_Exported");
		//Export dialog box propertiES
		this.params.showExportDialog = toBoolean (getFN (atts ["showexportdialog"] , 1));
		this.params.exportDialogMessage = getFV(atts["exportdialogmessage"],"Capturing Data : ");
		this.params.exportDialogColor = formatColor (getFV (atts["exportdialogcolor"], atts ["imagesavedialogcolor"] , "FFFFFF"));
		this.params.exportDialogBorderColor = formatColor (getFV (atts["exportdialogbordercolor"], "999999"));
		this.params.exportDialogFontColor = formatColor (getFV (atts["exportdialogfontcolor"], atts ["imagesavedialogfontcolor"] , "666666"));
		this.params.exportDialogPBColor = formatColor (getFV (atts["exportdialogpbcolor"], atts ["imagesavedialogcolor"] , "E2E2E2"));
		//Internal callback function to be invoked when capturing is done
		this.params.exportDataCaptureCallback = "FC_ExportDataReady";
		//Whether to unescape links specified in XML
		this.params.unescapeLinks = toBoolean (getFN (atts ["unescapelinks"] , 1));
		//Custom canvas margins (forced by the user)
		this.params.canvasLeftMargin = getFN(atts ["canvasleftmargin"] , -1);
		this.params.canvasRightMargin = getFN(atts ["canvasrightmargin"] , -1);
		this.params.canvasTopMargin = getFN(atts ["canvastopmargin"] , -1);
		this.params.canvasBottomMargin = getFN(atts ["canvasbottommargin"] , -1);
	}
	//----------- CORE FUNCTIONAL METHODS ----------//
	/**
	* setChartObjects method stores the list of chart objects
	* in local arrObjects array and objects enumeration.
	*	@return				Nothing
	*/
	private function setChartObjects():Void{
		//Copy array to instance variable
		//Iterate through the list of objects and add it to the enumeration
		var i:Number;
		for (i=0; i<this.arrObjects.length; i ++){
			this.objects.addItem(this.arrObjects[i]);
		}		
		//Now, if the chart is in debug mode, add the list to log		
		if (this.debugMode){
			var strChartObjects:String="";
			for (i=0; i<this.arrObjects.length; i++){
				strChartObjects += "<LI>" + this.arrObjects[i] + "</LI>";
			}
			this.log("Chart Objects", strChartObjects, Logger.LEVEL.INFO);
		}
	}
	
	/**
	 * Normalizes the keyword. For example, tab cannot be specified
	 * in XML as a tab character. So instead we use pseudo codes as {tab} as 
	 * keyword in XML. Internally, this method normalizes the specified
	 * pseudo keyword.
	 * @param	strKeyword	Pseudo code specified in XML.
	 * @return	Normalized string representation of the pseudo keyword specified
	 * 			in XML.
	 */
	private function normalizeKeyword(strKeyword:String):String {
		switch (strKeyword.toLowerCase()) {
			case "{tab}":
			return "\t";
			break;
			case "{quot}":
			return String.fromCharCode(34);
			break;
			case "{apos}":
			return String.fromCharCode(39);
			default:
			return strKeyword;
			break;
		}
	}
	
	/**
	 * setupAnnotationMC method creates the annotation container movie clips
	 * and conveys to the annotation class.
	*/
	private function setupAnnotationMC():Void{
		//Create movie clips for annotations-below and annotations abobe in the allotted depth.
		var annBelowMC:MovieClip = this.cMC.createEmptyMovieClip("AnnotationsBelow",this.dm.getDepth("ANNOTATIONBELOW"));
		var annAboveMC:MovieClip = this.cMC.createEmptyMovieClip("AnnotationsAbove",this.dm.getDepth("ANNOTATIONABOVE"));
		//Convey it to annotation manager instance
		this.am.setMC(annBelowMC, annAboveMC);
	}
	/**
	 * renderAnnotationBelow method is called when annotations below the chart are to
	 * be rendered.
	*/
	private function renderAnnotationBelow():Void{
		this.am.render(true);
		//Clear Interval
		clearInterval(this.config.intervals.annotationsBelow);
	}
	/**
	 * renderAnnotationAbove method is called when annotations above the chart are to 
	 * be rendered.	 
	*/
	private function renderAnnotationAbove():Void{
		this.am.render(false);
		//Clear Interval
		clearInterval(this.config.intervals.annotationsAbove);
	}
	
	/**
	* log method records a message to the chart's logger. We record
	* messages in the logger, only if the chart is in debug mode to
	* save memory
	*	@param	strTitle	Title of messsage
	*	@param	strMsg		Message to be logged
	*	@param	intLevel	Numeric level of message - a value from
	*						Logger.LEVEL Enumeration
	*/
	public function log(strTitle:String, strMsg:String, intLevel:Number):Void{
		if (debugMode){
			lgr.record (strTitle, strMsg, intLevel);
		}
	}
	//-----------------------------/
	/**
	* printChart method prints the chart.
	*/
	public function printChart():Void{
		//Create a Print Job Instance
		var PrintQueue = new PrintJob();
		//Show the Print box.
		var PrintStart:Boolean = PrintQueue.start();
		//If User has selected Ok, set the parameters.
		if (PrintStart){
			//Add the chart MC to the print job with the required dimensions
			//If the chart width/height is bigger than page width/height, we need to scale.
			if (this.width>PrintQueue.pageWidth || this.height>PrintQueue.pageHeight){				
				//Scale on the lower factor
				var factor:Number = Math.min((PrintQueue.pageWidth/this.width),(PrintQueue.pageHeight/this.height));
				//Scale the movie clip to fit paper size 
				this.cMC._xScale = factor*100;
				this.cMC._yScale = factor*100;
			}
			//Add the chart to printer queue
			PrintQueue.addPage (this.cMC, {xMin:0, xMax:this.width, yMin:0, yMax:this.height}, {printAsBitmap:true});
			//Send the page for printing
			PrintQueue.send();
			//Re-scale back to normal form (as the printing is over).
			this.cMC._xScale = this.cMC._yScale = 100;
		}		
		delete PrintQueue;
	}
	/**
	* reInit method re-initializes the chart. This method is basically called
	* when the user changes chart data through JavaScript. In that case, we need
	* to re-initialize the chart, set new XML data and again render.
	* Order of calling is chart.remove() --> chart.reInit();
	*/
	public function reInit():Void{
		//Re-initialize params and config object
		this.params = new Object();
		this.config = new Object();
		//Re-init objects too (as annotation ids might have been added)
		this.objects = new FCEnum();
		//Re-init chart elements
		this.elements = new Object();
		//Re-feed the original chart objects.
		this.setChartObjects();
		//Object to store chart rendering intervals
		this.config.intervals = new Object();
		//Re-create an empty chart movie clip
		this.cMC = parentMC.createEmptyMovieClip ("Chart", depth + 1);
		//Re-position the chart Movie clip to required x and y position
		this.cMC._x = this.x;
		this.cMC._y = this.y;
		//Movie clip loader for the logo.
		this.logoMCLoader = new MovieClipLoader();
		//Listener object for the logo MC
		this.logoMCListener = new Object();
		//Logo holder - Setting at depth 10, leaving 5 depths in between blank
		this.logoMC  = this.cMC.createEmptyMovieClip ("Logo", 100000);		
		//Reset the style manager
		this.styleM = new StyleManager(this, this.objects);
		//Reset macros
		this.macro = new Macros();
		//Re-create the annotation manager
		this.am = new AnnotationManager(this, this.objects, this.styleM, this.macro, this.tTip, this.width, this.height, this.registerWithJS);
		//Reset depth manager
		this.dm.clear();
		this.dm.setStartDepth (0);
		//Set timeElapsed to 0
		this.timeElapsed = 0;
		//Set chartRendered to false again
		this.chartRendered = false;
		//Export capture process back to false
		this.exportCaptureProcessOn = false;
	}
	/**
	* remove method removes the chart by clearing the chart movie clip
	* and removing any listeners. However, the logger still stays on.
	* To remove the logger too, you need to call destroy method of chart.
	*/
	public function remove():Void {
		//Remove all the intervals (which might not have been cleared)
		//from this.config.intervals
		var item:Object;
		for (item in this.config.intervals){
			//Clear interval
			clearInterval(this.config.intervals[item]);
		}
		//Remove all annotations
		this.am.destroy();
		//Remove application message (if any)
		this.removeAppMessage(this.tfAppMsg);
		//Remove listener of logo and its associated clips
		this.logoMCLoader.removeListener(this.logoMCListener);
		//Unloading movie clip after listeners have been removed, so that
		//onLoadError is NOT invoked.
		this.logoMCLoader.unloadClip(this.logoMC);
		//Remove the logoMC itself
		logoMC.removeMovieClip();
		//Remove the chart movie clip
		cMC.removeMovieClip();
		//Hide tool tip
		tTip.hide();
	}
	/**
	* destroy method destroys the chart by removing the chart movie clip,
	* logger movie clip, and removing any listeners.
	*/
	public function destroy():Void{
		//Remove the chart first
		this.remove();
		//Remove the chart movie clip
		cMC.removeMovieClip();
		//Destroy the logger
		this.lgr.destroy();
		//Destroy tool tip
		this.tTip.destroy();
		//Remove tool tip movie clip
		this.ttMC.removeMovieClip();
		//Remove test text field movie clip
		this.tfTestMC.removeMovieClip();
		//Remove logger movie clip
		this.logMC.removeMovieClip();	
		//Remove logo MC
		this.logoMC.removeMovieClip();
	}
	//------------ External Interface Methods -----------//
	/**
	 * Returns a boolean value indicating whether the chart has finished
	 * rendering.
	 * @return	Boolean value indicating whether the chart has finished
	 * 			rendering.
	 */
	private function hasChartRendered():Boolean {
		return this.chartRendered;
	}
	/**
	 * Returns the signature of the chart in format:
	 */
	public function signature():String {
		var sgn:String = "FusionWidgets/" + this._version;
		return sgn;
	}
	//-------------------- Context Menu related methods ----------------------//
	/**
	 * returnAbtMenuItem method returns a context menu item that reads
	 * "About FusionCharts".
	*/
	private function returnAbtMenuItem():ContextMenuItem{
		//Create a about context menu item
		var aboutCMI : ContextMenuItem = new ContextMenuItem (this.params.aboutMenuItemLabel, Delegate.create (this, openAboutMenuLink));
		aboutCMI.separatorBefore = true;		
		return aboutCMI;
	}
	/**
	 * Adds all the export chart related menu items to the context menu. This 
	 * method is invoked by each chart class. Here, we look at exportFormats and
	 * add all provided formats to the context menu.
	 * @param	cm	Context Menu to which we've to add export chart items.
	 */
	private function addExportItemsToMenu(cm:ContextMenu) {
		if (this.params.exportEnabled && this.params.exportShowMenuItem) {
			//First, parse the export formats given by user
			var expFrm:Array = this.params.exportFormats.split("|");
			var itm:String, itmLabel:String, itmFormat:String;
			//Iterate through each item and add to menu
			for (var i:Number = 0; i < expFrm.length; i++) {
				//If the item is not blank, proceed only then
				if (expFrm[i] != "") {
					//Set containers empty
					itmLabel = "";
					itmFormat = "";
					//If there's an equal to sign
					if (expFrm[i].indexOf("=") != -1) {
						//User has specified both format and context menu label
						itm = String(expFrm[i])
						itmFormat = itm.substring(0, itm.indexOf("="));
						itmLabel = itm.substring(itm.indexOf("=") + 1, itm.length + 1);						
					}else {
						//User has just specified format. So, automatically set context menu label.
						itmFormat = expFrm[i];
						itmLabel = "Save as " + itmFormat;
					}
					//Now, add it to context menu
					var exportCMI : ContextMenuItem = new ContextMenuItem (itmLabel, Delegate.create (this, exportTriggerHandlerCM));
					//Set the item format within the item, so that we do not need to track it individually
					exportCMI.format = itmFormat;
					cm.customItems.push(exportCMI);
				}
			}
		}
	}
	/**
	 * Returns a context menu item to represent Export Data. 
	 * @return
	 */
	private function returnExportDataMenuItem():ContextMenuItem {
		//Create a about context menu item
		var exportDataCMI : ContextMenuItem = new ContextMenuItem (this.params.exportDataMenuItemLabel, Delegate.create (this, exportChartDataMenuItemHandler));
		return exportDataCMI;
	}
	/**
	 * openAboutMenuLink is the handler for About Menu Item
	 * context menu item
	*/
	private function openAboutMenuLink():Void{
		//Open the link
		this.invokeLink(this.params.aboutMenuItemLink);
	}	
	/**
	 * Invoked when user selects the export data handler from
	 * context menu. Here, we get the export data and copy it to clipboard.
	 */
	private function exportChartDataMenuItemHandler() {
		//Copy the data to clipboard
		System.setClipboard(this.exportChartDataCSV());
	}
	/**
	 * Forward declaration block, as individual charts export their
	 * own data in the required format. Child classes can build on this class.
	 * @return	CSV separated data of the chart.
	 */
	public function exportChartDataCSV():String {
		return "";
	}
	//---------------------------------------------------------------------//
	//			           Export Chart Related Routines
	//---------------------------------------------------------------------//
	//---- Export Chart Trigger Handlers ------//
	/**
	 * Handles all the export chart triggers raised from the context menu
	 * of chart.
	 * @param	obj		Object on which the context menu was clicked
	 * @param	item	Representation of context menu item that was clicked.
	 * 					item.format represents the format that the user selected.
	 */
	private function exportTriggerHandlerCM(obj:Object, item:Object):Void {
		//Begin capture process
		this.exportCapture(item.format, this.params.exportHandler, this.params.exportAtClient, this.params.exportDataCaptureCallback, this.params.exportCallback, this.params.exportAction, this.params.exportTargetWindow, this.params.exportFileName, this.params.exportParameters, this.params.showExportDialog);
	}
	
	/**
	 * Handles export chart triggers raised from getImageData() JS function
	 * @param	exportSettings	Object containing over-riding settings of export parameters.
	 * 
	 */
	private function exportTriggerHandlerGI(exportSettings:Object):Void {
		//We proceed only if export is enabled
		if (this.params.exportEnabled) {
			//Convert all attributes in exportSettings to small case.
			var atts:Array = Utils.getParamsArray(exportSettings);
			var exportCallback:String = getFV(atts["exportcallback"], atts["callback"], this.params.exportCallback);
			var showExportDialog:Boolean = toBoolean(getFN(atts["showexportdialog"], this.params.showExportDialog?1:0));
			this.exportCapture("BMP", this.params.exportHandler, true, exportCallback, exportCallback, this.params.exportAction, this.params.exportTargetWindow, this.params.exportFileName, this.params.exportParameters, showExportDialog);
		}else {
			this.log("Export not enabled", "Exporting has not been enabled for this chart. Please set exportEnabled='1' in XML to allow exporting of chart.", Logger.LEVEL.ERROR);
		}
	}
	
	/**
	 * Handles export chart triggers raised from exportChart() JS function.
	 * @param	exportSettings	Object containing over-riding settings of all
	 * 							export related parameters.
	 */
	private function exportTriggerHandlerJS(exportSettings:Object):Void {
		//We proceed only if export is enabled
		if (this.params.exportEnabled) {
			//Convert all attributes in exportSettings to small case.
			var atts:Array = Utils.getParamsArray(exportSettings);
			//Now create a local list of parameters - based on over-riding/original
			var exportHandler:String = getFV(atts["exporthandler"], this.params.exportHandler);
			var exportAtClient:Boolean = toBoolean(getFN(atts["exportatclient"], this.params.exportAtClient?1:0));
			var exportCallback:String = getFV(atts["exportcallback"], this.params.exportCallback);
			var exportAction:String = String(getFV(atts["exportaction"], this.params.exportAction)).toLowerCase();
			var exportTargetWindow:String = String(getFV(atts["exporttargetwindow"], this.params.exportTargetWindow)).toLowerCase();
			var exportFileName:String = getFV(atts["exportfilename"], this.params.exportFileName);
			var exportParameters:String = getFV(atts["exportparameters"], this.params.exportParameters);
			//To get a default export format value, we need to find the first value specified in export formats
			var expFrm:Array = this.params.exportFormats.split("|");
			var firstExportFormat:String = expFrm[0].split("=")[0];
			var exportFormat:String = getFV(atts["exportformat"], firstExportFormat);
			var showExportDialog:Boolean = toBoolean(getFN(atts["showexportdialog"], this.params.showExportDialog?1:0));
			//Validation of over-written fields
			//Can only be save or download
			exportAction = (exportAction != "save" && exportAction != "download")?"download":exportAction;
			//Can only be _self or _blank
			exportTargetWindow = (exportTargetWindow != "_self" && exportTargetWindow != "_blank")?"_self":exportTargetWindow;			
			//Now, initiate the capture process
			this.exportCapture(exportFormat, exportHandler, exportAtClient, this.params.exportDataCaptureCallback, exportCallback, exportAction, exportTargetWindow, exportFileName, exportParameters, showExportDialog);
		}else {
			this.log("Export not enabled", "Exporting has not been enabled for this chart. Please set exportEnabled='1' in XML to allow exporting of chart.", Logger.LEVEL.ERROR);
		}
	}
	/**
	 * Starts the capture method of chart. This is the common method that is called
	 * from any of the export triggers.
	 * @param	exportFormat			The format in which export has to take place.
	 * @param	exportHandler			Handler for the exported data - either server side script or local export component.
	 * @param	exportAtClient			Whether to export the chart at client or at server.
	 * @param	exportCaptureCallback	In case of client side export, name of call back function to be invoked when data has finished capturing.
	 * @param	exportFinalCallback		Final call back function to invoked, when exported data has been saved/exported.
	 * @param	exportAction			In case of server side export, action to be taken.
	 * @param	exportTargetWindow		In case of server side and download-action, target window which would open the result chart 
	 * @param	exportFileName			Name of resultant export file
	 * @param	exportParameters		Any parameters to be passed to and fro.
	 * @param	showExportDialog		Whether to show export dialog box	
	 */
	private function exportCapture(exportFormat:String, exportHandler:String, exportAtClient:Boolean, exportCaptureCallback:String, exportFinalCallback:String, exportAction:String, exportTargetWindow:String, exportFileName:String, exportParameters:String, showExportDialog:Boolean):Void {
		//If the chart is already in export capture process, ignore this call
		if (this.exportCaptureProcessOn == true) {
			return;
		}else {
			//Set flag to on
			this.exportCaptureProcessOn = true;
		}
		//If format or handler is not specified, we do not export
		if (exportFormat == "" || exportHandler == "") {
			//Log that we're not 
			this.log("Incomplete export parameters", "You need to specify the mandatory export parameters (exportEnabled, exportFormat, exportHandler) before the chart can be exported", Logger.LEVEL.ERROR);
			return;
		}
		//Show the export dialog, if need be
		if (showExportDialog){
			exportDialogShow();
		}
		
		//1. Create a local object encapsulating all the properties passed to this method.
		//2. Create an instance of BitmapSave to capture the chart's image.
		//3. Define listener objects to track progress of it.
		
		//Object to store all export properties 
		var expO:Object = new Object();
		expO.exportFormat = exportFormat;
		expO.exportHandler =  exportHandler;
		expO.exportAtClient = exportAtClient;
		expO.exportCaptureCallback = exportCaptureCallback;
		expO.exportFinalCallback = exportFinalCallback;
		expO.exportAction = exportAction;
		expO.exportTargetWindow = exportTargetWindow;
		expO.exportFileName = exportFileName;
		expO.exportParameters = exportParameters;
		
		//Reference to this class
		var classRef = this;
		
		//Create listener object for capture.
		var cList:Object = new Object();		

		//Event to detect when capturing is complete.
		cList.onCaptureComplete = function(eventObj:Object) {
			//Hide the dialog
			if (showExportDialog){
				classRef.exportDialogHide();
			}
			//Capturing is complete. Now process the data.
			expO.stream = eventObj.out;
			classRef.exportProcess(expO);			
		}
		
		//Event to detect progress of capturing
		cList.onProgress = function(eventObj:Object){
			//Update the progess status
			if (showExportDialog){
				classRef.exportDialogUpdate(eventObj.percentDone);
			}
		}

		//Create an instance of BitmapSave 
		var bmpS:BitmapSave = new BitmapSave(this.cMC,this.x,this.y,this.width,this.height,0xffffff);	
		
		//Before we start capturing, we need to make sure that none of the movie clips
		//are cached as bitmap. So run a function that does this job.
		if(!this.cMC.skipBmpCacheCheck){
			var arrCache:Array = this.exportSetPreSaving(this.cMC);
		}
		
		//Capture the bitmap now.
		this.log("Export Capture Process Start", "The chart has started capturing bitmap data for export.", Logger.LEVEL.INFO);
		bmpS.capture();
		
		//Now that the bitmap is captured, we need to set the cache property to original
		if(!this.cMC.skipBmpCacheCheck){
			this.exportResetPostSaving(this.cMC, arrCache)
		}
		
		//Add the event listeners
		bmpS.addEventListener("onCaptureComplete", cList);
		bmpS.addEventListener("onProgress", cList);
	}
	/**
	 * Processes the chart's export data once the capture process is over.
	 * @param	expObj	Object containing the data stream and all export
	 * 					parameters.
	 */
	private function exportProcess(expObj:Object):Void {
		//Based on whether the export is to be done at client side or server side, we 
		//take different courses. In case of client side, we just pass the JS object
		//to the callback function and our job in done.
		//In case of server side, there are 2 options based on action - save and download
		//In case of download, we do not have to do anything.
		//In case of save, we need to track the return status and pass it to callback function.
		if (expObj.exportAtClient == true) {
			//Export at client. Build an object in the required format and send it out.
			this.log("Export Trasmit Data Start", "The chart has finished capture stage of bitmap export and is now initiating transfer of data to JS function '" + expObj.exportCaptureCallback + "'.", Logger.LEVEL.INFO);
			//Create an object to represent the transfer data.
			var out:Object = new Object();
			out.stream = expObj.stream;
			//Append the meta information
			out.meta = new Object();
			out.meta.caption = this.params.caption;
			out.meta.width = this.width;
			out.meta.height = this.height;
			out.meta.bgColor = "FFFFFF";
			out.meta.DOMId = this.DOMId;
			//Append the parameters that were passed as over-riding or XML
			out.parameters = new Object();
			out.parameters.exportAtClient = (expObj.exportAtClient==true)?"1":"0";
			out.parameters.exportFormat =  expObj.exportFormat;
			out.parameters.exportFormats =  this.params.exportFormats;
			out.parameters.exportCallback =  expObj.exportFinalCallback;
			out.parameters.exportAction =  expObj.exportAction;
			out.parameters.exportTargetWindow =  expObj.exportTargetWindow;
			out.parameters.exportFileName =  expObj.exportFileName;
			out.parameters.exportParameters =  expObj.exportParameters;
			out.parameters.exportHandler =  expObj.exportHandler;
			//Now, transfer it to the JS method
			if (this.registerWithJS==true && ExternalInterface.available && expObj.exportCaptureCallback!=""){
				ExternalInterface.call (expObj.exportCaptureCallback, out);
			}
		}else {
			//Export at client. Build an object in the required format and send it out.
			this.log("Export Transmit Data Start", "The chart has finished capture stage of bitmap export and is now initiating transfer of data to the module at '" + expObj.exportHandler + "'.", Logger.LEVEL.INFO);
			//Create the LoadVars object to be sent
			var l:LoadVars = new LoadVars();		
			//Set data
			l.stream = expObj.stream;
			//Set meta information
			l.meta_width = this.width;
			l.meta_height = this.height;
			l.meta_bgColor = "FFFFFF";
			l.meta_DOMId = this.DOMId;
			l.parameters = "exportAtClient=" + ((expObj.exportAtClient==true)?"1":"0") + "|" + 
				"exportFormat=" + expObj.exportFormat + "|" + "exportCallback=" + expObj.exportCallback + "|" +
				"exportAction=" + expObj.exportAction + "|" + "exportTargetWindow=" + expObj.exportTargetWindow + "|" +
				"exportFileName=" + expObj.exportFileName + "|" + "exportParameters=" + expObj.exportParameters + "|" +
				"exportHandler=" + expObj.exportHandler;
			//Now, based on whether the action is save or download, we invoke different course of action
			if (expObj.exportAction == "download") {
				//We just the data and get request in specified window.
				l.send(expObj.exportHandler, expObj.exportTargetWindow, "POST");
				//Delete the loadvars object right away
				delete l;
			}else {
				//Here, we send the data to server in background and then wait for status to be returned
				//We then invoke the callback function.
				//Create the results loadvar
				var result_lv:LoadVars = new LoadVars();
				var classRef = this;
				result_lv.onLoad = function(success:Boolean) {
					if (success) {
						//Output object
						var out:Object = new Object();
						//Append DOM Id
						DOMId = classRef.DOMId;
						//Iterate through all variables of result loadvars and add it to output objects	
						//This allows custom parameters to be passed from server side script to export JS.
						for (var name:String in result_lv) {
							//Only add string values. We remove function(s) as they do not serialize.
							if (typeof(result_lv[name])=="string"){
								out[name] = result_lv[name];
							}
						}
						//If the server returned a response, we check the status code and then take an action
						if (result_lv.statusCode == "1") {
							//If it comes here, it means that the export image was saved on server. So, call
							//the callback function and pass parameters to it.
							//Just over-ride necessary parameters
							out.width = classRef.width;
							out.height = classRef.height;
							out.fileName = result_lv.fileName;
							out.statusCode = result_lv.statusCode;
							out.statusMessage = result_lv.statusMessage;
						}else {
							//If the status code isn't one, it means there has been an error.
							classRef.log("Error in exporting", "The server side export module was unable to save the chart on server. Please check that the folder permissions have been correctly set and the requisite modules for handling graphics are installed on the server.", Logger.LEVEL.ERROR);
							//Over-ride necessary parameters
							out.width = 0;
							out.height = 0;
							out.fileName = "";
							out.statusCode = result_lv.statusCode;
							out.statusMessage = result_lv.statusMessage;
						}
						//Invoke the JS.
						if (classRef.registerWithJS==true && ExternalInterface.available && expObj.exportFinalCallback!=""){
							ExternalInterface.call (expObj.exportFinalCallback, out);
						}
					} else {
						//Log the error
						classRef.log("Error in connection", "The server side export module for exporting the chart could not be reached or it did not respond correctly. Please check the exportHandler path that you've specified in XML. Also, please check that the requisite modules are installed on the server to be able to generate the images.", Logger.LEVEL.ERROR);
					}
				};
				l.sendAndLoad(expObj.exportHandler, result_lv, "POST");
				//Delete loadvars after sending data
				delete l;
			}			
		}
		//Export capture process has finished. So reset flag
		this.exportCaptureProcessOn = false;
	}
	/**
	 * Shows the dialog box that is shown during export chart capture.
	 */
	private function exportDialogShow() {
		//Progress bar positioning and dimension
		var PBWidth:Number = (this.width > 200) ? 150 : (this.width - 25);
		var PBStartX:Number = this.x + this.width/2 - PBWidth/2;
		var PBStartY:Number = this.y + this.height/2 - 15;

		//Create the empty movie clips
		exportDialogMC = this.parentMC.createEmptyMovieClip("exportChartDialogBg", this.depth + 5);
		var exportDialogSubMC = exportDialogMC.createEmptyMovieClip("InternalDialog", 1);
		//Create a black overlay rectangle
		exportDialogMC.beginFill(0x000000,20);
		exportDialogMC.moveTo(this.x, this.y);
		exportDialogMC.lineTo(this.x + this.width, this.y);
		exportDialogMC.lineTo(this.x + this.width, this.y + this.height);
		exportDialogMC.lineTo(this.x, this.y + this.height);
		exportDialogMC.lineTo(this.x, this.y);
		
		//The main dialog at center of center
		var pad:Number = 20;
		exportDialogSubMC.beginFill(parseInt(this.params.exportDialogColor, 16),100);
		exportDialogSubMC.lineStyle(1, parseInt(this.params.exportDialogBorderColor,16), 100);
		exportDialogSubMC.moveTo(PBStartX - pad, PBStartY - pad);
		exportDialogSubMC.lineTo(PBStartX  + PBWidth + pad, PBStartY - pad);
		exportDialogSubMC.lineTo(PBStartX  + PBWidth + pad, PBStartY + 40 + pad);
		exportDialogSubMC.lineTo(PBStartX  - pad , PBStartY + 40 + pad);
		exportDialogSubMC.lineTo(PBStartX - pad, PBStartY - pad);
		
		//Add shadow the the dialog
		var shadowfilter:DropShadowFilter = new DropShadowFilter(2, 45, 0x333333, 0.8, 8, 8, 1, 1, false, false, false);
		exportDialogSubMC.filters = [shadowfilter];
		
		//Capture mouse event from everything otherwise underneath
		exportDialogMC.useHandCursor = false;
		exportDialogMC.onRollOver = function(){
		}
		
		//Instantiate the progress bar
		this.exportDialogPB = new FCProgressBar(this.parentMC, this.depth+6, 0, 100, PBStartX, PBStartY, PBWidth, 15, this.params.exportDialogPBColor, this.params.exportDialogPBColor, 1);
		
		//Create the text
		this.exportDialogTF = Utils.createText (false, this.params.exportDialogMessage, this.parentMC, this.depth+7, this.x + this.width/2, this.y + this.height/2 + 15, null, {align:"center", vAlign:"bottom", bold:false, italic:false, underline:false, font:"Verdana", size:10, color:this.params.exportDialogFontColor, isHTML:true, leftMargin:0, letterSpacing:0, bgColor:"", borderColor:""}, true, PBWidth, 40).tf;		
	}
	/**
	 * Updates the progress of capture in export chart dialog box
	 * @param	percentValue	Current state of capture progress
	 */
	private function exportDialogUpdate(percentValue:Number) {
		//Get the text format of text field
		var tFormat:TextFormat = exportDialogTF.getTextFormat();
		//Update the text field
		exportDialogTF.htmlText = "<font face='Verdana' size='10' color='#" + this.params.exportDialogFontColor + "'>" + this.params.exportDialogMessage + percentValue + "%</font>";
		exportDialogTF.setTextFormat(tFormat);
		//Set the value of progress bar
		exportDialogPB.setValue(percentValue);
	}
	/**
	 * Hides the dialog box once the capture process has completed.
	 */
	private function exportDialogHide() {
		//Remove all progress bar related movie clips
		exportDialogPB.destroy();
		exportDialogTF.removeTextField();
		exportDialogMC.removeMovieClip();
	}
	
	/**
	 * This method sets the bitmap caching of all objects in the chart
	 * so as to avoid freezing of interface.
	*/
	private function exportSetPreSaving(mc:MovieClip):Array{
		//Get the list of filters.
		var arrMcFilters:Array = new Array()
		//Iterate through each movie clip
		for(var i in mc){
			//Work only if it's a movie clip.
			if(mc[i] instanceof MovieClip){
				//Store the filters for this MC
				arrMcFilters[i] = new Array();
				arrMcFilters[i]['filters'] = mc[i].filters;
				mc[i].filters = [];
				//Store the cache property
				arrMcFilters[i]['cache'] = mc[i].cacheAsBitmap;
				mc[i].cacheAsBitmap = false;
				//Store children
				arrMcFilters[i]['children'] = arguments.callee(mc[i]);
			}
		}
		//Return the array
		return arrMcFilters;
	}
	/**
	 * This method restores the bitmap caching state of all the objects
	 * in the chart, once capturing is done.
	*/
	private function exportResetPostSaving(mc:MovieClip, arrMcFilters:Array){
		for(var i in arrMcFilters){			
			mc[i].filters = arrMcFilters[i]['filters'];
			mc[i].cacheAsBitmap = arrMcFilters[i]['cache'];
			arguments.callee(mc[i],arrMcFilters[i]['children']);
		}
	}
	
	// -------------------- UTILITY METHODS --------------------//	
	/**
	* returnDataAsElement method returns the data passed to this
	* method as an Element Object. We store each chart element as an
	* obejct to unify the various properties.
	*	@param	x		Start X of the element
	*	@param	y		Start Y of the element
	*	@param	w		Width of the element
	*	@param	h		Height of the element
	*	@return		Object representing the element
	*/
	private function returnDataAsElement (x:Number, y:Number, w:Number, h:Number):Object{
		//Create new object
		var element:Object = new Object();
		element.x = x;
		element.y = y;
		element.w = w;
		element.h = h;
		//Calculate and store toX and toY
		element.toX = x + w;
		element.toY = y + h;
		//Return
		return element;
	}		
	/**
	* renderAppMessage method helps display an application message to
	* end user.
	* @param	strMessage	Message to be displayed
	* @return				Reference to the text field created
	*/
	private function renderAppMessage (strMessage:String):TextField {
		return _global.createBasicText (strMessage, this.parentMC, depth, this.x + (this.width / 2) , this.y + (this.height / 2) , "Verdana", 10, "666666", "center", "bottom");
	}
	/**
	* removeAppMessage method removes the displayed application message
	* @param	tf	Text Field reference to the message
	*/
	private function removeAppMessage (tf:TextField){
		tf.removeTextField();
	}
	// --------------------- VISUAL RENDERING METHODS ------------------//
	/**
	* drawBackground method renders the chart background. The background
	* cant be solid color or gradient. All charts have a backround. So, we've
	* defined drawBackground in Chart class itself, so that sub classes can
	* directly access it (as it's common).
	*	@return		Nothing
	*/
	private function drawBackground():Void{
		//Create a new movie clip container for background
		var bgMC = this.cMC.createEmptyMovieClip("Background", this.dm.getDepth("BACKGROUND"));
		//Parse the color, alpha and ratio array
		var bgColor:Array = ColorExt.parseColorList(this.params.bgColor);
		var bgAlpha:Array = ColorExt.parseAlphaList(this.params.bgAlpha, bgColor.length);
		var bgRatio:Array = ColorExt.parseRatioList(this.params.bgRatio, bgColor.length);
		//Move to (-w/2, 0); - 0,0 registration point at center (x,y)
		bgMC.moveTo(-(this.width/2) , -(this.height / 2));
		//Create matrix object
		var matrix:Object = {matrixType:"box", w:this.width, h:this.height, x:- (this.width / 2) , y:- (this.height / 2) , r:MathExt.toRadians (this.params.bgAngle)};
		//If border is to be shown
		if (this.params.showBorder){
			bgMC.lineStyle (this.params.borderThickness, parseInt (this.params.borderColor, 16) , this.params.borderAlpha);
		}
		//Border thickness half
		var bth:Number = this.params.borderThickness/2;
		//Start the fill.
		bgMC.beginGradientFill ("linear", bgColor, bgAlpha, bgRatio, matrix);
		//Move to (-w/2, 0); - 0,0 registration point at center (x,y)
		bgMC.moveTo ( - (this.width / 2) + bth, - (this.height / 2) + bth);		
		//Draw the rectangle with center registration point
		bgMC.lineTo(this.width/2-bth, -(this.height/2)+bth);
		bgMC.lineTo(this.width/2-bth, this.height/2-bth);
		bgMC.lineTo(-(this.width/2)+ bth, this.height/2-bth);
		bgMC.lineTo(-(this.width/2)+ bth, -(this.height/2)+bth);
		//Set the x and y position
		bgMC._x = this.width/2;
		bgMC._y = this.height/2;
		//End Fill
		bgMC.endFill();
		//Apply animation
		if (this.params.animation){
			this.styleM.applyAnimation(bgMC, this.objects.BACKGROUND, this.macro, bgMC._x, - this.width / 2, bgMC._y, - this.height / 2, 100, 100, 100, null);
		}
		//Apply filters
		this.styleM.applyFilters(bgMC, this.objects.BACKGROUND);
	}
	/**
	* loadBgSWF method loads the background .swf file (if required) and also
	* loads the logo for the chart, if specified.
	*/
	private function loadBgSWF():Void{
		//We load the BG SWF only if it has been specified and it doesn't contain any colon characters
		//(to disallow XSS attacks)
		if (this.params.bgSWF != ""){
			if (this.params.bgSWF.indexOf(":")==-1 && this.params.bgSWF.indexOf("%3A")==-1){				
				//Create a movie clip container
				var bgSWFMC:MovieClip = this.cMC.createEmptyMovieClip ("BgSWF", this.dm.getDepth("BGSWF"));
				//Load the clip
				bgSWFMC.loadMovie (this.params.bgSWF);
				//Set alpha
				bgSWFMC._alpha = this.params.bgSWFAlpha;
			}else{
				this.log ("bgSWF not loaded", "The bgSWF path contains special characters like colon, which can be potentially dangerous in XSS attacks. As such, FusionCharts has not loaded the bgSWF. If you've specified the absolute path for bgSWF URL, we recommend specifying relative path under the same domain.", Logger.LEVEL.ERROR);
			}
		}
		//Now load the logo for the chart.
		if (this.params.logoURL != "") {
			//Create the listeners for the loader first. We need to deal with error and finish
			//handlers only
			//Local reference to class
			var cr = this;
			this.logoMCListener.onLoadInit = function(target_mc:MovieClip) {
				//This listener is invoked when the logo has finished loading.
				//Set the scale first, as position will then depend on scale
				target_mc._xscale = cr.params.logoScale;
				target_mc._yscale = cr.params.logoScale;
				//Now position the loader's container movie clip as per
				//the position specified in XML.
				switch(cr.params.logoPosition.toUpperCase()) {
					case "TR":
					target_mc._x = cr.x + cr.width - target_mc._width - cr.params.borderThickness;
					target_mc._y = cr.y + cr.params.borderThickness;
					break;
					case "BR":
					target_mc._x = cr.x + cr.width - target_mc._width - cr.params.borderThickness;
					target_mc._y = cr.y + cr.height - target_mc._height - cr.params.borderThickness;
					break;
					case "BL":
					target_mc._x = cr.x + cr.params.borderThickness;
					target_mc._y = cr.y + cr.height - target_mc._height - cr.params.borderThickness;
					break;
					case "CC":
					target_mc._x = cr.x + (cr.width/2) - (target_mc._width/2);
					target_mc._y = cr.y + (cr.height/2) - (target_mc._height/2);
					break;
					default:
					//Also handles TL
					target_mc._x = cr.x + cr.params.borderThickness;
					target_mc._y = cr.y + cr.params.borderThickness;
					break;
				}
				//Also, we apply the alpha.
				target_mc._alpha = cr.params.logoAlpha;
				//Set the link, if needed.
				if (cr.params.logoLink != "") {
					target_mc.useHandCursor = true;
					target_mc.onRelease = function() {
						cr.invokeLink(cr.params.logoLink);
					}
				}
			}
			this.logoMCListener.onLoadError = function(target_mc:MovieClip, errorCode:String, httpStatus:Number) {
				//This event indicates that there was an error in loading the logo.
				//So, we just log to the logger.
				cr.log ("Logo not loaded", "The logo could not be loaded. Please check that the path for logo specified in XML is valid and refers to the same sub-domain as this chart. Else, there could be network problem.", Logger.LEVEL.ERROR);
			}
			//Add the listener to loader
			this.logoMCLoader.addListener(this.logoMCListener);
			//Now, load the logo
			this.logoMCLoader.loadClip(this.params.logoURL, this.logoMC);
		}
	}
	/**
	* drawClickURLHandler method draws the rectangle over the chart
	* that responds to click URLs. It draws only if clickURL has been
	* defined for the chart.
	*/
	private function drawClickURLHandler():Void{
		//Check if it needs to be created
		if (this.params.clickURL != ""){
			//Create a new movie clip container for background
			var clickMC = this.cMC.createEmptyMovieClip("ClickURLHandler", this.dm.getDepth ("CLICKURLHANDLER"));
			clickMC.moveTo (0, 0);
			//Set fill with 0 alpha
			clickMC.beginFill (0xffffff, 0);
			//Draw the rectangle
			clickMC.lineTo (this.width, 0);
			clickMC.lineTo (this.width, this.height);
			clickMC.lineTo (0, this.height);
			clickMC.lineTo (0, 0);
			//End Fill
			clickMC.endFill();
			clickMC.useHandCursor = true;
			//Set click handler
			var strLink:String = this.params.clickURL;
			var chartRef:Chart = this;
			clickMC.onMouseDown = function(){
				chartRef.invokeLink (strLink);
			}
			clickMC.onRollOver = function(){
				//Empty function just to show hand cursor
				//Necessary, else, it wouldn't show hand cursors
				//for areas that have other links on the chart.
			}
		}
	}
	/**
	 * invokeLink method of the chart is a re-direction function
	 * to Utils.invokeLink.
	 *	@param	strLink		Link to be invoked.
	*/
	private function invokeLink(strLink:String):Void{
		Utils.invokeLink(strLink, this);
	}
	// -------------- APIs for external consumption ------------------//
	/**
	 * isAnimated method indicates whether the chart is in animation mode.
	 *	@return		Whether the chart is in animation mode?
	*/
	public function isAnimated():Boolean{
		return this.params.animation;
	}
	/**
	 * Returns whether the chart has to register with JS
	 * @return	Whether the chart is registered with JS
	 */
	public function registeredWithJS():Boolean {
		return this.registerWithJS;
	}
	// ---------- GENERIC TOOL-TIP RENDERER METHODS ---------//
	/**
	* setToolTipParam method sets the parameter for tool tip.
	*/
	private function setToolTipParam ()
	{
		//Get the style object for tool tip
		var tTipStyleObj : Object = this.styleM.getTextStyle (this.objects.TOOLTIP);
		this.tTip.setParams (tTipStyleObj.font, tTipStyleObj.size, tTipStyleObj.color, tTipStyleObj.bgColor, tTipStyleObj.borderColor, tTipStyleObj.isHTML, this.params.showToolTipShadow);
	}
	/**
	 * Shows the tooltip for any arbitrary object on the chart.
	 * This method is mostly called by delegates, and as such the
	 * tool-text is contained in tooltext property of the delegated
	 * function.
	 */
	private function showToolTip():Void {
		//The text to be shown as tooltip is contained as tooltext.
		var strToolText : String = arguments.caller.toolText;
		//Set tool tip text
		this.tTip.setText (strToolText);
		//Show the tool tip
		this.tTip.show ();
	}
	/**
	 * When the tooltip is being shown at the chart level, this method
	 * repositions the same (if visible).
	 */
	private function repositionToolTip():Void {
		//Reposition the tool tip only if it's in visible state
		if (this.tTip.visible ())
		{
			this.tTip.rePosition ();
		}
	}
	/**
	 * Hides the tooltip when it's no more required.
	 */
	private function hideToolTip():Void {
		//Hide the tool tip
		this.tTip.hide ();
	}
}
