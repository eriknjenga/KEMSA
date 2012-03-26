/**
* @class AlertManager
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd. 
* AlertManager class helps us to manage all the real-time alerts to be
* raised as per the user specifications. The user can define his range based
* alerts and do any of the following when a condition is matched:
* - CallJS - Call a JavaScript method with specified parameters.
* - showAnnotation - Show a pre-defined annotation group.
* - playSound - Plays an external MP3 as sound.
*/
import com.fusioncharts.is.core.Chart;
//Utilities
import com.fusioncharts.is.helper.Utils;
import com.fusioncharts.is.helper.FCEnum;
import com.fusioncharts.is.helper.AnnotationManager;
//Logger Class
import com.fusioncharts.is.helper.Logger;
class com.fusioncharts.is.realtime.AlertManager{
	//Enumeration for the various actions that's supported
	private var ACTION:FCEnum;
	//Target MC - required to create MC for sound manager
	private var targetMC:MovieClip;
	//Instance of which chart?
	private var chartIns:Chart;
	//Reference to Annotation Manager
	private var am:AnnotationManager;
	//Number of defined alerts
	private var numAlerts:Number;
	//Array to store all the user defined alerts
	private var alerts:Array;
	//Storage objects for Sound Alerts
	private var soundMC:MovieClip;
	private var alertSound:Sound;
	private var soundPlaying:Boolean;	
	//Variables to help us track and restore annotations that
	//were shown by previous alert value match.
	private var annotationActive:Boolean;
	private var annotationId:String;
	private var annotationAlertId:Number;
	//Short forms for common function names
	private var getFV:Function;
	private var getFN:Function;
	private var toBoolean:Function;
	/**
	 * Constructor function.
	 *	@param	chartIns	Instance of the chart class for which we're managing
	 *						alerts.
	 *	@param	am			Annotation Manager class associated with the chart.
	*/
	function AlertManager(chartIns:Chart, am:AnnotationManager){
		//Short forms for common function names.
		this.getFV = Utils.getFirstValue;
		this.getFN = Utils.getFirstNumber;
		this.toBoolean = Utils.toBoolean;
		//Store parameters		
		this.chartIns = chartIns;
		this.am = am;
		//Enumerate the supported Action Types
		ACTION = new FCEnum("CALLJS", "SHOWANNOTATION", "PLAYSOUND");		
		//Initialize other objects		
		this.soundPlaying = false;
		this.alerts = new Array();
		this.numAlerts = 0;
		//Set flags related to annotation
		this.annotationActive = false;
		this.annotationId = "";
		this.annotationAlertId = -1;
	}
	/**
	 * setContainerMC sets the container movie clip for the alert manager.
	 * We're setting this function separately, as during initialization, we
	 * do not know the MC reference.
	 *	@param	targetMC	Movie clip associated with Alert Manager
	*/
	public function setContainerMC(targetMC:MovieClip):Void{
		this.targetMC = targetMC;
		//Create the movie clip container for sound
		this.soundMC = targetMC.createEmptyMovieClip("SoundHolderMC",targetMC.getNextHighestDepth());
		//Set the sound object.
		this.alertSound = new Sound(this.soundMC);
	}
	/**
	 * parseXML method parses the XML nodes for the alerts. It accepts
	 * <alerts> node as its parameter.
	 *	@param	alertsNode	<Alerts> node and it's child nodes.
	*/
	public function parseXML(alertsNode:XMLNode){
		//Loop variables
		var i:Number, j:Number;
		for (i=0; i<alertsNode.childNodes.length; i++){
			//If it's alert node 
			if (alertsNode.childNodes[i].nodeName.toUpperCase()=="ALERT"){
				//Increment count
				this.numAlerts++;
				//Parse the attributes and store it
				var atts:Array = Utils.getAttributesArray(alertsNode.childNodes[i]);
				//Get values
				var minValue:Number = Number(atts["minvalue"]);
				var maxValue:Number = Number(atts["maxvalue"]);
				var action:String = getFV(atts["action"],"");
				var param:String = getFV(atts["param"],"");
				var occurOnce:Boolean = toBoolean(getFN(atts["occuronce"],0));
				//Now, if minValue & maxValue are proper values, only then we accept them.
				if ((minValue==undefined || minValue==null || isNaN(minValue)) || (minValue==undefined || minValue==null || isNaN(minValue))){
					//Log an error
					this.chartIns.log("Invalid range for Alert","You've specified an invalid minValue/maxValue for an alert. Alerts need to be have numeric range as threshold.",Logger.LEVEL.ERROR);
				} else {
					//Now, check whether action is a valid action.
					//Convert to upper case for case-insensitive check
					action = action.toUpperCase();
					//Get action Id
					var actionId:Number;
					switch(action){
						case "CALLJS":
						actionId = this.ACTION.CALLJS;
						break;
						case "SHOWANNOTATION":
						actionId = this.ACTION.SHOWANNOTATION;
						break;
						case "PLAYSOUND":
						actionId = this.ACTION.PLAYSOUND;
						break;
						default:
						//Error Flag
						actionId = -1;
						break;
					}
					//If it's an unrecognized action, throw error
					if (actionId==-1){
						this.chartIns.log("Invalid Alert Action","'" + action + "' is not a valid Alert action. Only valid options are - CallJS, ShowAnnotation or PlaySound",Logger.LEVEL.ERROR);
					}else{
						//Add to our list of alerts
						//Store as object
						this.alerts[this.numAlerts] = new Object();
						this.alerts[this.numAlerts].minValue = minValue;
						this.alerts[this.numAlerts].maxValue = maxValue;
						this.alerts[this.numAlerts].actionId = actionId;
						this.alerts[this.numAlerts].param = param;
						this.alerts[this.numAlerts].occurOnce = occurOnce;
						//Set flag that this alert has not occurred till now.
						this.alerts[this.numAlerts].occurred = false;
					}
				}
			}
		}
	}
	/**
	 * check method is the main method that checks each data feed for 
	 * alert value match. If any defined alerts match, it invokes the required
	 * action.
	*/
	public function check(value:Number):Void{
		//If it's not a number, simply return
		if (isNaN(value) || value==undefined){
			return;
		}
		//By default assume that no alerts were matched.
		var alertMatched:Number = -1;
		//Iterate through each alert (in sequential defined order) to check
		//which one matches it
		for (var i:Number=1; i<=this.numAlerts; i++){
			//If in range
			if (value>=this.alerts[i].minValue && value<=this.alerts[i].maxValue){
				alertMatched = i;
				//Branch out
				break;
			}
		}
		//If we found a valid alert
		if (alertMatched!=-1){
			//If the previous alert showed an annotation, which is not required now,
			//we need to hide it. We check if the annotation doesn't match the current
			//alert ID too.
			if (this.annotationActive && (this.annotationAlertId!=alertMatched)){
				//Hide annotation
				this.am.hide(this.annotationId);
				//Update flags that no more annotations are active now.
				this.annotationActive = false;
				this.annotationId = "";
				this.annotationAlertId = -1;
			}
			//Now, if this alert is to occur only once and has already occurred, we ignore
			if (!(this.alerts[alertMatched].occurOnce && this.alerts[alertMatched].occurred)){
				//Update flag that the alert has occured once
				this.alerts[alertMatched].occurred = true;
				//Now, based on type of action, do the required job.
				switch (this.alerts[alertMatched].actionId){
					case this.ACTION.CALLJS:
					this.callJS(alertMatched);
					break;
					case this.ACTION.SHOWANNOTATION:
					this.showAnnotation(alertMatched);
					break;
					case this.ACTION.PLAYSOUND:
					this.playSound(alertMatched);
					break;
				}
			}
		}
	}
	/**
	 * callJS method calls a JS function when an alert is matched.
	 *	@param	alertMatched	Internal id of alert that matched.
	*/
	private function callJS(alertMatched:Number):Void{		
		getURL("javascript:" + unescape(this.alerts[alertMatched].param) + ";");
	}
	/**
	 * showAnnotation method shows an annotation when an alert is matched.
	 *	@param	alertMatched	Internal id of alert that matched.	 
	*/
	private function showAnnotation(alertMatched:Number):Void{
		//We need to show the required annotation, if it's not already showing
		//If the last alert matched was this annotation itself, we do not need
		//to do anything, as that's already showing.
		if (alertMatched!=this.annotationAlertId){
			this.am.show(this.alerts[alertMatched].param);		
			//Update flags that we've an active annotations now.
			this.annotationActive = true;
			this.annotationId = this.alerts[alertMatched].param;
			this.annotationAlertId = alertMatched;
		}
	}
	/**
	 * playSound method plays a sound when an alert is matched.
	 *	@param	alertMatched	Internal id of alert that matched.
	*/
	private function playSound(alertMatched:Number):Void{
		//If an existing sound is not already playing, we start
		//loading and playing the other sound. Else, we ignore.
		if (!soundPlaying){
			//Stop previous sound (if any).
			this.alertSound.stop();	
			//Load the sound as event sound.
			this.alertSound.loadSound(this.alerts[alertMatched].param, false);
			//Local class reference
			var classRef = this;
			this.alertSound.onLoad = function(success){
				if (success){
					//Start the sound- as we've loaded it as event sound.
					this.start();
					//Set playing flag
					classRef.soundPlaying = true;
				}else{
					//Error in loading sound - could be any reason.
					//Update flag that we're not playing
					classRef.soundPlaying = false;
				}
			}
			this.alertSound.onSoundComplete = function(){
				//Update flag that we're done playing
				classRef.soundPlaying = false;
			}
		}
	}
	/**
	 * destroy method destroys the instance of this class. 
	*/
	public function destroy():Void{
		//Stop the sound, if playing
		alertSound.stop();
		//Delete it
		delete alertSound;
		//Delete movie clip associated with sound object
		soundMC.removeMovieClip();
		targetMC.removeMovieClip();
		//Delete containers
		delete this.alerts;
		delete this.ACTION;
	}
}
