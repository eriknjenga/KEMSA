/**
 * @class AnnotationGroup
 * @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
 * @version 3.0
 *
 * Copyright (C) InfoSoft Global Pvt. Ltd. 2005-2006
 * AnnotationGroup represents a single annotation group in
 * the annotation manager. Each annotation group can have 
 * multiple annotations inside it. Each group is responsible
 * for drawing it's own annotations. 
*/
import com.fusioncharts.is.helper.FCEnum;
import com.fusioncharts.is.helper.FCError;
import com.fusioncharts.is.helper.Utils;
import com.fusioncharts.is.helper.Logger;
//Extensions
import com.fusioncharts.is.extensions.ColorExt;
import com.fusioncharts.is.extensions.DrawingExt;
class com.fusioncharts.is.helper.AnnotationGroup{
	//Enumeration for the various annotation type that's supported
	private var TYPE:FCEnum;
	//Movie clip holder for this group
	private var mc:MovieClip;
	//Items within this annotation group
	private var item:Array;
	private var num:Number;
	//X and Y Position (w.r.t parent container)
	private var x:Number;
	private var y:Number;
	//X and Y Scale (user-defined) for the group
	private var xScale:Number;
	private var yScale:Number;
	//Alpha of entire group
	private var alpha:Number;
	//Current Stage width and height
	private var stageW:Number;	
	private var stageH:Number;
	//Original width and height of stage with whose respect the
	//co-ordinates are being given.
	private var origW:Number;
	private var origH:Number;
	//Whether to auto scale w.r.t orignal W and H
	private var autoScale:Boolean;
	//Whether to do a constrained scaling.
	private var constrainedScale:Boolean;
	//Whether to auto-scale images too?
	private var scaleImages:Boolean;
	//Wheter to auto-scale text?
	private var scaleText:Boolean;
	//X and Y Shift for the entire group (for correction purposes mainly)
	private var xShift:Number;
	private var yShift:Number;
	//Calculated scale factors
	private var scaleFactorX:Number;
	private var scaleFactorY:Number;
	//Short forms for common function names
	private var getFV:Function;
	private var getFN:Function;
	private var toBoolean:Function;
	private var formatColor : Function;
	//We'll store all the movie clip loader instances in array
	//so that we can later refer directly to them during destruction.
	private var mclStack:Array;
	/**
	 * Constructor function for AnnotationGroup.	
	 *	@param	x			X-Position of the group w.r.t parent container
	 *	@param	y			Y-Position of the group w.r.t parent container
	 *	@param	xScale		X-Scaling that we've to apply to the entire group.
	 *	@param	yScale		Y-Scaling that we've to apply to the entire group.
	 *	@param	alpha		Alpha that we've to apply to the entire group.
	 *	@param	stageW		Current width of the stage in which this annotation
	 *						group would be present.
	 *	@param	stageH		Current height of the stage in which this annotation
	 *						group would be present.
	 *	@param	origW		Original width of the stage for which the co-ordinates
	 *						have been defined. Useful when the user defines the 
	 *						co-ordinates for one size, but wants to scale it to bigger
	 *						size. So, he won't have to do it manually. 
	 *	@param	origH		Original height of the stage for which the co-ordinates
	 *						have been defined.
	 *	@param	autoScale	Whether to scale the entire annotation group w.r.t to the new
	 *						width and height.
	 *	@param	constrainedScale	Whether to scale the group in constrained way?
	 *	@param	scaleImages	Whether to scale the images or keep them at original size.
	 *	@param	scaleText	Whether to scale the text, or keep them at original size?
	 *	@param	xShift		If even after scaling, the entire group needs to be x-shifted,
	 *						this parameter specifies the shift.
	 *	@param	yShift		If even after scaling, the entire group needs to be y-shifted,
	 *						this parameter specifies the shift. 
	*/
	function AnnotationGroup(x:Number, y:Number, xScale:Number, yScale:Number, alpha:Number, stageW:Number, stageH:Number, origW:Number, origH:Number, autoScale:Boolean, constrainedScale:Boolean, scaleImages:Boolean, scaleText:Boolean, xShift:Number, yShift:Number){
		//Short forms for common function names.
		this.getFV = Utils.getFirstValue;
		this.getFN = Utils.getFirstNumber;
		this.toBoolean = Utils.toBoolean;
		//Get reference to ColorExt.formatHexColor
		this.formatColor = ColorExt.formatHexColor;
		//Enumerate the supported Annotation Types
		TYPE = new FCEnum("RECTANGLE", "CIRCLE", "POLYGON", "LINE", "ARC", "TEXT", "IMAGE");
		//Store parameters in instances variables		
		this.x = x;
		this.y = y;
		this.xScale = xScale;
		this.yScale = yScale;
		this.alpha = alpha;
		this.stageW = stageW;
		this.stageH = stageH;
		this.origW = origW;
		this.origH = origH;
		this.autoScale = autoScale;
		//If Original width,height == stage width,height, we set autoScale to false
		if (this.origW == this.stageW && this.origH ==this.stageH){
			this.autoScale = false;
		}
		this.constrainedScale = constrainedScale;
		this.scaleImages = scaleImages;
		this.scaleText = scaleText;
		this.xShift = xShift;
		this.yShift = yShift;		
		//Initialize array to store the items of this annotation group
		this.item = new Array();
		//Initialize number of items to 0.
		this.num = 0;
		//Scale factors
		this.scaleFactorX = 1;
		this.scaleFactorY = 1;
		//Initialize movie clip loader stack
		this.mclStack = new Array();
	}
	/**
	 * setContainerMC sets the reference of the movie clip in which we'll have to
	 * draw the annotation. We've separated this function from constructor, as during
	 * constructor, we do not have reference to the MCs.
	 *	@param	mc			Movie clip holder in which the entire group
	 *						will be rendered.
	*/
	public function setContainerMC(mc:MovieClip){
		//Just store it
		this.mc = mc;
	}
	/**
	 * addItem method adds an item to the annotation group. Each item can have
	 * multitude of parameters. We store all of them in an object instead of another
	 * sub-class to keep things more flexible. We directly accept the XML Node of the
	 * annotation to parse attributes here.
	 *	@param	itemNode	XML Node representing the <annotation> or <object> node.
	*/
	public function addItem(itemNode:XMLNode):Void{
		//We've received the <annotation> object as a node. So, we need to parse.
		//First, get an array of attributes of this node in a case in-sensitive form.
		var atts:Array = Utils.getAttributesArray(itemNode);
		//Create a local object to store the item
		var obj:Object = new Object();
		//Read type value
		obj.type = getTypeId(atts["type"]);
		//If type is -1, we throw an error. Else, we add the item
		if (obj.type==-1){
			//Throw error
			throw new FCError("Invalid Annotation Type", "Invalid Annotation type \""+atts["type"]+"\" specified. Only possible values for Annotation types are RECTANGLE, CIRCLE, POLYGON, LINE, ARC, TEXT & IMAGE.", Logger.LEVEL.ERROR);
		}else{
			//Continue extracting properties
			//X and Y Position of the annotation inside the annotation group
			//Note: This X and Y is w.r.t annotation group and not global.
			obj.x = getFN(atts["x"], atts["xpos"], 0);
			obj.y = getFN(atts["y"], atts["ypos"], 0);			
			
			//Cosmetics
			//Alpha of this annotation
			obj.alpha = getFN(atts["alpha"], 100);
			//Generic color property, from which font color, fill color and border color will derive.
			obj.color = formatColor(getFV(atts["color"], atts["linecolor"], "ff5904"));
			//Line thickness
			obj.thickness = getFN(atts["thickness"], atts["linethickness"], 2);			
			
			//Specific functional properties
			//Radius for circle, arc, polygon etc.
			//Round-radius in case of rectangle
			obj.radius = getFN(atts["radius"], (obj.type == this.TYPE.RECTANGLE) ? (0) : (0.3*(Math.min(this.stageW,this.stageH))));
			//Y-radius
			obj.yRadius = getFN(atts["yradius"], obj.radius);
			//Inner radius for arc - by default 80% of outer radius
			obj.innerRadius = getFN(atts["innerradius"], 0.8*obj.radius);
			//Radius cannot be greater than inner radius
			if (obj.innerRadius>obj.radius){
				//Swap them
				var ir:Number = obj.innerRadius;
				obj.innerRadius = obj.radius;
				obj.radius = ir;
			}

			//To x and to y positions for rectangle, line etc.
			//We're not putting this in case specific conditional block to 
			//use generalized logic while drawing and avoiding code repition 
			//in cases of circle.
			obj.toX = getFN(atts["tox"], atts["toxpos"], obj.x);
			obj.toY = getFN(atts["toy"], atts["toypos"], obj.y);
			
			//Dashed properties, if line
			if (obj.type == this.TYPE.LINE){
				//Whether the line should appear as dashed?
				obj.dashed = toBoolean(getFN(atts["dashed"], 0));
				obj.dashLen = getFN(atts["dashlen"], 3);
				obj.dashGap = getFN(atts["dashgap"], 3);
			}
			
			//If it's an image node
			if (obj.type == this.TYPE.IMAGE){
				//URL of image
				obj.url= getFV(atts["url"],"");
				//X and Y Scale for individual annotation
				obj.xScale = getFN(atts["xscale"], 100);
				obj.yScale = getFN(atts["yscale"], 100);
			}
			
			//Only if circle or polygon or arc
			if (obj.type == this.TYPE.CIRCLE  || obj.type == this.TYPE.POLYGON || obj.type == this.TYPE.ARC){
				//Start angle for polygon/arc
				obj.startAngle = getFN(atts["startangle"], 0);
				//End angle for polygon/arc
				obj.endAngle = getFN(atts["endangle"], 360);
				//Number of sides for polygon
				obj.sides = getFN(atts["sides"], atts["numsides"], 5);			
			}
			
			//Font properties - only if text
			if (obj.type == this.TYPE.TEXT){
				obj.isHTML = toBoolean(getFN(atts["ishtml"], 1));
				obj.font = getFV(atts["font"], "Verdana");
				obj.fontSize = getFN(atts["size"], atts["fontsize"], 10);
				obj.fontColor = formatColor(getFV(atts["color"], atts["fontcolor"], obj.color));
				obj.bold = toBoolean(getFN(atts["bold"], atts["isbold"], 0));
				obj.italic = toBoolean(getFN(atts["italic"], 0));
				obj.underline = toBoolean(getFN(atts["underline"], 0));
				obj.align = getFV(atts["align"], "center");
				obj.vAlign = getFV(atts["valign"], "middle");
				obj.letterSpacing = getFN(atts["letterspacing"], 0);
				obj.leftMargin = getFN(atts["leftmargin"], 0);
				obj.label = getFV(atts["label"], "");
				obj.bgColor = formatColor(getFV(atts["bgcolor"],""));
				obj.borderColor = formatColor(getFV(atts["bordercolor"],""));
				//Wrap properties
				obj.wrap = toBoolean(getFN(atts["wrap"], 0));
				obj.wrapWidth = getFN(atts["wrapwidth"], this.stageW);
				obj.wrapHeight = getFN(atts["wrapheight"], this.stageH);
			}
			
			//Fill and border properties, only in case of Rectangle, Circle, Polygon, Arc
			if (obj.type == this.TYPE.RECTANGLE || obj.type == this.TYPE.CIRCLE || obj.type == this.TYPE.POLYGON || obj.type == this.TYPE.ARC){
				obj.fillColor = ColorExt.parseColorList(getFV(atts["fillcolor"], obj.color));				
				obj.fillAlpha = ColorExt.parseAlphaList(getFV(atts["fillalpha"], "100"),obj.fillColor.length);
				obj.fillRatio = ColorExt.parseRatioList(getFV(atts["fillratio"], ""),obj.fillColor.length);
				obj.fillAngle = getFV(atts["fillangle"], atts["filldegree"], 0);				
				obj.fillPattern = getFV(atts["fillpattern"], ((obj.type == this.TYPE.CIRCLE || obj.type == this.TYPE.ARC) ? ("radial") : ("linear")));
				obj.fillPattern = obj.fillPattern.toLowerCase();
				//Restrict fillpattern to linear or radial
				if (obj.fillPattern!="radial" && obj.fillPattern!="linear"){
					obj.fillPattern="linear";
				}
				obj.showBorder = toBoolean(getFN(atts["showborder"], atts["bordercolor"]==undefined?0:1));
				obj.borderColor = formatColor(getFV(atts["bordercolor"], obj.color));
				obj.borderThickness = getFN(atts["borderthickness"], obj.thickness);
				obj.borderAlpha = getFN(atts["borderalpha"], 100);
				//If border is not to be shown, we set alpha as 0
				if (!obj.showBorder){
					obj.borderAlpha = 0;
				}
			}
			//Update counter
			this.num++;
			//Add the object to our items array
			this.item[num] = obj;			
		}
	}
	/**
	 * calculateScale method calculates the scaling for the annotation items.
	*/
	private function calculateScale():Void{
		//Scaling for manipulation of items position. Do scaling only if autoScale is on.
		if (this.autoScale){
			//Now, if the ratio of original width,height & stage width,height are same
			if ((this.origW / this.stageW) == (this.origH / this.stageH)){
				//In this case, the transformation value would be the same, as the ratio
				//of transformation of width and height is same.
				this.scaleFactorX = this.stageW/this.origW;
				this.scaleFactorY = this.scaleFactorX;
			}else{
				//If the transformation factors are different, we check if we've to do
				//constrained scaling. 
				if (this.constrainedScale){
					//If we've to do constrained scaling, we get the aspect whose delta
					//is on the lower side.
					this.scaleFactorX = Math.min((this.stageW/this.origW),(this.stageH/this.origH));
					this.scaleFactorY = this.scaleFactorX;
				} else {
					//Non-constrained scaling
					this.scaleFactorX = this.stageW/this.origW;
					this.scaleFactorY = this.stageH/this.origH;
				}
			}
		}
	}
	/**
	 * draw method draws all the items in this annotation group, after applying
	 * proper scaling, shifting etc.
	*/
	public function draw(){
		//Calculate the scale factor before drawing
		this.calculateScale();
		//Loop variable
		var i:Number;		
		//Shift the group movie clip (with offset)
		this.mc._x = this.x + this.xShift;
		this.mc._y = this.y + this.yShift;
		//Apply scaling to it (user specified explicit scaling)
		this.mc._xscale = this.xScale;
		this.mc._yscale = this.yScale;		
		//Temporary storage variables
		var x:Number, y:Number, toX:Number, toY:Number, radius:Number, yRadius:Number, innerRadius:Number;
		//Iterate through all the items
		for (i=1; i<=this.num; i++){
			//Update x and y position of the item based on scaling.
			//We take in account the co-ordinates of group container movie clip
			//too, as we do not directly adjust it's x and y. 
			x = (this.x + this.item[i].x)*this.scaleFactorX - this.x;
			y = (this.y + this.item[i].y)*this.scaleFactorY - this.y;
			//If it's circle, arc or polygon, we need to update radius
			if (this.item[i].type==this.TYPE.CIRCLE || this.item[i].type==this.TYPE.ARC || this.item[i].type==this.TYPE.POLYGON){
				radius = this.item[i].radius * scaleFactorX;
				yRadius = this.item[i].yRadius * scaleFactorY;
				innerRadius = this.item[i].innerRadius * scaleFactorX;
			}
			//Create movie clip container to hold the item within the annotation group.
			var itemMC:MovieClip = this.mc.createEmptyMovieClip("Item_"+i,this.mc.getNextHighestDepth());
			//Set the alpha
			itemMC._alpha = this.item[i].alpha;			
			//Start drawing based on type of the item.
			switch (this.item[i].type){
				case this.TYPE.TEXT:					
					//We need to create text type. Create an object representing properties
					//that we'll send to createText method.
					var textStyle:Object = new Object();
					//Set the properties and defaults
					textStyle.align = this.item[i].align;
					textStyle.vAlign = this.item[i].vAlign;
					textStyle.bold = this.item[i].bold;
					textStyle.italic = this.item[i].italic;
					textStyle.underline = this.item[i].underline;
					textStyle.font = this.item[i].font;
					textStyle.size = (this.scaleText)?(this.item[i].fontSize*Math.min(this.scaleFactorX, this.scaleFactorY)):(this.item[i].fontSize);
					textStyle.color = this.item[i].fontColor;
					textStyle.isHTML = this.item[i].isHTML;
					textStyle.leftMargin = this.item[i].leftMargin;
					textStyle.letterSpacing = this.item[i].letterSpacing;
					textStyle.bgColor = this.item[i].bgColor;
					textStyle.borderColor = this.item[i].borderColor;
					//Finally, create the text.
					Utils.createText(false, this.item[i].label, itemMC, itemMC.getNextHighestDepth(), 0, 0, 0, textStyle, this.item[i].wrap, this.item[i].wrapWidth, this.item[i].wrapHeight);
					itemMC._x = x;
					itemMC._y = y;
					break;
				case this.TYPE.LINE:
					//Scale toX and toY. Keep group MC start X and Y into consideration.
					toX = (this.x + this.item[i].toX)*this.scaleFactorX - this.x;
					toY = (this.x + this.item[i].toY)*this.scaleFactorY - this.x;					
					//We'll draw the line with 0,0 as center for animation
					//So, calculate the width & height for the same.
					var w:Number = toX-x;
					var h:Number = toY-y;
					//Find start and center position based on the width & height
					var sX:Number, sY:Number, eX:Number, eY:Number;
					var cX:Number, cY:Number;
					//Get width, height to keep registration point at 0,0.
					if (w>=0){
						sX = -w/2;
						eX = w/2;
						cX = x + w/2;
					}else{
						sX = Math.abs(w)/2;
						eX = w/2;
						cX = toX + Math.abs(w)/2;
					}
					if (h>=0){
						sY = -h/2;
						eY = h/2;
						cY = y + h/2;
					}else{
						sY = Math.abs(h)/2;
						eY = h/2;
						cY = toY + Math.abs(h)/2;
					}					
					//Set the cosmetic properties					
					itemMC.lineStyle(this.item[i].thickness, parseInt(this.item[i].color,16), this.item[i].alpha);
					//Now, based on whether we've to draw a solid or dashed line.
					if (this.item[i].dashed){
						DrawingExt.dashTo(itemMC, sX, sY, eX, eY, this.item[i].dashLen, this.item[i].dashGap);
					}else{
						itemMC.moveTo(sX, sY);
						itemMC.lineTo(eX, eY);
					}
					//Position the entire movie clip
					itemMC._x = cX;
					itemMC._y = cY;										
					break;
				case this.TYPE.RECTANGLE:
					//Calculate scaled x and y positions.
					//x always represents starting x and toX represents ending X. Same with y,toY.
					x = (this.x + Math.min(this.item[i].x,this.item[i].toX))*this.scaleFactorX - this.x;
					y = (this.y + Math.min(this.item[i].y,this.item[i].toY))*this.scaleFactorY - this.y;
					//Scale toX and toY. Keep group MC start X and Y into consideration.
					toX = (this.x + Math.max(this.item[i].x, this.item[i].toX))*this.scaleFactorX - this.x;
					toY = (this.x + Math.max(this.item[i].y, this.item[i].toY))*this.scaleFactorY - this.x;					
					//Calculate width and height of the rectangle
					var w:Number = toX-x;
					var h:Number = toY-y;
					//Set the cosmectic properties					
					itemMC.lineStyle(this.item[i].borderThickness, parseInt(this.item[i].borderColor,16), this.item[i].borderAlpha);					
					//Set gradient fill
					itemMC.beginGradientFill(this.item[i].fillPattern, this.item[i].fillColor, this.item[i].fillAlpha, this.item[i].fillRatio, {matrixType:"box", x:-w/2, y:-h/2, w:w, h:h, r:((360-this.item[i].fillAngle)/180)*Math.PI});
					//Draw keeping 0,0 as registration point (helps in scale animation)
					DrawingExt.drawRoundedRect(itemMC, -w/2, -h/2, w, h, {tl:this.item[i].radius, tr:this.item[i].radius, bl:this.item[i].radius, br:this.item[i].radius}, {l:parseInt(this.item[i].borderColor,16), r:parseInt(this.item[i].borderColor,16), t:parseInt(this.item[i].borderColor,16), b:parseInt(this.item[i].borderColor,16)}, {l:this.item[i].borderAlpha, r:this.item[i].borderAlpha, t:this.item[i].borderAlpha, b:this.item[i].borderAlpha}, {l:this.item[i].borderThickness, r:this.item[i].borderThickness, t:this.item[i].borderThickness, b:this.item[i].borderThickness})
					//End fill
					itemMC.endFill();
					//Shift the movie clip internally to get the right co-ordinates
					itemMC._x = x + w/2;
					itemMC._y = y + h/2;					
					break;				
				case this.TYPE.CIRCLE:
					//Set the cosmectic properties					
					itemMC.lineStyle(this.item[i].borderThickness, parseInt(this.item[i].borderColor,16), this.item[i].borderAlpha);					
					//Keep the center of gradient at left side
					itemMC.beginGradientFill(this.item[i].fillPattern, this.item[i].fillColor, this.item[i].fillAlpha, this.item[i].fillRatio, {matrixType:"box", x:-radius, y:-yRadius, w:radius*2, h:yRadius*2, r:((360-this.item[i].fillAngle)/180)*Math.PI});
					//Draw keeping 0,0 as registration point at center
					DrawingExt.drawCircle(itemMC, 0, 0, radius, yRadius, this.item[i].startAngle, this.item[i].endAngle - this.item[i].startAngle);
					//End fill
					itemMC.endFill();
					//Shift the movie clip internally to get the right co-ordinates
					itemMC._x = x;
					itemMC._y = y;
					break;
				case this.TYPE.POLYGON:
					//Set the cosmectic properties					
					itemMC.lineStyle(this.item[i].borderThickness, parseInt(this.item[i].borderColor,16), this.item[i].borderAlpha);					
					//Keep the center of gradient at left side
					itemMC.beginGradientFill(this.item[i].fillPattern, this.item[i].fillColor, this.item[i].fillAlpha, this.item[i].fillRatio, {matrixType:"box", x:-radius, y:-radius, w:radius*2, h:radius*2, r:((360-this.item[i].fillAngle)/180)*Math.PI});
					//Draw keeping 0,0 as registration point at center
					DrawingExt.drawPoly(itemMC, 0, 0, this.item[i].sides, radius, this.item[i].startAngle);					
					//End fill
					itemMC.endFill();
					//Shift the movie clip internally to get the right co-ordinates
					itemMC._x = x;
					itemMC._y = y;					
					break;
				case this.TYPE.ARC:
					//Store end points
					var ax:Number, ay:Number;
					var bx:Number, by:Number;
					ax = Math.cos(this.item[i].endAngle/180*Math.PI)*innerRadius;
					ay = Math.sin(-this.item[i].endAngle/180*Math.PI)*innerRadius;
					bx = Math.cos(this.item[i].startAngle/180*Math.PI)*radius;
					by = Math.sin(-this.item[i].startAngle/180*Math.PI)*radius;
					//We'll draw the border and fill separately because of the strange
					//behavior in beginFill which connects to the start point, irrespective
					//of specifying all co-ordinates.
					
					//Get the sweep angle
					var sweepAngle:Number = Math.abs(this.item[i].endAngle-this.item[i].startAngle);																				
					//First, draw the fill without any border.
					//--------------------------------------------------------------//
					itemMC.lineStyle();
					itemMC.beginGradientFill(this.item[i].fillPattern, this.item[i].fillColor, this.item[i].fillAlpha, this.item[i].fillRatio, {matrixType:"box", x:-radius, y:-radius, w:radius*2, h:radius*2, r:((360-this.item[i].fillAngle)/180)*Math.PI});
					DrawingExt.drawCircle(itemMC, 0, 0, radius, radius, this.item[i].startAngle, this.item[i].endAngle-this.item[i].startAngle);
					itemMC.lineTo(ax , ay);
					DrawingExt.drawCircle(itemMC, 0, 0, innerRadius, innerRadius, this.item[i].endAngle, -(this.item[i].endAngle-this.item[i].startAngle));
					itemMC.lineTo(bx, by);
					itemMC.endFill();
					//--------------------------------------------------------------//
					//Now, draw the border only.					
					if (this.item[i].showBorder){						
						//Set the cosmectic properties					
						itemMC.lineStyle(this.item[i].borderThickness, parseInt(this.item[i].borderColor,16), this.item[i].borderAlpha);										
						//Draw the outer arc
						DrawingExt.drawCircle(itemMC, 0, 0, radius, radius, this.item[i].startAngle, this.item[i].endAngle-this.item[i].startAngle);
						//Move to left side start of inner circle
						//If it's more than 360, we do not draw any internal line connectors.
						if (sweepAngle<360) {							
							itemMC.lineTo(ax, ay);
						}
						//Draw inner circle
						DrawingExt.drawCircle(itemMC, 0, 0, innerRadius, innerRadius, this.item[i].endAngle, -(this.item[i].endAngle-this.item[i].startAngle));
						//Join with outer circle
						if (sweepAngle<360) {
							itemMC.lineStyle(this.item[i].borderThickness, parseInt(this.item[i].borderColor,16), this.item[i].borderAlpha);						
							itemMC.lineTo(bx, by);
						}
					}					
					//Shift the movie clip internally to get the right co-ordinates
					itemMC._x = x;
					itemMC._y = y;
					break;				
				case this.TYPE.IMAGE:
					//We'll create an instance of the Movie Clip loader to load
					//the image / SWF file
					var mcl:MovieClipLoader = new MovieClipLoader();					
					//Calculate the required scale of image
					var imgXScale:Number = this.item[i].xScale;
					var imgYScale:Number = this.item[i].yScale;
					//If we've to scale images, then apply the factors
					if (this.scaleImages){
						imgXScale = imgXScale * this.scaleFactorX;
						imgYScale = imgYScale * this.scaleFactorY;
					}
					//Create a listener object
					var mclL:Object = new Object();
					mclL.onLoadInit = function(target_mc:MovieClip){
						//Scale the image movie clip internally.
						target_mc._xscale = imgXScale;
						target_mc._yscale = imgYScale;
					}
					mcl.addListener(mclL);
					//Load the image
					mcl.loadClip(this.item[i].url, itemMC);
					//Push it in the stack as an object.
					var objStack:Object = new Object();
					objStack.mcl = mcl;
					objStack.listener = mclL;
					objStack.holder = itemMC;
					this.mclStack.push(objStack);
					//Set the X and Y of container movie clip
					itemMC._x = x;
					itemMC._y = y; 
					break;
			}
		}
	}
	/**
	 * getTypeId method returns the id of a given annotation type.
	 * Id is the numerical value stored in TYPE enumeration of this class.
	 *	@param	strType		Type of annotation whose id we want to find.
	 *	@return				The id of the type if found. Else -1
	*/
	private function getTypeId(strType:String):Number {
		//If it's undefined, return 1 straight off.
		if (strType=="" || strType==undefined || strType==null){
			return -1;
		}
		//Capitalize strType for case-insensitive match
		strType = strType.toUpperCase();
		return this.TYPE.getItem(strType);
	}
	/**
	 * destroy method destroys the instance of the annotation group
	*/
	public function destroy():Void{
		//Remove all the movie clip loader listeners
		var i:Number;
		for (i=0; i<this.mclStack.length; i++){
			//Unload the movie
			this.mclStack[i].mcl.unloadClip(this.mclStack[i].holder);
			//Remove the listener
			this.mclStack[i].mcl.removeListener(this.mclStack[i].listener);			
		}
		//Remove the movie clip which was created for this group
		//Removing the movie clip automatically removes any nested movie clips.
		mc.removeMovieClip();
		//Delete instance variables
		delete this.TYPE;
		delete this.item;
		delete this.mclStack;
	}
}