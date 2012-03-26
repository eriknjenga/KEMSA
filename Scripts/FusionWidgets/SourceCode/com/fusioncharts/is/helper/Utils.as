/**
* @class Utils
* @author InfoSoft Global (P) Ltd. www.fusioncharts.com / www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.

* Utils class helps us bunch a group of utility functions.
*/
import com.fusioncharts.is.core.Chart;
import com.fusioncharts.is.extensions.StringExt;
import flash.external.ExternalInterface;
import flash.display.BitmapData;
class com.fusioncharts.is.helper.Utils {
	/**
	* Since Utils class is just a grouping of utility functions,
	* we do not want any instances of it (as all methods wil be static).
	* So, we declare a private constructor
	*/
	private function Utils() {
		//Private constructor to avoid creation of instances
	}
	/**
	* getFirstValue method is is used to return the first non-null
	* non-undefined non-empty value in a list of values provided to
	* this method. To this method you can pass a list of values like
	* a,b,c,d,e in a preferential order and this method will return the
	* first non-null non-undefined value in this list.
	*/
	public static function getFirstValue() {
		for (var i = 0; i<arguments.length; i++) {
			if (arguments[i] != null && arguments[i] != undefined && arguments[i] != "") {
				return arguments[i];
			}
		}
		return "";
	}
	/**
	* getFirstNumber method is is used to return the first non-null
	* non-undefined non-empty NUMBER in a list of values provided to
	* this method. To this method you can pass a list of numbers like
	* a,b,c,d,e in a preferential order and this method will return the
	* first non-null non-undefined NUMBER in this list.
	*/
	public static function getFirstNumber():Number {
		for (var i = 0; i<arguments.length; i++) {
			if (arguments[i] != null && arguments[i] != undefined && arguments[i] != "" && isNaN(Number(arguments[i])) == false) {
				return Number(arguments[i]);
			}
		}
		return 0;
	}
	/**
	* createText method returns textfield or MovieClip, 
	* whichever pertinent for text display, taking care of
	* rotation.
	*	@param		simulationMode	Whether we're simulating the text field creation
	*								to get width & height. Or, if we're actually
	*								rendering it. In simulation mode, we do not
	*								re-position the textfield to optimize the flow.
	*	@param		targetMC	Movie clip inside which we've to
	*							create the text field.
	*	@param		strText		Text to be shown in the text field
	*	@param		depth		Depth at which the text field is to
	*							be created
	*	@param		xPos		x-position of the text field
	*	@param		yPos		y-position of the text field
	*	@param		rotation	Numerical value of rotation
	*	@param		objStyle	Object containing style properties for
	*							the text field.
	*							This object should necessarily contain
	*							the following parameters:
	*				align		Horizontal alignment. Possible values:
	*							"left", "center" or "right"
	*				vAlign		Vertical alignment of text. Possible values:
	*							"top", "middle" or "bottom"
	*				bold		Boolean value indicating whether the text
	*							would be bold.
	*				italic		Boolean value indicating whether the text
	*							would be italic.
	*				underline	Boolean value indicating whether the text
	*							would be underline.
	*				font		Font face for the text.
	*				size		Font size for the text
	*				color		Color in RRGGBB format for the text.
	*				isHTML		Boolean value indicating whether text would
	*							be rendered as HTML.
	*				leftMargin	Left margin for text (in pixels)
	*				letterSpacing	Numerical value indicating the spacing
	*								between two letters
	*				bgColor		Hex Color RRGGBB or undefined value indicating
	*							the background color of the text field. If undefined,
	*							that means text field shouldn't have a background.
	*				borderColor	Hex Color RRGGBB or undefined value indicating
	*							border color of text field.
	*				wrap		Boolean value indicating whether we need to wrap
	*							labels
	*				width		If we've to wrap, width of textbox
	*				height		If we've to wrap, height of text box
	*	@return					An object cotaining reference to the text field that it
	*							creates and dimensions
	*/
	public static function createText(simulationMode:Boolean, strText:String, targetMC:MovieClip, depth:Number, xPos:Number, yPos:Number, rotation:Number, objStyle:Object, wrap:Boolean, width:Number, maxHeight:Number):Object {
		//First up, we create a text format object and set the properties
		var tFormat:TextFormat = new TextFormat();
		//Font properties
		tFormat.font = objStyle.font;
		tFormat.size = objStyle.size;
		tFormat.color = parseInt(objStyle.color, 16);
		//Text decoration
		tFormat.bold = objStyle.bold;
		tFormat.italic = objStyle.italic;
		tFormat.underline = objStyle.underline;
		//Margin and spacing
		tFormat.leftMargin = objStyle.leftMargin;
		tFormat.letterSpacing = objStyle.letterSpacing;
		//---------------------//
		// Work with textfield for no rotation or Movieclip with Bitmap for rotation
		if (rotation != null && rotation != undefined && rotation != 0) {
			// For rotation, call to get the MC returned encapsulated with other params.
			return getTextMc(simulationMode, strText, targetMC, depth, xPos, yPos, rotation, tFormat, objStyle, wrap, width, maxHeight);
		} else {
			// For no rotation, call to get the textfield returned encapsulated with other params.
			return getTextField(simulationMode, strText, targetMC, depth, xPos, yPos, rotation, tFormat, objStyle, wrap, width, maxHeight);
		}
	}
	/**
	* getTextField method creates a text field on the chart based
	* on the parameters provided.
	*	@param		simulationMode	Whether we're simulating the text field creation
	*								to get width & height. Or, if we're actually
	*								rendering it. In simulation mode, we do not
	*								re-position the textfield to optimize the flow.
	*	@param		targetMC	Movie clip inside which we've to
	*							create the text field.
	*	@param		strText		Text to be shown in the text field
	*	@param		depth		Depth at which the text field is to
	*							be created
	*	@param		xPos		x-position of the text field
	*	@param		yPos		y-position of the text field
	*	@param		rotation	Numerical value of rotation
	*	@param		tFormat		TextFormat object
	*	@param		objStyle	Object containing style properties for
	*							the text field.
	*							This object should necessarily contain
	*							the following parameters:
	*				align		Horizontal alignment. Possible values:
	*							"left", "center" or "right"
	*				vAlign		Vertical alignment of text. Possible values:
	*							"top", "middle" or "bottom"
	*				bold		Boolean value indicating whether the text
	*							would be bold.
	*				italic		Boolean value indicating whether the text
	*							would be italic.
	*				underline	Boolean value indicating whether the text
	*							would be underline.
	*				font		Font face for the text.
	*				size		Font size for the text
	*				color		Color in RRGGBB format for the text.
	*				isHTML		Boolean value indicating whether text would
	*							be rendered as HTML.
	*				leftMargin	Left margin for text (in pixels)
	*				letterSpacing	Numerical value indicating the spacing
	*								between two letters
	*				bgColor		Hex Color RRGGBB or undefined value indicating
	*							the background color of the text field. If undefined,
	*							that means text field shouldn't have a background.
	*				borderColor	Hex Color RRGGBB or undefined value indicating
	*							border color of text field.
	*				wrap		Boolean value indicating whether we need to wrap
	*							labels
	*				width		If we've to wrap, width of textbox
	*				height		If we've to wrap, height of text box
	*	@return					An object cotaining reference to the text field that it
	*							creates and dimensions
	*/
	public static function getTextField(simulationMode:Boolean, strText:String, targetMC:MovieClip, depth:Number, xPos:Number, yPos:Number, rotation:Number, tFormat:TextFormat, objStyle:Object, wrap:Boolean, width:Number, maxHeight:Number):Object {
		//Extract align and vAlign Properties from style Obj
		var alignPos:String = objStyle.align;
		var vAlignPos:String = objStyle.vAlign;
		//Adjust alignment position for 315 rotation
		alignPos = (rotation == 315) ? "RIGHT" : alignPos;
		//Create the actual text field object now.
		var tf:TextField;
		//a & b are undefined variables
		//We want the initial text field size to be of flexible size as we're
		//not wrapping. So we do not define the width and height here
		//Based on wrap, we create the textfield
		if (wrap == true) {
			//Get text extent for this text.
			var reqHeightExt:Object = tFormat.getTextExtent(strText, width);
			//Create the textfield with minimum required width & height
			tf = targetMC.createTextField("Text_"+depth, depth, xPos, yPos, width, Math.min(reqHeightExt.textFieldHeight, maxHeight));
			//Set align position for text format in case of wrapping
			tFormat.align = alignPos;
			//Set wordwrap
			tf.wordWrap = true;
		} else {
			var a, b;
			tf = targetMC.createTextField("Text_"+depth, depth, xPos, yPos, a, b);
			//Set align position
			tf.autoSize = alignPos;
		}
		//Set the properties
		tf.multiLine = true;
		tf.selectable = false;
		//Set the border color if required
		if (objStyle.borderColor != "") {
			tf.border = true;
			tf.borderColor = parseInt(objStyle.borderColor, 16);
		}
		//Set the background color if required 
		if (objStyle.bgColor != "") {
			tf.background = true;
			tf.backgroundColor = parseInt(objStyle.bgColor, 16);
		}
		//Whether HTML text or not? 
		tf.html = objStyle.isHTML;
		//If HTML text, we need to convert <BR> to /n.
		if (objStyle.isHTML) {
			strText = StringExt.replace(strText, "<BR>", "\n");
			strText = StringExt.replace(strText, "&lt;BR&gt;", "\n");
			strText = StringExt.replace(strText, "<br>", "\n");
			strText = StringExt.replace(strText, "&lt;br&gt;", "\n");
		}
		//Set the text 
		if (objStyle.isHTML) {
			//If it's HTML text, set as htmlText
			tf.htmlText = strText;
		} else {
			//Else, set as plain text
			tf.text = strText;
		}
		//Apply the text format
		tf.setTextFormat(tFormat);
		var originalH = tf._height;
		var dispItem:TextField = tf;
		//We now re-position the text field if not in simulation mode
		if (!simulationMode) {
			//------------------------------------------------------------------//
			//If the rotation angle is 0,null or undefined i.e., the
			//text is horizontal, we just need to adjust the vertical
			//alignment.
			if (rotation == 0 || rotation == null || rotation == undefined) {
				switch (vAlignPos.toUpperCase()) {
				case "TOP" :
					//Top(of the ypos mid line
					//        TEXT HERE
					//---------MID LINE---------
					//       (empty space)
					dispItem._y = dispItem._y-(dispItem._height);
					break;
				case "MIDDLE" :
					//       (empty space)
					//---------TEXT HERE---------
					//       (empty space)
					dispItem._y = dispItem._y-(dispItem._height/2);
					break;
				case "BOTTOM" :
					//Right is equivalent to bottom
					//       (empty space)
					//---------MID LINE---------
					//         TEXT HERE
					//No need to change - already at this position
					break;
				}
				//If in wrap mode, we need to horizontal align too
				if (wrap == true) {
					switch (alignPos.toUpperCase()) {
					case "LEFT" :
						//Nothing to do - pre-left aligned
						break;
					case "CENTER" :
						dispItem._x = dispItem._x-(dispItem._width/2);
						break;
					case "RIGHT" :
						dispItem._x = dispItem._x-(dispItem._width);
						break;
					}
				}
			}
		}
		//------------------------------------------------------------------// 
		//Create an object which we'll return
		var rtnObj:Object = new Object();
		//Set 3 properties of the temporary object
		//width, height, tf
		rtnObj.width = dispItem._width;
		rtnObj.height = dispItem._height;
		//For fonts not included
		if (rtnObj.height<=4) {
			rtnObj.height = objStyle.size*2;
		}
		//Set the text field 
		rtnObj.tf = dispItem;
		//Delete the temporary objects
		delete tFormat;
		delete tf;
		//Return this object
		return rtnObj;
	}
	/**
	* getTextMc method creates a text displaying Movieclip 
	* using bitmap on the chart based on the parameters 
	* provided.
	*	@param		simulationMode	Whether we're simulating the text field creation
	*								to get width & height. Or, if we're actually
	*								rendering it. In simulation mode, we do not
	*								re-position the textfield to optimize the flow.
	*	@param		targetMC	Movie clip inside which we've to
	*							create the text field.
	*	@param		strText		Text to be shown in the text field
	*	@param		depth		Depth at which the text field is to
	*							be created
	*	@param		xPos		x-position of the text field
	*	@param		yPos		y-position of the text field
	*	@param		rotation	Numerical value of rotation
	*	@param		tFormat		TextFormat object
	*	@param		objStyle	Object containing style properties for
	*							the text field.
	*							This object should necessarily contain
	*							the following parameters:
	*				align		Horizontal alignment. Possible values:
	*							"left", "center" or "right"
	*				vAlign		Vertical alignment of text. Possible values:
	*							"top", "middle" or "bottom"
	*				bold		Boolean value indicating whether the text
	*							would be bold.
	*				italic		Boolean value indicating whether the text
	*							would be italic.
	*				underline	Boolean value indicating whether the text
	*							would be underline.
	*				font		Font face for the text.
	*				size		Font size for the text
	*				color		Color in RRGGBB format for the text.
	*				isHTML		Boolean value indicating whether text would
	*							be rendered as HTML.
	*				leftMargin	Left margin for text (in pixels)
	*				letterSpacing	Numerical value indicating the spacing
	*								between two letters
	*				bgColor		Hex Color RRGGBB or undefined value indicating
	*							the background color of the text field. If undefined,
	*							that means text field shouldn't have a background.
	*				borderColor	Hex Color RRGGBB or undefined value indicating
	*							border color of text field.
	*				wrap		Boolean value indicating whether we need to wrap
	*							labels
	*				width		If we've to wrap, width of textbox
	*				height		If we've to wrap, height of text box
	*	@return					An object cotaining reference to the text field that it
	*							creates and dimensions
	*/
	public static function getTextMc(simulationMode:Boolean, strText:String, targetMC:MovieClip, depth:Number, xPos:Number, yPos:Number, rotation:Number, tFormat:TextFormat, objStyle:Object, wrap:Boolean, width:Number, maxHeight:Number):Object {
		//Extract align and vAlign Properties from style Obj
		var alignPos:String = objStyle.align;
		var vAlignPos:String = objStyle.vAlign;
		//Adjust alignment position for 315 rotation
		alignPos = (rotation == 315) ? "RIGHT" : alignPos;
		//Create the actual text field object now. This will be used to draw the bitmap and flushed thereof.
		var tf:TextField;
		//a & b are undefined variables
		//We want the initial text field size to be of flexible size as we're
		//not wrapping. So we do not define the width and height here
		//Based on wrap, we create the textfield
		if (wrap == true) {
			//Get text extent for this text.
			var reqHeightExt:Object = tFormat.getTextExtent(strText, width);
			//Create the textfield with minimum required width & height
			tf = targetMC.createTextField("Text_"+depth, depth, xPos, yPos, width, Math.min(reqHeightExt.textFieldHeight, maxHeight));
			//Set align position for text format in case of wrapping
			tFormat.align = alignPos;
			//Set wordwrap
			tf.wordWrap = true;
		} else {
			var a, b;
			tf = targetMC.createTextField("Text_"+depth, depth, xPos, yPos, a, b);
			//Set align position
			tf.autoSize = 'left';
		}
		//Set the properties
		tf.multiLine = true;
		tf.selectable = false;
		//Set the border color if required
		if (objStyle.borderColor != "") {
			tf.border = true;
			tf.borderColor = parseInt(objStyle.borderColor, 16);
		}
		//Set the background color if required 
		if (objStyle.bgColor != "") {
			tf.background = true;
			tf.backgroundColor = parseInt(objStyle.bgColor, 16);
		}
		//Whether HTML text or not? 
		tf.html = objStyle.isHTML;
		//If HTML text, we need to convert <BR> to /n.
		if (objStyle.isHTML) {
			strText = StringExt.replace(strText, "<BR>", "\n");
			strText = StringExt.replace(strText, "&lt;BR&gt;", "\n");
		}
		//Set the text 
		if (objStyle.isHTML) {
			//If it's HTML text, set as htmlText
			tf.htmlText = strText;
		} else {
			//Else, set as plain text
			tf.text = strText;
		}
		//Apply the text format
		tf.setTextFormat(tFormat);
		var originalH = tf._height;
		
		// Getting the BitmapData of the textfield, for using it instead of the textField itself to avoid embedding fonts.
		var bmp:BitmapData = getTxtBmp(tf);
		// The textfield is required no more.
		tf.removeTextField();
		// Movieclip created at the depth of the textfield destroyed.
		var dispItem:MovieClip = targetMC.createEmptyMovieClip('TextBmp_'+depth, depth);
		// Sub-container mc for alignment adjustments
		var mcBmp:MovieClip = dispItem.createEmptyMovieClip('mcBmp', 0);
		
		// Set to default values for the attachBitmap call.
		var pixelHinting:String = 'auto';
		var smoothed:Boolean = true;
		// Bitmapdata attached to the sub-movieclip created.
		mcBmp.attachBitmap(bmp, 0, pixelHinting, smoothed);
		// Reposition the text display to achieve alignment.
		if (!wrap) {
			if (alignPos == 'RIGHT') {
				mcBmp._x -= mcBmp._width;
			} else if (alignPos == 'CENTER') {
				mcBmp._x -= mcBmp._width/2;
			}
		}
		// Its position set. 
		dispItem._x = xPos;
		dispItem._y = yPos;
		//Set rotation
		dispItem._rotation = rotation;
		//We now re-position the MC if not in simulation mode
		if (!simulationMode) {
			//------------------------------------------------------------------//
			if (rotation == 270) {
				//Now, adjust the y orientation of the MC
				switch (alignPos.toUpperCase()) {
				case "LEFT" :
					//Adjust y-position based on vAlignPos
					switch (vAlignPos.toUpperCase()) {
					case "TOP" :
						//Nothing
						break;
					case "MIDDLE" :
						dispItem._y = dispItem._y+(dispItem._height/2);
						break;
					case "BOTTOM" :
						dispItem._y = dispItem._y+dispItem._height;
						break;
					}
					break;
				case "CENTER" :
					dispItem._x = dispItem._x-(dispItem._width/2);
					//Adjust y-position based on vAlignPos
					switch (vAlignPos.toUpperCase()) {
					case "TOP" :
						break;
					case "MIDDLE" :
					dispItem._y += dispItem._height/2;
						break;
					case "BOTTOM" :
						dispItem._y += dispItem._height;
						break;
					}
					break;
				case "RIGHT" :
					dispItem._x = dispItem._x-(dispItem._width);
					//Adjust y-position based on vAlignPos
					switch (vAlignPos.toUpperCase()) {
					case "TOP" :
						break;
					case "MIDDLE" :
						dispItem._y += dispItem._height/2;
						break;
					case "BOTTOM" :
					dispItem._y += dispItem._height;
						break;
					}
					break;
				}
			} else if (rotation == 315) {
				//If the rotation angle is 315, it can only be for x-axis
				//names in the chart. So we directly alter the x and y position
				//irrespective of alignment position specified.
				var root2 = 1.42;
				dispItem._x -= (originalH/root2)/2;
				//Minus 4 to avoid gutter space
				dispItem._y -= 4;
			}
			//Round the dispItem x and y, to avoid blurring
			dispItem._x = Math.round(dispItem._x);
			dispItem._y = Math.round(dispItem._y);
		}
		//------------------------------------------------------------------// 
		//Create an object which we'll return
		var rtnObj:Object = new Object();
		//Set 3 properties of the temporary object
		//width, height, tf
		rtnObj.width = dispItem._width;
		rtnObj.height = dispItem._height;
		//For fonts not included
		if (rtnObj.height<=4) {
			rtnObj.height = objStyle.size*2;
		}
		//Set the text field 
		rtnObj.tf = dispItem;
		//Delete the temporary objects
		delete tFormat;
		delete tf;
		//Return this object
		return rtnObj;
	}
	/**
	 * getTxtBmp method is a static method called to get the
	 * BitmapData of the textfield returned.
	 * @param	txt		the textfield
	 * @return			its BitmapData
	 */
	private static function getTxtBmp(txt:TextField):BitmapData {
		// BitmapData created
		var bmp:BitmapData = new BitmapData(txt._width+1, txt._height+1, true, 0x0);
		// image of textfield drawn
		bmp.draw(txt);
		// BitmapData of the textfield returned
		return bmp;
	}
	/**
	* getParamsArray method helps convert the list of attributes
	* for any object into an array. It basically helps us convert all
	* attributes into smaller case, for case insensitive parsing.
	* Reason:
	* Starting ActionScript 2, OBJECT/EMBED attributes have also
	* become case-sensitive. However, prior versions of FusionCharts
	* supported case-insensitive attributes. So we need to parse all
	* attributes as case-insensitive to maintain backward compatibility.
	* To do so, we first extract all attributes, convert it into
	* lower case and then store it in an array. Later, we extract value from
	* this array.
	* Once this array is returned, IT'S VERY NECESSARY IN THE CALLING CODE TO
	* REFERENCE THE NAME OF ATTRIBUTE IN LOWER CASE (STORED IN THIS ARRAY).
	* ELSE, UNDEFINED VALUE WOULD SHOW UP.
	*	@param	objSource	Object whose parameters we need to access as an array.
	*	@return				Associative array containing the parameters of the object.
	*						The keys of the array are parameter names in smaller case.
	*/
	public static function getParamsArray(objSource:Object):Array {
		//Array that will store the attributes
		var atts:Array = new Array();
		//Object used to iterate through the attributes collection
		var obj:Object;
		//Iterate through each attribute in the attributes collection,
		//convert to lower case and store it in array.
		for (obj in objSource) {
			//Store it in array
			atts[obj.toString().toLowerCase()] = objSource[obj];
		}
		//Return the array
		return atts;
	}
	/**
	* getAttributesArray method helps convert the list of attributes
	* for an XML node into an array.
	* Same as getParamsArray - just that it gets the attributes of an
	* XML node, instead of an object.
	* Once this array is returned, IT'S VERY NECESSARY IN THE CALLING CODE TO
	* REFERENCE THE NAME OF ATTRIBUTE IN LOWER CASE (STORED IN THIS ARRAY).
	* ELSE, UNDEFINED VALUE WOULD SHOW UP.
	*	@param	xmlNd	XML Node for which we've to get the attributes.
	*	@return			An associative array containing the attributes. The name
	*					of attribute (in all lower case) is the key and attribute value
	*					is value.
	*/
	public static function getAttributesArray(xmlNd:XMLNode):Array {
		//Array that will store the attributes
		var atts:Array = new Array();
		//Object used to iterate through the attributes collection
		var obj:Object;
		//Iterate through each attribute in the attributes collection,
		//convert to lower case and store it in array.
		for (obj in xmlNd.attributes) {
			//Store it in array
			atts[obj.toString().toLowerCase()] = xmlNd.attributes[obj];
		}
		//Return the array
		return atts;
	}
	/**
	* invokeLink method invokes a link for any defined drill down item.
	* A link in XML needs to be URL Encoded. Also, there are a few prefixes,
	* parameters that can be added to link so as to defined target link
	* opener object. For e.g., a link can open in same window, new window,
	* frame, pop-up window. Or, a link can invoke a JavaScript method.
	* Prefixes can be N - new window, F - Frame, P - Pop up, S - SWF link bubbled
	* to parent Flash movie.
	*	@param	strLink	Link to be invoked.
	*/
	public static function invokeLink(strLink:String, chartIns:Chart):Void {
		//We continue only if the link is not empty
		if (strLink != undefined && strLink != null && strLink != "")
		{
			//Unescape the link - as it might be URL Encoded
			strLink = unescape (strLink);
			//Now based on what the first character in the link is (N, F, P)
			//we invoke the link.
			if (strLink.charAt (0).toUpperCase () == "N" && strLink.charAt (1) == "-")
			{
				//Means we have to open the link in a new window.
				getURL (strLink.slice (2) , "_blank");
			} else if (strLink.charAt (0).toUpperCase () == "F" && strLink.charAt (1) == "-")
			{
				//Means we have to open the link in a frame.
				var dashPos : Number = strLink.indexOf ("-", 2);
				//strLink.slice(dashPos+1) indicates link
				//strLink.substr(2, dashPos-2) indicates frame name
				getURL (strLink.slice (dashPos + 1) , strLink.substr (2, dashPos - 2));
			} else if (strLink.charAt (0).toUpperCase () == "P" && strLink.charAt (1) == "-")
			{
				//Means we have to open the link in a pop-up window.
				var dashPos : Number = strLink.indexOf ("-", 2);
				var commaPos : Number = strLink.indexOf (",", 2);
				getURL ("javaScript:var " + strLink.substr (2, commaPos - 2) + " = window.open('" + strLink.slice (dashPos + 1) + "','" + strLink.substr (2, commaPos - 2) + "','" + strLink.substr (commaPos + 1, dashPos - commaPos - 1) + "'); " + strLink.substr (2, commaPos - 2) + ".focus(); void(0);");
			} else if (strLink.charAt (0).toUpperCase () == "J" && strLink.charAt (1) == "-") {
				//We can operate JS link only if ExternalInterface is available and the chart 
				//has been registered
				if (chartIns.registeredWithJS() &&  ExternalInterface.available){
					//Means we have to open the link as JavaScript
					var dashPos : Number = strLink.indexOf ("-", 2);
					//strLink.slice(dashPos+1) indicates arguments if any
					//strLink.substr(2, dashPos-2) indicates link
					//If no arguments, just call the link
					if (dashPos == -1) {
						ExternalInterface.call(strLink.substr(2, strLink.length-2));
					} else {
						//There could be multiple parameters. We just pass them as a single string to JS method.
						ExternalInterface.call(strLink.substr(2, dashPos-2), strLink.slice(dashPos+1));
					}
				}
			} else if (strLink.charAt (0).toUpperCase () == "S" && strLink.charAt (1) == "-")
			{
				//Means we have to convey the link as a event to parent Flash movie
				chartIns.dispatchEvent({type:"linkClicked", target:chartIns, link:strLink.slice(2)});				
			} else 
			{
				//Open the link in same window
				getURL (strLink, "_self");
			}
		}
	}
	/**
	* toBoolean method converts numeric form (1,0) to Flash
	* boolean.
	*	@param	num		Number (0,1)
	*	@return		Boolean value based on above number
	*/
	public static function toBoolean(num:Number):Boolean {
		return ((num == 1) ? (true) : (false));
	}
	/**
	 * fromBoolean method converts boolean form to numeric (1,0)
	 *	@param		boolVal		Boolean value
	 *	@return					Numeric value based on boolean value
	*/
	public static function fromBoolean(boolVal:Boolean):Number {
		return ((boolVal) ? 1 : 0);
	}
}
