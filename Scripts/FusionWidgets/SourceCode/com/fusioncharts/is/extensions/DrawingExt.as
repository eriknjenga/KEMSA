/**
* @class DrawingExt
* @author InfoSoft Global (P) Ltd.
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd. 
*
* Drawing class groups a bunch of drawing functions.
*/
class com.fusioncharts.is.extensions.DrawingExt {
	/**
	* Since DrawingExt class is just a grouping of drawming related methods,
	* we do not want any instances of it (as all methods wil be static).
	* So, we declare a private constructor
	*/
	private function DrawingExt() {
		//Private constructor to avoid creation of instances
	}
	/**
	* dashTo method helps draw a dashed line between any two points
	* for the given movie, with the required spacing in between.
	*	Assumptions: Movie clip is already created and line style has
	*				 already been set before this method is called to
	*				 draw a dashed line.
	*	@param		mc		Movie clip in which we've to draw the line
	*	@param		x		Starting x Point from where dashed line needs
	*						to be drawn.
	*	@param		y		Starting y Point from where dashed line needs
	*						to be drawn.
	*	@param		toX		Ending x Point from where dashed line needs
	*						to end.
	*	@param		toY		Ending y Point from where dashed line needs
	*						to end.
	*	@param		len		Length of each dash.
	*	@param		gap		Gap between two dashes.
	*	@return				Boolean value indicating whether the line was
	*						successfully drawn.
	*/
	public static function dashTo(mc:MovieClip, x:Number, y:Number, toX:Number, toY:Number, len:Number, gap:Number):Boolean {
		//If we've less than 7 arguments (function parameters), we exit
		if (arguments.length<7) {
			return false;
		}
		if (len<=0) {
			return false;
		}
		//Variables to store calculation   
		//dashLen indicates total dash length (including gap)
		var dashLen:Number = len+gap;
		//dX indicates the x displacement (starting, ending)
		var dX:Number = toX-x;
		//dY indicates y displacement
		var dY:Number = toY-y;
		//Distance indicates co-ordinate distance between 2 points
		//dis = sq. rt((toX-x)^2 + (toY-y)^2));
		var distance:Number = Math.sqrt(Math.pow(dX, 2)+Math.pow(dY, 2));
		//numDash indicates total dash segments that we need to draw
		//We take floor (so that partial dash is left out) of absolute
		//value(so that end X can be less than start X - and same with Y);
		var numDash:Number = Math.floor(Math.abs(distance/dashLen));
		//Angle indicates the angle of the line ATan of (dy/dX)
		var angle:Number = Math.atan2(dY, dX);
		//sX and sY indicate start of line - counters
		var sX:Number = x;
		var sY:Number = y;
		//Add the segment length (discounted by the proper angle) to get
		//next line point (next dash segment start)
		dX = Math.cos(angle)*dashLen;
		dY = Math.sin(angle)*dashLen;
		//Now draw all the segments
		var i:Number = 0;
		for (i=0; i<numDash; i++) {
			//Move to starting point of this dash segment
			mc.moveTo(sX, sY);
			//Draw the line to the end of this dash segment (len)
			mc.lineTo(sX+Math.cos(angle)*len, sY+Math.sin(angle)*len);
			//Update sX and sY to include gap - so that they point to
			//start of next dash segment
			sX += dX;
			sY += dY;
		}
		//Now, the last dash segment can be less than 1*dashLen (as it
		//can be partial)
		//Move to the end of last drawn dash
		mc.moveTo(sX, sY);
		//Re-calculate the distance for the last dash - again using square root
		//distance method.
		distance = Math.sqrt(Math.pow((toX-sX), 2)+Math.pow((toY-sY), 2));
		//If the last dash length gets included in the dash length, we draw
		//it full.
		if (distance>len) {
			mc.lineTo(sX+Math.cos(angle)*len, sY+Math.sin(angle)*len);
		} else if (distance>0) {
			//Else, it means that we do not have space to draw full dash
			//So, we draw only the remaining space.
			mc.lineTo(sX+Math.cos(angle)*distance, sY+Math.sin(angle)*distance);
		}
		//Move the drawing pointer to the end position- so that if further drawing is   
		//done, it starts from the end position
		mc.moveTo(toX, toY);
		return true;
	}
	/**
	* drawPoly method helps draw a polygon based on the parameters specified.
	*	Assumptions: Movie clip is already created and line/fill style has
	*				 already been set before this method is called to
	*				 draw a polygon.
	*	@param		mc		Movie clip in which we've to draw the polygon
	*	@param		x		Center X position of the polygon
	*	@param		sides	Number of sides required for polygon (min 3).
	*	@param		startAngle	Starting angle of the polygon in degrees. Default is 0.
	*/
	public static function drawPoly(mc:MovieClip, x:Number, y:Number, sides:Number, radius:Number, startAngle:Number):Void {
		//If we've been given less than 5 arguments, return, as we cannot draw.
		if (arguments.length<5) {
			return;
		}
		//Check if minimum 3 sides   
		if (sides>2) {
			//Default for starting angle
			startAngle = (startAngle == null || startAngle == undefined) ? 0 : startAngle;
			//Variables to store incremental angle
			var incAngle:Number;
			//Loop variable
			var i:Number;
			//Increment angle for each side
			incAngle = (Math.PI*2)/sides;
			//Starting angle for polygon. Convert to radians.
			startAngle = (startAngle/180)*Math.PI;
			//Move to initial position based on start angle
			mc.moveTo(x+(Math.cos(startAngle)*radius), y-(Math.sin(startAngle)*radius));
			//Draw all the sides
			for (i=1; i<=sides; i++) {
				//Points are calculated by adding incremental angle and then using sin/cos.
				mc.lineTo((x+Math.cos(startAngle+(incAngle*i))*radius), (y-Math.sin(startAngle+(incAngle*i))*radius));
			}
		}
	}
	/**
	 * drawRoundedRect method helps draw a rounded Rectangle based on the parameters specified.
	 * To keep this function as generic as possible, we accept corner radius for all the 4 corners.
	 * Apart from that, we also accept different line properties for the 4 lines.
	 * The rounded corners are drawn in 2 parts each, so that we just have 4 lines,
	 * instead of 4 lines and 4 corners.
	 *	Assumptions: Movie clip is already created. If corner radius us 0, then we assume that 
	 *				 line/fill style has already been set before this method is called to
	 *				 draw a rectangle.
	 *	@param		mc			Movie clip in which we've to draw the rounded rectangle
	 *	@param		x			Top Left X position of the rectangle.
	 *	@param		y			Top left Y position of the rectangle
	 *	@param		w			w width of the rectangle
	 *	@param		h			height of the rectangle
	 *	@param		objRadius	Since we're giving the option to provide 4 different corner radius
	 *							for 4 corners, this object accepts the radius as following
	 *							parameters:
	 *							- tl - Corner radius of top left
	 *							- tr - Corner radius of top right
	 *							- bl - Corner radius of bottom left
	 *							- br - Corner radius of bottom right
	 *	@param		objColor	We also accept 4 different colors for 4 sides.
	 *							- l - Color for left line
	 *							- r - Color for right line
	 *							- t - Color for top line
	 *							- b - Color for bottom line
	 *	@param		objAlpha	Like corner radius, we also accept 4 different line alpha for the 4 sides.
	 *							This makes it possible for us to hide any side's border, as we might
	 *							need in particular cases.
	 *							- l - Alpha for left line
	 *							- r - Alpha for right line
	 *							- t - Alpha for top line
	 *							- b - Alpha for bottom line	 
	 *	@param		objThickness	We also accept 4 different thickness for 4 sides.
	 *								- l - Thickness for left line
	 *								- r - Thickness for right line
	 *								- t - Thickness for top line
	 *								- b - Thickness for bottom line
	 *	@return		Nothing
	 */
	public static function drawRoundedRect(mc:MovieClip, x:Number, y:Number, w:Number, h:Number, objRadius:Object, objColor:Object, objAlpha:Object, objThickness:Object):Void {
		//We first make a check if the user has defined any corner radius as non zero. Else, we simply plot it as
		//a rectangle, as none of the corner calculations are required.
		if (!(objRadius.tl == 0 && objRadius.tr == 0 && objRadius.bl == 0 && objRadius.br == 0)) {
			//If w is negative, we shift x position by that much and then make width positive
			if (w<0){
				x = x + w;
				w = Math.abs(w);
			}
			//If h is negative, we shift y position by that much and then make height positive
			if (h<0){
				y = y + h;
				h = Math.abs(h);
			}
			//We check if the radius do not exceed the total width
			if ((objRadius.tl + objRadius.tr)>w){
				//Re-set radius to half
				objRadius.tl = Math.round(w/2);
				objRadius.tr = Math.round(w/2);
			}
			if ((objRadius.bl + objRadius.br)>w){
				//Re-set radius to half
				objRadius.bl = Math.round(w/2);
				objRadius.br = Math.round(w/2);
			}
			
			//Initialize variables to be used
			var theta:Number, angle:Number, cx:Number, cy:Number, px:Number, py:Number;
			//Each rounded corner will be plotted in 2 parts of 45 degrees each
			theta = Math.PI/4;
			//Draw the top line
			//Set the lineStyle according to top line style
			mc.lineStyle(objThickness.t, objColor.t, objAlpha.t, true, "none", "round", "round", 1);
			mc.moveTo(x+objRadius.tl, y);
			mc.lineTo(x+w-objRadius.tr, y);
			//Angle is currently 90 degrees
			angle = -Math.PI/2;
			//Draw the round part
			cx = x+w-objRadius.tr+(Math.cos(angle+(theta/2))*objRadius.tr/Math.cos(theta/2));
			cy = y+objRadius.tr+(Math.sin(angle+(theta/2))*objRadius.tr/Math.cos(theta/2));
			px = x+w-objRadius.tr+(Math.cos(angle+theta)*objRadius.tr);
			py = y+objRadius.tr+(Math.sin(angle+theta)*objRadius.tr);
			mc.curveTo(cx, cy, px, py);
			//Second round part.
			angle += theta;
			cx = x+w-objRadius.tr+(Math.cos(angle+(theta/2))*objRadius.tr/Math.cos(theta/2));
			cy = y+objRadius.tr+(Math.sin(angle+(theta/2))*objRadius.tr/Math.cos(theta/2));
			px = x+w-objRadius.tr+(Math.cos(angle+theta)*objRadius.tr);
			py = y+objRadius.tr+(Math.sin(angle+theta)*objRadius.tr);
			//Right side line
			mc.lineStyle(objThickness.r, objColor.r, objAlpha.r, true, "none", "round", "round", 1);
			mc.curveTo(cx, cy, px, py);
			//Line
			mc.lineTo(x+w, y+h-objRadius.br);
			//Corners
			angle += theta;
			cx = x+w-objRadius.br+(Math.cos(angle+(theta/2))*objRadius.br/Math.cos(theta/2));
			cy = y+h-objRadius.br+(Math.sin(angle+(theta/2))*objRadius.br/Math.cos(theta/2));
			px = x+w-objRadius.br+(Math.cos(angle+theta)*objRadius.br);
			py = y+h-objRadius.br+(Math.sin(angle+theta)*objRadius.br);
			mc.curveTo(cx, cy, px, py);
			angle += theta;
			cx = x+w-objRadius.br+(Math.cos(angle+(theta/2))*objRadius.br/Math.cos(theta/2));
			cy = y+h-objRadius.br+(Math.sin(angle+(theta/2))*objRadius.br/Math.cos(theta/2));
			px = x+w-objRadius.br+(Math.cos(angle+theta)*objRadius.br);
			py = y+h-objRadius.br+(Math.sin(angle+theta)*objRadius.br);
			//Bottom line
			mc.lineStyle(objThickness.b, objColor.b, objAlpha.b, true, "none", "round", "round", 1);
			mc.curveTo(cx, cy, px, py);
			//Line
			mc.lineTo(x+objRadius.bl, y+h);
			angle += theta;
			//Corners
			cx = x+objRadius.bl+(Math.cos(angle+(theta/2))*objRadius.bl/Math.cos(theta/2));
			cy = y+h-objRadius.bl+(Math.sin(angle+(theta/2))*objRadius.bl/Math.cos(theta/2));
			px = x+objRadius.bl+(Math.cos(angle+theta)*objRadius.bl);
			py = y+h-objRadius.bl+(Math.sin(angle+theta)*objRadius.bl);
			mc.curveTo(cx, cy, px, py);
			angle += theta;
			cx = x+objRadius.bl+(Math.cos(angle+(theta/2))*objRadius.bl/Math.cos(theta/2));
			cy = y+h-objRadius.bl+(Math.sin(angle+(theta/2))*objRadius.bl/Math.cos(theta/2));
			px = x+objRadius.bl+(Math.cos(angle+theta)*objRadius.bl);
			py = y+h-objRadius.bl+(Math.sin(angle+theta)*objRadius.bl);
			//Left Line
			mc.lineStyle(objThickness.l, objColor.l, objAlpha.l, true, "none", "round", "round", 1);
			mc.curveTo(cx, cy, px, py);
			//Line
			mc.lineTo(x, y+objRadius.tl);
			//Corners
			angle += theta;
			cx = x+objRadius.tl+(Math.cos(angle+(theta/2))*objRadius.tl/Math.cos(theta/2));
			cy = y+objRadius.tl+(Math.sin(angle+(theta/2))*objRadius.tl/Math.cos(theta/2));
			px = x+objRadius.tl+(Math.cos(angle+theta)*objRadius.tl);
			py = y+objRadius.tl+(Math.sin(angle+theta)*objRadius.tl);
			mc.curveTo(cx, cy, px, py);
			angle += theta;
			cx = x+objRadius.tl+(Math.cos(angle+(theta/2))*objRadius.tl/Math.cos(theta/2));
			cy = y+objRadius.tl+(Math.sin(angle+(theta/2))*objRadius.tl/Math.cos(theta/2));
			px = x+objRadius.tl+(Math.cos(angle+theta)*objRadius.tl);
			py = y+objRadius.tl+(Math.sin(angle+theta)*objRadius.tl);
			//Top left corner
			mc.lineStyle(objThickness.t, objColor.t, objAlpha.t, true, "none", "round", "miter", 1);
			mc.curveTo(cx, cy, px, py);
		} else {
			//No corner radius defined - so draw a simple rectangle
			//Here, we assume that the user has specified the line style before calling
			//this method, as it's a simple rectangle.
			mc.moveTo(x, y);
			mc.lineTo(x+w, y);
			mc.lineTo(x+w, y+h);
			mc.lineTo(x, y+h);
			mc.lineTo(x, y);
		}
	}
	/**
	 * drawCircle method draws a circle in the specified movie clip.
	 * It draws the circle by dividing the sweep angle into segments of
	 * 45 degrees.
	 *	Assumptions: Movie clip is already created and line/fill style has
	 *				 already been set before this method is called to
	 *				 draw a rounded rectangle.
	 *	@param		mc			Movie clip in which we've to draw the circle
	 *	@param		x			Center X position of the circle
	 *	@param		y			Center Y position of the circle
	 *	@param		xRadius		x radius of the circle (pixels)
	 *	@param		yRadius		y radius of the circle (pixels)
	 *	@param		startAngle	Starting angle of the circle (degrees).
	 *	@param		arc			Sweep angle of the circle (degrees).
	*/
	public static function drawCircle(mc:MovieClip, x:Number, y:Number, xRadius:Number, yRadius:Number, startAngle:Number, arc:Number):Void {
		// Variables
		var sweepAngle:Number;
		//Theta value
		var theta:Number;
		var angle:Number;
		var angleMid:Number;
		//Number of segments that we've to plot.
		var segs:Number;
		//Axis positions
		var ax:Number, ay:Number, bx:Number, by:Number;
		//Control Points
		var controlX:Number, controlY:Number;
		//Divide in 8 segments 
		segs = Math.ceil(Math.abs(arc)/45);
		// Now calculate the sweep angle of each segment.
		sweepAngle = arc/segs;
		theta = -(sweepAngle/180)*Math.PI;
		// convert angle startAngle to radians
		angle = (startAngle/180)*Math.PI;
		// Draw the curve in segments no larger than 45 degrees.
		if (segs>0) {
			//We need to move to the start of the curve
			ax = x+Math.cos(startAngle/180*Math.PI)*xRadius;
			ay = y+Math.sin(-startAngle/180*Math.PI)*yRadius;
			mc.moveTo(ax, ay);
			//Loop for drawing curve segments
			for (var i:Number = 1; i<=segs; i++) {
				//Plot next segment
				angleMid = angle-(theta/2);
				angle -= theta;
				//End points of this segment
				bx = x+(xRadius*Math.cos(angle));
				by = y+(yRadius*Math.sin(-angle));
				//Control Points
				controlX = x+Math.cos(angleMid)*(xRadius/Math.cos(theta/2));
				controlY = y+Math.sin(-angleMid)*(yRadius/Math.cos(theta/2));
				//Plot the curve
				mc.curveTo(controlX, controlY, bx, by);
			}
		}
	}
}
