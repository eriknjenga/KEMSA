// Import the Matrix class
import flash.geom.Matrix;
// Import the MathExt class
import com.fusioncharts.is.extensions.MathExt;
// Import the ColorExt class
import com.fusioncharts.is.extensions.ColorExt;
// Import the PyramidChart class (hack to fix a flash issue)
import com.fusioncharts.is.core.charts.PyramidChart;
/**
 * @class 		Pyramid
 * @version		3.0
 * @author		InfoSoft Global (P) Ltd.
 *
 * Copyright (C) InfoSoft Global Pvt. Ltd.
 
 * Pyramid class is responsible for creating a pyramid.
 * The pyramid is drawn on its instantiation by passing
 * parameters. Each instance is passed a (common) object
 * with a host of properties in them, the movieclip 
 * reference in which to draw the pyramid.
 */
class com.fusioncharts.is.core.chartobjects.Pyramid {
	// stores the reference of the basic Pyramid chart class
	private var chartClass;
	// stores the object, with a host of properties, passed as parameter during instantiation of this class
	private var objData:Object;
	// stores the reference of the movieclip constituting the whole pyramid
	private var mcObject:MovieClip;
	/**
	 * Constructor function for the class. Calls the primary 
	 * drawPyramid method.
	 * @param	chartClassRef	Name of class instance instantiating this.
	 * @param	mcPyramid		A movie clip reference passed from the
	 *							main movie. This movie clip is the clip
	 *							inside which we'll draw the pyramid.
	 *							Has to be necessarily provided.
	 * @param	obj				Object with various properties necessary
	 *							for drawing pyramid. 
	 */
	public function Pyramid(chartClassRef, mcPyramid:MovieClip, obj:Object) {
		// stores the referene of the basic class for creating a pyramid chart 
		chartClass = chartClassRef;
		// stores the reference of the movieclip inside which rendering 
		// for this pyramid, need to be done.
		mcObject = mcPyramid;
		// stores the object, with a host of properties
		objData = obj;
		// drawing of the pyramid is initialised
		this.drawPyramid();
		// rendering of labels initialised
		this.placeLabel();
	}
	/**
	 * drawPyramid is the prime method to control the entire
	 * work flow of rendering a specific pyramid along with
	 * all its visual features.
	 */
	private function drawPyramid():Void {
		// center co-ordinates of the lower rhombus of this pyramid
		var xcenter:Number = objData.x;
		var ycenter:Number = objData.y;
		//----------------------- Pyramid parameters ------------------------------//
		// squeezing factor of the squares to rhombuses, perspective issue
		var squeeze:Number = objData.squeeze;
		// original 3D perspective factor
		var squeezeMaxValue:Number = objData.squeezeMaxValue;
		// half of the angle subtended by the base width of the lowest pyramid at the apex (before isometric transformations), in radians
		var pyramidAngle:Number = objData.pyramidAng;
		// height of the pyramid to apex of pyramid layers above (and including) the current one
		var depthFromApex:Number = objData.depthFromApex;
		// height difference between centers of upper and lower rhombuses of this pyramid
		var pyramidHeight:Number = objData.h;
		//--------------------------- Record in MC ---------------------------------//
		// recording in pyramid MC, if this pyramid is currently sliced                                         
		mcObject.isSliced = objData.isSliced;
		// storing reference of pyramid id in pyramid MC
		// id w.r.t. this.data
		mcObject.idPerm = objData.idPerm;
		// id w.r.t. this.config.arrPyramid
		mcObject.idTemp = objData.idTemp;
		//----------------------------- Vertices -----------------------------------//
		// method called to get the 3D vertices of the pyramid
		var arrPoints:Array = this.getPyramid3DVertices(depthFromApex, pyramidHeight, pyramidAngle, ycenter);
		// vertices (in (x,y,z) form) stored in local variables
		// nomenclature is w.r.t. what a vertex WILL finally represent after isometric transformation (yet)
		// lower ones
		var bottomFront:Number = arrPoints[0][0];
		var bottomRight:Number = arrPoints[0][1];
		var bottomBack:Number = arrPoints[0][2];
		var bottomLeft:Number = arrPoints[0][3];
		// upper ones
		var topFront:Number = arrPoints[1][0];
		var topRight:Number = arrPoints[1][1];
		var topBack:Number = arrPoints[1][2];
		var topLeft:Number = arrPoints[1][3];
		//---------------------------------  Cosmetics ----------------------------------//
		// effect variation range factor
		var factor:Number = (squeezeMaxValue != 0) ? squeeze/squeezeMaxValue : 1;
		// color variation intensity set for the current perspective
		var variationIntensity:Number = 0.9-0.1*factor;
		// color derived from the pyramid color to be used for creating shadows
		var shadowColor:Number = ColorExt.getDarkColor(objData['color'].toString(16), variationIntensity);
		// color derived from the pyramid color to be used for creating highlights
		var highlightColor:Number = ColorExt.getLightColor(objData['color'].toString(16), variationIntensity);
		//------------------------------ D R A W I N G   B E G I N S ---------------------------------------//
		// mcObject
		//		- mcTop
		//				- mcBorder
		//				- mcBase
		//		- mcLeft
		//				- mcBorder
		//				- mchighlightGrad
		//				- mcBase
		//		- mcRight
		//				- mchighlightGrad
		//				- mcBase
		//		- mcBackBottomBorder
		//	if (objData.is2D) {
		//		- mcBorder
		//	}
		//---------------------- bottom back border ------------------------//
		var _mc:MovieClip = mcObject.createEmptyMovieClip('mcBackBottomBorder', mcObject.getNextHighestDepth());
		_mc.lineStyle(2, objData.borderColor, ((squeeze == 0) ? 0 : objData.fillAlpha));
		//
		var x = this.xFla(bottomLeft);
		var y = this.yFla(bottomLeft);
		_mc.moveTo(x, y);
		//
		var x = this.xFla(bottomBack);
		var y = this.yFla(bottomBack);
		_mc.lineTo(x, y);
		//
		var x = this.xFla(bottomRight);
		var y = this.yFla(bottomRight);
		_mc.lineTo(x, y);
		//--------------- MASK of above MC----------------//
		var _mc:MovieClip = mcObject.createEmptyMovieClip('mcBackBottomMask', mcObject.getNextHighestDepth());
		_mc.lineStyle(0);
		_mc.beginFill(0x0, 0);
		//
		var x = this.xFla(bottomLeft);
		var y = this.yFla(bottomLeft);
		_mc.moveTo(x, y);
		//
		var x = this.xFla(bottomBack);
		var y = this.yFla(bottomBack);
		_mc.lineTo(x, y);
		//
		var x = this.xFla(bottomRight);
		var y = this.yFla(bottomRight);
		_mc.lineTo(x, y);
		//
		var x = this.xFla(bottomFront);
		var y = this.yFla(bottomFront);
		_mc.lineTo(x, y);
		//setting mask for mcBackBottomBorder, to cover up projections of thick lines (as the case may be)
		mcObject.mcBackBottomBorder.setMask(_mc);
		//--------------------- right face -----------------------------//
		var right_mc:MovieClip = mcObject.createEmptyMovieClip('mcRight', mcObject.getNextHighestDepth());
		//----------------------//
		var _mc:MovieClip = right_mc.createEmptyMovieClip('mcBase', right_mc.getNextHighestDepth());
		//
		_mc.lineStyle(0, objData.borderColor, 0);
		_mc.beginFill(shadowColor, objData.fillAlpha);
		//
		var x = this.xFla(topFront);
		var y = this.yFla(topFront);
		_mc.moveTo(x, y);
		//
		var x = this.xFla(topRight);
		var y = this.yFla(topRight);
		_mc.lineTo(x, y);
		//
		var x = this.xFla(bottomRight);
		var y = this.yFla(bottomRight);
		_mc.lineTo(x, y);
		//
		var x = this.xFla(bottomFront);
		var y = this.yFla(bottomFront);
		_mc.lineTo(x, y);
		//
		_mc.endFill();
		//----------------------//
		if (!objData.is2D) {
			var _mc:MovieClip = right_mc.createEmptyMovieClip('mchighlightGrad', right_mc.getNextHighestDepth());
			_mc.lineStyle(0, objData.borderColor, 0);
			//
			var fillType:String = 'linear';
			var arrColors:Array = [highlightColor, shadowColor];
			var arrAlphas:Array = [objData.fillAlpha*factor, (objData.fillAlpha*0.1)*factor];
			var arrRatios:Array = [0, 10];
			var box_matrix:Matrix = new Matrix();
			var wBox:Number = objData.rightBoxWidth;
			var hBox:Number = Math.abs(this.yFla(topRight)-this.yFla(bottomFront));
			box_matrix.createGradientBox(wBox, hBox, 0, this.xFla(bottomFront), this.yFla(bottomFront));
			_mc.beginGradientFill(fillType, arrColors, arrAlphas, arrRatios, box_matrix);
			//
			var x = this.xFla(topFront);
			var y = this.yFla(topFront);
			_mc.moveTo(x, y);
			//
			var x = this.xFla(topRight);
			var y = this.yFla(topRight);
			_mc.lineTo(x, y);
			//
			var x = this.xFla(bottomRight);
			var y = this.yFla(bottomRight);
			_mc.lineTo(x, y);
			//
			var x = this.xFla(bottomFront);
			var y = this.yFla(bottomFront);
			_mc.lineTo(x, y);
			//
			_mc.endFill();
		}
		//-------------------------- left face ------------------------------//                   
		var left_mc:MovieClip = mcObject.createEmptyMovieClip('mcLeft', mcObject.getNextHighestDepth());
		//----------------------//
		var _mc:MovieClip = left_mc.createEmptyMovieClip('mcBase', left_mc.getNextHighestDepth());
		//
		_mc.lineStyle(0, objData.borderColor, 0);
		_mc.beginFill(highlightColor, objData.fillAlpha);
		//
		var x = this.xFla(topFront);
		var y = this.yFla(topFront);
		_mc.moveTo(x, y);
		//
		var x = this.xFla(topLeft);
		var y = this.yFla(topLeft);
		_mc.lineTo(x, y);
		//
		var x = this.xFla(bottomLeft);
		var y = this.yFla(bottomLeft);
		_mc.lineTo(x, y);
		//
		var x = this.xFla(bottomFront);
		var y = this.yFla(bottomFront);
		_mc.lineTo(x, y);
		//
		_mc.endFill();
		//----------------------//
		if (!objData.is2D) {
			var _mc:MovieClip = left_mc.createEmptyMovieClip('mchighlightGrad', left_mc.getNextHighestDepth());
			_mc.lineStyle(0, objData.borderColor, 0);
			//
			var fillType:String = 'linear';
			var arrColors:Array = [highlightColor, 0xffffff];
			var arrAlphas:Array = [0, (objData.fillAlpha*0.2)*factor];
			var arrRatios:Array = [240, 255];
			var box_matrix:Matrix = new Matrix();
			var wBox:Number = objData.leftBoxWidth;
			var hBox:Number = Math.abs(this.yFla(topLeft)-this.yFla(bottomFront));
			box_matrix.createGradientBox(wBox, hBox, 0, this.xFla(bottomFront)-wBox, this.yFla(bottomFront));
			_mc.beginGradientFill(fillType, arrColors, arrAlphas, arrRatios, box_matrix);
			//
			var x = this.xFla(topFront);
			var y = this.yFla(topFront);
			_mc.moveTo(x, y);
			//
			var x = this.xFla(topLeft);
			var y = this.yFla(topLeft);
			_mc.lineTo(x, y);
			//
			var x = this.xFla(bottomLeft);
			var y = this.yFla(bottomLeft);
			_mc.lineTo(x, y);
			//
			var x = this.xFla(bottomFront);
			var y = this.yFla(bottomFront);
			_mc.lineTo(x, y);
			//
			_mc.endFill();
			//----------------------// 
			var _mc:MovieClip = left_mc.createEmptyMovieClip('mcBorder', left_mc.getNextHighestDepth());
			_mc.lineStyle(2, 0xffffff, (objData.fillAlpha*0.05)*factor);
			//
			var x = this.xFla(topFront);
			var y = this.yFla(topFront);
			_mc.moveTo(x, y);
			//
			var x = this.xFla(bottomFront);
			var y = this.yFla(bottomFront);
			_mc.lineTo(x, y);
		}
		//------------------------- top face --------------------------------//                
		if (!objData.is2D || pyramidHeight == 0) {
			var top_mc:MovieClip = mcObject.createEmptyMovieClip('mcTop', mcObject.getNextHighestDepth());
			//----------------------//
			var _mc:MovieClip = top_mc.createEmptyMovieClip('mcBase', top_mc.getNextHighestDepth());
			_mc.lineStyle(0, objData.borderColor, 0);
			//
			var fillType:String = 'linear';
			var arrColors:Array = [highlightColor, shadowColor];
			var arrAlphas:Array = [objData.fillAlpha, objData.fillAlpha];
			var arrRatios:Array = [50, 180];
			var box_matrix:Matrix = new Matrix();
			var wBox:Number = Math.abs(this.xFla(topLeft)-this.xFla(topRight));
			var hBox:Number = Math.abs(this.yFla(topFront)-this.yFla(topBack));
			box_matrix.createGradientBox(wBox, hBox, -Math.PI/4, this.xFla(topLeft), this.yFla(topBack)+hBox/4);
			_mc.beginGradientFill(fillType, arrColors, arrAlphas, arrRatios, box_matrix);
			//
			var x = this.xFla(topFront);
			var y = this.yFla(topFront);
			_mc.moveTo(x, y);
			//
			var x = this.xFla(topLeft);
			var y = this.yFla(topLeft);
			_mc.lineTo(x, y);
			//
			var x = this.xFla(topBack);
			var y = this.yFla(topBack);
			_mc.lineTo(x, y);
			//
			var x = this.xFla(topRight);
			var y = this.yFla(topRight);
			_mc.lineTo(x, y);
			//
			_mc.endFill();
			//----------------------//
			if ((pyramidHeight != 0 && squeeze != 0) || squeeze == 0) {
				var _mc:MovieClip = top_mc.createEmptyMovieClip('mcBorder', top_mc.getNextHighestDepth());
				// capStyle is set to "none" to avoid outward projection at right end
				_mc.lineStyle(2, 0x0, 100, false, "normal", "none");
				//
				var fillType:String = 'linear';
				var arrColors:Array = [0xffffff, objData.color];
				var lineAlpha:Number = Math.round(objData.fillAlpha*0.3);
				var arrAlphas:Array = [lineAlpha, lineAlpha];
				//
				var arrRatios:Array = [40, 100];
				var box_matrix:Matrix = new Matrix();
				var wBox:Number = Math.abs(this.xFla(topLeft)-this.xFla(topRight));
				var hBox:Number = Math.abs(this.yFla(topFront)-this.yFla(topBack));
				box_matrix.createGradientBox(wBox, hBox, -Math.PI/4, this.xFla(topLeft), this.yFla(topBack));
				_mc.lineGradientStyle(fillType, arrColors, arrAlphas, arrRatios, box_matrix);
				//
				var x = this.xFla(topLeft);
				var y = this.yFla(topLeft);
				_mc.moveTo(x, y);
				//
				var x = this.xFla(topFront);
				var y = this.yFla(topFront);
				_mc.lineTo(x, y);
				//
				var x = this.xFla(topRight);
				var y = this.yFla(topRight);
				_mc.lineTo(x, y);
				//
				if (squeeze != 0) {
					var blurX:Number = 2;
					var blurY:Number = 2;
					var quality:Number = 2;
					var _blur:flash.filters.BlurFilter = new flash.filters.BlurFilter(blurX, blurY, quality);
					var arrFilters:Array = new Array();
					arrFilters.push(_blur);
					_mc.filters = arrFilters;
				}
			}
		}
		//------------------------- pyramid border --------------------------------//   
		// applicable only for explicitly 2D chart
		if (objData.is2D) {
			var _mc:MovieClip = mcObject.createEmptyMovieClip('mcBorder', mcObject.getNextHighestDepth());
			//----------------------//
			_mc.lineStyle(objData.lineThickness, objData.borderColor, objData.borderAlpha);
			//
			var x = this.xFla(topRight);
			var y = this.yFla(topRight);
			_mc.moveTo(x, y);
			//
			var x = this.xFla(topLeft);
			var y = this.yFla(topLeft);
			_mc.lineTo(x, y);
			//
			var x = this.xFla(bottomLeft);
			var y = this.yFla(bottomLeft);
			_mc.lineTo(x, y);
			//
			var x = this.xFla(bottomRight);
			var y = this.yFla(bottomRight);
			_mc.lineTo(x, y);
			//
			var x = this.xFla(topRight);
			var y = this.yFla(topRight);
			_mc.lineTo(x, y);
		}
	}
	/**
	 * getPyramid3DVertices method is called to evaluate and
	 * get all the 8 vertices of a pyramid in (x,y,z) form.
	 * @param	depthFromApex	depth of the pyramid base from 
	 *							apex
	 * @param	pyramidHeight	height difference between centres
	 *							of upper and lower rhombuses
	 * @param	pyramidAngle	semi-angle subtended by base of 
	 *							pyramid at apex (before isometric transformation)
	 * @param	ycenter			lower rhombus ordinate of pyramid
	 * @return					2 dimensional array, with 4 objects in each
	 *							dimension.
	 */
	private function getPyramid3DVertices(depthFromApex:Number, pyramidHeight:Number, pyramidAngle:Number, ycenter:Number):Array {
		var arrPoints:Array = new Array();
		// loop runs to evaluate vertices
		for (var i = 0; i<2; ++i) {
			// i = 0 ----> lower vertices of the pyramid
			// i = 1 ----> upper vertices of the pyramid
			// depth of the vertices from apex of the stacked pyramids.
			var depth:Number = (i == 0) ? depthFromApex : depthFromApex-pyramidHeight;
			// y coordinate adjustment value (absolute to specific coordinate system)
			var yAdjust:Number = (i == 0) ? 0 : pyramidHeight;
			// half the width of side of squares defining the pyramid
			var semiWidth:Number = depth*Math.tan(pyramidAngle);
			// a sub-array for each of the 2 levels of vertices (upper and lower)
			arrPoints[i] = new Array();
			// each level consists of 4 vertices
			// loop runs to find each in order
			for (var j = 0; j<4; ++j) {
				// multiplying factor, to set sign of the x coordinate, in order
				var xFactor:Number = (j == 0 || j == 3) ? -1 : 1;
				// multiplying factor, to set sign of the z coordinate, in order
				var zFactor:Number = (j == 0 || j == 1) ? -1 : 1;
				// 3D point characterised by x,y,z is encapsulated in an object
				var objPoint:Object = new Object();
				// x coordinate
				objPoint.x = MathExt.roundUp(xFactor*semiWidth);
				// y coordinate
				objPoint.y = MathExt.roundUp(ycenter+yAdjust);
				// z coordinate
				objPoint.z = MathExt.roundUp(zFactor*semiWidth);
				// object holding 3D coordinates is stored in level sub-array, in order               
				arrPoints[i].push(objPoint);
			}
		}
		// return
		return arrPoints;
	}
	/**
	 * xFla method transforms x,y,z coordinates into Flash x 
	 * coordinate.
	 * @param	obj		object containing x,y,z coordinates
	 * @return			flash coordinate.
	 */
	private function xFla(obj:Object):Number {
		var isometricAngle:Number = Math.atan(objData.squeeze);
		var xOrigin:Number = objData.x;
		// 3D coordinates
		var x = obj.x;
		var y = obj.y;
		var z = obj.z;
		// cartesian coordinates 
		var xCart = (x-z)*Math.cos(isometricAngle);
		// flash coordinates 
		var xI = MathExt.roundUp(xCart+xOrigin);
		return xI;
	}
	/**
	 * yFla method transforms x,y,z coordinates into Flash y 
	 * coordinate.
	 * @param	obj		object containing x,y,z coordinates
	 * @return			flash coordinate.
	 */
	private function yFla(obj:Object):Number {
		var isometricAngle:Number = Math.atan(objData.squeeze);
		var yOrigin:Number = objData.y;
		// 3D coordinates
		var x = obj.x;
		var y = obj.y;
		var z = obj.z;
		// cartesian coordinates 
		var yCart = y+(x+z)*Math.sin(isometricAngle);
		// flash coordinates
		var yI = MathExt.roundUp(-yCart+2*yOrigin);
		return yI;
	}
	/**
	 * placeLabel method renders label for a pyramid,
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
		// call to connect label with the pyramid with lines if labels are not be placed at pyramid center
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
	}
	/**
	 * joinLabel method joins a label with its pyramid by
	 * drawing lines.
	 */
	private function joinLabel():Void {
		var xIni:Number, yIni:Number, xEnd:Number, yEnd:Number;
		// getting starting and ending coordinates of the joining line
		xIni = Math.round(objData.x+objData.rightHalfWidth);
		yIni = Math.round(objData.y-objData.h/2);
		xEnd = Math.round(objData.xTxt);
		yEnd = Math.round(objData.yTxt+3*objData.txtHeight/4);
		// MC created to render this line in
		var mcLabelJoin:MovieClip = mcObject.createEmptyMovieClip('mcLabelJoin', mcObject.getNextHighestDepth());
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
}
