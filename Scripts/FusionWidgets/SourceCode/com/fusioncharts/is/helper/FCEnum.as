/**
* @class FCEnum
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.

* This class represents a basic Enumeration object, which stores
* a series of elements with a sequential numeric id associated to it.
* We've named it as FCEnum instead of Enum, as Enum is a reserved keyword
* by Flash for future usage.
*/
dynamic class com.fusioncharts.is.helper.FCEnum {
	//Private variable iterator to keep currently accessed value's index
	//By default set it to 1 - start of array.
	private var _iterator:Number = 1;
	//Count of total elements in the enumeration.
	private var _size:Number = 0;
	/**
	* Constructor function that takes in an array of string literals
	* and allots a sequential id to each one of them.
	*/
	function FCEnum() {
		//Deviation from standard: We're allowing to create empty enumerations
		//and to add values to them later.
		//Loop Variable  
		var i:Number;
		//Enumeration numeric index is base 1.
		//If the first element in arguments is array, then it means
		//that we've to render an enumeration from array.
		//If the enumeration items is passed as an array
		if (arguments[0] instanceof Array) {
			//Get the list of items
			var arrItems:Array = arguments[0];
			for (i=0; i<arrItems.length; i++) {
				this[arrItems[i]] = i+1;
			}
			//Store the size
			_size = arrItems.length;
		} else {
			//Iterate through the list of parameters passed
			//using the arguments collection
			for (i=0; i<arguments.length; i++) {
				//Save each literal in the array as array's key
				//and binary value as array's value.
				this[arguments[i]] = i+1;
			}
			//Store the size
			_size = arguments.length;
		}
	}
	/**
	 * addItem method adds a new item to the enumeration. 
	 *	@param	item	Item to add to enumeration.
	*/
	public function addItem(item:String):Void {
		//Increment size
		_size++;
		//Add the item
		this[item] = _size;
	}
	/**
	 * getItem method returns the value of an item currently in
	 * the enumeration.
	 *	@param	item	Item whose value is to be returned. -1 if not found.
	*/
	public function getItem(item:String):Number {
		return (this[item] == undefined) ? -1 : this[item];
	}
	/**
	* Moves the sequential iterator to start position.
	*/
	public function moveToFirst():Void {
		_iterator = 1;
	}
	/**
	* During sequential fetch, this method checks whether there are
	* any more elements in the enumeration and returns a boolean value
	* indicating that.
	* @return Boolean value indicating whether there are any more items
	*			in the enumeration.
	*/
	public function hasMoreElements():Boolean {
		return (_iterator<=_size);
	}
	/**
	* Returns the name and value of the next item in enumeration during
	* a sequential fetch.
	* @return Object containing name and value. Return value is of Object
	*			type having two properties - name and value.
	*/
	public function nextElement():Object {
		//If it's already the last element, throw an error
		if (!hasMoreElements()) {
			throw new Error("No more elements in enumeration");
		}
		var item:String;
		var rtn:Object = new Object();
		for (item in this) {
			if (this[item] == _iterator) {
				//If the class item has a value equal to the required iterator
				//value, we create a return object and assign values to it
				rtn.name = item;
				rtn.value = this[item];
			}
		}
		//Increment iterator
		_iterator++;
		//Return
		return rtn;
	}
}
