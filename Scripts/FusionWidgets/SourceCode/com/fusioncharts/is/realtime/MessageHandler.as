/**
* @class MessageHandler
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd. 
* MessageHandler method helps us to receive, collect and handle
* messages sent from server to chart, in real-time. This module is
* responsible for everything related to such messages.
* Messages can come from server with the following information:
* - msgId - An identifier for recognization/pairing purpose.
* - msgTitle - Title of the message (to put in Message log as title)
* - msgText - Actual text of the message to display in log/alert.
* - msgType - Either INFO or ERROR or LITERAL.
* - msgAppendToLog - Whether to append this message to the log.
* - msgSendToJS - Whether to send the message to JS Handler.
*/
//Utilities
import com.fusioncharts.is.helper.Utils;
//Logger Class - Provides the visual UI for logger 
import com.fusioncharts.is.helper.Logger;
//External Interface - to expose methods via JavaScript
import flash.external.ExternalInterface;
class com.fusioncharts.is.realtime.MessageHandler {
	//Container movie clip that'll contain the visual UI of logger.
	private var targetMC:MovieClip;
	//Instance of logger class
	private var lgr:Logger;
	//Parent width and height (chart width and height)
	//We'll need to contain the visual UI within this width and height.
	private var parentWidth:Number;
	private var parentHeight:Number;
	//Whether to expose the methods to JS
	private var exposeToJS:Boolean;
	//What percentage of width and height to occupy?
	private var wPercent:Number = 80;
	private var hPercent:Number = 70;
	//Whether messages go into log?
	private var messageGoesToLog:Boolean;
	private var messageGoesToJS:Boolean;
	//JS Handler function
	private var messageJSHandler:String;
	private var messagePassAllToJS:Boolean;
	//Log Title
	private var showTitle:Boolean = true;
	private var logTitle:String = "Message Log";
	//Cosmetics
	private var logColor:String = "";
	//Count of messages received and to be logged.
	private var msgCount:Number = 0;
	//Internal flag to keep a track of whether parameters have been defined
	private var bParamsDefined:Boolean = false;
	//Shortcut to function names.
	private var getFV:Function;
	private var getFN:Function;
	/**
	 * Constructor function.
	 *	@param	targetMC		Parent movie clip in which we'll draw the visual UI of
	 *							the message log.
	 *	@param	parentWidth		Width of the parent movie clip (chart).
	 *	@param	parentHeight	Height of the parent movie clip (chart).
	 *	@param	exposeToJS		Whether to expose the methods to JS.
	 *	@return					Nothing
	*/
	function MessageHandler(targetMC:MovieClip, parentWidth:Number, parentHeight:Number, exposeToJS:Boolean) {
		//Get shortcut to functions
		this.getFV = Utils.getFirstValue;
		this.getFN = Utils.getFirstNumber;
		this.exposeToJS = exposeToJS;
		//Store parameters in instance variables
		this.targetMC = targetMC;
		this.parentWidth = parentWidth;
		this.parentHeight = parentHeight;
		//Create the logger
		this.lgr = new Logger (this.targetMC, this.parentWidth, this.parentHeight);
		//Expose the methods to JavaScript using ExternalInterface
		if (this.exposeToJS==true && ExternalInterface.available){
			//showLog method
			ExternalInterface.addCallback("showLog", this, showLog);
			//hideLog method
			ExternalInterface.addCallback("hideLog", this, hideLog);
			//clearLog method
			ExternalInterface.addCallback("clearLog", this, clearLog);
		}
	}
	/**
	 * setParams method conveys the parameters from the container module to this
	 * module. It's necessary to set the parameters before the module can take any
	*/
	public function setParams(wPercent:Number, hPercent:Number, showTitle:Boolean, logTitle:String, logColor:String, messageGoesToLog:Boolean, messageGoesToJS:Boolean, messageJSHandler:String, messagePassAllToJS:Boolean){
		//Store parameters in instance variables.
		//Validate range and then store.
		this.wPercent = (wPercent<20 || wPercent>99)?80:wPercent;
		this.hPercent = (hPercent<20 || hPercent>99)?70:hPercent;		
		this.showTitle = showTitle;
		this.logTitle = logTitle;
		this.logColor = logColor;
		this.messageGoesToLog = messageGoesToLog;
		this.messageGoesToJS = messageGoesToJS;
		this.messageJSHandler = messageJSHandler;
		this.messagePassAllToJS = messagePassAllToJS;		
		//Update internal flag that parameters are now defined.
		this.bParamsDefined = true;
		//Convey the parameters to logger
		this.lgr.setColor(this.logColor);
		this.lgr.setParams(this.wPercent, this.hPercent, true, "M", this.showTitle, this.logTitle);
	}	
	/**
	 * feedQS method is used to pass the loadvars content containing
	 * message details to this module. 
	 *	@param	dataLv		LoadVars object containing details of the messages.
	 *	@return				Nothing.
	*/
	public function feedQS(dataLv:LoadVars) {
		//We cannot accept feed until the parameters have been defined.
		if (!this.bParamsDefined){
			throw new Error("You cannot feed message data to this module until the parameters have been defined. Please use setParams() method of this module to define parameters.");
		}
		//We extract the parameters from loadvars.
		//----------- Begin Parsing --------------
		//First get them in an array in case insensitive format.
		var params:Array = Utils.getParamsArray(dataLv);
		var msgId:String = getFV(params["msgid"],"");
		var msgTitle:String = getFV(params["msgtitle"],"");
		var msgText:String = getFV(params["msgtext"],"");
		var msgType:String = getFV(params["msgtype"],"INFO");		
		var msgGoesToLog:Number = getFN(params["msggoestolog"],this.messageGoesToLog?1:0);
		var msgGoesToJS:Number = getFN(params["msggoestojs"],this.messageGoesToJS?1:0);
		//Whether to clear log
		var clearLog:Number = getFN(params["clearlog"],0);
		//Numeric representation of message type.
		var msgTypeId:Number;		
		//Validate message type
		msgType = msgType.toUpperCase();
		//Can be either INFO, ERROR, LITERAL or LINK
		if (msgType!="INFO" && msgType!="ERROR" && msgType!="LITERAL" && msgType!="LINK"){
			//Set default to INFO
			msgType = "INFO";
		}
		//Select message type numeric representation
		switch(msgType){
			case "INFO":
			msgTypeId = Logger.LEVEL.INFO;
			break;
			case "ERROR":
			msgTypeId = Logger.LEVEL.ERROR;
			break;
			case "LITERAL":
			msgTypeId = Logger.LEVEL.CODE;
			break;
			case "LINK":
			msgTypeId = Logger.LEVEL.LINK;
			//We also need to append the link HTML tags, if it's link.
			//We open the link in same window, as the user has the option
			//to right click on a link and open it in new window in Flash Player.
			msgText = "<A HREF='" + msgText + "'>" + msgText + "</A>";
			break;
			default:
			//Default to INFO
			msgTypeId = Logger.LEVEL.INFO;
		}		
		//----------- End Parsing --------------
		
		//----------- Begin Action --------------
		//If log is to be cleared, clear it before appending the current message.
		if (clearLog==1){
			this.lgr.clear();
		}		
		
		//Our condition of appending a message to the log is that message text
		//has been defined. Else, we ignore the entire message block.
		if (msgText!=""){
			//If the messgae is to be added to log.
			if(msgGoesToLog==1){
				//Increment count.
				this.msgCount++;
				//If it's the first message that we've recorded, we need to make
				//the logger visible too
				if (this.msgCount==1){
					this.lgr.show();
				}				
				//Scroll to the end of logger - so that the last message is visible
				//scrollToEnd needs to be called before record() to scroll to last.
				this.lgr.scrollToEnd();
				//Log the message
				this.lgr.record(msgTitle, msgText, msgTypeId);				
			}
			//If the message needs to invoke a JS API
			if (msgGoesToJS==1){
				//Build the JS call str
				var strJSCall:String = "javascript:"+this.messageJSHandler+"(";
				//Now, we appended parameters, depending on whether we've to append all or just text
				if (this.messagePassAllToJS){
					//In order: Id, Title, Text, Type
					strJSCall = strJSCall + "'" + msgId+ "','" + msgTitle + "','" + msgText + "','" + msgType + "');";
				}else{
					strJSCall = strJSCall + "'" + msgText + "');";
				}
				//Invoke
				getURL(strJSCall,"_self");
			}
		}		
		//----------- End Action --------------
		//Clear up
		delete params;
	}
	/**
	 * showLog method shows the log. Exposed to JS.
	*/
	public function showLog():Void{
		this.lgr.show();
	}
	/**
	 * hideLog method hides the log. Exposed to JS.
	*/
	public function hideLog():Void{
		this.lgr.hide();
	}
	/**
	 * clearLog method clears the log. Exposed to JS.
	*/ 
	public function clearLog():Void{
		this.lgr.clear();
	}
	/**
	 * destroy method kills the instances of this class.
	*/
	public function destroy(){
		//Set msgCount to 0 again
		this.msgCount = 0;
		//Destroy the logger
		this.lgr.destroy ();
	}
}
