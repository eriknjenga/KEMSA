/** --- ExternalInterface.as ---
* Copyright InfoSoft Global Private Ltd. and its licensors.  All Rights Reserved.
*
* Use and/or redistribution of this file, in whole or in part, is subject
* to the License Files, which was distributed with this component.
*
* Data loading and parsing functions
* This file contains functions and constant definitions only, and is not
* associated with a class/movie clip.
*/
//If the movie is registered with JS (or other external script), we need to invoke
//the required external function FC_Loaded
if (_registerWithJS) {
	//We check the availability of ExternalInterface
	if (!ExternalInterface.available) {
		//Add the message to logger
		chart.log("WARNING", "Cannot register chart with external script. You need to allow script access for this chart.", Logger.LEVEL.ERROR);
	} else {
		//Call FC_Loaded JavaScript function to register
		//the load event of this chart i.e., the chart has
		//been downloaded to end user's computer and is
		//ready for any further actions.
		//If you want to return any value from the external interface call
		//uncomment line 1 below and comment line 2 (referential line no.s)
		//var objReturn:Object = ExternalInterface.call("FC_Loaded", _DOMId);
		ExternalInterface.call("FC_Loaded", _DOMId);
		//Also log the message based on existence of _DOMId
		if (_DOMId == undefined) {
			chart.log("INFO", "Chart registered with external script. However, the DOM Id of chart has not been defined. You need to define it if you want to interact with the chart using external scripting.", Logger.LEVEL.INFO);
		} else {
			chart.log("INFO", "Chart registered with external script. DOM Id of chart is "+_DOMId, Logger.LEVEL.INFO);
		}
	}
	//Register the setDataURL and setDataXML methods with external script
	var exDU:Boolean = ExternalInterface.addCallback("setDataURL", this, setDataURL);
	var exDX:Boolean = ExternalInterface.addCallback("setDataXML", this, setDataXML);
}
