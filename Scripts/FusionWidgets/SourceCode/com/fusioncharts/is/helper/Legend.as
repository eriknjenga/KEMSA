 /**
* @class Legend
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
* Legend class helps us generate legend for a chart.
*/
import com.fusioncharts.is.helper.ScrollBar;
import com.fusioncharts.is.extensions.StringExt;
//Event Dispatcher
import mx.events.EventDispatcher;
class com.fusioncharts.is.helper.Legend {
	//Array to store legend items
	private var items:Array;
	private var count:Number;
	//Containers to store parameters
	private var parentMC:MovieClip;
	private var fontProp:Object;
	private var alignPos:String;
	private var xPos:Number;
	private var yPos:Number;
	private var allowDrag:Boolean;
	//Caption of legend
	private var caption:String;
	//Whether to use circular legend
	private var useCircle:Boolean;
	//Whether to use in clickMode
	private var clickMode:Boolean;
	//Maximum and minimum height the legend can assume
	private var maxWidth:Number;
	private var maxHeight:Number;
	//Container size
	private var stageWidth:Number;
	private var stageHeight:Number;
	//Legend box background properties
	private var bgColor:String;
	private var bgAlpha:Number;
	//Legend box border properties
	private var borderColor:String;
	private var borderThickness:Number;
	private var borderAlpha:Number;
	//Scroll bar cosmetic properties
	private var scrollBgColor:String;
	private var scrollBarColor:String;
	private var btnColor:String;
	//Width and height of the legend (will be calculated later)
	private var width:Number;
	private var height:Number;
	//Reference to legend MC
	private var legendMC:MovieClip;
	//Reference to text field, background movie clip
	private var tf:TextField;
	private var bgMC:MovieClip;
	private var scrollMC:MovieClip;
	//Variables to store depth
	private var bgMCDepth:Number;
	private var tfDepth:Number;
	private var scrollDepth:Number;
	//Scroll bar
	var sBar:ScrollBar;
	//Reference to text format object
	private var tFormat:TextFormat;
	//Undefined variables which will be required to simulate text field dimensions
	private var a, b;
	//Flag whether we've to wrap text in final rendering
	private var wrapText:Boolean;
	//Flag whether we've to show scroll bar
	private var showScroll:Boolean;
	//Scroll bar properties
	var scrollWidth:Number = 12;
	var scrollPad:Number = 2;
	var scrollVPad:Number = 2;
	//xShift property
	var xShift:Number = 0;
	/**
	* Constructor function to initialize and store parameters.
	*	@param	targetMC		Parent movie clip in which we've to draw legend
	*	@param	fontProp		An object containing the following font properties:
	*							- bold
	*							- italic
	*							- underline
	*							- font
	*							- size
	*							- color
	*							- isHTML
	*							- leftMargin
	*	@param	alignPos		Alignment position of legend - BOTTOM or RIGHT
	*	@param	clickMode		Whether to use the legend in click mode?
	*	@param	xPos			Center X Position of the legend
	*	@param	yPos			Center Y Position of the legend
	*	@param	maxWidth		Maximum width that the legend can assume.
	*	@param	maxHeight		Maximum height that the legend can assume
	*	@param	allowDrag		Flag whether the legend should be allowed to drag
	*	@param	stageWidth		Width of the container stage
	*	@param	stageHeight		Height of the container stage
	*	@param	bgColor			Background color (if any) for the legend
	*	@param	bgAlpha			Background alpha
	*	@param	borderColor		Border color of the legend box.
	*	@param	borderThickness	Border thickness (in pixels).
	*	@param	borderAlpha		Border Alpha of the box.
	*	@param	scrollBgColor	Background color of scroll bar
	*	@param	scrollBarColor	Scroll bar color
	*	@param	btnColor		Scroll Button Color
	*/
	function Legend (targetMC:MovieClip, fontProp:Object, clickMode:Boolean, alignPos:String, xPos:Number, yPos:Number, maxWidth:Number, maxHeight:Number, allowDrag:Boolean, stageWidth:Number, stageHeight:Number, bgColor:String, bgAlpha:Number, borderColor:String, borderThickness:Number, borderAlpha:Number, scrollBgColor:String, scrollBarColor:String, btnColor:String){
		//Store parameters in instance variables
		this.parentMC = targetMC;
		this.fontProp = fontProp;
		this.clickMode = clickMode;
		this.alignPos = alignPos.toUpperCase ();
		this.xPos = xPos;
		this.yPos = yPos;
		this.maxWidth = maxWidth;
		this.maxHeight = maxHeight;
		this.allowDrag = allowDrag;
		this.stageWidth = stageWidth;
		this.stageHeight = stageHeight;
		this.bgColor = bgColor;
		this.bgAlpha = bgAlpha;
		this.borderColor = borderColor;
		this.borderThickness = borderThickness;
		this.borderAlpha = borderAlpha;
		this.scrollBgColor = scrollBgColor;
		this.scrollBarColor = scrollBarColor;
		this.btnColor = btnColor;
		//Initialize count to 0
		count = 0;
		//Initialize items array
		items = new Array ();
		//By default, we do not show scroll bar
		showScroll = false;
		//Set caption to blank value
		caption = "";
		//By default we use square
		this.useCircle = false;
		//Create the text format object
		tFormat = new TextFormat ();
		tFormat.align = (this.alignPos == "RIGHT") ? "left":"center";
		//tFormat.align = "left";
		tFormat.font = fontProp.font;
		tFormat.color = parseInt (fontProp.color, 16);
		tFormat.size = fontProp.size;
		tFormat.bold = fontProp.bold;
		tFormat.italic = fontProp.italic;
		tFormat.underline = fontProp.underline;
		tFormat.leftMargin = fontProp.leftMargin;
		tFormat.rightMargin = fontProp.leftMargin;
		tFormat.leading = 3;
		//Create Legend movie clip inside parent movie clip
		legendMC = this.parentMC.createEmptyMovieClip ("Legend", this.parentMC.getNextHighestDepth ());		
		//Get depths
		bgMCDepth = 1;
		tfDepth = 2;
		scrollDepth = 3;
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
	* addItem adds a legend item to be displayed.
	*	@param	itemName	String value to be displayed
	*	@param	itemColor	Color of the item. Hex Color code without #.
	*	@param	itemId		Internal Item ID - for use when the legend items
	*						are click-able.
	*/
	public function addItem (itemName:String, itemColor:String, itemId:Number){
		//We store each item as an object in items array.
		//Create an object from the given parameters and store it
		var objItem:Object = new Object ();
		//Replace < with &lt; if not in HTML mode
		itemName = StringExt.replace (itemName, "<", "&lt;")
		objItem.name = itemName;
		objItem.color = itemColor;
		objItem.id = itemId;
		//By default set the item as active
		objItem.active = true;
		//Store it in items array
		this.items.push (objItem);
		count ++;
		//Delete
		delete objItem;
	}
	/**
	 * setCaption method sets the caption for the legend.
	*/
	public function setCaption(strCaption:String):Void{
		//Store the caption
		this.caption = strCaption;
	}
	/**
	 * useCircleMarker method sets whether we've to use circular
	 * or square marker.
	 *	@param	useCircle	Boolean value indicating whether we've to use
	 *						circular or square marker.	 
	*/
	public function useCircleMarker(useCircle:Boolean):Void{
		this.useCircle = useCircle;
	}
	/**
	* getLegendStr method gets the entire HTML String for the legend.
	*/
	private function getLegendStr():String{
		var strText:String = "";
		var marker:String;
		//If caption has been defined, add that
		if (this.caption!=""){
			strText = strText + "<B>" + this.caption + "</B>";
			//If legend is in vertical alignment (alignPos = right), we add line break
			strText = (this.alignPos == "RIGHT") ? (strText + "<BR>"):(strText + "   ");
		}		
		//Now, iterate through all items and generate the string
		var i:Number;		
		for (i=0; i<count; i++){
			//If the item is active, based on what marker we've to use, select the same
			if (this.items[i].active){
				if (this.useCircle){
					//Character that works in Linux: •
					marker = "<font color='#" + this.items[i].color + "' size='" + Number(this.fontProp.size) + "'>●</font>&nbsp;";
				}else{
					marker = "<font face='Arial' color='#" + this.items[i].color + "'>■&nbsp;</font>";
				}					
			}else{
				if (this.useCircle){
					marker = "<font color='#" + this.items[i].color + "'>○&nbsp;</font>";
				}else{
					marker = "<font face='Arial' color='#" + this.items[i].color + "'>□&nbsp;</font>";
				}					
			}
			//Add the legend item name - with/without link
			strText = strText + ((this.clickMode==true)?("<A HREF='asfunction:localFN," + i + "'>"):("")) +  marker + "<font face='" + this.fontProp.font + "' color='#" + this.fontProp.color + "' size='" + this.fontProp.size + "'>"+ this.items[i].name + "</font>" + ((this.clickMode==true)?("</A>"):(""));
			//Add spacers - If legend is in vertical alignment (alignPos = right), we add line break
			strText = strText + ((this.alignPos == "RIGHT")?("<BR>"):("      "));
		}
		//Return string
		return strText;
	}
	/**
	* getDimensions method helps us to get the dimensions for the legend.
	* We simulate the text field to get appropriate width and height.
	* It's necessary to call getDimensions for a legend instance
	* (after feeding items), before you finally call render.
	*	@return	An object containing width and height.
	*/
	public function getDimensions():Object{
		//We continue only if any item has been fed
		if (count < 1){
			//Else, return object with 0 w,h
			var rtnObj:Object = new Object ();
			//Store width and height as 0
			rtnObj.width = 0;
			rtnObj.height = 0;
			return rtnObj;
		}
		//Create a return object
		var rtnObj:Object = new Object();
		//Get the legend display string
		var strText:String = this.getLegendStr();
		//First, we need to calculate the width required for the legend.
		//To do so, we simulate the legend text box by specifying undefined w,h.
		tf = this.legendMC.createTextField ("Legend", tfDepth, this.xPos, this.yPos, a, b);
		//AutoSize is set to center so that text field can expand itself to best fit.
		tf.autoSize = "center";
		tf.selectable = false;
		tf.multiline = true;
		tf.html = true;
		//Set text format
		tf.setNewTextFormat (tFormat);
		//Set text
		tf.htmlText = strText;
		//Get width - If the maxwidth is more, we choose text field width, else max width
		this.width = (tf._width > this.maxWidth) ? this.maxWidth:tf._width;
		//Now, if the legend is to be placed on right and the total width is more than max
		//width, we need to wrap text.
		if (this.alignPos == "RIGHT"){
			//We wrap text in case of right, only when the legend width exceeds max width
			wrapText = (tf._width >= this.maxWidth) ? true:false;
		} else {
			//We always wrap text when legend is at bottom
			wrapText = true;
		}
		//We've the width now. So, get the height
		if (this.alignPos == "BOTTOM"){
			//We need to simulate text field once more to get minimum width required.
			//Get text extent for legend text.
			var reqHeightExt:Object = tFormat.getTextExtent (strText, this.width);
			//Now, re-create the text field with the given width, height
			tf = this.legendMC.createTextField ("Legend", tfDepth, this.xPos, this.yPos, this.width, reqHeightExt.textFieldHeight);
			//Set autoSize to center (with fixed width), so that text field can expand vertically to best fit itself.
			tf.autoSize = "center";
			tf.selectable = false;
			tf.multiline = true;
			tf.wordWrap = true;
			tf.html = true;
			//Set text format
			tf.setNewTextFormat (tFormat);
			//Set text
			tf.htmlText = strText;
			//Now, get the minimum of current textfield height or max height specified.
			this.height = Math.min (tf._height, this.maxHeight);
		} else {
			if (wrapText){
				//If the legend is to be placed at side and if wrap text mode is on.
				//Now, re-create the text field with the given width, height
				tf = this.legendMC.createTextField ("Legend", tfDepth, this.xPos, this.yPos, this.width, b);
				tf.autoSize = "center";
				tf.selectable = false;
				tf.multiline = true;
				tf.wordWrap = true;
				tf.html = true;
				//Set text format
				tf.setNewTextFormat (tFormat);
				//Set text
				tf.htmlText = strText;
				//TRICKY: Directly after the text field is created, the _height
				//property is returning un-expected results. Probably, Flash needs
				//a time lag to update property. So, we first get the height in a variable
				//and later use tf._height to access correct value.
				var tmpHeight:Number = tf._height;
				this.height = Math.min (tf._height, this.maxHeight);
			} else {
				this.height = (tf._height > this.maxHeight) ? (this.maxHeight):(tf._height);
			}
		}
		//Update showScroll flag
		if (tf._height >= this.maxHeight){
			//If height of the text field is greater than max height.
			showScroll = true;
			//If width of text field (plus scroll width) is less than max width, we just shift text field
			if ((this.width + this.scrollWidth + this.scrollPad) < this.maxWidth){
				//Shift entire text field
				this.xPos = this.xPos - (this.scrollWidth + 2 * this.scrollPad) / 2;
				xShift = - (this.scrollWidth + 2 * this.scrollPad) / 2;
			} else {
				//We deduct the scroll width and padding from width
				this.width = this.width - (this.scrollWidth + 2 * this.scrollPad);
				this.xPos = this.xPos - (this.scrollWidth + 2 * this.scrollPad) / 2;
				xShift = - (this.scrollWidth + 2 * this.scrollPad) / 2;
				rtnObj.width = this.width + (this.scrollWidth + 2 * this.scrollPad);
				//Also set wrapText to true, as we've reduced text field's width
				wrapText = true;
			}
		}
		//Remove textfield
		tf.removeTextField ();
		//Store width and height
		rtnObj.width = (rtnObj.width == undefined || rtnObj.width == null) ?this.width:rtnObj.width;
		rtnObj.height = this.height;
		return rtnObj;
	}
	/**
	* resetXY method should be called BEFORE render method is called
	* to reset the X and Y position of the legend. During chart rendering,
	* we do not know the actual position of legend, as the canvas needs to
	* be calculated earlier. But, to calculate canvas position, we need to
	* simulate legend. So, that time, we just provide an arbitrary X,Y value.
	* Later, once we've the X and Y of canvas, we re-set the X,Y of legend for
	* proper display
	*	@param	x	New X Position
	*	@param	y	New Y Position
	*/
	public function resetXY (x:Number, y:Number):Void {
		this.xPos = x + xShift;
		this.yPos = y;
	}
	/**
	* render method draws the legend.
	*/
	public function render ():Void {
		//We continue only if any item has been fed
		if (count < 1){
			return;
		}
		//Create the background movie clip
		bgMC = this.legendMC.createEmptyMovieClip ("Bg", bgMCDepth);
		//Draw the background or border
		if (this.borderColor != ""){
			bgMC.lineStyle (this.borderThickness, parseInt (this.borderColor, 16) , this.borderAlpha);
		}
		if (this.bgColor != ""){
			bgMC.beginFill (parseInt (this.bgColor, 16) , this.bgAlpha);
		}
		//Draw the background
		var hW:Number = this.width / 2;
		var hH:Number = this.height / 2;
		//Also, accomodate the scroll bar within this rectangle (if required)
		var xScrollExt:Number = 0;
		if (showScroll){
			xScrollExt = this.scrollWidth + 2 * this.scrollPad;
		}
		bgMC.moveTo (this.xPos - hW, this.yPos - hH);
		bgMC.lineTo (this.xPos + hW + xScrollExt, this.yPos - hH);
		bgMC.lineTo (this.xPos + hW + xScrollExt, this.yPos + hH);
		bgMC.lineTo (this.xPos - hW, this.yPos + hH);
		bgMC.lineTo (this.xPos - hW, this.yPos - hH);
		
		//If in click mode
		if (this.clickMode){
			//We need to define the proxy handler function for asfunction clicks
			//The function needs to be defined for the parent movie clip- the one
			//that contains the text field.
			//Reference to this class.
			var classRef = this;
			legendMC.localFN = function(index:Number){
				//Delegate to clickEvent function of this class
				classRef.clickEvent(index);
			}
		}		
		//Create the text field now
		tf = this.legendMC.createTextField ("LegendTxt", tfDepth, this.xPos, this.yPos, this.width, this.height);
		tf.selectable = false;
		tf.multiline = true;
		tf.html = true;
		tf.wordWrap = wrapText;				
		//Set text format
		tf.setNewTextFormat (tFormat);
		//Set text
		tf.htmlText = this.getLegendStr ();
		//Re-set X and Y Position
		tf._x = tf._x - hW;
		//Shift the textbox 2,1 pixels down depending on align Position
		//This is basically to avoid overlap on background
		if (this.alignPos == "BOTTOM"){
			tf._y = tf._y - hH + 2;
		} else {
			tf._y = tf._y - hH + 1;
		}
		//Create scroll bar if required.
		if (showScroll) {
			scrollMC = this.legendMC.createEmptyMovieClip ("ScrollBar", scrollDepth);
			sBar = new ScrollBar (tf, scrollMC, tf._x + tf._width + scrollPad, tf._y + scrollVPad, scrollWidth, tf._height - (2 * scrollVPad) , scrollBgColor, scrollBarColor, btnColor);
		}
		//Set up the dragging facility
		if (allowDrag) {
			var x:Number = this.xPos;
			var y:Number = this.yPos;
			var sW:Number = this.stageWidth;
			var sH:Number = this.stageHeight;
			bgMC.useHandCursor = false;
			bgMC.onPress = function(){
				this._parent.startDrag (false, - x + this._width / 2, - y + this._height / 2, sW - x - this._width / 2, sH - y - this._height / 2);
			}
			bgMC.onRelease = bgMC.onReleaseOutside = function (){
				this._parent.stopDrag ();
			}
		}
	}
	/**
	 * clickEvent method is called when a legend item has been clicked
	 * by the user. Here, we dispatch the event to parent class.
	 *	@param	index	Internal index of the item which was clicked.
	*/
	private function clickEvent(index:Number):Void{
		//Set the active flag to reverse - for the item.
		this.items[index].active = !this.items[index].active;
		//Update display of legend, by just changing the text field content
		tf.htmlText = this.getLegendStr();
		//We're knowingly NOT invalidating the scroll bar here, as we've
		//just changed a character here. So, this results in the scroll bar being
		//at the exact position where it was left by the user (if the scroll is active, at all).
		//Get classRef
		var classRef = this;
		//Dispatch the click event
		classRef.dispatchEvent({type:"legendClick", target:classRef, index:this.items[index].id, active:this.items[index].active});
	}
	/**
	* reset method resets the legend class.
	*/
	public function reset():Void {
		//Initialize count to 0
		count = 0;
		//Initialize items array
		items = new Array ();
		xShift = 0;
	}
	/*
	* destroy function cleans up the given instance of Legend class.
	*/
	public function destroy():Void {
		//Clear containers
		delete this.items;
		delete this.fontProp;
		delete this.tFormat;
		//Remove the movie clips created
		bgMC.removeMovieClip ();
		tf.removeTextField ();
		//Destroy scroll bar
		sBar.destroy ();
		scrollMC.removeMovieClip ();
		//Remove legend MC too
		if (this.clickMode){
			delete legendMC.localFN;
		}
		legendMC.removeMovieClip();
	}
}
