/**
* @class DepthMgr
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.

* DepthMgr helps manage depths of various movie clips.
*/
class com.fusioncharts.is.helper.DepthManager {
	//Iterator variable that iterates through depths
	private var _iterator:Number = 0;
	//Counter for start and end depths
	private var _startDepth:Number = 0;
	//Associative Array to store depths
	private var depths:Array;
	//Constructor function
	function DepthManager(startDepth:Number) {
		//Initialize the array
		depths = new Array();
		//Set the start depth
		setStartDepth(startDepth);
	}
	/**
	* reserveDepths method reserves the specified number of depths
	* for the given object.
	*/
	public function reserveDepths(objectName:String, numDepths:Number):Void {
		//Create object to represent the depths only if numDepths>0
		if (numDepths>0) {
			var depthObj:Object = new Object();
			depthObj.start = _iterator+1;
			depthObj.end = depthObj.start+numDepths-1;
			depthObj.num = numDepths;
			//Store object
			this.depths[objectName] = depthObj;
			//Update iterator
			_iterator = _iterator+numDepths;
		}
	}
	/**
	* getDepth method returns the start depth for the given object
	*	@param	objName	Name of object for which depth is to be retrieved
	*/
	public function getDepth(objName:String):Number {
		var depth:Number = this.depths[objName].start;
		//If undefined return 0
		if (isNaN(depth) || (depth == undefined)) {
			return 0;
		} else {
			return depth;
		}
	}
	/**
	* setStartDepth method sets the start depth from where we've
	* to start counting for depths.
	*	@param	startDepth 	Start Depth
	*/
	public function setStartDepth(startDepth):Void {
		//Update iterator
		_iterator = startDepth;
		_startDepth = startDepth;
	}
	/**
	* clear method clears the depth array for re-initializiaton purposes.
	*/
	public function clear() {
		//Delete the array.
		delete this.depths;
		//Re-initialize
		this.depths = new Array();
	}
}
