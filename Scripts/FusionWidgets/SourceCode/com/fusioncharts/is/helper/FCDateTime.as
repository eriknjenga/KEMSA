/**
 * @class FCDateTime
 * @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com / www.fusioncharts.com
 * @version 3.0
 *
 * Copyright (C) InfoSoft Global Pvt. Ltd.
 *
 * FCDateTime class helps manipulate date and time quantities
 * easily using the methods exposed.
 *
 * We use the Julian Day Number to store serial for the dates. 
 * The Julian day or Julian day number (JDN) is the (integer) number of 
 * days that have elapsed since noon Greenwich Mean Time (UT or TT) Monday, 
 * January 1, 4713 BC in the proleptic Julian calendar [1]. That noon-to-noon 
 * day is counted as Julian day zero. Thus the multiples of 7 are Mondays. 
 * Negative values can also be used. 
 * Astronomical year numbering is used, thus 1 BC is 0, 2 BC is −1, and 4713 BC is −4712.
 * The day of the week can be determined from the Julian day number by calculating 
 * it modulo 7, where 0 means Monday.
 * Deviations in this class:
 * - We do not use 0.5 for noon calculation. 
 * - For indexing week, we use ISO 8601 standard where 1 means Monday and 7 Sunday.
 * - For time, we use a 24 hour clock. If time is not specified for
 * - a certain date, we set it as 00:00:00.
 * Also, the first week of the year is the week containing Thursday. 
*/
import com.fusioncharts.is.extensions.StringExt;
import com.fusioncharts.is.helper.Utils;
class com.fusioncharts.is.helper.FCDateTime {
	//Static variable to store the dateFormat.
	private static var dateFormat:String;
	//Date format for output date.
	private static var dateOFormat:String;
	//Static variables to store current date and time
	private static var currentDate:Date = new Date();
	private static var currentDay:Number = FCDateTime.currentDate.getUTCDate();
	private static var currentMonth:Number = FCDateTime.currentDate.getUTCMonth() + 1;
	private static var currentYear:Number = FCDateTime.currentDate.getUTCFullYear();
	//Static variable to store dayNames
	private static var dayNames:Array = new Array("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday");
	//Staic variable to store month namse
	private static var monthNames:Array = new Array("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");
	//Day Suffix for days
	private static var daySuffix:Array = new Array("","st","nd","rd","th","th","th","th","th","th","th","th","th","th","th","th","th","th","th","th","th","st","nd","rd","th","th","th","th","th","th","th","st");
	//Instance variables to store day, month, year
	private var day:Number;
	private var month:Number;
	private var year:Number;
	//Instances variables to store hour, minute, seconds
	private var hour:Number;
	private var min:Number;
	private var sec:Number;
	//Flags to indicate whether both date and time have been
	//specified by the user.
	private var dateGiven:Boolean = false;
	private var timeGiven:Boolean = false;
	//Serial number of this date. Serial number is stored
	//as dddddd.tttttt (fractional) w.r.t epoch.
	private var serial:Number = 0;
	//Short reference to Utils.getFirstNumber
	private var getFN:Function;
	/**
	 * Constructor function. Here, we can either accept the date time as a 
	 * single string and store it. Or, we can accept all the 6 different units
	 * and then store them.
	 
	 *	@param	strDateTime	String containing the date and time, that
	 *						we've to store in instance of this class.
	 *						Date separator can be in 2 formats:
	 *						dd/mm/yyyy hh:mm:ss
	 *						dd-mm-yyyy hh:mm:ss
	 *						Additionally, the user may opt not to specify
	 *						time at all.
	 *	@param				Y,m,d,h,mn,s as parameters.
	*/
	function FCDateTime() {
		//First check if date format has been set
		if (FCDateTime.dateFormat == undefined) {
			throw new Error("Error: You need to set the date format using static function setDateFormat, before creating an instance of this class.");
		}
		//Create short reference to Utils.getFirstNumber (for repeated use)    
		this.getFN = Utils.getFirstNumber;
		//If we've been passed only 1 parameter, it means the string
		//has been given
		if (arguments.length == 1) {
			//We need to parse the given date time string and store it in
			//instance variables.
			this.parseDateTime(arguments[0]);
		} else {
			//Directly store y,m,d,h,mn,s into local variables
			//In this case we assume that numeric values have been given
			//for all the 6 parameters (or 00 replacement).
			this.year = arguments[0];
			this.month = arguments[1];
			this.day = arguments[2];
			this.hour = arguments[3];
			this.min = arguments[4];
			this.sec = arguments[5];
			//Update dateGiven and timeGiven flags?
			this.dateGiven = true;
			if (!(this.hour == 0 && this.min == 0 && this.sec == 0)) {
				this.timeGiven = true;
			} else {
				this.timeGiven = false;
			}
		}
		//Now, convert the date time into serial
		this.convertToSerial();
	}
	/**
	 * Static function that will help set the date format for all
	 * the dates to be initialized later. This function should be 
	 * called initially - before initializing any instance of this
	 * class.
	 *	@param	strFormat	Format in which dates can be specified.
	 *						Possible Values: 
	 *						dd/mm/yyyy or dd-mm-yyyy or dd,mm,yyyy or dmy
	 *						mm/dd/yyyy or mm-dd-yyyy or mm,dd,yyyy or mdy
	 *						yyyy/mm/dd or yyyy-mm-dd or yyyy,mm,dd or ymd
	 *	@param	strOFormat	Format in which dates are outputted.
	*/
	public static function setDateFormat(strFormat:String, strOFormat:String):Void {
		//Check whether the date format is in valid format
		//Convert to lower case
		strFormat = strFormat.toLowerCase();
		strOFormat = strOFormat.toLowerCase();
		//Store output format
		FCDateTime.dateOFormat = strOFormat;
		//Remove any spaces from the same.
		strFormat = StringExt.removeSpaces(strFormat);
		//Store the date format now based on input
		switch (strFormat) {
		case "dd/mm/yyyy" :
		case "dd-mm-yyyy" :
		case "dd,mm,yyyy" :
		case "dmy" :
			FCDateTime.dateFormat = "dmy";
			break;
		case "mm/dd/yyyy" :
		case "mm-dd-yyyy" :
		case "mm,dd,yyyy" :
		case "mdy" :
			FCDateTime.dateFormat = "mdy";
			break;
		case "yyyy/mm/dd" :
		case "yyyy-mm-dd" :
		case "yyyy,mm,dd" :
		case "ymd" :
			FCDateTime.dateFormat = "ymd";
			break;
		default :
			//Set default as dmy
			FCDateTime.dateFormat = "dmy";
			break;
		}
	}
	// ------------ PRIVATE FUNCTIONS FOR VARIOUS TASKS ---------
	/**
	 * parseDateTime method parses the passed date/time string
	 * and stores it in local variables. It also checks for the 
	 * validity of date and time passed to it. 
	 * The user can either specify date or time or both. If no time
	 * is specified, we assume it as 00:00:00 (midnight) of that date.
	 * If no date is specified, we assume serial as 0. So date becomes
	 * epoch.
	 *	@param	strDateTime	Date and time specified as a string in
	 *						the specified date format. Time will be
	 *						specified in hh:mm:ss format in 24 hr format.
	*/
	private function parseDateTime(strDateTime:String):Void {
		//We first need to check if the dates are separated by - (hyphen)
		//If yes, we convert them to / (slash) for uniformity
		if (strDateTime.indexOf("-") != -1) {
			strDateTime = StringExt.replace(strDateTime, "-", "/");
		}
		//Split the string on basis of space - to separate date and time          
		var tokens:Array = new Array();
		tokens = strDateTime.split(" ");
		//We now need to find whether the user has given us both date
		//and time. We iterate through each element of array and search
		//for / (for date) and : (for time).
		var i:Number = 0;
		var dateTokenIndex:Number = -1;
		var timeTokenIndex:Number = -1;
		for (i=0; i<tokens.length; i++) {
			if (tokens[i].indexOf("/") != -1) {
				dateGiven = true;
				dateTokenIndex = i;
				break;
			}
		}
		//Do the same for time
		for (i=0; i<tokens.length; i++) {
			if (tokens[i].indexOf(":") != -1) {
				timeGiven = true;
				timeTokenIndex = i;
				break;
			}
		}
		//Now, we need to parse the date and time and store in
		//instance variables.
		if (dateGiven) {
			//Remove spaces from date token
			tokens[dateTokenIndex] = StringExt.removeSpaces(tokens[dateTokenIndex]);
			//Split this date token into sub-array
			var dateTokens:Array = new Array();
			dateTokens = tokens[dateTokenIndex].split("/");
			//We need to store the day, month and year into diff vars
			//based on the date format specified by user
			switch (FCDateTime.dateFormat) {
			case "dmy" :
				day = getFN(dateTokens[0], FCDateTime.currentDay);
				month = getFN(dateTokens[1], FCDateTime.currentMonth);
				year = getFN(dateTokens[2], FCDateTime.currentYear);
				break;
			case "mdy" :
				day = getFN(dateTokens[1], FCDateTime.currentDay);
				month = getFN(dateTokens[0], FCDateTime.currentMonth);
				year = getFN(dateTokens[2], FCDateTime.currentYear);
				break;
			case "ymd" :
				day = getFN(dateTokens[2], FCDateTime.currentDay);
				month = getFN(dateTokens[1], FCDateTime.currentMonth);
				year = getFN(dateTokens[0], FCDateTime.currentYear);
				break;
			}
			//Do conditional checks on day, month and year
			//Day cannot be greater than 31
			day = (day>31) ? 31 : day;
			//Month cannot be greater than 12
			month = (month>12) ? 12 : month;
			//Now, if 2 digits have been specified for year, we'll
			//add 19xx or 20xx to the same depending on the feasible date.
			//I.e., if 2000 + year > current year, we add 1900 to it
			if (year<100) {
				//2 Digit year specified
				if ((2000+year)>FCDateTime.currentYear) {
					year = 1900+year;
				} else {
					year = 2000+year;
				}
			}
			//Check for days in month - restrict to ceiling limit for each month.    
			var daysInMn:Array = this.getDaysInMonth(this.year);
			if (day>daysInMn[month] || day<1) {
				throw new Error("Invalid number of days specified in the month.");
			}
		} else {
			day = 0;
			month = 0;
			year = 0;
		}
		//Now, if time is given, store it
		if (timeGiven) {
			//Remove spaces from time token
			tokens[timeTokenIndex] = StringExt.removeSpaces(tokens[timeTokenIndex]);
			//Split this date token into sub-array
			var timeTokens:Array = new Array();
			timeTokens = tokens[timeTokenIndex].split(":");
			//Store the time in different variables
			hour = getFN(timeTokens[0], 0);
			min = getFN(timeTokens[1], 0);
			sec = getFN(timeTokens[2], 0);
			//Conditional checks on hour min and sec - we follow 24 hr clock			
			//Hour can be 24 only if min and sec are 0
			hour = (hour>23) ? ((hour==24 && min==0 && sec==0)?hour:23) : (hour);
			min = (min>59) ? 59 : min;
			sec = (sec>59) ? 59 : sec;			
		} else {
			hour = 0;
			min = 0;
			sec = 0;
		}
	}
	/**
	 * convertToSerial method converts the given date time into a serial
	 * value. 
	 * Serial number stores dates and times as JDN.tttttt
	 * The integer portion of the number, JDN, represents the Julian Day Number.
	 * 
	 * The integer portion of the number, tttttt, represents the fractional portion of a 
	 * 24 hour day.  For example, 6:00 AM is stored as 0.25, or 25% of a 24 hour day.  
	 * Similarly, 6PM is stored at 0.75,  or 75% percent of a 24 hour day.  
	*/
	private function convertToSerial():Void {
		//If date is given
		if (dateGiven) {
			var mDiv:Number = (month<=2) ? -1 : 0;
			this.serial = Math.floor((1461*(year+4800+mDiv))/4)+Math.floor((367*(month-2-12*(mDiv))/12))-Math.floor((3*(Math.floor((year+4900+mDiv)/100)))/4)+day-32075;
		}
		//Now, add time (if given)     
		if (timeGiven) {
			this.serial += ((hour*3600)+(min*60)+sec)/86400;
		}
	}
	/**
	 * serialToObj function converts the serial number of a date
	 * to y,m,d,h,m,s format and returns as object.
	 *	@param	s	Serial Number of Date
	 *	@return		Object containing y,m,d,h,mn,s
	*/
	private function serialToObj(s:Number):Object {
		//To avoid using decimal fractions, the code uses multiples.
		//Rather than use 365.25 days per year, 1461 is the number of days
		//in 4 years; similarly, 146097 is the number of days in 400 years
		var cDay:Number = Math.floor(s)-1721119;
		var cCenturies:Number = Math.floor((4*cDay-1)/146097);
		cDay = cDay+cCenturies-Math.floor(cCenturies/4);
		var rYear:Number = Math.floor((4*cDay-1)/1461);
		cDay = cDay-Math.floor((1461*rYear)/4);
		var rMonth:Number = Math.floor((10*cDay-5)/306);
		var rDay:Number = cDay-Math.floor((306*rMonth+5)/10);
		rMonth = rMonth+2;
		rYear = rYear+Math.floor(rMonth/12);
		rMonth = rMonth%12+1;
		//Convert time to hours, minutes, seconds
		var tSec:Number = Math.round((s-Math.floor(s))*86400);
		var rSec:Number = tSec%60;
		var tMin:Number = (tSec-rSec)/60;
		var rMin:Number = tMin%60;
		var rHour:Number = (tMin-rMin)/60;
		//Return Object
		var rtnObj:Object = new Object();
		rtnObj.y = rYear;
		rtnObj.m = rMonth;
		rtnObj.d = rDay;
		rtnObj.h = rHour;
		rtnObj.mn = rMin;
		rtnObj.s = rSec;
		//Return it now
		return rtnObj;
	}
	/**
	 * serialToDate function converts the serial number of a date
	 * to y,m,d,h,m,s format and returns as a date instance.
	 *	@param	s	Serial Number of Date
	 *	@return		Instance of FCDateTime Class
	*/
	private function serialToDate(s:Number):FCDateTime {
		//Get the object with date properties
		var dateObj:Object = this.serialToObj(s);
		//Return a date time instance
		return new FCDateTime(dateObj.y, dateObj.m, dateObj.d, dateObj.h, dateObj.mn, dateObj.s);
	}
	/**
	 * buildDateTimeStr method builds a date time string in the specified
	 * output date format and returns it.
	 *	@param		y		Year part of the date
	 *	@param		m		Month part of the date
	 *	@param		d		Day part of the date
	 *	@param		h		Hour part of the date
	 *	@param		mn		Minutes part of the date
	 *	@param		s		Seconds part of the date
	 *	@return				String representation of the date in required format.
	*/
	private function buildDateTimeStr(y:Number, m:Number, d:Number, h:Number, mn:Number, s:Number):String {
		//To build the output date, we simply replace tokens in this.dateOFormat
		var oDate:String = FCDateTime.dateOFormat;
		//We can have the following tokens (in order of parsing):
		// - mnl - Month name (long)
		// - mns - Month name (short)
		// - dnl - Day name (long)
		// - dns - Day name (short)
		// - dd - Day
		// - ds - Day suffix
		// - mm - Month
		// - yyyy - Year (4 digits)
		// - yy - Year (2 digits)
		// - ampm - Whether AM or PM?
		// - hh12 - Hour (based on 12 hr clock)
		// - hh - Hour
		// - mn - Minute
		// - ss - Seconds		
		//Replace date tokens only if we've to manipulate for date.
		if (dateGiven) {			
			if (oDate.indexOf("mnl")!=-1){
				//Long Month Name
				oDate = StringExt.replace(oDate,"mnl",this.monthName(m, false));
			}
			if (oDate.indexOf("mns")!=-1){
				//Short Month Name
				oDate = StringExt.replace(oDate,"mns",this.monthName(m, true));
			}
			if (oDate.indexOf("dnl")!=-1){
				//Long Day Name
				oDate = StringExt.replace(oDate,"dnl",this.dayName(false));
			}
			if (oDate.indexOf("dns")!=-1){
				//Short Day Name
				oDate = StringExt.replace(oDate,"dns",this.dayName(true));
			}
			if (oDate.indexOf("dd")!=-1){
				//Day
				oDate = StringExt.replace(oDate,"dd",String(d));
			}
			if (oDate.indexOf("mm")!=-1){
				//Month
				oDate = StringExt.replace(oDate,"mm",String(m));
			}
			if (oDate.indexOf("yyyy")!=-1){
				//Year - 4 digits
				oDate = StringExt.replace(oDate,"yyyy",String(y));
			}
			if (oDate.indexOf("yy")!=-1){
				//Year - 2 digits
				oDate = StringExt.replace(oDate,"yy",String(y).substr(2,2));
			}
			if (oDate.indexOf("ds")!=-1){
				//Day Suffix
				oDate = StringExt.replace(oDate,"ds",FCDateTime.daySuffix[d]);
			}
		}else{
			//Replace the date blocks with empty string
			oDate = StringExt.replace(oDate,"mnl","");
			oDate = StringExt.replace(oDate,"mns","");
			oDate = StringExt.replace(oDate,"dnl","");
			oDate = StringExt.replace(oDate,"dns","");
			oDate = StringExt.replace(oDate,"dd","");
			oDate = StringExt.replace(oDate,"mm","");
			oDate = StringExt.replace(oDate,"yyyy","");
			oDate = StringExt.replace(oDate,"yy","");
			oDate = StringExt.replace(oDate,"ds","");
			oDate = StringExt.replace(oDate,"/","");
		}
		if (timeGiven) {
			if (oDate.indexOf("ampm")!=-1){
				//AM or PM?
				oDate = StringExt.replace(oDate,"ampm",(h>=12)?"PM":"AM");
			}
			if (oDate.indexOf("hh12")!=-1){
				//Hours - 12 hours clock
				oDate = StringExt.replace(oDate,"hh12", padValue((h==12)?(12):(h%12)));
			}
			if (oDate.indexOf("hh")!=-1){
				//Hours - 24 hours clock
				oDate = StringExt.replace(oDate,"hh", padValue(h));
			}
			if (oDate.indexOf("mn")!=-1){
				//Minute
				oDate = StringExt.replace(oDate,"mn", padValue(mn));
			}
			if (oDate.indexOf("ss")!=-1){
				//Seconds
				oDate = StringExt.replace(oDate,"ss", padValue(s));
			}
		}else{
			//Replace any time token with empty string
			oDate = StringExt.replace(oDate,"ampm","");
			oDate = StringExt.replace(oDate,"hh12","");
			oDate = StringExt.replace(oDate,"hh", "");
			oDate = StringExt.replace(oDate,"mn", "");
			oDate = StringExt.replace(oDate,"ss", "");
		}
		return oDate;
	}
	/**
	 * padValue method adds zero padding to given date/time value.
	 *	@param	token	Token to add padding to
	 *	@return			Token with padding added to it.
	*/
	private function padValue(token:Number):String {
		var pToken:String = (token<10) ? ("0"+String(token)) : String(token);
		return pToken;
	}
	/**
	 * getDaysInMonth function returns the number of days in each month
	 * for the given year as an array.
	 *	@param	year	Year.
	 *	@return			Array containing number of days in each month of year.
	 *					Additional element (first one) has been added as 0 to
	 *					keep simple index of 1-12 instead of 0-11.
	*/
	private function getDaysInMonth(year:Number):Array {
		//If it's a leap year 
		if (isLeapYear(year)) {
			return new Array(0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
		} else {
			return new Array(0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
		}
	}
	/**
	 * resetTime method resets the time of this date.
	 *	@param	updateSerial	Whether to update serial after resetting time.
	*/
	private function resetTime(updateSerial:Boolean):Void {
		this.hour = 0;
		this.min = 0;
		this.sec = 0;
		if (updateSerial) {
			this.convertToSerial();
		}
	}
	// ------- PUBLIC DATE/TIME MANIPULATION FUNCTIONS ------- //
	/**
	 * getSerial Method returns the serial value of this date.
	 *	@return		Returns the serial JDN.tttt index of this date.
	*/
	public function getSerial():Number {
		return this.serial;
	}
	/**
	 * getDate method returns just the date part of this date.
	 *	@return		Date part (numerical value of this date).
	*/
	public function getDate():Number {
		return this.day;
	}
	/**
	 * getMonth method returns the month index of this date. 
	 *	@return		Month (numerical) of this date. Range is 1-12.
	*/
	public function getMonth():Number {
		return this.month;
	}
	/**
	 * getYear method returns the year of this date. 
	 *	@return		Year of this date.
	*/
	public function getYear():Number {
		return this.year;
	}
	/**
	 * getQuarter method returns the quarter for this date.
	 *	@return		Quarter of this date.
	*/
	public function getQuarter():Number {
		return (int((this.month-1)/3)+1);
	}
	/**
	 * getHours method returns the hours of this date/time. 
	 *	@return		Hours of this date/time.
	*/
	public function getHours():Number {
		return this.hour;
	}
	/**
	 * getMinutes method returns the minutes of this date/time. 
	 *	@return		Minutes of this date/time.
	*/
	public function getMinutes():Number {
		return this.min;
	}
	/**
	 * getSeconds method returns the seconds of this date/time. 
	 *	@return		Seconds of this date/time.
	*/
	public function getSeconds():Number {
		return this.sec;
	}
	/**
	 * toString method gets the textual representation of the date
	 * in the same format as input format.
	 *	@return		String representation of this date in the same format
	 *				as input format.
	*/
	public function toString():String {
		return this.buildDateTimeStr(this.year, this.month, this.day, this.hour, this.min, this.sec);
	}
	/**
	 * isLeapYear method helps us check whether the given year is
	 * a leap year
	 *	@param	year Year to check
	 *	@return		Boolean value indicating whether the year is a
	 *				leap year.
	*/
	public function isLeapYear():Boolean {
		if (arguments.length == 0) {
			//If we've to check whether the year of the class date is leap
			return (((this.year%4 == 0) && (this.year%100 != 0)) || (this.year%400 == 0));
		} else {
			//We've to check whether the passed date is leap year
			var year:Number = arguments[0];
			return (((year%4 == 0) && (year%100 != 0)) || (year%400 == 0));
		}
	}
	/**
	 * dayOfWeek method returns the index of day of week of this
	 * date. Monday represents 1 and Sunday 7
	 *	@return		Numerical index of the day of week of this date.
	*/
	public function dayOfWeek():Number {
		return ((Math.floor(this.serial)%7)+1);
	}
	/**
	 * dayName method returns the name of day for the given index (1-7)
	 * 1 represents Monday and 7 Sunday
	 *	@parameter	dayIndex	Index of the day
	 *	@return					String representation of day name.
	*/
	public function dayName():String {
		//If there is only 1 parameter given, we'll take dayIndex as that of
		//current date
		var dayIndex:Number;
		var useShortName:Boolean;
		if (arguments.length == 0) {
			//If both date and flag was not specified. 
			dayIndex = this.dayOfWeek();
			useShortName = false;
		} else if (arguments.length == 1) {
			//If date was not specified. Just useShortName flag was given.
			dayIndex = this.dayOfWeek();
			useShortName = arguments[0];
		} else {
			//If both day index and useShortName flag was given.
			dayIndex = arguments[0];
			useShortName = arguments[1];
		}
		//Force a definite value for useShortName.
		useShortName = (useShortName == undefined) ? true : useShortName;
		//Subtract index by 1 as array is 0 index based
		dayIndex--;
		if (useShortName) {
			return (FCDateTime.dayNames[dayIndex].substring(0, 3));
		} else {
			return (FCDateTime.dayNames[dayIndex]);
		}
	}
	/**
	 * monthName method returns the name of month for the given index (1-12)
	 *	@parameter	monthIndex	Index of the month
	 *	@return					String representation of month name.
	*/
	public function monthName():String {
		//If there is only 1 parameter given, we'll take month Index as that of
		//current date
		var monthIndex:Number;
		var useShortName:Boolean;
		if (arguments.length == 0) {
			//If both month and flag was not specified. 
			monthIndex = this.month;
			useShortName = false;
		} else if (arguments.length == 1) {
			//If month was not specified. Just useShortName flag was given.
			monthIndex = this.month;
			useShortName = arguments[0];
		} else {
			//If both month index and useShortName flag was given.
			monthIndex = arguments[0];
			useShortName = arguments[1];
		}
		//Force a definite value for useShortName.
		useShortName = (useShortName == undefined) ? true : useShortName;
		//Subtract index by 1 as array is 0 index based
		monthIndex--;
		if (useShortName) {
			return (FCDateTime.monthNames[monthIndex].substring(0, 3));
		} else {
			return (FCDateTime.monthNames[monthIndex]);
		}
	}
	/**
	 * dayOfYear method returns the index of the day w.r.t year.
	*/
	public function dayOfYear():Number {
		//Cumulative days in each month of year
		var mnthIndex:Array = new Array(0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334);
		var dayNum = this.day+mnthIndex[this.month];
		if (this.isLeapYear() && (this.month>2)) {
			dayNum++;
		}
		return dayNum;
	}
	/**
	 * jan1WeekDay method returns what week day Jan 1 was of this year
	 * (or the year specified as parameter).
	 *	@return	Index 1 (Monday) - 7(Sunday) for the given weekday of
	 *				Jan 1 of the year.
	*/
	public function jan1WeekDay():Number {
		//First, check if year has been specified as parameter.
		if (arguments.length == 1) {
			//Assume year as that specified
			var y:Number = arguments[0];
		} else {
			//Take year as that of the class date
			var y:Number = this.year;
		}
		var yy:Number = (y-1)%100;
		var c:Number = (y-1)-yy;
		var g:Number = yy+Math.floor(yy/4);
		var rtnVal:Number = 1+((((Math.floor(c/100)%4)*5)+g)%7);
		//1 is Monday and 7 is Sunday
		return rtnVal;
	}
	/**
	 * weekOfYear method returns the index of the week depending on
	 * the date. It can be 1-53. We're use ISO 8601 date standard here.
	 * ISO 8601 standards defines a week as the the week with the year's 
	 * first Thursday in it. Or, the week with January 4 in it. So,
	 * If 1 January is on a Monday, Tuesday, Wednesday or Thursday, it is 
	 * in week 01. If 1 January is on a Friday, Saturday or Sunday, it is 
	 * in week 52 or 53 of the previous year. 
	 *	@return		Week index (1-53) for the given date in this year,
	 *				or previous year or next year.
	*/
	public function weekOfYear():Number {
		//Floor the serial to remove time factor.
		var serial:Number = Math.floor(this.serial);
		var d4:Number = (((serial+31741-(serial%7))%146097)%36524)%1461;
		var l:Number = Math.floor(d4/1460);
		var d1:Number = ((d4-l)%365)+l;
		var wkNum:Number = Math.floor(d1/7)+1;
		return wkNum;
	}
	/**
	 * add function lets us add days, months or years to the given date.
	 * Negative values do the opposite (i.e., subtract them).
	 *	@param	interval	The interval you want to add. Can take the following values:
	 *						y - Year 
	 *						q - Quarter 
	 *						m - Month 
	 *						w - Week
	 *						d - Day 
	 *						h - Hour 
	 *						n - Minute 
	 *						s - Second 
	 *	@param	num			The number of interval you want to add. Can either be positive, 
	 *						for dates in the future, or negative, for dates in the past
	 *	@return				Reference of self.
	*/
	public function add(interval:String, num:Number):FCDateTime {
		//Convert interval to lower case for case-insensitive checking
		interval = interval.toLowerCase();
		//We convert quarter and week case into month and days case respectively
		//As they're both similar in nature
		if (interval == "q") {
			interval = "m";
			//Multiply num by 3, as we're converting quarters into months
			num = num*3;
		}
		if (interval == "w") {
			interval = "d";
			//Multiply num by 7, as we're converting weeks into days
			num = num*7;
		}
		//Now, we run on individual cases and add to the date.       
		switch (interval) {
		case "y" :
			//We need to add year to the date. So simply add year
			this.year = this.year+num;
			//Now, we need to adjust the day of last month falling in
			//calculation. 
			//For cases like 29 Feb 1904 + 1 Year != 29 Feb 1905- but 28 Feb 1905. 
			//To do so, first get the list of days for each month in ending year.
			var daysInMn:Array = this.getDaysInMonth(this.year);
			//Now, check for the day clause
			if (this.day>daysInMn[this.month]) {
				this.day = daysInMn[this.month];
			}
			//Re-calculate serial     
			this.convertToSerial();
			break;
		case "m" :
			//We need to add given number of months to the date. 
			//Now, if existing month + num is greater than 12, that will be 
			//added as extra years. Balance will be added to months. 			
			//Add month to the existing months
			this.month = this.month+num;
			//If this.month>12, we adjust years
			//For Cases like 11 Nov 1993 + 6 months
			if (this.month>12) {
				var extraMonths:Number = this.month%12;
				var extraYears:Number = (this.month-extraMonths)/12;
				//Add years 
				this.year = this.year+extraYears;
				//Add months now
				this.month = extraMonths;
			}
			//Or, if month goes negative or 0, due to subtraction     
			//For cases, like 1st Aug 1993 - (Minus) 9 months
			if (this.month<=0) {
				var extraYears:Number = Math.floor(Math.abs(this.month)/12)+1;
				this.year = this.year-extraYears;
				this.month = this.month+12*extraYears;
			}
			//Now, we need to adjust the day of last month falling in     
			//calculation. 
			// For cases like 31 Jan + 1 Month != 31 Feb - but 28/29 Feb. 
			//To do so, first get the list of days for each month in ending year.
			var daysInMn:Array = this.getDaysInMonth(this.year);
			//Now, check for the day clause
			if (this.day>daysInMn[this.month]) {
				this.day = daysInMn[this.month];
			}
			//Re-calculate serial     
			this.convertToSerial();
			break;
		case "d" :
			//We need to add days to the date
			this.serial = this.serial+num;
			//Convert the new serial to date
			var dtObj:Object = this.serialToObj(this.serial);
			//Update local vars
			this.year = dtObj.y;
			this.month = dtObj.m;
			this.day = dtObj.d;
			break;
		case "h" :
			//We need to add hours to the date
			this.hour = this.hour+num;
			//Now, if hours is > 24, we need to convert the hours into days
			//The balance hours stays as hours
			if (this.hour>=24) {
				var bHours:Number = this.hour%24;
				var extraDays:Number = (this.hour-bHours)/24;
				this.hour = bHours;
				//Add the given number of days
				this.add("d", extraDays);
				//Re-calculate serial  
				this.convertToSerial();
			} else {
				//If hour is less than 0 (negative)
				if (this.hour<0) {
					var extraDays:Number = Math.floor(Math.abs(this.hour)/24)+1;
					//Add hours on positive scale
					this.hour += 24*extraDays;
					//Negate days to adjust for added hours.
					this.add("d", -extraDays);
				} else {
					//Directly re-calculate serial - just add new hours
					this.serial += (num*3600)/86400;
				}
			}
			break;
		case "mn" :
			//We need to add minutes to the date
			this.min = this.min+num;
			//If Minutes>60, we need to convert that in hour.
			//The balance minutes stays as minutes
			if (this.min>=60) {
				var bMin:Number = this.min%60;
				var extraHours:Number = (this.min-bMin)/60;
				this.min = bMin;
				//Add the given number of hours
				this.add("h", extraHours);
				//Re-calculate serial  
				this.convertToSerial();
			} else {
				//If min is less than 0 (negative)
				if (this.min<0) {
					var extraHours:Number = Math.floor(Math.abs(this.min)/60)+1;
					//Add min on positive scale
					this.min += 60*extraHours;
					//Negate hours to adjust for added minutes.
					this.add("h", -extraHours);
				} else {
					//Directly re-calculate serial - just add new minutes
					this.serial += (num*60)/86400;
				}
			}
			break;
		case "s" :
			//We need to add seconds to the date
			this.sec = this.sec+num;
			//If Seconds>60, we need to convert that to minutes.
			//The balance seconds stays as seconds 
			if (this.sec>=60) {
				var bSec:Number = this.sec%60;
				var extraMins:Number = (this.sec-bSec)/60;
				this.sec = bSec;
				//Add the given number of minutes
				this.add("mn", extraMins);
				//Re-calculate serial  
				this.convertToSerial();
			} else {
				//If sec is less than 0 (negative)
				if (this.sec<0) {
					var extraMins:Number = Math.floor(Math.abs(this.sec)/60)+1;
					//Add sec on positive scale
					this.sec += 60*extraMins;
					//Negate mins to adjust for added seconds.
					this.add("mn", -extraMins);
				} else {
					//Directly re-calculate serial - just add new seconds
					this.serial += num;
				}
			}
			break;
		}
		return this;
	}
	/**
	 * diff function returns the difference between the two
	 * dates in the specified interval. Difference is rounded to
	 * the minimum value. For example, if there's a difference of
	 * 3.2 weeks, we return as 3.
	 *	@param	cDate		The date to compare with.
	 *	@param	interval	In which interval should the difference
	 *						be returned. Possible values are y,m,d,w,h,m,s
	 *						Default is taken as seconds.
	 *	@return				The difference between the two dates in specified
	 *						interval.
	*/
	public function diff(cDate:FCDateTime, interval:String):Number {
		//Convert interval to lower case for case-insensitive checking
		interval = interval.toLowerCase();
		//Variable to store diff in the specified interval
		var df:Number = 0;
		//Diff returned = cDate - this date. So, if cDate would be smaller
		//than this date, we'll return negative values.
		//Multiplication factor
		var multiple:Number = 1;
		//Internally we'll store both the dates in two new vars
		var dS:FCDateTime, dL:FCDateTime;
		//dS (smaller date) and dL (larger date) to avoid any confusions.
		if (this.isGreaterThan(cDate)) {
			//Store dates
			dS = cDate;
			dL = this;
			//Update multiplication flag to return value as negative
			multiple = -1;
		} else {
			//Directly store dates
			dS = this;
			dL = cDate;
		}
		//Now, find interval specific difference
		//Now, we run on individual cases and add to the date.   
		switch (interval) {
		case "y" :
			df = dL.getYear()-dS.getYear();
			break;
		case "q" :
			//Differencet in month
			var dM:Number = (dL.getYear()-dS.getYear())*12+(dL.getMonth()-dS.getMonth());
			//Start Month
			var sM:Number = dS.getMonth();
			//Cumulative end month
			var cEM:Number = sM+dM;
			//Difference (q)- Find the numbers between these two indexes, such
			//that num mod 3==1. So, we deduct 1 from both and then divide by 3,
			//floor it, and check the difference.
			df = int((cEM-1)/3)-int((sM-1)/3);
			break;
		case "m" :
			df = (dL.getYear()-dS.getYear())*12+(dL.getMonth()-dS.getMonth());
			break;
		case "w" :
			df = Math.floor((Math.floor(dL.getSerial())-Math.floor(dS.getSerial()))/7);
			break;
		case "d" :
			df = (Math.floor(dL.getSerial())-Math.floor(dS.getSerial()));
			break;
		case "h" :
			//Difference in serial to automatically adjust for date/time diff
			var diff:Number = dL.getSerial()-dS.getSerial();
			//Difference of days
			var dateDiff:Number = Math.floor(diff);
			//Difference in time on /86400 basis
			var timeDiff:Number = diff-dateDiff;
			//Convert timeDiff to hours now.
			var hrsDiff:Number = Math.floor((timeDiff*86400)/3600);
			//Add date*24 and hours
			df = dateDiff*24+hrsDiff;
			break;
		case "mn" :
			//Difference in serial to automatically adjust for date/time diff
			var diff:Number = dL.getSerial()-dS.getSerial();
			//Difference of days
			var dateDiff:Number = Math.floor(diff);
			//Difference in time on /86400 basis
			var timeDiff:Number = diff-dateDiff;
			//Convert timeDiff to minutes now.
			var minDiff:Number = Math.floor((timeDiff*86400)/60);
			//Add date*1440 and minutes
			df = dateDiff*1440+minDiff;
			break;
		case "s" :
			//Difference in serial to automatically adjust for date/time diff
			var diff:Number = dL.getSerial()-dS.getSerial();
			//Difference of days
			var dateDiff:Number = Math.floor(diff);
			//Difference in time in seconds
			var secDiff:Number = (diff-dateDiff)*86400;
			//Add date*86400 and seconds
			df = dateDiff*86400+secDiff;
			break;
		}
		//Return difference multiplied by the factor
		return Math.round(df)*multiple;
	}
	/**
	 * isGreaterThan method compares the existing date with the specified
	 * date and returns a boolean value. To check dates, we directly compare
	 * the serial values of both date.
	 *	@param	cDate		The date to compare with.
	 *	@return				Boolean value indicating whether the class's date
	 *						is greater than the specified date.
	*/
	public function isGreaterThan(cDate:FCDateTime):Boolean {
		return (this.serial>cDate.getSerial());
	}
	/**
	 * isEqualTo method compares the existing date with the specified date and
	 * returns a boolean value. To check dates, we directly compare the serial
	 * values of both date.
	 *	@param	cDate	The date to compare with.
	 *	@return			Boolean value indicating whether the dates are equal
	*/
	public function isEqualTo(cDate:FCDateTime):Boolean {
		return (this.serial == cDate.getSerial());
	}
	/**
	 * toNearestInterval method converts the date into the nearest interval
	 * specified. For example, if a date is Jan 12, 2006, and we've to convert it
	 * to nearest interval (month), the new date would be Feb 01, 2006. 
	 * Similary nearest week would be the closest week starting with Monday.
	 * Also, if the date is already on an interval (like 1-1-2006) for month, 
	 * we simply return the same, without any alterations.
	 *	@param		interval	Interval value to which we have to round the date to.
	 *							It can be y,q,m,w,d,h,mn. Seconds is not supported
	 *							as its the base unit of time tokens, as such the
	 *							interval always stays same.
	 *	@return					Nothing. We directly modify the instance values of 
	 *							this date.
	*/
	public function toNearestInterval(interval:String):Void {
		//Convert interval to lower case for case-insensitive checking
		interval = interval.toLowerCase();
		switch (interval) {
		case "y" :
			//If it's not 1-1-xxxx, we increase the year by one
			if (!(this.month == 1 && this.day == 1)) {
				//Increment year
				this.year++;
				//Reset day and month
				this.day = 1;
				this.month = 1;
			}
			//Reset time and serialize  
			this.resetTime(true);
			break;
		case "q" :
			//If the month is not already divisible by 3 and day is 1
			if (!(this.day == 1 && this.month%3 == 1)) {
				var monthsToAdd:Number = Math.round(3/(this.month-(3*int((this.month-1)/3))));
				//Reset day and time
				this.day = 1;
				//Reset time to 0 without serializing
				this.resetTime(false);
				//Add the months
				this.add("m", monthsToAdd);
			} else {
				//Reset time and serialize
				this.resetTime(true);
			}
		case "m" :
			//If we're not already on 1st of month
			if (this.day != 1) {
				//Reset day & time
				this.day = 1;
				//Reset time to 0 without serializing
				this.resetTime(false);
				//Add 1 month
				this.add("m", 1);
			} else {
				//Reset time and serialize
				this.resetTime(true);
			}
			break;
		case "w" :
			//Get the weekday for this date
			var wkDay:Number = this.dayOfWeek();
			//If it's not already monday
			if (wkDay != 1) {
				//Reset time to 0 without serializing
				this.resetTime(false);
				//We need to add 8-wkDay days
				this.add("d", 8-wkDay);
			} else {
				//Reset time and serialize
				this.resetTime(true);
			}
			break;
		case "d" :
			//If hour, min and sec are not already 0, adjust them
			if (!(this.hour == 0 && this.min == 0 && this.sec == 0)) {
				this.hour = 0;
				this.min = 0;
				this.sec = 0;
				this.add("d", 1);
			}
		case "h" :
			//If min and sec are not already 0, adjust them
			if (!(this.min == 0 && this.sec == 0)) {
				this.min = 0;
				this.sec = 0;
				this.add("h", 1);
			}
		case "mn" :
			//If sec is not already 0
			if (this.sec != 0) {
				this.sec = 0;
				this.add("mn", 1);
			}
		}
	}
	/** 
	 * clone method copies this date object and returns it.
	 *	@return		An instance of FCDateTime with same state as
	 *				that of this instance.	 
	*/
	public function clone():FCDateTime {
		//Create clone date instance
		var cDate:FCDateTime = new FCDateTime(this.year, this.month, this.day, this.hour, this.min, this.sec);
		//Update other relevant properties
		cDate.serial = this.serial;
		//cDate.dateGiven = this.dateGiven;
		//cDate.timeGiven = this.timeGiven;
		//Return it.
		return cDate;
	}
}