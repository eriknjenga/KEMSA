/**
* @class FCGrid
* @author InfoSoft Global (P) Ltd. www.fusioncharts.com / www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.

* FCGrid class helps draw a text grid having dragging capabilities.
*/
import com.fusioncharts.is.helper.Utils;
//Drop Shadow filter
import flash.filters.DropShadowFilter;
//Math Extension
import com.fusioncharts.is.extensions.MathExt;
class com.fusioncharts.is.helper.FCGrid {
	//Instance variables
	private var targetMC:MovieClip;
	private var width:Number, height:Number;
	private var rows:Number, columns:Number;
	private var cellWidth:Array, cellHeight:Array;
	private var allowResize:Boolean = false;
	private var borderColor:String = "666666";
	private var borderAlpha:Number = 100;
	private var resizeBarColor:String = "CCCCCC";
	private var resizeBarThickness:Number = 1;
	private var resizeBarAlpha:Number = 100;
	//Array to store data of each cell
	private var cells:Array;
	//Movie clip containers
	private var mcResizeIcon:MovieClip;
	//Public movie clip container - to draw reference boundary
	private var boundaryMC:MovieClip;
	//Depths for various objects
	private var depthColumn:Number, depthBoundary:Number, depthText:Number, depthResizeBars:Number, depthResizeIcon:Number;
	//Maximum cell width
	private var maxCellWidth:Number, maxRowHeight:Number;
	// CONSTANT - Padding between the drag resize bar and column end
	private var RESIZE_PADDING:Number = 15;
	/**
	 * Constructor function.
	 *	@param	targetMC			Which movie clip to build the grid in? The position will
	 *								start from 0,0 inside that. The target movie clip should be
	 *								an empty movie clip that'll just contain the grid. Also, the
	 *								position of the target movie clip determines where the grid
	 *								will appear on stage. The grid draws at 0,0 inside target MC.
	 *	@param	rows				Number of rows that this grid would have
	 *	@param	columns				Number of columns that this grid would have	 
	*/
	function FCGrid(targetMC:MovieClip, rows:Number, columns:Number) {
		//Store parameters into instance variables.
		this.targetMC = targetMC;		
		this.rows = rows;
		this.columns = columns;		
		//Initialize the array to store the data for this grid.  
		this.cells = new Array();
		// Create rows number of arrays to form r x c matrix
		var i:Number;
		for (i=1; i<=this.rows; i++) {
			this.cells[i] = new Array();
		}
		//Other containers		
		this.cellWidth = new Array();
		this.cellHeight = new Array();
		this.maxCellWidth = 0;
		this.maxRowHeight = 0;
		//Initialize
		this.init();
	}	
	/**
	 * returnDataAsCell method returns the data passed it it as an object. Each object
	 * encapsulates the properties for one cell.
	 *	@param	bgColor			Background color of the cell
	 *	@param	bgAlpha			Background alpha of the cell
	 *	@param	label			Label to be displayed in the cell
	 *	@param	font			Font in which the label should be rendered
	 *	@param	fontColor		Font Color
	 *	@param	fontSize		Size of the font.
	 *	@param	align			Horizontal alignment - "left", "center", "right"
	 *	@param	vAlign			Vertical alignment - "top", "middle", "bottom"
	 *	@param	isBold			Whether the text should be bold.
	 *	@param	isItalic		Whether the text should be italic
	 *	@param	isUnderLine		Whether the text should be underlines
	 *	@param	link			If the text should be linked, link of the text.
	*/
	private function returnDataAsCell(bgColor:String, bgAlpha:Number, label:String, font:String, fontColor:String, fontSize:Number, align:String, vAlign:String, isBold:Boolean, isItalic:Boolean, isUnderLine:Boolean, link:String):Object {
		//Create the object to represent cell
		var cellObj:Object = new Object();
		//Each cell object represents a particular cell
		cellObj.bgColor = bgColor;
		cellObj.bgAlpha = bgAlpha;
		cellObj.label = label;
		cellObj.font = font;
		cellObj.fontColor = fontColor;
		cellObj.fontSize = fontSize;
		cellObj.align = align;
		cellObj.vAlign = vAlign;
		cellObj.isBold = isBold;
		cellObj.isItalic = isItalic;
		cellObj.isUnderLine = isUnderLine;
		cellObj.link = link;		
		//Reference to the text field of this cell
		cellObj.tf = null;
		//Return it
		return cellObj;
	}
	/**
	 * init method is called as soon as the grid is instantiated. Init method does 
	 * all the calculations pertaining to the grid component.
	*/
	private function init():Void {		
		//Allot depths
		this.allotDepths();
	}
	/**
	 * allotDepths method allots the depths for various objects in the grid.
	*/
	private function allotDepths():Void {
		this.depthColumn = 1;		
		this.depthText = this.depthColumn+this.columns;
		this.depthResizeBars = this.depthText+this.rows*this.columns;
		this.depthResizeIcon = this.depthResizeBars+this.columns;
		this.depthBoundary = this.depthResizeIcon+1;
	}
	/**
	 * setCellDimensions method sets the width and height for cells which have
	 * not been explicitly defined.
	*/
	private function setCellDimensions() {		
		//For cell width, there can be 2 cases. One, the user has opted to show all
		//cells with the maximum width required. In that case, he'll pass -1 as the cellWidth.
		//So, we'll allot cellwidth as the actual width required to accomodate each cell.
		//Else, if the user has given percentage or numerical widths, we directly take that.
		//In this case, we also check for the final summation of user specified width/height
		//to make sure that the content doesn't run out of grid. If it does, we allot equi distant
		//width to all columns.		
		var i:Number;		
		var j:Number;
		if (this.cellWidth[1]==-1){
			//Case 1: Where user wants each cell to have the width equal to the max required for 
			//each column
			var maxColWidth:Number;
			for (i=1; i<=this.columns; i++){
				maxColWidth = 0;
				//Get the maximum column width required
				for (j=1; j<=this.rows; j++){
					maxColWidth = Math.max(maxColWidth, this.cells[j][i].width);
				}
				//Set it
				this.cellWidth[i] = maxColWidth;
			}
		}else{
			//Case 2: Where we take the user width specified by user - either numerical or as
			//percentage figure. Find the total un-allocated width and divide them equally into
			//cells that have not been allocated any width.
			var unallocatedCellWidth:Number = 0;			
			//Iterate and update the count of unallocated ones.
			for (i=1; i<=this.columns; i++) {
				if (this.cellWidth[i] == "" || this.cellWidth[i] == undefined) {
					//Set it as 0 value
					this.cellWidth[i] = 0;
					//Increase the counter of cells whose width are unallocated
					unallocatedCellWidth++;
				} else {
					//Check if the numbers are in percentage or actual numbers
					if (String(this.cellWidth[i]).indexOf("%")!=-1){
						//Convert the existing value into numbers (to be on safe side during calculations)
						this.cellWidth[i] = (parseInt(this.cellWidth[i],10)/100) * this.width;
					}else{
						//Convert the existing value into numbers (to be on safe side during calculations)
						this.cellWidth[i] = Number(this.cellWidth[i]);
					}				
					//If the cell width is more than the width of the grid, re-set
					if (this.cellWidth[i]>this.width) {
						//Set it to equal distance
						this.cellWidth[i] = this.width/this.columns;
					}
				}
			}
			//Now, calculate the total cell width "explicitly" allotted by user
			var cellWidthAllocation:Number = 0;
			var cellEquiWidth:Number = 0;
			for (i=1; i<=this.columns; i++) {
				//Add to cellWidthAllocation
				cellWidthAllocation = cellWidthAllocation+this.cellWidth[i];
			}
			//Now, divide the unallocated cell width into unallocated cells number
			cellEquiWidth = Math.abs(this.width-cellWidthAllocation)/unallocatedCellWidth;
			//Allot this equal width to cells having 0 values
			//Also store the sum of final cell widths
			var cellWidthSum:Number = 0;
			for (i=1; i<=this.columns; i++) {
				if (this.cellWidth[i] == 0) {
					this.cellWidth[i] = cellEquiWidth;
				}
				cellWidthSum = cellWidthSum + this.cellWidth[i];
			}
			//Now, check if cellWidth > this.width. If yes, we change all cell width to use
			//the equi distant width
			if (cellWidthSum>this.width){
				var eqWidth:Number = this.width/this.columns;
				for (i=1; i<=this.columns; i++) {
					this.cellWidth[i] = eqWidth;
				}
			}			
		}
		// ------------------ DO THE SAME FOR HEIGHT -----------------------//
		//Convert all cell height to numbers
		var unallocatedCellHeight:Number = 0;
		for (i=1; i<=this.rows; i++) {
			if (this.cellHeight[i] == "" || this.cellHeight[i] == undefined || isNaN(this.cellHeight[i]) == true) {
				//Set it as 0 value
				this.cellHeight[i] = 0;
				//Increase the counter of cells whose height are unallocated
				unallocatedCellHeight++;
			} else {
				//Convert the existing value into numbers (to be on safe side during calculations)
				this.cellHeight[i] = Number(this.cellHeight[i]);
				//If the cell height is more than the height of the grid, re-set
				if (this.cellHeight[i]>this.height) {
					//Set it to equal distance
					this.cellHeight[i] = this.height/this.rows;
				}
			}
		}
		//Now, calculate the total cell height "explicitly" allotted by user
		var cellHeightAllocation:Number = 0;
		var cellEquiHeight:Number = 0;
		for (i=1; i<=this.rows; i++) {
			//Add to cellHeightAllocation
			cellHeightAllocation = cellHeightAllocation+this.cellHeight[i];
		}
		//Now, divide the unallocated cell height into unallocated cells number
		cellEquiHeight = Math.abs(this.height-cellHeightAllocation)/unallocatedCellHeight;
		//Allot this equal height to cells having 0 values
		for (i=1; i<=this.rows; i++) {
			if (this.cellHeight[i] == 0) {
				this.cellHeight[i] = cellEquiHeight;
			}
		}
	}
	/**
	 * calcTextDimensions method calculates the width and height required to accomodate
	 * the text of a given cell using its own properties - but without wrapping.
	*/
	private function calcTextDimensions(rowIndex,columnIndex):Void{
		//Create the style object to represent the node
		var objStyle:Object = {align:this.cells[rowIndex][columnIndex].align, vAlign:"middle", bold:this.cells[rowIndex][columnIndex].isBold, italic:this.cells[rowIndex][columnIndex].isItalic, underline:this.cells[rowIndex][columnIndex].isUnderline, font:this.cells[rowIndex][columnIndex].font, size:this.cells[rowIndex][columnIndex].fontSize, color:this.cells[rowIndex][columnIndex].fontColor, isHTML:(this.cells[rowIndex][columnIndex].link != "" && this.cells[rowIndex][columnIndex].link != undefined), leftMargin:2, rightMargin:2, letterSpacing:0, bgColor:"FFFFFF", borderColor:"FFFFFF"};
		//Create the label
		var tfObj:Object = Utils.createText(true, this.cells[rowIndex][columnIndex].label, targetMC, 10000, 0, 0, 0, objStyle, false, null, null); 		
		//Store the same in cell - adding 2 pixels for extra spacing
		this.cells[rowIndex][columnIndex].width = tfObj.width + 2;
		this.cells[rowIndex][columnIndex].height = tfObj.height;
		//Remove the text field
		tfObj.tf.removeTextField();
		//Delete object
		delete tfObj;
	}
	/**
	 * drawColumnBase method draws the column base - rectangles that show up below
	 * each block of text. This method draws the column base for all the columns in 
	 * the grid.
	*/
	private function drawColumnBase():Void {
		//Draw the grid background (cell & rows border line) - column wise	
		var i:Number, j:Number, k:Number;
		var depth:Number = this.depthColumn;
		//Column starting position
		var columnXPos:Number = 0;
		for (i=1; i<=this.columns; i++) {
			//Create a new container for each column	
			var mcColumn:MovieClip = this.targetMC.createEmptyMovieClip("Column_"+i, depth);
			//Move to initial position
			mcColumn.moveTo(0, 0);
			//Get the width and height required.
			var currColWidth:Number = MathExt.toNearestTwip(this.cellWidth[i]);
			var currColHeight:Number = 0;
			//Draw the cells in it		
			for (j=1; j<=this.rows; j++) {
				//Set the line style for cell border
				mcColumn.lineStyle(0, parseInt(this.borderColor, 16), this.borderAlpha);
				//If it's to be filled, set the background color
				if (this.cells[j][i].bgColor != "" && this.cells[j][i].bgColor != undefined && this.cells[j][i].bgColor != null) {
					mcColumn.beginFill(parseInt(this.cells[j][i].bgColor, 16), this.cells[j][i].bgAlpha);
				}
				mcColumn.moveTo(0, currColHeight);
				mcColumn.lineTo(currColWidth, currColHeight);
				mcColumn.lineTo(currColWidth, currColHeight+this.cellHeight[j]);
				mcColumn.lineTo(0, currColHeight+this.cellHeight[j]);
				mcColumn.lineTo(0, currColHeight);
				//End fill																					  
				mcColumn.endFill();
				//Height
				currColHeight = currColHeight+this.cellHeight[j];
			}
			//Set the x-position of column
			mcColumn._x = columnXPos;
			delete mcColumn;
			//Increment column position
			columnXPos = columnXPos+MathExt.toNearestTwip(this.cellWidth[i]);
			//Increment depth
			depth++;
		}
	}
	/**
	 * drawColumnText method draws the text of a particular column.
	 *	@param	columnId	Which column's text to render?
	*/
	private function drawColumnText(columnId:Number):Void {
		var i:Number;
		//Variables to store text field x and y position, based on the alignment
		var tfX:Number, tfY:Number, tfVAlign:String;
		//Variable to store the y position of the row
		var rowStartY = 0;
		//Initial depth
		var depth = this.depthText+this.rows*(columnId-1);
		//First get the cumulative xPos of this column's center
		var columnCenterX:Number = 0;
		for (i=1; i<columnId; i++) {
			columnCenterX = columnCenterX+this.cellWidth[i];
		}		
		//Now iterate through all rows and create the text
		for (i=1; i<=this.rows; i++) {
			//Proceed only if the cell has a label
			if (this.cells[i][columnId].label != undefined && this.cells[i][columnId] != "" && this.cells[i][columnId] != null) {
				//Calculate the horizontal x position of the text field.
				switch (this.cells[i][columnId].align) {
				case "left" :
					tfX = columnCenterX;
					break;
				case "center" :
					tfX = columnCenterX+this.cellWidth[columnId]*0.5;
					break;
				case "right" :
					tfX = columnCenterX+this.cellWidth[columnId];
					break;
				}
				//Calculate the vertical y position of the text field.
				switch (this.cells[i][columnId].vAlign) {
				case "top" :
					tfVAlign = "bottom";
					tfY = rowStartY;
					break;
				case "middle" :
					tfVAlign = "middle";
					tfY = rowStartY+this.cellHeight[i]*0.5;
					break;
				case "bottom" :
					tfVAlign = "top";
					tfY = rowStartY+this.cellHeight[i];
					break;
				}
				//Create the style object to represent the node
				var objStyle:Object = {align:this.cells[i][columnId].align, vAlign:tfVAlign, bold:this.cells[i][columnId].isBold, italic:this.cells[i][columnId].isItalic, underline:this.cells[i][columnId].isUnderLine, font:this.cells[i][columnId].font, size:this.cells[i][columnId].fontSize, color:this.cells[i][columnId].fontColor, isHTML:(this.cells[i][columnId].link != "" && this.cells[i][columnId].link != undefined), leftMargin:2, rightMargin:2, letterSpacing:0, bgColor:"", borderColor:""};
				//Select the label depending on whether we've to show a link
				//var strLabel = (this.cells[i][columnId].link != "" && this.cells[i][columnId].link != undefined) ? ("<A HREF='"+this.cells[i][columnId].link+"'>"+this.cells[i][columnId].label+"</a>") : (this.cells[i][columnId].label);				
				var strLabel = (this.cells[i][columnId].link != "" && this.cells[i][columnId].link != undefined) ? ("<A HREF='asfunction:invokeLink,"+String(i+","+columnId)+"'>"+this.cells[i][columnId].label+"</A>") : (this.cells[i][columnId].label);								
				//Create the label
				//this.cells[i][columnId].tf = Utils.createText(false, strLabel, targetMC, depth, tfX, tfY, 0, objStyle, true, this.cellWidth[columnId], ).tf;
				this.cells[i][columnId].tf = Utils.createText(false, strLabel, targetMC, depth, tfX, tfY, 0, objStyle, true, this.cellWidth[columnId], ((this.cells[i][columnId].link != "" && this.cells[i][columnId].link != undefined)?(this.cells[i][columnId].height):(this.cellHeight[i]))).tf;
				//Increment the row height 
				rowStartY = rowStartY+this.cellHeight[i];
				//Increment depth
				depth++;
			}
		}
	}
	/**
	 * drawResizeIcon method draws the resize icon that will be used to resize the grid columns.
	*/
	private function drawResizeIcon():Void{
		//Create the movie clip container
		this.mcResizeIcon = this.targetMC.createEmptyMovieClip("resizeHandler", this.depthResizeIcon);
		//Hide the cursor initially
		this.mcResizeIcon._visible = false;
		//Start Filling
		this.mcResizeIcon.beginFill(parseInt("000000", 16), 100);
		//Draw the cursor
		this.mcResizeIcon.moveTo(4, 1);
		this.mcResizeIcon.lineTo(-4, 1);
		this.mcResizeIcon.lineTo(-4, 3.5);
		this.mcResizeIcon.lineTo(-6, 0);
		this.mcResizeIcon.lineTo(-4, -3.5);
		this.mcResizeIcon.lineTo(-4, -1);
		this.mcResizeIcon.lineTo(4, -1);
		this.mcResizeIcon.lineTo(4, -3.5);
		this.mcResizeIcon.lineTo(6, 0);
		this.mcResizeIcon.lineTo(4, 3.5);
		this.mcResizeIcon.lineTo(4, 1);
		this.mcResizeIcon.endFill();
		//Set shadow for the same.
		var shadowFilter:DropShadowFilter = new DropShadowFilter(3, 45, 0x999999, 0.8, 4, 4, 1, 1, false, false, false);
		this.mcResizeIcon.filters = [shadowFilter];		
	}
	/**
	 * drawResizeBars method draws the resize bars for the grid.
	*/
	private function drawResizeBars(){
		//Draw the resize bars only if there are more than 2 columns
		//and we have to allow resize
		if (this.columns>1 && this.allowResize == true) {
			var i:Number, j:Number, k:Number;
			var depth:Number = this.depthResizeBars;
			for (i=2; i<=this.columns; i++) {
				//Create the resize bar containers
				var mcResizeBar:MovieClip = targetMC.createEmptyMovieClip("ResizeBar_"+(i-1), depth);
				//Disabling tab - as it's not needed during scrolling
				mcResizeBar.tabEnabled = false;
				//Increment depth for next one
				depth++;
				//Create the visible and invisible parts of the resize bar
				//The invisible part is the one which responds to mouse events (drag)
				//Visible part shows up while drawing
				var mcRBHitArea:MovieClip = mcResizeBar.createEmptyMovieClip("HitArea", 1);
				var mcRBBar:MovieClip = mcResizeBar.createEmptyMovieClip("Bar", 2);				
				//Create the lines				
				//Hit Area
				mcRBHitArea.lineStyle(6, 0x000000, 0);
				mcRBHitArea.moveTo(0, 0);
				mcRBHitArea.lineTo(0, this.height);
				//Visible Bar
				mcRBBar.lineStyle(this.resizeBarThickness, parseInt(this.resizeBarColor, 16), this.resizeBarAlpha);
				mcRBBar.moveTo(0, 0);
				mcRBBar.lineTo(0, this.height);
				//By default the visible line won't be visible - they'll be visible when user clicks on them.
				mcRBBar._visible = false;
				//Set the x-position of the resize bar
				var barXPos:Number = 0;
				for (k = 1; k<=i-1; k++) {
					barXPos = barXPos+this.cellWidth[k];
				}
				mcResizeBar._x = barXPos;
				
				// ---------------- SET PROPERTIES OF THE BAR ------------------//
				//Reference to grid class
				var gridRef = this;
				//Id specifies the column index it drags (column index on whose right side this is attached)
				mcResizeBar.id = i-1;
				//Start X specifies the start x position till where it will be allowed to drag
				mcResizeBar.startX = barXPos-this.cellWidth[i-1];
				//End X specifies the end x position till where it will be allowed to drag.
				mcResizeBar.endX = barXPos+this.cellWidth[i];
				//Center X specifies its current position
				mcResizeBar.centerX = barXPos;
				//Now, set the event handlers.
				mcResizeBar.onRollOver = function() {
					//Hide mouse
					Mouse.hide();
					//Show our resize cursor
					gridRef.mcResizeIcon._visible = true;
					//Re-position it to current x-mouse
					gridRef.mcResizeIcon._x = this._parent._xmouse;
					gridRef.mcResizeIcon._y = this._parent._ymouse;
					//Keep re-positioning it with change of mouse
					this.onMouseMove = function() {
						gridRef.mcResizeIcon._x = this._parent._xmouse;
						gridRef.mcResizeIcon._y = this._parent._ymouse;
					};
				};
				mcResizeBar.onRollOut = function() {
					//Remove mouse move event
					delete this.onMouseMove;
					//Show mouse
					Mouse.show();
					//Hide our cursor
					gridRef.mcResizeIcon._visible = false;
				};				
				mcResizeBar.onPress = function() {
					//Flag that we're dragging
					this.dragging = true;
					//Show the resize bar
					this.Bar._visible = true;
					// Start dragging
					this.startDrag(false, this.startX+gridRef.RESIZE_PADDING, 0, this.endX-gridRef.RESIZE_PADDING, 0);
				};
				mcResizeBar.onRelease = mcResizeBar.onReleaseOutside=function () {
					//Update flag that we've stopped dragging
					this.dragging = false;
					//Stop dragging
					this.stopDrag();
					//Set line visible false
					this.Bar._visible = false;					
					// Make the size of the left column smaller
					var mcColumnLeft:MovieClip = gridRef.targetMC["Column_"+(this.id)];
					var mcColumnRight:MovieClip = gridRef.targetMC["Column_"+(this.id+1)];
					//Set the width of left column
					mcColumnLeft._width += (this._x-this.centerX);
					//Set x-position and width of right column
					mcColumnRight._x += (this._x-this.centerX);
					mcColumnRight._width -= (this._x-this.centerX);
					// Update global cellwidth
					gridRef.cellWidth[this.id] += (this._x-this.centerX);
					gridRef.cellWidth[this.id+1] -= (this._x-this.centerX);
					//Update indexes
					this.centerX = this._x;
					this.startX = mcColumnLeft._x;
					this.endX = mcColumnRight._x+mcColumnRight._width;
					//Get reference to previous resize bar
					var mcPreviousLine:MovieClip = gridRef.targetMC["ResizeBar_"+(this.id-1)];
					//Set its endX position - as it can now only drag upto the centerX of the currently dragged resize bar
					mcPreviousLine.endX = this.centerX;
					// Get reference to next resize bar
					var mcNextLine:MovieClip = gridRef.targetMC["ResizeBar_"+(this.id+1)];
					// Set its startX position - as it can now only drag from the centerX of the currently dragged resize bar
					mcNextLine.startX = this.centerX;
					// Re-draw the text for this column and the next column
					gridRef.drawColumnText(this.id);
					gridRef.drawColumnText(this.id+1);
				};
			}
		}
	}
	/**
	 * createLinkHandler method creates the link handler for links activated from
	 * clicks on grid.
	*/
	private function createLinkHandler():Void{
		//Create local link handler function in target Movie clip
		//We're not directly adding <A HREF> to text fields for 2 reasons:
		//- Cannot use FusionCharts link options (new window, frame etc.)
		//- Long links are mishandled by Flash
		// @param	strIndex String containing row index,column index as "r,c"
		//Reference to self.
		var gridRef = this;
		targetMC.invokeLink = function(strIndex:String):Void{
			//Split r,c into array r-[0], c-[1]
			var tokens:Array = strIndex.split(",");
			//Invoke the link
			Utils.invokeLink(gridRef.cells[Number(tokens[0])][Number(tokens[1])].link, null);
		}
	}
	/**
	 * drawBoundaryMC method draws the imaginary boundary across the grid. This is needed
	 * for reference outside the grid, if the user wants to use horizontal scroll component.
	*/
	private function drawBoundaryMC():Void{
		//Create a movie clip to draw boundary
		this.boundaryMC = this.targetMC.createEmptyMovieClip("BoundaryMC", this.depthBoundary);
		//Iterate through all columns to get width
		var i:Number;
		var w:Number = 1;		
		for (i=1; i<=this.columns; i++){
			w = w + this.cellWidth[i];
		}
		var h:Number = this.getMaxRowHeight();
		//Draw rectangle
		this.boundaryMC.lineStyle(0,0xffffff,0);		
		this.boundaryMC.moveTo(0,0);
		this.boundaryMC.lineTo(w,0);
		this.boundaryMC.lineTo(w,h);
		this.boundaryMC.lineTo(0,h);
		this.boundaryMC.lineTo(0,0);
	}
	//------------------------ PUBLIC APIS -------------------------//
	/**
	 * setSize method sets the size of the grid and width/height for individual cells.
 	 *	@param	width				Width of the grid (in pixels).
	 *	@param	height				Height of the grid (in pixels)
 	 *	@param	cellWidth			Array containing the width of each column
	 *	@param	cellHeight			Array containing the height of each row in grid.
	*/
	public function setSize(width:Number, height:Number, cellWidth:Array, cellHeight:Array):Void{
		this.width = width;
		this.height = height;
		
		//If user has specified the cell width and cell height, store them
		if (cellWidth != null && cellWidth != undefined && cellWidth.length>0) {
			this.cellWidth = cellWidth;
			// Unshift the array to make it synchronized with base 1
			this.cellWidth.unshift(0);
		}
		if (cellHeight != null && cellHeight != undefined && cellHeight.length>0) {
			this.cellHeight = cellHeight;
			// Unshift the array to make it synchronized with base 1
			this.cellHeight.unshift(0);
		}
		//Calculate the various dimensions required.
		this.setCellDimensions();
	}
	/**
	 * setParams method sets the parameter for the grid.
	 *	@param	allowResize			Whether to allow dragging and resizing of columns?
	 *	@param	borderColor			Border Color of the entire grid.
	 *	@param	borderAlpha			Border alpha of the grid.
	 *	@param	resizeBarColor		Color of the resizing bar
	 *	@param	resizeBarThickness	Thickness of the resizing bar line.
	 *	@param	resizeBarAlpha		Alpha of the resizing bar line.
	*/
	public function setParams(allowResize:Boolean, borderColor:String, borderAlpha:Number, resizeBarColor:String, resizeBarThickness:Number, resizeBarAlpha:Number):Void{
		this.allowResize = allowResize;
		this.borderColor = borderColor;
		this.borderAlpha = borderAlpha;
		this.resizeBarColor = resizeBarColor;
		this.resizeBarThickness = resizeBarThickness;
		this.resizeBarAlpha = resizeBarAlpha;		
	}
	/**
	 * setCell method sets the data for a particular cell of the grid.
	*/
	public function setCell(rowIndex:Number, columnIndex:Number, bgColor:String, bgAlpha:Number, label:String, font:String, fontColor:String, fontSize:Number, align:String, vAlign:String, isBold:Boolean, isItalic:Boolean, isUnderLine:Boolean, link:String):Void {
		//Check if rowIndex and columnIndex are within the bounds of the grid
		if (rowIndex>this.rows || columnIndex>this.columns) {
			throw new Error("Cell index out of bounds. Please increase the grid size in constructor function.");
			return;
		}
		//Else, create the object to represent the cell 
		this.cells[rowIndex][columnIndex] = this.returnDataAsCell(bgColor, bgAlpha, label, font, fontColor, fontSize, align, vAlign, isBold, isItalic, isUnderLine, link);
		//Update the width & height required for this text
		this.calcTextDimensions(rowIndex,columnIndex);
	}
	/**
	 * draw method draws the grid.
	*/
	public function draw():Void {
		//If the width and height has not been defined, raise an error
		if (this.width==undefined  || this.height==undefined){
			throw new Error("You've not defined the size of the grid. Please use the setSize() method to set the grid dimensions.");
			return;
		}
		//Draw the column base first.
		this.drawColumnBase();
		//Create the link click handler (before drawing text)
		this.createLinkHandler();		
		//Draw text of all the columns initially
		var i:Number;
		for (i=1; i<=this.columns; i++) {
			this.drawColumnText(i);
		}
		//Draw the resize icon
		this.drawResizeIcon();
		//Draw the resize bars (and set their events)
		this.drawResizeBars();
		//Draw the boundary movie clip.
		this.drawBoundaryMC();
	}
	/**
	 * getMaxCellWidth method returns the maximum cell width that can be occupied
	 * by any horizontal row. This method should be called after you've fed the data
	 * for all cells to the grid.
	*/
	public function getMaxCellWidth():Number{
		//If we've not already calculated before, calculate
		if (this.maxCellWidth==0){
			var i:Number, j:Number;	
			var maxColWidth:Number;
			var totalColWidth:Number = 0;
			//Iterate through each column and get the max column width required in that
			for (i=1; i<=this.columns; i++){
				maxColWidth = 0;
				//Get the maximum column width required
				for (j=1; j<=this.rows; j++){
					maxColWidth = Math.max(maxColWidth, this.cells[j][i].width);
				}
				//Sum it up
				totalColWidth += maxColWidth;
			}
			this.maxCellWidth = totalColWidth;
		}
		//Return the calculated value
		return this.maxCellWidth;		
	}
	/**
	 * getMaxRowHeight method returns the actual height taken by any row to fit the text
	 * in normal horizontal mode (no wrapping).
	*/
	public function getMaxRowHeight():Number{
		//If we've not already calculated before, calculate
		if (this.maxRowHeight==0){
			var maxRowHt:Number = 0;
			var i:Number, j:Number;			
			//Iterate through each row & column and store
			for (i=1; i<=this.columns; i++){
				maxRowHt = 0;
				for (j=1; j<=this.rows; j++){
					maxRowHt = maxRowHt + this.cells[j][i].height;
				}
				//Store the bigger
				this.maxRowHeight = Math.max(this.maxRowHeight, maxRowHt);
			}
		}
		//Return the calculated value
		return this.maxRowHeight;		
	}
	/**
	 * getBoundaryMC method returns the movie clip reference of the boundary of grid.
	*/
	public function getBoundaryMC():MovieClip{
		return this.boundaryMC;
	}
	/**
	 * destroy method destroys the grid and all its sub-components.
	*/
	public function destroy():Void {
		//Remove the entire parent movie clip itself
		this.targetMC.removeMovieClip();
	}
}