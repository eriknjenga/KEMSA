/**
* @class ToolTip
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* ToolTip class helps generate a tool tip (hover caption)
* based on the parameters specified
*/
//Drop Shadow filter
import flash.filters.DropShadowFilter;
import com.fusioncharts.is.extensions.StringExt;
class com.fusioncharts.is.helper.ToolTip {
	//Instance variables
	private var parent:MovieClip;
	private var sX:Number;
	private var sY:Number;
	private var sWidth:Number;
	private var sHeight:Number;
	private var font:String;
	private var color:String;
	private var size:Number;
	private var borderColor:String;
	private var bgColor:String;
	private var yPadding:Number;
	private var isHTML:Boolean;
	private var dropShadow:Boolean;
	private var txt:String;
	//Tool tip text field
	private var tf:TextField;
	//Tool Tip text format
	private var tFormat:TextFormat;
	//X-padding constanmt
	private var xPadding = 5;
	//Constructor function
	/**
	* Here, we initialize the tool tip objects.
	*	@param		target	Movie clip in which we've to create the
	*						text field.
	*	@param		sX		Top X of the stage.
	*	@param		sY		Top Y of the stage.
	*	@param		sWidth	Width of the stage.
	*	@param		sHeight	Height of the stage.
	*	@param		yPadding	y-axis padding (pixels)
	*/
	function ToolTip(target:MovieClip, sX:Number, sY:Number, sWidth:Number, sHeight:Number, yPadding:Number) {
		//Store parameters in instance variables
		this.parent = target;
		this.sX = sX;
		this.sY = sY;
		this.sWidth = sWidth;
		this.sHeight = sHeight;
		this.yPadding = yPadding;
		//Undefined variables to be used as text field width and
		//height - for auto sizing purposes.
		var a, b;
		//Create text field and text format objects
		this.tf = this.parent.createTextField("ToolTipTF", parent.getNextHighestDepth(), 0, 0, a, b);
		this.tFormat = new TextFormat();
		//Hide the text field initially
		this.tf._visible = false;
	}
	/**
	* setParams method sets the cosmetic and functional parameters
	* for the tool tip.
	*	@param	font		Font face of the tool tip
	*	@param	size		Font size for the tool tip
	*	@param	color		Color of font
	*	@param	bgColor		Background Color
	*	@param	borderColor	Border Color of the tool tip
	*	@param	isHTML		Whether text is to be rendered as HTML or plain
	*	@param	dropShadow	Whether to drop shadow for the tool tip.
	*/
	public function setParams(font:String, size:Number, color:String, bgColor:String, borderColor:String, isHTML:Boolean, dropShadow:Boolean) {
		//Store parameters in instance variables.
		this.font = font;
		this.size = size;
		this.color = color;
		this.bgColor = bgColor;
		this.borderColor = borderColor;
		this.isHTML = isHTML;
		this.dropShadow = dropShadow;
		//Create a text format object to represent the same.
		this.tFormat.font = this.font;
		this.tFormat.size = this.size;
		this.tFormat.color = parseInt(this.color, 16);
		//Set the background and border for text field
		//Set the border color if required
		if (this.borderColor!="" && this.borderColor != " " && this.borderColor != undefined && this.borderColor != null) {
			this.tf.border = true;
			this.tf.borderColor = parseInt(this.borderColor, 16);
		}
		//Set the background color if required  
		if (this.bgColor != "" && this.bgColor != " " && this.bgColor != undefined && this.bgColor != null) {
			this.tf.background = true;
			this.tf.backgroundColor = parseInt(this.bgColor, 16);
		}
		//Set text alignment to center  
		this.tf.autoSize = "center";
		this.tf.multiLine = true;
		this.tf.wordWrap = false;
		this.tf.selectable = false;
		//Is HTML?
		this.tf.html = this.isHTML;
		//Create filters and apply
		if (dropShadow) {
			var shadowFilter:DropShadowFilter = new DropShadowFilter(4, 65, 0x333333, 0.6, 4, 4, 1, 1, false, false, false);
			parent.filters = [shadowFilter];
		}
		//Re-position initially outside screen to avoid flicker later  
		//What happens is that when the text field is generated, it is placed
		//at 0,0 by default (our create method). Later, when we make it visible,
		//there's a slight lag, which causes the flicker. So, we now place it outside
		//screen so that the flicker is not visible at all.
		this.tf._x = -100;
		this.tf._y = -100;
	}
	/**
	 * setBorderColor method sets the border color of the tool tip textbox.
	*/
	public function setBorderColor(strColor:String):Void {
		//If it's not null and not undefined
		if (strColor == null || strColor == undefined) {
			return;
		}
		//Store in class instance vars 
		this.borderColor = strColor;
		if (strColor != "") {
			//If user has set a border color.
			this.tf.border = true;
			this.tf.borderColor = parseInt(this.borderColor, 16);
		} else {
			//Else, we hide the existing border too.
			this.tf.border = false;
		}
	}
	/**
	 * setBgColor method sets the background color of the tool tip textbox.
	*/
	public function setBgColor(strColor:String):Void {
		//If it's not null and not undefined
		if (strColor == null || strColor == undefined) {
			return;
		}
		//Store in class instance vars 
		this.bgColor = strColor;
		if (strColor != "") {
			//If user has set a background.
			this.tf.background = true;
			this.tf.backgroundColor = parseInt(this.bgColor, 16);
		} else {
			//Else, we hide the existing background too.
			this.tf.background = false;
		}
	}
	/**
	* setText method sets the text to be displayed in the
	* tool tip.
	*	@param	strText	Text to be displayed as tool tip.
	*/
	public function setText(strText:String):Void {
		//Setting word-wrap to false. This is done to make sure that any previous
		//long tooltip (content width > sWidth) that had changed wordWrap to true
		//doesn't affect this one.
		this.tf.wordWrap = false;
		//Also setting width to undefined so that it can take automatically now
		this.tf._width = undefined;
		//Replace <BR> with \n or &lt;BR&gt; with \n if it's HTML text
		if (this.isHTML) {
			strText = StringExt.replace(strText, "<BR>", "\n");
			strText = StringExt.replace(strText, "&lt;BR&gt;", "\n");
			//Also replace small <br>
			strText = StringExt.replace(strText, "<br>", "\n");
			strText = StringExt.replace(strText, "&lt;br&gt;", "\n");
		}
		//Now, even if it is not HTML text, we need to replace {br} with \n
		//This is done on-demand (when tooltip is shown) to optimize pre-rendering
		//speed time, and also with the assumption that user might not always
		//see all the tooltips for a chart.
		strText = StringExt.replace(strText, "{br}", "\n");
		strText = StringExt.replace(strText, "{BR}", "\n");
		
		//Set the text to be displayed in the tool tip  
		this.txt = strText;
		//Set for text field
		if (this.isHTML) {
			this.tf.htmlText = this.txt;
		} else {
			this.tf.text = this.txt;
		}
		//Now, if the tooltip is getting wider than the originally alloted
		//canvas width, we need to wrap it automatically.
		if (this.tf._width>this.sWidth){
			//Set word wrap to true			
			this.tf.wordWrap = true;
			//Set width equal to canvas side, after leaving spacing on left & right
			this.tf._width = this.sWidth - 2*this.xPadding;
		}
		//Apply text format
		this.tf.setTextFormat(this.tFormat);
	}
	/**
	* show method shows the tool tip.
	*/
	public function show():Void {
		//Show the text field
		this.tf._visible = true;
		//Re-position the text field based on mouse cursor position
		this.rePosition();
	}
	/**
	* hide method hides the tool tip.
	*/
	public function hide():Void {
		//Hide the text field
		this.tf._visible = false;
	}
	/**
	* rePosition method repositions the tool tip (text field) based
	* on mouse position. Here, we also check that the tool tip shouldn't
	* move outside the stage area.
	*/
	public function rePosition():Void {
		//Get co-ordinates for parent parent movieclip - as we need
		//relative co-ordinates.
		var xm:Number = this.parent._xmouse;
		var ym:Number = this.parent._ymouse;
		//Adjust y-position first
		/** Y Position should always be above the y mouse (unless
		* no space is available on top). There can be two cases:
		* 1. Normal - 	We've space available on the top of yMouse
		*				so we position it normally.
		* 2. We do not have space available above y mouse. But we've
		* 				enough space below it. So position it below
		*				y-mouse.
		* 3. We neither have full space above y-mouse, nor below it.
		*				So, in this case position the best fit possible. 
		**/
		//We adjust only if the tool tip is visible
		if (this.tf._visible) {
			if (ym-this.tf._height-this.yPadding>this.sY) {
				//We've space above the y-mouse.
				this.tf._y = ym-this.tf._height-this.yPadding;
			} else if (this.sY+ym+this.tf._height+this.yPadding+15<this.sHeight)
			{
				//Else if we've space below the y-mouse.
				//15 represents mouse cursor height
				this.tf._y = ym+this.yPadding+15;
			}
			else {
				//If we do not have full space above the mouse, neither below the mouse.
				//Show it at the top, leaving just yPadding space.
				this.tf._y = this.sY + this.yPadding;
			}
			//Adjust x - position
			/** X Position should always be at the center of x mouse (unless
			* no space is available on left/right). There can be three cases:
			* 1. Normal - 	We've space available on left & right of xMouse
			*				so we position it normally.
			* 2. We do not have space available on the right. So, we've
			* 	  to position it a little left. We DO use whatever space
			* 	  is available on the left, though.
			* 3. We do not have space available on the left. So, we've
			* 	  to position it a little right. We DO use whatever space
			* 	  is available on the right, though.
			**/
			if ((xm+this.tf._width/2)>(this.sWidth+this.sX)) {
				//Case 2
				//this.tf._x = xm-this.tf._width;
				this.tf._x = this.sWidth-this.xPadding-this.tf._width;
			} else if ((xm-this.tf._width/2)<this.sX) {
				//Case 3
				//this.tf._x = xm - this.sX + this.xPadding;
				this.tf._x = this.xPadding;
			} else {
				//Normal
				this.tf._x = xm-(this.tf._width/2);
			}
		}
	}
	/**
	* visible method returns the visibility of tool tip.
	*/
	public function visible():Boolean {
		//Just return the visibility of text field
		return this.tf._visible;
	}
	/**
	* destroy method MUST be called whenever you wish to delete this class's
	* instance.
	*/
	public function destroy():Void {
		//Delete text field and text format object
		this.tf.removeTextField();
		delete this.tFormat;
	}
}
