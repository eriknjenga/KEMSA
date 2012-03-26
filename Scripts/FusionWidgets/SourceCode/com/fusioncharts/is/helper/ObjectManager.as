/**
* @class ObjectManager
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* ObjectManager class helps us keep track of objects and their actual
* MC reference. It also helps us group the objects based on their names.
*/
class com.fusioncharts.is.helper.ObjectManager {
	//Array to store object groups
	private var groups:Array;
	/**
	 * Constructor function
	*/
	function ObjectManager() {
		//Initialize containers
		this.groups = new Array();
	}
	/**
	 * register method registers an object with this instance of ObjectManager.
	 *	@param	objRef			Reference to the actual object (movie clip/text field).
	 *	@param	strFriendlyName	Friendly name using which we want to store this object as.
	 *	@param	strGroupName	To which group does this object belong to? Friendly names.
	*/
	public function register(objRef:Object, strFriendlyName:String, strGroupName:String) {
		//First up, if we do not have a group with this name, create so.
		if (this.groups[strGroupName] == undefined) {
			//Create the object to store items
			this.groups[strGroupName] = new Object();
			//Now, array to store the item references
			this.groups[strGroupName].items = new Array();
		}
		//Now, push the item  
		this.groups[strGroupName].items[strFriendlyName] = objRef;
	}
	//--- We've created removeGroupMC & removeGroupTF as two different
	//--- functions to avoid condition overheads at run-time, as the condition
	//--- will get evaluated multiple times for each data feed update.
	/**
	 * removeGroupMC method removes all the MC in a specified group.
	 *	@param	strGroupName	Group whose items we've to remove.	 
	*/
	public function removeGroupMC(strGroupName:String):Void {
		//If there's no such group defined, simply return
		if (this.groups[strGroupName] == undefined) {
			return;
		}
		//Else, iterate through each item in this defined group  
		//and remove them, based on what they're
		var item:Object;
		for (item in this.groups[strGroupName].items) {			
			//Movie clip			
			this.groups[strGroupName].items[item].removeMovieClip();
		}
		//Delete entire group reference from array
		delete this.groups[strGroupName];
	}
	/**
	 * removeGroupTF method removes all the textfield in a specified group.
	 *	@param	strGroupName	Group whose items we've to remove.	 
	*/
	public function removeGroupTF(strGroupName:String):Void {
		//If there's no such group defined, simply return
		if (this.groups[strGroupName] == undefined) {
			return;
		}
		//Else, iterate through each item in this defined group  
		//and remove them, based on what they're
		var item:Object;
		for (item in this.groups[strGroupName].items) {
			//If the text field is rotated movie clip textfield, we use different method
			if (typeof(this.groups[strGroupName].items[item])=="movieclip"){
				//Remove the movie clip textfield (containing bitmap data)
				this.groups[strGroupName].items[item].removeMovieClip();
			}else{
				//Remove text field
				this.groups[strGroupName].items[item].removeTextField();			
			}
		}
		//Delete entire group reference from array
		delete this.groups[strGroupName];
	}
	/**
	 * clearGroupMC method clears all the movie clips in a specified group. 
	 * It doesn't remove them
	 *	@param	strGroupName	Group whose items we've to clear.	 
	*/
	public function clearGroupMC(strGroupName:String):Void {
		//If there's no such group defined, simply return
		if (this.groups[strGroupName] == undefined) {
			return;
		}
		//Else, iterate through each item in this defined group  
		//and clear them
		var item:Object;
		for (item in this.groups[strGroupName].items) {
			//Movie clip
			this.groups[strGroupName].items[item].clear();			
		}
		//Delete entire group reference from array
		delete this.groups[strGroupName];
	}
	/**
	 * toggleGroupVisibility method toggles the visibility of each item
	 * in a given group.
	 *	@param	strGroupName	Name of group whose items we've to toggle.
	 *	@param	state			The final visible state for those items.
	*/
	public function toggleGroupVisibility(strGroupName:String, state:Boolean):Void {
		//If there's no such group defined, simply return
		if (this.groups[strGroupName] == undefined) {
			return;
		}
		//Else, iterate through each item in this defined group  
		//and set their visible state
		var item:Object;
		for (item in this.groups[strGroupName].items) {
			this.groups[strGroupName].items[item]._visible = state;
		}
	}
	/**
	 * toggleItemVisibility method toogles the visibility of a specific item
	 * in the given group.
	 *	@param	strGroupName	Name of group to which this item belongs to.
	 *	@param	strItemName		Name of the item in the group, whose visibility
	 *							we've to toggle.
	 *	@param	state			The final visible state for those items.
	*/
	public function toggleItemVisibility(strGroupName:String, strItemName:String, state:Boolean):Void {
		//If there's no such group/item defined, simply return
		if (this.groups[strGroupName].items[strItemName] == undefined) {
			return;
		} else {
			//Set its visible state
			this.groups[strGroupName].items[strItemName]._visible = state;
		}
	}
	/**
	 * resetGroup method re-sets the object manager by clearing all stored
	 * references of a particular group.
	 *	@param	strGroupName	Group that we want to clear.
	*/
	function resetGroup(strGroupName:String) {
		//Reset the groups array
		delete this.groups[strGroupName];
	}
	/**
	 * reset method re-sets the object manager by clearing all stored
	 * references.
	*/
	function reset() {
		//Reset the groups array
		this.groups = new Array();
	}
}
