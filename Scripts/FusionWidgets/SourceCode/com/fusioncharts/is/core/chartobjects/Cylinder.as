import mx.transitions.Tween;
import flash.filters.BlurFilter;
import com.fusioncharts.is.extensions.ColorExt;
import flash.geom.*;
/**
 * @class Cylinder
 * @author InfoSoft Global (P) Ltd.
 * @version 3.0
 *
 * Copyright (C) InfoSoft Global Pvt. Ltd. 2006
 *
 * Cylinder class renders and controls a cylinder 
 * and its fill.
*/
class com.fusioncharts.is.core.chartobjects.Cylinder {
	// reference of main chart MC
	private var mcChart:MovieClip;
	// reference of MC within which Cylinder is rendered
	private var mcBase:MovieClip;
	// repository of cylinder properties
	private var config:Object;
	//----------------------  PUBLIC API  ---------------------------//
	/**
	 * Constructor of Cylinder class. Store passed parameters.
	 */
	public function Cylinder(mcCanvas:MovieClip, objProps:Object) {
		// reference of MC to hold the Cylinder passed over, is stored
		this.mcChart = mcCanvas;
		//--------------//
		// Steps taken to convert Flash coordinate sysytem to normal coordinate system.
		// MC created to draw the ultimate content in (just one more sub-level to achieve coodinate space conversion)
		this.mcBase = this.mcChart.createEmptyMovieClip('mcBase', 0);
		// coodinate space converted
		this.mcBase._yscale = -100;
		//--------------//
		// method called passing the objprop for setting up repository of cylinder properties.
		this.initProps(objProps);
	}
	/**
	 * setSystem method should be called after class 
	 * instantiation, to go for cylinder and its fill
	 * rendering and setting the stage to initial status.
	 */
	public function setSystem():Void {
		// glassware cylinder to be drawn now (in 2 halves)
		// MC for front face of glassware to be rendered in
		var mc1:MovieClip = this.mcBase.createEmptyMovieClip('mcFront', 3);
		// MC for back face of glassware to be rendered in
		var mc2:MovieClip = this.mcBase.createEmptyMovieClip('mcBack', 0);
		// method called to render glassware
		this.drawCylinder(mc1, mc2);
		//-----------------------------//
		// fluid in cylinder to be drawn now (in 2 halves)
		// MC for body of fluid to be rendered in
		var mc3:MovieClip = this.mcBase.createEmptyMovieClip('mcFluidBody', 1);
		// MC for top-face of fluid to be rendered in
		var mc4:MovieClip = this.mcBase.createEmptyMovieClip('mcFluidTop', 2);
		// method called to render fluid
		this.drawFluid(mc3, mc4);
		//-----------------------------//
		// method called to set initial visual status of the cylinder with fluid filled.
		this.setIni();
	}
	/**
	 * updateFluid method is called to reset fluid height
	 * in the cylinder.
	 * @param	newHeightPercent	new height of fluid in percentage
	 *								of total cylinder height.
	 */
	public function updateFluid(newHeightPercent:Number):Void {
		// ultimate new height for the class, in pixels
		var newHeight:Number = Math.round(this.config.hMin+this.config.hCylinder*newHeightPercent/100);
		// reference of this Cylinder class instance
		var insRef = this;
		// reference of MC for fluid body
		var mc1:MovieClip = this.fluidBody;
		// reference of MC for fluid top-face
		var mc2:MovieClip = this.fluidTop;
		// opacity (increase) transition of fluid, when older height was zero and new height is greater zero.
		if (mc1._alpha<100 && newHeightPercent>0) {
			if (this.config.animation) {
				// transition set for fluid body
				new Tween(mc1, "_alpha", mx.transitions.easing.Strong.easeIn, mc1._alpha, 100, this.config.alphaTransTime, true);
				// transition set for fluid top-face
				new Tween(mc2, "_alpha", mx.transitions.easing.Strong.easeIn, mc2._alpha, 100, this.config.alphaTransTime, true);
			} else {
				mc1._alpha = 100;
				mc2._alpha = 100;
			}
		}
		if (this.config.animation) {
			// height transition of fluid body, from old to new height
			var fluidBodyTween:Tween = new Tween(mc1, "_height", mx.transitions.easing.Strong.easeInOut, mc1._height, newHeight, this.config.heightTransTime, true);
			// position transition of fluid top-face, from old to new height    
			var fluidTopTween:Tween = new Tween(mc2, "_y", mx.transitions.easing.Strong.easeInOut, mc2._y, mc1._y+newHeight-this.config.bUpper, this.config.heightTransTime, true);
		} else {
			mc1._height = newHeight;
			mc2._y = mc1._y+newHeight-this.config.bUpper;
		}
		if (this.config.animation) {
			// opacity (decrease) transition of fluid, when changes to zero.
			fluidBodyTween.onMotionFinished = function() {
				// checking for zero height at transition end of fluid
				if (newHeight-insRef.config.hMin == 0) {
					// transition set for fluid body
					new Tween(mc1, "_alpha", mx.transitions.easing.Strong.easeOut, mc1._alpha, 10, insRef.config.alphaTransTime, true);
					// transition set for fluid top-face
					new Tween(mc2, "_alpha", mx.transitions.easing.Strong.easeOut, mc2._alpha, 0, insRef.config.alphaTransTime, true);
				}
			};
		} else {
			if (newHeight-insRef.config.hMin == 0) {
				mc1._alpha = 10;
				mc2._alpha = 0;
			}
		}
	}
	/**
	 * destroy method is called to destroy assets created
	 * by this class instance.
	 */
	public function destroy():Void {
		this.mcBase.removeMovieClip();
		delete this.config;
		delete this.mcBase;
		delete this.mcChart;
	}
	//---------------------------------------------------------------//
	/**
	 * initProps method is called to fill in property values
	 * of the cylinder with fill, in repository.
	 * @param	obj		encapsulated collection of properties
	 *					required for rendering and animation.
	 */
	private function initProps(obj:Object):Void {
		// repository created
		this.config = new Object();
		// cloning properties from passed object to repository
		for (var i in obj) {
			this.config[i] = obj[i];
		}
		// few other properties are evaluated and stored
		this.config.factor = 1;
		// semiminor axis length of lower ellipse
		this.config.bLower = this.config.squeeze*this.config.rCylinder;
		// semiminor axis length of upper ellipse
		this.config.bUpper = this.config.bLower/this.config.factor;
		// minimum height of the total cylindrical fluid body possible, vertically, 
		// on the plane of the monitor screen
		this.config.hMin = this.config.bLower+this.config.bUpper;
		//--------------//
		var pt:Point = new Point(this.config.OriginX, this.config.OriginY);
		// originX and originY are w.r.t parent of mcChart.
		// transformation done to get the equivalent point w.r.t. _root
		this.mcChart._parent.localToGlobal(pt);
		// transformation done to get the equivalent point, of the above obtained point, w.r.t. mcBase
		this.mcBase.globalToLocal(pt);
		//--------------//
		// cylinder center coordinates set
		this.config.centerX = pt.x+this.config.rCylinder;
		this.config.centerY = pt.y+this.config.hCylinder/2;
	}
	/**
	 * setIni method is called to set initial visual status
	 * of the cylinder with fluid, at zero level.
	 */
	private function setIni():Void {
		// reference of fluid body
		var mc1:MovieClip = this.fluidBody;
		// reference of fluid top-face
		var mc2:MovieClip = this.fluidTop;
		// 
		mc1._alpha = 10;
		mc2._alpha = 0;
		mc1._height = this.config.hMin;
		mc2._y -= this.config.hCylinder;
		//
		if (this.config.animation) {
			// put initial opacity of whole cylinder with fluid to zero
			this.mcBase._alpha = 0;
			// now, go for their fade-in (opacity transition)
			new Tween(this.mcBase, "_alpha", mx.transitions.easing.Strong.easeOut, this.mcBase._alpha, 100, this.config.alphaTransTime, true);
		}
	}
	/**
	 * fluidBody is the getter method of the
	 * reference of fluid body MC.
	 * @return	refernce of the MC asked for
	 */
	public function get fluidBody():MovieClip {
		return this.mcBase.mcFluidBody;
	}
	/**
	 * fluidTop is the getter method of the
	 * reference of fluid top-face MC.
	 * @return	refernce of the MC asked for
	 */
	public function get fluidTop():MovieClip {
		return this.mcBase.mcFluidTop;
	}
	//---------------------------------------------------------------//
	/**
	 * drawCylinder method renders the glassware cylinder.
	 * @param	mc1		MC reference of front face of cylinder
	 * @param	mc2		MC reference of back face of cylinder
	 */
	private function drawCylinder(mc1:MovieClip, mc2:MovieClip):Void {
		////////////////////////////  FRONT FACE OF GLASSWARE  ///////////////////////////////////
		var mc:MovieClip = mc1;
		mc._x = this.config.centerX;
		mc._y = this.config.centerY;
		//
		var xcenter:Number, ycenter:Number, directionSign:Number, startAng:Number;
		var xcontrol:Number, ycontrol:Number, xend:Number, yend:Number;
		//-----------------------//
		var mcBottom1:MovieClip = mc.createEmptyMovieClip('mcBottom1', mc.getNextHighestDepth());
		mcBottom1.lineStyle(0, 0x0, 30);
		mcBottom1.moveTo(-this.config.rCylinder, -this.config.hCylinder/2-5);
		//
		startAng = Math.PI;
		directionSign = 1;
		xcenter = 0;
		ycenter = -this.config.hCylinder/2-5;
		drawCurve(mcBottom1, startAng, directionSign, xcenter, ycenter, false);
		//
		var blurX:Number = 2;
		var blurY:Number = 2;
		var quality:Number = 2;
		var filter:BlurFilter = new BlurFilter(blurX, blurY, quality);
		var filterArray:Array = new Array();
		filterArray.push(filter);
		mcBottom1.filters = filterArray;
		//-----------------------//
		var mcBottom2:MovieClip = mc.createEmptyMovieClip('mcBottom2', mc.getNextHighestDepth());
		mcBottom2.lineStyle(2, 0xFFFFFF, 100);
		//
		var fluidColor:Number = this.config.fluidColor;
		//
		var fillType = "linear";
		var colors = [0xCCCCCC, fluidColor, fluidColor, 0xCCCCCC];
		var alphas = [50, 70, 70, 50];
		var ratios = [0, 125, 130, 255];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hMin/2, 0, -this.config.rCylinder, 0);
		mcBottom2.lineGradientStyle(fillType, colors, alphas, ratios, matrix);
		//
		mcBottom2.moveTo(-this.config.rCylinder, -this.config.hCylinder/2-2);
		//
		startAng = Math.PI;
		directionSign = 1;
		xcenter = 0;
		ycenter = -this.config.hCylinder/2-2;
		drawCurve(mcBottom2, startAng, directionSign, xcenter, ycenter, false);
		//
		var blurX:Number = 2;
		var blurY:Number = 2;
		var quality:Number = 2;
		var filter:BlurFilter = new BlurFilter(blurX, blurY, quality);
		var filterArray:Array = new Array();
		filterArray.push(filter);
		mcBottom2.filters = filterArray;
		//-----------------------//
		var mcBottomSparkle:MovieClip = mc.createEmptyMovieClip('mcBottomSparkle', mc.getNextHighestDepth());
		mcBottomSparkle.lineStyle(2);
		//
		var fillType = "linear";
		var colors = [0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF];
		var alphas = [0, 90, 90, 0];
		var ratios = [20, 30, 60, 70];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hCylinder+this.config.hMin, 0, -this.config.rCylinder, 0);
		mcBottomSparkle.lineGradientStyle(fillType, colors, alphas, ratios, matrix);
		//
		mcBottomSparkle.moveTo(-this.config.rCylinder, -this.config.hCylinder/2-1);
		//
		startAng = Math.PI;
		directionSign = 1;
		xcenter = 0;
		ycenter = -this.config.hCylinder/2-1;
		drawCurve(mcBottomSparkle, startAng, directionSign, xcenter, ycenter, true);
		//
		var blurX:Number = 2;
		var blurY:Number = 2;
		var quality:Number = 1;
		var filter:BlurFilter = new BlurFilter(blurX, blurY, quality);
		var filterArray:Array = new Array();
		filterArray.push(filter);
		mcBottomSparkle.filters = filterArray;
		//-----------------------//
		var mcTop1:MovieClip = mc.createEmptyMovieClip('mcTop1', mc.getNextHighestDepth());
		mcTop1.lineStyle(0, 0x0, 20);
		mcTop1.moveTo(this.config.rCylinder, this.config.hCylinder/2);
		//
		startAng = 0;
		directionSign = -1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2;
		drawCurve(mcTop1, startAng, directionSign, xcenter, ycenter, true);
		//
		var blurX:Number = 2;
		var blurY:Number = 2;
		var quality:Number = 2;
		var filter:BlurFilter = new BlurFilter(blurX, blurY, quality);
		var filterArray:Array = new Array();
		filterArray.push(filter);
		mcTop1.filters = filterArray;
		//-----------------------//
		var mcTop2:MovieClip = mc.createEmptyMovieClip('mcTop2', mc.getNextHighestDepth());
		mcTop2.lineStyle(0, 0xFFFFFF, 100);
		mcTop2.moveTo(this.config.rCylinder, this.config.hCylinder/2-2);
		//
		startAng = 0;
		directionSign = -1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2-2;
		drawCurve(mcTop2, startAng, directionSign, xcenter, ycenter, true);
		//
		var blurX:Number = 2;
		var blurY:Number = 2;
		var quality:Number = 2;
		var filter:BlurFilter = new BlurFilter(blurX, blurY, quality);
		var filterArray:Array = new Array();
		filterArray.push(filter);
		mcTop2.filters = filterArray;
		//-----------------------//
		var mcTopSparkle:MovieClip = mc.createEmptyMovieClip('mcTopSparkle', mc.getNextHighestDepth());
		mcTopSparkle.lineStyle(2);
		//
		var fillType = "linear";
		var colors = [0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF];
		var alphas = [0, 90, 90, 0];
		var ratios = [20, 30, 60, 70];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hCylinder+this.config.hMin, 0, -this.config.rCylinder, 0);
		mcTopSparkle.lineGradientStyle(fillType, colors, alphas, ratios, matrix);
		//
		mcTopSparkle.moveTo(this.config.rCylinder, this.config.hCylinder/2-2);
		//
		startAng = 0;
		directionSign = -1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2-2;
		drawCurve(mcTopSparkle, startAng, directionSign, xcenter, ycenter, true);
		//
		var blurX:Number = 2;
		var blurY:Number = 2;
		var quality:Number = 1;
		var filter:BlurFilter = new BlurFilter(blurX, blurY, quality);
		var filterArray:Array = new Array();
		filterArray.push(filter);
		mcTopSparkle.filters = filterArray;
		//-----------------------//
		var mcFullBase:MovieClip = mc.createEmptyMovieClip('mcFullBase', mc.getNextHighestDepth());
		mcFullBase._alpha = 40;
		mcFullBase.lineStyle(0, 0x0, 0);
		//
		var fillType = "linear";
		var colors = [0x0, 0xFFFFFF, 0xFFFFFF, 0x0];
		var alphas = [20, 50, 50, 20];
		var ratios = [0, 90, 100, 255];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hCylinder+this.config.hMin, 0, -this.config.rCylinder, 0);
		mcFullBase.beginGradientFill(fillType, colors, alphas, ratios, matrix);
		//
		mcFullBase.moveTo(-this.config.rCylinder, -this.config.hCylinder/2);
		//
		startAng = Math.PI;
		directionSign = 1;
		xcenter = 0;
		ycenter = -this.config.hCylinder/2;
		drawCurve(mcFullBase, startAng, directionSign, xcenter, ycenter, false);
		//
		mcFullBase.lineTo(this.config.rCylinder, this.config.hCylinder/2);
		//
		startAng = 0;
		directionSign = -1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2;
		drawCurve(mcFullBase, startAng, directionSign, xcenter, ycenter, true);
		//
		mcFullBase.lineTo(-this.config.rCylinder, -this.config.hCylinder/2);
		//------------------------//
		var mcRightIndirectLight:MovieClip = mc.createEmptyMovieClip('mcRightIndirectLight', mc.getNextHighestDepth());
		mcRightIndirectLight.blendMode = "screen";
		//mcRightIndirectLight._alpha = 50;
		mcRightIndirectLight.lineStyle(0, 0x0, 0);
		//
		var fillType = "linear";
		var colors = [0xFFFFFF, 0xFFFFFF, 0xFFFFFF];
		var alphas = [10, 50, 100];
		var ratios = [230, 252, 255];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hCylinder+this.config.hMin, 0, -this.config.rCylinder, 0);
		mcRightIndirectLight.beginGradientFill(fillType, colors, alphas, ratios, matrix);
		//
		mcRightIndirectLight.moveTo(-this.config.rCylinder, -this.config.hCylinder/2);
		//
		startAng = Math.PI;
		directionSign = 1;
		xcenter = 0;
		ycenter = -this.config.hCylinder/2;
		drawCurve(mcRightIndirectLight, startAng, directionSign, xcenter, ycenter, false);
		//
		mcRightIndirectLight.lineTo(this.config.rCylinder, this.config.hCylinder/2);
		//
		startAng = 0;
		directionSign = -1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2;
		drawCurve(mcRightIndirectLight, startAng, directionSign, xcenter, ycenter, true);
		//
		mcRightIndirectLight.lineTo(-this.config.rCylinder, -this.config.hCylinder/2);
		//------------------------//
		var mcLeftIndirectLight:MovieClip = mc.createEmptyMovieClip('mcLeftIndirectLight', mc.getNextHighestDepth());
		mcLeftIndirectLight.blendMode = "screen";
		mcLeftIndirectLight.lineStyle(0, 0x0, 0);
		//
		var fillType = "linear";
		var colors = [0xFFFFFF, 0xFFFFFF, 0xFFFFFF];
		var alphas = [100, 50, 10];
		var ratios = [0, 3, 20];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hCylinder+this.config.hMin, 0, -this.config.rCylinder, 0);
		mcLeftIndirectLight.beginGradientFill(fillType, colors, alphas, ratios, matrix);
		//
		mcLeftIndirectLight.moveTo(-this.config.rCylinder, -this.config.hCylinder/2);
		//
		startAng = Math.PI;
		directionSign = 1;
		xcenter = 0;
		ycenter = -this.config.hCylinder/2;
		drawCurve(mcLeftIndirectLight, startAng, directionSign, xcenter, ycenter, false);
		//
		mcLeftIndirectLight.lineTo(this.config.rCylinder, this.config.hCylinder/2);
		//
		startAng = 0;
		directionSign = -1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2;
		drawCurve(mcLeftIndirectLight, startAng, directionSign, xcenter, ycenter, true);
		//
		mcLeftIndirectLight.lineTo(-this.config.rCylinder, -this.config.hCylinder/2);
		//------------------------//
		var mcDirectLight:MovieClip = mc.createEmptyMovieClip('mcDirectLight', mc.getNextHighestDepth());
		mcDirectLight.blendMode = "screen";
		mcDirectLight._alpha = 20;
		mcDirectLight.lineStyle(0, 0x0, 0);
		//
		var fillType = "linear";
		var colors = [0xFFFFFF, 0xFFFFFF0, 0xFFFFFF, 0xFFFFFF];
		var alphas = [0, 100, 100, 0];
		var ratios = [29, 30, 60, 61];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hCylinder+this.config.hMin, 0, -this.config.rCylinder, 0);
		mcDirectLight.beginGradientFill(fillType, colors, alphas, ratios, matrix);
		//
		mcDirectLight.moveTo(-this.config.rCylinder, -this.config.hCylinder/2);
		//
		startAng = Math.PI;
		directionSign = 1;
		xcenter = 0;
		ycenter = -this.config.hCylinder/2;
		drawCurve(mcDirectLight, startAng, directionSign, xcenter, ycenter, false);
		//
		mcDirectLight.lineTo(this.config.rCylinder, this.config.hCylinder/2);
		//
		startAng = 0;
		directionSign = -1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2;
		drawCurve(mcDirectLight, startAng, directionSign, xcenter, ycenter, true);
		//
		mcDirectLight.lineTo(-this.config.rCylinder, -this.config.hCylinder/2);
		//----------------------------------------//
		var mcBorder:MovieClip = mc.createEmptyMovieClip('mcBorder', mc.getNextHighestDepth());
		mcBorder.lineStyle(2, 0x0, 1);
		mcBorder.moveTo(-this.config.rCylinder, -this.config.hCylinder/2);
		//
		startAng = Math.PI;
		directionSign = 1;
		xcenter = 0;
		ycenter = -this.config.hCylinder/2;
		drawCurve(mcBorder, startAng, directionSign, xcenter, ycenter, false);
		//
		mcBorder.lineStyle(0, 0x0, 5);
		mcBorder.lineTo(this.config.rCylinder, this.config.hCylinder/2);
		mcBorder.lineStyle(0, 0x0, 0);
		//
		startAng = 0;
		directionSign = -1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2;
		drawCurve(mcBorder, startAng, directionSign, xcenter, ycenter, true);
		//
		mcBorder.lineStyle(0, 0x0, 5);
		mcBorder.lineTo(-this.config.rCylinder, -this.config.hCylinder/2);
		//-------------------------------------//
		//////////////////////////////////////  BACK FACE OF GLASSWARE  /////////////////////////////////////////////
		mc = mc2;
		mc._x = this.config.centerX;
		mc._y = this.config.centerY;
		//
		var xcenter:Number, ycenter:Number, directionSign:Number, startAng:Number;
		var xcontrol:Number, ycontrol:Number, xend:Number, yend:Number;
		//
		//----------- TOP ------------//
		var mcTop1:MovieClip = mc.createEmptyMovieClip('mcTop1', mc.getNextHighestDepth());
		mcTop1.lineStyle(0, 0x0, 20);
		mcTop1.moveTo(this.config.rCylinder, this.config.hCylinder/2);
		//
		startAng = 0;
		directionSign = 1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2;
		drawCurve(mcTop1, startAng, directionSign, xcenter, ycenter, true);
		//
		var blurX:Number = 2;
		var blurY:Number = 2;
		var quality:Number = 2;
		var filter:BlurFilter = new BlurFilter(blurX, blurY, quality);
		var filterArray:Array = new Array();
		filterArray.push(filter);
		mcTop1.filters = filterArray;
		//-----------------------//
		var mcTop2:MovieClip = mc.createEmptyMovieClip('mcTop2', mc.getNextHighestDepth());
		mcTop2.lineStyle(0, 0xFFFFFF, 100);
		mcTop2.moveTo(this.config.rCylinder, this.config.hCylinder/2-2);
		//
		startAng = 0;
		directionSign = 1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2-2;
		drawCurve(mcTop2, startAng, directionSign, xcenter, ycenter, true);
		//
		var blurX:Number = 2;
		var blurY:Number = 2;
		var quality:Number = 2;
		var filter:BlurFilter = new BlurFilter(blurX, blurY, quality);
		var filterArray:Array = new Array();
		filterArray.push(filter);
		mcTop2.filters = filterArray;
		//----------- BOTTOM ------------//
		var mcBottom1:MovieClip = mc.createEmptyMovieClip('mcBottom1', mc.getNextHighestDepth());
		mcBottom1.lineStyle(0, 0x0, 20);
		mcBottom1.moveTo(-this.config.rCylinder, -this.config.hCylinder/2);
		//
		startAng = Math.PI;
		directionSign = -1;
		xcenter = 0;
		ycenter = -this.config.hCylinder/2;
		drawCurve(mcBottom1, startAng, directionSign, xcenter, ycenter, true);
		//
		var blurX:Number = 2;
		var blurY:Number = 2;
		var quality:Number = 3;
		var filter:BlurFilter = new BlurFilter(blurX, blurY, quality);
		var filterArray:Array = new Array();
		filterArray.push(filter);
		mcBottom1.filters = filterArray;
		//-----------------------//
		var mcBottom2:MovieClip = mc.createEmptyMovieClip('mcBottom2', mc.getNextHighestDepth());
		mcBottom2.lineStyle(2, 0xFFFFFF, 30);
		mcBottom2.moveTo(-this.config.rCylinder, -this.config.hCylinder/2-2);
		//
		startAng = Math.PI;
		directionSign = -1;
		xcenter = 0;
		ycenter = -this.config.hCylinder/2-2;
		drawCurve(mcBottom2, startAng, directionSign, xcenter, ycenter, true);
		//
		var blurX:Number = 2;
		var blurY:Number = 2;
		var quality:Number = 3;
		var filter:BlurFilter = new BlurFilter(blurX, blurY, quality);
		var filterArray:Array = new Array();
		filterArray.push(filter);
		mcBottom2.filters = filterArray;
		//-----------------------//
		var mcFullBase:MovieClip = mc.createEmptyMovieClip('mcFullBase', mc.getNextHighestDepth());
		mcFullBase._alpha = 35;
		mcFullBase.lineStyle(0, 0x0, 0);
		//
		var fillType = "linear";
		var colors = [0x0, 0xFFFFFF, 0xFFFFFF, 0x0];
		var alphas = [20, 40, 40, 20];
		var ratios = [0, 90, 100, 255];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hCylinder+this.config.hMin, Math.PI, -this.config.rCylinder, 0);
		mcFullBase.beginGradientFill(fillType, colors, alphas, ratios, matrix);
		//
		mcFullBase.moveTo(this.config.rCylinder, this.config.hCylinder/2);
		//
		startAng = 0;
		directionSign = 1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2;
		drawCurve(mcFullBase, startAng, directionSign, xcenter, ycenter, true);
		//
		startAng = Math.PI;
		drawCurve(mcFullBase, startAng, directionSign, xcenter, ycenter, true);
		//------------------------//
		var mcRightIndirectLight:MovieClip = mc.createEmptyMovieClip('mcRightIndirectLight', mc.getNextHighestDepth());
		mcRightIndirectLight.lineStyle(0, 0x0, 0);
		//
		var fillType = "linear";
		var colors = [0xFFFFFF, 0xFFFFFF, 0xFFFFFF];
		var alphas = [10, 50, 100];
		var ratios = [230, 252, 255];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hCylinder+this.config.hMin, 0, -this.config.rCylinder, 0);
		mcRightIndirectLight.beginGradientFill(fillType, colors, alphas, ratios, matrix);
		//
		mcRightIndirectLight.moveTo(this.config.rCylinder, this.config.hCylinder/2);
		//
		startAng = 0;
		directionSign = 1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2;
		drawCurve(mcRightIndirectLight, startAng, directionSign, xcenter, ycenter, true);
		//
		startAng = Math.PI;
		drawCurve(mcRightIndirectLight, startAng, directionSign, xcenter, ycenter, true);
		//------------------------//
		var mcLeftIndirectLight:MovieClip = mc.createEmptyMovieClip('mcLeftIndirectLight', mc.getNextHighestDepth());
		mcLeftIndirectLight.lineStyle(0, 0x0, 0);
		//
		var fillType = "linear";
		var colors = [0xFFFFFF, 0xFFFFFF, 0xFFFFFF];
		var alphas = [80, 50, 10];
		var ratios = [0, 3, 20];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hCylinder+this.config.hMin, 0, -this.config.rCylinder, 0);
		mcLeftIndirectLight.beginGradientFill(fillType, colors, alphas, ratios, matrix);
		//
		mcLeftIndirectLight.moveTo(this.config.rCylinder, this.config.hCylinder/2);
		//
		startAng = 0;
		directionSign = 1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2;
		drawCurve(mcLeftIndirectLight, startAng, directionSign, xcenter, ycenter, true);
		//
		startAng = Math.PI;
		drawCurve(mcLeftIndirectLight, startAng, directionSign, xcenter, ycenter, true);
		//------------------------//
		var mcDirectLight:MovieClip = mc.createEmptyMovieClip('mcDirectLight', mc.getNextHighestDepth());
		mcDirectLight._alpha = 15;
		mcDirectLight.lineStyle(0, 0x0, 0);
		//
		var fillType = "linear";
		var colors = [0xFFFFFF, 0xFFFFFF0, 0xFFFFFF, 0xFFFFFF];
		var alphas = [0, 100, 100, 0];
		var ratios = [29, 30, 60, 61];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hCylinder+this.config.hMin, Math.PI, -this.config.rCylinder, 0);
		mcDirectLight.beginGradientFill(fillType, colors, alphas, ratios, matrix);
		//
		mcDirectLight.moveTo(this.config.rCylinder, this.config.hCylinder/2);
		//
		startAng = 0;
		directionSign = 1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2;
		drawCurve(mcDirectLight, startAng, directionSign, xcenter, ycenter, true);
		//
		startAng = Math.PI;
		drawCurve(mcDirectLight, startAng, directionSign, xcenter, ycenter, true);
		//------------------------//
		var mcTopSparkle:MovieClip = mc.createEmptyMovieClip('mcTopSparkle', mc.getNextHighestDepth());
		mcTopSparkle.lineStyle(2);
		//
		var fillType = "linear";
		var colors = [0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF];
		var alphas = [0, 80, 80, 0];
		var ratios = [20, 30, 60, 70];
		//
		var matrix = new Matrix();
		matrix.createGradientBox(this.config.rCylinder*2, this.config.hCylinder+this.config.hMin, Math.PI, -this.config.rCylinder, 0);
		mcTopSparkle.lineGradientStyle(fillType, colors, alphas, ratios, matrix);
		//
		mcTopSparkle.moveTo(this.config.rCylinder, this.config.hCylinder/2-2);
		//
		startAng = 0;
		directionSign = 1;
		xcenter = 0;
		ycenter = this.config.hCylinder/2-2;
		drawCurve(mcTopSparkle, startAng, directionSign, xcenter, ycenter, true);
		//
		var blurX:Number = 2;
		var blurY:Number = 2;
		var quality:Number = 1;
		var filter:BlurFilter = new BlurFilter(blurX, blurY, quality);
		var filterArray:Array = new Array();
		filterArray.push(filter);
		mcTopSparkle.filters = filterArray;
		//-----------------------//
	}
	/**
	 * drawFluid method renders the fluid in cylinder.
	 * @param	mc1		MC reference of fluid body
	 * @param	mc2		MC reference of fluid top-face
	 */
	private function drawFluid(mc1:MovieClip, mc2:MovieClip):Void {
		var rFluid:Number = this.config.rCylinder;
		var fluidColor:Number = this.config.fluidColor;
		var topFluidColor:Number = ColorExt.getDarkColor(fluidColor.toString(16), 0.9);
		var fluidShadow:Number = ColorExt.getDarkColor(fluidColor.toString(16), 0.7);
		var topHighlightThickness:Number = 5;
		var bLower:Number = this.config.bLower;
		//
		var mc:MovieClip = mc1;
		////////////////////////////////////   BODY OF FLUID   /////////////////////////////////////////
		//
		var fillType = "radial";
		var colors = [fluidColor, fluidShadow];
		var alphas = [100, 100];
		var ratios = [50, 255];
		var matrix = new Matrix();
		matrix.createGradientBox(rFluid*2, this.config.hCylinder*2+this.config.hMin, 0, -rFluid, 0);
		mc.beginGradientFill(fillType, colors, alphas, ratios, matrix);
		//
		mc.lineStyle(0, 0x0, 0);
		mc._x = this.config.centerX;
		mc._y = this.config.centerY-this.config.hCylinder/2-bLower;
		//
		var xcenter:Number, ycenter:Number, directionSign:Number, startAng:Number;
		//
		mc.moveTo(-rFluid, bLower);
		//
		startAng = Math.PI;
		directionSign = 1;
		xcenter = 0;
		ycenter = bLower;
		drawCurve(mc, startAng, directionSign, xcenter, ycenter, false);
		//
		mc.lineTo(rFluid, this.config.hCylinder+bLower);
		//
		startAng = 0;
		directionSign = 1;
		xcenter = 0;
		ycenter = this.config.hCylinder+bLower;
		drawCurve(mc, startAng, directionSign, xcenter, ycenter, true);
		//
		mc.lineTo(-rFluid, bLower);
		//-----------------------------------//
		var grid:Rectangle = new Rectangle(-rFluid+bLower, bLower, 2*rFluid-2*bLower, this.config.hCylinder);
		mc.scale9Grid = grid;
		//-------------------------------------------------------------//
		mc = mc2;
		mc.lineStyle(0, 0x0, 0);
		mc._x = this.config.centerX;
		mc._y = this.config.centerY+this.config.hCylinder/2;
		//////////////////////////  TOP OF FLUID  //////////////////////////////////////
		/**
		 *	mcFluidTop
		 *		mcMaskTopEffect
		 *		mcTopEffect
		 *		mcTopBase
		 */
		var mcTopBase:MovieClip = mc.createEmptyMovieClip('mcTopBase', 0);
		mcTopBase.beginFill(topFluidColor, 60);
		mcTopBase.moveTo(rFluid, 0);
		startAng = 0;
		directionSign = 1;
		xcenter = 0;
		ycenter = 0;
		drawCurve(mcTopBase, startAng, directionSign, xcenter, ycenter, true);
		startAng = Math.PI;
		drawCurve(mcTopBase, startAng, directionSign, xcenter, ycenter, true);
		//-------//
		var mcTopEffect:MovieClip = mc.createEmptyMovieClip('mcTopEffect', 1);
		mcTopEffect.lineStyle(topHighlightThickness, 0xFFFFFF, 30);
		//
		var fillType = "radial";
		var colors = [0xFFFFFF, 0x000000];
		var alphas = [0, 10];
		var ratios = [150, 255];
		var matrix = new Matrix();
		matrix.createGradientBox(rFluid*2-topHighlightThickness, this.config.hMin-topHighlightThickness, 0, -rFluid, -this.config.hMin/2);
		mcTopEffect.beginGradientFill(fillType, colors, alphas, ratios, matrix);
		//
		mcTopEffect.moveTo(rFluid, 0);
		startAng = 0;
		directionSign = 1;
		xcenter = 0;
		ycenter = 0;
		drawCurve(mcTopEffect, startAng, directionSign, xcenter, ycenter, true);
		startAng = Math.PI;
		drawCurve(mcTopEffect, startAng, directionSign, xcenter, ycenter, true);
		//-------//
		var mcMaskTopEffect:MovieClip = mcTopBase.duplicateMovieClip('mcMaskTopEffect', 2);
		mcTopEffect.setMask(mcMaskTopEffect);
	}
	/**
	 * drawCurve method draws elliptic curve subtending 180 degree
	 * at the ellipse centre, in specified direction.
	 * @param	mcCanvas			MC to draw curve in
	 * @param	startAng			starting angle in radians
	 * @param	directionSign		anti-clockwise(+1) or clockwise(-1)
	 * @param	xcenter				abscissa of ellipse center
	 * @param	ycenter				ordinate of ellipse center
	 * @param	topCurve			flag for drawing part of ellipse
	 *								contained in upper (ellipse); (for perspective)
	 */
	private function drawCurve(mcCanvas:MovieClip, startAng:Number, directionSign:Number, xcenter:Number, ycenter:Number, topCurve:Boolean):Void {
		var sa:Number = this.config.rCylinder;
		var sb:Number = this.config.rCylinder*this.config.squeeze;
		if (topCurve) {
			sb /= this.config.factor;
		} else {
			//sb *= 1.1;
		}
		var xcontrol:Number, ycontrol:Number, xend:Number, yend:Number;
		for (var j:Number = 1; j<=4; ++j) {
			var t:Number = startAng+directionSign*Math.PI/4*j;
			xend = xcenter+sa*Math.cos(t);
			yend = ycenter+sb*Math.sin(t);
			xcontrol = xcenter+sa*Math.cos((2*(startAng+directionSign*Math.PI/4*(j-1))+directionSign*Math.PI/4)/2)/Math.cos(Math.PI/4/2);
			ycontrol = ycenter+sb*Math.sin((2*(startAng+directionSign*Math.PI/4*(j-1))+directionSign*Math.PI/4)/2)/Math.cos(Math.PI/4/2);
			mcCanvas.curveTo(xcontrol, ycontrol, xend, yend);
		}
	}
}
