 /**
* @class Logger
* @author InfoSoft Global (P) Ltd. www.fusioncharts.com / www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* Logger class helps us store a log of information related to
* the application. Whenever, an exception is generated in the
* application, instead of using throw statement, we add the error
* message to logger, as we do not want the user to see the error.
* The error should be shown only in debug mode to the developer
* who is developing the application using FusionCharts.
*
* The Logger class categorizes each message into these levels:
* INFO 	-	Information Message
*				Example: Chart Version, When data is retrieved, or
* 				what data is retrieved, version number.
* ERROR	- 	Error Message
*				Example: data could not be loaded, invalid character
* CODE		-	Any code that needs to be displayed to user
* LINK		- 	Link
*
* Movie Clip Structure
* LoggerMC -|
*			 |-Main -|
*					 |-tf (Text field)
*					 |-scrollMC (Scroll bar component)
*			 |-DebugMsg - Textbox containing the debug message
*/
import mx.utils.Delegate;
import com.fusioncharts.is.helper.FCEnum;
import com.fusioncharts.is.helper.ScrollBar;
//Color class - for choosing variations of color from single color
import com.fusioncharts.is.extensions.ColorExt;
class com.fusioncharts.is.helper.Logger 
{
	//Public Log Message LEVEL Enumeration
	public static var LEVEL : FCEnum;
	//Private variables
	//Array to store the log messages
	private var log : Array;
	//Boolean value to indicate whether the log is visible or not.
	private var logVisible : Boolean;
	//Chart width and height
	private var cWidth : Number;
	private var cHeight : Number;
	//Log width and co-ordinates
	private var lX : Number;
	private var lY : Number;
	private var lWidth : Number;
	private var lHeight : Number;
	//Text box width and co-ordinates
	private var tX : Number;
	private var tY : Number;
	private var tWidth : Number;
	private var tHeight : Number;
	//Text box padding
	private var tVPadding : Number = 15;
	private var tHPadding : Number = 15;
	//Scroll bar width
	private var scrollWidth : Number = 16;
	//Horizontal padding between the scroll bar and the textbox
	private var scrollPadding : Number = 3;
	//Switching properties
	private var allowSwitch:Boolean = true;
	private var switchChar:String = "D";
	//Title
	private var showTitle:Boolean = true;
	private var title:String = "Debug Mode";
	//Width and height percent
	private var wPercent:Number = 80;
	private var hPercent:Number = 70;
	//Cosmetic properties
	private var bgColor : Number = 0xFBFBFB;
	private var borderColor : Number = 0x999999;
	//Cosmetic Properties
	private var scrollBgColor:String =  "E2E2E2";
	private var scrollBarColor:String = "999999";
	private var scrollBtnColor:String = "666666";
	//Boolean value indicating whether the log has been drawn
	private var isDrawn : Boolean = false;
	//Flag to store whether we've to scroll to end after updating the display
	private var bScrollToEnd:Boolean = false;
	//Movie clip containers which contain the log visual elements
	private var logMC : MovieClip;
	//Sub-movies
	private var logMainMC : MovieClip;
	private var logDebugMsgTF : TextField;
	private var bgMC : MovieClip;
	private var tf : TextField;
	private var scrollMC : MovieClip;
	//Scroll bar
	private var logScrollBar : ScrollBar;
	//Iterator
	private var _iterator : Number;
	//Listener Object to listen to key
	private var objListener : Object;
	//Debugger state
	private var debuggerState : String;
	//Create a style sheet
	private var cssStyle;
	/**
	* Constructor function
	* @param	lMC				Reference to movieclip in which we'll draw the
	*							log elements.
	* @param	showInitially	Boolean value indicating whether we've to show
	*							the log initially or not.
	* @param	chartWidth		Total width of the chart
	* @param	chartHeight		Height of the chart
	*/
	function Logger (lMC : MovieClip, chartWidth : Number, chartHeight : Number)
	{
		//Store parameters in instance properties
		logMC = lMC;
		cWidth = chartWidth;
		cHeight = chartHeight;
		//Initialize our LEVEL enumeration
		LEVEL = new FCEnum("INFO", "ERROR", "CODE", "LINK");
		//Initialize log
		log = new Array ();
		//Initialize iterator
		_iterator = 0;
		//Initialize the style sheet
		this.cssStyle = new TextField.StyleSheet ();
		cssStyle.setStyle (".infoTitle", 
		{
			fontFamily : "Arial", fontSize : 11, color : "#005900", fontWeight : "normal", textDecoration : "none"
		});
		cssStyle.setStyle (".info", 
		{
			fontFamily : "Arial", fontSize : 11, color : "#333333", fontWeight : "normal", textDecoration : "none"
		});
		cssStyle.setStyle (".codeTitle", 
		{
			fontFamily : "Arial", fontSize : 11, color : "#005900", fontWeight : "normal", textDecoration : "none"
		});
		cssStyle.setStyle (".code", 
		{
			fontFamily : "Courier New", fontSize : 11, color : "#333333", marginLeft : 40, fontWeight : "normal", textDecoration : "none"
		});
		cssStyle.setStyle (".linkTitle", 
		{
			fontFamily : "Arial", fontSize : 11, color : "#005900", fontWeight : "normal", textDecoration : "none"
		});
		cssStyle.setStyle (".link", 
		{
			fontFamily : "Courier New", fontSize : 11, color : "#0000FF", fontWeight : "normal", textDecoration : "underline"
		});
		cssStyle.setStyle (".errorTitle", 
		{
			fontFamily : "Arial", fontSize : 11, color : "#CC0000", fontWeight : "normal"
		});
		cssStyle.setStyle (".error", 
		{
			fontFamily : "Arial", fontSize : 11, color : "#CC0000", fontWeight : "normal", textDecoration : "none"
		});
	}	
	/** 
	 * setParams method helps set the various configurable parameters of the logger.
	 * It over-rides the default values specified here-in. 
	 * This function should be called before the show method of the logger has 
	 * been called.
   */
   public function setParams(wPercent:Number, hPercent:Number, allowSwitch:Boolean, switchChar:String, showTitle:Boolean, title:String):Void{
	   //If the logger is already drawn, throw an error.
		if (isDrawn){
			throw new Error("You need to call setParams() method before invoking the show() method.");
			return;
		}
		//Store parameters
		this.wPercent = wPercent;
		this.hPercent = hPercent;
		this.allowSwitch = allowSwitch;
		this.switchChar = switchChar;
		this.showTitle = showTitle; 
		this.title = title;
   }
	/**
	 * setColor method sets the color for the logger. It accepts a single color
	 * and automatically chooses the rest of colors from the given color.
	 * This function should be called before the show method of the logger has 
	 * been called.
	*/
	public function setColor(strColor:String):Void{
		//If the logger is already drawn, throw an error.
		if (isDrawn){
			throw new Error("You need to call setColor() method before invoking the show() method.");
			return;
		}
		//Else, we need to get variations of the given color and store it in.
		this.bgColor = ColorExt.getLightColor(strColor,0.03); 
		this.borderColor = ColorExt.getDarkColor(strColor, 0.6); 
		//Cosmetic Properties
		this.scrollBgColor =  ColorExt.getLightColor(strColor,0.2).toString(16); 
		this.scrollBarColor = ColorExt.getDarkColor(strColor, 0.6).toString(16);
		this.scrollBtnColor = ColorExt.getDarkColor(strColor, 0.6).toString(16);
	}
	/**
	* show method shows the logger interface visually
	*/
	public function show () : Void 
	{
		//Update the visible flag
		logVisible = true;
		if ( ! isDrawn)	{
			//If the interface is not already drawn, draw it
			draw ();
		} else 	{
			//Else, just show the elements (previously hidden)
			logMainMC._visible = true;
		}
		//Update the log textbox to show the log messages recorded till
		//show() method was invoked.
		updateDisplay ();
		//Update title of log
		this.updateTitle();
	}
	/**
	* hide method hides the visual elements of log. But, the
	* debug message on the top stays.
	*/
	public function hide () : Void 
	{
		//Hide the movie clips
		logMainMC._visible = false;
		//Set the flag
		logVisible = false;
		//Update title of log
		this.updateTitle();
	}
	/**
	* draw method draws the log visual elements. This method is
	* to be called only once. Post which, show and hide log can be
	* called.
	*/
	private function draw () : Void 
	{
		//Calculate the log co-ordinates
		//Width is by default 80% of chart width
		//Height is by default 70% of chart height
		//Minimum values - width - 200 & Height - 125
		var wRatio : Number = cWidth * (wPercent/100);
		var hRatio : Number = cHeight * (hPercent/100);
		//Check for minimum values
		lWidth = (wRatio < 200) ? 200 : wRatio;
		lHeight = (hRatio < 125) ? 125 : hRatio;
		//Start position of the logger - center of screen
		lX = (cWidth - lWidth) / 2;
		lY = (cHeight - lHeight) / 2;
		//Now, start position and dimensions of the textbox
		tWidth = lWidth - ((2 * tHPadding) + scrollPadding + scrollWidth);
		tHeight = lHeight - (2 * tVPadding);
		tY = lY + tVPadding;
		tX = lX + tHPadding;
		//Create the movie clip containers
		logMainMC = logMC.createEmptyMovieClip ("Main", 1);
		logDebugMsgTF = logMC.createTextField ("DebugMsg", 2, 0, 0, cWidth, 0);
		bgMC = logMainMC.createEmptyMovieClip ("Bg", 1);
		tf = logMainMC.createTextField ("LogTF", 2, tX, tY, tWidth, tHeight);
		scrollMC = logMainMC.createEmptyMovieClip ("ScrollB", 3);
		//Draw the background
		bgMC.moveTo (lX, lY);
		bgMC.lineStyle (1, borderColor, 100);
		bgMC.beginFill (bgColor, 100);
		bgMC.lineTo (lX + lWidth, lY);
		bgMC.lineTo (lX + lWidth, lY + lHeight);
		bgMC.lineTo (lX, lY + lHeight);
		bgMC.lineTo (lX, lY);
		//Render the text-field properties
		tf.background = false;
		tf.border = false;
		tf.wordWrap = true;
		tf.multiline = true;
		tf.selectable = true;
		tf.html = true;
		tf.styleSheet = cssStyle;
		//Render the scroll bar
		logScrollBar = new ScrollBar (tf, scrollMC, tX + tWidth + scrollPadding, tY, scrollWidth, tHeight, this.scrollBgColor, this.scrollBarColor, this.scrollBtnColor);
		//Render the debug message if required
		if (this.allowSwitch && this.showTitle){
			//Forced check - we show bg only if it's debug mode
			if (this.title=="Debug Mode"){
				logDebugMsgTF.background = true;
				logDebugMsgTF.backgroundColor = 0xffffff;
			}
			logDebugMsgTF.border = false;
			logDebugMsgTF.selectable = false;
			logDebugMsgTF.wordWrap = true;
			logDebugMsgTF.autoSize = "left";
			logDebugMsgTF.html = true;
			logDebugMsgTF.fontFamily = "Verdana";
			//Set the text.
			logDebugMsgTF.htmlText = "<font face='Verdana' size='9'><B>" + this.title + ":</B> Click & press Shift + " + this. switchChar + " to hide.</font>";
		}
		//Create the key listener - if switching is allowed
		if (this.allowSwitch){
			//Add the listener object
			objListener = new Object ();
			//Delegate the onKeyDown event to alterLogVisibleState method of this class
			objListener.onKeyDown = Delegate.create (this, alterLogVisibleState);
			//Register the listener
			Key.addListener (objListener);
		}
		//Update the isDrawn flag
		isDrawn = true;
	}
	/**
	 * Scroll to end function scrolls the logger to the last scrollable view.
	 * This method needs to be called before record() method to show the last
	 * mesage too.
	*/
	public function scrollToEnd():Void{
		//Update flag that we've to scroll to end after update.
		this.bScrollToEnd = true;		
	}
	/**
	* record method adds a message to the log. It creates a generic object
	* and stores the level and log message.
	* We use object instead of a custom class (say LogMessage) to keep
	* overheads down, as the design is very simple here.
	*	@param	strMsg	Message to be added to the log.
	*	@param	level	Level of the message (from the LEVEL enumeration)
	*/
	public function record (strTitle : String, strMsg : String, level : Number)
	{
		//Create an object
		var logMessage : Object = new Object ();
		logMessage.title = strTitle;
		logMessage.msg = strMsg;
		logMessage.level = level;
		//Add the message to our log array
		this.log.push (logMessage);
		//Delete object
		delete logMessage;
		//If the log is visible, update display
		if (logVisible){
			updateDisplay ();
		}
	}
	/**
	* This method alters the visibility of the logger when the
	* user presses Shift + D.
	*/
	private function alterLogVisibleState () : Void 
	{
		//Do only if switching is allowed.
		if (this.allowSwitch && Key.isDown (Key.SHIFT) && Key.isDown (new String(this.switchChar).charCodeAt (0))){
			//Switch the visibility
			logMainMC._visible = ! logMainMC._visible;
			logVisible = logMainMC._visible;
			//Update title of the log
			this.updateTitle();
			//Also, update the display for any messages that might have been logged when invisible
			if (logVisible){				
				updateDisplay ();
			}
		}
	}
	/**
	 * updateTitle method updates the title of the logger. This is useful
	 * when the title visibility toggling is done through JS.
	*/
	private function updateTitle():Void{		
		//If logger title is to be shown (and switch is allowed), change it.
		if (this.showTitle && this.allowSwitch){
			debuggerState = (logVisible) ? "hide" : "show";
			logDebugMsgTF.htmlText = "<font face='Verdana' size='9'><B>" + this.title + ":</B> Click & press Shift + " + this. switchChar + " to " + debuggerState + ".</font>";
		}
	}
	/**
	* In this method, we add the log's message to the textbox
	* and update the iterator to the last message displayed.
	*/
	private function updateDisplay () : Void 
	{
		//This function adds the log messages to textbox.
		//Clone array to avoid overlapping at runtime - while another
		//message is being added to log.
		var logLength : Number = log.length;
		var msgQueue : String = tf.htmlText;
		for (var i : Number = _iterator; i < logLength; i ++)
		{
			switch (log [i].level)
			{
				case Logger.LEVEL.INFO :
				msgQueue = msgQueue + "<p><span class='infoTitle'>" + log [i].title + ": </span><span class='info'>" + log [i].msg + "</span></p>";
				break;
				case Logger.LEVEL.ERROR :
				msgQueue = msgQueue + "<p><span class='errorTitle'>" + log [i].title + ": </span><span class='error'>" + log [i].msg + "</span></p>";
				break;
				case Logger.LEVEL.CODE :
				msgQueue = msgQueue + "<p><span class='codeTitle'>" + log [i].title + ": </span><span class='code'>" + log [i].msg + "</span></p>";
				break;
				case Logger.LEVEL.LINK :
				msgQueue = msgQueue + "<p><span class='linkTitle'>" + log [i].title + ": </span><span class='link'>" + log [i].msg + "</span></p>";
				break;
			}
		}
		//Assign the text to textbox
		tf.htmlText = msgQueue;
		//Update iterator's index
		_iterator = logLength;
		//Now, if we've to scroll to end position, do so.
		if (this.bScrollToEnd){
			logScrollBar.scrollToEnd();
			//Automatically invalidated - as scrollToEnd contains invalidate.
			//Re-set flag
			this.bScrollToEnd = false;
		}else{
			//Else, simply invalidate the scroll bar
			//We have to do it manually - as textfield.onScroller is not invoked
			//when the text is changed using code.		
			logScrollBar.invalidate ();
		}
	}
	/**
	 * clear method clears the log history and visual display
	*/
	public function clear():Void{
		//Reset storage array
		this.log = new Array();
		//Reset iterator
		this._iterator = 0;
		//Update text field
		this.tf.htmlText = "";
		//Invalidate scroll bar
		logScrollBar.invalidate ();
	}
	/**
	* destroy method MUST be called whenever you wish to delete this class's
	* instance.
	*/
	public function destroy ()
	{
		//Delete containers
		delete this.log;
		delete this.cssStyle;
		//Remove listener.
		if (this.allowSwitch){
			Key.removeListener (objListener);
		}
		//Destroy scroll bar
		logScrollBar.destroy ();
		//Remove the movie clips
		bgMC.removeMovieClip ();
		tf.removeMovieClip ();
		scrollMC.removeMovieClip ();
		logMainMC.removeMovieClip ();
		logDebugMsgTF.removeMovieClip ();
	}
}
