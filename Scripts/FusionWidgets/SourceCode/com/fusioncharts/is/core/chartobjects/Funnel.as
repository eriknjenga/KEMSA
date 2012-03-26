// Import the Delegate class
import mx.utils.Delegate;
// Import the Point class
import flash.geom.Point;
// Import the Matrix class
import flash.geom.Matrix;
// Import the Rectangle class
import flash.geom.Rectangle;
// Import the BitmapData class
import flash.display.BitmapData;
// Import the MathExt class
import com.fusioncharts.is.extensions.MathExt;
// Import the ColorExt class
import com.fusioncharts.is.extensions.ColorExt;
// Import the FunnelChart class (hack to fix a flash issue)
import com.fusioncharts.is.core.charts.FunnelChart;
/**
 * @class 		Funnel
 * @version		3.0
 * @author		InfoSoft Global (P) Ltd.
 *
 * Copyright (C) InfoSoft Global Pvt. Ltd.
 
 * Funnel class is responsible for creating a funnel.
 * The funnel is drawn on its instantiation by passing
 * parameters. Each instance is passed a (common) object
 * with a host of properties in them, the movieclip 
 * reference in which to draw the funnel.
 */
class com.fusioncharts.is.core.chartobjects.Funnel {
	// stores the reference of the basic Funnel chart class
	private var chartClass;
	// stores the object, with a host of properties, passed as parameter during instantiation of this class
	private var objData:Object;
	// stores the reference of the movieclip constituting the whole funnel
	private var mcObject:MovieClip;
	// strores the reference of MathExt.toNearestTwip()
	private var toNT:Function;
	//private var bmpBase:BitmapData;
	private var arrBmpsRef:Array;
	//
	/**
	 * Constructor function for the class. Calls the primary 
	 * drawFunnel method.
	 * @param	chartClassRef	Name of class instance instantiating this.
	 * @param	mcFunnel		A movie clip reference passed from the
	 *							main movie. This movie clip is the clip
	 *							inside which we'll draw the funnel.
	 *							Has to be necessarily provided.
	 * @param	obj				Object with various properties necessary
	 *							for drawing funnels. 
	 */
	public function Funnel(chartClassRef, mcFunnel:MovieClip, obj:Object) {
		// stores the referene of the basic class for creating a funnel chart 
		chartClass = chartClassRef;
		// stores the reference of the movieclip inside which rendering 
		// for this funnel, need to be done.
		mcObject = mcFunnel;
		// stores the object, with a host of properties
		objData = obj;
		// storing the refernce of MathExt.toNearestTwip() 
		toNT = MathExt.toNearestTwip;
		// a central repository created only once to store all bitmaps of the chart created initially and 
		// to be used thereafter, an optimization issue
		if (!objData.isInitialised) {
			this.chartClass.arrBmps[objData.id] = new Array();
		}
		// reference of the sub-repository holding bitmaps for this funnel only                                                                                
		arrBmpsRef = this.chartClass.arrBmps[objData.id];
		// drawing of the funnel is initialised
		this.drawFunnel();
		// rendering of labels initialised
		this.placeLabel();
	}
	/**
	 * drawFunnel is the prime method to control the entire
	 * work flow of rendering a specific funnel along with
	 * all its visual features.
	 */
	private function drawFunnel():Void {
		// local variables created
		var isOuter:Boolean, posId:Number, heightBmp:Number, upperWidthBmp:Number, lowerWidthBmp:Number, loops:Number, startAng:Number, remainderAng:Number;
		// squeezing factor of the ellipses, perspective issue
		var squeeze:Number = objData.squeeze;
		// center co-ordinates of the upper ellipse of this funnel
		var centerX:Number = objData.x;
		var centerY:Number = objData.y;
		// lengths of the axes of the upper ellipse of this funnel
		var a1:Number = objData.r1;
		var b1:Number = a1*squeeze;
		// lengths of the axes of the lower ellipse of this funnel
		var a2:Number = objData.r2;
		var b2:Number = a2*squeeze;
		// height of this funnel
		var h:Number = objData.h;
		// opacity of funnel border determined
		var borderAlpha:Number = (objData.is2D) ? objData.borderAlpha : 0;
		//--------------------------------------------//
		// center co-ordinates to begin with and to be manipulated as per requirement
		var xcenter:Number = centerX;
		var ycenter:Number = centerY;
		// heights of the centers of the ellipses from registration point
		// upper
		var h1 = ycenter;
		// lower
		var h2 = ycenter+h;
		// getting the points of tangency for common tangents to the ellipses (those pertinent for the chart only)
		var objPoints:Object = this.calcPoints(a1, b1, h1, a2, b2, h2);
		// getting the eccentric angles respective to the points obtained above
		// upper ellipse
		var topRightAng:Number = MathExt.roundUp(this.calcAngle(objPoints.topRight, centerX, centerY, h, a1, b1), 2);
		var topLeftAng:Number = MathExt.roundUp(this.calcAngle(objPoints.topLeft, centerX, centerY, h, a1, b1), 2);
		// lower ellipse
		var bottomRightAng:Number = MathExt.roundUp(this.calcAngle(objPoints.bottomRight, centerX, centerY+h, h, a2, b2), 2);
		var bottomLeftAng:Number = MathExt.roundUp(this.calcAngle(objPoints.bottomLeft, centerX, centerY+h, h, a2, b2), 2);
		//----------------------------//
		// taking the reflex angle due to an internal change in direction of y axis
		topRightAng = 360-topRightAng;
		topLeftAng = 360-topLeftAng;
		bottomRightAng = 360-bottomRightAng;
		bottomLeftAng = 360-bottomLeftAng;
		//----------------------------//		
		// all 4 angles stored together for validity checking
		var arrAngs:Array = [topRightAng, bottomRightAng, topLeftAng, bottomLeftAng];
		// function for angle validation         
		var checkAngs:Function = function ():Boolean {
			for (var i = 0; i<4; ++i) {
				if (arrAngs[i] == 90 || arrAngs[i] == 270 || isNaN(arrAngs[i]) || h == 0) {
					return true;
				}
			}
			return false;
		};
		// angles reassigned if found invalid
		if (checkAngs()) {
			topRightAng = 0;
			bottomRightAng = 0;
			topLeftAng = 180;
			bottomLeftAng = 180;
		}
		// for inappropriate other cases:  
		if (bottomLeftAng<180) {
			// like 178.5
			bottomLeftAng = 180;
		}
		if (topLeftAng<180) {
			// like 178.5
			topLeftAng = 180;
		}
		if (bottomRightAng<90) {
			// like 2.5
			bottomRightAng = 0;
		}
		if (topRightAng<90) {
			// like 2.5
			topRightAng = 0;
		}
		//-----------------------------------------//  
		// recording in funnel MC if the funnel is currently sliced                                               
		mcObject.isSliced = objData.isSliced;
		// storing reference of funnel id in funnel MC
		mcObject.id = objData.id;
		//-----------------------------------------//
		// parameters set for creating bitmaps
		heightBmp = h+b2;
		// safely enhanced to encounter bmp unfill issue in the right side of funnel, since common tangents
		// are used to draw the sides of the funnel (upper and lower diametrical ends of ellipses aren't joined) and
		// point of tangencies vary in abscisae to reflect different bmp widths, while bmps to be created initially only.
		// N.B: Bmps are basically trapezium; scaling horizontally may not match both widths together.
		upperWidthBmp = 2*a1*1.15;
		lowerWidthBmp = 2*a2;
		//-------------------------------- drawing top border ----------------------------------------//
		if (!objData.is2D) {
			// MC to draw the top border        
			var mcTopBorder:MovieClip = mcObject.createEmptyMovieClip('mcTopBorder', mcObject.getNextHighestDepth());
			//
			// starting angle of the curve in radians
			startAng = 0;
			// top right angle to be used for drawing top border only
			var _topRightAng:Number = (topRightAng == 0) ? 360 : topRightAng;
			// number of 45 degree curves to be drawn in succession
			loops = Math.floor((360-_topRightAng)/45);
			// remaining angle to be drawn thereafter, in degrees
			remainderAng = (360-_topRightAng)%45;
			// for funnel with zero height
			if (h == 0) {
				loops = (!objData.isHollow) ? 4 : 8;
			}
			// call to draw this part of the curve                     
			this.drawCurvedBorder(mcTopBorder, a1, b1, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, true, -1, null);
			// no need to draw any more if the funnel is a completely thin one; previous call completes the draw in that case 
			// loops != 8 ---> for the case of topRightAng = 0
			if (h != 0 && loops != 8) {
				startAng = MathExt.toRadians(_topRightAng);
				loops = Math.floor((_topRightAng-topLeftAng)/45);
				remainderAng = (_topRightAng-topLeftAng)%45;
				this.drawCurvedBorder(mcTopBorder, a1, b1, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, false, -1, null);
				//
				startAng = MathExt.toRadians(topLeftAng);
				loops = Math.floor((topLeftAng-180)/45);
				remainderAng = (topLeftAng-180)%45;
				this.drawCurvedBorder(mcTopBorder, a1, b1, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, false, -1, null);
				// need to draw more if the funnel is a hollow one
				if (objData.isHollow) {
					startAng = Math.PI;
					loops = 4;
					remainderAng = 0;
					this.drawCurvedBorder(mcTopBorder, a1, b1, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, false, -1, null);
				}
			}
		}
		//-------------------------------- drawing back base ---------------------------------------//                                            
		// MC to draw the back portion of the funnel, actually renders the inner (back) face.
		var mcCanvas:MovieClip = mcObject.createEmptyMovieClip('mcCanvasBack', mcObject.getNextHighestDepth());
		// ------------------ //
		// if not explicitly 2D mode, create bitmap
		if (!objData.is2D) {
			var matrix:Matrix = new Matrix();
			// process to create bitmap for inner (back) face of funnel
			isOuter = false;
			// indexing position of referencing/getting the bitmap stored in central repository 
			posId = (isOuter) ? 0 : 1;
			// bitmap to be created only initially and stored thereafter in central repository 
			if (!objData.isInitialised) {
				// bitmap creation initiated (in 2 steps)
				this.rowMap(mcObject, upperWidthBmp, lowerWidthBmp, heightBmp, objData.color, isOuter);
			}
			// configuring matrix for manipulating the original bitmap for filling in MC                                                                         
			matrix.scale(1, heightBmp/arrBmpsRef[posId].height);
			matrix.translate(centerX-upperWidthBmp/2, centerY);
			// else, its explicitly 2D mode, simply apply a fill color
		} else {
			mcCanvas.beginFill(objData.color, 100);
		}
		//------------------//
		// if funnel is hollow and not explicitly 2D
		if (objData.isHollow && !objData.is2D) {
			// apply bitmap in MC for fill
			mcCanvas.beginBitmapFill(arrBmpsRef[posId], matrix, false, true);
			// else for solid funnel 
		} else {
			// ----------- face fill gradient ------------ // 
			var strFillType:String = 'radial';
			//calculating squeeze dependent ratio for shadow as well as highlight color
			var shadowRatio:Number = 0.75;
			var highlightRatio:Number = 0.8;
			var shadowColor:Number = ColorExt.getDarkColor(objData['color'].toString(16), shadowRatio);
			var highlightColor:Number = ColorExt.getLightColor(objData['color'].toString(16), highlightRatio);
			var arrColors:Array = [highlightColor, shadowColor];
			var arrAlphas:Array = [objData.fillAlpha, objData.fillAlpha];
			var arrRatios:Array = [0, 255];
			var xGrad:Number = centerX-a1-0.1*a1;
			var yGrad:Number = centerY-b1;
			var widthGrad:Number = 2*a1;
			var heightGrad:Number = 4*b1;
			var objMatrix:Object = {matrixType:"box", x:xGrad, y:yGrad, w:widthGrad, h:heightGrad, r:Math.PI};
			mcCanvas.beginGradientFill(strFillType, arrColors, arrAlphas, arrRatios, objMatrix);
		}
		// -------------------- //
		// start drawing curves
		startAng = 0;
		loops = Math.floor(topLeftAng/45);
		remainderAng = topLeftAng%45;
		this.drawCurvedBorder(mcCanvas, a1, b1, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, true, 1, borderAlpha);
		//----------------------//
		// this angle need to be 360 instead of zero for following calculations
		if (bottomRightAng == 0) {
			bottomRightAng = 360;
		}
		startAng = MathExt.toRadians(bottomLeftAng);
		if (!objData.isHollow) {
			loops = Math.floor((bottomRightAng-bottomLeftAng)/45);
			remainderAng = (bottomRightAng-bottomLeftAng)%45;
		} else {
			loops = Math.floor((360-(bottomRightAng-bottomLeftAng))/45);
			remainderAng = (360-(bottomRightAng-bottomLeftAng))%45;
		}
		//
		ycenter += h;
		// direction for running curve 
		// clockwise = 1 and anti-clockwise = -1
		var dir:Number = (objData.isHollow) ? -1 : 1;
		this.drawCurvedBorder(mcCanvas, a2, b2, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, false, dir, borderAlpha);
		//----------------------//
		ycenter -= h;
		startAng = MathExt.toRadians(topRightAng);
		loops = 0;
		dir = 1;
		remainderAng = 360-topRightAng;
		this.drawCurvedBorder(mcCanvas, a1, b1, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, false, dir, borderAlpha);
		mcCanvas.endFill();
		//--------------------------------- drawing mask of mcCanvasBack ----------------------------------//
		var mcMask:MovieClip = mcObject.createEmptyMovieClip('mcBackMask', mcObject.getNextHighestDepth());
		mcMask.beginFill(0x000000, 100);
		startAng = 0;
		loops = 8;
		remainderAng = 0;
		this.drawCurvedBorder(mcMask, a1, b1, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, true, -1, borderAlpha);
		mcMask.endFill();
		// mcMask is used to mask inner back MC (mcCanvasBack)
		mcCanvas.setMask(mcMask);
		//-------------------------------- drawing front mc --------------------------------------------// 
		// no more drawing required if the funnel is a completely thin one
		if (h != 0) {
			var mcCanvas:MovieClip = mcObject.createEmptyMovieClip('mcCanvasFront', mcObject.getNextHighestDepth());
			var xcenter:Number = centerX;
			var ycenter:Number = centerY;
			// ------------------------------------------------------------ //
			// if not explicitly 2D mode, create bitmap
			if (!objData.is2D) {
				var matrix:Matrix = new Matrix();
				// process to create bitmap for outer (front) face of funnel
				isOuter = true;
				// indexing position of referencing/getting the bitmap stored in central repository 
				posId = (isOuter) ? 0 : 1;
				// bitmap to be created only initially and stored thereafter in central repository 
				if (!objData.isInitialised) {
					// bitmap creation initiated (in 2 steps)
					this.rowMap(mcObject, upperWidthBmp, lowerWidthBmp, heightBmp, objData.color, isOuter);
				}
				// configuring matrix for manipulating the original bitmap for filling in MC                                                                   
				matrix.scale(1, heightBmp/arrBmpsRef[posId].height);
				matrix.translate(centerX-upperWidthBmp/2, centerY);
				mcCanvas.beginBitmapFill(arrBmpsRef[posId], matrix, false, true);
				// else, its explicitly 2D mode, simply apply a fill color
			} else {
				mcCanvas.beginFill(objData.color, 100);
			}
			// ------------------------------------------------------------ // 
			if (topRightAng == 0) {
				topRightAng = 360;
			}
			// drawing begins                       
			startAng = MathExt.toRadians(topRightAng);
			loops = Math.floor((topRightAng-topLeftAng)/45);
			remainderAng = (topRightAng-topLeftAng)%45;
			this.drawCurvedBorder(mcCanvas, a1, b1, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, true, -1, borderAlpha);
			//----------------------//
			startAng = MathExt.toRadians(bottomLeftAng);
			loops = Math.floor((bottomRightAng-bottomLeftAng)/45);
			remainderAng = (bottomRightAng-bottomLeftAng)%45;
			ycenter += h;
			this.drawCurvedBorder(mcCanvas, a2, b2, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, false, 1, borderAlpha);
			//----------------------//
			ycenter -= h;
			startAng = MathExt.toRadians(topRightAng);
			loops = 0;
			remainderAng = 0;
			this.drawCurvedBorder(mcCanvas, a1, b1, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, false, 1, borderAlpha);
			mcCanvas.endFill();
			//------------------------------- drawing CanvasBackBorder mc --------------------------------//  
			// this is required to have the lower back border of funnel to be barely  visible due low opacity of funnel
			var mcCanvas:MovieClip = mcObject.createEmptyMovieClip('mcCanvasBackBorder', mcObject.getNextHighestDepth());
			startAng = MathExt.toRadians(bottomRightAng);
			loops = Math.floor((360-bottomRightAng+bottomLeftAng)/45);
			remainderAng = (360-bottomRightAng+bottomLeftAng)%45;
			ycenter = centerY+h;
			//curve drawn without any fill
			this.drawCurvedBorder(mcCanvas, a2, b2, startAng, loops, MathExt.toRadians(remainderAng), xcenter, ycenter, true, 1, objData.fillAlpha);
			// putting mcCanvasBackBorder below mcCanvasFront
			mcObject.mcCanvasFront.swapDepths(mcObject.mcCanvasBackBorder);
			//  measures to have proper display of thin hollow funnels when the next lower one is visible due its hollowness
			var mcFrontMask:MovieClip = mcObject.mcCanvasFront.duplicateMovieClip('mcFrontMask', mcObject.getNextHighestDepth());
			mcCanvas.setMask(mcFrontMask);
			//-----------------------------------------------// 
		}
		if (!objData.is2D) {
			// lifting top border to the topmost level                                                    
			mcTopBorder.swapDepths(mcObject.getNextHighestDepth());
		}
	}
	/**
	 * calcAngle is the method to calculate and return the 
	 * eccentric angle of an ellipse corresponding to a
	 * given point on it.
	 * @param	p			point instance holding coordinates of the 
	 * 						point on the ellipse.
	 * @param	xCenter		abscissa of funnel top center
	 * @param	yCenter		ordinate of funnel top center
	 * @param	h			height between top and bottom centers
	 * @param	a			semi-major axis length of the ellipse
	 * @param	b			semi-minor axis length of the ellipse
	 * @returns 			eccentric angle corresponding to the given
	 *						point on the given ellipse.
	 */
	private function calcAngle(p:Point, xCenter:Number, yCenter:Number, h:Number, a:Number, b:Number):Number {
		p.x += xCenter;
		var dx = p.x-xCenter;
		var dy = p.y-yCenter;
		// angle formed between the mouse cursor and chart center
		var ellipticAngle:Number = Math.atan2(dy, dx);
		// adjustment for Math.atan2 which returns angle between  -90 to 90 degreees (obviously in radians) only
		var addAngle:Number = (dx<0) ? Math.PI : 0;
		// formula applied
		var eccentricAngle:Number = MathExt.boundAngle(MathExt.toDegrees(Math.atan((a/b)*Math.tan(ellipticAngle))+addAngle));
		if (isNaN(eccentricAngle) && objData.id == 0) {
			eccentricAngle = 0;
		}
		// returning angle required in degrees                          
		return eccentricAngle;
	}
	/**
	 * calcPoints method calculates and returns the 
	 * coordinates of four points of common tangency
	 * between the upper and lower ellipses.
	 * @param	a1			semi-major axis length of the upper ellipse
	 * @param	b1			semi-minor axis length of the upper ellipse
	 * @param	h1			height of upper ellipse center
	 * @param	a2			semi-major axis length of the lower ellipse
	 * @param	b2			semi-minor axis length of the lower ellipse
	 * @param	h2			height of lower ellipse center
	 * @returns				object holding point instances corresponding
	 * 						to the 4 points of tangencies.
	 */
	private function calcPoints(a1, b1, h1, a2, b2, h2):Object {
		// calcuating parameters of formula                
		var alpha = Math.pow(a2, 2)-Math.pow(a1, 2);
		var beta = -2*(Math.pow(a2, 2)*h1-Math.pow(a1, 2)*h2);
		var gamma = Math.pow(a1*b2, 2)+Math.pow(a2*h1, 2)-Math.pow(a2*b1, 2)-Math.pow(a1*h2, 2);
		var k = Math.sqrt(Math.pow(beta, 2)-4*alpha*gamma);
		// getting the 2 y-intercepts for there are 2 pairs of tangents               
		var c1 = (-beta+k)/(2*alpha);
		var c2 = (-beta-k)/(2*alpha);
		// but we need only one pair and hence one value of y-intercept              
		if (c1<h2 && c1>h1) {
			var c = c2;
		} else if (c2<h2 && c2>h1) {
			var c = c1;
		}
		// getting the slopes of the 2 tangents of the selected pair                                                                                                                                                                                    
		var m1 = Math.sqrt((Math.pow(c-h1, 2)-Math.pow(b1, 2))/Math.pow(a1, 2));
		var m2 = -m1;
		// getting the 4 points of tangency
		// right sided points
		//upper
		var p1 = new Point(MathExt.roundUp(Math.pow(a1, 2)*m1/(c-h1), 2), MathExt.roundUp((Math.pow(b1, 2)/(c-h1))+h1, 2));
		//lower
		var p2 = new Point(MathExt.roundUp(Math.pow(a2, 2)*m1/(c-h2), 2), MathExt.roundUp((Math.pow(b2, 2)/(c-h2))+h2, 2));
		// left sided points
		//upper
		var p3 = new Point(MathExt.roundUp(Math.pow(a1, 2)*m2/(c-h1), 2), MathExt.roundUp((Math.pow(b1, 2)/(c-h1))+h1, 2));
		//lower
		var p4 = new Point(MathExt.roundUp(Math.pow(a2, 2)*m2/(c-h2), 2), MathExt.roundUp((Math.pow(b2, 2)/(c-h2))+h2, 2));
		// storing in object to be passed as a collection
		var objPoints:Object = {topLeft:p3, bottomLeft:p4, topRight:p1, bottomRight:p2};
		// checking for invalid situations 
		for (var i in objPoints) {
			if (isNaN(objPoints[i].x) || isNaN(objPoints[i].y)) {
				// means ... the funnel is extremely thin and points of tangencies coincide with ellipse ends
				if (i == 'topLeft' || i == 'bottomLeft') {
					objPoints[i].x = -a1;
				} else {
					objPoints[i].x = a1;
				}
				objPoints[i].y = h1;
			}
		}
		// object returned            
		return objPoints;
	}
	/**
	 * drawCurvedBorder method draws the boundary of a funnel
	 * in steps as per calling instruction.
	 * @param	mcCanvas		Reference of movieclip to draw in
	 * @param	a				semi-major axis length of the ellipse
	 * @param	b				semi-minor axis length of the ellipse
	 * @param	startAng		Starting angle of curve	
	 * @param	steps			Number of iterations of 45 degrees curve
	 *							drawing.
	 * @param	remainder		Angle for curve drawing after 45 degree
	 *							drawing iterations are over
	 * @param	xCenter			abscissa of ellipse center
	 * @param	yCenter			ordinate of ellipse center
	 * @param	init			Boolean value to indicate whether to
	 *							start up the drawing process or is it in continuation
	 * @param	directionSign	direction to draw the ellipse,
	 *							clockwise or anti-clockwise 
	 * @param	borderAlpha		Numeric value of opacity for borders
	 */
	private function drawCurvedBorder(mcCanvas:MovieClip, a:Number, b:Number, startAng:Number, steps:Number, remainder:Number, xcenter:Number, ycenter:Number, init:Boolean, directionSign:Number, borderAlpha:Number):Void {
		directionSign *= -1;
		startAng = Math.PI*2-startAng;
		//------------------//
		// lengths of semi-axes
		var sa:Number = a;
		var sb:Number = b;
		// default line thickness
		var thickness:Number = objData.lineThickness;
		var xcontrol:Number, ycontrol:Number, xend:Number, yend:Number;
		// if in 2D mode
		if (borderAlpha != undefined) {
			// reassessing line thickness
			if (borderAlpha == 0) {
				// to avoid invisible hotspot area on pheriphery
				thickness = 0;
			}
			mcCanvas.lineStyle(thickness, objData.borderColor, borderAlpha);
			//else if in 3D mode
		} else {
			//  when animates to full 2D display
			if (objData.squeeze == 0) {
				thickness = 0;
				// else if funnel is hollow
			} else if (objData.isHollow) {
				thickness = 1;
				// else if funnel is solid
			} else {
				thickness = 2;
			}
			// in 3D mode, lines are always with color gradient
			// getting gradient colors of the line
			var gradEndColor:Number = ColorExt.getDarkColor((objData.color).toString(16), 0.5);
			var gradMidColor:Number = ColorExt.getLightColor((objData.color).toString(16), 0.4);
			// applying line thickness
			mcCanvas.lineStyle(thickness);
			// setting gradient properties
			if (objData.h == 0 && objData.isHollow) {
				var _arrColors:Array = [gradEndColor, gradEndColor, gradMidColor, gradEndColor, gradEndColor];
				var _arrAlphas:Array = [100, 100, 100, 100, 100];
			} else {
				var _arrColors:Array = [gradEndColor, gradEndColor, 0xffffff, gradEndColor, gradEndColor];
				var _arrAlphas:Array = [100, 50, 45, 50, 100];
			}
			var _arrRatios:Array = [0, 30, 127, 225, 255];
			var _objMatrix:Object = {matrixType:"box", x:xcenter-sa, y:ycenter-sb, w:2*sa, h:2*sb, r:Math.PI*15/180};
			// applying line gradient
			mcCanvas.lineGradientStyle('linear', _arrColors, _arrAlphas, _arrRatios, _objMatrix);
			//-----------------//
			// modifying lengths of semi-axes, for not having them protruding outside funnel
			sa -= thickness/2;
			sb -= thickness/2;
		}
		// starting coordinates
		var xstart:Number = toNT(xcenter+sa*Math.cos(startAng));
		var ystart:Number = toNT(ycenter+sb*Math.sin(startAng));
		//--------------------------------------------------//
		// is the curve initiating or is it a continuation over previous draw 
		if (init) {
			mcCanvas.moveTo(xstart, ystart);
		} else {
			mcCanvas.lineTo(xstart, ystart);
		}
		// drawing 45 degree curves
		for (var j = 1; j<=steps; ++j) {
			var t:Number = startAng+directionSign*MathExt.toRadians(45)*j;
			xend = toNT(xcenter+sa*Math.cos(t));
			yend = toNT(ycenter+sb*Math.sin(t));
			xcontrol = toNT(xcenter+sa*Math.cos((2*(startAng+directionSign*MathExt.toRadians(45)*(j-1))+directionSign*MathExt.toRadians(45))/2)/Math.cos(MathExt.toRadians(45)/2));
			ycontrol = toNT(ycenter+sb*Math.sin((2*(startAng+directionSign*MathExt.toRadians(45)*(j-1))+directionSign*MathExt.toRadians(45))/2)/Math.cos(MathExt.toRadians(45)/2));
			mcCanvas.curveTo(xcontrol, ycontrol, xend, yend);
		}
		// remaining angle to be drawn now
		// evaluating angle corresponding to end point
		var s:Number = startAng+directionSign*MathExt.toRadians(45)*steps+directionSign*remainder;
		xend = toNT(xcenter+sa*Math.cos(s));
		yend = toNT(ycenter+sb*Math.sin(s));
		// evaluating angle corresponding to control point
		var ang:Number = startAng+directionSign*MathExt.toRadians(45)*steps+directionSign*remainder/2;
		xcontrol = toNT(xcenter+sa*Math.cos(ang)/Math.cos(remainder/2));
		ycontrol = toNT(ycenter+sb*Math.sin(ang)/Math.cos(remainder/2));
		mcCanvas.curveTo(xcontrol, ycontrol, xend, yend);
	}
	/**
	 * placeLabel method renders label for a funnel,
	 * either centrally or aside, as per instruction.
	 */
	private function placeLabel():Void {
		// object holding label parameters
		var objTextProp:Object = objData.objLabelProps;
		// label text matter
		var strLabel:String = objData.labelText;
		var depth:Number = mcObject.getNextHighestDepth();
		var xPos:Number = objData.xTxt;
		var yPos:Number = objData.yTxt;
		// creating text field
		var txtLabel:TextField = mcObject.createTextField('txtLabel', depth, xPos, yPos, null, null);
		txtLabel.autoSize = true;
		if (objTextProp.isHTML) {
			txtLabel.html = true;
			txtLabel.htmlText = strLabel;
		} else {
			txtLabel.text = strLabel;
		}
		// call to format text as per specified parameters
		this.formatText(objTextProp, txtLabel);
		// call to connect label with the funnel with lines if labels are not be placed at funnel center
		if (!objData.showLabelsAtCenter && strLabel != '' && objData.enableSmartLabels) {
			this.joinLabel();
		}
		//                                                 
		if (objTextProp.borderColor != '') {
			txtLabel.borderColor = parseInt(objTextProp.borderColor, 16);
			txtLabel.border = true;
		}
		if (objTextProp.bgColor != '') {
			txtLabel.backgroundColor = parseInt(objTextProp.bgColor, 16);
			txtLabel.background = true;
		}
		// rendering top label if applicable for this funnel (logic same as above)                                                     
		if (objData.topLabel != null && objData.topLabel != '') {
			var xPos:Number = objData.x;
			var yPos:Number = objData.y;
			var depthTopLabel:Number = mcObject.getNextHighestDepth();
			var txtTopLabel:TextField = mcObject.createTextField('txtTopLabel', depthTopLabel, xPos, yPos, null, null);
			txtTopLabel.autoSize = true;
			if (objTextProp.isHTML) {
				txtTopLabel.html = true;
				txtTopLabel.htmlText = objData.topLabel;
			} else {
				txtTopLabel.text = objData.topLabel;
			}
			if (objTextProp.borderColor != '') {
				txtTopLabel.borderColor = parseInt(objTextProp.borderColor, 16);
				txtTopLabel.border = true;
			}
			if (objTextProp.bgColor != '') {
				txtTopLabel.backgroundColor = parseInt(objTextProp.bgColor, 16);
				txtTopLabel.background = true;
			}
			this.formatText(objTextProp, txtTopLabel);
			// positioning the label centrally above the funnel
			if (objData.topLabelX != null) {
				// if specified
				txtTopLabel._x = objData.topLabelX;
			} else {
				// determine position
				txtTopLabel._x -= txtTopLabel._width/2;
			}
			txtTopLabel._y -= objData.squeeze*objData.r1+txtTopLabel._height+5;
		}
	}
	/**
	 * joinLabel method joins a label with its funnel by
	 * drawing lines.
	 */
	private function joinLabel():Void {
		var xIni:Number, yIni:Number, xEnd:Number, yEnd:Number;
		// getting starting and ending coordinates of the joining line
		xIni = Math.round(objData.x+objData.r2);
		//
		yIni = Math.round(objData.y+objData.h);
		xEnd = Math.round(objData.xTxt);
		//
		yEnd = Math.round(objData.yTxt+3*objData.txtHeight/4);
		// MC created to render this line in
		var mcLabelJoin:MovieClip = mcObject.createEmptyMovieClip('mcLabelJoin', -1);
		mcLabelJoin.lineStyle(objData.smartLineThickness, parseInt(objData.smartLineColor, 16), objData.smartLineAlpha);
		// line drawn
		mcLabelJoin.moveTo(xIni, yIni);
		mcLabelJoin.lineTo(xEnd, yEnd);
	}
	/**
	 * formatText method formats a textfield w.r.t setting
	 * passed to it.
	 * @param	objTextProp		object holding text formatting 
	 *							properties
	 * @param	txtLabel		reference of the textfield to be 
	 *							formatted
	 */
	private function formatText(objTextProp:Object, txtLabel:TextField):Void {
		// textformat object for text field formatting
		var fmtTxt:TextFormat = new TextFormat();
		// properties stored
		fmtTxt.font = objTextProp.font;
		fmtTxt.size = objTextProp.size;
		fmtTxt.color = parseInt(objTextProp.color, 16);
		fmtTxt.bold = objTextProp.bold;
		fmtTxt.italic = objTextProp.italic;
		fmtTxt.underline = objTextProp.underline;
		fmtTxt.letterSpacing = objTextProp.letterSpacing;
		fmtTxt.leftMargin = objTextProp.leftMargin;
		// text field formatted with the stored properties                                                                                             
		txtLabel.setTextFormat(fmtTxt);
		// filters applied on datalabels
		chartClass.styleM.applyFilters(txtLabel, chartClass.objects.DATALABELS);
	}
	/**
	 * rowMap method creates the required bitmap for filling
	 * the funnel to have the desired 3D effect.
	 * @param	mc				reference of the MC to draw in
	 * @param	upperWidth		width of upper end of bitmap to be 
	 *							created
	 * @param	lowerWidth		width of lower end of bitmap to be 
	 *							created
	 * @param	heightBmp		height of  bitmap to be created
	 * @param	color			bitmap background color
	 * @param	isOuter			is the bitmap to fill front side or 
	 *							back side of the funnel
	 */
	private function rowMap(mc:MovieClip, upperWidth:Number, lowerWidth:Number, heightBmp:Number, color:Number, isOuter:Boolean) {
		heightBmp = Math.ceil(heightBmp);
		// conversion from 100 based scale to 255 based scale
		var fillAlpha:Number = objData.fillAlpha*255/100;
		// color conversion from 24 bits to 32 bits, by incorporating opacity (ARGB)
		color = fillAlpha << 24 | color;
		// Bitmap created, but blank
		var bmpBase:BitmapData = new BitmapData(upperWidth, heightBmp, true, color);
		// the one pixel thick gradient created as MC; to be used in the following code to built total bitmap required
		var _mc:MovieClip = this.generateUnitMap(mc, upperWidth, isOuter);
		// matrix to manipulate
		var _matbase:Matrix = new Matrix();
		// MC to be shifted by along x direction
		var delX:Number = MathExt.roundUp((upperWidth-lowerWidth)/(2*heightBmp), 3);
		// MC to be scaled by along x direction
		var delScaleX:Number = (upperWidth-lowerWidth)/(upperWidth*heightBmp);
		// variables to set matrix parameters initiated
		var tx:Number = 0;
		var ty:Number;
		var sx:Number = 1;
		// loop runs to create the required bitmap
		for (var i:Number = 0; i<=heightBmp; ++i) {
			// if not initial loop run
			if (i != heightBmp) {
				// x set
				tx += delX;
				// scale in x direction set
				sx -= delScaleX;
			}
			// y set                                                   
			ty = i;
			// matrix reset to identity matrix
			_matbase.identity();
			// scale set
			_matbase.scale(MathExt.roundUp(sx, 3), 1);
			// translation set
			_matbase.translate(tx, ty);
			bmpBase.draw(_mc, _matbase, null, "normal", new Rectangle(0, ty, upperWidth, 2));
		}
		// getting index in array for store; the mode of the bitmap w.r.t. whether it will fill inner back face or outer front face of the funnel
		var posId:Number = (isOuter) ? 0 : 1;
		// storing the bitmap in central repository
		arrBmpsRef[posId] = bmpBase.clone();
		// clear memory
		bmpBase.dispose();
		_mc.removeMovieClip();
	}
	/**
	 * generateUnitMap method creates the unit height gradient
	 * MC to be manipulated and used by rowMap method in 
	 * creating the total bitmap for the funnel.
	 * @param	mc			MC to create the unit map in
	 * @param	gradWidth	width of the unit map
	 * @param	isOuter		is the bitmap to fill front side or 
	 *						back side of the funnel
	 * @returns				reference of MC of the unit map
	 */
	private function generateUnitMap(mc:MovieClip, gradWidth:Number, isOuter:Boolean):MovieClip {
		// MC created draw the unit content
		var _mc:MovieClip = mc.createEmptyMovieClip('mcUnitMap', mc.getNextHighestDepth());
		// parameters set for applying gradient
		var _objMatrix:Object = {matrixType:"box", x:0, y:0, w:gradWidth, h:1, r:0};
		var _arrAlphas:Array = [50, 0, 0, 70];
		for (var i = 0; i<_arrAlphas.length; ++i) {
			_arrAlphas[i] = Math.floor(objData.fillAlpha*_arrAlphas[i]/100);
		}
		// percentage offset, either left or right from centre of the funnel for highlight
		var _gradOffsetPercent:Number = 10;
		// setting centre of highlight
		if (isOuter) {
			var s:Number = 127-Math.round(_gradOffsetPercent*255/100);
			var d1:Number = 0;
			var d2:Number = 8;
		} else {
			var s:Number = 127+Math.round(_gradOffsetPercent*255/100);
			var d1:Number = -8;
			var d2:Number = 0;
			// reversed to get the required orientation of gradient
			_arrAlphas.reverse();
		}
		var _arrColors:Array = [0x0, 0x0, 0x0, 0x0];
		var _arrRatios:Array = [0, s+d1, s+d2, 255];
		_mc.beginGradientFill('linear', _arrColors, _arrAlphas, _arrRatios, _objMatrix);
		// one pixel thick line drawn
		_mc.moveTo(0, 0);
		_mc.lineTo(gradWidth, 0);
		_mc.lineTo(gradWidth, 1);
		_mc.lineTo(0, 1);
		_mc.lineTo(0, 0);
		_mc.endFill();
		// MC returned
		return _mc;
	}
}
