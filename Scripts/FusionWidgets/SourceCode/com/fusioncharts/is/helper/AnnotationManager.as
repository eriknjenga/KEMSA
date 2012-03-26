/**
 * @class AnnotationManager
 * @author InfoSoft Global (P) Ltd.
 * @version 3.0
 *
 * Copyright (C) InfoSoft Global Pvt. Ltd. 
 * AnnotationManager helps manange the annotations for a given
 * chart. It is the central unit that:
 * - Parses annotations XML. Handles error for invalid entries.
 * - Creates AnnotationGroup instances to represent them
 * - Renders them on-demand 
 * - Delegates event back to parent class on required occasions.
 * - Manages them together
 * - Exposes events to control them via JS/Flash API
*/
//Parent Chart Class
import com.fusioncharts.is.core.Chart;
//Annotation Group Class
import com.fusioncharts.is.helper.AnnotationGroup;
//Other necessary classes
import com.fusioncharts.is.core.StyleManager;
import com.fusioncharts.is.helper.Macros;
import com.fusioncharts.is.helper.ToolTip;
import com.fusioncharts.is.helper.FCEnum;
import com.fusioncharts.is.helper.FCError;
import com.fusioncharts.is.helper.Utils;
import com.fusioncharts.is.helper.Logger;
import flash.external.ExternalInterface;
import mx.utils.Delegate;

class com.fusioncharts.is.helper.AnnotationManager{
	//Chart instance to which this annotation manager belongs to
	private var chartIns:Chart;
	//List of Chart objects (passing by reference)
	private var chartObjs:FCEnum;
	//Reference to chart style manager
	private var styleM:StyleManager;
	//Reference to chart Macros
	private var chartMacros:Macros;
	//Instance of tool tip class (reference)
	private var tTip:ToolTip;
	//Array to store all annotation groups
	//Each element of the array will be a new Object storing:
	//id, group (reference to annotation group), showBelow, visible, mc, link, tooltext
	private var group:Array;
	//Number of defined annotation groups
	private var numGroups:Number;
	//Movie clip references that will contain the annotation groups 
	private var belowMC:MovieClip;
	private var aboveMC:MovieClip;
	//Current Stage width and height
	private var stageW:Number;	
	private var stageH:Number;
	//Original width and height of stage with whose respect the
	//co-ordinates are being given.
	private var origW:Number;
	private var origH:Number;
	//Whether to auto scale w.r.t orignal W and H
	private var autoScale:Boolean;
	//Whether to do a constrained scaling.
	private var constrainedScale:Boolean;
	//Whether to auto-scale images too?
	private var scaleImages:Boolean;
	//Wheter to auto-scale text?
	private var scaleText:Boolean;
	//Whether to expose methods to JS
	private var exposeToJS:Boolean;
	//X and Y Shift for the entire group (for correction purposes mainly)
	private var xShift:Number;
	private var yShift:Number;
	//Short forms for common function names
	private var getFV:Function;
	private var getFN:Function;
	private var toBoolean:Function;
	/*
	 * Constructor function.
	 *	@param	chartIns	Reference to chart class, for which we're rendering the
	 *						annotations.
	 *	@param	chartObjs	Reference to the enumeration which contains the list of
	 *						objects for the chart. While parsing annotation groups, we
	 *						add the group IDs of the annotations to this enumeration.
	 *	@param	styleM		Style Manager for the chart.
	 *	@param	chartMacros	Refernce to the Macros for the chart.
	 *	@param	tTip		Tool-tip instance used by the chart.	 
 	 *	@param	stageW		Current width of the stage in which all annotation
	 *						group would be present.
	 *	@param	stageH		Current height of the stage in which all annotation
	 *						groups would be present.
	 *	@param	exposeToJS	Whether to expose methods to JS.
	*/
	function AnnotationManager(chartIns:Chart, chartObjs:FCEnum, styleM:StyleManager, chartMacros:Macros, tTip:ToolTip, stageW:Number, stageH:Number, exposeToJS:Boolean){
		//Short forms for common function names.
		this.getFV = Utils.getFirstValue;
		this.getFN = Utils.getFirstNumber;
		this.toBoolean = Utils.toBoolean;
		//Store reference to chart class
		this.chartIns = chartIns;
		//Store other parameters
		this.chartObjs = chartObjs;
		this.styleM = styleM;
		this.chartMacros = chartMacros;
		this.tTip = tTip;		
		//Store current stage width and height
		this.stageW = stageW;
		this.stageH = stageH;
		//Whether to expose methods to JS
		this.exposeToJS = exposeToJS;
		//Initialize groups storage array and count
		this.group = new Array();
		this.numGroups = 0;
		//Expose the methods to JavaScript using ExternalInterface
		if (this.exposeToJS && ExternalInterface.available){
			//showAnnotation method
			ExternalInterface.addCallback("showAnnotation", this, show);
			//hideAnnotation method
			ExternalInterface.addCallback("hideAnnotation", this, hide);
		}
	}
	/**
	 * setMC method sets the movie clips for annotation manager, in which 
	 * we'll plot the contents.
 	 *	@param	belowMC		Movie clip reference in which we'll plot items that
	 *						are to appear below other elements.
	 *	@param	aboveMC		Movie clip reference in which we'll plot items that
	 *						are to appear above other elements.
	*/
	public function setMC(belowMC:MovieClip, aboveMC:MovieClip):Void{
		//Store reference to movie clips
		this.belowMC = belowMC;
		this.aboveMC = aboveMC;
	}
	/**
	 * parseXML method parses the annotation XML from the passed XML node.
	 *	@param	annotationNode		Reference to <annotations> or <customObjects> node.
	*/
	public function parseXML(annotationNode:XMLNode):Void{
		//Loop variables
		var i:Number, j:Number;
		//Get attributes array
		var atts:Array = Utils.getAttributesArray(annotationNode);
		//Store the attributes
		this.origW = getFN(atts["origw"], this.stageW);
		this.origH = getFN(atts["origh"], this.stageH);
		this.autoScale = toBoolean(getFN(atts["autoscale"], 1));
		this.constrainedScale = toBoolean(getFN(atts["constrainedscale"],1));
		this.scaleImages = toBoolean(getFN(atts["scaleimages"],0));
		this.scaleText = toBoolean(getFN(atts["scaletext"],0));
		this.xShift = getFN(atts["xshift"],0);
		this.yShift = getFN(atts["yshift"],0);
		//Search for annotationGroup Nodes now
		for (i=0; i<annotationNode.childNodes.length; i++){
			//If it's annotationGroup node (or objectGroup, for backward compatibility)
			if (annotationNode.childNodes[i].nodeName.toUpperCase()=="ANNOTATIONGROUP" || annotationNode.childNodes[i].nodeName.toUpperCase()=="OBJECTGROUP"){
				//We deal with the group, only if the group has any child nodes
				if (annotationNode.childNodes[i].childNodes.length>0){
					//Update count of annotation groups
					this.numGroups++;
					//Extract attributes of Annotation group
					var anAtts:Array = Utils.getAttributesArray(annotationNode.childNodes[i]);
					//Each group necessarily needs to have an ID
					var grpId:String = getFV(anAtts["id"],"_ANGrp_"+String(this.numGroups));
					//Change to upper case for case insensitive matching
					grpId = grpId.toUpperCase();
					//If the annotation group Id is valid (doesn't exist), we proceed with rest of parsing.
					if (!validateGroupId(grpId)){
						var grpX:Number = getFN(anAtts["x"],anAtts["xpos"],0);
						var grpY:Number = getFN(anAtts["y"],anAtts["ypos"],0);
						var grpAlpha:Number = getFN(anAtts["alpha"],100);
						var grpXScale:Number = getFN(anAtts["xscale"],100);
						var grpYScale:Number = getFN(anAtts["yscale"],100);
						var grpOrigW:Number = getFN(anAtts["origw"], this.origW);
						var grpOrigH:Number = getFN(anAtts["origh"], this.origH);
						var grpAutoScale:Boolean = toBoolean(getFN(anAtts["autoscale"], this.autoScale?1:0));
						var grpConstrainedScale:Boolean = toBoolean(getFN(anAtts["constrainedscale"],this.constrainedScale?1:0));
						var grpScaleImages:Boolean = toBoolean(getFN(anAtts["scaleimages"],this.scaleImages?1:0));
						var grpScaleText:Boolean = toBoolean(getFN(anAtts["scaletext"],this.scaleText?1:0));
						var grpXShift:Number = getFN(anAtts["xshift"],this.xShift);
						var grpYShift:Number = getFN(anAtts["yshift"],this.yShift);
						//Whether to show below or above
						var showBelow:Boolean = toBoolean(getFN(anAtts["showbelow"],anAtts["showbelowchart"],1));					
						//Whether it's visible by default
						var grpVisible:Boolean = toBoolean(getFN(anAtts["visible"],1));					
						//Tool-text for the entire group.
						var grpToolText:String = getFV(anAtts["tooltext"], "");
						//Link for the entire group.
						var grpLink:String = getFV(anAtts["link"], "");
						//We need to store this annotation group as an AnnotationGroup instance.						
						//Create the AnnotationGroup instance.
						var anGrp:AnnotationGroup = new AnnotationGroup(grpX, grpY, grpXScale, grpYScale, grpAlpha, this.stageW, this.stageH, grpOrigW, grpOrigH, grpAutoScale, grpConstrainedScale, grpScaleImages, grpScaleText, grpXShift, grpYShift);
						//Add to our group array - Create new object to store properties
						this.group[this.numGroups] = new Object();
						this.group[this.numGroups].id = grpId;
						this.group[this.numGroups].group = anGrp;						
						this.group[this.numGroups].showBelow = showBelow;
						this.group[this.numGroups].visible = grpVisible;						
						this.group[this.numGroups].link = grpLink;
						this.group[this.numGroups].toolText = grpToolText;
						//Now, we need to iterate through each of the <annotation> node within <annotationGroup> node
						//and add them as items of annotation group.
						for (j=0; j<annotationNode.childNodes[i].childNodes.length; j++){
							//Add the node if it's Annotation (or Object node, for backward compatibility)
							if (annotationNode.childNodes[i].childNodes[j].nodeName.toUpperCase()=="ANNOTATION" || annotationNode.childNodes[i].childNodes[j].nodeName.toUpperCase()=="OBJECT"){
								try{
									anGrp.addItem(annotationNode.childNodes[i].childNodes[j]);
								} catch (e : com.fusioncharts.is.helper.FCError){
									//If the control comes here, that means the given annotation type
									//identifier is invalid. So, we log the error message to the logger.
									this.chartIns.log(e.name, e.message, e.level);								
								}
							}
						}
					}else{
						//Log error for duplicate annotation ID.
						this.chartIns.log("Duplicate Annotation Id", "Duplicate ID '" + grpId + "' found for Annotation Groups. Each Annotation Group needs to have a unique identifier. Also, Annotation Group IDs cannot be the same as Chart Object IDs.", Logger.LEVEL.ERROR);
					}
				}
			}
		}
	}
	/** 
	 * render method draws the annotations on-screen.
	 *	@param	annbelow	Whether to draw annotations that are below?
	*/
	public function render(annbelow:Boolean):Void{
		//Iterate through all groups and call their draw function
		var i:Number;
		var grpMC:MovieClip;
		//Delegat-ed rollover function holder
		var fnRollOver:Function;
		//Container for movie clip iterator - string name holder
		var subMCName:String;
		for (i=1; i<=this.numGroups; i++){
			//Based on which annotation set (below/above), we've to draw, do so.
			if (this.group[i].showBelow==annbelow){				
				//Based on whether we've to show the group below or above, we'll
				//need to create appropriate movie clips.						
				if (this.group[i].showBelow){
					grpMC = belowMC.createEmptyMovieClip("AnnotationGrp_"+i, belowMC.getNextHighestDepth());
				}else{
					grpMC = aboveMC.createEmptyMovieClip("AnnotationGrp_"+i, aboveMC.getNextHighestDepth());
				}						
				this.group[i].mc = grpMC;
				this.group[i].group.setContainerMC(grpMC);
			
				//Draw the contents of the group.
				this.group[i].group.draw();				
				//Set visibility of the entire group.
				this.group[i].mc._visible = this.group[i].visible;
				//Now, since we've reference to the style manager and group movie
				//clip in this class, we code for the events and style here.				
				//Apply the filters to the movie clip (stored in Style Manager)
				this.styleM.applyFilters(this.group[i].mc, this.chartObjs.getItem(this.group[i].id));
				//Apply animation to individual movie clips inside this mc				
				var subMC:MovieClip;
				//Iterate through each nested movie clip inside this group.
				//This is done as the registration point of parent movie clip
				//cannot be used to do x,y or x-scale y-scale animation.
				for (subMCName in this.group[i].mc){					
					subMC = this.group[i].mc[subMCName];
					//Apply style based animation (if chart is in animation mode)
					if (chartIns.isAnimated()){
						this.styleM.applyAnimation(subMC, this.chartObjs.getItem(this.group[i].id), this.chartMacros, subMC._x, subMC._y, subMC._alpha, subMC._xscale, subMC._yscale, subMC._rotation);
					}
				}
				//If tool text has been defined, create the handlers.
				if (this.group[i].toolText!=""){					
					//Create delegate functions
					//Create Delegate for roll over function columnOnRollOver
					fnRollOver = Delegate.create(this, groupRollOver);
					//Set the index
					fnRollOver.index = i;
					//Assing the delegates to movie clip handler
					this.group[i].mc.onRollOver = fnRollOver;
					//Set roll out and mouse move too.
					this.group[i].mc.onRollOut = this.group[i].mc.onReleaseOutside = Delegate.create(this, groupRollOut);
					this.group[i].mc.onMouseMove = Delegate.create(this, groupMouseMove);
				}
				//If link has been defined, create the handlers
				if (this.group[i].link!=""){
					//Set hand cursor to on.
					this.group[i].mc.useHandCursor = true;
					//Local storage for in-scope access
					var link:String = this.group[i].link;
					//Store the link as part of MC itself
					this.group[i].mc.link = link;
					this.group[i].mc.chartIns = chartIns;
					//Create the handler
					this.group[i].mc.onRelease = function(){
						Utils.invokeLink(this.link, this.chartIns);
					}
				}else{
					//Switch off hand cursor (for groups with tool tip)
					this.group[i].mc.useHandCursor = false;
				}				
			}
		}
	}
	//---------------------- Validators ----------------------------//
	/**
	 * getGroupIndex method returns the numerical array index by searching
	 * on the string ID of the group. Returns -1 if the group ID could not
	 * be found.
	 *	@param	grpId	String ID of the group.
	 *	@return			Numeric Array Index of the group. -1 if not found.
	*/
	private function getGroupIndex(grpId:String):Number{
		//By default assume that the group Id doesn't exist.
		var index:Number = -1;
		var i:Number;
		for (i=1; i<=this.numGroups; i++){
			if (this.group[i].id == grpId){
				//Update index
				index = i;
				//Break
				break;
			}
		}
		return index;
	}
	/**
	 * validateGroupId method checks whether the given annotation ID already exists. 
	 * If yes, raise an error. If no, add it to the chart's list of objects.
	 *	@param	grpId	String ID of the group.
	 *	@return			Boolean value indicating whether the ID already exists.
	*/
	private function validateGroupId(grpId:String):Boolean{
		//Check whether the ID exists
		var idExists:Boolean = (this.getGroupIndex(grpId)==-1)?false:true;
		//If the id isn't already there, we need to push it to chart objects
		if (!idExists){
			this.chartObjs.addItem(grpId);
		}
		return idExists;
	}
	// ------------------------- APIs -------------------------//
	/**
	 * show method makes an annotation group visible. This method is used
	 * by alert manager and also exposed to External Interface.
	 *	@param	grpId	Id of the annotation group which we intend to show.
	*/
	public function show(grpId:String):Void{
		//Convert to upper case for case-insensitive match
		grpId = grpId.toUpperCase();
		//Get the numerical array index for the specified group Id.
		var index:Number = getGroupIndex(grpId);
		//If it's valid Id, proceed		
		if (index!=-1){
			//Set the visibility of that movie clip
			this.group[index].mc._visible = true;
		}else{
			//If it's -1, log an error
			this.chartIns.log("Invalid Annotation ID","Invalid Annotation Group ID '" + grpId + "' specified.", Logger.LEVEL.ERROR);
		}
	}
	/**
	 * hide method makes an annotation group in-visible. This method is used
	 * by alert manager and also exposed to External Interface.
	 *	@param	grpId	Id of the annotation group which we intend to show.
	*/
	public function hide(grpId:String):Void{
		//Convert to upper case for case-insensitive match
		grpId = grpId.toUpperCase();
		//Get the numerical array index for the specified group Id.
		var index:Number = getGroupIndex(grpId);
		//If it's valid Id, proceed		
		if (index!=-1){
			//Set the visibility of that movie clip to false
			this.group[index].mc._visible = false;
		}else{
			//If it's -1, log an error
			this.chartIns.log("Invalid Annotation ID","Invalid Annotation Group ID '" + grpId + "' specified.", Logger.LEVEL.ERROR);
		}
	}
	// -------------------- EVENT HANDLERS --------------------//
	/**
	* groupRollOver is the delegat-ed event handler method that'll
	* be invoked when the user rolls his mouse over an annotation group.
	* This function is invoked, only if the tool tip is to be shown.
	* Here, we show the tool tip.
	*/
	private function groupRollOver():Void{
		//Index of annotation group is stored in arguments.caller.index
		var index:Number = arguments.caller.index;
		//Set tool tip text
		this.tTip.setText (this.group[index].toolText);
		//Show the tool tip
		this.tTip.show();
	}
	/**
	* groupRollOut method is invoked when the mouse rolls out
	* of group. We just hide the tool tip here.
	*/
	private function groupRollOut():Void{
		//Hide the tool tip
		this.tTip.hide ();
	}
	/*
	* groupMouseMove is called when the mouse position has changed
	* over group. We reposition the tool tip.
	*/
	private function groupMouseMove():Void{
		//Reposition the tool tip only if it's in visible state
		if (this.tTip.visible()){
			this.tTip.rePosition ();
		}
	}	
	/** 
	 * destroy method removes all the annotations from memory.
	*/
	public function destroy():Void{
		//Iterate through all groups and call their destroy function
		var i:Number;
		for (i=1; i<=this.numGroups; i++){
			//Delete the event handlers defined for each MC in this class
			delete this.group[i].mc.onRelease;
			delete this.group[i].mc.onRollOver;
			delete this.group[i].mc.onRollOut;
			delete this.group[i].mc.onReleaseOutside;
			delete this.group[i].mc.onMouseMove;
			//Now, destroy the entire group.
			this.group[i].group.destroy();
		}
		//Delete containers
		delete this.group;
	}
}