/**
* @class HashTable
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.

* HashTable enables developers direct access to data without having
* to traverse all the stored elements and is especially useful for
* storing data for maintaining state. After the table is populated the
* values can be retrieved directly using the corresponding keys.
* It should also be noted that in this implementation keys can be only
* string but any object type can be used for value. As, typically within
* an application it is common to store complex values (objects) only
* associated with a string key within a HashTable.

* It cannot contain duplicate keys and each key can only map to one value.
*/
class com.fusioncharts.is.helper.HashTable {
	//Array to store the key,value pairs
	private var table:Array;
	/**
	Constructor - Empty.
	*/
	function HashTable() {
		//Initialize table
		table = new Array();
	}
	//Public Methods
	/**
	* Adds the given key,value pair to table.
	* @param	key		Name of the key - can be string only for this implementation.
	* @param	value	Value of the key. This hashtable can store
	* any object as the value of a particular key.
	*/
	public function put(key:String, value:Object):Void {
		//Add the key value pair to table array
		//If the key is duplicated, Flash will automatically
		//overwrite the value.
		this.table[key] = value;
	}
	/**
	* Returns the value of a given key by iterating through the table.
	* @param	key	Name of the key.
	* @return	The value of the key as an object
	*/
	public function get(key:String):Object {
		//Get the value object
		return this.table[key];
	}
	/**
	* Removes a specified entry from the hash table whose key
	* matches the key passed
	* @param	key	Key which is to be removed from the HashTable
	*/
	public function remove(key:String):Void {
		//Delete
		delete this.table[key];
	}
	/**
	* Checks whether the table contains a specified key
	* @param	key	Key name.
	* @return	Returns a boolean value indicating whether the specified
	* 			key exists in this HashTable.
	*/
	public function containsKey(key:String):Boolean {
		//By default assume that the table doesn't contain this key
		var _contains:Boolean = false;
		var _item:String;
		for (_item in this.table) {
			//If we find a matching key, exit the loop
			if (_item == key) {
				_contains = true;
				break;
			}
		}
		return _contains;
	}
	/**
	* Returns the number of elements in hash table.
	* @return	Returns the number of elements in this hash table.
	*/
	public function size():Number {
		var _size:Number = 0;
		var _item:String;
		//Iterate through each item in the array and add.
		//Tricky: We cannot use Array.length here as we're not
		//adding values using push method (or general method).
		for (_item in this.table) {
			_size++;
		}
		return _size;
	}
	/**
	* Returns whether the hash table is empty
	* @return Returns a boolean value indicating whether this hash table
	* 			is empty or not.
	*/
	public function isEmpty():Boolean {
		return (this.size() == 0);
	}
	/**
	Clears the hash table.
	*/
	public function clear():Void {
		//Re-define the array
		this.table = new Array();
	}
	/**
	* Methods not implemented in this version:
	* clone():HashTable
	* getKeys():Array
	* getValues():Array
	* containsValue(value:Object):Boolean
	*/
}
