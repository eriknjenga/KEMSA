/**
* @class FCError
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* FCError class extends the Error class so that we can
* handle our own exceptions with the level of granulity
* required.
*/
class com.fusioncharts.is.helper.FCError extends Error {
	//Error name
	var name:String;
	//Detailed message
	var message:String;
	//Level of error
	var level:Number;
	/**
	* Constructor method which creates the error.
	*/
	function FCError(name:String, message:String, level:Number) {
		//Call Super class
		super(message);
		//Store in instance variables
		this.name = name;
		this.message = message;
		this.level = level;
	}
}
